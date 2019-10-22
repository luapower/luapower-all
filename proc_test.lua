local proc = require'proc'
local ffi = require'ffi'
local time = require'time'
local glue = require'glue'
local fs = require'fs'
local pp = require'pp'
io.stdout:setvbuf'no'
io.stderr:setvbuf'no'

local tests = {}
local test = setmetatable({}, {__newindex = function(self, k, v)
	rawset(self, k, v)
	table.insert(tests, k)
end})

function test.env()
	proc.setenv('zz', '123')
	proc.setenv('zZ', '567')
	if ffi.abi'win' then
		assert(proc.env('zz') == '567')
		assert(proc.env('zZ') == '567')
	else
		assert(proc.env('zz') == '123')
		assert(proc.env('zZ') == '567')
	end
	proc.setenv('zz')
	proc.setenv('zZ')
	assert(not proc.env'zz')
	assert(not proc.env'zZ')
	proc.setenv('Zz', '321')
	local t = proc.env()
	pp(t)
	assert(t.Zz == '321')
end

function test.exec_luafile()
	local p = assert(proc.exec_luafile('test.lua'))
	p:forget()
end

function test.kill()
	local luajit = fs.exepath()

	local p, err, errno = proc.exec(
		luajit,
		{'-e', 'local n=.12; for i=1,1000000000 do n=n*0.5321 end; print(n); os.exit(123)'},
		--{'-e', 'print(os.getenv\'XX\', require\'fs\'.cd()); os.exit(123)'},
		{XX = 55},
		'bin'
	)
	if not p then print(err, errno) end
	assert(p)
	print('pid:', p.id)
	print'sleeping'
	time.sleep(.5)
	print'killing'
	assert(p:kill())
	assert(p:kill())
	time.sleep(.5)
	print('exit code', p:exit_code())
	print('exit code', p:exit_code())
	--assert(p:exit_code() == 123)
	p:forget()
end

function test.pipe()
	local in_rf , in_wf  = fs.pipe()
	local out_rf, out_wf = fs.pipe()
	local err_rf, err_wf = fs.pipe()
	assert(proc.exec_luafile(
		'test.lua', nil, nil, nil,
		in_rf, out_wf, err_wf))

	local s = '1234\n'
	in_wf:write(s, #s)

	local cb = ffi.new('char[1]')
	while out_rf:read(cb, ffi.sizeof(cb)) > 0 do
		local c = string.char(cb[0])
		io.stdout:write(c, ' ')
		if c == 'T' then
			print()
			break
		end
	end
end

function test_all()
	for i,k in ipairs(tests) do
		print'+--------------------------------------------------------------+'
		print(string.format('| %-60s |', k))
		print'+--------------------------------------------------------------+'
		test[k]()
	end
end

test.pipe()

--test_all()
