local path = require'path'

assert(path.platform == 'win' or path.platform == 'unix')
assert(path.default_sep'win' == '\\')
assert(path.default_sep'unix' == '/')
assert(path.default_sep() == path.default_sep(path.platform))

assert(path.dev_alias'NUL' == 'NUL')
assert(path.dev_alias'c:/a/b/con.txt' == 'CON')

--type -----------------------------------------------------------------------

assert(path.type('c:\\', 'win') == 'abs')
assert(path.type('c:/a/b', 'win') == 'abs')
assert(path.type('/', 'unix') == 'abs')
assert(path.type('/a/b', 'unix') == 'abs')
assert(path.type('\\\\?\\C:\\', 'win') == 'abs_long')
assert(path.type('/a/b', 'win') == 'abs_nodrive')
assert(path.type('', 'win') == 'rel')
assert(path.type('a', 'win') == 'rel')
assert(path.type('a/b', 'win') == 'rel')
assert(path.type('C:', 'win') == 'rel_drive')
assert(path.type('C:a', 'win') == 'rel_drive')
assert(path.type('\\\\', 'win') == 'unc')
assert(path.type('\\\\server\\share', 'win') == 'unc')
assert(path.type('\\\\?\\UNC\\', 'win') == 'unc_long')
assert(path.type('\\\\?\\UNC\\server', 'win') == 'unc_long')
assert(path.type('\\\\?\\UNC\\server\\share', 'win') == 'unc_long')
assert(path.type('\\\\?\\', 'win') == 'global')
assert(path.type('\\\\?\\a', 'win') == 'global')
assert(path.type('\\\\.\\', 'win') == 'dev')
assert(path.type('\\\\.\\a', 'win') == 'dev')
assert(path.type('c:/nul', 'win') == 'dev_alias')

--isabs ----------------------------------------------------------------------

local function test(s, pl, isabs2, isempty2, isvalid2)
	local isabs1, isempty1, isvalid1 = path.isabs(s, pl)
	print('isabs', s, pl, '->', isabs1, isempty1, isvalid1)
	assert(isabs1 == isabs2)
	assert(isempty1 == isempty2)
	assert(isvalid1 == isvalid2)
end

test('',     'win', false, true, true)
test('/',    'win', true,  true, true)
test('\\//', 'win', true,  true, true)
test('C:',   'win', false, true, true)
test('C:/',  'win', true,  true, true)
test('C:/a', 'win', true,  false, true)
test('a',    'win', false, false, true)

--device alias but appears abs
test('C:/path/con.txt', 'win', false, false, true)

test('\\\\', 'win', true, true, false) --invalid
test('\\\\server', 'win', true, true, false) --invalid
test('\\\\server\\', 'win', true, true, true) --still invalid but better :)
test('\\\\server\\share', 'win', true, false, true) --valid

test('/', 'unix', true, true, true)
test('', 'unix', false, true, true)

--endsep ---------------------------------------------------------------------

local function test(s, s2, success2, pl, sep, default_sep)
	local s1, success1 = path.endsep(s, pl, sep, default_sep)
	print('endsep', s, pl, sep, '->', s1, success1)
	assert(s1 == s2)
	assert(success1 == success2)
end

--empty rel has no end sep
test('',   nil, nil, 'win', nil)
test('C:', nil, nil, 'win', nil)

--abs root has end sep
test('/',    '/', nil, 'win', nil)
test('/',    '/', nil, 'unix', nil)
test('C:\\', '\\', nil, 'win', nil)

--add
test('a',   'a/',   true, 'win',  '/') --add specific
test('a',   'a\\',  true, 'unix', '\\') --add specific (invalid but allowed)
test('a',   'a\\',  true, 'win',  true) --add default
test('a/b', 'a/b/', true, 'win',  true) --add detected

--remove
test('a/', 'a',  true, 'win', '') --remove
test('a/', 'a',  true, 'win', false) --remove

--already there, not adding
test('a/', 'a/', true, 'win', '\\')

--refuse to remove from the empty abs path
test('/',   '/',   false, 'win', '')
test('C:/', 'C:/', false, 'win', '')

--refuse to add to the empty rel path
test('',   '',   false, 'win', '/')
test('C:', 'C:', false, 'win', '/')

--separator ------------------------------------------------------------------

local function test(s, s2, pl, sep, default_sep, empty_names)
	local s1 = path.sep(s, pl, sep, default_sep, empty_names)
	print('sep', s, pl, sep, default_sep, empty_names, '->', s1)
	assert(s1 == s2)
end

test('', nil, 'win')
test('a', nil, 'win')
test('/', '/', 'win')
test('\\', '\\', 'win')
test('C:', nil, 'win')
test('\\\\server', nil, 'win') --invalid UNC
test('a/b\\c', nil, 'win')
test('a/b\\c', '/', 'unix')

test('', '', 'win', true)
test('a/b', 'a\\b', 'win', true) --default
test('a\\b', 'a/b', 'win', true, '/') --specific default
test('a/b/c', 'a/b/c', 'win', false) --default if mixed
test('a/b\\c', 'a\\b\\c', 'win', false) --default if mixed
test('a/b\\c', 'a/b/c', 'win', false, '/') --specific default if mixed
test('a/b\\c', 'a/b/c', 'win', '/') --specific
test('a/b/c', 'a\\b\\c', 'win', '\\') --specific (invalid but allowed)

test('a//b\\\\\\c', 'a/b\\c', 'win', nil, nil, false) --collapse only
--don't collapse, default if mixed, default
test('a//b\\\\\\c', 'a\\\\b\\\\\\c', 'win', true, nil, true)
--don't collapse, default if mixed, specific
test('a//b\\\\\\c', 'a//b///c', 'win', '/', nil, true)
--don't collapse, default if mixed
test('a//b\\\\\\c', 'a\\\\b\\\\\\c', 'win', false, nil, true)
--don't collapse, default if mixed, specific default
test('a//b\\\\\\c', 'a//b///c', 'win', false, '/', true)

--file -----------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.file(s, pl)
	print('file', s, pl, '->', s1)
	assert(s1 == s2)
end
test(''    , 'win', '')
test('/'   , 'win', '')
test('a'   , 'win', 'a')
test('a/'  , 'win', '')
test('/a'  , 'win', 'a')
test('a/b' , 'win', 'b')
test('a/b/', 'win', '')

test('a\\b\\', 'unix', 'a\\b\\')
test('a/b', 'unix', 'b')
test('a/b/', 'unix', '')

--nameext --------------------------------------------------------------------

local function test(s, pl, name2, ext2)
	local name1, ext1 = path.nameext(s, pl)
	print('nameext', s, pl, '->', name1, ext1)
	assert(name1 == name2)
	assert(ext1 == ext2)
end

test('',             'win', '', nil)
test('/',            'win', '', nil)
test('a/',           'win', '', nil)
test('/a/b/a',       'win', 'a', nil)
test('/a/b/a.',      'win', 'a', '') --invalid filename on Windows
test('/a/b/a.txt',   'win', 'a', 'txt')
test('/a/b/.bashrc', 'win', '.bashrc', nil)

--dir ------------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.dir(s, pl)
	print('dir', s, pl, '->', s1)
	assert(s1 == s2)
end

--empty rel path has no dir
test('', 'win', nil)
test('C:', 'win', nil)

--current dir has no dir
test('.', 'win', nil)

--root has no dir
test('C:/', 'win', nil)
test('/', 'win', nil)
test('\\', 'win', nil)

--dir is root
test('/b', 'unix', '/')
test('/aa', 'win', '/')
test('C:/a', 'win', 'C:/')

--dir is the current dir
test('a', 'win', '.')
test('aa', 'win', '.')
test('\\aa', 'unix', '.')
test('C:a', 'win', 'C:')

--dir of empty filename
test('a/', 'win', 'a')
test('./', 'win', '.')

--dir of non-empty filename
test('a/b', 'win', 'a')
test('aa/bb', 'win', 'aa')
test('C:/aa/bb', 'win', 'C:/aa')
test('C:a', 'win', 'C:')
test('a/b', 'unix', 'a')

--gsplit ---------------------------------------------------------------------

function test(s, pl, full, t2)
	local t1 = {}
	for s, sep in path.gsplit(s, pl, full) do
		table.insert(t1, s)
		table.insert(t1, sep)
	end
	local _ = require'pp'.format
	print('gsplit', s, pl, full, '->', _(t1))
	assert(_(t1) == _(t2))
end

test('', 'win', nil, {})
test('/', 'win', nil, {'', '/'})
test('/a', 'win', nil, {'', '/', 'a', ''})
test('/a/', 'win', nil, {'', '/', 'a', '/'})
test('\\/a\\/', 'win', nil, {'', '\\/', 'a', '\\/'})
test('C:', 'win', nil, {})
test('C:\\a/b', 'win', nil, {'', '\\', 'a', '/', 'b', ''})
test('a/b\\c', 'unix', nil, {'a', '/', 'b\\c', ''})

--normalize ------------------------------------------------------------------

local function test(s, pl, opt, s2)
	local s1 = path.normalize(s, pl, opt)
	print('normal', s, pl, 'opt', '->', s1)
	assert(s1 == s2)
end

--remove `.`
local opt = {dot_dot_dirs = true, endsep = 'leave', sep = 'leave'}
test('.', 'win', opt, '.')
test('./', 'win', opt, './')
test('C:.', 'win', opt, 'C:')
test('C:./', 'win', opt, 'C:')
test('.\\', 'win', opt, '.\\')
test('./.', 'win', opt, '.')
test('./.\\', 'win', opt, '.\\')
test('/.', 'win', opt, '/')
test('\\./', 'win', opt, '\\') --root slash kept
test('/.\\.', 'win', opt, '/') --root slash kept
test('/a/.', 'win', opt, '/a')
test('/./a', 'win', opt, '/a')
test('./a', 'win', opt, 'a')
test('a/.', 'win', opt, 'a')
test('a\\.', 'win', opt, 'a')
test('a\\./', 'win', opt, 'a\\')
test('a/b\\c', 'win', opt, 'a/b\\c')
test('a\\././b///', 'win', opt, 'a\\b///')
test('a/.\\.\\b\\\\', 'win', opt, 'a/b\\\\')

--remove `..`
local opt = {dot_dirs = true, endsep = 'leave', sep = 'leave'}
test('a/b/..', 'win', opt, 'a') --remove endsep from leftover
test('a/b/c/..', 'win', opt, 'a/b') --remove endsep from leftover
test('a/..', 'win', opt, '.') --no leftover to remove endsep from
test('\\a/..', 'win', opt, '\\') --can't remove endsep from empty abs path
test('\\a/../', 'win', opt, '\\') --keep endsep
test('\\../', 'win', opt, '\\') --remove from root, keep endsep
test('a\\b/../', 'win', opt, 'a\\') --keep endsep
test('a/../', 'win', opt, './') --no leftover to see endsep
test('C:/a/b/..', 'win', opt, 'C:/a')
test('C:/a/b/c/../..', 'win', opt, 'C:/a')
--remove till empty
test('a/..', 'win', opt, '.')
test('a/b/../..', 'win', opt, '.')
test('C:/a/..', 'win', opt, 'C:/') --keep endsep
test('C:/a/b/../..', 'win', opt, 'C:/') --keep endsep
--one `..` too many from rel paths
test('..', 'win', opt, '..')
test('../', 'win', opt, '../')
test('../..', 'win', opt, '../..')
test('../..\\', 'win', opt, '../..\\')
test('a/..\\', 'win', opt, '.\\')
test('a/b/../../..', 'win', opt, '..')
--one `..` too many from abs paths
test('/..', 'win', opt, '/')
test('/..\\', 'win', opt, '/')
test('/../..', 'win', opt, '/')
test('/../..\\', 'win', opt, '/')
test('C:/a/b/../../..', 'win', opt, 'C:/')
--skip `.` dirs when removing
test('a/b/./././..', 'win', opt, 'a/././.')
test('a/./././..', 'win', opt, '././.')
test('./././..', 'win', opt, './././..')
test('/./././..', 'win', opt, '/./././..')

--default options: remove `.` and `..` and end-slash, set-sep-if-mixed.
test('C:///a/././b/x/../c\\d', 'win', nil, 'C:\\a\\b\\c\\d')
--default options: even when not mixed, separators are collapsed.
test('C:///a/././b/x/../c/d', 'win', nil, 'C:/a/b/c/d')
--default options: remove endsep
test('.\\', 'win', nil, '.')
test('.\\././.\\', 'win', nil, '.')
test('C:./', 'win', nil, 'C:')

--long paths
local long = {long = 'auto', sep = 'leave', endsep = 'leave'}
test('C:'..('/a/b'):rep(65), 'win', long, '\\\\?\\C:'..('\\a\\b'):rep(65))

--commonpath -----------------------------------------------------------------

local function test(a, b, pl, c2)
	local c1 = path.commonpath(a, b, pl)
	print('commonp', a, b, pl, '->', c1)
	assert(c1 == c2)
end

--same path
test('',         '',           'win', '')
test('/',        '/',          'win', '/')
test('C:',       'C:',         'win', 'C:')
test('C:a',      'C:a',        'win', 'C:a')

--diff type and/or drive
test('C:/',      'C:',         'win', nil) --diff. type (common lexic prefix)
test('C:a',      'C:/',        'win', nil) --diff. type
test('C:/CON',   'C:/',        'win', nil) --diff. type
test('C:',       'X:',         'win', nil) --diff. drive
test('\\\\a\\',  '\\\\b\\',    'win', nil) --diff. server

--same path diff. syntax, choose the first path
test('c:/',      'C:/',        'win', 'c:/')
test('C:/',      'C:\\',       'win', 'C:/')
test('C:\\a/b',  'C:/a\\b',    'win', 'C:\\a/b')

--same path diff. syntax, choose the smallest path
test('C:////////', 'c://',       'win', 'c://')
test('c://',       'C:////////', 'win', 'c://')

test('C:/a',     'C:/b',       'win', 'C:/')
test('C:a',      'C:b',        'win', 'C:')
test('C:/a/b',   'C:/a/c',     'win', 'C:/a/')
test('C:/a/b',   'C:/a/b/',    'win', 'C:/a/b') --endsep not common
test('C:/a/b/',  'C:/a/b/c',   'win', 'C:/a/b/') --endsep common and end
test('C:/a/c/d', 'C:/a/b/f',   'win', 'C:/a/') --endsep common
test('C:/a/b',   'C:/a/bc',    'win', 'C:/a/') --last sep, not last char
test('C:/a//',   'C:/a//',     'win', 'C:/a//') --multiple endsep common

--case-sensitivity
test('a/B',     'a/b',       'unix', 'a/')
test('C:a/B',   'C:a/b',     'win',  'C:a/B') --pick first
test('C:a/B/c', 'C:a/b/c/d', 'win',  'C:a/B/c') --pick smallest

--depth ----------------------------------------------------------------------

assert(path.depth(''), 'win' == 0)
assert(path.depth('/'), 'win' == 0)
assert(path.depth('/\\///'), 'win' == 0)
assert(path.depth('a/'), 'win' == 1)
assert(path.depth('/a'), 'win' == 1)
assert(path.depth('/a/'), 'win' == 1)
assert(path.depth('a/b'), 'win' == 2)
assert(path.depth('/a/b'), 'win' == 2)
assert(path.depth('a/b/'), 'win' == 2)
assert(path.depth('/a/b/'), 'win' == 2)
assert(path.depth('a/b/c'), 'win' == 3)
assert(path.depth('C:/a/b/c'), 'win' == 3)
assert(path.depth('\\\\server\\share\\path'), 'win' == 2)

--combine (& implicitly abs) -------------------------------------------------

local function test(s1, s2, pl, p2, err2)
	local p1, err1 = path.combine(s1, s2, pl)
	print('combine', s1, s2, pl, '->', p1, err1, err1)
	assert(p1 == p2)
	if err2 then
		assert(err1:find(err2, 1, true))
	end
end

-- any + '' -> any
test('C:a/b', '', 'win', 'C:a/b')

-- any + c/d -> any/c/d
test('C:\\', 'c/d', 'win', 'C:\\c/d')

-- C:a/b + /d/e -> C:/d/e/a/b
test('C:a/b', '\\d\\e', 'win', 'C:\\d\\e/a/b')

-- C:/a/b + C:d/e -> C:/a/b/d/e
test('C:/a/b', 'C:d\\e', 'win', 'C:/a/b/d\\e')

-- errors
test('/a', '/b', 'win', nil, 'cannot combine') --types
test('C:', 'D:', 'win', nil, 'cannot combine') --drives


--rel ------------------------------------------------------------------------

local function test(s, pwd, s2, pl, sep, default_sep)
	local s1 = path.rel(s, pwd, pl, sep, default_sep)
	print('rel', s, pwd, pl, '->', s1)
	assert(s1 == s2)
end

test('/a/c',   '/a/b', '../c', 'win')
test('/a/b/c', '/a/b', 'c',    'win')

test('',  '',    '.',      'win')
test('',  'a',   '..',     'win')
test('a',  '',   'a',      'win')
test('a/', '',   'a/',     'win')
test('a',  'b',  '../a',   'win', '/')
test('a/', 'b',  '../a/',  'win')
test('a',  'b/', '../a',   'win')

test('a/b',    'a/c',   '../b',     'win') --1 updir + non-empty
test('a/b/',   'a/c',   '../b/',    'win') --1 updir + non-empty + endsep
test('a/b',    'a/b/c', '..',       'win') --1 updir + empty
test('a/b/',   'a/b/c', '../',      'win') --1 updir + empty + endsep
test('a/b/c',  'a/b',   'c',        'win') --0 updirs + non-empty
test('a/b',    'a/b',   '.',        'win') --0 updirs + empty
test('a/b/',   'a/b',   './',       'win') --0 updirs + empty + endsep
test('C:a/b/', 'C:a/b', 'C:./',     'win') --0 updirs + empty + endsep
test('a/b',    'a/c/d', '../../b',  'win') --2 updirs + non-empty
test('a/b/',   'a/c/d', '../../b/', 'win') --2 updirs + non-empty + endsep

--filename -------------------------------------------------------------------

local function test(s, pl, repl, s2)
	local s1, err, errcode = path.filename(s, pl, repl)
	print('filename', s, pl, repl, '->', s1, err, errcode)
	assert(s1 == s2)
end

test('/a/..', 'unix', nil, nil)
test('/a/..', 'unix', function() end, nil)
test('/a/..', 'unix', function() return false end, nil)
test('/a/..', 'unix', function(s, err) return '' end, '/a/')
--TODO

