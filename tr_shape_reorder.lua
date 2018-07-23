
-- Unicode UAX#9 rule L2 algorithm for reordering RTL BiDi text runs.
-- Written by Cosmin Apreutesei. Public Domain.

-- Derived from code by Behdad Esfahbod, Copyright (C) 2013 Google, Inc.
-- https://github.com/fribidi/linear-reorder/blob/master/linear-reorder.c

--[[
// Data structures used:

struct run_t {
  int level;
  // len, glyphs, text, ...
  struct run_t *next;
};

struct range_t {
	int level;
	// Left-most and right-most runs in the range, in visual order.
	// Following left's next member eventually gets us to right.
	// The right run's next member is undefined.
	struct run_t *left;
	struct run_t *right;
	struct range_t *previous;
};
]]

-- Merges range with previous range and returns the previous range.
local function merge_range_with_previous(range)
	local previous = range.previous
	assert(previous)
	assert(previous.level < range.level)

	local left, right
	if previous.level % 2 == 1 then
		-- Odd, previous goes to the right of range.
		left = range
		right = previous
	else
		-- Even, previous goes to the left of range.
		left = previous
		right = range
	end
	--Stich them.
	left.right.next = right.left
	previous.left = left.left
	previous.right = right.right

	return previous
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

		while range and range.level > run.level
			and range.previous and range.previous.level >= run.level
		do
			range = merge_range_with_previous (range)
		end

		if range and range.level >= run.level then
			-- Attach run to the range.
			if run.level % 2 == 1 then
				-- Odd, range goes to the right of run.
				run.next = range.left
				range.left = run
			else
				-- Even, range goes to the left of run.
				range.right.next = run
				range.right = run
			end
			range.level = run.level
		else
			-- Allocate new range for run and push into stack.
			local r = {}
			r.left = run
			r.right = run
			r.level = run.level
			r.previous = range
			range = r
		end
		run = next_run
	end
	assert (range)
	while range.previous do
		range = merge_range_with_previous (range)
	end

	range.right.next = nil

	return range.left
end

return reorder_runs
