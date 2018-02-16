
--tweening for animation
--Written by Cosmin Apreutesei. Public Domain.

--prototype-based dynamic inheritance with __call constructor from glue.
local function object(super, o)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	return setmetatable(o, o)
end

local function opt_object(super, o)
	return o and object(super, o) or super
end

local function clamp(x, min, max)
	return math.min(math.max(x, min), max)
end

--remove all false entries from an array efficiently.
local function cleanup(t)
	local j
	--bubble up all false entries
	for i=1,#t do
		if not t[i] then
			j = j or i
		elseif j then
			t[j] = t[i]
			t[i] = false
			j = j + 1
		end
	end
	--remove false entries
	if j then
		for i=#t,j,-1 do
			t[i] = nil
		end
		assert(#t == j-1)
	end
end

--module ---------------------------------------------------------------------

local tw = object()

tw.interpolate = {} --{type -> interpolate_function}
tw.value_semantics = {} --{type -> true|false}
tw.attr_types = {} --{attr -> type}
tw.attr_type_patterns = {} --{patt|func(attr) -> type}

function tw:ease_function(name)
	return require'easing'[name]
end

function tw:_attr_type(attr_type, attr)
	local attr_type = attr_type or self.attr_types[attr]
	if not attr_type then
		for patt, atype in pairs(self.attr_type_patterns) do
			if (type(patt) == 'string' and attr:find(patt))
				or (type(patt) ~= 'string' and patt(attr))
			then
				attr_type = atype
				break
			end
		end
		attr_type = attr_type or 'number'
		self.attr_types[attr] = attr_type --cache it
	end
	return attr_type
end

function tw:interpolation_function(attr_type, attr)
	local atype = self:_attr_type(attr_type, attr)
	local interpolate = self.interpolate[atype]
	local value_semantics = self.value_semantics[atype]
	if value_semantics == nil then
		value_semantics = true
	end
	return interpolate, value_semantics
end

function tw:current_clock()
	return require'time'.clock()
end

function tw:freeze()
	self._clock = self:current_clock()
end

function tw:unfreeze()
	self._clock = false
end

function tw:clock()
	if self._clock then
		return self._clock
	else
		return self:current_clock()
	end
end

function tw.__call(super, ...)
	local self = object(super)
	self._clock = false --avoid inheriting it
	self.interpolate = object(super.interpolate)
	self.value_semantics = object(super.value_semantics)
	self.attr_types = object(super.attr_types)
	self.attr_type_patterns = object(super.attr_type_patterns)
	return self
end

--interpolators --------------------------------------------------------------

function lerp(d, x1, x2)
	return x1 + d * (x2 - x1)
end

function tw.interpolate.number(d, x1, x2)
	return lerp(d, tonumber(x1), tonumber(x2))
end

function tw.interpolate.integer(d, i1, i2)
	return math.floor(lerp(d, tonumber(i1), tonumber(i2)) + 0.5)
end

function tw.interpolate.number_list(d, t1, t2, t)
	t = t or {}
	for i=1,math.min(#t1, #t2) do
		t[i] = lerp(d, t1[i], t2[i])
	end
	return t
end
tw.value_semantics.number_list = false

function tw.interpolate.number_table(d, t1, t2, t)
	t = t or {}
	for k,v in pairs(t1) do
		t[k] = lerp(d, v, t2[k])
	end
	return t
end
tw.value_semantics.point = false

--tweens ---------------------------------------------------------------------
--A tween updates a single attribute value on a single target object.

local tween = object()
tw.tween = tween

--timing model
tween.start = 0
tween.timeline = nil --if set, start is relative to timeline.start
tween.duration = 1 --loop duration; can't be negative
tween.ease = 'in_out_quad'
tween.ease_function = nil --set to tw:ease_function(ease)
tween.delay = 0 --start delay; can be negative
tween.speed = 1 --speed factor; can't be 0, can't be < 0
tween.direction = 'alternate' --'normal', 'reverse', 'alternate-reverse'
tween.loop = 1 --repeat count; use 1/0 for infinite; can be fractional
tween.loop_start = 0 --aka progress_start; can be fractional, negative, > 1
tween.running = true --set to false to start paused
tween.paused_clock = nil --set when pausing to advance start when resuming

--animation model
tween.target = nil --used as v = target[attr] and target[attr] = v
tween.attr = nil
tween.start_value = nil --value at progress 0
tween.end_value = nil --value at progress 1
tween.attr_type = nil
tween.interpolate = nil --custom interpolation function
tween.value_semantics = nil --the interpolator has value semantics

--constructor

function tween:__call(tw, o)
	local self = object(self, o)
	self.tw = tw
	self:reset()
	return self
end

function tween:reset()
	self:_init_timing_model()
	self:_init_animation_model()
end

--timing model

function tween:_init_timing_model()
	if self.running and not self.timeline then
		self.start = self:clock()
	end
	if type(self.ease) == 'string' then
		self.ease_function = self.tw:ease_function(self.ease)
	else
		self.ease_function = self.ease
	end
end

function tween:clock()
	return self.tw:clock()
end

function tween:start_clock()
	return self.start + (self.timeline and self.timeline:start_clock() or 0)
end

--minimum duration needed for fitting into a timeline.
function tween:loop_duration()
	local min_loop_count =
		(self.direction == 'alternate'
		or self.direction == 'alternate-reverse') and 2 or 1
	return self.delay / self.speed
		+ self.duration / self.speed * math.min(self.loop, min_loop_count)
end

function tween:total_duration()
	return self.delay / self.speed + self.duration / self.speed * self.loop
end

function tween:end_clock()
	return self:start_clock() + self:total_duration()
end

function tween:is_infinite()
	return self:total_duration() == 1/0
end

--returns where the entire animation is in the 0..1 interval.
--returns 0 for infinite tweens on any clock.
function tween:_total_progress(clock)
	clock = clock or self:clock()
	return (clock - self:start_clock()) / self:total_duration()
end

function tween:status(clock)
	local p = self:_total_progress(clock)
	return p < 0 and 'not_started' or p > 1 and 'finished'
		or self.running and 'running' or 'paused'
end

function tween:total_progress(clock)
	return clamp(self:_total_progress(clock), 0, 1)
end

--always returns the start clock for infinite tweens.
function tween:clock_at(total_progress)
	return self:start_clock() + self:total_duration() * total_progress
end

--check if the progress on the current iteration should increase or decrease.
function tween:is_forward(i)
	if self.direction == 'normal' then
		return true
	elseif self.direction == 'reverse' then
		return false
	elseif self.direction == 'alternate' then
		return i % 2 == 0
	elseif self.direction == 'alternate-reverse' then
		return i % 2 == 1
	end
end

--linear progress within current iteration in 0..1 (so excluding repeats)
--and the iteration number counting from math.floor(loop_start).
function tween:progress(clock)
	clock = clock or self:clock()
	local time_in = clock - (self:start_clock() + self.delay / self.speed)
	local p = time_in / (self.duration / self.speed)
	local p = self.loop_start + clamp(p, 0, self.loop)
	local i = math.floor(p)
	local p = p - i
	if not self:is_forward(i) then
		p = 1 - p
	end
	return p, i
end

--non-linear (eased) progress within current iteration (can exceed 0..1).
function tween:distance(progress, loop_index)
	return self.ease_function(progress, 0, 1, 1)
end

function tween:pause()
	if not self.running then return end
	self.running = false
	self.paused_clock = self:clock()
	return self
end

function tween:resume()
	if self.running then return end
	self.start = self.start + (self:clock() - self.paused_clock)
	self.paused_clock = false
	self.running = true
	return self
end

function tween:restart()
	--TODO
	self.start = self.start + (self:clock() - self.paused_clock)
	self.paused_clock = false
	self.running = true
	return self
end

--animation model

function tween:_init_animation_model()
	if not self.interpolate or self.auto_interpolate then
		self.interpolate, self.value_semantics =
			self.tw:interpolation_function(self.attr_type, self.attr)
		self.auto_interpolate = true
	end
	if not self.start_value
		or not self.end_value
		or self.auto_start_value
		or self.auto_end_value
	then
		local v = self.target[self.attr]
		if not self.value_semantics then
			v = self.interpolate(1, v, v)
		end
		if not self.start_value or self.auto_start_value then
			self.start_value = v
			self.auto_start_value = true
		end
		if not self.end_value or self.auto_end_value then
			self.end_value = v
			self.auto_end_value = true
		end
	end
end

function tween:update(clock)
	if not self.running then return end
	local d = self:distance(self:progress(clock))
	if self.value_semantics then
		self.target[self.attr] =
			self.interpolate(d, self.start_value, self.end_value)
	else
		self.interpolate(d, self.start_value, self.end_value,
			self.target[self.attr])
	end
end

--note: always seeks at the beginning for infinite tweens.
function tween:seek(total_progress)
	self:update(self:clock_at(total_progress))
end

--turn a tween into a tweenable object with the attribute `total_progress`
--tweenable in 0..1.
function tween:totarget()
	assert(not self:is_infinite())
	local t = {}
	setmetatable(t, t)
	function t.__index(t, k)
		if k == 'total_progress' then
			return self:total_progress() --only queried on tween creation
		end
	end
	function t.__newindex(t, k, v)
		if k == 'total_progress' then
			self:seek(v)
		end
	end
	return t
end

--timeline -------------------------------------------------------------------
--A timeline is a tween which tweens a list of tweens.

local timeline = object()
tw.timeline = timeline

for k,v in pairs(tween) do
	timeline[k] = v --statically inherit tween's fields
end

timeline.duration = 0
timeline.ease = 'linear'
timeline.auto_duration = true --auto-increase duration to include all tweens
timeline.auto_loop = true --set loop to infinite when adding infinite tweens
timeline.auto_remove = true --remove tweens automatically when finished

function timeline:reset()
	self:_init_timing_model()
	self.tweens = self.tweens or {}
	for i,tween in ipairs(self.tweens) do
		tween:reset()
	end
end

function timeline:tweens_total_duration(exclude_infinite_tweens)
	local start_clock = self:start_clock()
	local end_clock = start_clock
	for i,tween in ipairs(self.tweens) do
		if not (exclude_infinite_tweens and tween:is_infinite()) then
			end_clock = math.max(end_clock, tween:end_clock())
			if end_clock == 1/0 then
				break
			end
		end
	end
	return end_clock - start_clock
end

function timeline:_adjust(new_tween)
	if self.auto_duration then
		local tween_end_clock =
			new_tween:start_clock() + new_tween:loop_duration()
		local duration = tween_end_clock - self:start_clock()
		self.duration = math.max(self.duration, duration)
	end
	if self.auto_loop and new_tween:is_infinite() then
		self.loop = 1/0
	end
end

function timeline:add(tween, start)
	table.insert(self.tweens, tween)
	tween.start = start or self.duration
	tween.timeline = self
	self:_adjust(tween)
	return self
end

function timeline:remove(what)
	local found
	for i,tween in ipairs(self.tweens) do
		if what == tween.attr
			or what == tween.target
			or what == tween
		then
			if tween.remove then --recurse
				tween:remove(what)
			end
			self.tweens[i] = false
			found = true
		end
	end
	if found then
		cleanup(self.tweens)
	end
end

function timeline:clear()
	self.tweens = {}
end

--timing model

function timeline:status()
	if #self.tweens == 0 then
		return 'empty'
	end
	return tween.status(self)
end

--animation model

function timeline:update(clock)
	if not self.running then return end
	if #self.tweens == 0 then return end
	local d = self:distance(self:progress(clock))
	local found
	for i,tween in ipairs(self.tweens) do
		tween:update(clock)
		if self.auto_remove and tween:status(clock) == 'finished' then
			self.tweens[i] = false
			found = true
		end
	end
	if found then
		cleanup(self.tweens)
	end
end

--sugar APIs -----------------------------------------------------------------

function tw:to(target, duration, easing, end_values, start, loop)
	return self:tween{target = target, duration = duration, easing = easing,
		end_values = end_values, start = start, loop = loop}
end

function tw:from(target, duration, easing, start_values, start, loop)
	return self:tween{target = target, duration = duration, easing = easing,
		start_values = start_values, start = start, loop = loop}
end

--tests ----------------------------------------------------------------------

if not ... then

local tw = tw()

tw.attr_type_patterns['_color$'] = 'number_list'

local o = {x = 0, y = 200, x_color = {1, 0, 0, .5}, i = 0}

tw:freeze()
local tx = tw:tween{target = o, attr = 'x', end_value = 100, loop = 2, ease = 'out_elastic'}
local ty = tw:tween{target = o, attr = 'y', end_value = 0, loop = 2, ease = 'out_elastic'}
local tc = tw:tween{target = o, attr = 'x_color', end_value = {0, 0, 1, 1},
	loop = 2, duration = 1, ease = 'linear'}
local ti = tw:tween{target = o, attr = 'i', end_value = 100,
	attr_type = 'integer'}

local tl = tw:timeline()
tw:unfreeze()

tl.auto_remove = false
tl:add(tx, 0.1):add(ty, 0.2):add(tc, 0) --:add(ti)

local nw = require'nw'

local win = nw:app():window{x = 600, y = 400, w = 800, h = 500}

function win:repaint()
	local cr = self:bitmap():cairo()
	cr:rgb(0, 0, 0)
	cr:paint()

	tl:update()

	cr:rectangle(o.x + 100, o.y + 100, 100, 100)
	cr:rgba(unpack(o.x_color))
	cr:fill_preserve()
	cr:rgba(1, 1, 1, 1)
	cr:stroke()

	if tl:status() == 'running' then
		self:invalidate()
	else
		print'done'
		tl:reset()
		self:invalidate()
	end
end

nw:app():run()

end

return tw
