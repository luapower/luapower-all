
--libgi2 ffi binding (incomplete).
--Written by Cosmin Apreutesei. Public Domain.

require'libgit2_h'
local ffi = require'ffi'
local C = ffi.load'git2'
local git = {C = C}
local glue = require'glue'

--helpers

local function nilerr(ret)
	if ret >= 0 then return ret end
	local e = C.giterr_last()
	return nil, string.format('libgit2 error: %d/%d: %s',
		ret, e.klass, ffi.string(e.message))
end

local function check(ret)
	if ret >= 0 then return ret end
	local e = C.giterr_last()
	error(string.format('libgit2 error: %d/%d: %s',
		ret, e.klass, ffi.string(e.message)))
end

local function checkh(ret)
	if ret ~= nil then return ret end
	local e = C.giterr_last()
	error(string.format('libgit2 error: %d/%d: %s',
		ret, e.klass, ffi.string(e.message)))
end

local function strarray_to_table(sa)
	local t = {}
	for i = 1, tonumber(sa.count) do
		t[i] = ffi.string(sa.strings[i-1])
	end
	return t
end

--procedural API

git.GIT_OID_RAWSZ = 20
git.GIT_OID_HEXSZ = git.GIT_OID_RAWSZ * 2

function git.version()
	local v = ffi.new'int[3]'
	C.git_libgit2_version(v, v+1, v+2)
	return v[0], v[1], v[2]
end

function git.buf(size)
	return ffi.new'git_buf'
end

git.buf_free = C.git_buf_free

function git.buf_tostr(buf)
	return ffi.string(buf.ptr, buf.size)
end

function git.oid(s)
	if type(s) ~= 'string' then return s end
	local oid = ffi.new'git_oid'
	check(C.git_oid_fromstr(oid, s))
	return oid
end

function git.oid_tostr(oid)
	local out = ffi.new('char[?]', git.GIT_OID_HEXSZ+1)
	C.git_oid_tostr(out, git.GIT_OID_HEXSZ+1, oid)
	return ffi.string(out, sz)
end

function git.open(path, flags, ceiling_dirs)
	local repo = ffi.new'git_repository*[1]'
	check(C.git_repository_open_ext(repo, path, flags or 0, ceiling_dirs))
	repo = repo[0]
	ffi.gc(repo, C.git_repository_free)
	return repo
end

function git.repo_free(repo)
	ffi.gc(repo, nil)
	C.git_repository_free(repo)
end

function git.tags(repo)
	local tags = ffi.new'git_strarray'
	check(C.git_tag_list(tags, repo))
	return strarray_to_table(tags)
end

function git.tag(repo, oid)
	oid = oid or git.oid(oid)
	local tag = ffi.new'git_tag*[1]'
	check(C.git_tag_lookup(tag, repo, oid))
	tag = tag[0]
	ffi.gc(tag, C.git_tag_free)
	return tag
end

function git.tag_free(tag)
	ffi.gc(tag, nil)
	C.git_tag_free(tag)
end

local function describe_opts(opts)
	return ffi.new('git_describe_options',
		glue.update({version = 1, max_candidates_tags = 10}, opts))
end

local function describe_format(res, opts)
	local opts = ffi.new('git_describe_format_options',
		glue.update({version = 1, abbreviated_size = 7}, opts))
	local buf = git.buf()
	check(C.git_describe_format(buf, res[0], opts))
	local s = buf:tostring()
	buf:free()
	return s
end

function git.describe_commit(commit_obj, opts)
	local res = ffi.new'git_describe_result*[1]'
	check(C.git_describe_commit(res, commit_obj, describe_opts(opts)))
	local s = describe_format(res, opts)
	C.git_describe_result_free(res[0])
	return s
end

function git.describe_workdir(repo, opts)
	local res = ffi.new'git_describe_result*[1]'
	check(C.git_describe_workdir(res, repo, describe_opts(opts)))
	local s = describe_format(res, opts)
	C.git_describe_result_free(res[0])
	return s
end

local object_types = {commit = C.GIT_OBJ_COMMIT, tree = C.GIT_OBJ_TREE,
	blob = C.GIT_OBJ_BLOB, tag = C.GIT_OBJ_TAG}
function git.object(repo, oid, type)
	oid = oid or git.oid(oid)
	local obj = ffi.new'git_object*[1]'
	check(C.git_object_lookup(obj, repo, oid, object_types[type] or type))
	obj = obj[0]
	ffi.gc(obj, C.git_object_free)
	return obj
end

function git.object_free(obj)
	ffi.gc(obj, nil)
	C.git_object_free(obj)
end

local function getref(func)
	return function(...)
		local ref = ffi.new'git_reference*[1]'
		check(func(ref, ...))
		ref = ref[0]
		ffi.gc(ref, C.git_reference_free)
		return ref
	end
end

git.ref = getref(C.git_reference_lookup)
git.ref_dwim = getref(C.git_reference_dwim)

function git.ref_name_to_id(repo, name)
	local oid = ffi.new'git_oid'
	check(C.git_reference_name_to_id(oid, repo, name))
	return oid
end

function git.ref_name(ref)
	return ffi.string(checkh(C.git_reference_name(ref)))
end

function git.ref_free(ref)
	ffi.gc(ref, nil)
	C.git_reference_free(ref)
end

function git.refs(repo)
	local refs = ffi.new'git_strarray'
	check(C.git_reference_list(refs, repo))
	return strarray_to_table(refs)
end

function git.commit(repo, oid)
	oid = git.oid(oid)
	local commit = ffi.new'git_commit*[1]'
	check(C.git_commit_lookup(commit, repo, oid))
	commit = commit[0]
	ffi.gc(commit, C.git_commit_free)
	return commit
end

function git.commit_free(commit)
	ffi.gc(commit, nil)
	C.git_commit_free(commit)
end

function git.commit_tree(commit)
	local tree = ffi.new'git_tree*[1]'
	check(C.git_commit_tree(tree, commit))
	tree = tree[0]
	ffi.gc(tree, C.git_tree_free)
	return tree
end

function git.commit_time(commit)
	return tonumber(C.git_commit_time(commit))
end

function git.tree(repo, oid)
	local tree = ffi.new'git_tree*[1]'
	check(C.git_tree_lookup(tree, repo, oid))
	tree = tree[0]
	ffi.gc(tree, C.git_tree_free)
	return tree
end

function git.tree_free(tree)
	ffi.gc(tree, nil)
	C.git_tree_free(tree)
end

function git.tree_entrycount(tree)
	return tonumber(check(C.git_tree_entrycount(tree)))
end

function git.tree_entry_byindex(tree, i)
	return checkh(C.git_tree_entry_byindex(tree, i))
end

function git.tree_walk(repo, tree, func, level)
	level = level or 0
	for i = 0, tree:count()-1 do
		local entry = tree:byindex(i)
		func(entry, tree, level)
		if entry:type() == C.GIT_OBJ_TREE then
 			local subtree = repo:tree(entry:id())
 			git.tree_walk(repo, subtree, func, level + 1)
 			subtree:free()
		end
	end
end

function git.files(repo, tree)
	local level0, name0 = 0
	local parents = {}
	return coroutine.wrap(function()
		git.tree_walk(repo, tree, function(entry, tree, level)
				local name = entry:name()
				if level > level0 then
					table.insert(parents, name0)
				elseif level < level0 then
					for i = 1, level0 - level do
						table.remove(parents)
					end
				end
				table.insert(parents, name)
				local path = table.concat(parents, '/')
				table.remove(parents)
				coroutine.yield(path)
				level0, name0 = level, name
			end)
	end)
end

git.tree_entry_type = C.git_tree_entry_type

function git.tree_entry_name(entry)
	return ffi.string(C.git_tree_entry_name(entry))
end

git.tree_entry_id = C.git_tree_entry_id

local function findconfig(func)
	return function()
		local buf = git.buf()
		local ret, err = nilerr(func(buf))
		if not ret then return nil, err end
		local s = buf:tostring()
		buf:free()
		return s
	end
end
git.config_find_global = findconfig(C.git_config_find_global)
git.config_find_xdg    = findconfig(C.git_config_find_xdg)
git.config_find_system = findconfig(C.git_config_find_system)

local function getconfig(func)
	return function(...)
		local cfg = ffi.new'git_config*[1]'
		check(func(cfg, ...))
		cfg = cfg[0]
		ffi.gc(cfg, C.git_config_free)
		return cfg
	end
end

git.config_open_default = getconfig(C.git_config_open_default)
git.repo_config = getconfig(C.git_repository_config)

function git.config_free(cfg)
	ffi.gc(cfg, nil)
	C.git_config_free(cfg)
end

function git.config_get(cfg, name)
	local entry = ffi.new'const git_config_entry*[1]'
	local ret = C.git_config_get_entry(entry, cfg, name)
	if ret < 0 then return end
	return ffi.string(entry[0].value), entry[0].level
end

function git.config_set(cfg, name, val)
	local entry = ffi.new'git_config_entry'
	check(C.git_config_set_string(entry, cfg, name, val))
end

function git.config_entries(cfg)
	return coroutine.wrap(function()
		local iter = ffi.new'git_config_iterator*[1]'
		local entry = ffi.new'git_config_entry*[1]'
		C.git_config_iterator_new(iter, cfg)
		iter = iter[0]
		while C.git_config_next(entry, iter) == 0 do
			coroutine.yield(
				ffi.string(entry[0].name),
				ffi.string(entry[0].value),
				entry[0].level)
		end
		C.git_config_iterator_free(iter)
	end)
end


--object API

ffi.metatype('git_buf', {__index = {
		free = git.buf_free,
		tostring = git.buf_tostr,
	}})

ffi.metatype('git_oid', {__index = {
		tostring = git.oid_tostr,
	}})

ffi.metatype('git_repository', {__index = {
		free = git.repo_free,
		tags = git.tags,
		commit = git.commit,
		tag = git.tag,
		tree = git.tree,
		ref = git.ref,
		object = git.object,
		ref_dwim = git.ref_dwim,
		ref_name_to_id = git.ref_name_to_id,
		refs = git.refs,
		tree_walk = git.tree_walk,
		files = git.files,
		config = git.repo_config,
		describe = git.describe_workdir,
	}})

ffi.metatype('git_object', {__index = {
		free = git.object_free,
		describe_commit = git.describe_commit,
	}})

ffi.metatype('git_tag', {__index = {
		free = git.tag_free,
	}})

ffi.metatype('git_reference', {__index = {
		free = git.ref_free,
		name = git.ref_name,
	}})

ffi.metatype('git_commit', {__index = {
		free = git.commit_free,
		tree = git.commit_tree,
		time = git.commit_time,
	}})

ffi.metatype('git_tree', {__index = {
		free = git.tree_free,
		count = git.tree_entrycount,
		byindex = git.tree_entry_byindex,
	}})

ffi.metatype('git_tree_entry', {__index = {
		type = git.tree_entry_type,
		name = git.tree_entry_name,
		id   = git.tree_entry_id,
	}})

ffi.metatype('git_config', {__index = {
		free = git.config_free,
		get  = git.config_get,
		set  = git.config_set,
		entries = git.config_entries,
	}})


return git

