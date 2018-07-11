local glue = require'glue'
local ffi = require'ffi'
local pp = require'pp'
local ft = require'freetype'

local function inspect_face(lib, facename)
	local face = lib:face(facename)

	print(facename)
	print(('-'):rep(78))

	local face_flag_names = {
		[ft.C.FT_FACE_FLAG_SCALABLE]            = 'SCALABLE',
		[ft.C.FT_FACE_FLAG_FIXED_SIZES]         = 'FIXED_SIZES',
		[ft.C.FT_FACE_FLAG_FIXED_WIDTH]         = 'FIXED_WIDTH',
		[ft.C.FT_FACE_FLAG_SFNT]                = 'SFNT',
		[ft.C.FT_FACE_FLAG_HORIZONTAL]          = 'HORIZONTAL',
		[ft.C.FT_FACE_FLAG_VERTICAL]            = 'VERTICAL',
		[ft.C.FT_FACE_FLAG_KERNING]             = 'KERNING',
		[ft.C.FT_FACE_FLAG_FAST_GLYPHS]         = 'FAST_GLYPHS',
		[ft.C.FT_FACE_FLAG_MULTIPLE_MASTERS]    = 'MULTIPLE_MASTERS',
		[ft.C.FT_FACE_FLAG_GLYPH_NAMES]         = 'GLYPH_NAMES',
		[ft.C.FT_FACE_FLAG_EXTERNAL_STREAM]     = 'EXTERNAL_STREAM',
		[ft.C.FT_FACE_FLAG_HINTER]              = 'HINTER',
		[ft.C.FT_FACE_FLAG_CID_KEYED]           = 'CID_KEYED',
		[ft.C.FT_FACE_FLAG_TRICKY]              = 'TRICKY',
	}

	local style_flag_names = {
		[ft.C.FT_STYLE_FLAG_ITALIC]  = 'ITALIC',
		[ft.C.FT_STYLE_FLAG_BOLD]    = 'BOLD',
	}

	local function flags(flags, flag_names)
		local s
		for k,v in pairs(flag_names) do
			s = bit.band(flags, k) ~= 0 and ((s and s..', ' or '')..v) or s
		end
		return s or ''
	end

	local function s4(i)
		i = tonumber(i)
		return
			string.char(bit.band(bit.rshift(i, 24), 255)) ..
			string.char(bit.band(bit.rshift(i, 16), 255)) ..
			string.char(bit.band(bit.rshift(i,  8), 255)) ..
			string.char(bit.band(bit.rshift(i,  0), 255))
	end

	local function pad(s, n)
		return s..(' '):rep(n - #s)
	end

	local function struct(t,fields,decoders,indent)
		indent = indent or ''
		local s = ''
		for i,k in ipairs(fields) do
			s = s .. '\n   ' .. indent .. pad(k..':', 21 - #indent) .. (decoders and decoders[k] or glue.pass)(t[k])
		end
		return s
	end

	local function struct_array(t,n,fields,decoders,indent)
		indent = indent or ''
		local s = ''
		for i=0,n-1 do
			for j,k in ipairs(fields) do
				s = s .. '\n ' .. (j == 1 and '* ' or '  ') .. indent .. pad(k..':', 21 - #indent) ..
						(decoders and decoders[k] or glue.pass)(t[i][k])
			end
		end
		return s
	end

	local bitmap_size_fields = {'height','width','size','x_ppem','y_ppem'}
	local bitmap_size_decoders = {height = tonumber, width = tonumber, size = tonumber, x_ppem = tonumber, y_ppem = tonumber}
	local charmap_fields = {'encoding','platform_id','encoding_id'}
	local charmap_decoders = {encoding = s4}
	local bbox_fields = {'xMin','yMin','xMax','yMax'}
	local bbox_decoders = {xMin = tonumber, yMin = tonumber, xMax = tonumber, yMax = tonumber}
	local metrics_fields = {'x_ppem','y_ppem','x_scale','y_scale','ascender','descender','height','max_advance'}
	local metrics_decoders = { x_ppem = tonumber, y_ppem = tonumber, x_scale = tonumber, y_scale = tonumber, ascender = tonumber, descender = tonumber, height = tonumber, max_advance = tonumber}
	local size_fields = {'metrics'}
	local size_decoders = {metrics = function(m) return struct(m, metrics_fields, metrics_decoders, '   ') end}
	print('num_faces:           ', face.num_faces)
	print('face_index:          ', tonumber(face.face_index))
	print('face_flags:          ', flags(tonumber(face.face_flags), face_flag_names))
	print('style_flags:         ', flags(tonumber(face.style_flags), style_flag_names))
	print('num_glyphs:          ', face.num_glyphs)
	print('familiy_name:        ', ffi.string(face.family_name))
	print('style_name:          ', ffi.string(face.style_name))
	print('num_fixed_sizes:     ', face.num_fixed_sizes)
	print('available_sizes:     ', struct_array(face.available_sizes, face.num_fixed_sizes, bitmap_size_fields, bitmap_size_decoders))
	print('num_charmaps:        ', face.num_charmaps)
	print('charmaps:            ', struct_array(face.charmaps, face.num_charmaps, charmap_fields, charmap_decoders))
	print('bbox:                ', struct(face.bbox, bbox_fields, bbox_decoders))
	print('units_per_EM:        ', face.units_per_EM)
	print('ascender:            ', face.ascender)
	print('descender:           ', face.descender)
	print('height:              ', face.height)
	print('max_advance_width:   ', face.max_advance_width)
	print('max_advance_height:  ', face.max_advance_height)
	print('underline_position:  ', face.underline_position)
	print('underline_thickness: ', face.underline_thickness)
	print('size:                ', struct(face.size, size_fields, size_decoders))
	print('charmap:             ', struct(face.charmap, charmap_fields, charmap_decoders))

	face:set_pixel_sizes(16)
	for i=0,face.num_charmaps-1 do
		face:select_charmap(face.charmaps[i].encoding)
		local n = face:char_count()
		print(string.format('charmap %d:              %d\tentries', i, n))
	end

	print()
	face:free()
end

local lib = ft:new()

inspect_face(lib, 'media/fonts/DejaVuSerif.ttf')
inspect_face(lib, 'media/fonts/amiri-regular.ttf')
inspect_face(lib, 'media/fonts/fireflysung.ttf')

lib:free()
