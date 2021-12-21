// go@ mgit build jsmin
/* jsmin.c
   2019-10-30

Copyright (C) 2002 Douglas Crockford  (www.crockford.com)
Lua adaptation by Cosmin Apreutesei. Public Domain.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#include <stdlib.h>
#include <stdio.h>
#include "lua.h"
#include "lauxlib.h"

typedef struct st {
	const char* s; // input string
	int n; // input string length
	int i; // current index in input string
	luaL_Buffer out;
	int a;
	int b;
	int x;
	int y;
} st;

#define error(s) luaL_error(L, s)

// return true if the character is a letter, digit, underscore, dollar sign,
// or non-ASCII character.
static int is_alphanum(int c) {
	return (
		   (c >= 'a' && c <= 'z')
		|| (c >= '0' && c <= '9')
		|| (c >= 'A' && c <= 'Z')
		|| c == '_'
		|| c == '$'
		|| c == '\\'
		|| c > 126
	);
}

// return the next character from the string. Watch out for lookahead.
// If the character is a control character, translate it to a space or linefeed.
static int _get(lua_State *L, st* s) {
	int c = s->i < s->n ? s->s[s->i++] : EOF;
	if (c >= ' ' || c == '\n' || c == EOF)
		return c;
	if (c == '\r')
		return '\n';
	return ' ';
}
#define get() _get(L, s)

// get the next character without advancing.
static int _peek(lua_State *L, st* s) {
	return s->i < s->n ? s->s[s->i] : EOF;
}
#define peek() _peek(L, s)

// get the next character, excluding comments. peek() is used to see
// if a '/' is followed by a '/' or '*'.
static int _next(lua_State *L, st* s) {
	int c = get();
	if  (c == '/') {
		switch (peek()) {
		case '/':
			for (;;) {
				c = get();
				if (c <= '\n') {
					break;
				}
			}
			break;
		case '*':
			get();
			while (c != ' ') {
				switch (get()) {
				case '*':
					if (peek() == '/') {
						get();
						c = ' ';
					}
					break;
				case EOF:
					error("unterminated comment");
				}
			}
			break;
		}
	}
	s->y = s->x;
	s->x = c;
	return c;
}
#define next() _next(L, s)

#define putc(c, stdout) luaL_addchar(&s->out, c)

/* the argument can be one of:
		1:   Output A. Copy B to A. Get the next B.
		2:   Copy B to A. Get the next B. (Delete A).
		3:   Get the next B. (Delete B).
   Treats a string as a single character.
   Recognizes a regular expression if it is preceded by the likes of '(' or ',' or '='.
*/
static void _action(lua_State *L, st* s, int determined) {
	switch (determined) {
	case 1:
		putc(s->a, stdout);
		if (
			   (s->y == '\n' || s->y == ' ')
			&& (s->a == '+'  || s->a == '-' || s->a == '*' || s->a == '/')
			&& (s->b == '+'  || s->b == '-' || s->b == '*' || s->b == '/')
		) {
			putc(s->y, stdout);
		}
	case 2:
		s->a = s->b;
		if (s->a == '\'' || s->a == '"' || s->a == '`') {
			for (;;) {
				putc(s->a, stdout);
				s->a = get();
				if (s->a == s->b) {
					break;
				}
				if (s->a == '\\') {
					putc(s->a, stdout);
					s->a = get();
				}
				if (s->a == EOF) {
					error("unterminated string literal");
				}
			}
		}
	case 3:
		s->b = next();
		if (s->b == '/' && (
			   s->a == '(' || s->a == ',' || s->a == '=' || s->a == ':'
			|| s->a == '[' || s->a == '!' || s->a == '&' || s->a == '|'
			|| s->a == '?' || s->a == '+' || s->a == '-' || s->a == '~'
			|| s->a == '*' || s->a == '/' || s->a == '{' || s->a == '}'
			|| s->a == ';'
		)) {
			putc(s->a, stdout);
			if (s->a == '/' || s->a == '*') {
				putc(' ', stdout);
			}
			putc(s->b, stdout);
			for (;;) {
				s->a = get();
				if (s->a == '[') {
					for (;;) {
						putc(s->a, stdout);
						s->a = get();
						if (s->a == ']') {
							break;
						}
						if (s->a == '\\') {
							putc(s->a, stdout);
							s->a = get();
						}
						if (s->a == EOF) {
							error("unterminated set in regexp literal");
						}
					}
				} else if (s->a == '/') {
					switch (peek()) {
					case '/':
					case '*':
						error("unterminated set in regexp literal");
					}
					break;
				} else if (s->a =='\\') {
					putc(s->a, stdout);
					s->a = get();
				}
				if (s->a == EOF) {
					error("unterminated regexp literal");
				}
				putc(s->a, stdout);
			}
			s->b = next();
		}
	}
}
#define action(d) _action(L, s, d)

// copy the input to the output, deleting the characters which are
// insignificant to JavaScript. Comments will be removed. Tabs will be
// replaced with spaces. CR will be replaced with LF.
// Most spaces and LFs will be removed.
static int jsmin(lua_State *L) {

	st _s = {
		.x = EOF,
		.y = EOF,
	};

	size_t sn;
	_s.s = luaL_checklstring(L, 1, &sn);
	_s.n = sn;

	st *s = &_s;

	luaL_buffinit(L, &s->out);

	if (peek() == 0xEF) {
		get();
		get();
		get();
	}
	s->a = '\n';
	action(3);
	while (s->a != EOF) {
		switch (s->a) {
		case ' ':
			action(is_alphanum(s->b) ? 1 : 2);
			break;
		case '\n':
			switch (s->b) {
			case '{':
			case '[':
			case '(':
			case '+':
			case '-':
			case '!':
			case '~':
				action(1);
				break;
			case ' ':
				action(3);
				break;
			default:
				action(is_alphanum(s->b) ? 1 : 2);
			}
			break;
		default:
			switch (s->b) {
			case ' ':
				action(is_alphanum(s->a) ? 1 : 3);
				break;
			case '\n':
				switch (s->a) {
				case '}':
				case ']':
				case ')':
				case '+':
				case '-':
				case '"':
				case '\'':
				case '`':
					action(1);
					break;
				default:
					action(is_alphanum(s->a) ? 1 : 3);
				}
				break;
			default:
				action(1);
				break;
			}
		}
	}

	luaL_pushresult(&s->out);
	return 1;
}

static const struct luaL_Reg thislib[] = {
  {"minify", jsmin},
  {NULL, NULL}
};


LUALIB_API int luaopen_jsmin (lua_State *L) {
  luaL_register(L, "jsmin", thislib);
  return 1;
}
