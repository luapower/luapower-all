n=1.17.4
[ -d src ]       || git clone https://github.com/nginx/nginx --depth 1 --branch release-$n src
[ -d openresty ] || git clone https://github.com/openresty/openresty --depth 1
(cd openresty && git reset --hard)
cd src || exit 1
git reset --hard release-$n
git apply ../*.patch
cat ../openresty/patches/nginx-1.17.4-ssl_*.patch | patch -N -p1
