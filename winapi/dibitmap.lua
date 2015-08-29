
--proc/gdi/dibitmap: RGBA device independent bitmaps
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'winapi')

--initialize a new or existing DIB header for a top-down bgra8 bitmap.
local function dib_header(w, h, bi)
	if bi then
		ffi.fill(bi, ffi.sizeof'BITMAPV5HEADER')
		bi.bV5Size = ffi.sizeof'BITMAPV5HEADER'
	else
		bi = BITMAPV5HEADER()
	end
	bi.bV5Width  = w
	bi.bV5Height = -h
	bi.bV5Planes = 1
	bi.bV5BitCount = 32
	bi.bV5Compression = BI_BITFIELDS
	bi.bV5SizeImage = w * h * 4
	--this mask specifies a supported 32bpp alpha format for Windows XP.
	bi.bV5RedMask   = 0x00FF0000
	bi.bV5GreenMask = 0x0000FF00
	bi.bV5BlueMask  = 0x000000FF
	bi.bV5AlphaMask = 0xFF000000
	--this flag is important for making clipboard-compatible packed DIBs!
	bi.bV5CSType = LCS_WINDOWS_COLOR_SPACE
	return bi
end

--make a top-down bgra8 DIB and return it along with the pixel buffer.
local function dib(w, h, compat_hwnd)
	local bi = dib_header(w, h)
	local info = ffi.cast('BITMAPINFO*', bi)
	local hdc = GetDC(compat_hwnd)
	local hbmp, data = CreateDIBSection(hdc, info, DIB_RGB_COLORS)
	ReleaseDC(nil, hdc)
	return hbmp, data
end

--make a DIB that can be painted on any DC and on a WS_EX_LAYERED window.
function DIBitmap(w, h, compat_hwnd)

	--can't create a zero-sized bitmap
	assert(w > 0 and h > 0, 'invalid size')

	local hbmp, data = dib(w, h, compat_hwnd)
	local hdc = CreateCompatibleDC(compat_hwnd)
	local oldhbmp = SelectObject(hdc, hbmp)

	local bitmap = {
		--bitmap format
		w = w,
		h = h,
		data = data,
		stride = w * 4,
		size = w * h * 4,
		format = 'bgra8',
		--extra stuff
		hbmp = hbmp,
		hdc = hdc,
	}

	--paint the bitmap on a DC.
	function bitmap:paint(dest_hdc, dx, dy, sx, sy, op)
		BitBlt(dest_hdc, dx or 0, dy or 0, w, h, hdc, sx or 0, sy or 0, op or SRCCOPY)
	end

	--update a WS_EX_LAYERED window with the bitmap contents and size.
	--the bitmap must have window's client rectangle size, otherwise
	--the window is resized to the size of the bitmap!
	--NOTE: x and y should be the window's position in screen coordinates,
	--otherwise the window is moved to where the x and y indicates!
	--NOTE: returns true/false for success/failure.
	--NOTE: This call fails on Remote Desktop connections.
	local pos = POINT()
	local topleft = POINT()
	local size = SIZE(w, h)
	local blendfunc = types.BLENDFUNCTION{
		AlphaFormat = AC_SRC_ALPHA,
		BlendFlags = 0,
		BlendOp = AC_SRC_OVER,
		SourceConstantAlpha = 255,
	}
	function bitmap:update_layered(dest_hwnd, x, y)
		pos.x = x
		pos.y = y
		return UpdateLayeredWindow(dest_hwnd, nil, pos, size, hdc,
			topleft, 0, blendfunc, ULW_ALPHA)
	end

	--free the bitmap and DC.
	local function free()
		ffi.gc(hbmp, nil)
		SelectObject(hdc, oldhbmp)
		DeleteObject(hbmp)
		DeleteDC(hdc)
		bitmap.data = nil
	end
	ffi.gc(hbmp, free)
	bitmap.free = free

	return bitmap
end

