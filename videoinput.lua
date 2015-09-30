
local ffi = require'ffi'
local glue = require'glue'

local M = {}

local backends = {
	osx = 'videoinput_cocoa',
	linux = 'videoinput_v4l',
	windows = 'videoinput_dshow',
}

local B = require(assert(backends[ffi.os:lower()], 'OS not supported'))

function M.devices(which)
	if which == '#' then --count
		return B.device_count()
	elseif which == '*' then --default
		return B.default_device()
	elseif which then --recall by id
		return B.find_device(which)
	else --iterate
		return B.devices()
	end
end

local session = {}

local function find_device(which)
	if not which or type(which) == 'string' then --default or by id
		return M.devices(which or '*')
	elseif type(which) == 'table' and which._isdevice then --device object: pass through
		return which
	end
end

function M.open(t)
	local self = glue.update({}, session)
	local dev = find_device(t) or (t and find_device(t.device))
	if not dev then return nil end
	self.backend = B.open(self, dev.id, t)
	return self
end

function session:start()
	self.backend:start()
end

function session:stop()
	self.backend:stop()
end

function session:close()
	self:stop()
	self.backend:close()
end

function session:running(running)
	if running == nil then
		return self.backend:get_running()
	elseif running then
		self:start()
	else
		self:stop()
	end
end

function session:_backend_newframe(bmp)
	if not self.newframe then return end
	self:newframe(bmp)
end

return M

