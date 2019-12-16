/*

	webb | client-side utilities
	Written by Cosmin Apreutesei. Public Domain.

UTIL

	firstname([fullname], [email]) ->s        get name from full name or email
	render_multi_column(template_name, items, col_count)  multi-column templates
	select_map(a, selv)                       generate data to generate <select> elements

UI PATTERNS

	upid(e, attr)

	notify(msg, cls)

	.back-to-top


*/

// string formatting ---------------------------------------------------------

// 'firstname lastname' -> 'firstname'; 'email@domain' -> 'email'
function firstname(name, email) {
	if (name) {
		name = name.trim()
		var a = name.split(' ', 1)
		return a.length > 0 ? a[0] : name
	} else if (email) {
		email = email.trim()
		var a = email.split('@', 1)
		return a.length > 0 ? a[0] : email
	} else {
		return ''
	}
}

// rendering -----------------------------------------------------------------

function render_multi_column(template_name, items, col_count) {
	var s = '<table width=100%>'
	var w = 100 / col_count
	$.each(items, function(i, item) {
		if (i % col_count == 0)
			s = s + '<tr>'
		s = s + '<td width='+w+'% valign=top>' + render(template_name, item) + '</td>'
		if (i % col_count == col_count - 1 || i == items.length)
			s = s + '</tr>'
	})
	s = s + '</table>'
	return s
}

function select_map(a, selv) {
	var t = []
	$.each(a, function(i, v) {
		var o = {value: v}
		if (selv == v)
			o.selected = 'selected'
		t.push(o)
	})
	return t
}

// UI patterns ---------------------------------------------------------------

// find an id attribute in the parents of an element
function upid(e, attr) {
	return parseInt($(e).closest('['+attr+']').attr(attr))
}

// toasty notifications
function notify(msg, cls) {
	$().toasty({
		message: msg,
		position: 'tc',
		autoHide: 1 / (100 * 5 / 60) * 1000 * msg.length, // assume 100 WPM
		messageClass: cls,
	})
}

// address bar, links and scrolling ------------------------------------------

function slug(id, s) {
	return (s.toLowerCase()
		.replace(/ /g,'-')
		.replace(/[^\w-]+/g,'')
	) + '-' + id
}

function intarg(s) {
	s = s && s.match(/\d+$/)
	return s && parseInt(s) || ''
}

function optarg(s) {
	return s && ('/' + s) || ''
}

/*
$(function() {
	$(window).scroll(function() {

	})
})
*/
