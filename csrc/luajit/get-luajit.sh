[ -d src ] || git clone https://github.com/openresty/luajit2 src
(cd src && git checkout -f v2.1-agentzh && git pull)

# make LUA_PATH_DEFAULT and LUA_CPATH_DEFAULT overridable with -D gcc option.
(cd src/src && patch < ../../luaconf.h.patch)

# call require('terra') before running a *.t file
(cd src/src && patch < ../../luajit.c.patch)

# implement the `!` symbol in LUA_(C)PATH for Linux and OSX.
(cd src/src && patch < ../../lib_package.c.patch)
