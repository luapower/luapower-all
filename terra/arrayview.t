
--[[

	Array view type for Terra.
	Written by Cosmin Apreutesei. Public domain.

	An array view maps the idea of a finite array onto a memory location.

	local V = arrayview{T=,[size_t=int],[cmp=]} create a type from Lua
	local V = arrayview(T, [size_t=int],[cmp])  create a type from Lua
	var v =   arrayview{T=,[size_t=int],[cmp=]} create a value from Terra
	var v =   arrayview(T, [size_t=int],[cmp])  create a value from Terra
	var v =   arrayview(T, elements,len[ ,...]) create a value from Terra
	var v = V(nil)                              nil-cast (for use in global())
	var v = V{elements,len}                     field order is part of the API
	var v = V{elements=,len=}                   fields are part of the API

	v.elements, v.len                           fields are part of the API

	v:clamp(i) -> i                             clamp i to valid index
	v:index(i[,default]) -> i|default           valid positive index
	v(i[,default]) -> t|default                 get element at index
	v:at(i[,default]) -> &t|default             get element address at index
	v:set(i,t)                                  set element at index
	for i,&t in v do ... end                    iterate elements
	for i,&t in v:ipairs([forward],[step]) do.. iterate elements with iterator
	for i,&t in v:backwards([step]) do..        iterate elements backwards

	v:range(i,j) -> start,len                   v:range(5, 5) -> 5, 0
	v:sub(i,j) -> v                             create a sub-view
	v:copy(&t) -> &t                            copy to buffer
	v:copy(v) -> v                              copy to view
	v:fill(t)                                   set all elements to value

	v1 == v2                                    equality test
	v:__cmp(&v) -> -1,0,1                       comparison function
	v:__hash32(seed) -> h                       32bit hash function
	v:__hash64(seed) -> h                       64bit hash function

	v1 <|<=|==|>=|>|~= v2                       compare views

	cmp = {&T, &T} -> int32                     type of element comparison function
	v:sort([cmp])                               sort elements
	v:sort_desc()                               sort descending
	v:find(t[,default]) -> i                    find element
	v:count(t) -> n                             element occurences
	v:binsearch(t, [cmp]) -> i                  binsearch (sort the view first!)
	v:binsearch(t, v.lt|v.lte|v.gt|v.gte) -> i  binsearch with built-in cmp

	v:reverse()                                 reverse order of elements
	v:call(method, args...)                     call method on each element

	v:index(&t[,default]) -> i|default          element index by address
	v:next(&t,[&default]) -> &t|&default        next element
	v:prev(&t,[&default]) -> &t|&default        previous element

]]

if not ... then require'terra.arrayview_test'; return end

setfenv(1, require'terra.low')

local either = macro(function(v, a, b)
	return quote var v = v in v == a or v == b end
end)

local function view_type(T, size_t, cmp)

	--unsigned sizes not supported because we use -1 to signal an invalid index.
	assert(size_t:min() < 0)

	local struct view {
		elements: &T;
		len: size_t; --number of valid elements
	}

	view.T = T
	view.empty = `view{elements = nil, len = 0}

	newcast(view, niltype, function(exp)
		view:getmethod'' --force creation of methods
		return view.empty
	end)

	--debugging

	function view.metamethods.__typename(self)
		return 'arrayview('..tostring(T)..')'
	end

	function view.metamethods.__tostring(self, format_arg, fmt, args, freelist, indent)
		add(fmt, '%s[%d]<%llx>')
		add(args, tostring(T))
		add(args, `self.len)
		add(args, `self.elements)
	end

	--default method

	view.metamethods.__apply = macro(function(self, i, default)
		if default then return `self:get(i, default) else return `self:get(i) end
	end)

	--iteration

	view.metamethods.__for = function(self, body)
		return quote
			var self = self --workaround for terra issue #368
			for i = 0, self.len do
				[ body(i, `&self.elements[i]) ]
			end
		end
	end

	local struct iter { view: view; forward: bool; step: size_t; }
	iter.metamethods.__for = function(self, body)
		return quote
			var self = self --workaround for terra issue #368
			if self.forward then
				for i = 0, self.view.len, self.step do
					[ body(i, `&self.view.elements[i]) ]
				end
			else
				for i = self.view.len-1, -1, -self.step do
					[ body(i, `&self.view.elements[i]) ]
				end
			end
		end
	end
	view.methods.ipairs = macro(function(self, forward, step)
		forward = forward or true
		step = step or 1
		return `iter {self, forward, step}
	end)

	view.methods.backwards = macro(function(self, step)
		step = step or 1
		return `iter {self, false, step}
	end)

	addmethods(view, function()

		--bounds-checked access

		terra view:clamp(i: size_t)
			return clamp(i, 0, self.len-1)
		end

		view.methods.index = overload'index'
		view.methods.index:adddefinition(terra(self: &view, i: size_t, default: size_t)
			return iif(i >= 0 and i < self.len, i, default)
		end)
		view.methods.index:adddefinition(terra(self: &view, i: size_t)
			assert(i >= 0 and i < self.len, 'index out of range')
			return i
		end)

		view.methods.at = overload'at'
		view.methods.at:adddefinition(terra(self: &view, i: size_t): &T
			return &self.elements[self:index(i)]
		end)
		view.methods.at:adddefinition(terra(self: &view, i: size_t, default: &T): &T
			i = self:index(i, -1)
			return iif(i ~= -1, &self.elements[i], default)
		end)

		view.methods.get = overload'get'
		view.methods.get:adddefinition(terra(self: &view, i: size_t): T
			return self.elements[self:index(i)]
		end)
		view.methods.get:adddefinition(terra(self: &view, i: size_t, default: T): T
			i = self:index(i, -1)
			return iif(i ~= -1, self.elements[i], default)
		end)

		terra view:set(i: size_t, val: T)
			self.elements[self:index(i)] = val
		end

		view.methods.get_first = macro(function(self) --returns a lvalue
			return quote
				assert(self.len > 0, 'first: array empty')
				in self.elements[0]
			end
		end)

		view.methods.get_last = macro(function(self) --returns a lvalue
			return quote
				assert(self.len > 0, 'last: array empty')
				in self.elements[self.len-1]
			end
		end)

		--sub-views

		--NOTE: j is not the last position, but one position after that.
		--NOTE: if j < i, j is adjusted, not i.
		terra view:range(i: size_t, j: size_t)
			assert(i >= 0)
			i = min(i, self.len)
			j = max(i, j)
			j = min(j, self.len)
			return i, j-i
		end

		view.methods.sub = overload'sub'
		view.methods.sub:adddefinition(terra(self: &view, i: size_t, j: size_t)
			var start, len = self:range(i, j)
			return view {elements = self.elements + start, len = len}
		end)
		view.methods.sub:adddefinition(terra(self: &view, i: size_t)
			return self:sub(i, self.len)
		end)

		--copy out

		view.methods.copy = overload'copy'
		view.methods.copy:adddefinition(terra(self: &view, dst: &T)
			copy(dst, self.elements, self.len)
			return dst
		end)
		view.methods.copy:adddefinition(terra(self: &view, dst: view)
			copy(dst.elements, self.elements, min(dst.len, self.len))
			return dst
		end)

		terra view:fill(v: T)
			for i,e in self do
				@e = v
			end
		end

		--comparing views for inequality

		local user_cmp = cmp
		if not user_cmp then
			--elements must be compared via comparison operators.
			local use_op = T.metamethods and T.metamethods.__eq and T.metamethods.__lt

			--elements must be compared via comparison operators.
			if use_op or T:isarithmetic() or T:ispointer() then
				cmp = terra(a: &T, b: &T): int32 --for sorting this view
					return iif(@a == @b, 0, iif(@a < @b, -1, 1))
				end
			end

			--uint8 arrays can be mem-compared directly.
			if not use_op and T == uint8 then
				terra view:__cmp(v: &view) --for comparing views
					if v.len ~= self.len then
						return iif(self.len < v.len, -1, 1)
					end
					return bitequal(self.elements, v.elements, self.len)
				end
			end
		end

		--compare views by comparing elements individually.
		if cmp and not view.methods.__cmp then
			terra view:__cmp(v: &view)
				if v.len ~= self.len then
					return iif(self.len < v.len, -1, 1)
				end
				for i,val in self do
					var r = cmp(val, v:at(i))
					if r ~= 0 then
						return r
					end
				end
				return 0
			end
		end

		--make all inequality comparison operators work too.
		if view.methods.__cmp then
			view.metamethods.__lt = terra(self: &view, v: &view) return self:__cmp(v) == -1 end
			view.metamethods.__gt = terra(self: &view, v: &view) return self:__cmp(v) ==  1 end
			view.metamethods.__le = terra(self: &view, v: &view) return either(self:__cmp(v), -1, 0) end
			view.metamethods.__ge = terra(self: &view, v: &view) return either(self:__cmp(v),  1, 0) end
		end

		--comparing views for equality

		if user_cmp then
			--elements must be compared via user-supplied comparison function.
			terra view:__eq(v: &view)
				return self:__cmp(v) == 0
			end
		else
			--elements can be compared via `==`, own __eq method or memcmp.
			terra view:__eq(v: &view)
				if v.len ~= self.len then return false end
				return equal(self.elements, v.elements, self.len)
			end
		end

		--make `==` and `~=` operators work too.
		view.metamethods.__eq = view.methods.__eq

		if view.metamethods.__eq then
			view.metamethods.__ne = macro(function(self, other)
				return `not (self == other)
			end)
		end

		--hashing using the default hash function

		terra view:__hash32(seed: uint32)
			return hash(uint32, self.elements, seed, self.len)
		end
		terra view:__hash64(seed: uint64)
			return hash(uint64, self.elements, seed, self.len)
		end

		--memsize for caches and debugging

		terra view:__memsize()
			return sizeof(T) * self.len
		end

		--sorting

		view.methods.sort = overload'sort'
		view.methods.sort:adddefinition(terra(self: &view, cmp: {&T, &T} -> int32)
			qsort(self.elements, self.len, sizeof(T),
				[{&opaque, &opaque} -> int32](cmp))
			return self
		end)

		if cmp then
			view.methods.sort:adddefinition(terra(self: &view)
				return self:sort(cmp)
			end)
			local terra cmp_desc(a: &T, b: &T): int32
				return -cmp(a, b)
			end
			terra view:sort_desc() return self:sort(cmp_desc) end
		end

		--searching

		local eq = user_cmp and macro(function(a, b) return `user_cmp(a, b) == 0 end)
		if not eq and T.metamethods and not T.metamethods.__eq then --use memcmp
			eq = bitequal
		end
		eq = eq or macro(function(a, b) return `@a == @b end)

		view.methods.find = overload'find'
		view.methods.find:adddefinition(terra(self: &view, val: T, default: size_t)
			for i,v in self do
				if eq(v, &val) then
					return i
				end
			end
			return default
		end)
		view.methods.find:adddefinition(terra(self: &view, val: T)
			for i,v in self do
				if eq(v, &val) then
					return i
				end
			end
			assert(false, 'element not found')
		end)

		terra view:count(val: T)
			var n: size_t = 0
			for i, v in self do
				if eq(v, &val) then
					n = n + 1
				end
			end
			return n
		end

		--binary search for an insert position that keeps the array sorted.

		local lt, gt, lte, gte
		if cmp then
			lt = terra(a: &T, b: &T) return cmp(a, b) == -1 end
			gt = terra(a: &T, b: &T) return cmp(a, b) ==  1 end
			le = terra(a: &T, b: &T) return either(cmp(a, b), -1, 0) end
			ge = terra(a: &T, b: &T) return either(cmp(a, b),  1, 0) end
		elseif not T:isaggregate() then --TODO: fix this
			lt = terra(a: &T, b: &T) return @a <  @b end
			gt = terra(a: &T, b: &T) return @a >  @b end
			le = terra(a: &T, b: &T) return @a <= @b end
			ge = terra(a: &T, b: &T) return @a >= @b end
		end
		--expose comparators as virtual fields of the view.
		if lt then
			addproperties(view)
			view.properties.lt = lt
			view.properties.gt = gt
			view.properties.le = le
			view.properties.ge = ge
		end

		--binary search for the first insert position that keeps the array sorted.
		view.methods.binsearch = overload'binsearch'
		view.methods.binsearch:adddefinition(
		terra(self: &view, v: T, cmp: {&T, &T} -> bool): size_t
			var lo = [size_t](0)
			var hi = self.len-1
			var i = hi + 1
			while true do
				if lo < hi then
					var mid: int = lo + (hi - lo) / 2
					if cmp(&self.elements[mid], &v) then
						lo = mid + 1
					else
						hi = mid
					end
				elseif lo == hi and not cmp(&self.elements[lo], &v) then
					return lo
				else
					return i
				end
			end
		end)
		if lt then
			view.methods.binsearch:adddefinition(terra(self: &view, v: T): size_t
				return self:binsearch(v, lt)
			end)
		end

		--reversing the order of elements

		terra view:reverse()
			var j = self.len-1
			for k = 0, (j+1)/2 do
				swap(self.elements[k], self.elements[j-k])
			end
			return self
		end

		--calling methods on the elements

		view.methods.call = macro(function(self, method, ...)
			local args = {...}
			return `call(self.elements, method, self.len, args)
		end)

		--pointer interface

		view.methods.index:adddefinition(terra(self: &view, pv: &T, default: size_t)
			return self:index(pv - self.elements, default)
		end)
		view.methods.index:adddefinition(terra(self: &view, pv: &T)
			return self:index(pv - self.elements)
		end)

		view.methods.next = overload'next'
		view.methods.next:adddefinition(terra(self: &view, pv: &T, default: &T)
			var i = pv - self.elements
			return iif(i >= 0 and i < self.len-1, self.elements + i + 1, default)
		end)
		view.methods.next:adddefinition(terra(self: &view, pv: &T)
			var i = pv - self.elements
			assert(i >= 0 and i < self.len-1, 'next: eoa')
			return self.elements + i + 1
		end)

		view.methods.prev = overload'prev'
		view.methods.prev:adddefinition(terra(self: &view, pv: &T, default: &T)
			var i = pv - self.elements
			return iif(i > 0 and i < self.len, self.elements + i - 1, default)
		end)
		view.methods.prev:adddefinition(terra(self: &view, pv: &T)
			var i = pv - self.elements
			assert(i > 0 and i < self.len, 'prev: boa')
			return self.elements + i - 1
		end)

		setinlined(view.methods)

	end) --addmethods

	return view
end
view_type = memoize(view_type)

local view_type = function(T, size_t, cmp)
	if terralib.type(T) == 'table' then
		T, size_t, cmp = T.T, T.size_t, T.cmp
	end
	assert(T)
	size_t = size_t or int
	cmp = cmp or getmethod(T, '__cmp')
	return view_type(T, size_t, cmp)
end

arrview = macro(
	--calling it from Terra returns a new view.
	function(arg1, ...)
		local T, lval, len, size_t, cmp
		if arg1 and arg1:islvalue() then --wrap raw pointer: arrayview(&t, len, ...)
			lval, len, size_t, cmp = arg1, ...
			T = lval:gettype()
			assert(T:ispointer())
			T = T.type
		else --create new view: arrayview(T, ...)
			T, size_t, cmp = arg1, ...
			T = T and T:astype()
		end
		size_t = size_t and size_t:astype()
		local view = view_type(T, size_t, cmp)
		if lval then
			return quote var v: view; v.elements = lval; v.len = len in v end
		else
			return `view{}
		end
	end,
	--calling it from Lua returns just the type.
	view_type
)
