--nw cocoa backend for glview.
local nw = require'nw_cocoa'
local ffi = require'ffi'
local glue = require'glue'
local objc = require'objc'
objc.load'OpenGL'

local function unpack_nsrect(r)
	return r.origin.x, r.origin.y, r.size.width, r.size.height
end

local window = nw.app.window
local glview = glue.inherit({}, window.view)
window.glview = glview

local GLView = objc.class('GLView', 'NSOpenGLView')

function GLView.drawRect(cpu)
	local self
	if ffi.arch == 'x64' then
		self = ffi.cast('id', cpu.RDI.p) --RDI = self
	else
		self = ffi.cast('id', cpu.ESP.dp[1].p) --ESP[1] = self
	end
	self.nw_backend:_draw()
end

--convert rect from bottom-up to top-down
function glview:_flip_rect(x, y, w, h)
	local parent_h = select(4, self.window.frontend:client_rect())
	return x, parent_h - h - y, w, h
end

function glview:rect()
	return self:_flip_rect(unpack_nsrect(self.nsview:bounds()))
end

ffi.cdef[[
enum {
   NSOpenGLPFAAllRenderers       =   1,
   NSOpenGLPFATripleBuffer       =   3,
   NSOpenGLPFADoubleBuffer       =   5,
   NSOpenGLPFAStereo             =   6,
   NSOpenGLPFAAuxBuffers         =   7,
   NSOpenGLPFAColorSize          =   8,
   NSOpenGLPFAAlphaSize          =  11,
   NSOpenGLPFADepthSize          =  12,
   NSOpenGLPFAStencilSize        =  13,
   NSOpenGLPFAAccumSize          =  14,
   NSOpenGLPFAMinimumPolicy      =  51,
   NSOpenGLPFAMaximumPolicy      =  52,
   NSOpenGLPFAOffScreen          =  53,
   NSOpenGLPFAFullScreen         =  54,
   NSOpenGLPFASampleBuffers      =  55,
   NSOpenGLPFASamples            =  56,
   NSOpenGLPFAAuxDepthStencil    =  57,
   NSOpenGLPFAColorFloat         =  58,
   NSOpenGLPFAMultisample        =  59,
   NSOpenGLPFASupersample        =  60,
   NSOpenGLPFASampleAlpha        =  61,
   NSOpenGLPFARendererID         =  70,
   NSOpenGLPFASingleRenderer     =  71,
   NSOpenGLPFANoRecovery         =  72,
   NSOpenGLPFAAccelerated        =  73,
   NSOpenGLPFAClosestPolicy      =  74,
   NSOpenGLPFARobust             =  75,
   NSOpenGLPFABackingStore       =  76,
   NSOpenGLPFAMPSafe             =  78,
   NSOpenGLPFAWindow             =  80,
   NSOpenGLPFAMultiScreen        =  81,
   NSOpenGLPFACompliant          =  83,
   NSOpenGLPFAScreenMask         =  84,
   NSOpenGLPFAPixelBuffer        =  90,
   NSOpenGLPFARemotePixelBuffer  =  91,
   NSOpenGLPFAAllowOfflineRenderers = 96,
   NSOpenGLPFAAcceleratedCompute =  97,
   NSOpenGLPFAOpenGLProfile      =  99,
   NSOpenGLPFAVirtualScreenCount = 128
};
enum {
   NSOpenGLProfileVersionLegacy    = 0x1000,
   NSOpenGLProfileVersion3_2Core   = 0x3200
};
typedef uint32_t NSOpenGLPixelFormatAttribute;
]]

function glview:_init(t)
	local pixelFormatAttributes = ffi.new('NSOpenGLPixelFormatAttribute[?]', 10,
		objc.NSOpenGLPFAOpenGLProfile, objc.NSOpenGLProfileVersionLegacy, --objc.NSOpenGLProfileVersion3_2Core,
		objc.NSOpenGLPFAColorSize, 24,
		objc.NSOpenGLPFAAlphaSize, 8,
		objc.NSOpenGLPFADoubleBuffer,
		objc.NSOpenGLPFAAccelerated,
		objc.NSOpenGLPFANoRecovery,
		0)
	local pixelFormat = objc.NSOpenGLPixelFormat:alloc():initWithAttributes(pixelFormatAttributes)

	local nsrect = objc.NSMakeRect(self:_flip_rect(t.x, t.y, t.w, t.h))
	self.nsview = GLView:alloc():initWithFrame_pixelFormat(nsrect, pixelFormat)
	self.window.nswin:contentView():addSubview(self.nsview)
	self.nsview.nw_backend = self

	self.nsview:openGLContext():makeCurrentContext()
	--self.nsview:setWantsLayer(true)
end

function glview:free()
	self:_free_surface()
	self.nsview:release()
	self.nsview = nil
end

function glview:invalidate()
	self.nsview:setNeedsDisplay(true)
end

function glview:_create_surface()
	if self.pixels then return end
	self.pixels = true
end

function glview:_free_surface()
	if not self.pixels then return end

	self.pixels = nil
end

function glview:_draw()
	self:_create_surface()
	if not self.pixels then return end
	self.frontend:_backend_render()
	self.nsview:openGLContext():flushBuffer()
end


if not ... then require'nw_test' end
