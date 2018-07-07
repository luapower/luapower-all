
--autolayout algorithm for hierarchies of horizontal bands.
--Written by Cosmin Apreutesei. Public Domain.

--does not support supplying a maximum width, that would probably require the simplex algorithm.
--input:  band table with fields w, pw, min_w and and a list of child bands in the array part of the table.
--output: computed fields _w, _pw, _min_w, _max_w for each band.
--policy:
-- if min_w is given, the band has a minimum width. min_w applies over all other rules and defaults to 0.
-- if w is given, the band has a fixed width and its pw becomes 0 (if pw is also given it is ignored).
-- if pw is given, it is first is clamped in 0..1, then the band's width is pw * (width of parent band).
-- if total pw is greater than 1, all pws are scaled down so the total becomes 1.
-- in total pw is smaller than 1 and all bands have the pw field, all pws are scaled up so the total becomes 1.
-- for bands without pw, the default pw = (1 - total pw) / (number of bands without pw) is assigned.
-- if all band's children are fixed width, the band has fixed width = sum(widths of children).
-- the band's min. width is constrained by the children's min. width.
-- in case pw cannot be achieved because of w or min_w, the band becomes "rigid". all other "non-rigid" bands
-- are stretched proportionally up (or down) to parent's width.

local function band_min_w(band) --min. width of a band
	return math.max(band.w or 0, band.min_w or 0, 0)
end

local function band_max_w(band) --max. width of a band
	return math.max(math.min(band.w or 1/0), 0)
end

local function band_pw(band) --clamped pw of a band
	return math.min(math.max(band.pw, 0), 1)
end

local function set_minmax(band) --set min. and max. width for all bands (bottom-up)
	--start with own min. and max. widths
	band._min_w = band_min_w(band)
	band._max_w = band_max_w(band)
	--error: negative interval, adjust the max width
	if band._min_w > band._max_w then
		band._max_w = band._min_w
	end
	if #band > 0 then
		--get cummulated min and max. widths of children
		local cmin_w, cmax_w = 0, 0
		for i,cband in ipairs(band) do
			set_minmax(cband)
			cmin_w = cmin_w + cband._min_w
			cmax_w = cmax_w + cband._max_w
		end
		--clamp own constraints within those of children
		band._min_w = math.min(math.max(band._min_w, cmin_w), cmax_w)
		band._max_w = math.min(math.max(band._max_w, cmin_w), cmax_w)
	end
end

local function set_children_pw(band) --set percent-width for children bands

	--clamp pws, set them and sum them up
	local total_pw = 0
	local missing_pw_count = 0
	for i,cband in ipairs(band) do
		if cband._max_w < 1/0 then
			--fixed width: set _pw to 0, which ensures that applying _max_w over it can only increase the width,
			--never decrease it. this is important because we can only redistribute excess width, not deficit.
			cband._pw = 0
		elseif cband.pw then
			cband._pw = band_pw(cband)
			total_pw = total_pw + cband._pw
		else
			missing_pw_count = missing_pw_count + 1
		end
	end

	--scale pws so that the total is 1
	if total_pw > 1 or (total_pw > 0 and total_pw < 1 and missing_pw_count == 0) then
		for i,cband in ipairs(band) do
			if cband._pw then
				cband._pw = cband._pw / total_pw
			end
		end
		total_pw = 1
	end

	--if there are missing pws, distribute any space left equally among them
	if missing_pw_count > 0 then
		local missing_pw = (1 - total_pw) / missing_pw_count
		for i,cband in ipairs(band) do
			if not cband._pw then
				cband._pw = missing_pw
			end
		end
	end

	--recurse
	for i,cband in ipairs(band) do
		set_children_pw(cband)
	end
end

local function set_pw(band) --set percent-width for all bands
	band._pw = band.pw or 1
	set_children_pw(band)
end

local function wanted_w(band, parent_w)
	return parent_w * band._pw
end

local function constrained_w(band, wanted_w)
	return math.min(math.max(wanted_w, band._min_w), band._max_w)
end

local w_epsilon = 0.1

local function set_children_w(band) --set width for all children bands (top-down)

	if #band == 0 then return end --no children

	--set widths constrained and see what happens
	local total_w = 0
	for i,cband in ipairs(band) do
		local wanted_w = wanted_w(cband, band._w)
		local possible_w = constrained_w(cband, wanted_w)
		cband._w = possible_w
		total_w = total_w + possible_w
	end

	--while calc. width exceeds band's width, stretch the remaining unconstrained
	--columns proportionally to make up for the difference.
	while total_w - band._w > w_epsilon do

		--find out the total percentage of unconstrained columns
		local pw = 0
		for i,cband in ipairs(band) do
			if cband._w > cband._min_w then
				pw = pw + cband._pw
			end
		end

		--there must be a child that has room if the constraints are consistent between parents and children
		assert(pw > 0)

		--substract the excess width proportionally to each child's percent-width.
		local excess_w = total_w - band._w
		total_w = 0
		for i,cband in ipairs(band) do
			if cband._w > cband._min_w then
				local diff_w = excess_w * (cband._pw / pw)
				cband._w = math.max(cband._min_w, cband._w - diff_w)
			end
			total_w = total_w + cband._w
		end

	end

	--recurse
	for i,cband in ipairs(band) do
		set_children_w(cband)
	end
end

local function set_w(band, parent_w) --set width for all bands
	band._w = constrained_w(band, wanted_w(band, parent_w))
	set_children_w(band)
end

local function set_layout(band, parent_w)
	set_minmax(band)
	set_pw(band)
	set_w(band, parent_w or 0)
end

if not ... then require'grid_band_layout_demo' end

return set_layout

