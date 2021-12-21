
--freetype ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'freetype_test'; return end

local ffi = require'ffi'
local bit = require'bit'
require'freetype_h'
local C = ffi.load'freetype'
local freetype = {C = C}
setmetatable(freetype, freetype)

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

local has_error_strings = pcall(function () return C.FT_Error_String end)
local function checkz(result)
	if result == 0 then return end
	local estr
	if has_error_strings then estr = C.FT_Error_String(result) end
	estr = estr~=nil and ffi.string(estr) or nil
	error(string.format('freetype error %d: %s', result,
		estr or Error_Names[result] or '<unknown error>'), 2)
end

local function nonzero(ret)
	return ret ~= 0 and ret or nil
end

local function ptr(p)
	return p ~= nil and p or nil
end

function freetype.tag_tostring(i)
	i = tonumber(i)
	return
		string.char(bit.band(bit.rshift(i, 24), 0xff)) ..
		string.char(bit.band(bit.rshift(i, 16), 0xff)) ..
		string.char(bit.band(bit.rshift(i,  8), 0xff)) ..
		string.char(bit.band(bit.rshift(i,  0), 0xff))
end

function freetype.tag(s)
	if type(s) == 'string' then
		return s:byte(1) * 2^24 + s:byte(2) * 2^16 + s:byte(3) * 2^8 + s:byte(4)
	else
		return s
	end
end

--wrappers

function freetype.new()
	local library = ffi.new'FT_Library[1]'
	checkz(C.FT_Init_FreeType(library))
	return library[0]
end
freetype.__call = freetype.new

local lib = {} --FT_Library methods

function lib.version(library)
	local v = ffi.new'FT_Int[3]'
	C.FT_Library_Version(library, v, v+1, v+2)
	return v[0], v[1], v[2]
end

function lib.free(library)
	checkz(C.FT_Done_FreeType(library))
end

function lib.face(library, filename, face_index)
	local face = ffi.new'FT_Face[1]'
	checkz(C.FT_New_Face(library, filename, face_index or 0, face))
	return face[0]
end

function lib.memory_face(library, data, size, face_index)
	local face = ffi.new'FT_Face[1]'
	checkz(C.FT_New_Memory_Face(library, data, size, face_index or 0, face))
	return face[0]
end

--TODO: construct FT_Args
function lib.open_face(library, args, face_index)
	local face = ffi.new'FT_Face[1]'
	checkz(C.FT_Open_Face(library, args, face_index or 0, face))
	return face[0]
end

function lib.ref(lib)
	checkz(C.FT_Reference_Library(lib))
end

local face = {} --FT_Face methods

face.set_transform = C.FT_Set_Transform
face.char_index = C.FT_Get_Char_Index
--face.fstype_flags = C.FT_Get_FSType_Flags --fstype stripped (needs type1)

function face.ref(face)
	checkz(C.FT_Reference_Face(face))
end

function face.attach_file(face, filepathname)
	checkz(C.FT_Attach_File(face, filepathname))
end

--TODO: construct FT_Args
function face.attach_stream(face, parameters)
	checkz(C.FT_Attach_Stream(face, parameters))
end

function face.free(face)
	ffi.gc(face, nil)
	checkz(C.FT_Done_Face(face))
end

function face.select_size(face, strike_index)
	checkz(C.FT_Select_Size(face, strike_index))
end

function face.request_size(face, req)
	req = req or ffi.new'FT_Size_Request'
	checkz(C.FT_Request_Size(face, req))
	return req
end

function face.set_char_size(face, char_width, char_height, horz_resolution, vert_resolution)
	checkz(C.FT_Set_Char_Size(face, char_width, char_height or 0, horz_resolution or 0, vert_resolution or 0))
end

function face.set_pixel_sizes(face, pixel_width, pixel_height)
	checkz(C.FT_Set_Pixel_Sizes(face, pixel_width, pixel_height or 0))
end

function face.load_glyph(face, glyph_index, load_flags) --FT_LOAD_*
	checkz(C.FT_Load_Glyph(face, glyph_index, load_flags or 0))
end

function face.load_char(face, char_code, load_flags) --FT_LOAD_*
	checkz(C.FT_Load_Char(face, char_code, load_flags))
end

function face.kerning(face, left_glyph, right_glyph, kern_mode, kerning) --FT_KERNING_*
	kerning = kerning or ffi.new'FT_Vector'
	checkz(C.FT_Get_Kerning(face, left_glyph, right_glyph, kern_mode, kerning))
	return kerning
end

function face.track_kerning(face, point_size, degree, kerning)
	kerning = kerning or ffi.new'FT_Vector'
	checkz(C.FT_Get_Track_Kerning(face, point_size, degree, kerning))
	return kerning
end

function face.glyph_name(face, glyph_index, buffer, buffer_max)
	buffer = buffer or ffi.new('uint8_t[?]', buffer_max or 64)
	local ret = C.FT_Get_Glyph_Name(face, glyph_index, buffer, buffer_max)
	return ret == 0 and ffi.string(buffer) or nil
end

function face.postscript_name(face)
	local name = C.FT_Get_Postscript_Name(face)
	return name ~= nil and ffi.string(name) or nil
end

function face.select_charmap(face, encoding)
	if type(encoding) == 'string' then
		encoding =
			  (encoding:byte(1) or 32) * 2^24
			+ (encoding:byte(2) or 32) * 2^16
			+ (encoding:byte(3) or 32) * 2^8
			+ (encoding:byte(4) or 32)
	end
	checkz(C.FT_Select_Charmap(face, encoding))
end

function face.set_charmap(face, charmap)
	checkz(C.FT_Set_Charmap(face, charmap))
end

local charmap = {}

function charmap.index(charmap)
	local ret = C.FT_Get_Charmap_Index(charmap)
	assert(ret ~= -1, 'invalid charmap')
	return ret
end

function charmap.encoding_str(charmap)
	return string.reverse(ffi.string(charmap._encoding_str, 4))
end

face.first_char = C.FT_Get_First_Char
face.next_char = C.FT_Get_Next_Char

function face.chars(face) --returns iterator<charcode, glyph_index>
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

function face.char_count(face)
	local gindex = ffi.new'FT_UInt[1]'
	local charcode = C.FT_Get_First_Char(face, gindex)
	local n = 0
	while gindex[0] ~= 0 do
		n = n + 1
		charcode = C.FT_Get_Next_Char(face, charcode, gindex)
	end
	return n
end

function face.name_index(face, glyph_name)
	return nonzero(C.FT_Get_Name_Index(face, glyph_name))
end

function face.char_variant_index(face, charcode, variantSelector)
	return nonzero(C.FT_Face_GetCharVariantIndex(face, charcode, variantSelector))
end

function face.char_variant_is_default(face, charcode, variantSelector)
	local ret = C.FT_Face_GetCharVariantIsDefault(face, charcode, variantSelector)
	if ret == -1 then return nil end
	return ret == 1 --1 if found in the standard (Unicode) cmap, 0 if found in the variation selector cmap
end

function face.variant_selectors(face)
	return ptr(C.FT_Face_GetVariantSelectors(face))
end

function face.variants_of_char(face, charcode)
	return ptr(C.FT_Face_GetVariantsOfChar(face, charcode))
end

function face.chars_of_variant(face, variantSelector)
	return ptr(C.FT_Face_GetCharsOfVariant(face, variantSelector))
end

--ftbitmap.h

function lib.bitmap(library)
	local bitmap = ffi.new'FT_Bitmap'
	C.FT_Bitmap_New(bitmap)
	return bitmap
end

function lib.free_bitmap(library, bitmap)
	checkz(C.FT_Bitmap_Done(library, bitmap))
end

function lib.copy_bitmap(library, source, target)
	checkz(C.FT_Bitmap_Copy(library, source, target))
end

function lib.embolden_bitmap(library, bitmap, xStrength, yStrength)
	checkz(C.FT_Bitmap_Embolden(library, bitmap, xStrength, yStrength))
end

function lib.convert_bitmap(library, source, target, alignment)
	checkz(C.FT_Bitmap_Convert(library, source, target, alignment))
end

local slot = {} --FT_GlyphSlot methods

function slot.render(slot, render_mode) --FT_RENDER_*
	checkz(C.FT_Render_Glyph(slot, render_mode or 0))
end

function slot.subglyph_info(glyph, sub_index, p_index, p_flags, p_arg1, p_arg2, p_transform)
	p_index = p_index or ffi.new'FT_Int[1]'
	p_flags = p_flags or ffi.new'FT_UInt[1]'
	p_arg1  = p_arg1  or ffi.new'FT_Int[1]'
	p_arg2  = p_arg2  or ffi.new'FT_Int[1]'
	p_transform = p_transform or ffi.new'FT_Matrix'
	checkz(C.FT_Get_SubGlyph_Info(glyph, sub_index, p_index, p_flags, p_arg1, p_arg2, p_transform))
	return
		p_index[0], p_flags[0], p_arg1[0], p_arg2[0], p_transform
end

function slot.own_bitmap(slot)
	checkz(C.FT_GlyphSlot_Own_Bitmap(slot))
end

--ftglyph.h

function slot.glyph(slot, glyph)
	glyph = glyph or ffi.new'FT_Glyph[1]'
	checkz(C.FT_Get_Glyph(slot, glyph))
	return glyph[0]
end

local glyph = {}

function glyph.copy(source, target)
	target = target or ffi.new'FT_Glyph[1]'
	checkz(C.FT_Glyph_Copy(source, target))
	return target[0]
end

function glyph.transform(glyph, matrix, delta)
	checkz(C.FT_Glyph_Transform(glyph, matrix, delta))
	return glyph
end

function glyph.to_bitmap(glyph, render_mode, origin, destroy)
	if destroy == nil then destroy = true end
	local pglyph = ffi.new('FT_Glyph[1]', glyph)
	checkz(C.FT_Glyph_To_Bitmap(pglyph, render_mode or 0, origin, destroy))
	return pglyph[0]
end

glyph.cbox = C.FT_Glyph_Get_CBox
glyph.free = C.FT_Done_Glyph

function glyph.as_bitmap(glyph)
	assert(glyph.format == C.FT_GLYPH_FORMAT_BITMAP)
	return ffi.cast('FT_BitmapGlyph', glyph)
end

function glyph.as_outline(glyph)
	assert(glyph.format == C.FT_GLYPH_FORMAT_OUTLINE)
	return ffi.cast('FT_OutlineGlyph', glyph)
end

--ftoutln.h

function lib.outline(library, numPoints, numContours)
	numPoints = numPoints or 0xFFFF
	numContours = math.min(math.max(numContours or numPoints, 0), 0xFFFF)
	local outline = ffi.new'FT_Outline[1]'
	checkz(C.FT_Outline_New(library, numPoints, numContours, outline))
	return outline[0]
end

local outline = {} --FT_Outline methods

outline.translate = C.FT_Outline_Translate
outline.transform = C.FT_Outline_Transform
outline.orientation = C.FT_Outline_Get_Orientation

function lib.free_outline(library, outline)
	checkz(C.FT_Outline_Done(library, outline))
end

function outline.decompose(outline, func_interface, userdata)
	checkz(C.FT_Outline_Decompose(outline, func_interface, userdata))
end

function outline.check(outline)
	checkz(C.FT_Outline_Check(outline))
end

function outline.cbox(outline, cbox)
	cbox = cbox or ffi.new'FT_BBox'
	checkz(C.FT_Outline_Get_CBox(outline, cbox))
	return cbox
end

function outline.copy(source, target)
	checkz(C.FT_Outline_Copy(source, target))
	return target
end

function outline.embolden(outline, xstrength, ystrength)
	if ystrength then
		checkz(C.FT_Outline_EmboldenXY(outline, xstrength, ystrength))
	else
		checkz(C.FT_Outline_Embolden(outline, xstrength))
	end
end

function outline.reverse(outline)
	checkz(C.FT_Outline_Reverse(outline))
end

function lib.get_outline_bitmap(library, outline, bitmap)
	checkz(C.FT_Outline_Get_Bitmap(library, outline, bitmap))
	return bitmap
end

function lib.render_outline(library, outline, params)
	checkz(C.FT_Outline_Render(library, outline, params))
end

--matrix methods not included in freetype

local matrix = {}

function matrix:reset(...)
	self.xx, self.yx, self.xy, self.yy = 64, 0, 0, 64
	return self
end

function matrix:rotate(a)
	local s = math.sin(a) * 64
	local c = math.cos(a) * 64
	self.xx, self.yx, self.xy, self.yy =
		 c * self.xx + s * self.xy,
		 c * self.yx + s * self.yy,
		-s * self.xx + c * self.xy,
		-s * self.yx + c * self.yy
	return self
end

--methods

ffi.metatype('struct FT_LibraryRec_', {__index = lib})
ffi.metatype('struct FT_FaceRec_', {__index = face})
ffi.metatype('struct FT_GlyphSlotRec_', {__index = slot})
ffi.metatype('struct FT_GlyphRec_', {__index = glyph})
ffi.metatype('struct FT_CharMapRec_', {__index = charmap})
ffi.metatype('struct FT_Outline_', {__index = outline})
ffi.metatype('struct FT_Matrix_', {__index = matrix})

return freetype
