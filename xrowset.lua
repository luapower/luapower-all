
--Server-side rowset counterpart for x-widgets rowsets.
--Written by Cosmin Apreutesei. Public Domain.

require'mysql_h'

rowset = {}

action['rowset.json'] = function(name, ...)
	return check(rowset[name])(...)
end

local function field_defs_from_tables(tables)
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

local mysql_types = {
	[C.MYSQL_TYPE_DECIMAL    ] = 'number',
	[C.MYSQL_TYPE_TINY       ] = 'boolean',
	[C.MYSQL_TYPE_SHORT      ] = 'number',
	[C.MYSQL_TYPE_LONG       ] = 'number',
	[C.MYSQL_TYPE_FLOAT      ] = 'number',
	[C.MYSQL_TYPE_DOUBLE     ] = 'number',
	[C.MYSQL_TYPE_TIMESTAMP  ] = 'datetime',
	[C.MYSQL_TYPE_LONGLONG   ] = 'number',
	[C.MYSQL_TYPE_INT24      ] = 'number',
	[C.MYSQL_TYPE_DATE       ] = 'date',
	[C.MYSQL_TYPE_TIME       ] = 'time',
	[C.MYSQL_TYPE_DATETIME   ] = 'datetime',
	[C.MYSQL_TYPE_YEAR       ] = 'number',
	[C.MYSQL_TYPE_NEWDATE    ] = 'date',
	[C.MYSQL_TYPE_VARCHAR    ] = 'text',
	[C.MYSQL_TYPE_TIMESTAMP2 ] = 'datetime',
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

local function field_defs_from_query_cols(cols, extra_defs)
	local t, pk = {}, {}
	for i,col in ipairs(cols) do
		local field = {}
		field.name = col.name
		local type = mysql_types[col.type]
		field.type = type
		field.allow_null = col.allow_null
		field.editable = not col.auto_increment
		if type == 'number' then
			local range = mysql_range[col.type]
			if range then
				field.min = range[1 + (col.unsigned and 2 or 0)]
				field.max = range[2 + (col.unsigned and 2 or 0)]
			end
			field.multiple_of = 1 / 10^col.decimals
		elseif not type then
			field.maxlen = col.length * (mysql_charsize[col.charsetnr] or 1)
		end
		t[i] = update(field, extra_defs and extra_defs[col.name])
		if col.pri_key or col.unique_key then
			add(pk, col.name)
		end
	end
	return t, pk
end

function query_result_rowset(extra_defs, t, cols, params)
	if not t then return t, cols end
	local fields, pk = field_defs_from_query_cols(cols, extra_defs)
	local rows = {}
	for i,row in ipairs(t) do
		rows[i] = {values = row}
	end
	return {
		fields = fields,
		pk = #pk > 0 and concat(pk, ' ') or nil,
		rows = rows,
		params = params,
	}
end

function query_on_rowset(extra_defs, ...)
	if type(extra_defs) == 'table' then
		return query_result_rowset(extra_defs, query_on(...))
	else
		return query_result_rowset(nil, query_on(extra_defs, ...))
	end
end

function query_rowset(extra_defs, ...)
	if type(extra_defs) == 'table' then
		return query_result_rowset(extra_defs, query(...))
	else
		return query_result_rowset(nil, query(extra_defs, ...))
	end
end

--testing --------------------------------------------------------------------

local function send_slowly(s, dt)
	setheader('content-length', #s)
	local n = floor(#s * .1 / dt)
	while #s > 0 do
		out(s:sub(1, n))
		flush()
		sleep(.1)
		s = s:sub(n+1)
	end
end

action['ajax_test.txt'] = function()
	local s = 'There\'s no scientific evidence that life is important\n'
	local n = 5
	local z = 1
	sleep(1) --triggers `slow` event.
	setheader('content-length', #s * z * n)
	--^^comment to trigger chunked encoding (no progress in browser).
	--ngx.status = 500
	--^^uncomment see how browsers handles slow responses with non-200 codes.
	for i = 1, n do
		for i = 1, z do
			out(s)
		end
		flush(true)
		sleep(.5)
		--return
		--^^uncomment to trigger a timeout, if content_length is set.
	end
end

action['ajax_test.json'] = function()
	local t = post()
	t.a = t.a * 2
	out_json(t)
end

function rowset.test_static()
	if method'post' then
		--
	else
		local rows = {}
		for i = 1, 1e5 do
			rows[i] = {values = {i, 'Row '..i, 0}}
		end
		local t = {
			fields = {
				{name = 'id', type = 'number'},
				{name = 'name'},
				{name = 'date', type = 'date'},
			},
			rows = rows,
		}
		return t
		--sleep(5)
		--send_slowly(json(t), 1)
	end
end

function rowset.test_query()
	return query_rowset'select * from tables'
end
