--go@bin\mingw64\nginx.exe -c credex-nginx-dev.conf

require'$' --replaces: Lua's module().
require'webb'
require'daemon' --replaces: Lua's load() and webb's check().
local http = require'resty.http'
local mail = require'resty.mail'
local errors = require'errors'

app_name = 'credex'
app_env = 'Dev'

bt_host = 'ecclients.btrl.ro'
bt_port = 5443
bt_user = 'credex_api'
bt_pass = 'credex_api1'
--bt_return_url = 'https://ecclients.btrl.ro:5443/payment/merchants/Test_BT/finish.html'
--^^This is BT's default return URL. Use it for debugging.
bt_return_url = 'http://127.0.0.1:8100/multumim'
bt_ssl_verify = false --TODO: set up the CA root file for nginx and enable this to prevent MITM with BTPay.

smtp_host = 'aws-alerts.altex.ro'
smtp_port = 25
smtp_user = 'credex'
smtp_pass = '' -- don't put that here, put it in credex_conf.lua!
office_email = 'contact@credex-ifn.ro'

daemon()

local app = {}

--btpay api ------------------------------------------------------------------

local function bt_call(api, params)
	local uri = ('https://{host}:{port}/payment/rest/{api}'):subst{
		host = bt_host,
		port = bt_port,
		api  = api,
	}
	local query = update({
		userName = bt_user,
		password = bt_pass,
		language = 'ro',
	}, params)
	local client = http.new()
	note ('bt', 'http >', '%s\n%s', uri, pp.format(query, '  '))
	local res, err = client:request_uri(uri, {
		query = query,
		ssl_verify = bt_ssl_verify,
	})
	check('bt', 'http <', res, err)
	check('bt', 'http <', res.status == 200, '%d %s\n%s', res.status, res.reason, res.body)
	local ok, t = pcall(json, res.body)
	check('bt', 'http <', ok, '%s\n%s', t, res.body)
	local t_s = pp.format(t, '  ')
	check('bt', 'http <', not t.errorCode or tonumber(t.errorCode) == 0,
		'BT error %s: %s\n%s', t.errorCode, t.errorMessage, t_s)
	note ('bt', 'http <', t_s)
	client:close()
	return t
end

function app.bt_pay(order)
	local t = bt_call('register.do', {
		orderNumber = order.order_num,
		amount      = tostring(floor(order.amount * 100)),
		currency    = 946,
		description = order.description,
		returnUrl   = bt_return_url,
	})
	check('bt', 'http <', t.formUrl and t.orderId, 'formUrl and orderId fields are missing')
	return t.formUrl
end

local errors_ro = {
	[320] = 'Card inactiv. Vă rugăm activați cardul.',
	[801] = 'Emitent indisponibil.',
	[803] = 'Card blocat. Vă rugăm contactați banca emitentă.',
	[805] = 'Tranzacție respinsă.',
	[861] = 'Dată expirare card greșită.',
	[871] = 'CVV gresit.',
	[906] = 'Card expirat.',
	[914] = 'Cont invalid. Vă rugăm contactați banca emitentă.',
	[915] = 'Fonduri insuficiente.',
	[917] = 'Limită tranzacționare depășită.',
}

function app.bt_status(orderId)
	local t = bt_call('getOrderStatusExtended.do', {orderId = orderId})
	if t.actionCode ~= 0 then
		t.error_message = errors_ro[t.actionCode]
			or t.actionCodeDescription
			or _('Eroare BTPay %s', t.actionCode or '')
	end
	return t
end

--credex/btpay integration ---------------------------------------------------

local function to_cnp(s) --validate a CNP minimally.
	if not s then
		return nil, 'CNP-ul trebuie completat.'
	end
	if #s ~= 13 then
		return nil, 'CNP-ul trebuie sa contina 13 cifre.'
	end
	if not s:find'^%d+$' then
		return nil, 'CNP-ul trebuie sa contina doar cifre.'
	end
	--check CNP checksum.
	local function digit(s, i)
		return (s:byte(i, i) - ('0'):byte())
	end
	local n = 0
	for i = 1, 12 do
		n = n + digit(s, i) * digit('279146358279', i)
	end
	local checksum = n % 11
	if checksum == 10 then checksum = 1 end
	if checksum ~= digit(s, 13) then
		return nil, 'CNP incorect.'
	end
	return s
end

local function to_cid(s) --validate CREDEX contract ID.
	if not s then
		return true --cid is optional.
	end
	if #s ~= 11 then
		return nil, 'Numarul de contract trebuie sa contina 11 cifre.'
	end
	if not s:find'^%d+$' then
		return nil, 'Numarul de contract trebuie sa contina doar cifre.'
	end
	local year = tonumber(s:sub(1, 4)) --contract year
	local max_year = date'*t'.year
	local min_year = 2018
	if year < min_year then
		return nil, 'Contractul trebuie sa fie cel putin din anul %d.', min_year
	end
	if year > max_year then
		return nil, 'Contractul trebuie sa fie cel mult din anul curent %d.', max_year
	end
	return s
end

local function to_amount(s) --validate amount
	if not s then
		return nil, 'Suma de plata trebuie completata.'
	end
	if s:find',' then
		return nil, 'Va rugam sa folositi punctul ca separator pentru zecimale.'
	end
	local digits, decimals = s:match'^(%d+)%.?(%d*)$'
	if not digits then
		return nil, 'Suma de plata nu este un numar valid.'
	end
	if #decimals > 2 then
		return nil, 'Suma de plata trebuie sa contina maxim 2 zecimale.'
	end
	local n = tonumber(s)
	if n < 1 then
		return nil, 'Suma de plata este prea mica.'
	end
	if n >= 1e9 then
		return nil, 'Suma de plata este prea mare.'
	end
	return n
end

local function check_arg(field, v, ...)
	return errors.check('arg', v, {field = field}, ...)
end

function app.credex_pay(t)
	local dt = {}
	local cnp      = check_arg('cnp'   , to_cnp(t.cnp))
	local cid      = check_arg('cid'   , to_cid(t.cid))
	dt.amount      = check_arg('amount', to_amount(t.amount))
	dt.description = cnp..(cid ~= true and ' CRDX'..cid or '')
	dt.order_num   = gen_id'order_num'
	return app.bt_pay(dt)
end

function app.credex_pay_return(orderId)
	return app.bt_status(orderId)
end

--frontend -------------------------------------------------------------------

if ngx then

	local function out_main(content_template, t)
		template.main_content = template(content_template)
		out(render('main', t))
	end

	local function out_main_form(form_template, t)
		template.main_content = template'form'
		template.form_content = template(form_template)
		out(render('main', t))
	end

	local action = {}

	action[''] = function()
		local t = {}
		if method'post' then
			t.first_name = str_arg(post'first_name')
			t.last_name  = str_arg(post'last_name')
			t.phone      = str_arg(post'phone')
			t.email      = str_arg(post'email')
			t.message    = str_arg(post'message')
			t.agree1     = checkbox_arg(post'agree1')
			t.agree2     = checkbox_arg(post'agree2')

			local mailer = check('mail', 'new', mail.new({
				host = smtp_host,
				port = smtp_port,
				starttls = true,
				username = smtp_user,
				password = smtp_pass,
			}))

			local text = ([[
Nume: {first_name}
Prenume: {last_name}
Telefon: {phone}
Email: {email}
Mesaj: {message}
]]):subst(t)

			local ok, err = mailer:send{
				from = 'formular@credex-ifn.ro',
				to = { office_email },
				subject = 'Aplicatie pentru credit',
				text = text,
			}

			log(err and 'ERROR' or 'note', 'mail', 'send',
				'%s\n%s', err or 'OK', pp.format(t, '  '))

			redirect(ok and '/succes' or '/oops')
		end
		out_main_form('aplica', t)
	end

	function action.succes()
		local t = {}
		out_main('success', t)
	end

	function action.plateste_rata()
		local t = {}
		if method'post' then
			t.cnp    = str_arg(post'cnp')
			t.amount = str_arg(post'amount')
			t.cid    = str_arg(post'cid')
			local ok, err = errors.catch('arg', function()
				return redirect(app.credex_pay(t))
			end)
			if not ok then
				t.error = err.message
			end
		end
		out_main_form('plateste-rata', t)
	end

	function action.multumim()
		local orderId = str_arg(args'orderId')
		local orderId = check('client', 'url', orderId, 'orderId missing in return url')
		local t = app.credex_pay_return(orderId)
		out_main('multumim', t)
	end

	function action.oops()
		out_main'oops'
	end

	local function respond()
		local action_name = args(1):gsub('-', '_')
		local action = action[action_name]
		check('client', 'url', action, 'no action %s', action_name)
		action(select(2, unpack(args())))
	end
	function app.respond()
		local ok, err = errors.catch(nil, respond)
		if not ok then
			if not errors.is(err) or err.logged then
				log('CRASH', '', '', '%s\nuri: %s', tostring(err), ngx.var.uri)
			end
			if ngx.var.hide_errors then
				redirect'/oops'
			else
				errors.raise(err)
			end
		end
	end

end

return app
