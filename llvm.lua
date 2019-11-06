
--LLVM 8 C API ffi binding (x86 target).
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'llvm_test'; return end

local ffi = require'ffi'
local glue = require'glue'
local require, type, select, print =
      require, type, select, print
local add, concat = table.insert, table.concat
local free = ffi.C.free
local memoize = glue.memoize
require'llvm_h'
local C = ffi.load'llvm'
local M = setmetatable({}, {__index = C})
setfenv(1, M)

native_target = 'x86'

local sp = ffi.new'char*[1]'
local addrp = ffi.new'uint64_t[1]'
local sizep = ffi.new'size_t[1]'
local modp = ffi.new'LLVMModuleRef[1]'
local targetp = ffi.new'LLVMTargetRef[1]'
local enginep = ffi.new'LLVMExecutionEngineRef[1]'
local membufp = ffi.new'LLVMMemoryBufferRef[1]'

local function ptrornil(p)
	return p ~= nil and p or nil
end

local function retbool(f)
	return function(...)
		return f(...) == 1
	end
end

local function retstring(f)
	return function(...)
		local p = f(...)
		return p ~= nil and ffi.string(p) or nil
	end
end

local function countfrom1(f)
	return function(self, i)
		return f(self, i-1)
	end
end

local function getset(get, set)
	return function(self, arg)
		if arg then
			set(self, arg)
		else
			return get(self)
		end
	end
end

--error handling -------------------------------------------------------------

function LLVMGetErrorMessage(err)
	local sp = LLVMGetErrorMessage(err)
	if sp ~= nil then
		local s = ffi.string(sp)
		LLVMDisposeErrorMessage(sp)
		return s
	else
		return nil
	end
end

ffi.metatype('struct LLVMOpaqueError', {__index = {
	type_id = LLVMGetErrorTypeId,
	consume = LLVMConsumeError,
	message = LLVMGetErrorMessage,
}})

--memory buffers -------------------------------------------------------------

function membuffer(s, name) --NOTE: s must be pinned externally!
	return C.LLVMCreateMemoryBufferWithMemoryRange(s, #s, name or '<buffer>', false)
end

ffi.metatype('struct LLVMOpaqueMemoryBuffer', {__index = {
	free = LLVMDisposeMemoryBuffer,
	data = LLVMGetBufferStart,
	size = LLVMGetBufferSize,
}})

--metadata -------------------------------------------------------------------

function LLVMDITypeGetName(MD)
	local s = C.LLVMDITypeGetName(MD, sizep)
	return s ~= nil and ffi.string(s, sizep[0]) or nil
end

function LLVMTemporaryMDNode(MD, n)
	return C.LLVMTemporaryMDNode(LLVMGetGlobalContext(), MD, n)
end

ffi.metatype('struct LLVMOpaqueMetadata', {__index = {
	kind = LLVMGetMetadataKind,
	line = LLVMDILocationGetLine,
	col = LLVMDILocationGetColumn,
	scope = LLVMDILocationGetScope,
	typename = LLVMDITypeGetName,
	bitsize = LLVMDITypeGetSizeInBits,
	bitoffset = LLVMDITypeGetOffsetInBits,
	bitalign = LLVMDITypeGetAlignInBits,
	typeline = LLVMDITypeGetLine,
	typeflags = LLVMDITypeGetFlags,
	temp_node = LLVMTemporaryMDNode,
	free_temp_node = LLVMDisposeTemporaryMDNode,
	subprogram = getset(LLVMGetSubprogram, LLVMSetSubprogram),
}})

--debug info -----------------------------------------------------------------

debug_metadata_version = LLVMDebugMetadataVersion

ffi.metatype('struct LLVMOpaqueDIBuilder', {__index = {
	free = LLVMDisposeDIBuilder,
	finalize = LLVMDIBuilderFinalize,

	compile_unit = LLVMDIBuilderCreateCompileUnit,
	file = LLVMDIBuilderCreateFile,
	module = LLVMDIBuilderCreateModule,
	namespace = LLVMDIBuilderCreateNameSpace,
	fn = LLVMDIBuilderCreateFunction,
	lexical_block = LLVMDIBuilderCreateLexicalBlock,
	lexical_block_file = LLVMDIBuilderCreateLexicalBlockFile, --huh?
	imported_module_from_namespace = LLVMDIBuilderCreateImportedModuleFromNamespace,
	imported_module_from_alias = LLVMDIBuilderCreateImportedModuleFromAlias,
	imported_module_from_module = LLVMDIBuilderCreateImportedModuleFromModule,
	imported_decl = LLVMDIBuilderCreateImportedDeclaration,
	debug_location = LLVMDIBuilderCreateDebugLocation,
	subroutine = LLVMDIBuilderCreateSubroutineType,
	enum = LLVMDIBuilderCreateEnumerationType,
	union = LLVMDIBuilderCreateUnionType,
	array = LLVMDIBuilderCreateArrayType,
	--TODO: array = LLVMDIBuilderGetOrCreateArray,
	--TODO: array = LLVMDIBuilderGetOrCreateTypeArray,
	vec = LLVMDIBuilderCreateVectorType,
	unspecified_type = LLVMDIBuilderCreateUnspecifiedType,
	type = LLVMDIBuilderCreateBasicType,
	ptr = LLVMDIBuilderCreatePointerType,
	struct = LLVMDIBuilderCreateStructType,
	field = LLVMDIBuilderCreateMemberType,
	static_field = LLVMDIBuilderCreateStaticMemberType,
	ptr_field = LLVMDIBuilderCreateMemberPointerType,
	objc_ivar = LLVMDIBuilderCreateObjCIVar,
	objc_property = LLVMDIBuilderCreateObjCProperty,
	obj_ptr = LLVMDIBuilderCreateObjectPointerType,
	qualified_type = LLVMDIBuilderCreateQualifiedType,
	ref = LLVMDIBuilderCreateReferenceType,
	nullptr = LLVMDIBuilderCreateNullPtrType,
	typedef = LLVMDIBuilderCreateTypedef,
	inheritance = LLVMDIBuilderCreateInheritance,
	forward_decl = LLVMDIBuilderCreateForwardDecl,
	replaceable_composite = LLVMDIBuilderCreateReplaceableCompositeType,
	bit_field = LLVMDIBuilderCreateBitFieldMemberType,
	class = LLVMDIBuilderCreateClassType,
	artificial_type = LLVMDIBuilderCreateArtificialType,
	subrange = LLVMDIBuilderGetOrCreateSubrange,
	expr = LLVMDIBuilderCreateExpression,
	const_expr = LLVMDIBuilderCreateConstantValueExpression,
	global_expr = LLVMDIBuilderCreateGlobalVariableExpression,
	temp_global_forward_decl = LLVMDIBuilderCreateTempGlobalVariableFwdDecl,
	insert_declare_before = LLVMDIBuilderInsertDeclareBefore,
	insert_declare_at_end = LLVMDIBuilderInsertDeclareAtEnd,
	insert_debug_value_before = LLVMDIBuilderInsertDbgValueBefore,
	insert_debug_value_at_end = LLVMDIBuilderInsertDbgValueAtEnd,
	auto_var = LLVMDIBuilderCreateAutoVariable,
	param = LLVMDIBuilderCreateParameterVariable,
	replace_uses = LLVMMetadataReplaceAllUsesWith,
}})

--types ----------------------------------------------------------------------

function types(...)
	local t = ...
	if type(t) == 'table' then
		local n = #t
		return ffi.new('LLVMTypeRef[?]', n, t), n
	else
		local n = select('#', ...)
		return ffi.new('LLVMTypeRef[?]', n, ...), n
	end
end

local function LLVMFunctionType_(vararg, ret_type, ...)
	local param_types, n = types(...)
	return C.LLVMFunctionType(ret_type, param_types, n, vararg)
end
function LLVMFunctionType(...)
	if type((...)) ~= 'boolean' then
		return LLVMFunctionType_(false, ...)
	else
		return LLVMFunctionType_(...)
	end
end
fn = LLVMFunctionType

int1     = LLVMInt1Type()
int8     = LLVMInt8Type()
int16    = LLVMInt16Type()
int32    = LLVMInt32Type()
int64    = LLVMInt64Type()
int128   = LLVMInt128Type()
int      = LLVMIntType
half     = LLVMHalfType()
float    = LLVMFloatType()
double   = LLVMDoubleType()
fp80     = LLVMX86FP80Type()
fp128    = LLVMFP128Type()
void     = LLVMVoidType()
label    = LLVMLabelType()
mmx      = LLVMX86MMXType()
array    = LLVMArrayType
ptr      = LLVMPointerType
vec      = LLVMVectorType


function LLVMPrintTypeToString(M)
	local sp = C.LLVMPrintTypeToString(M)
	local s = ffi.string(sp)
	free(sp)
	return s
end

LLVMIsFunctionVarArg = retbool(LLVMIsFunctionVarArg)

function LLVMGetParamTypes(T)
	local n = T:param_count()
	local types = ffi.new('LLVMTypeRef[?]', n)
	C.LLVMGetParamTypes(T, types)
	return types, n
end

local function LLVMStructType_(packed, ...)
	local types, n = types(...)
	return C.LLVMStructType(types, n, packed)
end
function LLVMStructType(...)
	if type((...)) ~= 'boolean' then
		return LLVMStructType_(false, ...)
	else
		return LLVMStructType_(...)
	end
end
struct = LLVMStructType

function LLVMGetStructElementTypes(T)
	local n = T:elem_count()
	local types = ffi.new('LLVMTypeRef[?]', n)
	C.LLVMGetStructElementTypes(T, types)
	return types, n
end

local function LLVMStructSetBody_(T, packed, ...)
	local types, n = types(...)
	C.LLVMStructSetBody(T, types, n, packed)
end
function LLVMStructSetBody(T, ...)
	if type((...)) ~= 'boolean' then
		return LLVMStructSetBody_(false, ...)
	else
		return LLVMStructSetBody_(...)
	end
end

function LLVMGetSubtypes(T)
	local n = T:subtype_count()
	local types = ffi.new('LLVMTypeRef[?]', n)
	C.LLVMGetSubtypes(T, types)
	return types, n
end

LLVMIsOpaqueStruct = retbool(LLVMIsOpaqueStruct)

local function ctype_string(t)
	local k = t:kind()
	if k == C.LLVMVoidTypeKind then
		return 'void'
	elseif k == C.LLVMFloatTypeKind then
		return 'float'
	elseif k == C.LLVMDoubleTypeKind then
		return 'double'
	elseif k == C.LLVMIntegerTypeKind then
		local w = t:int_width()
		if w == 8 or w == 16 or w == 32 or w == 64 then
			return 'int'..t:int_width()..'_t'
		end
	elseif k == C.LLVMFunctionTypeKind then
		--
	elseif k == C.LLVMStructTypeKind then
		local dt = 'struct {\n\t'
		for i = 1, t:elem_count() do
			add(dt, t:elem_type(i):ctype_string())
			--TODO: add(dt, t:)
			add(dt, ',\n\t')
		end
		add(dt, '}')
		return concat(dt)
	elseif k == C.LLVMArrayTypeKind then
		return t:elem_type():ctype_string()..'['..t:len()..']'
	elseif k == C.LLVMPointerTypeKind then
		return
	end
end

LLVMStructGetTypeAtIndex = countfrom1(LLVMStructGetTypeAtIndex)

function type_from_ctype(ct)
	local ffi_reflect = require'ffi_reflect'
	local r = ffi_reflect.typeof(ct)
	local k = r.what
	if k == 'void' then
		return void
	elseif k == 'int' then
		local z = r.size
		if z == 1 then
			return int8
		elseif z == 2 then
			return int16
		elseif z == 4 then
			return int32
		elseif z == 8 then
			return int64
		end
	elseif k == 'float' then
		return float
	elseif k == 'double' then
		return double
	elseif k == 'enum' then
		return int32
	elseif k == 'ptr' or k == 'ref' then
		return ptr(type_from_ctype(r.element_type))
	elseif k == 'array' then
		local n = r.size / r.element_type.size
		return array(type_from_ctype(r.element_type), n)
	elseif k == 'struct' then
		local ft = {}
		for r in r:members() do
			add(ft, type_from_ctype(r.what))
		end
		return struct(ft)
	end
end

ffi.metatype('struct LLVMOpaqueType', {__index = {
	kind = LLVMGetTypeKind,
	is_sized = LLVMTypeIsSized,
	tostring = LLVMPrintTypeToString,
	align = LLVMAlignOf,
	size = LLVMSizeOf,
	--integer types
	int_width = LLVMGetIntTypeWidth,
	--function types
	is_vararg = LLVMIsFunctionVarArg,
	ret_type = LLVMGetReturnType,
	param_count = LLVMCountParamTypes,
	param_types = LLVMGetParamTypes,
	--struct types
	elem_count = LLVMCountStructElementTypes,
	elem_types = LLVMGetStructElementTypes,
	elem_type = LLVMStructGetTypeAtIndex,
	is_packed = LLVMIsPackedStruct,
	is_opaque = LLVMIsOpaqueStruct,
	is_literal = LLVMIsLiteralStruct,
	set_elems = LLVMStructSetBody,
	--sequential types
	elem_type = LLVMGetElementType,
	subtype_count = LLVMGetNumContainedTypes,
	subtypes = LLVMGetSubtypes,
	--array types
	len = LLVMGetArrayLength,
	--pointer types
	addr_space = LLVMGetPointerAddressSpace,
	--vector types
	vec_size = LLVMGetVectorSize,
	--ffi
	ctype_string = ctype_string,
}})

--constants ------------------------------------------------------------------

function LLVMConstString(s, dont_null_terminate)
	return C.LLVMConstString(s, #s, dont_null_terminate or false)
end

function LLVMConstStruct_(packed, ...)
	local values, n = values(...)
	return C.LLVMConstStruct(values, n, packed)
end
function LLVMConstStruct(...)
	if type((...)) ~= 'boolean' then
		return LLVMConstStruct_(false, ...)
	else
		return LLVMConstStruct_(...)
	end
end

function LLVMConstArray(T, ...)
	local values, n = values(...)
	return C.LLVMConstArray(T, values, n)
end

function LLVMConstVector(...)
	local values, n = values(...)
	return C.LLVMConstVector(values, n)
end

const_null     = LLVMConstNull
const_all_ones = LLVMConstAllOnes
undef          = LLVMGetUndef
const_ptr_null = LLVMConstPointerNull
const_int      = LLVMConstInt
const_real     = LLVMConstReal
const_string   = LLVMConstString
const_struct   = LLVMConstStruct
const_array    = LLVMConstArray
const_vec      = LLVMConstVector

--const_apint    = LLVMConstIntOfArbitraryPrecision --TODO: wrap
--TODO: LLVMConstIntOfString, LLVMConstIntOfStringAndSize
--TODO: LLVMConstRealOfString

--values ---------------------------------------------------------------------

LLVMIsNull = retbool(LLVMIsNull)
LLVMIsDeclaration = retbool(LLVMIsDeclaration)
LLVMGetSection = retstring(LLVMGetSection)
LLVMHasUnnamedAddr = retbool(LLVMHasUnnamedAddr)
LLVMValueIsBasicBlock = retbool(LLVMValueIsBasicBlock)

function LLVMGetBasicBlocks(V)
	local n = V:block_count()
	local blocks = ffi.new('LLVMOpaqueBasicBlock[?]', n)
	C.LLVMGetBasicBlocks(V, blocks)
	return blocks, n
end

ffi.metatype('struct LLVMOpaqueValue', {__index = {
	block = LLVMAppendBasicBlock,
	param_count = LLVMCountParams,
	param = LLVMGetParam,
	param_align = LLVMSetParamAlignment,
	type  = LLVMTypeOf,
	is_block = LLVMValueIsBasicBlock,
	as_block = LLVMValueAsBasicBlock,
	block_count = LLVMCountBasicBlocks,
	blocks = LLVMGetBasicBlocks,
	is_null = LLVMIsNull,
	is_decl = LLVMIsDeclaration,
	linkage = getset(LLVMGetLinkage, LLVMSetLinkage),
	section = getset(LLVMSetSection, LLVMGetSection),
	visibility = getset(LLVMGetVisibility, LLVMSetVisibility),
	dll_storage_class = getset(LLVMGetDLLStorageClass, LLVMSetDLLStorageClass),
	unnamed_addr = getset(LLVMGetUnnamedAddress, LLVMSetUnnamedAddress),
	has_unnamed_addr = getset(LLVMHasUnnamedAddr, LLVMSetUnnamedAddr),
	alignment = getset(LLVMGetAlignment, LLVMSetAlignment),
	init = getset(LLVMGetInitializer, LLVMSetInitializer),
	is_thread_local = getset(LLVMIsThreadLocal, LLVMSetThreadLocal),
	is_global_const = getset(LLVMIsGlobalConstant, LLVMSetGlobalConstant),
	thread_local_mode = getset(LLVMGetThreadLocalMode, LLVMSetThreadLocalMode),
	is_ext_init = getset(LLVMIsExternallyInitialized, LLVMSetExternallyInitialized),
	call_conv = getset(LLVMGetFunctionCallConv, LLVMSetFunctionCallConv),
	is_tail_call = getset(LLVMIsTailCall, LLVMSetTailCall),
	--instructions
	opcode = LLVMGetInstructionOpcode,
	--conditions
	cond = getset(LLVMGetCondition, LLVMSetCondition),
}})

--generic values -------------------------------------------------------------

function values(...)
	local n = select('#', ...)
	return ffi.new('LLVMGenericValueRef[?]', n, ...), n
end

function value(t, v)
	local k = t:kind()
	if k == C.LLVMFloatTypeKind or k == C.LLVMDoubleTypeKind then
		return floatval(t, v)
	elseif k == C.LLVMIntegerTypeKind then
		return intval(t, v)
	elseif k == C.LLVMStructTypeKind then
		local dt = 'struct {\n\t'
		for i = 1, t:elem_count() do
			add(dt, t:elem_type(i):ctype_string())
			--TODO: add(dt, t:)
			add(dt, ',\n\t')
		end
		add(dt, '}')
		return concat(dt)
	elseif k == C.LLVMArrayTypeKind then
		return t:elem_type():ctype_string()..'['..t:len()..']'
	elseif k == C.LLVMPointerTypeKind then
		return
	end
end

function param_values(fn, ...)
	local pt, n = fn:param_types()
	fn:is_vararg()
	local vt = ffi.new('LLVMGenericValueRef[?]', n)
	for i = 1, n do
		local t = pt[i-1]
		local v = select(i, ...)
		vt[i-1] = value(t, v)
	end
end

function intval(t, x) return LLVMCreateGenericValueOfInt(t, x, true) end
function uintval(t, x) return LLVMCreateGenericValueOfInt(t, x, false) end

ptrval = LLVMCreateGenericValueOfPointer
floatval = LLVMCreateGenericValueOfFloat

local int64_t = ffi.typeof'int64_t'
ffi.metatype('struct LLVMOpaqueGenericValue', {__index = {
	int_width = LLVMGenericValueIntWidth,
	toint = function(GenVal) return ffi.cast(int64_t, LLVMGenericValueToInt(GenVal, true)) end,
	touint = function (GenVal) return LLVMGenericValueToInt(GenVal, false) end,
	toptr = LLVMGenericValueToPointer,
	tofloat = LLVMGenericValueToFloat,
}})

--builders -------------------------------------------------------------------

builder = LLVMCreateBuilder

ffi.metatype('struct LLVMOpaqueBuilder', {__index = {

	free = LLVMDisposeBuilder,

	position_at     = LLVMPositionBuilder,
	position_before = LLVMPositionBuilderBefore,
	position_at_end = LLVMPositionBuilderAtEnd,

	add = LLVMBuildAdd,

	ret_void = LLVMBuildRetVoid,
	ret = LLVMBuildRet,

	debug_location = getset(LLVMGetCurrentDebugLocation, LLVMSetCurrentDebugLocation),
	inst_debug_location = LLVMSetInstDebugLocation,

}})

--execution engines ----------------------------------------------------------

local mcjit_linked
local function LLVMLinkInMCJIT()
	if not mcjit_linked then return end
	C.LLVMLinkInMCJIT()
	mcjit_linked = true
end

local initialized
local function LLVMInitializeX86Target()
	if initialized then return end
	C.LLVMInitializeX86TargetInfo()
	C.LLVMInitializeX86Target()
	C.LLVMInitializeX86TargetMC()
	C.LLVMInitializeX86AsmPrinter()
	C.LLVMInitializeX86AsmParser()
	C.LLVMInitializeX86Disassembler()
	initialized = true
end
LLVMInitializeNativeTarget = LLVMInitializeX86Target
LLVMInitializeAllTargets = LLVMInitializeNativeTarget

function LLVMCreateExecutionEngineForModule(M, mode, opt_level)
	LLVMInitializeNativeTarget()
	LLVMLinkInMCJIT()
	LLVMLinkInInterpreter()
	local ret
	if mode == 'interpreter' then
		ret = C.LLVMCreateInterpreterForModule(enginep, M, sp)
	elseif mode == 'jit' then
		opt_level = opt_level or LLVMCodeGenLevelDefault
		ret = C.LLVMCreateJITCompilerForModule(enginep, M, opt_level, sp)
	else
		ret = C.LLVMCreateExecutionEngineForModule(enginep, M, sp)
	end
	if ret ~= 0 then
		local s = ffi.string(sp[0])
		C.LLVMDisposeMessage(sp[0])
		return nil, s
	end
	return enginep[0]
end

function LLVMRunFunction(EE, F, args)
	local nargs = ffi.sizeof(args) / ffi.sizeof'LLVMGenericValueRef'
	return C.LLVMRunFunction(EE, F, nargs, args)
end

ffi.metatype('struct LLVMOpaqueExecutionEngine', {__index = {
	free = LLVMDisposeExecutionEngine,
	run = LLVMRunFunction,
	add_module = LLVMAddModule,
	global_ptr = LLVMGetPointerToGlobal,
	global_addr = LLVMGetGlobalValueAddress,
	fn_addr = LLVMGetFunctionAddress,
}})

--targets --------------------------------------------------------------------

function LLVMGetTargetFromName(name)
	LLVMInitializeAllTargets()
	return ptrornil(C.LLVMGetTargetFromName(name))
end
--LLVMGetTargetFromName = memoize(LLVMGetTargetFromName)

function target(name)
	return LLVMGetTargetFromName(name or native_target)
end

function LLVMGetTargetFromTriple(s)
	LLVMInitializeAllTargets()
	if C.LLVMGetTargetFromTriple(s, targetp, sp) ~= 0 then
		local s = ffi.string(sp[0])
		free(sp[0])
		return nil, s
	else
		return targetp[0]
	end
end
target_from_triple = LLVMGetTargetFromTriple

LLVMGetTargetName = retstring(LLVMGetTargetName)
LLVMGetTargetDescription = retstring(LLVMGetTargetDescription)
LLVMTargetHasJIT = retbool(LLVMTargetHasJIT)
LLVMTargetHasTargetMachine = retbool(LLVMTargetHasTargetMachine)
LLVMTargetHasAsmBackend = retbool(LLVMTargetHasAsmBackend)

function LLVMCreateTargetMachine(T, triple, cpu_name,
	features, codegen_level, reloc_mode, code_model
)
	return ptrornil(C.LLVMCreateTargetMachine(T,
		triple or default_target_triple(),
		cpu_name or host_cpu_name(),
		features or host_cpu_features(),
		codegen_level or LLVMCodeGenLevelDefault,
		reloc_mode or LLVMRelocPIC,
		code_model or LLVMCodeModelDefault))
end

ffi.metatype('struct LLVMTarget', {__index = {
	name = LLVMGetTargetName,
	descr = LLVMGetTargetDescription,
	has_jit = LLVMTargetHasJIT,
	has_machine = LLVMTargetHasTargetMachine,
	has_asm_backend = LLVMTargetHasAsmBackend,
	machine = LLVMCreateTargetMachine,
}})

LLVMGetTargetMachineTriple = retstring(LLVMGetTargetMachineTriple)
LLVMGetTargetMachineCPU = retstring(LLVMGetTargetMachineCPU)
LLVMGetTargetMachineFeatureString = retstring(LLVMGetTargetMachineFeatureString)

local CGFT = {
	asm = LLVMAssemblyFile,
	obj = LLVMObjectFile,
}
function LLVMTargetMachineEmitToString(TM, M, codegen)
	local codegen = CGFT[codegen or 'asm']
	if C.LLVMTargetMachineEmitToMemoryBuffer(TM, M, codegen, sp, membufp) ~= 0 then
		local s = ffi.string(sp[0])
		free(sp[0])
		return nil, s
	else
		return membuf:tostring()
	end
end

ffi.metatype('struct LLVMOpaqueTargetMachine', {__index = {
	free = LLVMDisposeTargetMachine,
	target = LLVMGetTargetMachineTarget,
	triple = LLVMGetTargetMachineTriple,
	cpu = LLVMGetTargetMachineCPU,
	features = LLVMGetTargetMachineFeatureString,
	data_layout = LLVMCreateTargetDataLayout,
	asm_verbosity = LLVMSetTargetMachineAsmVerbosity,
	compile = LLVMTargetMachineEmitToString,
	add_analysis_passes = LLVMAddAnalysisPasses,
}})

LLVMGetDefaultTargetTriple = memoize(retstring(LLVMGetDefaultTargetTriple))
LLVMNormalizeTargetTriple = retstring(LLVMNormalizeTargetTriple)
LLVMGetHostCPUName = memoize(retstring(LLVMGetHostCPUName))
LLVMGetHostCPUFeatures = memoize(retstring(LLVMGetHostCPUFeatures))

default_target_triple = LLVMGetDefaultTargetTriple
normalize_target_triple = LLVMNormalizeTargetTriple
host_cpu_name = LLVMGetHostCPUName
host_cpu_features = LLVMGetHostCPUFeatures

target_data = C.LLVMCreateTargetData

function LLVMCopyStringRepOfTargetData(TD)
	local sp = C.LLVMCopyStringRepOfTargetData(TD)
	local s = ffi.string(sp)
	free(sp)
	return s
end

ffi.metatype('struct LLVMOpaqueTargetData', {__index = {
	free = LLVMDisposeTargetData,
	byte_order = LLVMByteOrder,
	pointer_size = LLVMPointerSize,
	pointer_size_for_as = LLVMPointerSizeForAS,
	int_ptr_type = LLVMIntPtrType,
	int_ptr_type_for_as = LLVMIntPtrTypeForAS,
	bit_sizeof = LLVMSizeOfTypeInBits,
	sizeof = LLVMStoreSizeOfType,
	abi_sizeof = LLVMABISizeOfType,
	abi_align = LLVMABIAlignmentOfType,
	call_frame_align = LLVMCallFrameAlignmentOfType,
	preferred_align = LLVMPreferredAlignmentOfType,
	global_preferred_align = LLVMPreferredAlignmentOfGlobal,
	elem_at_offset = LLVMElementAtOffset,
	elem_offset = LLVMOffsetOfElement,
	tostring = LLVMCopyStringRepOfTargetData,
}})

--modules --------------------------------------------------------------------

function LLVMParseBitcode(s)
	local membuf = membuffer(s) --TODO: does the module get to own the membuf?
	if C.LLVMParseBitcode(membuf, modp, sp) ~= 0 then
		local s = ffi.string(sp)
		free(sp[0])
		return nil, s
	else
		return modp[0]
	end
end
parse_bitcode = LLVMParseBitcode
module = LLVMModuleCreateWithName

function LLVMVerifyModule(M, Action)
	if C.LLVMVerifyModule(M, Action or LLVMAbortProcessAction, sp) ~= 0 then
		local s = ffi.string(sp[0])
		LLVMDisposeMessage(sp[0])
		return false, s
	end
	return true
end

function LLVMPrintModuleToString(M)
	local sp = C.LLVMPrintModuleToString(M)
	local s = ffi.string(sp)
	free(sp)
	return s
end

function LLVMSetModuleInlineAsm(M, s)
	C.LLVMSetModuleInlineAsm2(M, s, #s)
end

function LLVMGetModuleInlineAsm(M, ip)
	local s = C.LLVMGetModuleInlineAsm(M, sizep)
	return ffi.string(s, sizep[0])
end

function LLVMParseIR(s, name)
	local membuf = membuffer(s, name) --gets owned by the module
	if C.LLVMParseIRInContext(LLVMGetGlobalContext(), membuf, modp, sp) ~= 0 then
		local s = ffi.string(sp[0])
		free(sp[0])
		return nil, s
	else
		return modp[0]
	end
end
parse_ir = LLVMParseIR

function LLVMLinkModules(M, SM)
	return C.LLVMLinkModules2(M, SM) == 0
end

function LLVMWriteBitcodeToString(M)
	local membuf = C.LLVMWriteBitcodeToMemoryBuffer(M)
	local s = ffi.string(membuf:data(), membuf:size())
	membuf:free()
	return s
end

LLVMGetTarget = retstring(LLVMGetTarget)

function LLVMCreateDIBuilder(M, disallow_unresolved)
	if disallow_unresolved then
		return C.LLVMCreateDIBuilderDisallowUnresolved(M)
	else
		return C.LLVMCreateDIBuilder(M)
	end
end

ffi.metatype('struct LLVMOpaqueModule', {__index = {
	free = LLVMDisposeModule,
	fn = LLVMAddFunction,
	global = LLVMAddGlobal,
	type = LLVMGetTypeByName,
	verify = LLVMVerifyModule,
	ir = LLVMPrintModuleToString,
	inline_asm = getset(LLVMGetModuleInlineAsm, LLVMSetModuleInlineAsm),
	exec_engine = LLVMCreateExecutionEngineForModule,
	link_module = LLVMLinkModules,
	bitcode = LLVMWriteBitcodeToString,
	source_filename = getset(LLVMGetSourceFileName, LLVMSetSourceFileName),
	target = getset(LLVMGetTarget, LLVMSetTarget),
	data_layout = getset(LLVMGetModuleDataLayout, LLVMSetModuleDataLayout),
	--debug info
	debug_metadata_version = LLVMGetModuleDebugMetadataVersion,
	strip = LLVMStripModuleDebugInfo,
	debug_info_builder = LLVMCreateDIBuilder,
}})

--ORC ------------------------------------------------------------------------

function LLVMOrcCreateInstance(machine)
	return ptrornil(C.LLVMOrcCreateInstance(machine))
end
orc = LLVMOrcCreateInstance

LLVMOrcGetErrorMsg = retstring(LLVMOrcGetErrorMsg)

local orc_modp = ffi.new'LLVMOrcModuleHandle[1]'

function LLVMOrcAddCompiledIR(J, M, resolve_sym, eagerly)
	local add = eagerly
		and LLVMOrcAddEagerlyCompiledIR
		 or LLVMOrcAddLazilyCompiledIR
	local resolve_sym_cb = resolve_sym and ffi.cb(resolve_sym)
	local err = add(J, orc_modp, M, resolve_sym_cb, nil)
	if err ~= nil then
		return nil, err:message()
	else
		return orc_modp[0]
	end
end

function LLVMOrcAddObjectFile(J, s)
	local membuf = membuffer(s)
	local resolve_sym_cb = resolve_sym and ffi.cb(resolve_sym)
	local err = C.LLVMOrcAddObjectFile(J, orc_modp, membuf, resolve_sym_cb, nil)
	if err ~= nil then
		return nil, err:message()
	else
		return orc_modp[0]
	end
end

local voidp_ct = ffi.typeof'void*'
function LLVMOrcGetSymbolAddress(J, OM, sym)
	local err
	if sym then
		 err = C.LLVMOrcGetSymbolAddressIn(J, addrp, OM, sym)
	else
		local sym = OM
		err = C.LLVMOrcGetSymbolAddress(J, addrp, sym)
	end
	if err ~= nil then
		return nil, err:message()
	else
		return ffi.cast(voidp_ct, addrp[0])
	end
end

ffi.metatype('struct LLVMOrcOpaqueJITStack', {__index = {
	free = LLVMOrcDisposeInstance,
	error_message = LLVMOrcGetErrorMsg,
	register_event_listener = LLVMOrcRegisterJITEventListener,
	unregister_event_listener = LLVMOrcUnregisterJITEventListener,
	lazy_compile_callback = LLVMOrcCreateLazyCompileCallback,
	indirect_stub = LLVMOrcCreateIndirectStub,
	set_indirect_stub = LLVMOrcSetIndirectStubPointer,
	add_module = LLVMOrcAddCompiledIR,
	add_obj = LLVMOrcAddObjectFile,
	remove_module = LLVMOrcRemoveModule,
	sym_addr = LLVMOrcGetSymbolAddress,
}})

return M
