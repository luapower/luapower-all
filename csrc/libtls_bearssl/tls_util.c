/* $OpenBSD: tls_util.c,v 1.14 2019/04/13 18:47:58 tb Exp $ */
/*
 * Copyright (c) 2014 Joel Sing <jsing@openbsd.org>
 * Copyright (c) 2014 Ted Unangst <tedu@openbsd.org>
 * Copyright (c) 2015 Reyk Floeter <reyk@openbsd.org>
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

#include <sys/stat.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#include "tls.h"
#include "tls_internal.h"

/*
 * Extract the host and port from a colon separated value. For a literal IPv6
 * address the address must be contained with square braces. If a host and
 * port are successfully extracted, the function will return 0 and the
 * caller is responsible for freeing the host and port. If no port is found
 * then the function will return 1, with both host and port being NULL.
 * On memory allocation failure -1 will be returned.
 */
int
tls_host_port(const char *hostport, char **host, char **port)
{
	char *h, *p, *s;
	int rv = 1;

	*host = NULL;
	*port = NULL;

	if ((s = strdup(hostport)) == NULL)
		goto err;

	h = p = s;

	/* See if this is an IPv6 literal with square braces. */
	if (p[0] == '[') {
		h++;
		if ((p = strchr(s, ']')) == NULL)
			goto done;
		*p++ = '\0';
	}

	/* Find the port seperator. */
	if ((p = strchr(p, ':')) == NULL)
		goto done;

	/* If there is another separator then we have issues. */
	if (strchr(p + 1, ':') != NULL)
		goto done;

	*p++ = '\0';

	if ((*host = strdup(h)) == NULL)
		goto err;
	if ((*port = strdup(p)) == NULL)
		goto err;

	rv = 0;
	goto done;

 err:
	free(*host);
	*host = NULL;
	free(*port);
	*port = NULL;
	rv = -1;

 done:
	free(s);

	return (rv);
}

uint8_t *
tls_load_file(const char *name, size_t *len, char *password)
{
	uint8_t *buf = NULL;
	struct stat st;
	size_t size = 0;
	int fd = -1;
	ssize_t n;

	*len = 0;

	/* secret key decryption not supported by BearSSL */
	if (password != NULL)
		return (NULL);

	if ((fd = open(name, O_RDONLY)) == -1)
		return (NULL);

	/* Just load the file into memory without decryption */
	if (fstat(fd, &st) != 0)
		goto err;
	if (st.st_size < 0)
		goto err;
	size = (size_t)st.st_size;
	if ((buf = malloc(size)) == NULL)
		goto err;
	n = read(fd, buf, size);
	if (n < 0 || (size_t)n != size)
		goto err;
	close(fd);

	*len = size;
	return (buf);

 err:
	if (fd != -1)
		close(fd);
	freezero(buf, size);

	return (NULL);
}

void
tls_unload_file(uint8_t *buf, size_t len)
{
	freezero(buf, len);
}
