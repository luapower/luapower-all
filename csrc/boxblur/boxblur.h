#ifndef BOXBLUR_H
#define BOXBLUR_H

void boxblur_g8(void *src, void *dst,
	int32_t width, int32_t height, int32_t src_stride, int32_t dst_stride,
	int32_t radius, int32_t passes, void* blurx, void* sumx);

void boxblur_8888(void *src, void *dst,
	int32_t width, int32_t height, int32_t src_stride, int32_t dst_stride,
	int32_t radius, int32_t passes, void* blurx, void* sumx);

void boxblur_extend(void *src, int32_t width, int32_t height,
	int32_t src_stride, int32_t bpp, int32_t radius);

#endif
