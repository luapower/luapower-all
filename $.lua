
--drop all the tools on the floor

ffi     = require'ffi'
bit     = require'bit'
glue    = require'glue'
errors  = require'errors'
time    = require'time'
pp      = require'pp'
exedir  = require'package.exedir'
exepath = require'package.exepath'

isstr  = glue.isstr
isnum  = glue.isnum
isint  = glue.isint
istab  = glue.istab
isfunc = glue.isfunc

floor       = math.floor
ceil        = math.ceil
min         = math.min
max         = math.max
abs         = math.abs
sqrt        = math.sqrt
ln          = math.log
sin         = math.sin
cos         = math.cos
tan         = math.tan
rad         = math.rad
deg         = math.deg
random      = math.random
randomseed  = math.randomseed
clamp       = glue.clamp
round       = glue.round
snap        = glue.snap
lerp        = glue.lerp
sign        = glue.sign
strict_sign = glue.strict_sign
nextpow2    = glue.nextpow2
repl        = glue.repl

concat      = table.concat
cat         = table.concat
catargs     = glue.catargs
insert      = table.insert
remove      = table.remove
shift       = glue.shift
local insert = insert; function add(t, v) return insert(t, v) end
push        = add
pop         = table.remove
del         = table.remove
ins         = table.insert
rem         = table.remove
append      = glue.append
extend      = glue.extend
sort        = table.sort
indexof     = glue.indexof
map         = glue.map
imap        = glue.imap
pack        = glue.pack
unpack      = glue.unpack
reverse     = glue.reverse
binsearch   = glue.binsearch
sortedarray = glue.sortedarray

empty       = glue.empty
update      = glue.update
merge       = glue.merge
attr        = glue.attr
count       = glue.count
index       = glue.index
keys        = glue.keys
sortedkeys  = glue.sortedkeys
sortedpairs = glue.sortedpairs

--make these globals because they're usually used with a string literal as arg#1.
format      = string.format
fmt         = string.format
_           = string.format
rep         = string.rep
char        = string.char
esc         = glue.esc
subst       = glue.subst
names       = glue.names
random_string = glue.random_string

--make these globals because they may be used as filters.
trim        = glue.trim
outdent     = glue.outdent

string.starts  = glue.starts
string.ends    = glue.ends
string.trim    = glue.trim
string.pad     = glue.pad
string.lpad    = glue.lpad
string.rpad    = glue.rpad
string.lines   = glue.lines
string.outdent = glue.outdent
string.esc     = glue.esc
string.fromhex = glue.fromhex
string.tohex   = glue.tohex
string.subst   = glue.subst
string.capitalize = glue.capitalize

collect = glue.collect

noop     = glue.noop
pass     = glue.pass

memoize    = glue.memoize
tuple      = glue.tuple
tuples     = glue.tuples
weaktuples = glue.weaktuples

assertf  = glue.assert

bnot = bit.bnot
shl  = bit.lshift
shr  = bit.rshift
band = bit.band
bor  = bit.bor
xor  = bit.bxor

C       = ffi.C
cast    = ffi.cast
sizeof  = ffi.sizeof
typeof  = ffi.typeof
_G[ffi.os] = true
win     = Windows
addr    = glue.addr
ptr     = glue.ptr

module   = glue.module
autoload = glue.autoload

inherit  = glue.inherit
object   = glue.object
before   = glue.before
after    = glue.after
override = glue.override
gettersandsetters = glue.gettersandsetters

pr = pr or pp --pp's printer is good, $log's printer is even better.

trace = function() print(debug.traceback()) end
traceback = debug.traceback

time.install() --replace os.date, os.time and os.clock.
date   = os.date
clock  = os.clock
time   = glue.time --replace time module with the uber-time function.
day    = glue.day
sunday = glue.sunday
month  = glue.month
year   = glue.year
timeago = glue.timeago

kbytes = glue.kbytes

canopen     = glue.canopen
readfile    = glue.readfile
writefile   = glue.writefile
replacefile = glue.replacefile
readpipe    = glue.readpipe

fpcall = glue.fpcall
fcall  = glue.fcall

exit = os.exit
env = os.getenv

freelist = glue.freelist

i8p = glue.i8p
i8a = glue.i8a
u8p = glue.u8p
u8a = glue.u8a
i32p = glue.i32p
i32a = glue.i32a
u32p = glue.u32p
u32a = glue.u32a

buffer   = glue.buffer
dynarray = glue.dynarray

--stubs, implemented in $log
log        = log      or noop
note       = note     or noop
dbg        = dbg      or noop
warnif     = warnif   or noop
logerror   = logerror or noop
logargs    = logargs  or pass
logprintargs = logprintargs or pass

raise = errors.raise

function check(errorclass, event, v, ...)
	if v then return v end
	assert(type(errorclass) == 'string' or errors.is(errorclass))
	assert(type(event) == 'string')
	local e = errors.new(errorclass, ...)
	if not e.logged then
		logerror(e.classname, event, e.message)
		e.logged = true --prevent duplicate logging of the error on a catch-all handler.
	end
	raise(e)
end

--dump standard library keywords for syntax highlighting.

if not ... then
	local t = {}
	require'$log'
	require'$fs'
	require'$daemon'
	for k,v in pairs(_G) do
		if k ~= 'type' then --reused too much, don't like it colored.
			t[#t+1] = k
			if type(v) == 'table' and v ~= _G and v ~= arg then
				for kk in pairs(v) do
					t[#t+1] = k..'.'..kk
				end
			end
		end
	end
	sort(t)
	print(concat(t, ' '))
end

return {with = function(s)
	for _,s in ipairs(names(s)) do
		require('$'..s)
	end
end}
