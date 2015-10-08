--include/vorbis/vorbisfile.h from libvorbis 1.3.5
local ffi = require'ffi'
require'libvorbis_h'

ffi.cdef[[
typedef struct FILE FILE;
typedef struct {
	size_t (*read_func) (void *ptr, size_t size, size_t nmemb, void *datasource);
	int (*seek_func) (void *datasource, ogg_int64_t offset, int whence);
	int (*close_func) (void *datasource);
	long (*tell_func) (void *datasource);
} ov_callbacks;
enum {
	NOTOPEN              = 0,
	PARTOPEN             = 1,
	OPENED               = 2,
	STREAMSET            = 3,
	INITSET              = 4,
};
typedef struct OggVorbis_File {
	void *datasource;
	int seekable;
	ogg_int64_t offset;
	ogg_int64_t end;
	ogg_sync_state oy;
	int links;
	ogg_int64_t *offsets;
	ogg_int64_t *dataoffsets;
	long *serialnos;
	ogg_int64_t *pcmlengths;
	vorbis_info *vi;
	vorbis_comment *vc;
	ogg_int64_t pcm_offset;
	int ready_state;
	long current_serialno;
	int current_link;
	double bittrack;
	double samptrack;
	ogg_stream_state os;
	vorbis_dsp_state vd;
	vorbis_block vb;
	ov_callbacks callbacks;
} OggVorbis_File;
int ov_clear(OggVorbis_File *vf);
int ov_fopen(const char *path,OggVorbis_File *vf);
int ov_open(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
int ov_open_callbacks(void *datasource, OggVorbis_File *vf,
	const char *initial, long ibytes, ov_callbacks callbacks);
int ov_test(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
int ov_test_callbacks(void *datasource, OggVorbis_File *vf,
	const char *initial, long ibytes, ov_callbacks callbacks);
int ov_test_open(OggVorbis_File *vf);
long ov_bitrate(OggVorbis_File *vf,int i);
long ov_bitrate_instant(OggVorbis_File *vf);
long ov_streams(OggVorbis_File *vf);
long ov_seekable(OggVorbis_File *vf);
long ov_serialnumber(OggVorbis_File *vf,int i);
ogg_int64_t ov_raw_total(OggVorbis_File *vf,int i);
ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int i);
double ov_time_total(OggVorbis_File *vf,int i);
int ov_raw_seek(OggVorbis_File *vf,ogg_int64_t pos);
int ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t pos);
int ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t pos);
int ov_time_seek(OggVorbis_File *vf,double pos);
int ov_time_seek_page(OggVorbis_File *vf,double pos);
int ov_raw_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
int ov_pcm_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
int ov_pcm_seek_page_lap(OggVorbis_File *vf,ogg_int64_t pos);
int ov_time_seek_lap(OggVorbis_File *vf,double pos);
int ov_time_seek_page_lap(OggVorbis_File *vf,double pos);
ogg_int64_t ov_raw_tell(OggVorbis_File *vf);
ogg_int64_t ov_pcm_tell(OggVorbis_File *vf);
double ov_time_tell(OggVorbis_File *vf);
vorbis_info *ov_info(OggVorbis_File *vf,int link);
vorbis_comment *ov_comment(OggVorbis_File *vf,int link);
long ov_read_float(OggVorbis_File *vf,float ***pcm_channels,int samples, int *bitstream);
long ov_read_filter(OggVorbis_File *vf,char *buffer,int length,
	int bigendianp,int word,int sgned,int *bitstream,
	void (*filter)(float **pcm,long channels,long samples,void *filter_param),void *filter_param);
long ov_read(OggVorbis_File *vf,char *buffer,int length,
	int bigendianp,int word,int sgned,int *bitstream);
int ov_crosslap(OggVorbis_File *vf1,OggVorbis_File *vf2);
int ov_halfrate(OggVorbis_File *vf,int flag);
int ov_halfrate_p(OggVorbis_File *vf);
]]
