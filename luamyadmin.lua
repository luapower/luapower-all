
require'$'
require'webb'
require'webb_action'
require'webb_query'
require'xrowset'
require'xmodule'
require'xrowset_test'

config('db_name', 'rowset_test')
config('db_pass', 'abcd12')

config('root_action', 'home')

local luamyadmin = {}

function rowset.tables()
	query'use information_schema'
	return sql_rowset([[
		select table_schema, table_name
		from tables
	]]):respond()
end

function rowset.columns()
	query'use information_schema'
	return sql_rowset([[
		select *
		from columns c
		where
			c.table_schema = :table_schema
			and c.table_name = :table_name
	]]):respond()
end

function action.test()
	pp(query('insert into rowset_test set name = ?', 'yo'))
end

return function()
	check(action(find_action(unpack(args()))))
end
