require'ffi'.cdef[[
unsigned XXH_versionNumber(void);

typedef union {
	uint64_t u64[2];
	uint32_t u32[4];
	uint8_t u8[16];
} XXH128_hash_t;

uint32_t      XXH32 (const void* input, size_t length, uint32_t seed);
uint64_t      XXH64 (const void* input, size_t length, uint64_t seed);
XXH128_hash_t XXH128(const void* input, size_t length, uint64_t seed);

XXH128_hash_t XXH3_128bits_withSecret(const void* data, size_t len, const void* secret, size_t secretSize);

typedef enum { XXH_OK=0, XXH_ERROR } XXH_errorcode;

typedef struct XXH3_state_s XXH3_state_t;
XXH3_state_t* XXH3_createState(void);
XXH_errorcode XXH3_freeState(XXH3_state_t* statePtr);
void XXH3_copyState(XXH3_state_t* dst_state, const XXH3_state_t* src_state);

XXH_errorcode XXH3_128bits_reset(XXH3_state_t* statePtr);
XXH_errorcode XXH3_128bits_reset_withSeed(XXH3_state_t* statePtr, uint64_t seed);
XXH_errorcode XXH3_128bits_reset_withSecret(XXH3_state_t* statePtr, const void* secret, size_t secretSize);

XXH_errorcode XXH3_128bits_update (XXH3_state_t* statePtr, const void* input, size_t length);
XXH128_hash_t XXH3_128bits_digest (const XXH3_state_t* statePtr);
]]
