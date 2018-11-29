
-- Unicode UAX#9 rule L2 algorithm for reordering RTL BiDi text runs.
-- Written by Cosmin Apreutesei. Public Domain.

-- Derived from code by Behdad Esfahbod, Copyright (C) 2013 Google, Inc.
-- https://github.com/fribidi/linear-reorder/blob/master/linear-reorder.c

-- Data structures used: `seg` and `range`.
-- A seg is a segment with fields: {bidi_level = level}.
-- A range is an internal structure used by the algorithm with the fields:
--   {left = left_seg, right = right_seg, prev = prev_range}.
-- A range contains the left-most and right-most segs in the range,
-- in visual order. Following left's `next` member eventually gets us to
-- `right`. The right seg's `next_vis` member is undefined.

local bit = require'bit'
local glue = require'glue'

local band = bit.band
local odd = function(x) return band(x, 1) == 1 end

local alloc_range, free_range = glue.freelist()

-- Merges range with previous range and returns the previous range.
local function merge_range_with_prev(range)
	local prev = range.prev
	assert(prev)
	assert(prev.bidi_level < range.bidi_level)

	local left, right
	if odd(prev.bidi_level) then
		-- Odd, previous goes to the right of range.
		left = range
		right = prev
	else
		-- Even, previous goes to the left of range.
		left = prev
		right = range
	end
	--Stich them.
	left.right.next = right.left
	prev.left = left.left
	prev.right = right.right

	free_range(range)
	return prev
end

-- Takes a list of segs on the line in the logical order and
-- reorders the list to be in visual order, returning the
-- left-most seg.
--
-- Caller is responsible to reverse the seg contents for any
-- seg that has an odd level.
--
function reorder_segs(seg)

	-- The algorithm here is something like this: sweep segs in the
	-- logical order, keeping a stack of ranges.  Upon seeing a seg,
	-- we flatten all ranges before it that have a level higher than
	-- the seg, by merging them, reordering as we go.  Then we either
	-- merge the seg with the previous range, or create a new range
	-- for the seg, depending on the level relationship.

	local range
	while seg do
		local next_seg = seg.next_vis

		while range and range.bidi_level > seg.bidi_level
			and range.prev and range.prev.bidi_level >= seg.bidi_level
		do
			range = merge_range_with_prev(range)
		end

		if range and range.bidi_level >= seg.bidi_level then
			-- Attach the seg to the range.
			if odd(seg.bidi_level) then
				-- Odd, range goes to the right of seg.
				seg.next_vis = range.left
				range.left = seg
			else
				-- Even, range goes to the left of seg.
				range.right.next = seg
				range.right = seg
			end
			range.bidi_level = seg.bidi_level
		else
			-- Allocate new range for seg and push into stack.
			local r = alloc_range()
			r.left = seg
			r.right = seg
			r.bidi_level = seg.bidi_level
			r.prev = range
			range = r
		end

		seg = next_seg
	end
	assert (range)
	while range.prev do
		range = merge_range_with_prev(range)
	end

	range.right.next = false

	free_range(range)
	return range.left
end

return reorder_segs
