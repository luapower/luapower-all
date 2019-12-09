local ffi = require'ffi' --crypto.h, cryptoerr.h
require'libcrypto_types_h'
ffi.cdef[[
// crypto.h
typedef struct {
    int dummy;
} CRYPTO_dynlock;
typedef void CRYPTO_RWLOCK;
CRYPTO_RWLOCK *CRYPTO_THREAD_lock_new(void);
int CRYPTO_THREAD_read_lock(CRYPTO_RWLOCK *lock);
int CRYPTO_THREAD_write_lock(CRYPTO_RWLOCK *lock);
int CRYPTO_THREAD_unlock(CRYPTO_RWLOCK *lock);
void CRYPTO_THREAD_lock_free(CRYPTO_RWLOCK *lock);
int CRYPTO_atomic_add(int *val, int amount, int *ret, CRYPTO_RWLOCK *lock);
enum {
	CRYPTO_MEM_CHECK_OFF = 0x0,
	CRYPTO_MEM_CHECK_ON  = 0x1,
	CRYPTO_MEM_CHECK_ENABLE = 0x2,
	CRYPTO_MEM_CHECK_DISABLE = 0x3,
};
struct crypto_ex_data_st {
    struct stack_st_void *sk;
};
struct stack_st_void; typedef int (*sk_void_compfunc)(const void * const *a, const void *const *b); typedef void (*sk_void_freefunc)(void *a); typedef void * (*sk_void_copyfunc)(const void *a); static __attribute__((unused)) inline int sk_void_num(const struct stack_st_void *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void *sk_void_value(const struct stack_st_void *sk, int idx) { return (void *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_void *sk_void_new(sk_void_compfunc compare) { return (struct stack_st_void *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_void *sk_void_new_null(void) { return (struct stack_st_void *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_void *sk_void_new_reserve(sk_void_compfunc compare, int n) { return (struct stack_st_void *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_void_reserve(struct stack_st_void *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_void_free(struct stack_st_void *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_void_zero(struct stack_st_void *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void *sk_void_delete(struct stack_st_void *sk, int i) { return (void *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline void *sk_void_delete_ptr(struct stack_st_void *sk, void *ptr) { return (void *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_void_push(struct stack_st_void *sk, void *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_void_unshift(struct stack_st_void *sk, void *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void *sk_void_pop(struct stack_st_void *sk) { return (void *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void *sk_void_shift(struct stack_st_void *sk) { return (void *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_void_pop_free(struct stack_st_void *sk, sk_void_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_void_insert(struct stack_st_void *sk, void *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline void *sk_void_set(struct stack_st_void *sk, int idx, void *ptr) { return (void *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_void_find(struct stack_st_void *sk, void *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_void_find_ex(struct stack_st_void *sk, void *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_void_sort(struct stack_st_void *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_void_is_sorted(const struct stack_st_void *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_void * sk_void_dup(const struct stack_st_void *sk) { return (struct stack_st_void *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_void *sk_void_deep_copy(const struct stack_st_void *sk, sk_void_copyfunc copyfunc, sk_void_freefunc freefunc) { return (struct stack_st_void *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_void_compfunc sk_void_set_cmp_func(struct stack_st_void *sk, sk_void_compfunc compare) { return (sk_void_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum {
	CRYPTO_EX_INDEX_SSL  = 0,
	CRYPTO_EX_INDEX_SSL_CTX = 1,
	CRYPTO_EX_INDEX_SSL_SESSION = 2,
	CRYPTO_EX_INDEX_X509 = 3,
	CRYPTO_EX_INDEX_X509_STORE = 4,
	CRYPTO_EX_INDEX_X509_STORE_CTX = 5,
	CRYPTO_EX_INDEX_DH   = 6,
	CRYPTO_EX_INDEX_DSA  = 7,
	CRYPTO_EX_INDEX_EC_KEY = 8,
	CRYPTO_EX_INDEX_RSA  = 9,
	CRYPTO_EX_INDEX_ENGINE = 10,
	CRYPTO_EX_INDEX_UI   = 11,
	CRYPTO_EX_INDEX_BIO  = 12,
	CRYPTO_EX_INDEX_APP  = 13,
	CRYPTO_EX_INDEX_UI_METHOD = 14,
	CRYPTO_EX_INDEX_DRBG = 15,
	CRYPTO_EX_INDEX__COUNT = 16,
};
int CRYPTO_mem_ctrl(int mode);
size_t OPENSSL_strlcpy(char *dst, const char *src, size_t siz);
size_t OPENSSL_strlcat(char *dst, const char *src, size_t siz);
size_t OPENSSL_strnlen(const char *str, size_t maxlen);
char *OPENSSL_buf2hexstr(const unsigned char *buffer, long len);
unsigned char *OPENSSL_hexstr2buf(const char *str, long *len);
int OPENSSL_hexchar2int(unsigned char c);
unsigned long OpenSSL_version_num(void);
const char *OpenSSL_version(int type);
enum {
	OPENSSL_VERSION      = 0,
	OPENSSL_CFLAGS       = 1,
	OPENSSL_BUILT_ON     = 2,
	OPENSSL_PLATFORM     = 3,
	OPENSSL_DIR          = 4,
	OPENSSL_ENGINES_DIR  = 5,
};
int OPENSSL_issetugid(void);
typedef void CRYPTO_EX_new (void *parent, void *ptr, CRYPTO_EX_DATA *ad,
                           int idx, long argl, void *argp);
typedef void CRYPTO_EX_free (void *parent, void *ptr, CRYPTO_EX_DATA *ad,
                             int idx, long argl, void *argp);
typedef int CRYPTO_EX_dup (CRYPTO_EX_DATA *to, const CRYPTO_EX_DATA *from,
                           void *from_d, int idx, long argl, void *argp);
 int CRYPTO_get_ex_new_index(int class_index, long argl, void *argp,
                            CRYPTO_EX_new *new_func, CRYPTO_EX_dup *dup_func,
                            CRYPTO_EX_free *free_func);
int CRYPTO_free_ex_index(int class_index, int idx);
int CRYPTO_new_ex_data(int class_index, void *obj, CRYPTO_EX_DATA *ad);
int CRYPTO_dup_ex_data(int class_index, CRYPTO_EX_DATA *to,
                       const CRYPTO_EX_DATA *from);
void CRYPTO_free_ex_data(int class_index, void *obj, CRYPTO_EX_DATA *ad);
int CRYPTO_set_ex_data(CRYPTO_EX_DATA *ad, int idx, void *val);
void *CRYPTO_get_ex_data(const CRYPTO_EX_DATA *ad, int idx);
enum {
	CRYPTO_LOCK          = 1,
	CRYPTO_UNLOCK        = 2,
	CRYPTO_READ          = 4,
	CRYPTO_WRITE         = 8,
};
typedef struct crypto_threadid_st {
    int dummy;
} CRYPTO_THREADID;
int CRYPTO_set_mem_functions(
        void *(*m) (size_t, const char *, int),
        void *(*r) (void *, size_t, const char *, int),
        void (*f) (void *, const char *, int));
int CRYPTO_set_mem_debug(int flag);
void CRYPTO_get_mem_functions(
        void *(**m) (size_t, const char *, int),
        void *(**r) (void *, size_t, const char *, int),
        void (**f) (void *, const char *, int));
void *CRYPTO_malloc(size_t num, const char *file, int line);
void *CRYPTO_zalloc(size_t num, const char *file, int line);
void *CRYPTO_memdup(const void *str, size_t siz, const char *file, int line);
char *CRYPTO_strdup(const char *str, const char *file, int line);
char *CRYPTO_strndup(const char *str, size_t s, const char *file, int line);
void CRYPTO_free(void *ptr, const char *file, int line);
void CRYPTO_clear_free(void *ptr, size_t num, const char *file, int line);
void *CRYPTO_realloc(void *addr, size_t num, const char *file, int line);
void *CRYPTO_clear_realloc(void *addr, size_t old_num, size_t num,
                           const char *file, int line);
int CRYPTO_secure_malloc_init(size_t sz, int minsize);
int CRYPTO_secure_malloc_done(void);
void *CRYPTO_secure_malloc(size_t num, const char *file, int line);
void *CRYPTO_secure_zalloc(size_t num, const char *file, int line);
void CRYPTO_secure_free(void *ptr, const char *file, int line);
void CRYPTO_secure_clear_free(void *ptr, size_t num,
                              const char *file, int line);
int CRYPTO_secure_allocated(const void *ptr);
int CRYPTO_secure_malloc_initialized(void);
size_t CRYPTO_secure_actual_size(void *ptr);
size_t CRYPTO_secure_used(void);
void OPENSSL_cleanse(void *ptr, size_t len);
void OPENSSL_die(const char *assertion, const char *file, int line);
int OPENSSL_isservice(void);
int FIPS_mode(void);
int FIPS_mode_set(int r);
void OPENSSL_init(void);
struct tm *OPENSSL_gmtime(const time_t *timer, struct tm *result);
int OPENSSL_gmtime_adj(struct tm *tm, int offset_day, long offset_sec);
int OPENSSL_gmtime_diff(int *pday, int *psec,
                        const struct tm *from, const struct tm *to);
int CRYPTO_memcmp(const void * in_a, const void * in_b, size_t len);
enum {
	OPENSSL_INIT_NO_LOAD_CRYPTO_STRINGS = 0x00000001,
	OPENSSL_INIT_LOAD_CRYPTO_STRINGS    = 0x00000002,
	OPENSSL_INIT_ADD_ALL_CIPHERS        = 0x00000004,
	OPENSSL_INIT_ADD_ALL_DIGESTS        = 0x00000008,
	OPENSSL_INIT_NO_ADD_ALL_CIPHERS     = 0x00000010,
	OPENSSL_INIT_NO_ADD_ALL_DIGESTS     = 0x00000020,
	OPENSSL_INIT_LOAD_CONFIG            = 0x00000040,
	OPENSSL_INIT_NO_LOAD_CONFIG         = 0x00000080,
	OPENSSL_INIT_ASYNC                  = 0x00000100,
	OPENSSL_INIT_ENGINE_RDRAND          = 0x00000200,
	OPENSSL_INIT_ENGINE_DYNAMIC         = 0x00000400,
	OPENSSL_INIT_ENGINE_OPENSSL         = 0x00000800,
	OPENSSL_INIT_ENGINE_CRYPTODEV       = 0x00001000,
	OPENSSL_INIT_ENGINE_CAPI            = 0x00002000,
	OPENSSL_INIT_ENGINE_PADLOCK         = 0x00004000,
	OPENSSL_INIT_ENGINE_AFALG           = 0x00008000,
	OPENSSL_INIT_ATFORK                 = 0x00020000,
	OPENSSL_INIT_NO_ATEXIT              = 0x00080000,
	OPENSSL_INIT_ENGINE_ALL_BUILTIN = (OPENSSL_INIT_ENGINE_RDRAND | OPENSSL_INIT_ENGINE_DYNAMIC | OPENSSL_INIT_ENGINE_CRYPTODEV | OPENSSL_INIT_ENGINE_CAPI | OPENSSL_INIT_ENGINE_PADLOCK),
};
void OPENSSL_cleanup(void);
int OPENSSL_init_crypto(uint64_t opts, const OPENSSL_INIT_SETTINGS *settings);
int OPENSSL_atexit(void (*handler)(void));
void OPENSSL_thread_stop(void);
OPENSSL_INIT_SETTINGS *OPENSSL_INIT_new(void);
int OPENSSL_INIT_set_config_filename(OPENSSL_INIT_SETTINGS *settings,
                                     const char *config_filename);
void OPENSSL_INIT_set_config_file_flags(OPENSSL_INIT_SETTINGS *settings,
                                        unsigned long flags);
int OPENSSL_INIT_set_config_appname(OPENSSL_INIT_SETTINGS *settings,
                                    const char *config_appname);
void OPENSSL_INIT_free(OPENSSL_INIT_SETTINGS *settings);
typedef unsigned int CRYPTO_ONCE;
typedef unsigned int CRYPTO_THREAD_LOCAL;
typedef unsigned int CRYPTO_THREAD_ID;
enum {
	CRYPTO_ONCE_STATIC_INIT = 0,
};
int CRYPTO_THREAD_run_once(CRYPTO_ONCE *once, void (*init)(void));
int CRYPTO_THREAD_init_local(CRYPTO_THREAD_LOCAL *key, void (*cleanup)(void *));
void *CRYPTO_THREAD_get_local(CRYPTO_THREAD_LOCAL *key);
int CRYPTO_THREAD_set_local(CRYPTO_THREAD_LOCAL *key, void *val);
int CRYPTO_THREAD_cleanup_local(CRYPTO_THREAD_LOCAL *key);
CRYPTO_THREAD_ID CRYPTO_THREAD_get_current_id(void);
int CRYPTO_THREAD_compare_id(CRYPTO_THREAD_ID a, CRYPTO_THREAD_ID b);

// cryptoerr.h
int ERR_load_CRYPTO_strings(void);
enum {
	CRYPTO_F_CMAC_CTX_NEW = 120,
	CRYPTO_F_CRYPTO_DUP_EX_DATA = 110,
	CRYPTO_F_CRYPTO_FREE_EX_DATA = 111,
	CRYPTO_F_CRYPTO_GET_EX_NEW_INDEX = 100,
	CRYPTO_F_CRYPTO_MEMDUP = 115,
	CRYPTO_F_CRYPTO_NEW_EX_DATA = 112,
	CRYPTO_F_CRYPTO_OCB128_COPY_CTX = 121,
	CRYPTO_F_CRYPTO_OCB128_INIT = 122,
	CRYPTO_F_CRYPTO_SET_EX_DATA = 102,
	CRYPTO_F_FIPS_MODE_SET = 109,
	CRYPTO_F_GET_AND_LOCK = 113,
	CRYPTO_F_OPENSSL_ATEXIT = 114,
	CRYPTO_F_OPENSSL_BUF2HEXSTR = 117,
	CRYPTO_F_OPENSSL_FOPEN = 119,
	CRYPTO_F_OPENSSL_HEXSTR2BUF = 118,
	CRYPTO_F_OPENSSL_INIT_CRYPTO = 116,
	CRYPTO_F_OPENSSL_LH_NEW = 126,
	CRYPTO_F_OPENSSL_SK_DEEP_COPY = 127,
	CRYPTO_F_OPENSSL_SK_DUP = 128,
	CRYPTO_F_PKEY_HMAC_INIT = 123,
	CRYPTO_F_PKEY_POLY1305_INIT = 124,
	CRYPTO_F_PKEY_SIPHASH_INIT = 125,
	CRYPTO_F_SK_RESERVE  = 129,
	CRYPTO_R_FIPS_MODE_NOT_SUPPORTED = 101,
	CRYPTO_R_ILLEGAL_HEX_DIGIT = 102,
	CRYPTO_R_ODD_NUMBER_OF_DIGITS = 103,
};
]]
