
## `require'$'`

Requires the minimum amount of modules that every Lua application seems to
need and makes a lot of symbols global. Run the script standalone with
`luajit $.lua` to get a listing of all the symbols (which you can then paste
into your editor config file for syntax highlighting).

Libraries don't use this module in an attempt to lower dependency count,
avoid polluting the global namespace and improve readability. Apps don't care
about all that and would rather establish a base vocabulary to use everywhere,
so they might welcome this module.

What libraries usually do instead of loading this module:

 * require the ffi module every goddamn time (and maybe the bit module).
 * copy-paste a few tools from [glue] to avoid bringing in the whole kitchen.
 * put used symbols into locals (also for speed when code is interpreted).

## Anyway, the API

---------------- -------------------------------------------------------------
__modules__
ffi              require'ffi'
bit              require'bit'
glue             require'glue'
pp               require'pp'
__math__
abs              math.abs
acos             math.acos
asin             math.asin
atan             math.atan
atan2            math.atan2
ceil             math.ceil
cos              math.cos
cosh             math.cosh
deg              math.deg
exp              math.exp
floor            math.floor
fmod             math.fmod
frexp            math.frexp
huge             math.huge
ldexp            math.ldexp
log              math.log
log10            math.log10
max              math.max
min              math.min
modf             math.modf
pi               math.pi
pow              math.pow
rad              math.rad
random           math.random
randomseed       math.randomseed
sin              math.sin
sinh             math.sinh
sqrt             math.sqrt
tan              math.tan
tanh             math.tanh
__table__
concat           table.concat
foreach          table.foreach
foreachi         table.foreachi
getn             table.getn
insert           table.insert
maxn             table.maxn
move             table.move
remove           table.remove
sort             table.sort
add              table.insert
push             table.insert
pop              table.remove
__coroutine__
cocreate         coroutine.create
cowrap           coroutine.wrap
resume           coroutine.resume
yield            coroutine.yield
__string__
format           string.format
_                string.format
rep              string.rep
char             string.char
traceback        debug.traceback
__os__
date             os.date
time             time.time with os.time semantics
clock            time.clock with os.clock semantics
sleep            time.sleep
exit             os.exit
__ffi__
cast             ffi.cast
Windows          ffi.os == 'Windows'
Linux            ffi.os == 'Linux'
OSX              ffi.os == 'OSX'
BSD              ffi.os == 'BSD'
POSIX            ffi.os == 'POSIX'
win              Windows
__bit__
bnot             bit.bnot
shl              bit.lshift
shr              bit.rshift
band             bit.band
bor              bit.bor
xor              bit.bxor
__glue__
memoize          glue.memoize
update           glue.update
merge            glue.merge
attr             glue.attr
count            glue.count
index            glue.index
keys             glue.keys
sortedpairs      glue.sortedpairs
map              glue.map
indexof          glue.indexof
append           glue.append
extend           glue.extend
autoload         glue.autoload
canopen          glue.canopen
readfile         glue.readfile
writefile        glue.writefile
readpipe         glue.readpipe
pack             glue.pack
unpack           glue.unpack
s:starts         glue.starts
s:ends           glue.ends
s:trim           glue.trim
s:lines          glue.lines
s:esc            glue.esc
esc              glue.esc
s:fromhex        glue.fromhex
s:tohex          glue.tohex
shift            glue.shift
addr             glue.addr
ptr              glue.ptr
inherit          glue.inherit
object           glue.object
---------------- -------------------------------------------------------------
