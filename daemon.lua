--[[

	Daemon API.
	Written by Cosmin Apreutesei. Public Domain.

	Logging:

		log()
		note()
		nolog()
		warnif()

	Error handling:

		check()

	Filesystem ops:

		exists()
		rm()
		mv()
		mkdir()
		load()
		save()
		cp()
		exec()
		touch()
		mtime()
		dir()

	Config:

		daemon(app_defaults) -> app

			Input:
				app_name
				app_env
				verbose
			Output:
				data_dir
				tmp_dir

	Autoincrement IDs:

		gen_id(name[, start]) -> n

]]

local fs = require'fs'
local errors = require'errors'
require'$'

--logging --------------------------------------------------------------------

local logtofile = noop --fw. decl.

function log(severity, topic, action, fmt, ...)
	local env1 = app_env:sub(1, 1)
	local date = date('%Y-%m-%d %H:%M:%S', time())
	local msg = fmt and _(tostring(fmt), ...):gsub('\r?\n', '\n                                             ')
	local entry = _('%s %s %-6s %-6s %-8s %s\n', env1, date, severity or '', topic or '', action or '', msg or '')
	if severity ~= '' then
		logtofile(entry)
	end
	if severity ~= '' or verbose then
		io.stderr:write(entry)
		io.stderr:flush()
	end
end

function note(...) return log('note', ...) end
function nolog(...) return log('', ...) end

function warnif(topic, action, cond, ...)
	if not cond then return end
	log('WARN', topic, action, ...)
end

function check(errorclass, action, v, ...)
	assert(type(errorclass) == 'string' or errors.is(errorclass))
	assert(type(action) == 'string')
	if v then return v end
	local e = errors.new(errorclass, ...)
	log('ERROR', e.classname, action, e.message)
	e.logged = true --prevent duplicate logging of the error on a catch-all handler.
	errors.raise(e)
end

--filesystem ops -------------------------------------------------------------

--make a path by combining dir and file.
function indir(dir, file)
	if dir == '.' then dir = nil end
	return dir and file and dir..'/'..file or file or dir
end

function exists(file)
	local is, err = fs.is(file)
	check('fs', 'exists', not err, 'could not check file %s: %s', file, err)
	return is
end

function rm(path)
	note('fs', 'rm', '%s', path)
	local ok, err = os.remove(path)
	check('fs', 'rm', ok, 'could not remove file %s: %s', path, err)
end

function mv(old_path, new_path)
	note('fs', 'mv', '1. %s ->\n2. %s', old_path, new_path)
	local ok, err = fs.move(old_path, new_path)
	check('fs', 'mv', ok, 'could not move file %s -> %s: %s', old_path, new_path, err)
end

function mkdir(path)
	local ok, err = fs.mkdir(path, true)
	if ok and err ~= 'already_exists' then
		note('fs', 'mkdir', '%s', path)
	end
	check('fs', 'mkdir', ok, 'could not create dir %s: %s', path, err)
	return path
end

--NOTE: shamelessly changing built-in load() that we never use.
function load(path) --load a file into a string.
	return check('fs', 'load', glue.readfile(path))
end

function save(s, path) --save a string or a Lua value to a file.
	note('fs', 'save', '%s (%d bytes)', path, #s)
	local ok, err = glue.writefile(path, s, nil, path..'.tmp')
	check('fs', 'save', ok, 'could not save file %s: %s', path, err)
end

function cp(src_file, dst_file)
	note('fs', 'cp', '1. %s ->\n2. %s', src_file, dst_file)
	save(load(src_file), dst_file)
end

function exec(path) --exec/wait program and get its stdout into a string.
	note('fs', 'exec', '%s', path)
	local s, err = glue.readpipe(path)
	return check('fs', 'exec', s, 'could not exec file %s: %s', path, err)
end

function touch(file, mtime, btime, silent) --create file or update its mtime.
	if not silent then
		nolog('fs', 'touch', '%s to %s%s', file,
			date('%d-%m-%Y %H:%M', mtime) or 'now',
			btime and ', btime '..date('%d-%m-%Y %H:%M', btime) or '')
	end
	if not exists(file) then
		save('', file)
		if not (mtime or btime) then
			return
		end
	end
	local ok, err = fs.attr(file, {
		mtime = mtime or time(),
		btime = btime or nil,
	})
	check('fs', 'touch', ok, 'could not set mtime/btime for %s: %s', file, err)
end

function mtime(file)
	return fs.attr(file, 'mtime')
end

function dir(path, patt, min_mtime, create, desc, order_by)
	local t = {}
	local create = create or function(file) return {} end
	for file, d in fs.dir(path) do
		if not file and d == 'not_found' then break end
		check('fs', 'dir', file, 'dir listing failed for %s: %s', path, d)
		if     (not min_mtime or d:attr'mtime' >= min_mtime)
			and (not patt or file:find(patt))
		then
			local f = create(file)
			if f then
				f.file  = indir(path, file)
				f.mtime = d:attr'mtime'
				f.btime = d:attr'btime'
				t[#t+1] = f
			end
		end
	end
	local cmp
	if order_by == 'name' then
		function cmp(a, b) return a.file < b.file end
	else
		function cmp(a, b)
			return a.mtime < b.mtime or (a.mtime == b.mtime and a.file < b.file)
		end
	end
	sort(t, cmp)
	if desc then
		glue.reverse(t)
	end
	nolog('fs', 'dir', '%-20s %5d files%s%s', path,
		#t,
		patt and '\n  match: '..patt or '',
		min_mtime and '\n  mtime >= '..date('%d-%m-%Y %H:%M', min_mtime) or '')
	local i = 0
	return function()
		i = i + 1
		return t[i]
	end
end

--autoincrement ids ----------------------------------------------------------

local function toid(s, field) --validate and id minimally.
	local n = tonumber(s)
	if n and n >= 0 and floor(n) == n then return n end
 	return nil, '%s invalid: %s', field or 'field', s
end

function gen_id(name, start)
	local next_id_file = indir(data_dir, 'next_'..name)
	if not exists(next_id_file) then
		save(tostring(start or 1), next_id_file)
	else
		touch(next_id_file)
	end
	local n = tonumber(load(next_id_file))
	check('fs', 'gen_id', toid(n, next_id_file))
	save(tostring(n + 1), next_id_file)
	note ('fs', 'gen_id', '%s: %d', name, n)
	return n
end

--init -----------------------------------------------------------------------

function daemon()

	assert(app_name, 'app_name required')

	--cd to base_dir so that we can use relative paths for everything.
	local exe_dir = fs.exedir()
	local base_dir = exe_dir..'/../..'
	check('fs', 'cd', fs.cd(base_dir), 'could not change dir to %s', base_dir)

	data_dir = data_dir or app_name
	tmp_dir  = tmp_dir or indir('tmp', app_name)

	mkdir(data_dir)
	mkdir(tmp_dir)

	--open the logfile.
	local logfile = indir(data_dir, app_name..'.log')
	local logf, err = io.open(logfile, 'a+')
	check('fs', 'open', logf, 'could not open log file %s: %s', logfile, err)
	--[[local]] function logtofile(s)
		logf:write(s)
		logf:flush()
	end

	--require an optional config file.
	pcall(require, app_name..'_conf')

	return app
end

--nginx/webb context ---------------------------------------------------------

if ngx then

	local our_check = check
	require'webb'
	check = our_check

end

