local glue = require'glue'
local path_state = require'path'

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local distance = require'path_point'.distance
local point_angle = require'path_point'.point_angle
local point_around = require'path_point'.point_around
local point_line_intersection = require'path_line'.point_line_intersection
local arc3p_to_arc = require'path_arc_3p'.to_arc
local svgarc_to_arc = require'path_svgarc'.to_arc
local arc_endpoints = require'path_arc'.endpoints
local arc_tangent_vector = require'path_arc'.tangent_vector
local point_at = require'path_arc'.point_at
local point_at = require'path_arc'.point_at
local circle_3p_to_circle = require'path_circle_3p'.to_circle
local star_to_star_2p = require'path_shapes'.star_to_star_2p

local function recursion_safe(f)
	local setting = false
	return function(...)
		if setting then return end
		setting = true
		f(...)
		setting = false
	end
end

local function new_mutex()
	local setting = false
	return function(f)
		return function(...)
			if setting then return end
			setting = true
			f(...)
			setting = false
		end
	end
end

local function control_points(path)
	local points = {} --{x1, y1, x2, y2, ...}
	local setters = {} --{set_x1, set_y1, ...}

	--override the value setter at index px so that it chain-calls another setter
	local function chain(px, setter)
		local old_setter = assert(setters[px])
		setters[px] = function(x)
			old_setter(x)
			setter(x)
		end
	end

	--create a point with a null update handler
	local function null_pt(x, y)
		local px, py = #points+1, #points+2
		points[px] = x
		points[py] = y
		setters[px] = glue.pass
		setters[py] = glue.pass
		return px, py
	end

	--create a point that updates itself
	local function self_pt(x, y)
		local px, py = null_pt(x, y)
		--point updates its own coordinates
		setters[px] = function(x) points[px] = x end
		setters[py] = function(y) points[py] = y end
		return px, py
	end

	--create a point that directly represents (and thus updates) an abs. point in path at index cx, cy
	local function path_abs_pt(cx, cy)
		local px, py = null_pt(path[cx], path[cy])
		--point updates itself and its representation in path
		setters[px] = function(x) points[px] = x; path[cx] = x end
		setters[py] = function(y) points[py] = y; path[cy] = y end
		return px, py
	end

	--create a point that directly represents (and thus updates) a rel. point in path at index cx, cy
	local function path_rel_pt(cx, cy, cpx, cpy)
		local px, py = null_pt(points[cpx] + path[cx], points[cpy] + path[cy])
		--point updates itself and its representation in path
		setters[px] = function(x) points[px] = x; path[cx] = x - points[cpx] end
		setters[py] = function(y) points[py] = y; path[cy] = y - points[cpy] end
		--current point updates the point in path that is relative to it, so as to preserve that point's absolute position
		chain(cpx, function(x) path[cx] = points[px] - x end)
		chain(cpy, function(y) path[cy] = points[py] - y end)
		return px, py
	end

	--create a point that directly represents (and thus updates) a rel. or an abs. point in path at index cx, cy
	local function path_pt(cx, cy, rel, cpx, cpy)
		return (rel and path_rel_pt or path_abs_pt)(cx, cy, cpx, cpy)
	end

	--move px,py with delta (difference of movement) when cx,cy is updated (i.e. cx,cy carries or drags px,py with it)
	local dx, dy = 0, 0
	local function move_delta(cx, cy, px, py, mutex)
		local move_px = function() setters[px](points[px] + dx) end
		local move_py = function() setters[py](points[py] + dy) end
		if mutex then
			move_px = mutex(move_px)
			move_py = mutex(move_py)
		end
		chain(cx, move_px)
		chain(cy, move_py)
	end

	local cpx, cpy, spx, spy, tkind, tx, ty, tclen

	for i,s in path_state.commands(path) do

		local s, rel = path_state.abs_name(s), path_state.is_rel(s)
		local tkind1 = tkind; tkind = nil

		if s == 'move' then

			local c2x, c2y = i+1, i+2
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			cpx, cpy = p2x, p2y
			spx, spy = cpx, cpy

		elseif s == 'line' then

			local c2x, c2y = i+1, i+2
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			cpx, cpy = p2x, p2y

		elseif s == 'close' then

			cpx, cpy = spx, spy

		elseif s == 'hline' then

			local p1x, p1y = cpx, cpy
			local c2x = i+1
			local p2x, p2y = self_pt((rel and points[p1x] or 0) + path[c2x], points[p1y])

			if not rel then
				--endpoint updates its representation in path
				chain(p2x, function(v) path[c2x] = points[p2x] end)
			else
				local function set_c2x(v) path[c2x] = points[p2x] - points[p1x] end

				--endpoint updates its representation in path
				chain(p2x, set_c2x)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_c2x)
			end

			--endpoint updates current point on the constrained axis to preserve horizontality
			chain(p2y, function(v) setters[p1y](v) end)

			--current point updates endpoint on the constrained axis to preserve horizontality
			chain(p1y, recursion_safe(function(v) setters[p2y](v) end))

			cpx, cpy = p2x, p2y

		elseif s == 'vline' then

			local p1x, p1y = cpx, cpy
			local c2y = i+1
			local p2x, p2y = self_pt(points[p1x], (rel and points[p1y] or 0) + path[c2y])

			if not rel then
				--endpoint updates its representation in path
				chain(p2y, function(v) path[c2y] = points[p2y] end)
			else
				local function set_c2y(v) path[c2y] = points[p2y] - points[p1y] end

				--endpoint updates its representation in path
				chain(p2y, set_c2y)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1y, set_c2y)
			end

			--endpoint updates current point on the constrained axis to preserve verticality
			chain(p2x, function(v) setters[p1x](v) end)

			--current point updates endpoint on the constrained axis to preserve verticality
			chain(p1x, recursion_safe(function(v) setters[p2x](v) end))

			cpx, cpy = p2x, p2y

		elseif s == 'quad_curve' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)

			--end points carry control point
			move_delta(p1x, p1y, p2x, p2y)
			move_delta(p3x, p3y, p2x, p2y)

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil

		elseif s == 'quad_curve_3p' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'tangent', p2x, p2y, nil

		elseif s == 'curve' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y, c4x, c4y = i+1, i+2, i+3, i+4, i+5, i+6
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)
			local p4x, p4y = path_pt(c4x, c4y, rel, cpx, cpy)

			--endpoints carry control points
			move_delta(p1x, p1y, p2x, p2y)
			move_delta(p4x, p4y, p3x, p3y)

			cpx, cpy = p4x, p4y
			tkind, tx, ty, tclen = 'cubic', p3x, p3y, nil

		elseif s == 'symm_quad_curve' or s == 'symm_curve' then

			local kind = s:find'quad' and 'quad' or 'cubic'
			local p1x, p1y = cpx, cpy
			local c3x, c3y = i+1, i+2
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)
			local p4x, p4y
			if kind == 'cubic' then
				local c4x, c4y = i+3, i+4
				p4x, p4y = path_pt(c4x, c4y, rel, cpx, cpy)
			end

			local psx, psy
			if tkind1 == kind then
				psx, psy = self_pt(reflect_point(points[tx], points[ty], points[p1x], points[p1y]))
				local tx_, ty_ = tx, ty

				--virtual control point moves the tangent tip
				chain(psx, recursion_safe(function(v) setters[tx_](2 * points[p1x] - v) end))
				chain(psy, recursion_safe(function(v) setters[ty_](2 * points[p1y] - v) end))

				--tangent tip moves the virtual control point
				chain(tx, function(v) setters[psx](2 * points[p1x] - v) end)
				chain(ty, function(v) setters[psy](2 * points[p1y] - v) end)

				--endpoints carry second control points
				if kind == 'quad' then
					move_delta(p3x, p3y, psx, psy)
				else
					move_delta(p1x, p1y, psx, psy)
				end
			else
				--if the tangent tip is missing or not of the right type, the first endpoint serves as tangent tip
				psx, psy = p1x, p1y
			end

			--second endpoint carries second control point
			if kind == 'cubic' then
				--TODO: move_delta(p4x, p4y, p3x, p3y)
			end

			--advance the state
			if kind == 'quad' then
				cpx, cpy = p3x, p3y
				tkind, tx, ty, tclen = kind, psx, psy, nil
			else
				cpx, cpy = p4x, p4y
				tkind, tx, ty, tclen = kind, p3x, p3y, nil
			end

		elseif s == 'smooth_quad_curve' or s == 'smooth_curve' then

			local kind = s:find'quad' and 'quad' or 'cubic'
			local p1x, p1y = cpx, cpy
			local clen, c3x, c3y = i+1, i+2, i+3
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)
			local p4x, p4y
			if kind == 'cubic' then
				local c4x, c4y = i+4, i+5
				p4x, p4y = path_pt(c4x, c4y, rel, cpx, cpy)
			end

			local psx, psy
			if tkind1 == 'tangent' then --there's a tangent tip and it's immovable
				local ptx, pty = tx, ty
				psx, psy = null_pt(0, 0)
				local mutex = new_mutex()

				setters[psx] = mutex(function(x)
					local x, y = point_line_intersection(x, points[psy], points[p1x], points[p1y], points[ptx], points[pty])
					points[psx] = x
					points[psy] = y
					path[clen] = distance(x, y, points[p1x], points[p1y])
				end)

				setters[psy] = mutex(function(y)
					local x, y = point_line_intersection(points[psx], y, points[p1x], points[p1y], points[ptx], points[pty])
					points[psx] = x
					points[psy] = y
					path[clen] = distance(x, y, points[p1x], points[p1y])
				end)

				--tangent tip rotates smooth control point
				local set_ps = mutex(function()
					local x, y = reflect_point_distance(points[ptx], points[pty], points[p1x], points[p1y], path[clen])
					points[psx] = x
					points[psy] = y
					setters[psx](x)
					setters[psy](y)
				end)
				chain(tx, set_ps)
				chain(ty, set_ps)
				set_ps()

			elseif tkind1 then --there's a tip and it's movable
				psx, psy = self_pt(reflect_point_distance(points[tx], points[ty], points[p1x], points[p1y], path[clen]))
				local tx_, ty_, tclen_ = tx, ty, tclen

				--moving the virtual control point updates clen
				local function set_clen()
					path[clen] = distance(points[psx], points[psy], points[p1x], points[p1y])
				end
				chain(psx, set_clen)
				chain(psy, set_clen)

				local mutex = new_mutex()

				--virtual control point moves tangent tip
				local move_tip = mutex(function()
					if tclen_ then
						local tlen = path[tclen_]
						local x, y = reflect_point_distance(points[psx], points[psy], points[p1x], points[p1y], tlen)
						setters[tx_](x)
						setters[ty_](y)
					else
						local tlen = distance(points[tx_], points[ty_], points[p1x], points[p1y])
						local x, y = reflect_point_distance(points[psx], points[psy], points[p1x], points[p1y], tlen)
						setters[tx_](x)
						setters[ty_](y)
					end
				end)
				chain(psx, move_tip)
				chain(psy, move_tip)

				--tangent tip moves virtual control point
				local move_vpoint = mutex(function()
					local x, y = reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])
					setters[psx](x)
					setters[psy](y)
				end)
				chain(tx, move_vpoint)
				chain(ty, move_vpoint)

				--second endpoint carries control point
				if kind == 'quad' then
					move_delta(p3x, p3y, psx, psy)
				end
			else --there's no tangent tip, so the first endpoint will serves as smooth point
				psx, psy = p1x, p1y
			end

			--second endpoint carries second control point
			if kind == 'cubic' then
				move_delta(p4x, p4y, p3x, p3y)
			end

			--advance the state
			if kind == 'quad' then
				cpx, cpy = p3x, p3y
				tkind, tx, ty, tclen = kind, psx, psy--, clen
			else
				cpx, cpy = p4x, p4y
				tkind, tx, ty, tclen = kind, p3x, p3y--, clen
			end

		elseif s == 'arc' or s == 'line_arc' or s == 'elliptic_arc' or s == 'line_elliptic_arc' then

			local p1x, p1y = cpx, cpy
			local ccx, ccy, crx, cry, cstart_angle, csweep_angle, crotation
			if s:find'elliptic' then
				ccx, ccy, crx, cry, cstart_angle, csweep_angle, crotation = i+1, i+2, i+3, i+4, i+5, i+6, i+7
			else
				ccx, ccy, crx, cry, cstart_angle, csweep_angle = i+1, i+2, i+3, i+3, i+4, i+5
			end
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)

			--arc endpoints
			local px1, py1 = self_pt(0, 0)
			local px2, py2 = self_pt(0, 0)
			local function set_endpoints()
				local cx, cy = points[pcx], points[pcy]
				local rx, ry, start_angle, sweep_angle = path[crx], path[cry], path[cstart_angle], path[csweep_angle]
				local rotation = crotation and path[crotation]
				local x1, y1, x2, y2 = arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation)
				points[px1] = x1
				points[py1] = y1
				--TODO
				--setters[px2](x2)
				--setters[py2](y2)
				points[px2] = x2
				points[py2] = y2
			end
			set_endpoints()

			--center carries endpoints
			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)

			--endpoints change angles
			local function move_angles()
				local a1 = point_angle(points[px1], points[py1], points[pcx], points[pcy])
				local a2 = point_angle(points[px2], points[py2], points[pcx], points[pcy])
				path[cstart_angle] = a1
				--path[csweep_angle] = a2 - a1
				set_endpoints()
			end
			chain(px1, move_angles)
			chain(py1, move_angles)
			chain(px2, move_angles)
			chain(py2, move_angles)

			if s:find'^line_' then
				cpx, cpy = px2, py2
			else
				spx, spy, cpx, cpy = px1, py1, px2, py2
			end

		elseif s == 'svgarc' then

			local px1, py1 = cpx, cpy
			local crx, cry, crotation, clarge_arc_flag, csweep_flag, cx2, cy2 = i+1, i+2, i+3, i+4, i+5, i+6, i+7
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)

			--arc's center, radii and rotation control points
			local pcx, pcy = self_pt(0, 0)
			local prxx, prxy = self_pt(0, 0)
			local pryx, pryy = self_pt(0, 0)
			local prxx1, prxy1 = self_pt(0, 0)
			local pryx1, pryy1 = self_pt(0, 0)
			local ptx, pty = null_pt(0, 0)

			--endpoints update control points
			local function set_pts()
				local cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2 =
					svgarc_to_arc(points[px1], points[py1], path[crx], path[cry], path[crotation],
										path[clarge_arc_flag], path[csweep_flag], points[px2], points[py2])
				if cx then
					points[pcx], points[pcy] = cx, cy
					points[prxx], points[prxy] = point_at(0, cx, cy, rx, ry, rotation)
					points[pryx], points[pryy] = point_at(90, cx, cy, rx, ry, rotation)
					points[prxx1], points[prxy1] = point_at(180, cx, cy, path[crx], path[cry], rotation)
					points[pryx1], points[pryy1] = point_at(270, cx, cy, path[crx], path[cry], rotation)
					points[ptx], points[pty] = select(3, arc_tangent_vector(1,
																		cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2))
				else
					--TODO: find better spots to place these
					points[pcx], points[pcy] = points[px1], points[py1]
					points[prxx], points[prxy] = points[px1], points[py1]
					points[pryx], points[pryy] = points[px1], points[py1]
					points[prxx1], points[prxy1] = points[px1], points[py1]
					points[pryx1], points[pryy1] = points[px1], points[py1]
					points[ptx], points[pty] = points[px1], points[py1]
				end
				setters[ptx](x)
				setters[pty](y)
			end
			set_pts()
			chain(px2, set_pts)
			chain(py2, set_pts)
			chain(px1, set_pts)
			chain(py1, set_pts)

			--center carries endpoints
			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)

			--rotation points update rotation and other control points
			local function rotate_around_rx()
				path[crotation] = point_angle(points[prxx], points[prxy], points[pcx], points[pcy])
				set_pts()
			end
			local function rotate_around_ry()
				path[crotation] = point_angle(points[pryx], points[pryy], points[pcx], points[pcy]) - 90
				set_pts()
			end
			chain(prxx, rotate_around_rx)
			chain(prxy, rotate_around_rx)
			chain(pryx, rotate_around_ry)
			chain(pryy, rotate_around_ry)

			--radii points update radii and other control points
			local function set_radii()
				path[crx] = distance(points[prxx1], points[prxy1], points[pcx], points[pcy])
				path[cry] = distance(points[pryx1], points[pryy1], points[pcx], points[pcy])
				set_pts()
			end
			chain(prxx1, set_radii)
			chain(prxy1, set_radii)
			chain(pryx1, set_radii)
			chain(pryy1, set_radii)

			cpx, cpy = px2, py2
			tkind, tx, ty = 'tangent', ptx, pty

		elseif s == 'arc_3p' then

			local px1, py1 = cpx, cpy
			local cxp, cyp, cx2, cy2 = i+1, i+2, i+3, i+4

			local pxp, pyp = path_pt(cxp, cyp, rel, cpx, cpy)
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)

			--tangent point: not directly updatable, but updated by any of the arc's endpoints
			local ptx, pty = null_pt(0, 0)
			local function setpt()
				local x1, y1, xp, yp, x2, y2 = points[px1], points[py1], points[pxp], points[pyp], points[px2], points[py2]
				local cx, cy, r, start_angle, sweep_angle, x2, y2 = arc3p_to_arc(x1, y1, xp, yp, x2, y2)
				if cx then
					x1, y1 = select(3, arc_tangent_vector(1, cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2))
				end
				points[ptx] = x1
				points[pty] = y1
				setters[ptx](x)
				setters[pty](y)
			end
			setpt()
			chain(px2, setpt)
			chain(px2, setpt)
			chain(px1, setpt)
			chain(py1, setpt)
			chain(pxp, setpt)
			chain(pyp, setpt)

			cpx, cpy = px2, py2
			tkind, tx, ty = 'tangent', ptx, pty

		elseif s == 'circle_3p' then

			local cx1, cy1, cx2, cy2, cx3, cy3 = i+1, i+2, i+3, i+4, i+5, i+6
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)
			local px3, py3 = path_pt(cx3, cy3, rel, cpx, cpy)

			--center point
			local pcx, pcy = self_pt(0, 0)
			local function set_center()
				local cx, cy, r = circle_3p_to_circle(points[px1], points[py1], points[px2], points[py2],
																	points[px3], points[py3])
				if not cx then return end
				points[pcx], points[pcy] = cx, cy
			end
			set_center()

			--tangent points move center point
			chain(px1, set_center)
			chain(py1, set_center)
			chain(px2, set_center)
			chain(py2, set_center)
			chain(px3, set_center)
			chain(py3, set_center)

			--center point carries tangent points
			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)
			move_delta(pcx, pcy, px3, py3)

		elseif s == 'circle' then

			local ccx, ccy, cr = i+1, i+2, i+3
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)

			--arbitrary point on circle representing its radius
			local px, py = self_pt(points[pcx] - path[cr], points[pcy])
			local function set_r()
				path[cr] = distance(points[px], points[py], points[pcx], points[pcy])
			end
			--radius point changes radius
			chain(px, set_r)
			chain(py, set_r)

			--center point carries radius point
			move_delta(pcx, pcy, px, py)

		elseif s == 'ellipse' then

			local ccx, ccy, crx, cry, crotation = i+1, i+2, i+3, i+4, i+5
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)

			local mutex = new_mutex()

			--radii points change radii
			local prxx, prxy = self_pt(0, 0)
			local pryx, pryy = self_pt(0, 0)
			local function set_pts()
				local cx, cy, rx, ry, rotation = points[pcx], points[pcy], path[crx], path[cry], path[crotation]
				points[prxx], points[prxy] = point_at(0, cx, cy, rx, ry, rotation)
				points[pryx], points[pryy] = point_at(90, cx, cy, rx, ry, rotation)
			end
			set_pts()
			local set_rx = mutex(function()
				path[crotation] = point_angle(points[prxx], points[prxy], points[pcx], points[pcy])
				path[crx] = distance(points[prxx], points[prxy], points[pcx], points[pcy])
				set_pts()
			end)
			chain(prxx, set_rx)
			chain(prxy, set_rx)

			local set_ry = mutex(function()
				path[crotation] = point_angle(points[pryx], points[pryy], points[pcx], points[pcy]) - 90
				path[cry] = distance(points[pryx], points[pryy], points[pcx], points[pcy])
				set_pts()
			end)
			chain(pryx, set_ry)
			chain(pryy, set_ry)

			--center point carries radii points exclusive of their own updating
			move_delta(pcx, pcy, prxx, prxy, mutex)
			move_delta(pcx, pcy, pryx, pryy, mutex)

		elseif s == 'rect' or s == 'round_rect' or s == 'elliptic_rect' then

			local cx, cy, cw, ch = i+1, i+2, i+3, i+4
			local px1, py1 = path_pt(cx, cy, rel, cpx, cpy)
			local px2, py2 = self_pt(points[px1] + path[cw], points[py1] + path[ch])
			local function set_size()
				path[cw] = points[px2] - points[px1]
				path[ch] = points[py2] - points[py1]
			end
			chain(px1, set_size)
			chain(py1, set_size)
			chain(px2, set_size)
			chain(py2, set_size)

			if s == 'round_rect' or s == 'elliptic_rect' then
				local crx, cry = i+5, s == 'round_rect' and i+5 or i+6

				local w, h, rx, ry = path[cw], path[ch], path[crx], path[cry]
				local min, max, abs = math.min, math.max, math.abs
				if crx == cry then
					rx = min(abs(rx), abs(w/2), abs(h/2))
					ry = rx
				else
					rx = min(abs(rx), abs(w/2))
					ry = min(abs(ry), abs(h/2))
				end

				local prxx, prxy = self_pt(points[px1] - rx, points[py1])
				local pryx, pryy = self_pt(points[px1], points[py1] - ry)

				local function set_rx()
					points[prxx] = math.max((points[px2] + points[px1]) / 2, math.min(points[px1], points[prxx]))
					path[crx] = points[px1] - points[prxx]
				end
				chain(prxx, set_rx)
				setters[prxy] = function(v) points[prxy] = points[py1] end

				local function set_ry()
					points[pryy] = math.max((points[py2] + points[py1]) / 2, math.min(points[py1], points[pryy]))
					path[cry] = points[py1] - points[pryy]
				end
				chain(pryy, set_ry)
				setters[pryx] = function(v) points[pryx] = points[px1] end

				move_delta(px1, py1, prxx, prxy)
				move_delta(px1, py1, pryx, pryy)
			end

		elseif s == 'star' then

			local ccx, ccy, cx1, cy1, cr2, cn = i+1, i+2, i+3, i+4, i+5, i+6
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)

			local px2, py2 = self_pt(0, 0)
			local function set_p2()
				local cx, cy, x1, y1, x2, y2, n =
					star_to_star_2p(points[pcx], points[pcy], points[px1], points[py1], path[cr2], path[cn])
				points[px2], points[py2] = x2, y2
			end
			set_p2()

			chain(px1, set_p2)
			chain(py1, set_p2)

			local function set_r2()
				path[cr2] = distance(points[px2], points[py2], points[pcx], points[pcy])
				set_p2()
			end
			chain(px2, set_r2)
			chain(py2, set_r2)

			move_delta(pcx, pcy, px1, py1)

		elseif s == 'star_2p' then

			local ccx, ccy, cx1, cy1, cx2, cy2, cn = i+1, i+2, i+3, i+4, i+5, i+6, i+7
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)

			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)

		elseif s == 'rpoly' then

			local ccx, ccy, cx1, cy1, cn = i+1, i+2, i+3, i+4, i+5
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)

			move_delta(pcx, pcy, px1, py1)

		elseif s == 'superformula' then

			local ccx, ccy, csize, csteps, crotation = i+1, i+2, i+3, i+4, i+5
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local mutex = new_mutex()

			local prx, pry = self_pt(point_around(points[pcx], points[pcy], path[csize], path[crotation]))
			local set_size = mutex(function()
				path[crotation] = point_angle(points[prx], points[pry], points[pcx], points[pcy])
				path[csize] = distance(points[prx], points[pry], points[pcx], points[pcy])
			end)
			chain(prx, set_size)
			chain(pry, set_size)

			move_delta(pcx, pcy, prx, pry, mutex)

		end
	end

	local function update(i, px, py, co)
		dx, dy = px - points[i], py - points[i+1]
		setters[i](px)
		setters[i+1](py)
	end

	return points, update
end

local function tangent_tips(p)
	--for i,s in
end

if not ... then require'path_editor_demo' end

return {
	control_points = control_points,
}

