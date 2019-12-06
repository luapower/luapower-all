// csrc/openssl/src/include/openssl/err.h
#define ERR_PUT_error(a,b,c,d,e) ERR_put_error(a,b,c,d,e)
enum {
	ERR_TXT_MALLOCED     = 0x01,
	ERR_TXT_STRING       = 0x02,
	ERR_FLAG_MARK        = 0x01,
	ERR_FLAG_CLEAR       = 0x02,
	ERR_NUM_ERRORS       = 16,
};
typedef struct err_state_st {
    int err_flags[16];
    unsigned long err_buffer[16];
    char *err_data[16];
    int err_data_flags[16];
    const char *err_file[16];
    int err_line[16];
    int top, bottom;
} ERR_STATE;
enum {
	ERR_LIB_NONE         = 1,
	ERR_LIB_SYS          = 2,
	ERR_LIB_BN           = 3,
	ERR_LIB_RSA          = 4,
	ERR_LIB_DH           = 5,
	ERR_LIB_EVP          = 6,
	ERR_LIB_BUF          = 7,
	ERR_LIB_OBJ          = 8,
	ERR_LIB_PEM          = 9,
	ERR_LIB_DSA          = 10,
	ERR_LIB_X509         = 11,
	ERR_LIB_ASN1         = 13,
	ERR_LIB_CONF         = 14,
	ERR_LIB_CRYPTO       = 15,
	ERR_LIB_EC           = 16,
	ERR_LIB_SSL          = 20,
	ERR_LIB_BIO          = 32,
	ERR_LIB_PKCS7        = 33,
	ERR_LIB_X509V3       = 34,
	ERR_LIB_PKCS12       = 35,
	ERR_LIB_RAND         = 36,
	ERR_LIB_DSO          = 37,
	ERR_LIB_ENGINE       = 38,
	ERR_LIB_OCSP         = 39,
	ERR_LIB_UI           = 40,
	ERR_LIB_COMP         = 41,
	ERR_LIB_ECDSA        = 42,
	ERR_LIB_ECDH         = 43,
	ERR_LIB_OSSL_STORE   = 44,
	ERR_LIB_FIPS         = 45,
	ERR_LIB_CMS          = 46,
	ERR_LIB_TS           = 47,
	ERR_LIB_HMAC         = 48,
	ERR_LIB_CT           = 50,
	ERR_LIB_ASYNC        = 51,
	ERR_LIB_KDF          = 52,
	ERR_LIB_SM2          = 53,
	ERR_LIB_USER         = 128,
};
#define SYSerr(f,r) ERR_PUT_error(ERR_LIB_SYS,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define BNerr(f,r) ERR_PUT_error(ERR_LIB_BN,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define RSAerr(f,r) ERR_PUT_error(ERR_LIB_RSA,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define DHerr(f,r) ERR_PUT_error(ERR_LIB_DH,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define EVPerr(f,r) ERR_PUT_error(ERR_LIB_EVP,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define BUFerr(f,r) ERR_PUT_error(ERR_LIB_BUF,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define OBJerr(f,r) ERR_PUT_error(ERR_LIB_OBJ,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define PEMerr(f,r) ERR_PUT_error(ERR_LIB_PEM,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define DSAerr(f,r) ERR_PUT_error(ERR_LIB_DSA,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define X509err(f,r) ERR_PUT_error(ERR_LIB_X509,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ASN1err(f,r) ERR_PUT_error(ERR_LIB_ASN1,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define CONFerr(f,r) ERR_PUT_error(ERR_LIB_CONF,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define CRYPTOerr(f,r) ERR_PUT_error(ERR_LIB_CRYPTO,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ECerr(f,r) ERR_PUT_error(ERR_LIB_EC,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define SSLerr(f,r) ERR_PUT_error(ERR_LIB_SSL,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define BIOerr(f,r) ERR_PUT_error(ERR_LIB_BIO,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define PKCS7err(f,r) ERR_PUT_error(ERR_LIB_PKCS7,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define X509V3err(f,r) ERR_PUT_error(ERR_LIB_X509V3,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define PKCS12err(f,r) ERR_PUT_error(ERR_LIB_PKCS12,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define RANDerr(f,r) ERR_PUT_error(ERR_LIB_RAND,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define DSOerr(f,r) ERR_PUT_error(ERR_LIB_DSO,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ENGINEerr(f,r) ERR_PUT_error(ERR_LIB_ENGINE,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define OCSPerr(f,r) ERR_PUT_error(ERR_LIB_OCSP,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define UIerr(f,r) ERR_PUT_error(ERR_LIB_UI,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define COMPerr(f,r) ERR_PUT_error(ERR_LIB_COMP,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ECDSAerr(f,r) ERR_PUT_error(ERR_LIB_ECDSA,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ECDHerr(f,r) ERR_PUT_error(ERR_LIB_ECDH,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define OSSL_STOREerr(f,r) ERR_PUT_error(ERR_LIB_OSSL_STORE,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define FIPSerr(f,r) ERR_PUT_error(ERR_LIB_FIPS,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define CMSerr(f,r) ERR_PUT_error(ERR_LIB_CMS,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define TSerr(f,r) ERR_PUT_error(ERR_LIB_TS,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define HMACerr(f,r) ERR_PUT_error(ERR_LIB_HMAC,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define CTerr(f,r) ERR_PUT_error(ERR_LIB_CT,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ASYNCerr(f,r) ERR_PUT_error(ERR_LIB_ASYNC,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define KDFerr(f,r) ERR_PUT_error(ERR_LIB_KDF,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define SM2err(f,r) ERR_PUT_error(ERR_LIB_SM2,(f),(r),OPENSSL_FILE,OPENSSL_LINE)
#define ERR_PACK(l,f,r) ( (((unsigned int)(l) & 0x0FF) << 24L) | (((unsigned int)(f) & 0xFFF) << 12L) | (((unsigned int)(r) & 0xFFF) ) )
#define ERR_GET_LIB(l) (int)(((l) >> 24L) & 0x0FFL)
#define ERR_GET_FUNC(l) (int)(((l) >> 12L) & 0xFFFL)
#define ERR_GET_REASON(l) (int)( (l) & 0xFFFL)
#define ERR_FATAL_ERROR(l) (int)( (l) & ERR_R_FATAL)
enum {
	SYS_F_FOPEN          = 1,
	SYS_F_CONNECT        = 2,
	SYS_F_GETSERVBYNAME  = 3,
	SYS_F_SOCKET         = 4,
	SYS_F_IOCTLSOCKET    = 5,
	SYS_F_BIND           = 6,
	SYS_F_LISTEN         = 7,
	SYS_F_ACCEPT         = 8,
	SYS_F_WSASTARTUP     = 9,
	SYS_F_OPENDIR        = 10,
	SYS_F_FREAD          = 11,
	SYS_F_GETADDRINFO    = 12,
	SYS_F_GETNAMEINFO    = 13,
	SYS_F_SETSOCKOPT     = 14,
	SYS_F_GETSOCKOPT     = 15,
	SYS_F_GETSOCKNAME    = 16,
	SYS_F_GETHOSTBYNAME  = 17,
	SYS_F_FFLUSH         = 18,
	SYS_F_OPEN           = 19,
	SYS_F_CLOSE          = 20,
	SYS_F_IOCTL          = 21,
	SYS_F_STAT           = 22,
	SYS_F_FCNTL          = 23,
	SYS_F_FSTAT          = 24,
	ERR_R_SYS_LIB        = ERR_LIB_SYS,
	ERR_R_BN_LIB         = ERR_LIB_BN,
	ERR_R_RSA_LIB        = ERR_LIB_RSA,
	ERR_R_DH_LIB         = ERR_LIB_DH,
	ERR_R_EVP_LIB        = ERR_LIB_EVP,
	ERR_R_BUF_LIB        = ERR_LIB_BUF,
	ERR_R_OBJ_LIB        = ERR_LIB_OBJ,
	ERR_R_PEM_LIB        = ERR_LIB_PEM,
	ERR_R_DSA_LIB        = ERR_LIB_DSA,
	ERR_R_X509_LIB       = ERR_LIB_X509,
	ERR_R_ASN1_LIB       = ERR_LIB_ASN1,
	ERR_R_EC_LIB         = ERR_LIB_EC,
	ERR_R_BIO_LIB        = ERR_LIB_BIO,
	ERR_R_PKCS7_LIB      = ERR_LIB_PKCS7,
	ERR_R_X509V3_LIB     = ERR_LIB_X509V3,
	ERR_R_ENGINE_LIB     = ERR_LIB_ENGINE,
	ERR_R_UI_LIB         = ERR_LIB_UI,
	ERR_R_ECDSA_LIB      = ERR_LIB_ECDSA,
	ERR_R_OSSL_STORE_LIB = ERR_LIB_OSSL_STORE,
	ERR_R_NESTED_ASN1_ERROR = 58,
	ERR_R_MISSING_ASN1_EOS = 63,
	ERR_R_FATAL          = 64,
	ERR_R_MALLOC_FAILURE = (1|ERR_R_FATAL),
	ERR_R_SHOULD_NOT_HAVE_BEEN_CALLED = (2|ERR_R_FATAL),
	ERR_R_PASSED_NULL_PARAMETER = (3|ERR_R_FATAL),
	ERR_R_INTERNAL_ERROR = (4|ERR_R_FATAL),
	ERR_R_DISABLED       = (5|ERR_R_FATAL),
	ERR_R_INIT_FAIL      = (6|ERR_R_FATAL),
	ERR_R_PASSED_INVALID_ARGUMENT = (7),
	ERR_R_OPERATION_FAIL = (8|ERR_R_FATAL),
};
typedef struct ERR_string_data_st {
    unsigned long error;
    const char *string;
} ERR_STRING_DATA;
struct lhash_st_ERR_STRING_DATA { union lh_ERR_STRING_DATA_dummy { void* d1; unsigned long d2; int d3; } dummy; }; static inline struct lhash_st_ERR_STRING_DATA * lh_ERR_STRING_DATA_new(unsigned long (*hfn)(const ERR_STRING_DATA *), int (*cfn)(const ERR_STRING_DATA *, const ERR_STRING_DATA *)) { return (struct lhash_st_ERR_STRING_DATA *) OPENSSL_LH_new((OPENSSL_LH_HASHFUNC)hfn, (OPENSSL_LH_COMPFUNC)cfn); } static __attribute__((unused)) inline void lh_ERR_STRING_DATA_free(struct lhash_st_ERR_STRING_DATA *lh) { OPENSSL_LH_free((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline ERR_STRING_DATA *lh_ERR_STRING_DATA_insert(struct lhash_st_ERR_STRING_DATA *lh, ERR_STRING_DATA *d) { return (ERR_STRING_DATA *)OPENSSL_LH_insert((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline ERR_STRING_DATA *lh_ERR_STRING_DATA_delete(struct lhash_st_ERR_STRING_DATA *lh, const ERR_STRING_DATA *d) { return (ERR_STRING_DATA *)OPENSSL_LH_delete((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline ERR_STRING_DATA *lh_ERR_STRING_DATA_retrieve(struct lhash_st_ERR_STRING_DATA *lh, const ERR_STRING_DATA *d) { return (ERR_STRING_DATA *)OPENSSL_LH_retrieve((OPENSSL_LHASH *)lh, d); } static __attribute__((unused)) inline int lh_ERR_STRING_DATA_error(struct lhash_st_ERR_STRING_DATA *lh) { return OPENSSL_LH_error((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline unsigned long lh_ERR_STRING_DATA_num_items(struct lhash_st_ERR_STRING_DATA *lh) { return OPENSSL_LH_num_items((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline void lh_ERR_STRING_DATA_node_stats_bio(const struct lhash_st_ERR_STRING_DATA *lh, BIO *out) { OPENSSL_LH_node_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline void lh_ERR_STRING_DATA_node_usage_stats_bio(const struct lhash_st_ERR_STRING_DATA *lh, BIO *out) { OPENSSL_LH_node_usage_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline void lh_ERR_STRING_DATA_stats_bio(const struct lhash_st_ERR_STRING_DATA *lh, BIO *out) { OPENSSL_LH_stats_bio((const OPENSSL_LHASH *)lh, out); } static __attribute__((unused)) inline unsigned long lh_ERR_STRING_DATA_get_down_load(struct lhash_st_ERR_STRING_DATA *lh) { return OPENSSL_LH_get_down_load((OPENSSL_LHASH *)lh); } static __attribute__((unused)) inline void lh_ERR_STRING_DATA_set_down_load(struct lhash_st_ERR_STRING_DATA *lh, unsigned long dl) { OPENSSL_LH_set_down_load((OPENSSL_LHASH *)lh, dl); } static __attribute__((unused)) inline void lh_ERR_STRING_DATA_doall(struct lhash_st_ERR_STRING_DATA *lh, void (*doall)(ERR_STRING_DATA *)) { OPENSSL_LH_doall((OPENSSL_LHASH *)lh, (OPENSSL_LH_DOALL_FUNC)doall); } struct lhash_st_ERR_STRING_DATA;
void ERR_put_error(int lib, int func, int reason, const char *file, int line);
void ERR_set_error_data(char *data, int flags);
unsigned long ERR_get_error(void);
unsigned long ERR_get_error_line(const char **file, int *line);
unsigned long ERR_get_error_line_data(const char **file, int *line,
                                      const char **data, int *flags);
unsigned long ERR_peek_error(void);
unsigned long ERR_peek_error_line(const char **file, int *line);
unsigned long ERR_peek_error_line_data(const char **file, int *line,
                                       const char **data, int *flags);
unsigned long ERR_peek_last_error(void);
unsigned long ERR_peek_last_error_line(const char **file, int *line);
unsigned long ERR_peek_last_error_line_data(const char **file, int *line,
                                            const char **data, int *flags);
void ERR_clear_error(void);
char *ERR_error_string(unsigned long e, char *buf);
void ERR_error_string_n(unsigned long e, char *buf, size_t len);
const char *ERR_lib_error_string(unsigned long e);
const char *ERR_func_error_string(unsigned long e);
const char *ERR_reason_error_string(unsigned long e);
void ERR_print_errors_cb(int (*cb) (const char *str, size_t len, void *u),
                         void *u);
void ERR_print_errors_fp(FILE *fp);
void ERR_print_errors(BIO *bp);
void ERR_add_error_data(int num, ...);
void ERR_add_error_vdata(int num, va_list args);
int ERR_load_strings(int lib, ERR_STRING_DATA *str);
int ERR_load_strings_const(const ERR_STRING_DATA *str);
int ERR_unload_strings(int lib, ERR_STRING_DATA *str);
int ERR_load_ERR_strings(void);
#define ERR_load_crypto_strings() OPENSSL_init_crypto(OPENSSL_INIT_LOAD_CRYPTO_STRINGS, NULL)
#define ERR_free_strings() while(0) continue
void ERR_remove_thread_state(void *) __attribute__ ((deprecated));
void ERR_remove_state(unsigned long pid) __attribute__ ((deprecated));
ERR_STATE *ERR_get_state(void);
int ERR_get_next_error_library(void);
int ERR_set_mark(void);
int ERR_pop_to_mark(void);
int ERR_clear_last_mark(void);

