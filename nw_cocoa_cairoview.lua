
--nw cocoa backend for cairoview.
--Written by Cosmin Apreutesei. Public domain.

if not ... then require'nw_test'; return end

local nw = require'nw_cocoa'
local ffi = require'ffi'
local glue = require'glue'
local cairo = require'cairo'
local objc = require'objc'
--objc.load'ApplicationServices'

local function unpack_nsrect(r)
	return r.origin.x, r.origin.y, r.size.width, r.size.height
end

local window = nw.app.window
local cairoview = glue.inherit({}, window.view)
window.cairoview = cairoview

local CairoView = objc.class('CairoView', 'NSView')

function CairoView.drawRect(cpu)
	local self
	if ffi.arch == 'x64' then
		self = ffi.cast('id', cpu.RDI.p) --RDI = self
	else
		self = ffi.cast('id', cpu.ESP.dp[1].p) --ESP[1] = self
	end
	self.nw_backend:_draw()
end

--convert rect from bottom-up to top-down
function cairoview:_flip_rect(x, y, w, h)
	local parent_h = select(4, self.window.frontend:client_rect())
	return x, parent_h - h - y, w, h
end

function cairoview:rect()
	return self:_flip_rect(unpack_nsrect(self.nsview:bounds()))
end

function cairoview:_init(t)
	if true then
		local x, y, w, h = t.x, t.y, t.w, t.h
		self.nsview = CairoView:alloc():initWithFrame(objc.NSMakeRect(0, 0, w, h))
		self.nsview.nw_backend = self
		x = x + self.window.nswin:frame().origin.x
		y = y - self.window.nswin:frame().origin.y
		local nsrect = objc.NSMakeRect(self:_flip_rect(x, y, w, h))
		self.nswin = objc.NSWindow:alloc():initWithContentRect_styleMask_backing_defer(
			nsrect, 0, objc.NSBackingStoreBuffered, false)
		self.nswin:setOpaque(false)
		self.nswin:setBackgroundColor(objc.NSColor:clearColor())
		self.nswin:setContentView(self.nsview)
		self.window.nswin:addChildWindow_ordered(self.nswin, objc.NSWindowAbove)
	else
		local nsrect = objc.NSMakeRect(self:_flip_rect(t.x, t.y, t.w, t.h))
		self.nsview = CairoView:alloc():initWithFrame(nsrect)
		self.nsview.nw_backend = self
		self.window.nswin:contentView():addSubview(self.nsview)
	end

	--self.nsview:setWantsLayer(true)
end

function cairoview:free()
	self:_free_surface()
	self.nsview:release()
	self.nsview = nil
end

function cairoview:invalidate()
	self.nsview:setNeedsDisplay(true)
end

function cairoview:_create_surface()
	if self.pixels then return end
	self.colorSpace = objc.CGColorSpaceCreateDeviceRGB()
	local sz = self.nsview:bounds().size
	local w, h = sz.width, sz.height
	local stride = w * 4
	self.size = stride * h
	self.pixels = glue.malloc(self.size)
	assert(self.pixels ~= nil)
	self.provider = objc.CGDataProviderCreateWithData(nil, self.pixels, self.size, nil)
	self.pixman_surface = cairo.cairo_image_surface_create_for_data(self.pixels,
									cairo.CAIRO_FORMAT_ARGB32, w, h, stride)
	self.pixman_cr = self.pixman_surface:create_context()
end

function cairoview:_free_surface()
	if not self.pixels then return end
	self.pixman_cr:free()
	self.pixman_surface:free()
	objc.CGColorSpaceRelease(self.colorSpace)
	objc.CGDataProviderRelease(self.provider)
	glue.free(self.pixels)
	self.pixels = nil
end

function cairoview:_draw()
	if not self.nsview then return end
	self:_create_surface()

	--CGImage expect the pixel buffer to be immutable, which is why we have to
	--create a new one every time. bummer.

	local sz = self.nsview:bounds().size
	local w, h = sz.width, sz.height
	local stride = w * 4

	local info = bit.bor(
		ffi.abi'le' and
			objc.kCGBitmapByteOrder32Little or
			objc.kCGBitmapByteOrder32Big,      --native endianness
		objc.kCGImageAlphaPremultipliedFirst) --ARGB32

	local image = objc.CGImageCreate(w, h,
		8,  --bpc
		32, --bpp
		stride,
		self.colorSpace,
		info,
		self.provider,
		nil, --no decode
		false, --no interpolation
		objc.kCGRenderingIntentDefault
	)

	ffi.fill(self.pixels, self.size)

	self.frontend:_backend_render(self.pixman_cr)

	--get the current graphics context and draw our image on it.
	local context = objc.NSGraphicsContext:currentContext():graphicsPort()
	objc.CGContextDrawImage(context, self.nsview:bounds(), image)
	objc.CGImageRelease(image)
end

