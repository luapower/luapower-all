
local giflib = require'giflib'
local ffi = require'ffi'
local fs = require'fs'
local testui = require'testui'

local white_bg = false
local max_cutsize = 65536
local cut_size = max_cutsize
local opaque = false
local bottom_up = false
local stride_aligned = false
local frame_state = {} --{[filename] = {frame = <current_frame_no>, time = <next_frame_time>}

function testui:repaint()

	self:checkerboard()

	self:pushgroup'down'

	self:pushgroup'right'
	self.min_w = 100

	local _
	_,cut_size  = self:slide('cut_size', 'cut size', cut_size, 0, max_cutsize, 1)
	_,opaque    = self:button('opaque', opaque)
	_,bottom_up = self:button('bottom_up', bottom_up)
	_,stride_aligned = self:button('stride_aligned', stride_aligned)

	self:nextgroup()
	self.y = self.y + 10

	for filename in fs.dir'media/gif' do
		local path = 'media/gif/'..filename

		local f = assert(fs.open(path))
		local bufread = f:buffered_read()
		local left = cut_size
		local function read(buf, sz)
			if left == 0 then return 0 end
			local readsz, err = bufread(buf, math.min(left, sz))
			if not readsz then return nil, err end
			left = left - readsz
			return readsz
		end

		local gif, err = giflib.open{read = read}
		if not gif then
			f:close()
			goto skip
		end

		local frames, err = gif:load{opaque = opaque,
			accept = {bottom_up = bottom_up, stride_aligned = stride_aligned}}
		if not frames then
			gif:free()
			f:close()
			goto skip
		end

		local state = frame_state[filename]
		if not state then
			state = {frame = 0, clock = 0}
			frame_state[filename] = state
		end

		local image
		if self.clock >= state.clock then
			state.frame = state.frame + 1
			if state.frame > #frames then
				state.frame = 1
			end
			image = frames[state.frame]
			state.clock = self.clock + (image.delay or 0)
		else
			image = frames[state.frame]
		end

		if self.x + image.w >= self.window:client_size() then --wrap
			self:nextgroup()
		end

		self:image(image)

		gif:free()
		f:close()

		::skip::
	end

	collectgarbage()
end

testui:init()
testui:continuous_repaint(true)
testui:run()
