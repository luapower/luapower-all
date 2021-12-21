
local tuple = require'tuple'
local push, pop, concat = table.insert, table.remove, table.concat

local t2 = {}

function t2.struct(t)
	t.type = 'type'
	t.kind = 'struct'
	return t
end

function t2.type(t)
	if not t.type then --tuple
		t = tuple(unpack(t))
		t.type = 'type'
		t.kind = 'tuple'
	end
	return t
end

function t2.func(t)
	t.type = 'func'
	return t
end

function t2.functype(t)
	t.type = 'type'
	t.kind = 'func'
	return t
end

local function expression_function(lx)

	local cur = lx.cur
	local next = lx.next
	local nextif = lx.nextif
	local expect = lx.expect
	local expectval = lx.expectval
	local errorexpected = lx.errorexpected
	local expectmatch = lx.expectmatch
	local line = lx.line
	local luaexpr = lx.luaexpr

	local function isend() --check for end of block
		local tk = cur()
		return tk == 'else' or tk == 'elseif' or tk == 'end'
			or tk == 'until' or tk == '<eof>'
	end

	local unary_priority = {
		['not'] = 9 * 2,
		['-'  ] = 9 * 2,
		['#'  ] = 9 * 2,
	}

	local binary_priority = {
		['^'  ] = 10 * 2,

		--unary priority: 9 * 2

		['*'  ] =  8 * 2,
		['/'  ] =  8 * 2,
		['%'  ] =  8 * 2,

		['+'  ] =  7 * 2,
		['-'  ] =  7 * 2,

		['..' ] =  6 * 2,

		['<<' ] =  5 * 2,
		['>>' ] =  5 * 2,
		['xor'] =  5 * 2,

		['==' ] =  4 * 2,
		['~=' ] =  4 * 2,
		['<'  ] =  4 * 2,
		['<=' ] =  4 * 2,
		['>'  ] =  4 * 2,
		['>=' ] =  4 * 2,

		['->' ] =  3 * 2,

		['and'] =  2 * 2,

		['or' ] =  1 * 2,
	}

	local right_associative = {
		['^' ] = true,
		['..'] = true,
	}

	local function expectname()
		return expectval'<name>'
	end

	local function funcdecl(name) --args_type [-> return_type]
		local bind_args_type = luaexpr()
		expect'->'
		local bind_ret_type = luaexpr()
		return function(...)
			return t2.func{
				name = name,
				args_type = bind_args_type(...),
				ret_type = bind_ret_type(...),
			}
		end
	end

	local function bindlist(t)
		return function(...)
			while #t > 0 do
				local bind = pop(t)
				bind(...)
			end
			return t
		end
	end

	local function funcdef(name, line, pos)

		--params: (name:type,...[,...])
		local tk = expect'('
		local t = {type = 'func', name = name, args = {}}
		if tk ~= ')' then
			repeat
				if tk == '<name>' then
					local name = expectname()
					expect':'
					local bind_type = luaexpr()
					push(t.args, name)
					push(t.args, false) --type slot
					local type_slot = #t.args
					t[#t+1] = function(...)
						t.args[type_slot] = bind_type(...) or false
					end
				elseif tk == '...' then
					t.vararg = true
					next()
					break
				else
					errorexpected'<name> or "..."'
				end
				tk = nextif','
			until not tk
		end
		expectmatch(')', 'terra', line, pos)

		--return type: [:type]
		if nextif':' then
			local bind_ret_type = luaexpr()
			t[#t+1] = function(...)
				t.ret_type = bind_ret_type(...)
			end
		end

		--body
		block(t)
		if cur() ~= 'end' then
			expectmatch('end', 'terra', line, pos)
		end
		next()
		local bind = bindlist(t)
		return function(...)
			return t2.func(bind(...))
		end
	end

	local function struct(name, line, pos)
		local tk = expect'{'
		local t = {name = name, fields = {}}
		while tk ~= '}' do
			local name = expectname()
			expect':'
			local bind_type = luaexpr()
			push(t.fields, name)
			push(t.fields, false) --type slot
			local type_slot = #t.fields
			t[#t+1] = function(...)
				t.fields[type_slot] = bind_type(...) or false
			end
			tk = nextif','
			if not tk then break end
		end
		expectmatch('}', 'struct', line, pos)
		local bind = bindlist(t)
		return function(...)
			return t2.struct(bind(...))
		end
	end

	local function type()
		local bind_type = luaexpr()
		if nextif'->' then
			--TODO: this is wrong: operator priority > than that of `and` and `or`
			--TODO: remove this after implementing extensible operators.
			local bind_rettype = luaexpr()
			return function(...)
				return t2.functype({
					args_type = bind_type(...),
					ret_type  = bind_rettype(...),
				})
			end
		else
			return function(...)
				return t2.type(bind_type(...))
			end
		end
	end

	local function ref()
		if refs then
			push(refs, expectval'<name>')
		else
			expect'<name>'
		end
	end

	local function expr_field() --.:name
		next()
		expectname()
	end

	local function expr_bracket() --[expr]
		next()
		expr()
		expect']'
	end

	local function expr_table() --{[expr]|name=expr,;...}
		local line, pos = line()
		local tk = expect'{'
		while tk ~= '}' do
			if tk == '[' then
				expr_bracket()
				expect'='
			elseif tk == '<name>' and lookahead() == '=' then
				expectname()
				expect'='
			end
			expr()
			if not nextif',' and not nextif';' then break end
			tk = cur()
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
		local tk = cur()
		if tk == '(' then
			local line, pos = line()
			tk = next()
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
		local tk = cur()
		if tk == '(' then
			local line, pos = line()
			next()
			expr()
			expectmatch(')', '(', line, pos)
		elseif tk == '<name>' then
			ref()
		else
			error'unexpected symbol'
		end
		local tk = cur()
		while true do --parse multiple expression suffixes.
			if tk == '.' then
				expr_field()
				iscall = false
			elseif tk == '[' then
				expr_bracket()
				iscall = false
			elseif tk == ':' then
				next()
				expectname()
				args()
				iscall = true
			elseif tk == '(' or tk == '<string>' or tk == '{' then
				args()
				iscall = true
			else
				break
			end
			tk = cur()
		end
		return iscall
	end

	local function expr_simple() --literal|...|{table}|expr_primary
		local tk = cur()
		if tk == '<number>' or tk == '<imag>' or tk == '<int>' or tk == '<u32>'
			or tk == '<i64>' or tk == '<u64>' or tk == '<string>' or tk == 'nil'
			or tk == 'true' or tk == 'false' or tk == '...'
		then --literal
			next()
		elseif tk == '{' then --{table}
			expr_table()
		else
			expr_primary()
		end
	end

	--parse binary expressions with priority higher than the limit.
	local function expr_binop(limit)
		local pri = unary_priority[cur()]
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
		expectname()
		local tk = expect'::'
		--recursively parse trailing statements: labels and ';' (Lua 5.2 only).
		while true do
			if tk == '::' then
				label()
			elseif tk == ';' then
				next()
			else
				break
			end
			tk = cur()
		end
	end

	--parse a statement. returns true if it must be the last one in a chunk.
	local function stmt()
		local tk = cur()
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
				tk = cur()
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
			expectname()
			local tk = cur()
			if tk == '=' then -- = expr, expr [,expr]
				next()
				expr()
				expect','
				expr()
				if nextif',' then expr() end
			elseif tk == ',' or tk == 'in' then -- ,name... in expr,...
				while nextif',' do
					expectname()
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
		elseif tk == 'terra' then --terra name body  |  terra name functype
			local line, pos = line()
			next()
			local name, next_tk = expectname()
			if next_tk == '::' then
				next()
				funcdecl(name)
			else
				funcdef(name, line, pos)
			end
		elseif tk == 'var' then
			--var name1[:type1],...[=expr1],...
			local line, pos = line()
			next()
			repeat --name[:type],...
				expectname()
				if nextif':' then
					type()
				end
			until not nextif','
			if nextif'=' then -- =expr,...
				expr_list()
			end
		elseif tk == 'return' then --return [expr,...]
			tk = next()
			if not (isend(tk) or tk == ';') then
				expr_list()
			end
			return true --must be last
		elseif tk == 'break' then
			next()
		elseif tk == ';' then
			next()
		elseif tk == '::' then
			label()
		elseif tk == 'goto' then --goto name
			next()
			expectname()
		elseif not expr_primary() then --function call or assignment
			assignment()
		end
		return false
	end

	function block(do_exit_scope) --stmt[;]...
		--enter_scope()
		local islast
		while not islast and not isend() do
			islast = stmt()
			nextif';'
		end
		if do_exit_scope ~= false then
			--exit_scope()
		end
	end

	return function(_, tk, stmt)
		next()
		if tk == 'struct' then
			local line, pos = line()
			local name = stmt and expectval'<name>'
			return struct(name, line, pos), name and {name}
		elseif tk == 'terra' then
			local bind
			local line, pos = line()
			local name, next_tk
			if stmt then
				name, next_tk = expectname()
			end
			if next_tk == '::' then
				next()
				bind = funcdecl(name)
			else
				bind = funcdef(name, line, pos)
			end
			return bind, name and {name}
		elseif tk == 'quote' then
		end
		assert(false)
	end
end

function t2.lang(lx)
	return {
		keywords = {'terra', 'quote', 'struct', 'var'},
		entrypoints = {
			statement = {'terra', 'struct'},
			expression = {'`'},
		},
		expression = expression_function(lx),
	}
end

return t2
