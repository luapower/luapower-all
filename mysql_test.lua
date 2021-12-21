
local mysql = require'mysql'
local sock = require'sock'
local pp = require'pp'
require'$'

sock.run(function()

	local conn = assert(mysql.connect{
		host = '127.0.0.1',
		port = 3307,
		user = 'root',
		password = 'root',
		db = 'sp',
		charset = 'utf8mb4',
	})

	assert(conn:query[[
	create table if not exists test (
		f1 decimal(20, 6),
		f2 tinyint(1),
		f2b tinyint unsigned,
		f3 smallint(2),
		f3a mediumint(3),
		f4 int(4),
		f5 bigint(5),
		f6 float(2), /* (2) ignored */
		f7 double, /* can't even give (2) here */
		f8 timestamp default current_timestamp,
		f9 date default '1000-11-22 12:34:56',
		f10 time,
		f11 datetime default '1000-11-22 12:34:56',
		f12 varchar(100),
		f12a varchar(100) not null collate ascii_bin,
		f13 char(100),
		f14 varbinary(100),
		f15 binary(100),
		f16 year,
		f17 bit(12),
		f18 enum('apple', 'bannana'),
		f19 set('a', 'b', 'c'),
		f20 tinyblob,
		f21 mediumblob,
		f22 longblob,
		f23 blob,
		f24  tinytext,
		f24a tinytext collate ascii_bin,
		f25  mediumtext,
		f25a mediumtext collate ascii_bin,
		f26  longtext,
		f26a longtext collate ascii_bin,
		f27  text,
		f27a text collate ascii_bin,
		f28 varchar(10),
		f29 char(10)
	);
	]])

	local function pr(cols, h)
		local t = {}
		for _,k in ipairs(h) do
			add(t, fmt('%20s', k))
		end
		print(cat(t))
		print()
		for _,col in ipairs(cols) do
			local t = {}
			for _,k in ipairs(h) do
				local v = col[k]
				v = isnum(v) and fmt('%0.17g', v) or v
				v = istab(v) and pp.format(v) or v
				add(t, fmt('%-20s', repl(v, nil, '')))
			end
			print(cat(t))
		end
		print()
	end

	--pp(conn:query'select * from val where val = 1')
	local stmt = assert(conn:prepare
		--'select cast(123 as tinyint) union select cast(123 as tinyint)')
		'select * from test')
		-- ('select min_price from vari where val = ?'))
	assert(stmt:exec())
	local rows, _, cols = conn:read_result({datetime_format = '*t'})
	pr(cols, {
		'name',
		'mysql_display_type',
		'type',
		'display_width',
		'decimals',
		'has_time',
		'padded',
		'mysql_display_charset',
		'mysql_display_collation',
		'mysql_buffer_type',
	})
	assert(stmt:free())

	conn:close()

	assert(conn:closed())

end)

