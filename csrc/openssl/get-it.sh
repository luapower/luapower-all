n=openssl-1.1.1d
[ -d src ] || {
    wget -q -nc http://www.openssl.org/source/$n.tar.gz
    tar xzfv $n.tar.gz; mv $n src; 
}
wget -q -nc https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-1.1.1c-sess_set_get_cb_yield.patch
