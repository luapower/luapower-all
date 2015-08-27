--tab expansion module for codedit (Cosmin Apreutesei, public domain).
--translates between visual columns and real columns based on a fixed tabsize.
--real columns map 1:1 to char indices, while visual columns represent screen columns after tab expansion.
local str = require'codedit_str'

--the first tabstop after a visual column
local function next_tabstop(vcol, tabsize)
	return (math.floor((vcol - 1) / tabsize) + 1) * tabsize + 1
end

--the first tabstop before a visual column
local function prev_tabstop(vcol, tabsize)
	return next_tabstop(vcol - 1, tabsize) - tabsize
end

--how wide should a tab character be if found at a certain visual position
local function tab_width(vcol, tabsize)
	return next_tabstop(vcol, tabsize) - vcol
end

--how many tabs and left-over spaces fit between two visual columns (vcol2 is the char right after the last tab/space)
local function tabs_and_spaces(vcol1, vcol2, tabsize)
	if vcol2 < vcol1 then
		return 0, 0
	end
	--the distance is covered by a first (full or partial) tab, a number of full tabs, and finally a number of spaces
	local distance_left = vcol2 - next_tabstop(vcol1, tabsize) --distance left after the first tab
	if distance_left >= 0 then
		local full_tabs = math.floor(distance_left / tabsize)
		local spaces = distance_left - full_tabs * tabsize
		return 1 + full_tabs, spaces
	else
		return 0, vcol2 - vcol1
	end
end

--real column -> visual column, for a fixed tabsize.
--the real column can be past string's end, in which case vcol will expand to the same amount.
local function visual_col(s, col, tabsize)
	local col1 = 0
	local vcol = 1
	for i in str.byte_indices(s) do
		col1 = col1 + 1
		if col1 >= col then
			return vcol
		end
		vcol = vcol + (str.istab(s, i) and tab_width(vcol, tabsize) or 1)
	end
	vcol = vcol + col - col1 - 1 --extend vcol past eol
	return vcol
end

--visual column -> real column, for a fixed tabsize.
--if the target vcol is between two possible vcols, return the vcol that is closer.
local function real_col(s, vcol, tabsize)
	local vcol1 = 1
	local col = 0
	for i in str.byte_indices(s) do
		col = col + 1
		local vcol2 = vcol1 + (str.istab(s, i) and tab_width(vcol1, tabsize) or 1)
		if vcol >= vcol1 and vcol <= vcol2 then --vcol is between the current and the next vcol
			return col + (vcol - vcol1 > vcol2 - vcol and 1 or 0)
		end
		vcol1 = vcol2
	end
	col = col + vcol - vcol1 + 1 --extend col past eol
	return col
end


if not ... then
	assert(tab_width(1, 3) == 3) --___X
	assert(tab_width(2, 3) == 2) --x__X
	assert(tab_width(3, 3) == 1) --xx_X
	assert(tab_width(4, 3) == 3) --xxx___X
	assert(tab_width(5, 3) == 2) --xxxx__X
	assert(tab_width(6, 3) == 1) --xxxxx_X

	assert(next_tabstop(1, 3) == 4) --x__X
	assert(next_tabstop(2, 3) == 4) --xx_X
	assert(next_tabstop(3, 3) == 4) --xxxX
	assert(next_tabstop(4, 3) == 7) --xxxx__X
	assert(next_tabstop(5, 3) == 7) --xxxxx_X
	assert(next_tabstop(6, 3) == 7) --xxxxxxX

	local function assert_pair(a1, b1, a2, b2)
		assert(a1 == a2 and b1 == b2)
	end

	assert_pair(0, 0, tabs_and_spaces(1, 1, 3))
	assert_pair(0, 1, tabs_and_spaces(1, 2, 3))
	assert_pair(0, 2, tabs_and_spaces(1, 3, 3))
	assert_pair(1, 0, tabs_and_spaces(1, 4, 3))
	assert_pair(1, 1, tabs_and_spaces(1, 5, 3))

	assert_pair(0, 0, tabs_and_spaces(2, 2, 3))
	assert_pair(0, 1, tabs_and_spaces(2, 3, 3))
	assert_pair(1, 0, tabs_and_spaces(2, 4, 3))
	assert_pair(1, 1, tabs_and_spaces(2, 5, 3))
	assert_pair(1, 2, tabs_and_spaces(2, 6, 3))
	assert_pair(2, 0, tabs_and_spaces(2, 7, 3))

	--TODO: tabs_and_spaces, real_col, visual_col
end

return {
	tab_width = tab_width,
	next_tabstop = next_tabstop,
	prev_tabstop = prev_tabstop,
	tabs_and_spaces = tabs_and_spaces,
	visual_col = visual_col,
	real_col = real_col,
}

