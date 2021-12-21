#include <stdlib.h>

#include <bearssl.h>

#include <tls.h>
#include "tls_internal.h"

#define LEN(a) (sizeof(a) / sizeof((a)[0]))

const char *
bearssl_strerror(int err)
{
	static const struct {
		int err;
		const char *str;
	} errors[] = {
		{BR_ERR_BAD_PARAM, "caller-provided parameter is incorrect"},
		{BR_ERR_BAD_STATE, "operation requested by the caller cannot be applied with the current context state"},
		{BR_ERR_UNSUPPORTED_VERSION, "incoming protocol or record version is unsupported"},
		{BR_ERR_BAD_VERSION, "incoming record version does not match the expected version"},
		{BR_ERR_BAD_LENGTH, "incoming record length is invalid"},
		{BR_ERR_TOO_LARGE, "incoming record is too large to be processed, or buffer is too small for the handshake message to send"},
		{BR_ERR_BAD_MAC, "decryption found an invalid padding, or the record MAC is not correct"},
		{BR_ERR_NO_RANDOM, "no initial entropy was provided, and none can be obtained from the OS"},
		{BR_ERR_UNKNOWN_TYPE, "incoming record type is unknown"},
		{BR_ERR_UNEXPECTED, "incoming record or message has wrong type with regards to the current engine state"},
		{BR_ERR_BAD_CCS, "ChangeCipherSpec message from the peer has invalid contents"},
		{BR_ERR_BAD_ALERT, "alert message from the peer has invalid contents (odd length)"},
		{BR_ERR_BAD_HANDSHAKE, "incoming handshake message decoding failed"},
		{BR_ERR_OVERSIZED_ID, "ServerHello contains a session ID which is larger than 32 bytes"},
		{BR_ERR_BAD_CIPHER_SUITE, "server wants to use a cipher suite that we did not claim to support"},
		{BR_ERR_BAD_COMPRESSION, "server wants to use a compression that we did not claim to support"},
		{BR_ERR_BAD_FRAGLEN, "server's max fragment length does not match client's"},
		{BR_ERR_BAD_SECRENEG, "secure renegotiation failed"},
		{BR_ERR_EXTRA_EXTENSION, "server sent an extension type that we did not announce, or used the same extension type several times in a single ServerHello"},
		{BR_ERR_BAD_SNI, "invalid Server Name Indication contents"},
		{BR_ERR_BAD_HELLO_DONE, "invalid ServerHelloDone from the server (length is not 0)"},
		{BR_ERR_LIMIT_EXCEEDED, "internal limit exceeded"},
		{BR_ERR_BAD_FINISHED, "finished message from peer does not match the expected value"},
		{BR_ERR_RESUME_MISMATCH, "session resumption attempt with distinct version or cipher suite"},
		{BR_ERR_INVALID_ALGORITHM, "unsupported or invalid algorithm"},
		{BR_ERR_BAD_SIGNATURE, "invalid signature"},
		{BR_ERR_WRONG_KEY_USAGE, "peer's public key does not have the proper type or is not allowed for requested operation"},
		{BR_ERR_NO_CLIENT_AUTH, "client did not send a certificate upon request, or the client certificate could not be validated"},
		{BR_ERR_IO, "I/O error or premature close on underlying transport stream"},

		{BR_ERR_X509_INVALID_VALUE, "X.509: invalid value in an ASN.1 structure"},
		{BR_ERR_X509_TRUNCATED, "X.509: truncated certificate"},
		{BR_ERR_X509_EMPTY_CHAIN, "X.509: empty certificate chain (no certificate at all)"},
		{BR_ERR_X509_INNER_TRUNC, "X.509: decoding error: inner element extends beyond outer element size"},
		{BR_ERR_X509_BAD_TAG_CLASS, "X.509: decoding error: unsupported tag class (application or private)"},
		{BR_ERR_X509_BAD_TAG_VALUE, "X.509: decoding error: unsupported tag value"},
		{BR_ERR_X509_INDEFINITE_LENGTH, "X.509: decoding error: indefinite length"},
		{BR_ERR_X509_EXTRA_ELEMENT, "X.509: decoding error: extraneous element"},
		{BR_ERR_X509_UNEXPECTED, "X.509: decoding error: unexpected element"},
		{BR_ERR_X509_NOT_CONSTRUCTED, "X.509: decoding error: expected constructed element, but is primitive"},
		{BR_ERR_X509_NOT_PRIMITIVE, "X.509: decoding error: expected primitive element, but is constructed"},
		{BR_ERR_X509_PARTIAL_BYTE, "X.509: decoding error: BIT STRING length is not multiple of 8"},
		{BR_ERR_X509_BAD_BOOLEAN, "X.509: decoding error: BOOLEAN value has invalid length"},
		{BR_ERR_X509_OVERFLOW, "X.509: decoding error: value is off-limits"},
		{BR_ERR_X509_BAD_DN, "X.509: invalid distinguished name"},
		{BR_ERR_X509_BAD_TIME, "X.509: invalid date/time representation"},
		{BR_ERR_X509_UNSUPPORTED, "X.509: certificate contains unsupported features that cannot be ignored"},
		{BR_ERR_X509_LIMIT_EXCEEDED, "X.509: key or signature size exceeds internal limits"},
		{BR_ERR_X509_WRONG_KEY_TYPE, "X.509: key type does not match that which was expected"},
		{BR_ERR_X509_BAD_SIGNATURE, "X.509: signature is invalid"},
		{BR_ERR_X509_TIME_UNKNOWN, "X.509: validation time is unknown"},
		{BR_ERR_X509_EXPIRED, "X.509: certificate is expired or not yet valid"},
		{BR_ERR_X509_DN_MISMATCH, "X.509: issuer/subject DN mismatch in the chain"},
		{BR_ERR_X509_BAD_SERVER_NAME, "X.509: expected server name was not found in the chain"},
		{BR_ERR_X509_CRITICAL_EXTENSION, "X.509: unknown critical extension in certificate"},
		{BR_ERR_X509_NOT_CA, "X.509: not a CA, or path length constraint violation"},
		{BR_ERR_X509_FORBIDDEN_KEY_USAGE, "X.509: Key Usage extension prohibits intended usage"},
		{BR_ERR_X509_WEAK_PUBLIC_KEY, "X.509: public key found in certificate is too small"},
		{BR_ERR_X509_NOT_TRUSTED, "X.509: chain could not be linked to a trust anchor"},
	};
	size_t i;

	for (i = 0; i < LEN(errors); ++i) {
		if (errors[i].err == err)
			return errors[i].str;
	}

	return "unknown error";
}

static int
wordcmp(const void *a, const void *b)
{
	return strcmp(a, b);
}

enum suite_prop {
	/* key exchange */
	kRSA      = 1<<0,
	ECDHE     = 1<<1,

	/* authentication */
	aRSA      = 1<<2,
	ECDSA     = 1<<3,

	/* encryption */
	TRIPLEDES = 1<<4,
	AES128    = 1<<5,
	AES256    = 1<<6,
	AESGCM    = 1<<7,
	AESCCM    = 1<<8,
	AESCCM8   = 1<<9,
	CHACHA20  = 1<<10,

	/* MAC */
	AEAD      = 1<<11,
	SHA1      = 1<<12,
	SHA256    = 1<<13,
	SHA384    = 1<<14,

	/* minimum TLS version */
	TLS10     = 1<<15,
	TLS12     = 1<<16,

	/* strength */
	HIGH      = 1<<17,
	MEDIUM    = 1<<18,
	LOW       = 1<<19,
};

static const struct {
	char name[32];
	uint16_t id;
	enum suite_prop prop;
	int bits;
} suite_info[] = {
	{
		"ECDHE-ECDSA-CHACHA20-POLY1305",
		BR_TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,
		ECDHE|ECDSA|CHACHA20|AEAD|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-RSA-CHACHA20-POLY1305",
		BR_TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,
		ECDHE|aRSA|CHACHA20|AEAD|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-ECDSA-AES128-GCM-SHA256",
		BR_TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
		ECDHE|ECDSA|AES128|AESGCM|AEAD|TLS12|HIGH,
		128,
	},
	{
		"ECDHE-RSA-AES128-GCM-SHA256",
		BR_TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
		ECDHE|aRSA|AES128|AESGCM|AEAD|TLS12|HIGH,
		128,
	},
	{
		"ECDHE-ECDSA-AES256-GCM-SHA384",
		BR_TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
		ECDHE|ECDSA|AES256|AESGCM|AEAD|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-RSA-AES256-GCM-SHA384",
		BR_TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
		ECDHE|aRSA|AES256|AESGCM|AEAD|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-ECDSA-AES128-CCM",
		BR_TLS_ECDHE_ECDSA_WITH_AES_128_CCM,
		ECDHE|ECDSA|AES128|AESCCM|AEAD|TLS12|HIGH,
		128,
	},
	{
		"ECDHE-ECDSA-AES256-CCM",
		BR_TLS_ECDHE_ECDSA_WITH_AES_256_CCM,
		ECDHE|ECDSA|AES256|AESCCM|AEAD|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-ECDSA-AES128-CCM8",
		BR_TLS_ECDHE_ECDSA_WITH_AES_128_CCM_8,
		ECDHE|ECDSA|AES128|AESCCM8|AEAD|TLS12|HIGH,
		128,
	},
	{
		"ECDHE-ECDSA-AES256-CCM8",
		BR_TLS_ECDHE_ECDSA_WITH_AES_256_CCM_8,
		ECDHE|ECDSA|AES256|AESCCM8|AEAD|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-ECDSA-AES128-SHA256",
		BR_TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,
		ECDHE|ECDSA|AES128|SHA256|TLS12|HIGH,
		128,
	},
	{
		"ECDHE-RSA-AES128-SHA256",
		BR_TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,
		ECDHE|aRSA|AES128|SHA256|TLS12|HIGH,
		128,
	},
	{
		"ECDHE-ECDSA-AES256-SHA384",
		BR_TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,
		ECDHE|ECDSA|AES256|SHA384|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-RSA-AES256-SHA384",
		BR_TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,
		ECDHE|aRSA|AES256|SHA384|TLS12|HIGH,
		256,
	},
	{
		"ECDHE-ECDSA-AES128-SHA",
		BR_TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,
		ECDHE|ECDSA|AES128|SHA1|TLS10|HIGH,
		128,
	},
	{
		"ECDHE-RSA-AES128-SHA",
		BR_TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,
		ECDHE|aRSA|AES128|SHA1|TLS10|HIGH,
		128,
	},
	{
		"ECDHE-ECDSA-AES256-SHA",
		BR_TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,
		ECDHE|ECDSA|AES256|SHA1|TLS10|HIGH,
		256,
	},
	{
		"ECDHE-RSA-AES256-SHA",
		BR_TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
		ECDHE|aRSA|AES256|SHA1|TLS10|HIGH,
		256,
	},
	/* ECDH suites, used in BearSSL "full" profile do
	 * not have corresponding OpenSSL
	 */
	{
		"AES128-GCM-SHA256",
		BR_TLS_RSA_WITH_AES_128_GCM_SHA256,
		kRSA|aRSA|AES128|AESGCM|SHA256|TLS12|HIGH,
		128,
	},
	{
		"AES256-GCM-SHA384",
		BR_TLS_RSA_WITH_AES_256_GCM_SHA384,
		kRSA|aRSA|AES256|AESGCM|SHA384|TLS12|HIGH,
		256,
	},
	{
		"AES128-CCM",
		BR_TLS_RSA_WITH_AES_128_CCM,
		kRSA|aRSA|AES128|AESCCM|TLS12|HIGH,
		128,
	},
	{
		"AES256-CCM",
		BR_TLS_RSA_WITH_AES_256_CCM,
		kRSA|aRSA|AES256|AESCCM|TLS12|HIGH,
		256,
	},
	{
		"AES128-CCM8",
		BR_TLS_RSA_WITH_AES_128_CCM_8,
		kRSA|aRSA|AES128|AESCCM8|TLS12|HIGH,
		128,
	},
	{
		"AES256-CCM8",
		BR_TLS_RSA_WITH_AES_256_CCM_8,
		kRSA|aRSA|AES256|AESCCM8|TLS12|HIGH,
		256,
	},
	{
		"AES128-SHA256",
		BR_TLS_RSA_WITH_AES_128_CBC_SHA256,
		kRSA|aRSA|AES128|SHA256|TLS12|HIGH,
		128,
	},
	{
		"AES256-SHA256",
		BR_TLS_RSA_WITH_AES_256_CBC_SHA256,
		kRSA|aRSA|AES256|SHA256|TLS12|HIGH,
		256,
	},
	{
		"AES128-SHA",
		BR_TLS_RSA_WITH_AES_128_CBC_SHA,
		kRSA|aRSA|AES128|SHA1|TLS10|HIGH,
		128,
	},
	{
		"AES256-SHA",
		BR_TLS_RSA_WITH_AES_256_CBC_SHA,
		kRSA|aRSA|AES256|SHA1|TLS10|HIGH,
		256,
	},
	{
		"ECDHE-ECDSA-DES-CBC3-SHA",
		BR_TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA,
		ECDHE|ECDSA|TRIPLEDES|SHA1|TLS10|MEDIUM,
		112,
	},
	{
		"ECDHE-RSA-DES-CBC3-SHA",
		BR_TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA,
		ECDHE|aRSA|TRIPLEDES|SHA1|TLS10|MEDIUM,
		112,
	},
	{
		"DES-CBC3-SHA",
		BR_TLS_RSA_WITH_3DES_EDE_CBC_SHA,
		kRSA|aRSA|TRIPLEDES|SHA1|TLS10|MEDIUM,
		112,
	},
};

struct suite_list {
	uint16_t suite[LEN(suite_info)];
	size_t len;
	uint32_t mask;
};

static int
suite_add(struct suite_list *list, size_t i)
{
	if ((list->mask & 1 << i) != 0)
		return 0;
	list->suite[list->len++] = suite_info[i].id;
	list->mask |= 1 << i;
	return 1;
}

static int
suite_del(struct suite_list *list, size_t i)
{
	size_t j;

	if ((list->mask & 1 << i) == 0)
		return 0;
	for (j = 0; j < list->len; ++j) {
		if (list->suite[j] == suite_info[i].id) {
			list->suite[j] = 0;
			break;
		}
	}
	list->mask &= ~(1 << i);
	return 1;
}

static void
suite_trim(struct suite_list *list)
{
	size_t i, j;

	for (i = 0, j = 0; j < list->len; ++j) {
		if (list->suite[j] == 0)
			continue;
		if (i < j)
			list->suite[i] = list->suite[j];
		++i;
	}
	list->len = i;
}

int
bearssl_parse_ciphers(const char *ciphers, uint16_t **suites, size_t *suites_len)
{
	static const struct {
		char name[20];
		enum suite_prop prop;
	} words[] = {
		/* SSL_CTX_set_cipher_list(3), keep sorted */
		{"3DES", TRIPLEDES},
		{"AEAD", AEAD},
		{"AES", AES128|AES256},
		{"AES128", AES128},
		{"AES256", AES256},
		{"AESCCM", AESCCM},
		{"AESCCM8", AESCCM8},
		{"AESGCM", AESGCM},
		{"ALL", ~0}, /* !eNULL */
		{"CHACHA20", CHACHA20},
		{"COMPLEMENTOFALL", 0}, /* eNULL */
		{"COMPLEMENTOFDEFAULT", 0}, /* aNULL:!eNULL */
		{"DEFAULT", ~0}, /* ALL:!aNULL:!eNULL */
		{"ECDH", ECDHE},
		{"ECDHE", ECDHE},
		{"ECDSA", ECDSA},
		{"EECDH", ECDHE},
		{"HIGH", HIGH},
		{"LOW", LOW},
		{"MEDIUM", MEDIUM},
		{"RSA", kRSA|aRSA},
		{"SHA", SHA1},
		{"SHA1", SHA1},
		{"SHA256", SHA256},
		{"SHA384", SHA384},
		{"SSLv3", TLS10},
		{"TLSv1", TLS10},
		{"TLSv1.2", TLS12},
		{"aECDSA", ECDSA},
		{"aRSA", aRSA},
		{"kEECDH", ECDHE},
		{"kRSA", kRSA},

		/* strings corresponding to an empty list:
		 *
		 * ADH = kEDH+aNULL
		 * aDSS
		 * AECDH = kEECDH+aNULL
		 * aGOST
		 * aGOST01
		 * aNULL
		 * CAMELLIA
		 * CAMELLIA128
		 * CAMELLIA256
		 * DES
		 * DH = kEDH
		 * DHE = kEDH:!aNULL
		 * DSS = aDSS
		 * EDH = DHE
		 * eNULL
		 * GOST89MAC
		 * GOST94
		 * IDEA
		 * kEDH
		 * kGOST
		 * MD5
		 * NULL = eNULL
		 * RC4
		 * STREEBOG256
		 */
	}, *word;
	struct suite_list avail = {0}, unavail = {0};
	uint32_t mask;
	size_t i;
	char *cs = NULL;
	char *p, *q, *r;
	char prefix;
	int rv = -1;

	if ((cs = strdup(ciphers)) == NULL)
		goto err;

	for (i = 0; i < LEN(suite_info); ++i)
		suite_add(&unavail, i);

	q = cs;
	while ((p = strsep(&q, ": ;,")) != NULL) {
		if (strcmp(p, "@STRENGTH") == 0)  /* not yet supported */
			goto err;
		if (p[0] == '!' || p[0] == '-' || p[0] == '+') {
			prefix = p[0];
			++p;
		} else {
			prefix = 0;
		}
		mask = -1;
		while ((r = strsep(&p, "+")) != NULL) {
			for (i = 0; i < LEN(suite_info); ++i) {
				if (strcmp(r, suite_info[i].name) == 0) {
					mask = 1 << i;
					goto update;
				}
			}
			word = bsearch(r, words, LEN(words), sizeof(words[0]), wordcmp);
			if (!word) {
				/* ignore unknown words */
				mask = 0;
				goto update;
			}
			for (i = 0; i < LEN(suite_info); ++i) {
				if (!(suite_info[i].prop & word->prop)) {
					mask &= ~(1 << i);
				}
			}
		}
	update:
		for (i = 0; i < LEN(suite_info); ++i) {
			if ((mask & 1 << i) == 0)
				continue;
			switch (prefix) {
			case 0:
				/* add */
				if (suite_del(&unavail, i))
					suite_add(&avail, i);
				break;
			case '+':
				/* reduce priority */
				if (suite_del(&avail, i))
					suite_add(&avail, i);
				break;
			case '-':
				/* delete */
				if (suite_del(&avail, i))
					suite_add(&unavail, i);
				break;
			case '!':
				/* permanently delete */
				suite_del(&avail, i);
				suite_del(&unavail, i);
				break;
			}
		}
		suite_trim(&avail);
		suite_trim(&unavail);
	}

	if (avail.len == 0)
		goto err;

	if ((*suites = reallocarray(NULL, avail.len, sizeof(avail.suite[0]))) == NULL)
		goto err;
	memcpy(*suites, avail.suite, avail.len * sizeof(avail.suite[0]));
	*suites_len = avail.len;

	rv = 0;

 err:
	free(cs);

	return (rv);
}

const char *
bearssl_suite_name(uint16_t id)
{
	size_t i;

	for (i = 0; i < LEN(suite_info); ++i) {
		if (suite_info[i].id == id)
			return suite_info[i].name;
	}

	return NULL;
}

int
bearssl_suite_bits(uint16_t id)
{
	size_t i;

	for (i = 0; i < LEN(suite_info); ++i) {
		if (suite_info[i].id == id)
			return suite_info[i].bits;
	}

	return 0;
}

struct ca_ctx {
	br_x509_decoder_context xc;
	struct tls_error *error;
	char dn[1024];
	size_t dn_len;
	int in_cert;
};

static void
append_dn(void *ptr, const void *buf, size_t len)
{
	struct ca_ctx *ctx = ptr;

	if (ctx->error->tls || !ctx->in_cert)
		return;
	if (sizeof(ctx->dn) - ctx->dn_len < len) {
		tls_error_setx(ctx->error, "X.509 DN is too long");
		return;
	}
	memcpy(ctx->dn + ctx->dn_len, buf, len);
	ctx->dn_len += len;
}

static void
x509_push(void *ptr, const void *buf, size_t len)
{
	struct ca_ctx *ctx = ptr;

	if (ctx->in_cert)
		br_x509_decoder_push(&ctx->xc, buf, len);
}

int
bearssl_load_ca(struct tls_error *error, const uint8_t *mem, size_t len, br_x509_trust_anchor **ca, size_t *ca_len)
{
	struct ca_ctx ctx;
	br_pem_decoder_context pc;
	br_x509_pkey *pkey;
	br_x509_trust_anchor *anchors = NULL, *new_anchors;
	size_t anchors_len = 0, anchors_cap = 0;
	br_x509_trust_anchor *ta = NULL;
	size_t ta_size;
	const char *name;
	size_t pushed;
	int rv = -1, ret;

	ctx.error = error;
	ctx.dn_len = 0;
	ctx.in_cert = 0;

	br_pem_decoder_init(&pc);
	br_pem_decoder_setdest(&pc, x509_push, &ctx);
	while (len > 0) {
		pushed = br_pem_decoder_push(&pc, mem, len);
		if (ctx.error->tls)
			goto err;
		mem += pushed;
		len -= pushed;
		switch (br_pem_decoder_event(&pc)) {
		case 0:
			break;
		case BR_PEM_BEGIN_OBJ:
			name = br_pem_decoder_name(&pc);
			if (strcmp(name, "CERTIFICATE") != 0 &&
			    strcmp(name, "X509 CERTIFICATE") != 0) {
				break;
			}
			br_x509_decoder_init(&ctx.xc, append_dn, &ctx);
			if (anchors_len == anchors_cap) {
				anchors_cap = anchors_cap ? anchors_cap * 2 : 32;
				if ((new_anchors = reallocarray(anchors, anchors_cap, sizeof(anchors[0]))) == NULL) {
					tls_error_setx(error, "allocate CA list");
					goto err;
				}
				anchors = new_anchors;
			}
			ctx.in_cert = 1;
			ctx.dn_len = 0;
			ta = &anchors[anchors_len++];
			ta->dn.data = NULL;
			break;
		case BR_PEM_END_OBJ:
			if (!ctx.in_cert)
				break;
			ctx.in_cert = 0;
			if ((ret = br_x509_decoder_last_error(&ctx.xc)) != 0) {
				tls_error_setx(error, "certificate decoding failed: %s",
				    bearssl_strerror(ret));
				goto err;
			}
			ta->flags = 0;
			if (br_x509_decoder_isCA(&ctx.xc))
				ta->flags |= BR_X509_TA_CA;
			pkey = br_x509_decoder_get_pkey(&ctx.xc);
			if (!pkey) {
				tls_error_setx(error, "certificate public key");
				goto err;
			}
			ta->pkey = *pkey;

			/* calculate space needed for trust anchor data */
			ta_size = ctx.dn_len;
			switch (pkey->key_type) {
			case BR_KEYTYPE_RSA:
				ta_size += pkey->key.rsa.nlen + pkey->key.rsa.elen;
				break;
			case BR_KEYTYPE_EC:
				ta_size += pkey->key.ec.qlen;
				break;
			default:
				tls_error_setx(error, "unknown public key type");
				goto err;
			}

			/* fill in trust anchor DN and public key data */
			if ((ta->dn.data = malloc(ta_size)) == NULL) {
				tls_error_set(error, "allocate trust anchor");
				goto err;
			}
			memcpy(ta->dn.data, ctx.dn, ctx.dn_len);
			ta->dn.len = ctx.dn_len;
			switch (pkey->key_type) {
			case BR_KEYTYPE_RSA:
				ta->pkey.key.rsa.n = ta->dn.data + ta->dn.len;
				memcpy(ta->pkey.key.rsa.n, pkey->key.rsa.n, pkey->key.rsa.nlen);
				ta->pkey.key.rsa.e = ta->pkey.key.rsa.n + ta->pkey.key.rsa.nlen;
				memcpy(ta->pkey.key.rsa.e, pkey->key.rsa.e, pkey->key.rsa.elen);
				break;
			case BR_KEYTYPE_EC:
				ta->pkey.key.ec.q = ta->dn.data + ta->dn.len;
				memcpy(ta->pkey.key.ec.q, pkey->key.ec.q, pkey->key.ec.qlen);
				break;
			}
			break;
		default:
			tls_error_setx(error, "unknown PEM decoder event");
			goto err;
		}
	}

	*ca = anchors;
	*ca_len = anchors_len;
	anchors = NULL;

	rv = 0;

 err:
	free(anchors);
	return (rv);
}
