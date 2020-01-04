--[[

	Terra build system, C header generator and LuaJIT ffi binding generator.
	Written by Cosmin Apreutesei. Public Domain.

Features:

	* compiles and links shared libraries.
	* creates C header files and LuaJIT ffi bindings.
	* supports structs, methods, global functions and global vars.
	* dependent struct and function pointer types are declared automatically.
	* tuples and function pointers are typedef'ed with friendly unique names.
	* struct typedefs are anonymous (except when forward declarations are
	  needed because of circular references) which allows the same struct
	  definition to appear in multiple ffi bindings without raising an error.
	* auto-assigns methods to types via ffi.metatype.
	* enables getters and setters via ffi.metatype.
	* publishes global numbers and bitmask values as enums.
	* diff-friendly deterministic output.

Terra type and function object attributes for controlling the output:

	* `cname`   : type/function name override.
	* `opaque`  : declare a type but don't define it.
	* `cprefix` : prefix method names.
	* `private` : tag method as private.
	* `public_methods`: specify which methods to publish.
	* `const_args`: specify which args have the const qualifier.

Conventions:

	* method names that start with an underscore are private by default.

Usage:

	local lib = require'terra.binder'.lib

	MyStruct.cname = 'my_struct_t'
	MyStruct.opaque = true
	MyStruct.methods.myMethod.cname = 'my_method'
	MyStruct.public_methods = {foo=1,bar=1,...}
	MyFunc.cname = 'my_func'
	MyOverloadedFunc.cname = {'my_func', 'my_func2'}
	MyFuncPointer.type.cname = 'myfunc_callback_t'
	MyFunc.const_args = {nil, true} --make arg#2 const (for passing Lua strings)

	local mylib = lib'mylib'

	mylib(MyStruct) --publish Terra struct MyStruct and its dependent types.
	mylib(MyFunc)   --publish Terra function MyFunc and its dependent types.
	mylib(_M, 'SP_', 'CP_') --publish all SP_FOO enums as CP_FOO.
	mylib(_M)       --publish all all-uppercase keys from _M as C enums.

	mylib:build{
		linkto = {'lib1', 'lib2', ...},
		optimize = false,  --for faster compile time when developing.
	}
	mylib:gen_ffi_binding()
	mylib:gen_c_header()

Note:

	C and LuaJIT ffi cannot handle all types of circular struct dependencies
	that Terra can handle, in particular you can't declare a struct with
	forward-declared struct fields (unlike Terra, C eager-completes types).
	This means that you might need to add some types manually in some rare cases.

]]

assert(terra, 'terra not loaded')

if not ... then require'terra.binder_test'; return end

setfenv(1, require'terra.low'.module())

--C defs generator -----------------------------------------------------------

function cdefs()

	--C type name generation --------------------------------------------------

	local ctype --fw. decl. (used recursively)

	local function clean_cname(s)
		return s:gsub('[%.%${},()]+', '_')
	end

	local function cname_fragment(T)
		return T:isintegral() and tostring(T):gsub('32$', '')
			or T == rawstring and 'string'
			or T:ispointer() and 'p' .. cname_fragment(T.type)
			or clean_cname(ctype(T))
	end

	local function append_cname_fragment(s, T, n)
		if not T then return s end
		local t = cname_fragment(T)
		return s .. (s ~= '' and  '_' or '') .. t .. (n > 1 and n or '')
	end
	local function unique_cname(types)
		local type0, n = nil, 0
		local s = ''
		for i,type in ipairs(types) do
			if type ~= type0 then
				s = append_cname_fragment(s, type0, n)
				type0, n = type, 1
			else
				n = n + 1
			end
		end
		return append_cname_fragment(s, type0, n)
	end

	local function tuple_cname(T)
		--each tuple entry is the array {name, type}, hence plucking index 2.
		return unique_cname(glue.map(T.entries, 2))
	end

	local function funcptr_cname(T)
		local s = unique_cname(T.parameters)
		s = s .. (s ~= '' and '_' or 'void_') .. 'to'
		return append_cname_fragment(s, T.returntype, 1)
	end

	local function func_cname(func)
		assert(not func.name:find'^anon ', 'unnamed function')
		return clean_cname(func.name)
	end

	local function overload_cname(over)
		local t = {}
		local over_name = func_cname(over)
		for i,func in ipairs(over.definitions) do
			t[i] = func.cname or over_name..(i ~= 1 and i or '')
		end
		return t
	end

	local function globalvar_cname(glob)
		assert(glob.name ~= '<global>', 'unnamed global')
		return clean_cname(glob.name)
	end

	function ctype(v) --(fw. declared)
		if	   type(v) == 'terrafunction'
			or type(v) == 'overloadedterrafunction'
			or type(v) == 'terraglobalvariable'
		then
			return v.cname
				or type(v) == 'terrafunction'           and func_cname(v)
				or type(v) == 'overloadedterrafunction' and overload_cname(v)
				or type(v) == 'terraglobalvariable'     and globalvar_cname(v)
		else
			assert(type(v) == 'terratype', 'invalid arg type ', type(v))
			local T = v
			if T == terralib.types.opaque or T:isunit() then
				return 'void'
			elseif T:isintegral() then
				return tostring(T)..'_t'
			elseif T:isfloat() or T:islogical() then
				return tostring(T)
			elseif T:ispointer() then
				if T.type:isfunction() then
					return ctype(T.type) --C's funcptr is its own type.
				else
					return ctype(T.type)..'*'
				end
			elseif T:isarray() then
				return ctype(T.type)..'['..T.N..']'
			elseif T:isstruct() or T:isfunction() then
				return T.cname
					or T:istuple() and tuple_cname(T)
					or T:isstruct() and clean_cname(tostring(T))
					or T:isfunction() and funcptr_cname(T)
			else
				assert(false, 'unsupported type ', T)
			end
		end
	end
	ctype = memoize(ctype)

	--C def generation --------------------------------------------------------

	local cdefs = {} --{str1, ...}; C def string accumulation buffer.
	local tdefs --typedefs at current level in typedef stack.
	local tdefstack = {}

	local function start_def()
		push(tdefstack, tdefs)
		tdefs = {}
	end

	local function end_def()
		extend(cdefs, tdefs)
		tdefs = pop(tdefstack)
	end

	local cdef --fw. decl. (used recursively)

	local function cdef_args(T, func)
		if #T.parameters == 0 then
			add(tdefs, 'void')
		else
			for i,arg in ipairs(T.parameters) do
				if func and func.const_args and func.const_args[i] then
					add(tdefs, 'const ') --allow passing Lua strings without copying.
				end
				add(tdefs, cdef(arg, false))
				if i < #T.parameters then
					add(tdefs, ', ')
				end
				if T.isvararg then
					add(tdefs, ', ...')
				end
			end
		end
	end

	local function cdef_func(func, cname)
		local T = func:gettype()
		start_def()
		append(tdefs, cdef(T.returntype, false), ' ', cname, '(')
		cdef_args(T, func)
		add(tdefs, ');\n')
		end_def()
	end

	local function cdef_overload(over, cname)
		for i,func in ipairs(over.definitions) do
			cdef_func(func, cname[i])
		end
	end

	local function cdef_globalvar(glob, cname)
		local T = glob:gettype()
		assert(glob:isextern(), glob, ':isextern() is false')
		start_def()
		append(tdefs, cdef(T, false), ' ', cname, ';\n')
		end_def()
	end

	--recursive struct typedefs -----------------------------------------------

	local decl  = {} --{T->false|true}

	local function cdef_entries(tdefs, entries, indent)
		for i,e in ipairs(entries) do
			for i=1,indent do add(tdefs, '\t') end
			if #e > 0 and type(e[1]) == 'table' then --union
				add(tdefs, 'union {\n')
				cdef_entries(tdefs, e, indent + 1)
				for i=1,indent do add(tdefs, '\t') end
				add(tdefs, '};\n')
			else --struct or tuple
				local field = e.field or e[1]
				local type  = e.type  or e[2]
				append(tdefs, cdef(type, false), ' ', field, ';\n')
			end
		end
	end

	local function declare_struct(T, cname)
		start_def()
		append(tdefs, 'typedef struct ', cname, ' ', cname, ';\n')
		end_def()
	end

	local function define_struct(T, cname, nodef)
		if T.opaque then
			assert(nodef ~= false, T, ' is opaque but its definition is needed')
			declare_struct(T, cname)
		else
			start_def()
			local entries = {}
			cdef_entries(entries, T.entries, 1)
			if decl[T] then --fw. declared: define it.
				append(tdefs, 'struct ', cname, ' {\n')
				extend(tdefs, entries)
				append(tdefs, '};\n')
			else --declare it as anonymous.
				append(tdefs, 'typedef struct {\n')
				extend(tdefs, entries)
				append(tdefs, '} ', cname, ';\n')
			end
			end_def()
		end
	end

	local function typedef_funcptr(T, cname)
		start_def()
		append(tdefs, 'typedef ', cdef(T.returntype, false), ' (*', cname, ') (')
		cdef_args(T)
		add(tdefs, ');\n')
		end_def()
	end

	local function typedef(T, cname, nodef) --fw. decl.
		local declared = decl[T]
		local defined = declared == 'defined'
		if defined or (declared and nodef) then return end
			local defining = declared == false
		if defining or nodef then
			if T:isstruct() then
				declare_struct(T, cname)
			elseif T:isfunction() then
				assert(not defining) --funcptr decls can't be cyclical.
				typedef_funcptr(T, cname)
			else
				assert(false)
			end
			decl[T] = true --mark as declared.
		else
			decl[T] = false --mark as "defining".
			assert(T:isstruct()) --only structs can be defined.
			define_struct(T, cname, nodef)
			decl[T] = 'defined' --mark as defined.
		end
	end

	function cdef(v, nodef) --(fw. declared)
		local cname = ctype(v)
		if type(v) == 'terrafunction' then
			cdef_func(v, cname)
		elseif type(v) == 'overloadedterrafunction' then
			cdef_overload(v, cname)
		elseif type(v) == 'terraglobalvariable' then
			cdef_globalvar(v, cname)
		else
			local T = v
			if T:ispointer() then
				cdef(T.type, true)
			elseif T:isarray() then
				cdef(T.type, false)
			elseif T:isstruct() and not T:isunit() then
				typedef(T, cname, nodef)
			elseif T:isfunction() then
				typedef(T, cname, true)
			end
		end
		return cname
	end

	--enums -------------------------------------------------------------------

	function cdef_enum(t, match, prefix)
		local function find(k, v, match)
			if type(k) == 'string' and type(v) == 'number' then
				if match then
					return k:sub(1, #match) == match
				else --by default, all all-uppercase keys match as enums
					return k:upper() == k
				end
			end
		end
		local enums = {}
		local function add_enums(match, prefix)
			local keys = {}
			for k,v in pairs(t) do
				if find(k, v, match) then
					add(keys, k)
				end
			end
			sort(keys)
			for i,k in ipairs(keys) do
				local v = tostring(t[k])
				if match then k = k:sub(#match + 1) end
				if prefix then k = prefix .. k end
				append(enums, '\t', k:upper(), ' = ', v, last and '\n' or ',\n')
			end
		end
		if type(match) == 'table' then --{match -> prefix}
			for match, prefix in pairs(match) do
				add_enums(match, prefix)
			end
		else
			add_enums(match, prefix)
		end
		if #enums > 0 then
			add(cdefs, 'enum {\n')
			extend(cdefs, enums)
			add(cdefs, '};\n')
		end
	end

	--user API ----------------------------------------------------------------

	local self = {}
	setmetatable(self, self)

	function self:enum(...) cdef_enum(...) end
	function self:ctype(v) return ctype(v) end
	function self:cdef(v) return cdef(v) end
	function self:dump() return concat(cdefs) end
	function self:__call(arg, ...)
		if type(arg) == 'table' then
			return self:enum(arg, ...)
		elseif arg then
			return self:cdef(arg)
		else
			return self:dump()
		end
	end

	return self
end

--shared lib builder ---------------------------------------------------------

function lib(modulename)

	local self = {}
	setmetatable(self, self)

	local cdefs = cdefs()

	local symbols = {} --{cname->func}; for saveobj().
	local objects = {} --{{obj=,cname=}|{obj=,cname=,methods|getters|setters={name->cname},...}

	local function add_func(func)
		local cname = cdefs:cdef(func)
		if type(cname) == 'table' then --overloaded
			for i,cname in ipairs(cname) do
				symbols[cname] = func.definitions[i]
			end
		else
			symbols[cname] = func
		end
		return cname
	end

	local function publish_func(func)
		local cname = add_func(func)
		add(objects, {obj = func, cname = cname})
	end

	local function method_is_private(func, name)
		if func.private ~= nil then return func.private end
		return name:find'^_' and true or false
	end

	local function publish_struct(T, public_methods)
		local pub = public_methods or T.public_methods
		if pub then
			for method in sortedpairs(pub) do
				local func = getmethod(T, method)
				if not func then
					print('Warning: method missing '..tostring(T)..':'..method..'()')
				elseif not type(func):find'terrafunction$' then
					print('Warning: method is not a function '..tostring(T)..':'..method..'()')
				end
			end
		end
		local struct_cname = cdefs:cdef(T)
		local cprefix = T.cprefix or struct_cname:gsub('_t$', '') .. '_'
		cancall(T, '') --force getmethod() to add all the methods.
		local st = {obj = T, cname = struct_cname, methods = {}, getters = {}, setters = {}}
		add(objects, st)
		for name, func in sortedpairs(T.methods) do
			local public
			if pub then --explicitly public
				public = pub[name]
			else --implicitly public
				public = not method_is_private(func, name)
			end
			if public and not type(func):find'terrafunction$' then
				public = false
			end
			if public then
				if type(func) == 'overloadedterrafunction' then
					local cname = type(public) == 'table' and public or func.cname
					assert(type(cname) == 'table',
						'Overloaded function ', T, ':', name, '() needs explicit cname list')
					--prefix the cnames of each overloaded implementation.
					--add separate methods for each overloaded implementation.
					func.cname = {}
					for i,cname in ipairs(cname) do
						func.cname[i] = cprefix .. cname
						st.methods[cname] = cprefix .. cname
					end
				else
					local name = type(public) == 'string' and public or name
					local cname = cprefix .. (func.cname or name)
					func.cname = cname
					if T.gettersandsetters then
						if name:starts'get_' and #func.type.parameters == 1 then
							st.getters[name:gsub('^get_', '')] = cname
						elseif name:starts'set_' and #func.type.parameters == 2 then
							st.setters[name:gsub('^set_', '')] = cname
						else
							st.methods[name] = cname
						end
					else
						st.methods[name] = cname
					end
				end
				add_func(func)
			end
		end
	end

	function self:publish(v, ...)
		if type(v) == 'terrafunction' or type(v) == 'overloadedterrafunction' then
			publish_func(v)
		elseif type(v) == 'terratype' and v:isstruct() then
			publish_struct(v, ...) --struct, [public_methods]
		elseif type(v) == 'table' then --enums
			cdefs:enum(v, ...) --match, prefix
		else
			assert(false, 'invalid arg type ', type(v))
		end
	end

	self.__call = self.publish

	function self:cdefs()
		return cdefs:dump()
	end

	function self:c_header()
		return '/* This file was auto-generated. Modify at your own risk. */\n\n'
			..cdefs:dump()
	end

	--generating LuaJIT ffi binding -------------------------------------------

	local function defmap(t, rs)
		for name, cname in sortedpairs(rs) do
			append(t, '\t', name, ' = C.', cname, ',\n')
		end
	end

	function self:ffi_binding()
		local t = {}
		add(t, '-- This file was auto-generated. Modify at your own risk.\n\n')
		add(t, "local ffi = require'ffi'\n")
		append(t, "local C = ffi.load'", modulename, "'\n")
		add(t, 'ffi.cdef[[\n')
		add(t, cdefs:dump())
		add(t, ']]\n')
		for i,o in ipairs(objects) do
			if next(o.getters or empty) or next(o.setters or empty) then
				add(t, 'local getters = {\n'); defmap(t, o.getters); add(t, '}\n')
				add(t, 'local setters = {\n'); defmap(t, o.setters); add(t, '}\n')
				add(t, 'local methods = {\n'); defmap(t, o.methods); add(t, '}\n')
				append(t, [[
ffi.metatype(']], o.cname, [[', {
	__index = function(self, k)
		local getter = getters[k]
		if getter then return getter(self) end
		return methods[k]
	end,
	__newindex = function(self, k, v)
		local setter = setters[k]
		if not setter then
			error(('field not found: %s'):format(tostring(k)), 2)
		end
		setter(self, v)
	end,
})
]])
			elseif next(o.methods or empty) then
				append(t, 'ffi.metatype(\'', o.cname, '\', {__index = {\n')
				defmap(t, o.methods)
				add(t, '}})\n')
			end
		end
		add(t, 'return C\n')
		return concat(t)
	end

	function self:ffi_manual_binding()
		local t = {}
		add(t, '-- This file was auto-generated. Modify at your own risk.\n')
		add(t, "local ffi = require'ffi'\n")
		append(t, "local C = ffi.load'", modulename, "'\n")
		add(t, 'local M = {C = C, types = {}, __index = C}\n')
		add(t, 'setmetatable(M, M)')
		add(t, 'ffi.cdef[[\n')
		add(t, cdefs:dump())
		add(t, ']]\n')
		for i,o in ipairs(objects) do
			local g = next(o.getters or empty)
			local s = next(o.setters or empty)
			local m = next(o.methods or empty)
			if g or s or m then
				append(t, 'local t = {}\n')
				append(t, 'M.types.', o.cname, ' = t\n')
				if g then add(t, 't.getters = {\n'); defmap(t, o.getters); add(t, '}\n') end
				if s then add(t, 't.setters = {\n'); defmap(t, o.setters); add(t, '}\n') end
				if m then add(t, 't.methods = {\n'); defmap(t, o.methods); add(t, '}\n') end
			end
		end
		add(t, [[
function M.wrap(ct, what, field, func)
	local t = M.types[ct][what]
	t[field] = func(t[field])
end
function M.done()
	for ct,t in pairs(M.types) do
		local getters = t.getters or {}
		local setters = t.setters or {}
		local methods = t.methods or {}
		ffi.metatype(ct, {
			__index = function(self, k)
				local getter = getters[k]
				if getter then return getter(self) end
				return methods[k]
			end,
			__newindex = function(self, k, v)
				local setter = setters[k]
				if not setter then
					error(('field not found: %s'):format(tostring(k)), 2)
				end
				setter(self, v)
			end,
		})
	end
	return C
end
]])
		add(t, 'return M\n')
		return concat(t)
	end

	--building ----------------------------------------------------------------

	function self:binpath(filename)
		return terralib.terrahome..(filename and '/'..filename or '')
	end

	function self:luapath(filename)
		return terralib.terrahome..'/../..'..(filename and '/'..filename or '')
	end

	function self:objfile()
		return self:binpath(modulename..'.o')
	end

	function self:sofile()
		local soext = {Windows = 'dll', OSX = 'dylib', Linux = 'so'}
		return self:binpath(modulename..'.'..soext[ffi.os])
	end

	function self:afile()
		return self:binpath(modulename..'.a')
	end

	function self:saveobj(optimize)
		zone'saveobj'
		terralib.saveobj(self:objfile(), 'object', symbols, nil, nil, optimize ~= false)
		zone()
	end

	function self:removeobj()
		os.remove(self:objfile())
	end

	function self:linkobj(linkto)
		zone'linkobj'
		local linkargs = linkto and '-l'..concat(linkto, ' -l') or ''
		local cmd = 'gcc '..self:objfile()..' -shared '..'-o '..self:sofile()
			..' -L'..self:binpath()..' '..linkargs
		os.execute(cmd)
		local cmd = 'ar rcs '..self:afile()..' '..self:objfile()
		os.execute(cmd)
		zone()
	end

	--TODO: make this work. Doesn't export symbols on Windows.
	function self:savelibrary(linkto)
		zone'savelibrary'
		local linkargs = linkto and '-l'..concat(linkto, ' -l') or ''
		terralib.saveobj(self:sofile(), 'sharedlibrary', symbols, linkargs)
		zone()
	end

	function self:build(opt)
		opt = opt or {}
		if true then
			self:saveobj(opt.optimize)
			self:linkobj(opt.linkto)
			self:removeobj()
		else
			self:savelibrary(opt.linkto)
		end
	end

	function self:gen_c_header(opt)
		zone'gen_c_header'
		opt = type(opt) == 'string' and {filename = opt} or opt or empty
		local filename = self:luapath(opt.filename or modulename .. '.h')
		writefile(filename, self:c_header(), nil, filename..'.tmp')
		zone()
	end

	function self:gen_ffi_binding(opt)
		zone'gen_ffi_binding'
		opt = type(opt) == 'string' and {filename = opt} or opt or empty
		local filename = self:luapath(opt.filename or modulename .. '_h.lua')
		local code = opt.manual and self:ffi_manual_binding() or self:ffi_binding()
		writefile(filename, code, nil, filename..'.tmp')
		zone()
	end

	return self
end

return _M
