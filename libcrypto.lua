
--OpenSSL libcrypto binding.
--Written by Cosmin Apreutesei. Public Domain.

require'libcrypto_h'
local ffi = require'ffi'
local C = ffi.load(ffi.abi'win' and 'libcrypto' or 'crypto')
local M = {C = C}
setmetatable(M, {__index = C})

if not ... then

local crypto = M
require'libcrypto_conf_h'
print(crypto.CONF_modules_load_file(nil, nil,
	bit.bor(
		crypto.CONF_MFLAGS_DEFAULT_SECTION,
		crypto.CONF_MFLAGS_IGNORE_MISSING_FILE)))
os.exit()

end

return M
