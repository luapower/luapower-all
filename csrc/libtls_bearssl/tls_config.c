/* $OpenBSD: tls_config.c,v 1.58 2020/01/20 08:39:21 jsing Exp $ */
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

#ifdef _MSC_VER
#define NO_REDEF_POSIX_FUNCTIONS
#endif

#include <sys/stat.h>

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <strings.h>
#include <time.h>
#include <unistd.h>

#include <tls.h>

#include "tls_internal.h"

static const char default_ca_file[] = TLS_DEFAULT_CA_FILE;

const char *
tls_default_ca_cert_file(void)
{
	return default_ca_file;
}

int
tls_config_load_file(struct tls_error *error, const char *filetype,
    const char *filename, char **buf, size_t *len)
{
	struct stat st;
	int fd = -1;
	ssize_t n;

	free(*buf);
	*buf = NULL;
	*len = 0;

	if ((fd = open(filename, O_RDONLY)) == -1) {
		tls_error_set(error, "failed to open %s file '%s'",
		    filetype, filename);
		goto err;
	}
	if (fstat(fd, &st) != 0) {
		tls_error_set(error, "failed to stat %s file '%s'",
		    filetype, filename);
		goto err;
	}
	if (st.st_size < 0)
		goto err;
	*len = (size_t)st.st_size;
	if ((*buf = malloc(*len)) == NULL) {
		tls_error_set(error, "failed to allocate buffer for "
		    "%s file", filetype);
		goto err;
	}
	n = read(fd, *buf, *len);
	if (n < 0 || (size_t)n != *len) {
		tls_error_set(error, "failed to read %s file '%s'",
		    filetype, filename);
		goto err;
	}
	close(fd);
	return 0;

 err:
	if (fd != -1)
		close(fd);
	freezero(*buf, *len);
	*buf = NULL;
	*len = 0;

	return -1;
}

struct tls_config *
tls_config_new_internal(void)
{
	struct tls_config *config;

	if ((config = calloc(1, sizeof(*config))) == NULL)
		return (NULL);

	if (pthread_mutex_init(&config->mutex, NULL) != 0)
		goto err;

	config->refcount = 1;

	if ((config->keypair = tls_keypair_new()) == NULL)
		goto err;

	/*
	 * Default configuration.
	 */
	if (tls_config_set_dheparams(config, "none") != 0)
		goto err;
	config->ec = *br_ec_get_default();
	if (tls_config_set_ecdhecurves(config, "default") != 0)
		goto err;
	if (tls_config_set_ciphers(config, "secure") != 0)
		goto err;

	if (tls_config_set_protocols(config, TLS_PROTOCOLS_DEFAULT) != 0)
		goto err;
	if (tls_config_set_verify_depth(config, 6) != 0)
		goto err;

	tls_config_prefer_ciphers_server(config);

	tls_config_verify(config);

	return (config);

 err:
	tls_config_free(config);
	return (NULL);
}

struct tls_config *
tls_config_new(void)
{
	if (tls_init() == -1)
		return (NULL);

	return tls_config_new_internal();
}

void
tls_config_free(struct tls_config *config)
{
	struct tls_keypair *kp, *nkp;
	int refcount;
	size_t i;

	if (config == NULL)
		return;

	pthread_mutex_lock(&config->mutex);
	refcount = --config->refcount;
	pthread_mutex_unlock(&config->mutex);

	if (refcount > 0)
		return;

	for (kp = config->keypair; kp != NULL; kp = nkp) {
		nkp = kp->next;
		tls_keypair_free(kp);
	}

	free(config->error.msg);

	if (config->alpn_len > 0)
		free((char *)config->alpn[0]);
	free(config->alpn);
	for (i = 0; i < config->ca_len; ++i)
		free(config->ca[i].dn.data);
	free(config->ca);
	free((uint16_t *)config->suites);

	free(config);
}

static void
tls_config_keypair_add(struct tls_config *config, struct tls_keypair *keypair)
{
	struct tls_keypair *kp;

	kp = config->keypair;
	while (kp->next != NULL)
		kp = kp->next;

	kp->next = keypair;
}

const char *
tls_config_error(struct tls_config *config)
{
	return config->error.msg;
}

void
tls_config_clear_keys(struct tls_config *config)
{
	struct tls_keypair *kp;

	for (kp = config->keypair; kp != NULL; kp = kp->next)
		tls_keypair_clear_key(kp);
}

int
tls_config_parse_protocols(uint32_t *protocols, const char *protostr)
{
	uint32_t proto, protos = 0;
	char *s, *p, *q;
	int negate;

	if (protostr == NULL) {
		*protocols = TLS_PROTOCOLS_DEFAULT;
		return (0);
	}

	if ((s = strdup(protostr)) == NULL)
		return (-1);

	q = s;
	while ((p = strsep(&q, ",:")) != NULL) {
		while (*p == ' ' || *p == '\t')
			p++;

		negate = 0;
		if (*p == '!') {
			negate = 1;
			p++;
		}

		if (negate && protos == 0)
			protos = TLS_PROTOCOLS_ALL;

		proto = 0;
		if (strcasecmp(p, "all") == 0 ||
		    strcasecmp(p, "legacy") == 0)
			proto = TLS_PROTOCOLS_ALL;
		else if (strcasecmp(p, "default") == 0 ||
		    strcasecmp(p, "secure") == 0)
			proto = TLS_PROTOCOLS_DEFAULT;
		if (strcasecmp(p, "tlsv1") == 0)
			proto = TLS_PROTOCOL_TLSv1;
		else if (strcasecmp(p, "tlsv1.0") == 0)
			proto = TLS_PROTOCOL_TLSv1_0;
		else if (strcasecmp(p, "tlsv1.1") == 0)
			proto = TLS_PROTOCOL_TLSv1_1;
		else if (strcasecmp(p, "tlsv1.2") == 0)
			proto = TLS_PROTOCOL_TLSv1_2;
		else if (strcasecmp(p, "tlsv1.3") == 0)
			proto = TLS_PROTOCOL_TLSv1_3;

		if (proto == 0) {
			free(s);
			return (-1);
		}

		if (negate)
			protos &= ~proto;
		else
			protos |= proto;
	}

	*protocols = protos;

	free(s);

	return (0);
}

static int
tls_config_parse_alpn(struct tls_config *config, const char *alpn,
    const char ***alpn_data, size_t *alpn_len)
{
	size_t names_len, i, len;
	const char **names = NULL;
	char *s = NULL;
	char *p, *q;

	free(*alpn_data);
	*alpn_data = NULL;
	*alpn_len = 0;

	if ((s = strdup(alpn)) == NULL) {
		tls_config_set_errorx(config, "out of memory");
		goto err;
	}

	names_len = 0;
	for (p = s; *p; ++p) {
		if (*p == ',')
			++names_len;
	}
	if ((names = reallocarray(NULL, names_len, sizeof(names[0]))) == NULL) {
		tls_config_set_errorx(config, "out of memory");
		goto err;
	}

	i = 0;
	q = s;
	while ((p = strsep(&q, ",")) != NULL) {
		if ((len = strlen(p)) == 0) {
			tls_config_set_errorx(config,
			    "alpn protocol with zero length");
			goto err;
		}
		if (len > 255) {
			tls_config_set_errorx(config,
			    "alpn protocol too long");
			goto err;
		}
		names[i++] = p;
	}

	free(s);

	*alpn_data = names;
	*alpn_len = names_len;

	return (0);

 err:
	free(names);
	free(s);

	return (-1);
}

int
tls_config_set_alpn(struct tls_config *config, const char *alpn)
{
	return tls_config_parse_alpn(config, alpn, &config->alpn,
	    &config->alpn_len);
}

static int
tls_config_add_keypair_file_internal(struct tls_config *config,
    const char *cert_file, const char *key_file, const char *ocsp_file)
{
	struct tls_keypair *keypair;

	if ((keypair = tls_keypair_new()) == NULL)
		return (-1);
	if (tls_keypair_set_cert_file(keypair, &config->error, cert_file) != 0)
		goto err;
	if (tls_keypair_set_key_file(keypair, &config->error, key_file) != 0)
		goto err;
	if (ocsp_file != NULL &&
	    tls_keypair_set_ocsp_staple_file(keypair, &config->error,
		ocsp_file) != 0)
		goto err;

	tls_config_keypair_add(config, keypair);

	return (0);

 err:
	tls_keypair_free(keypair);
	return (-1);
}

static int
tls_config_add_keypair_mem_internal(struct tls_config *config, const uint8_t *cert,
    size_t cert_len, const uint8_t *key, size_t key_len,
    const uint8_t *staple, size_t staple_len)
{
	struct tls_keypair *keypair;

	if ((keypair = tls_keypair_new()) == NULL)
		return (-1);
	if (tls_keypair_set_cert_mem(keypair, &config->error, cert, cert_len) != 0)
		goto err;
	if (tls_keypair_set_key_mem(keypair, &config->error, key, key_len) != 0)
		goto err;
	if (staple != NULL &&
	    tls_keypair_set_ocsp_staple_mem(keypair, &config->error, staple,
		staple_len) != 0)
		goto err;
	if (tls_keypair_check(keypair, &config->error) != 0)
		goto err;

	tls_config_keypair_add(config, keypair);

	return (0);

 err:
	tls_keypair_free(keypair);
	return (-1);
}

int
tls_config_add_keypair_mem(struct tls_config *config, const uint8_t *cert,
    size_t cert_len, const uint8_t *key, size_t key_len)
{
	return tls_config_add_keypair_mem_internal(config, cert, cert_len, key,
	    key_len, NULL, 0);
}

int
tls_config_add_keypair_file(struct tls_config *config,
    const char *cert_file, const char *key_file)
{
	return tls_config_add_keypair_file_internal(config, cert_file,
	    key_file, NULL);
}

int
tls_config_add_keypair_ocsp_mem(struct tls_config *config, const uint8_t *cert,
    size_t cert_len, const uint8_t *key, size_t key_len, const uint8_t *staple,
    size_t staple_len)
{
	return tls_config_add_keypair_mem_internal(config, cert, cert_len, key,
	    key_len, staple, staple_len);
}

int
tls_config_add_keypair_ocsp_file(struct tls_config *config,
    const char *cert_file, const char *key_file, const char *ocsp_file)
{
	return tls_config_add_keypair_file_internal(config, cert_file,
	    key_file, ocsp_file);
}

int
tls_config_set_ca_file(struct tls_config *config, const char *ca_file)
{
	char *ca_mem = NULL;
	size_t ca_len;
	int rv;

	if ((rv = tls_config_load_file(&config->error, "CA", ca_file,
	    &ca_mem, &ca_len)) != 0)
		return -1;

	rv = tls_config_set_ca_mem(config, (uint8_t *)ca_mem, ca_len);
	free(ca_mem);

	return rv;
}

int
tls_config_set_ca_path(struct tls_config *config, const char *ca_path)
{
	return -1;
}

int
tls_config_set_ca_mem(struct tls_config *config, const uint8_t *ca, size_t len)
{
	return bearssl_load_ca(&config->error, ca, len, &config->ca,
	    &config->ca_len);
}

int
tls_config_set_cert_file(struct tls_config *config, const char *cert_file)
{
	return tls_keypair_set_cert_file(config->keypair, &config->error,
	    cert_file);
}

int
tls_config_set_cert_mem(struct tls_config *config, const uint8_t *cert,
    size_t len)
{
	return tls_keypair_set_cert_mem(config->keypair, &config->error,
	    cert, len);
}

int
tls_config_set_ciphers(struct tls_config *config, const char *ciphers)
{
	int rv = -1;

	if (ciphers == NULL ||
	    strcasecmp(ciphers, "default") == 0 ||
	    strcasecmp(ciphers, "secure") == 0)
		ciphers = TLS_CIPHERS_DEFAULT;
	else if (strcasecmp(ciphers, "compat") == 0)
		ciphers = TLS_CIPHERS_COMPAT;
	else if (strcasecmp(ciphers, "legacy") == 0)
		ciphers = TLS_CIPHERS_LEGACY;
	else if (strcasecmp(ciphers, "all") == 0 ||
	    strcasecmp(ciphers, "insecure") == 0)
		ciphers = TLS_CIPHERS_ALL;

	if (bearssl_parse_ciphers(ciphers, (uint16_t **)&config->suites,
	    &config->suites_len) != 0) {
		tls_config_set_errorx(config, "failed to parse cipher list");
		goto err;
	}

	rv = 0;

 err:
	return rv;
}

int
tls_config_set_crl_file(struct tls_config *config, const char *crl_file)
{
	/* XXX: not supported by BearSSL */
	return -1;
}

int
tls_config_set_crl_mem(struct tls_config *config, const uint8_t *crl,
    size_t len)
{
	/* XXX: not supported by BearSSL */
	return -1;
}

int
tls_config_set_dheparams(struct tls_config *config, const char *params)
{
	int keylen;

	if (params == NULL || strcasecmp(params, "none") == 0)
		keylen = 0;
	else if (strcasecmp(params, "auto") == 0)
		keylen = -1;
	else if (strcasecmp(params, "legacy") == 0)
		keylen = 1024;
	else {
		tls_config_set_errorx(config, "invalid dhe param '%s'", params);
		return (-1);
	}

	config->dheparams = keylen;

	return (0);
}

int
tls_config_set_ecdhecurve(struct tls_config *config, const char *curve)
{
	if (curve == NULL ||
	    strcasecmp(curve, "none") == 0 ||
	    strcasecmp(curve, "auto") == 0) {
		curve = TLS_ECDHE_CURVES;
	} else if (strchr(curve, ',') != NULL || strchr(curve, ':') != NULL) {
		tls_config_set_errorx(config, "invalid ecdhe curve '%s'",
		    curve);
		return (-1);
	}

	return tls_config_set_ecdhecurves(config, curve);
}

int
tls_config_set_ecdhecurves(struct tls_config *config, const char *curve_names)
{
	/* BearSSL presents supported curves in a fixed order, so
	 * ECDHE curves set in the config must be a subsequence of the
	 * following sequence. */
	static const struct {
		char name[8];
		int id;
	} curves[] = {
		{"X25519", BR_EC_curve25519},
		{"P-256", BR_EC_secp256r1},
		{"P-384", BR_EC_secp384r1},
		{"P-521", BR_EC_secp521r1},
	};
	uint32_t supported_curves = 0;
	char *cs = NULL;
	char *p, *q;
	size_t i, j;
	int rv = -1;

	if (curve_names == NULL || strcasecmp(curve_names, "default") == 0)
		curve_names = TLS_ECDHE_CURVES;

	if ((cs = strdup(curve_names)) == NULL) {
		tls_config_set_errorx(config, "out of memory");
		goto err;
	}

	q = cs;
	i = 0;
next:
	while ((p = strsep(&q, ",:")) != NULL) {
		while (*p == ' ' || *p == '\t')
			p++;

		for (j = 0; j < sizeof(curves) / sizeof(curves[0]); ++j) {
			if (strcmp(p, curves[j].name) == 0) {
				if (j < i) {
					tls_config_set_errorx(config,
					    "unsupported ecdhe curve order");
					goto err;
				}
				supported_curves |= 1 << curves[j].id;
				i = j;
				goto next;
			}
		}
		tls_config_set_errorx(config,
		    "invalid ecdhe curve '%s'", p);
		goto err;
	}

	config->ec.supported_curves = supported_curves;

	rv = 0;

 err:
	free(cs);

	return (rv);
}

int
tls_config_set_key_file(struct tls_config *config, const char *key_file)
{
	return tls_keypair_set_key_file(config->keypair, &config->error,
	    key_file);
}

int
tls_config_set_key_mem(struct tls_config *config, const uint8_t *key,
    size_t len)
{
	return tls_keypair_set_key_mem(config->keypair, &config->error,
	    key, len);
}

static int
tls_config_set_keypair_file_internal(struct tls_config *config,
    const char *cert_file, const char *key_file, const char *ocsp_file)
{
	if (tls_config_set_cert_file(config, cert_file) != 0)
		return (-1);
	if (tls_config_set_key_file(config, key_file) != 0)
		return (-1);
	if (ocsp_file != NULL &&
	    tls_config_set_ocsp_staple_file(config, ocsp_file) != 0)
		return (-1);

	return (0);
}

static int
tls_config_set_keypair_mem_internal(struct tls_config *config, const uint8_t *cert,
    size_t cert_len, const uint8_t *key, size_t key_len,
    const uint8_t *staple, size_t staple_len)
{
	if (tls_config_set_cert_mem(config, cert, cert_len) != 0)
		return (-1);
	if (tls_config_set_key_mem(config, key, key_len) != 0)
		return (-1);
	if ((staple != NULL) &&
	    (tls_config_set_ocsp_staple_mem(config, staple, staple_len) != 0))
		return (-1);

	return (0);
}

int
tls_config_set_keypair_file(struct tls_config *config,
    const char *cert_file, const char *key_file)
{
	return tls_config_set_keypair_file_internal(config, cert_file, key_file,
	    NULL);
}

int
tls_config_set_keypair_mem(struct tls_config *config, const uint8_t *cert,
    size_t cert_len, const uint8_t *key, size_t key_len)
{
	return tls_config_set_keypair_mem_internal(config, cert, cert_len,
	    key, key_len, NULL, 0);
}

int
tls_config_set_keypair_ocsp_file(struct tls_config *config,
    const char *cert_file, const char *key_file, const char *ocsp_file)
{
	return tls_config_set_keypair_file_internal(config, cert_file, key_file,
	    ocsp_file);
}

int
tls_config_set_keypair_ocsp_mem(struct tls_config *config, const uint8_t *cert,
    size_t cert_len, const uint8_t *key, size_t key_len,
    const uint8_t *staple, size_t staple_len)
{
	return tls_config_set_keypair_mem_internal(config, cert, cert_len,
	    key, key_len, staple, staple_len);
}


int
tls_config_set_protocols(struct tls_config *config, uint32_t protocols)
{
	config->protocols = protocols;

	return (0);
}

int
tls_config_set_session_fd(struct tls_config *config, int session_fd)
{
	tls_config_set_error(config, "sessions are not supported");

	return (-1);
}

int
tls_config_set_verify_depth(struct tls_config *config, int verify_depth)
{
	config->verify_depth = verify_depth;

	return (0);
}

void
tls_config_prefer_ciphers_client(struct tls_config *config)
{
	config->ciphers_server = 0;
}

void
tls_config_prefer_ciphers_server(struct tls_config *config)
{
	config->ciphers_server = 1;
}

void
tls_config_insecure_noverifycert(struct tls_config *config)
{
	config->verify_cert = 0;
}

void
tls_config_insecure_noverifyname(struct tls_config *config)
{
	config->verify_name = 0;
}

void
tls_config_insecure_noverifytime(struct tls_config *config)
{
	config->verify_time = 0;
}

void
tls_config_verify(struct tls_config *config)
{
	config->verify_cert = 1;
	config->verify_name = 1;
	config->verify_time = 1;
}

void
tls_config_ocsp_require_stapling(struct tls_config *config)
{
	config->ocsp_require_stapling = 1;
}

void
tls_config_verify_client(struct tls_config *config)
{
	config->verify_client = 1;
}

void
tls_config_verify_client_optional(struct tls_config *config)
{
	config->verify_client = 2;
}

int
tls_config_set_ocsp_staple_file(struct tls_config *config, const char *staple_file)
{
	return tls_keypair_set_ocsp_staple_file(config->keypair, &config->error,
	    staple_file);
}

int
tls_config_set_ocsp_staple_mem(struct tls_config *config, const uint8_t *staple,
    size_t len)
{
	return tls_keypair_set_ocsp_staple_mem(config->keypair, &config->error,
	    staple, len);
}

int
tls_config_set_session_id(struct tls_config *config,
    const unsigned char *session_id, size_t len)
{
	tls_config_set_errorx(config, "session resumption is not supported");
	return (-1);
}

int
tls_config_set_session_lifetime(struct tls_config *config, int lifetime)
{
	if (lifetime != 0) {
		tls_config_set_errorx(config,
		    "session resumption is not supported");
		return (-1);
	}

	return (0);
}

int
tls_config_add_ticket_key(struct tls_config *config, uint32_t keyrev,
    unsigned char *key, size_t keylen)
{
	tls_config_set_errorx(config, "session resumption is not supported");
	return (-1);
}
