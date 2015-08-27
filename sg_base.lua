--scene graph mixin: provides shared caching, state synchronization and error reporting.
local glue = require'glue'
local Cache = require'sg_cache'

local SG = {
	defaults = {},
}

function SG:new(cache)
	return glue.inherit({
		state = {},  --state mirror
		cache = cache or Cache:new(), --shared or private object cache
		errors = {}, --error log
	}, self)
end

function SG:free() end --stub

function SG:error(...)
	self.errors[#self.errors+1] = string.format(...)..'\n'..debug.traceback()
end

function SG:assert(v,...)
	if not v then
		if not ... then
			self:error'assertion failed!'
		else
			self:error(...)
		end
	end
	return v,...
end

function SG:errors_flush()
	if #self.errors == 0 then return end
	local s = self.errors[1]--table.concat(self.errors, '\n')
	self.errors = {}
	error(s,3)
end

function SG:state_save()
	return glue.update({}, self.state)
end

function SG:state_restore(state)
	self.state = state
end

SG.NIL = {}

--prevent setting the same e for the same k twice. e can be any value including nil.
function SG:state_set_value(k, e, set)
	if e == nil then e = self.defaults[k] end
	if e == nil then e = self.NIL end
	if self.state[k] == e then return end
	self.state[k] = e
	if e == self.NIL then e = nil end
	set(self, e)
end

--like state_set but construct and set a cached object associated to e, instead of e itself.
function SG:state_set_object(k, e, cons, set)
	if e == nil then e = self.defaults[k] end
	if e ~= nil then
		local o = self.cache:get(e)
		if o and self.state[k] == e then return o end
		if not o then
			o = cons(self, e)
			self.cache:set(e, o)
		end
		set(self, o)
		self.state[k] = e
		return o
	else
		if self.state[k] ~= self.NIL then
			set(self, nil)
			self.state[k] = self.NIL
		end
		return nil
	end
end

function SG:state_value(k, set) --automate the task of making state-synchronized value setters
	self['set_'..k] = function(self, e)
		self:state_set_value(k, e, set)
	end
end

function SG:state_object(k, cons, set) --automate the task of making state-synchronized object setters
	self['set_'..k] = function(self, e)
		return self:state_set_object(k, e, cons, set)
	end
end

return SG
