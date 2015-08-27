
local ffi = require'ffi'

io.stdout:setvbuf'no'

local function test_load_all()
	require'strict'
	local glue = require'glue'
	local lp = require'luapower'

	lp.config('luapower_dir', glue.bin..'/../..')
	lp.config('auto_update_db', false)
	lp.config('allow_update_db_locally', false)

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

local function test_load_mysql()
	local mysql = require'mysql'
	mysql.config()
end

local platos = {Windows = 'mingw', Linux = 'linux', OSX = 'osx'}
local function current_platform()
	return platos[ffi.os]..(ffi.abi'32bit' and '32' or '64')
end

local function test_blob()
	local bundle = require'bundle'
	io.stdout:write'loading blob... '
	local s = bundle.load('.bundle-test/'..current_platform()..'/big.blob')
	print('ok ('..#s..' bytes)')
	assert(#s == 20*1024*1024+#'header'+#'footer')
	assert(s:find'^header')
	assert(s:sub(-#'footer') == 'footer')
end

test_load_all()
test_load_mysql()
test_blob()
