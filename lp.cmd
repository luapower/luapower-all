@pushd "%~dp0"
@call luajit luapower_cli.lua %*
@popd
