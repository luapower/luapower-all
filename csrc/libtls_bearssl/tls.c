/* $OpenBSD: tls.c,v 1.85 2020/05/24 15:12:54 jsing Exp $ */
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
#else
# include <sys/socket.h>
#endif

#include <errno.h>
#include <limits.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <tls.h>
#include "tls_internal.h"

static struct tls_config *tls_config_default;

static int tls_init_rv = -1;

static void
tls_do_init(void)
{
	if ((tls_config_default = tls_config_new_internal()) == NULL)
		return;

	tls_config_default->refcount++;

	tls_init_rv = 0;
}

int
tls_init(void)
{
	static pthread_once_t once = PTHREAD_ONCE_INIT;

	if (pthread_once(&once, tls_do_init) != 0)
		return -1;

	return tls_init_rv;
}

const char *
tls_error(struct tls *ctx)
{
	return ctx->error.msg;
}

void
tls_error_clear(struct tls_error *error)
{
	free(error->msg);
	error->msg = NULL;
	error->num = 0;
	error->tls = 0;
}

static int
tls_error_vset(struct tls_error *error, int errnum, const char *fmt, va_list ap)
{
	char *errmsg = NULL;
	int rv = -1;

	tls_error_clear(error);

	error->num = errnum;
	error->tls = 1;

	if (vasprintf(&errmsg, fmt, ap) == -1) {
		errmsg = NULL;
		goto err;
	}

	if (errnum == -1) {
		error->msg = errmsg;
		return (0);
	}

	if (asprintf(&error->msg, "%s: %s", errmsg, strerror(errnum)) == -1) {
		error->msg = NULL;
		goto err;
	}
	rv = 0;

 err:
	free(errmsg);

	return (rv);
}

int
tls_error_set(struct tls_error *error, const char *fmt, ...)
{
	va_list ap;
	int errnum, rv;

	errnum = errno;

	va_start(ap, fmt);
	rv = tls_error_vset(error, errnum, fmt, ap);
	va_end(ap);

	return (rv);
}

int
tls_error_setx(struct tls_error *error, const char *fmt, ...)
{
	va_list ap;
	int rv;

	va_start(ap, fmt);
	rv = tls_error_vset(error, -1, fmt, ap);
	va_end(ap);

	return (rv);
}

int
tls_config_set_error(struct tls_config *config, const char *fmt, ...)
{
	va_list ap;
	int errnum, rv;

	errnum = errno;

	va_start(ap, fmt);
	rv = tls_error_vset(&config->error, errnum, fmt, ap);
	va_end(ap);

	return (rv);
}

int
tls_config_set_errorx(struct tls_config *config, const char *fmt, ...)
{
	va_list ap;
	int rv;

	va_start(ap, fmt);
	rv = tls_error_vset(&config->error, -1, fmt, ap);
	va_end(ap);

	return (rv);
}

int
tls_set_error(struct tls *ctx, const char *fmt, ...)
{
	va_list ap;
	int errnum, rv;

	errnum = errno;

	va_start(ap, fmt);
	rv = tls_error_vset(&ctx->error, errnum, fmt, ap);
	va_end(ap);

	return (rv);
}

int
tls_set_errorx(struct tls *ctx, const char *fmt, ...)
{
	va_list ap;
	int rv;

	va_start(ap, fmt);
	rv = tls_error_vset(&ctx->error, -1, fmt, ap);
	va_end(ap);

	return (rv);
}

int
tls_set_ssl_errorx(struct tls *ctx, const char *fmt, ...)
{
	va_list ap;
	int rv;

	/* Only set an error if a more specific one does not already exist. */
	if (ctx->error.tls != 0)
		return (0);

	va_start(ap, fmt);
	rv = tls_error_vset(&ctx->error, -1, fmt, ap);
	va_end(ap);

	return (rv);
}

struct tls *
tls_new(void)
{
	struct tls *ctx;

	if ((ctx = calloc(1, sizeof(*ctx))) == NULL)
		return (NULL);

	tls_reset(ctx);

	if (tls_configure(ctx, tls_config_default) == -1) {
		free(ctx);
		return NULL;
	}

	return (ctx);
}

int
tls_configure(struct tls *ctx, struct tls_config *config)
{
	struct tls_keypair *kp;
	int rv = -1, required;

	if (config == NULL)
		config = tls_config_default;

	pthread_mutex_lock(&config->mutex);
	config->refcount++;
	pthread_mutex_unlock(&config->mutex);

	tls_config_free(ctx->config);

	ctx->config = config;
	ctx->keypair = config->keypair;

	required = (ctx->flags & TLS_SERVER) != 0;
	for (kp = ctx->keypair; kp; kp = kp->next) {
		if (kp->key_type == 0 && kp->chain_len == 0 && !required)
			continue;
		if (tls_keypair_check(kp, &ctx->error) != 0)
			goto err;
	}

	rv = 0;

 err:
	return (rv);
}

int
tls_cert_hash(br_x509_certificate *cert, char **hash)
{
	br_sha256_context ctx;
	unsigned char d[br_sha256_SIZE];
	char *dhex = NULL;
	int rv = -1;

	free(*hash);
	*hash = NULL;

	br_sha256_init(&ctx);
	br_sha256_update(&ctx, cert->data, cert->data_len);
	br_sha256_out(&ctx, d);

	if (tls_hex_string(d, sizeof(d), &dhex, NULL) != 0)
		goto err;

	if (asprintf(hash, "SHA256:%s", dhex) == -1) {
		*hash = NULL;
		goto err;
	}

	rv = 0;
 err:
	free(dhex);

	return (rv);
}

static void
x509_start_chain(const br_x509_class **vtable, const char *server_name)
{
	struct tls_x509 *x509 = TLS_CONTAINER_OF(vtable, struct tls_x509, vtable);

	if (!x509->ctx->config->verify_name)
		server_name = NULL;
	x509->depth = 0;
	x509->minimal.vtable->start_chain(&x509->minimal.vtable, server_name);
}

static void
x509_start_cert(const br_x509_class **vtable, uint32_t length)
{
	struct tls_x509 *x509 = TLS_CONTAINER_OF(vtable, struct tls_x509, vtable);
	struct tls *ctx = x509->ctx;
	br_x509_certificate *chain, *cert;

	++x509->depth;
	x509->minimal.vtable->start_cert(&x509->minimal.vtable, length);

	if (ctx->error.tls == 0) {
		if ((chain = reallocarray(ctx->peer_chain, ctx->peer_chain_len + 1,
		    sizeof(chain[0]))) == NULL) {
			tls_set_error(ctx, "X.509 certificate chain");
			return;
		}
		++ctx->peer_chain_len;
		ctx->peer_chain = chain;

		cert = &chain[ctx->peer_chain_len - 1];
		cert->data_len = 0;
		if ((cert->data = calloc(1, length)) == NULL) {
			tls_set_error(ctx, "X.509 certificate chain");
			return;
		}
	}
}

static void
x509_append(const br_x509_class **vtable, const unsigned char *buf, size_t len)
{
	struct tls_x509 *x509 = TLS_CONTAINER_OF(vtable, struct tls_x509, vtable);
	struct tls *ctx = x509->ctx;
	br_x509_certificate *cert = &ctx->peer_chain[ctx->peer_chain_len - 1];

	if (ctx->error.tls == 0) {
		memcpy(cert->data + cert->data_len, buf, len);
		cert->data_len += len;
	}
	x509->minimal.vtable->append(&x509->minimal.vtable, buf, len);
}

static void
x509_end_cert(const br_x509_class **vtable)
{
	struct tls_x509 *x509 = TLS_CONTAINER_OF(vtable, struct tls_x509, vtable);

	x509->minimal.vtable->end_cert(&x509->minimal.vtable);
}

static unsigned
x509_end_chain(const br_x509_class **vtable)
{
	struct tls_x509 *x509 = TLS_CONTAINER_OF(vtable, struct tls_x509, vtable);
	struct tls *ctx = x509->ctx;
	unsigned err;

	err = x509->minimal.vtable->end_chain(&x509->minimal.vtable);
	switch (err) {
	case BR_ERR_X509_EXPIRED:
		if (ctx->config->verify_time == 0)
			err = BR_ERR_OK;
		break;
	case BR_ERR_X509_BAD_SERVER_NAME:
		if (ctx->config->verify_name == 0)
			err = BR_ERR_OK;
		break;
	case BR_ERR_X509_NOT_TRUSTED:
		if (ctx->config->verify_cert == 0)
			err = BR_ERR_OK;
		break;
	}

	if (x509->depth > ctx->config->verify_depth + 2) {
		err = BR_ERR_X509_LIMIT_EXCEEDED;
		goto out;
	}

	if (x509->ctx->error.tls) {
		/* out of memory when allocating certificate chain */
		err = -1;
		goto out;
	}

 out:
	return err;
}

static const br_x509_pkey *
x509_get_pkey(const br_x509_class *const *vtable, unsigned *usages)
{
	struct tls_x509 *x509 = TLS_CONTAINER_OF(vtable, struct tls_x509, vtable);

	return x509->minimal.vtable->get_pkey(&x509->minimal.vtable, usages);
}

static const br_x509_class x509_vtable = {
	.start_chain = x509_start_chain,
	.start_cert = x509_start_cert,
	.append = x509_append,
	.end_cert = x509_end_cert,
	.end_chain = x509_end_chain,
	.get_pkey = x509_get_pkey,
};

struct tls_conn *
tls_conn_new(struct tls *ctx)
{
	struct tls_conn *conn;
	br_ssl_engine_context *eng;
	unsigned version_min, version_max;

	if ((conn = calloc(1, sizeof(*conn))) == NULL)
		return NULL;

	eng = &conn->u.engine;

	switch (ctx->config->protocols) {
	case TLS_PROTOCOL_TLSv1_0:
		version_min = BR_TLS10;
		version_max = BR_TLS10;
		break;
	case TLS_PROTOCOL_TLSv1_0|TLS_PROTOCOL_TLSv1_1:
		version_min = BR_TLS10;
		version_max = BR_TLS11;
		break;
	case TLS_PROTOCOL_TLSv1_0|TLS_PROTOCOL_TLSv1_1|TLS_PROTOCOL_TLSv1_2:
	case TLS_PROTOCOL_TLSv1_0|TLS_PROTOCOL_TLSv1_1|TLS_PROTOCOL_TLSv1_2|TLS_PROTOCOL_TLSv1_3:
		version_min = BR_TLS10;
		version_max = BR_TLS12;
		break;
	case TLS_PROTOCOL_TLSv1_1:
		version_min = BR_TLS11;
		version_max = BR_TLS11;
		break;
	case TLS_PROTOCOL_TLSv1_1|TLS_PROTOCOL_TLSv1_2:
	case TLS_PROTOCOL_TLSv1_1|TLS_PROTOCOL_TLSv1_2|TLS_PROTOCOL_TLSv1_3:
		version_min = BR_TLS11;
		version_max = BR_TLS12;
		break;
	case TLS_PROTOCOL_TLSv1_2:
	case TLS_PROTOCOL_TLSv1_2|TLS_PROTOCOL_TLSv1_3:
		version_min = BR_TLS12;
		version_max = BR_TLS12;
		break;
	default:
		tls_set_errorx(ctx, "unsupported set of protocol versions");
		goto err;
	}
	br_ssl_engine_set_versions(eng, version_min, version_max);
	br_ssl_engine_set_buffer(eng, conn->buf, BR_SSL_BUFSIZE_BIDI, 1);

	if (ctx->config->alpn != NULL) {
		br_ssl_engine_set_protocol_names(eng, ctx->config->alpn,
		    ctx->config->alpn_len);
	}

	if (ctx->config->suites != NULL) {
		br_ssl_engine_set_suites(eng, ctx->config->suites,
		    ctx->config->suites_len);
	}

	br_ssl_engine_set_default_rsavrfy(eng);
	br_ssl_engine_set_default_ecdsa(eng);
	/* default EC implementation, possibly with some curves removed */
	br_ssl_engine_set_ec(eng, &ctx->config->ec);

	br_ssl_engine_set_hash(eng, br_md5_ID, &br_md5_vtable);
	br_ssl_engine_set_hash(eng, br_sha1_ID, &br_sha1_vtable);
	br_ssl_engine_set_hash(eng, br_sha224_ID, &br_sha224_vtable);
	br_ssl_engine_set_hash(eng, br_sha256_ID, &br_sha256_vtable);
	br_ssl_engine_set_hash(eng, br_sha384_ID, &br_sha384_vtable);
	br_ssl_engine_set_hash(eng, br_sha512_ID, &br_sha512_vtable);

	br_ssl_engine_set_prf10(eng, &br_tls10_prf);
	br_ssl_engine_set_prf_sha256(eng, &br_tls12_sha256_prf);
	br_ssl_engine_set_prf_sha384(eng, &br_tls12_sha384_prf);

	br_ssl_engine_set_default_aes_cbc(eng);
	br_ssl_engine_set_default_aes_ccm(eng);
	br_ssl_engine_set_default_aes_gcm(eng);
	br_ssl_engine_set_default_des_cbc(eng);
	br_ssl_engine_set_default_chapol(eng);

	return (conn);

 err:
	return (NULL);
}

int
tls_configure_x509(struct tls *ctx)
{
	int rv = -1;
	struct tls_x509 *x509;

	/* If no CA has been specified, attempt to load the default. */
	if (ctx->config->verify_cert != 0 &&
	    ctx->config->ca == NULL &&
	    tls_config_set_ca_file(ctx->config, tls_default_ca_cert_file()) != 0) {
		tls_set_errorx(ctx, "CA load failed");
		goto err;
	}

	if ((x509 = calloc(1, sizeof(*x509))) == NULL) {
		tls_set_error(ctx, "X.509 context");
		goto err;
	}

	x509->ctx = ctx;
	x509->vtable = &x509_vtable;
	x509->subject_elts[TLS_DN_C] = (br_name_element){
		/* 2.5.4.6,  id-at-countryName */
		.oid = (unsigned char *)"\x03\x55\x04\x06",
		.buf = x509->subject.C,
		.len = sizeof(x509->subject.C),
	};
	x509->subject_elts[TLS_DN_ST] = (br_name_element){
		/* 2.5.4.8,  id-at-stateOrProvinceName */
		.oid = (unsigned char *)"\x03\x55\x04\x08",
		.buf = x509->subject.ST,
		.len = sizeof(x509->subject.ST),
	};
	x509->subject_elts[TLS_DN_L] = (br_name_element){
		/* 2.5.4.7,  id-at-localityName */
		.oid = (unsigned char *)"\x03\x55\x04\x07",
		.buf = x509->subject.L,
		.len = sizeof(x509->subject.L),
	};
	x509->subject_elts[TLS_DN_O] = (br_name_element){
		/* 2.5.4.10, id-at-organizationName */
		.oid = (unsigned char *)"\x03\x55\x04\x0a",
		.buf = x509->subject.O,
		.len = sizeof(x509->subject.O),
	};
	x509->subject_elts[TLS_DN_OU] = (br_name_element){
		/* 2.5.4.11, id-at-organizationalUnitName */
		.oid = (unsigned char *)"\x03\x55\x04\x0b",
		.buf = x509->subject.OU,
		.len = sizeof(x509->subject.OU),
	};
	x509->subject_elts[TLS_DN_CN] = (br_name_element){
		/* 2.5.4.3,  id-at-commonName */
		.oid = (unsigned char *)"\x03\x55\x04\x03",
		.buf = x509->subject.CN,
		.len = sizeof(x509->subject.CN),
	};
	br_x509_minimal_init_full(&x509->minimal, ctx->config->ca,
	    ctx->config->ca_len);
	br_x509_minimal_set_name_elements(&x509->minimal,
	    x509->subject_elts, TLS_DN_NUM_ELTS);
	br_ssl_engine_set_x509(&ctx->conn->u.engine, &x509->vtable);

	ctx->conn->x509 = x509;

	rv = 0;

 err:
	return (rv);
}

void
tls_free(struct tls *ctx)
{
	if (ctx == NULL)
		return;

	tls_reset(ctx);

	free(ctx);
}

void
tls_reset(struct tls *ctx)
{
	size_t i;

	tls_config_free(ctx->config);
	ctx->config = NULL;

	if (ctx->conn) {
		free(ctx->conn->x509);
		freezero(ctx->conn, sizeof(*ctx->conn));
	}
	ctx->conn = NULL;

	for (i = 0; i < ctx->peer_chain_len; ++i)
		free(ctx->peer_chain[i].data);
	ctx->peer_chain = NULL;
	ctx->peer_chain_len = 0;

	ctx->peer_chain = NULL;

	ctx->socket = -1;
	ctx->state = 0;

	free(ctx->servername);
	ctx->servername = NULL;

	free(ctx->error.msg);
	ctx->error.msg = NULL;
	ctx->error.num = -1;

	tls_conninfo_free(ctx->conninfo);
	ctx->conninfo = NULL;

	ctx->read_cb = NULL;
	ctx->write_cb = NULL;
	ctx->cb_arg = NULL;
}

/*
 * Run the TLS engine until the target state is reached, or an error
 * occurs.
 *
 * Return value:
 *    1  The desired state was reached.
 *    0  The engine was closed without error, or the read callback
 *       returned 0 and the handshake was completed.
 *   -1  The engine encountered an error, or the read or write
 *       callback returned -1, or the write callback returned 0.
 *   <0  The read or write callback returned some other negative
 *       value (for instance, TLS_WANT_POLLIN or TLS_WANT_POLLOUT).
 */
static int
tls_run_until(struct tls *ctx, unsigned target, const char *prefix)
{
	br_ssl_engine_context *eng = &ctx->conn->u.engine;
	unsigned state;
	unsigned char *buf;
	size_t len;
	ssize_t ret;
	int rv = -1, err;

	for (;;) {
		state = br_ssl_engine_current_state(eng);
		if (state & BR_SSL_CLOSED) {
			if ((err = br_ssl_engine_last_error(eng)) != 0)
				tls_set_ssl_errorx(ctx, "%s (%d)", bearssl_strerror(err), err);
			else
				rv = 0;
			goto out;
		}
		if (state & BR_SSL_SENDREC) {
			buf = br_ssl_engine_sendrec_buf(eng, &len);
			ret = (ctx->write_cb)(ctx, buf, len, ctx->cb_arg);
			if (ret == 0)
				ret = -1;
			if (ret == -1)
				tls_set_error(ctx, "%s failed", prefix);
			if (ret < 0) {
				rv = ret;
				goto out;
			}
			br_ssl_engine_sendrec_ack(eng, ret);
			continue;
		}
		if (state & target)
			break;
		if (state & BR_SSL_RECVAPP) {
			/* we use a bidirectional buffer, so this
			 * should never happen */
			tls_set_error(ctx, "unexpected I/O state");
			goto out;
		}
		if (state & BR_SSL_RECVREC) {
			buf = br_ssl_engine_recvrec_buf(eng, &len);
			ret = (ctx->read_cb)(ctx, buf, len, ctx->cb_arg);
			if (ret == 0) {
				if ((ctx->state & TLS_HANDSHAKE_COMPLETE) != 0) {
					ctx->state |= TLS_EOF_NO_CLOSE_NOTIFY;
					rv = 0;
				} else {
					tls_set_errorx(ctx, "unexpected EOF");
				}
				goto out;
			}
			if (ret == -1)
				tls_set_error(ctx, "%s failed", prefix);
			if (ret < 0) {
				rv = ret;
				goto out;
			}
			br_ssl_engine_recvrec_ack(eng, ret);
			continue;
		}
		br_ssl_engine_flush(eng, 0);
	}

	rv = 1;

 out:
	return rv;
}

int
tls_handshake(struct tls *ctx)
{
	int rv = -1;

	tls_error_clear(&ctx->error);

	if ((ctx->flags & TLS_CLIENT) != 0) {
		if ((ctx->state & TLS_CONNECTED) == 0) {
			tls_set_errorx(ctx, "context not connected");
			goto out;
		}
	} else if ((ctx->flags & TLS_SERVER_CONN) == 0) {
		tls_set_errorx(ctx, "invalid operation for context");
		goto out;
	}

	if ((ctx->state & TLS_HANDSHAKE_COMPLETE) != 0) {
		tls_set_errorx(ctx, "handshake already completed");
		goto out;
	}

	ctx->state |= TLS_SSL_NEEDS_SHUTDOWN;

	if ((rv = tls_run_until(ctx, BR_SSL_SENDAPP | BR_SSL_RECVAPP, "handshake")) != 1)
		goto out;

	ctx->state |= TLS_HANDSHAKE_COMPLETE;

	if (tls_conninfo_populate(ctx) == -1) {
		rv = -1;
		goto out;
	}

	rv = 0;

 out:
	/* Prevent callers from performing incorrect error handling */
	errno = 0;
	return (rv);
}

ssize_t
tls_read(struct tls *ctx, void *buf, size_t buflen)
{
	br_ssl_engine_context *eng = &ctx->conn->u.engine;
	ssize_t rv = -1;
	unsigned char *app;
	size_t applen;

	tls_error_clear(&ctx->error);

	if ((ctx->state & TLS_HANDSHAKE_COMPLETE) == 0) {
		if ((rv = tls_handshake(ctx)) != 0)
			goto out;
	}

	if ((rv = tls_run_until(ctx, BR_SSL_RECVAPP, "read")) != 1)
		goto out;

	app = br_ssl_engine_recvapp_buf(eng, &applen);
	if (applen > buflen)
		applen = buflen;
	memcpy(buf, app, applen);
	br_ssl_engine_recvapp_ack(eng, applen);

	rv = applen;

 out:
	/* Prevent callers from performing incorrect error handling */
	errno = 0;
	return (rv);
}

ssize_t
tls_write(struct tls *ctx, const void *buf, size_t buflen)
{
	br_ssl_engine_context *eng = &ctx->conn->u.engine;
	ssize_t rv = -1;
	unsigned char *app;
	size_t applen;

	tls_error_clear(&ctx->error);

	if ((ctx->state & TLS_HANDSHAKE_COMPLETE) == 0) {
		if ((rv = tls_handshake(ctx)) != 0)
			goto out;
	}

	for (;;) {
		if ((rv = tls_run_until(ctx, BR_SSL_SENDAPP, "write")) == 0) {
			tls_set_ssl_errorx(ctx, "connection closed");
			rv = -1;
		}
		if (rv != 1)
			goto out;
		if (ctx->conn->write_len > 0)
			break;

		app = br_ssl_engine_sendapp_buf(eng, &applen);
		if (applen > buflen)
			applen = buflen;
		memcpy(app, buf, applen);
		br_ssl_engine_sendapp_ack(eng, applen);
		br_ssl_engine_flush(eng, 0);
		ctx->conn->write_len = applen;
	}

	rv = ctx->conn->write_len;
	ctx->conn->write_len = 0;

 out:
	/* Prevent callers from performing incorrect error handling */
	errno = 0;
	return (rv);
}

int
tls_close(struct tls *ctx)
{
	br_ssl_engine_context *eng = &ctx->conn->u.engine;
	int rv = 0;

	tls_error_clear(&ctx->error);

	if ((ctx->flags & (TLS_CLIENT | TLS_SERVER_CONN)) == 0) {
		tls_set_errorx(ctx, "invalid operation for context");
		rv = -1;
		goto out;
	}

	if (ctx->state & TLS_SSL_NEEDS_SHUTDOWN) {
		if ((ctx->state & TLS_SSL_IN_SHUTDOWN) == 0) {
			br_ssl_engine_close(eng);
			ctx->state |= TLS_SSL_IN_SHUTDOWN;
		}
		rv = tls_run_until(ctx, 0, "close");
		if (rv == TLS_WANT_POLLIN || rv == TLS_WANT_POLLOUT)
			goto out;
		ctx->state &= ~TLS_SSL_NEEDS_SHUTDOWN;
	}

	if (ctx->socket != -1) {
		if (shutdown(ctx->socket, SHUT_RDWR) != 0) {
			if (rv == 0 &&
			    errno != ENOTCONN && errno != ECONNRESET) {
				tls_set_error(ctx, "shutdown");
				rv = -1;
			}
		}
		if (close(ctx->socket) != 0) {
			if (rv == 0) {
				tls_set_error(ctx, "close");
				rv = -1;
			}
		}
		ctx->socket = -1;
	}

	if ((ctx->state & TLS_EOF_NO_CLOSE_NOTIFY) != 0) {
		tls_set_errorx(ctx, "EOF without close notify");
		rv = -1;
	}

 out:
	/* Prevent callers from performing incorrect error handling */
	errno = 0;
	return (rv);
}

