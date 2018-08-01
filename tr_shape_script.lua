
--Unicode UAX#24 algorithm for detecting the script property of text runs.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local bit = require'bit'
local hb = require'harfbuzz'
local glue = require'glue'

local band = bit.band
local push = table.insert
local pop = table.remove
local index = glue.index
local memoize = glue.memoize
local odd = function(x) return band(x, 1) == 1 end

local non_scripts = index{
	hb.C.HB_SCRIPT_INVALID,
	hb.C.HB_SCRIPT_COMMON,
	hb.C.HB_SCRIPT_INHERITED,
	hb.C.HB_SCRIPT_UNKNOWN, --unassigned, private use, non-characters
}
local function real_script(script)
	return not non_scripts[script]
end

local pair_indices = index{
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
local function pair(c)
	local i = pair_indices[c]
	if not i then return nil end
	local open = odd(i)
	return i - (open and 0 or 1), open
end

local function is_combining_mark(c)
	local cat = hb.unicode_general_category(c)
	return
		cat == hb.C.HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK or
		cat == hb.C.HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK or
		cat == hb.C.HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK
end
--is_combining_mark = memoize(is_combining_mark)

--fills a buffer with the Script property for each char in a utf32 buffer.
--uses UAX#24 Section 5.1 and 5.2 to resolve chars with implicit scripts.
local function detect_scripts(s, len, outbuf)
	local script = hb.C.HB_SCRIPT_COMMON
	local base_char_i = 0 --index of base character in combining sequence
	local stack = {} --{script1, pair1, ...}
	for i = 0, len-1 do
		local c = s[i]
		if is_combining_mark(c) then --Section 5.2
			if not real_script(script) then --base char has no script
				local sc = hb.unicode_script(c)
				if real_script(sc) then --this combining mark has a script
					script = sc --subsequent marks must use this script too
					--resolve all previous marks and the base char
					for i = base_char_i, i-1 do
						outbuf[i] = script
					end
				end
			end
		else
			local sc = hb.unicode_script(c)
			if sc == hb.C.HB_SCRIPT_COMMON then --Section 5.1
				local pair, open = pair(c)
				if pair then
					if open then --remember the enclosing script
						push(stack, script)
						push(stack, pair)
					else --restore the enclosing script
						for i = #stack, 1, -2 do
							if stack[i] == pair then --pair opened here
								for i = #stack, i, -2 do
									pop(stack)
									script = pop(stack)
								end
								break
							end
						end
					end
				end
			elseif real_script(sc) then
				if script == hb.C.HB_SCRIPT_COMMON then
					--found a script for the first time: resolve all previous
					--unresolved chars.
					for i = 0, i-1 do
						if outbuf[i] == hb.C.HB_SCRIPT_COMMON then
							outbuf[i] = sc
						end
					end
					--resolve unresolved scripts of open pairs too.
					for i = 2, #stack, 2 do
						if stack[i] == hb.C.HB_SCRIPT_COMMON then
							stack[i] = sc
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

return detect_scripts
