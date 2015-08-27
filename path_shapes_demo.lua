local player = require'cplayer'
local glue = require'glue'
local shapes = require'path_shapes'
local bezier2_to_bezier3 = require'path_bezier2'.to_bezier3

local i = 60
function player:on_render(cr)

	i = self:slider{
		id = 'n',
		x = 10, y = 10, w = 200, h = 24, text = 'i',
		i0 = 0, i1 = 360, step = 1, i = i,
	}

	local x1,y1
	local function write(s,...)
		if s == 'move' then cr:move_to(...); x1,y1=...
		elseif s == 'line' then cr:line_to(...); x1,y1=...
		elseif s == 'curve' then cr:curve_to(...); x1,y1=select(5,...)
		elseif s == 'quad_curve' then cr:curve_to(select(3,bezier2_to_bezier3(x1,y1,...))); x1,y1=select(3,...)
		elseif s == 'close' then cr:close_path(); x1,y1=nil
		end
	end
	cr:set_source_rgb(1,1,1)

	--[[
	shapes.ellipse_to_bezier3(write, 100, 100, 50, 20)
	cr:stroke()

	shapes.circle_to_bezier3(write, 100, 100, 50)
	cr:stroke()
	]]

	shapes.rect_to_lines(write, 50, 50, 100, 100)
	cr:stroke()

	shapes.round_rect_to_bezier3(write, 50, 50, 100, 100, 20)
	cr:stroke()

	shapes.round_rect_to_bezier3(write, 250, 50, 100, 100, 20)
	cr:stroke()

	shapes.elliptic_rect_to_bezier3(write, 150 + 250, 50, 100, 100, 20, -200)
	cr:stroke()

	local n = 2 + 10 + math.floor(math.sin(i/100)*10)
	cr:translate(200, 300)

	shapes.rpoly_to_lines(write, 0, 0, 30, -100, n)
	cr:stroke()

	cr:translate(300, 0)
	shapes.star_to_lines(write, 0, 0, 0, -100, 30, n)
	cr:stroke()

	cr:translate(300, 0)
	shapes.star_2p_to_lines(write, 0, 0, 0, -100, 0, -50, n)
	cr:stroke()

	cr:translate(300, 0)
	shapes.circle_to_bezier2(write, 100, 100, 100, n)
	cr:stroke()

	cr:translate(-1000, 300)
	local s = math.sin(i/20)
	shapes.superformula_to_lines(write, 0, 0, 10, 300, 30, 1, 1, 6+math.floor(s*3), 1, 7, 8); cr:stroke()
	shapes.superformula_to_lines(write, 200, 0, 100, 300, 30, 1, 1, 6, 20+s*10, 7, 18); cr:stroke()
	shapes.superformula_to_lines(write, 500, 0, 100, 300, 30, 1, 1, 8, 1, 1, 8+s); cr:stroke()
	shapes.superformula_to_lines(write, 800, 0, 50, 300, 30, 1, 1, 5, 2+s/2, 6, 6); cr:stroke()
	shapes.superformula_to_lines(write, 1100, 0, 50, 300, 30, 1.5, .5, 4+s*4, 4+s, 7, 7); cr:stroke()
end

player:play()

