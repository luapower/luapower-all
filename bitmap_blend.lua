
--bitmap porter-duff blending.
--Written by Cosmin Apreutesei. Public domain.

local bitmap = require'bitmap'
local box2d = require'box2d'

local op = {}

function op.clear (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return 0, 0, 0, 0 end
function op.src   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return Sr, Sg, Sb, Sa end
function op.dst   (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da, max) return Dr, Dg, Db, Da end

function op.src_over (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr + (1 - Sa) * Dr,
		Sg + (1 - Sa) * Dg,
		Sb + (1 - Sa) * Db,
		Sa + Da - Sa * Da
end

function op.dst_over (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Dr + (1 - Da) * Sr,
		Dg + (1 - Da) * Sg,
		Db + (1 - Da) * Sb,
		Sa + Da - Sa * Da
end

function op.src_in (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * Da,
		Sg * Da,
		Sb * Da,
		Sa * Da
end

function op.dst_in (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sa * Dr,
		Sa * Dg,
		Sa * Db,
		Sa * Da
end

function op.src_out (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Dr),
		Sg * (1 - Dg),
		Sb * (1 - Db),
		Sa * (1 - Da)
end

function op.dst_out (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Dr * (1 - Sa),
		Dg * (1 - Sa),
		Db * (1 - Sa),
		Da * (1 - Sa)
end

function op.src_atop (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * Da + (1 - Sa) * Dr,
		Sg * Da + (1 - Sa) * Dg,
		Sb * Da + (1 - Sa) * Db,
		Da
end

function op.dst_atop (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sa * Dr + Sr * (1 - Da),
		Sa * Dg + Sg * (1 - Da),
		Sa * Db + Sb * (1 - Da),
		Sa
end

function op.xor (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Da) + (1 - Sa) * Dr,
		Sg * (1 - Da) + (1 - Sa) * Dg,
		Sb * (1 - Da) + (1 - Sa) * Db,
		Sa + Da - 2 * Sa * Da
end

function op.darken (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * (1 - Da) + Dr * (1 - Sa) + math.min(Sr, Dr),
		Sg * (1 - Da) + Dg * (1 - Sa) + math.min(Sg, Dg),
		Sb * (1 - Da) + Db * (1 - Sa) + math.min(Sb, Db),
		Sa + Da - Sa * Da
end

function op.lighten (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		math.min(math.max(Sr * (1 - Da) + Dr * (1 - Sa) + math.max(Sr, Dr), 0), 1),
		math.min(math.max(Sg * (1 - Da) + Dg * (1 - Sa) + math.max(Sg, Dg), 0), 1),
		math.min(math.max(Sb * (1 - Da) + Db * (1 - Sa) + math.max(Sb, Db), 0), 1),
		math.min(math.max(Sa + Da - Sa * Da, 0), 1)
end

function op.modulate (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr * Dr,
		Sg * Dg,
		Sb * Db,
		Sa * Da
end

function op.screen (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	return
		Sr + Dr - Sr * Dr,
		Sg + Dg - Sg * Dg,
		Sb + Db - Sb * Db,
		Sa + Da - Sa * Da
end

function op.add (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	Da = math.min(1, Sa + Da)
	local mDa = 1 / Da
	return
		(Sr + Dr) * mDa,
		(Sg + Dg) * mDa,
		(Sb + Db) * mDa,
		Da
end

function op.saturate (Sr, Sg, Sb, Sa, Dr, Dg, Db, Da)
	local Za = math.min(Sa, 1 - Da)
	Da = math.min(1, Sa + Da)
	local mDa = 1 / Da
	return
		(Za * Sr + Dr) * mDa,
		(Za * Sg + Dg) * mDa,
		(Za * Sb + Db) * mDa,
		Da
end

function bitmap.blend(src, dst, operator, x0, y0)
	x0 = x0 or 0
	y0 = y0 or 0
	operator = operator or 'src_over'
	local operator = assert(op[operator], 'invalid operator')
	local src_getpixel = bitmap.pixel_interface(src, 'rgbaf')
	local dst_getpixel, dst_setpixel = bitmap.pixel_interface(dst, 'rgbaf')
	local _, _, w, h = box2d.clip(x0, y0, src.w, src.h, 0, 0, dst.w, dst.h)
	for y = 0, h-1 do
		for x = 0, w-1 do
			local Sr, Sg, Sb, Sa = src_getpixel(x, y)
			local Dr, Dg, Db, Da = dst_getpixel(x0 + x, y0 + y)
			dst_setpixel(x0 + x, y0 + y, operator(Sr, Sg, Sb, Sa, Dr, Dg, Db, Da))
		end
	end
end

bitmap.blend_op = op


if not ... then require'bitmap_blend_demo' end

