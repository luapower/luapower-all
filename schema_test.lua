
local function sc1()

	import'schema_std'

	tables.t0 = { --to be removed
		f1, id, pk,
	}

	tables.t1 = { --to be modified
		f1, idpk, ix, fk(t0),
		f2, name, uk'f2 desc', check 'a < b',
	}

	trigger(foo, after, insert, t1, mysql [[ --to be removed
		dude wasup;
	]])

end

local function sc2()

	import'schema_std'

	tables.t1 = { --to be modified
		f1, id,
		f2, bigid, pk, check 'a <= b', ix,
		f3, name, uk, fk(t1),
	}

	tables.t2 = { --to be added
		f0, name,
		f1, id, pk'f1 desc', uk'f0,f1 desc', ix'f0 desc,f1 desc', check 'a > b',
	}

	trigger(foo, after, insert, t2, mysql [[
		dude wasup again;
	]])

	proc(foobar, {arg1, int, out, arg2, uint8}, mysql [[
		foobar;
	]])

end

local schema = require'schema'
local spp = require'sqlpp'.new'mysql'

local sc = schema.new()
require'webb_auth'
require'webb_lang'
local auth_schema = webb.auth_schema
local lang_schema = webb.lang_schema

local getfenv = getfenv
local pairs = pairs
local print = print
local update = glue.update

sc:import(function()
	import'schema_std'
	--for k, v in pairs(getfenv()) do print(k) end
	--types.int = {}
	--tables.t1 = {xx, int}

	import(auth_schema)
	import(lang_schema)

	tables.blah = {
		id, pk,
		name, name,
	}
end)

webb.run(function()

	if true then
		local st1 = {
			engine = 'mysql',
			relevant_field_attrs = {
				digits=1,
				decimals=1,
				size=1, --not relevant for numbers, mysql_type is enough.
				maxlen=1,
				unsigned=1,
				not_null=1,
				auto_increment=1,
				comment=1,
				mysql_type=1,
				mysql_charset=1,
				mysql_collation=1,
				mysql_default=1,
			},
			supports_fks = true,
			supports_checks = true,
			supports_triggers = true,
			supports_procs = true,
		}
		local st2 = update({}, st1)
		local sc1 = schema.new(st1):import(sc1)
		local sc2 = schema.new(st2):import(sc2)
		local d = schema.diff(sc1, sc2)
		--pp(d)
		d:pp()
	end

	if false then

		local cn = assert(spp.connect{
			host = '127.0.0.1',
			port = 3307,
			user = 'root',
			password = 'root',
			db = 'sp',
			charset = 'utf8mb4',
		})

		local dbsc = cn:extract_schema('sp')
		--pp(sc.tables.addr)
		--pp(sc.procs)

		local diff = schema.diff(cn:empty_schema(), sc)
		diff:pp{
			--hide_attrs = {mysql_collation=1, mysql_default=1},
		}

	end


end)
