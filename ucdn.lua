local ffi = require'ffi'
local C = ffi.load'ucdn'

ffi.cdef[[
const char *ucdn_get_unicode_version(void);
int ucdn_get_combining_class(uint32_t code);
int ucdn_get_east_asian_width(uint32_t code);
int ucdn_get_general_category(uint32_t code);
int ucdn_get_bidi_class(uint32_t code);
int ucdn_get_script(uint32_t code);
int ucdn_get_mirrored(uint32_t code);
uint32_t ucdn_mirror(uint32_t code);
int ucdn_decompose(uint32_t code, uint32_t *a, uint32_t *b);
int ucdn_compat_decompose(uint32_t code, uint32_t *decomposed);
int ucdn_compose(uint32_t *code, uint32_t a, uint32_t b);
]]

local M = setmetatable({C = C}, {__index = C})

function M.ucdn_get_unicode_version()
	return ffi.string(C.ucdn_get_unicode_version())
end

if not ... then

local ucdn = M

print('unicode version', ucdn.ucdn_get_unicode_version())

end

return C
