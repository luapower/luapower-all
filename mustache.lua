
--full-spec mustache parser and bytecode-based renderer.
--Written by Cosmin Apreutesei. Public Domain.

local push = table.insert
local pop = table.remove
local _ = string.format

--for a string, return a function that given a char position in the
--string returns the line and column numbers corresponding to that position.
local function textpos(s)
	--collect char indices of all the lines in s, incl. the index at #s + 1
	local t = {}
	for i in s:gmatch'()[^\r\n]*\r?\n?' do
		t[#t+1] = i
	end
	assert(#t >= 2)
	return function(i)
		--do a binary search in t to find the line
		assert(i > 0 and i <= #s + 1)
		local min, max = 1, #t
		while true do
			local k = math.floor(min + (max - min) / 2)
			if i >= t[k] then
				if k == #t or i < t[k+1] then --found it
					return k, i - t[k] + 1
				else --look forward
					min = k
				end
			else --look backward
				max = k
			end
		end
	end
end

local function raise(s, i, err, ...)
	err = _(err, ...)
	local where
	if s then
		if i then
			local pos = textpos(s)
			local line, col = pos(i)
			where = _('line %d, col %d', line, col)
		else
			where = 'eof'
		end
		err = _('error at %s: %s', where, err)
	else
		err = _('error: %s', err)
	end
	error(err)
end

local function trim(s) --from glue
	local from = s:match('^%s*()')
	return from > #s and '' or s:match('.*%S', from)
end

--calls parse(char_index, token_type, token) for each token in the string.
--tokens can be: ('var', name, [modifier]) or ('text', s).
--for 'var' tokens, modifiers can be: '&', '#', '^', '>', '/'.
--set delimiters and comments are dealt with in the tokenizer.
local function tokenize(s, parse)
	local d1 = '{{' --start delimiter
	local d2 = '}}' --end delimiter
	local i = 1
	while i <= #s do
		local j = s:find(d1, i, true) -- {{
		if j then
			if j > i then --there's text before {{
				parse(i, 'text', s:sub(i, j - 1))
				i = j
			end
			local i0 = i --position of {{
			i = i + #d1
			local modifier = s:match('^[!{&#%^/>=]', i)
			local d2_now = d2
			if modifier then
				i = i + 1
				if modifier == '{' then
					d2_now = '}'..d2 --expect }}}
					modifier = '&' --merge { and & cases
				elseif modifier == '=' then --set delimiter
					d1, d2 = s:match('^([^%s]+)%s+([^=]+)=', i)
					if not d1 or trim(d1) == '' or trim(d2) == '' then
						raise(s, i, 'invalid set delimiter')
					end
				end
			end
			local j = s:find(d2_now, i, true) -- }} or }}}
			if not j then
				raise(s, nil, d2_now..' expected')
			end
			if modifier == '=' or modifier == '!' then
				i = j + #d2_now
			else
				local var = s:sub(i, j - 1) --text before }}, could be empty
				i = j + #d2_now
				var = trim(var)
				if var == '' or var:find'%s' then
					raise(s, i0, 'invalid name %s', var)
				end
				parse(i0, 'var', var, modifier)
			end
		else --leftover text
			parse(i, 'text', s:sub(i))
			i = #s + 1
		end
	end

end

local function parse_var(var) --parse 'a.b.c' to {'a', 'b', 'c'}
	if var == '.' or not var:find('.', 1, true) then
		return var --simple var, leave it
	end
	local path = {}
	for s in var:gmatch'[^%.]+' do --split by `.`
		path[#path+1] = s
	end
	return path
end

--compile a template to a program that can be interpreted with render().
--the program is a list of commands with 0, 1, or 2 args as follows:
--  'text', s            : constant text, render it as is
--  'html', var          : substitute var and render it as html, escaped
--  'string', var        : substitute var and render it as is, unescaped
--  'iter', var, nextpc  : section; nexpc is the cmd index after the section
--  'ifnot', var, nextpc : inverted section
--  'end'                : end of section or inverted section
--  'render', partial    : render partial
local function compile(template)

	local prog = {template = template}
	local function cmd(cmd, arg1, arg2)
		prog[#prog+1] = cmd
		if arg1 then prog[#prog+1] = arg1 end
		if arg2 then prog[#prog+1] = arg2 end
	end

	local section_stack = {} --stack of unparsed section names
	local nextpc_stack = {} --stack of indices where nextpc needs to be set

	tokenize(template, function(i, what, s, modifier)
		if what == 'text' then
			cmd('text', s)
		elseif what == 'var' then
			if not modifier then
				cmd('html', parse_var(s))
			elseif modifier == '&' then --no escaping
				cmd('string', parse_var(s))
			elseif modifier == '#' or modifier == '^' then --section
				local c = modifier == '#' and 'iter' or 'ifnot'
			 	cmd(c, parse_var(s), 0) --we don't know nextpc yet so we set 0
				push(section_stack, s)
				push(nextpc_stack, #prog) --position of the above 0
			elseif modifier == '/' then --close section
				local expected = pop(section_stack)
				if expected ~= s then
					raise(template, i,
						'expected {{/%s}} but {{/%s}} found', expected, s)
				end
				cmd('end')
				local nextpc_index = pop(nextpc_stack)
				prog[nextpc_index] = #prog + 1 --set nextpc on the last iter cmd
			elseif modifier == '>' then --partial
				cmd('render', s)
			end
		end
	end)

	if #section_stack > 0 then
		local sections = table.concat(section_stack, ', ')
		raise(template, nil, 'unclosed sections: %s', sections)
	end

	return prog
end

local function dump(prog) --dump bytecode (only for debugging)
	local pp = require'pp'
	local function str(var)
		return type(var) == 'table' and table.concat(var, '.') or var
	end
	local pc = 1
	while pc <= #prog do
		local cmd = prog[pc]
		if cmd == 'text' then
			local s = pp.format(prog[pc+1])
			if #s > 50 then
				s = s:sub(1, 50-3)..'...'
			end
			print(_('%-4d %-6s %s', pc, cmd, s))
			pc = pc + 2
		elseif cmd == 'html' or cmd == 'string' or cmd == 'render' then
			print(_('%-4d %-6s %-12s', pc, cmd, str(prog[pc+1])))
			pc = pc + 2
		elseif cmd == 'iter' or cmd == 'ifnot' then
			print(_('%-4d %-6s %-12s nextpc: %d', pc, cmd, str(prog[pc+1]), prog[pc+2]))
			pc = pc + 3
		elseif cmd == 'end' then
			print(_('%-4d %-6s', pc, 'end'))
			pc = pc + 1
		else
			assert(false)
		end
	end
end

local escapes = {
	['&']  = '&amp;',
	['\\'] = '&#92;',
	['"']  = '&quot;',
	['<']  = '&lt;',
	['>']  = '&gt;',
}
local function escape_html(v)
	return v:gsub('[&\\"<>]', escapes) or v
end

--check if a value is considered valid, compatible with mustache.js.
local function istrue(v)
	if type(v) == 'table' then
		return next(v) ~= nil
	else
		return v and v ~= '' and v ~= 0 and v ~= '0' or false
	end
end

--check if a value is considered a valid list.
local function islist(t)
	return type(t) == 'table' and #t > 0
end

local function render(prog, context, getpartial, write)

	if type(prog) == 'string' then --template not compiled, compile it
		prog = compile(prog)
	end

	if type(getpartial) == 'table' then --partials table given, build getter
		local partials = getpartial
		getpartial = function(name)
			return partials[name]
		end
	end

	local outbuf
	if not write then --writer not given, do buffered output
		outbuf = {}
		write = function(s)
			outbuf[#outbuf+1] = s
		end
	end

	local function out(s)
		if s == nil then return end
		write(tostring(s))
	end

	local ctx_stack = {}

	local function lookup(var, i) --lookup a var in the context hierarchy
		local val = ctx_stack[i][var]
		if val ~= nil then --var found
			return val
		end
		if i == 1 then --top context
			return nil
		end
		return lookup(var, i-1) --check parent
	end

	local function resolve(var) --get the value of a var from the view
		if #ctx_stack == 0 then
			return nil --no view
		end
		local val
		local ctx = ctx_stack[#ctx_stack]
		if var == '.' then
			val = ctx
		elseif type(var) == 'table' then --'a.b.c' parsed as {'a', 'b', 'c'}
			val = lookup(var[1], #ctx_stack)
			for i=1,#var-1 do
				if type(val) ~= 'table' then
					raise(nil, nil, 'table expected for %s, got %s',
						var[i], type(val))
				end
				val = val[var[i]]
			end
		else --simple var
			val = lookup(var, #ctx_stack)
		end
		if type(val) == 'function' then --callback
			val = val()
		end
		return val
	end

	local pc = 1 --program counter
	local function pull()
		local val = prog[pc]
		pc = pc + 1
		return val
	end

	local iter_stack = {}
	local HASH, COND = {}, {} --hashmap and conditional-type iterator markers
	local function iter(val, nextpc)
		if islist(val) then --list value, iterate it
			push(iter_stack, {list = val, n = 1, pc = pc})
			push(ctx_stack, val[1])
		else
			if type(val) == 'table' then --hash map, set as context
				push(iter_stack, HASH)
				push(ctx_stack, val)
			else --conditional value, preserve context
				push(iter_stack, COND)
			end
		end
	end

	local function enditer()
		local iter = iter_stack[#iter_stack]
		if iter.n then --list
			iter.n = iter.n + 1
			if iter.n <= #iter.list then
				ctx_stack[#ctx_stack] = iter.list[iter.n]
				pc = iter.pc --loop
			end
		else --hashmap or conditional
			pop(iter_stack)
			if iter == HASH then --hashmap
				pop(ctx_stack)
			end
		end
	end

	push(ctx_stack, context)

	while pc <= #prog do
		local cmd = pull()
		if cmd == 'text' then
			out(pull())
		elseif cmd == 'html' then
			local val = resolve(pull())
			if val ~= nil then
				out(escape_html(tostring(val)))
			end
		elseif cmd == 'string' then
			out(resolve(pull()))
		elseif cmd == 'iter' or cmd == 'ifnot' then
			local val = resolve(pull())
			local nextpc = pull()
			if cmd == 'ifnot' then
				val = not istrue(val)
			end
			if istrue(val) then --valid section value, iterate it
				iter(val, nextpc)
			else
				pc = nextpc --skip section entirely
			end
		elseif cmd == 'end' then
			enditer() --loop back or pop iteration
		end
	end

	if outbuf then
		return table.concat(outbuf)
	end
end

if not ... then

local function test(template, view, partials)
	local prog = compile(template)
	dump(prog)
	print(render(prog, view, partials))
end

test('{{var}} world!', {var = 'hello (a & b)'})
test('{{{var}}} world!', {var = 'hello'})
test('{{& var }} world!', {var = 'hello'})
test('{{=$$  $$=}}$$ var $$ world!$$={{  }}=$$ and {{var}} again!', {var = 'hello'})
test('{{#a}}invisible{{/a}}{{#b}}visible{{/b}}', {a = false, b=true})
test('{{^a}}invisible{{/a}}{{^b}}visible{{/b}}', {a = true, b=false})
test('{{#a}}<{{b}}> {{/a}}', {a = {{b = 1}, {b = 2}, {b = 3}}})
test('{{#a}}<{{.}}> {{/a}}', {a = {1, 2, 3}})
test('{{undefined}}')
test('{{{undefined}}}')
test('{{&undefined}}')
test('{{&undefined}}')
test('{{#a}}{{undefined}}{{/a}}', {a = {b = 1}})

--test('{{#a}}{{b}}{{/a}}', {b=1, a = {b = 2}})
--test('{{#a}}{{b}}{{/a}}', {b=1, a = {{b = 2}, {c = 5}}})

end

return {
	compile = compile,
	render = render,
	dump = dump,
}

