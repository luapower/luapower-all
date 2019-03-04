#ifndef BOXBLUR_H
#define BOXBLUR_H

#include <stdint.h>
typedef uint8_t u8;
typedef int16_t i16;
typedef int32_t i32;

void boxblur_g8(u8 *src, u8 *dst, i32 width, i32 height,
	i32 src_stride, i32 dst_stride, i32 radius, i32 passes,
	i16* blurx, i16* sumx);

void boxblur_8888(u8 *src, u8 *dst, i32 width, i32 height,
	i32 src_stride, i32 dst_stride, i32 radius, i32 passes,
	i16* blurx, i16* sumx);

void boxblur_extend(u8 *src, i32 width, i32 height,
	i32 src_stride, i32 bpp, i32 radius);

#endif
