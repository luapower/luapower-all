
--portable filesystem API for LuaJIT
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
setfenv(1, require'fs_common')

local backends = {
	Windows = 'fs_win',
	OSX     = 'fs_posix',
	Linux   = 'fs_posix',
}
require(assert(backends[ffi.os], 'unsupported platform'))

ffi.metatype(file_ct, {__index = file})
ffi.metatype(stream_ct, {__index = stream})

return fs
