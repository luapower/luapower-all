--code editor based on codedit engine.
local codedit = require'codedit'
local view = require'codedit_view'
local str = require'codedit_str'
local glue = require'glue'
local player = require'cplayer'
local cairo = require'cairo'
local ft = require'freetype'
local lib = ft:new()
local winapi = require'winapi'
require'winapi.clipboard'

local view = glue.inherit({
	--font metrics
	font_file = 'Fixedsys',
	--scrollbox options
	vscroll = 'always',
	hscroll = 'auto',
	vscroll_w = 16, --use default
	hscroll_h = 16, --use default
	scroll_page_size = nil,
	--colors
	colors = {
		background = '#080808',
		selection_background = '#999999',
		selection_text = '#333333',
		cursor = '#ffffff',
		text = '#ffffff',
		margin_background = '#000000',
		line_number_text = '#66ffff',
		line_number_background = '#111111',
		line_number_highlighted_text = '#66ffff',
		line_number_highlighted_background = '#222222',
		line_number_separator = '#333333',
		line_highlight = '#222222',
		blame_text = '#444444',
		--lexer styles
		default = '#CCCCCC',
		whitespace = '#000000',
		comment = '#56CC66',
		string = '#FF3333',
		number = '#FF6666',
		keyword = '#FFFF00',
		identifier = '#FFFFFF',
		operator = '#FFFFFF',
		error = '#FF0000',
		preprocessor = '#56CC66',
		constant = '#FF3333',
		variable = '#FFFFFF',
		['function'] = '#FF6699',
		class        = '#FFFF00',
		type         = '#56CC66',
		label        = '#FFFF66',
		regex        = '#FF3333',
	},
	--extras
	eol_markers = true,
	minimap = true,
	smooth_vscroll = false,
	smooth_hscroll = false,
}, view)

function view:draw_scrollbox(x, y, w, h, cx, cy, cw, ch)
	local scroll_x, scroll_y, clip_x, clip_y, clip_w, clip_h = self.player:scrollbox{
		id = self.buffer.editor.id..'_scrollbox',
		x = x,
		y = y,
		w = w,
		h = h,
		cx = cx,
		cy = cy,
		cw = cw,
		ch = ch,
		vscroll = self.vscroll,
		hscroll = self.hscroll,
		vscroll_w = self.vscroll_w,
		hscroll_h = self.hscroll_h,
		page_size = self.scroll_page_size,
		--vscroll_step = self.smooth_vscroll and 1 or self.linesize,
		--hscroll_step = self.smooth_hscroll and 1 or self.charsize,
	}

	--local cr = self.player.cr
	--cr:save()

	--cr:translate(clip_x, clip_y)
	--cr:rectangle(0, 0, clip_w, clip_h)
	--cr:clip()
	--cr:translate(scroll_x, scroll_y)
	--cr:translate(self:margins_width(), 0)

	return scroll_x, scroll_y, clip_x, clip_y, clip_w, clip_h
end

function view:clip(x, y, w, h)
	self.player.cr:reset_clip()
	self.player.cr:rectangle(x, y, w, h)
	self.player.cr:clip()
end

function view:draw_rect(x, y, w, h, color)
	self.player:rect(x, y, w, h, self.colors[color])
end

local cache = {}

function player:clear_glpyh_cache()
	for _,t in pairs(cache) do
		if t.image then
			t.image:free()
			t.bitmap:free(t.library)
		end
	end
	cache = {}
end

function player:render_glyph(face, s, i, glyph_size, x, y)

	--local j = (str.next(s, i) or #s + 1) - 1
	local charcode = s:byte(i,i) --TODO: utf8 -> utf32

	if charcode == nil then return end

	local image, bitmap_left, bitmap_top
	local ci = cache[charcode]
	if ci then
		image, bitmap_left, bitmap_top = ci.image, ci.bitmap_left, ci.bitmap_top
		if not image then return end
	else
		face:select_charmap(ft.FT_ENCODING_UNICODE)
		local glyph_index = face:char_index(charcode)

		local load_mode = bit.bor(ft.FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH, --ft.FT_LOAD_NO_BITMAP,
											ft.FT_LOAD_NO_HINTING, ft.FT_LOAD_NO_AUTOHINT)
		local render_mode = ft.FT_RENDER_MODE_LIGHT

		face:set_char_size(glyph_size * 64)
		face:load_glyph(glyph_index, load_mode)
		local glyph = face.glyph

		if glyph.format ~= ft.FT_GLYPH_FORMAT_BITMAP then
			glyph:render(render_mode)
		end
		assert(glyph.format == ft.FT_GLYPH_FORMAT_BITMAP)

		if glyph.bitmap.width == 0 or glyph.bitmap.rows == 0 then
			cache[charcode] = {}
			return
		end

		local bitmap = glyph.library:new_bitmap()
		glyph.library:convert_bitmap(glyph.bitmap, bitmap, 4)

		local cairo_format = cairo.CAIRO_FORMAT_A8
		local cairo_stride = cairo.cairo_format_stride_for_width(cairo_format, bitmap.width)

		assert(bitmap.pixel_mode == ft.FT_PIXEL_MODE_GRAY)
		assert(bitmap.pitch == cairo_stride)

		image = cairo.cairo_image_surface_create_for_data(
			bitmap.buffer,
			cairo_format,
			bitmap.width,
			bitmap.rows,
			cairo_stride)
		bitmap_left = glyph.bitmap_left
		bitmap_top = glyph.bitmap_top

		cache[charcode] = {
			image = image,
			bitmap = bitmap,
			library = glyph.library,
			bitmap_left = bitmap_left,
			bitmap_top = bitmap_top,
		}
	end
	self.cr:mask_surface(image, x + bitmap_left, y - bitmap_top)
end

function view:draw_char(x, y, s, i, color)
	local cr = self.player.cr
	self.player:setcolor(self.colors[color] or self.colors.text)
	self.player:render_glyph(self.ft_face, s, i, self.line_h, x, y)
end

--draw a reverse pilcrow at eol
function view:render_eol_marker(line)
	local x, y = self:char_coords(line, self.buffer:visual_col(line, self.buffer:last_col(line) + 1))
	local x = x + 2.5
	local y = y + self.char_baseline - self.line_h + 3.5
	local cr = self.player.cr
	cr:new_path()
	cr:move_to(x, y)
	cr:rel_line_to(0, self.line_h - 0.5)
	cr:move_to(x + 3, y)
	cr:rel_line_to(0, self.line_h - 0.5)
	cr:move_to(x - 2.5, y)
	cr:line_to(x + 3.5, y)
	self.player:stroke('#ffffff66')
	cr:arc(x + 2.5, y + 3.5, 4, - math.pi / 2 + 0.2, - 3 * math.pi / 2 - 0.2)
	cr:close_path()
	self.player:fill('#ffffff66')
	cr:fill()
end

function view:render_eol_markers()
	if self.eol_markers then
		local line1, line2 = self:visible_lines()
		for line = line1, line2 do
			self:render_eol_marker(line)
		end
	end
end

function view:render_minimap()
	local cr = self.player.cr
	local mmap = glue.inherit({editor = self}, self)
	local self = mmap
	local scale = 1/6
	self.vscroll = 'never'
	self.hscroll = 'never'
	self.x = 0
	self.y = 0
	self.w = (100 - self.vscroll_w - 4) / scale
	self.h = self.h * 1/scale
	cr:save()
		cr:translate(self.editor.x + self.editor.w - 100, self.editor.y)
		cr:scale(scale, scale)
		codedit.render(self)
		cr:restore()
	cr:restore()
end

local view_render = view.render
function view:render()
	view_render(self)
	self.player.cr:identity_matrix()
	self.player.cr:reset_clip()
end

local editor = glue.inherit({view = view}, codedit)

function editor:render()
	local cr = self.player.cr
	for i = 1,1 do

		if self.view.ft_face_file ~= self.view.font_file then
			if self.view.ft_face then
				self.view.ft_face:free()
			end
			self.view.ft_face = lib:new_face(self.view.font_file)
			self.view.ft_face_file = self.view.font_file
		end

		--self.player:clear_glpyh_cache()

		self.view:render()
		self.view:render_eol_markers()
		--cr:restore()
		if self.view.minimap then
			self.view:render_minimap()
		end
	end
end

function editor:setactive(active)
	self.player.active = active and self.id or nil
end

function editor:set_clipboard(s)
	winapi.SetClipboardText(s)
end

function editor:get_clipboard()
	return winapi.GetClipboardText() or ''
end

function player:code_editor(t)
	local id = assert(t.id, 'id missing')
	local ed = t
	if not t.buffer or not t.buffer.lines then
		t.view = t.view and glue.inherit(t.view, view) or view
		t.cursor = t.cursor and glue.inherit(t.cursor, editor.cursor) or editor.cursor
		ed = editor:new(t)
	end
	ed.player = self
	ed.view.player = self
	ed:input(
		true, --self.focused == ed.id,
		self.active,
		self.key,
		self.char,
		self.ctrl,
		self.shift,
		self.alt,
		self.mousex,
		self.mousey,
		self.lbutton,
		self.rbutton,
		self.wheel_delta,
		self.doubleclicked,
		self.tripleclicked,
		self.quadrupleclicked,
		self.waiting_for_tripleclick)
	ed:render()

	return ed
end

if not ... then require'codedit_demo' end
