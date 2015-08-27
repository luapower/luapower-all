--return of `cpp hpdf.h` from libharu 2.3.0-RC2
local ffi = require'ffi'

ffi.cdef[[
typedef signed int HPDF_INT;
typedef unsigned int HPDF_UINT;
typedef signed int HPDF_INT32;
typedef unsigned int HPDF_UINT32;
typedef signed short HPDF_INT16;
typedef unsigned short HPDF_UINT16;
typedef signed char HPDF_INT8;
typedef unsigned char HPDF_UINT8;
typedef unsigned char HPDF_BYTE;
typedef float HPDF_REAL;
typedef double HPDF_DOUBLE;
typedef signed int HPDF_BOOL;
typedef unsigned long HPDF_STATUS;
typedef HPDF_UINT16 HPDF_CID;
typedef HPDF_UINT16 HPDF_UNICODE;
typedef struct _HPDF_Point {
    HPDF_REAL x;
    HPDF_REAL y;
} HPDF_Point;
typedef struct _HPDF_Rect {
    HPDF_REAL left;
    HPDF_REAL bottom;
    HPDF_REAL right;
    HPDF_REAL top;
} HPDF_Rect;
typedef struct _HPDF_Point3D {
 HPDF_REAL x;
 HPDF_REAL y;
 HPDF_REAL z;
} HPDF_Point3D;
typedef struct _HPDF_Rect HPDF_Box;
typedef struct _HPDF_Date {
    HPDF_INT year;
    HPDF_INT month;
    HPDF_INT day;
    HPDF_INT hour;
    HPDF_INT minutes;
    HPDF_INT seconds;
    char ind;
    HPDF_INT off_hour;
    HPDF_INT off_minutes;
} HPDF_Date;
typedef enum _HPDF_InfoType {
    HPDF_INFO_CREATION_DATE = 0,
    HPDF_INFO_MOD_DATE,
    HPDF_INFO_AUTHOR,
    HPDF_INFO_CREATOR,
    HPDF_INFO_PRODUCER,
    HPDF_INFO_TITLE,
    HPDF_INFO_SUBJECT,
    HPDF_INFO_KEYWORDS,
    HPDF_INFO_TRAPPED,
    HPDF_INFO_GTS_PDFX,
    HPDF_INFO_EOF
} HPDF_InfoType;
typedef enum _HPDF_PDFA_TYPE
{
    HPDF_PDFA_1A = 0,
    HPDF_PDFA_1B = 1
} HPDF_PDFAType;
typedef enum _HPDF_PdfVer {
    HPDF_VER_12 = 0,
    HPDF_VER_13,
    HPDF_VER_14,
    HPDF_VER_15,
    HPDF_VER_16,
    HPDF_VER_17,
    HPDF_VER_EOF
} HPDF_PDFVer;
typedef enum _HPDF_EncryptMode {
    HPDF_ENCRYPT_R2 = 2,
    HPDF_ENCRYPT_R3 = 3
} HPDF_EncryptMode;
typedef void
( *HPDF_Error_Handler) (HPDF_STATUS error_no,
                                     HPDF_STATUS detail_no,
                                     void *user_data);
typedef void*
( *HPDF_Alloc_Func) (HPDF_UINT size);
typedef void
( *HPDF_Free_Func) (void *aptr);
typedef struct _HPDF_TextWidth {
    HPDF_UINT numchars;
    HPDF_UINT numwords;
    HPDF_UINT width;
    HPDF_UINT numspace;
} HPDF_TextWidth;
typedef struct _HPDF_DashMode {
    HPDF_UINT16 ptn[8];
    HPDF_UINT num_ptn;
    HPDF_UINT phase;
} HPDF_DashMode;
typedef struct _HPDF_TransMatrix {
    HPDF_REAL a;
    HPDF_REAL b;
    HPDF_REAL c;
    HPDF_REAL d;
    HPDF_REAL x;
    HPDF_REAL y;
} HPDF_TransMatrix;
typedef enum _HPDF_ColorSpace {
    HPDF_CS_DEVICE_GRAY = 0,
    HPDF_CS_DEVICE_RGB,
    HPDF_CS_DEVICE_CMYK,
    HPDF_CS_CAL_GRAY,
    HPDF_CS_CAL_RGB,
    HPDF_CS_LAB,
    HPDF_CS_ICC_BASED,
    HPDF_CS_SEPARATION,
    HPDF_CS_DEVICE_N,
    HPDF_CS_INDEXED,
    HPDF_CS_PATTERN,
    HPDF_CS_EOF
} HPDF_ColorSpace;
typedef struct _HPDF_RGBColor {
    HPDF_REAL r;
    HPDF_REAL g;
    HPDF_REAL b;
} HPDF_RGBColor;
typedef struct _HPDF_CMYKColor {
    HPDF_REAL c;
    HPDF_REAL m;
    HPDF_REAL y;
    HPDF_REAL k;
} HPDF_CMYKColor;
typedef enum _HPDF_LineCap {
    HPDF_BUTT_END = 0,
    HPDF_ROUND_END,
    HPDF_PROJECTING_SCUARE_END,
    HPDF_LINECAP_EOF
} HPDF_LineCap;
typedef enum _HPDF_LineJoin {
    HPDF_MITER_JOIN = 0,
    HPDF_ROUND_JOIN,
    HPDF_BEVEL_JOIN,
    HPDF_LINEJOIN_EOF
} HPDF_LineJoin;
typedef enum _HPDF_TextRenderingMode {
    HPDF_FILL = 0,
    HPDF_STROKE,
    HPDF_FILL_THEN_STROKE,
    HPDF_INVISIBLE,
    HPDF_FILL_CLIPPING,
    HPDF_STROKE_CLIPPING,
    HPDF_FILL_STROKE_CLIPPING,
    HPDF_CLIPPING,
    HPDF_RENDERING_MODE_EOF
} HPDF_TextRenderingMode;
typedef enum _HPDF_WritingMode {
    HPDF_WMODE_HORIZONTAL = 0,
    HPDF_WMODE_VERTICAL,
    HPDF_WMODE_EOF
} HPDF_WritingMode;
typedef enum _HPDF_PageLayout {
    HPDF_PAGE_LAYOUT_SINGLE = 0,
    HPDF_PAGE_LAYOUT_ONE_COLUMN,
    HPDF_PAGE_LAYOUT_TWO_COLUMN_LEFT,
    HPDF_PAGE_LAYOUT_TWO_COLUMN_RIGHT,
    HPDF_PAGE_LAYOUT_TWO_PAGE_LEFT,
    HPDF_PAGE_LAYOUT_TWO_PAGE_RIGHT,
    HPDF_PAGE_LAYOUT_EOF
} HPDF_PageLayout;
typedef enum _HPDF_PageMode {
    HPDF_PAGE_MODE_USE_NONE = 0,
    HPDF_PAGE_MODE_USE_OUTLINE,
    HPDF_PAGE_MODE_USE_THUMBS,
    HPDF_PAGE_MODE_FULL_SCREEN,
    HPDF_PAGE_MODE_EOF
} HPDF_PageMode;
typedef enum _HPDF_PageNumStyle {
    HPDF_PAGE_NUM_STYLE_DECIMAL = 0,
    HPDF_PAGE_NUM_STYLE_UPPER_ROMAN,
    HPDF_PAGE_NUM_STYLE_LOWER_ROMAN,
    HPDF_PAGE_NUM_STYLE_UPPER_LETTERS,
    HPDF_PAGE_NUM_STYLE_LOWER_LETTERS,
    HPDF_PAGE_NUM_STYLE_EOF
} HPDF_PageNumStyle;
typedef enum _HPDF_DestinationType {
    HPDF_XYZ = 0,
    HPDF_FIT,
    HPDF_FIT_H,
    HPDF_FIT_V,
    HPDF_FIT_R,
    HPDF_FIT_B,
    HPDF_FIT_BH,
    HPDF_FIT_BV,
    HPDF_DST_EOF
} HPDF_DestinationType;
typedef enum _HPDF_AnnotType {
    HPDF_ANNOT_TEXT_NOTES,
    HPDF_ANNOT_LINK,
    HPDF_ANNOT_SOUND,
    HPDF_ANNOT_FREE_TEXT,
    HPDF_ANNOT_STAMP,
    HPDF_ANNOT_SQUARE,
    HPDF_ANNOT_CIRCLE,
    HPDF_ANNOT_STRIKE_OUT,
    HPDF_ANNOT_HIGHTLIGHT,
    HPDF_ANNOT_UNDERLINE,
    HPDF_ANNOT_INK,
    HPDF_ANNOT_FILE_ATTACHMENT,
    HPDF_ANNOT_POPUP,
    HPDF_ANNOT_3D,
    HPDF_ANNOT_SQUIGGLY,
 HPDF_ANNOT_LINE,
 HPDF_ANNOT_PROJECTION
} HPDF_AnnotType;
typedef enum _HPDF_AnnotFlgs {
    HPDF_ANNOT_INVISIBLE,
    HPDF_ANNOT_HIDDEN,
    HPDF_ANNOT_PRINT,
    HPDF_ANNOT_NOZOOM,
    HPDF_ANNOT_NOROTATE,
    HPDF_ANNOT_NOVIEW,
    HPDF_ANNOT_READONLY
} HPDF_AnnotFlgs;
typedef enum _HPDF_AnnotHighlightMode {
    HPDF_ANNOT_NO_HIGHTLIGHT = 0,
    HPDF_ANNOT_INVERT_BOX,
    HPDF_ANNOT_INVERT_BORDER,
    HPDF_ANNOT_DOWN_APPEARANCE,
    HPDF_ANNOT_HIGHTLIGHT_MODE_EOF
} HPDF_AnnotHighlightMode;
typedef enum _HPDF_AnnotIcon {
    HPDF_ANNOT_ICON_COMMENT = 0,
    HPDF_ANNOT_ICON_KEY,
    HPDF_ANNOT_ICON_NOTE,
    HPDF_ANNOT_ICON_HELP,
    HPDF_ANNOT_ICON_NEW_PARAGRAPH,
    HPDF_ANNOT_ICON_PARAGRAPH,
    HPDF_ANNOT_ICON_INSERT,
    HPDF_ANNOT_ICON_EOF
} HPDF_AnnotIcon;
typedef enum _HPDF_AnnotIntent {
    HPDF_ANNOT_INTENT_FREETEXTCALLOUT = 0,
    HPDF_ANNOT_INTENT_FREETEXTTYPEWRITER,
    HPDF_ANNOT_INTENT_LINEARROW,
    HPDF_ANNOT_INTENT_LINEDIMENSION,
    HPDF_ANNOT_INTENT_POLYGONCLOUD,
    HPDF_ANNOT_INTENT_POLYLINEDIMENSION,
    HPDF_ANNOT_INTENT_POLYGONDIMENSION
} HPDF_AnnotIntent;
typedef enum _HPDF_LineAnnotEndingStyle {
    HPDF_LINE_ANNOT_NONE = 0,
    HPDF_LINE_ANNOT_SQUARE,
    HPDF_LINE_ANNOT_CIRCLE,
    HPDF_LINE_ANNOT_DIAMOND,
    HPDF_LINE_ANNOT_OPENARROW,
    HPDF_LINE_ANNOT_CLOSEDARROW,
    HPDF_LINE_ANNOT_BUTT,
    HPDF_LINE_ANNOT_ROPENARROW,
    HPDF_LINE_ANNOT_RCLOSEDARROW,
    HPDF_LINE_ANNOT_SLASH
} HPDF_LineAnnotEndingStyle;
typedef enum _HPDF_LineAnnotCapPosition{
    HPDF_LINE_ANNOT_CAP_INLINE = 0,
    HPDF_LINE_ANNOT_CAP_TOP
} HPDF_LineAnnotCapPosition;
typedef enum _HPDF_StampAnnotName{
    HPDF_STAMP_ANNOT_APPROVED = 0,
    HPDF_STAMP_ANNOT_EXPERIMENTAL,
    HPDF_STAMP_ANNOT_NOTAPPROVED,
    HPDF_STAMP_ANNOT_ASIS,
    HPDF_STAMP_ANNOT_EXPIRED,
    HPDF_STAMP_ANNOT_NOTFORPUBLICRELEASE,
    HPDF_STAMP_ANNOT_CONFIDENTIAL,
    HPDF_STAMP_ANNOT_FINAL,
    HPDF_STAMP_ANNOT_SOLD,
    HPDF_STAMP_ANNOT_DEPARTMENTAL,
    HPDF_STAMP_ANNOT_FORCOMMENT,
    HPDF_STAMP_ANNOT_TOPSECRET,
    HPDF_STAMP_ANNOT_DRAFT,
    HPDF_STAMP_ANNOT_FORPUBLICRELEASE
} HPDF_StampAnnotName;
typedef enum _HPDF_BSSubtype {
    HPDF_BS_SOLID,
    HPDF_BS_DASHED,
    HPDF_BS_BEVELED,
    HPDF_BS_INSET,
    HPDF_BS_UNDERLINED
} HPDF_BSSubtype;
typedef enum _HPDF_BlendMode {
    HPDF_BM_NORMAL,
    HPDF_BM_MULTIPLY,
    HPDF_BM_SCREEN,
    HPDF_BM_OVERLAY,
    HPDF_BM_DARKEN,
    HPDF_BM_LIGHTEN,
    HPDF_BM_COLOR_DODGE,
    HPDF_BM_COLOR_BUM,
    HPDF_BM_HARD_LIGHT,
    HPDF_BM_SOFT_LIGHT,
    HPDF_BM_DIFFERENCE,
    HPDF_BM_EXCLUSHON,
    HPDF_BM_EOF
} HPDF_BlendMode;
typedef enum _HPDF_TransitionStyle {
    HPDF_TS_WIPE_RIGHT = 0,
    HPDF_TS_WIPE_UP,
    HPDF_TS_WIPE_LEFT,
    HPDF_TS_WIPE_DOWN,
    HPDF_TS_BARN_DOORS_HORIZONTAL_OUT,
    HPDF_TS_BARN_DOORS_HORIZONTAL_IN,
    HPDF_TS_BARN_DOORS_VERTICAL_OUT,
    HPDF_TS_BARN_DOORS_VERTICAL_IN,
    HPDF_TS_BOX_OUT,
    HPDF_TS_BOX_IN,
    HPDF_TS_BLINDS_HORIZONTAL,
    HPDF_TS_BLINDS_VERTICAL,
    HPDF_TS_DISSOLVE,
    HPDF_TS_GLITTER_RIGHT,
    HPDF_TS_GLITTER_DOWN,
    HPDF_TS_GLITTER_TOP_LEFT_TO_BOTTOM_RIGHT,
    HPDF_TS_REPLACE,
    HPDF_TS_EOF
} HPDF_TransitionStyle;
typedef enum _HPDF_PageSizes {
    HPDF_PAGE_SIZE_LETTER = 0,
    HPDF_PAGE_SIZE_LEGAL,
    HPDF_PAGE_SIZE_A3,
    HPDF_PAGE_SIZE_A4,
    HPDF_PAGE_SIZE_A5,
    HPDF_PAGE_SIZE_B4,
    HPDF_PAGE_SIZE_B5,
    HPDF_PAGE_SIZE_EXECUTIVE,
    HPDF_PAGE_SIZE_US4x6,
    HPDF_PAGE_SIZE_US4x8,
    HPDF_PAGE_SIZE_US5x7,
    HPDF_PAGE_SIZE_COMM10,
    HPDF_PAGE_SIZE_EOF
} HPDF_PageSizes;
typedef enum _HPDF_PageDirection {
    HPDF_PAGE_PORTRAIT = 0,
    HPDF_PAGE_LANDSCAPE
} HPDF_PageDirection;
typedef enum _HPDF_EncoderType {
    HPDF_ENCODER_TYPE_SINGLE_BYTE,
    HPDF_ENCODER_TYPE_DOUBLE_BYTE,
    HPDF_ENCODER_TYPE_UNINITIALIZED,
    HPDF_ENCODER_UNKNOWN
} HPDF_EncoderType;
typedef enum _HPDF_ByteType {
    HPDF_BYTE_TYPE_SINGLE = 0,
    HPDF_BYTE_TYPE_LEAD,
    HPDF_BYTE_TYPE_TRIAL,
    HPDF_BYTE_TYPE_UNKNOWN
} HPDF_ByteType;
typedef enum _HPDF_TextAlignment {
    HPDF_TALIGN_LEFT = 0,
    HPDF_TALIGN_RIGHT,
    HPDF_TALIGN_CENTER,
    HPDF_TALIGN_JUSTIFY
} HPDF_TextAlignment;
typedef enum _HPDF_NameDictKey {
    HPDF_NAME_EMBEDDED_FILES = 0,
    HPDF_NAME_EOF
} HPDF_NameDictKey;
typedef struct _HPDF_Error_Rec *HPDF_Error;
typedef struct _HPDF_Error_Rec {
    HPDF_STATUS error_no;
    HPDF_STATUS detail_no;
    HPDF_Error_Handler error_fn;
    void *user_data;
} HPDF_Error_Rec;
void
HPDF_Error_Init (HPDF_Error error,
                  void *user_data);
void
HPDF_Error_Reset (HPDF_Error error);
HPDF_STATUS
HPDF_Error_GetCode (HPDF_Error error);
HPDF_STATUS
HPDF_Error_GetDetailCode (HPDF_Error error);
HPDF_STATUS
HPDF_SetError (HPDF_Error error,
                HPDF_STATUS error_no,
                HPDF_STATUS detail_no);
HPDF_STATUS
HPDF_RaiseError (HPDF_Error error,
                  HPDF_STATUS error_no,
                  HPDF_STATUS detail_no);
typedef struct _HPDF_MPool_Node_Rec *HPDF_MPool_Node;
typedef struct _HPDF_MPool_Node_Rec {
    HPDF_BYTE* buf;
    HPDF_UINT size;
    HPDF_UINT used_size;
    HPDF_MPool_Node next_node;
} HPDF_MPool_Node_Rec;
typedef struct _HPDF_MMgr_Rec *HPDF_MMgr;
typedef struct _HPDF_MMgr_Rec {
    HPDF_Error error;
    HPDF_Alloc_Func alloc_fn;
    HPDF_Free_Func free_fn;
    HPDF_MPool_Node mpool;
    HPDF_UINT buf_size;
} HPDF_MMgr_Rec;
HPDF_MMgr
HPDF_MMgr_New (HPDF_Error error,
                HPDF_UINT buf_size,
                HPDF_Alloc_Func alloc_fn,
                HPDF_Free_Func free_fn);
void
HPDF_MMgr_Free (HPDF_MMgr mmgr);
void*
HPDF_GetMem (HPDF_MMgr mmgr,
              HPDF_UINT size);
void
HPDF_FreeMem (HPDF_MMgr mmgr,
               void *aptr);
typedef struct _HPDF_List_Rec *HPDF_List;
typedef struct _HPDF_List_Rec {
      HPDF_MMgr mmgr;
      HPDF_Error error;
      HPDF_UINT block_siz;
      HPDF_UINT items_per_block;
      HPDF_UINT count;
      void **obj;
} HPDF_List_Rec;
HPDF_List
HPDF_List_New (HPDF_MMgr mmgr,
                HPDF_UINT items_per_block);
void
HPDF_List_Free (HPDF_List list);
HPDF_STATUS
HPDF_List_Add (HPDF_List list,
                void *item);
HPDF_STATUS
HPDF_List_Insert (HPDF_List list,
                   void *target,
                   void *item);
HPDF_STATUS
HPDF_List_Remove (HPDF_List list,
                   void *item);
void*
HPDF_List_RemoveByIndex (HPDF_List list,
                          HPDF_UINT index);
void*
HPDF_List_ItemAt (HPDF_List list,
                   HPDF_UINT index);
HPDF_INT32
HPDF_List_Find (HPDF_List list,
                 void *item);
void
HPDF_List_Clear (HPDF_List list);
typedef struct HPDF_MD5Context
{
    HPDF_UINT32 buf[4];
    HPDF_UINT32 bits[2];
    HPDF_BYTE in[64];
} HPDF_MD5_CTX;
typedef struct _HPDF_ARC4_Ctx_Rec {
    HPDF_BYTE idx1;
    HPDF_BYTE idx2;
    HPDF_BYTE state[256];
} HPDF_ARC4_Ctx_Rec;
typedef struct _HPDF_Encrypt_Rec *HPDF_Encrypt;
typedef struct _HPDF_Encrypt_Rec {
    HPDF_EncryptMode mode;
    HPDF_UINT key_len;
    HPDF_BYTE owner_passwd[32];
    HPDF_BYTE user_passwd[32];
    HPDF_BYTE owner_key[32];
    HPDF_BYTE user_key[32];
    HPDF_INT permission;
    HPDF_BYTE encrypt_id[16];
    HPDF_BYTE encryption_key[16 + 5];
    HPDF_BYTE md5_encryption_key[16];
    HPDF_ARC4_Ctx_Rec arc4ctx;
} HPDF_Encrypt_Rec;
void
HPDF_MD5Init (struct HPDF_MD5Context *ctx);
void
HPDF_MD5Update (struct HPDF_MD5Context *ctx,
                 const HPDF_BYTE *buf,
                 HPDF_UINT32 len);
void
HPDF_MD5Final (HPDF_BYTE digest[16],
                struct HPDF_MD5Context *ctx);
void
HPDF_PadOrTrancatePasswd (const char *pwd,
                           HPDF_BYTE *new_pwd);
void
HPDF_Encrypt_Init (HPDF_Encrypt attr);
void
HPDF_Encrypt_CreateUserKey (HPDF_Encrypt attr);
void
HPDF_Encrypt_CreateOwnerKey (HPDF_Encrypt attr);
void
HPDF_Encrypt_CreateEncryptionKey (HPDF_Encrypt attr);
void
HPDF_Encrypt_InitKey (HPDF_Encrypt attr,
                       HPDF_UINT32 object_id,
                       HPDF_UINT16 gen_no);
void
HPDF_Encrypt_Reset (HPDF_Encrypt attr);
void
HPDF_Encrypt_CryptBuf (HPDF_Encrypt attr,
                        const HPDF_BYTE *src,
                        HPDF_BYTE *dst,
                        HPDF_UINT len);
typedef enum _HPDF_StreamType {
    HPDF_STREAM_UNKNOWN = 0,
    HPDF_STREAM_CALLBACK,
    HPDF_STREAM_FILE,
    HPDF_STREAM_MEMORY
} HPDF_StreamType;
typedef enum _HPDF_WhenceMode {
    HPDF_SEEK_SET = 0,
    HPDF_SEEK_CUR,
    HPDF_SEEK_END
} HPDF_WhenceMode;
typedef struct _HPDF_Stream_Rec *HPDF_Stream;
typedef HPDF_STATUS
(*HPDF_Stream_Write_Func) (HPDF_Stream stream,
                            const HPDF_BYTE *ptr,
                            HPDF_UINT siz);
typedef HPDF_STATUS
(*HPDF_Stream_Read_Func) (HPDF_Stream stream,
                           HPDF_BYTE *ptr,
                           HPDF_UINT *siz);
typedef HPDF_STATUS
(*HPDF_Stream_Seek_Func) (HPDF_Stream stream,
                           HPDF_INT pos,
                           HPDF_WhenceMode mode);
typedef HPDF_INT32
(*HPDF_Stream_Tell_Func) (HPDF_Stream stream);
typedef void
(*HPDF_Stream_Free_Func) (HPDF_Stream stream);
typedef HPDF_UINT32
(*HPDF_Stream_Size_Func) (HPDF_Stream stream);
typedef struct _HPDF_MemStreamAttr_Rec *HPDF_MemStreamAttr;
typedef struct _HPDF_MemStreamAttr_Rec {
    HPDF_List buf;
    HPDF_UINT buf_siz;
    HPDF_UINT w_pos;
    HPDF_BYTE *w_ptr;
    HPDF_UINT r_ptr_idx;
    HPDF_UINT r_pos;
    HPDF_BYTE *r_ptr;
} HPDF_MemStreamAttr_Rec;
typedef struct _HPDF_Stream_Rec {
    HPDF_UINT32 sig_bytes;
    HPDF_StreamType type;
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_UINT size;
    HPDF_Stream_Write_Func write_fn;
    HPDF_Stream_Read_Func read_fn;
    HPDF_Stream_Seek_Func seek_fn;
    HPDF_Stream_Free_Func free_fn;
    HPDF_Stream_Tell_Func tell_fn;
    HPDF_Stream_Size_Func size_fn;
    void* attr;
} HPDF_Stream_Rec;
HPDF_Stream
HPDF_MemStream_New (HPDF_MMgr mmgr,
                     HPDF_UINT buf_siz);
HPDF_BYTE*
HPDF_MemStream_GetBufPtr (HPDF_Stream stream,
                           HPDF_UINT index,
                           HPDF_UINT *length);
HPDF_UINT
HPDF_MemStream_GetBufSize (HPDF_Stream stream);
HPDF_UINT
HPDF_MemStream_GetBufCount (HPDF_Stream stream);
HPDF_STATUS
HPDF_MemStream_Rewrite (HPDF_Stream stream,
                         HPDF_BYTE *buf,
                         HPDF_UINT size);
void
HPDF_MemStream_FreeData (HPDF_Stream stream);
HPDF_STATUS
HPDF_Stream_WriteToStream (HPDF_Stream src,
                            HPDF_Stream dst,
                            HPDF_UINT filter,
                            HPDF_Encrypt e);
HPDF_Stream
HPDF_FileReader_New (HPDF_MMgr mmgr,
                      const char *fname);
HPDF_Stream
HPDF_FileWriter_New (HPDF_MMgr mmgr,
                      const char *fname);
HPDF_Stream
HPDF_CallbackReader_New (HPDF_MMgr mmgr,
                          HPDF_Stream_Read_Func read_fn,
                          HPDF_Stream_Seek_Func seek_fn,
                          HPDF_Stream_Tell_Func tell_fn,
                          HPDF_Stream_Size_Func size_fn,
                          void* data);
HPDF_Stream
HPDF_CallbackWriter_New (HPDF_MMgr mmgr,
                         HPDF_Stream_Write_Func write_fn,
                         void* data);
void
HPDF_Stream_Free (HPDF_Stream stream);
HPDF_STATUS
HPDF_Stream_WriteChar (HPDF_Stream stream,
                        char value);
HPDF_STATUS
HPDF_Stream_WriteStr (HPDF_Stream stream,
                       const char *value);
HPDF_STATUS
HPDF_Stream_WriteUChar (HPDF_Stream stream,
                         HPDF_BYTE value);
HPDF_STATUS
HPDF_Stream_WriteInt (HPDF_Stream stream,
                       HPDF_INT value);
HPDF_STATUS
HPDF_Stream_WriteUInt (HPDF_Stream stream,
                        HPDF_UINT value);
HPDF_STATUS
HPDF_Stream_WriteReal (HPDF_Stream stream,
                        HPDF_REAL value);
HPDF_STATUS
HPDF_Stream_Write (HPDF_Stream stream,
                    const HPDF_BYTE *ptr,
                    HPDF_UINT size);
HPDF_STATUS
HPDF_Stream_Read (HPDF_Stream stream,
                   HPDF_BYTE *ptr,
                   HPDF_UINT *size);
HPDF_STATUS
HPDF_Stream_ReadLn (HPDF_Stream stream,
                     char *s,
                     HPDF_UINT *size);
HPDF_INT32
HPDF_Stream_Tell (HPDF_Stream stream);
HPDF_STATUS
HPDF_Stream_Seek (HPDF_Stream stream,
                   HPDF_INT pos,
                   HPDF_WhenceMode mode);
HPDF_BOOL
HPDF_Stream_EOF (HPDF_Stream stream);
HPDF_UINT32
HPDF_Stream_Size (HPDF_Stream stream);
HPDF_STATUS
HPDF_Stream_Flush (HPDF_Stream stream);
HPDF_STATUS
HPDF_Stream_WriteEscapeName (HPDF_Stream stream,
                              const char *value);
HPDF_STATUS
HPDF_Stream_WriteEscapeText2 (HPDF_Stream stream,
                               const char *text,
                               HPDF_UINT len);
HPDF_STATUS
HPDF_Stream_WriteEscapeText (HPDF_Stream stream,
                              const char *text);
HPDF_STATUS
HPDF_Stream_WriteBinary (HPDF_Stream stream,
                          const HPDF_BYTE *data,
                          HPDF_UINT len,
                          HPDF_Encrypt e);
HPDF_STATUS
HPDF_Stream_Validate (HPDF_Stream stream);
typedef enum _HPDF_EncodingType {
    HPDF_STANDARD_ENCODING = 0,
    HPDF_MAC_ROMAN_ENCODING,
    HPDF_WIN_ANSI_ENCODING,
    HPDF_FONT_SPECIFIC,
    HPDF_ENCODING_EOF
} HPDF_EncodingType;
typedef struct _HPDF_ParseText_Rec {
    const HPDF_BYTE *text;
    HPDF_UINT index;
    HPDF_UINT len;
    HPDF_ByteType byte_type;
} HPDF_ParseText_Rec;
typedef struct _HPDF_Encoder_Rec *HPDF_Encoder;
typedef HPDF_ByteType
(*HPDF_Encoder_ByteType_Func) (HPDF_Encoder encoder,
                                HPDF_ParseText_Rec *state);
typedef HPDF_UNICODE
(*HPDF_Encoder_ToUnicode_Func) (HPDF_Encoder encoder,
                                 HPDF_UINT16 code);
typedef HPDF_STATUS
(*HPDF_Encoder_Write_Func) (HPDF_Encoder encoder,
                             HPDF_Stream out);
typedef HPDF_STATUS
(*HPDF_Encoder_Init_Func) (HPDF_Encoder encoder);
typedef void
(*HPDF_Encoder_Free_Func) (HPDF_Encoder encoder);
typedef struct _HPDF_Encoder_Rec {
    HPDF_UINT32 sig_bytes;
    char name[127 + 1];
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_EncoderType type;
    HPDF_Encoder_ByteType_Func byte_type_fn;
    HPDF_Encoder_ToUnicode_Func to_unicode_fn;
    HPDF_Encoder_Write_Func write_fn;
    HPDF_Encoder_Free_Func free_fn;
    HPDF_Encoder_Init_Func init_fn;
    void *attr;
} HPDF_Encoder_Rec;
typedef enum _HPDF_BaseEncodings {
    HPDF_BASE_ENCODING_STANDARD,
    HPDF_BASE_ENCODING_WIN_ANSI,
    HPDF_BASE_ENCODING_MAC_ROMAN,
    HPDF_BASE_ENCODING_FONT_SPECIFIC,
    HPDF_BASE_ENCODING_EOF
} HPDF_BaseEncodings;
HPDF_STATUS
HPDF_Encoder_Validate (HPDF_Encoder encoder);
void
HPDF_Encoder_SetParseText (HPDF_Encoder encoder,
                            HPDF_ParseText_Rec *state,
                            const HPDF_BYTE *text,
                            HPDF_UINT len);
HPDF_ByteType
HPDF_Encoder_ByteType (HPDF_Encoder encoder,
                        HPDF_ParseText_Rec *state);
HPDF_UNICODE
HPDF_Encoder_ToUnicode (HPDF_Encoder encoder,
                         HPDF_UINT16 code);
void
HPDF_Encoder_Free (HPDF_Encoder encoder);
typedef struct _HPDF_BasicEncoderAttr_Rec *HPDF_BasicEncoderAttr;
typedef struct _HPDF_BasicEncoderAttr_Rec {
      char base_encoding[127 + 1];
      HPDF_BYTE first_char;
      HPDF_BYTE last_char;
      HPDF_UNICODE unicode_map[256];
      HPDF_BOOL has_differences;
      HPDF_BYTE differences[256];
} HPDF_BasicEncoderAttr_Rec;
HPDF_Encoder
HPDF_BasicEncoder_New (HPDF_MMgr mmgr,
                        const char *encoding_name);
void
HPDF_BasicEncoder_Free (HPDF_Encoder encoder);
HPDF_STATUS
HPDF_BasicEncoder_Write (HPDF_Encoder encoder,
                          HPDF_Stream out);
HPDF_UNICODE
HPDF_BasicEncoder_ToUnicode (HPDF_Encoder encoder,
                             HPDF_UINT16 code);
typedef HPDF_BOOL
(*HPDF_CMapEncoder_ByteType_Func) (HPDF_Encoder encoder,
                                    HPDF_BYTE b);
typedef struct _HPDF_CidRange_Rec {
    HPDF_UINT16 from;
    HPDF_UINT16 to;
    HPDF_UINT16 cid;
} HPDF_CidRange_Rec;
typedef struct _HPDF_UnicodeMap_Rec {
    HPDF_UINT16 code;
    HPDF_UINT16 unicode;
} HPDF_UnicodeMap_Rec;
typedef struct _HPDF_CMapEncoderAttr_Rec *HPDF_CMapEncoderAttr;
typedef struct _HPDF_CMapEncoderAttr_Rec {
      HPDF_UNICODE unicode_map[256][256];
      HPDF_UINT16 cid_map[256][256];
      HPDF_UINT16 jww_line_head[128];
      HPDF_List cmap_range;
      HPDF_List notdef_range;
      HPDF_List code_space_range;
      HPDF_WritingMode writing_mode;
      char registry[127 + 1];
      char ordering[127 + 1];
      HPDF_INT suppliment;
      HPDF_CMapEncoder_ByteType_Func is_lead_byte_fn;
      HPDF_CMapEncoder_ByteType_Func is_trial_byte_fn;
      HPDF_INT uid_offset;
      HPDF_UINT xuid[3];
} HPDF_CMapEncoderAttr_Rec;
HPDF_Encoder
HPDF_CMapEncoder_New (HPDF_MMgr mmgr,
                       char *name,
                       HPDF_Encoder_Init_Func init_fn);
HPDF_STATUS
HPDF_CMapEncoder_InitAttr (HPDF_Encoder encoder);
void
HPDF_CMapEncoder_Free (HPDF_Encoder encoder);
HPDF_STATUS
HPDF_CMapEncoder_Write (HPDF_Encoder encoder,
                         HPDF_Stream out);
HPDF_UNICODE
HPDF_CMapEncoder_ToUnicode (HPDF_Encoder encoder,
                             HPDF_UINT16 code);
HPDF_UINT16
HPDF_CMapEncoder_ToCID (HPDF_Encoder encoder,
                         HPDF_UINT16 code);
HPDF_STATUS
HPDF_CMapEncoder_SetParseText (HPDF_Encoder encoder,
                                HPDF_ParseText_Rec *state,
                                const HPDF_BYTE *text,
                                HPDF_UINT len);
HPDF_ByteType
HPDF_CMapEncoder_ByteType (HPDF_Encoder encoder,
                            HPDF_ParseText_Rec *state);
HPDF_STATUS
HPDF_CMapEncoder_AddCMap (HPDF_Encoder encoder,
                           const HPDF_CidRange_Rec *range);
HPDF_STATUS
HPDF_CMapEncoder_AddNotDefRange (HPDF_Encoder encoder,
                                  HPDF_CidRange_Rec range);
HPDF_STATUS
HPDF_CMapEncoder_AddCodeSpaceRange (HPDF_Encoder encoder,
                                     HPDF_CidRange_Rec range);
void
HPDF_CMapEncoder_SetUnicodeArray (HPDF_Encoder encoder,
                                   const HPDF_UnicodeMap_Rec *array1);
HPDF_STATUS
HPDF_CMapEncoder_AddJWWLineHead (HPDF_Encoder encoder,
                                  const HPDF_UINT16 *code);
HPDF_BOOL
HPDF_Encoder_CheckJWWLineHead (HPDF_Encoder encoder,
                                const HPDF_UINT16 code);
const char*
HPDF_UnicodeToGryphName (HPDF_UNICODE unicode);
HPDF_UNICODE
HPDF_GryphNameToUnicode (const char *gryph_name);
typedef struct _HPDF_Obj_Header {
    HPDF_UINT32 obj_id;
    HPDF_UINT16 gen_no;
    HPDF_UINT16 obj_class;
} HPDF_Obj_Header;
HPDF_STATUS
HPDF_Obj_WriteValue (void *obj,
                      HPDF_Stream stream,
                      HPDF_Encrypt e);
HPDF_STATUS
HPDF_Obj_Write (void *obj,
                 HPDF_Stream stream,
                 HPDF_Encrypt e);
void
HPDF_Obj_Free (HPDF_MMgr mmgr,
                void *obj);
void
HPDF_Obj_ForceFree (HPDF_MMgr mmgr,
                     void *obj);
typedef struct _HPDF_Null_Rec *HPDF_Null;
typedef struct _HPDF_Null_Rec {
    HPDF_Obj_Header header;
} HPDF_Null_Rec;
HPDF_Null
HPDF_Null_New (HPDF_MMgr mmgr);
typedef struct _HPDF_Boolean_Rec *HPDF_Boolean;
typedef struct _HPDF_Boolean_Rec {
    HPDF_Obj_Header header;
    HPDF_BOOL value;
} HPDF_Boolean_Rec;
HPDF_Boolean
HPDF_Boolean_New (HPDF_MMgr mmgr,
                   HPDF_BOOL value);
HPDF_STATUS
HPDF_Boolean_Write (HPDF_Boolean obj,
                     HPDF_Stream stream);
typedef struct _HPDF_Number_Rec *HPDF_Number;
typedef struct _HPDF_Number_Rec {
    HPDF_Obj_Header header;
    HPDF_INT32 value;
} HPDF_Number_Rec;
HPDF_Number
HPDF_Number_New (HPDF_MMgr mmgr,
                  HPDF_INT32 value);
void
HPDF_Number_SetValue (HPDF_Number obj,
                       HPDF_INT32 value);
HPDF_STATUS
HPDF_Number_Write (HPDF_Number obj,
                    HPDF_Stream stream);
typedef struct _HPDF_Real_Rec *HPDF_Real;
typedef struct _HPDF_Real_Rec {
    HPDF_Obj_Header header;
    HPDF_Error error;
    HPDF_REAL value;
} HPDF_Real_Rec;
HPDF_Real
HPDF_Real_New (HPDF_MMgr mmgr,
                HPDF_REAL value);
HPDF_STATUS
HPDF_Real_Write (HPDF_Real obj,
                  HPDF_Stream stream);
HPDF_STATUS
HPDF_Real_SetValue (HPDF_Real obj,
                     HPDF_REAL value);
typedef struct _HPDF_Name_Rec *HPDF_Name;
typedef struct _HPDF_Name_Rec {
    HPDF_Obj_Header header;
    HPDF_Error error;
    char value[127 + 1];
} HPDF_Name_Rec;
HPDF_Name
HPDF_Name_New (HPDF_MMgr mmgr,
                const char *value);
HPDF_STATUS
HPDF_Name_SetValue (HPDF_Name obj,
                     const char *value);
HPDF_STATUS
HPDF_Name_Write (HPDF_Name obj,
                  HPDF_Stream stream);
const char*
HPDF_Name_GetValue (HPDF_Name obj);
typedef struct _HPDF_String_Rec *HPDF_String;
typedef struct _HPDF_String_Rec {
    HPDF_Obj_Header header;
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_Encoder encoder;
    HPDF_BYTE *value;
    HPDF_UINT len;
} HPDF_String_Rec;
HPDF_String
HPDF_String_New (HPDF_MMgr mmgr,
                  const char *value,
                  HPDF_Encoder encoder);
HPDF_STATUS
HPDF_String_SetValue (HPDF_String obj,
                       const char *value);
void
HPDF_String_Free (HPDF_String obj);
HPDF_STATUS
HPDF_String_Write (HPDF_String obj,
                    HPDF_Stream stream,
                    HPDF_Encrypt e);
HPDF_INT32
HPDF_String_Cmp (HPDF_String s1,
                  HPDF_String s2);
typedef struct _HPDF_Binary_Rec *HPDF_Binary;
typedef struct _HPDF_Binary_Rec {
    HPDF_Obj_Header header;
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_BYTE *value;
    HPDF_UINT len;
} HPDF_Binary_Rec;
HPDF_Binary
HPDF_Binary_New (HPDF_MMgr mmgr,
                  HPDF_BYTE *value,
                  HPDF_UINT len);
HPDF_STATUS
HPDF_Binary_SetValue (HPDF_Binary obj,
                       HPDF_BYTE *value,
                       HPDF_UINT len);
HPDF_BYTE*
HPDF_Binary_GetValue (HPDF_Binary obj);
void
HPDF_Binary_Free (HPDF_Binary obj);
HPDF_STATUS
HPDF_Binary_Write (HPDF_Binary obj,
                    HPDF_Stream stream,
                    HPDF_Encrypt e);
HPDF_UINT
HPDF_Binary_GetLen (HPDF_Binary obj);
typedef struct _HPDF_Array_Rec *HPDF_Array;
typedef struct _HPDF_Array_Rec {
    HPDF_Obj_Header header;
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_List list;
} HPDF_Array_Rec;
HPDF_Array
HPDF_Array_New (HPDF_MMgr mmgr);
HPDF_Array
HPDF_Box_Array_New (HPDF_MMgr mmgr,
                     HPDF_Box box);
void
HPDF_Array_Free (HPDF_Array array);
HPDF_STATUS
HPDF_Array_Write (HPDF_Array array,
                   HPDF_Stream stream,
                   HPDF_Encrypt e);
HPDF_STATUS
HPDF_Array_Add (HPDF_Array array,
                 void *obj);
HPDF_STATUS
HPDF_Array_Insert (HPDF_Array array,
                    void *target,
                    void *obj);
void*
HPDF_Array_GetItem (HPDF_Array array,
                     HPDF_UINT index,
                     HPDF_UINT16 obj_class);
HPDF_STATUS
HPDF_Array_AddNumber (HPDF_Array array,
                       HPDF_INT32 value);
HPDF_STATUS
HPDF_Array_AddReal (HPDF_Array array,
                     HPDF_REAL value);
HPDF_STATUS
HPDF_Array_AddName (HPDF_Array array,
                     const char *value);
void
HPDF_Array_Clear (HPDF_Array array);
HPDF_UINT
HPDF_Array_Items (HPDF_Array array);
typedef struct _HPDF_Xref_Rec *HPDF_Xref;
typedef struct _HPDF_Dict_Rec *HPDF_Dict;
typedef void
(*HPDF_Dict_FreeFunc) (HPDF_Dict obj);
typedef HPDF_STATUS
(*HPDF_Dict_BeforeWriteFunc) (HPDF_Dict obj);
typedef HPDF_STATUS
(*HPDF_Dict_AfterWriteFunc) (HPDF_Dict obj);
typedef HPDF_STATUS
(*HPDF_Dict_OnWriteFunc) (HPDF_Dict obj,
                           HPDF_Stream stream);
typedef struct _HPDF_Dict_Rec {
    HPDF_Obj_Header header;
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_List list;
    HPDF_Dict_BeforeWriteFunc before_write_fn;
    HPDF_Dict_OnWriteFunc write_fn;
    HPDF_Dict_AfterWriteFunc after_write_fn;
    HPDF_Dict_FreeFunc free_fn;
    HPDF_Stream stream;
    HPDF_UINT filter;
    HPDF_Dict filterParams;
    void *attr;
} HPDF_Dict_Rec;
typedef struct _HPDF_DictElement_Rec *HPDF_DictElement;
typedef struct _HPDF_DictElement_Rec {
    char key[127 + 1];
    void *value;
} HPDF_DictElement_Rec;
HPDF_Dict
HPDF_Dict_New (HPDF_MMgr mmgr);
HPDF_Dict
HPDF_DictStream_New (HPDF_MMgr mmgr,
                      HPDF_Xref xref);
void
HPDF_Dict_Free (HPDF_Dict dict);
HPDF_STATUS
HPDF_Dict_Write (HPDF_Dict dict,
                  HPDF_Stream stream,
                  HPDF_Encrypt e);
const char*
HPDF_Dict_GetKeyByObj (HPDF_Dict dict,
                       void *obj);
HPDF_STATUS
HPDF_Dict_Add (HPDF_Dict dict,
                const char *key,
                void *obj);
void*
HPDF_Dict_GetItem (HPDF_Dict dict,
                    const char *key,
                    HPDF_UINT16 obj_class);
HPDF_STATUS
HPDF_Dict_AddName (HPDF_Dict dict,
                   const char *key,
                   const char *value);
HPDF_STATUS
HPDF_Dict_AddNumber (HPDF_Dict dict,
                      const char *key,
                      HPDF_INT32 value);
HPDF_STATUS
HPDF_Dict_AddReal (HPDF_Dict dict,
                    const char *key,
                    HPDF_REAL value);
HPDF_STATUS
HPDF_Dict_AddBoolean (HPDF_Dict dict,
                       const char *key,
                       HPDF_BOOL value);
HPDF_STATUS
HPDF_Dict_RemoveElement (HPDF_Dict dict,
                          const char *key);
typedef struct _HPDF_Proxy_Rec *HPDF_Proxy;
typedef struct _HPDF_Proxy_Rec {
    HPDF_Obj_Header header;
    void *obj;
} HPDF_Proxy_Rec;
HPDF_Proxy
HPDF_Proxy_New (HPDF_MMgr mmgr,
                 void *obj);
typedef struct _HPDF_XrefEntry_Rec *HPDF_XrefEntry;
typedef struct _HPDF_XrefEntry_Rec {
      char entry_typ;
      HPDF_UINT byte_offset;
      HPDF_UINT16 gen_no;
      void* obj;
} HPDF_XrefEntry_Rec;
typedef struct _HPDF_Xref_Rec {
      HPDF_MMgr mmgr;
      HPDF_Error error;
      HPDF_UINT32 start_offset;
      HPDF_List entries;
      HPDF_UINT addr;
      HPDF_Xref prev;
      HPDF_Dict trailer;
} HPDF_Xref_Rec;
HPDF_Xref
HPDF_Xref_New (HPDF_MMgr mmgr,
                HPDF_UINT32 offset);
void
HPDF_Xref_Free (HPDF_Xref xref);
HPDF_STATUS
HPDF_Xref_Add (HPDF_Xref xref,
                void *obj);
HPDF_XrefEntry
HPDF_Xref_GetEntry (HPDF_Xref xref,
                     HPDF_UINT index);
HPDF_STATUS
HPDF_Xref_WriteToStream (HPDF_Xref xref,
                          HPDF_Stream stream,
                          HPDF_Encrypt e);
HPDF_XrefEntry
HPDF_Xref_GetEntryByObjectId (HPDF_Xref xref,
                               HPDF_UINT obj_id);
typedef HPDF_Dict HPDF_EmbeddedFile;
typedef HPDF_Dict HPDF_NameDict;
typedef HPDF_Dict HPDF_NameTree;
typedef HPDF_Dict HPDF_Pages;
typedef HPDF_Dict HPDF_Page;
typedef HPDF_Dict HPDF_Annotation;
typedef HPDF_Dict HPDF_3DMeasure;
typedef HPDF_Dict HPDF_ExData;
typedef HPDF_Dict HPDF_XObject;
typedef HPDF_Dict HPDF_Image;
typedef HPDF_Dict HPDF_Outline;
typedef HPDF_Dict HPDF_EncryptDict;
typedef HPDF_Dict HPDF_Action;
typedef HPDF_Dict HPDF_ExtGState;
typedef HPDF_Array HPDF_Destination;
typedef HPDF_Dict HPDF_U3D;
typedef HPDF_Dict HPDF_OutputIntent;
typedef HPDF_Dict HPDF_JavaScript;
typedef HPDF_Dict HPDF_Catalog;
HPDF_Catalog
HPDF_Catalog_New (HPDF_MMgr mmgr,
                   HPDF_Xref xref);
HPDF_NameDict
HPDF_Catalog_GetNames (HPDF_Catalog catalog);
HPDF_STATUS
HPDF_Catalog_SetNames (HPDF_Catalog catalog,
                        HPDF_NameDict dict);
HPDF_Pages
HPDF_Catalog_GetRoot (HPDF_Catalog catalog);
HPDF_PageLayout
HPDF_Catalog_GetPageLayout (HPDF_Catalog catalog);
HPDF_STATUS
HPDF_Catalog_SetPageLayout (HPDF_Catalog catalog,
                             HPDF_PageLayout layout);
HPDF_PageMode
HPDF_Catalog_GetPageMode (HPDF_Catalog catalog);
HPDF_STATUS
HPDF_Catalog_SetPageMode (HPDF_Catalog catalog,
                           HPDF_PageMode mode);
HPDF_STATUS
HPDF_Catalog_SetOpenAction (HPDF_Catalog catalog,
                             HPDF_Destination open_action);
HPDF_STATUS
HPDF_Catalog_AddPageLabel (HPDF_Catalog catalog,
                            HPDF_UINT page_num,
                            HPDF_Dict page_label);
HPDF_UINT
HPDF_Catalog_GetViewerPreference (HPDF_Catalog catalog);
HPDF_STATUS
HPDF_Catalog_SetViewerPreference (HPDF_Catalog catalog,
                                   HPDF_UINT value);
HPDF_BOOL
HPDF_Catalog_Validate (HPDF_Catalog catalog);
HPDF_Image
HPDF_Image_Load1BitImageFromMem (HPDF_MMgr mmgr,
                          const HPDF_BYTE *buf,
                          HPDF_Xref xref,
                          HPDF_UINT width,
                          HPDF_UINT height,
                          HPDF_UINT line_width,
                          HPDF_BOOL top_is_first
                          );
HPDF_Image
HPDF_Image_LoadPngImage (HPDF_MMgr mmgr,
                          HPDF_Stream png_data,
                          HPDF_Xref xref,
                          HPDF_BOOL delayed_loading);
HPDF_Image
HPDF_Image_LoadJpegImage (HPDF_MMgr mmgr,
                           HPDF_Stream jpeg_data,
                           HPDF_Xref xref);
HPDF_Image
HPDF_Image_LoadJpegImageFromMem (HPDF_MMgr mmgr,
                            const HPDF_BYTE *buf,
                                  HPDF_UINT size,
                                  HPDF_Xref xref);
HPDF_Image
HPDF_Image_LoadRawImage (HPDF_MMgr mmgr,
                          HPDF_Stream stream,
                          HPDF_Xref xref,
                          HPDF_UINT width,
                          HPDF_UINT height,
                          HPDF_ColorSpace color_space);
HPDF_Image
HPDF_Image_LoadRawImageFromMem (HPDF_MMgr mmgr,
                                 const HPDF_BYTE *buf,
                                 HPDF_Xref xref,
                                 HPDF_UINT width,
                                 HPDF_UINT height,
                                 HPDF_ColorSpace color_space,
                                 HPDF_UINT bits_per_component);
HPDF_BOOL
HPDF_Image_Validate (HPDF_Image image);
HPDF_STATUS
HPDF_Image_SetMask (HPDF_Image image,
                    HPDF_BOOL mask);
HPDF_STATUS
HPDF_Image_SetColorSpace (HPDF_Image image,
                           HPDF_Array colorspace);
HPDF_STATUS
HPDF_Image_SetRenderingIntent (HPDF_Image image,
                                const char* intent);
typedef struct _HPDF_CharData {
    HPDF_INT16 char_cd;
    HPDF_UNICODE unicode;
    HPDF_INT16 width;
} HPDF_CharData;
typedef enum _HPDF_FontDefType {
    HPDF_FONTDEF_TYPE_TYPE1,
    HPDF_FONTDEF_TYPE_TRUETYPE,
    HPDF_FONTDEF_TYPE_CID,
    HPDF_FONTDEF_TYPE_UNINITIALIZED,
    HPDF_FONTDEF_TYPE_EOF
} HPDF_FontDefType;
typedef struct _HPDF_CID_Width {
    HPDF_UINT16 cid;
    HPDF_INT16 width;
} HPDF_CID_Width;
typedef struct _HPDF_FontDef_Rec *HPDF_FontDef;
typedef void (*HPDF_FontDef_FreeFunc) (HPDF_FontDef fontdef);
typedef void (*HPDF_FontDef_CleanFunc) (HPDF_FontDef fontdef);
typedef HPDF_STATUS (*HPDF_FontDef_InitFunc) (HPDF_FontDef fontdef);
typedef struct _HPDF_FontDef_Rec {
    HPDF_UINT32 sig_bytes;
    char base_font[127 + 1];
    HPDF_MMgr mmgr;
    HPDF_Error error;
    HPDF_FontDefType type;
    HPDF_FontDef_CleanFunc clean_fn;
    HPDF_FontDef_FreeFunc free_fn;
    HPDF_FontDef_InitFunc init_fn;
    HPDF_INT16 ascent;
    HPDF_INT16 descent;
    HPDF_UINT flags;
    HPDF_Box font_bbox;
    HPDF_INT16 italic_angle;
    HPDF_UINT16 stemv;
    HPDF_INT16 avg_width;
    HPDF_INT16 max_width;
    HPDF_INT16 missing_width;
    HPDF_UINT16 stemh;
    HPDF_UINT16 x_height;
    HPDF_UINT16 cap_height;
    HPDF_Dict descriptor;
    HPDF_Stream data;
    HPDF_BOOL valid;
    void *attr;
} HPDF_FontDef_Rec;
void
HPDF_FontDef_Free (HPDF_FontDef fontdef);
void
HPDF_FontDef_Cleanup (HPDF_FontDef fontdef);
HPDF_BOOL
HPDF_FontDef_Validate (HPDF_FontDef fontdef);
typedef struct _HPDF_Type1FontDefAttrRec *HPDF_Type1FontDefAttr;
typedef struct _HPDF_Type1FontDefAttrRec {
    HPDF_BYTE first_char;
    HPDF_BYTE last_char;
    HPDF_CharData *widths;
    HPDF_UINT widths_count;
    HPDF_INT16 leading;
    char *char_set;
    char encoding_scheme[127 + 1];
    HPDF_UINT length1;
    HPDF_UINT length2;
    HPDF_UINT length3;
    HPDF_BOOL is_base14font;
    HPDF_BOOL is_fixed_pitch;
    HPDF_Stream font_data;
} HPDF_Type1FontDefAttr_Rec;
HPDF_FontDef
HPDF_Type1FontDef_New (HPDF_MMgr mmgr);
HPDF_FontDef
HPDF_Type1FontDef_Load (HPDF_MMgr mmgr,
                         HPDF_Stream afm,
                         HPDF_Stream font_data);
HPDF_FontDef
HPDF_Type1FontDef_Duplicate (HPDF_MMgr mmgr,
                              HPDF_FontDef src);
HPDF_STATUS
HPDF_Type1FontDef_SetWidths (HPDF_FontDef fontdef,
                              const HPDF_CharData *widths);
HPDF_INT16
HPDF_Type1FontDef_GetWidthByName (HPDF_FontDef fontdef,
                                   const char *gryph_name);
HPDF_INT16
HPDF_Type1FontDef_GetWidth (HPDF_FontDef fontdef,
                             HPDF_UNICODE unicode);
HPDF_FontDef
HPDF_Base14FontDef_New (HPDF_MMgr mmgr,
                         const char *font_name);
typedef struct _HPDF_TTF_Table {
        char tag[4];
        HPDF_UINT32 check_sum;
        HPDF_UINT32 offset;
        HPDF_UINT32 length;
} HPDF_TTFTable;
typedef struct _HPDF_TTF_OffsetTbl {
        HPDF_UINT32 sfnt_version;
        HPDF_UINT16 num_tables;
        HPDF_UINT16 search_range;
        HPDF_UINT16 entry_selector;
        HPDF_UINT16 range_shift;
        HPDF_TTFTable *table;
} HPDF_TTF_OffsetTbl;
typedef struct _HPDF_TTF_CmapRange {
        HPDF_UINT16 format;
        HPDF_UINT16 length;
        HPDF_UINT16 language;
        HPDF_UINT16 seg_count_x2;
        HPDF_UINT16 search_range;
        HPDF_UINT16 entry_selector;
        HPDF_UINT16 range_shift;
        HPDF_UINT16 *end_count;
        HPDF_UINT16 reserved_pad;
        HPDF_UINT16 *start_count;
        HPDF_INT16 *id_delta;
        HPDF_UINT16 *id_range_offset;
        HPDF_UINT16 *glyph_id_array;
        HPDF_UINT glyph_id_array_count;
} HPDF_TTF_CmapRange;
typedef struct _HPDF_TTF_GryphOffsets {
        HPDF_UINT32 base_offset;
        HPDF_UINT32 *offsets;
        HPDF_BYTE *flgs;
} HPDF_TTF_GryphOffsets;
typedef struct _HPDF_TTF_LongHorMetric {
        HPDF_UINT16 advance_width;
        HPDF_INT16 lsb;
} HPDF_TTF_LongHorMetric;
typedef struct _HPDF_TTF_FontHeader {
    HPDF_BYTE version_number[4];
    HPDF_UINT32 font_revision;
    HPDF_UINT32 check_sum_adjustment;
    HPDF_UINT32 magic_number;
    HPDF_UINT16 flags;
    HPDF_UINT16 units_per_em;
    HPDF_BYTE created[8];
    HPDF_BYTE modified[8];
    HPDF_INT16 x_min;
    HPDF_INT16 y_min;
    HPDF_INT16 x_max;
    HPDF_INT16 y_max;
    HPDF_UINT16 mac_style;
    HPDF_UINT16 lowest_rec_ppem;
    HPDF_INT16 font_direction_hint;
    HPDF_INT16 index_to_loc_format;
    HPDF_INT16 glyph_data_format;
} HPDF_TTF_FontHeader;
typedef struct _HPDF_TTF_NameRecord {
    HPDF_UINT16 platform_id;
    HPDF_UINT16 encoding_id;
    HPDF_UINT16 language_id;
    HPDF_UINT16 name_id;
    HPDF_UINT16 length;
    HPDF_UINT16 offset;
} HPDF_TTF_NameRecord;
typedef struct _HPDF_TTF_NamingTable {
    HPDF_UINT16 format;
    HPDF_UINT16 count;
    HPDF_UINT16 string_offset;
    HPDF_TTF_NameRecord *name_records;
} HPDF_TTF_NamingTable;
typedef struct _HPDF_TTFontDefAttr_Rec *HPDF_TTFontDefAttr;
typedef struct _HPDF_TTFontDefAttr_Rec {
    char base_font[127 + 1];
    HPDF_BYTE first_char;
    HPDF_BYTE last_char;
    char *char_set;
    char tag_name[6 + 1];
    char tag_name2[(6 + 1) * 2];
    HPDF_TTF_FontHeader header;
    HPDF_TTF_GryphOffsets glyph_tbl;
    HPDF_UINT16 num_glyphs;
    HPDF_TTF_NamingTable name_tbl;
    HPDF_TTF_LongHorMetric *h_metric;
    HPDF_UINT16 num_h_metric;
    HPDF_TTF_OffsetTbl offset_tbl;
    HPDF_TTF_CmapRange cmap;
    HPDF_UINT16 fs_type;
    HPDF_BYTE sfamilyclass[2];
    HPDF_BYTE panose[10];
    HPDF_UINT32 code_page_range1;
    HPDF_UINT32 code_page_range2;
    HPDF_UINT length1;
    HPDF_BOOL embedding;
    HPDF_BOOL is_cidfont;
    HPDF_Stream stream;
} HPDF_TTFontDefAttr_Rec;
HPDF_FontDef
HPDF_TTFontDef_New (HPDF_MMgr mmgr);
HPDF_FontDef
HPDF_TTFontDef_Load (HPDF_MMgr mmgr,
                      HPDF_Stream stream,
                      HPDF_BOOL embedding);
HPDF_FontDef
HPDF_TTFontDef_Load2 (HPDF_MMgr mmgr,
                       HPDF_Stream stream,
                       HPDF_UINT index,
                       HPDF_BOOL embedding);
HPDF_UINT16
HPDF_TTFontDef_GetGlyphid (HPDF_FontDef fontdef,
                            HPDF_UINT16 unicode);
HPDF_INT16
HPDF_TTFontDef_GetCharWidth (HPDF_FontDef fontdef,
                              HPDF_UINT16 unicode);
HPDF_INT16
HPDF_TTFontDef_GetGidWidth (HPDF_FontDef fontdef,
                             HPDF_UINT16 gid);
HPDF_STATUS
HPDF_TTFontDef_SaveFontData (HPDF_FontDef fontdef,
                              HPDF_Stream stream);
HPDF_Box
HPDF_TTFontDef_GetCharBBox (HPDF_FontDef fontdef,
                             HPDF_UINT16 unicode);
void
HPDF_TTFontDef_SetTagName (HPDF_FontDef fontdef,
                            char *tag);
typedef struct _HPDF_CIDFontDefAttrRec *HPDF_CIDFontDefAttr;
typedef struct _HPDF_CIDFontDefAttrRec {
    HPDF_List widths;
    HPDF_INT16 DW;
    HPDF_INT16 DW2[2];
} HPDF_CIDFontDefAttr_Rec;
HPDF_FontDef
HPDF_CIDFontDef_New (HPDF_MMgr mmgr,
                      char *name,
                      HPDF_FontDef_InitFunc init_fn);
HPDF_STATUS
HPDF_CIDFontDef_AddWidth (HPDF_FontDef fontdef,
                           const HPDF_CID_Width *widths);
HPDF_INT16
HPDF_CIDFontDef_GetCIDWidth (HPDF_FontDef fontdef,
                              HPDF_UINT16 cid);
HPDF_STATUS
HPDF_CIDFontDef_ChangeStyle (HPDF_FontDef fontdef,
                               HPDF_BOOL bold,
                               HPDF_BOOL italic);
typedef enum _HPDF_FontType {
    HPDF_FONT_TYPE1 = 0,
    HPDF_FONT_TRUETYPE,
    HPDF_FONT_TYPE3,
    HPDF_FONT_TYPE0_CID,
    HPDF_FONT_TYPE0_TT,
    HPDF_FONT_CID_TYPE0,
    HPDF_FONT_CID_TYPE2,
    HPDF_FONT_MMTYPE1
} HPDF_FontType;
typedef HPDF_Dict HPDF_Font;
typedef HPDF_TextWidth
(*HPDF_Font_TextWidths_Func) (HPDF_Font font,
                             const HPDF_BYTE *text,
                             HPDF_UINT len);
typedef HPDF_UINT
(*HPDF_Font_MeasureText_Func) (HPDF_Font font,
                              const HPDF_BYTE *text,
                              HPDF_UINT len,
                              HPDF_REAL width,
                              HPDF_REAL fontsize,
                              HPDF_REAL charspace,
                              HPDF_REAL wordspace,
                              HPDF_BOOL wordwrap,
                              HPDF_REAL *real_width);
typedef struct _HPDF_FontAttr_Rec *HPDF_FontAttr;
typedef struct _HPDF_FontAttr_Rec {
    HPDF_FontType type;
    HPDF_WritingMode writing_mode;
    HPDF_Font_TextWidths_Func text_width_fn;
    HPDF_Font_MeasureText_Func measure_text_fn;
    HPDF_FontDef fontdef;
    HPDF_Encoder encoder;
    HPDF_INT16* widths;
    HPDF_BYTE* used;
    HPDF_Xref xref;
    HPDF_Font descendant_font;
    HPDF_Dict map_stream;
    HPDF_Dict cmap_stream;
} HPDF_FontAttr_Rec;
HPDF_Font
HPDF_Type1Font_New (HPDF_MMgr mmgr,
                     HPDF_FontDef fontdef,
                     HPDF_Encoder encoder,
                     HPDF_Xref xref);
HPDF_Font
HPDF_TTFont_New (HPDF_MMgr mmgr,
                  HPDF_FontDef fontdef,
                  HPDF_Encoder encoder,
                  HPDF_Xref xref);
HPDF_Font
HPDF_Type0Font_New (HPDF_MMgr mmgr,
                     HPDF_FontDef fontdef,
                     HPDF_Encoder encoder,
                     HPDF_Xref xref);
HPDF_BOOL
HPDF_Font_Validate (HPDF_Font font);
typedef struct _HPDF_GState_Rec *HPDF_GState;
typedef struct _HPDF_GState_Rec {
    HPDF_TransMatrix trans_matrix;
    HPDF_REAL line_width;
    HPDF_LineCap line_cap;
    HPDF_LineJoin line_join;
    HPDF_REAL miter_limit;
    HPDF_DashMode dash_mode;
    HPDF_REAL flatness;
    HPDF_REAL char_space;
    HPDF_REAL word_space;
    HPDF_REAL h_scalling;
    HPDF_REAL text_leading;
    HPDF_TextRenderingMode rendering_mode;
    HPDF_REAL text_rise;
    HPDF_ColorSpace cs_fill;
    HPDF_ColorSpace cs_stroke;
    HPDF_RGBColor rgb_fill;
    HPDF_RGBColor rgb_stroke;
    HPDF_CMYKColor cmyk_fill;
    HPDF_CMYKColor cmyk_stroke;
    HPDF_REAL gray_fill;
    HPDF_REAL gray_stroke;
    HPDF_Font font;
    HPDF_REAL font_size;
    HPDF_WritingMode writing_mode;
    HPDF_GState prev;
    HPDF_UINT depth;
} HPDF_GState_Rec;
HPDF_GState
HPDF_GState_New (HPDF_MMgr mmgr,
                  HPDF_GState current);
HPDF_GState
HPDF_GState_Free (HPDF_MMgr mmgr,
                   HPDF_GState gstate);
HPDF_Dict
HPDF_ExtGState_New (HPDF_MMgr mmgr,
                     HPDF_Xref xref);
HPDF_BOOL
HPDF_ExtGState_Validate (HPDF_ExtGState ext_gstate);
HPDF_Pages
HPDF_Pages_New (HPDF_MMgr mmgr,
                 HPDF_Pages parent,
                 HPDF_Xref xref);
HPDF_BOOL
HPDF_Pages_Validate (HPDF_Pages pages);
HPDF_STATUS
HPDF_Pages_AddKids (HPDF_Pages parent,
                      HPDF_Dict kid);
HPDF_STATUS
HPDF_Page_InsertBefore (HPDF_Page page,
                         HPDF_Page target);
typedef struct _HPDF_PageAttr_Rec *HPDF_PageAttr;
typedef struct _HPDF_PageAttr_Rec {
    HPDF_Pages parent;
    HPDF_Dict fonts;
    HPDF_Dict xobjects;
    HPDF_Dict ext_gstates;
    HPDF_GState gstate;
    HPDF_Point str_pos;
    HPDF_Point cur_pos;
    HPDF_Point text_pos;
    HPDF_TransMatrix text_matrix;
    HPDF_UINT16 gmode;
    HPDF_Dict contents;
    HPDF_Stream stream;
    HPDF_Xref xref;
    HPDF_UINT compression_mode;
 HPDF_PDFVer *ver;
} HPDF_PageAttr_Rec;
HPDF_BOOL
HPDF_Page_Validate (HPDF_Page page);
HPDF_Page
HPDF_Page_New (HPDF_MMgr mmgr,
                HPDF_Xref xref);
void*
HPDF_Page_GetInheritableItem (HPDF_Page page,
                               const char *key,
                               HPDF_UINT16 obj_class);
const char*
HPDF_Page_GetXObjectName (HPDF_Page page,
                           HPDF_XObject xobj);
const char*
HPDF_Page_GetLocalFontName (HPDF_Page page,
                             HPDF_Font font);
const char*
HPDF_Page_GetExtGStateName (HPDF_Page page,
                             HPDF_ExtGState gstate);
HPDF_Box
HPDF_Page_GetMediaBox (HPDF_Page page);
HPDF_STATUS
HPDF_Page_SetBoxValue (HPDF_Page page,
                       const char *name,
                       HPDF_UINT index,
                       HPDF_REAL value);
void
HPDF_Page_SetFilter (HPDF_Page page,
                      HPDF_UINT filter);
HPDF_STATUS
HPDF_Page_CheckState (HPDF_Page page,
                       HPDF_UINT mode);
HPDF_Outline
HPDF_OutlineRoot_New (HPDF_MMgr mmgr,
                       HPDF_Xref xref);
HPDF_Outline
HPDF_Outline_New (HPDF_MMgr mmgr,
                   HPDF_Outline parent,
                   const char *title,
                   HPDF_Encoder encoder,
                   HPDF_Xref xref);
HPDF_Outline
HPDF_Outline_GetFirst (HPDF_Outline outline);
HPDF_Outline
HPDF_Outline_GetLast (HPDF_Outline outline);
HPDF_Outline
HPDF_Outline_GetPrev(HPDF_Outline outline);
HPDF_Outline
HPDF_Outline_GetNext (HPDF_Outline outline);
HPDF_Outline
HPDF_Outline_GetParent (HPDF_Outline outline);
HPDF_BOOL
HPDF_Outline_GetOpened (HPDF_Outline outline);
HPDF_BOOL
HPDF_Outline_Validate (HPDF_Outline obj);
typedef struct _HPDF_Doc_Rec {
    HPDF_UINT32 sig_bytes;
    HPDF_PDFVer pdf_version;
    HPDF_MMgr mmgr;
    HPDF_Catalog catalog;
    HPDF_Outline outlines;
    HPDF_Xref xref;
    HPDF_Pages root_pages;
    HPDF_Pages cur_pages;
    HPDF_Page cur_page;
    HPDF_List page_list;
    HPDF_Error_Rec error;
    HPDF_Dict info;
    HPDF_Dict trailer;
    HPDF_List font_mgr;
    HPDF_BYTE ttfont_tag[6];
    HPDF_List fontdef_list;
    HPDF_List encoder_list;
    HPDF_Encoder cur_encoder;
    HPDF_BOOL compression_mode;
    HPDF_BOOL encrypt_on;
    HPDF_EncryptDict encrypt_dict;
    HPDF_Encoder def_encoder;
    HPDF_UINT page_per_pages;
    HPDF_UINT cur_page_num;
    HPDF_Stream stream;
} HPDF_Doc_Rec;
typedef struct _HPDF_Doc_Rec *HPDF_Doc;
HPDF_Encoder
HPDF_Doc_FindEncoder (HPDF_Doc pdf,
                      const char *encoding_name);
HPDF_FontDef
HPDF_Doc_FindFontDef (HPDF_Doc pdf,
                      const char *font_name);
HPDF_Font
HPDF_Doc_FindFont (HPDF_Doc pdf,
                    const char *font_name,
                    const char *encoding_name);
HPDF_BOOL
HPDF_Doc_Validate (HPDF_Doc pdf);
HPDF_Pages
HPDF_Doc_GetCurrentPages (HPDF_Doc pdf);
HPDF_Pages
HPDF_Doc_AddPagesTo (HPDF_Doc pdf,
                      HPDF_Pages parent);
HPDF_STATUS
HPDF_Doc_SetCurrentPages (HPDF_Doc pdf,
                           HPDF_Pages pages);
HPDF_STATUS
HPDF_Doc_SetCurrentPage (HPDF_Doc pdf,
                          HPDF_Page page);
HPDF_FontDef
HPDF_GetFontDef (HPDF_Doc pdf,
                 const char *font_name);
HPDF_STATUS
HPDF_Doc_RegisterFontDef (HPDF_Doc pdf,
                           HPDF_FontDef fontdef);
HPDF_STATUS
HPDF_Doc_RegisterEncoder (HPDF_Doc pdf,
                           HPDF_Encoder encoder);
HPDF_STATUS
HPDF_Doc_SetEncryptOn (HPDF_Doc pdf);
HPDF_STATUS
HPDF_Doc_SetEncryptOff (HPDF_Doc pdf);
HPDF_STATUS
HPDF_Doc_PrepareEncryption (HPDF_Doc pdf);
HPDF_STATUS
HPDF_PDFA_AppendOutputIntents(HPDF_Doc pdf, const char *iccname, HPDF_Dict iccdict);
HPDF_STATUS
HPDF_PDFA_SetPDFAConformance (HPDF_Doc pdf,
         HPDF_PDFAType pdfatype);
HPDF_STATUS
HPDF_PDFA_GenerateID(HPDF_Doc);
const char *
HPDF_GetVersion (void);
HPDF_Doc
HPDF_NewEx (HPDF_Error_Handler user_error_fn,
             HPDF_Alloc_Func user_alloc_fn,
             HPDF_Free_Func user_free_fn,
             HPDF_UINT mem_pool_buf_size,
             void *user_data);
HPDF_Doc
HPDF_New (HPDF_Error_Handler user_error_fn,
           void *user_data);
HPDF_STATUS
HPDF_SetErrorHandler (HPDF_Doc pdf,
                       HPDF_Error_Handler user_error_fn);
void
HPDF_Free (HPDF_Doc pdf);
HPDF_STATUS
HPDF_NewDoc (HPDF_Doc pdf);
void
HPDF_FreeDoc (HPDF_Doc pdf);
HPDF_BOOL
HPDF_HasDoc (HPDF_Doc pdf);
void
HPDF_FreeDocAll (HPDF_Doc pdf);
HPDF_STATUS
HPDF_SaveToStream (HPDF_Doc pdf);
HPDF_STATUS
HPDF_GetContents (HPDF_Doc pdf,
                   HPDF_BYTE *buf,
                 HPDF_UINT32 *size);
HPDF_UINT32
HPDF_GetStreamSize (HPDF_Doc pdf);
HPDF_STATUS
HPDF_ReadFromStream (HPDF_Doc pdf,
                      HPDF_BYTE *buf,
                      HPDF_UINT32 *size);
HPDF_STATUS
HPDF_ResetStream (HPDF_Doc pdf);
HPDF_STATUS
HPDF_SaveToFile (HPDF_Doc pdf,
                  const char *file_name);
HPDF_STATUS
HPDF_GetError (HPDF_Doc pdf);
HPDF_STATUS
HPDF_GetErrorDetail (HPDF_Doc pdf);
void
HPDF_ResetError (HPDF_Doc pdf);
HPDF_STATUS
HPDF_CheckError (HPDF_Error error);
HPDF_STATUS
HPDF_SetPagesConfiguration (HPDF_Doc pdf,
                             HPDF_UINT page_per_pages);
HPDF_Page
HPDF_GetPageByIndex (HPDF_Doc pdf,
                      HPDF_UINT index);
HPDF_PageLayout
HPDF_GetPageLayout (HPDF_Doc pdf);
HPDF_STATUS
HPDF_SetPageLayout (HPDF_Doc pdf,
                     HPDF_PageLayout layout);
HPDF_PageMode
HPDF_GetPageMode (HPDF_Doc pdf);
HPDF_STATUS
HPDF_SetPageMode (HPDF_Doc pdf,
                   HPDF_PageMode mode);
HPDF_UINT
HPDF_GetViewerPreference (HPDF_Doc pdf);
HPDF_STATUS
HPDF_SetViewerPreference (HPDF_Doc pdf,
                           HPDF_UINT value);
HPDF_STATUS
HPDF_SetOpenAction (HPDF_Doc pdf,
                     HPDF_Destination open_action);
HPDF_Page
HPDF_GetCurrentPage (HPDF_Doc pdf);
HPDF_Page
HPDF_AddPage (HPDF_Doc pdf);
HPDF_Page
HPDF_InsertPage (HPDF_Doc pdf,
                  HPDF_Page page);
HPDF_STATUS
HPDF_Page_SetWidth (HPDF_Page page,
                     HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetHeight (HPDF_Page page,
                      HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetSize (HPDF_Page page,
                    HPDF_PageSizes size,
                    HPDF_PageDirection direction);
HPDF_STATUS
HPDF_Page_SetRotate (HPDF_Page page,
                      HPDF_UINT16 angle);
HPDF_STATUS
HPDF_Page_SetZoom (HPDF_Page page,
                    HPDF_REAL zoom);
HPDF_Font
HPDF_GetFont (HPDF_Doc pdf,
               const char *font_name,
               const char *encoding_name);
const char*
HPDF_LoadType1FontFromFile (HPDF_Doc pdf,
                             const char *afm_file_name,
                             const char *data_file_name);
HPDF_FontDef
HPDF_GetTTFontDefFromFile (HPDF_Doc pdf,
                           const char *file_name,
                           HPDF_BOOL embedding);
const char*
HPDF_LoadTTFontFromFile (HPDF_Doc pdf,
                         const char *file_name,
                         HPDF_BOOL embedding);
const char*
HPDF_LoadTTFontFromFile2 (HPDF_Doc pdf,
                          const char *file_name,
                          HPDF_UINT index,
                          HPDF_BOOL embedding);
HPDF_STATUS
HPDF_AddPageLabel (HPDF_Doc pdf,
                    HPDF_UINT page_num,
                    HPDF_PageNumStyle style,
                    HPDF_UINT first_page,
                    const char *prefix);
HPDF_STATUS
HPDF_UseJPFonts (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseKRFonts (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseCNSFonts (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseCNTFonts (HPDF_Doc pdf);
HPDF_Outline
HPDF_CreateOutline (HPDF_Doc pdf,
                     HPDF_Outline parent,
                     const char *title,
                     HPDF_Encoder encoder);
HPDF_STATUS
HPDF_Outline_SetOpened (HPDF_Outline outline,
                         HPDF_BOOL opened);
HPDF_STATUS
HPDF_Outline_SetDestination (HPDF_Outline outline,
                             HPDF_Destination dst);
HPDF_Destination
HPDF_Page_CreateDestination (HPDF_Page page);
HPDF_STATUS
HPDF_Destination_SetXYZ (HPDF_Destination dst,
                          HPDF_REAL left,
                          HPDF_REAL top,
                          HPDF_REAL zoom);
HPDF_STATUS
HPDF_Destination_SetFit (HPDF_Destination dst);
HPDF_STATUS
HPDF_Destination_SetFitH (HPDF_Destination dst,
                           HPDF_REAL top);
HPDF_STATUS
HPDF_Destination_SetFitV (HPDF_Destination dst,
                           HPDF_REAL left);
HPDF_STATUS
HPDF_Destination_SetFitR (HPDF_Destination dst,
                           HPDF_REAL left,
                           HPDF_REAL bottom,
                           HPDF_REAL right,
                           HPDF_REAL top);
HPDF_STATUS
HPDF_Destination_SetFitB (HPDF_Destination dst);
HPDF_STATUS
HPDF_Destination_SetFitBH (HPDF_Destination dst,
                            HPDF_REAL top);
HPDF_STATUS
HPDF_Destination_SetFitBV (HPDF_Destination dst,
                            HPDF_REAL left);
HPDF_Encoder
HPDF_GetEncoder (HPDF_Doc pdf,
                  const char *encoding_name);
HPDF_Encoder
HPDF_GetCurrentEncoder (HPDF_Doc pdf);
HPDF_STATUS
HPDF_SetCurrentEncoder (HPDF_Doc pdf,
                         const char *encoding_name);
HPDF_EncoderType
HPDF_Encoder_GetType (HPDF_Encoder encoder);
HPDF_ByteType
HPDF_Encoder_GetByteType (HPDF_Encoder encoder,
                           const char *text,
                           HPDF_UINT index);
HPDF_UNICODE
HPDF_Encoder_GetUnicode (HPDF_Encoder encoder,
                          HPDF_UINT16 code);
HPDF_WritingMode
HPDF_Encoder_GetWritingMode (HPDF_Encoder encoder);
HPDF_STATUS
HPDF_UseJPEncodings (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseKREncodings (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseCNSEncodings (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseCNTEncodings (HPDF_Doc pdf);
HPDF_STATUS
HPDF_UseUTFEncodings (HPDF_Doc pdf);
HPDF_Annotation
HPDF_Page_Create3DAnnot (HPDF_Page page,
       HPDF_Rect rect,
       HPDF_U3D u3d);
HPDF_Annotation
HPDF_Page_CreateTextAnnot (HPDF_Page page,
                            HPDF_Rect rect,
                            const char *text,
                            HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateFreeTextAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateLineAnnot (HPDF_Page page,
       const char *text,
       HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateLinkAnnot (HPDF_Page page,
                            HPDF_Rect rect,
                            HPDF_Destination dst);
HPDF_Annotation
HPDF_Page_CreateURILinkAnnot (HPDF_Page page,
                               HPDF_Rect rect,
                               const char *uri);
HPDF_Annotation
HPDF_Page_CreateTextMarkupAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder,
        HPDF_AnnotType subType);
HPDF_Annotation
HPDF_Page_CreateHighlightAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateUnderlineAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateSquigglyAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateStrikeOutAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreatePopupAnnot ( HPDF_Page page,
        HPDF_Rect rect,
        HPDF_Annotation parent);
HPDF_Annotation
HPDF_Page_CreateStampAnnot ( HPDF_Page page,
        HPDF_Rect rect,
        HPDF_StampAnnotName name,
        const char* text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateProjectionAnnot(HPDF_Page page,
        HPDF_Rect rect,
        const char* text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateSquareAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_Annotation
HPDF_Page_CreateCircleAnnot (HPDF_Page page,
        HPDF_Rect rect,
        const char *text,
        HPDF_Encoder encoder);
HPDF_STATUS
HPDF_LinkAnnot_SetHighlightMode (HPDF_Annotation annot,
                                  HPDF_AnnotHighlightMode mode);
HPDF_STATUS
HPDF_LinkAnnot_SetBorderStyle (HPDF_Annotation annot,
                                HPDF_REAL width,
                                HPDF_UINT16 dash_on,
                                HPDF_UINT16 dash_off);
HPDF_STATUS
HPDF_TextAnnot_SetIcon (HPDF_Annotation annot,
                         HPDF_AnnotIcon icon);
HPDF_STATUS
HPDF_TextAnnot_SetOpened (HPDF_Annotation annot,
                          HPDF_BOOL opened);
HPDF_STATUS
HPDF_Annot_SetRGBColor (HPDF_Annotation annot, HPDF_RGBColor color);
HPDF_STATUS
HPDF_Annot_SetCMYKColor (HPDF_Annotation annot, HPDF_CMYKColor color);
HPDF_STATUS
HPDF_Annot_SetGrayColor (HPDF_Annotation annot, HPDF_REAL color);
HPDF_STATUS
HPDF_Annot_SetNoColor (HPDF_Annotation annot);
HPDF_STATUS
HPDF_MarkupAnnot_SetTitle (HPDF_Annotation annot, const char* name);
HPDF_STATUS
HPDF_MarkupAnnot_SetSubject (HPDF_Annotation annot, const char* name);
HPDF_STATUS
HPDF_MarkupAnnot_SetCreationDate (HPDF_Annotation annot, HPDF_Date value);
HPDF_STATUS
HPDF_MarkupAnnot_SetTransparency (HPDF_Annotation annot, HPDF_REAL value);
HPDF_STATUS
HPDF_MarkupAnnot_SetIntent (HPDF_Annotation annot, HPDF_AnnotIntent intent);
HPDF_STATUS
HPDF_MarkupAnnot_SetPopup (HPDF_Annotation annot, HPDF_Annotation popup);
HPDF_STATUS
HPDF_MarkupAnnot_SetRectDiff (HPDF_Annotation annot, HPDF_Rect rect);
HPDF_STATUS
HPDF_MarkupAnnot_SetCloudEffect (HPDF_Annotation annot, HPDF_INT cloudIntensity);
HPDF_STATUS
HPDF_MarkupAnnot_SetInteriorRGBColor (HPDF_Annotation annot, HPDF_RGBColor color);
HPDF_STATUS
HPDF_MarkupAnnot_SetInteriorCMYKColor (HPDF_Annotation annot, HPDF_CMYKColor color);
HPDF_STATUS
HPDF_MarkupAnnot_SetInteriorGrayColor (HPDF_Annotation annot, HPDF_REAL color);
HPDF_STATUS
HPDF_MarkupAnnot_SetInteriorTransparent (HPDF_Annotation annot);
HPDF_STATUS
HPDF_TextMarkupAnnot_SetQuadPoints ( HPDF_Annotation annot, HPDF_Point lb, HPDF_Point rb, HPDF_Point rt, HPDF_Point lt);
HPDF_STATUS
HPDF_Annot_Set3DView ( HPDF_MMgr mmgr,
       HPDF_Annotation annot,
       HPDF_Annotation annot3d,
       HPDF_Dict view);
HPDF_STATUS
HPDF_PopupAnnot_SetOpened (HPDF_Annotation annot,
                            HPDF_BOOL opened);
HPDF_STATUS
HPDF_FreeTextAnnot_SetLineEndingStyle (HPDF_Annotation annot, HPDF_LineAnnotEndingStyle startStyle, HPDF_LineAnnotEndingStyle endStyle);
HPDF_STATUS
HPDF_FreeTextAnnot_Set3PointCalloutLine (HPDF_Annotation annot, HPDF_Point startPoint, HPDF_Point kneePoint, HPDF_Point endPoint);
HPDF_STATUS
HPDF_FreeTextAnnot_Set2PointCalloutLine (HPDF_Annotation annot, HPDF_Point startPoint, HPDF_Point endPoint);
HPDF_STATUS
HPDF_FreeTextAnnot_SetDefaultStyle (HPDF_Annotation annot, const char* style);
HPDF_STATUS
HPDF_LineAnnot_SetPosition (HPDF_Annotation annot,
       HPDF_Point startPoint, HPDF_LineAnnotEndingStyle startStyle,
       HPDF_Point endPoint, HPDF_LineAnnotEndingStyle endStyle);
HPDF_STATUS
HPDF_LineAnnot_SetLeader (HPDF_Annotation annot, HPDF_INT leaderLen, HPDF_INT leaderExtLen, HPDF_INT leaderOffsetLen);
HPDF_STATUS
HPDF_LineAnnot_SetCaption (HPDF_Annotation annot, HPDF_BOOL showCaption, HPDF_LineAnnotCapPosition position, HPDF_INT horzOffset, HPDF_INT vertOffset);
HPDF_STATUS
HPDF_Annotation_SetBorderStyle (HPDF_Annotation annot,
                                 HPDF_BSSubtype subtype,
                                 HPDF_REAL width,
                                 HPDF_UINT16 dash_on,
                                 HPDF_UINT16 dash_off,
                                 HPDF_UINT16 dash_phase);
HPDF_STATUS
HPDF_ProjectionAnnot_SetExData(HPDF_Annotation annot, HPDF_ExData exdata);
HPDF_3DMeasure
HPDF_Page_Create3DC3DMeasure(HPDF_Page page,
              HPDF_Point3D firstanchorpoint,
              HPDF_Point3D textanchorpoint
              );
HPDF_3DMeasure
HPDF_Page_CreatePD33DMeasure(HPDF_Page page,
              HPDF_Point3D annotationPlaneNormal,
              HPDF_Point3D firstAnchorPoint,
                 HPDF_Point3D secondAnchorPoint,
              HPDF_Point3D leaderLinesDirection,
                 HPDF_Point3D measurementValuePoint,
              HPDF_Point3D textYDirection,
              HPDF_REAL value,
        const char* unitsString
               );
HPDF_STATUS
HPDF_3DMeasure_SetName(HPDF_3DMeasure measure,
        const char* name);
HPDF_STATUS
HPDF_3DMeasure_SetColor(HPDF_3DMeasure measure,
         HPDF_RGBColor color);
HPDF_STATUS
HPDF_3DMeasure_SetTextSize(HPDF_3DMeasure measure,
         HPDF_REAL textsize);
HPDF_STATUS
HPDF_3DC3DMeasure_SetTextBoxSize(HPDF_3DMeasure measure,
        HPDF_INT32 x,
        HPDF_INT32 y);
HPDF_STATUS
HPDF_3DC3DMeasure_SetText(HPDF_3DMeasure measure,
        const char* text,
        HPDF_Encoder encoder);
HPDF_STATUS
HPDF_3DC3DMeasure_SetProjectionAnotation(HPDF_3DMeasure measure,
           HPDF_Annotation projectionanotation);
HPDF_ExData
HPDF_Page_Create3DAnnotExData(HPDF_Page page );
HPDF_STATUS
HPDF_3DAnnotExData_Set3DMeasurement(HPDF_ExData exdata, HPDF_3DMeasure measure);
HPDF_Dict
HPDF_Page_Create3DView (HPDF_Page page,
         HPDF_U3D u3d,
         HPDF_Annotation annot3d,
         const char *name);
HPDF_STATUS
HPDF_3DView_Add3DC3DMeasure(HPDF_Dict view,
       HPDF_3DMeasure measure);
HPDF_Image
HPDF_LoadPngImageFromMem (HPDF_Doc pdf,
                    const HPDF_BYTE *buffer,
                          HPDF_UINT size);
HPDF_Image
HPDF_LoadPngImageFromFile (HPDF_Doc pdf,
                           const char *filename);
HPDF_Image
HPDF_LoadPngImageFromFile2 (HPDF_Doc pdf,
                            const char *filename);
HPDF_Image
HPDF_LoadJpegImageFromFile (HPDF_Doc pdf,
                            const char *filename);
HPDF_Image
HPDF_LoadJpegImageFromMem (HPDF_Doc pdf,
                      const HPDF_BYTE *buffer,
                            HPDF_UINT size);
HPDF_Image
HPDF_LoadU3DFromFile (HPDF_Doc pdf,
                            const char *filename);
HPDF_Image
HPDF_Image_LoadRaw1BitImageFromMem (HPDF_Doc pdf,
                           const HPDF_BYTE *buf,
                          HPDF_UINT width,
                          HPDF_UINT height,
                          HPDF_UINT line_width,
                          HPDF_BOOL black_is1,
                          HPDF_BOOL top_is_first);
HPDF_Image
HPDF_LoadRawImageFromFile (HPDF_Doc pdf,
                            const char *filename,
                            HPDF_UINT width,
                            HPDF_UINT height,
                            HPDF_ColorSpace color_space);
HPDF_Image
HPDF_LoadRawImageFromMem (HPDF_Doc pdf,
                           const HPDF_BYTE *buf,
                           HPDF_UINT width,
                           HPDF_UINT height,
                           HPDF_ColorSpace color_space,
                           HPDF_UINT bits_per_component);
HPDF_STATUS
HPDF_Image_AddSMask (HPDF_Image image,
                      HPDF_Image smask);
HPDF_Point
HPDF_Image_GetSize (HPDF_Image image);
HPDF_STATUS
HPDF_Image_GetSize2 (HPDF_Image image, HPDF_Point *size);
HPDF_UINT
HPDF_Image_GetWidth (HPDF_Image image);
HPDF_UINT
HPDF_Image_GetHeight (HPDF_Image image);
HPDF_UINT
HPDF_Image_GetBitsPerComponent (HPDF_Image image);
const char*
HPDF_Image_GetColorSpace (HPDF_Image image);
HPDF_STATUS
HPDF_Image_SetColorMask (HPDF_Image image,
                         HPDF_UINT rmin,
                         HPDF_UINT rmax,
                         HPDF_UINT gmin,
                         HPDF_UINT gmax,
                         HPDF_UINT bmin,
                         HPDF_UINT bmax);
HPDF_STATUS
HPDF_Image_SetMaskImage (HPDF_Image image,
                          HPDF_Image mask_image);
HPDF_STATUS
HPDF_SetInfoAttr (HPDF_Doc pdf,
                  HPDF_InfoType type,
                  const char *value);
const char*
HPDF_GetInfoAttr (HPDF_Doc pdf,
                  HPDF_InfoType type);
HPDF_STATUS
HPDF_SetInfoDateAttr (HPDF_Doc pdf,
                      HPDF_InfoType type,
                      HPDF_Date value);
HPDF_STATUS
HPDF_SetPassword (HPDF_Doc pdf,
                   const char *owner_passwd,
                   const char *user_passwd);
HPDF_STATUS
HPDF_SetPermission (HPDF_Doc pdf,
                     HPDF_UINT permission);
HPDF_STATUS
HPDF_SetEncryptionMode (HPDF_Doc pdf,
                         HPDF_EncryptMode mode,
                         HPDF_UINT key_len);
HPDF_STATUS
HPDF_SetCompressionMode (HPDF_Doc pdf,
                          HPDF_UINT mode);
const char*
HPDF_Font_GetFontName (HPDF_Font font);
const char*
HPDF_Font_GetEncodingName (HPDF_Font font);
HPDF_INT
HPDF_Font_GetUnicodeWidth (HPDF_Font font,
                            HPDF_UNICODE code);
HPDF_Box
HPDF_Font_GetBBox (HPDF_Font font);
HPDF_INT
HPDF_Font_GetAscent (HPDF_Font font);
HPDF_INT
HPDF_Font_GetDescent (HPDF_Font font);
HPDF_UINT
HPDF_Font_GetXHeight (HPDF_Font font);
HPDF_UINT
HPDF_Font_GetCapHeight (HPDF_Font font);
HPDF_TextWidth
HPDF_Font_TextWidth (HPDF_Font font,
                      const HPDF_BYTE *text,
                      HPDF_UINT len);
HPDF_UINT
HPDF_Font_MeasureText (HPDF_Font font,
                       const HPDF_BYTE *text,
                       HPDF_UINT len,
                       HPDF_REAL width,
                       HPDF_REAL font_size,
                       HPDF_REAL char_space,
                       HPDF_REAL word_space,
                       HPDF_BOOL wordwrap,
                       HPDF_REAL *real_width);
HPDF_EmbeddedFile
HPDF_AttachFile (HPDF_Doc pdf,
                  const char *file);
HPDF_ExtGState
HPDF_CreateExtGState (HPDF_Doc pdf);
HPDF_STATUS
HPDF_ExtGState_SetAlphaStroke (HPDF_ExtGState ext_gstate,
                                HPDF_REAL value);
HPDF_STATUS
HPDF_ExtGState_SetAlphaFill (HPDF_ExtGState ext_gstate,
                              HPDF_REAL value);
HPDF_STATUS
HPDF_ExtGState_SetBlendMode (HPDF_ExtGState ext_gstate,
                              HPDF_BlendMode mode);
HPDF_REAL
HPDF_Page_TextWidth (HPDF_Page page,
                      const char *text);
HPDF_UINT
HPDF_Page_MeasureText (HPDF_Page page,
                        const char *text,
                        HPDF_REAL width,
                        HPDF_BOOL wordwrap,
                        HPDF_REAL *real_width);
HPDF_REAL
HPDF_Page_GetWidth (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetHeight (HPDF_Page page);
HPDF_UINT16
HPDF_Page_GetGMode (HPDF_Page page);
HPDF_Point
HPDF_Page_GetCurrentPos (HPDF_Page page);
HPDF_STATUS
HPDF_Page_GetCurrentPos2 (HPDF_Page page,
                           HPDF_Point *pos);
HPDF_Point
HPDF_Page_GetCurrentTextPos (HPDF_Page page);
HPDF_STATUS
HPDF_Page_GetCurrentTextPos2 (HPDF_Page page,
                               HPDF_Point *pos);
HPDF_Font
HPDF_Page_GetCurrentFont (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetCurrentFontSize (HPDF_Page page);
HPDF_TransMatrix
HPDF_Page_GetTransMatrix (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetLineWidth (HPDF_Page page);
HPDF_LineCap
HPDF_Page_GetLineCap (HPDF_Page page);
HPDF_LineJoin
HPDF_Page_GetLineJoin (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetMiterLimit (HPDF_Page page);
HPDF_DashMode
HPDF_Page_GetDash (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetFlat (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetCharSpace (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetWordSpace (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetHorizontalScalling (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetTextLeading (HPDF_Page page);
HPDF_TextRenderingMode
HPDF_Page_GetTextRenderingMode (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetTextRaise (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetTextRise (HPDF_Page page);
HPDF_RGBColor
HPDF_Page_GetRGBFill (HPDF_Page page);
HPDF_RGBColor
HPDF_Page_GetRGBStroke (HPDF_Page page);
HPDF_CMYKColor
HPDF_Page_GetCMYKFill (HPDF_Page page);
HPDF_CMYKColor
HPDF_Page_GetCMYKStroke (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetGrayFill (HPDF_Page page);
HPDF_REAL
HPDF_Page_GetGrayStroke (HPDF_Page page);
HPDF_ColorSpace
HPDF_Page_GetStrokingColorSpace (HPDF_Page page);
HPDF_ColorSpace
HPDF_Page_GetFillingColorSpace (HPDF_Page page);
HPDF_TransMatrix
HPDF_Page_GetTextMatrix (HPDF_Page page);
HPDF_UINT
HPDF_Page_GetGStateDepth (HPDF_Page page);
HPDF_STATUS
HPDF_Page_SetLineWidth (HPDF_Page page,
                         HPDF_REAL line_width);
HPDF_STATUS
HPDF_Page_SetLineCap (HPDF_Page page,
                       HPDF_LineCap line_cap);
HPDF_STATUS
HPDF_Page_SetLineJoin (HPDF_Page page,
                        HPDF_LineJoin line_join);
HPDF_STATUS
HPDF_Page_SetMiterLimit (HPDF_Page page,
                          HPDF_REAL miter_limit);
HPDF_STATUS
HPDF_Page_SetDash (HPDF_Page page,
                    const HPDF_UINT16 *dash_ptn,
                    HPDF_UINT num_param,
                    HPDF_UINT phase);
HPDF_STATUS
HPDF_Page_SetFlat (HPDF_Page page,
                    HPDF_REAL flatness);
HPDF_STATUS
HPDF_Page_SetExtGState (HPDF_Page page,
                         HPDF_ExtGState ext_gstate);
HPDF_STATUS
HPDF_Page_GSave (HPDF_Page page);
HPDF_STATUS
HPDF_Page_GRestore (HPDF_Page page);
HPDF_STATUS
HPDF_Page_Concat (HPDF_Page page,
                   HPDF_REAL a,
                   HPDF_REAL b,
                   HPDF_REAL c,
                   HPDF_REAL d,
                   HPDF_REAL x,
                   HPDF_REAL y);
HPDF_STATUS
HPDF_Page_MoveTo (HPDF_Page page,
                   HPDF_REAL x,
                   HPDF_REAL y);
HPDF_STATUS
HPDF_Page_LineTo (HPDF_Page page,
                   HPDF_REAL x,
                   HPDF_REAL y);
HPDF_STATUS
HPDF_Page_CurveTo (HPDF_Page page,
                    HPDF_REAL x1,
                    HPDF_REAL y1,
                    HPDF_REAL x2,
                    HPDF_REAL y2,
                    HPDF_REAL x3,
                    HPDF_REAL y3);
HPDF_STATUS
HPDF_Page_CurveTo2 (HPDF_Page page,
                     HPDF_REAL x2,
                     HPDF_REAL y2,
                     HPDF_REAL x3,
                     HPDF_REAL y3);
HPDF_STATUS
HPDF_Page_CurveTo3 (HPDF_Page page,
                     HPDF_REAL x1,
                     HPDF_REAL y1,
                     HPDF_REAL x3,
                     HPDF_REAL y3);
HPDF_STATUS
HPDF_Page_ClosePath (HPDF_Page page);
HPDF_STATUS
HPDF_Page_Rectangle (HPDF_Page page,
                      HPDF_REAL x,
                      HPDF_REAL y,
                      HPDF_REAL width,
                      HPDF_REAL height);
HPDF_STATUS
HPDF_Page_Stroke (HPDF_Page page);
HPDF_STATUS
HPDF_Page_ClosePathStroke (HPDF_Page page);
HPDF_STATUS
HPDF_Page_Fill (HPDF_Page page);
HPDF_STATUS
HPDF_Page_Eofill (HPDF_Page page);
HPDF_STATUS
HPDF_Page_FillStroke (HPDF_Page page);
HPDF_STATUS
HPDF_Page_EofillStroke (HPDF_Page page);
HPDF_STATUS
HPDF_Page_ClosePathFillStroke (HPDF_Page page);
HPDF_STATUS
HPDF_Page_ClosePathEofillStroke (HPDF_Page page);
HPDF_STATUS
HPDF_Page_EndPath (HPDF_Page page);
HPDF_STATUS
HPDF_Page_Clip (HPDF_Page page);
HPDF_STATUS
HPDF_Page_Eoclip (HPDF_Page page);
HPDF_STATUS
HPDF_Page_BeginText (HPDF_Page page);
HPDF_STATUS
HPDF_Page_EndText (HPDF_Page page);
HPDF_STATUS
HPDF_Page_SetCharSpace (HPDF_Page page,
                         HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetWordSpace (HPDF_Page page,
                         HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetHorizontalScalling (HPDF_Page page,
                                  HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetTextLeading (HPDF_Page page,
                           HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetFontAndSize (HPDF_Page page,
                           HPDF_Font font,
                           HPDF_REAL size);
HPDF_STATUS
HPDF_Page_SetTextRenderingMode (HPDF_Page page,
                                 HPDF_TextRenderingMode mode);
HPDF_STATUS
HPDF_Page_SetTextRise (HPDF_Page page,
                        HPDF_REAL value);
HPDF_STATUS
HPDF_Page_SetTextRaise (HPDF_Page page,
                         HPDF_REAL value);
HPDF_STATUS
HPDF_Page_MoveTextPos (HPDF_Page page,
                        HPDF_REAL x,
                        HPDF_REAL y);
HPDF_STATUS
HPDF_Page_MoveTextPos2 (HPDF_Page page,
                         HPDF_REAL x,
                         HPDF_REAL y);
HPDF_STATUS
HPDF_Page_SetTextMatrix (HPDF_Page page,
                          HPDF_REAL a,
                          HPDF_REAL b,
                          HPDF_REAL c,
                          HPDF_REAL d,
                          HPDF_REAL x,
                          HPDF_REAL y);
HPDF_STATUS
HPDF_Page_MoveToNextLine (HPDF_Page page);
HPDF_STATUS
HPDF_Page_ShowText (HPDF_Page page,
                     const char *text);
HPDF_STATUS
HPDF_Page_ShowTextNextLine (HPDF_Page page,
                             const char *text);
HPDF_STATUS
HPDF_Page_ShowTextNextLineEx (HPDF_Page page,
                               HPDF_REAL word_space,
                               HPDF_REAL char_space,
                               const char *text);
HPDF_STATUS
HPDF_Page_SetGrayFill (HPDF_Page page,
                        HPDF_REAL gray);
HPDF_STATUS
HPDF_Page_SetGrayStroke (HPDF_Page page,
                          HPDF_REAL gray);
HPDF_STATUS
HPDF_Page_SetRGBFill (HPDF_Page page,
                       HPDF_REAL r,
                       HPDF_REAL g,
                       HPDF_REAL b);
HPDF_STATUS
HPDF_Page_SetRGBStroke (HPDF_Page page,
                         HPDF_REAL r,
                         HPDF_REAL g,
                         HPDF_REAL b);
HPDF_STATUS
HPDF_Page_SetCMYKFill (HPDF_Page page,
                        HPDF_REAL c,
                        HPDF_REAL m,
                        HPDF_REAL y,
                        HPDF_REAL k);
HPDF_STATUS
HPDF_Page_SetCMYKStroke (HPDF_Page page,
                          HPDF_REAL c,
                          HPDF_REAL m,
                          HPDF_REAL y,
                          HPDF_REAL k);
HPDF_STATUS
HPDF_Page_ExecuteXObject (HPDF_Page page,
                           HPDF_XObject obj);
HPDF_STATUS
HPDF_Page_DrawImage (HPDF_Page page,
                      HPDF_Image image,
                      HPDF_REAL x,
                      HPDF_REAL y,
                      HPDF_REAL width,
                      HPDF_REAL height);
HPDF_STATUS
HPDF_Page_Circle (HPDF_Page page,
                   HPDF_REAL x,
                   HPDF_REAL y,
                   HPDF_REAL ray);
HPDF_STATUS
HPDF_Page_Ellipse (HPDF_Page page,
                    HPDF_REAL x,
                    HPDF_REAL y,
                    HPDF_REAL xray,
                    HPDF_REAL yray);
HPDF_STATUS
HPDF_Page_Arc (HPDF_Page page,
                HPDF_REAL x,
                HPDF_REAL y,
                HPDF_REAL ray,
                HPDF_REAL ang1,
                HPDF_REAL ang2);
HPDF_STATUS
HPDF_Page_TextOut (HPDF_Page page,
                    HPDF_REAL xpos,
                    HPDF_REAL ypos,
                    const char *text);
HPDF_STATUS
HPDF_Page_TextRect (HPDF_Page page,
                     HPDF_REAL left,
                     HPDF_REAL top,
                     HPDF_REAL right,
                     HPDF_REAL bottom,
                     const char *text,
                     HPDF_TextAlignment align,
                     HPDF_UINT *len);
HPDF_STATUS
HPDF_Page_SetSlideShow (HPDF_Page page,
                         HPDF_TransitionStyle type,
                         HPDF_REAL disp_time,
                         HPDF_REAL trans_time);
HPDF_OutputIntent
HPDF_ICC_LoadIccFromMem (HPDF_Doc pdf,
                        HPDF_MMgr mmgr,
                        HPDF_Stream iccdata,
                        HPDF_Xref xref,
                        int numcomponent);
HPDF_OutputIntent
HPDF_LoadIccProfileFromFile (HPDF_Doc pdf,
                            const char* icc_file_name,
                                   int numcomponent);
]]
