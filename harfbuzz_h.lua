
--hb.h from harfbuzz 1.8.2

local ffi = require'ffi'
ffi.cdef[[

//TODO expand these:
//#define HB_DIRECTION_IS_VALID(dir) ((((unsigned int) (dir)) & ~3U) == 4)
//#define HB_DIRECTION_IS_HORIZONTAL(dir) ((((unsigned int) (dir)) & ~1U) == 4)
//#define HB_DIRECTION_IS_VERTICAL(dir) ((((unsigned int) (dir)) & ~1U) == 6)
//#define HB_DIRECTION_IS_FORWARD(dir) ((((unsigned int) (dir)) & ~2U) == 4)
//#define HB_DIRECTION_IS_BACKWARD(dir) ((((unsigned int) (dir)) & ~2U) == 5)
//#define HB_DIRECTION_REVERSE(dir) ((hb_direction_t) (((unsigned int) (dir)) ^ 1))

// hb-common.h ---------------------------------------------------------------

typedef int      hb_bool_t;
typedef uint32_t hb_codepoint_t;
typedef int32_t  hb_position_t;
typedef uint32_t hb_mask_t;

typedef union _hb_var_int_t {
	uint32_t u32;
	int32_t i32;
	uint16_t u16[2];
	int16_t i16[2];
	uint8_t u8[4];
	int8_t i8[4];
} hb_var_int_t;

typedef uint32_t hb_tag_t;

hb_tag_t hb_tag_from_string (const char *str, int len);
void     hb_tag_to_string   (hb_tag_t tag, char *buf);

typedef enum {
	HB_DIRECTION_INVALID = 0,
	HB_DIRECTION_LTR = 4,
	HB_DIRECTION_RTL,
	HB_DIRECTION_TTB,
	HB_DIRECTION_BTT
} hb_direction_t;

hb_direction_t hb_direction_from_string (const char *str, int len);
const char*    hb_direction_to_string (hb_direction_t direction);

typedef const struct hb_language_impl_t *hb_language_t;

hb_language_t hb_language_from_string (const char *str, int len);
const char *hb_language_to_string (hb_language_t language);

enum {
	HB_LANGUAGE_INVALID = 0,
};

hb_language_t hb_language_get_default (void);

typedef enum {
	HB_SCRIPT_COMMON = ((hb_tag_t)((((uint8_t)('Z'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('y'))<<8)|((uint8_t)('y')))),
	HB_SCRIPT_INHERITED = ((hb_tag_t)((((uint8_t)('Z'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('h')))),
	HB_SCRIPT_UNKNOWN = ((hb_tag_t)((((uint8_t)('Z'))<<24)|(((uint8_t)('z'))<<16)|(((uint8_t)('z'))<<8)|((uint8_t)('z')))),
	HB_SCRIPT_ARABIC = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_ARMENIAN = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('n')))),
	HB_SCRIPT_BENGALI = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_CYRILLIC = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('l')))),
	HB_SCRIPT_DEVANAGARI = ((hb_tag_t)((((uint8_t)('D'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('v'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_GEORGIAN = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('o'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_GREEK = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('e'))<<8)|((uint8_t)('k')))),
	HB_SCRIPT_GUJARATI = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('j'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_GURMUKHI = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('u')))),
	HB_SCRIPT_HANGUL = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_HAN = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_HEBREW = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('b'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_HIRAGANA = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_KANNADA = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('n'))<<16)|(((uint8_t)('d'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_KATAKANA = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_LAO = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('o'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_LATIN = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('t'))<<8)|((uint8_t)('n')))),
	HB_SCRIPT_MALAYALAM = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('l'))<<16)|(((uint8_t)('y'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_ORIYA = ((hb_tag_t)((((uint8_t)('O'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('y'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_TAMIL = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('l')))),
	HB_SCRIPT_TELUGU = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('u')))),
	HB_SCRIPT_THAI = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_TIBETAN = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('b'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_BOPOMOFO = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('p'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_BRAILLE = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_CANADIAN_SYLLABICS = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('s')))),
	HB_SCRIPT_CHEROKEE = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('e'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_ETHIOPIC = ((hb_tag_t)((((uint8_t)('E'))<<24)|(((uint8_t)('t'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_KHMER = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_MONGOLIAN = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_MYANMAR = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_OGHAM = ((hb_tag_t)((((uint8_t)('O'))<<24)|(((uint8_t)('g'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_RUNIC = ((hb_tag_t)((((uint8_t)('R'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_SINHALA = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('h')))),
	HB_SCRIPT_SYRIAC = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('c')))),
	HB_SCRIPT_THAANA = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_YI = ((hb_tag_t)((((uint8_t)('Y'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('i'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_DESERET = ((hb_tag_t)((((uint8_t)('D'))<<24)|(((uint8_t)('s'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_GOTHIC = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('t'))<<8)|((uint8_t)('h')))),
	HB_SCRIPT_OLD_ITALIC = ((hb_tag_t)((((uint8_t)('I'))<<24)|(((uint8_t)('t'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('l')))),
	HB_SCRIPT_BUHID = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_HANUNOO = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_TAGALOG = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('g'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_TAGBANWA = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('g'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_CYPRIOT = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('p'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_LIMBU = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_LINEAR_B = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_OSMANYA = ((hb_tag_t)((((uint8_t)('O'))<<24)|(((uint8_t)('s'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_SHAVIAN = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('w')))),
	HB_SCRIPT_TAI_LE = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('e')))),
	HB_SCRIPT_UGARITIC = ((hb_tag_t)((((uint8_t)('U'))<<24)|(((uint8_t)('g'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_BUGINESE = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('g'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_COPTIC = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('p'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_GLAGOLITIC = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('l'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_KHAROSHTHI = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_NEW_TAI_LUE = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('u')))),
	HB_SCRIPT_OLD_PERSIAN = ((hb_tag_t)((((uint8_t)('X'))<<24)|(((uint8_t)('p'))<<16)|(((uint8_t)('e'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_SYLOTI_NAGRI = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_TIFINAGH = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('f'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_BALINESE = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_CUNEIFORM = ((hb_tag_t)((((uint8_t)('X'))<<24)|(((uint8_t)('s'))<<16)|(((uint8_t)('u'))<<8)|((uint8_t)('x')))),
	HB_SCRIPT_NKO = ((hb_tag_t)((((uint8_t)('N'))<<24)|(((uint8_t)('k'))<<16)|(((uint8_t)('o'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_PHAGS_PA = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_PHOENICIAN = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('x')))),
	HB_SCRIPT_CARIAN = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_CHAM = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_KAYAH_LI = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_LEPCHA = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('p'))<<8)|((uint8_t)('c')))),
	HB_SCRIPT_LYCIAN = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('c'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_LYDIAN = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('y'))<<16)|(((uint8_t)('d'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_OL_CHIKI = ((hb_tag_t)((((uint8_t)('O'))<<24)|(((uint8_t)('l'))<<16)|(((uint8_t)('c'))<<8)|((uint8_t)('k')))),
	HB_SCRIPT_REJANG = ((hb_tag_t)((((uint8_t)('R'))<<24)|(((uint8_t)('j'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_SAURASHTRA = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('u'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_SUNDANESE = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_VAI = ((hb_tag_t)((((uint8_t)('V'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('i'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_AVESTAN = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('v'))<<16)|(((uint8_t)('s'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_BAMUM = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('u')))),
	HB_SCRIPT_EGYPTIAN_HIEROGLYPHS = ((hb_tag_t)((((uint8_t)('E'))<<24)|(((uint8_t)('g'))<<16)|(((uint8_t)('y'))<<8)|((uint8_t)('p')))),
	HB_SCRIPT_IMPERIAL_ARAMAIC = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_INSCRIPTIONAL_PAHLAVI = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_INSCRIPTIONAL_PARTHIAN = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('t'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_JAVANESE = ((hb_tag_t)((((uint8_t)('J'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('v'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_KAITHI = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('t'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_LISU = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('s'))<<8)|((uint8_t)('u')))),
	HB_SCRIPT_MEETEI_MAYEK = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('t'))<<16)|(((uint8_t)('e'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_OLD_SOUTH_ARABIAN = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_OLD_TURKIC = ((hb_tag_t)((((uint8_t)('O'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('k'))<<8)|((uint8_t)('h')))),
	HB_SCRIPT_SAMARITAN = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('m'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_TAI_THAM = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_TAI_VIET = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('v'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_BATAK = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('t'))<<8)|((uint8_t)('k')))),
	HB_SCRIPT_BRAHMI = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('h')))),
	HB_SCRIPT_MANDAIC = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_CHAKMA = ((hb_tag_t)((((uint8_t)('C'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('k'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_MEROITIC_CURSIVE = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('c')))),
	HB_SCRIPT_MEROITIC_HIEROGLYPHS = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_MIAO = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('l'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_SHARADA = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_SORA_SOMPENG = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_TAKRI = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('k'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_BASSA_VAH = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('s'))<<8)|((uint8_t)('s')))),
	HB_SCRIPT_CAUCASIAN_ALBANIAN = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('g'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_DUPLOYAN = ((hb_tag_t)((((uint8_t)('D'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('p'))<<8)|((uint8_t)('l')))),
	HB_SCRIPT_ELBASAN = ((hb_tag_t)((((uint8_t)('E'))<<24)|(((uint8_t)('l'))<<16)|(((uint8_t)('b'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_GRANTHA = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('n')))),
	HB_SCRIPT_KHOJKI = ((hb_tag_t)((((uint8_t)('K'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('o'))<<8)|((uint8_t)('j')))),
	HB_SCRIPT_KHUDAWADI = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_LINEAR_A = ((hb_tag_t)((((uint8_t)('L'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_MAHAJANI = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('j')))),
	HB_SCRIPT_MANICHAEAN = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_MENDE_KIKAKUI = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_MODI = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('d'))<<8)|((uint8_t)('i')))),
	HB_SCRIPT_MRO = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('r'))<<16)|(((uint8_t)('o'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_NABATAEAN = ((hb_tag_t)((((uint8_t)('N'))<<24)|(((uint8_t)('b'))<<16)|(((uint8_t)('a'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_OLD_NORTH_ARABIAN = ((hb_tag_t)((((uint8_t)('N'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_OLD_PERMIC = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_PAHAWH_HMONG = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('m'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_PALMYRENE = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_PAU_CIN_HAU = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('u'))<<8)|((uint8_t)('c')))),
	HB_SCRIPT_PSALTER_PAHLAVI = ((hb_tag_t)((((uint8_t)('P'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('p')))),
	HB_SCRIPT_SIDDHAM = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('d'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_TIRHUTA = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('i'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('h')))),
	HB_SCRIPT_WARANG_CITI = ((hb_tag_t)((((uint8_t)('W'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_AHOM = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('o'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_ANATOLIAN_HIEROGLYPHS = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('l'))<<16)|(((uint8_t)('u'))<<8)|((uint8_t)('w')))),
	HB_SCRIPT_HATRAN = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('t'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_MULTANI = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('t')))),
	HB_SCRIPT_OLD_HUNGARIAN = ((hb_tag_t)((((uint8_t)('H'))<<24)|(((uint8_t)('u'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_SIGNWRITING = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('g'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('w')))),
	HB_SCRIPT_ADLAM = ((hb_tag_t)((((uint8_t)('A'))<<24)|(((uint8_t)('d'))<<16)|(((uint8_t)('l'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_BHAIKSUKI = ((hb_tag_t)((((uint8_t)('B'))<<24)|(((uint8_t)('h'))<<16)|(((uint8_t)('k'))<<8)|((uint8_t)('s')))),
	HB_SCRIPT_MARCHEN = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('r'))<<8)|((uint8_t)('c')))),
	HB_SCRIPT_OSAGE = ((hb_tag_t)((((uint8_t)('O'))<<24)|(((uint8_t)('s'))<<16)|(((uint8_t)('g'))<<8)|((uint8_t)('e')))),
	HB_SCRIPT_TANGUT = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_NEWA = ((hb_tag_t)((((uint8_t)('N'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('w'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_MASARAM_GONDI = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('m')))),
	HB_SCRIPT_NUSHU = ((hb_tag_t)((((uint8_t)('N'))<<24)|(((uint8_t)('s'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('u')))),
	HB_SCRIPT_SOYOMBO = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('y'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_ZANABAZAR_SQUARE = ((hb_tag_t)((((uint8_t)('Z'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('b')))),
	HB_SCRIPT_DOGRA = ((hb_tag_t)((((uint8_t)('D'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('g'))<<8)|((uint8_t)('r')))),
	HB_SCRIPT_GUNJALA_GONDI = ((hb_tag_t)((((uint8_t)('G'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('n'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_HANIFI_ROHINGYA = ((hb_tag_t)((((uint8_t)('R'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('h'))<<8)|((uint8_t)('g')))),
	HB_SCRIPT_MAKASAR = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('a'))<<16)|(((uint8_t)('k'))<<8)|((uint8_t)('a')))),
	HB_SCRIPT_MEDEFAIDRIN = ((hb_tag_t)((((uint8_t)('M'))<<24)|(((uint8_t)('e'))<<16)|(((uint8_t)('d'))<<8)|((uint8_t)('f')))),
	HB_SCRIPT_OLD_SOGDIAN = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('g'))<<8)|((uint8_t)('o')))),
	HB_SCRIPT_SOGDIAN = ((hb_tag_t)((((uint8_t)('S'))<<24)|(((uint8_t)('o'))<<16)|(((uint8_t)('g'))<<8)|((uint8_t)('d')))),
	HB_SCRIPT_INVALID = 0,
} hb_script_t;

hb_script_t    hb_script_from_iso15924_tag        (hb_tag_t tag);
hb_script_t    hb_script_from_string              (const char *str, int len);
hb_tag_t       hb_script_to_iso15924_tag          (hb_script_t script);
hb_direction_t hb_script_get_horizontal_direction (hb_script_t script);

typedef struct hb_user_data_key_t {
	char unused;
} hb_user_data_key_t;

typedef void (*hb_destroy_func_t) (void *user_data);

typedef struct hb_feature_t {
	hb_tag_t tag;
	uint32_t value;
	unsigned int start;
	unsigned int end;
} hb_feature_t;

hb_bool_t hb_feature_from_string (const char *str, int len, hb_feature_t *feature);
void      hb_feature_to_string   (hb_feature_t *feature, char *buf, unsigned int size);

typedef struct hb_variation_t {
  hb_tag_t tag;
  float value;
} hb_variation_t;

hb_bool_t hb_variation_from_string (const char *str, int len, hb_variation_t *variation);
void      hb_variation_to_string   (hb_variation_t *variation, char *buf, unsigned int size);

// hb-set.h ------------------------------------------------------------------

enum {
	HB_SET_VALUE_INVALID = ((hb_codepoint_t) -1),
};
typedef struct hb_set_t hb_set_t;

hb_set_t * hb_set_create (void);
hb_set_t * hb_set_get_empty (void);
hb_set_t * hb_set_reference (hb_set_t *set);
void       hb_set_destroy (hb_set_t *set);
hb_bool_t  hb_set_set_user_data (
	hb_set_t *set,
	hb_user_data_key_t *key,
	void * data,
	hb_destroy_func_t destroy,
	hb_bool_t replace
);
void *         hb_set_get_user_data  (hb_set_t *set, hb_user_data_key_t *key);
hb_bool_t      hb_set_allocation_successful (const hb_set_t *set);
void           hb_set_clear          (hb_set_t *set);
hb_bool_t      hb_set_is_empty       (const hb_set_t *set);
hb_bool_t      hb_set_has            (const hb_set_t *set, hb_codepoint_t codepoint);
void           hb_set_add            (hb_set_t *set, hb_codepoint_t codepoint);
void           hb_set_add_range      (hb_set_t *set, hb_codepoint_t first, hb_codepoint_t last);
void           hb_set_del            (hb_set_t *set, hb_codepoint_t codepoint);
void           hb_set_del_range      (hb_set_t *set, hb_codepoint_t first, hb_codepoint_t last);
hb_bool_t      hb_set_is_equal       (const hb_set_t *set, const hb_set_t *other);
hb_bool_t      hb_set_is_subset      (const hb_set_t *set, const hb_set_t *larger_set);
void           hb_set_set            (hb_set_t *set, const hb_set_t *other);
void           hb_set_union          (hb_set_t *set, const hb_set_t *other);
void           hb_set_intersect      (hb_set_t *set, const hb_set_t *other);
void           hb_set_subtract       (hb_set_t *set, const hb_set_t *other);
void           hb_set_symmetric_difference (hb_set_t *set, const hb_set_t *other);
unsigned int   hb_set_get_population (const hb_set_t *set);
hb_codepoint_t hb_set_get_min        (const hb_set_t *set);
hb_codepoint_t hb_set_get_max        (const hb_set_t *set);
hb_bool_t      hb_set_next           (const hb_set_t *set, hb_codepoint_t *codepoint);
hb_bool_t      hb_set_previous       (const hb_set_t *set, hb_codepoint_t *codepoint);
hb_bool_t      hb_set_next_range     (const hb_set_t *set, hb_codepoint_t *first, hb_codepoint_t *last);
hb_bool_t      hb_set_previous_range (const hb_set_t *set, hb_codepoint_t *first, hb_codepoint_t *last);

// hb-map.h ------------------------------------------------------------------

enum {
	HB_MAP_VALUE_INVALID = ((hb_codepoint_t) -1),
};
typedef struct hb_map_t hb_map_t;

hb_map_t*  hb_map_create (void);
hb_map_t*  hb_map_get_empty (void);
hb_map_t*  hb_map_reference (hb_map_t *map);
void       hb_map_destroy (hb_map_t *map);
hb_bool_t  hb_map_set_user_data (
	hb_map_t *map,
	hb_user_data_key_t *key,
	void * data,
	hb_destroy_func_t destroy,
	hb_bool_t replace
);
void*          hb_map_get_user_data  (hb_map_t *map, hb_user_data_key_t *key);
hb_bool_t      hb_map_allocation_successful (const hb_map_t *map);
void           hb_map_clear          (hb_map_t *map);
hb_bool_t      hb_map_is_empty       (const hb_map_t *map);
unsigned int   hb_map_get_population (const hb_map_t *map);
void           hb_map_set            (hb_map_t *map, hb_codepoint_t key, hb_codepoint_t value);
hb_codepoint_t hb_map_get            (const hb_map_t *map, hb_codepoint_t key);
void           hb_map_del            (hb_map_t *map, hb_codepoint_t key);
hb_bool_t      hb_map_has            (const hb_map_t *map, hb_codepoint_t key);

// hb-unicode.h --------------------------------------------------------------

typedef enum {
	HB_UNICODE_GENERAL_CATEGORY_CONTROL,
	HB_UNICODE_GENERAL_CATEGORY_FORMAT,
	HB_UNICODE_GENERAL_CATEGORY_UNASSIGNED,
	HB_UNICODE_GENERAL_CATEGORY_PRIVATE_USE,
	HB_UNICODE_GENERAL_CATEGORY_SURROGATE,
	HB_UNICODE_GENERAL_CATEGORY_LOWERCASE_LETTER,
	HB_UNICODE_GENERAL_CATEGORY_MODIFIER_LETTER,
	HB_UNICODE_GENERAL_CATEGORY_OTHER_LETTER,
	HB_UNICODE_GENERAL_CATEGORY_TITLECASE_LETTER,
	HB_UNICODE_GENERAL_CATEGORY_UPPERCASE_LETTER,
	HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK,
	HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK,
	HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK,
	HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER,
	HB_UNICODE_GENERAL_CATEGORY_LETTER_NUMBER,
	HB_UNICODE_GENERAL_CATEGORY_OTHER_NUMBER,
	HB_UNICODE_GENERAL_CATEGORY_CONNECT_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_DASH_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_CLOSE_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_FINAL_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_INITIAL_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_OTHER_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_OPEN_PUNCTUATION,
	HB_UNICODE_GENERAL_CATEGORY_CURRENCY_SYMBOL,
	HB_UNICODE_GENERAL_CATEGORY_MODIFIER_SYMBOL,
	HB_UNICODE_GENERAL_CATEGORY_MATH_SYMBOL,
	HB_UNICODE_GENERAL_CATEGORY_OTHER_SYMBOL,
	HB_UNICODE_GENERAL_CATEGORY_LINE_SEPARATOR,
	HB_UNICODE_GENERAL_CATEGORY_PARAGRAPH_SEPARATOR,
	HB_UNICODE_GENERAL_CATEGORY_SPACE_SEPARATOR
} hb_unicode_general_category_t;

typedef enum {
	HB_UNICODE_COMBINING_CLASS_NOT_REORDERED = 0,
	HB_UNICODE_COMBINING_CLASS_OVERLAY = 1,
	HB_UNICODE_COMBINING_CLASS_NUKTA = 7,
	HB_UNICODE_COMBINING_CLASS_KANA_VOICING = 8,
	HB_UNICODE_COMBINING_CLASS_VIRAMA = 9,
	HB_UNICODE_COMBINING_CLASS_CCC10 = 10,
	HB_UNICODE_COMBINING_CLASS_CCC11 = 11,
	HB_UNICODE_COMBINING_CLASS_CCC12 = 12,
	HB_UNICODE_COMBINING_CLASS_CCC13 = 13,
	HB_UNICODE_COMBINING_CLASS_CCC14 = 14,
	HB_UNICODE_COMBINING_CLASS_CCC15 = 15,
	HB_UNICODE_COMBINING_CLASS_CCC16 = 16,
	HB_UNICODE_COMBINING_CLASS_CCC17 = 17,
	HB_UNICODE_COMBINING_CLASS_CCC18 = 18,
	HB_UNICODE_COMBINING_CLASS_CCC19 = 19,
	HB_UNICODE_COMBINING_CLASS_CCC20 = 20,
	HB_UNICODE_COMBINING_CLASS_CCC21 = 21,
	HB_UNICODE_COMBINING_CLASS_CCC22 = 22,
	HB_UNICODE_COMBINING_CLASS_CCC23 = 23,
	HB_UNICODE_COMBINING_CLASS_CCC24 = 24,
	HB_UNICODE_COMBINING_CLASS_CCC25 = 25,
	HB_UNICODE_COMBINING_CLASS_CCC26 = 26,
	HB_UNICODE_COMBINING_CLASS_CCC27 = 27,
	HB_UNICODE_COMBINING_CLASS_CCC28 = 28,
	HB_UNICODE_COMBINING_CLASS_CCC29 = 29,
	HB_UNICODE_COMBINING_CLASS_CCC30 = 30,
	HB_UNICODE_COMBINING_CLASS_CCC31 = 31,
	HB_UNICODE_COMBINING_CLASS_CCC32 = 32,
	HB_UNICODE_COMBINING_CLASS_CCC33 = 33,
	HB_UNICODE_COMBINING_CLASS_CCC34 = 34,
	HB_UNICODE_COMBINING_CLASS_CCC35 = 35,
	HB_UNICODE_COMBINING_CLASS_CCC36 = 36,
	HB_UNICODE_COMBINING_CLASS_CCC84 = 84,
	HB_UNICODE_COMBINING_CLASS_CCC91 = 91,
	HB_UNICODE_COMBINING_CLASS_CCC103 = 103,
	HB_UNICODE_COMBINING_CLASS_CCC107 = 107,
	HB_UNICODE_COMBINING_CLASS_CCC118 = 118,
	HB_UNICODE_COMBINING_CLASS_CCC122 = 122,
	HB_UNICODE_COMBINING_CLASS_CCC129 = 129,
	HB_UNICODE_COMBINING_CLASS_CCC130 = 130,
	HB_UNICODE_COMBINING_CLASS_CCC133 = 132,
	HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW_LEFT = 200,
	HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW = 202,
	HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE = 214,
	HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE_RIGHT = 216,
	HB_UNICODE_COMBINING_CLASS_BELOW_LEFT = 218,
	HB_UNICODE_COMBINING_CLASS_BELOW = 220,
	HB_UNICODE_COMBINING_CLASS_BELOW_RIGHT = 222,
	HB_UNICODE_COMBINING_CLASS_LEFT = 224,
	HB_UNICODE_COMBINING_CLASS_RIGHT = 226,
	HB_UNICODE_COMBINING_CLASS_ABOVE_LEFT = 228,
	HB_UNICODE_COMBINING_CLASS_ABOVE = 230,
	HB_UNICODE_COMBINING_CLASS_ABOVE_RIGHT = 232,
	HB_UNICODE_COMBINING_CLASS_DOUBLE_BELOW = 233,
	HB_UNICODE_COMBINING_CLASS_DOUBLE_ABOVE = 234,
	HB_UNICODE_COMBINING_CLASS_IOTA_SUBSCRIPT = 240,
	HB_UNICODE_COMBINING_CLASS_INVALID = 255
} hb_unicode_combining_class_t;

typedef struct hb_unicode_funcs_t hb_unicode_funcs_t;

hb_unicode_funcs_t* hb_unicode_funcs_get_default (void);
hb_unicode_funcs_t* hb_unicode_funcs_create      (hb_unicode_funcs_t *parent);
hb_unicode_funcs_t* hb_unicode_funcs_get_empty   (void);
hb_unicode_funcs_t* hb_unicode_funcs_reference   (hb_unicode_funcs_t *ufuncs);
void                hb_unicode_funcs_destroy     (hb_unicode_funcs_t *ufuncs);

hb_bool_t hb_unicode_funcs_set_user_data (
	hb_unicode_funcs_t *ufuncs,
	hb_user_data_key_t *key,
	void * data,
	hb_destroy_func_t destroy,
	hb_bool_t replace);

void * hb_unicode_funcs_get_user_data (
	hb_unicode_funcs_t *ufuncs,
   hb_user_data_key_t *key);

void hb_unicode_funcs_make_immutable (hb_unicode_funcs_t *ufuncs);
hb_bool_t hb_unicode_funcs_is_immutable (hb_unicode_funcs_t *ufuncs);
hb_unicode_funcs_t * hb_unicode_funcs_get_parent (hb_unicode_funcs_t *ufuncs);

typedef hb_unicode_combining_class_t (*hb_unicode_combining_class_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t unicode,
	void *user_data);
typedef unsigned int (*hb_unicode_eastasian_width_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t unicode,
	void *user_data);
typedef hb_unicode_general_category_t (*hb_unicode_general_category_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t unicode,
	void *user_data);
typedef hb_codepoint_t (*hb_unicode_mirroring_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t unicode,
	void *user_data);
typedef hb_script_t (*hb_unicode_script_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t unicode,
	void *user_data);
typedef hb_bool_t (*hb_unicode_compose_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t a,
	hb_codepoint_t b,
	hb_codepoint_t *ab,
	void *user_data);
typedef hb_bool_t (*hb_unicode_decompose_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t ab,
	hb_codepoint_t *a,
	hb_codepoint_t *b,
	void *user_data);
typedef unsigned int (*hb_unicode_decompose_compatibility_func_t) (
	hb_unicode_funcs_t *ufuncs,
	hb_codepoint_t u,
	hb_codepoint_t *decomposed,
	void *user_data);

enum {
	HB_UNICODE_MAX_DECOMPOSITION_LEN = (18+1),
};

void
hb_unicode_funcs_set_combining_class_func (hb_unicode_funcs_t *ufuncs,
        hb_unicode_combining_class_func_t func,
        void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_eastasian_width_func (hb_unicode_funcs_t *ufuncs,
        hb_unicode_eastasian_width_func_t func,
        void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_general_category_func (hb_unicode_funcs_t *ufuncs,
         hb_unicode_general_category_func_t func,
         void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_mirroring_func (hb_unicode_funcs_t *ufuncs,
         hb_unicode_mirroring_func_t func,
         void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_script_func (hb_unicode_funcs_t *ufuncs,
      hb_unicode_script_func_t func,
      void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_compose_func (hb_unicode_funcs_t *ufuncs,
       hb_unicode_compose_func_t func,
       void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_decompose_func (hb_unicode_funcs_t *ufuncs,
         hb_unicode_decompose_func_t func,
         void *user_data, hb_destroy_func_t destroy);
void
hb_unicode_funcs_set_decompose_compatibility_func (hb_unicode_funcs_t *ufuncs,
         hb_unicode_decompose_compatibility_func_t func,
         void *user_data, hb_destroy_func_t destroy);
hb_unicode_combining_class_t
hb_unicode_combining_class (hb_unicode_funcs_t *ufuncs,
       hb_codepoint_t unicode);
unsigned int
hb_unicode_eastasian_width (hb_unicode_funcs_t *ufuncs,
       hb_codepoint_t unicode);
hb_unicode_general_category_t
hb_unicode_general_category (hb_unicode_funcs_t *ufuncs,
        hb_codepoint_t unicode);
hb_codepoint_t
hb_unicode_mirroring (hb_unicode_funcs_t *ufuncs,
        hb_codepoint_t unicode);
hb_script_t
hb_unicode_script (hb_unicode_funcs_t *ufuncs,
     hb_codepoint_t unicode);
hb_bool_t
hb_unicode_compose (hb_unicode_funcs_t *ufuncs,
      hb_codepoint_t a,
      hb_codepoint_t b,
      hb_codepoint_t *ab);
hb_bool_t
hb_unicode_decompose (hb_unicode_funcs_t *ufuncs,
        hb_codepoint_t ab,
        hb_codepoint_t *a,
        hb_codepoint_t *b);
unsigned int
hb_unicode_decompose_compatibility (hb_unicode_funcs_t *ufuncs,
        hb_codepoint_t u,
        hb_codepoint_t *decomposed);

// hb-blob.h -----------------------------------------------------------------

typedef enum {
	HB_MEMORY_MODE_DUPLICATE,
	HB_MEMORY_MODE_READONLY,
	HB_MEMORY_MODE_WRITABLE,
	HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE
} hb_memory_mode_t;

typedef struct hb_blob_t hb_blob_t;

hb_blob_t *
hb_blob_create (const char *data,
  unsigned int length,
  hb_memory_mode_t mode,
  void *user_data,
  hb_destroy_func_t destroy);
hb_blob_t *
hb_blob_create_sub_blob (hb_blob_t *parent,
    unsigned int offset,
    unsigned int length);
hb_blob_t *
hb_blob_copy_writable_or_fail (hb_blob_t *blob);
hb_blob_t *
hb_blob_get_empty (void);
hb_blob_t *
hb_blob_reference (hb_blob_t *blob);
void
hb_blob_destroy (hb_blob_t *blob);
hb_bool_t
hb_blob_set_user_data (hb_blob_t *blob,
         hb_user_data_key_t *key,
         void * data,
         hb_destroy_func_t destroy,
         hb_bool_t replace);
void *
hb_blob_get_user_data (hb_blob_t *blob,
         hb_user_data_key_t *key);
void
hb_blob_make_immutable (hb_blob_t *blob);
hb_bool_t
hb_blob_is_immutable (hb_blob_t *blob);
unsigned int
hb_blob_get_length (hb_blob_t *blob);
const char *
hb_blob_get_data (hb_blob_t *blob, unsigned int *length);
char *
hb_blob_get_data_writable (hb_blob_t *blob, unsigned int *length);
hb_blob_t *
hb_blob_create_from_file (const char *file_name);

// hb-face.h -----------------------------------------------------------------

unsigned int hb_face_count (hb_blob_t *blob);
typedef struct hb_face_t hb_face_t;
hb_face_t * hb_face_create (hb_blob_t *blob, unsigned int index);

typedef hb_blob_t * (*hb_reference_table_func_t) (hb_face_t *face, hb_tag_t tag, void *user_data);

hb_face_t * hb_face_create_for_tables (
	hb_reference_table_func_t reference_table_func,
	void *user_data,
	hb_destroy_func_t destroy);

hb_face_t * hb_face_get_empty (void);
hb_face_t * hb_face_reference (hb_face_t *face);
void hb_face_destroy (hb_face_t *face);

hb_bool_t hb_face_set_user_data (
	hb_face_t *face,
	hb_user_data_key_t *key,
	void * data,
	hb_destroy_func_t destroy,
	hb_bool_t replace);

void * hb_face_get_user_data (hb_face_t *face, hb_user_data_key_t *key);

void hb_face_make_immutable (hb_face_t *face);
hb_bool_t hb_face_is_immutable (hb_face_t *face);
hb_blob_t * hb_face_reference_table (hb_face_t *face, hb_tag_t tag);
hb_blob_t * hb_face_reference_blob (hb_face_t *face);
void         hb_face_set_index (hb_face_t *face, unsigned int index);
unsigned int hb_face_get_index (hb_face_t *face);
void         hb_face_set_upem (hb_face_t *face, unsigned int upem);
unsigned int hb_face_get_upem (hb_face_t *face);
void         hb_face_set_glyph_count (hb_face_t *face, unsigned int glyph_count);
unsigned int hb_face_get_glyph_count (hb_face_t *face);
unsigned int hb_face_get_table_tags (hb_face_t *face,
	unsigned int start_offset,
	unsigned int *table_count,
	hb_tag_t *table_tags );

// hb-font.h -----------------------------------------------------------------

typedef struct hb_font_t hb_font_t;
typedef struct hb_font_funcs_t hb_font_funcs_t;
hb_font_funcs_t * hb_font_funcs_create (void);
hb_font_funcs_t * hb_font_funcs_get_empty (void);
hb_font_funcs_t * hb_font_funcs_reference (hb_font_funcs_t *ffuncs);
void hb_font_funcs_destroy (hb_font_funcs_t *ffuncs);

hb_bool_t hb_font_funcs_set_user_data (
	hb_font_funcs_t *ffuncs,
	hb_user_data_key_t *key,
	void * data,
	hb_destroy_func_t destroy,
	hb_bool_t replace);

void * hb_font_funcs_get_user_data (
	hb_font_funcs_t *ffuncs,
	hb_user_data_key_t *key);

void hb_font_funcs_make_immutable (hb_font_funcs_t *ffuncs);
hb_bool_t hb_font_funcs_is_immutable (hb_font_funcs_t *ffuncs);

typedef struct hb_font_extents_t {
  hb_position_t ascender;
  hb_position_t descender;
  hb_position_t line_gap;
  hb_position_t reserved9;
  hb_position_t reserved8;
  hb_position_t reserved7;
  hb_position_t reserved6;
  hb_position_t reserved5;
  hb_position_t reserved4;
  hb_position_t reserved3;
  hb_position_t reserved2;
  hb_position_t reserved1;
} hb_font_extents_t;

typedef struct hb_glyph_extents_t {
  hb_position_t x_bearing;
  hb_position_t y_bearing;
  hb_position_t width;
  hb_position_t height;
} hb_glyph_extents_t;

typedef hb_bool_t (*hb_font_get_font_extents_func_t) (
	hb_font_t *font, void *font_data,
   hb_font_extents_t *metrics,
   void *user_data);
typedef hb_font_get_font_extents_func_t hb_font_get_font_h_extents_func_t;
typedef hb_font_get_font_extents_func_t hb_font_get_font_v_extents_func_t;
typedef hb_bool_t (*hb_font_get_nominal_glyph_func_t) (hb_font_t *font, void *font_data,
             hb_codepoint_t unicode,
             hb_codepoint_t *glyph,
             void *user_data);
typedef hb_bool_t (*hb_font_get_variation_glyph_func_t) (hb_font_t *font, void *font_data,
        hb_codepoint_t unicode, hb_codepoint_t variation_selector,
        hb_codepoint_t *glyph,
        void *user_data);
typedef hb_position_t (*hb_font_get_glyph_advance_func_t) (hb_font_t *font, void *font_data,
          hb_codepoint_t glyph,
          void *user_data);
typedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_h_advance_func_t;
typedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_v_advance_func_t;
typedef hb_bool_t (*hb_font_get_glyph_origin_func_t) (hb_font_t *font, void *font_data,
            hb_codepoint_t glyph,
            hb_position_t *x, hb_position_t *y,
            void *user_data);
typedef hb_font_get_glyph_origin_func_t hb_font_get_glyph_h_origin_func_t;
typedef hb_font_get_glyph_origin_func_t hb_font_get_glyph_v_origin_func_t;
typedef hb_position_t (*hb_font_get_glyph_kerning_func_t) (hb_font_t *font, void *font_data,
          hb_codepoint_t first_glyph, hb_codepoint_t second_glyph,
          void *user_data);
typedef hb_font_get_glyph_kerning_func_t hb_font_get_glyph_h_kerning_func_t;
typedef hb_font_get_glyph_kerning_func_t hb_font_get_glyph_v_kerning_func_t;
typedef hb_bool_t (*hb_font_get_glyph_extents_func_t) (hb_font_t *font, void *font_data,
             hb_codepoint_t glyph,
             hb_glyph_extents_t *extents,
             void *user_data);
typedef hb_bool_t (*hb_font_get_glyph_contour_point_func_t) (hb_font_t *font, void *font_data,
            hb_codepoint_t glyph, unsigned int point_index,
            hb_position_t *x, hb_position_t *y,
            void *user_data);
typedef hb_bool_t (*hb_font_get_glyph_name_func_t) (hb_font_t *font, void *font_data,
          hb_codepoint_t glyph,
          char *name, unsigned int size,
          void *user_data);
typedef hb_bool_t (*hb_font_get_glyph_from_name_func_t) (hb_font_t *font, void *font_data,
        const char *name, int len,
        hb_codepoint_t *glyph,
        void *user_data);
void
hb_font_funcs_set_font_h_extents_func (hb_font_funcs_t *ffuncs,
           hb_font_get_font_h_extents_func_t func,
           void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_font_v_extents_func (hb_font_funcs_t *ffuncs,
           hb_font_get_font_v_extents_func_t func,
           void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_nominal_glyph_func (hb_font_funcs_t *ffuncs,
          hb_font_get_nominal_glyph_func_t func,
          void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_variation_glyph_func (hb_font_funcs_t *ffuncs,
     hb_font_get_variation_glyph_func_t func,
     void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_h_advance_func (hb_font_funcs_t *ffuncs,
     hb_font_get_glyph_h_advance_func_t func,
     void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_v_advance_func (hb_font_funcs_t *ffuncs,
     hb_font_get_glyph_v_advance_func_t func,
     void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_h_origin_func (hb_font_funcs_t *ffuncs,
           hb_font_get_glyph_h_origin_func_t func,
           void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_v_origin_func (hb_font_funcs_t *ffuncs,
           hb_font_get_glyph_v_origin_func_t func,
           void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_h_kerning_func (hb_font_funcs_t *ffuncs,
     hb_font_get_glyph_h_kerning_func_t func,
     void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_v_kerning_func (hb_font_funcs_t *ffuncs,
     hb_font_get_glyph_v_kerning_func_t func,
     void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_extents_func (hb_font_funcs_t *ffuncs,
          hb_font_get_glyph_extents_func_t func,
          void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_contour_point_func (hb_font_funcs_t *ffuncs,
         hb_font_get_glyph_contour_point_func_t func,
         void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_name_func (hb_font_funcs_t *ffuncs,
       hb_font_get_glyph_name_func_t func,
       void *user_data, hb_destroy_func_t destroy);
void
hb_font_funcs_set_glyph_from_name_func (hb_font_funcs_t *ffuncs,
     hb_font_get_glyph_from_name_func_t func,
     void *user_data, hb_destroy_func_t destroy);
hb_bool_t
hb_font_get_h_extents (hb_font_t *font,
         hb_font_extents_t *extents);
hb_bool_t
hb_font_get_v_extents (hb_font_t *font,
         hb_font_extents_t *extents);
hb_bool_t
hb_font_get_nominal_glyph (hb_font_t *font,
      hb_codepoint_t unicode,
      hb_codepoint_t *glyph);
hb_bool_t
hb_font_get_variation_glyph (hb_font_t *font,
        hb_codepoint_t unicode, hb_codepoint_t variation_selector,
        hb_codepoint_t *glyph);
hb_position_t
hb_font_get_glyph_h_advance (hb_font_t *font,
        hb_codepoint_t glyph);
hb_position_t
hb_font_get_glyph_v_advance (hb_font_t *font,
        hb_codepoint_t glyph);
hb_bool_t
hb_font_get_glyph_h_origin (hb_font_t *font,
       hb_codepoint_t glyph,
       hb_position_t *x, hb_position_t *y);
hb_bool_t
hb_font_get_glyph_v_origin (hb_font_t *font,
       hb_codepoint_t glyph,
       hb_position_t *x, hb_position_t *y);
hb_position_t
hb_font_get_glyph_h_kerning (hb_font_t *font,
        hb_codepoint_t left_glyph, hb_codepoint_t right_glyph);
hb_position_t
hb_font_get_glyph_v_kerning (hb_font_t *font,
        hb_codepoint_t top_glyph, hb_codepoint_t bottom_glyph);
hb_bool_t
hb_font_get_glyph_extents (hb_font_t *font,
      hb_codepoint_t glyph,
      hb_glyph_extents_t *extents);
hb_bool_t
hb_font_get_glyph_contour_point (hb_font_t *font,
     hb_codepoint_t glyph, unsigned int point_index,
     hb_position_t *x, hb_position_t *y);
hb_bool_t
hb_font_get_glyph_name (hb_font_t *font,
   hb_codepoint_t glyph,
   char *name, unsigned int size);
hb_bool_t
hb_font_get_glyph_from_name (hb_font_t *font,
        const char *name, int len,
        hb_codepoint_t *glyph);
hb_bool_t
hb_font_get_glyph (hb_font_t *font,
     hb_codepoint_t unicode, hb_codepoint_t variation_selector,
     hb_codepoint_t *glyph);
void
hb_font_get_extents_for_direction (hb_font_t *font,
       hb_direction_t direction,
       hb_font_extents_t *extents);
void
hb_font_get_glyph_advance_for_direction (hb_font_t *font,
      hb_codepoint_t glyph,
      hb_direction_t direction,
      hb_position_t *x, hb_position_t *y);
void
hb_font_get_glyph_origin_for_direction (hb_font_t *font,
     hb_codepoint_t glyph,
     hb_direction_t direction,
     hb_position_t *x, hb_position_t *y);
void
hb_font_add_glyph_origin_for_direction (hb_font_t *font,
     hb_codepoint_t glyph,
     hb_direction_t direction,
     hb_position_t *x, hb_position_t *y);
void
hb_font_subtract_glyph_origin_for_direction (hb_font_t *font,
          hb_codepoint_t glyph,
          hb_direction_t direction,
          hb_position_t *x, hb_position_t *y);
void
hb_font_get_glyph_kerning_for_direction (hb_font_t *font,
      hb_codepoint_t first_glyph, hb_codepoint_t second_glyph,
      hb_direction_t direction,
      hb_position_t *x, hb_position_t *y);
hb_bool_t
hb_font_get_glyph_extents_for_origin (hb_font_t *font,
          hb_codepoint_t glyph,
          hb_direction_t direction,
          hb_glyph_extents_t *extents);
hb_bool_t
hb_font_get_glyph_contour_point_for_origin (hb_font_t *font,
         hb_codepoint_t glyph, unsigned int point_index,
         hb_direction_t direction,
         hb_position_t *x, hb_position_t *y);
void
hb_font_glyph_to_string (hb_font_t *font,
    hb_codepoint_t glyph,
    char *s, unsigned int size);
hb_bool_t
hb_font_glyph_from_string (hb_font_t *font,
      const char *s, int len,
      hb_codepoint_t *glyph);
hb_font_t *
hb_font_create (hb_face_t *face);
hb_font_t *
hb_font_create_sub_font (hb_font_t *parent);
hb_font_t *
hb_font_get_empty (void);
hb_font_t *
hb_font_reference (hb_font_t *font);
void
hb_font_destroy (hb_font_t *font);
hb_bool_t
hb_font_set_user_data (hb_font_t *font,
         hb_user_data_key_t *key,
         void * data,
         hb_destroy_func_t destroy,
         hb_bool_t replace);
void *
hb_font_get_user_data (hb_font_t *font,
         hb_user_data_key_t *key);
void
hb_font_make_immutable (hb_font_t *font);
hb_bool_t
hb_font_is_immutable (hb_font_t *font);
void
hb_font_set_parent (hb_font_t *font,
      hb_font_t *parent);
hb_font_t *
hb_font_get_parent (hb_font_t *font);
void
hb_font_set_face (hb_font_t *font,
    hb_face_t *face);
hb_face_t *
hb_font_get_face (hb_font_t *font);
void
hb_font_set_funcs (hb_font_t *font,
     hb_font_funcs_t *klass,
     void *font_data,
     hb_destroy_func_t destroy);
void
hb_font_set_funcs_data (hb_font_t *font,
          void *font_data,
          hb_destroy_func_t destroy);
void
hb_font_set_scale (hb_font_t *font,
     int x_scale,
     int y_scale);
void
hb_font_get_scale (hb_font_t *font,
     int *x_scale,
     int *y_scale);
void
hb_font_set_ppem (hb_font_t *font,
    unsigned int x_ppem,
    unsigned int y_ppem);
void
hb_font_get_ppem (hb_font_t *font,
    unsigned int *x_ppem,
    unsigned int *y_ppem);
void
hb_font_set_ptem (hb_font_t *font, float ptem);
float
hb_font_get_ptem (hb_font_t *font);
void
hb_font_set_variations (hb_font_t *font,
   const hb_variation_t *variations,
   unsigned int variations_length);
void
hb_font_set_var_coords_design (hb_font_t *font,
          const float *coords,
          unsigned int coords_length);
void
hb_font_set_var_coords_normalized (hb_font_t *font,
       const int *coords,
       unsigned int coords_length);
const int *
hb_font_get_var_coords_normalized (hb_font_t *font,
       unsigned int *length);

// hb-buffer.h ---------------------------------------------------------------

typedef struct hb_glyph_info_t {
	hb_codepoint_t codepoint;
	hb_mask_t mask;
	uint32_t cluster;
	hb_var_int_t var1;
	hb_var_int_t var2;
} hb_glyph_info_t;

typedef enum {
	HB_GLYPH_FLAG_UNSAFE_TO_BREAK = 0x00000001,
	HB_GLYPH_FLAG_DEFINED = 0x00000001
} hb_glyph_flags_t;

hb_glyph_flags_t hb_glyph_info_get_glyph_flags (const hb_glyph_info_t *info);

typedef struct hb_glyph_position_t {
  hb_position_t x_advance;
  hb_position_t y_advance;
  hb_position_t x_offset;
  hb_position_t y_offset;
  hb_var_int_t var;
} hb_glyph_position_t;
typedef struct hb_segment_properties_t {
  hb_direction_t direction;
  hb_script_t script;
  hb_language_t language;
  void *reserved1;
  void *reserved2;
} hb_segment_properties_t;

hb_bool_t
hb_segment_properties_equal (const hb_segment_properties_t *a,
        const hb_segment_properties_t *b);
unsigned int
hb_segment_properties_hash (const hb_segment_properties_t *p);
typedef struct hb_buffer_t hb_buffer_t;
hb_buffer_t *
hb_buffer_create (void);
hb_buffer_t *
hb_buffer_get_empty (void);
hb_buffer_t *
hb_buffer_reference (hb_buffer_t *buffer);
void
hb_buffer_destroy (hb_buffer_t *buffer);
hb_bool_t
hb_buffer_set_user_data (hb_buffer_t *buffer,
    hb_user_data_key_t *key,
    void * data,
    hb_destroy_func_t destroy,
    hb_bool_t replace);
void *
hb_buffer_get_user_data (hb_buffer_t *buffer,
    hb_user_data_key_t *key);
typedef enum {
	HB_BUFFER_CONTENT_TYPE_INVALID = 0,
	HB_BUFFER_CONTENT_TYPE_UNICODE,
	HB_BUFFER_CONTENT_TYPE_GLYPHS
} hb_buffer_content_type_t;
void
hb_buffer_set_content_type (hb_buffer_t *buffer,
       hb_buffer_content_type_t content_type);
hb_buffer_content_type_t
hb_buffer_get_content_type (hb_buffer_t *buffer);
void
hb_buffer_set_unicode_funcs (hb_buffer_t *buffer,
        hb_unicode_funcs_t *unicode_funcs);
hb_unicode_funcs_t *
hb_buffer_get_unicode_funcs (hb_buffer_t *buffer);
void
hb_buffer_set_direction (hb_buffer_t *buffer,
    hb_direction_t direction);
hb_direction_t
hb_buffer_get_direction (hb_buffer_t *buffer);
void
hb_buffer_set_script (hb_buffer_t *buffer,
        hb_script_t script);
hb_script_t
hb_buffer_get_script (hb_buffer_t *buffer);
void
hb_buffer_set_language (hb_buffer_t *buffer,
   hb_language_t language);
hb_language_t
hb_buffer_get_language (hb_buffer_t *buffer);
void
hb_buffer_set_segment_properties (hb_buffer_t *buffer,
      const hb_segment_properties_t *props);
void
hb_buffer_get_segment_properties (hb_buffer_t *buffer,
      hb_segment_properties_t *props);
void
hb_buffer_guess_segment_properties (hb_buffer_t *buffer);
typedef enum {
	HB_BUFFER_FLAG_DEFAULT = 0x00000000u,
	HB_BUFFER_FLAG_BOT = 0x00000001u,
	HB_BUFFER_FLAG_EOT = 0x00000002u,
	HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES = 0x00000004u,
	HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES = 0x00000008u
} hb_buffer_flags_t;
void
hb_buffer_set_flags (hb_buffer_t *buffer,
       hb_buffer_flags_t flags);
hb_buffer_flags_t
hb_buffer_get_flags (hb_buffer_t *buffer);
typedef enum {
	HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES = 0,
	HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS = 1,
	HB_BUFFER_CLUSTER_LEVEL_CHARACTERS = 2,
	HB_BUFFER_CLUSTER_LEVEL_DEFAULT = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
} hb_buffer_cluster_level_t;
void
hb_buffer_set_cluster_level (hb_buffer_t *buffer,
        hb_buffer_cluster_level_t cluster_level);
hb_buffer_cluster_level_t
hb_buffer_get_cluster_level (hb_buffer_t *buffer);
enum {
	HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT = 0xFFFDu,
};
void
hb_buffer_set_replacement_codepoint (hb_buffer_t *buffer,
         hb_codepoint_t replacement);
hb_codepoint_t
hb_buffer_get_replacement_codepoint (hb_buffer_t *buffer);
void
hb_buffer_reset (hb_buffer_t *buffer);
void
hb_buffer_clear_contents (hb_buffer_t *buffer);
hb_bool_t
hb_buffer_pre_allocate (hb_buffer_t *buffer,
          unsigned int size);
hb_bool_t
hb_buffer_allocation_successful (hb_buffer_t *buffer);
void
hb_buffer_reverse (hb_buffer_t *buffer);
void
hb_buffer_reverse_range (hb_buffer_t *buffer,
    unsigned int start, unsigned int end);
void
hb_buffer_reverse_clusters (hb_buffer_t *buffer);
void
hb_buffer_add (hb_buffer_t *buffer,
        hb_codepoint_t codepoint,
        unsigned int cluster);
void
hb_buffer_add_utf8 (hb_buffer_t *buffer,
      const char *text,
      int text_length,
      unsigned int item_offset,
      int item_length);
void
hb_buffer_add_utf16 (hb_buffer_t *buffer,
       const uint16_t *text,
       int text_length,
       unsigned int item_offset,
       int item_length);
void
hb_buffer_add_utf32 (hb_buffer_t *buffer,
       const uint32_t *text,
       int text_length,
       unsigned int item_offset,
       int item_length);
void
hb_buffer_add_latin1 (hb_buffer_t *buffer,
        const uint8_t *text,
        int text_length,
        unsigned int item_offset,
        int item_length);
void
hb_buffer_add_codepoints (hb_buffer_t *buffer,
     const hb_codepoint_t *text,
     int text_length,
     unsigned int item_offset,
     int item_length);
void
hb_buffer_append (hb_buffer_t *buffer,
    hb_buffer_t *source,
    unsigned int start,
    unsigned int end);
hb_bool_t
hb_buffer_set_length (hb_buffer_t *buffer,
        unsigned int length);
unsigned int
hb_buffer_get_length (hb_buffer_t *buffer);
hb_glyph_info_t *
hb_buffer_get_glyph_infos (hb_buffer_t *buffer,
                           unsigned int *length);
hb_glyph_position_t *
hb_buffer_get_glyph_positions (hb_buffer_t *buffer,
                               unsigned int *length);
void
hb_buffer_normalize_glyphs (hb_buffer_t *buffer);
typedef enum {
	HB_BUFFER_SERIALIZE_FLAG_DEFAULT = 0x00000000u,
	HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS = 0x00000001u,
	HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS = 0x00000002u,
	HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES = 0x00000004u,
	HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS = 0x00000008u,
	HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS = 0x00000010u,
	HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES = 0x00000020u
} hb_buffer_serialize_flags_t;
typedef enum {
	HB_BUFFER_SERIALIZE_FORMAT_TEXT = ((hb_tag_t)((((uint8_t)('T'))<<24)|(((uint8_t)('E'))<<16)|(((uint8_t)('X'))<<8)|((uint8_t)('T')))),
	HB_BUFFER_SERIALIZE_FORMAT_JSON = ((hb_tag_t)((((uint8_t)('J'))<<24)|(((uint8_t)('S'))<<16)|(((uint8_t)('O'))<<8)|((uint8_t)('N')))),
	HB_BUFFER_SERIALIZE_FORMAT_INVALID = ((hb_tag_t)((((uint8_t)(0))<<24)|(((uint8_t)(0))<<16)|(((uint8_t)(0))<<8)|((uint8_t)(0))))
} hb_buffer_serialize_format_t;
hb_buffer_serialize_format_t
hb_buffer_serialize_format_from_string (const char *str, int len);
const char *
hb_buffer_serialize_format_to_string (hb_buffer_serialize_format_t format);
const char **
hb_buffer_serialize_list_formats (void);
unsigned int
hb_buffer_serialize_glyphs (hb_buffer_t *buffer,
       unsigned int start,
       unsigned int end,
       char *buf,
       unsigned int buf_size,
       unsigned int *buf_consumed,
       hb_font_t *font,
       hb_buffer_serialize_format_t format,
       hb_buffer_serialize_flags_t flags);
hb_bool_t
hb_buffer_deserialize_glyphs (hb_buffer_t *buffer,
         const char *buf,
         int buf_len,
         const char **end_ptr,
         hb_font_t *font,
         hb_buffer_serialize_format_t format);
typedef enum {
	HB_BUFFER_DIFF_FLAG_EQUAL = 0x0000,
	HB_BUFFER_DIFF_FLAG_CONTENT_TYPE_MISMATCH = 0x0001,
	HB_BUFFER_DIFF_FLAG_LENGTH_MISMATCH = 0x0002,
	HB_BUFFER_DIFF_FLAG_NOTDEF_PRESENT = 0x0004,
	HB_BUFFER_DIFF_FLAG_DOTTED_CIRCLE_PRESENT = 0x0008,
	HB_BUFFER_DIFF_FLAG_CODEPOINT_MISMATCH = 0x0010,
	HB_BUFFER_DIFF_FLAG_CLUSTER_MISMATCH = 0x0020,
	HB_BUFFER_DIFF_FLAG_GLYPH_FLAGS_MISMATCH = 0x0040,
	HB_BUFFER_DIFF_FLAG_POSITION_MISMATCH = 0x0080
} hb_buffer_diff_flags_t;
hb_buffer_diff_flags_t
hb_buffer_diff (hb_buffer_t *buffer,
  hb_buffer_t *reference,
  hb_codepoint_t dottedcircle_glyph,
  unsigned int position_fuzz);
typedef hb_bool_t (*hb_buffer_message_func_t) (hb_buffer_t *buffer,
        hb_font_t *font,
        const char *message,
        void *user_data);
void
hb_buffer_set_message_func (hb_buffer_t *buffer,
       hb_buffer_message_func_t func,
       void *user_data, hb_destroy_func_t destroy);

// hb-shape.h ----------------------------------------------------------------

void
hb_shape (hb_font_t *font,
   hb_buffer_t *buffer,
   const hb_feature_t *features,
   unsigned int num_features);
hb_bool_t
hb_shape_full (hb_font_t *font,
        hb_buffer_t *buffer,
        const hb_feature_t *features,
        unsigned int num_features,
        const char * const *shaper_list);
const char **
hb_shape_list_shapers (void);

// hb-shape-plan.h -----------------------------------------------------------

typedef struct hb_shape_plan_t hb_shape_plan_t;
hb_shape_plan_t *
hb_shape_plan_create (hb_face_t *face,
        const hb_segment_properties_t *props,
        const hb_feature_t *user_features,
        unsigned int num_user_features,
        const char * const *shaper_list);
hb_shape_plan_t *
hb_shape_plan_create_cached (hb_face_t *face,
        const hb_segment_properties_t *props,
        const hb_feature_t *user_features,
        unsigned int num_user_features,
        const char * const *shaper_list);
hb_shape_plan_t *
hb_shape_plan_create2 (hb_face_t *face,
         const hb_segment_properties_t *props,
         const hb_feature_t *user_features,
         unsigned int num_user_features,
         const int *coords,
         unsigned int num_coords,
         const char * const *shaper_list);
hb_shape_plan_t *
hb_shape_plan_create_cached2 (hb_face_t *face,
         const hb_segment_properties_t *props,
         const hb_feature_t *user_features,
         unsigned int num_user_features,
         const int *coords,
         unsigned int num_coords,
         const char * const *shaper_list);
hb_shape_plan_t *
hb_shape_plan_get_empty (void);
hb_shape_plan_t *
hb_shape_plan_reference (hb_shape_plan_t *shape_plan);
void
hb_shape_plan_destroy (hb_shape_plan_t *shape_plan);
hb_bool_t
hb_shape_plan_set_user_data (hb_shape_plan_t *shape_plan,
        hb_user_data_key_t *key,
        void * data,
        hb_destroy_func_t destroy,
        hb_bool_t replace);
void *
hb_shape_plan_get_user_data (hb_shape_plan_t *shape_plan,
        hb_user_data_key_t *key);
hb_bool_t
hb_shape_plan_execute (hb_shape_plan_t *shape_plan,
         hb_font_t *font,
         hb_buffer_t *buffer,
         const hb_feature_t *features,
         unsigned int num_features);
const char *
hb_shape_plan_get_shaper (hb_shape_plan_t *shape_plan);

// hb-version.h --------------------------------------------------------------

void hb_version (
	unsigned int *major,
	unsigned int *minor,
	unsigned int *micro);

const char * hb_version_string (void);

hb_bool_t hb_version_atleast (
	unsigned int major,
	unsigned int minor,
	unsigned int micro);
]]
