
--Objecive-C runtime and bridgesupport binding.
--Written by Cosmin Apreutesei. Public domain.

--Ideas and code from TLC by Fjölnir Ásgeirsson (c) 2012, MIT license.
--Tested with with LuaJIT 2.0.3, 32bit and 64bit on OSX 10.9 and 10.7.

local ffi = require'ffi'
local cast = ffi.cast
local OSX = ffi.os == 'OSX'
local x64 = ffi.abi'64bit'

if OSX and ffi.arch ~= 'arm' then
	ffi.load('libobjc.A.dylib', true)
end

if x64 then
	ffi.cdef[[
	typedef double CGFloat;
	typedef long NSInteger;
	typedef unsigned long NSUInteger;
	]]
else
	ffi.cdef[[
	typedef float CGFloat;
	typedef int NSInteger;
	typedef unsigned int NSUInteger;
	]]
end

ffi.cdef[[
typedef signed char BOOL;

typedef struct objc_class    *Class;
typedef struct objc_object   *id;
typedef struct objc_selector *SEL;
typedef struct objc_method   *Method;
typedef id                   (*IMP) (id, SEL, ...);
typedef struct Protocol      Protocol;
typedef struct objc_property *objc_property_t;
typedef struct objc_ivar     *Ivar;

struct objc_class  { Class isa; };
struct objc_object { Class isa; };

struct objc_method_description {
	SEL name;
	char *types;
};

//stdlib
int access(const char *path, int amode);    // used to check if a file exists
void free (void*);                          // used for freeing returned dyn. allocated objects

//selectors
SEL sel_registerName(const char *str);
const char* sel_getName(SEL aSelector);

//classes
Class objc_getClass(const char *name);
const char *class_getName(Class cls);
Class class_getSuperclass(Class cls);
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);
void objc_disposeClassPair(Class cls);
BOOL class_isMetaClass(Class cls);

//instances
Class object_getClass(void* object);        // use this instead of obj.isa because of tagged pointers

//methods
Method class_getInstanceMethod(Class aClass, SEL aSelector);
SEL method_getName(Method method);
const char *method_getTypeEncoding(Method method);
IMP method_getImplementation(Method method);
BOOL class_respondsToSelector(Class cls, SEL sel);
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
void method_exchangeImplementations(Method m1, Method m2);

//protocols
Protocol *objc_getProtocol(const char *name);
const char *protocol_getName(Protocol *p);
struct objc_method_description protocol_getMethodDescription(Protocol *p,
	SEL aSel, BOOL isRequiredMethod, BOOL isInstanceMethod);
BOOL class_conformsToProtocol(Class cls, Protocol *protocol);
BOOL class_addProtocol(Class cls, Protocol *protocol);

//properties
objc_property_t class_getProperty(Class cls, const char *name);
objc_property_t protocol_getProperty(Protocol *proto, const char *name,
	BOOL isRequiredProperty, BOOL isInstanceProperty);
const char *property_getName(objc_property_t property);
const char *property_getAttributes(objc_property_t property);

//ivars
Ivar class_getInstanceVariable(Class cls, const char* name);
const char *ivar_getName(Ivar ivar);
const char *ivar_getTypeEncoding(Ivar ivar);
ptrdiff_t ivar_getOffset(Ivar ivar);

//inspection
Class *objc_copyClassList(unsigned int *outCount);
Protocol **objc_copyProtocolList(unsigned int *outCount);
Method *class_copyMethodList(Class cls, unsigned int *outCount);
struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *p,
	BOOL isRequiredMethod, BOOL isInstanceMethod, unsigned int *outCount);
objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount);
objc_property_t *protocol_copyPropertyList(Protocol *proto, unsigned int *outCount);
Protocol **class_copyProtocolList(Class cls, unsigned int *outCount);
Protocol **protocol_copyProtocolList(Protocol *proto, unsigned int *outCount);
Ivar * class_copyIvarList(Class cls, unsigned int *outCount);
]]

local C = ffi.C                               --C namespace
local P = setmetatable({}, {__index = _G})    --private namespace
local objc = {}                               --public namespace
setfenv(1, P)                                 --globals go in P, which is published as objc.debug

--helpers ----------------------------------------------------------------------------------------------------------------

local _ = string.format
local id_ct = ffi.typeof'id'

local function ptr(p) --convert NULL pointer to nil for easier handling (say 'not ptr' instead of 'ptr == nil')
	if p == nil then return nil end
	return p
end

local intptr_ct = ffi.typeof'intptr_t'

local function nptr(p) --convert pointer to Lua number for using as table key
	if p == nil then return nil end
	local np = cast(intptr_ct, p)
	local n = tonumber(np)
	if x64 and cast(intptr_ct, n) ~= np then --hi address: fall back to slower tostring()
		n = tostring(np)
	end
	return n
end

local function own(p) --own a malloc()'ed pointer
	return p ~= nil and ffi.gc(p, C.free) or nil
end

local function csymbol_(name) return C[name] end
local function csymbol(name)
	local ok, sym = pcall(csymbol_, name)
	if not ok then return end
	return sym
end

local function memoize(func, cache) --special memoize that works with pointer arguments too
	cache = cache or {}
	return function(input)
		local key = input
		if type(key) == 'cdata' then
			key = nptr(key)
		end
		if key == nil then return end
		local ret = rawget(cache, key)
		if ret == nil then
			ret = func(input)
			if ret == nil then return end
			rawset(cache, key, ret)
		end
		return ret
	end
end

local function memoize2(func, cache1) --memoize a two-arg. function (:
	local memoized = memoize(function(arg1)
		return memoize(function(arg2) --each unique arg1 gets 2 closures + 1 table of overhead
			return func(arg1, arg2)
		end)
	end, cache1)
	return function(arg1, arg2)
		return memoized(arg1)(arg2)
	end
end

local function canread(path) --check that a file is readable without having to open it
	return C.access(path, 2^2) == 0
end

local function citer(a) --return an iterator for a null-terminated C array
	local i = -1
	return function()
		if a == nil then return end
		i = i + 1
		if a[i] == nil then return end
		return a[i]
	end
end

--debugging --------------------------------------------------------------------------------------------------------------

errors = true    --log non-fatal errors to stderr
errcount = {}    --error counts per topic
logtopics = {}   --topics to log (none by default)

local function writelog(topic, fmt, ...)
	io.stderr:write(_('[objc] %-16s %s\n', topic, _(fmt, ...)))
end

local function log(topic, ...)
	if logtopics[topic] then
		writelog(topic, ...)
	end
end

local function err(topic, ...)
	errcount[topic] = (errcount[topic] or 0) + 1
	if errors then
		writelog(topic, ...)
	end
end

local function check(ok, fmt, ...) --assert with formatted strings
	if ok then return ok end
	error(_(fmt or 'assertion failed!', ...), 3)
end

--ffi declarations -------------------------------------------------------------------------------------------------------

checkredef = false --check incompatible redefinition attempts (makes parsing slower)
printcdecl = false --print C declarations to stdout (then you can grab them and make static ffi headers)
cnames = {global = {0}, struct = {0}} --C namespaces; ns[1] holds the count

local function defined(name, namespace) --check if a name is already defined in a C namespace
	return not checkredef and cnames[namespace][name]
end

local function redefined(name, namespace, new_cdecl) --check cdecl redefinitions and report on incompatible ones
	local old_cdecl = cnames[namespace][name]
	if not old_cdecl then return end
	if not checkredef then return end
	if old_cdecl == new_cdecl then return true end --already defined but same def.
	err('redefinition', '%s\nold:\n\t%s\nnew:\n\t%s', name, old_cdecl, new_cdecl)
	return true
end

local function declare(name, namespace, cdecl) --define a C type, const or function via ffi.cdef
	if redefined(name, namespace, cdecl) then return end
	local ok, cdeferr = pcall(ffi.cdef, cdecl)
	if ok then
		cnames[namespace][1] = cnames[namespace][1] + 1
		if printcdecl then
			print(cdecl .. ';')
		end
	else
		if cdeferr == 'table overflow' then --fatal error from luajit: no more space for ctypes
			error'too many ctypes'
		end
		err('cdef', '%s\n\t%s', cdeferr, cdecl)
	end
	cnames[namespace][name] = checkredef and cdecl or true --only store the cdecl if needed
	return ok
end

--type encodings: parsing and conversion to C types ----------------------------------------------------------------------

-- stype: a value type encoding, eg. 'B', '^[8i]', '{CGPoint="x"d"y"d}'; converts to a ctype.
-- mtype: a method type encoding, eg. 'v12@0:4c8' or just 'v@:c'; converts to a ftype.
-- ftype: a function/method type encoding in table form, eg. {retval='v', '@', ':', 'c'}. converts to a ctype.
-- ctype: a C type encoding for a stype, eg. 'B' -> 'BOOL', or for a ftype, eg. 'v:#c' -> 'void (*) (SEL, Class, char)'.
-- ct:    a ffi C type object for a ctype string, eg. ffi.typeof('void (*) (id, SEL)') -> ct.

--ftype spec:
--		variadic = true|nil         --vararg function
--		isblock = true|nil          --block or function (only for function pointers)
--		[argindex] = stype          --arg stype (argindex is 1,2,... or 'retval')
--		fp = {[argindex] = ftype}   --ftypes for function-pointer type args

local function optname(name) --format an optional name: if not nil, return it with a space in front
	return name and ' '..name or ''
end

local stype_ctype --fw. decl.

local function array_ctype(s, name, ...) --('[Ntype]', 'name') -> ctype('type', 'name[N]')
	local n,s = s:match'^%[(%d+)(.-)%]$'
	--protect pointers to arrays by enclosing the name, because `[]` has precedence over `*` in C declarations.
	--so for instance '^[8]' results in 'int (*)[8]` instead of `int *[8]`.
	if name and name:sub(1,1) == '*' then
		name = _('(%s)', name)
	end
	name = _('%s[%d]', name or '', n)
	return stype_ctype(s, name, ...)
end

--note: `tag` means the struct tag in the C struct namespace; `name` means the typedef name in the C global namespace.
--for named structs only 'struct `tag`' is returned; for anonymous structs the full 'struct {fields...}' is returned.
--before returning, named structs are recursively cdef'ed (unless deftype ~= 'cdef' which skips this step).
local function struct_ctype(s, name, deftype, indent) --('{CGPoint="x"d"y"d}', 'NSPoint') -> 'struct CGPoint NSPoint'

	--break the struct/union def. in its constituent parts: keyword, tag, fields
	local kw, tag, fields = s:match'^(.)([^=]*)=?(.*).$' -- '{tag=fields}'
	kw = kw == '{' and 'struct' or 'union'
	if tag == '?' or tag == '' then tag = nil end -- ? or empty means anonymous struct
	if fields == '' then fields = nil end -- empty definition means opaque struct

	if not fields and not tag then --rare case: '{?}' coming from '^{?}'
		return 'void'..optname(name)
	end

	if not fields or deftype ~= 'cdef' then --opaque named struct, or asked by caller not to be cdef'ed
		if not tag then
			err('parse', 'anonymous struct not valid here: %s', s)
			return 'void'..optname(name)
		end
		return _('%s %s%s', kw, tag, optname(name))
	end

	if not tag or not defined(tag, 'struct') then --anonymous or not alreay defined: parse it

		--parse the fields which come as '"name1"type1"name2"type2...'
		local t = {}
		local function addfield(name, s)
			if name == '' then name = nil end --empty field name means unnamed struct (different from anonymous)
			table.insert(t, stype_ctype(s, name, 'cdef', true)) --eg. 'struct _NSPoint origin'
			return '' --remove the match
		end
		local s = fields
		local n
		while s ~= '' do
			               s,n = s:gsub('^"([^"]*)"([%^]*%b{})',     addfield)     --try "field"{...}
			if n == 0 then s,n = s:gsub('^"([^"]*)"([%^]*%b())',     addfield) end --try "field"(...)
			if n == 0 then s,n = s:gsub('^"([^"]+)"([%^]*%b[])',     addfield) end --try "field"[...]
			if n == 0 then s,n = s:gsub('^"([^"]+)"(@)%?',           addfield) end --try "field"@? (block type)
			if n == 0 then s,n = s:gsub('^"([^"]+)"(@"[A-Z][^"]+")', addfield) end --try "field"@"Class"
			if n == 0 then s,n = s:gsub('^"([^"]*)"([^"]+)',         addfield) end --try "field"...
			assert(n > 0, s)
		end
		local ctype = _('%s%s {\n\t%s;\n}', kw, optname(tag), table.concat(t, ';\n\t'))

		--anonymous struct: return the full definition
		if not tag then
			if indent then --this is the only multiline output that can be indented
				ctype = ctype:gsub('\n', '\n\t')
			end
			return _('%s%s', ctype, optname(name))
		end

		--named struct: cdef it.
		--note: duplicate struct cdefs are rejected by luajit 2.0 with an error. we guard against that.
		declare(tag, 'struct', ctype)
	end

	return _('%s %s%s', kw, tag, optname(name))
end

local function bitfield_ctype(s, name, deftype) --('bN', 'name') -> 'unsigned name: N'; N must be <= 32
	local n = s:match'^b(%d+)$'
	return _('unsigned %s: %d', name or '_', n)
end

local function pointer_ctype(s, name, ...) --('^type', 'name') -> ctype('type', '*name')
	return stype_ctype(s:sub(2), '*'..(name or ''), ...)
end

local function char_ptr_ctype(s, ...) --('*', 'name') -> 'char *name'
	return pointer_ctype('^c', ...)
end

local function primitive_ctype(ctype)
	return function(s, name)
		return ctype .. optname(name)
	end
end

local function const_ctype(s, ...)
	return 'const ' .. stype_ctype(s:sub(2), ...)
end

local ctype_decoders = {
	['c'] = primitive_ctype'char', --also for `BOOL` (boolean-ness is specified through method type annotations)
	['i'] = primitive_ctype'int',
	['s'] = primitive_ctype'short',
	['l'] = primitive_ctype'long', --treated as a 32-bit quantity on 64-bit programs
	['q'] = primitive_ctype'long long',

	['C'] = primitive_ctype'unsigned char',
	['I'] = primitive_ctype'unsigned int',
	['S'] = primitive_ctype'unsigned short',
	['L'] = primitive_ctype'unsigned long',
	['Q'] = primitive_ctype'unsigned long long',

	['f'] = primitive_ctype'float',
	['d'] = primitive_ctype'double',
	['D'] = primitive_ctype'long double',

	['B'] = primitive_ctype'BOOL', --does not appear in the runtime, but in bridgesupport
	['v'] = primitive_ctype'void',
	['?'] = primitive_ctype'void', --unknown type; used for function pointers among other things

	['@'] = primitive_ctype'id', --@ or @? or @"ClassName"
	['#'] = primitive_ctype'Class',
	[':'] = primitive_ctype'SEL',

	['['] = array_ctype,    -- [Ntype]         ; N = number of elements
	['{'] = struct_ctype,   -- {name=fields}   ; struct
	['('] = struct_ctype,   -- (name=fields)   ; union
	['b'] = bitfield_ctype, -- bN              ; N = number of bits
	['^'] = pointer_ctype,  -- ^type           ; pointer
	['*'] = char_ptr_ctype, -- *               ; char* pointer
	['r'] = const_ctype,
}

--convert a value type encoding (stype) to its C type, or, if name given, its C declaration.
--3rd arg = 'cdef' means that named structs contain field names and thus can and should be cdef'ed before returning.
function stype_ctype(s, name, ...)
	local decoder = assert(ctype_decoders[s:sub(1,1)], s)
	return decoder(s, name, ...)
end

--decode a method type encoding (mtype), and return its table representation (ftype).
--note: other type annotations like `variadic` and `isblock` come from bridgesupport attributes.
local function mtype_ftype(mtype) --eg. 'v12@0:4c8' (retval offset arg1 offset arg2 offset ...)
	local ftype = {}
	local retval
	local function addarg(annotations, s)
		if annotations:find'r' then
			s = 'r' .. s
		end
		if not retval then
			retval = s
		else
			table.insert(ftype, s)
		end
		return '' --remove the match
	end
	local s,n = mtype
	while s ~= '' do
		               s,n = s:gsub('^([rnNoORV]*)([%^]*%b{})%d*',     addarg)     --try {...}offset
		if n == 0 then s,n = s:gsub('^([rnNoORV]*)([%^]*%b())%d*',     addarg) end --try (...)offset
		if n == 0 then s,n = s:gsub('^([rnNoORV]*)([%^]*%b[])%d*',     addarg) end --try [...]offset
		if n == 0 then s,n = s:gsub('^([rnNoORV]*)(@%?)%d*',           addarg) end --try @? (block type)
		if n == 0 then s,n = s:gsub('^([rnNoORV]*)(@"[A-Z][^"]+")%d*', addarg) end --try @"Class"offset
		if n == 0 then s,n = s:gsub('^([rnNoORV]*)([%^]*[cislqCISLQfdDBv%?@#%:%*])%d*', addarg) end --try <primitive>offset
		assert(n > 0, mtype)
	end
	if retval ~= 'v' then
		ftype.retval = retval
	end
	return ftype
end

--check if a ftype cannot be fully used with ffi callbacks, so we need to employ workarounds.
local function ftype_needs_wrapping(ftype)
	--ffi callbacks don't work with vararg methods.
	if ftype.variadic then
		return true
	end
	--ffi callbacks don't work with pass-by-value structs.
	for i = 1, #ftype do
		if ftype[i]:find'^[%{%(]' then
			return true
		end
	end
	--they also can't return structs directly.
	if ftype.retval and ftype.retval:find'^[%{%(]' then
		return true
	end
end

--format a table representation of a method or function (ftype) to its C type or, if name given, its C declaration.
--3rd arg = true means the type will be used for a ffi callback, which incurs some limitations.
local function ftype_ctype(ftype, name, for_callback)
	local retval = ftype.retval
	local lastarg = #ftype
	if for_callback then
		--ffi callbacks don't work with pass-by-value structs, so we're going to stop at the first one.
		for i = 1, #ftype do
			if ftype[i]:find'^[%{%(]' then
				lastarg = i - 1
			end
		end
		--they also can't return structs directly.
		if retval and retval:find'^[%{%(]' then
			retval = nil
		end
	end
	local t = {}
	for i = 1, lastarg do
		t[i] = stype_ctype(ftype[i])
	end
	local args = table.concat(t, ', ')
	local retval = retval and stype_ctype(retval) or 'void'
	local vararg = not for_callback and ftype.variadic and (#t > 0 and ', ...' or '...') or ''
	if name then
		return _('%s %s (%s%s)', retval, name, args, vararg)
	else
		return _('%s (*) (%s%s)', retval, args, vararg)
	end
end

local function ftype_mtype(ftype) --convert ftype to method type encoding
	return (ftype.retval or 'v') .. table.concat(ftype)
end

local static_mtype_ftype = memoize(function(mtype) --ftype cache for non-anotated method types
	return mtype_ftype(mtype)
end)

--cache anonymous function objects by their signature because we can only make 64K anonymous ct objects
--in luajit2 and there are a lot of duplicate method and function-pointer signatures (named functions are separate).
local ctype_ct = memoize(function(ctype)
	local ok,ct = pcall(ffi.typeof, ctype)
	check(ok, 'ctype error for "%s": %s', ctype, ct)
	return ct
end)

local function ftype_ct(ftype, name, for_callback)
	local cachekey = 'cb_ct' or 'ct'
	local ct = ftype[cachekey] or ctype_ct(ftype_ctype(ftype, name, for_callback))
	ftype[cachekey] = ct --cache it, useful for static ftypes
	return ct
end

--bridgesupport file parsing ---------------------------------------------------------------------------------------------

lazyfuncs = true --cdef functions on the first call rather than at the time of parsing the xml (see below)
loaddeps = false --load dependencies specified in the bridgesupport file (usually too many to be useful)

--rename tables to prevent name clashes

rename = {string = {}, enum = {}, typedef = {}, const = {}, ['function'] = {}} --rename table to solve name clashing

rename.typedef.mach_timebase_info = 'mach_timebase_info_t'
rename.const.TkFont = 'const_TkFont'

local function global(name, kind) --return the "fixed" name for a given global name
	return rename[kind][name] or name
end

--xml tag handlers

local tag = {} --{tag = start_tag_handler}

function tag.depends_on(attrs)
	if not loaddeps then return end
	local ok, loaderr = pcall(load_framework, attrs.path)
	if not ok then
		err('load', '%s', loaderr)
	end
end

local typekey = x64 and 'type64' or 'type'
local valkey = x64 and 'value64' or 'value'

function tag.string_constant(attrs)
	--note: some of these are NSStrings but we load them all as Lua strings.
	rawset(objc, global(attrs.name, 'string'), attrs.value)
end

function tag.enum(attrs)
	if attrs.ignore == 'true' then return end

	local s = attrs[valkey] or attrs.value
	if not s then return end --value not available on this platform

	rawset(objc, global(attrs.name, 'enum'), tonumber(s))
end

local function cdef_node(attrs, typedecl, deftype)
	local name = global(attrs.name, typedecl)

	--note: duplicate typedef and const defs are ignored by luajit 2.0 and don't overflow its ctype table,
	--but this is an implementation detail that we shouldn't rely on, so we guard against redefinitions.
	if defined(name, 'global') then return end

	local s = attrs[typekey] or attrs.type
	if not s then return end --type not available on this platform

	local ctype = stype_ctype(s, name, deftype)
	declare(name, 'global', _('%s %s', typedecl, ctype))
end

function tag.constant(attrs)
	cdef_node(attrs, 'const')
end

function tag.struct(attrs)
	cdef_node(attrs, 'typedef', attrs.opaque ~= 'true' and 'cdef' or nil)
end

function tag.cftype(attrs)
	cdef_node(attrs, 'typedef', 'cdef')
end

function tag.opaque(attrs)
	cdef_node(attrs, 'typedef')
end

--arg or retval tag with function_pointer attribute

local function fp_arg(argtag, attrs, getwhile)
	if attrs.function_pointer ~= 'true' then
		return
	end

	local argtype = attrs[typekey] or attrs.type
	local fp = {isblock = argtype == '@?' or nil}
	if fp.isblock then fp[1] = '^v' end --adjust type: arg#1 is a pointer to the block object

	for tag, attrs in getwhile(argtag) do
		if tag == 'arg' or tag == 'retval' then

			if fp then
				local argtype = attrs[typekey] or attrs.type
				if not argtype then --type not available on this platform: skip the entire argtag
					fp = nil
				else
					local argindex = tag == 'retval' and 'retval' or #fp + 1
					if not (argindex == 'retval' and argtype == 'v') then
						fp[argindex] = argtype
					end
				end
			end

			local fp1 = fp_arg(tag, attrs, getwhile) --fpargs can have fpargs too
			if fp and fp1 then
				local argindex = tag == 'retval' and 'retval' or #fp + 1
				fp.fp = fp.fp or {}
				fp.fp[argindex] = fp1
			end

			for _ in getwhile(tag) do end --eat it because it might be the same as argtag
		end
	end

	return fp
end

--function tag

local function_caller --fw. decl.

local function add_function(name, ftype, lazy) --cdef and call-wrap a global C function
	if lazy == nil then lazy = lazyfuncs end

	local function addfunc()
		declare(name, 'global', ftype_ctype(ftype, name))
		local cfunc = csymbol(name)
		if not cfunc then
			err('symbol', 'missing C function: %s', name)
			return
		end
		local caller = function_caller(ftype, cfunc)
		rawset(objc, name, caller) --overshadow the C function with the caller
		return caller
	end

	if lazy then
		--delay cdef'ing the function until the first call, to avoid polluting the C namespace with unused declarations.
		--this is because in luajit2 can only hold as many as 64k ctypes total.
		rawset(objc, name, function(...)
			local func = addfunc()
			if not func then return end
			return func(...)
		end)
	else
		addfunc()
	end
end

tag['function'] = function(attrs, getwhile)
	local name = global(attrs.name, 'function') --get the "fixed" name

	--note: duplicate function defs are ignored by luajit 2.0 but they do overflow its ctype table,
	--so it's necessary that we guard against redefinitions.
	if defined(name, 'global') then return end

	local ftype = {variadic = attrs.variadic == 'true' or nil}

	for tag, attrs in getwhile'function' do
		if ftype and (tag == 'arg' or tag == 'retval') then

			local argtype = attrs[typekey] or attrs.type
			if not argtype then --type not available on this platform: skip the entire function
				ftype = nil
			else
				local argindex = tag == 'retval' and 'retval' or #ftype + 1
				if not (argindex == 'retval' and argtype == 'v') then
					ftype[argindex] = argtype
				end

				local fp = fp_arg(tag, attrs, getwhile)
				if fp then
					ftype.fp = ftype.fp or {}
					ftype.fp[argindex] = fp
				end
			end
		end
	end

	if ftype then
		add_function(name, ftype)
	end
end

--informal_protocol tag

local add_informal_protocol --fw. decl.
local add_informal_protocol_method --fw. decl.

function tag.informal_protocol(attrs, getwhile)
	local proto = add_informal_protocol(attrs.name)
	for tag, attrs in getwhile'informal_protocol' do
		if proto and tag == 'method' then
			local mtype = attrs[typekey] or attrs.type
			if mtype then
				add_informal_protocol_method(proto, attrs.selector, attrs.class_method ~= 'true', mtype)
			end
		end
	end
end

--class tag

--method type annotations: {[is_instance] = {classname = {methodname = partial-ftype}}.
--only boolean retvals and function pointer args are recorded.
local mta = {[true] = {}, [false] = {}}

function tag.class(attrs, getwhile)
	local inst_methods = {}
	local class_methods = {}
	local classname = attrs.name

	for tag, attrs in getwhile'class' do
		if tag == 'method' then

			local meth = {}
			local inst = attrs.class_method ~= 'true'
			meth.variadic = attrs.variadic == 'true' or nil
			local methodname = attrs.selector

			for tag, attrs in getwhile'method' do
				if meth and (tag == 'arg' or tag == 'retval') then

					local argtype = attrs[typekey] or attrs.type
					--attrs.index is the arg. index starting from 0 after the first two arguments (obj, sel).
					local argindex = tag == 'retval' and 'retval' or attrs.index + 1 + 2

					if tag == 'retval' and argtype == 'B' then
						meth.retval = 'B'
					end

					local fp = fp_arg(tag, attrs, getwhile)
					if fp then
						meth.fp = meth.fp or {}
						meth.fp[argindex] = fp
					end
				end
			end

			if meth and next(meth) then
				if inst then
					inst_methods[methodname] = meth
				else
					class_methods[methodname] = meth
				end
			end
		end
	end

	if next(inst_methods) then
		mta[true][classname] = inst_methods
	end
	if next(class_methods) then
		mta[false][classname] = class_methods
	end
end

local function get_raw_mta(classname, selname, inst)
	local cls = mta[inst][classname]
	return cls and cls[selname]
end

--function_alias tag

function tag.function_alias(attrs) --these tags always come after the 'function' tags
	local name = attrs.name
	local original = attrs.original
	--delay getting a cdef to the original function until the first call to the alias
	rawset(objc, name, function(...)
		local origfunc = objc[original]
		rawset(objc, name, origfunc) --replace this wrapper with the original function
		return origfunc(...)
	end)
end

--xml tag processor that dispatches the processing of tags inside <signatures> tag to a table of tag handlers.
--the tag handler gets the tag attributes and a conditional iterator to get any subtags.
local function process_tags(gettag)

	local function nextwhile(endtag)
		local start, tag, attrs = gettag()
		if not start then
			if tag == endtag then return end
			return nextwhile(endtag)
		end
		return tag, attrs
	end
	local function getwhile(endtag) --iterate tags until `endtag` ends, returning (tag, attrs) for each tag
		return nextwhile, endtag
	end

	for tagname, attrs in getwhile'signatures' do
		if tag[tagname] then
			tag[tagname](attrs, getwhile)
		end
	end
end

--fast, push-style xml parser that works with the simple cocoa generated xml files.

local function readfile(name)
	local f = assert(io.open(name, 'rb'))
	local s = f:read'*a'
	f:close()
	return s
end

local function parse_xml(path, write)
	local s = readfile(path)
	for endtag, tag, attrs, tagends in s:gmatch'<(/?)([%a_][%w_]*)([^/>]*)(/?)>' do
		if endtag == '/' then
			write(false, tag)
		else
			local t = {}
			for name, val in attrs:gmatch'([%a_][%w_]*)=["\']([^"\']*)["\']' do
				if val:find('&quot;', 1, true) then --gsub alone is way slower
					val = val:gsub('&quot;', '"') --the only escaping found in all xml files tested
				end
				t[name] = val
			end
			write(true, tag, t)
			if tagends == '/' then
				write(false, tag)
			end
		end
	end
end

--xml processor driver. runs a user-supplied tag processor function in a coroutine.
--the processor receives a gettags() function to pull tags with, as its first argument.

usexpat = false --choice of xml parser: expat or the lua-based parser above.

local function process_xml(path, processor, ...)

	local send = coroutine.wrap(processor)
	send(coroutine.yield, ...) --start the parser by passing it the gettag() function and other user args.

	if usexpat then
		local expat = require'expat'
		expat.parse({path = path}, {
			start_tag = function(name, attrs)
				send(true, name, attrs)
			end,
			end_tag = function(name)
				send(false, name)
			end,
		})
	else
		parse_xml(path, send)
	end
end

function load_bridgesupport(path)
	process_xml(path, process_tags)
end

--loading frameworks -----------------------------------------------------------------------------------------------------

loadtypes = true --load bridgesupport files

local searchpaths = {
	'/System/Library/Frameworks',
	'/Library/Frameworks',
	'~/Library/Frameworks',
}

function find_framework(name) --given a framework name or its full path, return its full path and its name
	if name:find'^/' then
		-- try 'path/foo.framework'
		local path = name
		local name = path:match'([^/]+)%.framework$'
		if not name then
			-- try 'path/foo.framework/foo'
			name = path:match'([^/]+)$'
			path = name and path:sub(1, -#name-2)
		end
		if name and canread(path) then
			return path, name
		end
	else
		local subname = name:gsub('%.framework', '%$') --escape the '.framework' suffix
		subname = subname:gsub('%.', '.framework/Versions/Current/Frameworks/') --expand 'Framework.Subframework' syntax
		subname = subname:gsub('%$', '.framework') --unescape it
		name = name:match'([^%./]+)$' --strip relative path from name
		for i,path in pairs(searchpaths) do
			path = _('%s/%s.framework', path, subname)
			if canread(path) then
				return path, name
			end
		end
	end
end

loaded = {} --{framework_name = true}
loaded_bs = {} --{framework_name = true}

function load_framework(namepath, option) --load a framework given its name or full path
	if not OSX then
		error('platform not OSX', 2)
	end
	local basepath, name = find_framework(namepath)
	check(basepath, 'framework not found %s', namepath)
	if not loaded[basepath] then
		--load the framework binary which contains classes, functions and protocols
		local path = _('%s/%s', basepath, name)
		if canread(path) then
			ffi.load(path, true)
		end
		--load the bridgesupport dylib which contains callable versions of inline functions (NSMakePoint, etc.)
		local path = _('%s/Resources/BridgeSupport/%s.dylib', basepath, name)
		if canread(path) then
			ffi.load(path, true)
		end
		log('load', '%s', basepath)
		loaded[basepath] = true
	end
	if loadtypes and option ~= 'notypes' and not loaded_bs[basepath] then
		loaded_bs[basepath] = true --set it before loading the file to prevent recursion from depends_on tag
		--load the bridgesupport xml file which contains typedefs and constants which we can't get from the runtime.
		local path = _('%s/Resources/BridgeSupport/%s.bridgesupport', basepath, name)
		if canread(path) then
			load_bridgesupport(path)
		end
	end
end

--objective-c runtime ----------------------------------------------------------------------------------------------------

--selectors

local selector_object = memoize(function(name) --cache to prevent string creation on each method call (worth it?)
	--replace '_' with ':' except at the beginning
	name = name:match('^_*') .. name:gsub('^_*', ''):gsub('_', ':')
	return ptr(C.sel_registerName(name))
end)

local function selector(name)
	if type(name) ~= 'string' then return name end
	return selector_object(name)
end

local function selector_name(sel)
    return ffi.string(C.sel_getName(sel))
end

ffi.metatype('struct objc_selector', {
	__tostring = selector_name,
	__index = {
		name = selector_name,
	},
})

--formal protocols

local function formal_protocols()
	return citer(own(C.objc_copyProtocolList(nil)))
end

local function formal_protocol(name)
	return ptr(C.objc_getProtocol(name))
end

local function formal_protocol_name(proto)
	return ffi.string(C.protocol_getName(proto))
end

local function formal_protocol_protocols(proto) --protocols of superprotocols not included
	return citer(own(C.protocol_copyProtocolList(proto, nil)))
end

local function formal_protocol_properties(proto) --inherited properties not included
	return citer(own(C.protocol_copyPropertyList(proto, nil)))
end

local function formal_protocol_property(proto, name, required, readonly) --looks in superprotocols too
	return ptr(C.protocol_getProperty(proto, name, required, readonly))
end

local function formal_protocol_methods(proto, inst, required) --inherited methods not included
	local desc = own(C.protocol_copyMethodDescriptionList(proto, required, inst, nil))
	local i = -1
	return function()
		i = i + 1
		if desc == nil then return end
		if desc[i].name == nil then return end
		--note: we return the name of the selector instead of the selector itself to match the informal protocol API
		return selector_name(desc[i].name), ffi.string(desc[i].types)
	end
end

local function formal_protocol_mtype(proto, sel, inst, required) --looks in superprotocols too
	local desc = C.protocol_getMethodDescription(proto, sel, required, inst)
	if desc.name == nil then return end
	return ffi.string(desc.types)
end

local function formal_protocol_ftype(...)
	return static_mtype_ftype(formal_protocol_mtype(...))
end

local function formal_protocol_ctype(proto, sel, inst, required, for_callback)
	return ftype_ctype(formal_protocol_ftype(proto, sel, inst, required), nil, for_callback)
end

local function formal_protocol_ct(proto, sel, inst, required, for_callback)
	return ftype_ct(formal_protocol_ftype(proto, sel, inst, required), nil, for_callback)
end

ffi.metatype('struct Protocol', {
	__tostring = formal_protocol_name,
	__index = {
		formal      = true,
		name        = formal_protocol_name,
		protocols   = formal_protocol_protocols,
		properties  = formal_protocol_properties,
		property    = formal_protocol_property,
		methods     = formal_protocol_methods, --iterator() -> selname, mtype
		mtype       = formal_protocol_mtype,
		ftype       = formal_protocol_ftype,
		ctype       = formal_protocol_ctype,
		ct          = formal_protocol_ct,
	},
})

--informal protocols (must have the exact same API as formal protocols)

local informal_protocols = {} --{name = proto}
local infprot = {formal = false}
local infprot_meta = {__index = infprot}

local function informal_protocol(name)
	return informal_protocols[name]
end

function add_informal_protocol(name)
	if OSX and formal_protocol(name) then return end --prevent needless duplication of formal protocols
	local proto = setmetatable({_name = name, _methods = {}}, infprot_meta)
	informal_protocols[name] = proto
	return proto
end

function add_informal_protocol_method(proto, selname, inst, mtype)
	proto._methods[selname] = {_inst = inst, _mtype = mtype}
end

function infprot:name()
	return self._name
end

infprot_meta.__tostring = infprot.name

local function noop() return end

function infprot:protocols()
	return noop --not in bridgesupport
end

function infprot:properties()
	return noop --not in bridgesupport
end

infprot.property = noop

function infprot:methods(inst, required)
	if required then return noop end --by definition, informal protocols do not contain required methods
	return coroutine.wrap(function()
		for sel, m in pairs(self._methods) do
			if m._inst == inst then
				coroutine.yield(sel, m._mtype)
			end
		end
	end)
end

function infprot:mtype(sel, inst, required)
	if required then return end --by definition, informal protocols do not contain required methods
	local m = self._methods[selector_name(sel)]
	return m and m._inst == inst and m._mtype or nil
end

function infprot:ftype(...)
	return static_mtype_ftype(self:mtype(...))
end

function infprot:ctype(sel, inst, required, for_callback)
	return ftype_ctype(self:ftype(sel, inst, required), nil, for_callback)
end

function infprot:ct(sel, inst, required, for_callback)
	return ftype_ct(self:ftype(sel, inst, required), nil, for_callback)
end

--all protocols

local function protocols() --list all loaded protocols
	return coroutine.wrap(function()
		for proto in formal_protocols() do
			coroutine.yield(proto)
		end
		for name, proto in pairs(informal_protocols) do
			coroutine.yield(proto)
		end
	end)
end

local function protocol(name) --protocol by name
	if type(name) ~= 'string' then return name end
	return check(formal_protocol(name) or informal_protocol(name), 'unknown protocol %s', name)
end

--properties

local function property_name(prop)
	return ffi.string(C.property_getName(prop))
end

local prop_attr_decoders = { --TODO: copy, retain, nonatomic, dynamic, weak, gc.
	T = function(s, t) t.stype = s end,
	V = function(s, t) t.ivar = s end,
	G = function(s, t) t.getter = s end,
	S = function(s, t) t.setter = s end,
	R = function(s, t) t.readonly = true end,
}
local property_attrs = memoize(function(prop) --cache to prevent parsing on each property access
	local s = ffi.string(C.property_getAttributes(prop))
	local attrs = {}
	for k,v in (s..','):gmatch'(.)([^,]*),' do
		local decode = prop_attr_decoders[k]
		if decode then decode(v, attrs) end
	end
	return attrs
end)

local function property_getter(prop)
	local attrs = property_attrs(prop)
	if not attrs.getter then
		attrs.getter = property_name(prop) --default getter; cache it
	end
	return attrs.getter
end

local function property_setter(prop)
	local attrs = property_attrs(prop)
	if attrs.readonly then return end
	if not attrs.setter then
		local name = property_name(prop)
		attrs.setter = _('set%s%s:', name:sub(1,1):upper(), name:sub(2)) --'name' -> 'setName:'
	end
	return attrs.setter
end

local function property_stype(prop)
	return property_attrs(prop).stype
end

local function property_ctype(prop)
	local attrs = property_attrs(prop)
	if not attrs.ctype then
		attrs.ctype = stype_ctype(attrs.stype) --cache it
	end
	return attrs.ctype
end

local function property_readonly(prop)
	return property_attrs(prop).readonly == true
end

local function property_ivar(prop)
	return property_attrs(prop).ivar
end

ffi.metatype('struct objc_property', {
	__tostring = property_name,
	__index = {
		name     = property_name,
		getter   = property_getter,
		setter   = property_setter,
		stype    = property_stype,
		ctype    = property_ctype,
		readonly = property_readonly,
		ivar     = property_ivar,
	},
})

--methods

local function method_selector(method)
	return ptr(C.method_getName(method))
end

local function method_name(method)
	return selector_name(method_selector(method))
end

local function method_mtype(method) --NOTE: this runtime mtype might look different if corected by mta
	return ffi.string(C.method_getTypeEncoding(method))
end

local function method_raw_ftype(method) --NOTE: this is the raw runtime ftype, not corrected by mta
	return mtype_ftype(method_mtype(method))
end

local function method_raw_ctype(method) --NOTE: this is the raw runtime ctype, not corrected by mta
	return ftype_ctype(method_raw_ftype(method))
end

local function method_raw_ctype_cb(method)
	return ftype_ctype(method_raw_ftype(method), nil, true)
end

local function method_imp(method) --NOTE: this is of type IMP (i.e. vararg, untyped).
	return ptr(C.method_getImplementation(method))
end

local method_exchange_imp = OSX and C.method_exchangeImplementations

ffi.metatype('struct objc_method', {
	__tostring = method_name,
	__index = {
		selector        = method_selector,
		name            = method_name,
		mtype           = method_mtype,
		raw_ftype       = method_raw_ftype,
		raw_ctype       = method_raw_ctype,
		raw_ctype_cb    = method_raw_ctype_cb,
		imp             = method_imp,
		exchange_imp    = method_exchange_imp,
	},
})

--classes

local function classes() --list all loaded classes
	return citer(own(C.objc_copyClassList(nil)))
end

local add_class_protocol --fw. decl.

local function isobj(x)
	return ffi.istype(id_ct, x)
end

local class_ct = ffi.typeof'Class'
local function isclass(x)
	return ffi.istype(class_ct, x)
end

local function ismetaclass(cls)
	return C.class_isMetaClass(cls) == 1
end

local classof = OSX and C.object_getClass

local function class(name, super, proto, ...) --find or create a class

	if super == nil then --want to find a class, not to create one
		if isclass(name) then --class object: pass through
			return name
		end
		if isobj(name) then --instance: return its class
			return classof(name)
		end
		check(type(name) == 'string', 'object, class, or class name expected, got %s', type(name))
		return ptr(C.objc_getClass(name))
	else
		check(type(name) == 'string', 'class name expected, got %s', type(name))
	end

	--given a second arg., check for 'SuperClass <Prtocol1, Protocol2,...>' syntax
	if type(super) == 'string' then
		local supername, protos = super:match'^%s*([^%<%s]+)%s*%<%s*([^%>]+)%>%s*$'
		if supername then
			local t = {}
			for proto in (protos..','):gmatch'([^,%s]+)%s*,%s*' do
				t[#t+1] = proto
			end
			t[#t+1] = proto
			for i = 1, select('#', ...) do
				t[#t+1] = select(i, ...)
			end
			return class(name, supername, unpack(t))
		end
	end

	local superclass
	if super then
		superclass = class(super)
		check(superclass, 'superclass not found %s', super)
	end

	check(not class(name), 'class already defined %s', name)

	local cls = check(ptr(C.objc_allocateClassPair(superclass, name, 0)))
	C.objc_registerClassPair(cls)
	--TODO: we can't dispose the class if it has subclasses, so figure out
	--a way to dispose it only after the last subclass has been disposed.
	--ffi.gc(cls, C.objc_disposeClassPair)
	if proto then
		add_class_protocol(cls, proto, ...)
	end

	return cls
end

local function class_name(cls)
	if isobj(cls) then cls = classof(cls) end
	return ffi.string(C.class_getName(class(cls)))
end

local function superclass(cls) --note: superclass(metaclass(cls)) == metaclass(superclass(cls))
	if isobj(cls) then cls = classof(cls) end
	return ptr(C.class_getSuperclass(class(cls)))
end

local function metaclass(cls) --note: metaclass(metaclass(cls)) == nil
	cls = class(cls)
	if isobj(cls) then cls = classof(cls) end
	if ismetaclass(cls) then return nil end --OSX sets metaclass.isa to garbage
	return ptr(classof(cls))
end

local function isa(cls, what)
	what = class(what)
	if isobj(cls) then
		return classof(cls) == what or isa(classof(cls), what)
	end
	local super = superclass(cls)
	if super == what then
		return true
	elseif not super then
		return false
	end
	return isa(super, what)
end

--class protocols

local class_informal_protocols = {} --{[nptr(cls)] = {name = informal_protocol,...}}

local function class_protocols(cls) --does not include protocols of superclasses
	return coroutine.wrap(function()
		for proto in citer(own(C.class_copyProtocolList(cls, nil))) do
			coroutine.yield(proto)
		end
		local t = class_informal_protocols[nptr(cls)]
		if not t then return end
		for name, proto in pairs(t) do
			coroutine.yield(proto)
		end
	end)
end

local function class_conforms(cls, proto)
	cls = class(cls)
	proto = protocol(proto)
	if proto.formal then
		return C.class_conformsToProtocol(cls, proto) == 1
	else
		local t = class_informal_protocols[nptr(cls)]
		return t and t[proto:name()] and true or false
	end
end

function add_class_protocol(cls, proto, ...)
	cls = class(cls)
	proto = protocol(proto)
	if proto.formal then
		C.class_addProtocol(class(cls), proto)
	else
		local t = class_informal_protocols[nptr(cls)]
		if not t then
			t = {}
			class_informal_protocols[nptr(cls)] = t
		end
		t[proto:name()] = proto
	end
	if ... then
		add_class_protocol(cls, ...)
	end
end

--find a selector in conforming protocols and if found, return its type
local function conforming_mtype(cls, sel)
	local inst = not ismetaclass(cls)
	for proto in class_protocols(cls) do
		local mtype =
			proto:mtype(sel, inst, false) or
			proto:mtype(sel, inst, true)
		if mtype then
			return mtype
		end
	end
	if superclass(cls) then
		return conforming_mtype(superclass(cls), sel)
	end
end

--class properties

local function class_properties(cls) --inherited properties not included
	return citer(own(C.class_copyPropertyList(cls, nil)))
end

local function class_property(cls, name) --looks in superclasses too
	return ptr(C.class_getProperty(cls, name))
end

--class methods

local function class_methods(cls) --inherited methods not included
	return citer(own(C.class_copyMethodList(class(cls), nil)))
end

local function class_method(cls, sel) --looks for inherited methods too
	return ptr(C.class_getInstanceMethod(class(cls), selector(sel)))
end

local function class_responds(cls, sel) --looks for inherited methods too
	return C.class_respondsToSelector(superclass(cls), selector(sel)) == 1
end

local callback_caller -- fw. decl.

cbframe = false --use cbframe for struct-by-val callbacks
local cbframe_stack = {}

local function use_cbframe()
	table.insert(cbframe_stack, cbframe)
	cbframe = true
end

local function stop_using_cbframe()
	cbframe = table.remove(cbframe_stack)
end

local function add_class_method(cls, sel, func, ftype)
	cls = class(cls)
	sel = selector(sel)
	ftype = ftype or 'v@:'
	local mtype = ftype
	if type(ftype) == 'string' then --it's a mtype, parse it
		ftype = mtype_ftype(mtype)
	else
		mtype = ftype_mtype(ftype)
	end
	local imp
	if cbframe and ftype_needs_wrapping(ftype) then
		local cbframe = require'cbframe'            --runtime dependency, only needed with `cbframe` debug option.
		local callback = cbframe.new(func)          --note: pins func; also, it will never be released.
		imp = cast('IMP', callback.p)
	else
		local func = function(obj, sel, ...) --wrap to skip sel arg
			return func(obj, ...)
		end
		local func = callback_caller(ftype, func)   --wrapper that converts args and return values.
		local ct = ftype_ct(ftype, nil, true)       --get the callback ctype stripped of pass-by-val structs
		local callback = cast(ct, func)         --note: pins func; also, it will never be released.
		imp = cast('IMP', callback)
	end
	C.class_replaceMethod(cls, sel, imp, mtype) --add or replace
	if logtopics.addmethod then
		log('addmethod', '  %-40s %-40s %-8s %s', class_name(cls), selector_name(sel),
				ismetaclass(cls) and 'class' or 'inst', ftype_ctype(ftype, nil, true))
	end
end

--ivars

local function class_ivars(cls)
	return citer(own(C.class_copyIvarList(cls, nil)))
end

local function class_ivar(cls, name)
	return ptr(C.class_getInstanceVariable(cls, name))
end

local function ivar_name(ivar)
	return ffi.string(C.ivar_getName(ivar))
end

local function ivar_offset(ivar) --this could be just an alias but we want to load this module in windows too
	return C.ivar_getOffset(ivar)
end

local function ivar_stype(ivar)
	return ffi.string(C.ivar_getTypeEncoding(ivar))
end

local function ivar_stype_ctype(stype)
	local stype = stype:match'^[rnNoORV]*(.*)'
	return stype_ctype('^'..stype, nil, stype:find'^[%{%(]%?' and 'cdef')
end

local function ivar_ctype(ivar) --NOTE: bitfield ivars not supported (need ivar layouts for that)
	return ivar_stype_ctype(ivar_stype(ivar))
end

local ivar_stype_ct = memoize(function(stype) --cache to avoid re-parsing and ctype creation
	return ffi.typeof(ivar_stype_ctype(stype))
end)

local function ivar_ct(ivar)
	return ivar_stype_ct(ivar_stype(ivar))
end

local byteptr_ct = ffi.typeof'uint8_t*'

local function ivar_get_value(obj, name, ivar)
	return cast(ivar_ct(ivar), cast(byteptr_ct, obj) + ivar_offset(ivar))[0]
end

local function ivar_set_value(obj, name, ivar, val)
	cast(ivar_ct(ivar), cast(byteptr_ct, obj) + ivar_offset(ivar))[0] = val
end

ffi.metatype('struct objc_ivar', {
	__tostring = ivar_name,
	__index = {
		name   = ivar_name,
		stype  = ivar_stype,
		ctype  = ivar_ctype,
		ct     = ivar_ct,
		offset = ivar_offset,
	},
})

--class/instance luavars

local luavars = {} --{[nptr(cls|obj)] = {var1 = val1, ...}}

local function get_luavar(obj, var)
	local vars = luavars[nptr(obj)]
	return vars and vars[var]
end

local function set_luavar(obj, var, val)
	local vars = luavars[nptr(obj)]
	if not vars then
		vars = {}
		luavars[nptr(obj)] = vars
	end
	vars[var] = val
end

--class/instance/protocol method finding based on loose selector names.
--loose selector names are those that may or may not contain a trailing '_'.

local function find_method(cls, selname)
	local sel = selector(selname)
	local meth = class_method(cls, sel)
	if meth then return sel, meth end
	--method not found, try again with a trailing '_' or ':'
	if not (selname:find('_', #selname, true) or selname:find(':', #selname, true)) then
		return find_method(cls, selname..'_')
	end
end

local function find_conforming_mtype(cls, selname)
	local sel = selector(selname)
	local mtype = conforming_mtype(cls, sel)
	if mtype then return sel, mtype end
	if not selname:find'[_%:]$' then --method not found, try again with a trailing '_'
		return find_conforming_mtype(cls, selname..'_')
	end
end

--method ftype annotation

local function get_mta(cls, sel) --looks in superclasses too
	local mta = get_raw_mta(class_name(cls), selector_name(sel), not ismetaclass(cls))
	if mta then return mta end
	cls = superclass(cls)
	if not cls then return end
	return get_mta(cls, sel)
end

local function annotate_ftype(ftype, mta)
	if mta then --the mta is a partial ftype: add it over
		for k,v in pairs(mta) do
			ftype[k] = v
		end
	end
	return ftype
end

local function method_ftype(cls, sel, method)
	method = method or class_method(cls, sel)
	local mta = get_mta(cls, sel)
	if mta then
		return annotate_ftype(method_raw_ftype(method), mta)
	else
		return static_mtype_ftype(method_mtype(method))
	end
end

local function method_arg_ftype(cls, selname, argindex) --for constructing blocks to pass to methods
	check(argindex, 'argindex expected')
	local sel, method = find_method(cls, selname)
	if not sel then return end
	local ftype = method_ftype(cls, sel, method)
	argindex = argindex or 1
	argindex = argindex == 'retval' and argindex or argindex + 2
	return ftype, argindex
end

--class/instance method caller based on loose selector names.

--NOTE: ffi.gc() applies to cdata objects, not to the identities that they hold. Thus you can easily get
--the same object from two different method invocations into two distinct cdata objects. Setting ffi.gc()
--on both will result in your finalizer being called twice, each time when each cdata gets collected.
--This means that references to objects need to be refcounted if per-object resources need to be released on gc.

local refcounts = {} --number of collectable cdata references to an object

local function inc_refcount(obj, n)
	local refcount = (refcounts[nptr(obj)] or 0) + n
	assert(refcount >= 0, 'over-releasing')
	refcounts[nptr(obj)] = refcount ~= 0 and refcount or nil
	return refcount
end

local function release_object(obj)
	if inc_refcount(obj, -1) == 0 then
		luavars[nptr(obj)] = nil
	end
end

local function collect_object(obj) --note: assume this will be called multiple times on the same obj!
	obj:release()
end

--methods for which we should refrain from retaining the result object
noretain = {release=1, autorelease=1, retain=1, alloc=1, new=1, copy=1, mutableCopy=1}

--cache it to avoid re-parsing, annotating, formatting, casting, function-wrapping, method-wrapping.
local method_caller = memoize2(function(cls, selname)
	local sel, method = find_method(cls, selname)
	if not sel then return end

	local ftype = method_ftype(cls, sel, method)
	local ct = ftype_ct(ftype)

	local func = method_imp(method)
	local func = cast(ct, func)
	local func = function_caller(ftype, func)

	local can_retain = not noretain[selname]
	local is_release = selname == 'release' or selname == 'autorelease'
	local log_refcount = (is_release or selname == 'retain') and logtopics.refcount

	return function(obj, ...)

		local before_rc, after_rc, objstr, before_luarc, after_luarc
		if log_refcount then
			--get stuff from obj now because after the call obj can be a dead parrot
			objstr = tostring(obj)
			before_rc = tonumber(obj:retainCount())
			before_luarc = inc_refcount(obj, 0)
		end

		local ok, ret = xpcall(func, debug.traceback, obj, sel, ...)
		if not ok then
			check(false, '[%s %s] %s', tostring(cls), tostring(sel), ret)
		end
		if is_release then
			ffi.gc(obj, nil) --disown this reference to obj
			release_object(obj)
			if before_rc == 1 then
				after_rc = 0
			end
		elseif isobj(ret) then
			if can_retain then
				ret = ret:retain() --retain() will make ret a strong reference so we don't have to
			else
				ffi.gc(ret, collect_object)
				inc_refcount(ret, 1)
			end
		end

		if log_refcount then
			after_rc = after_rc or tonumber(obj:retainCount())
			after_luarc = inc_refcount(obj, 0)
			log('refcount', '%s: %d -> %d (%d -> %d)', objstr, before_luarc, after_luarc, before_rc, after_rc)
		end

		return ret
	end
end)

--add, replace or override an existing/conforming instance/class method based on a loose selector name
local function override(cls, selname, func, ftype) --returns true if a method was found and created
	--look to override an existing method
	local sel, method = find_method(cls, selname)
	if sel then
		ftype = ftype or method_ftype(cls, sel, method)
		add_class_method(cls, sel, func, ftype)
		return true
	end
	--look to override/create a conforming method
	local sel, mtype = find_conforming_mtype(cls, selname)
	if sel then
		ftype = ftype or static_mtype_ftype(mtype)
		add_class_method(cls, sel, func, ftype)
		return true
	end
	--try again on the metaclass
	cls = metaclass(cls)
	if cls then
		return override(cls, selname, func, ftype)
	end
end

--call a method in the superclass of obj
local function callsuper(obj, selname, ...)
	local super = superclass(obj)
	if not super then return end
	return method_caller(super, selname)(obj, ...)
end

--swap two instance/class methods of a class.
--the second selector can be a new selector, in which case:
--  1) it can't be a loose selector.
--  2) its implementation (func) must be given.
local function swizzle(cls, selname1, selname2, func)
	cls = class(cls)
	local sel1, method1 = find_method(cls, selname1)
	local sel2, method2 = find_method(cls, selname2)
	if not sel1 then
		--try again on the metaclass
		cls = metaclass(cls)
		if cls then
			return swizzle(cls, selname1, selname2, func)
		else
			check(false, 'method not found: %s', selname1)
		end
	end
	if not sel2 then
		check(func, 'implementation required for swizzling with new selector')
		local ftype = method_ftype(cls, sel1, method1)
		sel2 = selector(selname2)
		add_class_method(cls, sel2, func, ftype)
		method2 = class_method(cls, sel2)
		assert(method2)
	else
		check(not func, 'second selector already implemented')
	end
	method1:exchange_imp(method2)
end

--class fields

--try to get, in order:
--		a class luavar
--		a readable class property
--		a class method
--		a class luavar from a superclass
local function get_class_field(cls, field)
	assert(cls ~= nil, 'attempt to index a NULL class')
	--look for an existing class luavar
	local val = get_luavar(cls, field)
	if val ~= nil then
		return val
	end
	--look for a class property
	local prop = class_property(cls, field)
	if prop then
		local caller = method_caller(metaclass(cls), property_getter(prop))
		if caller then --the getter is a class method so this is a "class property"
			return caller(cls)
		end
	end
	--look for a class method
	local meth = method_caller(metaclass(cls), field)
	if meth then return meth end
	--look for an existing class luavar in a superclass
	cls = superclass(cls)
	while cls do
		local val = get_luavar(cls, field)
		if val ~= nil then
			return val
		end
		cls = superclass(cls)
	end
end

-- try to set, in order:
--		an existing class luavar
--		a writable class property
--		an instance method
--		a conforming instance method
--		a class method
--		a conforming class method
--		an existing class luavar in a superclass
local function set_existing_class_field(cls, field, val)
	--look to set an existing class luavar
	if get_luavar(cls, field) ~= nil then
		set_luavar(cls, field, val)
		return true
	end
	--look to set a writable class property
	local prop = class_property(cls, field)
	if prop then
		local setter = property_setter(prop)
		if setter then --not read-only
			local caller = method_caller(metaclass(cls), setter)
			if caller then --the setter is a class method so this is a "class property"
				caller(cls, val)
				return true
			end
		end
	end
	--look to override an instance/instance-conforming/class/class-conforming method, in this order
	if override(cls, field, val) then return true end
	--look to set an existing class luavar in a superclass
	cls = superclass(cls)
	while cls do
		if get_luavar(cls, field) ~= nil then
			set_luavar(cls, field, val)
			return true
		end
		cls = superclass(cls)
	end
end

--try to set, in order:
--		an existing class field (see above)
--		a new class luavar
local function set_class_field(cls, field, val)
	assert(cls ~= nil, 'attempt to index a NULL class')
	--look to set an existing class field
	if set_existing_class_field(cls, field, val) then return end
	--finally, set a new class luavar
	set_luavar(cls, field, val)
end

ffi.metatype('struct objc_class', {
	__tostring = class_name,
	__index = get_class_field,
	__newindex = set_class_field,
})

--instance fields

--try to get, in order;
--		an instance luavar
--		a readable instance property
--		an ivar
--		an instance method
--		a class field (see above)
local function get_instance_field(obj, field)
	assert(obj ~= nil, 'attempt to index a NULL object')
	--shortcut: look for an existing instance luavar
	local val = get_luavar(obj, field)
	if val ~= nil then
		return val
	end
	local cls = classof(obj)
	--look for an instance property
	local prop = class_property(cls, field)
	if prop then
		local caller = method_caller(cls, property_getter(prop))
		if caller then --the getter is an instance method so this is an "instance property"
			return caller(obj)
		end
	end
	--look for an ivar
	local ivar = class_ivar(cls, field)
	if ivar then
		return ivar_get_value(obj, field, ivar)
	end
	--look for an instance method
	local caller = method_caller(cls, field)
	if caller then
		return caller
	end
	--finally, look for a class field
	return get_class_field(cls, field)
end

--try to set, in order:
--		an existing instance luavar
--		a writable instance property
--		an ivar
--		an existing class field (see above)
--		a new instance luavar
local function set_instance_field(obj, field, val)
	assert(obj ~= nil, 'attempt to index a NULL object')
	--shortcut: look to set an existing instance luavar
	if get_luavar(obj, field) ~= nil then
		set_luavar(obj, field, val)
		return
	end
	local cls = classof(obj)
	--look to set a writable instance property
	local prop = class_property(cls, field)
	if prop then
		local setter = property_setter(prop)
		if setter then --not read-only
			local caller = method_caller(cls, setter)
			if caller then --the setter is an instance method so this is an "instance property"
				caller(obj, val)
				return
			end
		else
			check(false, 'attempt to write to read/only property "%s"', field)
		end
	end
	--look to set an ivar
	local ivar = class_ivar(cls, field)
	if ivar then
		ivar_set_value(obj, field, ivar, val)
		return
	end
	--look to set an existing class field
	if set_existing_class_field(cls, field, val) then return end
	--finally, add a new luavar
	set_luavar(obj, field, val)
end

local object_tostring

if ffi.sizeof(intptr_ct) > 4 then
	function object_tostring(obj)
		if obj == nil then return 'nil' end
		local i = cast('uintptr_t', obj)
		local lo = tonumber(i % 2^32)
		local hi = math.floor(tonumber(i / 2^32))
		return _('<%s: 0x%s>', class_name(obj), hi ~= 0 and _('%x%08x', hi, lo) or _('%x', lo))
	end
else
	function object_tostring(obj)
		if obj == nil then return 'nil' end
		return _('<%s>0x%08x', class_name(obj), tonumber(cast('uintptr_t', obj)))
	end
end

ffi.metatype('struct objc_object', {
	__tostring = object_tostring,
	__index = get_instance_field,
	__newindex = set_instance_field,
})

--blocks -----------------------------------------------------------------------------------------------------------------

--http://clang.llvm.org/docs/Block-ABI-Apple.html

ffi.cdef[[
typedef void (*dispose_helper_t) (void *src);
typedef void (*copy_helper_t)    (void *dst, void *src);

struct block_descriptor {
	unsigned long int reserved;         // NULL
	unsigned long int size;             // sizeof(struct block_literal)
	copy_helper_t     copy_helper;      // IFF (1<<25)
	dispose_helper_t  dispose_helper;   // IFF (1<<25)
};

struct block_literal {
	struct block_literal *isa;
	int flags;
	int reserved;
	void *invoke;
	struct block_descriptor *descriptor;
	struct block_descriptor d; // because they come in pairs
};

struct block_literal *_NSConcreteGlobalBlock;
struct block_literal *_NSConcreteStackBlock;
]]

local voidptr_ct        = ffi.typeof'void*'
local block_ct          = ffi.typeof'struct block_literal'
local copy_helper_ct    = ffi.typeof'copy_helper_t'
local dispose_helper_ct = ffi.typeof'dispose_helper_t'

--create a block and return it typecast to 'id'.
--note: the automatic memory management part adds an overhead of 2 closures + 2 ffi callback objects.
local function block(func, ftype)

	if isobj(func) then
		return func --must be a block, pass it through
	end

	ftype = ftype or {'v'}
	if type(ftype) == 'string' then
		ftype = mtype_ftype(ftype)
	end
	if not ftype.isblock then --not given a block ftype, adjust it
		ftype.isblock = true
		table.insert(ftype, 1, '^v') --first arg. is the block object
	end

	local callback, callback_ptr
	if cbframe and ftype_needs_wrapping(ftype) then
		local cbframe = require'cbframe'            --runtime dependency, only needed with `cbframe` debug option.
		callback = cbframe.new(func)
		callback_ptr = callback.p
	else
		local func = callback_caller(ftype, func)   --wrapper to convert args and retvals
		local function caller(block, ...)           --wrapper to remove the first arg
			return func(...)
		end
		local ct = ftype_ct(ftype, nil, true)
		callback = cast(ct, caller)
		callback_ptr = callback
	end

	local refcount = 1

	local function copy(dst, src)
		refcount = refcount + 1
		log('block', 'copy\trefcount: %-8d', refcount)
		assert(refcount >= 2)
	end

	local block
	local copy_callback
	local dispose_callback

	local function dispose(src)
		refcount = refcount - 1
		if refcount == 0 then
			block = nil --unpin it. this reference also serves to pin it until refcount is 0.
			callback:free()
			copy_callback:free()
			dispose_callback:free()
		end
		log('block', 'dispose\trefcount: %-8d', refcount)
		assert(refcount >= 0)
	end

	copy_callback = cast(copy_helper_ct, copy)
	dispose_callback = cast(dispose_helper_ct, dispose)

	block = block_ct()

	block.isa        = C._NSConcreteStackBlock --stack block because global blocks are not copied/disposed
	block.flags      = 2^25 --has copy & dispose helpers
	block.reserved   = 0
	block.invoke     = cast(voidptr_ct, callback_ptr) --callback is pinned by dispose()
	block.descriptor = block.d
	block.d.reserved = 0
	block.d.size     = ffi.sizeof(block_ct)
	block.d.copy_helper    = copy_callback
	block.d.dispose_helper = dispose_callback

	local block_object = cast(id_ct, block) --block remains pinned by dispose()
	ffi.gc(block_object, dispose)

	log('block', 'create\trefcount: %-8d', refcount)
	return block_object
end

--Lua type conversions ---------------------------------------------------------------------------------------------------

local function toobj(v) --convert a lua value to an objc object representing that value
	if type(v) == 'number' then
		return objc.NSNumber:numberWithDouble(v)
	elseif type(v) == 'string' then
	  return objc.NSString:stringWithUTF8String(v)
	elseif type(v) == 'table' then
		if #v == 0 then
			 local dic = objc.NSMutableDictionary:dictionary()
			 for k,v in pairs(v) do
				  dic:setObject_forKey(toobj(v), toobj(k))
			 end
			 return dic
		else
			 local arr = objc.NSMutableArray:array()
			 for i,v in ipairs(v) do
				  arr:addObject(toobj(v))
			 end
			 return arr
		end
	elseif isclass(v) then
		return cast(id_ct, v) --needed to convert arg#1 for class methods
	else
		return v --pass through
	end
end

local function tolua(obj) --convert an objc object that converts naturally to a lua value
	if isa(obj, objc.NSNumber) then
		return obj:doubleValue()
	elseif isa(obj, objc.NSString) then
		return obj:UTF8String()
	elseif isa(obj, objc.NSDictionary) then
		local t = {}
		local count = tonumber(obj:count())
		local vals = ffi.new('id[?]', count)
		local keys = ffi.new('id[?]', count)
		obj:getObjects_andKeys(vals, keys)
		for i = 0, count-1 do
			t[tolua(keys[i])] = tolua(vals[i])
		end
		return t
	elseif isa(obj, objc.NSArray) then
		local t = {}
		for i = 0, tonumber(obj:count())-1 do
			t[#t+1] = tolua(obj:objectAtIndex(i))
		end
		return t
	else
		return obj --pass through
	end
end

--convert arguments and retvals for functions and methods

local function convert_fp_arg(ftype, arg)
	if type(arg) ~= 'function' then
		return arg --pass through
	end
	if ftype.isblock then
		return block(arg, ftype)
	else
		local ct = ftype_ct(ftype, nil, true)
		return cast(ct, arg) --note: to get a chance to free this callback, you must get it with toarg()
	end
end

local function convert_arg(ftype, i, arg)
	local argtype = ftype[i]
	if argtype == ':' then
		return selector(arg) --selector, string
	elseif argtype == '#' then
		return class(arg) --class, obj, classname
	elseif argtype == '@' then
		return toobj(arg) --string, number, array-table, dict-table
	elseif ftype.fp and ftype.fp[i] then
		return convert_fp_arg(ftype.fp[i], arg) --function
	else
		return arg --pass through
	end
end

--not a tailcall and not JITed but at least it doesn't make any garbage.
--NOTE: this stumbles on "call unroll limit reached" and doing it with
--an accumulator table triggers "NYI: return to lower frame".
local function convert_args(ftype, i, ...)
	if select('#', ...) == 0 then return end
	return convert_arg(ftype, i, ...), convert_args(ftype, i + 1, select(2, ...))
end

local function toarg(cls, selname, argindex, arg)
	local ftype, argindex = method_arg_ftype(cls, selname, argindex)
	if not ftype then return end
	return convert_arg(ftype, argindex, arg)
end

--wrap a function for automatic type conversion of its args and return value.
local function convert_ret(ftype, ret)
	if ret == nil then
		return nil --NULL -> nil
	elseif ftype.retval == 'B' then
		return ret == 1 --BOOL -> boolean
	elseif ftype.retval == '*' or ftype.retval == 'r*' then
		return ffi.string(ret)
	else
		return ret --pass through
	end
end
function function_caller(ftype, func)
	if #ftype == 0 then
		return function()
			return convert_ret(ftype, func())
		end
	elseif #ftype == 1 then
		return function(arg)
			return convert_ret(ftype, func(convert_arg(ftype, 1, arg)))
		end
	elseif #ftype == 2 and ftype[1] == '@' and ftype[2] == ':' then --method, 0 args
		return function(arg1, arg2)
			return convert_ret(ftype, func(toobj(arg1), selector(arg2)))
		end
	elseif #ftype == 3 and ftype[1] == '@' and ftype[2] == ':' then --method, 1 arg
		return function(arg1, arg2, arg3)
			return convert_ret(ftype, func(toobj(arg1), selector(arg2),
				convert_arg(ftype, 3, arg3)))
		end
	else
		return function(...)
			return convert_ret(ftype, func(convert_args(ftype, 1, ...)))
		end
	end
end

--convert arguments and retvals for callbacks, i.e. overriden methods and blocks

local function convert_cb_fp_arg(ftype, arg)
	if ftype.isblock then
		return arg --let the user use it as an object, and call :invoke(), :retain() etc.
	else
		return cast(ftype_ct(ftype), arg)
	end
end

local function convert_cb_arg(ftype, i, arg)
	if ftype.fp and ftype.fp[i] then
		return convert_cb_fp_arg(ftype.fp[i], arg)
	else
		return arg --pass through
	end
end

local function convert_cb_args(ftype, i, ...) --not a tailcall but at least it doesn't make any garbage
	if select('#', ...) == 0 then return end
	return convert_cb_arg(ftype, i, ...), convert_cb_args(ftype, i + 1, select(2, ...))
end

--wrap a callback for automatic type conversion of its args and return value.
function callback_caller(ftype, func)
	if not ftype.fp then
		if ftype.retval == '@' then --only the return value to convert
			return function(...)
				return toobj(func(...))
			end
		else --nothing to convert
			return func
		end
	end
	return function(...)
		local ret = func(convert_cb_args(ftype, 1, ...))
		if ftype.retval == '@' then
			return toobj(ret)
		else
			return ret
		end
	end
end

--iterators --------------------------------------------------------------------------------------------------------------

local function array_next(arr, i)
	if i >= arr:count() then return end
	return i + 1, arr:objectAtIndex(i)
end

local function array_ipairs(arr)
	return array_next, arr, 0
end

--publish everything -----------------------------------------------------------------------------------------------------

local function objc_protocols(cls) --compressed API
	if not cls then
		return protocols()
	else
		return class_protocols(cls)
	end
end

--debug
objc.C = C
objc.debug = P
objc.use_cbframe = use_cbframe
objc.stop_using_cbframe = stop_using_cbframe

--manual declarations
objc.addfunction = add_function
objc.addprotocol = add_informal_protocol
objc.addprotocolmethod = add_informal_protocol_method

--loading frameworks
objc.load = load_framework
objc.searchpaths = searchpaths
objc.memoize = memoize
objc.findframework = find_framework

--low-level type conversions (mostly for testing)
objc.stype_ctype = stype_ctype
objc.mtype_ftype = mtype_ftype
objc.ftype_ctype = ftype_ctype
objc.ctype_ct    = ctype_ct
objc.ftype_ct    = ftype_ct
objc.method_ftype = method_ftype

--runtime/get
objc.SEL = selector
objc.protocols = objc_protocols
objc.protocol = protocol
objc.classes = classes
objc.isclass = isclass
objc.isobj = isobj
objc.ismetaclass = ismetaclass
objc.class = class
objc.classname = class_name
objc.superclass = superclass
objc.metaclass = metaclass
objc.isa = isa
objc.conforms = class_conforms
objc.properties = class_properties
objc.property = class_property
objc.methods = class_methods
objc.method = class_method
objc.responds = class_responds
objc.ivars = class_ivars
objc.ivar = class_ivar
objc.conform = add_class_protocol
objc.toarg = toarg

--runtime/add
objc.override = override
objc.addmethod = add_class_method
objc.swizzle = swizzle

--runtime/call
objc.caller = function(cls, selname)
	return
		method_caller(class(cls), tostring(selname)) or
		method_caller(metaclass(cls), tostring(selname))
end
objc.callsuper = callsuper

--hi-level type conversions
objc.block = block
objc.toobj = toobj
objc.tolua = tolua
objc.nptr  = nptr
objc.ipairs = array_ipairs

--autoload
local submodules = {
	inspect = 'objc_inspect',   --inspection tools
	dispatch = 'objc_dispatch', --GCD binding
}
local function autoload(k)
	return submodules[k] and require(submodules[k]) and objc[k]
end

--dynamic namespace
setmetatable(objc, {
	__index = function(t, k)
		return class(k) or csymbol(k) or autoload(k)
	end,
	__autoload = submodules, --for inspection
})

--print namespace
if not ... then
	for k,v in pairs(objc) do
		print(_('%-10s %s', type(v), 'objc.'..k))
		if k == 'debug' then
			for k,v in pairs(P) do
				print(_('%-10s %s', type(v), 'objc.debug.'..k))
			end
		end
	end
end


return objc
