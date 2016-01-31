local ffi = require'ffi'
local hb = require'harfbuzz'
local ft = require'freetype'
local cairo = require'cairo'

local player = require'cplayer'

local function shape_text(s, ft_face, hb_font, size, direction, script, language, features)
	local buf = hb.hb_buffer_create()
	buf:set_direction(direction or hb.HB_DIRECTION_LTR)
	buf:set_script(script or hb.HB_SCRIPT_UNKNOWN)
	if language then buf:set_language(language) end
	buf:add_utf8(s)
	local feats, feats_count = nil, 0
	if features then
		for _ in pairs(features) do feats_count = feats_count + 1 end
		feats = ffi.new('hb_feature_t[?]', feats_count)
		local i = 0
		for k,v in pairs(features) do
			assert(hb.hb_feature_from_string(k, #k, feats[i]) == 1)
			feats[i].value = v
			i = i + 1
		end
	end

	ft_face:set_char_size(size * 64)
	buf:shape(hb_font, feats, feats_count)
	local glyph_count = buf:get_length()
	local glyph_info  = buf:get_glyph_infos()
	local glyph_pos   = buf:get_glyph_positions()
	local cairo_glyphs = ffi.new('cairo_glyph_t[?]', glyph_count)
	local x, y = 0, 0
	for i=0,glyph_count-1 do
		cairo_glyphs[i].index = glyph_info[i].codepoint
		cairo_glyphs[i].x = x + glyph_pos[i].x_offset / 64
		cairo_glyphs[i].y = y - glyph_pos[i].y_offset / 64
		x = x + glyph_pos[i].x_advance / 64
		y = y - glyph_pos[i].y_advance / 64
	end
	buf:destroy()

	return cairo_glyphs, glyph_count
end

function player:draw_glyphs(x, y, cairo_glyphs, glyph_count, cairo_face, size, use_show_glyphs)
	local cr = self.cr
	cr:translate(x, y)
	cr:font_face(cairo_face)
	cr:font_size(size)
	self:setcolor'normal_fg'
	if use_show_glyphs then
		cr:show_glyphs(cairo_glyphs, glyph_count); --NOTE: does not support subpixel positioning
	else
		cr:glyph_path(cairo_glyphs, glyph_count); cr:fill() --NOTE: extremely slow but supports subpixel positioning
	end
	cr:font_face(cairo.NULL)
	cr:translate(-x, -y)
end

function player:draw_text(x, y, s, font, size, direction, script, language, features, use_show_glyphs)
	local glyphs, glyph_count = shape_text(s, font.ft_face, font.hb_font, size, direction, script, language, features)
	self:draw_glyphs(x, y, glyphs, glyph_count, font.cairo_face, size, use_show_glyphs)
end

local ft_lib = ft.FT_Init_FreeType()
ffi.gc(ft_lib, nil)

local function font(filename, load_flags)
	local ft_face = ft_lib:new_face(filename)
	local cairo_face = cairo.ft_font_face(ft_face, load_flags or 0)
	local hb_font = hb.hb_ft_font_create(ft_face, nil)
	ffi.gc(ft_face, nil)
	ffi.gc(cairo_face, nil)
	ffi.gc(hb_font, nil)
	return {ft_face = ft_face, cairo_face = cairo_face, hb_font = hb_font}
end

local amiri = font'media/fonts/amiri-regular.ttf'
local dejavu_hinted = font'media/fonts/DejaVuSerif.ttf'
local dejavu_nohint = font('media/fonts/DejaVuSerif.ttf', ft.FT_LOAD_NO_HINTING)
local dejavu_autohint = font('media/fonts/DejaVuSerif.ttf', ft.FT_LOAD_FORCE_AUTOHINT)

local dark = true
local selected_font = dejavu_hinted
local antialias = 'default'
local sub = 0
local font_options = cairo.font_options()
local lcd_filter = 'default'
local round_glyph_pos = 'off'
local use_show_glyphs = true

function player:on_render(cr)

	dark = self:togglebutton{id = 'dark', x = 10, y = 10, w = 60, h = 24,
										text = dark and 'lights on' or 'lights off', selected = dark}
	self.theme = self.themes[dark and 'dark' or 'light']

	antialias = self:mbutton{id = 'antialias',
		x = 100, y = 40, w = 600, h = 24,
		values = {
			'default',
			'none',
			'gray',
			'subpixel',
			'fast',
			'good',
			'best',
		},
		selected = antialias}

	round_glyph_pos = self:mbutton{id = 'round_glyph_pos',
		x = 410, y = 10, w = 200, h = 24,
		values = {'on', 'off'},
		texts = {on = 'round glyph pos', off = 'exact glyph pos'},
		selected = round_glyph_pos}

	lcd_filter = self:mbutton{id = 'lcd_filter',
		x = 620, y = 10, w = 400, h = 24,
		values = {
			'default',
			'none',
			'intra_pixel',
			'fir3',
			'fir5',
		},
		selected = lcd_filter}

	use_show_glyphs = self:mbutton{id = 'use_show_glyphs', x = 710, y = 40, w = 300, h = 24,
											values = {true, false},
											texts = {[true] = 'cairo_show_glyphs', [false] = 'cairo_glyph_path'},
											selected = use_show_glyphs}

	cr:antialias(antialias)
	font_options:lcd_filter(lcd_filter)
	font_options:antialias(antialias)
	font_options:round_glyph_positions(round_glyph_pos)
	cr:font_options(font_options)

	selected_font = self:mbutton{id = 'font',
		x = 100, y = 10, w = 300, h = 24,
		multiselect = false,
		values = {dejavu_hinted, dejavu_nohint, dejavu_autohint},
		texts = {[dejavu_hinted] = 'hinted', [dejavu_nohint] = 'unhinted', [dejavu_autohint] = 'autohinted'},
		selected = selected_font}

	self:draw_text(100, 150, "هذه هي بعض النصوص العربي", amiri, 40,
							hb.HB_DIRECTION_RTL, hb.HB_SCRIPT_ARABIC, 'ar', nil, use_show_glyphs)

	local y = 0
	for i=6,26 do
		self:draw_text(100 + sub, 200 + y, 'iiiiiiiiii - Te VA - This is Some English Text - Jumped', selected_font, i,
							hb.HB_DIRECTION_LTR, hb.HB_SCRIPT_LATIN, 'en', nil, use_show_glyphs)
		y = y + i
	end
	sub = sub + 1/256
end

player:play()

