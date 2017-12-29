local player = require'cplayer'
local libjpeg = require'libjpeg'
local cairo = require'cairo'
local glue = require'glue'
local fs = require'fs'
local ffi = require'ffi'

require'unit'
local files = {}
glue.extend(files, dir'media/jpeg/test*')
table.insert(files, 'media/jpeg/progressive.jpg')
table.insert(files, 'media/jpeg/cmyk.jpg') --test skip bytes with this one
table.insert(files, 'media/jpeg/birds.jpg')
table.insert(files, 'media/jpeg/autumn-wallpaper.jpg')
table.insert(files, 'media/jpeg/testimgari.jpg') --no i/o suspension with this one :(

--gui options
local formats = {ycc8 = true}
local max_cut_size = 1024 * 1024
local cut_size = max_cut_size --truncate input file to size to test progressive mode
local scroll = 0
local total_h = 0

--jpeg options
local source_type = 'path'
local dct_method = 'accurate'
local fancy_upsampling = false
local block_smoothing = false
local partial = true
local bottom_up = false
local stride_aligned = false
local suspended_io = true

player.continuous_rendering = false

function player:on_render(cr)

	suspended_io = self:togglebutton{
		id = 'suspended_io', x = 10, y = 10, w = 140, h = 24,
		text = 'suspended I/O',
		selected = suspended_io}

	partial = self:togglebutton{
		id = 'partial', x = 500, y = 10, w = 140, h = 24,
		text = 'partial loading',
		selected = partial}

	cut_size = self:slider{
		id = 'cut_size',
		x = 650, y = 10, w = self.w - 650 - 10, h = 24,
		i0 = 0, i1 = max_cut_size, step = 1, i = cut_size,
		text = 'file cut'}

	dct_method = self:mbutton{
		id = 'dct', x = 10, y = 40, w = 180, h = 24,
		values = {'accurate', 'fast', 'float'},
		selected = dct_method}

	fancy_upsampling = self:togglebutton{
		id = 'fancy_upsampling',
		x = 200, y = 40, w = 140, h = 24,
		text = 'fancy upsampling',
		selected = fancy_upsampling}

	block_smoothing = self:togglebutton{
		id = 'block_smoothing', x = 350, y = 40, w = 140, h = 24,
		text = 'block smoothing',
		selected = block_smoothing}

	formats = self:mbutton{
		id = 'format', x = 500, y = 40, w = 590, h = 24,
		values = {'rgb8', 'bgr8', 'rgba8', 'bgra8', 'argb8',
					'abgr8', 'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8',
					'g8', 'ga8', 'ag8', 'ycc8', 'ycck8', 'cmyk8'},
		selected = formats}

	bottom_up = self:togglebutton{
		id = 'bottom_up', x = 1100, y = 40, w = 90, h = 24,
		text = 'bottom_up',
		selected = bottom_up}

	stride_aligned = self:togglebutton{
		id = 'stride_aligned', x = 1200, y = 40, w = 90, h = 24,
		text = 'stride_aligned',
		selected = stride_aligned}

	stride_aligned = self:togglebutton{
		id = 'stride_aligned', x = 1200, y = 40, w = 90, h = 24,
		text = 'stride_aligned',
		selected = stride_aligned}

	local cy = 80
	local cx = 0

	scroll = scroll - self.wheel_delta * 100
	scroll = self:vscrollbar{
		id = 'vscroll', x = self.w - 16 - cx, y = cy, w = 16, h = self.h - cy,
		i = scroll, size = total_h}

	total_h = 0

	self.cr:rectangle(cx, cy, self.w - 16 - cx, self.h - cy)
	self.cr:clip()

	cy = cy - scroll

	local last_image, maxh
	for i,filename in ipairs(files) do

		local rendered_once
		local function render_scan(image, last_scan, scan_number, err)

			--if not last_scan then return end
			rendered_once = true
			local w, h = 300, 100
			if image then w, h = image.w, image.h end

			if cx + w + 10 + 16 > self.w then
				cx = 0
				local h = (maxh or h) + 10
				cy = cy + h
				total_h = total_h + h
				maxh = nil
			end

			if image then

				self:image{x = cx, y = cy, image = image}

				self:textbox(cx, cy, w, h,
					string.format('scan %d', scan_number),
					14, 'normal_fg', 'left', 'top')

				self:textbox(cx, cy, w, h,
					image.format .. (image.format ~= image.format and
						' -> ' .. image.format or ''),
					14, 'normal_fg', 'center', 'center')

				if image.partial then
					self:textbox(cx, cy, w, h, 'partial', 14, 'normal_fg', 'right', 'top')
				end
			else
				self:rect(cx, cy, w, h, 'error_bg')
				self:textbox(cx, cy, w, h,
					string.format('%s', err:match(': ([^:]-)$')),
					14, 'normal_fg', 'center', 'center')
			end

			cx = cx + w + 10
			maxh = math.max(maxh or 0, h)
		end

		local f = assert(fs.open(filename))
		local left = cut_size
		local function read(buf, sz)
			if left == 0 then return 0 end
			local sz = math.min(left, sz)
			local readsz
			if buf then
				readsz = assert(f:read(buf, sz))
			else
				local pos0 = assert(f:seek())
				local pos1 = assert(f:seek(sz))
				readsz = pos1 - pos0
			end
			left = left - readsz
			return readsz
		end
		local img, err = libjpeg.open{
			read = read,
			accept = glue.update({
				stride_aligned = stride_aligned,
				bottom_up = bottom_up,
			}, formats),
			dct_method = dct_method,
			fancy_upsampling = fancy_upsampling,
			block_smoothing = block_smoothing,
			partial_loading = partial,
			suspended_io = suspended_io,
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

	total_h = total_h + math.max(maxh or 0, last_image and last_image.h or 0)
end

player:play()

