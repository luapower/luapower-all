
local glue = require'glue'
local clock = require'time'.clock
local fs = require'fs'
local lx = require'lx'

local out = function(s) io.stdout:write(s) end
local printf = function(...) out(string.format(...)) end

local function test_speed_for(filename)
	local f = assert(fs.open(filename))
	local fs = assert(f:stream'rb')
	local ls = lx.lexer(fs, filename)

	local out = glue.noop
	local printf = glue.noop

	local t0 = clock()
	ls.next()
	ls.luastats()
	local n = ls.token_count()
	local ln = ls.line()
	local d = clock() - t0

	ls.free()
	fs:close()
	f:close()

	return d, n, ln
end

local function test_speed()
	local d, n, l = test_speed_for'ui.lua'
	print(string.format(
		'%.0fms %.2f Mtokens/s %.2f Mlines/s', d * 1000, n / d / 1e6, l / d / 1e6))
end

local function test_import()

	local s = [[
local a = 5
local b = 6
do
	import 'test1'
	local z = 3
	do
		local z = 4
		import 'test2'
		key2 z
		a = @ + a
	end
	local key1 f1 z
	--key2 y --error
	b = `2 * b
end
return a, b, f1
]]

local s1 = [[
import'test1'
   key1 zz bbbb = 2
]]

	local ls = lx.lexer(s)

	function ls.import(lang)
		if lang == 'test1' then
			return {
				keywords = {'key1'},
				entrypoints = {
					statement = {'key1'},
					expression = {'`'},
				},
				expression = function(self, kw, stmt)
					ls.next()
					if stmt then
						local name = ls.expectval'<name>'
						local refname = ls.expectval'<name>'
						ls.ref(refname)
						return function(env)
							--pp(env)
							return name..':'..env[refname]
						end, {name}
					else
						local expr = ls.luaexpr()
						return function(env)
							return expr(env)
						end
					end
				end,
			}
		elseif lang == 'test2' then
			return {
				keywords = {'key2'};
				entrypoints = {
					statement = {'key2'};
					expression = {'@'};
				};
				expression = function(self, kw, stmt)
					if stmt then
						ls.next()
						ls.ref(ls.expectval'<name>')
						return function(env)
							--pp(env)
							return 1
						end
					else
						ls.next()
						return function(env)
							--pp(env)
							return 1
						end
					end
				end,
			}
		end
	end

	--ls.next()
	--ls.luastats()
	--pp(ls.subst)

	local f = assert(ls.load())
	print(f())

end

local function test()
	local ls = lx.lexer'abc = 42'
	while true do
		local tk = ls.next()
		if tk == '<eof>' then break end
		print(tk, ls.filepos(), ls.len())
	end
end
--test()

test_speed()
test_import()
