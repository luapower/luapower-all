local ffi = require'ffi'
local mmap = require'mmap'

local function zerosize_file(filename)
	local file = filename or 'mmap.tmp'
	os.remove(file)
	local f = assert(io.open(file, 'w'))
	f:close()
	return file
end

local function test_pagesize()
	assert(mmap.pagesize() > 0)
	assert(mmap.pagesize() % 4096 == 0)
end

local function test_filesize()
	local file = zerosize_file()
	assert(mmap.filesize(file) == 0)
	assert(mmap.filesize(file, 123) == 123)
	assert(mmap.filesize(file) == 123)
	os.remove(file)
end

local function test_filesize_not_found()
	os.remove'mmap.tmp'
	local size, errmsg, errcode = mmap.filesize'mmap.tmp'
	assert(not size and errcode == 'not_found')
end

local function test_filesize_disk_full()
	local size, errmsg, errcode = mmap.filesize('mmap.tmp', 1024^5)
	--TODO: this doesn't fail
	--assert(not size and errcode == 'disk_full')
end

local function test_written(map)
	local p = ffi.cast('int32_t*', map.addr)
	for i = 0, map.size/4-1 do
		assert(p[i] == i)
	end
end

local function test_write(map)
	local p = ffi.cast('int32_t*', map.addr)
	for i = 0, map.size/4-1 do
		p[i] = i
	end
	test_written(map)
end

local function map_invalid_size()
	local ok, err = pcall(mmap.map, {file = 'mmap.lua', size = 0})
	assert(not ok and err:find'size')
end

local function map_invalid_offset()
	local ok, err = pcall(mmap.map, {file = 'mmap.lua', offset = 1})
	assert(not ok and err:find'aligned')
end

local function map_invalid_address()
	local map, errmsg, errcode = mmap.map{size = mmap.pagesize() * 1,
		addr = mmap.pagesize()} --TODO: are low addresses always used?
	assert(not map and errcode == 'invalid_address')
end

local function map_swap()
	local map = assert(mmap.map{access = 'w', size = 1000})
	print(map.addr, map.size)
	test_write(map)
	map:free()
end

local function map_swap_too_short()
	local map, errmsg, errcode = mmap.map{access = 'w', size = 1024^4}
	assert(not map and errcode == 'file_too_short')
end

--TODO: this test only works on 32bit and if the swapfile is > 3G.
local function map_swap_out_of_mem()
	if not ffi.abi'32bit' then return end
	local map, errmsg, errcode = mmap.map{access = 'w', size = 2^30*3}
	assert(not map and errcode == 'out_of_mem')
end

local function map_file_readonly()
	local map = assert(mmap.map{file = 'mmap.lua'})
	print(map.addr, map.size)
	assert(ffi.string(map.addr, 20):find'--memory mapping')
	map:free()
end

local function map_file_readonly_not_found()
	local map, errmsg, errcode = mmap.map{file = 'askdfask8920349zjk'}
	assert(not map and errcode == 'not_found')
end

local function map_file_readonly_too_short()
	local map, errmsg, errcode = mmap.map{file = 'mmap.lua', size = 1024*100}
	assert(not map and errcode == 'file_too_short')
end

local function map_file_readonly_too_short_zero()
	local map, errmsg, errcode = mmap.map{file = zerosize_file()}
	assert(not map and errcode == 'file_too_short')
end

local function map_file_write_too_short_zero()
	local map, errmsg, errcode = mmap.map{file = zerosize_file(), access = 'w'}
	assert(not map and errcode == 'file_too_short')
end

local function map_file_exec()
	local map = assert(mmap.map{file = 'bin/mingw64/luajit.exe', access = 'x'})
	print(map.addr, map.size)
	assert(ffi.string(map.addr, 2) == 'MZ')
	map:free()
end

local function map_file_write()
	local map = assert(mmap.map{file = 'mmap.tmp', size = 1000, access = 'w'})
	print(map.addr, map.size)
	test_write(map)
	map:free()
	os.remove('mmap.tmp')
end

local function map_file_copy_on_write()
	local map = assert(mmap.map{file = 'mmap.tmp', size = 1000, access = 'w'})
	test_write(map)
	map:free()
	local map = assert(mmap.map{file = 'mmap.tmp', size = 1000, access = 'c'})
	print(map.addr, map.size)
	ffi.fill(map.addr, map.size, 123)
	map:flush(true)
	map:free()
	--check that the file wasn't altered by fill()
	local map = assert(mmap.map{file = 'mmap.tmp', size = 1000})
	test_written(map)
	map:free()
	os.remove('mmap.tmp')
end

local function map_file_write_disk_full()
	local map, errmsg, errcode = mmap.map{file = 'mmap.tmp', size = 1024^4, access = 'w'}
	assert(not map and errcode == 'disk_full')
end

local function map_file_write_same_name()
	local map1 = assert(mmap.map{name = 'mmap_test', access = 'w', size = 2*65536})
	local map2 = assert(mmap.map{name = 'mmap_test', access = 'w', size = 2*65536})
	assert(map1.addr ~= map2.addr)
	for i = 0,65535 do
		ffi.cast('uint16_t*', map1.addr)[i] = i
	end
	for i = 0,65535 do
		assert(ffi.cast('uint16_t*', map2.addr)[i] == i)
	end
	map1:free()
	map2:free()
end

local function map_file_write_offset()
	local file = 'mmap.tmp'
	local offset = mmap.pagesize()
	local map = assert(mmap.map{file = file, size = offset + 2, offset = 0, access = 'w'})
	print(map.addr, map.size)
	local p = ffi.cast('char*', map.addr)
	p[offset + 0] = 123
	p[offset + 1] = -123
	map:free()
	local map = assert(mmap.map{file = file, offset = offset, access = 'w'})
	print(map.addr, map.size)
	local p = ffi.cast('char*', map.addr)
	assert(p[0] == 123)
	assert(p[1] == -123)
	map:free()
	os.remove(file)
end

local function map_file_mirror()
	local times = 50
	local map = assert(mmap.mirror{file = 'mmap.tmp', times = times})
	print(map.addr, map.size)
	local addr = map.addr
	local p = ffi.cast('char*', addr)
	p[0] = 123
	for i = 1, times-1 do
		assert(p[i*map.size] == 123)
	end
	map:free()
	os.remove('mmap.tmp')
end

test_pagesize()
test_filesize()
map_swap()
map_file_exec()
map_file_write()
map_file_copy_on_write()
map_file_write_same_name()
map_file_write_offset()
map_file_mirror()

test_filesize_not_found()
test_filesize_disk_full()
map_invalid_size()
map_invalid_offset()
map_invalid_address()
map_swap_too_short()
map_swap_out_of_mem()
map_file_readonly()
map_file_readonly_not_found()
map_file_readonly_too_short()
map_file_readonly_too_short_zero()
map_file_write_too_short_zero()
map_file_write_disk_full()
