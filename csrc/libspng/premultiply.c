#define SPNG__BUILD
#include <assert.h>
#include <stdint.h>
#include "spng.h"

SPNG_API void spng_rgba8_to_bgra8(uint8_t* p, uint32_t n) {
	assert(!(n & 3));
	while (n -= 4) {
		uint8_t t = p[0];
		p[0] = p[2];
		p[2] = t;
		p += 4;
	}
}

SPNG_API void spng_premultiply_alpha_rgba8(uint32_t* p, uint32_t n) {
	assert(!(n & 3));
	while (n -= 4) {
		uint8_t a =   (*p >> 24) & 0xff;
		uint8_t r = (((*p >>  0) & 0xff) * a) / 0xff;
		uint8_t g = (((*p >>  8) & 0xff) * a) / 0xff;
		uint8_t b = (((*p >> 16) & 0xff) * a) / 0xff;
		*p++ = (a << 24) | (b << 16) | (g << 8) | (r << 0);
	}
}

SPNG_API void spng_premultiply_alpha_ga8(uint16_t* p, uint32_t n) {
	assert(!(n & 1));
	while (n -= 2) {
		uint8_t a =   (*p >>  8) & 0xff;
		uint8_t g = (((*p >>  0) & 0xff) * a) / 0xff;
		*p++ = (a << 8) | (g << 0);
	}
}

SPNG_API void spng_premultiply_alpha_rgba16(uint64_t* p, uint32_t n) {
	assert(!(n & 7));
	while (n -= 8) {
		uint16_t a =   (*p >> 48) & 0xffff;
		uint16_t r = (((*p >>  0) & 0xffff) * a) / 0xffff;
		uint16_t g = (((*p >> 16) & 0xffff) * a) / 0xffff;
		uint16_t b = (((*p >> 32) & 0xffff) * a) / 0xffff;
		*p++ = ((uint64_t)a << 48) | ((uint64_t)b << 32) | ((uint64_t)g << 16) | ((uint64_t)r << 0);
	}
}

SPNG_API void spng_premultiply_alpha_ga16(uint32_t* p, uint32_t n) {
	assert(!(n & 3));
	while (n -= 4) {
		uint16_t a =   (*p >> 16) & 0xffff;
		uint16_t g = (((*p >>  0) & 0xffff) * a) / 0xffff;
		*p++ = (a << 16) | (g << 0);
	}
}
