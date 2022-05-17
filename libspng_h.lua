require'ffi'.cdef[[

enum spng_text_type
{
	SPNG_TEXT = 1,
	SPNG_ZTXT = 2,
	SPNG_ITXT = 3
};

enum spng_color_type
{
	SPNG_COLOR_TYPE_GRAYSCALE = 0,
	SPNG_COLOR_TYPE_TRUECOLOR = 2,
	SPNG_COLOR_TYPE_INDEXED = 3,
	SPNG_COLOR_TYPE_GRAYSCALE_ALPHA = 4,
	SPNG_COLOR_TYPE_TRUECOLOR_ALPHA = 6
};

enum spng_filter
{
	SPNG_FILTER_NONE = 0,
	SPNG_FILTER_SUB = 1,
	SPNG_FILTER_UP = 2,
	SPNG_FILTER_AVERAGE = 3,
	SPNG_FILTER_PAETH = 4
};

enum spng_filter_choice
{
	SPNG_DISABLE_FILTERING = 0,
	SPNG_FILTER_CHOICE_NONE = 8,
	SPNG_FILTER_CHOICE_SUB = 16,
	SPNG_FILTER_CHOICE_UP = 32,
	SPNG_FILTER_CHOICE_AVG = 64,
	SPNG_FILTER_CHOICE_PAETH = 128,
	SPNG_FILTER_CHOICE_ALL = (8|16|32|64|128)
};

enum spng_interlace_method
{
	SPNG_INTERLACE_NONE = 0,
	SPNG_INTERLACE_ADAM7 = 1
};

/* Channels are always in byte-order */
enum spng_format
{
	SPNG_FMT_RGBA8 = 1,
	SPNG_FMT_RGBA16 = 2,
	SPNG_FMT_RGB8 = 4,

	/* Partially implemented, see documentation */
	SPNG_FMT_GA8 = 16,
	SPNG_FMT_GA16 = 32,
	SPNG_FMT_G8 = 64,

	/* No conversion or scaling */
	SPNG_FMT_PNG = 256, /* host-endian */
	SPNG_FMT_RAW = 512  /* big-endian */
};

enum spng_ctx_flags
{
	SPNG_CTX_IGNORE_ADLER32 = 1, /* Ignore checksum in DEFLATE streams */
	SPNG_CTX_ENCODER = 2 /* Create an encoder context */
};

enum spng_decode_flags
{
	SPNG_DECODE_USE_TRNS = 1, /* Deprecated */
	SPNG_DECODE_USE_GAMA = 2, /* Deprecated */
	SPNG_DECODE_USE_SBIT = 8, /* Undocumented */

	SPNG_DECODE_TRNS = 1, /* Apply transparency */
	SPNG_DECODE_GAMMA = 2, /* Apply gamma correction */
	SPNG_DECODE_PROGRESSIVE = 256 /* Initialize for progressive reads */
};

enum spng_crc_action
{
	/* Default for critical chunks */
	SPNG_CRC_ERROR = 0,

	/* Discard chunk, invalid for critical chunks.
	   Since v0.6.2: default for ancillary chunks */
	SPNG_CRC_DISCARD = 1,

	/* Ignore and don't calculate checksum.
	   Since v0.6.2: also ignores checksums in DEFLATE streams */
	SPNG_CRC_USE = 2
};

enum spng_encode_flags
{
	SPNG_ENCODE_PROGRESSIVE = 1, /* Initialize for progressive writes */
	SPNG_ENCODE_FINALIZE = 2, /* Finalize PNG after encoding image */
};

struct spng_ihdr
{
	uint32_t width;
	uint32_t height;
	uint8_t bit_depth;
	uint8_t color_type;
	uint8_t compression_method;
	uint8_t filter_method;
	uint8_t interlace_method;
};

struct spng_plte_entry
{
	uint8_t red;
	uint8_t green;
	uint8_t blue;

	uint8_t alpha; /* Reserved for internal use */
};

struct spng_plte
{
	uint32_t n_entries;
	struct spng_plte_entry entries[256];
};

struct spng_trns
{
	uint16_t gray;

	uint16_t red;
	uint16_t green;
	uint16_t blue;

	uint32_t n_type3_entries;
	uint8_t type3_alpha[256];
};

struct spng_chrm_int
{
	uint32_t white_point_x;
	uint32_t white_point_y;
	uint32_t red_x;
	uint32_t red_y;
	uint32_t green_x;
	uint32_t green_y;
	uint32_t blue_x;
	uint32_t blue_y;
};

struct spng_chrm
{
	double white_point_x;
	double white_point_y;
	double red_x;
	double red_y;
	double green_x;
	double green_y;
	double blue_x;
	double blue_y;
};

struct spng_iccp
{
	char profile_name[80];
	size_t profile_len;
	char *profile;
};

struct spng_sbit
{
	uint8_t grayscale_bits;
	uint8_t red_bits;
	uint8_t green_bits;
	uint8_t blue_bits;
	uint8_t alpha_bits;
};

struct spng_text
{
	char keyword[80];
	int type;

	size_t length;
	char *text;

	uint8_t compression_flag; /* iTXt only */
	uint8_t compression_method; /* iTXt, ztXt only */
	char *language_tag; /* iTXt only */
	char *translated_keyword; /* iTXt only */
};

struct spng_bkgd
{
	uint16_t gray; /* Only for gray/gray alpha */
	uint16_t red;
	uint16_t green;
	uint16_t blue;
	uint16_t plte_index; /* Only for indexed color */
};

struct spng_hist
{
	uint16_t frequency[256];
};

struct spng_phys
{
	uint32_t ppu_x, ppu_y;
	uint8_t unit_specifier;
};

struct spng_splt_entry
{
	uint16_t red;
	uint16_t green;
	uint16_t blue;
	uint16_t alpha;
	uint16_t frequency;
};

struct spng_splt
{
	char name[80];
	uint8_t sample_depth;
	uint32_t n_entries;
	struct spng_splt_entry *entries;
};

struct spng_time
{
	uint16_t year;
	uint8_t month;
	uint8_t day;
	uint8_t hour;
	uint8_t minute;
	uint8_t second;
};

struct spng_offs
{
	int32_t x, y;
	uint8_t unit_specifier;
};

struct spng_exif
{
	size_t length;
	char *data;
};

struct spng_chunk
{
	size_t offset;
	uint32_t length;
	uint8_t type[4];
	uint32_t crc;
};

enum spng_location
{
	SPNG_AFTER_IHDR = 1,
	SPNG_AFTER_PLTE = 2,
	SPNG_AFTER_IDAT = 8,
};

struct spng_unknown_chunk
{
	uint8_t type[4];
	size_t length;
	void *data;
	enum spng_location location;
};

enum spng_option
{
	SPNG_KEEP_UNKNOWN_CHUNKS = 1,

	SPNG_IMG_COMPRESSION_LEVEL,
	SPNG_IMG_WINDOW_BITS,
	SPNG_IMG_MEM_LEVEL,
	SPNG_IMG_COMPRESSION_STRATEGY,

	SPNG_TEXT_COMPRESSION_LEVEL,
	SPNG_TEXT_WINDOW_BITS,
	SPNG_TEXT_MEM_LEVEL,
	SPNG_TEXT_COMPRESSION_STRATEGY,

	SPNG_FILTER_CHOICE,
	SPNG_CHUNK_COUNT_LIMIT,
	SPNG_ENCODE_TO_BUFFER,
};

struct spng_row_info
{
	uint32_t scanline_idx;
	uint32_t row_num; /* deinterlaced row index */
	int pass;
	uint8_t filter;
};

const char *spng_strerror(int err);
const char *spng_version_string(void);

typedef struct spng_ctx spng_ctx;
spng_ctx *spng_ctx_new(int flags);
void spng_ctx_free(spng_ctx *ctx);

typedef int spng_rw_fn(spng_ctx *ctx, void *user, uint8_t *dst_src, size_t length);
int spng_set_png_stream(spng_ctx *ctx, spng_rw_fn *rw_func, void *user);

int spng_set_image_limits(spng_ctx *ctx, uint32_t width, uint32_t height);
int spng_get_image_limits(spng_ctx *ctx, uint32_t *width, uint32_t *height);
int spng_set_chunk_limits(spng_ctx *ctx, size_t chunk_size, size_t cache_size);
int spng_get_chunk_limits(spng_ctx *ctx, size_t *chunk_size, size_t *cache_size);
int spng_set_crc_action(spng_ctx *ctx, int critical, int ancillary);
int spng_set_option(spng_ctx *ctx, enum spng_option option, int value);
int spng_get_option(spng_ctx *ctx, enum spng_option option, int *value);

/* Decode */
int spng_decoded_image_size(spng_ctx *ctx, int fmt, size_t *len);
int spng_decode_image(spng_ctx *ctx, void *out, size_t len, int fmt, int flags);
int spng_decode_row(spng_ctx *ctx, void *out, size_t len);
int spng_decode_chunks(spng_ctx *ctx);

/* Encode/decode */
int spng_get_row_info(spng_ctx *ctx, struct spng_row_info *row_info);

/* Encode */
int spng_encode_image(spng_ctx *ctx, const void *img, size_t len, int fmt, int flags);
int spng_encode_chunks(spng_ctx *ctx);

int spng_get_ihdr(spng_ctx *ctx, struct spng_ihdr *ihdr);
int spng_get_plte(spng_ctx *ctx, struct spng_plte *plte);
int spng_get_trns(spng_ctx *ctx, struct spng_trns *trns);
int spng_get_chrm(spng_ctx *ctx, struct spng_chrm *chrm);
int spng_get_chrm_int(spng_ctx *ctx, struct spng_chrm_int *chrm_int);
int spng_get_gama(spng_ctx *ctx, double *gamma);
int spng_get_gama_int(spng_ctx *ctx, uint32_t *gama_int);
int spng_get_iccp(spng_ctx *ctx, struct spng_iccp *iccp);
int spng_get_sbit(spng_ctx *ctx, struct spng_sbit *sbit);
int spng_get_srgb(spng_ctx *ctx, uint8_t *rendering_intent);
int spng_get_text(spng_ctx *ctx, struct spng_text *text, uint32_t *n_text);
int spng_get_bkgd(spng_ctx *ctx, struct spng_bkgd *bkgd);
int spng_get_hist(spng_ctx *ctx, struct spng_hist *hist);
int spng_get_phys(spng_ctx *ctx, struct spng_phys *phys);
int spng_get_splt(spng_ctx *ctx, struct spng_splt *splt, uint32_t *n_splt);
int spng_get_time(spng_ctx *ctx, struct spng_time *time);
int spng_get_unknown_chunks(spng_ctx *ctx, struct spng_unknown_chunk *chunks, uint32_t *n_chunks);
int spng_get_offs(spng_ctx *ctx, struct spng_offs *offs);
int spng_get_exif(spng_ctx *ctx, struct spng_exif *exif);

int spng_set_ihdr(spng_ctx *ctx, struct spng_ihdr *ihdr);
int spng_set_plte(spng_ctx *ctx, struct spng_plte *plte);
int spng_set_trns(spng_ctx *ctx, struct spng_trns *trns);
int spng_set_chrm(spng_ctx *ctx, struct spng_chrm *chrm);
int spng_set_chrm_int(spng_ctx *ctx, struct spng_chrm_int *chrm_int);
int spng_set_gama(spng_ctx *ctx, double gamma);
int spng_set_gama_int(spng_ctx *ctx, uint32_t gamma);
int spng_set_iccp(spng_ctx *ctx, struct spng_iccp *iccp);
int spng_set_sbit(spng_ctx *ctx, struct spng_sbit *sbit);
int spng_set_srgb(spng_ctx *ctx, uint8_t rendering_intent);
int spng_set_text(spng_ctx *ctx, struct spng_text *text, uint32_t n_text);
int spng_set_bkgd(spng_ctx *ctx, struct spng_bkgd *bkgd);
int spng_set_hist(spng_ctx *ctx, struct spng_hist *hist);
int spng_set_phys(spng_ctx *ctx, struct spng_phys *phys);
int spng_set_splt(spng_ctx *ctx, struct spng_splt *splt, uint32_t n_splt);
int spng_set_time(spng_ctx *ctx, struct spng_time *time);
int spng_set_unknown_chunks(spng_ctx *ctx, struct spng_unknown_chunk *chunks, uint32_t n_chunks);
int spng_set_offs(spng_ctx *ctx, struct spng_offs *offs);
int spng_set_exif(spng_ctx *ctx, struct spng_exif *exif);

/* extensions for luapower ffi binding */
void spng_rgba8_to_bgra8(void* p, uint32_t n);
void spng_premultiply_alpha_rgba8(void* p, uint32_t n);
void spng_premultiply_alpha_rgba16(void* p, uint32_t n);
void spng_premultiply_alpha_ga8(void* p, uint32_t n);
void spng_premultiply_alpha_ga16(void* p, uint32_t n);
]]
