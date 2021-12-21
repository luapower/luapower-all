
--OpenSSL libcrypto binding.
--Written by Cosmin Apreutesei. Public Domain.

require'libcrypto_h'
local ffi = require'ffi'
local C = ffi.load(ffi.abi'win' and 'libcrypto' or 'crypto')
local M = {C = C}
setmetatable(M, {__index = C})

if not ... then

local crypto = M

--TODO: make loading the default conf file work (might need a rebuild).
require'libcrypto_conf_h'
print(crypto.CONF_modules_load_file(nil, nil, crypto.CONF_MFLAGS_DEFAULT_SECTION) == 1)

end

return M
