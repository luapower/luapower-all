--go @ luajit -jp *
local time = require'time'
local ui = require'ui'
local color = require'color'
ui.use_google_fonts = true
ui = ui()

local win = ui:window{
	w = 800, h = 600,
	--transparent = true, frame = false,
}

function win:keydown(key)
	if key == 'esc' then
		self:close()
	end
end

win.view.padding = 20

local scale = 2
local pad = 0

local function test_layerlib()

	local layer = ui:layer{

		parent = win,

		--interdependent properties: test that init order is stable
		cx = 100 * scale,
		cy = 100 * scale,
		x = 0, y = 0,
		w = 0, h = 0,
		cw = 200 - pad * 2,
		ch = 200 - pad * 2,

		--has no effect on null layouts
		min_cw = 400,
		min_ch = 300,

		--padding_left = 20,
		padding = pad,

		rotation = 0,
		rotation_cx = -80,
		rotation_cy = -80,

		--scale = scale,
		scale_cx = 100,
		scale_cy = 100,

		snap_x = true,
		snap_y = false,

		clip_content = 'padding',
		opacity = .8,
		--operator = 'xor',

		--border_width_right = 1,
		border_width = 10,
		--border_color_left = '#f00',
		border_color = '#fff',
		corner_radius_bottom_right = 30,
		corner_radius = 5,

		border_dash = {4, 3},
		border_dash_offset = 1,

		--background_type = 'color',
		background_color = '#639',

		background_type = 'gradient',
		background_x1 = 0,
		background_y1 = 0,
		background_x2 = 0,
		background_y2 = 1,
		background_r1 = 50,
		background_r2 = 100,
		background_color_stops = {0, '#f00', .5, '#00f'},

		background_hittable = false,
		background_operator = 'xor',
		background_clip_border_offset = 0,

		background_x = 50,
		background_y = 50,

		background_rotation    = 10,
		background_rotation_cx = 10,
		background_rotation_cy = 10,

		background_scale = 100,
		background_scale_cx = 40,
		background_scale_cy = 40,
		background_extend   = 'reflect',

		text = 'Hello',
		font = 'Open Sans Bold',
		font_size = 100,

		script = 'Zyyy',
		lang   = 'en-us',
		dir    = 'ltr',

		nowrap = true,
		line_spacing = 1.2,
		hardline_spacing = 2,
		paragraph_spacing = 3,

		text_opacity = .8,
		text_color = '#ff0',
		--text_operator = 'xor',

		text_align_x = 'right',
		text_align_y = 'bottom',

		shadow_color = '#000',
		shadow_x = 2,
		shadow_y = 2,
		shadow_blur = 1,
		shadow_content = true,
		shadow_inset = true,

		--layout = 'textbox',

	}

end

local function test_flex()

	win.view.layout = 'flexbox'

	local flex = ui:layer{
		parent = win,
		layout = 'flexbox',
		flex_wrap = true,
		--flex_flow = 'y',
		item_align_y = 'center',
		align_items_y = 'start',
		border_width = 20,
		padding = 20,
		border_color = '#333',
		snap_x = false,
		clip_content = true,

		x = 40, y = 40,
		min_cw = win.cw - 120 - 40,
		min_ch = win.ch - 120 - 40,
	}

	for i = 1, 100 do
		local r = math.random(10)
		local b = ui:layer{
			parent = flex,
			layout = 'textbox',
			border_width = 1,
			min_cw = r * 12,
			min_ch = r * 6,
			--break_after = i == 50,
			--break_before = i == 50,
			--fr = r,
			--font_size = 10 + i * 3,
		}
	end

end

local function test_grid()

	win.view.layout = 'flexbox'

	local grid = ui:layer{
		parent = win,

		layout = 'grid',
		item_align_y = 'center',
		item_align_x = 'center',
		--align_items_y = 'start',
		--align_items_x = 'stretch',

		--grid_flow = 'yrb',
		grid_wrap = 6,
		grid_min_lines = 3,
		grid_col_gap = 1,
		grid_row_gap = 4,
		grid_col_frs = {3, 1, 2},
		grid_row_frs = {2, 1, 2},

		border_width = 20,
		padding = 20,
		border_color = '#333',
		--clip_content = true,

	}

	for i = 1, 15 do
		local r = math.random(30)
		local b = ui:layer{
			parent = grid,

			--align_x = 'right',

			layout = 'textbox',
			text_align_y = 'bottom',

			--grid_row = i,
			grid_col = -i,

			min_cw = r * 3,
			min_ch = r * 2,

			border_width = 1,

			snap_x = false,
		}
	end

end

------------------------------------------------------------------------------

local function fps_function()
	local count_per_sec = 2
	local frame_count, last_frame_count, last_time = 0, 0
	return function()
		last_time = last_time or time.clock()
		frame_count = frame_count + 1
		local time = time.clock()
		if time - last_time > 1 / count_per_sec then
			last_frame_count, frame_count = frame_count, 0
			last_time = time
		end
		return last_frame_count * count_per_sec
	end
end

function win:before_draw()
	self:invalidate()
end

local fps = fps_function()

win.native_window:on('repaint', function(self)
	self:title(string.format('%d fps', fps()))
end)

--keep showing fps in the titlebar every second.
ui:runevery(1, function()
	if win.dead then
		ui:quit()
	else
		win:invalidate()
	end
end)


--test_layerlib()
--test_flex()
test_grid()

ui:run()

ui:free()

require'layerlib_h'.memreport()

--[[

		set_border_line_to=1,

		get_background_image=1,
		set_background_image=1,

		--text

		get_text_span_feature_count=1,
		clear_text_span_features=1,
		get_text_span_feature=1,
		add_text_span_feature=1,

		text_caret_width=1,
		text_caret_color=1,
		text_caret_insert_mode=1,
		text_selectable=1,


]]
