local ffi = require'ffi'
assert(ffi.os == 'Windows', 'platform not Windows')
require'gl_types'
local glut = ffi.load'glut'

ffi.cdef[[
void glutSolidTeapot(GLdouble size);
void glutWireTeapot(GLdouble size);
]]

return glut
