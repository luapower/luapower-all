local ffi = require'ffi'
require'bearssl_rsa_h'
require'bearssl_ec_h'
ffi.cdef[[
enum {
	BR_ERR_X509_OK       = 32,
	BR_ERR_X509_INVALID_VALUE = 33,
	BR_ERR_X509_TRUNCATED = 34,
	BR_ERR_X509_EMPTY_CHAIN = 35,
	BR_ERR_X509_INNER_TRUNC = 36,
	BR_ERR_X509_BAD_TAG_CLASS = 37,
	BR_ERR_X509_BAD_TAG_VALUE = 38,
	BR_ERR_X509_INDEFINITE_LENGTH = 39,
	BR_ERR_X509_EXTRA_ELEMENT = 40,
	BR_ERR_X509_UNEXPECTED = 41,
	BR_ERR_X509_NOT_CONSTRUCTED = 42,
	BR_ERR_X509_NOT_PRIMITIVE = 43,
	BR_ERR_X509_PARTIAL_BYTE = 44,
	BR_ERR_X509_BAD_BOOLEAN = 45,
	BR_ERR_X509_OVERFLOW = 46,
	BR_ERR_X509_BAD_DN   = 47,
	BR_ERR_X509_BAD_TIME = 48,
	BR_ERR_X509_UNSUPPORTED = 49,
	BR_ERR_X509_LIMIT_EXCEEDED = 50,
	BR_ERR_X509_WRONG_KEY_TYPE = 51,
	BR_ERR_X509_BAD_SIGNATURE = 52,
	BR_ERR_X509_TIME_UNKNOWN = 53,
	BR_ERR_X509_EXPIRED  = 54,
	BR_ERR_X509_DN_MISMATCH = 55,
	BR_ERR_X509_BAD_SERVER_NAME = 56,
	BR_ERR_X509_CRITICAL_EXTENSION = 57,
	BR_ERR_X509_NOT_CA   = 58,
	BR_ERR_X509_FORBIDDEN_KEY_USAGE = 59,
	BR_ERR_X509_WEAK_PUBLIC_KEY = 60,
	BR_ERR_X509_NOT_TRUSTED = 62,
};
typedef struct {
 unsigned char key_type;
 union {
  br_rsa_public_key rsa;
  br_ec_public_key ec;
 } key;
} br_x509_pkey;
typedef struct {
 unsigned char *data;
 size_t len;
} br_x500_name;
typedef struct {
 br_x500_name dn;
 unsigned flags;
 br_x509_pkey pkey;
} br_x509_trust_anchor;
enum {
	BR_X509_TA_CA        = 0x0001,
	BR_KEYTYPE_RSA       = 1,
	BR_KEYTYPE_EC        = 2,
	BR_KEYTYPE_KEYX      = 0x10,
	BR_KEYTYPE_SIGN      = 0x20,
};
typedef struct br_x509_class_ br_x509_class;
struct br_x509_class_ {
 size_t context_size;
 void (*start_chain)(const br_x509_class **ctx,
  const char *server_name);
 void (*start_cert)(const br_x509_class **ctx, uint32_t length);
 void (*append)(const br_x509_class **ctx,
  const unsigned char *buf, size_t len);
 void (*end_cert)(const br_x509_class **ctx);
 unsigned (*end_chain)(const br_x509_class **ctx);
 const br_x509_pkey *(*get_pkey)(
  const br_x509_class *const *ctx, unsigned *usages);
};
typedef struct {
 const br_x509_class *vtable;
 br_x509_pkey pkey;
 unsigned usages;
} br_x509_knownkey_context;
extern const br_x509_class br_x509_knownkey_vtable;
void br_x509_knownkey_init_rsa(br_x509_knownkey_context *ctx,
 const br_rsa_public_key *pk, unsigned usages);
void br_x509_knownkey_init_ec(br_x509_knownkey_context *ctx,
 const br_ec_public_key *pk, unsigned usages);
enum {
	BR_X509_BUFSIZE_KEY  = 520,
	BR_X509_BUFSIZE_SIG  = 512,
};
typedef struct {
 const unsigned char *oid;
 char *buf;
 size_t len;
 int status;
} br_name_element;
typedef struct {
 const br_x509_class *vtable;
 br_x509_pkey pkey;
 struct {
  uint32_t *dp;
  uint32_t *rp;
  const unsigned char *ip;
 } cpu;
 uint32_t dp_stack[32];
 uint32_t rp_stack[32];
 int err;
 const char *server_name;
 unsigned char key_usages;
 uint32_t days, seconds;
 uint32_t cert_length;
 uint32_t num_certs;
 const unsigned char *hbuf;
 size_t hlen;
 unsigned char pad[256];
 unsigned char ee_pkey_data[520];
 unsigned char pkey_data[520];
 unsigned char cert_signer_key_type;
 uint16_t cert_sig_hash_oid;
 unsigned char cert_sig_hash_len;
 unsigned char cert_sig[512];
 uint16_t cert_sig_len;
 int16_t min_rsa_size;
 const br_x509_trust_anchor *trust_anchors;
 size_t trust_anchors_num;
 unsigned char do_mhash;
 br_multihash_context mhash;
 unsigned char tbs_hash[64];
 unsigned char do_dn_hash;
 const br_hash_class *dn_hash_impl;
 br_hash_compat_context dn_hash;
 unsigned char current_dn_hash[64];
 unsigned char next_dn_hash[64];
 unsigned char saved_dn_hash[64];
 br_name_element *name_elts;
 size_t num_name_elts;
 br_rsa_pkcs1_vrfy irsa;
 br_ecdsa_vrfy iecdsa;
 const br_ec_impl *iec;
} br_x509_minimal_context;
extern const br_x509_class br_x509_minimal_vtable;
void br_x509_minimal_init(br_x509_minimal_context *ctx,
 const br_hash_class *dn_hash_impl,
 const br_x509_trust_anchor *trust_anchors, size_t trust_anchors_num);
static inline void
br_x509_minimal_set_hash(br_x509_minimal_context *ctx,
 int id, const br_hash_class *impl)
{
 br_multihash_setimpl(&ctx->mhash, id, impl);
}
static inline void
br_x509_minimal_set_rsa(br_x509_minimal_context *ctx,
 br_rsa_pkcs1_vrfy irsa)
{
 ctx->irsa = irsa;
}
static inline void
br_x509_minimal_set_ecdsa(br_x509_minimal_context *ctx,
 const br_ec_impl *iec, br_ecdsa_vrfy iecdsa)
{
 ctx->iecdsa = iecdsa;
 ctx->iec = iec;
}
void br_x509_minimal_init_full(br_x509_minimal_context *ctx,
 const br_x509_trust_anchor *trust_anchors, size_t trust_anchors_num);
static inline void
br_x509_minimal_set_time(br_x509_minimal_context *ctx,
 uint32_t days, uint32_t seconds)
{
 ctx->days = days;
 ctx->seconds = seconds;
}
static inline void
br_x509_minimal_set_minrsa(br_x509_minimal_context *ctx, int byte_length)
{
 ctx->min_rsa_size = (int16_t)(byte_length - 128);
}
static inline void
br_x509_minimal_set_name_elements(br_x509_minimal_context *ctx,
 br_name_element *elts, size_t num_elts)
{
 ctx->name_elts = elts;
 ctx->num_name_elts = num_elts;
}
typedef struct {
 br_x509_pkey pkey;
 struct {
  uint32_t *dp;
  uint32_t *rp;
  const unsigned char *ip;
 } cpu;
 uint32_t dp_stack[32];
 uint32_t rp_stack[32];
 int err;
 unsigned char pad[256];
 unsigned char decoded;
 uint32_t notbefore_days, notbefore_seconds;
 uint32_t notafter_days, notafter_seconds;
 unsigned char isCA;
 unsigned char copy_dn;
 void *append_dn_ctx;
 void (*append_dn)(void *ctx, const void *buf, size_t len);
 const unsigned char *hbuf;
 size_t hlen;
 unsigned char pkey_data[520];
 unsigned char signer_key_type;
 unsigned char signer_hash_id;
} br_x509_decoder_context;
void br_x509_decoder_init(br_x509_decoder_context *ctx,
 void (*append_dn)(void *ctx, const void *buf, size_t len),
 void *append_dn_ctx);
void br_x509_decoder_push(br_x509_decoder_context *ctx,
 const void *data, size_t len);
static inline br_x509_pkey *
br_x509_decoder_get_pkey(br_x509_decoder_context *ctx)
{
 if (ctx->decoded && ctx->err == 0) {
  return &ctx->pkey;
 } else {
  return
        ((void *)0)
            ;
 }
}
static inline int
br_x509_decoder_last_error(br_x509_decoder_context *ctx)
{
 if (ctx->err != 0) {
  return ctx->err;
 }
 if (!ctx->decoded) {
  return 34;
 }
 return 0;
}
static inline int
br_x509_decoder_isCA(br_x509_decoder_context *ctx)
{
 return ctx->isCA;
}
static inline int
br_x509_decoder_get_signer_key_type(br_x509_decoder_context *ctx)
{
 return ctx->signer_key_type;
}
static inline int
br_x509_decoder_get_signer_hash_id(br_x509_decoder_context *ctx)
{
 return ctx->signer_hash_id;
}
typedef struct {
 unsigned char *data;
 size_t data_len;
} br_x509_certificate;
typedef struct {
 union {
  br_rsa_private_key rsa;
  br_ec_private_key ec;
 } key;
 struct {
  uint32_t *dp;
  uint32_t *rp;
  const unsigned char *ip;
 } cpu;
 uint32_t dp_stack[32];
 uint32_t rp_stack[32];
 int err;
 const unsigned char *hbuf;
 size_t hlen;
 unsigned char pad[256];
 unsigned char key_type;
 unsigned char key_data[3 * 512];
} br_skey_decoder_context;
void br_skey_decoder_init(br_skey_decoder_context *ctx);
void br_skey_decoder_push(br_skey_decoder_context *ctx,
 const void *data, size_t len);
static inline int
br_skey_decoder_last_error(const br_skey_decoder_context *ctx)
{
 if (ctx->err != 0) {
  return ctx->err;
 }
 if (ctx->key_type == 0) {
  return 34;
 }
 return 0;
}
static inline int
br_skey_decoder_key_type(const br_skey_decoder_context *ctx)
{
 if (ctx->err == 0) {
  return ctx->key_type;
 } else {
  return 0;
 }
}
static inline const br_rsa_private_key *
br_skey_decoder_get_rsa(const br_skey_decoder_context *ctx)
{
 if (ctx->err == 0 && ctx->key_type == 1) {
  return &ctx->key.rsa;
 } else {
  return
        ((void *)0)
            ;
 }
}
static inline const br_ec_private_key *
br_skey_decoder_get_ec(const br_skey_decoder_context *ctx)
{
 if (ctx->err == 0 && ctx->key_type == 2) {
  return &ctx->key.ec;
 } else {
  return
        ((void *)0)
            ;
 }
}
size_t br_encode_rsa_raw_der(void *dest, const br_rsa_private_key *sk,
 const br_rsa_public_key *pk, const void *d, size_t dlen);
size_t br_encode_rsa_pkcs8_der(void *dest, const br_rsa_private_key *sk,
 const br_rsa_public_key *pk, const void *d, size_t dlen);
size_t br_encode_ec_raw_der(void *dest,
 const br_ec_private_key *sk, const br_ec_public_key *pk);
size_t br_encode_ec_pkcs8_der(void *dest,
 const br_ec_private_key *sk, const br_ec_public_key *pk);
]]
