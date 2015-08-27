--scenegraph/gl/obj_model: render wavefront obj files.
local SG = require'sg_gl'
local obj_loader = require 'obj_loader'
require'sg_gl_mesh'

function SG.type:obj_model(e)
	local mesh = self.cache:get(e.file)
	if not mesh then
		mesh = obj_loader.load(e.file.path, e.file.use_cache)
		self.cache:set(e.file, mesh)
	end
	self:render_object(mesh)
	--clear vbo and ibo values/data from ram (the data is now in video ram)
	mesh.vbo_v.values = nil
	mesh.vbo_v.data = nil
	mesh.ibo.values = nil
	mesh.ibo.data = nil
end

if not ... then require'sg_gl_demo' end

