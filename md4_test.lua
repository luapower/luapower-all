local md4 = require'md4'
local glue = require'glue'

local function sumhex(s)
	return glue.tohex(md4.sum(s))
end

assert(sumhex'' == '31d6cfe0d16ae931b73c59d7e0c089c0')
assert(sumhex'a' == 'bde52cb31de33e46245e05fbdbd6fb24')
assert(sumhex'abc' == 'a448017aaf21d8525fc10ae87aa6729d')
assert(sumhex'message digest' == 'd9130a8164549fe818874806e1c7014b')
assert(sumhex'abcdefghijklmnopqrstuvwxyz' == 'd79e1c308aa5bbcdeea8ed63df412da9')
assert(sumhex'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' == '043f8582f241db351ce627e153e7f0e4')
assert(sumhex'12345678901234567890123456789012345678901234567890123456789012345678901234567890' ==
	'e33b4ddc9c38f2199c3e7b164fcc0536')
