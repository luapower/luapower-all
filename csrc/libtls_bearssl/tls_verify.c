/* $OpenBSD: tls_verify.c,v 1.20 2018/02/05 00:52:24 jsing Exp $ */
/*
 * Copyright (c) 2014 Jeremie Courreges-Anglas <jca@openbsd.org>
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

#include <tls.h>
#include "tls_internal.h"

int
tls_check_name(struct tls *ctx, br_x509_certificate *cert, const char *name, int *match)
{
	br_x509_minimal_context xc;
	unsigned err;

	br_x509_minimal_init_full(&xc, NULL, 0);
	xc.vtable->start_chain(&xc.vtable, name);
	xc.vtable->start_cert(&xc.vtable, cert->data_len);
	xc.vtable->append(&xc.vtable, cert->data, cert->data_len);
	xc.vtable->end_cert(&xc.vtable);

	switch ((err = xc.vtable->end_chain(&xc.vtable))) {
	case BR_ERR_OK:
	case BR_ERR_X509_NOT_TRUSTED:
		*match = 1;
		break;
	case BR_ERR_X509_BAD_SERVER_NAME:
		*match = 0;
		break;
	default:
		tls_set_errorx(ctx, "certificate name match: %s",
		    bearssl_strerror(err));
		return -1;
	}

	return 0;
}
