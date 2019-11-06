/*

	webbjs | authentication
	Written by Cosmin Apreutesei. Public Domain.

API

	login([auth], [success][, error], [opt])
	^usr, usr                                logged-in user changed

*/

var admin_ = false

function login(auth, success, error, opt, arg) {
	function logged_in(usr) {
		admin_ = usr.admin
		broadcast('usr', usr)
		if (success)
			success(usr)
	}
	function login_failed(xhr) {
		var err = xhr.responseText
		S('server_error', 'There was an error.<br>Please try again or contact us.')
		S('login_error_email_taken', 'This email is already taken')
		S('login_error_user_pass', 'Wrong email address or password')
		var msg = S('login_error_'+err) || S('server_error')
		if (error)
			error(err, msg)
	}
	opt = $.extend({
			url: '/login.json' + (arg || ''),
			success: logged_in,
			error: login_failed,
			data: auth,
		}, opt)
	$(opt.dst || document).ajax(opt)
}

function logout(success, error, opt) {
	return login(null, success, error, opt, '/logout')
}

function admin() {
	return admin_
}

function allow(truth) {
	if(!truth)
		exec('/account')
}

$.fn.login = function(auth, success, error, opt) {
	login(auth, success, error, $.extend({dst: $(this)}, opt))
	return this
}
