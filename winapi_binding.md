---
tagline: developer documentation
---

## Overview

To bind new "chapters" of the Windows API first identify which chapter
it is and check to see if there isn't already a module for that.
Module names should match msdn documentation as much as possible.
After you decided on a module name, start adding in all the necessary
ffi cdefs, defines and functions. The function names and args should
match WinAPI as much as possible. This is the "procedural layer"
of the binding. The OOP layer (if any) will be based on it.

## Binding WinAPI functions

### Error checking

Pass the result of winapi calls to `checknz`, `checkh` and friends according
to what constitutes an error in the result: you get automatic error handling
and clear code.

### Memory management

Use `own(object, finalizer)` on all newly created objects but call
`disown(object)` right after any successful api call that assigns that object
an owner responsible for freeing it, and use `own()` again every time a call
leaves an object without an owner. Doing this consistently will complicate
the implementation sometimes but it prevents leaks and you get automatic
object lifetime management (for what is worth given the non-deterministic
nature of the gc).

Avoid surfacing ABI boilerplate like buffers, buffer sizes and internal data
structures. Sometimes you may want to reuse a buffer to avoid heap trashing
especially on a function you know it could be called repeatedly many times.
In this case add the buffer as an optional trailing argument - if given it
will be used, if not, an internal buffer will be created. If there's a need
to pass state around beyond this, make a class (that is, do it in the
object layer).

### Strings

Use `wcs(arg)` on all string args: if arg is a Lua string, it will be
interpreted as an utf8 encoded string and converted to wcs, otherwise
it will be passed through untouched. This allows passing both Lua
strings and wcs buffers transparently.

### Flags

Use `flags(arg)` on all flag args so that you can pass a string of the form
`'FLAG1 FLAG2 ...'` as an alternative to `bit.bor(FLAG1, FLAG2, ...)`. It
also changes nil into 0 to allow for optional flag args to be passed where
winapi expects an int.

### Indices

Count from 1! Use `countfrom0` on all positional args: this will decrement
the arg but only if it's strictly > 0 so that negative numbers are passed
through as they are since we want to preserve values with special meaning
like -1.

### Simple structs

Use `arg = types.FOO(arg)` instead of `arg = ffi.new('FOO', arg)`.
This allows passing a pre-allocated FOO as argument.

Publish common types in the winapi namespace: `FOO = types.FOO`
and then use `FOO` instead of `types.FOO`.

### Arrays

Use `arg = arrays.FOO(arg)` instead of `arg = ffi.new('FOO[?]', #arg, arg)`.
This allows passing in a pre-allocated array as argument, and when passing
in a table, the array size will be #arg.

### Complex structs

Don't allocate structs with `ffi.new('FOO', arg)`. Instead, make a struct
constructor `FOO = struct{...}`, and pass all `FOO`'s args through it:
`arg = FOO(arg)`.

This can enable some magic, depending on how much you add to your definition:

  * the user can pass in a pre-allocated `FOO` which will be passed through.
  * if passing in a table, as it's usually the case,
    * the size (usually `cbSize`) field (if any) can be set automatically.
    * the struct's mask field (if any) can be set automatically to reflect
	 that only certain fields (those present in the table) need to be set.
	 * default values (eg. a version field) can be set automatically.
  * virtual fields with a getter and setter can be added which will be
  available alongside the cdata fields.

#### Virtual fields

Making a struct definition sets a metatable on the underlying ctype
(using ffi.metatype()), making any virtual fields available to all cdata
of that ctype. Accessing a struct through the virtual fields instead of the
C fields has some advantages:

  * the struct's mask field, if any, will be set based on which fields are
  set, provided a bitmask is specified in the struct's definition of that
  field. Setting a masked field to nil will clear its bitmask in the mask
  field. Getting the value of a field with its mask cleared returns nil,
  regardless of its data type.

  * bits of masked bitfields can be read and set individually, provided
  you define the data field, the mask field, and the prefix for the mask
  constants in the struct definition.

  * an `init` function can be provided in which any output buffers that
  the struct references can be allocated and anchored to the struct
  (i.e. they become part of the struct).

  * getters/setters can be conversion functions such as `mbs`/`wcs`.
  if the setter function returns a cdata, that cdata is anchored
  automatically to the struct's field.

#### Example:

~~~{.lua}
FOO = struct{
	ctype = 'FOO',    --the C struct that is to be created.
	size = 'cbSize',  --the field that must be set to sizeof(FOO), if any.
	mask = 'fMask',   --the field that masks other fields, if any.
	defaults = {
		nVersion = 1,  --set on creation.
		...
	},
	fields = mfields{ --mfields is the field def constructor for masked fields.
		'bar_field',    'barField',    MASK_BAR, setter, getter,
		'baz_field',    'bazField',    MASK_BAZ, pass,   pass,     -- setting baz_field sets MASK_BAZ in fMask.
		'zup_field',    'zupField',    MASK_ZUP, wcs,    mbs,      -- zup_field works with Lua strings.
		...
		'__state',      'stateField',     MASK_STATE, pass, pass,  -- bitfield, see below
		'__stateMask',  'stateMaskField', MASK_STATE, pass, pass,
	},
	bitfields = {
		-- setting state_FOO sets or clears the mask PREFIX_FOO in __state,
		-- and sets PREFIX_FOO to __stateMask (and sets MASK_STATE in fMask).
		-- getting state_FOO checks the mask PREFIX_FOO in __stateMask,
		-- and if set, checks the mask PREFIX_FOO in __state.
		state = {'__state', '__stateMask', 'PREFIX'},
	},
}
~~~

#### Naming virtual fields

Use the "lowercase with underscores" naming convention for virtual field names.
Use names like caption, x, y, w, h, pos, parent, etc. consistently throughout.

### Messages

Write message decoders for all WM_* and messages specific to your module.
(eg. mouse.lua contains message decoders for WM_MOUSE* messages).

Only write decoders for messages for which wParam and lParam mean something.

WM_* decoders go into the `WM` global table.

WM_NOTIFY decoders go into the `NM` global table.

All message names must be added into the global `WM_NAMES`
and `WM_NOTIFY_NAMES` tables respectively too, regardless whether
there are decoders for them or not. Examples:

~~~{.lua}
update(WM_NAMES, constants{
	LB_ADDSTRING             = 0x0180,
	LB_INSERTSTRING          = 0x0181,
	...
})

update(WM_NOTIFY_NAMES, constants{
	TBN_GETBUTTONINFOA       = TBN_FIRST-0,
	TBN_BEGINDRAG            = TBN_FIRST-1,
	...
})
~~~

## Making new classes

### Subclassing

The easiest way to create a new class is to use the code of an existing
class as a template. There are base classes for almost everything, so:

* subclass from `Control` if you are creating a new kind of control.
* subclass from `Window` if you are creating a new kind of top-level window.
* subclass from `VObject` if it's a non-visual class.
* subclass from `ItemList` if your class represents a list of objects.

### Initialization

Initialization is done by overriding the `__init` constructor.
`BaseWindow` also provides pre- and post-window-creation hooks
which you can override:

	__before_create(self, info, args)
	__after_create(self, info, args)

### Auto-generation of properties and events

`BaseWindow` contains extensive automation to help with binding
of HWND-based classes, so that binding a new window or control is mainly
an issue of filling up the following tables:

	__class_style_bitmask = bitmask{}  --for windows that own their WNDCLASS
	__style_bitmask = bitmask{}        --style bits
	__style_ex_bitmask = bitmask{}     --extended style bits
	__defaults = {}
	__init_properties = {}  --properties to be set after window creation
	__wm_handler_names = {} --message name -> event name mapping
	__wm_syscommand_handler_names = {} --WM_SYSCOMMAND code -> event name map
	__wm_command_handler_names = {}    --WM_COMMAND code -> event name map
	__wm_notify_handler_names = {}     --WM_NOTIFY code -> event name map

The `__*_bitmask` tables map property names to class style, window style
and extended window style constants respectively so that individual
properties can be created automatically based on those definitions.

Windows messages as well as WM_SYSCOMMAND, WM_COMMAND and WM_NOTIFY messages
are routed automatically to their respective windows and decoded
and individual events are generated per `__wm_*` tables.

### Item lists

Some controls (eg. listbox) need to manage a list of items. To add this you need to:

  * subclass `ItemList` for the list itself and implement at least
  add() and remove() methods (plus other properties and methods
  that apply to the items or to the item list as a whole).

  * instantiate your custom list class in the control's constructor
  (i.e. `__init`, which you override).

