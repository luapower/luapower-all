local terra = require'terra'
local ffi = require'ffi'

print('terra.terrahome   : ', terra.terrahome)
print('terra.cudahome    : ', terra.cudahome)
print('package.terrapath : ', package.terrapath)
print('terra.includepath : ', terra.includepath)

<<<<<<< HEAD
=======
terra.includepath = ''

>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
if ffi.os == 'OSX' then
	local sdkver = '10.10'
	local devpath = '/Applications/Xcode.app/Contents/Developer'
	local xctpath = devpath..'/Toolchains/XcodeDefault.xctoolchain'
	local sdkpath = string.format(devpath
		..'/Platforms/MacOSX.platform/Developer/SDKs/MacOSX'
		..sdkver..'.sdk')
<<<<<<< HEAD
	terra.includepath = ''
		..xctpath..'/usr/bin/../lib/clang/6.0/include;'
		..xctpath..'/usr/include;'
		..sdkpath..'/usr/include;'
		..sdkpath..'/System/Library/Frameworks'
elseif ffi.os == 'Windows' then
	--terra.includepath = [[C:\tools\mingw64\x86_64-w64-mingw32\include]]
	terra.includepath = [[C:\tools\mingw64\x86_64-w64-mingw32\include]]
	--terra.includepath = [[c:\vse2013\VC\include]]
=======
	terra.includepath = terra.includepath
		--..';'..xctpath..'/usr/bin/../lib/clang/6.0/include'
		--..';'..xctpath..'/usr/include'
		..';'..sdkpath..'/usr/include'
elseif ffi.os == 'Windows' then
	if ffi.abi'32bit' then
		terra.includepath = terra.includepath..
			';C:/tools/mingw32/i686-w64-mingw32/include'
	else
		terra.includepath = terra.includepath..
			';C:/tools/mingw64/x86_64-w64-mingw32/include'
	end
elseif ffi.os == 'Linux' then
	terra.includepath = terra.includepath..';/usr/include'
>>>>>>> d17849af2aaabad79f8193e42b4dc3d3c7554545
end

print('terra.includepath : ', terra.includepath)

require'terra_test_t'

terra.loadstring([[

C = terralib.includec("stdio.h")

terra hello()
	C.printf'hello from Terra\n'
end

hello()
print'hello from Lua'

]])()
