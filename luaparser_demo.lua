
local ffi = require'ffi'
local fs = require'fs'
local time = require'time'
local luaparser = require'luaparser'

local clock = time.clock()
local total_size = 0

local function lex(file)
	local f = assert(fs.open(file))
	local bufread = f:buffered_read()
	local function read(buf, sz)
		--return assert(bufread(buf, sz))
		return assert(f:read(buf, sz))
	end
	local lexer = luaparser.lexer(read, file)

	while true do
		local token, info, linenumber = lexer.next()
		if token == 'eos' then break end
	end

	f:close()
end

local function parse(file)
	local f = assert(fs.open(file))
	local bufread = f:buffered_read()
	local function read(buf, sz)
		return assert(f:read(buf, sz))
	end
	local lexer = luaparser.lexer(read, file)
	local parser = luaparser.parser(lexer)

	parser:parse()

	f:close()
end

local function parse_string(s)
	local function read(buf, sz)
		sz = math.min(#s, sz)
		if sz > 0 then
			ffi.copy(buf, s, sz)
			s = s:sub(sz + 1)
		end
		return sz
	end
	local lexer = luaparser.lexer(read, '[test]')
	local parser = luaparser.parser(lexer)
	parser:parse()
end

parse_string[[
a = 1
local a = 2

if a + 2 / 3 then

end

local function f()

end

]]

os.exit()

local files = 0
for f,d in fs.dir() do
	if d:is'file' and f:find'%.lua$' then
		if f ~= 'harfbuzz_ot_demo.lua' and not f:find'^_' then
			print(f)
			total_size = total_size + d:attr'size'
			files = files + 1
			--os.execute([[bin\mingw64\luajit.exe -b ]]..f..' _'..f)
			local ok, err
			if false then
				ok, err = loadfile(f)
			elseif false then
				ok, err = xpcall(lex, debug.traceback, f)
			else
				ok, err = xpcall(parse, debug.traceback, f)
			end
			if not ok then
				print(f, ok, err)
				break
			end
		end
	end
end

local size = total_size / 1024 / 1024
local duration = time.clock() - clock
local speed = size / duration
print(string.format('%d files, %.1f MB, %.1fs, %d MB/s',
	files, size, duration, speed))

