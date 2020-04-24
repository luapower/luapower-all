
--seriously, there's no reason for all that qualifying of everything.

ffi  = require'ffi'
bit  = require'bit'
glue = require'glue'
time = require'time'
pp   = require'pp'

floor       = math.floor
ceil        = math.ceil
min         = math.min
max         = math.max
abs         = math.abs
sqrt        = math.sqrt
random      = math.random
randomseed  = math.randomseed

concat      = table.concat
insert      = table.insert
remove      = table.remove
shift       = glue.shift
add         = table.insert
push        = table.insert
pop         = table.remove
append      = glue.append
extend      = glue.extend
sort        = table.sort
indexof     = glue.indexof
map         = glue.map
pack        = glue.pack
unpack      = glue.unpack

update      = glue.update
merge       = glue.merge
attr        = glue.attr
count       = glue.count
index       = glue.index
keys        = glue.keys
sortedpairs = glue.sortedpairs

--make these globals because they're usually used with a string literal as arg#1.
format      = string.format
_           = string.format
rep         = string.rep
char        = string.char
esc         = glue.esc

string.starts  = glue.starts
string.ends    = glue.ends
string.trim    = glue.trim
string.lines   = glue.lines
string.esc     = glue.esc
string.fromhex = glue.fromhex
string.tohex   = glue.tohex
string.subst   = glue.subst

cocreate    = coroutine.create
cowrap      = coroutine.wrap
resume      = coroutine.resume
yield       = coroutine.yield

noop     = glue.noop
pass     = glue.pass

memoize  = glue.memoize

bnot = bit.bnot
shl  = bit.lshift
shr  = bit.rshift
band = bit.band
bor  = bit.bor
xor  = bit.bxor

C       = ffi.C
cast    = ffi.cast
Windows = false
Linux   = false
OSX     = false
BSD     = false
POSIX   = false
_G[ffi.os] = true
win     = Windows
addr    = glue.addr
ptr     = glue.ptr

module    = glue.module
autoload  = glue.autoload

inherit  = glue.inherit
object   = glue.object
before   = glue.before
after    = glue.after
override = glue.override

traceback = debug.traceback

--OS API bindings

date  = os.date
clock = os.clock
time.install() --replace os.date and os.time.
sleep = time.sleep
time  = glue.time --replace time module with the uber-time function.
day   = glue.day
month = glue.month
year  = glue.year

canopen   = glue.canopen
readfile  = glue.readfile
writefile = glue.writefile

readpipe  = glue.readpipe

exit = os.exit

--dump standard library keywords for syntax highlighting.

if not ... then
	local t = {}
	for k,v in pairs(_G) do
		if k ~= 'type' then
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
