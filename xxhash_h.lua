require'ffi'.cdef[[
unsigned XXH_versionNumber(void);
uint32_t XXH32 (const void* input, size_t length, uint32_t seed);
uint64_t XXH64 (const void* input, size_t length, uint64_t seed);
]]
