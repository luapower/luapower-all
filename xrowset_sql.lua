--[[

	SQL rowsets.
	Written by Cosmin Apreutesei. Public Domain.

	What must be specified manually:
		- select          : select without where clause.
		- where_all       : where clause for all rows (without the word "where").
		- order_by        : order-by clause.
		- pk              : 'foo bar ...', required as it can't be inferred reliably.
		- db              : optional, connection alias to query on.

	More complex cases can specify:
		- select_all    : instead of select + where_all.
		- where_row     : where clause for single row: 'tbl.pk1 = :as_pk1 and ...'.
		- select_row    : instead of select + where_row.
		- select_none   : instead of select_row or (select + 'where 1 = 0').

	If all else fails, you can always implement the rowset's S/U/I/D methods
	yourself. Just make sure to wrap multiple update queries in atomic().

	Inferred field attributes:
		name             : column alias.
		type             : field type.
		min, max         : numeric range (integers).
		decimals         : number of decimals (integers and decimals).
		max_char_w       : max length in characters in the current result set.
	Additionally, for fields that can be traced back to their origin table:
		enum_values      : enum values.
		default          : default value.
		not_null         : not-null flag.
		maxlen           : max length in characters.
		min, max         : numeric range (decimals).
		ref_table        : reference table (foreign key).
		ref_col          : column name in reference table (single-column fk).

	Fields without an origin table (SQL expressions) are made readonly.
	Auto-increment fields are made readonly.

	How to use rowset param values in queries:
		- in where_all:
			- `:param:filter`
				- `tbl.pk in (:param:filter)`, if the rowset's pk is a single column.
				- `$filter(foo = :foo and bar = :bar, :param:filter)` for composite pks.
			- `:param:lang`         : current language.
			- `:param:default_lang` : default language.
		- in insert and update queries:
			- `:COL`      : the column's new or changed value.
		- in update and delete where clause:
			- `:COL:old`  : the column's old value.

	Field methods to implement:
		to_lua(v)        : convert value for select result sets.
		to_sql(v)        : convert value for update queries (SQL statements).
		to_bin(v)        : convert value for update queries (prepared statements).

]]

require'xrowset'
require'webb_query'

local glue = require'glue'

local format = string.format
local concat = table.concat
local add = table.insert

local outdent = glue.outdent
local names = glue.names
local noop = glue.noop
local index = glue.index
local assertf = glue.assert
local repl = glue.repl
local memoize = glue.memoize
local sortedpairs = glue.sortedpairs

--usage in sql:
	-- single-key: foo in (:param:filter)
	-- multi-key : $filter(foo <=> :foo and bar <=> :bar, :param:filter)
function qmacro.filter(expr, filter)
	local t = {}
	for i,vals in ipairs(filter) do
		t[i] = sqlparams(expr, vals)
	end
	return concat(t, ' or ')
end

local rowset_type = {
	bool        = 'bool',
	tinyint     = 'number',
	smallint    = 'number',
	mediumint   = 'number',
	int         = 'number',
	bigint      = 'number',
	float       = 'number',
	double      = 'number',
	decimal     = 'number',
	year        = 'number',
	enum        = 'enum',
	timestamp   = 'datetime',
	datetime    = 'datetime',
	date        = 'date',
	time        = 'time',
	blob        = 'file',
	tinyblob    = 'file',
	mediumblob  = 'file',
	longblob    = 'file',
}

local function guess_name_col(tdef)
	if tdef.name_col then return tdef.name_col end
	if tdef.fields.name then return 'name' end
end

local function lookup_rowset(tbl)
	local rs = 'lookup_'..tbl
	if not rowset[rs] then
		local tdef = table_def(tbl)
		local name_col = guess_name_col(tdef)
		local t = glue.extend({name_col}, tdef.pk)
		local cols = concat(glue.imap(t, sqlname), ', ')
		rowset[rs] = sql_rowset{
			select = format('select %s from %s', cols, tbl),
			pk = concat(tdef.pk, ' '),
			name_col = name_col,
		}
	end
	return rs, rs.name_col
end

function sql_rowset(...)

	return virtual_rowset(function(rs, sql, ...)

		if type(sql) == 'string' then
			rs.select = sql
		else
			update(rs, sql, ...)
		end

		rs.delay_init_fields = true

		--the rowset's pk cannot be reliably inferred so it must be user-supplied.

		rs.pk = names(rs.pk)
		assert(rs.pk and #rs.pk > 0, 'pk missing')
		table.sort(rs.pk)

		--static query generation (just stitching together user-supplied parts).

		if not rs.select_all and rs.select then
			rs.select_all = outdent(rs.select)
				.. (rs.where_all and '\nwhere '..rs.where_all or '')
				.. (rs.order_by and '\norder by '..rs.order_by or '')
		end

		if not rs.select_row and rs.select and rs.where_row then
			rs.select_row = outdent(rs.select) .. '\nwhere ' .. rs.where_row
		end

		if not rs.select_none and rs.select then
			rs.select_none = rs.select .. '\nwhere 1 = 0'
		end

		--query wrappers.

		local function query(...)
			return db(rs.db):query(...)
		end

		--see if we can make a static load_row().

		if not rs.load_row and rs.select_row then
			function rs:load_row(vals)
				local rows = query(rs.select_row, vals)
				assert(#rows < 2, 'loaded back multiple rows for one inserted row')
				return rows[1]
			end
		end

		--dynamic generation of update queries based on the mapping of the
		--selected columns to their origin tables obtained from running the
		--select query the first time. if any of the update methods are called
		--before the select is run, it runs the select_none query once to get
		--the column mappings.

		local configure

		local load_opt = {
			compact = true,
			null_value = null,
			get_table_defs = true,
			field_attrs = rs.field_attrs,
		}

		if not rs.load_rows then
			assert(rs.select_all, 'select_all missing')
			function rs:load_rows(res, param_vals)
				local rows, fields, params = query(load_opt, rs.select_all, param_vals)
				if configure then
					configure(fields)
					rs.params = params
				end
				res.rows = rows
			end
		end

		local user_methods = {}
		assert(rs.select_none, 'select_none missing')
		local apply_changes = rs.apply_changes
		function rs:apply_changes(changes)
			if configure then
				local _, fields = query(rs.select_none)
				configure(fields)
			end
			return apply_changes(self, changes)
		end

		--[[local]] function configure(fields)

			configure = nil --one-shot.

			rs.fields = fields
			for i,f in ipairs(fields) do
				f.sqltype = f.type
				f.type = rowset_type[f.type]
				if f.sqltype == 'tinyint' and f.digits == 1 then --only for origin columns!
					f.type = 'bool'
				end
				if not f.col or f.auto_increment then
					f.readonly = true
				end
				if f.ref_table then
					f.lookup_rowset_name, f.display_col = lookup_rowset(f.ref_table)
					f.lookup_col = f.ref_col
				end
			end
			rs:init_fields()

			local function where_row_sql()
				local t = {}
				for i, as_col in ipairs(rs.pk) do
					local f = fields[as_col]
					local tbl = f.db..'.'..f.table
					local where_col = (f.table_alias or tbl)..'.'..f.col
					if i > 1 then add(t, ' and ') end
					add(t, where_col..' = :'..as_col)
				end
				return concat(t)
			end

			if not rs.load_row then
				assert(rs.select, 'select missing to create load_row()')
				local where_row = where_row_sql()
				function rs:load_row(vals)
					local sql = outdent(rs.select) .. (where_all
						and format('\nwhere (%s) and (%s)', where_all, where_row)
						 or format('\nwhere %s', where_row))
					return first_row(load_opt, sql, vals)
				end
			end

		end

		local function make_atomic(f)
			if not f then return end
			return function(...)
				return atomic(f, ...)
			end
		end
		make_atomic(rs.insert_row)
		make_atomic(rs.update_row)
		make_atomic(rs.delete_row)

	end, ...)
end
