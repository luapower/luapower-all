
--libvorbisfile binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
require'libvorbis_file_h'
local C = ffi.load'vorbisfile'
local M = {C = C}

local function ret(ret)
	if ret == 0 then return true end
	return nil, ret
end

local function retpoz(ret)
	if ret >= 0 then return tonumber(ret) end
	return nil, ret
end

local function reth(h, ret)
	if ret == 0 then return h end
	return nil, ret
end

local function ptr(ptr)
	return ptr ~= nil and ptr or nil
end

function M.open(t)
	local self = ffi.new'OggVorbis_File'
	if t.path then
		return reth(self, C.ov_fopen(t.path, self))
	elseif t.stream then
		local open = t.test and C.ov_open or C.ov_test_open
		return reth(self, open(t.stream, self,
			t.initial_buffer or nil, t.initial_buffer_size or 0))
	elseif t.read then
		--TODO: memory management and wrapping of callbacks
		local callbacks = ffi.new'ov_callbacks'
		callbacks.read = t.read
		callbacks.seek = t.seek
		callbacks.close = t.close
		callbacks.tell = t.tell
		local open = t.test and C.ov_open_callbacks or C.ov_test_callbacks
		return reth(self, open(
			nil, self,
			t.initial_buffer or nil, t.initial_buffer_size or 0,
			callbacks))
	end
end

local ov = {}
ov.__index = ov

function ov:close()
	assert(ret(C.ov_clear(self)))
end

function ov:open()
	return ret(C.ov_test_open(self))
end

function ov:bitrate(i, instant)
	local bitrate = instant and C.ov_bitrate_instant or C.ov_bitrate
	return retpoz(bitrate(self, i or 0))
end

function ov:streams()
	return retpoz(C.ov_streams(self))
end

function ov:isseekable()
	return C.ov_seekable(self) ~= 0
end

function ov:serialnumber(i)
	local ret = C.ov_serialnumber(self, i or -1)
	return ret ~= -1 and ret or nil
end

function ov:raw_total(file, i)  return retpoz(C.ov_raw_total(self, i or -1)) end
function ov:pcm_total(file, i)  return retpoz(C.ov_pcm_total(self, i or -1)) end
function ov:time_total(file, i) return retpoz(C.ov_time_total(self, i or -1)) end

function ov:raw_seek(pos)           return ret(C.ov_raw_seek(self, pos)) end
function ov:pcm_seek(pos)           return ret(C.ov_pcm_seek(self, pos)) end
function ov:pcm_seek_page(pos)      return ret(C.ov_pcm_seek_page(self, pos)) end
function ov:time_seek(pos)          return ret(C.ov_time_seek(self, pos)) end
function ov:time_seek_page(pos)     return ret(C.ov_time_seek_page(self, pos)) end
function ov:raw_seek_lap(pos)       return ret(C.ov_raw_seek_lap(self, pos)) end
function ov:pcm_seek_lap(pos)       return ret(C.ov_pcm_seek_lap(self, pos)) end
function ov:pcm_seek_page_lap(pos)  return ret(C.ov_pcm_seek_page_lap(self, pos)) end
function ov:time_seek_lap(pos)      return ret(C.ov_time_seek_lap(self, pos)) end
function ov:time_seek_page_lap(pos) return ret(C.ov_time_seek_page_lap(self, pos)) end

function ov:raw_tell(pos)  return retpoz(C.ov_raw_tell(self, pos)) end
function ov:pcm_tell(pos)  return retpoz(C.ov_pcm_tell(self, pos)) end
function ov:time_tell(pos) return retpoz(C.ov_time_tell(self, pos)) end
function ov:info(link)     return ptr(C.ov_info(self, link or -1)) end
function ov:comments(link)
	local t = {}
	local c = ptr(C.ov_comment(self, link or -1))
	if c then
		for i=1,c.comments do
			t[i] = ffi.string(c.user_comments[i-1], c.comment_lengths[i-1])
		end
	end
	t.vendor = c.vendor ~= nil and ffi.string(c.vendor) or nil
	return t
end

function ov:print()
	print('bitrate    : ' .. self:bitrate())
	print('streams    : ' .. self:streams())
	print('seekable   : ' .. tostring(self:isseekable()))
	print('serial     : ' .. self:serialnumber())
	print('raw_total  : ' .. self:raw_total())
	print('pcm_total  : ' .. self:pcm_total())
	print('time_total : ' .. self:time_total())
	local t = self:info()
	print('info       : ')
	print('  version  : ' .. t.version)
	print('  channels : ' .. t.channels)
	print('  rate     : ' .. t.rate)
	print('  bitrate_upper    : ' .. t.bitrate_upper)
	print('  bitrate_nominal  : ' .. t.bitrate_nominal)
	print('  bitrate_window   : ' .. t.bitrate_window)
	print('  codec_setup      : ' .. (t.codec_setup ~= nil and ffi.string(t.codec_setup) or ''))
	local t = self:comments()
	print('comments   : ')
	for i=1,#t do
		print('  '..t[i])
	end
	print('  vendor   : '..t.vendor)
end

function ov:read_float(buf, maxsamples, bitstream)
	return retpoz(C.ov_read_float(self, buf, maxsamples, bitstream))
end

function ov:read(buf, sz, wordsize, signed, bigendian, bitstream)
	local i = 0
	while sz > 0 do
		print(sz)
		local n, err = retpoz(C.ov_read(self, buf + i, sz,
			bigendian and 1 or 0,
			wordsize or 2,
			signed == false and 0 or 1,
			bitstream))
		if not n then return nil, err end
		if n == 0 then break end
		sz = sz - n
		i = i + n
	end
	return i
end

--[[
--TODO
long ov_read_filter(OggVorbis_File *vf,char *buffer,int length,
	int bigendianp,int word,int sgned,int *bitstream,
	void (*filter)(float **pcm,long channels,long samples,void *filter_param),void *filter_param);
]]

function M.crosslap(ov1, ov2)
	return ret(C.ov_crosslap(ov1, ov2))
end

ffi.metatype('OggVorbis_File', ov)

return M
