local player = require'cplayer'
local giflib = require'giflib'
local cairo = require'cairo'
local glue = require'glue'
local ffi = require'ffi'

require'unit'

local files = dir'media/gif/*'

local white_bg = false
local source_type = 'path'
local opaque = false
local max_cutsize = 65536
local cut_size = max_cutsize
local frame_state = {} --{[filename] = {frame = <current_frame_no>, time = <next_frame_time>}

function player:on_render(cr)

	self:checkerboard()

	white_bg = self:mbutton{
		id = 'white_bg', x = 10, y = 10, w = 130, h = 24,
		texts = {[true] = 'white bg', [false] = 'dark bg'},
		values = {true, false},
		selected = white_bg}

	self.theme = self.themes[white_bg and 'light' or 'dark']

	source_type = self:mbutton{
	id = 'source_type', x = 150, y = 10, w = 290, h = 24,
	values = {'path', 'cdata', 'string'},
	selected = source_type}

	if source_type ~= 'path' then
		cut_size = self:slider{
			id = 'cut_size', x = 700, y = 10, w = 190, h = 24,
			i0 = 0, i1 = max_cutsize, i = cut_size,
			text = 'cut size'}
	end

	opaque = self:mbutton{
		id = 'mode', x = 450, y = 10, w = 190, h = 24,
		texts = {[true] = 'opaque', [false] = 'transparent'},
		values = {true, false},
		selected = opaque}

	local cx, cy = 0, 40
	local maxh = 0

	for i,filename in ipairs(files) do

		local t = {}
		if source_type == 'path' then
			t.path = filename
		elseif source_type == 'cdata' then
			local s = glue.readfile(filename)
			s = s:sub(1, cut_size)
			local cdata = ffi.new('unsigned char[?]', #s+1, s)
			t.cdata = cdata
			t.size = #s
		elseif source_type == 'string' then
			local s = glue.readfile(filename)
			s = s:sub(1, cut_size)
			t.string = s
		end
		t.opaque = opaque

		local ok,err = pcall(function()

			local gif = giflib.load(t)

			local state = frame_state[filename]
			if not state then
				state = {frame = 0, time = 0}
				frame_state[filename] = state
			end

			local image
			if self.clock >= state.time then
				state.frame = state.frame + 1
				if state.frame > #gif.frames then
					state.frame = 1
				end
				image = gif.frames[state.frame]
				state.time = self.clock + (image.delay_ms or 0) / 1000
			else
				image = gif.frames[state.frame]
			end

			if cx + gif.w > self.w then
				cx = 0
				cy = cy + maxh + 10
				maxh = 0
			end

			self:image{x = cx + image.x, y = cy + image.y, image = image}

			cx = cx + gif.w + 10
			maxh = math.max(maxh, gif.h)
		end)

	end
end

player:play()

