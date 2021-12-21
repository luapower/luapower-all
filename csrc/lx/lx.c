/*
** LuaJIT lexer. Cosmin Apreutesei. Public Domain.
** Most code is from LuaJIT. Copyright (C) 2005-2017 Mike Pall. MIT License.
*/

#include "lx.h"

#include <math.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

/* Portability section ---------------------------------------------------- */

#if defined(__GNUC__)
#define LX_LIKELY(x) __builtin_expect(!!(x), 1)
#define LX_UNLIKELY(x) __builtin_expect(!!(x), 0)
#define LX_AINLINE inline __attribute__((always_inline))
#define LX_NOINLINE __attribute__((noinline))
#elif defined(_MSC_VER)
#define LX_LIKELY(x) (x)
#define LX_UNLIKELY(x) (x)
#define LX_AINLINE  __forceinline
#define LX_NOINLINE __declspec(noinline)
#else
#define LX_LIKELY(x) (x)
#define LX_UNLIKELY(x) (x)
#define LX_AINLINE
#define LX_NOINLINE
#endif

#define lx_assert assert

#define LX_MAX_MEM32  0x7fffff00    /* Max. 32 bit memory allocation. */
#define LX_MAX_LINE   LX_MAX_MEM32  /* Max. source code line number. */

/* Character types -------------------------------------------------------- */

/*
** Character types.
** Donated to the public domain.
**
** This is intended to replace the problematic libc single-byte NLS functions.
** These just don't make sense anymore with UTF-8 locales becoming the norm
** on POSIX systems. It never worked too well on Windows systems since hardly
** anyone bothered to call setlocale().
**
** This table is hardcoded for ASCII. Identifiers include the characters
** 128-255, too. This allows for the use of all non-ASCII chars as identifiers
** in the lexer. This is a broad definition, but works well in practice
** for both UTF-8 locales and most single-byte locales (such as ISO-8859-*).
**
** If you really need proper character types for UTF-8 strings, please use
** an add-on library such as slnunicode: http://luaforge.net/projects/sln/
*/

#define LX_CHAR_CNTRL  0x01
#define LX_CHAR_SPACE  0x02
#define LX_CHAR_PUNCT  0x04
#define LX_CHAR_DIGIT  0x08
#define LX_CHAR_XDIGIT 0x10
#define LX_CHAR_UPPER  0x20
#define LX_CHAR_LOWER  0x40
#define LX_CHAR_IDENT  0x80
#define LX_CHAR_ALPHA  (LX_CHAR_LOWER|LX_CHAR_UPPER)
#define LX_CHAR_ALNUM  (LX_CHAR_ALPHA|LX_CHAR_DIGIT)
#define LX_CHAR_GRAPH  (LX_CHAR_ALNUM|LX_CHAR_PUNCT)

/* Only pass -1 or 0..255 to these macros. Never pass a signed char! */
#define lx_char_isa(c, t)      ((lx_char_bits+1)[(c)] & t)
#define lx_char_iscntrl(c)     lx_char_isa((c), LX_CHAR_CNTRL)
#define lx_char_isspace(c)     lx_char_isa((c), LX_CHAR_SPACE)
#define lx_char_ispunct(c)     lx_char_isa((c), LX_CHAR_PUNCT)
#define lx_char_isdigit(c)     lx_char_isa((c), LX_CHAR_DIGIT)
#define lx_char_isxdigit(c)    lx_char_isa((c), LX_CHAR_XDIGIT)
#define lx_char_isupper(c)     lx_char_isa((c), LX_CHAR_UPPER)
#define lx_char_islower(c)     lx_char_isa((c), LX_CHAR_LOWER)
#define lx_char_isident(c)     lx_char_isa((c), LX_CHAR_IDENT)
#define lx_char_isalpha(c)     lx_char_isa((c), LX_CHAR_ALPHA)
#define lx_char_isalnum(c)     lx_char_isa((c), LX_CHAR_ALNUM)
#define lx_char_isgraph(c)     lx_char_isa((c), LX_CHAR_GRAPH)

#define lx_char_toupper(c)     ((c) - (lx_char_islower(c) >> 1))
#define lx_char_tolower(c)     ((c) + lx_char_isupper(c))

static const uint8_t lx_char_bits[257] = {
    0,
    1,  1,  1,  1,  1,  1,  1,  1,  1,  3,  3,  3,  3,  3,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    2,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
  152,152,152,152,152,152,152,152,152,152,  4,  4,  4,  4,  4,  4,
    4,176,176,176,176,176,176,160,160,160,160,160,160,160,160,160,
  160,160,160,160,160,160,160,160,160,160,160,  4,  4,  4,  4,132,
    4,208,208,208,208,208,208,192,192,192,192,192,192,192,192,192,
  192,192,192,192,192,192,192,192,192,192,192,  4,  4,  4,  4,  1,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128
};

/* Number parser, kept in separate file ----------------------------------- */

#include "lx_strscan.c"

/* Token string buffer ---------------------------------------------------- */

typedef struct LX_Buf {
	uint8_t*   data;
	int        len;
	int        capacity;
	int        offset; /* offset of useful string */
} LX_Buf;

#define max(a,b) (((a) < (b)) ? (b) : (a))

static LX_AINLINE void lx_buf_putb(LX_Buf* b, uint8_t c)
{
	if (b->offset + b->len == b->capacity) {
		b->capacity = max(b->capacity, 64) * 2;
		b->data = realloc(b->data, b->capacity);
		assert(b->data);
	}
	b->data[b->offset + b->len++] = c;
}

static LX_AINLINE void lx_buf_reset(LX_Buf* b)
{
	b->offset = 0;
	b->len = 0;
}

static LX_AINLINE void lx_buf_free(LX_Buf* b)
{
	free(b->data);
	memset(b, 0, sizeof(*b));
}

/* Lexer state ------------------------------------------------------------ */

typedef int LX_Char;     /* Lexical character. Unsigned ext. from char. */

struct LX_State {
	int strscan_opt;      /* Current strscan options for number parsing. */
	LX_Value tv;          /* Current token value. */
	const char *p;        /* Current position in input buffer. */
	const char *pe;       /* End of input buffer. */
	LX_Char c;            /* Current character. */
	LX_Token tok;         /* Current token. */
	LX_Buf sb;            /* Buffer for string tokens. */
	LX_Reader read;       /* Reader callback. */
	void *rdata;          /* Reader callback data. */
	int line;             /* Current line. */
	int linepos;          /* Position in current line. */
	int filepos;          /* Position in file. */
	int start_line;       /* Line of current token. */
	int start_linepos;    /* Line offset of current token. */
	int start_filepos;    /* File offset of current token. */
	int err;              /* Current error code */
};

/* -- Buffer handling ----------------------------------------------------- */

#define EOF          (-1)
#define iseol(ls)    (ls->c == '\n' || ls->c == '\r')

/* Get more input from reader. */
static LX_NOINLINE LX_Char more(LX_State *ls)
{
	size_t sz;
	const char *p = ls->read(ls->rdata, &sz);
	if (p == NULL || sz == 0) return EOF;
	ls->pe = p + sz;
	ls->p = p + 1;
	return (LX_Char)(uint8_t)p[0];
}

/* Get next character. */
static LX_AINLINE LX_Char next(LX_State *ls)
{
	ls->linepos++;
	ls->filepos++;
	return (ls->c = (ls->p < ls->pe ? (LX_Char)(uint8_t)*ls->p++ : more(ls)));
}

/* Save character. */
static LX_AINLINE void save(LX_State *ls, LX_Char c)
{
	lx_buf_putb(&ls->sb, c);
}

/* Save previous character and get next character. */
static LX_AINLINE LX_Char savenext(LX_State *ls)
{
	save(ls, ls->c);
	return next(ls);
}

/* Skip line break. Handles "\n", "\r", "\r\n" or "\n\r". */
static int newline(LX_State *ls)
{
	LX_Char old = ls->c;
	lx_assert(iseol(ls));
	next(ls);  /* Skip "\n" or "\r". */
	if (iseol(ls) && ls->c != old) next(ls);  /* Skip "\n\r" or "\r\n". */
	if (++ls->line >= LX_MAX_LINE) {
		ls->err = LX_ERR_XLINES;
		return 1;
	}
	ls->linepos = 1;
	return 0;
}

/* -- Scanner for terminals ----------------------------------------------- */

/* Parse a number literal. */
static LX_Token number(LX_State *ls)
{
	LX_Char c, xp = 'e';
	lx_assert(lx_char_isdigit(ls->c));
	if ((c = ls->c) == '0' && (savenext(ls) | 0x20) == 'x')
		xp = 'p';
	while (lx_char_isident(ls->c) || ls->c == '.' ||
				 ((ls->c == '-' || ls->c == '+') && (c | 0x20) == xp)) {
		c = ls->c;
		savenext(ls);
	}
	save(ls, '\0');

	int fmt = lx_strscan_scan(ls->sb.data, &ls->tv, ls->strscan_opt);
	if (fmt == TK_ERROR)
		ls->err = LX_ERR_XNUMBER;
	return fmt;
}

/* Skip equal signs for "[=...=[" and "]=...=]" and return their count. */
static int skipeq(LX_State *ls)
{
	int count = 0;
	LX_Char s = ls->c;
	lx_assert(s == '[' || s == ']');
	while (savenext(ls) == '=')
		count++;
	return (ls->c == s) ? count : (-count) - 1;
}

/* Parse a long string or long comment. */
static int longstring(LX_State *ls, int sep, int string)
{
	savenext(ls);  /* Skip second '['. */
	if (iseol(ls))  /* Skip initial newline. */
		if (newline(ls)) return 1;
	for (;;) {
		switch (ls->c) {
			case EOF:
				ls->err = string ? LX_ERR_XLSTR : LX_ERR_XLCOM;
				return 1;
			case ']':
				if (skipeq(ls) == sep) {
					savenext(ls);  /* Skip second ']'. */
					goto endloop;
				}
				break;
			case '\n':
			case '\r':
				save(ls, '\n');
				if (newline(ls)) return 1;
				if (!string) lx_buf_reset(&ls->sb);  /* Don't waste space for comments. */
				break;
			default:
				savenext(ls);
				break;
		}
	} endloop:
	if (string) {
		ls->sb.offset = 2 + sep;
		ls->sb.len -= 2*(2 + sep);
	}
	return 0;
}

/* Parse a string. */
static int string(LX_State *ls)
{
	LX_Char delim = ls->c;  /* Delimiter is '\'' or '"'. */
	savenext(ls);
	while (ls->c != delim) {
		switch (ls->c) {
			case EOF:
			case '\n':
			case '\r':
				ls->err = LX_ERR_XSTR;
				return 1;
			case '\\': {
				LX_Char c = next(ls);  /* Skip the '\\'. */
				switch (c) {
					case 'a': c = '\a'; break;
					case 'b': c = '\b'; break;
					case 'f': c = '\f'; break;
					case 'n': c = '\n'; break;
					case 'r': c = '\r'; break;
					case 't': c = '\t'; break;
					case 'v': c = '\v'; break;
					case 'x':  /* Hexadecimal escape '\xXX'. */
						c = (next(ls) & 15u) << 4;
						if (!lx_char_isdigit(ls->c)) {
							if (!lx_char_isxdigit(ls->c)) goto err_xesc;
							c += 9 << 4;
						}
						c += (next(ls) & 15u);
						if (!lx_char_isdigit(ls->c)) {
							if (!lx_char_isxdigit(ls->c)) goto err_xesc;
							c += 9;
						}
						break;
					case 'u':  /* Unicode escape '\u{XX...}'. */
						if (next(ls) != '{') goto err_xesc;
						next(ls);
						c = 0;
						do {
							c = (c << 4) | (ls->c & 15u);
							if (!lx_char_isdigit(ls->c)) {
								if (!lx_char_isxdigit(ls->c)) goto err_xesc;
								c += 9;
							}
							if (c >= 0x110000) goto err_xesc;  /* Out of Unicode range. */
						} while (next(ls) != '}');
						if (c < 0x800) {
							if (c < 0x80) break;
							save(ls, 0xc0 | (c >> 6));
						} else {
							if (c >= 0x10000) {
								save(ls, 0xf0 | (c >> 18));
								save(ls, 0x80 | ((c >> 12) & 0x3f));
							} else {
								if (c >= 0xd800 && c < 0xe000) goto err_xesc;  /* No surrogates. */
								save(ls, 0xe0 | (c >> 12));
							}
							save(ls, 0x80 | ((c >> 6) & 0x3f));
						}
						c = 0x80 | (c & 0x3f);
						break;
					case 'z':  /* Skip whitespace. */
						next(ls);
						while (lx_char_isspace(ls->c))
							if (iseol(ls)) {
								if (newline(ls)) return 1;
							} else {
								next(ls);
							}
						continue;
					case '\n': case '\r':
						save(ls, '\n');
						if (newline(ls)) return 1;
						continue;
					case '\\': case '\"': case '\'':
						break;
					case EOF:
						continue;
					default:
						if (!lx_char_isdigit(c))
							goto err_xesc;
						c -= '0';  /* Decimal escape '\ddd'. */
						if (lx_char_isdigit(next(ls))) {
							c = c*10 + (ls->c - '0');
							if (lx_char_isdigit(next(ls))) {
								c = c*10 + (ls->c - '0');
								if (c > 255) {
								err_xesc:
									ls->err = LX_ERR_XESC;
									return 1;
								}
								next(ls);
							}
						}
						save(ls, c);
						continue;
				}
				save(ls, c);
				next(ls);
				continue;
				}
			default:
				savenext(ls);
				break;
		}
	}
	savenext(ls);  /* Skip trailing delimiter. */
	ls->sb.offset = 1;
	ls->sb.len -= 2;
	return 0;
}

/* -- Main lexical scanner ------------------------------------------------ */

/* Get next lexical token. */
static LX_Token scan(LX_State *ls)
{
	lx_buf_reset(&ls->sb);
	ls->start_line = ls->line;
	ls->start_linepos = ls->linepos;
	ls->start_filepos = ls->filepos;
	for (;;) {
		if (lx_char_isident(ls->c)) {
			if (lx_char_isdigit(ls->c)) {  /* Numeric literal. */
				return number(ls);
			}
			/* Identifier or reserved word. */
			do {
				savenext(ls);
			} while (lx_char_isident(ls->c));
			return TK_NAME; /* ls->sb contains the name. */
		}
		switch (ls->c) {
			case '\n':
			case '\r':
				if (newline(ls)) return TK_ERROR;
				/* Skip any whitespace in front of the token. */
				ls->start_line = ls->line;
				ls->start_linepos = ls->linepos;
				ls->start_filepos++;
				continue;
			case ' ':
			case '\t':
			case '\v':
			case '\f':
				next(ls);
				/* Skip any whitespace in front of the token. */
				ls->start_linepos++;
				ls->start_filepos++;
				continue;
			case '-':
				next(ls);
				if (ls->c == '>') { /* '->', Terra function pointer */
					next(ls);
					return TK_FUNC_PTR;
				}
				if (ls->c != '-') return '-';
				next(ls);
				if (ls->c == '[') {  /* Long comment "--[=*[...]=*]". */
					int sep = skipeq(ls);
					lx_buf_reset(&ls->sb);  /* `skipeq' may dirty the buffer */
					if (sep >= 0) {
						if (longstring(ls, sep, 0)) return TK_ERROR;
						lx_buf_reset(&ls->sb);
						continue;
					}
				}
				/* Short comment "--.*\n". */
				while (!iseol(ls) && ls->c != EOF)
					next(ls);
				continue;
			case '[': {
				int sep = skipeq(ls);
				if (sep >= 0) {
					if (longstring(ls, sep, 1)) return TK_ERROR;
					return TK_STRING;
				} else if (sep == -1) {
					return '[';
				} else {
					ls->err = LX_ERR_XLDELIM;
					return TK_ERROR;
				}
			}
			case '=':
				next(ls);
				if (ls->c == '=') { next(ls); return TK_EQ; }
				return '=';
			case '<':
				next(ls);
				if (ls->c == '<') { next(ls); return TK_LSHIFT; }
				if (ls->c == '=') { next(ls); return TK_LE; }
				return '<';
			case '>':
				next(ls);
				if (ls->c == '>') { next(ls); return TK_RSHIFT; }
				if (ls->c == '=') { next(ls); return TK_GE; }
				return '>';
			case '~':
				next(ls);
				if (ls->c == '=') { next(ls); return TK_NE; }
				return '~';
			case ':':
				next(ls);
				if (ls->c == ':') { next(ls); return TK_LABEL; }
				return ':';
			case '"':
			case '\'':
				if (string(ls)) return TK_ERROR;
				return TK_STRING;
			case '.':
				if (savenext(ls) == '.') {
					next(ls);
					if (ls->c == '.') {
						next(ls);
						return TK_DOTS;   /* ... */
					}
					return TK_CONCAT;   /* .. */
				} else if (!lx_char_isdigit(ls->c)) {
					return '.';
				} else {
					return number(ls);
				}
			case EOF:
				return TK_EOF;
			default: {
				LX_Char c = ls->c;
				next(ls);
				return c;  /* Single-char tokens (+ - / ...). */
			}
		}
	}
}

/* -- Lexer API / ctod/dtor ----------------------------------------------- */

LX_State* lx_state_create(LX_Reader read, void* rdata)
{
	LX_State* ls = malloc(sizeof(LX_State));
	memset(ls, 0, sizeof(LX_State));
	ls->strscan_opt = STRSCAN_OPT_TOINT | STRSCAN_OPT_LL | STRSCAN_OPT_IMAG;
	ls->read = read;
	ls->rdata = rdata;
	ls->line = 1;
	next(ls);  /* Read-ahead first char. */
	return ls;
}

void lx_state_free(LX_State *ls)
{
	lx_buf_free(&ls->sb);
	free(ls->rdata);
}

/* -- Lexer API / lexing -------------------------------------------------- */

/* Return next lexical token. */
LX_Token lx_next(LX_State *ls)
{
	ls->tok = scan(ls);  /* Get next token. */
	return ls->tok;
}

/* Get the string content of the last-retrieved token */
char* lx_string_value(LX_State *ls, int* outlen)
{
	*outlen = ls->sb.len;
	return (char*)(ls->sb.data + ls->sb.offset);
}
double   lx_double_value  (LX_State *ls) { return ls->tv.n; }
int32_t  lx_int32_value   (LX_State *ls) { return ls->tv.i; }
uint64_t lx_uint64_value  (LX_State *ls) { return ls->tv.u64; }
int      lx_error         (LX_State *ls) { return ls->err; }
int      lx_line          (LX_State *ls) { return ls->start_line; }
int      lx_linepos       (LX_State *ls) { return ls->start_linepos; }
int      lx_filepos       (LX_State *ls) { return ls->start_filepos; }
int      lx_end_line      (LX_State *ls) { return ls->line; }
int      lx_end_filepos   (LX_State *ls) { return ls->filepos; }

void lx_set_strscan_opt   (LX_State *ls, int opt) { ls->strscan_opt = opt; }

/* -- Lexer API / readers ------------------------------------------------- */

typedef struct FileReaderCtx {
	FILE *fp;
	char buf[8192];
} FileReaderCtx;

static const char *reader_file(void *ud, size_t *size)
{
	FileReaderCtx *ctx = (FileReaderCtx *)ud;
	if (feof(ctx->fp)) return NULL;
	*size = fread(ctx->buf, 1, sizeof(ctx->buf), ctx->fp);
	return *size > 0 ? ctx->buf : NULL;
}

LX_State* lx_state_create_for_file(FILE* fp) {
	FileReaderCtx* ctx = malloc(sizeof(FileReaderCtx));
	ctx->fp = fp;
	return lx_state_create(reader_file, (void*)ctx);
}

typedef struct StringReaderCtx {
	const char *s;
	size_t len;
} StringReaderCtx;

static const char *reader_string(void *ud, size_t *size)
{
	StringReaderCtx *ctx = (StringReaderCtx *)ud;
	if (ctx->len == 0) return NULL;
	*size = ctx->len;
	ctx->len = 0;
	return ctx->s;
}

LX_State* lx_state_create_for_string(const char* s, size_t len) {
	StringReaderCtx* ctx = malloc(sizeof(FileReaderCtx));
	ctx->s = s;
	ctx->len = len;
	return lx_state_create(reader_string, (void*)ctx);
}
