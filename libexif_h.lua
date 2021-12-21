--libexif/exif-loader.h from libexif 0.6.21 from http://libexif.sourceforge.net/ (LGPL license)
require'ffi'.cdef[[
typedef enum {
 EXIF_BYTE_ORDER_MOTOROLA,
 EXIF_BYTE_ORDER_INTEL
} ExifByteOrder;
const char *exif_byte_order_get_name (ExifByteOrder order);
typedef enum {
 EXIF_DATA_TYPE_UNCOMPRESSED_CHUNKY = 0,
 EXIF_DATA_TYPE_UNCOMPRESSED_PLANAR,
 EXIF_DATA_TYPE_UNCOMPRESSED_YCC,
 EXIF_DATA_TYPE_COMPRESSED,
 EXIF_DATA_TYPE_COUNT,
 EXIF_DATA_TYPE_UNKNOWN = EXIF_DATA_TYPE_COUNT
} ExifDataType;
typedef enum {
 EXIF_IFD_0 = 0,
 EXIF_IFD_1,
 EXIF_IFD_EXIF,
 EXIF_IFD_GPS,
 EXIF_IFD_INTEROPERABILITY,
 EXIF_IFD_COUNT
} ExifIfd;
const char *exif_ifd_get_name (ExifIfd ifd);
typedef enum {
        EXIF_FORMAT_BYTE = 1,
        EXIF_FORMAT_ASCII = 2,
        EXIF_FORMAT_SHORT = 3,
        EXIF_FORMAT_LONG = 4,
        EXIF_FORMAT_RATIONAL = 5,
 EXIF_FORMAT_SBYTE = 6,
        EXIF_FORMAT_UNDEFINED = 7,
 EXIF_FORMAT_SSHORT = 8,
        EXIF_FORMAT_SLONG = 9,
        EXIF_FORMAT_SRATIONAL = 10,
 EXIF_FORMAT_FLOAT = 11,
 EXIF_FORMAT_DOUBLE = 12
} ExifFormat;
const char *exif_format_get_name (ExifFormat format);
unsigned char exif_format_get_size (ExifFormat format);
typedef short unsigned int wchar_t;
typedef short unsigned int wint_t;
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned uint32_t;
typedef long long int64_t;
typedef unsigned long long uint64_t;
typedef signed char int_least8_t;
typedef unsigned char uint_least8_t;
typedef short int_least16_t;
typedef unsigned short uint_least16_t;
typedef int int_least32_t;
typedef unsigned uint_least32_t;
typedef long long int_least64_t;
typedef unsigned long long uint_least64_t;
typedef signed char int_fast8_t;
typedef unsigned char uint_fast8_t;
typedef short int_fast16_t;
typedef unsigned short uint_fast16_t;
typedef int int_fast32_t;
typedef unsigned int uint_fast32_t;
typedef long long int_fast64_t;
typedef unsigned long long uint_fast64_t;
  typedef int intptr_t;
  typedef unsigned int uintptr_t;
typedef long long intmax_t;
typedef unsigned long long uintmax_t;
typedef unsigned char ExifByte;
typedef signed char ExifSByte;
typedef char * ExifAscii;
typedef uint16_t ExifShort;
typedef int16_t ExifSShort;
typedef uint32_t ExifLong;
typedef int32_t ExifSLong;
typedef struct {ExifLong numerator; ExifLong denominator;} ExifRational;
typedef char ExifUndefined;
typedef struct {ExifSLong numerator; ExifSLong denominator;} ExifSRational;
ExifShort exif_get_short (const unsigned char *b, ExifByteOrder order);
ExifSShort exif_get_sshort (const unsigned char *b, ExifByteOrder order);
ExifLong exif_get_long (const unsigned char *b, ExifByteOrder order);
ExifSLong exif_get_slong (const unsigned char *b, ExifByteOrder order);
ExifRational exif_get_rational (const unsigned char *b, ExifByteOrder order);
ExifSRational exif_get_srational (const unsigned char *b, ExifByteOrder order);
void exif_set_short (unsigned char *b, ExifByteOrder order,
    ExifShort value);
void exif_set_sshort (unsigned char *b, ExifByteOrder order,
    ExifSShort value);
void exif_set_long (unsigned char *b, ExifByteOrder order,
    ExifLong value);
void exif_set_slong (unsigned char *b, ExifByteOrder order,
    ExifSLong value);
void exif_set_rational (unsigned char *b, ExifByteOrder order,
    ExifRational value);
void exif_set_srational (unsigned char *b, ExifByteOrder order,
    ExifSRational value);
void exif_convert_utf16_to_utf8 (char *out, const unsigned short *in, int maxlen);
void exif_array_set_byte_order (ExifFormat, unsigned char *, unsigned int,
  ExifByteOrder o_orig, ExifByteOrder o_new);
typedef void * (* ExifMemAllocFunc) (ExifLong s);
typedef void * (* ExifMemReallocFunc) (void *p, ExifLong s);
typedef void (* ExifMemFreeFunc) (void *p);
typedef struct _ExifMem ExifMem;
ExifMem *exif_mem_new (ExifMemAllocFunc a, ExifMemReallocFunc r,
    ExifMemFreeFunc f);
void exif_mem_ref (ExifMem *);
void exif_mem_unref (ExifMem *);
void *exif_mem_alloc (ExifMem *m, ExifLong s);
void *exif_mem_realloc (ExifMem *m, void *p, ExifLong s);
void exif_mem_free (ExifMem *m, void *p);
ExifMem *exif_mem_new_default (void);
typedef __builtin_va_list __gnuc_va_list;
typedef __gnuc_va_list va_list;
typedef struct _ExifLog ExifLog;
ExifLog *exif_log_new (void);
ExifLog *exif_log_new_mem (ExifMem *);
void exif_log_ref (ExifLog *log);
void exif_log_unref (ExifLog *log);
void exif_log_free (ExifLog *log);
typedef enum {
 EXIF_LOG_CODE_NONE,
 EXIF_LOG_CODE_DEBUG,
 EXIF_LOG_CODE_NO_MEMORY,
 EXIF_LOG_CODE_CORRUPT_DATA
} ExifLogCode;
const char *exif_log_code_get_title (ExifLogCode code);
const char *exif_log_code_get_message (ExifLogCode code);
typedef void (* ExifLogFunc) (ExifLog *log, ExifLogCode, const char *domain,
         const char *format, va_list args, void *data);
void exif_log_set_func (ExifLog *log, ExifLogFunc func, void *data);
void exif_log (ExifLog *log, ExifLogCode, const char *domain,
      const char *format, ...)
   __attribute__((__format__(printf,4,5)))
;
void exif_logv (ExifLog *log, ExifLogCode, const char *domain,
      const char *format, va_list args);
typedef enum {
 EXIF_TAG_INTEROPERABILITY_INDEX = 0x0001,
 EXIF_TAG_INTEROPERABILITY_VERSION = 0x0002,
 EXIF_TAG_NEW_SUBFILE_TYPE = 0x00fe,
 EXIF_TAG_IMAGE_WIDTH = 0x0100,
 EXIF_TAG_IMAGE_LENGTH = 0x0101,
 EXIF_TAG_BITS_PER_SAMPLE = 0x0102,
 EXIF_TAG_COMPRESSION = 0x0103,
 EXIF_TAG_PHOTOMETRIC_INTERPRETATION = 0x0106,
 EXIF_TAG_FILL_ORDER = 0x010a,
 EXIF_TAG_DOCUMENT_NAME = 0x010d,
 EXIF_TAG_IMAGE_DESCRIPTION = 0x010e,
 EXIF_TAG_MAKE = 0x010f,
 EXIF_TAG_MODEL = 0x0110,
 EXIF_TAG_STRIP_OFFSETS = 0x0111,
 EXIF_TAG_ORIENTATION = 0x0112,
 EXIF_TAG_SAMPLES_PER_PIXEL = 0x0115,
 EXIF_TAG_ROWS_PER_STRIP = 0x0116,
 EXIF_TAG_STRIP_BYTE_COUNTS = 0x0117,
 EXIF_TAG_X_RESOLUTION = 0x011a,
 EXIF_TAG_Y_RESOLUTION = 0x011b,
 EXIF_TAG_PLANAR_CONFIGURATION = 0x011c,
 EXIF_TAG_RESOLUTION_UNIT = 0x0128,
 EXIF_TAG_TRANSFER_FUNCTION = 0x012d,
 EXIF_TAG_SOFTWARE = 0x0131,
 EXIF_TAG_DATE_TIME = 0x0132,
 EXIF_TAG_ARTIST = 0x013b,
 EXIF_TAG_WHITE_POINT = 0x013e,
 EXIF_TAG_PRIMARY_CHROMATICITIES = 0x013f,
 EXIF_TAG_SUB_IFDS = 0x014a,
 EXIF_TAG_TRANSFER_RANGE = 0x0156,
 EXIF_TAG_JPEG_PROC = 0x0200,
 EXIF_TAG_JPEG_INTERCHANGE_FORMAT = 0x0201,
 EXIF_TAG_JPEG_INTERCHANGE_FORMAT_LENGTH = 0x0202,
 EXIF_TAG_YCBCR_COEFFICIENTS = 0x0211,
 EXIF_TAG_YCBCR_SUB_SAMPLING = 0x0212,
 EXIF_TAG_YCBCR_POSITIONING = 0x0213,
 EXIF_TAG_REFERENCE_BLACK_WHITE = 0x0214,
 EXIF_TAG_XML_PACKET = 0x02bc,
 EXIF_TAG_RELATED_IMAGE_FILE_FORMAT = 0x1000,
 EXIF_TAG_RELATED_IMAGE_WIDTH = 0x1001,
 EXIF_TAG_RELATED_IMAGE_LENGTH = 0x1002,
 EXIF_TAG_CFA_REPEAT_PATTERN_DIM = 0x828d,
 EXIF_TAG_CFA_PATTERN = 0x828e,
 EXIF_TAG_BATTERY_LEVEL = 0x828f,
 EXIF_TAG_COPYRIGHT = 0x8298,
 EXIF_TAG_EXPOSURE_TIME = 0x829a,
 EXIF_TAG_FNUMBER = 0x829d,
 EXIF_TAG_IPTC_NAA = 0x83bb,
 EXIF_TAG_IMAGE_RESOURCES = 0x8649,
 EXIF_TAG_EXIF_IFD_POINTER = 0x8769,
 EXIF_TAG_INTER_COLOR_PROFILE = 0x8773,
 EXIF_TAG_EXPOSURE_PROGRAM = 0x8822,
 EXIF_TAG_SPECTRAL_SENSITIVITY = 0x8824,
 EXIF_TAG_GPS_INFO_IFD_POINTER = 0x8825,
 EXIF_TAG_ISO_SPEED_RATINGS = 0x8827,
 EXIF_TAG_OECF = 0x8828,
 EXIF_TAG_TIME_ZONE_OFFSET = 0x882a,
 EXIF_TAG_EXIF_VERSION = 0x9000,
 EXIF_TAG_DATE_TIME_ORIGINAL = 0x9003,
 EXIF_TAG_DATE_TIME_DIGITIZED = 0x9004,
 EXIF_TAG_COMPONENTS_CONFIGURATION = 0x9101,
 EXIF_TAG_COMPRESSED_BITS_PER_PIXEL = 0x9102,
 EXIF_TAG_SHUTTER_SPEED_VALUE = 0x9201,
 EXIF_TAG_APERTURE_VALUE = 0x9202,
 EXIF_TAG_BRIGHTNESS_VALUE = 0x9203,
 EXIF_TAG_EXPOSURE_BIAS_VALUE = 0x9204,
 EXIF_TAG_MAX_APERTURE_VALUE = 0x9205,
 EXIF_TAG_SUBJECT_DISTANCE = 0x9206,
 EXIF_TAG_METERING_MODE = 0x9207,
 EXIF_TAG_LIGHT_SOURCE = 0x9208,
 EXIF_TAG_FLASH = 0x9209,
 EXIF_TAG_FOCAL_LENGTH = 0x920a,
 EXIF_TAG_SUBJECT_AREA = 0x9214,
 EXIF_TAG_TIFF_EP_STANDARD_ID = 0x9216,
 EXIF_TAG_MAKER_NOTE = 0x927c,
 EXIF_TAG_USER_COMMENT = 0x9286,
 EXIF_TAG_SUB_SEC_TIME = 0x9290,
 EXIF_TAG_SUB_SEC_TIME_ORIGINAL = 0x9291,
 EXIF_TAG_SUB_SEC_TIME_DIGITIZED = 0x9292,
 EXIF_TAG_XP_TITLE = 0x9c9b,
 EXIF_TAG_XP_COMMENT = 0x9c9c,
 EXIF_TAG_XP_AUTHOR = 0x9c9d,
 EXIF_TAG_XP_KEYWORDS = 0x9c9e,
 EXIF_TAG_XP_SUBJECT = 0x9c9f,
 EXIF_TAG_FLASH_PIX_VERSION = 0xa000,
 EXIF_TAG_COLOR_SPACE = 0xa001,
 EXIF_TAG_PIXEL_X_DIMENSION = 0xa002,
 EXIF_TAG_PIXEL_Y_DIMENSION = 0xa003,
 EXIF_TAG_RELATED_SOUND_FILE = 0xa004,
 EXIF_TAG_INTEROPERABILITY_IFD_POINTER = 0xa005,
 EXIF_TAG_FLASH_ENERGY = 0xa20b,
 EXIF_TAG_SPATIAL_FREQUENCY_RESPONSE = 0xa20c,
 EXIF_TAG_FOCAL_PLANE_X_RESOLUTION = 0xa20e,
 EXIF_TAG_FOCAL_PLANE_Y_RESOLUTION = 0xa20f,
 EXIF_TAG_FOCAL_PLANE_RESOLUTION_UNIT = 0xa210,
 EXIF_TAG_SUBJECT_LOCATION = 0xa214,
 EXIF_TAG_EXPOSURE_INDEX = 0xa215,
 EXIF_TAG_SENSING_METHOD = 0xa217,
 EXIF_TAG_FILE_SOURCE = 0xa300,
 EXIF_TAG_SCENE_TYPE = 0xa301,
 EXIF_TAG_NEW_CFA_PATTERN = 0xa302,
 EXIF_TAG_CUSTOM_RENDERED = 0xa401,
 EXIF_TAG_EXPOSURE_MODE = 0xa402,
 EXIF_TAG_WHITE_BALANCE = 0xa403,
 EXIF_TAG_DIGITAL_ZOOM_RATIO = 0xa404,
 EXIF_TAG_FOCAL_LENGTH_IN_35MM_FILM = 0xa405,
 EXIF_TAG_SCENE_CAPTURE_TYPE = 0xa406,
 EXIF_TAG_GAIN_CONTROL = 0xa407,
 EXIF_TAG_CONTRAST = 0xa408,
 EXIF_TAG_SATURATION = 0xa409,
 EXIF_TAG_SHARPNESS = 0xa40a,
 EXIF_TAG_DEVICE_SETTING_DESCRIPTION = 0xa40b,
 EXIF_TAG_SUBJECT_DISTANCE_RANGE = 0xa40c,
 EXIF_TAG_IMAGE_UNIQUE_ID = 0xa420,
 EXIF_TAG_GAMMA = 0xa500,
 EXIF_TAG_PRINT_IMAGE_MATCHING = 0xc4a5,
 EXIF_TAG_PADDING = 0xea1c
} ExifTag;
typedef enum {
 EXIF_SUPPORT_LEVEL_UNKNOWN = 0,
 EXIF_SUPPORT_LEVEL_NOT_RECORDED,
 EXIF_SUPPORT_LEVEL_MANDATORY,
 EXIF_SUPPORT_LEVEL_OPTIONAL
} ExifSupportLevel;
ExifTag exif_tag_from_name (const char *name);
const char *exif_tag_get_name_in_ifd (ExifTag tag, ExifIfd ifd);
const char *exif_tag_get_title_in_ifd (ExifTag tag, ExifIfd ifd);
const char *exif_tag_get_description_in_ifd (ExifTag tag, ExifIfd ifd);
ExifSupportLevel exif_tag_get_support_level_in_ifd (ExifTag tag, ExifIfd ifd,
                                                    ExifDataType t);
const char *exif_tag_get_name (ExifTag tag);
const char *exif_tag_get_title (ExifTag tag);
const char *exif_tag_get_description (ExifTag tag);
ExifTag exif_tag_table_get_tag (unsigned int n);
const char *exif_tag_table_get_name (unsigned int n);
unsigned int exif_tag_table_count (void);
typedef struct _ExifData ExifData;
typedef struct _ExifDataPrivate ExifDataPrivate;
typedef struct _ExifContent ExifContent;
typedef struct _ExifContentPrivate ExifContentPrivate;
typedef struct _ExifEntry ExifEntry;
typedef struct _ExifEntryPrivate ExifEntryPrivate;
struct _ExifEntry {
        ExifTag tag;
        ExifFormat format;
        unsigned long components;
        unsigned char *data;
        unsigned int size;
 ExifContent *parent;
 ExifEntryPrivate *priv;
};
ExifEntry *exif_entry_new (void);
ExifEntry *exif_entry_new_mem (ExifMem *);
void exif_entry_ref (ExifEntry *entry);
void exif_entry_unref (ExifEntry *entry);
void exif_entry_free (ExifEntry *entry);
void exif_entry_initialize (ExifEntry *e, ExifTag tag);
void exif_entry_fix (ExifEntry *entry);
const char *exif_entry_get_value (ExifEntry *entry, char *val,
      unsigned int maxlen);
void exif_entry_dump (ExifEntry *entry, unsigned int indent);
struct _ExifContent
{
        ExifEntry **entries;
        unsigned int count;
 ExifData *parent;
 ExifContentPrivate *priv;
};
ExifContent *exif_content_new (void);
ExifContent *exif_content_new_mem (ExifMem *);
void exif_content_ref (ExifContent *content);
void exif_content_unref (ExifContent *content);
void exif_content_free (ExifContent *content);
void exif_content_add_entry (ExifContent *c, ExifEntry *entry);
void exif_content_remove_entry (ExifContent *c, ExifEntry *e);
ExifEntry *exif_content_get_entry (ExifContent *content, ExifTag tag);
void exif_content_fix (ExifContent *c);
typedef void (* ExifContentForeachEntryFunc) (ExifEntry *, void *user_data);
void exif_content_foreach_entry (ExifContent *content,
      ExifContentForeachEntryFunc func,
      void *user_data);
ExifIfd exif_content_get_ifd (ExifContent *c);
void exif_content_dump (ExifContent *content, unsigned int indent);
void exif_content_log (ExifContent *content, ExifLog *log);
typedef struct _ExifMnoteData ExifMnoteData;
void exif_mnote_data_ref (ExifMnoteData *);
void exif_mnote_data_unref (ExifMnoteData *);
void exif_mnote_data_load (ExifMnoteData *d, const unsigned char *buf,
      unsigned int buf_siz);
void exif_mnote_data_save (ExifMnoteData *d, unsigned char **buf,
      unsigned int *buf_siz);
unsigned int exif_mnote_data_count (ExifMnoteData *d);
unsigned int exif_mnote_data_get_id (ExifMnoteData *d, unsigned int n);
const char *exif_mnote_data_get_name (ExifMnoteData *d, unsigned int n);
const char *exif_mnote_data_get_title (ExifMnoteData *d, unsigned int n);
const char *exif_mnote_data_get_description (ExifMnoteData *d, unsigned int n);
char *exif_mnote_data_get_value (ExifMnoteData *d, unsigned int n, char *val, unsigned int maxlen);
void exif_mnote_data_log (ExifMnoteData *, ExifLog *);
struct _ExifData
{
 ExifContent *ifd[EXIF_IFD_COUNT];
 unsigned char *data;
 unsigned int size;
 ExifDataPrivate *priv;
};
ExifData *exif_data_new (void);
ExifData *exif_data_new_mem (ExifMem *);
ExifData *exif_data_new_from_file (const char *path);
ExifData *exif_data_new_from_data (const unsigned char *data,
       unsigned int size);
void exif_data_load_data (ExifData *data, const unsigned char *d,
          unsigned int size);
void exif_data_save_data (ExifData *data, unsigned char **d,
          unsigned int *ds);
void exif_data_ref (ExifData *data);
void exif_data_unref (ExifData *data);
void exif_data_free (ExifData *data);
ExifByteOrder exif_data_get_byte_order (ExifData *data);
void exif_data_set_byte_order (ExifData *data, ExifByteOrder order);
ExifMnoteData *exif_data_get_mnote_data (ExifData *d);
void exif_data_fix (ExifData *d);
typedef void (* ExifDataForeachContentFunc) (ExifContent *, void *user_data);
void exif_data_foreach_content (ExifData *data,
      ExifDataForeachContentFunc func,
      void *user_data);
typedef enum {
 EXIF_DATA_OPTION_IGNORE_UNKNOWN_TAGS = 1 << 0,
 EXIF_DATA_OPTION_FOLLOW_SPECIFICATION = 1 << 1,
 EXIF_DATA_OPTION_DONT_CHANGE_MAKER_NOTE = 1 << 2
} ExifDataOption;
const char *exif_data_option_get_name (ExifDataOption o);
const char *exif_data_option_get_description (ExifDataOption o);
void exif_data_set_option (ExifData *d, ExifDataOption o);
void exif_data_unset_option (ExifData *d, ExifDataOption o);
void exif_data_set_data_type (ExifData *d, ExifDataType dt);
ExifDataType exif_data_get_data_type (ExifData *d);
void exif_data_dump (ExifData *data);
void exif_data_log (ExifData *data, ExifLog *log);
typedef struct _ExifLoader ExifLoader;
ExifLoader *exif_loader_new (void);
ExifLoader *exif_loader_new_mem (ExifMem *mem);
void exif_loader_ref (ExifLoader *loader);
void exif_loader_unref (ExifLoader *loader);
void exif_loader_write_file (ExifLoader *loader, const char *fname);
unsigned char exif_loader_write (ExifLoader *loader, unsigned char *buf, unsigned int sz);
void exif_loader_reset (ExifLoader *loader);
ExifData *exif_loader_get_data (ExifLoader *loader);
void exif_loader_get_buf (ExifLoader *loader, const unsigned char **buf,
        unsigned int *buf_size);
void exif_loader_log (ExifLoader *loader, ExifLog *log);
]]
