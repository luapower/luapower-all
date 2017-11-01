@pushd "%~dp0"
@call luajit32 luapower_cli.lua %*
@popd
