--submodule of codedit_str for text reflowing.
local str = require'codedit_str'
local tabs = require'codedit_tabs'
local glue = require'glue'

--split a list of text lines into paragraphs. paragraphs break at empty lines.
--a paragraph is a list of lines plus the field indent.
function str.paragraphs(lines, tabsize)
	local paragraphs = {}
	local paragraph
	for _,line in ipairs(lines) do
		local indent_col = str.next_nonspace(line)
		if not paragraph or not indent_col then --first paragraph, or empty line: start a new paragraph
			paragraph = {
				indent = str.sub(line, 1, indent_col and indent_col - 1), --paragraph indent whitespace, verbatim
			}
			table.insert(paragraphs, paragraph)
		end
		table.insert(paragraph, line)
	end
	return paragraphs
end

--given a line of text, break the text at spaces and return the resulting list of words.
--multiple consecutive spaces and tabs are treated as one space.
function str.line_words(line, words)
	local words = words or {}
	local starti, lasti
	for i in str.byte_indices(line) do
		if not starti and not str.isspace(line, i) then --start a word
			starti = i
		elseif starti and str.isspace(line, i) then --end the word
			table.insert(words, line:sub(starti, lasti))
			starti = nil
		--[[
		--TODO: break at hypenation.
		elseif starti and str.isascii(line, i, '-') then --end the word
			table.insert(words, line:sub(starti, i))
			starti = nil
		]]
		end
		lasti = i
	end
	if starti then
		table.insert(words, line:sub(starti))
	end
	return words
end

--given a list of text lines, break the text into words.
function str.words(lines, words)
	for _,line in ipairs(lines) do
		words = str.line_words(line, words)
	end
	return words
end

--word wrapping algorithms for word wrapping a list of words over a maximum allowed line width.

local wrap = {} --{name = f(words, line_width)}

function str.wrap(words, line_width, how)
	return wrap[how](words, line_width)
end

--word wrapping that produces the minimum amount of lines.
--TODO: make it work with mandatory or optional hypenation
function wrap.greedy(words, line_width)
	local lines = {}
	local space_left = line_width
	local i1 = 1
	local lasti
	for i,word in ipairs(words) do
		local word_width = str.len(word)
		if word_width + 1 > space_left then
			local only_word = i1 == i
			table.insert(lines, table.concat(words, ' ', i1, only_word and i1 or i - 1))
			i1 = only_word and i + 1 or i
			space_left = line_width - word_width
		else
			space_left = space_left - (word_width + 1)
		end
		lasti = i
	end
	if i1 <= #words then
		table.insert(lines, table.concat(words, ' ', i1, lasti))
	end
	return lines
end

--TODO: word wrapping that minimizes the difference between line lengths.
function wrap.knuth(words, line_width)
	error'NYI'
--[[
Add start of paragraph to list of active breakpoints
For each possible breakpoint (space) B_n, starting from the beginning:
   For each breakpoint in active list as B_a:
      If B_a is too far away from B_n:
          Delete B_a from active list
      else
          Calculate badness of line from B_a to B_n
          Add B_n to active list
          If using B_a minimizes cumulative badness from start to B_n:
             Record B_a and cumulative badness as best path to B_n

The result is a linked list of breakpoints to use.

The badness of lines under consideration can be calculated like this:

Each space is assigned a nominal width, a strechability, and a shrinkability.
The badness is then calculated as the ratio of stretching or shrinking used,
relative to what is allowed, raised e.g. to the third power (in order to
ensure that several slightly bad lines are prefered over one really bad one)
]]
end

--paragraph justification algorithms over word-wrapped lines

local align = {} --alignment algorithms: {name = f(lines, line_width)}

function str.align(lines, line_width, how)
	return align[how](lines, line_width)
end

function align.left(lines, line_width)
	return lines
end

--indent the lines so that they right-aligned to line_width
function align.right(lines, line_width)
	local out_lines = {}
	for i,line in ipairs(lines) do
		out_lines[i] = string.rep(' ', line_width - str.len(line)) .. line
	end
	return out_lines
end

--generate a random number that is different than other random numbers
local function unique_random_number(min, max, numbers, retries)
	while true do
		local n = math.random(min, max)
		if not numbers[n] or retries == 0 then
			return n
		end
		retries = retries - 1
	end
end

--add unique random numbers
local function add_random_places(places, count, min, max)
	assert(count <= max - min + 1, 'list too large for the range') --number wouldn't be unique
	local retries = 2 * count
	for _ = 1, count do
		local pos = unique_random_number(min, max, places, retries)
		places[pos] = (places[pos] or 0) + 1
		count = count - 1
	end
	return count
end

--add a place after each punctuation character
local function add_punctuation_places(places, count, words)
	for pos = 2, #words do
		if count < 1 then break end
		local word = words[pos - 1]
		local i = str.prev(word)
		if str.isword(word, i, '^[.!?,;]') then
			places[pos] = (places[pos] or 0) + 1
			count = count - 1
		end
	end
	return count
end

--for each line, add spaces to existing words at random until lines have the same width.
function align.justify(lines, line_width)
	local out_lines = {}
	math.randomseed(0) --reset the random sequence to get the same results for the same text
	for i = 1, #lines - 1 do
		local line = lines[i]
		local words = str.line_words(line)
		local spaces = line_width - str.len(line) --total number of spaces to be distributed between words
		local places = #words - 1 --number of word breaks available to distribute these spaces at
		local min_spaces = math.floor(spaces / places) --min. number of spaces that each word break should get
		local leftover_spaces = spaces - min_spaces * places --number of leftover spaces to be added over min_spaces

		if places > 0 then
			--decide on which positions to put the leftover spaces.
			local places = {}
			leftover_spaces = add_punctuation_places (places, leftover_spaces, words)
			leftover_spaces = add_random_places      (places, leftover_spaces, 2, #words)
			assert(leftover_spaces == 0)

			for pos = 2, #words do
				words[pos] = string.rep(' ', min_spaces + (places[pos] or 0)) .. words[pos]
			end
		end

		table.insert(out_lines, table.concat(words, ' '))
	end
	table.insert(out_lines, lines[#lines])
	return out_lines
end

function str.indent(lines, indent)
	local out_lines = {}
	for i,line in ipairs(lines) do
		out_lines[i] = indent .. line
	end
	return out_lines
end

function str.reflow(lines, line_width, tabsize, align, wrap)
	local paragraphs = str.paragraphs(lines, tabsize)
	local out_lines = {}
	for i,paragraph in ipairs(paragraphs) do
		local words = str.words(paragraph)
		if #words > 0 then
			words[1] = paragraph.indent .. words[1]
		end
		local lines = str.wrap(words, line_width, wrap)
		local lines = str.align(lines, line_width, align)
		if i > 1 then
			table.insert(out_lines, '')
		end
		glue.extend(out_lines, lines)
	end
	return out_lines
end


if not ... then require'codedit_demo' end
