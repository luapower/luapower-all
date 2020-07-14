require'$'
require'webb'
require'webb_action'

config('root_action', 'home')

return function()
	check(action(find_action(unpack(args()))))
end
