
--tweening for animation
--Written by Cosmin Apreutesei. Public Domain.

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
tw._type = {} --{attr -> type}
tw.type = {} --{patt|func(attr) -> type}

function tw:ease(ease, way, t)
	local easing = require'easing'
	return easing.ease(ease, way, t)
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
	self._type = object(super._type)
	self.type = object(super.type)
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

--timing model
tween.start = 0
tween.timeline = nil --if set, start is relative to timeline.start
tween.duration = 1 --loop duration; can't be negative
tween.ease = 'quad' --function `f(t) -> d` or name from easing module
tween.way = 'in' --easing way: 'in', 'out', 'inout', 'outin'
tween.delay = 0 --start delay; can be negative
tween.speed = 1 --speed factor; can't be 0, can't be < 0
tween.reverse = false --first iteration is backwards
tween.yoyo = true --alternate between forward and reverse on each iteration
tween.loop = 1 --repeat count; use 1/0 for infinite; can be fractional
tween.loop_start = 0 --aka progress_start; can be fractional, negative, > 1
tween.running = true --set to false to start paused
tween.paused_clock = nil --set when pausing to advance start when resuming

--animation model
tween.target = nil --used as v = target[attr] and target[attr] = v
tween.attr = nil
tween.start_value = nil --value at progress 0
tween.end_value = nil --value at progress 1
tween.type = nil
tween.interpolate = nil --custom interpolation function
tween.value_semantics = nil --false for avoiding allocations on update

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
end

function tween:clock()
	return self.tw:clock()
end

function tween:start_clock()
	return self.start + (self.timeline and self.timeline:start_clock() or 0)
end

function tween:total_duration()
	return (self.delay + self.duration * self.loop) * (1 / self.speed)
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
function tween:is_reverse(i)
	if self.yoyo then
		return i % 2 == (self.reverse and 1 or 0)
	else
		return not self.reverse
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
	if self:is_reverse(i) then
		p = 1 - p
	end
	return p, i
end

--non-linear (eased) progress within current iteration (can exceed 0..1).
function tween:distance(progress, loop_index)
	return self.tw:ease(self.ease, self.way, progress)
end

function tween:pause()
	if not self.running then return end
	self.running = false
	self.paused_clock = self:clock()
end

function tween:resume()
	if self.running then return end
	self.start = self.start + (self:clock() - self.paused_clock)
	self.paused_clock = false
	self.running = true
end

function tween:stop()
	self.running = false
	if self.timeline then
		self.timeline:remove(self)
		self.timeline = nil
	end
end


function tween:restart()
	--TODO
	self.start = self.start + (self:clock() - self.paused_clock)
	self.paused_clock = false
	self.running = true
end

--animation model

function tween:_init_animation_model()
	if not self.interpolate or self.auto_interpolate then
		self.interpolate, self.value_semantics =
			self.tw:interpolation_function(self.type, self.attr)
		self.auto_interpolate = true
	end
	if not self.start_value
		or not self.end_value
	then
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

function tween:update(clock)
	if not self.running then return end
	local d = self:distance(self:progress(clock))
	if self.value_semantics then
		local v = self.interpolate(d, self.start_value, self.end_value)
		self:set_value(v)
	else
		self.interpolate(d, self.start_value, self.end_value, self:get_value())
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

function timeline:_adjust(new_tween)
	if self.auto_duration then
		local tween_end_clock =
			new_tween:start_clock() + new_tween:total_duration()
		local duration = tween_end_clock - self:start_clock()
		self.duration = math.max(self.duration, duration)
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

timeline.get_value = nil --not supported
timeline.set_value = nil --not supported

function timeline:update(clock)
	if not self.running then return end
	if #self.tweens == 0 then return end
	local d = self:distance(self:progress(clock))
	local found
	for i,tween in ipairs(self.tweens) do
		local start = tween.start
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

tw.type['_color$'] = 'list'

local o = {x = 0, y = 200, x_color = {1, 0, 0, .5}, i = 0}

tw:freeze()
local tx = tw:tween{target = o, attr = 'x', end_value = 100, loop = 2, ease = 'elastic', way = 'out'}
local ty = tw:tween{target = o, attr = 'y', end_value = 0, loop = 2, ease = 'elastic', way = 'out'}
local tc = tw:tween{target = o, attr = 'x_color', end_value = {0, 0, 1, 1},
	loop = 2, duration = 1, ease = 'linear'}
local ti = tw:tween{target = o, attr = 'i', end_value = 100, type = 'integer'}

local tl = tw:timeline()
tw:unfreeze()

tl.auto_remove = false
tl:add(tx, 0.1):add(ty, 0.2)--:add(tc, 0) --:add(ti)

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
