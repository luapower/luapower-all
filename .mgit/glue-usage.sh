grep 'glue\..' *.lua winapi/*.lua cplayer/*.lua terra/*.t \
	| grep -v '_demo.lua:' \
	| grep -v '_test.lua:' \
	| sed -r 's/^.*?glue\.([a-z_]+).*$/\1/g' | sort | uniq -c | sort -n
