-- This file was auto-generated. Modify at your own risk.

local ffi = require'ffi'
local C = ffi.load'boxblurlib'
ffi.cdef[[
typedef struct {
	int32_t w;
	int32_t h;
	uint8_t* pixels;
	int64_t capacity;
	int32_t stride;
	int8_t format;
} Bitmap;
Bitmap new(int32_t, int32_t, int8_t, int32_t);
enum {
	BLUR_FORMAT_ARGB32 = 2,
	BLUR_FORMAT_G8 = 1,
	BLUR_FORMAT_INVALID = 0,
};
typedef struct {
	int32_t w;
	int32_t h;
	int8_t format;
	int32_t max_w;
	int32_t max_h;
	int32_t max_radius;
	Bitmap bmp1;
	Bitmap bmp1_parent;
	Bitmap bmp2;
	Bitmap bmp2_parent;
	Bitmap blurx;
	Bitmap blurx_parent;
	int16_t* sumx;
	int32_t sumx_size;
	Bitmap* src;
	Bitmap* dst;
	uint8_t radius;
	uint8_t passes;
	bool valid;
} Blur;
Bitmap* Blur_blur(Blur*);
void Blur_invalidate(Blur*);
Bitmap* Blur_invalidate_rect(Blur*, int32_t, int32_t, uint8_t, uint8_t);
void Blur_free(Blur*);
Blur* blur(int8_t);
]]
ffi.metatype('Blur', {__index = {
	blur = C.Blur_blur,
	free = C.Blur_free,
	invalidate = C.Blur_invalidate,
	invalidate_rect = C.Blur_invalidate_rect,
}})
return C
