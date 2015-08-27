local coro = require'coro'

local t = {}
coro.transfer(coro.create(function()
	local parent = coro.current
	local thread = coro.create(function()
		table.insert(t, 'sub')
	end)
	coro.transfer(thread)
	table.insert(t, 'back')
end))
assert(coro.current == coro.main)
assert(#t == 2)
assert(t[1] == 'sub')
assert(t[2] == 'back')

local t = {}
coro.transfer(coro.create(function()
	local parent = coro.current
	local thread = coro.wrap(function()
		for i=1,10 do
			coro.transfer(parent, i * i)
		end
	end)
	for s in thread do
		table.insert(t, s)
	end
end))
assert(coro.current == coro.main)
assert(#t == 10)
for i=1,10 do assert(t[i] == i * i) end
