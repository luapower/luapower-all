---
tagline: object model for winapi windows and controls
---

## `require'winapi.vobject'`

This module defines a single-inheritance object model with
virtual properties, method-overriding hooks and [events].

## Subclassing and instantiation protocol

At the core there's on an user API and an implementation protocol
for implementing a single-inheritance object model.

The user API is comprised of 2 functions:

  * `subclass(derived[, super]) -> derived`
  * `isinstance(object, class) -> true|false`

`subclass()` calls `super:__subclass(derived)` to perform the actual
subclassing and returns `derived`. This means that each class is free
to define how subclassing should be performed (copy all members to
the derived class aka static inheritance, assign an `__index`
metamethod aka dynamic inheritance, etc.). If the super class doesn't
define a `__subclass` method, nothing gets inherited and `derived`
is returned untouched.

`isinstance()` calls `object:__super()` recursively until it matches
the wanted class. Classes must implement `__super()` for this to work.

Note that there's no API or implementation protocol for instantiation.
The root class will define these.

## The root object

The `VObject` class is the base class of every other class in winapi.

VObject implements the single-inheritance object model. This means that
you can use `subclass()` to subclass from `VObject` and `isinstance()`
on every instance or subclass of `VObject`.

VObject It also defines how instantiation works: calling `Foo(args...)` creates
an instance of `Foo`, calls `__init(self, args...)` on it, and returns it.

VObject instances:

  * inhert class fields dynamically
  * inherit instance metamethods statically
  * inherit super class fields dynamically
  * inherit super class metamethods statically

## Virtual properties

Virtual properties means that:

  * `x = foo.bar` calls `foo:get_bar() -> x`, and
  * `foo.bar = x` calls `foo:set_bar(x)`.

If there's a `set_bar` but no `get_bar` defined, setting `foo.bar = x`
sets `foo.__state.bar = x` and later `x = foo.bar` returns the value
of `foo._state.bar`. These are called "stored properties".

If there's a `get_bar` but no `set_bar`, doing `foo.bar = x` raises an error.
These are called "read-only properties".

### Generating properties in bulk

Calling `Foo:__gen_vproperties({foo = true, bar = true}, getter, setter)`
generates getters and setters for `foo` and `bar` properties
based on `getter` and `setter` such that:

	get_foo(self)           calls getter(self, 'foo')
	get_bar(self)           calls getter(self, 'bar')
	set_foo(self, val)      calls setter(self, 'foo', val)
	set_bar(self, val)      calls setter(self, 'bar', val)

### API

------------------------------------------- ----------------------------------------------------------
__subclassing__
`__subclass(class) -> class`                subclassing constructor
`__gen_vproperties(names, getter, setter)`  generate virtual properties in bulk
__instantiation__
`__init(...)`                               stub object constructor (implemented in concrete classes)
__introspection__
`__super() -> class`                        access the super class
`__supers() -> iter() -> class`             iterate over the class hierarchy
`__allpairs() -> iter() -> k, v, class`     iterate instance and class members recursively
`__pairs() -> iter() -> k, v`               iterate the flattened map of instance and class members
`__properties() -> iter() -> k, class`      iterate the flattened map of instance and class members
`__vproperties() -> iter() -> prop, info`   iterate all virtual properties
------------------------------------------- ----------------------------------------------------------
