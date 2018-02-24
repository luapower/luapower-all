
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

local function lerp(d, x1, x2)
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

local function copy(t, dt)
	local dt = dt or {}
	for k,v in pairs(t) do
		dt[k] = v
	end
	return dt
end

--module ---------------------------------------------------------------------

local tw = object()

tw.interpolate = {} --{type -> interpolate_function}
tw.value_semantics = {} --{type -> true|false}
tw._type = {} --{attr -> type}
tw.type = {} --{patt|f(attr) -> type}

function tw.__call(super)
	local self = object(super)
	self._clock = false --avoid inheriting it
	self.interpolate = object(super.interpolate)
	self.value_semantics = object(super.value_semantics)
	self._type = object(super._type)
	self.type = object(super.type)
	return self
end

--relative values operations
local op = {}
op['+'] = function(b, a) return a + b end
op['-'] = function(b, a) return a - b end
op['*'] = function(b, a) return a * b end

--directional rotations
local rot = {}
function rot.ccw(b, a) return a < b and b - 2 * math.pi or b end
function rot.cw(b, a) return a > b and b + 2 * math.pi or b end
function rot.short(b, a)
	local bcw = rot.cw(b, a)
	local bccw = rot.ccw(b, a)
	return math.abs(a - bcw) < math.abs(a - bccw) and bcw or bccw
end

--unit conversions
local unit = {}
unit['%'] = function(b) return b / 100 end
unit.deg = math.rad

--note: attr_type and attr are not used here but overrides could use it.
function tw:parse_value(b, a, attr_type, attr)
	if b == nil then
		return a
	elseif type(b) == 'string' then
		local op_, unit_, rot_
		b = b:gsub('^([-+*])=', function(s)
			op_ = op[s]
			if op_ then return '' end
		end)
		b = b:gsub('_?([%a]+)$', function(s)
			rot_ = rot[s]
			if rot_ then return '' end
		end)
		b = b:gsub('[%a%%]+$', function(s)
			unit_ = unit[s]
			if unit_ then return '' end
		end)
		b = assert(tonumber(b), 'invalid value')
		if unit_ then b = unit_(b) end
		if op_ then b = op_(b, a) end
		if rot_ then b = rot_(b, a) end
	end
	return b
end

--note: loop_index is not used here but overrides could use it.
function tw:ease(ease, way, progress, loop_index, ...)
	local easing = require'easing'
	return easing.ease(ease, way, progress, ...)
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

--timing model / definition
tween.start = nil        --start clock
tween.timeline = nil     --if set, start is relative to timeline.start
tween.duration = 1       --loop duration; can't be negative
tween.ease = 'quad'      --function `f(t) -> d` or name from easing module
tween.way = 'in'         --easing way: 'in', 'out', 'inout', 'outin'
tween.backwards = false  --first iteration is backwards
tween.yoyo = true        --alternate between forwards/backwards on each loop
tween.loop = 1           --repeat count; 1/0 for infinite; can be fractional
--timing model / definition / less used
tween.delay = 0          --start delay; can be negative
tween.speed = 1          --speed factor; can't be 0, can't be < 0
tween.offset = 0         --can be fractional, negative, > 1
--timing model / state
tween.running = true     --set to false to start paused
tween.clock = nil        --current clock
tween.resume_clock = nil --current clock when paused

--animation model / definition
tween.target = nil       --used as v = target[attr] and target[attr] = v
tween.attr = nil
tween.from = nil         --rel/abs value at progress 0
tween.to = nil           --rel/abs value at progress 1
tween.type = nil         --force attr type
tween.interpolate = nil  --custom interpolation function
tween.value_semantics = nil --false for avoiding allocations on update

--constructors

function tween:__call(tweening, o)
	local self = object(self, o)
	self.tweening = tweening
	self:reset()
	return self
end

function tween:clone()
	return self:__call(self.tweening, copy(self))
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

function tween:total_duration()
	return math.max(self.delay + self.duration * self.loop, 0)
		* (1 / self.speed)
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
function tween:_total_progress(clock)
	return ((clock or self.clock) - self.start) / self:total_duration()
end

function tween:total_progress(clock)
	return clamp(self:_total_progress(clock), 0, 1)
end

function tween:status(clock)
	local p = self:_total_progress(clock)
	return p < 0 and 'not_started' or p >= 1 and 'finished'
		or self.running and 'running' or 'paused'
end

--linear progress within current iteration in 0..1 (so excluding repeats)
--and the iteration number counting from math.floor(offset).
function tween:progress(clock)
	local clock = clock or self.clock
	local inv_speed = 1 / self.speed
	local time_in = clock - (self.start + self.delay * inv_speed)
	local p = time_in / (self.duration * inv_speed)
	local p = self.offset + clamp(p, 0, self.loop)
	local i = math.floor(p)
	local p = p - i
	if self:is_backwards(i) then
		p = 1 - p
	end
	return p, i
end

--non-linear (eased) progress within current iteration (can exceed 0..1).
local empty = {}
function tween:distance(clock)
	return self.tweening:ease(self.ease, self.way, self:progress(clock),
		unpack(self.ease_args or empty))
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
	self:_init_animation_model()
	self:seek(0)
end

function tween:reverse()
	if self.duration == 1/0 then return end
	self:seek(1 - self:total_progress())
	self.backwards = not self.backwards
	self:update_value()
end

--turn a finite tween into a tweenable object with the attribute
--`total_progress` tweenable in 0..1.
function tween:totarget()
	local t = {}
	setmetatable(t, t)
	function t.__index(t, k)
		if k == 'total_progress' then
			return self:total_progress()
		else
			return rawget(self, k)
		end
	end
	function t.__newindex(t, k, v)
		if k == 'total_progress' then
			self:update(self:clock_at(v))
		else
			rawset(self, k, v)
		end
	end
	return t
end

--animation model

function tween:parse_value(v, relative_to)
	return self.tweening:parse_value(v, relative_to, self.type, self.attr)
end

function tween:_init_animation_model()
	if not self.interpolate or self._auto_interpolate then
		self.interpolate, self.value_semantics =
			self.tweening:interpolation_function(self.type, self.attr)
		self._auto_interpolate = true
	end
	local v = self:get_value()
	if not self.value_semantics then
		v = self.interpolate(1, v, v)
	end
	self._v0 = self:parse_value(self.from, v)
	self._v1 = self:parse_value(self.to, v)
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
		local v = self.interpolate(d, self._v0, self._v1)
		self:set_value(v)
	else
		self.interpolate(d, self._v0, self._v1, self:get_value())
	end
end

function tween:can_be_replaced_by(tween)
	return self.target == tween.target and self.attr == tween.attr
end

--timeline -------------------------------------------------------------------
--A timeline is a tween which plays a list of tweens.

local timeline = object()
tw.timeline = timeline
copy(tween, timeline) --statically inherit tween's fields

--timing model
timeline.duration = 0 --auto-increased when adding tweens
timeline.ease = 'linear'
timeline.auto_duration = true --auto-increase duration to include all tweens
timeline.auto_remove = true --remove tweens automatically when finished
timeline.tween_progress = false --interpolate the child tweens' progress

--constructors

function timeline:clone()
	local t = timeline(copy(self))
	t.tweens = copy(self.tweens)
	return t
end

function timeline:_init_animation_model() end

function timeline:restart()
	for i,tween in ipairs(self.tweens) do
		tween:_init_animation_model()
	end
	tween.restart(self)
end

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

function timeline:can_be_replaced_by(tween)
	return false
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

function timeline:replace(tween, start)
	local replaced
	for i,twn in ipairs(self.tweens) do
		if twn:can_be_replaced_by(tween) then
			self.tweens[i] = tween
			replaced = true
			break
		end
	end
	if not replaced then
		self:add(tween, start)
	end
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

--note: auto_remove not enabled in this mode.
function timeline:_interpolate_tweens()
	local d = self:distance()
	for i,tween in ipairs(self.tweens) do
		tween:update(tween:clock_at(d))
	end
end

function timeline:_update_tweens()
	local clock = self.clock
	local status = self:status()
	if status == 'finished' then
		clock = self:end_clock()
	elseif status == 'not_started' then
		clock = self.start
	end
	local clock = (clock - self.start) * self.speed - self.delay
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
	if self.tween_progress then
		self:_interpolate_tweens()
	else
		self:_update_tweens()
	end
end

--sugar APIs -----------------------------------------------------------------

function tw:to(target, duration, easing, way, end_values, start, loop, offset, delay)
	local tl = self:timeline{}
	for attr, val in pairs(end_values) do
		local tween = self:tween{target = target, duration = duration,
			easing = easing, end_values = end_values, start = start, loop = loop}
		tl:add(tween)
	end
	return tl
end

function tw:from(target, duration, easing, way, start_values, start, loop)
	return self:tween{target = target, duration = duration, easing = easing,
		start_values = start_values, start = start, loop = loop}
end

function tw:stagger_to(targets, duration, easing, way, end_values, start, loop, offset, delay)

end

return tw
