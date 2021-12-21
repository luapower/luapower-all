#ifndef HAVE_STRSEP
#include <string.h>
char *strsep(char **s, const char *delim)
{
	char *begin, *end;
	begin = *s;
	if (!begin) {
		return 0;
	}
	if (delim[0] == '\0' || delim[1] == '\0') {
		char ch = delim[0];
		if (ch == '\0') {
			end = 0;
		} else {
			if (*begin == ch) {
				end = begin;
			} else if (*begin == '\0') {
				end = 0;
			} else {
				end = strchr(begin + 1, ch);
			}
		}
	} else {
		end = strpbrk(begin, delim);
	}
	if (end) {
		*end++ = '\0';
		*s = end;
	}
	else {
		*s = 0;
	}
	return begin;
}
#endif
