
--string handling routines extracted from LuaJIT.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local C = ffi.load'ljstr'
local ljs = {C = C}

--lj_strscan_scan() from lj_strscan.c.

ffi.cdef[[
typedef enum {
  STRSCAN_ERROR,
  STRSCAN_NUM, STRSCAN_IMAG,
  STRSCAN_INT, STRSCAN_U32, STRSCAN_I64, STRSCAN_U64,
} StrScanFmt;

/* Tagged value. */
typedef __attribute__((aligned(8))) union TValue {
	uint64_t u64;   /* 64 bit pattern overlaps number. */
	int64_t  i64;   /* 64 bit pattern overlaps number. */
	double   n;     /* Number object overlaps split tag/value object. */
	int32_t  i;     /* Integer value. */
	uint32_t u;
	complex  c;
	struct {
		double d1;   /* Real part of comlex number */
		double d2;   /* Imaginary part of complex number */
	};
} TValue;

StrScanFmt lj_strscan_scan(const uint8_t *p, TValue *o, uint32_t opt);
]]

ljs.STRSCAN_OPT_TOINT = 0x01  --Convert to int32_t, if possible.
ljs.STRSCAN_OPT_TONUM = 0x02  --Always convert to double.
ljs.STRSCAN_OPT_IMAG  = 0x04  --Parse imaginary part of complex numbers.
ljs.STRSCAN_OPT_LL    = 0x08  --Parse LL and ULL-suffixed 64bit ints.
ljs.STRSCAN_OPT_C     = 0x10  --Parse 32bit ints for the ffi C parser.

local o = ffi.new'TValue'
local dopt = ljs.STRSCAN_OPT_TONUM + ljs.STRSCAN_OPT_LL + ljs.STRSCAN_OPT_IMAG

function ljs.strscan(p, opt)
	local ret = C.lj_strscan_scan(p, o, opt or dopt)
	if ret == C.STRSCAN_ERROR then
		return nil
	elseif ret == C.STRSCAN_NUM then
		return o.n, 'double'
	elseif ret == C.STRSCAN_IMAG then
		o.d2 = o.d1
		o.d1 = 0
		return o.c, 'complex'
	elseif ret == C.STRSCAN_INT then
		return o.i, 'int32_t'
	elseif ret == C.STRSCAN_U32 then
		return o.u, 'uint32_t'
	elseif ret == C.STRSCAN_I64 then
		return o.i64, 'int64_t'
	elseif ret == C.STRSCAN_U64 then
		return o.u64, 'uint64_t'
	end
end

--lj_char_is*() macros from lj_char.h turned into functions.

ffi.cdef[[
int lj_str_iscntrl(int32_t c);
int lj_str_isspace(int32_t c);
int lj_str_ispunct(int32_t c);
int lj_str_isdigit(int32_t c);
int lj_str_isxdigit(int32_t c);
int lj_str_isupper(int32_t c);
int lj_str_islower(int32_t c);
int lj_str_isident(int32_t c);
int lj_str_isalpha(int32_t c);
int lj_str_isalnum(int32_t c);
int lj_str_isgraph(int32_t c);
int lj_str_toupper(int32_t c);
int lj_str_tolower(int32_t c);
]]

ljs.iscntrl = function(c) return C.lj_str_iscntrl(c) ~= 0 end
ljs.isspace = function(c) return C.lj_str_isspace(c) ~= 0 end
ljs.ispunc = function(c) return C.lj_str_ispunct(c) ~= 0 end
ljs.isdigit = function(c) return C.lj_str_isdigit(c) ~= 0 end
ljs.isxdigit = function(c) return C.lj_str_isxdigit(c) ~= 0 end
ljs.isupper = function(c) return C.lj_str_isupper(c) ~= 0 end
ljs.islower = function(c) return C.lj_str_islower(c) ~= 0 end
ljs.isident = function(c) return C.lj_str_isident(c) ~= 0 end
ljs.isalpha = function(c) return C.lj_str_isalpha(c) ~= 0 end
ljs.isalnum = function(c) return C.lj_str_isalnum(c) ~= 0 end
ljs.isgraph = function(c) return C.lj_str_isgraph(c) ~= 0 end
ljs.toupper = C.lj_str_toupper
ljs.tolower = C.lj_str_tolower


if not ... then

print(ljs.strscan('123', ljs.STRSCAN_OPT_TOINT))
print(ljs.strscan('123.3', ljs.STRSCAN_OPT_TOINT))
print(ljs.strscan('123'))
print(ljs.strscan('12.3e-1'))
print(ljs.strscan('12.5i'))
assert(ljs.strscan('xxx') == nil)
assert(ljs.strscan('-1LL', 8) == -1LL)
assert(ljs.strscan('0xFFFFFFFFFFFFFFFFULL', 8) == 0xFFFFFFFFFFFFFFFFULL)

end

return ljs
