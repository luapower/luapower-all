
--Structured exceptions for Lua.
--Written by Cosmin Apreutesei. Public Domain.

--prototype-based dynamic inheritance with __call constructor (from glue).
local function object(super, o)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	o.__tostring = super and super.__tostring
	return setmetatable(o, o)
end

local lua_error = error

local classes = {} --{name -> class}
local class_sets = {} --{'name1 name2 ...' -> {class->true}}
local error --base error class, defined below.

local function error_type(classname, super)
	super = type(super) == 'string' and assert(classes[super]) or super or error
	local class = object(super, {classname = classname, is_error = true})
	if classname then
		assert(not classes[classname], 'error class name already defined')
		classes[classname] = class
		class_sets = {}
	end
	return class
end

error = error_type'error'

local function is_error(e)
	return type(e) == 'table' and e.is_error
end

local function error_object(arg, ...)
	if type(arg) == 'string' then
		local class = classes[arg] or error_type(arg)
		return class(...)
	end
	return arg
end

local function class_table(s)
	if type(s) == 'string' then
		local t = class_sets[s]
		if not t then
			t = {}
			class_sets[s] = t
			for s in s:gmatch'[^%s,]+' do
				local class = classes[s]
				while class do
					t[class] = true
					class = class.__index
				end
			end
		end
		return t
	else
		assert(type(s) == 'table')
		return s --if given as table, must contain superclasses too!
	end
end

local function is_error_of(e, classes)
	return is_error(e) and (not classes or class_table(classes)[e.__index] or false)
end

function error:__call(arg1, ...)
	if type(arg1) == 'table' then
		local message = ... and string.format(...) or nil
		local e = object(self, arg1)
		e.message = message
		return e
	else
		return object(self, {message = arg1 and string.format(arg1, ...) or nil})
	end
end

function error:__tostring()
	return (self.message or self.classname)
		..(self.traceback and '\n'..self.traceback or '')
end

local function raise(...)
	lua_error(error_object(...), 2)
end

local function pass(classes, ok, ...)
	if ok then return true, ... end
	local e = ...
	if is_error_of(e, classes) then
		return false, e
	end
	lua_error(e, 2)
end
local function onerror(e)
	if is_error(e) then
		e.traceback = debug.traceback(nil, 2)
	end
	return e
end
local function zpcall(f, ...)
	return xpcall(f, onerror, ...)
end
local function catch(classes, f, ...)
	return pass(classes, zpcall(f, ...))
end

local function check(class, v, ...)
	if v then return v, ... end
	raise(class, ...)
end

local function pass(ok, ...)
	if ok then return ... end
	return nil, ...
end
local function protect(classes, f)
	return function(...)
		return pass(catch(classes, f, ...))
	end
end

local M = {
	error = error,
	errortype = error_type,
	new = error_object,
	is = is_error_of,
	raise = raise,
	catch = catch,
	pcall = zpcall,
	check = check,
	protect = protect,
}

if not ... then

	local errors = M

	local e1 = errors.errortype'e1'
	local e2 = errors.errortype('e2', 'e1')
	local e3 = errors.errortype'e3'

	local ok, e = errors.catch('e2 e3', function()

		local ok, e = errors.catch('e1', function()

			errors.raise('e2', 'imma e2')

		end)

		print'should not get here'

	end)

	if not ok then
		print('caught', e.classname, e.message)
	end

	errors.raise(e)

end

return M
