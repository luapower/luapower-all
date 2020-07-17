/*

	AJAX requests
	Written by Cosmin Apreutesei. Public Domain.

	ajax(req) -> req

	req.send()
	req.abort()

	^slow(show|hide)
	^progress(p, loaded, [total])
	^upload_progress(p, loaded, [total])
	^success(response_object)
	^fail('timeout'|'network'|'abort')
	^fail('http', status, message, body_text)
	^done('success' | 'fail', ...)

*/

function ajax(req) {

	req = update({slow_timeout: 4}, req)
	events_mixin(req)

	let xhr = new XMLHttpRequest()

	let method = req.method || (req.upload ? 'POST' : 'GET')

	xhr.open(method, req.url, true, req.user, req.pass)

	let upload = req.upload
	if (typeof upload == 'object') {
		upload = json(upload)
		xhr.setRequestHeader('content-type', 'application/json')
	}

	xhr.timeout = (req.timeout || 0) * 1000

	if (req.headers)
		for (let h of headers)
			xhr.setRequestHeader(h, headers[h])

	let slow_watch

	function stop_slow_watch() {
		if (slow_watch) {
			clearTimeout(slow_watch)
			slow_watch = null
		}
		if (slow_watch === false) {
			req.fire('slow', false)
			slow_watch = null
		}
	}

	function slow_expired() {
		req.fire('slow', true)
		slow_watch = false
	}

	req.send = function() {
		slow_watch = after(req.slow_timeout, slow_expired)
		xhr.send(upload)
		return req
	}

	// NOTE: only Firefox fires progress events on non-200 responses.
	xhr.onprogress = function(ev) {
		if (ev.loaded > 0)
			stop_slow_watch()
		let p = ev.lengthComputable ? ev.loaded / ev.total : .5
		req.fire('progress', p, ev.loaded, ev.total)
	}

	xhr.upload.onprogress = function(ev) {
		if (ev.loaded > 0)
			stop_slow_watch()
		let p = ev.lengthComputable ? ev.loaded / ev.total : .5
		req.fire('upload_progress', p, ev.loaded, ev.total)
	}

	xhr.ontimeout = function() {
		req.fire('fail', 'timeout')
		req.fire('done', 'fail', 'timeout')
	}

	// NOTE: only fired on network errors like connection refused!
	xhr.onerror = function() {
		req.fire('fail', 'network')
		req.fire('done', 'fail', 'network')
	}

	xhr.onabort = function() {
		req.fire('fail', 'abort')
		req.fire('done', 'fail', 'abort')
	}

	xhr.onreadystatechange = function(ev) {
		if (xhr.readyState > 1)
			stop_slow_watch()
		if (xhr.readyState == 4) {
			if (xhr.status == 200) {
				let res = xhr.response
				if (!xhr.responseType || xhr.responseType == 'text')
					if (xhr.getResponseHeader('content-type') == 'application/json' && res)
						res = JSON.parse(res)
				req.fire('success', res)
				req.fire('done', 'success', res)
			} else if (xhr.status) { // status is 0 for network errors, incl. timeout.
				req.fire('fail', 'http', xhr.status, xhr.statusText, xhr.responseText)
				req.fire('done', 'fail', 'http', xhr.status, xhr.statusText, xhr.responseText)
			}
		}
	}

	req.abort = function() {
		xhr.abort()
		return req
	}

	req.on('slow', req.slow)
	req.on('progress', req.progress)
	req.on('upload_progress', req.upload_progress)
	req.on('done', req.done)
	req.on('fail', req.fail)
	req.on('success', req.success)

	req.xhr = xhr
	return req
}

