---
tagline: unicode line breaking
---

## `local ub = require'libunibreak'`

A ffi binding to [libunibreak][libunibreak lib], a C library implementing
the [unicode line breaking algorithm][tr14] and word breaking
from [unicode text segmentation][tr29].

## Line breaking

	`ub.linebreaks_utf8 (s,[len[,lang]],[out]) -> line_breaks`
	`ub.linebreaks_utf16(s,[len[,lang]],[out]) -> line_breaks`
	`ub.linebreaks_utf32(s,[len[,lang]],[out]) -> line_breaks`

The returned `line_breaks` is a 0-based array of flags, one for each byte
of the input string:

--- ------------------------------------
0   Break is mandatory.
1   Break is allowed.
2   No break is possible.
3   A UTF-8/16 sequence is unfinished.
--- ------------------------------------

## Word breaking

	`ub.wordbreaks_utf8 (s,[len[,lang]],[out]) -> word_breaks`
	`ub.wordbreaks_utf16(s,[len[,lang]],[out]) -> word_breaks`
	`ub.wordbreaks_utf32(s,[len[,lang]],[out]) -> word_breaks`

The returned `word_breaks` is a 0-based array of flags, one for each byte
of the input string:

--- ------------------------------------
0   Break is allowed.
1   No break is allowed.
2   A UTF-8/16 sequence is unfinished.
--- ------------------------------------

## Grapheme breaking

	`ub.graphemebreaks_utf8 (s[,len[,lang]],[out]) -> grapheme_breaks`
	`ub.graphemebreaks_utf16(s[,len[,lang]],[out]) -> grapheme_breaks`
	`ub.graphemebreaks_utf32(s[,len[,lang]],[out]) -> grapheme_breaks`

The returned `grapheme_breaks` is a 0-based array of flags, one for each byte
of the input string:

--- ------------------------------------
0   Break is allowed.
1   No break is allowed.
2   A UTF-8/16 sequence is unfinished.
--- ------------------------------------

## Unicode helpers

Iterate codepoints:

	`ub.next_char_utf8 (s,[len],[start]) -> next_start, codepoint`
	`ub.next_char_utf16(s,[len],[start]) -> next_start, codepoint`
	`ub.next_char_utf32(s,[len],[start]) -> next_start, codepoint`

	`ub.chars_utf8 (s,[len],[start]) -> iter() -> next_start, codepoint`
	`ub.chars_utf16(s,[len],[start]) -> iter() -> next_start, codepoint`
	`ub.chars_utf32(s,[len],[start]) -> iter() -> next_start, codepoint`

Count code points:

	`ub.len_utf8 (s[,len]) -> n`
	`ub.len_utf16(s[,len]) -> n`
	`ub.len_utf32(s[,len]) -> n`


[libunibreak lib]: http://vimgadgets.sourceforge.net/libunibreak/
[tr14]:            http://www.unicode.org/reports/tr14/
[tr29]:            http://www.unicode.org/reports/tr29/
