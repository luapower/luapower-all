
// turn lj_char macros into functions so they can be bound and used from Lua.

#include "lj_char.h"

int lj_str_iscntrl(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_CNTRL); }
int lj_str_isspace(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_SPACE); }
int lj_str_ispunct(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_PUNCT); }
int lj_str_isdigit(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_DIGIT); }
int lj_str_isxdigit(int32_t c) { return lj_char_isa(c, LJ_CHAR_XDIGIT); }
int lj_str_isupper(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_UPPER); }
int lj_str_islower(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_LOWER); }
int lj_str_isident(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_IDENT); }
int lj_str_isalpha(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_ALPHA); }
int lj_str_isalnum(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_ALNUM); }
int lj_str_isgraph(int32_t c)	 { return lj_char_isa(c, LJ_CHAR_GRAPH); }

int lj_str_toupper(int32_t c)	{ return c - (lj_char_islower(c) >> 1); }
int lj_str_tolower(int32_t c)	{ return c + lj_char_isupper(c); }

