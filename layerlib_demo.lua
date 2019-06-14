--go @ luajit -joff -jv *
jit.off(true, true)

local ffi = require'ffi'
local nw = require'nw'
local ll = require'layerlib_h'
local glue = require'glue'
local cairo = require'cairo'

local app = nw:app()

local win = app:window{
	w = 1200, h = 700,
}

local fonts = {
	glue.readfile'media/fonts/OpenSans-Regular.ttf';
	glue.readfile'media/fonts/OpenSans-Bold.ttf';
}

local function load_font(font_id, file_data_buf, file_size_buf)
	local s = assert(fonts[font_id+1])
	file_data_buf[0] = ffi.cast('void*', s)
	file_size_buf[0] = #s
end

local function unload_font(font_id, file_data_buf, file_size_buf)
	file_data_buf[0] = nil
	file_size_buf[0] = 0
end

local s = glue.readfile('lorem_ipsum.txt')

--assert(ll.memtotal() == 0)

local llib = ll.layerlib(load_font, unload_font)
local font1_id = llib:font()
local font2_id = llib:font()
local e = llib:layer(nil)
local e1, e2 = e:child(0), e:child(1)

e.clip_content = ll.CLIP_PADDING
--e.clip_content = ll.CLIP_NONE

e.padding_left   = 50
e.padding_top    = 50
e.padding_right  = 50
e.padding_bottom = 50

--e.border_width_left   =  2
--e.border_width_top    =  2
--e.border_width_right  =  2
--e.border_width_bottom =  2
e.border_color_left   = 0xff00ffff
e.border_color_top    = 0xffff00ff
e.border_color_right  = 0x008800ff
e.border_color_bottom = 0x888888ff
e.corner_radius_bottom_left  = 20
e.corner_radius_bottom_right = 10
e.corner_radius_kappa = 1.2

e.padding = 20
e.border_width = 10
e.border_color = 0xff0000ff

e.background_type = ll.BACKGROUND_COLOR
e.background_color = 0x00336699 --0x336699ff

--e.background_type = ll.background_LINEAR_GRADIENT
e.background_y2 = 100
e:set_background_color_stop_offset(0, 0)
e:set_background_color_stop_offset(1, 1)
e:set_background_color_stop_color(0, 0xff0000ff)
e:set_background_color_stop_color(1, 0x0000ffff)
e.background_x1 = 1

e:set_shadow_x       (0, 6)
e:set_shadow_y       (0, 6)
e:set_shadow_blur    (0, 4)
e:set_shadow_color   (0, 0x000000ff)
e:set_shadow_content (0, false)
e:set_shadow_inset   (0, false)

e:set_shadow_x       (1, 4)
e:set_shadow_y       (1, 4)
e:set_shadow_blur    (1, 0)
e:set_shadow_color   (1, 0xffffffff)
e:set_shadow_content (1, false)
e:set_shadow_inset   (1, false)

e.layout_type = ll.LAYOUT_FLEX
--e.flex_flow = ll.FLEX_FLOW_Y

e1.clip_content = ll.CLIP_BACKGROUND
e2.clip_content = ll.CLIP_PADDING

e2.background_type = ll.BACKGROUND_COLOR
e2.background_color = 0x33333366

e1.border_width = 10; e1.padding = 20
e2.border_width = 10; e2.padding = 20
e1.border_color = 0xffff00ff
e2.border_color = 0x00ff00ff
e1.min_cw = 10; e1.min_ch = 10
e2.min_cw = 10; e2.min_ch = 10

--llib.subpixel_x_resolution = 1/2
--llib.glyph_cache_size = 0
--llib.glyph_run_cache_size = 0

--e1:set_text_utf8(s, -1)
e1:set_text_span_font_id  (0, font1_id)
e1:set_text_span_font_size(0, 14)
e1:set_text_span_color    (0, 0xffffffff)
e1.text_align_y = ll.ALIGN_TOP
e1.text_align_x = ll.ALIGN_RIGHT

e1:set_shadow_x       (2, 1)
e1:set_shadow_y       (2, 1)
e1:set_shadow_blur    (2, 1)
e1:set_shadow_color   (2, 0x000000ff)
e1:set_shadow_content (2, true)
e1:set_shadow_inset   (2, false)

--e1.visible = false
--e2.visible = false

do local e = e2
--e:set_text_utf8('Yea but it\'s live!!', -1)
e:set_text_span_font_id  (0, font2_id)
e:set_text_span_font_size(0, 100)
e:set_text_span_color    (0, 0x333333ff)
e.text_align_y = ll.ALIGN_CENTER
e.text_align_x = ll.ALIGN_CENTER

e:set_shadow_x       (0, 0)
e:set_shadow_y       (0, 1)
e:set_shadow_blur    (0, 2)
e:set_shadow_color   (0, 0x000000ff)
e:set_shadow_content (0, true)
e:set_shadow_inset   (0, true)

e:set_shadow_x       (1, 0)
e:set_shadow_y       (1, 1)
e:set_shadow_blur    (1, 1)
e:set_shadow_color   (1, 0x888888ff)
e:set_shadow_content (1, true)
e:set_shadow_inset   (1, false)
end

function win:repaint()

	local cr = self:bitmap():cairo()

	cr:identity_matrix()
	cr:rgba(1, 1, 1, 1)
	cr:paint()

	local w, h = self:client_size()
	cr:translate(50, 50)
	e:sync(w - 100, h - 100)
	--print'synced'
	e:draw(cr)

	--e1:set_text_utf8('', -1)
	--e:clear_text_runs()
end

function win:keyup(key)
	if key == 'esc' then
		self:close()
	end
end

app:run()

e:free()
e1:free()
e2:free()

llib:dump_stats()
llib:free()
ll.memreport()
assert(ll.memtotal() == 0)
