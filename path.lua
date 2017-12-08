
--path manipulation for Windows and UNIX paths
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'path_test'; return end

local path = {}
setmetatable(path, path)

path.platform = package.config:sub(1, 1) == '\\' and 'win' or 'unix'

local function win(pl) --check if pl (or current platform) is Windows
	if pl == nil then pl = path.platform end
	assert(pl == 'unix' or pl == 'win', 'invalid platform')
	return pl == 'win'
end

function path.sep(pl)
	return win(pl) and '\\' or '/'
end

--device aliases are file names that are found _in any directory_.
local dev_aliases = {
	CON=1, PRN=1, AUX=1, NUL=1,
	COM1=1, COM2=1, COM3=1, COM4=1, COM5=1, COM6=1, COM7=1, COM8=1, COM9=1,
	LPT1=1, LPT2=1, LPT3=1, LPT4=1, LPT5=1, LPT6=1, LPT7=1, LPT8=1, LPT9=1,
}

--check if a path refers to a device alias and return that alias.
function path.dev_alias(s)
	s = s:match'[^\\/]+$' --basename (dev aliases are present in all dirs)
	s = s and s:match'^[^%.]+' --strip extension (they can have any extension)
	s = s and s:upper() --they're case-insensitive
	return s and dev_aliases[s] and s
end

--get the path type which can be: 'abs', 'abs_long', 'abs_nodrive',
--  'rel', 'rel_drive', 'unc', 'unc_long', 'global', 'dev', 'dev_alias'.
--NOTE: the empty path ('') comes off as type 'rel'.
function path.type(s, pl)
	if win(pl) then
		if s:find'^\\\\' then
			if s:find'^\\\\%?\\' then
				if s:find'^\\\\%?\\%a:\\' then
					return 'abs_long'
				elseif s:find'^\\\\%?\\[uU][nN][cC]\\' then
					return 'unc_long'
				else
					return 'global'
				end
			elseif s:find'^\\\\%.\\' then
				return 'dev'
			else
				return 'unc'
			end
		elseif path.dev_alias(s) then
			return 'dev_alias'
		elseif s:find'^%a:' then
			return s:find'^..[\\/]' and 'abs' or 'rel_drive'
		else
			return s:find'^[\\/]' and 'abs_nodrive' or 'rel'
		end
	else
		return s:byte(1) == ('/'):byte(1) and 'abs' or 'rel'
	end
end

--split a path into its local path component and, depending on the path
--type, the drive letter or server name.
--NOTE: UNC paths are not validated and can have and empty server or path.
function path.parse(s, pl)
	local type = path.type(s, pl)
	if win(pl) then
		if type == 'rel' or type == 'abs_nodrive' then
			return type, s -- nothing to split
		elseif type == 'abs' or type == 'rel_drive' then
			return type, s:sub(3), s:sub(1,1) -- \path, drive
		elseif type == 'abs_long' then
			return type, s:sub(3+4), s:sub(1+4,1 +4) -- \path, drive
		elseif type == 'unc' then
			local server, path = s:match'^..([^\\]*)(.*)$'
			return type, path, server
		elseif type == 'unc_long' then
			local server, path = s:match'^........([^\\]*)(.*)$'
			return type, path, server
		elseif type == 'dev' then
			return type, s:sub(4) -- \path
		elseif type == 'dev_alias' then
			return type, path.dev_alias(s) -- CON, NUL, ...
		elseif type == 'global' then
			return type, s:sub(4) -- \path
		end
	else
		return type, s --unix path: nothing to split
	end
end

--put together a path from its broken-down components.
function path.format(type, path, drive, pl)
	if win(pl) and type == 'abs' or type == 'rel_drive' then
		return drive .. ':' .. path
	elseif type == 'abs_long' then
		return '\\\\?\\' .. drive .. ':' .. path
	elseif type == 'unc' then
		local path = '\\\\' .. drive .. path
	elseif type == 'unc_long' then
		return '\\\\?\\UNC\\' .. drive .. path
	elseif type == 'dev_alias' then
		return path
	elseif type == 'dev' then
		return '\\\\.' .. path
	elseif type == 'global' then
		return '\\\\?' .. path
	else --abs/unix, rel, abs_nodrive
		return path
	end
end

--check if a path is an absolute path or not, and if it's empty or not.
--NOTE: absolute paths for which their local path is '' are actually invalid
--(currently only UNC paths can be invalid and still parse); for those paths
--the second return value will be nil.
local function isabs(type, p, win)
	if type == 'rel' or type == 'rel_drive' or type == 'dev_alias' then
		return false, p == ''
	elseif p == '' then
		return true, nil --invalid absolute path
	else
		return true, p:find(win and '^[\\/]+$' or '^/+$') and true or false
	end
end
function path.isabs(s, pl)
	local type, p = path.parse(s, pl)
	return isabs(type, p, win(pl))
end

--determine a path's separator if possible.
local function detect_sep(p, win)
	if win then
		local fws = p:find'[^/]*/'
		local bks = p:find'[^\\/]*\\'
		if not fws == not bks then
			return nil --can't determine
		end
		return fws and '/' or '\\'
	else
		return '/'
	end
end

--get/add/remove ending separator.
local function set_endsep(type, p, win, sep)
	local _, isempty = isabs(type, p, win)
	if isempty then --refuse to change the ending slash on empty paths
		return
	elseif sep == false or sep == '' then --remove it
		return p:gsub(win and '[\\/]+$' or '/+$', '')
	elseif p:find(win and '[\\/]$' or '/$') then --add it/already set
		return p
	else
		if sep == true then
			sep = detect_sep(p, win) or (win and '\\' or '/')
		end
		assert(sep == '\\' or sep == '/', 'invalid separator')
		return p .. sep
	end
end
function path.endsep(s, pl, sep)
	local win = win(pl)
	local type, p, drive = path.parse(s, pl)
	if sep == nil then
		return p:match(win and '[\\/]+$' or '/+$')
	else
		local p = set_endsep(type, p, win, sep)
		return p and path.format(type, p, drive, pl) or s, p and true or false
	end
end

--detect or set the a path's separator (for Windows paths only).
--NOTE: setting '\' on a UNIX path may result in an invalid path because
--`\` is a valid character in UNIX filenames!
local function set_separator(p, win, sep, default_sep, empty_names)
	local dsep = default_sep or (win and '\\' or '/')
	if sep == true then --set to default
		sep = dsep
	elseif sep == false then --set to default only if mixed
		sep = detect_sep(p, win) or dsep
	elseif sep == nil then --collapse only
		sep = '%1'
	else
		assert(sep == '\\' or sep == '/', 'invalid separator')
	end
	if empty_names then
		return p:gsub(win and '[\\/]' or '/', sep)
	else
		return p:gsub(win and '([\\/])[\\/]*' or '(/)/*', sep)
	end
end
function path.separator(s, pl, sep, default_sep, empty_names)
	local win = win(pl)
	local type, p, drive = path.parse(s, pl)
	if sep == nil and empty_names == nil then
		return detect_sep(p, win)
	else
		p = set_separator(p, win, sep, default_sep, empty_names)
		return path.format(type, p, drive, pl)
	end
end

--get the last path component of a path.
--if the path ends in a separator then the empty string is returned.
function path.basename(s, pl)
	local _, p = path.parse(s, pl)
	return p:match(win(pl) and '[^\\/]*$' or '[^/]*$')
end

--get the filename without extension and the extension from a path.
function path.splitext(s, pl)
	local patt = win(pl) and '^(.-)%.([^%.\\/]*)$' or '^(.-)%.([^%./]*)$'
	local filename = path.basename(s, pl)
	local name, ext = filename:match(patt)
	if not name or name == '' then -- 'dir' or '.bashrc'
		name, ext = filename, nil
	end
	return name, ext
end

function path.ext(s, pl)
	local _, ext = path.splitext(s, pl)
	return ext
end

--get a path without basename and separator. if the path ends with
--a separator then the whole path without the separator is returned.
function path.dirname(s, pl)
	local type, p, drive = path.parse(s, pl)
	local i1, i2 = p:match(win(pl)
		and '()[\\/]*()[^\\/]*$' or '()/*()[^/]*$')
	local i = i1 == 1 and i2 or i1 --if it starts with a slash, include it
	return path.format(type, p:sub(1, i-1), drive, pl)
end

--iterate over a path's components and separators.
function path.gsplit(s, pl, full)
	local win = win(pl)
	local p = full and s or select(2, path.parse(s, pl))
	local root_sep = p:match(win and '^[\\/]+' or '^/+')
	local next_pc = p:gmatch(win and '([^\\/]+)([\\/]*)' or '([^/]+)(/*)')
	local started = not root_sep
	return function()
		if not started then
			started = true
			return '', root_sep
		elseif started then
			return next_pc()
		end
	end
end

local function iif(a, b, c)
	if a == b then
		return c
	else
		return a
	end
end

-- remove `.` dirs (opt.dot_dirs)
-- remove unnecessary `..` dirs (opt.dot_dot_dirs)
-- normalize separator (opt.separator, opt.default_separator, opt.empty_names)
-- add/remove ending separator (opt.endsep)
-- convert between long and short Windows path encodings (opt.long)
function path.normalize(s, pl, opt)
	opt = opt or {}
	local win = win(pl)
	local type, p, drive = path.parse(s, pl)

	local t = {} --{dir1, sep1, ...}
	local lastsep --last separator that was not added to the list
	for s, sep in path.gsplit(p, pl, true) do
		if s == '.' and not opt.dot_dirs then
			--skip adding the `.` dir and the separator following it
			lastsep = sep
		elseif s == '..' and not opt.dot_dot_dirs and #t > 0 then
			--find the last dir past any `.` dirs, in case opt.dot_dirs = true.
			local i = #t-1
			while t[i] == '.' do
				i = i - 2
			end
			--remove the last dir (and the separator following it)
			--that's not `..` and it's not the root element.
			if i > 0 and ((i > 1 or t[i] ~= '') and t[i] ~= '..') then
				table.remove(t, i)
				table.remove(t, i)
				lastsep = sep
			elseif #t == 2 and t[1] == '' then
				--skip `..` after the root slash
				lastsep = sep
			else
				table.insert(t, s)
				table.insert(t, sep)
			end
		else
			table.insert(t, s)
			table.insert(t, sep)
			lastsep = nil
		end
	end
	if #t == 0 then --the empty rel path ('') is not a valid path. fix that.
		table.insert(t, '.')
		table.insert(t, lastsep)
	elseif lastsep == '' and (#t > 2 or t[1] ~= '') then
		--if there was no end separator originally before removing path
		--components, remove the left over separator now.
		table.remove(t)
	end
	p = table.concat(t)

	if opt.separator ~= 'leave' then
		p = set_separator(p, win,
			iif(iif(opt.separator, nil, false), 1, nil),
			opt.default_separator,
			opt.empty_names)
	end

	if opt.endsep ~= 'leave' then
		p = set_endsep(type, p, win, iif(opt.endsep, nil, false)) or p
	end

	s = path.format(type, p, drive, pl)

	if win and opt.long ~= 'leave' then
		local long = iif(opt.long, nil, 'auto')
		if type == 'abs'
			and ((long == 'auto' and #s > 259) or long == true)
		then
			p = p:gsub('/+', '\\') --TODO: this might create a smaller path
			s = path.format('abs_long', p, drive, pl)
		elseif type == 'abs_long'
			and ((long == 'auto' and #s <= 259 + 4) or long == false)
		then
			s = path.format('abs', p, drive, pl)
		end
	end

	return s
end

--get the common base path (including the end separator) between two paths.
--BUG: the case-insensitive comparison doesn't work with utf8 paths!
function path.commonpath(s1, s2, pl)
	local win = win(pl)
	local t1, p1, d1 = path.parse(s1, pl)
	local t2, p2, d2 = path.parse(s2, pl)
	local t, p, d
	if #p1 <= #p2 then --pick the smaller/first path when formatting
		t, p, d = t1, p1, d1
	else
		t, p, d = t2, p2, d2
	end
	if win then --make the search case-insensitive and normalize separators
		d1 = d1 and d1:lower()
		d2 = d2 and d2:lower()
		p1 = p1:lower():gsub('/', '\\')
		p2 = p2:lower():gsub('/', '\\')
	end
	if t1 ~= t2 or d1 ~= d2 or p1 == '' or p2 == '' then
		return path.format(t, '', d, pl)
	end
	local sep = (win and '\\' or '/'):byte(1)
	local si = 0 --index where the last common separator was found
	for i = 1, #p + 1 do
		local c1 = p1:byte(i)
		local c2 = p2:byte(i)
		local sep1 = c1 == nil or c1 == sep
		local sep2 = c2 == nil or c2 == sep
		if sep1 and sep2 then
			si = i
		elseif c1 ~= c2 then
			break
		end
	end
	p = p:sub(1, si)
	return path.format(t, p, d, pl)
end

local function depth(p, win)
	local n = 0
	for _ in p:gmatch(win and '()[^\\/]+' or '()[^/]+') do
		n = n + 1
	end
	return n
end
function path.depth(s, pl)
	local _, p = path.parse(s, pl)
	return depth(p, win(pl))
end

--transform an absolute path into a relative path which is relative to `pwd`.
function path.rel(s, pwd, pl)
	local type, p, drive = path.parse(s, pl)
	local win = win(pl)
	local prefix = path.commonpath(p, pwd, pl)
	--count the dir depth in pwd after the prefix.
	local pwd_suffix = pwd:sub(#prefix + 1)
	local n = depth(pwd_suffix, win)
	--[[
	local n = 0
	for _ in pwd_suffix:gmatch(win and '()[^\\/]+' or '()[^/]+') do
		n = n + 1
	end
	]]
	p = p:sub(#prefix + 1)
	p = ('../'):rep(n) .. p
	return path.format(type, p, drive, pl)
end

--combine two paths if possible.
local function combinable(type1, type2)
	if type2 == 'rel' then             -- any + c/d -> any/c/d
		return type1 ~= 'dev_alias'
	elseif type2 == 'abs_nodrive' then -- C:a/b + /c/d -> C:/c/d/a/b
		return type1 == 'rel_drive'
	elseif type2 == 'rel_drive' then   -- C:/a/b + C:c/d -> C:/a/b/c/d
		return type1 == 'abs' or type1 == 'abs_long'
	end
end
function path.combine(s1, s2, pl)
	local type1 = path.type(s1, pl)
	local type2 = path.type(s2, pl)
	if not combinable(type1, type2) then
		if combinable(type2, type1) then
			type1, type2, s1, s2 = type2, type1, s2, s1
		else
			return nil, ('cannot combine %s and %s paths'):format(type1, type2)
		end
	elseif s2 == '' then --any + '' -> any
		return s1
	elseif type2 == 'rel' then --any + c/d -> any/c/d
		return path.endsep(s1, pl, true) .. s2
	elseif type2 == 'abs_nodrive' then -- C:a/b + /d/e -> C:/d/e/a/b
		local type1, p1, drive1 = path.parse(s1)
		return path.format(type1, path.endsep(s2, pl, true) .. p1, drive1, pl)
	elseif type2 == 'rel_drive' then -- C:/a/b + C:d/e -> C:/a/b/d/e
		local type1, p1, drive1 = path.parse(s1)
		local type2, p2, drive2 = path.parse(s2)
		if drive1 ~= drive2 then
			return nil, 'path drives are different'
		end
		return path.combine(s1, p2, pl)
	end
end

--transform a relative path into an absolute path given a base dir.
function path.abs(s, pwd, pl)
	return path.combine(s, pwd, pl)
end

--validate/make-valid a filename
--NOTE: repl can be a function(match) -> repl_str.
--NOTE: if repl isn't itself escaped then duplicate filenames can result.
function path.filename(s, pl, repl)
	local win = win(pl)
	if s == '' then
		return nil, 'empty filename'
	end
	if s == '.' or s == '..' then
		if repl then
			return (s:gsub(s, repl))
		else
			return nil, 'filename is `' .. s .. '`'
		end
	end
	if win and path.dev_alias(s) then
		if repl then
			return (s:gsub(s, repl))
		else
			return nil, 'filename is a Windows device alias'
		end
	end
	local patt = win and '[%z\1-\31<>:"|%?%*\\/]' or '[%z/]'
	if repl then
		s = s:gsub(patt, repl)
	elseif s:find(patt) then
		return nil, 'invalid characters in filename'
	end
	if #s > 255 then --same maximum for Windows and Linux
		return nil, 'filename too long'
	end
	return s
end

--[=[
--if allow_long and type == 'abs' and #path + 1 > 260 then
--if allow_long and #path + 1 > 260 then

local function not_win(path, drive)
	return
		path:find'[%z\1-\31<>:"|%?%*]'
			and 'invalid characters in Windows path'
		or (drive and not drive:find'^%a$')
			and 'invalid drive letter in Windows path'
end

local function not_unix(path)
	return path:find'%z' and 'invalid characters in UNIX path'
end

local function not_clean(path)
	return
		path:find'[%z\1-\31<>:"|%?%*]' --breaks Windows, Unix, bash
		or path:find' +$'  --deceiving
		or path:find'^ +'  --deceiving (removed silently in Windows)
		or path:find'%.+$' --removed silently in Windows
		or path:find'^%-+' --breaks bash
		or path:find'[%[]' --breaks bash
		and 'path contains evil characters'
end

local function not_global(path)
	return path:find'^\\' and [[invalid Windows \\?\ global path]]
end

local function not_abs_win(path)
	return path:find'^[\\/]' and [[not a Windows absolute path]]
end

local function not_abs_unix(path)
	return path:find'^/' and [[not a UNIX absolute path]]
end

--NOTE: we refuse `/`, `.` and `..` as filenames in \\?\ paths because
--they don't mean what they mean in normal paths which would make normal
--paths non-translatable to long paths.
local function not_abs_long(path)
	return
		path:find'/'
			and [[slash in \\?\ path]]
		or (path:find'\\%.\\' or path:find'\\%.$')
			and [[`.` pathname in Windows \\?\ path]]
		or (path:find'\\%.%.\\' or path:find'\\%.%.$')
			and [[`..` pathname in Windows \\?\ path]]
end

local function not_unc(path, server)
	return
		(server == '' or server:find'\\')
			and 'invalid server name for Windows UNC path'
		or not path:find'^\\[^\\/]+' --\share
			and 'invalid path for Windows UNC path'
end

local function not_length(too_long)
	return too_long and 'path too long'
end

local function validate(pl, type, path, drive)
	if win(pl) then
		if type == 'unc' then
			return not_unc(path, drive)
		elseif type == 'unc_long' then
			return not_unc(path, drive)
		elseif type == 'global' then
			return not_global(path)
		elseif type == 'dev' then
			return not_global(path)
		elseif type == 'abs' then
			return not_abs_win(path)
			local err = not_win(path, drive)
				or (type == 'abs' or type == 'abs_nodrive'
					and not_abs_win(path))
			if not err then
				err = not_length((drive and 2 or 0) + #path + 1 > 260)
				if allow_long_abs and err and type == 'abs' then
					err = not_abs_long(path)
				end
			end
			return err
		end
	else
		return not_unix(t.path)
			or not_length(#t.path > 256)
			or (t.type == 'abs' and not_abs_unix(t.path))
	end
end
function path.validate(s, pl)
	return validate(pl, path.parse(s, pl))
end

function path.isclean( allow_long_abs)
	return wrap_not(t,
		not_valid(t, allow_long_abs)
		or not_clean(t.path)
		or (t.server and not_clean(t.server)))
end

local function not_convertible(t, pl)
	local win = win(pl)
	pl = pl or path.platform
	if pl == t.platform then
		return
	end
	if t.type ~= 'rel' then
		return 'only relative paths are convertible'
	end
	if win then
		if t.path:find'\\' then --UNIX path has filenames with backslashes
			return 'invalid characters in Windows path'
		end
		return not_win(t.path), t.path
	else
		return not_unix(t.path:gsub('\\', '/'))
	end
end

function path_t.isconvertible(t, pl)
	return wrap_not(t, not_convertible(t, pl))
end

--convert path between platforms
function path_t.convert(t, pl)
	pl = pl or path.platform
	local win = win(pl)
	if pl == t.platform then
		return t
	end
	if t.type ~= 'rel' then
		return nil, 'only relative paths are convertible'
	end
	if win then
		if t.path:find'\\' then --UNIX path has filenames with backslashes
			return nil, 'invalid characters in Windows path'
		end
		local err = not_win(t.path)
		if err then return nil, err end
		t.platform = pl
	else
		local path = t.path:gsub('\\', '/')
		local err = not_unix(path)
		if err then return nil, err end
		t.path = path
		t.platform = pl
	end
	return t
end


]=]


return path

