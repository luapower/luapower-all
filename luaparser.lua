--go@ bin/mingw64/luajit -jp *

io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
require'strict'
local pp = require'pp'

if not ... then require'luaparser_demo'; return end

--Lua lexer and parser using LuaJIT+ffi.
--Translated from llex.c v2.20.1.2 (Lua 5.1.5) by Cosmin Apreutesei.

local ffi = require'ffi'
local bit = require'bit'
local ljs = require'ljstr'
local C = ffi.C

--lexer ----------------------------------------------------------------------

local isalnum = ljs.isalnum
local isspace = ljs.isspace
local isdigit = ljs.isdigit
local isalpha = ljs.isalpha
local strscan = ljs.strscan

local function isnewline(c)
	return c == 10 or c == 13
end

local reserved = {}
for _,k in ipairs{
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'if',
	'in', 'local', 'nil', 'not', 'or', 'repeat',
	'return', 'then', 'true', 'until', 'while',
} do
	reserved[k] = true
end

local function chunkid(source)
	--[[
	if (*source == '=') {
		strncpy(out, source+1, buflen);  /* remove first char */
		out[buflen-1] = '\0';  /* ensures null termination */
	}
	else {  /* out = "source", or "...source" */
		if (*source == '@') {
			size_t l;
			source++;  /* skip the `@' */
			buflen -= sizeof(" '...' ");
			l = strlen(source);
			strcpy(out, "");
			if (l > buflen) {
				source += (l-buflen);  /* get last part of file name */
				strcat(out, "...");
			}
			strcat(out, source);
		}
		else {  /* out = [string "string"] */
			size_t len = strcspn(source, "\n\r");  /* stop at first newline */
			buflen -= sizeof(" [string \"...\"] ");
			if (len > buflen) len = buflen;
			strcpy(out, "[string \"");
			if (source[len] ~= '\0') {  /* must truncate? */
				strncat(out, source, len);
				strcat(out, "...");
			}
			else
				strcat(out, source);
			strcat(out, "\"]");
		}
	}
	]]
	return source
end

local function lexer(read, source)

	local max_bufsize = 2^31-1
	local max_linenumber = 2^31-3

	local buf_ct = ffi.typeof'uint8_t[?]'
	local bufsize = 64
	local buf = buf_ct(bufsize) --token buffer
	local len = 0 --token buffer filled length
	local c --current character ascii code
	local linenumber = 1

	local str = ffi.string
	local b = string.byte

	local save --fw. decl.

	local function format_token(token)
		if token == '<name>' or token == '<string>' or token == '<number>' then
			save(0)
			return str(buf)
		else
			return token
		end
	end
	local function lexerror(msg, token)
		msg = string.format('%s:%d: %s', chunkid(source), linenumber, msg)
		if token then
			msg = string.format('%s near \'%s\'', msg, format_token(token))
		end
		error(msg)
	end

	local function resizebuffer(newsize)
		local newbuf = buf_ct(newsize)
		ffi.copy(newbuf, buf, len)
		buf = newbuf
		bufsize = newsize
	end

	local function resetbuffer()
		len = 0
	end

	local EOF = -1 --because is*(c) can handle c == -1

	local function nextchar_func()
		local size = 4096
		local buf = ffi.new('uint8_t[?]', size)
		local ofs, len = 0, 0
		return function()
			if len == 0 then
				ofs = 0
				len = read(buf, size)
			end
			local sz = math.min(1, len)
			if sz <= 0 then
				c = EOF
			else
				c = buf[ofs]
				ofs = ofs + 1
				len = len - 1
			end
		end
	end
	local nextchar = nextchar_func()

	function save(c)
		if len == bufsize then
			if bufsize >= max_bufsize then
				lexerror'lexical element too long'
			end
			resizebuffer(bufsize * 2)
		end
		buf[len] = c
		len = len + 1
	end

	local function save_and_nextchar()
		save(c)
		nextchar()
	end

	local function inclinenumber()
		local c0 = c
		assert(isnewline(c))
		nextchar()  -- skip `\n' or `\r'
		if isnewline(c) and c ~= c0 then
			nextchar()  -- skip `\n\r' or `\r\n'
		end
		linenumber = linenumber + 1
		if linenumber >= max_linenumber then
			lexerror'chunk has too many lines'
		end
	end

	local function check_next(c1)
		if c ~= c1 then
			return false
		end
		save_and_nextchar()
		return true
	end

	local function parse_number()
		assert(isdigit(c))
		repeat
			save_and_nextchar()
		until not (isdigit(c) or c == b'.')
		if check_next(b'E') or check_next(b'e') then  -- `E'?
			if not check_next(b'+') then  -- optional exponent sign
				check_next(b'-')
			end
		end
		while isalnum(c) or c == b'_' do
			save_and_nextchar()
		end
		save(0)
		local n = strscan(buf)
		if not n then
			lexerror('malformed number', '<number>')
		end
		return n
	end


	local function skip_sep()
		local count = 0
		local c0 = c
		assert(c == b'[' or c == b']')
		save_and_nextchar()
		while c == b'=' do
			save_and_nextchar()
			count = count + 1
		end
		return c == c0 and count or (-count) - 1
	end


	local function parse_long_string(seminfo, sep)
		local cont = 0
		save_and_nextchar()  -- skip 2nd `['
		if isnewline(c) then  -- string starts with a newline?
			inclinenumber()  -- skip it
		end
		while true do
			if c == EOF then
				lexerror(seminfo and 'unfinished long string'
					or 'unfinished long comment', '<eos>')
				-- to avoid warnings
			elseif c == b']' then
				if skip_sep() == sep then
					save_and_nextchar()  -- skip 2nd `]'
					goto endloop
				end
			elseif isnewline(c) then
				save(b'\n')
				inclinenumber()
				if not seminfo then
					resetbuffer()
				end -- avoid wasting space
			else
				if seminfo then
					save_and_nextchar()
				else
					nextchar()
				end
			end
		end ::endloop::
		if seminfo then
			return str(buf + (2 + sep), len - 2 * (2 + sep))
		end
	end

	local function parse_string()
		local delim = c
		save_and_nextchar()
		while c ~= delim do
			if c == EOF then
				lexerror('unfinished string', '<eos>')
			elseif isnewline(c) then
				lexerror('unfinished string', '<string>')
			elseif c == b'\\' then
				nextchar() -- do not save the `\'
				if     c == b'a' then save_and_nextchar(b'\a'); goto continue
				elseif c == b'b' then save_and_nextchar(b'\b'); goto continue
				elseif c == b'f' then save_and_nextchar(b'\f'); goto continue
				elseif c == b'n' then save_and_nextchar(b'\n'); goto continue
				elseif c == b'r' then save_and_nextchar(b'\r'); goto continue
				elseif c == b't' then save_and_nextchar(b'\t'); goto continue
				elseif c == b'v' then save_and_nextchar(b'\v'); goto continue
				elseif isnewline(c) then -- go through
					save(b'\n')
					inclinenumber()
					goto continue
				elseif c == EOF then
					goto continue  -- will raise an error next loop
				elseif not isdigit(c) then
					save_and_nextchar() --handles \\, \', \', and \?
					goto continue
				else  -- \xxx
					local i = 0
					local d = 0
					repeat
						d = 10 * d + (c - b'0')
						nextchar()
						i = i + 1
					until not (i < 3 and isdigit(c))
					if d > 255 then
						lexerror('escape sequence too large', '<string>')
					end
					save(d)
					goto continue
				end
			else
				save_and_nextchar()
			end
			::continue::
		end
		save_and_nextchar() -- skip delimiter
		local s = str(buf + 1, len - 2)
		return s
	end

	local function next_token()
		resetbuffer()
		while true do
			if isnewline(c) then
				inclinenumber()
				goto continue
			elseif c == b'-' then
				nextchar()
				if c ~= b'-' then return b'-' end
				-- else is a comment
				nextchar()
				if c == b'[' then
					local sep = skip_sep() --int
					resetbuffer()  -- `skip_sep' may dirty the buffer
					if sep >= 0 then
						local s = parse_long_string(nil, sep)  -- long comment
						resetbuffer()
						goto continue
					end
				end
				-- else short comment
				while c ~= EOF and not isnewline(c) do
					nextchar()
				end
				goto continue
			elseif c == b'[' then
				local sep = skip_sep()
				if sep >= 0 then
					local s = parse_long_string(true, sep)
					return '<string>', s
				elseif sep == -1 then return '['
				else lexerror('invalid long string delimiter', '<string>') end
			elseif c == b'=' then
				nextchar()
				if c ~= b'=' then return '='
				else nextchar() return '==' end
			elseif c == b'<' then
				nextchar()
				if c ~= b'=' then return '<'
				else nextchar() return '<=' end
			elseif c == b'>' then
				nextchar()
				if c ~= b'=' then return '>'
				else nextchar() return '>=' end
			elseif c == b'~' then
				nextchar()
				if c ~= b'=' then return '~'
				else nextchar() return '~=' end
			elseif c == b'"' or c == b'\'' then
				return '<string>', parse_string()
			elseif c == b'.' then
				save_and_nextchar()
				if check_next(b'.') then
					if check_next(b'.') then
						return '...'
					else
						return '..'
					end
				elseif not isdigit(c) then
					return '.'
				else
					return '<number>', parse_number()
				end
			elseif c == EOF then
				return '<eos>'
			else
				if isspace(c) then
					assert(not isnewline(c))
					nextchar()
					goto continue
				elseif isdigit(c) then
					return '<number>', parse_number()
				elseif isalpha(c) or c == '_' then
					-- identifier or reserved word
					repeat
						save_and_nextchar()
					until not (isalnum(c) or c == '_')
					local s = str(buf, len)
					if reserved[s] then  -- reserved word?
						return s
					else
						return '<name>', s
					end
				else
					local c0 = c
					nextchar()
					return string.char(c0)  -- single-char tokens (+ - / ...)
				end
			end
			::continue::
		end
	end

	resizebuffer(64)  -- initialize buffer
	nextchar()  -- read first char

	local lexer = {}

	local token, token_val
	local lookahead_token, lookahead_info = '<eos>'
	local lastline = 1 -- line of last token consumed

	function lexer.next()
		lastline = linenumber
		if lookahead_token ~= '<eos>' then --is there a look-ahead token?
			token, token_val = lookahead_token, lookahead_info --use this one
			lookahead_token, lookahead_info = '<eos>' --and discharge it
		else
			token, token_val = next_token()
		end
		return token, token_val, linenumber
	end

	function lexer.lookahead()
		assert(lookahead_token == '<eos>')
		lookahead_token, lookahead_info = lex()
		return lookahead_token, lookahead_info, linenumber
	end

	function lexer:error(msg)
		lexerror(msg, token)
	end

	return lexer
end

--parser ---------------------------------------------------------------------

local VARARG_HASARG   = 1
local VARARG_ISVARARG = 2
local VARARG_NEEDSARG = 4
local LUA_MULTRET = -1

--[[
typedef enum {
  VVOID,	/* no value */
  VNIL,
  VTRUE,
  VFALSE,
  VK,		/* info = index of constant in `k' */
  VKNUM,	/* nval = numerical value */
  VLOCAL,	/* info = local register */
  VUPVAL,       /* info = index of upvalue in `upvalues' */
  VGLOBAL,	/* info = index of table; aux = index of global name in `k' */
  VINDEXED,	/* info = table register; aux = index register (or `k') */
  VJMP,		/* info = instruction pc */
  VRELOCABLE,	/* info = instruction pc */
  VNONRELOC,	/* info = result register */
  VCALL,	/* info = instruction pc */
  VVARARG	/* info = instruction pc */
} expkind;
]]

-- Marks the end of a patch list. It is an invalid value both as an absolute
-- address, and as a list link (would link an element to itself).
local NO_JUMP = -1

local function parser(lexer)

	local chunk, expr, open_func, close_func --fw. decl.
	local token, token_val, linenumber --lexer state
	local fs --parser state

	local function next()
		token, token_val, linenumber = lexer:next()
	end

	local function nextif(tok)
		if token == tok then
			next()
			return true
		else
			return false
		end
	end

	local function syntaxerror(msg)
		return lexer:error(msg)
	end

	local function error_expected(token)
		syntaxerror(string.format('\'%s\' expected', token))
	end

	local function check_match(what, who, where)
		if not nextif(what) then
			if where == linenumber then
				error_expected(what)
			else
				syntaxerror(string.format(
					'\'%s\' expected (to close \'%s\' at line %d)',
						what, who, where))
			end
		end
	end

	local function check(c)
		if token ~= c then
			error_expected(c)
		end
	end

	local function checkif(cond, msg)
		if not cond then
			syntaxerror(msg)
		end
	end

	local function codestring(e, s)
		init_exp(e, 'k', s) --luaK_stringK(fs, s))
	end

	local function checkname(e)
		check'<name>'
		local s = token_val
		next()
		if e then
			codestring(e, s)
		end
		return s
	end

	local function init_exp(e, k, i)
		print('init_exp', k, i)
	end

	local function hasmultret(k)
		return k == 'call' or k == 'vararg'
	end

	local function getlocvar(fs, i)
		return fs.locvars[fs.actvar[i]]
	end

	local function registerlocalvar(varname)
		local oldsize = fs.sizelocvars
		--luaM_growvector(ls.L, fs.locvars, fs.nlocvars, fs.sizelocvars, LocVar, SHRT_MAX, "too many local variables")
		while oldsize < fs.sizelocvars do
			fs.locvars[oldsize].varname = nil
			oldsize = oldsize + 1
		end
		fs.locvars[fs.nlocvars] = varname
		--luaC_objbarrier(ls.L, f, varname)
		local n = fs.nlocvars
		fs.nlocvars = fs.nlocvars + 1
		return n
	end

	--#define new_localvarliteral(v,n) \
		--new_localvar(luaX_newstring( "" v, (sizeof(v)/sizeof(char))-1), n)


	local function new_localvar(name, n)
		fs.actvar[fs.nactvar + n] = registerlocalvar(name)
	end

	local function adjustlocalvars(nvars)
		fs.nactvar = fs.nactvar + nvars
	end

	local function removevars(tolevel)
		while fs.nactvar > tolevel do
			fs.nactvar = fs.nactvar - 1
		end
	end

	local function indexupvalue(fs, name, v)
		local i
		local oldsize = fs.sizeupvalues
		for i=0,fs.nups-1 do
			if fs.upvalues[i].k == v.k and fs.upvalues[i].info == v.u.s.info then
				assert(fs.upvalues[i] == name)
				return i
			end
		end
		-- new one
		--TODO: luaM_growvector(fs.L, fs.upvalues, fs.nups, fs.sizeupvalues, TString *, MAX_INT, "")
		while oldsize < fs.sizeupvalues do
			fs.upvalues[oldsize] = nil
			oldsize = oldsize + 1
		end
		fs.upvalues[fs.nups] = name
		luaC_objbarrier(fs.L, f, name)
		assert(v.k == 'local' or v.k == 'upval')
		fs.upvalues[fs.nups].k = v.k
		fs.upvalues[fs.nups].info = cast_byte(v.u.s.info)
		local n = fs.nups
		fs.nups = fs.nups + 1
		return n
	end

	local function searchvar(fs, n)
		for i = fs.nactvar-1, 0, -1 do
			if n == getlocvar(fs, i).varname then
				return i
			end
		end
		return -1  -- not found
	end

	local function markupval(fs, level)
		local bl = fs.bl
		while bl and bl.nactvar > level do
			bl = bl.previous
		end
		if bl then bl.upval = 1 end
	end

	local function singlevaraux(fs, n, var, base)
		if fs == nil then  -- no more levels?
			init_exp(var, 'global', n)  -- default is global variable
			return 'global'
		else
			local v = searchvar(fs, n)  -- look up at current level
			if v >= 0 then
				init_exp(var, 'local', v)
				if not base then
					markupval(fs, v)  -- local will be used as an upval
				end
				return 'local'
			else -- not found at current level try upper one
				if singlevaraux(fs.prev, n, var, 0) == 'global' then
					return 'global'
				end
				var.u.s.info = indexupvalue(fs, n, var)  -- else was LOCAL or UPVAL
				var.k = 'upval'  -- upvalue in this level
				return 'upval'
			end
		end
	end

	local function singlevar(var)
		local varname = checkname()
		if singlevaraux(fs, varname, var, 1) == 'global' then
			--var.u.s.info = luaK_stringK(fs, varname)  -- info points to global name
		end
	end

	local function adjust_assign(nvars, nexps, e)
		local extra = nvars - nexps
		if hasmultret(e.k) then
			extra = extra + 1  -- includes call itself
			if extra < 0 then extra = 0 end
			luaK_setreturns(fs, e, extra)  -- last exp. provides the difference
			if extra > 1 then luaK_reserveregs(fs, extra-1) end
		else
			if e.k ~= 'void' then -- close last expression
				--luaK_exp2nextreg(fs, e)
			end
			if extra > 0 then
				local reg = fs.freereg
				--luaK_reserveregs(fs, extra)
				--luaK_nil(fs, reg, extra)
			end
		end
	end

	local function enterblock(fs, bl, isbreakable)
		bl.breaklist = NO_JUMP
		bl.isbreakable = isbreakable
		bl.nactvar = fs.nactvar
		bl.upval = 0
		bl.previous = fs.bl
		fs.bl = bl
	end

	local function leaveblock(fs)
		local bl = fs.bl
		fs.bl = bl.previous
		removevars(bl.nactvar)
		if bl.upval then
			--luaK_codeABC(fs, OP_CLOSE, bl.nactvar, 0, 0)
		end
		-- a block either controls scope or breaks (never both)
		assert(not bl.isbreakable or not bl.upval)
		assert(bl.nactvar == fs.nactvar)
		fs.freereg = fs.nactvar  -- free registers
		--luaK_patchtohere(fs, bl.breaklist)
	end


	local function pushclosure(func, v)
		local oldsize = fs.sizep
		local i
		--luaM_growvector(ls.L, fs.p, fs.np, fs.sizep, Proto *, MAXARG_Bx, "constant table overflow")
		while oldsize < fs.sizep do
			f.p[oldsize] = nil
			oldsize = oldsize + 1
		end
		fs.p[fs.np] = func
		fs.np = fs.np + 1
		--luaC_objbarrier(ls.L, f, func.f)
		init_exp(v, 'relocable', nil) --luaK_codeABx(fs, OP_CLOSURE, 0, fs.np-1))
		for i = 0, func.nups-1 do
			local o = func.upvalues[i].k == 'local' and OP_MOVE or OP_GETUPVAL
			--luaK_codeABC(fs, o, 0, func.upvalues[i].info, 0)
		end
	end

	-- GRAMMAR RULES ----------------------------------------------------------

	local function field(v) -- ['.' | ':'] NAME
		local key
		--luaK_exp2anyreg(fs, v)
		next()  -- skip the dot or colon
		checkname(key)
		luaK_indexed(fs, v, key)
	end

	local function yindex(v)  -- '[' expr ']'
		next()  -- skip the '['
		expr(v)
		luaK_exp2val(fs, v)
		check']'; next()
	end

	-- Rules for Constructors -------------------------------------------------

	--[=[
	ffi.cdef[[
	struct ConsControl {
		expdesc v  -- last list item read
		expdesc *t  -- table descriptor
		int nh  -- total number of `record' elements
		int na  -- total number of array elements
		int tostore  -- number of array elements pending to be stored
	};
	]]
	]=]

	local function recfield(cc) -- (NAME | `['exp1`]') = exp1
		local reg = fs.freereg
		local key, val
		local rkkey
		if token == '<name>' then
			checkname(key)
		else -- token == '['
			yindex(key)
		end
		cc.nh = cc.nh + 1
		check'='; next()
		rkkey = luaK_exp2RK(fs, key)
		expr(val)
		--luaK_codeABC(fs, OP_SETTABLE, cc.t.u.s.info, rkkey, luaK_exp2RK(fs, val))
		fs.freereg = reg  -- free registers
	end


	local function closelistfield(fs, cc)
		if cc.v.k == 'void' then return end -- there is no list item
		--luaK_exp2nextreg(fs, cc.v)
		cc.v.k = 'void'
		if (cc.tostore == LFIELDS_PER_FLUSH) then
			luaK_setlist(fs, cc.t.u.s.info, cc.na, cc.tostore)  -- flush
			cc.tostore = 0  -- no more items pending
		end
	end

	local function lastlistfield(fs, cc)
		if cc.tostore == 0 then return end
		if hasmultret(cc.v.k) then
			luaK_setmultret(fs, cc.v)
			luaK_setlist(fs, cc.t.u.s.info, cc.na, LUA_MULTRET)
			cc.na = cc.na - 1 -- do not count last expression (unknown number of elements)
		else
			if cc.v.k ~= 'void' then
				--luaK_exp2nextreg(fs, cc.v)
			end
			luaK_setlist(fs, cc.t.u.s.info, cc.na, cc.tostore)
		end
	end

	local function listfield(cc)
		expr(cc.v)
		cc.na = cc.na + 1
		cc.tostore = cc.tostore + 1
	end

	local function constructor(t) -- ??
		local line = linenumber
		--local pc = luaK_codeABC(fs, OP_NEWTABLE, 0, 0, 0)
		local cc
		cc.na = 0
		cc.nh = 0
		cc.tostore = 0
		cc.t = t
		init_exp(t, 'relocable', pc)
		init_exp(cc.v, 'void', 0)  -- no value (yet)
		--luaK_exp2nextreg(fs, t)  -- fix it at stack top (for gc)
		check'then'; next()
		repeat
			assert(cc.v.k == 'void' or cc.tostore > 0)
			if token == 'end' then break end
			closelistfield(fs, cc)
			if token == '<name>' then -- may be listfields or recfields
				luaX_lookahead()
				if ls.lookahead.token ~= '=' then  -- expression?
					listfield(cc)
				else
					recfield(cc)
				end
			elseif token == '[' then  -- constructor_item . recfield
				recfield(cc)
			else -- constructor_part . listfield
				listfield(cc)
			end
		until not (nextif',' or nextif'')
		check_match('end', 'then', line)
		lastlistfield(fs, cc)
		SETARG_B(fs.code[pc], luaO_int2fb(cc.na)) -- set initial array size
		SETARG_C(fs.code[pc], luaO_int2fb(cc.nh))  -- set initial table size
	end

	local function parlist()  -- [ param { `,' param } ]
		local nparams = 0
		fs.is_vararg = 0
		if token ~= ')' then  -- is `parlist' not empty?
			repeat
				if token == '<name>' then -- NAME
					new_localvar(checkname(), nparams)
					nparams = nparams + 1
				elseif token == '...' then
					next()
					fs.is_vararg = bit.bor(fs.is_vararg, VARARG_ISVARARG)
				else
					syntaxerror('<name> or \'...\' expected')
				end
			until not (not fs.is_vararg and nextif',')
		end
		adjustlocalvars(nparams)
		fs.numparams = fs.nactvar - bit.band(fs.is_vararg, VARARG_HASARG)
		--luaK_reserveregs(fs, fs.nactvar)  -- reserve register for parameters
	end

	local function body(e, needself, line) -- `(' parlist `)' chunk END
		print('body')
		local new_fs = {nactvar = 0}
		open_func(new_fs)
		new_fs.linedefined = line
		check'('; next()
		if needself then
			print('!!! self')
			--new_localvarliteral('self', 0)
			adjustlocalvars(1)
		end
		parlist()
		check')'; next()
		chunk()
		new_fs.lastlinedefined = linenumber
		check_match('end', 'function', line)
		close_func()
		pushclosure(new_fs, e)
	end

	local function explist1(v) -- expr { `,' expr }
		local n = 1  -- at least one expression
		expr(v)
		while nextif',' do
			--luaK_exp2nextreg(fs, v)
			expr(v)
			n = n + 1
		end
		return n
	end

	local function funcargs(f)
		local args = {}
		local base, nparams
		local line = linenumber
		if token == '(' then  -- `(' [ explist1 ] `)'
			if line ~= ls.lastline then
				syntaxerror'ambiguous syntax (function call x new statement)'
			end
			next()
			if token == ')' then  -- arg list is empty?
				args.k = 'void'
			else
				explist1(args)
				luaK_setmultret(fs, args)
			end
			check_match(')', '(', line)
		elseif token == 'then' then  -- constructor
			constructor(args)
		elseif token == '<string>' then  -- STRING
			codestring(args, token_val)
			next()  -- must use `seminfo' before `next'
		else
			syntaxerror'function arguments expected'
		end
		assert(f.k == VNONRELOC)
		--base = f.u.s.info  -- base register for call
		if hasmultret(args.k) then
			nparams = LUA_MULTRET  -- open call
		elseif args.k ~= VVOID then
			--luaK_exp2nextreg(fs, args)  -- close last argument
			nparams = fs.freereg - (base+1)
		end
		init_exp(f, 'call', nil) --luaK_codeABC(fs, OP_CALL, base, nparams+1, 2))
		--luaK_fixline(fs, line)
		--fs.freereg = base+1  -- call remove function and arguments and leaves (unless changed) one result
	end

	-- Expression parsing -----------------------------------------------------

	local function prefixexp(v) -- NAME | '(' expr ')'
		if token == '(' then
			local line = linenumber
			next()
			expr(v)
			check_match(')', '(', line)
			luaK_dischargevars(fs, v)
		elseif token == '<name>' then
			singlevar(v)
		else
			syntaxerror'unexpected symbol'
		end
	end


	-- prefixexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs }
	local function primaryexp(v)
		prefixexp(v)
		while true do
			if token == '.' then  -- field
				field(v)
			elseif token == '[' then  -- `[' exp1 `]'
				local key
				luaK_exp2anyreg(fs, v)
				yindex(key)
				luaK_indexed(fs, v, key)
			elseif token == ':' then  -- `:' NAME funcargs
				local key
				next()
				checkname(key)
				luaK_self(fs, v, key)
				funcargs(v)
			elseif token == '(' or token == '<string>' or token == 'then' then --funcargs
				--luaK_exp2nextreg(fs, v)
				funcargs(v)
			else
				return
			end
		end
	end

	-- NUMBER | STRING | NIL | true | false | ... | constructor | FUNCTION body | primaryexp
	local function simpleexp(v)
		if token == '<number>' then
			init_exp(v, 'number', token_val)
		elseif token == '<string>' then
			codestring(v, token_val)
		elseif token == 'nil' then
			init_exp(v, 'nil', 0)
		elseif token == 'true' then
			init_exp(v, 'true', 0)
		elseif token == 'false' then
			init_exp(v, 'false', 0)
		elseif token == '...' then  -- vararg
			checkif(fs.is_vararg, 'cannot use "..." outside a vararg function')
			fs.is_vararg = bit.band(fs.is_vararg, bit.bnot(VARARG_NEEDSARG))  -- don't need 'arg'
			init_exp(v, 'vararg', nil) --luaK_codeABC(fs, OP_VARARG, 0, 1, 0))
		elseif token == '{' then -- constructor
			constructor(v)
			return
		elseif token == 'function' then
			next()
			body(v, false, linenumber)
			return
		else
			primaryexp(v)
			return
		end
		next()
	end

	local priority = {}
	priority['+'  ] = {left = 6, right = 6}
	priority['-'  ] = {left = 6, right = 6}
	priority['*'  ] = {left = 7, right = 7}
	priority['/'  ] = {left = 7, right = 7}
	priority['%'  ] = {left = 7, right = 7}
	priority['^'  ] = {left =10, right = 9} --right associative
	priority['..' ] = {left = 5, right = 4} --right associative
	priority['~=' ] = {left = 3, right = 3}
	priority['==' ] = {left = 3, right = 3}
	priority['<'  ] = {left = 3, right = 3}
	priority['<=' ] = {left = 3, right = 3}
	priority['>'  ] = {left = 3, right = 3}
	priority['>=' ] = {left = 3, right = 3}
	priority['and'] = {left = 2, right = 2}
	priority['or' ] = {left = 1, right = 1}

	local UNARY_PRIORITY = 8 -- priority for unary operators

	-- (simpleexp | unop subexpr) { binop subexpr }
	-- where `binop' is any binary operator with a priority higher than `limit'
	local function subexpr(v, limit)
		local uop = token
		if uop == 'not' or uop == '-' or uop == '#' then
			print('unary op', token, token_val)
			next()
			subexpr(v, UNARY_PRIORITY)
			--print('prefix', uop)
			--luaK_prefix(fs, uop, v)
		else
			simpleexp(v)
		end
		-- expand while operators have priorities higher than `limit'
		local op = token
		local pri = priority[op]
		while pri and pri.left > limit do
			print('binary op', op)
			local v2 = {}
			next()
			--luaK_infix(fs, op, v)
			-- read sub-expression with higher priority
			local nextop = subexpr(v2, pri.right)
			--luaK_posfix(fs, op, v, v2)
			op = nextop
			pri = priority[op]
		end
		return op  -- return first untreated operator
	end

	function expr(v)
		subexpr(v, 0)
	end

	--Rules for statements ----------------------------------------------------

	local function block() -- chunk
		print'block'
		local bl = {}
		enterblock(fs, bl, false)
		chunk()
		assert(bl.breaklist == NO_JUMP)
		leaveblock(fs)
	end

	local function assignment(lh, nvars)
		local e
		--TODO: checkif(VLOCAL <= lh.v.k and lh.v.k <= VINDEXED, "syntax error")
		if nextif',' then  -- assignment . `,' primaryexp assignment
			local nv
			nv.prev = lh
			primaryexp(nv.v)
			assignment(nv, nvars+1)
		else -- assignment . `=' explist1
			check'='; next()
			local nexps = explist1(e)
			if nexps ~= nvars then
				adjust_assign(nvars, nexps, e)
				if nexps > nvars then
					fs.freereg = fs.freereg - (nexps - nvars)  -- remove extra values
				end
			else
				--luaK_setoneret(fs, e)  -- close last expression
				--luaK_storevar(fs, lh.v, e)
				return  -- avoid default
			end
		end
		init_exp(e, 'noreloc', fs.freereg-1)  -- default assignment
		--luaK_storevar(fs, lh.v, e)
	end


	local function cond() -- exp
		local v = {}
		expr(v)  -- read condition
		if v.k == 'nil' then
			v.k = 'false'
		end -- `falses' are all equal here
		--luaK_goiftrue(fs, v)
		return v.f
	end


	local function breakstat()
		local bl = fs.bl
		local upval = 0
		while bl and not bl.isbreakable do
			upval = bit.bor(upval, bl.upval)
			bl = bl.previous
		end
		if not bl then
			syntaxerror'no loop to break'
		end
		if upval then
			--luaK_codeABC(fs, OP_CLOSE, bl.nactvar, 0, 0)
		end
		--luaK_concat(fs, bl.breaklist, luaK_jump(fs))
	end

	local function whilestat(line) -- WHILE cond DO block END
		local whileinit
		local condexit
		local bl
		next()  -- skip WHILE
		whileinit = luaK_getlabel(fs)
		condexit = cond()
		enterblock(fs, bl, true)
		check'do'; next()
		block()
		luaK_patchlist(fs, luaK_jump(fs), whileinit)
		check_match('end', 'while', line)
		leaveblock(fs)
		luaK_patchtohere(fs, condexit)  -- false conditions finish the loop
	end


	local function repeatstat(line) -- REPEAT block UNTIL cond
		local condexit
		local repeat_init = luaK_getlabel(fs)
		local bl1, bl2
		enterblock(fs, bl1, true)  -- loop block
		enterblock(fs, bl2, false)  -- scope block
		next()  -- skip REPEAT
		chunk()
		check_match('until', 'repeat', line)
		condexit = cond()  -- read condition (inside scope block)
		if not bl2.upval then  -- no upvalues?
			leaveblock(fs)  -- finish scope
			luaK_patchlist(fs, condexit, repeat_init)  -- close the loop
		else -- complete semantics when there are upvalues
			breakstat()  -- if condition then break
			luaK_patchtohere(fs, condexit)  -- else...
			leaveblock(fs)  -- finish scope...
			luaK_patchlist(fs, luaK_jump(fs), repeat_init)  -- and repeat
		end
		leaveblock(fs)  -- finish loop
	end

	local function exp1()
		local e
		local k
		expr(e)
		k = e.k
		--luaK_exp2nextreg(fs, e)
		return k
	end

	local function forbody(base, line, nvars, isnum) -- forbody -> DO block
		local bl
		local prep, endfor
		adjustlocalvars(3)  -- control variables
		check'do'; next()
		prep = isnum and luaK_codeAsBx(fs, OP_FORPREP, base, NO_JUMP) or luaK_jump(fs)
		enterblock(fs, bl, false)  -- scope for declared variables
		adjustlocalvars(nvars)
		--luaK_reserveregs(fs, nvars)
		block()
		leaveblock(fs)  -- end of scope for declared variables
		--luaK_patchtohere(fs, prep)
		--endfor = isnum and luaK_codeAsBx(fs, OP_FORLOOP, base, NO_JUMP) or
		--						luaK_codeABC(fs, OP_TFORLOOP, base, 0, nvars)
		--luaK_fixline(fs, line)  -- pretend that `OP_FOR' starts the loop
		--luaK_patchlist(fs, (isnum and endfor or luaK_jump(fs)), prep + 1)
	end


	-- fornum -> NAME = exp1,exp1[,exp1] forbody
	local function fornum(varname, line)
		local base = fs.freereg
		new_localvarliteral('(for index)', 0)
		new_localvarliteral('(for limit)', 1)
		new_localvarliteral('(for step)', 2)
		new_localvar(varname, 3)
		check'='; next()
		exp1()  -- initial value
		check','; next()
		exp1()  -- limit
		if nextif',' then
			exp1()  -- optional step
		else -- default step = 1
			luaK_codeABx(fs, OP_LOADK, fs.freereg, luaK_numberK(fs, 1))
			luaK_reserveregs(fs, 1)
		end
		forbody(base, line, 1, 1)
	end

	-- forlist -> NAME {,NAME} IN explist1 forbody
	local function forlist(indexname)
		local e
		local nvars = 0
		local line
		local base = fs.freereg
		-- create control variables
		new_localvarliteral('(for generator)', nvars); nvars = nvars + 1
		new_localvarliteral('(for state)', nvars); nvars = nvars + 1
		new_localvarliteral('(for control)', nvars); nvars = nvars + 1
		-- create declared variables
		new_localvar(indexname, nvars); nvars = nvars + 1
		while nextif',' do
			new_localvar(checkname(), nvars); nvars = nvars + 1
		end
		check'in'; next()
		line = linenumber
		adjust_assign(3, explist1(e), e)
		luaK_checkstack(fs, 3)  -- extra space to call generator
		forbody(base, line, nvars - 3, 0)
	end

	local function forstat(line) -- FOR (fornum | forlist) END
		local varname
		local bl
		enterblock(fs, bl, true)  -- scope for loop and control variables
		next()  -- skip `for'
		varname = checkname()  -- first variable name
		if token == '=' then
			fornum(varname, line)
		elseif token == ',' or token == 'in' then
			forlist(varname)
		else
			syntaxerror'\'=\' or \'in\' expected'
		end
		check_match('end', 'for', line)
		leaveblock(fs)  -- loop scope (`break' jumps to this point)
	end

	local function test_then_block() -- [IF | ELSEIF] cond THEN block
		local condexit
		next()  -- skip IF or ELSEIF
		condexit = cond()
		check'then'; next()
		block()  -- `then' part
		return condexit
	end

	-- IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END
	local function ifstat(line)
		print'if'
		local flist = {}
		local escapelist = NO_JUMP
		flist = test_then_block()  -- IF cond THEN block
		while token == 'elseif' do
			--luaK_concat(fs, escapelist, luaK_jump(fs))
			--luaK_patchtohere(fs, flist)
			flist = test_then_block()  -- ELSEIF cond THEN block
		end
		if token == 'else' then
			--luaK_concat(fs, escapelist, luaK_jump(fs))
			--luaK_patchtohere(fs, flist)
			next()  -- skip ELSE (after patch, for correct line info)
			block()  -- `else' part
		else
			--luaK_concat(fs, escapelist, flist)
		end
		--luaK_patchtohere(fs, escapelist)
		check_match('end', 'if', line)
	end


	local function localfunc()
		local v, b
		new_localvar(checkname(), 0)
		init_exp(v, 'local', fs.freereg)
		--luaK_reserveregs(fs, 1)
		adjustlocalvars(1)
		body(b, false, linenumber)
		--luaK_storevar(fs, v, b)
		-- debug information will only see the variable after this point!
		--getlocvar(fs, fs.nactvar - 1).startpc = fs.pc
	end


	local function localstat() -- LOCAL NAME {`,' NAME} [`=' explist1]
		local nvars = 0
		local nexps
		local e = {}
		repeat
			new_localvar(checkname(), nvars); nvars = nvars + 1
		until not nextif','
		if nextif'=' then
			nexps = explist1(e)
		else
			e.k = 'void'
			nexps = 0
		end
		adjust_assign(nvars, nexps, e)
		adjustlocalvars(nvars)
	end


	local function funcname(v) -- funcname -> NAME thenfieldend [`:' NAME]
		local needself = 0
		singlevar(v)
		while token == '.' do
			field(v)
		end
		if token == ':' then
			needself = 1
			field(v)
		end
		return needself
	end


	local function funcstat(line) -- funcstat -> FUNCTION funcname body
		local needself
		local v, b
		next()  -- skip FUNCTION
		needself = funcname(v)
		body(b, needself, line)
		--luaK_storevar(fs, v, b)
		--luaK_fixline(fs, line)  -- definition `happens' in the first line
	end


	local function exprstat() -- func | assignment
		local v = {v = {}}
		primaryexp(v.v)
		if v.v.k == 'call' then  -- func
			--SETARG_C(getcode(fs, v.v), 1)  -- call statement uses no results
		else -- assignment
			v.prev = nil
			assignment(v, 1)
		end
	end

	local function block_follow()
		return token == 'else' or token == 'elseif' or token == 'end'
			or token == 'until' or token == '<eos>'
	end

	local function retstat() -- stat -> RETURN explist
		local e --expdesc
		local first, nret  -- registers with returned values
		next() -- skip RETURN
		if block_follow() or token == ';' then
			first = 0
			nret = 0  -- return no values
		else
			nret = explist1(e)  -- optional return values
			if hasmultret(e.k) then
				luaK_setmultret(fs, e)
				if e.k == 'vcall' and nret == 1 then  -- tail call?
					--
				end
				first = fs.nactvar
				nret = LUA_MULTRET  -- return all values
			else
				if nret == 1 then  -- only one single value?
					first = luaK_exp2anyreg(fs, e)
				else
					--luaK_exp2nextreg(fs, e)  -- values must go to the `stack'
					first = fs.nactvar  -- return all `active' values
					assert(nret == fs.freereg - first)
				end
			end
		end
		--luaK_ret(fs, first, nret)
	end

	local function statement()
		print('statement', token, token_val or '')
		local line = linenumber  -- needed for error messages
		if token == 'if' then
			ifstat(line)
		elseif token == 'while' then
			whilestat(line)
		elseif token == 'do' then  -- DO block END
			next()  -- skip DO
			block()
			check_match('end', 'do', line)
		elseif token == 'for' then
			forstat(line)
		elseif token == 'repeat' then
			repeatstat(line)
		elseif token == 'function' then
			funcstat(line)
		elseif token == 'local' then
			next()  -- skip LOCAL
			if nextif'function' then -- local function?
				localfunc()
			else
				localstat()
			end
		elseif token == 'return' then
			retstat()
			return true  -- must be last statement
		elseif token == 'break' then
			next()  -- skip BREAK
			breakstat()
			return true  -- must be last statement
		else
			exprstat() -- func | assignment
		end
		return false
	end

	function chunk() -- { stat [`;'] }
		local islast = false
		while not islast and not block_follow() do
			islast = statement()
			nextif';'
		end
	end

	function open_func(new_fs)
		new_fs.prev = fs  -- linked list of funcstates
		fs = new_fs
		fs.pc = 0
		fs.lasttarget = -1
		fs.jpc = NO_JUMP
		fs.freereg = 0
		fs.nk = 0
		fs.np = 0
		fs.nlocvars = 0
		fs.nactvar = 0
		fs.bl = nil
		fs.upvalues = {} --upvalues
		fs.actvar = {} --declared-variable stack

		--f
		fs.k = nil
		fs.sizek = 0
		fs.p = nil
		fs.sizep = 0
		fs.code = nil
		fs.sizecode = 0
		fs.sizelineinfo = 0
		fs.sizeupvalues = 0
		fs.nups = 0
		fs.upvalues = nil
		fs.numparams = 0
		fs.is_vararg = 0
		fs.maxstacksize = 0
		fs.lineinfo = nil
		fs.sizelocvars = 0
		fs.locvars = nil
		fs.linedefined = 0
		fs.lastlinedefined = 0
		fs.source = nil
		fs.locvars = {}
		fs.p = {}

		--fs.source = source
		fs.maxstacksize = 2  -- registers 0/1 are always valid
		fs.h = {}
	end

	function close_func()
		removevars(0)
		fs.sizek = fs.nk
		fs.sizep = fs.np
		fs.sizelocvars = fs.nlocvars
		fs.sizeupvalues = fs.nups
		assert(fs.bl == nil)
		fs = fs.prev
	end

	local function parse()
		local fs = {}
		open_func(fs)
		fs.is_vararg = VARARG_ISVARARG  -- main func. is always vararg
		next() -- read first token
		chunk()
		check'<eos>'
		close_func()
		assert(not fs.prev)
		assert(fs.nups == 0)
		return fs
	end

	local par = {}
	par.parse = parse

	return par

end

return {
	lexer = lexer,
	parser = parser,
}
