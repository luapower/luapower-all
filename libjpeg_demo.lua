local libjpeg = require'libjpeg'
local testui = require'testui'
local glue = require'glue'
local fs = require'fs'
local ffi = require'ffi'

require'unit'

local filesets = {}
filesets.test = dir'media/jpeg/test*'
table.remove(filesets.test, glue.indexof('media/jpeg/testimgari.jpg', filesets.test))
filesets.progressive = {'media/jpeg/progressive.jpg'}
filesets.cmyk = {'media/jpeg/cmyk.jpg'} --test skip bytes with this one
filesets.birds = {'media/jpeg/birds.jpg'}
filesets.autumn = {'media/jpeg/autumn-wallpaper.jpg'}
filesets.arith_decoding = {'media/jpeg/testimgari.jpg'} --no i/o suspension with this one :(
local fileset = 'test'

--gui options
local formats = {ycc8 = true}
local max_cut_size = 1024 * 1024
local cut_size = max_cut_size --truncate input file to size to test progressive mode

--jpeg options
local source_type = 'path'
local dct_method = 'accurate'
local fancy_upsampling = false
local block_smoothing = false
local partial = true
local bottom_up = false
local stride_aligned = false

function testui:repaint()

	self:pushgroup'right'
	local _
	_,fileset      = self:choose('file set', {
		'test', 'progressive', 'cmyk', 'birds', 'autumn', 'arith_decoding',
	}, fileset)
	_,partial      = self:button('partial loading', partial)
	self:nextgroup()
	self.min_w = self.cw - 2 * self.x
	_,cut_size     = self:slide ('file cut', cut_size, 0, max_cut_size, 1)
	self.min_w = 18
	self:nextgroup()
	_,dct_method   = self:choose('dct', {'accurate', 'fast', 'float'}, dct_method)
	_,fancy_upsampling = self:button('fancy upsampling', fancy_upsampling)
	_,block_smoothing  = self:button('block smoothing', block_smoothing)
	_,formats = self:choose('format', {
		'rgb8', 'bgr8', 'rgba8', 'bgra8', 'argb8',
		'abgr8', 'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
		'g8', 'ga8', 'ag8', 'ycc8', 'ycck8', 'cmyk8',
	}, formats)
	_, bottom_up = self:button('bottom_up', bottom_up)
	_,stride_aligned = self:button('stride_aligned', stride_aligned)
	self:nextgroup()

	local last_image, maxh
	for i,filename in ipairs(filesets[fileset]) do

		local rendered_once
		local function render_scan(image, last_scan, scan_number, err)

			--if not last_scan then return end
			rendered_once = true
			local w, h = 300, 100
			if image then
				w, h = image.w, image.h
			end

			if self.x + w >= self.cw then --wrap
				self:nextgroup()
			end

			if image then

				local x, y = self.x, self.y

				self:image(image)

				self:text(string.format('scan %d', scan_number),
					'left', 'top', x, y, w, h)

				self:text(image.format .. (image.format ~= image.format and
					' -> ' .. image.format or ''),
					'center', 'center', x, y, w, h)

				if image.partial then
					self:text('partial', 'right', 'top', x, y, w, h)
				end
			else
				local x, y, w, h = self:rect(w, h)
				self:box(x, y, w, h, '#f00')
				self:text(string.format('%s', err:match(': ([^:]-)$')),
					'center', 'center', x, y, w, h)
			end

		end

		local f = assert(fs.open(filename))
		local bufread = f:buffered_read()
		local left = cut_size
		local function read(buf, sz)
			if left == 0 then return 0 end
			local readsz, err = bufread(buf, math.min(left, sz))
			if not readsz then return nil, err end
			left = left - readsz
			return readsz
		end

		local img, err = libjpeg.open{
			read = read,
			skip_buffer = false,
			accept = glue.update({
				stride_aligned = stride_aligned,
				bottom_up = bottom_up,
			}, formats),
			dct_method = dct_method,
			fancy_upsampling = fancy_upsampling,
			block_smoothing = block_smoothing,
			partial_loading = partial,
		}
		if not img then err = 'open '..err end
		local ok
		if img then
			ok, err = img:load({render_scan = render_scan})
		end
		if not ok then
			render_scan(nil, true, 1, err)
		end
		if img then
			img:free()
		end

		f:close()
	end

end

testui:run()
