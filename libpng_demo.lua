local player = require'cplayer'
local libpng = require'libpng'
local glue = require'glue'
local ffi = require'ffi'
local stdio = require'stdio'
require'unit' --dir

local good_files = dir'media/png/good/*.png'
local bad_files = dir'media/png/bad/*.png'

local source_type = 'path'
local files = good_files
local bottom_up = false
local stride_aligned = false
local max_cut_size = 1024 * 6
local cut_size = max_cut_size
local pixel_format = 'rgb'
local interlaced_filter_values = {'interl', 'normal'}
local interlaced_filter = glue.index(interlaced_filter_values)
local paletted_filter_values = {'pal', 'bitmap'}
local paletted_filter = glue.index(paletted_filter_values)
local channels_filter_values = {'rgb', 'rgba', 'g', 'ga'}
local channels_filter = glue.index(channels_filter_values)
local bpc_filter_values = {'1b', '2b', '4b', '8b', '16b'}
local bpc_filter = glue.index(bpc_filter_values)
local passes_filter_values = {'single', 'multi'}
local passes_filter = glue.index(passes_filter_values)
local pass_only = 7
local sparkle = false

function player:on_render(cr)

	self:checkerboard()

	files = self:mbutton{id = 'files',
		x = 10, y = 10, w = 180, h = 24,
		values = {good_files, bad_files},
		texts = {[good_files] = 'good files', [bad_files] = 'bad files'},
		multiselect = false,
		selected = files}

	source_type = self:mbutton{id = 'source_type',
		x = 200, y = 10, w = 490, h = 24,
		values = {'path',  'stream', 'cdata', 'string',
			'read cdata', 'read string'},
		selected = source_type}

	sparkle = self:togglebutton{id = 'sparkle',
		x = 700, y = 10, w = 90, h = 24,
		text = 'sparkle', selected = sparkle}

	bottom_up = self:togglebutton{id = 'bottom_up',
		x = 800, y = 10, w = 90, h = 24,
		text = 'bottom_up', selected = bottom_up}
	stride_aligned = self:togglebutton{id = 'stride_aligned',
		x = 900, y = 10, w = 90, h = 24,
		text = 'stride_aligned', selected = stride_aligned}

	if source_type ~= 'path' and source_type ~= 'stream' then
		cut_size = self:slider{id = 'cut_size',
		x = 1000, y = 10, w = self.w - 1000 - 10, h = 24,
		i0 = 0, i1 = max_cut_size, step = 1, i = cut_size,
		text = 'file cut'}
	end

	pixel_format = self:mbutton{id = 'pixel',
		x = 10, y = 40, w = 380, h = 24,
		values = {'rgb', 'bgr', 'rgba', 'bgra',
			'argb', 'abgr', 'g', 'ga', 'ag'},
		selected = pixel_format}

	interlaced_filter = self:mbutton{id = 'interlaced_filter',
		x = 400, y = 40, w = 90, h = 24,
		values = interlaced_filter_values,
		selected = interlaced_filter}
	paletted_filter = self:mbutton{id = 'paletted_filter',
		x = 500, y = 40, w = 90, h = 24,
		values = paletted_filter_values,
		selected = paletted_filter}
	channels_filter = self:mbutton{id = 'channels_filter',
		x = 600, y = 40, w = 190, h = 24,
		values = channels_filter_values,
		selected = channels_filter}
	bpc_filter = self:mbutton{id = 'bpc_filter',
		x = 800, y = 40, w = 190, h = 24,
		values = bpc_filter_values,
		selected = bpc_filter}
	passes_filter = self:mbutton{id = 'passes_filter',
		x = 1000, y = 40, w = 90, h = 24,
		values = passes_filter_values,
		selected = passes_filter}
	pass_only = self:slider{id = 'pass_only',
		x = 1100, y = 40, w = 90, h = 24,
		i0 = 1, i1 = 7, i = pass_only,
		text = 'pass'}

	local function allow_image(image)
		if not interlaced_filter.interl and image.file.interlaced then return end
		if not interlaced_filter.normal and not image.file.interlaced then return end
		if not paletted_filter.pal and image.file.paletted then return end
		if not paletted_filter.bitmap and not image.file.paletted then return end
		if not bpc_filter[tostring(image.file.bpc)..'b'] then return end
		if not channels_filter[image.file.channels] then return end
		if not passes_filter.single and image.file.passes == 1 then return end
		if not passes_filter.multi and image.file.passes == 7 then return end
		return true
	end

	local cy = 80
	local cx = 10

	for i,filename in ipairs(files) do

		local t = {}
		if source_type == 'path' then
			t.path = filename
		elseif source_type == 'stream' then
			t.stream = stdio.fopen(filename, 'rb')
		else
			local s = glue.readfile(filename)
			s = s:sub(1, cut_size)
			local cdata = ffi.new('uint8_t[?]', #s+1, s)
			if source_type == 'cdata' then
				t.cdata = cdata
				t.size = #s
			elseif source_type == 'string' then
				t.string = s
			elseif source_type:match'^read' then
				local function one_shot_reader(buf, sz)
					local done
					return function()
						if done then return end
						done = true
						return buf, sz
					end
				end
				if source_type:find'string' then
					t.read = one_shot_reader(s)
				else
					t.read = one_shot_reader(cdata, #s)
				end
			end
		end

		local w, h = 32, 32

		--[[
		t.accept = {
			[pixel_format] = true,
			bottom_up = bottom_up,
			stride_aligned = stride_aligned}
		]]
		t.sparkle = sparkle

		function t.render_scan(image, last_scan, scan_number, err)

			if scan_number ~= pass_only
				and not (pass_only > 1 and scan_number == 1 and last_scan)
			then
				return
			end

			if not image then
				w = (w + 10) * 8 - 10
			end

			if cx + w + 10 > self.w then
				cx = 10
				cy = cy + h + 10 + 40
			end

			if image then
				self:image{x = cx, y = cy, image = image}

				self:textbox(cx, cy - 16, w, h,
					string.format('%s', image.file.format),
					8, 'normal_fg', 'center', 'top')

				self:textbox(cx, cy + 16, w, h,
					string.format('%s', image.format),
					8, 'normal_fg', 'center', 'bottom')

			else
				self:rect(cx, cy, w, h, 'error_bg')
				self:textbox(cx, cy, w, h,
					string.format('%s', err:match('^(.-)\n'):match(': ([^:]-)$')),
					14, 'normal_fg', 'center', 'center')
			end

			cx = cx + w + 10
		end

		local ok, err = pcall(function()

			local t0 = glue.merge({
				header_only = true,
				render_scan = false,
			}, t)
			local image = libpng.load(t0)
			if not allow_image(image) then return end

			libpng.load(t)
		end)
		if not ok then
			t.render_scan(nil, true, 1, err)
		end

		if t.stream then
			t.stream:close()
		end
	end
end

player:play()

