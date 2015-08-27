local player = require'cplayer'
local ffi = require'ffi'
local C = require'chipmunk'

local space = C.cpSpaceNew()
space.iterations = 20
space.gravity.x = 0
space.gravity.y = -100

local body = C.cpBodyNew(1, 10000) --m, i
body.p.x = 200
body.p.y = 200
--C.cpBodySetPos(body, ffi.new('cpVect', 200, 200))
C.cpSpaceAddBody(space, body)
body.v.x = 100
body.v.y = 100

local shape = C.cpCircleShapeNew(body, 50, ffi.new('cpVect', 20, 20)) --radius, offset
shape.collision_type = 1
C.cpSpaceAddShape(space, shape)
shape.u = 1.0
shape.e = 1.0

function player:on_render(cr)
	C.cpSpaceStep(space, 1/100)
	C.cpBodyUpdatePosition(body, 1/100)

	local offset = C.cpCircleShapeGetOffset(shape)
	local radius = C.cpCircleShapeGetRadius(shape)

	--print(offset.x, offset.y, radius)
	self:circle(offset.x, offset.y, radius)
end

player:play()

C.cpShapeFree(shape)
C.cpBodyFree(body)
C.cpSpaceFree(space)

