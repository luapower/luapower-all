
--Expat ffi binding.
--Written by Cosmin Apreutesei. Public Domain.

--parse xml from a string, cdata, file, or reader function.
--  parse(spec_t, callbacks)
--  treeparse(spec_t, [known_tags=]) -> root_node
--    spec_t = {read= | string= | cdata=,size= | path=}
--  	root_node = {tag=, attrs={<k>=v}, children={node1,...}, tags={<tag> = node}, cdata=}

local glue = require'glue'
local ffi = require'ffi'
require'expat_h'
local C = ffi.load'expat'

local cbsetters = {
	'element',        C.XML_SetElementDeclHandler,            ffi.typeof'XML_ElementDeclHandler',
	'attlist',        C.XML_SetAttlistDeclHandler,            ffi.typeof'XML_AttlistDeclHandler',
	'xml',            C.XML_SetXmlDeclHandler,                ffi.typeof'XML_XmlDeclHandler',
	'entity',         C.XML_SetEntityDeclHandler,             ffi.typeof'XML_EntityDeclHandler',
	'start_tag',      C.XML_SetStartElementHandler,           ffi.typeof'XML_StartElementHandler',
	'end_tag',        C.XML_SetEndElementHandler,             ffi.typeof'XML_EndElementHandler',
	'cdata',          C.XML_SetCharacterDataHandler,          ffi.typeof'XML_CharacterDataHandler',
	'pi',             C.XML_SetProcessingInstructionHandler,  ffi.typeof'XML_ProcessingInstructionHandler',
	'comment',        C.XML_SetCommentHandler,                ffi.typeof'XML_CommentHandler',
	'start_cdata',    C.XML_SetStartCdataSectionHandler,      ffi.typeof'XML_StartCdataSectionHandler',
	'end_cdata',      C.XML_SetEndCdataSectionHandler,        ffi.typeof'XML_EndCdataSectionHandler',
	'default',        C.XML_SetDefaultHandler,                ffi.typeof'XML_DefaultHandler',
	'default_expand', C.XML_SetDefaultHandlerExpand,          ffi.typeof'XML_DefaultHandler',
	'start_doctype',  C.XML_SetStartDoctypeDeclHandler,       ffi.typeof'XML_StartDoctypeDeclHandler',
	'end_doctype',    C.XML_SetEndDoctypeDeclHandler,         ffi.typeof'XML_EndDoctypeDeclHandler',
	'unparsed',       C.XML_SetUnparsedEntityDeclHandler,     ffi.typeof'XML_UnparsedEntityDeclHandler',
	'notation',       C.XML_SetNotationDeclHandler,           ffi.typeof'XML_NotationDeclHandler',
	'start_namespace',C.XML_SetStartNamespaceDeclHandler,     ffi.typeof'XML_StartNamespaceDeclHandler',
	'end_namespace',  C.XML_SetEndNamespaceDeclHandler,       ffi.typeof'XML_EndNamespaceDeclHandler',
	'not_standalone', C.XML_SetNotStandaloneHandler,          ffi.typeof'XML_NotStandaloneHandler',
	'ref',            C.XML_SetExternalEntityRefHandler,      ffi.typeof'XML_ExternalEntityRefHandler',
	'skipped',        C.XML_SetSkippedEntityHandler,          ffi.typeof'XML_SkippedEntityHandler',
}

local NULL = ffi.new'void*'
local function str(ptr, size)
	return ptr ~= NULL and ffi.string(ptr, size) or nil
end

local function decode_attrs(attrs) --char** {k1,v1,...,NULL}
	local t = {}
	local i = 0
	while true do
		local k = str(attrs[i]);   if not k then break end
		local v = str(attrs[i+1]); if not v then break end
		t[k] = v
		i = i + 2
	end
	return t
end

local pass_nothing = function(_) end
local cbdecoders = {
	element = function(_, name, model) return str(name), model end,
	attr_list = function(_, elem, name, type, dflt, is_required)
		return str(elem), str(name), str(type), str(dflt), is_required ~= 0
	end,
	xml = function(_, version, encoding, standalone)
		return str(version), str(encoding), standalone ~= 0
	end,
	entity = function(_, name, is_param_entity, val, val_len, base, sysid, pubid, notation)
		return str(name), is_param_entity ~= 0, str(val, val_len), str(base),
					str(sysid), str(pubid), str(notation)
	end,
	start_tag = function(_, name, attrs) return str(name), decode_attrs(attrs) end,
	end_tag = function(_, name) return str(name) end,
	cdata = function(_, s, len) return str(s, len) end,
	pi = function(_, target, data) return str(target), str(data) end,
	comment = function(_, s) return str(s) end,
	start_cdata = pass_nothing,
	end_cdata = pass_nothing,
	default = function(_, s, len) return str(s, len) end,
	default_expand = function(_, s, len) return str(s, len) end,
	start_doctype = function(_, name, sysid, pubid, has_internal_subset)
		return str(name), str(sysid), str(pubid), has_internal_subset ~= 0
	end,
	end_doctype = pass_nothing,
	unparsed = function(name, base, sysid, pubid, notation)
		return str(name), str(base), str(sysid), str(pubid), str(notation)
	end,
	notation = function(_, name, base, sysid, pubid)
		return str(name), str(base), str(sysid), str(pubid)
	end,
	start_namespace = function(_, prefix, uri) return str(prefix), str(uri) end,
	end_namespace = function(_, prefix) return str(prefix) end,
	not_standalone = pass_nothing,
	ref = function(parser, context, base, sysid, pubid)
		return parser, str(context), str(base), str(sysid), str(pubid)
	end,
	skipped = function(_, name, is_parameter_entity) return str(name), is_parameter_entity ~= 0 end,
	unknown = function(_, name, info) return str(name), info end,
}

local parser = {}

function parser.read(read, callbacks, options)
	local cbt = {}
	local function cb(cbtype, callback, decode)
		local cb = ffi.cast(cbtype, function(...) return callback(decode(...)) end)
		cbt[#cbt+1] = cb
		return cb
	end
	local function free_callbacks()
		for _,cb in ipairs(cbt) do
			cb:free()
		end
	end
	glue.fcall(function(finally)
		finally(free_callbacks)

		local parser = options.namespacesep and C.XML_ParserCreateNS(options.encoding, options.namespacesep:byte())
				or C.XML_ParserCreate(options.encoding)
		finally(function() C.XML_ParserFree(parser) end)

		for i=1,#cbsetters,3 do
			local k, setter, cbtype = cbsetters[i], cbsetters[i+1], cbsetters[i+2]
			if callbacks[k] then
				setter(parser, cb(cbtype, callbacks[k], cbdecoders[k]))
			elseif k == 'entity' then
				setter(parser, cb(cbtype,
						function(parser) C.XML_StopParser(parser, false) end,
						function(parser) return parser end))
			end
		end
		if callbacks.unknown then
			C.XML_SetUnknownEncodingHandler(parser,
				cb('XML_UnknownEncodingHandler', callbacks.unknown, cbdecoders.unknown), nil)
		end

		C.XML_SetUserData(parser, parser)

		repeat
			local data, size, more = read()
			if C.XML_Parse(parser, data, size, more and 0 or 1) == 0 then
				error(string.format('XML parser error at line %d, col %d: "%s"',
						tonumber(C.XML_GetCurrentLineNumber(parser)),
						tonumber(C.XML_GetCurrentColumnNumber(parser)),
						str(C.XML_ErrorString(C.XML_GetErrorCode(parser)))))
			end
		until not more
	end)
end

function parser.path(file, callbacks, options)
	glue.fcall(function(finally)
		local f = assert(io.open(file, 'rb'))
		finally(function() f:close() end)
		local function read()
			local s = f:read(16384)
			if s then
				return s, #s, true
			else
				return nil, 0
			end
		end
		parser.read(read, callbacks, options)
	end)
end

function parser.string(s, callbacks, options)
	local function read()
		return s, #s
	end
	parser.read(read, callbacks, options)
end

function parser.cdata(cdata, callbacks, options)
	local function read()
		return cdata, options.size
	end
	parser.read(read, callbacks, options)
end

local function parse(t, callbacks)
	for k,v in pairs(t) do
		if parser[k] then
			parser[k](v, callbacks, t)
			return
		end
	end
	error('unspecified data source: '..table.concat(glue.keys(parser), ', ')..' expected')
end

local function maketree_callbacks(known_tags)
	local root = {tag = 'root', attrs = {}, children = {}, tags = {}}
	local t = root
	local skip
	return {
		cdata = function(s)
			t.cdata = s
		end,
		start_tag = function(s, attrs)
			if skip then skip = skip + 1; return end
			if known_tags and not known_tags[s] then skip = 1; return end

			t = {tag = s, attrs = attrs, children = {}, tags = {}, parent = t}
			local ct = t.parent.children
			ct[#ct+1] = t
			t.parent.tags[t.tag] = t
		end,
		end_tag = function(s)
			if skip then
				skip = skip - 1
				if skip == 0 then skip = nil end
				return
			end

			t = t.parent
		end,
	}, root
end

local function treeparse(t, known_tags)
	local callbacks, root = maketree_callbacks(known_tags)
	parse(t, callbacks)
	return root
end

local function children(t,tag) --iterate a node's children of a specific tag
	local i=1
	return function()
		local v
		repeat
			v = t.children[i]
			i = i + 1
		until not v or v.tag == tag
		return v
	end
end

if not ... then require'expat_test' end

return {
	parse = parse,
	treeparse = treeparse,
	children = children,
	C = C,
}
