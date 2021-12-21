
// lock-free ring buffer.
// Written by Cosmin Apreutesei. Public Domain.
// Origins in libsound.io by Andrew Kelley. MIT License.

#ifndef LFRB_H
#define LFRB_H

#include <atomic>
using std::atomic_long;

#if ATOMIC_LONG_LOCK_FREE != 2
#error "require atomic_long to be lock free"
#endif

struct lfrb_state {
	atomic_long write_offset;
	atomic_long read_offset;
	int capacity;
};

extern "C" {
	int lfrb_write_index(struct lfrb_state*);
	void lfrb_advance_write_index(struct lfrb_state*, int count);
	int lfrb_read_index(struct lfrb_state*);
	void lfrb_advance_read_index(struct lfrb_state*, int count);
	int lfrb_fill_count(struct lfrb_state*);
	int lfrb_free_count(struct lfrb_state*);
	void lfrb_clear(struct lfrb_state*);
};

#endif
