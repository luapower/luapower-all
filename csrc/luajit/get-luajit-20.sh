[ -d src ] || git clone https://github.com/LuaJIT/LuaJIT src
(cd src && git checkout -f master && git pull)
(cd src/src && patch < ../../luaconf.h.patch)
