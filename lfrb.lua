
--lock-free ring buffer.
--Written by Cosmin Apreutesei. Public Domain.
--Origins in libsound.io by Andrew Kelley. MIT License.

local ffi = require'ffi'

ffi.cdef[[
struct lfrb_state {
	long _write_offset;
	long _read_offset;
	int capacity;
	char data[?];
};
int lfrb_write_index(struct lfrb_state*);
void lfrb_advance_write_index(struct lfrb_state*, int count);
int lfrb_read_index(struct lfrb_state*);
void lfrb_advance_read_index(struct lfrb_state*, int count);
int lfrb_fill_count(struct lfrb_state*);
int lfrb_free_count(struct lfrb_state*);
void lfrb_clear(struct lfrb_state*);
]]

local C = ffi.load'lfrb'
local M = {C = C}

function M.new(capacity)
	local rb = ffi.new('struct lfrb_state', capacity)
	rb.capacity = capacity
	return rb
end

function M.wrap(buffer_addr)
	return ffi.cast('struct lfrb_state*', buffer_addr)
end

--TODO: read_segments, write_segments

ffi.metatype('struct lfrb_state', {__index = {
	write_index = C.lfrb_write_index,
	advance_write_index = C.lfrb_advance_write_index,
	read_index = C.lfrb_read_index,
	advance_read_index = C.lfrb_advance_read_index,
	fill_count = C.lfrb_fill_count,
	free_count = C.lfrb_free_count,
	clear = C.lfrb_clear,
}})

if not ... then
	io.stdout:setvbuf'no'
	local lfrb = M
	local pthread = require'pthread'
	local lua = require'luastate'
	local time = require'time'

	local state = lua.open()
	state:openlibs()
	state:push(function(rb_addr, trials, maxpause)
		local ffi = require'ffi'
		local lfrb = require'lfrb'
		local time = require'time'
		local rb = lfrb.wrap(rb_addr)
		local function func()
			for i = 1, trials do
				local n = rb:fill_count()
				local n = math.floor(math.random() * n)
				if n > 0 then
					io.stdout:write(string.format('read  %4d [%3d%%]\n', n, rb:fill_count() / rb.capacity * 100))
					rb:advance_read_index(n)
				end
				time.sleep(math.random() * maxpause)
			end
		end
		local cb = ffi.cast('void *(*)(void *)', func)
		local cb_addr = tonumber(ffi.cast('intptr_t', cb))
		return cb_addr
	end)

	local trials = 10^6
	local maxpause = 0

	local rb = lfrb.new(1000)
	local rb_addr = tonumber(ffi.cast('intptr_t', ffi.cast('void*', rb)))
	local cb_addr = state:call(rb_addr, trials, maxpause)
	local cb = ffi.cast('void*', cb_addr)
	local thread = pthread.new(cb)

	for i = 1, trials do
		local n = rb:free_count()
		local n = math.floor(math.random() * n)
		if n > 0 then
			io.stdout:write(string.format('write %4d [%3d%%]\n', n, rb:fill_count() / rb.capacity * 100))
			rb:advance_write_index(n)
		end
		time.sleep(math.random() * maxpause)
	end

	thread:join()
end

return M
