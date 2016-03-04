
--BMP file load/save.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'bmp_demo'; return end

local ffi = require'ffi'
local bit = require'bit'
local bitmap = require'bitmap'
local glue = require'glue'
local shr, shl, bor, band, bnot =
	bit.rshift, bit.lshift, bit.bor, bit.band, bit.bnot

local M = {}

--BITMAPFILEHEADER
local file_header = ffi.typeof[[struct __attribute__((__packed__)) {
	char     magic[2]; // 'BM'
	uint32_t size;
	uint16_t reserved1;
	uint16_t reserved2;
	uint32_t image_offset;
	uint32_t header_size;
}]]

--BITMAPCOREHEADER, Windows 2.0 or later
local core_header = ffi.typeof[[struct __attribute__((__packed__)) {
	// BITMAPCOREHEADER
	uint16_t w;
	uint16_t h;
	uint16_t planes;       // 1
	uint16_t bpp;          // 1, 4, 8, 24
}]]

--BITMAPINFOHEADER, Windows NT, 3.1x or later
local info_header = ffi.typeof[[struct __attribute__((__packed__)) {
	int32_t  w;
	int32_t  h;
	uint16_t planes;       // 1
	uint16_t bpp;          // 0, 1, 4, 8, 16, 24, 32; 64 (GDI+)
	uint32_t compression;  // 0-6
	uint32_t image_size;   // 0 for BI_RGB
	uint32_t dpi_v;
	uint32_t dpi_h;
	uint32_t palette_colors; // 0 = 2^n
	uint32_t palette_colors_important; // ignored
}]]

--BITMAPV2INFOHEADER, undocumented, Adobe Photoshop
local v2_header = ffi.typeof([[struct __attribute__((__packed__)) {
	$;
	uint32_t mask_r;
	uint32_t mask_g;
	uint32_t mask_b;
}]], info_header)

--BITMAPV3INFOHEADER, undocumented, Adobe Photoshop
local v3_header = ffi.typeof([[struct __attribute__((__packed__)) {
	$;
	uint32_t mask_a;
}]], v2_header)

--BITMAPV4HEADER, Windows NT 4.0, 95 or later
local v4_header = ffi.typeof([[struct __attribute__((__packed__)) {
	$;
	uint32_t cs_type;
	struct { int32_t rx, ry, rz, gx, gy, gz, bx, by, bz; } endpoints;
	uint32_t gamma_r;
	uint32_t gamma_g;
	uint32_t gamma_b;
}]], v3_header)

--BITMAPV5HEADER, Windows NT 5.0, 98 or later
local v5_header = ffi.typeof([[struct __attribute__((__packed__)) {
	$;
	uint32_t intent;
	uint32_t profile_data;
	uint32_t profile_size;
	uint32_t reserved;
}]], v4_header)

local rgb_triple = ffi.typeof[[struct __attribute__((__packed__)) {
	uint8_t b;
	uint8_t g;
	uint8_t r;
}]]

local rgb_quad = ffi.typeof([[struct __attribute__((__packed__)) {
	$;
	uint8_t a;
}]], rgb_triple)

local compressions = {[0] = 'rgb', 'rle8', 'rle4', 'bitfields',
	'jpeg', 'png', 'alphabitfields'}

local valid_bpps = {
	rgb = glue.index{1, 2, 4, 8, 16, 24, 32, 64},
	rle4 = glue.index{4},
	rle8 = glue.index{8},
	bitfields = glue.index{16, 32},
	alphabitfields = glue.index{16, 32},
	jpeg = glue.index{0},
	png = glue.index{0},
}

M.open = glue.protect(function(read_bytes)

	--wrap the reader so we can count the bytes read
	local bytes_read = 0
	local function read(buf, sz)
		local sz = sz or ffi.sizeof(buf)
		assert(read_bytes(buf, sz) == sz, 'eof')
		bytes_read = bytes_read + sz
		return buf
	end

	--load the file header and validate it
	local fh = read(file_header())
	assert(ffi.string(fh.magic, 2) == 'BM')

	--load the DIB header
	local z = fh.header_size - 4
	local core --the ancient core header is more restricted
	local alpha_mask = true --bitfields can contain a mask for alpha or not
	local quad_pal = true --palette entries are quads except for core header
	local ext_bitmasks = false
	local h
	if z == ffi.sizeof(core_header) then
		core = true
		quad_pal = false
		h = read(core_header())
	elseif z == ffi.sizeof(info_header) then
		alpha_mask = false --...unless comp == 'alphabitfields', see below
		ext_bitmasks = true --bitfield masks are right after the header
		h = read(info_header())
	elseif z == ffi.sizeof(v2_header) then
		alpha_mask = false
		h = read(v2_header())
	elseif z == ffi.sizeof(v3_header) then
		h = read(v3_header())
	elseif z == ffi.sizeof(v4_header) then
		h = read(v4_header())
	elseif z == ffi.sizeof(v5_header) then
		h = read(v5_header())
	elseif z == 64 + 4 then
		error'OS22XBITMAPHEADER is not supported'
	else
		error('invalid info header size '..(z+4))
	end

	--validate it and extract info from it
	assert(h.planes == 1, 'invalid number of planes')
	local comp = core and 0 or h.compression
	local comp = assert(compressions[comp], 'invalid compression type')
	alpha_mask = alpha_mask or comp == 'alphabitfields' --Windows CE
	local bpp = h.bpp
	assert(valid_bpps[comp][bpp], 'invalid bpp')
	local rle = comp:find'^rle'
	local bitfields = comp:find'bitfields$'
	local palettized = bpp >=1 and bpp <= 8
	local width = h.w
	local height = math.abs(h.h)
	local bottom_up = h.h > 0
	assert(width >= 1, 'invalid width')
	assert(height >= 1, 'invalid height')

	--load the channel masks for bitfield bitmaps
	local bitmasks, has_alpha
	if bitfields then
		bitmasks = ffi.new('uint32_t[?]', 4)
		local masks_size = (alpha_mask and 4 or 3) * 4
		if ext_bitmasks then
			read(bitmasks, masks_size)
		else
			local masks_ptr = ffi.cast('uint8_t*', h) + ffi.offsetof(h, 'mask_r')
			ffi.copy(bitmasks, masks_ptr, masks_size)
		end
		has_alpha = bitmasks[3] > 0
	end

	--make a one-time palette loader and indexer
	local load_pal
	local pal_size = fh.image_offset - bytes_read
	assert(pal_size >= 0, 'invalid image offset')
	local function noop() end
	local function skip_pal()
		read(nil, pal_size) --null-read to pixel data
		load_pal = noop
	end
	load_pal = skip_pal
	local pal_count = 0
	local pal
	if palettized then
		local pal_entry_ct = quad_pal and rgb_quad or rgb_triple
		local pal_ct = ffi.typeof('$[?]', pal_entry_ct)
		pal_count = math.floor(pal_size / ffi.sizeof(pal_entry_ct))
		pal_count = math.min(pal_count, 2^bpp)
		if pal_count > 0 then
			function load_pal()
				pal = read(pal_ct(pal_count))
				read(nil, pal_size - ffi.sizeof(pal)) --null-read to pixel data
				load_pal = noop
			end
		end
	end
	local function pal_entry(i)
		load_pal()
		assert(i < pal_count, 'palette index out of range')
		return pal[i].r, pal[i].g, pal[i].b, 0xff
	end

	--make a row loader iterator and a bitmap loader
	local row_iterator, load_rows
	local function init_load()

		assert(not row_iterator, 'already loaded')

		if comp == 'jpeg' then
			error'jpeg not supported'
		elseif comp == 'png' then
			error'png not supported'
		end

		--decide on the row bitmap format and if needed make a pixel converter
		local format, convert_pixel, dst_colorspace
		if bitfields then --packed, standard or custom format

			--compute the shift distance and the number of bits for each mask
			local function mask_shr_bits(mask)
				if mask == 0 then
					return 0, 0
				end
				local shift = 0
				while band(mask, 1) == 0 do --lowest bit not reached yet
					mask = shr(mask, 1)
					shift = shift + 1
				end
				local bits = 0
				while mask > 0 do --highest bit not cleared yet
					mask = shr(mask, 1)
					bits = bits + 1
				end
				return shift, bits
			end

			--build a standard format name based on the bitfield masks
			local t = {} --{shr1, ...}
			local tc = {} --{shr -> color}
			local tb = {} --{shr -> bits}
			for ci, color in ipairs{'r', 'g', 'b', 'a'} do
				local shr, bits = mask_shr_bits(bitmasks[ci-1])
				if bits > 0 then
					t[#t+1] = shr
					tc[shr] = color
					tb[shr] = bits
				end
			end
			table.sort(t, function(a, b) return a > b end)
			local tc2, tb2 = {}, {}
			for i,shr in ipairs(t) do
				tc2[i] = tc[shr]
				tb2[i] = tb[shr]
			end
			format = table.concat(tc2)..table.concat(tb2)
			format = format:gsub('([^%d])8?888$', '%18')

			--make a custom pixel converter if the bitfields do not represent
			--a standard format implemented in the `bitmap` module.
			if not bitmap.formats[format] then
				format = 'raw'..bpp
				dst_colorspace = 'rgba8'
				local r_and = bitmasks[0]
				local r_shr = mask_shr_bits(r_and)
				local g_and = bitmasks[1]
				local g_shr = mask_shr_bits(g_and)
				local b_and = bitmasks[2]
				local b_shr = mask_shr_bits(b_and)
				local a_and = bitmasks[3]
				local a_shr = mask_shr_bits(a_and)
				function convert_pixel(x)
					return
						shr(band(x, r_and), r_shr),
						shr(band(x, g_and), g_shr),
						shr(band(x, b_and), b_shr),
						has_alpha and shr(band(x, a_and), a_shr) or 0xff
				end
			end

		elseif bpp <= 8 then --palettized, using custom converter

			format = 'g'..bpp --using gray<1,2,4,8> as the base format
			dst_colorspace = 'rgba8'
			if bpp == 1 then
				function convert_pixel(g8)
					return pal_entry(shr(g8, 7))
				end
			elseif bpp == 2 then
				function convert_pixel(g8)
					return pal_entry(shr(g8, 6))
				end
			elseif bpp == 4 then
				function convert_pixel(g8)
					return pal_entry(shr(g8, 4))
				end
			elseif bpp == 8 then
				convert_pixel = pal_entry
			else
				assert(false)
			end

		else --packed, standard format

			local formats = {
				[16] = 'rgb0555',
				[24] = 'bgr8',
				[32] = 'bgrx8',
				[64] = 'bgrx16',
			}
			format = assert(formats[bpp])

		end

		--make a row reader: either a RLE decoder or a straight buffer reader
		local function row_reader(row_bmp)
			if rle then

				local read_pixels, fill_pixels

				local rle_buf = ffi.new'uint8_t[2]'
				local p = ffi.cast('uint8_t*', row_bmp.data)

				if bpp == 8 then --RLE8

					function read_pixels(i, n)
						read(p + i, n)
						--read the word-align padding
						local n2 = band(n + 1, bnot(1)) - n
						if n2 > 0 then
							read(nil, n2)
						end
					end

					function fill_pixels(i, n, v)
						ffi.fill(p + i, n, v)
					end

				elseif bpp == 4 then --RLE4

					local function shift_back(i, n) --shift data back one nibble
						local i0 = math.floor(i)
						if i0 == i then return end --no need for shifting
						p[i0] = bor(band(p[i0], 0xf0), shr(p[i0+1], 4)) --stitch the first nibble
						for i = math.ceil(i), i0 + n do
							p[i] = bor(shl(p[i], 4), shr(p[i+1], 4))
						end
					end

					function read_pixels(i, n)
						local i = i * 0.5
						local n = math.ceil(n * 0.5)
						read(p + math.ceil(i), n)
						shift_back(i, n)
						--read the word-align padding
						local n2 = band(n + 1, bnot(1)) - n
						if n2 > 0 then
							read(nil, n2)
						end
					end

					function fill_pixels(i, n, v)
						local i = i * 0.5
						local n = math.ceil(n * 0.5)
						ffi.fill(p + math.ceil(i), n, v)
						shift_back(i, n)
					end

				else
					assert(false)
				end

				local j = 0
				return function()
					local i = 0
					while true do
						read(rle_buf, 2)
						local n = rle_buf[0]
						local k = rle_buf[1]
						if n == 0 then --escape
							if k == 0 then --eol
								assert(i == width, 'RLE EOL too soon')
								j = j + 1
								break
							elseif k == 1 then --eof
								assert(j == height-1, 'RLE EOF too soon')
								break
							elseif k == 2 then --delta
								read(rle_buf, 2)
								local x = rle_buf[0]
								local y = rle_buf[1]
								--we can't use a row-by-row loader with this code
								error'RLE delta not supported'
							else --absolute mode: k = number of pixels to read
								assert(i + k <= width, 'RLE overflow')
								read_pixels(i, k)
								i = i + k
							end
						else --repeat: n = number of pixels to repeat, k = color
							assert(i + n <= width, 'RLE overflow')
							fill_pixels(i, n, k)
							i = i + n
						end
					end
				end

			else
				return function()
					read(row_bmp.data, row_bmp.stride)
				end
			end
		end

		function row_iterator(arg, alloc)

			local dst_bmp
			if type(arg) == 'table' and arg.data then --arg is a bitmap
				dst_bmp = arg
			else --arg is a format name or specifier
				dst_bmp = bitmap.new(width, 1, arg, false, true, nil, alloc)
			end

			--load row function: convert or direct copy
			local load_row
			local stride = bitmap.aligned_stride(bitmap.min_stride(format, width))
			if convert_pixel                 --needs pixel conversion
				or dst_bmp.format ~= format   --needs pixel conversion
				or dst_bmp.w < width          --needs clipping
				or dst_bmp.stride < stride    --can't copy whole stride
			then
				local row_bmp = bitmap.new(width, 1, format, false, true)
				local read_row = row_reader(row_bmp)
				function load_row()
					read_row()
					bitmap.paint(row_bmp, dst_bmp, 0, 0,
						convert_pixel, nil, dst_colorspace)
				end
			else --load row into dst_bmp directly
				load_row = row_reader(dst_bmp)
			end

			load_pal()

			--unprotected row iterator
			local j = bottom_up and height or -1
			local s = bottom_up and -1 or 1
			local k = bottom_up and -1 or height
			return function()
				j = j + s
				if j == k then return end
				load_row()
				return j, dst_bmp
			end
		end

		function load_rows(arg, ...)

			local dst_bmp, dst_x, dst_y
			if type(arg) == 'table' and arg.data then
				dst_bmp, dst_x, dst_y = arg, ...
			else
				local dst_format, alloc = arg, ...
				dst_bmp = bitmap.new(width, height, dst_format, false, true, nil, alloc)
			end
			local dst_x = dst_x or 0
			local dst_y = dst_y or 0

			local row_bmp = bitmap.new(width, 1, format, false, true)
			local read_row = row_reader(row_bmp)

			local function load_row(j)
				read_row()
				bitmap.paint(row_bmp, dst_bmp, dst_x, dst_y + j,
					convert_pixel, nil, dst_colorspace)
			end

			load_pal()

			if bottom_up then
				for j = height-1, 0, -1 do
					load_row(j)
				end
			else
				for j = 0, height-1 do
					load_row(j)
				end
			end
		end

	end

	local function bool(x)
		return x and true or false
	end

	--gather everything in a bmp object
	local bmp = {}
	--dimensions and color depth
	bmp.w = width
	bmp.h = height
	bmp.bpp = bpp
	--encoding info
	bmp.bottom_up = bottom_up
	bmp.compression = comp
	bmp.transparent = bool(has_alpha)
	bmp.palettized = bool(palettized)
	bmp.bitmasks = bitmasks --uint32_t[4] or nil
	bmp.rle = bool(rle)
	--low-level info
	bmp.file_header = fh
	bmp.header = h
	--palette
	bmp.pal_count = pal_count
	function bmp:load_pal()
		local ok, err = pcall(load_pal)
		if ok then
			self.pal = pal
			return true
		else
			return nil, err
		end
	end
	function bmp:pal_entry(i)
		return pal_entry(i)
	end
	--loading
	bmp.rows = function(self, ...)
		init_load()
		return row_iterator(...)
	end
	bmp.load = glue.protect(function(self, ...)
		init_load()
		return load_rows(...)
	end)

	return bmp
end)

M.save = glue.protect(function(bmp, write)
	local fh = file_header()
	local h = info_header()
	local image_size = h.w * h.h * 4
	local masks =
		'\x00\x00\xff\x00'..  --R
		'\x00\xff\x00\x00'..  --G
		'\xff\x00\x00\x00'..  --B
		'\x00\x00\x00\xff'    --A
	ffi.copy(fh.magic, 'BM', 2)
	fh.image_offset = ffi.sizeof(fh) + ffi.sizeof(h) + #masks
	fh.size = fh.image_offset + image_size
	fh.header_size = ffi.sizeof(h) + 4
	h.w = bmp.w
	h.h = bmp.h
	h.planes = 1
	h.bpp = 32
	h.compression = 3 --bitfields so we can have alpha
	h.image_size = image_size
	write(fh, ffi.sizeof(fh))
	write(h, ffi.sizeof(h))
	write(masks, #masks)
	--save progressively line-by-line using a 1-row bitmap
	local row_bmp = bitmap.new(bmp.w, 1, 'bgra8')
	for j=bmp.h-1,0,-1 do
		local src_row_bmp = bitmap.sub(bmp, 0, j, bmp.w, 1)
		bitmap.paint(src_row_bmp, row_bmp)
		write(row_bmp.data, row_bmp.stride)
	end
end)


return M
