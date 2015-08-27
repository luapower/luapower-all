--chipmunk2D ffi binding for chipmunk 6.x
local ffi = require'ffi'
require'chipmunk_h'
local C = ffi.load'chipmunk'

C.cpInitChipmunk()

if not ... then require'chipmunk_demo' end

return C
