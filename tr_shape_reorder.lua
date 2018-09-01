
-- Unicode UAX#9 rule L2 algorithm for reordering RTL BiDi text runs.
-- Written by Cosmin Apreutesei. Public Domain.

-- Derived from code by Behdad Esfahbod, Copyright (C) 2013 Google, Inc.
-- https://github.com/fribidi/linear-reorder/blob/master/linear-reorder.c

-- Data structures used: `run` and `range`.
-- A run is a segment with fields: {bidi_level = level, next = next_run}.
-- A range is an internal structure used by the algorithm with the fields:
--   {left = left_run, right = right_run, prev = prev_range}.
-- A range contains the left-most and right-most runs in the range,
-- in visual order. Following left's `next` member eventually gets us to
-- `right`. The right run's `next` member is undefined.

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

-- Takes a list of runs on the line in the logical order and
-- reorders the list to be in visual order, returning the
-- left-most run.
--
-- Caller is responsible to reverse the run contents for any
-- run that has an odd level.
--
function reorder_runs(run)

	-- The algorithm here is something like this: sweep runs in the
	-- logical order, keeping a stack of ranges.  Upon seeing a run,
	-- we flatten all ranges before it that have a level higher than
	-- the run, by merging them, reordering as we go.  Then we either
	-- merge the run with the previous range, or create a new range
	-- for the run, depending on the level relationship.

	local range
	while run do
		local next_run = run.next

		while range and range.bidi_level > run.bidi_level
			and range.prev and range.prev.bidi_level >= run.bidi_level
		do
			range = merge_range_with_prev(range)
		end

		if range and range.bidi_level >= run.bidi_level then
			-- Attach run to the range.
			if odd(run.bidi_level) then
				-- Odd, range goes to the right of run.
				run.next = range.left
				range.left = run
			else
				-- Even, range goes to the left of run.
				range.right.next = run
				range.right = run
			end
			range.bidi_level = run.bidi_level
		else
			-- Allocate new range for run and push into stack.
			local r = alloc_range()
			r.left = run
			r.right = run
			r.bidi_level = run.bidi_level
			r.prev = range
			range = r
		end
		run = next_run
	end
	assert (range)
	while range.prev do
		range = merge_range_with_prev(range)
	end

	range.right.next = false

	free_range(range)
	return range.left
end

return reorder_runs
