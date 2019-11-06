
--LLVM 8.0 C API headers (x86 target).

local ffi = require'ffi'
ffi.cdef[[

typedef int64_t off_t;

// Types.h -------------------------------------------------------------------

typedef signed __int64 ssize_t;

// DataTypes.h ---------------------------------------------------------------

typedef int LLVMBool;
typedef struct LLVMOpaqueMemoryBuffer *LLVMMemoryBufferRef;
typedef struct LLVMOpaqueContext *LLVMContextRef;
typedef struct LLVMOpaqueModule *LLVMModuleRef;
typedef struct LLVMOpaqueType *LLVMTypeRef;
typedef struct LLVMOpaqueValue *LLVMValueRef;
typedef struct LLVMOpaqueBasicBlock *LLVMBasicBlockRef;
typedef struct LLVMOpaqueMetadata *LLVMMetadataRef;
typedef struct LLVMOpaqueNamedMDNode *LLVMNamedMDNodeRef;
typedef struct LLVMOpaqueValueMetadataEntry LLVMValueMetadataEntry;
typedef struct LLVMOpaqueBuilder *LLVMBuilderRef;
typedef struct LLVMOpaqueDIBuilder *LLVMDIBuilderRef;
typedef struct LLVMOpaqueModuleProvider *LLVMModuleProviderRef;
typedef struct LLVMOpaquePassManager *LLVMPassManagerRef;
typedef struct LLVMOpaquePassRegistry *LLVMPassRegistryRef;
typedef struct LLVMOpaqueUse *LLVMUseRef;
typedef struct LLVMOpaqueAttributeRef *LLVMAttributeRef;
typedef struct LLVMOpaqueDiagnosticInfo *LLVMDiagnosticInfoRef;
typedef struct LLVMComdat *LLVMComdatRef;
typedef struct LLVMOpaqueModuleFlagEntry LLVMModuleFlagEntry;
typedef struct LLVMOpaqueJITEventListener *LLVMJITEventListenerRef;

// Analysis.h ----------------------------------------------------------------

typedef enum {
  LLVMAbortProcessAction,
  LLVMPrintMessageAction,
  LLVMReturnStatusAction
} LLVMVerifierFailureAction;
LLVMBool LLVMVerifyModule(LLVMModuleRef M, LLVMVerifierFailureAction Action,
                          char **OutMessage);
LLVMBool LLVMVerifyFunction(LLVMValueRef Fn, LLVMVerifierFailureAction Action);
void LLVMViewFunctionCFG(LLVMValueRef Fn);
void LLVMViewFunctionCFGOnly(LLVMValueRef Fn);

// BitReader.h ---------------------------------------------------------------

LLVMBool LLVMParseBitcode(LLVMMemoryBufferRef MemBuf, LLVMModuleRef *OutModule,
                          char **OutMessage);
LLVMBool LLVMParseBitcode2(LLVMMemoryBufferRef MemBuf,
                           LLVMModuleRef *OutModule);
LLVMBool LLVMParseBitcodeInContext(LLVMContextRef ContextRef,
                                   LLVMMemoryBufferRef MemBuf,
                                   LLVMModuleRef *OutModule, char **OutMessage);
LLVMBool LLVMParseBitcodeInContext2(LLVMContextRef ContextRef,
                                    LLVMMemoryBufferRef MemBuf,
                                    LLVMModuleRef *OutModule);
LLVMBool LLVMGetBitcodeModuleInContext(LLVMContextRef ContextRef,
                                       LLVMMemoryBufferRef MemBuf,
                                       LLVMModuleRef *OutM, char **OutMessage);
LLVMBool LLVMGetBitcodeModuleInContext2(LLVMContextRef ContextRef,
                                        LLVMMemoryBufferRef MemBuf,
                                        LLVMModuleRef *OutM);
LLVMBool LLVMGetBitcodeModule(LLVMMemoryBufferRef MemBuf, LLVMModuleRef *OutM,
                              char **OutMessage);
LLVMBool LLVMGetBitcodeModule2(LLVMMemoryBufferRef MemBuf, LLVMModuleRef *OutM);

// BitWriter.h ---------------------------------------------------------------

int LLVMWriteBitcodeToFile(LLVMModuleRef M, const char *Path);
int LLVMWriteBitcodeToFD(LLVMModuleRef M, int FD, int ShouldClose,
                         int Unbuffered);
int LLVMWriteBitcodeToFileHandle(LLVMModuleRef M, int Handle);
LLVMMemoryBufferRef LLVMWriteBitcodeToMemoryBuffer(LLVMModuleRef M);

// Comdat.h ------------------------------------------------------------------

typedef enum {
  LLVMAnyComdatSelectionKind,
  LLVMExactMatchComdatSelectionKind,
  LLVMLargestComdatSelectionKind,
  LLVMNoDuplicatesComdatSelectionKind,
  LLVMSameSizeComdatSelectionKind
} LLVMComdatSelectionKind;
LLVMComdatRef LLVMGetOrInsertComdat(LLVMModuleRef M, const char *Name);
LLVMComdatRef LLVMGetComdat(LLVMValueRef V);
void LLVMSetComdat(LLVMValueRef V, LLVMComdatRef C);
LLVMComdatSelectionKind LLVMGetComdatSelectionKind(LLVMComdatRef C);
void LLVMSetComdatSelectionKind(LLVMComdatRef C, LLVMComdatSelectionKind Kind);

// ErrorHandling.h -----------------------------------------------------------

typedef void (*LLVMFatalErrorHandler)(const char *Reason);
void LLVMInstallFatalErrorHandler(LLVMFatalErrorHandler Handler);
void LLVMResetFatalErrorHandler(void);
void LLVMEnablePrettyStackTrace(void);

// Core.h --------------------------------------------------------------------

typedef enum {
  LLVMRet            = 1,
  LLVMBr             = 2,
  LLVMSwitch         = 3,
  LLVMIndirectBr     = 4,
  LLVMInvoke         = 5,
  LLVMUnreachable    = 7,
  LLVMFNeg           = 66,
  LLVMAdd            = 8,
  LLVMFAdd           = 9,
  LLVMSub            = 10,
  LLVMFSub           = 11,
  LLVMMul            = 12,
  LLVMFMul           = 13,
  LLVMUDiv           = 14,
  LLVMSDiv           = 15,
  LLVMFDiv           = 16,
  LLVMURem           = 17,
  LLVMSRem           = 18,
  LLVMFRem           = 19,
  LLVMShl            = 20,
  LLVMLShr           = 21,
  LLVMAShr           = 22,
  LLVMAnd            = 23,
  LLVMOr             = 24,
  LLVMXor            = 25,
  LLVMAlloca         = 26,
  LLVMLoad           = 27,
  LLVMStore          = 28,
  LLVMGetElementPtr  = 29,
  LLVMTrunc          = 30,
  LLVMZExt           = 31,
  LLVMSExt           = 32,
  LLVMFPToUI         = 33,
  LLVMFPToSI         = 34,
  LLVMUIToFP         = 35,
  LLVMSIToFP         = 36,
  LLVMFPTrunc        = 37,
  LLVMFPExt          = 38,
  LLVMPtrToInt       = 39,
  LLVMIntToPtr       = 40,
  LLVMBitCast        = 41,
  LLVMAddrSpaceCast  = 60,
  LLVMICmp           = 42,
  LLVMFCmp           = 43,
  LLVMPHI            = 44,
  LLVMCall           = 45,
  LLVMSelect         = 46,
  LLVMUserOp1        = 47,
  LLVMUserOp2        = 48,
  LLVMVAArg          = 49,
  LLVMExtractElement = 50,
  LLVMInsertElement  = 51,
  LLVMShuffleVector  = 52,
  LLVMExtractValue   = 53,
  LLVMInsertValue    = 54,
  LLVMFence          = 55,
  LLVMAtomicCmpXchg  = 56,
  LLVMAtomicRMW      = 57,
  LLVMResume         = 58,
  LLVMLandingPad     = 59,
  LLVMCleanupRet     = 61,
  LLVMCatchRet       = 62,
  LLVMCatchPad       = 63,
  LLVMCleanupPad     = 64,
  LLVMCatchSwitch    = 65
} LLVMOpcode;
typedef enum {
  LLVMVoidTypeKind,
  LLVMHalfTypeKind,
  LLVMFloatTypeKind,
  LLVMDoubleTypeKind,
  LLVMX86_FP80TypeKind,
  LLVMFP128TypeKind,
  LLVMPPC_FP128TypeKind,
  LLVMLabelTypeKind,
  LLVMIntegerTypeKind,
  LLVMFunctionTypeKind,
  LLVMStructTypeKind,
  LLVMArrayTypeKind,
  LLVMPointerTypeKind,
  LLVMVectorTypeKind,
  LLVMMetadataTypeKind,
  LLVMX86_MMXTypeKind,
  LLVMTokenTypeKind
} LLVMTypeKind;
typedef enum {
  LLVMExternalLinkage,
  LLVMAvailableExternallyLinkage,
  LLVMLinkOnceAnyLinkage,
  LLVMLinkOnceODRLinkage,
  LLVMLinkOnceODRAutoHideLinkage,
  LLVMWeakAnyLinkage,
  LLVMWeakODRLinkage,
  LLVMAppendingLinkage,
  LLVMInternalLinkage,
  LLVMPrivateLinkage,
  LLVMDLLImportLinkage,
  LLVMDLLExportLinkage,
  LLVMExternalWeakLinkage,
  LLVMGhostLinkage,
  LLVMCommonLinkage,
  LLVMLinkerPrivateLinkage,
  LLVMLinkerPrivateWeakLinkage
} LLVMLinkage;
typedef enum {
  LLVMDefaultVisibility,
  LLVMHiddenVisibility,
  LLVMProtectedVisibility
} LLVMVisibility;
typedef enum {
  LLVMNoUnnamedAddr,
  LLVMLocalUnnamedAddr,
  LLVMGlobalUnnamedAddr
} LLVMUnnamedAddr;
typedef enum {
  LLVMDefaultStorageClass   = 0,
  LLVMDLLImportStorageClass = 1,
  LLVMDLLExportStorageClass = 2
} LLVMDLLStorageClass;
typedef enum {
  LLVMCCallConv             = 0,
  LLVMFastCallConv          = 8,
  LLVMColdCallConv          = 9,
  LLVMGHCCallConv           = 10,
  LLVMHiPECallConv          = 11,
  LLVMWebKitJSCallConv      = 12,
  LLVMAnyRegCallConv        = 13,
  LLVMPreserveMostCallConv  = 14,
  LLVMPreserveAllCallConv   = 15,
  LLVMSwiftCallConv         = 16,
  LLVMCXXFASTTLSCallConv    = 17,
  LLVMX86StdcallCallConv    = 64,
  LLVMX86FastcallCallConv   = 65,
  LLVMARMAPCSCallConv       = 66,
  LLVMARMAAPCSCallConv      = 67,
  LLVMARMAAPCSVFPCallConv   = 68,
  LLVMMSP430INTRCallConv    = 69,
  LLVMX86ThisCallCallConv   = 70,
  LLVMPTXKernelCallConv     = 71,
  LLVMPTXDeviceCallConv     = 72,
  LLVMSPIRFUNCCallConv      = 75,
  LLVMSPIRKERNELCallConv    = 76,
  LLVMIntelOCLBICallConv    = 77,
  LLVMX8664SysVCallConv     = 78,
  LLVMWin64CallConv         = 79,
  LLVMX86VectorCallCallConv = 80,
  LLVMHHVMCallConv          = 81,
  LLVMHHVMCCallConv         = 82,
  LLVMX86INTRCallConv       = 83,
  LLVMAVRINTRCallConv       = 84,
  LLVMAVRSIGNALCallConv     = 85,
  LLVMAVRBUILTINCallConv    = 86,
  LLVMAMDGPUVSCallConv      = 87,
  LLVMAMDGPUGSCallConv      = 88,
  LLVMAMDGPUPSCallConv      = 89,
  LLVMAMDGPUCSCallConv      = 90,
  LLVMAMDGPUKERNELCallConv  = 91,
  LLVMX86RegCallCallConv    = 92,
  LLVMAMDGPUHSCallConv      = 93,
  LLVMMSP430BUILTINCallConv = 94,
  LLVMAMDGPULSCallConv      = 95,
  LLVMAMDGPUESCallConv      = 96
} LLVMCallConv;
typedef enum {
  LLVMArgumentValueKind,
  LLVMBasicBlockValueKind,
  LLVMMemoryUseValueKind,
  LLVMMemoryDefValueKind,
  LLVMMemoryPhiValueKind,
  LLVMFunctionValueKind,
  LLVMGlobalAliasValueKind,
  LLVMGlobalIFuncValueKind,
  LLVMGlobalVariableValueKind,
  LLVMBlockAddressValueKind,
  LLVMConstantExprValueKind,
  LLVMConstantArrayValueKind,
  LLVMConstantStructValueKind,
  LLVMConstantVectorValueKind,
  LLVMUndefValueValueKind,
  LLVMConstantAggregateZeroValueKind,
  LLVMConstantDataArrayValueKind,
  LLVMConstantDataVectorValueKind,
  LLVMConstantIntValueKind,
  LLVMConstantFPValueKind,
  LLVMConstantPointerNullValueKind,
  LLVMConstantTokenNoneValueKind,
  LLVMMetadataAsValueValueKind,
  LLVMInlineAsmValueKind,
  LLVMInstructionValueKind,
} LLVMValueKind;
typedef enum {
  LLVMIntEQ = 32,
  LLVMIntNE,
  LLVMIntUGT,
  LLVMIntUGE,
  LLVMIntULT,
  LLVMIntULE,
  LLVMIntSGT,
  LLVMIntSGE,
  LLVMIntSLT,
  LLVMIntSLE
} LLVMIntPredicate;
typedef enum {
  LLVMRealPredicateFalse,
  LLVMRealOEQ,
  LLVMRealOGT,
  LLVMRealOGE,
  LLVMRealOLT,
  LLVMRealOLE,
  LLVMRealONE,
  LLVMRealORD,
  LLVMRealUNO,
  LLVMRealUEQ,
  LLVMRealUGT,
  LLVMRealUGE,
  LLVMRealULT,
  LLVMRealULE,
  LLVMRealUNE,
  LLVMRealPredicateTrue
} LLVMRealPredicate;
typedef enum {
  LLVMLandingPadCatch,
  LLVMLandingPadFilter
} LLVMLandingPadClauseTy;
typedef enum {
  LLVMNotThreadLocal = 0,
  LLVMGeneralDynamicTLSModel,
  LLVMLocalDynamicTLSModel,
  LLVMInitialExecTLSModel,
  LLVMLocalExecTLSModel
} LLVMThreadLocalMode;
typedef enum {
  LLVMAtomicOrderingNotAtomic = 0,
  LLVMAtomicOrderingUnordered = 1,
  LLVMAtomicOrderingMonotonic = 2,
  LLVMAtomicOrderingAcquire = 4,
  LLVMAtomicOrderingRelease = 5,
  LLVMAtomicOrderingAcquireRelease = 6,
  LLVMAtomicOrderingSequentiallyConsistent = 7
} LLVMAtomicOrdering;
typedef enum {
    LLVMAtomicRMWBinOpXchg,
    LLVMAtomicRMWBinOpAdd,
    LLVMAtomicRMWBinOpSub,
    LLVMAtomicRMWBinOpAnd,
    LLVMAtomicRMWBinOpNand,
    LLVMAtomicRMWBinOpOr,
    LLVMAtomicRMWBinOpXor,
    LLVMAtomicRMWBinOpMax,
    LLVMAtomicRMWBinOpMin,
    LLVMAtomicRMWBinOpUMax,
    LLVMAtomicRMWBinOpUMin
} LLVMAtomicRMWBinOp;
typedef enum {
    LLVMDSError,
    LLVMDSWarning,
    LLVMDSRemark,
    LLVMDSNote
} LLVMDiagnosticSeverity;
typedef enum {
  LLVMInlineAsmDialectATT,
  LLVMInlineAsmDialectIntel
} LLVMInlineAsmDialect;
typedef enum {
  LLVMModuleFlagBehaviorError,
  LLVMModuleFlagBehaviorWarning,
  LLVMModuleFlagBehaviorRequire,
  LLVMModuleFlagBehaviorOverride,
  LLVMModuleFlagBehaviorAppend,
  LLVMModuleFlagBehaviorAppendUnique,
} LLVMModuleFlagBehavior;
enum {
  LLVMAttributeReturnIndex = 0U,
  LLVMAttributeFunctionIndex = -1,
};
typedef unsigned LLVMAttributeIndex;
void LLVMInitializeCore(LLVMPassRegistryRef R);
void LLVMShutdown(void);
char *LLVMCreateMessage(const char *Message);
void LLVMDisposeMessage(char *Message);
typedef void (*LLVMDiagnosticHandler)(LLVMDiagnosticInfoRef, void *);
typedef void (*LLVMYieldCallback)(LLVMContextRef, void *);
LLVMContextRef LLVMContextCreate(void);
LLVMContextRef LLVMGetGlobalContext(void);
void LLVMContextSetDiagnosticHandler(LLVMContextRef C,
                                     LLVMDiagnosticHandler Handler,
                                     void *DiagnosticContext);
LLVMDiagnosticHandler LLVMContextGetDiagnosticHandler(LLVMContextRef C);
void *LLVMContextGetDiagnosticContext(LLVMContextRef C);
void LLVMContextSetYieldCallback(LLVMContextRef C, LLVMYieldCallback Callback,
                                 void *OpaqueHandle);
LLVMBool LLVMContextShouldDiscardValueNames(LLVMContextRef C);
void LLVMContextSetDiscardValueNames(LLVMContextRef C, LLVMBool Discard);
void LLVMContextDispose(LLVMContextRef C);
char *LLVMGetDiagInfoDescription(LLVMDiagnosticInfoRef DI);
LLVMDiagnosticSeverity LLVMGetDiagInfoSeverity(LLVMDiagnosticInfoRef DI);
unsigned LLVMGetMDKindIDInContext(LLVMContextRef C, const char *Name,
                                  unsigned SLen);
unsigned LLVMGetMDKindID(const char *Name, unsigned SLen);
unsigned LLVMGetEnumAttributeKindForName(const char *Name, size_t SLen);
unsigned LLVMGetLastEnumAttributeKind(void);
LLVMAttributeRef LLVMCreateEnumAttribute(LLVMContextRef C, unsigned KindID,
                                         uint64_t Val);
unsigned LLVMGetEnumAttributeKind(LLVMAttributeRef A);
uint64_t LLVMGetEnumAttributeValue(LLVMAttributeRef A);
LLVMAttributeRef LLVMCreateStringAttribute(LLVMContextRef C,
                                           const char *K, unsigned KLength,
                                           const char *V, unsigned VLength);
const char *LLVMGetStringAttributeKind(LLVMAttributeRef A, unsigned *Length);
const char *LLVMGetStringAttributeValue(LLVMAttributeRef A, unsigned *Length);
LLVMBool LLVMIsEnumAttribute(LLVMAttributeRef A);
LLVMBool LLVMIsStringAttribute(LLVMAttributeRef A);
LLVMModuleRef LLVMModuleCreateWithName(const char *ModuleID);
LLVMModuleRef LLVMModuleCreateWithNameInContext(const char *ModuleID,
                                                LLVMContextRef C);
LLVMModuleRef LLVMCloneModule(LLVMModuleRef M);
void LLVMDisposeModule(LLVMModuleRef M);
const char *LLVMGetModuleIdentifier(LLVMModuleRef M, size_t *Len);
void LLVMSetModuleIdentifier(LLVMModuleRef M, const char *Ident, size_t Len);
const char *LLVMGetSourceFileName(LLVMModuleRef M, size_t *Len);
void LLVMSetSourceFileName(LLVMModuleRef M, const char *Name, size_t Len);
const char *LLVMGetDataLayoutStr(LLVMModuleRef M);
void LLVMSetDataLayout(LLVMModuleRef M, const char *DataLayoutStr);
const char *LLVMGetTarget(LLVMModuleRef M);
void LLVMSetTarget(LLVMModuleRef M, const char *Triple);
LLVMModuleFlagEntry *LLVMCopyModuleFlagsMetadata(LLVMModuleRef M, size_t *Len);
void LLVMDisposeModuleFlagsMetadata(LLVMModuleFlagEntry *Entries);
LLVMModuleFlagBehavior
LLVMModuleFlagEntriesGetFlagBehavior(LLVMModuleFlagEntry *Entries,
                                     unsigned Index);
const char *LLVMModuleFlagEntriesGetKey(LLVMModuleFlagEntry *Entries,
                                        unsigned Index, size_t *Len);
LLVMMetadataRef LLVMModuleFlagEntriesGetMetadata(LLVMModuleFlagEntry *Entries,
                                                 unsigned Index);
LLVMMetadataRef LLVMGetModuleFlag(LLVMModuleRef M,
                                  const char *Key, size_t KeyLen);
void LLVMAddModuleFlag(LLVMModuleRef M, LLVMModuleFlagBehavior Behavior,
                       const char *Key, size_t KeyLen,
                       LLVMMetadataRef Val);
char *LLVMPrintModuleToString(LLVMModuleRef M);
const char *LLVMGetModuleInlineAsm(LLVMModuleRef M, size_t *Len);
void LLVMSetModuleInlineAsm2(LLVMModuleRef M, const char *Asm, size_t Len);
void LLVMAppendModuleInlineAsm(LLVMModuleRef M, const char *Asm, size_t Len);
LLVMValueRef LLVMGetInlineAsm(LLVMTypeRef Ty,
                              char *AsmString, size_t AsmStringSize,
                              char *Constraints, size_t ConstraintsSize,
                              LLVMBool HasSideEffects, LLVMBool IsAlignStack,
                              LLVMInlineAsmDialect Dialect);
LLVMContextRef LLVMGetModuleContext(LLVMModuleRef M);
LLVMTypeRef LLVMGetTypeByName(LLVMModuleRef M, const char *Name);
LLVMNamedMDNodeRef LLVMGetFirstNamedMetadata(LLVMModuleRef M);
LLVMNamedMDNodeRef LLVMGetLastNamedMetadata(LLVMModuleRef M);
LLVMNamedMDNodeRef LLVMGetNextNamedMetadata(LLVMNamedMDNodeRef NamedMDNode);
LLVMNamedMDNodeRef LLVMGetPreviousNamedMetadata(LLVMNamedMDNodeRef NamedMDNode);
LLVMNamedMDNodeRef LLVMGetNamedMetadata(LLVMModuleRef M,
                                        const char *Name, size_t NameLen);
LLVMNamedMDNodeRef LLVMGetOrInsertNamedMetadata(LLVMModuleRef M,
                                                const char *Name,
                                                size_t NameLen);
const char *LLVMGetNamedMetadataName(LLVMNamedMDNodeRef NamedMD,
                                     size_t *NameLen);
unsigned LLVMGetNamedMetadataNumOperands(LLVMModuleRef M, const char *Name);
void LLVMGetNamedMetadataOperands(LLVMModuleRef M, const char *Name,
                                  LLVMValueRef *Dest);
void LLVMAddNamedMetadataOperand(LLVMModuleRef M, const char *Name,
                                 LLVMValueRef Val);
const char *LLVMGetDebugLocDirectory(LLVMValueRef Val, unsigned *Length);
const char *LLVMGetDebugLocFilename(LLVMValueRef Val, unsigned *Length);
unsigned LLVMGetDebugLocLine(LLVMValueRef Val);
unsigned LLVMGetDebugLocColumn(LLVMValueRef Val);
LLVMValueRef LLVMAddFunction(LLVMModuleRef M, const char *Name,
                             LLVMTypeRef FunctionTy);
LLVMValueRef LLVMGetNamedFunction(LLVMModuleRef M, const char *Name);
LLVMValueRef LLVMGetFirstFunction(LLVMModuleRef M);
LLVMValueRef LLVMGetLastFunction(LLVMModuleRef M);
LLVMValueRef LLVMGetNextFunction(LLVMValueRef Fn);
LLVMValueRef LLVMGetPreviousFunction(LLVMValueRef Fn);
LLVMTypeKind LLVMGetTypeKind(LLVMTypeRef Ty);
LLVMBool LLVMTypeIsSized(LLVMTypeRef Ty);
LLVMContextRef LLVMGetTypeContext(LLVMTypeRef Ty);
void LLVMDumpType(LLVMTypeRef Val);
char *LLVMPrintTypeToString(LLVMTypeRef Val);
LLVMTypeRef LLVMInt1TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt8TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt16TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt32TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt64TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMIntTypeInContext(LLVMContextRef C, unsigned NumBits);
LLVMTypeRef LLVMInt1Type(void);
LLVMTypeRef LLVMInt8Type(void);
LLVMTypeRef LLVMInt16Type(void);
LLVMTypeRef LLVMInt32Type(void);
LLVMTypeRef LLVMInt64Type(void);
LLVMTypeRef LLVMInt128Type(void);
LLVMTypeRef LLVMIntType(unsigned NumBits);
unsigned LLVMGetIntTypeWidth(LLVMTypeRef IntegerTy);
LLVMTypeRef LLVMHalfTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMFloatTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMDoubleTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMX86FP80TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMFP128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMPPCFP128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMHalfType(void);
LLVMTypeRef LLVMFloatType(void);
LLVMTypeRef LLVMDoubleType(void);
LLVMTypeRef LLVMX86FP80Type(void);
LLVMTypeRef LLVMFP128Type(void);
LLVMTypeRef LLVMPPCFP128Type(void);
LLVMTypeRef LLVMFunctionType(LLVMTypeRef ReturnType,
                             LLVMTypeRef *ParamTypes, unsigned ParamCount,
                             LLVMBool IsVarArg);
LLVMBool LLVMIsFunctionVarArg(LLVMTypeRef FunctionTy);
LLVMTypeRef LLVMGetReturnType(LLVMTypeRef FunctionTy);
unsigned LLVMCountParamTypes(LLVMTypeRef FunctionTy);
void LLVMGetParamTypes(LLVMTypeRef FunctionTy, LLVMTypeRef *Dest);
LLVMTypeRef LLVMStructTypeInContext(LLVMContextRef C, LLVMTypeRef *ElementTypes,
                                    unsigned ElementCount, LLVMBool Packed);
LLVMTypeRef LLVMStructType(LLVMTypeRef *ElementTypes, unsigned ElementCount,
                           LLVMBool Packed);
LLVMTypeRef LLVMStructCreateNamed(LLVMContextRef C, const char *Name);
const char *LLVMGetStructName(LLVMTypeRef Ty);
void LLVMStructSetBody(LLVMTypeRef StructTy, LLVMTypeRef *ElementTypes,
                       unsigned ElementCount, LLVMBool Packed);
unsigned LLVMCountStructElementTypes(LLVMTypeRef StructTy);
void LLVMGetStructElementTypes(LLVMTypeRef StructTy, LLVMTypeRef *Dest);
LLVMTypeRef LLVMStructGetTypeAtIndex(LLVMTypeRef StructTy, unsigned i);
LLVMBool LLVMIsPackedStruct(LLVMTypeRef StructTy);
LLVMBool LLVMIsOpaqueStruct(LLVMTypeRef StructTy);
LLVMBool LLVMIsLiteralStruct(LLVMTypeRef StructTy);
LLVMTypeRef LLVMGetElementType(LLVMTypeRef Ty);
void LLVMGetSubtypes(LLVMTypeRef Tp, LLVMTypeRef *Arr);
unsigned LLVMGetNumContainedTypes(LLVMTypeRef Tp);
LLVMTypeRef LLVMArrayType(LLVMTypeRef ElementType, unsigned ElementCount);
unsigned LLVMGetArrayLength(LLVMTypeRef ArrayTy);
LLVMTypeRef LLVMPointerType(LLVMTypeRef ElementType, unsigned AddressSpace);
unsigned LLVMGetPointerAddressSpace(LLVMTypeRef PointerTy);
LLVMTypeRef LLVMVectorType(LLVMTypeRef ElementType, unsigned ElementCount);
unsigned LLVMGetVectorSize(LLVMTypeRef VectorTy);
LLVMTypeRef LLVMVoidTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMLabelTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMX86MMXTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMTokenTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMMetadataTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMVoidType(void);
LLVMTypeRef LLVMLabelType(void);
LLVMTypeRef LLVMX86MMXType(void);
LLVMTypeRef LLVMTypeOf(LLVMValueRef Val);
LLVMValueRef LLVMIsAArgument               (LLVMValueRef Val);
LLVMValueRef LLVMIsABasicBlock             (LLVMValueRef Val);
LLVMValueRef LLVMIsAInlineAsm              (LLVMValueRef Val);
LLVMValueRef LLVMIsAUser                   (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstant               (LLVMValueRef Val);
LLVMValueRef LLVMIsABlockAddress           (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantAggregateZero  (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantArray          (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantDataSequential (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantDataArray      (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantDataVector     (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantExpr           (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantFP             (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantInt            (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantPointerNull    (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantStruct         (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantTokenNone      (LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantVector         (LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalValue            (LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalAlias            (LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalIFunc            (LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalObject           (LLVMValueRef Val);
LLVMValueRef LLVMIsAFunction               (LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalVariable         (LLVMValueRef Val);
LLVMValueRef LLVMIsAUndefValue             (LLVMValueRef Val);
LLVMValueRef LLVMIsAInstruction            (LLVMValueRef Val);
LLVMValueRef LLVMIsABinaryOperator         (LLVMValueRef Val);
LLVMValueRef LLVMIsACallInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsAIntrinsicInst          (LLVMValueRef Val);
LLVMValueRef LLVMIsADbgInfoIntrinsic       (LLVMValueRef Val);
LLVMValueRef LLVMIsADbgVariableIntrinsic   (LLVMValueRef Val);
LLVMValueRef LLVMIsADbgDeclareInst         (LLVMValueRef Val);
LLVMValueRef LLVMIsADbgLabelInst           (LLVMValueRef Val);
LLVMValueRef LLVMIsAMemIntrinsic           (LLVMValueRef Val);
LLVMValueRef LLVMIsAMemCpyInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAMemMoveInst            (LLVMValueRef Val);
LLVMValueRef LLVMIsAMemSetInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsACmpInst                (LLVMValueRef Val);
LLVMValueRef LLVMIsAFCmpInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsAICmpInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsAExtractElementInst     (LLVMValueRef Val);
LLVMValueRef LLVMIsAGetElementPtrInst      (LLVMValueRef Val);
LLVMValueRef LLVMIsAInsertElementInst      (LLVMValueRef Val);
LLVMValueRef LLVMIsAInsertValueInst        (LLVMValueRef Val);
LLVMValueRef LLVMIsALandingPadInst         (LLVMValueRef Val);
LLVMValueRef LLVMIsAPHINode                (LLVMValueRef Val);
LLVMValueRef LLVMIsASelectInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAShuffleVectorInst      (LLVMValueRef Val);
LLVMValueRef LLVMIsAStoreInst              (LLVMValueRef Val);
LLVMValueRef LLVMIsABranchInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAIndirectBrInst         (LLVMValueRef Val);
LLVMValueRef LLVMIsAInvokeInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAReturnInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsASwitchInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAUnreachableInst        (LLVMValueRef Val);
LLVMValueRef LLVMIsAResumeInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsACleanupReturnInst      (LLVMValueRef Val);
LLVMValueRef LLVMIsACatchReturnInst        (LLVMValueRef Val);
LLVMValueRef LLVMIsAFuncletPadInst         (LLVMValueRef Val);
LLVMValueRef LLVMIsACatchPadInst           (LLVMValueRef Val);
LLVMValueRef LLVMIsACleanupPadInst         (LLVMValueRef Val);
LLVMValueRef LLVMIsAUnaryInstruction       (LLVMValueRef Val);
LLVMValueRef LLVMIsAAllocaInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsACastInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsAAddrSpaceCastInst      (LLVMValueRef Val);
LLVMValueRef LLVMIsABitCastInst            (LLVMValueRef Val);
LLVMValueRef LLVMIsAFPExtInst              (LLVMValueRef Val);
LLVMValueRef LLVMIsAFPToSIInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAFPToUIInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAFPTruncInst            (LLVMValueRef Val);
LLVMValueRef LLVMIsAIntToPtrInst           (LLVMValueRef Val);
LLVMValueRef LLVMIsAPtrToIntInst           (LLVMValueRef Val);
LLVMValueRef LLVMIsASExtInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsASIToFPInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsATruncInst              (LLVMValueRef Val);
LLVMValueRef LLVMIsAUIToFPInst             (LLVMValueRef Val);
LLVMValueRef LLVMIsAZExtInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsAExtractValueInst       (LLVMValueRef Val);
LLVMValueRef LLVMIsALoadInst               (LLVMValueRef Val);
LLVMValueRef LLVMIsAVAArgInst              (LLVMValueRef Val);
LLVMValueKind LLVMGetValueKind(LLVMValueRef Val);
const char *LLVMGetValueName2(LLVMValueRef Val, size_t *Length);
void LLVMSetValueName2(LLVMValueRef Val, const char *Name, size_t NameLen);
void LLVMDumpValue(LLVMValueRef Val);
char *LLVMPrintValueToString(LLVMValueRef Val);
void LLVMReplaceAllUsesWith(LLVMValueRef OldVal, LLVMValueRef NewVal);
LLVMBool LLVMIsConstant(LLVMValueRef Val);
LLVMBool LLVMIsUndef(LLVMValueRef Val);
LLVMValueRef LLVMIsAMDNode(LLVMValueRef Val);
LLVMValueRef LLVMIsAMDString(LLVMValueRef Val);
const char *LLVMGetValueName(LLVMValueRef Val);
void LLVMSetValueName(LLVMValueRef Val, const char *Name);
LLVMUseRef LLVMGetFirstUse(LLVMValueRef Val);
LLVMUseRef LLVMGetNextUse(LLVMUseRef U);
LLVMValueRef LLVMGetUser(LLVMUseRef U);
LLVMValueRef LLVMGetUsedValue(LLVMUseRef U);
LLVMValueRef LLVMGetOperand(LLVMValueRef Val, unsigned Index);
LLVMUseRef LLVMGetOperandUse(LLVMValueRef Val, unsigned Index);
void LLVMSetOperand(LLVMValueRef User, unsigned Index, LLVMValueRef Val);
int LLVMGetNumOperands(LLVMValueRef Val);
LLVMValueRef LLVMConstNull(LLVMTypeRef Ty);
LLVMValueRef LLVMConstAllOnes(LLVMTypeRef Ty);
LLVMValueRef LLVMGetUndef(LLVMTypeRef Ty);
LLVMBool LLVMIsNull(LLVMValueRef Val);
LLVMValueRef LLVMConstPointerNull(LLVMTypeRef Ty);
LLVMValueRef LLVMConstInt(LLVMTypeRef IntTy, unsigned long long N,
                          LLVMBool SignExtend);
LLVMValueRef LLVMConstIntOfArbitraryPrecision(LLVMTypeRef IntTy,
                                              unsigned NumWords,
                                              const uint64_t Words[]);
LLVMValueRef LLVMConstIntOfString(LLVMTypeRef IntTy, const char *Text,
                                  uint8_t Radix);
LLVMValueRef LLVMConstIntOfStringAndSize(LLVMTypeRef IntTy, const char *Text,
                                         unsigned SLen, uint8_t Radix);
LLVMValueRef LLVMConstReal(LLVMTypeRef RealTy, double N);
LLVMValueRef LLVMConstRealOfString(LLVMTypeRef RealTy, const char *Text);
LLVMValueRef LLVMConstRealOfStringAndSize(LLVMTypeRef RealTy, const char *Text,
                                          unsigned SLen);
unsigned long long LLVMConstIntGetZExtValue(LLVMValueRef ConstantVal);
long long LLVMConstIntGetSExtValue(LLVMValueRef ConstantVal);
double LLVMConstRealGetDouble(LLVMValueRef ConstantVal, LLVMBool *losesInfo);
LLVMValueRef LLVMConstStringInContext(LLVMContextRef C, const char *Str,
                                      unsigned Length, LLVMBool DontNullTerminate);
LLVMValueRef LLVMConstString(const char *Str, unsigned Length,
                             LLVMBool DontNullTerminate);
LLVMBool LLVMIsConstantString(LLVMValueRef c);
const char *LLVMGetAsString(LLVMValueRef c, size_t *Length);
LLVMValueRef LLVMConstStructInContext(LLVMContextRef C,
                                      LLVMValueRef *ConstantVals,
                                      unsigned Count, LLVMBool Packed);
LLVMValueRef LLVMConstStruct(LLVMValueRef *ConstantVals, unsigned Count,
                             LLVMBool Packed);
LLVMValueRef LLVMConstArray(LLVMTypeRef ElementTy,
                            LLVMValueRef *ConstantVals, unsigned Length);
LLVMValueRef LLVMConstNamedStruct(LLVMTypeRef StructTy,
                                  LLVMValueRef *ConstantVals,
                                  unsigned Count);
LLVMValueRef LLVMGetElementAsConstant(LLVMValueRef C, unsigned idx);
LLVMValueRef LLVMConstVector(LLVMValueRef *ScalarConstantVals, unsigned Size);
LLVMOpcode LLVMGetConstOpcode(LLVMValueRef ConstantVal);
LLVMValueRef LLVMAlignOf(LLVMTypeRef Ty);
LLVMValueRef LLVMSizeOf(LLVMTypeRef Ty);
LLVMValueRef LLVMConstNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNSWNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNUWNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstFNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNot(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNUWAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNUWSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNUWMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstUDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstExactUDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstExactSDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstURem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSRem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFRem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstAnd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstOr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstXor(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstICmp(LLVMIntPredicate Predicate,
                           LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFCmp(LLVMRealPredicate Predicate,
                           LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstShl(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstLShr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstAShr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstGEP(LLVMValueRef ConstantVal,
                          LLVMValueRef *ConstantIndices, unsigned NumIndices);
LLVMValueRef LLVMConstGEP2(LLVMTypeRef Ty, LLVMValueRef ConstantVal,
                           LLVMValueRef *ConstantIndices, unsigned NumIndices);
LLVMValueRef LLVMConstInBoundsGEP(LLVMValueRef ConstantVal,
                                  LLVMValueRef *ConstantIndices,
                                  unsigned NumIndices);
LLVMValueRef LLVMConstInBoundsGEP2(LLVMTypeRef Ty, LLVMValueRef ConstantVal,
                                   LLVMValueRef *ConstantIndices,
                                   unsigned NumIndices);
LLVMValueRef LLVMConstTrunc(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstZExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPTrunc(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstUIToFP(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSIToFP(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPToUI(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPToSI(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstPtrToInt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstIntToPtr(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstBitCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstAddrSpaceCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstZExtOrBitCast(LLVMValueRef ConstantVal,
                                    LLVMTypeRef ToType);
LLVMValueRef LLVMConstSExtOrBitCast(LLVMValueRef ConstantVal,
                                    LLVMTypeRef ToType);
LLVMValueRef LLVMConstTruncOrBitCast(LLVMValueRef ConstantVal,
                                     LLVMTypeRef ToType);
LLVMValueRef LLVMConstPointerCast(LLVMValueRef ConstantVal,
                                  LLVMTypeRef ToType);
LLVMValueRef LLVMConstIntCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType,
                              LLVMBool isSigned);
LLVMValueRef LLVMConstFPCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSelect(LLVMValueRef ConstantCondition,
                             LLVMValueRef ConstantIfTrue,
                             LLVMValueRef ConstantIfFalse);
LLVMValueRef LLVMConstExtractElement(LLVMValueRef VectorConstant,
                                     LLVMValueRef IndexConstant);
LLVMValueRef LLVMConstInsertElement(LLVMValueRef VectorConstant,
                                    LLVMValueRef ElementValueConstant,
                                    LLVMValueRef IndexConstant);
LLVMValueRef LLVMConstShuffleVector(LLVMValueRef VectorAConstant,
                                    LLVMValueRef VectorBConstant,
                                    LLVMValueRef MaskConstant);
LLVMValueRef LLVMConstExtractValue(LLVMValueRef AggConstant, unsigned *IdxList,
                                   unsigned NumIdx);
LLVMValueRef LLVMConstInsertValue(LLVMValueRef AggConstant,
                                  LLVMValueRef ElementValueConstant,
                                  unsigned *IdxList, unsigned NumIdx);
LLVMValueRef LLVMBlockAddress(LLVMValueRef F, LLVMBasicBlockRef BB);
LLVMValueRef LLVMConstInlineAsm(LLVMTypeRef Ty,
                                const char *AsmString, const char *Constraints,
                                LLVMBool HasSideEffects, LLVMBool IsAlignStack);
LLVMModuleRef LLVMGetGlobalParent(LLVMValueRef Global);
LLVMBool LLVMIsDeclaration(LLVMValueRef Global);
LLVMLinkage LLVMGetLinkage(LLVMValueRef Global);
void LLVMSetLinkage(LLVMValueRef Global, LLVMLinkage Linkage);
const char *LLVMGetSection(LLVMValueRef Global);
void LLVMSetSection(LLVMValueRef Global, const char *Section);
LLVMVisibility LLVMGetVisibility(LLVMValueRef Global);
void LLVMSetVisibility(LLVMValueRef Global, LLVMVisibility Viz);
LLVMDLLStorageClass LLVMGetDLLStorageClass(LLVMValueRef Global);
void LLVMSetDLLStorageClass(LLVMValueRef Global, LLVMDLLStorageClass Class);
LLVMUnnamedAddr LLVMGetUnnamedAddress(LLVMValueRef Global);
void LLVMSetUnnamedAddress(LLVMValueRef Global, LLVMUnnamedAddr UnnamedAddr);
LLVMTypeRef LLVMGlobalGetValueType(LLVMValueRef Global);
LLVMBool LLVMHasUnnamedAddr(LLVMValueRef Global);
void LLVMSetUnnamedAddr(LLVMValueRef Global, LLVMBool HasUnnamedAddr);
unsigned LLVMGetAlignment(LLVMValueRef V);
void LLVMSetAlignment(LLVMValueRef V, unsigned Bytes);
void LLVMGlobalSetMetadata(LLVMValueRef Global, unsigned Kind,
                           LLVMMetadataRef MD);
void LLVMGlobalEraseMetadata(LLVMValueRef Global, unsigned Kind);
void LLVMGlobalClearMetadata(LLVMValueRef Global);
LLVMValueMetadataEntry *LLVMGlobalCopyAllMetadata(LLVMValueRef Value,
                                                  size_t *NumEntries);
void LLVMDisposeValueMetadataEntries(LLVMValueMetadataEntry *Entries);
unsigned LLVMValueMetadataEntriesGetKind(LLVMValueMetadataEntry *Entries,
                                         unsigned Index);
LLVMMetadataRef
LLVMValueMetadataEntriesGetMetadata(LLVMValueMetadataEntry *Entries,
                                    unsigned Index);
LLVMValueRef LLVMAddGlobal(LLVMModuleRef M, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMAddGlobalInAddressSpace(LLVMModuleRef M, LLVMTypeRef Ty,
                                         const char *Name,
                                         unsigned AddressSpace);
LLVMValueRef LLVMGetNamedGlobal(LLVMModuleRef M, const char *Name);
LLVMValueRef LLVMGetFirstGlobal(LLVMModuleRef M);
LLVMValueRef LLVMGetLastGlobal(LLVMModuleRef M);
LLVMValueRef LLVMGetNextGlobal(LLVMValueRef GlobalVar);
LLVMValueRef LLVMGetPreviousGlobal(LLVMValueRef GlobalVar);
void LLVMDeleteGlobal(LLVMValueRef GlobalVar);
LLVMValueRef LLVMGetInitializer(LLVMValueRef GlobalVar);
void LLVMSetInitializer(LLVMValueRef GlobalVar, LLVMValueRef ConstantVal);
LLVMBool LLVMIsThreadLocal(LLVMValueRef GlobalVar);
void LLVMSetThreadLocal(LLVMValueRef GlobalVar, LLVMBool IsThreadLocal);
LLVMBool LLVMIsGlobalConstant(LLVMValueRef GlobalVar);
void LLVMSetGlobalConstant(LLVMValueRef GlobalVar, LLVMBool IsConstant);
LLVMThreadLocalMode LLVMGetThreadLocalMode(LLVMValueRef GlobalVar);
void LLVMSetThreadLocalMode(LLVMValueRef GlobalVar, LLVMThreadLocalMode Mode);
LLVMBool LLVMIsExternallyInitialized(LLVMValueRef GlobalVar);
void LLVMSetExternallyInitialized(LLVMValueRef GlobalVar, LLVMBool IsExtInit);
LLVMValueRef LLVMAddAlias(LLVMModuleRef M, LLVMTypeRef Ty, LLVMValueRef Aliasee,
                          const char *Name);
LLVMValueRef LLVMGetNamedGlobalAlias(LLVMModuleRef M,
                                     const char *Name, size_t NameLen);
LLVMValueRef LLVMGetFirstGlobalAlias(LLVMModuleRef M);
LLVMValueRef LLVMGetLastGlobalAlias(LLVMModuleRef M);
LLVMValueRef LLVMGetNextGlobalAlias(LLVMValueRef GA);
LLVMValueRef LLVMGetPreviousGlobalAlias(LLVMValueRef GA);
LLVMValueRef LLVMAliasGetAliasee(LLVMValueRef Alias);
void LLVMAliasSetAliasee(LLVMValueRef Alias, LLVMValueRef Aliasee);
void LLVMDeleteFunction(LLVMValueRef Fn);
LLVMBool LLVMHasPersonalityFn(LLVMValueRef Fn);
LLVMValueRef LLVMGetPersonalityFn(LLVMValueRef Fn);
void LLVMSetPersonalityFn(LLVMValueRef Fn, LLVMValueRef PersonalityFn);
unsigned LLVMGetIntrinsicID(LLVMValueRef Fn);
LLVMValueRef LLVMGetIntrinsicDeclaration(LLVMModuleRef Mod,
                                         unsigned ID,
                                         LLVMTypeRef *ParamTypes,
                                         size_t ParamCount);
LLVMTypeRef LLVMIntrinsicGetType(LLVMContextRef Ctx, unsigned ID,
                                 LLVMTypeRef *ParamTypes, size_t ParamCount);
const char *LLVMIntrinsicGetName(unsigned ID, size_t *NameLength);
const char *LLVMIntrinsicCopyOverloadedName(unsigned ID,
                                            LLVMTypeRef *ParamTypes,
                                            size_t ParamCount,
                                            size_t *NameLength);
LLVMBool LLVMIntrinsicIsOverloaded(unsigned ID);
unsigned LLVMGetFunctionCallConv(LLVMValueRef Fn);
void LLVMSetFunctionCallConv(LLVMValueRef Fn, unsigned CC);
const char *LLVMGetGC(LLVMValueRef Fn);
void LLVMSetGC(LLVMValueRef Fn, const char *Name);
void LLVMAddAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx,
                             LLVMAttributeRef A);
unsigned LLVMGetAttributeCountAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx);
void LLVMGetAttributesAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx,
                              LLVMAttributeRef *Attrs);
LLVMAttributeRef LLVMGetEnumAttributeAtIndex(LLVMValueRef F,
                                             LLVMAttributeIndex Idx,
                                             unsigned KindID);
LLVMAttributeRef LLVMGetStringAttributeAtIndex(LLVMValueRef F,
                                               LLVMAttributeIndex Idx,
                                               const char *K, unsigned KLen);
void LLVMRemoveEnumAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx,
                                    unsigned KindID);
void LLVMRemoveStringAttributeAtIndex(LLVMValueRef F, LLVMAttributeIndex Idx,
                                      const char *K, unsigned KLen);
void LLVMAddTargetDependentFunctionAttr(LLVMValueRef Fn, const char *A,
                                        const char *V);
unsigned LLVMCountParams(LLVMValueRef Fn);
void LLVMGetParams(LLVMValueRef Fn, LLVMValueRef *Params);
LLVMValueRef LLVMGetParam(LLVMValueRef Fn, unsigned Index);
LLVMValueRef LLVMGetParamParent(LLVMValueRef Inst);
LLVMValueRef LLVMGetFirstParam(LLVMValueRef Fn);
LLVMValueRef LLVMGetLastParam(LLVMValueRef Fn);
LLVMValueRef LLVMGetNextParam(LLVMValueRef Arg);
LLVMValueRef LLVMGetPreviousParam(LLVMValueRef Arg);
void LLVMSetParamAlignment(LLVMValueRef Arg, unsigned Align);
LLVMValueRef LLVMMDStringInContext(LLVMContextRef C, const char *Str,
                                   unsigned SLen);
LLVMValueRef LLVMMDString(const char *Str, unsigned SLen);
LLVMValueRef LLVMMDNodeInContext(LLVMContextRef C, LLVMValueRef *Vals,
                                 unsigned Count);
LLVMValueRef LLVMMDNode(LLVMValueRef *Vals, unsigned Count);
LLVMValueRef LLVMMetadataAsValue(LLVMContextRef C, LLVMMetadataRef MD);
LLVMMetadataRef LLVMValueAsMetadata(LLVMValueRef Val);
const char *LLVMGetMDString(LLVMValueRef V, unsigned *Length);
unsigned LLVMGetMDNodeNumOperands(LLVMValueRef V);
void LLVMGetMDNodeOperands(LLVMValueRef V, LLVMValueRef *Dest);
LLVMValueRef LLVMBasicBlockAsValue(LLVMBasicBlockRef BB);
LLVMBool LLVMValueIsBasicBlock(LLVMValueRef Val);
LLVMBasicBlockRef LLVMValueAsBasicBlock(LLVMValueRef Val);
const char *LLVMGetBasicBlockName(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetBasicBlockParent(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetBasicBlockTerminator(LLVMBasicBlockRef BB);
unsigned LLVMCountBasicBlocks(LLVMValueRef Fn);
void LLVMGetBasicBlocks(LLVMValueRef Fn, LLVMBasicBlockRef *BasicBlocks);
LLVMBasicBlockRef LLVMGetFirstBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMGetLastBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMGetNextBasicBlock(LLVMBasicBlockRef BB);
LLVMBasicBlockRef LLVMGetPreviousBasicBlock(LLVMBasicBlockRef BB);
LLVMBasicBlockRef LLVMGetEntryBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMCreateBasicBlockInContext(LLVMContextRef C,
                                                const char *Name);
LLVMBasicBlockRef LLVMAppendBasicBlockInContext(LLVMContextRef C,
                                                LLVMValueRef Fn,
                                                const char *Name);
LLVMBasicBlockRef LLVMAppendBasicBlock(LLVMValueRef Fn, const char *Name);
LLVMBasicBlockRef LLVMInsertBasicBlockInContext(LLVMContextRef C,
                                                LLVMBasicBlockRef BB,
                                                const char *Name);
LLVMBasicBlockRef LLVMInsertBasicBlock(LLVMBasicBlockRef InsertBeforeBB,
                                       const char *Name);
void LLVMDeleteBasicBlock(LLVMBasicBlockRef BB);
void LLVMRemoveBasicBlockFromParent(LLVMBasicBlockRef BB);
void LLVMMoveBasicBlockBefore(LLVMBasicBlockRef BB, LLVMBasicBlockRef MovePos);
void LLVMMoveBasicBlockAfter(LLVMBasicBlockRef BB, LLVMBasicBlockRef MovePos);
LLVMValueRef LLVMGetFirstInstruction(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetLastInstruction(LLVMBasicBlockRef BB);
int LLVMHasMetadata(LLVMValueRef Val);
LLVMValueRef LLVMGetMetadata(LLVMValueRef Val, unsigned KindID);
void LLVMSetMetadata(LLVMValueRef Val, unsigned KindID, LLVMValueRef Node);
LLVMValueMetadataEntry *
LLVMInstructionGetAllMetadataOtherThanDebugLoc(LLVMValueRef Instr,
                                               size_t *NumEntries);
LLVMBasicBlockRef LLVMGetInstructionParent(LLVMValueRef Inst);
LLVMValueRef LLVMGetNextInstruction(LLVMValueRef Inst);
LLVMValueRef LLVMGetPreviousInstruction(LLVMValueRef Inst);
void LLVMInstructionRemoveFromParent(LLVMValueRef Inst);
void LLVMInstructionEraseFromParent(LLVMValueRef Inst);
LLVMOpcode LLVMGetInstructionOpcode(LLVMValueRef Inst);
LLVMIntPredicate LLVMGetICmpPredicate(LLVMValueRef Inst);
LLVMRealPredicate LLVMGetFCmpPredicate(LLVMValueRef Inst);
LLVMValueRef LLVMInstructionClone(LLVMValueRef Inst);
LLVMValueRef LLVMIsATerminatorInst(LLVMValueRef Inst);
unsigned LLVMGetNumArgOperands(LLVMValueRef Instr);
void LLVMSetInstructionCallConv(LLVMValueRef Instr, unsigned CC);
unsigned LLVMGetInstructionCallConv(LLVMValueRef Instr);
void LLVMSetInstrParamAlignment(LLVMValueRef Instr, unsigned index,
                                unsigned Align);
void LLVMAddCallSiteAttribute(LLVMValueRef C, LLVMAttributeIndex Idx,
                              LLVMAttributeRef A);
unsigned LLVMGetCallSiteAttributeCount(LLVMValueRef C, LLVMAttributeIndex Idx);
void LLVMGetCallSiteAttributes(LLVMValueRef C, LLVMAttributeIndex Idx,
                               LLVMAttributeRef *Attrs);
LLVMAttributeRef LLVMGetCallSiteEnumAttribute(LLVMValueRef C,
                                              LLVMAttributeIndex Idx,
                                              unsigned KindID);
LLVMAttributeRef LLVMGetCallSiteStringAttribute(LLVMValueRef C,
                                                LLVMAttributeIndex Idx,
                                                const char *K, unsigned KLen);
void LLVMRemoveCallSiteEnumAttribute(LLVMValueRef C, LLVMAttributeIndex Idx,
                                     unsigned KindID);
void LLVMRemoveCallSiteStringAttribute(LLVMValueRef C, LLVMAttributeIndex Idx,
                                       const char *K, unsigned KLen);
LLVMTypeRef LLVMGetCalledFunctionType(LLVMValueRef C);
LLVMValueRef LLVMGetCalledValue(LLVMValueRef Instr);
LLVMBool LLVMIsTailCall(LLVMValueRef CallInst);
void LLVMSetTailCall(LLVMValueRef CallInst, LLVMBool IsTailCall);
LLVMBasicBlockRef LLVMGetNormalDest(LLVMValueRef InvokeInst);
LLVMBasicBlockRef LLVMGetUnwindDest(LLVMValueRef InvokeInst);
void LLVMSetNormalDest(LLVMValueRef InvokeInst, LLVMBasicBlockRef B);
void LLVMSetUnwindDest(LLVMValueRef InvokeInst, LLVMBasicBlockRef B);
unsigned LLVMGetNumSuccessors(LLVMValueRef Term);
LLVMBasicBlockRef LLVMGetSuccessor(LLVMValueRef Term, unsigned i);
void LLVMSetSuccessor(LLVMValueRef Term, unsigned i, LLVMBasicBlockRef block);
LLVMBool LLVMIsConditional(LLVMValueRef Branch);
LLVMValueRef LLVMGetCondition(LLVMValueRef Branch);
void LLVMSetCondition(LLVMValueRef Branch, LLVMValueRef Cond);
LLVMBasicBlockRef LLVMGetSwitchDefaultDest(LLVMValueRef SwitchInstr);
LLVMTypeRef LLVMGetAllocatedType(LLVMValueRef Alloca);
LLVMBool LLVMIsInBounds(LLVMValueRef GEP);
void LLVMSetIsInBounds(LLVMValueRef GEP, LLVMBool InBounds);
void LLVMAddIncoming(LLVMValueRef PhiNode, LLVMValueRef *IncomingValues,
                     LLVMBasicBlockRef *IncomingBlocks, unsigned Count);
unsigned LLVMCountIncoming(LLVMValueRef PhiNode);
LLVMValueRef LLVMGetIncomingValue(LLVMValueRef PhiNode, unsigned Index);
LLVMBasicBlockRef LLVMGetIncomingBlock(LLVMValueRef PhiNode, unsigned Index);
unsigned LLVMGetNumIndices(LLVMValueRef Inst);
const unsigned *LLVMGetIndices(LLVMValueRef Inst);
LLVMBuilderRef LLVMCreateBuilderInContext(LLVMContextRef C);
LLVMBuilderRef LLVMCreateBuilder(void);
void LLVMPositionBuilder(LLVMBuilderRef Builder, LLVMBasicBlockRef Block,
                         LLVMValueRef Instr);
void LLVMPositionBuilderBefore(LLVMBuilderRef Builder, LLVMValueRef Instr);
void LLVMPositionBuilderAtEnd(LLVMBuilderRef Builder, LLVMBasicBlockRef Block);
LLVMBasicBlockRef LLVMGetInsertBlock(LLVMBuilderRef Builder);
void LLVMClearInsertionPosition(LLVMBuilderRef Builder);
void LLVMInsertIntoBuilder(LLVMBuilderRef Builder, LLVMValueRef Instr);
void LLVMInsertIntoBuilderWithName(LLVMBuilderRef Builder, LLVMValueRef Instr,
                                   const char *Name);
void LLVMDisposeBuilder(LLVMBuilderRef Builder);
void LLVMSetCurrentDebugLocation(LLVMBuilderRef Builder, LLVMValueRef L);
LLVMValueRef LLVMGetCurrentDebugLocation(LLVMBuilderRef Builder);
void LLVMSetInstDebugLocation(LLVMBuilderRef Builder, LLVMValueRef Inst);
LLVMValueRef LLVMBuildRetVoid(LLVMBuilderRef);
LLVMValueRef LLVMBuildRet(LLVMBuilderRef, LLVMValueRef V);
LLVMValueRef LLVMBuildAggregateRet(LLVMBuilderRef, LLVMValueRef *RetVals,
                                   unsigned N);
LLVMValueRef LLVMBuildBr(LLVMBuilderRef, LLVMBasicBlockRef Dest);
LLVMValueRef LLVMBuildCondBr(LLVMBuilderRef, LLVMValueRef If,
                             LLVMBasicBlockRef Then, LLVMBasicBlockRef Else);
LLVMValueRef LLVMBuildSwitch(LLVMBuilderRef, LLVMValueRef V,
                             LLVMBasicBlockRef Else, unsigned NumCases);
LLVMValueRef LLVMBuildIndirectBr(LLVMBuilderRef B, LLVMValueRef Addr,
                                 unsigned NumDests);
LLVMValueRef LLVMBuildInvoke(LLVMBuilderRef, LLVMValueRef Fn,
                             LLVMValueRef *Args, unsigned NumArgs,
                             LLVMBasicBlockRef Then, LLVMBasicBlockRef Catch,
                             const char *Name);
LLVMValueRef LLVMBuildInvoke2(LLVMBuilderRef, LLVMTypeRef Ty, LLVMValueRef Fn,
                              LLVMValueRef *Args, unsigned NumArgs,
                              LLVMBasicBlockRef Then, LLVMBasicBlockRef Catch,
                              const char *Name);
LLVMValueRef LLVMBuildUnreachable(LLVMBuilderRef);
LLVMValueRef LLVMBuildResume(LLVMBuilderRef B, LLVMValueRef Exn);
LLVMValueRef LLVMBuildLandingPad(LLVMBuilderRef B, LLVMTypeRef Ty,
                                 LLVMValueRef PersFn, unsigned NumClauses,
                                 const char *Name);
LLVMValueRef LLVMBuildCleanupRet(LLVMBuilderRef B, LLVMValueRef CatchPad,
                                 LLVMBasicBlockRef BB);
LLVMValueRef LLVMBuildCatchRet(LLVMBuilderRef B, LLVMValueRef CatchPad,
                               LLVMBasicBlockRef BB);
LLVMValueRef LLVMBuildCatchPad(LLVMBuilderRef B, LLVMValueRef ParentPad,
                               LLVMValueRef *Args, unsigned NumArgs,
                               const char *Name);
LLVMValueRef LLVMBuildCleanupPad(LLVMBuilderRef B, LLVMValueRef ParentPad,
                                 LLVMValueRef *Args, unsigned NumArgs,
                                 const char *Name);
LLVMValueRef LLVMBuildCatchSwitch(LLVMBuilderRef B, LLVMValueRef ParentPad,
                                  LLVMBasicBlockRef UnwindBB,
                                  unsigned NumHandlers, const char *Name);
void LLVMAddCase(LLVMValueRef Switch, LLVMValueRef OnVal,
                 LLVMBasicBlockRef Dest);
void LLVMAddDestination(LLVMValueRef IndirectBr, LLVMBasicBlockRef Dest);
unsigned LLVMGetNumClauses(LLVMValueRef LandingPad);
LLVMValueRef LLVMGetClause(LLVMValueRef LandingPad, unsigned Idx);
void LLVMAddClause(LLVMValueRef LandingPad, LLVMValueRef ClauseVal);
LLVMBool LLVMIsCleanup(LLVMValueRef LandingPad);
void LLVMSetCleanup(LLVMValueRef LandingPad, LLVMBool Val);
void LLVMAddHandler(LLVMValueRef CatchSwitch, LLVMBasicBlockRef Dest);
unsigned LLVMGetNumHandlers(LLVMValueRef CatchSwitch);
void LLVMGetHandlers(LLVMValueRef CatchSwitch, LLVMBasicBlockRef *Handlers);
LLVMValueRef LLVMGetArgOperand(LLVMValueRef Funclet, unsigned i);
void LLVMSetArgOperand(LLVMValueRef Funclet, unsigned i, LLVMValueRef value);
LLVMValueRef LLVMGetParentCatchSwitch(LLVMValueRef CatchPad);
void LLVMSetParentCatchSwitch(LLVMValueRef CatchPad, LLVMValueRef CatchSwitch);
LLVMValueRef LLVMBuildAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildNSWAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildNUWAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildFAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildNSWSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildNUWSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildFSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildNSWMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildNUWMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildFMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildUDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildExactUDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                                const char *Name);
LLVMValueRef LLVMBuildSDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildExactSDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                                const char *Name);
LLVMValueRef LLVMBuildFDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildURem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildSRem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildFRem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildShl(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildLShr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildAShr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildAnd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildOr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildXor(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildBinOp(LLVMBuilderRef B, LLVMOpcode Op,
                            LLVMValueRef LHS, LLVMValueRef RHS,
                            const char *Name);
LLVMValueRef LLVMBuildNeg(LLVMBuilderRef, LLVMValueRef V, const char *Name);
LLVMValueRef LLVMBuildNSWNeg(LLVMBuilderRef B, LLVMValueRef V,
                             const char *Name);
LLVMValueRef LLVMBuildNUWNeg(LLVMBuilderRef B, LLVMValueRef V,
                             const char *Name);
LLVMValueRef LLVMBuildFNeg(LLVMBuilderRef, LLVMValueRef V, const char *Name);
LLVMValueRef LLVMBuildNot(LLVMBuilderRef, LLVMValueRef V, const char *Name);
LLVMValueRef LLVMBuildMalloc(LLVMBuilderRef, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMBuildArrayMalloc(LLVMBuilderRef, LLVMTypeRef Ty,
                                  LLVMValueRef Val, const char *Name);
LLVMValueRef LLVMBuildMemSet(LLVMBuilderRef B, LLVMValueRef Ptr,
                             LLVMValueRef Val, LLVMValueRef Len,
                             unsigned Align);
LLVMValueRef LLVMBuildMemCpy(LLVMBuilderRef B,
                             LLVMValueRef Dst, unsigned DstAlign,
                             LLVMValueRef Src, unsigned SrcAlign,
                             LLVMValueRef Size);
LLVMValueRef LLVMBuildMemMove(LLVMBuilderRef B,
                              LLVMValueRef Dst, unsigned DstAlign,
                              LLVMValueRef Src, unsigned SrcAlign,
                              LLVMValueRef Size);
LLVMValueRef LLVMBuildAlloca(LLVMBuilderRef, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMBuildArrayAlloca(LLVMBuilderRef, LLVMTypeRef Ty,
                                  LLVMValueRef Val, const char *Name);
LLVMValueRef LLVMBuildFree(LLVMBuilderRef, LLVMValueRef PointerVal);
LLVMValueRef LLVMBuildLoad(LLVMBuilderRef, LLVMValueRef PointerVal,
                           const char *Name);
LLVMValueRef LLVMBuildLoad2(LLVMBuilderRef, LLVMTypeRef Ty,
                            LLVMValueRef PointerVal, const char *Name);
LLVMValueRef LLVMBuildStore(LLVMBuilderRef, LLVMValueRef Val, LLVMValueRef Ptr);
LLVMValueRef LLVMBuildGEP(LLVMBuilderRef B, LLVMValueRef Pointer,
                          LLVMValueRef *Indices, unsigned NumIndices,
                          const char *Name);
LLVMValueRef LLVMBuildInBoundsGEP(LLVMBuilderRef B, LLVMValueRef Pointer,
                                  LLVMValueRef *Indices, unsigned NumIndices,
                                  const char *Name);
LLVMValueRef LLVMBuildStructGEP(LLVMBuilderRef B, LLVMValueRef Pointer,
                                unsigned Idx, const char *Name);
LLVMValueRef LLVMBuildGEP2(LLVMBuilderRef B, LLVMTypeRef Ty,
                           LLVMValueRef Pointer, LLVMValueRef *Indices,
                           unsigned NumIndices, const char *Name);
LLVMValueRef LLVMBuildInBoundsGEP2(LLVMBuilderRef B, LLVMTypeRef Ty,
                                   LLVMValueRef Pointer, LLVMValueRef *Indices,
                                   unsigned NumIndices, const char *Name);
LLVMValueRef LLVMBuildStructGEP2(LLVMBuilderRef B, LLVMTypeRef Ty,
                                 LLVMValueRef Pointer, unsigned Idx,
                                 const char *Name);
LLVMValueRef LLVMBuildGlobalString(LLVMBuilderRef B, const char *Str,
                                   const char *Name);
LLVMValueRef LLVMBuildGlobalStringPtr(LLVMBuilderRef B, const char *Str,
                                      const char *Name);
LLVMBool LLVMGetVolatile(LLVMValueRef MemoryAccessInst);
void LLVMSetVolatile(LLVMValueRef MemoryAccessInst, LLVMBool IsVolatile);
LLVMAtomicOrdering LLVMGetOrdering(LLVMValueRef MemoryAccessInst);
void LLVMSetOrdering(LLVMValueRef MemoryAccessInst, LLVMAtomicOrdering Ordering);
LLVMValueRef LLVMBuildTrunc(LLVMBuilderRef, LLVMValueRef Val,
                            LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildZExt(LLVMBuilderRef, LLVMValueRef Val,
                           LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildSExt(LLVMBuilderRef, LLVMValueRef Val,
                           LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPToUI(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPToSI(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildUIToFP(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildSIToFP(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPTrunc(LLVMBuilderRef, LLVMValueRef Val,
                              LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPExt(LLVMBuilderRef, LLVMValueRef Val,
                            LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildPtrToInt(LLVMBuilderRef, LLVMValueRef Val,
                               LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildIntToPtr(LLVMBuilderRef, LLVMValueRef Val,
                               LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildBitCast(LLVMBuilderRef, LLVMValueRef Val,
                              LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildAddrSpaceCast(LLVMBuilderRef, LLVMValueRef Val,
                                    LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildZExtOrBitCast(LLVMBuilderRef, LLVMValueRef Val,
                                    LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildSExtOrBitCast(LLVMBuilderRef, LLVMValueRef Val,
                                    LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildTruncOrBitCast(LLVMBuilderRef, LLVMValueRef Val,
                                     LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildCast(LLVMBuilderRef B, LLVMOpcode Op, LLVMValueRef Val,
                           LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildPointerCast(LLVMBuilderRef, LLVMValueRef Val,
                                  LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildIntCast2(LLVMBuilderRef, LLVMValueRef Val,
                               LLVMTypeRef DestTy, LLVMBool IsSigned,
                               const char *Name);
LLVMValueRef LLVMBuildFPCast(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildIntCast(LLVMBuilderRef, LLVMValueRef Val,
                              LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildICmp(LLVMBuilderRef, LLVMIntPredicate Op,
                           LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildFCmp(LLVMBuilderRef, LLVMRealPredicate Op,
                           LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildPhi(LLVMBuilderRef, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMBuildCall(LLVMBuilderRef, LLVMValueRef Fn,
                           LLVMValueRef *Args, unsigned NumArgs,
                           const char *Name);
LLVMValueRef LLVMBuildCall2(LLVMBuilderRef, LLVMTypeRef, LLVMValueRef Fn,
                            LLVMValueRef *Args, unsigned NumArgs,
                            const char *Name);
LLVMValueRef LLVMBuildSelect(LLVMBuilderRef, LLVMValueRef If,
                             LLVMValueRef Then, LLVMValueRef Else,
                             const char *Name);
LLVMValueRef LLVMBuildVAArg(LLVMBuilderRef, LLVMValueRef List, LLVMTypeRef Ty,
                            const char *Name);
LLVMValueRef LLVMBuildExtractElement(LLVMBuilderRef, LLVMValueRef VecVal,
                                     LLVMValueRef Index, const char *Name);
LLVMValueRef LLVMBuildInsertElement(LLVMBuilderRef, LLVMValueRef VecVal,
                                    LLVMValueRef EltVal, LLVMValueRef Index,
                                    const char *Name);
LLVMValueRef LLVMBuildShuffleVector(LLVMBuilderRef, LLVMValueRef V1,
                                    LLVMValueRef V2, LLVMValueRef Mask,
                                    const char *Name);
LLVMValueRef LLVMBuildExtractValue(LLVMBuilderRef, LLVMValueRef AggVal,
                                   unsigned Index, const char *Name);
LLVMValueRef LLVMBuildInsertValue(LLVMBuilderRef, LLVMValueRef AggVal,
                                  LLVMValueRef EltVal, unsigned Index,
                                  const char *Name);
LLVMValueRef LLVMBuildIsNull(LLVMBuilderRef, LLVMValueRef Val,
                             const char *Name);
LLVMValueRef LLVMBuildIsNotNull(LLVMBuilderRef, LLVMValueRef Val,
                                const char *Name);
LLVMValueRef LLVMBuildPtrDiff(LLVMBuilderRef, LLVMValueRef LHS,
                              LLVMValueRef RHS, const char *Name);
LLVMValueRef LLVMBuildFence(LLVMBuilderRef B, LLVMAtomicOrdering ordering,
                            LLVMBool singleThread, const char *Name);
LLVMValueRef LLVMBuildAtomicRMW(LLVMBuilderRef B, LLVMAtomicRMWBinOp op,
                                LLVMValueRef PTR, LLVMValueRef Val,
                                LLVMAtomicOrdering ordering,
                                LLVMBool singleThread);
LLVMValueRef LLVMBuildAtomicCmpXchg(LLVMBuilderRef B, LLVMValueRef Ptr,
                                    LLVMValueRef Cmp, LLVMValueRef New,
                                    LLVMAtomicOrdering SuccessOrdering,
                                    LLVMAtomicOrdering FailureOrdering,
                                    LLVMBool SingleThread);
LLVMBool LLVMIsAtomicSingleThread(LLVMValueRef AtomicInst);
void LLVMSetAtomicSingleThread(LLVMValueRef AtomicInst, LLVMBool SingleThread);
LLVMAtomicOrdering LLVMGetCmpXchgSuccessOrdering(LLVMValueRef CmpXchgInst);
void LLVMSetCmpXchgSuccessOrdering(LLVMValueRef CmpXchgInst,
                                   LLVMAtomicOrdering Ordering);
LLVMAtomicOrdering LLVMGetCmpXchgFailureOrdering(LLVMValueRef CmpXchgInst);
void LLVMSetCmpXchgFailureOrdering(LLVMValueRef CmpXchgInst,
                                   LLVMAtomicOrdering Ordering);
LLVMModuleProviderRef
LLVMCreateModuleProviderForExistingModule(LLVMModuleRef M);
void LLVMDisposeModuleProvider(LLVMModuleProviderRef M);
LLVMBool LLVMCreateMemoryBufferWithContentsOfFile(const char *Path,
                                                  LLVMMemoryBufferRef *OutMemBuf,
                                                  char **OutMessage);
LLVMBool LLVMCreateMemoryBufferWithSTDIN(LLVMMemoryBufferRef *OutMemBuf,
                                         char **OutMessage);
LLVMMemoryBufferRef LLVMCreateMemoryBufferWithMemoryRange(const char *InputData,
                                                          size_t InputDataLength,
                                                          const char *BufferName,
                                                          LLVMBool RequiresNullTerminator);
LLVMMemoryBufferRef LLVMCreateMemoryBufferWithMemoryRangeCopy(const char *InputData,
                                                              size_t InputDataLength,
                                                              const char *BufferName);
const char *LLVMGetBufferStart(LLVMMemoryBufferRef MemBuf);
size_t LLVMGetBufferSize(LLVMMemoryBufferRef MemBuf);
void LLVMDisposeMemoryBuffer(LLVMMemoryBufferRef MemBuf);
LLVMPassRegistryRef LLVMGetGlobalPassRegistry(void);
LLVMPassManagerRef LLVMCreatePassManager(void);
LLVMPassManagerRef LLVMCreateFunctionPassManagerForModule(LLVMModuleRef M);
LLVMPassManagerRef LLVMCreateFunctionPassManager(LLVMModuleProviderRef MP);
LLVMBool LLVMRunPassManager(LLVMPassManagerRef PM, LLVMModuleRef M);
LLVMBool LLVMInitializeFunctionPassManager(LLVMPassManagerRef FPM);
LLVMBool LLVMRunFunctionPassManager(LLVMPassManagerRef FPM, LLVMValueRef F);
LLVMBool LLVMFinalizeFunctionPassManager(LLVMPassManagerRef FPM);
void LLVMDisposePassManager(LLVMPassManagerRef PM);
LLVMBool LLVMStartMultithreaded(void);
void LLVMStopMultithreaded(void);
LLVMBool LLVMIsMultithreaded(void);

// DebugInfo.h ---------------------------------------------------------------

typedef enum {
  LLVMDIFlagZero = 0,
  LLVMDIFlagPrivate = 1,
  LLVMDIFlagProtected = 2,
  LLVMDIFlagPublic = 3,
  LLVMDIFlagFwdDecl = 1 << 2,
  LLVMDIFlagAppleBlock = 1 << 3,
  LLVMDIFlagBlockByrefStruct = 1 << 4,
  LLVMDIFlagVirtual = 1 << 5,
  LLVMDIFlagArtificial = 1 << 6,
  LLVMDIFlagExplicit = 1 << 7,
  LLVMDIFlagPrototyped = 1 << 8,
  LLVMDIFlagObjcClassComplete = 1 << 9,
  LLVMDIFlagObjectPointer = 1 << 10,
  LLVMDIFlagVector = 1 << 11,
  LLVMDIFlagStaticMember = 1 << 12,
  LLVMDIFlagLValueReference = 1 << 13,
  LLVMDIFlagRValueReference = 1 << 14,
  LLVMDIFlagReserved = 1 << 15,
  LLVMDIFlagSingleInheritance = 1 << 16,
  LLVMDIFlagMultipleInheritance = 2 << 16,
  LLVMDIFlagVirtualInheritance = 3 << 16,
  LLVMDIFlagIntroducedVirtual = 1 << 18,
  LLVMDIFlagBitField = 1 << 19,
  LLVMDIFlagNoReturn = 1 << 20,
  LLVMDIFlagMainSubprogram = 1 << 21,
  LLVMDIFlagTypePassByValue = 1 << 22,
  LLVMDIFlagTypePassByReference = 1 << 23,
  LLVMDIFlagEnumClass = 1 << 24,
  LLVMDIFlagFixedEnum = LLVMDIFlagEnumClass,
  LLVMDIFlagThunk = 1 << 25,
  LLVMDIFlagTrivial = 1 << 26,
  LLVMDIFlagBigEndian = 1 << 27,
  LLVMDIFlagLittleEndian = 1 << 28,
  LLVMDIFlagIndirectVirtualBase = (1 << 2) | (1 << 5),
  LLVMDIFlagAccessibility = LLVMDIFlagPrivate | LLVMDIFlagProtected |
                            LLVMDIFlagPublic,
  LLVMDIFlagPtrToMemberRep = LLVMDIFlagSingleInheritance |
                             LLVMDIFlagMultipleInheritance |
                             LLVMDIFlagVirtualInheritance
} LLVMDIFlags;
typedef enum {
  LLVMDWARFSourceLanguageC89,
  LLVMDWARFSourceLanguageC,
  LLVMDWARFSourceLanguageAda83,
  LLVMDWARFSourceLanguageC_plus_plus,
  LLVMDWARFSourceLanguageCobol74,
  LLVMDWARFSourceLanguageCobol85,
  LLVMDWARFSourceLanguageFortran77,
  LLVMDWARFSourceLanguageFortran90,
  LLVMDWARFSourceLanguagePascal83,
  LLVMDWARFSourceLanguageModula2,
  LLVMDWARFSourceLanguageJava,
  LLVMDWARFSourceLanguageC99,
  LLVMDWARFSourceLanguageAda95,
  LLVMDWARFSourceLanguageFortran95,
  LLVMDWARFSourceLanguagePLI,
  LLVMDWARFSourceLanguageObjC,
  LLVMDWARFSourceLanguageObjC_plus_plus,
  LLVMDWARFSourceLanguageUPC,
  LLVMDWARFSourceLanguageD,
  LLVMDWARFSourceLanguagePython,
  LLVMDWARFSourceLanguageOpenCL,
  LLVMDWARFSourceLanguageGo,
  LLVMDWARFSourceLanguageModula3,
  LLVMDWARFSourceLanguageHaskell,
  LLVMDWARFSourceLanguageC_plus_plus_03,
  LLVMDWARFSourceLanguageC_plus_plus_11,
  LLVMDWARFSourceLanguageOCaml,
  LLVMDWARFSourceLanguageRust,
  LLVMDWARFSourceLanguageC11,
  LLVMDWARFSourceLanguageSwift,
  LLVMDWARFSourceLanguageJulia,
  LLVMDWARFSourceLanguageDylan,
  LLVMDWARFSourceLanguageC_plus_plus_14,
  LLVMDWARFSourceLanguageFortran03,
  LLVMDWARFSourceLanguageFortran08,
  LLVMDWARFSourceLanguageRenderScript,
  LLVMDWARFSourceLanguageBLISS,
  LLVMDWARFSourceLanguageMips_Assembler,
  LLVMDWARFSourceLanguageGOOGLE_RenderScript,
  LLVMDWARFSourceLanguageBORLAND_Delphi
} LLVMDWARFSourceLanguage;
typedef enum {
    LLVMDWARFEmissionNone = 0,
    LLVMDWARFEmissionFull,
    LLVMDWARFEmissionLineTablesOnly
} LLVMDWARFEmissionKind;
enum {
  LLVMMDStringMetadataKind,
  LLVMConstantAsMetadataMetadataKind,
  LLVMLocalAsMetadataMetadataKind,
  LLVMDistinctMDOperandPlaceholderMetadataKind,
  LLVMMDTupleMetadataKind,
  LLVMDILocationMetadataKind,
  LLVMDIExpressionMetadataKind,
  LLVMDIGlobalVariableExpressionMetadataKind,
  LLVMGenericDINodeMetadataKind,
  LLVMDISubrangeMetadataKind,
  LLVMDIEnumeratorMetadataKind,
  LLVMDIBasicTypeMetadataKind,
  LLVMDIDerivedTypeMetadataKind,
  LLVMDICompositeTypeMetadataKind,
  LLVMDISubroutineTypeMetadataKind,
  LLVMDIFileMetadataKind,
  LLVMDICompileUnitMetadataKind,
  LLVMDISubprogramMetadataKind,
  LLVMDILexicalBlockMetadataKind,
  LLVMDILexicalBlockFileMetadataKind,
  LLVMDINamespaceMetadataKind,
  LLVMDIModuleMetadataKind,
  LLVMDITemplateTypeParameterMetadataKind,
  LLVMDITemplateValueParameterMetadataKind,
  LLVMDIGlobalVariableMetadataKind,
  LLVMDILocalVariableMetadataKind,
  LLVMDILabelMetadataKind,
  LLVMDIObjCPropertyMetadataKind,
  LLVMDIImportedEntityMetadataKind,
  LLVMDIMacroMetadataKind,
  LLVMDIMacroFileMetadataKind
};
typedef unsigned LLVMMetadataKind;
typedef unsigned LLVMDWARFTypeEncoding;
unsigned LLVMDebugMetadataVersion(void);
unsigned LLVMGetModuleDebugMetadataVersion(LLVMModuleRef Module);
LLVMBool LLVMStripModuleDebugInfo(LLVMModuleRef Module);
LLVMDIBuilderRef LLVMCreateDIBuilderDisallowUnresolved(LLVMModuleRef M);
LLVMDIBuilderRef LLVMCreateDIBuilder(LLVMModuleRef M);
void LLVMDisposeDIBuilder(LLVMDIBuilderRef Builder);
void LLVMDIBuilderFinalize(LLVMDIBuilderRef Builder);
LLVMMetadataRef LLVMDIBuilderCreateCompileUnit(
    LLVMDIBuilderRef Builder, LLVMDWARFSourceLanguage Lang,
    LLVMMetadataRef FileRef, const char *Producer, size_t ProducerLen,
    LLVMBool isOptimized, const char *Flags, size_t FlagsLen,
    unsigned RuntimeVer, const char *SplitName, size_t SplitNameLen,
    LLVMDWARFEmissionKind Kind, unsigned DWOId, LLVMBool SplitDebugInlining,
    LLVMBool DebugInfoForProfiling);
LLVMMetadataRef
LLVMDIBuilderCreateFile(LLVMDIBuilderRef Builder, const char *Filename,
                        size_t FilenameLen, const char *Directory,
                        size_t DirectoryLen);
LLVMMetadataRef
LLVMDIBuilderCreateModule(LLVMDIBuilderRef Builder, LLVMMetadataRef ParentScope,
                          const char *Name, size_t NameLen,
                          const char *ConfigMacros, size_t ConfigMacrosLen,
                          const char *IncludePath, size_t IncludePathLen,
                          const char *ISysRoot, size_t ISysRootLen);
LLVMMetadataRef
LLVMDIBuilderCreateNameSpace(LLVMDIBuilderRef Builder,
                             LLVMMetadataRef ParentScope,
                             const char *Name, size_t NameLen,
                             LLVMBool ExportSymbols);
LLVMMetadataRef LLVMDIBuilderCreateFunction(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, const char *LinkageName, size_t LinkageNameLen,
    LLVMMetadataRef File, unsigned LineNo, LLVMMetadataRef Ty,
    LLVMBool IsLocalToUnit, LLVMBool IsDefinition,
    unsigned ScopeLine, LLVMDIFlags Flags, LLVMBool IsOptimized);
LLVMMetadataRef LLVMDIBuilderCreateLexicalBlock(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope,
    LLVMMetadataRef File, unsigned Line, unsigned Column);
LLVMMetadataRef
LLVMDIBuilderCreateLexicalBlockFile(LLVMDIBuilderRef Builder,
                                    LLVMMetadataRef Scope,
                                    LLVMMetadataRef File,
                                    unsigned Discriminator);
LLVMMetadataRef
LLVMDIBuilderCreateImportedModuleFromNamespace(LLVMDIBuilderRef Builder,
                                               LLVMMetadataRef Scope,
                                               LLVMMetadataRef NS,
                                               LLVMMetadataRef File,
                                               unsigned Line);
LLVMMetadataRef
LLVMDIBuilderCreateImportedModuleFromAlias(LLVMDIBuilderRef Builder,
                                           LLVMMetadataRef Scope,
                                           LLVMMetadataRef ImportedEntity,
                                           LLVMMetadataRef File,
                                           unsigned Line);
LLVMMetadataRef
LLVMDIBuilderCreateImportedModuleFromModule(LLVMDIBuilderRef Builder,
                                            LLVMMetadataRef Scope,
                                            LLVMMetadataRef M,
                                            LLVMMetadataRef File,
                                            unsigned Line);
LLVMMetadataRef
LLVMDIBuilderCreateImportedDeclaration(LLVMDIBuilderRef Builder,
                                       LLVMMetadataRef Scope,
                                       LLVMMetadataRef Decl,
                                       LLVMMetadataRef File,
                                       unsigned Line,
                                       const char *Name, size_t NameLen);
LLVMMetadataRef
LLVMDIBuilderCreateDebugLocation(LLVMContextRef Ctx, unsigned Line,
                                 unsigned Column, LLVMMetadataRef Scope,
                                 LLVMMetadataRef InlinedAt);
unsigned LLVMDILocationGetLine(LLVMMetadataRef Location);
unsigned LLVMDILocationGetColumn(LLVMMetadataRef Location);
LLVMMetadataRef LLVMDILocationGetScope(LLVMMetadataRef Location);
LLVMMetadataRef LLVMDIBuilderGetOrCreateTypeArray(LLVMDIBuilderRef Builder,
                                                  LLVMMetadataRef *Data,
                                                  size_t NumElements);
LLVMMetadataRef
LLVMDIBuilderCreateSubroutineType(LLVMDIBuilderRef Builder,
                                  LLVMMetadataRef File,
                                  LLVMMetadataRef *ParameterTypes,
                                  unsigned NumParameterTypes,
                                  LLVMDIFlags Flags);
LLVMMetadataRef LLVMDIBuilderCreateEnumerationType(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, LLVMMetadataRef File, unsigned LineNumber,
    uint64_t SizeInBits, uint32_t AlignInBits, LLVMMetadataRef *Elements,
    unsigned NumElements, LLVMMetadataRef ClassTy);
LLVMMetadataRef LLVMDIBuilderCreateUnionType(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, LLVMMetadataRef File, unsigned LineNumber,
    uint64_t SizeInBits, uint32_t AlignInBits, LLVMDIFlags Flags,
    LLVMMetadataRef *Elements, unsigned NumElements, unsigned RunTimeLang,
    const char *UniqueId, size_t UniqueIdLen);
LLVMMetadataRef
LLVMDIBuilderCreateArrayType(LLVMDIBuilderRef Builder, uint64_t Size,
                             uint32_t AlignInBits, LLVMMetadataRef Ty,
                             LLVMMetadataRef *Subscripts,
                             unsigned NumSubscripts);
LLVMMetadataRef
LLVMDIBuilderCreateVectorType(LLVMDIBuilderRef Builder, uint64_t Size,
                              uint32_t AlignInBits, LLVMMetadataRef Ty,
                              LLVMMetadataRef *Subscripts,
                              unsigned NumSubscripts);
LLVMMetadataRef
LLVMDIBuilderCreateUnspecifiedType(LLVMDIBuilderRef Builder, const char *Name,
                                   size_t NameLen);
LLVMMetadataRef
LLVMDIBuilderCreateBasicType(LLVMDIBuilderRef Builder, const char *Name,
                             size_t NameLen, uint64_t SizeInBits,
                             LLVMDWARFTypeEncoding Encoding,
                             LLVMDIFlags Flags);
LLVMMetadataRef LLVMDIBuilderCreatePointerType(
    LLVMDIBuilderRef Builder, LLVMMetadataRef PointeeTy,
    uint64_t SizeInBits, uint32_t AlignInBits, unsigned AddressSpace,
    const char *Name, size_t NameLen);
LLVMMetadataRef LLVMDIBuilderCreateStructType(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, LLVMMetadataRef File, unsigned LineNumber,
    uint64_t SizeInBits, uint32_t AlignInBits, LLVMDIFlags Flags,
    LLVMMetadataRef DerivedFrom, LLVMMetadataRef *Elements,
    unsigned NumElements, unsigned RunTimeLang, LLVMMetadataRef VTableHolder,
    const char *UniqueId, size_t UniqueIdLen);
LLVMMetadataRef LLVMDIBuilderCreateMemberType(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, LLVMMetadataRef File, unsigned LineNo,
    uint64_t SizeInBits, uint32_t AlignInBits, uint64_t OffsetInBits,
    LLVMDIFlags Flags, LLVMMetadataRef Ty);
LLVMMetadataRef
LLVMDIBuilderCreateStaticMemberType(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, LLVMMetadataRef File, unsigned LineNumber,
    LLVMMetadataRef Type, LLVMDIFlags Flags, LLVMValueRef ConstantVal,
    uint32_t AlignInBits);
LLVMMetadataRef
LLVMDIBuilderCreateMemberPointerType(LLVMDIBuilderRef Builder,
                                     LLVMMetadataRef PointeeType,
                                     LLVMMetadataRef ClassType,
                                     uint64_t SizeInBits,
                                     uint32_t AlignInBits,
                                     LLVMDIFlags Flags);
LLVMMetadataRef
LLVMDIBuilderCreateObjCIVar(LLVMDIBuilderRef Builder,
                            const char *Name, size_t NameLen,
                            LLVMMetadataRef File, unsigned LineNo,
                            uint64_t SizeInBits, uint32_t AlignInBits,
                            uint64_t OffsetInBits, LLVMDIFlags Flags,
                            LLVMMetadataRef Ty, LLVMMetadataRef PropertyNode);
LLVMMetadataRef
LLVMDIBuilderCreateObjCProperty(LLVMDIBuilderRef Builder,
                                const char *Name, size_t NameLen,
                                LLVMMetadataRef File, unsigned LineNo,
                                const char *GetterName, size_t GetterNameLen,
                                const char *SetterName, size_t SetterNameLen,
                                unsigned PropertyAttributes,
                                LLVMMetadataRef Ty);
LLVMMetadataRef
LLVMDIBuilderCreateObjectPointerType(LLVMDIBuilderRef Builder,
                                     LLVMMetadataRef Type);
LLVMMetadataRef
LLVMDIBuilderCreateQualifiedType(LLVMDIBuilderRef Builder, unsigned Tag,
                                 LLVMMetadataRef Type);
LLVMMetadataRef
LLVMDIBuilderCreateReferenceType(LLVMDIBuilderRef Builder, unsigned Tag,
                                 LLVMMetadataRef Type);
LLVMMetadataRef
LLVMDIBuilderCreateNullPtrType(LLVMDIBuilderRef Builder);
LLVMMetadataRef
LLVMDIBuilderCreateTypedef(LLVMDIBuilderRef Builder, LLVMMetadataRef Type,
                           const char *Name, size_t NameLen,
                           LLVMMetadataRef File, unsigned LineNo,
                           LLVMMetadataRef Scope);
LLVMMetadataRef
LLVMDIBuilderCreateInheritance(LLVMDIBuilderRef Builder,
                               LLVMMetadataRef Ty, LLVMMetadataRef BaseTy,
                               uint64_t BaseOffset, uint32_t VBPtrOffset,
                               LLVMDIFlags Flags);
LLVMMetadataRef LLVMDIBuilderCreateForwardDecl(
    LLVMDIBuilderRef Builder, unsigned Tag, const char *Name,
    size_t NameLen, LLVMMetadataRef Scope, LLVMMetadataRef File, unsigned Line,
    unsigned RuntimeLang, uint64_t SizeInBits, uint32_t AlignInBits,
    const char *UniqueIdentifier, size_t UniqueIdentifierLen);
LLVMMetadataRef
LLVMDIBuilderCreateReplaceableCompositeType(
    LLVMDIBuilderRef Builder, unsigned Tag, const char *Name,
    size_t NameLen, LLVMMetadataRef Scope, LLVMMetadataRef File, unsigned Line,
    unsigned RuntimeLang, uint64_t SizeInBits, uint32_t AlignInBits,
    LLVMDIFlags Flags, const char *UniqueIdentifier,
    size_t UniqueIdentifierLen);
LLVMMetadataRef
LLVMDIBuilderCreateBitFieldMemberType(LLVMDIBuilderRef Builder,
                                      LLVMMetadataRef Scope,
                                      const char *Name, size_t NameLen,
                                      LLVMMetadataRef File, unsigned LineNumber,
                                      uint64_t SizeInBits,
                                      uint64_t OffsetInBits,
                                      uint64_t StorageOffsetInBits,
                                      LLVMDIFlags Flags, LLVMMetadataRef Type);
LLVMMetadataRef LLVMDIBuilderCreateClassType(LLVMDIBuilderRef Builder,
    LLVMMetadataRef Scope, const char *Name, size_t NameLen,
    LLVMMetadataRef File, unsigned LineNumber, uint64_t SizeInBits,
    uint32_t AlignInBits, uint64_t OffsetInBits, LLVMDIFlags Flags,
    LLVMMetadataRef DerivedFrom,
    LLVMMetadataRef *Elements, unsigned NumElements,
    LLVMMetadataRef VTableHolder, LLVMMetadataRef TemplateParamsNode,
    const char *UniqueIdentifier, size_t UniqueIdentifierLen);
LLVMMetadataRef
LLVMDIBuilderCreateArtificialType(LLVMDIBuilderRef Builder,
                                  LLVMMetadataRef Type);
const char *LLVMDITypeGetName(LLVMMetadataRef DType, size_t *Length);
uint64_t LLVMDITypeGetSizeInBits(LLVMMetadataRef DType);
uint64_t LLVMDITypeGetOffsetInBits(LLVMMetadataRef DType);
uint32_t LLVMDITypeGetAlignInBits(LLVMMetadataRef DType);
unsigned LLVMDITypeGetLine(LLVMMetadataRef DType);
LLVMDIFlags LLVMDITypeGetFlags(LLVMMetadataRef DType);
LLVMMetadataRef LLVMDIBuilderGetOrCreateSubrange(LLVMDIBuilderRef Builder,
                                                 int64_t LowerBound,
                                                 int64_t Count);
LLVMMetadataRef LLVMDIBuilderGetOrCreateArray(LLVMDIBuilderRef Builder,
                                              LLVMMetadataRef *Data,
                                              size_t NumElements);
LLVMMetadataRef LLVMDIBuilderCreateExpression(LLVMDIBuilderRef Builder,
                                              int64_t *Addr, size_t Length);
LLVMMetadataRef
LLVMDIBuilderCreateConstantValueExpression(LLVMDIBuilderRef Builder,
                                           int64_t Value);
LLVMMetadataRef LLVMDIBuilderCreateGlobalVariableExpression(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, const char *Linkage, size_t LinkLen, LLVMMetadataRef File,
    unsigned LineNo, LLVMMetadataRef Ty, LLVMBool LocalToUnit,
    LLVMMetadataRef Expr, LLVMMetadataRef Decl, uint32_t AlignInBits);
LLVMMetadataRef LLVMTemporaryMDNode(LLVMContextRef Ctx, LLVMMetadataRef *Data,
                                    size_t NumElements);
void LLVMDisposeTemporaryMDNode(LLVMMetadataRef TempNode);
void LLVMMetadataReplaceAllUsesWith(LLVMMetadataRef TempTargetMetadata,
                                    LLVMMetadataRef Replacement);
LLVMMetadataRef LLVMDIBuilderCreateTempGlobalVariableFwdDecl(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, const char *Linkage, size_t LnkLen, LLVMMetadataRef File,
    unsigned LineNo, LLVMMetadataRef Ty, LLVMBool LocalToUnit,
    LLVMMetadataRef Decl, uint32_t AlignInBits);
LLVMValueRef LLVMDIBuilderInsertDeclareBefore(
  LLVMDIBuilderRef Builder, LLVMValueRef Storage, LLVMMetadataRef VarInfo,
  LLVMMetadataRef Expr, LLVMMetadataRef DebugLoc, LLVMValueRef Instr);
LLVMValueRef LLVMDIBuilderInsertDeclareAtEnd(
    LLVMDIBuilderRef Builder, LLVMValueRef Storage, LLVMMetadataRef VarInfo,
    LLVMMetadataRef Expr, LLVMMetadataRef DebugLoc, LLVMBasicBlockRef Block);
LLVMValueRef LLVMDIBuilderInsertDbgValueBefore(LLVMDIBuilderRef Builder,
                                               LLVMValueRef Val,
                                               LLVMMetadataRef VarInfo,
                                               LLVMMetadataRef Expr,
                                               LLVMMetadataRef DebugLoc,
                                               LLVMValueRef Instr);
LLVMValueRef LLVMDIBuilderInsertDbgValueAtEnd(LLVMDIBuilderRef Builder,
                                              LLVMValueRef Val,
                                              LLVMMetadataRef VarInfo,
                                              LLVMMetadataRef Expr,
                                              LLVMMetadataRef DebugLoc,
                                              LLVMBasicBlockRef Block);
LLVMMetadataRef LLVMDIBuilderCreateAutoVariable(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, LLVMMetadataRef File, unsigned LineNo, LLVMMetadataRef Ty,
    LLVMBool AlwaysPreserve, LLVMDIFlags Flags, uint32_t AlignInBits);
LLVMMetadataRef LLVMDIBuilderCreateParameterVariable(
    LLVMDIBuilderRef Builder, LLVMMetadataRef Scope, const char *Name,
    size_t NameLen, unsigned ArgNo, LLVMMetadataRef File, unsigned LineNo,
    LLVMMetadataRef Ty, LLVMBool AlwaysPreserve, LLVMDIFlags Flags);
LLVMMetadataRef LLVMGetSubprogram(LLVMValueRef Func);
void LLVMSetSubprogram(LLVMValueRef Func, LLVMMetadataRef SP);
LLVMMetadataKind LLVMGetMetadataKind(LLVMMetadataRef Metadata);

// DisassemblerTypes.h -------------------------------------------------------

typedef void *LLVMDisasmContextRef;
typedef int (*LLVMOpInfoCallback)(void *DisInfo, uint64_t PC,
                                  uint64_t Offset, uint64_t Size,
                                  int TagType, void *TagBuf);
struct LLVMOpInfoSymbol1 {
  uint64_t Present;
  const char *Name;
  uint64_t Value;
};
struct LLVMOpInfo1 {
  struct LLVMOpInfoSymbol1 AddSymbol;
  struct LLVMOpInfoSymbol1 SubtractSymbol;
  uint64_t Value;
  uint64_t VariantKind;
};
enum {
	LLVMDisassembler_VariantKind_None             = 0,
	LLVMDisassembler_VariantKind_ARM_HI16         = 1,
	LLVMDisassembler_VariantKind_ARM_LO16         = 2,
	LLVMDisassembler_VariantKind_ARM64_PAGE       = 1,
	LLVMDisassembler_VariantKind_ARM64_PAGEOFF    = 2,
	LLVMDisassembler_VariantKind_ARM64_GOTPAGE    = 3,
	LLVMDisassembler_VariantKind_ARM64_GOTPAGEOFF = 4,
	LLVMDisassembler_VariantKind_ARM64_TLVP       = 5,
	LLVMDisassembler_VariantKind_ARM64_TLVOFF     = 6,
};
typedef const char *(*LLVMSymbolLookupCallback)(void *DisInfo,
                                                uint64_t ReferenceValue,
                                                uint64_t *ReferenceType,
                                                uint64_t ReferencePC,
                                                const char **ReferenceName);
enum {
	LLVMDisassembler_ReferenceType_InOut_None            =           0,
	LLVMDisassembler_ReferenceType_In_Branch             =           1,
	LLVMDisassembler_ReferenceType_In_PCrel_Load         =           2,
	//LLVMDisassembler_ReferenceType_In_ARM64_ADRP         = 0x100000001,
	//LLVMDisassembler_ReferenceType_In_ARM64_ADDXri       = 0x100000002,
	//LLVMDisassembler_ReferenceType_In_ARM64_LDRXui       = 0x100000003,
	//LLVMDisassembler_ReferenceType_In_ARM64_LDRXl        = 0x100000004,
	//LLVMDisassembler_ReferenceType_In_ARM64_ADR          = 0x100000005,
	LLVMDisassembler_ReferenceType_Out_SymbolStub        =           1,
	LLVMDisassembler_ReferenceType_Out_LitPool_SymAddr   =           2,
	LLVMDisassembler_ReferenceType_Out_LitPool_CstrAddr  =           3,
	LLVMDisassembler_ReferenceType_Out_Objc_CFString_Ref =           4,
	LLVMDisassembler_ReferenceType_Out_Objc_Message      =           5,
	LLVMDisassembler_ReferenceType_Out_Objc_Message_Ref  =           6,
	LLVMDisassembler_ReferenceType_Out_Objc_Selector_Ref =           7,
	LLVMDisassembler_ReferenceType_Out_Objc_Class_Ref    =           8,
	LLVMDisassembler_ReferenceType_DeMangled_Name        =           9,
};

// Disassembler.h ------------------------------------------------------------

LLVMDisasmContextRef LLVMCreateDisasm(const char *TripleName, void *DisInfo,
                                      int TagType, LLVMOpInfoCallback GetOpInfo,
                                      LLVMSymbolLookupCallback SymbolLookUp);
LLVMDisasmContextRef LLVMCreateDisasmCPU(const char *Triple, const char *CPU,
                                         void *DisInfo, int TagType,
                                         LLVMOpInfoCallback GetOpInfo,
                                         LLVMSymbolLookupCallback SymbolLookUp);
LLVMDisasmContextRef
LLVMCreateDisasmCPUFeatures(const char *Triple, const char *CPU,
                            const char *Features, void *DisInfo, int TagType,
                            LLVMOpInfoCallback GetOpInfo,
                            LLVMSymbolLookupCallback SymbolLookUp);
int LLVMSetDisasmOptions(LLVMDisasmContextRef DC, uint64_t Options);
enum {
	LLVMDisassembler_Option_UseMarkup         =  1,
	LLVMDisassembler_Option_PrintImmHex       =  2,
	LLVMDisassembler_Option_AsmPrinterVariant =  4,
	LLVMDisassembler_Option_SetInstrComments  =  8,
	LLVMDisassembler_Option_PrintLatency      = 16,
};
void LLVMDisasmDispose(LLVMDisasmContextRef DC);
size_t LLVMDisasmInstruction(LLVMDisasmContextRef DC, uint8_t *Bytes,
                             uint64_t BytesSize, uint64_t PC,
                             char *OutString, size_t OutStringSize);

// Error.h -------------------------------------------------------------------

enum {
	LLVMErrorSuccess = 0,
};
typedef struct LLVMOpaqueError *LLVMErrorRef;
typedef const void *LLVMErrorTypeId;
LLVMErrorTypeId LLVMGetErrorTypeId(LLVMErrorRef Err);
void LLVMConsumeError(LLVMErrorRef Err);
char *LLVMGetErrorMessage(LLVMErrorRef Err);
void LLVMDisposeErrorMessage(char *ErrMsg);
LLVMErrorTypeId LLVMGetStringErrorTypeId();

// Target.h ------------------------------------------------------------------

enum LLVMByteOrdering { LLVMBigEndian, LLVMLittleEndian };
typedef struct LLVMOpaqueTargetData *LLVMTargetDataRef;
typedef struct LLVMOpaqueTargetLibraryInfotData *LLVMTargetLibraryInfoRef;
void LLVMInitializeX86TargetInfo(void);
void LLVMInitializeX86Target(void);
void LLVMInitializeX86TargetMC(void);
void LLVMInitializeX86AsmPrinter(void);
void LLVMInitializeX86AsmParser(void);
void LLVMInitializeX86Disassembler(void);
LLVMTargetDataRef LLVMGetModuleDataLayout(LLVMModuleRef M);
void LLVMSetModuleDataLayout(LLVMModuleRef M, LLVMTargetDataRef DL);
LLVMTargetDataRef LLVMCreateTargetData(const char *StringRep);
void LLVMDisposeTargetData(LLVMTargetDataRef TD);
void LLVMAddTargetLibraryInfo(LLVMTargetLibraryInfoRef TLI,
                              LLVMPassManagerRef PM);
char *LLVMCopyStringRepOfTargetData(LLVMTargetDataRef TD);
enum LLVMByteOrdering LLVMByteOrder(LLVMTargetDataRef TD);
unsigned LLVMPointerSize(LLVMTargetDataRef TD);
unsigned LLVMPointerSizeForAS(LLVMTargetDataRef TD, unsigned AS);
LLVMTypeRef LLVMIntPtrType(LLVMTargetDataRef TD);
LLVMTypeRef LLVMIntPtrTypeForAS(LLVMTargetDataRef TD, unsigned AS);
LLVMTypeRef LLVMIntPtrTypeInContext(LLVMContextRef C, LLVMTargetDataRef TD);
LLVMTypeRef LLVMIntPtrTypeForASInContext(LLVMContextRef C, LLVMTargetDataRef TD,
                                         unsigned AS);
unsigned long long LLVMSizeOfTypeInBits(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned long long LLVMStoreSizeOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned long long LLVMABISizeOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMABIAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMCallFrameAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMPreferredAlignmentOfType(LLVMTargetDataRef TD, LLVMTypeRef Ty);
unsigned LLVMPreferredAlignmentOfGlobal(LLVMTargetDataRef TD,
                                        LLVMValueRef GlobalVar);
unsigned LLVMElementAtOffset(LLVMTargetDataRef TD, LLVMTypeRef StructTy,
                             unsigned long long Offset);
unsigned long long LLVMOffsetOfElement(LLVMTargetDataRef TD,
                                       LLVMTypeRef StructTy, unsigned Element);

// TargetMachine.h -----------------------------------------------------------

typedef struct LLVMOpaqueTargetMachine *LLVMTargetMachineRef;
typedef struct LLVMTarget *LLVMTargetRef;
typedef enum {
    LLVMCodeGenLevelNone,
    LLVMCodeGenLevelLess,
    LLVMCodeGenLevelDefault,
    LLVMCodeGenLevelAggressive
} LLVMCodeGenOptLevel;
typedef enum {
    LLVMRelocDefault,
    LLVMRelocStatic,
    LLVMRelocPIC,
    LLVMRelocDynamicNoPic,
    LLVMRelocROPI,
    LLVMRelocRWPI,
    LLVMRelocROPI_RWPI
} LLVMRelocMode;
typedef enum {
    LLVMCodeModelDefault,
    LLVMCodeModelJITDefault,
    LLVMCodeModelTiny,
    LLVMCodeModelSmall,
    LLVMCodeModelKernel,
    LLVMCodeModelMedium,
    LLVMCodeModelLarge
} LLVMCodeModel;
typedef enum {
    LLVMAssemblyFile,
    LLVMObjectFile
} LLVMCodeGenFileType;
LLVMTargetRef LLVMGetFirstTarget(void);
LLVMTargetRef LLVMGetNextTarget(LLVMTargetRef T);
LLVMTargetRef LLVMGetTargetFromName(const char *Name);
LLVMBool LLVMGetTargetFromTriple(const char* Triple, LLVMTargetRef *T,
                                 char **ErrorMessage);
const char *LLVMGetTargetName(LLVMTargetRef T);
const char *LLVMGetTargetDescription(LLVMTargetRef T);
LLVMBool LLVMTargetHasJIT(LLVMTargetRef T);
LLVMBool LLVMTargetHasTargetMachine(LLVMTargetRef T);
LLVMBool LLVMTargetHasAsmBackend(LLVMTargetRef T);
LLVMTargetMachineRef LLVMCreateTargetMachine(LLVMTargetRef T,
  const char *Triple, const char *CPU, const char *Features,
  LLVMCodeGenOptLevel Level, LLVMRelocMode Reloc, LLVMCodeModel CodeModel);
void LLVMDisposeTargetMachine(LLVMTargetMachineRef T);
LLVMTargetRef LLVMGetTargetMachineTarget(LLVMTargetMachineRef T);
char *LLVMGetTargetMachineTriple(LLVMTargetMachineRef T);
char *LLVMGetTargetMachineCPU(LLVMTargetMachineRef T);
char *LLVMGetTargetMachineFeatureString(LLVMTargetMachineRef T);
LLVMTargetDataRef LLVMCreateTargetDataLayout(LLVMTargetMachineRef T);
void LLVMSetTargetMachineAsmVerbosity(LLVMTargetMachineRef T,
                                      LLVMBool VerboseAsm);
LLVMBool LLVMTargetMachineEmitToFile(LLVMTargetMachineRef T, LLVMModuleRef M,
  char *Filename, LLVMCodeGenFileType codegen, char **ErrorMessage);
LLVMBool LLVMTargetMachineEmitToMemoryBuffer(LLVMTargetMachineRef T, LLVMModuleRef M,
  LLVMCodeGenFileType codegen, char** ErrorMessage, LLVMMemoryBufferRef *OutMemBuf);
char* LLVMGetDefaultTargetTriple(void);
char* LLVMNormalizeTargetTriple(const char* triple);
char* LLVMGetHostCPUName(void);
char* LLVMGetHostCPUFeatures(void);
void LLVMAddAnalysisPasses(LLVMTargetMachineRef T, LLVMPassManagerRef PM);

// ExecutionEngine.h ---------------------------------------------------------

void LLVMLinkInMCJIT(void);
void LLVMLinkInInterpreter(void);
typedef struct LLVMOpaqueGenericValue *LLVMGenericValueRef;
typedef struct LLVMOpaqueExecutionEngine *LLVMExecutionEngineRef;
typedef struct LLVMOpaqueMCJITMemoryManager *LLVMMCJITMemoryManagerRef;
struct LLVMMCJITCompilerOptions {
  unsigned OptLevel;
  LLVMCodeModel CodeModel;
  LLVMBool NoFramePointerElim;
  LLVMBool EnableFastISel;
  LLVMMCJITMemoryManagerRef MCJMM;
};
LLVMGenericValueRef LLVMCreateGenericValueOfInt(LLVMTypeRef Ty,
                                                unsigned long long N,
                                                LLVMBool IsSigned);
LLVMGenericValueRef LLVMCreateGenericValueOfPointer(void *P);
LLVMGenericValueRef LLVMCreateGenericValueOfFloat(LLVMTypeRef Ty, double N);
unsigned LLVMGenericValueIntWidth(LLVMGenericValueRef GenValRef);
unsigned long long LLVMGenericValueToInt(LLVMGenericValueRef GenVal,
                                         LLVMBool IsSigned);
void *LLVMGenericValueToPointer(LLVMGenericValueRef GenVal);
double LLVMGenericValueToFloat(LLVMTypeRef TyRef, LLVMGenericValueRef GenVal);
void LLVMDisposeGenericValue(LLVMGenericValueRef GenVal);
LLVMBool LLVMCreateExecutionEngineForModule(LLVMExecutionEngineRef *OutEE,
                                            LLVMModuleRef M,
                                            char **OutError);
LLVMBool LLVMCreateInterpreterForModule(LLVMExecutionEngineRef *OutInterp,
                                        LLVMModuleRef M,
                                        char **OutError);
LLVMBool LLVMCreateJITCompilerForModule(LLVMExecutionEngineRef *OutJIT,
                                        LLVMModuleRef M,
                                        unsigned OptLevel,
                                        char **OutError);
void LLVMInitializeMCJITCompilerOptions(
  struct LLVMMCJITCompilerOptions *Options, size_t SizeOfOptions);
LLVMBool LLVMCreateMCJITCompilerForModule(
  LLVMExecutionEngineRef *OutJIT, LLVMModuleRef M,
  struct LLVMMCJITCompilerOptions *Options, size_t SizeOfOptions,
  char **OutError);
void LLVMDisposeExecutionEngine(LLVMExecutionEngineRef EE);
void LLVMRunStaticConstructors(LLVMExecutionEngineRef EE);
void LLVMRunStaticDestructors(LLVMExecutionEngineRef EE);
int LLVMRunFunctionAsMain(LLVMExecutionEngineRef EE, LLVMValueRef F,
                          unsigned ArgC, const char * const *ArgV,
                          const char * const *EnvP);
LLVMGenericValueRef LLVMRunFunction(LLVMExecutionEngineRef EE, LLVMValueRef F,
                                    unsigned NumArgs,
                                    LLVMGenericValueRef *Args);
void LLVMFreeMachineCodeForFunction(LLVMExecutionEngineRef EE, LLVMValueRef F);
void LLVMAddModule(LLVMExecutionEngineRef EE, LLVMModuleRef M);
LLVMBool LLVMRemoveModule(LLVMExecutionEngineRef EE, LLVMModuleRef M,
                          LLVMModuleRef *OutMod, char **OutError);
LLVMBool LLVMFindFunction(LLVMExecutionEngineRef EE, const char *Name,
                          LLVMValueRef *OutFn);
void *LLVMRecompileAndRelinkFunction(LLVMExecutionEngineRef EE,
                                     LLVMValueRef Fn);
LLVMTargetDataRef LLVMGetExecutionEngineTargetData(LLVMExecutionEngineRef EE);
LLVMTargetMachineRef
LLVMGetExecutionEngineTargetMachine(LLVMExecutionEngineRef EE);
void LLVMAddGlobalMapping(LLVMExecutionEngineRef EE, LLVMValueRef Global,
                          void* Addr);
void *LLVMGetPointerToGlobal(LLVMExecutionEngineRef EE, LLVMValueRef Global);
uint64_t LLVMGetGlobalValueAddress(LLVMExecutionEngineRef EE, const char *Name);
uint64_t LLVMGetFunctionAddress(LLVMExecutionEngineRef EE, const char *Name);
typedef uint8_t *(*LLVMMemoryManagerAllocateCodeSectionCallback)(
  void *Opaque, uintptr_t Size, unsigned Alignment, unsigned SectionID,
  const char *SectionName);
typedef uint8_t *(*LLVMMemoryManagerAllocateDataSectionCallback)(
  void *Opaque, uintptr_t Size, unsigned Alignment, unsigned SectionID,
  const char *SectionName, LLVMBool IsReadOnly);
typedef LLVMBool (*LLVMMemoryManagerFinalizeMemoryCallback)(
  void *Opaque, char **ErrMsg);
typedef void (*LLVMMemoryManagerDestroyCallback)(void *Opaque);
LLVMMCJITMemoryManagerRef LLVMCreateSimpleMCJITMemoryManager(
  void *Opaque,
  LLVMMemoryManagerAllocateCodeSectionCallback AllocateCodeSection,
  LLVMMemoryManagerAllocateDataSectionCallback AllocateDataSection,
  LLVMMemoryManagerFinalizeMemoryCallback FinalizeMemory,
  LLVMMemoryManagerDestroyCallback Destroy);
void LLVMDisposeMCJITMemoryManager(LLVMMCJITMemoryManagerRef MM);
LLVMJITEventListenerRef LLVMCreateGDBRegistrationListener(void);
LLVMJITEventListenerRef LLVMCreateIntelJITEventListener(void);
LLVMJITEventListenerRef LLVMCreateOProfileJITEventListener(void);
LLVMJITEventListenerRef LLVMCreatePerfJITEventListener(void);

// Initialization.h ----------------------------------------------------------

void LLVMInitializeCore(LLVMPassRegistryRef R);
void LLVMInitializeTransformUtils(LLVMPassRegistryRef R);
void LLVMInitializeScalarOpts(LLVMPassRegistryRef R);
void LLVMInitializeObjCARCOpts(LLVMPassRegistryRef R);
void LLVMInitializeVectorization(LLVMPassRegistryRef R);
void LLVMInitializeInstCombine(LLVMPassRegistryRef R);
void LLVMInitializeAggressiveInstCombiner(LLVMPassRegistryRef R);
void LLVMInitializeIPO(LLVMPassRegistryRef R);
void LLVMInitializeInstrumentation(LLVMPassRegistryRef R);
void LLVMInitializeAnalysis(LLVMPassRegistryRef R);
void LLVMInitializeIPA(LLVMPassRegistryRef R);
void LLVMInitializeCodeGen(LLVMPassRegistryRef R);
void LLVMInitializeTarget(LLVMPassRegistryRef R);

// IRReader.h ----------------------------------------------------------------

LLVMBool LLVMParseIRInContext(LLVMContextRef ContextRef,
                              LLVMMemoryBufferRef MemBuf, LLVMModuleRef *OutM,
                              char **OutMessage);

// Linker.h ------------------------------------------------------------------

typedef enum {
  LLVMLinkerDestroySource = 0,
  LLVMLinkerPreserveSource_Removed = 1
} LLVMLinkerMode;
LLVMBool LLVMLinkModules2(LLVMModuleRef Dest, LLVMModuleRef Src);

// LinkTimeOptimizer.h -------------------------------------------------------

typedef void* llvm_lto_t;
typedef enum llvm_lto_status {
 LLVM_LTO_UNKNOWN,
 LLVM_LTO_OPT_SUCCESS,
 LLVM_LTO_READ_SUCCESS,
 LLVM_LTO_READ_FAILURE,
 LLVM_LTO_WRITE_FAILURE,
 LLVM_LTO_NO_TARGET,
 LLVM_LTO_NO_WORK,
 LLVM_LTO_MODULE_MERGE_FAILURE,
 LLVM_LTO_ASM_FAILURE,
 LLVM_LTO_NULL_OBJECT
} llvm_lto_status_t;
llvm_lto_t llvm_create_optimizer(void);
void llvm_destroy_optimizer(llvm_lto_t lto);
llvm_lto_status_t llvm_read_object_file
	(llvm_lto_t lto, const char* input_filename);
llvm_lto_status_t llvm_optimize_modules
	(llvm_lto_t lto, const char* output_filename);

// lto.h ---------------------------------------------------------------------

typedef bool lto_bool_t;
enum {
	LTO_API_VERSION = 23,
};
typedef enum {
    LTO_SYMBOL_ALIGNMENT_MASK              = 0x0000001F,
    LTO_SYMBOL_PERMISSIONS_MASK            = 0x000000E0,
    LTO_SYMBOL_PERMISSIONS_CODE            = 0x000000A0,
    LTO_SYMBOL_PERMISSIONS_DATA            = 0x000000C0,
    LTO_SYMBOL_PERMISSIONS_RODATA          = 0x00000080,
    LTO_SYMBOL_DEFINITION_MASK             = 0x00000700,
    LTO_SYMBOL_DEFINITION_REGULAR          = 0x00000100,
    LTO_SYMBOL_DEFINITION_TENTATIVE        = 0x00000200,
    LTO_SYMBOL_DEFINITION_WEAK             = 0x00000300,
    LTO_SYMBOL_DEFINITION_UNDEFINED        = 0x00000400,
    LTO_SYMBOL_DEFINITION_WEAKUNDEF        = 0x00000500,
    LTO_SYMBOL_SCOPE_MASK                  = 0x00003800,
    LTO_SYMBOL_SCOPE_INTERNAL              = 0x00000800,
    LTO_SYMBOL_SCOPE_HIDDEN                = 0x00001000,
    LTO_SYMBOL_SCOPE_PROTECTED             = 0x00002000,
    LTO_SYMBOL_SCOPE_DEFAULT               = 0x00001800,
    LTO_SYMBOL_SCOPE_DEFAULT_CAN_BE_HIDDEN = 0x00002800,
    LTO_SYMBOL_COMDAT                      = 0x00004000,
    LTO_SYMBOL_ALIAS                       = 0x00008000
} lto_symbol_attributes;
typedef enum {
    LTO_DEBUG_MODEL_NONE         = 0,
    LTO_DEBUG_MODEL_DWARF        = 1
} lto_debug_model;
typedef enum {
    LTO_CODEGEN_PIC_MODEL_STATIC         = 0,
    LTO_CODEGEN_PIC_MODEL_DYNAMIC        = 1,
    LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC = 2,
    LTO_CODEGEN_PIC_MODEL_DEFAULT        = 3
} lto_codegen_model;
typedef struct LLVMOpaqueLTOModule *lto_module_t;
typedef struct LLVMOpaqueLTOCodeGenerator *lto_code_gen_t;
typedef struct LLVMOpaqueThinLTOCodeGenerator *thinlto_code_gen_t;
const char* lto_get_version(void);
const char* lto_get_error_message(void);
lto_bool_t lto_module_is_object_file(const char* path);
lto_bool_t lto_module_is_object_file_for_target(const char* path, const char* target_triple_prefix);
lto_bool_t lto_module_has_objc_category(const void *mem, size_t length);
lto_bool_t lto_module_is_object_file_in_memory(const void *mem, size_t length);
lto_bool_t lto_module_is_object_file_in_memory_for_target(const void* mem, size_t length, const char* target_triple_prefix);
lto_module_t lto_module_create(const char* path);
lto_module_t lto_module_create_from_memory(const void* mem, size_t length);
lto_module_t lto_module_create_from_memory_with_path(const void* mem, size_t length, const char *path);
lto_module_t lto_module_create_in_local_context(const void *mem, size_t length, const char *path);
lto_module_t lto_module_create_in_codegen_context(const void *mem, size_t length, const char *path, lto_code_gen_t cg);
lto_module_t lto_module_create_from_fd(int fd, const char *path, size_t file_size);
lto_module_t lto_module_create_from_fd_at_offset(int fd, const char *path, size_t file_size, size_t map_size, off_t offset);
void lto_module_dispose(lto_module_t mod);
const char* lto_module_get_target_triple(lto_module_t mod);
void lto_module_set_target_triple(lto_module_t mod, const char *triple);
unsigned int lto_module_get_num_symbols(lto_module_t mod);
const char* lto_module_get_symbol_name(lto_module_t mod, unsigned int index);
lto_symbol_attributes lto_module_get_symbol_attribute(lto_module_t mod, unsigned int index);
const char* lto_module_get_linkeropts(lto_module_t mod);
typedef enum {
  LTO_DS_ERROR = 0,
  LTO_DS_WARNING = 1,
  LTO_DS_REMARK = 3,
  LTO_DS_NOTE = 2
} lto_codegen_diagnostic_severity_t;
typedef void (*lto_diagnostic_handler_t)(
    lto_codegen_diagnostic_severity_t severity, const char *diag, void *ctxt);
void lto_codegen_set_diagnostic_handler(lto_code_gen_t,
                                               lto_diagnostic_handler_t,
                                               void *);
lto_code_gen_t lto_codegen_create(void);
lto_code_gen_t lto_codegen_create_in_local_context(void);
void lto_codegen_dispose(lto_code_gen_t);
lto_bool_t lto_codegen_add_module(lto_code_gen_t cg, lto_module_t mod);
void
lto_codegen_set_module(lto_code_gen_t cg, lto_module_t mod);
lto_bool_t
lto_codegen_set_debug_model(lto_code_gen_t cg, lto_debug_model);
lto_bool_t
lto_codegen_set_pic_model(lto_code_gen_t cg, lto_codegen_model);
void
lto_codegen_set_cpu(lto_code_gen_t cg, const char *cpu);
void
lto_codegen_set_assembler_path(lto_code_gen_t cg, const char* path);
void
lto_codegen_set_assembler_args(lto_code_gen_t cg, const char **args,
                               int nargs);
void
lto_codegen_add_must_preserve_symbol(lto_code_gen_t cg, const char* symbol);
lto_bool_t
lto_codegen_write_merged_modules(lto_code_gen_t cg, const char* path);
const void*
lto_codegen_compile(lto_code_gen_t cg, size_t* length);
lto_bool_t
lto_codegen_compile_to_file(lto_code_gen_t cg, const char** name);
lto_bool_t
lto_codegen_optimize(lto_code_gen_t cg);
const void*
lto_codegen_compile_optimized(lto_code_gen_t cg, size_t* length);
unsigned int
lto_api_version(void);
void
lto_codegen_debug_options(lto_code_gen_t cg, const char *);
void
lto_initialize_disassembler(void);
void
lto_codegen_set_should_internalize(lto_code_gen_t cg,
                                   lto_bool_t ShouldInternalize);
void
lto_codegen_set_should_embed_uselists(lto_code_gen_t cg,
                                      lto_bool_t ShouldEmbedUselists);
typedef struct {
  const char *Buffer;
  size_t Size;
} LTOObjectBuffer;
thinlto_code_gen_t thinlto_create_codegen(void);
void thinlto_codegen_dispose(thinlto_code_gen_t cg);
void thinlto_codegen_add_module(thinlto_code_gen_t cg,
                                       const char *identifier, const char *data,
                                       int length);
void thinlto_codegen_process(thinlto_code_gen_t cg);
unsigned int thinlto_module_get_num_objects(thinlto_code_gen_t cg);
LTOObjectBuffer thinlto_module_get_object(thinlto_code_gen_t cg,
                                                 unsigned int index);
unsigned int thinlto_module_get_num_object_files(thinlto_code_gen_t cg);
const char *thinlto_module_get_object_file(thinlto_code_gen_t cg,
                                           unsigned int index);
lto_bool_t thinlto_codegen_set_pic_model(thinlto_code_gen_t cg,
                                                lto_codegen_model);
void thinlto_codegen_set_savetemps_dir(thinlto_code_gen_t cg,
                                              const char *save_temps_dir);
void thinlto_set_generated_objects_dir(thinlto_code_gen_t cg,
                                       const char *save_temps_dir);
void thinlto_codegen_set_cpu(thinlto_code_gen_t cg, const char *cpu);
void thinlto_codegen_disable_codegen(thinlto_code_gen_t cg,
                                            lto_bool_t disable);
void thinlto_codegen_set_codegen_only(thinlto_code_gen_t cg,
                                             lto_bool_t codegen_only);
void thinlto_debug_options(const char *const *options, int number);
lto_bool_t lto_module_is_thinlto(lto_module_t mod);
void thinlto_codegen_add_must_preserve_symbol(thinlto_code_gen_t cg,
                                                     const char *name,
                                                     int length);
void thinlto_codegen_add_cross_referenced_symbol(thinlto_code_gen_t cg,
                                                        const char *name,
                                                        int length);
void thinlto_codegen_set_cache_dir(thinlto_code_gen_t cg,
                                          const char *cache_dir);
void thinlto_codegen_set_cache_pruning_interval(thinlto_code_gen_t cg,
                                                       int interval);
void thinlto_codegen_set_final_cache_size_relative_to_available_space(
    thinlto_code_gen_t cg, unsigned percentage);
void thinlto_codegen_set_cache_entry_expiration(thinlto_code_gen_t cg,
                                                       unsigned expiration);
void thinlto_codegen_set_cache_size_bytes(thinlto_code_gen_t cg,
                                                 unsigned max_size_bytes);
void
thinlto_codegen_set_cache_size_megabytes(thinlto_code_gen_t cg,
                                         unsigned max_size_megabytes);
void thinlto_codegen_set_cache_size_files(thinlto_code_gen_t cg,
                                                 unsigned max_size_files);

// Object.h ------------------------------------------------------------------

typedef struct LLVMOpaqueObjectFile *LLVMObjectFileRef;
typedef struct LLVMOpaqueSectionIterator *LLVMSectionIteratorRef;
typedef struct LLVMOpaqueSymbolIterator *LLVMSymbolIteratorRef;
typedef struct LLVMOpaqueRelocationIterator *LLVMRelocationIteratorRef;
LLVMObjectFileRef LLVMCreateObjectFile(LLVMMemoryBufferRef MemBuf);
void LLVMDisposeObjectFile(LLVMObjectFileRef ObjectFile);
LLVMSectionIteratorRef LLVMGetSections(LLVMObjectFileRef ObjectFile);
void LLVMDisposeSectionIterator(LLVMSectionIteratorRef SI);
LLVMBool LLVMIsSectionIteratorAtEnd(LLVMObjectFileRef ObjectFile,
                                LLVMSectionIteratorRef SI);
void LLVMMoveToNextSection(LLVMSectionIteratorRef SI);
void LLVMMoveToContainingSection(LLVMSectionIteratorRef Sect,
                                 LLVMSymbolIteratorRef Sym);
LLVMSymbolIteratorRef LLVMGetSymbols(LLVMObjectFileRef ObjectFile);
void LLVMDisposeSymbolIterator(LLVMSymbolIteratorRef SI);
LLVMBool LLVMIsSymbolIteratorAtEnd(LLVMObjectFileRef ObjectFile,
                                LLVMSymbolIteratorRef SI);
void LLVMMoveToNextSymbol(LLVMSymbolIteratorRef SI);
const char *LLVMGetSectionName(LLVMSectionIteratorRef SI);
uint64_t LLVMGetSectionSize(LLVMSectionIteratorRef SI);
const char *LLVMGetSectionContents(LLVMSectionIteratorRef SI);
uint64_t LLVMGetSectionAddress(LLVMSectionIteratorRef SI);
LLVMBool LLVMGetSectionContainsSymbol(LLVMSectionIteratorRef SI,
                                 LLVMSymbolIteratorRef Sym);
LLVMRelocationIteratorRef LLVMGetRelocations(LLVMSectionIteratorRef Section);
void LLVMDisposeRelocationIterator(LLVMRelocationIteratorRef RI);
LLVMBool LLVMIsRelocationIteratorAtEnd(LLVMSectionIteratorRef Section,
                                       LLVMRelocationIteratorRef RI);
void LLVMMoveToNextRelocation(LLVMRelocationIteratorRef RI);
const char *LLVMGetSymbolName(LLVMSymbolIteratorRef SI);
uint64_t LLVMGetSymbolAddress(LLVMSymbolIteratorRef SI);
uint64_t LLVMGetSymbolSize(LLVMSymbolIteratorRef SI);
uint64_t LLVMGetRelocationOffset(LLVMRelocationIteratorRef RI);
LLVMSymbolIteratorRef LLVMGetRelocationSymbol(LLVMRelocationIteratorRef RI);
uint64_t LLVMGetRelocationType(LLVMRelocationIteratorRef RI);
const char *LLVMGetRelocationTypeName(LLVMRelocationIteratorRef RI);
const char *LLVMGetRelocationValueString(LLVMRelocationIteratorRef RI);

// OptRemarks.h --------------------------------------------------------------

enum {
	OPT_REMARKS_API_VERSION = 0,
};
typedef struct {
  const char *Str;
  uint32_t Len;
} LLVMOptRemarkStringRef;
typedef struct {
  LLVMOptRemarkStringRef SourceFile;
  uint32_t SourceLineNumber;
  uint32_t SourceColumnNumber;
} LLVMOptRemarkDebugLoc;
typedef struct {
  LLVMOptRemarkStringRef Key;
  LLVMOptRemarkStringRef Value;
  LLVMOptRemarkDebugLoc DebugLoc;
} LLVMOptRemarkArg;
typedef struct {
  LLVMOptRemarkStringRef RemarkType;
  LLVMOptRemarkStringRef PassName;
  LLVMOptRemarkStringRef RemarkName;
  LLVMOptRemarkStringRef FunctionName;
  LLVMOptRemarkDebugLoc DebugLoc;
  uint32_t Hotness;
  uint32_t NumArgs;
  LLVMOptRemarkArg *Args;
} LLVMOptRemarkEntry;
typedef struct LLVMOptRemarkOpaqueParser *LLVMOptRemarkParserRef;
extern LLVMOptRemarkParserRef LLVMOptRemarkParserCreate(const void *Buf,
                                                        uint64_t Size);
extern LLVMOptRemarkEntry *
LLVMOptRemarkParserGetNext(LLVMOptRemarkParserRef Parser);
extern LLVMBool LLVMOptRemarkParserHasError(LLVMOptRemarkParserRef Parser);
extern const char *
LLVMOptRemarkParserGetErrorMessage(LLVMOptRemarkParserRef Parser);
extern void LLVMOptRemarkParserDispose(LLVMOptRemarkParserRef Parser);
extern uint32_t LLVMOptRemarkVersion(void);

// OrcBindings.h -------------------------------------------------------------

typedef struct LLVMOrcOpaqueJITStack *LLVMOrcJITStackRef;
typedef uint64_t LLVMOrcModuleHandle;
typedef uint64_t LLVMOrcTargetAddress;
typedef uint64_t (*LLVMOrcSymbolResolverFn)(const char *Name, void *LookupCtx);
typedef uint64_t (*LLVMOrcLazyCompileCallbackFn)(LLVMOrcJITStackRef JITStack,
                                                 void *CallbackCtx);
LLVMOrcJITStackRef LLVMOrcCreateInstance(LLVMTargetMachineRef TM);
const char *LLVMOrcGetErrorMsg(LLVMOrcJITStackRef JITStack);
void LLVMOrcGetMangledSymbol(LLVMOrcJITStackRef JITStack, char **MangledSymbol,
                             const char *Symbol);
void LLVMOrcDisposeMangledSymbol(char *MangledSymbol);
LLVMErrorRef LLVMOrcCreateLazyCompileCallback(
    LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress *RetAddr,
    LLVMOrcLazyCompileCallbackFn Callback, void *CallbackCtx);
LLVMErrorRef LLVMOrcCreateIndirectStub(LLVMOrcJITStackRef JITStack,
                                       const char *StubName,
                                       LLVMOrcTargetAddress InitAddr);
LLVMErrorRef LLVMOrcSetIndirectStubPointer(LLVMOrcJITStackRef JITStack,
                                           const char *StubName,
                                           LLVMOrcTargetAddress NewAddr);
LLVMErrorRef LLVMOrcAddEagerlyCompiledIR(LLVMOrcJITStackRef JITStack,
                                         LLVMOrcModuleHandle *RetHandle,
                                         LLVMModuleRef Mod,
                                         LLVMOrcSymbolResolverFn SymbolResolver,
                                         void *SymbolResolverCtx);
LLVMErrorRef LLVMOrcAddLazilyCompiledIR(LLVMOrcJITStackRef JITStack,
                                        LLVMOrcModuleHandle *RetHandle,
                                        LLVMModuleRef Mod,
                                        LLVMOrcSymbolResolverFn SymbolResolver,
                                        void *SymbolResolverCtx);
LLVMErrorRef LLVMOrcAddObjectFile(LLVMOrcJITStackRef JITStack,
                                  LLVMOrcModuleHandle *RetHandle,
                                  LLVMMemoryBufferRef Obj,
                                  LLVMOrcSymbolResolverFn SymbolResolver,
                                  void *SymbolResolverCtx);
LLVMErrorRef LLVMOrcRemoveModule(LLVMOrcJITStackRef JITStack,
                                 LLVMOrcModuleHandle H);
LLVMErrorRef LLVMOrcGetSymbolAddress(LLVMOrcJITStackRef JITStack,
                                     LLVMOrcTargetAddress *RetAddr,
                                     const char *SymbolName);
LLVMErrorRef LLVMOrcGetSymbolAddressIn(LLVMOrcJITStackRef JITStack,
                                       LLVMOrcTargetAddress *RetAddr,
                                       LLVMOrcModuleHandle H,
                                       const char *SymbolName);
LLVMErrorRef LLVMOrcDisposeInstance(LLVMOrcJITStackRef JITStack);
void LLVMOrcRegisterJITEventListener(LLVMOrcJITStackRef JITStack, LLVMJITEventListenerRef L);
void LLVMOrcUnregisterJITEventListener(LLVMOrcJITStackRef JITStack, LLVMJITEventListenerRef L);

// Support.h -----------------------------------------------------------------

LLVMBool LLVMLoadLibraryPermanently(const char* Filename);
void LLVMParseCommandLineOptions(int argc, const char *const *argv,
                                 const char *Overview);
void *LLVMSearchForAddressOfSymbol(const char *symbolName);
void LLVMAddSymbol(const char *symbolName, void *symbolValue);

// Transforms/*.h ------------------------------------------------------------

void LLVMAddAggressiveInstCombinerPass(LLVMPassManagerRef PM);
void LLVMAddCoroEarlyPass(LLVMPassManagerRef PM);
void LLVMAddCoroSplitPass(LLVMPassManagerRef PM);
void LLVMAddCoroElidePass(LLVMPassManagerRef PM);
void LLVMAddCoroCleanupPass(LLVMPassManagerRef PM);
void LLVMAddInstructionCombiningPass(LLVMPassManagerRef PM);
void LLVMAddArgumentPromotionPass(LLVMPassManagerRef PM);
void LLVMAddConstantMergePass(LLVMPassManagerRef PM);
void LLVMAddCalledValuePropagationPass(LLVMPassManagerRef PM);
void LLVMAddDeadArgEliminationPass(LLVMPassManagerRef PM);
void LLVMAddFunctionAttrsPass(LLVMPassManagerRef PM);
void LLVMAddFunctionInliningPass(LLVMPassManagerRef PM);
void LLVMAddAlwaysInlinerPass(LLVMPassManagerRef PM);
void LLVMAddGlobalDCEPass(LLVMPassManagerRef PM);
void LLVMAddGlobalOptimizerPass(LLVMPassManagerRef PM);
void LLVMAddIPConstantPropagationPass(LLVMPassManagerRef PM);
void LLVMAddPruneEHPass(LLVMPassManagerRef PM);
void LLVMAddIPSCCPPass(LLVMPassManagerRef PM);
void LLVMAddInternalizePass(LLVMPassManagerRef, unsigned AllButMain);
void LLVMAddStripDeadPrototypesPass(LLVMPassManagerRef PM);
void LLVMAddStripSymbolsPass(LLVMPassManagerRef PM);
typedef struct LLVMOpaquePassManagerBuilder *LLVMPassManagerBuilderRef;
LLVMPassManagerBuilderRef LLVMPassManagerBuilderCreate(void);
void LLVMPassManagerBuilderDispose(LLVMPassManagerBuilderRef PMB);
void LLVMPassManagerBuilderSetOptLevel(LLVMPassManagerBuilderRef PMB, unsigned OptLevel);
void LLVMPassManagerBuilderSetSizeLevel(LLVMPassManagerBuilderRef PMB, unsigned SizeLevel);
void LLVMPassManagerBuilderSetDisableUnitAtATime(LLVMPassManagerBuilderRef PMB, LLVMBool Value);
void LLVMPassManagerBuilderSetDisableUnrollLoops(LLVMPassManagerBuilderRef PMB, LLVMBool Value);
void LLVMPassManagerBuilderSetDisableSimplifyLibCalls(LLVMPassManagerBuilderRef PMB, LLVMBool Value);
void LLVMPassManagerBuilderUseInlinerWithThreshold(LLVMPassManagerBuilderRef PMB, unsigned Threshold);
void LLVMPassManagerBuilderPopulateFunctionPassManager(LLVMPassManagerBuilderRef PMB, LLVMPassManagerRef PM);
void LLVMPassManagerBuilderPopulateModulePassManager(LLVMPassManagerBuilderRef PMB,
                                                     LLVMPassManagerRef PM);
void LLVMPassManagerBuilderPopulateLTOPassManager(LLVMPassManagerBuilderRef PMB,
                                                  LLVMPassManagerRef PM,
                                                  LLVMBool Internalize,
                                                  LLVMBool RunInliner);
void LLVMAddAggressiveDCEPass(LLVMPassManagerRef PM);
void LLVMAddBitTrackingDCEPass(LLVMPassManagerRef PM);
void LLVMAddAlignmentFromAssumptionsPass(LLVMPassManagerRef PM);
void LLVMAddCFGSimplificationPass(LLVMPassManagerRef PM);
void LLVMAddDeadStoreEliminationPass(LLVMPassManagerRef PM);
void LLVMAddScalarizerPass(LLVMPassManagerRef PM);
void LLVMAddMergedLoadStoreMotionPass(LLVMPassManagerRef PM);
void LLVMAddGVNPass(LLVMPassManagerRef PM);
void LLVMAddNewGVNPass(LLVMPassManagerRef PM);
void LLVMAddIndVarSimplifyPass(LLVMPassManagerRef PM);
void LLVMAddInstructionCombiningPass(LLVMPassManagerRef PM);
void LLVMAddJumpThreadingPass(LLVMPassManagerRef PM);
void LLVMAddLICMPass(LLVMPassManagerRef PM);
void LLVMAddLoopDeletionPass(LLVMPassManagerRef PM);
void LLVMAddLoopIdiomPass(LLVMPassManagerRef PM);
void LLVMAddLoopRotatePass(LLVMPassManagerRef PM);
void LLVMAddLoopRerollPass(LLVMPassManagerRef PM);
void LLVMAddLoopUnrollPass(LLVMPassManagerRef PM);
void LLVMAddLoopUnrollAndJamPass(LLVMPassManagerRef PM);
void LLVMAddLoopUnswitchPass(LLVMPassManagerRef PM);
void LLVMAddLowerAtomicPass(LLVMPassManagerRef PM);
void LLVMAddMemCpyOptPass(LLVMPassManagerRef PM);
void LLVMAddPartiallyInlineLibCallsPass(LLVMPassManagerRef PM);
void LLVMAddReassociatePass(LLVMPassManagerRef PM);
void LLVMAddSCCPPass(LLVMPassManagerRef PM);
void LLVMAddScalarReplAggregatesPass(LLVMPassManagerRef PM);
void LLVMAddScalarReplAggregatesPassSSA(LLVMPassManagerRef PM);
void LLVMAddScalarReplAggregatesPassWithThreshold(LLVMPassManagerRef PM, int Threshold);
void LLVMAddSimplifyLibCallsPass(LLVMPassManagerRef PM);
void LLVMAddTailCallEliminationPass(LLVMPassManagerRef PM);
void LLVMAddConstantPropagationPass(LLVMPassManagerRef PM);
void LLVMAddDemoteMemoryToRegisterPass(LLVMPassManagerRef PM);
void LLVMAddVerifierPass(LLVMPassManagerRef PM);
void LLVMAddCorrelatedValuePropagationPass(LLVMPassManagerRef PM);
void LLVMAddEarlyCSEPass(LLVMPassManagerRef PM);
void LLVMAddEarlyCSEMemSSAPass(LLVMPassManagerRef PM);
void LLVMAddLowerExpectIntrinsicPass(LLVMPassManagerRef PM);
void LLVMAddTypeBasedAliasAnalysisPass(LLVMPassManagerRef PM);
void LLVMAddScopedNoAliasAAPass(LLVMPassManagerRef PM);
void LLVMAddBasicAliasAnalysisPass(LLVMPassManagerRef PM);
void LLVMAddUnifyFunctionExitNodesPass(LLVMPassManagerRef PM);
void LLVMAddLowerSwitchPass(LLVMPassManagerRef PM);
void LLVMAddPromoteMemoryToRegisterPass(LLVMPassManagerRef PM);
void LLVMAddLoopVectorizePass(LLVMPassManagerRef PM);
void LLVMAddSLPVectorizePass(LLVMPassManagerRef PM);
]]
