/*

	webbjs | ajax requests
	Written by Cosmin Apreutesei. Public Domain.

AJAX REQUESTS

	ajax([url, ]opt) -> xhr               ajax call with bells
	get(url[, success][, opt]) -> xhr
	post(url, data[, success][, opt]) -> xhr

	^slow_loading(show)
	ajax.defaults.slow_loading_delay: 1500
	ajax.defaults.adjust_url: lang_url

	.ajax([url, ]opt)                     trigger ajax events on target
	.get(url[, success][, opt])
	.post(url, data[, success][, opt])
	.abort()                              abort ajax call on target
	.abort_all([filter])                  abort all including on children

	^ajax_success, data, status, xhr
	^ajax_fail, xhr, status, err          failed for any reason
	^ajax_error, xhr, status, err         error, not for abort or timeout
	^ajax_abort, xhr, status, err         call aborted
	^ajax_timeout, xhr, status, err       timed out
	^ajax_complete, xhr, status, data|err completed in any way
	^ajax_slow_loading, show              some time passed before completion
*/

function _ajax_opt(url, opt) {
	var t
	if (typeof(url) == 'string')
		t = update({url: url}, opt)
	else
		t = update({}, url)
	assert(t.url, 'ajax(): url missing')
	return t
}


// +adjust_url filter which defaults to lang_url
// +sends non-string post data as application/json
// +sets type POST when data arg is present
// +callbacks: slow_loading(show|hide)
// +`this` is preserved on ^success, ^error, ^slow_loading.
function ajax(url, opt) {

	opt = update({}, ajax.defaults, _ajax_opt(url, opt))
	var self = this

	if (opt.adjust_url)
		opt.url = opt.adjust_url(opt.url)

	if (typeof(opt.data) !== 'string' || !opt.contentType) {
		opt.data = JSON.stringify(opt.data)
		opt.contentType = 'application/json; charset=utf-8'
	}

	opt.type = opt.type || (opt.data ? 'POST' : 'GET')

	var sl = false
	function slow_loading() {
		if (opt.slow_loading) {
			sl = true
			opt.slow_loading.call(self, true)
		}
	}
	var slow_watch = setTimeout(slow_loading, opt.slow_loading_delay)
	function finish() {
		clearTimeout(slow_watch)
		if (sl)
			opt.slow_loading.call(self, false)
	}

	var success = opt.success
	opt.success = function(data, status, xhr) {
		finish()
		if (success)
			success.call(self, data, status, xhr)
	}

	var error = opt.error
	opt.error = function(xhr, status, err) {
		finish()
		if (error)
			error.call(self, xhr, status, err)
	}

	if (opt.progress)
		opt.xhr = function() {
			var xhr = new window.XMLHttpRequest()
			xhr.addEventListener('progress', opt.progress, false)
			return xhr
		}

	return $.ajax(opt)
}

ajax.defaults = {
	slow_loading_delay: 1500,
	adjust_url: lang_url,
}

// +call signature: (url[, data][, success][, opt])
function _ajax_args(expect_data, arg1, arg2, arg3, arg4) {
	var url, data, success, opt
	if (typeof(arg1) == 'string') { // (url, ...)
		url = arg1
		if (expect_data) { // (url, data, ...)
			data = arg2
			if (typeof(arg3) == 'function') { // (url, data, success, opt)
				success = arg3
				opt = arg4
			} else { // (url, data, opt)
				opt = arg3
			}
		} else if (typeof(arg2) == 'function') { // (url, success, opt)
			success = arg2
			opt = arg3
		} else { // (url, opt)
			opt = arg2
		}
	} else { // (opt)
		opt = arg1
	}
	assert(!(url && opt && opt.url))
	assert(!(data && opt && opt.data))
	assert(!(success && opt && opt.success))
	return update({url: url, data: data, success: success}, opt)
}

function get(arg1, arg2, arg3, arg4) {
	return ajax.call(this, _ajax_args(false, arg1, arg2, arg3, arg4))
}

function post(arg1, arg2, arg3, arg4) {
	return ajax.call(this, _ajax_args(true, arg1, arg2, arg3, arg4))
}

// 1. automatically aborts pending ajax() calls over the same target.
// 2. triggers ajax_success|fail|abort|timeout|error|complete|slow events on the target.
$.fn.ajax = function(url, opt) {

	opt = _ajax_opt(url, opt)
	var self = this
	self.abort()

	var usr_slow_loading = opt.slow_loading
	opt.slow_loading = function(show) {
		self.trigger('ajax_slow_loading', [show])
		if (usr_slow_loading)
			usr_slow_loading.call(self, show)
	}

	var usr_progress = opt.progress
	opt.progress = function(e) {
		self.trigger('ajax_progress', [e])
		if (usr_progress)
			usr_progress.call(self, e)
	}

	var xhr =
		ajax.call(self, opt)
			.done(function(data) {
				self.trigger('ajax_success', [data])
			})
			.fail(function(xhr, status, err) {
				self.trigger('ajax_fail', [xhr, status, err])
				if (status == 'abort' || status == 'timeout')
					self.trigger('ajax_'+status, [xhr, status, err])
				else
					self.trigger('ajax_error', [xhr, status, err])
			})
			.always(function(xhr, status, arg) {
				self.trigger('ajax_complete', [xhr, status, arg])
			})

	self.data('xhr', xhr)

	return xhr
}

$.fn.abort = function() {
	this.each(function() {
		var xhr = $(this).data('xhr')
		if (xhr)
			xhr.abort()
	})
	return this
}

$.fn.abort_all = function(filter) {
	this.find('[data-xhr]').addBack().filter(filter || '*').abort()
	return this
}

var jqget = $.fn.get
$.fn.get = function(arg1, arg2, arg3, arg4) {
	// .get() is a standard jquery method we're overloading
	if (!arg1 || typeof(arg1) == 'number')
		return jqget.call(this, arg1)
	return $(this).ajax(_ajax_args(false, arg1, arg2, arg3, arg4))
}

$.fn.post = function(arg1, arg2, arg3, arg4) {
	return $(this).ajax(_ajax_args(true, arg1, arg2, arg3, arg4))
}

