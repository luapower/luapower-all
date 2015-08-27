local fb = require'fribidi'
local ffi = require'ffi'

print(fb.fribidi_version_info)
print(fb.fribidi_unicode_version)

for i,charset in ipairs{
	fb.FRIBIDI_CHAR_SET_NA,
	fb.FRIBIDI_CHAR_SET_UTF8,
	fb.FRIBIDI_CHAR_SET_CAP_RTL,
	fb.FRIBIDI_CHAR_SET_ISO8859_6,
	fb.FRIBIDI_CHAR_SET_ISO8859_8,
	fb.FRIBIDI_CHAR_SET_CP1255,
	fb.FRIBIDI_CHAR_SET_CP1256,
} do
	print(fb.fribidi_char_set_name(charset), fb.fribidi_char_set_title(charset))
end

print(fb.fribidi_char_set_desc_cap_rtl())

local function debug_func(str, visual_str, len, v_to_l, l_to_v, pbase_dir_out, bidi_types, levels, ar_props)
	print('dir', fb.fribidi_get_bidi_par_type_name(pbase_dir_out))
	for i=0,len-1 do
		local bidi_type_name = fb.fribidi_get_bidi_type_name(bidi_types[i])
		local joining_type_name = fb.fribidi_get_joining_type_name(ar_props[i])
		print(
			str[i],
			bidi_type_name,
			levels[i],
			joining_type_name,
			visual_str[i],
			v_to_l[i],
			l_to_v[i])
	end
end

print(fb.log2vis('english test', 'utf-8', debug_func))
print(fb.log2vis('a _lsimple _RteST_o th_oat', 'caprtl', debug_func))
print(fb.log2vis('HE SAID "it is a car!" AND RAN', 'caprtl', debug_func))
