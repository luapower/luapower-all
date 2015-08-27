---
tagline: libgit2 ffi binding
platforms: osx32, osx64
---

## `git = require'libgit2'`

libgit2 ffi binding -- only the basics of repository exploration are covered.

Feel free to improve it, it's a pretty boring API.

> NOTE: libgit2 dropped support for Windows XP.

## API

------------------------------------------------- ----------------------------
__buffers__
git.buf() -> buf                                  make an empty git_buf
buf:free()                                        empty out the buffer
buf:tostring() -> s                               buf contents as string
__oids__
git.oid(str) -> oid                               id by sha string
oid:tostring() -> str                             id's sha string
__repos__
git.open(path, [flags], [ceiling_dirs]) -> repo   open repo
repo:free()                                       free repo
__tags__
repo:tags() -> {tagname1, ...}                    tag names
__refs__
repo:refs() -> {refname1, ...}                    ref names
repo:ref_lookup(name) -> ref                      ref lookup
repo:ref_dwim(shortname) -> ref                   ref lookup by short name
repo:ref_name_to_id(name) -> oid                  ref id
ref:free()                                        free ref
ref:name() -> s
__commits__
repo:commit(oid) -> commit                        get a commit
commit:free()                                     free commit
commit:time() -> time                             commit time (in os.time() format)
__trees__
repo:tree_lookup(oid) -> tree                     get any tree
commit:tree() -> tree                             get a commit's file tree
tree:count() -> n                                 entry count of tree
tree:byindex(i) -> entry                          entry by index
entry:type() -> git.GIT_OBJ_*                     entry type
entry:name() -> s                                 entry name
entry:id() -> oid                                 entry id
repo:tree_walk(tree,func)->func(entry,tree,level) tree walker
repo:files(tree) -> iter() -> pathname            iterate files (depth first)
__config__
git.config_find_global() -> path | nil,err        global config path
git.config_find_xdg() -> path | nil,err           xdg config path
git.config_find_system() -> path | nil,err        system config path
git.config_open_default() -> cfg | nil,err        open the default config
repo:config() -> cfg                              open a repo's config
cfg:free()                                        free config
cfg:get(key) -> value, level                      get a config value (nil if missing)
cfg:set(key, value)                               set a config value
cfg:entries() -> iter() -> key, val, level        iterate config values
__library__
git.version() -> maj, min, build                  libgit2 version
------------------------------------------------- ----------------------------
