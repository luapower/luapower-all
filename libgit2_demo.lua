local pkg = ...
local git = require'libgit2'
local pp = require'pp'
local lfs = require'lfs'
print(git.version())

local pwd = lfs.currentdir()
lfs.chdir'../../../luapower'

local repo = git.open('.git') --git.open('.mgit/'..(pkg or 'glue')..'/.git')

pp(repo:tags())
pp(repo:refs())

print('system config', git.config_find_system())
print('xdg config',    git.config_find_xdg())
print('global config', git.config_find_global())

local cfg = repo:config()
for k,v,l in cfg:entries() do
	print(string.format('%-40s %s %d', k, v, tonumber(l)))
end
print(cfg:get'xxx')
cfg:free()

local ref = repo:ref_dwim'master'
local id = repo:ref_name_to_id(ref:name())
local commit = repo:commit(id)
print('last commit', id:tostring())
print('commit time', os.date('%c', commit:time()))
local tree = commit:tree()
for path in repo:files(tree) do
	print('', path)
end

tree:free()
commit:free()
ref:free()
repo:free()

lfs.chdir(pwd)
