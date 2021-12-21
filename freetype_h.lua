--freetype/*.h from freetype 2.9.1
require'ffi'.cdef[[

// config/ftconfig.h ---------------------------------------------------------

typedef signed short   FT_Int16;
typedef unsigned short FT_UInt16;
typedef signed int     FT_Int32;
typedef unsigned int   FT_UInt32;
typedef int            FT_Fast;
typedef unsigned int   FT_UFast;

// fttypes.h -----------------------------------------------------------------

typedef unsigned char  FT_Bool;
typedef signed short   FT_FWord;
typedef unsigned short FT_UFWord;
typedef signed char    FT_Char;
typedef unsigned char  FT_Byte;
typedef const FT_Byte* FT_Bytes;
typedef FT_UInt32      FT_Tag;
typedef char           FT_String;
typedef signed short   FT_Short;
typedef unsigned short FT_UShort;
typedef signed int     FT_Int;
typedef unsigned int   FT_UInt;
typedef signed long    FT_Long;
typedef unsigned long  FT_ULong;
typedef signed short   FT_F2Dot14;
typedef signed long    FT_F26Dot6;
typedef signed long    FT_Fixed;
typedef int            FT_Error;
typedef void*          FT_Pointer;
typedef size_t         FT_Offset;
typedef ptrdiff_t      FT_PtrDist;

typedef struct FT_UnitVector_ {
	FT_F2Dot14 x;
	FT_F2Dot14 y;
} FT_UnitVector;

typedef struct FT_Matrix_ {
	FT_Fixed xx, xy;
	FT_Fixed yx, yy;
} FT_Matrix;

typedef struct FT_Data_ {
	const FT_Byte* pointer;
	FT_Int length;
} FT_Data;

typedef void (*FT_Generic_Finalizer)( void* object );

typedef struct FT_Generic_ {
	void* data;
	FT_Generic_Finalizer finalizer;
} FT_Generic;

typedef struct FT_ListNodeRec_* FT_ListNode;
typedef struct FT_ListRec_* FT_List;

typedef struct FT_ListNodeRec_ {
	FT_ListNode prev;
	FT_ListNode next;
	void* data;
} FT_ListNodeRec;

typedef struct FT_ListRec_ {
	FT_ListNode head;
	FT_ListNode tail;
} FT_ListRec;

// ftsystem.h ----------------------------------------------------------------

typedef struct FT_MemoryRec_* FT_Memory;

typedef void* (*FT_Alloc_Func)   ( FT_Memory memory, long size );
typedef void  (*FT_Free_Func)    ( FT_Memory memory, void* block );
typedef void* (*FT_Realloc_Func) ( FT_Memory memory, long cur_size, long new_size, void* block );

struct FT_MemoryRec_ {
	void* user;
	FT_Alloc_Func alloc;
	FT_Free_Func free;
	FT_Realloc_Func realloc;
};

typedef struct FT_StreamRec_* FT_Stream;

typedef union FT_StreamDesc_ {
	long value;
	void* pointer;
} FT_StreamDesc;

typedef unsigned long (*FT_Stream_IoFunc)(
	FT_Stream stream,
	unsigned long offset,
	unsigned char* buffer,
	unsigned long count );

typedef void (*FT_Stream_CloseFunc)( FT_Stream stream );

typedef struct FT_StreamRec_ {
	unsigned char* base;
	unsigned long size;
	unsigned long pos;
	FT_StreamDesc descriptor;
	FT_StreamDesc pathname;
	FT_Stream_IoFunc read;
	FT_Stream_CloseFunc close;
	FT_Memory memory;
	unsigned char* cursor;
	unsigned char* limit;
} FT_StreamRec;

// ftimage.h -----------------------------------------------------------------

typedef signed long FT_Pos;

typedef struct FT_Vector_ {
	FT_Pos x;
	FT_Pos y;
} FT_Vector;

typedef struct FT_BBox_ {
	FT_Pos xMin, yMin;
	FT_Pos xMax, yMax;
} FT_BBox;

typedef enum FT_Pixel_Mode_ {
	FT_PIXEL_MODE_NONE = 0,
	FT_PIXEL_MODE_MONO,
	FT_PIXEL_MODE_GRAY,
	FT_PIXEL_MODE_GRAY2,
	FT_PIXEL_MODE_GRAY4,
	FT_PIXEL_MODE_LCD,
	FT_PIXEL_MODE_LCD_V,
	FT_PIXEL_MODE_BGRA,
} FT_Pixel_Mode;

typedef struct FT_Bitmap_ {
	unsigned int rows;
	unsigned int width;
	int pitch;
	unsigned char* buffer;
	unsigned short num_grays;
	unsigned char pixel_mode;
	unsigned char palette_mode;
	void* palette;
} FT_Bitmap;

typedef struct FT_Outline_ {
	short n_contours;
	short n_points;
	FT_Vector* points;
	char* tags;
	short* contours;
	int flags;
} FT_Outline;

enum {
	FT_OUTLINE_CONTOURS_MAX = 32767,
	FT_OUTLINE_POINTS_MAX = 32767,
	FT_OUTLINE_NONE      = 0x0,
	FT_OUTLINE_OWNER     = 0x1,
	FT_OUTLINE_EVEN_ODD_FILL = 0x2,
	FT_OUTLINE_REVERSE_FILL = 0x4,
	FT_OUTLINE_IGNORE_DROPOUTS = 0x8,
	FT_OUTLINE_SMART_DROPOUTS = 0x10,
	FT_OUTLINE_INCLUDE_STUBS = 0x20,
	FT_OUTLINE_HIGH_PRECISION = 0x100,
	FT_OUTLINE_SINGLE_PASS = 0x200,
};

enum {
	FT_CURVE_TAG_ON      = 1,
	FT_CURVE_TAG_CONIC   = 0,
	FT_CURVE_TAG_CUBIC   = 2,
	FT_CURVE_TAG_HAS_SCANMODE = 4,
	FT_CURVE_TAG_TOUCH_X = 8,
	FT_CURVE_TAG_TOUCH_Y = 16,
	FT_CURVE_TAG_TOUCH_BOTH = ( FT_CURVE_TAG_TOUCH_X | FT_CURVE_TAG_TOUCH_Y ),
};

typedef int (*FT_Outline_MoveToFunc) ( const FT_Vector* to, void* user );
typedef int (*FT_Outline_LineToFunc) ( const FT_Vector* to, void* user );
typedef int (*FT_Outline_ConicToFunc)( const FT_Vector* control, const FT_Vector* to, void* user );
typedef int (*FT_Outline_CubicToFunc)( const FT_Vector* control1, const FT_Vector* control2, const FT_Vector* to, void* user );

typedef struct FT_Outline_Funcs_ {
	FT_Outline_MoveToFunc move_to;
	FT_Outline_LineToFunc line_to;
	FT_Outline_ConicToFunc conic_to;
	FT_Outline_CubicToFunc cubic_to;
	int shift;
	FT_Pos delta;
} FT_Outline_Funcs;

typedef enum FT_Glyph_Format_ {
	 FT_GLYPH_FORMAT_NONE = ( ( (unsigned long)0 << 24 ) | ( (unsigned long)0 << 16 ) | ( (unsigned long)0 << 8 ) | (unsigned long)0 ),
	 FT_GLYPH_FORMAT_COMPOSITE = ( ( (unsigned long)'c' << 24 ) | ( (unsigned long)'o' << 16 ) | ( (unsigned long)'m' << 8 ) | (unsigned long)'p' ),
	 FT_GLYPH_FORMAT_BITMAP = ( ( (unsigned long)'b' << 24 ) | ( (unsigned long)'i' << 16 ) | ( (unsigned long)'t' << 8 ) | (unsigned long)'s' ),
	 FT_GLYPH_FORMAT_OUTLINE = ( ( (unsigned long)'o' << 24 ) | ( (unsigned long)'u' << 16 ) | ( (unsigned long)'t' << 8 ) | (unsigned long)'l' ),
	 FT_GLYPH_FORMAT_PLOTTER = ( ( (unsigned long)'p' << 24 ) | ( (unsigned long)'l' << 16 ) | ( (unsigned long)'o' << 8 ) | (unsigned long)'t' )
} FT_Glyph_Format;

typedef struct FT_RasterRec_* FT_Raster;

typedef struct FT_Span_ {
	short x;
	unsigned short len;
	unsigned char coverage;
} FT_Span;

typedef void (*FT_SpanFunc)( int y, int count, const FT_Span* spans, void* user );
typedef int  (*FT_Raster_BitTest_Func)( int y, int x, void* user );
typedef void (*FT_Raster_BitSet_Func)( int y, int x, void* user );

enum {
	FT_RASTER_FLAG_DEFAULT = 0x0,
	FT_RASTER_FLAG_AA    = 0x1,
	FT_RASTER_FLAG_DIRECT = 0x2,
	FT_RASTER_FLAG_CLIP  = 0x4,
};

typedef struct FT_Raster_Params_ {
	const FT_Bitmap* target;
	const void* source;
	int flags;
	FT_SpanFunc gray_spans;
	FT_SpanFunc black_spans;
	FT_Raster_BitTest_Func bit_test;
	FT_Raster_BitSet_Func bit_set;
	void* user;
	FT_BBox clip_box;
} FT_Raster_Params;

typedef int  (*FT_Raster_NewFunc)( void* memory, FT_Raster* raster );
typedef void (*FT_Raster_DoneFunc)( FT_Raster raster );

typedef void (*FT_Raster_ResetFunc)( FT_Raster raster,
	unsigned char* pool_base,
	unsigned long pool_size );

typedef int  (*FT_Raster_SetModeFunc)( FT_Raster raster,
	unsigned long mode,
	void* args );

typedef int (*FT_Raster_RenderFunc)( FT_Raster raster,
	const FT_Raster_Params* params );

typedef struct FT_Raster_Funcs_ {
	FT_Glyph_Format glyph_format;
	FT_Raster_NewFunc raster_new;
	FT_Raster_ResetFunc raster_reset;
	FT_Raster_SetModeFunc raster_set_mode;
	FT_Raster_RenderFunc raster_render;
	FT_Raster_DoneFunc raster_done;
} FT_Raster_Funcs;

// freetype.h ----------------------------------------------------------------

typedef struct FT_Glyph_Metrics_ {
	FT_Pos width;
	FT_Pos height;
	FT_Pos horiBearingX;
	FT_Pos horiBearingY;
	FT_Pos horiAdvance;
	FT_Pos vertBearingX;
	FT_Pos vertBearingY;
	FT_Pos vertAdvance;
} FT_Glyph_Metrics;

typedef struct FT_Bitmap_Size_ {
	FT_Short height;
	FT_Short width;
	FT_Pos size;
	FT_Pos x_ppem;
	FT_Pos y_ppem;
} FT_Bitmap_Size;

typedef struct FT_LibraryRec_ *FT_Library;
typedef struct FT_ModuleRec_* FT_Module;
typedef struct FT_DriverRec_* FT_Driver;
typedef struct FT_RendererRec_* FT_Renderer;
typedef struct FT_FaceRec_* FT_Face;
typedef struct FT_SizeRec_* FT_Size;
typedef struct FT_GlyphSlotRec_* FT_GlyphSlot;
typedef struct FT_CharMapRec_* FT_CharMap;

typedef enum FT_Encoding_ {
	FT_ENCODING_NONE = ( ( (FT_UInt32)(0) << 24 ) | ( (FT_UInt32)(0) << 16 ) | ( (FT_UInt32)(0) << 8 ) | (FT_UInt32)(0) ),
	FT_ENCODING_MS_SYMBOL = ( ( (FT_UInt32)('s') << 24 ) | ( (FT_UInt32)('y') << 16 ) | ( (FT_UInt32)('m') << 8 ) | (FT_UInt32)('b') ),
	FT_ENCODING_UNICODE = ( ( (FT_UInt32)('u') << 24 ) | ( (FT_UInt32)('n') << 16 ) | ( (FT_UInt32)('i') << 8 ) | (FT_UInt32)('c') ),
	FT_ENCODING_SJIS = ( ( (FT_UInt32)('s') << 24 ) | ( (FT_UInt32)('j') << 16 ) | ( (FT_UInt32)('i') << 8 ) | (FT_UInt32)('s') ),
	FT_ENCODING_PRC = ( ( (FT_UInt32)('g') << 24 ) | ( (FT_UInt32)('b') << 16 ) | ( (FT_UInt32)(' ') << 8 ) | (FT_UInt32)(' ') ),
	FT_ENCODING_BIG5 = ( ( (FT_UInt32)('b') << 24 ) | ( (FT_UInt32)('i') << 16 ) | ( (FT_UInt32)('g') << 8 ) | (FT_UInt32)('5') ),
	FT_ENCODING_WANSUNG = ( ( (FT_UInt32)('w') << 24 ) | ( (FT_UInt32)('a') << 16 ) | ( (FT_UInt32)('n') << 8 ) | (FT_UInt32)('s') ),
	FT_ENCODING_JOHAB = ( ( (FT_UInt32)('j') << 24 ) | ( (FT_UInt32)('o') << 16 ) | ( (FT_UInt32)('h') << 8 ) | (FT_UInt32)('a') ),
	FT_ENCODING_GB2312 = FT_ENCODING_PRC,
	FT_ENCODING_MS_SJIS = FT_ENCODING_SJIS,
	FT_ENCODING_MS_GB2312 = FT_ENCODING_PRC,
	FT_ENCODING_MS_BIG5 = FT_ENCODING_BIG5,
	FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
	FT_ENCODING_MS_JOHAB = FT_ENCODING_JOHAB,
	FT_ENCODING_ADOBE_STANDARD = ( ( (FT_UInt32)('A') << 24 ) | ( (FT_UInt32)('D') << 16 ) | ( (FT_UInt32)('O') << 8 ) | (FT_UInt32)('B') ),
	FT_ENCODING_ADOBE_EXPERT = ( ( (FT_UInt32)('A') << 24 ) | ( (FT_UInt32)('D') << 16 ) | ( (FT_UInt32)('B') << 8 ) | (FT_UInt32)('E') ),
	FT_ENCODING_ADOBE_CUSTOM = ( ( (FT_UInt32)('A') << 24 ) | ( (FT_UInt32)('D') << 16 ) | ( (FT_UInt32)('B') << 8 ) | (FT_UInt32)('C') ),
	FT_ENCODING_ADOBE_LATIN_1 = ( ( (FT_UInt32)('l') << 24 ) | ( (FT_UInt32)('a') << 16 ) | ( (FT_UInt32)('t') << 8 ) | (FT_UInt32)('1') ),
	FT_ENCODING_OLD_LATIN_2 = ( ( (FT_UInt32)('l') << 24 ) | ( (FT_UInt32)('a') << 16 ) | ( (FT_UInt32)('t') << 8 ) | (FT_UInt32)('2') ),
	FT_ENCODING_APPLE_ROMAN = ( ( (FT_UInt32)('a') << 24 ) | ( (FT_UInt32)('r') << 16 ) | ( (FT_UInt32)('m') << 8 ) | (FT_UInt32)('n') )
} FT_Encoding;

typedef struct FT_CharMapRec_ {
	FT_Face face;
	union {
		FT_Encoding encoding;
		char _encoding_str[4];
	};
	FT_UShort platform_id;
	FT_UShort encoding_id;
} FT_CharMapRec;

typedef struct FT_Face_InternalRec_* FT_Face_Internal;

typedef struct FT_FaceRec_ {
	FT_Long num_faces;
	FT_Long face_index;
	FT_Long face_flags;
	FT_Long style_flags;
	FT_Long num_glyphs;
	FT_String* family_name;
	FT_String* style_name;
	FT_Int num_fixed_sizes;
	FT_Bitmap_Size* available_sizes;
	FT_Int num_charmaps;
	FT_CharMap* charmaps;
	FT_Generic generic;
	FT_BBox bbox;
	FT_UShort units_per_EM;
	FT_Short ascender;
	FT_Short descender;
	FT_Short height;
	FT_Short max_advance_width;
	FT_Short max_advance_height;
	FT_Short underline_position;
	FT_Short underline_thickness;
	FT_GlyphSlot glyph;
	FT_Size size;
	FT_CharMap charmap;
	FT_Driver driver;
	FT_Memory memory;
	FT_Stream stream;
	FT_ListRec sizes_list;
	FT_Generic autohint;
	void* extensions;
	FT_Face_Internal internal;
} FT_FaceRec;

enum {
	FT_FACE_FLAG_SCALABLE         = ( 1 << 0 ),
	FT_FACE_FLAG_FIXED_SIZES      = ( 1 << 1 ),
	FT_FACE_FLAG_FIXED_WIDTH      = ( 1 << 2 ),
	FT_FACE_FLAG_SFNT             = ( 1 << 3 ),
	FT_FACE_FLAG_HORIZONTAL       = ( 1 << 4 ),
	FT_FACE_FLAG_VERTICAL         = ( 1 << 5 ),
	FT_FACE_FLAG_KERNING          = ( 1 << 6 ),
	FT_FACE_FLAG_FAST_GLYPHS      = ( 1 << 7 ),
	FT_FACE_FLAG_MULTIPLE_MASTERS = ( 1 << 8 ),
	FT_FACE_FLAG_GLYPH_NAMES      = ( 1 << 9 ),
	FT_FACE_FLAG_EXTERNAL_STREAM  = ( 1 << 10 ),
	FT_FACE_FLAG_HINTER           = ( 1 << 11 ),
	FT_FACE_FLAG_CID_KEYED        = ( 1 << 12 ),
	FT_FACE_FLAG_TRICKY           = ( 1 << 13 ),
	FT_FACE_FLAG_COLOR            = ( 1 << 14 ),
	FT_FACE_FLAG_VARIATION        = ( 1 << 15 ),
};

enum {
	FT_STYLE_FLAG_ITALIC = ( 1 << 0 ),
	FT_STYLE_FLAG_BOLD   = ( 1 << 1 ),
};

typedef struct FT_Size_InternalRec_* FT_Size_Internal;

typedef struct FT_Size_Metrics_ {
	FT_UShort x_ppem;
	FT_UShort y_ppem;
	FT_Fixed x_scale;
	FT_Fixed y_scale;
	FT_Pos ascender;
	FT_Pos descender;
	FT_Pos height;
	FT_Pos max_advance;
} FT_Size_Metrics;

typedef struct FT_SizeRec_ {
	FT_Face face;
	FT_Generic generic;
	FT_Size_Metrics metrics;
	FT_Size_Internal internal;
} FT_SizeRec;

typedef struct FT_SubGlyphRec_* FT_SubGlyph;
typedef struct FT_Slot_InternalRec_* FT_Slot_Internal;

typedef struct FT_GlyphSlotRec_ {
	FT_Library library;
	FT_Face face;
	FT_GlyphSlot next;
	FT_UInt reserved;
	FT_Generic generic;
	FT_Glyph_Metrics metrics;
	FT_Fixed linearHoriAdvance;
	FT_Fixed linearVertAdvance;
	FT_Vector advance;
	FT_Glyph_Format format;
	FT_Bitmap bitmap;
	FT_Int bitmap_left;
	FT_Int bitmap_top;
	FT_Outline outline;
	FT_UInt num_subglyphs;
	FT_SubGlyph subglyphs;
	void* control_data;
	long control_len;
	FT_Pos lsb_delta;
	FT_Pos rsb_delta;
	void* other;
	FT_Slot_Internal internal;
} FT_GlyphSlotRec;

FT_Error FT_Init_FreeType( FT_Library *alibrary );
FT_Error FT_Done_FreeType( FT_Library library );

enum {
	FT_OPEN_MEMORY       = 0x1,
	FT_OPEN_STREAM       = 0x2,
	FT_OPEN_PATHNAME     = 0x4,
	FT_OPEN_DRIVER       = 0x8,
	FT_OPEN_PARAMS       = 0x10,
};

typedef struct FT_Parameter_ {
	FT_ULong tag;
	FT_Pointer data;
} FT_Parameter;

typedef struct FT_Open_Args_ {
	FT_UInt flags;
	const FT_Byte* memory_base;
	FT_Long memory_size;
	FT_String* pathname;
	FT_Stream stream;
	FT_Module driver;
	FT_Int num_params;
	FT_Parameter* params;
} FT_Open_Args;

FT_Error
FT_New_Face(
	FT_Library library,
	const char* filepathname,
	FT_Long face_index,
	FT_Face *aface );

FT_Error
FT_New_Memory_Face(
	FT_Library library,
	const FT_Byte* file_base,
	FT_Long file_size,
	FT_Long face_index,
	FT_Face *aface );

FT_Error
FT_Open_Face(
	FT_Library library,
	const FT_Open_Args* args,
	FT_Long face_index,
	FT_Face *aface );

FT_Error FT_Attach_File   ( FT_Face face, const char* filepathname );
FT_Error FT_Attach_Stream ( FT_Face face, FT_Open_Args* parameters );

FT_Error FT_Reference_Face ( FT_Face face );
FT_Error FT_Done_Face      ( FT_Face face );

FT_Error FT_Select_Size    ( FT_Face face, FT_Int strike_index );

typedef enum FT_Size_Request_Type_ {
	FT_SIZE_REQUEST_TYPE_NOMINAL,
	FT_SIZE_REQUEST_TYPE_REAL_DIM,
	FT_SIZE_REQUEST_TYPE_BBOX,
	FT_SIZE_REQUEST_TYPE_CELL,
	FT_SIZE_REQUEST_TYPE_SCALES,
	FT_SIZE_REQUEST_TYPE_MAX
} FT_Size_Request_Type;

typedef struct FT_Size_RequestRec_ {
	FT_Size_Request_Type type;
	FT_Long width;
	FT_Long height;
	FT_UInt horiResolution;
	FT_UInt vertResolution;
} FT_Size_RequestRec;

typedef struct FT_Size_RequestRec_ *FT_Size_Request;

FT_Error
FT_Request_Size(
	FT_Face face,
	FT_Size_Request req );

FT_Error
FT_Set_Char_Size(
	FT_Face face,
	FT_F26Dot6 char_width,
	FT_F26Dot6 char_height,
	FT_UInt horz_resolution,
	FT_UInt vert_resolution );

FT_Error
FT_Set_Pixel_Sizes(
	FT_Face face,
	FT_UInt pixel_width,
	FT_UInt pixel_height );

FT_Error
FT_Load_Glyph(
	FT_Face face,
	FT_UInt glyph_index,
	FT_Int32 load_flags );

FT_Error
FT_Load_Char(
	FT_Face face,
	FT_ULong char_code,
	FT_Int32 load_flags );

enum {
	FT_LOAD_DEFAULT          = 0x0,
	FT_LOAD_NO_SCALE         = ( 1 << 0 ),
	FT_LOAD_NO_HINTING       = ( 1 << 1 ),
	FT_LOAD_RENDER           = ( 1 << 2 ),
	FT_LOAD_NO_BITMAP        = ( 1 << 3 ),
	FT_LOAD_VERTICAL_LAYOUT  = ( 1 << 4 ),
	FT_LOAD_FORCE_AUTOHINT   = ( 1 << 5 ),
	FT_LOAD_CROP_BITMAP      = ( 1 << 6 ), // ignored, deprecated
	FT_LOAD_PEDANTIC         = ( 1 << 7 ),
	FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH = ( 1 << 9 ),  // ignored, deprecated
	FT_LOAD_NO_RECURSE       = ( 1 << 10 ),
	FT_LOAD_IGNORE_TRANSFORM = ( 1 << 11 ),
	FT_LOAD_MONOCHROME       = ( 1 << 12 ),
	FT_LOAD_LINEAR_DESIGN    = ( 1 << 13 ),
	FT_LOAD_NO_AUTOHINT      = ( 1 << 15 ),
	FT_LOAD_COLOR            = ( 1 << 20 ),
	FT_LOAD_COMPUTE_METRICS  = ( 1 << 21 ),
	FT_LOAD_BITMAP_METRICS_ONLY = ( 1 << 22 ),
	FT_LOAD_ADVANCE_ONLY     = ( 1 << 8 ),
	FT_LOAD_SBITS_ONLY       = ( 1 << 14 ),
};

typedef enum FT_Render_Mode_ {
	FT_RENDER_MODE_NORMAL = 0,
	FT_RENDER_MODE_LIGHT,
	FT_RENDER_MODE_MONO,
	FT_RENDER_MODE_LCD,
	FT_RENDER_MODE_LCD_V,
	FT_RENDER_MODE_MAX
} FT_Render_Mode;

enum {
	FT_LOAD_TARGET_NORMAL = (FT_RENDER_MODE_NORMAL & 15) << 16,
	FT_LOAD_TARGET_LIGHT  = (FT_RENDER_MODE_LIGHT & 15) << 16,
	FT_LOAD_TARGET_MONO   = (FT_RENDER_MODE_MONO & 15) << 16,
	FT_LOAD_TARGET_LCD    = (FT_RENDER_MODE_LCD & 15) << 16,
	FT_LOAD_TARGET_LCD_V  = (FT_RENDER_MODE_LCD_V & 15) << 16
};

void FT_Set_Transform( FT_Face face, FT_Matrix* matrix, FT_Vector* delta );

FT_Error FT_Render_Glyph( FT_GlyphSlot slot, FT_Render_Mode render_mode );

typedef enum FT_Kerning_Mode_ {
	FT_KERNING_DEFAULT = 0,
	FT_KERNING_UNFITTED,
	FT_KERNING_UNSCALED
} FT_Kerning_Mode;

FT_Error
FT_Get_Kerning(
	FT_Face face,
	FT_UInt left_glyph,
	FT_UInt right_glyph,
	FT_UInt kern_mode,
	FT_Vector *akerning );

FT_Error
FT_Get_Track_Kerning(
	FT_Face face,
	FT_Fixed point_size,
	FT_Int degree,
	FT_Fixed* akerning );

FT_Error
FT_Get_Glyph_Name(
	FT_Face face,
	FT_UInt glyph_index,
	FT_Pointer buffer,
	FT_UInt buffer_max );

const char* FT_Get_Postscript_Name( FT_Face face );

FT_Error FT_Select_Charmap( FT_Face face, FT_Encoding encoding );
FT_Error FT_Set_Charmap( FT_Face face, FT_CharMap charmap );
FT_Int   FT_Get_Charmap_Index( FT_CharMap charmap );
FT_UInt  FT_Get_Char_Index( FT_Face face, FT_ULong charcode );
FT_ULong FT_Get_First_Char( FT_Face face, FT_UInt *agindex );
FT_ULong FT_Get_Next_Char( FT_Face face, FT_ULong char_code, FT_UInt *agindex );

FT_Error FT_Face_Properties( FT_Face face, FT_UInt num_properties, FT_Parameter* properties );
FT_UInt  FT_Get_Name_Index( FT_Face face, FT_String* glyph_name );

enum {
	FT_SUBGLYPH_FLAG_ARGS_ARE_WORDS = 1,
	FT_SUBGLYPH_FLAG_ARGS_ARE_XY_VALUES = 2,
	FT_SUBGLYPH_FLAG_ROUND_XY_TO_GRID = 4,
	FT_SUBGLYPH_FLAG_SCALE = 8,
	FT_SUBGLYPH_FLAG_XY_SCALE = 0x40,
	FT_SUBGLYPH_FLAG_2X2 = 0x80,
	FT_SUBGLYPH_FLAG_USE_MY_METRICS = 0x200,
};

FT_Error
FT_Get_SubGlyph_Info( FT_GlyphSlot glyph,
	FT_UInt sub_index,
	FT_Int *p_index,
	FT_UInt *p_flags,
	FT_Int *p_arg1,
	FT_Int *p_arg2,
	FT_Matrix *p_transform );

enum {
	FT_FSTYPE_INSTALLABLE_EMBEDDING = 0x0000,
	FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING = 0x0002,
	FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING = 0x0004,
	FT_FSTYPE_EDITABLE_EMBEDDING = 0x0008,
	FT_FSTYPE_NO_SUBSETTING = 0x0100,
	FT_FSTYPE_BITMAP_EMBEDDING_ONLY = 0x0200,
};

FT_UShort  FT_Get_FSType_Flags ( FT_Face face );

FT_UInt    FT_Face_GetCharVariantIndex     ( FT_Face face, FT_ULong charcode, FT_ULong variantSelector );
FT_Int     FT_Face_GetCharVariantIsDefault ( FT_Face face, FT_ULong charcode, FT_ULong variantSelector );
FT_UInt32* FT_Face_GetVariantSelectors     ( FT_Face face );
FT_UInt32* FT_Face_GetVariantsOfChar       ( FT_Face face, FT_ULong charcode );
FT_UInt32* FT_Face_GetCharsOfVariant       ( FT_Face face, FT_ULong variantSelector );

FT_Long  FT_MulDiv( FT_Long a, FT_Long b, FT_Long c );
FT_Long  FT_MulFix( FT_Long a, FT_Long b );
FT_Long  FT_DivFix( FT_Long a, FT_Long b );
FT_Fixed FT_RoundFix( FT_Fixed a );
FT_Fixed FT_CeilFix( FT_Fixed a );
FT_Fixed FT_FloorFix( FT_Fixed a );

void FT_Vector_Transform( FT_Vector* vec, const FT_Matrix* matrix );

void FT_Library_Version( FT_Library library,
	FT_Int *amajor,
	FT_Int *aminor,
	FT_Int *apatch );

FT_Bool FT_Face_CheckTrueTypePatents( FT_Face face );
FT_Bool FT_Face_SetUnpatentedHinting( FT_Face face, FT_Bool value );

// ftbitmap.h ----------------------------------------------------------------

void     FT_Bitmap_Init     (FT_Bitmap *abitmap);
void     FT_Bitmap_New      (FT_Bitmap *abitmap);
FT_Error FT_Bitmap_Copy     (FT_Library library, const FT_Bitmap *source, FT_Bitmap *target);
FT_Error FT_Bitmap_Embolden (FT_Library library, FT_Bitmap* bitmap, FT_Pos xStrength, FT_Pos yStrength);
FT_Error FT_Bitmap_Convert  (FT_Library library, const FT_Bitmap *source, FT_Bitmap *target, FT_Int alignment);
FT_Error FT_GlyphSlot_Own_Bitmap (FT_GlyphSlot slot);
FT_Error FT_Bitmap_Done     (FT_Library library, FT_Bitmap *bitmap);

// ftglyph.h -----------------------------------------------------------------

typedef struct FT_Glyph_Class_ FT_Glyph_Class;
typedef struct FT_GlyphRec_* FT_Glyph;
typedef struct FT_GlyphRec_ {
	FT_Library library;
	const FT_Glyph_Class* clazz;
	FT_Glyph_Format format;
	FT_Vector advance;
} FT_GlyphRec;

typedef struct FT_BitmapGlyphRec_* FT_BitmapGlyph;
typedef struct FT_BitmapGlyphRec_ {
	FT_GlyphRec root;
	FT_Int left;
	FT_Int top;
	FT_Bitmap bitmap;
} FT_BitmapGlyphRec;

typedef struct FT_OutlineGlyphRec_* FT_OutlineGlyph;
typedef struct FT_OutlineGlyphRec_ {
	FT_GlyphRec root;
	FT_Outline outline;
} FT_OutlineGlyphRec;

FT_Error FT_Get_Glyph       ( FT_GlyphSlot slot, FT_Glyph *aglyph );
FT_Error FT_Glyph_Copy      ( FT_Glyph source, FT_Glyph *target );
FT_Error FT_Glyph_Transform ( FT_Glyph glyph, FT_Matrix* matrix, FT_Vector* delta );

typedef enum FT_Glyph_BBox_Mode_ {
	FT_GLYPH_BBOX_UNSCALED = 0,
	FT_GLYPH_BBOX_SUBPIXELS = 0,
	FT_GLYPH_BBOX_GRIDFIT = 1,
	FT_GLYPH_BBOX_TRUNCATE = 2,
	FT_GLYPH_BBOX_PIXELS = 3
} FT_Glyph_BBox_Mode;

void     FT_Glyph_Get_CBox  ( FT_Glyph glyph, FT_UInt bbox_mode, FT_BBox *acbox );
FT_Error FT_Glyph_To_Bitmap ( FT_Glyph* the_glyph, FT_Render_Mode render_mode, FT_Vector* origin, FT_Bool destroy );
void     FT_Done_Glyph      ( FT_Glyph glyph );

void     FT_Matrix_Multiply ( const FT_Matrix* a, FT_Matrix* b );
FT_Error FT_Matrix_Invert   ( FT_Matrix* matrix );

// ftoutln.h -----------------------------------------------------------------

FT_Error FT_Outline_Decompose     ( FT_Outline* outline, const FT_Outline_Funcs* func_interface, void* user );
FT_Error FT_Outline_New           ( FT_Library library, FT_UInt numPoints, FT_Int numContours, FT_Outline *anoutline );
FT_Error FT_Outline_New_Internal  ( FT_Memory memory, FT_UInt numPoints, FT_Int numContours, FT_Outline *anoutline );
FT_Error FT_Outline_Done          ( FT_Library library, FT_Outline* outline );
FT_Error FT_Outline_Done_Internal ( FT_Memory memory, FT_Outline* outline );
FT_Error FT_Outline_Check         ( FT_Outline* outline );
void     FT_Outline_Get_CBox      ( const FT_Outline* outline, FT_BBox *acbox );
void     FT_Outline_Translate     ( const FT_Outline* outline, FT_Pos xOffset, FT_Pos yOffset );
FT_Error FT_Outline_Copy          ( const FT_Outline* source, FT_Outline *target );
void     FT_Outline_Transform     ( const FT_Outline* outline, const FT_Matrix* matrix );
FT_Error FT_Outline_Embolden      ( FT_Outline* outline, FT_Pos strength );
FT_Error FT_Outline_EmboldenXY    ( FT_Outline* outline, FT_Pos xstrength, FT_Pos ystrength );
void     FT_Outline_Reverse       ( FT_Outline* outline );
FT_Error FT_Outline_Get_Bitmap    ( FT_Library library, FT_Outline* outline, const FT_Bitmap *abitmap );
FT_Error FT_Outline_Render        ( FT_Library library, FT_Outline* outline, FT_Raster_Params* params );

typedef enum FT_Orientation_ {
	FT_ORIENTATION_TRUETYPE = 0,
	FT_ORIENTATION_POSTSCRIPT = 1,
	FT_ORIENTATION_FILL_RIGHT = FT_ORIENTATION_TRUETYPE,
	FT_ORIENTATION_FILL_LEFT = FT_ORIENTATION_POSTSCRIPT,
	FT_ORIENTATION_NONE
} FT_Orientation;

FT_Orientation FT_Outline_Get_Orientation( FT_Outline* outline );

// ftmodapi.h ----------------------------------------------------------------

enum {
	FT_MODULE_FONT_DRIVER = 1,
	FT_MODULE_RENDERER   = 2,
	FT_MODULE_HINTER     = 4,
	FT_MODULE_STYLER     = 8,
	FT_MODULE_DRIVER_SCALABLE = 0x100,
	FT_MODULE_DRIVER_NO_OUTLINES = 0x200,
	FT_MODULE_DRIVER_HAS_HINTER = 0x400,
	FT_MODULE_DRIVER_HINTS_LIGHTLY = 0x800,
};
typedef FT_Pointer FT_Module_Interface;
typedef FT_Error (*FT_Module_Constructor)( FT_Module module );
typedef void     (*FT_Module_Destructor)( FT_Module module );
typedef FT_Module_Interface(*FT_Module_Requester)(
	FT_Module module,
	const char* name );

typedef struct FT_Module_Class_ {
	FT_ULong module_flags;
	FT_Long module_size;
	const FT_String* module_name;
	FT_Fixed module_version;
	FT_Fixed module_requires;
	const void* module_interface;
	FT_Module_Constructor module_init;
	FT_Module_Destructor module_done;
	FT_Module_Requester get_interface;
} FT_Module_Class;

FT_Error  FT_Add_Module   ( FT_Library library, const FT_Module_Class* clazz );
FT_Module FT_Get_Module   ( FT_Library library, const char* module_name );
FT_Error  FT_Remove_Module( FT_Library library, FT_Module module );

FT_Error FT_Property_Set(
	FT_Library library,
	const FT_String* module_name,
	const FT_String* property_name,
	const void* value );

FT_Error FT_Property_Get(
	FT_Library library,
	const FT_String* module_name,
	const FT_String* property_name,
	void* value );

void FT_Set_Default_Properties( FT_Library library );

FT_Error FT_Reference_Library ( FT_Library library );
FT_Error FT_New_Library       ( FT_Memory memory, FT_Library *alibrary );
FT_Error FT_Done_Library      ( FT_Library library );

typedef void (*FT_DebugHook_Func)( void* arg );

void FT_Set_Debug_Hook(
	FT_Library library,
	FT_UInt hook_index,
	FT_DebugHook_Func debug_hook );

void FT_Add_Default_Modules(
	FT_Library library );

typedef enum FT_TrueTypeEngineType_ {
	FT_TRUETYPE_ENGINE_TYPE_NONE = 0,
	FT_TRUETYPE_ENGINE_TYPE_UNPATENTED,
	FT_TRUETYPE_ENGINE_TYPE_PATENTED
} FT_TrueTypeEngineType;

FT_TrueTypeEngineType FT_Get_TrueType_Engine_Type(
	FT_Library library );

// ftcache.h -----------------------------------------------------------------

typedef FT_Pointer FTC_FaceID;

typedef FT_Error (*FTC_Face_Requester)(
	FTC_FaceID face_id,
	FT_Library library,
	FT_Pointer req_data,
	FT_Face* aface );

typedef struct FTC_ManagerRec_* FTC_Manager;
typedef struct FTC_NodeRec_* FTC_Node;

FT_Error FTC_Manager_New(
	FT_Library library,
	FT_UInt max_faces,
	FT_UInt max_sizes,
	FT_ULong max_bytes,
	FTC_Face_Requester requester,
	FT_Pointer req_data,
	FTC_Manager *amanager );

void FTC_Manager_Reset( FTC_Manager manager );
void FTC_Manager_Done( FTC_Manager manager );

FT_Error FTC_Manager_LookupFace(
	FTC_Manager manager,
	FTC_FaceID face_id,
	FT_Face *aface );

typedef struct FTC_ScalerRec_ {
	FTC_FaceID face_id;
	FT_UInt width;
	FT_UInt height;
	FT_Int pixel;
	FT_UInt x_res;
	FT_UInt y_res;
} FTC_ScalerRec;

typedef struct FTC_ScalerRec_* FTC_Scaler;

FT_Error FTC_Manager_LookupSize(
	FTC_Manager manager,
	FTC_Scaler scaler,
	FT_Size *asize );

void FTC_Node_Unref(
	FTC_Node node,
	FTC_Manager manager );

void FTC_Manager_RemoveFaceID(
	FTC_Manager manager,
	FTC_FaceID face_id );

typedef struct FTC_CMapCacheRec_* FTC_CMapCache;

FT_Error FTC_CMapCache_New(
	FTC_Manager manager,
	FTC_CMapCache *acache );

FT_UInt FTC_CMapCache_Lookup(
	FTC_CMapCache cache,
	FTC_FaceID face_id,
	FT_Int cmap_index,
	FT_UInt32 char_code );

typedef struct FTC_ImageTypeRec_ {
	FTC_FaceID face_id;
	FT_UInt width;
	FT_UInt height;
	FT_Int32 flags;
} FTC_ImageTypeRec;

typedef struct FTC_ImageTypeRec_* FTC_ImageType;

typedef struct FTC_ImageCacheRec_* FTC_ImageCache;

FT_Error FTC_ImageCache_New(
	FTC_Manager manager,
	FTC_ImageCache *acache );

FT_Error FTC_ImageCache_Lookup(
	FTC_ImageCache cache,
	FTC_ImageType type,
	FT_UInt gindex,
	FT_Glyph *aglyph,
	FTC_Node *anode );

FT_Error FTC_ImageCache_LookupScaler(
	FTC_ImageCache cache,
	FTC_Scaler scaler,
	FT_ULong load_flags,
	FT_UInt gindex,
	FT_Glyph *aglyph,
	FTC_Node *anode );

typedef struct FTC_SBitRec_* FTC_SBit;
typedef struct FTC_SBitRec_ {
	FT_Byte width;
	FT_Byte height;
	FT_Char left;
	FT_Char top;
	FT_Byte format;
	FT_Byte max_grays;
	FT_Short pitch;
	FT_Char xadvance;
	FT_Char yadvance;
	FT_Byte* buffer;
} FTC_SBitRec;

typedef struct FTC_SBitCacheRec_* FTC_SBitCache;

FT_Error FTC_SBitCache_New(
	FTC_Manager manager,
	FTC_SBitCache *acache );

FT_Error FTC_SBitCache_Lookup(
	FTC_SBitCache cache,
	FTC_ImageType type,
	FT_UInt gindex,
	FTC_SBit *sbit,
	FTC_Node *anode );

FT_Error FTC_SBitCache_LookupScaler(
	FTC_SBitCache cache,
	FTC_Scaler scaler,
	FT_ULong load_flags,
	FT_UInt gindex,
	FTC_SBit *sbit,
	FTC_Node *anode );

// ftstroke.h ----------------------------------------------------------------

typedef struct FT_StrokerRec_* FT_Stroker;
typedef enum FT_Stroker_LineJoin_ {
	FT_STROKER_LINEJOIN_ROUND = 0,
	FT_STROKER_LINEJOIN_BEVEL = 1,
	FT_STROKER_LINEJOIN_MITER_VARIABLE = 2,
	FT_STROKER_LINEJOIN_MITER = FT_STROKER_LINEJOIN_MITER_VARIABLE,
	FT_STROKER_LINEJOIN_MITER_FIXED = 3
} FT_Stroker_LineJoin;

typedef enum FT_Stroker_LineCap_ {
	FT_STROKER_LINECAP_BUTT = 0,
	FT_STROKER_LINECAP_ROUND,
	FT_STROKER_LINECAP_SQUARE
} FT_Stroker_LineCap;

typedef enum FT_StrokerBorder_ {
	FT_STROKER_BORDER_LEFT = 0,
	FT_STROKER_BORDER_RIGHT
} FT_StrokerBorder;

FT_StrokerBorder FT_Outline_GetInsideBorder(
	FT_Outline* outline );

FT_StrokerBorder FT_Outline_GetOutsideBorder(
	FT_Outline* outline );

FT_Error FT_Stroker_New(
	FT_Library library,
	FT_Stroker *astroker );

void FT_Stroker_Set(
	FT_Stroker stroker,
	FT_Fixed radius,
	FT_Stroker_LineCap line_cap,
	FT_Stroker_LineJoin line_join,
	FT_Fixed miter_limit );

void FT_Stroker_Rewind(
	FT_Stroker stroker );

FT_Error FT_Stroker_ParseOutline(
	FT_Stroker stroker,
	FT_Outline* outline,
	FT_Bool opened );

FT_Error FT_Stroker_BeginSubPath(
	FT_Stroker stroker,
	FT_Vector* to,
	FT_Bool open );

FT_Error FT_Stroker_EndSubPath(
	FT_Stroker stroker );

FT_Error FT_Stroker_LineTo(
	FT_Stroker stroker,
	FT_Vector* to );

FT_Error FT_Stroker_ConicTo(
	FT_Stroker stroker,
	FT_Vector* control,
	FT_Vector* to );

FT_Error FT_Stroker_CubicTo(
	FT_Stroker stroker,
	FT_Vector* control1,
	FT_Vector* control2,
	FT_Vector* to );

FT_Error FT_Stroker_GetBorderCounts(
	FT_Stroker stroker,
	FT_StrokerBorder border,
	FT_UInt *anum_points,
	FT_UInt *anum_contours );

void FT_Stroker_ExportBorder(
	FT_Stroker stroker,
	FT_StrokerBorder border,
	FT_Outline* outline );

FT_Error FT_Stroker_GetCounts(
	FT_Stroker stroker,
	FT_UInt *anum_points,
	FT_UInt *anum_contours );

void FT_Stroker_Export(
	FT_Stroker stroker,
	FT_Outline* outline );

void FT_Stroker_Done( FT_Stroker stroker );

FT_Error FT_Glyph_Stroke(
	FT_Glyph *pglyph,
	FT_Stroker stroker,
	FT_Bool destroy );

FT_Error FT_Glyph_StrokeBorder(
	FT_Glyph *pglyph,
	FT_Stroker stroker,
	FT_Bool inside,
	FT_Bool destroy );
]]
