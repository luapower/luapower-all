require'$'
require'webb'
require'webb_action'

config('root_action', 'home')

return function()
	if args()[1] == 'comanda' or args()[1] == 'multumim' then
		args()[1] = ''
	end
	check(action(find_action(unpack(args()))))
end
