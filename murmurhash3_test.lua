local ffi = require'ffi'
require'unit'

local function sanity_test(hashmod)
	local hash = require(hashmod)
	assert(hash'hey' == 318325784)
	assert(hash'dude' == -284915725)

	--this code is from their tests
	local key = ffi.new'uint8_t[256]'
	local hashes = ffi.new'uint32_t[256]'
	for i=0,255 do
		key[i] = i
		hashes[i] = hash(key, i, 256-i)
	end
	local final = hash(ffi.cast('uint8_t*', hashes), 1024, 0)
  	test(final, bit.tobit(0xB0F57EE3))
	print(hashmod, 'ok')
end

sanity_test'murmurhash3'
sanity_test'pmurhash'
