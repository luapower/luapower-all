
--rsync algorithm in Lua.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'rsync_test' end

local ffi = require'ffi'
local bit = require'bit'

--rolling sum algorithm

local R = 31 --keep this a prime number

local rollsum = ffi.typeof[[
struct {
	uint32_t count; /* count of bytes included in sum */
	uint32_t s1;    /* s1 part of sum */
	uint32_t s2;    /* s2 part of sum */
}
]]

local rs = {}
rs.__index = rs

function rs.reset(sum)
	ffi.fill(sum, ffi.sizeof(sum))
end

function rs.rotate(sum, outc, inc)
	sum.s1 = sum.s1 + (inc - outc)
	sum.s2 = sum.s2 + sum.s1 - sum.count * (outc + R)
end

function rs.rollin(sum, c)
	sum.s1 = sum.s1 + (c + R)
	sum.s2 = sum.s2 + sum.count * (c + R)
	sum.count = sum.count + 1
end

function rs.rollout(sum, c)
	sum.s1 = sum.s1 - (c + R)
	sum.s2 = sum.s2 - sum.count * (c + R)
	sum.count = sum.count - 1
end

local shl, bor, band = bit.lshift, bit.bor, bit.band
function rs.final(sum)
	return bor(shl(sum.s2, 16), band(sum.s1, 0xffff))
end

function rs.update(sum, buf, len)
	local s1 = sum.s1
	local s2 = sum.s2
	sum.count = sum.count + len
	for i = 0, len-1 do
		s1 = s1 + buf[i] + R
		s2 = s2 + s1
	end
	sum.s1 = s1
	sum.s2 = s2
end

ffi.metatype(rollsum, rs)

--rsync module

local rsync = {}

function rsync:new(config) --create a derived module with overriden config
	local mod = setmetatable({}, {__index = rsync})
	if config then
		for k,v in pairs(config) do
			mod[k] = v
		end
	end
	return mod
end

rsync.rollsum = rollsum
rsync.block_len = 1024
rsync.mem_len = 1024 * 64

rsync.weak_sum = rollsum

function rsync:strong_sum()
	return require'blake2'.blake2sp_digest()
end

local function buffer_filler(read)
	return function(p, len)
		local total_len = 0
		while total_len < len do
			local read_len = assert(read(p, len))
			if read_len == 0 then --eof
				break
			end
			total_len = total_len + read_len
			p = p + read_len
		end
		return total_len
	end
end

function rsync:block_buffer(block_len, min_blocks)
	local min_len = (min_blocks or 1) * block_len
	local mem_len = math.max(min_len, self.mem_len)
	if mem_len % block_len ~= 0 then --make it multiple of block_len
		mem_len = mem_len - (mem_len % block_len) + block_len
	end
	return ffi.new('uint8_t[?]', mem_len), mem_len
end

--generate weak and strong signatures for all the blocks of a stream.
function rsync:gen_sigs(read, get_sigs, block_len)
	read = buffer_filler(read)
	local block_len = block_len or self.block_len
	local mem, mem_len = self:block_buffer(block_len)
	local weak_sum = self:weak_sum()
	local strong_sum = self:strong_sum()
	local sig_count = 0
	repeat
		local len = read(mem, mem_len)
		for offset = 0, len-block_len, block_len do
			weak_sum   :reset()
			strong_sum :reset()
			weak_sum   :update(mem + offset, block_len)
			strong_sum :update(mem + offset, block_len)
			get_sigs(weak_sum, strong_sum)
			sig_count = sig_count + 1
		end
	until len < mem_len
	return sig_count
end

--generate deltas for a stream and a list of strong+weak signature pairs
function rsync:gen_deltas(read, sigs, write_cmd, block_len)

	read = buffer_filler(read)
	local weak_sigs = sigs.weak
	local strong_sigs = sigs.strong
	local block_len = block_len or self.block_len
	local mem, mem_len = self:block_buffer(block_len, 2)
	local data = mem + 0
	local block = mem + 0
	local data_len = read(mem, mem_len)

	local weak_sum = self:weak_sum()
	local strong_sum = self:strong_sum()

	--take a function which operates on a buffer segment and which has the
	--same effect if called multiple times on consecutive pieces of that
	--segment and turn it into a function that works on a ringbuffer.
	local function split(f)
		return function(p, len)
			assert(len > 0)
			assert(len <= mem_len)
			if p - mem + len > mem_len then
				local len1 = mem_len - (p - mem)
				local r1 = f(p, len1)
				local r2 = f(mem, len - len1)
				return r1, r2
			else
				return f(p, len), 0
			end
		end
	end

	local update_weak_sum = split(function(p, len)
		weak_sum:update(p, len)
	end)

	local update_strong_sum = split(function(p, len)
		strong_sum:update(p, len)
	end)

	local write_data = split(function(p, len)
		assert(p - mem + len <= mem_len)
		write_cmd('data', p, len)
	end)

	local load_data = split(read)

	local function ptr_inc(p, len)
		if (p - mem) + len >= mem_len then
			return p + len - mem_len
		else
			return p + len
		end
	end

	local function ptr_diff(p1, p2)
		local diff = p1 - p2
		if diff < 0 then
			return diff + mem_len
		else
			return diff
		end
	end

	local function load_more_data(required_len)
		local free_len = mem_len - data_len
		assert(free_len >= required_len)
		local free = ptr_inc(data, data_len)
		local len1, len2 = load_data(free, free_len)
		local len = len1 + len2
		data_len = data_len + len
		return len >= required_len
	end

	local function write_data_before_block()
		local write_len = ptr_diff(block, data)
		if write_len == 0 then return end
		write_data(data, write_len)
		data = block
		data_len = data_len - write_len
	end

	local false_alarms = 0
	local good_alarms = 0

	local block_num, n

	if data_len < block_len then
		goto finish
	end

	::check_new_block::
	weak_sum:reset()
	update_weak_sum(block, block_len)

	::check_block::
	if not weak_sigs[weak_sum:final()] then
		goto advance_block
	end

	::check_strong_sum::
	strong_sum:reset()
	update_strong_sum(block, block_len)
	block_num = strong_sigs[strong_sum:final()]
	if not block_num then
		false_alarms = false_alarms + 1
		goto advance_block
	end
	good_alarms = good_alarms + 1

	write_data_before_block()

	write_cmd('copy', block_num)
	block = ptr_inc(block, block_len)
	data = block
	data_len = data_len - block_len

	if data_len < block_len then
		if not load_more_data(block_len - data_len) then
			goto finish
		end
	end
	goto check_new_block

	::advance_block::
	n = data_len - (ptr_diff(block, data) + block_len)
	if n == 0 then
		write_data_before_block()
		if not load_more_data(1) then
			goto finish
		end
		goto advance_block
	end
	for i=0,n-1 do --hot loop (byte-by-byte check)
		weak_sum:rotate(
			ptr_inc(block, i)[0],             --last byte
			ptr_inc(block, i + block_len)[0]  --next byte
		)
		if weak_sigs[weak_sum:final()] then
			block = ptr_inc(block, i + 1)
			goto check_strong_sum
		end
	end
	block = ptr_inc(block, n)
	goto advance_block

	::finish::
	if data_len > 0 then
		write_data(data, data_len)
	end
	write_cmd()

	return false_alarms, good_alarms
end

function rsync:patch(read_cmd, seek, read, write, block_len)
	read = buffer_filler(read)
	local block_len = block_len or self.block_len
	local mem, mem_len = self:block_buffer(block_len)
	for cmd, arg1, arg2 in read_cmd do
		if cmd == 'copy' then
			local offset = arg1 * block_len --arg1 is block_num
			seek(offset)
			read(mem, block_len)
			write(mem, block_len)
		elseif cmd == 'data' then
			write(arg1, arg2)
		end
	end
end

--serialization and deserialization of signatures, deltas and patching.

function rsync:weak_sig_ctype()
	return ffi.typeof'int32_t'
end

function rsync:strong_sig_ctype()
	return ffi.typeof('uint8_t[$]', self:strong_sum():length())
end

function rsync:sig_ctype()
	return ffi.typeof([[
		struct __attribute__((__packed__)) {
			$ weak_sig;
			$ strong_sig;
		} ]], self:weak_sig_ctype(), self:strong_sig_ctype())
end

function rsync:sigs_buffer()
	local sig_ctype = self:sig_ctype()
	local sig_len = ffi.sizeof(sig_ctype)
	local buf, len = self:block_buffer(sig_len)
	local sigs = ffi.cast(ffi.typeof('$*', sig_ctype), buf)
	local sig_count = len / sig_len
	return sigs, sig_count, buf, len
end

local pass = function(x) return x end
local bswap32 = ffi.abi'le' and pass or bit.bswap

function rsync:write_sig(sigs, i, weak_sig, strong_sig)
	sigs[i].weak_sig = bswap32(weak_sig:final())
	strong_sig:final_to_buffer(sigs[i].strong_sig)
end

function rsync:gen_sigs_file(read, write, block_len)
	local sigs, sig_count, buf, len = self:sigs_buffer()
	local write_sig = self.write_sig
	local i = 0
	local function get_sigs(weak_sig, strong_sig)
		write_sig(self, sigs, i, weak_sig, strong_sig)
		i = i + 1
		if i == sig_count then
			write(buf, len)
			i = 0
		end
	end
	local total_sig_count = self:gen_sigs(read, get_sigs, block_len)
	if i > 0 then --leftovers
		local p1 = ffi.cast('const char*', sigs[0])
		local p2 = ffi.cast('const char*', sigs[i])
		write(p1, p2 - p1)
	end
	return total_sig_count
end

function rsync:read_sig(sigs, i, strong_sig_len)
	return
		bswap32(sigs[i].weak_sig),
		ffi.string(sigs[i].strong_sig, strong_sig_len)
end

function rsync:load_sigs_file(read)
	read = buffer_filler(read)
	local sigs, sig_count, buf, buf_len = self:sigs_buffer()
	local sig_len = buf_len / sig_count
	local read_sig = self.read_sig
	local strong_sig_len = ffi.sizeof(sigs[0].strong_sig)
	local weak_sigs = {}
	local strong_sigs = {}
	local block_num = 0
	local count = 0
	repeat
		local len = read(buf, buf_len)
		local sig_count = len / sig_len
		for i = 0, sig_count-1 do
			local weak_sig, strong_sig = read_sig(self, sigs, i, strong_sig_len)
			weak_sigs[weak_sig] = block_num
			strong_sigs[strong_sig] = block_num
			block_num = block_num + 1
		end
		count = count + sig_count
	until len < buf_len
	return {weak = weak_sigs, strong = strong_sigs, count = count}
end

function rsync:cmd_writer(write)
	local u8 = ffi.new'uint8_t[1]'
	local u32 = ffi.new'uint32_t[1]'
	local block, block_count
	local function write_copy_range()
		if not block then return end
		assert(block <= 2^32-1) --max file size is 4TB for block_len=1024
		assert(block_count <= 255)
		u8[0] = 2
		write(u8, 1)
		u32[0] = bswap32(block)
		write(u32, 4)
		u8[0] = block_count
		write(u8, 1)
		block, block_count = nil
	end
	return function(cmd, arg1, arg2)
		if cmd == 'data' then
			write_copy_range()
			u8[0] = 1
			write(u8, 1)
			u32[0] = bswap32(arg2) --len
			write(u32, 4)
			write(arg1, arg2) --buf,len
		elseif cmd == 'copy' then
			if block and arg1 == block + block_count and block_count < 255 then
				block_count = block_count + 1
			else
				write_copy_range()
				block, block_count = arg1, 1
			end
		elseif not cmd then
			write_copy_range()
		end
	end
end

function rsync:cmd_reader(read)
	local u8 = ffi.new'uint8_t[1]'
	local u32 = ffi.new'uint32_t[1]'
	local buf, buf_len = self:block_buffer(1)
	local read = buffer_filler(read)
	return coroutine.wrap(function()
		while read(u8, 1) == 1 do
			if u8[0] == 1 then --data
				assert(read(u32, 4) == 4)
				local len = tonumber(u32[0])
				while len > 0 do
					local toread = math.min(len, buf_len)
					assert(read(buf, toread) == toread)
					coroutine.yield('data', buf, toread)
					len = len - toread
				end
			elseif u8[0] == 2 then --copy
				assert(read(u32, 4) == 4)
				local block_num = tonumber(u32[0])
				assert(read(u8, 1) == 1)
				local block_count = tonumber(u8[0])
				for i = 1, block_count do
					coroutine.yield('copy', block_num + i - 1)
				end
			end
		end
	end)
end

function rsync:gen_deltas_file(read, sigs, write, block_len)
	local write_cmd = self:cmd_writer(write)
	return self:gen_deltas(read, sigs, write_cmd, block_len)
end

function rsync:patch_file(read_delta, seek, read, write, block_len)
	local read_cmd = self:cmd_reader(read_delta)
	return self:patch(read_cmd, seek, read, write, block_len)
end

return rsync
