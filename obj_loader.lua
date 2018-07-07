--wavefront obj loader to the gl scene graph mesh format.
--supports groups with triangle and quad faces and textures with uv texcoords.
local parse = require'obj_parser'.parse
local glue = require'glue'
local tuple = require'tuple'
local ffi = require'ffi'

local function ibo_ctype(count)
	return count > 65535 and 'uint32_t[?]' or count > 255 and 'uint16_t[?]' or 'uint8_t[?]'
end

local function load(file, use_file_cache)

	if use_file_cache and glue.canopen(file..'.vbo') then
		local s = assert(glue.readfile(file..'.vbo.tmp'))
		local buf, sz = ffi.cast('const char*', s), #s
		local vbo = {layout = 'vnt', data = buf, size = sz, s = s}
		local buf, sz = read_binary_file(file..'.ibo.tmp')
		local ibo = {data = buf, size = sz}
		local ibo_partitions = loadfile(file..'.ibop.tmp')()
		return {
			type = 'mesh',
			vbo_v = vbo,
			vbo_n = vbo,
			vbo_t = vbo,
			ibo = ibo,
			ibo_partitions = ibo_partitions,
		}
	end

	local vertices, normals, texcoords, materials, textures = {}, {}, {}, {}, {}
	local vbo_values, vbo_indices, vbo_next_index = {}, {}, 0
	local face, material, texture
	local groups = {'__default__'} --we start off with a single default group
	local combinations = {} --{tuple(group, mode, texture) = {index1,index2,...}}
	local check
	parse(file, {
		check_function = function(check_func)
			check = check_func
		end,
		vertex = function(x,y,z)
			table.insert(vertices, x)
			table.insert(vertices, y)
			table.insert(vertices, z)
		end,
		normal = function(x,y,z)
			table.insert(normals, x)
			table.insert(normals, y)
			table.insert(normals, z)
		end,
		texcoord = function(u,v,w)
			table.insert(texcoords, u)
			table.insert(texcoords, v)
		end,
		start_face = function()
			face = {}
		end,
		end_face = function()
			local mode = #face == 3 and 'triangles' or #face == 4 and 'quads'
			if not mode then return end
			--if mode == 'triangles' then return end
			for _,group in ipairs(groups) do --add face indices to all current (group, mode, texture) combinations
				local slot = tuple(group, mode, texture)
				local t = combinations[slot]
				if not t then
					t = {}; combinations[slot] = t
				end
				glue.extend(t, face)
			end
			face = nil
		end,
		face_vtn = function(v,t,n)
			v = v and (v > 0 and v or #vertices/3 + v + 1)
			n = n and (n > 0 and n or #normals/3 + n + 1)
			t = t and (t > 0 and t or #texcoords/2 + t + 1)
			local vertex = tuple( --an ibo index will point to a unique v-t-n combination in the vbo
				check(vertices[v * 3 - 2]),
				check(vertices[v * 3 - 1]),
				check(vertices[v * 3]),
				n and check(normals[n * 3 - 2]) or 0,
				n and check(normals[n * 3 - 1]) or 0,
				n and check(normals[n * 3]) or 0,
				t and check(texcoords[t * 2 - 1]) or 0,
				t and check(texcoords[t * 2]) or 0
			)
			local i = vbo_indices[vertex]
			if not i then
				i = vbo_next_index; vbo_indices[vertex] = i
				glue.append(vbo_values, vertex())
				vbo_next_index = i + 1
			end
			face[#face+1] = i
		end,
		line = function(v,t)
			--TODO: line
		end,
		group = function(new_groups)
			groups = new_groups
		end,
		material = function(s)
			local material = check(materials[s])
			if material.map_kd then
				texture = textures[material]
				if not texture then
					texture = {type = 'image', file = {path = material.map_kd}}
					textures[material] = texture
				end
			end
		end,
		material_def = function(s, path)
			material = {}
			materials[s] = material
		end,
		material_attr = function(k,...)
			material[k] = select('#',...) > 1 and {...} or ...
		end,
		smoothing_group = function(enabled)
			--TODO: enable/disable computing of normals and compute normals
		end,
	})
	local vbo = {layout = 'vnt', values = vbo_values}
	local ibo = {values = {}}
	local ibo_partitions = {}
	for gmt, indices in pairs(combinations) do
		local group, mode, texture = gmt()
		ibo_partitions[#ibo_partitions+1] = {
			name = group,
			texture = texture,
			mode = mode,
			from = #ibo.values,
			count = #indices,
		}
		glue.extend(ibo.values, indices)
	end
	--print('vertices:', #vbo.values/8)
	--print('indices:', #ibo.values)
	--pp(ibo_partitions)

	if use_file_cache then
		--write vbo
		local data = ffi.new('float[?]', #vbo.values, vbo.values)
		local sz = ffi.sizeof(data)
		glue.writefile(file..'.vbo.tmp', ffi.string(data, sz))
		--write ibo
		local data = ffi.new(ibo_ctype(#ibo.values), #ibo.values, ibo.values)
		local sz = ffi.sizeof(data)
		glue.writefile(file..'.ibo.tmp', ffi.string(data, sz))
		--write partitions
		local pp = require'pp'
		pp.save(file..'.ibop.tmp', ibo_partitions)
	end

	return {
		type = 'mesh',
		vbo_v = vbo,
		vbo_n = vbo,
		vbo_t = vbo,
		ibo = ibo,
		ibo_partitions = ibo_partitions,
	}
end

if not ... then
--load'../media/obj/nexus2/nexus2.obj'
--load'../media/obj/cube/cube.obj'
--require'pp'(load'media/obj/greek_vase1/greek_vase.obj')
--require'sg_gl_demo'
end

return {
	load = load,
}
