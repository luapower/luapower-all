local matrix = require'affine2d'
local unit = require'unit'

local mt = matrix(1, 2, 3, 4, 5, 6)
test({mt:unpack()}, {1, 2, 3, 4, 5, 6})
mt:set(6, 5, 4, 3, 2, 1)
test({mt:unpack()}, {6, 5, 4, 3, 2, 1})
test({mt:copy():unpack()}, {mt:unpack()})
assert(mt:copy() ~= mt)
mt:reset()
test({mt:unpack()}, {1, 0, 0, 1, 0, 0})

mt:set(-1, 0, 0, 1, 5, 5)
test({mt:transform_point(10, 10)}, {10 * - 1 + 5, 10 + 5})
test({mt:transform_distance(10, 10)}, {10 * -1, 10})

--TODO: many more tests are needed.

