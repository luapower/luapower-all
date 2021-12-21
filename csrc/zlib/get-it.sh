n=1.2.11
wget -q -nc https://www.zlib.net/zlib-$n.tar.gz
tar xvfz zlib-$n.tar.gz
cd zlib-$n
cp -f *.c ..
cp -f *.h ..
