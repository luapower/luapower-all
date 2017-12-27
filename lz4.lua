
--LZ4 binding for LZ4 1.7.1 API.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'

ffi.cdef[[
int LZ4_versionNumber(void);

int LZ4_compressBound (int inputSize);

int LZ4_compress_default(
	const char* source,
	char* dest,
	int sourceSize,
	int maxDestSize);

int LZ4_compress_fast(
	const char* source,
	char* dest,
	int sourceSize,
	int maxDestSize,
	int acceleration);

int LZ4_sizeofState (void);

int LZ4_compress_fast_extState(
	void* state,
	const char* source,
	char* dest, int inputSize,
	int maxDestSize,
	int acceleration);

int LZ4_compress_destSize(
	const char* source,
	char* dest,
	int* sourceSizePtr,
	int targetDestSize);

int LZ4_decompress_safe(
	const char* source,
	char* dest,
	int compressedSize,
	int maxDecompressedSize);

int LZ4_decompress_fast(
	const char* source,
	char* dest,
	int originalSize);

int LZ4_decompress_safe_partial(
	const char* source,
	char* dest,
	int compressedSize,
	int targetOutputSize,
	int maxDecompressedSize);

typedef struct LZ4_stream_t LZ4_stream_t;

LZ4_stream_t* LZ4_createStream (void);
int           LZ4_freeStream   (LZ4_stream_t* streamPtr);
void          LZ4_resetStream  (LZ4_stream_t* streamPtr);

int LZ4_loadDict (LZ4_stream_t* streamPtr, const char* dictionary, int dictSize);
int LZ4_saveDict (LZ4_stream_t* streamPtr, char* safeBuffer, int dictSize);

int  LZ4_compress_fast_continue(
	LZ4_stream_t* streamPtr,
	const char* src,
	char* dst,
	int srcSize,
	int maxDstSize,
	int acceleration);

typedef struct LZ4_streamDecode_t LZ4_streamDecode_t;

LZ4_streamDecode_t* LZ4_createStreamDecode (void);
int                 LZ4_freeStreamDecode   (LZ4_streamDecode_t* LZ4_stream);

int LZ4_setStreamDecode(
	LZ4_streamDecode_t* LZ4_streamDecode,
	const char* dictionary,
	int dictSize);

int LZ4_decompress_safe_continue(
	LZ4_streamDecode_t* LZ4_streamDecode,
	const char* source,
	char* dest,
	int compressedSize,
	int maxDecompressedSize);

int LZ4_decompress_fast_continue(
	LZ4_streamDecode_t* LZ4_streamDecode,
	const char* source,
	char* dest,
	int originalSize);

int LZ4_decompress_safe_usingDict(
	const char* source,
	char* dest,
	int compressedSize,
	int maxDecompressedSize,
	const char* dictStart,
	int dictSize);

int LZ4_decompress_fast_usingDict(
	const char* source,
	char* dest,
	int originalSize,
	const char* dictStart,
	int dictSize);

// lz4hc.h

int LZ4_compress_HC(
	const char* src,
	char* dst,
	int srcSize,
	int maxDstSize,
	int compressionLevel);

int LZ4_sizeofStateHC(void);

int LZ4_compress_HC_extStateHC(
	void* state,
	const char* src,
	char* dst,
	int srcSize,
	int maxDstSize,
	int compressionLevel);

typedef struct LZ4_streamHC_t LZ4_streamHC_t;

LZ4_streamHC_t* LZ4_createStreamHC (void);
int             LZ4_freeStreamHC   (LZ4_streamHC_t* streamHCPtr);
void            LZ4_resetStreamHC  (LZ4_streamHC_t* streamHCPtr, int compressionLevel);

int LZ4_loadDictHC (LZ4_streamHC_t* streamHCPtr, const char* dictionary, int dictSize);
int LZ4_saveDictHC (LZ4_streamHC_t* streamHCPtr, char* safeBuffer, int maxDictSize);

int LZ4_compress_HC_continue(
	LZ4_streamHC_t* streamHCPtr,
	const char* src,
	char* dst,
	int srcSize,
	int maxDstSize);
]]

local C = ffi.load'lz4'
local M = {C = C}

M.version = C.LZ4_versionNumber

--NOTE: user-allocated states must start on 8-byte boundary!
M.sizeof_state = C.LZ4_sizeofState
M.sizeof_state_hc = C.LZ4_sizeofStateHC

M.compress_bound = C.LZ4_compressBound

function M.compress(src, srclen, dst, dstlen, accel, level, state, filldest)
	srclen = srclen or #src
	dstlen = dstlen or #dst
	if level then
		if state then
			dstlen = C.LZ4_compress_HC_extStateHC(state, src, dst, srclen, dstlen, level)
		else
			dstlen = C.LZ4_compress_HC(src, dst, srclen, dstlen, level)
		end
	elseif state then
		dstlen = C.LZ4_compress_fast_extState(state, src, dst, srclen, dstlen, accel or 1)
	elseif accel then
		dstlen = C.LZ4_compress_fast(src, dst, srclen, dstlen, accel)
	elseif filldest then --in this mode, state and accel args are not available
		local srclenp = ffi.new'int[1]'
		srclenp[0] = srclen
		dstlen = C.LZ4_compress_destSize(src, dst, srclenp, dstlen)
		if dstlen == 0 then return nil end
		return dstlen, srclenp[0]
	else
		dstlen = C.LZ4_compress_default(src, dst, srclen, dstlen)
	end
	if dstlen == 0 then
		return nil, 'compress error'
	end
	return dstlen
end

function M.decompress(src, srclen, dst, dstlen, outlen)
	srclen = srclen or #src
	dstlen = dstlen or #dst
	if dict then
		if srclen == true then
			dstlen = C.LZ4_decompress_fast_usingDict(src, dst,
				dstlen, dict, dictsize or #dict)
		else
			dstlen = C.LZ4_decompress_safe_usingDict(src, dst, srclen,
				dstlen, dict, dictsize or #dict)
		end
	elseif outlen then
		dstlen = C.LZ4_decompress_safe_partial(src, dst, srclen, outlen, dstlen)
	elseif srclen == true then
		dstlen = C.LZ4_decompress_fast(src, dst, dstlen)
	else
		dstlen = C.LZ4_decompress_safe(src, dst, srclen, dstlen)
	end
	if dstlen < 0 then
		return nil, 'decompress error', dstlen
	end
	return dstlen
end

local enc = {}
enc.__index = enc

function M.compress_stream(hc)
	local stream = hc and C.LZ4_createStreamHC() or C.LZ4_createStream()
	assert(stream ~= nil)
	return ffi.gc(stream, stream.free)
end

function enc:compress(src, srclen, dst, dstlen, accel)
	local dstlen = C.LZ4_compress_fast_continue(self,
		src, srclen or #src,
		dst, dstlen or #dst,
		accel or 1)
end

function enc:free()
	ffi.gc(self, nil)
	C.LZ4_freeStream(self)
end

enc.reset = C.LZ4_resetStream

function enc:load_dict(dict, dictlen)
	return C.LZ4_loadDict(dict, dictlen or #dict)
end

function enc:save_dict(dict, dictlen)
	return C.LZ4_saveDict(dict, dictlen)
end

local enchc = {}
enchc.__index = enchc

function enchc:free()
	ffi.gc(self, nil)
	C.LZ4_freeStreamHC(self)
end

function enchc:reset(level)
	return C.LZ4_resetStreamHC(self, level or 0)
end

function enchc:compress(src, srclen, dst, dstlen, level)
	local dstlen = C.LZ4_compress_HC_continue(self,
		src, srclen or #src,
		dst, dstlen or #dst,
		level or 0)
end

function enchc:load_dict(dict, dictlen)
	return C.LZ4_loadDictHC(dict, dictlen or #dict)
end

function enchc:save_dict(dict, dictlen)
	return C.LZ4_saveDictHC(dict, dictlen)
end

local dec = {}
dec.__index = dec

function M.decompress_stream()
	local stream = C.LZ4_createStreamDecode()
	assert(stream ~= nil)
	return ffi.gc(stream, stream.free)
end

function dec:free()
	ffi.gc(self, nil)
	C.LZ4_freeStreamDecode(self)
end

function dec:set_dict(dict, dictlen)
	return C.LZ4_setStreamDecode(self, dict, dictlen)
end

function dec:decompress(src, srclen, dst, dstlen)
	local dstlen
	if srclen == true then
		dstlen = C.LZ4_decompress_safe_continue(self, src, dst, srclen, dstlen)
	else
		dstlen = C.LZ4_decompress_fast_continue(self, src, dst, dstlen)
	end
	return dstlen
end

ffi.metatype('LZ4_stream_t', enc)
ffi.metatype('LZ4_streamHC_t', enchc)
ffi.metatype('LZ4_streamDecode_t', dec)


if not ... then
	local lz = M--require'lz4'
	local s = lz.compress_stream()
	--TODO
	--local n = s:compress(src, srclen, dst, dstlen)
	s:free()
end

