/* $OpenBSD: tls_conninfo.c,v 1.21 2019/11/02 13:37:59 jsing Exp $ */
/*
 * Copyright (c) 2015 Joel Sing <jsing@openbsd.org>
 * Copyright (c) 2015 Bob Beck <beck@openbsd.org>
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

#include <stdio.h>
#include <stdlib.h>

#include <tls.h>
#include "tls_internal.h"

#ifdef WIN32
# include <time.h>
#endif

int ASN1_time_tm_clamp_notafter(struct tm *tm);

int
tls_hex_string(const unsigned char *in, size_t inlen, char **out,
    size_t *outlen)
{
	static const char hex[] = "0123456789abcdef";
	size_t i, len;
	char *p;

	if (outlen != NULL)
		*outlen = 0;

	if (inlen >= SIZE_MAX)
		return (-1);
	if ((*out = reallocarray(NULL, inlen + 1, 2)) == NULL)
		return (-1);

	p = *out;
	len = 0;
	for (i = 0; i < inlen; i++) {
		p[len++] = hex[(in[i] >> 4) & 0x0f];
		p[len++] = hex[in[i] & 0x0f];
	}
	p[len++] = 0;

	if (outlen != NULL)
		*outlen = len;

	return (0);
}

static int
tls_get_peer_cert_hash(struct tls *ctx, char **hash)
{
	*hash = NULL;
	if (ctx->peer_chain == NULL)
		return (0);

	if (tls_cert_hash(&ctx->peer_chain[0], hash) == -1) {
		tls_set_errorx(ctx, "unable to compute peer certificate hash - out of memory");
		*hash = NULL;
		return -1;
	}
	return 0;
}

static int
tls_get_peer_cert_issuer(struct tls *ctx,  char **issuer)
{
	/* XXX: BearSSL has no way to get certificate issuer string */
	*issuer = NULL;

	return (0);
}

static size_t
escape_name_element(char *dst, const char *src)
{
	size_t len = 0;
	int esc;

	for (; *src; ++src) {
		switch (*src) {
		case ',':
		case '+':
		case '"':
		case '\\':
		case '<':
		case '>':
		case ':':
			esc = 1;
			break;
		case ' ':
			esc = len == 0 || !src[1];
			break;
		case '#':
			esc = len == 0;
			break;
		default:
			esc = 0;
		}
		if (dst) {
			if (esc)
				*dst++ = '\\';
			*dst++ = *src;
		}
		len += 1 + esc;
	}

	return len;
}

static int
tls_get_peer_cert_subject(struct tls *ctx, char **subject)
{
	static const char attr[][3] = {
		[TLS_DN_C] = "C",
		[TLS_DN_ST] = "ST",
		[TLS_DN_L] = "L",
		[TLS_DN_O] = "O",
		[TLS_DN_OU] = "OU",
		[TLS_DN_CN] = "CN",
	};
	char *p;
	size_t i, len;
	br_name_element *elts;

	*subject = NULL;
	if (ctx->conn == NULL || ctx->conn->x509 == NULL)
		return (-1);

	/* calculate subject string length */
	elts = ctx->conn->x509->subject_elts;
	len = 0;
	for (i = 0; i < TLS_DN_NUM_ELTS; ++i) {
		if (elts[i].status == -1)
			return (-1);
		if (elts[i].status == 1)
			len += 4 + escape_name_element(NULL, elts[i].buf);
	}

	if ((*subject = p = malloc(len)) == NULL)
		return (-1);

	for (i = 0; i < TLS_DN_NUM_ELTS; ++i) {
		if (elts[i].status != 1)
			continue;
		p = stpcpy(p, attr[i]);
		*p++ = '=';
		p += escape_name_element(p, elts[i].buf);
		*p++ = ',';
	}
	p[-1] = '\0';

	return (0);
}

static int
tls_get_peer_cert_times(struct tls *ctx, time_t *notbefore,
    time_t *notafter)
{
	/* XXX: BearSSL has no way to get certificate notBefore and
	 * notAfter */
	*notbefore = -1;
	*notafter = -1;

	return (0);
}

static int
tls_get_peer_cert_info(struct tls *ctx)
{
	if (ctx->peer_chain == NULL)
		return (0);

	if (tls_get_peer_cert_hash(ctx, &ctx->conninfo->hash) == -1)
		goto err;
	if (tls_get_peer_cert_subject(ctx, &ctx->conninfo->subject) == -1)
		goto err;
	if (tls_get_peer_cert_issuer(ctx, &ctx->conninfo->issuer) == -1)
		goto err;
	if (tls_get_peer_cert_times(ctx, &ctx->conninfo->notbefore,
	    &ctx->conninfo->notafter) == -1)
		goto err;

	return (0);

 err:
	return (-1);
}

static int
tls_conninfo_alpn_proto(struct tls *ctx)
{
	const char *alpn;

	alpn = br_ssl_engine_get_selected_protocol(&ctx->conn->u.engine);
	if (alpn)
		ctx->conninfo->alpn = strdup(alpn);

	return (0);
}

static int
tls_conninfo_cert_pem(struct tls *ctx)
{
	int rv = -1;
	uint8_t *ptr;
	size_t len, i;

	if (ctx->peer_chain == NULL)
		return 0;

	len = 0;
	for (i = 0; i < ctx->peer_chain_len; ++i) {
		len += br_pem_encode(NULL, NULL, ctx->peer_chain[i].data_len,
		    "X509 CERTIFICATE", 0);
	}

	free(ctx->conninfo->peer_cert);
	ctx->conninfo->peer_cert_len = 0;
	if ((ctx->conninfo->peer_cert = ptr = malloc(len)) == NULL)
		goto err;

	for (i = 0; i < ctx->peer_chain_len; ++i) {
		ptr += br_pem_encode(ptr, ctx->peer_chain[i].data,
		    ctx->peer_chain[i].data_len, "X509 CERTIFICATE", 0);
	}

	rv = 0;
 err:
	return rv;
}

int
tls_conninfo_populate(struct tls *ctx)
{
	br_ssl_session_parameters params;
	const char *tmp;

	tls_conninfo_free(ctx->conninfo);

	if ((ctx->conninfo = calloc(1, sizeof(struct tls_conninfo))) == NULL) {
		tls_set_errorx(ctx, "out of memory");
		goto err;
	}

	if (tls_conninfo_alpn_proto(ctx) == -1)
		goto err;

	br_ssl_engine_get_session_parameters(&ctx->conn->u.engine, &params);
	if ((tmp = bearssl_suite_name(params.cipher_suite)) == NULL)
		goto err;
	if ((ctx->conninfo->cipher = strdup(tmp)) == NULL)
		goto err;
	ctx->conninfo->cipher_strength = bearssl_suite_bits(params.cipher_suite);

	if (ctx->servername != NULL) {
		if ((ctx->conninfo->servername =
		    strdup(ctx->servername)) == NULL)
			goto err;
	}

	switch (br_ssl_engine_get_version(&ctx->conn->u.engine)) {
	case BR_TLS10:
		tmp = "TLSv1";
		break;
	case BR_TLS11:
		tmp = "TLSv1.1";
		break;
	case BR_TLS12:
		tmp = "TLSv1.2";
		break;
	default:
		goto err;
	}
	if ((ctx->conninfo->version = strdup(tmp)) == NULL)
		goto err;

	if (tls_get_peer_cert_info(ctx) == -1)
		goto err;

	if (tls_conninfo_cert_pem(ctx) == -1)
		goto err;

	return (0);

 err:
	explicit_bzero(&params, sizeof(params));
	tls_conninfo_free(ctx->conninfo);
	ctx->conninfo = NULL;

	return (-1);
}

void
tls_conninfo_free(struct tls_conninfo *conninfo)
{
	if (conninfo == NULL)
		return;

	free(conninfo->alpn);
	free(conninfo->cipher);
	free(conninfo->servername);
	free(conninfo->version);

	free(conninfo->hash);
	free(conninfo->issuer);
	free(conninfo->subject);

	free(conninfo->peer_cert);

	free(conninfo);
}

const char *
tls_conn_alpn_selected(struct tls *ctx)
{
	if (ctx->conninfo == NULL)
		return (NULL);
	return (ctx->conninfo->alpn);
}

const char *
tls_conn_cipher(struct tls *ctx)
{
	if (ctx->conninfo == NULL)
		return (NULL);
	return (ctx->conninfo->cipher);
}

int
tls_conn_cipher_strength(struct tls *ctx)
{
	if (ctx->conninfo == NULL)
		return (0);
	return (ctx->conninfo->cipher_strength);
}

const char *
tls_conn_servername(struct tls *ctx)
{
	if (ctx->conninfo == NULL)
		return (NULL);
	return (ctx->conninfo->servername);
}

int
tls_conn_session_resumed(struct tls *ctx)
{
	/* we don't support session resumption */
	return (0);
}

const char *
tls_conn_version(struct tls *ctx)
{
	if (ctx->conninfo == NULL)
		return (NULL);
	return (ctx->conninfo->version);
}
