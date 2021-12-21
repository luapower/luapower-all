local ffi = require'ffi'
ffi.cdef[[
typedef struct {
 const void *data;
 size_t len;
} br_tls_prf_seed_chunk;
void br_tls10_prf(void *dst, size_t len,
 const void *secret, size_t secret_len, const char *label,
 size_t seed_num, const br_tls_prf_seed_chunk *seed);
void br_tls12_sha256_prf(void *dst, size_t len,
 const void *secret, size_t secret_len, const char *label,
 size_t seed_num, const br_tls_prf_seed_chunk *seed);
void br_tls12_sha384_prf(void *dst, size_t len,
 const void *secret, size_t secret_len, const char *label,
 size_t seed_num, const br_tls_prf_seed_chunk *seed);
typedef void (*br_tls_prf_impl)(void *dst, size_t len,
 const void *secret, size_t secret_len, const char *label,
 size_t seed_num, const br_tls_prf_seed_chunk *seed);
]]
