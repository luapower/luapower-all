
--Lua lexer in C with extensible Lua parser.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'lx_test'; return end

local ffi = require'ffi'
local C = ffi.load'lx'
local M = {C = C}
local push, pop, concat = table.insert, table.remove, table.concat

local function inherit(t)
	local dt = {}; for k,v in pairs(t) do dt[k] = v end
	return setmetatable(dt, {parent = t})
end

local function getparent(t)
	return getmetatable(t).parent
end

--number parsing options
M.STRSCAN_OPT_TOINT = 0x01
M.STRSCAN_OPT_TONUM = 0x02
M.STRSCAN_OPT_IMAG  = 0x04
M.STRSCAN_OPT_LL    = 0x08
M.STRSCAN_OPT_C     = 0x10

ffi.cdef[[
/* Token types. */
enum {
	TK_EOF = -100, TK_ERROR,
	TK_NUM, TK_IMAG, TK_INT, TK_U32, TK_I64, TK_U64, /* number types */
	TK_NAME, TK_STRING, TK_LABEL,
	TK_EQ, TK_LE, TK_GE, TK_NE, TK_DOTS, TK_CONCAT,
	TK_FUNC_PTR, TK_LSHIFT, TK_RSHIFT,
};

/* Error codes. */
enum {
	LX_ERR_NONE    ,
	LX_ERR_XLINES  , /* chunk has too many lines */
	LX_ERR_XNUMBER , /* malformed number */
	LX_ERR_XLCOM   , /* unfinished long comment */
	LX_ERR_XLSTR   , /* unfinished long string */
	LX_ERR_XSTR    , /* unfinished string */
	LX_ERR_XESC    , /* invalid escape sequence */
	LX_ERR_XLDELIM , /* invalid long string delimiter */
};

typedef int LX_Token;
typedef struct LX_State LX_State;

typedef const char* (*LX_Reader) (void*, size_t*);

LX_State* lx_state_create            (LX_Reader, void*);
LX_State* lx_state_create_for_file   (struct FILE*);
LX_State* lx_state_create_for_string (const char*, size_t);
void      lx_state_free              (LX_State*);

LX_Token lx_next          (LX_State*);
char*    lx_string_value  (LX_State*, int*);
double   lx_double_value  (LX_State*);
int32_t  lx_int32_value   (LX_State*);
uint64_t lx_uint64_value  (LX_State*);
int      lx_error         (LX_State*);
int      lx_line          (LX_State*);
int      lx_linepos       (LX_State*);
int      lx_filepos       (LX_State*);
int      lx_end_line      (LX_State*);
int      lx_end_filepos   (LX_State*);

void lx_set_strscan_opt   (LX_State*, int);
]]

local intbuf = ffi.new'int[1]'
local function to_str(ls)
	local s = C.lx_string_value(ls, intbuf)
	return ffi.string(s, intbuf[0])
end

local msg = {
	[C.LX_ERR_XLINES ] = 'chunk has too many lines';
	[C.LX_ERR_XNUMBER] = 'malformed number';
	[C.LX_ERR_XLCOM  ] = 'unfinished long comment';
	[C.LX_ERR_XLSTR  ] = 'unfinished long string';
	[C.LX_ERR_XSTR   ] = 'unfinished string';
	[C.LX_ERR_XESC   ] = 'invalid escape sequence';
	[C.LX_ERR_XLDELIM] = 'invalid long string delimiter';
}
local function errmsg(ls)
	return msg[ls:error()]
end

ffi.metatype('LX_State', {__index = {
	free     = C.lx_state_free;
	next     = C.lx_next;
	string   = to_str;
	num      = C.lx_double_value;
	int      = C.lx_int32_value;
	u64      = C.lx_uint64_value;
	error    = C.lx_error;
	errmsg   = errmsg;
	line     = C.lx_line;
	linepos  = C.lx_linepos;
	filepos  = C.lx_filepos;
	end_line = C.lx_end_line;
	end_filepos = C.lx_end_filepos;
}})

--lexer API inspired by Terra's lexer for extension languages.

local lua_keywords = {}
for i,k in ipairs{
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'goto', 'if',
	'in', 'local', 'nil', 'not', 'or', 'repeat',
	'return', 'then', 'true', 'until', 'while',
	'import', --extension
} do
	lua_keywords[k] = true
end

local token_names = {
	[C.TK_STRING  ] = '<string>',
	[C.TK_LABEL   ] = '::',
	[C.TK_NUM     ] = '<number>',
	[C.TK_IMAG    ] = '<imag>',
	[C.TK_INT     ] = '<int>',
	[C.TK_U32     ] = '<u32>',
	[C.TK_I64     ] = '<i64>',
	[C.TK_U64     ] = '<u64>',
	[C.TK_EQ      ] = '==',
	[C.TK_LE      ] = '<=',
	[C.TK_GE      ] = '>=',
	[C.TK_NE      ] = '~=',
	[C.TK_DOTS    ] = '...',
	[C.TK_CONCAT  ] = '..',
	[C.TK_FUNC_PTR] = '->', --extension
	[C.TK_LSHIFT  ] = '<<', --extension
	[C.TK_RSHIFT  ] = '>>', --extension
	[C.TK_EOF     ] = '<eof>',
}

function M.lexer(arg, filename)

	local lx = {filename = filename} --polymorphic lexer object

	local read, ls
	if type(arg) == 'string' then
		lx.s = arg --anchor it
		ls = C.lx_state_create_for_string(arg, #arg)
	elseif type(arg) == 'function' then
		read = ffi.cast('LX_Reader', arg)
		ls = C.lx_state_create(read, nil)
	else
		ls = C.lx_state_create_for_file(arg)
	end

	function lx.free()
		if read then read:free() end
		ls:free()
	end

	--lexer API ---------------------------------------------------------------

	local keywords = lua_keywords --reserved words in current scope

	local efp0, eln0 --end filepos of last token
	local tk, v, ln, eln, lp, fp, efp
	--^^current token type, value, line, line at token end, line pos, file pos, file pos at token end.
	local tk1 --next token

	local function line()
		if ln == nil then
			ln = ls:line()
			lp = ls:linepos()
		end
		return ln, lp
	end

	local function filepos() fp = fp or ls:filepos(); return fp end
	local function end_line() eln = eln or ls:end_line(); return eln end
	local function end_filepos() efp = efp or ls:end_filepos(); return efp end

	--convert '<name>' tokens for reserved words to the actual keyword.
	--also, convert token codes to Lua strings.
	--this makes lexing 2x slower but simplifies the parsing API.
	local function token(tk)
		if tk >= 0 then
			return string.char(tk)
		elseif tk == C.TK_NAME then
			v = ls:string()
			return keywords[v] and v or '<name>'
		else
			return token_names[tk] or tk
		end
	end

	local function val() --get the parsed value of literal tokens.
		if v == nil then
			if tk == '<name>' or tk == '<string>' then
				v = ls:string()
			elseif tk == '<number>' then
				v = ls:num()
			elseif tk == '<imag>' then
				error'NYI'
			elseif tk == '<int>' then
				v = ls:int()
			elseif tk == '<u64>' then
				v = ls:u64()
			else
				v = tk
			end
		end
		return v
	end

	local ntk = 0

	local function next()
		efp0 = end_filepos()
		eln0 = end_line()
		tk = tk1 or token(ls:next())
		tk1, v, ln, eln, lp, fp, efp = nil
		ntk = ntk + 1
		--print(tk, filepos(), line())
		return tk
	end

	local function lookahead()
		assert(tk1 == nil)
		val(); line(); filepos(); end_line(); end_filepos()
		--^^save current state because ls:next() changes it.
		tk1 = token(ls:next())
		return tk1
	end

	local function cur() return tk end

	local function nextif(tk1)
		if tk == tk1 then
			return next()
		else
			return false
		end
	end

	local function error(msg) --stub
		local line, pos = line()
		_G.error(string.format('%s:%d:%d: %s', filename or '@string', line, pos, msg), 0)
	end

	local function errorexpected(what)
		error(what..' expected')
	end

	local function expect(tk1)
		local tk = nextif(tk1)
		if not tk then
			errorexpected(tk1)
		end
		return tk
	end

	local function expectval(tk1)
		if tk ~= tk1 then
			errorexpected(tk1)
		end
		local s = val()
		return s, next()
	end

	local function expectmatch(tk1, openingtk, ln, lp)
		local tk = nextif(tk1)
		if not tk then
			if line() == ln then
				errorexpected(tostring(tk1))
			else
				error(string.format('%s expected (to close %s at %d:%d)',
					tostring(tk1), tostring(openingtk), ln, lp))
			end
		end
		return tk
	end

	--language extension API --------------------------------------------------

	local expr, block --fw. decl.

	local scope_level = 0
	local lang_stack = {} --{lang1,...}
	local imported = {} --{lang_name->true}
	local entrypoints = {statement = {}, expression = {}} --{token->lang}

	local function push_entrypoints(lang, kind)
		entrypoints[kind] = inherit(entrypoints[kind])
		local tokens = lang.entrypoints[kind]
		if tokens then
			for i,tk in ipairs(tokens) do
				entrypoints[kind][tk] = lang
			end
		end
	end

	local function pop_entrypoints(kind)
		entrypoints[kind] = getparent(entrypoints[kind])
	end

	function lx.import(name) --stub
		return require(name).lang(lx)
	end

	local langs = {}

	local function import(lang_name)
		if imported[lang_name] then return end --already in scope
		local lang = langs[lang_name]
		if not lang then
			lang = assert(lx.import(lang_name))
			langs[lang_name] = lang
		end
		push(lang_stack, lang)
		imported[lang_name] = true
		lang.scope_level = scope_level
		lang.name = lang_name
		push_entrypoints(lang, 'statement')
		push_entrypoints(lang, 'expression')
		keywords = inherit(keywords)
		if lang.keywords then
			for i,k in ipairs(lang.keywords) do
				keywords[k] = true
			end
		end
	end

	local refs

	function lx.ref(expr)
		assert(expr)
		refs[#refs+1] = expr
		return #refs
	end

	function lx.luaexpr()
		local i0 = filepos()
		expr()
		local i1 = efp0
		local s = lx.s:sub(i0, i1-1)
		local ref_id = lx.ref(s)
		return function(...)
			return (select(ref_id, ...))
		end
	end

	function lx.luastats()

	end

	local function enter_scope()
		scope_level = scope_level + 1
	end

	local function exit_scope()
		for i = #lang_stack, 1, -1 do
			local lang = lang_stack[i]
			if lang.scope_level == scope_level then
				lang_stack[i] = nil
				imported[lang.name] = false
				lang.scope_level = false
				pop_entrypoints'statement'
				pop_entrypoints'expression'
				keywords = getparent(keywords)
			else
				assert(lang.scope_level < scope_level)
				break
			end
		end
		scope_level	= scope_level - 1
	end

	local subst = {} --{subst1,...}

	local function lang_expr(lang, kw, stmt)
		refs = {}
		local i0, line0 = filepos(), line()
		local cons, names = lang:expression(kw, stmt)
		local i1, line1 = efp0, eln0
		push(subst, {
			cons = cons, refs = refs, names = names, stmt = stmt,
			i = i0, len = i1 - i0, lines = line1 - line0,
		})
		refs = nil
	end

	--Lua parser --------------------------------------------------------------

	local function isend() --check for end of block
		return tk == 'else' or tk == 'elseif' or tk == 'end'
			or tk == 'until' or tk == '<eof>'
	end

	local unary_priority = {
		['not'] = 7 * 2,
		['-'  ] = 7 * 2,
		['#'  ] = 7 * 2,
	}

	local binary_priority = {
		['^'  ] = 8 * 2,

		--unary priority: 7 * 2

		['*'  ] = 6 * 2,
		['/'  ] = 6 * 2,
		['%'  ] = 6 * 2,

		['+'  ] = 5 * 2,
		['-'  ] = 5 * 2,

		['..' ] = 4 * 2,

		['==' ] = 3 * 2,
		['~=' ] = 3 * 2,
		['<'  ] = 3 * 2,
		['<=' ] = 3 * 2,
		['>'  ] = 3 * 2,
		['>=' ] = 3 * 2,

		['and'] = 2 * 2,

		['or' ] = 1 * 2,
	}

	local right_associative = {
		['^' ] = true,
		['..'] = true,
	}

	local function params() --(name,...[,...])
		expect'('
		if tk ~= ')' then
			repeat
				if tk == '<name>' then
					next()
				elseif tk == '...' then
					next()
					break
				else
					errorexpected'<name> or "..."'
				end
			until not nextif','
		end
		expect')'
	end

	local function body(line, pos) --(params) block end
		params()
		block()
		if tk ~= 'end' then
			expectmatch('end', 'function', line, pos)
		end
		next()
	end

	local function name()
		expect'<name>'
	end

	local function expr_field() --.:name
		next()
		name()
	end

	local function expr_bracket() --[expr]
		next()
		expr()
		expect']'
	end

	local function expr_table() --{[expr]|name=expr,;...}
		local line, pos = line()
		expect'{'
		while tk ~= '}' do
			if tk == '[' then
				expr_bracket()
				expect'='
			elseif tk == '<name>' and lookahead() == '=' then
				name()
				expect'='
			end
			expr()
			if not nextif',' and not nextif';' then break end
		end
		expectmatch('}', '{', line, pos)
	end

	local function expr_list() --expr,...
		expr()
		while nextif',' do
			expr()
		end
	end

	local function args() --(expr,...)|{table}|string
		if tk == '(' then
			local line, pos = line()
			next()
			if tk == ')' then --f()
			else
				expr_list()
			end
			expectmatch(')', '(', line, pos)
		elseif tk == '{' then
			expr_table()
		elseif tk == '<string>' then
			next()
		else
			errorexpected'function arguments'
		end
	end

	local function expr_primary() --(expr)|name .name|[expr]|:nameargs|args ...
		local iscall
		--parse prefix expression.
		if tk == '(' then
			local line, pos = line()
			next()
			expr()
			expectmatch(')', '(', line, pos)
		elseif tk == '<name>' then
			next()
		else
			error'unexpected symbol'
		end
		while true do --parse multiple expression suffixes.
			if tk == '.' then
				expr_field()
				iscall = false
			elseif tk == '[' then
				expr_bracket()
				iscall = false
			elseif tk == ':' then
				next()
				name()
				args()
				iscall = true
			elseif tk == '(' or tk == '<string>' or tk == '{' then
				args()
				iscall = true
			else
				break
			end
		end
		return iscall
	end

	local function expr_simple() --literal|...|{table}|function(params) end|expr_primary
		if tk == '<number>' or tk == '<imag>' or tk == '<int>' or tk == '<u32>'
			or tk == '<i64>' or tk == '<u64>' or tk == '<string>' or tk == 'nil'
			or tk == 'true' or tk == 'false' or tk == '...'
		then --literal
			next()
		elseif tk == '{' then --{table}
			expr_table()
		elseif tk == 'function' then --function body
			local line, pos = line()
			next()
			body(line, pos)
		else
			local lang = entrypoints.expression[tk]
			if lang then --entrypoint token for extension language.
				lang_expr(lang, tk)
			else
				expr_primary()
			end
		end
	end

	--parse binary expressions with priority higher than the limit.
	local function expr_binop(limit)
		local pri = unary_priority[tk]
		if pri then --unary operator
			next()
			expr_binop(pri)
		else
			expr_simple()
		end
		local pri = binary_priority[tk]
		while pri and pri > limit do
			next()
			--parse binary expression with higher priority.
			local op = expr_binop(pri - (right_associative[tk] and 1 or 0))
			pri = binary_priority[op]
		end
		return tk --return unconsumed binary operator (if any).
	end

	function expr() --parse expression.
		expr_binop(0) --priority 0: parse whole expression.
	end

	local function assignment() --expr_primary,... = expr,...
		if nextif',' then --collect LHS list and recurse upwards.
			expr_primary()
			assignment()
		else --parse RHS.
			expect'='
			expr_list()
		end
	end

	local function label() --::name::
		next()
		name()
		expect'::'
		--recursively parse trailing statements: labels and ';' (Lua 5.2 only).
		while true do
			if tk == '::' then
				label()
			elseif tk == ';' then
				next()
			else
				break
			end
		end
	end

	--parse a statement. returns true if it must be the last one in a chunk.
	local function stmt()
		if tk == 'if' then --if expr then block [elseif expr then block]... [else block] end
			local line, pos = line()
			next()
			expr()
			expect'then'
			block()
			while tk == 'elseif' do --elseif expr then block...
				next()
				expr()
				expect'then'
				block()
			end
			if tk == 'else' then --else block
				next()
				block()
			end
			expectmatch('end', 'if', line, pos)
		elseif tk == 'while' then --while expr do block end
			local line, pos = line()
			next()
			expr()
			expect'do'
			block()
			expectmatch('end', 'while', line, pos)
		elseif tk == 'do' then  --do block end
			local line, pos = line()
			next()
			block()
			expectmatch('end', 'do', line, pos)
		elseif tk == 'for' then
			--for name = expr, expr [,expr] do block end
			--for name,... in expr,... do block end
			local line, pos = line()
			next()
			name()
			if tk == '=' then -- = expr, expr [,expr]
				next()
				expr()
				expect','
				expr()
				if nextif',' then expr() end
			elseif tk == ',' or tk == 'in' then -- ,name... in expr,...
				while nextif',' do
					name()
				end
				expect'in'
				expr_list()
			else
				errorexpected'"=" or "in"'
			end
			expect'do'
			block()
			expectmatch('end', 'for', line, pos)
		elseif tk == 'repeat' then --repeat block until expr
			local line, pos = line()
			next()
			block(false)
			expectmatch('until', 'repeat', line, pos)
			expr() --parse condition (still inside inner scope).
			exit_scope()
		elseif tk == 'function' then --function name[.name...][:name] body
			local line, pos = line()
			next()
			name()
			while tk == '.' do --.name...
				expr_field()
			end
			if tk == ':' then --:name
				expr_field()
			end
			body(line, pos)
		elseif tk == 'local' then
			--local function name body
			--local name,...[=expr,...]
			local line, pos = line()
			next()
			if nextif'function' then
				name()
				body(line, pos)
			else
				local lang = entrypoints.statement[tk]
				if lang then --entrypoint token for extension language.
					lang_expr(lang, tk, true)
				else
					repeat --name,...
						name()
					until not nextif','
					if nextif'=' then -- =expr,...
						expr_list()
					end
				end
			end
		elseif tk == 'return' then --return [expr,...]
			next()
			if not (isend() or tk == ';') then
				expr_list()
			end
			return true --must be last
		elseif tk == 'break' then
			next()
			--return true: must be last in Lua 5.1
		elseif tk == ';' then
			next()
		elseif tk == '::' then
			label()
		elseif tk == 'goto' then --goto name
			next()
			name()
		elseif tk == 'import' then --import 'lang_name'
			local i0, line0 = filepos(), line()
			next()
			if tk ~= '<string>' then
				errorexpected'<string>'
			end
			import(ls:string())
			next() --calling next() after import() which alters the keywords table.
		else
			local lang = entrypoints.statement[tk]
			if lang then --entrypoint token for extension language.
				lang_expr(lang, tk, true)
			elseif not expr_primary() then --function call or assignment
				assignment()
			end
		end
		return false
	end

	function block(do_exit_scope) --stmt[;]...
		enter_scope()
		local islast
		while not islast and not isend() do
			islast = stmt()
			nextif';'
		end
		if do_exit_scope ~= false then
			exit_scope()
		end
	end

	function lx.luastats()
		block()
	end

	--lexer API
	lx.cur = cur
	lx.val = val
	lx.line = line
	lx.offset = filepos
	lx.end_line = end_line
	lx.end_offset = end_filepos
	lx.next = next
	lx.nextif = nextif
	lx.lookahead = lookahead
	lx.expect = expect
	lx.expectval = expectval
	lx.expectmatch = expectmatch
	lx.errorexpected = errorexpected

	--debugging
	lx.token_count = function() return ntk end

	--frontend ----------------------------------------------------------------

	function lx.load()
		lx.next()
		lx.luastats()

		local s = lx.s
		local dt = {}
		local j = 1
		--pp(subst)
		for ti,t in ipairs(subst) do
			push(dt, s:sub(j, t.i-1))

			if t.names and #t.names > 0 then
				for i,name in ipairs(t.names) do
					push(dt, name)
					push(dt, ',')
				end
				dt[#dt] = '='
			end

			push(dt, ('§(%d'):format(ti))
			for i = 1, #t.refs do
				push(dt, ',')
				push(dt, t.refs[i])
			end
			push(dt, ')')

			push(dt, t.stmt and ';' or ' ')
			for i = 1, t.lines do
				push(dt, '\n')
			end

			j = t.i + t.len
		end
		push(dt, s:sub(j))

		local s = concat(dt)
		print(s)
		local func, err = load(s, lx.filename, 't')
		if not func then return nil, err end
		_G.import = function() end
		_G['§'] = function(i, ...)
			return subst[i].cons(...)
		end
		return func
	end

	return lx
end

package.luaxpath = package.luaxpath or package.path:gsub('%.lua', '.luax')

push(package.loaders, function(name)
	local path, err = package.searchpath(name, package.luaxpath)
	if not path then return nil, err end
	return function()
		local f = assert(io.open(path, 'r'))
		local s = assert(f:read'*a')
		f:close()
		local lx = M.lexer(s, path)
		local chunk = lx.load()
		return chunk()
	end
end)

return M
