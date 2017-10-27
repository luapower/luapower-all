
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
		print('DUMP:')
		mustache.dump(t.template)
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

local function test_specs()
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
				end
				total = total + 1
			end
			print()
		end
	end
	print('SPEC TESTS FAILED: '..failed..' / '..total)
	print()
end

local function test_dump()
	print'TESTING DUMP:'
	print()
	mustache.dump(
		'  {{>nope}}\n  {{hei}} there {{#cowboy}}inside{{/cowboy}}'..
		'{{=<% %>=}}  <%^cow%>outside<%/cow%>')
	print()
end

local function test_marginal_cases()
	assert(mustache.render('') == '')
	assert(mustache.render('{{x}}', {x=false}) == 'false')
end

local function test_errors()
	print'TESTING ERROR CASES:'
	print()
	local function testerr(f, ...)
		local ok, err = pcall(f, ...)
		assert(not ok)
		print(err)
	end
	testerr(mustache.render, 'first line\nhello {{  }}!')
	testerr(mustache.render, 'first line\n  {{= <% =}}')
	testerr(mustache.render, '{{#s1}}{{^s2}}')
	testerr(mustache.render, '{{#s1}}{{#s2}}{{/s1}}{{/s2}}')
	testerr(mustache.render, '{{#a.b}}{{/a.b}}', {a = 'hey'})
	testerr(mustache.render, '{{/a}}')
	print()
end

test_specs()
test_dump()
test_marginal_cases()
test_errors()
