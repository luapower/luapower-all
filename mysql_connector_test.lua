--mysql test unit (see comments for problems with libmariadb)
--NOTE: create a database called 'test' first to run these tests!
local mysql = require'mysql_connector'
local glue = require'glue'
local pp = require'pp'
local myprint = require'mysql_connector_print'
local ffi = require'ffi'

mysql.bind'mariadb'

--helpers

local print_table = myprint.table
local print_result = myprint.result
local fit = myprint.fit

local function assert_deepequal(t1, t2) --assert the equality of two values
	assert(type(t1) == type(t2), type(t1)..' ~= '..type(t2))
	if type(t1) == 'table' then
		for k,v in pairs(t1) do assert_deepequal(t2[k], v) end
		for k,v in pairs(t2) do assert_deepequal(t1[k], v) end
	else
		assert(t1 == t2, pp.format(t1) .. ' ~= ' .. pp.format(t2))
	end
end

local function print_fields(fields_iter)
	local fields = {'name', 'type', 'type_flag', 'length', 'max_length', 'decimals', 'charsetnr',
							'org_name', 'table', 'org_table', 'db', 'catalog', 'def', 'extension'}
	local rows = {}
	local aligns = {}
	for i,field in fields_iter do
		rows[i] = {}
		for j=1,#fields do
			local v = field[fields[j]]
			rows[i][j] = tostring(v)
			aligns[j] = type(v) == 'number' and 'right' or 'left'
		end
	end
	print_table(fields, rows, aligns)
end

--client library

print('mysql.thread_safe()   ', '->', pp.format(mysql.thread_safe()))
print('mysql.client_info()   ', '->', pp.format(mysql.client_info()))
print('mysql.client_version()', '->', pp.format(mysql.client_version()))

--connections

local t = {
	host = 'localhost',
	user = 'root',
	db = 'test',
	options = {
		MYSQL_SECURE_AUTH = false, --not supported by libmariadb
		MYSQL_OPT_READ_TIMEOUT = 1,
	},
	flags = {
		CLIENT_LONG_PASSWORD = true,
	},
}
local conn = mysql.connect(t)
print('mysql.connect         ', pp.format(t, '   '), '->', conn)
print('conn:change_user(     ', pp.format(t.user), ')', conn:change_user(t.user))
print('conn:select_db(       ', pp.format(t.db), ')', conn:select_db(t.db))
print('conn:set_multiple_statements(', pp.format(true), ')', conn:set_multiple_statements(true))
print('conn:set_charset(     ', pp.format('utf8'), ')', conn:set_charset('utf8'))

--conn info

print('conn:charset_name()   ', '->', pp.format(conn:charset())); assert(conn:charset() == 'utf8')
print('conn:charset_info()   ', '->', pp.format(conn:charset_info(), '   ')) --crashes libmariadb
print('conn:ping()           ', '->', pp.format(conn:ping()))
print('conn:thread_id()      ', '->', pp.format(conn:thread_id()))
print('conn:stat()           ', '->', pp.format(conn:stat()))
print('conn:server_info()    ', '->', pp.format(conn:server_info()))
print('conn:host_info()      ', '->', pp.format(conn:host_info()))
print('conn:server_version() ', '->', pp.format(conn:server_version()))
print('conn:proto_info()     ', '->', pp.format(conn:proto_info()))
print('conn:ssl_cipher()     ', '->', pp.format(conn:ssl_cipher()))

--transactions

print('conn:commit()         ', conn:commit())
print('conn:rollback()       ', conn:rollback())
print('conn:set_autocommit() ', conn:set_autocommit(true))

--test types and values

local test_fields = {
	'fdecimal',
	'fnumeric',
	'ftinyint',
	'futinyint',
	'fsmallint',
	'fusmallint',
	'finteger',
	'fuinteger',
	'ffloat',
	'fdouble',
	'fdouble2',
	'fdouble3',
	'fdouble4',
	'freal',
	'fbigint',
	'fubigint',
	'fmediumint',
	'fumediumint',
	'fdate',
	'ftime',
	'ftime2',
	'fdatetime',
	'fdatetime2',
	'ftimestamp',
	'ftimestamp2',
	'fyear',
	'fbit2',
	'fbit22',
	'fbit64',
	'fenum',
	'fset',
	'ftinyblob',
	'fmediumblob',
	'flongblob',
	'ftext',
	'fblob',
	'fvarchar',
	'fvarbinary',
	'fchar',
	'fbinary',
	'fnull',
}

local field_indices = glue.index(test_fields)

local field_types = {
	fdecimal = 'decimal(8,2)',
	fnumeric = 'numeric(6,4)',
	ftinyint = 'tinyint',
	futinyint = 'tinyint unsigned',
	fsmallint = 'smallint',
	fusmallint = 'smallint unsigned',
	finteger = 'int',
	fuinteger = 'int unsigned',
	ffloat = 'float',
	fdouble = 'double',
	fdouble2 = 'double',
	fdouble3 = 'double',
	fdouble4 = 'double',
	freal = 'real',
	fbigint = 'bigint',
	fubigint = 'bigint unsigned',
	fmediumint = 'mediumint',
	fumediumint = 'mediumint unsigned',
	fdate = 'date',
	ftime = 'time(0)',
	ftime2 = 'time(6)',
	fdatetime = 'datetime(0)',
	fdatetime2 = 'datetime(6)',
	ftimestamp = 'timestamp(0) null',
	ftimestamp2 = 'timestamp(6) null',
	fyear = 'year',
	fbit2 = 'bit(2)',
	fbit22 = 'bit(22)',
	fbit64 = 'bit(64)',
	fenum = "enum('yes', 'no')",
	fset = "set('e1', 'e2', 'e3')",
	ftinyblob = 'tinyblob',
	fmediumblob = 'mediumblob',
	flongblob = 'longblob',
	ftext = 'text',
	fblob = 'blob',
	fvarchar = 'varchar(200)',
	fvarbinary = 'varbinary(200)',
	fchar = 'char(200)',
	fbinary = 'binary(20)',
	fnull = 'int'
}

local test_values = {
	fdecimal = '42.12',
	fnumeric = '42.1234',
	ftinyint = 42,
	futinyint = 255,
	fsmallint = 42,
	fusmallint = 65535,
	finteger = 42,
	fuinteger = 2^32-1,
	ffloat = tonumber(ffi.cast('float', 42.33)),
	fdouble = 42.33,
	fdouble2 = nil, --null from mysql 5.1.24+
	fdouble3 = nil, --null from mysql 5.1.24+
	fdouble4 = nil, --null from mysql 5.1.24+
	freal = 42.33,
	fbigint = 420LL,
	fubigint = 0ULL - 1,
	fmediumint = 440,
	fumediumint = 2^24-1,
	fdate = {year = 2013, month = 10, day = 05},
	ftime = {hour = 21, min = 30, sec = 15, frac = 0},
	ftime2 = {hour = 21, min = 30, sec = 16, frac = 123456},
	fdatetime = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 17, frac = 0},
	fdatetime2 = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 18, frac = 123456},
	ftimestamp = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 19, frac = 0},
	ftimestamp2 = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 20, frac = 123456},
	fyear = 2013,
	fbit2 = 2,
	fbit22 = 2 * 2^8 + 2,
	fbit64 = 2ULL * 2^(64-8) + 2 * 2^8 + 2,
	fenum = 'yes',
	fset = 'e2,e3',
	ftinyblob = 'tiny tiny blob',
	fmediumblob = 'medium blob',
	flongblob = 'loong blob',
	ftext = 'just a text',
	fblob = 'bloob',
	fvarchar = 'just a varchar',
	fvarbinary = 'a varbinary',
	fchar = 'a char',
	fbinary = 'a binary char\0\0\0\0\0\0\0',
	fnull = nil,
}

local set_values = {
	fdecimal = "'42.12'",
	fnumeric = "42.1234",
	ftinyint = "'42'",
	futinyint = "'255'",
	fsmallint = "42",
	fusmallint = "65535",
	finteger = "'42'",
	fuinteger = tostring(2^32-1),
	ffloat = "42.33",
	fdouble = "'42.33'",
	fdouble2 = "0/0",
	fdouble3 = "1/0",
	fdouble4 = "-1/0",
	freal = "42.33",
	fbigint = "'420'",
	fubigint = tostring(0ULL-1):sub(1,-4), --remove 'ULL'
	fmediumint = "440",
	fumediumint = tostring(2^24-1),
	fdate = "'2013-10-05'",
	ftime = "'21:30:15'",
	ftime2 = "'21:30:16.123456'",
	fdatetime = "'2013-10-05 21:30:17'",
	fdatetime2 = "'2013-10-05 21:30:18.123456'",
	ftimestamp = "'2013-10-05 21:30:19'",
	ftimestamp2 = "'2013-10-05 21:30:20.123456'",
	fyear = "2013",
	fbit2 = "b'10'",
	fbit22 = "b'1000000010'",
	fbit64 = "b'0000001000000000000000000000000000000000000000000000001000000010'",
	fenum = "'yes'",
	fset = "('e3,e2')",
	ftinyblob = "'tiny tiny blob'",
	fmediumblob = "'medium blob'",
	flongblob = "'loong blob'",
	ftext = "'just a text'",
	fblob = "'bloob'",
	fvarchar = "'just a varchar'",
	fvarbinary = "'a varbinary'",
	fchar = "'a char'",
	fbinary = "'a binary char'",
	fnull = "null"
}

local bind_types = {
	fdecimal = 'decimal(20)', --TODO: truncation
	fnumeric = 'numeric(20)',
	ftinyint = 'tinyint',
	futinyint = 'tinyint unsigned',
	fsmallint = 'smallint',
	fusmallint = 'smallint unsigned',
	finteger = 'int',
	fuinteger = 'int unsigned',
	ffloat = 'float',
	fdouble = 'double',
	fdouble2 = 'double',
	fdouble3 = 'double',
	fdouble4 = 'double',
	freal = 'real',
	fbigint = 'bigint',
	fubigint = 'bigint unsigned',
	fmediumint = 'mediumint',
	fumediumint = 'mediumint unsigned',
	fdate = 'date',
	ftime = 'time',
	ftime2 = 'time',
	fdatetime = 'datetime',
	fdatetime2 = 'datetime',
	ftimestamp = 'timestamp',
	ftimestamp2 = 'timestamp',
	fyear = 'year',
	fbit2 = 'bit(2)',
	fbit22 = 'bit(22)',
	fbit64 = 'bit(64)',
	fenum = 'enum(200)',
	fset = 'set(200)',
	ftinyblob = 'tinyblob(200)',
	fmediumblob = 'mediumblob(200)',
	flongblob = 'longblob(200)',
	ftext = 'text(200)',
	fblob = 'blob(200)',
	fvarchar = 'varchar(200)',
	fvarbinary = 'varbinary(200)',
	fchar = 'char(200)',
	fbinary = 'binary(200)',
	fnull = 'int',
}

--queries

local esc = "'escape me'"
print('conn:escape(          ', pp.format(esc), ')', '->', pp.format(conn:escape(esc)))
local q1 = 'drop table if exists binding_test'
print('conn:query(           ', pp.format(q1), ')', conn:query(q1))

local field_defs = ''
for i,field in ipairs(test_fields) do
	field_defs = field_defs .. field .. ' ' .. field_types[field] .. (i == #test_fields and '' or ', ')
end

local field_sets = ''
for i,field in ipairs(test_fields) do
	field_sets = field_sets .. field .. ' = ' .. set_values[field] .. (i == #test_fields and '' or ', ')
end

conn:query([[
create table binding_test ( ]] .. field_defs .. [[ );

insert into binding_test set ]] .. field_sets .. [[ ;

insert into binding_test values ();

select * from binding_test;
]])

--query info

print('conn:field_count()    ', '->', pp.format(conn:field_count()))
print('conn:affected_rows()  ', '->', pp.format(conn:affected_rows()))
print('conn:insert_id()      ', '->', conn:insert_id())
print('conn:errno()          ', '->', pp.format(conn:errno()))
print('conn:sqlstate()       ', '->', pp.format(conn:sqlstate()))
print('conn:warning_count()  ', '->', pp.format(conn:warning_count()))
print('conn:info()           ', '->', pp.format(conn:info()))
for i=1,3 do
print('conn:more_results()   ', '->', pp.format(conn:more_results())); assert(conn:more_results())
print('conn:next_result()    ', '->', pp.format(conn:next_result()))
end
assert(not conn:more_results())

--query results

local res = conn:store_result() --TODO: local res = conn:use_result()
print('conn:store_result()   ', '->', res)
print('res:row_count()       ', '->', pp.format(res:row_count())); assert(res:row_count() == 2)
print('res:field_count()     ', '->', pp.format(res:field_count())); assert(res:field_count() == #test_fields)
print('res:eof()             ', '->', pp.format(res:eof())); assert(res:eof() == true)
print('res:fields()          ', '->') print_fields(res:fields())
print('res:field_info(1)     ', '->', pp.format(res:field_info(1)))

--first row: fetch as array and test values
local row = assert(res:fetch'n')
print("res:fetch'n'          ", '->', pp.format(row))
for i,field in res:fields() do
	assert_deepequal(row[i], test_values[field.name])
end

--first row again: fetch as assoc. array and test values
print('res:seek(1)           ', '->', res:seek(1))
local row = assert(res:fetch'a')
print("res:fetch'a'         ", '->', pp.format(row))
for i,field in res:fields() do
	assert_deepequal(row[field.name], test_values[field.name])
end

--first row again: fetch unpacked and test values
print('res:seek(1)           ', '->', res:seek(1))
local function pack(_, ...)
	local t = {}
	for i=1,select('#', ...) do
		t[i] = select(i, ...)
	end
	return t
end
local row = pack(res:fetch())
print("res:fetch()           ", '-> packed: ', pp.format(row))
for i,field in res:fields() do
	assert_deepequal(row[i], test_values[field.name])
end

--first row again: print its values parsed and unparsed for comparison
res:seek(1)
local row = assert(res:fetch'n')
res:seek(1)
local row_s = assert(res:fetch'ns')
print()
print(fit('', 4, 'right') .. '  ' .. fit('field', 20) .. fit('unparsed', 40) .. '  ' .. 'parsed')
print(('-'):rep(4 + 2 + 20 + 40 + 40))
for i,field in res:fields() do
	print(fit(tostring(i), 4, 'right') .. '  ' .. fit(field.name, 20) .. fit(pp.format(row_s[i]), 40) .. '  ' .. pp.format(row[i]))
end
print()

--second row: all nulls
local row = assert(res:fetch'n')
print("res:fetch'n'          ", '->', pp.format(row))
assert(#row == 0)
for i=1,res:field_count() do
	assert(row[i] == nil)
end
assert(not res:fetch'n')

--all rows again: test iterator
res:seek(1)
local n = 0
for i,row in res:rows'nas' do
	n = n + 1
	assert(i == n)
end
print("for i,row in res:rows'nas' do <count-rows>", '->', n); assert(n == 2)

print('res:free()            ', res:free())

--reflection

print('res:list_dbs()        ', '->'); print_result(conn:list_dbs())
print('res:list_tables()     ', '->'); print_result(conn:list_tables())
print('res:list_processes()  ', '->'); print_result(conn:list_processes())

--prepared statements

local query = 'select '.. table.concat(test_fields, ', ')..' from binding_test'
local stmt = conn:prepare(query)

print('conn:prepare(         ', pp.format(query), ')', '->', stmt)
print('stmt:field_count()    ', '->', pp.format(stmt:field_count())); assert(stmt:field_count() == #test_fields)
--we can get the fields and their types before execution so we can create create our bind structures.
--max. length is not computed though, but length is, so we can use that.
print('stmt:fields()         ', '->'); print_fields(stmt:fields())

--binding phase

local btypes = {}
for i,field in ipairs(test_fields) do
	btypes[i] = bind_types[field]
end
local bind = stmt:bind_result(btypes)
print('stmt:bind_result(     ', pp.format(btypes), ')', '->', pp.format(bind))

--execution and loading

print('stmt:exec()           ', stmt:exec())
print('stmt:store_result()   ', stmt:store_result())

--result info

print('stmt:row_count()      ', '->', pp.format(stmt:row_count()))
print('stmt:affected_rows()  ', '->', pp.format(stmt:affected_rows()))
print('stmt:insert_id()      ', '->', pp.format(stmt:insert_id()))
print('stmt:sqlstate()       ', '->', pp.format(stmt:sqlstate()))

--result data (different API since we don't get a result object)

print('stmt:fetch()          ', stmt:fetch())

print('stmt:fields()         ', '->'); print_fields(stmt:fields())

print('bind:is_truncated(1)  ', '->', pp.format(bind:is_truncated(1))); assert(bind:is_truncated(1) == false)
print('bind:is_null(1)       ', '->', pp.format(bind:is_null(1))); assert(bind:is_null(1) == false)
print('bind:get(1)           ', '->', pp.format(bind:get(1))); assert(bind:get(1) == test_values.fdecimal)
local i = field_indices.fdate
print('bind:get_date(        ', i, ')', '->', bind:get_date(i)); assert_deepequal({bind:get_date(i)}, {2013, 10, 5})
local i = field_indices.ftime
print('bind:get_date(        ', i, ')', '->', bind:get_date(i)); assert_deepequal({bind:get_date(i)}, {nil, nil, nil, 21, 30, 15, 0})
local i = field_indices.fdatetime
print('bind:get_date(        ', '->', bind:get_date(i)); assert_deepequal({bind:get_date(i)}, {2013, 10, 5, 21, 30, 17, 0})
local i = field_indices.ftimestamp
print('bind:get_date(        ', '->', bind:get_date(i)); assert_deepequal({bind:get_date(i)}, {2013, 10, 5, 21, 30, 19, 0})
local i = field_indices.ftimestamp2
print('bind:get_date(        ', '->', bind:get_date(i)); assert_deepequal({bind:get_date(i)}, {2013, 10, 5, 21, 30, 20, 123456})
print('for i=1,bind.field_count do bind:get(i)', '->')

local function print_bind_buffer(bind)
	print()
	for i,field in ipairs(test_fields) do
		local v = bind:get(i)
		assert_deepequal(v, test_values[field])
		assert(bind:is_truncated(i) == false)
		assert(bind:is_null(i) == (test_values[field] == nil))
		print(fit(tostring(i), 4, 'right') .. '  ' .. fit(field, 20) .. pp.format(v))
	end
	print()
end
print_bind_buffer(bind)

print('stmt:free_result()    ', stmt:free_result())
--local next_result = stmt:next_result()
--print('stmt:next_result()    ', '->', pp.format(next_result)); assert(next_result == false)

print('stmt:reset()          ', stmt:reset())
print('stmt:close()          ', stmt:close())

--prepared statements with parameters

for i,field in ipairs(test_fields) do
	local query = 'select * from binding_test where '..field..' = ?'
	local stmt = conn:prepare(query)
	print('conn:prepare(         ', pp.format(query), ')')
	local param_bind_def = {bind_types[field]}

	local bind = stmt:bind_params(param_bind_def)
	print('stmt:bind_params      ', pp.format(param_bind_def))

	local function exec()
		print('stmt:exec()           ', stmt:exec())
		print('stmt:store_result()   ', stmt:store_result())
		print('stmt:row_count()      ', '->', stmt:row_count())
		assert(stmt:row_count() == 1) --libmariadb() returns 0
	end

	local v = test_values[field]
	if v ~= nil then
		print('bind:set(             ', 1, pp.format(v), ')'); bind:set(1, v); exec()

		if field:find'date' or field:find'time' then
			print('bind:set_date(     ', 1, v.year, v.month, v.day, v.hour, v.min, v.sec, v.frac, ')')
			bind:set_date(1, v.year, v.month, v.day, v.hour, v.min, v.sec, v.frac)
			exec() --libmariadb crashes the server
		end
	end
	print('stmt:close()          ', stmt:close())
end

--prepared statements with auto-allocated result bind buffers.

local query = 'select * from binding_test'
local stmt = conn:prepare(query)
local bind = stmt:bind_result()
--pp(stmt:bind_result_types())
stmt:exec()
stmt:store_result()
stmt:fetch()
print_bind_buffer(bind)
stmt:close()

local q = 'drop table binding_test'
print('conn:query(           ', pp.format(q), ')', conn:query(q))
print('conn:commit()         ', conn:commit())
print('conn:close()          ', conn:close())

