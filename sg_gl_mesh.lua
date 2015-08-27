--scenegraph/gl/mesh: render mesh objects made of VBOs, IBOs and IBO slices.
--supports interleaved or separate v/n/t/c VBOs in any combination.
--textures can be either image files or 2D scene graphs rendered with cairo on a pixman surface.
--imagefile module is loaded on-demand for image-type textures (which in turn loads libpng, etc. on demand).
--sg_cairo module is loaded on-demand for surface-type textures.
local glue = require'glue'
local ffi = require'ffi'
local gl = require'winapi.gl21'
local SG = require'sg_gl'

local function buffer_free(vbo)
	gl.glDeleteBuffers(1, vbo.handle)
end

local vbo_usages = {
	static = gl.GL_STATIC_DRAW,
	dynamic = gl.GL_DYNAMIC_DRAW,
	stream = gl.GL_STREAM_DRAW,
}

local vbo_sizes = {
	v = 12, --vertices:  float(x,y,z)
	n = 12, --normals:   float(x,y,z)
	t =  8, --texcoords: float(u,v)
	c = 16, --colors:    float(r,g,b,a)
}

SG:state_object('vbo',
	function(self, e)
		local record_size = 0
		local offsets = {}
		for c in e.layout:gmatch'.' do
			offsets[c] = record_size
			record_size = record_size + vbo_sizes[c]
		end
		local handle = ffi.new'uint32_t[1]'
		local data, sz
		if e.data then
			data, sz = e.data, e.size
		elseif e.values then
			data = ffi.new('float[?]', #e.values, e.values)
			sz = ffi.sizeof(data)
		else
			error'vbo data or values missing'
		end
		gl.glGenBuffers(1, handle)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, handle[0])
		gl.glBufferData(gl.GL_ARRAY_BUFFER, sz, data, vbo_usages[e.usage or 'static'])
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
		local count = sz / record_size
		assert(math.floor(count) == count)
		return {
			handle = handle,
			record_size = record_size,       --for glVertexPointer
			offsets = offsets,               --for glVertexPointer
			count = count,                   --for range checking and creating a default ibo
			free = buffer_free,
		}
	end,
	function(self, vbo)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo and vbo.handle[0] or 0)
	end
)

SG:state_value('vbo_v', function(self, vbo)
	if vbo then
		vbo = self:set_vbo(vbo)
		gl.glEnableClientState(gl.GL_VERTEX_ARRAY)
		gl.glVertexPointer(3, gl.GL_FLOAT, vbo.record_size, ffi.cast('void*', vbo.offsets.v))
	else
		gl.glDisableClientState(gl.GL_VERTEX_ARRAY)
	end
end)

SG:state_value('vbo_n', function(self, vbo)
	if vbo then
		vbo = self:set_vbo(vbo)
		gl.glEnableClientState(gl.GL_NORMAL_ARRAY)
		gl.glNormalPointer(gl.GL_FLOAT, vbo.record_size, ffi.cast('void*', vbo.offsets.n))
	else
		gl.glDisableClientState(gl.GL_NORMAL_ARRAY)
	end
end)

SG:state_value('vbo_t', function(self, vbo)
	if vbo then
		vbo = self:set_vbo(vbo)
		gl.glEnableClientState(gl.GL_TEXTURE_COORD_ARRAY)
		gl.glTexCoordPointer(2, gl.GL_FLOAT, vbo.record_size, ffi.cast('void*', vbo.offsets.t))
	else
		gl.glDisableClientState(gl.GL_TEXTURE_COORD_ARRAY)
	end
end)

SG:state_value('vbo_c', function(self, vbo)
	if vbo then
		vbo = self:set_vbo(vbo)
		gl.glEnableClientState(gl.GL_COLOR_ARRAY)
		gl.glColorPointer(4, gl.GL_FLOAT, vbo.record_size, ffi.cast('void*', vbo.offsets.c))
	else
		gl.glDisableClientState(gl.GL_COLOR_ARRAY)
	end
end)

local function ibo_ctype(count)
	return count > 65535 and 'uint32_t[?]' or count > 255 and 'uint16_t[?]' or 'uint8_t[?]'
end

local function ibo_gltype(count)
	return count > 65535 and gl.GL_UNSIGNED_INT or count > 255 and gl.GL_UNSIGNED_SHORT or gl.GL_UNSIGNED_BYTE
end

SG:state_object('ibo',
	function(self, e)
		local handle = ffi.new'uint32_t[1]'
		local data, sz, count
		if e.data then
			data, sz, count = e.data, e.size, e.count
			if not count then
				assert(sz, 'ibo: size expected in absence of count')
				count = sz > 65535 * 4 and sz / 4 or sz > 255 * 2 and sz / 2 or sz
			elseif not sz then
				assert(count, 'ibo: count expected in absence of size')
				sz = ffi.sizeof(ibo_ctype(count), count)
			end
		elseif e.values then
			count = #e.values
			data = ffi.new(ibo_ctype(count), count, e.values)
			sz = ffi.sizeof(data)
			--for i=0,(sz-1)/2 do print(data[i]) end
		elseif e.count then
			count = e.count
			data = ffi.new(ibo_ctype(count), count)
			for i=0,count-1 do
				data[i] = e.from + i --e.from is the start index into the vbo
			end
		else
			error'ibo: data, values or count exptected'
		end
		local sz = ffi.sizeof(data)
		gl.glGenBuffers(1, handle)
		gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, handle[0])
		gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, sz, data, vbo_usages[e.usage or 'static'])
		gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, 0)
		return {
			handle = handle,
			count = count, --for range checking
			free = buffer_free,
		}
	end,
	function(self, ibo)
		gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, ibo.handle[0])
	end
)

local gl_source_formats = {
	rgb = gl.GL_RGB,
	bgr = gl.GL_BGR,
	g = gl.GL_LUMINANCE,
	ga = gl.GL_LUMINANCE_ALPHA,
	rgba = gl.GL_RGBA,
	bgra = gl.GL_BGRA,
}

local imagefile_load_options = {
	accept = glue.update({bottom_up = true}, gl_source_formats)
}

local function texture_free(tex)
	gl.glDeleteTextures(1, tex.handle)
end

SG:state_object('texture',
	function(self, e)
		return self:assert(glue.fpcall(function(finally, except)

			local handle = ffi.new'uint32_t[1]'
			gl.glGenTextures(1, handle)
			except(function() gl.glDeleteTextures(1, handle) end)

			gl.glBindTexture(gl.GL_TEXTURE_2D, handle[0])
			gl.glTexEnvi(gl.GL_TEXTURE_ENV, gl.GL_TEXTURE_ENV_MODE, gl.GL_REPLACE) --ignore texture env. color
			gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR)
			gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR)
			gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP)
			gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP)
			gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1)

			if e.type == 'image' then --image textures don't require cairo

				local imagefile = require'imagefile'

				local img = imagefile.load(e.file, imagefile_load_options)
				e.w = img.w
				e.h = img.h
				local format = assert(gl_source_formats[img.format.pixel], 'image texture: unsupported source format')
				gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, img.w, img.h, 0, format, gl.GL_UNSIGNED_BYTE, img.data)

			elseif e.type == 'surface' then

				assert(e.w and not e.h, 'surface texture: w and h expected')
				local CairoSG = require'sg_cairo'

				local sg = self.cache:get(e.object)
				if not sg then
					local surface = cairo.cairo_image_surface_create(cairo.CAIRO_FORMAT_ARGB32, e.w, e.h)
					sg = CairoSG:new(surface, self.cache) --we share our cache
					surface:destroy() --sg created an internal context for the surface, which now is the only reference to it.
											--this means the surface will be freed when the context is freed on sg:free().
					if e.nocache then --if texture is not cached, keep sg alive (and implicitly surface) so it can be reused.
						self.cache:set(e.object, sg)
					else
						finally(function() sg:free() end)
					end
				end

				sg:render(e.object)

				gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, e.w, e.h,
												0, gl.BGRA, gl.GL_UNSIGNED_BYTE, sg.cr:get_surface():get_data())

			else
				error(string.format('texture: image or surface object expected, got %s', e.type or '<unknown>'))
			end
			return {handle = handle, free = texture_free}
		end))
	end,
	function(self, tex)
		gl.glBindTexture(gl.GL_TEXTURE_2D, tex and tex.handle[0] or 0)
	end
)

SG:state_value('line_width', function(self, width) gl.glLineWidth(width) end)

SG.mesh_modes = {
	points = gl.GL_POINTS,
	line_strip = gl.GL_LINE_STRIP,
	line_loop = gl.GL_LINE_LOOP,
	lines = gl.GL_LINES,
	triangles = gl.GL_TRIANGLES,
	triangle_strip = gl.GL_TRIANGLE_STRIP,
	triangle_fan = gl.GL_TRIANGLE_FAN,
	quads = gl.GL_QUADS,
	quad_strip = gl.GL_QUAD_STRIP,
	polygon = gl.GL_POLYGON,
}

function SG:gl_draw_elements(mode, from, count, buffer_count, transparent)
	mode = self:assert(self.mesh_modes[mode], 'invalid mode %s', tostring(mode))
	if not mode then return end
	assert(from + count <= buffer_count, 'ibo selection out of range')
	--print(mode, from, count, ffi.cast('uint8_t*', ffi.sizeof(ibo_ctype(buffer_count), from)))
	gl.glDrawElements(mode, count, ibo_gltype(count), ffi.cast('uint8_t*', ffi.sizeof(ibo_ctype(buffer_count), from)))
end

function SG.type:mesh(e)
	assert(e.vbo_v, 'vbo_v expected')
	self:set_vbo_v(e.vbo_v)
	self:set_vbo_n(e.vbo_n)
	self:set_vbo_t(e.vbo_t)
	self:set_vbo_c(e.vbo_c)
	self:set_texture(e.texture)
	if not e.ibo then --create a default ibo that selects all vertices
		local vbo_v = self.cache:get(e.vbo_v)
		local vbo_n = e.vbo_n and self.cache:get(e.vbo_n)
		local vbo_t = e.vbo_t and self.cache:get(e.vbo_t)
		local vbo_c = e.vbo_c and self.cache:get(e.vbo_c)
		local count = math.min(
							vbo_v.count or math.huge,
							vbo_n and vbo_n.count or math.huge,
							vbo_t and vbo_t.count or math.huge,
							vbo_c and vbo_c.count or math.huge)
		e.ibo = {from = 0, count = count}
	end
	local ibo = self:set_ibo(e.ibo)
	if e.ibo_partitions then
		for _,p in ipairs(e.ibo_partitions) do
			self:set_texture(p.texture or e.texture)
			self:gl_draw_elements(p.mode or e.mode, p.from, p.count, ibo.count, p.transparent or e.transparent)
		end
	else
		self:gl_draw_elements(e.mode, e.from or 0, e.count or ibo.count, ibo.count)
	end
end

if not ... then require'sg_gl_demo' end

