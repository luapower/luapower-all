echo "require'$1'" > tmp/resty-cli.lua
./nginx -c .mgit/resty-cli.conf
