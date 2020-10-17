
--main entry point for all URIs that are not static files.
--dispatches URIs to individual actions.

require'webb'
local ffi = require'ffi'
local lp = require'luapower'
local fs = require'fs'
local tuple = require'tuple'

lp.persistent_cache = config('luapower_persistent_cache', false)

--in our current setup, the dependency db must be updated manually.
lp.auto_update_db          = config('luapower_allow_update_db_locally', false)
lp.allow_update_db_locally = config('luapower_allow_update_db_locally', false)

local pandoc_cmd = 'bin/'..lp.current_platform()..'/pandoc'
if ffi.abi'win' then pandoc_cmd = pandoc_cmd:gsub('/', '\\') end

local action = {} --{name->handler}

--helpers --------------------------------------------------------------------

--filesystem

local function older(file1, file2)
	local mtime1 = fs.attr(file1, 'mtime')
	local mtime2 = fs.attr(file2, 'mtime')
	if not mtime1 then return true end
	if not mtime2 then return false end
	return mtime1 < mtime2
end

local function escape_filename(s)
	return (s:gsub('[/\\%?%%%*%:|"<> ]', '-'))
end

local function render_main(name, data)
	template.content = template(name)
	local html = render('main',
		glue.merge({
			grep_enabled = true,
		}, data)
	)
	template.content = nil
	return html
end

--date/time formatting

local function rel_time(s)
	if s > 2 * 365 * 24 * 3600 then
		return ('%d years'):format(math.floor(s / (365 * 24 * 3600)))
	elseif s > 2 * 30.5 * 24 * 3600 then
		return ('%d months'):format(math.floor(s / (30.5 * 24 * 3600)))
	elseif s > 1.5 * 24 * 3600 then
		return ('%d days'):format(math.floor(s / (24 * 3600)))
	elseif s > 2 * 3600 then
		return ('%d hours'):format(math.floor(s / 3600))
	elseif s > 2 * 60 then
		return ('%d minutes'):format(math.floor(s / 60))
	else
		return 'a minute'
	end
end

local function timeago(time)
	local s = os.difftime(os.time(), time)
	return string.format(s > 0 and '%s ago' or 'in %s', rel_time(math.abs(s)))
end

local function format_time(time)
	return time and os.date('%b %m \'%y %H:%M', time) or ''
end

local function format_date(time)
	return time and os.date('%b %m \'%y', time) or ''
end

--widgets --------------------------------------------------------------------

local widgets = {}

function widgets.module_list(package)
	local origin_url = lp.git_origin_url(package)
	local t = lp.module_headers(package)
	local dt = {}
	local function _(...) dt[#dt+1] = string.format(...)..'\n' end
	local cat0
	_'<table width=100%%>'
	for i,t in ipairs(t) do
		local path = tostring(lp.modules(package)[t.module])
		local docpath = lp.docs(package)[t.module]

		local cat = t.name and t.name:match'^(.-)/[^/]+$' or 'other'
		if cat ~= cat0 then
			_(' <tr><td colspan=2><strong>%s</strong></td>'..
				'<td class="gray small" style="vertical-align: bottom">'..
				'last updated</td></tr>', cat)
			cat0 = cat
		end

		local mtime = lp.git_file_time(package, path)
		if mtime then
			t.mtime = format_date(mtime)
			t.mtime_ago = timeago(mtime)
		end

		local tagline = lp.module_tagline(package, t.module)

		local doclink = docpath and
			string.format(' [<a href="/%s">doc</a>]', t.module) or ''

		_' <tr>'
			_ '  <td class=nowrap>'
			_('   <a href="%s/blob/master/%s?ts=3">%s</a>%s',
				origin_url, path, t.module, doclink)
			_ '  </td><td>'
			_('   %s', tagline or '')
			_ '  </td><td class=nowrap>'
			_('   <span class=time time="%s" reltime="%s">%s</span>',
				t.mtime, t.mtime_ago, t.mtime_ago)
			_ '  </td>'
		_' </tr>'
	end
	_'</table>'
	return table.concat(dt)
end

--doc rendering --------------------------------------------------------------

local function md_refs()
	local t = {}
	local refs = {}
	local function addref(s)
		if refs[s] then return end
		table.insert(t, string.format('[%s]: /%s', s, s))
		refs[s] = true
	end
	--add refs in the order in which uris are dispatched.
	for pkg in pairs(lp.installed_packages()) do
		addref(pkg)
	end
	for doc in pairs(lp.docs()) do
		addref(doc)
	end
	for file in fs.dir(wwwpath'md') do
		if file:find'%.md$' then
			addref(file:match'^(.-)%.md$')
		end
	end
	table.insert(t, assert(glue.readfile(wwwpath'ext-links.md')))
	return table.concat(t, '\n')
end

local function render_docfile(infile)
	local outfile = config('www_dir')..'/.cache/'..escape_filename(infile)..'.html'
	if older(outfile, infile) then
		local s1 = glue.readfile(infile)
		local s2 = md_refs()
		local tmpfile = os.tmpname()
		assert(glue.writefile(tmpfile, s1..'\n\n'..s2))
		local cmd = pandoc_cmd..' --tab-stop=3 -r markdown+definition_lists -w html '..
			tmpfile..' > '..outfile
		os.execute(cmd)
		os.remove(tmpfile)
	end
	return assert(glue.readfile(outfile))
end

local function render_docheader(pkg, mod, h)
	if not h.doc then return end
	local url = lp.git_origin_url(pkg)
	local path = tostring(lp.modules(pkg)[mod])
	return '<pre>'..h.doc..'</pre><p> See the '..
		string.format('<a href="%s/blob/master/%s?ts=3">source code</a>', url, path)
		..' for more info.</p>'
end

local function www_docfile(doc)
	local docfile = wwwpath('md/'..doc..'.md')
	if not fs.is(docfile) then return end
	return docfile
end

local function action_docfile(doc)
	local t = {}
	local docfile = www_docfile(doc)
	t.doc_html = render_docfile(docfile)
	local dtags = lp.docfile_tags(docfile)
	t.title = dtags.title
	t.tagline = dtags.tagline
	local mtime = fs.attr(docfile, 'mtime')
	t.doc_mtime = format_date(mtime)
	t.doc_mtime_ago = mtime and timeago(mtime)
	t.edit_link = string.format('https://github.com/luapower/website/edit/master/luapower-www/md/%s.md', doc)
	t.docs = {}
	for file in fs.dir(wwwpath'md') do
		if not file then break end
		local name = file:match'(.-)%.md$'
		if name then
			table.insert(t.docs, {
				shortname = name,
				name = name,
				source_url = string.format('https://github.com/luapower/website/blob/master/luapower-www/md/%s.md?ts=3', doc),
				selected = name == doc,
			})
		end
	end
	table.sort(t.docs, function(a, b) return a.name < b.name end)
	out(render_main('doc', t))
end

--package info ---------------------------------------------------------------

local ljsrc = 'https://github.com/LuaJIT/LuaJIT/blob/master/src/'

local module_src_urls = {
	string    = ljsrc..'lib_string.c',
	table     = ljsrc..'lib_table.c',
	coroutine = ljsrc..'lib_base.c',
	package   = ljsrc..'lib_package.c',
	io        = ljsrc..'lib_io.c',
	math      = ljsrc..'lib_math.c',
	os        = ljsrc..'lib_os.c',
	_G        = ljsrc..'lib_base.c',
	debug     = ljsrc..'lib_debug.c',
	ffi       = ljsrc..'lib_ffi.c',
	bit       = ljsrc..'lib_bit.c',
	jit       = ljsrc..'lib_jit.c',
	['jit.util']    = ljsrc..'lib_jit.c',
	['jit.profile'] = ljsrc..'lib_jit.c',
}

local function source_url(pkg, path, mod)
	local url = module_src_urls[mod]
	if url then return url end
	if type(path) ~= 'string' then return end
	local url = lp.git_origin_url(pkg)
	if url:find'github%.com' then
		return string.format('%s/blob/master/%s?ts=3', url, path)
	else
		--NOTE: we don't have non-github browsable URLs yet,
		--so this is just a placeholder for now.
		return string.format('%s/master/%s', url, path)
	end
end

local os_list          = lp.supported_os_list
local os_platform_list = lp.supported_os_platform_list
local platform_list    = lp.supported_platform_list

--create a custom-ordered list of possible platforms.
local ext_platform_list = {'all', 'common'}
for _,os in ipairs(os_list) do
	table.insert(ext_platform_list, os)
	glue.extend(ext_platform_list, os_platform_list[os])
end

local platform_icon_titles = {
	mingw   = 'Windows',
	mingw64 = '64bit Windows',
	linux   = 'Linux',
	linux64 = '64bit Linux',
	osx     = 'OS X',
	osx64   = '64bit OS X',
}

--platform icons, in order, given a map of supported platforms. vis_only
--controls whether a missing platform show as disabled or not included at all.
--if both 32bit and 64bit platforms of the same OS are supported,
--the result is a single OS icon without the 32/64 label.
local function platform_icons(platforms, vis_only)
	local t = {}
	for _,p in ipairs(platform_list) do
		if not vis_only or platforms[p] then
			table.insert(t, {
				name = p,
				disabled = not platforms[p] and 'disabled' or nil,
			})
		end
	end
	--combine 32bit and 64bit icon pairs into OS icons
	local i = 1
	while i < #t do
		if t[i].name:match'^[^%d]+' == t[i+1].name:match'^[^%d]+' then
			if t[i].disabled == t[i+1].disabled then
				t[i].name = t[i].name:match'^([^%d]+)'
			else
				t[i].name = t[i].disabled and t[i+1].name or t[i].name
				t[i].disabled = nil
			end
			table.remove(t, i+1)
		end
		i = i + 1
	end
	--set the icon title
	for i,pt in ipairs(t) do
		pt.title = (pt.disabled and 'doesn\'t work on ' or 'works on ')..
			platform_icon_titles[pt.name]
	end
	return t
end

--given {place1 = {item1 = val1, ...}, ...}, extract items that are
--found in all places into the place indicated by all_key.
local function extract_common_keys(maps, all_key)
	--count occurences for each item
	local maxn = glue.count(maps)
	--if less than two places to group, don't group
	if maxn < 2 then return maps end
	local nt = {} --{item = n}
	local tt = {} --{item = val}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			nt[item] = (nt[item] or 0) + 1
			--val of 'all' is the val of the first item.
			tt[item] = tt[item] or val
		end
	end
	--extract items found in all places
	local all = {}
	for item, n in pairs(nt) do
		if n == maxn then
			all[item] = tt[item]
		end
	end
	--add items not found in all places, to their original places
	local t = {[all_key] = next(all) and all}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			if all[item] == nil then
				glue.attr(t, place)[item] = val
			end
		end
	end
	return t
end

--same as above, but use an "all-or-nothing strategy" of extraction
local function extract_common_keys_aot(maps, all_key)
	--count occurences for each item
	local maxn = glue.count(maps)
	--if less than two places to group, don't group
	if maxn < 2 then return maps end
	local nt = {} --{item = n}
	local tt = {} --{item = val}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			nt[item] = (nt[item] or 0) + 1
			--val of 'all' is the val of the first item.
			tt[item] = tt[item] or val
		end
	end
	--check to see if all items were extracted
	local all_extracted = true
	for item, n in pairs(nt) do
		if n < maxn then
			all_extracted = false
		end
	end
	return all_extracted and {[all_key] = tt} or maps
end

--given {platform1 = {item1 = val1, ...}, ...}, group items that are
--common to the same OS into OS keys, and all-around common items
--into the all_key key, if given.
local function platform_maps(maps, all_key, aot)
	local extract = aot and extract_common_keys_aot or extract_common_keys
	--extract common items across all places, if all_key given
	maps = all_key and extract(maps, all_key) or glue.update({}, maps)
	--combine platforms per OS
	for _,os in ipairs(os_list) do
		local t = {}
		for _,platform in ipairs(os_platform_list[os]) do
			t[platform] = maps[platform]
			maps[platform] = nil
		end
		glue.update(maps, extract(t, os))
	end
	return maps
end

--return the identifying icons for a package and a sorting string
local function package_icons(ptype, platforms, small)

	local has_lua = ptype:find'Lua'
	local has_ffi = ptype:find'ffi'

	local t = {}

	if ptype == 'Terra' then
		table.insert(t, {
			name = 'terra',
			title = 'written in Terra',
		})
	elseif ptype == 'Resty' then
		table.insert(t, {
			name = 'resty',
			title = 'written in Lua for OpenResty',
		})
	elseif has_ffi then
		table.insert(t, {
			name = 'luajit',
			title = 'written in Lua with ffi extension',
		})
	elseif has_lua then
		table.insert(t, {
			name = small and 'luas' or 'lua',
			title = 'written in Lua',
		})
	else
		table.insert(t, {
			name = small and 'luas' or 'lua',
			title = ptype .. ' package',
			invisible = 'invisible',
		})
	end

	--add platform icons
	if next(platforms) then --don't show platform icons for Lua modules
		glue.extend(t, platform_icons(platforms))
	end

	--create a "sorting string" that sorts the packages by platform support
	local st = {}
	local pt = glue.keys(platforms, true)
	table.insert(st, tostring(((has_lua or has_ffi) and #pt == 0)
		and 100 or #pt)) --portable vs cross-platform
	--Lua vs Lua+ffi vs others
	table.insert(st, has_ffi and 1 or has_lua and 2 or 0)
	--type, just to sort others predictably too
	table.insert(st, ptype)
	--platforms, just to group the same combinations together
	glue.extend(st, pt)
	local ss = table.concat(st, ';')

	return t, ss
end

--dependency lists

local function sorted_names(deps) --sort dependency lists by (kind, name)
	return glue.keys(deps, function(name1, name2)
		local kind1 = deps[name1].kind
		local kind2 = deps[name2].kind
		if kind1 == kind2 then return name1 < name2 end
		return kind1 < kind2
	end)
end

local function pdep_list(pdeps) --package dependency list
	local packages = {}
	local names = sorted_names(pdeps)
	for _,pkg in ipairs(names) do
		local pdep = pdeps[pkg]
		table.insert(packages, glue.update({
			dep_package = pkg,
			external = pdep and pdep.kind == 'external',
		}, pdep))
	end
	return packages
end

local function mdep_list(mdeps) --module dependency list
	local modules = {}
	local names = sorted_names(mdeps)
	for _,mod in ipairs(names) do
		local mt = mdeps[mod]
		table.insert(modules, glue.update({
			dep_module = mod,
		}, mt))
	end
	return modules
end

local function packages_of(dep_func, mod, pkg, platform)
	local t = {}
	for mod in pairs(dep_func(mod, pkg, platform)) do
		local dpkg = lp.module_package(mod)
		if dpkg and dpkg ~= pkg then --exclude self
			t[dpkg] = true
		end
	end
	return t
end

local function packages_of_many(dep_func, mod, pkg, platform)
	local t = {}
	for mod in pairs(mod) do
		glue.update(t, packages_of(dep_func, mod, pkg, platform))
	end
	return t
end

local function packages_of_all(dep_func, _, pkg, platform)
	return packages_of_many(dep_func, lp.modules(pkg), pkg, platform)
end

local function package_dep_maps(pkg, platforms)
	local pts = {}
	for platform in pairs(platforms) do
		local pt = {}
		pts[platform] = pt
		local pext = packages_of_all(lp.module_requires_loadtime_ext,
			nil, pkg, platform)
		local pall = packages_of_all(lp.module_requires_loadtime_all,
			nil, pkg, platform)
		local penv = packages_of_all(lp.module_environment,
			nil, pkg, platform)
		glue.update(pext, lp.bin_deps(pkg, platform))
		glue.update(pall, lp.bin_deps_all(pkg, platform))
		glue.update(pall, penv)
		for p in pairs(pall) do
			pt[p] = {kind = pext[p] and 'external' or penv[p] and 'environment' or 'indirect'}
		end
	end
	return pts
end


local function package_bin_dep_maps(pkg, platforms)
	local pts = {}
	for platform in pairs(platforms) do
		local pt = {}
		pts[platform] = pt
		local pext = lp.bin_deps(pkg, platform)
		local pall = lp.bin_deps_all(pkg, platform)
		for p in pairs(pall) do
			pt[p] = {kind = pext[p] and 'external' or 'indirect'}
		end
	end
	return pts
end

local function package_rev_dep_maps(pkg, platforms)
	local pts = {}
	for platform in pairs(platforms) do
		local pt = {}
		pts[platform] = pt
		local pext = packages_of_all(
			lp.module_required_loadtime, nil, pkg, platform)
		local pall = packages_of_all(
			lp.module_required_loadtime_all, nil, pkg, platform)
		glue.update(pext, lp.rev_bin_deps(pkg, platform))
		glue.update(pall, lp.rev_bin_deps_all(pkg, platform))
		for p in pairs(pall) do
			pt[p] = {kind = pext[p] and 'external' or 'indirect'}
		end
	end
	return pts
end

local function filter(t1, t2)
	local dt = {}
	for k, v in pairs(t1) do
		if t2[k] then
			dt[k] = v
		end
	end
	return dt
end

local function module_package_dep_maps(pkg, mod, platforms)
	local pts = {}
	for platform in pairs(platforms) do
		local pext = packages_of(
			lp.module_requires_loadtime_ext, mod, pkg, platform)
		local pall = packages_of(
			lp.module_requires_loadtime_all, mod, pkg, platform)
		local penv = packages_of(
			lp.module_environment, mod, pkg, platform)
		glue.update(pext, filter(lp.bin_deps(pkg, platform),
			lp.module_platforms(mod, pkg)))
		glue.update(pall, filter(lp.bin_deps_all(pkg, platform),
			lp.module_platforms(mod, pkg)))
		glue.update(pall, penv)
		local pt = {}
		for p in pairs(pall) do
			pt[p] = {kind = pext[p] and 'direct' or penv[p] and 'environment' or 'indirect'}
		end
		pts[platform] = pt
	end
	return pts
end

local function module_runtime_package_dep_maps(pkg, mod, platforms)
	local pts = {}
	for platform in pairs(platforms) do
		local pdeps = packages_of(
			lp.module_requires_runtime, mod, pkg, platform)
		local pt = {}
		for p in pairs(pdeps) do
			pt[p] = {kind = 'direct'}
		end
		pts[platform] = pt
	end
	return pts
end

local function module_module_dep_maps(pkg, mod, platforms)
	local mts = {}
	local mint = lp.modules(pkg)
	for platform in pairs(platforms) do
		local mext = lp.module_requires_loadtime_ext(mod, pkg, platform)
		local mall = lp.module_requires_loadtime_all(mod, pkg, platform)
		local menv = lp.module_environment(mod, pkg, platform)
		glue.update(mall, menv)
		local mt = {}
		for m in pairs(mall) do
			local pkg = lp.module_package(m)
			local path = lp.modules(pkg)[m]
			mt[m] = {
				kind = mext[m] and 'external'
					or mint[m] and 'internal' or menv[m] and 'environment' or 'indirect',
				dep_package = pkg,
				dep_source_url = source_url(pkg, path, m),
			}
		end
		mts[platform] = mt
	end
	return mts
end

local function module_runtime_module_dep_maps(pkg, mod, platforms)
	local mts = {}
	local mint = lp.modules(pkg)
	for platform in pairs(platforms) do
		local mrun = lp.module_requires_runtime(mod, pkg, platform)
		local mt = {}
		for m in pairs(mrun) do
			local pkg = lp.module_package(m)
			local path = lp.modules(pkg)[m]
			mt[m] = {
				kind = 'external',
				dep_package = pkg,
				dep_source_url = source_url(pkg, path, m),
			}
		end
		mts[platform] = mt
	end
	return mts
end

local function package_dep_lists(pdeps)
	local t = {}
	for _,platform in ipairs(ext_platform_list) do
		local pdeps = pdeps[platform]
		if pdeps then
			local icon =
				platform ~= 'all'
				and platform ~= 'common'
				and platform or nil
			local text = not icon and platform or nil
			table.insert(t, {
				icon = icon,
				text = text,
				packages = pdep_list(pdeps),
			})
		end
	end
	return t
end

local function module_dep_lists(mdeps)
	local t = {}
	for _,platform in ipairs(ext_platform_list) do
		local mdeps = mdeps[platform]
		if mdeps then
			local icon =
				platform ~= 'all'
				and platform ~= 'common'
				and platform or nil
			local text = not icon and platform or nil
			table.insert(t, {
				icon = icon,
				text = text,
				modules = mdep_list(mdeps),
			})
		end
	end
	return t
end

local function package_dep_matrix(pdeps)
	local names = {}
	local icons = {}
	local depmat = {}

	for _,platform in ipairs(ext_platform_list) do
		local pmap = pdeps[platform]
		if pmap then
			table.insert(icons, platform)
			for pkg in pairs(pmap) do
				names[pkg] = true
			end
		end
	end
	local depmat_names = glue.keys(names, true)
	for i, icon in ipairs(icons) do
		depmat[i] = {
			pkg = {},
			text = icon == 'all' and icon or nil,
			icon = icon ~= 'all' and icon or nil,
		}
		for j, pkg in ipairs(depmat_names) do
			local pt = pdeps[icon][pkg]
			depmat[i].pkg[j] = {
				checked = pt ~= nil,
				kind = pt and pt.kind,
			}
		end
	end
	return depmat, depmat_names
end

local function package_note(pkg, note)
	--nothing to say.
end

local function package_info(pkg, doc)

	local t = {package = pkg}

	--gather info
	local package_type = lp.package_type(pkg)
	local platforms = lp.platforms(pkg)
	local all_platforms =
		next(platforms)
			and platforms
			or glue.update({}, lp.supported_platforms)
	local master_time = lp.git_master_time(pkg)
	local author = lp.author(pkg)
	local license = lp.license(pkg)
	local ctags = lp.what_tags(pkg) or {}
	local origin_url = lp.git_origin_url(pkg)
	local on_github = origin_url:find'github%.com'
	local git_version = lp.git_version(pkg)
	local git_tag = lp.git_tag(pkg)
	local released =
		git_tag
		and git_tag ~= ''
		and git_tag ~= 'dev' --tag "dev" is not a release
	local git_tags = lp.git_tags(pkg)
	local doc = doc or pkg
	local docs = lp.docs(pkg)
	local docheaders = lp.docheaders(pkg)
	local doc_path = docs[doc]
	if not doc_path and glue.count(docs) == 1 then
		doc = next(docs)
		doc_path = docs[doc]
	end
	local title = doc
	local tagline = lp.module_tagline(pkg, doc)
	if doc_path then
		local dtags = lp.doc_tags(pkg, doc)
		title = dtags.title
	end
	local package_cat = lp.package_cat(pkg)

	--top bar / github url
	t.origin_url = origin_url
	t.github_url = on_github and origin_url
	t.github_title = on_github and origin_url:gsub('^https://', '')

	--download / "Changes since..."
	t.git_tag = git_tag
	t.changes_url = released and on_github and
		string.format('%s/compare/%s...master', origin_url, git_tag)

	--download / releases
	t.git_tags = {}
	if released then
		for i,tag in ipairs(git_tags) do
			if tag == 'dev' then
				table.remove(git_tags, i)
				break
			end
		end
		for i=#git_tags,1,-1 do
			local tag = git_tags[i]
			local prevtag = git_tags[i-1]
			local mtime = lp.git_tag_time(pkg, tag)
			table.insert(t.git_tags, {
				tag = tag,
				time = format_date(mtime),
				reltime = timeago(mtime),
				changes_text = prevtag and 'Changes...' or 'Files...',
				changes_url = on_github and (prevtag
					and string.format('%s/compare/%s...%s',
						origin_url, prevtag, tag)
					or string.format('%s/tree/%s', origin_url, tag)),
			})
		end
	end
	t.has_git_tags = #t.git_tags > 0

	--package info / overview / supported platorms
	t.platforms = {}
	for i,p in ipairs(platform_list) do
		if platforms[p] then
			table.insert(t.platforms, {icon = p})
		end
	end
	if not next(t.platforms) then
		local runtime = package_type == 'Lua+ffi' and 'LuaJIT' or package_type
		table.insert(t.platforms,
			{name = runtime and 'all '..runtime..' platforms'})
	end

	--package info / docs
	--menubar / doc list
	t.docs = {}
	for name, path in glue.sortedpairs(docs) do
		table.insert(t.docs, {
			shortname = name:gsub('^'..glue.esc(pkg)..'[%._]', ''),
			name = name,
			path = path,
			source_url = source_url(pkg, path),
			selected = name == doc,
		})
	end

	--package info / docheaders
	for name, h in glue.sortedpairs(docheaders) do
		if h.doc then
			table.insert(t.docs, {
				name = name,
				shortname = name:gsub('^'..glue.esc(pkg)..'[%._]', ''),
				path = name,
				selected = name == doc,
			})
		end
	end

	t.has_docs = #t.docs > 0

	--doc page
	t.title = title or doc
	t.doc_path = doc_path
	t.tagline = tagline
	t.edit_link =
		on_github
		and doc_path
		and origin_url..'/edit/master/'..doc_path

	--sidebar
	t.icons = package_icons(package_type, platforms)
	t.type = package_type
	t.version = git_version
	t.mtime = format_time(master_time)
	t.mtime_ago = timeago(master_time)
	t.author = author
	t.license = license
	t.c_name =
		ctags.realname
		and ctags.realname ~= pkg
		and ctags.realname
		or nil
	t.c_version = ctags.version
	t.c_url = ctags.url

	--menubar / other packages in cat
	t.cats = {}
	for i,cat in ipairs(lp.cats()) do
		if cat.name == package_cat then
			local ct = {name = cat.name}
			table.insert(t.cats, ct)
			ct.packages = {}
			for i, package in ipairs(cat.packages) do
				table.insert(ct.packages, {
					package = package.name,
					selected = package.name == pkg,
					note = package_note(package.name, package.note),
				})
			end
		end
	end

	--package dependencies ----------------------------------------------------

	--combined package dependencies
	local pts = package_dep_maps(pkg, all_platforms)
	local pdeps = platform_maps(pts, 'common')
	t.package_deps = package_dep_lists(pdeps)
	t.has_package_deps = #t.package_deps > 0

	--combined package dependency matrix
	local pdeps_aot = platform_maps(pts, 'all', 'aot')
	t.depmat, t.depmat_names = package_dep_matrix(pdeps_aot)

	--package clone lists
	if not pdeps_aot.all then --make a combined list for all platforms
		local all = {}
		for platform, pts in pairs(pdeps_aot) do
			for package in pairs(pts) do
				all[package] = {}
			end
		end
		pdeps_aot.all = all
	end
	t.clone_lists = {}
	for _,platform in ipairs(ext_platform_list) do
		local pdeps = pdeps_aot[platform]
		if pdeps then
			local packages = {{dep_package = pkg}}
			local pdeps = pdep_list(pdeps)
			glue.extend(packages, pdeps)
			table.insert(t.clone_lists, {
				platform = platform,
				text = platform == 'all' and platform or nil,
				icon = platform ~= 'all' and platform or nil,
				is_unix = not platform:find'mingw',
				hidden = platform ~= 'all' and 'hidden' or nil,
				disabled = platform ~= 'all' and 'disabled' or nil,
				packages = packages,
			})
		end
	end

	--combined package reverse dependencies
	local pts = package_rev_dep_maps(pkg, all_platforms)
	local rpdeps = platform_maps(pts, 'common')
	t.package_rdeps = package_dep_lists(rpdeps)
	t.has_package_rdeps = #t.package_rdeps > 0

	--binary dependencies
	local pts = package_bin_dep_maps(pkg, all_platforms)
	local pdeps = platform_maps(pts, 'common')
	t.bin_deps = package_dep_lists(pdeps)
	t.has_bin_deps = #t.bin_deps > 0

	--build order
	local pts = {}
	for platform in pairs(all_platforms) do
		local bo = lp.build_order(pkg, platform)
		pts[platform] = {[tuple(unpack(bo))] = bo}
	end
	local bo = platform_maps(pts, 'all', 'aot')
	t.build_order = {}
	for _,platform in ipairs(ext_platform_list) do
		local bo = bo[platform]
		if bo then
			table.insert(t.build_order, {
				icon = platform ~= 'all' and platform,
				text = platform == 'all' and 'all',
				packages = {next(bo)()},
			})
		end
	end

	--module list -------------------------------------------------------------

	t.modules = {}
	for mod, path in glue.sortedpairs(lp.modules(pkg)) do
		local mt = {module = mod}
		table.insert(t.modules, mt)

		local mtags = lp.module_tags(pkg, mod)
		mt.lang = mtags.lang

		if type(path) == 'table' then
			mt.source_urls = {}
			for plat, path in pairs(path) do
				table.insert(mt.source_urls, {
					platform = plat,
					source_url = source_url(pkg, path, mod),
				})
			end
		else
			mt.source_url = source_url(pkg, path, mod)
		end

		local mplatforms = lp.module_platforms(mod, pkg)

		mt.icons = {}
		if tuple(unpack(glue.keys(mplatforms, true))) ~=
			tuple(unpack(glue.keys(all_platforms, true)))
		then
			mt.icons = platform_icons(mplatforms, true)
		end

		--loadtime package deps
		local pts = module_package_dep_maps(pkg, mod, all_platforms)
		local pdeps = platform_maps(pts, 'all')
		mt.package_deps = package_dep_lists(pdeps)

		--loadtime module deps
		local mts = module_module_dep_maps(pkg, mod, all_platforms)
		local mdeps = platform_maps(mts, 'all')
		mt.module_deps = module_dep_lists(mdeps)

		--runtime package deps
		local pts = module_runtime_package_dep_maps(pkg, mod, all_platforms)
		local pdeps = platform_maps(pts, 'all')
		mt.runtime_package_deps = package_dep_lists(pdeps)
		mt.module_has_runtime_deps = #mt.runtime_package_deps > 0
		t.has_runtime_deps = t.has_runtime_deps or mt.module_has_runtime_deps

		--runtime module deps
		local mts = module_runtime_module_dep_maps(pkg, mod, all_platforms)
		local mdeps = platform_maps(mts, 'all')
		mt.runtime_module_deps = module_dep_lists(mdeps)

		--autoloads
		local auto = {}
		for platform in pairs(all_platforms) do
			local autoloads = lp.module_autoloads(mod, pkg, platform)
			if next(autoloads) then
				for k, mod in pairs(autoloads) do
					glue.attr(auto, platform)[tuple(k, mod)] = true
				end
			end
		end
		auto = platform_maps(auto, 'all')
		mt.autoloads = {}
		local function autoload_list(platform, auto)
			local t = {}
			local function cmp(k1, k2) --sort by (module_name, key)
				local k1, mod1 = k1()
				local k2, mod2 = k2()
				if mod1 == mod2 then return k1 < k2 end
				return mod1 < mod2
			end
			for k in glue.sortedpairs(auto, cmp) do
				local k, mod = k()
				local pkg = lp.module_package(mod)
				local impl_path = pkg and lp.modules(pkg)[mod]
				table.insert(t, {
					platform ~= 'all' and platform,
					key = k,
					path = path,
					impl_module = mod,
					impl_path = impl_path,
				})
			end
			return t
		end
		for platform, auto in glue.sortedpairs(auto) do
			glue.extend(mt.autoloads, autoload_list(platform, auto))
		end
		mt.module_has_autoloads = #mt.autoloads > 0
		t.has_autoloads = t.has_autoloads or mt.module_has_autoloads

		--load errors
		local errs = {}
		for platform in pairs(lp.module_platforms(mod, pkg)) do
			local err = lp.module_load_error(mod, pkg, platform)
			if err then
				errs[platform] = {[err] = true}
			end
		end
		errs = platform_maps(errs, 'all')
		mt.load_errors = {}
		for platform, errs in pairs(errs) do
			table.insert(mt.load_errors, {
				icon = platform,
				errors = glue.keys(errs, true),
			})
		end
		mt.module_has_load_errors = #mt.load_errors > 0
		t.has_load_errors = t.has_load_errors or mt.module_has_load_errors
	end
	t.has_modules = glue.count(t.modules, 1) > 0

	--script list
	t.scripts = {}
	for mod, path in glue.sortedpairs(lp.scripts(pkg)) do
		local st = {}
		table.insert(t.scripts, st)

		st.module = mod
		st.path = path
		st.source_url = source_url(pkg, path, mod)

		local mts = glue.update({}, lp.module_requires_runtime(mod))
		local pts = {}
		for mod in pairs(mts) do
			local pkg = lp.module_package(mod)
			if pkg then
				pts[pkg] = true
			end
		end

		st.package_deps = glue.keys(pts, true)

		st.module_deps = {}
		for mod in glue.sortedpairs(mts) do
			local pkg = lp.module_package(mod)
			local path = lp.modules(pkg)[mod] or lp.scripts(pkg)[mod]
			table.insert(st.module_deps, {
				dep_module = mod,
				dep_source_url = source_url(pkg, path, mod),
			})
		end

	end
	t.has_scripts = #t.scripts > 0

	return t
end

local function action_package(pkg, doc, what)
	local t = package_info(pkg, doc)
	if what == 'info' then
		t.info = true
	elseif what == 'download' then
		t.download = true
	elseif what == 'cc' then
		action.clear_cache(pkg)
		return
	elseif not what then
		if t.doc_path then
			local path = lp.powerpath(t.doc_path)
			t.doc_html = render_docfile(path)

			--add any widgets
			local function getwidget(_, name)
				local widget = widgets[name]
				return widget and widget(pkg)
			end
			local view = setmetatable({}, {__index = getwidget})
			t.doc_html = render_string(t.doc_html, view)

			local mtime = lp.git_file_time(pkg, t.doc_path)
			if mtime then
				t.doc_mtime = format_date(mtime)
				t.doc_mtime_ago = timeago(mtime)
			end
		else
			local doc = doc or pkg
			local h = lp.docheaders()[doc]
			t.doc_html = h and render_docheader(pkg, doc, h)
		end
	end
	out(render_main('package', t))
end

local function load_errors()
	local t = {}
	for _,platform in ipairs(lp.supported_platform_list) do
		for pkg in glue.sortedpairs(lp.installed_packages()) do
			for mod in glue.sortedpairs(lp.modules(pkg)) do
				if lp.module_platforms(mod, pkg)[platform] then
					local err = lp.module_load_error(mod, pkg, platform)
					if err and not err:find'^could not create tracking environment' then
						t[#t+1] = {
							platform = platform,
							package = pkg,
							module = mod,
							error = err,
						}
					end
				end
			end
		end
	end
	return t
end

local function action_home()
	local data = {}

	local pt = {}
	data.packages = pt --{pkg:{type=, platforms=, ...},...}
	for pkg in glue.sortedpairs(lp.installed_packages()) do
		if lp.known_packages()[pkg] then --exclude "luapower-repos"
			local t = {name = pkg}
			t.type = lp.package_type(pkg)
			t.platforms = lp.platforms(pkg)
			t.icons, t.platform_string = package_icons(t.type, t.platforms, true)
			t.tagline = lp.module_tagline(pkg, pkg)
			local cat = lp.package_cat(pkg)
			t.cat = cat and cat.name
			t.version = lp.git_version(pkg)
			local mtime = lp.git_master_time(pkg)
			t.mtimestamp = mtime
			t.mtime = format_time(mtime)
			t.mtime_ago = timeago(mtime)
			t.license = lp.license(pkg)
			t.license_short = t.license:lower() == 'public domain' and 'P.D.' or t.license
			t.hot = math.abs(os.difftime(os.time(), mtime)) < 3600 * 24 * 7
			table.insert(pt, t)
		end
	end

	data.load_errors = load_errors()

	data.github_title = 'github.com/luapower'
	data.github_url = 'https://'..data.github_title

	local pkgmap = {}
	for _,pkg in ipairs(data.packages) do
		pkgmap[pkg.name] = pkg
	end
	data.cats = {}
	for i, cat in ipairs(lp.cats()) do
		local t = {}
		for i, pkg in ipairs(cat.packages) do
			local pt = pkgmap[pkg.name]
			pt.note = package_note(pkg.name, pkg.note)
			table.insert(t, pt)
		end
		table.insert(data.cats, {cat = cat.name, packages = t})
	end

	local file = config'www_dir'..'/../../files/luapower-all.zip'
	local size = fs.attr(file, 'size')
	local size = size and string.format('%d MB', size / 1024 / 1024) or '&nbsp;'
	data.all_download_size = size

	out(render_main('home', data))
end

--annotated tree -------------------------------------------------------------

local path_match = {

	'^luajit$', '<b class=important>LuaJIT loader for Linux and OSX<b>',
	'^luajit32$', '<b class=important>LuaJIT 32bit mode loader for Linux and OSX<b>',
	'^luajit.cmd$', '<b class=important>LuaJIT loader for Windows<b>',
	'^luajit32.cmd$', '<b class=important>LuaJIT 32bit loader for Windows<b>',

	'^MGIT_DIR/$', 'Multigit directory (contains all .git directories)',
	'^MGIT_DIR/([^/]+)/$', 'Contains the .git directory for package <b>{1}</b>',
	'^MGIT_DIR/([^/]+)/%.git/$', '.git directory for package <b>{1}</b>',
	'^MGIT_DIR/([^/]+)%.exclude$', 'Git ignore file for package <b>{1}</b>',
	'^MGIT_DIR/([^/]+)%.origin$', 'Multigit origin file for package <b>{1}</b>',
	'^MGIT_DIR/([^/]+).baseurl$', 'Multigit baseurl file for origin <b>{1}</b>',

	'^bin/$', 'All binaries for all packages & all platforms',
	'^bin/([^/]+)/$', 'All binaries compiled for <b>{1}</b>',

	'^bin/([^/]+)/luajit$', 'LuaJIT wrapper for <b>{1}</b>',
	'^bin/([^/]+)/luajit-bin$', 'LuaJIT executable for <b>{1}</b>',
	'^bin/([^/]+)/luajit.exe$', 'LuaJIT executable for <b>{1}</b>',

	'^bin/([^/]+)/clib/$', 'All Lua/C modules compiled for <b>{1}</b>',
	'^bin/([^/]+)/clib/(.-)%.a$', 'Lua/C module <b>{2}</b> compiled statically for <b>{1}</b>',
	'^bin/([^/]+)/clib/(.-)/$', 'Submodules of Lua/C module <b>{2}</b> compiled for <b>{1}</b>',
	'^bin/([^/]+)/clib/(.-)%.so$', 'Lua/C module <b>{2}</b> compiled dynamically for <b>{1}</b>',

	'^bin/([^/]+)/lib(.-)%.a$', 'C library <b>{2}</b> compiled statically for <b>{1}</b>',
	'^bin/([^/]+)/(.-)%.a$', 'C library <b>{2}</b> compiled statically for <b>{1}</b>',

	'^bin/([^/]+)/lib(.-)%.so$', 'C library <b>{2}</b> compiled dynamically for <b>{1}</b>',
	'^bin/([^/]+)/lib(.-)%.dylib$', 'C library <b>{2}</b> compiled dynamically for <b>{1}</b>',
	'^bin/([^/]+)/(.-)%.dll$', 'C library <b>{2}</b> compiled dynamically for <b>{1}</b>',

	'^bin/([^/]+)/.-/$', 'Some files needed for <b>PACKAGE</b>',
	'^bin/([^/]+)/', 'Some file needed for <b>PACKAGE</b>',

	'^csrc/$', 'All C source files and build scripts for all packages',
	'^csrc/(PACKAGE)/$', 'C sources & build scripts for <b>{1}</b>',
	'^csrc/(PACKAGE)/WHAT$', 'WHAT file for <b>{1}</b>',
	'^csrc/(PACKAGE)/LICENSE$', 'License file for <b>{1}</b>',
	'^csrc/(PACKAGE)/COPYING', 'License file for <b>{1}</b>',
	'^csrc/(PACKAGE)/build%-(.-)%.sh$', 'Build script for compiling <b>{1}</b> on <b>{2}</b>',
	'^csrc/(PACKAGE)/build.sh$', 'Build script for compiling <b>{1}</b> on all platforms',
	'^csrc/(PACKAGE)/.-%.[ch]$', 'C source file for <b>{1}</b>',
	'^csrc/(PACKAGE).-/$', 'Source files for <b>{1}</b>',
	'^csrc/(PACKAGE)', 'Some source file for <b>{1}</b>',

	'^media/$', 'All input data for tests and demos for all packages',

	'^media/.-/$', 'Data files for package <b>PACKAGE</b>',
	'^media/.-', 'Data file for package <b>PACKAGE</b>',
	'^media/.-/$', 'Some data files',
	'^media/.-', 'Some data file',

	'^([^%.]+)/$', 'Submodules of <b>{1}</b>',
	'(.-)_h%.lua$', 'FFI cdefs for <b>{1}</b>',
	'(.-)_test%.lua$', 'Test script for <b>{1}</b>',
	'(.-)_test%.t$', 'Test script for <b>{1}</b>',
	'(.-)_demo%.lua$', 'Demo app for <b>{1}</b>',
	'(.-)_demo%.t$', 'Demo app for <b>{1}</b>',
	'(.-)_app%.lua$', 'Lua app called <b>{1}</b>',
	'(.-)_app%.t$', 'Terra app called <b>{1}</b>',
	'(.-)%.lua$', 'Lua module <b>{1}</b>',
	'(.-)%.t$', 'Terra module <b>{1}</b>',
	'(.-)%.dasl$', 'Lua/DynASM module <b>{1}</b>',
	'(.-)%.md$', 'Documentation for <b>{1}</b>',
	'%.sh$', 'Some shell script needed for <b>PACKAGE</b>',

}

local function pass(format, ...)
	if not ... then return end
	local t = glue.pack(...)
	return format:gsub('{(%d)}', function(n)
		return t[tonumber(n)]:gsub('^csrc/', ''):gsub('/', '.')
	end)
end
local path_description = lp.memoize('path_description', function(path, package)
	for i=1,#path_match,2 do
		local patt, format = path_match[i], path_match[i+1]
		patt = patt:gsub('MGIT_DIR', lp.mgitpath())
		if patt:find'PACKAGE' then
			if package then
				patt = patt:gsub('PACKAGE', package)
			else
				goto skip
			end
		elseif format:find'PACKAGE' then
			if package then
				format = format:gsub('PACKAGE', package)
			else
				goto skip
			end
		end
		local s = pass(format, path:match(patt))
		if s then return s end
		::skip::
	end
end)

--recursive fs.dir()
local function ls_dir(p0, each)
	assert(p0)
	local function rec(p)
		local dp = p0 .. (p and '/' .. p or '')
		for f, d in fs.dir(dp) do
			local pf = p and p .. '/' .. f or f
			if each(f, pf, d:attr'type') and d:is'dir' then
				rec(pf)
			end
		end
		each(nil, nil, 'up')
	end
	rec()
end

local tree_json = lp.memoize('tree_json', function()
	local root = {
		file = 'luapower',
		descr = 'The luapower tree',
		files = {},
		dir = false,
		path = '/',
	}

	local mod_paths = glue.index(lp.modules())

	--list all files and dirs recursively and add info to tracked files.
	local dir = root
	ls_dir(lp.powerpath(), function(filename, path, ftype)
		if ftype == 'up' then
			dir = dir.dir
		elseif path:find'^%.mgit/[^/]+/%.git/' then --skip this huge dir
		elseif ftype == 'dir' then
			if not (
				path:find'^csrc/[^/]+/[^/]+'
				or path:find'^%.git'
			) then --don't dive in here
				local node = {file = filename, dir = dir, files = {},
					path = path..'/'}
				table.insert(dir.files, node)
				dir = node
				return true --recurse
			end
		else
			local node = {file = filename, dir = dir, path = path}
			node.package = lp.tracked_files()[path]
			node.type = lp.file_types()[path]
			local mod = mod_paths[path]
			if mod then
				node.title = lp.module_tagline(node.package, mod)
			end
			table.insert(dir.files, node)
		end
	end)

	--recursive node iterator (depth-first)
	local function rec(node, each)
		if node.files then
			for i, node in ipairs(node.files) do
				rec(node, each)
			end
		end
		each(node)
	end

	--sort files in each folder by name, with subfolders first
	--also remove the dir key to avoid recursion when serializing.
	--also set package if all the files inside are of the same package.
	--also set package=true for dirs containing files from multiple packages.
	--also set show_package flag for grouping by package.
	local function cmp(node1, node2)
		local is_dir1 = node1.files and true
		local is_dir2 = node2.files and true
		if is_dir1 == is_dir2 then --both dirs or files, compare their names
			return node1.file < node2.file
		else
			return is_dir1 --dirs come first
		end
	end
	rec(root, function(node)
		node.dir = nil
		if not node.files then --not a dir
			return
		end
		table.sort(node.files, cmp)
		local p0
		for i=1,#node.files do
			local p1 = node.files[i].package
			if p1 and p0 and p1 ~= p0 then
				node.package = true --contains multiple packages
				break
			elseif p1 and not p0 then
				p0 = p1
				node.package = p1
			end
		end
		if node.package then
			local p0
			for i=1,#node.files do
				local file = node.files[i]
				local p1 = file.package
				if p1 and p1 ~= p0 then
					file.show_package = true
					p0 = p1
				end
			end
		end
	end)

	rec(root, function(node)
		local package = node.package ~= true and node.package or nil
		node.descr = path_description(node.path, package)
		node.path = nil
	end)

	return json(root)
end)

action['tree.json'] = function()
	setmime'json'
	out(tree_json())
end

function action.tree()
	out(render_main('tree', {}))
end

--status page ----------------------------------------------------------------

function action.status()
	local statuses = {}
	for platform, server in glue.sortedpairs(lp.servers) do
		local ip, port = unpack(server)
		local t = {platform = platform, ip = ip, port = port}
		local rlp, err = lp.connect(platform, nil, connect)
		t.status = rlp and 'up' or 'down'
		t.error = err and err:match'^.-:.-: ([^\n]+)'
		if rlp then
			t.os, t.arch = rlp.osarch()
			t.installed_package_count = glue.count(rlp.installed_packages())
			t.known_package_count = glue.count(rlp.known_packages())
			t.load_errors = {}
			for mod, err in glue.sortedpairs(lp.load_errors(nil, platform)) do
				table.insert(t.load_errors, {
					module = mod,
					error = err,
				})
			end
			t.load_error_count = #t.load_errors
		end
		table.insert(statuses, t)
	end
	out(render_main('status', {statuses = statuses}))
end

--grepping through the source code and documentation -------------------------

local function filelines(file)
	local t = {}
	for line in io.lines(lp.powerpath(file)) do --most time is wasted here!
		t[#t+1] = line
	end
	return t
end

local function grepfile(s0, file, maxmatches)
	local lines = filelines(file)

	--record matches
	local matches = {}
	local limited = false
	for line, s in ipairs(lines) do
		local col0 = 1
		while true do
			if #matches >= (maxmatches or 1/0) then
				limited = true
				break
			end
			local col = s:find(s0, col0, true)
			if not col then break end
			table.insert(matches, {line = line, col = col})
			col0 = col + #s0
		end
		if limited then break end
	end

	--combine matches that are close together in chunks
	local chunks = {}
	local lastchunk, lastline
	for i,match in ipairs(matches) do
		local line = match.line
		local chunk
		if lastline and line - lastline < 10 then
			chunk = lastchunk
		else
			chunk = {line1 = line}
			table.insert(chunks, chunk)
		end
		chunk.line2 = line
		table.insert(chunk, match)
		lastline = line
		lastchunk = chunk
	end

	--create the text fragments
	for i,chunk in ipairs(chunks) do
		local line1 = glue.clamp(chunk.line1 - 2, 1, #lines)
		local line2 = glue.clamp(chunk.line2 + 2, 1, #lines)
		local dt = {}
		for line = line1, line2 do
			local col0 = 1
			local s = lines[line]
			local t = {}
			for _, match in ipairs(chunk) do
				if match.line == line then
					local col = match.col
					local s1 = s:sub(col0, col - 1)
					table.insert(t, {s = s1})
					table.insert(t, {hl = s0})
					col0 = col + #s0
				end
			end
			local s1 = s:sub(col0)
			table.insert(t, {s = s1})
			table.insert(dt, {line = line, fragments = t})
		end
		chunk.text = dt
		chunk.line1 = line1
		chunk.line2 = line2
	end

	return {matchcount = #matches, limited = limited, chunks = chunks}
end

local function grep(s0, maxmatches)
	local t = {}
	local dn, mn, fn, n = 0, 0, 0, 0
	local limited
	if s0 and s0 ~= '' then
		for pkg in pairs(lp.installed_packages()) do
			for doc, file in pairs(lp.docs(pkg)) do
				local res = grepfile(s0, file, maxmatches)
				dn = dn + 1
				n = n + res.matchcount
				if res.matchcount > 0 then
					fn = fn + 1
					limited = limited or res.limited
					table.insert(t, glue.update({
						package = pkg,
						file = file,
					}, res))
				end
			end
			for mod, file in pairs(lp.modules(pkg)) do
				--exclude built-in modules and binary files
				if file ~= true and lp.module_tags(pkg, mod).lang ~= 'C' then
					file = tostring(file)
					local res = grepfile(s0, file, maxmatches)
					mn = mn + 1
					n = n + res.matchcount
					if res.matchcount > 0 then
						fn = fn + 1
						limited = limited or res.limited
						table.insert(t, glue.update({
							package = pkg, file = file,
						}, res))
					end
				end
			end
		end
	end
	table.sort(t, function(t1, t2) return t1.matchcount > t2.matchcount end)
	return {
		results = t,
		docs_searched = dn,
		modules_searched = mn,
		file_matchcount = fn,
		matchcount = n,
		matchcount_limited = limited,
	}
end

local disallow = glue.index{'{}', '()', '))', '}}', '==', '[[', ']]', '--'}
function action.grep(s)
	local results = {search = s}
	if not s or #glue.trim(s) < 2 or disallow[s] then
		results.message = 'Type two or more non-space characters and not '..
			table.concat(glue.keys(disallow), ', ')..'.'
	else
		sleep(1) --sorry about this
		glue.update(results, grep(s, 10))
		results.title = 'grepping for '..(s or '')
		results.message = #results.results > 0 and '' or 'Nothing found.'
		results.searched = true
	end
	out(render_main('grep', results))
end

--update via github ----------------------------------------------------------

function action.github(repo)
	--if not method'post' then return end
	repo = check(post'repository' and post'repository'.name or repo)
	check(lp.installed_packages()[repo])
	lp.git(repo, 'pull') --TODO: this is blocking the server!!!
	lp.git(repo, 'pull --tags') --TODO: this is blocking the server!!!
	lp.clear_cache(repo)
	print'ok'
end

--clearing the cache and updating the deps db --------------------------------

function action.clear_cache(package)
	setmime'txt'
	lp.clear_cache(package)
	lp.unload_db()
	out('cache cleared for '..(package or 'all')..'\n')
end

function action.update_db(package)
	action.clear_cache(package)
	lp.update_db(package)
	lp.save_db()
	out'db updated and saved\n'
end

--creating rockspecs ---------------------------------------------------------

local function action_rockspec(pkg)
	pkg = pkg:match'^luapower%-([%w_]+)'
	local dtags = lp.doc_tags(pkg, pkg)
	local tagline = lp.module_tagline(pkg, pkg)
	local homepage = 'http://luapower.com/'..pkg
	local license = lp.license(pkg)
	local pext = package_deps(lp.module_requires_loadtime_ext, pkg, platform)
	local deps = {}
	for pkg in glue.sortedpairs(pext) do
		table.insert(deps, 'luapower-'..pkg)
	end
	local plat = {}
	local plats = {
		mingw64 = 'windows',
		linux64 = 'linux',
		osx64 = 'macosx',
	}
	for pl in pairs(lp.platforms(pkg)) do
		plat[plats[pl]] = true
	end
	plat = next(plat) and glue.keys(plat, true) or nil
	local ver = lp.git_version(pkg)
	local maj, min = ver:match('^([^%-]+)%-([^%-]+)')
	if maj then
		maj = maj:gsub('[^%d]', '')
		min = min:gsub('[^%d]', '')
		ver = '0.'..maj..'-'..min
	end
	local lua_modules = {}
	local luac_modules = {}
	for mod, path in pairs(lp.modules(pkg)) do
		local mtags = lp.module_tags(pkg,	 mod)
		if mtags.lang == 'C' then
			luac_modules[mod] = path
		elseif mtags.lang == 'Lua' or mtags.lang == 'Lua/ASM' then
			lua_modules[mod] = path
		end
	end
	local t = {
		package = 'luapower-'..pkg,
		supported_platforms = plat,
		version = ver,
		source = {
			url = lp.git_origin_url(pkg),
		},
		description = {
			summary = tagline,
			homepage = homepage,
			license = license,
		},
		dependencies = deps,
		build = {
			type = 'none',
			install = {
				lua = lua_modules,
				lib = luac_modules,
			},
		},
		--copy_directories = {},
	}
	setmime'txt'
	for k,v in glue.sortedpairs(t) do
		out(k)
		out' = '
		out(pp.format(v, '   '))
		out'\n'
	end
end

--action dispatch ------------------------------------------------------------

local function default_action(s, ...)
	local hs = s and s:match'^(.-)%.html$' or s
	if not s or s == '' then
		return action_home()
	elseif lp.installed_packages()[hs] then
		return action_package(hs, nil, ...)
	elseif lp.docs()[hs] then
		local pkg = lp.doc_package(hs)
		return action_package(pkg, hs, ...)
	elseif lp.docheaders()[hs] then
		local pkg = lp.module_package(hs)
		return action_package(pkg, hs, ...)
	elseif s:find'%.rockspec$' then
		local pkg = s:match'^(.-)%.rockspec$'
		if lp.installed_packages()[pkg] then
			return action_rockspec(pkg)
		end
	else
		if www_docfile(hs) then
			return action_docfile(hs, ...)
		end
	end
	http_error(404, 'Not found')
end

--webb_nginx module ----------------------------------------------------------

local M = {}

function M.respond()
	local act = args()[1]
	local action = act and action[act]
	local action_ = action or default_action
	action_(unpack(args(), action and 2 or 1))
end

return M
