@pushd "%~dp0"
@call nginx -c luamyadmin-nginx.conf %*

@popd
