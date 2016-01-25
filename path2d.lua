--2D paths in Lua (Cosmin Apreutesei, public domain).
--supports lines, with horiz. and vert. variations, quadratic beziers and cubic beziers, with smooth
--and symmetrical variations, absolute and relative variations for all commands, circular arcs, 3-point circular arcs,
--svg-style elliptical arcs, text, and many composite shapes.
--supports affine transforms, bounding box, length, shortest-distance-to-point, splitting, editing, etc.

if not ... then require'path2d_demo'; return end

local glue = require'glue' --update, shift, index, append

local reflect_point                = require'path2d_point'.reflect_point
local reflect_point_distance       = require'path2d_point'.reflect_point_distance
local bezier2_3point_control_point = require'path2d_bezier2'._3point_control_point
local arc_endpoints                = require'path2d_arc'.endpoints
local arc_tangent_vector           = require'path2d_arc'.tangent_vector
local svgarc_to_arc                = require'path2d_svgarc'.to_arc
local arc3p_to_arc                 = require'path2d_arc_3p'.to_arc
local circle_3p_to_circle          = require'path2d_circle_3p'.to_circle

local assert, unpack, select =
	   assert, unpack, select

--path command iteration -------------------------------------------------------------------------------------------------

local argc = {
	--control commands
	move = 2,                       --x2, y2
	close = 0,
	--lines and curves
	line = 2,                       --x2, y2
	hline = 1,                      --x2
	vline = 1,                      --y2
	curve = 6,                      --x2, y2, x3, y3, x4, y4
	symm_curve = 4,                 --x3, y3, x4, y4
	smooth_curve = 5,               --len, x3, y3, x4, y4
	quad_curve = 4,                 --x2, y2, x3, y3
	quad_curve_3p = 4,              --xp, yp, x3, y3
	symm_quad_curve = 2,            --x3, y3
	smooth_quad_curve = 3,          --len, x3, y3
	--arcs
	arc = 5,                        --cx, cy, r, start_angle, sweep_angle
	line_arc = 5,                   --cx, cy, r, start_angle, sweep_angle
	elliptic_arc = 7,               --cx, cy, rx, ry, start_angle, sweep_angle, rotation
	line_elliptic_arc = 7,          --cx, cy, rx, ry, start_angle, sweep_angle, rotation
	arc_3p = 4,                     --xp, yp, x3, y3
	svgarc = 7,                     --rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2
	--closed shapes
	circle = 3,                     --cx, cy, r
	circle_3p = 6,                  --xp, yp, x3, y3
	ellipse = 5,                    --cx, cy, rx, ry, rotation
	rect = 4,                       --x, y, w, h
	round_rect = 5,                 --x, y, w, h, r
	elliptic_rect = 6,              --x, y, w, h, rx, ry
	star = 6,                       --cx, cy, x1, y1, r2, n
	star_2p = 7,                    --cx, cy, x1, y1, x2, y2, n
	rpoly = 5,                      --cx, cy, x1, y1, n
	superformula = 11,              --cx, cy, size, steps, rotation, a, b, m, n1, n2, n3
	--text
	text = 4,                       --x, y, {[family=s], [size=n]}, text
}

--helper function to mirror all keys in t with rel_* keys.
local function rel_variations(t)
	local rt = {}
	for k,v in pairs(t) do
		rt['rel_'..k] = v
	end
	return rt
end

--all commands have relative-to-current-point counterparts with the same number of arguments.
glue.update(argc, rel_variations(argc))

--given an index in a path pointing at a command string (we'll call that a command index),
--return the index of the next command and the command name.
local function next_cmd(path, i)
	i = i and i + assert(argc[path[i]], 'invalid command') + 1 or 1
	if i > #path then return end
	return i, path[i]
end

--iterate over path commands retreiving the command index and the command name.
local function commands(path, last_index)
	return next_cmd, path, last_index
end

--given a command index, unpack the command and its args.
local function cmd(path, i)
	return unpack(path, i, i+assert(argc[path[i]], 'invalid command'))
end

--given a command index, return the index of the prev. command and the command name.
local function prev_cmd(path, target_index)
	if target_index == 1 then return end
	for i,s in commands(path) do
		if next_cmd(path,i) == target_index then
			return i,s
		end
	end
	error'invalid path index'
end

--adding, replacing and removing path commands ---------------------------------------------------------------------------

local table_shift = glue.shift

--update table elements at i in place.
local function table_update(dt, i, ...)
	for k=1,select('#',...) do
		dt[i+k-1] = select(k,...)
	end
end

--append command.
local function append_cmd(path, s, ...)
	local n = select('#', ...)
	assert(n == argc[s], 'wrong argument count')
	table_update(path, #path+1, s, ...)
end

--insert command at index i, shifting elemetns as needed. if i is nil, append the command instead.
local function insert_cmd(path, i, s, ...)
	if not i then
		append_cmd(path, s, ...)
		return
	end
	local n = select('#', ...)
	assert(n == argc[s], 'wrong argument count')
	table_shift(path, i, 1 + n)
	table_update(path, i, s, ...)
end

--replace command at index i with a new command and args, shifting elements as needed.
local function replace_cmd(path, i, s, ...)
	local old = argc[path[i]]
	local new = select('#', ...)
	assert(new == argc[s], 'wrong argument count')
	table_shift(path, i+1, new-old)
	table_update(path, i, s, ...)
end

--remove command at i, shifting elements as needed.
local function remove_cmd(path, i)
	table_shift(path, i, - (1 + argc[path[i]]))
end

--update table elements at i in place with the contents of another table.
local function table_update_table(dt, i, t)
	for k=1,#t do
		dt[i+k-1] = t[k]
	end
end

local function replace_cmd_t(path, i, s, t)
	local old = argc[path[i]]
	local new = #t
	table_shift(path, i+1, new-old)
	table_update_table(path, i, t)
end

--path command decoding: absolute and relative commands ------------------------------------------------------------------

local abs_names = {}
local rel_names = {}
for s in pairs(argc) do
	abs_names[s] = s:match'^rel_(.*)' or s
	rel_names[s] = s:match'^rel_' and s or 'rel_'..s
end

local function is_rel(s) --check if the command is rel. or abs.
	return rel_names[s] == s
end

local function abs_name(s) --return the abs. variant for any command, be it abs. or rel.
	return abs_names[s]
end

local function rel_name(s) --return the rel. variant for any command, be it abs. or rel.
	return rel_names[s]
end

--commands that start with a point and that point is the only argument that can be abs. or rel.
local only_x1y1 = glue.index{'arc', 'elliptic_arc', 'line_arc', 'line_elliptic_arc',
										'rect', 'round_rect', 'elliptic_rect', 'ellipse',
										'circle', 'superformula', 'text'}

--given a point and an unpacked command and its args, return the args with the point added to them.
local function translate_cmd(cpx, cpy, s, ...)
	assert(cpx and cpy, 'no current point')
	s = abs_name(s)
	if s == 'move' or s == 'line' then
		local x2, y2 = ...
		return cpx + x2, cpy + y2
	elseif s == 'close' then
		return
	elseif s == 'hline' then
		return cpx + ...
	elseif s == 'vline' then
		return cpy + ...
	elseif s == 'curve' then
		local x2, y2, x3, y3, x4, y4 = ...
		return cpx + x2, cpy + y2, cpx + x3, cpy + y3, cpx + x4, cpy + y4
	elseif s == 'symm_curve' then
		local x3, y3, x4, y4 = ...
		return cpx + x3, cpy + y3, cpx + x4, cpy + y4
	elseif s == 'smooth_curve' then
		local len, x3, y3, x4, y4 = ...
		return len, cpx + x3, cpy + y3, cpx + x4, cpy + y4
	elseif s == 'quad_curve' or s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		return cpx + x2, cpy + y2, cpx + x3, cpy + y3
	elseif s == 'symm_quad_curve' then
		local x3, y3 = ...
		return cpx + x3, cpy + y3
	elseif s == 'smooth_quad_curve' then
		local len, x3, y3 = ...
		return len, cpx + x3, cpy + y3
	elseif s == 'arc_3p' then
		local xp, yp, x2, y2 = ...
		return cpx + xp, cpy + yp, cpx + x2, cpy + y2
	elseif s == 'circle_3p' then
		local x1, y1, x2, y2, x3, y3 = ...
		return cpx + x1, cpy + y1, cpx + x2, cpy + y2, cpx + x3, cpy + y3
	elseif s == 'svgarc' then
		local rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2 = ...
		return rx, ry, rotation, large_arc_flag, sweep_flag, cpx + x2, cpy + y2
	elseif only_x1y1[s] then
		local x, y = ...
		return cpx + x, cpy + y, select(3, ...)
	elseif s == 'star' then
		local cx, cy, x1, y1, r2, n = ...
		return cpx + cx, cpy + cy, cpx + x1, cpy + y1, r2, n
	elseif s == 'star_2p' then
		local cx, cy, x1, y1, x2, y2, n = ...
		return cpx + cx, cpy + cy, cpx + x1, cpy + y1, cpx + x2, cpy + y2, n
	elseif s == 'rpoly' then
		local cx, cy, x1, y1, n = ...
		return cpx + cx, cpy + cy, cpx + x1, cpy + y1, n
	elseif s == 'text' then
		local x, y, font, text = ...
		return cpx + x, cpy + y, font, text
	else
		error'invalid command'
	end
end

--given current point and an unpacked command and its args, return the command in absolute form.
local function abs_cmd(cpx, cpy, s, ...)
	if not is_rel(s) then return s, ... end
	return abs_name(s), translate_cmd(cpx, cpy, s, ...)
end

--given current point and an unpacked command and its args, return the command in relative form.
local function rel_cmd(cpx, cpy, s, ...)
	if is_rel(s) then return s, ... end
	return rel_name(s), translate_cmd(-cpx, -cpy, s, ...)
end

--adding, replacing and removing path commands, in relative or absolute form ---------------------------------------------

--given a rel. or abs. command name and its args in abs. form, encode the command as relative if the name is relative.
local function to_rel(cpx, cpy, s, ...)
	if not is_rel(s) then return s, ... end
	return s, translate_cmd(-cpx, -cpy, s, ...)
end

local function append_rel_cmd(path, cpx, cpy, s, ...)
	append_cmd(path, to_rel(cpx, cpy, s, ...))
end

local function insert_rel_cmd(path, i, cpx, cpy, s, ...)
	insert_cmd(path, i, to_rel(cpx, cpy, s, ...))
end

local function replace_rel_cmd(path, i, cpx, cpy, s, ...)
	replace_cmd(path, i, to_rel(cpx, cpy, s, ...))
end

--path command decoding: advancing the current point ---------------------------------------------------------------------

--given current command in abs. form and current cp info, return the cp info of the next path command.
--cpx, cpy is the next "current point" or pen point, needed by all relative commands and by most other commands.
--spx, spy is the starting point of the current subpath, needed by the "close" command.
--note: closed composite shapes don't change the current point.
local function next_cp(cpx, cpy, spx, spy, s, ...)
	if s == 'move' then
		cpx, cpy = ...
		spx, spy = ...
	elseif s == 'line' then
		cpx, cpy = ...
	elseif s == 'close' then
		cpx, cpy = spx, spy
	elseif s == 'hline' then
		cpx = ...
	elseif s == 'vline' then
		cpy = ...
	elseif s == 'curve' then
		cpx, cpy = select(5, ...)
	elseif s == 'symm_curve' then
		cpx, cpy = select(3, ...)
	elseif s == 'smooth_curve' then
		cpx, cpy = select(4, ...)
	elseif s == 'quad_curve' then
		cpx, cpy = select(3, ...)
	elseif s == 'quad_curve_3p' then
		cpx, cpy = select(3, ...)
	elseif s == 'symm_quad_curve' then
		cpx, cpy = ...
	elseif s == 'smooth_quad_curve' then
		cpx, cpy = select(2, ...)
	elseif s == 'arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		spx, spy, cpx, cpy = arc_endpoints(cx, cy, r, r, start_angle, sweep_angle)
	elseif s == 'line_arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		cpx, cpy = select(3, arc_endpoints(cx, cy, r, r, start_angle, sweep_angle))
	elseif s == 'elliptic_arc' then
		spx, spy, cpx, cpy = arc_endpoints(...)
	elseif s == 'line_elliptic_arc' then
		cpx, cpy = select(3, arc_endpoints(...))
	elseif s == 'arc_3p' then
		cpx, cpy = select(3, ...)
	elseif s == 'svgarc' then
		cpx, cpy = select(6, ...)
	end
	return cpx, cpy, spx, spy
end

--return the "current point" at an arbitrary command index, and the current point of the subpath
--of which the command is part of, which we'll call the "starting point".
local function cp_at(path, target_index)
	local cpx, cpy, spx, spy
	for i,s in commands(path) do
		if i == target_index then
			return cpx, cpy, spx, spy
		end
		cpx, cpy, spx, spy =
			next_cp(cpx, cpy, spx, spy,
			abs_cmd(cpx, cpy,
				 cmd(path, i)))
	end
	error'invalid path index'
end

--path command decoding: computing the tangent vector at command endpoint ------------------------------------------------

--given current command in abs. form and current control point, return the tip of the tangent vector at command endpoint.
--tkind is 'quad', 'cubic' or 'tangent'. a symm_curve can only use a cubic tip, a symm_quad_curve can only use a quad tip.
--smooth curves can use any kind of tip as they only use the vector's angle, neverminding its length.
--all (and only) commands that leave a current point leave a tangent point, except 'move'.
--TODO: svgarc_to_arc() is expensive and yet it's called twice, once in tangent_tip() then again in
--			simple_cmd(). find a nice way to reuse the results instead of calling it twice.
local function tangent_tip(cpx, cpy, tkind, tx, ty, s, ...)
	if s == 'line' then
		return 'tangent', cpx, cpy
	elseif s == 'curve' then
		local tx, ty = select(3, ...)
		return 'cubic', tx, ty
	elseif s == 'symm_curve' then
		local tx, ty = ...
		return 'cubic', tx, ty
	elseif s == 'smooth_curve' then
		local tx, ty = select(2, ...)
		return 'cubic', tx, ty
	elseif s == 'quad_curve' then
		local tx, ty = ...
		return 'quad', tx, ty
	elseif s == 'quad_curve_3p' then
		return 'quad', bezier2_3point_control_point(cpx, cpy, ...)
	elseif s == 'symm_quad_curve' then
		return 'quad', reflect_point(tkind == 'quad' and tx or cpx, tkind == 'quad' and ty or cpy, cpx, cpy)
	elseif s == 'smooth_quad_curve' then
		return 'quad', reflect_point_distance(tx or cpx, ty or cpy, cpx, cpy, (...))
	elseif s == 'arc' or s == 'line_arc' then
		local cx, cy, r, start_angle, sweep_angle, x2, y2 = ...
		return 'tangent', select(3, arc_tangent_vector(1, cx, cy, r, r, start_angle, sweep_angle, x2, y2))
	elseif s == 'elliptic_arc' or s == 'line_elliptic_arc' then
		return 'tangent', select(3, arc_tangent_vector(1, ...))
	elseif s == 'svgarc' then
		local cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2 = svgarc_to_arc(cpx, cpy, ...)
		if not cx then --invalid parametrization, arc is a line
			return 'tangent', cpx, cpy
		else
			return 'tangent', select(3, arc_tangent_vector(1,
													cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2))
		end
	elseif s == 'arc_3p' then
		local xp, yp, x2, y2 = ...
		local cx, cy, rx, ry, start_angle, sweep_angle, x2, y2 = arc3p_to_arc(cpx, cpy, xp, yp, x2, y2)
		if not cx then --invalid parametrization, arc is a line
			return 'tangent', cpx, cpy
		else
			return 'tangent', select(3, arc_tangent_vector(1, cx, cy, rx, ry, start_angle, sweep_angle, x2, y2))
		end
	end
end

--path command decoding: advancing the command state ---------------------------------------------------------------------

local function next_state(cpx, cpy, spx, spy, tkind, tx, ty, s, ...)
	tkind, tx, ty = tangent_tip(cpx, cpy, tkind, tx, ty, s, ...)
	cpx, cpy, spx, spy = next_cp(cpx, cpy, spx, spy, s, ...)
	return cpx, cpy, spx, spy, tkind, tx, ty
end

--return the state of the path command at an arbitrary command index.
--TODO: avoid calling tangent_tip() if current cmd is *svgarc and next cmd is not *smooth_*.
local function state_at(path, target_index)
	local cpx, cpy, spx, spy, tkind, tx, ty
	for i,s in commands(path) do
		if i == target_index then
			return cpx, cpy, spx, spy, tkind, tx, ty
		end
		cpx, cpy, spx, spy, tkind, tx, ty =
			next_state(cpx, cpy, spx, spy, tkind, tx, ty,
				abs_cmd(cpx, cpy,
					 cmd(path, i)))
	end
	error'invalid path index'
end

--path command decoding: state + command = context-free command ----------------------------------------------------------

--given current state and an abs. cmd, if it's a smooth or symm. curve, return it as a cusp curve, decontextualizing it.
local function to_cusp(cpx, cpy, tkind, tx, ty, s, ...)
	if s == 'symm_curve' then
		local x2, y2 = reflect_point(tkind == 'cubic' and tx or cpx, tkind == 'cubic' and ty or cpy, cpx, cpy)
		return 'curve', x2, y2, ...
	elseif s == 'smooth_curve' then
		local x2, y2 = reflect_point_distance(tx or cpx, ty or cpy, cpx, cpy, (...))
		return 'curve', x2, y2, select(2, ...)
	elseif s == 'symm_quad_curve' then
		local x2, y2 = reflect_point(tkind == 'quad' and tx or cpx, tkind == 'quad' and ty or cpy, cpx, cpy)
		return 'quad_curve', x2, y2, ...
	elseif s == 'smooth_quad_curve' then
		local x2, y2 = reflect_point_distance(tx or cpx, ty or cpy, cpx, cpy, (...))
		return 'quad_curve', x2, y2, select(2, ...)
	else
		return s, ...
	end
end

--given a command in abs. form and current state, return the command in simplified context-free form,
--prepending the current point, removing line, curve and arc variations, and dealing with invalid parametrization.
--'carc' means canonical arc, which is an elliptic arc optionally connected to the path by a line.
local function simple_cmd(cpx, cpy, spx, spy, tkind, tx, ty, s, ...)
	if s == 'move' then
		return s, ...
	elseif s == 'line' or s == 'curve' or s == 'quad_curve' then
		return s, cpx, cpy, ...
	elseif s == 'close' then
		return s, cpx, cpy, spx, spy
	elseif s == 'hline' then
		return 'line', cpx, cpy, ..., cpy
	elseif s == 'vline' then
		return 'line', cpx, cpy, cpx, ...
	elseif s == 'symm_curve' or s == 'smooth_curve' then
		return 'curve', cpx, cpy, select(2, to_cusp(cpx, cpy, tkind, tx, ty, s, ...))
	elseif s == 'symm_quad_curve' or s == 'smooth_quad_curve' then
		return 'quad_curve', cpx, cpy, select(2, to_cusp(cpx, cpy, tkind, tx, ty, s, ...))
	elseif s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		local x2, y2 = bezier2_3point_control_point(cpx, cpy, x2, y2, x3, y3)
		return 'quad_curve', cpx, cpy, x2, y2, x3, y3
	elseif s == 'arc_3p' then
		local xp, yp, x2, y2 = ...
		local cx, cy, rx, ry, start_angle, sweep_angle = arc3p_to_arc(cpx, cpy, xp, yp, x2, y2)
		if not cx then --invalid parametrization, arc is a line
			return 'line', cpx, cpy, x2, y2
		end
		return 'carc', cpx, cpy, nil, cx, cy, rx, ry, start_angle, sweep_angle, 0, x2, y2
	elseif s == 'svgarc' then
		local cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2 = svgarc_to_arc(cpx, cpy, ...)
		if not cx then --invalid parametrization, arc is a line
			return 'line', cpx, cpy, select(6, ...)
		end
		return 'carc', cpx, cpy, nil, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2
	elseif s == 'arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		return 'carc', cpx, cpy, 'move', cx, cy, r, r, start_angle, sweep_angle, 0
	elseif s == 'line_arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		return 'carc', cpx, cpy, 'line', cx, cy, r, r, start_angle, sweep_angle, 0
	elseif s == 'elliptic_arc' then
		return 'carc', cpx, cpy, 'move', ...
	elseif s == 'line_elliptic_arc' then
		return 'carc', cpx, cpy, 'line', ...
	elseif s == 'circle' then
		local cx, cy, r = ...
		return 'ellipse', cx, cy, r, r, 0
	elseif s == 'circle_3p' then
		local cx, cy, r = circle_3p_to_circle(...)
		if not cx then --invalid parametrization, circle has zero radius
			cx, cy, r = 0, 0, 0
		end
		return 'ellipse', cx, cy, r, r, 0
	else --other commands are already in context-free canonical form.
		return s, ...
	end
end

--path command decoding: decode paths and path command streams -----------------------------------------------------------

--given an abs. path command and current state, decode it and pass it to a processor function and then
--return the next state. the processor will usually write its output using the supplied write function.
local function decode_cmd(process, write, mt, i, cpx, cpy, spx, spy, tkind, tx, ty, s, ...)
	process(write, mt, i, simple_cmd(cpx, cpy, spx, spy, tkind, tx, ty, s, ...))
	return next_state(cpx, cpy, spx, spy, tkind, tx, ty, s, ...)
end

--decode a path and process each command using a processor function.
--state is optional and can be used for concatenating paths.
local function decode_path(process, write, path, mt, cpx, cpy, spx, spy, tkind, tx, ty)
	for i,s in commands(path) do
		cpx, cpy, spx, spy, tkind, tx, ty =
				 decode_cmd(process, write, mt, i, cpx, cpy, spx, spy, tkind, tx, ty,
					 abs_cmd(cpx, cpy,
						  cmd(path, i)))
	end
	return cpx, cpy, spx, spy, tkind, tx, ty
end

--return a decoder function that decodes and processes an arbitrary path command every time it is called, preserving
--and advancing the state between calls. also returns a function for retrieving the state after the last call.
local function command_decoder(process, write, mt, i, cpx, cpy, spx, spy, tkind, tx, ty)
	return function(s, ...)
		cpx, cpy, spx, spy, tkind, tx, ty =
				 decode_cmd(process, write, mt, i, cpx, cpy, spx, spy, tkind, tx, ty,
					 abs_cmd(cpx, cpy, s, ...))
	end, function()
		return cpx, cpy, spx, spy, tkind, tx, ty
	end
end

--point transform helper -------------------------------------------------------------------------------------------------

local function transform_points(mt, ...)
	if not mt then return ... end
	local n = select('#', ...)
	if n == 2 then
		return mt(...)
	elseif n == 4 then
		local x1, y1, x2, y2 = ...
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
		return x1, y1, x2, y2
	elseif n == 6 then
		local x1, y1, x2, y2, x3, y3 = ...
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
		x3, y3 = mt(x3, y3)
		return x1, y1, x2, y2, x3, y3
	elseif n == 8 then
		local x1, y1, x2, y2, x3, y3, x4, y4 = ...
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
		x3, y3 = mt(x3, y3)
		x4, y4 = mt(x4, y4)
		return x1, y1, x2, y2, x3, y3, x4, y4
	end
	assert(false)
end

--path decomposition -----------------------------------------------------------------------------------------------------

local decompose = {}

--the processor function for path decomposition.
local function decompose_processor(write, mt, i, s, ...)
	decompose[s](write, mt, ...)
end

--given a path and optionally a transformation matrix, decompose a path into primitive commands.
--primitive commands are: move, close, line, curve, quad_curve.
local function decompose_path(write, path, mt)
	decode_path(decompose_processor, write, path, mt)
end

function decompose.move(write, mt, x2, y2)
	write('move', transform_points(mt, x2, y2))
end

function decompose.close(write, mt, cpx, cpy, spx, spy)
	if cpx ~= spx or cpy ~= spy then
		write('line', transform_points(mt, spx, spy))
	end
	write('close')
end

function decompose.line(write, mt, x1, y1, x2, y2)
	write('line', transform_points(mt, x2, y2))
end

function decompose.quad_curve(write, mt, x1, y1, x2, y2, x3, y3)
	write('quad_curve', transform_points(mt, x2, y2, x3, y3))
end

function decompose.curve(write, mt, x1, y1, x2, y2, x3, y3, x4, y4)
	write('curve', transform_points(mt, x2, y2, x3, y3, x4, y4))
end

local arc_to_bezier3 = require'path2d_arc'.to_bezier3

function decompose.carc(write, mt, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if connect then
		local x1, y1 = arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		write(connect, x1, y1)
	end
	arc_to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
end

--note: if rx * ry is negative, the ellipse is drawn counterclockwise.
function decompose.ellipse(write, mt, cx, cy, rx, ry, rotation)
	if rx == 0 or ry == 0 then return end --invalid parametrization, skip it
	local sweep_angle = rx*ry >= 0 and 360 or -360
	local x1, y1 = arc_endpoints(cx, cy, rx, ry, 0, sweep_angle, rotation)
	write('move', transform_points(mt, x1, y1))
	arc_to_bezier3(write, cx, cy, rx, ry, 0, sweep_angle, rotation, x1, y1, mt)
	write('close')
end

local rect_to_lines = require'path2d_shapes'.rect_to_lines

function decompose.rect(write, mt, x1, y1, w, h)
	rect_to_lines(write, x1, y1, w, h, mt)
end

--these shapes can draw themselves but can't transform themselves so we must write custom decomposers for them.
--shapes can draw themselves using only primitive commands, starting in an empty state.
--the ability to draw composites using arbitrary path commands can be enabled in the code below (see comments).
local decompose_no_transform = {
	round_rect    = require'path2d_shapes'.round_rect_to_bezier3,
	elliptic_rect = require'path2d_shapes'.elliptic_rect_to_bezier3,
	star          = require'path2d_shapes'.star_to_lines,
	star_2p       = require'path2d_shapes'.star_2p_to_lines,
	rpoly         = require'path2d_shapes'.rpoly_to_lines,
	superformula  = require'path2d_shapes'.superformula_to_lines,
	text          = require'path2d_text'.to_bezier3,
}

for s,decompose_nt in pairs(decompose_no_transform) do
	decompose[s] = function(write, mt, ...)
		if not mt then
			--we know that composite commands draw themselves with only primitive commands so we write them directly.
			--if composite commands could have written other types of commands, we would not have had this branch.
			decompose_nt(write, ...)
		else
			--we use decomposition only to transform the points, we know we're only dealing with primitive commands.
			--note: composite commands don't need a state to start with, and they don't leave any state behind.
			--we can't access the initial state from here anyway, and we can't return the final state either.
			local decoder = command_decoder(decompose_processor, write, mt)
			decompose_nt(decoder, ...)
		end
	end
end

function decompose.text(write, mt, x, y, font, text)
	--write('text', x, y, font, text)
end

--recursive path decoding ------------------------------------------------------------------------------------------------

--decode a path and process its commands using a conditional processor. the processor will be tried for each command.
--for commands for which the processor returns false, decompose the command and then process the resulted segments.
--processors for primitive commands must never return false otherwise infinite recursion occurs.
local function decode_recursive(process, write, path, mt)
	local cpx, cpy, spx, spy, tkind, tx, ty

	local function recursive_processor(write, mt, i, s, ...)
		if process(write, mt, i, s, ...) == false then
			local decoder = command_decoder(recursive_processor, write, mt, i, cpx, cpy, spx, spy, tkind, tx, ty)
			decompose_processor(decoder, nil, i, s, ...)
		end
	end

	for i,s in commands(path) do
		cpx, cpy, spx, spy, tkind, tx, ty =
			 decode_cmd(recursive_processor, write, mt, i, cpx, cpy, spx, spy, tkind, tx, ty,
				 abs_cmd(cpx, cpy,
					  cmd(path, i)))
	end
end

--path bounding box ------------------------------------------------------------------------------------------------------

local bbox = {}

local function bbox_processor(write, mt, i, s, ...)
	if not bbox[s] then return false end
	return bbox[s](write, mt, ...)
end

local min, max = math.min, math.max
local function path_bbox(path, mt)
	local straight = not mt or mt:is_straight()
	local x1, y1, x2, y2 = 1/0, 1/0, -1/0, -1/0
	local function write(x, y, w, h)
		local ax1, ay1, ax2, ay2 = x, y, x+w, y+h

		if mt and straight then
			ax1, ay1 = mt(ax1, ay1)
			ax2, ay2 = mt(ax2, ay2)
		end

		x1 = min(x1, ax1, ax2)
		y1 = min(y1, ay1, ay2)
		x2 = max(x2, ax1, ax2)
		y2 = max(y2, ay1, ay2)
	end
	decode_recursive(bbox_processor, write, path, not straight and mt or nil)
	if x1 == 1/0 then return 0, 0, 0, 0 end
	return x1, y1, x2-x1, y2-y1
end

local line_bbox       = require'path2d_line'.bounding_box
local curve_bbox      = require'path2d_bezier3'.bounding_box
local quad_curve_bbox = require'path2d_bezier2'.bounding_box
local arc_bbox        = require'path2d_arc'.bounding_box
local ellipse_bbox    = require'path2d_shapes'.ellipse_bbox
local rect_bbox       = require'path2d_shapes'.rect_bbox

function bbox.move() end

function bbox.line(write, mt, x1, y1, x2, y2)
	write(line_bbox(transform_points(mt, x1, y1, x2, y2)))
end

bbox.close = bbox.line

function bbox.curve(write, mt, x1, y1, x2, y2, x3, y3, x4, y4)
	write(curve_bbox(transform_points(mt, x1, y1, x2, y2, x3, y3, x4, y4)))
end

function bbox.quad_curve(write, mt, x1, y1, x2, y2, x3, y3)
	write(quad_curve_bbox(transform_points(mt, x1, y1, x2, y2, x3, y3)))
end

function bbox.carc(write, mt, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if mt or rx ~= ry or rotation ~= 0 then return false end
	if connect == 'line' then
		local x1, y1 = arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
		write(line_bbox(cpx, cpy, x1, y1))
	end
	write(arc_bbox(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2))
end

function bbox.ellipse(write, mt, cx, cy, rx, ry, rotation)
	if mt or rotation ~= 0 then return false end
	write(ellipse_bbox(cx, cy, rx, ry))
end

function bbox.rect(write, mt, x, y, w, h)
	if mt then return false end
	write(rect_bbox(x, y, w, h))
end

bbox.round_rect = bbox.rect
bbox.elliptic_rect = bbox.rect

function bbox.text()
	return false
end

--path length ------------------------------------------------------------------------------------------------------------

local len = {}

local function len_processor(write, mt, i, s, ...)
	if not len[s] then return false end
	return len[s](write, mt, ...)
end
local function path_length(path, mt)
	local total = 0
	local function write(len)
		total = total + len
	end
	decode_recursive(len_processor, write, path, mt and not mt:has_unity_scale() and mt or nil)
	return total
end

local line_len       = require'path2d_line'.length
local quad_curve_len = require'path2d_bezier2'.length
local curve_len      = require'path2d_bezier3'.length
local arc_len        = require'path2d_arc'.length
local circle_len     = require'path2d_shapes'.circle_length
local rect_len       = require'path2d_shapes'.rect_length
local round_rect_len = require'path2d_shapes'.round_rect_length

function len.move() end

function len.line(write, mt, x1, y1, x2, y2)
	write(line_len(1, transform_points(mt, x1, y1, x2, y2)))
end

len.close = len.line

function len.curve(write, mt, x1, y1, x2, y2, x3, y3, x4, y4)
	write(curve_len(1, transform_points(mt, x1, y1, x2, y2, x3, y3, x4, y4)))
end

function len.quad_curve(write, mt, x1, y1, x2, y2, x3, y3)
	write(quad_curve_len(1, transform_points(mt, x1, y1, x2, y2, x3, y3)))
end

function len.carc(write, mt, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if connect == 'line' then
		local x1, y1 = arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
		if mt then
			cpx, cpy = mt(cpx, cpy)
			x1, y1 = mt(x1, y1)
		end
		write(line_len(1, cpx, cpy, x1, y1))
	end
	write(arc_len(1, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2))
end

function len.ellipse(write, mt, cx, cy, rx, ry)
	if mt or rx ~= ry then return false end
	write(circle_len(cx, cy, rx))
end

function len.rect(write, mt, x, y, w, h)
	if mt then return false end
	write(rect_len(x, y, w, h))
end

function len.round_rect(write, mt, x, y, w, h, r)
	if mt then return false end
	write(round_rect_len(x, y, w, h, r))
end

function len.text()
	return false
end

--path hit ---------------------------------------------------------------------------------------------------------------

local ht = {}

local function hit_path(x0, y0, path, mt)
	local mi, md, mx, my, mt_
	local function write(i, d, x, y, t)
		if not md or d < md then
			mi, md, mx, my, mt_ = i, d, x, y, t
		end
	end
	local function hit_processor(write, mt, i, s, ...)
		if not ht[s] then
			return false --signal decoder to recurse.
		end
		return ht[s](write, mt, i, x0, y0, ...)
	end
	decode_recursive(hit_processor, write, path, mt)
	return md, mx, my, mi, mt_
end

local distance2        = require'path2d_point'.distance2
local line_hit         = require'path2d_line'.hit
local quad_curve_hit   = require'path2d_bezier2'.hit
local curve_hit        = require'path2d_bezier3'.hit
local arc_hit          = require'path2d_arc'.hit

function ht.move(write, mt, i, x0, y0, x2, y2)
	x2, y2 = transform_points(mt, x2, y2)
	write(i, distance2(x0, y0, x2, y2), x2, y2, 0)
end

function ht.line(write, mt, i, x0, y0, x1, y1, x2, y2)
	write(i, line_hit(x0, y0, transform_points(mt, x1, y1, x2, y2)))
end

ht.close = ht.line

function ht.curve(write, mt, i, x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)
	write(i, curve_hit(x0, y0, transform_points(mt, x1, y1, x2, y2, x3, y3, x4, y4)))
end

function ht.quad_curve(write, mt, i, x0, y0, x1, y1, x2, y2, x3, y3)
	write(i, quad_curve_hit(x0, y0, transform_points(mt, x1, y1, x2, y2, x3, y3)))
end

function ht.carc(write, mt, i, x0, y0, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if connect == 'line' then
		local x1, y1 = arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		if mt then cpx, cpy = mt(cpx, cpy) end
		local d, x, y, t = line_hit(x0, y0, cpx, cpy, x1, y1)
		write(i, d, x, y, t/2)
		local d, x, y, t = arc_hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		write(i, d, x, y, 0.5 + t/2)
	else
		write(i, arc_hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt))
	end
end

function ht.text()
	return false
end

--path split -------------------------------------------------------------------------------------------------------------

local line_split       = require'path2d_line'.split
local quad_curve_split = require'path2d_bezier2'.split
local curve_split      = require'path2d_bezier3'.split

local split = {}

function split.line(path, i, t, s, rs, cpx, cpy, ...)
	local x, y = select(3, line_split(t, cpx, cpy, ...))
	if s == 'line' then
		insert_rel_cmd(path, i, cpx, cpy, rs, x, y)
	elseif s == 'hline' then
		insert_rel_cmd(path, i, cpx, cpy, rs, x)
	elseif s == 'vline' then
		insert_rel_cmd(path, i, cpx, cpy, rs, y)
	elseif s == 'arc_3p' then
		--TODO
	elseif s == 'svgarc' then
		--TODO
	end
end

function split.quad_curve(path, i, t, s, rs, cpx, cpy, ...)
	local
		x11, y11, x12, y12, x13, y13,
		x21, y21, x22, y22, x23, y23 = quad_curve_split(t, cpx, cpy, ...)
	if s == 'quad_curve' then
		 insert_rel_cmd(path, i,     rs, cpx, cpy, rs, x12, y12, x13, y13)
		replace_rel_cmd(path, i + 8, rs, cpx, cpy, rs, x22, y22, x23, y23)
	elseif s == 'symm_quad_curve' then
		 insert_rel_cmd(path, i,     rs, cpx, cpy, rs, x13, y13)
		replace_rel_cmd(path, i + 8, rs, cpx, cpy, rs, x23, y23)
	elseif s == 'smooth_quad_curve' then

	end
end

function split.quad_curve(path, i, t, s, rs, cpx, cpy, ...)
	local
		x11, y11, x12, y12, x13, y13, y14,
		x21, y21, x22, y22, x23, y23, y24 = quad_curve_split(t, cpx, cpy, ...)
	if s == 'curve' then
		 insert_rel_cmd(path, i,     rs, cpx, cpy, rs, x12, y12, x13, y13, y14)
		replace_rel_cmd(path, i + 8, rs, cpx, cpy, rs, x22, y22, x23, y23, y24)
	elseif s == 'symm_curve' then
		 insert_rel_cmd(path, i,     rs, cpx, cpy, rs, x13, y13, y14)
		replace_rel_cmd(path, i + 8, rs, cpx, cpy, rs, x23, y23, y24)
	elseif s == 'smooth_curve' then

	end
end

function split.carc(path, i, t, s, rs, cpx, cpy, ...)
	--TODO
end

local function split_path(path, i, t)
	local cpx, cpy, spx, spy, tkind, tx, ty = state_at(path, i)
	local function process(s, ...)
		local rs = path[i]
		local as = abs_cmd(rs)
		split[s](path, i, t, as, rs, ...)
	end
	process(simple_cmd(cpx, cpy, spx, spy, tkind, tx, ty,
				  abs_cmd(cpx, cpy,
					   cmd(path, i))))
end

--path to abs/rel conversion ---------------------------------------------------------------------------------------------

local function add_abs_cmd(path, cpx, cpy, spx, spy, ...)
	append_cmd(path, ...)
	return next_cp(cpx, cpy, spx, spy, ...)
end
local function abs_path(path)
	local t = {}
	local cpx, cpy, spx, spy
	for i,s in commands(path) do
		cpx, cpy, spx, spy = add_abs_cmd(t, cpx, cpy, spx, spy, abs_cmd(cpx, cpy, cmd(path, i)))
	end
	return t
end

local function add_rel_cmd(path, cpx, cpy, spx, spy, s, ...)
	append_rel_cmd(path, cpx, cpy, cpx and rel_name(s) or s, ...)
	return next_cp(cpx, cpy, spx, spy, s, ...)
end
local function rel_path(path)
	local t = {}
	local cpx, cpy, spx, spy
	for i,s in commands(path) do
		cpx, cpy, spx, spy = add_rel_cmd(t, cpx, cpy, spx, spy, abs_cmd(cpx, cpy, cmd(path, i)))
	end
	return t
end

--subpath iteration and decoding -----------------------------------------------------------------------------------------

local closed_shapes = glue.index{
		'circle', 'circle_3p', 'ellipse', 'rect', 'round_rect', 'elliptic_rect',
		'star', 'star_2p', 'rpoly', 'superformula', 'text'}
glue.update(closed_shapes, rel_variations(closed_shapes))

local subpath_starters = glue.index{'move', 'arc', 'elliptic_arc'}
glue.update(subpath_starters, rel_variations(subpath_starters))
glue.update(subpath_starters, closed_shapes)

--check if a command starts a subpath, also implicitly ending the prev. subpath, if any.
local function starts_subpath(s)
	return subpath_starters[s] and true or false
end

--check if a command closes a subpath, also implicitly ending it.
local function closes_subpath(s)
	return s == 'close' or s == 'rel_close' or closed_shapes[s] and true or false
end

--given a command index, return the index of the last command of the subpath which the command is part of.
local function subpath_end(path, i)
	local s = assert(path[i], 'invalid path index')
	while not closes_subpath(s) do
		local nexti, nexts = next_cmd(path, i)
		if not nexts then break end --there's no next command, so path ends here.
		if starts_subpath(nexts) then break end --the next command starts a new subpath, thus ending this one.
		i, s = nexti, nexts
	end
	return i, s
end

--given a command index, return the index of the first command of the next subpath.
local function next_subpath(path, i)
	if not i then
		if #path == 0 then return end
		return 1, path[1]
	end
	return next_cmd(path, subpath_end(path, i))
end

--iterate subpaths, returning every time the index of the first command in the subpath and the command name.
local function subpaths(path, last_index)
	return next_subpath, path, last_index
end

--given an arbitrary path index, return the command index which starts the subpath of which the index is part of.
local function subpath_start(path, target_index)
	if target_index == 1 then return 1 end
	for i,s in subpaths(path) do
		local nexti = next_subpath(path, i)
		if nexti and nexti >= target_index then
			return i,s
		end
	end
	error'invalid path index'
end

--check if the subpath starting at command index i contains no drawing commands.
local function subpath_is_empty(path, i)
	if abs_name(path[i]) ~= 'move' then return false end
	local nexti, nexts = next_cmd(path, i)
	return not nexts or starts_subpath(nexts) or closes_subpath(nexts)
end

--given a command index, check if the subpath which the command is part of is closed or not.
local function is_closed(path, i)
	return closes_subpath(select(2, subpath_end(path, i)))
end

--subpath manipulation ---------------------------------------------------------------------------------------------------

--given a command index, close the subpath which the command is part of (if it's already closed, do nothing).
local function close_subpath(path, i)
	local endi, ends = subpath_end(path, i)
	if closes_subpath(ends) then return end
	local nexti, nexts = next_cmd(path, endi)
	if nexts and is_rel(nexts) then
		--the next subpath is relative to the current point in which this subpath ends.
		--we make that point explicit by prefixing a 'move' as to not affect the shape of the next subpath.
		local cpx, cpy = cp_at(path, nexti)
		insert_cmd(path, nexti, 'move', cpx, cpy)
	end
	insert_cmd(path, nexti, 'close')
end

--given a command index, open the subpath which the command is part of.
--if it's already open, do nothing. if it's a closed shape, do nothing.
local function open_subpath(path, i)
	local endi, ends = subpath_end(path, i)
	if abs_name(ends) ~= 'close' then return end
	remove_cmd(path, endi)
end

--move a subpath to a different position in the path. i and j must be subpath-starting command indices.
local function move_subpath(path, i, j)
	--
end

--given a command index which starts a subpath, reverse the subpath.
local function reverse_subpath(path, i)
	local endi, ends = subpath_end(path, i)
	while true do
		if i == endi then break end
		i = next_cmd(path, i)
	end
end

--given a command index part of a closed subpath, move the subpath commands around so that the subpath starts
--at a new command index part of the same subpath, while perfectly preserving the subpath shape. also, if the following
--subpath, if any, starts implicitly from this subpath's 'close' command, make it explicit by adding a 'move' command.
local function move_closed_subpath_start_command(path, i, new_index)
	--TOOD
end

--break a subpath at a command index. if the subpath was closed, the 'close' command is converted to a 'line' command,
--and all the commands until the break point are moved after the 'line' command and tied to it. also, if the next subpath
--was starting implicitly from the current point created by the 'close' command, make it explicit by adding a 'move'.
local function break_subpath(path, i)
	--TODO
end

--extract the path subsection between two indices as a valid independent path, assuming i is a command index and j is
--at the exact position of the last argument of the last command that needs to be included (defaults to #path).
local function extract_subpath(path, i, j)
	j = j or #path
	assert(i >=1 and i <= #path, 'invalid path index')
	if j < i then return end

	local t = {}
	local s = path[i]

	if starts_subpath(s) then
		if is_rel(s) then --starting a subpath, but with a rel. cmd, so we add it in abs. form.
			local cpx, cpy = cp_at(path, i)
			append_cmd(t, abs_cmd(cpx, cpy, cmd(path, i)))
			i = next_cmd(path, i)
			if not i then return t end
		end
	else
		local pi,ps = prev_cmd(path, i)
		if ps and abs_name(ps) == 'close' then --starting a subpath is implicit in a prev. close, so make the move explicit.
			local cpx, cpy = cp_at(path, i)
			append_cmd(t, 'move', cpx, cpy)
		else --we're in the middle of a subpath, so make the current point explicit and decontextualize the first command.
			local cpx, cpy, spx, spy, tkind, tx, ty = state_at(path, i)
			append_cmd(t, 'move', cpx, cpy)
			if abs_name(s) == 'close' then
				append_cmd(t, 'line', spx, spy)
				local nexti, nexts = next_cmd(path, i)
				if nexts and not starts_subpath(nexts) then --make sure we break the subpath where the close would had.
					append_cmd(t, 'move', spx, spy)
				end
				i = nexti
				if not i then return t end
			elseif s:find'symm_' or s:find'smooth_' then --unsmooth a smooth curve.
				append_cmd(t, to_cusp(cpx, cpy, tkind, tx, ty, abs_cmd(cpx, cpy, cmd(path, i))))
				i = next_cmd(path, i)
				if not i then return t end
			end
			--since we are breaking a subpath, if the subpath was closed, we have to reinterpret
			--the 'close' command as a 'line' and a 'move' and thus end the subpath without closing it.
			local endi,ends = subpath_end(path, i)
			if ends and abs_name(ends) == 'close' then
				--add all cmds till close
				for i = i, endi-1, 1 do
					t[#t+1] = path[i]
				end
				local cpx, cpy, spx, spy = cp_at(path, endi)
				append_cmd(t, 'line', spx, spy)
				local nexti, nexts = next_cmd(path, endi)
				if nexts and not starts_subpath(nexts) then --make sure we break the subpath where the close would had.
					append_cmd(t, 'move', spx, spy)
				end
				i = nexti
				if not i then return t end
			end
		end
	end

	for i = i, j do
		t[#t+1] = path[i]
	end

	return t
end

--whole path manipulation ------------------------------------------------------------------------------------------------

local function reverse_path(path)
	local t = {}
	local function save(write, _, i, s, ...)
		t[#t+1] = {i, s, ...}
	end
	decode_path(save, nil, path)

	local p = {}
	for ti = #t,1,-1 do
		local i, s = unpack(t[ti])
		local rs, as = path[i], abs_cmd(path[i])

		if s == 'close' then
			--insert_rel_cmd(p, 'move', ...
		end
	end
end

--command conversions ----------------------------------------------------------------------------------------------------

local function to_curves(path, i)
	local spath = {}
	local function write(s, ...)
		glue.append(spath, ...)
	end
	local cpx, cpy, spx, spy, bx, by, qx, qy = state_at(path, i)
	simplify_cmd(write, nil, cpx, cpy, spx, spy, bx, by, qx, qy,
		 bezier2_to_bezier3(cpx, cpy,
				canonical_cmd(cpx, cpy, spx, spy, bx, by, qx, qy,
						abs_cmd(cpx, cpy,
							 cmd(path, i)))))
	replace_cmd_t(path, i, spath)
end

--given a command in canonical form and the current point, return a 'line' command that best approximates it.
local function to_line(cpx, cpy, spx, spy, s, ...)
	local x2, y2 = next_state(cpx, cpy, spx, spy, nil, nil, nil, nil, s, ...)
	if x2 then return 'line', x2, y2 end
end

local line_point = require'path2d_line'.point
local b3_to_b2 = require'path2d_bezier3'.to_bezier2

--given a command in canonical form and the current point, return a 'quad_curve' command that best approximates it.
local function to_quad_curve(cpx, cpy, s, ...)
	if s == 'quad_curve' then
		return s, ...
	elseif s == 'line' then
		local x2, y2 = line_point(0.5, cpx, cpy, ...)
		return 'quad_curve', x2, y2, ...
	elseif as == 'curve' then
		return 'quad_curve', select(3, b3_to_b2(cpx, cpy, ...))
	end
end

--given a command in canonical form and the current point, return a 'curve' command that best approximates it.
local function to_curve(cpx, cpy, s, ...)
	if s == 'curve' then
		return s, ...
	elseif s == 'line' then
		local x2, y2 = line_point(1/3, cpx, cpy, ...)
		local x3, y3 = line_point(2/3, cpx, cpy, ...)
		return 'curve', x2, y2, x3, y3, ...
	elseif s == 'quad_curve' then
		return 'curve', select(3, b2_to_b3(cpx, cpy, ...))
	end
end

--
local function to_smooth(cpx, cpy, bx, by, qx, qy, s, ...)
	if s == 'curve' then
		return 'smooth_curve', ...
	elseif s == 'quad_curve' then
		return 'smooth_quad_curve', ...
	end
end

local function to_symm(cpx, cpy, bx, by, qx, qy, s, ...)
	if s == 'curve' then
		return 'smooth_curve', ...
	elseif s == 'quad_curve' then
		return 'smooth_quad_curve', ...
	end
end

local function to_cusp(cpx, cpy, bx, by, qx, qy, s, ...)
	if s == 'curve' then
		return 'smooth_curve', ...
	elseif s == 'quad_curve' then
		return 'smooth_quad_curve', ...
	end
end

local function to_arc_3p() end
local function to_arc() end
local function to_svgarc() end

local conversions = {} --{command = {["conversion name"] = converter}}

for _,s in ipairs{'line', 'curve', 'quad_curve', 'arc'} do
	--abs. commands can be made rel.
	conversions[s] = {
	}

	--rel. commands can be made abs.
	conversions['rel_'..s] = {
	}
end

local line_conversions = {
	['to curve'] = to_curve,
}
glue.update(conversions.line,     line_conversions)
glue.update(conversions.rel_line, line_conversions)

local curve_conversions = {
	['to line'] = to_line,
}
glue.update(conversions.curve,     curve_conversions)
glue.update(conversions.rel_curve, curve_conversions)

local arc_conversions = {
	['to 3-point arc']  = to_arc_3p,
	['to elliptic arc'] = to_svgarc,
}
glue.update(conversions.arc,     arc_conversions)
glue.update(conversions.rel_arc, arc_conversions)

--TODO: composites can be converted to curves

--path transformation

--check if a command is transformable by an affine transformation.
local function is_transformable(s)

end

--path reflection --------------------------------------------------------------------------------------------------------

local pp = require'pp'

local function fmt_args(path, i)
	if abs_name(path[i]) == 'text' then
		return path[i+1], path[i+2], pp.format(path[i+3]), path[i+4]
	else
		return select(2, cmd(path, i))
	end
end

local function inspect(path)
	local t = {}
	local count = 0
	for i in subpaths(path) do
		count = count + 1
		t[i] = count
	end
	print'sub# index#         cpx, cpy  command                  args'
	print'----------------------------------------------------------------------'
	local cpx, cpy, spx, spy
	for i,s in commands(path) do
		print(string.format('%s %6d %16s  %-24s '..('%s, '):rep(argc[path[i]]),
									t[i] and string.format('%4s', t[i]) or '    ',
									i,
									cpx and string.format('%g, %g', cpx, cpy) or 'nil, nil',
									s,
									fmt_args(path, i)))
		cpx, cpy, spx, spy = next_cp(cpx, cpy, spx, spy, abs_cmd(cpx, cpy, cmd(path, i)))
	end
end

--public API -------------------------------------------------------------------------------------------------------------

return {
	--iterating
	argc = argc,
	next_cmd = next_cmd,
	prev_cmd = prev_cmd,
	commands = commands,
	cmd = cmd,
	--modifying
	append_cmd = append_cmd,
	insert_cmd = insert_cmd,
	replace_cmd = replace_cmd,
	remove_cmd = remove_cmd,
	--decoding: rel->abs
	is_rel = is_rel,
	abs_name = abs_name,
	rel_name = rel_name,
	abs_cmd = abs_cmd,
	rel_cmd = rel_cmd,
	--decoding: command state: current point
	next_cp = next_cp,
	cp_at = cp_at,
	--decoding: command state: current point + tangent tip
	next_state = next_state,
	state_at = state_at,
	--decoding: simplifying
	decode = decode_path,
	command_decoder = command_decoder,
	--decoding: decomposing and transforming
	decompose = decompose_path,
	decode_recursive = decode_recursive,
	--measuring and hit testing
	bounding_box = path_bbox,
	length = path_length,
	hit = hit_path,
	split = split_path,
	--conversion
	to_abs = abs_path,
	to_rel = rel_path,
	--subpaths
	next_subpath = next_subpath,
	subpaths = subpaths,
	subpath_start = subpath_start,
	subpath_end = subpath_end,
	subpath_is_empty = subpath_is_empty,
	is_closed = is_closed,
	close_subpath = close_subpath,
	open_subpath = open_subpath,
	reverse_subpath = reverse_subpath,
	extract_subpath = extract_subpath,
	--
	reverse = reverse_path,
	--reflection
	inspect = inspect,
}

