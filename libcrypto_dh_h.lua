// csrc/openssl/src/include/openssl/dh.h
enum {
	OPENSSL_DH_MAX_MODULUS_BITS = 10000,
	OPENSSL_DH_FIPS_MIN_MODULUS_BITS = 1024,
	DH_FLAG_CACHE_MONT_P = 0x01,
	DH_FLAG_NO_EXP_CONSTTIME = 0x00,
	DH_FLAG_FIPS_METHOD  = 0x0400,
	DH_FLAG_NON_FIPS_ALLOW = 0x0400,
};
const ASN1_ITEM * DHparams_it(void);
enum {
	DH_GENERATOR_2       = 2,
	DH_GENERATOR_5       = 5,
	DH_CHECK_P_NOT_PRIME = 0x01,
	DH_CHECK_P_NOT_SAFE_PRIME = 0x02,
	DH_UNABLE_TO_CHECK_GENERATOR = 0x04,
	DH_NOT_SUITABLE_GENERATOR = 0x08,
	DH_CHECK_Q_NOT_PRIME = 0x10,
	DH_CHECK_INVALID_Q_VALUE = 0x20,
	DH_CHECK_INVALID_J_VALUE = 0x40,
	DH_CHECK_PUBKEY_TOO_SMALL = 0x01,
	DH_CHECK_PUBKEY_TOO_LARGE = 0x02,
	DH_CHECK_PUBKEY_INVALID = 0x04,
	DH_CHECK_P_NOT_STRONG_PRIME = DH_CHECK_P_NOT_SAFE_PRIME,
};
#define d2i_DHparams_fp(fp,x) (DH *)ASN1_d2i_fp((char *(*)())DH_new, (char *(*)())d2i_DHparams, (fp), (unsigned char **)(x))
#define i2d_DHparams_fp(fp,x) ASN1_i2d_fp(i2d_DHparams,(fp), (unsigned char *)(x))
#define d2i_DHparams_bio(bp,x) ASN1_d2i_bio_of(DH, DH_new, d2i_DHparams, bp, x)
#define i2d_DHparams_bio(bp,x) ASN1_i2d_bio_of_const(DH,i2d_DHparams,bp,x)
#define d2i_DHxparams_fp(fp,x) (DH *)ASN1_d2i_fp((char *(*)())DH_new, (char *(*)())d2i_DHxparams, (fp), (unsigned char **)(x))
#define i2d_DHxparams_fp(fp,x) ASN1_i2d_fp(i2d_DHxparams,(fp), (unsigned char *)(x))
#define d2i_DHxparams_bio(bp,x) ASN1_d2i_bio_of(DH, DH_new, d2i_DHxparams, bp, x)
#define i2d_DHxparams_bio(bp,x) ASN1_i2d_bio_of_const(DH, i2d_DHxparams, bp, x)
DH *DHparams_dup(DH *);
const DH_METHOD *DH_OpenSSL(void);
void DH_set_default_method(const DH_METHOD *meth);
const DH_METHOD *DH_get_default_method(void);
int DH_set_method(DH *dh, const DH_METHOD *meth);
DH *DH_new_method(ENGINE *engine);
DH *DH_new(void);
void DH_free(DH *dh);
int DH_up_ref(DH *dh);
int DH_bits(const DH *dh);
int DH_size(const DH *dh);
int DH_security_bits(const DH *dh);
#define DH_get_ex_new_index(l,p,newf,dupf,freef) CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_DH, l, p, newf, dupf, freef)
int DH_set_ex_data(DH *d, int idx, void *arg);
void *DH_get_ex_data(DH *d, int idx);
DH *DH_generate_parameters(int prime_len, int generator, void (*callback) (int, int, void *), void *cb_arg) __attribute__ ((deprecated));
int DH_generate_parameters_ex(DH *dh, int prime_len, int generator,
                              BN_GENCB *cb);
int DH_check_params_ex(const DH *dh);
int DH_check_ex(const DH *dh);
int DH_check_pub_key_ex(const DH *dh, const BIGNUM *pub_key);
int DH_check_params(const DH *dh, int *ret);
int DH_check(const DH *dh, int *codes);
int DH_check_pub_key(const DH *dh, const BIGNUM *pub_key, int *codes);
int DH_generate_key(DH *dh);
int DH_compute_key(unsigned char *key, const BIGNUM *pub_key, DH *dh);
int DH_compute_key_padded(unsigned char *key, const BIGNUM *pub_key, DH *dh);
DH *d2i_DHparams(DH **a, const unsigned char **pp, long length);
int i2d_DHparams(const DH *a, unsigned char **pp);
DH *d2i_DHxparams(DH **a, const unsigned char **pp, long length);
int i2d_DHxparams(const DH *a, unsigned char **pp);
int DHparams_print_fp(FILE *fp, const DH *x);
int DHparams_print(BIO *bp, const DH *x);
DH *DH_get_1024_160(void);
DH *DH_get_2048_224(void);
DH *DH_get_2048_256(void);
DH *DH_new_by_nid(int nid);
int DH_get_nid(const DH *dh);
int DH_KDF_X9_42(unsigned char *out, size_t outlen,
                 const unsigned char *Z, size_t Zlen,
                 ASN1_OBJECT *key_oid,
                 const unsigned char *ukm, size_t ukmlen, const EVP_MD *md);
void DH_get0_pqg(const DH *dh,
                 const BIGNUM **p, const BIGNUM **q, const BIGNUM **g);
int DH_set0_pqg(DH *dh, BIGNUM *p, BIGNUM *q, BIGNUM *g);
void DH_get0_key(const DH *dh,
                 const BIGNUM **pub_key, const BIGNUM **priv_key);
int DH_set0_key(DH *dh, BIGNUM *pub_key, BIGNUM *priv_key);
const BIGNUM *DH_get0_p(const DH *dh);
const BIGNUM *DH_get0_q(const DH *dh);
const BIGNUM *DH_get0_g(const DH *dh);
const BIGNUM *DH_get0_priv_key(const DH *dh);
const BIGNUM *DH_get0_pub_key(const DH *dh);
void DH_clear_flags(DH *dh, int flags);
int DH_test_flags(const DH *dh, int flags);
void DH_set_flags(DH *dh, int flags);
ENGINE *DH_get0_engine(DH *d);
long DH_get_length(const DH *dh);
int DH_set_length(DH *dh, long length);
DH_METHOD *DH_meth_new(const char *name, int flags);
void DH_meth_free(DH_METHOD *dhm);
DH_METHOD *DH_meth_dup(const DH_METHOD *dhm);
const char *DH_meth_get0_name(const DH_METHOD *dhm);
int DH_meth_set1_name(DH_METHOD *dhm, const char *name);
int DH_meth_get_flags(const DH_METHOD *dhm);
int DH_meth_set_flags(DH_METHOD *dhm, int flags);
void *DH_meth_get0_app_data(const DH_METHOD *dhm);
int DH_meth_set0_app_data(DH_METHOD *dhm, void *app_data);
int (*DH_meth_get_generate_key(const DH_METHOD *dhm)) (DH *);
int DH_meth_set_generate_key(DH_METHOD *dhm, int (*generate_key) (DH *));
int (*DH_meth_get_compute_key(const DH_METHOD *dhm))
        (unsigned char *key, const BIGNUM *pub_key, DH *dh);
int DH_meth_set_compute_key(DH_METHOD *dhm,
        int (*compute_key) (unsigned char *key, const BIGNUM *pub_key, DH *dh));
int (*DH_meth_get_bn_mod_exp(const DH_METHOD *dhm))
    (const DH *, BIGNUM *, const BIGNUM *, const BIGNUM *, const BIGNUM *,
     BN_CTX *, BN_MONT_CTX *);
int DH_meth_set_bn_mod_exp(DH_METHOD *dhm,
    int (*bn_mod_exp) (const DH *, BIGNUM *, const BIGNUM *, const BIGNUM *,
                       const BIGNUM *, BN_CTX *, BN_MONT_CTX *));
int (*DH_meth_get_init(const DH_METHOD *dhm))(DH *);
int DH_meth_set_init(DH_METHOD *dhm, int (*init)(DH *));
int (*DH_meth_get_finish(const DH_METHOD *dhm)) (DH *);
int DH_meth_set_finish(DH_METHOD *dhm, int (*finish) (DH *));
int (*DH_meth_get_generate_params(const DH_METHOD *dhm))
        (DH *, int, int, BN_GENCB *);
int DH_meth_set_generate_params(DH_METHOD *dhm,
        int (*generate_params) (DH *, int, int, BN_GENCB *));
#define EVP_PKEY_CTX_set_dh_paramgen_prime_len(ctx,len) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DH, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DH_PARAMGEN_PRIME_LEN, len, NULL)
#define EVP_PKEY_CTX_set_dh_paramgen_subprime_len(ctx,len) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DH, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DH_PARAMGEN_SUBPRIME_LEN, len, NULL)
#define EVP_PKEY_CTX_set_dh_paramgen_type(ctx,typ) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DH, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DH_PARAMGEN_TYPE, typ, NULL)
#define EVP_PKEY_CTX_set_dh_paramgen_generator(ctx,gen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DH, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DH_PARAMGEN_GENERATOR, gen, NULL)
#define EVP_PKEY_CTX_set_dh_rfc5114(ctx,gen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DH_RFC5114, gen, NULL)
#define EVP_PKEY_CTX_set_dhx_rfc5114(ctx,gen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_PARAMGEN, EVP_PKEY_CTRL_DH_RFC5114, gen, NULL)
#define EVP_PKEY_CTX_set_dh_nid(ctx,nid) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DH, EVP_PKEY_OP_PARAMGEN | EVP_PKEY_OP_KEYGEN, EVP_PKEY_CTRL_DH_NID, nid, NULL)
#define EVP_PKEY_CTX_set_dh_pad(ctx,pad) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DH, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_PAD, pad, NULL)
#define EVP_PKEY_CTX_set_dh_kdf_type(ctx,kdf) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_KDF_TYPE, kdf, NULL)
#define EVP_PKEY_CTX_get_dh_kdf_type(ctx) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_KDF_TYPE, -2, NULL)
#define EVP_PKEY_CTX_set0_dh_kdf_oid(ctx,oid) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_KDF_OID, 0, (void *)(oid))
#define EVP_PKEY_CTX_get0_dh_kdf_oid(ctx,poid) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_DH_KDF_OID, 0, (void *)(poid))
#define EVP_PKEY_CTX_set_dh_kdf_md(ctx,md) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_KDF_MD, 0, (void *)(md))
#define EVP_PKEY_CTX_get_dh_kdf_md(ctx,pmd) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_DH_KDF_MD, 0, (void *)(pmd))
#define EVP_PKEY_CTX_set_dh_kdf_outlen(ctx,len) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_KDF_OUTLEN, len, NULL)
#define EVP_PKEY_CTX_get_dh_kdf_outlen(ctx,plen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_DH_KDF_OUTLEN, 0, (void *)(plen))
#define EVP_PKEY_CTX_set0_dh_kdf_ukm(ctx,p,plen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_DH_KDF_UKM, plen, (void *)(p))
#define EVP_PKEY_CTX_get0_dh_kdf_ukm(ctx,p) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_DHX, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_DH_KDF_UKM, 0, (void *)(p))
enum {
	EVP_PKEY_CTRL_DH_PARAMGEN_PRIME_LEN = (EVP_PKEY_ALG_CTRL + 1),
	EVP_PKEY_CTRL_DH_PARAMGEN_GENERATOR = (EVP_PKEY_ALG_CTRL + 2),
	EVP_PKEY_CTRL_DH_RFC5114 = (EVP_PKEY_ALG_CTRL + 3),
	EVP_PKEY_CTRL_DH_PARAMGEN_SUBPRIME_LEN = (EVP_PKEY_ALG_CTRL + 4),
	EVP_PKEY_CTRL_DH_PARAMGEN_TYPE = (EVP_PKEY_ALG_CTRL + 5),
	EVP_PKEY_CTRL_DH_KDF_TYPE = (EVP_PKEY_ALG_CTRL + 6),
	EVP_PKEY_CTRL_DH_KDF_MD = (EVP_PKEY_ALG_CTRL + 7),
	EVP_PKEY_CTRL_GET_DH_KDF_MD = (EVP_PKEY_ALG_CTRL + 8),
	EVP_PKEY_CTRL_DH_KDF_OUTLEN = (EVP_PKEY_ALG_CTRL + 9),
	EVP_PKEY_CTRL_GET_DH_KDF_OUTLEN = (EVP_PKEY_ALG_CTRL + 10),
	EVP_PKEY_CTRL_DH_KDF_UKM = (EVP_PKEY_ALG_CTRL + 11),
	EVP_PKEY_CTRL_GET_DH_KDF_UKM = (EVP_PKEY_ALG_CTRL + 12),
	EVP_PKEY_CTRL_DH_KDF_OID = (EVP_PKEY_ALG_CTRL + 13),
	EVP_PKEY_CTRL_GET_DH_KDF_OID = (EVP_PKEY_ALG_CTRL + 14),
	EVP_PKEY_CTRL_DH_NID = (EVP_PKEY_ALG_CTRL + 15),
	EVP_PKEY_CTRL_DH_PAD = (EVP_PKEY_ALG_CTRL + 16),
	EVP_PKEY_DH_KDF_NONE = 1,
	EVP_PKEY_DH_KDF_X9_42 = 2,
};

// csrc/openssl/src/include/openssl/dherr.h
int ERR_load_DH_strings(void);
enum {
	DH_F_COMPUTE_KEY     = 102,
	DH_F_DHPARAMS_PRINT_FP = 101,
	DH_F_DH_BUILTIN_GENPARAMS = 106,
	DH_F_DH_CHECK_EX     = 121,
	DH_F_DH_CHECK_PARAMS_EX = 122,
	DH_F_DH_CHECK_PUB_KEY_EX = 123,
	DH_F_DH_CMS_DECRYPT  = 114,
	DH_F_DH_CMS_SET_PEERKEY = 115,
	DH_F_DH_CMS_SET_SHARED_INFO = 116,
	DH_F_DH_METH_DUP     = 117,
	DH_F_DH_METH_NEW     = 118,
	DH_F_DH_METH_SET1_NAME = 119,
	DH_F_DH_NEW_BY_NID   = 104,
	DH_F_DH_NEW_METHOD   = 105,
	DH_F_DH_PARAM_DECODE = 107,
	DH_F_DH_PKEY_PUBLIC_CHECK = 124,
	DH_F_DH_PRIV_DECODE  = 110,
	DH_F_DH_PRIV_ENCODE  = 111,
	DH_F_DH_PUB_DECODE   = 108,
	DH_F_DH_PUB_ENCODE   = 109,
	DH_F_DO_DH_PRINT     = 100,
	DH_F_GENERATE_KEY    = 103,
	DH_F_PKEY_DH_CTRL_STR = 120,
	DH_F_PKEY_DH_DERIVE  = 112,
	DH_F_PKEY_DH_INIT    = 125,
	DH_F_PKEY_DH_KEYGEN  = 113,
	DH_R_BAD_GENERATOR   = 101,
	DH_R_BN_DECODE_ERROR = 109,
	DH_R_BN_ERROR        = 106,
	DH_R_CHECK_INVALID_J_VALUE = 115,
	DH_R_CHECK_INVALID_Q_VALUE = 116,
	DH_R_CHECK_PUBKEY_INVALID = 122,
	DH_R_CHECK_PUBKEY_TOO_LARGE = 123,
	DH_R_CHECK_PUBKEY_TOO_SMALL = 124,
	DH_R_CHECK_P_NOT_PRIME = 117,
	DH_R_CHECK_P_NOT_SAFE_PRIME = 118,
	DH_R_CHECK_Q_NOT_PRIME = 119,
	DH_R_DECODE_ERROR    = 104,
	DH_R_INVALID_PARAMETER_NAME = 110,
	DH_R_INVALID_PARAMETER_NID = 114,
	DH_R_INVALID_PUBKEY  = 102,
	DH_R_KDF_PARAMETER_ERROR = 112,
	DH_R_KEYS_NOT_SET    = 108,
	DH_R_MISSING_PUBKEY  = 125,
	DH_R_MODULUS_TOO_LARGE = 103,
	DH_R_NOT_SUITABLE_GENERATOR = 120,
	DH_R_NO_PARAMETERS_SET = 107,
	DH_R_NO_PRIVATE_VALUE = 100,
	DH_R_PARAMETER_ENCODING_ERROR = 105,
	DH_R_PEER_KEY_ERROR  = 111,
	DH_R_SHARED_INFO_ERROR = 113,
	DH_R_UNABLE_TO_CHECK_GENERATOR = 121,
};
