--result of `cpp jpeglib.h` from libjpeg-turbo 1.2.1 with JPEG_LIB_VERSION = 62.
--added a few new typedefs for useful structs and callbacks.
local ffi = require'ffi'

if ffi.os == 'Windows' then
	ffi.cdef'typedef unsigned char boolean;' --can you believe it?
else
	ffi.cdef'typedef int boolean;'
end

ffi.cdef[[
typedef struct FILE FILE;

enum {
	JPEG_SUSPENDED,     /* Suspended due to lack of input data */
	JPEG_REACHED_SOS,   /* Reached start of new scan */
	JPEG_REACHED_EOI,   /* Reached end of image */
	JPEG_ROW_COMPLETED, /* Completed one iMCU row */
	JPEG_SCAN_COMPLETED /* Completed last iMCU row of a scan */
};
typedef short INT16;
typedef signed int INT32;
typedef unsigned char JSAMPLE;
typedef short JCOEF;
typedef unsigned char JOCTET;
typedef unsigned char UINT8;
typedef unsigned short UINT16;
typedef unsigned int JDIMENSION;
typedef JSAMPLE *JSAMPROW;
typedef JSAMPROW *JSAMPARRAY;
typedef JSAMPARRAY *JSAMPIMAGE;
typedef JCOEF JBLOCK[64];
typedef JBLOCK *JBLOCKROW;
typedef JBLOCKROW *JBLOCKARRAY;
typedef JBLOCKARRAY *JBLOCKIMAGE;
typedef JCOEF *JCOEFPTR;

typedef struct {
	UINT16 quantval[64];
	boolean sent_table;
} JQUANT_TBL;

typedef struct {
	UINT8 bits[17];
	UINT8 huffval[256];
	boolean sent_table;
} JHUFF_TBL;

typedef struct {
	int component_id;
	int component_index;
	int h_samp_factor;
	int v_samp_factor;
	int quant_tbl_no;
	int dc_tbl_no;
	int ac_tbl_no;
	JDIMENSION width_in_blocks;
	JDIMENSION height_in_blocks;
	int DCT_scaled_size;
	JDIMENSION downsampled_width;
	JDIMENSION downsampled_height;
	boolean component_needed;
	int MCU_width;
	int MCU_height;
	int MCU_blocks;
	int MCU_sample_width;
	int last_col_width;
	int last_row_height;
	JQUANT_TBL * quant_table;
	void * dct_table;
} jpeg_component_info;

typedef struct {
	int comps_in_scan;
	int component_index[4];
	int Ss, Se;
	int Ah, Al;
} jpeg_scan_info;

typedef struct jpeg_marker_struct * jpeg_saved_marker_ptr;

struct jpeg_marker_struct {
	jpeg_saved_marker_ptr next;
	UINT8 marker;
	unsigned int original_length;
	unsigned int data_length;
	JOCTET * data;
};

typedef enum {
	JCS_UNKNOWN,
	JCS_GRAYSCALE,
	JCS_RGB,
	JCS_YCbCr,
	JCS_CMYK,
	JCS_YCCK,
	/* libjpeg-turbo only */
	JCS_EXT_RGB,
	JCS_EXT_RGBX,
	JCS_EXT_BGR,
	JCS_EXT_BGRX,
	JCS_EXT_XBGR,
	JCS_EXT_XRGB,
	JCS_EXT_RGBA,
	JCS_EXT_BGRA,
	JCS_EXT_ABGR,
	JCS_EXT_ARGB
} J_COLOR_SPACE;

typedef enum {
	JDCT_ISLOW,
	JDCT_IFAST,
	JDCT_FLOAT
} J_DCT_METHOD;

typedef enum {
	JDITHER_NONE,
	JDITHER_ORDERED,
	JDITHER_FS
} J_DITHER_MODE;

struct jpeg_common_struct {
  struct jpeg_error_mgr * err;
  struct jpeg_memory_mgr * mem;
  struct jpeg_progress_mgr * progress;
  void * client_data;
  boolean is_decompressor;
  int global_state;
};

typedef struct jpeg_common_struct * j_common_ptr;
typedef struct jpeg_compress_struct * j_compress_ptr;
typedef struct jpeg_decompress_struct * j_decompress_ptr;

typedef struct jpeg_compress_struct {
	struct jpeg_error_mgr * err;
	struct jpeg_memory_mgr * mem;
	struct jpeg_progress_mgr * progress;
	void * client_data;
	boolean is_decompressor;
	int global_state;
	struct jpeg_destination_mgr * dest;
	JDIMENSION image_width;
	JDIMENSION image_height;
	int input_components;
	J_COLOR_SPACE in_color_space;
	double input_gamma;
	int data_precision;
	int num_components;
	J_COLOR_SPACE jpeg_color_space;
	jpeg_component_info * comp_info;
	JQUANT_TBL * quant_tbl_ptrs[4];
	JHUFF_TBL * dc_huff_tbl_ptrs[4];
	JHUFF_TBL * ac_huff_tbl_ptrs[4];
	UINT8 arith_dc_L[16];
	UINT8 arith_dc_U[16];
	UINT8 arith_ac_K[16];
	int num_scans;
	const jpeg_scan_info * scan_info;
	boolean raw_data_in;
	boolean arith_code;
	boolean optimize_coding;
	boolean CCIR601_sampling;
	int smoothing_factor;
	J_DCT_METHOD dct_method;
	unsigned int restart_interval;
	int restart_in_rows;
	boolean write_JFIF_header;
	UINT8 JFIF_major_version;
	UINT8 JFIF_minor_version;
	UINT8 density_unit;
	UINT16 X_density;
	UINT16 Y_density;
	boolean write_Adobe_marker;
	JDIMENSION next_scanline;
	boolean progressive_mode;
	int max_h_samp_factor;
	int max_v_samp_factor;
	JDIMENSION total_iMCU_rows;
	int comps_in_scan;
	jpeg_component_info * cur_comp_info[4];
	JDIMENSION MCUs_per_row;
	JDIMENSION MCU_rows_in_scan;
	int blocks_in_MCU;
	int MCU_membership[10];
	int Ss, Se, Ah, Al;
	struct jpeg_comp_master * master;
	struct jpeg_c_main_controller * main;
	struct jpeg_c_prep_controller * prep;
	struct jpeg_c_coef_controller * coef;
	struct jpeg_marker_writer * marker;
	struct jpeg_color_converter * cconvert;
	struct jpeg_downsampler * downsample;
	struct jpeg_forward_dct * fdct;
	struct jpeg_entropy_encoder * entropy;
	jpeg_scan_info * script_space;
	int script_space_size;
} jpeg_compress_struct;

typedef struct jpeg_decompress_struct {
	struct jpeg_error_mgr * err;
	struct jpeg_memory_mgr * mem;
	struct jpeg_progress_mgr * progress;
	void * client_data;
	boolean is_decompressor;
	int global_state;
	struct jpeg_source_mgr * src;
	JDIMENSION image_width;
	JDIMENSION image_height;
	int num_components;
	J_COLOR_SPACE jpeg_color_space;
	J_COLOR_SPACE out_color_space;
	unsigned int scale_num, scale_denom;
	double output_gamma;
	boolean buffered_image;
	boolean raw_data_out;
	J_DCT_METHOD dct_method;
	boolean do_fancy_upsampling;
	boolean do_block_smoothing;
	boolean quantize_colors;
	J_DITHER_MODE dither_mode;
	boolean two_pass_quantize;
	int desired_number_of_colors;
	boolean enable_1pass_quant;
	boolean enable_external_quant;
	boolean enable_2pass_quant;
	JDIMENSION output_width;
	JDIMENSION output_height;
	int out_color_components;
	int output_components;
	int rec_outbuf_height;
	int actual_number_of_colors;
	JSAMPARRAY colormap;
	JDIMENSION output_scanline;
	int input_scan_number;
	JDIMENSION input_iMCU_row;
	int output_scan_number;
	JDIMENSION output_iMCU_row;
	int (*coef_bits)[64];
	JQUANT_TBL * quant_tbl_ptrs[4];
	JHUFF_TBL * dc_huff_tbl_ptrs[4];
	JHUFF_TBL * ac_huff_tbl_ptrs[4];
	int data_precision;
	jpeg_component_info * comp_info;
	boolean progressive_mode;
	boolean arith_code;
	UINT8 arith_dc_L[16];
	UINT8 arith_dc_U[16];
	UINT8 arith_ac_K[16];
	unsigned int restart_interval;
	boolean saw_JFIF_marker;
	UINT8 JFIF_major_version;
	UINT8 JFIF_minor_version;
	UINT8 density_unit;
	UINT16 X_density;
	UINT16 Y_density;
	boolean saw_Adobe_marker;
	UINT8 Adobe_transform;
	boolean CCIR601_sampling;
	jpeg_saved_marker_ptr marker_list;
	int max_h_samp_factor;
	int max_v_samp_factor;
	int min_DCT_scaled_size;
	JDIMENSION total_iMCU_rows;
	JSAMPLE * sample_range_limit;
	int comps_in_scan;
	jpeg_component_info * cur_comp_info[4];
	JDIMENSION MCUs_per_row;
	JDIMENSION MCU_rows_in_scan;
	int blocks_in_MCU;
	int MCU_membership[10];
	int Ss, Se, Ah, Al;
	int unread_marker;
	struct jpeg_decomp_master * master;
	struct jpeg_d_main_controller * main;
	struct jpeg_d_coef_controller * coef;
	struct jpeg_d_post_controller * post;
	struct jpeg_input_controller * inputctl;
	struct jpeg_marker_reader * marker;
	struct jpeg_entropy_decoder * entropy;
	struct jpeg_inverse_dct * idct;
	struct jpeg_upsampler * upsample;
	struct jpeg_color_deconverter * cconvert;
	struct jpeg_color_quantizer * cquantize;
} jpeg_decompress_struct;

typedef void (*jpeg_error_exit_callback) (j_common_ptr cinfo);
typedef void (*jpeg_emit_message_callback) (j_common_ptr cinfo, int msg_level);
typedef void (*jpeg_output_message_callback) (j_common_ptr cinfo);
typedef void (*jpeg_format_message_callback) (j_common_ptr cinfo, char * buffer);

typedef struct jpeg_error_mgr {
	jpeg_error_exit_callback error_exit;
	jpeg_emit_message_callback emit_message;
	jpeg_output_message_callback output_message;
	jpeg_format_message_callback format_message;
	void (*reset_error_mgr) (j_common_ptr cinfo);
	int msg_code;
	union {
		int i[8];
		char s[80];
	} msg_parm;
	int trace_level;
	long num_warnings;
	const char * const * jpeg_message_table;
	int last_jpeg_message;
	const char * const * addon_message_table;
	int first_addon_message;
	int last_addon_message;
} jpeg_error_mgr;

struct jpeg_progress_mgr {
	void (*progress_monitor) (j_common_ptr cinfo);
	long pass_counter;
	long pass_limit;
	int completed_passes;
	int total_passes;
};

typedef void    (*jpeg_init_destination_callback)    (j_compress_ptr cinfo);
typedef boolean (*jpeg_empty_output_buffer_callback) (j_compress_ptr cinfo);
typedef void    (*jpeg_term_destination_callback)    (j_compress_ptr cinfo);

typedef struct jpeg_destination_mgr {
	JOCTET * next_output_byte;
	size_t free_in_buffer;
	jpeg_init_destination_callback     init_destination;
	jpeg_empty_output_buffer_callback  empty_output_buffer;
	jpeg_term_destination_callback     term_destination;
} jpeg_destination_mgr;

typedef void    (*jpeg_init_source_callback)       (j_decompress_ptr cinfo);
typedef boolean (*jpeg_fill_input_buffer_callback) (j_decompress_ptr cinfo);
typedef void    (*jpeg_skip_input_data_callback)   (j_decompress_ptr cinfo, long num_bytes);
typedef boolean (*jpeg_resync_to_restart_callback) (j_decompress_ptr cinfo, int desired);
typedef void    (*jpeg_term_source_callback)       (j_decompress_ptr cinfo);

typedef struct jpeg_source_mgr {
	const JOCTET * next_input_byte;
	size_t bytes_in_buffer;
	jpeg_init_source_callback        init_source;
	jpeg_fill_input_buffer_callback  fill_input_buffer;
	jpeg_skip_input_data_callback    skip_input_data;
	jpeg_resync_to_restart_callback  resync_to_restart;
	jpeg_term_source_callback        term_source;
} jpeg_source_mgr;

typedef struct jvirt_sarray_control * jvirt_sarray_ptr;
typedef struct jvirt_barray_control * jvirt_barray_ptr;

struct jpeg_memory_mgr {
  void * (*alloc_small) (j_common_ptr cinfo, int pool_id, size_t sizeofobject);
  void * (*alloc_large) (j_common_ptr cinfo, int pool_id, size_t sizeofobject);
  JSAMPARRAY (*alloc_sarray) (j_common_ptr cinfo, int pool_id, JDIMENSION samplesperrow, JDIMENSION numrows);
  JBLOCKARRAY (*alloc_barray) (j_common_ptr cinfo, int pool_id, JDIMENSION blocksperrow, JDIMENSION numrows);
  jvirt_sarray_ptr (*request_virt_sarray) (j_common_ptr cinfo, int pool_id, boolean pre_zero, JDIMENSION samplesperrow, JDIMENSION numrows, JDIMENSION maxaccess);
  jvirt_barray_ptr (*request_virt_barray) (j_common_ptr cinfo, int pool_id, boolean pre_zero, JDIMENSION blocksperrow, JDIMENSION numrows, JDIMENSION maxaccess);
  void (*realize_virt_arrays) (j_common_ptr cinfo);
  JSAMPARRAY (*access_virt_sarray) (j_common_ptr cinfo, jvirt_sarray_ptr ptr, JDIMENSION start_row, JDIMENSION num_rows, boolean writable);
  JBLOCKARRAY (*access_virt_barray) (j_common_ptr cinfo, jvirt_barray_ptr ptr, JDIMENSION start_row, JDIMENSION num_rows, boolean writable);
  void (*free_pool) (j_common_ptr cinfo, int pool_id);
  void (*self_destruct) (j_common_ptr cinfo);
  long max_memory_to_use;
  long max_alloc_chunk;
};

typedef boolean (*jpeg_marker_parser_method) (j_decompress_ptr cinfo);

struct jpeg_error_mgr * jpeg_std_error (struct jpeg_error_mgr * err);

void jpeg_CreateCompress (j_compress_ptr cinfo, int version, size_t structsize);
void jpeg_CreateDecompress (j_decompress_ptr cinfo, int version, size_t structsize);
void jpeg_destroy_compress (j_compress_ptr cinfo);
void jpeg_destroy_decompress (j_decompress_ptr cinfo);
void jpeg_stdio_dest (j_compress_ptr cinfo, FILE * outfile);
void jpeg_stdio_src (j_decompress_ptr cinfo, FILE * infile);
void jpeg_set_defaults (j_compress_ptr cinfo);
void jpeg_set_colorspace (j_compress_ptr cinfo, J_COLOR_SPACE colorspace);
void jpeg_default_colorspace (j_compress_ptr cinfo);
void jpeg_set_quality (j_compress_ptr cinfo, int quality, boolean force_baseline);
void jpeg_set_linear_quality (j_compress_ptr cinfo, int scale_factor, boolean force_baseline);
void jpeg_add_quant_table (j_compress_ptr cinfo, int which_tbl, const unsigned int *basic_table, int scale_factor, boolean force_baseline);
int jpeg_quality_scaling (int quality);
void jpeg_simple_progression (j_compress_ptr cinfo);
void jpeg_suppress_tables (j_compress_ptr cinfo, boolean suppress);
JQUANT_TBL * jpeg_alloc_quant_table (j_common_ptr cinfo);
JHUFF_TBL * jpeg_alloc_huff_table (j_common_ptr cinfo);
void jpeg_start_compress (j_compress_ptr cinfo, boolean write_all_tables);
JDIMENSION jpeg_write_scanlines (j_compress_ptr cinfo, JSAMPARRAY scanlines, JDIMENSION num_lines);
void jpeg_finish_compress (j_compress_ptr cinfo);
JDIMENSION jpeg_write_raw_data (j_compress_ptr cinfo, JSAMPIMAGE data, JDIMENSION num_lines);
void jpeg_write_marker (j_compress_ptr cinfo, int marker, const JOCTET * dataptr, unsigned int datalen);
void jpeg_write_m_header (j_compress_ptr cinfo, int marker, unsigned int datalen);
void jpeg_write_m_byte (j_compress_ptr cinfo, int val);
void jpeg_write_tables (j_compress_ptr cinfo);
int jpeg_read_header (j_decompress_ptr cinfo, boolean require_image);
boolean jpeg_start_decompress (j_decompress_ptr cinfo);
JDIMENSION jpeg_read_scanlines (j_decompress_ptr cinfo, JSAMPARRAY scanlines, JDIMENSION max_lines);
boolean jpeg_finish_decompress (j_decompress_ptr cinfo);
JDIMENSION jpeg_read_raw_data (j_decompress_ptr cinfo, JSAMPIMAGE data, JDIMENSION max_lines);
boolean jpeg_has_multiple_scans (j_decompress_ptr cinfo);
boolean jpeg_start_output (j_decompress_ptr cinfo, int scan_number);
boolean jpeg_finish_output (j_decompress_ptr cinfo);
boolean jpeg_input_complete (j_decompress_ptr cinfo);
void jpeg_new_colormap (j_decompress_ptr cinfo);
int jpeg_consume_input (j_decompress_ptr cinfo);
void jpeg_calc_output_dimensions (j_decompress_ptr cinfo);
void jpeg_save_markers (j_decompress_ptr cinfo, int marker_code, unsigned int length_limit);
void jpeg_set_marker_processor (j_decompress_ptr cinfo, int marker_code, jpeg_marker_parser_method routine);
jvirt_barray_ptr * jpeg_read_coefficients (j_decompress_ptr cinfo);
void jpeg_write_coefficients (j_compress_ptr cinfo, jvirt_barray_ptr * coef_arrays);
void jpeg_copy_critical_parameters (j_decompress_ptr srcinfo, j_compress_ptr dstinfo);
void jpeg_abort_compress (j_compress_ptr cinfo);
void jpeg_abort_decompress (j_decompress_ptr cinfo);
void jpeg_abort (j_common_ptr cinfo);
void jpeg_destroy (j_common_ptr cinfo);
boolean jpeg_resync_to_restart (j_decompress_ptr cinfo, int desired);
]]
