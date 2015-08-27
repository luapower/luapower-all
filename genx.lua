--genx xml generator binding.

if not ... then require'genx_demo' end

local ffi = require'ffi'
local C = ffi.load'genx'
local M = {C = C}
require'genx_h'

local function checkh(w, statusP, h)
	if h ~= nil then return h end
	local s = C.genxGetErrorMessage(w, statusP[0])
	error(s ~= nil and ffi.string(s) or 'unknown error')
end

local function checknz(w, status)
	if status == 0 then return end
	local s = C.genxGetErrorMessage(w, status)
	error(s ~= nil and ffi.string(s) or 'unknown error')
end

local function nzcaller(f)
	return function(w, ...)
		return checknz(w, f(w, ...))
	end
end

function M.version()
	return ffi.string(C.genxGetVersion())
end

function M.new(alloc, dealloc, userdata)
	local w = C.genxNew(alloc, dealloc, userdata)
	assert(w ~= nil, 'out of memory')
	ffi.gc(w, C.genxDispose)
	return w
end

local senders = {} --{[genxWriter] = genxSender}

local function free_sender(w)
	local sender = senders[w]
	if not sender then return end
	sender.send:free()
	sender.sendBounded:free()
	sender.flush:free()
	senders[w] = nil
end

local function free(w)
	C.genxDispose(ffi.gc(w, nil))
	free_sender(w)
end

ffi.metatype('genxWriter_rec', {__index = {

	free = free,

	start_doc = function(w, f, ...)
		free_sender(w)
		if type(f) == 'function' then
			--f is called as either: f(s), f(s, sz), or f() to signal EOF.
			local sender = ffi.new'genxSender'
			sender.send = ffi.new('send_callback', function(_, s) f(s); return 0 end)
			sender.sendBounded = ffi.new('sendBounded_callback', function(_, p1, p2) f(p1, p2-p1); return 0 end)
			sender.flush = ffi.new('flush_callback', function() f(); return 0 end)
			senders[w] = sender
			checknz(w, C.genxStartDocSender(w, sender))
		else
			checknz(w, C.genxStartDocFile(w, f))
		end
	end,

	end_doc = nzcaller(C.genxEndDocument),

	ns = function(w, uri, prefix, statusP)
		statusP = statusP or ffi.new'genxStatus[1]'
		return checkh(w, statusP, C.genxDeclareNamespace(w, uri, prefix, statusP))
	end,

	element = function(w, name, ns, statusP)
		statusP = statusP or ffi.new'genxStatus[1]'
		return checkh(w, statusP, C.genxDeclareElement(w, ns, name, statusP))
	end,

	attr = function(w, name, ns, statusP)
		statusP = statusP or ffi.new'genxStatus[1]'
		return checkh(w, statusP, C.genxDeclareAttribute(w, ns, name, statusP))
	end,

	comment = nzcaller(C.genxComment),

	pi = nzcaller(C.genxPI),

	start_element = function(w, e, ns, prefix)
		if type(ns) == 'string' then
			ns = w:ns(ns, prefix)
		end
		if type(e) == 'string' then
			e = w:element(e, ns)
		end
		checknz(w, C.genxStartElement(e))
	end,

	add_attr = function(w, a, val, ns, prefix)
		if type(ns) == 'string' then
			ns = w:ns(ns, prefix)
		end
		if type(a) == 'string' then
			a = w:attr(a, ns)
		end
		checknz(w, C.genxAddAttribute(a, val))
	end,

	add_ns = function(w, ns, prefix)
		if type(ns) == 'string' then
			ns = w:ns(ns, prefix)
		end
		checknz(w, C.genxAddNamespace(ns, prefix))
	end,

	unset_default_namespace = nzcaller(C.genxUnsetDefaultNamespace),

	end_element = nzcaller(C.genxEndElement),

	text = function(w, s, sz)
		checknz(w, C.genxAddCountedText(w, s, sz or #s))
	end,

	char = nzcaller(C.genxAddCharacter),

	check_text = C.genxCheckText,

	scrub_text = function(s_in)
		s_out = ffi.new('constUtf8[?]', #s_in + 1)
		if C.genxScrubText(s_in, s_out) ~= 0 then
			return ffi.string(s_out)
		else
			return s_in
		end
	end,

}, __gc = free})

return M

