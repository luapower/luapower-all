local tw = require'tweening'
local cplayer = require'cplayer'
--local nw = require'nw'

local tw = tw()

tw.type['_color$'] = 'list'

local targets = {
	{name = '1', x =   0, y = 100, a = math.rad(90), x_color = {1, 0, 1, .5}},
	{name = '2', x =   0, y = 200, a = math.rad(90), x_color = {1, 1, 0, .5}},
	{name = '3', x = 100, y = 100, a = math.rad(90), x_color = {0, 1, 1, .5}},
	{name = '4', x = 100, y = 200, a = math.rad(90), x_color = {0, 1, 0, .5}},
}
local o = targets[1]

tw:clock(math.floor(tw:clock()))
local tx = tw:tween{name = 'tx', target = o, attr = 'x', to = 1000, duration = 2, loop = 1.2}
local ty = tw:tween{name = 'ty', target = o, attr = 'y', to = '+=50', duration = 2, loop = 2.5}
local ta = tw:tween{name = 'ta', target = o, attr = 'a', to = '+=90deg_cw',
	duration = 2, loop = 5, offset = 0.5, speed = 2, way = 'inout'}
local tl = tw:timeline{name = 'tl'}
local tl2 = tw:timeline{name = 'tl2'}
--tl:pause()
tw:clock(false)

tl.auto_remove = false
tl2.auto_remove = false
--tl:add(ta, '+=500ms'):add(tl2:add(tx):add(ty, 1), 0)
tl2.duration = 3
--tl.duration = 4

math.randomseed(require'time'.clock())

local tl = tw:timeline{name = 'tl', loop = 2, ease = 'quad', way = 'out',
	tween_progress = true,
	auto_remove = false,
}
tl:add{
	targets = targets,
	cycle_to = {
		y = {'+=100', '-=100'},
		x = {'+=800', '+=700'},
		a = {'+=270deg', '-=270deg'}
	},
	loop = 1, ease = 'slowmo', duration = 2,
	start = '+=1500ms',
}

for i,t in ipairs(tl.tweens) do
	t.start = math.random()
	if t.attr == 'a' then
		t.ease = 'elastic'
		t.way = 'outin'
	end
	t:reset()
end

cplayer.x = 10
cplayer.w = 1900

local fit_width

function cplayer:on_render(cr)

	if self.key == 'left' then
		tl.clock = tl.clock - 0.2
	elseif self.key == 'right' then
		tl.clock = tl.clock + 0.2
	end

	fit_width = self:togglebutton{id = 'fit_width', x = 680, y = 10, w = 60, h = 26, selected = fit_width}

	local function ui(t, x)
		local name = (t.attr and t.attr..t.target.name or t.name) .. '.'
		local y = 10
		local w = 200
		local i0, i1 = -10, 10
		local pos_text
		if not t.timeline then
			local clock = tw:clock()
			i0 = clock - 10
			i1 = clock + 10
		end

		t.start = self:slider{id = name..'start', x = x, y = y, w = w, h = 26, i = t.start, i0 = i0, i1 = i1, step = 1/16}
		y = y + 30
		t.duration = self:slider{id = name..'duration', x = x, y = y, w = w - 50, h = 26,
			i = t.duration, i1 = 4, step = 1/8}
		t.duration = self:togglebutton{
			id = name..'duration_inf', text = '1/0', x = x + w - 45, y = y, w = 45, h = 26, selected = t.duration == 1/0}
			and 1/0 or t.duration
		y = y + 30
		t.loop = self:slider{id = name..'loop', x = x, y = y, w = w - 50, h = 26, i = t.loop, i1 = 4, step = 1/8}
		t.loop = self:togglebutton{
			id = name..'loop_inf', text = '1/0', x = x + w - 45, y = y, w = 45, h = 26, selected = t.loop == 1/0}
			and 1/0 or t.loop
		y = y + 30
		t.offset = self:slider{id = name..'offset', x = x, y = y, w = w, h = 26, i = t.offset,
			i1 = 4, step = 1/8}
		y = y + 30
		t.yoyo = self:togglebutton{id = name..'yoyo', x = x, y = y, w = w / 2 - 2.5, h = 26, selected = t.yoyo}
		t.backwards = self:togglebutton{id = name..'backwards', x = x + w / 2 + 2.5, y = y, w = w / 2, h = 26,
			selected = t.backwards}
		y = y + 30
		t.speed = self:slider{id = name..'speed', x = x, y = y, w = w, h = 26, i = t.speed, i0 = -2, i1 = 2, step = 1/8}
		if math.abs(t.speed) < 0.01 then
			--t.speed = 0.01
		end
		y = y + 30
		t.ease = self:mbutton{id = name..'ease', x = x, y = y, w = w, h = 26,
			values = require'easing'.names, selected = t.ease}
		y = y + 30
		t.way = self:mbutton{id = name..'way', x = x, y = y, w = w, h = 26,
			values = {'in', 'out', 'inout', 'outin'}, selected = t.way}
		y = y + 30
		local bw = w/5
		if self:button{id = name..'pause', x = x, y = y, w = bw, h = 26} then
			t:pause()
		end
		if self:button{id = name..'resume', x = x + 1*bw, y = y, w = bw, h = 26} then
			t:resume()
		end
		if self:button{id = name..'reverse', x = x + 2*bw, y = y, w = bw, h = 26} then
			t:reverse()
		end
		if self:button{id = name..'restart', x = x + 3*bw, y = y, w = bw, h = 26} then
			t:restart()
		end
		if self:button{id = name..'reset', x = x + 4*bw, y = y, w = bw, h = 26} then
			t:reset()
		end

		y = y + 30
		local progress = self:slider{id = name..'progress',
			text = self.active == name..'progress' and 'seeking' or t:status(),
			x = x, y = y, w = w, h = 26,
			i = t:progress(), i1 = 1, step = 0.0001
		}
		if self.active == name..'progress' then
			t:seek(progress)
		end

		y = y + 30
		local loop_progress = self:slider{id = name..'loop_progress',
			text = self.active == name..'loop_progress' and 'seeking' or t:status(),
			x = x, y = y, w = w, h = 26,
			i = t:loop_progress(), i1 = t.loop, step = 0.0001
		}
		if self.active == name..'loop_progress' then
			t:loop_seek(loop_progress)
		end

		if not self.active and tl:status() == 'finished' then
			--tl:restart()
		end

		y = y + 36
		self:label{x = x, y = y, w = w, h = 26, text = 'total duration: ' .. t:total_duration()}
		y = y + 20
		self:label{x = x, y = y, w = w, h = 26, text = 'progress: ' .. t:progress()}
		y = y + 20
		local p = t:loop_progress()
		self:label{x = x, y = y, w = w, h = 26, text = 'loop_progress: ' .. p}
		y = y + 20
		self:label{x = x, y = y, w = w, h = 26, text = 'distance: ' .. t:distance()}
		y = y + 20

		if t.tweens ~= nil then
			t.tween_progress = self:togglebutton{id = name..'tween_progress',
				x = x, y = y, w = w, h = 26, selected = t.tween_progress}

			for i,tween in ipairs(t.tweens) do
				x = x + w + 10
				ui(tween, x)
			end
		end
	end
	tl:update()
	ui(tl, 10)

	local function draw_tween(t, start)
		local lw = .02
		local start = t.start - start
		local dir = t.speed >= 0 and 1 or -1
		local max_duration = math.min(10, math.abs(t:total_duration())) * dir

		--start
		cr:rgb(.5, .5, 1)
		cr:rectangle(start - lw/2, 0, lw, -1); cr:fill()

		--end
		cr:rgb(.5, .5, 1)
		cr:rectangle(start - lw/2 + max_duration, 0, lw, -1); cr:fill()

		--total duration
		cr:rgb(1, 0, 0)
		cr:rectangle(start - lw/2, -1, max_duration, lw); cr:fill()

		--distance
		cr:translate(start, 0)
		cr:move_to(0, 0)
		cr:rgb(1, 1, 1)
		for duration = 0, max_duration, 0.01 * dir do
			local clock = t.start + duration
			local y = t:distance(clock)
			local x = duration
			cr:line_to(x, -y)
		end
		local x, y = cr:current_point()
		cr:rel_line_to(0, -y)
		cr:close_path()
		cr:fill()
		cr:translate(-start, 0)

		--clock marker
		local p = t:loop_progress()
		local clock = t:loop_clock_at(p)
		local d = t:distance()
		local s = t:status()
		cr:rgb(1, s == 'finished' and 1 or 0, s == 'not_started' and 1 or 0)
		cr:rectangle(start + clock - t.start - lw/2, 0, lw, -1); cr:fill()
		cr:circle(start + clock - t.start, -d, lw*1.5); cr:fill()

		--child tweens
		if t.tweens then
			cr:translate(start, 0)
			for i,tween in ipairs(t.tweens) do
				cr:translate(0, 1.05)
				draw_tween(tween, 0)
			end
		end
	end
	cr:identity_matrix()
	cr:translate(1100, 110)
	cr:scale(100, 50)
	if fit_width and not tl:is_infinite() then
		cr:scale((self.w - 800) / 200 / tl:total_duration(), 1)
	end
	draw_tween(tl, tl.start)

	--moving square
	for i,o in ipairs(targets) do
		cr:identity_matrix()
		cr:translate(100, 300)
		cr:rotate_around(o.x + 50, o.y + 50, o.a)
		cr:rectangle(o.x, o.y, 100, 100)
		cr:circle(o.x + 100, o.y + 50, 10, 10)
		cr:rgba(unpack(o.x_color))
		cr:fill_preserve()
		cr:rgba(1, 1, 1, 1)
		cr:stroke()
	end

	self:invalidate()
end

cplayer:play()
