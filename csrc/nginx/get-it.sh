NGINX=release-1.17.4
NGX_DEVEL_KIT=v0.3.1
LUA_NGINX_MODULE=v0.10.15

[ -d src       ] || git clone https://github.com/nginx/nginx                --depth 1 --branch $NGINX src
[ -d openresty ] || git clone https://github.com/openresty/openresty        --depth 1
[ -d ndk       ] || git clone https://github.com/simplresty/ngx_devel_kit   --depth 1 --branch $NGX_DEVEL_KIT ndk
[ -d lua       ] || git clone https://github.com/openresty/lua-nginx-module --depth 1 --branch $LUA_NGINX_MODULE lua

(cd src && {
	git reset --hard $NGINX
	git apply ../src-*.patch
	cat ../openresty/patches/nginx-1.17.4-ssl_*.patch | patch -N -p1
})
(cd openresty && git reset --hard)
(cd ndk && git reset --hard $NGX_DEVEL_KIT)
(cd lua && {
    git reset --hard $LUA_NGINX_MODULE
    git apply ../lua-*.patch
})
