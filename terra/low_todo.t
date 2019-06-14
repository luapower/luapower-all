
--auto-initializer -----------------------------------------------------------

local function gen_init_code(T, self, code)
	local entries = T:getlayout().entries
	for i = 1, #entries do
		local e = entries[i]
		if e.type:islogical() then
			add(code, quote self.[e.key] = false end)
		elseif e.type:isarithmetic() then
			add(code, quote self.[e.key] = 0 end)
		elseif e.type:isstruct() then
			if not e.type.methods.init then
				local k = symbol(&e.type, e.key)
				add(code, quote var [k] = &self.[e.key] end)
				gen_init_code(e.type, k, code)
			else
				add(code, quote self.[e.key]:init() end)
			end
		else
			add(code, quote self.[e.key] = nil end)
		end
	end
end

local function gen_free_code(T, self, code)
	local entries = T:getlayout().entries
	for i = #entries, 1, -1 do
		local e = entries[i]
		if e.type:isstruct() then
			if not e.type.methods.free then
				local k = symbol(&e.type, e.key)
				add(code, quote var [k] = &self.[e.key] end)
				gen_free_code(e.type, k, code)
			else
				add(code, quote self.[e.key]:free() end)
			end
		end
	end
end

low.autoinit = function(T, after_init, before_free)
	local self = symbol(&T, 'self')
	local init_code = {}
	gen_init_code(T, self, init_code)
	add(init_code, after_init)
	T.methods.init = terra([self])
		[ init_code ]
	end
	local free_code = {}
	gen_free_code(T, self, free_code)
	add(free_code, before_free)
	T.methods.free = terra([self])
		[ free_code ]
	end
	T.metamethods.__cast = function(from, to, exp)
		if from == niltype then
			return quote var t = T{}; t:init(); in t end
		else
			error'invalid cast'
		end
	end
end

--variable-length struct -----------------------------------------------------

low.VLS = macro(function(T, VT, len)
	T = T:astype()
	VT = VT:astype()
	return quote
		assert(len >= 0)
		var v = [&T](malloc(sizeof(T) + sizeof(VT) + len))
		memset(v, 0, sizeof(T))
		in v
	end
end)

--checked allocators ---------------------------------------------------------

low.allocs = function()
	local C = {}; setmetatable(C, C).__index = low.C
	local size_t = uint64

	terra C.realloc(p0: &opaque, size: size_t)
		var p = realloc(p0, size)
		--TODO: track memory here
		return p
	end
	--the following functions are based on realloc only.
	terra C.malloc(size: size_t): &opaque
		return C.realloc(nil, size)
	end
	terra C.calloc(n: size_t, size: size_t)
		var p = C.realloc(nil, n * size)
		if p ~= nil then memset(p, 0, n * size) end
		return p
	end
	terra C.free(p: &opaque)
		C.realloc(p, 0)
	end
	return C
end
