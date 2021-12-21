--[[

	MySQL sqlpp backend.
	Written by Cosmin Apreutesei. Public Domain.

	Schema NYI:
	- views
	- functions
	- index type
	- table engine
	- zerofill
	- other obscure MySQL things I don't even know about?

]]

if not ... then require'sqlpp_mysql_test'; return end

local glue = require'glue'
local mysql = require'mysql'

local fmt = string.format
local add = table.insert
local cat = table.concat

local repl = glue.repl
local outdent = glue.outdent
local sortedpairs = glue.sortedpairs
local subst = glue.subst
local catargs = glue.catargs
local attr = glue.attr
local imap = glue.imap
local index = glue.index
local update = glue.update
local empty = glue.empty

local function init_spp(spp, cmd)

	--command API -------------------------------------------------------------

	local function pass(self, cn, ...)
		if not cn then return cn, ... end
		self.server_cache_key = cn.host..':'..cn.port
		function self:esc(s)
			return cn:esc(s)
		end
		function self:rawquery(sql, opt)
			return cn:query(sql, opt)
		end
		function self:rawagain(opt)
			return cn:read_result(opt)
		end
		function self:rawprepare(sql, opt)
			return cn:prepare(sql, opt)
		end
		return cn
	end
	function cmd:rawconnect(opt)
		if opt and opt.fake then
			return {fake = true, host = 'fake', port = 'fake', esc = mysql.esc_utf8}
		end
		return pass(self, mysql.connect(opt))
	end
	function cmd:rawuse(cn)
		return pass(self, cn)
	end

	function cmd:rawstmt_query(rawstmt, opt, ...)
		return rawstmt:query(opt, ...)
	end

	function cmd:rawstmt_free(rawstmt)
		rawstmt:free()
	end

	--SQL quoting -------------------------------------------------------------

	cmd.sqlname_quote = '`'

	local sqlnumber = cmd.sqlnumber
	function cmd:sqlnumber(v)
		if v ~= v or v == 1/0 or v == -1/0 then
			return 'null' --avoid syntax error for what ends up as null anyway.
		end
		return sqlnumber(self, v)
	end

	function cmd:sqlboolean(v)
		return v and 1 or 0
	end

	function cmd:get_reserved_words()
		if not self.rawquery then --fake
			return {}
		end
		return index(self:assert(self:rawquery([[
			select lower(word) from information_schema.keywords where reserved = 1
		]], {compact = true})))
	end

	--SQL formatting ----------------------------------------------------------

	spp.engine = 'mysql'
	spp.TO_SQL = 'mysql_to_sql'

	function cmd:sqltype(fld)
		local mt = fld.mysql_type
		if mt == 'decimal' then
			return _('decimal(%d,%d)', fld.digits, fld.decimals)
		elseif mt == 'enum' or mt == 'set' then
			local function sqlval(s) return self:sqlval(s) end
			local vals = fld.enum_values or fld.set_values
			return _('%s(%s)', mt, cat(imap(vals, sqlval), ', '))
		elseif mt == 'varchar' or mt == 'char' then
			local maxlen = fld.maxlen or mysql.char_size(fld.size, fld.mysql_collation)
			return _('%s(%d)', mt, maxlen)
		elseif mt == 'varbinary' or mt == 'binary' then
			return _('%s(%d)', mt, fld.size)
		else
			return mt
		end
	end

	function cmd:sqlcol_flags(fld)
		return catargs(' ',
			fld.unsigned and 'unsigned' or nil,
			fld.mysql_collation and 'collate '..fld.mysql_collation or nil,
			fld.not_null and 'not null' or nil,
			fld.auto_increment and 'auto_increment' or nil,
			fld.mysql_default ~= nil and 'default '..self:sqlval(fld.mysql_default) or nil,
			fld.mysql_on_update ~= nil and 'on update '..self:sqlval(fld.mysql_on_update) or nil,
			fld.comment and 'comment '..self:sqlval(fld.comment) or nil
		)
	end

	--schema diff'ing ---------------------------------------------------------

	spp.schema_options = {
		supports_fks = true,
		supports_checks = true,
		supports_triggers = true,
		supports_procs = true,
		relevant_field_attrs = {
			col=1,
			col_pos=1,
			digits=1,
			decimals=1,
			size=1,
			maxlen=1,
			not_null=1,
			auto_increment=1,
			comment=1,
			mysql_type=1,
			unsigned=1,
			mysql_collation=1,
			mysql_default=1,
			mysql_on_update=1,
		},
	}

	--schema extraction -------------------------------------------------------

	local function parse_values(s)
		local vals = s:match'%((.-)%)$'
		if not vals then return end
		local t = {}
		vals:gsub("'(.-)'", function(s)
			t[#t+1] = s
		end)
		return t
	end

	--input: data_type, column_type, numeric_precision, numeric_scale,
	--  ordinal_position, character_octet_length, character_set_name,
	--  collation_name, character_maximum_length.
	local function make_field(t)
		local mt = t.data_type
		local dt = {mysql_type = mt}
		dt.unsigned = t.column_type:find' unsigned$' and true or nil
		if mt == 'decimal' then
			dt.digits = t.numeric_precision
			dt.decimals = t.numeric_scale
			dt.type = dt.digits > 15 and 'decimal' or 'number'
			if dt.type == 'number' then
				min, max = mysql.dec_range(dt.digits, dt.decimals, dt.unsigned)
			end
		elseif mt == 'tinyint' or mt == 'smallint' or mt == 'mediumint'
			or mt == 'int' or mt == 'bigint'
		then
			dt.type = 'number'
			dt.min, dt.max, dt.size = mysql.int_range(mt, dt.unsigned)
			dt.decimals = 0
		elseif mt == 'float' then
			dt.type = 'number'
			dt.size = 4
		elseif mt == 'double' then
			dt.type = 'number'
			dt.size = 8
		elseif mt == 'year' then
			dt.type = 'number'
			dt.min, dt.max, dt.size = 1901, 2055, 2
		elseif mt == 'date' or mt == 'datetime' or mt == 'timestamp' then
			dt.type = 'date'
			dt.has_time = type ~= 'date' or nil
		elseif mt == 'enum' then
			dt.type = 'enum'
			dt.enum_values = parse_values(t.column_type)
			dt.mysql_charset = t.character_set_name
			dt.mysql_collation = t.collation_name
		elseif mt == 'set' then
			dt.type = 'set'
			dt.set_values = parse_values(t.column_type)
		elseif mt == 'varchar' or mt == 'char'
			or mt == 'tinytext' or mt == 'text'
			or mt == 'mediumtext' or mt == 'longtext'
			or mt == 'enum'
		then
			dt.type = 'text'
			dt.padded = mt == 'char' or nil
			dt.size = t.character_octet_length
			dt.maxlen = t.character_maximum_length
			dt.mysql_charset = t.character_set_name
			dt.mysql_collation = t.collation_name
		elseif mt == 'varbinary' or mt == 'binary'
			or mt == 'tinyblob' or mt == 'blob'
			or mt == 'mediumblob' or mt == 'longblob'
		then
			dt.type = 'binary'
			dt.size = t.character_octet_length
			dt.padded = mt == 'binary' or nil
		end
		return dt
	end

	function cmd:get_table_defs(opt)

		opt = opt or empty
		local tables = {} --{DB.TBL->table}

		local sql_db = opt.db and self:sqlval(opt.db)

		for i, db_tbl, grp in spp.each_group('db_tbl', self:assert(self:rawquery([[
			select
				concat(table_schema, '.', table_name) db_tbl,
				table_name,
				column_name,
				data_type,
				column_type,
				column_key,
				column_default,
				is_nullable,
				extra,
				character_maximum_length,
				character_octet_length,
				numeric_precision,
				numeric_scale,
				character_set_name,
				collation_name
			from
				information_schema.columns
			where
				table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
				]]..(db and ' and table_schema = '..sql_db or '')..[[
			order by
				table_schema, table_name, ordinal_position
			]])))
		do
			local fields = {}
			for i, row in ipairs(grp) do
				local col = row.column_name
				local auto_increment = row.extra == 'auto_increment' or nil
				local field = make_field(row)
				field.col = col
				field.col_pos = i
				field.col_in_front = i > 1 and fields[i-1].col
				field.auto_increment = auto_increment
				field.not_null = row.is_nullable == 'NO' or nil
				field.mysql_default = row.column_default
				field.default = row.column_default --not used in DDL, sent to client.
				if field.type == 'date' and field.mysql_default == 'CURRENT_TIMESTAMP' then
					field.mysql_default = spp.symbol_for.current_timestamp
					field.default = nil
				end
				field.mysql_on_update = row.extra
					and row.extra:match'on update CURRENT_TIMESTAMP'
					and spp.symbol_for.current_timestamp
				fields[i] = field
				fields[col] = field
			end
			tables[db_tbl] = {
				db = db, name = grp[1].table_name, fields = fields,
			}
		end

		local function row_col(row) return row.col end
		local function row_ref_col(row) return row.ref_col end
		local function return_false() return false end

		for i, db_tbl, constraints in spp.each_group('db_tbl', self:assert(self:rawquery([[
			select
				concat(cs.table_schema, '.', cs.table_name) db_tbl,
				cs.table_schema as db,
				cs.table_name,
				kcu.column_name col,
				cs.constraint_name,
				cs.constraint_type,
				kcu.referenced_table_schema ref_db,
				kcu.referenced_table_name ref_tbl,
				kcu.referenced_column_name ref_col,
				coalesce(rc.update_rule, 'no action') as onupdate,
				coalesce(rc.delete_rule, 'no action') as ondelete
			from
				information_schema.table_constraints cs /* cs type: pk, fk, uk */
				left join information_schema.key_column_usage kcu /* fk ref_tbl & ref_cols */
					 on kcu.table_schema     = cs.table_schema
					and kcu.table_name       = cs.table_name
					and kcu.constraint_name  = cs.constraint_name
				left join information_schema.referential_constraints rc /* fk rules: innodb only */
					 on rc.constraint_schema = kcu.table_schema
					and rc.table_name        = kcu.table_name
					and rc.constraint_name   = kcu.constraint_name
			where
				cs.table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
				]]..(db and ' and cs.table_schema = '..sql_db or '')..[[
			order by
				cs.table_schema, cs.table_name, cs.constraint_name, kcu.ordinal_position
			]])))
		do
			local tbl = tables[db_tbl]
			for i, cs_name, grp in spp.each_group('constraint_name', constraints) do
				local cs_type = grp[1].constraint_type
				if cs_type == 'PRIMARY KEY' then
					tbl.pk = imap(grp, row_col)
				elseif cs_type == 'FOREIGN KEY' then
					local db      = grp[1].db
					local ref_db  = grp[1].ref_db
					local ref_tbl = grp[1].ref_tbl
					if ref_db ~= db then --external fk
						ref_tbl = ref_db..'.'..ref_tbl
					end
					if #grp == 1 then
						local field = tbl.fields[grp[1].col]
						field.ref_table = ref_tbl
						field.ref_col = grp[1].ref_col
					end
					local cols = imap(grp, row_col)
					cols.desc = imap(cols, return_false) --in case there's no matching index.
					attr(tbl, 'fks')[cs_name] = {
						name      = cs_name,
						table     = tbl.name,
						ref_table = ref_tbl,
						cols      = cols,
						ref_cols  = imap(grp, row_ref_col),
						onupdate  = repl(grp[1].onupdate:lower(), 'no action', nil),
						ondelete  = repl(grp[1].ondelete:lower(), 'no action', nil),
					}
				elseif cs_type == 'UNIQUE' then
					attr(tbl, 'uks')[cs_name] = imap(grp, row_col)
				end
			end

		end

		--NOTE: constraints do not create an index if one is already available
		--on the columns that they need, so not every constraint has an entry
		--in the statistics table (which is why we couldn't join `statistics`
		--in and had to get indexes with a separate select).

		local function row_desc(t) return t.collation == 'D' end

		if opt.all or opt.indexes then
			for i, db_tbl, ixs in spp.each_group('db_tbl', self:assert(self:rawquery([[
				select
					concat(s.table_schema, '.', s.table_name) db_tbl,
					s.table_name,
					s.column_name col,
					cs.constraint_name,
					s.index_name,
					s.collation /* D|A */
				from information_schema.statistics s /* columns for pk, uk, fk, ix */
				left join information_schema.table_constraints cs /* cs type: pk, fk, uk */
					 on cs.table_schema     = s.table_schema
					and cs.table_name       = s.table_name
					and cs.constraint_name  = s.index_name
				where
					s.table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
					]]..(db and ' and s.table_schema = '..sql_db or '')..[[
				order by
					s.table_schema, s.table_name, s.index_name, s.seq_in_index
				]])))
			do
				local tbl = tables[db_tbl]
				local uks = tbl.uks
				local fks = tbl.fks
				for i, ix_name, grp in spp.each_group('index_name', ixs) do
					local desc = imap(grp, row_desc)
					if ix_name == 'PRIMARY' then
						tbl.pk.desc = desc
					else
						local cs_name = grp[1].constraint_name
						if cs_name then --matching uk or fk
							local uk = uks and uks[cs_name]
							local fk = fks and fks[cs_name]
							assert(not uk ~= not fk)
							if uk then uk.desc = desc end
							if fk then fk.cols.desc = desc end
						else --ix
							local ix = imap(grp, row_col)
							ix.desc = desc
							attr(tbl, 'ixs')[ix_name] = ix
						end
					end
				end
			end
		end

		if opt.all or opt.checks then
			for i, db_tbl, checks in spp.each_group('db_tbl', self:assert(self:rawquery([[
				select
					concat(cs.table_schema, '.', cs.table_name) db_tbl,
					cc.constraint_name,
					cc.check_clause
				from information_schema.table_constraints cs
				inner join information_schema.check_constraints cc
					 on cs.table_schema    = cc.constraint_schema
					and cs.constraint_name = cc.constraint_name
				where
					cs.table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
					]]..(db and ' and cs.table_schema = '..sql_db or '')..[[
				order by
					cs.table_schema, cs.table_name
				]])))
			do
				local tbl = tables[db_tbl]
				for i, row in ipairs(checks) do
					attr(tbl, 'checks')[row.constraint_name] = {
						mysql_body = row.check_clause:gsub('`', ''):gsub('^%(', ''):gsub('%)$', ''),
					}
				end
			end
		end

		if opt.all or opt.triggers then
			for i, db_tbl, triggers in spp.each_group('db_tbl', self:assert(self:rawquery([[
				select
					concat(event_object_schema, '.', event_object_table) db_tbl,
					trigger_name,
					action_order,
					action_timing,      /* before|after */
					event_manipulation, /* insert|update|delete */
					action_statement
				from information_schema.triggers
				where
					event_object_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
					and definer = current_user
					]]..(db and ' and event_object_schema = '..sql_db or '')..[[
				order by
					event_object_schema, event_object_table
				]])))
			do
				local tbl = tables[db_tbl]
				for i, row in ipairs(triggers) do
					attr(tbl, 'triggers')[row.trigger_name] = {
						pos        = row.action_order,
						when       = row.action_timing:lower(),
						op         = row.event_manipulation:lower(),
						mysql_body = row.action_statement,
					}
				end
			end
		end

		return tables
	end

	local function make_param(t)
		local p = make_field(t)
		p.mode = repl(t.parameter_mode:lower(), 'in', nil)
		p.col  = t.parameter_name --it's weird, but easier bc fields have `col`.
		return p
	end

	--TODO: get functions too.

	function cmd:get_procs(db)
		local procsets = {} --{db->{proc->p}}
		for i, db, procs in spp.each_group('db', self:assert(self:rawquery([[
			select
				r.routine_schema db,
				r.routine_name,
				r.routine_definition,

				p.parameter_mode, /* in|out */
				p.parameter_name,

				/* input for field_type_attrs(): */
				p.data_type,
				p.dtd_identifier column_type,
				p.numeric_precision,
				p.numeric_scale,
				p.ordinal_position,
				p.character_octet_length,
				p.character_set_name,
				p.collation_name,
				p.character_maximum_length

			from information_schema.routines r
			left join information_schema.parameters p
				on p.specific_name = r.routine_name
			where
				r.routine_type = 'PROCEDURE'
				and r.routine_schema <> 'sys'
				]]..(db and ' and r.routine_schema = '..self:sqlval(db) or '')..[[
			order by
				r.routine_schema
			]])))
		do
			local procset = attr(procsets, db)
			for i, proc_name, grp in spp.each_group('routine_name', procs) do
				local p = {
					args       = imap(grp, make_param),
					mysql_body = grp[1].routine_definition,
				}
				procset[proc_name] = p
				for i, param in ipairs(grp) do
					p[i] = self:sqltype(param)
				end
			end
		end
		return procsets
	end

	--structured errors -------------------------------------------------------

	spp.errno[1364] = function(self, err)
		err.col = err.message:match"'(.-)'"
		err.message = _(S('error_field_required', 'Field "%s" is required'), err.col)
		err.code = 'required'
	end

	spp.errno[1048] = function(self, err)
		err.col = err.message:match"'(.-)'"
		err.message = _(S('error_field_not_null', 'Field "%s" cannot be empty'), err.col)
		err.code = 'not_null'
	end

	spp.errno[1062] = function(self, err)
		local pri = err.message:find"for key '.-%.PRIMARY'"
		err.code = pri and 'pk' or 'uk'
	end

	function spp.fk_message_remove()
		return 'Cannot remove {foreign_entity}: remove any associated {entity} first.'
	end

	function spp.fk_message_set()
		return 'Cannot set {entity}: {foreign_entity} not found in database.'
	end

	local function fk_message(self, err, op)
		local def = self:table_def(err.table)
		local fdef = self:table_def(err.fk_table)
		local t = {}
		t.entity = (def.text or def.name):lower()
		t.foreign_entity = (fdef.text or fdef.name):lower()
		local s = (op == 'remove' and spp.fk_message_remove or spp.fk_message_set)()
		return subst(s, t)
	end

	local function dename(s)
		return s:gsub('`', '')
	end
	local function errno_fk(self, err, op)
		local tbl, col, fk_tbl, fk_col =
			err.message:match"%((.-), CONSTRAINT .- FOREIGN KEY %((.-)%) REFERENCES (.-) %((.-)%)"
		if tbl:find'%.`#sql-' then --internal constraint from `alter table add foreign key` errors.
			return err
		end
		err.table = dename(tbl)
		err.col = dename(col)
		err.fk_table = dename(fk_tbl)
		err.fk_col = dename(fk_col)
		err.message = fk_message(self, err, op)
		err.code = 'fk'
	end
	spp.errno[1451] = function(self, err) return errno_fk(self, err, 'remove') end
	spp.errno[1452] = function(self, err) return errno_fk(self, err, 'set') end

end

return {
	init_spp = init_spp,
}
