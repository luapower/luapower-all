
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

local function lerp(d, x1, x2) --lerp from 0..1 to x1..x2
	return x1 + d * (x2 - x1)
end

--remove entries marked `false` from an array efficiently.
local function cleanup(t)
	local j
	--move marked entries to the end
	for i=1,#t do
		if not t[i] then
			j = j or i
		elseif j then
			t[j] = t[i]
			t[i] = false
			j = j + 1
		end
	end
	--remove marked entries without creating gaps
	if j then
		for i=#t,j,-1 do
			t[i] = nil
		end
		assert(#t == j-1)
	end
end

local function copy(t, dt)
	local dt = dt or {}
	if t then
		for k,v in pairs(t) do
			dt[k] = v
		end
	end
	return dt
end

--module ---------------------------------------------------------------------

local tw = object()

tw.interpolate = {}     --{type -> interpolate_function}
tw.value_semantics = {} --{type -> true|false}
tw._type = {}           --{attr -> type}
tw.type = {}            --{patt|f(attr) -> type}

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
function rot.cw(b, a) return a > b and b + 2 * math.pi or b end
function rot.ccw(b, a) return a < b and b - 2 * math.pi or b end
function rot.short(b, a) --shortest sweep
	local b_cw = rot.cw(b, a)
	local b_ccw = rot.ccw(b, a)
	return math.abs(a - b_cw) < math.abs(a - b_ccw) and b_cw or b_ccw
end

--unit conversions
local unit = {}
unit['%'] = function(b, a) return b / 100 * a end
unit.ms = function(b, a) return b / 1000 end
unit.deg = function(b, a) return math.rad(b) end

--note: tween is not used here but overrides could use it.
function tw:parse_value(b, a, tween)
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
		if unit_ then b = unit_(b, a) end
		if op_ then b = op_(b, a) end
		if rot_ then b = rot_(b, a) end
	elseif type(b) == 'function' then
		b = b(a, tween)
	end
	return b
end

--note: loop_index is not used here but overrides could use it.
function tw:ease(ease, way, progress, loop_index, ...)
	local easing = require'easing'
	return easing.ease(ease, way, progress, ...)
end

--find an attribute type based on its name
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
	if clock ~= nil then --freeze the clock
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
tween.speed = 1          --speed factor; can be <= 0 with caveats
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
	return math.max(self.duration * self.loop, 0) / self.speed
end

function tween:end_clock()
	return self.start + self:total_duration()
end

function tween:is_infinite()
	return math.abs(self:total_duration()) == 1/0
end

--always returns the start clock for infinite tweens.
function tween:clock_at(progress)
	return self.start + self:total_duration() * progress
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
function tween:_progress(clock)
	return ((clock or self.clock) - self.start) / self:total_duration()
end

function tween:progress(clock)
	return clamp(self:_progress(clock), 0, 1)
end

function tween:status(clock)
	local p = self:_progress(clock)
	return p < 0 and 'not_started' or p >= 1 and 'finished'
		or self.running and 'running' or 'paused'
end

--linear progress in 0..loop
function tween:_loop_progress(clock)
	local clock = clock or self.clock
	local time_in = clock - self.start
	return time_in / (self.duration / self.speed)
end

function tween:loop_progress(clock)
	return clamp(self:_loop_progress(clock), 0, self.loop)
end

function tween:loop_clock_at(loop_progress)
	return self.start + loop_progress * (self.duration / self.speed)
end

--non-linear (eased) progress within current iteration (can exceed 0..1).
local empty = {}
function tween:distance(clock)
	local p = self.offset + self:loop_progress(clock)
	local i = math.floor(p)
	local p = p - i
	if self:is_backwards(i) then
		p = 1 - p
	end
	return self.tweening:ease(self.ease, self.way, p, i,
		unpack(self.ease_args or empty))
end

--timing model / state-changing

function tween:update_clock(clock)
	clock = clock or self.tweening:clock()
	if self.running then
		self.clock = clock
	else
		self.resume_clock = clock
	end
end

function tween:update(clock)
	self:update_clock(clock)
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

function tween:seek(progress)
	if self:is_infinite() then return end
	if self.running then
		self.start = self.start
			+ (self.clock - self:clock_at(progress))
	else
		self.clock = self:clock_at(progress)
	end
	self:update_value()
end

function tween:loop_seek(loop_progress)
	if self:is_infinite() then return end
	if self.running then
		self.start = self.start + (self.clock - self:loop_clock_at(loop_progress))
	else
		self.clock = self:loop_clock_at(loop_progress)
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
	self:loop_seek(0)
end

--these weird calculations change the timing parameters such that the shape
--of distance() gets horizontally flipped around the current clock point in
--order to look like it's going back in time while actually continuing to go
--forward.
--note: this can also be done more generally (with less knowledge of the
--timing model) by just negating `speed`, but that wouldn't work with an
--infinite tween because `start` would then be a fixed point in the future.
function tween:reverse()
	local p = self:_loop_progress()
	local loop = self.loop
	if loop == 1/0 then
		loop = math.ceil(p)
	end
	self.offset = (1 - self.offset) - (loop - math.floor(loop))
	self.start = self.start - (self:loop_clock_at(loop - p) - self.clock)
	if not self.yoyo or math.floor(loop) % 2 == 0 then
		self.backwards = not self.backwards
	end
end

--turn a finite tween into a tweenable object with the attribute
--`progress` tweenable in 0..1 and `loop_progress` tweenable in `0..loop`.
function tween:totarget()
	local t = {}
	setmetatable(t, t)
	function t.__index(t, k)
		if k == 'progress' then
			return self:progress()
		elseif k == 'loop_progress' then
			return self:loop_progress()
		else
			return rawget(self, k)
		end
	end
	function t.__newindex(t, k, v)
		if k == 'progress' then
			self:update(self:clock_at(v))
		elseif k == 'loop_progress' then
			self:update(self:loop_clock_at(v))
		else
			rawset(self, k, v)
		end
	end
	return t
end

--animation model

function tween:parse_value(v, relative_to)
	return self.tweening:parse_value(v, relative_to, self)
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

function timeline:_add_tween(tween, start)
	table.insert(self.tweens, tween)
	if start then
		tween.start = self:parse_value(start, self:total_duration())
	elseif self:is_infinite() then
		tween.start = 0
	else
		tween.start = self:total_duration()
	end
	tween.timeline = self
	self:_adjust(tween)
	return self
end

function timeline:_add_tweens(t, start)
	local attrs = {}
	copy(t.from, attrs)
	copy(t.to, attrs)
	copy(t.cycle_from, attrs)
	copy(t.cycle_to, attrs)
	copy(t.cycle, attrs)
	start = start or t.start
	for attr in pairs(attrs) do
		local targets = t.targets or {t.target}
		local from = t.from and t.from[attr]
		local to = t.to and t.to[attr]
		local c_from = t.cycle_from or (t.from and t.cycle)
		local c_to   = t.cycle_to   or (t.to   and t.cycle)
		c_from = c_from and c_from[attr]
		c_to   = c_to   and c_to  [attr]
		for i,target in ipairs(t.targets) do
			local tt = copy(t)
			tt.attr = attr
			tt.from = c_from and c_from[(i - 1) % #c_from + 1] or from
			tt.to = c_to and c_to[(i - 1) % #c_to + 1] or to
			tt.target = target
			tt.start = 0
			tt.cycle_from = nil
			tt.cycle_to = nil
			tt.cycle = nil
			local tween = self.tweening:tween(tt)
			self:add(tween, start)
			start = tween.start --parsed start, same for all tweens
		end
	end
	return self
end

function timeline:add(t, start)
	if t.__index then
		return self:_add_tween(t, start)
	elseif t.from or t.to or t.cycle_from or t.cycle_to or t.cycle then
		return self:_add_tweens(t, start)
	else
		error'invalid arguments'
	end
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

function timeline:find(what, recursive)
	if recursive == nil then
		recursive = true
	end
	return coroutine.wrap(function()
		for i,tween in ipairs(self.tweens) do
			if what == true
				or what == tween
				or what == tween.attr
				or what == tween.target
			then
				coroutine.yield(tween, i)
				if tween.tweens then
					tween:find(what)
				end
			end
		end
	end)
end

function timeline:_remove(what, recursive)
	local found
	for tween, i in self:find(what, recursive) do
		tween.timeline[i] = false
		tween.timeline = false
		found = true
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
	local clock = (clock - self.start) * self.speed
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

return tw
