
-- X11/XKBlib.h, X11/extensions/XKB.h, X11/extensions/XKBstr.h

local ffi = require'ffi'
local X = require'xlib_h'

ffi.cdef[[

// /usr/include/X11/extensions/XKB.h
enum {
	X_kbUseExtension     = 0,
	X_kbSelectEvents     = 1,
	X_kbBell             = 3,
	X_kbGetState         = 4,
	X_kbLatchLockState   = 5,
	X_kbGetControls      = 6,
	X_kbSetControls      = 7,
	X_kbGetMap           = 8,
	X_kbSetMap           = 9,
	X_kbGetCompatMap     = 10,
	X_kbSetCompatMap     = 11,
	X_kbGetIndicatorState = 12,
	X_kbGetIndicatorMap  = 13,
	X_kbSetIndicatorMap  = 14,
	X_kbGetNamedIndicator = 15,
	X_kbSetNamedIndicator = 16,
	X_kbGetNames         = 17,
	X_kbSetNames         = 18,
	X_kbGetGeometry      = 19,
	X_kbSetGeometry      = 20,
	X_kbPerClientFlags   = 21,
	X_kbListComponents   = 22,
	X_kbGetKbdByName     = 23,
	X_kbGetDeviceInfo    = 24,
	X_kbSetDeviceInfo    = 25,
	X_kbSetDebuggingFlags = 101,
	XkbEventCode         = 0,
	XkbNumberEvents      = (XkbEventCode+1),
	XkbNewKeyboardNotify = 0,
	XkbMapNotify         = 1,
	XkbStateNotify       = 2,
	XkbControlsNotify    = 3,
	XkbIndicatorStateNotify = 4,
	XkbIndicatorMapNotify = 5,
	XkbNamesNotify       = 6,
	XkbCompatMapNotify   = 7,
	XkbBellNotify        = 8,
	XkbActionMessage     = 9,
	XkbAccessXNotify     = 10,
	XkbExtensionDeviceNotify = 11,
	XkbNewKeyboardNotifyMask = (1 << 0),
	XkbMapNotifyMask     = (1 << 1),
	XkbStateNotifyMask   = (1 << 2),
	XkbControlsNotifyMask = (1 << 3),
	XkbIndicatorStateNotifyMask = (1 << 4),
	XkbIndicatorMapNotifyMask = (1 << 5),
	XkbNamesNotifyMask   = (1 << 6),
	XkbCompatMapNotifyMask = (1 << 7),
	XkbBellNotifyMask    = (1 << 8),
	XkbActionMessageMask = (1 << 9),
	XkbAccessXNotifyMask = (1 << 10),
	XkbExtensionDeviceNotifyMask = (1 << 11),
	XkbAllEventsMask     = (0xFFF),
	XkbNKN_KeycodesMask  = (1 << 0),
	XkbNKN_GeometryMask  = (1 << 1),
	XkbNKN_DeviceIDMask  = (1 << 2),
	XkbAllNewKeyboardEventsMask = (0x7),
	XkbAXN_SKPress       = 0,
	XkbAXN_SKAccept      = 1,
	XkbAXN_SKReject      = 2,
	XkbAXN_SKRelease     = 3,
	XkbAXN_BKAccept      = 4,
	XkbAXN_BKReject      = 5,
	XkbAXN_AXKWarning    = 6,
	XkbAXN_SKPressMask   = (1 << 0),
	XkbAXN_SKAcceptMask  = (1 << 1),
	XkbAXN_SKRejectMask  = (1 << 2),
	XkbAXN_SKReleaseMask = (1 << 3),
	XkbAXN_BKAcceptMask  = (1 << 4),
	XkbAXN_BKRejectMask  = (1 << 5),
	XkbAXN_AXKWarningMask = (1 << 6),
	XkbAllAccessXEventsMask = (0xf),
	XkbAllBellEventsMask = (1 << 0),
	XkbAllActionMessagesMask = (1 << 0),
	XkbKeyboard          = 0,
	XkbNumberErrors      = 1,
	XkbErr_BadDevice     = 0xff,
	XkbErr_BadClass      = 0xfe,
	XkbErr_BadId         = 0xfd,
	XkbClientMapMask     = (1 << 0),
	XkbServerMapMask     = (1 << 1),
	XkbCompatMapMask     = (1 << 2),
	XkbIndicatorMapMask  = (1 << 3),
	XkbNamesMask         = (1 << 4),
	XkbGeometryMask      = (1 << 5),
	XkbControlsMask      = (1 << 6),
	XkbAllComponentsMask = (0x7f),
	XkbModifierStateMask = (1 << 0),
	XkbModifierBaseMask  = (1 << 1),
	XkbModifierLatchMask = (1 << 2),
	XkbModifierLockMask  = (1 << 3),
	XkbGroupStateMask    = (1 << 4),
	XkbGroupBaseMask     = (1 << 5),
	XkbGroupLatchMask    = (1 << 6),
	XkbGroupLockMask     = (1 << 7),
	XkbCompatStateMask   = (1 << 8),
	XkbGrabModsMask      = (1 << 9),
	XkbCompatGrabModsMask = (1 << 10),
	XkbLookupModsMask    = (1 << 11),
	XkbCompatLookupModsMask = (1 << 12),
	XkbPointerButtonMask = (1 << 13),
	XkbAllStateComponentsMask = (0x3fff),
	XkbRepeatKeysMask    = (1 << 0),
	XkbSlowKeysMask      = (1 << 1),
	XkbBounceKeysMask    = (1 << 2),
	XkbStickyKeysMask    = (1 << 3),
	XkbMouseKeysMask     = (1 << 4),
	XkbMouseKeysAccelMask = (1 << 5),
	XkbAccessXKeysMask   = (1 << 6),
	XkbAccessXTimeoutMask = (1 << 7),
	XkbAccessXFeedbackMask = (1 << 8),
	XkbAudibleBellMask   = (1 << 9),
	XkbOverlay1Mask      = (1 << 10),
	XkbOverlay2Mask      = (1 << 11),
	XkbIgnoreGroupLockMask = (1 << 12),
	XkbGroupsWrapMask    = (1 << 27),
	XkbInternalModsMask  = (1 << 28),
	XkbIgnoreLockModsMask = (1 << 29),
	XkbPerKeyRepeatMask  = (1 << 30),
	XkbControlsEnabledMask = (1 << 31),
	XkbAccessXOptionsMask = (XkbStickyKeysMask|XkbAccessXFeedbackMask),
	XkbAllBooleanCtrlsMask = (0x00001FFF),
	XkbAllControlsMask   = (0xF8001FFF),
	XkbAX_SKPressFBMask  = (1 << 0),
	XkbAX_SKAcceptFBMask = (1 << 1),
	XkbAX_FeatureFBMask  = (1 << 2),
	XkbAX_SlowWarnFBMask = (1 << 3),
	XkbAX_IndicatorFBMask = (1 << 4),
	XkbAX_StickyKeysFBMask = (1 << 5),
	XkbAX_TwoKeysMask    = (1 << 6),
	XkbAX_LatchToLockMask = (1 << 7),
	XkbAX_SKReleaseFBMask = (1 << 8),
	XkbAX_SKRejectFBMask = (1 << 9),
	XkbAX_BKRejectFBMask = (1 << 10),
	XkbAX_DumbBellFBMask = (1 << 11),
	XkbAX_FBOptionsMask  = (0xF3F),
	XkbAX_SKOptionsMask  = (0x0C0),
	XkbAX_AllOptionsMask = (0xFFF),
	XkbUseCoreKbd        = 0x0100,
	XkbUseCorePtr        = 0x0200,
	XkbDfltXIClass       = 0x0300,
	XkbDfltXIId          = 0x0400,
	XkbAllXIClasses      = 0x0500,
	XkbAllXIIds          = 0x0600,
	XkbXINone            = 0xff00,
	XkbNoModifier        = 0xff,
	XkbNoShiftLevel      = 0xff,
	XkbNoShape           = 0xff,
	XkbNoIndicator       = 0xff,
	XkbNoModifierMask    = 0,
	XkbAllModifiersMask  = 0xff,
	XkbAllVirtualModsMask = 0xffff,
	XkbNumKbdGroups      = 4,
	XkbMaxKbdGroup       = (XkbNumKbdGroups-1),
	XkbMaxMouseKeysBtn   = 4,
	XkbGroup1Index       = 0,
	XkbGroup2Index       = 1,
	XkbGroup3Index       = 2,
	XkbGroup4Index       = 3,
	XkbAnyGroup          = 254,
	XkbAllGroups         = 255,
	XkbGroup1Mask        = (1<<0),
	XkbGroup2Mask        = (1<<1),
	XkbGroup3Mask        = (1<<2),
	XkbGroup4Mask        = (1<<3),
	XkbAnyGroupMask      = (1<<7),
	XkbAllGroupsMask     = (0xf),
	XkbWrapIntoRange     = (0x00),
	XkbClampIntoRange    = (0x40),
	XkbRedirectIntoRange = (0x80),
	XkbSA_ClearLocks     = (1 << 0),
	XkbSA_LatchToLock    = (1 << 1),
	XkbSA_LockNoLock     = (1 << 0),
	XkbSA_LockNoUnlock   = (1 << 1),
	XkbSA_UseModMapMods  = (1 << 2),
	XkbSA_GroupAbsolute  = (1 << 2),
	XkbSA_UseDfltButton  = 0,
	XkbSA_NoAcceleration = (1 << 0),
	XkbSA_MoveAbsoluteX  = (1 << 1),
	XkbSA_MoveAbsoluteY  = (1 << 2),
	XkbSA_ISODfltIsGroup = (1 << 7),
	XkbSA_ISONoAffectMods = (1 << 6),
	XkbSA_ISONoAffectGroup = (1 << 5),
	XkbSA_ISONoAffectPtr = (1 << 4),
	XkbSA_ISONoAffectCtrls = (1 << 3),
	XkbSA_ISOAffectMask  = (0x78),
	XkbSA_MessageOnPress = (1 << 0),
	XkbSA_MessageOnRelease = (1 << 1),
	XkbSA_MessageGenKeyEvent = (1 << 2),
	XkbSA_AffectDfltBtn  = 1,
	XkbSA_DfltBtnAbsolute = (1 << 2),
	XkbSA_SwitchApplication = (1 << 0),
	XkbSA_SwitchAbsolute = (1 << 2),
	XkbSA_IgnoreVal      = (0x00),
	XkbSA_SetValMin      = (0x10),
	XkbSA_SetValCenter   = (0x20),
	XkbSA_SetValMax      = (0x30),
	XkbSA_SetValRelative = (0x40),
	XkbSA_SetValAbsolute = (0x50),
	XkbSA_ValOpMask      = (0x70),
	XkbSA_ValScaleMask   = (0x07),
	XkbSA_NoAction       = 0x00,
	XkbSA_SetMods        = 0x01,
	XkbSA_LatchMods      = 0x02,
	XkbSA_LockMods       = 0x03,
	XkbSA_SetGroup       = 0x04,
	XkbSA_LatchGroup     = 0x05,
	XkbSA_LockGroup      = 0x06,
	XkbSA_MovePtr        = 0x07,
	XkbSA_PtrBtn         = 0x08,
	XkbSA_LockPtrBtn     = 0x09,
	XkbSA_SetPtrDflt     = 0x0a,
	XkbSA_ISOLock        = 0x0b,
	XkbSA_Terminate      = 0x0c,
	XkbSA_SwitchScreen   = 0x0d,
	XkbSA_SetControls    = 0x0e,
	XkbSA_LockControls   = 0x0f,
	XkbSA_ActionMessage  = 0x10,
	XkbSA_RedirectKey    = 0x11,
	XkbSA_DeviceBtn      = 0x12,
	XkbSA_LockDeviceBtn  = 0x13,
	XkbSA_DeviceValuator = 0x14,
	XkbSA_LastAction     = XkbSA_DeviceValuator,
	XkbSA_NumActions     = (XkbSA_LastAction+1),
	XkbSA_XFree86Private = 0x86,
	XkbSA_BreakLatch     = ((1<<XkbSA_NoAction)|(1<<XkbSA_PtrBtn)|(1<<XkbSA_LockPtrBtn)| (1<<XkbSA_Terminate)|(1<<XkbSA_SwitchScreen)|(1<<XkbSA_SetControls)| (1<<XkbSA_LockControls)|(1<<XkbSA_ActionMessage)| (1<<XkbSA_RedirectKey)|(1<<XkbSA_DeviceBtn)|(1<<XkbSA_LockDeviceBtn)),
	XkbKB_Permanent      = 0x80,
	XkbKB_OpMask         = 0x7f,
	XkbKB_Default        = 0x00,
	XkbKB_Lock           = 0x01,
	XkbKB_RadioGroup     = 0x02,
	XkbKB_Overlay1       = 0x03,
	XkbKB_Overlay2       = 0x04,
	XkbKB_RGAllowNone    = 0x80,
	XkbMinLegalKeyCode   = 8,
	XkbMaxLegalKeyCode   = 255,
	XkbMaxKeyCount       = (XkbMaxLegalKeyCode-XkbMinLegalKeyCode+1),
	XkbPerKeyBitArraySize = ((XkbMaxLegalKeyCode+1)/8),
	XkbNumModifiers      = 8,
	XkbNumVirtualMods    = 16,
	XkbNumIndicators     = 32,
	XkbAllIndicatorsMask = (0xffffffff),
	XkbMaxRadioGroups    = 32,
	XkbAllRadioGroupsMask = (0xffffffff),
	XkbMaxShiftLevel     = 63,
	XkbMaxSymsPerKey     = (XkbMaxShiftLevel*XkbNumKbdGroups),
	XkbRGMaxMembers      = 12,
	XkbActionMessageLength = 6,
	XkbKeyNameLength     = 4,
	XkbMaxRedirectCount  = 8,
	XkbGeomPtsPerMM      = 10,
	XkbGeomMaxColors     = 32,
	XkbGeomMaxLabelColors = 3,
	XkbGeomMaxPriority   = 255,
	XkbOneLevelIndex     = 0,
	XkbTwoLevelIndex     = 1,
	XkbAlphabeticIndex   = 2,
	XkbKeypadIndex       = 3,
	XkbLastRequiredType  = XkbKeypadIndex,
	XkbNumRequiredTypes  = (XkbLastRequiredType+1),
	XkbMaxKeyTypes       = 255,
	XkbOneLevelMask      = (1<<0),
	XkbTwoLevelMask      = (1<<1),
	XkbAlphabeticMask    = (1<<2),
	XkbKeypadMask        = (1<<3),
	XkbAllRequiredTypes  = (0xf),
	XkbMajorVersion      = 1,
	XkbMinorVersion      = 0,
	XkbExplicitKeyTypesMask = (0x0f),
	XkbExplicitKeyType1Mask = (1<<0),
	XkbExplicitKeyType2Mask = (1<<1),
	XkbExplicitKeyType3Mask = (1<<2),
	XkbExplicitKeyType4Mask = (1<<3),
	XkbExplicitInterpretMask = (1<<4),
	XkbExplicitAutoRepeatMask = (1<<5),
	XkbExplicitBehaviorMask = (1<<6),
	XkbExplicitVModMapMask = (1<<7),
	XkbAllExplicitMask   = (0xff),
	XkbKeyTypesMask      = (1<<0),
	XkbKeySymsMask       = (1<<1),
	XkbModifierMapMask   = (1<<2),
	XkbExplicitComponentsMask = (1<<3),
	XkbKeyActionsMask    = (1<<4),
	XkbKeyBehaviorsMask  = (1<<5),
	XkbVirtualModsMask   = (1<<6),
	XkbVirtualModMapMask = (1<<7),
	XkbAllClientInfoMask = (XkbKeyTypesMask|XkbKeySymsMask|XkbModifierMapMask),
	XkbAllServerInfoMask = (XkbExplicitComponentsMask|XkbKeyActionsMask|XkbKeyBehaviorsMask|XkbVirtualModsMask|XkbVirtualModMapMask),
	XkbAllMapComponentsMask = (XkbAllClientInfoMask|XkbAllServerInfoMask),
	XkbSI_AutoRepeat     = (1<<0),
	XkbSI_LockingKey     = (1<<1),
	XkbSI_LevelOneOnly   = (0x80),
	XkbSI_OpMask         = (0x7f),
	XkbSI_NoneOf         = (0),
	XkbSI_AnyOfOrNone    = (1),
	XkbSI_AnyOf          = (2),
	XkbSI_AllOf          = (3),
	XkbSI_Exactly        = (4),
	XkbIM_NoExplicit     = (1 << 7),
	XkbIM_NoAutomatic    = (1 << 6),
	XkbIM_LEDDrivesKB    = (1 << 5),
	XkbIM_UseBase        = (1 << 0),
	XkbIM_UseLatched     = (1 << 1),
	XkbIM_UseLocked      = (1 << 2),
	XkbIM_UseEffective   = (1 << 3),
	XkbIM_UseCompat      = (1 << 4),
	XkbIM_UseNone        = 0,
	XkbIM_UseAnyGroup    = (XkbIM_UseBase|XkbIM_UseLatched|XkbIM_UseLocked |XkbIM_UseEffective),
	XkbIM_UseAnyMods     = (XkbIM_UseAnyGroup|XkbIM_UseCompat),
	XkbSymInterpMask     = (1<<0),
	XkbGroupCompatMask   = (1<<1),
	XkbAllCompatMask     = (0x3),
	XkbKeycodesNameMask  = (1<<0),
	XkbGeometryNameMask  = (1<<1),
	XkbSymbolsNameMask   = (1<<2),
	XkbPhysSymbolsNameMask = (1<<3),
	XkbTypesNameMask     = (1<<4),
	XkbCompatNameMask    = (1<<5),
	XkbKeyTypeNamesMask  = (1<<6),
	XkbKTLevelNamesMask  = (1<<7),
	XkbIndicatorNamesMask = (1<<8),
	XkbKeyNamesMask      = (1<<9),
	XkbKeyAliasesMask    = (1<<10),
	XkbVirtualModNamesMask = (1<<11),
	XkbGroupNamesMask    = (1<<12),
	XkbRGNamesMask       = (1<<13),
	XkbComponentNamesMask = (0x3f),
	XkbAllNamesMask      = (0x3fff),
	XkbGBN_TypesMask     = (1 << 0),
	XkbGBN_CompatMapMask = (1 << 1),
	XkbGBN_ClientSymbolsMask = (1 << 2),
	XkbGBN_ServerSymbolsMask = (1 << 3),
	XkbGBN_SymbolsMask   = (XkbGBN_ClientSymbolsMask|XkbGBN_ServerSymbolsMask),
	XkbGBN_IndicatorMapMask = (1 << 4),
	XkbGBN_KeyNamesMask  = (1 << 5),
	XkbGBN_GeometryMask  = (1 << 6),
	XkbGBN_OtherNamesMask = (1 << 7),
	XkbGBN_AllComponentsMask = (0xff),
	XkbLC_Hidden         = (1 << 0),
	XkbLC_Default        = (1 << 1),
	XkbLC_Partial        = (1 << 2),
	XkbLC_AlphanumericKeys = (1 << 8),
	XkbLC_ModifierKeys   = (1 << 9),
	XkbLC_KeypadKeys     = (1 << 10),
	XkbLC_FunctionKeys   = (1 << 11),
	XkbLC_AlternateGroup = (1 << 12),
	XkbXI_KeyboardsMask  = (1 << 0),
	XkbXI_ButtonActionsMask = (1 << 1),
	XkbXI_IndicatorNamesMask = (1 << 2),
	XkbXI_IndicatorMapsMask = (1 << 3),
	XkbXI_IndicatorStateMask = (1 << 4),
	XkbXI_UnsupportedFeatureMask = (1 << 15),
	XkbXI_AllFeaturesMask = (0x001f),
	XkbXI_AllDeviceFeaturesMask = (0x001e),
	XkbXI_IndicatorsMask = (0x001c),
	XkbAllExtensionDeviceEventsMask = (0x801f),
	XkbPCF_DetectableAutoRepeatMask = (1 << 0),
	XkbPCF_GrabsUseXKBStateMask = (1 << 1),
	XkbPCF_AutoResetControlsMask = (1 << 2),
	XkbPCF_LookupStateWhenGrabbed = (1 << 3),
	XkbPCF_SendEventUsesXKBState = (1 << 4),
	XkbPCF_AllFlagsMask  = (0x1F),
	XkbDF_DisableLocks   = (1<<0),
	XkbAllControlEventsMask = XkbAllControlsMask,
	XkbAllStateEventsMask = XkbAllStateComponentsMask,
	XkbAllMapEventsMask  = XkbAllMapComponentsMask,
	XkbAllIndicatorEventsMask = XkbAllIndicatorsMask,
	XkbAllNameEventsMask = XkbAllNamesMask,
	XkbAllCompatMapEventsMask = XkbAllCompatMask,
};

// /usr/include/X11/extensions/XKBstr.h
typedef struct _XkbStateRec {
	unsigned char group;
	unsigned char locked_group;
	unsigned short base_group;
	unsigned short latched_group;
	unsigned char mods;
	unsigned char base_mods;
	unsigned char latched_mods;
	unsigned char locked_mods;
	unsigned char compat_state;
	unsigned char grab_mods;
	unsigned char compat_grab_mods;
	unsigned char lookup_mods;
	unsigned char compat_lookup_mods;
	unsigned short ptr_buttons;
} XkbStateRec,*XkbStatePtr;
typedef struct _XkbMods {
	unsigned char mask;
	unsigned char real_mods;
	unsigned short vmods;
} XkbModsRec,*XkbModsPtr;
typedef struct _XkbKTMapEntry {
	int active;
	unsigned char level;
	XkbModsRec mods;
} XkbKTMapEntryRec,*XkbKTMapEntryPtr;
typedef struct _XkbKeyType {
	XkbModsRec mods;
	unsigned char num_levels;
	unsigned char map_count;
	XkbKTMapEntryPtr map;
	XkbModsPtr preserve;
	Atom name;
	Atom * level_names;
} XkbKeyTypeRec, *XkbKeyTypePtr;
typedef struct _XkbBehavior {
	unsigned char type;
	unsigned char data;
} XkbBehavior;
enum {
	XkbAnyActionDataSize = 7,
};
typedef struct _XkbAnyAction {
	unsigned char type;
	unsigned char data[7];
} XkbAnyAction;
typedef struct _XkbModAction {
	unsigned char type;
	unsigned char flags;
	unsigned char mask;
	unsigned char real_mods;
	unsigned char vmods1;
	unsigned char vmods2;
} XkbModAction;
typedef struct _XkbGroupAction {
	unsigned char type;
	unsigned char flags;
	char group_XXX;
} XkbGroupAction;
typedef struct _XkbISOAction {
	unsigned char type;
	unsigned char flags;
	unsigned char mask;
	unsigned char real_mods;
	char group_XXX;
	unsigned char affect;
	unsigned char vmods1;
	unsigned char vmods2;
} XkbISOAction;
typedef struct _XkbPtrAction {
	unsigned char type;
	unsigned char flags;
	unsigned char high_XXX;
	unsigned char low_XXX;
	unsigned char high_YYY;
	unsigned char low_YYY;
} XkbPtrAction;
typedef struct _XkbPtrBtnAction {
	unsigned char type;
	unsigned char flags;
	unsigned char count;
	unsigned char button;
} XkbPtrBtnAction;
typedef struct _XkbPtrDfltAction {
	unsigned char type;
	unsigned char flags;
	unsigned char affect;
	char valueXXX;
} XkbPtrDfltAction;
typedef struct _XkbSwitchScreenAction {
	unsigned char type;
	unsigned char flags;
	char screenXXX;
} XkbSwitchScreenAction;
typedef struct _XkbCtrlsAction {
	unsigned char type;
	unsigned char flags;
	unsigned char ctrls3;
	unsigned char ctrls2;
	unsigned char ctrls1;
	unsigned char ctrls0;
} XkbCtrlsAction;
typedef struct _XkbMessageAction {
	unsigned char type;
	unsigned char flags;
	unsigned char message[6];
} XkbMessageAction;
typedef struct _XkbRedirectKeyAction {
	unsigned char type;
	unsigned char new_key;
	unsigned char mods_mask;
	unsigned char mods;
	unsigned char vmods_mask0;
	unsigned char vmods_mask1;
	unsigned char vmods0;
	unsigned char vmods1;
} XkbRedirectKeyAction;
typedef struct _XkbDeviceBtnAction {
	unsigned char type;
	unsigned char flags;
	unsigned char count;
	unsigned char button;
	unsigned char device;
} XkbDeviceBtnAction;
typedef struct _XkbDeviceValuatorAction {
	unsigned char type;
	unsigned char device;
	unsigned char v1_what;
	unsigned char v1_ndx;
	unsigned char v1_value;
	unsigned char v2_what;
	unsigned char v2_ndx;
	unsigned char v2_value;
} XkbDeviceValuatorAction;
typedef union _XkbAction {
	XkbAnyAction any;
	XkbModAction mods;
	XkbGroupAction group;
	XkbISOAction iso;
	XkbPtrAction ptr;
	XkbPtrBtnAction btn;
	XkbPtrDfltAction dflt;
	XkbSwitchScreenAction screen;
	XkbCtrlsAction ctrls;
	XkbMessageAction msg;
	XkbRedirectKeyAction redirect;
	XkbDeviceBtnAction devbtn;
	XkbDeviceValuatorAction devval;
	unsigned char type;
} XkbAction;
typedef struct _XkbControls {
	unsigned char mk_dflt_btn;
	unsigned char num_groups;
	unsigned char groups_wrap;
	XkbModsRec internal;
	XkbModsRec ignore_lock;
	unsigned int enabled_ctrls;
	unsigned short repeat_delay;
	unsigned short repeat_interval;
	unsigned short slow_keys_delay;
	unsigned short debounce_delay;
	unsigned short mk_delay;
	unsigned short mk_interval;
	unsigned short mk_time_to_max;
	unsigned short mk_max_speed;
	short mk_curve;
	unsigned short ax_options;
	unsigned short ax_timeout;
	unsigned short axt_opts_mask;
	unsigned short axt_opts_values;
	unsigned int axt_ctrls_mask;
	unsigned int axt_ctrls_values;
	unsigned char per_key_repeat[((255 +1)/8)];
} XkbControlsRec, *XkbControlsPtr;
typedef struct _XkbServerMapRec {
	unsigned short num_acts;
	unsigned short size_acts;
	XkbAction *acts;
	XkbBehavior *behaviors;
	unsigned short *key_acts;
	unsigned char *explicit;
	unsigned char vmods[16];
	unsigned short *vmodmap;
} XkbServerMapRec, *XkbServerMapPtr;
typedef struct _XkbSymMapRec {
	unsigned char kt_index[4];
	unsigned char group_info;
	unsigned char width;
	unsigned short offset;
} XkbSymMapRec, *XkbSymMapPtr;
typedef struct _XkbClientMapRec {
	unsigned char size_types;
	unsigned char num_types;
	XkbKeyTypePtr types;
	unsigned short size_syms;
	unsigned short num_syms;
	KeySym *syms;
	XkbSymMapPtr key_sym_map;
	unsigned char *modmap;
} XkbClientMapRec, *XkbClientMapPtr;
typedef struct _XkbSymInterpretRec {
	KeySym sym;
	unsigned char flags;
	unsigned char match;
	unsigned char mods;
	unsigned char virtual_mod;
	XkbAnyAction act;
} XkbSymInterpretRec,*XkbSymInterpretPtr;
typedef struct _XkbCompatMapRec {
	XkbSymInterpretPtr sym_interpret;
	XkbModsRec groups[4];
	unsigned short num_si;
	unsigned short size_si;
} XkbCompatMapRec, *XkbCompatMapPtr;
typedef struct _XkbIndicatorMapRec {
	unsigned char flags;
	unsigned char which_groups;
	unsigned char groups;
	unsigned char which_mods;
	XkbModsRec mods;
	unsigned int ctrls;
} XkbIndicatorMapRec, *XkbIndicatorMapPtr;
typedef struct _XkbIndicatorRec {
	unsigned long phys_indicators;
	XkbIndicatorMapRec maps[32];
} XkbIndicatorRec,*XkbIndicatorPtr;
typedef struct _XkbKeyNameRec {
	char name[4];
} XkbKeyNameRec,*XkbKeyNamePtr;
typedef struct _XkbKeyAliasRec {
	char real[4];
	char alias[4];
} XkbKeyAliasRec,*XkbKeyAliasPtr;
typedef struct _XkbNamesRec {
	Atom keycodes;
	Atom geometry;
	Atom symbols;
	Atom types;
	Atom compat;
	Atom vmods[16];
	Atom indicators[32];
	Atom groups[4];
	XkbKeyNamePtr keys;
	XkbKeyAliasPtr key_aliases;
	Atom *radio_groups;
	Atom phys_symbols;
	unsigned char num_keys;
	unsigned char num_key_aliases;
	unsigned short num_rg;
} XkbNamesRec,*XkbNamesPtr;
typedef struct _XkbGeometry *XkbGeometryPtr;
typedef struct _XkbDesc {
	struct _XDisplay * dpy;
	unsigned short flags;
	unsigned short device_spec;
	KeyCode min_key_code;
	KeyCode max_key_code;
	XkbControlsPtr ctrls;
	XkbServerMapPtr server;
	XkbClientMapPtr map;
	XkbIndicatorPtr indicators;
	XkbNamesPtr names;
	XkbCompatMapPtr compat;
	XkbGeometryPtr geom;
} XkbDescRec, *XkbDescPtr;
typedef struct _XkbMapChanges {
	unsigned short changed;
	KeyCode min_key_code;
	KeyCode max_key_code;
	unsigned char first_type;
	unsigned char num_types;
	KeyCode first_key_sym;
	unsigned char num_key_syms;
	KeyCode first_key_act;
	unsigned char num_key_acts;
	KeyCode first_key_behavior;
	unsigned char num_key_behaviors;
	KeyCode first_key_explicit;
	unsigned char num_key_explicit;
	KeyCode first_modmap_key;
	unsigned char num_modmap_keys;
	KeyCode first_vmodmap_key;
	unsigned char num_vmodmap_keys;
	unsigned char pad;
	unsigned short vmods;
} XkbMapChangesRec,*XkbMapChangesPtr;
typedef struct _XkbControlsChanges {
	unsigned int changed_ctrls;
	unsigned int enabled_ctrls_changes;
	int num_groups_changed;
} XkbControlsChangesRec,*XkbControlsChangesPtr;
typedef struct _XkbIndicatorChanges {
	unsigned int state_changes;
	unsigned int map_changes;
} XkbIndicatorChangesRec,*XkbIndicatorChangesPtr;
typedef struct _XkbNameChanges {
	unsigned int changed;
	unsigned char first_type;
	unsigned char num_types;
	unsigned char first_lvl;
	unsigned char num_lvls;
	unsigned char num_aliases;
	unsigned char num_rg;
	unsigned char first_key;
	unsigned char num_keys;
	unsigned short changed_vmods;
	unsigned long changed_indicators;
	unsigned char changed_groups;
} XkbNameChangesRec,*XkbNameChangesPtr;
typedef struct _XkbCompatChanges {
	unsigned char changed_groups;
	unsigned short first_si;
	unsigned short num_si;
} XkbCompatChangesRec,*XkbCompatChangesPtr;
typedef struct _XkbChanges {
	unsigned short device_spec;
	unsigned short state_changes;
	XkbMapChangesRec map;
	XkbControlsChangesRec ctrls;
	XkbIndicatorChangesRec indicators;
	XkbNameChangesRec names;
	XkbCompatChangesRec compat;
} XkbChangesRec, *XkbChangesPtr;
typedef struct _XkbComponentNames {
	char * keymap;
	char * keycodes;
	char * types;
	char * compat;
	char * symbols;
	char * geometry;
} XkbComponentNamesRec, *XkbComponentNamesPtr;
typedef struct _XkbComponentName {
	unsigned short flags;
	char * name;
} XkbComponentNameRec,*XkbComponentNamePtr;
typedef struct _XkbComponentList {
	int num_keymaps;
	int num_keycodes;
	int num_types;
	int num_compat;
	int num_symbols;
	int num_geometry;
	XkbComponentNamePtr keymaps;
	XkbComponentNamePtr keycodes;
	XkbComponentNamePtr types;
	XkbComponentNamePtr compat;
	XkbComponentNamePtr symbols;
	XkbComponentNamePtr geometry;
} XkbComponentListRec, *XkbComponentListPtr;
typedef struct _XkbDeviceLedInfo {
	unsigned short led_class;
	unsigned short led_id;
	unsigned int phys_indicators;
	unsigned int maps_present;
	unsigned int names_present;
	unsigned int state;
	Atom names[32];
	XkbIndicatorMapRec maps[32];
} XkbDeviceLedInfoRec,*XkbDeviceLedInfoPtr;
typedef struct _XkbDeviceInfo {
	char * name;
	Atom type;
	unsigned short device_spec;
	int has_own_state;
	unsigned short supported;
	unsigned short unsupported;
	unsigned short num_btns;
	XkbAction * btn_acts;
	unsigned short sz_leds;
	unsigned short num_leds;
	unsigned short dflt_kbd_fb;
	unsigned short dflt_led_fb;
	XkbDeviceLedInfoPtr leds;
} XkbDeviceInfoRec,*XkbDeviceInfoPtr;
typedef struct _XkbDeviceLedChanges {
	unsigned short led_class;
	unsigned short led_id;
	unsigned int defined;
	struct _XkbDeviceLedChanges *next;
} XkbDeviceLedChangesRec,*XkbDeviceLedChangesPtr;
typedef struct _XkbDeviceChanges {
	unsigned int changed;
	unsigned short first_btn;
	unsigned short num_btns;
	XkbDeviceLedChangesRec leds;
} XkbDeviceChangesRec,*XkbDeviceChangesPtr;

// X11/XKBlib.h
typedef struct _XkbAnyEvent {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	unsigned int device;
} XkbAnyEvent;
typedef struct _XkbNewKeyboardNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	int old_device;
	int min_key_code;
	int max_key_code;
	int old_min_key_code;
	int old_max_key_code;
	unsigned int changed;
	char req_major;
	char req_minor;
} XkbNewKeyboardNotifyEvent;
typedef struct _XkbMapNotifyEvent {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int changed;
	unsigned int flags;
	int first_type;
	int num_types;
	KeyCode min_key_code;
	KeyCode max_key_code;
	KeyCode first_key_sym;
	KeyCode first_key_act;
	KeyCode first_key_behavior;
	KeyCode first_key_explicit;
	KeyCode first_modmap_key;
	KeyCode first_vmodmap_key;
	int num_key_syms;
	int num_key_acts;
	int num_key_behaviors;
	int num_key_explicit;
	int num_modmap_keys;
	int num_vmodmap_keys;
	unsigned int vmods;
} XkbMapNotifyEvent;
typedef struct _XkbStateNotifyEvent {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int changed;
	int group;
	int base_group;
	int latched_group;
	int locked_group;
	unsigned int mods;
	unsigned int base_mods;
	unsigned int latched_mods;
	unsigned int locked_mods;
	int compat_state;
	unsigned char grab_mods;
	unsigned char compat_grab_mods;
	unsigned char lookup_mods;
	unsigned char compat_lookup_mods;
	int ptr_buttons;
	KeyCode keycode;
	char event_type;
	char req_major;
	char req_minor;
} XkbStateNotifyEvent;
typedef struct _XkbControlsNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int changed_ctrls;
	unsigned int enabled_ctrls;
	unsigned int enabled_ctrl_changes;
	int num_groups;
	KeyCode keycode;
	char event_type;
	char req_major;
	char req_minor;
} XkbControlsNotifyEvent;
typedef struct _XkbIndicatorNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int changed;
	unsigned int state;
} XkbIndicatorNotifyEvent;
typedef struct _XkbNamesNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int changed;
	int first_type;
	int num_types;
	int first_lvl;
	int num_lvls;
	int num_aliases;
	int num_radio_groups;
	unsigned int changed_vmods;
	unsigned int changed_groups;
	unsigned int changed_indicators;
	int first_key;
	int num_keys;
} XkbNamesNotifyEvent;
typedef struct _XkbCompatMapNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int changed_groups;
	int first_si;
	int num_si;
	int num_total_si;
} XkbCompatMapNotifyEvent;
typedef struct _XkbBellNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	int percent;
	int pitch;
	int duration;
	int bell_class;
	int bell_id;
	Atom name;
	Window window;
	int event_only;
} XkbBellNotifyEvent;
typedef struct _XkbActionMessage {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	KeyCode keycode;
	int press;
	int key_event_follows;
	int group;
	unsigned int mods;
	char message[6 +1];
} XkbActionMessageEvent;
typedef struct _XkbAccessXNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	int detail;
	int keycode;
	int sk_delay;
	int debounce_delay;
} XkbAccessXNotifyEvent;
typedef struct _XkbExtensionDeviceNotify {
	int type;
	unsigned long serial;
	int send_event;
	Display * display;
	Time time;
	int xkb_type;
	int device;
	unsigned int reason;
	unsigned int supported;
	unsigned int unsupported;
	int first_btn;
	int num_btns;
	unsigned int leds_defined;
	unsigned int led_state;
	int led_class;
	int led_id;
} XkbExtensionDeviceNotifyEvent;
typedef union _XkbEvent {
	int type;
	XkbAnyEvent any;
	XkbNewKeyboardNotifyEvent new_kbd;
	XkbMapNotifyEvent map;
	XkbStateNotifyEvent state;
	XkbControlsNotifyEvent ctrls;
	XkbIndicatorNotifyEvent indicators;
	XkbNamesNotifyEvent names;
	XkbCompatMapNotifyEvent compat;
	XkbBellNotifyEvent bell;
	XkbActionMessageEvent message;
	XkbAccessXNotifyEvent accessx;
	XkbExtensionDeviceNotifyEvent device;
	XEvent core;
} XkbEvent;
typedef struct _XkbKbdDpyState XkbKbdDpyStateRec,*XkbKbdDpyStatePtr;
enum {
	XkbOD_Success        = 0,
	XkbOD_BadLibraryVersion = 1,
	XkbOD_ConnectionRefused = 2,
	XkbOD_NonXkbServer   = 3,
	XkbOD_BadServerVersion = 4,
	XkbLC_ForceLatin1Lookup = (1<<0),
	XkbLC_ConsumeLookupMods = (1<<1),
	XkbLC_AlwaysConsumeShiftAndLock = (1<<2),
	XkbLC_IgnoreNewKeyboards = (1<<3),
	XkbLC_ControlFallback = (1<<4),
	XkbLC_ConsumeKeysOnComposeFail = (1<<29),
	XkbLC_ComposeLED     = (1<<30),
	XkbLC_BeepOnComposeFail = (1<<31),
	XkbLC_AllComposeControls = (0xc0000000),
	XkbLC_AllControls    = (0xc000001f),
};
int XkbIgnoreExtension(
	int
);
Display *XkbOpenDisplay(
	char * ,
	int * ,
	int * ,
	int * ,
	int * ,
	int *
);
int XkbQueryExtension(
	Display * ,
	int * ,
	int * ,
	int * ,
	int * ,
	int *
);
int XkbUseExtension(
	Display * ,
	int * ,
	int *
);
int XkbLibraryVersion(
	int * ,
	int *
);
unsigned int XkbSetXlibControls(
	Display* ,
	unsigned int ,
	unsigned int
);
unsigned int XkbGetXlibControls(
	Display*
);
unsigned int XkbXlibControlsImplemented(void);
typedef Atom (*XkbInternAtomFunc)(
	Display * ,
	const char * ,
	int
);
typedef char * (*XkbGetAtomNameFunc)(
	Display * ,
	Atom
);
void XkbSetAtomFuncs(
	XkbInternAtomFunc ,
	XkbGetAtomNameFunc
);
KeySym XkbKeycodeToKeysym(
	Display * ,
	KeyCode ,
	int ,
	int
);
unsigned int XkbKeysymToModifiers(
	Display * ,
	KeySym
);
int XkbLookupKeySym(
	Display * ,
	KeyCode ,
	unsigned int ,
	unsigned int * ,
	KeySym *
);
int XkbLookupKeyBinding(
	Display * ,
	KeySym ,
	unsigned int ,
	char * ,
	int ,
	int *
);
int XkbTranslateKeyCode(
	XkbDescPtr ,
	KeyCode ,
	unsigned int ,
	unsigned int * ,
	KeySym *
);
int XkbTranslateKeySym(
	Display * ,
	register KeySym * ,
	unsigned int ,
	char * ,
	int ,
	int *
);
int XkbSetAutoRepeatRate(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbGetAutoRepeatRate(
	Display * ,
	unsigned int ,
	unsigned int * ,
	unsigned int *
);
int XkbChangeEnabledControls(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbDeviceBell(
	Display * ,
	Window ,
	int ,
	int ,
	int ,
	int ,
	Atom
);
int XkbForceDeviceBell(
	Display * ,
	int ,
	int ,
	int ,
	int
);
int XkbDeviceBellEvent(
	Display * ,
	Window ,
	int ,
	int ,
	int ,
	int ,
	Atom
);
int XkbBell(
	Display * ,
	Window ,
	int ,
	Atom
);
int XkbForceBell(
	Display * ,
	int
);
int XkbBellEvent(
	Display * ,
	Window ,
	int ,
	Atom
);
int XkbSelectEvents(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbSelectEventDetails(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned long ,
	unsigned long
);
void XkbNoteMapChanges(
	XkbMapChangesPtr ,
	XkbMapNotifyEvent * ,
	unsigned int
);
void XkbNoteNameChanges(
	XkbNameChangesPtr ,
	XkbNamesNotifyEvent * ,
	unsigned int
);
int XkbGetIndicatorState(
	Display * ,
	unsigned int ,
	unsigned int *
);
int XkbGetDeviceIndicatorState(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned int *
);
int XkbGetIndicatorMap(
	Display * ,
	unsigned long ,
	XkbDescPtr
);
int XkbSetIndicatorMap(
	Display * ,
	unsigned long ,
	XkbDescPtr
);
int XkbGetNamedIndicator(
	Display * ,
	Atom ,
	int * ,
	int * ,
	XkbIndicatorMapPtr ,
	int *
);
int XkbGetNamedDeviceIndicator(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	Atom ,
	int * ,
	int * ,
	XkbIndicatorMapPtr ,
	int *
);
int XkbSetNamedIndicator(
	Display * ,
	Atom ,
	int ,
	int ,
	int ,
	XkbIndicatorMapPtr
);
int XkbSetNamedDeviceIndicator(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	Atom ,
	int ,
	int ,
	int ,
	XkbIndicatorMapPtr
);
int XkbLockModifiers(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbLatchModifiers(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbLockGroup(
	Display * ,
	unsigned int ,
	unsigned int
);
int XkbLatchGroup(
	Display * ,
	unsigned int ,
	unsigned int
);
int XkbSetServerInternalMods(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbSetIgnoreLockMods(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbVirtualModsToReal(
	XkbDescPtr ,
	unsigned int ,
	unsigned int *
);
int XkbComputeEffectiveMap(
	XkbDescPtr ,
	XkbKeyTypePtr ,
	unsigned char *
);
int XkbInitCanonicalKeyTypes(
	XkbDescPtr ,
	unsigned int ,
	int
);
XkbDescPtr XkbAllocKeyboard(
	void
);
void XkbFreeKeyboard(
	XkbDescPtr ,
	unsigned int ,
	int
);
int XkbAllocClientMap(
	XkbDescPtr ,
	unsigned int ,
	unsigned int
);
int XkbAllocServerMap(
	XkbDescPtr ,
	unsigned int ,
	unsigned int
);
void XkbFreeClientMap(
	XkbDescPtr ,
	unsigned int ,
	int
);
void XkbFreeServerMap(
	XkbDescPtr ,
	unsigned int ,
	int
);
XkbKeyTypePtr XkbAddKeyType(
	XkbDescPtr ,
	Atom ,
	int ,
	int ,
	int
);
int XkbAllocIndicatorMaps(
	XkbDescPtr
);
void XkbFreeIndicatorMaps(
	XkbDescPtr
);
XkbDescPtr XkbGetMap(
	Display * ,
	unsigned int ,
	unsigned int
);
int XkbGetUpdatedMap(
	Display * ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetMapChanges(
	Display * ,
	XkbDescPtr ,
	XkbMapChangesPtr
);
int XkbRefreshKeyboardMapping(
	XkbMapNotifyEvent *
);
int XkbGetKeyTypes(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetKeySyms(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetKeyActions(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetKeyBehaviors(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetVirtualMods(
	Display * ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetKeyExplicitComponents(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetKeyModifierMap(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbGetKeyVirtualModMap(
	Display * ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbAllocControls(
	XkbDescPtr ,
	unsigned int
);
void XkbFreeControls(
	XkbDescPtr ,
	unsigned int ,
	int
);
int XkbGetControls(
	Display * ,
	unsigned long ,
	XkbDescPtr
);
int XkbSetControls(
	Display * ,
	unsigned long ,
	XkbDescPtr
);
void XkbNoteControlsChanges(
	XkbControlsChangesPtr ,
	XkbControlsNotifyEvent * ,
	unsigned int
);
int XkbAllocCompatMap(
	XkbDescPtr ,
	unsigned int ,
	unsigned int
);
void XkbFreeCompatMap(
	XkbDescPtr ,
	unsigned int ,
	int
);
int XkbGetCompatMap(
	Display * ,
	unsigned int ,
	XkbDescPtr
);
int XkbSetCompatMap(
	Display * ,
	unsigned int ,
	XkbDescPtr ,
	int
);
XkbSymInterpretPtr XkbAddSymInterpret(
	XkbDescPtr ,
	XkbSymInterpretPtr ,
	int ,
	XkbChangesPtr
);
int XkbAllocNames(
	XkbDescPtr ,
	unsigned int ,
	int ,
	int
);
int XkbGetNames(
	Display * ,
	unsigned int ,
	XkbDescPtr
);
int XkbSetNames(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	XkbDescPtr
);
int XkbChangeNames(
	Display * ,
	XkbDescPtr ,
	XkbNameChangesPtr
);
void XkbFreeNames(
	XkbDescPtr ,
	unsigned int ,
	int
);
int XkbGetState(
	Display * ,
	unsigned int ,
	XkbStatePtr
);
int XkbSetMap(
	Display * ,
	unsigned int ,
	XkbDescPtr
);
int XkbChangeMap(
	Display* ,
	XkbDescPtr ,
	XkbMapChangesPtr
);
int XkbSetDetectableAutoRepeat(
	Display * ,
	int ,
	int *
);
int XkbGetDetectableAutoRepeat(
	Display * ,
	int *
);
int XkbSetAutoResetControls(
	Display * ,
	unsigned int ,
	unsigned int * ,
	unsigned int *
);
int XkbGetAutoResetControls(
	Display * ,
	unsigned int * ,
	unsigned int *
);
int XkbSetPerClientControls(
	Display * ,
	unsigned int ,
	unsigned int *
);
int XkbGetPerClientControls(
	Display * ,
	unsigned int *
);
int XkbCopyKeyType(
	XkbKeyTypePtr ,
	XkbKeyTypePtr
);
int XkbCopyKeyTypes(
	XkbKeyTypePtr ,
	XkbKeyTypePtr ,
	int
);
int XkbResizeKeyType(
	XkbDescPtr ,
	int ,
	int ,
	int ,
	int
);
KeySym *XkbResizeKeySyms(
	XkbDescPtr ,
	int ,
	int
);
XkbAction *XkbResizeKeyActions(
	XkbDescPtr ,
	int ,
	int
);
int XkbChangeTypesOfKey(
	XkbDescPtr ,
	int ,
	int ,
	unsigned int ,
	int * ,
	XkbMapChangesPtr
);
int XkbChangeKeycodeRange(
	XkbDescPtr ,
	int ,
	int ,
	XkbChangesPtr
);
XkbComponentListPtr XkbListComponents(
	Display * ,
	unsigned int ,
	XkbComponentNamesPtr ,
	int *
);
void XkbFreeComponentList(
	XkbComponentListPtr
);
XkbDescPtr XkbGetKeyboard(
	Display * ,
	unsigned int ,
	unsigned int
);
XkbDescPtr XkbGetKeyboardByName(
	Display * ,
	unsigned int ,
	XkbComponentNamesPtr ,
	unsigned int ,
	unsigned int ,
	int
);
int XkbKeyTypesForCoreSymbols(
	XkbDescPtr ,
	int ,
	KeySym * ,
	unsigned int ,
	int * ,
	KeySym *
);
int XkbApplyCompatMapToKey(
	XkbDescPtr ,
	KeyCode ,
	XkbChangesPtr
);
int XkbUpdateMapFromCore(
	XkbDescPtr ,
	KeyCode ,
	int ,
	int ,
	KeySym * ,
	XkbChangesPtr
);
XkbDeviceLedInfoPtr XkbAddDeviceLedInfo(
	XkbDeviceInfoPtr ,
	unsigned int ,
	unsigned int
);
int XkbResizeDeviceButtonActions(
	XkbDeviceInfoPtr ,
	unsigned int
);
XkbDeviceInfoPtr XkbAllocDeviceInfo(
	unsigned int ,
	unsigned int ,
	unsigned int
);
void XkbFreeDeviceInfo(
	XkbDeviceInfoPtr ,
	unsigned int ,
	int
);
void XkbNoteDeviceChanges(
	XkbDeviceChangesPtr ,
	XkbExtensionDeviceNotifyEvent * ,
	unsigned int
);
XkbDeviceInfoPtr XkbGetDeviceInfo(
	Display * ,
	unsigned int ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbGetDeviceInfoChanges(
	Display * ,
	XkbDeviceInfoPtr ,
	XkbDeviceChangesPtr
);
int XkbGetDeviceButtonActions(
	Display * ,
	XkbDeviceInfoPtr ,
	int ,
	unsigned int ,
	unsigned int
);
int XkbGetDeviceLedInfo(
	Display * ,
	XkbDeviceInfoPtr ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbSetDeviceInfo(
	Display * ,
	unsigned int ,
	XkbDeviceInfoPtr
);
int XkbChangeDeviceInfo(
	Display* ,
	XkbDeviceInfoPtr ,
	XkbDeviceChangesPtr
);
int XkbSetDeviceLedInfo(
	Display * ,
	XkbDeviceInfoPtr ,
	unsigned int ,
	unsigned int ,
	unsigned int
);
int XkbSetDeviceButtonActions(
	Display * ,
	XkbDeviceInfoPtr ,
	unsigned int ,
	unsigned int
);
char XkbToControl(
	char
);
int XkbSetDebuggingFlags(
	Display * ,
	unsigned int ,
	unsigned int ,
	char * ,
	unsigned int ,
	unsigned int ,
	unsigned int * ,
	unsigned int *
);
int XkbApplyVirtualModChanges(
	XkbDescPtr ,
	unsigned int ,
	XkbChangesPtr
);
int XkbUpdateActionVirtualMods(
	XkbDescPtr ,
	XkbAction * ,
	unsigned int
);
void XkbUpdateKeyTypeVirtualMods(
	XkbDescPtr ,
	XkbKeyTypePtr ,
	unsigned int ,
	XkbChangesPtr
);
]]

--[=[
function XkbCharToInt(v) return (v)&0x80?(int)((v)|(~0xff)):(int)((v)&0x7f) end
function XkbIntTo2Chars(i,h,l) return ((h)=((i>>8)&0xff)),((l)=((i)&0xff)) end
function Xkb2CharsToInt(h,l) return (short)(((h)<<8)|(l)) end

function XkbModLocks(s) return (s).locked_mods end
function XkbStateMods(s) return (s).base_mods|(s).latched_mods|XkbModLocks(s) end
function XkbGroupLock(s) return (s).locked_group end
function XkbStateGroup(s) return (s).base_group+(s).latched_group+XkbGroupLock(s) end
function XkbStateFieldFromRec(s) return XkbBuildCoreState((s).lookup_mods,(s).group) end
function XkbGrabStateFromRec(s) return XkbBuildCoreState((s).grab_mods,(s).group) end

function XkbNoteIndicatorMapChanges(o,n,w) return (o).map_changes|=((n).map_changes&(w)) end
function XkbNoteIndicatorStateChanges(o,n,w) return (o).state_changes|=((n).state_changes&(w)) end
function XkbGetIndicatorMapChanges(d,x,c) return XkbGetIndicatorMap((d),(c).map_changes,x) end
function XkbChangeIndicatorMaps(d,x,c) return XkbSetIndicatorMap((d),(c).map_changes,x) end

function XkbGetControlsChanges(d,x,c) return XkbGetControls(d,(c).changed_ctrls,x) end
function XkbChangeControls(d,x,c) return XkbSetControls(d,(c).changed_ctrls,x) end

function XkbNumGroups(g) return (g)&0x0f end
function XkbOutOfRangeGroupInfo(g) return (g)&0xf0 end
function XkbOutOfRangeGroupAction(g) return (g)&0xc0 end
function XkbOutOfRangeGroupNumber(g) return ((g)&0x30)>>4 end
function XkbSetGroupInfo(g,w,n) return ((w)&0xc0)|(((n)&3)<<4)|((g)&0x0f) end
function XkbSetNumGroups(g,n) return ((g)&0xf0)|((n)&0x0f) end

function XkbModActionVMods(a) return (short)(((a).vmods1<<8)|((a).vmods2)) end
function XkbSetModActionVMods(a,v) return ((a).vmods1=(((v)>>8)&0xff)),(a).vmods2=((v)&0xff) end

function XkbSAGroup(a) return XkbCharToInt((a).group_XXX) end
function XkbSASetGroup(a,g) return (a).group_XXX=(g) end

function XkbPtrActionX(a) return Xkb2CharsToInt((a).high_XXX,(a).low_XXX) end
function XkbPtrActionY(a) return Xkb2CharsToInt((a).high_YYY,(a).low_YYY) end
function XkbSetPtrActionX(a,x) return XkbIntTo2Chars(x,(a).high_XXX,(a).low_XXX) end
function XkbSetPtrActionY(a,y) return XkbIntTo2Chars(y,(a).high_YYY,(a).low_YYY) end

function XkbSAPtrDfltValue(a) return XkbCharToInt((a).valueXXX) end
function XkbSASetPtrDfltValue(a,c) return (a).valueXXX= ((c)&0xff) end

function XkbSAScreen(a) return XkbCharToInt((a).screenXXX) end
function XkbSASetScreen(a,s) return (a).screenXXX= ((s)&0xff) end

function XkbActionSetCtrls(a,c) return ((a).ctrls3=(((c)>>24)&0xff)), ((a).ctrls2=(((c)>>16)&0xff)), ((a).ctrls1=(((c)>>8)&0xff)), ((a).ctrls0=((c)&0xff)) end
function XkbActionCtrls(a) return (((unsigned int)(a).ctrls3)<<24)| (((unsigned int)(a).ctrls2)<<16)| (((unsigned int)(a).ctrls1)<<8)| ((unsigned int)((a).ctrls0)) end

function XkbSARedirectVMods(a) return (((unsigned int)(a).vmods1)<<8)| ((unsigned int)(a).vmods0) end
function XkbSARedirectSetVMods(a,m) return ((a).vmods_mask1=(((m)>>8)&0xff)), ((a).vmods_mask0=((m)&0xff)) end
function XkbSARedirectVModsMask(a) return (((unsigned int)(a).vmods_mask1)<<8)| ((unsigned int)(a).vmods_mask0) end
function XkbSARedirectSetVModsMask(a,m) return ((a).vmods_mask1=(((m)>>8)&0xff)), ((a).vmods_mask0=((m)&0xff)) end

function XkbAX_AnyFeedback(c) return (c).enabled_ctrls&XkbAccessXFeedbackMask end
function XkbAX_NeedOption(c,w) return (c).ax_options&(w) end
function XkbAX_NeedFeedback(c,w) return XkbAX_AnyFeedback(c)&&XkbAX_NeedOption(c,w) end

function XkbSMKeyActionsPtr(m,k) return &(m).acts[(m).key_acts[k]] end

function XkbCMKeyGroupInfo(m,k) return (m).key_sym_map[k].group_info end
function XkbCMKeyNumGroups(m,k) return XkbNumGroups((m).key_sym_map[k].group_info) end
function XkbCMKeyGroupWidth(m,k,g) return XkbCMKeyType(m,k,g).num_levels end
function XkbCMKeyGroupsWidth(m,k) return (m).key_sym_map[k].width end
function XkbCMKeyTypeIndex(m,k,g) return (m).key_sym_map[k].kt_index[g&0x3] end
function XkbCMKeyType(m,k,g) return &(m).types[XkbCMKeyTypeIndex(m,k,g)] end
function XkbCMKeyNumSyms(m,k) return XkbCMKeyGroupsWidth(m,k)*XkbCMKeyNumGroups(m,k) end
function XkbCMKeySymsOffset(m,k) return (m).key_sym_map[k].offset end
function XkbCMKeySymsPtr(m,k) return &(m).syms[XkbCMKeySymsOffset(m,k)] end

function XkbIM_IsAuto(i) return (((i).flags&XkbIM_NoAutomatic)==0)&& (((i).which_groups&&(i).groups)|| ((i).which_mods&&(i).mods.mask)|| ((i).ctrls)) end
function XkbIM_InUse(i) return ((i).flags)||((i).which_groups)|| ((i).which_mods)||((i).ctrls) end

function XkbKeyKeyTypeIndex(d,k,g) return XkbCMKeyTypeIndex((d).map,k,g) end
function XkbKeyKeyType(d,k,g) return XkbCMKeyType((d).map,k,g) end
function XkbKeyGroupWidth(d,k,g) return XkbCMKeyGroupWidth((d).map,k,g) end
function XkbKeyGroupsWidth(d,k) return XkbCMKeyGroupsWidth((d).map,k) end
function XkbKeyGroupInfo(d,k) return XkbCMKeyGroupInfo((d).map,(k)) end
function XkbKeyNumGroups(d,k) return XkbCMKeyNumGroups((d).map,(k)) end
function XkbKeyNumSyms(d,k) return XkbCMKeyNumSyms((d).map,(k)) end
function XkbKeySymsPtr(d,k) return XkbCMKeySymsPtr((d).map,(k)) end
function XkbKeySym(d,k,n) return XkbKeySymsPtr(d,k)[n] end
function XkbKeySymEntry(d,k,sl,g) return XkbKeySym(d,k,((XkbKeyGroupsWidth(d,k)*(g))+(sl))) end
function XkbKeyAction(d,k,n) return XkbKeyHasActions(d,k)?&XkbKeyActionsPtr(d,k)[n]:NULL end
function XkbKeyActionEntry(d,k,sl,g) return XkbKeyHasActions(d,k)? XkbKeyAction(d,k,((XkbKeyGroupsWidth(d,k)*(g))+(sl))):NULL end
function XkbKeyHasActions(d,k) return (d).server.key_acts[k]!=0 end
function XkbKeyNumActions(d,k) return XkbKeyHasActions(d,k)?XkbKeyNumSyms(d,k):1 end
function XkbKeyActionsPtr(d,k) return XkbSMKeyActionsPtr((d).server,k) end
function XkbKeycodeInRange(d,k) return ((k)>=(d).min_key_code)&& ((k)<=(d).max_key_code) end
function XkbNumKeys(d) return (d).max_key_code-(d).min_key_code+1 end

function XkbXI_DevHasBtnActs(d) return ((d).num_btns>0)&&((d).btn_acts!=NULL) end
function XkbXI_LegalDevBtn(d,b) return XkbXI_DevHasBtnActs(d)&&((b)<(d).num_btns) end
function XkbXI_DevHasLeds(d) return ((d).num_leds>0)&&((d).leds!=NULL) end

function XkbLegalXILedClass(c) return ((c)==KbdFeedbackClass)|| ((c)==LedFeedbackClass)|| ((c)==XkbDfltXIClass)|| ((c)==XkbAllXIClasses) end
function XkbLegalXIBellClass(c) return ((c)==KbdFeedbackClass)|| ((c)==BellFeedbackClass)|| ((c)==XkbDfltXIClass)|| ((c)==XkbAllXIClasses) end
function XkbExplicitXIDevice(c) return ((c)&(~0xff))==0 end
function XkbExplicitXIClass(c) return ((c)&(~0xff))==0 end
function XkbExplicitXIId(c) return ((c)&(~0xff))==0 end
function XkbSingleXIClass(c) return (((c)&(~0xff))==0)||((c)==XkbDfltXIClass) end
function XkbSingleXIId(c) return (((c)&(~0xff))==0)||((c)==XkbDfltXIId) end

function XkbBuildCoreState(m,g) return (((g)&0x3)<<13)|((m)&0xff) end
function XkbGroupForCoreState(s) return ((s)>>13)&0x3 end
function XkbIsLegalGroup(g) return ((g)>=0)&&((g)<XkbNumKbdGroups) end

function XkbSA_ValOp(a) return (a)&XkbSA_ValOpMask end
function XkbSA_ValScale(a) return (a)&XkbSA_ValScaleMask end

function XkbIsModAction(a) return ((a).type>=Xkb_SASetMods)&&((a).type<=XkbSA_LockMods) end
function XkbIsGroupAction(a) return ((a).type>=XkbSA_SetGroup)&&((a).type<=XkbSA_LockGroup) end
function XkbIsPtrAction(a) return ((a).type>=XkbSA_MovePtr)&&((a).type<=XkbSA_SetPtrDflt) end

function XkbIsLegalKeycode(k) return (k)>=XkbMinLegalKeyCode end

function XkbShiftLevel(n) return (n)-1 end
function XkbShiftLevelMask(n) return 1<<((n)-1) end

XkbName = "XKEYBOARD"

]=]

return X
