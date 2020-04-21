--[[

	HTML-like box-model layouting and rendering engine in Terra with a C API.
	Written by Cosmin Apreutesei. Public Domain.

	Discuss at luapower.com/forum or at github.com/luapower/terra.layer/issues.

	Uses `cairo` for path filling, stroking, clipping, masking and blending.
	Uses `terra.tr` for text shaping and rendering.
	Uses `terra.boxblur` and `boxblur` for shadows.

	NOTE: This is the implementation module. In here, invalid input data is
	undefined behavior and changing layer properties does not keep the internal
	state consistent. Use `layer_api` instead which takes care of all of that.

	Box model:

	* the "layer box" is defined by (x, y, w, h).
	* paddings are applied to the layer box, creating the "content box".
	* child layers are positioned relative to the content box.
	* child layers can be clipped to the content box subject to `clip_content`.
	* border can be inside or outside the layer box, subject to `border_offset`.
	* border and padding are independent as both are relative to the layer box
	  so to make room for an inner border, you need to add some padding.
	* background can be clipped to the inside or outside of the border outline,
	  subject to `background_clip_border_offset`.

	Layout types:

	* none (default): manual positioning via x, y, w, h properties.
	* textbox: content box grows to contain the text.
	* flexbox: "css flexbox"-like layout type.
	* grid: "css grid"-like layout type.

	Content-wrapping in layout systems:

	The presence of auto-wrapped content (text or wrapped flexbox items) in
	content-based layout systems (i.e. layouts that expand based on the
	content's minimum size) imposes that the layout be computed on the
	content's main flow axis before being computed on the cross-axis. This is
	because the minimum height of the content (assuming the main axis is the
	x-axis) cannot be known until wrapping the content, but wrapping requires
	knowing the final width of the container. This means that a layout that
	contains a mix of both horizontally and vertically flowing wrapped content
	cannot be computed correctly because such layout doesn't have a single
	solution. The current implementation simply favors one axis over another
	via `axis_order = AXIS_ORDER_XY` which means that vertically flowing
	wrapped flexboxes aren't able to impose a minimum size on their container.

]]

setfenv(1, require'terra.low'.module())
require'terra.memcheck'
require'terra.cairo'
require'terra.tr_paint_cairo'
tr = require'terra.tr_api'
bitmap = require'terra.bitmap'
blur = require'terra.boxblur'
box2d = require'terra.box2d'

--external types -------------------------------------------------------------

color = cairo_argb32_color_t
matrix = cairo_matrix_t
pattern = cairo_pattern_t
context = cairo_t
surface = cairo_surface_t
rect = box2d.rect(num)
Bitmap = bitmap.Bitmap
FontLoadFunc   = tr.FontLoadFunc
FontUnloadFunc = tr.FontUnloadFunc
ErrorFunc      = tr.ErrorFunc

--common enums ---------------------------------------------------------------

ALIGN_DEFAULT       = 0                --only for align_x/y
ALIGN_LEFT          = tr.ALIGN_LEFT
ALIGN_RIGHT         = tr.ALIGN_RIGHT
ALIGN_CENTER        = tr.ALIGN_CENTER
ALIGN_JUSTIFY       = tr.ALIGN_JUSTIFY
ALIGN_START         = tr.ALIGN_START   --left for LTR text, right for RTL
ALIGN_END           = tr.ALIGN_END     --left for RTL text, right for LTR
ALIGN_TOP           = tr.ALIGN_TOP     --needs to be same as ALIGN_LEFT!
ALIGN_BOTTOM        = tr.ALIGN_BOTTOM  --needs to be same as ALIGN_RIGHT!
ALIGN_STRETCH       = tr.ALIGN_MAX + 1
ALIGN_SPACE_EVENLY  = tr.ALIGN_MAX + 2 --only for align_items_*
ALIGN_SPACE_AROUND  = tr.ALIGN_MAX + 3 --only for align_items_*
ALIGN_SPACE_BETWEEN = tr.ALIGN_MAX + 4 --only for align_items_*
ALIGN_BASELINE      = tr.ALIGN_MAX + 5 --only for item_align_y

local function map_enum(C, src_prefix, dst_prefix)
	dst_prefix = dst_prefix or src_prefix
	for k,v in pairs(C) do
		local op = k:match('^'..src_prefix..'(.*)')
		if op then _M[dst_prefix..op] = v end
	end
end
map_enum(C, 'CAIRO_OPERATOR_', 'OPERATOR_')
map_enum(tr.__index, 'DIR_')
map_enum(tr.__index, 'CURSOR_')
map_enum(tr.__index, 'UNDERLINE_')
map_enum(tr.__index, 'WRAP_')
map_enum(bitmap, 'FORMAT_', 'BITMAP_FORMAT_')
map_enum(C, 'CAIRO_EXTEND_', 'BACKGROUND_EXTEND_')

OPERATOR_MIN = OPERATOR_CLEAR
OPERATOR_MAX = OPERATOR_HSL_LUMINOSITY

BACKGROUND_EXTEND_MIN = BACKGROUND_EXTEND_NONE
BACKGROUND_EXTEND_MAX = BACKGROUND_EXTEND_PAD

HIT_NONE           = 0 --this must be zero
HIT_BORDER         = 1
HIT_BACKGROUND     = 2
HIT_TEXT           = 3
HIT_TEXT_SELECTION = 4

--overridable constants ------------------------------------------------------

DEFAULT_BORDER_COLOR = DEFAULT_BORDER_COLOR or `color {0xffffffff}
DEFAULT_SHADOW_COLOR = DEFAULT_SHADOW_COLOR or `color {0x000000ff}

--macros for updating field values -------------------------------------------

change = macro(function(self, FIELD, v)
	FIELD = FIELD:asvalue()
	return quote
		var changed = (self.[FIELD] ~= v)
		if changed then
			self.[FIELD] = v
		end
		in changed
	end
end)

struct Layer;
struct Lib;

Layer.methods.invalidate = macro(function(self, WHAT)
	WHAT = WHAT:asvalue() or ''
	return quote
		escape
			for s in WHAT:gmatch'[^%s]+' do
				emit quote self:['invalidate_'..s]() end
			end
		end
	end
end)

Layer.methods.change = macro(function(self, target, FIELD, v, WHAT)
	WHAT = WHAT or ''
	return quote
		var changed = change(target, FIELD, v)
		if changed then
			self:invalidate(WHAT)
		end
		in changed
	end
end)

Layer.methods.changelen = macro(function(self, arr, len, init, WHAT)
	WHAT = WHAT or ''
	return quote
		var changed = arr.len ~= len
		if changed then
			escape
				if type(init:asvalue()) == 'terramacro' then
					emit quote
						var new_elements = arr:setlen(len)
						for _,e in new_elements do
							init(&self, e)
						end
					end
				else --init is actually the default value
					emit quote arr:setlen(len, init) end
				end
			end
			self:invalidate(WHAT)
		end
		in changed
	end
end)

--bool bitmap ----------------------------------------------------------------

struct BoolBitmap {
	bitmap: Bitmap;
}

terra BoolBitmap:init()
	self.bitmap:init(BITMAP_FORMAT_G8)
end

terra BoolBitmap:free()
	self.bitmap:free()
end

--transform ------------------------------------------------------------------

struct Transform {
	rotation: num;
	rotation_cx: num;
	rotation_cy: num;
	scale: num;
	scale_cx: num;
	scale_cy: num;
}

terra Transform:init()
	self.scale = 1
end

terra Transform:apply(m: &matrix)
	if self.rotation ~= 0 then
		m:rotate_around(self.rotation_cx, self.rotation_cy, rad(self.rotation))
	end
	if self.scale ~= 1 then
		m:scale_around(self.scale_cx, self.scale_cy, self.scale, self.scale)
	end
end

--border ---------------------------------------------------------------------

BorderLineToFunc = {&Layer, &context, num, num, num} -> {}

struct Border (gettersandsetters) {

	width_left   : num;
	width_right  : num;
	width_top    : num;
	width_bottom : num;

	corner_radius_top_left     : num;
	corner_radius_top_right    : num;
	corner_radius_bottom_left  : num;
	corner_radius_bottom_right : num;

	--draw rounded corners with a modified bezier for smoother line-to-arc
	--transitions. kappa=1 uses circle arcs instead.
	corner_radius_kappa: num;

	color_left   : color;
	color_right  : color;
	color_top    : color;
	color_bottom : color;

	dash: arr(double);
	dash_offset: num;

	-- border stroke positioning relative to box edge.
	-- -1..1 goes from inside to outside of box edge.
	offset: num;

	line_to: BorderLineToFunc;

}

terra Border:init()
	self.color_left   = DEFAULT_BORDER_COLOR
	self.color_right  = DEFAULT_BORDER_COLOR
	self.color_top    = DEFAULT_BORDER_COLOR
	self.color_bottom = DEFAULT_BORDER_COLOR
	self.corner_radius_kappa = 1.2
	self.offset = -1 --inner border
end

terra Border:free()
	self.dash:free()
end

--background -----------------------------------------------------------------

BACKGROUND_TYPE_NONE            =  0
BACKGROUND_TYPE_COLOR           =  1
BACKGROUND_TYPE_LINEAR_GRADIENT =  2
BACKGROUND_TYPE_RADIAL_GRADIENT =  3
BACKGROUND_TYPE_IMAGE           =  4

BACKGROUND_TYPE_MIN = 0
BACKGROUND_TYPE_MAX = BACKGROUND_TYPE_IMAGE

struct ColorStop {
	offset: num;
	color: color;
}

struct BackgroundGradient {
	color_stops: arr(ColorStop);
	x1: num; y1: num;
	x2: num; y2: num;
	r1: num; r2: num;
}

terra BackgroundGradient:free()
	self.color_stops:free()
end

struct BackgroundPattern {
	x: num;
	y: num;
	gradient: BackgroundGradient;
	bitmap: Bitmap;
	bitmap_surface: &surface;
	pattern: &pattern;
	transform: Transform;
	extend: enum; --BACKGROUND_EXTEND_*
}

terra BackgroundPattern:init()
	self.transform:init()
	self.extend = BACKGROUND_EXTEND_REPEAT
end

terra BackgroundPattern:free_pattern()
	if self.pattern ~= nil then
		self.pattern:free()
		self.pattern = nil
	end
end

terra BackgroundPattern:set_bitmap(w: int, h: int, format: int, stride: int, pixels: &uint8)
	if self.bitmap_surface ~= nil then
		self.bitmap_surface:free()
		self.bitmap_surface = nil
	end
	if pixels ~= nil then
		self.bitmap:free()
		self.bitmap.format = format
		self.bitmap.w = w
		self.bitmap.h = h
		self.bitmap.stride = stride
		self.bitmap.pixels = pixels
		self.bitmap.capacity = 0 --not owning the pixel buffer
	else
		self.bitmap:realloc(w, h, format, stride, 0)
	end
end

terra BackgroundPattern:free()
	self:free_pattern()
	if self.bitmap_surface ~= nil then
		self.bitmap_surface:free()
		self.bitmap_surface = nil
	end
	self.bitmap:free()
	self.gradient:free()
end

struct Background (gettersandsetters) {
	type: enum; --BACKGROUND_TYPE_*
	hittable: bool;
	operator: enum; --OPERATOR_*
	opacity: num;
	-- overlapping between background clipping edge and border stroke.
	-- -1..1 goes from inside to outside of border edge.
	clip_border_offset: num;
	color: color;
	pattern: BackgroundPattern;
}

terra Background:init()
	self.hittable = true
	self.operator = OPERATOR_OVER
	self.opacity = 1
	self.clip_border_offset = 1 --border fully overlaps the background
	self.pattern:init()
end

terra Background:free()
	self.pattern:free()
end

terra Background:get_is_gradient()
	return
		   self.type == BACKGROUND_TYPE_LINEAR_GRADIENT
		or self.type == BACKGROUND_TYPE_RADIAL_GRADIENT
end

--shadow ---------------------------------------------------------------------

struct Shadow (gettersandsetters) {
	--config
	layer: &Layer;
	offset_x: num; --relative to the shape that it is shadowing
	offset_y: num;
	color: color;
	_blur_radius: uint8;
	_blur_passes: uint8;
	_inset: bool;
	_content: bool;  --shadow the layer content vs its box
	--state
	blur: blur.Blur;
	surface: &surface;
	surface_x: num; --relative to the origin of the shadow shape
	surface_y: num;
}

terra Shadow:init(layer: &Layer)
	fill(self)
	self.layer = layer
	self.color = DEFAULT_SHADOW_COLOR
	self._blur_passes = 3
	self.blur:init(BITMAP_FORMAT_G8)
end

terra Shadow:free()
	self.blur:free()
	if self.surface ~= nil then
		self.surface:free()
		self.surface = nil
	end
end

terra Shadow:invalidate_blur()
	self.blur:invalidate()
end
Shadow.methods.invalidate_blur:setinlined(true)

Shadow.methods.invalidate = Layer.methods.invalidate
Shadow.methods.change = Layer.methods.change

terra Shadow:get_blur_radius() return self._blur_radius end
terra Shadow:get_blur_passes() return self._blur_passes end
terra Shadow:get_inset      () return self._inset       end
terra Shadow:get_content    () return self._content     end

terra Shadow:set_blur_radius(v: int)  self:change(self, '_blur_radius', v, 'blur') end
terra Shadow:set_blur_passes(v: int)  self:change(self, '_blur_passes', v, 'blur') end
terra Shadow:set_inset      (v: bool) self:change(self, '_inset'      , v, 'blur') end
terra Shadow:set_content    (v: bool) self:change(self, '_content'    , v, 'blur') end

terra Shadow:visible()
	return self.blur_radius > 0
		or self.offset_x ~= 0
		or self.offset_y ~= 0
end

terra Shadow:get_edge_size()
	return self.blur_passes * self.blur_radius
end

terra Shadow:get_spread()
	if self.inset then
		return max(abs(self.offset_x), abs(self.offset_y))
	else
		return self.edge_size
	end
end

--text -----------------------------------------------------------------------

struct Text (gettersandsetters) {
	layout: tr.Layout;
	embeds_valid: bool;
}

terra Text:init(r: &tr.Renderer)
	self.layout:init(r)
	self.embeds_valid = false
	self.layout.maxlen = 4096
end

terra Text:free()
	self.layout:free()
end

--layouting ------------------------------------------------------------------

struct LayoutSolver {
	type       : enum; --LAYOUT_TYPE_*
	axis_order : enum; --AXIS_ORDER_*
	show_text  : bool;
	sync       : {&Layer} -> {};
	sync_min_w : {&Layer, bool} -> num;
	sync_min_h : {&Layer, bool} -> num;
	sync_x     : {&Layer, bool} -> bool;
	sync_y     : {&Layer, bool} -> bool;
}

FLEX_FLOW_X = 0
FLEX_FLOW_Y = 1

FLEX_FLOW_MIN = FLEX_FLOW_X
FLEX_FLOW_MAX = FLEX_FLOW_Y

struct FlexLayout {
	flow: enum; --FLEX_FLOW_*
	wrap: bool;
}

struct GridLayoutCol (gettersandsetters) {
	x: num;
	w: num;
	fr: num;
	align_x: enum;
	_min_w: num;
}
terra GridLayoutCol:get_inlayout() return true end

struct GridLayout {
	col_frs: arr(num);
	row_frs: arr(num);
	col_gap: num;
	row_gap: num;
	flow: enum; --GRID_FLOW_* mask
	wrap: int;
	min_lines: int;

	--computed by the auto-positioning algorithm.
	_flip_rows: bool;
	_flip_cols: bool;
	_max_row: int;
	_max_col: int;
	_cols: arr(GridLayoutCol);
	_rows: arr(GridLayoutCol);
}

terra GridLayout:init()
	self.wrap = 1
	self.min_lines = 1
end

terra GridLayout:free()
	self.col_frs:free()
	self.row_frs:free()
	self._cols:free()
	self._rows:free()
end

--hit testing ----------------------------------------------------------------

struct HitTestResult {
	layer: &Layer;
	area: enum;
	x: num;
	y: num;
	text_offset: int;
	text_cursor_which: enum;
};

terra HitTestResult:set(layer: &Layer, area: enum, x: num, y: num)
	self.layer = layer
	self.area = area
	self.x = x
	self.y = y
end

--lib ------------------------------------------------------------------------

struct Lib (gettersandsetters) {
	text_renderer: tr.Renderer;
	grid_occupied: BoolBitmap;
	default_shadow: Shadow;
	hit_test_result: HitTestResult;
}

--layer ----------------------------------------------------------------------

terra Layer.methods.free :: {&Layer} -> {}

struct Layer (gettersandsetters) {

	lib: &Lib;
	_parent: &Layer;
	_pos_parent: &Layer;
	top_layer: &Layer;
	children: arr{T = &Layer, own_elements = true};

	_x: num;
	_y: num;
	_w: num;
	_h: num;
	_baseline: num;

	visible      : bool;
	operator     : enum;
	clip_content : bool;
	snap_x       : bool; --snap to pixels on x-axis
	snap_y       : bool; --snap to pixels on y-axis

	parent_has_content_shadow: bool; --one of the parents has a content shadow

	opacity: num;

	padding_left   : num;
	padding_right  : num;
	padding_top    : num;
	padding_bottom : num;

	transform  : Transform;
	border     : Border;
	background : Background;
	shadows    : arr(Shadow);
	text       : Text;

	--layouting -------------------

	layout_solver: &LayoutSolver;

	final_x: num;
	final_y: num;
	final_w: num;
	final_h: num;

	--setting this flag makes layouting set final_x,y,w,h instead of x,y,w,h
	--which allows the client to animate x,y,w,h towards final_x,y,w,h after
	--layouting and before redrawing.
	in_transition: bool;

	layout_valid: bool;
	pixels_valid: bool;

	--flex & grid layout
	align_items_x: enum;  --ALIGN_*
	align_items_y: enum;  --ALIGN_*
 	item_align_x: enum;   --ALIGN_* when parent's align_items_x == ALIGN_STRETCH
	item_align_y: enum;   --ALIGN_* when parent's align_items_y == ALIGN_STRETCH
	flex: FlexLayout;
	grid: GridLayout;

	--child of flex & grid layout
	_min_w: num;
	_min_h: num;
	min_cw: num; --min client width
	min_ch: num; --min client height
	align_x: enum; --ALIGN_*
	align_y: enum; --ALIGN_*

	--child of flex layout
	fr: num;
	break_before: bool;
	break_after : bool;

	--child of grid layout
	grid_col: int;
	grid_row: int;
	grid_col_span: int;
	grid_row_span: int;
	--computed by the auto-positioning algorithm.
	_grid_col: int;
	_grid_row: int;
	_grid_col_span: int;
	_grid_row_span: int;

	--hit testing -----------------

	hit_test_mask: enum;
}

terra Layer.methods.invalidate_layout                          :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_layout                   :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_layout_ignore_pos_parent :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_layout_ignore_visible    :: {&Layer} -> {}
terra Layer.methods.invalidate_pixels                          :: {&Layer} -> {}
terra Layer.methods.invalidate_background                      :: {&Layer} -> {}
terra Layer.methods.invalidate_text                            :: {&Layer} -> {}
terra Layer.methods.invalidate_box_shadows                     :: {&Layer} -> {}
terra Layer.methods.invalidate_content_shadows                 :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_content_shadows          :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_content_shadows_force    :: {&Layer} -> {}
terra Layer.methods.invalidate_embeds                          :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_embeds                   :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_embeds_ignore_pos_parent :: {&Layer} -> {}
terra Layer.methods.invalidate_parent_embeds_ignore_visible    :: {&Layer} -> {}

terra Layer.methods.init_layout  :: {&Layer} -> {}
terra Layer.methods.content_bbox :: {&Layer, bool} -> {num, num, num, num}
terra Layer.methods.draw_content :: {&Layer, &context, bool} -> {}

terra Layer:init(lib: &Lib, parent: &Layer)
	fill(self)
	self.lib = lib
	self._parent = parent
	self.top_layer = iif(parent ~= nil, parent.top_layer, self)

	self.visible = true
	self.operator = OPERATOR_OVER
	self.opacity = 1
	self.snap_x = true
	self.snap_y = true

	self.transform:init()
	self.border:init()
	self.background:init()
	self.text:init(&lib.text_renderer)

	self.align_items_x = ALIGN_STRETCH
	self.align_items_y = ALIGN_STRETCH
 	self.item_align_x  = ALIGN_STRETCH
	self.item_align_y  = ALIGN_STRETCH
	self.fr = 1

	self.grid:init()
	self.grid_col_span = 1
	self.grid_row_span = 1

	self:init_layout()
end

--a layer's parent children array is the owner of its child layers so this
--is called automatically when a layer is removed from that array by any means.
terra Layer:free()
	self.children:free()
	self.border:free()
	self.background:free()
	self.shadows:free()
	self.text:free()
	self.grid:free()
	dealloc(self)
end

terra Layer:get_parent() return self._parent end
terra Layer:get_pos_parent() return self._pos_parent end

terra Layer:get_index()
	return iif(self.parent ~= nil, self.parent.children:find(self), 0)
end

terra Layer:is_child_of(e: &Layer)
	while self.parent ~= e do
		self = self.parent
		if self == nil then
			return false
		end
	end
	return true
end

terra Layer:is_pos_child_of(e: &Layer)
	while self.pos_parent ~= e do
		self = self.pos_parent
		if self == nil then
			return false
		end
	end
	return true
end

terra Layer:move(parent: &Layer, i: int)
	if parent == self.parent then
		if parent == nil then
			return false
		end
		i = parent.children:clamp(i)
		var i0 = self.index
		if i0 == i then
			return false
		end
		parent.children:move(i0, i)
		self:invalidate'pixels parent_layout parent_embeds parent_content_shadows'
	else
		if parent ~= nil and (parent == self or parent:is_child_of(self)) then
			return false
		end
		--invalidate things in the old hierarchy...
		self:invalidate'pixels parent_layout parent_embeds parent_content_shadows'
		if self.parent ~= nil then
			self.parent.children:leak(self.index)
		end
		if parent ~= nil then
			i = clamp(i, 0, parent.children.len)
			parent.children:insert(i, self)
		end
		self._parent = parent
		self.top_layer = iif(parent ~= nil, parent.top_layer, self)
		--invalidate things in the new hierarchy...
		self:invalidate'pixels parent_layout parent_embeds parent_content_shadows_force'
	end
	return true
end

terra Layer:set_pos_parent(pos_parent: &Layer)
	if pos_parent == self.pos_parent then return end
	if pos_parent == self then return end
	if pos_parent ~= nil and pos_parent:is_pos_child_of(self) then return end
	if self.pos_parent == nil or pos_parent == nil then --got in or out of layout
		self:invalidate'parent_layout_ignore_pos_parent parent_embeds_ignore_pos_parent'
	end
	self._pos_parent = pos_parent
	self:invalidate'pixels parent_content_shadows'
end

Layer.metamethods.__for = function(self, body)
	return quote
		var children = self.children --workaround for terra issue #368
		for i = 0, children.len do
			[ body(`children(i)) ]
		end
	end
end

terra Layer:child(i: int)
	return self.children(i)
end

--layer geometry -------------------------------------------------------------

terra Layer:get_px() return self.padding_left end
terra Layer:get_py() return self.padding_top end
terra Layer:get_pw() return self.padding_left + self.padding_right end
terra Layer:get_ph() return self.padding_top + self.padding_bottom end

terra Layer:get_x() return self._x end
terra Layer:get_y() return self._y end
terra Layer:get_w() return self._w end
terra Layer:get_h() return self._h end

terra Layer:set_x(x: num)
	if self.in_transition then
		self.final_x = x
	else
		self:change(self, '_x', x, 'pixels parent_content_shadows')
	end
end
terra Layer:set_y(y: num)
	if self.in_transition then
		self.final_y = y
	else
		self:change(self, '_y', y, 'pixels parent_content_shadows')
	end
end

terra Layer:set_w(w: num)
	w = max(w, 0)
	if self.in_transition then
		self.final_w = w
	else
		self:change(self, '_w', w, 'pixels box_shadows parent_embeds parent_content_shadows')
	end
end
terra Layer:set_h(h: num)
	h = max(h, 0)
	if self.in_transition then
		self.final_h = h
	else
		self:change(self, '_h', h, 'pixels box_shadows parent_embeds parent_content_shadows')
	end
end

terra Layer:get_cx() return self.x + self.px end --in parent's content space
terra Layer:get_cy() return self.y + self.py end
terra Layer:get_cw() return self.w - self.pw end
terra Layer:get_ch() return self.h - self.ph end

terra Layer:set_cx(cx: num) self.x = cx - self.w / 2 end
terra Layer:set_cy(cy: num) self.y = cy - self.h / 2 end
terra Layer:set_cw(cw: num) self.w = cw + (self.w - self.cw) end
terra Layer:set_ch(ch: num) self.h = ch + (self.h - self.ch) end

--layer relative geometry & matrix -------------------------------------------

terra Layer:rel_matrix() --box matrix relative to parent's content space
	var m: matrix; m:init()
	m:translate(self.x, self.y)
	self.transform:apply(&m)
	return m
end

terra Layer:abs_matrix(): matrix --box matrix in window space
	var parent = iif(self.pos_parent ~= nil, self.pos_parent, self.parent)
	var am: matrix
	if parent ~= nil then
		am = parent:abs_matrix()
		am:translate(parent.px, parent.py)
	else
		am = [matrix.identity]
	end
	var rm = self:rel_matrix()
	am:transform(&rm)
	return am
end

terra Layer:abs_matrix_from(m: matrix)
	if self.pos_parent ~= nil then
		return self:abs_matrix()
	else
		var m = m:copy()
		var r = self:rel_matrix()
		m:transform(&r)
		return m
	end
end

--convert point from own box space to parent content space.
terra Layer:from_box_to_parent(x: num, y: num)
	if self.pos_parent ~= nil then
		var x, y = self:abs_matrix():point(x, y)
		return self.parent:from_window(x, y)
	else
		var m = self:rel_matrix()
		return m:point(x, y)
	end
end

--convert point from parent content space to own box space.
terra Layer:from_parent_to_box(x: num, y: num)
	if self.pos_parent ~= nil then
		var m = self:abs_matrix()
		m:invert()
		var x, y = self.parent:to_window(x, y)
		return m:point(x, y)
	else
		var m = self:rel_matrix(); m:invert()
		return m:point(x, y)
	end
end

--convert point from own content space to parent content space.
terra Layer:to_parent(x: num, y: num)
	if self.pos_parent ~= nil then
		var m = self:abs_matrix()
		m:translate(self.px, self.py)
		var x, y = m:point(x, y)
		return self.parent:from_window(x, y)
	else
		var m = self:rel_matrix()
		m:translate(self.px, self.py)
		return m:point(x, y)
	end
end

--convert point from parent content space to own content space.
terra Layer:from_parent(x: num, y: num)
	if self.pos_parent ~= nil then
		var m = self:abs_matrix()
		m:translate(self.px, self.py)
		m:invert()
		var x, y = self.parent:to_window(x, y)
		return m:point(x, y)
	else
		var m = self:rel_matrix()
		m:translate(self.px, self.py)
		m:invert()
		return m:point(x, y)
	end
end

terra Layer:to_window(x: num, y: num): {num, num} --parent & child interface
	var x, y = self:to_parent(x, y)
	if self.parent ~= nil then
		return self.parent:to_window(x, y)
	else
		return x, y
	end
end

terra Layer:from_window(x: num, y: num): {num, num} --parent & child interface
	if self.parent ~= nil then
		x, y = self.parent:from_window(x, y)
	end
	return self:from_parent(x, y)
end

--content-box geometry, drawing and hit testing ------------------------------

--convert point from own box space to own content space.
terra Layer:to_content(x: num, y: num)
	return x - self.px, y - self.py
end

--content point from own content space to own box space.
terra Layer:from_content(x: num, y: num)
	return self.px + x, self.py + y
end

--border geometry and drawing ------------------------------------------------

--border edge widths relative to box rect at %-offset in border width.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
--returned widths are positive when inside and negative when outside box rect.
terra Border:edge_widths(offset: num, max_w: num, max_h: num)
	var o = self.offset + offset + 1
	var w1 = lerp(o, -1, 1, self.width_left,   0)
	var h1 = lerp(o, -1, 1, self.width_top,    0)
	var w2 = lerp(o, -1, 1, self.width_right,  0)
	var h2 = lerp(o, -1, 1, self.width_bottom, 0)
	--adjust overlapping widths by scaling them down proportionally.
	if w1 + w2 > max_w or h1 + h2 > max_h then
		var scale = min(max_w / (w1 + w2), max_h / (h1 + h2))
		w1 = w1 * scale
		h1 = h1 * scale
		w2 = w2 * scale
		h2 = h2 * scale
	end
	return w1, h1, w2, h2
end

--border rect at %-offset in border width.
terra Layer:border_rect(offset: num, size_offset: num)
	var w1, h1, w2, h2 = self.border:edge_widths(offset, self.w, self.h)
	var w = self.w - w2 - w1
	var h = self.h - h2 - h1
	return rect.offset(size_offset, w1, h1, w, h)
end

--corner radius at pixel offset from the stroke's center on one dimension.
local terra offset_radius(r: num, o: num)
	return iif(r > 0, max(num(0), r + o), num(0))
end

--border rect at %-offset in border width, plus radii of rounded corners.
terra Layer:border_round_rect(offset: num, size_offset: num)

	var k = self.border.corner_radius_kappa

	var x1, y1, w, h = self:border_rect(0, 0) --at stroke center
	var X1, Y1, W, H = self:border_rect(offset, size_offset) --at offset

	var x2, y2 = x1 + w, y1 + h
	var X2, Y2 = X1 + W, Y1 + H

	var r1 = self.border.corner_radius_top_left
	var r2 = self.border.corner_radius_top_right
	var r3 = self.border.corner_radius_bottom_right
	var r4 = self.border.corner_radius_bottom_left

	--offset the radii to preserve curvature at offset.
	var r1x = offset_radius(r1, x1-X1)
	var r1y = offset_radius(r1, y1-Y1)
	var r2x = offset_radius(r2, X2-x2)
	var r2y = offset_radius(r2, y1-Y1)
	var r3x = offset_radius(r3, X2-x2)
	var r3y = offset_radius(r3, Y2-y2)
	var r4x = offset_radius(r4, x1-X1)
	var r4y = offset_radius(r4, Y2-y2)

	--remove degenerate arcs.
	if r1x == 0 or r1y == 0 then r1x = 0; r1y = 0 end
	if r2x == 0 or r2y == 0 then r2x = 0; r2y = 0 end
	if r3x == 0 or r3y == 0 then r3x = 0; r3y = 0 end
	if r4x == 0 or r4y == 0 then r4x = 0; r4y = 0 end

	--adjust overlapping radii by scaling them down proportionally.
	var maxx = max(r1x + r2x, r3x + r4x)
	var maxy = max(r1y + r4y, r2y + r3y)
	if maxx > W or maxy > H then
		var scale = min(W / maxx, H / maxy)
		r1x = r1x * scale
		r1y = r1y * scale
		r2x = r2x * scale
		r2y = r2y * scale
		r3x = r3x * scale
		r3y = r3y * scale
		r4x = r4x * scale
		r4y = r4y * scale
	end

	return
		X1, Y1, W, H,
		r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y,
		k
end

--De Casteljau split of a cubic bezier at time t (from path2d).
local terra bezier_split(
	first: bool, t: num,
	x1: num, y1: num,
	x2: num, y2: num,
	x3: num, y3: num,
	x4: num, y4: num
)
	var mt = 1-t
	var x12 = x1 * mt + x2 * t
	var y12 = y1 * mt + y2 * t
	var x23 = x2 * mt + x3 * t
	var y23 = y2 * mt + y3 * t
	var x34 = x3 * mt + x4 * t
	var y34 = y3 * mt + y4 * t
	var x123 = x12 * mt + x23 * t
	var y123 = y12 * mt + y23 * t
	var x234 = x23 * mt + x34 * t
	var y234 = y23 * mt + y34 * t
	var x1234 = x123 * mt + x234 * t
	var y1234 = y123 * mt + y234 * t
	if first then
		return x1, y1, x12, y12, x123, y123, x1234, y1234 --first curve
	else
		return x1234, y1234, x234, y234, x34, y34, x4, y4 --second curve
	end
end

local kappa = 4 / 3 * (sqrt(2) - 1)

--more-aesthetically-pleasing elliptic arc. only for 45deg and 90deg sweeps!
local terra bezier_qarc(cr: &context, cx: num, cy: num, rx: num, ry: num, q1: num, qlen: num, k: num)
	cr:save()
	cr:translate(cx, cy)
	cr:scale(rx / ry, 1)
	cr:rotate(floor(min(q1, q1 + qlen) - 2) * PI / 2)
	var r = ry
	var k = r * kappa * k
	var x1, y1, x2, y2, x3, y3, x4, y4 = 0, -r, k, -r, r, -k, r, 0
	if qlen < 0 then --reverse curve
		x1, y1, x2, y2, x3, y3, x4, y4 = x4, y4, x3, y3, x2, y2, x1, y1
		qlen = abs(qlen)
	end
	if qlen ~= 1 then
		assert(qlen == .5)
		var first = q1 == floor(q1)
		x1, y1, x2, y2, x3, y3, x4, y4 =
			bezier_split(first, qlen, x1, y1, x2, y2, x3, y3, x4, y4)
	end
	cr:line_to(x1, y1)
	cr:curve_to(x2, y2, x3, y3, x4, y4)
	cr:restore()
end

--draw a rounded corner: q1 is the quadrant starting top-left going clockwise.
--qlen is in 90deg units and can only be +/- .5 or 1 if k ~= 1.
terra Layer:corner_path(cr: &context, cx: num, cy: num, rx: num, ry: num, q1: num, qlen: num, k: num)
	if rx == 0 or ry == 0 then --null arcs need a line to the first endpoint
		assert(rx == 0 and ry == 0)
		cr:line_to(cx, cy)
	elseif k == 1 then --geometrically-correct elliptic arc
		var q2 = q1 + qlen
		var a1 = (q1 - 3) * PI / 2
		var a2 = (q2 - 3) * PI / 2
		if a1 < a2 then
			cr:elliptic_arc(cx, cy, rx, ry, 0, a1, a2)
		else
			cr:elliptic_arc_negative(cx, cy, rx, ry, 0, a1, a2)
		end
	else
		bezier_qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	end
end

terra Layer:border_line_to(cr: &context, x: num, y: num, q: num)
	if self.border.line_to ~= nil then
		self.border.line_to(self, cr, x, y, q)
	end
end

--trace the border contour path at offset.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
terra Layer:border_path(cr: &context, offset: num, size_offset: num)
	var x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(offset, size_offset)
	var x2, y2 = x1 + w, y1 + h
	cr:move_to(x1, y1+r1y)
	self:corner_path    (cr, x1+r1x, y1+r1y, r1x, r1y, 1, 1, k) --tl
	self:border_line_to (cr, x2-r2x, y1, 1)
	self:corner_path    (cr, x2-r2x, y1+r2y, r2x, r2y, 2, 1, k) --tr
	self:border_line_to (cr, x2, y2-r3y, 2)
	self:corner_path    (cr, x2-r3x, y2-r3y, r3x, r3y, 3, 1, k) --br
	self:border_line_to (cr, x1+r4x, y2, 3)
	self:corner_path    (cr, x1+r4x, y2-r4y, r4x, r4y, 4, 1, k) --bl
	self:border_line_to (cr, x1, y1+r1y, 4)
	cr:close_path()
end

terra Layer:border_visible()
	return
		   self.border.width_left   ~= 0
		or self.border.width_top    ~= 0
		or self.border.width_right  ~= 0
		or self.border.width_bottom ~= 0
end

terra Layer:border_opaque()
	return
		    self.border.width_left   ~= 0
		and self.border.width_top    ~= 0
		and self.border.width_right  ~= 0
		and self.border.width_bottom ~= 0
		and self.border.color_left  .alpha == 255
		and self.border.color_top   .alpha == 255
		and self.border.color_right .alpha == 255
		and self.border.color_bottom.alpha == 255
end

terra Layer:draw_border(cr: &context)
	if not self:border_visible() then return end

	cr:operator(self.operator)

	--seamless drawing when all side colors are the same.
	if self.border.color_left.uint == self.border.color_top.uint
		and self.border.color_left.uint == self.border.color_right.uint
		and self.border.color_left.uint == self.border.color_bottom.uint
	then
		cr:new_path()
		cr:rgba(self.border.color_bottom)
		if self.border.width_left == self.border.width_top
			and self.border.width_left == self.border.width_right
			and self.border.width_left == self.border.width_bottom
		then --stroke-based drawing (doesn't require path offseting; supports dashing)
			self:border_path(cr, 0, 0)
			cr:line_width(self.border.width_left)
			cr:dash(
				self.border.dash.elements,
				self.border.dash.len,
				self.border.dash_offset)
			cr:stroke()
		else --fill-based drawing (requires path offsetting; supports patterns)
			cr:fill_rule(CAIRO_FILL_RULE_EVEN_ODD)
			self:border_path(cr, -1, 0)
			self:border_path(cr,  1, 0)
			cr:fill()
		end
		return
	end

	--complicated drawing of each side separately.
	--still shows seams on adjacent sides of the same color.
	var x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(-1, 0)
	var X1, Y1, W, H, R1X, R1Y, R2X, R2Y, R3X, R3Y, R4X, R4Y, K =
		self:border_round_rect( 1, 0)

	var x2, y2 = x1 + w, y1 + h
	var X2, Y2 = X1 + W, Y1 + H

	if self.border.color_left.alpha > 0 then
		cr:new_path()
		cr:move_to(x1, y1+r1y)
		self:corner_path(cr, x1+r1x, y1+r1y, r1x, r1y, 1, .5, k)
		self:corner_path(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 1.5, -.5, K)
		cr:line_to(X1, Y2-R4Y)
		self:corner_path(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 5, -.5, K)
		self:corner_path(cr, x1+r4x, y2-r4y, r4x, r4y, 4.5, .5, k)
		cr:close_path()
		cr:rgba(self.border.color_left)
		cr:fill()
	end

	if self.border.color_top.alpha > 0 then
		cr:new_path()
		cr:move_to(x2-r2x, y1)
		self:corner_path(cr, x2-r2x, y1+r2y, r2x, r2y, 2, .5, k)
		self:corner_path(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 2.5, -.5, K)
		cr:line_to(X1+R1X, Y1)
		self:corner_path(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 2, -.5, K)
		self:corner_path(cr, x1+r1x, y1+r1y, r1x, r1y, 1.5, .5, k)
		cr:close_path()
		cr:rgba(self.border.color_top)
		cr:fill()
	end

	if self.border.color_right.alpha > 0 then
		cr:new_path()
		cr:move_to(x2, y2-r3y)
		self:corner_path(cr, x2-r3x, y2-r3y, r3x, r3y, 3, .5, k)
		self:corner_path(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 3.5, -.5, K)
		cr:line_to(X2, Y1+R2Y)
		self:corner_path(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 3, -.5, K)
		self:corner_path(cr, x2-r2x, y1+r2y, r2x, r2y, 2.5, .5, k)
		cr:close_path()
		cr:rgba(self.border.color_right)
		cr:fill()
	end

	if self.border.color_bottom.alpha > 0 then
		cr:new_path()
		cr:move_to(x1+r4x, y2)
		self:corner_path(cr, x1+r4x, y2-r4y, r4x, r4y, 4, .5, k)
		self:corner_path(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 4.5, -.5, K)
		cr:line_to(X2-R3X, Y2)
		self:corner_path(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 4, -.5, K)
		self:corner_path(cr, x2-r3x, y2-r3y, r3x, r3y, 3.5, .5, k)
		cr:close_path()
		cr:rgba(self.border.color_bottom)
		cr:fill()
	end
end

--background drawing ---------------------------------------------------------

terra Layer:background_visible()
	return self.background.type ~= BACKGROUND_TYPE_NONE
		and self.background.opacity > 0
end

terra Layer:background_opaque()
	if self.background.type == BACKGROUND_TYPE_NONE then
		return false
	end
	if self.background.type == BACKGROUND_TYPE_COLOR then
		return self.background.opacity >= 1
			and self.background.color.alpha == 255
	end
	return false --hard to check transparency on gradients and images.
end

terra Layer:background_rect(size_offset: num)
	return self:border_rect(self.background.clip_border_offset, size_offset)
end

terra Layer:background_round_rect(size_offset: num)
	return self:border_round_rect(self.background.clip_border_offset, size_offset)
end

terra Layer:background_path(cr: &context, size_offset: num)
	self:border_path(cr, self.background.clip_border_offset, size_offset)
end

terra Layer:invalidate_background()
	self.background.pattern:free_pattern()
end

terra Background:pattern()
	var p = &self.pattern
	if p.pattern == nil then
		if    self.type == BACKGROUND_TYPE_LINEAR_GRADIENT
			or self.type == BACKGROUND_TYPE_RADIAL_GRADIENT
		then
			var g = p.gradient
			if self.type == BACKGROUND_TYPE_LINEAR_GRADIENT then
				p.pattern = cairo_pattern_create_linear(g.x1, g.y1, g.x2, g.y2)
			else
				p.pattern = cairo_pattern_create_radial(g.x1, g.y1, g.r1, g.x2, g.y2, g.r2)
			end
			for _,c in g.color_stops do
				p.pattern:add_color_stop_rgba(c.offset, c.color)
			end
		elseif self.type == BACKGROUND_TYPE_IMAGE then
			if p.bitmap.format ~= BITMAP_FORMAT_INVALID then
				if p.bitmap_surface == nil then
					p.bitmap_surface = p.bitmap:surface()
				end
				p.pattern = cairo_pattern_create_for_surface(p.bitmap_surface)
			end
		end
	end
	return p.pattern
end

terra Background:paint(cr: &context)
	cr:operator(self.operator)
	if self.type == BACKGROUND_TYPE_COLOR then
		cr:rgba(self.color)
		cr:paint_with_alpha(self.opacity)
	else
		var m: matrix; m:init()
		m:translate(self.pattern.x, self.pattern.y)
		self.pattern.transform:apply(&m)
		m:invert()
		var patt = self:pattern()
		if patt ~= nil then
			patt:matrix(&m)
			patt:extend(self.pattern.extend)
			cr:source(patt)
			cr:paint_with_alpha(self.opacity)
			cr:rgb(0, 0, 0) --release source
		end
	end
end

terra Layer:paint_background(cr: &context)
	self.background:paint(cr)
end

--shadow drawing -------------------------------------------------------------

terra Shadow:bitmap_rect()
	if self.content then
		var x, y, w, h = self.layer:content_bbox(true)
		return rect.offset(self.spread, x, y, w, h)
	else
		if self.layer:border_visible() then
			return self.layer:border_rect(iif(self.inset, -1, 1), self.spread)
		else
			return self.layer:background_rect(self.spread)
		end
	end
end

terra Shadow:path(cr: &context)
	if self.layer:border_visible() then
		self.layer:border_path(cr, iif(self.inset, -1, 1), 0)
	else
		self.layer:background_path(cr, 0)
	end
end

--check if the layer has a closed path inside which no pixel is transparent
--and if it does, generate that path and return true.
terra Layer:opaque_path(cr: &context)
	if self:background_opaque() then
		if self:border_opaque() then
			self:border_path(cr, 1, 0)
			return true
		else
			self:background_path(cr, 0)
			return true
		end
	end
	return false
end

--the content-shadow of a layer with an opaque background and with clipped
--content is equivalent to the content-shadow of a layer with no content
--so there's no point drawing the content in this case to make the shadow.
terra Layer:content_casts_own_shadow()
	return not (self.clip_content and self:background_opaque())
end

local terra invert_path(cr: &context)
	cr:fill_rule(CAIRO_FILL_RULE_EVEN_ODD)
	var m = cr:matrix()
	cr:identity_matrix()
	cr:rectangle(0, 0, cr:target():width(), cr:target():height())
	cr:matrix(&m)
end

terra Shadow:clip_path(cr: &context)
	if not (self.content or self.inset) then
		--if the layer has an opaque path, clip the shadow by that path
		--to speed up painting it, since that's the bulk of it.
		if self.layer:opaque_path(cr) then
			invert_path(cr)
			return true
		end
	end
	return false
end

terra Shadow:draw_shape(cr: &context)
	cr:new_path()
	self:path(cr)
	if self.inset then
		invert_path(cr)
	end
	cr:operator(CAIRO_OPERATOR_SOURCE)
	cr:rgba(0, 0, 0, 1)
	cr:fill()
end

terra Shadow:draw(cr: &context)
	var content_shadow_updated = false
	if not self.blur.valid then
		if not self:visible() then return end
		var bx, by, bw, bh = self:bitmap_rect()
		if not (bw > 0 and bh > 0) then return end
		self.surface_x = bx
		self.surface_y = by
		var src_bmp = self.blur:invalidate(bw, bh, self.blur_radius, self.blur_passes)
		if src_bmp ~= nil then
			var mask_bmp: Bitmap
			var mask_sr: &surface = nil
			var sr = src_bmp:surface()
			var cr = sr:context()
			cr:translate(-self.surface_x, -self.surface_y)
			cr:operator(CAIRO_OPERATOR_SOURCE)
			cr:rgba(0, 0, 0, 0)
			cr:paint()
			if self.content then
				self.layer:draw_content(cr, true)
				if self.inset then
					sr:flush()
					mask_bmp = src_bmp:copy()
					mask_sr = mask_bmp:surface()
					cr:operator(CAIRO_OPERATOR_XOR)
					cr:rgba(1, 1, 1, 1)
					cr:paint()
				end
				content_shadow_updated = true
			else
				self:draw_shape(cr)
			end
			cr:free()
			sr:free()

			var dst_bmp = self.blur:blur()
			if self.surface ~= nil then
				self.surface:free()
			end
			self.surface = dst_bmp:surface()

			if mask_sr ~= nil then
				var cr = self.surface:context()
				cr:translate(-self.offset_x, -self.offset_y)
				cr:operator(CAIRO_OPERATOR_DEST_IN)
				cr:source(mask_sr, 0, 0)
				cr:paint()
				cr:free()
				mask_sr:free()
				mask_bmp:free()
			end
		end
	end

	var sx = self.surface_x + self.offset_x
	var sy = self.surface_y + self.offset_y
	cr:save()
	cr:new_path()
	if self:clip_path(cr) then
		cr:clip()
	end
	cr:rgba(self.color)
	cr:operator(self.layer.operator)
	cr:mask(self.surface, sx, sy)
	cr:restore()

	if content_shadow_updated then
		self.layer:update_parent_has_content_shadow_flag(true)
	end
end

terra Layer:draw_shadows(cr: &context, inset: bool, content: bool)
	for _,s in self.shadows do
		if s.content == content and s.inset == inset then
			s:draw(cr)
		end
	end
end
terra Layer:draw_inset_content_shadows(cr: &context)
	self:draw_shadows(cr, true, true)
end
terra Layer:draw_outset_content_shadows(cr: &context)
	self:draw_shadows(cr, false, true)
end
terra Layer:draw_inset_box_shadows(cr: &context)
	self:draw_shadows(cr, true, false)
end
terra Layer:draw_outset_box_shadows(cr: &context)
	self:draw_shadows(cr, false, false)
end

terra Layer:update_parent_has_content_shadow_flag(v: bool): {}
	for e in self do
		e.parent_has_content_shadow = v
		e:update_parent_has_content_shadow_flag(v)
	end
end

terra Layer:invalidate_box_shadows()
	for _,s in self.shadows do
		if not s.content then
			s:invalidate_blur()
		end
	end
end

terra Layer:invalidate_content_shadows()
	for _,s in self.shadows do
		if s.content then
			s:invalidate_blur()
		end
	end
end

terra Layer:invalidate_pcs(force: bool)
	if self.visible and (force or self.parent_has_content_shadow) then
		repeat
			self.parent:invalidate_content_shadows()
			self = self.parent
		until not self.parent_has_content_shadow
		--all content shadows up the tree were invalidated so we can
		--relieve children from having to check their parents again.
		--this should speed up deserialization of large hierarchies.
		self:update_parent_has_content_shadow_flag(false)
	end
end

terra Layer:invalidate_parent_content_shadows      () self:invalidate_pcs(false) end
terra Layer:invalidate_parent_content_shadows_force() self:invalidate_pcs(true) end

--text drawing & hit testing -------------------------------------------------

terra Layer:get_show_text()
	return self.layout_solver.show_text
end

terra Layer:invalidate_text()
	if not self.text.layout.min_size_valid then
		self:invalidate'parent_layout'
	elseif not self.text.layout.align_valid then
		self.text.layout:align()
	end
	if not self.text.layout.pixels_valid then
		self:invalidate'pixels content_shadows parent_content_shadows'
	end
end

terra Layer:sync_text_shape()
	self.text.layout:shape()
end

terra Layer:sync_text_wrap()
	self.text.layout.align_w = self.cw
	self.text.layout:wrap()
end

terra Layer.methods.set_baseline :: {&Layer, num} -> {}

terra Layer:sync_text_align()
	self.text.layout.align_h = self.ch
	self.text.layout:align()
	self.baseline = self.text.layout.baseline
end

terra Layer:get_text_laid_out()
	return self.text.layout.align_valid
end

terra Layer:draw_text(cr: &context, for_shadow: bool)
	if self.show_text and self.text.layout.visible then
		var x1, y1, x2, y2 = cr:clip_extents()
		self.text.layout:set_clip_extents(x1, y1, x2, y2)
		self.text.layout:clip()
		self.text.layout:paint(cr, for_shadow)
	end
end

terra Layer:text_bbox(): {num, num, num, num} --for float->double conversion!
	return iif(self.show_text, self.text.layout:bbox(), {0.0, 0.0, 0.0, 0.0})
end

terra Layer:hit_test_text(cr: &context, x: num, y: num)
	if self.show_text and self.text.layout.visible then
		self.lib.hit_test_result:set(self, HIT_TEXT, x, y)
		return true
	else
		return false
	end
end

--[[
terra Layer:make_visible_text_cursor()
	local segs = self.text.segments
	local lines = segs.lines
	local sx, sy = lines.x, lines.y
	local cw, ch = self:client_size()
	local x, y, w, h = self:text_cursor_visibility_rect()
	lines.x, lines.y = box2d.scroll_to_view(x-sx, y-sy, w, h, cw, ch, sx, sy)
	self:make_visible(self:text_cursor_visibility_rect())
end
]]

--embed geometry, drawing and invalidation -----------------------------------

terra Layer:get_baseline()
	return self._baseline
end

terra Layer:set_baseline(v: num)
	self:change(self, '_baseline', v, 'parent_embeds')
end

terra Layer:get_ascent()
	return -self.baseline
end

terra Layer:get_descent()
	return -(self.h - self.baseline)
end

terra Layer:get_advance_x()
	return self.w
end

local terra text_embed_draw(cr: &context, x: num, y: num, layout: &tr.Layout,
	embed_index: int, embed: &tr.Embed, span: &tr.Span, for_shadow: bool
)
	var text = structptr(layout, Text, 'layout')
	var self = structptr(text, Layer, 'text')
	var layer = self.children(embed_index, nil)
	if layer == nil then return end
	cr:save()
	cr:translate(x, y - layer.baseline - layer.py)
	layer:draw(cr, for_shadow)
	cr:restore()
end

terra Layer:get_inlayout()
	return self.visible and self.pos_parent == nil
end

terra Layer:invalidate_embeds()
	self.text.embeds_valid = false
end

terra Layer:invalidate_parent_embeds()
	if self.parent ~= nil and self.parent.show_text and self.inlayout then
		self.parent.text.embeds_valid = false
	end
end

terra Layer:invalidate_parent_embeds_ignore_pos_parent()
	if self.parent ~= nil and self.parent.show_text and self.visible then
		self.parent.text.embeds_valid = false
	end
end

terra Layer:invalidate_parent_embeds_ignore_visible()
	if self.parent ~= nil and self.parent.show_text and self.pos_parent == nil then
		self.parent.text.embeds_valid = false
	end
end

terra Layer:sync_text_embeds()
	if not self.text.embeds_valid then
		self.text.layout.embed_count = self.children.len
		for i,layer in self.children do
			var layer = @layer
			var inlayout = layer.inlayout
			self.text.layout:set_embed_advance_x(i, iif(inlayout, layer.advance_x, 0))
			self.text.layout:set_embed_ascent   (i, iif(inlayout, layer.ascent   , 0))
			self.text.layout:set_embed_descent  (i, iif(inlayout, layer.descent  , 0))
		end
		self.text.embeds_valid = true
	end
end

--layer bbox -----------------------------------------------------------------

terra Layer:content_bbox(strict: bool) --in self content space
	var bb = rect{0, 0, 0, 0}
	for layer in self do
		bb:bbox(rect(layer:bbox(strict)))
	end
	bb:bbox(rect(self:text_bbox()))
	return bb()
end

terra Layer:bbox(strict: bool) --in parent's content space
	var bb = rect{0, 0, 0, 0}
	if self.visible then
		if strict or not self.clip_content then
			var cbb = rect(self:content_bbox(strict))
			inc(cbb.x, self.cx)
			inc(cbb.y, self.cy)
			if self.clip_content then
				cbb:intersect(rect(self:background_rect(0)))
			end
			bb:bbox(cbb)
		end
		if not strict and self.clip_content
			or self.background.hittable
			or self:background_visible()
		then
			bb:bbox(rect(self:background_rect(0)))
		end
		if self:border_visible() then
			bb:bbox(rect(self:border_rect(1, 0)))
		end
		inc(bb.x, self.x)
		inc(bb.y, self.y)
	end
	return bb()
end

--children drawing & hit testing ---------------------------------------------

terra Layer.methods.draw :: {&Layer, &context, bool} -> {}
terra Layer.methods.hit_test :: {&Layer, &context, num, num, enum} -> bool

terra Layer:draw_children(cr: &context, for_shadow: bool) --called in own content space
	for e in self do
		e:draw(cr, for_shadow)
	end
end

terra Layer:hit_test_children(cr: &context, x: num, y: num, reason: enum) --called in content space
	for i = self.children.len-1, -1, -1 do
		if self.children(i):hit_test(cr, x, y, reason) then
			return true
		end
	end
	return false
end

--content drawing & hit testing ----------------------------------------------

terra Layer:draw_content(cr: &context, for_shadow: bool) --called in own content space
	if self.layout_solver.show_text then
		self:draw_text(cr, for_shadow)
	else
		self:draw_children(cr, for_shadow)
	end
end

terra Layer:hit_test_content(cr: &context, x: num, y: num, reason: enum)
	if self:hit_test_text(cr, x, y) then
		return true
	else
		return self:hit_test_children(cr, x, y, reason)
	end
end

--layer drawing & hit testing ------------------------------------------------

local terra snapx(x: num, enable: bool)
	return iif(enable, floor(x + .5), x)
end
terra Layer:snap_matrix(m: &matrix)
	if m.xy == 0 and m.yx == 0 and m.xx == 1 and m.yy == 1 then
		m.x0 = snapx(m.x0, self.snap_x)
		m.y0 = snapx(m.y0, self.snap_y)
	end
end

terra Layer:draw(cr: &context, for_shadow: bool) --called in parent's content space

	if not self.visible or self.opacity <= 0 then
		return
	end

	var compose = self.opacity < 1
	if compose then
		cr:push_group()
	else
		cr:save()
	end

	var bm = self:abs_matrix_from(cr:matrix())
	var cm = bm:copy()
	cm:translate(self.px, self.py)

	self:snap_matrix(&bm)
	self:snap_matrix(&cm)

	cr:matrix(&bm)

	self:draw_outset_box_shadows(cr)

	if self:background_visible() then
		cr:save()
		cr:new_path()
		self:background_path(cr, 0)
		cr:clip()
		self:paint_background(cr)
		cr:restore()
	end

	if self.clip_content then
		cr:save()
		cr:new_path()
		self:background_path(cr, 0)
		cr:clip()
	end

	cr:matrix(&cm)

	self:draw_outset_content_shadows(cr)

	if not self.clip_content then
		cr:matrix(&bm)
		self:draw_border(cr)
	end

	cr:matrix(&cm)
	if not for_shadow or self:content_casts_own_shadow() then
		self:draw_content(cr, for_shadow)
	end
	self:draw_inset_content_shadows(cr)

	if self.clip_content then
		cr:restore()
		self:draw_border(cr)
	end

	self:draw_inset_box_shadows(cr)

	if compose then
		cr:pop_group_to_source()
		cr:operator(self.operator)
		cr:paint_with_alpha(self.opacity)
		cr:rgb(0, 0, 0) --release source
	else
		cr:restore()
	end
end

--called in parent's content space; child interface.
terra Layer:hit_test(cr: &context, x: num, y: num, reason: enum)

	if not self.visible or self.opacity <= 0 then
		return false
	end

	var self_allowed = self.hit_test_mask == 0
		or (self.hit_test_mask and reason) ~= 0

	var x, y = self:from_parent_to_box(x, y)
	cr:save()
	cr:identity_matrix()

	--hit the content first if it's not clipped
	if not self.clip_content then
		var cx, cy = self:to_content(x, y)
		if self:hit_test_content(cr, cx, cy, reason) then
			cr:restore()
			return true
		end
	end

	--border is drawn last so hit it first
	if self:border_visible() then
		cr:new_path()
		self:border_path(cr, 1, 0)
		if cr:in_fill(x, y) then --inside border outer edge
			cr:new_path()
			self:border_path(cr, -1, 0)
			if not cr:in_fill(x, y) then --outside border inner edge
				cr:restore()
				if self_allowed then
					self.lib.hit_test_result:set(self, HIT_BORDER, x, y)
					return true
				else
					return false
				end
			end
		elseif self.clip_content then --outside border outer edge when clipped
			cr:restore()
			return false
		end
	end

	--hit background's clip area
	var in_bg = false
	if self.clip_content or self.background.hittable or self:background_visible() then
		cr:new_path()
		self:background_path(cr, 0)
		in_bg = cr:in_fill(x, y)
	end

	--hit the content if inside the clip area.
	if self.clip_content and in_bg then
		var cx, cy = self:to_content(x, y)
		if self:hit_test_content(cr, cx, cy, reason) then
			cr:restore()
			return true
		end
	end

	--hit the background if any
	if self_allowed and in_bg then
		self.lib.hit_test_result:set(self, HIT_BACKGROUND, x, y)
		return true
	end

	return false
end

--layouts --------------------------------------------------------------------

terra Layer:invalidate_layout()
	if self.visible then
		self.top_layer.layout_valid = false
	end
end

terra Layer:invalidate_parent_layout()
	if self.inlayout then
		self:invalidate_layout()
	end
end

terra Layer:invalidate_parent_layout_ignore_pos_parent()
	if self.visible then
		self.top_layer.layout_valid = false
	end
end

terra Layer:invalidate_parent_layout_ignore_visible()
	if self.pos_parent == nil then
		self.top_layer.layout_valid = false
	end
end

terra Layer:invalidate_pixels()
	if self.visible then
		self.top_layer.pixels_valid = false
	end
end

terra Layer:invalidate_pixels_ignore_visible()
	self.top_layer.pixels_valid = false
end

--layout plugin interface ----------------------------------------------------

LAYOUT_TYPE_NULL    = 0
LAYOUT_TYPE_TEXTBOX = 1
LAYOUT_TYPE_FLEXBOX = 2
LAYOUT_TYPE_GRID    = 3

LAYOUT_TYPE_MIN     = 0
LAYOUT_TYPE_MAX     = LAYOUT_TYPE_GRID

terra Layer:sync_layout() self.layout_solver.sync(self) end
terra Layer:sync_min_w(b: bool) return self.layout_solver.sync_min_w(self, b) end
terra Layer:sync_min_h(b: bool) return self.layout_solver.sync_min_h(self, b) end
terra Layer:sync_layout_x(b: bool) return self.layout_solver.sync_x(self, b) end
terra Layer:sync_layout_y(b: bool) return self.layout_solver.sync_y(self, b) end

--layout utils ---------------------------------------------------------------

AXIS_ORDER_XY = 1
AXIS_ORDER_YX = 2

--used by layout types that need to solve their layout on one axis completely
--before they can solve it on the other axis.
terra Layer:sync_layout_separate_axes(axis_order: enum, min_w: num, min_h: num)
	axis_order = iif(axis_order ~= 0, axis_order, self.layout_solver.axis_order)
	var sync_x = axis_order == AXIS_ORDER_XY
	var axis_synced = false
	var other_axis_synced = false
	for phase = 0, 3 do
		other_axis_synced = axis_synced
		if sync_x then
			--sync the x-axis.
			self.w = max(self:sync_min_w(other_axis_synced), min_w)
			axis_synced = self:sync_layout_x(other_axis_synced)
		else
			--sync the y-axis.
			self.h = max(self:sync_min_h(other_axis_synced), min_h)
			axis_synced = self:sync_layout_y(other_axis_synced)
		end
		if axis_synced and other_axis_synced then
			break --both axes were solved before last phase.
		end
		sync_x = not sync_x
	end
	assert(axis_synced and other_axis_synced)
end

terra Layer:sync_layout_children()
	for layer in self do
		layer:sync_layout() --recurse
	end
end

--null layout ----------------------------------------------------------------

--layouting system entry point: called on the top layer.
--called by null-layout layers to layout themselves and their children.
local terra null_sync(self: &Layer)
	self:sync_layout_children() --used as text embeds.
	self:sync_text_shape()
	self:sync_text_embeds()
	self:sync_text_wrap()
	self:sync_text_align()
end

--called by flexible layouts to know the minimum width of their children.
--width-in-height-out layouts call this before h and y are sync'ed.
local terra null_sync_min_w(self: &Layer, other_axis_synced: bool)
	self._min_w = self.min_cw + self.pw
	return self._min_w
end

--called by flexible layouts to know the minimum height of their children.
--width-in-height-out layouts call this only after w and x are sync'ed.
local terra null_sync_min_h(self: &Layer, other_axis_synced: bool)
	self._min_h = self.min_ch + self.ph
	return self._min_h
end

--called by flexible layouts to sync their children on one axis. in response,
--null-layouts sync themselves and their children on both axes when the
--second axis is synced.
local terra null_sync_x(self: &Layer, other_axis_synced: bool)
	if other_axis_synced then
		self:sync_layout()
	end
	return true
end

local null_layout = constant(`LayoutSolver {
	type       = LAYOUT_TYPE_NULL;
	axis_order = 0;
	show_text  = true,
	sync       = null_sync;
	sync_min_w = null_sync_min_w;
	sync_min_h = null_sync_min_h;
	sync_x     = null_sync_x;
	sync_y     = null_sync_x;
})

--textbox layout -------------------------------------------------------------

local terra text_sync(self: &Layer)
	self:sync_layout_children() --used as text embeds.
	self:sync_text_shape()
	self:sync_text_embeds()
	self.cw = max(self.text.layout.min_w, self.min_cw)
	self:sync_text_wrap()
	self.ch = max(self.min_ch, self.text.layout.spaced_h)
	self:sync_text_align()
end

terra Layer:get_nowrap()
	return self.text.layout:get_span_wrap(0) == tr.WRAP_NONE
		and self.text.layout:has_wrap(0, -1)
end

local terra text_sync_min_w(self: &Layer, other_axis_synced: bool)
	var min_cw: num
	if not other_axis_synced or self.nowrap then
		self:sync_text_shape()
		min_cw = self.text.layout.min_w
	else
		--height-in-width-out parent layout with wrapping text not supported
		min_cw = 0
	end
	min_cw = max(min_cw, self.min_cw)
	var min_w = min_cw + self.pw
	self._min_w = min_w
	return min_w
end

local terra text_sync_min_h(self: &Layer, other_axis_synced: bool)
	var min_ch: num
	if other_axis_synced or self.nowrap then
		min_ch = self.text.layout.spaced_h
	else
		--height-in-width-out parent layout with wrapping text not supported
		min_ch = 0
	end
	min_ch = max(min_ch, self.min_ch)
	var min_h = min_ch + self.ph
	self._min_h = min_h
	return min_h
end

local terra text_sync_x(self: &Layer, other_axis_synced: bool)
	if not other_axis_synced then
		self:sync_text_wrap()
		return true
	end
end

local terra text_sync_y(self: &Layer, other_axis_synced: bool)
	if other_axis_synced then
		self:sync_text_align()
		self:sync_layout_children()
		return true
	end
end

local text_layout = constant(`LayoutSolver {
	type       = LAYOUT_TYPE_TEXTBOX;
	axis_order = 0;
	show_text  = true,
	sync       = text_sync;
	sync_min_w = text_sync_min_w;
	sync_min_h = text_sync_min_h;
	sync_x     = text_sync_x;
	sync_y     = text_sync_y;
})

--stuff common to flex & grid layouts ----------------------------------------

local function stretch_items_main_axis_func(items_T, GET_ITEM, T, X, W)

	local _MIN_W = '_min_'..W
	local ALIGN_X = 'align_'..X

	--compute a single item's stretched width and aligned width.
	local terra stretched_item_widths(item: &T, total_w: num,
		total_fr: num, total_overflow_w: num, total_free_w: num, align: enum
	)
		var min_w = item.[_MIN_W]
		var flex_w = total_w * item.fr / total_fr
		var sw: num --stretched width
		if min_w > flex_w then --overflow
			sw = min_w
		else
			var free_w = flex_w - min_w
			var free_p = free_w / total_free_w
			var shrink_w = total_overflow_w * free_p
			if isnan(shrink_w) then --total_free_w == 0
				shrink_w = 0
			end
			sw = flex_w - shrink_w
		end
		return sw, iif(align == ALIGN_STRETCH, sw, min_w)
	end

	--stretch a line of items on the main axis.
	local terra stretch_items_main_axis(
		self: &items_T, i: int, j: int, total_w: num, item_align_x: enum)
		--compute the fraction representing the total width.
		var total_fr = num(0)
		for i = i, j do
			var item = self:[GET_ITEM](i)
			if item.inlayout then
				total_fr = total_fr + max(num(0), item.fr)
			end
		end
		total_fr = max(num(1), total_fr) --treat sub-unit fractions like css flex

		--compute the total overflow width and total free width.
		var total_overflow_w = num(0)
		var total_free_w = num(0)
		for i = i, j do
			var item = self:[GET_ITEM](i)
			if item.inlayout then
				var min_w = item.[_MIN_W]
				var flex_w = total_w * max(num(0), item.fr) / total_fr
				var overflow_w = max(num(0), min_w - flex_w)
				var free_w = max(num(0), flex_w - min_w)
				total_overflow_w = total_overflow_w + overflow_w
				total_free_w = total_free_w + free_w
			end
		end

		--distribute the overflow to children which have free space to
		--take it. each child shrinks to take in the percent of the overflow
		--equal to the child's percent of free space.
		var sx = num(0) --stretched x-coord
		for i = i, j do
			var item = self:[GET_ITEM](i)
			if item.inlayout then

				--compute item's stretched width.
				var align = iif(item.[ALIGN_X] ~= 0, item.[ALIGN_X], item_align_x)
				var sw, w = stretched_item_widths(
					item, total_w, total_fr, total_overflow_w, total_free_w, align
				)

				--align item inside the stretched segment defined by (sx, sw).
				var x = sx
				if align == ALIGN_END or align == ALIGN_RIGHT then
					x = sx + sw - w
				elseif align == ALIGN_CENTER then
					x = sx + (sw - w) / 2
				end

				item.[X] = x
				item.[W] = w
				sx = sx + sw
			end
		end
	end

	return stretch_items_main_axis
end

--get first-item-spacing and inter-item-spacing for distributing main-axis
--free space between items and aligning the items.
local terra align_spacings(align: enum, container_w: num, items_w: num, item_count: int)
	var x = num(0)
	var spacing = num(0)
	if align == ALIGN_END or align == ALIGN_RIGHT then
		x = container_w - items_w
	elseif align == ALIGN_CENTER then
		x = (container_w - items_w) / 2
	elseif align == ALIGN_SPACE_EVENLY then
		spacing = (container_w - items_w) / (item_count + 1)
		x = spacing
	elseif align == ALIGN_SPACE_AROUND then
		spacing = (container_w - items_w) / item_count
		x = spacing / 2
	elseif align == ALIGN_SPACE_BETWEEN then
		spacing = (container_w - items_w) / (item_count - 1)
	end
	return x, spacing
end

--distribute free space between items on the main axis.
local function align_items_main_axis_func(items_T, GET_ITEM, T, X, W, _MIN_W)
	local _MIN_W = _MIN_W or '_min_'..W
	return terra(self: &items_T, i: int, j: int, sx: num, spacing: num)
		for i = i, j do
			var item = self:[GET_ITEM](i)
			if item.inlayout then
				var x, w = sx, item.[_MIN_W]
				var sw = w + spacing
				item.[X] = x
				item.[W] = w
				sx = sx + sw
			end
		end
	end
end

--flexbox layout -------------------------------------------------------------

local function items_max_x(_MIN_W)
	return terra(self: &Layer, i: int, j: int)
		var max_w = num(0)
		var item_count = 0
		for i = i, j do
			var item = self.children(i)
			if item.visible then
				max_w = max(max_w, item.[_MIN_W])
				item_count = item_count + 1
			end
		end
		return max_w, item_count
	end
end
items_max_x_x = items_max_x'_min_w'
items_max_x_y = items_max_x'_min_h'

--generate pairs of methods for vertical and horizontal flex layouts.
local function gen_funcs(X, Y, W, H)

	local CW = 'c'..W
	local CH = 'c'..H
	local _MIN_W = '_min_'..W
	local _MIN_H = '_min_'..H

	local ALIGN_ITEMS_X = 'align_items_'..X
	local ALIGN_ITEMS_Y = 'align_items_'..Y
	local ITEM_ALIGN_X = 'item_align_'..X
	local ITEM_ALIGN_Y = 'item_align_'..Y
	local ALIGN_Y = 'align_'..Y

	local items_max_x = X == 'x' and items_max_x_x or items_max_x_y
	local items_max_y = X == 'x' and items_max_x_y or items_max_x_x

	local terra items_sum_x(self: &Layer, i: int, j: int)
		var sum_w = num(0)
		var item_count = 0
		for i = i, j do
			var item = self.children(i)
			if item.visible then
				sum_w = sum_w + item.[_MIN_W]
				item_count = item_count + 1
			end
		end
		return sum_w, item_count
	end

	local stretch_items_main_axis_x = stretch_items_main_axis_func(Layer, 'child', Layer, X, W)
	local align_items_main_axis_x = align_items_main_axis_func(Layer, 'child', Layer, X, W)

	--special items_min_h() for baseline align.
	--requires that the children are already sync'ed on y-axis.
	local terra items_min_h_baseline(self: &Layer, i: int, j: int)
		var max_ascent  = num(-inf)
		var max_descent = num(-inf)
		for i = i, j do
			var layer = self.children(i)
			if layer.inlayout then
				var baseline = layer.baseline
				max_ascent = max(max_ascent, baseline)
				max_descent = max(max_descent, layer._min_h - baseline)
			end
		end
		return max_ascent + max_descent, max_ascent
	end

	local terra items_min_h(self: &Layer, i: int, j: int, align_baseline: bool)
		if align_baseline then
			return items_min_h_baseline(self, i, j)
		end
		return items_max_y(self, i, j)._0, nan
	end

	local terra linewrap_next(self: &Layer, i: int): {int, int}
		i = i + 1
		if i >= self.children.len then
			return -1, -1
		elseif not self.flex.wrap then
			return i, self.children.len
		end
		var wrap_w = self.[CW]
		var line_w = num(0)
		for j = i, self.children.len do
			var layer = self.children(j)
			if layer.inlayout then
				if j > i and layer.break_before then
					return i, j
				end
				if layer.break_after then
					return i, j+1
				end
				var item_w = layer.[_MIN_W]
				if line_w + item_w > wrap_w then
					return i, j
				end
				line_w = line_w + item_w
			end
		end
		return i, self.children.len
	end

	local struct linewrap {layer: &Layer}
	linewrap.metamethods.__for = function(self, body)
		return quote
			var layer = self.layer --workaround for terra issue #368
			var i = -1
			var j = 0
			while true do
				i, j = linewrap_next(layer, j-1)
				if j == -1 then break end
				[ body(i, j) ]
			end
		end
	end

	Layer.methods['flex_min_cw_'..X] = terra(self: &Layer, other_axis_synced: bool)
		if self.flex.wrap then
			return items_max_x(self, 0, self.children.len)._0
		else
			return items_sum_x(self, 0, self.children.len)._0
		end
	end

	Layer.methods['flex_min_ch_'..X] = terra(
		self: &Layer, other_axis_synced: bool, align_baseline: bool
	)
		if not other_axis_synced and self.flex.wrap then
			--width-in-height-out parent layout requesting min_w on a y-axis
			--wrapping flex (which is a height-in-width-out layout).
			return 0
		end
		var lines_h = num(0)
		for i, j in linewrap{self} do
			var line_h, _ = items_min_h(self, i, j, align_baseline)
			lines_h = lines_h + line_h
		end
		return lines_h
	end

	--align a line of items on the main axis.
	local terra align_items_x(self: &Layer, i: int, j: int, align: enum)
		if align == ALIGN_STRETCH then
			stretch_items_main_axis_x(self, i, j, self.[CW], self.[ITEM_ALIGN_X])
		else
			var sx: num, spacing: num
			if align == ALIGN_START or align == ALIGN_LEFT then
				sx, spacing = 0, 0
			else
				var items_w, item_count = items_sum_x(self, i, j)
				sx, spacing = align_spacings(align, self.[CW], items_w, item_count)
			end
			align_items_main_axis_x(self, i, j, sx, spacing)
		end
	end

	--stretch or align a flex's items on the main-axis.
	Layer.methods['flex_sync_x_'..X] = terra(self: &Layer, other_axis_synced: bool)
		var align = self.[ALIGN_ITEMS_X]
		for i, j in linewrap{self} do
			align_items_x(self, i, j, align)
		end
		return true
	end

	--align a line of items on the cross-axis.
	local terra align_items_y(self: &Layer, i: int, j: int,
		line_y: num, line_h: num, line_baseline: num
	)
		var align = self.[ITEM_ALIGN_Y]
		for i = i, j do
			var layer = self.children(i)
			if layer.inlayout then
				var align = iif(layer.[ALIGN_Y] ~= 0, layer.[ALIGN_Y], align)
				var y: num
				var h: num
				if align == ALIGN_STRETCH then
					y = line_y
					h = line_h
				else
					var item_h = layer.[_MIN_H]
					if align == ALIGN_TOP or align == ALIGN_START then
						y = line_y
						h = item_h
					elseif align == ALIGN_BOTTOM or align == ALIGN_END then
						y = line_y + line_h - item_h
						h = item_h
					elseif align == ALIGN_CENTER then
						y = line_y + (line_h - item_h) / 2
						h = item_h
					elseif not isnan(line_baseline) then
						y = line_y + line_baseline - layer.baseline
					end
				end
				if isnan(line_baseline) then
					layer.[H] = h
				end
				layer.[Y] = y
			end
		end
	end

	--stretch or align a flex's items on the cross-axis.
	Layer.methods['flex_sync_y_'..X] = terra(
		self: &Layer, other_axis_synced: bool, align_baseline: bool
	)
		if not other_axis_synced and self.flex.wrap then
			--trying to lay out the y-axis before knowing the x-axis:
			--dismiss and wait for the 3rd pass.
			return false
		end

		var lines_y: num
		var line_spacing: num
		var line_h: num
		var align = self.[ALIGN_ITEMS_Y]
		if align == ALIGN_STRETCH then
			var lines_h = self.[CH]
			var line_count = 0
			for _1,_2 in linewrap{self} do
				line_count = line_count + 1
			end
			lines_y = 0
			line_spacing = 0
			line_h = lines_h / line_count
		elseif align == ALIGN_TOP or align == ALIGN_START then
			lines_y = 0
			line_spacing = 0
			line_h = nan
		else
			var lines_h = num(0)
			var line_count: int = 0
			for i, j in linewrap{self} do
				var line_h, _ = items_min_h(self, i, j, align_baseline)
				lines_h = lines_h + line_h
				line_count = line_count + 1
			end
			lines_y, line_spacing = align_spacings(align, self.[CH], lines_h, line_count)
			line_h = nan
		end
		var y = lines_y
		var no_line_h = isnan(line_h)
		for i, j in linewrap{self} do
			var line_h = line_h
			var line_baseline = num(nan)
			if no_line_h then
				line_h, line_baseline = items_min_h(self, i, j, align_baseline)
			end
			align_items_y(self, i, j, y, line_h, line_baseline)
			y = y + line_h + line_spacing
		end

		return true
	end

end
gen_funcs('x', 'y', 'w', 'h')
gen_funcs('y', 'x', 'h', 'w')

local terra flex_sync_min_w(self: &Layer, other_axis_synced: bool)

	--sync all children first (bottom-up sync).
	for layer in self do
		if layer.visible then
			layer:sync_min_w(other_axis_synced) --recurse
		end
	end

	var min_cw = iif(self.flex.flow == FLEX_FLOW_X,
			self:flex_min_cw_x(other_axis_synced),
			self:flex_min_ch_y(other_axis_synced, false))

	min_cw = max(min_cw, self.min_cw)
	var min_w = min_cw + self.pw
	self._min_w = min_w
	return min_w
end

local terra flex_sync_min_h(self: &Layer, other_axis_synced: bool)

	var align_baseline = self.flex.flow == FLEX_FLOW_X
		and self.item_align_y == ALIGN_BASELINE

	--sync all children first (bottom-up sync).
	for layer in self do
		if layer.visible then
			var min_h = layer:sync_min_h(other_axis_synced) --recurse
			--for baseline align also layout the children because we need
			--their baseline. we can do this here because we already know
			--we won't stretch them beyond their min_h in this case.
			if align_baseline then
				layer.h = min_h
				layer:sync_layout_y(other_axis_synced)
			end
		end
	end

	var min_ch = iif(self.flex.flow == FLEX_FLOW_X,
		self:flex_min_ch_x(other_axis_synced, align_baseline),
		self:flex_min_cw_y(other_axis_synced))

	min_ch = max(min_ch, self.min_ch)
	var min_h = min_ch + self.ph
	self._min_h = min_h
	return min_h
end

local terra flex_sync_x(self: &Layer, other_axis_synced: bool)

	var synced = iif(self.flex.flow == FLEX_FLOW_X,
			self:flex_sync_x_x(other_axis_synced),
			self:flex_sync_y_y(other_axis_synced, false))

	if synced then
		--sync all children last (top-down sync).
		for layer in self do
			if layer.visible then
				layer:sync_layout_x(other_axis_synced) --recurse
			end
		end
	end
	return synced
end

local terra flex_sync_y(self: &Layer, other_axis_synced: bool)

	if self.flex.flow == FLEX_FLOW_X and self.item_align_y == ALIGN_BASELINE then
		--chilren already sync'ed in sync_min_h().
		return self:flex_sync_y_x(other_axis_synced, true)
	end

	var synced = self.flex.flow == FLEX_FLOW_Y
		and self:flex_sync_x_y(other_axis_synced)
		 or self:flex_sync_y_x(other_axis_synced, false)

	if synced then
		--sync all children last (top-down sync).
		for layer in self do
			if layer.visible then
				layer:sync_layout_y(other_axis_synced) --recurse
			end
		end
	end

	return synced
end

local terra flex_sync(self: &Layer)
	self:sync_layout_separate_axes(0, -inf, -inf)
end

local flex_layout = constant(`LayoutSolver {
	type       = LAYOUT_TYPE_FLEXBOX;
	axis_order = AXIS_ORDER_XY;
	show_text  = false;
	sync       = flex_sync;
	sync_min_w = flex_sync_min_w;
	sync_min_h = flex_sync_min_h;
	sync_x     = flex_sync_x;
	sync_y     = flex_sync_y;
})

--[[
--faster hit-testing for non-wrapped flexboxes.
local terra cmp_ys(items, i, y)
	return items[i].visible and items[i].y < y -- < < [=] = < <
end
var terra cmp_xs(items, i, x)
	return items[i].visible and items[i].x < x -- < < [=] = < <
end
terra flex:hit_test_flex_item(x, y)
	var cmp = self.flex_flow == 'y' and cmp_ys or cmp_xs
	var coord = self.flex_flow == 'y' and y or x
	return max(1, (binsearch(coord, self, cmp) or #self + 1) - 1)
end

terra flex:override_hit_test_children(inherited, x, y, reason)
	if #self < 2 or self.flex_wrap then
		return inherited(self, x, y, reason)
	end
	var i = self:hit_test_flex_item(x, y)
	return self[i]:hit_test(x, y, reason)
end

--faster clipped drawing for non-wrapped flexboxes.
terra flex:override_draw_children(inherited, cr)
	if #self < 1 or self.flex_wrap then
		return inherited(self, cr)
	end
	var x1, y1, x2, y2 = cr:clip_extents()
	var i = self:hit_test_flex_item(x1, y1)
	var j = self:hit_test_flex_item(x2, y2)
	for i = i, j do
		self[i]:draw(cr)
	end
end
]]

--bitmap-of-bools object -----------------------------------------------------

terra BoolBitmap:set(row: int, col: int, val: bool)
	var p = self.bitmap:pixel_addr(col-1, row-1)
	if p ~= nil then
		@p = uint8(val)
	end
end

terra BoolBitmap:get(row: int, col: int)
	var p = self.bitmap:pixel_addr(col-1, row-1)
	return iif(p ~= nil, bool(@p), false)
end

terra BoolBitmap:grow(min_rows: int, min_cols: int)
	var rows0 = self.bitmap.h
	var cols0 = self.bitmap.w
	var rows = max(min_rows, rows0)
	var cols = max(min_cols, cols0)
	if rows > rows0 or cols > cols0 then
		assert(self.bitmap:resize(cols, rows, -1, -1))
		self.bitmap:sub(cols0, 0, cols - cols0, rows):clear()
		self.bitmap:sub(0, rows0, cols0, rows - rows0):clear()
	end
end

terra BoolBitmap:mark(row1: int, col1: int, row_span: int, col_span: int, val: bool)
	self:grow(row1+row_span-1, col1+col_span-1)
	self.bitmap:sub(col1-1, row1-1, col_span, row_span):fill(uint8(val))
end

terra BoolBitmap:hasmarks(row1: int, col1: int, row_span: int, col_span: int)
	var row2 = row1 + row_span
	var col2 = col1 + col_span
	for row = row1, row2 do
		for col = col1, col2 do
			if self:get(row, col) then
				return true
			end
		end
	end
	return false
end

terra BoolBitmap:clear()
	assert(self.bitmap:resize(0, 0, -1, -1))
end

--grid layout ----------------------------------------------------------------

--NOTE: row and column numbering starts from 1, but the arrays are 0-indexed.

--these flags can be combined: X|Y + L|R + T|B
GRID_FLOW_X = 0; GRID_FLOW_Y = 1 --main axis
GRID_FLOW_L = 0; GRID_FLOW_R = 2 --horizontal direction
GRID_FLOW_T = 0; GRID_FLOW_B = 4 --vertical direction

--check that all bits are used (see set_grid_flow()).
GRID_FLOW_MAX = GRID_FLOW_Y + GRID_FLOW_R + GRID_FLOW_B
assert(nextpow2(GRID_FLOW_MAX) == GRID_FLOW_MAX+1)

--auto-positioning algorithm

local terra clip_span(
	row1: int, col1: int, row_span: int, col_span: int,
	max_row: int, max_col: int
)
	var row2 = row1 + row_span - 1
	var col2 = col1 + col_span - 1
	--clip the span to grid boundaries
	row1 = clamp(row1, 1, max_row)
	col1 = clamp(col1, 1, max_col)
	row2 = clamp(row2, 1, max_row)
	col2 = clamp(col2, 1, max_col)
	--support negative spans
	if row1 > row2 then
		row1, row2 = row2, row1
	end
	if col1 > col2 then
		col1, col2 = col2, col1
	end
	row_span = row2 - row1 + 1
	col_span = col2 - col1 + 1
	return row1, col1, row_span, col_span
end

terra Layer:sync_layout_grid_autopos()

	var flow = self.grid.flow
	var col_first = (flow and GRID_FLOW_Y) == 0
	var row_first = not col_first
	var flip_cols = (flow and GRID_FLOW_R) ~= 0
	var flip_rows = (flow and GRID_FLOW_B) ~= 0

	var occupied = &self.lib.grid_occupied

	var grid_wrap = max(1, self.grid.wrap)
	var min_lines = max(1, self.grid.min_lines)
	var max_col = iif(col_first, grid_wrap, min_lines)
	var max_row = iif(row_first, grid_wrap, min_lines)

	--position explicitly-positioned layers first, mark occupied cells
	--and grow the grid bounds to include these layers fully.
	var missing_indices = false
	var negative_indices = false
	for layer in self do
		if layer.inlayout then
			var row = layer.grid_row
			var col = layer.grid_col
			var row_span = max(1, layer.grid_row_span)
			var col_span = max(1, layer.grid_col_span)

			if row ~= 0 or col ~= 0 then --explicit position
				row = iif(row == 0, 1, row)
				col = iif(col == 0, 1, col)
				if row > 0 and col > 0 then
					row, col, row_span, col_span =
						clip_span(row, col, row_span, col_span, maxint, maxint)

					occupied:mark(row, col, row_span, col_span, true)

					max_row = max(max_row, row + row_span - 1)
					max_col = max(max_col, col + col_span - 1)
				else
					negative_indices = true --solve these later
				end
			else --auto-positioned
				--negative spans are treated as positive.
				row_span = abs(row_span)
				col_span = abs(col_span)

				--grow the grid bounds on the main axis to fit the widest layer.
				if col_first then
					max_col = max(max_col, col_span)
				else
					max_row = max(max_row, row_span)
				end

				missing_indices = true --solve these later
			end

			layer._grid_row = row
			layer._grid_col = col
			layer._grid_row_span = row_span
			layer._grid_col_span = col_span
		end
	end

	--position explicitly-positioned layers with negative indices
	--now that we know the grid bounds. these types of spans do not enlarge
	--the grid bounds, but instead are clipped to it.
	if negative_indices then
		for layer in self do
			if layer.inlayout then
				var row = layer._grid_row
				var col = layer._grid_col
				if row < 0 or col < 0 then
					var row_span = layer._grid_row_span
					var col_span = layer._grid_col_span
					if row < 0 then
						row = max_row + row + 1
					end
					if col < 0 then
						col = max_col + col + 1
					end
					row, col, row_span, col_span =
						clip_span(row, col, row_span, col_span, max_row, max_col)

					occupied:mark(row, col, row_span, col_span, true)

					layer._grid_row = row
					layer._grid_col = col
					layer._grid_row_span = row_span
					layer._grid_col_span = col_span
				end
			end
		end
	end

	--auto-wrap layers without explicit indices over non-occupied cells.
	--grow grid bounds on the cross-axis if needed but not on the main axis.
	--these types of spans are never clipped to the grid bounds.
	if missing_indices then
		var row, col = 1, 1
		for layer in self do
			if layer.inlayout and layer._grid_row == 0 then
				var row_span = layer._grid_row_span
				var col_span = layer._grid_col_span

				while true do
					--check for wrapping.
					if col_first and col + col_span - 1 > max_col then
						col = 1
						row = row + 1
					elseif row_first and row + row_span - 1 > max_row then
						row = 1
						col = col + 1
					end
					if occupied:hasmarks(row, col, row_span, col_span) then
						--advance cursor by one cell.
						if col_first then
							col = col + 1
						else
							row = row + 1
						end
					else
						break
					end
				end

				occupied:mark(row, col, row_span, col_span, true)

				layer._grid_row = row
				layer._grid_col = col

				--grow grid bounds on the cross-axis.
				if col_first then
					max_row = max(max_row, row + row_span - 1)
				else
					max_col = max(max_col, col + col_span - 1)
				end

				--advance cursor to right after the span, without wrapping.
				if col_first then
					col = col + col_span
				else
					row = row + row_span
				end
			end
		end
	end

	occupied:clear()

	--reverse the order of rows and/or columns depending on grid_flow.
	if flip_rows or flip_cols then
		for layer in self do
			if layer.inlayout then
				if flip_rows then
					layer._grid_row = max_row
						- layer._grid_row
						- layer._grid_row_span
						+ 2
				end
				if flip_cols then
					layer._grid_col = max_col
						- layer._grid_col
						- layer._grid_col_span
						+ 2
				end
			end
		end
	end

	self.grid._flip_rows = flip_rows
	self.grid._flip_cols = flip_cols
	self.grid._max_row = max_row
	self.grid._max_col = max_col
end

--layouting algorithm

local stretch_cols_main_axis = stretch_items_main_axis_func(arr(GridLayoutCol), 'at', GridLayoutCol, 'x', 'w')
local align_cols_main_axis   = align_items_main_axis_func(arr(GridLayoutCol), 'at', GridLayoutCol, 'x', 'w')
local realign_cols_main_axis = align_items_main_axis_func(arr(GridLayoutCol), 'at', GridLayoutCol, 'x', 'w', 'w')

local function gen_funcs(X, Y, W, H, COL)

	local CW = 'c'..W
	local PW = 'p'..W
	local MIN_CW = 'min_'..CW
	local _MIN_W = '_min_'..W
	local COL_FRS = COL..'_frs'
	local COL_GAP = COL..'_gap'
	local ALIGN_ITEMS_X = 'align_items_'..X
	local ITEM_ALIGN_X = 'item_align_'..X
	local ALIGN_X = 'align_'..X
	local _COLS = '_'..COL..'s'
	local _MAX_COL = '_max_'..COL
	local _COL = '_grid_'..COL
	local _COL_SPAN = '_grid_'..COL..'_span'
	local _FLIP_COLS = '_flip_'..COL..'s'

	local terra sync_min_w(self: &Layer, other_axis_synced: bool)

		if not other_axis_synced then
			self:sync_layout_grid_autopos()
		end

		--sync all children first (bottom-up sync).
		for layer in self do
			if layer.visible then
				layer:['sync_min_'..W](other_axis_synced) --recurse
			end
		end

		var max_col = self.grid.[_MAX_COL]
		var frs = &self.grid.[COL_FRS] --{fr1, ...}

		--compute the fraction representing the total width.
		var total_fr = num(0)
		for layer in self do
			if layer.inlayout then
				var col1 = layer.[_COL]
				var col2 = col1 + layer.[_COL_SPAN]
				for col = col1, col2 do
					total_fr = total_fr + frs(col-1, 1)
				end
			end
		end

		--create pseudo-layers to apply flex stretching to.
		var cols = &self.grid.[_COLS]
		cols.len = max_col

		for col = 0, max_col do
			cols:set(col, GridLayoutCol{
				fr = frs(col, 1),
				_min_w = 0,
				x = 0,
				w = 0,
				align_x = 0,
			})
		end

		--compute the minimum width of each column.
		for layer in self do
			if layer.inlayout then
				var col1 = layer.[_COL]
				var col2 = col1 + layer.[_COL_SPAN] - 1
				var span_min_w = layer.[_MIN_W]

				if col1 == col2 then
					var item = cols:at(col1-1)
					var col_min_w = span_min_w
					item._min_w = max(item._min_w, col_min_w)
				else --merged columns: unmerge
					var span_fr = num(0)
					for col = col1, col2 do
						span_fr = span_fr + frs(col-1, 1)
					end
					for col = col1, col2 do
						var item = cols:at(col-1)
						var col_min_w = frs(col-1, 1) / span_fr * span_min_w
						item._min_w = max(item._min_w, col_min_w)
					end
				end
			end
		end

		var gap_w = self.grid.[COL_GAP]
		var min_cw = (max_col - 1) * gap_w

		for _,item in cols do
			min_cw = min_cw + item._min_w
		end

		min_cw = max(min_cw, self.[MIN_CW])
		var min_w = min_cw + self.[PW]
		self.[_MIN_W] = min_w

		return min_w
	end

	local terra sum_min_w(cols: &arr(GridLayoutCol))
		var w = num(0)
		for _,col in cols do
			w = w + col._min_w
		end
		return w
	end

	local terra sync_x(self: &Layer, other_axis_synced: bool)

		var cols = &self.grid.[_COLS]
		var gap_w = self.grid.[COL_GAP]
		var max_col = self.grid.[_MAX_COL]
		var cw = self.[CW]
		var align_items_x = self.[ALIGN_ITEMS_X]
		var item_align_x = self.[ITEM_ALIGN_X]

		var ALIGN_START, ALIGN_END = ALIGN_START, ALIGN_END
		if self.grid.[_FLIP_COLS] then
			ALIGN_START, ALIGN_END = ALIGN_END, ALIGN_START
		end

		var nogap_cw = cw - (max_col - 1) * gap_w
		var has_gap = cw ~= nogap_cw

		if align_items_x == ALIGN_STRETCH then
			stretch_cols_main_axis(cols, 0, cols.len, nogap_cw, ALIGN_STRETCH)
		else
			var sx: num, spacing: num
			if align_items_x == ALIGN_START or align_items_x == ALIGN_LEFT then
				sx, spacing = 0, 0
			else
				var items_w = sum_min_w(cols)
				var items_count = cols.len
				sx, spacing = align_spacings(align_items_x, nogap_cw, items_w, items_count)
			end
			align_cols_main_axis(cols, 0, cols.len, sx, spacing)
		end

		if has_gap then
			var sx, spacing = align_spacings(ALIGN_SPACE_BETWEEN, cw, nogap_cw, cols.len)
			realign_cols_main_axis(cols, 0, cols.len, sx, spacing)
		end

		var x = num(0)
		for layer in self do
			if layer.inlayout then

				var col1 = layer.[_COL]
				var col2 = col1 + layer.[_COL_SPAN] - 1
				var col_item1 = cols:at(col1-1)
				var col_item2 = cols:at(col2-1)
				var x1 = col_item1.x
				var x2 = col_item2.x + col_item2.w

				var align = iif(layer.[ALIGN_X] ~= 0, layer.[ALIGN_X], item_align_x)
				var x: num, w: num
				if align == ALIGN_STRETCH then
					x, w = x1, x2 - x1
				elseif align == ALIGN_START or align == ALIGN_LEFT then
					x, w = x1, layer.[_MIN_W]
				elseif align == ALIGN_END or align == ALIGN_RIGHT then
					w = layer.[_MIN_W]
					x = x2 - w
				elseif align == ALIGN_CENTER then
					w = layer.[_MIN_W]
					x = x1 + (x2 - x1 - w) / 2
				end
				layer.[X] = x
				layer.[W] = w
			end
		end

		--sync all children last (top-down sync).
		for layer in self do
			if layer.visible then
				layer:['sync_layout_'..X](other_axis_synced) --recurse
			end
		end

		return true
	end

	return sync_min_w, sync_x
end
local grid_sync_min_w, grid_sync_x = gen_funcs('x', 'y', 'w', 'h', 'col')
local grid_sync_min_h, grid_sync_y = gen_funcs('y', 'x', 'h', 'w', 'row')

local terra grid_sync(self: &Layer)
	self:sync_layout_separate_axes(0, -inf, -inf)
end

local grid_layout = constant(`LayoutSolver {
	type       = LAYOUT_TYPE_GRID;
	axis_order = AXIS_ORDER_XY;
	show_text  = false;
	sync       = grid_sync;
	sync_min_w = grid_sync_min_w;
	sync_min_h = grid_sync_min_h;
	sync_x     = grid_sync_x;
	sync_y     = grid_sync_y;
})

--layout plugin vtable -------------------------------------------------------

--NOTE: layouts must be added in the order of LAYOUT_TYPE_* constants.
local layouts = constant(`arrayof(LayoutSolver,
	null_layout,
	text_layout,
	flex_layout,
	grid_layout
))

terra Layer:get_layout_type() return self.layout_solver.type end

terra Layer:set_layout_type(type: enum)
	self.layout_solver = &layouts[type]
end

terra Layer:init_layout()
	self.layout_solver = &null_layout
end

--lib ------------------------------------------------------------------------

terra Lib:init(load_font: FontLoadFunc, unload_font: FontUnloadFunc)
	self.text_renderer:init(load_font, unload_font)
	self.text_renderer.embed_draw_function = text_embed_draw
	self.grid_occupied:init()
	self.default_shadow:init(nil)
end

terra Lib:free()
	self.text_renderer:free()
	self.grid_occupied:free()
end

--inlining invalidation one-liners just in case the compiler won't.
setinlined(Layer.methods, function(s) return (s:find'^invalidate_') end)

return _M
