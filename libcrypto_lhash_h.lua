local ffi = require'ffi'
--[[
// csrc/openssl/src/include/openssl/lhash.h
typedef struct lhash_node_st OPENSSL_LH_NODE;
typedef int (*OPENSSL_LH_COMPFUNC) (const void *, const void *);
typedef unsigned long (*OPENSSL_LH_HASHFUNC) (const void *);
typedef void (*OPENSSL_LH_DOALL_FUNC) (void *);
typedef void (*OPENSSL_LH_DOALL_FUNCARG) (void *, void *);
typedef struct lhash_st OPENSSL_LHASH;
#define DECLARE_LHASH_HASH_FN(name,o_type) unsigned long name ##_LHASH_HASH(const void *);
#define IMPLEMENT_LHASH_HASH_FN(name,o_type) unsigned long name ##_LHASH_HASH(const void *arg) { const o_type *a = arg; return name ##_hash(a); }
#define LHASH_HASH_FN(name) name ##_LHASH_HASH
#define DECLARE_LHASH_COMP_FN(name,o_type) int name ##_LHASH_COMP(const void *, const void *);
#define IMPLEMENT_LHASH_COMP_FN(name,o_type) int name ##_LHASH_COMP(const void *arg1, const void *arg2) { const o_type *a = arg1; const o_type *b = arg2; return name ##_cmp(a,b); }
#define LHASH_COMP_FN(name) name ##_LHASH_COMP
#define DECLARE_LHASH_DOALL_ARG_FN(name,o_type,a_type) void name ##_LHASH_DOALL_ARG(void *, void *);
#define IMPLEMENT_LHASH_DOALL_ARG_FN(name,o_type,a_type) void name ##_LHASH_DOALL_ARG(void *arg1, void *arg2) { o_type *a = arg1; a_type *b = arg2; name ##_doall_arg(a, b); }
#define LHASH_DOALL_ARG_FN(name) name ##_LHASH_DOALL_ARG
enum {
	LH_LOAD_MULT         = 256,
};
int OPENSSL_LH_error(OPENSSL_LHASH *lh);
OPENSSL_LHASH *OPENSSL_LH_new(OPENSSL_LH_HASHFUNC h, OPENSSL_LH_COMPFUNC c);
void OPENSSL_LH_free(OPENSSL_LHASH *lh);
void *OPENSSL_LH_insert(OPENSSL_LHASH *lh, void *data);
void *OPENSSL_LH_delete(OPENSSL_LHASH *lh, const void *data);
void *OPENSSL_LH_retrieve(OPENSSL_LHASH *lh, const void *data);
void OPENSSL_LH_doall(OPENSSL_LHASH *lh, OPENSSL_LH_DOALL_FUNC func);
void OPENSSL_LH_doall_arg(OPENSSL_LHASH *lh, OPENSSL_LH_DOALL_FUNCARG func, void *arg);
unsigned long OPENSSL_LH_strhash(const char *c);
unsigned long OPENSSL_LH_num_items(const OPENSSL_LHASH *lh);
unsigned long OPENSSL_LH_get_down_load(const OPENSSL_LHASH *lh);
void OPENSSL_LH_set_down_load(OPENSSL_LHASH *lh, unsigned long down_load);
void OPENSSL_LH_stats(const OPENSSL_LHASH *lh, FILE *fp);
void OPENSSL_LH_node_stats(const OPENSSL_LHASH *lh, FILE *fp);
void OPENSSL_LH_node_usage_stats(const OPENSSL_LHASH *lh, FILE *fp);
void OPENSSL_LH_stats_bio(const OPENSSL_LHASH *lh, BIO *out);
void OPENSSL_LH_node_stats_bio(const OPENSSL_LHASH *lh, BIO *out);
void OPENSSL_LH_node_usage_stats_bio(const OPENSSL_LHASH *lh, BIO *out);
enum {
	_LHASH               = OPENSSL_LHASH,
	LHASH_NODE           = OPENSSL_LH_NODE,
	lh_error             = OPENSSL_LH_error,
	lh_new               = OPENSSL_LH_new,
	lh_free              = OPENSSL_LH_free,
	lh_insert            = OPENSSL_LH_insert,
	lh_delete            = OPENSSL_LH_delete,
	lh_retrieve          = OPENSSL_LH_retrieve,
	lh_doall             = OPENSSL_LH_doall,
	lh_doall_arg         = OPENSSL_LH_doall_arg,
	lh_strhash           = OPENSSL_LH_strhash,
	lh_num_items         = OPENSSL_LH_num_items,
	lh_stats             = OPENSSL_LH_stats,
	lh_node_stats        = OPENSSL_LH_node_stats,
	lh_node_usage_stats  = OPENSSL_LH_node_usage_stats,
	lh_stats_bio         = OPENSSL_LH_stats_bio,
	lh_node_stats_bio    = OPENSSL_LH_node_stats_bio,
	lh_node_usage_stats_bio = OPENSSL_LH_node_usage_stats_bio,
};
#define LHASH_OF(type) struct lhash_st_ ##type
#define DEFINE_LHASH_OF(type) LHASH_OF(type) { union lh_ ##type ##_dummy { void* d1; unsigned long d2; int d3; } dummy; }; static ossl_inline LHASH_OF(type) * lh_ ##type ##_new(unsigned long (*hfn)(const type *), int (*cfn)(const type *, const type *)) { return (LHASH_OF(type) *) OPENSSL_LH_new((OPENSSL_LH_HASHFUNC)hfn, (OPENSSL_LH_COMPFUNC)cfn); } static ossl_unused ossl_inline void lh_ ##type ##_free(LHASH_OF(type) *lh) { OPENSSL_LH_free((OPENSSL_LHASH *)lh); } static ossl_unused ossl_inline type *lh_ ##type ##_insert(LHASH_OF(type) *lh, type *d) { return (type *)OPENSSL_LH_insert((OPENSSL_LHASH *)lh, d); } static ossl_unused ossl_inline type *lh_ ##type ##_delete(LHASH_OF(type) *lh, const type *d) { return (type *)OPENSSL_LH_delete((OPENSSL_LHASH *)lh, d); } static ossl_unused ossl_inline type *lh_ ##type ##_retrieve(LHASH_OF(type) *lh, const type *d) { return (type *)OPENSSL_LH_retrieve((OPENSSL_LHASH *)lh, d); } static ossl_unused ossl_inline int lh_ ##type ##_error(LHASH_OF(type) *lh) { return OPENSSL_LH_error((OPENSSL_LHASH *)lh); } static ossl_unused ossl_inline unsigned long lh_ ##type ##_num_items(LHASH_OF(type) *lh) { return OPENSSL_LH_num_items((OPENSSL_LHASH *)lh); } static ossl_unused ossl_inline void lh_ ##type ##_node_stats_bio(const LHASH_OF(type) *lh, BIO *out) { OPENSSL_LH_node_stats_bio((const OPENSSL_LHASH *)lh, out); } static ossl_unused ossl_inline void lh_ ##type ##_node_usage_stats_bio(const LHASH_OF(type) *lh, BIO *out) { OPENSSL_LH_node_usage_stats_bio((const OPENSSL_LHASH *)lh, out); } static ossl_unused ossl_inline void lh_ ##type ##_stats_bio(const LHASH_OF(type) *lh, BIO *out) { OPENSSL_LH_stats_bio((const OPENSSL_LHASH *)lh, out); } static ossl_unused ossl_inline unsigned long lh_ ##type ##_get_down_load(LHASH_OF(type) *lh) { return OPENSSL_LH_get_down_load((OPENSSL_LHASH *)lh); } static ossl_unused ossl_inline void lh_ ##type ##_set_down_load(LHASH_OF(type) *lh, unsigned long dl) { OPENSSL_LH_set_down_load((OPENSSL_LHASH *)lh, dl); } static ossl_unused ossl_inline void lh_ ##type ##_doall(LHASH_OF(type) *lh, void (*doall)(type *)) { OPENSSL_LH_doall((OPENSSL_LHASH *)lh, (OPENSSL_LH_DOALL_FUNC)doall); } LHASH_OF(type)
#define IMPLEMENT_LHASH_DOALL_ARG_CONST(type,argtype) int_implement_lhash_doall(type, argtype, const type)
#define IMPLEMENT_LHASH_DOALL_ARG(type,argtype) int_implement_lhash_doall(type, argtype, type)
#define int_implement_lhash_doall(type,argtype,cbargtype) static ossl_unused ossl_inline void lh_ ##type ##_doall_ ##argtype(LHASH_OF(type) *lh, void (*fn)(cbargtype *, argtype *), argtype *arg) { OPENSSL_LH_doall_arg((OPENSSL_LHASH *)lh, (OPENSSL_LH_DOALL_FUNCARG)fn, (void *)arg); } LHASH_OF(type)
struct lhash_st_OPENSSL_STRING { union lh_OPENSSL_STRING_dummy { void* d1; unsigned long d2; int d3; } dummy; }; static inline struct lhash_st_OPENSSL_STRING * lh_OPENSSL_STRING_new(unsigned long (*hfn)(const OPENSSL_STRING *), int (*cfn)(const OPENSSL_STRING *, const OPENSSL_STRING *)) { return (struct lhash_st_OPENSSL_STRING *) OPENSSL_LH_new((OPENSSL_LH_HASHFUNC)hfn, (OPENSSL_LH_COMPFUNC)cfn); } static __attribute__((unused)) inline void lh_OPENSSL_STRING_free(struct lhash_st_OPENSSL_STRING *lh) { OPENSSL_LH_free((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline OPENSSL_STRING *lh_OPENSSL_STRING_insert(struct lhash_st_OPENSSL_STRING *lh, OPENSSL_STRING *d) { return (OPENSSL_STRING *)OPENSSL_LH_insert((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline OPENSSL_STRING *lh_OPENSSL_STRING_delete(struct lhash_st_OPENSSL_STRING *lh, const OPENSSL_STRING *d) { return (OPENSSL_STRING *)OPENSSL_LH_delete((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline OPENSSL_STRING *lh_OPENSSL_STRING_retrieve(struct lhash_st_OPENSSL_STRING *lh, const OPENSSL_STRING *d) { return (OPENSSL_STRING *)OPENSSL_LH_retrieve((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline int lh_OPENSSL_STRING_error(struct lhash_st_OPENSSL_STRING *lh) { return OPENSSL_LH_error((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline unsigned long lh_OPENSSL_STRING_num_items(struct lhash_st_OPENSSL_STRING *lh) { return OPENSSL_LH_num_items((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline void lh_OPENSSL_STRING_node_stats_bio(const struct lhash_st_OPENSSL_STRING *lh, BIO *out) { OPENSSL_LH_node_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline void lh_OPENSSL_STRING_node_usage_stats_bio(const struct lhash_st_OPENSSL_STRING *lh, BIO *out) { OPENSSL_LH_node_usage_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline void lh_OPENSSL_STRING_stats_bio(const struct lhash_st_OPENSSL_STRING *lh, BIO *out) { OPENSSL_LH_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline unsigned long lh_OPENSSL_STRING_get_down_load(struct lhash_st_OPENSSL_STRING *lh) { return OPENSSL_LH_get_down_load((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline void lh_OPENSSL_STRING_set_down_load(struct lhash_st_OPENSSL_STRING *lh, unsigned long dl) { OPENSSL_LH_set_down_load((OPENSSL_LHASH *)lh, dl); } static __attribute__((unused)) inline void lh_OPENSSL_STRING_doall(struct lhash_st_OPENSSL_STRING *lh, void (*doall)(OPENSSL_STRING *)) { OPENSSL_LH_doall((OPENSSL_LHASH *)lh, (OPENSSL_LH_DOALL_FUNC)doall); } struct lhash_st_OPENSSL_STRING;
struct lhash_st_OPENSSL_CSTRING { union lh_OPENSSL_CSTRING_dummy { void* d1; unsigned long d2; int d3; } dummy; }; static inline struct lhash_st_OPENSSL_CSTRING * lh_OPENSSL_CSTRING_new(unsigned long (*hfn)(const OPENSSL_CSTRING *), int (*cfn)(const OPENSSL_CSTRING *, const OPENSSL_CSTRING *)) { return (struct lhash_st_OPENSSL_CSTRING *) OPENSSL_LH_new((OPENSSL_LH_HASHFUNC)hfn, (OPENSSL_LH_COMPFUNC)cfn); } static __attribute__((unused)) inline void lh_OPENSSL_CSTRING_free(struct lhash_st_OPENSSL_CSTRING *lh) { OPENSSL_LH_free((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline OPENSSL_CSTRING *lh_OPENSSL_CSTRING_insert(struct lhash_st_OPENSSL_CSTRING *lh, OPENSSL_CSTRING *d) { return (OPENSSL_CSTRING *)OPENSSL_LH_insert((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline OPENSSL_CSTRING *lh_OPENSSL_CSTRING_delete(struct lhash_st_OPENSSL_CSTRING *lh, const OPENSSL_CSTRING *d) { return (OPENSSL_CSTRING *)OPENSSL_LH_delete((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline OPENSSL_CSTRING *lh_OPENSSL_CSTRING_retrieve(struct lhash_st_OPENSSL_CSTRING *lh, const OPENSSL_CSTRING *d) { return (OPENSSL_CSTRING *)OPENSSL_LH_retrieve((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline int lh_OPENSSL_CSTRING_error(struct lhash_st_OPENSSL_CSTRING *lh) { return OPENSSL_LH_error((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline unsigned long lh_OPENSSL_CSTRING_num_items(struct lhash_st_OPENSSL_CSTRING *lh) { return OPENSSL_LH_num_items((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline void lh_OPENSSL_CSTRING_node_stats_bio(const struct lhash_st_OPENSSL_CSTRING *lh, BIO *out) { OPENSSL_LH_node_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline void lh_OPENSSL_CSTRING_node_usage_stats_bio(const struct lhash_st_OPENSSL_CSTRING *lh, BIO *out) { OPENSSL_LH_node_usage_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline void lh_OPENSSL_CSTRING_stats_bio(const struct lhash_st_OPENSSL_CSTRING *lh, BIO *out) { OPENSSL_LH_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline unsigned long lh_OPENSSL_CSTRING_get_down_load(struct lhash_st_OPENSSL_CSTRING *lh) { return OPENSSL_LH_get_down_load((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline void lh_OPENSSL_CSTRING_set_down_load(struct lhash_st_OPENSSL_CSTRING *lh, unsigned long dl) { OPENSSL_LH_set_down_load((OPENSSL_LHASH *)lh, dl); } static __attribute__((unused)) inline void lh_OPENSSL_CSTRING_doall(struct lhash_st_OPENSSL_CSTRING *lh, void (*doall)(OPENSSL_CSTRING *)) { OPENSSL_LH_doall((OPENSSL_LHASH *)lh, (OPENSSL_LH_DOALL_FUNC)doall); } struct lhash_st_OPENSSL_CSTRING;
]]
