/* $OpenBSD: tls_internal.h,v 1.77 2019/11/16 21:39:52 beck Exp $ */
/*
 * Copyright (c) 2014 Jeremie Courreges-Anglas <jca@openbsd.org>
 * Copyright (c) 2014 Joel Sing <jsing@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef HEADER_TLS_INTERNAL_H
#define HEADER_TLS_INTERNAL_H

#include <pthread.h>

#ifdef WIN32
# include <Winsock2.h>
# include <in6addr.h>
#else
# include <netinet/in.h>
# include <arpa/inet.h>
#endif

#include <bearssl.h>

#include "compat.h"

#ifndef TLS_DEFAULT_CA_FILE
#define TLS_DEFAULT_CA_FILE 	"/etc/ssl/cert.pem"
#endif

#define TLS_CIPHERS_DEFAULT	"TLSv1.3:TLSv1.2+AEAD+ECDHE:TLSv1.2+AEAD+DHE"
#define TLS_CIPHERS_COMPAT	"HIGH:!aNULL"
#define TLS_CIPHERS_LEGACY	"HIGH:MEDIUM:!aNULL"
#define TLS_CIPHERS_ALL		"ALL:!aNULL:!eNULL"

#define TLS_ECDHE_CURVES	"X25519,P-256,P-384"

#define TLS_CONTAINER_OF(p, t, m) ((t *)((char *)(p) - offsetof(t, m)))

union tls_addr {
	struct in_addr ip4;
	struct in6_addr ip6;
};

struct tls_error {
	char *msg;
	int num;
	int tls;
};

struct tls_keypair {
	struct tls_keypair *next;

	br_x509_certificate *chain;
	size_t chain_len;
	int signer_key_type;

	int key_type;
	unsigned char *key_data;
	size_t key_data_len;
	union {
		br_rsa_private_key rsa;
		br_ec_private_key ec;
	} key;
};

struct tls_config {
	struct tls_error error;

	pthread_mutex_t mutex;
	int refcount;

	const char **alpn;
	size_t alpn_len;
	br_x509_trust_anchor *ca;
	size_t ca_len;
	const uint16_t *suites;
	size_t suites_len;
	int ciphers_server;
	int dheparams;
	br_ec_impl ec;
	struct tls_keypair *keypair;
	int ocsp_require_stapling;
	uint32_t protocols;
	int verify_cert;
	int verify_client;
	int verify_depth;
	int verify_name;
	int verify_time;
};

struct tls_conninfo {
	char *alpn;
	char *cipher;
	int cipher_strength;
	char *servername;
	char *version;

	char *hash;
	char *issuer;
	char *subject;

	uint8_t *peer_cert;
	size_t peer_cert_len;

	time_t notbefore;
	time_t notafter;
};

#define TLS_CLIENT		(1 << 0)
#define TLS_SERVER		(1 << 1)
#define TLS_SERVER_CONN		(1 << 2)

#define TLS_EOF_NO_CLOSE_NOTIFY	(1 << 0)
#define TLS_CONNECTED		(1 << 1)
#define TLS_HANDSHAKE_COMPLETE	(1 << 2)
#define TLS_SSL_NEEDS_SHUTDOWN	(1 << 3)
#define TLS_SSL_IN_SHUTDOWN	(1 << 4)

enum {
	TLS_DN_C,
	TLS_DN_ST,
	TLS_DN_L,
	TLS_DN_O,
	TLS_DN_OU,
	TLS_DN_CN,

	TLS_DN_NUM_ELTS
};

struct tls_x509 {
	struct tls *ctx;
	const br_x509_class *vtable;
	br_x509_minimal_context minimal;
	int depth;

	struct {
		char C[3];
		char ST[129];
		char L[129];
		char O[65];
		char OU[65];
		char CN[65];
	} subject;
	br_name_element subject_elts[TLS_DN_NUM_ELTS];
};

struct tls_conn {
	struct tls *ctx;
	union {
		br_ssl_client_context client;
		br_ssl_server_context server;
		br_ssl_engine_context engine;
	} u;
	const br_ssl_server_policy_class *policy;
	struct tls_x509 *x509;
	char buf[BR_SSL_BUFSIZE_BIDI];
	size_t write_len;
};

struct tls {
	struct tls_config *config;
	struct tls_keypair *keypair;

	struct tls_error error;

	uint32_t flags;
	uint32_t state;

	char *servername;
	int socket;

	struct tls_conn *conn;

	br_x509_certificate *peer_chain;
	size_t peer_chain_len;

	struct tls_conninfo *conninfo;

	tls_read_cb read_cb;
	tls_write_cb write_cb;
	void *cb_arg;
	int fd_read;
	int fd_write;
};

/* BearSSL utility functions */
int bearssl_init(void);
const char *bearssl_strerror(int err);
void bearssl_random(void *buf, size_t len);
int bearssl_parse_ciphers(const char *ciphers, uint16_t **suites,
    size_t *suites_len);
int bearssl_load_ca(struct tls_error *error, const uint8_t *mem, size_t len,
    br_x509_trust_anchor **ca, size_t *ca_len);
const char *bearssl_suite_name(uint16_t suite_id);
int bearssl_suite_bits(uint16_t suite_id);

struct tls_keypair *tls_keypair_new(void);
void tls_keypair_clear_key(struct tls_keypair *_keypair);
void tls_keypair_free(struct tls_keypair *_keypair);
int tls_keypair_set_cert_file(struct tls_keypair *_keypair,
    struct tls_error *_error, const char *_cert_file);
int tls_keypair_set_cert_mem(struct tls_keypair *_keypair,
    struct tls_error *_error, const uint8_t *_cert, size_t _len);
int tls_keypair_set_key_file(struct tls_keypair *_keypair,
    struct tls_error *_error, const char *_key_file);
int tls_keypair_set_key_mem(struct tls_keypair *_keypair,
    struct tls_error *_error, const uint8_t *_key, size_t _len);
int tls_keypair_set_ocsp_staple_file(struct tls_keypair *_keypair,
    struct tls_error *_error, const char *_ocsp_file);
int tls_keypair_set_ocsp_staple_mem(struct tls_keypair *_keypair,
    struct tls_error *_error, const uint8_t *_staple, size_t _len);
int tls_keypair_check(struct tls_keypair *_keypair,
    struct tls_error *_error);

struct tls_config *tls_config_new_internal(void);

struct tls *tls_new(void);
struct tls *tls_server_conn(struct tls *ctx);

int tls_check_name(struct tls *ctx, br_x509_certificate *cert,
    const char *servername, int *match);
int tls_configure_x509(struct tls *ctx);

struct tls_conn *tls_conn_new(struct tls *ctx);

int tls_config_load_file(struct tls_error *error, const char *filetype,
    const char *filename, char **buf, size_t *len);
int tls_host_port(const char *hostport, char **host, char **port);

ssize_t tls_fd_read_cb(struct tls *ctx, void *buf, size_t buflen, void *cb_arg);
ssize_t tls_fd_write_cb(struct tls *ctx, const void *buf, size_t buflen,
    void *cb_arg);
int tls_set_cbs(struct tls *ctx,
    tls_read_cb read_cb, tls_write_cb write_cb, void *cb_arg);

void tls_error_clear(struct tls_error *error);
int tls_error_set(struct tls_error *error, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));
int tls_error_setx(struct tls_error *error, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));
int tls_config_set_error(struct tls_config *cfg, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));
int tls_config_set_errorx(struct tls_config *cfg, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));
int tls_set_error(struct tls *ctx, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));
int tls_set_errorx(struct tls *ctx, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));
int tls_set_ssl_errorx(struct tls *ctx, const char *fmt, ...)
    __attribute__((__format__ (printf, 2, 3)))
    __attribute__((__nonnull__ (2)));

int tls_ssl_error(struct tls *ctx, br_ssl_engine_context *eng, ssize_t ret,
    const char *prefix);

int tls_conninfo_populate(struct tls *ctx);
void tls_conninfo_free(struct tls_conninfo *conninfo);

int tls_hex_string(const unsigned char *_in, size_t _inlen, char **_out,
    size_t *_outlen);
int tls_cert_hash(br_x509_certificate *cert, char **hash);

#endif /* HEADER_TLS_INTERNAL_H */
