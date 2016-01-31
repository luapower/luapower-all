local player = require'cplayer'
local jpeg = require'nanojpeg'
local cairo = require'cairo'
local glue = require'glue'
local ffi = require'ffi'

require'unit'

local files = dir'media/jpeg/*'

local source_type = 'path'
local scale = 0.5

function player:on_render(cr)

	source_type = self:mbutton{id = 'source_type', x = 10, y = 10, w = 280, h = 24,
						values = {'path', 'cdata', 'string'},
						selected = source_type}
	local cx, cy = 0, 40
	local maxh = 0

	for i,filename in ipairs(files) do

		local source
		if source_type == 'path' then
			source = {path = filename}
		elseif source_type == 'cdata' then
			local s = glue.readfile(filename)
			local cdata = ffi.new('unsigned char[?]', #s+1, s)
			source = {cdata = cdata, size = #s}
		elseif source_type == 'string' then
			local s = glue.readfile(filename)
			source = {string = s}
		end

		pcall(function()

			local image = jpeg.load(source)
			local w, h = image.w * scale, image.h * scale

			if cx + w > self.w then
				cx = 0
				cy = cy + maxh + 10
				maxh = 0
			end

			self:image{x = cx, y = cy, image = image, scale = scale}

			cx = cx + w + 10
			maxh = math.max(maxh, h)

		end)

	end
end

player:play()

