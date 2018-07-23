
local dlist = require'dlist'

local list = dlist()

local function test(t) --test length and list traversal in both directions
	assert(list.length == #t)
	local i = 0
	for item in list:items() do
		i = i + 1
		assert(item[1] == t[i])
	end
	assert(i == #t)
	local i = #t + 1
	for item in list:reverse_items() do
		i = i - 1
		assert(item[1] == t[i])
	end
	assert(i == 1)
end

list:insert_last({'a'}); test{'a'}
list:insert_last({'b'}); test{'a','b'}
list:insert_first({'0'}); test{'0','a','b'}
list:insert_after(list:next(), {'1'}); test{'0','1','a','b'}
assert(list:remove_last()[1] == 'b'); test{'0','1','a'}
assert(list:remove_first()[1] == '0'); test{'1','a'}
assert(list:remove(list:next())[1] == '1'); test{'a'}
assert(list:remove(list:prev())[1] == 'a'); test{}

list:clear(); test{}
assert(list:remove_last() == nil)

list:clear(); list:insert_first({'a'}); test{'a'}
list:clear(); list:insert_first({'a'}); test{'a'}

