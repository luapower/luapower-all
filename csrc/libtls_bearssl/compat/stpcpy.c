#ifndef HAVE_STPCPY
#include <string.h>
char* stpcpy(char *dst, const char *src)
{
	const size_t len = strlen(src);
	return (char*)memcpy(dst, src, len + 1) + len;
}
#endif
