gcc tgx.c -lgenx -L../../linux/bin -o tgx
LD_LIBRARY_PATH=../../linux/bin ./tgx >/dev/null
rm tgx
