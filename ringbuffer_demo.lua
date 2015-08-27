local ringbuffer = require'ringbuffer'
local ffi = require'ffi'
local rand = math.random

io.stdout:setvbuf'no'
math.randomseed(os.time())

local b = ringbuffer{ctype = 'char', size = 5, read = function() end}

local function randstr(n)
	return string.char(rand(('A'):byte(), ('Z'):byte())):rep(n)
end

for i = 0, b.size-1 do
	b.data[i] = string.byte('.')
end

for i = 1, 30 do
	local cmd, s, n
	::cont::
	if rand() > .5 then
		cmd = 'push'
		local free = b.size - b.length
		local need = math.max(1, free)
		b:checksize(need)
		n = math.floor(rand(1, need))
		s = randstr(math.abs(n))
		b:push(n, ffi.cast('const char*', s))
	else
		cmd = 'pull'
		if b.length == 0 then goto cont end
	 	n = math.floor(rand(1, b.length))
	 	s = nil
		b:pull(n)
	end
	local i1, n1, i2, n2 = b:free_segments()
	for i = 0, n1-1 do b.data[i1+i] = string.byte('.') end
	for i = 0, n2-1 do b.data[i2+i] = string.byte('.') end
	local ds = ffi.string(b.data, b.size)
	local i1, n1, i2, n2 = b:segments()
	print(string.format('%s %s %3d: %2d+%2d, %2d+%2d  %s', ds, cmd, n, i1, n1, i2, n2, s or ''))
end

