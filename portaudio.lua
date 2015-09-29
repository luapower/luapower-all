
--PortAudio binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'portaudio_demo'; return end

local ffi = require'ffi'
local M = {}
local C = ffi.load'portaudio'
require'portaudio_h'

--helpers --------------------------------------------------------------------

local function ptr(p) return p ~= nil and p or nil end
local function ok(ret) return ret == C.paNoError end
local function err(ret) error(ffi.string(C.Pa_GetErrorText(ret)), 3) end

local function check(ret)
	if not ok(ret) then err(ret) end
end

local function checkbool(ret)
	if ret == 1 then return true end
	if ret == 0 then return false end
	err(ret)
end

M.version = C.Pa_GetVersion
function M.versionstring()
	return ffi.string(C.Pa_GetVersionText())
end

--lib ------------------------------------------------------------------------

function M.initialize() check(C.Pa_Initialize()) end
function M.terminate() check(C.Pa_Terminate()) end

--host APIs ------------------------------------------------------------------

local apis = {
	directsound = C.paDirectSound,
	mme = C.paMME,
	asio = C.paASIO,
	soundmanager = C.paSoundManager,
	coreaudio = C.paCoreAudio,
	oss = C.paOSS,
	alsa = C.paALSA,
	al = C.paAL,
	beos = C.paBeOS,
	wdmks = C.paWDMKS,
	jack = C.paJACK,
	wasapi = C.paWASAPI,
	audiosciencehpi = C.paAudioScienceHPI,
}

function M.hostapi(which)
	local i = type(which) == 'string'
		and C.Pa_HostApiTypeIdToHostApiIndex(assert(apis[which:lower()], 'invalid API type'))
		or which or C.Pa_GetDefaultHostApi()
	return ptr(C.Pa_GetHostApiInfo(i))
end

function M.hostapis(what)
	if what == '#' then
		return C.Pa_GetHostApiCount()
	elseif what == '*' then
		return C.Pa_GetDefaultHostApi()
	end
	local i = -1
	return function()
		i = i + 1
		local info = M.hostapi(i)
		if info == nil then return end
		return i, info
	end
end

local api_map = {}; for k,v in pairs(apis) do api_map[tonumber(v)] = k end
ffi.metatype('PaHostApiInfo', {__index = function(self, k)
	if k == 'type' then return api_map[tonumber(self.type_id)] end
	if k == 'name' then return ffi.string(self.name_ptr) end
end})

--devices --------------------------------------------------------------------

local function device_index(which)
	return
		which == '*i' and M.devices'*i' or
		which == '*o' and M.devices'*o' or
		tonumber(which)
end

function M.device(which)
	return ptr(C.Pa_GetDeviceInfo(device_index(which)))
end

function M.devices(what)
	if what == '#' then
		return C.Pa_GetDeviceCount()
	elseif what == '*i' then
		return C.Pa_GetDefaultInputDevice()
	elseif what == '*o' then
		return C.Pa_GetDefaultOutputDevice()
	end
	local i = -1
	return function()
		i = i + 1
		local info = M.device(i)
		if info == nil then return end
		return i, info
	end
end

ffi.metatype('PaDeviceInfo', {__index = function(self, k)
	if k == 'name' then return ffi.string(self.name_ptr) end
end})

--streams --------------------------------------------------------------------

function M.checkformat(t)
	return ok(C.Pa_IsFormatSupported(t.input, t.output, t.samplerate))
end

local formats = {
	float32 = C.paFloat32,
	int32 = C.paInt32,
	int24 = C.paInt24,
	int16 = C.paInt16,
	int8 = C.paInt8,
	uint8 = C.paUInt8,
	custom = C.paCustomFormat,
}

local function stream_params(t, default_device)
	if not t then return end
	local dev = device_index(t)
	if dev then t = {device = dev} end
	local p = ffi.new'PaStreamParameters'
	p.device = device_index(t.device or default_device)
	p.channelCount = t.channels or 2
	p.sampleFormat = bit.bor(
		assert(formats[(t.format or 'int16'):lower()], 'unknown format'),
		t.interleaved == false and C.paNonInterleaved or 0)
	p.suggestedLatency = t.latency or 0
	return p
end

local statuses = {
	C.paInputUnderflow,
	C.paInputOverflow,
	C.paOutputUnderflow,
	C.paOutputOverflow,
	C.paPrimingOutput,
}

local callback_retvals = {
	continue = C.paContinue, --continue invoking the callback and processing audio.
	complete = C.paComplete, --stop invoking the callback and finish once all output samples have played.
	abort = C.paAbort,       --stop invoking the callback and finish as soon as possible.
	[true] = C.paComplete,
	[false] = C.paAbort,
}

local function cbret(ret)
	if ret == nil then ret = 'continue' end
	return assert(callback_retvals[ret], 'invalid return value from callback')
end

function M.open(t)
	if not t then t = '*o' end
	if t == '*i' then t = {input = '*i'} end
	if t == '*o' then t = {output = '*o'} end

	--if a device number is given without specifying whether it's for input
	--or for output, use its max_*_channels info to decide how to used it.
	if tonumber(t) then
		local dev = tonumber(t)
		local info = assert(M.device(dev), 'invalid device')
		t = {}
		if info.max_input_channels > 0 then t.input = dev end
		if info.max_output_channels > 0 then t.output = dev end
	end

	local inparams = stream_params(t.input, '*i')
	local outparams = stream_params(t.output, '*o')
	assert(inparams or outparams, 'input and/or output fields expected')

	local cb --ffi callback object
	local usercallback = t.callback
	if usercallback then
		local callback

		if inparams and outparams then
			function callback(input, output, frames, timeinfo, status, udata)
				return cbret(usercallback(input, output, frames, timeinfo, status))
			end
		elseif inparams then
			function callback(input, output, frames, timeinfo, status, udata)
				return cbret(usercallback(input, frames, timeinfo, status))
			end
		elseif outparams then
			function callback(input, output, frames, timeinfo, status, udata)
				return cbret(usercallback(output, frames, timeinfo, status))
			end
		end
		cb = ffi.cast('PaStreamCallback*', callback)
	end

	local flags = bit.bor(
		t.noclip and C.paClipOff or 0,
		t.nodither and C.paDitherOff or 0,
		t.neverdropinput and C.paNeverDropInput or 0,
		t.primeoutput and C.paPrimeOutputBuffersUsingStreamCallback or 0)

	local stream = ffi.new'PaStream*[1]'

	local ret = C.Pa_OpenStream(stream, inparams, outparams,
		t.samplerate or 44100,
		t.frames or C.paFramesPerBufferUnspecified,
		flags, cb, nil)

	if not ok(ret) then
		if cb then cb:free() end
		err(ret)
	end

	local stream = stream[0]

	local fincb
	if t.finished then
		fincb = ffi.cast('PaStreamFinishedCallback*', t.finished)
		C.Pa_SetStreamFinishedCallback(stream, fincb)
	end

	ffi.gc(stream, function(self)
		self:close()
		if fincb then fincb:free() end
		if cb then cb:free() end
		inparams, outparams = nil --pin aux buffers
	end)

	return stream
end

local stream = {}

function stream:close() check(C.Pa_CloseStream(self)); ffi.gc(self, nil) end
function stream:start() check(C.Pa_StartStream(self)) end
function stream:stop() check(C.Pa_StopStream(self)) end
function stream:abort() check(C.Pa_AbortStream(self)) end
function stream:running() return not checkbool(C.Pa_IsStreamStopped(self)) end
function stream:active() return checkbool(C.Pa_IsStreamActive(self)) end
function stream:info() return ptr(Pa_GetStreamInfo(self)) end
function stream:time() return C.Pa_GetStreamTime(self) end
function stream:cpuload() return C.Pa_GetStreamCpuLoad(self) end

function stream:read(buf, frames)
	if buf == '#' then
		return C.Pa_GetStreamReadAvailable(self)
	end
	check(C.Pa_ReadStream(self, buf, frames))
end

function stream:write(buf, frames)
	if buf == '#' then
		return C.Pa_GetStreamWriteAvailable(self)
	end
	check(C.Pa_WriteStream(self, buf, frames))
end

function M.samplesize(format) return C.Pa_GetSampleSize(format) end
function M.sleep(s) C.Pa_Sleep(s * 1000) end

ffi.metatype('PaStream', {__index = stream})

M.initialize()

return M
