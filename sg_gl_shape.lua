local SG = require'sg_gl'
local gl = require'winapi.gl21'
local glue = require'glue'

function SG.type:shape(e)
	local mesh = self.cache:get(e)
	if not mesh then
		local vbo = {layout = 'vc', values = {}}
		mesh = {type = 'mesh', vbo_v = vbo, vbo_c = vbo, ibo_partitions = {}}
		local i = 1
		local color, partition
		while i <= #e do
			if type(e[i]) == 'string' then --see if there's a command
				local s = e[i]
				i = i + 1
				if self.mesh_modes[s] then
					partition = {
						mode = s,
						from = partition and partition.from + partition.count or 0,
						count = 0,
						transparent = color and color[4] < 1 or nil,
					}
					mesh.ibo_partitions[#mesh.ibo_partitions+1] = partition
				elseif s == 'color' then
					if not (e[i] and e[i+1] and e[i+2] and e[i+3]) then
						self:error'shape: invalid color: r,g,b,a expected'
						return
					end
					color = {e[i], e[i+1], e[i+2], e[i+3]}
					if e[i+3] < 1 and partition then
						partition.transparent = true
					end
					i = i + 4
				else
					self:error('shape: unknown command %s', s)
					return
				end
			else
				self:assert(partition, 'shape: no current mode')
				self:assert(color, 'shape: no current color')
				if not partition or not color then return end

				if not (e[i] and e[i+1] and e[i+2]) then
					self:error'shape: invalid vertex: x,y,z expected'
					return
				end
				glue.append(vbo.values, e[i], e[i+1], e[i+2], unpack(color))
				partition.count = partition.count + 1
				i = i + 3
			end
		end
		self.cache:set(e, mesh)
	end
	self:render_object(mesh)
end

if not ... then require'sg_gl_demo' end

