
setfenv(1, require'terra/low')
require'terra/bitarray'

local terra draw(a: bitarrview2d())
	for y=0,a.h do
		for x=0,a.w do
			pf('%c', iif(a:get(x, y), [('x'):byte()], [('_'):byte()]))
		end
		pfn('')
	end
end

local terra test_view2d_getset()
	var a = bitarrview2d()

	var b: uint64 = 0xdeadbeef1badbeefULL
	var b0 = b
	a.bits = [&uint8](&b)
	a.stride = 16
	a.w = 16
	a.h = 4
	assert(a.w <= a.stride)
	assert(a.stride * a.h <= sizeof(b) * 8)
	--invert all bits one-by-one
	var aa = a:sub(0, 0, a.w, a.h)
	for y=0,aa.h do
		for x=0,aa.w do
			aa:set(x, y, not aa:get(x, y))
		end
	end
	assert(b == not b0)
end
test_view2d_getset()

local terra test_view2d_fill_arrview()
	var buf = arr(uint8)
	buf.len = div_up(71 * 31, 8)
	var a = bitarrview2d()
	a.bits = buf.elements
	a.stride = 71
	a.w = 59
	a.h = 29
	a:asline():fill(false)
	for y=0,a.h do
		var ln = a:line(y)
		ln:fill(y, y, true)
		ln:fill(a.h-y-1, a.h-y-1, true)
	end
	var b = 11
	a:sub(b, b, a.w - 2*b, a.h - 2*b):fill(true)
	return a
end

local terra test_view2d_fill()
	draw(test_view2d_fill_arrview())
end
test_view2d_fill()

local terra test_view2d_copy()
	var a = test_view2d_fill_arrview()
	var b = test_view2d_fill_arrview()
	b:asline():fill(false)
	var asub = a:sub(5, 5, a.w-10, a.h-10)
	var bsub = b:sub(5, 5, maxint, maxint)
	asub:copy(&bsub)
	print()
	draw(b)
end
test_view2d_copy()

