--result of `cpp fribidi.h` and `charset/*.h` from fribidi HEAD from June 08, 2013
local ffi = require'ffi'

ffi.cdef[[
/* A few Unicode characters: */
typedef enum {
	/* Bidirectional marks */
	FRIBIDI_CHAR_LRM		= 0x200E,
	FRIBIDI_CHAR_RLM		= 0x200F,
	FRIBIDI_CHAR_LRE		= 0x202A,
	FRIBIDI_CHAR_RLE		= 0x202B,
	FRIBIDI_CHAR_PDF		= 0x202C,
	FRIBIDI_CHAR_LRO		= 0x202D,
	FRIBIDI_CHAR_RLO		= 0x202E,

	/* Line and Paragraph Separators */
	FRIBIDI_CHAR_LS			= 0x2028,
	FRIBIDI_CHAR_PS			= 0x2029,

	/* Arabic Joining marks */
	FRIBIDI_CHAR_ZWNJ		= 0x200C,
	FRIBIDI_CHAR_ZWJ		= 0x200D,

	/* Hebrew and Arabic */
	FRIBIDI_CHAR_HEBREW_ALEF	= 0x05D0,
	FRIBIDI_CHAR_ARABIC_ALEF	= 0x0627,
	FRIBIDI_CHAR_ARABIC_ZERO	= 0x0660,
	FRIBIDI_CHAR_PERSIAN_ZERO	= 0x06F0,

	/* Misc */
	FRIBIDI_CHAR_ZWNBSP	= 0xFEFF,

	/* Char we place for a deleted slot, to delete later */
	FRIBIDI_CHAR_FILL		= FRIBIDI_CHAR_ZWNBSP,
};

/* Option flags */
typedef enum {
	FRIBIDI_FLAG_SHAPE_MIRRORING  = 0x00000001,
	FRIBIDI_FLAG_REORDER_NSM      = 0x00000002,

	FRIBIDI_FLAG_SHAPE_ARAB_PRES  = 0x00000100,
	FRIBIDI_FLAG_SHAPE_ARAB_LIGA  = 0x00000200,
	FRIBIDI_FLAG_SHAPE_ARAB_CONSOLE = 0x00000400,

	FRIBIDI_FLAG_REMOVE_BIDI      = 0x00010000,
	FRIBIDI_FLAG_REMOVE_JOINING   = 0x00020000,
	FRIBIDI_FLAG_REMOVE_SPECIALS  = 0x00040000,

	/* And their combinations */
	FRIBIDI_FLAGS_DEFAULT      = ( \
		FRIBIDI_FLAG_SHAPE_MIRRORING	| \
		FRIBIDI_FLAG_REORDER_NSM	| \
		FRIBIDI_FLAG_REMOVE_SPECIALS	),

	FRIBIDI_FLAGS_ARABIC       = ( \
		FRIBIDI_FLAG_SHAPE_ARAB_PRES	| \
		FRIBIDI_FLAG_SHAPE_ARAB_LIGA	),
};

typedef unsigned char fribidi_int8;
typedef signed short fribidi_int16;
typedef signed int fribidi_int32;
typedef unsigned char fribidi_uint8;
typedef unsigned short fribidi_uint16;
typedef unsigned int fribidi_uint32;
typedef int fribidi_boolean;
typedef fribidi_uint32 FriBidiChar;
typedef int FriBidiStrIndex;

const char *fribidi_unicode_version;

typedef fribidi_uint32 FriBidiFlags;
typedef signed char FriBidiLevel;

typedef enum {
	FRIBIDI_TYPE_LTR = ( 0x00000010 | 0x00000100 ),
	FRIBIDI_TYPE_RTL = ( 0x00000010 | 0x00000100 | 0x00000001 ),
	FRIBIDI_TYPE_AL = ( 0x00000010 | 0x00000100 | 0x00000001 | 0x00000002 ),
	FRIBIDI_TYPE_EN = ( 0x00000020 | 0x00000200 ),
	FRIBIDI_TYPE_AN = ( 0x00000020 | 0x00000200 | 0x00000002 ),
	FRIBIDI_TYPE_ES = ( 0x00000020 | 0x00000400 | 0x00010000 ),
	FRIBIDI_TYPE_ET = ( 0x00000020 | 0x00000400 | 0x00020000 ),
	FRIBIDI_TYPE_CS = ( 0x00000020 | 0x00000400 | 0x00040000 ),
	FRIBIDI_TYPE_NSM = ( 0x00000020 | 0x00080000 ),
	FRIBIDI_TYPE_BN = ( 0x00000020 | 0x00000800 | 0x00100000 ),
	FRIBIDI_TYPE_BS = ( 0x00000040 | 0x00000800 | 0x00002000 | 0x00200000 ),
	FRIBIDI_TYPE_SS = ( 0x00000040 | 0x00000800 | 0x00002000 | 0x00400000 ),
	FRIBIDI_TYPE_WS = ( 0x00000040 | 0x00000800 | 0x00800000 ),
	FRIBIDI_TYPE_ON = ( 0x00000040 ),
	FRIBIDI_TYPE_LRE = ( 0x00000010 | 0x00001000 ),
	FRIBIDI_TYPE_RLE = ( 0x00000010 | 0x00001000 | 0x00000001 ),
	FRIBIDI_TYPE_LRO = ( 0x00000010 | 0x00001000 | 0x00004000 ),
	FRIBIDI_TYPE_RLO = ( 0x00000010 | 0x00001000 | 0x00000001 | 0x00004000 ),
	FRIBIDI_TYPE_PDF = ( 0x00000020 | 0x00001000 ),
} FriBidiCharType;

typedef enum {
	FRIBIDI_PAR_LTR = ( 0x00000010 | 0x00000100 ),
	FRIBIDI_PAR_RTL = ( 0x00000010 | 0x00000100 | 0x00000001 ),
	FRIBIDI_PAR_ON = ( 0x00000040 ),
	FRIBIDI_PAR_WLTR = ( 0x00000020 ),
	FRIBIDI_PAR_WRTL = ( 0x00000020 | 0x00000001 ),
} FriBidiParType;

FriBidiCharType fribidi_get_bidi_type (FriBidiChar ch);

void fribidi_get_bidi_types (
  const FriBidiChar *str,
  const FriBidiStrIndex len,
  FriBidiCharType *btypes
);

const char *fribidi_get_bidi_type_name (FriBidiCharType t);

FriBidiParType fribidi_get_par_direction (
  const FriBidiCharType *bidi_types,
  const FriBidiStrIndex len
);

FriBidiLevel fribidi_get_par_embedding_levels (
  const FriBidiCharType *bidi_types,
  const FriBidiStrIndex len,
  FriBidiParType *pbase_dir,
  FriBidiLevel *embedding_levels
);

FriBidiLevel fribidi_reorder_line (
  FriBidiFlags flags,
  const FriBidiCharType *bidi_types,
  const FriBidiStrIndex len,
  const FriBidiStrIndex off,
  const FriBidiParType base_dir,
  FriBidiLevel *embedding_levels,
  FriBidiChar *visual_str,
  FriBidiStrIndex *map
);

enum _FriBidiJoiningTypeEnum {
	FRIBIDI_JOINING_TYPE_U = ( 0 ),
	FRIBIDI_JOINING_TYPE_R = ( 0x01 | 0x04 ),
	FRIBIDI_JOINING_TYPE_D = ( 0x01 | 0x02 | 0x04 ),
	FRIBIDI_JOINING_TYPE_C = ( 0x01 | 0x02 ),
	FRIBIDI_JOINING_TYPE_T = ( 0x08 | 0x04 ),
	FRIBIDI_JOINING_TYPE_L = ( 0x02 | 0x04 ),
	FRIBIDI_JOINING_TYPE_G = ( 0x10 ),
};

typedef fribidi_uint8 FriBidiJoiningType;
typedef fribidi_uint8 FriBidiArabicProp;

FriBidiJoiningType fribidi_get_joining_type (FriBidiChar ch);

void fribidi_get_joining_types (
  const FriBidiChar *str,
  const FriBidiStrIndex len,
  FriBidiJoiningType *jtypes
);

const char *fribidi_get_joining_type_name (FriBidiJoiningType j);

void fribidi_join_arabic (
  const FriBidiCharType *bidi_types,
  const FriBidiStrIndex len,
  const FriBidiLevel *embedding_levels,
  FriBidiArabicProp *ar_props
);

fribidi_boolean fribidi_get_mirror_char (
  FriBidiChar ch,
  FriBidiChar *mirrored_ch
);

void fribidi_shape_mirroring (
  const FriBidiLevel *embedding_levels,
  const FriBidiStrIndex len,
  FriBidiChar *str
);

void fribidi_shape_arabic (
  FriBidiFlags flags,
  const FriBidiLevel *embedding_levels,
  const FriBidiStrIndex len,
  FriBidiArabicProp *ar_props,
  FriBidiChar *str
);

void fribidi_shape (
  FriBidiFlags flags,
  const FriBidiLevel *embedding_levels,
  const FriBidiStrIndex len,
  FriBidiArabicProp *ar_props,
  FriBidiChar *str
);

fribidi_boolean fribidi_mirroring_status (void);

fribidi_boolean fribidi_set_mirroring (fribidi_boolean state);
fribidi_boolean fribidi_reorder_nsm_status (void);
fribidi_boolean fribidi_set_reorder_nsm (fribidi_boolean state);

FriBidiLevel fribidi_log2vis_get_embedding_levels (
  const FriBidiCharType *bidi_types,
  const FriBidiStrIndex len,
  FriBidiParType *pbase_dir,
  FriBidiLevel *embedding_levels
);

FriBidiCharType fribidi_get_type (FriBidiChar ch);

FriBidiCharType fribidi_get_type_internal (FriBidiChar ch);

FriBidiStrIndex fribidi_remove_bidi_marks (
  FriBidiChar *str,
  const FriBidiStrIndex len,
  FriBidiStrIndex *positions_to_this,
  FriBidiStrIndex *position_from_this_list,
  FriBidiLevel *embedding_levels
);

FriBidiLevel fribidi_log2vis (
  const FriBidiChar *str,
  const FriBidiStrIndex len,
  FriBidiParType *pbase_dir,
  FriBidiChar *visual_str,
  FriBidiStrIndex *positions_L_to_V,
  FriBidiStrIndex *positions_V_to_L,
  FriBidiLevel *embedding_levels
);

const char *fribidi_version_info;
]]

--charset/*.h

ffi.cdef[[
typedef enum {
	FRIBIDI_CHAR_SET_NA,
	FRIBIDI_CHAR_SET_UTF8,
	FRIBIDI_CHAR_SET_CAP_RTL,
	FRIBIDI_CHAR_SET_ISO8859_6,
	FRIBIDI_CHAR_SET_ISO8859_8,
	FRIBIDI_CHAR_SET_CP1255,
	FRIBIDI_CHAR_SET_CP1256,
} FriBidiCharSet;

FriBidiStrIndex fribidi_charset_to_unicode (FriBidiCharSet char_set, const char *s, FriBidiStrIndex len, FriBidiChar *us);
FriBidiStrIndex fribidi_unicode_to_charset (FriBidiCharSet char_set, const FriBidiChar *us, FriBidiStrIndex len, char *s);

FriBidiCharSet fribidi_parse_charset (const char *s);
const char *fribidi_char_set_name (FriBidiCharSet char_set);
const char *fribidi_char_set_title (FriBidiCharSet char_set);

const char *fribidi_char_set_desc_cap_rtl (void);

FriBidiStrIndex fribidi_cap_rtl_to_unicode (const char *s, FriBidiStrIndex length, FriBidiChar *us);
FriBidiStrIndex fribidi_unicode_to_cap_rtl (const FriBidiChar *us, FriBidiStrIndex length, char *s);

FriBidiChar fribidi_cp1255_to_unicode_c (char ch);
char fribidi_unicode_to_cp1255_c (FriBidiChar uch);

FriBidiChar fribidi_cp1256_to_unicode_c (char ch);
char fribidi_unicode_to_cp1256_c (FriBidiChar uch);

FriBidiChar fribidi_iso8859_6_to_unicode_c (char ch);
char fribidi_unicode_to_iso8859_6_c (FriBidiChar uch);

FriBidiChar fribidi_iso8859_8_to_unicode_c (char ch);
char fribidi_unicode_to_iso8859_8_c (FriBidiChar uch);

FriBidiStrIndex fribidi_utf8_to_unicode (const char *s, FriBidiStrIndex length, FriBidiChar *us);
FriBidiStrIndex fribidi_unicode_to_utf8 (const FriBidiChar *us, FriBidiStrIndex length, char *s);
]]

