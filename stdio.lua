
--stdio binding (incomplete).
--Written by Cosmin Apreutesei. Public domain.

--Rationale: although the io.* library exposes FILE* handles, there's
--no API extension to work with buffers and avoid creating Lua strings.

local ffi = require'ffi'
require'stdio_h'
local M = setmetatable({C = ffi.C}, {__index = ffi.C})

local function checkh(h)
	if h ~= nil then return h end
	error(string.format('errno: %d', ffi.errno()))
end

local function str(s)
	return ffi.string(checkh(s))
end

local function checkz(ret)
	if ret == 0 then return end
	error(string.format('errno: %d', ffi.errno()))
end

local function zcaller(f)
	return function(...)
		checkz(f(...))
	end
end

function M.fopen(path, mode)
	return ffi.gc(checkh(ffi.C.fopen(path, mode or 'rb')), M.fclose)
end

function M.freopen(file, path, mode)
	return checkh(ffi.C.freopen(path, mode or 'rb', file))
end

function M.tmpfile()
	return ffi.gc(checkh(ffi.C.tmpfile()), M.fclose)
end

function M.tmpnam(prefix)
	return str(ffi.C.tmpnam(prefix))
end

function M.fclose(file)
	checkz(ffi.C.fclose(file))
	ffi.gc(file, nil)
end

local fileno = ffi.abi'win' and ffi.C._fileno or ffi.C.fileno
function M.fileno(file)
	local n = fileno(file)
	assert(n >= 0, 'fileno error')
	return n
end

M.fflush = zcaller(ffi.C.fflush)

--methods

ffi.metatype('FILE', {__index = {
	close = M.fclose,
	reopen = M.freopen,
	flush = M.fflush,
	no = M.fileno,
}})

--hi-level API

function M.readfile(file, format)
	local f = M.fopen(file, format=='t' and 'r' or 'rb')
	ffi.C.fseek(f, 0, ffi.C.SEEK_END)
	local sz = ffi.C.ftell(f)
	ffi.C.fseek(f, 0, ffi.C.SEEK_SET)
	local buf = ffi.new('uint8_t[?]', sz)
	ffi.C.fread(buf, 1, sz, f)
	f:close()
	return buf, sz
end

function M.writefile(file, data, sz, format)
	local f = M.fopen(file, format=='t' and 'w' or 'wb')
	ffi.C.fwrite(data, 1, sz, f)
	f:close()
end

return M
