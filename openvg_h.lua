--result of `cpp openvg.h` from http://www.khronos.org/registry/vg/api/1.1/openvg.h
--result of `cpp vgu.h` from http://www.khronos.org/registry/vg/api/1.1/vgu.h
local ffi = require'ffi'

ffi.cdef[[
enum {
	VG_PATH_FORMAT_STANDARD = 0
};
typedef float VGfloat;
typedef signed char VGbyte;
typedef unsigned char VGubyte;
typedef signed short VGshort;
typedef signed int VGint;
typedef unsigned int VGuint;
typedef unsigned int VGbitfield;
typedef VGuint VGHandle;
typedef VGHandle VGPath;
typedef VGHandle VGImage;
typedef VGHandle VGMaskLayer;
typedef VGHandle VGFont;
typedef VGHandle VGPaint;
typedef enum {
  VG_FALSE = 0,
  VG_TRUE = 1,
  VG_BOOLEAN_FORCE_SIZE = 0x7FFFFFFF
} VGboolean;
typedef enum {
  VG_NO_ERROR = 0,
  VG_BAD_HANDLE_ERROR = 0x1000,
  VG_ILLEGAL_ARGUMENT_ERROR = 0x1001,
  VG_OUT_OF_MEMORY_ERROR = 0x1002,
  VG_PATH_CAPABILITY_ERROR = 0x1003,
  VG_UNSUPPORTED_IMAGE_FORMAT_ERROR = 0x1004,
  VG_UNSUPPORTED_PATH_FORMAT_ERROR = 0x1005,
  VG_IMAGE_IN_USE_ERROR = 0x1006,
  VG_NO_CONTEXT_ERROR = 0x1007,
  VG_ERROR_CODE_FORCE_SIZE = 0x7FFFFFFF
} VGErrorCode;
typedef enum {
  VG_MATRIX_MODE = 0x1100,
  VG_FILL_RULE = 0x1101,
  VG_IMAGE_QUALITY = 0x1102,
  VG_RENDERING_QUALITY = 0x1103,
  VG_BLEND_MODE = 0x1104,
  VG_IMAGE_MODE = 0x1105,
  VG_SCISSOR_RECTS = 0x1106,
  VG_COLOR_TRANSFORM = 0x1170,
  VG_COLOR_TRANSFORM_VALUES = 0x1171,
  VG_STROKE_LINE_WIDTH = 0x1110,
  VG_STROKE_CAP_STYLE = 0x1111,
  VG_STROKE_JOIN_STYLE = 0x1112,
  VG_STROKE_MITER_LIMIT = 0x1113,
  VG_STROKE_DASH_PATTERN = 0x1114,
  VG_STROKE_DASH_PHASE = 0x1115,
  VG_STROKE_DASH_PHASE_RESET = 0x1116,
  VG_TILE_FILL_COLOR = 0x1120,
  VG_CLEAR_COLOR = 0x1121,
  VG_GLYPH_ORIGIN = 0x1122,
  VG_MASKING = 0x1130,
  VG_SCISSORING = 0x1131,
  VG_PIXEL_LAYOUT = 0x1140,
  VG_SCREEN_LAYOUT = 0x1141,
  VG_FILTER_FORMAT_LINEAR = 0x1150,
  VG_FILTER_FORMAT_PREMULTIPLIED = 0x1151,
  VG_FILTER_CHANNEL_MASK = 0x1152,
  VG_MAX_SCISSOR_RECTS = 0x1160,
  VG_MAX_DASH_COUNT = 0x1161,
  VG_MAX_KERNEL_SIZE = 0x1162,
  VG_MAX_SEPARABLE_KERNEL_SIZE = 0x1163,
  VG_MAX_COLOR_RAMP_STOPS = 0x1164,
  VG_MAX_IMAGE_WIDTH = 0x1165,
  VG_MAX_IMAGE_HEIGHT = 0x1166,
  VG_MAX_IMAGE_PIXELS = 0x1167,
  VG_MAX_IMAGE_BYTES = 0x1168,
  VG_MAX_FLOAT = 0x1169,
  VG_MAX_GAUSSIAN_STD_DEVIATION = 0x116A,
  VG_PARAM_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGParamType;
typedef enum {
  VG_RENDERING_QUALITY_NONANTIALIASED = 0x1200,
  VG_RENDERING_QUALITY_FASTER = 0x1201,
  VG_RENDERING_QUALITY_BETTER = 0x1202,
  VG_RENDERING_QUALITY_FORCE_SIZE = 0x7FFFFFFF
} VGRenderingQuality;
typedef enum {
  VG_PIXEL_LAYOUT_UNKNOWN = 0x1300,
  VG_PIXEL_LAYOUT_RGB_VERTICAL = 0x1301,
  VG_PIXEL_LAYOUT_BGR_VERTICAL = 0x1302,
  VG_PIXEL_LAYOUT_RGB_HORIZONTAL = 0x1303,
  VG_PIXEL_LAYOUT_BGR_HORIZONTAL = 0x1304,
  VG_PIXEL_LAYOUT_FORCE_SIZE = 0x7FFFFFFF
} VGPixelLayout;
typedef enum {
  VG_MATRIX_PATH_USER_TO_SURFACE = 0x1400,
  VG_MATRIX_IMAGE_USER_TO_SURFACE = 0x1401,
  VG_MATRIX_FILL_PAINT_TO_USER = 0x1402,
  VG_MATRIX_STROKE_PAINT_TO_USER = 0x1403,
  VG_MATRIX_GLYPH_USER_TO_SURFACE = 0x1404,
  VG_MATRIX_MODE_FORCE_SIZE = 0x7FFFFFFF
} VGMatrixMode;
typedef enum {
  VG_CLEAR_MASK = 0x1500,
  VG_FILL_MASK = 0x1501,
  VG_SET_MASK = 0x1502,
  VG_UNION_MASK = 0x1503,
  VG_INTERSECT_MASK = 0x1504,
  VG_SUBTRACT_MASK = 0x1505,
  VG_MASK_OPERATION_FORCE_SIZE = 0x7FFFFFFF
} VGMaskOperation;
typedef enum {
  VG_PATH_DATATYPE_S_8 = 0,
  VG_PATH_DATATYPE_S_16 = 1,
  VG_PATH_DATATYPE_S_32 = 2,
  VG_PATH_DATATYPE_F = 3,
  VG_PATH_DATATYPE_FORCE_SIZE = 0x7FFFFFFF
} VGPathDatatype;
typedef enum {
  VG_ABSOLUTE = 0,
  VG_RELATIVE = 1,
  VG_PATH_ABS_REL_FORCE_SIZE = 0x7FFFFFFF
} VGPathAbsRel;
typedef enum {
  VG_CLOSE_PATH = ( 0 << 1),
  VG_MOVE_TO = ( 1 << 1),
  VG_LINE_TO = ( 2 << 1),
  VG_HLINE_TO = ( 3 << 1),
  VG_VLINE_TO = ( 4 << 1),
  VG_QUAD_TO = ( 5 << 1),
  VG_CUBIC_TO = ( 6 << 1),
  VG_SQUAD_TO = ( 7 << 1),
  VG_SCUBIC_TO = ( 8 << 1),
  VG_SCCWARC_TO = ( 9 << 1),
  VG_SCWARC_TO = (10 << 1),
  VG_LCCWARC_TO = (11 << 1),
  VG_LCWARC_TO = (12 << 1),
  VG_PATH_SEGMENT_FORCE_SIZE = 0x7FFFFFFF
} VGPathSegment;
typedef enum {
  VG_MOVE_TO_ABS = VG_MOVE_TO | VG_ABSOLUTE,
  VG_MOVE_TO_REL = VG_MOVE_TO | VG_RELATIVE,
  VG_LINE_TO_ABS = VG_LINE_TO | VG_ABSOLUTE,
  VG_LINE_TO_REL = VG_LINE_TO | VG_RELATIVE,
  VG_HLINE_TO_ABS = VG_HLINE_TO | VG_ABSOLUTE,
  VG_HLINE_TO_REL = VG_HLINE_TO | VG_RELATIVE,
  VG_VLINE_TO_ABS = VG_VLINE_TO | VG_ABSOLUTE,
  VG_VLINE_TO_REL = VG_VLINE_TO | VG_RELATIVE,
  VG_QUAD_TO_ABS = VG_QUAD_TO | VG_ABSOLUTE,
  VG_QUAD_TO_REL = VG_QUAD_TO | VG_RELATIVE,
  VG_CUBIC_TO_ABS = VG_CUBIC_TO | VG_ABSOLUTE,
  VG_CUBIC_TO_REL = VG_CUBIC_TO | VG_RELATIVE,
  VG_SQUAD_TO_ABS = VG_SQUAD_TO | VG_ABSOLUTE,
  VG_SQUAD_TO_REL = VG_SQUAD_TO | VG_RELATIVE,
  VG_SCUBIC_TO_ABS = VG_SCUBIC_TO | VG_ABSOLUTE,
  VG_SCUBIC_TO_REL = VG_SCUBIC_TO | VG_RELATIVE,
  VG_SCCWARC_TO_ABS = VG_SCCWARC_TO | VG_ABSOLUTE,
  VG_SCCWARC_TO_REL = VG_SCCWARC_TO | VG_RELATIVE,
  VG_SCWARC_TO_ABS = VG_SCWARC_TO | VG_ABSOLUTE,
  VG_SCWARC_TO_REL = VG_SCWARC_TO | VG_RELATIVE,
  VG_LCCWARC_TO_ABS = VG_LCCWARC_TO | VG_ABSOLUTE,
  VG_LCCWARC_TO_REL = VG_LCCWARC_TO | VG_RELATIVE,
  VG_LCWARC_TO_ABS = VG_LCWARC_TO | VG_ABSOLUTE,
  VG_LCWARC_TO_REL = VG_LCWARC_TO | VG_RELATIVE,
  VG_PATH_COMMAND_FORCE_SIZE = 0x7FFFFFFF
} VGPathCommand;
typedef enum {
  VG_PATH_CAPABILITY_APPEND_FROM = (1 << 0),
  VG_PATH_CAPABILITY_APPEND_TO = (1 << 1),
  VG_PATH_CAPABILITY_MODIFY = (1 << 2),
  VG_PATH_CAPABILITY_TRANSFORM_FROM = (1 << 3),
  VG_PATH_CAPABILITY_TRANSFORM_TO = (1 << 4),
  VG_PATH_CAPABILITY_INTERPOLATE_FROM = (1 << 5),
  VG_PATH_CAPABILITY_INTERPOLATE_TO = (1 << 6),
  VG_PATH_CAPABILITY_PATH_LENGTH = (1 << 7),
  VG_PATH_CAPABILITY_POINT_ALONG_PATH = (1 << 8),
  VG_PATH_CAPABILITY_TANGENT_ALONG_PATH = (1 << 9),
  VG_PATH_CAPABILITY_PATH_BOUNDS = (1 << 10),
  VG_PATH_CAPABILITY_PATH_TRANSFORMED_BOUNDS = (1 << 11),
  VG_PATH_CAPABILITY_ALL = (1 << 12) - 1,
  VG_PATH_CAPABILITIES_FORCE_SIZE = 0x7FFFFFFF
} VGPathCapabilities;
typedef enum {
  VG_PATH_FORMAT = 0x1600,
  VG_PATH_DATATYPE = 0x1601,
  VG_PATH_SCALE = 0x1602,
  VG_PATH_BIAS = 0x1603,
  VG_PATH_NUM_SEGMENTS = 0x1604,
  VG_PATH_NUM_COORDS = 0x1605,
  VG_PATH_PARAM_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGPathParamType;
typedef enum {
  VG_CAP_BUTT = 0x1700,
  VG_CAP_ROUND = 0x1701,
  VG_CAP_SQUARE = 0x1702,
  VG_CAP_STYLE_FORCE_SIZE = 0x7FFFFFFF
} VGCapStyle;
typedef enum {
  VG_JOIN_MITER = 0x1800,
  VG_JOIN_ROUND = 0x1801,
  VG_JOIN_BEVEL = 0x1802,
  VG_JOIN_STYLE_FORCE_SIZE = 0x7FFFFFFF
} VGJoinStyle;
typedef enum {
  VG_EVEN_ODD = 0x1900,
  VG_NON_ZERO = 0x1901,
  VG_FILL_RULE_FORCE_SIZE = 0x7FFFFFFF
} VGFillRule;
typedef enum {
  VG_STROKE_PATH = (1 << 0),
  VG_FILL_PATH = (1 << 1),
  VG_PAINT_MODE_FORCE_SIZE = 0x7FFFFFFF
} VGPaintMode;
typedef enum {
  VG_PAINT_TYPE = 0x1A00,
  VG_PAINT_COLOR = 0x1A01,
  VG_PAINT_COLOR_RAMP_SPREAD_MODE = 0x1A02,
  VG_PAINT_COLOR_RAMP_PREMULTIPLIED = 0x1A07,
  VG_PAINT_COLOR_RAMP_STOPS = 0x1A03,
  VG_PAINT_LINEAR_GRADIENT = 0x1A04,
  VG_PAINT_RADIAL_GRADIENT = 0x1A05,
  VG_PAINT_PATTERN_TILING_MODE = 0x1A06,
  VG_PAINT_PARAM_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGPaintParamType;
typedef enum {
  VG_PAINT_TYPE_COLOR = 0x1B00,
  VG_PAINT_TYPE_LINEAR_GRADIENT = 0x1B01,
  VG_PAINT_TYPE_RADIAL_GRADIENT = 0x1B02,
  VG_PAINT_TYPE_PATTERN = 0x1B03,
  VG_PAINT_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGPaintType;
typedef enum {
  VG_COLOR_RAMP_SPREAD_PAD = 0x1C00,
  VG_COLOR_RAMP_SPREAD_REPEAT = 0x1C01,
  VG_COLOR_RAMP_SPREAD_REFLECT = 0x1C02,
  VG_COLOR_RAMP_SPREAD_MODE_FORCE_SIZE = 0x7FFFFFFF
} VGColorRampSpreadMode;
typedef enum {
  VG_TILE_FILL = 0x1D00,
  VG_TILE_PAD = 0x1D01,
  VG_TILE_REPEAT = 0x1D02,
  VG_TILE_REFLECT = 0x1D03,
  VG_TILING_MODE_FORCE_SIZE = 0x7FFFFFFF
} VGTilingMode;
typedef enum {
  VG_sRGBX_8888 = 0,
  VG_sRGBA_8888 = 1,
  VG_sRGBA_8888_PRE = 2,
  VG_sRGB_565 = 3,
  VG_sRGBA_5551 = 4,
  VG_sRGBA_4444 = 5,
  VG_sL_8 = 6,
  VG_lRGBX_8888 = 7,
  VG_lRGBA_8888 = 8,
  VG_lRGBA_8888_PRE = 9,
  VG_lL_8 = 10,
  VG_A_8 = 11,
  VG_BW_1 = 12,
  VG_A_1 = 13,
  VG_A_4 = 14,
  VG_sXRGB_8888 = 0 | (1 << 6),
  VG_sARGB_8888 = 1 | (1 << 6),
  VG_sARGB_8888_PRE = 2 | (1 << 6),
  VG_sARGB_1555 = 4 | (1 << 6),
  VG_sARGB_4444 = 5 | (1 << 6),
  VG_lXRGB_8888 = 7 | (1 << 6),
  VG_lARGB_8888 = 8 | (1 << 6),
  VG_lARGB_8888_PRE = 9 | (1 << 6),
  VG_sBGRX_8888 = 0 | (1 << 7),
  VG_sBGRA_8888 = 1 | (1 << 7),
  VG_sBGRA_8888_PRE = 2 | (1 << 7),
  VG_sBGR_565 = 3 | (1 << 7),
  VG_sBGRA_5551 = 4 | (1 << 7),
  VG_sBGRA_4444 = 5 | (1 << 7),
  VG_lBGRX_8888 = 7 | (1 << 7),
  VG_lBGRA_8888 = 8 | (1 << 7),
  VG_lBGRA_8888_PRE = 9 | (1 << 7),
  VG_sXBGR_8888 = 0 | (1 << 6) | (1 << 7),
  VG_sABGR_8888 = 1 | (1 << 6) | (1 << 7),
  VG_sABGR_8888_PRE = 2 | (1 << 6) | (1 << 7),
  VG_sABGR_1555 = 4 | (1 << 6) | (1 << 7),
  VG_sABGR_4444 = 5 | (1 << 6) | (1 << 7),
  VG_lXBGR_8888 = 7 | (1 << 6) | (1 << 7),
  VG_lABGR_8888 = 8 | (1 << 6) | (1 << 7),
  VG_lABGR_8888_PRE = 9 | (1 << 6) | (1 << 7),
  VG_IMAGE_FORMAT_FORCE_SIZE = 0x7FFFFFFF
} VGImageFormat;
typedef enum {
  VG_IMAGE_QUALITY_NONANTIALIASED = (1 << 0),
  VG_IMAGE_QUALITY_FASTER = (1 << 1),
  VG_IMAGE_QUALITY_BETTER = (1 << 2),
  VG_IMAGE_QUALITY_FORCE_SIZE = 0x7FFFFFFF
} VGImageQuality;
typedef enum {
  VG_IMAGE_FORMAT = 0x1E00,
  VG_IMAGE_WIDTH = 0x1E01,
  VG_IMAGE_HEIGHT = 0x1E02,
  VG_IMAGE_PARAM_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGImageParamType;
typedef enum {
  VG_DRAW_IMAGE_NORMAL = 0x1F00,
  VG_DRAW_IMAGE_MULTIPLY = 0x1F01,
  VG_DRAW_IMAGE_STENCIL = 0x1F02,
  VG_IMAGE_MODE_FORCE_SIZE = 0x7FFFFFFF
} VGImageMode;
typedef enum {
  VG_RED = (1 << 3),
  VG_GREEN = (1 << 2),
  VG_BLUE = (1 << 1),
  VG_ALPHA = (1 << 0),
  VG_IMAGE_CHANNEL_FORCE_SIZE = 0x7FFFFFFF
} VGImageChannel;
typedef enum {
  VG_BLEND_SRC = 0x2000,
  VG_BLEND_SRC_OVER = 0x2001,
  VG_BLEND_DST_OVER = 0x2002,
  VG_BLEND_SRC_IN = 0x2003,
  VG_BLEND_DST_IN = 0x2004,
  VG_BLEND_MULTIPLY = 0x2005,
  VG_BLEND_SCREEN = 0x2006,
  VG_BLEND_DARKEN = 0x2007,
  VG_BLEND_LIGHTEN = 0x2008,
  VG_BLEND_ADDITIVE = 0x2009,
  VG_BLEND_MODE_FORCE_SIZE = 0x7FFFFFFF
} VGBlendMode;
typedef enum {
  VG_FONT_NUM_GLYPHS = 0x2F00,
  VG_FONT_PARAM_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGFontParamType;
typedef enum {
  VG_IMAGE_FORMAT_QUERY = 0x2100,
  VG_PATH_DATATYPE_QUERY = 0x2101,
  VG_HARDWARE_QUERY_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGHardwareQueryType;
typedef enum {
  VG_HARDWARE_ACCELERATED = 0x2200,
  VG_HARDWARE_UNACCELERATED = 0x2201,
  VG_HARDWARE_QUERY_RESULT_FORCE_SIZE = 0x7FFFFFFF
} VGHardwareQueryResult;
typedef enum {
  VG_VENDOR = 0x2300,
  VG_RENDERER = 0x2301,
  VG_VERSION = 0x2302,
  VG_EXTENSIONS = 0x2303,
  VG_STRING_ID_FORCE_SIZE = 0x7FFFFFFF
} VGStringID;
VGErrorCode vgGetError(void);
void vgFlush(void);
void vgFinish(void);
void vgSetf (VGParamType type, VGfloat value);
void vgSeti (VGParamType type, VGint value);
void vgSetfv(VGParamType type, VGint count,
                         const VGfloat* values);
void vgSetiv(VGParamType type, VGint count,
                         const VGint* values);
VGfloat vgGetf(VGParamType type);
VGint vgGeti(VGParamType type);
VGint vgGetVectorSize(VGParamType type);
void vgGetfv(VGParamType type, VGint count, VGfloat* values);
void vgGetiv(VGParamType type, VGint count, VGint* values);
void vgSetParameterf(VGHandle object,
                                 VGint paramType,
                                 VGfloat value);
void vgSetParameteri(VGHandle object,
                                 VGint paramType,
                                 VGint value);
void vgSetParameterfv(VGHandle object,
                                  VGint paramType,
                                  VGint count, const VGfloat* values);
void vgSetParameteriv(VGHandle object,
                                  VGint paramType,
                                  VGint count, const VGint* values);
VGfloat vgGetParameterf(VGHandle object,
                                    VGint paramType);
VGint vgGetParameteri(VGHandle object,
                                  VGint paramType);
VGint vgGetParameterVectorSize(VGHandle object,
                                           VGint paramType);
void vgGetParameterfv(VGHandle object,
                                  VGint paramType,
                                  VGint count, VGfloat* values);
void vgGetParameteriv(VGHandle object,
                                  VGint paramType,
                                  VGint count, VGint* values);
void vgLoadIdentity(void);
void vgLoadMatrix(const VGfloat* m);
void vgGetMatrix(VGfloat* m);
void vgMultMatrix(const VGfloat* m);
void vgTranslate(VGfloat tx, VGfloat ty);
void vgScale(VGfloat sx, VGfloat sy);
void vgShear(VGfloat shx, VGfloat shy);
void vgRotate(VGfloat angle);
void vgMask(VGHandle mask, VGMaskOperation operation,
                                     VGint x, VGint y,
                                     VGint width, VGint height);
void vgRenderToMask(VGPath path,
                                            VGbitfield paintModes,
                                            VGMaskOperation operation);
VGMaskLayer vgCreateMaskLayer(VGint width, VGint height);
void vgDestroyMaskLayer(VGMaskLayer maskLayer);
void vgFillMaskLayer(VGMaskLayer maskLayer,
                                             VGint x, VGint y,
                                             VGint width, VGint height,
                                             VGfloat value);
void vgCopyMask(VGMaskLayer maskLayer,
                                        VGint dx, VGint dy,
                                        VGint sx, VGint sy,
                                        VGint width, VGint height);
void vgClear(VGint x, VGint y, VGint width, VGint height);
VGPath vgCreatePath(VGint pathFormat,
                                VGPathDatatype datatype,
                                VGfloat scale, VGfloat bias,
                                VGint segmentCapacityHint,
                                VGint coordCapacityHint,
                                VGbitfield capabilities);
void vgClearPath(VGPath path, VGbitfield capabilities);
void vgDestroyPath(VGPath path);
void vgRemovePathCapabilities(VGPath path,
                                          VGbitfield capabilities);
VGbitfield vgGetPathCapabilities(VGPath path);
void vgAppendPath(VGPath dstPath, VGPath srcPath);
void vgAppendPathData(VGPath dstPath,
                                  VGint numSegments,
                                  const VGubyte* pathSegments,
                                  const void* pathData);
void vgModifyPathCoords(VGPath dstPath, VGint startIndex,
                                    VGint numSegments,
                                    const void* pathData);
void vgTransformPath(VGPath dstPath, VGPath srcPath);
VGboolean vgInterpolatePath(VGPath dstPath,
                                        VGPath startPath,
                                        VGPath endPath,
                                        VGfloat amount);
VGfloat vgPathLength(VGPath path,
                                 VGint startSegment, VGint numSegments);
void vgPointAlongPath(VGPath path,
                                  VGint startSegment, VGint numSegments,
                                  VGfloat distance,
                                  VGfloat* x, VGfloat* y,
                                  VGfloat* tangentX, VGfloat* tangentY);
void vgPathBounds(VGPath path,
                              VGfloat* minX, VGfloat* minY,
                              VGfloat* width, VGfloat* height);
void vgPathTransformedBounds(VGPath path,
                                         VGfloat* minX, VGfloat* minY,
                                         VGfloat* width, VGfloat* height);
void vgDrawPath(VGPath path, VGbitfield paintModes);
VGPaint vgCreatePaint(void);
void vgDestroyPaint(VGPaint paint);
void vgSetPaint(VGPaint paint, VGbitfield paintModes);
VGPaint vgGetPaint(VGPaintMode paintMode);
void vgSetColor(VGPaint paint, VGuint rgba);
VGuint vgGetColor(VGPaint paint);
void vgPaintPattern(VGPaint paint, VGImage pattern);
VGImage vgCreateImage(VGImageFormat format,
                                  VGint width, VGint height,
                                  VGbitfield allowedQuality);
void vgDestroyImage(VGImage image);
void vgClearImage(VGImage image,
                              VGint x, VGint y, VGint width, VGint height);
void vgImageSubData(VGImage image,
                                const void* data, VGint dataStride,
                                VGImageFormat dataFormat,
                                VGint x, VGint y, VGint width, VGint height);
void vgGetImageSubData(VGImage image,
                                   void* data, VGint dataStride,
                                   VGImageFormat dataFormat,
                                   VGint x, VGint y,
                                   VGint width, VGint height);
VGImage vgChildImage(VGImage parent,
                                 VGint x, VGint y, VGint width, VGint height);
VGImage vgGetParent(VGImage image);
void vgCopyImage(VGImage dst, VGint dx, VGint dy,
                             VGImage src, VGint sx, VGint sy,
                             VGint width, VGint height,
                             VGboolean dither);
void vgDrawImage(VGImage image);
void vgSetPixels(VGint dx, VGint dy,
                             VGImage src, VGint sx, VGint sy,
                             VGint width, VGint height);
void vgWritePixels(const void* data, VGint dataStride,
                               VGImageFormat dataFormat,
                               VGint dx, VGint dy,
                               VGint width, VGint height);
void vgGetPixels(VGImage dst, VGint dx, VGint dy,
                             VGint sx, VGint sy,
                             VGint width, VGint height);
void vgReadPixels(void* data, VGint dataStride,
                              VGImageFormat dataFormat,
                              VGint sx, VGint sy,
                              VGint width, VGint height);
void vgCopyPixels(VGint dx, VGint dy,
                              VGint sx, VGint sy,
                              VGint width, VGint height);
VGFont vgCreateFont(VGint glyphCapacityHint);
void vgDestroyFont(VGFont font);
void vgSetGlyphToPath(VGFont font,
                                              VGuint glyphIndex,
                                              VGPath path,
                                              VGboolean isHinted,
                                              const VGfloat glyphOrigin [2],
                                              const VGfloat escapement[2]);
void vgSetGlyphToImage(VGFont font,
                                               VGuint glyphIndex,
                                               VGImage image,
                                               const VGfloat glyphOrigin [2],
                                               const VGfloat escapement[2]);
void vgClearGlyph(VGFont font,VGuint glyphIndex);
void vgDrawGlyph(VGFont font,
                                         VGuint glyphIndex,
                                         VGbitfield paintModes,
                                         VGboolean allowAutoHinting);
void vgDrawGlyphs(VGFont font,
                                          VGint glyphCount,
                                          const VGuint*glyphIndices,
                                          const VGfloat*adjustments_x,
                                          const VGfloat*adjustments_y,
                                          VGbitfield paintModes,
                                          VGboolean allowAutoHinting);
void vgColorMatrix(VGImage dst, VGImage src,
                               const VGfloat* matrix);
void vgConvolve(VGImage dst, VGImage src,
                            VGint kernelWidth, VGint kernelHeight,
                            VGint shiftX, VGint shiftY,
                            const VGshort* kernel,
                            VGfloat scale,
                            VGfloat bias,
                            VGTilingMode tilingMode);
void vgSeparableConvolve(VGImage dst, VGImage src,
                                     VGint kernelWidth,
                                     VGint kernelHeight,
                                     VGint shiftX, VGint shiftY,
                                     const VGshort* kernelX,
                                     const VGshort* kernelY,
                                     VGfloat scale,
                                     VGfloat bias,
                                     VGTilingMode tilingMode);
void vgGaussianBlur(VGImage dst, VGImage src,
                                VGfloat stdDeviationX,
                                VGfloat stdDeviationY,
                                VGTilingMode tilingMode);
void vgLookup(VGImage dst, VGImage src,
                          const VGubyte* redLUT,
                          const VGubyte* greenLUT,
                          const VGubyte* blueLUT,
                          const VGubyte* alphaLUT,
                          VGboolean outputLinear,
                          VGboolean outputPremultiplied);
void vgLookupSingle(VGImage dst, VGImage src,
                                const VGuint* lookupTable,
                                VGImageChannel sourceChannel,
                                VGboolean outputLinear,
                                VGboolean outputPremultiplied);
VGHardwareQueryResult vgHardwareQuery(VGHardwareQueryType key,
                                                  VGint setting);
const VGubyte* vgGetString(VGStringID name);
]]

ffi.cdef[[
typedef enum {
  VGU_NO_ERROR = 0,
  VGU_BAD_HANDLE_ERROR = 0xF000,
  VGU_ILLEGAL_ARGUMENT_ERROR = 0xF001,
  VGU_OUT_OF_MEMORY_ERROR = 0xF002,
  VGU_PATH_CAPABILITY_ERROR = 0xF003,
  VGU_BAD_WARP_ERROR = 0xF004,
  VGU_ERROR_CODE_FORCE_SIZE = 0x7FFFFFFF
} VGUErrorCode;
typedef enum {
  VGU_ARC_OPEN = 0xF100,
  VGU_ARC_CHORD = 0xF101,
  VGU_ARC_PIE = 0xF102,
  VGU_ARC_TYPE_FORCE_SIZE = 0x7FFFFFFF
} VGUArcType;
VGUErrorCode vguLine(VGPath path,
                                  VGfloat x0, VGfloat y0,
                                  VGfloat x1, VGfloat y1);
VGUErrorCode vguPolygon(VGPath path,
                                     const VGfloat* points, VGint count,
                                     VGboolean closed);
VGUErrorCode vguRect(VGPath path,
                                  VGfloat x, VGfloat y,
                                  VGfloat width, VGfloat height);
VGUErrorCode vguRoundRect(VGPath path,
                                       VGfloat x, VGfloat y,
                                       VGfloat width, VGfloat height,
                                       VGfloat arcWidth, VGfloat arcHeight);
VGUErrorCode vguEllipse(VGPath path,
                                     VGfloat cx, VGfloat cy,
                                     VGfloat width, VGfloat height);
VGUErrorCode vguArc(VGPath path,
                                 VGfloat x, VGfloat y,
                                 VGfloat width, VGfloat height,
                                 VGfloat startAngle, VGfloat angleExtent,
                                 VGUArcType arcType);
VGUErrorCode vguComputeWarpQuadToSquare(VGfloat sx0, VGfloat sy0,
                                                     VGfloat sx1, VGfloat sy1,
                                                     VGfloat sx2, VGfloat sy2,
                                                     VGfloat sx3, VGfloat sy3,
                                                     VGfloat* matrix);
VGUErrorCode vguComputeWarpSquareToQuad(VGfloat dx0, VGfloat dy0,
                                                     VGfloat dx1, VGfloat dy1,
                                                     VGfloat dx2, VGfloat dy2,
                                                     VGfloat dx3, VGfloat dy3,
                                                     VGfloat* matrix);
VGUErrorCode vguComputeWarpQuadToQuad(VGfloat dx0, VGfloat dy0,
                                                   VGfloat dx1, VGfloat dy1,
                                                   VGfloat dx2, VGfloat dy2,
                                                   VGfloat dx3, VGfloat dy3,
                                                   VGfloat sx0, VGfloat sy0,
                                                   VGfloat sx1, VGfloat sy1,
                                                   VGfloat sx2, VGfloat sy2,
                                                   VGfloat sx3, VGfloat sy3,
                                                   VGfloat* matrix);
]]
