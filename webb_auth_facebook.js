/*

CONFIG

	config('facebook_app_id')

*/

function facebook_connect(success, error, opt) {
	FB.getLoginStatus(function(response) {
		if (response.status == 'connected')
			login({
				type: 'facebook',
				access_token: response.authResponse.accessToken,
			}, success, error, opt)
		else
			if (error) error()
	})
}

function facebook_login(success, error, opt) {
	FB.login(function(response) {
		if (response.authResponse)
			login({
				type: 'facebook',
				access_token: response.authResponse.accessToken,
			}, success, error, opt)
		else
			if (error) error()
	}, {scope: 'public_profile,email'})
}

window.fbAsyncInit = function() {
	if (!config('facebook_app_id', false)) return
	FB.init({
		appId   : config('facebook_app_id'),
		cookie  : true,  // enable cookies to allow the server to access the session
		xfbml   : true,  // parse social plugins on this page
		version : 'v2.1' // use version 2.1
	})
}

$.getScript('//connect.facebook.net/en_US/sdk.js')
