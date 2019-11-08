
setfenv(1, require'terra.low')

local struct mem {
	len: uint64;
	element_size: int;
	element_type: rawstring;
	--info: rawstring;
}

mem.methods.size = macro(function(self) return `self.len * self.element_size end)

local memmap_t = map(&opaque, mem)
local memmap = global(memmap_t, memmap_t.empty)
memmap_t:getmethod'at' --force addmethods() so that the map uses raw alloc.

local total = global(uint64)

local terra checkalloc(p: &opaque, oldp: &opaque, len: int64, sz: size_t, element_type: rawstring, label: rawstring)
	if len == 0 and oldp == nil then
		return
	end
	if p == nil and len > 0 then
		print('alloc failed', element_type, len, label)
		return
	end

	if oldp ~= nil then --realloc or free
		var m = memmap:at(oldp) --reports double-free
		if len > 0 then --realloc
			if p ~= oldp then --rellocated
				--pfn('realloc %s %d', element_type, len)
				dec(total, m:size())
				memmap:remove(oldp)
				goto new
			else --updated
				dec(total, m:size())
				m.len = len
				inc(total, m:size())
			end
		else --free
			assert(p == nil)
			dec(total, m:size())
			memmap:remove(oldp)
		end
	else --new
		::new::
		var m = mem{len = len, element_size = sz, element_type = element_type}
		inc(total, m:size())
		memmap:set(p, m)
	end

	if p ~= oldp then
		if oldp ~= nil and p ~= nil then
			--pfn('>relloc:  %-12s %-8s %x -> %x [%d]', label, element_type, oldp, p, len)
		elseif oldp ~= nil and p == nil then
			--pfn('>free:    %-12s %-8s %x', label, element_type, oldp)
		end
	end
end

local rawalloc = alloc
alloc = macro(function(T, len, oldp, label)
	oldp = oldp or `nil
	len = len or 1
	label = label or ''
	T = T:astype()
	return quote
		var p = rawalloc(T, len, oldp)
		checkalloc(p, oldp, len, [T == opaque and 1 or sizeof(T)], [tostring(T)], label)
		in p
	end
end)

terra memtotal() return total end

terra memreport()
	for k,mem in memmap do
		pfn('%8x %8d %s', k, mem.len, mem.element_type)
	end
	print('------------------------------------------------------------------')
	pfn('LEAK: %d bytes.', total)
end

dp = macro(function(p, sz)
	sz = sz or 1
	local T = p:getpointertype()
	return quote
		for start, mem in memmap do
			if [&opaque](p) >= @start and [&opaque](p + sz) <= [&opaque]([&uint8](@start) + mem:size())
				and strcmp(mem.element_type, [tostring(T)]) == 0
			then
				return
			end
		end
		pfn('out-of-heap access for %s<%x> + %d elements', [tostring(T)], p, sz)
	end
end)

if not ... then

terra test()
	var p = alloc(int, 200)
end
test()

end

return _M
