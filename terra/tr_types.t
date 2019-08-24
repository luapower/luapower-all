
--Module table with dependencies, enums and types.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/low'.module'terra/tr_module')

--dependencies ---------------------------------------------------------------

assert(color, 'require the graphics adapter first, eg. terra/tr_paint_cairo')

low = require'terra/low'
require'terra/phf'
require'terra/fixedfreelist'
require'terra/lrucache'
require'terra/arrayfreelist'
require'terra/box2d'
require_h'freetype_h'
require_h'harfbuzz_h'
require_h'fribidi_h'
require_h'libunibreak_h'
require_h'xxhash_h'

linklibrary'harfbuzz'
linklibrary'fribidi'
linklibrary'unibreak'
linklibrary'freetype'
linklibrary'xxhash'

--replace the default hash function with faster xxhash.
low.bithash = macro(function(size_t, k, h, len)
	local size_t = size_t:astype()
	local T = k:getpointertype()
	local len = len or 1
	local xxh = sizeof(size_t) == 8 and XXH64 or XXH32
	return `[size_t](xxh([&opaque](k), len * sizeof(T), h))
end)

--create getters and setters for converting from/to fixed-point decimal fields.
function fixpointfields(T)
	for i,e in ipairs(T.entries) do
		local priv = e.field
		local pub, digits, decimals = priv:match'^(.-)_(%d+)_(%d+)$'
		if pub then
			local intbits = tonumber(digits) - tonumber(decimals)
			local factor = 2^decimals
			T.methods['get_'..pub] = macro(function(self)
				return `[num](self.[priv] / [num](factor))
			end)
			local maxn = 2^intbits * 64 - 1
			T.methods['set_'..pub] = macro(function(self, x)
				return quote self.[priv] = clamp(x * factor, 0, maxn) end
			end)
		end
	end
end

--enums ----------------------------------------------------------------------

--NOTE: starting enum values at 1 so that clients can reserve 0 for "default".
ALIGN_LEFT    = 1
ALIGN_RIGHT   = 2
ALIGN_CENTER  = 3
ALIGN_JUSTIFY = 4
ALIGN_TOP     = ALIGN_LEFT
ALIGN_BOTTOM  = ALIGN_RIGHT
ALIGN_START   = 5 --based on bidi dir; only for align_x
ALIGN_END     = 6 --based on bidi dir; only for align_x
ALIGN_MAX     = 6

--dir
DIR_AUTO = FRIBIDI_PAR_ON; assert(DIR_AUTO ~= 0)
DIR_LTR  = FRIBIDI_PAR_LTR
DIR_RTL  = FRIBIDI_PAR_RTL
DIR_WLTR = FRIBIDI_PAR_WLTR
DIR_WRTL = FRIBIDI_PAR_WRTL

--linebreak codes
BREAK_NONE = 0
BREAK_LINE = 1
BREAK_PARA = 2

--base types -----------------------------------------------------------------

num = float
rect = rect(num)
font_id_t = int16
bidi_dir_t = FriBidiParType
bidi_level_t = FriBidiLevel

struct Renderer;
struct Font;

--overridable constants ------------------------------------------------------

DEFAULT_TEXT_COLOR        = DEFAULT_TEXT_COLOR      or `color {0xffffffff}
DEFAULT_SELECTION_COLOR   = DEFAULT_SELECTION_COLOR or `color {0x6666ff66}
DEFAULT_TEXT_OPERATOR     = DEFAULT_TEXT_OPERATOR   or 2 --CAIRO_OPERATOR_OVER
DEFAULT_SELECTION_OPACITY = DEFAULT_SELECTION_OPACITY or 1

--font type ------------------------------------------------------------------

struct Font (gettersandsetters) {
	r: &Renderer;
	--loading and unloading
	file_data: &opaque;
	file_size: size_t;
	refcount: int;
	--freetype & harfbuzz font objects
	hb_font: &hb_font_t;
	ft_face: FT_Face;
	ft_load_flags: int;
	ft_render_flags: FT_Render_Mode;
	--font metrics per current size
	size: num;
	scale: num; --scaling factor for bitmap fonts
	ascent: num;
	descent: num;
}

FontLoadFunc = {int, &&opaque, &size_t} -> {}
FontLoadFunc.cname = 'tr_font_load_func'

--layout type ----------------------------------------------------------------

struct Span (gettersandsetters) {
	offset: int; --offset in the text, in codepoints.
	font_id: font_id_t;
	font_size_16_6: uint16;
	features: arr(hb_feature_t);
	script: hb_script_t;
	lang: hb_language_t;
	paragraph_dir: bidi_dir_t; --bidi dir override for current paragraph.
	nowrap: bool; --disable word wrapping.
	color: color;
	opacity: double; --the opacity level in 0..1.
	operator: int;   --blending operator.
}
fixpointfields(Span)

Span.empty = `Span {
	offset = 0;
	font_id = -1;
	font_size_16_6 = 0;
	features = [arr(hb_feature_t).empty];
	script = 0;
	lang = nil;
	paragraph_dir = 0;
	nowrap = false;
	color = DEFAULT_TEXT_COLOR;
	opacity = 1;
	operator = DEFAULT_TEXT_OPERATOR;
}

terra Span:init()
	@self = [Span.empty]
end

terra Span:free()
	self.features:free()
end

terra Span:copy()
	var s = @self
	s.features = self.features:copy()
	return s
end

struct Embed {
	offset: int; --offset in the text
	ascent: num;
	descent: num;
	advance_x: num;
}

struct SubSeg {
	i: int16;
	j: int16;
	span: &Span;
	clip_left: num;
	clip_right: num;
}

struct Seg {
	--filled by shaping
	glyph_run_id: int;
	line_num: int;             --physical line number
	linebreak: enum;           --for line/paragraph breaking
	bidi_level: bidi_level_t;  --for bidi reordering
	paragraph_dir: bidi_dir_t; --computed paragraph bidi dir, for ALIGN_AUTO
	span: &Span;               --span of the first sub-segment
	offset: int;               --codepoint offset into the text
	--filled by layouting
	line_index: int;
	x: num;
	advance_x: num; --segment's x-axis boundaries
	next_vis: &Seg; --next segment on the same line in visual order
	wrapped: bool;  --segment is the last on a wrapped line
	visible: bool;  --segment is not entirely clipped
	subsegs: arr(SubSeg);
}

terra Seg:free()
	self.subsegs:free()
end

struct Line (gettersandsetters) {
	index: int;
	first: &Seg;     --first segment in text order
	first_vis: &Seg; --first segment in visual order
	x: num;
	y: num;
	advance_x: num;
	ascent: num;
	descent: num;
	spaced_ascent: num;
	spaced_descent: num;
	linebreak: enum; --set by wrap(), used by align()
}

Line.metamethods.__for = function(self, body)
	if self:islvalue() then self = `&self end
	return quote
		var self = self
		var seg = self.first_vis
		while seg ~= nil do
			[body(seg)]
			seg = seg.next_vis
		end
	end
end

STATE_UNSHAPED = 0 --must be 0
STATE_SHAPED   = 1
STATE_WRAPPED  = 2
STATE_SPACED   = 3
STATE_ALIGNED  = 4

struct Cursor;
terra Cursor.methods.free :: {&Cursor} -> {}
--^^for Layout.cursors to take ownership.

struct Selection;
terra Selection.methods.free :: {&Selection} -> {}
--^^for Layout.selections to take ownership.

struct Layout (gettersandsetters) {
	r: &Renderer;
	--input/shape
	spans: arr(Span);
	embeds: arr(Embed);
	text: arr(codepoint);
	_maxlen: int;
	_dir: bidi_dir_t; --default base paragraph direction.
	--input/wrap+align
	_align_w: num;
	_align_h: num;
	_align_x: enum;
	_align_y: enum;
	_line_spacing: num; --line spacing multiplication factor (m.f.).
	_hardline_spacing: num; --line spacing m.f. for hard-breaked lines.
	_paragraph_spacing: num; --paragraph spacing m.f.
	--input/clip+paint
	_clip_x: num;
	_clip_y: num;
	_clip_w: num;
	_clip_h: num;
	_x: num;
	_y: num;
	--state
	state: enum; --STATE_*
	--shaping output: segments and bidi info
	segs: arr(Seg);
	bidi: bool; --`true` if the text is bidirectional.
	--wrap/align output: lines
	lines: arr(Line);
	max_ax: num; --text's maximum x-advance (equivalent to text's width).
	h: num; --text's wrapped height.
	spaced_h: num; --text's wrapped height including line and paragraph spacing.
	baseline: num;
	min_x: num;
	--clip output
	clip_valid: bool;
	first_visible_line: int;
	last_visible_line: int;
	--cached computed values
	_min_w: num;
	_max_w: num;
	--text cursors and selections, kept synchronized with text changes.
	cursors: arr(&Cursor);
	selections: arr(&Selection);
}

terra Layout:get_maxlen  () return self._maxlen end
terra Layout:get_dir     () return self._dir end
terra Layout:get_align_w () return self._align_w end
terra Layout:get_align_h () return self._align_h end
terra Layout:get_align_x () return self._align_x end
terra Layout:get_align_y () return self._align_y end
terra Layout:get_line_spacing      () return self._line_spacing end
terra Layout:get_hardline_spacing  () return self._hardline_spacing end
terra Layout:get_paragraph_spacing () return self._paragraph_spacing end
terra Layout:get_clip_x  () return self._clip_x end
terra Layout:get_clip_y  () return self._clip_y end
terra Layout:get_clip_w  () return self._clip_w end
terra Layout:get_clip_h  () return self._clip_h end
terra Layout:get_x       () return self._x end
terra Layout:get_y       () return self._y end

terra Layout:span_end_offset(i: int)
	var next_span = self.spans:at(i+1, nil)
	return iif(next_span ~= nil, next_span.offset, self.text.len)
end

terra Layout:seg_index(seg: &Seg)
	return self.segs:index(seg)
end

terra Layout:init(r: &Renderer)
	fill(self)
	self.r = r
	self._maxlen   =  maxint
	self._dir      =  DIR_AUTO
	self._align_x  =  ALIGN_CENTER
	self._align_y  =  ALIGN_CENTER
	self._line_spacing      = 1.0
	self._hardline_spacing  = 1.0
	self._paragraph_spacing = 2.0
	self._clip_x   = -inf
	self._clip_y   = -inf
	self._clip_w   =  inf
	self._clip_h   =  inf
	self.spans:add([Span.empty])
end

--glyph run type -------------------------------------------------------------

struct GlyphInfo (gettersandsetters) {
	glyph_index: int;
	x: num; --glyph origin relative to glyph run origin
	image_x_16_6: int16; --glyph image origin relative to glyph origin
	image_y_16_6: int16;
	cluster: int;
}
fixpointfields(GlyphInfo)

struct GlyphImage {
	surface: &surface;
 	x: int16; --image coordinates relative to the (first) glyph origin
	y: int16;
}
GlyphImage.empty = `GlyphImage{surface = nil, x = 0, y = 0}

terra GlyphImage.methods.free :: {&GlyphImage, &Renderer} -> {}

struct GlyphRun (gettersandsetters) {
	--cache key fields: no alignment holes between lang..rtl!
	text            : arr(codepoint);
	features        : arr(hb_feature_t);
	lang            : hb_language_t;     --8
	script          : hb_script_t;       --4
	font_id         : font_id_t;         --2
	font_size_16_6  : uint16;            --2
	rtl             : bool;              --1
	--resulting glyphs and glyph metrics
	glyphs          : arr(GlyphInfo);
	--for positioning in horizontal flow
	ascent          : num;
	descent         : num;
	advance_x       : num;
	wrap_advance_x  : num;
	--pre-rendered images for each subpixel offset.
	images          : arr{T = GlyphImage, context_t = &Renderer};
	images_memsize  : int;
	--for cursor positioning and hit testing (len = text.len+1)
	cursor_offsets  : arr(uint16);
	cursor_xs       : arr(num);
	trailing_space  : bool;
}
fixpointfields(GlyphRun)

local key_offset = offsetof(GlyphRun, 'lang')
local key_size = offsetafter(GlyphRun, 'rtl') - key_offset

terra GlyphRun:__hash32(h: uint32)
	h = hash(uint32, [&char](self) + key_offset, h, key_size)
	h = hash(uint32, &self.text, h)
	h = hash(uint32, &self.features, h)
	return h
end

terra GlyphRun:__eq(other: &GlyphRun)
	return equal(
			[&char](self)  + key_offset,
			[&char](other) + key_offset, key_size)
		and equal(&self.text, &other.text)
		and equal(&self.features, &other.features)
end

terra GlyphRun:__memsize()
	return
		  memsize(self.text)
		+ memsize(self.features)
		+ memsize(self.glyphs)
		+ memsize(self.images)
		+ memsize(self.cursor_offsets)
		+ memsize(self.cursor_xs)
		+ self.images_memsize
end

terra GlyphRun.methods.free :: {&GlyphRun, &Renderer} -> {}

--glyph type -----------------------------------------------------------------

struct Glyph (gettersandsetters) {
	--cache key: no alignment holes between fields!
	font_id         : font_id_t;   --2
	font_size_16_6  : uint16;      --2
	glyph_index     : uint;        --4
	subpixel_offset_x_8_6 : uint8; --1
	--glyph image
	image: GlyphImage;
}
fixpointfields(Glyph)

Glyph.empty = `Glyph {
	font_id = -1;
	font_size_16_6 = 0;
	glyph_index = 0;
	subpixel_offset_x_8_6 = 0;
	image = [GlyphImage.empty];
}

local key_offset = offsetof(Glyph, 'font_id')
local key_size = offsetafter(Glyph, 'subpixel_offset_x_8_6') - key_offset

terra Glyph:__hash32(h: uint32)
	return hash(uint32, [&char](self) + key_offset, h, key_size)
end

terra Glyph:__eq(other: &Glyph)
	return equal(
		[&char](self ) + key_offset,
		[&char](other) + key_offset, key_size)
end

terra Glyph:__memsize()
	return iif(self.image.surface ~= nil,
		1024 + self.image.surface:stride() * self.image.surface:height(), 0)
end

terra Glyph.methods.free :: {&Glyph, &Renderer} -> {}

--cursor & selection types ---------------------------------------------------

--visual position in shaped text and matching offset in logical text.
struct Pos (gettersandsetters) {
	layout: &Layout;
	seg: &Seg;
	i: int;
	offset: int; --offset in logical text, for repositioning after reshaping.
}

struct Cursor (gettersandsetters) {
	p: Pos;
	x: num; --x-coord to try to go to when navigating up and down.
	--park cursor to home or end if vertical navigation goes above or beyond
	--available text lines.
	park_home: bool;
	park_end: bool;
	--jump-through same-text-offset cursors: most text editors remove duplicate
	--cursors to keep a 1:1 relationship between text positions and cursor
	--positions, which gets funny with BiDi and you also can't tell if there's
	--a space at the end of a wrapped line or not.
	unique_offsets: bool;
	--keep a cursor after the last space char on a wrapped line: this cursor can
	--be trouble because it is outside the textbox and if there's not enough room
	--on the wrap-side of the textbox it can get clipped out.
	wrapped_space: bool;
	insert_mode: bool;
	--drawing attributes
	visible: bool;
	color: color;
	opacity: num;
	w: num;
}

terra Cursor:get_layout() return self.p.layout end
terra Cursor:set_layout(p: &Layout) self.p.layout = p end

struct Selection (gettersandsetters) {
	p1: Pos;
	p2: Pos;
	color: color;
	opacity: num;
}

terra Selection:get_layout() return self.p1.layout end
terra Selection:set_layout(p: &Layout)
	self.p1.layout = p
	self.p2.layout = p
end

--renderer type --------------------------------------------------------------

struct SegRange {
	left: &Seg;
	right: &Seg;
	prev: &SegRange;
	bidi_level: int8;
}

RangesFreelist = fixedfreelist(SegRange)

GlyphRunCache = lrucache {key_t = GlyphRun, context_t = &Renderer}
GlyphCache = lrucache {key_t = Glyph, context_t = &Renderer}

struct Renderer (gettersandsetters) {

	--rasterizer config
	font_size_resolution: num;
	subpixel_x_resolution: num;
	word_subpixel_x_resolution: num;

	ft_lib: FT_Library;

	fonts: arrayfreelist(Font, font_id_t);
	load_font: FontLoadFunc;
	unload_font: FontLoadFunc;

	glyphs: GlyphCache;
	glyph_runs: GlyphRunCache;

	--temporary arrays that grow as long as the longest input text.
	cpstack:         arr(codepoint);
	scripts:         arr(hb_script_t);
	langs:           arr(hb_language_t);
	bidi_types:      arr(FriBidiCharType);
	bracket_types:   arr(FriBidiBracketType);
	levels:          arr(bidi_level_t);
	linebreaks:      arr(char);
	grapheme_breaks: arr(char);
	carets_buffer:   arr(hb_position_t);
	substack:        arr(SubSeg);
	ranges:          RangesFreelist;
	sbuf:            arr(char);
	xsbuf:           arr(double);
	paragraph_dirs:  arr(bidi_dir_t);

	--constants that neeed to be initialized at runtime.
	HB_LANGUAGE_EN: hb_language_t;
	HB_LANGUAGE_DE: hb_language_t;
	HB_LANGUAGE_ES: hb_language_t;
	HB_LANGUAGE_FR: hb_language_t;
	HB_LANGUAGE_RU: hb_language_t;
	HB_LANGUAGE_ZH: hb_language_t;

	paint_glyph_num: int;
}

terra Layout:glyph_run(seg: &Seg)
	return &self.r.glyph_runs:pair(seg.glyph_run_id).key
end


return _M
