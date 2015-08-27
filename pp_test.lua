local pp = require'pp'

if bit then --how else to identify if we're running luajit?
	local ffi = require'ffi'
	local n = ffi.new('int64_t', -1)
	print(pp.format(n))
	local un = ffi.new('uint64_t', -1)
	print(pp.format(un))
end

print(pp.format('\'"\t\n\r\b\0\1\2\31\32\33\125\126\127\128\255'))
print(pp.format({1,2,3,a={4,5,6,b={c={d={e={f={7,8,9}}}}}}}))
print(pp.format({[{[{[{[{[{[{}]='f'}]='e'}]='d'}]='c'}]='b'}]='a',}))
print(pp.format{})
local c = {[{'c'}] = 'c'}
print(pp.format({'a','b','c','d',a=1,b={a=1,b=2},[c]=c}, '   '))
local meta={}
local meta2={}
local t2=setmetatable({a=1,b='zzz'},meta2)
local t=setmetatable({a=1,b=t2},meta)
meta.__pwrite = function(v, write, write_value)
	write'tuple('; write_value(v.a); write','; write_value(v.b); write')'
end
meta2.__pwrite = function(v, write, write_value)
	write'tuple('; write_value(v.a); write','; write_value(v.b); write')'
end
print(pp.format(t))
local t={a={}}; t.a=t; print(pp.format(t,' ',{}))
print(pp.format({a=coroutine.create(function() end)},' ',{}))
