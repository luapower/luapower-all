
-- Unicode UAX#9 rule L2 algorithm for reordering RTL BiDi text runs.
-- Written by Cosmin Apreutesei. Public Domain.

-- Derived from code by Behdad Esfahbod, Copyright (C) 2013 Google, Inc.
-- https://github.com/fribidi/linear-reorder/blob/master/linear-reorder.c

-- A range contains the left-most and right-most segs in the range,
-- in visual order. Following left's `next` member eventually gets us to
-- `right`. The right seg's `next_vis` member is undefined!

if not ... then require'terra.tr_test'; return end

setfenv(1, require'terra.tr_types')

-- Merges range with previous range and returns the previous range.
local terra merge_range_with_prev(range: &SegRange, ranges: &RangesFreelist)
	var prev = range.prev
	assert(prev ~= nil)
	assert(prev.bidi_level < range.bidi_level)

	var left: &SegRange
	var right: &SegRange
	if prev.bidi_level % 2 == 1 then
		-- Odd, previous goes to the right of range.
		left = range
		right = prev
	else
		-- Even, previous goes to the left of range.
		left = prev
		right = range
	end
	--Stich them.
	left.right.next_vis = right.left
	prev.left = left.left
	prev.right = right.right
	ranges:release(range)
	return prev
end

-- Takes a list of segs on the line in the logical order and
-- reorders the list to be in visual order, returning the
-- left-most seg.
--
-- Caller is responsible to reverse the seg contents for any
-- seg that has an odd level.
--
local terra reorder_segs(seg: &Seg, ranges: &RangesFreelist)

	-- The algorithm here is something like this: sweep segs in the
	-- logical order, keeping a stack of ranges.  Upon seeing a seg,
	-- we flatten all ranges before it that have a level higher than
	-- the seg, by merging them, reordering as we go.  Then we either
	-- merge the seg with the previous range, or create a new range
	-- for the seg, depending on the level relationship.

	var range: &SegRange = nil
	while seg ~= nil do
		var next_seg = seg.next_vis

		while range ~= nil and range.bidi_level > seg.bidi_level
			and range.prev ~= nil and range.prev.bidi_level >= seg.bidi_level
		do
			range = merge_range_with_prev(range, ranges)
		end

		if range ~= nil and range.bidi_level >= seg.bidi_level then
			-- Attach the seg to the range.
			if seg.bidi_level % 2 == 1 then
				-- Odd, range goes to the right of seg.
				seg.next_vis = range.left
				range.left = seg
			else
				-- Even, range goes to the left of seg.
				range.right.next_vis = seg
				range.right = seg
			end
			range.bidi_level = seg.bidi_level
		else
			-- Allocate new range for seg and push into stack.
			assert(ranges.items.len < ranges.items.capacity) --no relocation!
			var r = ranges:alloc()
			assert(r ~= nil)
			r.left = seg
			r.right = seg
			r.bidi_level = seg.bidi_level
			r.prev = range
			range = r
		end

		seg = next_seg
	end
	assert(range ~= nil)
	while range.prev ~= nil do
		range = merge_range_with_prev(range, ranges)
	end

	range.right.next_vis = nil

	var left = range.left
	ranges:release(range)
	return left
end

return reorder_segs
