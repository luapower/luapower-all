
local mustache = require'mustache'
local glue = require'glue'
local cjson = require'cjson'
local lfs = require'lfs'
local pp = require'pp'

local function test_spec(t)
	print(t.name)
	print(t.desc)
	local s = mustache.render(t.template, t.data)
	local success = s == t.expected
	if not success then
		print()
		print('TEMPLATE:')
		print(t.template)
		print()
		print('DATA:')
		print()
		pp(t.data)
		print()
		print('EXPECTED:')
		print()
		print(t.expected)
		print()
		print('RENDERED:')
		print()
		print(s)
		print()
	end
	return success
end

local failed = 0
local total = 0
local dir = 'media/mustache'
for file in lfs.dir(dir) do
	if file:find'%.json$' then
		local doc = cjson.decode(glue.readfile(dir..'/'..file))
		print('SPEC FILE: '..file)
		print(('-'):rep(78))
		for i, test in ipairs(doc.tests) do
			if not test_spec(test) then
				failed = failed + 1
				--os.exit(1)
			end
			total = total + 1
		end
	end
end
print('FAILED: '..failed..'/'..total)

