
--db update API.

setfenv(1, require'app')

local function load_luapower()
	package.loaded.luapower = nil
	local luapower = require'luapower'
	luapower.config('luapower_dir', config'luapower_dir')
	return luapower
end

local function update_package_platform(lp, package, platform)
	local lp, err = lp.connect(platform, nil, connect)
	if not lp then print(err) return end

	local t = lp.exec(function(pkg)

		local lp = require'luapower'
		local glue = require'glue'
		local t = {}

		--[[
		t.package_deps = {}
		local pkgext = lp.package_requires_packages_ext(pkg)
		for pkg in pairs(lp.package_requires_packages_all(pkg)) do
			t.package_deps[pkg] = pkgext[pkg] and 'external' or 'indirect'
		end

		t.package_rdeps = lp.package_required_packages_all(pkg)

		t.modmap = {}
		local modules = lp.modules(pkg)
		for mod, file in pairs(modules) do
			local mt = {}
			mt.load_error = lp.module_load_error(mod, pkg)
			mt.module_deps = {}
			mt.package_deps = {}

			if not mt.load_error then
				local pkgext = lp.module_requires_packages_ext(mod, pkg)
				for pkg in pairs(lp.module_requires_packages_all(mod, pkg)) do
					local kind = pkgext[pkg] and 'external' or 'indirect'
					mt.package_deps[pkg] = {
						kind = kind,
					}
				end
				local modext = lp.module_requires_loadtime_ext(mod, pkg)
				local modrun = lp.module_requires_runtime(mod, pkg)
				for mod in pairs(lp.module_requires_loadtime_all(mod, pkg)) do
					local kind = modext[mod] and 'external' or modules[mod]
						and 'internal' or 'indirect'
					local pkg = lp.module_package(mod)
					local file = pkg and lp.modules(pkg)[mod]
					mt.module_deps[mod] = {
						kind = kind,
						dep_package = pkg,
						dep_file = file,
					}
				end
			end

			mt.autoloads = lp.module_autoloads(mod)

			t.modmap[mod] = mt
		end
		]]

		return t

	end, pkg)
	lp.close()

	--query('update package ')
end

local function update_package(pkg)
	local lp = load_luapower()
	local lp.

	query([[
		insert into package
			(origin_url, )
		values
			(?, ?, )
		on duplicate key update
			origin_url = ?,
			csrc_dir = ?,
			cat = ?,
			pos = ?,
			last_commit = ?,
			type = ?
	]], pkg)


	for platform in pairs(lp.config'servers') do
		--update_package_platform(lp, package, platform)
	end
end

local function update_packages()
	load_luapower()
	for pkg in pairs(lp.installed_packages()) do
		update_package(pkg)
	end
end

return {
	update_package = update_package,
	update_packages = update_packages,
}
