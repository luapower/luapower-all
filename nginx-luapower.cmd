@pushd "%~dp0"
@call nginx -c nginx-luapower.conf %*

@popd
