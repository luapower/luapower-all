--[[

	Daemon API.
	Written by Cosmin Apreutesei. Public Domain.

	daemon(app_name) -> app

	app_name     app codename (the name of your main Lua module).
	APP_conf.lua optional app config file loaded by the daemon() call.
		deploy    app deployment name.
		env       app environment ('dev').
		log_host  log server host.
		log_port  log server port.
	app_dir      app directory (exe dir for bundled apps, or Lua source dir).
	var_dir      r/w persistent data dir (app_dir).
	tmp_dir      r/w persistent temp dir (app_dir/tmp/app_name).
	cmd          {name->f} place to add command-line handlers.
	wincmd       add Windows-only commands here.
	lincmd       add Linux-only commands here.
	help         {cmd->s} help line for command.

	say(s)
	sayn(s)
	die(s)

]]

require'$fs'
require'$log'

function say(s)
	io.stderr:write(s..'\n')
	io.stderr:flush()
end

function sayn(s)
	io.stderr:write(s)
end

function die(s)
	say('ABORT: '..s)
	os.exit(1)
end

--init -----------------------------------------------------------------------

function daemon(app_name)

	local app = {}
	cmd = {}
	wincmd = {}
	lincmd = {}
	help = {}

	_G.app_name = assert(app_name)

	--consider this module loaded so that other app submodules that
	--require it at runtime don't try to load it again.
	package.loaded[app_name] = app

	--cd to app_dir so that we can use relative paths for everything.
	app_dir = exedir
	if not package.loaded.bundle_loader then
		--standalone luajit exe. files are in luapower dir at ../..
		app_dir = indir(indir(app_dir, '..'), '..')
	end
	_G.var_dir = rawget(_G, 'var_dir') or path.normalize(indir(app_dir, app_name..'-var'))
	_G.tmp_dir = rawget(_G, 'tmp_dir') or path.normalize(indir(indir(app_dir, 'tmp'), app_name))

	--r:run_cmdequire an optional config file.
	local ok, opt = pcall(require, app_name..'_conf')
	app.conf = ok and type(opt) == 'table' and opt or {}

	local wrapped = {help=1, start=1}
	function cmd.help(extra)
		if extra then
			for k,v in sortedpairs(cmd) do
				if not wrapped[k] then
					say(fmt('   %-33s %s', k:gsub('_', '-'), help[k] or ''))
				end
			end
			return
		end
		say''
		say(' USAGE: '..app_name..' [OPTIONS] COMMAND ...')
		say''
		for k,v in sortedpairs(cmd) do
			print(fmt('   %-33s %s', k:gsub('_', '-'), help[k] or ''))
		end
		say''
		say' OPTIONS:'
		say''
		say'   -v       verbose'
		say'   --debug  debug'
		say''
	end

	function app:run_cmd(f, ...) --stub
		local exit_code = f(...)
		self:finish()
		return exit_code
	end

	--if you override run_cmd() then you have to call this!
	function app:finish()
		logging:toserver_stop()
	end

	function app:run(...)

		if ... == app_name then --caller module loaded with require()
			return app
		end

		check('fs', 'cd', fs.cd(app_dir), 'could not change dir to %s', app_dir)
		mkdir(var_dir)
		mkdir(tmp_dir)

		--set up logging.

		logging.deploy  = app.conf.deploy
		logging.env     = app.conf.env
		logging.verbose = app_name

		local i = 1
		local f
		while true do
			local s = select(i, ...)
			i = i + 1
			if s == '-v' then
				logging.verbose = true
				env('VERBOSE', 1) --propagate verbosity to sub-processes.
			elseif s == '--debug' then
				logging.verbose = true
				logging.debug = true
				env('DEBUG', 1) --propagate debug to sub-processes.
				env('VERBOSE', 1) --propagate verbosity to sub-processes.
			else
				if s == '--help' then s = 'help' end
				local c = s and s:gsub('-', '_')
				f = c and cmd[c]
					or (Windows and wincmd[c])
					or (Linux   and lincmd[c])
					or cmd.help
				break
			end
		end

		--inherit debug and verbosity from parent process.
		if repl(env'DEBUG'  , '', nil) then logging.debug   = true end
		if repl(env'VERBOSE', '', nil) then logging.verbose = true end

		local logfile = indir(var_dir, app_name..'.log')
		logging:tofile(logfile)

		if app.conf.log_host and app.conf.log_port then
			logging:toserver(app.conf.log_host, app.conf.log_port)
		end

		return self:run_cmd(f, select(i, ...))
	end

	return app

end
