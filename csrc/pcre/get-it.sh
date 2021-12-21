n=8.43
[ -d src ] && exit 1
wget -ncv https://ftp.pcre.org/pub/pcre/pcre-$n.tar.gz
tar xf pcre-$n.tar.gz
mv pcre-$n src
rm pcre-$n.tar.gz

# TODO:
#  copy *.{c,h} from src/src except programs (grep for 'main(')
#  copy *.h.generic to *.h
#  copy *.c.dist to *.c

