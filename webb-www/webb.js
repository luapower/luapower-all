/*

	webbjs | client-side main module
	Written by Cosmin Apreutesei. Public Domain.

CONFIG API

	config(name[, default]) -> value       for global config options
	S(name[, default]) -> s                for internationalized strings
	lang()                                 current language

URLs

	url(url) -> {path: [s,...], params: {k->v}}    decode URL
	url(path_elements[, params]) -> url            encode URL
	url(url, params) -> url                        update URL
	url(url, path_elements[, params]) -> url       update URL

ACTIONS

	lang_url([path[, params[, lang]]]) -> url  traslate a URL
	find_action(path) -> handler | nil     find the client-side action for a path
	.setlink([path[, params]])             hook an action to a link
	.setlinks([filter])                    hook actions to all links
	page_loading() -> t|f                  was current page loaded or exec()'ed?
	url_changed()                          window's URL changed
	exec(path[, params])                   change the window URL
	back()                                 go back to last URL in history
	setscroll([top])                       set scroll to last position or reset
	settitle([title])                      set title to <h1> contents or arg
	^url_changed                           url changed event
	^action_not_found                      action not found event
	action: {action: handler}

ARG VALIDATION

	intarg(s)
	optarg(s)

	slug(id, s)

TEMPLATES

	load_templates(success)                load templates from the server
	template(name) -> s                    get a template
	render_string(s[, data]) -> s          render a template from a string
	render(name[, data]) -> s              render a template
	.render_string(s, data)                render template string to target
	.render(name[, data])                  render template to target
	.setup()                               trigger ^setup event
	^setup                                 triggered after render on target

PUB/SUB

	listen(topic, func)                       add an event listener
	unlisten(topic)                           remove event listeners on a topic
	broadcast_local(topic, data)              broadcast data to local listeners
	broadcast_external(topic, data)           broadcast data to other windows
	broadcast(topic, data)                    broadcast data to all windows

PERSISTENCE

	store(key, value)                         store a value in the local store
	getback(key) -> value                     get back the stored value

*/

// config --------------------------------------------------------------------

// some of the values come from the server (see config.js.lua).
var C_ = {}
function config(name, val) {
	if (val && !C_[name])
		C_[name] = val
	if (typeof(C_[name]) === 'undefined')
		console.log('warning: missing config value for ', name)
	return C_[name]
}

// global S() for internationalizing strings.
var S_ = {}
function S(name, val) {
	if (val && !S_[name])
		S_[name] = val
	return S_[name]
}

function lang() {
	return document.documentElement.lang
}

// url encoding & decoding ---------------------------------------------------

// 1. decode: url('a/b?k=v') -> {path: ['a','b'], params: {k:'v'}}
// 2. encode: url(['a','b'], {k:'v'}) -> 'a/b?k=v'
// 3. update: url('a/b', {k:'v'}) -> 'a/b?k=v'
// 4. update: url('a/b?k=v', ['c'], {k:'x'}) -> 'c/b?k=x'
function url(path, params, update) {
	if (typeof path == 'string') { // decode or update
		if (params !== undefined || update !== undefined) { // update
			if (typeof params == 'object') { // update params only
				update = params
				params = undefined
			}
			var t = url(path) // decode
			if (params) // update path
				for (var i = 0; i < params.length; i++)
					t.path[i] = params[i]
			if (update) // update params
				for (k in update)
					t.params[k] = update[k]
			return url(t.path, t.params) // encode back
		} else { // decode
			var i = path.indexOf('?')
			var params
			if (i > -1) {
				params = path.substring(i + 1)
				path = path.substring(0, i)
			}
			var a = path.split('/')
			for (var i = 0; i < a.length; i++)
				a[i] = decodeURIComponent(a[i])
			var t = {}
			if (params !== undefined) {
				params = params.split('&')
				for (var i = 0; i < params.length; i++) {
					var kv = params[i].split('=')
					var k = decodeURIComponent(kv[0])
					var v = kv.length == 1 ? true : decodeURIComponent(kv[1])
					if (t[k] !== undefined) {
						if (typeof t[k] != 'array')
							t[k] = [t[k]]
						t[k].push(v)
					} else {
						t[k] = v
					}
				}
			}
			return {path: a, params: t}
		}
	} else { // encode
		if (typeof path == 'object') {
			params = path.params
			path = path.path
		}
		var a = []
		for (var i = 0; i < path.length; i++)
			a[i] = encodeURIComponent(path[i])
		var path = a.join('/')
		var a = []
		var keys = Object.keys(params).sort()
		for (var i = 0; i < keys.length; i++) {
			var pk = keys[i]
			var k = encodeURIComponent(pk)
			var v = params[pk]
			if (typeof v == 'array') {
				for (var j = 0; j < v.length; j++) {
					var z = v[j]
					var kv = k + (z !== true ? '=' + encodeURIComponent(z) : '')
					a.push(kv)
				}
			} else {
				var kv = k + (v !== true ? '=' + encodeURIComponent(v) : '')
				a.push(kv)
			}
		}
		var params = a.join('&')
		return path + (params ? '?' + params : '')
	}
}

/*
//decode
console.log(url('a/b?a&b=1'))
console.log(url('a/b?'))
console.log(url('a/b'))
console.log(url('?a&b=1&b=2'))
console.log(url('/'))
console.log(url(''))
//encode
// TODO
console.log(url(['a', 'b'], {a: true, b: 1}))
//update
// TODO
*/

// actions/encoding ----------------------------------------------------------

function _underscores(action) {
	return action.replace(/-/g, '_')
}

_action_name = _underscores

function _action_urlname(action) {
	return action.replace(/_/g, '-')
}

function _decode_url(path, params) {
	if (typeof path == 'string') {
		var t = url(path)
		if (params)
			for (k in params)
				if (params.hasOwnProperty(k))
					t.params[k] = params[k]
		return t
	} else {
		return {path: path, params: params || {}}
	}
}

// extract the action from a decoded url
function _url_action(t) {
	if (t.path[0] == '' && t.path.length >= 2)
		return _action_name(t.path[1])
}

// given an url (in encoded or decoded form), if it's an action url,
// replace its action name with a language-specific alias for a given
// (or current) language if any, or add ?lang= if the given language
// is not the default language.
function lang_url(path, params, target_lang) {
	var t = _decode_url(path, params)
	var default_lang = config('lang')
	var target_lang = target_lang || t.params.lang || lang()
	var action = _url_action(t)
	if (action === undefined)
		return url(t)
	var is_root = t.path[1] == ''
	if (is_root)
		action = _action_name(config('root_action'))
	var at = config('aliases').to_lang[action]
	var lang_action = at && at[target_lang]
	if (lang_action) {
		if (! (is_root && target_lang == default_lang))
			t.path[1] = lang_action
	} else if (target_lang != default_lang) {
		t.params.lang = target_lang
	}
	t.path[1] = _action_urlname(t.path[1])
	return url(t)
}

var action = {} // {action: handler}

// given a path (in encoded form), find the action it points to
// and return its handler.
function find_action(path) {
	var t = url(path)
	var act = _url_action(t)
	if (act === undefined)
		return
	if (act == '')
		act = config('root_action')
	else // an alias or the act name directly
		act = config('aliases').to_en[act] || act
	act = _action_name(act)
	var handler = action[act] // find a handler
	if (!handler) {
		// no handler, find a static template
		if (template(act) !== undefined) {
			handler = function() {
				render(act, null, '#main')
			}
		}
	}
	if (!handler)
		return
	var args = t.path
	args.shift(0) // remove /
	args.shift(0) // remove act
	return function() {
		handler.apply(null, args)
	}
}

// actions/history -----------------------------------------------------------

function check(truth) {
	if(!truth) {
		$(document).trigger('action_not_found')
	}
}

var g_page_loading = true

// check if the action was triggered by a page load or by exec()
function page_loading() {
	return g_page_loading
}

$(function() {
	var History = window.History
	History.Adapter.bind(window, 'statechange', function() {
		g_page_loading = false
		url_changed()
	})
})

var g_ignore_url_changed

function url_changed() {
	if (g_ignore_url_changed) return
	$(document).trigger('url_changed')
	var handler = find_action(location.pathname)
	if (handler)
		handler()
	else
		check(false)
	$(document).trigger('after_exec')
}

$(document).on('url_changed', function() {
	$(document).off('.current_action')
	unlisten('.current_action')
})

function _save_scroll_state(top) {
	var state = History.getState()
	g_ignore_url_changed = true
	History.replaceState({top: top}, state.title, state.url)
	g_ignore_url_changed = false
}

var exec, back
(function() {

	var aborted

	function abort_exec() {
		aborted = true
	}

	function check_exec() {
		aborted = false
		$(document).trigger('before_exec', [abort_exec])
		return !aborted
	}

	exec = function(path, params) {
		if (!check_exec())
			return
		// store current scroll top in current state first
		_save_scroll_state($(window).scrollTop())
		// push new state without data
		History.pushState(null, null, lang_url(path, params))
	}

	back = function() {
		if (!check_exec())
			return
		History.back()
	}

})()

// set scroll back to where it was or reset it
function setscroll(top) {
	if (top !== undefined) {
		_save_scroll_state(top)
	} else {
		var state = History.getState()
		var top = state.data && state.data.top || 0
	}
	$(window).scrollTop(top)
}

$.fn.setlink = function(path, params) {
	$.each(this, function() {
		var a = $(this)
		if (a.data('hooked_'))
			return
		if (a.attr('target'))
			return
		var path = path || a.attr('href')
		if (!path)
			return
		var url = lang_url(path, params)
		a.attr('href', url)
		var handler = find_action(url)
		if (!handler)
			return
		a.click(function(event) {
			// shit/ctrl+click passes through to open in new window or tab
			if (event.shiftKey || event.ctrlKey) return
			event.preventDefault()
			exec(path, params)
		}).data('hooked_', true)
	})
	return this
}

$.fn.setlinks = function(filter) {
	this.find(filter || 'a[href],area[href]').setlink()
	return this
}

function settitle(title) {
	title = title
		|| $('h1').html()
		|| url(location.pathname).path[1].replace(/[-_]/g, ' ')
	if (title)
		document.title = title + config('page_title_suffix')
}

// templates -----------------------------------------------------------------

function load_templates(success) {
	$.get('/'+config('templates_action'), function(s) {
		$('#__templates').html(s)
		if (success)
			success()
	}).fail(function() {
		assert(false, 'could not load templates')
	})
}

function template(name) {
	var t = $('#' + _underscores(name) + '_template')
	return t.length > 0 && t.html() || undefined
}

function load_partial_(name) {
	return template(name)
}

function render_string(s, data) {
	return Mustache.render(s, data || {}, load_partial_)
}

function render(template_name, data) {
	var s = template(template_name)
	return render_string(s, data)
}

$.fn.render_string = function(s, data) {
	assert(this.length > 0, 'render_string(): target empty')
	var s = render_string(s, data)
	return this.teardown().html(s).setup()
}

$.fn.teardown = function() {
	this.trigger('teardown')
	return this
}

$.fn.setup = function() {
	this.trigger('setup')
	return this
}

$.fn.render = function(name, data) {
	return this.render_string(template(name), data)
}

// inter-window events -------------------------------------------------------

var g_events = $({})

function listen(topic, func) {
	g_events.on(topic, function(e, data) {
		func(data)
	})
}

function unlisten(topic) {
	g_events.off(topic)
}

// broadcast a message to local listeners
function broadcast_local(topic, data) {
	g_events.trigger(topic, data)
}

window.addEventListener('storage', function(e) {
	// decode the message
	if (e.key != 'broadcast_') return
	var args = e.newValue
	if (!args) return
	args = JSON.parse(args)
	// broadcast it
	broadcast_local(args.topic, args.data)
})

// broadcast a message to other windows
function broadcast_external(topic, data) {
	if (localStorage === undefined)
		return
	localStorage.setItem('broadcast_', '')
	localStorage.setItem('broadcast_',
		JSON.stringify({
			topic: topic,
			data: data
		})
	)
	localStorage.setItem('broadcast_', '')
}

function broadcast(topic, data) {
	broadcast_local(topic, data)
	broadcast_external(topic, data)
}

// trickled-down events ------------------------------------------------------

(function() {

	var registered = {}

	function capture(etype, handler) {
		var attr = 'capture-'+etype
		$(this).on(etype, handler).attr(attr, true)
		if (!registered[etype]) {
			$([window, document]).on(etype, function(e) {
				var args = $.makeArray(arguments)
				args.shift()
				var ret
				$(e.target).find('['+attr+']').each(function() {
					ret = $(this).triggerHandler(e, args)
				})
				return ret
			})
			registered[etype] = true
		}
	}

	$.fn.capture = function(etypes, handler) {
		etypes = etypes.trim().split(' ')
		for(var i = 0; i < etypes.length; i++) {
			var etype = etypes[i].trim()
			if (etype)
				capture.call(this, etype, handler)
		}
		return this
	}

})()

// persistence ---------------------------------------------------------------

function store(key, value) {
	Storage.setItem(key, JSON.stringify(value))
}

function getback(key) {
	var value = Storage.getItem(key)
	return value && JSON.parse(value)
}

// init ----------------------------------------------------------------------

$(function() {
	analytics_init()
	load_templates(function() {
		$(document).setup()
		if (client_action)
			url_changed()
	})
})
