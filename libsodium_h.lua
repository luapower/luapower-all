--`mgit precompile csrc\libsodium\include\sodium.h` from libsodium 1.0.3

local ffi = require'ffi'

ffi.cdef[[
// sodium/core.h
int sodium_init(void);

// sodium/crypto_aead_chacha20poly1305.h
enum {
	crypto_aead_chacha20poly1305_KEYBYTES = 32U,
	crypto_aead_chacha20poly1305_NSECBYTES = 0U,
	crypto_aead_chacha20poly1305_NPUBBYTES = 8U,
	crypto_aead_chacha20poly1305_ABYTES = 16U,
	crypto_aead_chacha20poly1305_IETF_NPUBBYTES = 12U,
};
size_t crypto_aead_chacha20poly1305_keybytes(void);
size_t crypto_aead_chacha20poly1305_nsecbytes(void);
size_t crypto_aead_chacha20poly1305_npubbytes(void);
size_t crypto_aead_chacha20poly1305_abytes(void);
int crypto_aead_chacha20poly1305_encrypt(unsigned char *c,
                                         unsigned long long *clen_p,
                                         const unsigned char *m,
                                         unsigned long long mlen,
                                         const unsigned char *ad,
                                         unsigned long long adlen,
                                         const unsigned char *nsec,
                                         const unsigned char *npub,
                                         const unsigned char *k);
int crypto_aead_chacha20poly1305_decrypt(unsigned char *m,
                                         unsigned long long *mlen_p,
                                         unsigned char *nsec,
                                         const unsigned char *c,
                                         unsigned long long clen,
                                         const unsigned char *ad,
                                         unsigned long long adlen,
                                         const unsigned char *npub,
                                         const unsigned char *k);
size_t crypto_aead_chacha20poly1305_ietf_npubbytes(void);
int crypto_aead_chacha20poly1305_ietf_encrypt(unsigned char *c,
                                              unsigned long long *clen_p,
                                              const unsigned char *m,
                                              unsigned long long mlen,
                                              const unsigned char *ad,
                                              unsigned long long adlen,
                                              const unsigned char *nsec,
                                              const unsigned char *npub,
                                              const unsigned char *k);
int crypto_aead_chacha20poly1305_ietf_decrypt(unsigned char *m,
                                              unsigned long long *mlen_p,
                                              unsigned char *nsec,
                                              const unsigned char *c,
                                              unsigned long long clen,
                                              const unsigned char *ad,
                                              unsigned long long adlen,
                                              const unsigned char *npub,
                                              const unsigned char *k);


// sodium/crypto_auth.h
size_t crypto_auth_bytes(void);
size_t crypto_auth_keybytes(void);
const char *crypto_auth_primitive(void);
int crypto_auth(unsigned char *out, const unsigned char *in,
                unsigned long long inlen, const unsigned char *k);
int crypto_auth_verify(const unsigned char *h, const unsigned char *in,
                       unsigned long long inlen, const unsigned char *k);

// sodium/crypto_hash_sha256.h
enum {
	crypto_hash_sha256_BYTES = 32U,
};
typedef struct crypto_hash_sha256_state {
    uint32_t state[8];
    uint64_t count;
    unsigned char buf[64];
} crypto_hash_sha256_state;
size_t crypto_hash_sha256_statebytes(void);
size_t crypto_hash_sha256_bytes(void);
int crypto_hash_sha256(unsigned char *out, const unsigned char *in,
                       unsigned long long inlen);
int crypto_hash_sha256_init(crypto_hash_sha256_state *state);
int crypto_hash_sha256_update(crypto_hash_sha256_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);
int crypto_hash_sha256_final(crypto_hash_sha256_state *state,
                             unsigned char *out);

// sodium/crypto_hash_sha512.h
enum {
	crypto_hash_sha512_BYTES = 64U,
};
typedef struct crypto_hash_sha512_state {
    uint64_t state[8];
    uint64_t count[2];
    unsigned char buf[128];
} crypto_hash_sha512_state;
size_t crypto_hash_sha512_statebytes(void);
size_t crypto_hash_sha512_bytes(void);
int crypto_hash_sha512(unsigned char *out, const unsigned char *in,
                       unsigned long long inlen);
int crypto_hash_sha512_init(crypto_hash_sha512_state *state);
int crypto_hash_sha512_update(crypto_hash_sha512_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);
int crypto_hash_sha512_final(crypto_hash_sha512_state *state,
                             unsigned char *out);

// sodium/crypto_auth_hmacsha256.h
enum {
	crypto_auth_hmacsha256_BYTES = 32U,
	crypto_auth_hmacsha256_KEYBYTES = 32U,
};
size_t crypto_auth_hmacsha256_bytes(void);
size_t crypto_auth_hmacsha256_keybytes(void);
int crypto_auth_hmacsha256(unsigned char *out,
                           const unsigned char *in,
                           unsigned long long inlen,
                           const unsigned char *k);
int crypto_auth_hmacsha256_verify(const unsigned char *h,
                                  const unsigned char *in,
                                  unsigned long long inlen,
                                  const unsigned char *k);
typedef struct crypto_auth_hmacsha256_state {
	crypto_hash_sha256_state ictx;
	crypto_hash_sha256_state octx;
} crypto_auth_hmacsha256_state;
size_t crypto_auth_hmacsha256_statebytes(void);
int crypto_auth_hmacsha256_init(crypto_auth_hmacsha256_state *state,
                                const unsigned char *key,
                                size_t keylen);
int crypto_auth_hmacsha256_update(crypto_auth_hmacsha256_state *state,
                                  const unsigned char *in,
                                  unsigned long long inlen);
int crypto_auth_hmacsha256_final(crypto_auth_hmacsha256_state *state,
                                 unsigned char *out);

// sodium/crypto_auth_hmacsha512.h
enum {
	crypto_auth_hmacsha512_BYTES = 64U,
	crypto_auth_hmacsha512_KEYBYTES = 32U,
};
size_t crypto_auth_hmacsha512_bytes(void);
size_t crypto_auth_hmacsha512_keybytes(void);
int crypto_auth_hmacsha512(unsigned char *out,
                           const unsigned char *in,
                           unsigned long long inlen,
                           const unsigned char *k);
int crypto_auth_hmacsha512_verify(const unsigned char *h,
                                  const unsigned char *in,
                                  unsigned long long inlen,
                                  const unsigned char *k);
typedef struct crypto_auth_hmacsha512_state {
    crypto_hash_sha512_state ictx;
    crypto_hash_sha512_state octx;
} crypto_auth_hmacsha512_state;
size_t crypto_auth_hmacsha512_statebytes(void);
int crypto_auth_hmacsha512_init(crypto_auth_hmacsha512_state *state,
                                const unsigned char *key,
                                size_t keylen);
int crypto_auth_hmacsha512_update(crypto_auth_hmacsha512_state *state,
                                  const unsigned char *in,
                                  unsigned long long inlen);
int crypto_auth_hmacsha512_final(crypto_auth_hmacsha512_state *state,
                                 unsigned char *out);


// sodium/crypto_auth_hmacsha512256.h
enum {
	crypto_auth_hmacsha512256_BYTES = 32U,
	crypto_auth_hmacsha512256_KEYBYTES = 32U,
};
size_t crypto_auth_hmacsha512256_bytes(void);
size_t crypto_auth_hmacsha512256_keybytes(void);
int crypto_auth_hmacsha512256(unsigned char *out, const unsigned char *in,
                              unsigned long long inlen,const unsigned char *k);
int crypto_auth_hmacsha512256_verify(const unsigned char *h,
                                     const unsigned char *in,
                                     unsigned long long inlen,
                                     const unsigned char *k);
typedef crypto_auth_hmacsha512_state crypto_auth_hmacsha512256_state;
size_t crypto_auth_hmacsha512256_statebytes(void);
int crypto_auth_hmacsha512256_init(crypto_auth_hmacsha512256_state *state,
                                   const unsigned char *key,
                                   size_t keylen);
int crypto_auth_hmacsha512256_update(crypto_auth_hmacsha512256_state *state,
                                     const unsigned char *in,
                                     unsigned long long inlen);
int crypto_auth_hmacsha512256_final(crypto_auth_hmacsha512256_state *state,
                                    unsigned char *out);

// sodium/crypto_box.h
size_t crypto_box_seedbytes(void);
size_t crypto_box_publickeybytes(void);
size_t crypto_box_secretkeybytes(void);
size_t crypto_box_noncebytes(void);
size_t crypto_box_macbytes(void);
const char *crypto_box_primitive(void);
int crypto_box_seed_keypair(unsigned char *pk, unsigned char *sk,
                            const unsigned char *seed);
int crypto_box_keypair(unsigned char *pk, unsigned char *sk);
int crypto_box_easy(unsigned char *c, const unsigned char *m,
                    unsigned long long mlen, const unsigned char *n,
                    const unsigned char *pk, const unsigned char *sk);
int crypto_box_open_easy(unsigned char *m, const unsigned char *c,
                         unsigned long long clen, const unsigned char *n,
                         const unsigned char *pk, const unsigned char *sk);
int crypto_box_detached(unsigned char *c, unsigned char *mac,
                        const unsigned char *m, unsigned long long mlen,
                        const unsigned char *n, const unsigned char *pk,
                        const unsigned char *sk);
int crypto_box_open_detached(unsigned char *m, const unsigned char *c,
                             const unsigned char *mac,
                             unsigned long long clen,
                             const unsigned char *n,
                             const unsigned char *pk,
                             const unsigned char *sk);
size_t crypto_box_beforenmbytes(void);
int crypto_box_beforenm(unsigned char *k, const unsigned char *pk,
                        const unsigned char *sk);
int crypto_box_easy_afternm(unsigned char *c, const unsigned char *m,
                            unsigned long long mlen, const unsigned char *n,
                            const unsigned char *k);
int crypto_box_open_easy_afternm(unsigned char *m, const unsigned char *c,
                                 unsigned long long clen, const unsigned char *n,
                                 const unsigned char *k);
int crypto_box_detached_afternm(unsigned char *c, unsigned char *mac,
                                const unsigned char *m, unsigned long long mlen,
                                const unsigned char *n, const unsigned char *k);
int crypto_box_open_detached_afternm(unsigned char *m, const unsigned char *c,
                                     const unsigned char *mac,
                                     unsigned long long clen, const unsigned char *n,
                                     const unsigned char *k);
size_t crypto_box_sealbytes(void);
int crypto_box_seal(unsigned char *c, const unsigned char *m,
                    unsigned long long mlen, const unsigned char *pk);
int crypto_box_seal_open(unsigned char *m, const unsigned char *c,
                         unsigned long long clen,
                         const unsigned char *pk, const unsigned char *sk);
size_t crypto_box_zerobytes(void);
size_t crypto_box_boxzerobytes(void);
int crypto_box(unsigned char *c, const unsigned char *m,
               unsigned long long mlen, const unsigned char *n,
               const unsigned char *pk, const unsigned char *sk);
int crypto_box_open(unsigned char *m, const unsigned char *c,
                    unsigned long long clen, const unsigned char *n,
                    const unsigned char *pk, const unsigned char *sk);
int crypto_box_afternm(unsigned char *c, const unsigned char *m,
                       unsigned long long mlen, const unsigned char *n,
                       const unsigned char *k);
int crypto_box_open_afternm(unsigned char *m, const unsigned char *c,
                            unsigned long long clen, const unsigned char *n,
                            const unsigned char *k);

// sodium/crypto_box_curve25519xsalsa20poly1305.h
enum {
	crypto_box_curve25519xsalsa20poly1305_SEEDBYTES = 32U,
	crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES = 32U,
	crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES = 32U,
	crypto_box_curve25519xsalsa20poly1305_BEFORENMBYTES = 32U,
	crypto_box_curve25519xsalsa20poly1305_NONCEBYTES = 24U,
	crypto_box_curve25519xsalsa20poly1305_ZEROBYTES = 32U,
	crypto_box_curve25519xsalsa20poly1305_BOXZEROBYTES = 16U,
	crypto_box_curve25519xsalsa20poly1305_MACBYTES = (crypto_box_curve25519xsalsa20poly1305_ZEROBYTES - crypto_box_curve25519xsalsa20poly1305_BOXZEROBYTES),
};
size_t crypto_box_curve25519xsalsa20poly1305_seedbytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_publickeybytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_secretkeybytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_beforenmbytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_noncebytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_zerobytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_boxzerobytes(void);
size_t crypto_box_curve25519xsalsa20poly1305_macbytes(void);
int crypto_box_curve25519xsalsa20poly1305(unsigned char *c,
                                          const unsigned char *m,
                                          unsigned long long mlen,
                                          const unsigned char *n,
                                          const unsigned char *pk,
                                          const unsigned char *sk);
int crypto_box_curve25519xsalsa20poly1305_open(unsigned char *m,
                                               const unsigned char *c,
                                               unsigned long long clen,
                                               const unsigned char *n,
                                               const unsigned char *pk,
                                               const unsigned char *sk);
int crypto_box_curve25519xsalsa20poly1305_seed_keypair(unsigned char *pk,
                                                       unsigned char *sk,
                                                       const unsigned char *seed);
int crypto_box_curve25519xsalsa20poly1305_keypair(unsigned char *pk,
                                                  unsigned char *sk);
int crypto_box_curve25519xsalsa20poly1305_beforenm(unsigned char *k,
                                                   const unsigned char *pk,
                                                   const unsigned char *sk);
int crypto_box_curve25519xsalsa20poly1305_afternm(unsigned char *c,
                                                  const unsigned char *m,
                                                  unsigned long long mlen,
                                                  const unsigned char *n,
                                                  const unsigned char *k);
int crypto_box_curve25519xsalsa20poly1305_open_afternm(unsigned char *m,
                                                       const unsigned char *c,
                                                       unsigned long long clen,
                                                       const unsigned char *n,
                                                       const unsigned char *k);

// sodium/crypto_core_hsalsa20.h
enum {
	crypto_core_hsalsa20_OUTPUTBYTES = 32U,
	crypto_core_hsalsa20_INPUTBYTES = 16U,
	crypto_core_hsalsa20_KEYBYTES = 32U,
	crypto_core_hsalsa20_CONSTBYTES = 16U,
};
size_t crypto_core_hsalsa20_outputbytes(void);
size_t crypto_core_hsalsa20_inputbytes(void);
size_t crypto_core_hsalsa20_keybytes(void);
size_t crypto_core_hsalsa20_constbytes(void);
int crypto_core_hsalsa20(unsigned char *out, const unsigned char *in,
                         const unsigned char *k, const unsigned char *c);

// sodium/crypto_core_salsa20.h
enum {
	crypto_core_salsa20_OUTPUTBYTES = 64U,
	crypto_core_salsa20_INPUTBYTES = 16U,
	crypto_core_salsa20_KEYBYTES = 32U,
	crypto_core_salsa20_CONSTBYTES = 16U,
};
size_t crypto_core_salsa20_outputbytes(void);
size_t crypto_core_salsa20_inputbytes(void);
size_t crypto_core_salsa20_keybytes(void);
size_t crypto_core_salsa20_constbytes(void);
int crypto_core_salsa20(unsigned char *out, const unsigned char *in,
                        const unsigned char *k, const unsigned char *c);

// sodium/crypto_core_salsa2012.h
enum {
	crypto_core_salsa2012_OUTPUTBYTES = 64U,
	crypto_core_salsa2012_INPUTBYTES = 16U,
	crypto_core_salsa2012_KEYBYTES = 32U,
	crypto_core_salsa2012_CONSTBYTES = 16U,
};
size_t crypto_core_salsa2012_outputbytes(void);
size_t crypto_core_salsa2012_inputbytes(void);
size_t crypto_core_salsa2012_keybytes(void);
size_t crypto_core_salsa2012_constbytes(void);
int crypto_core_salsa2012(unsigned char *out, const unsigned char *in,
                          const unsigned char *k, const unsigned char *c);

// sodium/crypto_core_salsa208.h
enum {
	crypto_core_salsa208_OUTPUTBYTES = 64U,
	crypto_core_salsa208_INPUTBYTES = 16U,
	crypto_core_salsa208_KEYBYTES = 32U,
	crypto_core_salsa208_CONSTBYTES = 16U,
};
size_t crypto_core_salsa208_outputbytes(void);
size_t crypto_core_salsa208_inputbytes(void);
size_t crypto_core_salsa208_keybytes(void);
size_t crypto_core_salsa208_constbytes(void);
int crypto_core_salsa208(unsigned char *out, const unsigned char *in,
                         const unsigned char *k, const unsigned char *c);

// sodium/crypto_generichash_blake2b.h
#pragma pack(push, 1)
typedef __attribute__((aligned(64))) struct crypto_generichash_blake2b_state {
    uint64_t h[8];
    uint64_t t[2];
    uint64_t f[2];
    uint8_t buf[2 * 128];
    size_t buflen;
    uint8_t last_node;
} crypto_generichash_blake2b_state;
#pragma pack(pop)
enum {
	crypto_generichash_blake2b_BYTES_MIN = 16U,
	crypto_generichash_blake2b_BYTES_MAX = 64U,
	crypto_generichash_blake2b_BYTES = 32U,
	crypto_generichash_blake2b_KEYBYTES_MIN = 16U,
	crypto_generichash_blake2b_KEYBYTES_MAX = 64U,
	crypto_generichash_blake2b_KEYBYTES = 32U,
	crypto_generichash_blake2b_SALTBYTES = 16U,
	crypto_generichash_blake2b_PERSONALBYTES = 16U,
};
size_t crypto_generichash_blake2b_bytes_min(void);
size_t crypto_generichash_blake2b_bytes_max(void);
size_t crypto_generichash_blake2b_bytes(void);
size_t crypto_generichash_blake2b_keybytes_min(void);
size_t crypto_generichash_blake2b_keybytes_max(void);
size_t crypto_generichash_blake2b_keybytes(void);
size_t crypto_generichash_blake2b_saltbytes(void);
size_t crypto_generichash_blake2b_personalbytes(void);
int crypto_generichash_blake2b(unsigned char *out, size_t outlen,
                               const unsigned char *in,
                               unsigned long long inlen,
                               const unsigned char *key, size_t keylen);
int crypto_generichash_blake2b_salt_personal(unsigned char *out, size_t outlen,
                                             const unsigned char *in,
                                             unsigned long long inlen,
                                             const unsigned char *key,
                                             size_t keylen,
                                             const unsigned char *salt,
                                             const unsigned char *personal);
int crypto_generichash_blake2b_init(crypto_generichash_blake2b_state *state,
                                    const unsigned char *key,
                                    const size_t keylen, const size_t outlen);
int crypto_generichash_blake2b_init_salt_personal(crypto_generichash_blake2b_state *state,
                                                  const unsigned char *key,
                                                  const size_t keylen, const size_t outlen,
                                                  const unsigned char *salt,
                                                  const unsigned char *personal);
int crypto_generichash_blake2b_update(crypto_generichash_blake2b_state *state,
                                      const unsigned char *in,
                                      unsigned long long inlen);
int crypto_generichash_blake2b_final(crypto_generichash_blake2b_state *state,
                                     unsigned char *out,
                                     const size_t outlen);

// sodium/crypto_generichash.h

size_t crypto_generichash_bytes_min(void);
size_t crypto_generichash_bytes_max(void);
size_t crypto_generichash_bytes(void);
size_t crypto_generichash_keybytes_min(void);
size_t crypto_generichash_keybytes_max(void);
size_t crypto_generichash_keybytes(void);
const char *crypto_generichash_primitive(void);
typedef crypto_generichash_blake2b_state crypto_generichash_state;
size_t crypto_generichash_statebytes(void);
int crypto_generichash(unsigned char *out, size_t outlen,
                       const unsigned char *in, unsigned long long inlen,
                       const unsigned char *key, size_t keylen);
int crypto_generichash_init(crypto_generichash_state *state,
                            const unsigned char *key,
                            const size_t keylen, const size_t outlen);
int crypto_generichash_update(crypto_generichash_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);
int crypto_generichash_final(crypto_generichash_state *state,
                             unsigned char *out, const size_t outlen);

// sodium/crypto_hash.h
size_t crypto_hash_bytes(void);
int crypto_hash(unsigned char *out, const unsigned char *in,
                unsigned long long inlen);
const char *crypto_hash_primitive(void);

// sodium/crypto_onetimeauth_poly1305.h
typedef struct crypto_onetimeauth_poly1305_state {
    unsigned long long aligner;
    unsigned char opaque[136];
} crypto_onetimeauth_poly1305_state;
typedef struct crypto_onetimeauth_poly1305_implementation {
    const char *(*implementation_name)(void);
    int (*onetimeauth)(unsigned char *out,
                               const unsigned char *in,
                               unsigned long long inlen,
                               const unsigned char *k);
    int (*onetimeauth_verify)(const unsigned char *h,
                                      const unsigned char *in,
                                      unsigned long long inlen,
                                      const unsigned char *k);
    int (*onetimeauth_init)(crypto_onetimeauth_poly1305_state *state,
                                    const unsigned char *key);
    int (*onetimeauth_update)(crypto_onetimeauth_poly1305_state *state,
                                      const unsigned char *in,
                                      unsigned long long inlen);
    int (*onetimeauth_final)(crypto_onetimeauth_poly1305_state *state,
                                     unsigned char *out);
} crypto_onetimeauth_poly1305_implementation;
enum {
	crypto_onetimeauth_poly1305_BYTES = 16U,
};
size_t crypto_onetimeauth_poly1305_bytes(void);
size_t crypto_onetimeauth_poly1305_keybytes(void);
const char *crypto_onetimeauth_poly1305_implementation_name(void);
int crypto_onetimeauth_poly1305_set_implementation(crypto_onetimeauth_poly1305_implementation *impl);
crypto_onetimeauth_poly1305_implementation *crypto_onetimeauth_pick_best_implementation(void);
int crypto_onetimeauth_poly1305(unsigned char *out,
                                const unsigned char *in,
                                unsigned long long inlen,
                                const unsigned char *k);
int crypto_onetimeauth_poly1305_verify(const unsigned char *h,
                                       const unsigned char *in,
                                       unsigned long long inlen,
                                       const unsigned char *k);
int crypto_onetimeauth_poly1305_init(crypto_onetimeauth_poly1305_state *state,
                                     const unsigned char *key);
int crypto_onetimeauth_poly1305_update(crypto_onetimeauth_poly1305_state *state,
                                       const unsigned char *in,
                                       unsigned long long inlen);
int crypto_onetimeauth_poly1305_final(crypto_onetimeauth_poly1305_state *state,
                                      unsigned char *out);

// sodium/crypto_onetimeauth.h
typedef crypto_onetimeauth_poly1305_state crypto_onetimeauth_state;
size_t crypto_onetimeauth_statebytes(void);
size_t crypto_onetimeauth_bytes(void);
size_t crypto_onetimeauth_keybytes(void);
const char *crypto_onetimeauth_primitive(void);
int crypto_onetimeauth(unsigned char *out, const unsigned char *in,
                       unsigned long long inlen, const unsigned char *k);
int crypto_onetimeauth_verify(const unsigned char *h, const unsigned char *in,
                              unsigned long long inlen, const unsigned char *k);
int crypto_onetimeauth_init(crypto_onetimeauth_state *state,
                            const unsigned char *key);
int crypto_onetimeauth_update(crypto_onetimeauth_state *state,
                              const unsigned char *in,
                              unsigned long long inlen);
int crypto_onetimeauth_final(crypto_onetimeauth_state *state,
                             unsigned char *out);

// sodium/crypto_pwhash_scryptsalsa208sha256.h
enum {
	crypto_pwhash_scryptsalsa208sha256_SALTBYTES = 32U,
	crypto_pwhash_scryptsalsa208sha256_STRBYTES = 102U,
};
size_t crypto_pwhash_scryptsalsa208sha256_saltbytes(void);
size_t crypto_pwhash_scryptsalsa208sha256_strbytes(void);
const char *crypto_pwhash_scryptsalsa208sha256_strprefix(void);
size_t crypto_pwhash_scryptsalsa208sha256_opslimit_interactive(void);
size_t crypto_pwhash_scryptsalsa208sha256_memlimit_interactive(void);
size_t crypto_pwhash_scryptsalsa208sha256_opslimit_sensitive(void);
size_t crypto_pwhash_scryptsalsa208sha256_memlimit_sensitive(void);
int crypto_pwhash_scryptsalsa208sha256(unsigned char * const out,
                                       unsigned long long outlen,
                                       const char * const passwd,
                                       unsigned long long passwdlen,
                                       const unsigned char * const salt,
                                       unsigned long long opslimit,
                                       size_t memlimit);
int crypto_pwhash_scryptsalsa208sha256_str(char out[102U],
                                           const char * const passwd,
                                           unsigned long long passwdlen,
                                           unsigned long long opslimit,
                                           size_t memlimit);
int crypto_pwhash_scryptsalsa208sha256_str_verify(const char str[102U],
                                                  const char * const passwd,
                                                  unsigned long long passwdlen);
int crypto_pwhash_scryptsalsa208sha256_ll(const uint8_t * passwd, size_t passwdlen,
                                          const uint8_t * salt, size_t saltlen,
                                          uint64_t N, uint32_t r, uint32_t p,
                                          uint8_t * buf, size_t buflen);

// sodium/crypto_scalarmult.h

size_t crypto_scalarmult_bytes(void);
size_t crypto_scalarmult_scalarbytes(void);
const char *crypto_scalarmult_primitive(void);
int crypto_scalarmult_base(unsigned char *q, const unsigned char *n);
int crypto_scalarmult(unsigned char *q, const unsigned char *n,
                      const unsigned char *p);

// sodium/crypto_scalarmult_curve25519.h
enum {
	crypto_scalarmult_curve25519_BYTES = 32U,
	crypto_scalarmult_curve25519_SCALARBYTES = 32U,
};
size_t crypto_scalarmult_curve25519_bytes(void);
size_t crypto_scalarmult_curve25519_scalarbytes(void);
int crypto_scalarmult_curve25519(unsigned char *q, const unsigned char *n,
                                 const unsigned char *p);
int crypto_scalarmult_curve25519_base(unsigned char *q, const unsigned char *n);

// sodium/crypto_secretbox.h
size_t crypto_secretbox_keybytes(void);
size_t crypto_secretbox_noncebytes(void);
size_t crypto_secretbox_macbytes(void);
const char *crypto_secretbox_primitive(void);
int crypto_secretbox_easy(unsigned char *c, const unsigned char *m,
                          unsigned long long mlen, const unsigned char *n,
                          const unsigned char *k);
int crypto_secretbox_open_easy(unsigned char *m, const unsigned char *c,
                               unsigned long long clen, const unsigned char *n,
                               const unsigned char *k);
int crypto_secretbox_detached(unsigned char *c, unsigned char *mac,
                              const unsigned char *m,
                              unsigned long long mlen,
                              const unsigned char *n,
                              const unsigned char *k);
int crypto_secretbox_open_detached(unsigned char *m,
                                   const unsigned char *c,
                                   const unsigned char *mac,
                                   unsigned long long clen,
                                   const unsigned char *n,
                                   const unsigned char *k);

size_t crypto_secretbox_zerobytes(void);
size_t crypto_secretbox_boxzerobytes(void);
int crypto_secretbox(unsigned char *c, const unsigned char *m,
                     unsigned long long mlen, const unsigned char *n,
                     const unsigned char *k);
int crypto_secretbox_open(unsigned char *m, const unsigned char *c,
                          unsigned long long clen, const unsigned char *n,
                          const unsigned char *k);

// sodium/crypto_secretbox_xsalsa20poly1305.h
size_t crypto_secretbox_xsalsa20poly1305_keybytes(void);
size_t crypto_secretbox_xsalsa20poly1305_noncebytes(void);
size_t crypto_secretbox_xsalsa20poly1305_zerobytes(void);
size_t crypto_secretbox_xsalsa20poly1305_boxzerobytes(void);
size_t crypto_secretbox_xsalsa20poly1305_macbytes(void);
int crypto_secretbox_xsalsa20poly1305(unsigned char *c,
                                      const unsigned char *m,
                                      unsigned long long mlen,
                                      const unsigned char *n,
                                      const unsigned char *k);
int crypto_secretbox_xsalsa20poly1305_open(unsigned char *m,
                                           const unsigned char *c,
                                           unsigned long long clen,
                                           const unsigned char *n,
                                           const unsigned char *k);

// sodium/crypto_shorthash.h
size_t crypto_shorthash_bytes(void);
size_t crypto_shorthash_keybytes(void);
const char *crypto_shorthash_primitive(void);
int crypto_shorthash(unsigned char *out, const unsigned char *in,
                     unsigned long long inlen, const unsigned char *k);

// sodium/crypto_shorthash_siphash24.h
enum {
	crypto_shorthash_siphash24_BYTES = 8U,
	crypto_shorthash_siphash24_KEYBYTES = 16U,
};
size_t crypto_shorthash_siphash24_bytes(void);
size_t crypto_shorthash_siphash24_keybytes(void);
int crypto_shorthash_siphash24(unsigned char *out, const unsigned char *in,
                               unsigned long long inlen, const unsigned char *k);

// sodium/crypto_sign.h
size_t crypto_sign_bytes(void);
size_t crypto_sign_seedbytes(void);
size_t crypto_sign_publickeybytes(void);
size_t crypto_sign_secretkeybytes(void);
const char *crypto_sign_primitive(void);
int crypto_sign_seed_keypair(unsigned char *pk, unsigned char *sk,
                             const unsigned char *seed);
int crypto_sign_keypair(unsigned char *pk, unsigned char *sk);
int crypto_sign(unsigned char *sm, unsigned long long *smlen_p,
                const unsigned char *m, unsigned long long mlen,
                const unsigned char *sk);
int crypto_sign_open(unsigned char *m, unsigned long long *mlen_p,
                     const unsigned char *sm, unsigned long long smlen,
                     const unsigned char *pk);
int crypto_sign_detached(unsigned char *sig, unsigned long long *siglen_p,
                         const unsigned char *m, unsigned long long mlen,
                         const unsigned char *sk);
int crypto_sign_verify_detached(const unsigned char *sig,
                                const unsigned char *m,
                                unsigned long long mlen,
                                const unsigned char *pk);

// sodium/crypto_sign_ed25519.h
enum {
	crypto_sign_ed25519_BYTES = 64U,
	crypto_sign_ed25519_SEEDBYTES = 32U,
	crypto_sign_ed25519_PUBLICKEYBYTES = 32U,
	crypto_sign_ed25519_SECRETKEYBYTES = (32U + 32U),
};
size_t crypto_sign_ed25519_bytes(void);
size_t crypto_sign_ed25519_seedbytes(void);
size_t crypto_sign_ed25519_publickeybytes(void);
size_t crypto_sign_ed25519_secretkeybytes(void);
int crypto_sign_ed25519(unsigned char *sm, unsigned long long *smlen_p,
                        const unsigned char *m, unsigned long long mlen,
                        const unsigned char *sk);
int crypto_sign_ed25519_open(unsigned char *m, unsigned long long *mlen_p,
                             const unsigned char *sm, unsigned long long smlen,
                             const unsigned char *pk);
int crypto_sign_ed25519_detached(unsigned char *sig,
                                 unsigned long long *siglen_p,
                                 const unsigned char *m,
                                 unsigned long long mlen,
                                 const unsigned char *sk);
int crypto_sign_ed25519_verify_detached(const unsigned char *sig,
                                        const unsigned char *m,
                                        unsigned long long mlen,
                                        const unsigned char *pk);
int crypto_sign_ed25519_keypair(unsigned char *pk, unsigned char *sk);
int crypto_sign_ed25519_seed_keypair(unsigned char *pk, unsigned char *sk,
                                     const unsigned char *seed);
int crypto_sign_ed25519_pk_to_curve25519(unsigned char *curve25519_pk,
                                         const unsigned char *ed25519_pk);
int crypto_sign_ed25519_sk_to_curve25519(unsigned char *curve25519_sk,
                                         const unsigned char *ed25519_sk);
int crypto_sign_ed25519_sk_to_seed(unsigned char *seed,
                                   const unsigned char *sk);
int crypto_sign_ed25519_sk_to_pk(unsigned char *pk, const unsigned char *sk);

// sodium/crypto_stream.h
size_t crypto_stream_keybytes(void);
size_t crypto_stream_noncebytes(void);
const char *crypto_stream_primitive(void);
int crypto_stream(unsigned char *c, unsigned long long clen,
                  const unsigned char *n, const unsigned char *k);
int crypto_stream_xor(unsigned char *c, const unsigned char *m,
                      unsigned long long mlen, const unsigned char *n,
                      const unsigned char *k);

// sodium/crypto_stream_xsalsa20.h
enum {
	crypto_stream_xsalsa20_KEYBYTES = 32U,
	crypto_stream_xsalsa20_NONCEBYTES = 24U,
};
size_t crypto_stream_xsalsa20_keybytes(void);
size_t crypto_stream_xsalsa20_noncebytes(void);
int crypto_stream_xsalsa20(unsigned char *c, unsigned long long clen,
                           const unsigned char *n, const unsigned char *k);
int crypto_stream_xsalsa20_xor(unsigned char *c, const unsigned char *m,
                               unsigned long long mlen, const unsigned char *n,
                               const unsigned char *k);
int crypto_stream_xsalsa20_xor_ic(unsigned char *c, const unsigned char *m,
                                  unsigned long long mlen,
                                  const unsigned char *n, uint64_t ic,
                                  const unsigned char *k);

// sodium/crypto_stream_aes128ctr.h
enum {
	crypto_stream_aes128ctr_KEYBYTES = 16U,
	crypto_stream_aes128ctr_NONCEBYTES = 16U,
	crypto_stream_aes128ctr_BEFORENMBYTES = 1408U,
};
size_t crypto_stream_aes128ctr_keybytes(void);
size_t crypto_stream_aes128ctr_noncebytes(void);
size_t crypto_stream_aes128ctr_beforenmbytes(void);
int crypto_stream_aes128ctr(unsigned char *out, unsigned long long outlen,
                            const unsigned char *n, const unsigned char *k);
int crypto_stream_aes128ctr_xor(unsigned char *out, const unsigned char *in,
                                unsigned long long inlen, const unsigned char *n,
                                const unsigned char *k);
int crypto_stream_aes128ctr_beforenm(unsigned char *c, const unsigned char *k);
int crypto_stream_aes128ctr_afternm(unsigned char *out, unsigned long long len,
                                    const unsigned char *nonce, const unsigned char *c);
int crypto_stream_aes128ctr_xor_afternm(unsigned char *out, const unsigned char *in,
                                        unsigned long long len,
                                        const unsigned char *nonce,
                                        const unsigned char *c);

// sodium/crypto_stream_chacha20.h
enum {
	crypto_stream_chacha20_KEYBYTES = 32U,
	crypto_stream_chacha20_NONCEBYTES = 8U,
	crypto_stream_chacha20_IETF_NONCEBYTES = 12U,
};
size_t crypto_stream_chacha20_keybytes(void);
size_t crypto_stream_chacha20_noncebytes(void);
int crypto_stream_chacha20(unsigned char *c, unsigned long long clen,
                           const unsigned char *n, const unsigned char *k);
int crypto_stream_chacha20_xor(unsigned char *c, const unsigned char *m,
                               unsigned long long mlen, const unsigned char *n,
                               const unsigned char *k);
int crypto_stream_chacha20_xor_ic(unsigned char *c, const unsigned char *m,
                                  unsigned long long mlen,
                                  const unsigned char *n, uint64_t ic,
                                  const unsigned char *k);
size_t crypto_stream_chacha20_ietf_noncebytes(void);
int crypto_stream_chacha20_ietf(unsigned char *c, unsigned long long clen,
                                const unsigned char *n, const unsigned char *k);
int crypto_stream_chacha20_ietf_xor(unsigned char *c, const unsigned char *m,
                                    unsigned long long mlen, const unsigned char *n,
                                    const unsigned char *k);
int crypto_stream_chacha20_ietf_xor_ic(unsigned char *c, const unsigned char *m,
                                       unsigned long long mlen,
                                       const unsigned char *n, uint32_t ic,
                                       const unsigned char *k);

// sodium/crypto_stream_salsa20.h
enum {
	crypto_stream_salsa20_KEYBYTES = 32U,
	crypto_stream_salsa20_NONCEBYTES = 8U,
	crypto_stream_salsa2012_KEYBYTES = 32U,
	crypto_stream_salsa2012_NONCEBYTES = 8U,
};
size_t crypto_stream_salsa20_keybytes(void);
size_t crypto_stream_salsa20_noncebytes(void);
int crypto_stream_salsa20(unsigned char *c, unsigned long long clen,
                          const unsigned char *n, const unsigned char *k);
int crypto_stream_salsa20_xor(unsigned char *c, const unsigned char *m,
                              unsigned long long mlen, const unsigned char *n,
                              const unsigned char *k);
int crypto_stream_salsa20_xor_ic(unsigned char *c, const unsigned char *m,
                                 unsigned long long mlen,
                                 const unsigned char *n, uint64_t ic,
                                 const unsigned char *k);

// sodium/crypto_stream_salsa2012.h
size_t crypto_stream_salsa2012_keybytes(void);
size_t crypto_stream_salsa2012_noncebytes(void);
int crypto_stream_salsa2012(unsigned char *c, unsigned long long clen,
                            const unsigned char *n, const unsigned char *k);
int crypto_stream_salsa2012_xor(unsigned char *c, const unsigned char *m,
                                unsigned long long mlen, const unsigned char *n,
                                const unsigned char *k);

// sodium/crypto_stream_salsa208.h
enum {
	crypto_stream_salsa208_KEYBYTES = 32U,
	crypto_stream_salsa208_NONCEBYTES = 8U,
};
size_t crypto_stream_salsa208_keybytes(void);
size_t crypto_stream_salsa208_noncebytes(void);
int crypto_stream_salsa208(unsigned char *c, unsigned long long clen,
                           const unsigned char *n, const unsigned char *k);
int crypto_stream_salsa208_xor(unsigned char *c, const unsigned char *m,
                               unsigned long long mlen, const unsigned char *n,
                               const unsigned char *k);

// sodium/crypto_verify_16.h
enum {
	crypto_verify_16_BYTES = 16U,
};
size_t crypto_verify_16_bytes(void);
int crypto_verify_16(const unsigned char *x, const unsigned char *y);

// sodium/crypto_verify_32.h
enum {
	crypto_verify_32_BYTES = 32U,
};
size_t crypto_verify_32_bytes(void);
int crypto_verify_32(const unsigned char *x, const unsigned char *y);

// sodium/crypto_verify_64.h
enum {
	crypto_verify_64_BYTES = 64U,
};
size_t crypto_verify_64_bytes(void);
int crypto_verify_64(const unsigned char *x, const unsigned char *y);

// sodium/randombytes.h
typedef struct randombytes_implementation {
	const char *(*implementation_name)(void);
	uint32_t (*random)(void);
	void (*stir)(void);
	uint32_t (*uniform)(const uint32_t upper_bound);
	void (*buf)(void * const buf, const size_t size);
	int (*close)(void);
} randombytes_implementation;

void randombytes_buf(void * const buf, const size_t size);
uint32_t randombytes_random(void);
uint32_t randombytes_uniform(const uint32_t upper_bound);
void randombytes_stir(void);
int randombytes_close(void);
int randombytes_set_implementation(randombytes_implementation *impl);
const char *randombytes_implementation_name(void);
void randombytes(unsigned char * const buf, const unsigned long long buf_len);

// sodium/randombytes_salsa20_random.h
struct randombytes_implementation randombytes_salsa20_implementation;
const char *randombytes_salsa20_implementation_name(void);
uint32_t randombytes_salsa20_random(void);
void randombytes_salsa20_random_stir(void);
uint32_t randombytes_salsa20_random_uniform(const uint32_t upper_bound);
void randombytes_salsa20_random_buf(void * const buf, const size_t size);
int randombytes_salsa20_random_close(void);

// sodium/randombytes_sysrandom.h
struct randombytes_implementation randombytes_sysrandom_implementation;
const char *randombytes_sysrandom_implementation_name(void);
uint32_t randombytes_sysrandom(void);
void randombytes_sysrandom_stir(void);
uint32_t randombytes_sysrandom_uniform(const uint32_t upper_bound);
void randombytes_sysrandom_buf(void * const buf, const size_t size);
int randombytes_sysrandom_close(void);

// sodium/runtime.h
int sodium_runtime_get_cpu_features(void);
int sodium_runtime_has_neon(void);
int sodium_runtime_has_sse2(void);
int sodium_runtime_has_sse3(void);

// sodium/utils.h
void sodium_memzero(void * const pnt, const size_t len);
int sodium_memcmp(const void * const b1_, const void * const b2_, size_t len);
char *sodium_bin2hex(char * const hex, const size_t hex_maxlen,
                     const unsigned char * const bin, const size_t bin_len);
int sodium_hex2bin(unsigned char * const bin, const size_t bin_maxlen,
                   const char * const hex, const size_t hex_len,
                   const char * const ignore, size_t * const bin_len,
                   const char ** const hex_end);
int sodium_mlock(void * const addr, const size_t len);
int sodium_munlock(void * const addr, const size_t len);
void *sodium_malloc(const size_t size);
void *sodium_allocarray(size_t count, size_t size);
void sodium_free(void *ptr);
int sodium_mprotect_noaccess(void *ptr);
int sodium_mprotect_readonly(void *ptr);
int sodium_mprotect_readwrite(void *ptr);
void sodium_increment(unsigned char *n, const size_t nlen);
int _sodium_alloc_init(void);

// sodium/version.h
const char *sodium_version_string(void);
int sodium_library_version_major(void);
int sodium_library_version_minor(void);
]]

--[[
crypto_auth_PRIMITIVE = "hmacsha512256",
crypto_auth_BYTES    = crypto_auth_hmacsha512256_BYTES
crypto_auth_KEYBYTES = crypto_auth_hmacsha512256_KEYBYTES,
crypto_box_SEEDBYTES = crypto_box_curve25519xsalsa20poly1305_SEEDBYTES,
crypto_box_PUBLICKEYBYTES = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES,
crypto_box_PRIMITIVE = "curve25519xsalsa20poly1305",
crypto_box_SECRETKEYBYTES = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES,
crypto_box_SEALBYTES = (crypto_box_PUBLICKEYBYTES + crypto_box_MACBYTES),
crypto_box_BEFORENMBYTES = crypto_box_curve25519xsalsa20poly1305_BEFORENMBYTES,
crypto_box_MACBYTES  = crypto_box_curve25519xsalsa20poly1305_MACBYTES,
crypto_box_NONCEBYTES = crypto_box_curve25519xsalsa20poly1305_NONCEBYTES,
crypto_box_BOXZEROBYTES = crypto_box_curve25519xsalsa20poly1305_BOXZEROBYTES,
crypto_box_ZEROBYTES = crypto_box_curve25519xsalsa20poly1305_ZEROBYTES,
crypto_generichash_PRIMITIVE = "blake2b",
crypto_generichash_KEYBYTES = crypto_generichash_blake2b_KEYBYTES,
crypto_generichash_KEYBYTES_MAX = crypto_generichash_blake2b_KEYBYTES_MAX,
crypto_generichash_KEYBYTES_MIN = crypto_generichash_blake2b_KEYBYTES_MIN,
crypto_generichash_BYTES = crypto_generichash_blake2b_BYTES,
crypto_generichash_BYTES_MAX = crypto_generichash_blake2b_BYTES_MAX,
crypto_generichash_BYTES_MIN = crypto_generichash_blake2b_BYTES_MIN,
crypto_onetimeauth_poly1305_KEYBYTES = 32U,
crypto_onetimeauth_PRIMITIVE = "poly1305",
crypto_onetimeauth_KEYBYTES = crypto_onetimeauth_poly1305_KEYBYTES,
crypto_onetimeauth_BYTES = crypto_onetimeauth_poly1305_BYTES,
crypto_hash_PRIMITIVE = "sha512",
crypto_hash_BYTES    = crypto_hash_sha512_BYTES,
crypto_pwhash_scryptsalsa208sha256_STRPREFIX = "$7$",
crypto_scalarmult_PRIMITIVE = "curve25519",
crypto_scalarmult_SCALARBYTES = crypto_scalarmult_curve25519_SCALARBYTES,
crypto_scalarmult_BYTES = crypto_scalarmult_curve25519_BYTES,
crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE = 1073741824ULL,
crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE = 33554432ULL,
crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE = 16777216ULL,
crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE = 524288ULL,
crypto_stream_PRIMITIVE = "xsalsa20",
crypto_stream_NONCEBYTES = crypto_stream_xsalsa20_NONCEBYTES,
crypto_stream_KEYBYTES = crypto_stream_xsalsa20_KEYBYTES,
crypto_sign_PRIMITIVE = "ed25519",
crypto_sign_SECRETKEYBYTES = crypto_sign_ed25519_SECRETKEYBYTES,
crypto_sign_PUBLICKEYBYTES = crypto_sign_ed25519_PUBLICKEYBYTES,
crypto_sign_SEEDBYTES = crypto_sign_ed25519_SEEDBYTES,
crypto_sign_BYTES    = crypto_sign_ed25519_BYTES,
crypto_shorthash_PRIMITIVE = "siphash24",
crypto_shorthash_KEYBYTES = crypto_shorthash_siphash24_KEYBYTES,
crypto_shorthash_BYTES = crypto_shorthash_siphash24_BYTES,
crypto_secretbox_xsalsa20poly1305_MACBYTES = (crypto_secretbox_xsalsa20poly1305_ZEROBYTES - crypto_secretbox_xsalsa20poly1305_BOXZEROBYTES),
crypto_secretbox_xsalsa20poly1305_BOXZEROBYTES = 16U,
crypto_secretbox_xsalsa20poly1305_ZEROBYTES = 32U,
crypto_secretbox_xsalsa20poly1305_NONCEBYTES = 24U,
crypto_secretbox_xsalsa20poly1305_KEYBYTES = 32U,
crypto_secretbox_BOXZEROBYTES = crypto_secretbox_xsalsa20poly1305_BOXZEROBYTES,
crypto_secretbox_ZEROBYTES = crypto_secretbox_xsalsa20poly1305_ZEROBYTES,
crypto_secretbox_PRIMITIVE = "xsalsa20poly1305",
crypto_secretbox_MACBYTES = crypto_secretbox_xsalsa20poly1305_MACBYTES,
crypto_secretbox_NONCEBYTES = crypto_secretbox_xsalsa20poly1305_NONCEBYTES,
crypto_secretbox_KEYBYTES = crypto_secretbox_xsalsa20poly1305_KEYBYTES,
]]
