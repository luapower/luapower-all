
--&name; parser for utf-8 strings.
--Written by Cosmin Apreutesei. Public Domain.

local u = {} --{name -> utf8-sequence}

--paragraph and line separators.
u.ps = '\u{2029}' --paragraph separator
u.ls = '\u{2028}' --line separator

--for use in bidi text.
u.lrm = '\u{200E}' --LR mark
u.rlm = '\u{200F}' --RL mark
u.lre = '\u{202A}' --LR embedding
u.rle = '\u{202B}' --RL embedding
u.pdf = '\u{202C}' --close LRE or RLE
u.lro = '\u{202D}' --LR override
u.rlo = '\u{202E}' --RL override
u.lri = '\u{2066}' --LR isolate
u.rli = '\u{2067}' --RL isolate
u.fsi = '\u{2068}' --first-strong isolate
u.pdi = '\u{2069}' --close RLI, LRI or FSI

--line wrapping control.
u.nbsp   = '\u{00A0}' --non-breaking space
u.zwsp   = '\u{200B}' --zero-width space (i.e. soft-wrap mark)
u.zwnbsp = '\u{FEFF}' --zero-width non-breaking space (i.e. nowrap mark)

--spacing control.
u.figure_sp = '\u{2007}' --figure non-breaking space (for separating digits)
u.thin_sp   = '\u{2009}' --thin space
u.hair_sp   = '\u{200A}' --hair space

function u.__call(self, s)
	return (s:gsub('&([^&;]+);', self))
end
setmetatable(u, u)

if not ... then
	assert(u'these&nbsp;words&ls;apples & oranges'
				== 'these\u{00a0}words\u{2028}apples & oranges')
end

return u
