
--tweening module for vector-based animation
--Written by Cosmin Apreutesei. Public Domain.

--prototype-based dynamic inheritance with __call constructor.
local function object(super, o)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	return setmetatable(o, o)
end

local function opt_object(super, o)
	return o and object(super, o) or super
end

--module ---------------------------------------------------------------------

local tw = object()

tw.interpolate = {} --{type -> interpolate(t, x1, x2) -> x}
tw.types = {} --{attr -> type}
tw.type_patterns = {} --{patt|func -> type}

function tw:easing(name)
	return require'easing'[name]
end

function tw:clock()
	return require'time'.clock()
end

function tw.__call(super, ...)
	local self = object(super)
	self.interpolate = object(super.interpolate)
	self.types = object(super.types)
	self.type_patterns = object(super.type_patterns)
	return self
end

--interpolators --------------------------------------------------------------

function lerp(t, x1, x2)
	return x1 + t * (x2 - x1)
end

function tw.interpolate.number(t, x1, x2)
	return lerp(t, tonumber(x1), tonumber(x2))
end

function tw.interpolate.integer(t, i1, i2)
	return math.floor(lerp(t, tonumber(i1), tonumber(i2)) + 0.5)
end

function tw.interpolate.color(t, c1, c2, c)
	local r1, g1, b1, a1 = unpack(c1)
	local r2, g2, b2, a2 = unpack(c2)
	c = c or {}
	c[1] = lerp(t, r1, r2)
	c[2] = lerp(t, g1, g2)
	c[3] = lerp(t, b1, b2)
	if a1 then
		c[4] = lerp(t, a1, a2)
	end
	return c
end

function tw.interpolate.point(t, p1, p2, p)
	p = p or {}
	p.x = lerp(t, p1.x, p2.x)
	p.y = lerp(t, p1.y, p2.y)
	if p1.z then
		p.z = lerp(t, p1.z, p2.z)
	end
	return p
end

--tween ----------------------------------------------------------------------

local tween = object()
tw.tween = tween

tween.speed = 1
tween.easing = 'linear'
tween.running = true

function tween:__call(tw, opt)
	local self = object(self)
	self.tw = tw
	self.start = opt.start or self.tw:clock()
	self.duration = opt.duration
	self.easing = opt.easing
	self.easing_func = self.tw:easing(self.easing) or self.easing
	self.start_values = opt.start_values
	self.end_values = opt.values
	self.target = opt.target
	self.clamp = opt.clamp
	self.speed = opt.speed
	self.loop = opt.loop
	self.running = opt.running
	if not self.start_values then
		self.start_values = {}
		self._start_values_auto = true
		self:get_start_values()
	end
	self.interpolate = opt_object(self.tw.interpolate, opt.interpolate)
	self.types = opt_object(self.tw.types, opt.types)
	self.type_patterns = opt_object(self.tw.type_patterns, opt.type_patterns)
	return self
end

function tween:clone(start)
	local o = object(self)
	o.start = start or self.tw:clock()
	if self._start_values_auto then
		self.start_values = {}
		self:get_start_values()
	end
	return o
end

function tw:to(target, duration, easing, values, start, loop)
	return self:tween{target = target, duration = duration, easing = easing,
		values = values, start = start, loop = loop}
end

function tween:get_start_values()
	for k,v in pairs(self.end_values) do
		self.start_values[k] = self.target[k]
	end
end

function tween:_distance(time)
	time = time or self.tw:clock()
	if self.clamp then
		time = math.max(time, self.start)
		time = math.min(time, self.start + self.duration)
	end
	return self.easing_func(time - self.start, 0, 1, self.duration)
end

function tween:_interpolate(attr, distance, v1, v2, vout)
	local attr_type = self.types[attr]
	if not attr_type then
		for patt, atype in pairs(self.type_patterns) do
			local found
			if (type(patt) == 'string' and attr:find(patt))
				or (not type(patt) == 'string' and patt(attr))
			then
				attr_type = atype
				self.types[attr] = atype --cache it
			end
		end
	end
	local interpolate = self.interpolate[attr_type or 'number']
	return interpolate(distance, v1, v2, vout)
end

function tween:_value(attr, distance)
	local v1 = self.start_values[attr]
	local v2 = self.end_values[attr]
	local vout = self.target[attr]
	return self:_interpolate(attr, distance, v1, v2, vout)
end

function tween:progress(distance)
	if not self.running then
		return self.current_distance
	end
	self.current_distance = distance or self:_distance()
	for attr in pairs(self.end_values) do
		self.target[attr] = self:_value(attr, self.current_distance)
	end
	return self.current_distance
end

function tween:seek(rel_time)
	return self:progress(self:_distance(self.start + rel_time))
end

function tween:pause()
	self.running = false
end

function tween:resume()
	self.running = true
end

function tween:reverse()
	self.speed = -self.speed
end

function tween:restart(time)
	self.start = time or self.tw:clock()
	if self._start_values_auto then
		self:get_start_values()
	end
end

--timeline -------------------------------------------------------------------

local timeline = object()
tw.timeline = timeline

timeline.speed = 1
timeline.running = false

function timeline:__call(tw, opt)
	local self = object(self)
	self.tw = tw
	self.start = opt.start or self.tw:clock()
	self.duration = 0
	self.speed = opt.speed
	self.running = opt.running
	self.tweens = {}
	return self
end

function timeline:add(tween, rel_start)
	table.insert(self.tweens, tween)
	tween.rel_start = rel_start or self.duration
	self:_tween_changed(tween)
	return self
end

function timeline:to(target, duration, easing, values, rel_start)
	local tween = self.tw:to(target, duration, easing, values, 0)
	return self:add(tween, rel_start)
end

function timeline:progress(time)
	if not self.running then return end
	if not time then
		return self.current_time
	end
	for _,tween in ipairs(self.tweens) do
		--if tween:running(dt)
	end
	self.current_time = time
end

function timeline:_tween_changed(tween)
	self.duration = math.max(self.duration, tween.start + tween.duration)
end

function timeline:_update_duration()
	self.duration = 0
	for _,tween in ipairs(self.tweens) do
		if tween._update_duration then
			tween:_update_duration()
			self:_tween_changed(tween)
		end
	end
end

function timeline:pause()
	self.running = false
end

function timeline:resume()
	self.running = true
end

function timeline:reverse()
	self.speed = -self.speed
end

function timeline:restart(time)
	self.start = time or self.tw:clock()
	for _,tween in ipairs(self.tweens) do
		--
	end
end


--tests ----------------------------------------------------------------------

if not ... then

local tw = tw()

tw.type_patterns['_color$'] = 'color'

local o = {x = 0, y = 1000, x_color = {1, 0, 0, 0}, i = 0}
local t1 = tw:tween{
	values = {x = 100, y = 0, x_color = {0, 0.5, 1, 1}, i = 100},
	target = o, duration = 1,
	types = {i = 'integer'},
}
t1:seek(0.26)
pp(o)

end

return tw
