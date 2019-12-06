// csrc/openssl/src/include/openssl/ec.h
enum {
	OPENSSL_ECC_MAX_FIELD_BITS = 661,
};
typedef enum {
    POINT_CONVERSION_COMPRESSED = 2,
    POINT_CONVERSION_UNCOMPRESSED = 4,
    POINT_CONVERSION_HYBRID = 6
} point_conversion_form_t;
typedef struct ec_method_st EC_METHOD;
typedef struct ec_group_st EC_GROUP;
typedef struct ec_point_st EC_POINT;
typedef struct ecpk_parameters_st ECPKPARAMETERS;
typedef struct ec_parameters_st ECPARAMETERS;
const EC_METHOD *EC_GFp_simple_method(void);
const EC_METHOD *EC_GFp_mont_method(void);
const EC_METHOD *EC_GFp_nist_method(void);
const EC_METHOD *EC_GF2m_simple_method(void);
EC_GROUP *EC_GROUP_new(const EC_METHOD *meth);
void EC_GROUP_free(EC_GROUP *group);
void EC_GROUP_clear_free(EC_GROUP *group);
int EC_GROUP_copy(EC_GROUP *dst, const EC_GROUP *src);
EC_GROUP *EC_GROUP_dup(const EC_GROUP *src);
const EC_METHOD *EC_GROUP_method_of(const EC_GROUP *group);
int EC_METHOD_get_field_type(const EC_METHOD *meth);
int EC_GROUP_set_generator(EC_GROUP *group, const EC_POINT *generator,
                           const BIGNUM *order, const BIGNUM *cofactor);
const EC_POINT *EC_GROUP_get0_generator(const EC_GROUP *group);
BN_MONT_CTX *EC_GROUP_get_mont_data(const EC_GROUP *group);
int EC_GROUP_get_order(const EC_GROUP *group, BIGNUM *order, BN_CTX *ctx);
const BIGNUM *EC_GROUP_get0_order(const EC_GROUP *group);
int EC_GROUP_order_bits(const EC_GROUP *group);
int EC_GROUP_get_cofactor(const EC_GROUP *group, BIGNUM *cofactor,
                          BN_CTX *ctx);
const BIGNUM *EC_GROUP_get0_cofactor(const EC_GROUP *group);
void EC_GROUP_set_curve_name(EC_GROUP *group, int nid);
int EC_GROUP_get_curve_name(const EC_GROUP *group);
void EC_GROUP_set_asn1_flag(EC_GROUP *group, int flag);
int EC_GROUP_get_asn1_flag(const EC_GROUP *group);
void EC_GROUP_set_point_conversion_form(EC_GROUP *group,
                                        point_conversion_form_t form);
point_conversion_form_t EC_GROUP_get_point_conversion_form(const EC_GROUP *);
unsigned char *EC_GROUP_get0_seed(const EC_GROUP *x);
size_t EC_GROUP_get_seed_len(const EC_GROUP *);
size_t EC_GROUP_set_seed(EC_GROUP *, const unsigned char *, size_t len);
int EC_GROUP_set_curve(EC_GROUP *group, const BIGNUM *p, const BIGNUM *a,
                       const BIGNUM *b, BN_CTX *ctx);
int EC_GROUP_get_curve(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b,
                       BN_CTX *ctx);
int EC_GROUP_set_curve_GFp(EC_GROUP *group, const BIGNUM *p, const BIGNUM *a, const BIGNUM *b, BN_CTX *ctx);
int EC_GROUP_get_curve_GFp(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx);
int EC_GROUP_set_curve_GF2m(EC_GROUP *group, const BIGNUM *p, const BIGNUM *a, const BIGNUM *b, BN_CTX *ctx);
int EC_GROUP_get_curve_GF2m(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx);
int EC_GROUP_get_degree(const EC_GROUP *group);
int EC_GROUP_check(const EC_GROUP *group, BN_CTX *ctx);
int EC_GROUP_check_discriminant(const EC_GROUP *group, BN_CTX *ctx);
int EC_GROUP_cmp(const EC_GROUP *a, const EC_GROUP *b, BN_CTX *ctx);
EC_GROUP *EC_GROUP_new_curve_GFp(const BIGNUM *p, const BIGNUM *a,
                                 const BIGNUM *b, BN_CTX *ctx);
EC_GROUP *EC_GROUP_new_curve_GF2m(const BIGNUM *p, const BIGNUM *a,
                                  const BIGNUM *b, BN_CTX *ctx);
EC_GROUP *EC_GROUP_new_by_curve_name(int nid);
EC_GROUP *EC_GROUP_new_from_ecparameters(const ECPARAMETERS *params);
ECPARAMETERS *EC_GROUP_get_ecparameters(const EC_GROUP *group,
                                        ECPARAMETERS *params);
EC_GROUP *EC_GROUP_new_from_ecpkparameters(const ECPKPARAMETERS *params);
ECPKPARAMETERS *EC_GROUP_get_ecpkparameters(const EC_GROUP *group,
                                            ECPKPARAMETERS *params);
typedef struct {
    int nid;
    const char *comment;
} EC_builtin_curve;
size_t EC_get_builtin_curves(EC_builtin_curve *r, size_t nitems);
const char *EC_curve_nid2nist(int nid);
int EC_curve_nist2nid(const char *name);
EC_POINT *EC_POINT_new(const EC_GROUP *group);
void EC_POINT_free(EC_POINT *point);
void EC_POINT_clear_free(EC_POINT *point);
int EC_POINT_copy(EC_POINT *dst, const EC_POINT *src);
EC_POINT *EC_POINT_dup(const EC_POINT *src, const EC_GROUP *group);
const EC_METHOD *EC_POINT_method_of(const EC_POINT *point);
int EC_POINT_set_to_infinity(const EC_GROUP *group, EC_POINT *point);
int EC_POINT_set_Jprojective_coordinates_GFp(const EC_GROUP *group,
                                             EC_POINT *p, const BIGNUM *x,
                                             const BIGNUM *y, const BIGNUM *z,
                                             BN_CTX *ctx);
int EC_POINT_get_Jprojective_coordinates_GFp(const EC_GROUP *group,
                                             const EC_POINT *p, BIGNUM *x,
                                             BIGNUM *y, BIGNUM *z,
                                             BN_CTX *ctx);
int EC_POINT_set_affine_coordinates(const EC_GROUP *group, EC_POINT *p,
                                    const BIGNUM *x, const BIGNUM *y,
                                    BN_CTX *ctx);
int EC_POINT_get_affine_coordinates(const EC_GROUP *group, const EC_POINT *p,
                                    BIGNUM *x, BIGNUM *y, BN_CTX *ctx);
int EC_POINT_set_affine_coordinates_GFp(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx);
int EC_POINT_get_affine_coordinates_GFp(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx);
int EC_POINT_set_compressed_coordinates(const EC_GROUP *group, EC_POINT *p,
                                        const BIGNUM *x, int y_bit,
                                        BN_CTX *ctx);
int EC_POINT_set_compressed_coordinates_GFp(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, int y_bit, BN_CTX *ctx);
int EC_POINT_set_affine_coordinates_GF2m(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx);
int EC_POINT_get_affine_coordinates_GF2m(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx);
int EC_POINT_set_compressed_coordinates_GF2m(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, int y_bit, BN_CTX *ctx);
size_t EC_POINT_point2oct(const EC_GROUP *group, const EC_POINT *p,
                          point_conversion_form_t form,
                          unsigned char *buf, size_t len, BN_CTX *ctx);
int EC_POINT_oct2point(const EC_GROUP *group, EC_POINT *p,
                       const unsigned char *buf, size_t len, BN_CTX *ctx);
size_t EC_POINT_point2buf(const EC_GROUP *group, const EC_POINT *point,
                          point_conversion_form_t form,
                          unsigned char **pbuf, BN_CTX *ctx);
BIGNUM *EC_POINT_point2bn(const EC_GROUP *, const EC_POINT *,
                          point_conversion_form_t form, BIGNUM *, BN_CTX *);
EC_POINT *EC_POINT_bn2point(const EC_GROUP *, const BIGNUM *,
                            EC_POINT *, BN_CTX *);
char *EC_POINT_point2hex(const EC_GROUP *, const EC_POINT *,
                         point_conversion_form_t form, BN_CTX *);
EC_POINT *EC_POINT_hex2point(const EC_GROUP *, const char *,
                             EC_POINT *, BN_CTX *);
int EC_POINT_add(const EC_GROUP *group, EC_POINT *r, const EC_POINT *a,
                 const EC_POINT *b, BN_CTX *ctx);
int EC_POINT_dbl(const EC_GROUP *group, EC_POINT *r, const EC_POINT *a,
                 BN_CTX *ctx);
int EC_POINT_invert(const EC_GROUP *group, EC_POINT *a, BN_CTX *ctx);
int EC_POINT_is_at_infinity(const EC_GROUP *group, const EC_POINT *p);
int EC_POINT_is_on_curve(const EC_GROUP *group, const EC_POINT *point,
                         BN_CTX *ctx);
int EC_POINT_cmp(const EC_GROUP *group, const EC_POINT *a, const EC_POINT *b,
                 BN_CTX *ctx);
int EC_POINT_make_affine(const EC_GROUP *group, EC_POINT *point, BN_CTX *ctx);
int EC_POINTs_make_affine(const EC_GROUP *group, size_t num,
                          EC_POINT *points[], BN_CTX *ctx);
int EC_POINTs_mul(const EC_GROUP *group, EC_POINT *r, const BIGNUM *n,
                  size_t num, const EC_POINT *p[], const BIGNUM *m[],
                  BN_CTX *ctx);
int EC_POINT_mul(const EC_GROUP *group, EC_POINT *r, const BIGNUM *n,
                 const EC_POINT *q, const BIGNUM *m, BN_CTX *ctx);
int EC_GROUP_precompute_mult(EC_GROUP *group, BN_CTX *ctx);
int EC_GROUP_have_precompute_mult(const EC_GROUP *group);
const ASN1_ITEM * ECPKPARAMETERS_it(void);
ECPKPARAMETERS *ECPKPARAMETERS_new(void); void ECPKPARAMETERS_free(ECPKPARAMETERS *a);
const ASN1_ITEM * ECPARAMETERS_it(void);
ECPARAMETERS *ECPARAMETERS_new(void); void ECPARAMETERS_free(ECPARAMETERS *a);
int EC_GROUP_get_basis_type(const EC_GROUP *);
int EC_GROUP_get_trinomial_basis(const EC_GROUP *, unsigned int *k);
int EC_GROUP_get_pentanomial_basis(const EC_GROUP *, unsigned int *k1,
                                   unsigned int *k2, unsigned int *k3);
enum {
	OPENSSL_EC_EXPLICIT_CURVE = 0x000,
	OPENSSL_EC_NAMED_CURVE = 0x001,
};
EC_GROUP *d2i_ECPKParameters(EC_GROUP **, const unsigned char **in, long len);
int i2d_ECPKParameters(const EC_GROUP *, unsigned char **out);
#define d2i_ECPKParameters_bio(bp,x) ASN1_d2i_bio_of(EC_GROUP,NULL,d2i_ECPKParameters,bp,x)
#define i2d_ECPKParameters_bio(bp,x) ASN1_i2d_bio_of_const(EC_GROUP,i2d_ECPKParameters,bp,x)
#define d2i_ECPKParameters_fp(fp,x) (EC_GROUP *)ASN1_d2i_fp(NULL, (char *(*)())d2i_ECPKParameters,(fp),(unsigned char **)(x))
#define i2d_ECPKParameters_fp(fp,x) ASN1_i2d_fp(i2d_ECPKParameters,(fp), (unsigned char *)(x))
int ECPKParameters_print(BIO *bp, const EC_GROUP *x, int off);
int ECPKParameters_print_fp(FILE *fp, const EC_GROUP *x, int off);
enum {
	EC_PKEY_NO_PARAMETERS = 0x001,
	EC_PKEY_NO_PUBKEY    = 0x002,
	EC_FLAG_NON_FIPS_ALLOW = 0x1,
	EC_FLAG_FIPS_CHECKED = 0x2,
	EC_FLAG_COFACTOR_ECDH = 0x1000,
};
EC_KEY *EC_KEY_new(void);
int EC_KEY_get_flags(const EC_KEY *key);
void EC_KEY_set_flags(EC_KEY *key, int flags);
void EC_KEY_clear_flags(EC_KEY *key, int flags);
EC_KEY *EC_KEY_new_by_curve_name(int nid);
void EC_KEY_free(EC_KEY *key);
EC_KEY *EC_KEY_copy(EC_KEY *dst, const EC_KEY *src);
EC_KEY *EC_KEY_dup(const EC_KEY *src);
int EC_KEY_up_ref(EC_KEY *key);
ENGINE *EC_KEY_get0_engine(const EC_KEY *eckey);
const EC_GROUP *EC_KEY_get0_group(const EC_KEY *key);
int EC_KEY_set_group(EC_KEY *key, const EC_GROUP *group);
const BIGNUM *EC_KEY_get0_private_key(const EC_KEY *key);
int EC_KEY_set_private_key(EC_KEY *key, const BIGNUM *prv);
const EC_POINT *EC_KEY_get0_public_key(const EC_KEY *key);
int EC_KEY_set_public_key(EC_KEY *key, const EC_POINT *pub);
unsigned EC_KEY_get_enc_flags(const EC_KEY *key);
void EC_KEY_set_enc_flags(EC_KEY *eckey, unsigned int flags);
point_conversion_form_t EC_KEY_get_conv_form(const EC_KEY *key);
void EC_KEY_set_conv_form(EC_KEY *eckey, point_conversion_form_t cform);
#define EC_KEY_get_ex_new_index(l,p,newf,dupf,freef) CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_EC_KEY, l, p, newf, dupf, freef)
int EC_KEY_set_ex_data(EC_KEY *key, int idx, void *arg);
void *EC_KEY_get_ex_data(const EC_KEY *key, int idx);
void EC_KEY_set_asn1_flag(EC_KEY *eckey, int asn1_flag);
int EC_KEY_precompute_mult(EC_KEY *key, BN_CTX *ctx);
int EC_KEY_generate_key(EC_KEY *key);
int EC_KEY_check_key(const EC_KEY *key);
int EC_KEY_can_sign(const EC_KEY *eckey);
int EC_KEY_set_public_key_affine_coordinates(EC_KEY *key, BIGNUM *x,
                                             BIGNUM *y);
size_t EC_KEY_key2buf(const EC_KEY *key, point_conversion_form_t form,
                      unsigned char **pbuf, BN_CTX *ctx);
int EC_KEY_oct2key(EC_KEY *key, const unsigned char *buf, size_t len,
                   BN_CTX *ctx);
int EC_KEY_oct2priv(EC_KEY *key, const unsigned char *buf, size_t len);
size_t EC_KEY_priv2oct(const EC_KEY *key, unsigned char *buf, size_t len);
size_t EC_KEY_priv2buf(const EC_KEY *eckey, unsigned char **pbuf);
EC_KEY *d2i_ECPrivateKey(EC_KEY **key, const unsigned char **in, long len);
int i2d_ECPrivateKey(EC_KEY *key, unsigned char **out);
EC_KEY *d2i_ECParameters(EC_KEY **key, const unsigned char **in, long len);
int i2d_ECParameters(EC_KEY *key, unsigned char **out);
EC_KEY *o2i_ECPublicKey(EC_KEY **key, const unsigned char **in, long len);
int i2o_ECPublicKey(const EC_KEY *key, unsigned char **out);
int ECParameters_print(BIO *bp, const EC_KEY *key);
int EC_KEY_print(BIO *bp, const EC_KEY *key, int off);
int ECParameters_print_fp(FILE *fp, const EC_KEY *key);
int EC_KEY_print_fp(FILE *fp, const EC_KEY *key, int off);
const EC_KEY_METHOD *EC_KEY_OpenSSL(void);
const EC_KEY_METHOD *EC_KEY_get_default_method(void);
void EC_KEY_set_default_method(const EC_KEY_METHOD *meth);
const EC_KEY_METHOD *EC_KEY_get_method(const EC_KEY *key);
int EC_KEY_set_method(EC_KEY *key, const EC_KEY_METHOD *meth);
EC_KEY *EC_KEY_new_method(ENGINE *engine);
int ECDH_KDF_X9_62(unsigned char *out, size_t outlen,
                   const unsigned char *Z, size_t Zlen,
                   const unsigned char *sinfo, size_t sinfolen,
                   const EVP_MD *md);
int ECDH_compute_key(void *out, size_t outlen, const EC_POINT *pub_key,
                     const EC_KEY *ecdh,
                     void *(*KDF) (const void *in, size_t inlen,
                                   void *out, size_t *outlen));
typedef struct ECDSA_SIG_st ECDSA_SIG;
ECDSA_SIG *ECDSA_SIG_new(void);
void ECDSA_SIG_free(ECDSA_SIG *sig);
int i2d_ECDSA_SIG(const ECDSA_SIG *sig, unsigned char **pp);
ECDSA_SIG *d2i_ECDSA_SIG(ECDSA_SIG **sig, const unsigned char **pp, long len);
void ECDSA_SIG_get0(const ECDSA_SIG *sig, const BIGNUM **pr, const BIGNUM **ps);
const BIGNUM *ECDSA_SIG_get0_r(const ECDSA_SIG *sig);
const BIGNUM *ECDSA_SIG_get0_s(const ECDSA_SIG *sig);
int ECDSA_SIG_set0(ECDSA_SIG *sig, BIGNUM *r, BIGNUM *s);
ECDSA_SIG *ECDSA_do_sign(const unsigned char *dgst, int dgst_len,
                         EC_KEY *eckey);
ECDSA_SIG *ECDSA_do_sign_ex(const unsigned char *dgst, int dgstlen,
                            const BIGNUM *kinv, const BIGNUM *rp,
                            EC_KEY *eckey);
int ECDSA_do_verify(const unsigned char *dgst, int dgst_len,
                    const ECDSA_SIG *sig, EC_KEY *eckey);
int ECDSA_sign_setup(EC_KEY *eckey, BN_CTX *ctx, BIGNUM **kinv, BIGNUM **rp);
int ECDSA_sign(int type, const unsigned char *dgst, int dgstlen,
               unsigned char *sig, unsigned int *siglen, EC_KEY *eckey);
int ECDSA_sign_ex(int type, const unsigned char *dgst, int dgstlen,
                  unsigned char *sig, unsigned int *siglen,
                  const BIGNUM *kinv, const BIGNUM *rp, EC_KEY *eckey);
int ECDSA_verify(int type, const unsigned char *dgst, int dgstlen,
                 const unsigned char *sig, int siglen, EC_KEY *eckey);
int ECDSA_size(const EC_KEY *eckey);
EC_KEY_METHOD *EC_KEY_METHOD_new(const EC_KEY_METHOD *meth);
void EC_KEY_METHOD_free(EC_KEY_METHOD *meth);
void EC_KEY_METHOD_set_init(EC_KEY_METHOD *meth,
                            int (*init)(EC_KEY *key),
                            void (*finish)(EC_KEY *key),
                            int (*copy)(EC_KEY *dest, const EC_KEY *src),
                            int (*set_group)(EC_KEY *key, const EC_GROUP *grp),
                            int (*set_private)(EC_KEY *key,
                                               const BIGNUM *priv_key),
                            int (*set_public)(EC_KEY *key,
                                              const EC_POINT *pub_key));
void EC_KEY_METHOD_set_keygen(EC_KEY_METHOD *meth,
                              int (*keygen)(EC_KEY *key));
void EC_KEY_METHOD_set_compute_key(EC_KEY_METHOD *meth,
                                   int (*ckey)(unsigned char **psec,
                                               size_t *pseclen,
                                               const EC_POINT *pub_key,
                                               const EC_KEY *ecdh));
void EC_KEY_METHOD_set_sign(EC_KEY_METHOD *meth,
                            int (*sign)(int type, const unsigned char *dgst,
                                        int dlen, unsigned char *sig,
                                        unsigned int *siglen,
                                        const BIGNUM *kinv, const BIGNUM *r,
                                        EC_KEY *eckey),
                            int (*sign_setup)(EC_KEY *eckey, BN_CTX *ctx_in,
                                              BIGNUM **kinvp, BIGNUM **rp),
                            ECDSA_SIG *(*sign_sig)(const unsigned char *dgst,
                                                   int dgst_len,
                                                   const BIGNUM *in_kinv,
                                                   const BIGNUM *in_r,
                                                   EC_KEY *eckey));
void EC_KEY_METHOD_set_verify(EC_KEY_METHOD *meth,
                              int (*verify)(int type, const unsigned
                                            char *dgst, int dgst_len,
                                            const unsigned char *sigbuf,
                                            int sig_len, EC_KEY *eckey),
                              int (*verify_sig)(const unsigned char *dgst,
                                                int dgst_len,
                                                const ECDSA_SIG *sig,
                                                EC_KEY *eckey));
void EC_KEY_METHOD_get_init(const EC_KEY_METHOD *meth,
                            int (**pinit)(EC_KEY *key),
                            void (**pfinish)(EC_KEY *key),
                            int (**pcopy)(EC_KEY *dest, const EC_KEY *src),
                            int (**pset_group)(EC_KEY *key,
                                               const EC_GROUP *grp),
                            int (**pset_private)(EC_KEY *key,
                                                 const BIGNUM *priv_key),
                            int (**pset_public)(EC_KEY *key,
                                                const EC_POINT *pub_key));
void EC_KEY_METHOD_get_keygen(const EC_KEY_METHOD *meth,
                              int (**pkeygen)(EC_KEY *key));
void EC_KEY_METHOD_get_compute_key(const EC_KEY_METHOD *meth,
                                   int (**pck)(unsigned char **psec,
                                               size_t *pseclen,
                                               const EC_POINT *pub_key,
                                               const EC_KEY *ecdh));
void EC_KEY_METHOD_get_sign(const EC_KEY_METHOD *meth,
                            int (**psign)(int type, const unsigned char *dgst,
                                          int dlen, unsigned char *sig,
                                          unsigned int *siglen,
                                          const BIGNUM *kinv, const BIGNUM *r,
                                          EC_KEY *eckey),
                            int (**psign_setup)(EC_KEY *eckey, BN_CTX *ctx_in,
                                                BIGNUM **kinvp, BIGNUM **rp),
                            ECDSA_SIG *(**psign_sig)(const unsigned char *dgst,
                                                     int dgst_len,
                                                     const BIGNUM *in_kinv,
                                                     const BIGNUM *in_r,
                                                     EC_KEY *eckey));
void EC_KEY_METHOD_get_verify(const EC_KEY_METHOD *meth,
                              int (**pverify)(int type, const unsigned
                                              char *dgst, int dgst_len,
                                              const unsigned char *sigbuf,
                                              int sig_len, EC_KEY *eckey),
                              int (**pverify_sig)(const unsigned char *dgst,
                                                  int dgst_len,
                                                  const ECDSA_SIG *sig,
                                                  EC_KEY *eckey));
#define ECParameters_dup(x) ASN1_dup_of(EC_KEY,i2d_ECParameters,d2i_ECParameters,x)
#define EVP_PKEY_CTX_set_ec_paramgen_curve_nid(ctx,nid) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_PARAMGEN|EVP_PKEY_OP_KEYGEN, EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID, nid, NULL)
#define EVP_PKEY_CTX_set_ec_param_enc(ctx,flag) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_PARAMGEN|EVP_PKEY_OP_KEYGEN, EVP_PKEY_CTRL_EC_PARAM_ENC, flag, NULL)
#define EVP_PKEY_CTX_set_ecdh_cofactor_mode(ctx,flag) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_ECDH_COFACTOR, flag, NULL)
#define EVP_PKEY_CTX_get_ecdh_cofactor_mode(ctx) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_ECDH_COFACTOR, -2, NULL)
#define EVP_PKEY_CTX_set_ecdh_kdf_type(ctx,kdf) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_KDF_TYPE, kdf, NULL)
#define EVP_PKEY_CTX_get_ecdh_kdf_type(ctx) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_KDF_TYPE, -2, NULL)
#define EVP_PKEY_CTX_set_ecdh_kdf_md(ctx,md) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_KDF_MD, 0, (void *)(md))
#define EVP_PKEY_CTX_get_ecdh_kdf_md(ctx,pmd) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_EC_KDF_MD, 0, (void *)(pmd))
#define EVP_PKEY_CTX_set_ecdh_kdf_outlen(ctx,len) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_KDF_OUTLEN, len, NULL)
#define EVP_PKEY_CTX_get_ecdh_kdf_outlen(ctx,plen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_EC_KDF_OUTLEN, 0, (void *)(plen))
#define EVP_PKEY_CTX_set0_ecdh_kdf_ukm(ctx,p,plen) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_EC_KDF_UKM, plen, (void *)(p))
#define EVP_PKEY_CTX_get0_ecdh_kdf_ukm(ctx,p) EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, EVP_PKEY_OP_DERIVE, EVP_PKEY_CTRL_GET_EC_KDF_UKM, 0, (void *)(p))
#define EVP_PKEY_CTX_set1_id(ctx,id,id_len) EVP_PKEY_CTX_ctrl(ctx, -1, -1, EVP_PKEY_CTRL_SET1_ID, (int)id_len, (void*)(id))
#define EVP_PKEY_CTX_get1_id(ctx,id) EVP_PKEY_CTX_ctrl(ctx, -1, -1, EVP_PKEY_CTRL_GET1_ID, 0, (void*)(id))
#define EVP_PKEY_CTX_get1_id_len(ctx,id_len) EVP_PKEY_CTX_ctrl(ctx, -1, -1, EVP_PKEY_CTRL_GET1_ID_LEN, 0, (void*)(id_len))
enum {
	EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID = (EVP_PKEY_ALG_CTRL + 1),
	EVP_PKEY_CTRL_EC_PARAM_ENC = (EVP_PKEY_ALG_CTRL + 2),
	EVP_PKEY_CTRL_EC_ECDH_COFACTOR = (EVP_PKEY_ALG_CTRL + 3),
	EVP_PKEY_CTRL_EC_KDF_TYPE = (EVP_PKEY_ALG_CTRL + 4),
	EVP_PKEY_CTRL_EC_KDF_MD = (EVP_PKEY_ALG_CTRL + 5),
	EVP_PKEY_CTRL_GET_EC_KDF_MD = (EVP_PKEY_ALG_CTRL + 6),
	EVP_PKEY_CTRL_EC_KDF_OUTLEN = (EVP_PKEY_ALG_CTRL + 7),
	EVP_PKEY_CTRL_GET_EC_KDF_OUTLEN = (EVP_PKEY_ALG_CTRL + 8),
	EVP_PKEY_CTRL_EC_KDF_UKM = (EVP_PKEY_ALG_CTRL + 9),
	EVP_PKEY_CTRL_GET_EC_KDF_UKM = (EVP_PKEY_ALG_CTRL + 10),
	EVP_PKEY_CTRL_SET1_ID = (EVP_PKEY_ALG_CTRL + 11),
	EVP_PKEY_CTRL_GET1_ID = (EVP_PKEY_ALG_CTRL + 12),
	EVP_PKEY_CTRL_GET1_ID_LEN = (EVP_PKEY_ALG_CTRL + 13),
	EVP_PKEY_ECDH_KDF_NONE = 1,
	EVP_PKEY_ECDH_KDF_X9_63 = 2,
	EVP_PKEY_ECDH_KDF_X9_62 = EVP_PKEY_ECDH_KDF_X9_63,
};

// csrc/openssl/src/include/openssl/ecerr.h
int ERR_load_EC_strings(void);
enum {
	EC_F_BN_TO_FELEM     = 224,
	EC_F_D2I_ECPARAMETERS = 144,
	EC_F_D2I_ECPKPARAMETERS = 145,
	EC_F_D2I_ECPRIVATEKEY = 146,
	EC_F_DO_EC_KEY_PRINT = 221,
	EC_F_ECDH_CMS_DECRYPT = 238,
	EC_F_ECDH_CMS_SET_SHARED_INFO = 239,
	EC_F_ECDH_COMPUTE_KEY = 246,
	EC_F_ECDH_SIMPLE_COMPUTE_KEY = 257,
	EC_F_ECDSA_DO_SIGN_EX = 251,
	EC_F_ECDSA_DO_VERIFY = 252,
	EC_F_ECDSA_SIGN_EX   = 254,
	EC_F_ECDSA_SIGN_SETUP = 248,
	EC_F_ECDSA_SIG_NEW   = 265,
	EC_F_ECDSA_VERIFY    = 253,
	EC_F_ECD_ITEM_VERIFY = 270,
	EC_F_ECKEY_PARAM2TYPE = 223,
	EC_F_ECKEY_PARAM_DECODE = 212,
	EC_F_ECKEY_PRIV_DECODE = 213,
	EC_F_ECKEY_PRIV_ENCODE = 214,
	EC_F_ECKEY_PUB_DECODE = 215,
	EC_F_ECKEY_PUB_ENCODE = 216,
	EC_F_ECKEY_TYPE2PARAM = 220,
	EC_F_ECPARAMETERS_PRINT = 147,
	EC_F_ECPARAMETERS_PRINT_FP = 148,
	EC_F_ECPKPARAMETERS_PRINT = 149,
	EC_F_ECPKPARAMETERS_PRINT_FP = 150,
	EC_F_ECP_NISTZ256_GET_AFFINE = 240,
	EC_F_ECP_NISTZ256_INV_MOD_ORD = 275,
	EC_F_ECP_NISTZ256_MULT_PRECOMPUTE = 243,
	EC_F_ECP_NISTZ256_POINTS_MUL = 241,
	EC_F_ECP_NISTZ256_PRE_COMP_NEW = 244,
	EC_F_ECP_NISTZ256_WINDOWED_MUL = 242,
	EC_F_ECX_KEY_OP      = 266,
	EC_F_ECX_PRIV_ENCODE = 267,
	EC_F_ECX_PUB_ENCODE  = 268,
	EC_F_EC_ASN1_GROUP2CURVE = 153,
	EC_F_EC_ASN1_GROUP2FIELDID = 154,
	EC_F_EC_GF2M_MONTGOMERY_POINT_MULTIPLY = 208,
	EC_F_EC_GF2M_SIMPLE_FIELD_INV = 296,
	EC_F_EC_GF2M_SIMPLE_GROUP_CHECK_DISCRIMINANT = 159,
	EC_F_EC_GF2M_SIMPLE_GROUP_SET_CURVE = 195,
	EC_F_EC_GF2M_SIMPLE_LADDER_POST = 285,
	EC_F_EC_GF2M_SIMPLE_LADDER_PRE = 288,
	EC_F_EC_GF2M_SIMPLE_OCT2POINT = 160,
	EC_F_EC_GF2M_SIMPLE_POINT2OCT = 161,
	EC_F_EC_GF2M_SIMPLE_POINTS_MUL = 289,
	EC_F_EC_GF2M_SIMPLE_POINT_GET_AFFINE_COORDINATES = 162,
	EC_F_EC_GF2M_SIMPLE_POINT_SET_AFFINE_COORDINATES = 163,
	EC_F_EC_GF2M_SIMPLE_SET_COMPRESSED_COORDINATES = 164,
	EC_F_EC_GFP_MONT_FIELD_DECODE = 133,
	EC_F_EC_GFP_MONT_FIELD_ENCODE = 134,
	EC_F_EC_GFP_MONT_FIELD_INV = 297,
	EC_F_EC_GFP_MONT_FIELD_MUL = 131,
	EC_F_EC_GFP_MONT_FIELD_SET_TO_ONE = 209,
	EC_F_EC_GFP_MONT_FIELD_SQR = 132,
	EC_F_EC_GFP_MONT_GROUP_SET_CURVE = 189,
	EC_F_EC_GFP_NISTP224_GROUP_SET_CURVE = 225,
	EC_F_EC_GFP_NISTP224_POINTS_MUL = 228,
	EC_F_EC_GFP_NISTP224_POINT_GET_AFFINE_COORDINATES = 226,
	EC_F_EC_GFP_NISTP256_GROUP_SET_CURVE = 230,
	EC_F_EC_GFP_NISTP256_POINTS_MUL = 231,
	EC_F_EC_GFP_NISTP256_POINT_GET_AFFINE_COORDINATES = 232,
	EC_F_EC_GFP_NISTP521_GROUP_SET_CURVE = 233,
	EC_F_EC_GFP_NISTP521_POINTS_MUL = 234,
	EC_F_EC_GFP_NISTP521_POINT_GET_AFFINE_COORDINATES = 235,
	EC_F_EC_GFP_NIST_FIELD_MUL = 200,
	EC_F_EC_GFP_NIST_FIELD_SQR = 201,
	EC_F_EC_GFP_NIST_GROUP_SET_CURVE = 202,
	EC_F_EC_GFP_SIMPLE_BLIND_COORDINATES = 287,
	EC_F_EC_GFP_SIMPLE_FIELD_INV = 298,
	EC_F_EC_GFP_SIMPLE_GROUP_CHECK_DISCRIMINANT = 165,
	EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE = 166,
	EC_F_EC_GFP_SIMPLE_MAKE_AFFINE = 102,
	EC_F_EC_GFP_SIMPLE_OCT2POINT = 103,
	EC_F_EC_GFP_SIMPLE_POINT2OCT = 104,
	EC_F_EC_GFP_SIMPLE_POINTS_MAKE_AFFINE = 137,
	EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES = 167,
	EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES = 168,
	EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES = 169,
	EC_F_EC_GROUP_CHECK  = 170,
	EC_F_EC_GROUP_CHECK_DISCRIMINANT = 171,
	EC_F_EC_GROUP_COPY   = 106,
	EC_F_EC_GROUP_GET_CURVE = 291,
	EC_F_EC_GROUP_GET_CURVE_GF2M = 172,
	EC_F_EC_GROUP_GET_CURVE_GFP = 130,
	EC_F_EC_GROUP_GET_DEGREE = 173,
	EC_F_EC_GROUP_GET_ECPARAMETERS = 261,
	EC_F_EC_GROUP_GET_ECPKPARAMETERS = 262,
	EC_F_EC_GROUP_GET_PENTANOMIAL_BASIS = 193,
	EC_F_EC_GROUP_GET_TRINOMIAL_BASIS = 194,
	EC_F_EC_GROUP_NEW    = 108,
	EC_F_EC_GROUP_NEW_BY_CURVE_NAME = 174,
	EC_F_EC_GROUP_NEW_FROM_DATA = 175,
	EC_F_EC_GROUP_NEW_FROM_ECPARAMETERS = 263,
	EC_F_EC_GROUP_NEW_FROM_ECPKPARAMETERS = 264,
	EC_F_EC_GROUP_SET_CURVE = 292,
	EC_F_EC_GROUP_SET_CURVE_GF2M = 176,
	EC_F_EC_GROUP_SET_CURVE_GFP = 109,
	EC_F_EC_GROUP_SET_GENERATOR = 111,
	EC_F_EC_GROUP_SET_SEED = 286,
	EC_F_EC_KEY_CHECK_KEY = 177,
	EC_F_EC_KEY_COPY     = 178,
	EC_F_EC_KEY_GENERATE_KEY = 179,
	EC_F_EC_KEY_NEW      = 182,
	EC_F_EC_KEY_NEW_METHOD = 245,
	EC_F_EC_KEY_OCT2PRIV = 255,
	EC_F_EC_KEY_PRINT    = 180,
	EC_F_EC_KEY_PRINT_FP = 181,
	EC_F_EC_KEY_PRIV2BUF = 279,
	EC_F_EC_KEY_PRIV2OCT = 256,
	EC_F_EC_KEY_SET_PUBLIC_KEY_AFFINE_COORDINATES = 229,
	EC_F_EC_KEY_SIMPLE_CHECK_KEY = 258,
	EC_F_EC_KEY_SIMPLE_OCT2PRIV = 259,
	EC_F_EC_KEY_SIMPLE_PRIV2OCT = 260,
	EC_F_EC_PKEY_CHECK   = 273,
	EC_F_EC_PKEY_PARAM_CHECK = 274,
	EC_F_EC_POINTS_MAKE_AFFINE = 136,
	EC_F_EC_POINTS_MUL   = 290,
	EC_F_EC_POINT_ADD    = 112,
	EC_F_EC_POINT_BN2POINT = 280,
	EC_F_EC_POINT_CMP    = 113,
	EC_F_EC_POINT_COPY   = 114,
	EC_F_EC_POINT_DBL    = 115,
	EC_F_EC_POINT_GET_AFFINE_COORDINATES = 293,
	EC_F_EC_POINT_GET_AFFINE_COORDINATES_GF2M = 183,
	EC_F_EC_POINT_GET_AFFINE_COORDINATES_GFP = 116,
	EC_F_EC_POINT_GET_JPROJECTIVE_COORDINATES_GFP = 117,
	EC_F_EC_POINT_INVERT = 210,
	EC_F_EC_POINT_IS_AT_INFINITY = 118,
	EC_F_EC_POINT_IS_ON_CURVE = 119,
	EC_F_EC_POINT_MAKE_AFFINE = 120,
	EC_F_EC_POINT_NEW    = 121,
	EC_F_EC_POINT_OCT2POINT = 122,
	EC_F_EC_POINT_POINT2BUF = 281,
	EC_F_EC_POINT_POINT2OCT = 123,
	EC_F_EC_POINT_SET_AFFINE_COORDINATES = 294,
	EC_F_EC_POINT_SET_AFFINE_COORDINATES_GF2M = 185,
	EC_F_EC_POINT_SET_AFFINE_COORDINATES_GFP = 124,
	EC_F_EC_POINT_SET_COMPRESSED_COORDINATES = 295,
	EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GF2M = 186,
	EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GFP = 125,
	EC_F_EC_POINT_SET_JPROJECTIVE_COORDINATES_GFP = 126,
	EC_F_EC_POINT_SET_TO_INFINITY = 127,
	EC_F_EC_PRE_COMP_NEW = 196,
	EC_F_EC_SCALAR_MUL_LADDER = 284,
	EC_F_EC_WNAF_MUL     = 187,
	EC_F_EC_WNAF_PRECOMPUTE_MULT = 188,
	EC_F_I2D_ECPARAMETERS = 190,
	EC_F_I2D_ECPKPARAMETERS = 191,
	EC_F_I2D_ECPRIVATEKEY = 192,
	EC_F_I2O_ECPUBLICKEY = 151,
	EC_F_NISTP224_PRE_COMP_NEW = 227,
	EC_F_NISTP256_PRE_COMP_NEW = 236,
	EC_F_NISTP521_PRE_COMP_NEW = 237,
	EC_F_O2I_ECPUBLICKEY = 152,
	EC_F_OLD_EC_PRIV_DECODE = 222,
	EC_F_OSSL_ECDH_COMPUTE_KEY = 247,
	EC_F_OSSL_ECDSA_SIGN_SIG = 249,
	EC_F_OSSL_ECDSA_VERIFY_SIG = 250,
	EC_F_PKEY_ECD_CTRL   = 271,
	EC_F_PKEY_ECD_DIGESTSIGN = 272,
	EC_F_PKEY_ECD_DIGESTSIGN25519 = 276,
	EC_F_PKEY_ECD_DIGESTSIGN448 = 277,
	EC_F_PKEY_ECX_DERIVE = 269,
	EC_F_PKEY_EC_CTRL    = 197,
	EC_F_PKEY_EC_CTRL_STR = 198,
	EC_F_PKEY_EC_DERIVE  = 217,
	EC_F_PKEY_EC_INIT    = 282,
	EC_F_PKEY_EC_KDF_DERIVE = 283,
	EC_F_PKEY_EC_KEYGEN  = 199,
	EC_F_PKEY_EC_PARAMGEN = 219,
	EC_F_PKEY_EC_SIGN    = 218,
	EC_F_VALIDATE_ECX_DERIVE = 278,
	EC_R_ASN1_ERROR      = 115,
	EC_R_BAD_SIGNATURE   = 156,
	EC_R_BIGNUM_OUT_OF_RANGE = 144,
	EC_R_BUFFER_TOO_SMALL = 100,
	EC_R_CANNOT_INVERT   = 165,
	EC_R_COORDINATES_OUT_OF_RANGE = 146,
	EC_R_CURVE_DOES_NOT_SUPPORT_ECDH = 160,
	EC_R_CURVE_DOES_NOT_SUPPORT_SIGNING = 159,
	EC_R_D2I_ECPKPARAMETERS_FAILURE = 117,
	EC_R_DECODE_ERROR    = 142,
	EC_R_DISCRIMINANT_IS_ZERO = 118,
	EC_R_EC_GROUP_NEW_BY_NAME_FAILURE = 119,
	EC_R_FIELD_TOO_LARGE = 143,
	EC_R_GF2M_NOT_SUPPORTED = 147,
	EC_R_GROUP2PKPARAMETERS_FAILURE = 120,
	EC_R_I2D_ECPKPARAMETERS_FAILURE = 121,
	EC_R_INCOMPATIBLE_OBJECTS = 101,
	EC_R_INVALID_ARGUMENT = 112,
	EC_R_INVALID_COMPRESSED_POINT = 110,
	EC_R_INVALID_COMPRESSION_BIT = 109,
	EC_R_INVALID_CURVE   = 141,
	EC_R_INVALID_DIGEST  = 151,
	EC_R_INVALID_DIGEST_TYPE = 138,
	EC_R_INVALID_ENCODING = 102,
	EC_R_INVALID_FIELD   = 103,
	EC_R_INVALID_FORM    = 104,
	EC_R_INVALID_GROUP_ORDER = 122,
	EC_R_INVALID_KEY     = 116,
	EC_R_INVALID_OUTPUT_LENGTH = 161,
	EC_R_INVALID_PEER_KEY = 133,
	EC_R_INVALID_PENTANOMIAL_BASIS = 132,
	EC_R_INVALID_PRIVATE_KEY = 123,
	EC_R_INVALID_TRINOMIAL_BASIS = 137,
	EC_R_KDF_PARAMETER_ERROR = 148,
	EC_R_KEYS_NOT_SET    = 140,
	EC_R_LADDER_POST_FAILURE = 136,
	EC_R_LADDER_PRE_FAILURE = 153,
	EC_R_LADDER_STEP_FAILURE = 162,
	EC_R_MISSING_PARAMETERS = 124,
	EC_R_MISSING_PRIVATE_KEY = 125,
	EC_R_NEED_NEW_SETUP_VALUES = 157,
	EC_R_NOT_A_NIST_PRIME = 135,
	EC_R_NOT_IMPLEMENTED = 126,
	EC_R_NOT_INITIALIZED = 111,
	EC_R_NO_PARAMETERS_SET = 139,
	EC_R_NO_PRIVATE_VALUE = 154,
	EC_R_OPERATION_NOT_SUPPORTED = 152,
	EC_R_PASSED_NULL_PARAMETER = 134,
	EC_R_PEER_KEY_ERROR  = 149,
	EC_R_PKPARAMETERS2GROUP_FAILURE = 127,
	EC_R_POINT_ARITHMETIC_FAILURE = 155,
	EC_R_POINT_AT_INFINITY = 106,
	EC_R_POINT_COORDINATES_BLIND_FAILURE = 163,
	EC_R_POINT_IS_NOT_ON_CURVE = 107,
	EC_R_RANDOM_NUMBER_GENERATION_FAILED = 158,
	EC_R_SHARED_INFO_ERROR = 150,
	EC_R_SLOT_FULL       = 108,
	EC_R_UNDEFINED_GENERATOR = 113,
	EC_R_UNDEFINED_ORDER = 128,
	EC_R_UNKNOWN_COFACTOR = 164,
	EC_R_UNKNOWN_GROUP   = 129,
	EC_R_UNKNOWN_ORDER   = 114,
	EC_R_UNSUPPORTED_FIELD = 131,
	EC_R_WRONG_CURVE_PARAMETERS = 145,
	EC_R_WRONG_ORDER     = 130,
};
