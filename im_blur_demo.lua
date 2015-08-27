local boxblur = require'im_boxblur'.blur_8888
local boxblur_lua = require'im_boxblur_lua'.blur_8888
local stackblur = require'im_stackblur'.blur_8888
local ffi = require'ffi'

local player = require'cplayer'
local jpeg = require'nanojpeg'
local bitmap = require'bitmap'

local source_img = jpeg.load'media/jpeg/birds.jpg'
source_img = bitmap.copy(source_img, 'bgra8', false, true)

function player:on_render()
	local img = bitmap.copy(source_img)
	local radius = math.floor((self.mousex or 1) / 100)+1
	for i=1,2 do
		--stackblur(img.data, img.w, img.h, radius)
		boxblur(img.data, img.w, img.h, radius)
		--boxblur_lua(img.data, img.w, img.h, radius)
	end
	self:image{x = 50, y = 50, image = img}
end

player:play()
