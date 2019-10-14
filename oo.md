---
tagline: fancy object system
---

## `local oo = require'oo'`

Object system with virtual properties and method overriding hooks.

## In a nutshell

 * single, dynamic inheritance by default:
   * `Fruit = oo.Fruit()`
   * `Apple = oo.Apple(Fruit, {carpels = 5})`
	* `Apple.carpels -> 5` (class field)
   * `apple = Apple(...)`
   * `apple.carpels -> 5` (serves as default value)
	* `apple.super -> Apple`
   * `Apple.super -> Fruit`
   * `apple.isApple, apple.isFruit, Apple.isApple, Apple.isFruit -> true`
 * multiple, static inheritance by request:
   * `Apple:inherit(Fruit[,replace])` - statically inherit `Fruit`,
	  optionally replacing existing properties.
   * `Apple:detach()` - detach from the parent class, in other words
	  statically inherit `self.super`.
 * virtual properties with getter and setter:
   * reading `apple.foo` calls `Apple:get_foo()` to get the value, if
	  `apple.get_foo` is defined.
   * assignment to `apple.foo` calls `Apple:set_foo(value)` if
	  `Apple.set_foo` is defined.
   * missing the setter, the property is considered read-only and the
	  assignment fails.
 * method overriding hooks:
   * `function Apple:before_pick(args...) end` makes `apple:pick()` call the
	code inside `before_pick()` first.
   * `function Apple:after_pick(args...) end` makes `apple:pick()` call the
	code inside `after_pick()` last.
   * `function Apple:override_pick(inherited, ...)` lets you override
	  `Apple:pick()` and call `inherited(self, ...)`.
 * virtual classes (aka dependency injection, described below).
 * introspection:
   * `oo.is(obj|class, class|classname) -> true|false` - check instance/class ancestry
   * `oo.isinstance(obj|class[, class|classname]) -> true|false` - check instance ancestry
   * `apple:is(class|classname) -> true|false` - check instance/class ancestry
	* `apple:isinstance([class|classname]) -> true|false` - check instance ancestry
	* `oo.closest_ancestor(apple, orange) -> Fruit` - closest ancestor of `orange` in
	  `apple`'s hierarchy
	* `apple:hasproperty(name) -> false | true, 'field'|'property' - check if property
	exists without accessing its value
	* `self:allpairs([super]) -> iterator() -> name, value, source` - iterate all
	  properties, including inherited _and overriden_ ones up until `super`.
   * `self:allproperties([super])` -> get a table of all current properties and values,
	  including inherited ones up until `super`.
   * `self:inspect([show_oo_fields])` - inspect the class/instance structure
	  and contents in detail (requires [glue]).
 * overridable subclassing and instantiation mechanisms:
   * `Fruit = oo.Fruit()` is sugar for `Fruit = oo.Object:subclass('Fruit')`
   * `Apple = oo.Apple(Fruit)` is sugar for `Apple = Fruit:subclass('Apple')`
   * `apple = Apple(...)` is sugar for `apple = Apple:create(...)`
      * `Apple:create()` calls `apple:init(...)`

## Inheritance and instantiation

**Classes are created** with `oo.ClassName([super])`, where `super` is
usually another class, but can also be an instance, which is useful for
creating polymorphic "views" on existing instances.

~~~{.lua}
local Fruit = oo.Fruit()
~~~

You can also create anonymous classes with `oo.class([super])`:

~~~{.lua}
local cls = oo.class()
~~~

**Instances are created** with `cls:create(...)` or simply `cls()`, which in
turn calls `cls:init(...)` which is the object constructor. While `cls` is
normally a class, it can also be an instance, which effectively enables
prototype-based inheritance.

~~~{.lua}
local obj = cls()
~~~

**The superclass** of a class or the class of an instance is accessible as
`self.super`.

~~~{.lua}
assert(obj.super == cls)
assert(cls.super == oo.Object)
~~~

**Inheritance is dynamic**: properties are looked up at runtime in
`self.super` and changing a property or method in the superclass reflects on
all subclasses and instances. This can be slow, but it saves space.

~~~{.lua}
cls.the_answer = 42
assert(obj.the_answer == 42)
~~~

**You can detach** the class/instance from its parent class by calling
`self:detach() -> self`. This copies all inherited fields to the
class/instance and removes `self.super`.

~~~{.lua}
cls:detach()
obj:detach()
assert(obj.super == nil)
assert(cls.super == nil)
assert(cls.the_answer == 42)
assert(obj.the_answer == 42)
~~~

**Static inheritance** can be achieved by calling
`self:inherit([other],[replace],[stop_super]) -> self` which copies over
the properties of another class or instance, effectively *monkey-patching*
`self`, optionally overriding properties with the same name. The fields
`self.classname` and `self.super` are always preserved though, even with
the `override` flag.

  * `other` can also be a plain table, in which case it is shallow-copied.
  * `other` defaults to `self.super`.
  * `stop_super` limits how far up in the inheritance chain of `other`
  too look for fields and properties to copy.
  * if `other` is not in `self`'s hierarchy, `stop_super` defaults to
  `oo.closest_ancestor(self, other)` in order to prevent inheriting any fields
  from common ancestors, which would undo any overridings done in subclasses
  of the closest ancestor.

~~~{.lua}
local other_cls = oo.class()
other_cls.the_answer = 13

obj:inherit(other_cls)
assert(obj.the_answer == 13) --obj continues to dynamically inherit cls.the_answer
                             --but statically inherited other_cls.the_answer

obj.the_answer = nil
assert(obj.the_answer == 42) --reverted to class default

cls:inherit(other_cls)
assert(cls.the_answer == 42) --no override

cls:inherit(other_cls, true)
assert(cls.the_answer == 13) --override
~~~

In fact, `self:detach()` is written as `self:inherit(self.super)` with the
minor detail of setting `self.classname = self.classname` and removing
`self.super`.

__NOTE:__ Detaching instances _or final classes_ helps preventing LuaJIT from
bailing out to the interpreter which can result in 100x performance drop.
Even in interpreter mode, detaching instances can increase performance for
method lookup by 10x (see benchmarks).

You can do this easily with:

~~~{.lua}
--detach instances of (subclasses of) myclass from their class.
--patching myclass or its subclasses afterwards will not affect
--existing instances but it will affect new instnaces.
function myclass:before_init()
	self:detach()
end

--detach all new subclasses of myclass. patching myclass or its
--supers afterwards will have no effect on existing subclasses
--of myclass or its instances. patching final classes though
--will affect both new and existing instances.
function myclass:override_subclass(inherited, ...)
	return inherited(self, ...):detach()
end
~~~

__NOTE:__ Static inheritance changes field lookup semantics in a subtle way:
because field values no longer dynamically overshadow the values set in the
superclasses, setting a statically inherited field to `nil` doesn't expose
back the value from the super class, instead the field remains `nil`.

To further customize how the values are copied over for static inheritance,
override `self:properties()`.

## Virtual properties

**Virtual properties** are created by defining a getter and a setter. Once
you have defined `self:get_foo()` and `self:set_foo(value)` you can read and
write to `self.foo` and the getter and setter will be called instead.
The setter is optional. Assigning a value to a property that doesn't have
a setter results in an error.

Getters and setters are only called on instances. This allows setting default
values for properties on the class as plain fields with the same name as the
property, following that those defaults will be applied manually in the
constructor with `self.foo = self.super.foo`.

There are no virtual properties for classes. Use singleton instances instead.

~~~{.lua}
function cls:get_answer_to_life() return deep_thought:get_answer() end
function cls:set_answer_to_life(v) deep_thought:set_answer(v) end
obj = cls()
obj.answer_to_life = 42
assert(obj.answer_to_life == 42) --assuming deep_thought can store a number
~~~

Virtual properties can be *generated in bulk* given a _multikey_ getter and
a _multikey_ setter and a list of property names, by calling
`self:gen_properties(names, [getter], [setter])`. The setter and getter must
be methods of form:

  * `getter(self, k) -> v`
  * `setter(self, k, v)`

## Overriding hooks

Overriding hooks are sugar to make method overriding more easy and readable.

Instead of:

~~~{.lua}
function Apple:pick(arg)
	print('picking', arg)
	local ret = Apple.super.pick(self, arg)
	print('picked', ret)
	return ret
end
~~~

Write:

~~~{.lua}
function Apple:override_pick(inherited, arg, ...)
	print('picking', arg)
	local ret = inherited(self, arg, ...)
	print('picked', ret)
	return ret
end
~~~

Or even better:

~~~{.lua}
function Apple:before_pick(arg)
	print('picking', arg)
end

function Apple:after_pick(arg)
	print('picked', arg)
	return ret
end

~~~

By defining `self:before_<method>(...)` a new implementation for
`self.<method>` is created which calls the before hook and then calls the
existing (inherited) implementation. Both calls receive all arguments.

By defining `self:after_<method>(...)` a new implementation for
`self.<method>` is created which calls the existing (inherited)
implementation, after which it calls the hook and returns whatever the hook
returns. Both calls receive all arguments.

By defining `self:override_<method>(inherited, ...)` you can access
`self.super.<method>` as `inherited`.

~~~{.lua}
function cls:before_init(foo, bar)
  self.foo = foo or default_foo
  self.bar = bar or default_bar
end

function cls:after_init()
  --allocate resources
end

function cls:before_destroy()
  --destroy resources
end
~~~

If you don't know the name of the method you want to override until runtime,
use `cls:before(name, func)`, `cls:after(name, func)` and
`cls:override(name, func)` instead.

## Virtual classes (aka dependency injection)

Virtual classes provide an additional way to extend composite objects
(objects which need to instantiate other objects) beyond inheritance which
doesn't by itself cover extending the classes of the sub-objects of the
composite object. Virtual classes come for free in languages where classes
are first-class entitites: all you have to do is to make the inner class
a class field of the outer class and instantiate it with `self:inner_class()`.
This simple indirection has many advantages:

  * it allows subclassing the inner class in subclasses of the outer class
    by just overriding the `inner_class` field.
  * using `self:inner_class()` instead of `self.inner_class()` passes the
    outer object as the second arg to the constructor of the inner object
    (the first arg is the inner object) so that you can reference the outer
    object in the constructor, which is usually needed.
  * the`inner_class` field can be used as a method of the outer class so
    it can be made part of its public API without needing any additional
	 wrapping, and it can also be overriden with a normal method in subclasses
	 of the outer class (the overriding mechanism still works even if it's
	 not overriding a real method).

## Events

Events are useful for associating actions with callback functions. This
can already be done more flexibly with plain methods and overriding, but
events have the distinct ability to revert the overidding at runtime
(with `obj:off()`). They also differ in the fact that returning a non-nil
value from a callback short-circuits the call chain and the value is
returned back to the user.

The events functionality can be enabled by adding the [events] mixin to
oo's base class (or to any other class):

~~~{.lua}
local events = require'events'
oo.Object:inherit(events)
~~~

## Performance Tips

Instance fields are accessed directly but methods and default values
(class fields) go through a slower dynamic dispatch function (it's the
price you pay for virtual properties). Copying class fields to the instance
by calling `self:inherit()` will short-circuit this lookup at the expense
of more memory consumption. Fields with a `nil` value go through the same
function too so providing a `false` default value to those fields will
also speed up their lookup.
