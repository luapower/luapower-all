grep 'glue\..' *.lua winapi/*.lua cplayer/*.lua \
	| grep -v '_demo.lua:' \
	| grep -v '_test.lua:' \
	| sed -r 's/^.*?glue\.([a-z_]+).*$/\1/g' | sort | uniq -c | sort
