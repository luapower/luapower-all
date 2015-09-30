local nw = require'nw'

local objc = require'objc'
local ffi = require'ffi'
local dispatch = require'objc_dispatch'
local glue = require'glue'

objc.load'AVFoundation'
objc.load'CoreVideo'
objc.load'CoreMedia'
objc.load'CoreFoundation'

local B = {}

local function find_dev(id)
	return objc.AVCaptureDevice:deviceWithUniqueID(id)
end

local function default_dev()
	return objc.AVCaptureDevice:defaultDeviceWithMediaType(objc.AVMediaTypeVideo)
end

local function wrap_dev(dev, default_dev)
	if not dev.connected then return end
	local t = {_isdevice = true}
	t.name = objc.tolua(dev.localizedName)
	t.id = objc.tolua(dev.uniqueID)
	t.isdefault = dev == default_dev
	return t
end

function B.device_count()
	return objc.AVCaptureDevice.devices:count()
end

function B.default_device()
	local default_dev = default_dev()
	return wrap_dev(default_dev, default_dev)
end

function B.find_device(id)
	return wrap_dev(find_dev(id))
end

function B.devices()
	local t = {}
	local default_dev = default_dev()
	for i, dev in objc.ipairs(objc.AVCaptureDevice:devicesWithMediaType(objc.AVMediaTypeVideo)) do
		table.insert(t, wrap_dev(dev, default_dev))
	end
	return t
end

local session = {}
B.session = session

local VI_AVCaptureVideoDataOutput = objc.class('VI_AVCaptureVideoDataOutput',
	'AVCaptureVideoDataOutput <AVCaptureVideoDataOutputSampleBufferDelegate>')

function B.open(frontend, dev_id, t)

	local device = find_dev(dev_id)
	assert(device)

	local self = glue.update({}, session)
	self.frontend = frontend

	local err = ffi.new'id[1]'
	local input = objc.AVCaptureDeviceInput:deviceInputWithDevice_error(device, err)
	assert(err[0] == nil)
	assert(input)

	local output = VI_AVCaptureVideoDataOutput:new()
	assert(output)

	--set bgra8 output
	local pixelformat = objc.tolua(ffi.cast('id', objc.kCVPixelBufferPixelFormatTypeKey))
	local settings = objc.toobj{[pixelformat] = objc.kCVPixelFormatType_32BGRA}
	output:setVideoSettings(settings)

	output:setAlwaysDiscardsLateVideoFrames(true)

	function output.captureOutput_didOutputSampleBuffer_fromConnection(output, _, cmsb, _)
		local img = objc.CMSampleBufferGetImageBuffer(cmsb)
		objc.CVPixelBufferLockBaseAddress(img, objc.kCVPixelBufferLock_ReadOnly)
		local buf = objc.CVPixelBufferGetBaseAddress(img)
		local sz = objc.CVImageBufferGetDisplaySize(img)
		local w, h = sz.width, sz.height
		local bitmap = {
			data = buf,
			w = w,
			h = h,
			stride = w * 4,
			size   = w * 4 * h,
			format = 'bgra8',
		}
		self.frontend:_backend_newframe(bitmap)
		objc.CVPixelBufferUnlockBaseAddress(img, objc.kCVPixelBufferLock_ReadOnly)
	end

	local queue = dispatch.main_queue
	output:setSampleBufferDelegate_queue(output, queue)
	dispatch.release(queue)

	local session = objc.AVCaptureSession:alloc():init()
	assert(session)
	session:setSessionPreset(objc.AVCaptureSessionPresetHigh)
	assert(session:canAddInput(input))
	session:addInput(input)
	assert(session:canAddOutput(output))
	session:addOutput(output)

	conn = output.connections:objectAtIndex(0)
	assert(conn)
	assert(conn.enabled)
	assert(conn.active)

	self._device = device
	self._input = input
	self._output = output
	self._session = session

	return self
end

function session:start()
	self._session:startRunning()
end

function session:stop()
	self._session:stopRunning()
end

function session:get_running()
	return self._session.running
end

function session:close()
end

return B
