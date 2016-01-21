local glue = require'glue'
local path = require'path'
local draw_function = require'path_cairo'
local player = require'cplayer'

local i=0
local drag_i
local p = {
	'move', 900, 110,
	--lines and control commands
	'rel_line', 20, 100,
	'rel_hline', 100,
	'rel_vline', -100,
	'close',
	'rel_line', 50, 50,
	--quad curves
	'move', 100, 160,
	'rel_quad_curve', 20, -100, 40, 0,
	'rel_symm_quad_curve', 40, 0,
	'rel_move', 50, 0,
	'rel_smooth_quad_curve', 100, 20, 0, --smooth without a tangent
	'rel_move', 50, 0,
	'rel_quad_curve', 20, -100, 20, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a quad curve
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a cubic curve
	'rel_move', 50, 0,
	'rel_arc_3p', 0, -40, 50, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth an arc
	'rel_move', 50, -50,
	'rel_line', 0, 50,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a line
	'rel_move', 50, 0,
	'rel_quad_curve_3p', 20, -50, 40, 0,  --3p
	--cubic curves
	'move', 100, 300,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_symm_curve', 40, 50, 40, 0,
	'rel_move', 50, 0,
	'rel_smooth_curve', 100, 20, 50, 20, 0, --smooth without a tangent
	'rel_move', 50, 0,
	'rel_quad_curve', 20, -100, 20, 0,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a quad curve
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a cubic curve
	'rel_move', 50, 0,
	'rel_arc_3p', 0, -40, 50, 0,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth an arc
	'rel_move', 50, -50,
	'rel_line', 0, 50,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a line
	--arcs
	'move', 100, 450,
	'rel_line_arc', 0, 0, 50, -90, 180,
	'rel_move', 100, -50,
	'rel_arc', 0, 0, 50, -90, 180,
	'rel_move', 100, -100,
	'rel_svgarc', -50, -20, -30, 0, 1, 30, 40,
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
	'rect', 100+60, 650, -50, -100,
	'round_rect', 100+120, 650, -50, -100, -10,
	'elliptic_rect', 100+180, 650, -50, -100, -100, -10,
	'elliptic_rect', 100+240, 650, -50, -100, -10, -100,
	'circle', 100+300, 600, -50,
	'ellipse', 100+390, 600, -30, -50, 30,
	'move', 100+480, 600,
	'rel_circle_3p', 50, 0, 0, 50, -50, 0,
	'superformula', 100+580, 600, 50, 300, 30, 1, 1, 3, 1, 1, 1,
	'move', 100+700, 600,
	'rel_star', 0, 0, 0, -50, 30, 8,
	'move', 100+800, 600,
	'rel_star_2p', 0, 0, 0, -50, 20, 15, 5,
	'move', 100+900, 600,
	'rel_rpoly', 0, 0, 20, -30, 5,
	'move', 700, 350,
	'rel_text', 0, 0, {size=70}, 'mittens',
}

function player:on_render(cr)
	i=i+1

	local draw = draw_function(cr)
	local mt --= require'affine2d'():translate(100, 200):scale(1, .7):rotate_around(500, 300, i/10)

	--close all non-empty subpaths
	if true then
		for i,s in path.subpaths(p) do
			if not path.subpath_is_empty(p,i) then
				path.close_subpath(p,i)
			end
		end
		--path.inspect(p)
		--os.exit(1)
	end
	--p = path.reverse(p)

	--intermitent open all non-empty subpaths
	if false and i % 50 > 25 then
		for i,s in path.subpaths(p) do
			if not path.subpath_is_empty(p,i) then
				path.open_subpath(p,i)
			end
		end
		--path.inspect(p)
		--os.exit(1)
	end

	--intermitent reverse path
	if i % 50 > 25 then
		--
	end

	--bounding box of the entire path
	if true then
		local x,y,w,h = path.bounding_box(p, mt)
		draw{'rect',x,y,w,h}
		cr:rgba(1,1,1,.5)
		cr:line_width(1)
		cr:stroke()
	end

	--bounding boxes of subpaths
	if true then
		for i,s in path.subpaths(p) do
			local j = path.next_subpath(p, i)
			j = j and j-1
			local subp = path.extract_subpath(p, i, j)
			local x,y,w,h = path.bounding_box(subp, mt)
			draw{'rect',x,y,w,h}
			cr:rgba(1,1,1,.5)
			cr:line_width(1)
			cr:stroke()
		end
	end

	--draw as is
	if true then
		draw(p, mt)
		cr:rgba(1,1,0,1)
		cr:fill()
	end

	--convert to abs. form and draw
	if true then
		local ap = path.to_abs(p)
		draw(ap, mt)
		cr:rgba(1,1,0,1)
		cr:line_width(7)
		cr:stroke()
	end

	--convert to rel. form and draw
	if true then
		local rp = path.to_rel(p)
		draw(rp, mt)
		cr:rgba(0,.2,1,1)
		cr:line_width(4)
		cr:stroke()
	end

	--print total length
	if true then
		local len = path.length(p, mt)
		cr:rgb(1,1,1)
		cr:move_to(self.window.client_w - 260, 20)
		cr:font_size(18)
		cr:text_path(string.format('length: %4.20f', len))
		cr:fill()
	end

	--hit testing
	if false then
		local x0, y0 = self.mouse_x, self.mouse_y
		if x0 then
			local d,x,y,i,t = path.hit(x0, y0, p, mt)
			cr:circle(x,y,5)
			cr:rgb(1,1,0)
			cr:fill()

			cr:move_to(x,y+16)
			cr:text_path(string.format(t and '(%d) %s: %g' or '[%d] %s', i, p[i], t))
			cr:line_width(1)
			cr:rgb(0,0,0)
			cr:stroke_preserve()
			cr:rgb(1,1,0)
			cr:fill()

			--if self.mouse_last.x ==
		end
	end

	--inspecting
	if false then
		path.inspect(p)
		os.exit(1)
	end

end
player:play()
