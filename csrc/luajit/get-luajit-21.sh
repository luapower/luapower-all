[ -d src ] || git clone https://github.com/LuaJIT/LuaJIT src
(cd src && git checkout -f v2.1 && git pull)
(cd src/src && patch < ../../luaconf.h.patch)
(cd src/src && patch < ../../luajit.c.patch)
