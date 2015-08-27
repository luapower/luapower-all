--freebidi binding
local ffi = require'ffi'
local bit = require'bit'
require'fribidi_h'
local C = ffi.load'fribidi'
local M = setmetatable({C = C}, {__index = C})

M.fribidi_unicode_version = ffi.string(C.fribidi_unicode_version)
M.fribidi_version_info = ffi.string(C.fribidi_version_info)

local function str_func(func)
	return function(...)
		local s = func(...)
		return s ~= nil and ffi.string(s) or nil
	end
end

--see http://www.unicode.org/reports/tr9/#Bidirectional_Character_Types
M.fribidi_get_bidi_type_name = str_func(C.fribidi_get_bidi_type_name)

local par_type_names = {
	[C.FRIBIDI_PAR_LTR]  = 'LTR',
	[C.FRIBIDI_PAR_RTL]  = 'RTL',
	[C.FRIBIDI_PAR_ON]   = 'ON',
	[C.FRIBIDI_PAR_WLTR] = 'WLTR',
	[C.FRIBIDI_PAR_WRTL] = 'WRTL',
}
function M.fribidi_get_bidi_par_type_name(t)
	return par_type_names[tonumber(t)]
end

M.fribidi_get_joining_type_name = str_func(C.fribidi_get_joining_type_name)
M.fribidi_char_set_name = str_func(C.fribidi_char_set_name)
M.fribidi_char_set_title = str_func(C.fribidi_char_set_title)
M.fribidi_char_set_desc_cap_rtl = str_func(C.fribidi_char_set_desc_cap_rtl)

function M.fribidi_charset_to_unicode(char_set, s, len, us)
	if type(char_set) == 'string' then
		char_set = C.fribidi_parse_charset(char_set)
	end
	us = us or ffi.new('FriBidiChar[?]', len + 1)
	return us, C.fribidi_charset_to_unicode(char_set, s, len, us)
end

function M.fribidi_unicode_to_charset(char_set, us, len, s)
	if type(char_set) == 'string' then
		char_set = C.fribidi_parse_charset(char_set)
	end
	s = s or ffi.new('char[?]', len * ffi.sizeof('FriBidiChar') + 1)
	return s, C.fribidi_unicode_to_charset(char_set, us, len, s)
end

--http://lists.freedesktop.org/archives/fribidi/2005-September/000439.html
--also see fribidi_log2vis() in fribidi-deprecated.c
function M.log2vis_ucs4(str, len, debug_func)

	local visual_str = ffi.new('FriBidiChar[?]', len)
	local bidi_types = ffi.new('FriBidiCharType[?]', len)
	local levels     = ffi.new('FriBidiLevel[?]', len)
	local ar_props   = ffi.new('FriBidiArabicProp[?]', len)
	local v_to_l     = ffi.new('FriBidiStrIndex[?]', len)
	local l_to_v     = ffi.new('FriBidiStrIndex[?]', len)
	local pbase_dir_out

	M.fribidi_get_bidi_types(str, len, bidi_types)
	local pbase_dir_in = C.fribidi_get_par_direction(bidi_types, len)
	local pbase_dir_out = ffi.new('FriBidiParType[1]', pbase_dir_in)
	assert(M.fribidi_get_par_embedding_levels(bidi_types, len, pbase_dir_out, levels) > 0)
	local pbase_dir_out = pbase_dir_out[0]

	--arabic joining
   local flags = bit.bor(C.FRIBIDI_FLAGS_DEFAULT, C.FRIBIDI_FLAGS_ARABIC)
   C.fribidi_get_joining_types(str, len, ar_props)
	C.fribidi_join_arabic(bidi_types, len, levels, ar_props)

	ffi.copy(visual_str, str, len * ffi.sizeof('FriBidiChar'))
	C.fribidi_shape(flags, levels, len, ar_props, visual_str)

	--TODO: line breaking.
	--The bidi algorithm assumes that that line breaking is done *before* reordering.
	--You need to carry over the paragraph bidirectional direction from line to line,
	--but that is done after the lines have been broken into paragraphs.

	for i=0,len-1 do
		v_to_l[i] = i
	end

	--[[
	local x = 0
	for i,offset in ipairs(line_offsets) do
		local bidi_types
		local status = C.fribidi_reorder_line(flags, bidi_types, len, 0, pbase_dir_out, levels, visual_str, v_to_l)
	end
	]]

	for i=0,len-1 do
		l_to_v[i] = -1
	end
	for i=0,len-1 do
		l_to_v[v_to_l[i]] = i
	end

	if debug_func then
		debug_func(str, visual_str, len, v_to_l, l_to_v, pbase_dir_out, bidi_types, levels, ar_props)
	end

	return visual_str, len
end

function M.log2vis_ucs42(str, len)
	local visual_str = ffi.new('FriBidiChar[?]', len)
	local pbase_dir = ffi.new('FriBidiParType[1]')
	assert(C.fribidi_log2vis(str, len, pbase_dir, visual_str, nil, nil, nil) > 0)
	return visual_str, len
end

function M.log2vis(s, charset, ...)
	charset = charset or 'utf-8'
	local str, str_len = M.fribidi_charset_to_unicode(charset, s, #s)
	local visual_str, visual_str_len = M.log2vis_ucs4(str, str_len, ...)
	local out_s, out_len = M.fribidi_unicode_to_charset(charset, visual_str, visual_str_len)
	return ffi.string(out_s, out_len)
end

if not ... then require'fribidi_test' end

return M
