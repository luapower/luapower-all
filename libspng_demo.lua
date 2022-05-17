local spng = require'libspng'
local testui = require'testui'
local glue = require'glue'
local fs = require'fs'
local ffi = require'ffi'
require'unit' --dir

local filesets = {
	good_files = dir'media/png/good/*.png',
	bad_files = dir'media/png/bad/*.png',
}
local files = 'good_files'
local bottom_up = false
local stride_aligned = false
local max_cut_size = 1024 * 6
local cut_size = max_cut_size
local pixel_formats = {bgra8 = true}
local gamma = false

function testui:repaint()

	self:checkerboard()

	self:pushgroup'right'
	local _
	_,files          = self:choose('files', {'good_files', 'bad_files'}, files)
	_,bottom_up      = self:button('bottom_up', bottom_up)
	_,stride_aligned = self:button('stride_aligned', stride_aligned)
	_,cut_size       = self:slide('cut_size', cut_size, 0, max_cut_size, 1)
	_,pixel_formats  = self:choose('format', {
		'rgb8', 'rgba8', 'bgra8', 'rgba16', 'g8', 'ga8', 'ga16',
	}, pixel_formats)
	_,gamma          = self:button('gamma', gamma)
	self:nextgroup()

	for i,path in ipairs(filesets[files]) do

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

		local img, bmp, err
		img, err = spng.open{read = read}
		if img then
			bmp, err = img:load{
				accept = glue.update({
					bottom_up = bottom_up,
					stride_aligned = stride_aligned,
				}, pixel_formats),
				gamma = gamma,
			}
		end

		if bmp and self.x + bmp.w >= self.window:client_size() then --wrap
			self:nextgroup()
		end

		if bmp then

			self:pushgroup'down'
			self:label(img.format)
			self:image(bmp)
			self:label(bmp.format)
			self:popgroup()
			self:rect(0, bmp.h * 2.5)

		else
			--self:rect(cx, cy, w, h, 'error_bg')
			--self:textbox(cx, cy, w, h,
			--	string.format('%s', err:match('^(.-)\n'):match(': ([^:]-)$')),
			--	14, 'normal_fg', 'center', 'center')
		end

		if img then img:free() end
	end
end

testui:init()
testui:continuous_repaint(1/0)
testui:run()
