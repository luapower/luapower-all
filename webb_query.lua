--[==[

	webb | mysql query function
	Written by Cosmin Apreutesei. Public Domain.

PREPROCESSOR

	sqlpp                                          sqlpp instance, for extending.

	sqlval(s) -> s                                 quote string to SQL literal
	sqlname(s) -> s                                quote string to SQL identifier
	sqlparams(s, t) -> s                           quote query with :name placeholders.
	sqlquery(s, t) -> s                            quote query with any preprocessor directives.
	sqlrows(rows[, opt]) -> s                      quote rows to SQL insert values list
	sql_default                                    placeholder for default value
	qsubst(typedef)                                create a substitution definition
	qmacro.<name> = f(args...)                     create a macro definition

EXECUTION

	db(ns) -> db                                   get a sqlpp connection
	create_schema([ns])                            create database schema
	[db:]query([opt,]sql, ...) -> rows             query and return rows in a table
	[db:]first_row([opt,]sql, ...) -> t            query and return first row or value
	[db:]each_row([opt,]sql, ...) -> iter          query and iterate rows
	[db:]each_row_vals([opt,]sql, ...) -> iter     query and iterate rows unpacked
	[db:]each_group(col, [opt,]sql, ...) -> iter   query, group rows and and iterate groups
	[db:]atomic(func)                              execute func in transaction

DDL

	[db:]table_def(tbl) -> def                     table definition
	[db:]drop_table(name)                          drop table
	[db:]drop_tables('T1 T2 ...')                  drop multiple tables
	[db:]add_column(tbl, name, type, pos)          add column
	[db:]rename_column(tbl, old_name, new_name)    rename column
	[db:]drop_column(tbl, col)                     remove column
	[db:][re]add_fk(tbl, col, ...)                 (re)create foreign key
	[db:][re]add_uk(tbl, col)                      (re)create unique key
	[db:][re]add_ix(tbl, col)                      (re)create index
	[db:]drop_fk(tbl, col)                         drop foreign key
	[db:]drop_uk(tbl, col)                         drop unique key
	[db:]drop_ix(tbl, col)                         drop index
	[db:][re]add_trigger(name, tbl, on, code)      (re)create trigger
	[db:]drop_trigger(name, tbl, on)               drop trigger
	[db:][re]add_proc(name, args, code)            (re)create stored proc
	[db:]drop_proc(name)                           drop stored proc
	[db:][re]add_column_locks(tbl, cols)           trigger to make columns read-only

DEBUGGING

	pqr(rows, cols)                                pretty-print query result

]==]

require'webb'
sqlpp = require'sqlpp'.new()
require'sqlpp_mysql'
sqlpp.require'mysql'
sqlpp.require'mysql_domains'
local mysql_print = require'mysql_client_print'
local pool = require'connpool'.new{log = webb.log}

sqlpp.keywords[null] = 'null'
sql_default = sqlpp.keyword.default
qsubst = sqlpp.subst
qmacro = sqlpp.macro

local function pconfig(ns, k, default)
	if ns then
		return config(ns..'_'..k, config(k, default))
	else
		return config(k, default)
	end
end

function dbschema(ns)
	local default = assert(config'app_name')..(ns and '_'..ns or '')
	return pconfig(ns, 'db_schema', default)
end

local conn_opt = memoize(function(ns)
	local t = {}
	t.host      = pconfig(ns, 'db_host', '127.0.0.1')
	t.port      = pconfig(ns, 'db_port', 3306)
	t.user      = pconfig(ns, 'db_user', 'root')
	t.password  = pconfig(ns, 'db_pass')
	t.schema    = dbschema(ns)
	t.charset   = 'utf8mb4'
	t.pool_key = t.host..':'..t.port..':'..(t.schema or '')
	return t
end)

function db(ns, without_schema)
	ns = ns or false
	local opt = conn_opt(ns)
	local key = opt.pool_key
	local thread = currentthread()
	local env = attr(threadenv, thread)
	local dbs = env.dbs
	if not dbs then
		dbs = {}
		env.dbs = dbs
		onthreadfinish(thread, function()
			for _,db in pairs(dbs) do
				db:release()
			end
		end)
	end
	local db, err = dbs[key]
	if not db then
		db, err = pool:get(key)
		if not db then
			if err == 'empty' then
				local schema = opt.schema
				if without_schema then
					opt = update({}, opt)
					opt.schema = nil
				end
				db = sqlpp.connect(opt)
				pool:put(key, db, db.rawconn.tcp)
				dbs[key] = db
			else
				assert(nil, err)
			end
		end
	end
	return db
end

function create_schema(ns)
	local db = db(ns, true)
	local schema = dbschema(ns)
	db:create_schema(schema)
	db:use(schema)
end

function sqlpp.fk_message_remove()
	return S('fk_message_remove', 'Cannot remove {foreign_entity}: remove any associated {entity} first.')
end

function sqlpp.fk_message_set()
	return S('fk_message_set', 'Cannot set {entity}: {foreign_entity} not found in database.')
end

for method, name in pairs{
	--preprocessor
	sqlval=1, sqlrows=1, sqlname=1, sqlparams=1, sqlquery=1,
	--query execution
	use='use_schema', query=1, first_row=1, each_row=1, each_row_vals=1, each_group=1,
	atomic=1,
	--ddl
	table_def=1,
	drop_table=1, drop_tables=1,
	add_column=1, rename_column=1, drop_column=1,
	add_fk=1, readd_fk=1, drop_fk=1,
	add_uk=1, readd_uk=1, drop_uk=1,
	add_ix=1, readd_ix=1, drop_ix=1,
	add_trigger=1, readd_trigger=1, drop_trigger=1,
	add_proc=1, read_proc=1, drop_proc=1,
	add_column_locks=1, readd_column_locks=1,
	--mdl
	insert_row=1, insert_or_update_row=1, update_row=1, delete_row=1,
} do
	name = type(name) == 'string' and name or method
	_G[name] = function(...)
		local db = db()
		return db[method](db, ...)
	end
end

function pqr(rows, cols)
	return mysql_print.result(rows, cols)
end
