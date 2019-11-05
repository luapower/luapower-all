n=1.17.4
[ -d src ] && exit
git clone https://github.com/nginx/nginx src --depth 1
cd src || exit
git checkout -b $n
git apply ../*.patch
