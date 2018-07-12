
--fribidi ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'fribidi_test'; return end

local ffi = require'ffi'
local bit = require'bit'
require'fribidi_h'
local C = ffi.load'fribidi'
local fb = {C = C}

fb.version_info = ffi.string(C.fribidi_version_info)
fb.unicode_version = ffi.string(C.fribidi_unicode_version)

local function str_func(func)
	return function(...)
		local s = func(...)
		return s ~= nil and ffi.string(s) or nil
	end
end

--bidi types

fb.bidi_type = C.fribidi_get_bidi_type
fb.bidi_types = C.fribidi_get_bidi_types
fb.bidi_type_name = str_func(C.fribidi_get_bidi_type_name)

--joining

fb.joining_type = C.fribidi_get_joining_type
fb.joining_types = C.fribidi_get_joining_types
fb.joining_type_name = str_func(C.fribidi_get_joining_type_name)

fb.join_arabic = C.fribidi_join_arabic

--mirroring

local c1 = 'FriBidiChar[1]'
function fb.mirror_char(c)
	local ret = C.fribidi_get_mirror_char(c, c1)
	return ret == 1, c1[0]
end

fb.shape_mirroring = C.fribidi_shape_mirroring

--brackets

fb.bracket = C.fribidi_get_bracket
fb.bracket_types = C.fribidi_get_bracket_types

--arabic shaper

fb.shape_arabic = C.fribidi_shape_arabic

--shaping

fb.shape = C.fribidi_shape --calls shape_mirroring and shape_arabic

--bidi algorithm

local par_type_names = {
	[C.FRIBIDI_PAR_LTR]  = 'LTR',
	[C.FRIBIDI_PAR_RTL]  = 'RTL',
	[C.FRIBIDI_PAR_ON]   = 'ON',
	[C.FRIBIDI_PAR_WLTR] = 'WLTR',
	[C.FRIBIDI_PAR_WRTL] = 'WRTL',
}
function fb.par_type_name(t)
	return par_type_names[tonumber(t)]
end

fb.par_direction = C.fribidi_get_par_direction --(bidi_types, len)

local par_base_dir_out = ffi.new'FriBidiParType[1]'
function fb.par_embedding_levels(
	bidi_types, bracket_types, len, par_base_dir, embedding_levels
)
	par_base_dir_out[0] = par_base_dir
	local max_level = C.fribidi_get_par_embedding_levels_ex(
		bidi_types, bracket_types, len, par_base_dir_out, embedding_levels
	)
	return max_level > 0 and max_level - 1, par_base_dir_out[0]
end

function fb.reorder_line(...)
	local max_level = C.fribidi_reorder_line(...)
	return max_level > 0 and max_level - 1
end

--charsets

function fb.charset(cs)
	if type(cs) == 'string' then
		cs = C.fribidi_parse_charset(cs:lower())
		if cs == 0 then return nil, 'invalid charset' end
	end
	return cs
end
local function cs_func(func)
	return str_func(function(cs)
		local cs, err = fb.charset(cs)
		if not cs then return nil, err end
		return func(cs)
	end)
end
fb.charset_name = cs_func(C.fribidi_char_set_name)
fb.charset_title = cs_func(C.fribidi_char_set_title)
fb.charset_desc = cs_func(C.fribidi_char_set_desc)

--charset conversion

function fb.charset_to_unicode(charset, s, len, us, us_len)
	local charset, err = fb.charset(charset)
	if not charset then return nil, err end
	len = len or #s
	local min_us_len = len
	if not us then
		us_len = min_us_len
		us = ffi.new('FriBidiChar[?]', us_len)
	elseif us_len < min_us_len then
		return nil, 'output buffer too small'
	end
	return us, C.fribidi_charset_to_unicode(charset, s, len, us)
end

function fb.unicode_to_charset(charset, us, len, s, s_len)
	local charset, err = fb.charset(charset)
	if not charset then return nil, err end
	len = len or #s
	local min_s_len = len * 4 + 1 -- +1 for traling \0
	if not s then
		s_len = min_s_len
		s = ffi.new('char[?]', s_len)
	elseif s_len < min_s_len then
		return nil, 'output buffer too small'
	end
	return s, C.fribidi_unicode_to_charset(charset, us, len, s)
end

--hi-level API

function fb.buffers(len, b, charset)

	charset = charset or 'ucs4'

	if b and b.len >= len then
		if charset ~= 'ucs4' then
			if b.str then
				ffi.fill(b.str, len)
				ffi.fill(b.s, len + 1)
			else
				b.s_len = b.len * 4 + 1
				b.s = ffi.new('char[?]', b.s_len)
				b.str = ffi.new('FriBidiCharType[?]', b.len)
			end
		end
		ffi.fill(b.bidi_types, len)
		ffi.fill(b.bracket_types, len)
		ffi.fill(b.visual_str, len)
		ffi.fill(b.levels, len)
		ffi.fill(b.ar_props, len)
		return b
	end

	b = {}
	b.len = len
	b.bidi_types    = ffi.new('FriBidiCharType[?]', len)
	b.bracket_types = ffi.new('FriBidiBracketType[?]', len)
	b.visual_str    = ffi.new('FriBidiChar[?]', len)
	b.levels        = ffi.new('FriBidiLevel[?]', len)
	b.ar_props      = ffi.new('FriBidiArabicProp[?]', len)
	b.v_to_l        = ffi.new('FriBidiStrIndex[?]', len)
	b.l_to_v        = ffi.new('FriBidiStrIndex[?]', len)

	if charset ~= 'ucs4' then
		b.s_len = len * 4 + 1
		b.s   = ffi.new('char[?]', b.s_len)
		b.str = ffi.new('FriBidiCharType[?]', len)
	end

	return b
end

--http://lists.freedesktop.org/archives/fribidi/2005-September/000439.html
--also see fribidi_log2vis() in fribidi-deprecated.c
function fb.bidi(str, len, charset, buffers, flags)

	local was_string = type(str) == 'string'
	local len = len or #str
	local charset = charset or C.FRIBIDI_CHAR_SET_UTF8

	local b = fb.buffers(len, buffers, charset)

	if charset ~= 'ucs4' then --str needs conversion
		str, len = fb.charset_to_unicode(charset, str, len, b.str, b.len)
		if not str then return str, len end
	end

	local flags = flags or bit.bor(
		C.FRIBIDI_FLAGS_DEFAULT,
		C.FRIBIDI_FLAGS_ARABIC)

	fb.bidi_types(str, len, b.bidi_types)
	fb.bracket_types(str, len, b.bidi_types, b.bracket_types)
	local par_base_dir = C.FRIBIDI_PAR_ON --fb.par_direction(b.bidi_types, len)
	local max_level, resolved_par_base_dir = fb.par_embedding_levels(
		b.bidi_types, b.bracket_types, len, par_base_dir, b.levels)

	if not max_level then
		return nil, 'fribidi_par_embedding_levels() error'
	end

	--arabic joining
   fb.joining_types(str, len, b.ar_props)
	fb.join_arabic(b.bidi_types, len, b.levels, b.ar_props)

	--mirror shaping and arabic shaping
	ffi.copy(b.visual_str, str, len * ffi.sizeof('FriBidiChar'))
	fb.shape(flags, b.levels, len, b.ar_props, b.visual_str)

	--TODO: line breaking.
	--The bidi algorithm assumes that that line breaking is done *before* reordering.
	--You need to carry over the paragraph bidirectional direction from line to line,
	--but that is done after the lines have been broken into paragraphs.

	--set up the ordering array to identity order
	for i=0,len-1 do
		b.v_to_l[i] = i
	end

	--TODO: line breaking
	--[[
	local x = 0
	for i, offset in ipairs(line_offsets) do
		local bidi_types
		local max_level = fb.reorder_line(flags, bidi_types, len, offset,
			resolved_par_base_dir, levels, visual_str, v_to_l)
	end
	]]
	local max_level = fb.reorder_line(flags, b.bidi_types, len, 0,
		resolved_par_base_dir, b.levels, b.visual_str, b.v_to_l)

	if not max_level then
		return nil, 'fribidi_reorder_line() error'
	end

	--convert the v2l list to l2v
	for i=0,len-1 do
		b.l_to_v[i] = -1
	end
	for i=0,len-1 do
		b.l_to_v[b.v_to_l[i]] = i
	end

	--add additional info into the output object
	b.max_level = max_level
	b.par_base_dir = resolved_par_base_dir

	--convert the output back to the same charset as the input
	local s, s_len = b.visual_str, len
	if charset ~= 'ucs4' then
		s, s_len = fb.unicode_to_charset(charset, s, s_len, b.s, b.s_len)
		if not s then return nil, s_len end
	end

	--convert output back to string if the input was a string
	if was_string then
		s = ffi.string(s, s_len)
	end

	return s, s_len, b
end

return fb
