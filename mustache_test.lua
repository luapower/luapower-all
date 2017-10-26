
local mustache = require'mustache'
local glue = require'glue'
local cjson = require'cjson'
local lfs = require'lfs'
local pp = require'pp'

local function test_spec(t)
	print(t.desc)
	local ok, s = pcall(mustache.render, t.template, t.data, t.partials)
	local success = ok and s == t.expected
	if not success then
		print()
		print('TEMPLATE:')
		print(pp.format(t.template))
		print()
		print('DATA:')
		print()
		pp(t.data)
		print()
		if t.partials then
			print('PARTIALS:')
			print()
			pp(t.partials)
			print()
		end
		print('EXPECTED:')
		print()
		print(pp.format(t.expected))
		print()
		print('RENDERED:')
		print()
		print(pp.format(s))
		print()
	end
	return success
end

local failed = 0
local total = 0
local dir = 'media/mustache'
for file in lfs.dir(dir) do
	local path = dir..'/'..file
	local doc
	if file:find'%.json$' then
		doc = cjson.decode(glue.readfile(path))
	elseif file:find'%.lua$' then
		doc = loadfile(path)()
	end
	if doc then
		print('SPEC FILE: '..file)
		print(('-'):rep(78))
		for i, test in ipairs(doc.tests) do
			if not test_spec(test) then
				failed = failed + 1
				--os.exit(1)
			end
			total = total + 1
		end
		print()
	end
end
print('FAILED: '..failed..'/'..total)

