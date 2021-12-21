local ffi = require'ffi'
--[[
// csrc/openssl/src/include/openssl/pkcs7.h
typedef struct pkcs7_issuer_and_serial_st {
    X509_NAME *issuer;
    ASN1_INTEGER *serial;
} PKCS7_ISSUER_AND_SERIAL;
typedef struct pkcs7_signer_info_st {
    ASN1_INTEGER *version;
    PKCS7_ISSUER_AND_SERIAL *issuer_and_serial;
    X509_ALGOR *digest_alg;
    struct stack_st_X509_ATTRIBUTE *auth_attr;
    X509_ALGOR *digest_enc_alg;
    ASN1_OCTET_STRING *enc_digest;
    struct stack_st_X509_ATTRIBUTE *unauth_attr;
    EVP_PKEY *pkey;
} PKCS7_SIGNER_INFO;
struct stack_st_PKCS7_SIGNER_INFO; typedef int (*sk_PKCS7_SIGNER_INFO_compfunc)(const PKCS7_SIGNER_INFO * const *a, const PKCS7_SIGNER_INFO *const *b); typedef void (*sk_PKCS7_SIGNER_INFO_freefunc)(PKCS7_SIGNER_INFO *a); typedef PKCS7_SIGNER_INFO * (*sk_PKCS7_SIGNER_INFO_copyfunc)(const PKCS7_SIGNER_INFO *a); static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_num(const struct stack_st_PKCS7_SIGNER_INFO *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_value(const struct stack_st_PKCS7_SIGNER_INFO *sk, int idx) { return (PKCS7_SIGNER_INFO *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_new(sk_PKCS7_SIGNER_INFO_compfunc compare) { return (struct stack_st_PKCS7_SIGNER_INFO *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_new_null(void) { return (struct stack_st_PKCS7_SIGNER_INFO *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_new_reserve(sk_PKCS7_SIGNER_INFO_compfunc compare, int n) { return (struct stack_st_PKCS7_SIGNER_INFO *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_reserve(struct stack_st_PKCS7_SIGNER_INFO *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_PKCS7_SIGNER_INFO_free(struct stack_st_PKCS7_SIGNER_INFO *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_PKCS7_SIGNER_INFO_zero(struct stack_st_PKCS7_SIGNER_INFO *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_delete(struct stack_st_PKCS7_SIGNER_INFO *sk, int i) { return (PKCS7_SIGNER_INFO *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_delete_ptr(struct stack_st_PKCS7_SIGNER_INFO *sk, PKCS7_SIGNER_INFO *ptr) { return (PKCS7_SIGNER_INFO *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_push(struct stack_st_PKCS7_SIGNER_INFO *sk, PKCS7_SIGNER_INFO *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_unshift(struct stack_st_PKCS7_SIGNER_INFO *sk, PKCS7_SIGNER_INFO *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_pop(struct stack_st_PKCS7_SIGNER_INFO *sk) { return (PKCS7_SIGNER_INFO *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_shift(struct stack_st_PKCS7_SIGNER_INFO *sk) { return (PKCS7_SIGNER_INFO *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_PKCS7_SIGNER_INFO_pop_free(struct stack_st_PKCS7_SIGNER_INFO *sk, sk_PKCS7_SIGNER_INFO_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_insert(struct stack_st_PKCS7_SIGNER_INFO *sk, PKCS7_SIGNER_INFO *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_set(struct stack_st_PKCS7_SIGNER_INFO *sk, int idx, PKCS7_SIGNER_INFO *ptr) { return (PKCS7_SIGNER_INFO *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_find(struct stack_st_PKCS7_SIGNER_INFO *sk, PKCS7_SIGNER_INFO *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_find_ex(struct stack_st_PKCS7_SIGNER_INFO *sk, PKCS7_SIGNER_INFO *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_PKCS7_SIGNER_INFO_sort(struct stack_st_PKCS7_SIGNER_INFO *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_PKCS7_SIGNER_INFO_is_sorted(const struct stack_st_PKCS7_SIGNER_INFO *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_PKCS7_SIGNER_INFO * sk_PKCS7_SIGNER_INFO_dup(const struct stack_st_PKCS7_SIGNER_INFO *sk) { return (struct stack_st_PKCS7_SIGNER_INFO *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_PKCS7_SIGNER_INFO *sk_PKCS7_SIGNER_INFO_deep_copy(const struct stack_st_PKCS7_SIGNER_INFO *sk, sk_PKCS7_SIGNER_INFO_copyfunc copyfunc, sk_PKCS7_SIGNER_INFO_freefunc freefunc) { return (struct stack_st_PKCS7_SIGNER_INFO *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_PKCS7_SIGNER_INFO_compfunc sk_PKCS7_SIGNER_INFO_set_cmp_func(struct stack_st_PKCS7_SIGNER_INFO *sk, sk_PKCS7_SIGNER_INFO_compfunc compare) { return (sk_PKCS7_SIGNER_INFO_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct pkcs7_recip_info_st {
    ASN1_INTEGER *version;
    PKCS7_ISSUER_AND_SERIAL *issuer_and_serial;
    X509_ALGOR *key_enc_algor;
    ASN1_OCTET_STRING *enc_key;
    X509 *cert;
} PKCS7_RECIP_INFO;
struct stack_st_PKCS7_RECIP_INFO; typedef int (*sk_PKCS7_RECIP_INFO_compfunc)(const PKCS7_RECIP_INFO * const *a, const PKCS7_RECIP_INFO *const *b); typedef void (*sk_PKCS7_RECIP_INFO_freefunc)(PKCS7_RECIP_INFO *a); typedef PKCS7_RECIP_INFO * (*sk_PKCS7_RECIP_INFO_copyfunc)(const PKCS7_RECIP_INFO *a); static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_num(const struct stack_st_PKCS7_RECIP_INFO *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_value(const struct stack_st_PKCS7_RECIP_INFO *sk, int idx) { return (PKCS7_RECIP_INFO *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_new(sk_PKCS7_RECIP_INFO_compfunc compare) { return (struct stack_st_PKCS7_RECIP_INFO *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_new_null(void) { return (struct stack_st_PKCS7_RECIP_INFO *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_new_reserve(sk_PKCS7_RECIP_INFO_compfunc compare, int n) { return (struct stack_st_PKCS7_RECIP_INFO *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_reserve(struct stack_st_PKCS7_RECIP_INFO *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_PKCS7_RECIP_INFO_free(struct stack_st_PKCS7_RECIP_INFO *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_PKCS7_RECIP_INFO_zero(struct stack_st_PKCS7_RECIP_INFO *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_delete(struct stack_st_PKCS7_RECIP_INFO *sk, int i) { return (PKCS7_RECIP_INFO *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_delete_ptr(struct stack_st_PKCS7_RECIP_INFO *sk, PKCS7_RECIP_INFO *ptr) { return (PKCS7_RECIP_INFO *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_push(struct stack_st_PKCS7_RECIP_INFO *sk, PKCS7_RECIP_INFO *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_unshift(struct stack_st_PKCS7_RECIP_INFO *sk, PKCS7_RECIP_INFO *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_pop(struct stack_st_PKCS7_RECIP_INFO *sk) { return (PKCS7_RECIP_INFO *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_shift(struct stack_st_PKCS7_RECIP_INFO *sk) { return (PKCS7_RECIP_INFO *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_PKCS7_RECIP_INFO_pop_free(struct stack_st_PKCS7_RECIP_INFO *sk, sk_PKCS7_RECIP_INFO_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_insert(struct stack_st_PKCS7_RECIP_INFO *sk, PKCS7_RECIP_INFO *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_set(struct stack_st_PKCS7_RECIP_INFO *sk, int idx, PKCS7_RECIP_INFO *ptr) { return (PKCS7_RECIP_INFO *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_find(struct stack_st_PKCS7_RECIP_INFO *sk, PKCS7_RECIP_INFO *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_find_ex(struct stack_st_PKCS7_RECIP_INFO *sk, PKCS7_RECIP_INFO *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_PKCS7_RECIP_INFO_sort(struct stack_st_PKCS7_RECIP_INFO *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_PKCS7_RECIP_INFO_is_sorted(const struct stack_st_PKCS7_RECIP_INFO *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_PKCS7_RECIP_INFO * sk_PKCS7_RECIP_INFO_dup(const struct stack_st_PKCS7_RECIP_INFO *sk) { return (struct stack_st_PKCS7_RECIP_INFO *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_PKCS7_RECIP_INFO *sk_PKCS7_RECIP_INFO_deep_copy(const struct stack_st_PKCS7_RECIP_INFO *sk, sk_PKCS7_RECIP_INFO_copyfunc copyfunc, sk_PKCS7_RECIP_INFO_freefunc freefunc) { return (struct stack_st_PKCS7_RECIP_INFO *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_PKCS7_RECIP_INFO_compfunc sk_PKCS7_RECIP_INFO_set_cmp_func(struct stack_st_PKCS7_RECIP_INFO *sk, sk_PKCS7_RECIP_INFO_compfunc compare) { return (sk_PKCS7_RECIP_INFO_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct pkcs7_signed_st {
    ASN1_INTEGER *version;
    struct stack_st_X509_ALGOR *md_algs;
    struct stack_st_X509 *cert;
    struct stack_st_X509_CRL *crl;
    struct stack_st_PKCS7_SIGNER_INFO *signer_info;
    struct pkcs7_st *contents;
} PKCS7_SIGNED;
typedef struct pkcs7_enc_content_st {
    ASN1_OBJECT *content_type;
    X509_ALGOR *algorithm;
    ASN1_OCTET_STRING *enc_data;
    const EVP_CIPHER *cipher;
} PKCS7_ENC_CONTENT;
typedef struct pkcs7_enveloped_st {
    ASN1_INTEGER *version;
    struct stack_st_PKCS7_RECIP_INFO *recipientinfo;
    PKCS7_ENC_CONTENT *enc_data;
} PKCS7_ENVELOPE;
typedef struct pkcs7_signedandenveloped_st {
    ASN1_INTEGER *version;
    struct stack_st_X509_ALGOR *md_algs;
    struct stack_st_X509 *cert;
    struct stack_st_X509_CRL *crl;
    struct stack_st_PKCS7_SIGNER_INFO *signer_info;
    PKCS7_ENC_CONTENT *enc_data;
    struct stack_st_PKCS7_RECIP_INFO *recipientinfo;
} PKCS7_SIGN_ENVELOPE;
typedef struct pkcs7_digest_st {
    ASN1_INTEGER *version;
    X509_ALGOR *md;
    struct pkcs7_st *contents;
    ASN1_OCTET_STRING *digest;
} PKCS7_DIGEST;
typedef struct pkcs7_encrypted_st {
    ASN1_INTEGER *version;
    PKCS7_ENC_CONTENT *enc_data;
} PKCS7_ENCRYPT;
typedef struct pkcs7_st {
    unsigned char *asn1;
    long length;
enum {
	PKCS7_S_HEADER       = 0,
	PKCS7_S_BODY         = 1,
	PKCS7_S_TAIL         = 2,
};
    int state;
    int detached;
    ASN1_OBJECT *type;
    union {
        char *ptr;
        ASN1_OCTET_STRING *data;
        PKCS7_SIGNED *sign;
        PKCS7_ENVELOPE *enveloped;
        PKCS7_SIGN_ENVELOPE *signed_and_enveloped;
        PKCS7_DIGEST *digest;
        PKCS7_ENCRYPT *encrypted;
        ASN1_TYPE *other;
    } d;
} PKCS7;
struct stack_st_PKCS7; typedef int (*sk_PKCS7_compfunc)(const PKCS7 * const *a, const PKCS7 *const *b); typedef void (*sk_PKCS7_freefunc)(PKCS7 *a); typedef PKCS7 * (*sk_PKCS7_copyfunc)(const PKCS7 *a); static __attribute__((unused)) inline int sk_PKCS7_num(const struct stack_st_PKCS7 *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7 *sk_PKCS7_value(const struct stack_st_PKCS7 *sk, int idx) { return (PKCS7 *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_PKCS7 *sk_PKCS7_new(sk_PKCS7_compfunc compare) { return (struct stack_st_PKCS7 *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_PKCS7 *sk_PKCS7_new_null(void) { return (struct stack_st_PKCS7 *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_PKCS7 *sk_PKCS7_new_reserve(sk_PKCS7_compfunc compare, int n) { return (struct stack_st_PKCS7 *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_PKCS7_reserve(struct stack_st_PKCS7 *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_PKCS7_free(struct stack_st_PKCS7 *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_PKCS7_zero(struct stack_st_PKCS7 *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7 *sk_PKCS7_delete(struct stack_st_PKCS7 *sk, int i) { return (PKCS7 *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline PKCS7 *sk_PKCS7_delete_ptr(struct stack_st_PKCS7 *sk, PKCS7 *ptr) { return (PKCS7 *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_push(struct stack_st_PKCS7 *sk, PKCS7 *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_unshift(struct stack_st_PKCS7 *sk, PKCS7 *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline PKCS7 *sk_PKCS7_pop(struct stack_st_PKCS7 *sk) { return (PKCS7 *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline PKCS7 *sk_PKCS7_shift(struct stack_st_PKCS7 *sk) { return (PKCS7 *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_PKCS7_pop_free(struct stack_st_PKCS7 *sk, sk_PKCS7_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_PKCS7_insert(struct stack_st_PKCS7 *sk, PKCS7 *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline PKCS7 *sk_PKCS7_set(struct stack_st_PKCS7 *sk, int idx, PKCS7 *ptr) { return (PKCS7 *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_find(struct stack_st_PKCS7 *sk, PKCS7 *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_PKCS7_find_ex(struct stack_st_PKCS7 *sk, PKCS7 *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_PKCS7_sort(struct stack_st_PKCS7 *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_PKCS7_is_sorted(const struct stack_st_PKCS7 *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_PKCS7 * sk_PKCS7_dup(const struct stack_st_PKCS7 *sk) { return (struct stack_st_PKCS7 *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_PKCS7 *sk_PKCS7_deep_copy(const struct stack_st_PKCS7 *sk, sk_PKCS7_copyfunc copyfunc, sk_PKCS7_freefunc freefunc) { return (struct stack_st_PKCS7 *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_PKCS7_compfunc sk_PKCS7_set_cmp_func(struct stack_st_PKCS7 *sk, sk_PKCS7_compfunc compare) { return (sk_PKCS7_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum {
	PKCS7_OP_SET_DETACHED_SIGNATURE = 1,
	PKCS7_OP_GET_DETACHED_SIGNATURE = 2,
};
#define PKCS7_get_signed_attributes(si) ((si)->auth_attr)
#define PKCS7_get_attributes(si) ((si)->unauth_attr)
#define PKCS7_type_is_signed(a) (OBJ_obj2nid((a)->type) == NID_pkcs7_signed)
#define PKCS7_type_is_encrypted(a) (OBJ_obj2nid((a)->type) == NID_pkcs7_encrypted)
#define PKCS7_type_is_enveloped(a) (OBJ_obj2nid((a)->type) == NID_pkcs7_enveloped)
#define PKCS7_type_is_signedAndEnveloped(a) (OBJ_obj2nid((a)->type) == NID_pkcs7_signedAndEnveloped)
#define PKCS7_type_is_data(a) (OBJ_obj2nid((a)->type) == NID_pkcs7_data)
#define PKCS7_type_is_digest(a) (OBJ_obj2nid((a)->type) == NID_pkcs7_digest)
#define PKCS7_set_detached(p,v) PKCS7_ctrl(p,PKCS7_OP_SET_DETACHED_SIGNATURE,v,NULL)
#define PKCS7_get_detached(p) PKCS7_ctrl(p,PKCS7_OP_GET_DETACHED_SIGNATURE,0,NULL)
#define PKCS7_is_detached(p7) (PKCS7_type_is_signed(p7) && PKCS7_get_detached(p7))
enum {
	PKCS7_TEXT           = 0x1,
	PKCS7_NOCERTS        = 0x2,
	PKCS7_NOSIGS         = 0x4,
	PKCS7_NOCHAIN        = 0x8,
	PKCS7_NOINTERN       = 0x10,
	PKCS7_NOVERIFY       = 0x20,
	PKCS7_DETACHED       = 0x40,
	PKCS7_BINARY         = 0x80,
	PKCS7_NOATTR         = 0x100,
	PKCS7_NOSMIMECAP     = 0x200,
	PKCS7_NOOLDMIMETYPE  = 0x400,
	PKCS7_CRLFEOL        = 0x800,
	PKCS7_STREAM         = 0x1000,
	PKCS7_NOCRL          = 0x2000,
	PKCS7_PARTIAL        = 0x4000,
	PKCS7_REUSE_DIGEST   = 0x8000,
	PKCS7_NO_DUAL_CONTENT = 0x10000,
	SMIME_TEXT           = PKCS7_TEXT,
	SMIME_NOCERTS        = PKCS7_NOCERTS,
	SMIME_NOSIGS         = PKCS7_NOSIGS,
	SMIME_NOCHAIN        = PKCS7_NOCHAIN,
	SMIME_NOINTERN       = PKCS7_NOINTERN,
	SMIME_NOVERIFY       = PKCS7_NOVERIFY,
	SMIME_DETACHED       = PKCS7_DETACHED,
	SMIME_BINARY         = PKCS7_BINARY,
	SMIME_NOATTR         = PKCS7_NOATTR,
	SMIME_ASCIICRLF      = 0x80000,
};
PKCS7_ISSUER_AND_SERIAL *PKCS7_ISSUER_AND_SERIAL_new(void); void PKCS7_ISSUER_AND_SERIAL_free(PKCS7_ISSUER_AND_SERIAL *a); PKCS7_ISSUER_AND_SERIAL *d2i_PKCS7_ISSUER_AND_SERIAL(PKCS7_ISSUER_AND_SERIAL **a, const unsigned char **in, long len); int i2d_PKCS7_ISSUER_AND_SERIAL(PKCS7_ISSUER_AND_SERIAL *a, unsigned char **out); const ASN1_ITEM * PKCS7_ISSUER_AND_SERIAL_it(void);
int PKCS7_ISSUER_AND_SERIAL_digest(PKCS7_ISSUER_AND_SERIAL *data,
                                   const EVP_MD *type, unsigned char *md,
                                   unsigned int *len);
PKCS7 *d2i_PKCS7_fp(FILE *fp, PKCS7 **p7);
int i2d_PKCS7_fp(FILE *fp, PKCS7 *p7);
PKCS7 *PKCS7_dup(PKCS7 *p7);
PKCS7 *d2i_PKCS7_bio(BIO *bp, PKCS7 **p7);
int i2d_PKCS7_bio(BIO *bp, PKCS7 *p7);
int i2d_PKCS7_bio_stream(BIO *out, PKCS7 *p7, BIO *in, int flags);
int PEM_write_bio_PKCS7_stream(BIO *out, PKCS7 *p7, BIO *in, int flags);
PKCS7_SIGNER_INFO *PKCS7_SIGNER_INFO_new(void); void PKCS7_SIGNER_INFO_free(PKCS7_SIGNER_INFO *a); PKCS7_SIGNER_INFO *d2i_PKCS7_SIGNER_INFO(PKCS7_SIGNER_INFO **a, const unsigned char **in, long len); int i2d_PKCS7_SIGNER_INFO(PKCS7_SIGNER_INFO *a, unsigned char **out); const ASN1_ITEM * PKCS7_SIGNER_INFO_it(void);
PKCS7_RECIP_INFO *PKCS7_RECIP_INFO_new(void); void PKCS7_RECIP_INFO_free(PKCS7_RECIP_INFO *a); PKCS7_RECIP_INFO *d2i_PKCS7_RECIP_INFO(PKCS7_RECIP_INFO **a, const unsigned char **in, long len); int i2d_PKCS7_RECIP_INFO(PKCS7_RECIP_INFO *a, unsigned char **out); const ASN1_ITEM * PKCS7_RECIP_INFO_it(void);
PKCS7_SIGNED *PKCS7_SIGNED_new(void); void PKCS7_SIGNED_free(PKCS7_SIGNED *a); PKCS7_SIGNED *d2i_PKCS7_SIGNED(PKCS7_SIGNED **a, const unsigned char **in, long len); int i2d_PKCS7_SIGNED(PKCS7_SIGNED *a, unsigned char **out); const ASN1_ITEM * PKCS7_SIGNED_it(void);
PKCS7_ENC_CONTENT *PKCS7_ENC_CONTENT_new(void); void PKCS7_ENC_CONTENT_free(PKCS7_ENC_CONTENT *a); PKCS7_ENC_CONTENT *d2i_PKCS7_ENC_CONTENT(PKCS7_ENC_CONTENT **a, const unsigned char **in, long len); int i2d_PKCS7_ENC_CONTENT(PKCS7_ENC_CONTENT *a, unsigned char **out); const ASN1_ITEM * PKCS7_ENC_CONTENT_it(void);
PKCS7_ENVELOPE *PKCS7_ENVELOPE_new(void); void PKCS7_ENVELOPE_free(PKCS7_ENVELOPE *a); PKCS7_ENVELOPE *d2i_PKCS7_ENVELOPE(PKCS7_ENVELOPE **a, const unsigned char **in, long len); int i2d_PKCS7_ENVELOPE(PKCS7_ENVELOPE *a, unsigned char **out); const ASN1_ITEM * PKCS7_ENVELOPE_it(void);
PKCS7_SIGN_ENVELOPE *PKCS7_SIGN_ENVELOPE_new(void); void PKCS7_SIGN_ENVELOPE_free(PKCS7_SIGN_ENVELOPE *a); PKCS7_SIGN_ENVELOPE *d2i_PKCS7_SIGN_ENVELOPE(PKCS7_SIGN_ENVELOPE **a, const unsigned char **in, long len); int i2d_PKCS7_SIGN_ENVELOPE(PKCS7_SIGN_ENVELOPE *a, unsigned char **out); const ASN1_ITEM * PKCS7_SIGN_ENVELOPE_it(void);
PKCS7_DIGEST *PKCS7_DIGEST_new(void); void PKCS7_DIGEST_free(PKCS7_DIGEST *a); PKCS7_DIGEST *d2i_PKCS7_DIGEST(PKCS7_DIGEST **a, const unsigned char **in, long len); int i2d_PKCS7_DIGEST(PKCS7_DIGEST *a, unsigned char **out); const ASN1_ITEM * PKCS7_DIGEST_it(void);
PKCS7_ENCRYPT *PKCS7_ENCRYPT_new(void); void PKCS7_ENCRYPT_free(PKCS7_ENCRYPT *a); PKCS7_ENCRYPT *d2i_PKCS7_ENCRYPT(PKCS7_ENCRYPT **a, const unsigned char **in, long len); int i2d_PKCS7_ENCRYPT(PKCS7_ENCRYPT *a, unsigned char **out); const ASN1_ITEM * PKCS7_ENCRYPT_it(void);
PKCS7 *PKCS7_new(void); void PKCS7_free(PKCS7 *a); PKCS7 *d2i_PKCS7(PKCS7 **a, const unsigned char **in, long len); int i2d_PKCS7(PKCS7 *a, unsigned char **out); const ASN1_ITEM * PKCS7_it(void);
const ASN1_ITEM * PKCS7_ATTR_SIGN_it(void);
const ASN1_ITEM * PKCS7_ATTR_VERIFY_it(void);
int i2d_PKCS7_NDEF(PKCS7 *a, unsigned char **out);
int PKCS7_print_ctx(BIO *out, PKCS7 *x, int indent, const ASN1_PCTX *pctx);
long PKCS7_ctrl(PKCS7 *p7, int cmd, long larg, char *parg);
int PKCS7_set_type(PKCS7 *p7, int type);
int PKCS7_set0_type_other(PKCS7 *p7, int type, ASN1_TYPE *other);
int PKCS7_set_content(PKCS7 *p7, PKCS7 *p7_data);
int PKCS7_SIGNER_INFO_set(PKCS7_SIGNER_INFO *p7i, X509 *x509, EVP_PKEY *pkey,
                          const EVP_MD *dgst);
int PKCS7_SIGNER_INFO_sign(PKCS7_SIGNER_INFO *si);
int PKCS7_add_signer(PKCS7 *p7, PKCS7_SIGNER_INFO *p7i);
int PKCS7_add_certificate(PKCS7 *p7, X509 *x509);
int PKCS7_add_crl(PKCS7 *p7, X509_CRL *x509);
int PKCS7_content_new(PKCS7 *p7, int nid);
int PKCS7_dataVerify(X509_STORE *cert_store, X509_STORE_CTX *ctx,
                     BIO *bio, PKCS7 *p7, PKCS7_SIGNER_INFO *si);
int PKCS7_signatureVerify(BIO *bio, PKCS7 *p7, PKCS7_SIGNER_INFO *si,
                          X509 *x509);
BIO *PKCS7_dataInit(PKCS7 *p7, BIO *bio);
int PKCS7_dataFinal(PKCS7 *p7, BIO *bio);
BIO *PKCS7_dataDecode(PKCS7 *p7, EVP_PKEY *pkey, BIO *in_bio, X509 *pcert);
PKCS7_SIGNER_INFO *PKCS7_add_signature(PKCS7 *p7, X509 *x509,
                                       EVP_PKEY *pkey, const EVP_MD *dgst);
X509 *PKCS7_cert_from_signer_info(PKCS7 *p7, PKCS7_SIGNER_INFO *si);
int PKCS7_set_digest(PKCS7 *p7, const EVP_MD *md);
struct stack_st_PKCS7_SIGNER_INFO *PKCS7_get_signer_info(PKCS7 *p7);
PKCS7_RECIP_INFO *PKCS7_add_recipient(PKCS7 *p7, X509 *x509);
void PKCS7_SIGNER_INFO_get0_algs(PKCS7_SIGNER_INFO *si, EVP_PKEY **pk,
                                 X509_ALGOR **pdig, X509_ALGOR **psig);
void PKCS7_RECIP_INFO_get0_alg(PKCS7_RECIP_INFO *ri, X509_ALGOR **penc);
int PKCS7_add_recipient_info(PKCS7 *p7, PKCS7_RECIP_INFO *ri);
int PKCS7_RECIP_INFO_set(PKCS7_RECIP_INFO *p7i, X509 *x509);
int PKCS7_set_cipher(PKCS7 *p7, const EVP_CIPHER *cipher);
int PKCS7_stream(unsigned char ***boundary, PKCS7 *p7);
PKCS7_ISSUER_AND_SERIAL *PKCS7_get_issuer_and_serial(PKCS7 *p7, int idx);
ASN1_OCTET_STRING *PKCS7_digest_from_attributes(struct stack_st_X509_ATTRIBUTE *sk);
int PKCS7_add_signed_attribute(PKCS7_SIGNER_INFO *p7si, int nid, int type,
                               void *data);
int PKCS7_add_attribute(PKCS7_SIGNER_INFO *p7si, int nid, int atrtype,
                        void *value);
ASN1_TYPE *PKCS7_get_attribute(PKCS7_SIGNER_INFO *si, int nid);
ASN1_TYPE *PKCS7_get_signed_attribute(PKCS7_SIGNER_INFO *si, int nid);
int PKCS7_set_signed_attributes(PKCS7_SIGNER_INFO *p7si,
                                struct stack_st_X509_ATTRIBUTE *sk);
int PKCS7_set_attributes(PKCS7_SIGNER_INFO *p7si,
                         struct stack_st_X509_ATTRIBUTE *sk);
PKCS7 *PKCS7_sign(X509 *signcert, EVP_PKEY *pkey, struct stack_st_X509 *certs,
                  BIO *data, int flags);
PKCS7_SIGNER_INFO *PKCS7_sign_add_signer(PKCS7 *p7,
                                         X509 *signcert, EVP_PKEY *pkey,
                                         const EVP_MD *md, int flags);
int PKCS7_final(PKCS7 *p7, BIO *data, int flags);
int PKCS7_verify(PKCS7 *p7, struct stack_st_X509 *certs, X509_STORE *store,
                 BIO *indata, BIO *out, int flags);
struct stack_st_X509 *PKCS7_get0_signers(PKCS7 *p7, struct stack_st_X509 *certs,
                                   int flags);
PKCS7 *PKCS7_encrypt(struct stack_st_X509 *certs, BIO *in, const EVP_CIPHER *cipher,
                     int flags);
int PKCS7_decrypt(PKCS7 *p7, EVP_PKEY *pkey, X509 *cert, BIO *data,
                  int flags);
int PKCS7_add_attrib_smimecap(PKCS7_SIGNER_INFO *si,
                              struct stack_st_X509_ALGOR *cap);
struct stack_st_X509_ALGOR *PKCS7_get_smimecap(PKCS7_SIGNER_INFO *si);
int PKCS7_simple_smimecap(struct stack_st_X509_ALGOR *sk, int nid, int arg);
int PKCS7_add_attrib_content_type(PKCS7_SIGNER_INFO *si, ASN1_OBJECT *coid);
int PKCS7_add0_attrib_signing_time(PKCS7_SIGNER_INFO *si, ASN1_TIME *t);
int PKCS7_add1_attrib_digest(PKCS7_SIGNER_INFO *si,
                             const unsigned char *md, int mdlen);
int SMIME_write_PKCS7(BIO *bio, PKCS7 *p7, BIO *data, int flags);
PKCS7 *SMIME_read_PKCS7(BIO *bio, BIO **bcont);
BIO *BIO_new_PKCS7(BIO *out, PKCS7 *p7);

// csrc/openssl/src/include/openssl/pkcs7err.h
int ERR_load_PKCS7_strings(void);
enum {
	PKCS7_F_DO_PKCS7_SIGNED_ATTRIB = 136,
	PKCS7_F_PKCS7_ADD0_ATTRIB_SIGNING_TIME = 135,
	PKCS7_F_PKCS7_ADD_ATTRIB_SMIMECAP = 118,
	PKCS7_F_PKCS7_ADD_CERTIFICATE = 100,
	PKCS7_F_PKCS7_ADD_CRL = 101,
	PKCS7_F_PKCS7_ADD_RECIPIENT_INFO = 102,
	PKCS7_F_PKCS7_ADD_SIGNATURE = 131,
	PKCS7_F_PKCS7_ADD_SIGNER = 103,
	PKCS7_F_PKCS7_BIO_ADD_DIGEST = 125,
	PKCS7_F_PKCS7_COPY_EXISTING_DIGEST = 138,
	PKCS7_F_PKCS7_CTRL   = 104,
	PKCS7_F_PKCS7_DATADECODE = 112,
	PKCS7_F_PKCS7_DATAFINAL = 128,
	PKCS7_F_PKCS7_DATAINIT = 105,
	PKCS7_F_PKCS7_DATAVERIFY = 107,
	PKCS7_F_PKCS7_DECRYPT = 114,
	PKCS7_F_PKCS7_DECRYPT_RINFO = 133,
	PKCS7_F_PKCS7_ENCODE_RINFO = 132,
	PKCS7_F_PKCS7_ENCRYPT = 115,
	PKCS7_F_PKCS7_FINAL  = 134,
	PKCS7_F_PKCS7_FIND_DIGEST = 127,
	PKCS7_F_PKCS7_GET0_SIGNERS = 124,
	PKCS7_F_PKCS7_RECIP_INFO_SET = 130,
	PKCS7_F_PKCS7_SET_CIPHER = 108,
	PKCS7_F_PKCS7_SET_CONTENT = 109,
	PKCS7_F_PKCS7_SET_DIGEST = 126,
	PKCS7_F_PKCS7_SET_TYPE = 110,
	PKCS7_F_PKCS7_SIGN   = 116,
	PKCS7_F_PKCS7_SIGNATUREVERIFY = 113,
	PKCS7_F_PKCS7_SIGNER_INFO_SET = 129,
	PKCS7_F_PKCS7_SIGNER_INFO_SIGN = 139,
	PKCS7_F_PKCS7_SIGN_ADD_SIGNER = 137,
	PKCS7_F_PKCS7_SIMPLE_SMIMECAP = 119,
	PKCS7_F_PKCS7_VERIFY = 117,
	PKCS7_R_CERTIFICATE_VERIFY_ERROR = 117,
	PKCS7_R_CIPHER_HAS_NO_OBJECT_IDENTIFIER = 144,
	PKCS7_R_CIPHER_NOT_INITIALIZED = 116,
	PKCS7_R_CONTENT_AND_DATA_PRESENT = 118,
	PKCS7_R_CTRL_ERROR   = 152,
	PKCS7_R_DECRYPT_ERROR = 119,
	PKCS7_R_DIGEST_FAILURE = 101,
	PKCS7_R_ENCRYPTION_CTRL_FAILURE = 149,
	PKCS7_R_ENCRYPTION_NOT_SUPPORTED_FOR_THIS_KEY_TYPE = 150,
	PKCS7_R_ERROR_ADDING_RECIPIENT = 120,
	PKCS7_R_ERROR_SETTING_CIPHER = 121,
	PKCS7_R_INVALID_NULL_POINTER = 143,
	PKCS7_R_INVALID_SIGNED_DATA_TYPE = 155,
	PKCS7_R_NO_CONTENT   = 122,
	PKCS7_R_NO_DEFAULT_DIGEST = 151,
	PKCS7_R_NO_MATCHING_DIGEST_TYPE_FOUND = 154,
	PKCS7_R_NO_RECIPIENT_MATCHES_CERTIFICATE = 115,
	PKCS7_R_NO_SIGNATURES_ON_DATA = 123,
	PKCS7_R_NO_SIGNERS   = 142,
	PKCS7_R_OPERATION_NOT_SUPPORTED_ON_THIS_TYPE = 104,
	PKCS7_R_PKCS7_ADD_SIGNATURE_ERROR = 124,
	PKCS7_R_PKCS7_ADD_SIGNER_ERROR = 153,
	PKCS7_R_PKCS7_DATASIGN = 145,
	PKCS7_R_PRIVATE_KEY_DOES_NOT_MATCH_CERTIFICATE = 127,
	PKCS7_R_SIGNATURE_FAILURE = 105,
	PKCS7_R_SIGNER_CERTIFICATE_NOT_FOUND = 128,
	PKCS7_R_SIGNING_CTRL_FAILURE = 147,
	PKCS7_R_SIGNING_NOT_SUPPORTED_FOR_THIS_KEY_TYPE = 148,
	PKCS7_R_SMIME_TEXT_ERROR = 129,
	PKCS7_R_UNABLE_TO_FIND_CERTIFICATE = 106,
	PKCS7_R_UNABLE_TO_FIND_MEM_BIO = 107,
	PKCS7_R_UNABLE_TO_FIND_MESSAGE_DIGEST = 108,
	PKCS7_R_UNKNOWN_DIGEST_TYPE = 109,
	PKCS7_R_UNKNOWN_OPERATION = 110,
	PKCS7_R_UNSUPPORTED_CIPHER_TYPE = 111,
	PKCS7_R_UNSUPPORTED_CONTENT_TYPE = 112,
	PKCS7_R_WRONG_CONTENT_TYPE = 113,
	PKCS7_R_WRONG_PKCS7_TYPE = 114,
};
]]
