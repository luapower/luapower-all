
--bitmap conversions and processing leveraging LuaJIT.
--Written by Cosmin Apreutesei. Public domain.

local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
local box2d = require'box2d'

local floor, ceil, min, max =
	math.floor, math.ceil, math.min, math.max
local shr, shl, band, bor, bnot =
	bit.rshift, bit.lshift, bit.band, bit.bor, bit.bnot

--colortypes

local colortypes = glue.autoload({
	rgba8  = {channels = 'rgba', bpc =  8, max = 0xff},
	rgba16 = {channels = 'rgba', bpc = 16, max = 0xffff},
	ga8    = {channels = 'ga',   bpc =  8, max = 0xff},
	ga16   = {channels = 'ga',   bpc = 16, max = 0xffff},
	cmyk8  = {channels = 'cmyk', bpc =  8, max = 0xff},
	ycc8   = {channels = 'ycc',  bpc =  8, max = 0xff},
	ycck8  = {channels = 'ycck', bpc =  8, max = 0xff},
}, {
	rgbaf = 'bitmap_rgbaf',
})

--pixel formats

local formats = {}

local function format(bpp, ctype, colortype, read, write, ...)
	return {bpp = bpp, ctype = ffi.typeof(ctype),
		colortype = colortype, read = read, write = write, ...}
end

local function override_format(fmt, ...)
	return glue.merge(format(...), formats[fmt])
end

--read/write individual channels
local function r0(s,i) return s[i] end
local function r1(s,i) return s[i+1] end
local function r2(s,i) return s[i+2] end
local function r3(s,i) return s[i+3] end
local function rff(s,i) return 0xff end
local function rffff(s,i) return 0xffff end
local function w0(d,i,v) d[i] = v end
local function w1(d,i,v) d[i+1] = v end
local function w2(d,i,v) d[i+2] = v end
local function w3(d,i,v) d[i+3] = v end

--8bpc RGB, BGR
formats.rgb8 = format(24, 'uint8_t', 'rgba8',
	function(s,i) return s[i], s[i+1], s[i+2], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2] = r,g,b end,
	r0, r1, r2, rff, w0, w1, w2)

formats.bgr8 = format(24, 'uint8_t', 'rgba8',
	function(s,i) return s[i+2], s[i+1], s[i], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2] = b,g,r end,
	r2, r1, r0, rff, w2, w1, w0)

--16bpc RGB, BGR
formats.rgb16 = format(48, 'uint16_t', 'rgba16',
	function(s,i) return s[i], s[i+1], s[i+2], 0xffff end,
	formats.rgb8.write,
	r0, r1, r2, rffff, w0, w1, w2)
formats.bgr16 = format(48, 'uint16_t', 'rgba16',
	function(s,i) return s[i+2], s[i+1], s[i], 0xffff end,
	formats.bgr8.write,
	r2, r1, r0, rffff, w2, w1, w0)

--8bpc RGBX, BGRX, XRGB, XBGR
formats.rgbx8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i], s[i+1], s[i+2], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,0xff end,
	r0, r1, r2, rff, w0, w1, w2)

formats.bgrx8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+2], s[i+1], s[i], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,0xff end,
	r2, r1, r0, rff, w2, w1, w0)

formats.xrgb8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+1], s[i+2], s[i+3], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xff,r,g,b end,
	r1, r2, r3, rff, w1, w2, w3)

formats.xbgr8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+3], s[i+2], s[i+1], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xff,b,g,r end,
	r3, r2, r1, rff, w3, w2, w1)

--16bpc RGBX, BGRX, XRGB, XBGR
formats.rgbx16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i], s[i+1], s[i+2], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,0xffff end,
	r0, r1, r2, rffff, w0, w1, w2)

formats.bgrx16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i+2], s[i+1], s[i], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,0xffff end,
	r2, r1, r0, rffff, w2, w1, w0)

formats.xrgb16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i+1], s[i+2], s[i+3], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xffff,r,g,b end,
	r1, r2, r3, rffff, w1, w2, w3)

formats.xbgr16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i+3], s[i+2], s[i+1], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xffff,b,g,r end,
	r1, r2, r3, rffff, w1, w2, w3)

--8bpc RGBA, BGRA, ARGB, ARGB
formats.rgba8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i], s[i+1], s[i+2], s[i+3] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,a end,
	r0, r1, r2, r3, w0, w1, w2, w3)

formats.bgra8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+2], s[i+1], s[i], s[i+3] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,a end,
	r2, r1, r0, r3, w2, w1, w0, w3)

formats.argb8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+1], s[i+2], s[i+3], s[i] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = a,r,g,b end,
	r1, r2, r3, r0, w1, w2, w3, w0)

formats.abgr8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+3], s[i+2], s[i+1], s[i] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = a,b,g,r end,
	r1, r2, r3, r0, w1, w2, w3, w0)

--16bpc RGBA, BGRA, ARGB, ABGR
formats.rgba16 = override_format('rgba8', 64, 'uint16_t', 'rgba16')
formats.bgra16 = override_format('bgra8', 64, 'uint16_t', 'rgba16')
formats.argb16 = override_format('argb8', 64, 'uint16_t', 'rgba16')
formats.abgr16 = override_format('abgr8', 64, 'uint16_t', 'rgba16')

--8bpc GRAY and GRAY+APLHA
formats.g8 = format( 8, 'uint8_t', 'ga8',
	function(s,i) return s[i], 0xff end,
	w0,
	r0, rff, w0)

formats.ga8 = format(16, 'uint8_t', 'ga8',
	function(s,i) return s[i], s[i+1] end,
	function(d,i,g,a) d[i], d[i+1] = g,a end,
	r0, r1, w0, w1)

formats.ag8 = format(16, 'uint8_t', 'ga8',
	function(s,i) return s[i+1], s[i] end,
	function(d,i,g,a) d[i], d[i+1] = a,g end,
	r1, r0, w1, w0)

--16bpc GRAY and GRAY+ALPHA
formats.g16 = format(16, 'uint16_t', 'ga16',
	function(s,i) return s[i], 0xffff end,
	w0,
	r0, rffff, w0)

formats.ga16 = override_format('ga8', 32, 'uint16_t', 'ga16')
formats.ag16 = override_format('ag8', 32, 'uint16_t', 'ga16')

--8bpc INVERSE CMYK
formats.cmyk8 = override_format('rgba8', 32, 'uint8_t', 'cmyk8')

--16bpp RGB565
local function rr(s,i) return      shr(s[i], 11)      * (255 / 31) end
local function rg(s,i) return band(shr(s[i],  5), 63) * (255 / 63) end
local function rb(s,i) return band(    s[i],      31) * (255 / 31) end
local function wr(d,i,v) d[i] = bor(band(d[i], 0x07ff), shl(shr(r, 3), 11)) end
local function wg(d,i,v) d[i] = bor(band(d[i], 0xf81f), shl(shr(g, 2),  5)) end
local function wb(d,i,v) d[i] = bor(band(d[i], 0xffe0), shr(b, 3)) end
local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), 0xff
end
local function wrgba(d,i,r,g,b)
	d[i] = bor(shl(shr(r, 3), 11),
	           shl(shr(g, 2),  5),
	               shr(b, 3))
end
formats.rgb565 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, rff, wr, wg, wb)

--16bpp RGB444 and RGBA4444
local function rr(s,i) return      shr(s[i], 12)      * (255 / 15) end
local function rg(s,i) return band(shr(s[i],  8), 15) * (255 / 15) end
local function rb(s,i) return band(shr(s[i],  4), 15) * (255 / 15) end
local function ra(s,i) return band(    s[i],      15) * (255 / 15) end
local function wr(d,i,v) d[i] = bor(band(d[i], 0x0fff), shl(shr(r, 4), 12)) end
local function wg(d,i,v) d[i] = bor(band(d[i], 0xf0ff), shl(shr(g, 4),  8)) end
local function wb(d,i,v) d[i] = bor(band(d[i], 0xff0f), shl(shr(b, 4),  4)) end
local function wa(d,i,v) d[i] = bor(band(d[i], 0xfff0),     shr(a, 4)     ) end
local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), 0xff
end
local function wrgba(d,i,r,g,b)
	d[i] = bor(shl(shr(r, 4), 12),
	           shl(shr(g, 4),  8),
	           shl(shr(b, 4),  4))
end
formats.rgb444 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, rff, wr, wg, wb)

local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), ra(s,i)
end
local function wrgba(d,i,r,g,b,a)
	d[i] = bor(shl(shr(r, 4), 12),
	           shl(shr(g, 4),  8),
	           shl(shr(b, 4),  4),
	               shr(a, 4))
end
formats.rgba4444 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, ra, wr, wg, wb, wa)

--16bpp RGB5550 and RGBA5551
local function rr(s,i) return      shr(s[i], 11)      * (255 / 31) end
local function rg(s,i) return band(shr(s[i],  6), 31) * (255 / 31) end
local function rb(s,i) return band(shr(s[i],  1), 31) * (255 / 31) end
local function ra(s,i) return band(    s[i],  1)      *  255       end
local function wr(d,i,v) d[i] = bor(band(d[i], 0x07ff), shl(shr(r, 3), 11)) end
local function wg(d,i,v) d[i] = bor(band(d[i], 0xf83f), shl(shr(g, 3),  6)) end
local function wb(d,i,v) d[i] = bor(band(d[i], 0xffc1), shl(shr(b, 3),  1)) end
local function wa(d,i,v) d[i] = bor(band(d[i], 0xfffe),     shr(a, 7)     ) end
local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), 0xff
end
function wrgba(d,i,r,g,b,a)
	d[i] = bor(shl(shr(r, 3), 11),
	           shl(shr(g, 3),  6),
	           shl(shr(b, 3),  1))
end
formats.rgb5550 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, rff, wr, wg, wb)

local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), ra(s,i)
end
function wrgba(d,i,r,g,b,a)
	d[i] = bor(shl(shr(r, 3), 11),
	           shl(shr(g, 3),  6),
	           shl(shr(b, 3),  1),
	               shr(a, 7))
end
formats.rgba5551 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, ra, wr, wg, wb, wa)

--16bpp RGB0555 and ARGB1555
local function rr(s,i) return band(shr(s[i], 10), 31) * (255 / 31) end
local function rg(s,i) return band(shr(s[i],  5), 31) * (255 / 31) end
local function rb(s,i) return band(    s[i],      31) * (255 / 31) end
local function ra(s,i) return      shr(s[i], 15)      *  255       end
local function wr(d,i,v) d[i] = bor(band(d[i], 0x83ff), shl(shr(r, 3), 10)) end
local function wg(d,i,v) d[i] = bor(band(d[i], 0xfc1f), shl(shr(g, 3),  5)) end
local function wb(d,i,v) d[i] = bor(band(d[i], 0xffe0),     shr(b, 3)     ) end
local function wa(d,i,v) d[i] = bor(band(d[i], 0x7fff), shl(shr(a, 7), 15)) end
local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), 0xff
end
function wrgba(d,i,r,g,b,a)
	d[i] = bor(shl(shr(r, 3), 10),
				  shl(shr(g, 3),  5),
				      shr(b, 3))
end
formats.rgb0555 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, rff, wr, wg, wb)

local function rrgba(s,i)
	return rr(s,i), rg(s,i), rb(s,i), ra(s,i)
end
function wrgba(d,i,r,g,b,a)
	d[i] = bor(shl(shr(r, 3), 10),
	           shl(shr(g, 3),  5),
	               shr(b, 3),
				  shl(shr(a, 7), 15))
end
formats.rgba1555 = format(16, 'uint16_t', 'rgba8',
	rrgba, wrgba, rr, rg, rb, ra, wr, wg, wb, wa)

--sub-byte (< 8bpp) formats
formats.g1  = format(1, 'uint8_t', 'ga8')
formats.g2  = format(2, 'uint8_t', 'ga8')
formats.g4  = format(4, 'uint8_t', 'ga8')

function formats.g1.read(s,i)
	local sbit = band(i * 8, 7) --i is fractional, that's why this works.
	return band(shr(s[i], 7-sbit), 1) * 255, 0xff
end

function formats.g2.read(s,i)
	local sbit = band(i * 8, 7) --0,2,4,6
	return band(shr(s[i], 6-sbit), 3) * (255 / 3), 0xff
end

function formats.g4.read(s,i)
	local sbit = band(i * 8, 7) --0,4
	return band(shr(s[i], 4-sbit), 15) * (255 / 15), 0xff
end

function formats.g1.write(d,i,g)
	local dbit = band(i * 8, 7) --0-7
	d[i] = bor(
				band(d[i], shr(0xffff-0x80, dbit)), --clear the bit
				shr(band(g, 0x80), dbit)) --set the bit
end

function formats.g2.write(d,i,g)
	local dbit = band(i * 8, 7) --0,2,4,6
	d[i] = bor(
				band(d[i], shr(0xffff-0xC0, dbit)), --clear the bits
				shr(band(g, 0xC0), dbit)) --set the bits
end

function formats.g4.write(d,i,g)
	local dbit = band(i * 8, 7) --0,4
	d[i] = bor(
				band(d[i], shr(0xffff-0xf0, dbit)), --clear the bits
				shr(band(g, 0xf0), dbit)) --set the bits
end

glue.append(formats.g1, formats.g1.read, rff, formats.g1.write)
glue.append(formats.g2, formats.g2.read, rff, formats.g2.write)
glue.append(formats.g4, formats.g4.read, rff, formats.g4.write)

--8bpc YCC and YCCK
formats.ycc8  = override_format('rgb8',  24, 'uint8_t', 'ycc8')
formats.ycck8 = override_format('rgba8', 32, 'uint8_t', 'ycck8')

--formats from other submodules
glue.autoload(formats, {
	rgbaf = 'bitmap_rgbaf',
	rgbad = 'bitmap_rgbaf',
})

--converters between different standard colortypes

local conv = {
	rgba8 = {}, rgba16 = {}, ga8 = {}, ga16 = {},
	cmyk8 = {}, ycc8 = {}, ycck8 = {},
}

function conv.rgba8.rgba16(r, g, b, a)
	return
		r * 257, --257 = 65535 / 255
		g * 257,
		b * 257,
		a * 257
end

--NOTE: formula from libpng/pngrtran.c
function conv.rgba16.rgba8(r, g, b, a)
	return
		shr((r * 255 + 32895), 16),
		shr((g * 255 + 32895), 16),
		shr((b * 255 + 32895), 16),
		shr((a * 255 + 32895), 16)
end

function conv.ga8.ga16(g, a)
	return
		g * 257,
		a * 257
end

function conv.ga16.ga8(g, a)
	return
		shr((g * 255 + 32895), 16),
		shr((a * 255 + 32895), 16)
end

--NOTE: floor(x+0.5) is expensive as a round() function, so we just add 0.5
--and clamp the result instead, and let the ffi truncate the value when
--it writes it to the integer pointer.
local function round8(x)
	return min(max(x + 0.5, 0), 0xff)
end

local function round16(x)
	return min(max(x + 0.5, 0), 0xffff)
end

--NOTE: needs no clamping as long as the r, g, b values are within range.
local function rgb2g(r, g, b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function conv.rgba8.ga8(r, g, b, a)
	return round8(rgb2g(r, g, b)), a
end

function conv.rgba16.ga16(r, g, b, a)
	return round16(rgb2g(r, g, b)), a
end

function conv.ga8.rgba8(g, a)
	return g, g, g, a
end

conv.ga16.rgba16 = conv.ga8.rgba8

function conv.cmyk8.rgba16(c, m, y, k)
	return c * k, m * k, y * k, 0xffff
end

--from http://en.wikipedia.org/wiki/YCbCr#JPEG_conversion
function conv.ycc8.rgba8(y, cb, cr)
	return
		round8(y                        + 1.402   * (cr - 128)),
		round8(y - 0.34414 * (cb - 128) - 0.71414 * (cr - 128)),
      round8(y + 1.772   * (cb - 128)),
		0xff
end

function conv.ycck8.cmyk8(y, cb, cr, k)
	local r, g, b = conv.ycc8.rgba8(y, cb, cr)
	return 255 - r, 255 - g, 255 - b, k
end

--composite converters

function conv.ga16.rgba8(g, a) return conv.rgba16.rgba8(conv.ga16.rgba16(g, a)) end
function conv.ga8.rgba16(g, a) return conv.ga16.rgba16(conv.ga8.ga16(g, a)) end
function conv.rgba16.ga8(r, g, b, a) return conv.ga16.ga8(conv.rgba16.ga16(r, g, b, a)) end
function conv.rgba8.ga16(r, g, b, a) return conv.rgba16.ga16(conv.rgba8.rgba16(r, g, b, a)) end

function conv.cmyk8.rgba8(c, m, y, k) return conv.rgba16.rgba8(conv.cmyk8.rgba16(c, m, y, k)) end
function conv.cmyk8.ga16(c, m, y, k) return conv.rgba16.ga16(conv.cmyk8.rgba16(c, m, y, k)) end
function conv.cmyk8.ga8(c, m, y, k) return conv.ga16.ga8(conv.rgba16.ga16(conv.cmyk8.rgba16(c, m, y, k))) end

function conv.ycc8.rgba16(y, cb, cr) return conv.rgba8.rgba16(conv.ycc8.rgba8(y, cb, cr)) end
function conv.ycc8.ga16(y, cb, cr) return conv.rgba16.ga16(conv.rgba8.rgba16(conv.ycc8.rgba8(y, cb, cr))) end
function conv.ycc8.ga8(y, cb, cr) return conv.rgba8.ga8(conv.ycc8.rgba8(y, cb, cr)) end

function conv.ycck8.rgba16(y, cb, cr, k) return conv.cmyk8.rgba16(conv.ycck8.cmyk8(y, cb, cr, k)) end
function conv.ycck8.rgba8(y, cb, cr, k) return conv.cmyk8.rgba8(conv.ycck8.cmyk8(y, cb, cr, k)) end
function conv.ycck8.ga16(y, cb, cr, k)
	return conv.rgba16.ga16(conv.cmyk8.rgba16(conv.ycck8.cmyk8(y, cb, cr, k)))
end
function conv.ycck8.ga8(y, cb, cr, k) return
	conv.ga16.ga8(conv.rgba16.ga16(conv.cmyk8.rgba16(conv.ycck8.cmyk8(y, cb, cr, k))))
end

--raw colortypes and formats

for i=3,6 do
	local n = 2^i --8..64
	local name = 'raw'..n
	colortypes[name] = {channels = 'x', bpc = n, max = 2^n}
	formats[name] = format(n, 'uint'..n..'_t', name, r0, w0, r0, w0)
	conv[name] = {}
end

--bitmap objects

local function valid_colortype(colortype)
	return type(colortype) == 'string'
				and assert(colortypes[colortype], 'invalid colortype') --standard colortype
				or assert(colortype, 'colortype missing') --custom colortype
end

local function valid_format(format)
	return type(format) == 'string'
				and assert(formats[format], 'invalid format') --standard format
				or assert(format, 'format missing') --custom format
end

--next address that is multiple of `align` bytes
local function aligned_address(addr, align)
	if not align or align == 1 then
		return addr, 1
	elseif align == true then
		align = 4 --default for cairo (sse2 needs 16)
	end
	assert(align >= 2)
	assert(band(align, align - 1) == 0) --must be power-of-two
	if ffi.istype('uint64_t', addr) then
		align = ffi.cast('uint64_t', align) --so that bnot() works
	end
	return band(addr + align - 1, bnot(align - 1)), align
end

local voidp_ct = ffi.typeof'void*'
local function aligned_pointer(ptr, align)
	local addr = ffi.cast('uintptr_t', ptr)
	return ffi.cast(voidp_ct, (aligned_address(addr, align)))
end

--next stride that is a multiple of `align` bytes
local function aligned_stride(stride, align)
	return aligned_address(ceil(stride), align)
end

--minimum stride for a specific format
local function min_stride(format, w)
	return w * valid_format(format).bpp / 8 --stride is fractional for < 8bpp formats, that's ok.
end

--validate stride against min. stride
local function valid_stride(format, w, stride, align)
	local min_stride = min_stride(format, w)
	local stride = stride or min_stride
	local stride, align = aligned_stride(stride, align)
	assert(stride >= min_stride, 'invalid stride')
	return stride, align
end

local function bitmap_stride(bmp)
	return valid_stride(bmp.format, bmp.w, bmp.stride)
end

local function bitmap_row_size(bmp) --can be fractional
	return min_stride(bmp.format, bmp.w)
end

local function bitmap_format(bmp)
	return valid_format(type(bmp) == 'string' and bmp or bmp.format)
end

local function bitmap_colortype(bmp)
	return valid_colortype(type(bmp) == 'string' and bmp
			or valid_format(bmp.format).colortype)
end

local function new(w, h, format, bottom_up, align, stride, alloc)
	local stride, align = valid_stride(format, w, stride, align)
	local size = ceil(stride * h)
	assert(size > 0, 'invalid size')
	local _size = size + (align - 1)
	local _data = alloc and alloc(_size) or ffi.new(ffi.typeof('char[$]', _size))
	local data = aligned_pointer(_data, align)
	return {w = w, h = h, format = format, bottom_up = bottom_up or nil,
		stride = stride, data = data, _data = _data, size = size,
		alloc = alloc and true or nil}
end

--low-level bitmap interface for random access to pixels

local function data_interface(bmp)
	local format = bitmap_format(bmp)
	local data = ffi.cast(ffi.typeof('$*', ffi.typeof(format.ctype)), bmp.data)
	local stride_bytes = valid_stride(bmp.format, bmp.w, bmp.stride)
	local stride_samples = stride_bytes / ffi.sizeof(format.ctype)
	--NOTE: pixelsize is fractional for < 8bpp formats, that's ok.
	local pixelsize = format.bpp / 8 / ffi.sizeof(format.ctype)
	return format, data, stride_samples, pixelsize
end

--coordinate-based bitmap interface for random access to pixels

local function coord_interface(bmp, read, write)
	local format, data, stride, pixelsize = data_interface(bmp)
	local get, set
	if bmp.bottom_up then
		function get(x, y, ...)
			return read(data, (bmp.h - y - 1) * stride + x * pixelsize, ...)
		end
		function set(x, y, ...)
			write(data, (bmp.h - y - 1) * stride + x * pixelsize, ...)
		end
	else
		function get(x, y, ...)
			return read(data, y * stride + x * pixelsize, ...)
		end
		function set(x, y, ...)
			write(data, y * stride + x * pixelsize, ...)
		end
	end
	return get, set
end

local function discard() end
local function channel_interface(bmp, channel)
	local colortype = bitmap_colortype(bmp)
	local n = #colortype.channels
	local format = bitmap_format(bmp)
	local read = format[channel]
	local write = format[n + channel] or discard
	return coord_interface(bmp, read, write)
end

local function direct_pixel_interface(bmp)
	local format = bitmap_format(bmp)
	return coord_interface(bmp, format.read, format.write)
end

local function pixel_interface(bmp, colortype)
	local format, data, stride, pixelsize = data_interface(bmp)
	if not colortype or colortype == format.colortype then
		return direct_pixel_interface(bmp)
	end
	valid_colortype(format.colortype) --autoload colortypes
	valid_colortype(colortype)        --autoload colortypes
	local read_pixel  = assert(conv[format.colortype][colortype], 'invalid conversion')
	local write_pixel = assert(conv[colortype][format.colortype], 'invalid conversion')
	local direct_getpixel, direct_setpixel = direct_pixel_interface(bmp)
	local function getpixel(x, y)
		return read_pixel(direct_getpixel(x, y))
	end
	local function setpixel(x, y, ...)
		direct_setpixel(x, y, write_pixel(...))
	end
	return getpixel, setpixel
end

--bitmap region selector

--create a bitmap representing a rectangular region of another bitmap.
--no pixels are copied: the bitmap references the same data buffer as the original.
local function sub(bmp, x, y, w, h)
	x, y, w, h = box2d.clip(x or 0, y or 0, w or 1/0, h or 1/0, 0, 0, bmp.w, bmp.h)
	if w == 0 or h == 0 then return end --can't have bitmaps in 1 or 0 dimensions
	local format, data, stride, pixelsize = data_interface(bmp)
	if bmp.bottom_up then
		y = bmp.h - y - h
	end
	local i = y * stride + x * pixelsize
	assert(i == floor(i), 'invalid coordinates')
	local byte_stride = stride * ffi.sizeof(format.ctype)
	return {w = w, h = h, format = bmp.format, bottom_up = bmp.bottom_up,
				stride = bmp.stride, data = data + i, size = byte_stride * h,
				parent = bmp, x = x, y = y}
end

--bitmap converter

local function colortype_pixel_converter(src_colortype, dst_colortype)
	if src_colortype == dst_colortype then return end
	return assert(conv[src_colortype][dst_colortype], 'invalid conversion')
end

local function chain(f, g)
	if f and g then
		return function(...)
			return f(g(...))
		end
	end
	return f or g
end

local function paint(dst, src, dstx, dsty, convert_pixel, src_colortype, dst_colortype)

	if not tonumber(dstx) then --dstx, dsty are optional inner args
		convert_pixel, dstx, dsty = dstx
	end

	--find the clip rectangle and make sub-bitmaps
	dstx = dstx or 0
	dsty = dsty or 0
	if dstx ~= 0 or dsty ~= 0 or src.w ~= dst.w or src.h ~= dst.h then
		local x, y, w, h = box2d.clip(dstx, dsty, dst.w-dstx, dst.h-dsty, dstx, dsty, src.w, src.h)
		if w == 0 or h == 0 then return end
		src = sub(src, 0, 0, w, h)
		dst = sub(dst, x, y, w, h)
	end
	assert(src.h == dst.h)
	assert(src.w == dst.w)

	local src_format, src_data, src_stride, src_pixelsize = data_interface(src)
	local dst_format, dst_data, dst_stride, dst_pixelsize = data_interface(dst)

	local src_rowsize = bitmap_row_size(src)

	--try to copy the bitmap whole
	if src_format == dst_format
		and not convert_pixel
		and src_stride == dst_stride
		and not src.bottom_up == not dst.bottom_up
	then
		if src.data ~= dst.data then
			assert(dst.size >= src.size)
			ffi.copy(dst.data, src.data, src.size)
		end
		return dst
	end

	--check that dest. pixels would not be written ahead of source pixels
	assert(src.data ~= dst.data or (
		dst_format.bpp <= src_format.bpp
		and dst_stride <= src_stride
		and not src.bottom_up == not dst.bottom_up))

	--dest. starting index and step, depending on whether the orientation is different.
	local dj = 0
	if not src.bottom_up ~= not dst.bottom_up then
		dj = (src.h - 1) * dst_stride --first pixel of the last row
		dst_stride = -dst_stride --...and stepping backwards
	end

	--try to copy the bitmap row-by-row
	if src_format == dst_format
		and not convert_pixel
		and src_stride == floor(src_stride) --can't copy from fractional offsets
		and dst_stride == floor(dst_stride) --can't copy into fractional offsets
		and src_rowsize == floor(src_rowsize) --can't copy fractional row sizes
	then
		for sj = 0, (src.h - 1) * src_stride, src_stride do
			ffi.copy(dst_data + dj, src_data + sj, src_rowsize)
			dj = dj + dst_stride
		end
		return dst
	end

	--convert the bitmap pixel-by-pixel

	if convert_pixel then
		local src_colortype = src_colortype or src_format.colortype
		local dst_colortype = dst_colortype or dst_format.colortype
		local sconv = colortype_pixel_converter(src_format.colortype, src_colortype)
		local dconv = colortype_pixel_converter(dst_colortype, dst_format.colortype)
		convert_pixel = convert_pixel and chain(chain(sconv, convert_pixel), dconv)
	else
		convert_pixel = colortype_pixel_converter(src_format.colortype, dst_format.colortype)
	end

	for sj = 0, (src.h - 1) * src_stride, src_stride do
		for i = 0, src.w-1 do
			if convert_pixel then
				dst_format.write(dst_data, dj + i * dst_pixelsize,
					convert_pixel(
						src_format.read(src_data, sj + i * src_pixelsize)))
			else
				dst_format.write(dst_data, dj + i * dst_pixelsize,
					src_format.read(src_data, sj + i * src_pixelsize))
			end
		end
		dj = dj + dst_stride
	end

	return dst
end

--bitmap copy

local function copy(src, format, bottom_up, align, stride)
	if not format then
		format = src.format
		if bottom_up == nil then bottom_up = src.bottom_up end
		stride = stride or src.stride
	end
	local dst = new(src.w, src.h, format, bottom_up, align, stride)
	return paint(dst, src)
end

local function clear(bmp, c)
	ffi.fill(bmp.data, bmp.h * bmp.stride, c)
end

--reflection

local function conversions(src_format)
	src_format = valid_format(src_format)
	return coroutine.wrap(function()
		for dname, dst_format in pairs(formats) do
			if dst_format.colortype == src_format.colortype then
				coroutine.yield(dname, dst_format)
			end
		end
		for dst_colortype in pairs(conv[src_format.colortype]) do
			for dname, dst_format in pairs(formats) do
				if dst_format.colortype == dst_colortype then
					coroutine.yield(dname, dst_format)
				end
			end
		end
	end)
end

local function dumpinfo()
	local function enumkeys(t)
		t = glue.keys(t)
		table.sort(t)
		return table.concat(t, ', ')
	end
	local format = '%-10s %-6s %-25s %-10s %s'
	print(string.format(format, '!format', 'bpp', 'ctype', 'colortype',
		'conversions'))
	for s,t in glue.sortedpairs(formats) do
		local ct = {}
		for d in conversions(s) do
			ct[#ct+1] = d
		end
		table.sort(ct)
		print(string.format(format, s, tostring(t.bpp), tostring(t.ctype),
			t.colortype, table.concat(ct, ', ')))
	end
	local format = '%-12s %-10s %-6s  ->  %s'
	print(string.format(format, '!colortype', 'channels', 'bpc',
		'conversions'))
	for s,t in glue.sortedpairs(conv) do
		local ct = colortypes[s]
		print(string.format(format, s, ct.channels, tostring(ct.bpc),
			enumkeys(t)))
	end
end


if not ... then require'bitmap_test' end

return glue.autoload({
	--format/stride math
	valid_format = valid_format,
	aligned_stride = aligned_stride,
	aligned_pointer = aligned_pointer,
	min_stride = min_stride,
	valid_stride = valid_stride,
	--bitmap info
	format = bitmap_format,
	stride = bitmap_stride,
	row_size = bitmap_row_size,
	colortype = bitmap_colortype,
	--bitmap operations
	new = new,
	paint = paint,
	copy = copy,
	clear = clear,
	sub = sub,
	--pixel interface
	--data_interface = data_interface, --publish if needed
	pixel_interface = pixel_interface,
	channel_interface = channel_interface,
	--reflection
	conversions = conversions,
	dumpinfo = dumpinfo,
	--extension
	colortypes = colortypes,
	formats = formats,
	converters = conv,
	rgb2g = rgb2g,
}, {
	dither    = 'bitmap_dither',
	invert    = 'bitmap_effects',
	grayscale = 'bitmap_effects',
	convolve  = 'bitmap_effects',
	sharpen   = 'bitmap_effects',
	mirror    = 'bitmap_effects',
	blend     = 'bitmap_blend',
	blend_op  = 'bitmap_blend',
	resize    = 'bitmap_resize',
})

