/* $OpenBSD: tls_bio_cb.c,v 1.19 2017/01/12 16:18:39 jsing Exp $ */
/*
 * Copyright (c) 2016 Tobias Pape <tobias@netshed.de>
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

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include <tls.h>
#include "tls_internal.h"

ssize_t
tls_fd_read_cb(struct tls *ctx, void *buf, size_t buflen, void *cb_arg)
{
	ssize_t rv;

	rv = read(ctx->fd_read, buf, buflen);
	if (rv < 0 && errno == EAGAIN)
		return TLS_WANT_POLLIN;
	return rv;
}

ssize_t
tls_fd_write_cb(struct tls *ctx, const void *buf, size_t buflen, void *cb_arg)
{
	ssize_t rv;

	rv = write(ctx->fd_write, buf, buflen);
	if (rv < 0 && errno == EAGAIN)
		return TLS_WANT_POLLOUT;
	return rv;
}

int
tls_set_cbs(struct tls *ctx, tls_read_cb read_cb, tls_write_cb write_cb,
    void *cb_arg)
{
	int rv = -1;

	if (read_cb == NULL || write_cb == NULL) {
		tls_set_errorx(ctx, "no callbacks provided");
		goto err;
	}

	ctx->read_cb = read_cb;
	ctx->write_cb = write_cb;
	ctx->cb_arg = cb_arg;

	rv = 0;

 err:
	return (rv);
}
