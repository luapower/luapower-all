/*

	User settings dropdown and sign-in dialog.
	Written by Cosmin Apreutesei. Public Domain.

*/

{

function set_night_mode(v) {
	document.body.attr('theme', v ? 'dark' : null)
	document.fire('theme_changed', v ? 'dark' : null)
}

let init_settings_nav = function() {

	init_settings_nav = noop

	let set = {}

	set.night_mode = function(v) {
		set_night_mode(v)
	}

	let nav = bare_nav({
		id: 'user_settings_nav',
		static_rowset: {
			fields: [
				{
					name: 'night_mode', type: 'bool', default: false,
					text: S('night_mode', 'Night Mode'),
				},
			],
		},
		row_vals: [{
			night_mode: false,
		}],
		props: {row_vals: {slot: 'user'}},
		save_row_on: 'input',
	})
	body.add(nav)

	function set_all() {
		for (let field of nav.all_fields)
			set[field.name](nav.cell_val(nav.focused_row, field))
	}

	nav.on('reset', set_all)

	nav.on('focused_row_cell_val_changed', function(field, v) {
		set[field.name](v)
	})

	nav.on('saved', function() {
		if (!window.xmodule)
			return
		xmodule.save()
	})

	set_all()
}

component('x-settings-button', function(e) {

	button.construct(e)

	e.xoff()
	e.bare = true
	e.text = ''
	e.icon = 'fa fa-user-circle'
	e.xon()

	let tt

	e.on('activate', function() {

		if (tt && tt.target) {

			tt.close()

		} else {

			let night_mode = checkbox({
				nav_id: 'user_settings_nav',
				col: 'night_mode',
				button_style: 'toggle',
				autoclose: true,
			})

			night_mode.on('val_changed', function(v) {
				set_night_mode(v)
			})

			let sign_in_button, logout_button
			if (!usr || usr.anonymous) {
				sign_in_button = button({
					text: S('button_text_sign_in', 'Sign-In'),
					action: () => { tt.close(); sign_in(); },
				})
			} else {
				logout_button = button({
					text: S('button_text_log_out', 'Log out'),
					bare: true,
					icon: 'fa fa-sign-out-alt',
					action: () => { tt.close(); sign_out(); },
				})
			}

			let settings_form = div({style: `
					display: flex;
					flex-flow: column;
				`},
				night_mode,
				sign_in_button,
				logout_button,
			)

			tt = tooltip({
				classes: 'x-settings-tooltip',
				target: e, side: 'bottom', align: 'end',
				text: settings_form,
				close_button: true,
				autoclose: true,
			})

		}

	})

})

// sign-in form --------------------------------------------------------------

let sign_in_dialog = memoize(function() {

	let e = unsafe_html(render('sign_in_dialog', window.sign_in_options))

	e.slides       = e.$1('.sign-in-slides')
	e.email_edit   = e.$1('.sign-in-email-edit')
	e.code_edit    = e.$1('.sign-in-code-edit')
	e.email_button = e.$1('.sign-in-email-button')
	e.code_button  = e.$1('.sign-in-code-button')

	e.email_edit.field = {not_null: true}
	e.code_edit.field = {not_null: true}

	e.email_button.action = function() {
		let d = sign_in_dialog()
		e.email_button.post(href('/sign-in-email.json'), {
			email: e.email_edit.val,
		}, function() {
			sign_in_code()
		}, function(err) {
			e.email_edit.errors = [{message: err, passed: false}]
			e.email_edit.focus()
		})
	}

	e.code_button.action = function() {
		let d = sign_in_dialog()
		call_login({
				type: 'code',
				code: e.code_edit.val,
			},
			e.code_button,
			function() {
				if (location.pathname.starts('/sign-in'))
					exec('/')
				else
					e.close()
			},
			function(err) {
				e.code_edit.errors = [{message: err, passed: false}]
				e.code_edit.focus()
			}
		)
	}

	return e
})

let sign_in_dialog_modal = function() {
	return sign_in_dialog().modal()
}

let sign_in = function() {
	let d = sign_in_dialog_modal()
	d.email_edit.errors = null
	d.slides.slide(0)
}

let sign_in_code = function() {
	let d = sign_in_dialog_modal()
	d.code_edit.errors = null
	d.slides.slide(1)
}

flap.sign_in = function(on) {
	let d = sign_in_dialog()
	if (!on && d)
		d.close()
}

action.sign_in = function() {
	setflaps('sign_in')
	sign_in()
}

action.sign_in_code = function() {
	setflaps('sign_in')
	sign_in_code()
}

let call_login = function(upload, notify_widget, success, fail) {
	ajax({
		url: href('/login.json'),
		upload: upload || empty,
		notify: notify_widget,
		success: function(usr1) {
			usr = usr1
			print('usr_changed', usr)
			broadcast('usr_changed', usr)
			if (window.xmodule)
				xmodule.set_layer('user', 'user', 'user-'+usr.usr)
			if (success) success()
		},
		fail: function(err) {
			notify(err, 'error')
			if (fail) fail(err)
		},
	})
}

function init_auth() {
	init_settings_nav()
	call_login()
}

let sign_out = function() {
	call_login({type: 'logout'})
}

}

