--result of cpp png.h from libpng 1.5.12 (and no longjmp stuff)
local ffi = require'ffi'

ffi.cdef[[
typedef struct FILE FILE;
typedef int32_t __time32_t;

enum {
	PNG_TEXT_COMPRESSION_NONE_WR = -3,
	PNG_TEXT_COMPRESSION_zTXt_WR = -2,
	PNG_TEXT_COMPRESSION_NONE = -1,
	PNG_TEXT_COMPRESSION_zTXt = 0,
	PNG_ITXT_COMPRESSION_NONE = 1,
	PNG_ITXT_COMPRESSION_zTXt = 2,
	PNG_HAVE_IHDR = 0x01,
	PNG_HAVE_PLTE = 0x02,
	PNG_AFTER_IDAT = 0x08,
	PNG_FP_1 = 100000,
	PNG_FP_HALF = 50000,
	PNG_COLOR_MASK_PALETTE = 1,
	PNG_COLOR_MASK_COLOR = 2,
	PNG_COLOR_MASK_ALPHA = 4,
	PNG_COLOR_TYPE_GRAY = 0,
	PNG_COLOR_TYPE_PALETTE = 3,
	PNG_COLOR_TYPE_RGB = 2,
	PNG_COLOR_TYPE_RGB_ALPHA = 6,
	PNG_COLOR_TYPE_GRAY_ALPHA = 4,
	PNG_COLOR_TYPE_RGBA = PNG_COLOR_TYPE_RGB_ALPHA,
	PNG_COLOR_TYPE_GA = PNG_COLOR_TYPE_GRAY_ALPHA,
	PNG_COMPRESSION_TYPE_BASE = 0,
	PNG_COMPRESSION_TYPE_DEFAULT = PNG_COMPRESSION_TYPE_BASE,
	PNG_FILTER_TYPE_BASE = 0,
	PNG_INTRAPIXEL_DIFFERENCING = 64,
	PNG_FILTER_TYPE_DEFAULT = PNG_FILTER_TYPE_BASE,
	PNG_INTERLACE_NONE = 0,
	PNG_INTERLACE_ADAM7 = 1,
	PNG_OFFSET_PIXEL = 0,
	PNG_OFFSET_MICROMETER = 1,
	PNG_EQUATION_LINEAR = 0,
	PNG_EQUATION_BASE_E = 1,
	PNG_EQUATION_ARBITRARY = 2,
	PNG_EQUATION_HYPERBOLIC = 3,
	PNG_SCALE_UNKNOWN = 0,
	PNG_SCALE_METER = 1,
	PNG_SCALE_RADIAN = 2,
	PNG_RESOLUTION_UNKNOWN = 0,
	PNG_RESOLUTION_METER = 1,
	PNG_sRGB_INTENT_PERCEPTUAL = 0,
	PNG_sRGB_INTENT_RELATIVE = 1,
	PNG_sRGB_INTENT_SATURATION = 2,
	PNG_sRGB_INTENT_ABSOLUTE = 3,
	PNG_KEYWORD_MAX_LENGTH = 79,
	PNG_MAX_PALETTE_LENGTH = 256,
	PNG_INFO_gAMA = 0x0001,
	PNG_INFO_sBIT = 0x0002,
	PNG_INFO_cHRM = 0x0004,
	PNG_INFO_PLTE = 0x0008,
	PNG_INFO_tRNS = 0x0010,
	PNG_INFO_bKGD = 0x0020,
	PNG_INFO_hIST = 0x0040,
	PNG_INFO_pHYs = 0x0080,
	PNG_INFO_oFFs = 0x0100,
	PNG_INFO_tIME = 0x0200,
	PNG_INFO_pCAL = 0x0400,
	PNG_INFO_sRGB = 0x0800,
	PNG_INFO_iCCP = 0x1000,
	PNG_INFO_sPLT = 0x2000,
	PNG_INFO_sCAL = 0x4000,
	PNG_INFO_IDAT = 0x8000,
	PNG_TRANSFORM_IDENTITY = 0x0000,
	PNG_TRANSFORM_STRIP_16 = 0x0001,
	PNG_TRANSFORM_STRIP_ALPHA = 0x0002,
	PNG_TRANSFORM_PACKING = 0x0004,
	PNG_TRANSFORM_PACKSWAP = 0x0008,
	PNG_TRANSFORM_EXPAND = 0x0010,
	PNG_TRANSFORM_INVERT_MONO = 0x0020,
	PNG_TRANSFORM_SHIFT = 0x0040,
	PNG_TRANSFORM_BGR = 0x0080,
	PNG_TRANSFORM_SWAP_ALPHA = 0x0100,
	PNG_TRANSFORM_SWAP_ENDIAN = 0x0200,
	PNG_TRANSFORM_INVERT_ALPHA = 0x0400,
	PNG_TRANSFORM_STRIP_FILLER = 0x0800,
	PNG_TRANSFORM_STRIP_FILLER_BEFORE = PNG_TRANSFORM_STRIP_FILLER,
	PNG_TRANSFORM_STRIP_FILLER_AFTER = 0x1000,
	PNG_TRANSFORM_GRAY_TO_RGB = 0x2000,
	PNG_TRANSFORM_EXPAND_16 = 0x4000,
	PNG_TRANSFORM_SCALE_16 = 0x8000,
	PNG_FLAG_MNG_EMPTY_PLTE = 0x01,
	PNG_FLAG_MNG_FILTER_64 = 0x04,
	PNG_ALL_MNG_FEATURES = 0x05,
	PNG_ERROR_ACTION_NONE = 1,
	PNG_ERROR_ACTION_WARN = 2,
	PNG_ERROR_ACTION_ERROR = 3,
	PNG_RGB_TO_GRAY_DEFAULT = -1,
	PNG_ALPHA_PNG = 0,
	PNG_ALPHA_STANDARD = 1,
	PNG_ALPHA_ASSOCIATED = 1,
	PNG_ALPHA_PREMULTIPLIED = 1,
	PNG_ALPHA_OPTIMIZED = 2,
	PNG_ALPHA_BROKEN = 3,
	PNG_DEFAULT_sRGB = -1,
	PNG_GAMMA_MAC_18 = -2,
	PNG_GAMMA_sRGB = 220000,
	PNG_GAMMA_LINEAR = PNG_FP_1,
	PNG_BACKGROUND_GAMMA_UNKNOWN = 0,
	PNG_BACKGROUND_GAMMA_SCREEN  = 1,
	PNG_BACKGROUND_GAMMA_FILE    = 2,
	PNG_BACKGROUND_GAMMA_UNIQUE  = 3,
	PNG_FILLER_BEFORE = 0,
	PNG_FILLER_AFTER = 1,
	PNG_GAMMA_THRESHOLD_FIXED = 5000,
	PNG_CRC_DEFAULT = 0,
	PNG_CRC_ERROR_QUIT = 1,
	PNG_CRC_WARN_DISCARD = 2,
	PNG_CRC_WARN_USE = 3,
	PNG_CRC_QUIET_USE = 4,
	PNG_CRC_NO_CHANGE = 5,
	PNG_NO_FILTERS = 0x00,
	PNG_FILTER_NONE = 0x08,
	PNG_FILTER_SUB = 0x10,
	PNG_FILTER_UP = 0x20,
	PNG_FILTER_AVG = 0x40,
	PNG_FILTER_PAETH = 0x80,
	PNG_ALL_FILTERS = 0xf8,
	PNG_FILTER_VALUE_NONE = 0,
	PNG_FILTER_VALUE_SUB = 1,
	PNG_FILTER_VALUE_UP = 2,
	PNG_FILTER_VALUE_AVG = 3,
	PNG_FILTER_VALUE_PAETH = 4,
	PNG_FILTER_HEURISTIC_DEFAULT = 0,
	PNG_FILTER_HEURISTIC_UNWEIGHTED = 1,
	PNG_FILTER_HEURISTIC_WEIGHTED = 2,
	PNG_FREE_HIST = 0x0008,
	PNG_FREE_ICCP = 0x0010,
	PNG_FREE_SPLT = 0x0020,
	PNG_FREE_ROWS = 0x0040,
	PNG_FREE_PCAL = 0x0080,
	PNG_FREE_SCAL = 0x0100,
	PNG_FREE_UNKN = 0x0200,
	PNG_FREE_PLTE = 0x1000,
	PNG_FREE_TRNS = 0x2000,
	PNG_FREE_TEXT = 0x4000,
	PNG_FREE_ALL = 0x7fff,
	PNG_FREE_MUL = 0x4220,
	PNG_HANDLE_CHUNK_AS_DEFAULT = 0,
	PNG_HANDLE_CHUNK_NEVER = 1,
	PNG_HANDLE_CHUNK_IF_SAFE = 2,
	PNG_HANDLE_CHUNK_ALWAYS = 3
};

typedef unsigned int png_uint_32;
typedef int png_int_32;
typedef unsigned short png_uint_16;
typedef short png_int_16;
typedef unsigned char png_byte;
typedef size_t png_size_t;
typedef png_int_32 png_fixed_point;
typedef void * png_voidp;
typedef const void * png_const_voidp;
typedef png_byte * png_bytep;
typedef const png_byte * png_const_bytep;
typedef png_uint_32 * png_uint_32p;
typedef const png_uint_32 * png_const_uint_32p;
typedef png_int_32 * png_int_32p;
typedef const png_int_32 * png_const_int_32p;
typedef png_uint_16 * png_uint_16p;
typedef const png_uint_16 * png_const_uint_16p;
typedef png_int_16 * png_int_16p;
typedef const png_int_16 * png_const_int_16p;
typedef char * png_charp;
typedef const char * png_const_charp;
typedef png_fixed_point * png_fixed_point_p;
typedef const png_fixed_point * png_const_fixed_point_p;
typedef png_size_t * png_size_tp;
typedef const png_size_t * png_const_size_tp;
typedef FILE * png_FILE_p;
typedef double * png_doublep;
typedef const double * png_const_doublep;
typedef png_byte * * png_bytepp;
typedef png_uint_32 * * png_uint_32pp;
typedef png_int_32 * * png_int_32pp;
typedef png_uint_16 * * png_uint_16pp;
typedef png_int_16 * * png_int_16pp;
typedef const char * * png_const_charpp;
typedef char * * png_charpp;
typedef png_fixed_point * * png_fixed_point_pp;
typedef double * * png_doublepp;
typedef char * * * png_charppp;
typedef png_size_t png_alloc_size_t;
typedef char* png_libpng_version_1_5_12;
typedef struct png_color_struct
{
   png_byte red;
   png_byte green;
   png_byte blue;
} png_color;
typedef png_color * png_colorp;
typedef const png_color * png_const_colorp;
typedef png_color * * png_colorpp;
typedef struct png_color_16_struct
{
   png_byte index;
   png_uint_16 red;
   png_uint_16 green;
   png_uint_16 blue;
   png_uint_16 gray;
} png_color_16;
typedef png_color_16 * png_color_16p;
typedef const png_color_16 * png_const_color_16p;
typedef png_color_16 * * png_color_16pp;
typedef struct png_color_8_struct
{
   png_byte red;
   png_byte green;
   png_byte blue;
   png_byte gray;
   png_byte alpha;
} png_color_8;
typedef png_color_8 * png_color_8p;
typedef const png_color_8 * png_const_color_8p;
typedef png_color_8 * * png_color_8pp;
typedef struct png_sPLT_entry_struct
{
   png_uint_16 red;
   png_uint_16 green;
   png_uint_16 blue;
   png_uint_16 alpha;
   png_uint_16 frequency;
} png_sPLT_entry;
typedef png_sPLT_entry * png_sPLT_entryp;
typedef const png_sPLT_entry * png_const_sPLT_entryp;
typedef png_sPLT_entry * * png_sPLT_entrypp;
typedef struct png_sPLT_struct
{
   png_charp name;
   png_byte depth;
   png_sPLT_entryp entries;
   png_int_32 nentries;
} png_sPLT_t;
typedef png_sPLT_t * png_sPLT_tp;
typedef const png_sPLT_t * png_const_sPLT_tp;
typedef png_sPLT_t * * png_sPLT_tpp;
typedef struct png_text_struct
{
   int compression;
   png_charp key;
   png_charp text;
   png_size_t text_length;
   png_size_t itxt_length;
   png_charp lang;
   png_charp lang_key;
} png_text;
typedef png_text * png_textp;
typedef const png_text * png_const_textp;
typedef png_text * * png_textpp;
typedef struct png_time_struct
{
   png_uint_16 year;
   png_byte month;
   png_byte day;
   png_byte hour;
   png_byte minute;
   png_byte second;
} png_time;
typedef png_time * png_timep;
typedef const png_time * png_const_timep;
typedef png_time * * png_timepp;
typedef struct png_unknown_chunk_t
{
    png_byte name[5];
    png_byte *data;
    png_size_t size;
    png_byte location;
}
png_unknown_chunk;
typedef png_unknown_chunk * png_unknown_chunkp;
typedef const png_unknown_chunk * png_const_unknown_chunkp;
typedef png_unknown_chunk * * png_unknown_chunkpp;
typedef struct png_info_def png_info;
typedef png_info * png_infop;
typedef const png_info * png_const_infop;
typedef png_info * * png_infopp;
typedef struct png_row_info_struct
{
   png_uint_32 width;
   png_size_t rowbytes;
   png_byte color_type;
   png_byte bit_depth;
   png_byte channels;
   png_byte pixel_depth;
} png_row_info;
typedef png_row_info * png_row_infop;
typedef png_row_info * * png_row_infopp;
typedef struct png_struct_def png_struct;
typedef const png_struct * png_const_structp;
typedef png_struct * png_structp;
typedef void (*png_error_ptr) (png_structp, png_const_charp);
typedef void (*png_rw_ptr) (png_structp, png_bytep, png_size_t);
typedef void (*png_flush_ptr) (png_structp);
typedef void (*png_read_status_ptr) (png_structp, png_uint_32, int);
typedef void (*png_write_status_ptr) (png_structp, png_uint_32, int);
typedef void (*png_progressive_info_ptr) (png_structp, png_infop);
typedef void (*png_progressive_end_ptr) (png_structp, png_infop);
typedef void (*png_progressive_row_ptr) (png_structp, png_bytep, png_uint_32, int);
typedef void (*png_user_transform_ptr) (png_structp, png_row_infop, png_bytep);
typedef int (*png_user_chunk_ptr) (png_structp, png_unknown_chunkp);
typedef void (*png_unknown_chunk_ptr) (png_structp);
typedef png_voidp (*png_malloc_ptr) (png_structp, png_alloc_size_t);
typedef void (*png_free_ptr) (png_structp, png_voidp);
typedef png_struct * * png_structpp;
png_uint_32 (png_access_version_number) (void);
void (png_set_sig_bytes) (png_structp png_ptr, int num_bytes);
int (png_sig_cmp) (png_const_bytep sig, png_size_t start, png_size_t num_to_check);
png_structp (png_create_read_struct) (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn);
png_structp (png_create_write_struct) (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn);
png_size_t (png_get_compression_buffer_size) (png_const_structp png_ptr);
void (png_set_compression_buffer_size) (png_structp png_ptr, png_size_t size);
void (png_longjmp) (png_structp png_ptr, int val);
int (png_reset_zstream) (png_structp png_ptr);
png_structp (png_create_read_struct_2) (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn, png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);
png_structp (png_create_write_struct_2) (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn, png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);
void (png_write_sig) (png_structp png_ptr);
void (png_write_chunk) (png_structp png_ptr, png_const_bytep chunk_name, png_const_bytep data, png_size_t length);
void (png_write_chunk_start) (png_structp png_ptr, png_const_bytep chunk_name, png_uint_32 length);
void (png_write_chunk_data) (png_structp png_ptr, png_const_bytep data, png_size_t length);
void (png_write_chunk_end) (png_structp png_ptr);
png_infop (png_create_info_struct) (png_structp png_ptr);
void (png_info_init_3) (png_infopp info_ptr, png_size_t png_info_struct_size);
void (png_write_info_before_PLTE) (png_structp png_ptr, png_infop info_ptr);
void (png_write_info) (png_structp png_ptr, png_infop info_ptr);
void (png_read_info) (png_structp png_ptr, png_infop info_ptr);
png_const_charp (png_convert_to_rfc1123) (png_structp png_ptr, png_const_timep ptime);
void (png_convert_from_struct_tm) (png_timep ptime, const struct tm * ttime);
void (png_convert_from_time_t) (png_timep ptime, __time32_t ttime);
void (png_set_expand) (png_structp png_ptr);
void (png_set_expand_gray_1_2_4_to_8) (png_structp png_ptr);
void (png_set_palette_to_rgb) (png_structp png_ptr);
void (png_set_tRNS_to_alpha) (png_structp png_ptr);
void (png_set_expand_16) (png_structp png_ptr);
void (png_set_bgr) (png_structp png_ptr);
void (png_set_gray_to_rgb) (png_structp png_ptr);
void (png_set_rgb_to_gray) (png_structp png_ptr, int error_action, double red, double green);
void (png_set_rgb_to_gray_fixed) (png_structp png_ptr, int error_action, png_fixed_point red, png_fixed_point green);
png_byte (png_get_rgb_to_gray_status) (png_const_structp png_ptr);
void (png_build_grayscale_palette) (int bit_depth, png_colorp palette);
void (png_set_alpha_mode) (png_structp png_ptr, int mode, double output_gamma);
void (png_set_alpha_mode_fixed) (png_structp png_ptr, int mode, png_fixed_point output_gamma);
void (png_set_strip_alpha) (png_structp png_ptr);
void (png_set_swap_alpha) (png_structp png_ptr);
void (png_set_invert_alpha) (png_structp png_ptr);
void (png_set_filler) (png_structp png_ptr, png_uint_32 filler, int flags);
void (png_set_add_alpha) (png_structp png_ptr, png_uint_32 filler, int flags);
void (png_set_swap) (png_structp png_ptr);
void (png_set_packing) (png_structp png_ptr);
void (png_set_packswap) (png_structp png_ptr);
void (png_set_shift) (png_structp png_ptr, png_const_color_8p true_bits);
int (png_set_interlace_handling) (png_structp png_ptr);
void (png_set_invert_mono) (png_structp png_ptr);
void (png_set_background) (png_structp png_ptr, png_const_color_16p background_color, int background_gamma_code, int need_expand, double background_gamma);
void (png_set_background_fixed) (png_structp png_ptr, png_const_color_16p background_color, int background_gamma_code, int need_expand, png_fixed_point background_gamma);
void (png_set_scale_16) (png_structp png_ptr);
void (png_set_strip_16) (png_structp png_ptr);
void (png_set_quantize) (png_structp png_ptr, png_colorp palette, int num_palette, int maximum_colors, png_const_uint_16p histogram, int full_quantize);
void (png_set_gamma) (png_structp png_ptr, double screen_gamma, double override_file_gamma);
void (png_set_gamma_fixed) (png_structp png_ptr, png_fixed_point screen_gamma, png_fixed_point override_file_gamma);
void (png_set_flush) (png_structp png_ptr, int nrows);
void (png_write_flush) (png_structp png_ptr);
void (png_start_read_image) (png_structp png_ptr);
void (png_read_update_info) (png_structp png_ptr, png_infop info_ptr);
void (png_read_rows) (png_structp png_ptr, png_bytepp row, png_bytepp display_row, png_uint_32 num_rows);
void (png_read_row) (png_structp png_ptr, png_bytep row, png_bytep display_row);
void (png_read_image) (png_structp png_ptr, png_bytepp image);
void (png_write_row) (png_structp png_ptr, png_const_bytep row);
void (png_write_rows) (png_structp png_ptr, png_bytepp row, png_uint_32 num_rows);
void (png_write_image) (png_structp png_ptr, png_bytepp image);
void (png_write_end) (png_structp png_ptr, png_infop info_ptr);
void (png_read_end) (png_structp png_ptr, png_infop info_ptr);
void (png_destroy_info_struct) (png_structp png_ptr, png_infopp info_ptr_ptr);
void (png_destroy_read_struct) (png_structpp png_ptr_ptr, png_infopp info_ptr_ptr, png_infopp end_info_ptr_ptr);
void (png_destroy_write_struct) (png_structpp png_ptr_ptr, png_infopp info_ptr_ptr);
void (png_set_crc_action) (png_structp png_ptr, int crit_action, int ancil_action);
void (png_set_filter) (png_structp png_ptr, int method, int filters);
void (png_set_filter_heuristics) (png_structp png_ptr, int heuristic_method, int num_weights, png_const_doublep filter_weights, png_const_doublep filter_costs);
void (png_set_filter_heuristics_fixed) (png_structp png_ptr, int heuristic_method, int num_weights, png_const_fixed_point_p filter_weights, png_const_fixed_point_p filter_costs);
void (png_set_compression_level) (png_structp png_ptr, int level);
void (png_set_compression_mem_level) (png_structp png_ptr, int mem_level);
void (png_set_compression_strategy) (png_structp png_ptr, int strategy);
void (png_set_compression_window_bits) (png_structp png_ptr, int window_bits);
void (png_set_compression_method) (png_structp png_ptr, int method);
void (png_set_text_compression_level) (png_structp png_ptr, int level);
void (png_set_text_compression_mem_level) (png_structp png_ptr, int mem_level);
void (png_set_text_compression_strategy) (png_structp png_ptr, int strategy);
void (png_set_text_compression_window_bits) (png_structp png_ptr, int window_bits);
void (png_set_text_compression_method) (png_structp png_ptr, int method);
void (png_init_io) (png_structp png_ptr, png_FILE_p fp);
void (png_set_error_fn) (png_structp png_ptr, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warning_fn);
png_voidp (png_get_error_ptr) (png_const_structp png_ptr);
void (png_set_write_fn) (png_structp png_ptr, png_voidp io_ptr, png_rw_ptr write_data_fn, png_flush_ptr output_flush_fn);
void (png_set_read_fn) (png_structp png_ptr, png_voidp io_ptr, png_rw_ptr read_data_fn);
png_voidp (png_get_io_ptr) (png_structp png_ptr);
void (png_set_read_status_fn) (png_structp png_ptr, png_read_status_ptr read_row_fn);
void (png_set_write_status_fn) (png_structp png_ptr, png_write_status_ptr write_row_fn);
void (png_set_mem_fn) (png_structp png_ptr, png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);
png_voidp (png_get_mem_ptr) (png_const_structp png_ptr);
void (png_set_read_user_transform_fn) (png_structp png_ptr, png_user_transform_ptr read_user_transform_fn);
void (png_set_write_user_transform_fn) (png_structp png_ptr, png_user_transform_ptr write_user_transform_fn);
void (png_set_user_transform_info) (png_structp png_ptr, png_voidp user_transform_ptr, int user_transform_depth, int user_transform_channels);
png_voidp (png_get_user_transform_ptr) (png_const_structp png_ptr);
png_uint_32 (png_get_current_row_number) (png_const_structp);
png_byte (png_get_current_pass_number) (png_const_structp);
void (png_set_read_user_chunk_fn) (png_structp png_ptr, png_voidp user_chunk_ptr, png_user_chunk_ptr read_user_chunk_fn);
png_voidp (png_get_user_chunk_ptr) (png_const_structp png_ptr);
void (png_set_progressive_read_fn) (png_structp png_ptr, png_voidp progressive_ptr, png_progressive_info_ptr info_fn, png_progressive_row_ptr row_fn, png_progressive_end_ptr end_fn);
png_voidp (png_get_progressive_ptr) (png_const_structp png_ptr);
void (png_process_data) (png_structp png_ptr, png_infop info_ptr, png_bytep buffer, png_size_t buffer_size);
png_size_t (png_process_data_pause) (png_structp, int save);
png_uint_32 (png_process_data_skip) (png_structp);
void (png_progressive_combine_row) (png_structp png_ptr, png_bytep old_row, png_const_bytep new_row);
png_voidp (png_malloc) (png_structp png_ptr, png_alloc_size_t size);
png_voidp (png_calloc) (png_structp png_ptr, png_alloc_size_t size);
png_voidp (png_malloc_warn) (png_structp png_ptr, png_alloc_size_t size);
void (png_free) (png_structp png_ptr, png_voidp ptr);
void (png_free_data) (png_structp png_ptr, png_infop info_ptr, png_uint_32 free_me, int num);
void (png_data_freer) (png_structp png_ptr, png_infop info_ptr, int freer, png_uint_32 mask);
png_voidp (png_malloc_default) (png_structp png_ptr, png_alloc_size_t size);
void (png_free_default) (png_structp png_ptr, png_voidp ptr);
void (png_error) (png_structp png_ptr, png_const_charp error_message);
void (png_chunk_error) (png_structp png_ptr, png_const_charp error_message);
void (png_warning) (png_structp png_ptr, png_const_charp warning_message);
void (png_chunk_warning) (png_structp png_ptr, png_const_charp warning_message);
void (png_benign_error) (png_structp png_ptr, png_const_charp warning_message);
void (png_chunk_benign_error) (png_structp png_ptr, png_const_charp warning_message);
void (png_set_benign_errors) (png_structp png_ptr, int allowed);
png_uint_32 (png_get_valid) (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_32 flag);
png_size_t (png_get_rowbytes) (png_const_structp png_ptr, png_const_infop info_ptr);
png_bytepp (png_get_rows) (png_const_structp png_ptr, png_const_infop info_ptr);
void (png_set_rows) (png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers);
png_byte (png_get_channels) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_image_width) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_image_height) (png_const_structp png_ptr, png_const_infop info_ptr);
png_byte (png_get_bit_depth) (png_const_structp png_ptr, png_const_infop info_ptr);
png_byte (png_get_color_type) (png_const_structp png_ptr, png_const_infop info_ptr);
png_byte (png_get_filter_type) (png_const_structp png_ptr, png_const_infop info_ptr);
png_byte (png_get_interlace_type) (png_const_structp png_ptr, png_const_infop info_ptr);
png_byte (png_get_compression_type) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_pixels_per_meter) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_x_pixels_per_meter) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_y_pixels_per_meter) (png_const_structp png_ptr, png_const_infop info_ptr);
float (png_get_pixel_aspect_ratio) (png_const_structp png_ptr, png_const_infop info_ptr);
png_fixed_point (png_get_pixel_aspect_ratio_fixed) (png_const_structp png_ptr, png_const_infop info_ptr);
png_int_32 (png_get_x_offset_pixels) (png_const_structp png_ptr, png_const_infop info_ptr);
png_int_32 (png_get_y_offset_pixels) (png_const_structp png_ptr, png_const_infop info_ptr);
png_int_32 (png_get_x_offset_microns) (png_const_structp png_ptr, png_const_infop info_ptr);
png_int_32 (png_get_y_offset_microns) (png_const_structp png_ptr, png_const_infop info_ptr);
png_const_bytep (png_get_signature) (png_const_structp png_ptr, png_infop info_ptr);
png_uint_32 (png_get_bKGD) (png_const_structp png_ptr, png_infop info_ptr, png_color_16p *background);
void (png_set_bKGD) (png_structp png_ptr, png_infop info_ptr, png_const_color_16p background);
png_uint_32 (png_get_cHRM) (png_const_structp png_ptr, png_const_infop info_ptr, double *white_x, double *white_y, double *red_x, double *red_y, double *green_x, double *green_y, double *blue_x, double *blue_y);
png_uint_32 (png_get_cHRM_XYZ) (png_structp png_ptr, png_const_infop info_ptr, double *red_X, double *red_Y, double *red_Z, double *green_X, double *green_Y, double *green_Z, double *blue_X, double *blue_Y, double *blue_Z);
png_uint_32 (png_get_cHRM_fixed) (png_const_structp png_ptr, png_const_infop info_ptr, png_fixed_point *int_white_x, png_fixed_point *int_white_y, png_fixed_point *int_red_x, png_fixed_point *int_red_y, png_fixed_point *int_green_x, png_fixed_point *int_green_y, png_fixed_point *int_blue_x, png_fixed_point *int_blue_y);
png_uint_32 (png_get_cHRM_XYZ_fixed) (png_structp png_ptr, png_const_infop info_ptr, png_fixed_point *int_red_X, png_fixed_point *int_red_Y, png_fixed_point *int_red_Z, png_fixed_point *int_green_X, png_fixed_point *int_green_Y, png_fixed_point *int_green_Z, png_fixed_point *int_blue_X, png_fixed_point *int_blue_Y, png_fixed_point *int_blue_Z);
void (png_set_cHRM) (png_structp png_ptr, png_infop info_ptr, double white_x, double white_y, double red_x, double red_y, double green_x, double green_y, double blue_x, double blue_y);
void (png_set_cHRM_XYZ) (png_structp png_ptr, png_infop info_ptr, double red_X, double red_Y, double red_Z, double green_X, double green_Y, double green_Z, double blue_X, double blue_Y, double blue_Z);
void (png_set_cHRM_fixed) (png_structp png_ptr, png_infop info_ptr, png_fixed_point int_white_x, png_fixed_point int_white_y, png_fixed_point int_red_x, png_fixed_point int_red_y, png_fixed_point int_green_x, png_fixed_point int_green_y, png_fixed_point int_blue_x, png_fixed_point int_blue_y);
void (png_set_cHRM_XYZ_fixed) (png_structp png_ptr, png_infop info_ptr, png_fixed_point int_red_X, png_fixed_point int_red_Y, png_fixed_point int_red_Z, png_fixed_point int_green_X, png_fixed_point int_green_Y, png_fixed_point int_green_Z, png_fixed_point int_blue_X, png_fixed_point int_blue_Y, png_fixed_point int_blue_Z);
png_uint_32 (png_get_gAMA) (png_const_structp png_ptr, png_const_infop info_ptr, double *file_gamma);
png_uint_32 (png_get_gAMA_fixed) (png_const_structp png_ptr, png_const_infop info_ptr, png_fixed_point *int_file_gamma);
void (png_set_gAMA) (png_structp png_ptr, png_infop info_ptr, double file_gamma);
void (png_set_gAMA_fixed) (png_structp png_ptr, png_infop info_ptr, png_fixed_point int_file_gamma);
png_uint_32 (png_get_hIST) (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_16p *hist);
void (png_set_hIST) (png_structp png_ptr, png_infop info_ptr, png_const_uint_16p hist);
png_uint_32 (png_get_IHDR) (png_structp png_ptr, png_infop info_ptr, png_uint_32 *width, png_uint_32 *height, int *bit_depth, int *color_type, int *interlace_method, int *compression_method, int *filter_method);
void (png_set_IHDR) (png_structp png_ptr, png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth, int color_type, int interlace_method, int compression_method, int filter_method);
png_uint_32 (png_get_oFFs) (png_const_structp png_ptr, png_const_infop info_ptr, png_int_32 *offset_x, png_int_32 *offset_y, int *unit_type);
void (png_set_oFFs) (png_structp png_ptr, png_infop info_ptr, png_int_32 offset_x, png_int_32 offset_y, int unit_type);
png_uint_32 (png_get_pCAL) (png_const_structp png_ptr, png_const_infop info_ptr, png_charp *purpose, png_int_32 *X0, png_int_32 *X1, int *type, int *nparams, png_charp *units, png_charpp *params);
void (png_set_pCAL) (png_structp png_ptr, png_infop info_ptr, png_const_charp purpose, png_int_32 X0, png_int_32 X1, int type, int nparams, png_const_charp units, png_charpp params);
png_uint_32 (png_get_pHYs) (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_32 *res_x, png_uint_32 *res_y, int *unit_type);
void (png_set_pHYs) (png_structp png_ptr, png_infop info_ptr, png_uint_32 res_x, png_uint_32 res_y, int unit_type);
png_uint_32 (png_get_PLTE) (png_const_structp png_ptr, png_const_infop info_ptr, png_colorp *palette, int *num_palette);
void (png_set_PLTE) (png_structp png_ptr, png_infop info_ptr, png_const_colorp palette, int num_palette);
png_uint_32 (png_get_sBIT) (png_const_structp png_ptr, png_infop info_ptr, png_color_8p *sig_bit);
void (png_set_sBIT) (png_structp png_ptr, png_infop info_ptr, png_const_color_8p sig_bit);
png_uint_32 (png_get_sRGB) (png_const_structp png_ptr, png_const_infop info_ptr, int *file_srgb_intent);
void (png_set_sRGB) (png_structp png_ptr, png_infop info_ptr, int srgb_intent);
void (png_set_sRGB_gAMA_and_cHRM) (png_structp png_ptr, png_infop info_ptr, int srgb_intent);
png_uint_32 (png_get_iCCP) (png_const_structp png_ptr, png_const_infop info_ptr, png_charpp name, int *compression_type, png_bytepp profile, png_uint_32 *proflen);
void (png_set_iCCP) (png_structp png_ptr, png_infop info_ptr, png_const_charp name, int compression_type, png_const_bytep profile, png_uint_32 proflen);
png_uint_32 (png_get_sPLT) (png_const_structp png_ptr, png_const_infop info_ptr, png_sPLT_tpp entries);
void (png_set_sPLT) (png_structp png_ptr, png_infop info_ptr, png_const_sPLT_tp entries, int nentries);
png_uint_32 (png_get_text) (png_const_structp png_ptr, png_const_infop info_ptr, png_textp *text_ptr, int *num_text);
void (png_set_text) (png_structp png_ptr, png_infop info_ptr, png_const_textp text_ptr, int num_text);
png_uint_32 (png_get_tIME) (png_const_structp png_ptr, png_infop info_ptr, png_timep *mod_time);
void (png_set_tIME) (png_structp png_ptr, png_infop info_ptr, png_const_timep mod_time);
png_uint_32 (png_get_tRNS) (png_const_structp png_ptr, png_infop info_ptr, png_bytep *trans_alpha, int *num_trans, png_color_16p *trans_color);
void (png_set_tRNS) (png_structp png_ptr, png_infop info_ptr, png_const_bytep trans_alpha, int num_trans, png_const_color_16p trans_color);
png_uint_32 (png_get_sCAL) (png_const_structp png_ptr, png_const_infop info_ptr, int *unit, double *width, double *height);
png_uint_32 (png_get_sCAL_fixed) (png_structp png_ptr, png_const_infop info_ptr, int *unit, png_fixed_point *width, png_fixed_point *height);
png_uint_32 (png_get_sCAL_s) (png_const_structp png_ptr, png_const_infop info_ptr, int *unit, png_charpp swidth, png_charpp sheight);
void (png_set_sCAL) (png_structp png_ptr, png_infop info_ptr, int unit, double width, double height);
void (png_set_sCAL_fixed) (png_structp png_ptr, png_infop info_ptr, int unit, png_fixed_point width, png_fixed_point height);
void (png_set_sCAL_s) (png_structp png_ptr, png_infop info_ptr, int unit, png_const_charp swidth, png_const_charp sheight);
void (png_set_keep_unknown_chunks) (png_structp png_ptr, int keep, png_const_bytep chunk_list, int num_chunks);
int (png_handle_as_unknown) (png_structp png_ptr, png_const_bytep chunk_name);
void (png_set_unknown_chunks) (png_structp png_ptr, png_infop info_ptr, png_const_unknown_chunkp unknowns, int num_unknowns);
void (png_set_unknown_chunk_location) (png_structp png_ptr, png_infop info_ptr, int chunk, int location);
int (png_get_unknown_chunks) (png_const_structp png_ptr, png_const_infop info_ptr, png_unknown_chunkpp entries);
void (png_set_invalid) (png_structp png_ptr, png_infop info_ptr, int mask);
void (png_read_png) (png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params);
void (png_write_png) (png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params);
png_const_charp (png_get_copyright) (png_const_structp png_ptr);
png_const_charp (png_get_header_ver) (png_const_structp png_ptr);
png_const_charp (png_get_header_version) (png_const_structp png_ptr);
png_const_charp (png_get_libpng_ver) (png_const_structp png_ptr);
png_uint_32 (png_permit_mng_features) (png_structp png_ptr, png_uint_32 mng_features_permitted);
void (png_set_user_limits) (png_structp png_ptr, png_uint_32 user_width_max, png_uint_32 user_height_max);
png_uint_32 (png_get_user_width_max) (png_const_structp png_ptr);
png_uint_32 (png_get_user_height_max) (png_const_structp png_ptr);
void (png_set_chunk_cache_max) (png_structp png_ptr, png_uint_32 user_chunk_cache_max);
png_uint_32 (png_get_chunk_cache_max) (png_const_structp png_ptr);
void (png_set_chunk_malloc_max) (png_structp png_ptr, png_alloc_size_t user_chunk_cache_max);
png_alloc_size_t (png_get_chunk_malloc_max) (png_const_structp png_ptr);
png_uint_32 (png_get_pixels_per_inch) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_x_pixels_per_inch) (png_const_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_y_pixels_per_inch) (png_const_structp png_ptr, png_const_infop info_ptr);
float (png_get_x_offset_inches) (png_const_structp png_ptr, png_const_infop info_ptr);
png_fixed_point (png_get_x_offset_inches_fixed) (png_structp png_ptr, png_const_infop info_ptr);
float (png_get_y_offset_inches) (png_const_structp png_ptr, png_const_infop info_ptr);
png_fixed_point (png_get_y_offset_inches_fixed) (png_structp png_ptr, png_const_infop info_ptr);
png_uint_32 (png_get_pHYs_dpi) (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_32 *res_x, png_uint_32 *res_y, int *unit_type);
png_uint_32 (png_get_io_state) (png_structp png_ptr);
png_const_bytep (png_get_io_chunk_name) (png_structp png_ptr);
png_uint_32 (png_get_io_chunk_type) (png_const_structp png_ptr);
png_uint_32 (png_get_uint_32) (png_const_bytep buf);
png_uint_16 (png_get_uint_16) (png_const_bytep buf);
png_int_32 (png_get_int_32) (png_const_bytep buf);
png_uint_32 (png_get_uint_31) (png_structp png_ptr, png_const_bytep buf);
void (png_save_uint_32) (png_bytep buf, png_uint_32 i);
void (png_save_int_32) (png_bytep buf, png_int_32 i);
void (png_save_uint_16) (png_bytep buf, unsigned int i);
void (png_set_check_for_invalid_index) (png_structp png_ptr, int allowed);
]]
