
require'$'
require'webb'
require'webb_action'
--require'webb_query'
--require'xrowset'
--require'xmodule'
--require'x_dba'

--config('db_name', 'ck')
--config('db_pass', 'abcd12')

config('root_action', 'home')

alias('home', 'jobs'   , 'en')
alias('home', 'about'  , 'en')
alias('home', 'contact', 'en')

return function()
	check(action(find_action(unpack(args()))))
end
