local player = require'cplayer'
local socket = require'socket' --for gettime(), self.clock is not synchronized
local easing = require'easing'

--point on the circle of radius r, at position n, on a circle
--with f positions starting at -90 degrees.
local function point(n, r, f)
	local a = math.rad((n - f / 4) * (360 / f))
	local y = math.sin(a) * r
	local x = math.cos(a) * r
	return x, y
end

function player:analog_clock(t)
	local cx, cy, r
	if t.cx then
		cx, cy, r = t.cx, t.cy, t.r
	else
		--fit clock in a box
		local x, y, w, h = self:getbox(t)
		r = math.min(w, h) / 2
		cx = x + w / 2
		cy = y + h / 2
	end
	local time = t.time or os.date'*t'
	local h = time.hour
	local m = time.min
	local s = time.sec
	local ms = math.floor(socket.gettime() * 1000) % 1000

	--logo
	if t.text then
		self:textbox(cx-r, cy-r, 2*r, 3.2*r,
			t.text,
			'Arial Black,'..math.floor(r/14),
			t.text_color or t.color, 'center', 'center')
	end

	--marker lines
	for i = 0, 59 do
		local x1, y1 = point(i, r, 60)
		local x2, y2 = point(i, r * 0.95 * (i % 5 == 0 and 0.89 or .99), 60)
		self:line(cx + x1, cy + y1, cx + x2, cy + y2,
			t.color,
			i % 5 == 0 and r * .03 or r * .015)
	end

	h = h + m / 60 --adjust hour by minute

	--hour tongue
	local x1, y1 = point(h, r * -.2, 12)
	local x2, y2 = point(h, r * 0.6, 12)
	self:line(cx + x1, cy + y1, cx + x2, cy + y2,
		t.hour_color or t.color,
		r * .08)

	--minute tongue
	local x1, y1 = point(m, r * -.15, 60)
	local x2, y2 = point(m, r * 0.95, 60)
	self:line(cx + x1, cy + y1, cx + x2, cy + y2,
		t.min_color or t.color,
		r * .05)

	--seconds tongue
	local ms1 = 400
	if ms < ms1 then
		s = s - 1 + easing.out_elastic(ms / ms1, 0, 1, 1)
	end
	local x1, y1 = point(s, r * -.15, 60)
	local x2, y2 = point(s, r * 0.73, 60)
	self:line(cx + x1, cy + y1, cx + x2, cy + y2,
		t.sec_color or t.color,
		r * 0.03)
	self:circle(cx + x2, cy + y2, r * 0.09, t.sec_color or t.color)
end

if not ... then

function player:on_render(cr)
	self:analog_clock{
		x = 10, y = 10, w = self.w - 20, h = self.h - 20,
		hour_color = '#eeeeee',
		min_color = '#dddddd',
		sec_color = '#ff0000',
		text_color = '#800000',
		text = 'LUA POWER',
	}
end

player:play()

end
