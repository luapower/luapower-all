[ -d src ] || git clone https://github.com/openresty/luajit2 src
(cd src && git checkout -f v2.1-agentzh && git pull)

# read the first line on each .patch file to see what it does.
cat *.patch | patch -N -p0

# remove SONAME from library to avoid dependencies on libluajit 
# to fixate on the name of the file.
sed 's|-Wl,-soname,\$(TARGET_SONAME)||g' -i src/src/Makefile
