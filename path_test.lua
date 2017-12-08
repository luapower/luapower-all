local path = require'path'

assert(path.platform == 'win' or path.platform == 'unix')
assert(path.sep'win' == '\\')
assert(path.sep'unix' == '/')
assert(path.sep() == path.sep(path.platform))

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

local function test(s, pl, isabs2, isempty2)
	local isabs1, isempty1 = path.isabs(s, pl)
	print('isabs', s, pl, '->', isabs1, isempty1)
	assert(isabs1 == isabs2)
	assert(isempty1 == isempty2)
end

test('',     'win', false, true)
test('/',    'win', true,  true)
test('\\//', 'win', true,  true)
test('C:',   'win', false, true)
test('C:/',  'win', true,  true)
test('C:/a', 'win', true,  false)
test('a',    'win', false, false)
test('C:/path/con.txt', 'win', false, false) --device alias but appears abs

test('\\\\', 'win', true, nil) --invalid
test('\\\\server', 'win', true, nil) --invalid
test('\\\\server\\', 'win', true, true) --still invalid but better :)
test('\\\\server\\share', 'win', true, false) --valid

test('/', 'unix', true, true)
test('', 'unix', false, true)

--endsep ---------------------------------------------------------------------

--TODO: `path.endsep(s, [pl], [sep]) -> s, success`

local function test(s, s2, success2, pl, sep)
	local s1, success1 = path.endsep(s, pl, sep)
	print('endsep', s, pl, sep, '->', s1, success1)
	assert(s1 == s2)
	assert(success1 == success2)
end

test('', nil, nil, 'win', nil)
test('/', '/', nil, 'win', nil)
test('/', '/', nil, 'unix', nil)
test('C:', nil, nil, 'win', nil)
test('C:\\', '\\', nil, 'win', nil)

test('a', 'a/', true, 'win', '/') --add specific
test('a', 'a\\', true, 'unix', '\\') --add specific (invalid but allowed)
test('a', 'a\\', true, 'win', true) --add default
test('a/b', 'a/b/', true, 'win', true) --add detected
test('a/', 'a', true, 'win', '') --remove
test('a/', 'a', true, 'win', false) --remove
test('a/', 'a/', true, 'win', '\\') --already there, not changing
test('C:', 'C:', false, 'win', '/') --refuse to add
test('C:/', 'C:/', false, 'win', '') --refuse to remove

--separator ------------------------------------------------------------------

local function test(s, s2, pl, sep, default_sep, empty_names)
	local s1 = path.separator(s, pl, sep, default_sep, empty_names)
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

--basename -------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.basename(s, pl)
	print('basenam', s, pl, '->', s1)
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

--splitext -------------------------------------------------------------------

local function test(s, pl, name2, ext2)
	local name1, ext1 = path.splitext(s, pl)
	print('ext', s, pl, '->', name1, ext1)
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

--dirname --------------------------------------------------------------------

local function test(s, pl, s2)
	local s1 = path.dirname(s, pl)
	print('dirname', s, pl, '->', s1)
	assert(s1 == s2)
end

test('', 'win', '')
test('a', 'win', '')
test('aa', 'win', '')
test('a/b', 'win', 'a')
test('aa/bb', 'win', 'aa')
test('C:/aa/bb', 'win', 'C:/aa')
test('C:a', 'win', 'C:')
test('C:/', 'win', 'C:/')
test('C:/a', 'win', 'C:/')
test('\\aa', 'unix', '')
test('a/b', 'unix', 'a')
test('/b', 'unix', '/')
test('/', 'win', '/')
test('\\', 'win', '\\')
test('/aa', 'win', '/')

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
local opt = {dot_dot_dirs = true, endsep = 'leave', separator = 'leave'}
test('.', 'win', opt, '.')
test('./', 'win', opt, './')
test('.\\', 'win', opt, '.\\') --original endsep is used
test('./.', 'win', opt, '.')
test('./.\\', 'win', opt, '.\\') --original endsep is used
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
local opt = {dot_dirs = true, endsep = 'leave', separator = 'leave'}
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

--long paths
local long = {long = 'auto', separator = 'leave', endsep = 'leave'}
test('C:'..('/a/b'):rep(65), 'win', long, '\\\\?\\C:'..('\\a\\b'):rep(65))

--commonpath -----------------------------------------------------------------

local function test(a, b, pl, c2)
	local c1 = path.commonpath(a, b, pl)
	print('commonp', a, b, pl, '->', c1)
	assert(c1 == c2)
end

test('',         '',           'win', '')
test('/',        '/',          'win', '/')
test('C:',       'C:',         'win', 'C:')
test('c:/',      'C:/',        'win', 'c:/') --first when equal
test('C:/',      'C:\\',       'win', 'C:/') --first when equal
test('C:////////', 'c://',     'win', 'c://') --smallest
test('c://',     'C:////////', 'win', 'c://') --smallest
test('C:/',      'C:',         'win', 'C:')
test('C:',       'C:/',        'win', 'C:')
test('C:a',      'C:/',        'win', 'C:')
test('C:/a',     'C:/b',       'win', 'C:/')
test('C:a',      'C:b',        'win', 'C:')
test('C:/a/b',   'C:/a/c',     'win', 'C:/a/')
test('C:/a/b',   'C:/a/b/',    'win', 'C:/a/b')
test('C:/a/b/',  'C:/a/b/c',   'win', 'C:/a/b/')
test('C:/a/b',   'C:/a/bc',    'win', 'C:/a/')
test('C:/a//',   'C:/a//',     'win', 'C:/a//')
test('C:/a/c/d', 'C:/a/b/f',   'win', 'C:/a/')

--case-sensitivity
test('a/B',     'a/b',       'unix', 'a/')
test('C:a/B',   'C:a/b',     'win',  'C:a/B') --pick first
test('C:a/B/c', 'C:a/b/c/d', 'win',  'C:a/B/c') --pick smallest

--rel ------------------------------------------------------------------------

local function test(s, pwd, pl, r2)
	local r1 = path.rel(s, pwd, pl)
	print('rel', s, pwd, pl, '->', r1)
	assert(r1 == r2)
end

--TODO

--combine (& implicitly abs) -------------------------------------------------

local function test(s, pwd, pl, r2)
	local r1 = path.abs(s, pwd, pl)
	print('abs', s, pwd, pl, '->', r1)
	assert(r1 == r2)
end

--TODO

--filename -------------------------------------------------------------------

--TODO `path.filename(s, [pl], [repl]) -> s`

