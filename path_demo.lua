local player = require'cplayer'
local glue = require'glue'
local path = require'path'
local matrix = require'affine2d'

local b2_to_b3 = require'path_bezier2'.to_bezier3
local function draw_function(cr)
	local cpx, cpy
	local function write(s, ...)
		if s == 'move' then
			cr:move_to(...)
			cpx, cpy = ...
		elseif s == 'close' then
			cr:close_path()
		elseif s == 'line' then
			cr:line_to(...)
			cpx, cpy = ...
		elseif s == 'curve' then
			cr:curve_to(...)
			cpx, cpy = select(5, ...)
		elseif s == 'quad_curve' then
			cr:curve_to(select(3, b2_to_b3(cpx, cpy, ...)))
			cpx, cpy = select(3, ...)
		elseif s == 'text' then
			local x1, y1, font, text = ...
			cr:select_font_face(font.family or 'Arial', 0, 0)
			cr:set_font_size(font.size or 12)
			cr:move_to(x1, y1)
			cr:text_path(tostring(text))
			cpx, cpy = nil
		end
	end
	local function draw(path_, mt)
		cr:new_sub_path()
		path.decompose(write, path_, mt)
	end

	return draw
end

local subpaths, abs_rel, inspect

function player:on_render(cr)

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

	local draw = draw_function(cr)
	local mt = matrix():translate(150, -50)

	subpaths = self:mbutton{x = 10, y = 10, w = 190, h = 24, id = 'subpaths', values = {'mixed', 'open', 'closed'},
									selected = subpaths or 'mixed'}
	abs_rel  = self:mbutton{x = 10, y = 40, w = 190, h = 24, id = 'abs_rel', values = {'mixed', 'abs', 'rel'},
									selected = abs_rel or 'mixed'}
	inspect = self:button{x = 10, y = 70, w = 190, h = 24, id = 'inspect'}

	if subpaths == 'closed' then
		--close all non-empty subpaths
		for i,s in path.subpaths(p) do
			if not path.subpath_is_empty(p,i) then
				path.close_subpath(p,i)
			end
		end
	elseif subpaths == 'open' then
		--open all non-empty subpaths
		for i,s in path.subpaths(p) do
			if not path.subpath_is_empty(p,i) then
				path.open_subpath(p,i)
			end
		end
	end

	--convert to abs. or rel.
	if abs_rel == 'abs' then
		p = path.to_abs(p)
	elseif abs_rel == 'rel' then
		p = path.to_rel(p)
	end

	--hit testing
	local d,x,y,i,t = path.hit(self.mousex, self.mousey, p, mt)
	local hot = d < 20
	local selected = hot and self.lbutton

	if hot then
		self:circle(x,y,5)

		local cpx, cpy, spx, spy, tkind = path.state_at(p, i)
		self:label{x = self.mousex + 10, y = self.mousey + 22,
			text = string.format('%d %s\nt: %g\ncp: %s, %s\nsp: %s, %s\ntip: %s',
				i or 0,
				p[i] or 'n/a',
				t or 0,
				cpx and string.format('%4.2f', cpx) or 'nil',
				cpx and string.format('%4.2f', cpy) or 'nil',
				spy and string.format('%4.2f', spx) or 'nil',
				spy and string.format('%4.2f', spy) or 'nil',
				tkind
			)
		}
	end

	draw(p, mt)
	self:stroke('normal_fg')

	--bounding box of the entire path
	if true then
		local x,y,w,h = path.bounding_box(p, mt)
		self:rect(x,y,w,h, nil, 'normal_fg', 0.3)
	end

	--bounding boxes of subpaths
	if true then
		for i,s in path.subpaths(p) do
			local j = path.next_subpath(p, i)
			j = j and j-1
			local subp = path.extract_subpath(p, i, j)
			local x,y,w,h = path.bounding_box(subp, mt)
			self:rect(x,y,w,h, nil, 'normal_fg', 0.3)
		end
	end

	--inspecting
	--local editor = require
	--self:editor

	if hot and not selected then
		local p = path.extract_subpath(p, i, i + path.argc[p[i]])
		draw(p, mt)
		self:stroke('normal_fg', 2)
	end

	--inspecting
	if inspect then
		path.inspect(p)
	end

end

player:play()
