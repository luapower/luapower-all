// csrc/openssl/src/include/openssl/asn1.h
enum {
	V_ASN1_UNIVERSAL     = 0x00,
	V_ASN1_APPLICATION   = 0x40,
	V_ASN1_CONTEXT_SPECIFIC = 0x80,
	V_ASN1_PRIVATE       = 0xc0,
	V_ASN1_CONSTRUCTED   = 0x20,
	V_ASN1_PRIMITIVE_TAG = 0x1f,
	V_ASN1_PRIMATIVE_TAG = V_ASN1_PRIMITIVE_TAG,
	V_ASN1_APP_CHOOSE    = -2,
	V_ASN1_OTHER         = -3,
	V_ASN1_ANY           = -4,
	V_ASN1_UNDEF         = -1,
	V_ASN1_EOC           = 0,
	V_ASN1_BOOLEAN       = 1,
	V_ASN1_INTEGER       = 2,
	V_ASN1_BIT_STRING    = 3,
	V_ASN1_OCTET_STRING  = 4,
	V_ASN1_NULL          = 5,
	V_ASN1_OBJECT        = 6,
	V_ASN1_OBJECT_DESCRIPTOR = 7,
	V_ASN1_EXTERNAL      = 8,
	V_ASN1_REAL          = 9,
	V_ASN1_ENUMERATED    = 10,
	V_ASN1_UTF8STRING    = 12,
	V_ASN1_SEQUENCE      = 16,
	V_ASN1_SET           = 17,
	V_ASN1_NUMERICSTRING = 18,
	V_ASN1_PRINTABLESTRING = 19,
	V_ASN1_T61STRING     = 20,
	V_ASN1_TELETEXSTRING = 20,
	V_ASN1_VIDEOTEXSTRING = 21,
	V_ASN1_IA5STRING     = 22,
	V_ASN1_UTCTIME       = 23,
	V_ASN1_GENERALIZEDTIME = 24,
	V_ASN1_GRAPHICSTRING = 25,
	V_ASN1_ISO64STRING   = 26,
	V_ASN1_VISIBLESTRING = 26,
	V_ASN1_GENERALSTRING = 27,
	V_ASN1_UNIVERSALSTRING = 28,
	V_ASN1_BMPSTRING     = 30,
	V_ASN1_NEG           = 0x100,
	V_ASN1_NEG_INTEGER   = (2 | V_ASN1_NEG),
	V_ASN1_NEG_ENUMERATED = (10 | V_ASN1_NEG),
	B_ASN1_NUMERICSTRING = 0x0001,
	B_ASN1_PRINTABLESTRING = 0x0002,
	B_ASN1_T61STRING     = 0x0004,
	B_ASN1_TELETEXSTRING = 0x0004,
	B_ASN1_VIDEOTEXSTRING = 0x0008,
	B_ASN1_IA5STRING     = 0x0010,
	B_ASN1_GRAPHICSTRING = 0x0020,
	B_ASN1_ISO64STRING   = 0x0040,
	B_ASN1_VISIBLESTRING = 0x0040,
	B_ASN1_GENERALSTRING = 0x0080,
	B_ASN1_UNIVERSALSTRING = 0x0100,
	B_ASN1_OCTET_STRING  = 0x0200,
	B_ASN1_BIT_STRING    = 0x0400,
	B_ASN1_BMPSTRING     = 0x0800,
	B_ASN1_UNKNOWN       = 0x1000,
	B_ASN1_UTF8STRING    = 0x2000,
	B_ASN1_UTCTIME       = 0x4000,
	B_ASN1_GENERALIZEDTIME = 0x8000,
	B_ASN1_SEQUENCE      = 0x10000,
	MBSTRING_FLAG        = 0x1000,
	MBSTRING_UTF8        = (MBSTRING_FLAG),
	MBSTRING_ASC         = (MBSTRING_FLAG|1),
	MBSTRING_BMP         = (MBSTRING_FLAG|2),
	MBSTRING_UNIV        = (MBSTRING_FLAG|4),
	SMIME_OLDMIME        = 0x400,
	SMIME_CRLFEOL        = 0x800,
	SMIME_STREAM         = 0x1000,
};
    struct X509_algor_st;
struct stack_st_X509_ALGOR; typedef int (*sk_X509_ALGOR_compfunc)(const X509_ALGOR * const *a, const X509_ALGOR *const *b); typedef void (*sk_X509_ALGOR_freefunc)(X509_ALGOR *a); typedef X509_ALGOR * (*sk_X509_ALGOR_copyfunc)(const X509_ALGOR *a); static __attribute__((unused)) inline int sk_X509_ALGOR_num(const struct stack_st_X509_ALGOR *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_ALGOR *sk_X509_ALGOR_value(const struct stack_st_X509_ALGOR *sk, int idx) { return (X509_ALGOR *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_X509_ALGOR *sk_X509_ALGOR_new(sk_X509_ALGOR_compfunc compare) { return (struct stack_st_X509_ALGOR *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_X509_ALGOR *sk_X509_ALGOR_new_null(void) { return (struct stack_st_X509_ALGOR *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_X509_ALGOR *sk_X509_ALGOR_new_reserve(sk_X509_ALGOR_compfunc compare, int n) { return (struct stack_st_X509_ALGOR *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_X509_ALGOR_reserve(struct stack_st_X509_ALGOR *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_X509_ALGOR_free(struct stack_st_X509_ALGOR *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_ALGOR_zero(struct stack_st_X509_ALGOR *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_ALGOR *sk_X509_ALGOR_delete(struct stack_st_X509_ALGOR *sk, int i) { return (X509_ALGOR *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline X509_ALGOR *sk_X509_ALGOR_delete_ptr(struct stack_st_X509_ALGOR *sk, X509_ALGOR *ptr) { return (X509_ALGOR *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ALGOR_push(struct stack_st_X509_ALGOR *sk, X509_ALGOR *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ALGOR_unshift(struct stack_st_X509_ALGOR *sk, X509_ALGOR *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline X509_ALGOR *sk_X509_ALGOR_pop(struct stack_st_X509_ALGOR *sk) { return (X509_ALGOR *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline X509_ALGOR *sk_X509_ALGOR_shift(struct stack_st_X509_ALGOR *sk) { return (X509_ALGOR *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_X509_ALGOR_pop_free(struct stack_st_X509_ALGOR *sk, sk_X509_ALGOR_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_X509_ALGOR_insert(struct stack_st_X509_ALGOR *sk, X509_ALGOR *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline X509_ALGOR *sk_X509_ALGOR_set(struct stack_st_X509_ALGOR *sk, int idx, X509_ALGOR *ptr) { return (X509_ALGOR *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ALGOR_find(struct stack_st_X509_ALGOR *sk, X509_ALGOR *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_X509_ALGOR_find_ex(struct stack_st_X509_ALGOR *sk, X509_ALGOR *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_X509_ALGOR_sort(struct stack_st_X509_ALGOR *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_X509_ALGOR_is_sorted(const struct stack_st_X509_ALGOR *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_ALGOR * sk_X509_ALGOR_dup(const struct stack_st_X509_ALGOR *sk) { return (struct stack_st_X509_ALGOR *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_X509_ALGOR *sk_X509_ALGOR_deep_copy(const struct stack_st_X509_ALGOR *sk, sk_X509_ALGOR_copyfunc copyfunc, sk_X509_ALGOR_freefunc freefunc) { return (struct stack_st_X509_ALGOR *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_X509_ALGOR_compfunc sk_X509_ALGOR_set_cmp_func(struct stack_st_X509_ALGOR *sk, sk_X509_ALGOR_compfunc compare) { return (sk_X509_ALGOR_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum {
	ASN1_STRING_FLAG_BITS_LEFT = 0x08,
	ASN1_STRING_FLAG_NDEF = 0x010,
	ASN1_STRING_FLAG_CONT = 0x020,
	ASN1_STRING_FLAG_MSTRING = 0x040,
	ASN1_STRING_FLAG_EMBED = 0x080,
	ASN1_STRING_FLAG_X509_TIME = 0x100,
};
struct asn1_string_st {
    int length;
    int type;
    unsigned char *data;
    long flags;
};
typedef struct ASN1_ENCODING_st {
    unsigned char *enc;
    long len;
    int modified;
} ASN1_ENCODING;
enum {
	ASN1_LONG_UNDEF      = 0x7fffffffL,
	STABLE_FLAGS_MALLOC  = 0x01,
	STABLE_FLAGS_CLEAR   = STABLE_FLAGS_MALLOC,
	STABLE_NO_MASK       = 0x02,
	DIRSTRING_TYPE       = (B_ASN1_PRINTABLESTRING|B_ASN1_T61STRING|B_ASN1_BMPSTRING|B_ASN1_UTF8STRING),
	PKCS9STRING_TYPE     = (DIRSTRING_TYPE|B_ASN1_IA5STRING),
};
typedef struct asn1_string_table_st {
    int nid;
    long minsize;
    long maxsize;
    unsigned long mask;
    unsigned long flags;
} ASN1_STRING_TABLE;
struct stack_st_ASN1_STRING_TABLE; typedef int (*sk_ASN1_STRING_TABLE_compfunc)(const ASN1_STRING_TABLE * const *a, const ASN1_STRING_TABLE *const *b); typedef void (*sk_ASN1_STRING_TABLE_freefunc)(ASN1_STRING_TABLE *a); typedef ASN1_STRING_TABLE * (*sk_ASN1_STRING_TABLE_copyfunc)(const ASN1_STRING_TABLE *a); static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_num(const struct stack_st_ASN1_STRING_TABLE *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_value(const struct stack_st_ASN1_STRING_TABLE *sk, int idx) { return (ASN1_STRING_TABLE *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_new(sk_ASN1_STRING_TABLE_compfunc compare) { return (struct stack_st_ASN1_STRING_TABLE *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_new_null(void) { return (struct stack_st_ASN1_STRING_TABLE *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_new_reserve(sk_ASN1_STRING_TABLE_compfunc compare, int n) { return (struct stack_st_ASN1_STRING_TABLE *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_reserve(struct stack_st_ASN1_STRING_TABLE *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_ASN1_STRING_TABLE_free(struct stack_st_ASN1_STRING_TABLE *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_STRING_TABLE_zero(struct stack_st_ASN1_STRING_TABLE *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_delete(struct stack_st_ASN1_STRING_TABLE *sk, int i) { return (ASN1_STRING_TABLE *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_delete_ptr(struct stack_st_ASN1_STRING_TABLE *sk, ASN1_STRING_TABLE *ptr) { return (ASN1_STRING_TABLE *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_push(struct stack_st_ASN1_STRING_TABLE *sk, ASN1_STRING_TABLE *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_unshift(struct stack_st_ASN1_STRING_TABLE *sk, ASN1_STRING_TABLE *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_pop(struct stack_st_ASN1_STRING_TABLE *sk) { return (ASN1_STRING_TABLE *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_shift(struct stack_st_ASN1_STRING_TABLE *sk) { return (ASN1_STRING_TABLE *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_STRING_TABLE_pop_free(struct stack_st_ASN1_STRING_TABLE *sk, sk_ASN1_STRING_TABLE_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_insert(struct stack_st_ASN1_STRING_TABLE *sk, ASN1_STRING_TABLE *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_set(struct stack_st_ASN1_STRING_TABLE *sk, int idx, ASN1_STRING_TABLE *ptr) { return (ASN1_STRING_TABLE *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_find(struct stack_st_ASN1_STRING_TABLE *sk, ASN1_STRING_TABLE *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_find_ex(struct stack_st_ASN1_STRING_TABLE *sk, ASN1_STRING_TABLE *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_ASN1_STRING_TABLE_sort(struct stack_st_ASN1_STRING_TABLE *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_ASN1_STRING_TABLE_is_sorted(const struct stack_st_ASN1_STRING_TABLE *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_STRING_TABLE * sk_ASN1_STRING_TABLE_dup(const struct stack_st_ASN1_STRING_TABLE *sk) { return (struct stack_st_ASN1_STRING_TABLE *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_STRING_TABLE *sk_ASN1_STRING_TABLE_deep_copy(const struct stack_st_ASN1_STRING_TABLE *sk, sk_ASN1_STRING_TABLE_copyfunc copyfunc, sk_ASN1_STRING_TABLE_freefunc freefunc) { return (struct stack_st_ASN1_STRING_TABLE *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_ASN1_STRING_TABLE_compfunc sk_ASN1_STRING_TABLE_set_cmp_func(struct stack_st_ASN1_STRING_TABLE *sk, sk_ASN1_STRING_TABLE_compfunc compare) { return (sk_ASN1_STRING_TABLE_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum {
	ub_name              = 32768,
	ub_common_name       = 64,
	ub_locality_name     = 128,
	ub_state_name        = 128,
	ub_organization_name = 64,
	ub_organization_unit_name = 64,
	ub_title             = 64,
	ub_email_address     = 128,
};
typedef struct ASN1_TEMPLATE_st ASN1_TEMPLATE;
typedef struct ASN1_TLC_st ASN1_TLC;
typedef struct ASN1_VALUE_st ASN1_VALUE;
#define DECLARE_ASN1_FUNCTIONS(type) DECLARE_ASN1_FUNCTIONS_name(type, type)
#define DECLARE_ASN1_ALLOC_FUNCTIONS(type) DECLARE_ASN1_ALLOC_FUNCTIONS_name(type, type)
#define DECLARE_ASN1_FUNCTIONS_name(type,name) DECLARE_ASN1_ALLOC_FUNCTIONS_name(type, name) DECLARE_ASN1_ENCODE_FUNCTIONS(type, name, name)
#define DECLARE_ASN1_FUNCTIONS_fname(type,itname,name) DECLARE_ASN1_ALLOC_FUNCTIONS_name(type, name) DECLARE_ASN1_ENCODE_FUNCTIONS(type, itname, name)
#define DECLARE_ASN1_ENCODE_FUNCTIONS(type,itname,name) type *d2i_ ##name(type **a, const unsigned char **in, long len); int i2d_ ##name(type *a, unsigned char **out); DECLARE_ASN1_ITEM(itname)
#define DECLARE_ASN1_ENCODE_FUNCTIONS_const(type,name) type *d2i_ ##name(type **a, const unsigned char **in, long len); int i2d_ ##name(const type *a, unsigned char **out); DECLARE_ASN1_ITEM(name)
#define DECLARE_ASN1_NDEF_FUNCTION(name) int i2d_ ##name ##_NDEF(name *a, unsigned char **out);
#define DECLARE_ASN1_FUNCTIONS_const(name) DECLARE_ASN1_ALLOC_FUNCTIONS(name) DECLARE_ASN1_ENCODE_FUNCTIONS_const(name, name)
#define DECLARE_ASN1_ALLOC_FUNCTIONS_name(type,name) type *name ##_new(void); void name ##_free(type *a);
#define DECLARE_ASN1_PRINT_FUNCTION(stname) DECLARE_ASN1_PRINT_FUNCTION_fname(stname, stname)
#define DECLARE_ASN1_PRINT_FUNCTION_fname(stname,fname) int fname ##_print_ctx(BIO *out, stname *x, int indent, const ASN1_PCTX *pctx);
#define D2I_OF(type) type *(*)(type **,const unsigned char **,long)
#define I2D_OF(type) int (*)(type *,unsigned char **)
#define I2D_OF_const(type) int (*)(const type *,unsigned char **)
#define CHECKED_D2I_OF(type,d2i) ((d2i_of_void*) (1 ? d2i : ((D2I_OF(type))0)))
#define CHECKED_I2D_OF(type,i2d) ((i2d_of_void*) (1 ? i2d : ((I2D_OF(type))0)))
#define CHECKED_NEW_OF(type,xnew) ((void *(*)(void)) (1 ? xnew : ((type *(*)(void))0)))
#define CHECKED_PTR_OF(type,p) ((void*) (1 ? p : (type*)0))
#define CHECKED_PPTR_OF(type,p) ((void**) (1 ? p : (type**)0))
#define TYPEDEF_D2I_OF(type) typedef type *d2i_of_ ##type(type **,const unsigned char **,long)
#define TYPEDEF_I2D_OF(type) typedef int i2d_of_ ##type(type *,unsigned char **)
#define TYPEDEF_D2I2D_OF(type) TYPEDEF_D2I_OF(type); TYPEDEF_I2D_OF(type)
typedef void *d2i_of_void(void **,const unsigned char **,long); typedef int i2d_of_void(void *,unsigned char **);
typedef const ASN1_ITEM *ASN1_ITEM_EXP (void);
#define ASN1_ITEM_ptr(iptr) (iptr())
#define ASN1_ITEM_ref(iptr) (iptr ##_it)
#define ASN1_ITEM_rptr(ref) (ref ##_it())
#define DECLARE_ASN1_ITEM(name) const ASN1_ITEM * name ##_it(void);
enum {
	ASN1_STRFLGS_ESC_2253 = 1,
	ASN1_STRFLGS_ESC_CTRL = 2,
	ASN1_STRFLGS_ESC_MSB = 4,
	ASN1_STRFLGS_ESC_QUOTE = 8,
	CHARTYPE_PRINTABLESTRING = 0x10,
	CHARTYPE_FIRST_ESC_2253 = 0x20,
	CHARTYPE_LAST_ESC_2253 = 0x40,
	ASN1_STRFLGS_UTF8_CONVERT = 0x10,
	ASN1_STRFLGS_IGNORE_TYPE = 0x20,
	ASN1_STRFLGS_SHOW_TYPE = 0x40,
	ASN1_STRFLGS_DUMP_ALL = 0x80,
	ASN1_STRFLGS_DUMP_UNKNOWN = 0x100,
	ASN1_STRFLGS_DUMP_DER = 0x200,
	ASN1_STRFLGS_ESC_2254 = 0x400,
	ASN1_STRFLGS_RFC2253 = (ASN1_STRFLGS_ESC_2253 | ASN1_STRFLGS_ESC_CTRL | ASN1_STRFLGS_ESC_MSB | ASN1_STRFLGS_UTF8_CONVERT | ASN1_STRFLGS_DUMP_UNKNOWN | ASN1_STRFLGS_DUMP_DER),
};
struct stack_st_ASN1_INTEGER; typedef int (*sk_ASN1_INTEGER_compfunc)(const ASN1_INTEGER * const *a, const ASN1_INTEGER *const *b); typedef void (*sk_ASN1_INTEGER_freefunc)(ASN1_INTEGER *a); typedef ASN1_INTEGER * (*sk_ASN1_INTEGER_copyfunc)(const ASN1_INTEGER *a); static __attribute__((unused)) inline int sk_ASN1_INTEGER_num(const struct stack_st_ASN1_INTEGER *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_INTEGER *sk_ASN1_INTEGER_value(const struct stack_st_ASN1_INTEGER *sk, int idx) { return (ASN1_INTEGER *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_ASN1_INTEGER *sk_ASN1_INTEGER_new(sk_ASN1_INTEGER_compfunc compare) { return (struct stack_st_ASN1_INTEGER *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_ASN1_INTEGER *sk_ASN1_INTEGER_new_null(void) { return (struct stack_st_ASN1_INTEGER *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_ASN1_INTEGER *sk_ASN1_INTEGER_new_reserve(sk_ASN1_INTEGER_compfunc compare, int n) { return (struct stack_st_ASN1_INTEGER *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_reserve(struct stack_st_ASN1_INTEGER *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_ASN1_INTEGER_free(struct stack_st_ASN1_INTEGER *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_INTEGER_zero(struct stack_st_ASN1_INTEGER *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_INTEGER *sk_ASN1_INTEGER_delete(struct stack_st_ASN1_INTEGER *sk, int i) { return (ASN1_INTEGER *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline ASN1_INTEGER *sk_ASN1_INTEGER_delete_ptr(struct stack_st_ASN1_INTEGER *sk, ASN1_INTEGER *ptr) { return (ASN1_INTEGER *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_push(struct stack_st_ASN1_INTEGER *sk, ASN1_INTEGER *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_unshift(struct stack_st_ASN1_INTEGER *sk, ASN1_INTEGER *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline ASN1_INTEGER *sk_ASN1_INTEGER_pop(struct stack_st_ASN1_INTEGER *sk) { return (ASN1_INTEGER *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_INTEGER *sk_ASN1_INTEGER_shift(struct stack_st_ASN1_INTEGER *sk) { return (ASN1_INTEGER *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_INTEGER_pop_free(struct stack_st_ASN1_INTEGER *sk, sk_ASN1_INTEGER_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_insert(struct stack_st_ASN1_INTEGER *sk, ASN1_INTEGER *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline ASN1_INTEGER *sk_ASN1_INTEGER_set(struct stack_st_ASN1_INTEGER *sk, int idx, ASN1_INTEGER *ptr) { return (ASN1_INTEGER *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_find(struct stack_st_ASN1_INTEGER *sk, ASN1_INTEGER *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_find_ex(struct stack_st_ASN1_INTEGER *sk, ASN1_INTEGER *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_ASN1_INTEGER_sort(struct stack_st_ASN1_INTEGER *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_ASN1_INTEGER_is_sorted(const struct stack_st_ASN1_INTEGER *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_INTEGER * sk_ASN1_INTEGER_dup(const struct stack_st_ASN1_INTEGER *sk) { return (struct stack_st_ASN1_INTEGER *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_INTEGER *sk_ASN1_INTEGER_deep_copy(const struct stack_st_ASN1_INTEGER *sk, sk_ASN1_INTEGER_copyfunc copyfunc, sk_ASN1_INTEGER_freefunc freefunc) { return (struct stack_st_ASN1_INTEGER *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_ASN1_INTEGER_compfunc sk_ASN1_INTEGER_set_cmp_func(struct stack_st_ASN1_INTEGER *sk, sk_ASN1_INTEGER_compfunc compare) { return (sk_ASN1_INTEGER_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
struct stack_st_ASN1_GENERALSTRING; typedef int (*sk_ASN1_GENERALSTRING_compfunc)(const ASN1_GENERALSTRING * const *a, const ASN1_GENERALSTRING *const *b); typedef void (*sk_ASN1_GENERALSTRING_freefunc)(ASN1_GENERALSTRING *a); typedef ASN1_GENERALSTRING * (*sk_ASN1_GENERALSTRING_copyfunc)(const ASN1_GENERALSTRING *a); static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_num(const struct stack_st_ASN1_GENERALSTRING *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_value(const struct stack_st_ASN1_GENERALSTRING *sk, int idx) { return (ASN1_GENERALSTRING *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_new(sk_ASN1_GENERALSTRING_compfunc compare) { return (struct stack_st_ASN1_GENERALSTRING *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_new_null(void) { return (struct stack_st_ASN1_GENERALSTRING *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_new_reserve(sk_ASN1_GENERALSTRING_compfunc compare, int n) { return (struct stack_st_ASN1_GENERALSTRING *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_reserve(struct stack_st_ASN1_GENERALSTRING *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_ASN1_GENERALSTRING_free(struct stack_st_ASN1_GENERALSTRING *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_GENERALSTRING_zero(struct stack_st_ASN1_GENERALSTRING *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_delete(struct stack_st_ASN1_GENERALSTRING *sk, int i) { return (ASN1_GENERALSTRING *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_delete_ptr(struct stack_st_ASN1_GENERALSTRING *sk, ASN1_GENERALSTRING *ptr) { return (ASN1_GENERALSTRING *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_push(struct stack_st_ASN1_GENERALSTRING *sk, ASN1_GENERALSTRING *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_unshift(struct stack_st_ASN1_GENERALSTRING *sk, ASN1_GENERALSTRING *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_pop(struct stack_st_ASN1_GENERALSTRING *sk) { return (ASN1_GENERALSTRING *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_shift(struct stack_st_ASN1_GENERALSTRING *sk) { return (ASN1_GENERALSTRING *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_GENERALSTRING_pop_free(struct stack_st_ASN1_GENERALSTRING *sk, sk_ASN1_GENERALSTRING_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_insert(struct stack_st_ASN1_GENERALSTRING *sk, ASN1_GENERALSTRING *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_set(struct stack_st_ASN1_GENERALSTRING *sk, int idx, ASN1_GENERALSTRING *ptr) { return (ASN1_GENERALSTRING *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_find(struct stack_st_ASN1_GENERALSTRING *sk, ASN1_GENERALSTRING *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_find_ex(struct stack_st_ASN1_GENERALSTRING *sk, ASN1_GENERALSTRING *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_ASN1_GENERALSTRING_sort(struct stack_st_ASN1_GENERALSTRING *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_ASN1_GENERALSTRING_is_sorted(const struct stack_st_ASN1_GENERALSTRING *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_GENERALSTRING * sk_ASN1_GENERALSTRING_dup(const struct stack_st_ASN1_GENERALSTRING *sk) { return (struct stack_st_ASN1_GENERALSTRING *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_GENERALSTRING *sk_ASN1_GENERALSTRING_deep_copy(const struct stack_st_ASN1_GENERALSTRING *sk, sk_ASN1_GENERALSTRING_copyfunc copyfunc, sk_ASN1_GENERALSTRING_freefunc freefunc) { return (struct stack_st_ASN1_GENERALSTRING *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_ASN1_GENERALSTRING_compfunc sk_ASN1_GENERALSTRING_set_cmp_func(struct stack_st_ASN1_GENERALSTRING *sk, sk_ASN1_GENERALSTRING_compfunc compare) { return (sk_ASN1_GENERALSTRING_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
struct stack_st_ASN1_UTF8STRING; typedef int (*sk_ASN1_UTF8STRING_compfunc)(const ASN1_UTF8STRING * const *a, const ASN1_UTF8STRING *const *b); typedef void (*sk_ASN1_UTF8STRING_freefunc)(ASN1_UTF8STRING *a); typedef ASN1_UTF8STRING * (*sk_ASN1_UTF8STRING_copyfunc)(const ASN1_UTF8STRING *a); static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_num(const struct stack_st_ASN1_UTF8STRING *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_UTF8STRING *sk_ASN1_UTF8STRING_value(const struct stack_st_ASN1_UTF8STRING *sk, int idx) { return (ASN1_UTF8STRING *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_ASN1_UTF8STRING *sk_ASN1_UTF8STRING_new(sk_ASN1_UTF8STRING_compfunc compare) { return (struct stack_st_ASN1_UTF8STRING *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_ASN1_UTF8STRING *sk_ASN1_UTF8STRING_new_null(void) { return (struct stack_st_ASN1_UTF8STRING *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_ASN1_UTF8STRING *sk_ASN1_UTF8STRING_new_reserve(sk_ASN1_UTF8STRING_compfunc compare, int n) { return (struct stack_st_ASN1_UTF8STRING *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_reserve(struct stack_st_ASN1_UTF8STRING *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_ASN1_UTF8STRING_free(struct stack_st_ASN1_UTF8STRING *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_UTF8STRING_zero(struct stack_st_ASN1_UTF8STRING *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_UTF8STRING *sk_ASN1_UTF8STRING_delete(struct stack_st_ASN1_UTF8STRING *sk, int i) { return (ASN1_UTF8STRING *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline ASN1_UTF8STRING *sk_ASN1_UTF8STRING_delete_ptr(struct stack_st_ASN1_UTF8STRING *sk, ASN1_UTF8STRING *ptr) { return (ASN1_UTF8STRING *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_push(struct stack_st_ASN1_UTF8STRING *sk, ASN1_UTF8STRING *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_unshift(struct stack_st_ASN1_UTF8STRING *sk, ASN1_UTF8STRING *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline ASN1_UTF8STRING *sk_ASN1_UTF8STRING_pop(struct stack_st_ASN1_UTF8STRING *sk) { return (ASN1_UTF8STRING *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_UTF8STRING *sk_ASN1_UTF8STRING_shift(struct stack_st_ASN1_UTF8STRING *sk) { return (ASN1_UTF8STRING *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_UTF8STRING_pop_free(struct stack_st_ASN1_UTF8STRING *sk, sk_ASN1_UTF8STRING_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_insert(struct stack_st_ASN1_UTF8STRING *sk, ASN1_UTF8STRING *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline ASN1_UTF8STRING *sk_ASN1_UTF8STRING_set(struct stack_st_ASN1_UTF8STRING *sk, int idx, ASN1_UTF8STRING *ptr) { return (ASN1_UTF8STRING *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_find(struct stack_st_ASN1_UTF8STRING *sk, ASN1_UTF8STRING *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_find_ex(struct stack_st_ASN1_UTF8STRING *sk, ASN1_UTF8STRING *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_ASN1_UTF8STRING_sort(struct stack_st_ASN1_UTF8STRING *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_ASN1_UTF8STRING_is_sorted(const struct stack_st_ASN1_UTF8STRING *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_UTF8STRING * sk_ASN1_UTF8STRING_dup(const struct stack_st_ASN1_UTF8STRING *sk) { return (struct stack_st_ASN1_UTF8STRING *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_UTF8STRING *sk_ASN1_UTF8STRING_deep_copy(const struct stack_st_ASN1_UTF8STRING *sk, sk_ASN1_UTF8STRING_copyfunc copyfunc, sk_ASN1_UTF8STRING_freefunc freefunc) { return (struct stack_st_ASN1_UTF8STRING *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_ASN1_UTF8STRING_compfunc sk_ASN1_UTF8STRING_set_cmp_func(struct stack_st_ASN1_UTF8STRING *sk, sk_ASN1_UTF8STRING_compfunc compare) { return (sk_ASN1_UTF8STRING_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct asn1_type_st {
    int type;
    union {
        char *ptr;
        ASN1_BOOLEAN boolean;
        ASN1_STRING *asn1_string;
        ASN1_OBJECT *object;
        ASN1_INTEGER *integer;
        ASN1_ENUMERATED *enumerated;
        ASN1_BIT_STRING *bit_string;
        ASN1_OCTET_STRING *octet_string;
        ASN1_PRINTABLESTRING *printablestring;
        ASN1_T61STRING *t61string;
        ASN1_IA5STRING *ia5string;
        ASN1_GENERALSTRING *generalstring;
        ASN1_BMPSTRING *bmpstring;
        ASN1_UNIVERSALSTRING *universalstring;
        ASN1_UTCTIME *utctime;
        ASN1_GENERALIZEDTIME *generalizedtime;
        ASN1_VISIBLESTRING *visiblestring;
        ASN1_UTF8STRING *utf8string;
        ASN1_STRING *set;
        ASN1_STRING *sequence;
        ASN1_VALUE *asn1_value;
    } value;
} ASN1_TYPE;
struct stack_st_ASN1_TYPE; typedef int (*sk_ASN1_TYPE_compfunc)(const ASN1_TYPE * const *a, const ASN1_TYPE *const *b); typedef void (*sk_ASN1_TYPE_freefunc)(ASN1_TYPE *a); typedef ASN1_TYPE * (*sk_ASN1_TYPE_copyfunc)(const ASN1_TYPE *a); static __attribute__((unused)) inline int sk_ASN1_TYPE_num(const struct stack_st_ASN1_TYPE *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_TYPE *sk_ASN1_TYPE_value(const struct stack_st_ASN1_TYPE *sk, int idx) { return (ASN1_TYPE *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_ASN1_TYPE *sk_ASN1_TYPE_new(sk_ASN1_TYPE_compfunc compare) { return (struct stack_st_ASN1_TYPE *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_ASN1_TYPE *sk_ASN1_TYPE_new_null(void) { return (struct stack_st_ASN1_TYPE *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_ASN1_TYPE *sk_ASN1_TYPE_new_reserve(sk_ASN1_TYPE_compfunc compare, int n) { return (struct stack_st_ASN1_TYPE *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_ASN1_TYPE_reserve(struct stack_st_ASN1_TYPE *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_ASN1_TYPE_free(struct stack_st_ASN1_TYPE *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_TYPE_zero(struct stack_st_ASN1_TYPE *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_TYPE *sk_ASN1_TYPE_delete(struct stack_st_ASN1_TYPE *sk, int i) { return (ASN1_TYPE *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline ASN1_TYPE *sk_ASN1_TYPE_delete_ptr(struct stack_st_ASN1_TYPE *sk, ASN1_TYPE *ptr) { return (ASN1_TYPE *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_TYPE_push(struct stack_st_ASN1_TYPE *sk, ASN1_TYPE *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_TYPE_unshift(struct stack_st_ASN1_TYPE *sk, ASN1_TYPE *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline ASN1_TYPE *sk_ASN1_TYPE_pop(struct stack_st_ASN1_TYPE *sk) { return (ASN1_TYPE *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_TYPE *sk_ASN1_TYPE_shift(struct stack_st_ASN1_TYPE *sk) { return (ASN1_TYPE *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_TYPE_pop_free(struct stack_st_ASN1_TYPE *sk, sk_ASN1_TYPE_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_ASN1_TYPE_insert(struct stack_st_ASN1_TYPE *sk, ASN1_TYPE *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline ASN1_TYPE *sk_ASN1_TYPE_set(struct stack_st_ASN1_TYPE *sk, int idx, ASN1_TYPE *ptr) { return (ASN1_TYPE *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_TYPE_find(struct stack_st_ASN1_TYPE *sk, ASN1_TYPE *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_TYPE_find_ex(struct stack_st_ASN1_TYPE *sk, ASN1_TYPE *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_ASN1_TYPE_sort(struct stack_st_ASN1_TYPE *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_ASN1_TYPE_is_sorted(const struct stack_st_ASN1_TYPE *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_TYPE * sk_ASN1_TYPE_dup(const struct stack_st_ASN1_TYPE *sk) { return (struct stack_st_ASN1_TYPE *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_TYPE *sk_ASN1_TYPE_deep_copy(const struct stack_st_ASN1_TYPE *sk, sk_ASN1_TYPE_copyfunc copyfunc, sk_ASN1_TYPE_freefunc freefunc) { return (struct stack_st_ASN1_TYPE *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_ASN1_TYPE_compfunc sk_ASN1_TYPE_set_cmp_func(struct stack_st_ASN1_TYPE *sk, sk_ASN1_TYPE_compfunc compare) { return (sk_ASN1_TYPE_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef struct stack_st_ASN1_TYPE ASN1_SEQUENCE_ANY;
ASN1_SEQUENCE_ANY *d2i_ASN1_SEQUENCE_ANY(ASN1_SEQUENCE_ANY **a, const unsigned char **in, long len); int i2d_ASN1_SEQUENCE_ANY(const ASN1_SEQUENCE_ANY *a, unsigned char **out); const ASN1_ITEM * ASN1_SEQUENCE_ANY_it(void);
ASN1_SEQUENCE_ANY *d2i_ASN1_SET_ANY(ASN1_SEQUENCE_ANY **a, const unsigned char **in, long len); int i2d_ASN1_SET_ANY(const ASN1_SEQUENCE_ANY *a, unsigned char **out); const ASN1_ITEM * ASN1_SET_ANY_it(void);
typedef struct BIT_STRING_BITNAME_st {
    int bitnum;
    const char *lname;
    const char *sname;
} BIT_STRING_BITNAME;
enum {
	B_ASN1_TIME          = B_ASN1_UTCTIME | B_ASN1_GENERALIZEDTIME,
	B_ASN1_PRINTABLE     = B_ASN1_NUMERICSTRING| B_ASN1_PRINTABLESTRING| B_ASN1_T61STRING| B_ASN1_IA5STRING| B_ASN1_BIT_STRING| B_ASN1_UNIVERSALSTRING| B_ASN1_BMPSTRING| B_ASN1_UTF8STRING| B_ASN1_SEQUENCE| B_ASN1_UNKNOWN,
	B_ASN1_DIRECTORYSTRING = B_ASN1_PRINTABLESTRING| B_ASN1_TELETEXSTRING| B_ASN1_BMPSTRING| B_ASN1_UNIVERSALSTRING| B_ASN1_UTF8STRING,
	B_ASN1_DISPLAYTEXT   = B_ASN1_IA5STRING| B_ASN1_VISIBLESTRING| B_ASN1_BMPSTRING| B_ASN1_UTF8STRING,
};
ASN1_TYPE *ASN1_TYPE_new(void); void ASN1_TYPE_free(ASN1_TYPE *a); ASN1_TYPE *d2i_ASN1_TYPE(ASN1_TYPE **a, const unsigned char **in, long len); int i2d_ASN1_TYPE(ASN1_TYPE *a, unsigned char **out); const ASN1_ITEM * ASN1_ANY_it(void);
int ASN1_TYPE_get(const ASN1_TYPE *a);
void ASN1_TYPE_set(ASN1_TYPE *a, int type, void *value);
int ASN1_TYPE_set1(ASN1_TYPE *a, int type, const void *value);
int ASN1_TYPE_cmp(const ASN1_TYPE *a, const ASN1_TYPE *b);
ASN1_TYPE *ASN1_TYPE_pack_sequence(const ASN1_ITEM *it, void *s, ASN1_TYPE **t);
void *ASN1_TYPE_unpack_sequence(const ASN1_ITEM *it, const ASN1_TYPE *t);
ASN1_OBJECT *ASN1_OBJECT_new(void);
void ASN1_OBJECT_free(ASN1_OBJECT *a);
int i2d_ASN1_OBJECT(const ASN1_OBJECT *a, unsigned char **pp);
ASN1_OBJECT *d2i_ASN1_OBJECT(ASN1_OBJECT **a, const unsigned char **pp,
                             long length);
const ASN1_ITEM * ASN1_OBJECT_it(void);
struct stack_st_ASN1_OBJECT; typedef int (*sk_ASN1_OBJECT_compfunc)(const ASN1_OBJECT * const *a, const ASN1_OBJECT *const *b); typedef void (*sk_ASN1_OBJECT_freefunc)(ASN1_OBJECT *a); typedef ASN1_OBJECT * (*sk_ASN1_OBJECT_copyfunc)(const ASN1_OBJECT *a); static __attribute__((unused)) inline int sk_ASN1_OBJECT_num(const struct stack_st_ASN1_OBJECT *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_OBJECT *sk_ASN1_OBJECT_value(const struct stack_st_ASN1_OBJECT *sk, int idx) { return (ASN1_OBJECT *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_ASN1_OBJECT *sk_ASN1_OBJECT_new(sk_ASN1_OBJECT_compfunc compare) { return (struct stack_st_ASN1_OBJECT *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_ASN1_OBJECT *sk_ASN1_OBJECT_new_null(void) { return (struct stack_st_ASN1_OBJECT *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_ASN1_OBJECT *sk_ASN1_OBJECT_new_reserve(sk_ASN1_OBJECT_compfunc compare, int n) { return (struct stack_st_ASN1_OBJECT *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_reserve(struct stack_st_ASN1_OBJECT *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_ASN1_OBJECT_free(struct stack_st_ASN1_OBJECT *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_OBJECT_zero(struct stack_st_ASN1_OBJECT *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_OBJECT *sk_ASN1_OBJECT_delete(struct stack_st_ASN1_OBJECT *sk, int i) { return (ASN1_OBJECT *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline ASN1_OBJECT *sk_ASN1_OBJECT_delete_ptr(struct stack_st_ASN1_OBJECT *sk, ASN1_OBJECT *ptr) { return (ASN1_OBJECT *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_push(struct stack_st_ASN1_OBJECT *sk, ASN1_OBJECT *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_unshift(struct stack_st_ASN1_OBJECT *sk, ASN1_OBJECT *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline ASN1_OBJECT *sk_ASN1_OBJECT_pop(struct stack_st_ASN1_OBJECT *sk) { return (ASN1_OBJECT *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline ASN1_OBJECT *sk_ASN1_OBJECT_shift(struct stack_st_ASN1_OBJECT *sk) { return (ASN1_OBJECT *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_ASN1_OBJECT_pop_free(struct stack_st_ASN1_OBJECT *sk, sk_ASN1_OBJECT_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_insert(struct stack_st_ASN1_OBJECT *sk, ASN1_OBJECT *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline ASN1_OBJECT *sk_ASN1_OBJECT_set(struct stack_st_ASN1_OBJECT *sk, int idx, ASN1_OBJECT *ptr) { return (ASN1_OBJECT *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_find(struct stack_st_ASN1_OBJECT *sk, ASN1_OBJECT *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_find_ex(struct stack_st_ASN1_OBJECT *sk, ASN1_OBJECT *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_ASN1_OBJECT_sort(struct stack_st_ASN1_OBJECT *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_ASN1_OBJECT_is_sorted(const struct stack_st_ASN1_OBJECT *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_OBJECT * sk_ASN1_OBJECT_dup(const struct stack_st_ASN1_OBJECT *sk) { return (struct stack_st_ASN1_OBJECT *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_ASN1_OBJECT *sk_ASN1_OBJECT_deep_copy(const struct stack_st_ASN1_OBJECT *sk, sk_ASN1_OBJECT_copyfunc copyfunc, sk_ASN1_OBJECT_freefunc freefunc) { return (struct stack_st_ASN1_OBJECT *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_ASN1_OBJECT_compfunc sk_ASN1_OBJECT_set_cmp_func(struct stack_st_ASN1_OBJECT *sk, sk_ASN1_OBJECT_compfunc compare) { return (sk_ASN1_OBJECT_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
ASN1_STRING *ASN1_STRING_new(void);
void ASN1_STRING_free(ASN1_STRING *a);
void ASN1_STRING_clear_free(ASN1_STRING *a);
int ASN1_STRING_copy(ASN1_STRING *dst, const ASN1_STRING *str);
ASN1_STRING *ASN1_STRING_dup(const ASN1_STRING *a);
ASN1_STRING *ASN1_STRING_type_new(int type);
int ASN1_STRING_cmp(const ASN1_STRING *a, const ASN1_STRING *b);
int ASN1_STRING_set(ASN1_STRING *str, const void *data, int len);
void ASN1_STRING_set0(ASN1_STRING *str, void *data, int len);
int ASN1_STRING_length(const ASN1_STRING *x);
void ASN1_STRING_length_set(ASN1_STRING *x, int n);
int ASN1_STRING_type(const ASN1_STRING *x);
unsigned char *ASN1_STRING_data(ASN1_STRING *x) __attribute__ ((deprecated));
const unsigned char *ASN1_STRING_get0_data(const ASN1_STRING *x);
ASN1_BIT_STRING *ASN1_BIT_STRING_new(void); void ASN1_BIT_STRING_free(ASN1_BIT_STRING *a); ASN1_BIT_STRING *d2i_ASN1_BIT_STRING(ASN1_BIT_STRING **a, const unsigned char **in, long len); int i2d_ASN1_BIT_STRING(ASN1_BIT_STRING *a, unsigned char **out); const ASN1_ITEM * ASN1_BIT_STRING_it(void);
int ASN1_BIT_STRING_set(ASN1_BIT_STRING *a, unsigned char *d, int length);
int ASN1_BIT_STRING_set_bit(ASN1_BIT_STRING *a, int n, int value);
int ASN1_BIT_STRING_get_bit(const ASN1_BIT_STRING *a, int n);
int ASN1_BIT_STRING_check(const ASN1_BIT_STRING *a,
                          const unsigned char *flags, int flags_len);
int ASN1_BIT_STRING_name_print(BIO *out, ASN1_BIT_STRING *bs,
                               BIT_STRING_BITNAME *tbl, int indent);
int ASN1_BIT_STRING_num_asc(const char *name, BIT_STRING_BITNAME *tbl);
int ASN1_BIT_STRING_set_asc(ASN1_BIT_STRING *bs, const char *name, int value,
                            BIT_STRING_BITNAME *tbl);
ASN1_INTEGER *ASN1_INTEGER_new(void); void ASN1_INTEGER_free(ASN1_INTEGER *a); ASN1_INTEGER *d2i_ASN1_INTEGER(ASN1_INTEGER **a, const unsigned char **in, long len); int i2d_ASN1_INTEGER(ASN1_INTEGER *a, unsigned char **out); const ASN1_ITEM * ASN1_INTEGER_it(void);
ASN1_INTEGER *d2i_ASN1_UINTEGER(ASN1_INTEGER **a, const unsigned char **pp,
                                long length);
ASN1_INTEGER *ASN1_INTEGER_dup(const ASN1_INTEGER *x);
int ASN1_INTEGER_cmp(const ASN1_INTEGER *x, const ASN1_INTEGER *y);
ASN1_ENUMERATED *ASN1_ENUMERATED_new(void); void ASN1_ENUMERATED_free(ASN1_ENUMERATED *a); ASN1_ENUMERATED *d2i_ASN1_ENUMERATED(ASN1_ENUMERATED **a, const unsigned char **in, long len); int i2d_ASN1_ENUMERATED(ASN1_ENUMERATED *a, unsigned char **out); const ASN1_ITEM * ASN1_ENUMERATED_it(void);
int ASN1_UTCTIME_check(const ASN1_UTCTIME *a);
ASN1_UTCTIME *ASN1_UTCTIME_set(ASN1_UTCTIME *s, time_t t);
ASN1_UTCTIME *ASN1_UTCTIME_adj(ASN1_UTCTIME *s, time_t t,
                               int offset_day, long offset_sec);
int ASN1_UTCTIME_set_string(ASN1_UTCTIME *s, const char *str);
int ASN1_UTCTIME_cmp_time_t(const ASN1_UTCTIME *s, time_t t);
int ASN1_GENERALIZEDTIME_check(const ASN1_GENERALIZEDTIME *a);
ASN1_GENERALIZEDTIME *ASN1_GENERALIZEDTIME_set(ASN1_GENERALIZEDTIME *s,
                                               time_t t);
ASN1_GENERALIZEDTIME *ASN1_GENERALIZEDTIME_adj(ASN1_GENERALIZEDTIME *s,
                                               time_t t, int offset_day,
                                               long offset_sec);
int ASN1_GENERALIZEDTIME_set_string(ASN1_GENERALIZEDTIME *s, const char *str);
int ASN1_TIME_diff(int *pday, int *psec,
                   const ASN1_TIME *from, const ASN1_TIME *to);
ASN1_OCTET_STRING *ASN1_OCTET_STRING_new(void); void ASN1_OCTET_STRING_free(ASN1_OCTET_STRING *a); ASN1_OCTET_STRING *d2i_ASN1_OCTET_STRING(ASN1_OCTET_STRING **a, const unsigned char **in, long len); int i2d_ASN1_OCTET_STRING(ASN1_OCTET_STRING *a, unsigned char **out); const ASN1_ITEM * ASN1_OCTET_STRING_it(void);
ASN1_OCTET_STRING *ASN1_OCTET_STRING_dup(const ASN1_OCTET_STRING *a);
int ASN1_OCTET_STRING_cmp(const ASN1_OCTET_STRING *a,
                          const ASN1_OCTET_STRING *b);
int ASN1_OCTET_STRING_set(ASN1_OCTET_STRING *str, const unsigned char *data,
                          int len);
ASN1_VISIBLESTRING *ASN1_VISIBLESTRING_new(void); void ASN1_VISIBLESTRING_free(ASN1_VISIBLESTRING *a); ASN1_VISIBLESTRING *d2i_ASN1_VISIBLESTRING(ASN1_VISIBLESTRING **a, const unsigned char **in, long len); int i2d_ASN1_VISIBLESTRING(ASN1_VISIBLESTRING *a, unsigned char **out); const ASN1_ITEM * ASN1_VISIBLESTRING_it(void);
ASN1_UNIVERSALSTRING *ASN1_UNIVERSALSTRING_new(void); void ASN1_UNIVERSALSTRING_free(ASN1_UNIVERSALSTRING *a); ASN1_UNIVERSALSTRING *d2i_ASN1_UNIVERSALSTRING(ASN1_UNIVERSALSTRING **a, const unsigned char **in, long len); int i2d_ASN1_UNIVERSALSTRING(ASN1_UNIVERSALSTRING *a, unsigned char **out); const ASN1_ITEM * ASN1_UNIVERSALSTRING_it(void);
ASN1_UTF8STRING *ASN1_UTF8STRING_new(void); void ASN1_UTF8STRING_free(ASN1_UTF8STRING *a); ASN1_UTF8STRING *d2i_ASN1_UTF8STRING(ASN1_UTF8STRING **a, const unsigned char **in, long len); int i2d_ASN1_UTF8STRING(ASN1_UTF8STRING *a, unsigned char **out); const ASN1_ITEM * ASN1_UTF8STRING_it(void);
ASN1_NULL *ASN1_NULL_new(void); void ASN1_NULL_free(ASN1_NULL *a); ASN1_NULL *d2i_ASN1_NULL(ASN1_NULL **a, const unsigned char **in, long len); int i2d_ASN1_NULL(ASN1_NULL *a, unsigned char **out); const ASN1_ITEM * ASN1_NULL_it(void);
ASN1_BMPSTRING *ASN1_BMPSTRING_new(void); void ASN1_BMPSTRING_free(ASN1_BMPSTRING *a); ASN1_BMPSTRING *d2i_ASN1_BMPSTRING(ASN1_BMPSTRING **a, const unsigned char **in, long len); int i2d_ASN1_BMPSTRING(ASN1_BMPSTRING *a, unsigned char **out); const ASN1_ITEM * ASN1_BMPSTRING_it(void);
int UTF8_getc(const unsigned char *str, int len, unsigned long *val);
int UTF8_putc(unsigned char *str, int len, unsigned long value);
ASN1_STRING *ASN1_PRINTABLE_new(void); void ASN1_PRINTABLE_free(ASN1_STRING *a); ASN1_STRING *d2i_ASN1_PRINTABLE(ASN1_STRING **a, const unsigned char **in, long len); int i2d_ASN1_PRINTABLE(ASN1_STRING *a, unsigned char **out); const ASN1_ITEM * ASN1_PRINTABLE_it(void);
ASN1_STRING *DIRECTORYSTRING_new(void); void DIRECTORYSTRING_free(ASN1_STRING *a); ASN1_STRING *d2i_DIRECTORYSTRING(ASN1_STRING **a, const unsigned char **in, long len); int i2d_DIRECTORYSTRING(ASN1_STRING *a, unsigned char **out); const ASN1_ITEM * DIRECTORYSTRING_it(void);
ASN1_STRING *DISPLAYTEXT_new(void); void DISPLAYTEXT_free(ASN1_STRING *a); ASN1_STRING *d2i_DISPLAYTEXT(ASN1_STRING **a, const unsigned char **in, long len); int i2d_DISPLAYTEXT(ASN1_STRING *a, unsigned char **out); const ASN1_ITEM * DISPLAYTEXT_it(void);
ASN1_PRINTABLESTRING *ASN1_PRINTABLESTRING_new(void); void ASN1_PRINTABLESTRING_free(ASN1_PRINTABLESTRING *a); ASN1_PRINTABLESTRING *d2i_ASN1_PRINTABLESTRING(ASN1_PRINTABLESTRING **a, const unsigned char **in, long len); int i2d_ASN1_PRINTABLESTRING(ASN1_PRINTABLESTRING *a, unsigned char **out); const ASN1_ITEM * ASN1_PRINTABLESTRING_it(void);
ASN1_T61STRING *ASN1_T61STRING_new(void); void ASN1_T61STRING_free(ASN1_T61STRING *a); ASN1_T61STRING *d2i_ASN1_T61STRING(ASN1_T61STRING **a, const unsigned char **in, long len); int i2d_ASN1_T61STRING(ASN1_T61STRING *a, unsigned char **out); const ASN1_ITEM * ASN1_T61STRING_it(void);
ASN1_IA5STRING *ASN1_IA5STRING_new(void); void ASN1_IA5STRING_free(ASN1_IA5STRING *a); ASN1_IA5STRING *d2i_ASN1_IA5STRING(ASN1_IA5STRING **a, const unsigned char **in, long len); int i2d_ASN1_IA5STRING(ASN1_IA5STRING *a, unsigned char **out); const ASN1_ITEM * ASN1_IA5STRING_it(void);
ASN1_GENERALSTRING *ASN1_GENERALSTRING_new(void); void ASN1_GENERALSTRING_free(ASN1_GENERALSTRING *a); ASN1_GENERALSTRING *d2i_ASN1_GENERALSTRING(ASN1_GENERALSTRING **a, const unsigned char **in, long len); int i2d_ASN1_GENERALSTRING(ASN1_GENERALSTRING *a, unsigned char **out); const ASN1_ITEM * ASN1_GENERALSTRING_it(void);
ASN1_UTCTIME *ASN1_UTCTIME_new(void); void ASN1_UTCTIME_free(ASN1_UTCTIME *a); ASN1_UTCTIME *d2i_ASN1_UTCTIME(ASN1_UTCTIME **a, const unsigned char **in, long len); int i2d_ASN1_UTCTIME(ASN1_UTCTIME *a, unsigned char **out); const ASN1_ITEM * ASN1_UTCTIME_it(void);
ASN1_GENERALIZEDTIME *ASN1_GENERALIZEDTIME_new(void); void ASN1_GENERALIZEDTIME_free(ASN1_GENERALIZEDTIME *a); ASN1_GENERALIZEDTIME *d2i_ASN1_GENERALIZEDTIME(ASN1_GENERALIZEDTIME **a, const unsigned char **in, long len); int i2d_ASN1_GENERALIZEDTIME(ASN1_GENERALIZEDTIME *a, unsigned char **out); const ASN1_ITEM * ASN1_GENERALIZEDTIME_it(void);
ASN1_TIME *ASN1_TIME_new(void); void ASN1_TIME_free(ASN1_TIME *a); ASN1_TIME *d2i_ASN1_TIME(ASN1_TIME **a, const unsigned char **in, long len); int i2d_ASN1_TIME(ASN1_TIME *a, unsigned char **out); const ASN1_ITEM * ASN1_TIME_it(void);
const ASN1_ITEM * ASN1_OCTET_STRING_NDEF_it(void);
ASN1_TIME *ASN1_TIME_set(ASN1_TIME *s, time_t t);
ASN1_TIME *ASN1_TIME_adj(ASN1_TIME *s, time_t t,
                         int offset_day, long offset_sec);
int ASN1_TIME_check(const ASN1_TIME *t);
ASN1_GENERALIZEDTIME *ASN1_TIME_to_generalizedtime(const ASN1_TIME *t,
                                                   ASN1_GENERALIZEDTIME **out);
int ASN1_TIME_set_string(ASN1_TIME *s, const char *str);
int ASN1_TIME_set_string_X509(ASN1_TIME *s, const char *str);
int ASN1_TIME_to_tm(const ASN1_TIME *s, struct tm *tm);
int ASN1_TIME_normalize(ASN1_TIME *s);
int ASN1_TIME_cmp_time_t(const ASN1_TIME *s, time_t t);
int ASN1_TIME_compare(const ASN1_TIME *a, const ASN1_TIME *b);
int i2a_ASN1_INTEGER(BIO *bp, const ASN1_INTEGER *a);
int a2i_ASN1_INTEGER(BIO *bp, ASN1_INTEGER *bs, char *buf, int size);
int i2a_ASN1_ENUMERATED(BIO *bp, const ASN1_ENUMERATED *a);
int a2i_ASN1_ENUMERATED(BIO *bp, ASN1_ENUMERATED *bs, char *buf, int size);
int i2a_ASN1_OBJECT(BIO *bp, const ASN1_OBJECT *a);
int a2i_ASN1_STRING(BIO *bp, ASN1_STRING *bs, char *buf, int size);
int i2a_ASN1_STRING(BIO *bp, const ASN1_STRING *a, int type);
int i2t_ASN1_OBJECT(char *buf, int buf_len, const ASN1_OBJECT *a);
int a2d_ASN1_OBJECT(unsigned char *out, int olen, const char *buf, int num);
ASN1_OBJECT *ASN1_OBJECT_create(int nid, unsigned char *data, int len,
                                const char *sn, const char *ln);
int ASN1_INTEGER_get_int64(int64_t *pr, const ASN1_INTEGER *a);
int ASN1_INTEGER_set_int64(ASN1_INTEGER *a, int64_t r);
int ASN1_INTEGER_get_uint64(uint64_t *pr, const ASN1_INTEGER *a);
int ASN1_INTEGER_set_uint64(ASN1_INTEGER *a, uint64_t r);
int ASN1_INTEGER_set(ASN1_INTEGER *a, long v);
long ASN1_INTEGER_get(const ASN1_INTEGER *a);
ASN1_INTEGER *BN_to_ASN1_INTEGER(const BIGNUM *bn, ASN1_INTEGER *ai);
BIGNUM *ASN1_INTEGER_to_BN(const ASN1_INTEGER *ai, BIGNUM *bn);
int ASN1_ENUMERATED_get_int64(int64_t *pr, const ASN1_ENUMERATED *a);
int ASN1_ENUMERATED_set_int64(ASN1_ENUMERATED *a, int64_t r);
int ASN1_ENUMERATED_set(ASN1_ENUMERATED *a, long v);
long ASN1_ENUMERATED_get(const ASN1_ENUMERATED *a);
ASN1_ENUMERATED *BN_to_ASN1_ENUMERATED(const BIGNUM *bn, ASN1_ENUMERATED *ai);
BIGNUM *ASN1_ENUMERATED_to_BN(const ASN1_ENUMERATED *ai, BIGNUM *bn);
int ASN1_PRINTABLE_type(const unsigned char *s, int max);
unsigned long ASN1_tag2bit(int tag);
int ASN1_get_object(const unsigned char **pp, long *plength, int *ptag,
                    int *pclass, long omax);
int ASN1_check_infinite_end(unsigned char **p, long len);
int ASN1_const_check_infinite_end(const unsigned char **p, long len);
void ASN1_put_object(unsigned char **pp, int constructed, int length,
                     int tag, int xclass);
int ASN1_put_eoc(unsigned char **pp);
int ASN1_object_size(int constructed, int length, int tag);
void *ASN1_dup(i2d_of_void *i2d, d2i_of_void *d2i, void *x);
#define ASN1_dup_of(type,i2d,d2i,x) ((type*)ASN1_dup(CHECKED_I2D_OF(type, i2d), CHECKED_D2I_OF(type, d2i), CHECKED_PTR_OF(type, x)))
#define ASN1_dup_of_const(type,i2d,d2i,x) ((type*)ASN1_dup(CHECKED_I2D_OF(const type, i2d), CHECKED_D2I_OF(type, d2i), CHECKED_PTR_OF(const type, x)))
void *ASN1_item_dup(const ASN1_ITEM *it, void *x);
#define M_ASN1_new_of(type) (type *)ASN1_item_new(ASN1_ITEM_rptr(type))
#define M_ASN1_free_of(x,type) ASN1_item_free(CHECKED_PTR_OF(type, x), ASN1_ITEM_rptr(type))
void *ASN1_d2i_fp(void *(*xnew) (void), d2i_of_void *d2i, FILE *in, void **x);
#define ASN1_d2i_fp_of(type,xnew,d2i,in,x) ((type*)ASN1_d2i_fp(CHECKED_NEW_OF(type, xnew), CHECKED_D2I_OF(type, d2i), in, CHECKED_PPTR_OF(type, x)))
void *ASN1_item_d2i_fp(const ASN1_ITEM *it, FILE *in, void *x);
int ASN1_i2d_fp(i2d_of_void *i2d, FILE *out, void *x);
#define ASN1_i2d_fp_of(type,i2d,out,x) (ASN1_i2d_fp(CHECKED_I2D_OF(type, i2d), out, CHECKED_PTR_OF(type, x)))
#define ASN1_i2d_fp_of_const(type,i2d,out,x) (ASN1_i2d_fp(CHECKED_I2D_OF(const type, i2d), out, CHECKED_PTR_OF(const type, x)))
int ASN1_item_i2d_fp(const ASN1_ITEM *it, FILE *out, void *x);
int ASN1_STRING_print_ex_fp(FILE *fp, const ASN1_STRING *str, unsigned long flags);
int ASN1_STRING_to_UTF8(unsigned char **out, const ASN1_STRING *in);
void *ASN1_d2i_bio(void *(*xnew) (void), d2i_of_void *d2i, BIO *in, void **x);
#define ASN1_d2i_bio_of(type,xnew,d2i,in,x) ((type*)ASN1_d2i_bio( CHECKED_NEW_OF(type, xnew), CHECKED_D2I_OF(type, d2i), in, CHECKED_PPTR_OF(type, x)))
void *ASN1_item_d2i_bio(const ASN1_ITEM *it, BIO *in, void *x);
int ASN1_i2d_bio(i2d_of_void *i2d, BIO *out, unsigned char *x);
#define ASN1_i2d_bio_of(type,i2d,out,x) (ASN1_i2d_bio(CHECKED_I2D_OF(type, i2d), out, CHECKED_PTR_OF(type, x)))
#define ASN1_i2d_bio_of_const(type,i2d,out,x) (ASN1_i2d_bio(CHECKED_I2D_OF(const type, i2d), out, CHECKED_PTR_OF(const type, x)))
int ASN1_item_i2d_bio(const ASN1_ITEM *it, BIO *out, void *x);
int ASN1_UTCTIME_print(BIO *fp, const ASN1_UTCTIME *a);
int ASN1_GENERALIZEDTIME_print(BIO *fp, const ASN1_GENERALIZEDTIME *a);
int ASN1_TIME_print(BIO *fp, const ASN1_TIME *a);
int ASN1_STRING_print(BIO *bp, const ASN1_STRING *v);
int ASN1_STRING_print_ex(BIO *out, const ASN1_STRING *str, unsigned long flags);
int ASN1_buf_print(BIO *bp, const unsigned char *buf, size_t buflen, int off);
int ASN1_bn_print(BIO *bp, const char *number, const BIGNUM *num,
                  unsigned char *buf, int off);
int ASN1_parse(BIO *bp, const unsigned char *pp, long len, int indent);
int ASN1_parse_dump(BIO *bp, const unsigned char *pp, long len, int indent,
                    int dump);
const char *ASN1_tag2str(int tag);
int ASN1_UNIVERSALSTRING_to_string(ASN1_UNIVERSALSTRING *s);
int ASN1_TYPE_set_octetstring(ASN1_TYPE *a, unsigned char *data, int len);
int ASN1_TYPE_get_octetstring(const ASN1_TYPE *a, unsigned char *data, int max_len);
int ASN1_TYPE_set_int_octetstring(ASN1_TYPE *a, long num,
                                  unsigned char *data, int len);
int ASN1_TYPE_get_int_octetstring(const ASN1_TYPE *a, long *num,
                                  unsigned char *data, int max_len);
void *ASN1_item_unpack(const ASN1_STRING *oct, const ASN1_ITEM *it);
ASN1_STRING *ASN1_item_pack(void *obj, const ASN1_ITEM *it,
                            ASN1_OCTET_STRING **oct);
void ASN1_STRING_set_default_mask(unsigned long mask);
int ASN1_STRING_set_default_mask_asc(const char *p);
unsigned long ASN1_STRING_get_default_mask(void);
int ASN1_mbstring_copy(ASN1_STRING **out, const unsigned char *in, int len,
                       int inform, unsigned long mask);
int ASN1_mbstring_ncopy(ASN1_STRING **out, const unsigned char *in, int len,
                        int inform, unsigned long mask,
                        long minsize, long maxsize);
ASN1_STRING *ASN1_STRING_set_by_NID(ASN1_STRING **out,
                                    const unsigned char *in, int inlen,
                                    int inform, int nid);
ASN1_STRING_TABLE *ASN1_STRING_TABLE_get(int nid);
int ASN1_STRING_TABLE_add(int, long, long, unsigned long, unsigned long);
void ASN1_STRING_TABLE_cleanup(void);
ASN1_VALUE *ASN1_item_new(const ASN1_ITEM *it);
void ASN1_item_free(ASN1_VALUE *val, const ASN1_ITEM *it);
ASN1_VALUE *ASN1_item_d2i(ASN1_VALUE **val, const unsigned char **in,
                          long len, const ASN1_ITEM *it);
int ASN1_item_i2d(ASN1_VALUE *val, unsigned char **out, const ASN1_ITEM *it);
int ASN1_item_ndef_i2d(ASN1_VALUE *val, unsigned char **out,
                       const ASN1_ITEM *it);
void ASN1_add_oid_module(void);
void ASN1_add_stable_module(void);
ASN1_TYPE *ASN1_generate_nconf(const char *str, CONF *nconf);
ASN1_TYPE *ASN1_generate_v3(const char *str, X509V3_CTX *cnf);
int ASN1_str2mask(const char *str, unsigned long *pmask);
enum {
	ASN1_PCTX_FLAGS_SHOW_ABSENT = 0x001,
	ASN1_PCTX_FLAGS_SHOW_SEQUENCE = 0x002,
	ASN1_PCTX_FLAGS_SHOW_SSOF = 0x004,
	ASN1_PCTX_FLAGS_SHOW_TYPE = 0x008,
	ASN1_PCTX_FLAGS_NO_ANY_TYPE = 0x010,
	ASN1_PCTX_FLAGS_NO_MSTRING_TYPE = 0x020,
	ASN1_PCTX_FLAGS_NO_FIELD_NAME = 0x040,
	ASN1_PCTX_FLAGS_SHOW_FIELD_STRUCT_NAME = 0x080,
	ASN1_PCTX_FLAGS_NO_STRUCT_NAME = 0x100,
};
int ASN1_item_print(BIO *out, ASN1_VALUE *ifld, int indent,
                    const ASN1_ITEM *it, const ASN1_PCTX *pctx);
ASN1_PCTX *ASN1_PCTX_new(void);
void ASN1_PCTX_free(ASN1_PCTX *p);
unsigned long ASN1_PCTX_get_flags(const ASN1_PCTX *p);
void ASN1_PCTX_set_flags(ASN1_PCTX *p, unsigned long flags);
unsigned long ASN1_PCTX_get_nm_flags(const ASN1_PCTX *p);
void ASN1_PCTX_set_nm_flags(ASN1_PCTX *p, unsigned long flags);
unsigned long ASN1_PCTX_get_cert_flags(const ASN1_PCTX *p);
void ASN1_PCTX_set_cert_flags(ASN1_PCTX *p, unsigned long flags);
unsigned long ASN1_PCTX_get_oid_flags(const ASN1_PCTX *p);
void ASN1_PCTX_set_oid_flags(ASN1_PCTX *p, unsigned long flags);
unsigned long ASN1_PCTX_get_str_flags(const ASN1_PCTX *p);
void ASN1_PCTX_set_str_flags(ASN1_PCTX *p, unsigned long flags);
ASN1_SCTX *ASN1_SCTX_new(int (*scan_cb) (ASN1_SCTX *ctx));
void ASN1_SCTX_free(ASN1_SCTX *p);
const ASN1_ITEM *ASN1_SCTX_get_item(ASN1_SCTX *p);
const ASN1_TEMPLATE *ASN1_SCTX_get_template(ASN1_SCTX *p);
unsigned long ASN1_SCTX_get_flags(ASN1_SCTX *p);
void ASN1_SCTX_set_app_data(ASN1_SCTX *p, void *data);
void *ASN1_SCTX_get_app_data(ASN1_SCTX *p);
const BIO_METHOD *BIO_f_asn1(void);
BIO *BIO_new_NDEF(BIO *out, ASN1_VALUE *val, const ASN1_ITEM *it);
int i2d_ASN1_bio_stream(BIO *out, ASN1_VALUE *val, BIO *in, int flags,
                        const ASN1_ITEM *it);
int PEM_write_bio_ASN1_stream(BIO *out, ASN1_VALUE *val, BIO *in, int flags,
                              const char *hdr, const ASN1_ITEM *it);
int SMIME_write_ASN1(BIO *bio, ASN1_VALUE *val, BIO *data, int flags,
                     int ctype_nid, int econt_nid,
                     struct stack_st_X509_ALGOR *mdalgs, const ASN1_ITEM *it);
ASN1_VALUE *SMIME_read_ASN1(BIO *bio, BIO **bcont, const ASN1_ITEM *it);
int SMIME_crlf_copy(BIO *in, BIO *out, int flags);
int SMIME_text(BIO *in, BIO *out);
const ASN1_ITEM *ASN1_ITEM_lookup(const char *name);
const ASN1_ITEM *ASN1_ITEM_get(size_t i);

// csrc/openssl/src/include/openssl/asn1err.h
int ERR_load_ASN1_strings(void);
enum {
	ASN1_F_A2D_ASN1_OBJECT = 100,
	ASN1_F_A2I_ASN1_INTEGER = 102,
	ASN1_F_A2I_ASN1_STRING = 103,
	ASN1_F_APPEND_EXP    = 176,
	ASN1_F_ASN1_BIO_INIT = 113,
	ASN1_F_ASN1_BIT_STRING_SET_BIT = 183,
	ASN1_F_ASN1_CB       = 177,
	ASN1_F_ASN1_CHECK_TLEN = 104,
	ASN1_F_ASN1_COLLECT  = 106,
	ASN1_F_ASN1_D2I_EX_PRIMITIVE = 108,
	ASN1_F_ASN1_D2I_FP   = 109,
	ASN1_F_ASN1_D2I_READ_BIO = 107,
	ASN1_F_ASN1_DIGEST   = 184,
	ASN1_F_ASN1_DO_ADB   = 110,
	ASN1_F_ASN1_DO_LOCK  = 233,
	ASN1_F_ASN1_DUP      = 111,
	ASN1_F_ASN1_ENC_SAVE = 115,
	ASN1_F_ASN1_EX_C2I   = 204,
	ASN1_F_ASN1_FIND_END = 190,
	ASN1_F_ASN1_GENERALIZEDTIME_ADJ = 216,
	ASN1_F_ASN1_GENERATE_V3 = 178,
	ASN1_F_ASN1_GET_INT64 = 224,
	ASN1_F_ASN1_GET_OBJECT = 114,
	ASN1_F_ASN1_GET_UINT64 = 225,
	ASN1_F_ASN1_I2D_BIO  = 116,
	ASN1_F_ASN1_I2D_FP   = 117,
	ASN1_F_ASN1_ITEM_D2I_FP = 206,
	ASN1_F_ASN1_ITEM_DUP = 191,
	ASN1_F_ASN1_ITEM_EMBED_D2I = 120,
	ASN1_F_ASN1_ITEM_EMBED_NEW = 121,
	ASN1_F_ASN1_ITEM_FLAGS_I2D = 118,
	ASN1_F_ASN1_ITEM_I2D_BIO = 192,
	ASN1_F_ASN1_ITEM_I2D_FP = 193,
	ASN1_F_ASN1_ITEM_PACK = 198,
	ASN1_F_ASN1_ITEM_SIGN = 195,
	ASN1_F_ASN1_ITEM_SIGN_CTX = 220,
	ASN1_F_ASN1_ITEM_UNPACK = 199,
	ASN1_F_ASN1_ITEM_VERIFY = 197,
	ASN1_F_ASN1_MBSTRING_NCOPY = 122,
	ASN1_F_ASN1_OBJECT_NEW = 123,
	ASN1_F_ASN1_OUTPUT_DATA = 214,
	ASN1_F_ASN1_PCTX_NEW = 205,
	ASN1_F_ASN1_PRIMITIVE_NEW = 119,
	ASN1_F_ASN1_SCTX_NEW = 221,
	ASN1_F_ASN1_SIGN     = 128,
	ASN1_F_ASN1_STR2TYPE = 179,
	ASN1_F_ASN1_STRING_GET_INT64 = 227,
	ASN1_F_ASN1_STRING_GET_UINT64 = 230,
	ASN1_F_ASN1_STRING_SET = 186,
	ASN1_F_ASN1_STRING_TABLE_ADD = 129,
	ASN1_F_ASN1_STRING_TO_BN = 228,
	ASN1_F_ASN1_STRING_TYPE_NEW = 130,
	ASN1_F_ASN1_TEMPLATE_EX_D2I = 132,
	ASN1_F_ASN1_TEMPLATE_NEW = 133,
	ASN1_F_ASN1_TEMPLATE_NOEXP_D2I = 131,
	ASN1_F_ASN1_TIME_ADJ = 217,
	ASN1_F_ASN1_TYPE_GET_INT_OCTETSTRING = 134,
	ASN1_F_ASN1_TYPE_GET_OCTETSTRING = 135,
	ASN1_F_ASN1_UTCTIME_ADJ = 218,
	ASN1_F_ASN1_VERIFY   = 137,
	ASN1_F_B64_READ_ASN1 = 209,
	ASN1_F_B64_WRITE_ASN1 = 210,
	ASN1_F_BIO_NEW_NDEF  = 208,
	ASN1_F_BITSTR_CB     = 180,
	ASN1_F_BN_TO_ASN1_STRING = 229,
	ASN1_F_C2I_ASN1_BIT_STRING = 189,
	ASN1_F_C2I_ASN1_INTEGER = 194,
	ASN1_F_C2I_ASN1_OBJECT = 196,
	ASN1_F_C2I_IBUF      = 226,
	ASN1_F_C2I_UINT64_INT = 101,
	ASN1_F_COLLECT_DATA  = 140,
	ASN1_F_D2I_ASN1_OBJECT = 147,
	ASN1_F_D2I_ASN1_UINTEGER = 150,
	ASN1_F_D2I_AUTOPRIVATEKEY = 207,
	ASN1_F_D2I_PRIVATEKEY = 154,
	ASN1_F_D2I_PUBLICKEY = 155,
	ASN1_F_DO_BUF        = 142,
	ASN1_F_DO_CREATE     = 124,
	ASN1_F_DO_DUMP       = 125,
	ASN1_F_DO_TCREATE    = 222,
	ASN1_F_I2A_ASN1_OBJECT = 126,
	ASN1_F_I2D_ASN1_BIO_STREAM = 211,
	ASN1_F_I2D_ASN1_OBJECT = 143,
	ASN1_F_I2D_DSA_PUBKEY = 161,
	ASN1_F_I2D_EC_PUBKEY = 181,
	ASN1_F_I2D_PRIVATEKEY = 163,
	ASN1_F_I2D_PUBLICKEY = 164,
	ASN1_F_I2D_RSA_PUBKEY = 165,
	ASN1_F_LONG_C2I      = 166,
	ASN1_F_NDEF_PREFIX   = 127,
	ASN1_F_NDEF_SUFFIX   = 136,
	ASN1_F_OID_MODULE_INIT = 174,
	ASN1_F_PARSE_TAGGING = 182,
	ASN1_F_PKCS5_PBE2_SET_IV = 167,
	ASN1_F_PKCS5_PBE2_SET_SCRYPT = 231,
	ASN1_F_PKCS5_PBE_SET = 202,
	ASN1_F_PKCS5_PBE_SET0_ALGOR = 215,
	ASN1_F_PKCS5_PBKDF2_SET = 219,
	ASN1_F_PKCS5_SCRYPT_SET = 232,
	ASN1_F_SMIME_READ_ASN1 = 212,
	ASN1_F_SMIME_TEXT    = 213,
	ASN1_F_STABLE_GET    = 138,
	ASN1_F_STBL_MODULE_INIT = 223,
	ASN1_F_UINT32_C2I    = 105,
	ASN1_F_UINT32_NEW    = 139,
	ASN1_F_UINT64_C2I    = 112,
	ASN1_F_UINT64_NEW    = 141,
	ASN1_F_X509_CRL_ADD0_REVOKED = 169,
	ASN1_F_X509_INFO_NEW = 170,
	ASN1_F_X509_NAME_ENCODE = 203,
	ASN1_F_X509_NAME_EX_D2I = 158,
	ASN1_F_X509_NAME_EX_NEW = 171,
	ASN1_F_X509_PKEY_NEW = 173,
	ASN1_R_ADDING_OBJECT = 171,
	ASN1_R_ASN1_PARSE_ERROR = 203,
	ASN1_R_ASN1_SIG_PARSE_ERROR = 204,
	ASN1_R_AUX_ERROR     = 100,
	ASN1_R_BAD_OBJECT_HEADER = 102,
	ASN1_R_BMPSTRING_IS_WRONG_LENGTH = 214,
	ASN1_R_BN_LIB        = 105,
	ASN1_R_BOOLEAN_IS_WRONG_LENGTH = 106,
	ASN1_R_BUFFER_TOO_SMALL = 107,
	ASN1_R_CIPHER_HAS_NO_OBJECT_IDENTIFIER = 108,
	ASN1_R_CONTEXT_NOT_INITIALISED = 217,
	ASN1_R_DATA_IS_WRONG = 109,
	ASN1_R_DECODE_ERROR  = 110,
	ASN1_R_DEPTH_EXCEEDED = 174,
	ASN1_R_DIGEST_AND_KEY_TYPE_NOT_SUPPORTED = 198,
	ASN1_R_ENCODE_ERROR  = 112,
	ASN1_R_ERROR_GETTING_TIME = 173,
	ASN1_R_ERROR_LOADING_SECTION = 172,
	ASN1_R_ERROR_SETTING_CIPHER_PARAMS = 114,
	ASN1_R_EXPECTING_AN_INTEGER = 115,
	ASN1_R_EXPECTING_AN_OBJECT = 116,
	ASN1_R_EXPLICIT_LENGTH_MISMATCH = 119,
	ASN1_R_EXPLICIT_TAG_NOT_CONSTRUCTED = 120,
	ASN1_R_FIELD_MISSING = 121,
	ASN1_R_FIRST_NUM_TOO_LARGE = 122,
	ASN1_R_HEADER_TOO_LONG = 123,
	ASN1_R_ILLEGAL_BITSTRING_FORMAT = 175,
	ASN1_R_ILLEGAL_BOOLEAN = 176,
	ASN1_R_ILLEGAL_CHARACTERS = 124,
	ASN1_R_ILLEGAL_FORMAT = 177,
	ASN1_R_ILLEGAL_HEX   = 178,
	ASN1_R_ILLEGAL_IMPLICIT_TAG = 179,
	ASN1_R_ILLEGAL_INTEGER = 180,
	ASN1_R_ILLEGAL_NEGATIVE_VALUE = 226,
	ASN1_R_ILLEGAL_NESTED_TAGGING = 181,
	ASN1_R_ILLEGAL_NULL  = 125,
	ASN1_R_ILLEGAL_NULL_VALUE = 182,
	ASN1_R_ILLEGAL_OBJECT = 183,
	ASN1_R_ILLEGAL_OPTIONAL_ANY = 126,
	ASN1_R_ILLEGAL_OPTIONS_ON_ITEM_TEMPLATE = 170,
	ASN1_R_ILLEGAL_PADDING = 221,
	ASN1_R_ILLEGAL_TAGGED_ANY = 127,
	ASN1_R_ILLEGAL_TIME_VALUE = 184,
	ASN1_R_ILLEGAL_ZERO_CONTENT = 222,
	ASN1_R_INTEGER_NOT_ASCII_FORMAT = 185,
	ASN1_R_INTEGER_TOO_LARGE_FOR_LONG = 128,
	ASN1_R_INVALID_BIT_STRING_BITS_LEFT = 220,
	ASN1_R_INVALID_BMPSTRING_LENGTH = 129,
	ASN1_R_INVALID_DIGIT = 130,
	ASN1_R_INVALID_MIME_TYPE = 205,
	ASN1_R_INVALID_MODIFIER = 186,
	ASN1_R_INVALID_NUMBER = 187,
	ASN1_R_INVALID_OBJECT_ENCODING = 216,
	ASN1_R_INVALID_SCRYPT_PARAMETERS = 227,
	ASN1_R_INVALID_SEPARATOR = 131,
	ASN1_R_INVALID_STRING_TABLE_VALUE = 218,
	ASN1_R_INVALID_UNIVERSALSTRING_LENGTH = 133,
	ASN1_R_INVALID_UTF8STRING = 134,
	ASN1_R_INVALID_VALUE = 219,
	ASN1_R_LIST_ERROR    = 188,
	ASN1_R_MIME_NO_CONTENT_TYPE = 206,
	ASN1_R_MIME_PARSE_ERROR = 207,
	ASN1_R_MIME_SIG_PARSE_ERROR = 208,
	ASN1_R_MISSING_EOC   = 137,
	ASN1_R_MISSING_SECOND_NUMBER = 138,
	ASN1_R_MISSING_VALUE = 189,
	ASN1_R_MSTRING_NOT_UNIVERSAL = 139,
	ASN1_R_MSTRING_WRONG_TAG = 140,
	ASN1_R_NESTED_ASN1_STRING = 197,
	ASN1_R_NESTED_TOO_DEEP = 201,
	ASN1_R_NON_HEX_CHARACTERS = 141,
	ASN1_R_NOT_ASCII_FORMAT = 190,
	ASN1_R_NOT_ENOUGH_DATA = 142,
	ASN1_R_NO_CONTENT_TYPE = 209,
	ASN1_R_NO_MATCHING_CHOICE_TYPE = 143,
	ASN1_R_NO_MULTIPART_BODY_FAILURE = 210,
	ASN1_R_NO_MULTIPART_BOUNDARY = 211,
	ASN1_R_NO_SIG_CONTENT_TYPE = 212,
	ASN1_R_NULL_IS_WRONG_LENGTH = 144,
	ASN1_R_OBJECT_NOT_ASCII_FORMAT = 191,
	ASN1_R_ODD_NUMBER_OF_CHARS = 145,
	ASN1_R_SECOND_NUMBER_TOO_LARGE = 147,
	ASN1_R_SEQUENCE_LENGTH_MISMATCH = 148,
	ASN1_R_SEQUENCE_NOT_CONSTRUCTED = 149,
	ASN1_R_SEQUENCE_OR_SET_NEEDS_CONFIG = 192,
	ASN1_R_SHORT_LINE    = 150,
	ASN1_R_SIG_INVALID_MIME_TYPE = 213,
	ASN1_R_STREAMING_NOT_SUPPORTED = 202,
	ASN1_R_STRING_TOO_LONG = 151,
	ASN1_R_STRING_TOO_SHORT = 152,
	ASN1_R_THE_ASN1_OBJECT_IDENTIFIER_IS_NOT_KNOWN_FOR_THIS_MD = 154,
	ASN1_R_TIME_NOT_ASCII_FORMAT = 193,
	ASN1_R_TOO_LARGE     = 223,
	ASN1_R_TOO_LONG      = 155,
	ASN1_R_TOO_SMALL     = 224,
	ASN1_R_TYPE_NOT_CONSTRUCTED = 156,
	ASN1_R_TYPE_NOT_PRIMITIVE = 195,
	ASN1_R_UNEXPECTED_EOC = 159,
	ASN1_R_UNIVERSALSTRING_IS_WRONG_LENGTH = 215,
	ASN1_R_UNKNOWN_FORMAT = 160,
	ASN1_R_UNKNOWN_MESSAGE_DIGEST_ALGORITHM = 161,
	ASN1_R_UNKNOWN_OBJECT_TYPE = 162,
	ASN1_R_UNKNOWN_PUBLIC_KEY_TYPE = 163,
	ASN1_R_UNKNOWN_SIGNATURE_ALGORITHM = 199,
	ASN1_R_UNKNOWN_TAG   = 194,
	ASN1_R_UNSUPPORTED_ANY_DEFINED_BY_TYPE = 164,
	ASN1_R_UNSUPPORTED_CIPHER = 228,
	ASN1_R_UNSUPPORTED_PUBLIC_KEY_TYPE = 167,
	ASN1_R_UNSUPPORTED_TYPE = 196,
	ASN1_R_WRONG_INTEGER_TYPE = 225,
	ASN1_R_WRONG_PUBLIC_KEY_TYPE = 200,
	ASN1_R_WRONG_TAG     = 168,
};
