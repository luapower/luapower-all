
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
	ls:next()
	ls:luastats()
	local n = ls:token_count()
	local ln = ls:line()
	local d = clock() - t0

	ls:free()
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
do
	import 'test1'
	do
		import 'test2'
		key2 z
		a = @ + a
	end
	--key1 x
	--key2 y
	b = ` + b
end
]]

local s = [[
import'test1'
   key1 z b = 2
]]

	local ls = lx.lexer(s)

	function ls:import(lang)
		if lang == 'test1' then
			return {
				keywords = {'key1'};
				entrypoints = {
					statement = {'key1'};
					expression = {'`'};
				};
				statement = function(self, lx)
					lx:next()
					lx:ref(lx:expectval'<name>')
					return function()
						return 1
					end
				end,
				expression = function(self, lx)
					lx:next()
					return function()
						return 1
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
				statement = function(self, lx)
					lx:next()
					lx:ref(lx:expectval'<name>')
					return function()
						return 1
					end
				end,
				expression = function(self, lx)
					lx:next()
					return function()
						return 1
					end
				end,
			}
		end
	end

	--ls:next()
	--ls:luastats()
	--pp(ls.subst)

	local f = assert(ls:load())

end

local function test()
	local ls = lx.lexer'abc = 42'
	while true do
		local tk = ls:next()
		if tk == '<eof>' then break end
		print(tk, ls:filepos(), ls:len())
	end
end
--test()

--test_speed()
test_import()
