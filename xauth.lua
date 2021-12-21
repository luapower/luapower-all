
require'webb_spa'
require'webb_auth'
require'xrowset_sql'

jsfile'x-auth.js'
cssfile'x-auth.css'

Sfile'webb_auth.lua'
Sfile'xrowset.lua'
Sfile'xrowset_sql.lua'
Sfile'x-auth.js'
Sfile'xauth.lua'

wwwfile['x-auth.css'] = [[

.breadcrumbs {
	margin: 1em 0;
}

.x-settings-button {

}

.x-settings-button > .x-button-icon {
	font-size: 1.2em;
}

.sign-in-slides {
	align-self: center;
	width: 300px;
	padding: 1em 2em;
}

.sign-in-slides .x-button {
	//margin: .25em 0;
}

]]

template.sign_in_dialog = [[
<x-dialog>
	<content>
		{{#logo}}
			<img class=sign-in-logo src="{{logo}}">
		{{/logo}}
		<x-slides class=sign-in-slides>

			<div vflex class="x-flex">
				<div class=x-dialog-heading>
					Sign-in
				</div>
				<p small>
				The security of your account is important to us.
				That is why instead of having you set up a hard-to-remember password,
				we will send you a one-time activation code every time
				you need to sign in.
				</p>
				<x-textedit class=sign-in-email-edit field_type=email label="Email address"></x-textedit>
				<x-button primary class=sign-in-email-button>E-mail me a sign-in code</x-button>
			</div>

			<div vflex class="x-flex">
				<div class=x-dialog-heading>
					Enter code
				</div>
				<p small>
				An e-mail was sent to you with a 6-digit sign-in code.
				Enter the code below to sign-in.
				<br>
				If you haven't received an email even after
				a few minutes, please <a href="/sign-in">try again</a>.
				</p>
				<x-textedit class=sign-in-code-edit field_type=sign_in_code label="6-digit sign-in code"></x-textedit>
				<x-button primary class=sign-in-code-button>Sign-in</x-button>
			</div>

		</x-slides>
	</content>
</x-dialog>
]]

template.sign_in_email = [[

Your sign-in code:

{{code}}

]]

action['login.json'] = function()
	local auth = post()
	allow(login(auth))
	return usr'*'
end

action['sign_in_email.json'] = function()
	local params = post()
	local noreply = config'noreply_email' or email'no-reply'
	local email = allow(json_str_arg(params.email),
		S('email_required', 'Email address required'))
	local code = allow(gen_auth_code('email', email))
	log('SIGN-IN', 'email=%s code=%s', email, code)
	local subj = S('sign_in_email_subject', 'Your sign-in code')
	local msg = render('sign_in_email', {code = code, host = host()})
	sendmail(noreply, email, subj, msg)
	return {ok = true}
end

action['sign_in_phone.json'] = function()
	local phone = allow(json_str_arg(params.phone),
		S('phone_required', 'Phone number required'))
	local code = allow(gen_auth_code('phone', phone))
	local msg = S('sign_in_sms_message',
		'Your sign-in code for {1} is: {0}', code, host())
	log('SIGN-IN', 'phone=%s code=%s', phone, code)
	sendsms(phone, msg)
	return {ok = true}
end
