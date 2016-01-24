local affine2d = require'affine2d'
local player = require'cplayer'
local path_cairo = require'path_cairo'
local path_editor = require'path_editor'

local path = {
	'move', 10, 10,
	--lines and control commands
	'rel_line', 20, 100,
	'rel_hline', 100,
	'rel_vline', -100,
	'close',
	'rel_line', 40, 20,
	'hline', 100,
	'vline', 100,
	'hline', 70,
	'line', 60, 50,
	'close',
	--quad curves
	'rel_move', 10, 200,
	'rel_quad_curve', 20, -50, 40, 0, --quad
	'rel_symm_quad_curve', 40, 0,     --quad -> symm quad
	'rel_symm_quad_curve', 40, 0,     --quad -> symm quad -> symm quad
	'rel_symm_quad_curve', 40, 0,     --quad -> symm quad -> symm quad -> symm quad
	'rel_move', 50, 0,
	'rel_quad_curve', 20, -50, 40, 0,   --quad
	'rel_smooth_quad_curve', 40, 40, 0, --quad -> smooth quad
	'rel_smooth_quad_curve', 40, 40, 0, --quad -> smooth quad -> smooth quad
	'rel_smooth_quad_curve', 40, 40, 0, --quad -> smooth quad -> smooth quad -> smooth quad
	'rel_move', 50, 0,              --move
	'rel_symm_quad_curve', 0, -50,  --move -> symm quad
	'rel_symm_quad_curve', 50, -10, --move -> symm quad -> symm quad
	'rel_symm_quad_curve', 50, -10, --move -> symm quad -> symm quad -> symm quad
	'rel_move', 50, 80,                  --move
	'rel_smooth_quad_curve', 40, 0, -70, --move -> smooth quad
	'rel_smooth_quad_curve', 40, 50, 50, --move -> smooth quad -> smooth quad
	'rel_smooth_quad_curve', 80, 50,  0, --move -> smooth quad -> smooth quad-> smooth quad
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0, --cubic
	'rel_symm_quad_curve', 20, -20,      --cubic -> symm quad
	'rel_symm_quad_curve', 20, 20,       --cubic -> symm quad -> symm quad
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0, --cubic
	'rel_smooth_quad_curve', 50, 40, 0,  --cubic -> smooth quad
	'rel_smooth_quad_curve', 50, 40, 0,  --cubic -> smooth quad -> smooth quad
	'rel_move', 70, 0,
	'rel_elliptic_arc', 1, 1, 40, 30, 0, 270, 30, --elliptic arc
	'rel_smooth_quad_curve', 50, 40, 0,           --elliptic arc -> smooth quad
	'rel_smooth_quad_curve', 50, 40, 0,           --elliptic arc -> smooth quad -> smooth quad
	'rel_move', 70, 0,
	'rel_svgarc', 50, 30, -60, 0, 1, 30, 60, --svgarc
	'rel_smooth_quad_curve', 50, 40, 0,      --svgarc -> smooth quad
	'rel_smooth_quad_curve', 50, 40, 0,      --svgarc -> smooth quad -> smooth quad
	'rel_move', 50, 0,
	'rel_arc_3p', 0, -50, 50, -30,      --arc-3p
	'rel_smooth_quad_curve', 50, 40, 0, --arc-3p -> smooth quad
	'rel_smooth_quad_curve', 50, 40, 0, --arc-3p -> smooth quad -> smooth quad
	'rel_move', 50, -50,
	'rel_line', 0, 50,                  --line
	'rel_smooth_quad_curve', 50, 40, 0, --line -> smooth quad
	'rel_smooth_quad_curve', 50, 40, 0, --line -> smooth quad -> smooth quad
	'rel_move', 50, 0,
	'rel_quad_curve_3p', 20, -50, 40, 0,  --quad-3p
	'rel_smooth_quad_curve', 50, 40, 0,   --quad-3p -> smooth quad
	'rel_smooth_quad_curve', 50, 40, 0,   --quad-3p -> smooth quad -> smooth quad
	--cubic curves
	'rel_move', -1850, 150,
	'rel_move', 50, 0,
	'rel_curve', 0, -40, 40, -40, 40, 0,  --cubic
	'rel_symm_curve', 40,  40, 40, 0,     --cubic -> symm cubic
	'rel_symm_curve', 40, -40, 40, 0,     --cubic -> symm cubic -> symm cubic
	'rel_symm_curve', 40,  40, 40, 0,     --cubic -> symm cubic -> symm cubic -> symm cubic
	'rel_move', 50, 0,
	'rel_curve', 0, -40, 40, -40, 40, 0,    --cubic
	'rel_smooth_curve', 40, 40,  40, 40, 0, --cubic -> smooth cubic
	'rel_smooth_curve', 40, 40, -40, 40, 0, --cubic -> smooth cubic -> smooth cubic
	'rel_smooth_curve', 40, 40,  40, 40, 0, --cubic -> smooth cubic -> smooth cubic -> smooth cubic
	'rel_move', 50, 0,                --move
	'rel_symm_curve', 40, -40, 40, 0, --move -> symm cubic
	'rel_symm_curve', 40,  40, 40, 0, --move -> symm cubic -> symm cubic
	'rel_symm_curve', 40, -40, 40, 0, --move -> symm cubic -> symm cubic -> symm cubic
	'rel_move', 30, 0,                      --move
	'rel_smooth_curve', 40, 40, -40, 40, 0, --move -> smooth cubic
	'rel_smooth_curve', 40, 40,  40, 40, 0, --move -> smooth cubic -> smooth cubic
	'rel_smooth_curve', 40, 40, -40, 40, 0, --move -> smooth cubic -> smooth cubic -> smooth cubic
	'rel_move', 30, 0,
	'rel_quad_curve', 20, -50, 40, 0, --quad
	'rel_symm_curve', 40,  40, 40, 0, --quad -> symm cubic
	'rel_symm_curve', 40, -40, 40, 0, --quad -> symm cubic -> symm cubic
	'rel_move', 30, 0,
	'rel_quad_curve', 20, -50, 40, 0,       --quad
	'rel_smooth_curve', 40, 40,  40, 40, 0, --quad -> smooth cubic
	'rel_smooth_curve', 40, 40, -40, 40, 0, --quad -> smooth cubic -> smooth cubic
	'rel_move', 70, 0,
	'rel_elliptic_arc', 1, 1, 40, 30, 0, 270, 30, --elliptic arc
	'rel_smooth_curve', 50,  40, 0, 40, 0,        --elliptic arc -> smooth cubic
	'rel_smooth_curve', 50, -40, 0, 40, 0,        --elliptic arc -> smooth cubic -> smooth cubic
	'rel_move', 70, 0,
	'rel_svgarc', 50, 30, -60, 0, 1, 30, 60, --svgarc
	'rel_smooth_curve', 50,  40, 0, 40, 0,   --svgarc -> smooth cubic
	'rel_smooth_curve', 50, -40, 0, 40, 0,   --svgarc -> smooth cubic -> smooth cubic
	'rel_move', 70, 0,
	'rel_arc_3p', 0, -50, 50, -30, --arc-3p
	'rel_smooth_curve', 50,  40, 0, 40, 0, --arc-3p -> smooth cubic
	'rel_smooth_curve', 50, -40, 0, 40, 0, --arc-3p -> smooth cubic -> smooth cubic
	'rel_move', 50, -50,
	'rel_line', 0, 50,                     --line
	'rel_smooth_curve', 50,  40, 0, 40, 0, --line -> smooth cubic
	'rel_smooth_curve', 50, -40, 0, 40, 0, --line -> smooth cubic -> smooth cubic
	'rel_move', 50, 0,
	'rel_quad_curve_3p', 20, -50, 40, 0,   --quad-3p
	'rel_smooth_curve', 50,  40, 0, 40, 0, --quad-3p -> smooth cubic
	'rel_smooth_curve', 50, -40, 0, 40, 0, --quad-3p -> smooth cubic -> smooth cubic
	--arcs
	'rel_move', -1820, 150,
	'rel_line_arc', 0, 0, 50, -90, 180,
	'rel_move', 100, -50,
	'rel_arc', 0, 0, 50, -90, 180,
	'rel_move', 150, -100,
	'rel_svgarc', -50, -20, -30, 1, 1, 30, 40,
	'rel_svgarc', -50, -20, -30, 1, 0, 30, 40,
	'rel_svgarc', 10, 0, 0, 0, 0, 50, 0, --invalid parametrization (zero radius)
	'rel_svgarc', 10, 10, 10, 10, 0, 0, 0, --invalid parametrization (endpoints coincide)
	'rel_move', 50, -50,
	'rel_arc_3p', 40, -40, 80, 0,
	'rel_arc_3p', 40, 0, 40, 0, --invalid parametrization (endpoints are collinear)
	'rel_arc_3p', 0, 0, 0, 0, --invalid parametrization (endpoints coincide)
	'rel_move', 70, 0,
	'rel_line_elliptic_arc', 0, 0, 70, 30, 0, -270, -30,
	'close',
	--closed shapes
	'rel_move', -520, 220,
	'rel_rect', 0, 0, -50, -100,
	'rel_move', 70, 0,
	'rel_round_rect', 0, 0, -50, -100, -10,
	'rel_move', 70, 0,
	'rel_elliptic_rect', 0, 0, -50, -100, -100, -10,
	'rel_move', 70, 0,
	'rel_elliptic_rect', 0, 0, -50, -100, -10, -100,
	'rel_move', 70, 0,
	'rel_circle', 0, -50, -50,
	'rel_move', 100, 0,
	'rel_ellipse', 0, -50, -30, -50, 30,
	'rel_move', 100, -50,
	'rel_circle_3p', 0, -50, 0, 50, -50, 0,
	'rel_move', 100, 0,
	'rel_superformula', 0, 0, 50, 300, 30, 1, 1, 3, 1, 1, 1,
	'rel_move', 100, 0,
	'rel_star', 0, 0, 0, -50, 30, 8,
	'rel_move', 100, 0,
	'rel_star_2p', 0, 0, 0, -50, 20, 15, 5,
	'rel_move', 100, 0,
	'rel_rpoly', 0, 0, 20, -30, 5,
	'rel_move', 100, 0,
	'rel_text', 0, 0, {size=70}, 'mittens',
}

local mt = affine2d()--:translate(100, 0):rotate(10):scale(1, .7)
local invmt = mt:inverse()
local points, update = path_editor.control_points(path, mt)

local drag_i
local i = 0
function player:on_render(cr)
	local draw = path_cairo(cr)
	cr:rgb(0,0,0)
	cr:paint()

	draw(path, mt)
	cr:rgb(1,1,1)
	cr:stroke()

	for i=1,#points,2 do
		local x,y = points[i], points[i+1]
		x,y = mt(x,y)
		cr:rectangle(x-3,y-3,6,6)
		cr:rgb(1,1,0)
		cr:fill()
	end

	for i=1,#points,2 do
		local x, y = points[i], points[i+1]
		x,y = mt(x,y)
		if not drag_i and self.mouse_buttons.lbutton then
			if self:dragging(x, y, 3) then
				drag_i = i
			end
		elseif not self.mouse_buttons.lbutton then
			drag_i = nil
		end
	end
	if drag_i then
		local mx, my = self.mouse_x, self.mouse_y
		mx, my = invmt(mx, my)
		update(drag_i, mx, my)
	end

	--local ttips = tangent_tips(p)

end

player.window.w = 1800
player:play()
