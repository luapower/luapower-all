
--oo/controls/bitmappanel: RGBA bitmap control
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local bit = require'bit'
setfenv(1, require'winapi')
require'winapi.bitmap'
require'winapi.panelclass'

BitmapPanel = class(Panel)

function BitmapPanel:on_paint(hdc)
	self:__paint_bitmap()

	local bmp = self.__bmp
	if not bmp then return end

	BitBlt(hdc, 0, 0, bmp.size.w, bmp.size.h, bmp.hdc, 0, 0, SRCCOPY)
end

function BitmapPanel:WM_ERASEBKGND()
	return false --we draw our own background (prevent flicker)
end

function BitmapPanel:__create_bitmap()
	local bmp = self.__bmp
	if bmp then return end

	local w, h = self.client_w, self.client_h
	if w <= 0 or h <= 0 then return end

	bmp = {}
	self.__bmp = bmp

	bmp.size = SIZE{w = w, h = h}

	local info = types.BITMAPINFO()
	info.bmiHeader.biSize = ffi.sizeof'BITMAPINFO'
	info.bmiHeader.biWidth = w
	info.bmiHeader.biHeight = -h
	info.bmiHeader.biPlanes = 1
	info.bmiHeader.biBitCount = 32
	info.bmiHeader.biCompression = BI_RGB
	bmp.hdc = CreateCompatibleDC()
	bmp.hbmp, bmp.bits = CreateDIBSection(bmp.hdc, info, DIB_RGB_COLORS)
	bmp.old_hbmp = SelectObject(bmp.hdc, bmp.hbmp)

	bmp.bitmap = {
		w = w,
		h = h,
		stride = w * 4,
		size = w * h * 4,
		data = bmp.bits,
		format = 'bgra8',
	}

	self:on_bitmap_create(bmp.bitmap)
end

function BitmapPanel:__free_bitmap()
	local bmp = self.__bmp
	if not bmp then return end

	self:on_bitmap_free(self.bitmap)

	local w, h = self.client_w, self.client_h
	if bmp.size.w == w and bmp.size.h == h then return end

	SelectObject(bmp.hdc, bmp.old_hbmp)
	DeleteObject(bmp.hbmp)
	DeleteDC(bmp.hdc)
	self.__bmp = nil
end

function BitmapPanel:__paint_bitmap()
	self:__create_bitmap()

	local bmp = self.__bmp
	if not bmp then return end

	GdiFlush()
	self:on_bitmap_paint(bmp.bitmap)
end

function BitmapPanel:on_bitmap_create(bitmap) end
function BitmapPanel:on_bitmap_free(bitmap) end
function BitmapPanel:on_bitmap_paint(bitmap) end

function BitmapPanel:on_resized()
	self:__free_bitmap()
	self:invalidate()
end

--showcase

if not ... then
	require'winapi.showcase'
	local win = ShowcaseWindow()
	local bp = BitmapPanel{
		x = 20,
		y = 20,
		w = win.client_w - 40,
		h = win.client_h - 40,
		parent = win,
		anchors = {left = true, top = true, right = true, bottom = true},
	}
	function bp:on_bitmap_paint(bmp)
		local pixels = ffi.cast('int32_t*', bmp.data)
		for y = 0, bmp.h - 1 do
			for x = 0, bmp.w - 1 do
				pixels[y * bmp.w + x] = y * 2^8 + x * 2^16
			end
		end
	end
	win:invalidate()
	MessageLoop()
end

return BitmapPanel
