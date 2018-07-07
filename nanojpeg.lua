
--nanojpeg2 binding (see csrc/nanojpeg).
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'nanojpeg_demo'; return end

local ffi = require'ffi'
local glue = require'glue'
local C = ffi.load'nanojpeg2'

ffi.cdef[[
typedef struct nj_context_t_ nj_context_t;
nj_context_t* njInit(void);
int njDecode(nj_context_t* nj, const void* jpeg, const int size);
int njGetWidth(nj_context_t* nj);
int njGetHeight(nj_context_t* nj);
int njIsColor(nj_context_t* nj);
uint8_t* njGetImage(nj_context_t* nj);
void njFreeImage(uint8_t* image);
int njGetImageSize(nj_context_t* nj);
void njDone(nj_context_t* nj);
]]

local error_messages = {
	'Not a JPEG file',
	'Unsupported format',
	'Out of memory',
	'Internal error',
	'Syntax error',
}

local function load(t)
	local s, data, sz
	if type(t) == 'string' then
		s = t
	elseif t.path then
		s = assert(glue.readfile(t.path))
	elseif t.string then
		s = t.string
	elseif t.cdata then
		data, sz = t.cdata, t.size
	else
		error'source missing'
	end
	if s then
		data, sz = ffi.cast('const char*', s), #s
	end

	return glue.fcall(function(finally)
		local nj = C.njInit()
		finally(function() C.njDone(nj) end)

		local res = C.njDecode(nj, data, sz)
		assert(res == 0, error_messages[res])

		local img = {}
		img.w = C.njGetWidth(nj)
		img.h = C.njGetHeight(nj)
		img.format = C.njIsColor(nj) == 1 and 'rgb8' or 'g8'
		img.stride = img.w * (C.njIsColor(nj) == 1 and 3 or 1)
		img.orientation = 'top_down'
		img.size = C.njGetImageSize(nj)
		img.data = C.njGetImage(nj) --pointer to RGB888[] or G8[]
		ffi.gc(img.data, C.njFreeImage)
		return img
	end)
end

return {
	load = load,
	C = C,
}

