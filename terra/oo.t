--[[

	OOP DSL for Terra.
	Written by Cosmin Apreutesei. Public Domain.

]]

if not ... then require'terra.oo_test'; return end

setfenv(1, require'terra.low')

--parser/compiler for `class <C>[:<S>] ... end` decls.
local class = {}; setmetatable(class, class)

--parser ---------------------------------------------------------------------

function class:__call()
	local self = {__index = self}
	return setmetatable(self, self)
end

function class:parse_class_expr(lex)
	--header: `class <name>[:<super_expr>]`
	lex:expect'class'
	local self = self()
	self.ast = {fields = {}, methods = {}}
	local name_token = lex:expect(lex.name)
	self.name = name_token.value
	self.ast.linenumber = name_token.linenumber
	if lex:nextif':' then
		self.ast.super_expr = lex:luaexpr()
	end
	--definitions: <field_def> | <method_def> | <macro_def> | <hook_def>
	while not lex:nextif'end' do
		if lex:matches'before' or lex:matches'after' or lex:matches'over' then --<hook_def>
			--before|after|over <method_def>|<macro_def>
			local hook = lex:next().type
			local name_token = lex:expect(lex.name)
			local name = name_token.value
			local ast = self:parse_method_or_macro_def(lex, name, name_token.linenumber)
			ast.linenumber = name_token.linenumber
			ast.hook = hook
			add(self.ast.methods, ast)
		else
			local name_token = lex:expect(lex.name)
			local name = name_token.value
			if lex:matches':' or lex:matches'=' then --<field_def>
				local ast = self:parse_field_def(lex, name, name_token.linenumber)
				ast.linenumber = name_token.linenumber
				add(self.ast.fields, ast)
			elseif lex:matches'(' then --<method_def> | <macro_def>
				local ast = self:parse_method_or_macro_def(lex, name, name_token.linenumber)
				ast.linenumber = name_token.linenumber
				add(self.ast.methods, ast)
			else
				lex:error'field or method definition expected'
			end
		end
	end
	local ctor = function(getenv)
		local env = getenv()
		self.ast.env = env
		for i,ast in ipairs(self.ast.fields) do ast.env = env end
		for i,ast in ipairs(self.ast.methods) do ast.env = env end
		return self:make_type()
	end
	return ctor, {self.name} --statement: name = ctor(getenv))
end

--<field_name>[: field_type_expr] [=init_const_expr]
function class:parse_field_def(lex, name, linenumber)
	local ast = {name = name, private = name:starts'_' or nil, linenumber = linenumber}
	if lex:nextif':' then
		ast.type_expr = lex:luaexpr()
	end
	if lex:nextif'=' then
		ast.val_expr = lex:luaexpr()
	end
	return ast
end

--method: <name>(arg_name: arg_type_expr, ...)[: ret_type_expr]
--macro:  <name>(arg_name, ...)
function class:parse_method_or_macro_def(lex, name, linenumber)
	lex:expect'('
	local ast = {name = name, args = {}, ismacro = false,
		private = name:starts'_' or nil, linenumber = linenumber}
	while not lex:nextif')' do --method args
		--TODO: support escapes in arg list (splice per Terra semantics)
		local arg = {}
		arg.name = lex:expect(lex.name).value
		if lex:nextif':' then
			arg.type_expr = lex:luaexpr()
		else
			ast.ismacro = true
		end
		lex:nextif','
		add(ast.args, arg)
	end
	if lex:nextif':' then --method return type (optional)
		ast.ret_type_expr = lex:luaexpr()
	end
	ast.body_stmts = ast.ismacro and lex:luastats() or lex:terrastats()
	lex:expect'end'
	return ast
end

--field|method|before|after|over <classname>:<field_def>|<method_def>|<macro_def>
function class:parse_standalone_def(lex)
	local keyword = lex:next().type
	--TODO: support a.b:c syntax
	local clsname = lex:expect(lex.name).value
	lex:ref(clsname)
	lex:expect(keyword == 'field' and '.' or ':')
	local name_token = lex:expect(lex.name)
	local name = name_token.value
	local ast = keyword == 'field'
		and class:parse_field_def(lex, name, name_token.linenumber)
		 or class:parse_method_or_macro_def(lex, name, name_token.linenumber)
	ast.hook =
		   (keyword == 'before'
		 or keyword == 'after'
		 or keyword == 'over') and keyword or nil
	return function(getenv)
		ast.env = getenv()
		local T = ast.env[clsname]
		local self = T.metamethods.class
		assert(not self.fields, 'class ',clsname,' is already compiled')
		if keyword == 'field' then
			add(self.ast.fields, ast)
		else
			add(self.ast.methods, ast)
		end
	end
end

--compiler -------------------------------------------------------------------

--return a unique identity for each method signature across all methods.
--the signature for a terra method is (name, arg1_type, ...).
--the signature for a macro is (name, true) (no overloading for macros).
local sigmt = {}
function sigmt:__tostring()
	local t = {}; for i=1,#self do add(t, tostring(self[i])) end
	return '('..table.concat(t, ', ')..')'
end
local signature = memoize(function(...) return setmetatable({...}, sigmt) end)
function class:signature(...) return signature(...) end

--eval Lua expressions for argument and return types and compute
--the method signature. make arg symbols too for building the method later.
function class:type_method(ast)
	if not ast.ismacro then
		local arg_types = {}
		ast.arg_syms = {symbol(&self.T, 'self')}
		for _,arg in ipairs(ast.args) do
			local arg_type = arg.type_expr and arg.type_expr(ast.env) or arg.type
			arg.type_expr = nil
			add(arg_types, arg_type)
			add(ast.arg_syms, symbol(arg_type, arg.name))
		end
		if ast.ret_type_expr then
			ast.ret_type = ast.ret_type_expr(ast.env); ast.ret_type_expr = nil
		end
		ast.sig = self:signature(ast.name, unpack(arg_types))
	else
		ast.sig = self:signature(ast.name, true)
	end
end

--make a terra function from scratch given all the necessary ingredients.
local nothing = quote end
local function mkterra(arg_syms, ret_type, body_quote)
	body_quote = body_quote or nothing
	return ret_type
		and terra([arg_syms]): ret_type body_quote end
		 or terra([arg_syms]) body_quote end
end

--make a terra function with the same type as another function but with its
--body constructed by a constructor which receives the arg symbols.
local function mksameterra(func, mkbody, self_type)
	local arg_syms = {} --pluck arg symbols from func's definition.
	for i,var_ in ipairs(func.definition.parameters) do
		add(arg_syms, var_.symbol)
	end
	if self_type then
		arg_syms[1] = symbol(&self_type, 'self')
	end
	local ret_type = func:gettype().returntype
	local body_quote = mkbody and mkbody(arg_syms)
	return mkterra(arg_syms, ret_type, body_quote)
end

--build a terra function in a lexical environment. extra_arg_syms are extra
--symbols to inject in the function environment and pass as first args.
function class:compile_terra(ast, extra_arg_syms, inherited_func)
	local arg_syms = extra_arg_syms
		and extend({}, extra_arg_syms, ast.arg_syms) or ast.arg_syms
	local fenv = setmetatable({}, {__index = ast.env})
	local self_sym = symbol(&self.T, 'self')
	fenv.self = self_sym
	for i,arg_sym in ipairs(arg_syms) do
		fenv[arg_sym.displayname] = arg_sym
	end
	self.T.methods.inherited = inherited_func
	local body_quote = ast.body_stmts(fenv)
	local func = mkterra(arg_syms, ast.ret_type, body_quote)
	self.T.methods.inherited = nil
	return func
end

--build a macro in a lexical environment.
function class:compile_macro(ast)
	local fenv = setmetatable({}, {__index = ast.env})
	return macro(function(self, ...)
		fenv.self = self
		for i,arg in ipairs(ast.args) do
			fenv[arg.name] = select(i, ...)
		end
		return ast.body_stmts(fenv)
	end)
end

local compile_terra_override = {}

function compile_terra_override:over(ast, func)
	local func_type = func:gettype()
	local inherited_sym = symbol(&func_type, 'inherited')
	local over_func = self:compile_terra(ast, {inherited_sym}, func)
	return mkterra(ast.arg_syms, func_type.returntype, quote
		var [inherited_sym] = func
		return over_func([inherited_sym], [ast.arg_syms])
	end)
end

function compile_terra_override:before(ast, func)
	local before_func = self:compile_terra(ast)
	return mkterra(ast.arg_syms, ast.ret_type, quote
		before_func([ast.arg_syms])
		return func([ast.arg_syms])
	end)
end

function compile_terra_override:after(ast, func)
	local ret_type = func:gettype().returntype
	if ret_type:isunit() then
		local after_func = self:compile_terra(ast)
		return mkterra(ast.arg_syms, ret_type, quote
			func([ast.arg_syms])
			after_func([ast.arg_syms])
		end)
	else
		--make `retval` available in the hook's environment
		if not ast.ret_type or ast.ret_type:isunit() then
			local retval_sym = symbol(&ret_type, 'retval')
			local after_func = self:compile_terra(ast, {retval_sym}, func)
			return mkterra(ast.arg_syms, ret_type, quote
				var retval = func([ast.arg_syms])
				after_func(&retval, [ast.arg_syms])
				return retval
			end)
		else --hook returns a value: return it back.
			return mkterra(ast.arg_syms, ret_type,
				`after_func(func([ast.arg_syms]), [ast.arg_syms])
			)
		end
	end
end

function class:compile_terra_override(ast, func)
	return compile_terra_override[ast.hook](self, ast, func)
end

--add or overload a method.
function class:add_method(sig, func)
	local name = assert(sig[1])
	local func0 = self.T.methods[name]
	if not func0 then
		self.T.methods[name] = func
	else
		if type(func0) == 'overloadedterrafunction' then
			func0:adddefinition(func)
		elseif type(func0) == 'terrafunction' then
			local func = terralib.overloadedfunction(name, {func0, func})
			self.T.methods[name] = func
		elseif type(func0) == 'terramacro' then
			error('duplicate definition for macro '..name..'()')
		end
	end
end

function class:compile_header()
	--eval super_expr in `class <name>: <super_expr>`
	if self.ast.super_expr then
		local st = self.ast.super_expr(self.ast.env)
		if st then
			assert(st:isstruct(), 'trying to inherit from non-struct type',st)
			self.super = assert(st.metamethods.class, 'struct is not a class ',st)
		end
	end
end

function class:compile_fields()
	if self.fields then return end

	--inherit super's fields at the same offsets.
	if self.super then
		self.super:compile_fields()
		for i,entry in ipairs(self.super.T.entries) do
			self.T.entries[i] = {
				type = entry.type,
				name = entry.name,
				field = entry.private
					and (self.super and entry.field or tostring(i))
					 or entry.name and self.name..'.'..entry.name or entry.field,
				private = entry.private,
			}
		end
	else
		add(self.T.entries, {field = '__vtable', type = &&opaque})
	end

	--type the new fields, sort them by size for better packing and add them.
	for i,ast in ipairs(self.ast.fields) do
		ast.type = ast.type_expr and ast.type_expr(ast.env) or ast.type; ast.type_expr = nil
		ast.val = ast.val_expr and ast.val_expr(ast.env); ast.val_expr = nil
		assert(ast.val or ast.type, 'field type or initial value expected')
		ast.type = ast.type or (`ast.val):gettype()
	end
	sort(self.ast.fields, function(ast1, ast2)
		return sizeof(ast1.type) > sizeof(ast2.type)
	end)
	for i,ast in ipairs(self.ast.fields) do
		local entry = {
			field = self.name..'.'..ast.name,
			type = ast.type,
			name = ast.name,
			private = ast.private,
		}
		add(self.T.entries, entry)
	end

	--create field maps to find fields by name.
	self.fields = {}
	for i,entry in ipairs(self.T.entries) do
		if entry.name then
			self.fields[entry.name] = entry
		end
	end

	self.T.metamethods.__entrymissing = macro(function(name, obj)
		--call a field getter instead. getters overshadow field access.
		if self.T.methods['get_'..name] then
			return `obj:['get_'..name]()
		end
		--qualify field names (this is how super's private fields get hidden).
		local entry = assert(self.fields[name], 'field not found: ',name)
		return `obj.[entry.field]
	end)

	self.T.metamethods.__setentry = macro(function(name, obj, rhs)
		--call a field setter instead. setters overshadow field assignment.
		if self.T.methods['set_'..name] then
			return quote obj:['set_'..name](rhs) end
		end
		--qualify field names (this is how super's private fields get hidden).
		local entry = self.fields[name]
		return entry and quote obj.[entry.field] = rhs end
	end)

	--create init() and free() methods (or hooks).
	--1. initialize all fields that have a default value in decl. order.
	--2. call init() and free() on all non-pointer fields that have it,
	--so all non-pointer structs are considered owned by default.

	insert(self.ast.methods, 1, {name = 'init', args = {}, body_stmts = function(env)
		local fields = self.ast.fields
		local self = env.self
		local t = {}
		for _,e in ipairs(fields) do
			if e.val then
				add(t, quote self.[e.name] = [e.val] end)
			elseif e.type:isstruct() and e.type.methods.init
				and #e.type.methods.init.type.parameters == 1 --default initializer
			then
				add(t, quote self.[e.name]:init() end)
			end
		end
		return t
	end, hook = self.super and 'after'})

	insert(self.ast.methods, 1, {name = 'free', args = {}, body_stmts = function(env)
		local fields = self.ast.fields
		local self = env.self
		local t = {}
		for _,e in ipairs(fields) do
			if e.type:isstruct() and e.type.methods.free then
				add(t, quote self.[e.name]:free() end)
			end
		end
		return t
	end, hook = self.super and 'before'})

end

function class:compile_methods()
	if self.methods then return end
	self.T:complete()

	self.methods = {} --{sig  -> method}
	self.vtable  = {} --{vidx -> vfunc}
	self.vindex  = {} --{sig  -> vidx}

	if self.super then
		self.super:compile_methods()
		--inherit the vtable (later modified with overrides).
		extend(self.vtable, self.super.vtable)
		update(self.vindex, self.super.vindex)
		--inherit non-private methods.
		for sig,m in pairs(self.super.methods) do
			if not m.private then
				self.methods[sig] = {
					func = m.func, --static function or vtable accessor.
					vfunc = m.vfunc,  --virtual function, this is the impl.
					ismacro = m.ismacro,
				}
			end
		end
	end

	--add new (to-compile) methods and method hooks, in order.
	for i,ast in ipairs(self.ast.methods) do
		self:type_method(ast)
		local m = self.methods[ast.sig]
		if not m then
			assert(not ast.hook, 'missing method to override for ',self.name,':',ast.name)
			m = {ast = ast, private = ast.private, ismacro = ast.ismacro}
			self.methods[ast.sig] = m
		else
			assert(ast.hook, 'duplicate definition for ',self.name,':',ast.name)
			assert(m.ast or m.vfunc, 'trying to override static method ',self.name,':',ast.name)
			m.inherited = m.vfunc or true
		end
	end

	--make stubs for all methods that have a new implementation so that
	--method references can be resolved by terra eagerly.
	--NOTE: method references can also be solved in a __methodmissing
	--handler but that would require duplicating the terra logic for chosing
	--an overloaded definition for a particular combination of arg types.
	--This method has its own big drawback: return-type inference doesn't work
	--anymore.
	for sig,m in pairs(self.methods) do
		if not m.ismacro then
			local stub
			if m.ast then --new method
				stub = mkterra(m.ast.arg_syms, m.ast.ret_type)
			elseif m.inherited then --override
				stub = mksameterra(m.inherited, nil, self.T)
			end
			if stub then
				if self.vindex[sig] then --replace entry in vtable
					m.vfunc = stub
					self.vtable[self.vindex[sig]] = stub
				elseif not m.private then --create new entry in vtable
					assert(not self.vindex[sig])
					m.vfunc = stub
					--allocate a new slot and method stub
					local vidx = #self.vtable + 1
					self.vindex[sig] = vidx
					self.vtable[vidx] = stub
					local func_type = stub:gettype()
					m.func = mksameterra(stub, function(args)
						return quote
							var fn = [&func_type]([args[1]].__vtable[vidx-1])
							return fn([args])
						end
					end)
				else --static private method
					m.func = stub
				end
			end
		end
		self:add_method(sig, m.func)
	end

	local function resetdefinition(stub, func, ast)
		local ok, err = pcall(function()
			stub:resetdefinition(func)
		end)
		if not ok then
			err = err .. '\n' .. 'at line: ' .. ast.linenumber
			error(err, 2)
		end
	end

	--compile all new methods and method hooks so we can build the vtable.
	for i,ast in ipairs(self.ast.methods) do
		local m = self.methods[ast.sig]
		local stub = m.vfunc or m.func
		if not ast.ismacro then
			if not ast.hook then
				local func = self:compile_terra(ast)
				if m.inherited then --hooked on in the same class
					m.inherited = func
				else
					resetdefinition(stub, func, ast)
				end
			else
				local func = self:compile_terra_override(
					ast, m.inherited or m.vfunc)
				resetdefinition(stub, func, ast)
				m.inherited = func
			end
		else
			assert(not ast.hook or ast.hook == 'over')
			local func = self:compile_macro(ast)
			m.vfunc = func
			m.func = func
			self.T.methods[ast.sig[1]] = func
		end
	end

	self.__vtable = constant(`arrayof([&opaque], [self.vtable]))
end

function class:make_type()
	self.T = newstruct(self.name)
	self.T.metamethods.class = self

	self:compile_header()

	function self.T.metamethods.__getentries()
		self:compile_fields()
		return self.T.entries
	end

	function self.T.metamethods.__getmethod(T, name)
		self:compile_methods()
		self.T.metamethods.__getmethod = nil
		return self.T.methods[name]
	end

	--implicit cast of &derived to &ancestor. serves two purposes:
	--calling ancestor methods with a derived object as self without a cast.
	--inheriting ancestor methods into derived types without re-typing them.
	function self.T.metamethods.__cast(from, to, exp)
		if from == niltype then
			self:compile_methods()
			return quote
				var t: self.T
				t.__vtable = self.__vtable
				t:init()
				in t
			end
		end
		if from:ispointer() and to:ispointer() then
			local to_ptr = to
			local from, to = from.type, to.type
			while from ~= to and from ~= nil do
				local mm = from.metamethods
				from = mm and mm.class and mm.class.super and mm.class.super.T
			end
			if from ~= nil then
				return `[to_ptr](exp)
			end
		end
		error(tostring(from)..' is not a subtype of '..tostring(to))
	end

	return self.T
end

--language extension ---------------------------------------------------------

local oopslang = {
	name = 'oopslang';
	entrypoints = {'class', 'method', 'field', 'before', 'after', 'over'};
	keywords = {};
}

function oopslang:expression(lex)
	return class:parse_class_expr(lex)
end

function oopslang:statement(lex)
	if lex:matches'class' then
		return class:parse_class_expr(lex)
	else
		return class:parse_standalone_def(lex)
	end
end
oopslang.localstatement = oopslang.statement

return oopslang
