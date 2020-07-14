@pushd "%~dp0"
@call nginx -c donut-studio-nginx.conf %*

@popd
