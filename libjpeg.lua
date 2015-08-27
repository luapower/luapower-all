
--libjpeg ffi binding.
--Written by Cosmin Apreutesei. Public domain.

local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
local stdio = require'stdio'
local jit = require'jit'
require'libjpeg_h'
local C = ffi.load'jpeg'

local LIBJPEG_VERSION = 62

--NOTE: images with C.JCS_UNKNOWN format are not supported.
local formats = {
	[C.JCS_GRAYSCALE]= 'g8',
	[C.JCS_YCbCr]    = 'ycc8',
	[C.JCS_CMYK]     = 'cmyk8',
	[C.JCS_YCCK]     = 'ycck8',
	[C.JCS_RGB]      = 'rgb8',
	--libjpeg-turbo only
	[C.JCS_EXT_RGB]  = 'rgb8',
	[C.JCS_EXT_BGR]  = 'bgr8',
	[C.JCS_EXT_RGBX] = 'rgbx8',
	[C.JCS_EXT_BGRX] = 'bgrx8',
	[C.JCS_EXT_XRGB] = 'xrgb8',
	[C.JCS_EXT_XBGR] = 'xbgr8',
	[C.JCS_EXT_RGBA] = 'rgba8',
	[C.JCS_EXT_BGRA] = 'bgra8',
	[C.JCS_EXT_ARGB] = 'argb8',
	[C.JCS_EXT_ABGR] = 'abgr8',
}

local channel_count = {
	g8 = 1, ycc8 = 3, cmyk8 = 4, ycck8 = 4, rgb8 = 3, bgr8 = 3,
	rgbx8 = 4, bgrx8 = 4, xrgb8 = 4, xbgr8 = 4,
	rgba8 = 4, bgra8 = 4, argb8 = 4, abgr8 = 4,
}

local color_spaces = glue.index(formats)

--all conversions that libjpeg implements, in order of preference.
--{source = {dest1, ...}}
local conversions = {
	ycc8 = {'rgb8', 'bgr8', 'rgba8', 'bgra8', 'argb8', 'abgr8', 'rgbx8',
		'bgrx8', 'xrgb8', 'xbgr8', 'g8'},
	g8 = {'rgb8', 'bgr8', 'rgba8', 'bgra8', 'argb8', 'abgr8', 'rgbx8', 'bgrx8',
		'xrgb8', 'xbgr8'},
	ycck8 = {'cmyk8'},
}

--given current pixel format of an image and an accept table,
--choose the best accepted pixel format.
local function best_format(format, accept)
	if not accept or accept[format] then --no preference or source format accepted
		return format
	end
	if conversions[format] then
		for _,dformat in ipairs(conversions[format]) do
			if accept[dformat] then --convertible to the best accepted format
				return dformat
			end
		end
	end
	return format --not convertible
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

--create a callback manager object and its destructor.
local function callback_manager(mgr_ctype, callbacks)
	local mgr = ffi.new(mgr_ctype)
	local cbt = {}
	for k,f in pairs(callbacks) do
		if type(f) == 'function' then
			cbt[k] = ffi.cast(string.format('jpeg_%s_callback', k), f)
			mgr[k] = cbt[k]
		else
			mgr[k] = f
		end
	end
	local function free_mgr()
		ffi.gc(mgr, nil)
		for k,cb in pairs(cbt) do
			mgr[k] = nil
			cb:free()
		end
	end
	ffi.gc(mgr, free_mgr)
	return mgr, free_mgr
end

--end-of-image marker, inserted on EOF for partial display of broken images.
local JPEG_EOI = string.char(0xff, 0xD9):rep(32)

local dct_methods = {
	accurate = C.JDCT_ISLOW,
	fast = C.JDCT_IFAST,
	float = C.JDCT_FLOAT,
}

local ccptr_ct = ffi.typeof'const uint8_t*' --const prevents copying

--create and setup a error handling object.
local function jpeg_err(t, finally)
	local jerr = ffi.new'jpeg_error_mgr'
	C.jpeg_std_error(jerr)
	local err_cb = ffi.cast('jpeg_error_exit_callback', function(cinfo)
		local buf = ffi.new'uint8_t[512]'
		cinfo.err.format_message(cinfo, buf)
		error(ffi.string(buf))
	end)
	local warnbuf --cache this buffer because there are a ton of messages
	local emit_cb = ffi.cast('jpeg_emit_message_callback', function(cinfo, level)
		if t.warning then
			warnbuf = warnbuf or ffi.new'uint8_t[512]'
			cinfo.err.format_message(cinfo, warnbuf)
			t.warning(ffi.string(warnbuf), level)
		end
	end)
	finally(function() --anchor jerr, err_cb, emit_cb
		C.jpeg_std_error(jerr) --reset jerr fields
		err_cb:free()
		emit_cb:free()
	end)
	jerr.error_exit = err_cb
	jerr.emit_message = emit_cb
	return jerr
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

		--create the state object and output image
		local cinfo = ffi.new'jpeg_decompress_struct'
		local img = {}

		--setup error handling
		cinfo.err = jpeg_err(t, finally)

		--init state
		C.jpeg_CreateDecompress(cinfo,
			t.lib_version or LIBJPEG_VERSION,
			ffi.sizeof(cinfo))
		finally(function() C.jpeg_destroy_decompress(cinfo) end)

		--setup source
		if t.stream then

			C.jpeg_stdio_src(cinfo, t.stream)

		elseif t.path then

			local file = stdio.fopen(t.path, 'rb')
			finally(function()
				C.jpeg_stdio_src(cinfo, nil)
				file:close()
			end)
			C.jpeg_stdio_src(cinfo, file)

		elseif t.string or t.cdata or t.read then

			--wrap cdata and string into a one-shot stream reader.
			local read = t.read
				or t.string and one_shot_reader(t.string)
				or t.cdata  and one_shot_reader(t.cdata, t.size)

			--create source callbacks
			local cb = {}
			cb.init_source = glue.pass
			cb.term_source = t.finish or glue.pass
			cb.resync_to_restart = C.jpeg_resync_to_restart

			local partial_loading = t.partial_loading ~= false

			local buf, sz, s --upvalues to prevent collecting between calls
			function cb.fill_input_buffer(cinfo)
				s = nil --release the string from the last call if any
				buf, sz = read() --replace the buffer from the last call
				if not buf then
					if partial_loading then
						buf = JPEG_EOI
						img.partial = true
					else
						error'eof'
					end
				end
				if type(buf) == 'string' then
					s = buf --anchor buf in upvalue to prevent collecting
					buf = ffi.cast(ccptr_ct, s) --const prevents string copy
					sz = #s
				end
				assert(sz > 0, 'eof')
				cinfo.src.bytes_in_buffer = sz
				cinfo.src.next_input_byte = buf
				return true
			end

			function cb.skip_input_data(cinfo, sz)
				if sz <= 0 then return end
				while sz > cinfo.src.bytes_in_buffer do
					sz = sz - cinfo.src.bytes_in_buffer
					cb.fill_input_buffer(cinfo)
				end
				cinfo.src.next_input_byte = cinfo.src.next_input_byte + sz
				cinfo.src.bytes_in_buffer = cinfo.src.bytes_in_buffer - sz
			end

			--create a source manager and set it up
			local mgr, free_mgr = callback_manager('jpeg_source_mgr', cb)
			cinfo.src = mgr
			finally(function() --the finalizer anchors mgr through free_mgr!
				cinfo.src = nil
				free_mgr()
			end)

			cinfo.src.bytes_in_buffer = 0
			cinfo.src.next_input_byte = nil
		else
			error'source missing'
		end

		--read header
		assert(C.jpeg_read_header(cinfo, 1) ~= 0, 'eof')

		img.file = {}
		img.file.w = cinfo.image_width
		img.file.h = cinfo.image_height
		img.file.format = formats[tonumber(cinfo.jpeg_color_space)]
		img.file.progressive = C.jpeg_has_multiple_scans(cinfo) ~= 0

		img.file.jfif = cinfo.saw_JFIF_marker == 1 and {
			maj_ver = cinfo.JFIF_major_version,
			min_ver = cinfo.JFIF_minor_version,
			density_unit = cinfo.density_unit,
			x_density = cinfo.X_density,
			y_density = cinfo.Y_density,
		} or nil

		img.file.adobe = cinfo.saw_Adobe_marker == 1 and {
			transform = cinfo.Adobe_transform,
		} or nil

		if t.header_only then
			return img
		end

		--find the best accepted output pixel format
		assert(img.file.format, 'invalid pixel format')
		assert(cinfo.num_components == channel_count[img.file.format])
		img.format = best_format(img.file.format, t.accept)

		--set decompression options
		cinfo.out_color_space = assert(color_spaces[img.format])
		cinfo.output_components = channel_count[img.format]
		cinfo.scale_num = t.scale_num or 1
		cinfo.scale_denom = t.scale_denom or 1
		cinfo.dct_method =
			assert(dct_methods[t.dct_method or 'accurate'], 'invalid dct_method')
		cinfo.do_fancy_upsampling = t.fancy_upsampling or false
		cinfo.do_block_smoothing = t.block_smoothing or false
		cinfo.buffered_image = img.file.progressive and t.render_scan and 1 or 0

		--start decompression, which fills the info about the output image
		C.jpeg_start_decompress(cinfo)

		--get info about the output image
		img.w = cinfo.output_width
		img.h = cinfo.output_height

		--compute the stride
		img.stride = cinfo.output_width * cinfo.output_components
		if t.accept and t.accept.stride_aligned then
			img.stride = pad_stride(img.stride)
		end

		--allocate image and row buffers
		img.size = img.h * img.stride
		img.data = ffi.new('uint8_t[?]', img.size)
		img.bottom_up = t.accept and t.accept.bottom_up

		local rows = rows_buffer(img.h, img.bottom_up, img.data, img.stride)

		--finally, decompress the image
		local function render_scan(last_scan, scan_number, multiple_scans)

			--read all the scanlines into the row buffers
			while cinfo.output_scanline < img.h do

				--read several scanlines at once, depending on the size of the output buffer
				local i = cinfo.output_scanline
				local n = math.min(img.h - i, cinfo.rec_outbuf_height)
				local actual = C.jpeg_read_scanlines(cinfo, rows + i, n)
				assert(actual == n)
				assert(cinfo.output_scanline == i + actual)
			end

			--call the rendering callback on the converted image
			if t.render_scan then
				t.render_scan(img, last_scan, scan_number)
			end
		end

		if cinfo.buffered_image == 1 then --multiscan reading
			while true do
				--read all the scanlines of the current scan
				local ret
				repeat
					ret = C.jpeg_consume_input(cinfo)
					assert(ret ~= C.JPEG_SUSPENDED, 'eof')
				until ret == C.JPEG_REACHED_EOI or ret == C.JPEG_SCAN_COMPLETED
				local last_scan = ret == C.JPEG_REACHED_EOI

				--render the scan
				C.jpeg_start_output(cinfo, cinfo.input_scan_number)
				render_scan(last_scan, cinfo.output_scan_number, true)
				C.jpeg_finish_output(cinfo)

				if C.jpeg_input_complete(cinfo) ~= 0 then return end
			end
		else
			render_scan(true, 1, false)
		end

		C.jpeg_finish_decompress(cinfo)

		return img
	end)
end

jit.off(load, true) --can't call error() from callbacks called from C

local function save(t)

	return glue.fcall(function(finally)

		--create the state object.
		local cinfo = ffi.new'jpeg_compress_struct'

		--setup error handling.
		cinfo.err = jpeg_err(t, finally)

		--init state.
		C.jpeg_CreateCompress(cinfo,
			t.lib_version or LIBJPEG_VERSION,
			ffi.sizeof(cinfo))
		finally(function() C.jpeg_destroy_compress(cinfo) end)

		--setup destination.
		local ret

		if t.stream then

			C.jpeg_stdio_dest(cinfo, t.stream)

		elseif t.path then

			local file = stdio.fopen(t.path, 'wb')
			finally(function()
				C.jpeg_stdio_dest(cinfo, nil)
				file:close()
			end)
			C.jpeg_stdio_dest(cinfo, file)

		else

			--create the write and finish functions.
			local write, finish
			local user_finish = t.finish or glue.pass
			if t.write then --sink output
				write = t.write
				finish = user_finish
			elseif t.chunks then --table output
				function write(buf, sz)
					table.insert(t.chunks, ffi.string(buf, sz))
				end
				function finish()
					ret = t.chunks
					user_finish()
				end
			else --string output
				local chunks = {}
				function write(buf, sz)
					table.insert(chunks, ffi.string(buf, sz))
				end
				function finish()
					ret = table.concat(chunks)
					user_finish()
				end
			end

			--create the dest. buffer.
			local sz = t.bufsize or 4096
			local buf = ffi.new('char[?]', sz)

			--create destination callbacks.
			local cb = {}

			function cb.init_destination(cinfo)
				cinfo.dest.next_output_byte = buf
				cinfo.dest.free_in_buffer = sz
			end

			function cb.term_destination(cinfo)
				write(buf, sz - cinfo.dest.free_in_buffer)
				finish()
			end

			function cb.empty_output_buffer(cinfo)
				write(buf, sz)
				cb.init_destination(cinfo)
				return true
			end

			--create a destination manager and set it up.
			local mgr, free_mgr = callback_manager('jpeg_destination_mgr', cb)
			cinfo.dest = mgr
			finally(function() --the finalizer anchors mgr through free_mgr!
				cinfo.dest = nil
				free_mgr()
			end)

		end

		--set source format.
		cinfo.image_width = t.bitmap.w
		cinfo.image_height = t.bitmap.h
		cinfo.in_color_space =
			assert(color_spaces[t.bitmap.format], 'invalid source format')
		cinfo.input_components =
			assert(channel_count[t.bitmap.format], 'invalid source format')

		--set the default compression options based on in_color_space.
		C.jpeg_set_defaults(cinfo)

		--set compression options.
		if t.format then
			C.jpeg_set_colorspace(cinfo,
				assert(color_spaces[t.format], 'invalid destination format'))
		end
		if t.quality then
			C.jpeg_set_quality(cinfo, t.quality, true)
		end
		if t.progressive then
			C.jpeg_simple_progression(cinfo)
		end
		if t.dct_method then
			cinfo.dct_method =
				assert(dct_methods[t.dct_method], 'invalid dct_method')
		end
		if t.optimize_coding then
			cinfo.optimize_coding = t.optimize_coding
		end
		if t.smoothing then
			cinfo.smoothing_factor = t.smoothing
		end

		--start the compression cycle.
		C.jpeg_start_compress(cinfo, true)

		--make row pointers from the bitmap buffer.
		local bmp = t.bitmap
		local rows = rows_buffer(bmp.h, bmp.bottom_up, bmp.data, bmp.stride)

		--compress rows.
		C.jpeg_write_scanlines(cinfo, rows, bmp.h)

		--finish the compression, optionally adding additional scans.
		C.jpeg_finish_compress(cinfo)

		return ret
	end)
end

jit.off(save, true) --can't call error() from callbacks called from C

if not ... then
	require'libjpeg_test'
	require'libjpeg_demo'
end

return {
	load = load,
	save = save,
	C = C,
}

