/*

CONFIG

	config('google_client_id')

*/

var force_prompt = false
function google_login(success, fail) {
	var params = {
		clientid: config('google_client_id'),
		scope:    'https://www.googleapis.com/auth/plus.login email',
		requestvisibleactions: 'http://schema.org/AddAction',
		cookiepolicy: 'single_host_origin',
		approval_prompt: force_prompt ? 'force' : 'auto',
	}
	params.callback = function(authResult) {
		if (authResult.status.signed_in) {
			if (authResult.status.method == 'AUTO') {
				force_prompt = false
				login({
					type: 'google',
					access_token: authResult.access_token,
				}, success, fail)
			}
		} else {
			// Possible error values:
			//   "user_signed_out" - User is signed-out
			//   "access_denied" - User denied access to your app
			//   "immediate_failed" - Could not automatically log in the user
			if (fail) fail()
		}
	}
	gapi.auth.signIn(params)
}

$.getScript('https://apis.google.com/js/client:platform.js')
