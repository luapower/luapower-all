
--OpenSSL libcrypto binding.
--Written by Cosmin Apreutesei. Public Domain.

require'libcrypto_h'
local ffi = require'ffi'
--TODO: rename libcrypto.dll to crypto.dll on Windows.
local C = pcall(ffi.load, 'crypto') or ffi.load'libcrypto'
local M = {C = C}
setmetatable(M, {__index = C})

return M
