/*
	Fast box blur algorithm for bgra8 and g8 pixel formats.
	Written by Cosmin Apreutesei. Public Domain.

	Compile with: gcc boxblur.c -ansi -pedantic -Wall -msse2 -O3
*/

#include <x86intrin.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#ifdef SSE
	#define X_INC 8
#else
	#define X_INC 1
#endif

typedef uint8_t u8;
typedef int16_t i16;
typedef int32_t i32;

void boxblur_g8(u8 *src, u8 *dst, i32 width, i32 height,
	i32 src_stride, i32 dst_stride, i32 radius, i32 passes,
	i16* blurx, i16* sumx)
{
	int x, y;
	i16 factor;
#ifdef SSE
	__m128i factors;
#endif

	factor = 65536 / (2 * radius + 1);
#ifdef SSE
	factors = _mm_set1_epi16(factor);
#endif
	for (y = -radius; y < height + radius; y++) {

		int i;
		i16 S;
		u8 *row, *dstrow;
		i16 *xrow, *xrow0;

		row = src + y * src_stride;
		xrow0 = blurx + (y - 2 * radius - 1) * src_stride;
		xrow = blurx + y * src_stride;
		dstrow = dst + (y - radius) * dst_stride;

		S = 0;
		for (i = (-radius - 1); i < radius; i++) {
			S += row[i];
		}

		/* moving average on x */
		for (x = 0; x < width; x ++) {
			S = S + row[x+radius] - row[x-radius-1];
			xrow[x] = (S * factor) >> 16;
		}

		/* moving average on y */
		for (x = 0; x < width; x += X_INC) {
#ifndef SSE
			sumx[x] = sumx[x] + xrow[x] - xrow0[x];
			dstrow[x] = (sumx[x] * factor) >> 16;
#else
			__m128i sumxx = _mm_adds_epi16(
				_mm_loadu_si128((__m128i*)&sumx[x]),
				_mm_sub_epi16(
					_mm_loadu_si128((__m128i*)&xrow[x]),
					_mm_loadu_si128((__m128i*)&xrow0[x])));

			_mm_storeu_si128((__m128i*)&sumx[x], sumxx);

			_mm_storeu_si128((__m128i*)&dstrow[x],
				_mm_packus_epi16(
					_mm_mulhi_epi16(sumxx, factors),
					_mm_setzero_si128()));
#endif
		}
	}

}

void boxblur_8888(u8 *src, u8 *dst, i32 width, i32 height,
	i32 src_stride, i32 dst_stride, i32 radius, i32 passes,
	i16* blurx, i16* sumx)
{

	int x, y;
	i16 factor;
#ifdef SSE
	__m128i factors;
#endif

	factor = 65536 / (2 * radius + 1);
#ifdef SSE
	factors = _mm_set1_epi16(factor);
#endif

	for (y = -radius; y < height + radius; y++) {

		int i;
		i16 S0, S1, S2, S3;
		u8 *row, *dstrow;
		i16 *xrow, *xrow0;

		row = src + y * src_stride;
		xrow0 = blurx + (y - 2 * radius - 1) * src_stride;
		xrow = blurx + y * src_stride;
		dstrow = dst + (y - radius) * dst_stride;

		S0 = 0;
		S1 = 0;
		S2 = 0;
		S3 = 0;

		for (i = (-radius-1) * 4; i < radius * 4; i += 4) {
			S0 += row[i+0];
			S1 += row[i+1];
			S2 += row[i+2];
			S3 += row[i+3];
		}

		for (x = 0; x < width * 4; x += 4) {
			/* moving average on x */
			S0 = S0 + row[x + radius * 4 + 0] - row[x + (-radius-1) * 4 + 0];
			S1 = S1 + row[x + radius * 4 + 1] - row[x + (-radius-1) * 4 + 1];
			S2 = S2 + row[x + radius * 4 + 2] - row[x + (-radius-1) * 4 + 2];
			S3 = S3 + row[x + radius * 4 + 3] - row[x + (-radius-1) * 4 + 3];
			/* horizontal blur */
#ifndef SSE
			xrow[x+0] = (S0 * factor) >> 16;
			xrow[x+1] = (S1 * factor) >> 16;
			xrow[x+2] = (S2 * factor) >> 16;
			xrow[x+3] = (S3 * factor) >> 16;
#else
			_mm_storeu_si128((__m128i*)&xrow[x],
				_mm_mulhi_epi16(
					_mm_set_epi16(0, 0, 0, 0, S3, S2, S1, S0),
					factors));
#endif
		}

		/* moving average on y */
		for (x = 0; x < width * 4; x += X_INC) {
#ifndef SSE
			sumx[x] = sumx[x] + xrow[x] - xrow0[x];
			dstrow[x] = (sumx[x] * factor) >> 16;
#else
			__m128i sumxx = _mm_adds_epi16(
				_mm_loadu_si128((__m128i*)&sumx[x]),
				_mm_sub_epi16(
					_mm_loadu_si128((__m128i*)&xrow[x]),
					_mm_loadu_si128((__m128i*)&xrow0[x])));

			_mm_storeu_si128((__m128i*)&sumx[x], sumxx);

			_mm_storeu_si128((__m128i*)&dstrow[x],
				_mm_packus_epi16(
					_mm_mulhi_epi16(sumxx, factors),
					_mm_setzero_si128()));
#endif
		}
	}

}

void boxblur_extend(u8 *src, i32 width, i32 height,
	i32 src_stride, i32 bpp, i32 radius)
{
	int y, x;
	bpp = bpp >> 3;

	/* extend source image top and bottom sides */
	for (y = -radius; y < 0; y++) {
		u8* row = src + y * src_stride;
		memcpy(row, src, src_stride);
	}
	for (y = height; y < height + radius; y++) {
		u8* row = src + y * src_stride;
		memcpy(row, src + (height - 1) * src_stride, src_stride);
	}

	/* extend source image left and right sides */
	for (y = -radius; y < height + radius; y++) {
		u8* row = src + y * src_stride;
		for (x = -radius * bpp; x < 0; x += bpp) {
			memcpy(row + x, row, bpp);
		}
		for (x = width * bpp; x < (width + radius) * bpp; x += bpp) {
			memcpy(row + x, row + (width - 1) * bpp, bpp);
		}
	}

}

