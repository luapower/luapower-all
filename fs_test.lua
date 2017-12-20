local ffi = require'ffi'
local fs = require'fs'
local pp = require'pp'
local time = require'time'
local win = ffi.abi'win'
local linux = ffi.os == 'Linux'
local osx = ffi.os == 'OSX'

local test = setmetatable({}, {__newindex = function(t, k, v)
	rawset(t, k, v)
	rawset(t, #t+1, k)
end})

--open/close -----------------------------------------------------------------

function test.open_close()
	local testfile = 'fs_test_file'
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
	local testfile = 'fs_test_file'
	local f = assert(fs.open(testfile, 'w'))
	assert(f:close())
	local f, err = fs.open(testfile,
		win and {
			access = 'write',
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
	fs.rmdir(testfile)
	assert(fs.mkdir(testfile))
	local f, err = fs.open(testfile,
		win and {
			access = 'write',
			creation = 'create_new',
			flags = 'backup_semantics'
		} or {
			flags = 'creat excl'
		})
	assert(not f)
	assert(err == 'already_exists')
	assert(fs.rmdir(testfile))
end

function test.open_dir()
	local testfile = 'fs_test_dir'
	local using_backup_semantics = true
	fs.rmdir(testfile)
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
	assert(fs.rmdir(testfile))
end

--i/o ------------------------------------------------------------------------

function test.read_write()
	local test_file = 'fs_test_read_write'
	local sz = 4096
	local buf = ffi.new('uint8_t[?]', sz)

	--write some patterns
	local f = assert(fs.open(test_file, 'w'))
	for i=0,sz-1 do
		buf[i] = i
	end
	for i=1,4 do
		assert(f:write(buf, sz))
	end
	assert(f:close())

	--read them back
	local f = assert(fs.open(test_file))
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

	assert(fs.remove(test_file))
end

function test.open_modes()
	local test_file = 'fs_test'
	--TODO:
	local f = assert(fs.open(test_file, 'w'))
	f:close()
	assert(fs.remove(test_file))
end

function test.seek_size()
	local test_file = 'fs_test'
	local f = assert(fs.open(test_file, 'w'))

	--test large file support by seeking out-of-bounds
	local newpos = 2^51 + 113
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
	assert(f:attr'size' == newpos + 1)
	assert(f:close())

	assert(fs.remove(test_file))
end

--streams --------------------------------------------------------------------

function test.stream()
	local test_file = 'fs_test'
	local f = assert(assert(fs.open(test_file, 'w')):stream('w'))
	f:close()
	local f = assert(assert(fs.open(test_file, 'r')):stream('r'))
	f:close()
	assert(fs.remove(test_file))
end

--truncate -------------------------------------------------------------------

function test.truncate_seek()
	local test_file = 'fs_test_truncate_seek'
	--truncate/grow
	local f = assert(fs.open(test_file, 'w'))
	local newpos = 1024^2
	local pos = assert(f:seek(newpos))
	assert(pos == newpos)
	assert(f:truncate())
	local pos = assert(f:seek())
	assert(pos == newpos)
	assert(f:close())
	--check size
	local f = assert(fs.open(test_file, 'r+'))
	local pos = assert(f:seek'end')
	assert(pos == newpos)
	--truncate/shrink
	local pos = assert(f:seek('end', -100))
	assert(f:truncate())
	assert(pos == newpos - 100)
	assert(f:close())
	--check size
	local f = assert(fs.open(test_file, 'r'))
	local pos = assert(f:seek'end')
	assert(pos == newpos - 100)
	assert(f:close())

	assert(fs.remove(test_file))
end

function test.file_size_set()
	--TODO: test f:size(sz) and also fs.attr(path, {size=, sparse=})
end

--filesystem operations ------------------------------------------------------

function test.cd_mkdir_rmdir()
	local testdir = 'fs_test_dir'
	local cd = assert(fs.cd())
	assert(fs.mkdir(testdir)) --relative paths should work
	assert(fs.cd(testdir))   --relative paths should work
	assert(fs.cd(cd))
	assert(fs.cd() == cd)
	assert(fs.rmdir(testdir)) --relative paths should work
end

function test.mkdir_recursive()
	assert(fs.mkdir('fs_test_dir/a/b/c', true))
	assert(fs.rmdir'fs_test_dir/a/b/c')
	assert(fs.rmdir'fs_test_dir/a/b')
	assert(fs.rmdir'fs_test_dir/a')
	assert(fs.rmdir'fs_test_dir')
end

function test.rmdir_recursive()
	local rootdir = 'fs_test_rmdir_rec/'
	fs.rmdir(rootdir, true)
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
	assert(fs.rmdir(rootdir, true))
end

function test.mkdir_already_exists_dir()
	assert(fs.mkdir'fs_test_dir')
	local ok, err = fs.mkdir'fs_test_dir'
	assert(not ok)
	assert(err == 'already_exists')
	assert(fs.rmdir'fs_test_dir')
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

function test.rmdir_not_found()
	local testfile = 'fs_test_rmdir'
	local ok, err = fs.rmdir(testfile)
	assert(not ok)
	assert(err == 'not_found')
end

function test.rmdir_not_empty()
	local dir1 = 'fs_test_rmdir'
	local dir2 = 'fs_test_rmdir/subdir'
	fs.rmdir(dir2)
	fs.rmdir(dir1)
	assert(fs.mkdir(dir1))
	assert(fs.mkdir(dir2))
	local ok, err = fs.rmdir(dir1)
	assert(not ok)
	assert(err == 'not_empty')
	assert(fs.rmdir(dir2))
	assert(fs.rmdir(dir1))
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

function test.remove_dir_access_denied()
	local testfile = 'fs_test_remove_dir'
	fs.rmdir(testfile)
	assert(fs.mkdir(testfile))
	local ok, err = fs.remove(testfile)
	assert(not ok)
	assert(err == 'access_denied')
	assert(fs.rmdir(testfile))
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
	local prefix = win and '' or os.getenv'HOME'..'/'
	local f1 = prefix..'fs_test_symlink_file'
	local f2 = prefix..'fs_test_symlink_file_target'
	fs.remove(f1)
	fs.remove(f2)
	mksymlink_file(f1, f2)
	assert(fs.is(f1, 'symlink'))
	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

local function mksymlink_dir(d1, d2)
	fs.rmdir(d1)
	fs.rmdir(d2..'/test_dir')
	fs.rmdir(d2)

	assert(fs.mkdir(d2..'/test_dir', true))
	assert(fs.mksymlink(d1, d2, true))
	assert(fs.is(d1, 'symlink'))
	local t = {}
	for d in fs.dir(d1) do
		t[#t+1] = d
	end
	assert(#t == 1)
	assert(t[1] == 'test_dir')
	assert(fs.rmdir(d1..'/test_dir'))
end

function test.mksymlink_dir()
	local d1 = 'fs_test_symlink_dir'
	local d2 = 'fs_test_symlink_dir_target'
	mksymlink_dir(d1, d2)
	assert(fs.rmdir(d1))
	assert(fs.rmdir(d2))
end

function test.readlink_file()
	local f1 = 'fs_test_readlink_file'
	local f2 = 'fs_test_readlink_file_target'
	mksymlink_file(f1, f2)
	assert(fs.readlink(f1) == f2)
	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

function test.readlink_dir()
	local d1 = 'fs_test_readlink_dir'
	local d2 = 'fs_test_readlink_dir_target'
	mksymlink_dir(d1, d2)
	assert(fs.readlink(d1) == d2)
	assert(fs.rmdir(d1))
	assert(fs.rmdir(d2))
end

--TODO: readlink() with relative symlink chain
--TODO: attr() with defer and symlink chain
--TODO: dir() with defer and symlink chain

function test.attr_deref()
	--
end

function test.symlink_attr_deref()
	local f1 = 'fs_test_readlink_file'
	local f2 = 'fs_test_readlink_file_target'
	mksymlink_file(f1, f2)
	local pp = require'pp'
	pp(fs.attr(f1, nil, false))
	pp(fs.attr(f1, nil, true))
	pp(fs.attr(f2))
	assert(fs.remove(f1))
	assert(fs.remove(f2))
end

--hardlinks ------------------------------------------------------------------

function test.mkhardlink() --hardlinks only work for files in NTFS
	local f1 = 'fs_test_hardlink'
	local f2 = 'fs_test_hardlink_target'
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

--[==[

--file times -----------------------------------------------------------------

function test.times()
	local test_file = 'fs_test_time'
	fs.remove'fs_test_time'
	local f = assert(fs.open(test_file, 'w'))
	local t = f:times()
	assert(t.atime >= 0)
	assert(t.mtime >= 0)
	assert(win or t.ctime >= 0)
	assert(linux or t.btime >= 0)
	assert(f:close())
end

function test.times_set()
	local test_file = 'fs_test_time'
	local f = assert(fs.open(test_file, 'w'))

	--TODO: futimes() on OSX doesn't use tv_usec
	local frac = osx and 0 or 1/2
	local mtime = os.time() - 3600 - frac
	local atime = os.time() - 1800 - frac
	local btime = os.time() - 7200 - frac

	assert(f:times{mtime = mtime, atime = atime, btime = btime})
	local mtime1 = f:times'mtime'
	local atime1 = f:times'atime'
	local btime1 = f:times'btime' --OSX has it but can't be changed currently
	assert(mtime == mtime1)
	assert(atime == atime1)
	if win then assert(btime == btime1) end

	--change only mtime, should not affect atime
	mtime = mtime + 100
	assert(f:times('mtime', mtime))
	local mtime1 = f:times().mtime
	local atime1 = f:times().atime
	assert(mtime == mtime1)
	assert(atime == atime1)

	--change only atime, should not affect mtime
	atime = atime + 100
	assert(f:times{atime = atime})
	local mtime1 = f:times'mtime'
	local atime1 = f:times'atime'
	assert(mtime == mtime1)
	assert(atime == atime1)

	assert(f:close())
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
	print(string.format('  found %d dir/file entries in pwd', n))
	assert(found, 'fs_test.lua not found in pwd')
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

--file attributes ------------------------------------------------------------

function test.attr()
	local testfile = 'fs_test.lua'
	local attr = assert(fs.attr(testfile, false))
	pp(attr)
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

]==]

--test cmdline ---------------------------------------------------------------

if not ... or ... == 'fs_test' then
	--run all tests in the order in which they appear in the code.
	for i,k in ipairs(test) do
		print('test '..k)
		local ok, err = xpcall(test[k], debug.traceback)
		if not ok then
			print(err)
		end
	end
elseif test[...] then
	test[...]()
else
	print('Unknown test "'..(...)..'".')
end
