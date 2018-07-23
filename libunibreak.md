---
tagline: Unicode line breaking
---

## `local ub = require'libunibreak'`

A ffi binding to [libunibreak][libunibreak lib], a C library implementing
the [Unicode line breaking algorithm][tr14] and word breaking
from [Unicode text segmentation][tr29].

## Line breaking

	`ub.linebreaks(s,[len],[lang],[out]) -> line_breaks`

The returned `line_breaks` is a 0-based array of flags, one for each byte
of the input string:

--- ------------------------------------
0   Break is mandatory.
1   Break is allowed.
2   No break is possible.
--- ------------------------------------

## Word breaking

	`ub.wordbreaks(s,[len],[lang],[out]) -> word_breaks`

The returned `word_breaks` is a 0-based array of flags, one for each byte
of the input string:

--- ------------------------------------
0   Break is allowed.
1   No break is allowed.
--- ------------------------------------

## Grapheme breaking

	`ub.graphemebreaks(s,[len],[lang],[out]) -> grapheme_breaks`

The returned `grapheme_breaks` is a 0-based array of flags, one for each byte
of the input string:

--- ------------------------------------
0   Break is allowed.
1   No break is allowed.
--- ------------------------------------

[libunibreak lib]: http://vimgadgets.sourceforge.net/libunibreak/
[tr14]:            http://www.unicode.org/reports/tr14/
[tr29]:            http://www.unicode.org/reports/tr29/
