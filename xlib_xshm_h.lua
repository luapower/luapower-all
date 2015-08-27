
--X11/extensions/XShm.h from libxext-dev.

local ffi = require'ffi'
require'xlib_h'

ffi.cdef[[
typedef unsigned long ShmSeg;
typedef struct {
    int type;
    unsigned long serial;
    Bool send_event;
    Display *display;
    Drawable drawable;
    int major_code;
    int minor_code;
    ShmSeg shmseg;
    unsigned long offset;
} XShmCompletionEvent;
typedef struct {
    ShmSeg shmseg;
    int shmid;
    char *shmaddr;
    Bool readOnly;
} XShmSegmentInfo;
Bool XShmQueryExtension(
    Display*
);
int XShmGetEventBase(
    Display*
);
Bool XShmQueryVersion(
    Display* ,
    int* ,
    int* ,
    Bool*
);
int XShmPixmapFormat(
    Display*
);
Status XShmAttach(
    Display* ,
    XShmSegmentInfo*
);
Status XShmDetach(
    Display* ,
    XShmSegmentInfo*
);
Status XShmPutImage(
    Display* ,
    Drawable ,
    GC ,
    XImage* ,
    int ,
    int ,
    int ,
    int ,
    unsigned int ,
    unsigned int ,
    Bool
);
Status XShmGetImage(
    Display* ,
    Drawable ,
    XImage* ,
    int ,
    int ,
    unsigned long
);
XImage *XShmCreateImage(
    Display* ,
    Visual* ,
    unsigned int ,
    int ,
    char* ,
    XShmSegmentInfo* ,
    unsigned int ,
    unsigned int
);
Pixmap XShmCreatePixmap(
    Display* ,
    Drawable ,
    char* ,
    XShmSegmentInfo* ,
    unsigned int ,
    unsigned int ,
    unsigned int
);
]]
