
--luapower command-line interface.
--Written by Cosmin Apreutesei. Public Domain.

if ... == 'luapower_cli' then return end --loaded as module: nothing to show

local lp = require'luapower'
local glue = require'glue'
local _ = string.format

--hack: set stdout to binary mode to avoid writing out CR's which breaks bash.
local ffi = require 'ffi'
if ffi.os == 'Windows' then
	ffi.cdef[[
		int _setmode(int, int);
		int _fileno(void *);
	]]
	local _O_BINARY = 0x8000
	assert(ffi.C._setmode(ffi.C._fileno(io.stdout), _O_BINARY) ~= -1)
end

--listing helpers
------------------------------------------------------------------------------

local function list_values(t)
	for i,k in ipairs(t) do
		print(k)
	end
end

local function list_keys(t, cmp)
	for k in glue.sortedpairs(t, cmp) do
		print(k)
	end
end

local function list_kv(t, cmp)
	for k,v in glue.sortedpairs(t, cmp) do
		print(_('%-20s %s', k, v))
	end
end

local function enum_values(t)
	return table.concat(t, ', ')
end

local function enum_keys(kt, cmp)
	local t = {}
	for k in glue.sortedpairs(kt, cmp) do
		t[#t+1] = k
	end
	return enum_values(t)
end

local function list_tree(t)
	lp.walk_tree(t, function(node, level)
		print(('  '):rep(level) .. node.name)
	end)
end

local function lister(lister)
	return function(handler, cmp)
		return function(...)
			lister(handler(...), cmp)
		end
	end
end
local values_lister = lister(list_values)
local keys_lister = lister(list_keys)
local kv_lister = lister(list_kv)
local tree_lister = lister(list_tree)

local function list_errors(title, t, lister)
	if not next(t) then return end
	local s = _('%s (%d)', title, glue.count(t))
	print(s)
	print(('-'):rep(#s))
	lister = lister or list_keys
	lister(t)
	print''
end

local function package_lister(handler, lister, enumerator)
	lister = lister or print
	enumerator = enumerator or glue.pass
	return function(package, ...)
		if package then
			local v = handler(package, ...)
			if v then
				lister(v)
			end
		else
			for package in glue.sortedpairs(lp.installed_packages()) do
				local v = handler(package, ...)
				if v then
					print(_('%-16s %s', package, enumerator(v)))
				end
			end
		end
	end
end

local function module_lister(handler, lister, enumerator)
	lister = lister or print
	enumerator = enumerator or glue.pass
	return function(mod, ...)
		if mod then
			local v = handler(mod, ...)
			if v then
				lister(v)
			end
		else
			for mod in glue.sortedpairs(lp.modules()) do
				local v = handler(mod, ...)
				if v then
					print(_('%-26s %s', mod, enumerator(v)))
				end
			end
		end
	end
end

local function enum_deps(deps_t)
	local t = {}
	--invert {platform = {dep=true}} to {dep = {platform = true}}
	local platforms = {}
	for pl, deps in pairs(deps_t) do
		for dep in pairs(deps) do
			local dt = glue.attr(platforms, dep)
			dt[pl] = true
		end
	end
	local maxpcount = glue.count(lp.supported_platforms)
	--for deps that are present on all platforms, show them simply,
	--without listing the platforms, otherwise show `dep (platform1, ...)`
	for dep, pt in glue.sortedpairs(platforms) do
		if glue.count(pt) < maxpcount then
			local deps = table.concat(glue.keys(pt, true), ', ')
			table.insert(t, dep..' ('..deps..')')
		else
			table.insert(t, dep)
		end
	end
	return table.concat(t, ', ') -- `dep1 (platform1, ...), ...`
end

local function list_ctags(t)
	print(_('  %-20s: %s', 'clib name', t.realname))
	print(_('  %-20s: %s', 'clib version', t.version))
	print(_('  %-20s: %s', 'release url', t.url))
	print(_('  %-20s: %s', 'license', t.license))
	print(_('  %-20s: %s', 'dependencies', enum_deps(t.dependencies)))
end

local function list_mtags(package, mod)
	if not package then
		for package in pairs(lp.installed_packages()) do
			list_mtags(package)
		end
	elseif not mod or mod == '--all' then
		for mod in pairs(lp.modules(package)) do
			list_mtags(package, mod)
		end
	else
		local mt = lp.module_tags(package, mod)
		local flags = {}
		if mt.test_module then table.insert(flags, 'test') end
		if mt.demo_module then table.insert(flags, 'demo') end
		print(_('%-16s %-24s %-6s %-4s',
			package, mod, mt.lang, table.concat(flags, ', ')))
	end
end

local function list_mheader(package, mod)
	if not package then
		for package in pairs(lp.installed_packages()) do
			list_mheader(package)
		end
	elseif not mod or mod == '--all' then
		local t = lp.module_headers(package)
		for i,t in ipairs(t) do
			print(_('%-26s %-26s %-60s %-26s %s',
				t.module, t.name or t.module,
				t.descr or '', t.author or '', t.license or ''))
		end
	else
		local t = lp.module_header(package, mod)
		print(_('%-26s %-26s %-60s %-26s %s',
			mod, t.name, t.descr, t.author, t.license))
	end
end

local function enum_ctags(t)
	return _('%-24s %-16s %-16s %-36s',
		t.realname, t.version, t.license, t.url)
end

--command actions
------------------------------------------------------------------------------

local actions
local action_list

local function add_action(name, args, info, handler)
	local action = {name = name, args = args, info = info, handler = handler}
	actions[name] = action
	action_list[#action_list+1] = action
end

local function add_section(title)
	action_list[#action_list+1] = {title = title}
end

local function assert_arg(ok, ...)
	if ok then return ok,... end
	print''
	print('ERROR: '..(...))
	print''
	os.exit(1)
end

--wrapper for command handlers that take <package> as arg#1
--it provides the default value for <package>.
local function package_arg(handler, package_required, package_invalid_ok)
	return function(package, ...)
		if package == '--all' then
			package = nil
		else
			package = package or os.getenv'MULTIGIT_REPO'
		end
		assert_arg(package or not package_required, 'package required')
		assert_arg(
			not package
			or package_invalid_ok
			or lp.installed_packages()[package],
			'unknown package '..tostring(package))
		return handler(package, ...)
	end
end

local function help()
	print''
	print(_([[
USAGE: luapower [-s|--server IP|NAME] [-p|--port PORT] COMMAND ...]], arg[0]))
	for i,t in ipairs(action_list) do
		if t.name then
			print(_('   %-30s %s', t.name .. ' ' .. t.args, t.info))
		elseif t.title then
			print''
			print(t.title)
			print''
		end
	end
print[[

NOTES

   The MODULE arg can be `modules-of-PACKAGE`, which results in the combined
   list of dependencies for all modules of PACKAGE.

   The PACKAGE arg defaults to the env var MULTIGIT_REPO, as set by the `mgit`
   subshell, and if that is not set, and the PACKAGE arg is optional, then it
   defaults to `--all`, which means that it applies to all packages.

   Example:

       ./luapower packages-of d-alltime-all modules-of-winapi mingw32')

   will return the packages of direct + indirect (all) loadtime + runtime
   + autoloaded (alltime) module dependencies of all modules of package
   "winapi" that were recorded on the mingw32 platform.
]]
end

local function consistency_checks(package)
	--global checks, only enabled if package is not specified
	if not package then
		list_errors('duplicate docs', lp.duplicate_docs())
	end
	--package-specific checks (they also work with no package specified)
	list_errors('undocumented packages', lp.undocumented_package(package))
	list_errors('module load errors', lp.load_errors(package), list_kv)
end

local d_commands = {
	'd-loadtime',         'module_requires_loadtime',
	                      'load-time requires',

	'd-autoload',         'module_autoloaded',
	                      'autoloaded requires',

	'd-runtime',          'module_requires_runtime',
	                      'runtime requires',

	'd-alltime',          'module_requires_alltime',
	                      'load-time + runtime + autoloaded req',

	'd-loadtime-all',     'module_requires_loadtime_all',
	                      'load-time direct + indirect requires',

	'd-alltime-all',      'module_requires_alltime_all',
	                      'all-time direct + indirect requires',

	'd-loadtime-int',     'module_requires_loadtime_int',
	                      'load-time internal (same package) requires',

	'd-loadtime-ext',     'module_requires_loadtime_ext',
	                      'load-time direct-external requires',

	'd-rev-loadtime',     'module_required_loadtime',
	                      'reverse direct load-time requires',

	'd-rev-alltime',      'module_required_alltime',
	                      'reverse direct all-time requires',

	'd-rev-loadtime-all', 'module_required_loadtime_all',
	                      'reverse direct + indirect load-time requires',

	'd-rev-alltime-all',  'module_required_alltime_all',
	                      'reverse direct + indirect all-time requires',
}

local dmap = {}
for i=1,#d_commands,3 do
	local cmd, func_name = d_commands[i], d_commands[i+1]
	dmap[cmd] = func_name
end

local function d_command(cmd, ...)
	local of, mod, platform
	if cmd == 'packages-of' or cmd == 'ffi-of' then
		of, cmd, mod, platform = cmd, ...
	else
		mod, platform = ...
	end
	assert(mod, 'module required')
	local func_name = assert_arg(dmap[cmd], 'invalid d-... command')
	local pkg = mod:match'^modules%-of%-(.*)'
	assert_arg(not pkg or lp.installed_packages()[pkg],
		'invalid package '..tostring(pkg))

	return lp.exec(function(func_name, of, pkg, mod, platform)
		local lp = require'luapower'
		local func = lp[func_name]
		local t
		if pkg then
			t = {}
			for mod in pairs(lp.modules(pkg)) do
				glue.update(t, func(mod, pkg, platform))
			end
		else
			 t = func(mod, nil, platform) --package inferred
		end
		if of then
			local mt = t
			t = {}
			if of == 'packages-of' then
				--convert to packages of result
				for mod in pairs(mt) do
					local dpkg = lp.module_package(mod)
					if dpkg and dpkg ~= pkg then --exclude self
						t[dpkg] = true
					end
				end
			elseif of == 'ffi-of' then
				--add ffis of arg
				if pkg then
					for mod in pairs(lp.modules(pkg)) do
						glue.update(t,
							lp.module_requires_loadtime_ffi(mod, pkg, platform))
					end
				else
					glue.update(t,
						lp.module_requires_loadtime_ffi(mod, nil,platform))
				end
				--add ffis of result
				for mod in pairs(mt) do
					glue.update(t,
						lp.module_requires_loadtime_ffi(mod, nil, platform))
				end
			end
		end
		return t
	end, func_name, of, pkg, mod, platform)
end

--generate a nice markdown page for a package
local function describe_package(package, platform)

	local llp = require'luapower' --local module, not rpc

	local function h(s)
		print''
		print('## '..s)
		print''
	end

	h'Overview'
	local dtags = lp.doc_tags(package, package) or {}
	print(_('  %-20s: %s', 'name', package))
	print(_('  %-20s: %s', 'tagline', dtags.tagline or ''))
	print(_('  %-20s: %s', 'type', lp.package_type(package)))
	print(_('  %-20s: %s', 'tag', lp.git_tag(package)))
	print(_('  %-20s: %s', 'tags', enum_values(lp.git_tags(package))))
	print(_('  %-20s: %s', 'version', lp.git_version(package)))
	print(_('  %-20s: %s', 'license', lp.license(package)))
	print(_('  %-20s: %s', 'platforms', enum_keys(lp.platforms(package))))
	print(_('  %-20s: %s', 'category', lp.package_cat(package) or ''))

	if next(lp.modules(package)) then
		h'Modules'
		llp.walk_tree(lp.module_tree(package), function(node, level)
			local mod = node.name
			local mt = lp.module_tags(package, mod)
			local err = lp.module_load_error(mod, package, platform)
			local deps = lp.module_requires_loadtime_ext(mod, package, platform)
			local flags =
				(mt.test_module and 'T' or '') ..
				(mt.demo_module and 'D' or '')
			print(_('%-30s %-8s %-4s %s',
				('  '):rep(level) .. '  ' .. mod, mt.lang, flags,
				err and '(!) '..err or enum_keys(deps, llp.module_name_cmp)))
		end)

		h'Dependencies'
		for i=1,#d_commands,3 do
			local cmd = d_commands[i]
			local t = d_command(
				'packages-of', cmd, 'modules-of-'..package, platform)
			print(_('  %-20s: %s', cmd, enum_keys(t)))
		end
		print(_('  %-20s: %s', 'd-bin',
			enum_keys(lp.bin_deps(package, platform))))
		print(_('  %-20s: %s', 'd-bin-all',
			enum_keys(lp.bin_deps_all(package, platform))))
		print(_('  %-20s: %s', 'd-rev-bin',
			enum_keys(lp.rev_bin_deps(package, platform))))
		print(_('  %-20s: %s', 'd-rev-bin-all',
			enum_keys(lp.rev_bin_deps_all(package, platform))))
	end

	if next(lp.scripts(package)) then
		h'Scripts'
		list_keys(lp.scripts(package))
	end

	if lp.what_tags(package) then
		h'C Lib'
		list_ctags(lp.what_tags(package))
	end

	if next(lp.docs(package)) then
		h'Docs'
		for doc, path in glue.sortedpairs(lp.docs(package)) do
			local t = lp.doc_tags(package, doc)
			print(_('  %-20s %s', t.title, t.tagline or ''))
		end
	end
	print''
end

local function start_server(v, ip, port)
	local loop = require'socketloop'
	local rpc = require'luapower_rpc'
	if v ~= '-v' then
		v, ip, port = false, v, ip
	end
	rpc.verbose = v and true
	rpc.server(ip, port)
	loop.start(1)
end

local function init_actions()

	actions = {}
	action_list = {}

	add_section'HELP'

	add_action('help', '', 'this screen', help)
	add_action('--help', '', 'this screen', help)

	add_section'PACKAGES'

	add_action('ls',          '', 'list installed packages',
		keys_lister(lp.installed_packages))

	add_action('ls-all',      '', 'list all known package',
		keys_lister(lp.known_packages))

	add_action('ls-uncloned', '', 'list not yet installed packages',
		keys_lister(lp.not_installed_packages))

	add_section'PACKAGE INFO'

	add_action('describe',  ' PACKAGE  [PLATFORM]', 'describe a package',
		package_arg(describe_package, true))

	add_action('type',      '[PACKAGE]', 'package type',
		package_arg(package_lister(lp.package_type)))

	add_action('version',   '[PACKAGE]', 'current git version',
		package_arg(package_lister(lp.git_version)))

	add_action('tags',      '[PACKAGE]', 'git tags',
		package_arg(package_lister(lp.git_tags, list_values, enum_values)))

	add_action('tag',       '[PACKAGE]', 'current git tag',
		package_arg(package_lister(lp.git_tag)))

	add_action('files',     '[PACKAGE]', 'tracked files',
		package_arg(keys_lister(lp.tracked_files)))

	add_action('docs',      '[PACKAGE]', 'docs',
		package_arg(keys_lister(lp.docs)))

	add_action('modules',   '[PACKAGE] [PLATFORM]', 'modules',
		package_arg(keys_lister(function(pkg, platform)
			if not platform then
				return lp.modules(pkg)
			end
			local t = {}
			for mod in pairs(lp.modules(pkg)) do
				local pt = lp.module_platforms(mod, pkg)
				if not next(pt) or pt[platform] then
					t[mod] = true
				end
			end
			return t
		end)))

	add_action('scripts',   '[PACKAGE]', 'scripts',
		package_arg(keys_lister(lp.scripts)))

	add_action('tree',      '[PACKAGE]', 'module tree',
		package_arg(tree_lister(lp.module_tree)))

	add_action('mtags',     '[PACKAGE [MODULE]]', 'module info',
		package_arg(list_mtags))

	add_action('mheader',   '[PACKAGE [MODULE]]', 'module header',
		package_arg(list_mheader))

	add_action('platforms', '[PACKAGE]', 'supported platforms',
		package_arg(package_lister(lp.platforms, list_keys, enum_keys)))

	add_action('ctags',     '[PACKAGE]', 'C package info',
		package_arg(package_lister(lp.what_tags, list_ctags, enum_ctags)))

	add_action('mplatforms','[MODULE]', 'supported platforms per module',
		module_lister(lp.module_platforms, list_keys, enum_keys))

	add_section'CHECKS'

	add_action('check',        '[PACKAGE]', 'run all consistency checks',
		package_arg(consistency_checks))

	add_action('load-errors',  '[PACKAGE] [PLATFORM]',
		'list module load errors',
		kv_lister(package_arg(lp.load_errors)))

	add_section'DEPENDENCIES'

	add_action('d-tree', '              MODULE  [PLATFORM]',
		'load-time require tree',
		tree_lister(function(mod, platform)
			return lp.module_requires_loadtime_tree(mod, nil, platform)
		end))

	for i=1,#d_commands,3 do
		local cmd, __, descr = unpack(d_commands, i, i+2)
		local args = string.rep(' ', 18 - #cmd)..' [MODULE] [PLATFORM]'
		add_action(cmd, args, descr,
			module_lister(function(...) return d_command(cmd, ...) end,
			list_keys, enum_keys))
	end

	add_action('ffi-of', '       d-... [MODULE] [PLATFORM]',
		'ffi.loads of module dependencies',
		function(cmd, mod, ...)
			return module_lister(function(mod, ...)
				return d_command('ffi-of', cmd, mod, ...)
			end, list_keys, enum_keys)(mod, ...)
		end)

	add_action('packages-of', '  d-... [MODULE] [PLATFORM]',
		'packages of module dependencies',
		function(cmd, mod, ...)
			return module_lister(function(mod, ...)
				return d_command('packages-of', cmd, mod, ...)
			end, list_keys, enum_keys)(mod, ...)
		end)

	add_action('d-bin', '        [PACKAGE] [PLATFORM]',
		'direct binary dependencies',
		package_arg(package_lister(lp.bin_deps, list_keys, enum_keys)))

	add_action('d-bin-all', '    [PACKAGE] [PLATFORM]',
		'direct + indirect binary dependencies',
		package_arg(package_lister(lp.bin_deps_all, list_keys, enum_keys)))

	add_action('d-rev-bin', '    [PACKAGE] [PLATFORM]',
		'reverse direct binary dependencies',
		package_arg(package_lister(lp.rev_bin_deps, list_keys, enum_keys)))

	add_action('d-rev-bin-all', '[PACKAGE] [PLATFORM]',
		'direct + indirect binary dependencies',
		package_arg(package_lister(lp.rev_bin_deps_all, list_keys, enum_keys)))

	add_action('build-order',    '[PACKAGE1,...] [PLATFORM]',
		'build order',
		package_arg(values_lister(lp.build_order), nil, true))

	add_section'RPC'

	add_action('server',  '[-v] [IP [PORT]] | [PLATFORM]',
		'start the RPC server',
		start_server)

	add_action('restart', '', 'restart a RPC server', lp.restart)

	add_action('stop',    '', 'stop a RPC server', lp.stop)

	add_action('platform','',
		'report platform',
		function() print(lp.current_platform()) end)

	add_action('os-arch', '',
		'report OS and arch',
		function() print(lp.osarch()) end)

	add_action('server-status', '[PLATFORM]',
		'show status of RPC servers',
		function(platform)
			for platform, t in glue.sortedpairs(lp.server_status()) do
				print(platform, t.os or '', t.arch or '', t.err or '')
			end
		end)

	add_action('listen',  '[-v] [IP [PORT]]', 'start a luapower server')
	add_action('connect', '[-v] [IP [PORT]]', 'connect to a luapower server')

	add_section'DEPENDENCY DB'

	add_action('update-db', '[package] [platform]',
		'update the dependency database',
		package_arg(function(package, platform)
			lp.update_db(package, platform)
			lp.save_db()
		end))

	add_action('update-mgit-deps', '[package]',
		'update the .mgit/*.deps file(s)',
		package_arg(function(package)
			lp.update_mgit_deps(package)
		end))
end

local function run(action, ...)
	action = action or 'help'
	init_actions()
	if not actions[action] then
		print''
		print('ERROR: invalid command '..action)
		print''
		return
	end
	actions[action].handler(...)
end

local t = glue.extend({}, arg)
local server, port
if t[1] == '-s' or t[1] == '--server' then
	table.remove(t, 1)
	server = table.remove(t, 1)
end
if t[1] == '-p' or t[1] == '--port' then
	table.remove(t, 1)
	port = table.remove(t, 1)
end
if server or port then
	local loop = require'socketloop'
	loop.newthread(function()
		lp = assert(lp.connect(server, port))
		run(unpack(t))
		lp.close()
	end)
	loop.start(1)
else
	run(unpack(t))
end

