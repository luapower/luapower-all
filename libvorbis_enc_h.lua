--include/vorbis/vorbisenc.h from libvorbis 1.3.5
local ffi = require'ffi'
require'libvorbis_h'

ffi.cdef[[
int vorbis_encode_init(vorbis_info *vi,
	long channels,
	long rate,
	long max_bitrate,
	long nominal_bitrate,
	long min_bitrate);
int vorbis_encode_setup_managed(vorbis_info *vi,
	long channels,
	long rate,
	long max_bitrate,
	long nominal_bitrate,
	long min_bitrate);
int vorbis_encode_setup_vbr(vorbis_info *vi,
	long channels,
	long rate,
	float quality
	);
int vorbis_encode_init_vbr(vorbis_info *vi,
	long channels,
	long rate,
	float base_quality
	);
int vorbis_encode_setup_init(vorbis_info *vi);
int vorbis_encode_ctl(vorbis_info *vi,int number,void *arg);
struct ovectl_ratemanage_arg {
	int management_active;
	long bitrate_hard_min;
	long bitrate_hard_max;
	double bitrate_hard_window;
	long bitrate_av_lo;
	long bitrate_av_hi;
	double bitrate_av_window;
	double bitrate_av_window_center;
};
struct ovectl_ratemanage2_arg {
	int management_active;
	long bitrate_limit_min_kbps;
	long bitrate_limit_max_kbps;
	long bitrate_limit_reservoir_bits;
	double bitrate_limit_reservoir_bias;
	long bitrate_average_kbps;
	double bitrate_average_damping;
};
enum {
	OV_ECTL_RATEMANAGE2_GET = 0x14,
	OV_ECTL_RATEMANAGE2_SET = 0x15,
	OV_ECTL_LOWPASS_GET  = 0x20,
	OV_ECTL_LOWPASS_SET  = 0x21,
	OV_ECTL_IBLOCK_GET   = 0x30,
	OV_ECTL_IBLOCK_SET   = 0x31,
	OV_ECTL_COUPLING_GET = 0x40,
	OV_ECTL_COUPLING_SET = 0x41,
	OV_ECTL_RATEMANAGE_GET = 0x10,
	OV_ECTL_RATEMANAGE_SET = 0x11,
	OV_ECTL_RATEMANAGE_AVG = 0x12,
	OV_ECTL_RATEMANAGE_HARD = 0x13,
};
]]
