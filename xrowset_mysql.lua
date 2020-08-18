
--MySQL rowsets.
--Written by Cosmin Apreutesei. Public Domain.

require'xrowset'
require'mysql_h'

--[=[
local function field_defs_from_columns_table(tables)
	local where = {}
	for _,t in ipairs(tables) do
		if #where > 0 then
			add(where, '\n\t\t\tor ')
		end
		append(where,
			'(c.table_schema = ', quote_sql(t[1]),
			' and c.table_name = ', quote_sql(t[2]), ' and (')
		for i = 3, #t do
			if i > 3 then
				add(where, ' or ')
			end
			add(where, 'c.column_name = ')
			add(where, quote_sql(t[i]))
		end
		add(where, '))')
	end
	print_queries(true)
	for i,row in ipairs(query([[
		select
			c.column_name,
			c.column_default,
			c.is_nullable,
			c.data_type,
			c.character_maximum_length,
			c.numeric_precision,
			c.numeric_scale,
			c.datetime_precision,
			c.character_set_name,
			c.extra, --auto_increment, on update ...
			c.is_generated
		from
			columns c
		where
			]]..concat(where))
	) do
		pp(row)
	end
end
]=]

local mysql_types = {
	[C.MYSQL_TYPE_DECIMAL    ] = 'number',
	[C.MYSQL_TYPE_TINY       ] = 'boolean',
	[C.MYSQL_TYPE_SHORT      ] = 'number',
	[C.MYSQL_TYPE_LONG       ] = 'number',
	[C.MYSQL_TYPE_FLOAT      ] = 'number',
	[C.MYSQL_TYPE_DOUBLE     ] = 'number',
	[C.MYSQL_TYPE_TIMESTAMP  ] = 'date',
	[C.MYSQL_TYPE_LONGLONG   ] = 'number',
	[C.MYSQL_TYPE_INT24      ] = 'number',
	[C.MYSQL_TYPE_DATE       ] = 'datetime',
	[C.MYSQL_TYPE_TIME       ] = 'time',
	[C.MYSQL_TYPE_DATETIME   ] = 'datetime',
	[C.MYSQL_TYPE_YEAR       ] = 'number',
	[C.MYSQL_TYPE_NEWDATE    ] = 'date',
	[C.MYSQL_TYPE_VARCHAR    ] = 'text',
	[C.MYSQL_TYPE_TIMESTAMP2 ] = 'date',
	[C.MYSQL_TYPE_DATETIME2  ] = 'datetime',
	[C.MYSQL_TYPE_TIME2      ] = 'time',
	[C.MYSQL_TYPE_NEWDECIMAL ] = 'number',
	[C.MYSQL_TYPE_ENUM       ] = 'enum',
	--[C.MYSQL_TYPE_SET        ] = '',
	[C.MYSQL_TYPE_TINY_BLOB  ] = 'file',
	[C.MYSQL_TYPE_MEDIUM_BLOB] = 'file',
	[C.MYSQL_TYPE_LONG_BLOB  ] = 'file',
	[C.MYSQL_TYPE_BLOB       ] = 'file',
	--[C.MYSQL_TYPE_VAR_STRING ] = '',
	--[C.MYSQL_TYPE_STRING     ] = '',
	--[C.MYSQL_TYPE_GEOMETRY   ] = '',
}

local mysql_range = {
	--[C.MYSQL_TYPE_DECIMAL    ] = {},
	[C.MYSQL_TYPE_TINY       ] = {-127, 127, 0, 255},
	[C.MYSQL_TYPE_SHORT      ] = {-32768, 32767, 0, 65535},
	[C.MYSQL_TYPE_LONG       ] = {},
	--[C.MYSQL_TYPE_FLOAT      ] = {},
	--[C.MYSQL_TYPE_DOUBLE     ] = {},
	[C.MYSQL_TYPE_LONGLONG   ] = {},
	[C.MYSQL_TYPE_INT24      ] = {-2^23, 2^23-1, 0, 2^24-1},
	--[C.MYSQL_TYPE_NEWDECIMAL ] = {},
}

local mysql_charsize = {
	[33] = 3, --utf8
	[45] = 4, --utf8mb4
}

local function field_defs_from_query_result_cols(cols, extra_defs, update_table)
	local t, pk, id_col = {}, {}
	for i,col in ipairs(cols) do
		local field = {}
		field.name = col.name
		local type = mysql_types[col.type]
		field.type = type
		field.allow_null = col.allow_null
		if col.auto_increment then
			field.focusable = false
			field.editable = false
			field.is_id = true
			if col.orig_table == update_table then
				id_col = col.name
			end
		end
		if type == 'number' then
			local range = mysql_range[col.type]
			if range then
				field.min = range[1 + (col.unsigned and 2 or 0)]
				field.max = range[2 + (col.unsigned and 2 or 0)]
			end
			if col.type ~= C.MYSQL_TYPE_FLOAT and col.type ~= C.MYSQL_TYPE_DOUBLE then
				field.multiple_of = 1 / 10^col.decimals
			end
		elseif not type then
			field.maxlen = col.length * (mysql_charsize[col.charsetnr] or 1)
		end
		t[i] = update(field, extra_defs and extra_defs[col.name])
		if col.pri_key or col.unique_key then
			add(pk, col.name)
		end
	end
	return t, pk, id_col
end

local function parse_fields(s)
	if type(s) ~= 'string' then
		return s
	end
	local t = {}
	for s in s:gmatch'[^%s]+' do
		t[#t+1] = s
	end
	return t
end

local function where_sql(pk, suffix)
	local t = {'where '}
	for i,k in ipairs(pk) do
		append(t, quote_sqlname(k), ' <=> ', ':', k, suffix or '', ' and ')
	end
	t[#t] = nil --remove the last ' and '.
	return concat(t)
end

local function insert_sql(tbl, fields, values)
	local t = {'insert into ', quote_sqlname(tbl), ' set '}
	for _,k in ipairs(fields) do
		local v = values[k]
		if v ~= nil then
			append(t, quote_sqlname(k), ' = ', quote_sql(v), ', ')
		end
	end
	if t[#t] == ' set ' then --no fields.
		t[#t] = ' values ()'
	else
		t[#t] = nil --remove the last ',  '.
	end
	return concat(t)
end

local function update_sql(tbl, fields, where_sql, values)
	local t = {'update ', quote_sqlname(tbl), ' set '}
	for _,k in ipairs(fields) do
		local v = values[k]
		if v ~= nil then
			append(t, quote_sqlname(k), ' = ', quote_sql(v), ', ')
		end
	end
	t[#t] = ' ' --replace the last comma.
	add(t, (quote_sqlparams(where_sql, values)))
	return concat(t)
end

local function delete_sql(tbl, where_sql, values)
	return concat{'delete from ', quote_sqlname(tbl), ' ',
		(quote_sqlparams(where_sql, values))}
end

function sql_rowset(...)
	return virtual_rowset(function(rs, sql, ...)

		if type(sql) == 'string' then
			rs.select = sql
		else
			update(rs, sql, ...)
		end

		rs.update_fields = parse_fields(rs.update_fields)
		rs.pk = parse_fields(rs.pk)

		if not rs.where_row and rs.pk then
			rs.where_row = where_sql(rs.pk)
		end
		if not rs.where_row_update and rs.pk then
			rs.where_row_update = where_sql(rs.pk, ':old')
		end

		if not rs.select_one and rs.select_all and rs.where_row then
			rs.select_one = rs.select_all .. ' ' .. rs.where_row
		end
		if not rs.select_one_update and rs.select_all and rs.where_row_update then
			rs.select_one_update = rs.select_all .. ' ' .. rs.where_row_update
		end
		if not rs.select and rs.select_all then
			rs.select = rs.select_all .. (rs.where and ' ' .. rs.where or '')
		end
		rs.insert_fields = rs.insert_fields or rs.update_fields

		assert(rs.select)

		function rs:select_rows(res, param_values)
			trace_queries(not config'hide_errors')
			local rows, cols, params = query_on(rs.db, rs.select, param_values)
			local fields, pk, id_col =
				field_defs_from_query_result_cols(cols, rs.field_attrs, rs.update_table)
			local sql_trace = trace_queries(false)
			merge(res, {
				fields = fields,
				pk = pk,
				id_col = id_col,
				rows = rows,
				params = params,
				sql_trace = sql_trace,
			})
		end

		local apply_changes = rs.apply_changes
		function rs:apply_changes(changes)
			trace_queries(not config'hide_errors')
			local res = apply_changes(self, changes)
			res.sql_trace = trace_queries(false)
			return res
		end

		if rs.update_table and rs.insert_fields then
			function rs:insert_row(row)
				local t = query(insert_sql(rs.update_table, rs.insert_fields, row))
				return t.affected_rows, t.insert_id ~= 0 and t.insert_id or nil
			end
		end

		if rs.update_table and rs.update_fields and rs.where_row_update then
			function rs:update_row(row)
				local t = query(update_sql(rs.update_table, rs.update_fields, rs.where_row_update, row))
				return t.affected_rows
			end
		end

		if rs.update_table and rs.where_row then
			function rs:delete_row(row)
				local t = query(delete_sql(rs.update_table, rs.where_row, row))
				return t.affected_rows
			end
		end

		if rs.select_one then
			function rs:select_row(row)
				return query1(rs.select_one, row)
			end
		end

		if rs.select_one_update then
			function rs:select_row_update(row)
				return query1(rs.select_one_update, row)
			end
		end

	end, ...)
end

