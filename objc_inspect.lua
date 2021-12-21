local objc = require'objc'

local inspect = {}
objc.inspect = inspect

--pretty helpers

local _ = string.format

local function p(...) --formatted line
	print(_(...))
end

local function isort(iter, method) --sort an iterator of object by a method
	local t = {}
	while true do
		local v = iter()
		if v == nil then break end
		t[#t+1] = v
	end
	table.sort(t, function(a, b) return a[method](a) < b[method](b) end)
	local i = 0
	return function()
		i = i + 1
		if t[i] == nil then return end
		return t[i]
	end
end

local function icount(iter)
	local n = 0
	for _ in iter do
		n = n + 1
	end
	return n
end

--class header

local function protocols_spec(protocols)
	local t = {}
	for proto in isort(protocols, 'name') do
		t[#t+1] = proto:name() .. protocols_spec(proto:protocols())
	end
	return #t > 0 and _(' <%s>', table.concat(t, ', ')) or ''
end

local function class_spec(cls, indent)
	indent = indent or 1
	local super_spec = objc.superclass(cls) and
		_('\n%s<- %s', ('  '):rep(indent), class_spec(objc.superclass(cls), indent + 1)) or ''
	return objc.classname(cls) .. protocols_spec(objc.protocols(cls)) .. super_spec
end

local function protocol_spec(proto)
	return proto:name() .. protocols_spec(proto:protocols())
end

function inspect.class_header(cls)
	p('Class %s', class_spec(objc.class(cls)))
end

--classes

function inspect.classes()
	for cls in objc.classes() do
		p('%-50s protocols: %-5s properties: %-5s ivars: %-5s methods (i): %-5s methods (c): %-5s',
			objc.classname(cls),
			icount(objc.protocols(cls)),
			icount(objc.properties(cls)),
			icount(objc.ivars(cls)),
			icount(objc.methods(cls)),
			icount(objc.methods(objc.metaclass(cls))))
	end
end

--protocols

function inspect.protocols()
	for proto in objc.protocols() do
		p('%-50s %-10s protocols: %-5s properties: %-5s methods (i/o): %-5s methods (i/r): %-5s methods (c/o): %-5s methods (c/r): %-5s',
			proto:name(), proto.formal and 'formal' or 'informal',
			icount(proto:protocols()),
			icount(proto:properties()),
			icount(proto:methods(true,  false)),
			icount(proto:methods(true,  true)),
			icount(proto:methods(false, false)),
			icount(proto:methods(false, true)))
	end
end

--properties

local function inspect_properties(name, props)
	for prop in isort(props, 'name') do
		p('%-30s %-40s %-8s %-20s %-20s %-20s %-20s',
				name, prop:name(), prop:readonly() and 'r/o' or 'r/w',
				prop:ctype(), prop:ivar() or '', prop:getter(), prop:setter() or '')
	end
end

local function not_(arg, list, process, ...)
	if arg then return end
	for arg in list() do
		process(arg, ...)
	end
	return true
end

function inspect.protocol_properties(proto)
	if not_(proto, objc.protocols, inspect.protocol_properties) then return end
	proto = objc.protocol(proto)
	inspect_properties(proto:name(), proto:properties())
end

function inspect.class_properties(cls)
	if not_(cls, objc.classes, inspect.class_properties) then return end
	cls = objc.class(cls)
	inspect_properties(objc.classname(cls), objc.properties(cls))
end

--methods

function inspect.class_methods(cls, inst)
	if not_(cls, objc.classes, inspect.class_methods, inst) then return end
	cls = inst and objc.class(cls) or objc.metaclass(cls)
	for meth in isort(objc.methods(cls), 'name') do
		p('%-40s %-50s %-50s %s', objc.classname(cls), meth:name(),
				objc.ftype_ctype(objc.method_ftype(cls, meth:selector(), meth)), meth:mtype())
	end
end

function inspect.protocol_methods(proto, inst, required)
	if not_(proto, objc.protocols, inspect.protocol_methods, inst, required) then return end
	proto = objc.protocol(proto)
	for selname, mtype in proto:methods(inst or false, required or false) do
		p('%-40s %-50s %-50s %s', proto:name(), selname, objc.ftype_ctype(objc.mtype_ftype(mtype)), mtype)
	end
end

--ivars

function inspect.class_ivars(cls)
	if not_(cls, objc.classes, inspect.ivars) then return end
	cls = objc.class(cls)
	for ivar in isort(objc.ivars(cls), 'name') do
		p('%-40s %-50s %-50s %-5s %s', objc.classname(cls), ivar:name(), ivar:ctype(),
												tonumber(ivar:offset()), ivar:stype())
	end
end

--full class inspection

function inspect.class(cls)
	print''
	inspect.class_header(cls)
	print'\nProperties:\n'
	inspect.class_properties(cls)
	print'\nIvars:\n'
	inspect.class_ivars(cls)
	print'\nMethods:\n'
	inspect.class_methods(cls)
end

function inspect.protocol(proto)
	print''
	print(objc.protocol(proto):name())
	print'\nProperties:\n'
	inspect.protocol_properties(proto)
	print'\nMethods (i/o):\n'
	inspect.protocol_methods(proto, true, false)
	print'\nMethods (i/r):\n'
	inspect.protocol_methods(proto, true, true)
	print'\nMethods (c/o):\n'
	inspect.protocol_methods(proto, false, false)
	print'\nMethods (c/r):\n'
	inspect.protocol_methods(proto, false, true)
end

function inspect.find(patt)
	--TODO: find framework / load all frameworks
	local function find_in_class(prefix, cls)
		for meth in objc.methods(cls) do
			if meth:name():find(patt) then
				p('%-20s [%s %s]', prefix..' method', objc.classname(cls), meth:name())
			end
		end
		for prop in objc.properties(cls) do
			if prop:name():find(patt) then
				p('%-20s %s.%s', prefix..' property', objc.classname(cls), prop:name())
			end
		end
		for ivar in objc.ivars(cls) do
			if ivar:name():find(patt) then
				p('%-20s %s.%s', prefix..' ivar', objc.classname(cls), ivar:name())
			end
		end
	end
	for cls in objc.classes() do
		if objc.classname(cls):find(patt) then
			p('%-20s %s', 'class', objc.classname(cls))
		end
		find_in_class('instance', cls)
		find_in_class('class', cls)
	end
	local function find_proto_method(proto, postfix, inst, required)
		for selname in proto:methods(inst, required) do
			if selname:find(patt) then
				p('%-20s [%s %s]', 'protocol method ('..postfix..')', proto:name(), selname)
			end
		end
	end
	for proto in objc.protocols() do
		if proto:name():find(patt) then
			p('%-20s %s', 'protocol', proto:name())
		end
		find_proto_method(proto, 'i/o', true, false)
		find_proto_method(proto, 'i/r', true, true)
		find_proto_method(proto, 'c/o', false, false)
		find_proto_method(proto, 'c/r', false, true)
		for prop in proto:properties() do
			if prop:name():find(patt) then
				p('%-20s %s.%s', 'protocol property', proto:name(), prop:name())
			end
		end
	end
	local function find_global(title, prefix, namespace)
		for k in pairs(namespace) do
			if type(k) == 'string' and k:find(patt) then
				p('%-20s %s%s', title, prefix, k)
			end
		end
	end
	find_global('global', 'objc.', objc)
	find_global('C global', 'objc.', objc.debug.cnames.global)
	find_global('C struct', '', objc.debug.cnames.struct)
end


if not ... then
	for k,v in pairs(inspect) do
		print(_('%-10s %s', type(v), 'objc.inspect.'..k))
	end
end

return inspect
