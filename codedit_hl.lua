--codedit incremental highlighter: integrating scintillua with a line buffer object.
local glue = require'glue'
local str = require'codedit_str'
local lexer = require'lexer'
lexer.LEXERPATH = 'media/lexers/?.lua'

--select text from buffer between (line1, p1) up to the end of line2 excluding line terminator.
local function select_text(buffer, line1, p1, line2)
	line2 = line2 or buffer:last_line()
	local s = buffer:getline(line1):sub(p1)
	if line2 > line1 then
		s = s .. buffer.line_terminator ..
				table.concat(buffer.lines, buffer.line_terminator, line1 + 1, line2)
	end
	return s
end

--lex selected text returning a list of token positions and styles.
--the token list is a zero-based array of form {[0] = pos1, style1, ..., posN, styleN, posN+1}
local function lex_text(s, lang)
	local lex = lexer.load(lang)
	local t = lexer.lex(lex, s)
	t[0] = 1
	return t
end

--token lists can also have explicit length, so we use len() to test for length.
local function len(t)
	return t.len or #t
end

local function unpack_token_pos(t, i) --i, p
	if i > len(t) then return end
	return i, t[i]
end

local function next_token_pos(t, i)
	return unpack_token_pos(t, i and i + 2 or 0)
end

local function tokens_pos(t)
	return next_token_pos, t
end

local function unpack_token(t, i) --i, p1, p2, style
	if i >= len(t) then return end
	return i, t[i], t[i + 2], t[i + 1]
end

local function next_token(t, i)
	return unpack_token(t, i and i + 2 or 0)
end

local function tokens(t)
	return next_token, t
end

local function linesize(line, buffer)
	return #buffer:getline(line) + #buffer.line_terminator
end

--project token positions originated from text at (line1, p1) back into the text,
--returning (i, line, p) for each position.
local function project_pos(t, line1, p1, buffer)
	local line = line1
	local minp, maxp = 1, linesize(line1, buffer)
	--token positions are relative to (line1, p1), not (line1, 1). shift line positions to accomodate that.
	minp = minp - p1 + 1
	maxp = maxp - p1 + 1
	local i
	return function()
		local p
		i, p = next_token_pos(t, i)
		if not i then return end
		--if p is outside the current line, advance the line until it's on it again
		while p > maxp do
			line = line + 1
			minp, maxp = maxp + 1, maxp + linesize(line, buffer)
		end
		return i, line, p - minp + 1
	end
end

--project tokens originated from text at (line1, p1) back into the text,
--returning (i, line1, p1, line2, p2, style) for each token.
local function project_tokens(t, line1, p1, buffer)
	local next_pos = project_pos(t, line1, p1, buffer)
	local i, line, p = next_pos()
	return function()
		if not i then return end
		local i2, line2, p2 = next_pos()
		if not i2 then return end
		local i1, line1, p1 = i, line, p
		i, line, p = i2, line2, p2
		return i1, line1, p1, line2, p2, t[i1 + 1]
	end
end

--project tokens originated from text at (line1, p1) back into the text,
--splitting multi-line tokens, and returning (i, line, p1, p2, style) for each line.
local function project_lines(t, line1, p1, buffer)
	local next_token = project_tokens(t, line1, p1, buffer)

	local i, line1, p1, line2, p2, style = next_token()
	local line = line1

	local function advance_token(ri, rline, rp1, rp2, rstyle)
		i, line1, p1, line2, p2, style = next_token()
		line = line1
		return ri, rline, rp1, rp2, rstyle
	end

	local function advance_line(ri, rline, rp1, rp2, rstyle)
		line = line + 1
		return ri, rline, rp1, rp2, rstyle
	end

	return function()
		if not i then return end
		if line1 == line2 then
			return advance_token(i, line, p1, p2, style)
		elseif line == line1 then
			return advance_line(i, line, p1, linesize(line, buffer) + 1, style)
		elseif line == line2 then
			return advance_token(i, line, 1, p2, style)
		else
			return advance_line(i, line, 1, linesize(line, buffer) + 1, style)
		end
	end
end

--[[
--find the last token positioned before or at the beginning of a line.
local function token_for(line, t, line1, p1, buffer)
	assert(line >= line1)
	if line == line1 then
		return 0, line1, p1
	end
	for i, line1, p1, line2, p2 in project_tokens(t, line1, p1, buffer) do
		if line2 >= line then
			return i, line1, p1
		end
	end
end
]]

--find the last whitespace token positioned before or at the beginning of a line.
local function start_token_for(line, t, line1, p1, buffer, lang0)
	local i0, line0, p0 = 0, line1, p1
	for i, line1, p1, line2, p2, style in project_tokens(t, line1, p1, buffer) do
		local lang = style:match'^(.-)_whitespace$'
		if lang then
			i0, line0, p0 = i, line1, p1
		end
		if line2 >= line then
			break
		end
	end
	return i0, line0, p0, lang0
end

--replace the tokens in t from i onwards with new tokens.
--the new tokens must represent the lexed text at that position.
local function replace_tokens(t, i, newt)
	local p0 = t[i] - 1
	for i1, p1, p2, style in tokens(newt) do
		t[i + i1 + 0] = p1 + p0
		t[i + i1 + 1] = style
		t[i + i1 + 2] = p2
	end
	--instead of deleting garbage entries, we keep them, and explicitly mark the list end.
	t.len = i + len(newt)
end

local function replace_start_tokens(st, t, line1, p1, buffer)
	local i0, line0, p0 = 0, line1, p1
	for i, line, p1, p2, style in project_lines(t, line1, p1, buffer) do
		local lang = style:match'^(.-)_whitespace$'
		if lang then
			i0, line0, p0 = i, line1, p1
		end
		st[line + 1] = {i0, line0, p0, lang}
	end
end

--given a list of tokens representing the lexed text from the beginning up to `last_line`,
--re-lex the text incrementally up to `max_line`.
local function relex(maxline, t, last_line, buffer, lang0, start_tokens)

	local line1 = last_line + 1
	local line2 = math.min(maxline, buffer:last_line())

	if line1 > line2 then
		return t, line2, start_tokens --nothing to do
	end

	t = t or {[0] = 1}

	local line0 = line1
	local i, p1, lang

	if start_tokens and start_tokens[line1] then
		i, line1, p1, lang = unpack(start_tokens[line1])
		print('cache', line0, '', i, line1, p1, lang)
	else
		i, line1, p1, lang = start_token_for(line1, t, 1, 1, buffer, lang0)
		print('comp', line0, '', i, line1, p1, lang)
	end

	local text = select_text(buffer, line1, p1, line2)
	local newt = lex_text(text, lang)

	replace_tokens(t, i, newt)

	--start_tokens = start_tokens or {}
	--replace_start_tokens(start_tokens, newt, line1, p1, buffer)

	return t, line2--, start_tokens
end

--highlighter object

local hl = {}

function hl:new(buffer, lang)
	return glue.inherit({buffer = buffer, lang = lang, last_line = 0}, self)
end

function hl:invalidate(line)
	self.last_line = math.min(self.last_line, line - 1)
end

function hl:relex(maxline)
	self.tokens, self.last_line = relex(maxline, self.tokens, self.last_line, self.buffer, self.lang)
end

function hl:lines()
	return project_lines(self.tokens, 1, 1, self.buffer)
end


if not ... then

	if false then

		local text = [==[
--[[
]]
A
]==]

		local buffer = require'codedit_buffer'; require'codedit_undo'
		local view = {tabsize = 3, invalidate = function() end}
		local editor = {getstate = function() end, setstate = function() end}
		local buf = buffer:new(editor, view, text)

		local s = select_text(buf, 1, 1)
		local t = lex_text(s, 'lua')

		for i, p1, p2, style in tokens(t) do
			pp(i, style, p1, p2, s:sub(p1, p2 - 1))
		end

		print('ti', 'i', 'j', 'line1', 'p1', 'line2', 'p2', 'style')
		for ti, line1, p1, line2, p2 in project_tokens(t, 1, 1, buf) do
			local ti, i, j, style = unpack_token(t, ti)
			pp(ti, i, j, line1, p1, line2, p2, style)
		end

	else

		---if not ... then require'codedit_demo' end

	end

end

return {
	relex = relex,
	tokens = project_lines,
}

