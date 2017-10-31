local pp = require'pp'

if jit then
	local ffi = require'ffi'
	local n = ffi.new('int64_t', -1)
	assert(pp.format(n) == '-1LL')
	local un = ffi.new('uint64_t', -1)
	assert(pp.format(un) == '18446744073709551615ULL')
end

--escaping
assert(pp.format('\'"\t\n\r\b\0\1\2\31\32\33\125\126\127\128\255') ==
						[['\'"\t\n\r\8\0\1\2\31 !}~\127\128\255']])

--edge cases
assert(pp.format{} == '{}')

--recursion
assert(pp.format(
	 {1,2,3,a={4,5,6,b={c={d={e={f={7,8,9}}}}}}}, {sort_keys = true}) ==
	'{1,2,3,a={4,5,6,b={c={d={e={f={7,8,9}}}}}}}')

--table keys
assert(pp.format(
	 {[{[{[{[{[{[{}]='f'}]='e'}]='d'}]='c'}]='b'}]='a'}, {sort_keys = true}) ==
	"{[{[{[{[{[{[{}]='f'}]='e'}]='d'}]='c'}]='b'}]='a'}")

--indentation
local c = {[{'c'}] = 'c'}
local s1 = pp.format(
	{'a','b','c','d',a=1,b={a=1,b=2},[c]=c},
	{indent = '   ', sort_keys = true})
local s2 = [[
{
   'a',
   'b',
   'c',
   'd',
   a=1,
   b={
      a=1,
      b=2
   },
   [{
      [{
         'c'
      }]='c'
   }]={
      [{
         'c'
      }]='c'
   }
}]]
assert(s1 == s2)

--__pwrite metamethod
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
assert(pp.format(t) == "tuple(1,tuple(1,'zzz'))")

--__tostring metamethod
local t = {
	[setmetatable({}, {__tostring = function() return 'tostring_key' end})] =
		setmetatable({}, {__tostring = function() return 'tostring_val' end}),
}
assert(pp.format(t) == "{tostring_key='tostring_val'}")

--cycle detection
local t={a={}}; t.a=t
assert(pp.format(t,' ',{}) == [==[
{
 a=nil --[[cycle]]
}]==])
assert(pp.format({a=coroutine.create(function() end)},' ',{}) == [==[
{
 a=nil --[[unserializable thread]]
}]==])

--key sorting
local s = pp.format({
	[0] = '7', 5, 3, 1,
	[12] = 'a',
	[14.5] = 'b',	[1/0] = 'x',
	[-1/0] = 'y',
	a = 1, x = 7, p = 3,
	[true] = 'x', [false] = 'y',
	[{5, 6, 7}] = 'a',
	[{5, 6, 7}] = 'b',
	[{z = 5, a = 7}] = 'b',
	[{z = 4, a = 7}] = 'b',
	[setmetatable({}, {__tostring = function() return 'tostring_key' end})] =
		setmetatable({}, {__tostring = function() return 'tostring_val' end}),
}, {indent = ' ', sort_keys = true})
assert(s == [==[
{
 5,
 3,
 1,
 [false]='y',
 [true]='x',
 [-1/0]='y',
 [0]='7',
 [12]='a',
 [14.5]='b',
 [1/0]='x',
 a=1,
 p=3,
 tostring_key='tostring_val',
 x=7,
 [{
  5,
  6,
  7
 }]='a',
 [{
  5,
  6,
  7
 }]='b',
 [{
  a=7,
  z=4
 }]='b',
 [{
  a=7,
  z=5
 }]='b'
}]==])
