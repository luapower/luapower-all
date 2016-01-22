--demo for hit testing, length, split and bbox for lines, arcs, beizer2, bezier3.
local player = require'cplayer'
local glue = require'glue'
local distance2 = require'path_point'.distance2
local line = require'path_line'
local arc = require'path_arc'
local bezier2 = require'path_bezier2'
local bezier3 = require'path_bezier3'
local cairo = require'cairo'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:rgb(0,0,0)
	cr:paint()
	cr:line_width(1)
	cr:fill_rule'even_odd'
	cr:font_face('Fixedsys')
	cr:font_size(12)

	local function hex_color(s)
		local r,g,b,a = tonumber(s:sub(2,3), 16), tonumber(s:sub(4,5), 16),
							 tonumber(s:sub(6,7), 16), tonumber(s:sub(8,9), 16) or 255
		return r/255, g/255, b/255, a/255
	end
	local function stroke(color, width)
		cr:rgba(hex_color(color or '#ffffff'))
		cr:line_width(width or 1)
		cr:stroke()
	end
	local function fill(color)
		cr:rgba(hex_color(color or '#ffffff'))
		cr:fill()
	end

	local x0 = self.mousex or self.window.client_w/2
	local y0 = self.mousey or self.window.client_h/2

	local dists = {}
	local lens = {}

	local function draw_line(x1,y1,x2,y2,color,width)
		cr:move_to(x1,y1)
		cr:line_to(x2,y2)
		stroke(color,width)
	end

	local function line_hit(x1,y1,x2,y2)
		x2,y2=x1+x2,y1+y2
		cr:rectangle(line.bounding_box(x1,y1,x2,y2)); stroke('#666666')
		draw_line(x1,y1,x2,y2)
		local d,x,y,t = line.hit(x0,y0,x1,y1,x2,y2)
		glue.append(dists,d,x,y,t,line.point(t,x1,y1,x2,y2))

		local ax1,ay1,ax2,ay2, bx1,by1,bx2,by2 =
			line.split(t, x1,y1,x2,y2)
		draw_line(ax1,ay1,ax2,ay2,'#ff000060',10)
		draw_line(bx1,by1,bx2,by2,'#0000ff60',10)

		lens[#dists] = line.length(t,x1,y1,x2,y2)
	end

	local function observed_sweep(sweep_angle)
		return math.max(math.min(sweep_angle, 360), -360)
	end

	local function draw_arc(cx,cy,r,a1,a2,color,width)
		a1,a2 = math.rad(a1), math.rad(observed_sweep(a2))
		if a2 < 0 then
			cr:arc_negative(cx,cy,r,a1,a1+a2)
		else
			cr:arc(cx,cy,r,a1,a1+a2)
		end
		stroke(color,width)
	end

	local function arc_hit(cx,cy,r,a1,a2)
		local x1,y1,x2,y2 = arc.endpoints(cx,cy,r,r,a1,a2)
		cr:rectangle(arc.bounding_box(cx,cy,r,r,a1,a2)); stroke('#666666')
		draw_arc(cx,cy,r,a1,a2)
		local d,x,y,t = arc.hit(x0,y0,cx,cy,r,r,a1,a2)
		glue.append(dists,d,x,y,t,arc.point(t,cx,cy,r,r,a1,a2))

		local acx,acy,ar,ar,aa1,aa2,_, bcx,bcy,br,br,ba1,ba2 =
			arc.split(t,cx,cy,r,r,a1,a2)
		draw_arc(acx,acy,ar,aa1,aa2,'#ff000060',10)
		draw_arc(bcx,bcy,br,ba1,ba2,'#0000ff60',10)

		lens[#dists] = arc.length(t, cx,cy,r,r,a1,a2)
	end

	local function draw_bezier2(x1,y1,x2,y2,x3,y3,color,width)
		cr:move_to(x1,y1)
		cr:curve_to(select(3, bezier2.to_bezier3(x1,y1,x2,y2,x3,y3)))
		stroke(color,width)
	end

	local function bezier2_hit(x1,y1,x2,y2,x3,y3)
		x2,y2,x3,y3=x1+x2,y1+y2,x1+x3,y1+y3
		cr:rectangle(bezier2.bounding_box(x1,y1,x2,y2,x3,y3)); stroke('#666666')
		draw_bezier2(x1,y1,x2,y2,x3,y3)
		local d,x,y,t = bezier2.hit(x0,y0,x1,y1,x2,y2,x3,y3)
		glue.append(dists,d,x,y,t,bezier2.point(t,x1,y1,x2,y2,x3,y3))

		local ax1,ay1,ax2,ay2,ax3,ay3, bx1,by1,bx2,by2,bx3,by3 =
			bezier2.split(t, x1,y1,x2,y2,x3,y3)
		draw_bezier2(ax1,ay1,ax2,ay2,ax3,ay3,'#ff000060',10)
		draw_bezier2(bx1,by1,bx2,by2,bx3,by3,'#0000ff60',10)

		lens[#dists] = bezier2.length(t,x1,y1,x2,y2,x3,y3)
	end

	local function draw_bezier3(x1,y1,x2,y2,x3,y3,x4,y4,color,width)
		cr:move_to(x1,y1)
		cr:curve_to(x2,y2,x3,y3,x4,y4)
		stroke(color,width)
	end

	local function bezier3_hit(x1,y1,x2,y2,x3,y3,x4,y4)
		x2,y2,x3,y3,x4,y4=x1+x2,y1+y2,x1+x3,y1+y3,x1+x4,y1+y4
		cr:rectangle(bezier3.bounding_box(x1,y1,x2,y2,x3,y3,x4,y4)); stroke('#666666')
		draw_bezier3(x1,y1,x2,y2,x3,y3,x4,y4)
		local d,x,y,t = bezier3.hit(x0,y0,x1,y1,x2,y2,x3,y3,x4,y4)
		glue.append(dists,d,x,y,t,bezier3.point(t,x1,y1,x2,y2,x3,y3,x4,y4))

		local ax1,ay1,ax2,ay2,ax3,ay3,ax4,ay4, bx1,by1,bx2,by2,bx3,by3,bx4,by4 =
			bezier3.split(t, x1,y1,x2,y2,x3,y3,x4,y4)
		draw_bezier3(ax1,ay1,ax2,ay2,ax3,ay3,ax4,ay4,'#ff000060',10)
		draw_bezier3(bx1,by1,bx2,by2,bx3,by3,bx4,by4,'#0000ff60',10)

		lens[#dists] = bezier3.length(t,x1,y1,x2,y2,x3,y3,x4,y4)
	end

	line_hit(100, 100, 50, 100)
	line_hit(200, 200, -50, -100)
	line_hit(350, 100, -100, 0)
	line_hit(250, 150, 100, 0)
	line_hit(400, 200, 0, -100)
	line_hit(450, 100, 0, 100)
	line_hit(600, 100, -100, 50)
	line_hit(500, 200, 100, -50)

	arc_hit(100, 300, 50, 0, 90)
	arc_hit(300, 300, 50, -270, 180+45)
	arc_hit(500, 300, 50, 270, -270)
	arc_hit(700, 300, 50, 0, 360 + 90)
	arc_hit(900, 300, 50, 0, -360)

	bezier2_hit(100, 400, 50, 100, 1000, 0) --wide assymetric
	bezier2_hit(100, 500, 2000, 0, 0, 5) --very close sides
	bezier2_hit(100, 550, 0, 0, 1000, 0) --handles on endpoints

	bezier3_hit(100, 600, -500, 10, 1500, 10, 1000, 0) --very close sides
	bezier3_hit(100, 700, 500, -100, 500, -100, 1000, 0) --elevated quad curve

	bezier3_hit(700, 100, 400, 100, -200, 100, 200, 0) --loop
	bezier3_hit(1000, 100, 200, 100, 0, 100, 200, 0) --cusp
	bezier3_hit(1100, 200, -300, 100, 300, 100, 0, 0) --bowl

	bezier3_hit(50, 800, 0, -1000, 2000000, -1000, 2000000, 0) --huge (test precision)
	bezier3_hit(1300, 100, 10000, 0, 10000, 2000000, 0, 2000000) --huge (test precision)

	local mind = 1/0
	local x1,y1,t1,len
	for i=1,#dists,6 do
		local d,x,y,t,x2,y2 = unpack(dists,i,i+5)
		cr:circle(x2,y2,7); stroke('#3333ff')
		cr:circle(x,y,9); stroke('#ff0000')
		if d < mind then
			mind = d
			x1,y1,t1,len=x,y,t,lens[i+5]
		end
	end
	if x1 then
		cr:move_to(x0,y0); cr:line_to(x1,y1); stroke('#ff0000')
		--cr:circle(x1,y1,5); fill('#00ff00')
		cr:move_to(x0+20,y0+24); cr:text_path(string.format('t: %.2f', t1)); fill('#ffffff')
		cr:move_to(x0+20,y0+38); cr:text_path(string.format('length: %.2f', len)); fill('#ffffff')
	end
end

player:play()

