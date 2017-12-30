
--freetype ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'freetype_test'; return end

local ffi = require'ffi'
require'freetype_h'
local C = ffi.load'freetype'
local M = setmetatable({C = C}, {__index = C})

--utilities

local Error_Names = {
	[0x01] = 'Cannot Open Resource',
	[0x02] = 'Unknown File Format',
	[0x03] = 'Invalid File Format',
	[0x04] = 'Invalid Version',
	[0x05] = 'Lower Module Version',
	[0x06] = 'Invalid Argument',
	[0x07] = 'Unimplemented Feature',
	[0x08] = 'Invalid Table',
	[0x09] = 'Invalid Offset',
	[0x0A] = 'Array Too Large',
	[0x10] = 'Invalid Glyph Index',
	[0x11] = 'Invalid Character Code',
	[0x12] = 'Invalid Glyph Format',
	[0x13] = 'Cannot Render Glyph',
	[0x14] = 'Invalid Outline',
	[0x15] = 'Invalid Composite',
	[0x16] = 'Too Many Hints',
	[0x17] = 'Invalid Pixel Size',
	[0x20] = 'Invalid Handle',
	[0x21] = 'Invalid Library Handle',
	[0x22] = 'Invalid Driver Handle',
	[0x23] = 'Invalid Face Handle',
	[0x24] = 'Invalid Size Handle',
	[0x25] = 'Invalid Slot Handle',
	[0x26] = 'Invalid CharMap Handle',
	[0x27] = 'Invalid Cache Handle',
	[0x28] = 'Invalid Stream Handle',
	[0x30] = 'Too Many Drivers',
	[0x31] = 'Too Many Extensions',
	[0x40] = 'Out Of Memory',
	[0x41] = 'Unlisted Object',
	[0x51] = 'Cannot Open Stream',
	[0x52] = 'Invalid Stream Seek',
	[0x53] = 'Invalid Stream Skip',
	[0x54] = 'Invalid Stream Read',
	[0x55] = 'Invalid Stream Operation',
	[0x56] = 'Invalid Frame Operation',
	[0x57] = 'Nested Frame Access',
	[0x58] = 'Invalid Frame Read',
	[0x60] = 'Raster Uninitialized',
	[0x61] = 'Raster Corrupted',
	[0x62] = 'Raster Overflow',
	[0x63] = 'Raster Negative Height',
	[0x70] = 'Too Many Caches',
	[0x80] = 'Invalid Opcode',
	[0x81] = 'Too Few Arguments',
	[0x82] = 'Stack Overflow',
	[0x83] = 'Code Overflow',
	[0x84] = 'Bad Argument',
	[0x85] = 'Divide By Zero',
	[0x86] = 'Invalid Reference',
	[0x87] = 'Debug OpCode',
	[0x88] = 'ENDF In Exec Stream',
	[0x89] = 'Nested DEFS',
	[0x8A] = 'Invalid CodeRange',
	[0x8B] = 'Execution Too Long',
	[0x8C] = 'Too Many Function Defs',
	[0x8D] = 'Too Many Instruction Defs',
	[0x8E] = 'Table Missing',
	[0x8F] = 'Horiz Header Missing',
	[0x90] = 'Locations Missing',
	[0x91] = 'Name Table Missing',
	[0x92] = 'CMap Table Missing',
	[0x93] = 'Hmtx Table Missing',
	[0x94] = 'Post Table Missing',
	[0x95] = 'Invalid Horiz Metrics',
	[0x96] = 'Invalid CharMap Format',
	[0x97] = 'Invalid PPem',
	[0x98] = 'Invalid Vert Metrics',
	[0x99] = 'Could Not Find Context',
	[0x9A] = 'Invalid Post Table Format',
	[0x9B] = 'Invalid Post Table',
	[0xA0] = 'Syntax Error',
	[0xA1] = 'Stack Underflow',
	[0xA2] = 'Ignore',
	[0xA3] = 'No Unicode Glyph Name',
	[0xB0] = 'Missing Startfont Field',
	[0xB1] = 'Missing Font Field',
	[0xB2] = 'Missing Size Field',
	[0xB3] = 'Missing Fontboundingbox Field',
	[0xB4] = 'Missing Chars Field',
	[0xB5] = 'Missing Startchar Field',
	[0xB6] = 'Missing Encoding Field',
	[0xB7] = 'Missing Bbx Field',
	[0xB8] = 'Bbx Too Big',
	[0xB9] = 'Corrupted Font Header',
	[0xBA] = 'Corrupted Font Glyphs',
}

local function checknz(result)
	if result == 0 then return end
	error(string.format('freetype error %d: %s', result, Error_Names[result] or '<unknown error>'), 2)
end

local function nonzero(ret)
	return ret ~= 0 and ret or nil
end

local function ptr(p)
	return p ~= nil and p or nil
end

--wrappers

function M.FT_Init_FreeType()
	local library = ffi.new'FT_Library[1]'
	checknz(C.FT_Init_FreeType(library))
	return library[0]
end

function M.FT_Done_FreeType(library)
	checknz(C.FT_Done_FreeType(library))
end

function M.FT_New_Face(library, filename, i)
	local face = ffi.new'FT_Face[1]'
	checknz(C.FT_New_Face(library, filename, i or 0, face))
	return face[0]
end

function M.FT_New_Memory_Face(library, file_base, file_size, face_index)
	local face = ffi.new'FT_Face[1]'
	checknz(C.FT_New_Memory_Face(library, file_base, file_size, face_index or 0, face))
	return face[0]
end

--TODO: construct FT_Args
function M.FT_Open_Face(library, args, face_index)
	local face = ffi.new'FT_Face[1]'
	checknz(C.FT_Open_Face(library, args, face_index or 0, face))
	return face[0]
end

function M.FT_Reference_Face(face)
	checknz(C.FT_Reference_Face(face))
end

function M.FT_Attach_File(face, filepathname)
	checknz(C.FT_Attach_File(face, filepathname))
end

--TODO: construct FT_Args
function M.FT_Attach_Stream(face, parameters)
	checknz(C.FT_Attach_Stream(face, parameters))
end

function M.FT_Done_Face(face)
	checknz(C.FT_Done_Face(face))
end

function M.FT_Select_Size(face, strike_index)
	checknz(C.FT_Select_Size(face, strike_index))
end

function M.FT_Request_Size(face, req)
	req = req or ffi.new'FT_Size_Request'
	checknz(C.FT_Request_Size(face, req))
	return req
end

function M.FT_Set_Char_Size(face, char_width, char_height, horz_resolution, vert_resolution)
	checknz(C.FT_Set_Char_Size(face, char_width, char_height or 0, horz_resolution or 0, vert_resolution or 0))
end

function M.FT_Set_Pixel_Sizes(face, pixel_width, pixel_height)
	checknz(C.FT_Set_Pixel_Sizes(face, pixel_width, pixel_height or 0))
end

function M.FT_Load_Glyph(face, glyph_index, load_flags) --FT_LOAD_*
	checknz(C.FT_Load_Glyph(face, glyph_index, load_flags or 0))
end

function M.FT_Load_Char(face, char_code, load_flags) --FT_LOAD_*
	checknz(C.FT_Load_Char(face, char_code, load_flags))
end

function M.FT_Render_Glyph(slot, render_mode) --FT_RENDER_*
	checknz(C.FT_Render_Glyph(slot, render_mode or 0))
end

function M.FT_Get_Kerning(face, left_glyph, right_glyph, kern_mode, kerning) --FT_KERNING_*
	kerning = kerning or ffi.new'FT_Vector'
	checknz(C.FT_Get_Kerning(face, left_glyph, right_glyph, kern_mode, kerning))
	return kerning
end

function M.FT_Get_Track_Kerning(face, point_size, degree, kerning)
	kerning = kerning or ffi.new'FT_Vector'
	checknz(C.FT_Get_Track_Kerning(face, point_size, degree, kerning))
	return kerning
end

function M.FT_Get_Glyph_Name(face, glyph_index, buffer, buffer_max)
	buffer = buffer or ffi.new('uint8_t[?]', buffer_max or 64)
	local ret = C.FT_Get_Glyph_Name(face, glyph_index, buffer, buffer_max)
	return ret ~= 0 and ffi.string(buffer) or nil
end

function M.FT_Get_Postscript_Name(face)
	local name = C.FT_Get_Postscript_Name(face)
	return name ~= nil and ffi.string(name) or nil
end

function M.FT_Select_Charmap(face, encoding)
	if type(encoding) == 'string' then
		encoding = (s:byte(1) or 32) * 2^24 + (s:byte(2) or 32) * 2^16 + (s:byte(3) or 32) * 256 + (s:byte(4) or 32)
	end
	checknz(C.FT_Select_Charmap(face, encoding))
end

function M.FT_Set_Charmap(face, charmap)
	checknz(C.FT_Set_Charmap(face, charmap))
end

function M.FT_Get_Charmap_Index(charmap)
	local ret = C.FT_Get_Charmap_Index(charmap)
	assert(ret ~= -1, 'invalid charmap')
	return ret
end

local function face_chars(face) --returns iterator<charcode, glyph_index>
	local gindex = ffi.new'FT_UInt[1]'
	return function(_, charcode)
		if not charcode then
			charcode = C.FT_Get_First_Char(face, gindex)
		else
			charcode = C.FT_Get_Next_Char(face, charcode, gindex)
		end
		if gindex[0] == 0 then return end
		return charcode, gindex[0]
	end
end

local function face_char_count(face)
	local gindex = ffi.new'FT_UInt[1]'
	local charcode = C.FT_Get_First_Char(face, gindex)
	local n = 0
	while gindex[0] ~= 0 do
		n = n + 1
		charcode = C.FT_Get_Next_Char(face, charcode, gindex)
	end
	return n
end

function M.FT_Get_Name_Index(face, glyph_name)
	return nonzero(C.FT_Get_Name_Index(face, glyph_name))
end

function M.FT_Get_SubGlyph_Info(glyph, sub_index, p_index, p_flags, p_arg1, p_arg2, p_transform)
	p_index = p_index or ffi.new'FT_Int[1]'
	p_flags = p_flags or ffi.new'FT_UInt[1]'
	p_arg1  = p_arg1  or ffi.new'FT_Int[1]'
	p_arg2  = p_arg2  or ffi.new'FT_Int[1]'
	p_transform = p_transform or ffi.new'FT_Matrix'
	checknz(C.FT_Get_SubGlyph_Info(glyph, sub_index, p_index, p_flags, p_arg1, p_arg2, p_transform))
	return
		p_index[0], p_flags[0], p_arg1[0], p_arg2[0], p_transform
end

function M.FT_Face_GetCharVariantIndex(face, charcode, variantSelector)
	return nonzero(C.FT_Face_GetCharVariantIndex(face, charcode, variantSelector))
end

function M.FT_Face_GetCharVariantIsDefault(face, charcode, variantSelector)
	local ret = C.FT_Face_GetCharVariantIsDefault(face, charcode, variantSelector)
	if ret == -1 then return nil end
	return ret == 1 --1 if found in the standard (Unicode) cmap, 0 if found in the variation selector cmap
end

function M.FT_Face_GetVariantSelectors(face)
	return ptr(C.FT_Face_GetVariantSelectors(face))
end

function M.FT_Face_GetVariantsOfChar(face, charcode)
	return ptr(C.FT_Face_GetVariantsOfChar(face, charcode))
end

function M.FT_Face_GetCharsOfVariant(face, variantSelector)
	return ptr(C.FT_Face_GetCharsOfVariant(face, variantSelector))
end

function M.FT_Library_Version(library)
	local v = 'FT_Int[3]'
	C.FT_Library_Version(library, v, v+1, v+2)
	return v[0], v[1], v[2]
end

--ftbitmap.h

function M.FT_Bitmap_New(library)
	local bitmap = ffi.new'FT_Bitmap[1]'
	C.FT_Bitmap_New(bitmap)
	return bitmap[0]
end

function M.FT_Bitmap_Copy(library, source, target)
	checknz(C.FT_Bitmap_Copy(library, source, target))
end

function M.FT_Bitmap_Embolden(library, bitmap, xStrength, yStrength)
	checknz(C.FT_Bitmap_Embolden(library, bitmap, xStrength, yStrength))
end

function M.FT_Bitmap_Convert(library, source, target, alignment)
	checknz(C.FT_Bitmap_Convert(library, source, target, alignment))
end

function M.FT_GlyphSlot_Own_Bitmap(slot)
	checknz(C.FT_GlyphSlot_Own_Bitmap(slot))
end

function M.FT_Bitmap_Done(library, bitmap)
	checknz(C.FT_Bitmap_Done(library, bitmap))
end

--ftglyph.h

function M.FT_Get_Glyph(slot, glyph)
	glyph = glyph or ffi.new'FT_Glyph[1]'
	checknz(C.FT_Get_Glyph(slot, glyph))
	return glyph[0]
end

function M.FT_Glyph_Copy(source, target)
	target = target or ffi.new'FT_Glyph[1]'
	checknz(C.FT_Glyph_Copy(source, target))
	return target[0]
end

function M.FT_Glyph_Transform(glyph, matrix, delta)
	checknz(C.FT_Glyph_Transform(glyph, matrix, delta))
	return glyph
end

function M.FT_Glyph_To_Bitmap(glyph, render_mode, origin, destroy)
	if destroy == nil then destroy = true end
	local pglyph = ffi.new('FT_Glyph[1]', glyph)
	checknz(C.FT_Glyph_To_Bitmap(pglyph, render_mode or 0, origin, destroy))
	return pglyph[0]
end

--ftoutln.h

function M.FT_Outline_New(library, numPoints, numContours)
	numPoints = numPoints or 0xFFFF
	numContours = math.min(math.max(numContours or numPoints, 0), 0xFFFF)
	local outline = ffi.new'FT_Outline[1]'
	checknz(C.FT_Outline_New(library, numPoints, numContours, outline))
	return outline[0]
end

function M.FT_Outline_Done(library, outline)
	checknz(C.FT_Outline_Done(library, outline))
end

function M.FT_Outline_Decompose(outline, func_interface, userdata)
	checknz(C.FT_Outline_Decompose(outline, func_interface, userdata))
end

function M.FT_Outline_Check(outline)
	checknz(C.FT_Outline_Check(outline))
end

function M.FT_Outline_Get_CBox(outline, cbox)
	cbox = cbox or ffi.new'FT_BBox'
	checknz(C.FT_Outline_Get_CBox(outline, cbox))
	return cbox
end

function M.FT_Outline_Copy(source, target)
	checknz(C.FT_Outline_Copy(source, target))
	return target
end

function M.FT_Outline_Embolden(outline, xstrength, ystrength)
	if ystrength then
		checknz(C.FT_Outline_EmboldenXY(outline, xstrength, ystrength))
	else
		checknz(C.FT_Outline_Embolden(outline, xstrength))
	end
end

function M.FT_Outline_Reverse(outline)
	checknz(C.FT_Outline_Reverse(outline))
end

function M.FT_Outline_Get_Bitmap(library, outline, bitmap)
	checknz(C.FT_Outline_Get_Bitmap(library, outline, bitmap))
	return bitmap
end

function M.FT_Outline_Render(library, outline, params)
	checknz(C.FT_Outline_Render(library, outline, params))
end

--methods

M.new = M.FT_Init_FreeType

ffi.metatype('FT_LibraryRec', {__index = {
	free = M.FT_Done_FreeType,
	new_face = M.FT_New_Face,
	new_memory_face = M.FT_New_Memory_Face,
	open_face = M.FT_Open_Face,
	version = M.FT_Library_Version,
	--bitmaps
	new_bitmap = M.FT_Bitmap_New,
	copy_bitmap = M.FT_Bitmap_Copy,
	embolden_bitmap = M.FT_Bitmap_Embolden,
	convert_bitmap = M.FT_Bitmap_Convert,
	free_bitmap = M.FT_Bitmap_Done,
}})

ffi.metatype('FT_FaceRec', {__index = {
	free = M.FT_Done_Face,
	reference = M.FT_Reference_Face,
	attach_file = M.FT_Attach_File,
	atach_stream = M.FT_Attach_Stream,
	select_size = M.FT_Select_Size,
	request_size = M.FT_Request_Size,
	set_char_size = M.FT_Set_Char_Size,
	set_pixel_sizes = M.FT_Set_Pixel_Sizes,
	load_glyph = M.FT_Load_Glyph,
	load_char = M.FT_Load_Char,
	set_transform = M.FT_Set_Transform,
	kerning = M.FT_Get_Kerning,
	track_kerning = M.FT_Get_Track_Kerning,
	glyph_name = M.FT_Get_Glyph_Name,
	postscript_name = M.FT_Get_Postscript_Name,
	select_charmap = M.FT_Select_Charmap,
	set_charmap = M.FT_Set_Charmap,
	char_index = M.FT_Get_Char_Index,
	first_char = M.FT_Get_First_Char,
	next_char = M.FT_Get_Next_Char,
	chars = face_chars,
	char_count = face_char_count,
	name_index = M.FT_Get_Name_Index,
	--fstype_flags = M.FT_Get_FSType_Flags, --fstype stripped (needs type1)
	--glyph variants
	char_variant_index = M.FT_Face_GetCharVariantIndex,
	char_variant_is_default = M.FT_Face_GetCharVariantIsDefault,
	variant_selectors = M.FT_Face_GetVariantSelectors,
	variants_of_char = M.FT_Face_GetVariantsOfChar,
	chars_of_variant = M.FT_Face_GetCharsOfVariant,
}})

ffi.metatype('FT_GlyphSlotRec', {__index = {
	render = M.FT_Render_Glyph,
	subglyph_info = M.FT_Get_SubGlyph_Info,
	--bitmaps
	own_bitmap = M.FT_GlyphSlot_Own_Bitmap,
	--glyphs
	get_glyph = M.FT_Get_Glyph,
}})

ffi.metatype('FT_GlyphRec', {__index = {
	copy = M.FT_Glyph_Copy,
	transform = M.FT_Glyph_Transform,
	get_cbox = M.FT_Glyph_Get_CBox,
	to_bitmap = M.FT_Glyph_To_Bitmap,
	free = M.FT_Done_Glyph,
	as_bitmap = function(glyph)
		assert(glyph.format == C.FT_GLYPH_FORMAT_BITMAP)
		return ffi.cast('FT_BitmapGlyph', glyph)
	end,
	as_outline = function(glyph)
		assert(glyph.format == C.FT_GLYPH_FORMAT_OUTLINE)
		return ffi.cast('FT_BitmapGlyph', glyph)
	end,
}})

ffi.metatype('FT_CharMapRec', {__index = {
	index = M.FT_Get_Charmap_Index,
}})

ffi.metatype('FT_Bitmap', {__index = {
	copy     = function(self, library, ...) return M.FT_Bitmap_Copy(library, self, ...) end,
	embolden = function(self, library, ...) return M.FT_Bitmap_Embolden(library, self, ...) end,
	convert  = function(self, library, ...) return M.FT_Bitmap_Convert(library, self, ...) end,
	free     = function(self, library, ...) return M.FT_Bitmap_Done(library, self, ...) end,
}})

ffi.metatype('FT_Outline', {__index = {
	decompose = M.FT_Outline_Decompose,
	free = M.FT_Outline_Done,
	check = M.FT_Outline_Check,
	cbox = M.FT_Outline_Get_CBox,
	translate = M.FT_Outline_Translate,
	copy = M.FT_Outline_Copy,
	transform = M.FT_Outline_Transform,
	embolden = M.FT_Outline_Embolden,
	reverse = M.FT_Outline_Reverse,
	get_bitmap = function(self, library, ...) return M.FT_Outline_Get_Bitmap(library, self, ...) end,
	render = function(self, library, ...) return M.FT_Outline_Render(library, self, ...) end,
	orientation = M.FT_Outline_Get_Orientation,
}})

return M
