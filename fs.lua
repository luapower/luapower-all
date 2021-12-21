
--portable filesystem API for LuaJIT
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fs_test'; return end

local ffi = require'ffi'
setfenv(1, require'fs_common')

if win then
	require'fs_win'
elseif linux or osx then
	require'fs_posix'
else
	error'platform not Windows, Linux or OSX'
end

ffi.metatype(stream_ct, {__index = stream})
ffi.metatype(dir_ct, {__index = dir})

return fs
