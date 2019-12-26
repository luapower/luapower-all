
--package info script.
--Written by Cosmin Apreutesei. Public Domain.

local luapower = require'luapower'
local glue = require'glue'
local pp = require'pp'
local ffi = require'ffi'

--import the luapower API into the script's global env.
setfenv(1, setmetatable({}, {__index = _G}))
glue.update(getfenv(), luapower)

--web links
------------------------------------------------------------------------------

--external doc refs for referencing external docs for modules and packages
local external_refs = memoize(function()
	local t = {}
	for s in io.lines(lpdir..'/'..config.links_file) do
		local ref, url = s:match'^%[([^%]]+)%]%:%s*(.*)$'
		t[ref] = url
	end
	return t
end)

--TODO: search for package's actual origin (don't assume luapower)
local github_source_url = memoize(function(project, path)
	return 'https://github.com/luapower/' .. project ..
		(path and '/blob/master/' .. path or '')
end)

--url for viewing a module's (or script's) source file.
local module_source_url = memoize(function(package, mod)
	if modules(package)[mod] then
		local lang = module_tags(package, mod).lang
		if not (lang == 'Lua' or lang == 'Lua/ASM') then return end
	end
	local path = modules(package)[mod] or scripts(package)[mod]
	return github_source_url(package, path)
end)

local function doc_url(mod)
	return config.new_site and '/'..mod or mod..'.html'
end

local function module_doc_url_(package, mod)
	if external_refs()[mod] then
		return external_refs()[mod]
	end
	if package and docs(package)[mod] then
		return doc_url(mod)
	end
end

--best url for referencing a module: either an external url, a doc url,
--the first doc url of one of the parents, the view-source url, or none.
local module_doc_url = memoize(function(package, mod)
	local mod0 = mod
	while mod do
		local url = module_doc_url_(package, mod)
		if url then
			if mod == mod0 then
				return url
			else
				return url..'#'..mod0:sub(#mod + 2) --'bitmap_blend' -> 'blend'
			end
		end
		if not package then return end
		mod = module_parent(package, mod)
	end
	return module_source_url(package, mod0)
end)

--url for viewing a package's browsing page
local package_source_url = memoize(function(package)
	return github_source_url(package)
end)

--best url for referencing a package: either a doc url or the github home url
local package_doc_url = memoize(function(package)
	if docs(package)[package] then
		return doc_url(package)
	else
		return package_source_url(package)
	end
end)

--package output

local function module_list(t)
	local dt = glue.keys(t)
	table.sort(dt, module_name_cmp)
	return dt
end

if not connect then
	local loop = require'socketloop'
	connect = loop.connect
	newthread = loop.newthread
	wait = loop.start
end

--execute handler(platform, luapower_namespace) for each platform.
local function platform_info(handler)
	local threads = {}
	for platform, srv in pairs(config.servers) do
		local ip, port = unpack(srv)
		local thread = thread_api.newthread(function()
			local host =
				(ip or luapower.config.default_ip)..':'..
				(port or luapower.config.default_port)
			--print('connecting: ', host, platform)
			local lp = connect(ip, port, thread_api.connect)
			--print('connected: ', host, lp.platform())
			handler(platform, lp)
			lp.close()
		end)
		table.insert(threads, thread)
	end
	thread_api.wait(table.unpack(threads))
end

--local platform_count = glue.count(config.servers)

local package_info = memoize(function(package)
	local t = {}
	t.name = package
	t.source_url = package_source_url(package)
	t.doc_url = package_doc_url(package)
	t.clib = c_tags(package)
	if t.clib then
		t.clib.csrc_dir = csrc_dir(package)
	end
	t.platforms = platforms(package)
	t.modules = module_list(modules(package))

	local mpdeps = {} --{mod={platf={pkg=}}}
	local pkgn = {}
	local pkgmodn = {}
	platform_info(function(platform, lp)
		t.type = lp.package_type(package)
		for mod in pairs(modules(package)) do
			local err = lp.module_load_error(mod)
			if not err then
				local pdeps = lp.module_requires_packages_all(mod, package)
				for pkg in pairs(pdeps) do
					pkgn[pkg] = glue.attr(pkgn, pkg, 0) + 1
					local pkgn = glue.attr(pkgmodn, mod)
					pkgn[pkg] = glue.attr(pkgn, pkg, 0) + 1
				end
				glue.attr(mpdeps, mod)[platform] = pdeps
			end
		end
	end)

	local pkgall = {}
	local modn = glue.count(modules(package))
	for pkg, n in pairs(pkgn) do
		if n == modn then
			pkgall[pkg] = true
		end
	end

	local mpldeps = {}
	for mod, t in pairs(mpdeps) do
		local pldeps = {all = {}}
		mpldeps[mod] = pldeps
		for platf, pkgdeps in pairs(t) do
			local deps = {}
			pldeps[platf] = deps
			for pkg in pairs(pkgdeps) do
				if not pkgall[pkg] then
					deps[pkg] = platf
				end
			end
		end
	end

	local t2 = {} --{mod={pkg={n=#platf, platforms={platf=true}}}}
	for mod, mt in pairs(t1) do
		for platform, m in pairs(mt.platforms) do
			for pkg in pairs(m.package_deps) do
				local t = glue.attr(glue.attr(t2, mod), pkg)
				glue.attr(t, 'platforms')[platform] = true
				t.n = (t.n or 0) + 1
			end
		end
	end

	local t3 = {}
	for mod, mt in pairs(t2) do
		for pkg, pt in pairs(mt) do
			if pt.n == platform_count then
				glue.attr(glue.attr(t3, mod), 'all')[pkg] = true
			else
				for platform in pairs(pt.platforms) do
					glue.attr(glue.attr(t3, mod), platform)[pkg] = true
				end
			end
		end
	end
	t.m = t3

	t.module_data = {}
	for mod in pairs(modules(package)) do
		local dm = {}
		t.module_data[mod] = dm
	end

	--[[
	--info on modules
	t.module_data = {}
	for mod,file in pairs(modules(package)) do
		local m = {}
		t.module_data[mod] = m

		m.file = file
		m.source_url = module_source_url(package, mod)
		m.doc_url = module_doc_url(package, mod)

		glue.update(m, module_tags(package, mod)) --lang, demo_module, test_module
	end

	--info on external modules
	for mod in pairs(need_info) do
		if not t.module_data[mod] then
			local m = {}
			t.module_data[mod] = m
			m.package = module_package(mod)
		end
	end

	--info on scripts
	t.scripts = {}
	for mod,file in pairs(scripts(package)) do
		local m = {}
		t.scripts[mod] = m

		m.file = file
		m.source_url = module_source_url(package, mod)

		m.requires = module_requires_by_parsing(mod)
	end

	--info on docs
	t.docs = {}
	for doc,path in pairs(docs(package)) do
		local d = {}
		t.docs[doc] = d
		glue.update(d, doc_tags(package, doc))
		d.file = path
		d.url = doc_url(doc)
	end

	--reverse require dependencies (internal)
	for mod in pairs(modules(package)) do
		for uses_mod in pairs(module_requires_int(mod, package)) do
			glue.attr(t.module_data[uses_mod], 'required_by_int')[mod] = true
		end
	end
	]]

	--[[
	--reverse autoload dependencies (internal)
	for mod in pairs(modules(package)) do
		for autoload_key, uses_mod in pairs(t.module_data[mod].autoloads) do
			local m = t.module_data[uses_mod]
			if m then --internal autoload
				glue.attr(m, 'autoloaded_by_int')[mod] = autoload_key
			end
		end
	end
	]]

	--[[
	--build the runtime tree

	local autoloaded = {} --dump bucket for all autoloaded modules
	for mod,m in pairs(t.modules) do
		if m.autoloaded_by_int then
			autoloaded[mod] = true
		end
	end
	for mod in pairs(autoloaded) do
		if module_requires_int(mod, package) then
			autoloaded[mod] = true
		end
	end

	local function is_top(mod)
		if autoloaded[mod] then return end --autoloaded, so not top
		local rt = t.modules[mod].required_by_int
		if not rt then return true end --not required, so top
		for rmod in pairs(rt) do
			if not autoloaded[rmod] then return end --required by non-autoloaded, so not top
		end
		return true --required only by autoloaded modules, so top
	end
	t.require_tree = {}
	for mod,m in pairs(t.modules) do
		if is_top(mod) then
			t.require_tree[mod] = true
		end
	end
	]]

	return t
end)

