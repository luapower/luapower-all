mgit ls-untracked \
	| grep -v 'csrc/llvm/' \
	| grep -v 'media/fonts/gfonts/' \
	| grep -v 'media/rsync/' \
	| grep -v 'csrc/nginx/src/' \
	| grep -v 'csrc/nginx/ndk/' \
	| grep -v 'csrc/nginx/openresty/' \
	| grep -v 'csrc/nginx/lua/' \
	| grep -v 'csrc/terra/terra/' \
	| grep -v 'luapower-www/\.cache/' \
	| grep -v 'nginx-luapower\.conf' \
	| grep -v 'logs/' \
	| grep -v 'tmp/' \
	| grep -v 'donut-studio/'	\
	| grep -v 'scite\.lua' \
	| grep -v '.*_conf\.lua' \
	| grep -v '.*\.pem' \
	| grep -v '.*\.crt' \
	| grep -v '.*\.csr' \
	| grep -v '.*\.log' \
	| grep -v '.*\-next-id' \
	| grep -v '.*\.key'
