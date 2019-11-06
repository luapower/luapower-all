--[[

	Freelist for Terra based on a dynamic array.
	Written by Cosmin Apreutesei. Public Domain.

	Element pointers are not stable between allocations, but their indices are,
	which is why alloc() also return the element id (i.e. index).

	local fl = arrayfreelist(T, [size_t], [context_t])

	fl:init()
	fl:free()

	fl:alloc() -> e, id
	fl:new(...) -> e, id
	fl:release()

	fl.livecount -> n

]]

setfenv(1, require'terra/low')

local arrayfreelist_type = memoize(function(T, size_t, context_t)

	local itemlist = arr{T = T, size_t = size_t,
		context_t = context_t, own_elements = false}
	local indexlist = arr{T = size_t, size_t = size_t}

	local struct freelist (gettersandsetters) {
		items: itemlist;
		freeindices: indexlist;
	}

	freelist.empty = `freelist{
		items = [itemlist.empty];
		freeindices = nil;
	}

	newcast(freelist, niltype, freelist.empty)

	freelist.methods.new = macro(function(self, ...)
		local args = {...}
		return quote
			var e, id = self:alloc()
			e:init([args])
			in e, id
		end
	end)

	addmethods(freelist, function()

		if context_t ~= tuple() then
			terra freelist:init(context: context_t)
				@self = [freelist.empty]
				self.items.context = context
			end
		else
			terra freelist:init()
				@self = [freelist.empty]
			end
		end

		terra freelist:free()
			self.items:free_elements()
			self.items:free()
			self.freeindices:free()
		end

		terra freelist:alloc()
			var e: &T
			var id: size_t
			if self.freeindices.len > 0 then
				id = self.freeindices:pop()
				e = self.items:at(id)
			else
				e = self.items:add()
				id = self.items.len-1
			end
			return e, id
		end

		terra freelist:release(i: size_t)
			self.items:free_element(i)
			self.freeindices:add(i)
		end

		terra freelist:get_livecount()
			return self.items.len - self.freeindices.len
		end
	end)

	--forward all other methods to items' view on-demand.
	after_getmethod(freelist, function(freelist, name)
		if itemlist.view:getmethod(name) then
			return macro(function(self, ...)
				local args = {...}
				return `self.items.view:[name]([args])
			end)
		end --fall through to own methods
	end)

	return freelist
end)

arrayfreelist = function(T, size_t, context_t)
	context_t = context_t or tuple()
	size_t = size_t or int
	return arrayfreelist_type(T, size_t, context_t)
end

return _M
