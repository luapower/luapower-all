--[[

	Base module in which we include dependencies and declare enums and types.

]]

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

linklibrary'freetype'
linklibrary'harfbuzz'
linklibrary'fribidi'
linklibrary'unibreak'
linklibrary'xxhash'

--replace the default hash function used by the hashmap with faster xxhash.
low.bithash = macro(function(size_t, k, h, len)
	local size_t = size_t:astype()
	local T = k:getpointertype()
	local len = len or 1
	local xxh = sizeof(size_t) == 8 and XXH64 or XXH32
	return `[size_t](xxh([&opaque](k), len * sizeof(T), h))
end)

--create getters and setters for converting from/to fixed-point decimal fields.
--all fields with the name `<name>_<digits>_<decimals>` will be considered.
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

--bidi paragraph directions (starting at 1, see above).
DIR_AUTO = 1 --auto-detect.
DIR_LTR  = 2
DIR_RTL  = 3
DIR_WLTR = 4 --weak LTR
DIR_WRTL = 5 --weak RTL

DIR_MIN = DIR_AUTO
DIR_MAX = DIR_WRTL

--linebreak codes
BREAK_NONE = 0 --wrapping not allowed
BREAK_WRAP = 1 --wrapping allowed
BREAK_LINE = 2 --explicit line break (CR, LF, etc.)
BREAK_PARA = 3 --explicit paragraph break (PS).

--codepoint range reserved for embeds.
EMBED_MIN       = 0x100000 --PUA-B
EMBED_MAX       = 0x10FFFD
MAX_EMBED_COUNT = EMBED_MAX - EMBED_MIN

UNDERLINE_NONE   = 0 --must be zero.
UNDERLINE_SOLID  = 1
UNDERLINE_ZIGZAG = 2

UNDERLINE_MIN = UNDERLINE_NONE
UNDERLINE_MAX = UNDERLINE_ZIGZAG

--base types -----------------------------------------------------------------

num = float --using floats on the glyph runs saves 25% memory.
rect = rect(num)

struct Renderer;
struct Font;

--font type ------------------------------------------------------------------

struct FontFace (gettersandsetters) {
	ft_face: FT_Face;
	hb_font: &hb_font_t; --represents a ft_face at a particular size.
	ft_load_flags: int;
	ft_render_flags: FT_Render_Mode;
	--font metrics for current size
	size: num;
	scale: num; --scaling factor for scaling raster glyphs.
}

FontFace.empty = `FontFace {
	ft_face = nil;
	hb_font = nil;
	ft_load_flags = 0;
	ft_render_flags = 0;
	size = 0;
	scale = 0;
}

terra FontFace.methods.free :: {&FontFace} -> {}

struct Font (gettersandsetters) {
	r: &Renderer;
	--loading and unloading
	file_data: &opaque; --nil signals loading failure.
	file_size: size_t;
	faces: arr{T = FontFace, own_elements = true};
	selected_face_index: int;
	id: int; --kept for unloading.
	mmapped: bool; --mmapped or allocated.
}

terra Font.methods.free :: {&Font} -> {}

FontLoadFunc   = {int, &&opaque, &size_t, &bool} -> {}
FontUnloadFunc = {int, &opaque, size_t, bool} -> {}

terra Font:__memsize() --for lru cache
	return self.file_size
end

--layout type ----------------------------------------------------------------

terra hb_feature_t:__eq(other: &hb_feature_t)
	return
		    self.tag     == other.tag
		and self.value   == other.value
		and self.start   == other.start
		and self.['end'] == other.['end']
end

hb_feature_arr_t = arr(hb_feature_t)

-- A span is a set of properties for a specific part of the text.
-- Spans are kept in an array and cover the whole text without holes by virtue
-- of their `offset` field alone: a span ends where the next one begins.

WRAP_WORD = 0
WRAP_CHAR = 1
WRAP_NONE = 2

struct Span (gettersandsetters) {
	offset: int; --offset in the text, in codepoints.
	font_id: int;
	font: &Font;
	font_face_index: uint16;
	font_size_16_6: uint16;
	features: hb_feature_arr_t;
	lang: hb_language_t;
	script: hb_script_t;
	opacity: num; --the opacity level in 0..1.
	color: color;
	operator: enum; --blending operator.
	paragraph_dir: enum; --bidi dir override for current paragraph.
	wrap: enum; --WRAP_*
	underline: enum; --UNDERLINE_*
	underline_color: color;
	underline_opacity: num;
	baseline: num; --0..1 corresponds to 0..ascent.
}
fixpointfields(Span)

Span.empty_const = constant(`Span {
	offset = 0;
	font_id = -1;
	font = nil;
	font_face_index = 0;
	font_size_16_6 = 0;
	features = [hb_feature_arr_t.empty];
	lang = nil;
	script = 0;
	opacity = 1;
	color = DEFAULT_TEXT_COLOR;
	operator = DEFAULT_TEXT_OPERATOR;
	paragraph_dir = 0;
	wrap = WRAP_WORD;
	underline = 0;
	underline_color = DEFAULT_TEXT_COLOR;
	underline_opacity = 1;
	baseline = 0;
})

terra Span:init()
	@self = [Span.empty_const]
end

terra forget_font :: {&Renderer, int} -> {}

terra Span:free(r: &Renderer)
	self.features:free()
	forget_font(r, self.font_id)
	self.font = nil
end

struct SegMetrics {
	ascent: num;
	descent: num;
	advance_x: num;
	wrap_advance_x: num;
}

SegMetrics.empty = `SegMetrics{
	ascent = 0;
	descent = 0;
	advance_x = 0;
	wrap_advance_x = 0;
}

--an embed provides custom metrics for a PUA-B codepoint and it's used to
--embed widgets in text using codepoints starting at \u{100000}.
struct Embed {
	metrics: SegMetrics;
}

Embed.empty_const = constant(`Embed{
	metrics = [SegMetrics.empty];
})

--a sub-segment is a clipped part of a glyph run image, used when a single
--glyph run is coverd by multiple spans.
struct SubSeg {
	span: &Span;
	glyph_index1: int16;
	glyph_index2: int16;
	x1: num;
	x2: num;
	clip_left: bool;
	clip_right: bool;
}

struct Layout;

-- A segment is the result of shaping a single shaping-unit i.e. a single
-- word as delimited by soft-breaks per unicode line-breaking algorithm.
-- because shaping is expensive, shaping results are cached in a struct
-- called "glyph run" which the segment references via its `glyph_run_id`.
-- segs are kept in an array in logical text order.

struct Seg (gettersandsetters) {
	--filled by shaping
	glyph_run_id: int;    --NOTE: negative ids are mapped to layout.embeds.
	line_num: int;        --physical line number
	linebreak: enum;      --for line/paragraph breaking
	bidi_level: int8;     --for bidi reordering
	paragraph_dir: enum;  --computed paragraph bidi dir, for ALIGN_START|END
	span: &Span;          --span of the first sub-segment
	offset: int;          --codepoint offset into the text
	--filled by layouting
	line_index: int;
	x: num;
	advance_x: num; --segment's x-axis boundaries (changes with wrapping)
	next_vis: &Seg; --next segment <<on the same line>> in visual order
	wrapped: bool;  --segment is the last on a wrapped line
	visible: bool;  --segment is not entirely clipped
	subsegs: arr(SubSeg);
}

terra forget_glyph_run :: {&Renderer, int} -> {}

--can't bundle this into Seg:free() because the Seg array doesn't have a Renderer context.
terra Seg:forget_glyph_run(r: &Renderer)
	if self.glyph_run_id < 0 then return end --embed
	forget_glyph_run(r, self.glyph_run_id)
end

terra Seg:free()
	self.subsegs:free()
end

-- A line is the result of line-wrapping the text. line segments can be
-- iterated in visual order via `line.first_vis/seg.next_vis` or in logical
-- order via `line.first/layout.segs:next(seg)`.

struct Line (gettersandsetters) {
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

--iterate a line's segments in visual order.
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

-- A layout is a unit of multi-paragraph rich text to be shaped, layouted,
-- rendered, navigated, hit-tested, edited, updated, re-rendered and so on.

local arr_Span = arr(Span)

struct Layout (gettersandsetters) {
	r: &Renderer;
	spans: arr_Span;        --shape/in
	embeds: arr(Embed);     --shape/in
	text: arr(codepoint);   --shape/in
	align_w: num;           --wrap+align/in
	align_h: num;           --align/in
	align_x: enum;          --align/in
	align_y: enum;          --align/in
	dir: enum;              --shape/in:     default base paragraph direction.
	bidi: bool;             --shape/out:   `true` if the text is bidirectional.
	line_spacing: num;      --spaceout/in:  line spacing multiplication factor (m.f.).
	hardline_spacing: num;  --spaceout/in:  line spacing m.f. for hard-breaked lines.
	paragraph_spacing: num; --spaceout/in:  paragraph spacing m.f.
	clip_x: num;            --clip/in
	clip_y: num;            --clip/in
	clip_w: num;            --clip/in
	clip_h: num;            --clip/in
	x: num;                 --paint/in
	y: num;                 --paint/in
	segs: arr(Seg);         --shape/out
	lines: arr(Line);       --wrap+align/out
	max_ax: num;            --wrap/out:     maximum x-advance
	h: num;                 --spaceout/out: wrapped height.
	spaced_h: num;          --spaceout/out: wrapped height incl. line/paragraph spacing.
	baseline: num;          --spaceout/out: y of first line.
	min_x: num;
	first_visible_line: int; --clip/out
	last_visible_line: int;  --clip/out
	_min_w: num;             --get_min_w/cache
	_max_w: num;             --get_max_w/cache
	tabstops: arr(num);
}

terra arr_Span:free_element(span: &Span)
	span:free(structptr(self, Layout, 'spans').r)
end

--a span's ending offset is the starting offset of the next span.
terra Layout:span_end_offset(span_i: int)
	var next_span = self.spans:at(span_i+1, nil)
	return iif(next_span ~= nil, next_span.offset, self.text.len)
end

terra Layout:init(r: &Renderer)
	fill(self)
	self.r = r
	self.dir      =  DIR_AUTO
	self.align_x  =  ALIGN_CENTER
	self.align_y  =  ALIGN_CENTER
	self.line_spacing      = 1.0
	self.hardline_spacing  = 1.0
	self.paragraph_spacing = 2.0
	self.clip_x   = -inf
	self.clip_y   = -inf
	self.clip_w   =  inf
	self.clip_h   =  inf
end

--glyph run type -------------------------------------------------------------

-- Glyph runs hold the results of shaping individual words and are kept in a
-- special LRU cache that can also ref-count its objects so that they're not
-- evicted from the cache when the cache memory size limit is reached. Segs
-- keep their glyph run alive by holding a ref to it while they're alive.

-- Glyph runs are rasterized on-demand and the images are cached in the
-- `images` array, one image for each subpixel offset, so for a 1/4 subpixel
-- resolution the array will hold at most 4 images at indices 0, 1, 2, 3
-- corresponding to subpixel offsets 0, 1/4, 2/4, 3/4 respectively.
-- Glyph runs are rasterized because cairo is too slow at blitting glyphs
-- individually from their individual image surfaces.

-- The glyphs on RTL runs are reversed (by HarfBuzz) so the `cluser` value
-- is monotonically descending on those as opposed to LTR runs where it is
-- monotonically ascending. In both cases however the cluser represents the
-- _starting_ codepoint that the glyph represents, so eg. in a RTL glyph run
-- with clusters (3, 0), the second glyph represents codepoints (0, 1, 2).

struct GlyphInfo (gettersandsetters) {
	glyph_index: int; --in the font's charmap
	x: num; --glyph origin relative to glyph run's origin
	image_x_16_6: int16; --glyph image origin relative to glyph origin
	image_y_16_6: int16;
	cluster: int8; --offset of starting codepoint that this glyph represents
}
fixpointfields(GlyphInfo)

struct GlyphImage {
	surface: &surface;
 	x: int16; --image coordinates relative to the (first) glyph origin
	y: int16;
}
GlyphImage.empty = `GlyphImage{surface = nil, x = 0, y = 0}

terra GlyphImage:free()
	if self.surface == nil then return end
	self.surface:free()
	self.surface = nil
end

--these arrays hold exactly text.len+1 items, one for each position in
--front of each codepoint plus the position after the last codepoint.
struct Cursors (gettersandsetters) {
	offsets : arr(int8); --navigable offsets, so some are duplicates.
	xs      : arr(num); --x-coords, so some are duplicates.
}

terra Cursors:__memsize()
	return memsize(self.offsets) + memsize(self.xs)
end

terra Cursors:init()
	fill(self)
end

terra Cursors:free()
	self.offsets:free()
	self.xs:free()
end

terra Cursors:get_len()
	return self.offsets.len
end

struct GlyphRun (gettersandsetters) {
	--cache key fields: no alignment holes allowed between fields `lang` and `rtl` !!!
	text            : arr(codepoint);
	features        : hb_feature_arr_t;
	lang            : hb_language_t;     --8
	script          : hb_script_t;       --4
	font_id         : int;               --4
	font_face_index : uint16;            --2
	font_size_16_6  : uint16;            --2
	rtl             : bool;              --1
	--resulting glyphs and glyph metrics
	glyphs          : arr(GlyphInfo);
	--for vertical positioning in horizontal flow
	metrics         : SegMetrics;
	cursors         : Cursors;
	--pre-rendered images for each subpixel offset.
	images          : arr(GlyphImage);
	images_memsize  : int;
	--for cursor positioning and hit testing.
	trailing_space  : bool; --the text includes a trailing space (for wrapping).
}
fixpointfields(GlyphRun)

local key_offset = offsetof(GlyphRun, 'lang')
local key_size = offsetafter(GlyphRun, 'rtl') - key_offset
assert(key_size ==
	  sizeof(hb_language_t)
	+ sizeof(hb_script_t)
	+ sizeof(int)
	+ sizeof(uint16)
	+ sizeof(uint16)
	+ sizeof(bool)) --no gaps

terra GlyphRun:__hash32(h: uint32) --for hashmap
	h = hash(uint32, [&char](self) + key_offset, h, key_size)
	h = hash(uint32, &self.text, h)
	h = hash(uint32, &self.features, h)
	return h
end

terra GlyphRun:__eq(other: &GlyphRun) --for hashmap
	return equal(
			[&char](self)  + key_offset,
			[&char](other) + key_offset, key_size)
		and equal(&self.text, &other.text)
		and equal(&self.features, &other.features)
end

terra GlyphRun:__memsize() --for lru cache
	return
		  memsize(self.text)
		+ memsize(self.features)
		+ memsize(self.glyphs)
		+ memsize(self.images)
		+ memsize(self.cursors)
		+ self.images_memsize
end

terra GlyphRun:free(r: &Renderer)
	self.cursors:free()
	self.text:free()
	self.features:free()
	self.glyphs:free()
	self.images:free()
	fill(self)
end

--glyph type -----------------------------------------------------------------

--besides glyph runs, rasterized glyphs are also cached individually,
--this time without ref counting since rasterization is done on-demand
--on paint(). the same glyph might end up being rasterized multiple times
--once for each subpixel offset encountered.

struct Glyph (gettersandsetters) {
	--cache key fields: no alignment holes allowed between cache key fields !!!
	glyph_index     : uint;        --4
	font_id         : int;         --4
	font_face_index : uint16;      --2
	font_size_16_6  : uint16;      --2
	subpixel_offset_x_8_6 : uint8; --1
	--glyph image
	image: GlyphImage;
}
fixpointfields(Glyph)

Glyph.empty = `Glyph {
	font_id = -1;
	font_face_index = 0;
	font_size_16_6 = 0;
	glyph_index = 0;
	subpixel_offset_x_8_6 = 0;
	image = [GlyphImage.empty];
}

local key_offset = offsetof(Glyph, 'glyph_index')
local key_size = offsetafter(Glyph, 'subpixel_offset_x_8_6') - key_offset
assert(key_size ==
	  sizeof(uint)
	+ sizeof(int)
	+ sizeof(uint16)
	+ sizeof(uint16)
	+ sizeof(uint8)) --no gaps

terra Glyph:__hash32(h: uint32) --for hashmap
	return hash(uint32, [&char](self) + key_offset, h, key_size)
end

terra Glyph:__eq(other: &Glyph) --for hashmap
	return equal(
		[&char](self ) + key_offset,
		[&char](other) + key_offset, key_size)
end

terra Glyph:__memsize() --for lru cache
	return iif(self.image.surface ~= nil,
		1024 + self.image.surface:stride() * self.image.surface:height(), 0)
end

terra Glyph:free(r: &Renderer)
	if self.image.surface == nil then return end
	self.image:free()
end

--cursor type ----------------------------------------------------------------

--live cursor position, valid only on the layout as currently shaped.
struct Pos {
	seg: &Seg;
	i: int;
}

--NOTE: using enlarged types for forward-ABI compat since this is a public struct.
struct CursorState {
	--position in logical text and whether is the first or last visual
	--position in case there's two visual positions for the same offset.
	offset: int;
	which: enum;
	--selection-end position, when selecting text by moving the cursor.
	sel_offset: int;
	sel_which: enum;
	--x-coord to try to go to when navigating vertically.
	x: double;
}

struct Cursor (gettersandsetters) {

	layout: &Layout;
	state: CursorState;

	--park cursor to start or end of text if vertical navigation goes above
	--or beyond available text lines.
	park_home: bool;
	park_end: bool;

	--jump-through same-text-offset cursors: most text editors remove duplicate
	--cursors to keep a 1:1 relationship between text positions and cursor
	--positions, which gets funny with BiDi and you also can't tell if there's
	--a space at the end of a wrapped line or not. OTOH, having two visual
	--positions for the same position in logical text can be confusing too.
	--a third, better way is needed but I haven't found it yet.
	unique_offsets: bool;

	--keep a cursor after the last space char on a wrapped line: this cursor
	--position can be trouble because it is outside the textbox and if there's
	--not enough room on the wrap-side of the textbox it can get clipped out.
	wrapped_space: bool;

	--typing inserts text at cursor rather than writing over the text in front
	--of the cursor (most people don't even know the second way).
	insert_mode: bool;

	--drawing attributes
	caret_visible: bool; --alternate this for blinking.
	caret_opacity: num;
	caret_thickness: num;

	selection_visible: bool;
	selection_color: color;
	selection_opacity: num;
}

Cursor.empty_const = constant(`Cursor {
	layout = nil,
	state = CursorState {
		offset = 0;
		which = 0;
		sel_offset = 0;
		sel_which = 0;
		x = 0;
	},

	park_home = false,
	park_end = false,

	unique_offsets = true,
	wrapped_space = false,
	insert_mode = true,

	caret_visible = true,
	caret_opacity = 1,
	caret_thickness = 1,

	selection_visible = true,
	selection_color = DEFAULT_SELECTION_COLOR,
	selection_opacity = DEFAULT_SELECTION_OPACITY,
})

--renderer type --------------------------------------------------------------

--the renderer manages shared resource like fonts and caches.
--there's usually no point in making more than one of these per thread,
--but using one from multiple threads won't work either.

--seg range, a special type used only by tr_wrap_reorder.t.
struct SegRange {
	left: &Seg;
	right: &Seg;
	prev: &SegRange;
	bidi_level: int8;
}
RangesFreelist = fixedfreelist(SegRange)

GlyphRunCache = lrucache {size_t = int, key_t = GlyphRun, context_t = &Renderer, own_keys = true}
GlyphCache    = lrucache {size_t = int, key_t = Glyph, context_t = &Renderer, own_keys = true}
FontCache     = lrucache {size_t = int, key_t = int, val_t = &Font, own_values = true}

EmbedDrawFunc = {&context, double, double, &Layout, int, &Embed, &Span, bool} -> {}

struct Renderer (gettersandsetters) {

	--rasterizer config
	font_size_resolution: num;
	subpixel_x_resolution: num;
	word_subpixel_x_resolution: num;

	ft_lib: FT_Library;

	load_font           : FontLoadFunc;
	unload_font         : FontUnloadFunc;
	embed_draw_function : EmbedDrawFunc;

	glyphs        : GlyphCache;
	glyph_runs    : GlyphRunCache;
	mem_fonts     : FontCache;
	mmapped_fonts : FontCache;

	--temporary arrays that grow as long as the longest input text.
	cpstack:         arr(codepoint);
	scripts:         arr(hb_script_t);
	langs:           arr(hb_language_t);
	bidi_types:      arr(FriBidiCharType);
	bracket_types:   arr(FriBidiBracketType);
	levels:          arr(int8);
	linebreaks:      arr(char);
	grapheme_breaks: arr(char);
	carets_buffer:   arr(hb_position_t);
	substack:        arr(SubSeg);
	ranges:          RangesFreelist;
	sbuf:            arr(char);
	xsbuf:           arr(double);
	paragraph_dirs:  arr(enum);
	embed_cursors:   Cursors;

	--constants that neeed to be initialized at runtime.
	HB_LANGUAGE_EN: hb_language_t;
	HB_LANGUAGE_DE: hb_language_t;
	HB_LANGUAGE_ES: hb_language_t;
	HB_LANGUAGE_FR: hb_language_t;
	HB_LANGUAGE_RU: hb_language_t;
	HB_LANGUAGE_ZH: hb_language_t;

	paint_glyph_num: int;
}

--common struct API ----------------------------------------------------------

terra Seg:get_rtl()
	return isodd(self.bidi_level)
end

terra Seg:get_is_embed()
	return self.glyph_run_id < 0
end

terra Seg:get_embed_index()
	return -self.glyph_run_id - 1
end

terra Seg:set_embed_index(i: int)
	self.glyph_run_id = -(i + 1)
end

terra Layout:seg_glyph_run(seg: &Seg)
	return &self.r.glyph_runs:pair(seg.glyph_run_id).key
end

terra Layout:seg_embed_or_default(seg: &Seg)
	var embed = self.embeds:at(seg.embed_index, nil)
	return iif(embed ~= nil, embed, &[Embed.empty_const])
end

terra Layout:seg_metrics(seg: &Seg)
	return iif(seg.is_embed,
		self:seg_embed_or_default(seg).metrics,
		self:seg_glyph_run(seg).metrics)
end

terra Renderer:init_embed_cursors()
	var c = &self.embed_cursors
	c.offsets.len = 2
	c.offsets:set(0, 0)
	c.offsets:set(1, 1)
	c.xs.len = 2
end

terra Layout:seg_cursors(seg: &Seg)
	if seg.is_embed then
		var cursors = &self.r.embed_cursors
		var xs = &cursors.xs
		if seg.rtl then
			xs:set(1, 0)
			xs:set(0, seg.advance_x)
		else
			xs:set(0, 0)
			xs:set(1, seg.advance_x)
		end
		return cursors
	else
		return &self:seg_glyph_run(seg).cursors
	end
end

return _M

