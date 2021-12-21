
--X11/Xcursor/Xcursor.h

local ffi = require'ffi'
require'xlib_h'

ffi.cdef[[
typedef struct FILE_ FILE;

typedef int XcursorBool;
typedef unsigned int XcursorUInt;
typedef XcursorUInt XcursorDim;
typedef XcursorUInt XcursorPixel;
enum {
	XCURSOR_MAGIC        = 0x72756358,
	XCURSOR_LIB_MAJOR    = 1,
	XCURSOR_LIB_MINOR    = 1,
	XCURSOR_LIB_REVISION = 9,
	XCURSOR_LIB_VERSION  = ((XCURSOR_LIB_MAJOR * 10000) + (XCURSOR_LIB_MINOR * 100) + (XCURSOR_LIB_REVISION)),
	XCURSOR_FILE_MAJOR   = 1,
	XCURSOR_FILE_MINOR   = 0,
	XCURSOR_FILE_VERSION = ((XCURSOR_FILE_MAJOR << 16) | (XCURSOR_FILE_MINOR)),
	XCURSOR_FILE_HEADER_LEN = (4 * 4),
	XCURSOR_FILE_TOC_LEN = (3 * 4),
};
typedef struct _XcursorFileToc {
	XcursorUInt type;
	XcursorUInt subtype;
	XcursorUInt position;
} XcursorFileToc;
typedef struct _XcursorFileHeader {
	XcursorUInt magic;
	XcursorUInt header;
	XcursorUInt version;
	XcursorUInt ntoc;
	XcursorFileToc *tocs;
} XcursorFileHeader;
enum {
	XCURSOR_CHUNK_HEADER_LEN = (4 * 4),
};
typedef struct _XcursorChunkHeader {
	XcursorUInt header;
	XcursorUInt type;
	XcursorUInt subtype;
	XcursorUInt version;
} XcursorChunkHeader;
enum {
	XCURSOR_COMMENT_TYPE = 0xfffe0001,
	XCURSOR_COMMENT_VERSION = 1,
	XCURSOR_COMMENT_HEADER_LEN = (XCURSOR_CHUNK_HEADER_LEN + (1 *4)),
	XCURSOR_COMMENT_COPYRIGHT = 1,
	XCURSOR_COMMENT_LICENSE = 2,
	XCURSOR_COMMENT_OTHER = 3,
	XCURSOR_COMMENT_MAX_LEN = 0x100000,
};
typedef struct _XcursorComment {
	XcursorUInt version;
	XcursorUInt comment_type;
	char *comment;
} XcursorComment;
enum {
	XCURSOR_IMAGE_TYPE   = 0xfffd0002,
	XCURSOR_IMAGE_VERSION = 1,
	XCURSOR_IMAGE_HEADER_LEN = (XCURSOR_CHUNK_HEADER_LEN + (5*4)),
	XCURSOR_IMAGE_MAX_SIZE = 0x7fff,
};
typedef struct _XcursorImage {
	XcursorUInt version;
	XcursorDim size;
	XcursorDim width;
	XcursorDim height;
	XcursorDim xhot;
	XcursorDim yhot;
	XcursorUInt delay;
	XcursorPixel *pixels;
} XcursorImage;
typedef struct _XcursorImages {
	int nimage;
	XcursorImage **images;
	char *name;
} XcursorImages;
typedef struct _XcursorCursors {
	Display *dpy;
	int ref;
	int ncursor;
	Cursor *cursors;
} XcursorCursors;
typedef struct _XcursorAnimate {
	XcursorCursors *cursors;
	int sequence;
} XcursorAnimate;
typedef struct _XcursorFile XcursorFile;
struct _XcursorFile {
	void *closure;
	int (*read) (XcursorFile *file, unsigned char *buf, int len);
	int (*write) (XcursorFile *file, unsigned char *buf, int len);
	int (*seek) (XcursorFile *file, long offset, int whence);
};
typedef struct _XcursorComments {
	int ncomment;
	XcursorComment **comments;
} XcursorComments;
XcursorImage *
XcursorImageCreate (int width, int height);
void
XcursorImageDestroy (XcursorImage *image);
XcursorImages *
XcursorImagesCreate (int size);
void
XcursorImagesDestroy (XcursorImages *images);
void
XcursorImagesSetName (XcursorImages *images, const char *name);
XcursorCursors *
XcursorCursorsCreate (Display *dpy, int size);
void
XcursorCursorsDestroy (XcursorCursors *cursors);
XcursorAnimate *
XcursorAnimateCreate (XcursorCursors *cursors);
void
XcursorAnimateDestroy (XcursorAnimate *animate);
Cursor
XcursorAnimateNext (XcursorAnimate *animate);
XcursorComment *
XcursorCommentCreate (XcursorUInt comment_type, int length);
void
XcursorCommentDestroy (XcursorComment *comment);
XcursorComments *
XcursorCommentsCreate (int size);
void
XcursorCommentsDestroy (XcursorComments *comments);
XcursorImage *
XcursorXcFileLoadImage (XcursorFile *file, int size);
XcursorImages *
XcursorXcFileLoadImages (XcursorFile *file, int size);
XcursorImages *
XcursorXcFileLoadAllImages (XcursorFile *file);
XcursorBool
XcursorXcFileLoad (XcursorFile *file,
     XcursorComments **commentsp,
     XcursorImages **imagesp);
XcursorBool
XcursorXcFileSave (XcursorFile *file,
     const XcursorComments *comments,
     const XcursorImages *images);
XcursorImage *
XcursorFileLoadImage (FILE *file, int size);
XcursorImages *
XcursorFileLoadImages (FILE *file, int size);
XcursorImages *
XcursorFileLoadAllImages (FILE *file);
XcursorBool
XcursorFileLoad (FILE *file,
   XcursorComments **commentsp,
   XcursorImages **imagesp);
XcursorBool
XcursorFileSaveImages (FILE *file, const XcursorImages *images);
XcursorBool
XcursorFileSave (FILE * file,
   const XcursorComments *comments,
   const XcursorImages *images);
XcursorImage *
XcursorFilenameLoadImage (const char *filename, int size);
XcursorImages *
XcursorFilenameLoadImages (const char *filename, int size);
XcursorImages *
XcursorFilenameLoadAllImages (const char *filename);
XcursorBool
XcursorFilenameLoad (const char *file,
       XcursorComments **commentsp,
       XcursorImages **imagesp);
XcursorBool
XcursorFilenameSaveImages (const char *filename, const XcursorImages *images);
XcursorBool
XcursorFilenameSave (const char *file,
       const XcursorComments *comments,
       const XcursorImages *images);
XcursorImage *
XcursorLibraryLoadImage (const char *library, const char *theme, int size);
XcursorImages *
XcursorLibraryLoadImages (const char *library, const char *theme, int size);
const char *
XcursorLibraryPath (void);
int
XcursorLibraryShape (const char *library);
Cursor
XcursorImageLoadCursor (Display *dpy, const XcursorImage *image);
XcursorCursors *
XcursorImagesLoadCursors (Display *dpy, const XcursorImages *images);
Cursor
XcursorImagesLoadCursor (Display *dpy, const XcursorImages *images);
Cursor
XcursorFilenameLoadCursor (Display *dpy, const char *file);
XcursorCursors *
XcursorFilenameLoadCursors (Display *dpy, const char *file);
Cursor
XcursorLibraryLoadCursor (Display *dpy, const char *file);
XcursorCursors *
XcursorLibraryLoadCursors (Display *dpy, const char *file);
XcursorImage *
XcursorShapeLoadImage (unsigned int shape, const char *theme, int size);
XcursorImages *
XcursorShapeLoadImages (unsigned int shape, const char *theme, int size);
Cursor
XcursorShapeLoadCursor (Display *dpy, unsigned int shape);
XcursorCursors *
XcursorShapeLoadCursors (Display *dpy, unsigned int shape);
Cursor
XcursorTryShapeCursor (Display *dpy,
         Font source_font,
         Font mask_font,
         unsigned int source_char,
         unsigned int mask_char,
         XColor const *foreground,
         XColor const *background);
void
XcursorNoticeCreateBitmap (Display *dpy,
      Pixmap pid,
      unsigned int width,
      unsigned int height);
void
XcursorNoticePutBitmap (Display *dpy,
   Drawable draw,
   XImage *image);
Cursor
XcursorTryShapeBitmapCursor (Display *dpy,
        Pixmap source,
        Pixmap mask,
        XColor *foreground,
        XColor *background,
        unsigned int x,
        unsigned int y);
enum {
	XCURSOR_BITMAP_HASH_SIZE = 16,
};
void XcursorImageHash (XImage *image, unsigned char hash[16]);
XcursorBool XcursorSupportsARGB (Display *dpy);
XcursorBool XcursorSupportsAnim (Display *dpy);
XcursorBool XcursorSetDefaultSize (Display *dpy, int size);
int         XcursorGetDefaultSize (Display *dpy);
XcursorBool XcursorSetTheme (Display *dpy, const char *theme);
char*       XcursorGetTheme (Display *dpy);
XcursorBool XcursorGetThemeCore (Display *dpy);
XcursorBool XcursorSetThemeCore (Display *dpy, XcursorBool theme_core);
]]
