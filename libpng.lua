
--libpng binding for libpng 1.5.6+
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'libpng_demo'; return end

local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue' --fcall
local jit = require'jit' --off
require'libpng_h'
local C = ffi.load'png'

local PNG_LIBPNG_VER_STRING = '1.5.10'

local channels = {
	[C.PNG_COLOR_TYPE_GRAY] = 'g',         --bpc 1,2,4,8,16
	[C.PNG_COLOR_TYPE_RGB] = 'rgb',        --bpc 8,16
	[C.PNG_COLOR_TYPE_RGB_ALPHA] = 'rgba', --bpc 8,16
	[C.PNG_COLOR_TYPE_GRAY_ALPHA] = 'ga',  --bpc 8,16
}

--given a reader function that returns an unknwn amount of bytes each time
--it is called, return a reader function which expects an exact amount
--of bytes to be filled in, each time it is called.
local const_char_ptr = ffi.typeof'const char*' --const prevents string copy
local function buffered_reader(read, bufsize)
	local buf, s --upvalues so they don't get collected between calls
	local left = 0 --how much bytes left to consume from the current buffer
	local sbuf --current pointer in buf
	return function(dbuf, dsz)
		while dsz > 0 do
			--if current buffer is empty, refill it
			if left == 0 then
				s, buf = nil --release current string and buffer
				buf, left = read(dsz) --read and anchor the new buffer
				if not buf then
					error'eof'
				end
				if type(buf) == 'string' then
					s = buf --pin the new string
					buf = ffi.cast(const_char_ptr, s)
					left = #s
				else
					assert(left, 'size missing')
				end
				assert(left > 0, 'eof')
				sbuf = buf
			end
			--consume from buffer, till empty or till size
			local sz = math.min(dsz, left)
			ffi.copy(dbuf, sbuf, sz)
			sbuf = sbuf + sz
			dbuf = dbuf + sz
			left = left - sz
			dsz = dsz - sz
		end
	end
end

--given a row stride, return the next larger stride that is a multiple of 4.
local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

--given a string or cdata/size pair, return a reader function that returns
--the entire data on the first call.
local function one_shot_reader(buf, sz)
	local done
	return function()
		if done then return end
		done = true
		return buf, sz
	end
end

--create a top-down or bottom-up array of rows pointing to a bitmap buffer.
local function rows_buffer(h, bottom_up, data, stride)
	local rows = ffi.new('uint8_t*[?]', h)
	if bottom_up then
		for i=0,h-1 do
			rows[h-1-i] = data + (i * stride)
		end
	else
		for i=0,h-1 do
			rows[i] = data + (i * stride)
		end
	end
	return rows
end

local function load(t)
	return glue.fcall(function(finally)

		--normalize args
		if type(t) == 'string' then
			t = {path = t}
		elseif type(t) == 'function' then
			t = {read = t}
		end

		--create the state objects
		local png_ptr = assert(C.png_create_read_struct(
			t.lib_version or PNG_LIBPNG_VER_STRING,
			nil, nil, nil))
		local info_ptr = assert(C.png_create_info_struct(png_ptr))
		finally(function()
			local png_ptr = ffi.new('png_structp[1]', png_ptr)
			local info_ptr = ffi.new('png_infop[1]', info_ptr)
			C.png_destroy_read_struct(png_ptr, info_ptr, nil)
		end)

		--setup error handling
		local warning_cb = ffi.cast('png_error_ptr', function(png_ptr, err)
			if t.warning then
				t.warning(ffi.string(err))
			end
		end)
		local error_cb = ffi.cast('png_error_ptr', function(png_ptr, err)
			error(ffi.string(err))
		end)
		finally(function()
			C.png_set_error_fn(png_ptr, nil, nil, nil)
			error_cb:free()
			warning_cb:free()
		end)
		C.png_set_error_fn(png_ptr, nil, error_cb, warning_cb)

		--setup input source
		if t.stream then

			C.png_init_io(png_ptr, t.stream)

		elseif t.path then

			local file = io.open(t.path, 'rb')
			finally(function()
				C.png_init_io(png_ptr, nil)
				file:close()
			end)
			C.png_init_io(png_ptr, file)

		elseif t.string or t.cdata or t.read then

			--wrap cdata and string into a one-shot stream reader.
			local read = t.read
				or t.string and one_shot_reader(t.string)
				or t.cdata  and one_shot_reader(t.cdata, t.size)

			--wrap the stream reader into a buffered reader.
			local buffered_read = buffered_reader(read)

			--wrap the buffered reader so that errors go through png_error().
			local function png_read(png_ptr, dbuf, dsz)
				local ok, err = pcall(buffered_read, dbuf, tonumber(dsz))
				if not ok then C.png_error(png_ptr, err) end
			end

			--wrap the png reader into a RAII callback object.
			local read_cb = ffi.cast('png_rw_ptr', png_read)
			finally(function()
				C.png_set_read_fn(png_ptr, nil, nil)
				read_cb:free()
			end)

			--put the onion into the oven.
			C.png_set_read_fn(png_ptr, nil, read_cb)
		else
			error'source missing'
		end

		local function image_info(t)
			t = t or {}
			t.w = C.png_get_image_width(png_ptr, info_ptr)
			t.h = C.png_get_image_height(png_ptr, info_ptr)
			t.bpc = C.png_get_bit_depth(png_ptr, info_ptr)
			local ct = C.png_get_color_type(png_ptr, info_ptr)
			t.paletted =
				bit.band(ct, C.PNG_COLOR_MASK_PALETTE) ==
					C.PNG_COLOR_MASK_PALETTE
			ct = bit.band(ct, bit.bnot(C.PNG_COLOR_MASK_PALETTE))
			t.channels = channels[ct]
			t.format = t.channels .. t.bpc
			t.interlaced =
				C.png_get_interlace_type(png_ptr, info_ptr) ~=
					C.PNG_INTERLACE_NONE
			local bg = ffi.new'png_color_16'
			local bgp = ffi.new('png_color_16p[1]', bg)
			if C.png_get_bKGD(png_ptr, info_ptr, bgp) ~= 0 then
				t.bgcolor = bg
			end
			return t
		end

		--read header
		C.png_read_info(png_ptr, info_ptr)
		local img = {}
		img.file = image_info()

		if t.header_only then
			return img
		end

		--expand 1,2,4->8bpc, palette->8bpc, tRNS->alpha
		C.png_set_expand(png_ptr)

		--convert 16bpc big-endian values to little-endian.
		if ffi.abi'le' and img.file.bpc == 16 then
			C.png_set_swap(png_ptr)
		end

		--premultiply alpha using linear gamma (cairo compatible)
		--NOTE: this doubles the loading time.
		if img.file.channels:find'a' and t.premultiply ~= false then
			C.png_set_alpha_mode(png_ptr, C.PNG_ALPHA_STANDARD, C.PNG_GAMMA_LINEAR)
		end

		--local my_background = ffi.new('png_color_16', 0, 0xffff, 0xffff, 0xffff, 0xffff)
		if img.file.bgcolor then
			C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
			C.png_set_background(png_ptr, img.file.bgcolor,
				C.PNG_BACKGROUND_GAMMA_FILE, 1, 1.0)
		end

		--deinterlace
		local passes = C.png_set_interlace_handling(png_ptr)
		img.file.passes = passes

		--apply transformations and get the new transformed header.
		C.png_read_update_info(png_ptr, info_ptr)

		--check that the transformations had the desired effect.
		local info = image_info()
		assert(info.w == img.file.w)
		assert(info.h == img.file.h)
		assert(not info.paletted)
		assert(info.bpc >= 8)

		--set output image fields
		img.w = info.w
		img.h = info.h
		img.format = info.format

		--compute the stride
		img.stride = tonumber(C.png_get_rowbytes(png_ptr, info_ptr))
		if t.accept and t.accept.stride_aligned then
			img.stride = pad_stride(img.stride)
		end

		--allocate image and rows buffers
		img.size = img.h * img.stride
		img.data = ffi.new('uint8_t[?]', img.size)
		img.bottom_up = t.accept and t.accept.bottom_up

		local rows = rows_buffer(img.h, img.bottom_up, img.data, img.stride)

		--finally, decompress the image
		if passes > 1 and t.render_scan then --multipass reading
			for pass = 1, passes do
				if t.sparkle then
					C.png_read_rows(png_ptr, rows, nil, img.h)
				else
					C.png_read_rows(png_ptr, nil, rows, img.h)
				end
				if t.render_scan then
					local last_pass = pass == passes
					t.render_scan(img, last_pass, pass)
				end
			end
		else
			C.png_read_image(png_ptr, rows)
			if t.render_scan then
				t.render_scan(img, true, 1)
			end
		end

		C.png_read_end(png_ptr, info_ptr)
		return img
	end)
end

jit.off(load, true) --can't call error() from callbacks called from C

return {
	load = load,
	C = C,
}
