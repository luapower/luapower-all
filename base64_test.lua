local base64 = require'base64'

local decode = base64.decode
local encode = base64.encode

assert(decode'YW55IGNhcm5hbCBwbGVhc3VyZS4=' == 'any carnal pleasure.')
assert(decode'YW55IGNhcm5hbCBwbGVhc3VyZQ==' == 'any carnal pleasure')
assert(decode'YW55IGNhcm5hbCBwbGVhc3Vy' == 'any carnal pleasur')
assert(decode'YW55IGNhcm5hbCBwbGVhc3U=' == 'any carnal pleasu')
assert(decode'YW55IGNhcm5hbCBwbGVhcw==' == 'any carnal pleas')
assert(decode'., ? !@#$%^& \n\r\n\r YW55IGNhcm5hbCBwbGVhcw== \n\r' == 'any carnal pleas')

assert(encode'any carnal pleasure.' == 'YW55IGNhcm5hbCBwbGVhc3VyZS4=')
assert(encode'any carnal pleasure' == 'YW55IGNhcm5hbCBwbGVhc3VyZQ==')
assert(encode'any carnal pleasur' == 'YW55IGNhcm5hbCBwbGVhc3Vy')
assert(encode'any carnal pleasu' == 'YW55IGNhcm5hbCBwbGVhc3U=')
assert(encode'any carnal pleas' == 'YW55IGNhcm5hbCBwbGVhcw==')

assert(decode(encode'') == '')
assert(decode(encode'x') == 'x')
assert(decode(encode'xx') == 'xx')
assert(decode'.!@#$%^&*( \n\r\t' == '')

local clock = require'time'.clock
local libb64 = require'libb64'
local s=''
for i=1,1000 do s = s .. '0123456789' end
local n = 50000

local st = clock()
local encoded1
for i=1,n do
	encoded1 = encode(s)
end
local et = clock()
local dt = et - st
print('Lua len:',#s,'n:',n,dt,'sec', (#s*n)/dt/1024.0/1024.0, 'MB/s' )

local st = clock()
local encoded2
for i=1,n do
	encoded2 = libb64.encode(s)
end
local et = clock()
local dt = et - st
print('C   len:',#s,'n:',n,dt,'sec', (#s*n)/dt/1024.0/1024.0, 'MB/s' )

encoded2 = encoded2:gsub('\n', '')
assert(encoded1 == encoded2)
assert(decode(encoded1) == s)

--TODO: benchmark decode.
