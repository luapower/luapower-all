--scene graph render for opengl
local ffi = require'ffi'
local glue = require'glue'
local BaseSG = require'sg_base'
local gl = require'winapi.gl21'
local glu = require'glu_lua'

local SG = glue.update({}, BaseSG)

SG.defaults = {
	frustum = {x1 = -1, x2 = 1, y1 = -1, y2 = 1, near = 1, far = 100},
}

function SG:free()
	if self.cairo_sg then self.cairo_sg:free() end --see 'texture' state object in sg_gl_mesh
	BaseSG.free(self)
end

function SG:transform(e)
	if e.abs then gl.glLoadIdentity() end
	if e.matrix then gl.glTransform(e.matrix) end
	if e.x or e.y or e.z then gl.glTranslated(e.x or 0, e.y or 0, e.z or 0) end
	if e.ax or e.ay or e.az then
		if e.rx or e.ry or e.rz then
			gl.glTranslated(e.rx or 0, e.ry or 0, e.rz or 0)
		end
		if e.ax then gl.glRotated(e.ax, 1, 0, 0) end
		if e.ay then gl.glRotated(e.ay, 0, 1, 0) end
		if e.az then gl.glRotated(e.az, 0, 0, 1) end
		if e.rx or e.ry or e.rz then
			gl.glTranslated(e.rx and -e.rx or 0, e.ry and -e.ry or 0, e.rz and -e.rz or 0)
		end
	end
	if e.sx or e.sy or e.sz then
		gl.glScaled(e.sx or 1, e.sy or 1, e.sz or 1)
	end
	if e.scale then gl.glScaled(e.scale, e.scale, e.scale) end
end

function SG:get_matrix()
	local matrix = ffi.new'GLfloat[16]'
	gl.glGetFloatv(gl.GL_MODELVIEW_MATRIX, matrix)
	return matrix
end

function SG:set_matrix(mt) --we're always in MODELVIEW mode
	gl.glLoadMatrixf(mt)
end

function SG:get_pmatrix()
	local matrix = ffi.new'GLfloat[16]'
	gl.glGetFloatv(gl.GL_PROJECTION_MATRIX, matrix)
	return matrix
end

SG.type = {}

function SG.type:viewport(e)
	local x, y, w, h = e.x or 0, e.y or 0, e.w, e.h
	--set viewport
	gl.glViewport(x, y, w, h)
	gl.glScissor(x, y, w, h)
	--set frustum
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	local f = glue.merge({}, e.frustum, self.defaults.frustum)
	local x1, x2, y1, y2, near, far = f.x1, f.x2, f.y1, f.y2, f.near, f.far
	gl.glFrustum(x1, x2, y1, y2, near, far)
	--set perspective division based on frustum and viewport aspect ratios
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	local fscale = math.abs(x2 - x1) / math.abs(y2 - y1)
	gl.glScaled(fscale, w/h, 1)
	--set camera
	if e.camera then
		local e = e.camera
		if e.eye then
			glu.gluLookAt(
				e.eye[1], e.eye[2], e.eye[3],
				e.center[1], e.center[2], e.center[3],
				e.up[1], e.up[2], e.up[3])
		end
		self:transform(e)
	end
	e.pmatrix = self:get_pmatrix()
	e.cmatrix = self:get_matrix()
	self:render_object(e.scene)
end

function SG.type:group(e)
	local matrix = self:get_matrix()
	for i=1,#e do
		self:render_object(e[i])
		self:set_matrix(matrix)
	end
end

function SG:render_object(e)
	local renderer = self:assert(self.type[e.type], 'invalid object type "%s"', tostring(e.type))
	if not renderer then return end
	if e.type ~= 'viewport' then self:transform(e) end
	renderer(self,e)
end

function SG:render_transparent(e)
	self.transparent_objects[#self.transparent_objects+1] = {
		matrix = self:get_matrix(),
		object = e,
	}
end

function SG:render_transparent_objects()
	gl.glDepthMask(gl.GL_FALSE)
	for i=1,#self.transparent_objects do
		local t = self.transparent_objects[i]
		self:set_matrix(t.matrix)
		self:render_object(t.object)
	end
	gl.glDepthMask(gl.GL_TRUE)
end

function SG:init()
	gl.glEnable(gl.GL_TEXTURE_2D)
	gl.glEnable(gl.GL_DEPTH_TEST)
	gl.glDepthFunc(gl.GL_LEQUAL) --for coplanar fragments (decals)
	gl.glDepthMask(gl.GL_TRUE)
	gl.glEnable(gl.GL_BLEND)
	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
	gl.glClearDepth(1)
	--gl.glClearColor(0,0,0,1)
	gl.glClearColor(1,1,1,1)
	--[[
	gl.glEnable(gl.GL_NORMALIZE)
	gl.glEnable(gl.GL_LIGHTING)
	gl.glEnable(gl.GL_LIGHT0)
	]]
	--[[
	--gl.glLightModelfv(gl.GL_LIGHT_MODEL_AMBIENT, ffi.new('GLfloat[4]', 1,1,0,0))
	local lightColor0 = ffi.new('GLfloat[4]', 1, 1, 0, 1)
	local lightPos0 = ffi.new('GLfloat[4]', 0, 0, -r/100, 1)
	gl.glLightfv(gl.GL_LIGHT0, gl.GL_DIFFUSE, lightColor0)
	gl.glLightfv(gl.GL_LIGHT0, gl.GL_POSITION, lightPos0)
	]]
	self.initialized = true
end

function SG:render(e)
	if not self.initialized then self:init() end
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
	self.transparent_objects = {}
	self:render_object(e)
	self:render_transparent_objects()
	if self.nocache then self:cache_clear() end
	self:errors_flush()
end

if not ... then require'sg_gl_demo' end

return SG

