
--PortAudio binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local M = {}
local C = ffi.load'portaudio'
require'portaudio_h'

local function ptr(p) return p ~= nil and p or nil end
local function bool(ret) return ret == C.paNoError end

local function check(ret)
	if bool(ret) then return end
	error(ffi.string(C.Pa_GetErrorText(ret)), 3)
end

M.version = C.Pa_GetVersion
function M.versionstring()
	return ffi.string(C.Pa_GetVersionText())
end

function M.initialize() check(C.Pa_Initialize()) end
function M.terminate() check(C.Pa_Terminate()) end

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

function M.device(which)
	local i =
		which == '*i' and M.devices'*i' or
		which == '*o' and M.devices'*o' or which
	return ptr(C.Pa_GetDeviceInfo(i))
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

function M.checkformat(t)
	return bool(C.Pa_IsFormatSupported(t.inparams, t.outparams, t.samplerate))
end

function M.open(t)
	local stream = ffi.new'PaStream*[1]'
	local flags = 0

	--[[
	PaDeviceIndex device;
	int channelCount;
	PaSampleFormat sampleFormat;
	PaTime suggestedLatency;
	void *hostApiSpecificStreamInfo;
	]]

	PaStream** stream,
	int numInputChannels,
	int numOutputChannels,
	PaSampleFormat sampleFormat,
	double sampleRate,
	unsigned long framesPerBuffer,
	PaStreamCallback *streamCallback,
	void *userData

	check(C.Pa_OpenStream(stream, t.inparams, t.outparams, t.samplerate,
		t.frames, flags, t.callback, nil))

	return stream[0]
end

local stream = {}

function stream:set_finished_callback(callback)
	local cb = ffi.new'PaStreamFinishedCallback'
	Pa_SetStreamFinishedCallback(self, cb)
end

function stream:close() check(C.Pa_CloseStream(self)) end
function stream:start() check(C.Pa_StartStream(self)) end
function stream:stop() check(C.Pa_StopStream(self)) end
function stream:abort() check(C.Pa_AbortStream(self)) end
function stream:stopped() return bool(C.Pa_IsStreamStopped(self)) end
function stream:active() return bool(C.Pa_IsStreamActive(self)) end
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
function M.sleep(s) C.Pa_Sleep(s / 1000) end

ffi.metatype('PaStream', {__index = stream})

--demo

if not ... then
	local pa = M
	print('version:', pa.version())
	print('version text:', pa.versionstring())
	pa.initialize()

	print('host API count:   ', pa.hostapis'#')
	print('default host API: ', pa.hostapis'*i')

	for i,info in pa.hostapis() do
		print('host API ', i)
		print('', 'structVersion', info.structVersion)
		print('', 'type         ', info.type)
		print('', 'name         ', ffi.string(info.name))
		print('', 'device count ', info.deviceCount)
		print('', 'input dev    ', info.defaultInputDevice)
		print('', 'outpu dev    ', info.defaultOutputDevice)
	end

	for i,dev in pa.devices() do
		print('', 'structVersion', dev.structVersion)
		print('', 'name         ', ffi.string(dev.name))
		print('', 'host API     ', dev.hostApi)
		print('', 'max input channels  ', dev.maxInputChannels)
		print('', 'max output channels ', dev.maxOutputChannels)
		print('', 'default sample rate ', dev.defaultSampleRate)
	end

	local stream = pa.open{
		--
	}

	--[[
		print('device', dev.device)
		print('', 'channels ', dev.channelCount)
		print('', 'format   ', dev.sampleFormat)
		print('', 'latency  ', dev.suggestedLatency)
	]]

	pa.terminate()
end

return M
