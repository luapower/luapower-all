require'$'
require'webb'
require'webb_action'

config('root_action', 'shop')

function action.plaseaza_comanda()
	local order = post()
	--writefile('donut-studio/'+
end

return function()
	if args()[1] == 'comanda' or args()[1] == 'multumim' then
		args()[1] = 'shop'
	end
	check(action(find_action(unpack(args()))))
end
