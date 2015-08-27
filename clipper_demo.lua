local player = require'cplayer'
local clipper = require'clipper'
local ffi = require'ffi'
local cairo = require'cairo'

local point_count = 20
local first_poly = true
local second_poly = true
local result_poly = true
local even_odd = true
local seed = 0
local offset = 5
local command = 'intersection'
local join_type = 'round'
local miter_limit = 5

function player:on_render(cr)

	if self:button{
		id = 'generate',
		x = 10, y = 10, w = 160, h = 24,
		text = 'generate',
		theme = self.themes.red,
	} then
		seed = seed + 1
	end

	command = self:mbutton{
		id = 'command',
		x = 200, y = 10, w = 300, h = 24,
		values = {'intersection', 'union', 'difference', 'xor'},
		selected = command,
	}

	even_odd = self:mbutton{
		id = 'even_odd',
		x = 520, y = 10, w = 160, h = 24,
		values = {true, false},
		texts = {[true] = 'even odd', [false] = 'winding'},
		selected = even_odd,
	}

	first_poly  = self:togglebutton{id = 'first_poly',  x = 700, y = 10, w = 60, h = 24, text = 'first',  selected = first_poly,  cut = 'right'}
	second_poly = self:togglebutton{id = 'second_poly', x = 760, y = 10, w = 60, h = 24, text = 'second', selected = second_poly, cut = 'both'}
	result_poly = self:togglebutton{id = 'result_poly', x = 820, y = 10, w = 60, h = 24, text = 'result', selected = result_poly, cut = 'left'}

	point_count = self:slider{
		id = 'point_count',
		x = 10, y = 40, w = 160, h = 24,
		i0 = 3, i1 = 20,
		i = point_count,
		text = 'points',
	}

	offset = self:slider{
		id = 'offset',
		x = 10, y = 100, w = 160, h = 24,
		i0 = 0, i1 = 20,
		i = offset,
		text = 'offset',
	}

	join_type = self:mbutton{
		id = 'join_type',
		x = 10, y = 130, w = 160, h = 24,
		values = {'round', 'square', 'miter'},
		selected = join_type,
	}

	miter_limit = self:slider{
		id = 'miter_limit',
		x = 10, y = 160, w = 160, h = 24,
		i0 = 0, i1 = 100,
		i = miter_limit,
		text = 'miter limit',
	}

	math.randomseed(seed)

	cr:set_fill_rule(even_odd and
		cairo.C.CAIRO_FILL_RULE_EVEN_ODD or
		cairo.C.CAIRO_FILL_RULE_WINDING)
	cr:set_line_width(1)

	local scale = 1000000

	local function draw_poly(i, p, fr,fg,fb,fa, sr,sg,sb,sa)
		if p:size() == 0 then return end
		cr:new_path()
		cr:move_to(p:get(1).x / scale, p:get(1).y / scale)
		for i=2,p:size() do
			cr:line_to(p:get(i).x / scale, p:get(i).y / scale)
		end
		cr:close_path()
		if fr then
			fr, fg, fb, fa = fr or 1, fg or 1, fb or 1, fa or 1
			cr:set_source_rgba(fr, fg, fb, fa)
			cr:fill_preserve()
		end
		if sr then
			sr, sg, sb, sa = sr or 1, sg or 1, sb or 1, sa or 1
			cr:set_source_rgba(sr, sg, sb, sa)
			cr:stroke()
		end
	end

	local function draw_polys(p, ...)
		for i=1,p:size() do
			draw_poly(i, p:get(i), ...)
		end
	end

	local function random_polys(n)
		local n1 = math.floor(n / 2)
		local n2 = math.ceil(n / 2)
		--you can preallocate elements...
		local p = clipper.polygon(n1)
		for i=1,n1 do
			p:get(i).x = math.random(100, 1000) * scale
			p:get(i).y = math.random(100, 600) * scale
		end
		--or you can add elements one by one...
		for i=1,n2 do
			p:add(math.random(100, 1000) * scale, math.random(100, 600) * scale)
		end

		p = p:clean() --test CleanPolygon()
		p = clipper.polygons(p) --test polygons constructor
		p = p:clean() --test CleanPolygons()
		p = p:simplify(even_odd and 'even_odd' or 'non_zero')
		return p
	end

	local p1 = random_polys(point_count)
	local p2 = random_polys(point_count)

	if first_poly then
		draw_polys(p1, 0.7, 0.7, 1, 0.2, 0.7, 0.7, 1, 0.5)
	end

	if second_poly then
		draw_polys(p2, 0.7, 1, 0.7, 0.2, 0.7, 1, 0.7, 0.5)
	end

	local cl = clipper.new()
	cl:add_subject(p1)
	cl:add_clip(p2)
	local p3 = cl:execute(command)

	if result_poly then
		draw_polys(p3, 0, 1, 0, 0.5, 0, 1, 0, 1)
	end

	if offset > 0 then
		draw_polys(p3:offset(offset * scale, join_type, miter_limit), 0, 1, 0, 0, 0, 1, 0, 1)
		draw_polys(p3:offset(-offset * scale, join_type, miter_limit), 0, 1, 0, 0, 0, 1, 0, 1)
	end
end

player:play()

