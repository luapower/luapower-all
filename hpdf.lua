--hpdf (libharu) binding (Cosmin Apreutesei, public domain)
local ffi = require'ffi'
require'hpdf_h'

local C = ffi.load'hpdf'
local M = C

--TODO: luaized API

return M
