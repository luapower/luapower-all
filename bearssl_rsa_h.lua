local ffi = require'ffi'
require'bearssl_hash_h'
require'bearssl_rand_h'
ffi.cdef[[
typedef struct {
	unsigned char *n;
	size_t nlen;
	unsigned char *e;
	size_t elen;
} br_rsa_public_key;
typedef struct {
	uint32_t n_bitlen;
	unsigned char *p;
	size_t plen;
	unsigned char *q;
	size_t qlen;
	unsigned char *dp;
	size_t dplen;
	unsigned char *dq;
	size_t dqlen;
	unsigned char *iq;
	size_t iqlen;
} br_rsa_private_key;
typedef uint32_t (*br_rsa_public)(unsigned char *x, size_t xlen,
	const br_rsa_public_key *pk);
typedef uint32_t (*br_rsa_pkcs1_vrfy)(const unsigned char *x, size_t xlen,
	const unsigned char *hash_oid, size_t hash_len,
	const br_rsa_public_key *pk, unsigned char *hash_out);
typedef uint32_t (*br_rsa_pss_vrfy)(const unsigned char *x, size_t xlen,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const void *hash, size_t salt_len, const br_rsa_public_key *pk);
typedef size_t (*br_rsa_oaep_encrypt)(
	const br_prng_class **rnd, const br_hash_class *dig,
	const void *label, size_t label_len,
	const br_rsa_public_key *pk,
	void *dst, size_t dst_max_len,
	const void *src, size_t src_len);
typedef uint32_t (*br_rsa_private)(unsigned char *x,
	const br_rsa_private_key *sk);
typedef uint32_t (*br_rsa_pkcs1_sign)(const unsigned char *hash_oid,
	const unsigned char *hash, size_t hash_len,
	const br_rsa_private_key *sk, unsigned char *x);
typedef uint32_t (*br_rsa_pss_sign)(const br_prng_class **rng,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const unsigned char *hash_value, size_t salt_len,
	const br_rsa_private_key *sk, unsigned char *x);
typedef uint32_t (*br_rsa_oaep_decrypt)(
	const br_hash_class *dig, const void *label, size_t label_len,
	const br_rsa_private_key *sk, void *data, size_t *len);
uint32_t br_rsa_i32_public(unsigned char *x, size_t xlen,
	const br_rsa_public_key *pk);
uint32_t br_rsa_i32_pkcs1_vrfy(const unsigned char *x, size_t xlen,
	const unsigned char *hash_oid, size_t hash_len,
	const br_rsa_public_key *pk, unsigned char *hash_out);
uint32_t br_rsa_i32_pss_vrfy(const unsigned char *x, size_t xlen,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const void *hash, size_t salt_len, const br_rsa_public_key *pk);
uint32_t br_rsa_i32_private(unsigned char *x,
	const br_rsa_private_key *sk);
uint32_t br_rsa_i32_pkcs1_sign(const unsigned char *hash_oid,
	const unsigned char *hash, size_t hash_len,
	const br_rsa_private_key *sk, unsigned char *x);
uint32_t br_rsa_i32_pss_sign(const br_prng_class **rng,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const unsigned char *hash_value, size_t salt_len,
	const br_rsa_private_key *sk, unsigned char *x);
uint32_t br_rsa_i31_public(unsigned char *x, size_t xlen,
	const br_rsa_public_key *pk);
uint32_t br_rsa_i31_pkcs1_vrfy(const unsigned char *x, size_t xlen,
	const unsigned char *hash_oid, size_t hash_len,
	const br_rsa_public_key *pk, unsigned char *hash_out);
uint32_t br_rsa_i31_pss_vrfy(const unsigned char *x, size_t xlen,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const void *hash, size_t salt_len, const br_rsa_public_key *pk);
uint32_t br_rsa_i31_private(unsigned char *x,
	const br_rsa_private_key *sk);
uint32_t br_rsa_i31_pkcs1_sign(const unsigned char *hash_oid,
	const unsigned char *hash, size_t hash_len,
	const br_rsa_private_key *sk, unsigned char *x);
uint32_t br_rsa_i31_pss_sign(const br_prng_class **rng,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const unsigned char *hash_value, size_t salt_len,
	const br_rsa_private_key *sk, unsigned char *x);
uint32_t br_rsa_i62_public(unsigned char *x, size_t xlen,
	const br_rsa_public_key *pk);
uint32_t br_rsa_i62_pkcs1_vrfy(const unsigned char *x, size_t xlen,
	const unsigned char *hash_oid, size_t hash_len,
	const br_rsa_public_key *pk, unsigned char *hash_out);
uint32_t br_rsa_i62_pss_vrfy(const unsigned char *x, size_t xlen,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const void *hash, size_t salt_len, const br_rsa_public_key *pk);
uint32_t br_rsa_i62_private(unsigned char *x,
	const br_rsa_private_key *sk);
uint32_t br_rsa_i62_pkcs1_sign(const unsigned char *hash_oid,
	const unsigned char *hash, size_t hash_len,
	const br_rsa_private_key *sk, unsigned char *x);
uint32_t br_rsa_i62_pss_sign(const br_prng_class **rng,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const unsigned char *hash_value, size_t salt_len,
	const br_rsa_private_key *sk, unsigned char *x);
br_rsa_public br_rsa_i62_public_get(void);
br_rsa_pkcs1_vrfy br_rsa_i62_pkcs1_vrfy_get(void);
br_rsa_pss_vrfy br_rsa_i62_pss_vrfy_get(void);
br_rsa_private br_rsa_i62_private_get(void);
br_rsa_pkcs1_sign br_rsa_i62_pkcs1_sign_get(void);
br_rsa_pss_sign br_rsa_i62_pss_sign_get(void);
br_rsa_oaep_encrypt br_rsa_i62_oaep_encrypt_get(void);
br_rsa_oaep_decrypt br_rsa_i62_oaep_decrypt_get(void);
uint32_t br_rsa_i15_public(unsigned char *x, size_t xlen,
	const br_rsa_public_key *pk);
uint32_t br_rsa_i15_pkcs1_vrfy(const unsigned char *x, size_t xlen,
	const unsigned char *hash_oid, size_t hash_len,
	const br_rsa_public_key *pk, unsigned char *hash_out);
uint32_t br_rsa_i15_pss_vrfy(const unsigned char *x, size_t xlen,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const void *hash, size_t salt_len, const br_rsa_public_key *pk);
uint32_t br_rsa_i15_private(unsigned char *x,
	const br_rsa_private_key *sk);
uint32_t br_rsa_i15_pkcs1_sign(const unsigned char *hash_oid,
	const unsigned char *hash, size_t hash_len,
	const br_rsa_private_key *sk, unsigned char *x);
uint32_t br_rsa_i15_pss_sign(const br_prng_class **rng,
	const br_hash_class *hf_data, const br_hash_class *hf_mgf1,
	const unsigned char *hash_value, size_t salt_len,
	const br_rsa_private_key *sk, unsigned char *x);
br_rsa_public br_rsa_public_get_default(void);
br_rsa_private br_rsa_private_get_default(void);
br_rsa_pkcs1_vrfy br_rsa_pkcs1_vrfy_get_default(void);
br_rsa_pss_vrfy br_rsa_pss_vrfy_get_default(void);
br_rsa_pkcs1_sign br_rsa_pkcs1_sign_get_default(void);
br_rsa_pss_sign br_rsa_pss_sign_get_default(void);
br_rsa_oaep_encrypt br_rsa_oaep_encrypt_get_default(void);
br_rsa_oaep_decrypt br_rsa_oaep_decrypt_get_default(void);
uint32_t br_rsa_ssl_decrypt(br_rsa_private core, const br_rsa_private_key *sk,
	unsigned char *data, size_t len);
size_t br_rsa_i15_oaep_encrypt(
	const br_prng_class **rnd, const br_hash_class *dig,
	const void *label, size_t label_len,
	const br_rsa_public_key *pk,
	void *dst, size_t dst_max_len,
	const void *src, size_t src_len);
uint32_t br_rsa_i15_oaep_decrypt(
	const br_hash_class *dig, const void *label, size_t label_len,
	const br_rsa_private_key *sk, void *data, size_t *len);
size_t br_rsa_i31_oaep_encrypt(
	const br_prng_class **rnd, const br_hash_class *dig,
	const void *label, size_t label_len,
	const br_rsa_public_key *pk,
	void *dst, size_t dst_max_len,
	const void *src, size_t src_len);
uint32_t br_rsa_i31_oaep_decrypt(
	const br_hash_class *dig, const void *label, size_t label_len,
	const br_rsa_private_key *sk, void *data, size_t *len);
size_t br_rsa_i32_oaep_encrypt(
	const br_prng_class **rnd, const br_hash_class *dig,
	const void *label, size_t label_len,
	const br_rsa_public_key *pk,
	void *dst, size_t dst_max_len,
	const void *src, size_t src_len);
uint32_t br_rsa_i32_oaep_decrypt(
	const br_hash_class *dig, const void *label, size_t label_len,
	const br_rsa_private_key *sk, void *data, size_t *len);
size_t br_rsa_i62_oaep_encrypt(
	const br_prng_class **rnd, const br_hash_class *dig,
	const void *label, size_t label_len,
	const br_rsa_public_key *pk,
	void *dst, size_t dst_max_len,
	const void *src, size_t src_len);
uint32_t br_rsa_i62_oaep_decrypt(
	const br_hash_class *dig, const void *label, size_t label_len,
	const br_rsa_private_key *sk, void *data, size_t *len);
typedef uint32_t (*br_rsa_keygen)(
	const br_prng_class **rng_ctx,
	br_rsa_private_key *sk, void *kbuf_priv,
	br_rsa_public_key *pk, void *kbuf_pub,
	unsigned size, uint32_t pubexp);
uint32_t br_rsa_i15_keygen(
	const br_prng_class **rng_ctx,
	br_rsa_private_key *sk, void *kbuf_priv,
	br_rsa_public_key *pk, void *kbuf_pub,
	unsigned size, uint32_t pubexp);
uint32_t br_rsa_i31_keygen(
	const br_prng_class **rng_ctx,
	br_rsa_private_key *sk, void *kbuf_priv,
	br_rsa_public_key *pk, void *kbuf_pub,
	unsigned size, uint32_t pubexp);
uint32_t br_rsa_i62_keygen(
	const br_prng_class **rng_ctx,
	br_rsa_private_key *sk, void *kbuf_priv,
	br_rsa_public_key *pk, void *kbuf_pub,
	unsigned size, uint32_t pubexp);
br_rsa_keygen br_rsa_i62_keygen_get(void);
br_rsa_keygen br_rsa_keygen_get_default(void);
typedef size_t (*br_rsa_compute_modulus)(void *n, const br_rsa_private_key *sk);
size_t br_rsa_i15_compute_modulus(void *n, const br_rsa_private_key *sk);
size_t br_rsa_i31_compute_modulus(void *n, const br_rsa_private_key *sk);
br_rsa_compute_modulus br_rsa_compute_modulus_get_default(void);
typedef uint32_t (*br_rsa_compute_pubexp)(const br_rsa_private_key *sk);
uint32_t br_rsa_i15_compute_pubexp(const br_rsa_private_key *sk);
uint32_t br_rsa_i31_compute_pubexp(const br_rsa_private_key *sk);
br_rsa_compute_pubexp br_rsa_compute_pubexp_get_default(void);
typedef size_t (*br_rsa_compute_privexp)(void *d,
	const br_rsa_private_key *sk, uint32_t pubexp);
size_t br_rsa_i15_compute_privexp(void *d,
	const br_rsa_private_key *sk, uint32_t pubexp);
size_t br_rsa_i31_compute_privexp(void *d,
	const br_rsa_private_key *sk, uint32_t pubexp);
br_rsa_compute_privexp br_rsa_compute_privexp_get_default(void);
]]
