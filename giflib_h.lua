--giflib.h from giflib 5.0
local ffi = require'ffi'

ffi.cdef[[
enum {
   CONTINUE_EXT_FUNC_CODE    = 0x00,
   COMMENT_EXT_FUNC_CODE     = 0xfe,
   GRAPHICS_EXT_FUNC_CODE    = 0xf9,
   PLAINTEXT_EXT_FUNC_CODE   = 0x01,
   APPLICATION_EXT_FUNC_CODE = 0xff,

   DISPOSAL_UNSPECIFIED      = 0,
   DISPOSE_DO_NOT            = 1,
   DISPOSE_BACKGROUND        = 2,
   DISPOSE_PREVIOUS          = 3,

   E_GIF_ERR_OPEN_FAILED    = 1,
   E_GIF_ERR_WRITE_FAILED   = 2,
   E_GIF_ERR_HAS_SCRN_DSCR  = 3,
   E_GIF_ERR_HAS_IMAG_DSCR  = 4,
   E_GIF_ERR_NO_COLOR_MAP   = 5,
   E_GIF_ERR_DATA_TOO_BIG   = 6,
   E_GIF_ERR_NOT_ENOUGH_MEM = 7,
   E_GIF_ERR_DISK_IS_FULL   = 8,
   E_GIF_ERR_CLOSE_FAILED   = 9,
   E_GIF_ERR_NOT_WRITEABLE  = 10,

   D_GIF_ERR_OPEN_FAILED    = 101,
   D_GIF_ERR_READ_FAILED    = 102,
   D_GIF_ERR_NOT_GIF_FILE   = 103,
   D_GIF_ERR_NO_SCRN_DSCR   = 104,
   D_GIF_ERR_NO_IMAG_DSCR   = 105,
   D_GIF_ERR_NO_COLOR_MAP   = 106,
   D_GIF_ERR_WRONG_RECORD   = 107,
   D_GIF_ERR_DATA_TOO_BIG   = 108,
   D_GIF_ERR_NOT_ENOUGH_MEM = 109,
   D_GIF_ERR_CLOSE_FAILED   = 110,
   D_GIF_ERR_NOT_READABLE   = 111,
   D_GIF_ERR_IMAGE_DEFECT   = 112,
   D_GIF_ERR_EOF_TOO_SOON   = 113,

   GIF_FONT_WIDTH  = 8,
   GIF_FONT_HEIGHT = 8,
};

typedef unsigned char GifPixelType;
typedef unsigned char *GifRowType;
typedef unsigned char GifByteType;
typedef unsigned int GifPrefixType;
typedef int GifWord;
typedef struct GifColorType {
    GifByteType Red, Green, Blue;
} GifColorType;
typedef struct ColorMapObject {
    int ColorCount;
    int BitsPerPixel;
    _Bool SortFlag;
    GifColorType *Colors;
} ColorMapObject;
typedef struct GifImageDesc {
    GifWord Left, Top, Width, Height;
    _Bool Interlace;
    ColorMapObject *ColorMap;
} GifImageDesc;
typedef struct ExtensionBlock {
    int ByteCount;
    GifByteType *Bytes;
    int Function;
} ExtensionBlock;
typedef struct SavedImage {
    GifImageDesc ImageDesc;
    GifByteType *RasterBits;
    int ExtensionBlockCount;
    ExtensionBlock *ExtensionBlocks;
} SavedImage;
typedef struct GifFileType {
    GifWord SWidth, SHeight;
    GifWord SColorResolution;
    GifWord SBackGroundColor;
    GifByteType AspectByte;
    ColorMapObject *SColorMap;
    int ImageCount;
    GifImageDesc Image;
    SavedImage *SavedImages;
    int ExtensionBlockCount;
    ExtensionBlock *ExtensionBlocks;
    int Error;
    void *UserData;
    void *Private;
} GifFileType;
typedef enum {
    UNDEFINED_RECORD_TYPE,
    SCREEN_DESC_RECORD_TYPE,
    IMAGE_DESC_RECORD_TYPE,
    EXTENSION_RECORD_TYPE,
    TERMINATE_RECORD_TYPE
} GifRecordType;
typedef int (*GifInputFunc) (GifFileType *, GifByteType *, int);
typedef int (*GifOutputFunc) (GifFileType *, const GifByteType *, int);
typedef struct GraphicsControlBlock {
    int DisposalMode;
    _Bool UserInputFlag;
    int DelayTime;
    int TransparentColor;
} GraphicsControlBlock;
GifFileType *EGifOpenFileName(const char *GifFileName,
                              const _Bool GifTestExistence, int *Error);
GifFileType *EGifOpenFileHandle(const int GifFileHandle, int *Error);
GifFileType *EGifOpen(void *userPtr, GifOutputFunc writeFunc, int *Error);
int EGifSpew(GifFileType * GifFile);
char *EGifGetGifVersion(GifFileType *GifFile);
int EGifCloseFile(GifFileType * GifFile);
int EGifPutScreenDesc(GifFileType *GifFile,
                      const int GifWidth, const int GifHeight,
        const int GifColorRes,
                      const int GifBackGround,
                      const ColorMapObject *GifColorMap);
int EGifPutImageDesc(GifFileType *GifFile,
       const int GifLeft, const int GifTop,
                     const int GifWidth, const int GifHeight,
       const _Bool GifInterlace,
                     const ColorMapObject *GifColorMap);
int EGifPutLine(GifFileType *GifFile, GifPixelType *GifLine,
                int GifLineLen);
int EGifPutPixel(GifFileType *GifFile, const GifPixelType GifPixel);
int EGifPutComment(GifFileType *GifFile, const char *GifComment);
int EGifPutExtensionLeader(GifFileType *GifFile, const int GifExtCode);
int EGifPutExtensionBlock(GifFileType *GifFile,
                         const int GifExtLen, const void *GifExtension);
int EGifPutExtensionTrailer(GifFileType *GifFile);
int EGifPutExtension(GifFileType *GifFile, const int GifExtCode,
       const int GifExtLen,
                     const void *GifExtension);
int EGifPutCode(GifFileType *GifFile, int GifCodeSize,
                const GifByteType *GifCodeBlock);
int EGifPutCodeNext(GifFileType *GifFile,
                    const GifByteType *GifCodeBlock);
GifFileType *DGifOpenFileName(const char *GifFileName, int *Error);
GifFileType *DGifOpenFileHandle(int GifFileHandle, int *Error);
int DGifSlurp(GifFileType * GifFile);
GifFileType *DGifOpen(void *userPtr, GifInputFunc readFunc, int *Error);
int DGifCloseFile(GifFileType * GifFile);
int DGifGetScreenDesc(GifFileType *GifFile);
int DGifGetRecordType(GifFileType *GifFile, GifRecordType *GifType);
int DGifGetImageDesc(GifFileType *GifFile);
int DGifGetLine(GifFileType *GifFile, GifPixelType *GifLine, int GifLineLen);
int DGifGetPixel(GifFileType *GifFile, GifPixelType GifPixel);
int DGifGetComment(GifFileType *GifFile, char *GifComment);
int DGifGetExtension(GifFileType *GifFile, int *GifExtCode,
                     GifByteType **GifExtension);
int DGifGetExtensionNext(GifFileType *GifFile, GifByteType **GifExtension);
int DGifGetCode(GifFileType *GifFile, int *GifCodeSize,
                GifByteType **GifCodeBlock);
int DGifGetCodeNext(GifFileType *GifFile, GifByteType **GifCodeBlock);
int DGifGetLZCodes(GifFileType *GifFile, int *GifCode);
int GifQuantizeBuffer(unsigned int Width, unsigned int Height,
                   int *ColorMapSize, GifByteType * RedInput,
                   GifByteType * GreenInput, GifByteType * BlueInput,
                   GifByteType * OutputBuffer,
                   GifColorType * OutputColorMap);
char *GifErrorString(int ErrorCode);
ColorMapObject *GifMakeMapObject(int ColorCount,
                                     const GifColorType *ColorMap);
void GifFreeMapObject(ColorMapObject *Object);
ColorMapObject *GifUnionColorMap(const ColorMapObject *ColorIn1,
                                     const ColorMapObject *ColorIn2,
                                     GifPixelType ColorTransIn2[]);
int GifBitSize(int n);
void GifApplyTranslation(SavedImage *Image, GifPixelType Translation[]);
int GifAddExtensionBlock(int *ExtensionBlock_Count,
    ExtensionBlock **ExtensionBlocks,
    int Function,
    unsigned int Len, unsigned char ExtData[]);
void GifFreeExtensions(int *ExtensionBlock_Count,
         ExtensionBlock **ExtensionBlocks);
SavedImage *GifMakeSavedImage(GifFileType *GifFile,
                                  const SavedImage *CopyFrom);
void GifFreeSavedImages(GifFileType *GifFile);
int DGifExtensionToGCB(const size_t GifExtensionLength,
         const GifByteType *GifExtension,
         GraphicsControlBlock *GCB);
size_t EGifGCBToExtension(const GraphicsControlBlock *GCB,
         GifByteType *GifExtension);
int DGifSavedExtensionToGCB(GifFileType *GifFile,
       int ImageIndex,
       GraphicsControlBlock *GCB);
int EGifGCBToSavedExtension(const GraphicsControlBlock *GCB,
       GifFileType *GifFile,
       int ImageIndex);
const unsigned char GifAsciiTable8x8[][8];
void GifDrawText8x8(SavedImage *Image,
                     const int x, const int y,
                     const char *legend, const int color);
void GifDrawBox(SavedImage *Image,
                    const int x, const int y,
                    const int w, const int d, const int color);
void GifDrawRectangle(SavedImage *Image,
                   const int x, const int y,
                   const int w, const int d, const int color);
void GifDrawBoxedText8x8(SavedImage *Image,
                          const int x, const int y,
                          const char *legend,
                          const int border, const int bg, const int fg);
]]
