local ffi = require'ffi'
--[[
// csrc/openssl/src/include/openssl/dsa.h
enum {
	OPENSSL_DSA_MAX_MODULUS_BITS = 10000,
	OPENSSL_DSA_FIPS_MIN_MODULUS_BITS = 1024,
	DSA_FLAG_CACHE_MONT_P = 0x01,
	DSA_FLAG_NO_EXP_CONSTTIME = 0x00,
	DSA_FLAG_FIPS_METHOD = 0x0400,
	DSA_FLAG_NON_FIPS_ALLOW = 0x0400,
	DSA_FLAG_FIPS_CHECKED = 0x0800,
};
typedef struct DSA_SIG_st DSA_SIG;
#define d2i_DSAparams_fp(fp,x) (DSA *)ASN1_d2i_fp((char *(*)())DSA_new, (char *(*)())d2i_DSAparams,(fp),(unsigned char **)(x))
#define i2d_DSAparams_fp(fp,x) ASN1_i2d_fp(i2d_DSAparams,(fp), (unsigned char *)(x))
#define d2i_DSAparams_bio(bp,x) ASN1_d2i_bio_of(DSA,DSA_new,d2i_DSAparams,bp,x)
#define i2d_DSAparams_bio(bp,x) ASN1_i2d_bio_of_const(DSA,i2d_DSAparams,bp,x)
DSA *DSAparams_dup(DSA *x);
DSA_SIG *DSA_SIG_new(void);
void DSA_SIG_free(DSA_SIG *a);
int i2d_DSA_SIG(const DSA_SIG *a, unsigned char **pp);
DSA_SIG *d2i_DSA_SIG(DSA_SIG **v, const unsigned char **pp, long length);
void DSA_SIG_get0(const DSA_SIG *sig, const BIGNUM **pr, const BIGNUM **ps);
int DSA_SIG_set0(DSA_SIG *sig, BIGNUM *r, BIGNUM *s);
DSA_SIG *DSA_do_sign(const unsigned char *dgst, int dlen, DSA *dsa);
int DSA_do_verify(const unsigned char *dgst, int dgst_len,
                  DSA_SIG *sig, DSA *dsa);
const DSA_METHOD *DSA_OpenSSL(void);
void DSA_set_default_method(const DSA_METHOD *);
const DSA_METHOD *DSA_get_default_method(void);
int DSA_set_method(DSA *dsa, const DSA_METHOD *);
const DSA_METHOD *DSA_get_method(DSA *d);
DSA *DSA_new(void);
DSA *DSA_new_method(ENGINE *engine);
void DSA_free(DSA *r);
int DSA_up_ref(DSA *r);
int DSA_size(const DSA *);
int DSA_bits(const DSA *d);
int DSA_security_bits(const DSA *d);
int DSA_sign_setup(DSA *dsa, BN_CTX *ctx_in, BIGNUM **kinvp, BIGNUM **rp);
int DSA_sign(int type, const unsigned char *dgst, int dlen,
             unsigned char *sig, unsigned int *siglen, DSA *dsa);
int DSA_verify(int type, const unsigned char *dgst, int dgst_len,
               const unsigned char *sigbuf, int siglen, DSA *dsa);
#define DSA_get_ex_new_index(l,p,newf,dupf,freef) CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_DSA, l, p, newf, dupf, freef)
int DSA_set_ex_data(DSA *d, int idx, void *arg);
void *DSA_get_ex_data(DSA *d, int idx);
DSA *d2i_DSAPublicKey(DSA **a, const unsigned char **pp, long length);
DSA *d2i_DSAPrivateKey(DSA **a, const unsigned char **pp, long length);
DSA *d2i_DSAparams(DSA **a, const unsigned char **pp, long length);
DSA *DSA_generate_parameters(int bits, unsigned char *seed, int seed_len, int *counter_ret, unsigned long *h_ret, void (*callback) (int, int, void *), void *cb_arg) __attribute__ ((deprecated));
int DSA_generate_parameters_ex(DSA *dsa, int bits,
                               const unsigned char *seed, int seed_len,
                               int *counter_ret, unsigned long *h_ret,
                               BN_GENCB *cb);
int DSA_generate_key(DSA *a);
int i2d_DSAPublicKey(const DSA *a, unsigned char **pp);
int i2d_DSAPrivateKey(const DSA *a, unsigned char **pp);
int i2d_DSAparams(const DSA *a, unsigned char **pp);
int DSAparams_print(BIO *bp, const DSA *x);
int DSA_print(BIO *bp, const DSA *x, int off);
int DSAparams_print_fp(FILE *fp, const DSA *x);
int DSA_print_fp(FILE *bp, const DSA *x, int off);
enum {
	DSS_prime_checks     = 64,
};
#define DSA_is_prime(n,callback,cb_arg) BN_is_prime(n, DSS_prime_checks, callback, NULL, cb_arg)
DH *DSA_dup_DH(const DSA *r);
#define EVP_PKEY_CTX_set_dsa_paramgen_bits(ctx,nbits) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DSA, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DSA_PARAMGEN_BITS, nbits, NULL)
enum {
	EVP_PKEY_CTRL_DSA_PARAMGEN_BITS = (EVP_PKEY_ALG_CTRL + 1),
	EVP_PKEY_CTRL_DSA_PARAMGEN_Q_BITS = (EVP_PKEY_ALG_CTRL + 2),
	EVP_PKEY_CTRL_DSA_PARAMGEN_MD = (EVP_PKEY_ALG_CTRL + 3),
};
void DSA_get0_pqg(const DSA *d,
                  const BIGNUM **p, const BIGNUM **q, const BIGNUM **g);
int DSA_set0_pqg(DSA *d, BIGNUM *p, BIGNUM *q, BIGNUM *g);
void DSA_get0_key(const DSA *d,
                  const BIGNUM **pub_key, const BIGNUM **priv_key);
int DSA_set0_key(DSA *d, BIGNUM *pub_key, BIGNUM *priv_key);
const BIGNUM *DSA_get0_p(const DSA *d);
const BIGNUM *DSA_get0_q(const DSA *d);
const BIGNUM *DSA_get0_g(const DSA *d);
const BIGNUM *DSA_get0_pub_key(const DSA *d);
const BIGNUM *DSA_get0_priv_key(const DSA *d);
void DSA_clear_flags(DSA *d, int flags);
int DSA_test_flags(const DSA *d, int flags);
void DSA_set_flags(DSA *d, int flags);
ENGINE *DSA_get0_engine(DSA *d);
DSA_METHOD *DSA_meth_new(const char *name, int flags);
void DSA_meth_free(DSA_METHOD *dsam);
DSA_METHOD *DSA_meth_dup(const DSA_METHOD *dsam);
const char *DSA_meth_get0_name(const DSA_METHOD *dsam);
int DSA_meth_set1_name(DSA_METHOD *dsam, const char *name);
int DSA_meth_get_flags(const DSA_METHOD *dsam);
int DSA_meth_set_flags(DSA_METHOD *dsam, int flags);
void *DSA_meth_get0_app_data(const DSA_METHOD *dsam);
int DSA_meth_set0_app_data(DSA_METHOD *dsam, void *app_data);
DSA_SIG *(*DSA_meth_get_sign(const DSA_METHOD *dsam))
        (const unsigned char *, int, DSA *);
int DSA_meth_set_sign(DSA_METHOD *dsam,
                       DSA_SIG *(*sign) (const unsigned char *, int, DSA *));
int (*DSA_meth_get_sign_setup(const DSA_METHOD *dsam))
        (DSA *, BN_CTX *, BIGNUM **, BIGNUM **);
int DSA_meth_set_sign_setup(DSA_METHOD *dsam,
        int (*sign_setup) (DSA *, BN_CTX *, BIGNUM **, BIGNUM **));
int (*DSA_meth_get_verify(const DSA_METHOD *dsam))
        (const unsigned char *, int, DSA_SIG *, DSA *);
int DSA_meth_set_verify(DSA_METHOD *dsam,
    int (*verify) (const unsigned char *, int, DSA_SIG *, DSA *));
int (*DSA_meth_get_mod_exp(const DSA_METHOD *dsam))
        (DSA *, BIGNUM *, const BIGNUM *, const BIGNUM *, const BIGNUM *,
         const BIGNUM *, const BIGNUM *, BN_CTX *, BN_MONT_CTX *);
int DSA_meth_set_mod_exp(DSA_METHOD *dsam,
    int (*mod_exp) (DSA *, BIGNUM *, const BIGNUM *, const BIGNUM *,
                    const BIGNUM *, const BIGNUM *, const BIGNUM *, BN_CTX *,
                    BN_MONT_CTX *));
int (*DSA_meth_get_bn_mod_exp(const DSA_METHOD *dsam))
    (DSA *, BIGNUM *, const BIGNUM *, const BIGNUM *, const BIGNUM *,
     BN_CTX *, BN_MONT_CTX *);
int DSA_meth_set_bn_mod_exp(DSA_METHOD *dsam,
    int (*bn_mod_exp) (DSA *, BIGNUM *, const BIGNUM *, const BIGNUM *,
                       const BIGNUM *, BN_CTX *, BN_MONT_CTX *));
int (*DSA_meth_get_init(const DSA_METHOD *dsam))(DSA *);
int DSA_meth_set_init(DSA_METHOD *dsam, int (*init)(DSA *));
int (*DSA_meth_get_finish(const DSA_METHOD *dsam)) (DSA *);
int DSA_meth_set_finish(DSA_METHOD *dsam, int (*finish) (DSA *));
int (*DSA_meth_get_paramgen(const DSA_METHOD *dsam))
        (DSA *, int, const unsigned char *, int, int *, unsigned long *,
         BN_GENCB *);
int DSA_meth_set_paramgen(DSA_METHOD *dsam,
        int (*paramgen) (DSA *, int, const unsigned char *, int, int *,
                         unsigned long *, BN_GENCB *));
int (*DSA_meth_get_keygen(const DSA_METHOD *dsam)) (DSA *);
int DSA_meth_set_keygen(DSA_METHOD *dsam, int (*keygen) (DSA *));

// csrc/openssl/src/include/openssl/dsaerr.h
int ERR_load_DSA_strings(void);
enum {
	DSA_F_DSAPARAMS_PRINT = 100,
	DSA_F_DSAPARAMS_PRINT_FP = 101,
	DSA_F_DSA_BUILTIN_PARAMGEN = 125,
	DSA_F_DSA_BUILTIN_PARAMGEN2 = 126,
	DSA_F_DSA_DO_SIGN    = 112,
	DSA_F_DSA_DO_VERIFY  = 113,
	DSA_F_DSA_METH_DUP   = 127,
	DSA_F_DSA_METH_NEW   = 128,
	DSA_F_DSA_METH_SET1_NAME = 129,
	DSA_F_DSA_NEW_METHOD = 103,
	DSA_F_DSA_PARAM_DECODE = 119,
	DSA_F_DSA_PRINT_FP   = 105,
	DSA_F_DSA_PRIV_DECODE = 115,
	DSA_F_DSA_PRIV_ENCODE = 116,
	DSA_F_DSA_PUB_DECODE = 117,
	DSA_F_DSA_PUB_ENCODE = 118,
	DSA_F_DSA_SIGN       = 106,
	DSA_F_DSA_SIGN_SETUP = 107,
	DSA_F_DSA_SIG_NEW    = 102,
	DSA_F_OLD_DSA_PRIV_DECODE = 122,
	DSA_F_PKEY_DSA_CTRL  = 120,
	DSA_F_PKEY_DSA_CTRL_STR = 104,
	DSA_F_PKEY_DSA_KEYGEN = 121,
	DSA_R_BAD_Q_VALUE    = 102,
	DSA_R_BN_DECODE_ERROR = 108,
	DSA_R_BN_ERROR       = 109,
	DSA_R_DECODE_ERROR   = 104,
	DSA_R_INVALID_DIGEST_TYPE = 106,
	DSA_R_INVALID_PARAMETERS = 112,
	DSA_R_MISSING_PARAMETERS = 101,
	DSA_R_MISSING_PRIVATE_KEY = 111,
	DSA_R_MODULUS_TOO_LARGE = 103,
	DSA_R_NO_PARAMETERS_SET = 107,
	DSA_R_PARAMETER_ENCODING_ERROR = 105,
	DSA_R_Q_NOT_PRIME    = 113,
	DSA_R_SEED_LEN_SMALL = 110,
};
]]
