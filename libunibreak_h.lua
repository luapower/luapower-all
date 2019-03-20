require'ffi'.cdef[[

// linebreak.h, wordbreak.h, graphemebreak.h from libunibreak 4.0

const int unibreak_version;

typedef unsigned char  utf8_t;
typedef unsigned short utf16_t;
typedef unsigned int   utf32_t;

enum {
	LINEBREAK_MUSTBREAK   = 0,  // Break is mandatory.
	LINEBREAK_ALLOWBREAK  = 1,  // Break is allowed.
	LINEBREAK_NOBREAK     = 2,  // No break is possible.
	LINEBREAK_INSIDEACHAR = 3,  // A UTF-8/16 sequence is unfinished.
};

void init_linebreak(void);
void set_linebreaks_utf8 (const utf8_t  *s, size_t len, const char *lang, char *brks);
void set_linebreaks_utf16(const utf16_t *s, size_t len, const char *lang, char *brks);
void set_linebreaks_utf32(const utf32_t *s, size_t len, const char *lang, char *brks);
int is_line_breakable(utf32_t char1, utf32_t char2, const char *lang);

enum {
	WORDBREAK_BREAK       = 0,  // Break is allowed.
	WORDBREAK_NOBREAK     = 1,  // No break is allowed.
	WORDBREAK_INSIDEACHAR = 2,  // A UTF-8/16 sequence is unfinished.
};

void init_wordbreak(void);
void set_wordbreaks_utf8 (const utf8_t  *s, size_t len, const char* lang, char *brks);
void set_wordbreaks_utf16(const utf16_t *s, size_t len, const char* lang, char *brks);
void set_wordbreaks_utf32(const utf32_t *s, size_t len, const char* lang, char *brks);

enum {
	GRAPHEMEBREAK_BREAK       = 0,
	GRAPHEMEBREAK_NOBREAK     = 1,
	GRAPHEMEBREAK_INSIDEACHAR = 2,
};
void init_graphemebreak(void);
void set_graphemebreaks_utf8 (const utf8_t  *s, size_t len, const char *lang, char *brks);
void set_graphemebreaks_utf16(const utf16_t *s, size_t len, const char *lang, char *brks);
void set_graphemebreaks_utf32(const utf32_t *s, size_t len, const char *lang, char *brks);


utf32_t ub_get_next_char_utf8 (const utf8_t  *s, size_t len, size_t *ip);
utf32_t ub_get_next_char_utf16(const utf16_t *s, size_t len, size_t *ip);
utf32_t ub_get_next_char_utf32(const utf32_t *s, size_t len, size_t *ip);

]]
