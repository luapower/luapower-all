--wavefront obj callback-based parser.
local glue = require'glue'

local function readlines(file, callback)
	glue.fcall(function(finally)
		local f = assert(io.open(file, 'r'))
		finally(function() f:close() end)
		local line, line_str = 0, ''
		local function check(v, ...)
			if v then return v end
			local msg = ... and string.format(...)..'\n' or ''
			error(string.format('error reading file "%s", line %d, "%s"\n%s%s', file, line, line_str, msg, debug.traceback()), 2)
		end
		local more --lines ending with a backslash continue on the next line
		for s in f:lines() do
			line = line + 1
			if more then
				line_str = line_str..s
			else
				line_str = s
			end
			if s:find'\\$' then
				more = true
			else
				more = false
				callback(s, check)
			end
		end
	end)
end

local map_cmds = glue.index{
	'map_ka',    -- the ambient texture map
	'map_kd',    -- the diffuse texture map (most of the time, it will be the same as the ambient texture map)
	'map_ks',    -- specular color texture map
	'map_ns',    -- specular highlight component
	'map_d',     -- the alpha texture map
	'map_bump',  -- some implementations use 'map_bump' instead of 'bump' below
	'bump',      -- bump map (which by default uses luminance channel of the image)
	'disp',      -- displacement map
	'decal',     -- stencil decal texture (defaults to 'matte' channel of the image)
}

local function parse(file, handlers)
	readlines(file, function(s, check)
		handlers.check_function(check)
		local cmd, s = s:match'^%s*(%S+) +(.*)'
		cmd = cmd and cmd:lower()
		if not cmd or cmd == '#' then
			--comment or empty line
		elseif cmd == 'v' then
			local x,y,z = s:match'^(%S+) +(%S+) +(%S+)'
			x,y,z = check(tonumber(x)), check(tonumber(y)), check(tonumber(z))
			handlers.vertex(x,y,z)
		elseif cmd == 'vn' then
			local x,y,z = s:match'^(%S+) +(%S+) +(%S+)'
			x,y,z = check(tonumber(x)), check(tonumber(y)), check(tonumber(z))
			handlers.normal(x,y,z)
		elseif cmd == 'vt' then
			local u,v,w = s:match'^(%S+) *(%S*) *(.*)'
			u = check(tonumber(u))
			v = v ~= '' and check(tonumber(v)) or 0
			w = w ~= '' and check(tonumber(w)) or 0
			handlers.texcoord(u,v,w)
		elseif cmd == 'f' then
			handlers.start_face()
			for c in s:gmatch'(%S+)' do
				local v,t,n = c:match'^([^/]+)/?([^/]*)/?([^/]*)'
				v = check(tonumber(v))
				t = t ~= '' and check(tonumber(t)) or nil
				n = n ~= '' and check(tonumber(n)) or nil
				handlers.face_vtn(v,t,n)
			end
			handlers.end_face()
		elseif cmd == 'l' then
			for c in s:gmatch'(%S+)' do
				local v,t = c:match'^([^/]+)/?([^/]*)'
				v = check(tonumber(v))
				t = t ~= '' and check(tonumber(t)) or nil
				handlers.line(v,t)
			end
		elseif cmd == 'mtllib' then
			local dir = file:match'^(.*[\\/])[^\\/]+$' or ''
			readlines(dir..s, function(s, check)
				local cmd, s = s:match'^%s*(%S+) +(.*)'
				cmd = cmd and cmd:lower()
				if cmd == 'newmtl' then
					handlers.material_def(s)
				elseif cmd == 'ka' or cmd == 'kd' or cmd == 'ks' then
					local r,g,b = s:match'^(%S+) +(%S+) +(%S+)'
					r,g,b = check(tonumber(r)), check(tonumber(g)), check(tonumber(b))
					handlers.material_attr(cmd, r, g, b)
				elseif cmd == 'illum' or cmd == 'ns' or cmd == 'd' or cmd == 'tr' then
					handlers.material_attr(cmd, check(tonumber(s)))
				elseif map_cmds[cmd] then
					handlers.material_attr(cmd, dir..s)
				end
			end)
		elseif cmd == 'usemtl' then
			handlers.material(s)
		elseif cmd == 'g' then
			handlers.group(glue.collect(s:gmatch'(%S+)'))
		elseif cmd == 's' then
			handlers.smoothing_group((s ~= 'off' and s ~= '0') and check(tonumber(s)))
		end
	end)
end

if not ... then require'sg_gl_demo' end

return parse

