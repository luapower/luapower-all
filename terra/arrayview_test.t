
setfenv(1, require'terra/low')

local s = 'Hello World!\0'
terra test()
	var buf = alloc(int8, [#s])
	copy(buf, s, [#s])
	var v: arrview(int8)
	v:onrawstring(buf)
	print(v.len)
	print(v:at(11))
	print(v:at(12, nil))
	print(v(11))
	print(v(12, -1))
	for i,v in v do
		fprintf(stdout(), '%d ', @v)
	end
	print()
	var v2 = v:sub(0, v.len)
	v:sort()
	v:reverse()
	for i,v in v2:backwards() do
		fprintf(stdout(), '%d ', @v)
	end
	print()
	assert(v == v2)
	v2.len = v2.len - 1
	assert(v ~= v2)
	assert(v > v2)
	assert(v >= v2)
	assert(not (v < v2))
	assert(not (v <= v2))
end
test()
