
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
	proc.env('zz', '123')
	proc.env('zZ', '567')
	if ffi.abi'win' then
		assert(proc.env('zz') == '567')
		assert(proc.env('zZ') == '567')
	else
		assert(proc.env('zz') == '123')
		assert(proc.env('zZ') == '567')
	end
	proc.env('zz', false)
	proc.env('zZ', false)
	assert(not proc.env'zz')
	assert(not proc.env'zZ')
	proc.env('Zz', '321')
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
		{luajit, '-e', 'local n=.12; for i=1,1000000000 do n=n*0.5321 end; print(n); os.exit(123)'},
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

	io.stdin:setvbuf'no'
	io.stdout:setvbuf'no'
	io.stderr:setvbuf'no'

	assert(glue.writefile('proc_test_pipe.lua', [[
io.stdin:setvbuf'no'
io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
n = io.stdin:read('*n')
io.stderr:write'Error\r\n\r\n'
print'Hello'
os.exit(123)
]]))

	local p = assert(proc.exec_luafile({
		script = 'proc_test_pipe.lua',
		stdin = in_rf,
		stdout = out_wf,
		--stderr = err_wf,
		autokill = true,
	}))

	--required to avoid hanging.
	in_rf:close()
	out_wf:close()
	err_wf:close()

	local s = '1234\n'
	in_wf:write(s)
	in_wf:close()

	local cb = ffi.new('uint8_t[1]')
	while true do
		local rlen, err = out_rf:read(cb, 1)
		if not rlen or rlen == 0 then
			break
		end
		local c = string.char(cb[0])
		io.stdout:write(c)
	end

	print('exit code', p:wait(1/0))

	assert(os.remove('proc_test_pipe.lua'))
end

function test.pipe_async()

	local sock = require'sock'

	io.stdin:setvbuf'no'
	io.stdout:setvbuf'no'
	io.stderr:setvbuf'no'

	assert(glue.writefile('proc_test_pipe.lua', [[
io.stdin:setvbuf'no'
io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
local time = require'time'
time.sleep(.1)
print'Started'
time.sleep(.1)
local n = assert(io.stdin:read('*n'))
print('Got '..n)
time.sleep(.1)
io.stderr:write'Error1\n'
time.sleep(.1)
print'Hello1'
time.sleep(.1)
io.stderr:write'Error2\n'
time.sleep(.1)
print'Hello2'
io.stderr:write'Error3\n'
time.sleep(.1)
print'Hello3'
time.sleep(.1)
os.exit(123)
]]))

	local char_vla, sz = ffi.typeof'char[?]', 1024

	sock.run(function()

		local p = assert(proc.exec_luafile({
			script = 'proc_test_pipe.lua',
			async = true,
			stdin = true,
			stdout = true,
			stderr = true,
			autokill = true,
		}))

		if p.stdin then
			sock.thread(function()
				local s = '1234\n'
				assert(p.stdin:write(s))
				p.stdin:close()
			end)
		end

		if p.stdout then
			sock.thread(function()
				local buf = char_vla(sz)
				while true do
					local len = assert(p.stdout:read(buf, sz))
					if len > 0 then
						io.stdout:write(ffi.string(buf, len))
					else
						p.stdout:close()
						break
					end
				end
			end)
		end

		if p.stderr then
			sock.thread(function()
				local buf = char_vla(sz)
				while true do
					local len = assert(p.stderr:read(buf, sz))
					if len > 0 then
						io.stdout:write(ffi.string(buf, len))
					else
						p.stderr:close()
						break
					end
				end
			end)
		end

		print('Process finished. Exit code:', p:wait(1/0))

		while
			   (p.stdin  and not p.stdin :closed())
			or (p.stdout and not p.stdout:closed())
			or (p.stderr and not p.stderr:closed())
		do
			print'Still waiting for the pipes to close...'
			print(glue.catargs(' ',
				p.stdin  and not p.stdin :closed() and 'stdin' or nil,
				p.stdout and not p.stdout:closed() and 'stdout' or nil,
				p.stderr and not p.stderr:closed() and 'stderr' or nil
			))
			sock.sleep(.1)
		end

		assert(os.remove('proc_test_pipe.lua'))

	end)

end

function test.autokill()
	if ffi.abi'win' then
		assert(proc.exec{cmd = 'notepad', autokill = true})
		print'waiting 1s'
		time.sleep(1)
	else
		assert(proc.exec{cmd = '/bin/sleep 123', autokill = true})
		print'waiting 5s'
		time.sleep(5)
	end
	print'done'
end

function test_all()
	for i,k in ipairs(tests) do
		print'+--------------------------------------------------------------+'
		print(string.format('| %-60s |', k))
		print'+--------------------------------------------------------------+'
		test[k]()
	end
end

function test.esc()
	if ffi.abi'win' then
		assert(proc.quote_arg[[a\"xx"yx\\\]] == [["a\\\"xx\"yx\\\\\\"]])
	else
		--TODO
	end
end

test.env()
test.esc()
--test.pipe()
test.pipe_async()
--test.autokill()
--test_all()
