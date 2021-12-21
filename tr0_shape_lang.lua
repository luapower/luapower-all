
--function for returning the most common language for a script.
--list of language-script associations taken from pango-language.c.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local hb = require'harfbuzz'
local C = hb.C

local langs = {}

for script, lang in pairs{
	[C.HB_SCRIPT_ARABIC] = 'ar',
	[C.HB_SCRIPT_ARMENIAN] = 'hy',
	[C.HB_SCRIPT_BENGALI] = 'bn',
	[C.HB_SCRIPT_CHEROKEE] = 'chr',
	[C.HB_SCRIPT_COPTIC] = 'cop',
	[C.HB_SCRIPT_CYRILLIC] = 'ru',
	[C.HB_SCRIPT_DEVANAGARI] = 'hi',
	[C.HB_SCRIPT_ETHIOPIC] = 'am',
	[C.HB_SCRIPT_GEORGIAN] = 'ka',
	[C.HB_SCRIPT_GREEK] = 'el',
	[C.HB_SCRIPT_GUJARATI] = 'gu',
	[C.HB_SCRIPT_GURMUKHI] = 'pa',
	[C.HB_SCRIPT_HANGUL] = 'ko',
	[C.HB_SCRIPT_HEBREW] = 'he',
	[C.HB_SCRIPT_HIRAGANA] = 'ja',
	[C.HB_SCRIPT_KANNADA] = 'kn',
	[C.HB_SCRIPT_KATAKANA] = 'ja',
	[C.HB_SCRIPT_KHMER] = 'km',
	[C.HB_SCRIPT_LAO] = 'lo',
	[C.HB_SCRIPT_LATIN] = 'en',
	[C.HB_SCRIPT_MALAYALAM] = 'ml',
	[C.HB_SCRIPT_MONGOLIAN] = 'mn',
	[C.HB_SCRIPT_MYANMAR] = 'my',
	[C.HB_SCRIPT_ORIYA] = 'or',
	[C.HB_SCRIPT_SINHALA] = 'si',
	[C.HB_SCRIPT_SYRIAC] = 'syr',
	[C.HB_SCRIPT_TAMIL] = 'ta',
	[C.HB_SCRIPT_TELUGU] = 'te',
	[C.HB_SCRIPT_THAANA] = 'dv',
	[C.HB_SCRIPT_THAI] = 'th',
	[C.HB_SCRIPT_TIBETAN] = 'bo',
	[C.HB_SCRIPT_CANADIAN_SYLLABICS] = 'iu',
	[C.HB_SCRIPT_TAGALOG] = 'tl',
	[C.HB_SCRIPT_HANUNOO] = 'hnn',
	[C.HB_SCRIPT_BUHID] = 'bku',
	[C.HB_SCRIPT_TAGBANWA] = 'tbw',
	[C.HB_SCRIPT_OSMANYA] = 'so',
	[C.HB_SCRIPT_SHAVIAN] = 'en',
	[C.HB_SCRIPT_UGARITIC] = 'uga',
	[C.HB_SCRIPT_BUGINESE] = 'bug',
	[C.HB_SCRIPT_SYLOTI_NAGRI] = 'syl',
	[C.HB_SCRIPT_OLD_PERSIAN] = 'peo',
	[C.HB_SCRIPT_NKO] = 'nqo',
} do
	langs[script] = assert(hb.language(lang))
end

local function lang_for_script(hb_script)
	return langs[hb_script]
end

return lang_for_script
