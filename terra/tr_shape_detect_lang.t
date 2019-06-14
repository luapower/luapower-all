
--Function for returning the most common language for a script.
--Written by Cosmin Apreutesei. Public Domain.
--List of language-script associations taken from pango-language.c.

setfenv(1, require'terra/tr_types')

local lang_maps = {
	[HB_SCRIPT_ARABIC] = 'ar',
	[HB_SCRIPT_ARMENIAN] = 'hy',
	[HB_SCRIPT_BENGALI] = 'bn',
	[HB_SCRIPT_CHEROKEE] = 'chr',
	[HB_SCRIPT_COPTIC] = 'cop',
	[HB_SCRIPT_CYRILLIC] = 'ru',
	[HB_SCRIPT_DEVANAGARI] = 'hi',
	[HB_SCRIPT_ETHIOPIC] = 'am',
	[HB_SCRIPT_GEORGIAN] = 'ka',
	[HB_SCRIPT_GREEK] = 'el',
	[HB_SCRIPT_GUJARATI] = 'gu',
	[HB_SCRIPT_GURMUKHI] = 'pa',
	[HB_SCRIPT_HANGUL] = 'ko',
	[HB_SCRIPT_HEBREW] = 'he',
	[HB_SCRIPT_HIRAGANA] = 'ja',
	[HB_SCRIPT_KANNADA] = 'kn',
	[HB_SCRIPT_KATAKANA] = 'ja',
	[HB_SCRIPT_KHMER] = 'km',
	[HB_SCRIPT_LAO] = 'lo',
	[HB_SCRIPT_LATIN] = 'en',
	[HB_SCRIPT_MALAYALAM] = 'ml',
	[HB_SCRIPT_MONGOLIAN] = 'mn',
	[HB_SCRIPT_MYANMAR] = 'my',
	[HB_SCRIPT_ORIYA] = 'or',
	[HB_SCRIPT_SINHALA] = 'si',
	[HB_SCRIPT_SYRIAC] = 'syr',
	[HB_SCRIPT_TAMIL] = 'ta',
	[HB_SCRIPT_TELUGU] = 'te',
	[HB_SCRIPT_THAANA] = 'dv',
	[HB_SCRIPT_THAI] = 'th',
	[HB_SCRIPT_TIBETAN] = 'bo',
	[HB_SCRIPT_CANADIAN_SYLLABICS] = 'iu',
	[HB_SCRIPT_TAGALOG] = 'tl',
	[HB_SCRIPT_HANUNOO] = 'hnn',
	[HB_SCRIPT_BUHID] = 'bku',
	[HB_SCRIPT_TAGBANWA] = 'tbw',
	[HB_SCRIPT_OSMANYA] = 'so',
	[HB_SCRIPT_SHAVIAN] = 'en',
	[HB_SCRIPT_UGARITIC] = 'uga',
	[HB_SCRIPT_BUGINESE] = 'bug',
	[HB_SCRIPT_SYLOTI_NAGRI] = 'syl',
	[HB_SCRIPT_OLD_PERSIAN] = 'peo',
	[HB_SCRIPT_NKO] = 'nqo',
}
for script, lang in pairs(lang_maps) do
	lang_maps[script] = assert(hb_language_from_string(lang, #lang))
end

return phf(lang_maps, hb_script_t, hb_language_t, `nil)
