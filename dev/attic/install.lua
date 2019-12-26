
setfenv(1, require'app')

require'ddl'

qsubst'table  create table if not exists'

--type domains
--qsubst'id      int unsigned'
--qsubst'pk      int unsigned primary key auto_increment'
qsubst'name      varchar(64) character set ascii not null'
qsubst'opt_name  varchar(64) character set ascii'
--qsubst'uname   varchar(64) character set utf8 collate utf8_general_ci'
--qsubst'email   varchar(128) character set utf8 collate utf8_general_ci'
qsubst'hash      varchar(40) character set ascii not null' --hmac_sha1 in hex
qsubst'url       varchar(2048)'
--qsubst'bool    tinyint not null default 0'
--qsubst'bool1   tinyint not null default 1'
qsubst'time      timestamp not null'


return function()

setmime'txt'

--drop db

pdbq[[
drop database if exists luapower
]]

--create db

pdbq[[
create database if not exists luapower
	character set utf8
	collate utf8_general_ci
]]

--create tables

pq[[
$table package (
	package $name,
	origin_url $url,
	csrc_dir $url,
	cat $opt_name,
	pos int,
	last_commit $hash,
	type $name, --Lua+ffi, Lua/C, Lua, C, other
	primary key (package)
);
]]

pq[[
$table commit (
	commit $hash,
	package $name,
	commit_time $time,
	version $name,
	primary key (commit)
);
]]

pq[[
$table platform (
	commit $hash,
	platform $name,
	primary key (commit, platform)
);
]]

pq[[
$table ctag (
	commit $hash,
	c_name $opt_name,
	c_version $opt_name,
	c_url $url,
	c_license $opt_name,
	primary key (commit)
);
]]

pq[[
$table cpdep ( --cpdep = C package dependencies
	commit $hash,
	platform $name,
	cpdep $name,
	primary key (commit, platform, cpdep)
);
]]

pq[[
$table doc (
	commit $hash,
	doc $name,
	path $name,
	title $opt_name,
	tagline text,
	primary key (commit, doc)
);
]]

pq[[
$table cat (
	cat $name,
	pos int,
	primary key (cat)
);
]]

pq[[
$table module (
	commit $hash,
	module $name,
	path $opt_name, --null for built-ins
	lang $name, --built-in, Lua, Lua/ASM, C
	type $name, --module, script
	parent_name $opt_name,
	primary key (commit, module)
);
]]

pq[[
$table loaderr (
	commit $name,
	module $name,
	platform $name,
	err text not null,
	primary key (commit, module, platform)
);
]]

pq[[
$table mdep (
	commit $hash,
	module $name,
	platform $name,
	mdep $name,
	type $name, --lua, ffi
	circ $name, --loadtime, runtime, autoload
	autload_key $opt_name,
	primary key (commit, module, platform, mdep)
);
]]

pq[[
$table ffidep (
	commit $hash,
	clib $name,
	path $name,
	primary key (commit, clib)
);
]]


end --function
