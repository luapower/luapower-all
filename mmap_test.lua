
--TODO: offset + size -> invalid arg
--TODO: test flush() with invalid address and/or size (clamp them?)
--TODO: test exec flag by trying to execute code in it

local ffi = require'ffi'
local mmap = require'mmap'

local test = setmetatable({}, {__newindex = function(t, k, v)
	rawset(t, k, v)
	rawset(t, #t+1, k)
end})

local mediumsize = 1024^2 * 10 + 1 -- 10 MB + 1 byte to make it non-aligned

local file = 'mmap.tmp'
if ffi.os ~= 'Windows' then
	--if luapower sits on a VirtualBox shared folder on a Windows host
	--we can't mmap files from that, so we'll use $HOME, which is usually
	--a normal mount.
	file = os.getenv'HOME'..'/'..file
end
os.remove(file)

local function zerosize_file(filename)
	local file = filename or file
	os.remove(file)
	local f = assert(io.open(file, 'w'))
	f:close()
	return file
end

function test.pagesize()
	assert(mmap.pagesize() > 0)
	assert(mmap.pagesize() % 4096 == 0)
end

function test.filesize()
	local file = zerosize_file()
	assert(mmap.filesize(file) == 0)
	assert(mmap.filesize(file, 123) == 123)
	assert(mmap.filesize(file) == 123)
	os.remove(file)
end

local function fill(map)
	assert(map.size/4 <= 2^32)
	local p = ffi.cast('int32_t*', map.addr)
	for i = 0, map.size/4-1 do
		p[i] = i
	end
end

local function check_filled(map, offset)
	local offset = (offset or 0) / 4
	local p = ffi.cast('int32_t*', map.addr)
	for i = 0, map.size/4-1 do
		assert(p[i] == i + offset)
	end
end

local function check_empty(map)
	local p = ffi.cast('int32_t*', map.addr)
	for i = 0, map.size/4-1 do
		assert(p[i] == 0)
	end
end

function test.anonymous_write(size)
	local map = assert(mmap.map{access = 'w', size = size or mediumsize})
	check_empty(map)
	fill(map)
	check_filled(map)
	map:free()
end

--NOTE: there's no point in making an unshareable read-only mapping.
function test.anonymous_readonly_empty()
	local map = assert(mmap.map{access = 'r', size = mediumsize})
	check_empty(map)
	map:free()
end

function test.file_read()
	local map = assert(mmap.map{file = 'mmap.lua'})
	assert(ffi.string(map.addr, 20):find'--memory mapping')
	map:free()
end

function test.file_write()
	os.remove(file)
	local map1 = assert(mmap.map{file = file, size = mediumsize, access = 'w'})
	fill(map1)
	map1:free()
	local map2 = assert(mmap.map{file = file, access = 'r'})
	check_filled(map2)
	map2:free()
	os.remove(file)
end

function test.file_write_live()
	os.remove(file)
	local map1 = assert(mmap.map{file = file, size = mediumsize, access = 'w'})
	local map2 = assert(mmap.map{file = file, access = 'r'})
	fill(map1)
	map1:flush()
	check_filled(map2)
	map1:free()
	map2:free()
	os.remove(file)
end

function test.file_copy_on_write()
	os.remove(file)
	local size = mediumsize
	local map = assert(mmap.map{file = file, access = 'w', size = size})
	fill(map)
	map:free()
	local map = assert(mmap.map{file = file, access = 'c'})
	assert(map.size == size)
	ffi.fill(map.addr, map.size, 123)
	map:flush()
	map:free()
	--check that the file wasn't altered by fill()
	local map = assert(mmap.map{file = file})
	assert(map.size == size)
	check_filled(map)
	map:free()
	os.remove(file)
end

function test.file_copy_on_write_live()
	os.remove(file)
	local size = mediumsize
	local mapw = assert(mmap.map{file = file, access = 'w', size = size})
	local mapc = assert(mmap.map{file = file, access = 'c'})
	local mapr = assert(mmap.map{file = file, access = 'r'})
	assert(mapw.size == size)
	assert(mapc.size == size)
	assert(mapr.size == size)
	fill(mapw)
	mapw:flush()
	check_filled(mapc) --COW mapping sees writes from W mapping.
	ffi.fill(mapc.addr, mapc.size, 123)
	mapc:flush()
	for i=0,size-1 do
		assert(ffi.cast('char*', mapc.addr)[i] == 123)
	end
	check_filled(mapw) --W mapping doesn't see writes from COW mapping.
	check_filled(mapr) --R mapping doesn't see writes from COW mapping.
	mapw:free()
	mapc:free()
	mapr:free()
	os.remove(file)
end

function test.shared_via_tagname()
	local size = mediumsize
	local map1 = assert(mmap.map{tagname = 'mmap_test', access = 'w', size = size})
	local map2 = assert(mmap.map{tagname = 'mmap_test', access = 'r', size = size})
	map1:unlink() --can be called while mappings are alive.
	map2:unlink() --no-op if file not found.
	assert(map1.addr ~= map2.addr)
	assert(map1.size == map2.size)
	fill(map1)
	map1:flush()
	check_filled(map2)
	map1:free()
	map2:free()
end

function test.file_exec()
	--TODO: test by exec'ing code
	local map = assert(mmap.map{file = 'bin/mingw64/luajit.exe', access = 'x'})
	assert(ffi.string(map.addr, 2) == 'MZ')
	map:free()
end

function test.offset_live()
	os.remove(file)
	local offset = mmap.pagesize()
	local size = offset * 2
	local map1 = assert(mmap.map{file = file, size = size, access = 'w'})
	local map2 = assert(mmap.map{file = file, offset = offset})
	fill(map1)
	map1:flush()
	check_filled(map2, offset)
	map1:free()
	map2:free()
	os.remove(file)
end

function test.mirror()
	os.remove(file)
	local times = 50
	local map = assert(mmap.mirror{file = file, times = times})
	local addr = map.addr
	local p = ffi.cast('char*', addr)
	p[0] = 123
	for i = 1, times-1 do
		assert(p[i*map.size] == 123)
	end
	map:free()
	os.remove(file)
end

--test failure modes ---------------------------------------------------------

function test.filesize_not_found()
	os.remove(file)
	local size, errmsg, errcode = mmap.filesize(file)
	assert(not size and errcode == 'not_found')
end

function test.filesize_disk_full()
	local size, errmsg, errcode = mmap.filesize(file, 1024^5)
	--TODO: this doesn't fail
	--assert(not size and errcode == 'disk_full')
end

function test.invalid_size()
	local ok, err = pcall(mmap.map, {file = 'mmap.lua', size = 0})
	assert(not ok and err:find'size')
end

function test.invalid_offset()
	local ok, err = pcall(mmap.map, {file = 'mmap.lua', offset = 1})
	assert(not ok and err:find'aligned')
end

function test.invalid_address()
	local map, errmsg, errcode = mmap.map{size = mmap.pagesize() * 1,
		addr = ffi.os == 'Windows' and mmap.pagesize()  --TODO: not robust
			or ffi.cast('uintptr_t', -mmap.pagesize()),  --TODO: not robust
	}
	assert(not map and errcode == 'out_of_mem')
end

function test.swap_too_short()
	local map, errmsg, errcode = mmap.map{access = 'w', size = 1024^4}
	assert(not map and errcode == 'file_too_short')
end

--TODO: this test only works on 32bit and if the swapfile is > 3G.
function test.swap_out_of_mem()
	if not ffi.abi'32bit' then return end
	local map, errmsg, errcode = mmap.map{access = 'w', size = 2^30*3}
	assert(not map and errcode == 'out_of_mem')
end

function test.readonly_not_found()
	local map, errmsg, errcode = mmap.map{file = 'askdfask8920349zjk'}
	assert(not map and errcode == 'not_found')
end

function test.readonly_too_short()
	local map, errmsg, errcode = mmap.map{file = 'mmap.lua', size = 1024*1000}
	assert(not map and errcode == 'file_too_short')
end

function test.readonly_too_short_zero()
	local map, errmsg, errcode = mmap.map{file = zerosize_file()}
	assert(not map and errcode == 'file_too_short')
end

function test.write_too_short_zero()
	local map, errmsg, errcode = mmap.map{file = zerosize_file(), access = 'w'}
	assert(not map and errcode == 'file_too_short')
end

function test.disk_full_windows()
	if ffi.os ~= 'Windows' then return end
	local map, errmsg, errcode = mmap.map{file = file,
		size = 1024^4 * 16 - 1,
		access = 'w'}
	assert(not map and errcode == 'disk_full')
end

function test.out_of_mem_windows()
	if ffi.os ~= 'Windows' then return end
	local map, errmsg, errcode = mmap.map{file = file,
		size = 1024^4 * 16,
		access = 'w'}
	assert(not map and errcode == 'out_of_mem')
end

function test.disk_full_linux()
	if ffi.os ~= 'Linux' then return end
	local map, errmsg, errcode = mmap.map{file = file,
		size = 1024^5, --1024 TB
		access = 'w'}
	assert(not map and errcode == 'disk_full')
end

function test.out_of_mem_linux()
	if ffi.os ~= 'Linux' then return end
	--TODO
end


if not ... or ... == 'mmap_test' then
	--run all tests in the order in which they appear in the code.
	for i,k in ipairs(test) do
		print('test '..k)
		test[k]()
	end
else
	test[...]()
end
