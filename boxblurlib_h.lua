local ffi = require'ffi'
local C = ffi.load'boxblurlib'
ffi.cdef[[
typedef struct Bitmap Bitmap;
typedef struct Blur Blur;
struct Bitmap {
	int32_t w;
	int32_t h;
	uint8_t* pixels;
	int32_t stride;
	int8_t format;
};
Bitmap bitmap(int32_t, int32_t, int8_t, int32_t);
void Blur_invalidate(Blur*);
Bitmap* Blur_invalidate_rect(Blur*, int32_t, int32_t, uint8_t, uint8_t);
Bitmap* Blur_blur(Blur*);
void Blur_free(Blur*);
Blur* blur(int8_t);
]]
ffi.metatype('Bitmap', {__index = {
}})
ffi.metatype('Blur', {__index = {
	invalidate = C.Blur_invalidate,
	invalidate_rect = C.Blur_invalidate_rect,
	blur = C.Blur_blur,
	free = C.Blur_free,
}})
ffi.cdef[[
enum {
	BITMAP_ARGB32 = 2,
	BITMAP_COPY = 0,
	BITMAP_G8 = 1,
	BITMAP_INVALID = 0,
	BITMAP_OVER = 1,
}]]
return C
