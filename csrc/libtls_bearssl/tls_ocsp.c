/*	$OpenBSD: tls_ocsp.c,v 1.19 2019/12/03 14:56:42 tb Exp $ */
/*
 * Copyright (c) 2015 Marko Kreen <markokr@gmail.com>
 * Copyright (c) 2016 Bob Beck <beck@openbsd.org>
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

#include <sys/types.h>

#include <tls.h>
#include "tls_internal.h"

/*
 * Public API
 */

/* Retrieve OCSP URL from peer certificate, if present. */
const char *
tls_peer_ocsp_url(struct tls *ctx)
{
	return NULL;
}

const char *
tls_peer_ocsp_result(struct tls *ctx)
{
	return NULL;
}

int
tls_peer_ocsp_response_status(struct tls *ctx)
{
	return -1;
}

int
tls_peer_ocsp_cert_status(struct tls *ctx)
{
	return -1;
}

int
tls_peer_ocsp_crl_reason(struct tls *ctx)
{
	return -1;
}

time_t
tls_peer_ocsp_this_update(struct tls *ctx)
{
	return -1;
}

time_t
tls_peer_ocsp_next_update(struct tls *ctx)
{
	return -1;
}

time_t
tls_peer_ocsp_revocation_time(struct tls *ctx)
{
	return -1;
}

int
tls_ocsp_process_response(struct tls *ctx, const unsigned char *response,
    size_t size)
{
	return -1;
}
