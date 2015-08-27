--glulua: GLU in Lua taken from mesa's glu 9.0.0
local ffi = require'ffi'
local gl = require'winapi.gl21'

local M = {}

local function normalize(v) --float[3]
	local r = math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])
	if r == 0 then return end
	v[0] = v[0]/r
	v[1] = v[1]/r
	v[2] = v[2]/r
end

local function cross(v1, v2, result) --float[3]
	result[0] = v1[1]*v2[2] - v1[2]*v2[1]
	result[1] = v1[2]*v2[0] - v1[0]*v2[2]
	result[2] = v1[0]*v2[1] - v1[1]*v2[0]
end

local function __gluMakeIdentityf(m) --float[16]
    m[0+4*0] = 1; m[0+4*1] = 0; m[0+4*2] = 0; m[0+4*3] = 0
    m[1+4*0] = 0; m[1+4*1] = 1; m[1+4*2] = 0; m[1+4*3] = 0
    m[2+4*0] = 0; m[2+4*1] = 0; m[2+4*2] = 1; m[2+4*3] = 0
    m[3+4*0] = 0; m[3+4*1] = 0; m[3+4*2] = 0; m[3+4*3] = 1
end

function M.gluLookAt(eyex, eyey, eyez, centerx, centery, centerz, upx, upy, upz)
    local forward = ffi.new'float[3]'
	 local side = ffi.new'float[3]'
	 local up = ffi.new'float[3]'
    local m = ffi.new'float[4][4]'

    forward[0] = centerx - eyex
    forward[1] = centery - eyey
    forward[2] = centerz - eyez

    up[0] = upx
    up[1] = upy
    up[2] = upz

    normalize(forward)

    -- Side = forward x up
    cross(forward, up, side)
    normalize(side)

    -- Recompute up as: up = side x forward
    cross(side, forward, up)

    __gluMakeIdentityf(ffi.cast('float*', m))
    m[0][0] = side[0]
    m[1][0] = side[1]
    m[2][0] = side[2]

    m[0][1] = up[0]
    m[1][1] = up[1]
    m[2][1] = up[2]

    m[0][2] = -forward[0]
    m[1][2] = -forward[1]
    m[2][2] = -forward[2]

    gl.glMultMatrixf(ffi.cast('float*', m))
    gl.glTranslated(-eyex, -eyey, -eyez)
end

function M.gluInvertMatrixf(m)
	 local inv = ffi.new'double[16]'

    inv[0] =   m[5]*m[10]*m[15] - m[5]*m[11]*m[14] - m[9]*m[6]*m[15]
             + m[9]*m[7]*m[14] + m[13]*m[6]*m[11] - m[13]*m[7]*m[10]
    inv[4] =  -m[4]*m[10]*m[15] + m[4]*m[11]*m[14] + m[8]*m[6]*m[15]
             - m[8]*m[7]*m[14] - m[12]*m[6]*m[11] + m[12]*m[7]*m[10]
    inv[8] =   m[4]*m[9]*m[15] - m[4]*m[11]*m[13] - m[8]*m[5]*m[15]
             + m[8]*m[7]*m[13] + m[12]*m[5]*m[11] - m[12]*m[7]*m[9]
    inv[12] = -m[4]*m[9]*m[14] + m[4]*m[10]*m[13] + m[8]*m[5]*m[14]
             - m[8]*m[6]*m[13] - m[12]*m[5]*m[10] + m[12]*m[6]*m[9]
    inv[1] =  -m[1]*m[10]*m[15] + m[1]*m[11]*m[14] + m[9]*m[2]*m[15]
             - m[9]*m[3]*m[14] - m[13]*m[2]*m[11] + m[13]*m[3]*m[10]
    inv[5] =   m[0]*m[10]*m[15] - m[0]*m[11]*m[14] - m[8]*m[2]*m[15]
             + m[8]*m[3]*m[14] + m[12]*m[2]*m[11] - m[12]*m[3]*m[10]
    inv[9] =  -m[0]*m[9]*m[15] + m[0]*m[11]*m[13] + m[8]*m[1]*m[15]
             - m[8]*m[3]*m[13] - m[12]*m[1]*m[11] + m[12]*m[3]*m[9]
    inv[13] =  m[0]*m[9]*m[14] - m[0]*m[10]*m[13] - m[8]*m[1]*m[14]
             + m[8]*m[2]*m[13] + m[12]*m[1]*m[10] - m[12]*m[2]*m[9]
    inv[2] =   m[1]*m[6]*m[15] - m[1]*m[7]*m[14] - m[5]*m[2]*m[15]
             + m[5]*m[3]*m[14] + m[13]*m[2]*m[7] - m[13]*m[3]*m[6]
    inv[6] =  -m[0]*m[6]*m[15] + m[0]*m[7]*m[14] + m[4]*m[2]*m[15]
             - m[4]*m[3]*m[14] - m[12]*m[2]*m[7] + m[12]*m[3]*m[6]
    inv[10] =  m[0]*m[5]*m[15] - m[0]*m[7]*m[13] - m[4]*m[1]*m[15]
             + m[4]*m[3]*m[13] + m[12]*m[1]*m[7] - m[12]*m[3]*m[5]
    inv[14] = -m[0]*m[5]*m[14] + m[0]*m[6]*m[13] + m[4]*m[1]*m[14]
             - m[4]*m[2]*m[13] - m[12]*m[1]*m[6] + m[12]*m[2]*m[5]
    inv[3] =  -m[1]*m[6]*m[11] + m[1]*m[7]*m[10] + m[5]*m[2]*m[11]
             - m[5]*m[3]*m[10] - m[9]*m[2]*m[7] + m[9]*m[3]*m[6]
    inv[7] =   m[0]*m[6]*m[11] - m[0]*m[7]*m[10] - m[4]*m[2]*m[11]
             + m[4]*m[3]*m[10] + m[8]*m[2]*m[7] - m[8]*m[3]*m[6]
    inv[11] = -m[0]*m[5]*m[11] + m[0]*m[7]*m[9] + m[4]*m[1]*m[11]
             - m[4]*m[3]*m[9] - m[8]*m[1]*m[7] + m[8]*m[3]*m[5]
    inv[15] =  m[0]*m[5]*m[10] - m[0]*m[6]*m[9] - m[4]*m[1]*m[10]
             + m[4]*m[2]*m[9] + m[8]*m[1]*m[6] - m[8]*m[2]*m[5]

	local det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12]
	if det == 0 then return end
	det = 1 / det
	for i=0,15 do
		inv[i] = inv[i] * det
	end
	local ret = ffi.new'float[16]'
	for i=0,15 do ret[i] = inv[i] end
	return ret
end

function M.gluMultMatrixf(m1, m2)
	local m = ffi.new'GLfloat[16]'
	for i = 0,3 do
		for j = 0,3 do
			local x = 0
			for k = 0,3 do
				x = x + m1[i*4+k] * m2[k*4+j]
			end
			m[i*4+j] = x
		end
	end
	return m
end

return M
