--result of `cpp vlc.h` from vlc 2.0.5
local ffi = require'ffi'

ffi.cdef[[
typedef struct libvlc_instance_t libvlc_instance_t;
typedef int64_t libvlc_time_t;
typedef struct libvlc_log_t libvlc_log_t;
typedef struct libvlc_log_iterator_t libvlc_log_iterator_t;
typedef struct libvlc_log_message_t
{
    int i_severity;
    const char *psz_type;
    const char *psz_name;
    const char *psz_header;
    const char *psz_message;
} libvlc_log_message_t;
const char *libvlc_errmsg (void);
void libvlc_clearerr (void);
const char *libvlc_vprinterr (const char *fmt, va_list ap);
const char *libvlc_printerr (const char *fmt, ...);
libvlc_instance_t *libvlc_new( int argc , const char *const *argv );
void libvlc_release( libvlc_instance_t *p_instance );
void libvlc_retain( libvlc_instance_t *p_instance );
int libvlc_add_intf( libvlc_instance_t *p_instance, const char *name );
void libvlc_set_exit_handler( libvlc_instance_t *p_instance,
                              void (*cb) (void *), void *opaque );
void libvlc_wait( libvlc_instance_t *p_instance );
void libvlc_set_user_agent( libvlc_instance_t *p_instance,
                            const char *name, const char *http );
const char * libvlc_get_version(void);
const char * libvlc_get_compiler(void);
const char * libvlc_get_changeset(void);
void libvlc_free( void *ptr );
typedef struct libvlc_event_manager_t libvlc_event_manager_t;
struct libvlc_event_t;
typedef int libvlc_event_type_t;
typedef void ( *libvlc_callback_t )( const struct libvlc_event_t *, void * );
int libvlc_event_attach( libvlc_event_manager_t *p_event_manager,
                                        libvlc_event_type_t i_event_type,
                                        libvlc_callback_t f_callback,
                                        void *user_data );
void libvlc_event_detach( libvlc_event_manager_t *p_event_manager,
                                         libvlc_event_type_t i_event_type,
                                         libvlc_callback_t f_callback,
                                         void *p_user_data );
const char * libvlc_event_type_name( libvlc_event_type_t event_type );
typedef struct libvlc_module_description_t
{
    char *psz_name;
    char *psz_shortname;
    char *psz_longname;
    char *psz_help;
    struct libvlc_module_description_t *p_next;
} libvlc_module_description_t;
void libvlc_module_description_list_release( libvlc_module_description_t *p_list );
libvlc_module_description_t *libvlc_audio_filter_list_get( libvlc_instance_t *p_instance );
libvlc_module_description_t *libvlc_video_filter_list_get( libvlc_instance_t *p_instance );
int64_t libvlc_clock(void);
typedef struct libvlc_media_t libvlc_media_t;
typedef enum libvlc_meta_t {
    libvlc_meta_Title,
    libvlc_meta_Artist,
    libvlc_meta_Genre,
    libvlc_meta_Copyright,
    libvlc_meta_Album,
    libvlc_meta_TrackNumber,
    libvlc_meta_Description,
    libvlc_meta_Rating,
    libvlc_meta_Date,
    libvlc_meta_Setting,
    libvlc_meta_URL,
    libvlc_meta_Language,
    libvlc_meta_NowPlaying,
    libvlc_meta_Publisher,
    libvlc_meta_EncodedBy,
    libvlc_meta_ArtworkURL,
    libvlc_meta_TrackID
} libvlc_meta_t;
typedef enum libvlc_state_t
{
    libvlc_NothingSpecial=0,
    libvlc_Opening,
    libvlc_Buffering,
    libvlc_Playing,
    libvlc_Paused,
    libvlc_Stopped,
    libvlc_Ended,
    libvlc_Error
} libvlc_state_t;
enum
{
    libvlc_media_option_trusted = 0x2,
    libvlc_media_option_unique = 0x100
};
typedef enum libvlc_track_type_t
{
    libvlc_track_unknown = -1,
    libvlc_track_audio = 0,
    libvlc_track_video = 1,
    libvlc_track_text = 2
} libvlc_track_type_t;
typedef struct libvlc_media_stats_t
{
    int i_read_bytes;
    float f_input_bitrate;
    int i_demux_read_bytes;
    float f_demux_bitrate;
    int i_demux_corrupted;
    int i_demux_discontinuity;
    int i_decoded_video;
    int i_decoded_audio;
    int i_displayed_pictures;
    int i_lost_pictures;
    int i_played_abuffers;
    int i_lost_abuffers;
    int i_sent_packets;
    int i_sent_bytes;
    float f_send_bitrate;
} libvlc_media_stats_t;
typedef struct libvlc_media_track_info_t
{
    uint32_t i_codec;
    int i_id;
    libvlc_track_type_t i_type;
    int i_profile;
    int i_level;
    union {
        struct {
            unsigned i_channels;
            unsigned i_rate;
        } audio;
        struct {
            unsigned i_height;
            unsigned i_width;
        } video;
    } u;
} libvlc_media_track_info_t;
libvlc_media_t *libvlc_media_new_location(
                                   libvlc_instance_t *p_instance,
                                   const char * psz_mrl );
libvlc_media_t *libvlc_media_new_path(
                                   libvlc_instance_t *p_instance,
                                   const char *path );
libvlc_media_t *libvlc_media_new_fd(
                                   libvlc_instance_t *p_instance,
                                   int fd );
libvlc_media_t *libvlc_media_new_as_node(
                                   libvlc_instance_t *p_instance,
                                   const char * psz_name );
void libvlc_media_add_option(
                                   libvlc_media_t *p_md,
                                   const char * ppsz_options );
void libvlc_media_add_option_flag(
                                   libvlc_media_t *p_md,
                                   const char * ppsz_options,
                                   unsigned i_flags );
void libvlc_media_retain( libvlc_media_t *p_md );
void libvlc_media_release( libvlc_media_t *p_md );
char *libvlc_media_get_mrl( libvlc_media_t *p_md );
libvlc_media_t *libvlc_media_duplicate( libvlc_media_t *p_md );
char *libvlc_media_get_meta( libvlc_media_t *p_md,
                                             libvlc_meta_t e_meta );
void libvlc_media_set_meta( libvlc_media_t *p_md,
                                           libvlc_meta_t e_meta,
                                           const char *psz_value );
int libvlc_media_save_meta( libvlc_media_t *p_md );
libvlc_state_t libvlc_media_get_state(
                                   libvlc_media_t *p_md );
int libvlc_media_get_stats( libvlc_media_t *p_md,
                                           libvlc_media_stats_t *p_stats );
struct libvlc_media_list_t *
libvlc_media_subitems( libvlc_media_t *p_md );
libvlc_event_manager_t *
    libvlc_media_event_manager( libvlc_media_t *p_md );
libvlc_time_t
   libvlc_media_get_duration( libvlc_media_t *p_md );
void
libvlc_media_parse( libvlc_media_t *p_md );
void
libvlc_media_parse_async( libvlc_media_t *p_md );
int
   libvlc_media_is_parsed( libvlc_media_t *p_md );
void
    libvlc_media_set_user_data( libvlc_media_t *p_md, void *p_new_user_data );
void *libvlc_media_get_user_data( libvlc_media_t *p_md );
int libvlc_media_get_tracks_info( libvlc_media_t *p_md,
                                  libvlc_media_track_info_t **tracks );
typedef struct libvlc_media_player_t libvlc_media_player_t;
typedef struct libvlc_track_description_t
{
    int i_id;
    char *psz_name;
    struct libvlc_track_description_t *p_next;
} libvlc_track_description_t;
typedef struct libvlc_audio_output_t
{
    char *psz_name;
    char *psz_description;
    struct libvlc_audio_output_t *p_next;
} libvlc_audio_output_t;
typedef struct libvlc_rectangle_t
{
    int top, left;
    int bottom, right;
} libvlc_rectangle_t;
typedef enum libvlc_video_marquee_option_t {
    libvlc_marquee_Enable = 0,
    libvlc_marquee_Text,
    libvlc_marquee_Color,
    libvlc_marquee_Opacity,
    libvlc_marquee_Position,
    libvlc_marquee_Refresh,
    libvlc_marquee_Size,
    libvlc_marquee_Timeout,
    libvlc_marquee_X,
    libvlc_marquee_Y
} libvlc_video_marquee_option_t;
typedef enum libvlc_navigate_mode_t
{
    libvlc_navigate_activate = 0,
    libvlc_navigate_up,
    libvlc_navigate_down,
    libvlc_navigate_left,
    libvlc_navigate_right
} libvlc_navigate_mode_t;
libvlc_media_player_t * libvlc_media_player_new( libvlc_instance_t *p_libvlc_instance );
libvlc_media_player_t * libvlc_media_player_new_from_media( libvlc_media_t *p_md );
void libvlc_media_player_release( libvlc_media_player_t *p_mi );
void libvlc_media_player_retain( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_media( libvlc_media_player_t *p_mi,
                                                   libvlc_media_t *p_md );
libvlc_media_t * libvlc_media_player_get_media( libvlc_media_player_t *p_mi );
libvlc_event_manager_t * libvlc_media_player_event_manager ( libvlc_media_player_t *p_mi );
int libvlc_media_player_is_playing ( libvlc_media_player_t *p_mi );
int libvlc_media_player_play ( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_pause ( libvlc_media_player_t *mp,
                                                    int do_pause );
void libvlc_media_player_pause ( libvlc_media_player_t *p_mi );
void libvlc_media_player_stop ( libvlc_media_player_t *p_mi );
typedef void *(*libvlc_video_lock_cb)(void *opaque, void **planes);
typedef void (*libvlc_video_unlock_cb)(void *opaque, void *picture,
                                       void *const *planes);
typedef void (*libvlc_video_display_cb)(void *opaque, void *picture);
typedef unsigned (*libvlc_video_format_cb)(void **opaque, char *chroma,
                                           unsigned *width, unsigned *height,
                                           unsigned *pitches,
                                           unsigned *lines);
typedef void (*libvlc_video_cleanup_cb)(void *opaque);
void libvlc_video_set_callbacks( libvlc_media_player_t *mp,
                                 libvlc_video_lock_cb lock,
                                 libvlc_video_unlock_cb unlock,
                                 libvlc_video_display_cb display,
                                 void *opaque );
void libvlc_video_set_format( libvlc_media_player_t *mp, const char *chroma,
                              unsigned width, unsigned height,
                              unsigned pitch );
void libvlc_video_set_format_callbacks( libvlc_media_player_t *mp,
                                        libvlc_video_format_cb setup,
                                        libvlc_video_cleanup_cb cleanup );
void libvlc_media_player_set_nsobject ( libvlc_media_player_t *p_mi, void * drawable );
void * libvlc_media_player_get_nsobject ( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_agl ( libvlc_media_player_t *p_mi, uint32_t drawable );
uint32_t libvlc_media_player_get_agl ( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_xwindow ( libvlc_media_player_t *p_mi, uint32_t drawable );
uint32_t libvlc_media_player_get_xwindow ( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_hwnd ( libvlc_media_player_t *p_mi, void *drawable );
void *libvlc_media_player_get_hwnd ( libvlc_media_player_t *p_mi );
typedef void (*libvlc_audio_play_cb)(void *data, const void *samples,
                                     unsigned count, int64_t pts);
typedef void (*libvlc_audio_pause_cb)(void *data, int64_t pts);
typedef void (*libvlc_audio_resume_cb)(void *data, int64_t pts);
typedef void (*libvlc_audio_flush_cb)(void *data, int64_t pts);
typedef void (*libvlc_audio_drain_cb)(void *data);
typedef void (*libvlc_audio_set_volume_cb)(void *data,
                                           float volume, _Bool mute);
void libvlc_audio_set_callbacks( libvlc_media_player_t *mp,
                                 libvlc_audio_play_cb play,
                                 libvlc_audio_pause_cb pause,
                                 libvlc_audio_resume_cb resume,
                                 libvlc_audio_flush_cb flush,
                                 libvlc_audio_drain_cb drain,
                                 void *opaque );
void libvlc_audio_set_volume_callback( libvlc_media_player_t *mp,
                                       libvlc_audio_set_volume_cb set_volume );
typedef int (*libvlc_audio_setup_cb)(void **data, char *format, unsigned *rate,
                                     unsigned *channels);
typedef void (*libvlc_audio_cleanup_cb)(void *data);
void libvlc_audio_set_format_callbacks( libvlc_media_player_t *mp,
                                        libvlc_audio_setup_cb setup,
                                        libvlc_audio_cleanup_cb cleanup );
void libvlc_audio_set_format( libvlc_media_player_t *mp, const char *format,
                              unsigned rate, unsigned channels );
libvlc_time_t libvlc_media_player_get_length( libvlc_media_player_t *p_mi );
libvlc_time_t libvlc_media_player_get_time( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_time( libvlc_media_player_t *p_mi, libvlc_time_t i_time );
float libvlc_media_player_get_position( libvlc_media_player_t *p_mi );
void libvlc_media_player_set_position( libvlc_media_player_t *p_mi, float f_pos );
void libvlc_media_player_set_chapter( libvlc_media_player_t *p_mi, int i_chapter );
int libvlc_media_player_get_chapter( libvlc_media_player_t *p_mi );
int libvlc_media_player_get_chapter_count( libvlc_media_player_t *p_mi );
int libvlc_media_player_will_play( libvlc_media_player_t *p_mi );
int libvlc_media_player_get_chapter_count_for_title(
                       libvlc_media_player_t *p_mi, int i_title );
void libvlc_media_player_set_title( libvlc_media_player_t *p_mi, int i_title );
int libvlc_media_player_get_title( libvlc_media_player_t *p_mi );
int libvlc_media_player_get_title_count( libvlc_media_player_t *p_mi );
void libvlc_media_player_previous_chapter( libvlc_media_player_t *p_mi );
void libvlc_media_player_next_chapter( libvlc_media_player_t *p_mi );
float libvlc_media_player_get_rate( libvlc_media_player_t *p_mi );
int libvlc_media_player_set_rate( libvlc_media_player_t *p_mi, float rate );
libvlc_state_t libvlc_media_player_get_state( libvlc_media_player_t *p_mi );
float libvlc_media_player_get_fps( libvlc_media_player_t *p_mi );
unsigned libvlc_media_player_has_vout( libvlc_media_player_t *p_mi );
int libvlc_media_player_is_seekable( libvlc_media_player_t *p_mi );
int libvlc_media_player_can_pause( libvlc_media_player_t *p_mi );
void libvlc_media_player_next_frame( libvlc_media_player_t *p_mi );
void libvlc_media_player_navigate( libvlc_media_player_t* p_mi,
                                              unsigned navigate );
void libvlc_track_description_list_release( libvlc_track_description_t *p_track_description );
void libvlc_toggle_fullscreen( libvlc_media_player_t *p_mi );
void libvlc_set_fullscreen( libvlc_media_player_t *p_mi, int b_fullscreen );
int libvlc_get_fullscreen( libvlc_media_player_t *p_mi );
void libvlc_video_set_key_input( libvlc_media_player_t *p_mi, unsigned on );
void libvlc_video_set_mouse_input( libvlc_media_player_t *p_mi, unsigned on );
int libvlc_video_get_size( libvlc_media_player_t *p_mi, unsigned num,
                           unsigned *px, unsigned *py );
int libvlc_video_get_cursor( libvlc_media_player_t *p_mi, unsigned num,
                             int *px, int *py );
float libvlc_video_get_scale( libvlc_media_player_t *p_mi );
void libvlc_video_set_scale( libvlc_media_player_t *p_mi, float f_factor );
char *libvlc_video_get_aspect_ratio( libvlc_media_player_t *p_mi );
void libvlc_video_set_aspect_ratio( libvlc_media_player_t *p_mi, const char *psz_aspect );
int libvlc_video_get_spu( libvlc_media_player_t *p_mi );
int libvlc_video_get_spu_count( libvlc_media_player_t *p_mi );
libvlc_track_description_t *
        libvlc_video_get_spu_description( libvlc_media_player_t *p_mi );
int libvlc_video_set_spu( libvlc_media_player_t *p_mi, unsigned i_spu );
int libvlc_video_set_subtitle_file( libvlc_media_player_t *p_mi, const char *psz_subtitle );
int64_t libvlc_video_get_spu_delay( libvlc_media_player_t *p_mi );
int libvlc_video_set_spu_delay( libvlc_media_player_t *p_mi, int64_t i_delay );
libvlc_track_description_t *
        libvlc_video_get_title_description( libvlc_media_player_t *p_mi );
libvlc_track_description_t *
        libvlc_video_get_chapter_description( libvlc_media_player_t *p_mi, int i_title );
char *libvlc_video_get_crop_geometry( libvlc_media_player_t *p_mi );
void libvlc_video_set_crop_geometry( libvlc_media_player_t *p_mi, const char *psz_geometry );
int libvlc_video_get_teletext( libvlc_media_player_t *p_mi );
void libvlc_video_set_teletext( libvlc_media_player_t *p_mi, int i_page );
void libvlc_toggle_teletext( libvlc_media_player_t *p_mi );
int libvlc_video_get_track_count( libvlc_media_player_t *p_mi );
libvlc_track_description_t *
        libvlc_video_get_track_description( libvlc_media_player_t *p_mi );
int libvlc_video_get_track( libvlc_media_player_t *p_mi );
int libvlc_video_set_track( libvlc_media_player_t *p_mi, int i_track );
int libvlc_video_take_snapshot( libvlc_media_player_t *p_mi, unsigned num,
                                const char *psz_filepath, unsigned int i_width,
                                unsigned int i_height );
void libvlc_video_set_deinterlace( libvlc_media_player_t *p_mi,
                                                  const char *psz_mode );
int libvlc_video_get_marquee_int( libvlc_media_player_t *p_mi,
                                                 unsigned option );
char *libvlc_video_get_marquee_string( libvlc_media_player_t *p_mi,
                                                      unsigned option );
void libvlc_video_set_marquee_int( libvlc_media_player_t *p_mi,
                                                  unsigned option, int i_val );
void libvlc_video_set_marquee_string( libvlc_media_player_t *p_mi,
                                                     unsigned option, const char *psz_text );
enum libvlc_video_logo_option_t {
    libvlc_logo_enable,
    libvlc_logo_file,
    libvlc_logo_x,
    libvlc_logo_y,
    libvlc_logo_delay,
    libvlc_logo_repeat,
    libvlc_logo_opacity,
    libvlc_logo_position
};
int libvlc_video_get_logo_int( libvlc_media_player_t *p_mi,
                                              unsigned option );
void libvlc_video_set_logo_int( libvlc_media_player_t *p_mi,
                                               unsigned option, int value );
void libvlc_video_set_logo_string( libvlc_media_player_t *p_mi,
                                      unsigned option, const char *psz_value );
enum libvlc_video_adjust_option_t {
    libvlc_adjust_Enable = 0,
    libvlc_adjust_Contrast,
    libvlc_adjust_Brightness,
    libvlc_adjust_Hue,
    libvlc_adjust_Saturation,
    libvlc_adjust_Gamma
};
int libvlc_video_get_adjust_int( libvlc_media_player_t *p_mi,
                                                unsigned option );
void libvlc_video_set_adjust_int( libvlc_media_player_t *p_mi,
                                                 unsigned option, int value );
float libvlc_video_get_adjust_float( libvlc_media_player_t *p_mi,
                                                    unsigned option );
void libvlc_video_set_adjust_float( libvlc_media_player_t *p_mi,
                                                   unsigned option, float value );
typedef enum libvlc_audio_output_device_types_t {
    libvlc_AudioOutputDevice_Error = -1,
    libvlc_AudioOutputDevice_Mono = 1,
    libvlc_AudioOutputDevice_Stereo = 2,
    libvlc_AudioOutputDevice_2F2R = 4,
    libvlc_AudioOutputDevice_3F2R = 5,
    libvlc_AudioOutputDevice_5_1 = 6,
    libvlc_AudioOutputDevice_6_1 = 7,
    libvlc_AudioOutputDevice_7_1 = 8,
    libvlc_AudioOutputDevice_SPDIF = 10
} libvlc_audio_output_device_types_t;
typedef enum libvlc_audio_output_channel_t {
    libvlc_AudioChannel_Error = -1,
    libvlc_AudioChannel_Stereo = 1,
    libvlc_AudioChannel_RStereo = 2,
    libvlc_AudioChannel_Left = 3,
    libvlc_AudioChannel_Right = 4,
    libvlc_AudioChannel_Dolbys = 5
} libvlc_audio_output_channel_t;
libvlc_audio_output_t *
        libvlc_audio_output_list_get( libvlc_instance_t *p_instance );
void libvlc_audio_output_list_release( libvlc_audio_output_t *p_list );
int libvlc_audio_output_set( libvlc_media_player_t *p_mi,
                                            const char *psz_name );
int libvlc_audio_output_device_count( libvlc_instance_t *p_instance,
                                                     const char *psz_audio_output );
char * libvlc_audio_output_device_longname( libvlc_instance_t *p_instance,
                                                           const char *psz_audio_output,
                                                           int i_device );
char * libvlc_audio_output_device_id( libvlc_instance_t *p_instance,
                                                     const char *psz_audio_output,
                                                     int i_device );
void libvlc_audio_output_device_set( libvlc_media_player_t *p_mi,
                                                    const char *psz_audio_output,
                                                    const char *psz_device_id );
int libvlc_audio_output_get_device_type( libvlc_media_player_t *p_mi );
void libvlc_audio_output_set_device_type( libvlc_media_player_t *p_mi,
                                                         int device_type );
void libvlc_audio_toggle_mute( libvlc_media_player_t *p_mi );
int libvlc_audio_get_mute( libvlc_media_player_t *p_mi );
void libvlc_audio_set_mute( libvlc_media_player_t *p_mi, int status );
int libvlc_audio_get_volume( libvlc_media_player_t *p_mi );
int libvlc_audio_set_volume( libvlc_media_player_t *p_mi, int i_volume );
int libvlc_audio_get_track_count( libvlc_media_player_t *p_mi );
libvlc_track_description_t *
        libvlc_audio_get_track_description( libvlc_media_player_t *p_mi );
int libvlc_audio_get_track( libvlc_media_player_t *p_mi );
int libvlc_audio_set_track( libvlc_media_player_t *p_mi, int i_track );
int libvlc_audio_get_channel( libvlc_media_player_t *p_mi );
int libvlc_audio_set_channel( libvlc_media_player_t *p_mi, int channel );
int64_t libvlc_audio_get_delay( libvlc_media_player_t *p_mi );
int libvlc_audio_set_delay( libvlc_media_player_t *p_mi, int64_t i_delay );
typedef struct libvlc_media_list_t libvlc_media_list_t;
libvlc_media_list_t *
    libvlc_media_list_new( libvlc_instance_t *p_instance );
void
    libvlc_media_list_release( libvlc_media_list_t *p_ml );
void
    libvlc_media_list_retain( libvlc_media_list_t *p_ml );
void
libvlc_media_list_set_media( libvlc_media_list_t *p_ml, libvlc_media_t *p_md );
libvlc_media_t *
    libvlc_media_list_media( libvlc_media_list_t *p_ml );
int
libvlc_media_list_add_media( libvlc_media_list_t *p_ml, libvlc_media_t *p_md );
int
libvlc_media_list_insert_media( libvlc_media_list_t *p_ml,
                                libvlc_media_t *p_md, int i_pos );
int
libvlc_media_list_remove_index( libvlc_media_list_t *p_ml, int i_pos );
int
    libvlc_media_list_count( libvlc_media_list_t *p_ml );
libvlc_media_t *
    libvlc_media_list_item_at_index( libvlc_media_list_t *p_ml, int i_pos );
int
    libvlc_media_list_index_of_item( libvlc_media_list_t *p_ml,
                                     libvlc_media_t *p_md );
int
    libvlc_media_list_is_readonly( libvlc_media_list_t * p_ml );
void
    libvlc_media_list_lock( libvlc_media_list_t *p_ml );
void
    libvlc_media_list_unlock( libvlc_media_list_t *p_ml );
libvlc_event_manager_t *
    libvlc_media_list_event_manager( libvlc_media_list_t *p_ml );
typedef struct libvlc_media_list_player_t libvlc_media_list_player_t;
typedef enum libvlc_playback_mode_t
{
    libvlc_playback_mode_default,
    libvlc_playback_mode_loop,
    libvlc_playback_mode_repeat
} libvlc_playback_mode_t;
libvlc_media_list_player_t *
    libvlc_media_list_player_new( libvlc_instance_t * p_instance );
void
    libvlc_media_list_player_release( libvlc_media_list_player_t * p_mlp );
void
    libvlc_media_list_player_retain( libvlc_media_list_player_t *p_mlp );
libvlc_event_manager_t *
    libvlc_media_list_player_event_manager(libvlc_media_list_player_t * p_mlp);
void
    libvlc_media_list_player_set_media_player(
                                     libvlc_media_list_player_t * p_mlp,
                                     libvlc_media_player_t * p_mi );
void
    libvlc_media_list_player_set_media_list(
                                     libvlc_media_list_player_t * p_mlp,
                                     libvlc_media_list_t * p_mlist );
void libvlc_media_list_player_play(libvlc_media_list_player_t * p_mlp);
void libvlc_media_list_player_pause(libvlc_media_list_player_t * p_mlp);
int
    libvlc_media_list_player_is_playing( libvlc_media_list_player_t * p_mlp );
libvlc_state_t
    libvlc_media_list_player_get_state( libvlc_media_list_player_t * p_mlp );
int libvlc_media_list_player_play_item_at_index(libvlc_media_list_player_t * p_mlp,
                                                int i_index);
int libvlc_media_list_player_play_item(libvlc_media_list_player_t * p_mlp,
                                       libvlc_media_t * p_md);
void
    libvlc_media_list_player_stop( libvlc_media_list_player_t * p_mlp);
int libvlc_media_list_player_next(libvlc_media_list_player_t * p_mlp);
int libvlc_media_list_player_previous(libvlc_media_list_player_t * p_mlp);
void libvlc_media_list_player_set_playback_mode(libvlc_media_list_player_t * p_mlp,
                                                libvlc_playback_mode_t e_mode );
typedef struct libvlc_media_library_t libvlc_media_library_t;
libvlc_media_library_t *
    libvlc_media_library_new( libvlc_instance_t * p_instance );
void
    libvlc_media_library_release( libvlc_media_library_t * p_mlib );
void
    libvlc_media_library_retain( libvlc_media_library_t * p_mlib );
int
    libvlc_media_library_load( libvlc_media_library_t * p_mlib );
libvlc_media_list_t *
    libvlc_media_library_media_list( libvlc_media_library_t * p_mlib );
typedef struct libvlc_media_discoverer_t libvlc_media_discoverer_t;
libvlc_media_discoverer_t *
libvlc_media_discoverer_new_from_name( libvlc_instance_t * p_inst,
                                       const char * psz_name );
void libvlc_media_discoverer_release( libvlc_media_discoverer_t * p_mdis );
char * libvlc_media_discoverer_localized_name( libvlc_media_discoverer_t * p_mdis );
libvlc_media_list_t * libvlc_media_discoverer_media_list( libvlc_media_discoverer_t * p_mdis );
libvlc_event_manager_t *
        libvlc_media_discoverer_event_manager( libvlc_media_discoverer_t * p_mdis );
int
        libvlc_media_discoverer_is_running( libvlc_media_discoverer_t * p_mdis );
enum libvlc_event_e {
    libvlc_MediaMetaChanged=0,
    libvlc_MediaSubItemAdded,
    libvlc_MediaDurationChanged,
    libvlc_MediaParsedChanged,
    libvlc_MediaFreed,
    libvlc_MediaStateChanged,
    libvlc_MediaPlayerMediaChanged=0x100,
    libvlc_MediaPlayerNothingSpecial,
    libvlc_MediaPlayerOpening,
    libvlc_MediaPlayerBuffering,
    libvlc_MediaPlayerPlaying,
    libvlc_MediaPlayerPaused,
    libvlc_MediaPlayerStopped,
    libvlc_MediaPlayerForward,
    libvlc_MediaPlayerBackward,
    libvlc_MediaPlayerEndReached,
    libvlc_MediaPlayerEncounteredError,
    libvlc_MediaPlayerTimeChanged,
    libvlc_MediaPlayerPositionChanged,
    libvlc_MediaPlayerSeekableChanged,
    libvlc_MediaPlayerPausableChanged,
    libvlc_MediaPlayerTitleChanged,
    libvlc_MediaPlayerSnapshotTaken,
    libvlc_MediaPlayerLengthChanged,
    libvlc_MediaPlayerVout,
    libvlc_MediaListItemAdded=0x200,
    libvlc_MediaListWillAddItem,
    libvlc_MediaListItemDeleted,
    libvlc_MediaListWillDeleteItem,
    libvlc_MediaListViewItemAdded=0x300,
    libvlc_MediaListViewWillAddItem,
    libvlc_MediaListViewItemDeleted,
    libvlc_MediaListViewWillDeleteItem,
    libvlc_MediaListPlayerPlayed=0x400,
    libvlc_MediaListPlayerNextItemSet,
    libvlc_MediaListPlayerStopped,
    libvlc_MediaDiscovererStarted=0x500,
    libvlc_MediaDiscovererEnded,
    libvlc_VlmMediaAdded=0x600,
    libvlc_VlmMediaRemoved,
    libvlc_VlmMediaChanged,
    libvlc_VlmMediaInstanceStarted,
    libvlc_VlmMediaInstanceStopped,
    libvlc_VlmMediaInstanceStatusInit,
    libvlc_VlmMediaInstanceStatusOpening,
    libvlc_VlmMediaInstanceStatusPlaying,
    libvlc_VlmMediaInstanceStatusPause,
    libvlc_VlmMediaInstanceStatusEnd,
    libvlc_VlmMediaInstanceStatusError
};
typedef struct libvlc_event_t
{
    int type;
    void *p_obj;
    union
    {
        struct
        {
            libvlc_meta_t meta_type;
        } media_meta_changed;
        struct
        {
            libvlc_media_t * new_child;
        } media_subitem_added;
        struct
        {
            int64_t new_duration;
        } media_duration_changed;
        struct
        {
            int new_status;
        } media_parsed_changed;
        struct
        {
            libvlc_media_t * md;
        } media_freed;
        struct
        {
            libvlc_state_t new_state;
        } media_state_changed;
        struct
        {
            float new_cache;
        } media_player_buffering;
        struct
        {
            float new_position;
        } media_player_position_changed;
        struct
        {
            libvlc_time_t new_time;
        } media_player_time_changed;
        struct
        {
            int new_title;
        } media_player_title_changed;
        struct
        {
            int new_seekable;
        } media_player_seekable_changed;
        struct
        {
            int new_pausable;
        } media_player_pausable_changed;
        struct
        {
            int new_count;
        } media_player_vout;
        struct
        {
            libvlc_media_t * item;
            int index;
        } media_list_item_added;
        struct
        {
            libvlc_media_t * item;
            int index;
        } media_list_will_add_item;
        struct
        {
            libvlc_media_t * item;
            int index;
        } media_list_item_deleted;
        struct
        {
            libvlc_media_t * item;
            int index;
        } media_list_will_delete_item;
        struct
        {
            libvlc_media_t * item;
        } media_list_player_next_item_set;
        struct
        {
             char* psz_filename ;
        } media_player_snapshot_taken ;
        struct
        {
            libvlc_time_t new_length;
        } media_player_length_changed;
        struct
        {
            const char * psz_media_name;
            const char * psz_instance_name;
        } vlm_media_event;
        struct
        {
            libvlc_media_t * new_media;
        } media_player_media_changed;
    } u;
} libvlc_event_t;
void libvlc_vlm_release( libvlc_instance_t *p_instance );
int libvlc_vlm_add_broadcast( libvlc_instance_t *p_instance,
                                             const char *psz_name, const char *psz_input,
                                             const char *psz_output, int i_options,
                                             const char * const* ppsz_options,
                                             int b_enabled, int b_loop );
int libvlc_vlm_add_vod( libvlc_instance_t * p_instance,
                                       const char *psz_name, const char *psz_input,
                                       int i_options, const char * const* ppsz_options,
                                       int b_enabled, const char *psz_mux );
int libvlc_vlm_del_media( libvlc_instance_t * p_instance,
                                         const char *psz_name );
int libvlc_vlm_set_enabled( libvlc_instance_t *p_instance,
                                           const char *psz_name, int b_enabled );
int libvlc_vlm_set_output( libvlc_instance_t *p_instance,
                                          const char *psz_name,
                                          const char *psz_output );
int libvlc_vlm_set_input( libvlc_instance_t *p_instance,
                                         const char *psz_name,
                                         const char *psz_input );
int libvlc_vlm_add_input( libvlc_instance_t *p_instance,
                                         const char *psz_name,
                                         const char *psz_input );
int libvlc_vlm_set_loop( libvlc_instance_t *p_instance,
                                        const char *psz_name,
                                        int b_loop );
int libvlc_vlm_set_mux( libvlc_instance_t *p_instance,
                                       const char *psz_name,
                                       const char *psz_mux );
int libvlc_vlm_change_media( libvlc_instance_t *p_instance,
                                            const char *psz_name, const char *psz_input,
                                            const char *psz_output, int i_options,
                                            const char * const *ppsz_options,
                                            int b_enabled, int b_loop );
int libvlc_vlm_play_media ( libvlc_instance_t *p_instance,
                                           const char *psz_name );
int libvlc_vlm_stop_media ( libvlc_instance_t *p_instance,
                                           const char *psz_name );
int libvlc_vlm_pause_media( libvlc_instance_t *p_instance,
                                           const char *psz_name );
int libvlc_vlm_seek_media( libvlc_instance_t *p_instance,
                                          const char *psz_name,
                                          float f_percentage );
const char* libvlc_vlm_show_media( libvlc_instance_t *p_instance,
                                                  const char *psz_name );
float libvlc_vlm_get_media_instance_position( libvlc_instance_t *p_instance,
                                                             const char *psz_name,
                                                             int i_instance );
int libvlc_vlm_get_media_instance_time( libvlc_instance_t *p_instance,
                                                       const char *psz_name,
                                                       int i_instance );
int libvlc_vlm_get_media_instance_length( libvlc_instance_t *p_instance,
                                                         const char *psz_name,
                                                         int i_instance );
int libvlc_vlm_get_media_instance_rate( libvlc_instance_t *p_instance,
                                                       const char *psz_name,
                                                       int i_instance );
libvlc_event_manager_t *
    libvlc_vlm_get_event_manager( libvlc_instance_t *p_instance );
]]
