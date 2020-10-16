@pushd "%~dp0"
@call nginx -c nginx-allegory.conf %*

@popd
