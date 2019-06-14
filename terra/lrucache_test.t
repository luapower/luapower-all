
--NOASSERTS=1
setfenv(1, require'terra/low')
require'terra/lrucache'

local S = struct {
	size: intptr;
}

terra S:__memsize()
	return self.size
end

local cache = lrucache{key_t = int, val_t = S}
local terra test(key_range: double, probes: double)
	var cache: cache; cache:init()
	cache.max_size = 10000
	var t0 = clock()
	var misses = 0
	for i = 1, [int64](probes) do
		var key = random(key_range)
		var pair_i, val = cache:get(key)
		if pair_i == -1 then
			inc(misses)
			var val = S{size = random(1000)}
			pair_i = cache:put(key, val)._0
		end
		cache:forget(pair_i)
	end
	pfn('%6.2f Mprobes/s, hit rate: %6.2f%%',
		[double](probes) / (clock() - t0) / 1000 / 1000,
		[double](probes - misses) / probes * 100
	)
end
test( 27, 1000000)
test( 40, 1000000)
test(100, 1000000)
