/* $OpenBSD: tls_keypair.c,v 1.6 2018/04/07 16:35:34 jsing Exp $ */
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

#include <stdlib.h>

#include <tls.h>

#include "tls_internal.h"

struct tls_keypair *
tls_keypair_new(void)
{
	return calloc(1, sizeof(struct tls_keypair));
}

void
tls_keypair_clear_key(struct tls_keypair *keypair)
{
	keypair->key_type = 0;
	freezero(keypair->key_data, keypair->key_data_len);
	keypair->key_data = NULL;
	keypair->key_data_len = 0;
	explicit_bzero(&keypair->key, sizeof(keypair->key));
}

int
tls_keypair_set_cert_file(struct tls_keypair *keypair, struct tls_error *error,
    const char *cert_file)
{
	int rv = -1;
	char *cert = NULL;
	size_t len;

	if (tls_config_load_file(error, "certificate", cert_file,
	    &cert, &len) == -1)
		return -1;

	if (tls_keypair_set_cert_mem(keypair, error, (uint8_t *)cert, len) != 0)
		goto err;

	rv = 0;

 err:
	free(cert);
	return rv;
}

struct cert_pem_ctx {
	struct tls_error *error;
	char *buf;
	size_t len;
	size_t cap;
};

static void
append_cert(void *data, const void *src, size_t len)
{
	struct cert_pem_ctx *ctx = data;
	size_t cap;
	char *buf;

	if (ctx->error->tls)
		return;
	cap = ctx->cap;
	while (cap - ctx->len < len)
		cap = ctx->cap ? ctx->cap * 2 : 1024;
	if (ctx->cap != cap) {
		if ((buf = realloc(ctx->buf, cap)) == NULL) {
			tls_error_set(ctx->error, "certificate buffer");
			return;
		}
		ctx->buf = buf;
		ctx->cap = cap;
	}
	memcpy(ctx->buf + ctx->len, src, len);
	ctx->len += len;
}

int
tls_keypair_set_cert_mem(struct tls_keypair *keypair, struct tls_error *error,
    const uint8_t *mem, size_t len)
{
	struct cert_pem_ctx ctx = {.error = error};
	br_pem_decoder_context pc;
	size_t pushed;
	const char *name;
	br_x509_certificate *chain = NULL, *new_chain, *cert = NULL;
	size_t chain_len = 0;
	int rv = -1;

	br_pem_decoder_init(&pc);
	while (len > 0) {
		pushed = br_pem_decoder_push(&pc, mem, len);
		mem += pushed;
		len -= pushed;
		switch (br_pem_decoder_event(&pc)) {
		case BR_PEM_BEGIN_OBJ:
			name = br_pem_decoder_name(&pc);
			if (strcmp(name, "CERTIFICATE") != 0 &&
			    strcmp(name, "X509 CERTIFICATE") != 0) {
				br_pem_decoder_setdest(&pc, NULL, NULL);
				cert = NULL;
				break;
			}
			++chain_len;
			if ((new_chain = reallocarray(chain, chain_len, sizeof(chain[0]))) == NULL) {
				tls_error_set(error, "certificate chain");
				goto err;
			}
			chain = new_chain;
			cert = &chain[chain_len - 1];
			br_pem_decoder_setdest(&pc, append_cert, &ctx);
			ctx.len = 0;
			break;
		case BR_PEM_END_OBJ:
			if (cert == NULL)
				break;
			if ((cert->data = malloc(ctx.len)) == NULL) {
				tls_error_set(error, "certificate data");
				goto err;
			}
			memcpy(cert->data, ctx.buf, ctx.len);
			cert->data_len = ctx.len;
			break;
		default:
			tls_error_setx(error, "certificate decoding failed");
			goto err;
		}
	}
	if (chain_len == 0) {
		tls_error_setx(error, "empty certificate chain");
		goto err;
	}

	keypair->chain = chain;
	keypair->chain_len = chain_len;
	chain = NULL;

	rv = 0;

 err:
	free(chain);
	free(ctx.buf);

	return rv;
}

int
tls_keypair_set_key_file(struct tls_keypair *keypair, struct tls_error *error,
    const char *key_file)
{
	char *key = NULL;
	size_t len = 0;
	int rv = -1;

	if (tls_config_load_file(error, "key", key_file, &key, &len) == -1)
		goto err;

	if (tls_keypair_set_key_mem(keypair, error, (uint8_t *)key, len) != 0)
		goto err;

	rv = 0;

 err:
	freezero(key, len);

	return rv;
}

static void
append_skey(void *ctx, const void *src, size_t len)
{
	br_skey_decoder_push((br_skey_decoder_context *)ctx, src, len);
}

int
tls_keypair_set_key_mem(struct tls_keypair *keypair, struct tls_error *error,
    const uint8_t *key, size_t len)
{
	br_pem_decoder_context pc;
	br_skey_decoder_context kc;
	const char *name;
	size_t pushed;
	unsigned char *data, *ptr;
	size_t data_len;
	int key_type = 0;
	const br_ec_private_key *ec;
	const br_rsa_private_key *rsa;
	int err, in_key = 0;
	int rv = -1;

	tls_keypair_clear_key(keypair);

	br_pem_decoder_init(&pc);
	while (len > 0) {
		pushed = br_pem_decoder_push(&pc, key, len);
		key += pushed;
		len -= pushed;
		switch (br_pem_decoder_event(&pc)) {
		case BR_PEM_BEGIN_OBJ:
			name = br_pem_decoder_name(&pc);
			if (strcmp(name, "RSA PRIVATE KEY") != 0 &&
			    strcmp(name, "EC PRIVATE KEY") != 0 &&
			    strcmp(name, "PRIVATE KEY") != 0) {
				br_pem_decoder_setdest(&pc, NULL, NULL);
				break;
			}
			br_pem_decoder_setdest(&pc, append_skey, &kc);
			br_skey_decoder_init(&kc);
			in_key = 1;
			break;
		case BR_PEM_END_OBJ:
			if (!in_key)
				break;
			in_key = 0;
			if ((err = br_skey_decoder_last_error(&kc)) != 0) {
				tls_error_setx(error,
				    "secret key decoding failed: %s",
				    bearssl_strerror(err));
				goto err;
			}
			key_type = br_skey_decoder_key_type(&kc);
			len = 0;
			break;
		default:
			tls_error_setx(error, "secret key decoding failed");
			goto err;
		}
	}

	switch (key_type) {
	case BR_KEYTYPE_RSA:
		rsa = br_skey_decoder_get_rsa(&kc);
		data_len = rsa->plen + rsa->qlen + rsa->dplen + rsa->dqlen + rsa->iqlen;
		if ((data = malloc(data_len)) == NULL) {
			tls_error_set(error, "RSA secret key");
			goto err;
		}
		keypair->key.rsa = *rsa;

		ptr = data;

		keypair->key.rsa.p = ptr;
		memcpy(ptr, rsa->p, rsa->plen);
		ptr += rsa->plen;

		keypair->key.rsa.q = ptr;
		memcpy(ptr, rsa->q, rsa->qlen);
		ptr += rsa->qlen;

		keypair->key.rsa.dp = ptr;
		memcpy(ptr, rsa->dp, rsa->dplen);
		ptr += rsa->dplen;

		keypair->key.rsa.dq = ptr;
		memcpy(ptr, rsa->dq, rsa->dqlen);
		ptr += rsa->dqlen;

		keypair->key.rsa.iq = ptr;
		memcpy(ptr, rsa->iq, rsa->iqlen);
		break;
	case BR_KEYTYPE_EC:
		ec = br_skey_decoder_get_ec(&kc);
		data_len = ec->xlen;
		if ((data = malloc(data_len)) == NULL) {
			tls_error_set(error, "EC secret key");
			goto err;
		}
		keypair->key.ec = *ec;
		keypair->key.ec.x = data;
		memcpy(data, ec->x, ec->xlen);
		break;
	default:
		tls_error_setx(error, "unsupported or missing secret key");
		goto err;
	}

	keypair->key_type = key_type;
	keypair->key_data = data;
	keypair->key_data_len = data_len;

	rv = 0;

 err:
	explicit_bzero(&pc, sizeof(pc));
	explicit_bzero(&kc, sizeof(kc));

	return rv;
}

int
tls_keypair_set_ocsp_staple_file(struct tls_keypair *keypair,
    struct tls_error *error, const char *ocsp_file)
{
	tls_error_setx(error, "OCSP stapling is not supported");
	return (-1);
}

int
tls_keypair_set_ocsp_staple_mem(struct tls_keypair *keypair,
    struct tls_error *error, const uint8_t *staple, size_t len)
{
	tls_error_setx(error, "OCSP stapling is not supported");
	return (-1);
}

int
tls_keypair_check(struct tls_keypair *keypair, struct tls_error *error)
{
	br_x509_decoder_context xc;
	br_x509_certificate *cert;
	br_x509_pkey *pkey;
	br_ec_public_key ec_pkey;
	const br_ec_impl *ec;
	br_rsa_compute_modulus compute_modulus;
	unsigned char n[512]; /* 4096 bits */
	size_t nlen;
	unsigned char kbuf[BR_EC_KBUF_PUB_MAX_SIZE];
	int rv = -1, ret;

	if (keypair->key_type == 0) {
		tls_error_setx(error, "incomplete key pair; missing private key");
		return -1;
	}
	if (keypair->chain_len == 0) {
		tls_error_setx(error, "incomplete key pair; missing certificate chain");
		return -1;
	}

	cert = &keypair->chain[0];
	br_x509_decoder_init(&xc, NULL, NULL);
	br_x509_decoder_push(&xc, cert->data, cert->data_len);
	if ((ret = br_x509_decoder_last_error(&xc)) != 0) {
		tls_error_setx(error, "%s", bearssl_strerror(ret));
		return -1;
	}

	pkey = br_x509_decoder_get_pkey(&xc);
	if (pkey->key_type != keypair->key_type)
		goto err;

	switch (keypair->key_type) {
	case BR_KEYTYPE_RSA:
		compute_modulus = br_rsa_compute_modulus_get_default();
		nlen = compute_modulus(NULL, &keypair->key.rsa);
		if (nlen == 0 || nlen > sizeof(n))
			goto err;
		compute_modulus(n, &keypair->key.rsa);
		if (nlen != pkey->key.rsa.nlen ||
		    memcmp(pkey->key.rsa.n, n, nlen) != 0)
			goto err;
		break;
	case BR_KEYTYPE_EC:
		ec = br_ec_get_default();
		if (br_ec_compute_pub(ec, &ec_pkey, kbuf, &keypair->key.ec) == 0)
			goto err;
		if (pkey->key.ec.curve != ec_pkey.curve ||
		    pkey->key.ec.qlen != ec_pkey.qlen ||
		    memcmp(pkey->key.ec.q, ec_pkey.q, ec_pkey.qlen) != 0)
			goto err;
		break;
	default:
		goto err;
	}

	return (0);

 err:
	tls_error_setx(error, "private/public key mismatch");
	return (rv);
}

void
tls_keypair_free(struct tls_keypair *keypair)
{
	size_t i;

	if (keypair == NULL)
		return;

	tls_keypair_clear_key(keypair);

	for (i = 0; i < keypair->chain_len; ++i)
		free(keypair->chain[i].data);
	free(keypair->chain);

	free(keypair);
}
