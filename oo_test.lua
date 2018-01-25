local oo = require'oo'

--inheritance
local c1 = oo.class()
c1.classname = 'c1'
c1.a = 1
c1.b = 1
local c2 = oo.class(c1)
c2.classname = 'c2'
c2.b = 2
c2.c = 2
assert(c2.super == c1)
assert(c2.unknown == nil)
assert(c2.a == 1)
assert(c2.b == 2)
assert(c2.c == 2)
assert(c2.init == c1.init)

--polymorphism
function c1:before_init(...) print('c1 before_init',...); self.b = ...; assert(self.b == 'o'); return self.b end
function c1:after_init() print('c1 after_init') end
function c2:before_init(...) print('c2 before_init',...); return ... end
function c2:after_init() print('c2 after_init') end
function c2:override_init(inherited, ...)
	print('c2 overriden init', ...)
	return inherited(self, ...)
end
assert(c2.init ~= c1.init)
local o = c2('o')
assert(o.a == 1)
assert(o.b == 'o')
assert(o.c == 2)
assert(o.super == c2)
assert(o.unknown == nil)

--arg passing through hooks
function c1:test_args(x, y) return x + y, x * y end
function c2:before_test_args(x, y) return x * 4, y * 4 end
function c2:after_test_args(x, y) return x / 2, y / 2 end
function c2:override_test_args(inherited, x, y)
	x, y = inherited(self, x * 10, y * 10)
	return x * 50, y * 50
end
local x, y = o:test_args(2, 3)
assert(x == (2 * 10 * 4 + 3 * 10 * 4) / 2 * 50)
assert(y == (2 * 10 * 4 * 3 * 10 * 4) / 2 * 50)

--virtual properties
function o:get_x() assert(self.__x == 42) return self.__x end
function o:set_x(x) assert(x == 42) self.__x = x end
o.x = 42
assert(o.x == 42)

--stored properties
function o:set_s(s) print('set_s', s) assert(s == 13) end
o.s = 13
assert(o.s == 13)
assert(o.state.s == 13)

--registering
local MyClass = oo.MyClass()
assert(MyClass == oo.MyClass)
assert(MyClass.classname == 'MyClass')
local MySubClass = oo.MySubClass'MyClass'
assert(MySubClass == oo.MySubClass)
assert(MySubClass.classname == 'MySubClass')
assert(MySubClass.super == MyClass)

--events

local MyClass = oo.MyClass()
local obj = MyClass()
local n = 0
local t = {}
local function handler_func(order)
	return function(self, a, b, c)
		assert(a == 3)
		assert(b == 5)
		assert(c == nil)
		n = n + 1
		table.insert(t, order)
	end
end

obj:on('testing.ns1', handler_func(2))
obj:on('testing.ns2', handler_func(3))
obj:on('testing.ns3', handler_func(4))
obj.testing = handler_func(1)

obj:fire('testing', 3, 5)
assert(#t == 4)
assert(t[1] == 1)
assert(t[2] == 2)
assert(t[3] == 3)
assert(t[4] == 4)

t = {}
obj:off'.ns2'
obj:fire('testing', 3, 5)
assert(#t == 3)
assert(t[1] == 1)
assert(t[2] == 2)
assert(t[3] == 4)

t = {}
obj:off'testing'
obj:fire('testing', 3, 5)
assert(#t == 1)
assert(t[1] == 1)

--inspect
print'-------------- (before collapsing) -----------------'
o:inspect()

--detach
o:detach()
assert(rawget(o, 'a') == 1)
assert(rawget(o, 'b') == 'o')
assert(rawget(o, 'c') == 2)

--inherit, not overriding
local c3 = oo.class()
c3.c = 3
o:inherit(c3)
assert(o.c == 2)

--inherit, overriding
o:inherit(c3, true)
assert(o.c == 3)

print'--------------- (after collapsing) -----------------'
o:inspect()

