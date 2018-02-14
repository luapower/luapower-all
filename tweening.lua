
--tween-based animation for UI toolkits
--Written by Cosmin Apreutesei. Public Domain.

--prototype-based dynamic inheritance with __call constructor.
local function object(super)
	local o = {__index = super, __call = super and super.__call}
	return setmetatable(o, o)
end

--module ---------------------------------------------------------------------

local tw = object()

tw.interpolate = {} --{type -> interpolate(t, x1, x2) -> x}
tw.type = {} --{attr -> type}
tw.type_patt = {} --{patt -> type}

function tw:easing(name)
	return require'easing'[name]
end

function tw:clock()
	return require'time'.clock()
end

function tw.__call(super, ...)
	local self = object(super)
	self.interpolate = object(super.interpolate)
	self.type = object(super.type)
	self.type_patt = object(super.type_patt)
	return self
end

function tw.interpolate.number(t, x1, x2)
	return x1 + t * (x2 - x1)
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
	self.running = opt.running
	if not self.start_values then
		self.start_values = {}
		self._start_values_auto = true
		self:get_start_values()
	end
	return self
end

function tw:to(target, duration, easing, values, start)
	return self:tween{target = target, duration = duration, easing = easing,
		values = values, start = start}
end

function tween:get_start_values()
	for k,v in pairs(self.end_values) do
		self.start_values[k] = self.target[k]
	end
end

function tween:_distance(time)
	if self.clamp then
		time = math.max(time, self.start)
		time = math.min(time, self.start + self.duration)
	end
	return self.easing_func(time - self.start, 0, 1, self.duration)
end

function tween:_interpolate(attr, distance, v1, v2)
	local attr_type = self.tw.type[attr]
	if not attr_type then
		for patt, atype in pairs(self.tw.type_patt) do
			if attr:find(patt) then
				attr_type = atype
				self.tw.type[attr] = atype --cache it
			end
		end
	end
	local interpolate = self.tw.interpolate[attr_type or 'number']
	return interpolate(distance, v1, v2)
end

function tween:_value(attr, distance)
	local v1 = self.start_values[attr]
	local v2 = self.end_values[attr]
	return self:_interpolate(attr, distance, v1, v2)
end

function tween:update(time)
	if not self.running then return end
	local distance = self:_distance(time)
	for attr in pairs(self.end_values) do
		self.target[attr] = self:_value(attr, distance)
	end
end

function tween:seek(time)
	return self:update(self.start + time)
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

function timeline:add(tween, start)
	table.insert(self.tweens, tween)
	tween.rel_start = start or self.duration
	self:_tween_changed(tween)
	return self
end

function timeline:to(...)
	return self:add(self.tw:to(...))
end

function timeline:update(dt)
	if not self.running then return end
	for _,tween in ipairs(self.tweens) do
		--if tween:running(dt)
	end
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

function tween:seek(time)
	return self:update(self.start + time)
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
	for _,tween in ipairs(self.tweens) do
		--
	end
end


--tests ----------------------------------------------------------------------

if not ... then

local tw = tw()

tw.type.color = 'color'
tw.type_patt['_color$'] = 'color'

function tw.interpolate.color(t, c1, c2)
	local r1, g1, b1, a1 = unpack(c1)
	local r2, g2, b2, a2 = unpack(c2)
	local r = tw.interpolate.number(t, r1, r2)
	local g = tw.interpolate.number(t, g1, g2)
	local b = tw.interpolate.number(t, b1, b2)
	local a = tw.interpolate.number(t, a1, a2)
	return {r, g, b, a}
end

local o = {x = 0, y = 0, x_color = {1, 0, 0, 0}}
local t1 = tw:tween{
	values = {x = 100, y = 500, x_color = {0, 0.5, 1, 1}},
	target = o, duration = 1
}
t1:update(tw:clock() + 0.25)
pp(o)

end

return tw
