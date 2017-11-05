---
platforms: osx32, osx64
tagline:   Obj-C & Cocoa bridge
---

## `local objc = require'objc'`

## Features

  * Coverage
    * full access to Cocoa classes, protocols, C functions, structs, enums, constants
	 * access to methods, properties and ivars
	 * creating classes and overriding methods
	 * exploring and searching the Objective-C runtime
  * Platforms
    * tested with __OSX 10.7 to 10.12__ (__32bit__ and __64bit__)
  * Dependencies
    * none for Cocoa (XML parser included), [expat] for non-standard bridgesupport files
  * Type Bridging
    * methods and functions return Lua booleans
    * Lua numbers, strings and tables can be passed for NSNumber, NSStrings, NSArray and NSDictionary args
	 * string names can be passed for class and selector args
	 * Lua functions can be passed for block and function-pointer args without specifying a type signature
    * overriding methods does not require specifying the method type signature
      * method signatures are inferred from existing supermethods and conforming protocols
         * formal and informal protocols supported
    * function-pointer args on overriden methods and blocks can be called without specifying a type signature
  * GC Bridging
    * attaching Lua variables to classes and objects
      * Lua variables follow the lifetime of Obj-C objects
		* Lua variables attached to classes are inherited
    * automatic memory management of objects and blocks
      * blocks are refcounted and freed when their last owner releases them
  * Speed
    * aggressive caching all-around
	 * no gc pressure in calling methods after the first invocation
	 * fast, small embedded XML parser


## Limitations

Blocks, function callbacks and overriden methods are based on ffi callbacks
which come with some limitations:

 * can't access the vararg part of the function, for variadic functions/methods
 * can't access the pass-by-value struct args or any arg after the first pass-by-value struct arg
 * can't return structs by value

To counter this, you can use [cbframe] as a workaround. Enable it with
`objc.debug.cbframe = true` and now all problem methods and blocks
will receive a single arg: a pointer to a [D_CPUSTATE] struct that you have
to pick up args from and write the return value into. Note that self
isn't passed in this case, the cpu state is the only arg.

[D_CPUSTATE]: https://github.com/luapower/cbframe/blob/master/cbframe_x86_h.lua

## Quick Tutorial

### Loading frameworks

~~~{.lua}
--load a framework by name; `objc.searchpaths` says where the frameworks are. you can also use full paths.
--classes and protocols are loaded, but also C constants, enums, functions, structs and even macros.
objc.load'Foundation'

--you can also load sub-frameworks like this:
objc.load'Carbon.HIToolbox'

--which is the same as using relative paths:
objc.load'Carbon.framework/Versions/Current/Frameworks/HIToolbox'
~~~

### Creating and using objects

~~~{.lua}
--instantiate a class. the resulting object is retained and released on gc.
--you can call `release()` on it too, for a more speedy destruction.
local str = objc.NSString:alloc():initWithUTF8String'wazza'

--call methods with multiple arguments using underscores for ':'. last underscore is optional.
--C constants, enums and functions are in the objc namespace too.
local result = str:compare_options(otherStr, objc.NSLiteralSearch)
~~~

### Subclassing

~~~{.lua}
--create a derived class. when creating a class, say which protocols you wish it conforms to,
--so that you don't have to deal with type encodings when implementing its methods.
objc.class('NSMainWindow', 'NSWindw <NSWindowDelegate>')

--add methods to your class. the selector `windowWillClose` is from the `NSWindowDelegate` protocol
--so its type encoding is inferred from the protocol definition.
function objc.NSMainWindow:windowWillClose(notification)
	...
end

--override existing methods. use `objc.callsuper` to call the supermethod.
function objc.NSMainWindow:update()
	...
	return objc.callsuper(self, 'update')
end

~~~

### Converting between Lua and Obj-C types

~~~{.lua}
local str = objc.toobj'hello'             --create a NSString from a Lua string
local num = objc.toobj(3.14)              --create a NSNumber from a Lua number
local dic = objc.toobj{a = 1, b = 'hi'}   --create a NSDictionary from a Lua table
local arr = objc.toobj{1, 2, 3}           --create a NSArray from a Lua table

local s = objc.tolua(str)
local n = objc.tolua(num)
local t1 = objc.tolua(dic)
local t2 = objc.tolua(arr)
~~~

### Adding Lua variables (luavars)

~~~{.lua}
--add Lua variables to your objects - their lifetime is tied to the lifetime of the object.
--you can also add class variables - they will be accessible through the objects too.
objc.NSObject.myClassVar = 'I can live forever'
local obj = objc.NSObject:new()
obj.myInstanceVar = 'I live while obj lives'
obj.myClassVar = 5 --change the class var (same value for all objects)
~~~

### Adding Lua methods

Lua methods are just Lua variables which happen to have a function-type value.
You can add them to a class or to an instance, but that doesn't make them
"class methods" or "instance methods" in OOP sense. Instead, this distinction
comes about when you call them:

~~~{.lua}
function objc.NSObject:myMethod() end
local str = objc.toobj'hello'   --create a NSString instance, which is a NSObject
str:myMethod()                  --instance method (str passed as self)
objc.NSString:myMethod()        --class method (NSString passed as self)
~~~

As you can see, luavars attached to a class are also inherited.

> If this looks like a lot of magic, it is. The indexing rules for class and instance
objects (i.e. getting and setting object and class fields) are pretty complex.
Have a look at the API sections "object fields" and "class fields" to learn more.

### Accessing properties & ivars

~~~{.lua}
--get and set class and instance properties using the dot notation.
local pr = objc.NSProgress:progressWithTotalUnitCount(123)
print(pr.totalUnitCount) --prints 123
pr.totalUnitCount = 321  --sets it

--get and set ivars using the dot notation.
local obj = objc.NSDocInfo:new()
obj.time = 123
print(obj.time) --prints 123
~~~

### Creating and using blocks

~~~{.lua}
--blocks are created automatically when passing a Lua function where a block is expected.
--their lifetime is auto-managed, for both synchronous and asynchronous methods.
local str = objc.NSString:alloc():initWithUTF8String'line1\nline2\nline3'
str:enumerateLinesUsingBlock(function(line, stop)
	print(line:UTF8String()) --'char *' return values are also converted to Lua strings automatically
end)

--however, blocks are slow to create and use ffi callbacks which are very limited in number.
--create your blocks outside loops if possible, or call `collectgarbage()` every few hundred iterations.

--create a block with its type signature inferred from usage.
--in this case, its type is that of arg#1 to NSString's `enumerateLinesUsingBlock` method.
local block = objc.toarg(objc.NSString, 'enumerateLinesUsingBlock', 1, function(line, stop)
	print(line:UTF8String())
end)
str:enumerateLinesUsingBlock(block)

--create a block with its method type encoding given manaully.
--for type encodings see:
--   https://code.google.com/p/jscocoa/wiki/MethodEncoding
local block = objc.block(function(line, stop)
	print(line:UTF8String())
end, 'v@^B'}) --retval is 'v' (void), line is '@' (object), stop is '^B' (pointer to BOOL)
str:enumerateLinesUsingBlock(block)
~~~

### More goodies

Look up anything in Cocoa by a Lua pattern:

		./luajit objc_test.lua inspect_find foo

Then inspect it:

		./luajit objc_test.lua inspect_class PAFootprint


### Even more goodies

Check out the unit test script, it also contains a few demos, not just tests. \
Check out the undocumented `objc_inspect` module, it has a simple cmdline inspection API.


## Memory management

Memory management in objc is automatic. Cocoa's reference counting system is
tied to the Lua's garbage collector so that you don't have to worry about
retain/release. The integration is not air-tight though, so you need to know
how it's put together to avoid some tricky situations.

### Strong and weak references

Ref. counting systems are fragile: they require that retain() and release()
calls on an object be perfectly balanced. If they're not, you're toast.
Thinking of object relationships in in terms of weak and strong references
can help a lot with that.

A strong reference is a retained reference, guaranteed to be available until
released. A weak reference is not retained and its availability depends on
context.

A strong reference has a finalizer that calls release() when collected.
A weak reference doesn't have a finalizer.

Calling release() on a strong reference releases the reference, and removes
the finalizer, turning it into a weak reference. You should not call
release() on a weak reference.

### Return values are strong

Cocoa's rules say that if you alloc an object, you get a strong (retained)
reference on that object. Other method calls that return an object return
a weak (non-retained) reference to that object. Lua retains all object return
values so you always get a strong reference. This is required for the
alloc():init() sequence to work, and it's generally convenient.

### Callback arguments are weak

Object arguments passed to overriden methods (including the self argument),
blocks and function pointers, are weak references, not tied to Lua's garbage
collector. If you want to keep them around outside the scope of the callback,
you need to retain them:

~~~{.lua}
local strong_ref
function MySubClass:overridenMethod()
	strong_ref = self:retain() --self is a weak ref. it needs to be retained.
end
~~~

### Luavars and object ownership

You should only use luavars on objects that you own. Luavars go away
when the last strong reference to an object goes away. Setting Lua vars
on an object with only weak references will leak those vars! Even worse,
those vars might show up as vars of other objects!

### Strong/weak ambiguities

If you create a `NSWindow`, you don't get an _unconditionally_ retained
reference to that window, contrary to Cocoa's rules, because if the user
closes the window, it is your reference that gets released. The binding
doesn't know about that and on gc it calls release again, giving you a crash
at an unpredictable time (`export NSZombieEnabled=YES` can help here).
To fix that you can either tell Cocoa that your ref is strong by calling
`win:setReleasedWhenClosed(false)`, or tell the gc that your ref is weak by
calling `ffi.gc(win, nil)`. If you chose the latter, remember that you can't
use luavars on that window!


## Main API

----------------------------------------------------------- --------------------------------------------------------------
__global objects__

`objc`																		namespace for loaded classes, C functions,
																				function aliases, enums, constants, and this API

__frameworks__

`objc.load(name|path[, option])`										load a framework given its name or its full path \
																				option 'notypes': don't load bridgesupport file

`objc.searchpaths = {path1, ...}`									search paths for frameworks

`objc.findframework(name|path) -> path, name`					find a framework in searchpaths

__classes__

`objc.class'name' -> cls`												class by name (`objc.class'Foo'` == `objc.Foo`)

`objc.class(obj) -> cls`												class of instance

`objc.class('Foo', 'SuperFoo <Protocol1, ...>') -> cls`		create a class which conforms to protocols

`objc.class('Foo', 'SuperFoo', 'Protocol1', ...) -> cls`		create a class (alternative way)

`objc.classname(cls) -> s`												class name

`objc.isclass(x) -> true|false`										check for Class type

`objc.isobj(x) -> true|false`											check for id type

`objc.ismetaclass(cls) -> true|false`								check if the class is a metaclass

`objc.superclass(cls|obj) -> cls|nil`								superclass

`objc.metaclass(cls|obj) -> cls`										metaclass

`objc.isa(cls|obj, supercls) -> true|false`						check the inheritance chain

`objc.conforms(cls|obj, protocol) -> true|false`				check if a class conforms to a protocol

`objc.responds(cls, sel) -> true|false`							check if instances of cls responds to a selector

`objc.conform(cls, protocol) -> true|false`						declare that a class conforms to a protocol

__object fields__

`obj.field` \																access an instance field, i.e. try to get, in order: \
`obj:method(args...)`														- an instance luavar \
																					- a readable instance property \
																					- an ivar \
																					- an instance method \
																					- a class field (see below)

`obj.field = val` \															set an instance field, i.e. try to set, in order: \
																					- an existing instance luavar \
																					- a writable instance property \
																					- an ivar \
																					- an existing class field (see below) \
																					- a new instance luavar

__class fields__

`cls.field` \																access a class field, i.e. try to get, in order: \
`cls:method(args...)`														- a class luavar \
																					- a readable class property \
																					- a class method \
																					- a class luavar from a superclass

`cls.field = val` \														set a class field, i.e. try to set, in order: \
`function cls:method(args...) end`										- an existing class luavar \
																					- a writable class property \
																					- an instance method \
																					- a conforming instance method \
																					- a class method \
																					- a conforming class method \
																					- an existing class luavar in a superclass \
																					- a new class luavar

__type conversions__

`objc.tolua(x) -> luatype`												convert a NSNumber, NSString, NSDictionary, NSArray
																				to a Lua number, string, table respectively.
																				anything else passes through.

`objc.toobj(x) -> objtype`												convert a Lua number, string, or table to a
																				NSNumber, NSString, NSDictionary, NSArray respectively.
																				anything else passes through.

`objc.ipairs(arr) -> next, arr, 0`									ipairs for NSarray.

__overriding__

`objc.override(cls, sel, func[,mtype|ftype]) -> true|false`	override an existing method, or add a method
																				which conforms to one of the conforming protocols.
																				returns true if the method was found and overriden.

`objc.callsuper(obj, sel, args...) -> retval`					call the method implementation of the superclass
																				of an object.

`objc.swizle(cls, sel1, sel2[, func])`								swap implementations between sel1 and sel2.
																				if sel2 is not an existing selector, func is required.

__selectors__

`objc.SEL(name|sel) -> sel`											create/find a selector by name

`sel:name() -> s`															selector name (same as tostring(sel))


__blocks and callbacks__

`objc.toarg(cls, sel, argindex, x) -> objtype`					convert a Lua value to an objc value - used specifically
																				to create blocks and function callbacks with an appropriate
																				type signature for a specific method argument.

`objc.block(func, mtype|ftype) -> block`							create a block with a specific type encoding.

----------------------------------------------------------- --------------------------------------------------------------


## Reflection API

----------------------------------------------------------- --------------------------------------------------------------
__protocols__

`objc.protocols() -> iter() -> proto`								loaded protocols (formal or informal)

`objc.protocol(name|proto) -> proto`								get a protocol by name (formal or informal)

`proto:name() -> s`														protocol name (same as tostring(proto))

`proto:protocols() -> iter() -> proto`								inherited protocols

`proto:properties() -> iter() -> prop`								get properties (inherited ones not included)

`proto:property(proto, name, required, readonly) -> prop`	find a property

`proto:methods(proto, inst, req) -> iter() -> sel, mtype`	get method names and raw, non-annotated type encodings

`proto:mtype(proto, sel, inst, req) -> mtype`					find a method and return its raw type encoding

`proto:ctype(proto, sel, inst, req[, for_cb]) -> ctype`		find a method and return its C type encoding

__classes__

`objc.classes() -> iter() -> cls`									loaded classes

`objc.protocols(cls) -> iter() -> proto`							protocols which a class conforms to (formal or informal)

objc.properties(cls) -> iter() -> prop`							instance properties \
																				use metaclass(cls) to get class properties

`objc.property(cls, name) -> prop`									instance property by name (looks in superclasses too)

`objc.methods(cls) -> iter() -> meth`								instance methods \
																				use metaclass(cls) to get class methods

`objc.method(cls, name) -> meth`										instance method by name (looks in superclasses too)

`objc.ivars(cls) -> iter() -> ivar`									ivars

`objc.ivar(cls) -> ivar`												ivar by name (looks in superclasses too)

__properties__

`prop:name() -> s`														property name (same as tostring(prop))

`prop:getter() -> s`														getter name

`prop:setter() -> s`														setter name (if not readonly)

`prop:stype() -> s`														type encoding

`prop:ctype() -> s`														C type encoding

`prop:readonly() -> true|false`										readonly check

`prop:ivar() -> s`														ivar name

__methods__

`meth:selector() -> sel`												selector

`meth:name() -> s`														selector name (same as tostring(meth))

`meth:mtype() -> s`														type encoding

`meth:implementation() -> IMP`										implementation (untyped)

__ivars__

`ivar:name() -> s`														name (same as tostring(ivar))

`ivar:stype() -> s`														type encoding

`ivar:ctype() -> s`														C type encoding

`ivar:offset() -> n`														offset

----------------------------------------------------------- --------------------------------------------------------------


## Debug API

----------------------------------------------------------- --------------------------------------------------------------
__logging__
`objc.debug.errors` (true)												log errors to stderr
`objc.debug.printcdecl` (false)										print C declarations on stdout
`objc.debug.logtopics= {topic = true}` (empty)					enable logging on some topic (see source code)
`objc.debug.errcount = {topic = count}`							error counts
__solving C name clashes__
`objc.debug.rename.string.foo = bar`								load a string constant under a different name
`objc.debug.rename.enum.foo = bar`									load an enum under a different name
`objc.debug.rename.typedef.foo = bar`								load a type under a different name
`objc.debug.rename.const.foo = bar`									load a const under a different name
`objc.debug.rename.function.foo = bar`								load a global function under a different name
__loading frameworks__
`objc.debug.loadtypes` (true)											load bridgesupport files
`objc.debug.loaddeps` (false)											load dependencies per bridgesupport file (too many to be useful)
`objc.debug.lazyfuncs` (true)											cdef functions on the first call instead of on load
`objc.debug.checkredef` (false)										check incompatible redefinition attempts (makes parsing slower)
`objc.debug.usexpat` (false)											use expat to parse bridgesupport files
__gc bridging__
`objc.debug.noretain.foo = true`										declare that method `foo` already retains the object it returns
----------------------------------------------------------- --------------------------------------------------------------

## Future developments

> NOTE: I don't plan to work on these, except on requests with a use case. Patches/pull requests welcome.

### Bridging

  * function-pointer args on function-pointer args (recorded but not used - need use cases)
  * test for overriding a method that takes a function-pointer (not a block) arg and invoking that arg from the callback
  * auto-coercion of types for functions/methods with format strings, eg. NSLog
    * format string parser - apply to variadic functions and methods that have the `printf_format` attribute
  * return pass-by-reference out parameters as multiple Lua return values
    * record type modifiers O=out, N=inout
  * auto-allocation of out arrays using array type annotations
    * `c_array_length_in_result` - array length is the return value
    * `c_array_length_in_arg` - array length is an arg
    * `c_array_delimited_by_null` - vararg ends in null - doesn't luajit do that already?
    * `c_array_of_variable_length` - ???
    * `c_array_of_fixed_length` - specifies array size? doesn't seem so
  * `sel_of_type`, `sel_of_type64` - use cases?
  * core foundation stuff
    * `cftypes` xml node - use cases?
    * `already_retained` flag
  * operator overloading (need good use cases)

### Inspection

  * list all frameworks in searchpaths
  * find framework in searchpaths
  * report conforming methods, where they come from and mark the required ones, especially required but not implemented
  * inspection of instances
    * print class, superclasses and protocols in one line
    * print values of luavars, ivars, properties
    * listing sections: ivars, properties, methods, with origin class/protocol for each

### Type Cache

The idea is to cache bridgesupport data into Lua files for faster loading of frameworks.

  * one Lua cache file for each framework to be loaded with standard 'require'
    * dependencies also loaded using standard 'require'
  * save dependency loading
  * save cdecls - there's already a pretty printer and infrastructure for recording those
  * save constants and enums
  * save function wrappers
  * save mtas (find a more compact format for annotations containing only {retval='B'} ?)
  * save informal protocols
