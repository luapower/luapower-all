---
tagline: unicode line breaking
---

## `local ub = require'libunibreak'`

A ffi binding to [libunibreak][libunibreak lib], a C library implementing
the [unicode line breaking algorithm][tr14] and word breaking from [unicode text segmentation][tr29].

## Line breaking

	ub.linebreaks_utf8 (s[,size[,lang]]) -> line_breaks
	ub.linebreaks_utf16(s[,size[,lang]]) -> line_breaks
	ub.linebreaks_utf32(s[,size[,lang]]) -> line_breaks

The returned `line_breaks` is a 0-based array of flags, one for each byte of the input string:

--- ------------------------------------
0   Break is mandatory.
1   Break is allowed.
2   No break is possible.
3   A UTF-8/16 sequence is unfinished.
--- ------------------------------------

## Word breaking

	ub.wordbreaks_utf8 (s[,size[,lang]]) -> word_breaks
	ub.wordbreaks_utf16(s[,size[,lang]]) -> word_breaks
	ub.wordbreaks_utf32(s[,size[,lang]]) -> word_breaks

The returned `word_breaks` is a 0-based array of flags, one for each byte of the input string:

--- ------------------------------------
0   Break is allowed.
1   No break is allowed.
2   A UTF-8/16 sequence is unfinished.
--- ------------------------------------

## Grapheme breaking

	ub.graphemebreaks_utf8 (s[,size[,lang]]) -> grapheme_breaks
	ub.graphemebreaks_utf16(s[,size[,lang]]) -> grapheme_breaks
	ub.graphemebreaks_utf32(s[,size[,lang]]) -> grapheme_breaks

The returned `grapheme_breaks` is a 0-based array of flags, one for each byte of the input string:

--- ------------------------------------
0   Break is allowed.
1   No break is allowed.
2   A UTF-8/16 sequence is unfinished.
--- ------------------------------------

## Unicode helpers

	ub.chars_utf8(s) -> iter() -> i, codepoint
	ub.chars_utf16(s) -> iter() -> i, codepoint
	ub.chars_utf32(s) -> iter() -> i, codepoint

Iterate codepoints.

	ub.len_utf8(s[,size]) -> len
	ub.len_utf16(s[,size]) -> len
	ub.len_utf32(s[,size]) -> len

Get the number of codepoints in string.


[libunibreak lib]: http://vimgadgets.sourceforge.net/libunibreak/
[tr14]:            http://www.unicode.org/reports/tr14/
[tr29]:            http://www.unicode.org/reports/tr29/
