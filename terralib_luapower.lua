
--terralib luapower extensions.

assert(terra, 'terra not loaded')

local ffi = require'ffi'
local List = require'asdl'.List

terralib.terrahome = require'package.exedir'

terralib.low_includepath = terralib.terrahome..'/../../csrc'

--$ mgit clone mingw64-headers
local mingw64_headers_dir = terralib.low_includepath..'/mingw64-headers'

terra.systemincludes = List()
if ffi.os == 'Windows' then
	--Terra looks for Visual Studio headers by default but we use mingw64.
	terra.systemincludes:insertall {
		('%s/mingw64/include'):format(mingw64_headers_dir),
		('%s/mingw64/include-fixed'):format(mingw64_headers_dir),
		('%s/mingw32'):format(mingw64_headers_dir),
	}
elseif ffi.os == 'Linux' then
	--TODO:
	terra.systemincludes:insertall {
		 '/usr/lib/gcc/x86_64-linux-gnu/7/include',
		 '/usr/local/include',
		 '/usr/lib/gcc/x86_64-linux-gnu/7/include-fixed',
		 '/usr/include/x86_64-linux-gnu',
		 '/usr/include',
	}
elseif ffi.os == 'OSX' then
	--TODO:
end

--load Terra files from the same locations as Lua files.
package.terrapath = package.path:gsub('%.lua', '%.t')

--overload loadfile() to interpret *.t files as Terra code.
local lua_loadfile = loadfile
function loadfile(file)
	local loadfile = file:find'%.t$' and terra.loadfile or lua_loadfile
	return loadfile(file)
end

--make linklibrary work more portably like ffi.load() does.
local linklibrary = terralib.linklibrary

if ffi.os == 'Linux' then
	function terralib.linklibrary(filename)
		if not (filename:find'%.so$' or filename:find'/') then
			filename = 'lib'..filename..'.so'
		end
		return linklibrary(filename)
	end
elseif ffi.os == 'OSX' then
	function terralib.linklibrary(filename)
		if not (filename:find'%.dylib$' or filename:find'/') then
			filename = 'lib'..filename..'.dylib'
		end
		return linklibrary(filename)
	end
end
