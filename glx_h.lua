
--GL/glx.h and GL/glxext.h from mesa-common-dev ubuntu package.

local ffi = require'ffi'

require'xlib_h'

ffi.cdef[[

// bits from GL/gl.h
typedef unsigned char GLubyte;
typedef int GLsizei;
typedef float GLfloat;
typedef void GLvoid;
typedef unsigned int GLuint;
typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef int GLint;

// GL/glx.h
enum {
	GLX_USE_GL           = 1,
	GLX_BUFFER_SIZE      = 2,
	GLX_LEVEL            = 3,
	GLX_RGBA             = 4,
	GLX_DOUBLEBUFFER     = 5,
	GLX_STEREO           = 6,
	GLX_AUX_BUFFERS      = 7,
	GLX_RED_SIZE         = 8,
	GLX_GREEN_SIZE       = 9,
	GLX_BLUE_SIZE        = 10,
	GLX_ALPHA_SIZE       = 11,
	GLX_DEPTH_SIZE       = 12,
	GLX_STENCIL_SIZE     = 13,
	GLX_ACCUM_RED_SIZE   = 14,
	GLX_ACCUM_GREEN_SIZE = 15,
	GLX_ACCUM_BLUE_SIZE  = 16,
	GLX_ACCUM_ALPHA_SIZE = 17,
	GLX_BAD_SCREEN       = 1,
	GLX_BAD_ATTRIBUTE    = 2,
	GLX_NO_EXTENSION     = 3,
	GLX_BAD_VISUAL       = 4,
	GLX_BAD_CONTEXT      = 5,
	GLX_BAD_VALUE        = 6,
	GLX_BAD_ENUM         = 7,
	GLX_VENDOR           = 1,
	GLX_VERSION          = 2,
	GLX_EXTENSIONS       = 3,
	GLX_CONFIG_CAVEAT    = 0x20,
	GLX_DONT_CARE        = 0xFFFFFFFF,
	GLX_X_VISUAL_TYPE    = 0x22,
	GLX_TRANSPARENT_TYPE = 0x23,
	GLX_TRANSPARENT_INDEX_VALUE = 0x24,
	GLX_TRANSPARENT_RED_VALUE = 0x25,
	GLX_TRANSPARENT_GREEN_VALUE = 0x26,
	GLX_TRANSPARENT_BLUE_VALUE = 0x27,
	GLX_TRANSPARENT_ALPHA_VALUE = 0x28,
	GLX_WINDOW_BIT       = 0x00000001,
	GLX_PIXMAP_BIT       = 0x00000002,
	GLX_PBUFFER_BIT      = 0x00000004,
	GLX_AUX_BUFFERS_BIT  = 0x00000010,
	GLX_FRONT_LEFT_BUFFER_BIT = 0x00000001,
	GLX_FRONT_RIGHT_BUFFER_BIT = 0x00000002,
	GLX_BACK_LEFT_BUFFER_BIT = 0x00000004,
	GLX_BACK_RIGHT_BUFFER_BIT = 0x00000008,
	GLX_DEPTH_BUFFER_BIT = 0x00000020,
	GLX_STENCIL_BUFFER_BIT = 0x00000040,
	GLX_ACCUM_BUFFER_BIT = 0x00000080,
	GLX_NONE             = 0x8000,
	GLX_SLOW_CONFIG      = 0x8001,
	GLX_TRUE_COLOR       = 0x8002,
	GLX_DIRECT_COLOR     = 0x8003,
	GLX_PSEUDO_COLOR     = 0x8004,
	GLX_STATIC_COLOR     = 0x8005,
	GLX_GRAY_SCALE       = 0x8006,
	GLX_STATIC_GRAY      = 0x8007,
	GLX_TRANSPARENT_RGB  = 0x8008,
	GLX_TRANSPARENT_INDEX = 0x8009,
	GLX_VISUAL_ID        = 0x800B,
	GLX_SCREEN           = 0x800C,
	GLX_NON_CONFORMANT_CONFIG = 0x800D,
	GLX_DRAWABLE_TYPE    = 0x8010,
	GLX_RENDER_TYPE      = 0x8011,
	GLX_X_RENDERABLE     = 0x8012,
	GLX_FBCONFIG_ID      = 0x8013,
	GLX_RGBA_TYPE        = 0x8014,
	GLX_COLOR_INDEX_TYPE = 0x8015,
	GLX_MAX_PBUFFER_WIDTH = 0x8016,
	GLX_MAX_PBUFFER_HEIGHT = 0x8017,
	GLX_MAX_PBUFFER_PIXELS = 0x8018,
	GLX_PRESERVED_CONTENTS = 0x801B,
	GLX_LARGEST_PBUFFER  = 0x801C,
	GLX_WIDTH            = 0x801D,
	GLX_HEIGHT           = 0x801E,
	GLX_EVENT_MASK       = 0x801F,
	GLX_DAMAGED          = 0x8020,
	GLX_SAVED            = 0x8021,
	GLX_WINDOW           = 0x8022,
	GLX_PBUFFER          = 0x8023,
	GLX_PBUFFER_HEIGHT   = 0x8040,
	GLX_PBUFFER_WIDTH    = 0x8041,
	GLX_RGBA_BIT         = 0x00000001,
	GLX_COLOR_INDEX_BIT  = 0x00000002,
	GLX_PBUFFER_CLOBBER_MASK = 0x08000000,
	GLX_SAMPLE_BUFFERS   = 0x186a0,
	GLX_SAMPLES          = 0x186a1,
};
typedef struct __GLXcontextRec *GLXContext;
typedef XID GLXPixmap;
typedef XID GLXDrawable;
typedef struct __GLXFBConfigRec *GLXFBConfig;
typedef XID GLXFBConfigID;
typedef XID GLXContextID;
typedef XID GLXWindow;
typedef XID GLXPbuffer;
XVisualInfo* glXChooseVisual( Display *dpy, int screen,
         int *attribList );
GLXContext glXCreateContext( Display *dpy, XVisualInfo *vis,
        GLXContext shareList, int direct );
void glXDestroyContext( Display *dpy, GLXContext ctx );
int glXMakeCurrent( Display *dpy, GLXDrawable drawable,
       GLXContext ctx);
void glXCopyContext( Display *dpy, GLXContext src, GLXContext dst,
       unsigned long mask );
void glXSwapBuffers( Display *dpy, GLXDrawable drawable );
GLXPixmap glXCreateGLXPixmap( Display *dpy, XVisualInfo *visual,
         Pixmap pixmap );
void glXDestroyGLXPixmap( Display *dpy, GLXPixmap pixmap );
int glXQueryExtension( Display *dpy, int *errorb, int *event );
int glXQueryVersion( Display *dpy, int *maj, int *min );
int glXIsDirect( Display *dpy, GLXContext ctx );
int glXGetConfig( Display *dpy, XVisualInfo *visual,
    int attrib, int *value );
GLXContext glXGetCurrentContext( void );
GLXDrawable glXGetCurrentDrawable( void );
void glXWaitGL( void );
void glXWaitX( void );
void glXUseXFont( Font font, int first, int count, int list );
const char *glXQueryExtensionsString( Display *dpy, int screen );
const char *glXQueryServerString( Display *dpy, int screen, int name );
const char *glXGetClientString( Display *dpy, int name );
Display *glXGetCurrentDisplay( void );
GLXFBConfig *glXChooseFBConfig( Display *dpy, int screen,
                                       const int *attribList, int *nitems );
int glXGetFBConfigAttrib( Display *dpy, GLXFBConfig config,
                                 int attribute, int *value );
GLXFBConfig *glXGetFBConfigs( Display *dpy, int screen,
                                     int *nelements );
XVisualInfo *glXGetVisualFromFBConfig( Display *dpy,
                                              GLXFBConfig config );
GLXWindow glXCreateWindow( Display *dpy, GLXFBConfig config,
                                  Window win, const int *attribList );
void glXDestroyWindow( Display *dpy, GLXWindow window );
GLXPixmap glXCreatePixmap( Display *dpy, GLXFBConfig config,
                                  Pixmap pixmap, const int *attribList );
void glXDestroyPixmap( Display *dpy, GLXPixmap pixmap );
GLXPbuffer glXCreatePbuffer( Display *dpy, GLXFBConfig config,
                                    const int *attribList );
void glXDestroyPbuffer( Display *dpy, GLXPbuffer pbuf );
void glXQueryDrawable( Display *dpy, GLXDrawable draw, int attribute,
                              unsigned int *value );
GLXContext glXCreateNewContext( Display *dpy, GLXFBConfig config,
                                       int renderType, GLXContext shareList,
                                       int direct );
int glXMakeContextCurrent( Display *dpy, GLXDrawable draw,
                                   GLXDrawable read, GLXContext ctx );
GLXDrawable glXGetCurrentReadDrawable( void );
int glXQueryContext( Display *dpy, GLXContext ctx, int attribute,
                            int *value );
void glXSelectEvent( Display *dpy, GLXDrawable drawable,
                            unsigned long mask );
void glXGetSelectedEvent( Display *dpy, GLXDrawable drawable,
                                 unsigned long *mask );
typedef GLXFBConfig * (* PFNGLXGETFBCONFIGSPROC) (Display *dpy, int screen, int *nelements);
typedef GLXFBConfig * (* PFNGLXCHOOSEFBCONFIGPROC) (Display *dpy, int screen, const int *attrib_list, int *nelements);
typedef int (* PFNGLXGETFBCONFIGATTRIBPROC) (Display *dpy, GLXFBConfig config, int attribute, int *value);
typedef XVisualInfo * (* PFNGLXGETVISUALFROMFBCONFIGPROC) (Display *dpy, GLXFBConfig config);
typedef GLXWindow (* PFNGLXCREATEWINDOWPROC) (Display *dpy, GLXFBConfig config, Window win, const int *attrib_list);
typedef void (* PFNGLXDESTROYWINDOWPROC) (Display *dpy, GLXWindow win);
typedef GLXPixmap (* PFNGLXCREATEPIXMAPPROC) (Display *dpy, GLXFBConfig config, Pixmap pixmap, const int *attrib_list);
typedef void (* PFNGLXDESTROYPIXMAPPROC) (Display *dpy, GLXPixmap pixmap);
typedef GLXPbuffer (* PFNGLXCREATEPBUFFERPROC) (Display *dpy, GLXFBConfig config, const int *attrib_list);
typedef void (* PFNGLXDESTROYPBUFFERPROC) (Display *dpy, GLXPbuffer pbuf);
typedef void (* PFNGLXQUERYDRAWABLEPROC) (Display *dpy, GLXDrawable draw, int attribute, unsigned int *value);
typedef GLXContext (* PFNGLXCREATENEWCONTEXTPROC) (Display *dpy, GLXFBConfig config, int render_type, GLXContext share_list, int direct);
typedef int (* PFNGLXMAKECONTEXTCURRENTPROC) (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
typedef GLXDrawable (* PFNGLXGETCURRENTREADDRAWABLEPROC) (void);
typedef Display * (* PFNGLXGETCURRENTDISPLAYPROC) (void);
typedef int (* PFNGLXQUERYCONTEXTPROC) (Display *dpy, GLXContext ctx, int attribute, int *value);
typedef void (* PFNGLXSELECTEVENTPROC) (Display *dpy, GLXDrawable draw, unsigned long event_mask);
typedef void (* PFNGLXGETSELECTEDEVENTPROC) (Display *dpy, GLXDrawable draw, unsigned long *event_mask);
enum {
	GLX_ARB_get_proc_address = 1,
};
typedef void (*__GLXextFuncPtr)(void);
__GLXextFuncPtr glXGetProcAddressARB (const GLubyte *);
void (*glXGetProcAddress(const GLubyte *procname))( void );
typedef __GLXextFuncPtr (* PFNGLXGETPROCADDRESSPROC) (const GLubyte *procName);
void *glXAllocateMemoryNV(GLsizei size, GLfloat readfreq, GLfloat writefreq, GLfloat priority);
void glXFreeMemoryNV(GLvoid *pointer);
typedef void * ( * PFNGLXALLOCATEMEMORYNVPROC) (GLsizei size, GLfloat readfreq, GLfloat writefreq, GLfloat priority);
typedef void ( * PFNGLXFREEMEMORYNVPROC) (GLvoid *pointer);
enum {
	GLX_MESA_allocate_memory = 1,
};
void *glXAllocateMemoryMESA(Display *dpy, int scrn, size_t size, float readfreq, float writefreq, float priority);
void glXFreeMemoryMESA(Display *dpy, int scrn, void *pointer);
GLuint glXGetMemoryOffsetMESA(Display *dpy, int scrn, const void *pointer);
typedef void * ( * PFNGLXALLOCATEMEMORYMESAPROC) (Display *dpy, int scrn, size_t size, float readfreq, float writefreq, float priority);
typedef void ( * PFNGLXFREEMEMORYMESAPROC) (Display *dpy, int scrn, void *pointer);
typedef GLuint (* PFNGLXGETMEMORYOFFSETMESAPROC) (Display *dpy, int scrn, const void *pointer);
enum {
	GLX_ARB_render_texture = 1,
};
int glXBindTexImageARB(Display *dpy, GLXPbuffer pbuffer, int buffer);
int glXReleaseTexImageARB(Display *dpy, GLXPbuffer pbuffer, int buffer);
int glXDrawableAttribARB(Display *dpy, GLXDrawable draw, const int *attribList);
enum {
	GLX_MESA_swap_frame_usage = 1,
};
int glXGetFrameUsageMESA(Display *dpy, GLXDrawable drawable, float *usage);
int glXBeginFrameTrackingMESA(Display *dpy, GLXDrawable drawable);
int glXEndFrameTrackingMESA(Display *dpy, GLXDrawable drawable);
int glXQueryFrameTrackingMESA(Display *dpy, GLXDrawable drawable, int64_t *swapCount, int64_t *missedFrames, float *lastMissedUsage);
typedef int (*PFNGLXGETFRAMEUSAGEMESAPROC) (Display *dpy, GLXDrawable drawable, float *usage);
typedef int (*PFNGLXBEGINFRAMETRACKINGMESAPROC)(Display *dpy, GLXDrawable drawable);
typedef int (*PFNGLXENDFRAMETRACKINGMESAPROC)(Display *dpy, GLXDrawable drawable);
typedef int (*PFNGLXQUERYFRAMETRACKINGMESAPROC)(Display *dpy, GLXDrawable drawable, int64_t *swapCount, int64_t *missedFrames, float *lastMissedUsage);
enum {
	GLX_MESA_swap_control = 1,
};
int glXSwapIntervalMESA(unsigned int interval);
int glXGetSwapIntervalMESA(void);
typedef int (*PFNGLXSWAPINTERVALMESAPROC)(unsigned int interval);
typedef int (*PFNGLXGETSWAPINTERVALMESAPROC)(void);
typedef struct {
    int event_type;
    int draw_type;
    unsigned long serial;
    int send_event;
    Display *display;
    GLXDrawable drawable;
    unsigned int buffer_mask;
    unsigned int aux_buffer;
    int x, y;
    int width, height;
    int count;
} GLXPbufferClobberEvent;
typedef union __GLXEvent {
    GLXPbufferClobberEvent glxpbufferclobber;
    long pad[24];
} GLXEvent;

// GL/glxext.h
enum {
	GLX_GLXEXT_VERSION   = 25,
	GLX_SAMPLE_BUFFERS_ARB = 100000,
	GLX_SAMPLES_ARB      = 100001,
	GLX_RGBA_FLOAT_TYPE_ARB = 0x20B9,
	GLX_RGBA_FLOAT_BIT_ARB = 0x00000004,
	GLX_CONTEXT_DEBUG_BIT_ARB = 0x00000001,
	GLX_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x00000002,
	GLX_CONTEXT_MAJOR_VERSION_ARB = 0x2091,
	GLX_CONTEXT_MINOR_VERSION_ARB = 0x2092,
	GLX_CONTEXT_FLAGS_ARB = 0x2094,
	GLX_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001,
	GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002,
	GLX_CONTEXT_PROFILE_MASK_ARB = 0x9126,
	GLX_SAMPLE_BUFFERS_SGIS = 100000,
	GLX_SAMPLES_SGIS     = 100001,
	GLX_X_VISUAL_TYPE_EXT = 0x22,
	GLX_TRANSPARENT_TYPE_EXT = 0x23,
	GLX_TRANSPARENT_INDEX_VALUE_EXT = 0x24,
	GLX_TRANSPARENT_RED_VALUE_EXT = 0x25,
	GLX_TRANSPARENT_GREEN_VALUE_EXT = 0x26,
	GLX_TRANSPARENT_BLUE_VALUE_EXT = 0x27,
	GLX_TRANSPARENT_ALPHA_VALUE_EXT = 0x28,
	GLX_NONE_EXT         = 0x8000,
	GLX_TRUE_COLOR_EXT   = 0x8002,
	GLX_DIRECT_COLOR_EXT = 0x8003,
	GLX_PSEUDO_COLOR_EXT = 0x8004,
	GLX_STATIC_COLOR_EXT = 0x8005,
	GLX_GRAY_SCALE_EXT   = 0x8006,
	GLX_STATIC_GRAY_EXT  = 0x8007,
	GLX_TRANSPARENT_RGB_EXT = 0x8008,
	GLX_TRANSPARENT_INDEX_EXT = 0x8009,
	GLX_VISUAL_CAVEAT_EXT = 0x20,
	GLX_SLOW_VISUAL_EXT  = 0x8001,
	GLX_NON_CONFORMANT_VISUAL_EXT = 0x800D,
	GLX_SHARE_CONTEXT_EXT = 0x800A,
	GLX_VISUAL_ID_EXT    = 0x800B,
	GLX_SCREEN_EXT       = 0x800C,
	GLX_WINDOW_BIT_SGIX  = 0x00000001,
	GLX_PIXMAP_BIT_SGIX  = 0x00000002,
	GLX_RGBA_BIT_SGIX    = 0x00000001,
	GLX_COLOR_INDEX_BIT_SGIX = 0x00000002,
	GLX_DRAWABLE_TYPE_SGIX = 0x8010,
	GLX_RENDER_TYPE_SGIX = 0x8011,
	GLX_X_RENDERABLE_SGIX = 0x8012,
	GLX_FBCONFIG_ID_SGIX = 0x8013,
	GLX_RGBA_TYPE_SGIX   = 0x8014,
	GLX_COLOR_INDEX_TYPE_SGIX = 0x8015,
	GLX_PBUFFER_BIT_SGIX = 0x00000004,
	GLX_BUFFER_CLOBBER_MASK_SGIX = 0x08000000,
	GLX_FRONT_LEFT_BUFFER_BIT_SGIX = 0x00000001,
	GLX_FRONT_RIGHT_BUFFER_BIT_SGIX = 0x00000002,
	GLX_BACK_LEFT_BUFFER_BIT_SGIX = 0x00000004,
	GLX_BACK_RIGHT_BUFFER_BIT_SGIX = 0x00000008,
	GLX_AUX_BUFFERS_BIT_SGIX = 0x00000010,
	GLX_DEPTH_BUFFER_BIT_SGIX = 0x00000020,
	GLX_STENCIL_BUFFER_BIT_SGIX = 0x00000040,
	GLX_ACCUM_BUFFER_BIT_SGIX = 0x00000080,
	GLX_SAMPLE_BUFFERS_BIT_SGIX = 0x00000100,
	GLX_MAX_PBUFFER_WIDTH_SGIX = 0x8016,
	GLX_MAX_PBUFFER_HEIGHT_SGIX = 0x8017,
	GLX_MAX_PBUFFER_PIXELS_SGIX = 0x8018,
	GLX_OPTIMAL_PBUFFER_WIDTH_SGIX = 0x8019,
	GLX_OPTIMAL_PBUFFER_HEIGHT_SGIX = 0x801A,
	GLX_PRESERVED_CONTENTS_SGIX = 0x801B,
	GLX_LARGEST_PBUFFER_SGIX = 0x801C,
	GLX_WIDTH_SGIX       = 0x801D,
	GLX_HEIGHT_SGIX      = 0x801E,
	GLX_EVENT_MASK_SGIX  = 0x801F,
	GLX_DAMAGED_SGIX     = 0x8020,
	GLX_SAVED_SGIX       = 0x8021,
	GLX_WINDOW_SGIX      = 0x8022,
	GLX_PBUFFER_SGIX     = 0x8023,
	GLX_SYNC_FRAME_SGIX  = 0x00000000,
	GLX_SYNC_SWAP_SGIX   = 0x00000001,
	GLX_DIGITAL_MEDIA_PBUFFER_SGIX = 0x8024,
	GLX_BLENDED_RGBA_SGIS = 0x8025,
	GLX_MULTISAMPLE_SUB_RECT_WIDTH_SGIS = 0x8026,
	GLX_MULTISAMPLE_SUB_RECT_HEIGHT_SGIS = 0x8027,
	GLX_SAMPLE_BUFFERS_3DFX = 0x8050,
	GLX_SAMPLES_3DFX     = 0x8051,
	GLX_3DFX_WINDOW_MODE_MESA = 0x1,
	GLX_3DFX_FULLSCREEN_MODE_MESA = 0x2,
	GLX_VISUAL_SELECT_GROUP_SGIX = 0x8028,
	GLX_SWAP_METHOD_OML  = 0x8060,
	GLX_SWAP_EXCHANGE_OML = 0x8061,
	GLX_SWAP_COPY_OML    = 0x8062,
	GLX_SWAP_UNDEFINED_OML = 0x8063,
	GLX_FLOAT_COMPONENTS_NV = 0x20B0,
	GLX_HYPERPIPE_PIPE_NAME_LENGTH_SGIX = 80,
	GLX_BAD_HYPERPIPE_CONFIG_SGIX = 91,
	GLX_BAD_HYPERPIPE_SGIX = 92,
	GLX_HYPERPIPE_DISPLAY_PIPE_SGIX = 0x00000001,
	GLX_HYPERPIPE_RENDER_PIPE_SGIX = 0x00000002,
	GLX_PIPE_RECT_SGIX   = 0x00000001,
	GLX_PIPE_RECT_LIMITS_SGIX = 0x00000002,
	GLX_HYPERPIPE_STEREO_SGIX = 0x00000003,
	GLX_HYPERPIPE_PIXEL_AVERAGE_SGIX = 0x00000004,
	GLX_HYPERPIPE_ID_SGIX = 0x8030,
	GLX_RGBA_UNSIGNED_FLOAT_TYPE_EXT = 0x20B1,
	GLX_RGBA_UNSIGNED_FLOAT_BIT_EXT = 0x00000008,
	GLX_FRAMEBUFFER_SRGB_CAPABLE_EXT = 0x20B2,
	GLX_TEXTURE_1D_BIT_EXT = 0x00000001,
	GLX_TEXTURE_2D_BIT_EXT = 0x00000002,
	GLX_TEXTURE_RECTANGLE_BIT_EXT = 0x00000004,
	GLX_BIND_TO_TEXTURE_RGB_EXT = 0x20D0,
	GLX_BIND_TO_TEXTURE_RGBA_EXT = 0x20D1,
	GLX_BIND_TO_MIPMAP_TEXTURE_EXT = 0x20D2,
	GLX_BIND_TO_TEXTURE_TARGETS_EXT = 0x20D3,
	GLX_Y_INVERTED_EXT   = 0x20D4,
	GLX_TEXTURE_FORMAT_EXT = 0x20D5,
	GLX_TEXTURE_TARGET_EXT = 0x20D6,
	GLX_MIPMAP_TEXTURE_EXT = 0x20D7,
	GLX_TEXTURE_FORMAT_NONE_EXT = 0x20D8,
	GLX_TEXTURE_FORMAT_RGB_EXT = 0x20D9,
	GLX_TEXTURE_FORMAT_RGBA_EXT = 0x20DA,
	GLX_TEXTURE_1D_EXT   = 0x20DB,
	GLX_TEXTURE_2D_EXT   = 0x20DC,
	GLX_TEXTURE_RECTANGLE_EXT = 0x20DD,
	GLX_FRONT_LEFT_EXT   = 0x20DE,
	GLX_FRONT_RIGHT_EXT  = 0x20DF,
	GLX_BACK_LEFT_EXT    = 0x20E0,
	GLX_BACK_RIGHT_EXT   = 0x20E1,
	GLX_FRONT_EXT        = GLX_FRONT_LEFT_EXT,
	GLX_BACK_EXT         = GLX_BACK_LEFT_EXT,
	GLX_AUX0_EXT         = 0x20E2,
	GLX_AUX1_EXT         = 0x20E3,
	GLX_AUX2_EXT         = 0x20E4,
	GLX_AUX3_EXT         = 0x20E5,
	GLX_AUX4_EXT         = 0x20E6,
	GLX_AUX5_EXT         = 0x20E7,
	GLX_AUX6_EXT         = 0x20E8,
	GLX_AUX7_EXT         = 0x20E9,
	GLX_AUX8_EXT         = 0x20EA,
	GLX_AUX9_EXT         = 0x20EB,
	GLX_NUM_VIDEO_SLOTS_NV = 0x20F0,
	GLX_VIDEO_OUT_COLOR_NV = 0x20C3,
	GLX_VIDEO_OUT_ALPHA_NV = 0x20C4,
	GLX_VIDEO_OUT_DEPTH_NV = 0x20C5,
	GLX_VIDEO_OUT_COLOR_AND_ALPHA_NV = 0x20C6,
	GLX_VIDEO_OUT_COLOR_AND_DEPTH_NV = 0x20C7,
	GLX_VIDEO_OUT_FRAME_NV = 0x20C8,
	GLX_VIDEO_OUT_FIELD_1_NV = 0x20C9,
	GLX_VIDEO_OUT_FIELD_2_NV = 0x20CA,
	GLX_VIDEO_OUT_STACKED_FIELDS_1_2_NV = 0x20CB,
	GLX_VIDEO_OUT_STACKED_FIELDS_2_1_NV = 0x20CC,
	GLX_DEVICE_ID_NV     = 0x20CD,
	GLX_UNIQUE_ID_NV     = 0x20CE,
	GLX_NUM_VIDEO_CAPTURE_SLOTS_NV = 0x20CF,
	GLX_SWAP_INTERVAL_EXT = 0x20F1,
	GLX_MAX_SWAP_INTERVAL_EXT = 0x20F2,
};
typedef XID GLXVideoSourceSGIX;
typedef XID GLXFBConfigIDSGIX;
typedef struct __GLXFBConfigRec *GLXFBConfigSGIX;
typedef XID GLXPbufferSGIX;
typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    Display *display;
    GLXDrawable drawable;
    int event_type;
    int draw_type;
    unsigned int mask;
    int x, y;
    int width, height;
    int count;
} GLXBufferClobberEventSGIX;
typedef unsigned int GLXVideoDeviceNV;
typedef XID GLXVideoCaptureDeviceNV;
typedef GLXContext ( * PFNGLXCREATECONTEXTATTRIBSARBPROC) (Display *dpy, GLXFBConfig config, GLXContext share_context, int direct, const int *attrib_list);
typedef int ( * PFNGLXSWAPINTERVALSGIPROC) (int interval);
typedef int ( * PFNGLXGETVIDEOSYNCSGIPROC) (unsigned int *count);
typedef int ( * PFNGLXWAITVIDEOSYNCSGIPROC) (int divisor, int remainder, unsigned int *count);
typedef int ( * PFNGLXMAKECURRENTREADSGIPROC) (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
typedef GLXDrawable ( * PFNGLXGETCURRENTREADDRAWABLESGIPROC) (void);
typedef Display * ( * PFNGLXGETCURRENTDISPLAYEXTPROC) (void);
typedef int ( * PFNGLXQUERYCONTEXTINFOEXTPROC) (Display *dpy, GLXContext context, int attribute, int *value);
typedef GLXContextID ( * PFNGLXGETCONTEXTIDEXTPROC) (const GLXContext context);
typedef GLXContext ( * PFNGLXIMPORTCONTEXTEXTPROC) (Display *dpy, GLXContextID contextID);
typedef void ( * PFNGLXFREECONTEXTEXTPROC) (Display *dpy, GLXContext context);
typedef int ( * PFNGLXGETFBCONFIGATTRIBSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, int attribute, int *value);
typedef GLXFBConfigSGIX * ( * PFNGLXCHOOSEFBCONFIGSGIXPROC) (Display *dpy, int screen, int *attrib_list, int *nelements);
typedef GLXPixmap ( * PFNGLXCREATEGLXPIXMAPWITHCONFIGSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, Pixmap pixmap);
typedef GLXContext ( * PFNGLXCREATECONTEXTWITHCONFIGSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, int render_type, GLXContext share_list, int direct);
typedef XVisualInfo * ( * PFNGLXGETVISUALFROMFBCONFIGSGIXPROC) (Display *dpy, GLXFBConfigSGIX config);
typedef GLXFBConfigSGIX ( * PFNGLXGETFBCONFIGFROMVISUALSGIXPROC) (Display *dpy, XVisualInfo *vis);
typedef GLXPbufferSGIX ( * PFNGLXCREATEGLXPBUFFERSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, unsigned int width, unsigned int height, int *attrib_list);
typedef void ( * PFNGLXDESTROYGLXPBUFFERSGIXPROC) (Display *dpy, GLXPbufferSGIX pbuf);
typedef int ( * PFNGLXQUERYGLXPBUFFERSGIXPROC) (Display *dpy, GLXPbufferSGIX pbuf, int attribute, unsigned int *value);
typedef void ( * PFNGLXSELECTEVENTSGIXPROC) (Display *dpy, GLXDrawable drawable, unsigned long mask);
typedef void ( * PFNGLXGETSELECTEDEVENTSGIXPROC) (Display *dpy, GLXDrawable drawable, unsigned long *mask);
typedef void ( * PFNGLXCUSHIONSGIPROC) (Display *dpy, Window window, float cushion);
typedef int ( * PFNGLXBINDCHANNELTOWINDOWSGIXPROC) (Display *display, int screen, int channel, Window window);
typedef int ( * PFNGLXCHANNELRECTSGIXPROC) (Display *display, int screen, int channel, int x, int y, int w, int h);
typedef int ( * PFNGLXQUERYCHANNELRECTSGIXPROC) (Display *display, int screen, int channel, int *dx, int *dy, int *dw, int *dh);
typedef int ( * PFNGLXQUERYCHANNELDELTASSGIXPROC) (Display *display, int screen, int channel, int *x, int *y, int *w, int *h);
typedef int ( * PFNGLXCHANNELRECTSYNCSGIXPROC) (Display *display, int screen, int channel, GLenum synctype);
typedef void ( * PFNGLXJOINSWAPGROUPSGIXPROC) (Display *dpy, GLXDrawable drawable, GLXDrawable member);
typedef void ( * PFNGLXBINDSWAPBARRIERSGIXPROC) (Display *dpy, GLXDrawable drawable, int barrier);
typedef int ( * PFNGLXQUERYMAXSWAPBARRIERSSGIXPROC) (Display *dpy, int screen, int *max);
typedef int ( * PFNGLXGETTRANSPARENTINDEXSUNPROC) (Display *dpy, Window overlay, Window underlay, long *pTransparentIndex);
typedef void ( * PFNGLXCOPYSUBBUFFERMESAPROC) (Display *dpy, GLXDrawable drawable, int x, int y, int width, int height);
typedef GLXPixmap ( * PFNGLXCREATEGLXPIXMAPMESAPROC) (Display *dpy, XVisualInfo *visual, Pixmap pixmap, Colormap cmap);
typedef int ( * PFNGLXRELEASEBUFFERSMESAPROC) (Display *dpy, GLXDrawable drawable);
typedef int ( * PFNGLXSET3DFXMODEMESAPROC) (int mode);
typedef int ( * PFNGLXGETSYNCVALUESOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t *ust, int64_t *msc, int64_t *sbc);
typedef int ( * PFNGLXGETMSCRATEOMLPROC) (Display *dpy, GLXDrawable drawable, int32_t *numerator, int32_t *denominator);
typedef int64_t ( * PFNGLXSWAPBUFFERSMSCOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t target_msc, int64_t divisor, int64_t remainder);
typedef int ( * PFNGLXWAITFORMSCOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t target_msc, int64_t divisor, int64_t remainder, int64_t *ust, int64_t *msc, int64_t *sbc);
typedef int ( * PFNGLXWAITFORSBCOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t target_sbc, int64_t *ust, int64_t *msc, int64_t *sbc);
typedef struct {
    char pipeName[80];
    int networkId;
} GLXHyperpipeNetworkSGIX;
typedef struct {
    char pipeName[80];
    int channel;
    unsigned int
      participationType;
    int timeSlice;
} GLXHyperpipeConfigSGIX;
typedef struct {
    char pipeName[80];
    int srcXOrigin, srcYOrigin, srcWidth, srcHeight;
    int destXOrigin, destYOrigin, destWidth, destHeight;
} GLXPipeRect;
typedef struct {
    char pipeName[80];
    int XOrigin, YOrigin, maxHeight, maxWidth;
} GLXPipeRectLimits;
typedef GLXHyperpipeNetworkSGIX * ( * PFNGLXQUERYHYPERPIPENETWORKSGIXPROC) (Display *dpy, int *npipes);
typedef int ( * PFNGLXHYPERPIPECONFIGSGIXPROC) (Display *dpy, int networkId, int npipes, GLXHyperpipeConfigSGIX *cfg, int *hpId);
typedef GLXHyperpipeConfigSGIX * ( * PFNGLXQUERYHYPERPIPECONFIGSGIXPROC) (Display *dpy, int hpId, int *npipes);
typedef int ( * PFNGLXDESTROYHYPERPIPECONFIGSGIXPROC) (Display *dpy, int hpId);
typedef int ( * PFNGLXBINDHYPERPIPESGIXPROC) (Display *dpy, int hpId);
typedef int ( * PFNGLXQUERYHYPERPIPEBESTATTRIBSGIXPROC) (Display *dpy, int timeSlice, int attrib, int size, void *attribList, void *returnAttribList);
typedef int ( * PFNGLXHYPERPIPEATTRIBSGIXPROC) (Display *dpy, int timeSlice, int attrib, int size, void *attribList);
typedef int ( * PFNGLXQUERYHYPERPIPEATTRIBSGIXPROC) (Display *dpy, int timeSlice, int attrib, int size, void *returnAttribList);
typedef unsigned int ( * PFNGLXGETAGPOFFSETMESAPROC) (const void *pointer);
typedef void ( * PFNGLXBINDTEXIMAGEEXTPROC) (Display *dpy, GLXDrawable drawable, int buffer, const int *attrib_list);
typedef void ( * PFNGLXRELEASETEXIMAGEEXTPROC) (Display *dpy, GLXDrawable drawable, int buffer);
typedef unsigned int * ( * PFNGLXENUMERATEVIDEODEVICESNVPROC) (Display *dpy, int screen, int *nelements);
typedef int ( * PFNGLXBINDVIDEODEVICENVPROC) (Display *dpy, unsigned int video_slot, unsigned int video_device, const int *attrib_list);
typedef int ( * PFNGLXGETVIDEODEVICENVPROC) (Display *dpy, int screen, int numVideoDevices, GLXVideoDeviceNV *pVideoDevice);
typedef int ( * PFNGLXRELEASEVIDEODEVICENVPROC) (Display *dpy, int screen, GLXVideoDeviceNV VideoDevice);
typedef int ( * PFNGLXBINDVIDEOIMAGENVPROC) (Display *dpy, GLXVideoDeviceNV VideoDevice, GLXPbuffer pbuf, int iVideoBuffer);
typedef int ( * PFNGLXRELEASEVIDEOIMAGENVPROC) (Display *dpy, GLXPbuffer pbuf);
typedef int ( * PFNGLXSENDPBUFFERTOVIDEONVPROC) (Display *dpy, GLXPbuffer pbuf, int iBufferType, unsigned long *pulCounterPbuffer, GLboolean bBlock);
typedef int ( * PFNGLXGETVIDEOINFONVPROC) (Display *dpy, int screen, GLXVideoDeviceNV VideoDevice, unsigned long *pulCounterOutputPbuffer, unsigned long *pulCounterOutputVideo);
typedef int ( * PFNGLXJOINSWAPGROUPNVPROC) (Display *dpy, GLXDrawable drawable, GLuint group);
typedef int ( * PFNGLXBINDSWAPBARRIERNVPROC) (Display *dpy, GLuint group, GLuint barrier);
typedef int ( * PFNGLXQUERYSWAPGROUPNVPROC) (Display *dpy, GLXDrawable drawable, GLuint *group, GLuint *barrier);
typedef int ( * PFNGLXQUERYMAXSWAPGROUPSNVPROC) (Display *dpy, int screen, GLuint *maxGroups, GLuint *maxBarriers);
typedef int ( * PFNGLXQUERYFRAMECOUNTNVPROC) (Display *dpy, int screen, GLuint *count);
typedef int ( * PFNGLXRESETFRAMECOUNTNVPROC) (Display *dpy, int screen);
typedef int ( * PFNGLXBINDVIDEOCAPTUREDEVICENVPROC) (Display *dpy, unsigned int video_capture_slot, GLXVideoCaptureDeviceNV device);
typedef GLXVideoCaptureDeviceNV * ( * PFNGLXENUMERATEVIDEOCAPTUREDEVICESNVPROC) (Display *dpy, int screen, int *nelements);
typedef void ( * PFNGLXLOCKVIDEOCAPTUREDEVICENVPROC) (Display *dpy, GLXVideoCaptureDeviceNV device);
typedef int ( * PFNGLXQUERYVIDEOCAPTUREDEVICENVPROC) (Display *dpy, GLXVideoCaptureDeviceNV device, int attribute, int *value);
typedef void ( * PFNGLXRELEASEVIDEOCAPTUREDEVICENVPROC) (Display *dpy, GLXVideoCaptureDeviceNV device);
typedef int ( * PFNGLXSWAPINTERVALEXTPROC) (Display *dpy, GLXDrawable drawable, int interval);
typedef void ( * PFNGLXCOPYIMAGESUBDATANVPROC) (Display *dpy, GLXContext srcCtx, GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLXContext dstCtx, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei width, GLsizei height, GLsizei depth);
]]
