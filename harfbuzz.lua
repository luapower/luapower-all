
--harfbuzz ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'harfbuzz_demo'; return end

local ffi = require'ffi'
local bit = require'bit'
require'harfbuzz_h'
local C = ffi.load'harfbuzz'
local hb = {C = C}

local band = bit.band

--wrappers

local x = ffi.new'int32_t[1]'
local y = ffi.new'int32_t[1]'
local function get_xy_func(func)
	return function(self)
		func(self, x, y)
		return x[0], y[0]
	end
end

local x = ffi.new'hb_position_t[1]'
local y = ffi.new'hb_position_t[1]'
local function get_pos_func(func)
	return function(self, glyph)
		func(self, glyph, x, y)
		return x[0], y[0]
	end
end

local function get_pos2_func(func)
	return function(self, glyph, index)
		func(self, glyph, index, x, y)
		return x[0], y[0]
	end
end

local function string_func(func)
	return function(...)
		local s = func(...)
		return s ~= nil and ffi.string(s) or nil
	end
end

function from_string_func(func, badret)
	return function(s)
		if type(s) == 'string' then
			local c = func(s, #s)
			return c ~= badret and c or nil
		else
			return s
		end
	end
end

function obj_from_string_func(func, obj_type)
	obj_type = ffi.typeof(obj_type)
	return function(s, obj)
		obj = obj or obj_type()
		if type(s) == 'string' then
			local ret = func(s, #s, obj)
			if ret == 0 then return nil end
			return obj
		else
			return s
		end
	end
end

local strbuf = ffi.new'char[128]'

function obj_tostring_func(func)
	return function(obj)
		func(obj, strbuf, 128)
		return ffi.string(strbuf)
	end
end

local function create_func(func, destroy_func)
	return function(...)
		local ptr = func(...)
		assert(ptr ~= nil)
		return ffi.gc(ptr, function(ptr)
			ffi.gc(ptr, nil)
			destroy_func(ptr)
		end)
	end
end

local function destroy_func(destroy_func)
	return function(ptr)
		ffi.gc(ptr, nil)
		destroy_func(ptr)
	end
end

--globals

function hb.version()
	local v = ffi.new'uint32_t[3]'
	C.hb_version(v, v+1, v+2)
	return v[0], v[1], v[2]
end

hb.version_string = string_func(C.hb_version_string)

function hb.list_shapers()
	local t = {}
	local s = C.hb_shape_list_shapers()
	while s[0] ~= nil do
		t[#t+1] = ffi.string(s[0])
		s = s + 1
	end
	return t
end

--tags, languages, directions, scripts (static objects)

hb.tag = from_string_func(C.hb_tag_from_string, 0)

hb.tag_tostring = string_func(function(tag)
	C.hb_tag_to_string(tag, strbuf)
	return strbuf
end)
hb.direction = from_string_func(C.hb_direction_from_string, 0)
hb.direction_tostring = string_func(C.hb_direction_to_string)

hb.language = from_string_func(C.hb_language_from_string, nil)
hb.language_tostring = string_func(C.hb_language_to_string)
hb.default_language = C.hb_language_get_default

function hb.script(s)
	if type(s) == 'string' then
		local script = C.hb_script_from_string(s, #s)
		if script == 0 then return nil end
	elseif ffi.istype('hb_tag_t', s) then
		local script = C.hb_script_from_iso15924_tag(s)
		if script == 0 then return nil end
	end
	return s
end
hb.script_to_tag = C.hb_script_to_iso15924_tag --output == input
hb.script_horizontal_direction = C.hb_script_get_horizontal_direction

--features, variations (user-allocated objects without a destructor)

hb.feature   = obj_from_string_func(C.hb_feature_from_string,   'hb_feature_t')
hb.variation = obj_from_string_func(C.hb_variation_from_string, 'hb_variation_t')

--blobs, buffers (user-allocated objects with a destructor)

hb.blob = create_func(C.hb_blob_create, C.hb_blob_destroy)
hb.buffer = create_func(C.hb_buffer_create, C.hb_buffer_destroy)

--hb-unicode.h

local default_unicode_funcs = C.hb_unicode_funcs_get_default()

function hb.unicode_combining_class(c)
	return C.hb_unicode_combining_class(default_unicode_funcs, c)
end

function hb.unicode_eastasian_width(c)
	return C.hb_unicode_eastasian_width(default_unicode_funcs, c)
end

function hb.unicode_general_category(c)
	return C.hb_unicode_general_category(default_unicode_funcs, c)
end

function hb.unicode_mirroring(c)
	return C.hb_unicode_mirroring(default_unicode_funcs, c)
end

function hb.unicode_script(c)
	return C.hb_unicode_script(default_unicode_funcs, c)
end

local c1 = ffi.new'hb_codepoint_t[1]'
local c2 = ffi.new'hb_codepoint_t[1]'

function hb.unicode_compose(a, b)
	local ok = C.hb_unicode_compose(default_unicode_funcs, a, b, c1) == 1
	return ok and c1[0] or nil
end

function hb.unicode_decompose(c)
	local ok = C.hb_unicode_decompose(default_unicode_funcs, c, c1, c2) == 1
	if not ok then return nil end
	return c1[0], c2[0]
end

local c0 = ffi.new'uint32_t[18]'

function hb.unicode_decompose_compatibility(c, out)
	local out = out or c0
	local len = C.hb_unicode_decompose_compatibility(
		default_unicode_funcs, c, out)
	if len == 0 then return nil end
	return out, len
end

--from hb-ft.h

hb.ft_face        = create_func(C.hb_ft_face_create, C.hb_face_destroy)
hb.ft_face_cached = create_func(C.hb_ft_face_create_cached, C.hb_face_destroy)
hb.ft_font        = create_func(C.hb_ft_font_create, C.hb_font_destroy)

--methods

ffi.metatype('hb_feature_t', {__index = {
	tostring = obj_tostring_func(C.hb_feature_to_string),
}})

ffi.metatype('hb_variation_t', {__index = {
	tostring = obj_tostring_func(C.hb_variation_to_string),
}})

ffi.metatype('hb_blob_t', {__index = {
	ref = create_func(C.hb_blob_reference, C.hb_blob_destroy),
	free = destroy_func(C.hb_blob_destroy),
	set_user_data = C.hb_blob_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_blob_get_user_data, --key -> data
	make_immutable = C.hb_blob_make_immutable,
	is_immutable = C.hb_blob_is_immutable,

	get_length = C.hb_blob_get_length,
	get_data = C.hb_blob_get_data, --length -> data
	get_data_writable = C.hb_blob_get_data_writable, --length -> data,

	sub_blob = create_func(C.hb_blob_create_sub_blob, C.hb_blob_destroy), -- offset, length -> hb_blob_t
	face = create_func(C.hb_face_create, C.hb_face_destroy),
}})

ffi.metatype('hb_face_t', {__index = {
	ref = create_func(C.hb_face_reference, C.hb_face_destroy),
	free = destroy_func(C.hb_face_destroy),
	set_user_data = C.hb_face_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_face_get_user_data, --key -> data
	make_immutable = C.hb_face_make_immutable,
	is_immutable = C.hb_face_is_immutable,

	reference_table = create_func(C.hb_face_reference_table, C.hb_blob_destroy), --tag -> hb_blob_t
	refernce_blob = create_func(C.hb_face_reference_blob, C.hb_blob_destroy),
	set_index = C.hb_face_set_index,
	get_index = C.hb_face_get_index,
	set_upem  = C.hb_face_set_upem,
	get_upem  = C.hb_face_get_upem,
	set_glyph_count = C.hb_face_set_glyph_count,
	get_glyph_count = C.hb_face_get_glyph_count,

	font              = create_func(C.hb_font_create, C.hb_font_destroy),
	shape_plan        = create_func(C.hb_shape_plan_create, C.hb_shape_plan_destroy),
	shape_plan_cached = create_func(C.hb_shape_plan_create_cached, C.hb_shape_plan_destroy),

	--from hb-ot.h
	get_script_tags     = C.hb_ot_layout_table_get_script_tags,
	find_script         = C.hb_ot_layout_table_find_script,
	choose_script       = C.hb_ot_layout_table_choose_script,
	get_feature_tags    = C.hb_ot_layout_table_get_feature_tags,
	get_language_tags   = C.hb_ot_layout_script_get_language_tags,
	find_language       = C.hb_ot_layout_script_find_language,
	get_required_feature_index = C.hb_ot_layout_language_get_required_feature_index,
	get_feature_indexes = C.hb_ot_layout_language_get_feature_indexes,
	get_feature_tags    = C.hb_ot_layout_language_get_feature_tags,
	find_feature        = C.hb_ot_layout_language_find_feature,
	get_feature_lookups = C.hb_ot_layout_feature_get_lookups,
	collect_lookups     = C.hb_ot_layout_collect_lookups,
	collect_glyphs      = C.hb_ot_layout_lookup_collect_glyphs,
	has_substitution    = C.hb_ot_layout_has_substitution,
	would_substitute    = C.hb_ot_layout_lookup_would_substitute,
	substitute_closure  = C.hb_ot_layout_lookup_substitute_closure,
	has_positioning     = C.hb_ot_layout_has_positioning,
	get_size_params     = C.hb_ot_layout_get_size_params,
}})

--static, auto-growing buffer allocation pattern (from glue).
local function growbuffer(ctype)
	local ctype = ffi.typeof(ctype or 'char[?]')
	local buf
	local len = -1
	return function(newlen)
		if newlen > len then
			len = newlen
			buf = ctype(len)
		end
		return buf, newlen
	end
end

local carets_buffer = growbuffer'hb_position_t[?]'
local count_buf = ffi.new'unsigned int[1]'
local function get_ligature_carets(hb_font, direction, glyph_index, start_offset)
	start_offset = start_offset or 0
	local count = C.hb_ot_layout_get_ligature_carets(hb_font, direction,
		glyph_index, start_offset, nil, nil)
	local carets_buf = carets_buffer(count)
	count_buf[0] = count
	C.hb_ot_layout_get_ligature_carets(hb_font, direction, glyph_index,
		start_offset, count_buf, carets_buf)
	return carets_buf, count
end

ffi.metatype('hb_font_t', {__index = {
	ref = create_func(C.hb_font_reference, C.hb_font_destroy),
	free = destroy_func(C.hb_font_destroy),
	set_user_data = C.hb_font_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_font_get_user_data, --key -> data
	make_immutable = C.hb_font_make_immutable,
	is_immutable = C.hb_font_is_immutable,

	sub_font = create_func(C.hb_font_create_sub_font, C.hb_font_destroy),

	get_parent = C.hb_font_get_parent,
	get_face = C.hb_font_get_face,

	set_scale = C.hb_font_set_scale, --(x_scale, y_scale)
	get_scale = get_xy_func(C.hb_font_get_scale), -- () -> x_scale, y_scale
	set_ppem = C.hb_font_set_ppem, --(x_ppem, y_ppem)
	get_ppem = get_xy_func(C.hb_font_get_ppem), --() -> x_ppem, y_ppem

	get_glyph = C.hb_font_get_glyph, --(hb_codepoint_t unicode, hb_codepoint_t variation_selector, hb_codepoint_t *glyph) -> hb_glyph_t
	get_glyph_h_advance = C.hb_font_get_glyph_h_advance, --(glyph) -> hb_position_t
	get_glyph_v_advance = C.hb_font_get_glyph_v_advance, --(glyph) -> hb_position_t
	get_glyph_h_origin = get_pos_func(C.hb_font_get_glyph_h_origin), --(glyph) -> x, y
	get_glyph_v_origin = get_pos_func(C.hb_font_get_glyph_v_origin), --(glyph) -> x, y
	get_glyph_h_kerning = C.hb_font_get_glyph_h_kerning, --(left_glyph, right_glyph) -> hb_position_t
	get_glyph_v_kerning = C.hb_font_get_glyph_v_kerning, --(top_glyph, bottom_glyph) -> hb_position_t
	get_glyph_extents = C.hb_font_get_glyph_extents, --(glyph, hb_glyph_extents_t *extents)
	get_glyph_contour_point = get_pos2_func(C.hb_font_get_glyph_contour_point), --(glyph, point_index) -> x, y
	get_glyph_name = C.hb_font_get_glyph_name, --(glyph, name, size)
	get_glyph_from_name = C.hb_font_get_glyph_from_name, --(name, len, *glyph)
	get_glyph_advance_for_direction = C.hb_font_get_glyph_advance_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	get_glyph_origin_for_direction = C.hb_font_get_glyph_origin_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	add_glyph_origin_for_direction = C.hb_font_add_glyph_origin_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	subtract_glyph_origin_for_direction = C.hb_font_subtract_glyph_origin_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	get_glyph_kerning_for_direction = C.hb_font_get_glyph_kerning_for_direction, --b_codepoint_t first_glyph, hb_codepoint_t second_glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	get_glyph_extents_for_origin = C.hb_font_get_glyph_extents_for_origin, --hb_codepoint_t glyph, hb_direction_t direction, hb_glyph_extents_t *extents -> hb_bool_t
	get_glyph_contour_point_for_origin = C.hb_font_get_glyph_contour_point_for_origin, --hb_codepoint_t glyph, point_index, hb_direction_t direction, hb_position_t *x, hb_position_t *y -> hb_bool_t
	glyph_to_string = C.hb_font_glyph_to_string, --hb_codepoint_t glyph, s, size
	glyph_from_string = C.hb_font_glyph_from_string, --s, len, hb_codepoint_t *glyph -> hb_bool_t

	shape = function(font, buffer, features, num_features)
		C.hb_shape(font, buffer, features, num_features or 0)
	end,
	shape_full = function(font, buffer, features, num_features, shaper_list)
		return C.hb_shape_full(font, buffer, features, num_features or 0, shaper_list) == 1
	end,

	--from hb-ot.h
	get_ligature_carets  = get_ligature_carets,
	shape_glyphs_closure = C.hb_ot_shape_glyphs_closure,

	--from hb-ft.h
	set_ft_funcs = C.hb_ft_font_set_funcs,
	get_ft_face = C.hb_ft_font_get_face,
	set_ft_load_flags = C.hb_ft_font_set_load_flags,
	get_ft_load_flags = C.hb_ft_font_get_load_flags,
	ft_changed = C.hb_ft_font_changed,
}})

local function add_func(c_add_func, charsize)
	return function(self, buf, len, item_ofs, item_len)
		len = len or #buf / charsize
		c_add_func(self, buf, len, item_ofs or 0, item_len or len)
	end
end

ffi.metatype('hb_buffer_t', {__index = {
	ref = create_func(C.hb_buffer_reference, C.hb_buffer_destroy),
	free = destroy_func(C.hb_buffer_destroy),
	set_user_data = C.hb_buffer_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_buffer_get_user_data, --key -> data

	set_content_type = C.hb_buffer_set_content_type, --hb_buffer_content_type_t content_type
	get_content_type = C.hb_buffer_get_content_type, -- () -> hb_buffer_content_type_t
	set_unicode_funcs = C.hb_buffer_set_unicode_funcs, --hb_unicode_funcs_t *unicode_funcs
	get_unicode_funcs = C.hb_buffer_get_unicode_funcs,
	set_direction = function(self, direction)
		if type(direction) == 'string' then
			direction = C.hb_direction_from_string(direction, #direction)
		end
		C.hb_buffer_set_direction(self, direction)
	end,
	get_direction = C.hb_buffer_get_direction,
	set_script = C.hb_buffer_set_script, --hb_script_t script
	get_script = C.hb_buffer_get_script,
	set_language = function(self, lang)
		if type(lang) == 'string' then
			lang = C.hb_language_from_string(lang, #lang)
		end
		C.hb_buffer_set_language(self, lang)
	end,
	get_language = C.hb_buffer_get_language,
	set_segment_properties = C.hb_buffer_set_segment_properties, --hb_segment_properties_t *props
	get_segment_properties = C.hb_buffer_get_segment_properties,
	guess_segment_properties = C.hb_buffer_guess_segment_properties,

	set_flags = C.hb_buffer_set_flags, --hb_buffer_flags_t flags
	get_flags = C.hb_buffer_get_flags,
	set_cluster_level = C.hb_buffer_set_cluster_level,
	get_cluster_level = C.hb_buffer_get_cluster_level,
	set_replacement_codepoint = C.hb_buffer_set_replacement_codepoint,
	get_replacement_codepoint = C.hb_buffer_get_replacement_codepoint,

	reset = C.hb_buffer_reset,
	clear = C.hb_buffer_clear_contents,
	pre_allocate = C.hb_buffer_pre_allocate, --size
	allocation_successful = C.hb_buffer_allocation_successful,
	reverse = C.hb_buffer_reverse,
	reverse_clusters = C.hb_buffer_reverse_clusters,

	add = C.hb_buffer_add, --hb_codepoint_t codepoint, unsigned int cluster
	add_utf8  = add_func(C.hb_buffer_add_utf8, 1),
	add_utf16 = add_func(C.hb_buffer_add_utf16, 2),
	add_utf32 = add_func(C.hb_buffer_add_utf32, 4),
	add_codepoints = add_func(C.hb_buffer_add_codepoints, 4),

	set_length = C.hb_buffer_set_length, --length
	get_length = C.hb_buffer_get_length,
	get_glyph_infos     = function(self) return C.hb_buffer_get_glyph_infos(self, nil) end,
	get_glyph_positions = function(self) return C.hb_buffer_get_glyph_positions(self, nil) end,

	normalize_glyphs = C.hb_buffer_normalize_glyphs,
	serialize_glyphs = function(self, buf, sz, start, end_, buf_consumed, font, format, flags)
		start = start or 1
		end_ = end_ or self:get_length()
		format = format or C.HB_BUFFER_SERIALIZE_FORMAT_JSON
		flags = flags or C.HB_BUFFER_SERIALIZE_FLAGS_DEFAULT
		--returns number of items serialized
		return C.hb_buffer_serialize_glyphs(start-1, end_-1, buf, sz, buf_consumed, font, format, flags)
	end,
	deserialize_glyphs = function(self, buf, buf_len, end_ptr, font, format)
		format = format or C.HB_BUFFER_SERIALIZE_FORMAT_JSON
		return C.hb_buffer_deserialize_glyphs(buf, buf_len or -1, end_ptr, font, format)
	end,

	shape = function(buffer, font, features, num_features)
		C.hb_shape(font, buffer, features, num_features or 0)
	end,
	shape_full = function(buffer, font, features, num_features, shaper_list)
		return C.hb_shape_full(font, buffer, features, num_features or 0, shaper_list)
	end,
}})

ffi.metatype('hb_shape_plan_t', {__index = {
	ref = create_func(C.hb_shape_plan_reference, C.hb_shape_plan_destroy),
	free = destroy_func(C.hb_shape_plan_destroy),
	set_user_data = C.hb_shape_plan_set_user_data,
	get_user_data = C.hb_shape_plan_get_user_data,
	execute = C.hb_shape_plan_execute,
	get_shaper = string_func(C.hb_shape_plan_get_shaper),

	--from hb-ot.h
	collect_lookups = C.hb_ot_shape_plan_collect_lookups,
}})

ffi.metatype('hb_glyph_info_t', {__index = {
	unsafe_to_break = function(glyph_info, i)
		return band(glyph_info[i].mask, C.HB_GLYPH_FLAG_UNSAFE_TO_BREAK) ~= 0
	end,
}})

return hb

