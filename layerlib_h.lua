local ffi = require'ffi'
local C = ffi.load'layerlib'
ffi.cdef[[
typedef struct Lib Lib;
typedef struct Layer Layer;
typedef struct double2 double2;
typedef struct _cairo _cairo;
typedef struct Bitmap Bitmap;
typedef struct cairo_argb32_color_t cairo_argb32_color_t;
typedef void (*FontLoadFunc) (int16_t, void**, int64_t*);
typedef void (*BorderLineToFunc) (Layer*, _cairo*, double, double, double);
uint64_t memtotal();
void memreport();
Lib* layerlib(FontLoadFunc, FontLoadFunc);
Layer* Lib_layer(Lib*, Layer*);
double Lib_get_font_size_resolution(Lib*);
double Lib_get_subpixel_x_resolution(Lib*);
double Lib_get_word_subpixel_x_resolution(Lib*);
int32_t Lib_get_glyph_cache_size(Lib*);
int32_t Lib_get_glyph_run_cache_size(Lib*);
void Lib_set_font_size_resolution(Lib*, double);
void Lib_set_subpixel_x_resolution(Lib*, double);
void Lib_set_word_subpixel_x_resolution(Lib*, double);
void Lib_set_glyph_cache_size(Lib*, int32_t);
void Lib_set_glyph_run_cache_size(Lib*, int32_t);
int16_t Lib_font(Lib*);
void Lib_free(Lib*);
void Lib_dump_stats(Lib*);
Layer* Layer_get_parent(Layer*);
void Layer_free(Layer*);
int32_t Layer_get_index(Layer*);
void Layer_move(Layer*, Layer*, int32_t);
void Layer_set_index(Layer*, int32_t);
void Layer_set_parent(Layer*, Layer*);
int32_t Layer_get_child_count(Layer*);
void Layer_set_child_count(Layer*, int32_t);
Layer* Layer_child(Layer*, int32_t);
double Layer_get_x(Layer*);
double Layer_get_y(Layer*);
double Layer_get_w(Layer*);
double Layer_get_h(Layer*);
void Layer_set_x(Layer*, double);
void Layer_set_y(Layer*, double);
void Layer_set_w(Layer*, double);
void Layer_set_h(Layer*, double);
double Layer_get_cw(Layer*);
double Layer_get_ch(Layer*);
void Layer_set_cw(Layer*, double);
void Layer_set_ch(Layer*, double);
double Layer_get_cx(Layer*);
double Layer_get_cy(Layer*);
void Layer_set_cx(Layer*, double);
void Layer_set_cy(Layer*, double);
double2 Layer_from_box_to_parent(Layer*, double, double);
double2 Layer_from_parent_to_box(Layer*, double, double);
double2 Layer_to_parent(Layer*, double, double);
double2 Layer_from_parent(Layer*, double, double);
double2 Layer_to_window(Layer*, double, double);
double2 Layer_from_window(Layer*, double, double);
double2 Layer_to_content(Layer*, double, double);
double2 Layer_from_content(Layer*, double, double);
void Layer_draw(Layer*, _cairo*);
void Layer_sync_top(Layer*, double, double);
void Layer_sync_layout_separate_axes(Layer*, int8_t, double, double);
int8_t Layer_get_layout_type(Layer*);
void Layer_set_layout_type(Layer*, int8_t);
double Layer_get_padding_left(Layer*);
double Layer_get_padding_right(Layer*);
double Layer_get_padding_top(Layer*);
double Layer_get_padding_bottom(Layer*);
void Layer_set_padding_left(Layer*, double);
void Layer_set_padding_right(Layer*, double);
void Layer_set_padding_top(Layer*, double);
void Layer_set_padding_bottom(Layer*, double);
void Layer_set_padding(Layer*, double);
bool Layer_get_visible(Layer*);
int8_t Layer_get_operator(Layer*);
int8_t Layer_get_clip_content(Layer*);
bool Layer_get_snap_x(Layer*);
bool Layer_get_snap_y(Layer*);
double Layer_get_opacity(Layer*);
void Layer_set_visible(Layer*, bool);
void Layer_set_operator(Layer*, int8_t);
void Layer_set_clip_content(Layer*, int8_t);
void Layer_set_snap_x(Layer*, bool);
void Layer_set_snap_y(Layer*, bool);
void Layer_set_opacity(Layer*, double);
double Layer_get_rotation(Layer*);
double Layer_get_rotation_cx(Layer*);
double Layer_get_rotation_cy(Layer*);
double Layer_get_scale(Layer*);
double Layer_get_scale_cx(Layer*);
double Layer_get_scale_cy(Layer*);
void Layer_set_rotation(Layer*, double);
void Layer_set_rotation_cx(Layer*, double);
void Layer_set_rotation_cy(Layer*, double);
void Layer_set_scale(Layer*, double);
void Layer_set_scale_cx(Layer*, double);
void Layer_set_scale_cy(Layer*, double);
double Layer_get_border_width_left(Layer*);
double Layer_get_border_width_right(Layer*);
double Layer_get_border_width_top(Layer*);
double Layer_get_border_width_bottom(Layer*);
void Layer_set_border_width_left(Layer*, double);
void Layer_set_border_width_right(Layer*, double);
void Layer_set_border_width_top(Layer*, double);
void Layer_set_border_width_bottom(Layer*, double);
void Layer_set_border_width(Layer*, double);
double Layer_get_corner_radius_top_left(Layer*);
double Layer_get_corner_radius_top_right(Layer*);
double Layer_get_corner_radius_bottom_left(Layer*);
double Layer_get_corner_radius_bottom_right(Layer*);
double Layer_get_corner_radius_kappa(Layer*);
void Layer_set_corner_radius_top_left(Layer*, double);
void Layer_set_corner_radius_top_right(Layer*, double);
void Layer_set_corner_radius_bottom_left(Layer*, double);
void Layer_set_corner_radius_bottom_right(Layer*, double);
void Layer_set_corner_radius_kappa(Layer*, double);
void Layer_set_corner_radius(Layer*, double);
uint32_t Layer_get_border_color_left(Layer*);
uint32_t Layer_get_border_color_right(Layer*);
uint32_t Layer_get_border_color_top(Layer*);
uint32_t Layer_get_border_color_bottom(Layer*);
void Layer_set_border_color_left(Layer*, uint32_t);
void Layer_set_border_color_right(Layer*, uint32_t);
void Layer_set_border_color_top(Layer*, uint32_t);
void Layer_set_border_color_bottom(Layer*, uint32_t);
void Layer_set_border_color(Layer*, uint32_t);
int32_t Layer_get_border_dash_count(Layer*);
void Layer_set_border_dash_count(Layer*, int32_t);
double Layer_get_border_dash(Layer*, int32_t);
double* Layer_set_border_dash(Layer*, int32_t, double);
int32_t Layer_get_border_dash_offset(Layer*);
void Layer_set_border_dash_offset(Layer*, int32_t);
void Layer_set_border_line_to(Layer*, BorderLineToFunc);
int8_t Layer_get_background_type(Layer*);
void Layer_set_background_type(Layer*, int8_t);
bool Layer_get_background_hittable(Layer*);
void Layer_set_background_hittable(Layer*, bool);
int8_t Layer_get_background_operator(Layer*);
void Layer_set_background_operator(Layer*, int8_t);
double Layer_get_background_clip_border_offset(Layer*);
void Layer_set_background_clip_border_offset(Layer*, double);
uint32_t Layer_get_background_color(Layer*);
void Layer_set_background_color(Layer*, uint32_t);
bool Layer_get_background_color_set(Layer*);
void Layer_set_background_color_set(Layer*, bool);
double Layer_get_background_x1(Layer*);
double Layer_get_background_y1(Layer*);
double Layer_get_background_x2(Layer*);
double Layer_get_background_y2(Layer*);
double Layer_get_background_r1(Layer*);
double Layer_get_background_r2(Layer*);
void Layer_set_background_x1(Layer*, double);
void Layer_set_background_y1(Layer*, double);
void Layer_set_background_x2(Layer*, double);
void Layer_set_background_y2(Layer*, double);
void Layer_set_background_r1(Layer*, double);
void Layer_set_background_r2(Layer*, double);
int32_t Layer_get_background_color_stop_count(Layer*);
void Layer_set_background_color_stop_count(Layer*, int32_t);
uint32_t Layer_get_background_color_stop_color(Layer*, int32_t);
double Layer_get_background_color_stop_offset(Layer*, int32_t);
void Layer_set_background_color_stop_color(Layer*, int32_t, uint32_t);
void Layer_set_background_color_stop_offset(Layer*, int32_t, double);
Bitmap* Layer_get_background_image(Layer*);
void Layer_set_background_image(Layer*, Bitmap*);
double Layer_get_background_x(Layer*);
double Layer_get_background_y(Layer*);
int8_t Layer_get_background_extend(Layer*);
void Layer_set_background_x(Layer*, double);
void Layer_set_background_y(Layer*, double);
void Layer_set_background_extend(Layer*, int8_t);
double Layer_get_background_rotation(Layer*);
double Layer_get_background_rotation_cx(Layer*);
double Layer_get_background_rotation_cy(Layer*);
double Layer_get_background_scale(Layer*);
double Layer_get_background_scale_cx(Layer*);
double Layer_get_background_scale_cy(Layer*);
void Layer_set_background_rotation(Layer*, double);
void Layer_set_background_rotation_cx(Layer*, double);
void Layer_set_background_rotation_cy(Layer*, double);
void Layer_set_background_scale(Layer*, double);
void Layer_set_background_scale_cx(Layer*, double);
void Layer_set_background_scale_cy(Layer*, double);
double Layer_get_shadow_x(Layer*, int32_t);
double Layer_get_shadow_y(Layer*, int32_t);
cairo_argb32_color_t Layer_get_shadow_color(Layer*, int32_t);
uint8_t Layer_get_shadow_blur(Layer*, int32_t);
uint8_t Layer_get_shadow_passes(Layer*, int32_t);
bool Layer_get_shadow_inset(Layer*, int32_t);
bool Layer_get_shadow_content(Layer*, int32_t);
void Layer_set_shadow_x(Layer*, int32_t, double);
void Layer_set_shadow_y(Layer*, int32_t, double);
void Layer_set_shadow_color(Layer*, int32_t, uint32_t);
void Layer_set_shadow_blur(Layer*, int32_t, uint8_t);
void Layer_set_shadow_passes(Layer*, int32_t, uint8_t);
void Layer_set_shadow_inset(Layer*, int32_t, bool);
void Layer_set_shadow_content(Layer*, int32_t, bool);
uint32_t* Layer_get_text_utf32(Layer*);
int32_t Layer_get_text_utf32_len(Layer*);
void Layer_set_text_utf32(Layer*, uint32_t*, int32_t);
void Layer_set_text_utf8(Layer*, const char *, int32_t);
int32_t Layer_get_text_utf8_len(Layer*);
int32_t Layer_get_text_utf8(Layer*, const char *, int32_t);
int32_t Layer_get_text_maxlen(Layer*);
void Layer_set_text_maxlen(Layer*, int32_t);
int32_t Layer_get_text_span_count(Layer*);
void Layer_set_text_span_count(Layer*, int32_t);
int32_t Layer_get_text_span_feature_count(Layer*, int32_t);
void Layer_clear_text_span_features(Layer*, int32_t);
bool Layer_get_text_span_feature(Layer*, int32_t, int32_t, const char *, int32_t);
bool Layer_add_text_span_feature(Layer*, int32_t, const char *, int32_t);
int32_t Layer_get_text_span_offset(Layer*, int32_t);
float Layer_get_text_span_font_size(Layer*, int32_t);
uint32_t Layer_get_text_span_dir(Layer*, int32_t);
float Layer_get_text_span_line_spacing(Layer*, int32_t);
float Layer_get_text_span_hardline_spacing(Layer*, int32_t);
float Layer_get_text_span_paragraph_spacing(Layer*, int32_t);
bool Layer_get_text_span_nowrap(Layer*, int32_t);
uint32_t Layer_get_text_span_color(Layer*, int32_t);
double Layer_get_text_span_opacity(Layer*, int32_t);
int32_t Layer_get_text_span_operator(Layer*, int32_t);
void Layer_set_text_span_offset(Layer*, int32_t, int32_t);
void Layer_set_text_span_font_size(Layer*, int32_t, double);
void Layer_set_text_span_dir(Layer*, int32_t, uint32_t);
void Layer_set_text_span_line_spacing(Layer*, int32_t, double);
void Layer_set_text_span_hardline_spacing(Layer*, int32_t, double);
void Layer_set_text_span_paragraph_spacing(Layer*, int32_t, double);
void Layer_set_text_span_nowrap(Layer*, int32_t, bool);
void Layer_set_text_span_color(Layer*, int32_t, uint32_t);
void Layer_set_text_span_opacity(Layer*, int32_t, double);
void Layer_set_text_span_operator(Layer*, int32_t, int32_t);
const char * Layer_get_text_span_script(Layer*, int32_t);
void Layer_set_text_span_script(Layer*, int32_t, const char *);
const char * Layer_get_text_span_lang(Layer*, int32_t);
void Layer_set_text_span_lang(Layer*, int32_t, const char *);
int8_t Layer_get_text_align_x(Layer*);
int8_t Layer_get_text_align_y(Layer*);
void Layer_set_text_align_x(Layer*, int8_t);
void Layer_set_text_align_y(Layer*, int8_t);
double Layer_get_text_caret_width(Layer*);
uint32_t Layer_get_text_caret_color(Layer*);
bool Layer_get_text_caret_insert_mode(Layer*);
bool Layer_get_text_selectable(Layer*);
void Layer_set_text_caret_width(Layer*, double);
void Layer_set_text_caret_color(Layer*, uint32_t);
void Layer_set_text_caret_insert_mode(Layer*, bool);
void Layer_set_text_selectable(Layer*, bool);
int16_t Layer_get_text_span_font_id(Layer*, int32_t);
void Layer_set_text_span_font_id(Layer*, int32_t, int32_t);
int8_t Layer_get_align_items_x(Layer*);
int8_t Layer_get_align_items_y(Layer*);
int8_t Layer_get_item_align_x(Layer*);
int8_t Layer_get_item_align_y(Layer*);
void Layer_set_align_items_x(Layer*, int8_t);
void Layer_set_align_items_y(Layer*, int8_t);
void Layer_set_item_align_x(Layer*, int8_t);
void Layer_set_item_align_y(Layer*, int8_t);
int8_t Layer_get_flex_flow(Layer*);
void Layer_set_flex_flow(Layer*, int8_t);
bool Layer_get_flex_wrap(Layer*);
void Layer_set_flex_wrap(Layer*, bool);
double Layer_get_fr(Layer*);
void Layer_set_fr(Layer*, double);
bool Layer_get_break_before(Layer*);
bool Layer_get_break_after(Layer*);
void Layer_set_break_before(Layer*, bool);
void Layer_set_break_after(Layer*, bool);
int32_t Layer_get_grid_col_fr_count(Layer*);
int32_t Layer_get_grid_row_fr_count(Layer*);
void Layer_set_grid_col_fr_count(Layer*, int32_t);
void Layer_set_grid_row_fr_count(Layer*, int32_t);
double Layer_get_grid_col_fr(Layer*, int32_t);
double Layer_get_grid_row_fr(Layer*, int32_t);
void Layer_set_grid_col_fr(Layer*, int32_t, double);
void Layer_set_grid_row_fr(Layer*, int32_t, double);
double Layer_get_grid_col_gap(Layer*);
double Layer_get_grid_row_gap(Layer*);
void Layer_set_grid_col_gap(Layer*, double);
void Layer_set_grid_row_gap(Layer*, double);
int8_t Layer_get_grid_flow(Layer*);
void Layer_set_grid_flow(Layer*, int8_t);
int32_t Layer_get_grid_wrap(Layer*);
void Layer_set_grid_wrap(Layer*, int32_t);
int32_t Layer_get_grid_min_lines(Layer*);
void Layer_set_grid_min_lines(Layer*, int32_t);
double Layer_get_min_cw(Layer*);
double Layer_get_min_ch(Layer*);
void Layer_set_min_cw(Layer*, double);
void Layer_set_min_ch(Layer*, double);
int32_t Layer_get_grid_col(Layer*);
int32_t Layer_get_grid_row(Layer*);
void Layer_set_grid_col(Layer*, int32_t);
void Layer_set_grid_row(Layer*, int32_t);
int32_t Layer_get_grid_col_span(Layer*);
int32_t Layer_get_grid_row_span(Layer*);
void Layer_set_grid_col_span(Layer*, int32_t);
void Layer_set_grid_row_span(Layer*, int32_t);
int8_t Layer_get_hit_test_mask(Layer*);
void Layer_set_hit_test_mask(Layer*, int8_t);
int8_t Layer_hit_test(Layer*, _cairo*, double, double, int8_t, Layer**);
]]
pcall(ffi.cdef, 'struct double2 { double _0; double _1; };')
local getters = {
	font_size_resolution = C.Lib_get_font_size_resolution,
	subpixel_x_resolution = C.Lib_get_subpixel_x_resolution,
	word_subpixel_x_resolution = C.Lib_get_word_subpixel_x_resolution,
	glyph_cache_size = C.Lib_get_glyph_cache_size,
	glyph_run_cache_size = C.Lib_get_glyph_run_cache_size,
}
local setters = {
	font_size_resolution = C.Lib_set_font_size_resolution,
	subpixel_x_resolution = C.Lib_set_subpixel_x_resolution,
	word_subpixel_x_resolution = C.Lib_set_word_subpixel_x_resolution,
	glyph_cache_size = C.Lib_set_glyph_cache_size,
	glyph_run_cache_size = C.Lib_set_glyph_run_cache_size,
}
local methods = {
	layer = C.Lib_layer,
	font = C.Lib_font,
	free = C.Lib_free,
	dump_stats = C.Lib_dump_stats,
}
ffi.metatype('Lib', {
	__index = function(self, k)
		local getter = getters[k]
		if getter then return getter(self) end
		return methods[k]
	end,
	__newindex = function(self, k, v)
		local setter = setters[k]
		if not setter then
			error(('field not found: %s'):format(tostring(k)), 2)
		end
		setter(self, v)
	end,
})
local getters = {
	parent = C.Layer_get_parent,
	index = C.Layer_get_index,
	child_count = C.Layer_get_child_count,
	x = C.Layer_get_x,
	y = C.Layer_get_y,
	w = C.Layer_get_w,
	h = C.Layer_get_h,
	cw = C.Layer_get_cw,
	ch = C.Layer_get_ch,
	cx = C.Layer_get_cx,
	cy = C.Layer_get_cy,
	layout_type = C.Layer_get_layout_type,
	padding_left = C.Layer_get_padding_left,
	padding_right = C.Layer_get_padding_right,
	padding_top = C.Layer_get_padding_top,
	padding_bottom = C.Layer_get_padding_bottom,
	visible = C.Layer_get_visible,
	operator = C.Layer_get_operator,
	clip_content = C.Layer_get_clip_content,
	snap_x = C.Layer_get_snap_x,
	snap_y = C.Layer_get_snap_y,
	opacity = C.Layer_get_opacity,
	rotation = C.Layer_get_rotation,
	rotation_cx = C.Layer_get_rotation_cx,
	rotation_cy = C.Layer_get_rotation_cy,
	scale = C.Layer_get_scale,
	scale_cx = C.Layer_get_scale_cx,
	scale_cy = C.Layer_get_scale_cy,
	border_width_left = C.Layer_get_border_width_left,
	border_width_right = C.Layer_get_border_width_right,
	border_width_top = C.Layer_get_border_width_top,
	border_width_bottom = C.Layer_get_border_width_bottom,
	corner_radius_top_left = C.Layer_get_corner_radius_top_left,
	corner_radius_top_right = C.Layer_get_corner_radius_top_right,
	corner_radius_bottom_left = C.Layer_get_corner_radius_bottom_left,
	corner_radius_bottom_right = C.Layer_get_corner_radius_bottom_right,
	corner_radius_kappa = C.Layer_get_corner_radius_kappa,
	border_color_left = C.Layer_get_border_color_left,
	border_color_right = C.Layer_get_border_color_right,
	border_color_top = C.Layer_get_border_color_top,
	border_color_bottom = C.Layer_get_border_color_bottom,
	border_dash_count = C.Layer_get_border_dash_count,
	border_dash_offset = C.Layer_get_border_dash_offset,
	background_type = C.Layer_get_background_type,
	background_hittable = C.Layer_get_background_hittable,
	background_operator = C.Layer_get_background_operator,
	background_clip_border_offset = C.Layer_get_background_clip_border_offset,
	background_color = C.Layer_get_background_color,
	background_color_set = C.Layer_get_background_color_set,
	background_x1 = C.Layer_get_background_x1,
	background_y1 = C.Layer_get_background_y1,
	background_x2 = C.Layer_get_background_x2,
	background_y2 = C.Layer_get_background_y2,
	background_r1 = C.Layer_get_background_r1,
	background_r2 = C.Layer_get_background_r2,
	background_color_stop_count = C.Layer_get_background_color_stop_count,
	background_image = C.Layer_get_background_image,
	background_x = C.Layer_get_background_x,
	background_y = C.Layer_get_background_y,
	background_extend = C.Layer_get_background_extend,
	background_rotation = C.Layer_get_background_rotation,
	background_rotation_cx = C.Layer_get_background_rotation_cx,
	background_rotation_cy = C.Layer_get_background_rotation_cy,
	background_scale = C.Layer_get_background_scale,
	background_scale_cx = C.Layer_get_background_scale_cx,
	background_scale_cy = C.Layer_get_background_scale_cy,
	text_utf32 = C.Layer_get_text_utf32,
	text_utf32_len = C.Layer_get_text_utf32_len,
	text_utf8_len = C.Layer_get_text_utf8_len,
	text_maxlen = C.Layer_get_text_maxlen,
	text_span_count = C.Layer_get_text_span_count,
	text_align_x = C.Layer_get_text_align_x,
	text_align_y = C.Layer_get_text_align_y,
	text_caret_width = C.Layer_get_text_caret_width,
	text_caret_color = C.Layer_get_text_caret_color,
	text_caret_insert_mode = C.Layer_get_text_caret_insert_mode,
	text_selectable = C.Layer_get_text_selectable,
	align_items_x = C.Layer_get_align_items_x,
	align_items_y = C.Layer_get_align_items_y,
	item_align_x = C.Layer_get_item_align_x,
	item_align_y = C.Layer_get_item_align_y,
	flex_flow = C.Layer_get_flex_flow,
	flex_wrap = C.Layer_get_flex_wrap,
	fr = C.Layer_get_fr,
	break_before = C.Layer_get_break_before,
	break_after = C.Layer_get_break_after,
	grid_col_fr_count = C.Layer_get_grid_col_fr_count,
	grid_row_fr_count = C.Layer_get_grid_row_fr_count,
	grid_col_gap = C.Layer_get_grid_col_gap,
	grid_row_gap = C.Layer_get_grid_row_gap,
	grid_flow = C.Layer_get_grid_flow,
	grid_wrap = C.Layer_get_grid_wrap,
	grid_min_lines = C.Layer_get_grid_min_lines,
	min_cw = C.Layer_get_min_cw,
	min_ch = C.Layer_get_min_ch,
	grid_col = C.Layer_get_grid_col,
	grid_row = C.Layer_get_grid_row,
	grid_col_span = C.Layer_get_grid_col_span,
	grid_row_span = C.Layer_get_grid_row_span,
	hit_test_mask = C.Layer_get_hit_test_mask,
}
local setters = {
	index = C.Layer_set_index,
	parent = C.Layer_set_parent,
	child_count = C.Layer_set_child_count,
	x = C.Layer_set_x,
	y = C.Layer_set_y,
	w = C.Layer_set_w,
	h = C.Layer_set_h,
	cw = C.Layer_set_cw,
	ch = C.Layer_set_ch,
	cx = C.Layer_set_cx,
	cy = C.Layer_set_cy,
	layout_type = C.Layer_set_layout_type,
	padding_left = C.Layer_set_padding_left,
	padding_right = C.Layer_set_padding_right,
	padding_top = C.Layer_set_padding_top,
	padding_bottom = C.Layer_set_padding_bottom,
	padding = C.Layer_set_padding,
	visible = C.Layer_set_visible,
	operator = C.Layer_set_operator,
	clip_content = C.Layer_set_clip_content,
	snap_x = C.Layer_set_snap_x,
	snap_y = C.Layer_set_snap_y,
	opacity = C.Layer_set_opacity,
	rotation = C.Layer_set_rotation,
	rotation_cx = C.Layer_set_rotation_cx,
	rotation_cy = C.Layer_set_rotation_cy,
	scale = C.Layer_set_scale,
	scale_cx = C.Layer_set_scale_cx,
	scale_cy = C.Layer_set_scale_cy,
	border_width_left = C.Layer_set_border_width_left,
	border_width_right = C.Layer_set_border_width_right,
	border_width_top = C.Layer_set_border_width_top,
	border_width_bottom = C.Layer_set_border_width_bottom,
	border_width = C.Layer_set_border_width,
	corner_radius_top_left = C.Layer_set_corner_radius_top_left,
	corner_radius_top_right = C.Layer_set_corner_radius_top_right,
	corner_radius_bottom_left = C.Layer_set_corner_radius_bottom_left,
	corner_radius_bottom_right = C.Layer_set_corner_radius_bottom_right,
	corner_radius_kappa = C.Layer_set_corner_radius_kappa,
	corner_radius = C.Layer_set_corner_radius,
	border_color_left = C.Layer_set_border_color_left,
	border_color_right = C.Layer_set_border_color_right,
	border_color_top = C.Layer_set_border_color_top,
	border_color_bottom = C.Layer_set_border_color_bottom,
	border_color = C.Layer_set_border_color,
	border_dash_count = C.Layer_set_border_dash_count,
	border_dash_offset = C.Layer_set_border_dash_offset,
	border_line_to = C.Layer_set_border_line_to,
	background_type = C.Layer_set_background_type,
	background_hittable = C.Layer_set_background_hittable,
	background_operator = C.Layer_set_background_operator,
	background_clip_border_offset = C.Layer_set_background_clip_border_offset,
	background_color = C.Layer_set_background_color,
	background_color_set = C.Layer_set_background_color_set,
	background_x1 = C.Layer_set_background_x1,
	background_y1 = C.Layer_set_background_y1,
	background_x2 = C.Layer_set_background_x2,
	background_y2 = C.Layer_set_background_y2,
	background_r1 = C.Layer_set_background_r1,
	background_r2 = C.Layer_set_background_r2,
	background_color_stop_count = C.Layer_set_background_color_stop_count,
	background_image = C.Layer_set_background_image,
	background_x = C.Layer_set_background_x,
	background_y = C.Layer_set_background_y,
	background_extend = C.Layer_set_background_extend,
	background_rotation = C.Layer_set_background_rotation,
	background_rotation_cx = C.Layer_set_background_rotation_cx,
	background_rotation_cy = C.Layer_set_background_rotation_cy,
	background_scale = C.Layer_set_background_scale,
	background_scale_cx = C.Layer_set_background_scale_cx,
	background_scale_cy = C.Layer_set_background_scale_cy,
	text_maxlen = C.Layer_set_text_maxlen,
	text_span_count = C.Layer_set_text_span_count,
	text_align_x = C.Layer_set_text_align_x,
	text_align_y = C.Layer_set_text_align_y,
	text_caret_width = C.Layer_set_text_caret_width,
	text_caret_color = C.Layer_set_text_caret_color,
	text_caret_insert_mode = C.Layer_set_text_caret_insert_mode,
	text_selectable = C.Layer_set_text_selectable,
	align_items_x = C.Layer_set_align_items_x,
	align_items_y = C.Layer_set_align_items_y,
	item_align_x = C.Layer_set_item_align_x,
	item_align_y = C.Layer_set_item_align_y,
	flex_flow = C.Layer_set_flex_flow,
	flex_wrap = C.Layer_set_flex_wrap,
	fr = C.Layer_set_fr,
	break_before = C.Layer_set_break_before,
	break_after = C.Layer_set_break_after,
	grid_col_fr_count = C.Layer_set_grid_col_fr_count,
	grid_row_fr_count = C.Layer_set_grid_row_fr_count,
	grid_col_gap = C.Layer_set_grid_col_gap,
	grid_row_gap = C.Layer_set_grid_row_gap,
	grid_flow = C.Layer_set_grid_flow,
	grid_wrap = C.Layer_set_grid_wrap,
	grid_min_lines = C.Layer_set_grid_min_lines,
	min_cw = C.Layer_set_min_cw,
	min_ch = C.Layer_set_min_ch,
	grid_col = C.Layer_set_grid_col,
	grid_row = C.Layer_set_grid_row,
	grid_col_span = C.Layer_set_grid_col_span,
	grid_row_span = C.Layer_set_grid_row_span,
	hit_test_mask = C.Layer_set_hit_test_mask,
}
local methods = {
	free = C.Layer_free,
	move = C.Layer_move,
	child = C.Layer_child,
	from_box_to_parent = C.Layer_from_box_to_parent,
	from_parent_to_box = C.Layer_from_parent_to_box,
	to_parent = C.Layer_to_parent,
	from_parent = C.Layer_from_parent,
	to_window = C.Layer_to_window,
	from_window = C.Layer_from_window,
	to_content = C.Layer_to_content,
	from_content = C.Layer_from_content,
	draw = C.Layer_draw,
	sync_top = C.Layer_sync_top,
	sync_layout_separate_axes = C.Layer_sync_layout_separate_axes,
	get_border_dash = C.Layer_get_border_dash,
	set_border_dash = C.Layer_set_border_dash,
	get_background_color_stop_color = C.Layer_get_background_color_stop_color,
	get_background_color_stop_offset = C.Layer_get_background_color_stop_offset,
	set_background_color_stop_color = C.Layer_set_background_color_stop_color,
	set_background_color_stop_offset = C.Layer_set_background_color_stop_offset,
	get_shadow_x = C.Layer_get_shadow_x,
	get_shadow_y = C.Layer_get_shadow_y,
	get_shadow_color = C.Layer_get_shadow_color,
	get_shadow_blur = C.Layer_get_shadow_blur,
	get_shadow_passes = C.Layer_get_shadow_passes,
	get_shadow_inset = C.Layer_get_shadow_inset,
	get_shadow_content = C.Layer_get_shadow_content,
	set_shadow_x = C.Layer_set_shadow_x,
	set_shadow_y = C.Layer_set_shadow_y,
	set_shadow_color = C.Layer_set_shadow_color,
	set_shadow_blur = C.Layer_set_shadow_blur,
	set_shadow_passes = C.Layer_set_shadow_passes,
	set_shadow_inset = C.Layer_set_shadow_inset,
	set_shadow_content = C.Layer_set_shadow_content,
	set_text_utf32 = C.Layer_set_text_utf32,
	set_text_utf8 = C.Layer_set_text_utf8,
	get_text_utf8 = C.Layer_get_text_utf8,
	get_text_span_feature_count = C.Layer_get_text_span_feature_count,
	clear_text_span_features = C.Layer_clear_text_span_features,
	get_text_span_feature = C.Layer_get_text_span_feature,
	add_text_span_feature = C.Layer_add_text_span_feature,
	get_text_span_offset = C.Layer_get_text_span_offset,
	get_text_span_font_size = C.Layer_get_text_span_font_size,
	get_text_span_dir = C.Layer_get_text_span_dir,
	get_text_span_line_spacing = C.Layer_get_text_span_line_spacing,
	get_text_span_hardline_spacing = C.Layer_get_text_span_hardline_spacing,
	get_text_span_paragraph_spacing = C.Layer_get_text_span_paragraph_spacing,
	get_text_span_nowrap = C.Layer_get_text_span_nowrap,
	get_text_span_color = C.Layer_get_text_span_color,
	get_text_span_opacity = C.Layer_get_text_span_opacity,
	get_text_span_operator = C.Layer_get_text_span_operator,
	set_text_span_offset = C.Layer_set_text_span_offset,
	set_text_span_font_size = C.Layer_set_text_span_font_size,
	set_text_span_dir = C.Layer_set_text_span_dir,
	set_text_span_line_spacing = C.Layer_set_text_span_line_spacing,
	set_text_span_hardline_spacing = C.Layer_set_text_span_hardline_spacing,
	set_text_span_paragraph_spacing = C.Layer_set_text_span_paragraph_spacing,
	set_text_span_nowrap = C.Layer_set_text_span_nowrap,
	set_text_span_color = C.Layer_set_text_span_color,
	set_text_span_opacity = C.Layer_set_text_span_opacity,
	set_text_span_operator = C.Layer_set_text_span_operator,
	get_text_span_script = C.Layer_get_text_span_script,
	set_text_span_script = C.Layer_set_text_span_script,
	get_text_span_lang = C.Layer_get_text_span_lang,
	set_text_span_lang = C.Layer_set_text_span_lang,
	get_text_span_font_id = C.Layer_get_text_span_font_id,
	set_text_span_font_id = C.Layer_set_text_span_font_id,
	get_grid_col_fr = C.Layer_get_grid_col_fr,
	get_grid_row_fr = C.Layer_get_grid_row_fr,
	set_grid_col_fr = C.Layer_set_grid_col_fr,
	set_grid_row_fr = C.Layer_set_grid_row_fr,
	hit_test = C.Layer_hit_test,
}
ffi.metatype('Layer', {
	__index = function(self, k)
		local getter = getters[k]
		if getter then return getter(self) end
		return methods[k]
	end,
	__newindex = function(self, k, v)
		local setter = setters[k]
		if not setter then
			error(('field not found: %s'):format(tostring(k)), 2)
		end
		setter(self, v)
	end,
})
ffi.cdef[[
enum {
	ALIGN_AUTO = 4,
	ALIGN_BASELINE = 11,
	ALIGN_BOTTOM = 2,
	ALIGN_CENTER = 3,
	ALIGN_DEFAULT = 0,
	ALIGN_END = 7,
	ALIGN_LEFT = 1,
	ALIGN_RIGHT = 2,
	ALIGN_SPACE_AROUND = 9,
	ALIGN_SPACE_BETWEEN = 10,
	ALIGN_SPACE_EVENLY = 8,
	ALIGN_START = 6,
	ALIGN_STRETCH = 5,
	ALIGN_TOP = 1,
	AXIS_ORDER_XY = 1,
	AXIS_ORDER_YX = 2,
	BACKGROUND_COLOR = 0,
	BACKGROUND_EXTEND_NONE = 0,
	BACKGROUND_EXTEND_PAD = 3,
	BACKGROUND_EXTEND_REFLECT = 2,
	BACKGROUND_EXTEND_REPEAT = 1,
	BACKGROUND_GRADIENT = 6,
	BACKGROUND_IMAGE = 4,
	BACKGROUND_LINEAR_GRADIENT = 6,
	BACKGROUND_PATTERN = 4,
	BACKGROUND_RADIAL_GRADIENT = 7,
	CLIP_BACKGROUND = 2,
	CLIP_NONE = 0,
	CLIP_PADDING = 1,
	DIR_AUTO = 64,
	DIR_LTR = 272,
	DIR_RTL = 273,
	DIR_WLTR = 32,
	DIR_WRTL = 33,
	FLEX_FLOW_X = 0,
	FLEX_FLOW_Y = 1,
	GRID_FLOW_B = 8,
	GRID_FLOW_L = 0,
	GRID_FLOW_R = 4,
	GRID_FLOW_T = 0,
	GRID_FLOW_X = 0,
	GRID_FLOW_Y = 2,
	HIT_BACKGROUND = 2,
	HIT_BORDER = 1,
	HIT_NONE = 0,
	HIT_TEXT = 3,
	HIT_TEXT_SELECTION = 4,
	LAYOUT_FLEXBOX = 2,
	LAYOUT_GRID = 3,
	LAYOUT_NULL = 0,
	LAYOUT_TEXTBOX = 1,
	OPERATOR_ADD = 12,
	OPERATOR_ATOP = 5,
	OPERATOR_CLEAR = 0,
	OPERATOR_COLOR_BURN = 20,
	OPERATOR_COLOR_DODGE = 19,
	OPERATOR_DARKEN = 17,
	OPERATOR_DEST = 6,
	OPERATOR_DEST_ATOP = 10,
	OPERATOR_DEST_IN = 8,
	OPERATOR_DEST_OUT = 9,
	OPERATOR_DEST_OVER = 7,
	OPERATOR_DIFFERENCE = 23,
	OPERATOR_EXCLUSION = 24,
	OPERATOR_HARD_LIGHT = 21,
	OPERATOR_HSL_COLOR = 27,
	OPERATOR_HSL_HUE = 25,
	OPERATOR_HSL_LUMINOSITY = 28,
	OPERATOR_HSL_SATURATION = 26,
	OPERATOR_IN = 3,
	OPERATOR_LIGHTEN = 18,
	OPERATOR_MULTIPLY = 14,
	OPERATOR_OUT = 4,
	OPERATOR_OVER = 2,
	OPERATOR_OVERLAY = 16,
	OPERATOR_SATURATE = 13,
	OPERATOR_SCREEN = 15,
	OPERATOR_SOFT_LIGHT = 22,
	OPERATOR_SOURCE = 1,
	OPERATOR_XOR = 11,
}]]
return C
