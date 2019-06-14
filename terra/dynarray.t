--[[

	Dynamic array type for Terra.
	Written by Cosmin Apreutesei. Public domain.

	A dynamic array is a typed interface over realloc().

	When the array owns its elements (own_elements ~= false, the default),
	elem:free() is called on each element that gets removed or replaced.

	local A = arr{T=,...}                       create a type from Lua
	local A = arr(T, [size_t=int])              create a type from Lua
	var a =   arr{T=,...}                       create a value from Terra
	var a =   arr(T, [size_t=int])              create a value from Terra
	var a =   arr(T, elements, len[,...])       create a value from Terra
	var a = A(nil)                              nil-cast (for use in global())
	var a = A(&v)                               copy constructor from view
	var a = A(&a)                               copy constructor from array

	a:init() | fill(&a)                         initialize (for struct members)

	a:free()                                    free the elements and free the array
	a:setcapacity(n) -> ok?                     `a.capacity = n` with error checking

	var a = A(rawstring|'string constant')      cast from C string
	a:fromrawstring(rawstring)                  init with C string

	a.view                                      (read/only) arr's arrayview
	a.elements                                  (read/only) array elements
	a.len                                       (read/write) array length
	a:setlen(len) -> new_elems                  set length and return new elements view
	a:setlen(len,empty_t)                       set length and set new elements
	a.capacity                                  (read/write) array capacity
	a.min_len                                   (write/only) grow array
	a.min_capacity                              (write/only) grow capacity

	a:set(i,t) -> &t                            replace value
	a:set(i) -> &t                              free value and get its address
	a:set(i,t,empty_t) -> &t                    grow array and set value or replace value
	a:getat(i) -> &t, new_elems                 grow array or get address
	a:getat(i,empty_t) -> &t                    grow array or get address

	a:push|add() -> &t                          a:insert(self.len)
	a:push|add(t) -> i                          a:insert(self.len, t)
	a:push|add(&t,n) -> i                       a:insert(self.len, &t, n)
	a:push|add(&v) -> i                         a:insert(self.len, &v)
	a:push|add(&a) -> i                         a:insert(self.len, &a)
	a:pop() -> t                                remove top value and return a copy

	a:insertn(i,n)                              make room for n elements at i
	a:insertn(i,n,empty_t)                      grow array or make room for n elements
	a:insert(i) -> &t                           make room at i and return address
	a:insert(i,t)                               insert element at i
	a:insert(i,&t,n)                            insert buffer at i
	a:insert(i,&v)                              insert arrayview at i
	a:insert(i,&a)                              insert dynarray at i
	a:remove() -> i                             free & remove top element
	a:remove(i,[n])                             free & remove n elements starting at i
	a:remove(&t) -> i                           free & remove element at address

	a:copy() -> &a                              copy to new array
	a:move(i0,i1)                               move element to new position

	a:METHOD(...) -> a.view:METHOD(...)         call a method of a.view through a

]]

if not ... then require'terra/dynarray_test'; return end

setfenv(1, require'terra/low')

local arr_type = memoize(function(T, size_t, context_t, cmp, own_elements)

	local view = arrview(T, size_t, cmp)

	local struct arr (gettersandsetters) {
		view: view;
		_capacity: size_t;
		context: context_t;
	}

	arr.view = view
	arr.empty = `arr{view = nil; _capacity = 0}

	function arr.metamethods.__typename(self)
		return 'arr('..tostring(T)..')'
	end

	function arr.metamethods.__cast(from, to, exp)
		if to == arr then
			if T == int8 and from == rawstring then
				return quote var a = arr(nil); a:fromrawstring(exp) in a end
			elseif from == niltype then
				return arr.empty
			elseif from == view then
				return quote var a = arr(nil); a:add(v) in a end
			elseif from == arr and to == arr then
				return quote var a = arr(nil); a:add(a) in a end
			end
		end
		assert(false, 'invalid cast from ', from, ' to ', to, ': ', exp)
	end

	function arr.metamethods.__tostring(self, format_arg, fmt, args, freelist, indent)
		add(fmt, '%s[%d]<%llx>')
		add(args, tostring(T))
		add(args, `self.len)
		add(args, `self.elements)
	end

	arr.methods.get_len      = macro(function(self) return `self.view.len end)
	arr.methods.get_capacity = macro(function(self) return `self._capacity end)
	arr.methods.get_elements = macro(function(self) return `self.view.elements end)

	arr.metamethods.__apply = view.metamethods.__apply
	arr.metamethods.__for = view.metamethods.__for

	addmethods(arr, function()

		own_elements = own_elements and cancall(T, 'free')

		if context_t ~= tuple() then
			terra arr:init(context: context_t)
				@self = [arr.empty]
				self.context = context
			end
			terra arr:free_element(i: size_t)
				call(self.elements[i], 'free', 1, self.context)
			end
		else
			terra arr:init()
				@self = [arr.empty]
			end
			terra arr:free_element(i: size_t)
				call(self.elements[i], 'free')
			end
		end

		terra arr:free_elements()
			for i = 0, self.len do
				self:free_element(i)
			end
		end

		terra arr:free()
			if self.capacity == 0 and self.elements ~= nil then return end
			--^the view was assigned by the user (elements are not owned).
			if own_elements then
				self:free_elements()
			end
			realloc(self.view.elements, 0)
			self.view.elements = nil
			self.view.len = 0
			self._capacity = 0
		end

		terra arr:setcapacity(capacity: size_t): bool
			assert(capacity >= self.len)
			if capacity == self.capacity then return true end
			if capacity == 0 then self:free(); return true end
			if self.capacity == 0 and self.elements ~= nil then return false end
			--^the view was assigned by the user (elements are not owned).
			var elements = realloc(self.elements, capacity)
			if elements == nil then return false end
			self.view.elements = elements
			self._capacity = capacity
			return true
		end

		terra arr:set_capacity(capacity: size_t)
			assert(self:setcapacity(max(self.len, capacity)))
		end

		terra arr:set_min_capacity(capacity: size_t)
			capacity = nextpow2(capacity)
			assert(self:setcapacity(max(self.capacity, capacity)))
		end

		terra arr:set_len(len: size_t)
			assert(len >= 0)
			self.min_capacity = len
			if own_elements then
				if len < self.len then --shrink
					for i = len, self.len do
						self:free_element(i)
					end
				end
			end
			self.view.len = len
		end

		arr.methods.setlen = overload'setlen'
		arr.methods.setlen:adddefinition(terra(self: &arr, len: size_t)
			var len0 = self.len
			self.len = len
			return self.view:sub(len0)
		end)
		arr.methods.setlen:adddefinition(terra(self: &arr, len: size_t, empty_val: T)
			var new_elems = self:setlen(len)
			for _,e in new_elems do
				@e = empty_val
			end
		end)

		terra arr:set_min_len(len: size_t)
			self.len = max(len, self.len)
		end

		if view:getmethod'onrawstring' then
			terra arr:fromrawstring(s: rawstring)
				var v = view(s)
				self.len = v.len
				v:copy(self.elements)
				return self
			end
		end

		--setting, pushing and popping elements

		arr.methods.set = overload'set'
		arr.methods.set:adddefinition(terra(self: &arr, i: size_t)
			assert(i >= 0 and i < self.len)
			if own_elements then
				self:free_element(i)
			end
			return &self.elements[i]
		end)
		arr.methods.set:adddefinition(terra(self: &arr, i: size_t, val: T)
			var e = self:set(i)
			@e = val
			return e
		end)
		--set variant that grows the array automatically, filling the gap with empty_val.
		arr.methods.set:adddefinition(terra(self: &arr, i: size_t, val: T, empty_val: T)
			if i >= self.len then --fill the gap
				var j = self.len
				self.len = i+1
				for j = j, i do
					self.elements[j] = empty_val
				end
				var e = &self.elements[i]
				@e = val
				return e
			else
				return self:set(i, val)
			end
		end)

		--TODO: find a better name for this pattern
		arr.methods.getat = overload'getat'
		arr.methods.getat:adddefinition(terra(self: &arr, i: size_t)
			var new_elems = self:setlen(max(self.len, i+1))
			return &self.elements[i], new_elems
		end)
		arr.methods.getat:adddefinition(terra(self: &arr, i: size_t, empty_val: T)
			var elem, new_elems = self:getat(i)
			for _,e in new_elems do
				@e = empty_val
			end
			return &self.elements[i]
		end)

		arr.methods.push = overload'push'
		arr.methods.push:adddefinition(terra(self: &arr)
			var i = self.len
			self.len = i + 1
			return &self.elements[i]
		end)
		arr.methods.push:adddefinition(terra(self: &arr, val: T)
			var i = self.len
			self.len = i + 1
			self.elements[i] = val
			return i
		end)
		arr.methods.add = arr.methods.push

		terra arr:pop()
			var i = self.len-1
			assert(i >= 0)
			var val = self.elements[i]
			self.view.len = i
			return val
		end

		--shifting segments to the left or to the right

		--NOTE: not overloading insert() because of ambiguity with insert(i,T).
		arr.methods.insertn = overload'insertn'
		arr.methods.insertn:adddefinition(terra(self: &arr, i: size_t, n: size_t)
			var len = self.len
			assert(i >= 0 and i <= len) --no gaps allowed
			assert(n >= 0)
			self.len = len + n
			var move_n = len - i
			if move_n > 0 then --move trailing elements if any
				copy(self.elements + i + n, self.elements + i, move_n)
			end
		end)
		arr.methods.insertn:adddefinition(terra(self: &arr, i: size_t, n: size_t, empty_val: T)
			assert(i >= 0)
			assert(n >= 0)
			var len = self.len
			self.len = len + n
			for i = len, i do --fill the gap, if any
				self.elements[i] = empty_val
			end
			var move_n = len - i
			if move_n > 0 then --move trailing elements if any
				copy(self.elements + i + n, self.elements + i, move_n)
			end
		end)

		arr.methods.insert = overload'insert'
		arr.methods.insert:adddefinition(terra(self: &arr, i: size_t)
			self:insertn(i, 1)
			return self.elements + i
		end)
		arr.methods.insert:adddefinition(terra(self: &arr, i: size_t, val: T)
			self:insertn(i, 1)
			self.elements[i] = val
		end)
		arr.methods.insert:adddefinition(terra(self: &arr, i: size_t, p: &T, n: size_t)
			self:insertn(i, n)
			copy(self.elements + i, p, n)
		end)
		arr.methods.insert:adddefinition(terra(self: &arr, i: size_t, v: &view)
			self:insertn(i, v.len)
			v:copy(self.elements + i)
		end)
		arr.methods.insert:adddefinition(terra(self: &arr, i: size_t, a: &arr)
			self:insertn(i, a.len)
			a.view:copy(self.elements + i)
		end)

		arr.methods.add:adddefinition(terra(self: &arr, p: &T, n: size_t)
			var i = self.len; self:insert(i, p, n); return i
		end)
		arr.methods.add:adddefinition(terra(self: &arr, v: &view)
			var i = self.len; self:insert(i, v); return i
		end)
		arr.methods.add:adddefinition(terra(self: &arr, a: &arr)
			var i = self.len; self:insert(i, a); return i
		end)

		arr.methods.remove = overload'remove'
		arr.methods.remove:adddefinition(terra(self: &arr, i: size_t, n: size_t)
			assert(i >= 0)
			assert(n >= 0)
			if own_elements then
				for i = i, min(self.len, i+n) do
					self:free_element(i)
				end
			end
			var move_n = self.len - i - n --how many elements must be moved
			if move_n > 0 then
				copy(self.elements + i, self.elements + i + n, move_n)
			end
			self.view.len = self.len - min(n, self.len-i)
		end)
		arr.methods.remove:adddefinition(terra(self: &arr, i: size_t)
			self:remove(i, 1)
		end)
		arr.methods.remove:adddefinition(terra(self: &arr)
			var i = self.len-1; self:remove(i, 1); return i
		end)
		arr.methods.remove:adddefinition(terra(self: &arr, e: &T)
			var i = self.view:index(e); self:remove(i); return i
		end)

		arr.methods.copy = overload'copy'
		arr.methods.copy:adddefinition(terra(self: &arr, dst: &T)
			return self.view:copy(dst)
		end)
		arr.methods.copy:adddefinition(terra(self: &arr, dst: &view)
			return self.view:copy(dst)
		end)
		arr.methods.copy:adddefinition(terra(self: &arr)
			var a = arr(nil)
			a:add(&self.view)
			return a
		end)

		terra arr:move(i0: size_t, i1: size_t)
			i0 = self.view:index(i0)
			i1 = self.view:index(i1)
			if i1 ~= i0 then
				var move_n = abs(i1 - i0)
				if i1 > i0 then --move in-between elements to the left
					var e0 = self.elements[i0]
					copy(self.elements + i0, self.elements + i0 + 1, move_n)
					self.elements[i1] = e0
				else --move in-between elements to the right
					var e1 = self.elements[i1]
					copy(self.elements + i0 + 1, self.elements + i0, move_n)
					self.elements[i0] = e1
				end
			end
		end

		if view:getmethod'__cmp' then
			terra arr:__cmp(a: &arr)
				return self.view:__cmp(&a.view)
			end
			local m = view.metamethods
			arr.metamethods.__lt = terra(self: &arr, a: &arr) return m.__lt(&self.view, &a.view) end
			arr.metamethods.__gt = terra(self: &arr, a: &arr) return m.__gt(&self.view, &a.view) end
			arr.metamethods.__le = terra(self: &arr, a: &arr) return m.__le(&self.view, &a.view) end
			arr.metamethods.__ge = terra(self: &arr, a: &arr) return m.__ge(&self.view, &a.view) end
		end

		if view:getmethod'__eq' then
			terra arr:__eq(a: &arr)
				return self.view:__eq(&a.view)
			end
			arr.metamethods.__eq = arr.methods.__eq
			arr.metamethods.__ne = macro(function(self, other)
				return not (self == other)
			end)
		end

		terra arr:__memsize()
			return sizeof(T) * self.len
		end

		setinlined(arr.methods, function(name)
			return name ~= 'setcapacty'
		end)

	end) --addmethods()

	--forward all other methods to the view on-demand.
	after_getmethod(arr, function(arr, name)
		if view:getmethod(name) then
			return macro(function(self, ...)
				local args = {...}
				return `self.view:[name]([args])
			end)
		end --fall through to own methods
	end)

	return arr
end)

local arr_type = function(T, size_t)
	local context_t, cmp, own_elements
	if terralib.type(T) == 'table' then
		T, size_t, context_t, cmp, own_elements =
			T.T, T.size_t, T.context_t, T.cmp, T.own_elements
	end
	assert(T)
	size_t = size_t or int
	context_t = context_t or tuple()
	cmp = cmp or getmethod(T, '__cmp')
	own_elements = own_elements ~= false
	return arr_type(T, size_t, context_t, cmp, own_elements)
end

arr = macro(
	--calling it from Terra returns a new array.
	function(arg1, ...)
		local T, lval, len, size_t
		if arg1 and arg1:islvalue() then --wrap raw pointer: arr(&t, len, ...)
			lval, len, size_t = arg1, ...
			T = lval:gettype()
			assert(T:ispointer())
			T = T.type
		else --create new array: arr(T, ...)
			T, size_t = arg1, ...
			T = T and T:astype()
		end
		size_t = size_t and size_t:astype()
		local arr = arr_type(T, size_t)
		if lval then
			return quote var a = arr(nil); a:add(lval, len) in a end
		else
			return `arr(nil)
		end
	end,
	--calling it from Lua or from an escape or in a type declaration returns
	--just the type, and you can also pass a custom C namespace.
	arr_type
)

return _M
