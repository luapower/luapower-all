local ffi = require'ffi'
local fs = require'fs'
local pp = require'pp'
local time = require'time'
local win = ffi.abi'win'
local linux = ffi.os == 'Linux'
local osx = ffi.os == 'OSX'
local x64 = ffi.arch == 'x64'

--if luapower sits on a VirtualBox shared folder on a Windows host
--we can't mmap files, create symlinks or use locking on that, so we'll use
--$HOME, which is usually a disk mount.
local prefix = win and '' or os.getenv'HOME'..'/'

local test = setmetatable({}, {__newindex = function(t, k, v)
	rawset(t, k, v)
	rawset(t, #t+1, k)
end})

--open/close -----------------------------------------------------------------

function test.open_close()
	local testfile = 'fs_testfile'
	local f = assert(fs.open(testfile, 'w'))
	assert(fs.isfile(f))
	assert(not f:closed())
	assert(f:close())
	assert(f:closed())
	assert(fs.remove(testfile))
end

function test.open_not_found()
	local nonexistent = 'this_file_should_not_exist'
	local f, err = fs.open(nonexistent)
	assert(not f)
	assert(err == 'not_found')
end

function test.open_already_exists_file()
	local testfile = 'fs_testfile'
	local f = assert(fs.open(testfile, 'w'))
	assert(f:close())
	local f, err = fs.open(testfile,
		win and {
			access = 'file_write',
			creation = 'create_new',
			flags = 'backup_semantics'
		} or {
			flags = 'creat excl'
		})
	assert(not f)
	assert(err == 'already_exists')
	assert(fs.remove(testfile))
end

function test.open_already_exists_dir()
	local testfile = 'fs_test_dir_already_exists'
	fs.remove(testfile)
	assert(fs.mkdir(testfile))
	local f, err = fs.open(testfile,
		win and {
			access = 'file_write',
			creation = 'create_new',
			flags = 'backup_semantics'
		} or {
			flags = 'creat excl'
		})
	assert(not f)
	assert(err == 'already_exists')
	assert(fs.remove(testfile))
end

function test.open_dir()
	local testfile = 'fs_test_dir'
	local using_backup_semantics = true
	fs.remove(testfile, true)
	assert(fs.mkdir(testfile))
	local f, err = fs.open(testfile)
	if win and not using_backup_semantics then
		--using `backup_semantics` flag on CreateFile allows us to upen
		--directories like in Linux, otherwise we'd get an access_denied error.
		--Need more testing to see if this flag does not create other problems.
		assert(not f)
		assert(err == 'access_denied')
	else
		assert(f)
		assert(f:close())
	end
	assert(fs.remove(testfile))
end

function test.wrap_file() --indirectly tests wrap_fd() and wrap_handle()
	local name = 'fs_test_wrap_file'
	os.remove(name)
	local F = io.open(name, 'w')
	F:write'hello'
	F:flush()
	local f = fs.wrap_file(F)
	assert(f:attr'size' == 5)
	F:close()
	os.remove(name)
end

--pipes ----------------------------------------------------------------------

function test.pipe() --I/O test in proc_test.lua
	local rf, wf = assert(fs.pipe())
	rf:close()
	wf:close()
end

function test.named_pipe() --I/O test in proc_test.lua
	local opt = 'rw' --'rw single_instance'
	local name = win and [[\\.\pipe\fs_test_pipe]] or 'fs_test_pipe'
	local p1 = assert(fs.pipe(name, opt))
	local p2 = assert(fs.pipe(name, opt))
	if win then
		print(p1.handle)
		print(p2.handle)
		p1:close()
		p2:close()
	end
end

--i/o ------------------------------------------------------------------------

function test.read_write()
	local testfile = 'fs_test_read_write'
	local sz = 4096
	local buf = ffi.new('uint8_t[?]', sz)

	--write some patterns
	local f = assert(fs.open(testfile, 'w'))
	for i=0,sz-1 do
		buf[i] = i
	end
	for i=1,4 do
		assert(f:write(buf, sz))
	end
	assert(f:close())

	--read them back
	local f = assert(fs.open(testfile))
	local t = {}
	while true do
		local readsz = assert(f:read(buf, sz))
		if readsz == 0 then break end
		t[#t+1] = ffi.string(buf, readsz)
	end
	assert(f:close())

	--check them out
	local s = table.concat(t)
	for i=1,#s do
		assert(s:byte(i) == (i-1) % 256)
	end

	assert(fs.remove(testfile))
end

function test.open_modes()
	local testfile = 'fs_test'
	--TODO:
	local f = assert(fs.open(testfile, 'w'))
	f:close()
	assert(fs.remove(testfile))
end

function test.seek()
	local testfile = 'fs_test'
	local f = assert(fs.open(testfile, 'w'))

	--test large file support by seeking out-of-bounds
	local newpos = x64 and 2^51 + 113 or 2^42 + 113
	local pos = assert(f:seek('set', newpos))
	assert(pos == newpos)
	local pos = assert(f:seek(-100))
	assert(pos == newpos -100)
	local pos = assert(f:seek('end', 100))
	assert(pos == 100)

	--write some data and check again
	local newpos = 1024^2
	local buf = ffi.new'char[1]'
	local pos = assert(f:seek('set', newpos))
	assert(pos == newpos) --seeked outside
	buf[0] = 0xaa
	f:write(buf, 1) --write outside cur
	local pos = assert(f:seek())
	assert(pos == newpos + 1) --cur advanced
	local pos = assert(f:seek('end'))
	assert(pos == newpos + 1) --end updated
	assert(f:seek'end' == newpos + 1)
	assert(f:close())

	assert(fs.remove(testfile))
end

--streams --------------------------------------------------------------------

function test.stream()
	local testfile = 'fs_test'
	local f = assert(assert(fs.open(testfile, 'w')):stream('w'))
	f:close()
	local f = assert(assert(fs.open(testfile, 'r')):stream('r'))
	f:close()
	assert(fs.remove(testfile))
end

--truncate -------------------------------------------------------------------

function test.truncate_seek()
	local testfile = 'fs_test_truncate_seek'
	--truncate/grow
	local f = assert(fs.open(testfile, 'w'))
	local newpos = 1024^2
	local pos = assert(f:seek(newpos))
	assert(pos == newpos)
	assert(f:truncate())
	local pos = assert(f:seek())
	assert(pos == newpos)
	assert(f:close())
	--check size
	local f = assert(fs.open(testfile, 'r+'))
	local pos = assert(f:seek'end')
	assert(pos == newpos)
	--truncate/shrink
	local pos = assert(f:seek('end', -100))
	assert(f:truncate())
	assert(pos == newpos - 100)
	assert(f:close())
	--check size
	local f = assert(fs.open(testfile, 'r'))
	local pos = assert(f:seek'end')
	assert(pos == newpos - 100)
	assert(f:close())

	assert(fs.remove(testfile))
end

function test.file_size_set()
	--TODO: test f:size(sz) and also fs.attr(path, {size=, sparse=})
end

--filesystem operations ------------------------------------------------------

function test.cd_mkdir_remove()
	local testdir = 'fs_test_dir'
	local cd = assert(fs.cd())
	assert(fs.mkdir(testdir)) --relative paths should work
	assert(fs.cd(testdir))   --relative paths should work
	assert(fs.cd(cd))
	assert(fs.cd() == cd)
	assert(fs.remove(testdir)) --relative paths should work
end

function test.mkdir_recursive()
	assert(fs.mkdir('fs_test_dir/a/b/c', true))
	assert(fs.remove'fs_test_dir/a/b/c')
	assert(fs.remove'fs_test_dir/a/b')
	assert(fs.remove'fs_test_dir/a')
	assert(fs.remove'fs_test_dir')
end

function test.remove_recursive()
	local rootdir = prefix..'fs_test_rmdir_rec/'
	fs.remove(rootdir, true)
	local function mkdir(dir)
		assert(fs.mkdir(rootdir..dir, true))
	end
	local function mkfile(file)
		local f = assert(fs.open(rootdir..file, 'w'))
		assert(f:close())
	end
	mkdir'a/b/c'
	mkfile'a/b/c/f1'
	mkfile'a/b/c/f2'
	mkdir'a/b/c/d1'
	mkdir'a/b/c/d2'
	mkfile'a/b/f1'
	mkfile'a/b/f2'
	mkdir'a/b/d1'
	mkdir'a/b/d2'
	assert(fs.remove(rootdir, true))
end

function test.dir_empty()
	local d = 'fs_test_dir_empty/a/b'
	fs.remove('fs_test_dir_empty/', true)
	fs.mkdir(d, true)
	for name in fs.dir(d) do
		print(name)
	end
	fs.remove('fs_test_dir_empty/', true)
end

function test.mkdir_already_exists_dir()
	assert(fs.mkdir'fs_test_dir')
	local ok, err = fs.mkdir'fs_test_dir'
	assert(not ok)
	assert(err == 'already_exists')
	assert(fs.remove'fs_test_dir')
end

function test.mkdir_already_exists_file()
	local testfile = 'fs_test_dir_already_exists_file'
	local f = assert(fs.open(testfile, 'w'))
	assert(f:close())
	local ok, err = fs.mkdir(testfile)
	assert(not ok)
	assert(err == 'already_exists')
	assert(fs.remove(testfile))
end

function test.mkdir_not_found()
	local ok, err = fs.mkdir'fs_test_nonexistent/nonexistent'
	assert(not ok)
	assert(err == 'not_found')
end

function test.remove_not_found()
	local testfile = 'fs_test_rmdir'
	local ok, err = fs.remove(testfile)
	assert(not ok)
	assert(err == 'not_found')
end

function test.remove_not_empty()
	local dir1 = 'fs_test_rmdir'
	local dir2 = 'fs_test_rmdir/subdir'
	fs.remove(dir2)
	fs.remove(dir1)
	assert(fs.mkdir(dir1))
	assert(fs.mkdir(dir2))
	local ok, err = fs.remove(dir1)
	assert(not ok)
	assert(err == 'not_empty')
	assert(fs.remove(dir2))
	assert(fs.remove(dir1))
end

function test.remove_file()
	local name = 'fs_test_remove_file'
	os.remove(name)
	assert(io.open(name, 'w')):close()
	assert(fs.remove(name))
	assert(not io.open(name, 'r'))
end

function test.cd_not_found()
	local ok, err = fs.cd'fs_test_nonexistent/nonexistent'
	assert(not ok)
	assert(err == 'not_found')
end

function test.remove()
	local testfile = 'fs_test_remove'
	local f = assert(fs.open(testfile, 'w'))
	assert(f:close())
	assert(fs.remove(testfile))
	assert(not fs.open(testfile))
end

function test.remove_not_found()
	local testfile = 'fs_test_remove'
	local ok, err = fs.remove(testfile)
	assert(not ok)
	assert(err == 'not_found')
end

function test.move()
	local f1 = 'fs_test_move1'
	local f2 = 'fs_test_move2'
	local f = assert(fs.open(f1, 'w'))
	assert(f:close())
	assert(fs.move(f1, f2))
	assert(fs.remove(f2))
	assert(not fs.remove(f1))
end

function test.move_not_found()
	local ok, err = fs.move('fs_nonexistent_file', 'fs_nonexistent2')
	assert(not ok)
	assert(err == 'not_found')
end

function test.move_replace()
	local f1 = 'fs_test_move1'
	local f2 = 'fs_test_move2'
	local buf = ffi.new'char[1]'

	local f = assert(fs.open(f1, 'w'))
	buf[0] = ('1'):byte(1)
	f:write(buf, 1)
	assert(f:close())

	local f = assert(fs.open(f2, 'w'))
	buf[0] = ('2'):byte(1)
	assert(f:write(buf, 1))
	assert(f:close())

	assert(fs.move(f1, f2))

	local f = assert(fs.open(f2))
	assert(f:read(buf, 1))
	assert(buf[0] == ('1'):byte(1))
	assert(f:close())

	assert(fs.remove(f2))
end

function test.remove_not_found()
	local ok, err = fs.remove'fs_non_existent'
	assert(not ok)
	assert(err == 'not_found')
end

--symlinks -------------------------------------------------------------------

local function mksymlink_file(f1, f2)
	local buf = ffi.new'char[1]'

	fs.remove(f1)
	fs.remove(f2)

	local f = assert(fs.open(f2, 'w'))
	buf[0] = ('X'):byte(1)
	f:write(buf, 1)
	assert(f:close())

	time.sleep(0.1)

	assert(fs.mksymlink(f1, f2))
	assert(fs.is(f1, 'symlink'))

	local f = assert(fs.open(f1))
	assert(f:read(buf, 1))
	assert(buf[0] == ('X'):byte(1))
	assert(f:close())
end

function test.mksymlink_file()
	local f1 = prefix..'fs_test_symlink_file'
	local f2 = prefix..'fs_test_symlink_file_target'
	fs.remove(f1)
	fs.remove(f2)
	mksymlink_file(f1, f2)
	assert(fs.is(f1, 'symlink'))
	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

function test.mksymlink_dir()
	local link = prefix..'fs_test_symlink_dir'
	local dir = prefix..'fs_test_symlink_dir_target'
	fs.remove(link)
	fs.remove(dir..'/test_dir')
	fs.remove(dir)
	assert(fs.mkdir(dir))
	assert(fs.mkdir(dir..'/test_dir'))
	assert(fs.mksymlink(link, dir, true))
	assert(fs.is(link..'/test_dir', 'dir'))
	assert(fs.remove(link..'/test_dir'))
	assert(fs.remove(link))
	assert(fs.remove(dir))
end

function test.readlink_file()
	local f1 = prefix..'fs_test_readlink_file'
	local f2 = prefix..'fs_test_readlink_file_target'
	mksymlink_file(f1, f2)
	assert(fs.readlink(f1) == f2)
	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

function test.readlink_dir()
	local d1 = prefix..'fs_test_readlink_dir'
	local d2 = prefix..'fs_test_readlink_dir_target'
	fs.remove(d1)
	fs.remove(d2..'/test_dir')
	fs.remove(d2)
	fs.remove(d2)
	assert(fs.mkdir(d2))
	assert(fs.mkdir(d2..'/test_dir'))
	assert(fs.mksymlink(d1, d2, true))
	assert(fs.is(d1, 'symlink'))
	local t = {}
	for d in fs.dir(d1) do
		t[#t+1] = d
	end
	assert(#t == 1)
	assert(t[1] == 'test_dir')
	assert(fs.remove(d1..'/test_dir'))
	assert(fs.readlink(d1) == d2)
	assert(fs.remove(d1))
	assert(fs.remove(d2))
end

--TODO: readlink() with relative symlink chain
--TODO: attr() with defer and symlink chain
--TODO: dir() with defer and symlink chain

function test.attr_deref()
	--
end

function test.symlink_attr_deref()
	local f1 = prefix..'fs_test_readlink_file'
	local f2 = prefix..'fs_test_readlink_file_target'
	mksymlink_file(f1, f2)
	local pp = require'pp'
	local lattr = assert(fs.attr(f1, false))
	local tattr1 = assert(fs.attr(f1, true))
	local tattr2 = assert(fs.attr(f2))
	assert(lattr.type == 'symlink')
	assert(tattr1.type == 'file')
	assert(tattr2.type == 'file')
	if win then
		assert(tattr1.id == tattr2.id) --same file
	else
		assert(tattr1.inode == tattr2.inode) --same file
	end
	assert(tattr1.btime == tattr2.btime)
	if win then
		assert(lattr.id ~= tattr1.id) --diff. file
	else
		assert(lattr.inode ~= tattr1.inode) --diff. file
	end
	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

--hardlinks ------------------------------------------------------------------

function test.mkhardlink() --hardlinks only work for files in NTFS
	local f1 = prefix..'fs_test_hardlink'
	local f2 = prefix..'fs_test_hardlink_target'
	fs.remove(f1)
	fs.remove(f2)

	local buf = ffi.new'char[1]'

	local f = assert(fs.open(f2, 'w'))
	buf[0] = ('X'):byte(1)
	f:write(buf, 1)
	assert(f:close())

	assert(fs.mkhardlink(f1, f2))

	local f = assert(fs.open(f1))
	assert(f:read(buf, 1))
	assert(buf[0] == ('X'):byte(1))
	assert(f:close())

	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

--file times -----------------------------------------------------------------

function test.times()
	local testfile = 'fs_test_time'
	fs.remove(testfile)
	local f = assert(fs.open(testfile, 'w'))
	local t = f:attr()
	assert(t.atime >= 0)
	assert(t.mtime >= 0)
	assert(win or t.ctime >= 0)
	assert(linux or t.btime >= 0)
	assert(f:close())
	assert(fs.remove(testfile))
end

function test.times_set()
	local testfile = 'fs_test_time'
	local f = assert(fs.open(testfile, 'w'))

	--TODO: futimes() on OSX doesn't use tv_usec
	local frac = osx and 0 or 1/2
	local btime = os.time() - 7200 - frac
	local mtime = os.time() - 3600 - frac
	local ctime = os.time() - 2800 - frac
	local atime = os.time() - 1800 - frac

	assert(f:attr{btime = btime, mtime = mtime, ctime = ctime, atime = atime})
	local btime1 = f:attr'btime' --OSX has it but can't be changed currently
	local mtime1 = f:attr'mtime'
	local ctime1 = f:attr'ctime'
	local atime1 = f:attr'atime'
	assert(mtime == mtime1)
	assert(atime == atime1)
	if win then
		assert(btime == btime1)
		assert(ctime == ctime1)
	end

	--change only mtime, should not affect atime
	mtime = mtime + 100
	assert(f:attr{mtime = mtime})
	local mtime1 = f:attr().mtime
	local atime1 = f:attr().atime
	assert(mtime == mtime1)
	assert(atime == atime1)

	--change only atime, should not affect mtime
	atime = atime + 100
	assert(f:attr{atime = atime})
	local mtime1 = f:attr'mtime'
	local atime1 = f:attr'atime'
	assert(mtime == mtime1)
	assert(atime == atime1)

	assert(f:close())
	assert(fs.remove(testfile))
end

--common paths ---------------------------------------------------------------

function test.paths()
	print('homedir', fs.homedir())
	print('tmpdir ', fs.tmpdir())
	print('exepath', fs.exepath())
	print('exedir' , fs.exedir())
end

--file attributes ------------------------------------------------------------

function test.attr()
	local testfile = 'fs_test.lua'
	local attr = assert(fs.attr(testfile, false))
	--pp(attr)
	assert(attr.type == 'file')
	assert(attr.size > 10000)
	assert(attr.atime)
	assert(attr.mtime)
	assert(linux and attr.ctime or attr.btime)
	assert(not win or attr.archive)
	if not win then
		assert(attr.inode)
		assert(attr.uid >= 0)
		assert(attr.gid >= 0)
		assert(attr.perms >= 0)
		assert(attr.nlink >= 1)
		assert(attr.perms > 0)
		assert(attr.blksize > 0)
		assert(attr.blocks > 0)
		assert(attr.dev >= 0)
	end
end

function test.attr_set()
	--TODO
end

--directory listing ----------------------------------------------------------

function test.dir()
	local found
	local n = 0
	local files = {}
	for file, d in fs.dir() do
		if not file then break end
		found = found or file == 'fs_test.lua'
		n = n + 1
		local t = {}
		files[file] = t
		--these are fast to get on all platforms
		t.type = d:attr('type', false)
		t.inode = d:attr('inode', false) --missing on Windows, so nil
		--these are free to get on Windows but need a stat() call on POSIX
		if win then
			t.btime = assert(d:attr('btime', false))
			t.mtime = assert(d:attr('mtime', false))
			t.atime = assert(d:attr('atime', false))
			t.size  = assert(d:attr('size' , false))
		end
		--getting all attrs is free on Windows but needs a stat() call on POSIX
		t._all_attrs = assert(d:attr(false))
		local noval, err = d:attr('non_existent_attr', false)
		assert(noval == nil) --non-existent attributes are free to get
		assert(not err) --and they are not an error
		--print('', d:attr('type', false), file)
	end
	assert(not files['.'])  --skipping this by default
	assert(not files['..']) --skipping this by default
	assert(files['fs_test.lua'].type == 'file')
	local t = files['fs_test.lua']
	print(string.format('  found %d dir/file entries in cwd', n))
	assert(found, 'fs_test.lua not found in cwd')
end

function test.dir_not_found()
	local n = 0
	local err
	for file, err1 in fs.dir'nonexistent_dir' do
		if not file then
			err = err1
			break
		else
			n = n + 1
		end
	end
	assert(n == 0)
	assert(#err > 0)
	assert(err == 'not_found')
end

function test.dir_is_file()
	local n = 0
	local err
	for file, err1 in fs.dir'fs_test.lua' do
		if not file then
			err = err1
			break
		else
			n = n + 1
		end
	end
	assert(n == 0)
	assert(#err > 0)
	assert(err == 'not_found')
end

--memory mapping -------------------------------------------------------------

--TODO: how to test for disk full on 32bit?
--TODO: offset + size -> invalid arg
--TODO: test flush() with invalid address and/or size (clamp them?)
--TODO: test exec flag by trying to execute code in it
--TODO: COW on opened file doesn't work on OSX
--TODO: test protect

local mediumsize = 1024^2 * 10 + 1 -- 10 MB + 1 byte to make it non-aligned

function test.pagesize()
	assert(fs.pagesize() > 0)
	assert(fs.pagesize() % 4096 == 0)
end

--[[

local function zerosize_file(filename)
	local file = filename or file
	os.remove(file)
	local f = assert(io.open(file, 'w'))
	f:close()
	return file
end

function test.filesize()
	local file = zerosize_file()
	assert(mmap.filesize(file) == 0)
	assert(mmap.filesize(file, 123) == 123) --grow
	assert(mmap.filesize(file) == 123)
	assert(mmap.filesize(file, 63) == 63) --shrink
	assert(mmap.filesize(file) == 63)
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
	assert(ffi.string(map.addr, 20):find'memory mapping')
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
	--TODO: COW on opened file doesn't work on OSX
	if ffi.os == 'OSX' then return end
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
	local map1 = assert(mmap.map{tagname = 'mmap_test',
		access = 'w', size = size})
	local map2 = assert(mmap.map{tagname = 'mmap_test',
		access = 'r', size = size})
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
	--TODO: test by exec'ing some code in the memory
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

--mmap failure modes

function test.filesize_disk_full()
	local file = zerosize_file()
	local size, errmsg, errcode = mmap.filesize(file, 1024^4)
	assert(not size and errcode == 'disk_full')
	local actual_size = mmap.filesize(file)
	assert(actual_size == 0) --file has the same size on error
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

function test.size_too_large()
	local size = 1024^3 * (ffi.abi'32bit' and 3 or 1024^3)
	local map, errmsg, errcode = mmap.map{access = 'w', size = size}
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

function test.map_disk_full()
	--TODO: how to test for disk full on 32bit? need a < 3G partition
	if ffi.abi'32bit' then return end
	local map, errmsg, errcode = mmap.map{
		file = file,
		size = 1024^4,
		access = 'w',
	}
	assert(not map and errcode == 'disk_full')
end
]]

--virtual files --------------------------------------------------------------

function test.open_buffer()
	local sz = 100
	local buf = ffi.new('char[?]', sz)
	ffi.fill(buf, sz, 42)
	local f = assert(fs.open_buffer(buf, sz, 'w'))
	assert(f:seek(100) == 100)
	assert(f:seek(100) == 200)
	assert(f:seek() == 200)
	assert(f:seek('end', 0) == 100)
	assert(f:seek('set', 0) == 0)
	local buf = ffi.new('char[?]', 100)
	assert(f:seek(200) == 200)
	assert(f:read(buf, 10) == 0)
	assert(f:seek('set', 50) == 50)
	assert(f:read(buf, 1000) == 50)
	assert(ffi.string(buf, 50) == (string.char(42):rep(50)))
	assert(f:write(buf, 1000) == 0)
	assert(f:seek('set', 0))
	ffi.fill(buf, sz, 43)
	assert(f:write(buf, 1000) == 100)
	assert(ffi.string(buf, 100) == (string.char(43):rep(100)))
	assert(f:close())
	assert(f:closed())
	assert(f:read(buf, 1000) == nil)
	assert(f:write(buf, 1000) == nil)
end

--test cmdline ---------------------------------------------------------------

local name = ...
if not name or name == 'fs_test' then
	--run all tests in the order in which they appear in the code.
	for i,k in ipairs(test) do
		if not k:find'^_' then
			print('test '..k)
			local ok, err = xpcall(test[k], debug.traceback)
			if not ok then
				print(err)
			end
		end
	end
elseif test[name] then
	test[name](select(2, ...))
else
	print('Unknown test "'..(name)..'".')
end
