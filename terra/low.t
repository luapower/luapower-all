
--Lua+Terra standard library & flat vocabulary of tools.
--Written by Cosmin Apreutesei. Public domain.

--Intended to be used as global environment: setfenv(1, require'terra/low').

if not ... then require'terra/low_test'; return; end

--dependencies ---------------------------------------------------------------

local _M --this module, set below

--create a module table that dynamically inherits from _M.
local function module(parent)
	parent = parent or _M
	local M = {__index = parent}
	M._M = M
	return setmetatable(M, M)
end

local C = module(_G) --the C namespace: include() and extern() dump symbols here.
_M = module(C) --inherits C instead of polluting it.
setfenv(1, _M) --globals go to _M from here on.

_M.C = C
_M.module = module

ffi  = require'ffi'
zone = require'jit.zone'
glue = require'glue'
pp   = require'pp'

glue.autoload(_M, {
	arrview    = 'terra/arrayview',
	arr        = 'terra/dynarray',
	map        = 'terra/hashmap',
	set        = 'terra/hashmap',
	random     = 'terra/random',
	randomseed = 'terra/random',
})

require = function(mod)
	zone'require'
	zone('require_'..mod)
	local ret = _G.require(mod)
	zone()
	zone()
	return ret
end

--promoting symbols to global ------------------------------------------------

--[[  Lua 5.1 std library use (promoted symbols not listed)

TODO:
	pcall with traceback		glue.pcall

Modules:
	table math io os string debug coroutine package

Used:
	type tostring tonumber
	setmetatable getmetatable rawget rawset rawequal
	next pairs ipairs
	print
	pcall xpcall error assert
	select
	require load loadstring loadfile dofile
	setfenv getfenv
	s:rep s:sub s:upper s:lower
	s:find s:gsub s:gmatch s:match
	s:byte s:char
	io.stdin io.stdout io.stderr
	io.open io.popen io.lines io.tmpfile io.type
	os.execute os.rename os.remove
	os.getenv
	os.difftime os.date os.time
	arg _G
	collectgarbage newproxy
	s:reverse s:dump s:format(=string.format)
	coroutine.status coroutine.running
	debug.getinfo
	package.path package.cpath package.config
	package.loaded package.searchpath package.loaders
	os.exit

Not used:
	table.maxn
	math.modf math.mod math.fmod math.log10 math.exp
	math.sinh math.cosh math.tanh

Never use:
	module gcinfo _VERSION
	math.huge(=1/0) math.pow math.ldexp
	s:len s:gfind os.clock
	table.getn table.foreach table.foreachi
	io.close io.input io.output io.read io.write io.flush
	os.tmpname os.setlocale
	package.loadlib package.preload package.seeall
	debug.*

]]

push   = table.insert
pop    = table.remove
add    = table.insert
insert = table.insert
concat = table.concat
sort   = table.sort
format = string.format
traceback = debug.traceback
yield    = coroutine.yield
resume   = coroutine.resume
cowrap   = coroutine.wrap
cocreate = coroutine.create

--[[  LuaJIT 2.1 std library use (promoted symbols not listed)

Modules:
	bit jit ffi

Used:
	ffi.new
	ffi.string ffi.sizeof ffi.istype ffi.typeof ffi.offsetof
	ffi.copy ffi.fill
	ffi.load ffi.cdef
	ffi.metatype ffi.gc
	ffi.errno
	ffi.C
	jit.off

Not used:
	bit.rol bit.ror bit.bswap bit.arshif bit.tobit bit.tohex
	ffi.alignof
	jit.flush

Never use:
	ffi.os ffi.abi ffi.arch
	jit.os jit.arch jit.version jit.version_num jit.on jit.status
	jit.attach jit.util jit.opt

]]

cast = ffi.cast

bnot = bit.bnot
shl  = bit.lshift
shr  = bit.rshift
band = bit.band
bor  = bit.bor
xor  = bit.bxor

Windows = false
Linux = false
OSX = false
BSD = false
POSIX = false
_M[ffi.os] = true

--[[  glue use (promoted symbols not listed)

Modules:
	glue.string

Used:
	glue.map
	glue.keys
	glue.shift
	glue.addr glue.ptr
	glue.bin
	glue.collect
	glue.esc
	glue.floor glue.ceil
	glue.pcall glue.fcall glue.fpcall glue.protect
	glue.gsplit
	glue.inherit glue.object
	glue.malloc glue.free
	glue.printer
	glue.replacefile
	glue.fromhex glue.tohex
	glue.freelist glue.growbuffer

Not used:
	glue.readpipe
	glue.reverse
	glue.cpath glue.luapath

]]

memoize = glue.memoize --same as terralib.memoize

update      = glue.update
merge       = glue.merge
attr        = glue.attr
count       = glue.count
index       = glue.index
sortedpairs = glue.sortedpairs

indexof = glue.indexof
append  = glue.append
extend  = glue.extend

autoload  = glue.autoload

canopen   = glue.canopen
writefile = glue.writefile

pack   = glue.pack
unpack = glue.unpack

string.starts = glue.starts
string.trim   = glue.trim
string.lines  = glue.lines

--[[  Terra 1.0.0 std library use (promoted symbols not listed)

Used:
	terra macro quote escape struct var global constant tuple arrayof
	(u)int8|16|32|64 int long float double bool niltype opaque rawstring ptrdiff
	sizeof unpacktuple unpackstruct
	import

Not used:
	unit(=:isunit, ={})

Type checks:
	terralib.isfunction
	terralib.isoverloadedfunction
	terralib.isintegral
	terralib.types.istype
	terralib.islabel
	terralib.isquote
	terralib.issymbol
	terralib.isconstant
	terralib.isglobalvar
	terralib.ismacro
	terralib.isfunction
	terralib.islist
	terralib.israwlist
	<numeric_type>.signed
	<numeric_type>:min()
	<numeric_type>:max()
	<pointer_type>.type

FFI objects:
	terralib.new
	terralib.cast
	terralib.typeof

Used rarely:
	terralib.load terralib.loadstring terralib.loadfile
	terralib.includec
	terralib.saveobj
	package.terrapath terralib.includepath

Not used yet:
	terralib.linkllvm terralib.linkllvmstring
	terralib.newlist
	terralib.version
	terralib.intrinsic
	terralib.select
	terralib.newtarget terralib.istarget
	terralib.terrahome
	terralib.systemincludes

Debugging:
	terralib.traceback
	terralib.backtrace
	terralib.disas
	terralib.lookupsymbol
	terralib.lookupline

Undocumented:
	terralib.dumpmodule
	terralib.types
	terralib.types.funcpointer
	terralib.asm
	operator
	terralib.pointertolightuserdata
	terralib.registerinternalizedfiles
	terralib.bindtoluaapi
	terralib.internalmacro
	terralib.kinds
	terralib.definequote terralib.newquote
	terralib.anonfunction
	terralib.attrstore
	terralib.irtypes
	terralib.registercfile
	terralib.compilationunitaddvalue
	terralib.systemincludes
	terralib.jit
	terralib.anonstruct
	terralib.disassemble
	terralib.environment
	terralib.makeenv
	terralib.newenvironment
	terralib.getvclinker
	terralib.istree
	terralib.attrload
	terralib.defineobjects
	terralib.newanchor
	terralib.jitcompilationunit
	terralib.target terralib.freetarget terralib.nativetarget terralib.inittarget
	terralib.newcompilationunit terralib.initcompilationunit terralib.freecompilationunit
	terralib.llvmsizeof

]]

type = terralib.type

char = int8
enum = int8
num = double --Lua-compat type
codepoint = uint32
size_t = uint64

offsetof = terralib.offsetof

pr = terralib.printraw
linklibrary = terralib.linklibrary
overload = terralib.overloadedfunction
newstruct = terralib.types.newstruct

includecstring = function(...)
	zone'includecstring'
	local C = terralib.includecstring(...)
	zone()
	return C
end

--terralib extensions

--make sizeof work with values too
local terra_sizeof = sizeof
sizeof = macro(function(t)
	local T = t:istype() and t:astype() or t:gettype()
	return `terra_sizeof(T)
end, terra_sizeof)

function terralib.irtypes.Type.istuple(T)
	return type(T) == 'terratype' and T.convertible == 'tuple'
end

terralib.irtypes['quote'].istype = function(self)
	return self.tree:is'luaobject' and terralib.irtypes.Type:isclassof(self.tree.value)
end

terralib.irtypes['quote'].isliteral = function(self)
	return self.tree:is'literal'
end

terralib.irtypes['quote'].getpointertype = function(self)
	local T = self:gettype()
	return assert(T:ispointer() and T.type, 'pointer expected, got ', T)
end

function offsetafter(T, field)
	return offsetof(T, field) + sizeof(T:getfield(field).type)
end

--ternary operator -----------------------------------------------------------

--NOTE: terralib.select() can also be used but it's not short-circuiting.
iif = macro(function(cond, t, f)
	return quote var v: t:gettype(); if cond then v = t else v = f end in v end
end)

--getmethod that works on primitive types and pointers too -------------------

function getmethod(t, name)
	local T = type(t) == 'terratype' and t or t:istype() and t:astype() or t:gettype()
	if T:ispointer() then T = T.type end
	return T.getmethod and T:getmethod(name) or nil
end

--struct packing constructor -------------------------------------------------

local function entry_size(e)
	if e.type then
		return sizeof(e.type)
	else --union
		local size = 0
		for _,e in ipairs(e) do
			size = max(size, entry_size(e))
		end
		return size
	end
end
local function byfield(e, name) return e.field == name end
function packstruct(T, first_field, last_field)
	local i1 = first_field and indexof(first_field, T.entries, byfield)
	local i2 = last_field  and indexof(last_field, T.entries, byfield)
	assert(not i1 == not i2)
	local entries = T.entries
	if i1 then
		assert(i2 > i1) --sort a single field?
		entries = {}
		local inside
		for i,e in ipairs(T.entries) do
			if i == i1 then inside = true end
			if inside then add(entries, e) end
			if i == i2 then break end
		end
	end
	sort(entries, function(e1, e2)
		return entry_size(e1) > entry_size(e2)
	end)
	if i1 then
		print(#entries, i1, i2, i2-i1, first_field, last_field)
		assert(#entries == i2-i1+1)
		for i = i1, i2 do
			T.entries[i] = entries[i-i1+1]
		end
	end
end

--extensible struct metamethods ----------------------------------------------

local function override(mm, T, f, ismacro)
	local f0 = T.metamethods[mm]
	local f0 = f0 and ismacro and f0.fromterra or f0 or noop
	--TODO: see why errors are lost in recursive calls to __getmethod
	--and remove this whole hack with pcall and pass.
	local function pass(ok, ...)
		if not ok then
			print(...)
			os.exit(-1)
		end
		return ...
	end
	local f = function(...)
		return pass(pcall(f, f0, ...))
	end
	if ismacro then f = macro(f) end
	T.metamethods[mm] = f
	return T
end

local function before(mm, T, f, ...)
	local f = function(inherited, ...)
		return f(...) or inherited(...)
	end
	return override(mm, T, f, ...)
end
local function after(mm, T, f, ...)
	local f = function(inherited, ...)
		return inherited(...) or f(...)
	end
	return override(mm, T, f, ...)
end

function override_entrymissing    (T, f) return override('__entrymissing', T, f, true) end
function override_methodmissing   (T, f) return override('__methodmissing', T, f, true) end
function override_setentry        (T, f) return override('__setentry', T, f, true) end
function override_getentries      (T, f) return override('__getentries', T, f) end
function override_getmethod       (T, f) return override('__getmethod', T, memoize(f)) end

function before_entrymissing  (T, f) return before('__entrymissing', T, f, true) end
function before_methodmissing (T, f) return before('__methodmissing', T, f, true) end
function before_setentry      (T, f) return before('__setentry', T, f, true) end
function before_getentries    (T, f) return before('__getentries', T, f) end
function before_getmethod     (T, f) return before('__getmethod', T, memoize(f)) end

function after_entrymissing   (T, f) return after('__entrymissing', T, f, true) end
function after_methodmissing  (T, f) return after('__methodmissing', T, f, true) end
function after_setentry       (T, f) return after('__setentry', T, f, true) end
function after_getentries     (T, f) return after('__getentries', T, f) end
function after_getmethod      (T, f) return after('__getmethod', T, memoize(f)) end

--activate macro-based assignable properties in structs.
function addproperties(T, props)
	props = props or {}
	T.properties = props
	return after_entrymissing(T, function(k, self)
		local prop = props[k]
		if type(prop) == 'terramacro' or type(prop) == 'terrafunction' then
			return `prop(self)
		else
			return prop --quote or Lua constant value
		end
	end)
end

--forward t.name to t.sub.name (for anonymous structs and such).
function forwardproperties(sub)
	return function(T)
		return after_entrymissing(T, function(k, self)
			return `self.[sub].[k]
		end)
	end
end

--activate getters and setters in structs.
function gettersandsetters(T)
	if T.gettersandsetters then return end
	T.gettersandsetters = true
	after_entrymissing(T, function(name, obj)
		if T.addmethods then T.addmethods() end
		if T.methods['get_'..name] then
			return `obj:['get_'..name]()
		end
	end)
	after_setentry(T, function(name, obj, rhs)
		if T.addmethods then T.addmethods() end
		if T.methods['set_'..name] then
			return quote obj:['set_'..name](rhs) end
		end
	end)
	return T
end

--lazy method publishing pattern for containers
--workaround for terra issue #348.
--NOTE: __methodmissing is no longer called if __getmethod is present!
function addmethods(T, addmethods_func)
	T.addmethods = function(self, name)
		T.addmethods = nil
		addmethods_func()
	end
	return after_getmethod(T, function(self, name)
		if T.addmethods then T.addmethods() end
		return self.methods[name]
	end)
end

--wrapping opaque structs declared in C headers
--workaround for terra issue #351.
function wrapopaque(T)
	return override_getentries(T, function() return {} end)
end

--make all methods inline, except some (useful for containers).
--A syntax for method annotations would remove the need for this hack.
function setinlined(methods, include)
	include = include or pass
	for name,m in pairs(methods) do
		if m.setinlined and include(name, 1, m) then
			m:setinlined(true)
		elseif m.definitions then
			for i,m in ipairs(m.definitions) do
				if include(name, i, m) then
					m:setinlined(true)
				end
			end
		end
	end
end

--easier way to define common casts.
function newcast(T, fromT, ret)
	local oldcast = T.metamethods.__cast
	function T.metamethods.__cast(from, to, exp)
		if to == T and from == fromT then
			if type(ret) == 'function' then
				return ret(exp)
			else
				return ret
			end
		end
		if oldcast then
			return oldcast(from, to, exp)
		end
		assert(false, 'invalid cast from ', from, ' to ', to, ': ', exp)
	end
end

--pack all or some bool-type fields into a single bitmask field.
function packboolfields(T, fields, BITS)
	local bool_fields = glue.map(fields or T.entries, function(e)
		return e.type == bool and e or nil
	end)
	if #bool_fields == 0 then return end
	local BITS = BITS or '_flags'
	local i = indexof(T, function(e) return e.field == BITS end)
	local BITS_field = T.entries[i]
	if not BITS_field then
		local bmtype =
			   #bool_fields > 32 and uint64
			or #bool_fields > 16 and uint32
			or #bool_fields >  8 and uint16
			or uint8
		BITS_field = {field = BITS, type = bmtype}
		add(T.entries, BITS_field)
	end
	local BITS_T = BITS_field.type
	assert(sizeof(BITS_T) >= 2^#bool_fields)
	gettersandsetters(T)
	for i,e in ipairs(bool_fields) do
		i = i - 1
		T.methods['get_'..e.field] = macro(function(self)
			return `getbit(self.[BITS], i)
		end)
		T.methods['set_'..e.field] = macro(function(self, b)
			return quote setbit(self.[BITS], i, b) end
		end)
	end
end

--compile-time speed probing -------------------------------------------------

local t0 = terralib.currenttimeinseconds()
local function probe_lua(...)
	local t = terralib.currenttimeinseconds()
	print(format('%.2fs', t - t0), ...)
	t0 = t
end

--C include system -----------------------------------------------------------

function includepath(path)
	terralib.includepath = terralib.includepath .. ';' .. path
end

--overriding this built-in so that modules can depend on it being memoized.
terralib.includec = memoize(terralib.includec)

--terralib.includec variant that dumps symbols into C.
function include(header,...)
	zone'include'
	zone('include_'..header)
	update(C, terralib.includec(header,...))
	zone()
	zone()
	return C
end

function extern(name, T)
	local func = terralib.externfunction(name, T)
	C[name] = func
	return func
end

function C:__call(cstring, ...)
	return update(self, terralib.includecstring(cstring, ...))
end

--forward ffi.cdef() calls to includecstring() so that Terra can use ffi
--cdefs from LuaJIT C bindings instead of loading original header files
--which can load up to 10x slower.
builtin_ctypes = [[
typedef          char      int8_t;
typedef unsigned char      uint8_t;
typedef          short     int16_t;
typedef unsigned short     uint16_t;
typedef          int       int32_t;
typedef unsigned int       uint32_t;
typedef          long long int64_t;
typedef unsigned long long uint64_t;

typedef uint64_t size_t;
typedef int64_t  ptrdiff_t;
typedef uint16_t wchar_t;

// MSVC types
typedef int8_t  __int8;
typedef int16_t __int16;
typedef int32_t __int32;
typedef int64_t __int64;
]]
local load_cdefs = memoize(function(m)
	local cdef = ffi.cdef
	local t = {}
	ffi.cdef = function(s) add(t, s) end
	require(m)
	ffi.cdef = cdef
	return t
end)
function require_h(...)
	local t = {}
	for i=1,select('#',...) do
		local m = select(i,...)
		if type(m) == 'table' then
			extend(t, m)
		else
			extend(t, load_cdefs(m))
		end
	end
	local s = concat(t)
	C(builtin_ctypes..s, {'-Wno-missing-declarations'})
	--ffi.cdef(s)
	--^^enums are anonymized in some headers because they are boxed in
	--LuaJIT, but Clang complains about that hence -Wno-missing-declarations.
end

--stdlib dependencies --------------------------------------------------------

--loading these takes 0.1s on Windows.
include'stdio.h'
include'stdlib.h'
include'string.h'
include'math.h'

--math module ----------------------------------------------------------------

--Lua compat
PI     = math.pi
min    = macro(function(a, b) return `iif(a < b, a, b) end, math.min)
max    = macro(function(a, b) return `iif(a > b, a, b) end, math.max)
abs    = macro(function(x) return `iif(x < 0, -x, x) end, math.abs)
sqrt   = macro(function(x) return `C.sqrt(x) end, math.sqrt)
pow    = C.pow --beacause ^ means xor in terra
log    = macro(function(x) return `C.log(x) end, math.log)
sin    = macro(function(x) return `C.sin(x) end, math.sin)
cos    = macro(function(x) return `C.cos(x) end, math.cos)
tan    = macro(function(x) return `C.tan(x) end, math.tan)
asin   = macro(function(x) return `C.asin(x) end, math.sin)
acos   = macro(function(x) return `C.acos(x) end, math.sin)
atan   = macro(function(x) return `C.atan(x) end, math.sin)
atan2  = macro(function(y, x) return `C.atan2(y, x) end, math.sin)
deg    = macro(function(r) return `r * (180.0 / PI) end, math.deg)
rad    = macro(function(d) return `d * (PI / 180.0) end, math.rad)

--go full Pascal :)
inc    = macro(function(x, i) i=i or 1; return quote x = x + i in x end end)
dec    = macro(function(x, i) i=i or 1; return quote x = x - i in x end end)
swap   = macro(function(a, b) return quote var c = a; a = b; b = c end end)
isodd  = macro(function(x) return `x % 2 == 1 end)
iseven = macro(function(x) return `x % 2 == 0 end)
isnan  = macro(function(x) return `x ~= x end)
inf    = 1/0
nan    = 0/0
maxint = int:max()
minint = int:min()

--find the smallest n for which x <= 2^n.
nextpow2 = macro(function(x)
	local T = x:gettype()
	if T:isintegral() then
		local bytes = sizeof(T)
		return quote
			var x = x
			x = x - 1
			x = x or (x >>  1)
			x = x or (x >>  2)
			x = x or (x >>  4)
			if bytes >= 2 then x = x or (x >>  8) end
			if bytes >= 4 then x = x or (x >> 16) end
			if bytes >= 8 then x = x or (x >> 32) end
			x = x + 1
			in x
		end
	end
	error('unsupported type ', x:gettype())
end, glue.nextpow2)

--get the value of x's i'th bit as a bool.
getbit = macro(function(x, i)
	return `(x and (1 << i)) ~= 0
end)

--set the value of x's i'th bit with a bool.
setbit = macro(function(x, i, b)
	local T = x:gettype()
	return quote x = x ^ (((-[T](b)) ^ x) and (1 << i)) end
end)

--set multiple bits from src into dest based on mask.
setbits = macro(function(dst, src, mask)
	return quote dst = (dst and (not mask)) or (src and mask) end
end)

--integer division variants

div_up = macro(function(x, p)
	if x:gettype():isintegral() and p:gettype():isintegral() then
		return `x / p + iif(x % p ~= 0, [int]((x > 0) == (p > 0)), 0)
	end
	return `C.ceil(x / p)
end)

div_down = macro(function(x, p)
	if x:gettype():isfloat() or p:gettype():isfloat() then
		return `C.floor(x / p) * p
	else
		return `(x / p) * p
	end
end)

div_nearest = macro(function(x, p)
	if x:gettype():isintegral() and p:gettype():isintegral() then
		return `(2*x - p + 2*([int]((x < 0) ~= (p > 0))*p)) / (2*p)
	end
	return `C.floor(x / p + .5)
end)

--math from glue

round = macro(function(x, p)
	p = p or 1
	return `div_nearest(x, p) * p
end, glue.round)
snap = round

floor = macro(function(x, p)
	p = p or 1
	return `div_down(x, p) * p
end, glue.floor)

ceil = macro(function(x, p)
	p = p or 1
	return `div_up(x, p) * p
end, glue.ceil)

clamp = macro(function(x, m, M)
	return `min(max(x, m), M)
end, glue.clamp)

lerp = macro(function(x, x0, x1, y0, y1)
	return `[double](y0) + ([double](x)-[double](x0))
		* (([double](y1)-[double](y0)) / ([double](x1) - [double](x0)))
end, glue.lerp)

--binary search for an insert position that keeps the array sorted.
local less = macro(function(t, i, v) return `t[i] <  v end)
binsearch = macro(function(v, t, lo, hi, cmp)
	cmp = cmp or less
	return quote
		var lo = [lo]
		var hi = [hi]
		var i = hi + 1
		while true do
			if lo < hi then
				var mid: int = lo + (hi - lo) / 2
				if cmp(t, mid, v) then
					lo = mid + 1
				else
					hi = mid
				end
			else
				if lo == hi and not cmp(t, lo, v) then
					i = lo
				end
				break
			end
		end
	in i
	end
end, glue.binsearch)

--other from glue...
pass = macro(glue.pass, glue.pass)
noop = macro(function() return quote end end, glue.noop)

--stdin/out/err --------------------------------------------------------------

if Windows then
	stdin  = terra() return C.__iob_func()+0 end
	stdout = terra() return C.__iob_func()+1 end
	stderr = terra() return C.__iob_func()+2 end
else
	C[[
	#include <stdio.h>
	FILE* stdin  (void) { return stdin;  }
	FILE* stdout (void) { return stdout; }
	FILE* stderr (void) { return stderr; }
	]]
end

--tostring -------------------------------------------------------------------

local function format_arg(arg, fmt, args, freelist, indent)
	local t = arg:gettype()
		 if t == &int8    then add(fmt, '%s'   ); add(args, arg)
	elseif t == int8     then add(fmt, '%d'   ); add(args, arg)
	elseif t == uint8    then add(fmt, '%u'   ); add(args, arg)
	elseif t == int16    then add(fmt, '%d'   ); add(args, arg)
	elseif t == uint16   then add(fmt, '%u'   ); add(args, arg)
	elseif t == int32    then add(fmt, '%d'   ); add(args, arg)
	elseif t == uint32   then add(fmt, '%u'   ); add(args, arg)
	elseif t == int64    then add(fmt, '%lldL'); add(args, arg)
	elseif t == uint64   then add(fmt, '%lluU'); add(args, arg)
	elseif t == double   then add(fmt, '%.14g'); add(args, arg)
	elseif t == float    then add(fmt, '%.14g'); add(args, arg)
	elseif t == bool     then add(fmt, '%s'   ); add(args, `iif(arg, 'true', 'false'))
	elseif t:isarray() then
		add(fmt, '[')
		for i=0,t.N-1 do
			format_arg(`arg[i], fmt, args, freelist, indent+1)
			if i < t.N-1 then add(fmt, ',') end
		end
		add(fmt, ']')
	elseif t:isstruct() then
		local __tostring = t.metamethods.__tostring
		if __tostring then
			__tostring(arg, format_arg, fmt, args, freelist, indent)
		else
			add(fmt, tostring(t)..' {')
			local layout = t:getlayout()
			for i,e in ipairs(layout.entries) do
				add(fmt, '\n')
				add(fmt, ('   '):rep(indent+1))
				add(fmt, e.key..' = ')
				format_arg(`arg.[e.key], fmt, args, freelist, indent+1)
			end
			add(fmt, '\n')
			add(fmt, ('   '):rep(indent))
			add(fmt, '}')
		end
	elseif t:isfunction() then
		add(fmt, tostring(t)..'<%llx>'); add(args, arg)
	elseif t:ispointer() then
		add(fmt, tostring(t):gsub(' ', '')..'<%llx>'); add(args, arg)
	end
end

tostring = macro(function(arg, outbuf, maxlen)
	local fmt, args, freelist = {}, {}, {}
	format_arg(arg, fmt, args, freelist, 0)
	fmt = concat(fmt)
	local snprintf = Windows and _snprintf or snprintf
	if outbuf then
		return quote
			snprintf(outbuf, maxlen, fmt, [args])
			[ freelist ]
		end
	else
		return quote
			var out = arr(char)
			if out:setcapacity(32) then
				var n = snprintf(out.elements, out.capacity, fmt, [args])
				if n < 0 then
					out:free()
				elseif n < out.capacity then
					out.len = n+1
				else
					if not out:setcapacity(n+1) then
						out:free()
					else
						assert(snprintf(out.elements, out.capacity, fmt, [args]) == n)
						out.len = n+1
					end
				end
			end
			[ freelist ]
			in out
		end
	end
end, tostring)

--flushed printf -------------------------------------------------------------

pfn = macro(function(...)
	local args = {...}
	return quote
		var stdout = stdout()
		fprintf(stdout, [args])
		fprintf(stdout, '\n')
		fflush(stdout)
	end
end, function(...)
	print(string.format(...))
	io.stdout:flush()
end)

pf = macro(function(...)
	local args = {...}
	return quote
		var stdout = stdout()
		fprintf(stdout, [args])
		fflush(stdout)
	end
end, function(...)
	io.stdout:write(string.format(...))
	io.stdout:flush()
end)

--Lua-style print ------------------------------------------------------------

print = macro(function(...)
	local fmt, args, freelist = {}, {}, {}
	local n = select('#', ...)
	for i=1,n do
		local arg = select(i, ...)
		format_arg(arg, fmt, args, freelist, 0)
		add(fmt, i < n and '\t' or nil)
	end
	fmt = concat(fmt)
	return quote
		var stdout = stdout()
		fprintf(stdout, fmt, [args])
		fprintf(stdout, '\n')
		fflush(stdout)
		[ freelist ]
	end
end, function(...)
	_G.print(...)
	io.stdout:flush()
end)

--assert ---------------------------------------------------------------------

assert = macro(function(expr, msg)
	if NOASSERTS then return `expr end
	return quote
		if not expr then
			var stderr = stderr()
			fprintf(stderr, [
				'assertion failed '
				.. (msg and '('..msg:asvalue()..') ' or '')
				.. tostring(expr.filename)
				.. ':' .. tostring(expr.linenumber)
				.. ': ' .. tostring(expr) .. '\n'
			])
			fflush(stderr)
			abort()
		end
	end
end, function(v, ...)
	if v then return v end
	if not ... then error('assertion failed', 2) end
	local t=pack(...); for i=1,t.n do t[i]=tostring(t[i]) end
	error(concat(t), 2)
end)

assertf = glue.assert

--clock ----------------------------------------------------------------------
--monotonic clock (can't go back or drift) in seconds with ~1us precision.

local tclock
if Windows then
	extern('QueryPerformanceFrequency', {&int64} -> int32)
	extern('QueryPerformanceCounter',   {&int64} -> int32)
	linklibrary'kernel32'
	local inv_qpf = global(double, 0)
	local terra init()
		var t: int64
		assert(QueryPerformanceFrequency(&t) ~= 0)
		inv_qpf = 1.0 / t --precision loss in e-10
	end
	tclock = terra(): double
		if inv_qpf == 0 then init() end
		var t: int64
		assert(QueryPerformanceCounter(&t) ~= 0)
		return t * inv_qpf
	end
elseif Linux then
	--TODO: finish and test this
	include'time.h'
	linklibrary'rt'
	tclock = terra(): double
		var t: timespec
		assert(clock_gettime(CLOCK_MONOTONIC, &tp) == 0)
		return t.tv_sec + t.tv_nsec / 1.0e9
	end
elseif OSX then
	--TODO: finish and test this
	tclock = terra(): double
		return [double](mach_absolute_time())
	end
end
clock = macro(function() return `tclock() end, terralib.currenttimeinseconds)

local t0 = global(double, 0.0)
local function probe_terra(...)
	local args = {...}
	return quote
		var t = clock()
		if t0 == 0 then t0 = t end
		pf('%.2fs\t', t - t0)
		print(args)
		t0 = t
	end
end
probe = macro(probe_terra, probe_lua)

--call a method on each element of an array ----------------------------------

local empty = {}
local function args(...) return select('#',...) > 0 and {...} or empty end

local function cancall_lua(T, method)
	return getmethod(T, method) and true or false
end
cancall = macro(function(t, method)
	method = method:asvalue()
	local T = type(t) == 'terratype' and t or t:istype() and t:astype() or t:gettype()
	return cancall_lua(T, method)
end, cancall_lua)

call = macro(function(t, method, len, ...)
	len = len and len:isliteral() and len:asvalue() or len or 1
	method = method:asvalue()
	if cancall(t, method) then
		local args = args(...)
		if len == 1 then
			return quote t:[method]([args]) in t end
		else
			return quote
				for i=0,len do
					(t+i):[method]([args])
				end
				in t
			end
		end
	else
		return quote end
	end
end)

--typed malloc ---------------------------------------------------------------

local C_realloc = C.realloc
local C_free = C.free

--prevent use of these variants so we can have a single entry point for
--dynamic allocations which is alloc().
C.realloc = nil
C.free = nil
C.malloc = nil
C.calloc = nil

alloc = macro(function(T, len, oldp, label)
	oldp = oldp or `nil
	len = len or 1
	label = label or ''
	T = T:astype()
	local sz = (T == opaque) and 1 or sizeof(T)
	return quote
		var p: &T
		if len > 0 then
			p = [&T](C_realloc(oldp, len * sz))
		else
			assert(len >= 0)
			C_free(oldp)
			p = nil
		end
		in p
	end
end)

realloc = macro(function(p, len, label) --works as free() when len = 0
	label = label or ''
	local T = p:getpointertype()
	return `alloc(T, len, p, label)
end)

--Note the necessity to pass a `len` if freeing an array of objects that have
--a free() method otherwise only the first element of the array will be freed!
free = macro(function(p, len, nilvalue)
	nilvalue = nilvalue or `nil
	len = len or 1
	return quote
		if p ~= nil then
			call(p, 'free', len)
			realloc(p, 0)
			p = nilvalue
		end
	end
end)

new = macro(function(T, ...)
	local args = args(...)
	return quote
		var obj = alloc(T)
		obj:init([args])
		in obj
	end
end)

--typed memset ---------------------------------------------------------------

local C_memset = C.memset; C.memset = nil

fill = macro(function(p, val, len)
	if len == nil then --fill(p, len)
		val, len = nil, val
	end
	val = val or 0
	len = len or 1
	local T = p:getpointertype()
	return quote
		assert(len >= 0)
		C_memset(p, val, sizeof(T) * len)
		in p
	end
end)

--typed memmove --------------------------------------------------------------

local C_memmove = C.memmove; C.memmove = nil

bitcopy = macro(function(dst, src, len)
	len = len or 1
	local T1 = dst:getpointertype()
	local T2 = src:getpointertype()
	assert(sizeof(T1) == sizeof(T2), 'memcopy() sizeof mismatch ', T1, ' vs ', T2)
	local T = T1
	return quote C_memmove(dst, src, len * sizeof(T)) in dst end
end)

copy = macro(function(dst, src, len)
	--TODO: check if T1 can be cast to T2 or viceversa and use that instead!
	return `bitcopy(dst, src, len)
end)

--typed memcmp ---------------------------------------------------------------

local C_memcmp = C.memcmp; C.memcmp = nil

bitequal = macro(function(p1, p2, len)
	len = len or 1
	local T1 = p1:getpointertype()
	local T2 = p2:getpointertype()
	assert(sizeof(T1) == sizeof(T2), 'bitequal() sizeof mismatch ', T1, ' vs ', T2)
	local T = T1
	return `C_memcmp(p1, p2, len * sizeof(T)) == 0
end)

local op_eq = macro(function(a, b) return `@a == @b end)
local mt_eq = macro(function(a, b) return `a:__eq(b) end)

equal = macro(function(p1, p2, len)
	len = len or 1
	local T1 = p1:getpointertype()
	local T2 = p2:getpointertype()
	--TODO: check if T1 can be cast to T2 or viceversa first!
	assert(T1 == T2, 'equal() type mismatch ', T1, ' vs ', T2, traceback())
	local T = T1
	--check if elements must be compared via `==` operator.
	--floats can't be memcmp'ed since they may not be normalized.
	local must_op = T.metamethods and T.metamethods.__eq and op_eq
	local must_mt = not T:ispointer() and getmethod(T, '__eq') and mt_eq
	local eq = must_op or must_mt or (T:isfloat() and op_eq)
	if eq then
		if len == 1 then
			return `eq(p1, p2)
		else
			return quote
				var equal = false
				for i=0,len do
					if eq(p1, p2) then
						equal = true
						break
					end
				end
				in equal
			end
		end
	else --fallback to memcmp
		return `bitequal(p1, p2, len)
	end
end)

--default hash function ------------------------------------------------------

bithash = macro(function(size_t, k, h, len) --FNV-1A hash
	local size_t = size_t:astype()
	local T = k:getpointertype()
	local len = len or 1
	h = h and h ~= 0 and h or 0x811C9DC5
	return quote
		var d = [size_t](h)
		var k = [&int8](k)
		for i = 0, len * sizeof(T) do
			d = (d ^ k[i]) * 16777619
		end
		in d
	end
end)

hash = macro(function(size_t, k, h, len)
	len = len or 1
	h = h or 0
	local size_t = size_t:astype()
	local T = k:getpointertype()
	if T.getmethod then
		local method = '__hash'..(sizeof(size_t) * 8)
		if T:getmethod(method) then
			if len == 1 then
				return `k:[method]([size_t](h))
			else
				return quote
					var h = [size_t](h)
					for i=0,len do
						h = k:[method](h)
					end
					in h
				end
			end
		end
	end
	return `bithash(size_t, k, h, len)
end)

--sizeof of dynamically allocated memory -------------------------------------

memsize = macro(function(t)
	if t:istype() then return `sizeof(t) end
	local T = t:gettype()
	if getmethod(T, '__memsize') then
		return `t:__memsize()
	else
		return 0
	end
end)

--readfile -------------------------------------------------------------------

local terra treadfile(name: rawstring): {&opaque, int64}
	var f = fopen(name, 'rb')
	defer fclose(f)
	if f ~= nil then
		if fseek(f, 0, SEEK_END) == 0 then
			var filesize = ftell(f)
			if filesize > 0 then
				rewind(f)
				var out = [&opaque](alloc(uint8, filesize))
				if out ~= nil and fread(out, 1, filesize, f) == filesize then
					return out, filesize
				end
				realloc(out, 0)
			end
		end
	end
	return nil, 0
end
readfile = macro(function(name) return `treadfile(name) end, glue.readfile)

--freelist -------------------------------------------------------------------

freelist = memoize(function(T)
	local struct freelist {
		next: &freelist;
	}
	addmethods(freelist, function()
		assert(sizeof(T) >= sizeof(&opaque), 'freelist item too small')
		terra freelist:init()
			self.next = nil
		end
		terra freelist:free()
			while self.next ~= nil do
				var next = self.next.next
				realloc(self.next, 0)
				self.next = next
			end
		end
		terra freelist:alloc()
			if self.next ~= nil then
				var p = self.next
				self.next = p.next
				return [&T](p)
			else
				return alloc(T)
			end
		end
		terra freelist:release(p: &T)
			var node = [&freelist](p)
			node.next = self.next
			self.next = node
		end
	end)
	return freelist
end)

--building to dll for LuaJIT ffi consumption ---------------------------------

--Features:
-- * supports publishing terra functions and named terra structs with methods.
-- * tuples and function pointers are typedef'ed with friendly unique names.
-- * the same tuple definition can appear in multiple modules without error.
-- * auto-assign methods to types via ffi.metatype.
-- * enable getters and setters via ffi.metatype.
-- * type name override with `__typename_ffi` metamethod.
-- * deciding which methods to publish via `public_methods` table.
-- * publishing enum and bitmask values.
-- * diff-friendly deterministic output.

function publish(modulename)

	local self = {}
	setmetatable(self, self)

	local objects = {}
	local enums = {}

	function self:__call(T, public_methods, opaque)
		if type(T) == 'terrafunction'
			or (type(T) == 'terratype' and T:isstruct() and not T:istuple())
		then
			T.opaque = opaque
			if type(T) == 'terrafunction' or type(T) == 'overloadedterrafunction' then
				T.ffi_name = public_methods
			else
				T.public_methods = public_methods or T.methods
				if public_methods then
					for method in pairs(public_methods) do
						if not getmethod(T, method) then
							print('Warning: method missing for publishing '..tostring(T)..':'..method..'()')
						end
					end
				end
			end
			add(objects, T)
		elseif type(T) == 'table' and not getmetatable(T) then --plain table: enums
			update(enums, T)
		else
			assert(false, 'expected terra function, struct or enum table, got ', T)
		end
		return T
	end

	function self:getenums(moduletable, match)
		for k,v in pairs(moduletable) do
			if type(k) == 'string' and type(v) == 'number' and k:upper() == k
				and (not match or k:find(match))
			then
				enums[k] = v
			end
		end
	end

	local saveobj_table = {}

	function self:bindingcode()
		local tdefs = {} --typedefs
		local pdefs = {} --function pointer typedefs
		local xdefs = {} --shared struct defs (pcalled)
		local cdefs = {} --function defs
		local mdefs = {} --metatype defs

		add(tdefs, "local ffi = require'ffi'\n")
		add(tdefs, "local C = ffi.load'"..modulename.."'\n")
		add(tdefs, 'ffi.cdef[[\n')

		local ctype --fw. decl.

		local function cdef_tuple(T, name)
			add(xdefs, 'pcall(ffi.cdef, \'')
			append(xdefs, 'struct ', name, ' { ')
			for i,e in ipairs(T.entries) do
				local name, type = e[1], e[2]
				append(xdefs, ctype(type), ' ', name, '; ')
			end
			add(xdefs, '};\')\n')
		end

		local function typedef_struct(name)
			append(tdefs, 'typedef struct ', name, ' ', name, ';\n')
		end

		local function typedef_functionpointer(T, name)
			append(pdefs, 'typedef ', ctype(T.returntype), ' (*', name, ') (')
			for i,arg in ipairs(T.parameters) do
				add(pdefs, ctype(arg))
				if i < #T.parameters then
					add(pdefs, ', ')
				end
				if T.isvararg then
					add(pdefs, ',...')
				end
			end
			add(pdefs, ');\n')
		end

		local function append_typename_fragment(s, T, n)
			if not T then return s end
			local ct = T:isintegral() and tostring(T):gsub('32$', '')
				or T:ispointer() and 'p' .. ctype(T.type)
				or ctype(T)
			return s .. (s ~= '' and  '_' or '') .. ct .. (n > 1 and n or '')
		end
		local function unique_typename(types)
			local type0, n = nil, 0
			local s = ''
			for i,type in ipairs(types) do
				if type ~= type0 then
					s = append_typename_fragment(s, type0, n)
					type0, n = type, 1
				else
					n = n + 1
				end
			end
			return append_typename_fragment(s, type0, n)
		end

		local function tuple_typename(T)
			--each tuple entry is the array {name, type}, hence plucking index 2.
			return unique_typename(glue.map(T.entries, 2))
		end

		local function function_typename(T)
			local s = unique_typename(T.parameters)
			s = s .. (s ~= '' and '_' or '') .. 'to'
			return append_typename_fragment(s, T.returntype, 1)
		end

		local function clean_typename(s)
			return (s:gsub('[%${},()]', '_'))
		end

		local function typename(T, name)
			local typename = T.metamethods and T.metamethods.__typename_ffi
			local typename = typename
				and (type(typename) == 'string' and typename or typename(T))
			if T:istuple() then
				typename = typename or clean_typename(tuple_typename(T))
				cdef_tuple(T, typename)
				typedef_struct(typename)
			elseif T:isstruct() then
				typename = typename or clean_typename(tostring(T))
				typedef_struct(typename)
			elseif T:isfunction() then
				typename = typename or clean_typename(name or function_typename(T))
				typedef_functionpointer(T, typename)
			else
				typename = clean_typename(tostring(T))
			end
			return typename
		end
		typename = memoize(typename)

		function ctype(T)
			if T:isintegral() then
				return tostring(T)..'_t'
			elseif T:isfloat() or T:islogical() then
				return tostring(T)
			elseif T == rawstring then
				return 'const char *'
			elseif T:ispointer() then
				if T:ispointertofunction() then
					return typename(T.type, T.__typename_ffi)
				else
					return ctype(T.type)..'*'
				end
			elseif T == terralib.types.opaque or T:isunit() then
				return 'void'
			elseif T:isstruct() then
				return typename(T)
			elseif T:isarray() then --TODO: this is invalid syntax
				return ctype(T.type)..'['..T.N..']'
			else
				assert(false, 'NYI: ', tostring(T))
			end
		end

		local function cdef_function(func, name)
			local T = func:gettype()
			append(cdefs, ctype(T.returntype), ' ', name, '(')
			for i,arg in ipairs(T.parameters) do
				add(cdefs, ctype(arg))
				if i < #T.parameters then
					add(cdefs, ', ')
				end
				if T.isvararg then
					add(cdefs, ',...')
				end
			end
			add(cdefs, ');\n')
			saveobj_table[name] = func
		end

		local function cdef_entries(cdefs, entries, indent)
			for i,e in ipairs(entries) do
				for i=1,indent do add(cdefs, '\t') end
				if #e > 0 and type(e[1]) == 'table' then --union
					add(cdefs, 'union {\n')
					cdef_entries(cdefs, e, indent + 1)
					for i=1,indent do add(cdefs, '\t') end
					add(cdefs, '};\n')
				else
					append(cdefs, ctype(e.type), ' ', e.field, ';\n')
				end
			end
		end
		local function cdef_struct(T)
			name = typename(T)
			if not T.opaque then
				append(cdefs, 'struct ', name, ' {\n')
				cdef_entries(cdefs, T.entries, 1)
				add(cdefs, '};\n')
			end
		end

		local function overloadname(fname, name, i)
			if type(name) == 'table' and name[i] then return name[i] end
			return (type(name) == 'string' and name or fname)..(i ~= 1 and i or '')
		end

		local function publicname(T, fname, i)
			local name = not T.public_methods or T.public_methods[fname]
			return name and overloadname(fname, name, i)
		end

		local function cdef_methods(T)
			local name = typename(T)
			local methods = {}
			local getters = {}
			local setters = {}

			--unpack overloads.
			local m = {}
			for fname, func in pairs(T.methods) do
				if type(func) == 'overloadedterrafunction' then
					for i,func in ipairs(func.definitions) do
						local name = publicname(T, fname, i)
						if name then
							m[name] = func
						end
					end
				elseif type(func) == 'terrafunction' then
					local name = publicname(T, fname)
					if name then
						m[name] = func
					end
				end
			end

			--declare methods in source code order.
			local function cmp(k1, k2)
				local m1 = m[k1]
				local m2 = m[k2]
				local d1 = m1.definition
				local d2 = m2.definition
				assert(d1, 'method '..tostring(T)..':'..k1..' has no body')
				assert(d2, 'method '..tostring(T)..':'..k2..' has no body')
				if d1.filename == d2.filename then
					return d1.linenumber < d2.linenumber
				else
					return d1.filename < d2.filename
				end
			end

			for fname, func in sortedpairs(m, cmp) do
				if fname then
					local cname = name..'_'..fname
					cdef_function(func, cname)
					local t
					if T.gettersandsetters then
						if fname:starts'get_' and #func.type.parameters == 1 then
							t, fname = getters, fname:gsub('^get_', '')
						elseif fname:starts'set_' and #func.type.parameters == 2 then
							t, fname = setters, fname:gsub('^set_', '')
						else
							t = methods
						end
					else
						t = methods
					end
					add(t, '\t'..fname..' = C.'..cname..',\n')
				end
			end
			if T.gettersandsetters and (#getters > 0 or #setters > 0) then
				add(mdefs, 'local getters = {\n'); extend(mdefs, getters); add(mdefs, '}\n')
				add(mdefs, 'local setters = {\n'); extend(mdefs, setters); add(mdefs, '}\n')
				add(mdefs, 'local methods = {\n'); extend(mdefs, methods); add(mdefs, '}\n')
				add(mdefs, [[
ffi.metatype(']]..name..[[', {
	__index = function(self, k)
		local getter = getters[k]
		if getter then return getter(self) end
		return methods[k]
	end,
	__newindex = function(self, k, v)
		local setter = setters[k]
		if not setter then
			error(('field not found: %s'):format(tostring(k)), 2)
		end
		setter(self, v)
	end,
})
]])
			else
				append(mdefs, 'ffi.metatype(\'', name, '\', {__index = {\n')
				extend(mdefs, methods)
				add(mdefs, '}})\n')
			end
		end

		for i,obj in ipairs(objects) do
			if type(obj) == 'terrafunction' then
				cdef_function(obj, obj.ffi_name or obj.name:gsub('%.', '_'))
			elseif type(obj) == 'overloadedterrafunction' then
				local name = obj.ffi_name or obj.name:gsub('%.', '_')
				for i,obj in ipairs(obj.definitions) do
					cdef_function(obj, type(name) == 'table' and name[i] or overloadname(name, i))
				end
			elseif obj:isstruct() then
				cdef_struct(obj)
				cdef_methods(obj)
			end
		end

		add(cdefs, ']]\n')

		local enums_code = ''
		if next(enums) then
			local t = {'ffi.cdef[[\nenum {\n'}
			local function addt(s) add(t, s) end
			for k,v in sortedpairs(enums) do
				add(t, '\t'); add(t, k); add(t, ' = '); pp.write(addt, v); add(t, ',\n')
			end
			enums_code = concat(t) .. '}]]\n'
		end

		return concat(tdefs) .. concat(pdefs) .. concat(cdefs)
			.. concat(xdefs) .. concat(mdefs) .. enums_code
			.. 'return C\n'

	end

	function self:savebinding(filename)
		zone'savebinding'
		local filename = self:luapath(filename or modulename .. '_h.lua')
		writefile(filename, self:bindingcode(), nil, filename..'.tmp')
		zone()
	end

	function self:binpath(filename)
		return terralib.terrahome..(filename and '/'..filename or '')
	end

	function self:luapath(filename)
		return terralib.terrahome..'/../..'..(filename and '/'..filename or '')
	end

	function self:objfile()
		return self:binpath(modulename..'.o')
	end

	function self:sofile()
		local soext = {Windows = 'dll', OSX = 'dylib', Linux = 'so'}
		return self:binpath(modulename..'.'..soext[ffi.os])
	end

	function self:saveobj()
		zone'saveobj'
		terralib.saveobj(self:objfile(), 'object', saveobj_table)
		zone()
	end

	function self:removeobj()
		os.remove(self:objfile())
	end

	function self:linkobj(linkto)
		zone'linkobj'
		local linkargs = linkto and '-l'..concat(linkto, ' -l') or ''
		local cmd = 'gcc '..self:objfile()..' -shared '..'-o '..self:sofile()
			..' -L'..self:binpath()..' '..linkargs
		os.execute(cmd)
		zone()
	end

	--TODO: make this work. Doesn't export symbols on Windows.
	function self:savelibrary(linkto)
		zone'savelibrary'
		local linkargs = linkto and '-l'..concat(linkto, ' -l') or ''
		terralib.saveobj(self:sofile(), 'sharedlibrary', saveobj_table, linkargs)
		zone()
	end

	function self:build(opt)
		opt = opt or {}
		self:savebinding()
		if true then
			self:saveobj()
			self:linkobj(opt.linkto)
			self:removeobj()
		else
			self:savelibrary(opt.linkto)
		end
	end

	return self
end

return _M
