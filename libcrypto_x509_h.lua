local ffi = require'ffi'
--[[
// csrc/openssl/src/include/openssl/x509.h
enum {
	X509_SIG_INFO_VALID  = 0x1,
	X509_SIG_INFO_TLS    = 0x2,
	X509_FILETYPE_PEM    = 1,
	X509_FILETYPE_ASN1   = 2,
	X509_FILETYPE_DEFAULT = 3,
	X509v3_KU_DIGITAL_SIGNATURE = 0x0080,
	X509v3_KU_NON_REPUDIATION = 0x0040,
	X509v3_KU_KEY_ENCIPHERMENT = 0x0020,
	X509v3_KU_DATA_ENCIPHERMENT = 0x0010,
	X509v3_KU_KEY_AGREEMENT = 0x0008,
	X509v3_KU_KEY_CERT_SIGN = 0x0004,
	X509v3_KU_CRL_SIGN   = 0x0002,
	X509v3_KU_ENCIPHER_ONLY = 0x0001,
	X509v3_KU_DECIPHER_ONLY = 0x8000,
	X509v3_KU_UNDEF      = 0xffff,
};
struct X509_algor_st {
    ASN1_OBJECT *algorithm;
    ASN1_TYPE *parameter;
} ;
typedef struct stack_st_X509_ALGOR X509_ALGORS;
typedef struct X509_val_st {
    ASN1_TIME *notBefore;
    ASN1_TIME *notAfter;
} X509_VAL;
typedef struct X509_sig_st X509_SIG;
typedef struct X509_name_entry_st X509_NAME_ENTRY;
struct stack_st_X509_NAME_ENTRY; typedef int (*sk_X509_NAME_ENTRY_compfunc)(const X509_NAME_ENTRY * const *a, const X509_NAME_ENTRY *const *b); typedef void (*sk_X509_NAME_ENTRY_freefunc)(X509_NAME_ENTRY *a); typedef X509_NAME_ENTRY * (*sk_X509_NAME_ENTRY_copyfunc)(const X509_NAME_ENTRY *a); static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_num(const struct stack_st_X509_NAME_ENTRY *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_NAME_ENTRY *sk_X509_NAME_ENTRY_value(const struct stack_st_X509_NAME_ENTRY *sk, int idx) { return (X509_NAME_ENTRY *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_NAME_ENTRY *sk_X509_NAME_ENTRY_new(sk_X509_NAME_ENTRY_compfunc compare) { return (struct stack_st_X509_NAME_ENTRY *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_NAME_ENTRY *sk_X509_NAME_ENTRY_new_null(void) { return (struct stack_st_X509_NAME_ENTRY *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_NAME_ENTRY *sk_X509_NAME_ENTRY_new_reserve(sk_X509_NAME_ENTRY_compfunc compare, int n) { return (struct stack_st_X509_NAME_ENTRY *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_reserve(struct stack_st_X509_NAME_ENTRY *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_NAME_ENTRY_free(struct stack_st_X509_NAME_ENTRY *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_NAME_ENTRY_zero(struct stack_st_X509_NAME_ENTRY *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_NAME_ENTRY *sk_X509_NAME_ENTRY_delete(struct stack_st_X509_NAME_ENTRY *sk, int i) { return (X509_NAME_ENTRY *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_NAME_ENTRY *sk_X509_NAME_ENTRY_delete_ptr(struct stack_st_X509_NAME_ENTRY *sk, X509_NAME_ENTRY *ptr) { return (X509_NAME_ENTRY *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_push(struct stack_st_X509_NAME_ENTRY *sk, X509_NAME_ENTRY *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_unshift(struct stack_st_X509_NAME_ENTRY *sk, X509_NAME_ENTRY *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_NAME_ENTRY *sk_X509_NAME_ENTRY_pop(struct stack_st_X509_NAME_ENTRY *sk) { return (X509_NAME_ENTRY *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_NAME_ENTRY *sk_X509_NAME_ENTRY_shift(struct stack_st_X509_NAME_ENTRY *sk) { return (X509_NAME_ENTRY *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_NAME_ENTRY_pop_free(struct stack_st_X509_NAME_ENTRY *sk, sk_X509_NAME_ENTRY_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_insert(struct stack_st_X509_NAME_ENTRY *sk, X509_NAME_ENTRY *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_NAME_ENTRY *sk_X509_NAME_ENTRY_set(struct stack_st_X509_NAME_ENTRY *sk, int idx, X509_NAME_ENTRY *ptr) { return (X509_NAME_ENTRY *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_find(struct stack_st_X509_NAME_ENTRY *sk, X509_NAME_ENTRY *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_find_ex(struct stack_st_X509_NAME_ENTRY *sk, X509_NAME_ENTRY *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_NAME_ENTRY_sort(struct stack_st_X509_NAME_ENTRY *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_NAME_ENTRY_is_sorted(const struct stack_st_X509_NAME_ENTRY *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_NAME_ENTRY * sk_X509_NAME_ENTRY_dup(const struct stack_st_X509_NAME_ENTRY *sk) { return (struct stack_st_X509_NAME_ENTRY *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_NAME_ENTRY *sk_X509_NAME_ENTRY_deep_copy(const struct stack_st_X509_NAME_ENTRY *sk, sk_X509_NAME_ENTRY_copyfunc copyfunc, sk_X509_NAME_ENTRY_freefunc freefunc) { return (struct stack_st_X509_NAME_ENTRY *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_NAME_ENTRY_compfunc sk_X509_NAME_ENTRY_set_cmp_func(struct stack_st_X509_NAME_ENTRY *sk, sk_X509_NAME_ENTRY_compfunc compare) { return (sk_X509_NAME_ENTRY_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
struct stack_st_X509_NAME; typedef int (*sk_X509_NAME_compfunc)(const X509_NAME * const *a, const X509_NAME *const *b); typedef void (*sk_X509_NAME_freefunc)(X509_NAME *a); typedef X509_NAME * (*sk_X509_NAME_copyfunc)(const X509_NAME *a); static __attribute__((unused)) inline int sk_X509_NAME_num(const struct stack_st_X509_NAME *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_NAME *sk_X509_NAME_value(const struct stack_st_X509_NAME *sk, int idx) { return (X509_NAME *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_NAME *sk_X509_NAME_new(sk_X509_NAME_compfunc compare) { return (struct stack_st_X509_NAME *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_NAME *sk_X509_NAME_new_null(void) { return (struct stack_st_X509_NAME *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_NAME *sk_X509_NAME_new_reserve(sk_X509_NAME_compfunc compare, int n) { return (struct stack_st_X509_NAME *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_NAME_reserve(struct stack_st_X509_NAME *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_NAME_free(struct stack_st_X509_NAME *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_NAME_zero(struct stack_st_X509_NAME *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_NAME *sk_X509_NAME_delete(struct stack_st_X509_NAME *sk, int i) { return (X509_NAME *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_NAME *sk_X509_NAME_delete_ptr(struct stack_st_X509_NAME *sk, X509_NAME *ptr) { return (X509_NAME *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_push(struct stack_st_X509_NAME *sk, X509_NAME *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_unshift(struct stack_st_X509_NAME *sk, X509_NAME *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_NAME *sk_X509_NAME_pop(struct stack_st_X509_NAME *sk) { return (X509_NAME *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_NAME *sk_X509_NAME_shift(struct stack_st_X509_NAME *sk) { return (X509_NAME *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_NAME_pop_free(struct stack_st_X509_NAME *sk, sk_X509_NAME_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_NAME_insert(struct stack_st_X509_NAME *sk, X509_NAME *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_NAME *sk_X509_NAME_set(struct stack_st_X509_NAME *sk, int idx, X509_NAME *ptr) { return (X509_NAME *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_find(struct stack_st_X509_NAME *sk, X509_NAME *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_NAME_find_ex(struct stack_st_X509_NAME *sk, X509_NAME *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_NAME_sort(struct stack_st_X509_NAME *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_NAME_is_sorted(const struct stack_st_X509_NAME *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_NAME * sk_X509_NAME_dup(const struct stack_st_X509_NAME *sk) { return (struct stack_st_X509_NAME *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_NAME *sk_X509_NAME_deep_copy(const struct stack_st_X509_NAME *sk, sk_X509_NAME_copyfunc copyfunc, sk_X509_NAME_freefunc freefunc) { return (struct stack_st_X509_NAME *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_NAME_compfunc sk_X509_NAME_set_cmp_func(struct stack_st_X509_NAME *sk, sk_X509_NAME_compfunc compare) { return (sk_X509_NAME_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum {
	X509_EX_V_NETSCAPE_HACK = 0x8000,
	X509_EX_V_INIT       = 0x0001,
};
typedef struct X509_extension_st X509_EXTENSION;
typedef struct stack_st_X509_EXTENSION X509_EXTENSIONS;
struct stack_st_X509_EXTENSION; typedef int (*sk_X509_EXTENSION_compfunc)(const X509_EXTENSION * const *a, const X509_EXTENSION *const *b); typedef void (*sk_X509_EXTENSION_freefunc)(X509_EXTENSION *a); typedef X509_EXTENSION * (*sk_X509_EXTENSION_copyfunc)(const X509_EXTENSION *a); static __attribute__((unused)) inline int sk_X509_EXTENSION_num(const struct stack_st_X509_EXTENSION *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_EXTENSION *sk_X509_EXTENSION_value(const struct stack_st_X509_EXTENSION *sk, int idx) { return (X509_EXTENSION *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_EXTENSION *sk_X509_EXTENSION_new(sk_X509_EXTENSION_compfunc compare) { return (struct stack_st_X509_EXTENSION *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_EXTENSION *sk_X509_EXTENSION_new_null(void) { return (struct stack_st_X509_EXTENSION *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_EXTENSION *sk_X509_EXTENSION_new_reserve(sk_X509_EXTENSION_compfunc compare, int n) { return (struct stack_st_X509_EXTENSION *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_EXTENSION_reserve(struct stack_st_X509_EXTENSION *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_EXTENSION_free(struct stack_st_X509_EXTENSION *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_EXTENSION_zero(struct stack_st_X509_EXTENSION *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_EXTENSION *sk_X509_EXTENSION_delete(struct stack_st_X509_EXTENSION *sk, int i) { return (X509_EXTENSION *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_EXTENSION *sk_X509_EXTENSION_delete_ptr(struct stack_st_X509_EXTENSION *sk, X509_EXTENSION *ptr) { return (X509_EXTENSION *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_EXTENSION_push(struct stack_st_X509_EXTENSION *sk, X509_EXTENSION *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_EXTENSION_unshift(struct stack_st_X509_EXTENSION *sk, X509_EXTENSION *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_EXTENSION *sk_X509_EXTENSION_pop(struct stack_st_X509_EXTENSION *sk) { return (X509_EXTENSION *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_EXTENSION *sk_X509_EXTENSION_shift(struct stack_st_X509_EXTENSION *sk) { return (X509_EXTENSION *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_EXTENSION_pop_free(struct stack_st_X509_EXTENSION *sk, sk_X509_EXTENSION_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_EXTENSION_insert(struct stack_st_X509_EXTENSION *sk, X509_EXTENSION *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_EXTENSION *sk_X509_EXTENSION_set(struct stack_st_X509_EXTENSION *sk, int idx, X509_EXTENSION *ptr) { return (X509_EXTENSION *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_EXTENSION_find(struct stack_st_X509_EXTENSION *sk, X509_EXTENSION *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_EXTENSION_find_ex(struct stack_st_X509_EXTENSION *sk, X509_EXTENSION *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_EXTENSION_sort(struct stack_st_X509_EXTENSION *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_EXTENSION_is_sorted(const struct stack_st_X509_EXTENSION *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_EXTENSION * sk_X509_EXTENSION_dup(const struct stack_st_X509_EXTENSION *sk) { return (struct stack_st_X509_EXTENSION *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_EXTENSION *sk_X509_EXTENSION_deep_copy(const struct stack_st_X509_EXTENSION *sk, sk_X509_EXTENSION_copyfunc copyfunc, sk_X509_EXTENSION_freefunc freefunc) { return (struct stack_st_X509_EXTENSION *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_EXTENSION_compfunc sk_X509_EXTENSION_set_cmp_func(struct stack_st_X509_EXTENSION *sk, sk_X509_EXTENSION_compfunc compare) { return (sk_X509_EXTENSION_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct x509_attributes_st X509_ATTRIBUTE;
struct stack_st_X509_ATTRIBUTE; typedef int (*sk_X509_ATTRIBUTE_compfunc)(const X509_ATTRIBUTE * const *a, const X509_ATTRIBUTE *const *b); typedef void (*sk_X509_ATTRIBUTE_freefunc)(X509_ATTRIBUTE *a); typedef X509_ATTRIBUTE * (*sk_X509_ATTRIBUTE_copyfunc)(const X509_ATTRIBUTE *a); static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_num(const struct stack_st_X509_ATTRIBUTE *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_ATTRIBUTE *sk_X509_ATTRIBUTE_value(const struct stack_st_X509_ATTRIBUTE *sk, int idx) { return (X509_ATTRIBUTE *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_ATTRIBUTE *sk_X509_ATTRIBUTE_new(sk_X509_ATTRIBUTE_compfunc compare) { return (struct stack_st_X509_ATTRIBUTE *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_ATTRIBUTE *sk_X509_ATTRIBUTE_new_null(void) { return (struct stack_st_X509_ATTRIBUTE *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_ATTRIBUTE *sk_X509_ATTRIBUTE_new_reserve(sk_X509_ATTRIBUTE_compfunc compare, int n) { return (struct stack_st_X509_ATTRIBUTE *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_reserve(struct stack_st_X509_ATTRIBUTE *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_ATTRIBUTE_free(struct stack_st_X509_ATTRIBUTE *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_ATTRIBUTE_zero(struct stack_st_X509_ATTRIBUTE *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_ATTRIBUTE *sk_X509_ATTRIBUTE_delete(struct stack_st_X509_ATTRIBUTE *sk, int i) { return (X509_ATTRIBUTE *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_ATTRIBUTE *sk_X509_ATTRIBUTE_delete_ptr(struct stack_st_X509_ATTRIBUTE *sk, X509_ATTRIBUTE *ptr) { return (X509_ATTRIBUTE *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_push(struct stack_st_X509_ATTRIBUTE *sk, X509_ATTRIBUTE *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_unshift(struct stack_st_X509_ATTRIBUTE *sk, X509_ATTRIBUTE *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_ATTRIBUTE *sk_X509_ATTRIBUTE_pop(struct stack_st_X509_ATTRIBUTE *sk) { return (X509_ATTRIBUTE *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_ATTRIBUTE *sk_X509_ATTRIBUTE_shift(struct stack_st_X509_ATTRIBUTE *sk) { return (X509_ATTRIBUTE *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_ATTRIBUTE_pop_free(struct stack_st_X509_ATTRIBUTE *sk, sk_X509_ATTRIBUTE_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_insert(struct stack_st_X509_ATTRIBUTE *sk, X509_ATTRIBUTE *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_ATTRIBUTE *sk_X509_ATTRIBUTE_set(struct stack_st_X509_ATTRIBUTE *sk, int idx, X509_ATTRIBUTE *ptr) { return (X509_ATTRIBUTE *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_find(struct stack_st_X509_ATTRIBUTE *sk, X509_ATTRIBUTE *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_find_ex(struct stack_st_X509_ATTRIBUTE *sk, X509_ATTRIBUTE *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_ATTRIBUTE_sort(struct stack_st_X509_ATTRIBUTE *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_ATTRIBUTE_is_sorted(const struct stack_st_X509_ATTRIBUTE *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_ATTRIBUTE * sk_X509_ATTRIBUTE_dup(const struct stack_st_X509_ATTRIBUTE *sk) { return (struct stack_st_X509_ATTRIBUTE *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_ATTRIBUTE *sk_X509_ATTRIBUTE_deep_copy(const struct stack_st_X509_ATTRIBUTE *sk, sk_X509_ATTRIBUTE_copyfunc copyfunc, sk_X509_ATTRIBUTE_freefunc freefunc) { return (struct stack_st_X509_ATTRIBUTE *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_ATTRIBUTE_compfunc sk_X509_ATTRIBUTE_set_cmp_func(struct stack_st_X509_ATTRIBUTE *sk, sk_X509_ATTRIBUTE_compfunc compare) { return (sk_X509_ATTRIBUTE_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct X509_req_info_st X509_REQ_INFO;
typedef struct X509_req_st X509_REQ;
typedef struct x509_cert_aux_st X509_CERT_AUX;
typedef struct x509_cinf_st X509_CINF;
struct stack_st_X509; typedef int (*sk_X509_compfunc)(const X509 * const *a, const X509 *const *b); typedef void (*sk_X509_freefunc)(X509 *a); typedef X509 * (*sk_X509_copyfunc)(const X509 *a); static __attribute__((unused)) inline int sk_X509_num(const struct stack_st_X509 *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509 *sk_X509_value(const struct stack_st_X509 *sk, int idx) { return (X509 *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509 *sk_X509_new(sk_X509_compfunc compare) { return (struct stack_st_X509 *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509 *sk_X509_new_null(void) { return (struct stack_st_X509 *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509 *sk_X509_new_reserve(sk_X509_compfunc compare, int n) { return (struct stack_st_X509 *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_reserve(struct stack_st_X509 *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_free(struct stack_st_X509 *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_zero(struct stack_st_X509 *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509 *sk_X509_delete(struct stack_st_X509 *sk, int i) { return (X509 *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509 *sk_X509_delete_ptr(struct stack_st_X509 *sk, X509 *ptr) { return (X509 *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_push(struct stack_st_X509 *sk, X509 *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_unshift(struct stack_st_X509 *sk, X509 *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509 *sk_X509_pop(struct stack_st_X509 *sk) { return (X509 *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509 *sk_X509_shift(struct stack_st_X509 *sk) { return (X509 *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_pop_free(struct stack_st_X509 *sk, sk_X509_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_insert(struct stack_st_X509 *sk, X509 *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509 *sk_X509_set(struct stack_st_X509 *sk, int idx, X509 *ptr) { return (X509 *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_find(struct stack_st_X509 *sk, X509 *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_find_ex(struct stack_st_X509 *sk, X509 *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_sort(struct stack_st_X509 *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_is_sorted(const struct stack_st_X509 *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509 * sk_X509_dup(const struct stack_st_X509 *sk) { return (struct stack_st_X509 *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509 *sk_X509_deep_copy(const struct stack_st_X509 *sk, sk_X509_copyfunc copyfunc, sk_X509_freefunc freefunc) { return (struct stack_st_X509 *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_compfunc sk_X509_set_cmp_func(struct stack_st_X509 *sk, sk_X509_compfunc compare) { return (sk_X509_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct x509_trust_st {
    int trust;
    int flags;
    int (*check_trust) (struct x509_trust_st *, X509 *, int);
    char *name;
    int arg1;
    void *arg2;
} X509_TRUST;
struct stack_st_X509_TRUST; typedef int (*sk_X509_TRUST_compfunc)(const X509_TRUST * const *a, const X509_TRUST *const *b); typedef void (*sk_X509_TRUST_freefunc)(X509_TRUST *a); typedef X509_TRUST * (*sk_X509_TRUST_copyfunc)(const X509_TRUST *a); static __attribute__((unused)) inline int sk_X509_TRUST_num(const struct stack_st_X509_TRUST *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_TRUST *sk_X509_TRUST_value(const struct stack_st_X509_TRUST *sk, int idx) { return (X509_TRUST *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_TRUST *sk_X509_TRUST_new(sk_X509_TRUST_compfunc compare) { return (struct stack_st_X509_TRUST *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_TRUST *sk_X509_TRUST_new_null(void) { return (struct stack_st_X509_TRUST *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_TRUST *sk_X509_TRUST_new_reserve(sk_X509_TRUST_compfunc compare, int n) { return (struct stack_st_X509_TRUST *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_TRUST_reserve(struct stack_st_X509_TRUST *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_TRUST_free(struct stack_st_X509_TRUST *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_TRUST_zero(struct stack_st_X509_TRUST *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_TRUST *sk_X509_TRUST_delete(struct stack_st_X509_TRUST *sk, int i) { return (X509_TRUST *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_TRUST *sk_X509_TRUST_delete_ptr(struct stack_st_X509_TRUST *sk, X509_TRUST *ptr) { return (X509_TRUST *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_TRUST_push(struct stack_st_X509_TRUST *sk, X509_TRUST *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_TRUST_unshift(struct stack_st_X509_TRUST *sk, X509_TRUST *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_TRUST *sk_X509_TRUST_pop(struct stack_st_X509_TRUST *sk) { return (X509_TRUST *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_TRUST *sk_X509_TRUST_shift(struct stack_st_X509_TRUST *sk) { return (X509_TRUST *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_TRUST_pop_free(struct stack_st_X509_TRUST *sk, sk_X509_TRUST_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_TRUST_insert(struct stack_st_X509_TRUST *sk, X509_TRUST *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_TRUST *sk_X509_TRUST_set(struct stack_st_X509_TRUST *sk, int idx, X509_TRUST *ptr) { return (X509_TRUST *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_TRUST_find(struct stack_st_X509_TRUST *sk, X509_TRUST *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_TRUST_find_ex(struct stack_st_X509_TRUST *sk, X509_TRUST *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_TRUST_sort(struct stack_st_X509_TRUST *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_TRUST_is_sorted(const struct stack_st_X509_TRUST *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_TRUST * sk_X509_TRUST_dup(const struct stack_st_X509_TRUST *sk) { return (struct stack_st_X509_TRUST *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_TRUST *sk_X509_TRUST_deep_copy(const struct stack_st_X509_TRUST *sk, sk_X509_TRUST_copyfunc copyfunc, sk_X509_TRUST_freefunc freefunc) { return (struct stack_st_X509_TRUST *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_TRUST_compfunc sk_X509_TRUST_set_cmp_func(struct stack_st_X509_TRUST *sk, sk_X509_TRUST_compfunc compare) { return (sk_X509_TRUST_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum {
	X509_TRUST_DEFAULT   = 0,
	X509_TRUST_COMPAT    = 1,
	X509_TRUST_SSL_CLIENT = 2,
	X509_TRUST_SSL_SERVER = 3,
	X509_TRUST_EMAIL     = 4,
	X509_TRUST_OBJECT_SIGN = 5,
	X509_TRUST_OCSP_SIGN = 6,
	X509_TRUST_OCSP_REQUEST = 7,
	X509_TRUST_TSA       = 8,
	X509_TRUST_MIN       = 1,
	X509_TRUST_MAX       = 8,
	X509_TRUST_DYNAMIC   = (1U << 0),
	X509_TRUST_DYNAMIC_NAME = (1U << 1),
	X509_TRUST_NO_SS_COMPAT = (1U << 2),
	X509_TRUST_DO_SS_COMPAT = (1U << 3),
	X509_TRUST_OK_ANY_EKU = (1U << 4),
	X509_TRUST_TRUSTED   = 1,
	X509_TRUST_REJECTED  = 2,
	X509_TRUST_UNTRUSTED = 3,
	X509_FLAG_COMPAT     = 0,
	X509_FLAG_NO_HEADER  = 1L,
	X509_FLAG_NO_VERSION = (1L << 1),
	X509_FLAG_NO_SERIAL  = (1L << 2),
	X509_FLAG_NO_SIGNAME = (1L << 3),
	X509_FLAG_NO_ISSUER  = (1L << 4),
	X509_FLAG_NO_VALIDITY = (1L << 5),
	X509_FLAG_NO_SUBJECT = (1L << 6),
	X509_FLAG_NO_PUBKEY  = (1L << 7),
	X509_FLAG_NO_EXTENSIONS = (1L << 8),
	X509_FLAG_NO_SIGDUMP = (1L << 9),
	X509_FLAG_NO_AUX     = (1L << 10),
	X509_FLAG_NO_ATTRIBUTES = (1L << 11),
	X509_FLAG_NO_IDS     = (1L << 12),
	XN_FLAG_SEP_MASK     = (0xf << 16),
	XN_FLAG_COMPAT       = 0,
	XN_FLAG_SEP_COMMA_PLUS = (1 << 16),
	XN_FLAG_SEP_CPLUS_SPC = (2 << 16),
	XN_FLAG_SEP_SPLUS_SPC = (3 << 16),
	XN_FLAG_SEP_MULTILINE = (4 << 16),
	XN_FLAG_DN_REV       = (1 << 20),
	XN_FLAG_FN_MASK      = (0x3 << 21),
	XN_FLAG_FN_SN        = 0,
	XN_FLAG_FN_LN        = (1 << 21),
	XN_FLAG_FN_OID       = (2 << 21),
	XN_FLAG_FN_NONE      = (3 << 21),
	XN_FLAG_SPC_EQ       = (1 << 23),
	XN_FLAG_DUMP_UNKNOWN_FIELDS = (1 << 24),
	XN_FLAG_FN_ALIGN     = (1 << 25),
	XN_FLAG_RFC2253      = (ASN1_STRFLGS_RFC2253 | XN_FLAG_SEP_COMMA_PLUS | XN_FLAG_DN_REV | XN_FLAG_FN_SN | XN_FLAG_DUMP_UNKNOWN_FIELDS),
	XN_FLAG_ONELINE      = (ASN1_STRFLGS_RFC2253 | ASN1_STRFLGS_ESC_QUOTE | XN_FLAG_SEP_CPLUS_SPC | XN_FLAG_SPC_EQ | XN_FLAG_FN_SN),
	XN_FLAG_MULTILINE    = (ASN1_STRFLGS_ESC_CTRL | ASN1_STRFLGS_ESC_MSB | XN_FLAG_SEP_MULTILINE | XN_FLAG_SPC_EQ | XN_FLAG_FN_LN | XN_FLAG_FN_ALIGN),
};
struct stack_st_X509_REVOKED; typedef int (*sk_X509_REVOKED_compfunc)(const X509_REVOKED * const *a, const X509_REVOKED *const *b); typedef void (*sk_X509_REVOKED_freefunc)(X509_REVOKED *a); typedef X509_REVOKED * (*sk_X509_REVOKED_copyfunc)(const X509_REVOKED *a); static __attribute__((unused)) inline int sk_X509_REVOKED_num(const struct stack_st_X509_REVOKED *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_REVOKED *sk_X509_REVOKED_value(const struct stack_st_X509_REVOKED *sk, int idx) { return (X509_REVOKED *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_REVOKED *sk_X509_REVOKED_new(sk_X509_REVOKED_compfunc compare) { return (struct stack_st_X509_REVOKED *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_REVOKED *sk_X509_REVOKED_new_null(void) { return (struct stack_st_X509_REVOKED *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_REVOKED *sk_X509_REVOKED_new_reserve(sk_X509_REVOKED_compfunc compare, int n) { return (struct stack_st_X509_REVOKED *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_REVOKED_reserve(struct stack_st_X509_REVOKED *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_REVOKED_free(struct stack_st_X509_REVOKED *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_REVOKED_zero(struct stack_st_X509_REVOKED *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_REVOKED *sk_X509_REVOKED_delete(struct stack_st_X509_REVOKED *sk, int i) { return (X509_REVOKED *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_REVOKED *sk_X509_REVOKED_delete_ptr(struct stack_st_X509_REVOKED *sk, X509_REVOKED *ptr) { return (X509_REVOKED *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_REVOKED_push(struct stack_st_X509_REVOKED *sk, X509_REVOKED *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_REVOKED_unshift(struct stack_st_X509_REVOKED *sk, X509_REVOKED *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_REVOKED *sk_X509_REVOKED_pop(struct stack_st_X509_REVOKED *sk) { return (X509_REVOKED *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_REVOKED *sk_X509_REVOKED_shift(struct stack_st_X509_REVOKED *sk) { return (X509_REVOKED *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_REVOKED_pop_free(struct stack_st_X509_REVOKED *sk, sk_X509_REVOKED_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_REVOKED_insert(struct stack_st_X509_REVOKED *sk, X509_REVOKED *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_REVOKED *sk_X509_REVOKED_set(struct stack_st_X509_REVOKED *sk, int idx, X509_REVOKED *ptr) { return (X509_REVOKED *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_REVOKED_find(struct stack_st_X509_REVOKED *sk, X509_REVOKED *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_REVOKED_find_ex(struct stack_st_X509_REVOKED *sk, X509_REVOKED *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_REVOKED_sort(struct stack_st_X509_REVOKED *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_REVOKED_is_sorted(const struct stack_st_X509_REVOKED *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_REVOKED * sk_X509_REVOKED_dup(const struct stack_st_X509_REVOKED *sk) { return (struct stack_st_X509_REVOKED *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_REVOKED *sk_X509_REVOKED_deep_copy(const struct stack_st_X509_REVOKED *sk, sk_X509_REVOKED_copyfunc copyfunc, sk_X509_REVOKED_freefunc freefunc) { return (struct stack_st_X509_REVOKED *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_REVOKED_compfunc sk_X509_REVOKED_set_cmp_func(struct stack_st_X509_REVOKED *sk, sk_X509_REVOKED_compfunc compare) { return (sk_X509_REVOKED_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct X509_crl_info_st X509_CRL_INFO;
struct stack_st_X509_CRL; typedef int (*sk_X509_CRL_compfunc)(const X509_CRL * const *a, const X509_CRL *const *b); typedef void (*sk_X509_CRL_freefunc)(X509_CRL *a); typedef X509_CRL * (*sk_X509_CRL_copyfunc)(const X509_CRL *a); static __attribute__((unused)) inline int sk_X509_CRL_num(const struct stack_st_X509_CRL *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_CRL *sk_X509_CRL_value(const struct stack_st_X509_CRL *sk, int idx) { return (X509_CRL *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_CRL *sk_X509_CRL_new(sk_X509_CRL_compfunc compare) { return (struct stack_st_X509_CRL *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_CRL *sk_X509_CRL_new_null(void) { return (struct stack_st_X509_CRL *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_CRL *sk_X509_CRL_new_reserve(sk_X509_CRL_compfunc compare, int n) { return (struct stack_st_X509_CRL *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_CRL_reserve(struct stack_st_X509_CRL *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_CRL_free(struct stack_st_X509_CRL *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_CRL_zero(struct stack_st_X509_CRL *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_CRL *sk_X509_CRL_delete(struct stack_st_X509_CRL *sk, int i) { return (X509_CRL *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_CRL *sk_X509_CRL_delete_ptr(struct stack_st_X509_CRL *sk, X509_CRL *ptr) { return (X509_CRL *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_CRL_push(struct stack_st_X509_CRL *sk, X509_CRL *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_CRL_unshift(struct stack_st_X509_CRL *sk, X509_CRL *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_CRL *sk_X509_CRL_pop(struct stack_st_X509_CRL *sk) { return (X509_CRL *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_CRL *sk_X509_CRL_shift(struct stack_st_X509_CRL *sk) { return (X509_CRL *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_CRL_pop_free(struct stack_st_X509_CRL *sk, sk_X509_CRL_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_CRL_insert(struct stack_st_X509_CRL *sk, X509_CRL *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_CRL *sk_X509_CRL_set(struct stack_st_X509_CRL *sk, int idx, X509_CRL *ptr) { return (X509_CRL *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_CRL_find(struct stack_st_X509_CRL *sk, X509_CRL *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_CRL_find_ex(struct stack_st_X509_CRL *sk, X509_CRL *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_CRL_sort(struct stack_st_X509_CRL *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_CRL_is_sorted(const struct stack_st_X509_CRL *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_CRL * sk_X509_CRL_dup(const struct stack_st_X509_CRL *sk) { return (struct stack_st_X509_CRL *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_CRL *sk_X509_CRL_deep_copy(const struct stack_st_X509_CRL *sk, sk_X509_CRL_copyfunc copyfunc, sk_X509_CRL_freefunc freefunc) { return (struct stack_st_X509_CRL *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_CRL_compfunc sk_X509_CRL_set_cmp_func(struct stack_st_X509_CRL *sk, sk_X509_CRL_compfunc compare) { return (sk_X509_CRL_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct private_key_st {
    int version;
    X509_ALGOR *enc_algor;
    ASN1_OCTET_STRING *enc_pkey;
    EVP_PKEY *dec_pkey;
    int key_length;
    char *key_data;
    int key_free;
    EVP_CIPHER_INFO cipher;
} X509_PKEY;
typedef struct X509_info_st {
    X509 *x509;
    X509_CRL *crl;
    X509_PKEY *x_pkey;
    EVP_CIPHER_INFO enc_cipher;
    int enc_len;
    char *enc_data;
} X509_INFO;
struct stack_st_X509_INFO; typedef int (*sk_X509_INFO_compfunc)(const X509_INFO * const *a, const X509_INFO *const *b); typedef void (*sk_X509_INFO_freefunc)(X509_INFO *a); typedef X509_INFO * (*sk_X509_INFO_copyfunc)(const X509_INFO *a); static __attribute__((unused)) inline int sk_X509_INFO_num(const struct stack_st_X509_INFO *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_INFO *sk_X509_INFO_value(const struct stack_st_X509_INFO *sk, int idx) { return (X509_INFO *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_INFO *sk_X509_INFO_new(sk_X509_INFO_compfunc compare) { return (struct stack_st_X509_INFO *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_INFO *sk_X509_INFO_new_null(void) { return (struct stack_st_X509_INFO *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_INFO *sk_X509_INFO_new_reserve(sk_X509_INFO_compfunc compare, int n) { return (struct stack_st_X509_INFO *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_INFO_reserve(struct stack_st_X509_INFO *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_INFO_free(struct stack_st_X509_INFO *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_INFO_zero(struct stack_st_X509_INFO *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_INFO *sk_X509_INFO_delete(struct stack_st_X509_INFO *sk, int i) { return (X509_INFO *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_INFO *sk_X509_INFO_delete_ptr(struct stack_st_X509_INFO *sk, X509_INFO *ptr) { return (X509_INFO *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_INFO_push(struct stack_st_X509_INFO *sk, X509_INFO *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_INFO_unshift(struct stack_st_X509_INFO *sk, X509_INFO *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_INFO *sk_X509_INFO_pop(struct stack_st_X509_INFO *sk) { return (X509_INFO *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_INFO *sk_X509_INFO_shift(struct stack_st_X509_INFO *sk) { return (X509_INFO *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_INFO_pop_free(struct stack_st_X509_INFO *sk, sk_X509_INFO_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_INFO_insert(struct stack_st_X509_INFO *sk, X509_INFO *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_INFO *sk_X509_INFO_set(struct stack_st_X509_INFO *sk, int idx, X509_INFO *ptr) { return (X509_INFO *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_INFO_find(struct stack_st_X509_INFO *sk, X509_INFO *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_INFO_find_ex(struct stack_st_X509_INFO *sk, X509_INFO *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_INFO_sort(struct stack_st_X509_INFO *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_INFO_is_sorted(const struct stack_st_X509_INFO *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_INFO * sk_X509_INFO_dup(const struct stack_st_X509_INFO *sk) { return (struct stack_st_X509_INFO *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_INFO *sk_X509_INFO_deep_copy(const struct stack_st_X509_INFO *sk, sk_X509_INFO_copyfunc copyfunc, sk_X509_INFO_freefunc freefunc) { return (struct stack_st_X509_INFO *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_INFO_compfunc sk_X509_INFO_set_cmp_func(struct stack_st_X509_INFO *sk, sk_X509_INFO_compfunc compare) { return (sk_X509_INFO_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct Netscape_spkac_st {
    X509_PUBKEY *pubkey;
    ASN1_IA5STRING *challenge;
} NETSCAPE_SPKAC;
typedef struct Netscape_spki_st {
    NETSCAPE_SPKAC *spkac;
    X509_ALGOR sig_algor;
    ASN1_BIT_STRING *signature;
} NETSCAPE_SPKI;
typedef struct Netscape_certificate_sequence {
    ASN1_OBJECT *type;
    struct stack_st_X509 *certs;
} NETSCAPE_CERT_SEQUENCE;
typedef struct PBEPARAM_st {
    ASN1_OCTET_STRING *salt;
    ASN1_INTEGER *iter;
} PBEPARAM;
typedef struct PBE2PARAM_st {
    X509_ALGOR *keyfunc;
    X509_ALGOR *encryption;
} PBE2PARAM;
typedef struct PBKDF2PARAM_st {
    ASN1_TYPE *salt;
    ASN1_INTEGER *iter;
    ASN1_INTEGER *keylength;
    X509_ALGOR *prf;
} PBKDF2PARAM;
typedef struct SCRYPT_PARAMS_st {
    ASN1_OCTET_STRING *salt;
    ASN1_INTEGER *costParameter;
    ASN1_INTEGER *blockSize;
    ASN1_INTEGER *parallelizationParameter;
    ASN1_INTEGER *keyLength;
} SCRYPT_PARAMS;
enum {
	X509_EXT_PACK_UNKNOWN = 1,
	X509_EXT_PACK_STRING = 2,
};
#define X509_extract_key(x) X509_get_pubkey(x)
#define X509_REQ_extract_key(a) X509_REQ_get_pubkey(a)
#define X509_name_cmp(a,b) X509_NAME_cmp((a),(b))
void X509_CRL_set_default_method(const X509_CRL_METHOD *meth);
X509_CRL_METHOD *X509_CRL_METHOD_new(int (*crl_init) (X509_CRL *crl),
                                     int (*crl_free) (X509_CRL *crl),
                                     int (*crl_lookup) (X509_CRL *crl,
                                                        X509_REVOKED **ret,
                                                        ASN1_INTEGER *ser,
                                                        X509_NAME *issuer),
                                     int (*crl_verify) (X509_CRL *crl,
                                                        EVP_PKEY *pk));
void X509_CRL_METHOD_free(X509_CRL_METHOD *m);
void X509_CRL_set_meth_data(X509_CRL *crl, void *dat);
void *X509_CRL_get_meth_data(X509_CRL *crl);
const char *X509_verify_cert_error_string(long n);
int X509_verify(X509 *a, EVP_PKEY *r);
int X509_REQ_verify(X509_REQ *a, EVP_PKEY *r);
int X509_CRL_verify(X509_CRL *a, EVP_PKEY *r);
int NETSCAPE_SPKI_verify(NETSCAPE_SPKI *a, EVP_PKEY *r);
NETSCAPE_SPKI *NETSCAPE_SPKI_b64_decode(const char *str, int len);
char *NETSCAPE_SPKI_b64_encode(NETSCAPE_SPKI *x);
EVP_PKEY *NETSCAPE_SPKI_get_pubkey(NETSCAPE_SPKI *x);
int NETSCAPE_SPKI_set_pubkey(NETSCAPE_SPKI *x, EVP_PKEY *pkey);
int NETSCAPE_SPKI_print(BIO *out, NETSCAPE_SPKI *spki);
int X509_signature_dump(BIO *bp, const ASN1_STRING *sig, int indent);
int X509_signature_print(BIO *bp, const X509_ALGOR *alg,
                         const ASN1_STRING *sig);
int X509_sign(X509 *x, EVP_PKEY *pkey, const EVP_MD *md);
int X509_sign_ctx(X509 *x, EVP_MD_CTX *ctx);
int X509_http_nbio(OCSP_REQ_CTX *rctx, X509 **pcert);
int X509_REQ_sign(X509_REQ *x, EVP_PKEY *pkey, const EVP_MD *md);
int X509_REQ_sign_ctx(X509_REQ *x, EVP_MD_CTX *ctx);
int X509_CRL_sign(X509_CRL *x, EVP_PKEY *pkey, const EVP_MD *md);
int X509_CRL_sign_ctx(X509_CRL *x, EVP_MD_CTX *ctx);
int X509_CRL_http_nbio(OCSP_REQ_CTX *rctx, X509_CRL **pcrl);
int NETSCAPE_SPKI_sign(NETSCAPE_SPKI *x, EVP_PKEY *pkey, const EVP_MD *md);
int X509_pubkey_digest(const X509 *data, const EVP_MD *type,
                       unsigned char *md, unsigned int *len);
int X509_digest(const X509 *data, const EVP_MD *type,
                unsigned char *md, unsigned int *len);
int X509_CRL_digest(const X509_CRL *data, const EVP_MD *type,
                    unsigned char *md, unsigned int *len);
int X509_REQ_digest(const X509_REQ *data, const EVP_MD *type,
                    unsigned char *md, unsigned int *len);
int X509_NAME_digest(const X509_NAME *data, const EVP_MD *type,
                     unsigned char *md, unsigned int *len);
X509 *d2i_X509_fp(FILE *fp, X509 **x509);
int i2d_X509_fp(FILE *fp, X509 *x509);
X509_CRL *d2i_X509_CRL_fp(FILE *fp, X509_CRL **crl);
int i2d_X509_CRL_fp(FILE *fp, X509_CRL *crl);
X509_REQ *d2i_X509_REQ_fp(FILE *fp, X509_REQ **req);
int i2d_X509_REQ_fp(FILE *fp, X509_REQ *req);
RSA *d2i_RSAPrivateKey_fp(FILE *fp, RSA **rsa);
int i2d_RSAPrivateKey_fp(FILE *fp, RSA *rsa);
RSA *d2i_RSAPublicKey_fp(FILE *fp, RSA **rsa);
int i2d_RSAPublicKey_fp(FILE *fp, RSA *rsa);
RSA *d2i_RSA_PUBKEY_fp(FILE *fp, RSA **rsa);
int i2d_RSA_PUBKEY_fp(FILE *fp, RSA *rsa);
DSA *d2i_DSA_PUBKEY_fp(FILE *fp, DSA **dsa);
int i2d_DSA_PUBKEY_fp(FILE *fp, DSA *dsa);
DSA *d2i_DSAPrivateKey_fp(FILE *fp, DSA **dsa);
int i2d_DSAPrivateKey_fp(FILE *fp, DSA *dsa);
EC_KEY *d2i_EC_PUBKEY_fp(FILE *fp, EC_KEY **eckey);
int i2d_EC_PUBKEY_fp(FILE *fp, EC_KEY *eckey);
EC_KEY *d2i_ECPrivateKey_fp(FILE *fp, EC_KEY **eckey);
int i2d_ECPrivateKey_fp(FILE *fp, EC_KEY *eckey);
X509_SIG *d2i_PKCS8_fp(FILE *fp, X509_SIG **p8);
int i2d_PKCS8_fp(FILE *fp, X509_SIG *p8);
PKCS8_PRIV_KEY_INFO *d2i_PKCS8_PRIV_KEY_INFO_fp(FILE *fp,
                                                PKCS8_PRIV_KEY_INFO **p8inf);
int i2d_PKCS8_PRIV_KEY_INFO_fp(FILE *fp, PKCS8_PRIV_KEY_INFO *p8inf);
int i2d_PKCS8PrivateKeyInfo_fp(FILE *fp, EVP_PKEY *key);
int i2d_PrivateKey_fp(FILE *fp, EVP_PKEY *pkey);
EVP_PKEY *d2i_PrivateKey_fp(FILE *fp, EVP_PKEY **a);
int i2d_PUBKEY_fp(FILE *fp, EVP_PKEY *pkey);
EVP_PKEY *d2i_PUBKEY_fp(FILE *fp, EVP_PKEY **a);
X509 *d2i_X509_bio(BIO *bp, X509 **x509);
int i2d_X509_bio(BIO *bp, X509 *x509);
X509_CRL *d2i_X509_CRL_bio(BIO *bp, X509_CRL **crl);
int i2d_X509_CRL_bio(BIO *bp, X509_CRL *crl);
X509_REQ *d2i_X509_REQ_bio(BIO *bp, X509_REQ **req);
int i2d_X509_REQ_bio(BIO *bp, X509_REQ *req);
RSA *d2i_RSAPrivateKey_bio(BIO *bp, RSA **rsa);
int i2d_RSAPrivateKey_bio(BIO *bp, RSA *rsa);
RSA *d2i_RSAPublicKey_bio(BIO *bp, RSA **rsa);
int i2d_RSAPublicKey_bio(BIO *bp, RSA *rsa);
RSA *d2i_RSA_PUBKEY_bio(BIO *bp, RSA **rsa);
int i2d_RSA_PUBKEY_bio(BIO *bp, RSA *rsa);
DSA *d2i_DSA_PUBKEY_bio(BIO *bp, DSA **dsa);
int i2d_DSA_PUBKEY_bio(BIO *bp, DSA *dsa);
DSA *d2i_DSAPrivateKey_bio(BIO *bp, DSA **dsa);
int i2d_DSAPrivateKey_bio(BIO *bp, DSA *dsa);
EC_KEY *d2i_EC_PUBKEY_bio(BIO *bp, EC_KEY **eckey);
int i2d_EC_PUBKEY_bio(BIO *bp, EC_KEY *eckey);
EC_KEY *d2i_ECPrivateKey_bio(BIO *bp, EC_KEY **eckey);
int i2d_ECPrivateKey_bio(BIO *bp, EC_KEY *eckey);
X509_SIG *d2i_PKCS8_bio(BIO *bp, X509_SIG **p8);
int i2d_PKCS8_bio(BIO *bp, X509_SIG *p8);
PKCS8_PRIV_KEY_INFO *d2i_PKCS8_PRIV_KEY_INFO_bio(BIO *bp,
                                                 PKCS8_PRIV_KEY_INFO **p8inf);
int i2d_PKCS8_PRIV_KEY_INFO_bio(BIO *bp, PKCS8_PRIV_KEY_INFO *p8inf);
int i2d_PKCS8PrivateKeyInfo_bio(BIO *bp, EVP_PKEY *key);
int i2d_PrivateKey_bio(BIO *bp, EVP_PKEY *pkey);
EVP_PKEY *d2i_PrivateKey_bio(BIO *bp, EVP_PKEY **a);
int i2d_PUBKEY_bio(BIO *bp, EVP_PKEY *pkey);
EVP_PKEY *d2i_PUBKEY_bio(BIO *bp, EVP_PKEY **a);
X509 *X509_dup(X509 *x509);
X509_ATTRIBUTE *X509_ATTRIBUTE_dup(X509_ATTRIBUTE *xa);
X509_EXTENSION *X509_EXTENSION_dup(X509_EXTENSION *ex);
X509_CRL *X509_CRL_dup(X509_CRL *crl);
X509_REVOKED *X509_REVOKED_dup(X509_REVOKED *rev);
X509_REQ *X509_REQ_dup(X509_REQ *req);
X509_ALGOR *X509_ALGOR_dup(X509_ALGOR *xn);
int X509_ALGOR_set0(X509_ALGOR *alg, ASN1_OBJECT *aobj, int ptype,
                    void *pval);
void X509_ALGOR_get0(const ASN1_OBJECT **paobj, int *pptype,
                     const void **ppval, const X509_ALGOR *algor);
void X509_ALGOR_set_md(X509_ALGOR *alg, const EVP_MD *md);
int X509_ALGOR_cmp(const X509_ALGOR *a, const X509_ALGOR *b);
X509_NAME *X509_NAME_dup(X509_NAME *xn);
X509_NAME_ENTRY *X509_NAME_ENTRY_dup(X509_NAME_ENTRY *ne);
int X509_cmp_time(const ASN1_TIME *s, time_t *t);
int X509_cmp_current_time(const ASN1_TIME *s);
ASN1_TIME *X509_time_adj(ASN1_TIME *s, long adj, time_t *t);
ASN1_TIME *X509_time_adj_ex(ASN1_TIME *s,
                            int offset_day, long offset_sec, time_t *t);
ASN1_TIME *X509_gmtime_adj(ASN1_TIME *s, long adj);
const char *X509_get_default_cert_area(void);
const char *X509_get_default_cert_dir(void);
const char *X509_get_default_cert_file(void);
const char *X509_get_default_cert_dir_env(void);
const char *X509_get_default_cert_file_env(void);
const char *X509_get_default_private_dir(void);
X509_REQ *X509_to_X509_REQ(X509 *x, EVP_PKEY *pkey, const EVP_MD *md);
X509 *X509_REQ_to_X509(X509_REQ *r, int days, EVP_PKEY *pkey);
X509_ALGOR *X509_ALGOR_new(void); void X509_ALGOR_free(X509_ALGOR *a); X509_ALGOR *d2i_X509_ALGOR(X509_ALGOR **a, const unsigned char **in, long len); int i2d_X509_ALGOR(X509_ALGOR *a, unsigned char **out); const ASN1_ITEM * X509_ALGOR_it(void);
X509_ALGORS *d2i_X509_ALGORS(X509_ALGORS **a, const unsigned char **in, long len); int i2d_X509_ALGORS(X509_ALGORS *a, unsigned char **out); const ASN1_ITEM * X509_ALGORS_it(void);
X509_VAL *X509_VAL_new(void); void X509_VAL_free(X509_VAL *a); X509_VAL *d2i_X509_VAL(X509_VAL **a, const unsigned char **in, long len); int i2d_X509_VAL(X509_VAL *a, unsigned char **out); const ASN1_ITEM * X509_VAL_it(void);
X509_PUBKEY *X509_PUBKEY_new(void); void X509_PUBKEY_free(X509_PUBKEY *a); X509_PUBKEY *d2i_X509_PUBKEY(X509_PUBKEY **a, const unsigned char **in, long len); int i2d_X509_PUBKEY(X509_PUBKEY *a, unsigned char **out); const ASN1_ITEM * X509_PUBKEY_it(void);
int X509_PUBKEY_set(X509_PUBKEY **x, EVP_PKEY *pkey);
EVP_PKEY *X509_PUBKEY_get0(X509_PUBKEY *key);
EVP_PKEY *X509_PUBKEY_get(X509_PUBKEY *key);
int X509_get_pubkey_parameters(EVP_PKEY *pkey, struct stack_st_X509 *chain);
long X509_get_pathlen(X509 *x);
int i2d_PUBKEY(EVP_PKEY *a, unsigned char **pp);
EVP_PKEY *d2i_PUBKEY(EVP_PKEY **a, const unsigned char **pp, long length);
int i2d_RSA_PUBKEY(RSA *a, unsigned char **pp);
RSA *d2i_RSA_PUBKEY(RSA **a, const unsigned char **pp, long length);
int i2d_DSA_PUBKEY(DSA *a, unsigned char **pp);
DSA *d2i_DSA_PUBKEY(DSA **a, const unsigned char **pp, long length);
int i2d_EC_PUBKEY(EC_KEY *a, unsigned char **pp);
EC_KEY *d2i_EC_PUBKEY(EC_KEY **a, const unsigned char **pp, long length);
X509_SIG *X509_SIG_new(void); void X509_SIG_free(X509_SIG *a); X509_SIG *d2i_X509_SIG(X509_SIG **a, const unsigned char **in, long len); int i2d_X509_SIG(X509_SIG *a, unsigned char **out); const ASN1_ITEM * X509_SIG_it(void);
void X509_SIG_get0(const X509_SIG *sig, const X509_ALGOR **palg,
                   const ASN1_OCTET_STRING **pdigest);
void X509_SIG_getm(X509_SIG *sig, X509_ALGOR **palg,
                   ASN1_OCTET_STRING **pdigest);
X509_REQ_INFO *X509_REQ_INFO_new(void); void X509_REQ_INFO_free(X509_REQ_INFO *a); X509_REQ_INFO *d2i_X509_REQ_INFO(X509_REQ_INFO **a, const unsigned char **in, long len); int i2d_X509_REQ_INFO(X509_REQ_INFO *a, unsigned char **out); const ASN1_ITEM * X509_REQ_INFO_it(void);
X509_REQ *X509_REQ_new(void); void X509_REQ_free(X509_REQ *a); X509_REQ *d2i_X509_REQ(X509_REQ **a, const unsigned char **in, long len); int i2d_X509_REQ(X509_REQ *a, unsigned char **out); const ASN1_ITEM * X509_REQ_it(void);
X509_ATTRIBUTE *X509_ATTRIBUTE_new(void); void X509_ATTRIBUTE_free(X509_ATTRIBUTE *a); X509_ATTRIBUTE *d2i_X509_ATTRIBUTE(X509_ATTRIBUTE **a, const unsigned char **in, long len); int i2d_X509_ATTRIBUTE(X509_ATTRIBUTE *a, unsigned char **out); const ASN1_ITEM * X509_ATTRIBUTE_it(void);
X509_ATTRIBUTE *X509_ATTRIBUTE_create(int nid, int atrtype, void *value);
X509_EXTENSION *X509_EXTENSION_new(void); void X509_EXTENSION_free(X509_EXTENSION *a); X509_EXTENSION *d2i_X509_EXTENSION(X509_EXTENSION **a, const unsigned char **in, long len); int i2d_X509_EXTENSION(X509_EXTENSION *a, unsigned char **out); const ASN1_ITEM * X509_EXTENSION_it(void);
X509_EXTENSIONS *d2i_X509_EXTENSIONS(X509_EXTENSIONS **a, const unsigned char **in, long len); int i2d_X509_EXTENSIONS(X509_EXTENSIONS *a, unsigned char **out); const ASN1_ITEM * X509_EXTENSIONS_it(void);
X509_NAME_ENTRY *X509_NAME_ENTRY_new(void); void X509_NAME_ENTRY_free(X509_NAME_ENTRY *a); X509_NAME_ENTRY *d2i_X509_NAME_ENTRY(X509_NAME_ENTRY **a, const unsigned char **in, long len); int i2d_X509_NAME_ENTRY(X509_NAME_ENTRY *a, unsigned char **out); const ASN1_ITEM * X509_NAME_ENTRY_it(void);
X509_NAME *X509_NAME_new(void); void X509_NAME_free(X509_NAME *a); X509_NAME *d2i_X509_NAME(X509_NAME **a, const unsigned char **in, long len); int i2d_X509_NAME(X509_NAME *a, unsigned char **out); const ASN1_ITEM * X509_NAME_it(void);
int X509_NAME_set(X509_NAME **xn, X509_NAME *name);
X509_CINF *X509_CINF_new(void); void X509_CINF_free(X509_CINF *a); X509_CINF *d2i_X509_CINF(X509_CINF **a, const unsigned char **in, long len); int i2d_X509_CINF(X509_CINF *a, unsigned char **out); const ASN1_ITEM * X509_CINF_it(void);
X509 *X509_new(void); void X509_free(X509 *a); X509 *d2i_X509(X509 **a, const unsigned char **in, long len); int i2d_X509(X509 *a, unsigned char **out); const ASN1_ITEM * X509_it(void);
X509_CERT_AUX *X509_CERT_AUX_new(void); void X509_CERT_AUX_free(X509_CERT_AUX *a); X509_CERT_AUX *d2i_X509_CERT_AUX(X509_CERT_AUX **a, const unsigned char **in, long len); int i2d_X509_CERT_AUX(X509_CERT_AUX *a, unsigned char **out); const ASN1_ITEM * X509_CERT_AUX_it(void);
#define X509_get_ex_new_index(l,p,newf,dupf,freef) CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_X509, l, p, newf, dupf, freef)
int X509_set_ex_data(X509 *r, int idx, void *arg);
void *X509_get_ex_data(X509 *r, int idx);
int i2d_X509_AUX(X509 *a, unsigned char **pp);
X509 *d2i_X509_AUX(X509 **a, const unsigned char **pp, long length);
int i2d_re_X509_tbs(X509 *x, unsigned char **pp);
int X509_SIG_INFO_get(const X509_SIG_INFO *siginf, int *mdnid, int *pknid,
                      int *secbits, uint32_t *flags);
void X509_SIG_INFO_set(X509_SIG_INFO *siginf, int mdnid, int pknid,
                       int secbits, uint32_t flags);
int X509_get_signature_info(X509 *x, int *mdnid, int *pknid, int *secbits,
                            uint32_t *flags);
void X509_get0_signature(const ASN1_BIT_STRING **psig,
                         const X509_ALGOR **palg, const X509 *x);
int X509_get_signature_nid(const X509 *x);
int X509_trusted(const X509 *x);
int X509_alias_set1(X509 *x, const unsigned char *name, int len);
int X509_keyid_set1(X509 *x, const unsigned char *id, int len);
unsigned char *X509_alias_get0(X509 *x, int *len);
unsigned char *X509_keyid_get0(X509 *x, int *len);
int (*X509_TRUST_set_default(int (*trust) (int, X509 *, int))) (int, X509 *,
                                                                int);
int X509_TRUST_set(int *t, int trust);
int X509_add1_trust_object(X509 *x, const ASN1_OBJECT *obj);
int X509_add1_reject_object(X509 *x, const ASN1_OBJECT *obj);
void X509_trust_clear(X509 *x);
void X509_reject_clear(X509 *x);
struct stack_st_ASN1_OBJECT *X509_get0_trust_objects(X509 *x);
struct stack_st_ASN1_OBJECT *X509_get0_reject_objects(X509 *x);
X509_REVOKED *X509_REVOKED_new(void); void X509_REVOKED_free(X509_REVOKED *a); X509_REVOKED *d2i_X509_REVOKED(X509_REVOKED **a, const unsigned char **in, long len); int i2d_X509_REVOKED(X509_REVOKED *a, unsigned char **out); const ASN1_ITEM * X509_REVOKED_it(void);
X509_CRL_INFO *X509_CRL_INFO_new(void); void X509_CRL_INFO_free(X509_CRL_INFO *a); X509_CRL_INFO *d2i_X509_CRL_INFO(X509_CRL_INFO **a, const unsigned char **in, long len); int i2d_X509_CRL_INFO(X509_CRL_INFO *a, unsigned char **out); const ASN1_ITEM * X509_CRL_INFO_it(void);
X509_CRL *X509_CRL_new(void); void X509_CRL_free(X509_CRL *a); X509_CRL *d2i_X509_CRL(X509_CRL **a, const unsigned char **in, long len); int i2d_X509_CRL(X509_CRL *a, unsigned char **out); const ASN1_ITEM * X509_CRL_it(void);
int X509_CRL_add0_revoked(X509_CRL *crl, X509_REVOKED *rev);
int X509_CRL_get0_by_serial(X509_CRL *crl,
                            X509_REVOKED **ret, ASN1_INTEGER *serial);
int X509_CRL_get0_by_cert(X509_CRL *crl, X509_REVOKED **ret, X509 *x);
X509_PKEY *X509_PKEY_new(void);
void X509_PKEY_free(X509_PKEY *a);
NETSCAPE_SPKI *NETSCAPE_SPKI_new(void); void NETSCAPE_SPKI_free(NETSCAPE_SPKI *a); NETSCAPE_SPKI *d2i_NETSCAPE_SPKI(NETSCAPE_SPKI **a, const unsigned char **in, long len); int i2d_NETSCAPE_SPKI(NETSCAPE_SPKI *a, unsigned char **out); const ASN1_ITEM * NETSCAPE_SPKI_it(void);
NETSCAPE_SPKAC *NETSCAPE_SPKAC_new(void); void NETSCAPE_SPKAC_free(NETSCAPE_SPKAC *a); NETSCAPE_SPKAC *d2i_NETSCAPE_SPKAC(NETSCAPE_SPKAC **a, const unsigned char **in, long len); int i2d_NETSCAPE_SPKAC(NETSCAPE_SPKAC *a, unsigned char **out); const ASN1_ITEM * NETSCAPE_SPKAC_it(void);
NETSCAPE_CERT_SEQUENCE *NETSCAPE_CERT_SEQUENCE_new(void); void NETSCAPE_CERT_SEQUENCE_free(NETSCAPE_CERT_SEQUENCE *a); NETSCAPE_CERT_SEQUENCE *d2i_NETSCAPE_CERT_SEQUENCE(NETSCAPE_CERT_SEQUENCE **a, const unsigned char **in, long len); int i2d_NETSCAPE_CERT_SEQUENCE(NETSCAPE_CERT_SEQUENCE *a, unsigned char **out); const ASN1_ITEM * NETSCAPE_CERT_SEQUENCE_it(void);
X509_INFO *X509_INFO_new(void);
void X509_INFO_free(X509_INFO *a);
char *X509_NAME_oneline(const X509_NAME *a, char *buf, int size);
int ASN1_verify(i2d_of_void *i2d, X509_ALGOR *algor1,
                ASN1_BIT_STRING *signature, char *data, EVP_PKEY *pkey);
int ASN1_digest(i2d_of_void *i2d, const EVP_MD *type, char *data,
                unsigned char *md, unsigned int *len);
int ASN1_sign(i2d_of_void *i2d, X509_ALGOR *algor1,
              X509_ALGOR *algor2, ASN1_BIT_STRING *signature,
              char *data, EVP_PKEY *pkey, const EVP_MD *type);
int ASN1_item_digest(const ASN1_ITEM *it, const EVP_MD *type, void *data,
                     unsigned char *md, unsigned int *len);
int ASN1_item_verify(const ASN1_ITEM *it, X509_ALGOR *algor1,
                     ASN1_BIT_STRING *signature, void *data, EVP_PKEY *pkey);
int ASN1_item_sign(const ASN1_ITEM *it, X509_ALGOR *algor1,
                   X509_ALGOR *algor2, ASN1_BIT_STRING *signature, void *data,
                   EVP_PKEY *pkey, const EVP_MD *type);
int ASN1_item_sign_ctx(const ASN1_ITEM *it, X509_ALGOR *algor1,
                       X509_ALGOR *algor2, ASN1_BIT_STRING *signature,
                       void *asn, EVP_MD_CTX *ctx);
long X509_get_version(const X509 *x);
int X509_set_version(X509 *x, long version);
int X509_set_serialNumber(X509 *x, ASN1_INTEGER *serial);
ASN1_INTEGER *X509_get_serialNumber(X509 *x);
const ASN1_INTEGER *X509_get0_serialNumber(const X509 *x);
int X509_set_issuer_name(X509 *x, X509_NAME *name);
X509_NAME *X509_get_issuer_name(const X509 *a);
int X509_set_subject_name(X509 *x, X509_NAME *name);
X509_NAME *X509_get_subject_name(const X509 *a);
const ASN1_TIME * X509_get0_notBefore(const X509 *x);
ASN1_TIME *X509_getm_notBefore(const X509 *x);
int X509_set1_notBefore(X509 *x, const ASN1_TIME *tm);
const ASN1_TIME *X509_get0_notAfter(const X509 *x);
ASN1_TIME *X509_getm_notAfter(const X509 *x);
int X509_set1_notAfter(X509 *x, const ASN1_TIME *tm);
int X509_set_pubkey(X509 *x, EVP_PKEY *pkey);
int X509_up_ref(X509 *x);
int X509_get_signature_type(const X509 *x);
enum {
	X509_get_notBefore   = X509_getm_notBefore,
	X509_get_notAfter    = X509_getm_notAfter,
	X509_set_notBefore   = X509_set1_notBefore,
	X509_set_notAfter    = X509_set1_notAfter,
};
X509_PUBKEY *X509_get_X509_PUBKEY(const X509 *x);
const struct stack_st_X509_EXTENSION *X509_get0_extensions(const X509 *x);
void X509_get0_uids(const X509 *x, const ASN1_BIT_STRING **piuid,
                    const ASN1_BIT_STRING **psuid);
const X509_ALGOR *X509_get0_tbs_sigalg(const X509 *x);
EVP_PKEY *X509_get0_pubkey(const X509 *x);
EVP_PKEY *X509_get_pubkey(X509 *x);
ASN1_BIT_STRING *X509_get0_pubkey_bitstr(const X509 *x);
int X509_certificate_type(const X509 *x, const EVP_PKEY *pubkey);
long X509_REQ_get_version(const X509_REQ *req);
int X509_REQ_set_version(X509_REQ *x, long version);
X509_NAME *X509_REQ_get_subject_name(const X509_REQ *req);
int X509_REQ_set_subject_name(X509_REQ *req, X509_NAME *name);
void X509_REQ_get0_signature(const X509_REQ *req, const ASN1_BIT_STRING **psig,
                             const X509_ALGOR **palg);
int X509_REQ_get_signature_nid(const X509_REQ *req);
int i2d_re_X509_REQ_tbs(X509_REQ *req, unsigned char **pp);
int X509_REQ_set_pubkey(X509_REQ *x, EVP_PKEY *pkey);
EVP_PKEY *X509_REQ_get_pubkey(X509_REQ *req);
EVP_PKEY *X509_REQ_get0_pubkey(X509_REQ *req);
X509_PUBKEY *X509_REQ_get_X509_PUBKEY(X509_REQ *req);
int X509_REQ_extension_nid(int nid);
int *X509_REQ_get_extension_nids(void);
void X509_REQ_set_extension_nids(int *nids);
struct stack_st_X509_EXTENSION *X509_REQ_get_extensions(X509_REQ *req);
int X509_REQ_add_extensions_nid(X509_REQ *req, struct stack_st_X509_EXTENSION *exts,
                                int nid);
int X509_REQ_add_extensions(X509_REQ *req, struct stack_st_X509_EXTENSION *exts);
int X509_REQ_get_attr_count(const X509_REQ *req);
int X509_REQ_get_attr_by_NID(const X509_REQ *req, int nid, int lastpos);
int X509_REQ_get_attr_by_OBJ(const X509_REQ *req, const ASN1_OBJECT *obj,
                             int lastpos);
X509_ATTRIBUTE *X509_REQ_get_attr(const X509_REQ *req, int loc);
X509_ATTRIBUTE *X509_REQ_delete_attr(X509_REQ *req, int loc);
int X509_REQ_add1_attr(X509_REQ *req, X509_ATTRIBUTE *attr);
int X509_REQ_add1_attr_by_OBJ(X509_REQ *req,
                              const ASN1_OBJECT *obj, int type,
                              const unsigned char *bytes, int len);
int X509_REQ_add1_attr_by_NID(X509_REQ *req,
                              int nid, int type,
                              const unsigned char *bytes, int len);
int X509_REQ_add1_attr_by_txt(X509_REQ *req,
                              const char *attrname, int type,
                              const unsigned char *bytes, int len);
int X509_CRL_set_version(X509_CRL *x, long version);
int X509_CRL_set_issuer_name(X509_CRL *x, X509_NAME *name);
int X509_CRL_set1_lastUpdate(X509_CRL *x, const ASN1_TIME *tm);
int X509_CRL_set1_nextUpdate(X509_CRL *x, const ASN1_TIME *tm);
int X509_CRL_sort(X509_CRL *crl);
int X509_CRL_up_ref(X509_CRL *crl);
enum {
	X509_CRL_set_lastUpdate = X509_CRL_set1_lastUpdate,
	X509_CRL_set_nextUpdate = X509_CRL_set1_nextUpdate,
};
long X509_CRL_get_version(const X509_CRL *crl);
const ASN1_TIME *X509_CRL_get0_lastUpdate(const X509_CRL *crl);
const ASN1_TIME *X509_CRL_get0_nextUpdate(const X509_CRL *crl);
ASN1_TIME *X509_CRL_get_lastUpdate(X509_CRL *crl) __attribute__ ((deprecated));
ASN1_TIME *X509_CRL_get_nextUpdate(X509_CRL *crl) __attribute__ ((deprecated));
X509_NAME *X509_CRL_get_issuer(const X509_CRL *crl);
const struct stack_st_X509_EXTENSION *X509_CRL_get0_extensions(const X509_CRL *crl);
struct stack_st_X509_REVOKED *X509_CRL_get_REVOKED(X509_CRL *crl);
void X509_CRL_get0_signature(const X509_CRL *crl, const ASN1_BIT_STRING **psig,
                             const X509_ALGOR **palg);
int X509_CRL_get_signature_nid(const X509_CRL *crl);
int i2d_re_X509_CRL_tbs(X509_CRL *req, unsigned char **pp);
const ASN1_INTEGER *X509_REVOKED_get0_serialNumber(const X509_REVOKED *x);
int X509_REVOKED_set_serialNumber(X509_REVOKED *x, ASN1_INTEGER *serial);
const ASN1_TIME *X509_REVOKED_get0_revocationDate(const X509_REVOKED *x);
int X509_REVOKED_set_revocationDate(X509_REVOKED *r, ASN1_TIME *tm);
const struct stack_st_X509_EXTENSION *
X509_REVOKED_get0_extensions(const X509_REVOKED *r);
X509_CRL *X509_CRL_diff(X509_CRL *base, X509_CRL *newer,
                        EVP_PKEY *skey, const EVP_MD *md, unsigned int flags);
int X509_REQ_check_private_key(X509_REQ *x509, EVP_PKEY *pkey);
int X509_check_private_key(const X509 *x509, const EVP_PKEY *pkey);
int X509_chain_check_suiteb(int *perror_depth,
                            X509 *x, struct stack_st_X509 *chain,
                            unsigned long flags);
int X509_CRL_check_suiteb(X509_CRL *crl, EVP_PKEY *pk, unsigned long flags);
struct stack_st_X509 *X509_chain_up_ref(struct stack_st_X509 *chain);
int X509_issuer_and_serial_cmp(const X509 *a, const X509 *b);
unsigned long X509_issuer_and_serial_hash(X509 *a);
int X509_issuer_name_cmp(const X509 *a, const X509 *b);
unsigned long X509_issuer_name_hash(X509 *a);
int X509_subject_name_cmp(const X509 *a, const X509 *b);
unsigned long X509_subject_name_hash(X509 *x);
unsigned long X509_issuer_name_hash_old(X509 *a);
unsigned long X509_subject_name_hash_old(X509 *x);
int X509_cmp(const X509 *a, const X509 *b);
int X509_NAME_cmp(const X509_NAME *a, const X509_NAME *b);
unsigned long X509_NAME_hash(X509_NAME *x);
unsigned long X509_NAME_hash_old(X509_NAME *x);
int X509_CRL_cmp(const X509_CRL *a, const X509_CRL *b);
int X509_CRL_match(const X509_CRL *a, const X509_CRL *b);
int X509_aux_print(BIO *out, X509 *x, int indent);
int X509_print_ex_fp(FILE *bp, X509 *x, unsigned long nmflag,
                     unsigned long cflag);
int X509_print_fp(FILE *bp, X509 *x);
int X509_CRL_print_fp(FILE *bp, X509_CRL *x);
int X509_REQ_print_fp(FILE *bp, X509_REQ *req);
int X509_NAME_print_ex_fp(FILE *fp, const X509_NAME *nm, int indent,
                          unsigned long flags);
int X509_NAME_print(BIO *bp, const X509_NAME *name, int obase);
int X509_NAME_print_ex(BIO *out, const X509_NAME *nm, int indent,
                       unsigned long flags);
int X509_print_ex(BIO *bp, X509 *x, unsigned long nmflag,
                  unsigned long cflag);
int X509_print(BIO *bp, X509 *x);
int X509_ocspid_print(BIO *bp, X509 *x);
int X509_CRL_print_ex(BIO *out, X509_CRL *x, unsigned long nmflag);
int X509_CRL_print(BIO *bp, X509_CRL *x);
int X509_REQ_print_ex(BIO *bp, X509_REQ *x, unsigned long nmflag,
                      unsigned long cflag);
int X509_REQ_print(BIO *bp, X509_REQ *req);
int X509_NAME_entry_count(const X509_NAME *name);
int X509_NAME_get_text_by_NID(X509_NAME *name, int nid, char *buf, int len);
int X509_NAME_get_text_by_OBJ(X509_NAME *name, const ASN1_OBJECT *obj,
                              char *buf, int len);
int X509_NAME_get_index_by_NID(X509_NAME *name, int nid, int lastpos);
int X509_NAME_get_index_by_OBJ(X509_NAME *name, const ASN1_OBJECT *obj,
                               int lastpos);
X509_NAME_ENTRY *X509_NAME_get_entry(const X509_NAME *name, int loc);
X509_NAME_ENTRY *X509_NAME_delete_entry(X509_NAME *name, int loc);
int X509_NAME_add_entry(X509_NAME *name, const X509_NAME_ENTRY *ne,
                        int loc, int set);
int X509_NAME_add_entry_by_OBJ(X509_NAME *name, const ASN1_OBJECT *obj, int type,
                               const unsigned char *bytes, int len, int loc,
                               int set);
int X509_NAME_add_entry_by_NID(X509_NAME *name, int nid, int type,
                               const unsigned char *bytes, int len, int loc,
                               int set);
X509_NAME_ENTRY *X509_NAME_ENTRY_create_by_txt(X509_NAME_ENTRY **ne,
                                               const char *field, int type,
                                               const unsigned char *bytes,
                                               int len);
X509_NAME_ENTRY *X509_NAME_ENTRY_create_by_NID(X509_NAME_ENTRY **ne, int nid,
                                               int type,
                                               const unsigned char *bytes,
                                               int len);
int X509_NAME_add_entry_by_txt(X509_NAME *name, const char *field, int type,
                               const unsigned char *bytes, int len, int loc,
                               int set);
X509_NAME_ENTRY *X509_NAME_ENTRY_create_by_OBJ(X509_NAME_ENTRY **ne,
                                               const ASN1_OBJECT *obj, int type,
                                               const unsigned char *bytes,
                                               int len);
int X509_NAME_ENTRY_set_object(X509_NAME_ENTRY *ne, const ASN1_OBJECT *obj);
int X509_NAME_ENTRY_set_data(X509_NAME_ENTRY *ne, int type,
                             const unsigned char *bytes, int len);
ASN1_OBJECT *X509_NAME_ENTRY_get_object(const X509_NAME_ENTRY *ne);
ASN1_STRING * X509_NAME_ENTRY_get_data(const X509_NAME_ENTRY *ne);
int X509_NAME_ENTRY_set(const X509_NAME_ENTRY *ne);
int X509_NAME_get0_der(X509_NAME *nm, const unsigned char **pder,
                       size_t *pderlen);
int X509v3_get_ext_count(const struct stack_st_X509_EXTENSION *x);
int X509v3_get_ext_by_NID(const struct stack_st_X509_EXTENSION *x,
                          int nid, int lastpos);
int X509v3_get_ext_by_OBJ(const struct stack_st_X509_EXTENSION *x,
                          const ASN1_OBJECT *obj, int lastpos);
int X509v3_get_ext_by_critical(const struct stack_st_X509_EXTENSION *x,
                               int crit, int lastpos);
X509_EXTENSION *X509v3_get_ext(const struct stack_st_X509_EXTENSION *x, int loc);
X509_EXTENSION *X509v3_delete_ext(struct stack_st_X509_EXTENSION *x, int loc);
struct stack_st_X509_EXTENSION *X509v3_add_ext(struct stack_st_X509_EXTENSION **x,
                                         X509_EXTENSION *ex, int loc);
int X509_get_ext_count(const X509 *x);
int X509_get_ext_by_NID(const X509 *x, int nid, int lastpos);
int X509_get_ext_by_OBJ(const X509 *x, const ASN1_OBJECT *obj, int lastpos);
int X509_get_ext_by_critical(const X509 *x, int crit, int lastpos);
X509_EXTENSION *X509_get_ext(const X509 *x, int loc);
X509_EXTENSION *X509_delete_ext(X509 *x, int loc);
int X509_add_ext(X509 *x, X509_EXTENSION *ex, int loc);
void *X509_get_ext_d2i(const X509 *x, int nid, int *crit, int *idx);
int X509_add1_ext_i2d(X509 *x, int nid, void *value, int crit,
                      unsigned long flags);
int X509_CRL_get_ext_count(const X509_CRL *x);
int X509_CRL_get_ext_by_NID(const X509_CRL *x, int nid, int lastpos);
int X509_CRL_get_ext_by_OBJ(const X509_CRL *x, const ASN1_OBJECT *obj,
                            int lastpos);
int X509_CRL_get_ext_by_critical(const X509_CRL *x, int crit, int lastpos);
X509_EXTENSION *X509_CRL_get_ext(const X509_CRL *x, int loc);
X509_EXTENSION *X509_CRL_delete_ext(X509_CRL *x, int loc);
int X509_CRL_add_ext(X509_CRL *x, X509_EXTENSION *ex, int loc);
void *X509_CRL_get_ext_d2i(const X509_CRL *x, int nid, int *crit, int *idx);
int X509_CRL_add1_ext_i2d(X509_CRL *x, int nid, void *value, int crit,
                          unsigned long flags);
int X509_REVOKED_get_ext_count(const X509_REVOKED *x);
int X509_REVOKED_get_ext_by_NID(const X509_REVOKED *x, int nid, int lastpos);
int X509_REVOKED_get_ext_by_OBJ(const X509_REVOKED *x, const ASN1_OBJECT *obj,
                                int lastpos);
int X509_REVOKED_get_ext_by_critical(const X509_REVOKED *x, int crit,
                                     int lastpos);
X509_EXTENSION *X509_REVOKED_get_ext(const X509_REVOKED *x, int loc);
X509_EXTENSION *X509_REVOKED_delete_ext(X509_REVOKED *x, int loc);
int X509_REVOKED_add_ext(X509_REVOKED *x, X509_EXTENSION *ex, int loc);
void *X509_REVOKED_get_ext_d2i(const X509_REVOKED *x, int nid, int *crit,
                               int *idx);
int X509_REVOKED_add1_ext_i2d(X509_REVOKED *x, int nid, void *value, int crit,
                              unsigned long flags);
X509_EXTENSION *X509_EXTENSION_create_by_NID(X509_EXTENSION **ex,
                                             int nid, int crit,
                                             ASN1_OCTET_STRING *data);
X509_EXTENSION *X509_EXTENSION_create_by_OBJ(X509_EXTENSION **ex,
                                             const ASN1_OBJECT *obj, int crit,
                                             ASN1_OCTET_STRING *data);
int X509_EXTENSION_set_object(X509_EXTENSION *ex, const ASN1_OBJECT *obj);
int X509_EXTENSION_set_critical(X509_EXTENSION *ex, int crit);
int X509_EXTENSION_set_data(X509_EXTENSION *ex, ASN1_OCTET_STRING *data);
ASN1_OBJECT *X509_EXTENSION_get_object(X509_EXTENSION *ex);
ASN1_OCTET_STRING *X509_EXTENSION_get_data(X509_EXTENSION *ne);
int X509_EXTENSION_get_critical(const X509_EXTENSION *ex);
int X509at_get_attr_count(const struct stack_st_X509_ATTRIBUTE *x);
int X509at_get_attr_by_NID(const struct stack_st_X509_ATTRIBUTE *x, int nid,
                           int lastpos);
int X509at_get_attr_by_OBJ(const struct stack_st_X509_ATTRIBUTE *sk,
                           const ASN1_OBJECT *obj, int lastpos);
X509_ATTRIBUTE *X509at_get_attr(const struct stack_st_X509_ATTRIBUTE *x, int loc);
X509_ATTRIBUTE *X509at_delete_attr(struct stack_st_X509_ATTRIBUTE *x, int loc);
struct stack_st_X509_ATTRIBUTE *X509at_add1_attr(struct stack_st_X509_ATTRIBUTE **x,
                                           X509_ATTRIBUTE *attr);
struct stack_st_X509_ATTRIBUTE *X509at_add1_attr_by_OBJ(struct stack_st_X509_ATTRIBUTE
                                                  **x, const ASN1_OBJECT *obj,
                                                  int type,
                                                  const unsigned char *bytes,
                                                  int len);
struct stack_st_X509_ATTRIBUTE *X509at_add1_attr_by_NID(struct stack_st_X509_ATTRIBUTE
                                                  **x, int nid, int type,
                                                  const unsigned char *bytes,
                                                  int len);
struct stack_st_X509_ATTRIBUTE *X509at_add1_attr_by_txt(struct stack_st_X509_ATTRIBUTE
                                                  **x, const char *attrname,
                                                  int type,
                                                  const unsigned char *bytes,
                                                  int len);
void *X509at_get0_data_by_OBJ(struct stack_st_X509_ATTRIBUTE *x,
                              const ASN1_OBJECT *obj, int lastpos, int type);
X509_ATTRIBUTE *X509_ATTRIBUTE_create_by_NID(X509_ATTRIBUTE **attr, int nid,
                                             int atrtype, const void *data,
                                             int len);
X509_ATTRIBUTE *X509_ATTRIBUTE_create_by_OBJ(X509_ATTRIBUTE **attr,
                                             const ASN1_OBJECT *obj,
                                             int atrtype, const void *data,
                                             int len);
X509_ATTRIBUTE *X509_ATTRIBUTE_create_by_txt(X509_ATTRIBUTE **attr,
                                             const char *atrname, int type,
                                             const unsigned char *bytes,
                                             int len);
int X509_ATTRIBUTE_set1_object(X509_ATTRIBUTE *attr, const ASN1_OBJECT *obj);
int X509_ATTRIBUTE_set1_data(X509_ATTRIBUTE *attr, int attrtype,
                             const void *data, int len);
void *X509_ATTRIBUTE_get0_data(X509_ATTRIBUTE *attr, int idx, int atrtype,
                               void *data);
int X509_ATTRIBUTE_count(const X509_ATTRIBUTE *attr);
ASN1_OBJECT *X509_ATTRIBUTE_get0_object(X509_ATTRIBUTE *attr);
ASN1_TYPE *X509_ATTRIBUTE_get0_type(X509_ATTRIBUTE *attr, int idx);
int EVP_PKEY_get_attr_count(const EVP_PKEY *key);
int EVP_PKEY_get_attr_by_NID(const EVP_PKEY *key, int nid, int lastpos);
int EVP_PKEY_get_attr_by_OBJ(const EVP_PKEY *key, const ASN1_OBJECT *obj,
                             int lastpos);
X509_ATTRIBUTE *EVP_PKEY_get_attr(const EVP_PKEY *key, int loc);
X509_ATTRIBUTE *EVP_PKEY_delete_attr(EVP_PKEY *key, int loc);
int EVP_PKEY_add1_attr(EVP_PKEY *key, X509_ATTRIBUTE *attr);
int EVP_PKEY_add1_attr_by_OBJ(EVP_PKEY *key,
                              const ASN1_OBJECT *obj, int type,
                              const unsigned char *bytes, int len);
int EVP_PKEY_add1_attr_by_NID(EVP_PKEY *key,
                              int nid, int type,
                              const unsigned char *bytes, int len);
int EVP_PKEY_add1_attr_by_txt(EVP_PKEY *key,
                              const char *attrname, int type,
                              const unsigned char *bytes, int len);
int X509_verify_cert(X509_STORE_CTX *ctx);
X509 *X509_find_by_issuer_and_serial(struct stack_st_X509 *sk, X509_NAME *name,
                                     ASN1_INTEGER *serial);
X509 *X509_find_by_subject(struct stack_st_X509 *sk, X509_NAME *name);
PBEPARAM *PBEPARAM_new(void); void PBEPARAM_free(PBEPARAM *a); PBEPARAM *d2i_PBEPARAM(PBEPARAM **a, const unsigned char **in, long len); int i2d_PBEPARAM(PBEPARAM *a, unsigned char **out); const ASN1_ITEM * PBEPARAM_it(void);
PBE2PARAM *PBE2PARAM_new(void); void PBE2PARAM_free(PBE2PARAM *a); PBE2PARAM *d2i_PBE2PARAM(PBE2PARAM **a, const unsigned char **in, long len); int i2d_PBE2PARAM(PBE2PARAM *a, unsigned char **out); const ASN1_ITEM * PBE2PARAM_it(void);
PBKDF2PARAM *PBKDF2PARAM_new(void); void PBKDF2PARAM_free(PBKDF2PARAM *a); PBKDF2PARAM *d2i_PBKDF2PARAM(PBKDF2PARAM **a, const unsigned char **in, long len); int i2d_PBKDF2PARAM(PBKDF2PARAM *a, unsigned char **out); const ASN1_ITEM * PBKDF2PARAM_it(void);
SCRYPT_PARAMS *SCRYPT_PARAMS_new(void); void SCRYPT_PARAMS_free(SCRYPT_PARAMS *a); SCRYPT_PARAMS *d2i_SCRYPT_PARAMS(SCRYPT_PARAMS **a, const unsigned char **in, long len); int i2d_SCRYPT_PARAMS(SCRYPT_PARAMS *a, unsigned char **out); const ASN1_ITEM * SCRYPT_PARAMS_it(void);
int PKCS5_pbe_set0_algor(X509_ALGOR *algor, int alg, int iter,
                         const unsigned char *salt, int saltlen);
X509_ALGOR *PKCS5_pbe_set(int alg, int iter,
                          const unsigned char *salt, int saltlen);
X509_ALGOR *PKCS5_pbe2_set(const EVP_CIPHER *cipher, int iter,
                           unsigned char *salt, int saltlen);
X509_ALGOR *PKCS5_pbe2_set_iv(const EVP_CIPHER *cipher, int iter,
                              unsigned char *salt, int saltlen,
                              unsigned char *aiv, int prf_nid);
X509_ALGOR *PKCS5_pbe2_set_scrypt(const EVP_CIPHER *cipher,
                                  const unsigned char *salt, int saltlen,
                                  unsigned char *aiv, uint64_t N, uint64_t r,
                                  uint64_t p);
X509_ALGOR *PKCS5_pbkdf2_set(int iter, unsigned char *salt, int saltlen,
                             int prf_nid, int keylen);
PKCS8_PRIV_KEY_INFO *PKCS8_PRIV_KEY_INFO_new(void); void PKCS8_PRIV_KEY_INFO_free(PKCS8_PRIV_KEY_INFO *a); PKCS8_PRIV_KEY_INFO *d2i_PKCS8_PRIV_KEY_INFO(PKCS8_PRIV_KEY_INFO **a, const unsigned char **in, long len); int i2d_PKCS8_PRIV_KEY_INFO(PKCS8_PRIV_KEY_INFO *a, unsigned char **out); const ASN1_ITEM * PKCS8_PRIV_KEY_INFO_it(void);
EVP_PKEY *EVP_PKCS82PKEY(const PKCS8_PRIV_KEY_INFO *p8);
PKCS8_PRIV_KEY_INFO *EVP_PKEY2PKCS8(EVP_PKEY *pkey);
int PKCS8_pkey_set0(PKCS8_PRIV_KEY_INFO *priv, ASN1_OBJECT *aobj,
                    int version, int ptype, void *pval,
                    unsigned char *penc, int penclen);
int PKCS8_pkey_get0(const ASN1_OBJECT **ppkalg,
                    const unsigned char **pk, int *ppklen,
                    const X509_ALGOR **pa, const PKCS8_PRIV_KEY_INFO *p8);
const struct stack_st_X509_ATTRIBUTE *
PKCS8_pkey_get0_attrs(const PKCS8_PRIV_KEY_INFO *p8);
int PKCS8_pkey_add1_attr_by_NID(PKCS8_PRIV_KEY_INFO *p8, int nid, int type,
                                const unsigned char *bytes, int len);
int X509_PUBKEY_set0_param(X509_PUBKEY *pub, ASN1_OBJECT *aobj,
                           int ptype, void *pval,
                           unsigned char *penc, int penclen);
int X509_PUBKEY_get0_param(ASN1_OBJECT **ppkalg,
                           const unsigned char **pk, int *ppklen,
                           X509_ALGOR **pa, X509_PUBKEY *pub);
int X509_check_trust(X509 *x, int id, int flags);
int X509_TRUST_get_count(void);
X509_TRUST *X509_TRUST_get0(int idx);
int X509_TRUST_get_by_id(int id);
int X509_TRUST_add(int id, int flags, int (*ck) (X509_TRUST *, X509 *, int),
                   const char *name, int arg1, void *arg2);
void X509_TRUST_cleanup(void);
int X509_TRUST_get_flags(const X509_TRUST *xp);
char *X509_TRUST_get0_name(const X509_TRUST *xp);
int X509_TRUST_get_trust(const X509_TRUST *xp);


// csrc/openssl/src/include/openssl/x509err.h
int ERR_load_X509_strings(void);
enum {
	X509_F_ADD_CERT_DIR  = 100,
	X509_F_BUILD_CHAIN   = 106,
	X509_F_BY_FILE_CTRL  = 101,
	X509_F_CHECK_NAME_CONSTRAINTS = 149,
	X509_F_CHECK_POLICY  = 145,
	X509_F_DANE_I2D      = 107,
	X509_F_DIR_CTRL      = 102,
	X509_F_GET_CERT_BY_SUBJECT = 103,
	X509_F_I2D_X509_AUX  = 151,
	X509_F_LOOKUP_CERTS_SK = 152,
	X509_F_NETSCAPE_SPKI_B64_DECODE = 129,
	X509_F_NETSCAPE_SPKI_B64_ENCODE = 130,
	X509_F_NEW_DIR       = 153,
	X509_F_X509AT_ADD1_ATTR = 135,
	X509_F_X509V3_ADD_EXT = 104,
	X509_F_X509_ATTRIBUTE_CREATE_BY_NID = 136,
	X509_F_X509_ATTRIBUTE_CREATE_BY_OBJ = 137,
	X509_F_X509_ATTRIBUTE_CREATE_BY_TXT = 140,
	X509_F_X509_ATTRIBUTE_GET0_DATA = 139,
	X509_F_X509_ATTRIBUTE_SET1_DATA = 138,
	X509_F_X509_CHECK_PRIVATE_KEY = 128,
	X509_F_X509_CRL_DIFF = 105,
	X509_F_X509_CRL_METHOD_NEW = 154,
	X509_F_X509_CRL_PRINT_FP = 147,
	X509_F_X509_EXTENSION_CREATE_BY_NID = 108,
	X509_F_X509_EXTENSION_CREATE_BY_OBJ = 109,
	X509_F_X509_GET_PUBKEY_PARAMETERS = 110,
	X509_F_X509_LOAD_CERT_CRL_FILE = 132,
	X509_F_X509_LOAD_CERT_FILE = 111,
	X509_F_X509_LOAD_CRL_FILE = 112,
	X509_F_X509_LOOKUP_METH_NEW = 160,
	X509_F_X509_LOOKUP_NEW = 155,
	X509_F_X509_NAME_ADD_ENTRY = 113,
	X509_F_X509_NAME_CANON = 156,
	X509_F_X509_NAME_ENTRY_CREATE_BY_NID = 114,
	X509_F_X509_NAME_ENTRY_CREATE_BY_TXT = 131,
	X509_F_X509_NAME_ENTRY_SET_OBJECT = 115,
	X509_F_X509_NAME_ONELINE = 116,
	X509_F_X509_NAME_PRINT = 117,
	X509_F_X509_OBJECT_NEW = 150,
	X509_F_X509_PRINT_EX_FP = 118,
	X509_F_X509_PUBKEY_DECODE = 148,
	X509_F_X509_PUBKEY_GET0 = 119,
	X509_F_X509_PUBKEY_SET = 120,
	X509_F_X509_REQ_CHECK_PRIVATE_KEY = 144,
	X509_F_X509_REQ_PRINT_EX = 121,
	X509_F_X509_REQ_PRINT_FP = 122,
	X509_F_X509_REQ_TO_X509 = 123,
	X509_F_X509_STORE_ADD_CERT = 124,
	X509_F_X509_STORE_ADD_CRL = 125,
	X509_F_X509_STORE_ADD_LOOKUP = 157,
	X509_F_X509_STORE_CTX_GET1_ISSUER = 146,
	X509_F_X509_STORE_CTX_INIT = 143,
	X509_F_X509_STORE_CTX_NEW = 142,
	X509_F_X509_STORE_CTX_PURPOSE_INHERIT = 134,
	X509_F_X509_STORE_NEW = 158,
	X509_F_X509_TO_X509_REQ = 126,
	X509_F_X509_TRUST_ADD = 133,
	X509_F_X509_TRUST_SET = 141,
	X509_F_X509_VERIFY_CERT = 127,
	X509_F_X509_VERIFY_PARAM_NEW = 159,
	X509_R_AKID_MISMATCH = 110,
	X509_R_BAD_SELECTOR  = 133,
	X509_R_BAD_X509_FILETYPE = 100,
	X509_R_BASE64_DECODE_ERROR = 118,
	X509_R_CANT_CHECK_DH_KEY = 114,
	X509_R_CERT_ALREADY_IN_HASH_TABLE = 101,
	X509_R_CRL_ALREADY_DELTA = 127,
	X509_R_CRL_VERIFY_FAILURE = 131,
	X509_R_IDP_MISMATCH  = 128,
	X509_R_INVALID_ATTRIBUTES = 138,
	X509_R_INVALID_DIRECTORY = 113,
	X509_R_INVALID_FIELD_NAME = 119,
	X509_R_INVALID_TRUST = 123,
	X509_R_ISSUER_MISMATCH = 129,
	X509_R_KEY_TYPE_MISMATCH = 115,
	X509_R_KEY_VALUES_MISMATCH = 116,
	X509_R_LOADING_CERT_DIR = 103,
	X509_R_LOADING_DEFAULTS = 104,
	X509_R_METHOD_NOT_SUPPORTED = 124,
	X509_R_NAME_TOO_LONG = 134,
	X509_R_NEWER_CRL_NOT_NEWER = 132,
	X509_R_NO_CERTIFICATE_FOUND = 135,
	X509_R_NO_CERTIFICATE_OR_CRL_FOUND = 136,
	X509_R_NO_CERT_SET_FOR_US_TO_VERIFY = 105,
	X509_R_NO_CRL_FOUND  = 137,
	X509_R_NO_CRL_NUMBER = 130,
	X509_R_PUBLIC_KEY_DECODE_ERROR = 125,
	X509_R_PUBLIC_KEY_ENCODE_ERROR = 126,
	X509_R_SHOULD_RETRY  = 106,
	X509_R_UNABLE_TO_FIND_PARAMETERS_IN_CHAIN = 107,
	X509_R_UNABLE_TO_GET_CERTS_PUBLIC_KEY = 108,
	X509_R_UNKNOWN_KEY_TYPE = 117,
	X509_R_UNKNOWN_NID   = 109,
	X509_R_UNKNOWN_PURPOSE_ID = 121,
	X509_R_UNKNOWN_TRUST_ID = 120,
	X509_R_UNSUPPORTED_ALGORITHM = 111,
	X509_R_WRONG_LOOKUP_TYPE = 112,
	X509_R_WRONG_TYPE    = 122,
};
]]
