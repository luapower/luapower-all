/*

	JavaScript extended vocabulary of basic tools.
	Written by Cosmin Apreutesei. Public domain.


	clamp(x, x0, x1)
	sign(x)

	s.format(fmt, ...)

	assert(ret, err, ...)

	a.insert(i, e)
	a.remove(i)

	keys(t, [cmp]) -> t
	update(t, [t1], ...) -> t

	json(v) -> s

*/

// math ----------------------------------------------------------------------

floor = Math.floor
ceil = Math.ceil
round = Math.round
abs = Math.abs
min = Math.min
max = Math.max
sqrt = Math.sqrt
random = Math.random

function clamp(x, x0, x1) {
	return min(max(x, or(x0, -1/0)), or(x1, 1/0))
}

// sign() that only returns -1 or 1, never 0, and returns -1 for -0.
function strict_sign(x) {
	return 1/x == 1/-0 ? -1 : (x >= 0 ? 1 : -1)
}

function lerp(x, x0, x1, y0, y1) {
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
}

function num(s, z) {
	let x = parseFloat(s)
	return x != x ? z : x
}

// % that works with negative numbers.
function mod(a, b) {
	return (a % b + b) % b
}

PI = Math.PI
sin = Math.sin
cos = Math.cos
tan = Math.tan

// logic ---------------------------------------------------------------------

// `||` operator that considers `0` and `''` to be truth values.
function or(x, z) { return x != null ? x : z }

// `||` operator that considers `null` to be truth value as well.
function opt(x, z) { return x !== undefined ? x : z }

// `&&` operator that considers `0` and `''` to be truth values.
function and(x, z) { return x != null ? z : x }

function repl(x, v, z) { return x == v ? z : x }

// callbacks -----------------------------------------------------------------

function noop() {}
function return_true() { return true; }

// error handling ------------------------------------------------------------

print = console.log
trace = console.trace

function assert(ret, err, ...args) {
	if (ret == null || ret === false) {
		throw ((err && err.format(...args) || 'assertion failed'))
	}
	return ret
}

// objects -------------------------------------------------------------------

// extend an object with a property, checking for upstream name clashes.
function property(cls, prop, descriptor) {
	let proto = cls.prototype || cls
	assert(!(prop in proto), '{0}.{1} already exists', cls.name, prop)
	Object.defineProperty(proto, prop, descriptor)
}

// extend an object with a method, checking for upstream name clashes.
// NOTE: does not actually create methods but "data properties" which happen
// to have their "value" be a function object. These can be called like
// methods but come before methods in the look-up chain!
function method(cls, meth, func) {
	property(cls, meth, {
		value: func,
		enumerable: false,
	})
}

function override(cls, meth, func) {
	let proto = cls.prototype || cls
	let inherited = proto[meth] || noop
	function wrapper(...args) {
		return func.call(this, inherited, ...args)
	}
	Object.defineProperty(proto, meth, {
		value: wrapper,
		enumerable: false,
	})
}

function getRecursivePropertyDescriptor(obj, key) {
	return Object.prototype.hasOwnProperty.call(obj, key)
		? Object.getOwnPropertyDescriptor(obj, key)
		: getRecursivePropertyDescriptor(Object.getPrototypeOf(obj), key)
}
method(Object, 'getPropertyDescriptor', function(key) {
	return key in this && getRecursivePropertyDescriptor(this, key)
})

function alias(cls, new_name, old_name) {
	let proto = cls.prototype || cls
	let d = proto.getPropertyDescriptor(old_name)
	assert(d, '{0}.{1} does not exist', cls.name, old_name)
	Object.defineProperty(proto, new_name, d)
}

// strings -------------------------------------------------------------------

// usage:
//		'{1} of {0}'.format(total, current)
//		'{1} of {0}'.format([total, current])
//		'{current} of {total}'.format({'current': current, 'total': total})

method(String, 'format', function(...args) {
	let s = this.toString()
	if (!args.length)
		return s
	if (isarray(args[0]))
		args = args[0]
	if (typeof args[0] == 'object')
		for (let k in args)
			s = s.replace(RegExp('\\{' + k + '\\}', 'gi'), args[k])
	else
		for (let i = 0; i < args.length; i++)
			s = s.replace(RegExp('\\{' + i + '\\}', 'gi'), args[i])
	return s
})

alias(String, 'starts', 'startsWith')
alias(String, 'ends'  , 'endsWith')
alias(String, 'upper' , 'toUpperCase')
alias(String, 'lower' , 'toLowerCase')

// stub for getting message strings that can be translated multiple languages.
if (!S)
	function S(label, msg)
		{ return msg }

// arrays --------------------------------------------------------------------

isarray = Array.isArray

method(Array, 'insert', function(i, e) {
	this.splice(i, 0, e)
})

method(Array, 'remove', function(i, n) {
	let v = this[i]
	this.splice(i, or(n, 1))
	return v
})

method(Array, 'remove_value', function(v) {
	let i = this.indexOf(v)
	if (i == -1) return
	this.splice(i, 1)
	return v
})

property(Array, 'last', {get: function() { return this[this.length-1] } })

// hash maps -----------------------------------------------------------------

function keys(o, cmp) {
	let t = Object.keys(o)
	if (typeof sort == 'function')
		t.sort(cmp)
	else if (cmp)
		t.sort()
	return t
}

// like Object.assign() but skips assigning `undefined` values.
function update(dt, ...args) {
	for (let arg of args)
		if (arg != null)
			for (k in arg)
				if (arg[k] !== undefined)
					dt[k] = arg[k]
	return dt
}

function attr(t, k) {
	let v = t[k]
	if (!v) { v = {}; t[k] = v }
	return v
}

function array_attr(t, k) {
	let v = t[k]
	if (!v) { v = []; t[k] = v }
	return v
}

// events --------------------------------------------------------------------

function events_mixin(o) {
	let obs = new Map()
	o.on = function(topic, handler, enable) {
		assert(enable === undefined || typeof enable == 'boolean')
		if (enable !== undefined && enable !== true)
			return o.off(topic, handler)
		if (!handler)
			return
		let handlers = obs.get(topic)
		if (!handlers) {
			handlers = []
			obs.set(topic, handlers)
		}
		handlers.push(handler)
	}
	o.off = function(topic, handler) {
		let handlers = obs.get(topic)
		if (handlers)
			if (handler)
				handlers.remove_value(handler)
			else
				handlers.clear()
	}
	o.once = function(topic, handler) {
		let wrapper = function(...args) {
			let ret = handler(...args)
			o.off(topic, wrapper)
			return ret
		}
		o.on(topic, wrapper)
	}
	o.fire = function(topic, ...args) {
		var a = obs.get(topic)
		if (!a) return
		for (f of a) {
			let ret = f.call(o, ...args)
			if (ret !== undefined)
				return ret
		}
	}
	return o
}

// timestamps ----------------------------------------------------------------

time = Date.now
utctime = Date.UTC

_d = new Date() // public temporary date object.

// get the time at the start of the day of a given time, plus/minus a number of days.
function day(t, offset) {
	_d.setTime(t)
	_d.setMilliseconds(0)
	_d.setSeconds(0)
	_d.setMinutes(0)
	_d.setHours(0)
	_d.setDate(_d.getDate() + (offset || 0))
	return _d.valueOf()
}

// get the time at the start of the month of a given time, plus/minus a number of months.
function month(t, offset) {
	_d.setTime(t)
	_d.setMilliseconds(0)
	_d.setSeconds(0)
	_d.setMinutes(0)
	_d.setHours(0)
	_d.setDate(1)
	_d.setMonth(_d.getMonth() + (offset || 0))
	return _d.valueOf()
}

// get the time at the start of the year of a given time, plus/minus a number of years.
function year(t, offset) {
	_d.setTime(t)
	_d.setMilliseconds(0)
	_d.setSeconds(0)
	_d.setMinutes(0)
	_d.setHours(0)
	_d.setDate(1)
	_d.setMonth(0)
	_d.setFullYear(_d.getFullYear() + (offset || 0))
	return _d.valueOf()
}

// get the time at the start of the week of a given time, plus/minus a number of weeks.
function week(t, offset) {
	_d.setTime(t)
	_d.setMilliseconds(0)
	_d.setSeconds(0)
	_d.setMinutes(0)
	_d.setHours(0)
	let days = -_d.getDay() + week_start_offset()
	if (days > 0) days -= 7
	_d.setDate(_d.getDate() + days + (offset || 0) * 7)
	return _d.valueOf()
}

function days(dt) {
	return dt / (3600 * 24 * 1000)
}

function year_of      (t) { _d.setTime(t); return _d.getFullYear() }
function month_of     (t) { _d.setTime(t); return _d.getMonth() }
function month_day_of (t) { _d.setTime(t); return _d.getDay() }

locale = navigator.language

function weekday_name(t, how) {
	_d.setTime(t)
	return _d.toLocaleDateString(locale, {weekday: how || 'short'})
}

function month_name(t, how) {
	_d.setTime(t)
	return _d.toLocaleDateString(locale, {month: how || 'short'})
}

// no way to get OS locale in JS in 2020. I hate the web.
function week_start_offset() {
	return locale.starts('en') ? 0 : 1
}

// timers --------------------------------------------------------------------

function after(t, f) {
	return setTimeout(f, t * 1000)
}

// serialization -------------------------------------------------------------

json = JSON.stringify
