
require'$'
require'webb'
require'webb_action'
require'webb_query'
require'xrowset'

config('db_name', 'information_schema')
config('db_pass', 'abcd12')

config('root_action', 'home')

local luamyadmin = {}

function rowset.tables()
	return query_rowset[[
		select table_schema, table_name
		from tables
	]]
end

function rowset.columns()
	return query_rowset([[
		select *
		from columns c
		where
			c.table_schema = $table_schema
			and c.table_name = $table_name
	]], {
		table_schema = args'table_schema' or null,
		table_name = args'table_name' or null,
	})
end

return function()
	check(action(find_action(unpack(args()))))
end
