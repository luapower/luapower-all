
// lock-free ring buffer.
// Written by Cosmin Apreutesei. Public Domain.
// Origins in libsound.io by Andrew Kelley. MIT License.

#include "lfrb.hpp"
#include <stdlib.h>
#include <assert.h>

int lfrb_write_index(struct lfrb_state *rb) {
	return rb->write_offset % rb->capacity;
}

void lfrb_advance_write_index(struct lfrb_state *rb, int count) {
	rb->write_offset += count;
	assert(lfrb_fill_count(rb) >= 0);
}

int lfrb_read_index(struct lfrb_state *rb) {
	return rb->read_offset % rb->capacity;
}

void lfrb_advance_read_index(struct lfrb_state *rb, int count) {
	rb->read_offset += count;
	assert(lfrb_fill_count(rb) >= 0);
}

int lfrb_fill_count(struct lfrb_state *rb) {
	int count = rb->write_offset - rb->read_offset;
	assert(count >= 0);
	assert(count <= rb->capacity);
	return count;
}

int lfrb_free_count(struct lfrb_state *rb) {
	return rb->capacity - lfrb_fill_count(rb);
}

void lfrb_clear(struct lfrb_state *rb) {
	return rb->write_offset.store(rb->read_offset.load());
}
