b="$PWD"
n=openssl-1.0.2e
d=~/openssl.src

# we unpack the sources in home because they contain symlinks
# and the luapower tree could be mounted on a samba share.

mkdir -p $d
cd $d || exit 1
[ -f $n.tar.gz ] || wget -O $n.tar.gz http://www.openssl.org/source/$n.tar.gz
[ -d src ] || { tar xzfv $n.tar.gz; mv $n src; }

(cd "$b"
for f in *.sh; do
    ln -sf "$b/$f" "$d/$f"
done)
ln -sf "$b/../.." luapower
(cd src; patch -N -r /dev/null < "$b/Makefile.shared.patch")

echo "Build dir set in \"$PWD\". Run build scripts from there."
