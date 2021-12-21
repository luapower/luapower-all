local ffi = require'ffi'
ffi.cdef[[
typedef struct br_block_cbcenc_class_ br_block_cbcenc_class;
struct br_block_cbcenc_class_ {
 size_t context_size;
 unsigned block_size;
 unsigned log_block_size;
 void (*init)(const br_block_cbcenc_class **ctx,
  const void *key, size_t key_len);
 void (*run)(const br_block_cbcenc_class *const *ctx,
  void *iv, void *data, size_t len);
};
typedef struct br_block_cbcdec_class_ br_block_cbcdec_class;
struct br_block_cbcdec_class_ {
 size_t context_size;
 unsigned block_size;
 unsigned log_block_size;
 void (*init)(const br_block_cbcdec_class **ctx,
  const void *key, size_t key_len);
 void (*run)(const br_block_cbcdec_class *const *ctx,
  void *iv, void *data, size_t len);
};
typedef struct br_block_ctr_class_ br_block_ctr_class;
struct br_block_ctr_class_ {
 size_t context_size;
 unsigned block_size;
 unsigned log_block_size;
 void (*init)(const br_block_ctr_class **ctx,
  const void *key, size_t key_len);
 uint32_t (*run)(const br_block_ctr_class *const *ctx,
  const void *iv, uint32_t cc, void *data, size_t len);
};
typedef struct br_block_ctrcbc_class_ br_block_ctrcbc_class;
struct br_block_ctrcbc_class_ {
 size_t context_size;
 unsigned block_size;
 unsigned log_block_size;
 void (*init)(const br_block_ctrcbc_class **ctx,
  const void *key, size_t key_len);
 void (*encrypt)(const br_block_ctrcbc_class *const *ctx,
  void *ctr, void *cbcmac, void *data, size_t len);
 void (*decrypt)(const br_block_ctrcbc_class *const *ctx,
  void *ctr, void *cbcmac, void *data, size_t len);
 void (*ctr)(const br_block_ctrcbc_class *const *ctx,
  void *ctr, void *data, size_t len);
 void (*mac)(const br_block_ctrcbc_class *const *ctx,
  void *cbcmac, const void *data, size_t len);
};
enum {
	br_aes_big_BLOCK_SIZE = 16,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_big_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_big_cbcdec_keys;
typedef struct {
 const br_block_ctr_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_big_ctr_keys;
typedef struct {
 const br_block_ctrcbc_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_big_ctrcbc_keys;
extern const br_block_cbcenc_class br_aes_big_cbcenc_vtable;
extern const br_block_cbcdec_class br_aes_big_cbcdec_vtable;
extern const br_block_ctr_class br_aes_big_ctr_vtable;
extern const br_block_ctrcbc_class br_aes_big_ctrcbc_vtable;
void br_aes_big_cbcenc_init(br_aes_big_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_aes_big_cbcdec_init(br_aes_big_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_aes_big_ctr_init(br_aes_big_ctr_keys *ctx,
 const void *key, size_t len);
void br_aes_big_ctrcbc_init(br_aes_big_ctrcbc_keys *ctx,
 const void *key, size_t len);
void br_aes_big_cbcenc_run(const br_aes_big_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_aes_big_cbcdec_run(const br_aes_big_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
uint32_t br_aes_big_ctr_run(const br_aes_big_ctr_keys *ctx,
 const void *iv, uint32_t cc, void *data, size_t len);
void br_aes_big_ctrcbc_encrypt(const br_aes_big_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_big_ctrcbc_decrypt(const br_aes_big_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_big_ctrcbc_ctr(const br_aes_big_ctrcbc_keys *ctx,
 void *ctr, void *data, size_t len);
void br_aes_big_ctrcbc_mac(const br_aes_big_ctrcbc_keys *ctx,
 void *cbcmac, const void *data, size_t len);
enum {
	br_aes_small_BLOCK_SIZE = 16,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_small_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_small_cbcdec_keys;
typedef struct {
 const br_block_ctr_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_small_ctr_keys;
typedef struct {
 const br_block_ctrcbc_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_small_ctrcbc_keys;
extern const br_block_cbcenc_class br_aes_small_cbcenc_vtable;
extern const br_block_cbcdec_class br_aes_small_cbcdec_vtable;
extern const br_block_ctr_class br_aes_small_ctr_vtable;
extern const br_block_ctrcbc_class br_aes_small_ctrcbc_vtable;
void br_aes_small_cbcenc_init(br_aes_small_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_aes_small_cbcdec_init(br_aes_small_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_aes_small_ctr_init(br_aes_small_ctr_keys *ctx,
 const void *key, size_t len);
void br_aes_small_ctrcbc_init(br_aes_small_ctrcbc_keys *ctx,
 const void *key, size_t len);
void br_aes_small_cbcenc_run(const br_aes_small_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_aes_small_cbcdec_run(const br_aes_small_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
uint32_t br_aes_small_ctr_run(const br_aes_small_ctr_keys *ctx,
 const void *iv, uint32_t cc, void *data, size_t len);
void br_aes_small_ctrcbc_encrypt(const br_aes_small_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_small_ctrcbc_decrypt(const br_aes_small_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_small_ctrcbc_ctr(const br_aes_small_ctrcbc_keys *ctx,
 void *ctr, void *data, size_t len);
void br_aes_small_ctrcbc_mac(const br_aes_small_ctrcbc_keys *ctx,
 void *cbcmac, const void *data, size_t len);
enum {
	br_aes_ct_BLOCK_SIZE = 16,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_ct_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_ct_cbcdec_keys;
typedef struct {
 const br_block_ctr_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_ct_ctr_keys;
typedef struct {
 const br_block_ctrcbc_class *vtable;
 uint32_t skey[60];
 unsigned num_rounds;
} br_aes_ct_ctrcbc_keys;
extern const br_block_cbcenc_class br_aes_ct_cbcenc_vtable;
extern const br_block_cbcdec_class br_aes_ct_cbcdec_vtable;
extern const br_block_ctr_class br_aes_ct_ctr_vtable;
extern const br_block_ctrcbc_class br_aes_ct_ctrcbc_vtable;
void br_aes_ct_cbcenc_init(br_aes_ct_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_aes_ct_cbcdec_init(br_aes_ct_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_aes_ct_ctr_init(br_aes_ct_ctr_keys *ctx,
 const void *key, size_t len);
void br_aes_ct_ctrcbc_init(br_aes_ct_ctrcbc_keys *ctx,
 const void *key, size_t len);
void br_aes_ct_cbcenc_run(const br_aes_ct_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_aes_ct_cbcdec_run(const br_aes_ct_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
uint32_t br_aes_ct_ctr_run(const br_aes_ct_ctr_keys *ctx,
 const void *iv, uint32_t cc, void *data, size_t len);
void br_aes_ct_ctrcbc_encrypt(const br_aes_ct_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_ct_ctrcbc_decrypt(const br_aes_ct_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_ct_ctrcbc_ctr(const br_aes_ct_ctrcbc_keys *ctx,
 void *ctr, void *data, size_t len);
void br_aes_ct_ctrcbc_mac(const br_aes_ct_ctrcbc_keys *ctx,
 void *cbcmac, const void *data, size_t len);
enum {
	br_aes_ct64_BLOCK_SIZE = 16,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 uint64_t skey[30];
 unsigned num_rounds;
} br_aes_ct64_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 uint64_t skey[30];
 unsigned num_rounds;
} br_aes_ct64_cbcdec_keys;
typedef struct {
 const br_block_ctr_class *vtable;
 uint64_t skey[30];
 unsigned num_rounds;
} br_aes_ct64_ctr_keys;
typedef struct {
 const br_block_ctrcbc_class *vtable;
 uint64_t skey[30];
 unsigned num_rounds;
} br_aes_ct64_ctrcbc_keys;
extern const br_block_cbcenc_class br_aes_ct64_cbcenc_vtable;
extern const br_block_cbcdec_class br_aes_ct64_cbcdec_vtable;
extern const br_block_ctr_class br_aes_ct64_ctr_vtable;
extern const br_block_ctrcbc_class br_aes_ct64_ctrcbc_vtable;
void br_aes_ct64_cbcenc_init(br_aes_ct64_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_aes_ct64_cbcdec_init(br_aes_ct64_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_aes_ct64_ctr_init(br_aes_ct64_ctr_keys *ctx,
 const void *key, size_t len);
void br_aes_ct64_ctrcbc_init(br_aes_ct64_ctrcbc_keys *ctx,
 const void *key, size_t len);
void br_aes_ct64_cbcenc_run(const br_aes_ct64_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_aes_ct64_cbcdec_run(const br_aes_ct64_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
uint32_t br_aes_ct64_ctr_run(const br_aes_ct64_ctr_keys *ctx,
 const void *iv, uint32_t cc, void *data, size_t len);
void br_aes_ct64_ctrcbc_encrypt(const br_aes_ct64_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_ct64_ctrcbc_decrypt(const br_aes_ct64_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_ct64_ctrcbc_ctr(const br_aes_ct64_ctrcbc_keys *ctx,
 void *ctr, void *data, size_t len);
void br_aes_ct64_ctrcbc_mac(const br_aes_ct64_ctrcbc_keys *ctx,
 void *cbcmac, const void *data, size_t len);
enum {
	br_aes_x86ni_BLOCK_SIZE = 16,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_x86ni_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_x86ni_cbcdec_keys;
typedef struct {
 const br_block_ctr_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_x86ni_ctr_keys;
typedef struct {
 const br_block_ctrcbc_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_x86ni_ctrcbc_keys;
extern const br_block_cbcenc_class br_aes_x86ni_cbcenc_vtable;
extern const br_block_cbcdec_class br_aes_x86ni_cbcdec_vtable;
extern const br_block_ctr_class br_aes_x86ni_ctr_vtable;
extern const br_block_ctrcbc_class br_aes_x86ni_ctrcbc_vtable;
void br_aes_x86ni_cbcenc_init(br_aes_x86ni_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_aes_x86ni_cbcdec_init(br_aes_x86ni_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_aes_x86ni_ctr_init(br_aes_x86ni_ctr_keys *ctx,
 const void *key, size_t len);
void br_aes_x86ni_ctrcbc_init(br_aes_x86ni_ctrcbc_keys *ctx,
 const void *key, size_t len);
void br_aes_x86ni_cbcenc_run(const br_aes_x86ni_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_aes_x86ni_cbcdec_run(const br_aes_x86ni_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
uint32_t br_aes_x86ni_ctr_run(const br_aes_x86ni_ctr_keys *ctx,
 const void *iv, uint32_t cc, void *data, size_t len);
void br_aes_x86ni_ctrcbc_encrypt(const br_aes_x86ni_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_x86ni_ctrcbc_decrypt(const br_aes_x86ni_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_x86ni_ctrcbc_ctr(const br_aes_x86ni_ctrcbc_keys *ctx,
 void *ctr, void *data, size_t len);
void br_aes_x86ni_ctrcbc_mac(const br_aes_x86ni_ctrcbc_keys *ctx,
 void *cbcmac, const void *data, size_t len);
const br_block_cbcenc_class *br_aes_x86ni_cbcenc_get_vtable(void);
const br_block_cbcdec_class *br_aes_x86ni_cbcdec_get_vtable(void);
const br_block_ctr_class *br_aes_x86ni_ctr_get_vtable(void);
const br_block_ctrcbc_class *br_aes_x86ni_ctrcbc_get_vtable(void);
enum {
	br_aes_pwr8_BLOCK_SIZE = 16,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_pwr8_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_pwr8_cbcdec_keys;
typedef struct {
 const br_block_ctr_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_pwr8_ctr_keys;
typedef struct {
 const br_block_ctrcbc_class *vtable;
 union {
  unsigned char skni[16 * 15];
 } skey;
 unsigned num_rounds;
} br_aes_pwr8_ctrcbc_keys;
extern const br_block_cbcenc_class br_aes_pwr8_cbcenc_vtable;
extern const br_block_cbcdec_class br_aes_pwr8_cbcdec_vtable;
extern const br_block_ctr_class br_aes_pwr8_ctr_vtable;
extern const br_block_ctrcbc_class br_aes_pwr8_ctrcbc_vtable;
void br_aes_pwr8_cbcenc_init(br_aes_pwr8_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_aes_pwr8_cbcdec_init(br_aes_pwr8_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_aes_pwr8_ctr_init(br_aes_pwr8_ctr_keys *ctx,
 const void *key, size_t len);
void br_aes_pwr8_ctrcbc_init(br_aes_pwr8_ctrcbc_keys *ctx,
 const void *key, size_t len);
void br_aes_pwr8_cbcenc_run(const br_aes_pwr8_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_aes_pwr8_cbcdec_run(const br_aes_pwr8_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
uint32_t br_aes_pwr8_ctr_run(const br_aes_pwr8_ctr_keys *ctx,
 const void *iv, uint32_t cc, void *data, size_t len);
void br_aes_pwr8_ctrcbc_encrypt(const br_aes_pwr8_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_pwr8_ctrcbc_decrypt(const br_aes_pwr8_ctrcbc_keys *ctx,
 void *ctr, void *cbcmac, void *data, size_t len);
void br_aes_pwr8_ctrcbc_ctr(const br_aes_pwr8_ctrcbc_keys *ctx,
 void *ctr, void *data, size_t len);
void br_aes_pwr8_ctrcbc_mac(const br_aes_pwr8_ctrcbc_keys *ctx,
 void *cbcmac, const void *data, size_t len);
const br_block_cbcenc_class *br_aes_pwr8_cbcenc_get_vtable(void);
const br_block_cbcdec_class *br_aes_pwr8_cbcdec_get_vtable(void);
const br_block_ctr_class *br_aes_pwr8_ctr_get_vtable(void);
const br_block_ctrcbc_class *br_aes_pwr8_ctrcbc_get_vtable(void);
typedef union {
 const br_block_cbcenc_class *vtable;
 br_aes_big_cbcenc_keys c_big;
 br_aes_small_cbcenc_keys c_small;
 br_aes_ct_cbcenc_keys c_ct;
 br_aes_ct64_cbcenc_keys c_ct64;
 br_aes_x86ni_cbcenc_keys c_x86ni;
 br_aes_pwr8_cbcenc_keys c_pwr8;
} br_aes_gen_cbcenc_keys;
typedef union {
 const br_block_cbcdec_class *vtable;
 br_aes_big_cbcdec_keys c_big;
 br_aes_small_cbcdec_keys c_small;
 br_aes_ct_cbcdec_keys c_ct;
 br_aes_ct64_cbcdec_keys c_ct64;
 br_aes_x86ni_cbcdec_keys c_x86ni;
 br_aes_pwr8_cbcdec_keys c_pwr8;
} br_aes_gen_cbcdec_keys;
typedef union {
 const br_block_ctr_class *vtable;
 br_aes_big_ctr_keys c_big;
 br_aes_small_ctr_keys c_small;
 br_aes_ct_ctr_keys c_ct;
 br_aes_ct64_ctr_keys c_ct64;
 br_aes_x86ni_ctr_keys c_x86ni;
 br_aes_pwr8_ctr_keys c_pwr8;
} br_aes_gen_ctr_keys;
typedef union {
 const br_block_ctrcbc_class *vtable;
 br_aes_big_ctrcbc_keys c_big;
 br_aes_small_ctrcbc_keys c_small;
 br_aes_ct_ctrcbc_keys c_ct;
 br_aes_ct64_ctrcbc_keys c_ct64;
 br_aes_x86ni_ctrcbc_keys c_x86ni;
 br_aes_pwr8_ctrcbc_keys c_pwr8;
} br_aes_gen_ctrcbc_keys;
enum {
	br_des_tab_BLOCK_SIZE = 8,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 uint32_t skey[96];
 unsigned num_rounds;
} br_des_tab_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 uint32_t skey[96];
 unsigned num_rounds;
} br_des_tab_cbcdec_keys;
extern const br_block_cbcenc_class br_des_tab_cbcenc_vtable;
extern const br_block_cbcdec_class br_des_tab_cbcdec_vtable;
void br_des_tab_cbcenc_init(br_des_tab_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_des_tab_cbcdec_init(br_des_tab_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_des_tab_cbcenc_run(const br_des_tab_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_des_tab_cbcdec_run(const br_des_tab_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
enum {
	br_des_ct_BLOCK_SIZE = 8,
};
typedef struct {
 const br_block_cbcenc_class *vtable;
 uint32_t skey[96];
 unsigned num_rounds;
} br_des_ct_cbcenc_keys;
typedef struct {
 const br_block_cbcdec_class *vtable;
 uint32_t skey[96];
 unsigned num_rounds;
} br_des_ct_cbcdec_keys;
extern const br_block_cbcenc_class br_des_ct_cbcenc_vtable;
extern const br_block_cbcdec_class br_des_ct_cbcdec_vtable;
void br_des_ct_cbcenc_init(br_des_ct_cbcenc_keys *ctx,
 const void *key, size_t len);
void br_des_ct_cbcdec_init(br_des_ct_cbcdec_keys *ctx,
 const void *key, size_t len);
void br_des_ct_cbcenc_run(const br_des_ct_cbcenc_keys *ctx, void *iv,
 void *data, size_t len);
void br_des_ct_cbcdec_run(const br_des_ct_cbcdec_keys *ctx, void *iv,
 void *data, size_t len);
typedef union {
 const br_block_cbcenc_class *vtable;
 br_des_tab_cbcenc_keys tab;
 br_des_ct_cbcenc_keys ct;
} br_des_gen_cbcenc_keys;
typedef union {
 const br_block_cbcdec_class *vtable;
 br_des_tab_cbcdec_keys c_tab;
 br_des_ct_cbcdec_keys c_ct;
} br_des_gen_cbcdec_keys;
typedef uint32_t (*br_chacha20_run)(const void *key,
 const void *iv, uint32_t cc, void *data, size_t len);
uint32_t br_chacha20_ct_run(const void *key,
 const void *iv, uint32_t cc, void *data, size_t len);
uint32_t br_chacha20_sse2_run(const void *key,
 const void *iv, uint32_t cc, void *data, size_t len);
br_chacha20_run br_chacha20_sse2_get(void);
typedef void (*br_poly1305_run)(const void *key, const void *iv,
 void *data, size_t len, const void *aad, size_t aad_len,
 void *tag, br_chacha20_run ichacha, int encrypt);
void br_poly1305_ctmul_run(const void *key, const void *iv,
 void *data, size_t len, const void *aad, size_t aad_len,
 void *tag, br_chacha20_run ichacha, int encrypt);
void br_poly1305_ctmul32_run(const void *key, const void *iv,
 void *data, size_t len, const void *aad, size_t aad_len,
 void *tag, br_chacha20_run ichacha, int encrypt);
void br_poly1305_i15_run(const void *key, const void *iv,
 void *data, size_t len, const void *aad, size_t aad_len,
 void *tag, br_chacha20_run ichacha, int encrypt);
void br_poly1305_ctmulq_run(const void *key, const void *iv,
 void *data, size_t len, const void *aad, size_t aad_len,
 void *tag, br_chacha20_run ichacha, int encrypt);
br_poly1305_run br_poly1305_ctmulq_get(void);
]]
