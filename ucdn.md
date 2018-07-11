---
tagline: unicode database and normalization
---

## `local ucdn = require'ucdn'`

A ffi binding of [UCDN][https://github.com/grigorig/ucdn].

UCDN is a Unicode support library. Currently, it provides access
to basic character properties contained in the Unicode Character
Database and low-level normalization functions (pairwise canonical
composition/decomposition and compatibility decomposition).

## API

------------------------------------------ -----------------------------------------
`ucdn.unicode_version() -> s`              Unicode version
`ucdn.combining_class(c) -> class`         combining class of code point per UAX#44
`ucdn.east_asian_width(c) -> width`        east asian width of code point per UAX#11
`ucdn.general_category(c) -> cat`          general category of code point per UAX#44
`ucdn.bidi_class(c) -> class`              BiDi class of code point per UAX#44
`ucdn.script(c) -> script`                 script name of code point per UAX#24
`ucdn.linebreak_class(c) -> class`         line-break class of code point per UAX#14
`ucdn.resolved_linebreak_class(c) -> cls`  resolved line-break class
`ucdn.mirrored(c) -> t|f`                  true if mirrored character exists
`ucdn.mirror(c) -> c`                      mirrored codepoint if no mirrored char exists
`ucdn.paired_bracket(c) -> c`              paired bracket if no paired bracket char exists
`ucdn.paired_bracket_type(c) -> type`      paired bracket type per UAX#9
`ucdn.decompose(c) -> ok, a, b`            pairwise canonical decomposition
`ucdn.compat_decompose(c) -> a`            compatibility decomposition
`ucdn.compose(a, b) -> ok, c`              pairwise canonical composition
------------------------------------------ ------------------------------------------

### `ucdn.resolved_linebreak_class(c) -> class`

Get resolved linebreak class of a codepoint. This resolves characters
in the AI, SG, XX, SA and CJ classes according to rule LB1 of UAX#14.
In addition the CB class is resolved as the equivalent B2 class and
the NL class is resolved as the equivalent BK class.

### `ucdn.decompose(c) -> ok, a, b`

Pairwise canonical decomposition of a codepoint. This includes
Hangul Jamo decomposition (see chapter 3.12 of the Unicode core
specification).

Hangul is decomposed into L and V jamos for LV forms, and an
LV precomposed syllable and a T jamo for LVT forms.

### `ucdn.compose(a, b) -> ok, c`

Pairwise canonical composition of two codepoints. This includes
Hangul Jamo composition (see chapter 3.12 of the Unicode core
specification).

Hangul composition expects either L and V jamos, or an LV
precomposed syllable and a T jamo. This is exactly the inverse
of pairwise Hangul decomposition.
