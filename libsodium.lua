
--libsodium binding
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
require'libsodium_h'

local C = ffi.load'sodium'
local M = {C = C}

--TODO

if not ... then
	--TODO
end

return M

