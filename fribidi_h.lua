--fribidi.h from fribidi 1.8.2
local ffi = require'ffi'
ffi.cdef[[

// fribidi.h

const char *fribidi_version_info;

// fribidi-unicode.h

enum {
	// We do not support surrogates yet
	FRIBIDI_UNICODE_CHARS = 0xFFFE,
};

const char *fribidi_unicode_version;

enum {
   // A few relevant Unicode characters:
	// Bidirectional marks
	FRIBIDI_CHAR_LRM     = 0x200E,
	FRIBIDI_CHAR_RLM     = 0x200F,
	FRIBIDI_CHAR_LRE     = 0x202A,
	FRIBIDI_CHAR_RLE     = 0x202B,
	FRIBIDI_CHAR_PDF     = 0x202C,
	FRIBIDI_CHAR_LRO     = 0x202D,
	FRIBIDI_CHAR_RLO     = 0x202E,
	FRIBIDI_CHAR_LRI     = 0x2066,
	FRIBIDI_CHAR_RLI     = 0x2067,
	FRIBIDI_CHAR_FSI     = 0x2068,
	FRIBIDI_CHAR_PDI     = 0x2069,
	// Line and Paragraph Separators
	FRIBIDI_CHAR_LS      = 0x2028,
	FRIBIDI_CHAR_PS      = 0x2029,
	// Arabic Joining marks
	FRIBIDI_CHAR_ZWNJ    = 0x200C,
	FRIBIDI_CHAR_ZWJ     = 0x200D,
	// Hebrew and Arabic
	FRIBIDI_CHAR_HEBREW_ALEF = 0x05D0,
	FRIBIDI_CHAR_ARABIC_ALEF = 0x0627,
	FRIBIDI_CHAR_ARABIC_ZERO = 0x0660,
	FRIBIDI_CHAR_PERSIAN_ZERO = 0x06F0,
	// Misc
	FRIBIDI_CHAR_ZWNBSP  = 0xFEFF,
};

// fribidi-types.h

typedef int fribidi_boolean;
typedef uint32_t FriBidiChar;
typedef int FriBidiStrIndex;
typedef FriBidiChar FriBidiBracketType;

enum {
	// Use FRIBIDI_NO_BRACKET for assigning to a non-bracket
	FRIBIDI_NO_BRACKET   = 0,
};

// fribidi-unicode-version.h

enum {
	FRIBIDI_UNICODE_MAJOR_VERSION = 11,
	FRIBIDI_UNICODE_MINOR_VERSION = 0,
	FRIBIDI_UNICODE_MICRO_VERSION = 0,
};

// fribidi-flags.h

typedef uint32_t FriBidiFlags;

enum {
	// option flags that various functions use.
	FRIBIDI_FLAG_SHAPE_MIRRORING = 0x00000001,
	FRIBIDI_FLAG_REORDER_NSM = 0x00000002,
	FRIBIDI_FLAG_SHAPE_ARAB_PRES = 0x00000100,
	FRIBIDI_FLAG_SHAPE_ARAB_LIGA = 0x00000200,
	FRIBIDI_FLAG_SHAPE_ARAB_CONSOLE = 0x00000400,
	FRIBIDI_FLAG_REMOVE_BIDI = 0x00010000,
	FRIBIDI_FLAG_REMOVE_JOINING = 0x00020000,
	FRIBIDI_FLAG_REMOVE_SPECIALS = 0x00040000,
	FRIBIDI_FLAGS_DEFAULT = ( FRIBIDI_FLAG_SHAPE_MIRRORING | FRIBIDI_FLAG_REORDER_NSM | FRIBIDI_FLAG_REMOVE_SPECIALS ),
	FRIBIDI_FLAGS_ARABIC = ( FRIBIDI_FLAG_SHAPE_ARAB_PRES | FRIBIDI_FLAG_SHAPE_ARAB_LIGA ),
};

// fribidi-bidi-types.h

typedef signed char FriBidiLevel;

enum {

	// RTL mask better be the least significant bit.
	FRIBIDI_MASK_RTL    = 0x00000001,  // Is right to left
	FRIBIDI_MASK_ARABIC = 0x00000002,  // Is arabic

	// Each char can be only one of the three following.
	FRIBIDI_MASK_STRONG   = 0x00000010, // Is strong
	FRIBIDI_MASK_WEAK     = 0x00000020, // Is weak
	FRIBIDI_MASK_NEUTRAL  = 0x00000040, // Is neutral
	FRIBIDI_MASK_SENTINEL = 0x00000080, // Is sentinel
	// Sentinels are not valid chars, just identify the start/end of strings.

	// Each char can be only one of the six following.
	FRIBIDI_MASK_LETTER    = 0x00000100, // Is letter: L, R, AL
	FRIBIDI_MASK_NUMBER    = 0x00000200, // Is number: EN, AN
	FRIBIDI_MASK_NUMSEPTER = 0x00000400, // Is separator or terminator: ES, ET, CS
	FRIBIDI_MASK_SPACE     = 0x00000800, // Is space: BN, BS, SS, WS
	FRIBIDI_MASK_EXPLICIT  = 0x00001000, // Is explicit mark: LRE, RLE, LRO, RLO, PDF
	FRIBIDI_MASK_ISOLATE   = 0x00008000, // Is isolate mark: LRI, RLI, FSI, PDI

	// Can be set only if FRIBIDI_MASK_SPACE is also set.
	FRIBIDI_MASK_SEPARATOR = 0x00002000, // Is text separator: BS, SS
	// Can be set only if FRIBIDI_MASK_EXPLICIT is also set.
	FRIBIDI_MASK_OVERRIDE  = 0x00004000, // Is explicit override: LRO, RLO
	FRIBIDI_MASK_FIRST     = 0x02000000, // Whether direction is determined by first strong

	// The following exist to make types pairwise different, some of them can
	// be removed but are here because of efficiency (make queries faster).

	FRIBIDI_MASK_ES =  0x00010000,
	FRIBIDI_MASK_ET =  0x00020000,
	FRIBIDI_MASK_CS =  0x00040000,

	FRIBIDI_MASK_NSM = 0x00080000,
	FRIBIDI_MASK_BN =  0x00100000,

	FRIBIDI_MASK_BS =  0x00200000,
	FRIBIDI_MASK_SS =  0x00400000,
	FRIBIDI_MASK_WS =  0x00800000,

	// We reserve a single bit for user's private use: we will never use it.
	FRIBIDI_MASK_PRIVATE = 0x01000000,

};

typedef enum {

	// Strong types

	// Left-To-Right letter
	FRIBIDI_TYPE_LTR_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_LETTER ),
	// Right-To-Left letter
	FRIBIDI_TYPE_RTL_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_LETTER \
	  | FRIBIDI_MASK_RTL),
	// Arabic Letter
	FRIBIDI_TYPE_AL_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_LETTER \
	  | FRIBIDI_MASK_RTL | FRIBIDI_MASK_ARABIC ),
	// Left-to-Right Embedding
	FRIBIDI_TYPE_LRE_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_EXPLICIT),
	// Right-to-Left Embedding
	FRIBIDI_TYPE_RLE_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_EXPLICIT \
	  | FRIBIDI_MASK_RTL ),
	// Left-to-Right Override
	FRIBIDI_TYPE_LRO_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_EXPLICIT \
	  | FRIBIDI_MASK_OVERRIDE ),
	// Right-to-Left Override
	FRIBIDI_TYPE_RLO_VAL = ( FRIBIDI_MASK_STRONG | FRIBIDI_MASK_EXPLICIT \
	  | FRIBIDI_MASK_RTL | FRIBIDI_MASK_OVERRIDE ),

	// Weak types

	// Pop Directional Flag
	FRIBIDI_TYPE_PDF_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_EXPLICIT ),
	// European Numeral
	FRIBIDI_TYPE_EN_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_NUMBER ),
	// Arabic Numeral
	FRIBIDI_TYPE_AN_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_NUMBER \
	  | FRIBIDI_MASK_ARABIC ),
	// European number Separator
	FRIBIDI_TYPE_ES_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_NUMSEPTER \
	  | FRIBIDI_MASK_ES ),
	// European number Terminator
	FRIBIDI_TYPE_ET_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_NUMSEPTER \
	  | FRIBIDI_MASK_ET ),
	// Common Separator
	FRIBIDI_TYPE_CS_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_NUMSEPTER \
	  | FRIBIDI_MASK_CS ),
	// Non Spacing Mark
	FRIBIDI_TYPE_NSM_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_NSM ),
	// Boundary Neutral
	FRIBIDI_TYPE_BN_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_SPACE \
	  | FRIBIDI_MASK_BN ),

	// Neutral types

	// Block Separator
	FRIBIDI_TYPE_BS_VAL = ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_SPACE \
	  | FRIBIDI_MASK_SEPARATOR | FRIBIDI_MASK_BS ),
	// Segment Separator
	FRIBIDI_TYPE_SS_VAL = ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_SPACE \
	  | FRIBIDI_MASK_SEPARATOR | FRIBIDI_MASK_SS ),
	// WhiteSpace
	FRIBIDI_TYPE_WS_VAL = ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_SPACE \
	  | FRIBIDI_MASK_WS ),
	// Other Neutral
	FRIBIDI_TYPE_ON_VAL = ( FRIBIDI_MASK_NEUTRAL ),

	// The following are used in specifying paragraph direction only.

	// Weak Left-To-Right
	FRIBIDI_TYPE_WLTR_VAL = ( FRIBIDI_MASK_WEAK ),
	// Weak Right-To-Left
	FRIBIDI_TYPE_WRTL_VAL = ( FRIBIDI_MASK_WEAK | FRIBIDI_MASK_RTL ),

	// Private types for applications.  More private types can be obtained by
	// summing up from this one.
	FRIBIDI_TYPE_PRIVATE = ( FRIBIDI_MASK_PRIVATE ),

	// New types in Unicode 6.3

	// Left-to-Right Isolate
	FRIBIDI_TYPE_LRI_VAL =    ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_ISOLATE ),
	// Right-to-Left Isolate
	FRIBIDI_TYPE_RLI_VAL =    ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_ISOLATE | FRIBIDI_MASK_RTL ),
	// First strong isolate
	FRIBIDI_TYPE_FSI_VAL =    ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_ISOLATE | FRIBIDI_MASK_FIRST ),

	// Pop Directional Isolate
	FRIBIDI_TYPE_PDI_VAL = ( FRIBIDI_MASK_NEUTRAL | FRIBIDI_MASK_WEAK | FRIBIDI_MASK_ISOLATE ),

} FriBidiCharType;

typedef enum {
	FRIBIDI_PAR_LTR  = FRIBIDI_TYPE_LTR_VAL,
	FRIBIDI_PAR_RTL  = FRIBIDI_TYPE_RTL_VAL,
	FRIBIDI_PAR_ON	  = FRIBIDI_TYPE_ON_VAL,
	FRIBIDI_PAR_WLTR = FRIBIDI_TYPE_WLTR_VAL,
	FRIBIDI_PAR_WRTL = FRIBIDI_TYPE_WRTL_VAL,
} FriBidiParType;

FriBidiCharType fribidi_get_bidi_type (FriBidiChar ch);

void fribidi_get_bidi_types (
	const FriBidiChar *str,
	const FriBidiStrIndex len,
	FriBidiCharType *btypes
);

const char *fribidi_get_bidi_type_name (
	FriBidiCharType t
);

// fribidi-bidi-types-list.h

enum {
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
	FRIBIDI_TYPE_LRI = ( 0x00000040 | 0x00008000 ),
	FRIBIDI_TYPE_RLI = ( 0x00000040 | 0x00008000 | 0x00000001 ),
	FRIBIDI_TYPE_FSI = ( 0x00000040 | 0x00008000 | 0x02000000 ),
	FRIBIDI_TYPE_PDI = ( 0x00000040 | 0x00000020 | 0x00008000 ),
};

// fribidi-bidi.h

FriBidiParType fribidi_get_par_direction (
	const FriBidiCharType *bidi_types,
	const FriBidiStrIndex len
);

FriBidiLevel fribidi_get_par_embedding_levels_ex (
	const FriBidiCharType *bidi_types,
	const FriBidiBracketType *bracket_types,
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

// fribidi-joining-types.h

enum {
	FRIBIDI_MASK_JOINS_RIGHT = 0x01,
	FRIBIDI_MASK_JOINS_LEFT = 0x02,
	FRIBIDI_MASK_ARAB_SHAPES = 0x04,
	FRIBIDI_MASK_TRANSPARENT = 0x08,
	FRIBIDI_MASK_IGNORED = 0x10,
	FRIBIDI_MASK_LIGATURED = 0x20,
};

enum _FriBidiJoiningTypeEnum {
	FRIBIDI_JOINING_TYPE_U_VAL = ( 0 ),
	FRIBIDI_JOINING_TYPE_R_VAL = ( FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_ARAB_SHAPES ),
	FRIBIDI_JOINING_TYPE_D_VAL = ( FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT | FRIBIDI_MASK_ARAB_SHAPES ),
	FRIBIDI_JOINING_TYPE_C_VAL = ( FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT ),
	FRIBIDI_JOINING_TYPE_L_VAL = ( FRIBIDI_MASK_JOINS_LEFT | FRIBIDI_MASK_ARAB_SHAPES ),
	FRIBIDI_JOINING_TYPE_T_VAL = ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_ARAB_SHAPES ),
	FRIBIDI_JOINING_TYPE_G_VAL = ( FRIBIDI_MASK_IGNORED ),
};

typedef uint8_t FriBidiJoiningType;
typedef uint8_t FriBidiArabicProp;

FriBidiJoiningType fribidi_get_joining_type (
	FriBidiChar ch
);

void fribidi_get_joining_types (
	const FriBidiChar *str,
	const FriBidiStrIndex len,
	FriBidiJoiningType *jtypes
);

const char *fribidi_get_joining_type_name (
	FriBidiJoiningType j
);

// fribidi-joining-types-list.h

enum {
	FRIBIDI_JOINING_TYPE_U = ( 0 ),
	FRIBIDI_JOINING_TYPE_R = ( 0x01 | 0x04 ),
	FRIBIDI_JOINING_TYPE_D = ( 0x01 | 0x02 | 0x04 ),
	FRIBIDI_JOINING_TYPE_C = ( 0x01 | 0x02 ),
	FRIBIDI_JOINING_TYPE_T = ( 0x08 | 0x04 ),
	FRIBIDI_JOINING_TYPE_L = ( 0x02 | 0x04 ),
	FRIBIDI_JOINING_TYPE_G = ( 0x10 ),
};

// fribidi-joining.h

void fribidi_join_arabic (
	const FriBidiCharType *bidi_types,
	const FriBidiStrIndex len,
	const FriBidiLevel *embedding_levels,
	FriBidiArabicProp *ar_props
);

// fribidi-mirroring.h

fribidi_boolean fribidi_get_mirror_char (
	FriBidiChar ch,
	FriBidiChar *mirrored_ch
);

void fribidi_shape_mirroring (
	const FriBidiLevel *embedding_levels,
	const FriBidiStrIndex len,
	FriBidiChar *str
);

// fribidi-brackets.h

FriBidiBracketType fribidi_get_bracket (
	FriBidiChar ch
);

void fribidi_get_bracket_types (
	const FriBidiChar *str,
	const FriBidiStrIndex len,
	const FriBidiCharType *types,
	FriBidiBracketType *btypes
);

enum {
	FRIBIDI_BRACKET_OPEN_MASK = 0x80000000,
	FRIBIDI_BRACKET_ID_MASK = 0x7fffffff,
};

// fribidi-arabic.h

void fribidi_shape_arabic (
	FriBidiFlags flags,
	const FriBidiLevel *embedding_levels,
	const FriBidiStrIndex len,
	FriBidiArabicProp *ar_props,
	FriBidiChar *str
);

// fribidi-shape.h

void fribidi_shape (
	FriBidiFlags flags,
	const FriBidiLevel *embedding_levels,
	const FriBidiStrIndex len,
	FriBidiArabicProp *ar_props,
	FriBidiChar *str
);

// fribidi-char-sets.h

typedef enum {
	_FRIBIDI_CHAR_SET_NOT_FOUND,
	FRIBIDI_CHAR_SET_UTF8,      // UTF-8 (Unicode)
	FRIBIDI_CHAR_SET_CAP_RTL,   // CapRTL (Test)
	FRIBIDI_CHAR_SET_ISO8859_6, // ISO8859-6 (Arabic)
	FRIBIDI_CHAR_SET_ISO8859_8, // ISO8859-8 (Hebrew)
	FRIBIDI_CHAR_SET_CP1255,    // CP1255 (MS Hebrew/Yiddish)
	FRIBIDI_CHAR_SET_CP1256,    // CP1256 (MS Arabic)
} FriBidiCharSet;

FriBidiStrIndex fribidi_charset_to_unicode (
	FriBidiCharSet char_set,
	const char *s,
	FriBidiStrIndex len,
	FriBidiChar *us
);

FriBidiStrIndex fribidi_unicode_to_charset (
	FriBidiCharSet char_set,
	const FriBidiChar *us,
	FriBidiStrIndex len,
	char *s
);

FriBidiCharSet fribidi_parse_charset (const char *s);
const char *fribidi_char_set_name (FriBidiCharSet char_set);
const char *fribidi_char_set_title (FriBidiCharSet char_set);
const char *fribidi_char_set_desc (FriBidiCharSet char_set);
]]

--[[
// fribidi-deprecated.h

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

FriBidiLevel fribidi_get_par_embedding_levels (
	const FriBidiCharType *bidi_types,
	const FriBidiStrIndex len,
	FriBidiParType *pbase_dir,
	FriBidiLevel *embedding_levels
);

enum {
	UNI_LRM              = FRIBIDI_CHAR_LRM,
	UNI_RLM              = FRIBIDI_CHAR_RLM,
	UNI_LRE              = FRIBIDI_CHAR_LRE,
	UNI_RLE              = FRIBIDI_CHAR_RLE,
	UNI_LRO              = FRIBIDI_CHAR_LRO,
	UNI_RLO              = FRIBIDI_CHAR_RLO,
	UNI_LS               = FRIBIDI_CHAR_LS,
	UNI_PS               = FRIBIDI_CHAR_PS,
	UNI_ZWNJ             = FRIBIDI_CHAR_ZWNJ,
	UNI_ZWJ              = FRIBIDI_CHAR_ZWJ,
	UNI_HEBREW_ALEF      = FRIBIDI_CHAR_HEBREW_ALEF,
	UNI_ARABIC_ALEF      = FRIBIDI_CHAR_ARABIC_ALEF,
	UNI_ARABIC_ZERO      = FRIBIDI_CHAR_ARABIC_ZERO,
	UNI_FARSI_ZERO       = FRIBIDI_CHAR_PERSIAN_ZERO,
	FRIBIDI_TYPE_WL      = FRIBIDI_PAR_WLTR,
	FRIBIDI_TYPE_WR      = FRIBIDI_PAR_WRTL,
	FRIBIDI_TYPE_L       = FRIBIDI_PAR_LTR,
	FRIBIDI_TYPE_R       = FRIBIDI_PAR_RTL,
	FRIBIDI_TYPE_N       = FRIBIDI_PAR_ON,
	FRIBIDI_TYPE_B       = FRIBIDI_TYPE_BS,
	FRIBIDI_TYPE_S       = FRIBIDI_TYPE_SS,
};

function FRIBIDI_LEVEL_IS_RTL(lev) ((lev) & 1)
function FRIBIDI_LEVEL_TO_DIR(lev) (FRIBIDI_LEVEL_IS_RTL (lev) ? FRIBIDI_TYPE_RTL : FRIBIDI_TYPE_LTR)
function FRIBIDI_DIR_TO_LEVEL(dir) ((FriBidiLevel) (FRIBIDI_IS_RTL (dir) ? 1 : 0))
function FRIBIDI_IS_RTL(p) ((p) & FRIBIDI_MASK_RTL)
function FRIBIDI_IS_ARABIC(p) ((p) & FRIBIDI_MASK_ARABIC)
function FRIBIDI_IS_STRONG(p) ((p) & FRIBIDI_MASK_STRONG)
function FRIBIDI_IS_WEAK(p) ((p) & FRIBIDI_MASK_WEAK)
function FRIBIDI_IS_NEUTRAL(p) ((p) & FRIBIDI_MASK_NEUTRAL)
function FRIBIDI_IS_SENTINEL(p) ((p) & FRIBIDI_MASK_SENTINEL)
function FRIBIDI_IS_LETTER(p) ((p) & FRIBIDI_MASK_LETTER)
function FRIBIDI_IS_NUMBER(p) ((p) & FRIBIDI_MASK_NUMBER)
function FRIBIDI_IS_NUMBER_SEPARATOR_OR_TERMINATOR(p) ((p) & FRIBIDI_MASK_NUMSEPTER)
function FRIBIDI_IS_SPACE(p) ((p) & FRIBIDI_MASK_SPACE)
function FRIBIDI_IS_EXPLICIT(p) ((p) & FRIBIDI_MASK_EXPLICIT)
function FRIBIDI_IS_ISOLATE(p) ((p) & FRIBIDI_MASK_ISOLATE)
function FRIBIDI_IS_SEPARATOR(p) ((p) & FRIBIDI_MASK_SEPARATOR)
function FRIBIDI_IS_OVERRIDE(p) ((p) & FRIBIDI_MASK_OVERRIDE)
function FRIBIDI_IS_LTR_LETTER(p) ((p) & (FRIBIDI_MASK_LETTER | FRIBIDI_MASK_RTL) == FRIBIDI_MASK_LETTER)
function FRIBIDI_IS_RTL_LETTER(p) ((p) & (FRIBIDI_MASK_LETTER | FRIBIDI_MASK_RTL) == (FRIBIDI_MASK_LETTER | FRIBIDI_MASK_RTL))
function FRIBIDI_IS_ES_OR_CS(p) ((p) & (FRIBIDI_MASK_ES | FRIBIDI_MASK_CS))
function FRIBIDI_IS_EXPLICIT_OR_BN(p) ((p) & (FRIBIDI_MASK_EXPLICIT | FRIBIDI_MASK_BN))
function FRIBIDI_IS_EXPLICIT_OR_BN_OR_NSM(p) ((p) & (FRIBIDI_MASK_EXPLICIT | FRIBIDI_MASK_BN | FRIBIDI_MASK_NSM))
function FRIBIDI_IS_EXPLICIT_OR_ISOLATE_OR_BN_OR_NSM(p) ((p) & (FRIBIDI_MASK_EXPLICIT | FRIBIDI_MASK_ISOLATE | FRIBIDI_MASK_BN | FRIBIDI_MASK_NSM))
function FRIBIDI_IS_EXPLICIT_OR_BN_OR_WS(p) ((p) & (FRIBIDI_MASK_EXPLICIT | FRIBIDI_MASK_BN | FRIBIDI_MASK_WS))
function FRIBIDI_IS_EXPLICIT_OR_SEPARATOR_OR_BN_OR_WS(p) ((p) & (FRIBIDI_MASK_EXPLICIT | FRIBIDI_MASK_SEPARATOR | FRIBIDI_MASK_BN | FRIBIDI_MASK_WS))
function FRIBIDI_IS_PRIVATE(p) ((p) & FRIBIDI_MASK_PRIVATE)
function FRIBIDI_CHANGE_NUMBER_TO_RTL(p) (FRIBIDI_IS_NUMBER(p) ? FRIBIDI_TYPE_RTL : (p))
function FRIBIDI_EXPLICIT_TO_OVERRIDE_DIR(p) (FRIBIDI_IS_OVERRIDE(p) ? FRIBIDI_LEVEL_TO_DIR(FRIBIDI_DIR_TO_LEVEL(p)) : FRIBIDI_TYPE_ON)
function FRIBIDI_WEAK_PARAGRAPH(p) (FRIBIDI_PAR_WLTR | ((p) & FRIBIDI_MASK_RTL))

function FRIBIDI_IS_JOINING_TYPE_U(p) ( 0 == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT ) ) )
function FRIBIDI_IS_JOINING_TYPE_R(p) ( FRIBIDI_MASK_JOINS_RIGHT == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT ) ) )
function FRIBIDI_IS_JOINING_TYPE_D(p) ( ( FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT | FRIBIDI_MASK_ARAB_SHAPES ) == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT | FRIBIDI_MASK_ARAB_SHAPES ) ) )
function FRIBIDI_IS_JOINING_TYPE_C(p) ( ( FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT ) == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT | FRIBIDI_MASK_ARAB_SHAPES ) ) )
function FRIBIDI_IS_JOINING_TYPE_L(p) ( FRIBIDI_MASK_JOINS_LEFT == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT ) ) )
function FRIBIDI_IS_JOINING_TYPE_T(p) ( FRIBIDI_MASK_TRANSPARENT == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED ) ) )
function FRIBIDI_IS_JOINING_TYPE_G(p) ( FRIBIDI_MASK_IGNORED == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED ) ) )
function FRIBIDI_IS_JOINING_TYPE_RC(p) ( FRIBIDI_MASK_JOINS_RIGHT == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_RIGHT ) ) )
function FRIBIDI_IS_JOINING_TYPE_LC(p) ( FRIBIDI_MASK_JOINS_LEFT == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_JOINS_LEFT ) ) )
function FRIBIDI_JOINS_RIGHT(p) ((p) & FRIBIDI_MASK_JOINS_RIGHT)
function FRIBIDI_JOINS_LEFT(p) ((p) & FRIBIDI_MASK_JOINS_LEFT)
function FRIBIDI_ARAB_SHAPES(p) ((p) & FRIBIDI_MASK_ARAB_SHAPES)
function FRIBIDI_IS_JOIN_SKIPPED(p) ((p) & (FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED))
function FRIBIDI_IS_JOIN_BASE_SHAPES(p) ( FRIBIDI_MASK_ARAB_SHAPES == ( (p) & ( FRIBIDI_MASK_TRANSPARENT | FRIBIDI_MASK_IGNORED | FRIBIDI_MASK_ARAB_SHAPES ) ) )
function FRIBIDI_JOINS_PRECEDING_MASK(level) (FRIBIDI_LEVEL_IS_RTL (level) ? FRIBIDI_MASK_JOINS_RIGHT : FRIBIDI_MASK_JOINS_LEFT)
function FRIBIDI_JOINS_FOLLOWING_MASK(level) (FRIBIDI_LEVEL_IS_RTL (level) ? FRIBIDI_MASK_JOINS_LEFT : FRIBIDI_MASK_JOINS_RIGHT)
function FRIBIDI_JOIN_SHAPE(p) ((p) & ( FRIBIDI_MASK_JOINS_RIGHT | FRIBIDI_MASK_JOINS_LEFT ))

function FRIBIDI_IS_BRACKET_OPEN(bt) ((bt & FRIBIDI_BRACKET_OPEN_MASK)>0)
function FRIBIDI_BRACKET_ID(bt) ((bt & FRIBIDI_BRACKET_ID_MASK))
]]
