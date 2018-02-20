
--tweening for animation
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tweening_demo' end

--prototype-based dynamic inheritance with __call constructor from glue.
local function object(super, o)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	return setmetatable(o, o)
end

local function clamp(x, min, max) --from glue
	return math.min(math.max(x, min), max)
end

local function lerp(x, x0, x1, y0, y1)
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
end

local function lerp01(d, x1, x2)
	return x1 + d * (x2 - x1)
end

--remove all false entries from an array efficiently.
local function cleanup(t)
	local j
	--move false entries to the end
	for i=1,#t do
		if not t[i] then
			j = j or i
		elseif j then
			t[j] = t[i]
			t[i] = false
			j = j + 1
		end
	end
	--remove false entries without creating gaps
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
tw._type = {} --{attr -> type}
tw.type = {} --{patt|func(attr) -> type}

function tw.__call(super)
	local self = object(super)
	self._clock = false --avoid inheriting it
	self.interpolate = object(super.interpolate)
	self.value_semantics = object(super.value_semantics)
	self._type = object(super._type)
	self.type = object(super.type)
	return self
end

--note: loop_index is not used here but overrides of ease() could use it.
function tw:ease(ease, way, progress, loop_index)
	local easing = require'easing'
	return easing.ease(ease, way, progress)
end

function tw:_attr_type(attr_type, attr)
	local attr_type = attr_type or self._type[attr]
	if not attr_type then
		for patt, atype in pairs(self.type) do
			if (type(patt) == 'string' and attr:find(patt))
				or (type(patt) ~= 'string' and patt(attr))
			then
				attr_type = atype
				break
			end
		end
		attr_type = attr_type or 'number'
		self._type[attr] = attr_type --cache it
	end
	return attr_type
end

function tw:interpolation_function(attr_type, attr)
	local attr_type = self:_attr_type(attr_type, attr)
	local interpolate = self.interpolate[attr_type]
	local value_semantics = self.value_semantics[attr_type]
	if value_semantics == nil then
		value_semantics = true
	end
	return interpolate, value_semantics
end

function tw:current_clock()
	return require'time'.clock()
end

function tw:clock(clock)
	if clock ~= nil then
		self._clock = clock
	end
	return self._clock or self:current_clock()
end

--interpolators --------------------------------------------------------------

function tw.interpolate.number(d, x1, x2)
	return lerp01(d, tonumber(x1), tonumber(x2))
end

function tw.interpolate.integer(d, i1, i2)
	return math.floor(lerp(d, tonumber(i1), tonumber(i2)) + 0.5)
end

function tw.interpolate.list(d, t1, t2, t) --colors, unpacked coord lists...
	t = t or {}
	for i=1,math.min(#t1, #t2) do
		t[i] = lerp(d, t1[i], t2[i])
	end
	return t
end
tw.value_semantics.list = false

--tweens ---------------------------------------------------------------------
--A tween updates a single attribute value on a single target object.

local tween = object()
tw.tween = tween

--timing model / definition
tween.start = nil --start time
tween.timeline = nil --if set, start is relative to timeline.start
tween.duration = 1 --loop duration; can't be negative
tween.ease = 'quad' --function `f(t) -> d` or name from easing module
tween.way = 'in' --easing way: 'in', 'out', 'inout', 'outin'
tween.delay = 0 --start delay; can be negative
tween.speed = 1 --speed factor; can't be 0, can't be < 0
tween.backwards = false --first iteration is backwards
tween.yoyo = false --alternate between forward and backwards on each iteration
tween.loop = 1 --repeat count; use 1/0 for infinite; can be fractional
tween.loop_start = 0 --aka progress_start; can be fractional, negative, > 1
--timing model / state
tween.running = true --set to false to start paused
tween.clock = nil --current time
tween.resume_clock = nil --resume time

--animation model / definition
tween.target = nil --used as v = target[attr] and target[attr] = v
tween.attr = nil
tween.start_value = nil --value at progress 0
tween.end_value = nil --value at progress 1
tween.type = nil
tween.interpolate = nil --custom interpolation function
tween.value_semantics = nil --false for avoiding allocations on update

--constructor

function tween:__call(tweening, o)
	local self = object(self, o)
	self.tweening = tweening
	self:reset()
	return self
end

function tween:reset()
	self:_init_timing_model()
	self:_init_animation_model()
end

--timing model / definition

function tween:_init_timing_model()
	self.start = self.start or self.tweening:clock()
	self.clock = self.clock or self.start
	if not self.running and not self.resume_clock then
		self.resume_clock = self.clock
	end
end

--returns true if the tween is the identity tween,
--i.e. that the distance simplifies to (clock - start) / duration.
function tween:is_identity()
	return self.delay == 0 and self.speed == 1 and self.ease == 'linear'
		and not self.backwards and not self.yoyo and self.loop == 1
		and self.loop_start == 0
end

function tween:total_duration()
	return (self.delay + self.duration * self.loop) * (1 / self.speed)
end

function tween:end_clock()
	return self.start + self:total_duration()
end

function tween:is_infinite()
	return self:total_duration() == 1/0
end

--always returns the start clock for infinite tweens.
function tween:clock_at(total_progress)
	return self.start + self:total_duration() * total_progress
end

--check if the progress on a certain iteration should increase or decrease.
function tween:is_backwards(i)
	if self.yoyo then
		return i % 2 == (self.backwards and 0 or 1)
	else
		return self.backwards
	end
end

--timing model / state-depending

--returns where the entire animation is in the 0..1 interval.
--returns 0 for infinite tweens on any clock.
function tween:_total_progress()
	return (self.clock - self.start) / self:total_duration()
end

function tween:total_progress()
	return clamp(self:_total_progress(), 0, 1)
end

function tween:status()
	local p = self:_total_progress()
	return p < 0 and 'not_started' or p > 1 and 'finished'
		or self.running and 'running' or 'paused'
end

--linear progress within current iteration in 0..1 (so excluding repeats)
--and the iteration number counting from math.floor(loop_start).
function tween:progress(clock)
	local clock = clock or self.clock
	local inv_speed = 1 / self.speed
	local time_in = clock - (self.start + self.delay * inv_speed)
	local p = time_in / (self.duration * inv_speed)
	local p = self.loop_start + clamp(p, 0, self.loop)
	local i = math.floor(p)
	local p = p - i
	if self:is_backwards(i) then
		p = 1 - p
	end
	return p, i
end

--non-linear (eased) progress within current iteration (can exceed 0..1).
function tween:distance(clock)
	return self.tweening:ease(self.ease, self.way, self:progress(clock))
end

--timing model / state-changing

function tween:update(clock)
	clock = clock or self.tweening:clock()
	if self.running then
		self.clock = clock
	else
		self.resume_clock = clock
	end
	self:update_value()
end

function tween:pause()
	self.running = false
	self.resume_clock = self.clock
end

function tween:resume()
	if self.running then return end
	self.running = true
	self.start = self.start + (self.resume_clock - self.clock)
	self:update_value()
end

--note: always seeks at the beginning for infinite tweens.
function tween:seek(total_progress)
	if self.running then
		self.start = self.start + (self.clock - self:clock_at(total_progress))
	else
		self.clock = self:clock_at(total_progress)
	end
	self:update_value()
end

function tween:stop()
	self:pause()
	if self.timeline then
		self.timeline:remove(self)
	end
end

function tween:restart()
	self:seek(0)
end

function tween:reverse()
	if self.duration == 1/0 then return end
	clock = clock or self:clock()
	self:resume(clock)
	local p = self:total_progress(clock)
	local clock = self:clock_at(1 - p)
	print(1 - p, clock)
	self.start = clock
	self.backwards = not self.backwards
	self:update_value()
end

--animation model

function tween:_init_animation_model()
	if not self.interpolate or self.auto_interpolate then
		self.interpolate, self.value_semantics =
			self.tweening:interpolation_function(self.type, self.attr)
		self.auto_interpolate = true
	end
	if not self.start_value or not self.end_value then
		local v = self:get_value()
		if not self.value_semantics then
			v = self.interpolate(1, v, v)
		end
		if not self.start_value then
			self.start_value = v
		end
		if not self.end_value then
			self.end_value = v
		end
	end
end

function tween:get_value()
	return self.target[self.attr]
end

function tween:set_value(v)
	self.target[self.attr] = v
end

function tween:update_value()
	local d = self:distance()
	if self.value_semantics then
		local v = self.interpolate(d, self.start_value, self.end_value)
		self:set_value(v)
	else
		self.interpolate(d, self.start_value, self.end_value, self:get_value())
	end
end

--turn a finite tween into a tweenable object with the attribute
--`total_progress` tweenable in 0..1.
function tween:totarget()
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

--statically inherit tween's fields
for k,v in pairs(tween) do
	timeline[k] = v
end

--timing model
timeline.duration = 0
timeline.ease = 'linear'
timeline.auto_duration = true --auto-increase duration to include all tweens
timeline.auto_remove = true --remove tweens automatically when finished

function timeline:reset()
	self:_init_timing_model()
	self.tweens = self.tweens or {}
	if self.auto_duration then
		self.duration = 0
	end
	for i,tween in ipairs(self.tweens) do
		tween:reset()
		self:_adjust(tween)
	end
end

function timeline:_adjust(new_tween)
	if not self.auto_duration then return end
	self.duration = math.max(self.duration, new_tween:end_clock())
end

function timeline:add(tween, start)
	table.insert(self.tweens, tween)
	if start then
		tween.start = start
	elseif self:is_infinite() then
		tween.start = 0
	else
		tween.start = self:total_duration()
	end
	tween.timeline = self
	self:_adjust(tween)
	return self
end

function timeline:_remove(what, recursive)
	local found
	for i,tween in ipairs(self.tweens) do
		if what == true
			or what == tween
			or what == tween.attr
			or what == tween.target
		then
			self.tweens[i] = false
			tween.timeline = false
			found = true
		elseif recursive and tween.remove then
			found = tween:_remove(what) or found
		end
	end
	if found then
		cleanup(self.tweens)
	end
	return found
end
function timeline:remove(what)
	return self:_remove(what, true)
end
function timeline:clear()
	return self:_remove(true, false)
end

--timing model

function timeline:status()
	if #self.tweens == 0 then
		return 'empty'
	end
	return tween.status(self)
end

--animation model

timeline.get_value = nil --not supported
timeline.set_value = nil --not supported

function timeline:_interpolate_tweens()
	local distance = self:distance()
	local found
	for i,tween in ipairs(self.tweens) do
		local t0 = tween.start
		local t1 = tween:end_clock()
		local d  = self:distance()
		local d0 = self:distance(self.start + t0)
		local d1 = self:distance(self.start + t1)
		local t = lerp(d, d0, d1, t0, t1)
		--print(t, t0, t1, d, d0, d1)
		tween:update(t)
		if self.auto_remove and tween:status(clock) == 'finished' then
			self.tweens[i] = false
			found = true
		end
	end
	if found then
		cleanup(self.tweens)
	end
end
function timeline:_update_tweens(clock)
	local clock = clock - self.start
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
function timeline:update_value()
	if #self.tweens == 0 then return end
	if self.duration == 1/0 then
		--infinite duration: timing variables that logically require a finite
		--duration don't work, leaving only speed and delay to have an effect.
		local start = tween.start + self.delay
		local clock = self.clock + (self.clock - self.start) * self.speed
		self:_update_tweens(clock)
	elseif false and self:is_identity() then
		--identity tweening (default): tweens' clocks align to timeline's clock.
		self:_update_tweens(self.clock)
	else
		--worst case: tweening the tweens
		self:_interpolate_tweens()
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

return tw
