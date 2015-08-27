local ffi = require'ffi'
assert(ffi.os == 'Windows', 'platform not Windows')
require'glu_h'
return ffi.load'glu32'
