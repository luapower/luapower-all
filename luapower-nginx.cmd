@pushd "%~dp0"
@call nginx -c luapower-nginx.conf %*

@popd
