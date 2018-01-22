local glue = require'glue'
local ffi = require'ffi'
local ft = require'freetype'
local player = require'cplayer'
local cairo = require'cairo'

local load_mode = bit.bor(ft.FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH, ft.FT_LOAD_NO_BITMAP,
									ft.FT_LOAD_NO_HINTING, ft.FT_LOAD_NO_AUTOHINT)
local render_mode = ft.FT_RENDER_MODE_LIGHT

function player:render_glyph(face, glyph_index, glyph_size, x, y, t, i)

	face:set_char_size(glyph_size * 64)
	face:load_glyph(glyph_index, load_mode)
	local glyph = face.glyph

	if glyph.format ~= ft.FT_GLYPH_FORMAT_BITMAP then
		glyph:render(render_mode)
	end
	assert(glyph.format == ft.FT_GLYPH_FORMAT_BITMAP)

	local bitmap = glyph.bitmap

	if bitmap.width == 0 or bitmap.rows == 0 then
		return
	end

	if bitmap.pitch % 4 ~= 0 or bitmap.pixel_mode ~= ft.FT_PIXEL_MODE_GRAY then
		bitmap = glyph.library:bitmap()
		glyph.library:convert_bitmap(glyph.bitmap, bitmap, 4)
	end
	local cairo_format = 'a8'
	local cairo_stride = cairo.stride('a8', bitmap.width)

	assert(bitmap.pixel_mode == ft.FT_PIXEL_MODE_GRAY)
	assert(bitmap.pitch == cairo_stride)

	local image = cairo.image_surface{
		data = bitmap.buffer,
		format = 'g8',
		w = bitmap.width,
		h = bitmap.rows,
		stride = cairo_stride,
	}

	x = x + glyph.bitmap_left
	y = y - glyph.bitmap_top

	if t.draw_bg then
		self:rect(x, y, bitmap.width, bitmap.rows, 'faint_bg')
	end

	self:setcolor'normal_fg'
	self.cr:mask(image, x, y)

	image:free()
	if glyph.bitmap ~= bitmap then
		glyph.library:free_bitmap(bitmap)
	end
end

--same thing, diff. API
function player:render_glyph2(face, glyph_index, glyph_size, x, y, t, i)

	face:set_char_size(glyph_size * 64)
	face:load_glyph(glyph_index, load_mode)
	local ft_glyph = face.glyph:glyph():to_bitmap(render_mode, nil, true)
	local bitmap = ft_glyph:as_bitmap().bitmap
	if bitmap.width == 0 or bitmap.rows == 0 then
		return
	end
	local old_bitmap = bitmap
	if bitmap.pitch % 4 ~= 0 or bitmap.pixel_mode ~= ft.FT_PIXEL_MODE_GRAY then
		bitmap = face.glyph.library:bitmap()
		face.glyph.library:convert_bitmap(old_bitmap, bitmap, 4)
	end

	local cairo_stride = cairo.stride('a8', bitmap.width)
	assert(bitmap.pixel_mode == ft.FT_PIXEL_MODE_GRAY)
	assert(bitmap.pitch == cairo_stride)

	local image = cairo.image_surface{
		data = bitmap.buffer,
		format = 'g8',
		w = bitmap.width,
		h = bitmap.rows,
		stride = cairo_stride,
	}

	x = x + ft_glyph:as_bitmap().left
	y = y - ft_glyph:as_bitmap().top

	if t.draw_bg then
		self:rect(x, y, bitmap.width, bitmap.rows, 'faint_bg')
	end

	self:setcolor'normal_fg'
	self.cr:mask(image, x, y)

	image:free()
	if old_bitmap ~= bitmap then
		face.glyph.library:free_bitmap(bitmap)
	end
	ft_glyph:free()
end

local function boxes_intersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	return ax2 >= bx1 and ax1 <= bx2 and ay2 >= by1 and ay1 <= by2
end

local function glyphs_per_line(cell_size, line_width)
	return math.floor(line_width / cell_size - 0.75)
end

local function charmap_height(glyph_count, cell_size, line_width)
	local n = glyphs_per_line(cell_size, line_width)
	return math.ceil(glyph_count / n) * cell_size + cell_size / 2
end

local i = 0
function player:charmap(face, glyph_size, cell_size, x0, y0, bx1, by1, bx2, by2, t)
	i = i + 1
	local row, col = 0, 0
	local cols = glyphs_per_line(cell_size, bx2 - bx1)
	for char, glyph_index in face:chars() do
		local x = x0 + col * cell_size
		local y = y0 + row * cell_size
		if boxes_intersect(x, y, x + glyph_size, y + glyph_size, bx1, by1, bx2, by2) then
			self:rect(x, y, cell_size, cell_size, nil, 'normal_fg', 0.1)
			self:render_glyph2(face, glyph_index, glyph_size, x, y + cell_size, t, i)
			self:rect(
				x + face.glyph.advance.x / 64,
				y + cell_size - face.glyph.advance.y / 64,
				2, 2, 'error_bg')
			self:rect(
				x + face.glyph.linearHoriAdvance / 0xffff,
				y + cell_size - face.glyph.linearVertAdvance / 0xffff,
				4, 4, 'error_bg')
			self:rect(
				x + face.glyph.metrics.horiAdvance / 64,
				y + cell_size - face.glyph.metrics.vertAdvance / 64,
				4, 4, 'error_bg')
			self:rect(
				x + face.glyph.metrics.horiBearingX / 64,
				y + cell_size - face.glyph.metrics.horiBearingY / 64,
				4, 4, 'error_bg')
			--self:rect(
				--x + face.glyph.metrics.vertBearingX / 64,
				--y + cell_size - face.glyph.metrics.vertBearingY / 64,
				--4, 4, 'error_bg')
		end
		col = col + 1
		if col >= cols then
			col = 0
			row = row + 1
		end
	end
end

--fonts
local faces = {
	['Amiri Regular'] = 'media/fonts/amiri-regular.ttf',
	['DejaVu Serif']  = 'media/fonts/DejaVuSerif.ttf',
	['Firefly Sung']  = 'media/fonts/fireflysung.ttf',
}

--metrics
local button_h = 22
local scroll_w = 16
local charmap_x = 40
local charmap_y = 40
local fade_y = 10 + 2 + button_h
local fade_h = 20

--state
local theme = 'dark'
local glyph_size = 64
local cell_size = 96
local charmap = 0
local scroll = 0
local facefile = faces['Amiri Regular']
local draw_bg = false

local lib = ft:new()

local function mbutton_values(t)
	local names = glue.keys(t); table.sort(names)
	local values, texts = {}, {}
	for i,name in ipairs(names) do
		local v = t[name]
		values[i] = v
		texts[v] = name
	end
	return values, texts
end

local dark = true

function player:on_render(cr)

	--parametrization

	dark = self:togglebutton{id = 'dark', x = 10, y = 10, w = 60, h = button_h,
										text = dark and 'lights on' or 'lights off', selected = dark}
	self.theme = self.themes[dark and 'dark' or 'light']

	draw_bg = self:togglebutton{id = 'bg', x = 80, y = 10, w = 40, h = button_h,
										text = 'bg', selected = draw_bg}

	local old_glyph_size = glyph_size

	if self.char == '+' then
		glyph_size = glyph_size * 1.5
	elseif self.char == '-' then
		glyph_size = glyph_size / 1.5
	end
	glyph_size = self:slider{id = 'glyph_size', text = 'glyph size', x = 140, y = 10, w = 100, h = button_h,
									i = glyph_size, i0 = 32, i1 = 400}
	if glyph_size ~= old_glyph_size then
		cell_size = glyph_size
	end
	cell_size = self:slider{id = 'cell_size', text = 'cell size', x = 250, y = 10, w = 100, h = button_h,
									i = cell_size, i0 = glyph_size, i1 = 400}

	local values, texts = mbutton_values(faces)
	local old_facefile = facefile
	facefile = self:mbutton{id = 'face', x = 360, y = 10, w = #values * 80, h = button_h,
									values = values, texts = texts, selected = facefile}
	if old_facefile ~= facefile then
		charmap = 0
	end
	local face = lib:face(facefile)

	local values, texts = {}, {}
	for i=1,face.num_charmaps do
		local v = i-1
		values[i] = v
		texts[v] = 'Charmap '..tostring(i)
	end

	charmap = self:mbutton{id = 'charmap', x = 610, y = 10, w = #values * 80, h = button_h,
									values = values, texts = texts, selected = charmap}

	face:select_charmap(face.charmaps[charmap].encoding)

	--measure and scroll

	local glyph_count = face:char_count()
	local charmap_h = charmap_height(glyph_count, cell_size, self.w - scroll_w)
	local page_size = cell_size * 4
	local line_size = cell_size / 2

	scroll = scroll - self.wheel_delta * page_size

	if self.key == 'pagedown' or self.key == 'right' then
		scroll = scroll + page_size
	elseif self.key == 'pageup' or self.key == 'left' then
		scroll = scroll - page_size
	elseif self.key == 'down' then
		scroll = scroll + line_size
	elseif self.key == 'up' then
		scroll = scroll - line_size
	elseif self.key == 'home' then
		scroll = 0
	elseif self.key == 'end' then
		scroll = math.huge
	end

	scroll = self:vscrollbar{id = 'scrollbar', x = self.w - scroll_w, y = charmap_y,
										w = scroll_w, h = self.h - charmap_y, size = charmap_h, i = scroll, autohide = false}

	--draw the charmap in a clip rectangle

	self.cr:rectangle(0, fade_y, self.w, self.h - fade_y)
	self.cr:save()
	self.cr:clip()
	self:charmap(face, glyph_size, cell_size,
		charmap_x, -scroll + charmap_y,
		charmap_x, charmap_y, charmap_x + self.w - scroll_w, charmap_y + self.h,
		{draw_bg = draw_bg})
	self.cr:restore()

	--draw a gradient over the top of the charmap for kicks
	do
		local gradient = cairo.linear_gradient(0, fade_y, 0, fade_y + fade_h)
		local r,g,b = self:parse_color(self.theme.window_bg)
		gradient:add_color_stop(0.5, r,g,b,1)
		gradient:add_color_stop(1.0, r,g,b,0)
		self.cr:source(gradient)
		self.cr:rectangle(0, fade_y, self.w - scroll_w, fade_h)
		self.cr:fill()
		gradient:unref()
	end

	face:free()
end

player:play()

lib:free()
