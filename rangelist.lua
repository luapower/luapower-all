
--One-dimension non-overlapping selection ranges.
--Written by Cosmin Apreutesei. Public Domain.

local glue = require'glue'

local push = table.insert
local pop = table.insert
local binsearch = glue.binsearch
local shift = glue.shift

local ranges = {}
setmetatable(ranges, ranges)

function ranges:__call()
	self = {offsets = {}, lengths = {}, __index = self}
	return setmetatable(self, self)
end

--return index of next non-overlapping non-touching range from range `(i, len)`.
function ranges:next_range_index(i, len, k1, k2)
	k1 = k1 or 1
	k2 = k2 or #self.offsets
	return binsearch(i + len + 1, self.offsets, nil, k1, k2) or k2 + 1
end

--return index of prev. non-overlapping non-touching range from position `i`.
local function cmp(t, i, v)
	return t.offsets[i] + t.lengths[i] < v
end
function ranges:prev_range_index(i, k1, k2)
	k1 = k1 or 1
	k2 = k2 or #self.offsets
	return (binsearch(i, self, cmp, k1, k2) or k2 + 1) - 1
end

--return true if `i` is inside a range, and the index of that range,
--or if not inside a range, the index of the previous range.
--NOTE: returned k can be 0 when not inside a range.
function ranges:hit_test(i, k1, k2)
	--find the range which either overlaps i or is the last one before i.
	local k = self:next_range_index(i, 0, k1, k2) - 1
	local offset2 = k > 0 and self.offsets[k] + self.lengths[k] or 0
	return i < offset2, k
end

--return the first and last indices of the sub-array of ranges which are near
--and/or overlap an arbitrary range, and the number of overlapping ranges.
function ranges:touching_ranges(i, len)
	assert(len >= 1)
	local k2 = self:next_range_index(i, len)
	local k1 = self:prev_range_index(i, 1, k2 - 1)
	local ranges = k2 - k1 - 1
	assert(ranges >= 0)
	return k1+1, k2-1, ranges
end

--shrink or enlarge the arrays representing the ranges.
function ranges:_shift(k, n)
	shift(self.offsets, k, n)
	shift(self.lengths, k, n)
end

--mark all positions in `(i, len)` as selected.
function ranges:select(i, len, selected)
	if selected == false then
		return self:unselect(i, len)
	end
	if len < 1 then
		return self
	end
	local k1, k2, ranges = self:touching_ranges(i, len)
	if ranges == 0 then --standalone range
		push(self.offsets, k2+1, i)
		push(self.lengths, k2+1, len)
	else --merge with overlapping ranges
		local offset1 = math.min(i, self.offsets[k1])
		local offset2 = math.max(i+len, self.offsets[k2]+self.lengths[k2])
		self:_shift(k1, -(ranges-1)) --keep 1 slot for the replacement range
		self.offsets[k1] = offset1
		self.lengths[k1] = offset2 - offset1
	end
	return self
end

--mark all positions in `(i, len)` as unselected.
function ranges:unselect(i, len)
	if len < 1 then
		return self
	end
	local k1, k2, ranges = self:touching_ranges(i, len)
	if ranges == 0 then return end
	local offset2_r1 = i
	local offset1_r1 = self.offsets[k1]
	local len_r1 = offset2_r1 - offset1_r1
	local offset1_r2 = i+len
	local offset2_r2 = self.offsets[k2]+self.lengths[k2]
	local len_r2 = offset2_r2 - offset1_r2
	if len_r1 > 0 and len_r2 > 0 and ranges == 1 then --split range
		k2 = k1+1
		self:_shift(k2, 1)
		self.lengths[k1] = len_r1
		self.offsets[k2] = offset1_r2
		self.lengths[k2] = len_r2
	else
		if len_r1 > 0 then --shorten first range
			self.lengths[k1] = len_r1
			ranges = ranges - 1 --keep this range
			k1 = k1 + 1
		end
		if len_r2 > 0 then --shorten second range
			self.offsets[k2] = offset1_r2
			self.lengths[k2] = len_r2
			ranges = ranges - 1 --keep this range
		end
		assert(ranges >= 0)
		self:_shift(k1, -ranges)
	end
	return self
end

--remove `(i, len)` positions, shifting the selection ranges as needed.
function ranges:remove(i, len)
	self:unselect(i, len)
	--shift all offsets of all subsequent ranges to the left.
	--NOTE: using len-1 to include the eventual range that starts exactly
	--after the removed range.
	local k = self:next_range_index(i, len-1)
	for k = k, #self.offsets do
		self.offsets[k] = self.offsets[k] - len
	end
	--merge remaining ranges if they are exactly near each other.
	if k > 1 and k <= #self.offsets
		and self.offsets[k-1] + self.lengths[k-1] == self.offsets[k]
	then
		self.lengths[k-1] = self.lengths[k-1] + self.lengths[k]
		self:_shift(k, -1)
	end
end

--insert `(i, len)` positions, shifting the selection ranges as needed.
function ranges:insert(i, len, selected)
	local inside, k = self:hit_test(i)
	if inside then --enlarge range
		self.lengths[k] = self.lengths[k] + len
	end
	--shift all offsets of all subsequent ranges to the right.
	for k = k + 1, #self.offsets do
		self.offsets[k] = self.offsets[k] + len
	end
end

--create a state that is capable of hit testing the ranges in O(1)
--whenever hit_test() is called with the index of the last call + 1.
function ranges:cursor(n)
	local offsets = self.offsets
	local lengths = self.lengths

	local i, inside, k, next_on_i, next_off_i --cursor state

	local function seek(_, target_i)
		local inside, k1 = self:hit_test(target_i)
		k = k1 + (inside and 0 or 1)
		next_on_i = offsets[k]
		next_off_i = next_on_i and next_on_i + lengths[k]
		i = target_i - 1
	end

	local function next()
		if i == n then --out of range
			return nil
		end
		i = i + 1
		if not next_on_i then --after last range
			inside = false
		elseif i < next_on_i then --before next range
			inside = false
		elseif i < next_off_i then --inside range
			inside = true
		else --end-of-range, load next range
			k = k + 1
			next_on_i = offsets[k]
			next_off_i = next_on_i and next_on_i + lengths[k]
			--there should be no glued ranges
			assert(not next_on_i or next_on_i > i)
			inside = false
		end
		return i, inside
	end

	local function hit_test(_, target_i)
		if target_i == i then
			--`inside` already loaded
		elseif target_i - 1 == i then
			next()
		else
			seek(_, target_i)
			next()
		end
		return inside
	end

	return {next = next, seek = seek, hit_test = hit_test}
end

--debugging

function ranges:load(t) --load ranges from a flat array of {offset, len, ...}
	self.offsets = {}
	self.lengths = {}
	local n = math.floor(#t / 2)
	for i = 1, n do
		self.offsets[i] = t[i * 2 - 1]
		self.lengths[i] = t[i * 2]
	end
	return self
end

function ranges:format() --pretty-print ranges
	local t = {}
	for i = 1, #self.offsets do
		t[#t+1] = tostring(self.offsets[i])
		t[#t+1] = '-'
		t[#t+1] = tostring(self.offsets[i] + self.lengths[i] - 1)
		t[#t+1] = ' '
	end
	return table.concat(t)
end

--tests

if not ... then

local function test(f, r, i, len)
	local s = string.format('%-24s %-10s %d-%d', r:format(), f, i, i+len-1)
	r[f](r, i, len)
	print(string.format('%-44s ->  %s', s, r:format()))
end

local r = ranges()
test('select', r, 5, 3) --empty
test('select', r, 14, 2) --after
test('select', r, 1, 3) --before
test('select', r, 18, 3) --after
test('select', r, 1, 4) --near
test('select', r, 1, 5) --overlapping partially
test('select', r, 1, 7) --overlapping totally
test('select', r, 1, 10) --overlapping and beyond
test('select', r, 13, 1) --near 2nd
test('select', r, 14, 1) --overlapping 2nd
test('select', r, 14, 2) --overlapping totally
test('select', r, 2, 20) --enclosing all
test('select', r, 22, 2) --near to the right
test('select', r, 50, 2) --after
test('select', r, 25, 24) --in between
test('unselect', r, 100, 100) --nothing
test('unselect', r, 24, 1) --non-overlapping but near both sides
test('unselect', r, 24, 6) --overlapping right side
test('unselect', r, 21, 3) --overlapping left side
test('unselect', r, 16, 10) --overlapping left side and beyond
test('unselect', r, 11, 30) --overlapping both sides
test('unselect', r, 3, 3) --split range
test('unselect', r, 1, 5) --enclose range
test('unselect', r, 1, 10) --enclose range
test('unselect', r, 1, 51) --remove all
test('insert', r, 10, 10) --insert on empty
test('remove', r, 10, 10) --remove on empty
test('select', r, 1, 10)
test('select', r, 21, 10)
test('insert', r, 5, 10) --enlarge range, shift subs. ranges
test('insert', r, 1, 10) --enlarge range, shift subs. ranges
test('unselect', r, 1, 20)
test('insert', r, 20, 10) --shift subs. ranges
test('insert', r, 61, 10) --after
test('remove', r, 36, 20) --unselect, shift and merge
test('remove', r, 41, 20) --after
test('remove', r, 21, 10) --shift (no enlarge)

end

return ranges
