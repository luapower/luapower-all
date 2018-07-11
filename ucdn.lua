
-- harfbuzz-ucdn ffi binding
-- Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local C = ffi.load'ucdn'

ffi.cdef[[
const char *ucdn_get_unicode_version(void);
int      ucdn_get_combining_class(uint32_t code);
int      ucdn_get_east_asian_width(uint32_t code);
int      ucdn_get_general_category(uint32_t code);
int      ucdn_get_bidi_class(uint32_t code);
int      ucdn_get_script(uint32_t code);
int      ucdn_get_linebreak_class(uint32_t code);
int      ucdn_get_resolved_linebreak_class(uint32_t code);
int      ucdn_get_mirrored(uint32_t code);
uint32_t ucdn_mirror(uint32_t code);
uint32_t ucdn_paired_bracket(uint32_t code);
int      ucdn_paired_bracket_type(uint32_t code);
int      ucdn_decompose(uint32_t code, uint32_t *a, uint32_t *b);
int      ucdn_compat_decompose(uint32_t code, uint32_t *decomposed);
int      ucdn_compose(uint32_t *code, uint32_t a, uint32_t b);
]]

local ucdn = {C = C}

function ucdn.unicode_version()
	return ffi.string(C.ucdn_get_unicode_version())
end

ucdn.combining_class = C.ucdn_get_combining_class

local widths = {[0] = 'F', 'H', 'W', 'Na', 'A', 'N'}
function ucdn.east_asian_width(c)
	return widths[C.ucdn_get_east_asian_width(c)]
end

local cat = {[0] = 'Cc', 'Cf', 'Cn', 'Co', 'Cs', 'Ll', 'Lm', 'Lo', 'Lt', 'Lu',
	'Mc', 'Me', 'Mn', 'Nd', 'Nl', 'No', 'Pc', 'Pd', 'Pe', 'Pf', 'Pi', 'Po',
	'Ps', 'Sc', 'Sk', 'Sm', 'So', 'Zl', 'Zp', 'Zs',
}
function ucdn.general_category(c)
	return cat[C.ucdn_get_general_category(c)]
end

local bidi = {[0] = 'L', 'LRE', 'LRO', 'R', 'AL', 'RLE', 'RLO', 'PDF', 'EN',
	'ES', 'ET', 'AN', 'CS', 'NSM', 'BN', 'B', 'S', 'WS', 'ON', 'LRI', 'RLI',
	'FSI', 'PDI',
}
function ucdn.bidi_class(c)
	return bidi[C.ucdn_get_bidi_class(c)]
end

local scripts = {[0] = 'common', 'latin', 'greek', 'cyrillic', 'armenian',
	'hebrew', 'arabic', 'syriac', 'thaana', 'devanagari', 'bengali',
	'gurmukhi', 'gujarati', 'oriya', 'tamil', 'telugu', 'kannada', 'malayalam',
	'sinhala', 'thai', 'lao', 'tibetan', 'myanmar', 'georgian', 'hangul',
	'ethiopic', 'cherokee', 'canadian_aboriginal', 'ogham', 'runic', 'khmer',
	'mongolian', 'hiragana', 'katakana', 'bopomofo', 'han', 'yi', 'old_italic',
	'gothic', 'deseret', 'inherited', 'tagalog', 'hanunoo', 'buhid',
	'tagbanwa', 'limbu', 'tai_le', 'linear_b', 'ugaritic', 'shavian',
	'osmanya', 'cypriot', 'braille', 'buginese', 'coptic', 'new_tai_lue',
	'glagolitic', 'tifinagh', 'syloti_nagri', 'old_persian', 'kharoshthi',
	'balinese', 'cuneiform', 'phoenician', 'phags_pa', 'nko', 'sundanese',
	'lepcha', 'ol_chiki', 'vai', 'saurashtra', 'kayah_li', 'rejang', 'lycian',
	'carian', 'lydian', 'cham', 'tai_tham', 'tai_viet', 'avestan',
	'egyptian_hieroglyphs', 'samaritan', 'lisu', 'bamum', 'javanese',
	'meetei_mayek', 'imperial_aramaic', 'old_south_arabian',
	'inscriptional_parthian', 'inscriptional_pahlavi', 'old_turkic', 'kaithi',
	'batak', 'brahmi', 'mandaic', 'chakma', 'meroitic_cursive',
	'meroitic_hieroglyphs', 'miao', 'sharada', 'sora_sompeng', 'takri',
	'unknown', 'bassa_vah', 'caucasian_albanian', 'duployan', 'elbasan',
	'grantha', 'khojki', 'khudawadi', 'linear_a', 'mahajani', 'manichaean',
	'mende_kikakui', 'modi', 'mro', 'nabataean', 'old_north_arabian',
	'old_permic', 'pahawh_hmong', 'palmyrene', 'pau_cin_hau',
	'psalter_pahlavi', 'siddham', 'tirhuta', 'warang_citi', 'ahom',
	'anatolian_hieroglyphs', 'hatran', 'multani', 'old_hungarian',
	'signwriting', 'adlam', 'bhaiksuki', 'marchen', 'newa', 'osage', 'tangut',
	'masaram_gondi', 'nushu', 'soyombo', 'zanabazar_square',
}
function ucdn.script(c)
	return scripts[C.ucdn_get_script(c)]
end

local lb = {[0] = 'OP', 'CL', 'CP', 'QU', 'GL', 'NS', 'EX', 'SY', 'IS', 'PR',
	'PO', 'NU', 'AL', 'HL', 'ID', 'IN', 'HY', 'BA', 'BB', 'B2', 'ZW', 'CM',
	'WJ', 'H2', 'H3', 'JL', 'JV', 'JT', 'RI', 'AI', 'BK', 'CB', 'CJ', 'CR',
	'LF', 'NL', 'SA', 'SG', 'SP', 'XX', 'ZWJ', 'EB', 'EM',
}
function ucdn.linebreak_class(c)
	return lb[C.ucdn_get_linebreak_class(c)]
end

function ucdn.resolved_linebreak_class(c)
	return lb[C.ucdn_get_resolved_linebreak_class(c)]
end

function ucdn.mirrored(c)
	return C.ucdn_get_mirrored(c) == 1
end

ucdn.mirror = C.ucdn_mirror

ucdn.paired_bracket = C.ucdn_paired_bracket

local pb = {[0] = 'open', 'close', 'none'}
function ucdn.paired_bracket_type(c)
	return pb[C.ucdn_paired_bracket_type(c)]
end

local c1 = ffi.new'uint32_t[1]'
local c2 = ffi.new'uint32_t[1]'
function ucdn.decompose(code)
	local ok = C.ucdn_decompose(code, c1, c2) == 1
	return ok, c1[0], c2[0]
end

local c0 = ffi.new'uint32_t[18]'
function ucdn.compat_decompose(code, c)
	local c = c or c0
	local len = C.ucdn_compat_decompose(code, c)
	return c, len
end

function ucdn.compose(a, b)
	local ok = C.ucdn_compose(c1, a, b) == 1
	return ok, c1[0]
end

--tests ----------------------------------------------------------------------

if not ... then

	print('unicode version', ucdn.unicode_version())

	assert(ucdn.combining_class(0x0E48) == 107)
	assert(ucdn.east_asian_width(0x4E00) == 'W')
	assert(ucdn.general_category(('A'):byte(1)) == 'Lu')
	assert(ucdn.general_category(('a'):byte(1)) == 'Ll')
	assert(ucdn.bidi_class(0x202B) == 'RLE')
	assert(ucdn.bidi_class(0x202C) == 'PDF')
	assert(ucdn.script(0x32D0) == 'katakana')
	assert(ucdn.linebreak_class(10) == 'LF')
	assert(ucdn.linebreak_class(('A'):byte(1)) == 'AL')
	assert(ucdn.resolved_linebreak_class(('A'):byte(1)) == 'AL')
	assert(ucdn.mirrored(0x0028) == true) --()
	assert(ucdn.mirror(0x0028) == 0x0029) -- ()
	assert(ucdn.paired_bracket(0x0028) == 0x0029) --()
	assert(ucdn.paired_bracket_type(0x0028) == 'open')
	assert(ucdn.paired_bracket_type(0x0029) == 'close')
	local ok,a,b = ucdn.decompose(0x00f1) --fi
	assert(ok and a == 0x006e and b == 0x0303)
	local p, len = ucdn.compat_decompose(0x00f1)
	assert(len == 2 and p[0] == 0x006e and p[1] == 0x0303)
	local ok, c = ucdn.compose(0x006e, 0x0303)
	assert(ok and c == 0x00f1)

end

return ucdn
