
--Unicode UAX#24 algorithm for detecting the script property of text runs.
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'terra/tr_types')

local terra is_combining_mark(funcs: &hb_unicode_funcs_t, c: codepoint)
	var cat = hb_unicode_general_category(funcs, c)
	return
		   cat == HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK
		or cat == HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK
		or cat == HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK
end

local terra real_script(script: hb_script_t)
	return not (
		   script == HB_SCRIPT_INVALID
		or script == HB_SCRIPT_COMMON
		or script == HB_SCRIPT_INHERITED
		or script == HB_SCRIPT_UNKNOWN --unassigned, private use, non-characters
	)
end

local pairs_table = {
  0x0028, 0x0029, -- ascii paired punctuation
  0x003c, 0x003e,
  0x005b, 0x005d,
  0x007b, 0x007d,
  0x00ab, 0x00bb, -- guillemets
  0x2018, 0x2019, -- general punctuation
  0x201c, 0x201d,
  0x2039, 0x203a,
  0x3008, 0x3009, -- chinese paired punctuation
  0x300a, 0x300b,
  0x300c, 0x300d,
  0x300e, 0x300f,
  0x3010, 0x3011,
  0x3014, 0x3015,
  0x3016, 0x3017,
  0x3018, 0x3019,
  0x301a, 0x301b
}
local pairs_array = constant(terralib.new(int32[#pairs_table], pairs_table))
local pair_index = phf(index(pairs_table), codepoint, int8)
local terra pair(c: codepoint): {bool, int, bool}
	var i = pair_index(c)
	if i == 0 then
		return false, 0, false
	end
	var open = i % 2 == 1
	if not open then i = i - 1 end
	return true, pairs_array[i-1], open
end

--fills a buffer with the Script property for each char in a utf32 buffer.
--uses UAX#24 Section 5.1 and 5.2 to resolve chars with implicit scripts.
terra detect_scripts(r: &Renderer, s: &codepoint, len: int, outbuf: &hb_script_t)
	var stack = r.cpstack
	stack.len = 0
	var unicode_funcs = hb_unicode_funcs_get_default()
	var script = HB_SCRIPT_COMMON
	var base_char_i = 0 --index of base character in combining sequence
	for i = 0, len do
		var c = s[i]
		if is_combining_mark(unicode_funcs, c) then --Section 5.2
			if not real_script(script) then --base char has no script
				var sc = hb_unicode_script(unicode_funcs, c)
				if real_script(sc) then --this combining mark has a script
					script = sc --subsequent marks must use this script too
					--resolve all previous marks and the base char
					for i = base_char_i, i do
						outbuf[i] = script
					end
				end
			end
		else
			var sc = hb_unicode_script(unicode_funcs, c)
			if sc == HB_SCRIPT_COMMON then --Section 5.1
				var ispair, pair, open = pair(c)
				if ispair then
					if open then --remember the enclosing script
						stack:push(script)
						stack:push(pair)
					else --restore the enclosing script
						for i = stack.len-1, -1, -2 do
							if stack(i) == pair then --pair opened here
								for i = stack.len-1, i-1, -2 do
									stack:pop()
									script = stack:pop()
								end
								break
							end
						end
					end
				end
			elseif real_script(sc) then
				if script == HB_SCRIPT_COMMON then
					--found a script for the first time: resolve all previous
					--unresolved chars.
					for i = 0, i-1 do
						if outbuf[i] == HB_SCRIPT_COMMON then
							outbuf[i] = sc
						end
					end
					--resolve unresolved scripts of open pairs too.
					for i = 1, stack.len, 2 do
						if stack(i) == HB_SCRIPT_COMMON then
							stack:set(i, sc)
						end
					end
				end
				script = sc
			end
			base_char_i = base_char_i + 1
		end
		outbuf[i] = script
	end
end
