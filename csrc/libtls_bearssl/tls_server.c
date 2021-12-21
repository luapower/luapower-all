/* $OpenBSD: tls_server.c,v 1.45 2019/05/13 22:36:01 bcook Exp $ */
/*
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

#ifdef WIN32
# include <Winsock2.h>
# include <ws2tcpip.h>
#else
# include <sys/socket.h>
# include <arpa/inet.h>
#endif

#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <tls.h>
#include "tls_internal.h"

struct tls *
tls_server(void)
{
	struct tls *ctx;

	if (tls_init() == -1)
		return (NULL);

	if ((ctx = tls_new()) == NULL)
		return (NULL);

	ctx->flags |= TLS_SERVER;

	return (ctx);
}

struct tls *
tls_server_conn(struct tls *ctx)
{
	struct tls *conn_ctx;

	if ((conn_ctx = tls_new()) == NULL)
		return (NULL);

	conn_ctx->flags |= TLS_SERVER_CONN;

	pthread_mutex_lock(&ctx->config->mutex);
	ctx->config->refcount++;
	pthread_mutex_unlock(&ctx->config->mutex);

	conn_ctx->config = ctx->config;
	conn_ctx->keypair = ctx->config->keypair;

	return (conn_ctx);
}

static int
choose_algo(br_ssl_server_choices *choices, uint16_t hashes, unsigned version,
    unsigned hash)
{
	int rv = -1;

	if (version >= BR_TLS12) {
		for (hash = 6; hash >= 2; --hash) {
			if ((hashes & 1 << hash) != 0) {
				rv = 0;
				break;
			}
		}
	} else if ((hashes & 1 << hash) != 0) {
		rv = 0;
	}
	choices->algo_id = 0xFF00 | hash;
	return rv;
}

static int
policy_choose(const br_ssl_server_policy_class **vtable,
    const br_ssl_server_context *ssl_ctx, br_ssl_server_choices *choices)
{
	struct tls *ctx = TLS_CONTAINER_OF(vtable, struct tls_conn, policy)->ctx;
	struct tls_keypair *kp;
	union tls_addr addrbuf;
	const char *name;
	const br_suite_translated *suites;
	size_t suites_len, i;
	uint32_t hashes;
	unsigned version;
	int match;

	name = br_ssl_engine_get_server_name(&ssl_ctx->eng);
	version = br_ssl_engine_get_version(&ssl_ctx->eng);
	hashes = br_ssl_server_get_client_hashes(ssl_ctx);
	suites = br_ssl_server_get_client_suites(ssl_ctx, &suites_len);

	/*
	 * Per RFC 6066 section 3: ensure that name is not an IP literal.
	 *
	 * While we should treat this as an error, a number of clients
	 * (Python, Ruby and Safari) are not RFC compliant. To avoid handshake
	 * failures, pretend that we did not receive the extension.
	 */
	if (inet_pton(AF_INET, name, &addrbuf) == 1 ||
	    inet_pton(AF_INET6, name, &addrbuf) == 1) {
		name = NULL;
	}

	for (kp = ctx->config->keypair; kp != NULL; kp = kp->next) {
		if (kp->chain_len == 0)
			continue;
		if (tls_check_name(ctx, &kp->chain[0], name, &match) == -1)
			return 0;
		if (match)
			break;
	}

	if (kp == NULL)
		kp = ctx->config->keypair;

	ctx->keypair = kp;
	choices->chain = kp->chain;
	choices->chain_len = kp->chain_len;

	for (i = 0; i < suites_len; ++i) {
		choices->cipher_suite = suites[i][0];
		switch (suites[i][1] >> 12) {
		case BR_SSLKEYX_RSA:
			if (kp->key_type != BR_KEYTYPE_RSA)
				continue;
			return 1;
		case BR_SSLKEYX_ECDHE_RSA:
			if (kp->key_type != BR_KEYTYPE_RSA)
				continue;
			if (choose_algo(choices, hashes, version, br_md5sha1_ID) != 0)
				continue;
			return 1;
		case BR_SSLKEYX_ECDHE_ECDSA:
			if (kp->key_type != BR_KEYTYPE_EC)
				continue;
			if (choose_algo(choices, hashes >> 8, version, br_sha1_ID) != 0)
				continue;
			return 1;
		case BR_SSLKEYX_ECDH_RSA:
			if (kp->key_type != BR_KEYTYPE_EC ||
			    kp->signer_key_type != BR_KEYTYPE_RSA)
				continue;
			return 1;
		case BR_SSLKEYX_ECDH_ECDSA:
			if (kp->key_type == BR_KEYTYPE_EC &&
			    kp->signer_key_type == BR_KEYTYPE_EC)
				continue;
			return 1;
		}
	}

	return 0;
}

static uint32_t
policy_do_keyx(const br_ssl_server_policy_class **vtable, unsigned char *data, size_t *len)
{
	struct tls *ctx = TLS_CONTAINER_OF(vtable, struct tls_conn, policy)->ctx;
	struct tls_keypair *kp = ctx->keypair;
	const br_ec_impl *ec;
	br_rsa_private rsa;
	size_t xoff, xlen;
	uint32_t rv = 0;

	switch (kp->key_type) {
	case BR_KEYTYPE_RSA:
		rsa = br_rsa_private_get_default();
		rv = br_rsa_ssl_decrypt(rsa, &kp->key.rsa, data, *len);
		break;
	case BR_KEYTYPE_EC:
		ec = br_ec_get_default();
		rv = ec->mul(data, *len, kp->key.ec.x, kp->key.ec.xlen,
		    kp->key.ec.curve);
		xoff = ec->xoff(kp->key.ec.curve, &xlen);
		memmove(data, data + xoff, xlen);
		*len = xlen;
		break;
	}

	return (rv);
}

static size_t
policy_do_sign(const br_ssl_server_policy_class **vtable, unsigned algo_id,
    unsigned char *data, size_t hv_len, size_t len)
{
	struct tls *ctx = TLS_CONTAINER_OF(vtable, struct tls_conn, policy)->ctx;
	struct tls_keypair *kp = ctx->keypair;
	unsigned char hv[64];
	size_t sig_len;
	const unsigned char *hash_oid;
	const br_hash_class *hash_impl;
	const br_ec_impl *ec;
	br_ecdsa_sign ecdsa_sign;
	br_rsa_pkcs1_sign rsa_sign;
	size_t rv = 0;

	if (hv_len > sizeof(hv)) {
		tls_set_errorx(ctx, "buffer too small for hash value");
		goto err;
	}

	memcpy(hv, data, hv_len);

	switch (kp->key_type) {
	case BR_KEYTYPE_RSA:
		switch (algo_id & 0xFF) {
		case br_sha1_ID:
			hash_oid = BR_HASH_OID_SHA1;
			break;
		case br_sha224_ID:
			hash_oid = BR_HASH_OID_SHA224;
			break;
		case br_sha256_ID:
			hash_oid = BR_HASH_OID_SHA256;
			break;
		case br_sha384_ID:
			hash_oid = BR_HASH_OID_SHA384;
			break;
		case br_sha512_ID:
			hash_oid = BR_HASH_OID_SHA512;
			break;
		default:
			tls_set_errorx(ctx, "unknown hash function for RSA signature");
			goto err;
		}

		sig_len = (kp->key.rsa.n_bitlen + 7) >> 3;
		if (len < sig_len) {
			tls_set_errorx(ctx, "buffer is too small for RSA signature");
			goto err;
		}

		rsa_sign = br_rsa_pkcs1_sign_get_default();
		if (rsa_sign(hash_oid, hv, hv_len, &kp->key.rsa, data) != 1) {
			tls_set_errorx(ctx, "RSA sign failed");
			goto err;
		}

		rv = sig_len;
		break;
	case BR_KEYTYPE_EC:
		switch (algo_id & 0xFF) {
		case br_md5sha1_ID:
			hash_impl = &br_md5sha1_vtable;
			break;
		case br_sha1_ID:
			hash_impl = &br_sha1_vtable;
			break;
		case br_sha224_ID:
			hash_impl = &br_sha224_vtable;
			break;
		case br_sha256_ID:
			hash_impl = &br_sha256_vtable;
			break;
		case br_sha384_ID:
			hash_impl = &br_sha384_vtable;
			break;
		case br_sha512_ID:
			hash_impl = &br_sha512_vtable;
			break;
		default:
			tls_set_errorx(ctx, "unknown hash function for ECDSA signature");
			goto err;
		}

		/* maximum size of supported ECDSA signature (P-512) */
		if (len < 139) {
			tls_set_errorx(ctx, "buffer is too small for RSA signature");
			goto err;
		}

		ec = br_ec_get_default();
		ecdsa_sign = br_ecdsa_sign_asn1_get_default();
		if ((rv = ecdsa_sign(ec, hash_impl, hv, &kp->key.ec, data)) == 0) {
			tls_set_errorx(ctx, "ECDSA sign failed");
			goto err;
		}
		break;
	default:
		tls_set_errorx(ctx, "unknown private key type");
		break;
	}

 err:
	return rv;
}

static const br_ssl_server_policy_class policy_vtable = {
	.choose = policy_choose,
	.do_keyx = policy_do_keyx,
	.do_sign = policy_do_sign,
};

static struct tls *
tls_accept_common(struct tls *ctx)
{
	struct tls *conn_ctx = NULL;
	struct tls_conn *conn;
	uint32_t flags;

	if ((ctx->flags & TLS_SERVER) == 0) {
		tls_set_errorx(ctx, "not a server context");
		goto err;
	}

	if ((conn_ctx = tls_server_conn(ctx)) == NULL) {
		tls_set_errorx(ctx, "connection context failure");
		goto err;
	}

	if ((conn = tls_conn_new(ctx)) == NULL) {
		goto err;
	}

	conn->ctx = conn_ctx;
	conn_ctx->conn = conn;

	conn->policy = &policy_vtable;
	br_ssl_server_set_policy(&conn->u.server, &conn->policy);

	flags = BR_OPT_NO_RENEGOTIATION;
	if (conn_ctx->config->verify_client != 0) {
		if (tls_configure_x509(conn_ctx) != 0)
			goto err;

		if (ctx->config->ca_len == 0) {
			tls_set_error(ctx, "cannot verify client without trust anchors");
			goto err;
		}

		br_ssl_server_set_trust_anchor_names_alt(&conn_ctx->conn->u.server,
		    ctx->config->ca, ctx->config->ca_len);

		if (conn_ctx->config->verify_client == 2)
			flags |= BR_OPT_TOLERATE_NO_CLIENT_AUTH;
	}
	if (conn_ctx->config->ciphers_server == 1)
		flags |= BR_OPT_ENFORCE_SERVER_PREFERENCES;
	br_ssl_engine_set_all_flags(&conn_ctx->conn->u.engine, flags);

	/* DHE is not supported by BearSSL, so it is safe to ignore
	 * ctx->config->dheparams */

	br_ssl_server_reset(&conn_ctx->conn->u.server);

	return conn_ctx;

 err:
	tls_free(conn_ctx);

	return (NULL);
}

int
tls_accept_socket(struct tls *ctx, struct tls **cctx, int s)
{
	return (tls_accept_fds(ctx, cctx, s, s));
}

int
tls_accept_fds(struct tls *ctx, struct tls **cctx, int fd_read, int fd_write)
{
	struct tls *conn_ctx;

	if ((conn_ctx = tls_accept_common(ctx)) == NULL)
		goto err;

	conn_ctx->read_cb = tls_fd_read_cb;
	conn_ctx->fd_read = fd_read;
	conn_ctx->write_cb = tls_fd_write_cb;
	conn_ctx->fd_write = fd_write;
	conn_ctx->cb_arg = NULL;

	*cctx = conn_ctx;

	return (0);
 err:
	tls_free(conn_ctx);
	*cctx = NULL;

	return (-1);
}

int
tls_accept_cbs(struct tls *ctx, struct tls **cctx,
    tls_read_cb read_cb, tls_write_cb write_cb, void *cb_arg)
{
	struct tls *conn_ctx;

	if ((conn_ctx = tls_accept_common(ctx)) == NULL)
		goto err;

	if (tls_set_cbs(conn_ctx, read_cb, write_cb, cb_arg) != 0)
		goto err;

	*cctx = conn_ctx;

	return (0);
 err:
	tls_free(conn_ctx);
	*cctx = NULL;

	return (-1);
}
