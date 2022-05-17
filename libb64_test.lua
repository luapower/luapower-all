local b64 = require'libb64'
local decode = b64.decode
local encode = b64.encode

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

