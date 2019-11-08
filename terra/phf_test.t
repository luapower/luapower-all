
setfenv(1, require'terra.low')
require'terra.phf'

local function read_words(file)
	local t = {}
	local i = 0
	for s in io.lines(file) do
		i = i + 1
		t[s:gsub('[\n\r]', '')] = i
	end
	return t
end

local function gen_numbers(n, cov)
	local t = {}
	for i = 1, n do
		t[cov and math.random(n / cov) or i] = i
	end
	return t
end

local function test(t, ktype, vtype, invalid_value, complete_set, cov)

	local t0 = clock()
	local lookup, tries, maxtries =
		phf(t, ktype, vtype, invalid_value, complete_set)
	local t1 = clock()

	for k,i in pairs(t) do
		if ktype == 'string' then
			assert(lookup(k, #k) == i)
		else
			assert(lookup(k) == i)
		end
	end

	local n = count(t)
	print(string.format(
		'%8s->%-8s items: %6d fill: %s Mkeys/s: %5.3f. second tries: %3d%%. max tries: %2d'
		,tostring(ktype)
		,tostring(vtype)
		,n
		,(cov and string.format('%3d%%', cov * 100) or 'n/a%')
		,n / (t1 - t0) / 1000000
		,(tries / n) * 100, maxtries
	))

	return lookup
end

print'Generation speed:'
local map = test(read_words'media/phf/words', 'string', int32, nil, true)
--TODO: make phf_nofp work with strings.
--assert(map.lookup('invalid word', #'invalid word') == nil)
local lookup = test(gen_numbers(10, 1), int32, int32, -1, nil, 1)
assert(lookup(20) == -1)
local lookup = test(gen_numbers(100000, 1), int32, int32, nil, nil, 1)
assert(lookup(500000) == 0)
local lookup = test(gen_numbers(100000, .5), uint32, int32, nil, nil, 1)
assert(lookup(500000) == 0)
local lookup = test(gen_numbers(100000, 1), int32, int32, -1, false, .5)
assert(lookup(500000) == -1)

print()
print'Lookup speed:'
local terra test_speed()
	var t0 = clock()
	var n = 100000
	var m = 10
	var c = 0
	for j=1,m do
		c = 0
		for i=1,n do
			var v = lookup(i)
			if v >= 0 then
				c = c + 1
			end
		end
	end
	pfn('%-8s hit rate: %3.0f%%, Mlookups/sec: %8.3f',
		[tostring(int32)], (1.0 * c / n) * 100, (n * m / 1000000.0) / (clock() - t0) )
end
test_speed()
