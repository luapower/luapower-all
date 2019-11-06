---
tagline: Nginx server with lua-nginx-module.
---

## What is this?

This is the nginx server built with
[lua-nginx-module](https://github.com/openresty/lua-nginx-module)
i.e. OpenResty core.

Unlike standard Nginx or OpenResty binaries, this build links dynamically
to its dependencies which are provided as separate packages so you must
get them too for nginx to run.

Other OpenResty modules are provided as separate packages as well.

## HowTo

Like with [LuaJIT], a wrapper script is provided to run the right nginx
binary for the platform you're on. The nginx `prefix` directory is `.`
(i.e. the current directory) which, if you use the wrapper script, is the
directory of the script itself i.e. the luapower directory. `nginx.conf`
is also searched for in here (eg. see [webb]), logs go in `logs` and temp
files go in `tmp`.

Consult the build scripts for more info on how this was built.
