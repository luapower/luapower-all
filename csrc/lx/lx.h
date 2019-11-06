/*
** LuaJIT lexer. C API. Public Domain.
*/

#ifndef _LX_H
#define _LX_H

#include <stdint.h>
#include <stdio.h>

/* number parsing options */
#define STRSCAN_OPT_TOINT  0x01  /* Convert to int32_t, if possible. */
#define STRSCAN_OPT_TONUM  0x02  /* Always convert to double. */
#define STRSCAN_OPT_IMAG   0x04
#define STRSCAN_OPT_LL     0x08
#define STRSCAN_OPT_C      0x10

/* Token types. */
enum {
	TK_EOF = -100, TK_ERROR,
	TK_NUM, TK_IMAG, TK_INT, TK_U32, TK_I64, TK_U64, /* number types */
	TK_NAME, TK_STRING, TK_LABEL,
	TK_EQ, TK_LE, TK_GE, TK_NE, TK_DOTS, TK_CONCAT,
	TK_FUNC_PTR, TK_LSHIFT, TK_RSHIFT,
};

/* Error codes. */
enum {
	LX_ERR_NONE    ,
	LX_ERR_XLINES  , /* chunk has too many lines */
	LX_ERR_XNUMBER , /* malformed number */
	LX_ERR_XLCOM   , /* unfinished long comment */
	LX_ERR_XLSTR   , /* unfinished long string */
	LX_ERR_XSTR    , /* unfinished string */
	LX_ERR_XESC    , /* invalid escape sequence */
	LX_ERR_XLDELIM , /* invalid long string delimiter */
};

typedef int LX_Token;
typedef struct LX_State LX_State;

typedef const char* (*LX_Reader)  (void*, size_t*);

LX_State* lx_state_create            (LX_Reader, void*);
LX_State* lx_state_create_for_file   (FILE*);
LX_State* lx_state_create_for_string (const char*, size_t);
void      lx_state_free              (LX_State*);

LX_Token lx_next          (LX_State*);
char*    lx_string_value  (LX_State*, int*);
double   lx_double_value  (LX_State*);
int32_t  lx_int32_value   (LX_State*);
uint64_t lx_uint64_value  (LX_State*);
int      lx_error         (LX_State *ls);
int      lx_line          (LX_State *ls);
int      lx_linepos       (LX_State *ls);
int      lx_filepos       (LX_State *ls);

void lx_set_strscan_opt   (LX_State*, int);

#endif
