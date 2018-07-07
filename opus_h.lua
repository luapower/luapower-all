--result of cpp opus.h from opus 1.2.1
local ffi = require'ffi'

ffi.cdef[[
typedef short opus_int16;
typedef unsigned short opus_uint16;
typedef int opus_int32;
typedef unsigned int opus_uint32;

const char *opus_strerror(int error);
const char *opus_get_version_string(void);

typedef struct OpusEncoder OpusEncoder;
int opus_encoder_get_size(int channels);
OpusEncoder *opus_encoder_create(
	opus_int32 Fs,
	int channels,
	int application,
	int *error
);
int opus_encoder_init(
	OpusEncoder *st,
	opus_int32 Fs,
	int channels,
	int application
);
opus_int32 opus_encode(
	OpusEncoder *st,
	const opus_int16 *pcm,
	int frame_size,
	unsigned char *data,
	opus_int32 max_data_bytes
);
opus_int32 opus_encode_float(
	OpusEncoder *st,
	const float *pcm,
	int frame_size,
	unsigned char *data,
	opus_int32 max_data_bytes
);
void opus_encoder_destroy(OpusEncoder *st);
int opus_encoder_ctl(OpusEncoder *st, int request, ...);

typedef struct OpusDecoder OpusDecoder;
int opus_decoder_get_size(int channels);
OpusDecoder *opus_decoder_create(
	opus_int32 Fs,
	int channels,
	int *error
);
int opus_decoder_init(
	OpusDecoder *st,
	opus_int32 Fs,
	int channels
);
int opus_decode(
	OpusDecoder *st,
	const unsigned char *data,
	opus_int32 len,
	opus_int16 *pcm,
	int frame_size,
	int decode_fec
);
int opus_decode_float(
	OpusDecoder *st,
	const unsigned char *data,
	opus_int32 len,
	float *pcm,
	int frame_size,
	int decode_fec
);
int opus_decoder_ctl(OpusDecoder *st, int request, ...);
void opus_decoder_destroy(OpusDecoder *st);

int opus_packet_parse(
   const unsigned char *data,
   opus_int32 len,
   unsigned char *out_toc,
   const unsigned char *frames[48],
   opus_int16 size[48],
   int *payload_offset
);
int opus_packet_get_bandwidth(const unsigned char *data);
int opus_packet_get_samples_per_frame(const unsigned char *data, opus_int32 Fs);
int opus_packet_get_nb_channels(const unsigned char *data);
int opus_packet_get_nb_frames(const unsigned char packet[], opus_int32 len);
int opus_packet_get_nb_samples(const unsigned char packet[], opus_int32 len, opus_int32 Fs);

int opus_decoder_get_nb_samples(const OpusDecoder *dec, const unsigned char packet[], opus_int32 len);

void opus_pcm_soft_clip(float *pcm, int frame_size, int channels, float *softclip_mem);

typedef struct OpusRepacketizer OpusRepacketizer;
int opus_repacketizer_get_size(void);
OpusRepacketizer *opus_repacketizer_init(OpusRepacketizer *rp);
OpusRepacketizer *opus_repacketizer_create(void);
void opus_repacketizer_destroy(OpusRepacketizer *rp);
int opus_repacketizer_cat(OpusRepacketizer *rp, const unsigned char *data, opus_int32 len);
opus_int32 opus_repacketizer_out_range(OpusRepacketizer *rp, int begin, int end, unsigned char *data, opus_int32 maxlen);
int opus_repacketizer_get_nb_frames(OpusRepacketizer *rp);
opus_int32 opus_repacketizer_out(OpusRepacketizer *rp, unsigned char *data, opus_int32 maxlen);
int opus_packet_pad(unsigned char *data, opus_int32 len, opus_int32 new_len);
opus_int32 opus_packet_unpad(unsigned char *data, opus_int32 len);
int opus_multistream_packet_pad(unsigned char *data, opus_int32 len, opus_int32 new_len, int nb_streams);
opus_int32 opus_multistream_packet_unpad(unsigned char *data, opus_int32 len, int nb_streams);
]]
