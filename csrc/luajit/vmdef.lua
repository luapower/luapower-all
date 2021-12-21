local ffi = require'ffi'
if ffi.os == 'Windows' then
	return require'jit.vmdef_mingw64'
elseif ffi.os == 'Linux' then
	return require'jit.vmdef_linux64'
elseif ffi.os == 'OSX' then
	return require'jit.vmdef_osx64'
else
	error('jit.vmdef_'..ffi.os:lower()..' missing')
end
