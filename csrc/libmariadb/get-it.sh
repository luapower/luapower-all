[ -d src ] || git clone https://github.com/MariaDB/mariadb-connector-c.git src
cd src
git checkout v3.1.4

cp -f  libmariadb/ma_*.c ..
cp -f  libmariadb/mariadb_*.c ..
cp -f  libmariadb/secure/{ma_schannel.c,ma_schannel.h,schannel.c,win_crypt.c} ../tls-schannel/
cp -f  libmariadb/secure/openssl*.c ../tls-openssl/
cp -f  plugins/auth/old_password.c ..
cp -f  plugins/auth/my_auth.c      ..
cp -rf include/* ..

