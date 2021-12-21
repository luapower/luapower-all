/*

	webb.js | single-page apps | client-side API
	Written by Cosmin Apreutesei. Public Domain.

INIT

	init_action()

CONFIG API

	config(name[, default]) -> value       for global config options
	S(name, [default], ...args) -> s       for internationalized strings
	lang()                                 current language

ACTIONS

	href(url, [lang]) -> url               traslate a URL
	current_url() -> url
	e.sethref([url])                       hook an action to a link
	e.sethrefs()                           hook actions to all links
	page_loading() -> t|f                  was current page loaded or exec()'ed?
	exec(url[, opt])                       change the tab URL
	back()                                 go back to last URL in history
	setscroll([top])                       set scroll to last position or reset
	settitle([title])                      set title to <h1> contents or arg
	^url_changed                           url changed event
	^action_not_found                      action not found event
	action: {action: handler}
	id_arg(s)
	opt_arg(s)
	slug(id, s)

PAGE FLAPS

	flap.NAME = function(on) { ... }
	setflaps('NAME1 ...')

TEMPLATES

	template(name) -> s                    get a template
	render_string(s, [data]) -> s          render a template from a string
	render(name, [data]) -> s              render a template
	e.render_string(s, data)               render template string into e
	e.render([data])                       render e.template into e
	^bind(on, [data])                      fired before & after render

*/

{ // module scope.

// config --------------------------------------------------------------------

// some of the values come from the server (see config.js action).
{
let t = obj()
function config(name, val) {
	if (val !== undefined && t[name] === undefined)
		t[name] = val
	if (t[name] === undefined)
		warn('missing config value for', name)
	return t[name]
}}

// global S() for internationalizing strings.

S_texts = obj()

function S(name, en_s, ...args) {
	let s = or(S_texts[name], en_s) || ''
	if (args.length)
		return s.subst(...args)
	else
		return s
}

function lang() {
	return document.documentElement.lang
}

// actions -------------------------------------------------------------------

let action_name = function(action) {
	return action.replaceAll('-', '_')
}

// extract the action from a decoded url
let url_action = function(t) {
	if (t.segments[0] == '' && t.segments.length >= 2)
		return action_name(t.segments[1])
}

// given an url (in encoded or decoded form), if it's an action url,
// replace its action name with a language-specific alias for a given
// (or current) language if any, or add ?lang= if the given language
// is not the default language.
function href(url_s, target_lang) {
	let t = url_arg(url_s)
	let default_lang = config('lang')
	target_lang = target_lang || t.args.lang || lang()
	let action = url_action(t)
	if (action === undefined)
		return url(t)
	let is_root = t.segments[1] == ''
	if (is_root)
		action = action_name(config('root_action'))
	let at = config('aliases').to_lang[action]
	let lang_action = at && at[target_lang]
	if (lang_action) {
		if (!(is_root && target_lang == default_lang))
			t.segments[1] = lang_action
	} else if (target_lang != default_lang) {
		t.args.lang = target_lang
	}
	return url(t)
}

action = obj() // {name->handler}

// given a url (in encoded form), find its action and return the handler.
let action_handler = function(url_s) {
	let t = url_arg(url_s)
	let act = url_action(t)
	if (act === undefined)
		return
	if (act == '')
		act = config('root_action')
	else // an alias or the act name directly
		act = config('aliases').to_en[act] || act
	act = action_name(act)
	let handler = action[act] // find a handler
	if (!handler) {
		// no handler, find a static template with the same name
		// to be rendered on the #main element or on document.body.
		if (template(act)) {
			handler = function() {
				let main = window.main || document.body
				if (main)
					main.render(act)
			}
		} else if (static_template(act)) {
			handler = function() {
				let main = window.main || document.body
				if (main)
					main.unsafe_html = static_template(act)
			}
		}
	}
	if (!handler)
		return
	let segs = t.segments
	segs.shift() // remove /
	segs.shift() // remove act
	return function(opt) {
		assign(t, opt)
		handler.call(null, segs, t)
	}
}

let loading = true

// check if the action was triggered by a page load or by exec()
function page_loading() {
	return loading
}

function current_url() {
	return location.pathname + location.search + location.hash
}

let ignore_url_changed

let url_changed = function(ev) {
	if (ignore_url_changed)
		return
	let opt = ev && ev.detail || empty
	document.fire('url_changed', opt)
	let handler = action_handler(current_url())
	if (handler)
		handler(opt)
	else
		document.fire('action_not_found', opt)
}

document.on('action_not_found', function() {
	if (location.pathname == '/') {
		setflaps('action_not_found')
		return // no home action
	}
	exec('/', {samepage: true})
})

function _save_scroll_state(top) {
	let state = history.state
	if (!state)
		return
	ignore_url_changed = true
	history.replaceState({top: top}, state.title, state.url)
	ignore_url_changed = false
}

let exec_aborted

let abort_exec = function() {
	exec_aborted = true
}

let check_exec = function() {
	exec_aborted = false
	document.fire('before_exec', abort_exec)
	return !exec_aborted
}

function exec(url, opt) {
	opt = opt || {}
	opt.prev_url = current_url()
	if (!check_exec())
		return
	_save_scroll_state(window.scrollY)
	url = href(url)
	if (opt.samepage)
		history.replaceState(null, null, url)
	else {
		if (window.location.href == (new URL(url, document.baseURI)).href)
			return
		history.pushState(null, null, url)
	}
	let ev = new PopStateEvent('popstate')
	ev.detail = opt
	window.fire(ev)
}

function back() {
	if (!check_exec())
		return
	history.back()
}

// set scroll back to where it was or reset it
function setscroll(top) {
	if (top !== undefined) {
		_save_scroll_state(top)
	} else {
		let state = history.state
		if (!state)
			return
		let top = state.data && state.data.top || 0
	}
	window.scrollTo(0, top)
}

method(Element, 'sethref', function(url, opt) {
	if (this._hooked)
		return
	if (this.attr('target'))
		return
	if (this.attr('href') == '')
		this.attr('href', null)
	url = url || this.attr('href')
	if (!url)
		return
	if (this.bool_attr('samepage') || this.bool_attr('sameplace')) {
		opt = opt || {}
		opt.samepage = this.bool_attr('samepage')
		opt.sameplace = this.bool_attr('sameplace')
	}
	url = href(url)
	this.attr('href', url)
	let handler = action_handler(url)
	if (!handler)
		return
	this.on('click', function(ev) {
		// shit/ctrl+click passes through to open in new window or tab.
		if (ev.shiftKey || ev.ctrlKey)
			return
		ev.preventDefault()
		exec(url, opt)
	})
	this._hooked = true
	return this
})

method(Element, 'sethrefs', function(selector) {
	for (let ce of this.$(selector || 'a[href]'))
		ce.sethref()
	return this
})

bind_component('a', function(e) {
	e.sethref()
}, 'a[href]')

function settitle(title) {
	title = title
		|| $('h1').html()
		|| url(location.pathname).segments[1].replace(/[-_]/g, ' ')
	if (title)
		document.title = title + config('page_title_suffix')
}

function slug(id, s) {
	return (s.upper()
		.replace(/ /g,'-')
		.replace(/[^\w-]+/g,'')
	) + '-' + id
}

function id_arg(s) {
	s = s && s.match(/\d+$/)
	return s && num(s) || ''
}

function opt_arg(s) {
	return s && ('/' + s) || ''
}

// page flaps ----------------------------------------------------------------

{
let cur_cx
flap = {}
function setflaps(new_cx) {
	if (cur_cx == new_cx)
		return
	let cx0 = cur_cx && cur_cx.names().tokeys() || empty
	let cx1 = new_cx && new_cx.names().tokeys() || empty
	for (let cx in cx0)
		if (!cx1[cx]) {
			let handler = flap[cx]
			if (handler)
				handler(false)
		}
	for (let cx in cx1)
		if (!cx0[cx]) {
			let handler = flap[cx]
			if (handler)
				handler(true)
		}
	cur_cx = new_cx
}}

// templates -----------------------------------------------------------------

function template(name) {
	let e = window[name+'_template']
	return e && e.tag == 'script' ? e.html : null
}

function static_template(name) {
	let e = window[name+'_template']
	return e && e.tag == 'template' ? e.html : null
}

function render_string(s, data) {
	return Mustache.render(s, data || obj(), template)
}

function render(template_name, data) {
	let s = template(template_name)
	return render_string(s, data)
}

method(Element, 'render_string', function(s, data, ev) {
	this.unsafe_html = render_string(s, data)
	this.fire('render', data, ev)
	return this
})

method(Element, 'render', function(data, ev) {
	let s = this.template_string
		|| template(this.template || this.attr('template') || this.id || this.tag)
	return this.render_string(s, data, ev)
})

// init ----------------------------------------------------------------------

function init_action() {
	window.on('popstate', function(ev) {
		loading = false
		url_changed(ev)
	})
	if (client_action) // set from server.
		url_changed()
}

} // module scope.
