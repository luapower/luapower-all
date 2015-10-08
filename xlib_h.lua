
--X11/X.h, X11/Xfuncproto.h, X11/Xlib.h, X11/Xutil.h, X11/Xatom.h,
--Xm/MwmUtil.h, X11/extensions/Xinerama.h, X11/extensions/XShm.h.

local ffi = require'ffi'

ffi.cdef[[

// X11/X.h
typedef unsigned long XID;
typedef unsigned long Mask;
typedef unsigned long Atom;
typedef unsigned long VisualID;
typedef unsigned long Time;
typedef int Bool;
typedef int Status;
typedef XID Window;
typedef XID Drawable;
typedef XID Font;
typedef XID Pixmap;
typedef XID Cursor;
typedef XID Colormap;
typedef XID GContext;
typedef XID KeySym;
typedef unsigned char KeyCode;
enum {
	None                 = 0,
	False                = 0,
	True                 = 1,
	ParentRelative       = 1,
	CopyFromParent       = 0,
	PointerWindow        = 0,
	InputFocus           = 1,
	PointerRoot          = 1,
	AnyPropertyType      = 0,
	AnyKey               = 0,
	AnyButton            = 0,
	AllTemporary         = 0,
	CurrentTime          = 0,
	NoSymbol             = 0,
	NoEventMask          = 0,
	KeyPressMask         = (1<<0),
	KeyReleaseMask       = (1<<1),
	ButtonPressMask      = (1<<2),
	ButtonReleaseMask    = (1<<3),
	EnterWindowMask      = (1<<4),
	LeaveWindowMask      = (1<<5),
	PointerMotionMask    = (1<<6),
	PointerMotionHintMask = (1<<7),
	Button1MotionMask    = (1<<8),
	Button2MotionMask    = (1<<9),
	Button3MotionMask    = (1<<10),
	Button4MotionMask    = (1<<11),
	Button5MotionMask    = (1<<12),
	ButtonMotionMask     = (1<<13),
	KeymapStateMask      = (1<<14),
	ExposureMask         = (1<<15),
	VisibilityChangeMask = (1<<16),
	StructureNotifyMask  = (1<<17),
	ResizeRedirectMask   = (1<<18),
	SubstructureNotifyMask = (1<<19),
	SubstructureRedirectMask = (1<<20),
	FocusChangeMask      = (1<<21),
	PropertyChangeMask   = (1<<22),
	ColormapChangeMask   = (1<<23),
	OwnerGrabButtonMask  = (1<<24),
	KeyPress             = 2,
	KeyRelease           = 3,
	ButtonPress          = 4,
	ButtonRelease        = 5,
	MotionNotify         = 6,
	EnterNotify          = 7,
	LeaveNotify          = 8,
	FocusIn              = 9,
	FocusOut             = 10,
	KeymapNotify         = 11,
	Expose               = 12,
	GraphicsExpose       = 13,
	NoExpose             = 14,
	VisibilityNotify     = 15,
	CreateNotify         = 16,
	DestroyNotify        = 17,
	UnmapNotify          = 18,
	MapNotify            = 19,
	MapRequest           = 20,
	ReparentNotify       = 21,
	ConfigureNotify      = 22,
	ConfigureRequest     = 23,
	GravityNotify        = 24,
	ResizeRequest        = 25,
	CirculateNotify      = 26,
	CirculateRequest     = 27,
	PropertyNotify       = 28,
	SelectionClear       = 29,
	SelectionRequest     = 30,
	SelectionNotify      = 31,
	ColormapNotify       = 32,
	ClientMessage        = 33,
	MappingNotify        = 34,
	GenericEvent         = 35,
	LASTEvent            = 36,
	ShiftMask            = (1<<0),
	LockMask             = (1<<1),
	ControlMask          = (1<<2),
	Mod1Mask             = (1<<3),
	Mod2Mask             = (1<<4),
	Mod3Mask             = (1<<5),
	Mod4Mask             = (1<<6),
	Mod5Mask             = (1<<7),
	ShiftMapIndex        = 0,
	LockMapIndex         = 1,
	ControlMapIndex      = 2,
	Mod1MapIndex         = 3,
	Mod2MapIndex         = 4,
	Mod3MapIndex         = 5,
	Mod4MapIndex         = 6,
	Mod5MapIndex         = 7,
	Button1Mask          = (1<<8),
	Button2Mask          = (1<<9),
	Button3Mask          = (1<<10),
	Button4Mask          = (1<<11),
	Button5Mask          = (1<<12),
	AnyModifier          = (1<<15),
	Button1              = 1,
	Button2              = 2,
	Button3              = 3,
	Button4              = 4,
	Button5              = 5,
	NotifyNormal         = 0,
	NotifyGrab           = 1,
	NotifyUngrab         = 2,
	NotifyWhileGrabbed   = 3,
	NotifyHint           = 1,
	NotifyAncestor       = 0,
	NotifyVirtual        = 1,
	NotifyInferior       = 2,
	NotifyNonlinear      = 3,
	NotifyNonlinearVirtual = 4,
	NotifyPointer        = 5,
	NotifyPointerRoot    = 6,
	NotifyDetailNone     = 7,
	VisibilityUnobscured = 0,
	VisibilityPartiallyObscured = 1,
	VisibilityFullyObscured = 2,
	PlaceOnTop           = 0,
	PlaceOnBottom        = 1,
	FamilyInternet       = 0,
	FamilyDECnet         = 1,
	FamilyChaos          = 2,
	FamilyInternet6      = 6,
	FamilyServerInterpreted = 5,
	PropertyNewValue     = 0,
	PropertyDelete       = 1,
	ColormapUninstalled  = 0,
	ColormapInstalled    = 1,
	GrabModeSync         = 0,
	GrabModeAsync        = 1,
	GrabSuccess          = 0,
	AlreadyGrabbed       = 1,
	GrabInvalidTime      = 2,
	GrabNotViewable      = 3,
	GrabFrozen           = 4,
	AsyncPointer         = 0,
	SyncPointer          = 1,
	ReplayPointer        = 2,
	AsyncKeyboard        = 3,
	SyncKeyboard         = 4,
	ReplayKeyboard       = 5,
	AsyncBoth            = 6,
	SyncBoth             = 7,
	RevertToNone         = (int)None,
	RevertToPointerRoot  = (int)PointerRoot,
	RevertToPaAnyPropertyTyperent       = 2,
	Success              = 0,
	BadRequest           = 1,
	BadValue             = 2,
	BadWindow            = 3,
	BadPixmap            = 4,
	BadAtom              = 5,
	BadCursor            = 6,
	BadFont              = 7,
	BadMatch             = 8,
	BadDrawable          = 9,
	BadAccess            = 10,
	BadAlloc             = 11,
	BadColor             = 12,
	BadGC                = 13,
	BadIDChoice          = 14,
	BadName              = 15,
	BadLength            = 16,
	BadImplementation    = 17,
	FirstExtensionError  = 128,
	LastExtensionError   = 255,
	InputOutput          = 1,
	InputOnly            = 2,
	CWBackPixmap         = (1<<0),
	CWBackPixel          = (1<<1),
	CWBorderPixmap       = (1<<2),
	CWBorderPixel        = (1<<3),
	CWBitGravity         = (1<<4),
	CWWinGravity         = (1<<5),
	CWBackingStore       = (1<<6),
	CWBackingPlanes      = (1<<7),
	CWBackingPixel       = (1<<8),
	CWOverrideRedirect   = (1<<9),
	CWSaveUnder          = (1<<10),
	CWEventMask          = (1<<11),
	CWDontPropagate      = (1<<12),
	CWColormap           = (1<<13),
	CWCursor             = (1<<14),
	CWX                  = (1<<0),
	CWY                  = (1<<1),
	CWWidth              = (1<<2),
	CWHeight             = (1<<3),
	CWBorderWidth        = (1<<4),
	CWSibling            = (1<<5),
	CWStackMode          = (1<<6),
	ForgetGravity        = 0,
	NorthWestGravity     = 1,
	NorthGravity         = 2,
	NorthEastGravity     = 3,
	WestGravity          = 4,
	CenterGravity        = 5,
	EastGravity          = 6,
	SouthWestGravity     = 7,
	SouthGravity         = 8,
	SouthEastGravity     = 9,
	StaticGravity        = 10,
	UnmapGravity         = 0,
	NotUseful            = 0,
	WhenMapped           = 1,
	Always               = 2,
	IsUnmapped           = 0,
	IsUnviewable         = 1,
	IsViewable           = 2,
	SetModeInsert        = 0,
	SetModeDelete        = 1,
	DestroyAll           = 0,
	RetainPermanent      = 1,
	RetainTemporary      = 2,
	Above                = 0,
	Below                = 1,
	TopIf                = 2,
	BottomIf             = 3,
	Opposite             = 4,
	RaiseLowest          = 0,
	LowerHighest         = 1,
	PropModeReplace      = 0,
	PropModePrepend      = 1,
	PropModeAppend       = 2,
	GXclear              = 0x0,
	GXand                = 0x1,
	GXandReverse         = 0x2,
	GXcopy               = 0x3,
	GXandInverted        = 0x4,
	GXnoop               = 0x5,
	GXxor                = 0x6,
	GXor                 = 0x7,
	GXnor                = 0x8,
	GXequiv              = 0x9,
	GXinvert             = 0xa,
	GXorReverse          = 0xb,
	GXcopyInverted       = 0xc,
	GXorInverted         = 0xd,
	GXnand               = 0xe,
	GXset                = 0xf,
	LineSolid            = 0,
	LineOnOffDash        = 1,
	LineDoubleDash       = 2,
	CapNotLast           = 0,
	CapButt              = 1,
	CapRound             = 2,
	CapProjecting        = 3,
	JoinMiter            = 0,
	JoinRound            = 1,
	JoinBevel            = 2,
	FillSolid            = 0,
	FillTiled            = 1,
	FillStippled         = 2,
	FillOpaqueStippled   = 3,
	EvenOddRule          = 0,
	WindingRule          = 1,
	ClipByChildren       = 0,
	IncludeInferiors     = 1,
	Unsorted             = 0,
	YSorted              = 1,
	YXSorted             = 2,
	YXBanded             = 3,
	CoordModeOrigin      = 0,
	CoordModePrevious    = 1,
	Complex              = 0,
	Nonconvex            = 1,
	Convex               = 2,
	ArcChord             = 0,
	ArcPieSlice          = 1,
	GCFunction           = (1<<0),
	GCPlaneMask          = (1<<1),
	GCForeground         = (1<<2),
	GCBackground         = (1<<3),
	GCLineWidth          = (1<<4),
	GCLineStyle          = (1<<5),
	GCCapStyle           = (1<<6),
	GCJoinStyle          = (1<<7),
	GCFillStyle          = (1<<8),
	GCFillRule           = (1<<9),
	GCTile               = (1<<10),
	GCStipple            = (1<<11),
	GCTileStipXOrigin    = (1<<12),
	GCTileStipYOrigin    = (1<<13),
	GCFont               = (1<<14),
	GCSubwindowMode      = (1<<15),
	GCGraphicsExposures  = (1<<16),
	GCClipXOrigin        = (1<<17),
	GCClipYOrigin        = (1<<18),
	GCClipMask           = (1<<19),
	GCDashOffset         = (1<<20),
	GCDashList           = (1<<21),
	GCArcMode            = (1<<22),
	GCLastBit            = 22,
	FontLeftToRight      = 0,
	FontRightToLeft      = 1,
	FontChange           = 255,
	XYBitmap             = 0,
	XYPixmap             = 1,
	ZPixmap              = 2,
	AllocNone            = 0,
	AllocAll             = 1,
	DoRed                = (1<<0),
	DoGreen              = (1<<1),
	DoBlue               = (1<<2),
	CursorShape          = 0,
	TileShape            = 1,
	StippleShape         = 2,
	AutoRepeatModeOff    = 0,
	AutoRepeatModeOn     = 1,
	AutoRepeatModeDefault = 2,
	LedModeOff           = 0,
	LedModeOn            = 1,
	KBKeyClickPercent    = (1<<0),
	KBBellPercent        = (1<<1),
	KBBellPitch          = (1<<2),
	KBBellDuration       = (1<<3),
	KBLed                = (1<<4),
	KBLedMode            = (1<<5),
	KBKey                = (1<<6),
	KBAutoRepeatMode     = (1<<7),
	MappingSuccess       = 0,
	MappingBusy          = 1,
	MappingFailed        = 2,
	MappingModifier      = 0,
	MappingKeyboard      = 1,
	MappingPointer       = 2,
	DontPreferBlanking   = 0,
	PreferBlanking       = 1,
	DefaultBlanking      = 2,
	DisableScreenSaver   = 0,
	DisableScreenInterval = 0,
	DontAllowExposures   = 0,
	AllowExposures       = 1,
	DefaultExposures     = 2,
	ScreenSaverReset     = 0,
	ScreenSaverActive    = 1,
	HostInsert           = 0,
	HostDelete           = 1,
	EnableAccess         = 1,
	DisableAccess        = 0,
	StaticGray           = 0,
	GrayScale            = 1,
	StaticColor          = 2,
	PseudoColor          = 3,
	TrueColor            = 4,
	DirectColor          = 5,
	LSBFirst             = 0,
	MSBFirst             = 1,
};

// X11/Xfuncproto.h
enum {
	NeedFunctionPrototypes = 1,
	NeedVarargsPrototypes = 1,
	NeedNestedPrototypes = 1,
	FUNCPROTO            = 15,
	NeedWidePrototypes   = 0,
};

// Xlib.h
typedef char *XPointer;
enum {
	QueuedAlready        = 0,
	QueuedAfterReading   = 1,
	QueuedAfterFlush     = 2,
};
typedef struct _XExtData {
	int number;
	struct _XExtData *next;
	int (*free_private)(struct _XExtData *extension);
	XPointer private_data;
} XExtData;
typedef struct {
	int extension;
	int major_opcode;
	int first_event;
	int first_error;
} XExtCodes;
typedef struct {
	int depth;
	int bits_per_pixel;
	int scanline_pad;
} XPixmapFormatValues;
typedef struct {
	int function;
	unsigned long plane_mask;
	unsigned long foreground;
	unsigned long background;
	int line_width;
	int line_style;
	int cap_style;
	int join_style;
	int fill_style;
	int fill_rule;
	int arc_mode;
	Pixmap tile;
	Pixmap stipple;
	int ts_x_origin;
	int ts_y_origin;
	Font font;
	int subwindow_mode;
	int graphics_exposures;
	int clip_x_origin;
	int clip_y_origin;
	Pixmap clip_mask;
	int dash_offset;
	char dashes;
} XGCValues;
typedef struct _XGC *GC;
typedef struct {
	XExtData *ext_data;
	VisualID visualid;
	int class;
	unsigned long red_mask, green_mask, blue_mask;
	int bits_per_rgb;
	int map_entries;
} Visual;
typedef struct {
	int depth;
	int nvisuals;
	Visual *visuals;
} Depth;
struct _XDisplay;
typedef struct {
	XExtData *ext_data;
	struct _XDisplay *display;
	Window root;
	int width, height;
	int mwidth, mheight;
	int ndepths;
	Depth *depths;
	int root_depth;
	Visual *root_visual;
	GC default_gc;
	Colormap cmap;
	unsigned long white_pixel;
	unsigned long black_pixel;
	int max_maps, min_maps;
	int backing_store;
	int save_unders;
	long root_input_mask;
} Screen;
typedef struct {
	XExtData *ext_data;
	int depth;
	int bits_per_pixel;
	int scanline_pad;
} ScreenFormat;
typedef struct {
	Pixmap background_pixmap;
	unsigned long background_pixel;
	Pixmap border_pixmap;
	unsigned long border_pixel;
	int bit_gravity;
	int win_gravity;
	int backing_store;
	unsigned long backing_planes;
	unsigned long backing_pixel;
	int save_under;
	long event_mask;
	long do_not_propagate_mask;
	int override_redirect;
	Colormap colormap;
	Cursor cursor;
} XSetWindowAttributes;
typedef struct {
	int x, y;
	int width, height;
	int border_width;
	int depth;
	Visual *visual;
	Window root;
	int class;
	int bit_gravity;
	int win_gravity;
	int backing_store;
	unsigned long backing_planes;
	unsigned long backing_pixel;
	int save_under;
	Colormap colormap;
	int map_installed;
	int map_state;
	long all_event_masks;
	long your_event_mask;
	long do_not_propagate_mask;
	int override_redirect;
	Screen *screen;
} XWindowAttributes;
typedef struct {
	int family;
	int length;
	char *address;
} XHostAddress;
typedef struct {
	int typelength;
	int valuelength;
	char *type;
	char *value;
} XServerInterpretedAddress;
typedef struct _XImage {
	int width, height;
	int xoffset;
	int format;
	char *data;
	int byte_order;
	int bitmap_unit;
	int bitmap_bit_order;
	int bitmap_pad;
	int depth;
	int bytes_per_line;
	int bits_per_pixel;
	unsigned long red_mask;
	unsigned long green_mask;
	unsigned long blue_mask;
	XPointer obdata;
	struct funcs {
		struct _XImage *(*create_image)(
			struct _XDisplay* ,
			Visual* ,
			unsigned int ,
			int ,
			int ,
			char* ,
			unsigned int ,
			unsigned int ,
			int ,
			int );
		int (*destroy_image) (struct _XImage *);
		unsigned long (*get_pixel) (struct _XImage *, int, int);
		int (*put_pixel) (struct _XImage *, int, int, unsigned long);
		struct _XImage *(*sub_image)(struct _XImage *, int, int, unsigned int, unsigned int);
		int (*add_pixel) (struct _XImage *, long);
		} f;
} XImage;
typedef struct {
	int x, y;
	int width, height;
	int border_width;
	Window sibling;
	int stack_mode;
} XWindowChanges;
typedef struct {
	unsigned long pixel;
	unsigned short red, green, blue;
	char flags;
	char pad;
} XColor;
typedef struct {
	short x1, y1, x2, y2;
} XSegment;
typedef struct {
	short x, y;
} XPoint;
typedef struct {
	short x, y;
	unsigned short width, height;
} XRectangle;
typedef struct {
	short x, y;
	unsigned short width, height;
	short angle1, angle2;
} XArc;
typedef struct {
	int key_click_percent;
	int bell_percent;
	int bell_pitch;
	int bell_duration;
	int led;
	int led_mode;
	int key;
	int auto_repeat_mode;
} XKeyboardControl;
typedef struct {
	int key_click_percent;
	int bell_percent;
	unsigned int bell_pitch, bell_duration;
	unsigned long led_mask;
	int global_auto_repeat;
	char auto_repeats[32];
} XKeyboardState;
typedef struct {
	Time time;
	short x, y;
} XTimeCoord;
typedef struct {
	int max_keypermod;
	KeyCode *modifiermap;
} XModifierKeymap;
typedef struct _XDisplay Display;
struct _XPrivate;
struct _XrmHashBucketRec;
typedef struct {
	XExtData *ext_data;
	struct _XPrivate *private1;
	int fd;
	int private2;
	int proto_major_version;
	int proto_minor_version;
	char *vendor;
	XID private3;
	XID private4;
	XID private5;
	int private6;
	XID (*resource_alloc)(struct _XDisplay*);
	int byte_order;
	int bitmap_unit;
	int bitmap_pad;
	int bitmap_bit_order;
	int nformats;
	ScreenFormat *pixmap_format;
	int private8;
	int release;
	struct _XPrivate *private9, *private10;
	int qlen;
	unsigned long last_request_read;
	unsigned long request;
	XPointer private11;
	XPointer private12;
	XPointer private13;
	XPointer private14;
	unsigned max_request_size;
	struct _XrmHashBucketRec *db;
	int (*private15)(struct _XDisplay*);
	char *display_name;
	int default_screen;
	int nscreens;
	Screen *screens;
	unsigned long motion_buffer;
	unsigned long private16;
	int min_keycode;
	int max_keycode;
	XPointer private17;
	XPointer private18;
	int private19;
	char *xdefaults;
} *_XPrivDisplay;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Window root;
	Window subwindow;
	Time time;
	int x, y;
	int x_root, y_root;
	unsigned int state;
	unsigned int keycode;
	int same_screen;
} XKeyEvent;
typedef XKeyEvent XKeyPressedEvent;
typedef XKeyEvent XKeyReleasedEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Window root;
	Window subwindow;
	Time time;
	int x, y;
	int x_root, y_root;
	unsigned int state;
	unsigned int button;
	int same_screen;
} XButtonEvent;
typedef XButtonEvent XButtonPressedEvent;
typedef XButtonEvent XButtonReleasedEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Window root;
	Window subwindow;
	Time time;
	int x, y;
	int x_root, y_root;
	unsigned int state;
	char is_hint;
	int same_screen;
} XMotionEvent;
typedef XMotionEvent XPointerMovedEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Window root;
	Window subwindow;
	Time time;
	int x, y;
	int x_root, y_root;
	int mode;
	int detail;
	int same_screen;
	int focus;
	unsigned int state;
} XCrossingEvent;
typedef XCrossingEvent XEnterWindowEvent;
typedef XCrossingEvent XLeaveWindowEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	int mode;
	int detail;
} XFocusChangeEvent;
typedef XFocusChangeEvent XFocusInEvent;
typedef XFocusChangeEvent XFocusOutEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	char key_vector[32];
} XKeymapEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	int x, y;
	int width, height;
	int count;
} XExposeEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Drawable drawable;
	int x, y;
	int width, height;
	int count;
	int major_code;
	int minor_code;
} XGraphicsExposeEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Drawable drawable;
	int major_code;
	int minor_code;
} XNoExposeEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	int state;
} XVisibilityEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window parent;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	int override_redirect;
} XCreateWindowEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
} XDestroyWindowEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
	int from_configure;
} XUnmapEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
	int override_redirect;
} XMapEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window parent;
	Window window;
} XMapRequestEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
	Window parent;
	int x, y;
	int override_redirect;
} XReparentEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	Window above;
	int override_redirect;
} XConfigureEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
	int x, y;
} XGravityEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	int width, height;
} XResizeRequestEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window parent;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	Window above;
	int detail;
	unsigned long value_mask;
} XConfigureRequestEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window event;
	Window window;
	int place;
} XCirculateEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window parent;
	Window window;
	int place;
} XCirculateRequestEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Atom atom;
	Time time;
	int state;
} XPropertyEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Atom selection;
	Time time;
} XSelectionClearEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window owner;
	Window requestor;
	Atom selection;
	Atom target;
	Atom property;
	Time time;
} XSelectionRequestEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window requestor;
	Atom selection;
	Atom target;
	Atom property;
	Time time;
} XSelectionEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Colormap colormap;
	int new;
	int state;
} XColormapEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	Atom message_type;
	int format;
	union {
		char b[20];
		short s[10];
		long l[5];
	} data;
} XClientMessageEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
	int request;
	int first_keycode;
	int count;
} XMappingEvent;
typedef struct {
	int type;
	Display *display;
	XID resourceid;
	unsigned long serial;
	unsigned char error_code;
	unsigned char request_code;
	unsigned char minor_code;
} XErrorEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	Window window;
} XAnyEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	int extension;
	int evtype;
	} XGenericEvent;
typedef struct {
	int type;
	unsigned long serial;
	int send_event;
	Display *display;
	int extension;
	int evtype;
	unsigned int cookie;
	void *data;
} XGenericEventCookie;
typedef union _XEvent {
	int type;
	XAnyEvent xany;
	XKeyEvent xkey;
	XButtonEvent xbutton;
	XMotionEvent xmotion;
	XCrossingEvent xcrossing;
	XFocusChangeEvent xfocus;
	XExposeEvent xexpose;
	XGraphicsExposeEvent xgraphicsexpose;
	XNoExposeEvent xnoexpose;
	XVisibilityEvent xvisibility;
	XCreateWindowEvent xcreatewindow;
	XDestroyWindowEvent xdestroywindow;
	XUnmapEvent xunmap;
	XMapEvent xmap;
	XMapRequestEvent xmaprequest;
	XReparentEvent xreparent;
	XConfigureEvent xconfigure;
	XGravityEvent xgravity;
	XResizeRequestEvent xresizerequest;
	XConfigureRequestEvent xconfigurerequest;
	XCirculateEvent xcirculate;
	XCirculateRequestEvent xcirculaterequest;
	XPropertyEvent xproperty;
	XSelectionClearEvent xselectionclear;
	XSelectionRequestEvent xselectionrequest;
	XSelectionEvent xselection;
	XColormapEvent xcolormap;
	XClientMessageEvent xclient;
	XMappingEvent xmapping;
	XErrorEvent xerror;
	XKeymapEvent xkeymap;
	XGenericEvent xgeneric;
	XGenericEventCookie xcookie;
	long pad[24];
} XEvent;
typedef struct {
	short lbearing;
	short rbearing;
	short width;
	short ascent;
	short descent;
	unsigned short attributes;
} XCharStruct;
typedef struct {
	Atom name;
	unsigned long card32;
} XFontProp;
typedef struct {
	XExtData *ext_data;
	Font fid;
	unsigned direction;
	unsigned min_char_or_byte2;
	unsigned max_char_or_byte2;
	unsigned min_byte1;
	unsigned max_byte1;
	int all_chars_exist;
	unsigned default_char;
	int n_properties;
	XFontProp *properties;
	XCharStruct min_bounds;
	XCharStruct max_bounds;
	XCharStruct *per_char;
	int ascent;
	int descent;
} XFontStruct;
typedef struct {
	char *chars;
	int nchars;
	int delta;
	Font font;
} XTextItem;
typedef struct {
	unsigned char byte1;
	unsigned char byte2;
} XChar2b;
typedef struct {
	XChar2b *chars;
	int nchars;
	int delta;
	Font font;
} XTextItem16;
typedef union {
	Display *display;
	GC gc;
	Visual *visual;
	Screen *screen;
	ScreenFormat *pixmap_format;
	XFontStruct *font;
} XEDataObject;
typedef struct {
	XRectangle max_ink_extent;
	XRectangle max_logical_extent;
} XFontSetExtents;
typedef struct _XOM *XOM;
typedef struct _XOC *XOC, *XFontSet;
typedef struct {
	char *chars;
	int nchars;
	int delta;
	XFontSet font_set;
} XmbTextItem;
typedef struct {
	wchar_t *chars;
	int nchars;
	int delta;
	XFontSet font_set;
} XwcTextItem;
typedef struct {
	int charset_count;
	char **charset_list;
} XOMCharSetList;
typedef enum {
	XOMOrientation_LTR_TTB,
	XOMOrientation_RTL_TTB,
	XOMOrientation_TTB_LTR,
	XOMOrientation_TTB_RTL,
	XOMOrientation_Context
} XOrientation;
typedef struct {
	int num_orientation;
	XOrientation *orientation;
} XOMOrientation;
typedef struct {
	int num_font;
	XFontStruct **font_struct_list;
	char **font_name_list;
} XOMFontInfo;
typedef struct _XIM *XIM;
typedef struct _XIC *XIC;
typedef void (*XIMProc)(
	XIM,
	XPointer,
	XPointer
);
typedef int (*XICProc)(
	XIC,
	XPointer,
	XPointer
);
typedef void (*XIDProc)(
	Display*,
	XPointer,
	XPointer
);
typedef unsigned long XIMStyle;
typedef struct {
	unsigned short count_styles;
	XIMStyle *supported_styles;
} XIMStyles;
enum {
	XIMPreeditArea       = 0x0001,
	XIMPreeditCallbacks  = 0x0002,
	XIMPreeditPosition   = 0x0004,
	XIMPreeditNothing    = 0x0008,
	XIMPreeditNone       = 0x0010,
	XIMStatusArea        = 0x0100,
	XIMStatusCallbacks   = 0x0200,
	XIMStatusNothing     = 0x0400,
	XIMStatusNone        = 0x0800,
	XBufferOverflow      = -1,
	XLookupNone          = 1,
	XLookupChars         = 2,
	XLookupKeySym        = 3,
	XLookupBoth          = 4,
};
typedef void *XVaNestedList;
typedef struct {
	XPointer client_data;
	XIMProc callback;
} XIMCallback;
typedef struct {
	XPointer client_data;
	XICProc callback;
} XICCallback;
typedef unsigned long XIMFeedback;
enum {
	XIMReverse           = 1,
	XIMUnderline         = (1<<1),
	XIMHighlight         = (1<<2),
	XIMPrimary           = (1<<5),
	XIMSecondary         = (1<<6),
	XIMTertiary          = (1<<7),
	XIMVisibleToForward  = (1<<8),
	XIMVisibleToBackword = (1<<9),
	XIMVisibleToCenter   = (1<<10),
};
typedef struct _XIMText {
	unsigned short length;
	XIMFeedback *feedback;
	int encoding_is_wchar;
	union {
		char *multi_byte;
		wchar_t *wide_char;
	} string;
} XIMText;
typedef unsigned long XIMPreeditState;
enum {
	XIMPreeditUnKnown    = 0,
	XIMPreeditEnable     = 1,
	XIMPreeditDisable    = (1<<1),
};
typedef struct _XIMPreeditStateNotifyCallbackStruct {
	XIMPreeditState state;
} XIMPreeditStateNotifyCallbackStruct;
typedef unsigned long XIMResetState;
enum {
	XIMInitialState      = 1,
	XIMPreserveState     = (1<<1),
};
typedef unsigned long XIMStringConversionFeedback;
enum {
	XIMStringConversionLeftEdge = (0x00000001),
	XIMStringConversionRightEdge = (0x00000002),
	XIMStringConversionTopEdge = (0x00000004),
	XIMStringConversionBottomEdge = (0x00000008),
	XIMStringConversionConcealed = (0x00000010),
	XIMStringConversionWrapped = (0x00000020),
};
typedef struct _XIMStringConversionText {
	unsigned short length;
	XIMStringConversionFeedback *feedback;
	int encoding_is_wchar;
	union {
		char *mbs;
		wchar_t *wcs;
	} string;
} XIMStringConversionText;
typedef unsigned short XIMStringConversionPosition;
typedef unsigned short XIMStringConversionType;
enum {
	XIMStringConversionBuffer = (0x0001),
	XIMStringConversionLine = (0x0002),
	XIMStringConversionWord = (0x0003),
	XIMStringConversionChar = (0x0004),
};
typedef unsigned short XIMStringConversionOperation;
enum {
	XIMStringConversionSubstitution = (0x0001),
	XIMStringConversionRetrieval = (0x0002),
};
typedef enum {
	XIMForwardChar, XIMBackwardChar,
	XIMForwardWord, XIMBackwardWord,
	XIMCaretUp, XIMCaretDown,
	XIMNextLine, XIMPreviousLine,
	XIMLineStart, XIMLineEnd,
	XIMAbsolutePosition,
	XIMDontChange
} XIMCaretDirection;
typedef struct _XIMStringConversionCallbackStruct {
	XIMStringConversionPosition position;
	XIMCaretDirection direction;
	XIMStringConversionOperation operation;
	unsigned short factor;
	XIMStringConversionText *text;
} XIMStringConversionCallbackStruct;
typedef struct _XIMPreeditDrawCallbackStruct {
	int caret;
	int chg_first;
	int chg_length;
	XIMText *text;
} XIMPreeditDrawCallbackStruct;
typedef enum {
	XIMIsInvisible,
	XIMIsPrimary,
	XIMIsSecondary
} XIMCaretStyle;
typedef struct _XIMPreeditCaretCallbackStruct {
	int position;
	XIMCaretDirection direction;
	XIMCaretStyle style;
} XIMPreeditCaretCallbackStruct;
typedef enum {
	XIMTextType,
	XIMBitmapType
} XIMStatusDataType;
typedef struct _XIMStatusDrawCallbackStruct {
	XIMStatusDataType type;
	union {
		XIMText *text;
		Pixmap bitmap;
	} data;
} XIMStatusDrawCallbackStruct;
typedef struct _XIMHotKeyTrigger {
	KeySym keysym;
	int modifier;
	int modifier_mask;
} XIMHotKeyTrigger;
typedef struct _XIMHotKeyTriggers {
	int num_hot_key;
	XIMHotKeyTrigger *key;
} XIMHotKeyTriggers;
typedef unsigned long XIMHotKeyState;
enum {
	XIMHotKeyStateON     = (0x0001),
	XIMHotKeyStateOFF    = (0x0002),
};
typedef struct {
	unsigned short count_values;
	char **supported_values;
} XIMValuesList;
XFontStruct *XLoadQueryFont(
	Display* ,
	const char*
);
XFontStruct *XQueryFont(
	Display* ,
	XID
);
XTimeCoord *XGetMotionEvents(
	Display* ,
	Window ,
	Time ,
	Time ,
	int*
);
XModifierKeymap *XDeleteModifiermapEntry(
	XModifierKeymap* ,
	KeyCode ,
	int
);
XModifierKeymap *XGetModifierMapping(
	Display*
);
XModifierKeymap *XInsertModifiermapEntry(
	XModifierKeymap* ,
	KeyCode ,
	int
);
XModifierKeymap *XNewModifiermap(
	int
);
XImage *XCreateImage(
	Display* ,
	Visual* ,
	unsigned int ,
	int ,
	int ,
	char* ,
	unsigned int ,
	unsigned int ,
	int ,
	int
);
int XInitImage(
	XImage*
);
XImage *XGetImage(
	Display* ,
	Drawable ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	unsigned long ,
	int
);
XImage *XGetSubImage(
	Display* ,
	Drawable ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	unsigned long ,
	int ,
	XImage* ,
	int ,
	int
);
Display *XOpenDisplay(
	const char*
);
void XrmInitialize(
	void
);
char *XFetchBytes(
	Display* ,
	int*
);
char *XFetchBuffer(
	Display* ,
	int* ,
	int
);
char *XGetAtomName(
	Display* ,
	Atom
);
int XGetAtomNames(
	Display* ,
	Atom* ,
	int ,
	char**
);
char *XGetDefault(
	Display* ,
	const char* ,
	const char*
);
char *XDisplayName(
	const char*
);
char *XKeysymToString(
	KeySym
);
int (*XSynchronize(
	Display* ,
	int
))(
	Display*
);
int (*XSetAfterFunction(
	Display* ,
	int (*) (
	  Display*
			  )
))(
	Display*
);
Atom XInternAtom(
	Display* ,
	const char* ,
	int
);
int XInternAtoms(
	Display* ,
	char** ,
	int ,
	int ,
	Atom*
);
Colormap XCopyColormapAndFree(
	Display* ,
	Colormap
);
Colormap XCreateColormap(
	Display* ,
	Window ,
	Visual* ,
	int
);
Cursor XCreatePixmapCursor(
	Display* ,
	Pixmap ,
	Pixmap ,
	XColor* ,
	XColor* ,
	unsigned int ,
	unsigned int
);
Cursor XCreateGlyphCursor(
	Display* ,
	Font ,
	Font ,
	unsigned int ,
	unsigned int ,
	XColor const * ,
	XColor const *
);
Cursor XCreateFontCursor(
	Display* ,
	unsigned int
);
Font XLoadFont(
	Display* ,
	const char*
);
GC XCreateGC(
	Display* ,
	Drawable ,
	unsigned long ,
	XGCValues*
);
GContext XGContextFromGC(
	GC
);
void XFlushGC(
	Display* ,
	GC
);
Pixmap XCreatePixmap(
	Display* ,
	Drawable ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
Pixmap XCreateBitmapFromData(
	Display* ,
	Drawable ,
	const char* ,
	unsigned int ,
	unsigned int
);
Pixmap XCreatePixmapFromBitmapData(
	Display* ,
	Drawable ,
	char* ,
	unsigned int ,
	unsigned int ,
	unsigned long ,
	unsigned long ,
	unsigned int
);
Window XCreateSimpleWindow(
	Display* ,
	Window ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned long ,
	unsigned long
);
Window XGetSelectionOwner(
	Display* ,
	Atom
);
Window XCreateWindow(
	Display* ,
	Window ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	int ,
	unsigned int ,
	Visual* ,
	unsigned long ,
	XSetWindowAttributes*
);
Colormap *XListInstalledColormaps(
	Display* ,
	Window ,
	int*
);
char **XListFonts(
	Display* ,
	const char* ,
	int ,
	int*
);
char **XListFontsWithInfo(
	Display* ,
	const char* ,
	int ,
	int* ,
	XFontStruct**
);
char **XGetFontPath(
	Display* ,
	int*
);
char **XListExtensions(
	Display* ,
	int*
);
Atom *XListProperties(
	Display* ,
	Window ,
	int*
);
XHostAddress *XListHosts(
	Display* ,
	int* ,
	int*
);
KeySym XKeycodeToKeysym(
	Display* ,
	KeyCode ,
	int
);
KeySym XLookupKeysym(
	XKeyEvent* ,
	int
);
KeySym *XGetKeyboardMapping(
	Display* ,
	KeyCode ,
	int ,
	int*
);
KeySym XStringToKeysym(
	const char*
);
long XMaxRequestSize(
	Display*
);
long XExtendedMaxRequestSize(
	Display*
);
char *XResourceManagerString(
	Display*
);
char *XScreenResourceString(
Screen*
);
unsigned long XDisplayMotionBufferSize(
	Display*
);
VisualID XVisualIDFromVisual(
	Visual*
);
int XInitThreads(
	void
);
void XLockDisplay(
	Display*
);
void XUnlockDisplay(
	Display*
);
XExtCodes *XInitExtension(
	Display* ,
	const char*
);
XExtCodes *XAddExtension(
	Display*
);
XExtData *XFindOnExtensionList(
	XExtData** ,
	int
);
XExtData **XEHeadOfExtensionList(
	XEDataObject
);
Window XRootWindow(
	Display* ,
	int
);
Window XDefaultRootWindow(
	Display*
);
Window XRootWindowOfScreen(
	Screen*
);
Visual *XDefaultVisual(
	Display* ,
	int
);
Visual *XDefaultVisualOfScreen(
	Screen*
);
GC XDefaultGC(
	Display* ,
	int
);
GC XDefaultGCOfScreen(
	Screen*
);
unsigned long XBlackPixel(
	Display* ,
	int
);
unsigned long XWhitePixel(
	Display* ,
	int
);
unsigned long XAllPlanes(
	void
);
unsigned long XBlackPixelOfScreen(
	Screen*
);
unsigned long XWhitePixelOfScreen(
	Screen*
);
unsigned long XNextRequest(
	Display*
);
unsigned long XLastKnownRequestProcessed(
	Display*
);
char *XServerVendor(
	Display*
);
char *XDisplayString(
	Display*
);
Colormap XDefaultColormap(
	Display* ,
	int
);
Colormap XDefaultColormapOfScreen(
	Screen*
);
Display *XDisplayOfScreen(
	Screen*
);
Screen *XScreenOfDisplay(
	Display* ,
	int
);
Screen *XDefaultScreenOfDisplay(
	Display*
);
long XEventMaskOfScreen(
	Screen*
);
int XScreenNumberOfScreen(
	Screen*
);
typedef int (*XErrorHandler) (
	Display* ,
	XErrorEvent*
);
XErrorHandler XSetErrorHandler (
	XErrorHandler
);
typedef int (*XIOErrorHandler) (
	Display*
);
XIOErrorHandler XSetIOErrorHandler (
	XIOErrorHandler
);
XPixmapFormatValues *XListPixmapFormats(
	Display* ,
	int*
);
int *XListDepths(
	Display* ,
	int ,
	int*
);
int XReconfigureWMWindow(
	Display* ,
	Window ,
	int ,
	unsigned int ,
	XWindowChanges*
);
int XGetWMProtocols(
	Display* ,
	Window ,
	Atom** ,
	int*
);
int XSetWMProtocols(
	Display* ,
	Window ,
	Atom* ,
	int
);
int XIconifyWindow(
	Display* ,
	Window ,
	int
);
int XWithdrawWindow(
	Display* ,
	Window ,
	int
);
int XGetCommand(
	Display* ,
	Window ,
	char*** ,
	int*
);
int XGetWMColormapWindows(
	Display* ,
	Window ,
	Window** ,
	int*
);
int XSetWMColormapWindows(
	Display* ,
	Window ,
	Window* ,
	int
);
void XFreeStringList(
	char**
);
int XSetTransientForHint(
	Display* ,
	Window ,
	Window
);
int XActivateScreenSaver(
	Display*
);
int XAddHost(
	Display* ,
	XHostAddress*
);
int XAddHosts(
	Display* ,
	XHostAddress* ,
	int
);
int XAddToExtensionList(
	struct _XExtData** ,
	XExtData*
);
int XAddToSaveSet(
	Display* ,
	Window
);
int XAllocColor(
	Display* ,
	Colormap ,
	XColor*
);
int XAllocColorCells(
	Display* ,
	Colormap ,
	int ,
	unsigned long* ,
	unsigned int ,
	unsigned long* ,
	unsigned int
);
int XAllocColorPlanes(
	Display* ,
	Colormap ,
	int ,
	unsigned long* ,
	int ,
	int ,
	int ,
	int ,
	unsigned long* ,
	unsigned long* ,
	unsigned long*
);
int XAllocNamedColor(
	Display* ,
	Colormap ,
	const char* ,
	XColor* ,
	XColor*
);
int XAllowEvents(
	Display* ,
	int ,
	Time
);
int XAutoRepeatOff(
	Display*
);
int XAutoRepeatOn(
	Display*
);
int XBell(
	Display* ,
	int
);
int XBitmapBitOrder(
	Display*
);
int XBitmapPad(
	Display*
);
int XBitmapUnit(
	Display*
);
int XCellsOfScreen(
	Screen*
);
int XChangeActivePointerGrab(
	Display* ,
	unsigned int ,
	Cursor ,
	Time
);
int XChangeGC(
	Display* ,
	GC ,
	unsigned long ,
	XGCValues*
);
int XChangeKeyboardControl(
	Display* ,
	unsigned long ,
	XKeyboardControl*
);
int XChangeKeyboardMapping(
	Display* ,
	int ,
	int ,
	KeySym* ,
	int
);
int XChangePointerControl(
	Display* ,
	int ,
	int ,
	int ,
	int ,
	int
);
int XChangeProperty(
	Display* ,
	Window ,
	Atom ,
	Atom ,
	int ,
	int ,
	const unsigned char* ,
	int
);
int XChangeSaveSet(
	Display* ,
	Window ,
	int
);
int XChangeWindowAttributes(
	Display* ,
	Window ,
	unsigned long ,
	XSetWindowAttributes*
);
int XCheckIfEvent(
	Display* ,
	XEvent* ,
	int (*) (
		 Display* ,
				  XEvent* ,
				  XPointer
				) ,
	XPointer
);
int XCheckMaskEvent(
	Display* ,
	long ,
	XEvent*
);
int XCheckTypedEvent(
	Display* ,
	int ,
	XEvent*
);
int XCheckTypedWindowEvent(
	Display* ,
	Window ,
	int ,
	XEvent*
);
int XCheckWindowEvent(
	Display* ,
	Window ,
	long ,
	XEvent*
);
int XCirculateSubwindows(
	Display* ,
	Window ,
	int
);
int XCirculateSubwindowsDown(
	Display* ,
	Window
);
int XCirculateSubwindowsUp(
	Display* ,
	Window
);
int XClearArea(
	Display* ,
	Window ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	int
);
int XClearWindow(
	Display* ,
	Window
);
int XCloseDisplay(
	Display*
);
int XConfigureWindow(
	Display* ,
	Window ,
	unsigned int ,
	XWindowChanges*
);
int XConnectionNumber(
	Display*
);
int XConvertSelection(
	Display* ,
	Atom ,
	Atom ,
	Atom ,
	Window ,
	Time
);
int XCopyArea(
	Display* ,
	Drawable ,
	Drawable ,
	GC ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	int ,
	int
);
int XCopyGC(
	Display* ,
	GC ,
	unsigned long ,
	GC
);
int XCopyPlane(
	Display* ,
	Drawable ,
	Drawable ,
	GC ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	int ,
	int ,
	unsigned long
);
int XDefaultDepth(
	Display* ,
	int
);
int XDefaultDepthOfScreen(
	Screen*
);
int XDefaultScreen(
	Display*
);
int XDefineCursor(
	Display* ,
	Window ,
	Cursor
);
int XDeleteProperty(
	Display* ,
	Window ,
	Atom
);
int XDestroyWindow(
	Display* ,
	Window
);
int XDestroySubwindows(
	Display* ,
	Window
);
int XDoesBackingStore(
	Screen*
);
int XDoesSaveUnders(
	Screen*
);
int XDisableAccessControl(
	Display*
);
int XDisplayCells(
	Display* ,
	int
);
int XDisplayHeight(
	Display* ,
	int
);
int XDisplayHeightMM(
	Display* ,
	int
);
int XDisplayKeycodes(
	Display* ,
	int* ,
	int*
);
int XDisplayPlanes(
	Display* ,
	int
);
int XDisplayWidth(
	Display* ,
	int
);
int XDisplayWidthMM(
	Display* ,
	int
);
int XDrawArc(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	int ,
	int
);
int XDrawArcs(
	Display* ,
	Drawable ,
	GC ,
	XArc* ,
	int
);
int XDrawImageString(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	const char* ,
	int
);
int XDrawImageString16(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	const XChar2b* ,
	int
);
int XDrawLine(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	int ,
	int
);
int XDrawLines(
	Display* ,
	Drawable ,
	GC ,
	XPoint* ,
	int ,
	int
);
int XDrawPoint(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int
);
int XDrawPoints(
	Display* ,
	Drawable ,
	GC ,
	XPoint* ,
	int ,
	int
);
int XDrawRectangle(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	unsigned int ,
	unsigned int
);
int XDrawRectangles(
	Display* ,
	Drawable ,
	GC ,
	XRectangle* ,
	int
);
int XDrawSegments(
	Display* ,
	Drawable ,
	GC ,
	XSegment* ,
	int
);
int XDrawString(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	const char* ,
	int
);
int XDrawString16(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	const XChar2b* ,
	int
);
int XDrawText(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	XTextItem* ,
	int
);
int XDrawText16(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	XTextItem16* ,
	int
);
int XEnableAccessControl(
	Display*
);
int XEventsQueued(
	Display* ,
	int
);
int XFetchName(
	Display* ,
	Window ,
	char**
);
int XFillArc(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	int ,
	int
);
int XFillArcs(
	Display* ,
	Drawable ,
	GC ,
	XArc* ,
	int
);
int XFillPolygon(
	Display* ,
	Drawable ,
	GC ,
	XPoint* ,
	int ,
	int ,
	int
);
int XFillRectangle(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	unsigned int ,
	unsigned int
);
int XFillRectangles(
	Display* ,
	Drawable ,
	GC ,
	XRectangle* ,
	int
);
int XFlush(
	Display*
);
int XForceScreenSaver(
	Display* ,
	int
);
int XFree(
	void*
);
int XFreeColormap(
	Display* ,
	Colormap
);
int XFreeColors(
	Display* ,
	Colormap ,
	unsigned long* ,
	int ,
	unsigned long
);
int XFreeCursor(
	Display* ,
	Cursor
);
int XFreeExtensionList(
	char**
);
int XFreeFont(
	Display* ,
	XFontStruct*
);
int XFreeFontInfo(
	char** ,
	XFontStruct* ,
	int
);
int XFreeFontNames(
	char**
);
int XFreeFontPath(
	char**
);
int XFreeGC(
	Display* ,
	GC
);
int XFreeModifiermap(
	XModifierKeymap*
);
int XFreePixmap(
	Display* ,
	Pixmap
);
int XGeometry(
	Display* ,
	int ,
	const char* ,
	const char* ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	int ,
	int ,
	int* ,
	int* ,
	int* ,
	int*
);
int XGetErrorDatabaseText(
	Display* ,
	const char* ,
	const char* ,
	const char* ,
	char* ,
	int
);
int XGetErrorText(
	Display* ,
	int ,
	char* ,
	int
);
int XGetFontProperty(
	XFontStruct* ,
	Atom ,
	unsigned long*
);
int XGetGCValues(
	Display* ,
	GC ,
	unsigned long ,
	XGCValues*
);
int XGetGeometry(
	Display* ,
	Drawable ,
	Window* ,
	int* ,
	int* ,
	unsigned int* ,
	unsigned int* ,
	unsigned int* ,
	unsigned int*
);
int XGetIconName(
	Display* ,
	Window ,
	char**
);
int XGetInputFocus(
	Display* ,
	Window* ,
	int*
);
int XGetKeyboardControl(
	Display* ,
	XKeyboardState*
);
int XGetPointerControl(
	Display* ,
	int* ,
	int* ,
	int*
);
int XGetPointerMapping(
	Display* ,
	unsigned char* ,
	int
);
int XGetScreenSaver(
	Display* ,
	int* ,
	int* ,
	int* ,
	int*
);
int XGetTransientForHint(
	Display* ,
	Window ,
	Window*
);
int XGetWindowProperty(
	Display* ,
	Window ,
	Atom ,
	long ,
	long ,
	int ,
	Atom ,
	Atom* ,
	int* ,
	unsigned long* ,
	unsigned long* ,
	unsigned char**
);
int XGetWindowAttributes(
	Display* ,
	Window ,
	XWindowAttributes*
);
int XGrabButton(
	Display* ,
	unsigned int ,
	unsigned int ,
	Window ,
	int ,
	unsigned int ,
	int ,
	int ,
	Window ,
	Cursor
);
int XGrabKey(
	Display* ,
	int ,
	unsigned int ,
	Window ,
	int ,
	int ,
	int
);
int XGrabKeyboard(
	Display* ,
	Window ,
	int ,
	int ,
	int ,
	Time
);
int XGrabPointer(
	Display* ,
	Window ,
	int ,
	unsigned int ,
	int ,
	int ,
	Window ,
	Cursor ,
	Time
);
int XGrabServer(
	Display*
);
int XHeightMMOfScreen(
	Screen*
);
int XHeightOfScreen(
	Screen*
);
typedef int (*XIfEventCallback) (Display*, XEvent*, XPointer);
int XIfEvent(
	Display* ,
	XEvent* ,
	XIfEventCallback ,
	XPointer
);
int XImageByteOrder(
	Display*
);
int XInstallColormap(
	Display* ,
	Colormap
);
KeyCode XKeysymToKeycode(
	Display* ,
	KeySym
);
int XKillClient(
	Display* ,
	XID
);
int XLookupColor(
	Display* ,
	Colormap ,
	const char* ,
	XColor* ,
	XColor*
);
int XLowerWindow(
	Display* ,
	Window
);
int XMapRaised(
	Display* ,
	Window
);
int XMapSubwindows(
	Display* ,
	Window
);
int XMapWindow(
	Display* ,
	Window
);
int XMaskEvent(
	Display* ,
	long ,
	XEvent*
);
int XMaxCmapsOfScreen(
	Screen*
);
int XMinCmapsOfScreen(
	Screen*
);
int XMoveResizeWindow(
	Display* ,
	Window ,
	int ,
	int ,
	unsigned int ,
	unsigned int
);
int XMoveWindow(
	Display* ,
	Window ,
	int ,
	int
);
int XNextEvent(
	Display* ,
	XEvent*
);
int XNoOp(
	Display*
);
int XParseColor(
	Display* ,
	Colormap ,
	const char* ,
	XColor*
);
int XParseGeometry(
	const char* ,
	int* ,
	int* ,
	unsigned int* ,
	unsigned int*
);
int XPeekEvent(
	Display* ,
	XEvent*
);
int XPeekIfEvent(
	Display* ,
	XEvent* ,
	XIfEventCallback ,
	XPointer
);
int XPending(
	Display*
);
int XPlanesOfScreen(
	Screen*
);
int XProtocolRevision(
	Display*
);
int XProtocolVersion(
	Display*
);
int XPutBackEvent(
	Display* ,
	XEvent*
);
int XPutImage(
	Display* ,
	Drawable ,
	GC ,
	XImage* ,
	int ,
	int ,
	int ,
	int ,
	unsigned int ,
	unsigned int
);
int XQLength(
	Display*
);
int XQueryBestCursor(
	Display* ,
	Drawable ,
	unsigned int ,
	unsigned int ,
	unsigned int* ,
	unsigned int*
);
int XQueryBestSize(
	Display* ,
	int ,
	Drawable ,
	unsigned int ,
	unsigned int ,
	unsigned int* ,
	unsigned int*
);
int XQueryBestStipple(
	Display* ,
	Drawable ,
	unsigned int ,
	unsigned int ,
	unsigned int* ,
	unsigned int*
);
int XQueryBestTile(
	Display* ,
	Drawable ,
	unsigned int ,
	unsigned int ,
	unsigned int* ,
	unsigned int*
);
int XQueryColor(
	Display* ,
	Colormap ,
	XColor*
);
int XQueryColors(
	Display* ,
	Colormap ,
	XColor* ,
	int
);
int XQueryExtension(
	Display* ,
	const char* ,
	int* ,
	int* ,
	int*
);
int XQueryKeymap(
	Display* ,
	char [32]
);
int XQueryPointer(
	Display* ,
	Window ,
	Window* ,
	Window* ,
	int* ,
	int* ,
	int* ,
	int* ,
	unsigned int*
);
int XQueryTextExtents(
	Display* ,
	XID ,
	const char* ,
	int ,
	int* ,
	int* ,
	int* ,
	XCharStruct*
);
int XQueryTextExtents16(
	Display* ,
	XID ,
	const XChar2b* ,
	int ,
	int* ,
	int* ,
	int* ,
	XCharStruct*
);
int XQueryTree(
	Display* ,
	Window ,
	Window* ,
	Window* ,
	Window** ,
	unsigned int*
);
int XRaiseWindow(
	Display* ,
	Window
);
int XReadBitmapFile(
	Display* ,
	Drawable ,
	const char* ,
	unsigned int* ,
	unsigned int* ,
	Pixmap* ,
	int* ,
	int*
);
int XReadBitmapFileData(
	const char* ,
	unsigned int* ,
	unsigned int* ,
	unsigned char** ,
	int* ,
	int*
);
int XRebindKeysym(
	Display* ,
	KeySym ,
	KeySym* ,
	int ,
	const unsigned char* ,
	int
);
int XRecolorCursor(
	Display* ,
	Cursor ,
	XColor* ,
	XColor*
);
int XRefreshKeyboardMapping(
	XMappingEvent*
);
int XRemoveFromSaveSet(
	Display* ,
	Window
);
int XRemoveHost(
	Display* ,
	XHostAddress*
);
int XRemoveHosts(
	Display* ,
	XHostAddress* ,
	int
);
int XReparentWindow(
	Display* ,
	Window ,
	Window ,
	int ,
	int
);
int XResetScreenSaver(
	Display*
);
int XResizeWindow(
	Display* ,
	Window ,
	unsigned int ,
	unsigned int
);
int XRestackWindows(
	Display* ,
	Window* ,
	int
);
int XRotateBuffers(
	Display* ,
	int
);
int XRotateWindowProperties(
	Display* ,
	Window ,
	Atom* ,
	int ,
	int
);
int XScreenCount(
	Display*
);
int XSelectInput(
	Display* ,
	Window ,
	long
);
int XSendEvent(
	Display* ,
	Window ,
	int ,
	long ,
	XEvent*
);
int XSetAccessControl(
	Display* ,
	int
);
int XSetArcMode(
	Display* ,
	GC ,
	int
);
int XSetBackground(
	Display* ,
	GC ,
	unsigned long
);
int XSetClipMask(
	Display* ,
	GC ,
	Pixmap
);
int XSetClipOrigin(
	Display* ,
	GC ,
	int ,
	int
);
int XSetClipRectangles(
	Display* ,
	GC ,
	int ,
	int ,
	XRectangle* ,
	int ,
	int
);
int XSetCloseDownMode(
	Display* ,
	int
);
int XSetCommand(
	Display* ,
	Window ,
	char** ,
	int
);
int XSetDashes(
	Display* ,
	GC ,
	int ,
	const char* ,
	int
);
int XSetFillRule(
	Display* ,
	GC ,
	int
);
int XSetFillStyle(
	Display* ,
	GC ,
	int
);
int XSetFont(
	Display* ,
	GC ,
	Font
);
int XSetFontPath(
	Display* ,
	char** ,
	int
);
int XSetForeground(
	Display* ,
	GC ,
	unsigned long
);
int XSetFunction(
	Display* ,
	GC ,
	int
);
int XSetGraphicsExposures(
	Display* ,
	GC ,
	int
);
int XSetIconName(
	Display* ,
	Window ,
	const char*
);
int XSetInputFocus(
	Display* ,
	Window ,
	int ,
	Time
);
int XSetLineAttributes(
	Display* ,
	GC ,
	unsigned int ,
	int ,
	int ,
	int
);
int XSetModifierMapping(
	Display* ,
	XModifierKeymap*
);
int XSetPlaneMask(
	Display* ,
	GC ,
	unsigned long
);
int XSetPointerMapping(
	Display* ,
	const unsigned char* ,
	int
);
int XSetScreenSaver(
	Display* ,
	int ,
	int ,
	int ,
	int
);
int XSetSelectionOwner(
	Display* ,
	Atom ,
	Window ,
	Time
);
int XSetState(
	Display* ,
	GC ,
	unsigned long ,
	unsigned long ,
	int ,
	unsigned long
);
int XSetStipple(
	Display* ,
	GC ,
	Pixmap
);
int XSetSubwindowMode(
	Display* ,
	GC ,
	int
);
int XSetTSOrigin(
	Display* ,
	GC ,
	int ,
	int
);
int XSetTile(
	Display* ,
	GC ,
	Pixmap
);
int XSetWindowBackground(
	Display* ,
	Window ,
	unsigned long
);
int XSetWindowBackgroundPixmap(
	Display* ,
	Window ,
	Pixmap
);
int XSetWindowBorder(
	Display* ,
	Window ,
	unsigned long
);
int XSetWindowBorderPixmap(
	Display* ,
	Window ,
	Pixmap
);
int XSetWindowBorderWidth(
	Display* ,
	Window ,
	unsigned int
);
int XSetWindowColormap(
	Display* ,
	Window ,
	Colormap
);
int XStoreBuffer(
	Display* ,
	const char* ,
	int ,
	int
);
int XStoreBytes(
	Display* ,
	const char* ,
	int
);
int XStoreColor(
	Display* ,
	Colormap ,
	XColor*
);
int XStoreColors(
	Display* ,
	Colormap ,
	XColor* ,
	int
);
int XStoreName(
	Display* ,
	Window ,
	const char*
);
int XStoreNamedColor(
	Display* ,
	Colormap ,
	const char* ,
	unsigned long ,
	int
);
int XSync(
	Display* ,
	int
);
int XTextExtents(
	XFontStruct* ,
	const char* ,
	int ,
	int* ,
	int* ,
	int* ,
	XCharStruct*
);
int XTextExtents16(
	XFontStruct* ,
	const XChar2b* ,
	int ,
	int* ,
	int* ,
	int* ,
	XCharStruct*
);
int XTextWidth(
	XFontStruct* ,
	const char* ,
	int
);
int XTextWidth16(
	XFontStruct* ,
	const XChar2b* ,
	int
);
int XTranslateCoordinates(
	Display* ,
	Window ,
	Window ,
	int ,
	int ,
	int* ,
	int* ,
	Window*
);
int XUndefineCursor(
	Display* ,
	Window
);
int XUngrabButton(
	Display* ,
	unsigned int ,
	unsigned int ,
	Window
);
int XUngrabKey(
	Display* ,
	int ,
	unsigned int ,
	Window
);
int XUngrabKeyboard(
	Display* ,
	Time
);
int XUngrabPointer(
	Display* ,
	Time
);
int XUngrabServer(
	Display*
);
int XUninstallColormap(
	Display* ,
	Colormap
);
int XUnloadFont(
	Display* ,
	Font
);
int XUnmapSubwindows(
	Display* ,
	Window
);
int XUnmapWindow(
	Display* ,
	Window
);
int XVendorRelease(
	Display*
);
int XWarpPointer(
	Display* ,
	Window ,
	Window ,
	int ,
	int ,
	unsigned int ,
	unsigned int ,
	int ,
	int
);
int XWidthMMOfScreen(
	Screen*
);
int XWidthOfScreen(
	Screen*
);
int XWindowEvent(
	Display* ,
	Window ,
	long ,
	XEvent*
);
int XWriteBitmapFile(
	Display* ,
	const char* ,
	Pixmap ,
	unsigned int ,
	unsigned int ,
	int ,
	int
);
int XSupportsLocale (void);
char *XSetLocaleModifiers(
	const char*
);
XOM XOpenOM(
	Display* ,
	struct _XrmHashBucketRec* ,
	const char* ,
	const char*
);
int XCloseOM(
	XOM
);
char *XSetOMValues(
	XOM ,
	...
);
char *XGetOMValues(
	XOM ,
	...
);
Display *XDisplayOfOM(
	XOM
);
char *XLocaleOfOM(
	XOM
);
XOC XCreateOC(
	XOM ,
	...
);
void XDestroyOC(
	XOC
);
XOM XOMOfOC(
	XOC
);
char *XSetOCValues(
	XOC ,
	...
);
char *XGetOCValues(
	XOC ,
	...
);
XFontSet XCreateFontSet(
	Display* ,
	const char* ,
	char*** ,
	int* ,
	char**
);
void XFreeFontSet(
	Display* ,
	XFontSet
);
int XFontsOfFontSet(
	XFontSet ,
	XFontStruct*** ,
	char***
);
char *XBaseFontNameListOfFontSet(
	XFontSet
);
char *XLocaleOfFontSet(
	XFontSet
);
int XContextDependentDrawing(
	XFontSet
);
int XDirectionalDependentDrawing(
	XFontSet
);
int XContextualDrawing(
	XFontSet
);
XFontSetExtents *XExtentsOfFontSet(
	XFontSet
);
int XmbTextEscapement(
	XFontSet ,
	const char* ,
	int
);
int XwcTextEscapement(
	XFontSet ,
	const wchar_t* ,
	int
);
int Xutf8TextEscapement(
	XFontSet ,
	const char* ,
	int
);
int XmbTextExtents(
	XFontSet ,
	const char* ,
	int ,
	XRectangle* ,
	XRectangle*
);
int XwcTextExtents(
	XFontSet ,
	const wchar_t* ,
	int ,
	XRectangle* ,
	XRectangle*
);
int Xutf8TextExtents(
	XFontSet ,
	const char* ,
	int ,
	XRectangle* ,
	XRectangle*
);
int XmbTextPerCharExtents(
	XFontSet ,
	const char* ,
	int ,
	XRectangle* ,
	XRectangle* ,
	int ,
	int* ,
	XRectangle* ,
	XRectangle*
);
int XwcTextPerCharExtents(
	XFontSet ,
	const wchar_t* ,
	int ,
	XRectangle* ,
	XRectangle* ,
	int ,
	int* ,
	XRectangle* ,
	XRectangle*
);
int Xutf8TextPerCharExtents(
	XFontSet ,
	const char* ,
	int ,
	XRectangle* ,
	XRectangle* ,
	int ,
	int* ,
	XRectangle* ,
	XRectangle*
);
void XmbDrawText(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	XmbTextItem* ,
	int
);
void XwcDrawText(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	XwcTextItem* ,
	int
);
void Xutf8DrawText(
	Display* ,
	Drawable ,
	GC ,
	int ,
	int ,
	XmbTextItem* ,
	int
);
void XmbDrawString(
	Display* ,
	Drawable ,
	XFontSet ,
	GC ,
	int ,
	int ,
	const char* ,
	int
);
void XwcDrawString(
	Display* ,
	Drawable ,
	XFontSet ,
	GC ,
	int ,
	int ,
	const wchar_t* ,
	int
);
void Xutf8DrawString(
	Display* ,
	Drawable ,
	XFontSet ,
	GC ,
	int ,
	int ,
	const char* ,
	int
);
void XmbDrawImageString(
	Display* ,
	Drawable ,
	XFontSet ,
	GC ,
	int ,
	int ,
	const char* ,
	int
);
void XwcDrawImageString(
	Display* ,
	Drawable ,
	XFontSet ,
	GC ,
	int ,
	int ,
	const wchar_t* ,
	int
);
void Xutf8DrawImageString(
	Display* ,
	Drawable ,
	XFontSet ,
	GC ,
	int ,
	int ,
	const char* ,
	int
);
XIM XOpenIM(
	Display* ,
	struct _XrmHashBucketRec* ,
	char* ,
	char*
);
int XCloseIM(
	XIM
);
char *XGetIMValues(
	XIM , ...
);
char *XSetIMValues(
	XIM , ...
);
Display *XDisplayOfIM(
	XIM
);
char *XLocaleOfIM(
	XIM
);
XIC XCreateIC(
	XIM , ...
);
void XDestroyIC(
	XIC
);
void XSetICFocus(
	XIC
);
void XUnsetICFocus(
	XIC
);
wchar_t *XwcResetIC(
	XIC
);
char *XmbResetIC(
	XIC
);
char *Xutf8ResetIC(
	XIC
);
char *XSetICValues(
	XIC , ...
);
char *XGetICValues(
	XIC , ...
);
XIM XIMOfIC(
	XIC
);
int XFilterEvent(
	XEvent* ,
	Window
);
int XmbLookupString(
	XIC ,
	XKeyPressedEvent* ,
	char* ,
	int ,
	KeySym* ,
	int*
);
int XwcLookupString(
	XIC ,
	XKeyPressedEvent* ,
	wchar_t* ,
	int ,
	KeySym* ,
	int*
);
int Xutf8LookupString(
	XIC ,
	XKeyPressedEvent* ,
	char* ,
	int ,
	KeySym* ,
	int*
);
XVaNestedList XVaCreateNestedList(
	int , ...
);
int XRegisterIMInstantiateCallback(
	Display* ,
	struct _XrmHashBucketRec* ,
	char* ,
	char* ,
	XIDProc ,
	XPointer
);
int XUnregisterIMInstantiateCallback(
	Display* ,
	struct _XrmHashBucketRec* ,
	char* ,
	char* ,
	XIDProc ,
	XPointer
);
typedef void (*XConnectionWatchProc)(
	Display* ,
	XPointer ,
	int ,
	int ,
	XPointer*
);
int XInternalConnectionNumbers(
	Display* ,
	int** ,
	int*
);
void XProcessInternalConnection(
	Display* ,
	int
);
int XAddConnectionWatch(
	Display* ,
	XConnectionWatchProc ,
	XPointer
);
void XRemoveConnectionWatch(
	Display* ,
	XConnectionWatchProc ,
	XPointer
);
void XSetAuthorization(
	char * ,
	int ,
	char * ,
	int
);
int _Xmbtowc(
	wchar_t * ,
	char * ,
	int
);
int _Xwctomb(
	char * ,
	wchar_t
);
int XGetEventData(
	Display* ,
	XGenericEventCookie*
);
void XFreeEventData(
	Display* ,
	XGenericEventCookie*
);

// X11/Xutil.h
enum {
	NoValue              = 0x0000,
	XValue               = 0x0001,
	YValue               = 0x0002,
	WidthValue           = 0x0004,
	HeightValue          = 0x0008,
	AllValues            = 0x000F,
	XNegative            = 0x0010,
	YNegative            = 0x0020,
};
typedef struct {
	long flags;
	int x, y;
	int width, height;
	int min_width, min_height;
	int max_width, max_height;
	int width_inc, height_inc;
	struct {
		int x;
		int y;
	} min_aspect, max_aspect;
	int base_width, base_height;
	int win_gravity;
} XSizeHints;
enum {
	USPosition           = (1 << 0),
	USSize               = (1 << 1),
	PPosition            = (1 << 2),
	PSize                = (1 << 3),
	PMinSize             = (1 << 4),
	PMaxSize             = (1 << 5),
	PResizeInc           = (1 << 6),
	PAspect              = (1 << 7),
	PBaseSize            = (1 << 8),
	PWinGravity          = (1 << 9),
	PAllHints            = (PPosition|PSize|PMinSize|PMaxSize|PResizeInc|PAspect),
};
typedef struct {
	long flags;
	int input;
	int initial_state;
	Pixmap icon_pixmap;
	Window icon_window;
	int icon_x, icon_y;
	Pixmap icon_mask;
	XID window_group;
} XWMHints;
enum {
	InputHint            = (1 << 0),
	StateHint            = (1 << 1),
	IconPixmapHint       = (1 << 2),
	IconWindowHint       = (1 << 3),
	IconPositionHint     = (1 << 4),
	IconMaskHint         = (1 << 5),
	WindowGroupHint      = (1 << 6),
	AllHints             = (InputHint|StateHint|IconPixmapHint|IconWindowHint|IconPositionHint|IconMaskHint|WindowGroupHint),
	XUrgencyHint         = (1 << 8),
	WithdrawnState       = 0,
	NormalState          = 1,
	IconicState          = 3,
	DontCareState        = 0,
	ZoomState            = 2,
	InactiveState        = 4,
};
typedef struct {
	unsigned char *value;
	Atom encoding;
	int format;
	unsigned long nitems;
} XTextProperty;
enum {
	XNoMemory            = -1,
	XLocaleNotSupported  = -2,
	XConverterNotFound   = -3,
};
typedef enum {
	XStringStyle,
	XCompoundTextStyle,
	XTextStyle,
	XStdICCTextStyle,
	XUTF8StringStyle
} XICCEncodingStyle;
typedef struct {
	int min_width, min_height;
	int max_width, max_height;
	int width_inc, height_inc;
} XIconSize;
typedef struct {
	char *res_name;
	char *res_class;
} XClassHint;
typedef struct _XComposeStatus {
	XPointer compose_ptr;
	int chars_matched;
} XComposeStatus;
typedef struct _XRegion *Region;
enum {
	RectangleOut         = 0,
	RectangleIn          = 1,
	RectanglePart        = 2,
};
typedef struct {
	Visual *visual;
	VisualID visualid;
	int screen;
	int depth;
	int class;
	unsigned long red_mask;
	unsigned long green_mask;
	unsigned long blue_mask;
	int colormap_size;
	int bits_per_rgb;
} XVisualInfo;
enum {
	VisualNoMask         = 0x0,
	VisualIDMask         = 0x1,
	VisualScreenMask     = 0x2,
	VisualDepthMask      = 0x4,
	VisualClassMask      = 0x8,
	VisualRedMaskMask    = 0x10,
	VisualGreenMaskMask  = 0x20,
	VisualBlueMaskMask   = 0x40,
	VisualColormapSizeMask = 0x80,
	VisualBitsPerRGBMask = 0x100,
	VisualAllMask        = 0x1FF,
};
typedef struct {
 Colormap colormap;
 unsigned long red_max;
 unsigned long red_mult;
 unsigned long green_max;
 unsigned long green_mult;
 unsigned long blue_max;
 unsigned long blue_mult;
 unsigned long base_pixel;
 VisualID visualid;
 XID killid;
} XStandardColormap;
enum {
	ReleaseByFreeingColormap = ((XID) 1),
	BitmapSuccess        = 0,
	BitmapOpenFailed     = 1,
	BitmapFileInvalid    = 2,
	BitmapNoMemory       = 3,
	XCSUCCESS            = 0,
	XCNOMEM              = 1,
	XCNOENT              = 2,
};
typedef int XContext;
XClassHint *XAllocClassHint (
	void
);
XIconSize *XAllocIconSize (
	void
);
XSizeHints *XAllocSizeHints (
	void
);
XStandardColormap *XAllocStandardColormap (
	void
);
XWMHints *XAllocWMHints (
	void
);
int XClipBox(
	Region ,
	XRectangle*
);
Region XCreateRegion(
	void
);
const char *XDefaultString (void);
int XDeleteContext(
	Display* ,
	XID ,
	XContext
);
int XDestroyRegion(
	Region
);
int XEmptyRegion(
	Region
);
int XEqualRegion(
	Region ,
	Region
);
int XFindContext(
	Display* ,
	XID ,
	XContext ,
	XPointer*
);
int XGetClassHint(
	Display* ,
	Window ,
	XClassHint*
);
int XGetIconSizes(
	Display* ,
	Window ,
	XIconSize** ,
	int*
);
int XGetNormalHints(
	Display* ,
	Window ,
	XSizeHints*
);
int XGetRGBColormaps(
	Display* ,
	Window ,
	XStandardColormap** ,
	int* ,
	Atom
);
int XGetSizeHints(
	Display* ,
	Window ,
	XSizeHints* ,
	Atom
);
int XGetStandardColormap(
	Display* ,
	Window ,
	XStandardColormap* ,
	Atom
);
int XGetTextProperty(
	Display* ,
	Window ,
	XTextProperty* ,
	Atom
);
XVisualInfo *XGetVisualInfo(
	Display* ,
	long ,
	XVisualInfo* ,
	int*
);
int XGetWMClientMachine(
	Display* ,
	Window ,
	XTextProperty*
);
XWMHints *XGetWMHints(
	Display* ,
	Window
);
int XGetWMIconName(
	Display* ,
	Window ,
	XTextProperty*
);
int XGetWMName(
	Display* ,
	Window ,
	XTextProperty*
);
int XGetWMNormalHints(
	Display* ,
	Window ,
	XSizeHints* ,
	long*
);
int XGetWMSizeHints(
	Display* ,
	Window ,
	XSizeHints* ,
	long* ,
	Atom
);
int XGetZoomHints(
	Display* ,
	Window ,
	XSizeHints*
);
int XIntersectRegion(
	Region ,
	Region ,
	Region
);
void XConvertCase(
	KeySym ,
	KeySym* ,
	KeySym*
);
int XLookupString(
	XKeyEvent* ,
	char* ,
	int ,
	KeySym* ,
	XComposeStatus*
);
int XMatchVisualInfo(
	Display* ,
	int ,
	int ,
	int ,
	XVisualInfo*
);
int XOffsetRegion(
	Region ,
	int ,
	int
);
int XPointInRegion(
	Region ,
	int ,
	int
);
Region XPolygonRegion(
	XPoint* ,
	int ,
	int
);
int XRectInRegion(
	Region ,
	int ,
	int ,
	unsigned int ,
	unsigned int
);
int XSaveContext(
	Display* ,
	XID ,
	XContext ,
	const char*
);
int XSetClassHint(
	Display* ,
	Window ,
	XClassHint*
);
int XSetIconSizes(
	Display* ,
	Window ,
	XIconSize* ,
	int
);
int XSetNormalHints(
	Display* ,
	Window ,
	XSizeHints*
);
void XSetRGBColormaps(
	Display* ,
	Window ,
	XStandardColormap* ,
	int ,
	Atom
);
int XSetSizeHints(
	Display* ,
	Window ,
	XSizeHints* ,
	Atom
);
int XSetStandardProperties(
	Display* ,
	Window ,
	const char* ,
	const char* ,
	Pixmap ,
	char** ,
	int ,
	XSizeHints*
);
void XSetTextProperty(
	Display* ,
	Window ,
	XTextProperty* ,
	Atom
);
void XSetWMClientMachine(
	Display* ,
	Window ,
	XTextProperty*
);
int XSetWMHints(
	Display* ,
	Window ,
	XWMHints*
);
void XSetWMIconName(
	Display* ,
	Window ,
	XTextProperty*
);
void XSetWMName(
	Display* ,
	Window ,
	XTextProperty*
);
void XSetWMNormalHints(
	Display* ,
	Window ,
	XSizeHints*
);
void XSetWMProperties(
	Display* ,
	Window ,
	XTextProperty* ,
	XTextProperty* ,
	char** ,
	int ,
	XSizeHints* ,
	XWMHints* ,
	XClassHint*
);
void XmbSetWMProperties(
	Display* ,
	Window ,
	const char* ,
	const char* ,
	char** ,
	int ,
	XSizeHints* ,
	XWMHints* ,
	XClassHint*
);
void Xutf8SetWMProperties(
	Display* ,
	Window ,
	const char* ,
	const char* ,
	char** ,
	int ,
	XSizeHints* ,
	XWMHints* ,
	XClassHint*
);
void XSetWMSizeHints(
	Display* ,
	Window ,
	XSizeHints* ,
	Atom
);
int XSetRegion(
	Display* ,
	GC ,
	Region
);
void XSetStandardColormap(
	Display* ,
	Window ,
	XStandardColormap* ,
	Atom
);
int XSetZoomHints(
	Display* ,
	Window ,
	XSizeHints*
);
int XShrinkRegion(
	Region ,
	int ,
	int
);
int XStringListToTextProperty(
	char** ,
	int ,
	XTextProperty*
);
int XSubtractRegion(
	Region ,
	Region ,
	Region
);
int XmbTextListToTextProperty(
	Display* display,
	char** list,
	int count,
	XICCEncodingStyle style,
	XTextProperty* text_prop_return
);
int XwcTextListToTextProperty(
	Display* display,
	wchar_t** list,
	int count,
	XICCEncodingStyle style,
	XTextProperty* text_prop_return
);
int Xutf8TextListToTextProperty(
	Display* display,
	char** list,
	int count,
	XICCEncodingStyle style,
	XTextProperty* text_prop_return
);
void XwcFreeStringList(
	wchar_t** list
);
int XTextPropertyToStringList(
	XTextProperty* ,
	char*** ,
	int*
);
int XmbTextPropertyToTextList(
	Display* display,
	const XTextProperty* text_prop,
	char*** list_return,
	int* count_return
);
int XwcTextPropertyToTextList(
	Display* display,
	const XTextProperty* text_prop,
	wchar_t*** list_return,
	int* count_return
);
int Xutf8TextPropertyToTextList(
	Display* display,
	const XTextProperty* text_prop,
	char*** list_return,
	int* count_return
);
int XUnionRectWithRegion(
	XRectangle* ,
	Region ,
	Region
);
int XUnionRegion(
	Region ,
	Region ,
	Region
);
int XWMGeometry(
	Display* ,
	int ,
	const char* ,
	const char* ,
	unsigned int ,
	XSizeHints* ,
	int* ,
	int* ,
	int* ,
	int* ,
	int*
);
int XXorRegion(
	Region ,
	Region ,
	Region
);

// X11/Xatom.h
enum {
	XATOM_H              = 1,
	XA_PRIMARY           = 1,
	XA_SECONDARY         = 2,
	XA_ARC               = 3,
	XA_ATOM              = 4,
	XA_BITMAP            = 5,
	XA_CARDINAL          = 6,
	XA_COLORMAP          = 7,
	XA_CURSOR            = 8,
	XA_CUT_BUFFER0       = 9,
	XA_CUT_BUFFER1       = 10,
	XA_CUT_BUFFER2       = 11,
	XA_CUT_BUFFER3       = 12,
	XA_CUT_BUFFER4       = 13,
	XA_CUT_BUFFER5       = 14,
	XA_CUT_BUFFER6       = 15,
	XA_CUT_BUFFER7       = 16,
	XA_DRAWABLE          = 17,
	XA_FONT              = 18,
	XA_INTEGER           = 19,
	XA_PIXMAP            = 20,
	XA_POINT             = 21,
	XA_RECTANGLE         = 22,
	XA_RESOURCE_MANAGER  = 23,
	XA_RGB_COLOR_MAP     = 24,
	XA_RGB_BEST_MAP      = 25,
	XA_RGB_BLUE_MAP      = 26,
	XA_RGB_DEFAULT_MAP   = 27,
	XA_RGB_GRAY_MAP      = 28,
	XA_RGB_GREEN_MAP     = 29,
	XA_RGB_RED_MAP       = 30,
	XA_STRING            = 31,
	XA_VISUALID          = 32,
	XA_WINDOW            = 33,
	XA_WM_COMMAND        = 34,
	XA_WM_HINTS          = 35,
	XA_WM_CLIENT_MACHINE = 36,
	XA_WM_ICON_NAME      = 37,
	XA_WM_ICON_SIZE      = 38,
	XA_WM_NAME           = 39,
	XA_WM_NORMAL_HINTS   = 40,
	XA_WM_SIZE_HINTS     = 41,
	XA_WM_ZOOM_HINTS     = 42,
	XA_MIN_SPACE         = 43,
	XA_NORM_SPACE        = 44,
	XA_MAX_SPACE         = 45,
	XA_END_SPACE         = 46,
	XA_SUPERSCRIPT_X     = 47,
	XA_SUPERSCRIPT_Y     = 48,
	XA_SUBSCRIPT_X       = 49,
	XA_SUBSCRIPT_Y       = 50,
	XA_UNDERLINE_POSITION = 51,
	XA_UNDERLINE_THICKNESS = 52,
	XA_STRIKEOUT_ASCENT  = 53,
	XA_STRIKEOUT_DESCENT = 54,
	XA_ITALIC_ANGLE      = 55,
	XA_X_HEIGHT          = 56,
	XA_QUAD_WIDTH        = 57,
	XA_WEIGHT            = 58,
	XA_POINT_SIZE        = 59,
	XA_RESOLUTION        = 60,
	XA_COPYRIGHT         = 61,
	XA_NOTICE            = 62,
	XA_FONT_NAME         = 63,
	XA_FAMILY_NAME       = 64,
	XA_FULL_NAME         = 65,
	XA_CAP_HEIGHT        = 66,
	XA_WM_CLASS          = 67,
	XA_WM_TRANSIENT_FOR  = 68,
	XA_LAST_PREDEFINED   = 68,
};

// Xm/MwmUtil.h
// _MOTIF_WM_HINTS property layout.
// 32-bit property items are stored as long on the client. XChangeProperty
// handles the conversion to the actual 32-bit quantities sent to the server.
typedef struct {
	unsigned long flags, functions, decorations;
	long input_mode;
	unsigned long status;
} PropMotifWmHints;
enum {
	/* number of elements of size 32 in _MOTIF_WM_HINTS */
	MOTIF_WM_HINTS_ELEMENTS = 5,
	/* bit definitions for MwmHints.flags */
	MWM_HINTS_FUNCTIONS     = (1 << 0),
	MWM_HINTS_DECORATIONS   = (1 << 1),
	MWM_HINTS_INPUT_MODE    = (1 << 2),
	MWM_HINTS_STATUS        = (1 << 3),
	/* bit definitions for MwmHints.functions */
	MWM_FUNC_ALL            = (1 << 0),
	MWM_FUNC_RESIZE         = (1 << 1),
	MWM_FUNC_MOVE           = (1 << 2),
	MWM_FUNC_MINIMIZE       = (1 << 3),
	MWM_FUNC_MAXIMIZE       = (1 << 4),
	MWM_FUNC_CLOSE          = (1 << 5),
	/* bit definitions for MwmHints.decorations */
	MWM_DECOR_ALL           = (1 << 0),
	MWM_DECOR_BORDER        = (1 << 1),
	MWM_DECOR_RESIZEH       = (1 << 2),
	MWM_DECOR_TITLE         = (1 << 3),
	MWM_DECOR_MENU          = (1 << 4),
	MWM_DECOR_MINIMIZE      = (1 << 5),
	MWM_DECOR_MAXIMIZE      = (1 << 6),
	/* values for MwmHints.input_mode */
	MWM_INPUT_MODELESS                  = 0,
	MWM_INPUT_PRIMARY_APPLICATION_MODAL = 1,
	MWM_INPUT_SYSTEM_MODAL              = 2,
	MWM_INPUT_FULL_APPLICATION_MODAL    = 3,
	MWM_INPUT_APPLICATION_MODAL         = 1,
	/* bit definitions for MwmHints.status */
	MWM_TEAROFF_WINDOW      = (1 << 0),
};

// X11/extensions/Xinerama.h
typedef struct {
	int screen_number;
	short x_org;
	short y_org;
	short width;
	short height;
} XineramaScreenInfo;
int XineramaQueryExtension (
	Display *dpy,
	int *event_base,
	int *error_base
);
int XineramaQueryVersion(
	Display *dpy,
	int *major_versionp,
	int *minor_versionp
);
int XineramaIsActive(Display *dpy);
XineramaScreenInfo *
XineramaQueryScreens(
	Display *dpy,
	int *number
);

// X11/extensions/XShm.h
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

local X = {} --macro namespace

--macros from X11/Xutil.h

function X.XAllocID(dpy) return dpy.resource_alloc(dpy) end
function X.XDestroyImage(ximage) return ximage.f.destroy_image(ximage) end
function X.XGetPixel(ximage,x,y) return ximage.f.get_pixel(ximage, x, y) end
function X.XPutPixel(ximage,x,y,pixel) return ximage.f.put_pixel(ximage, x, y, pixel) end
function X.XSubImage(ximage,x,y,width,height) return ximage.f.sub_image(ximage, x, y, width, height) end
function X.XAddPixel(ximage,value) return ximage.f.add_pixel(ximage, value) end

return X
