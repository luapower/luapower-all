--go@ mgit bundle-test

local ffi = require'ffi'

io.stdout:setvbuf'no'

local function test_load_all()
	require'strict'
	local glue = require'glue'
	local lp = require'luapower'

	lp.luapower_dir = glue.bin..'/../..'
	lp.auto_update_db = false
	lp.allow_update_db_locally = false

	--warming up the cache
	io.stdout:write'loading module list... '
	for mod in pairs(lp.modules()) do
		lp.module_platforms(mod)
	end
	print'ok'

	io.stdout:write'loading modules... '
	local m = 0
	for mod in glue.sortedpairs(lp.modules()) do
		if lp.module_platforms(mod)[lp.current_platform()] then
			local ok, err = pcall(require, mod)
			if not ok then
				print(mod, err)
			else
				m = m + 1
			end
		end
	end
	print('ok ('..m..')')
end

local platos = {Windows = 'mingw', Linux = 'linux', OSX = 'osx'}
local function current_platform()
	return platos[ffi.os]..(ffi.abi'32bit' and '32' or '64')
end

local function test_blob()
	local bundle = require'bundle'
	io.stdout:write'loading blob... '
	local blobfile = '.bundle-test/'..current_platform()..'/big.blob'
	local filesize = 20*1024*1024+#'header'+#'footer'

	local s = assert(bundle.load(blobfile))
	assert(#s == filesize)
	assert(s:find'^header')
	assert(s:sub(-#'footer') == 'footer')

	local f = assert(bundle.fs_open(blobfile))
	local buf = ffi.new'char[6]'
	assert(f:seek(0) == 0)
	assert(f:read(buf, 6) == 6)
	assert(ffi.string(buf, 6) == 'header')
	assert(f:seek('end', -6) == filesize - 6)
	assert(f:read(buf, 6) == 6)
	assert(ffi.string(buf, 6) == 'footer')
	f:close()

	print('ok ('..#s..' bytes)')
end

local function test_dir()
	local bundle = require'bundle'
	print'loading dir listing for .mgit...'
	for name, d in bundle.fs_dir'.mgit' do
		if not name then
			print('error: '..d)
			break
		else
			print(string.format("%-8s %-30s %s", d:attr'type', d:name(), d:path()))
		end
	end
end

--test_load_all()
test_blob()
test_dir()
