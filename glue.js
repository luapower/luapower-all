/*

	JavaScript "assorted lengths of wire" library.
	Written by Cosmin Apreutesei. Public domain.

	types:
		isobject(e)
		isarray(a)
		isobj(t)
		isstr(s)
		isnum(n)
		isbool(b)
		isfunc(f)
	logic:
		or(x, z)
		strict_or(x, z)
		repl(x, v, z)
	math:
		inf
		floor(x) ceil(x) round(x)
		abs(x)
		min(x, y) max(x, y)
		sqrt(x)
		ln(x)
		random()
		PI sin(x) cos(x) tan(x) rad deg
		clamp(x, x0, x1)
		sign(x)
		strict_sign(x)
		lerp(x, x0, x1, y0, y1)
		num(s, z)
		mod(a, b)
		nextpow2(x)
		x.dec([decimals])
		x.base([base], [digits])
	callback stubs:
		noop
		return_true
		return_false
		return_arg
		assert_false
	error handling:
		print(...)
		warn(...)
		debug(...)
		trace()
		assert(v, err, ...) -> v
		stacktrace()
	extending built-in objects:
		property(cls, prop, descriptor | get,set)
		method(cls, method, func)
		override(cls, method, func)
		alias(cls, new_name, old_name)
		override_property_setter(cls, prop, set)
	strings:
		s.subst('{0} {1}', a0, a1, ...)
		s.starts(s)
		s.ends(s)
		s.upper()
		s.lower()
		s.display_name()
		s.cat(sep, ...)
		s.names() -> a
	arrays:
		empty_array
		a.extend(a1)
		a.set(a1)
		a.insert(i, v)
		a.remove(i) -> v
		a.remove_value(v) -> i
		a.remove_values(cond)
		a.last
		a.binsearch(v, cmp, i1, i2)
		a.each(f)
		a.tokeys([v]) -> t
	hash maps:
		obj()
		set()
		map()
		empty
		keys(t)
		assign(dt, t1, ...)
		assign_opt(dt, t1, ...)
		attr(t, k[, cons])
		memoize(f)
	typed arrays:
		[dyn_][f32|i8|u8|i16|u16|i32|u32]arr(arr|[...]|capacity, [nc]) -> [dyn]arr
			.set(in_arr, [offset=0], [len], [in_offset=0])
			.invalidate([offset=0], [len])
			.grow(cap, [preserve_contents=true], [pow2=true])
			.grow_type(arr_type|max_index|[...]|arr, [preserve_contents=true])
			.setlen(len)
	timestamps:
		time() -> ts
		time(y, m, d, H, M, s, ms) -> ts
		time(date_str) -> ts
		[day|month|year|week](ts[, offset]) -> ts
		days(delta_ts) -> ds
		[year|month|week_day|month_day|hours|minutes|seconds]_of(ts)
		set_[year|month|month_day|hours|minutes|seconds](ts)
		locale
		weekday_name (ts, ['long'])
		month_name   (ts, ['long'])
		month_year   (ts, ['long'])
		week_start_offset()
	time formatting:
		ds.duration() -> s
		ts.timeago() -> s
	file size formatting:
		x.filesize(x, [mag], [dec]) -> s
	colors:
		hsl_to_rgb(h, s, L) -> '#rrggbb'
	geometry:
		point_around(cx, cy, r, angle) -> [x, y]
	timers:
		runafter(t, f)
		runevery(t, f)
		clock()
		timer(f)
	serialization:
		json_arg(s) -> t
		json(t) -> s
	clipboard:
		copy_to_clipboard(text, done_func)
	local storage:
		save(key, s)
		load(key) -> s
	url decoding, encoding and updating:
		url_arg(s) -> t
		url(t) -> s
	ajax requests:
		ajax({
			url: s,
			upload: json|s, ...,
			success: f(json|res),
			fail: f(error, 'http'|'timeout'|'network'|'abort'[, status, msg, content]),
			done: f('success'|'fail', ...),
			...
		}) -> req
		get(url, success, [error], [opt]) -> req
		post(url, data, [success], [error], [opt]) -> req
*/

// types ---------------------------------------------------------------------

isobject = e => e != null && typeof e == 'object' // includes arrays, HTMLElements, etc.
isarray = Array.isArray
isobj = t => isobject(t) && (t.constructor == Object || t.constructor === undefined)
isstr = s => typeof s == 'string'
isnum = n => typeof n == 'number'
isbool = b => typeof b == 'boolean'
isfunc = f => typeof f == 'function'

// logic ---------------------------------------------------------------------

// non-shortcircuiting `||` operator for which only `undefined` and `null` are falsey.
function or(x, z) { return x != null ? x : z }

// non-shortcircuiting `||` operator for which only `undefined` is falsey.
function strict_or(x, z) { return x !== undefined ? x : z }

// single-value filter.
function repl(x, v, z) { return x === v ? z : x }

// math ----------------------------------------------------------------------

inf = Infinity
floor = Math.floor
ceil = Math.ceil
round = Math.round
abs = Math.abs
min = Math.min
max = Math.max
sqrt = Math.sqrt
ln = Math.log
random = Math.random
sign = Math.sign

// NOTE: returns x1 if x1 < x0, which enables the idiom
// `a[clamp(i, 0, b.length-1)]` to return undefined when b is empty.
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

function nextpow2(x) {
	return max(0, 2**(ceil(ln(x) / ln(2))))
}

PI  = Math.PI
sin = Math.sin
cos = Math.cos
tan = Math.tan
rad = PI / 180
deg = 180 / PI

asin  = Math.asin
acos  = Math.acos
atan  = Math.atan
atan2 = Math.atan2

Number.prototype.base = function(base, decimals) {
	let s = this.toString(base)
	if (decimals != null)
		s = s.padStart(decimals, '0')
	return s
}
Number.prototype.dec = Number.prototype.toFixed

// callback stubs ------------------------------------------------------------

function noop() {}
function return_true() { return true; }
function return_false() { return false; }
function return_arg(arg) { return arg; }

// error handling ------------------------------------------------------------

print = console.log
warn  = print
debug = print
trace = console.trace

function assert(ret, err, ...args) {
	if (ret == null || ret === false) {
		throw ((err && err.subst(...args) || 'assertion failed'))
	}
	return ret
}

function stacktrace() {
	try {
		throw new Error()
	} catch(e) {
		return e.stack
	}
}

/* extending built-in objects ------------------------------------------------

NOTE: built-in methods are actually "data properties" that shadow normal
methods so if we want to override one we need to replace the property.
These special kinds of methods are also non-enumerable, unlike normal
methods, which is useful if we want to extend Object without injecting
enumerables into it.

*/

// extend an object with a property, checking for upstream name clashes.
function property(cls, prop, get, set) {
	let proto = cls.prototype || cls
	assert(!(prop in proto), '{0}.{1} already exists', cls.type || cls.name, prop)
	let descriptor = isobject(get) ? get : {get: get, set: set}
	Object.defineProperty(proto, prop, descriptor)
}

// extend an object with a method, checking for upstream name clashes.
function method(cls, meth, func) {
	property(cls, meth, {
		value: func,
		enumerable: false,
	})
}

// override a method, with the ability to override a built-in method.
function override(cls, meth, func) {
	let proto = cls.prototype || cls
	let inherited = proto[meth]
	assert(inherited, '{0}.{1} does not exists', cls.type || cls.name, meth)
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
	assert(d, '{0}.{1} does not exist', cls.type || cls.name, old_name)
	Object.defineProperty(proto, new_name, d)
}

// override a property setter in a prototype *or instance*.
function override_property_setter(cls, prop, set) {
	let proto = cls.prototype || cls
	let d0 = proto.getPropertyDescriptor(prop)
	assert(d0, '{0}.{1} does not exist', cls.type || cls.name, prop)
	let inherited = d0.set || noop
	function wrapper(v) {
		return set.call(this, inherited, v)
	}
	d0.set = wrapper
	Object.defineProperty(proto, prop, d0)
}

// strings -------------------------------------------------------------------

// usage:
//		'{1} of {0}'.subst(total, current)
//		'{1} of {0}'.subst([total, current])
//		'{current} of {total}'.subst({'current': current, 'total': total})

method(String, 'subst', function(...args) {
	if (!args.length)
		return this
	if (isarray(args[0]))
		args = args[0]
	if (isobject(args[0]))
		args = args[0]
	return this.replace(/{(\w+)}/g, (match, s) => args[s])
})

alias(String, 'starts', 'startsWith')
alias(String, 'ends'  , 'endsWith')
alias(String, 'upper' , 'toUpperCase')
alias(String, 'lower' , 'toLowerCase')

{
let upper = function(s) {
	return s.toUpperCase()
}
let upper2 = function(s) {
	return ' ' + s.slice(1).toUpperCase()
}
method(String, 'display_name', function() {
	return this.replace(/[\w]/, upper).replace(/(_[\w])/g, upper2)
})
}

{
let non_null = (s) => s != null
function catargs(sep, ...args) {
	return args.filter(non_null).join(sep)
}
method(String, 'cat', catargs)
}

method(String, 'names', function() {
	return this.trim().split(/\s+/)
})

// multi-language stubs replaced in webb_spa.js ------------------------------

// stub for getting message strings that can be translated multiple languages.
if (!window.S)
	function S(label, msg) { return msg }

// stub for getting current language.
if (!window.lang)
	function lang() { return document.documentElement.lang }

// stub for rewriting links to current language.
if (!window.href)
	href = return_arg

// arrays --------------------------------------------------------------------

empty_array = []

method(Array, 'extend', function(a) {
	let i0 = this.length
	let n = a.length
	this.length += n
	for (let i = 0; i < n; i++)
		this[i0+i] = a[i]
	return this
})

method(Array, 'set', function(a) {
	let n = a.length
	this.length = n
	for (let i = 0; i < n; i++)
		this[i] = a[i]
	return this
})

method(Array, 'insert', function(i, v) {
	if (i == null)
		this.push(v)
	else if (i >= this.length)
		this[i] = v
	else
		this.splice(i, 0, v)
	return this
})

method(Array, 'remove', function(i) {
	return this.splice(i, 1)[0]
})

method(Array, 'remove_value', function(v) {
	let i = this.indexOf(v)
	if (i == -1)
		return null
	this.splice(i, 1)
	return i
})

method(Array, 'remove_values', function(cond) {
	let i = 0, j = 0
	while (i < this.length) {
		let v = this[i]
		if (!cond(v, i, this))
			this[j++] = v
		i++
	}
	this.length = j
})

method(Array, 'clear', function() {
	this.length = 0
	return this
})

// move the n elements at i1 to a new position which is an index in the
// array as it stands after the removal of the elements to be moved.
method(Array, 'move', function(i1, n, insert_i) {
	this.splice(insert_i, 0, ...this.splice(i1, n))
})

property(Array, 'last', {
	get: function() { return this[this.length-1] },
	set: function(v) { this[this.length-1] = v }
})

method(Array, 'equals', function(a, i0, i1) {
	i0 = i0 || 0
	i1 = i1 || max(this.length, a.length)
	for (let i = i0; i < i1; i++)
		if (this[i] !== a[i])
			return false
	return true
})

// binary search for an insert position that keeps the array sorted.
// using '<' gives the first insert position, while '<=' gives the last.
{
let cmps = {}
cmps['<' ] = ((a, b) => a <  b)
cmps['>' ] = ((a, b) => a >  b)
cmps['<='] = ((a, b) => a <= b)
cmps['>='] = ((a, b) => a >= b)
method(Array, 'binsearch', function(v, cmp, i1, i2) {
	let lo = or(i1, 0) - 1
	let hi = or(i2, this.length)
	cmp = cmps[cmp || '<'] || cmp
	while (lo + 1 < hi) {
		let mid = (lo + hi) >> 1
		if (cmp(this[mid], v))
			lo = mid
		else
			hi = mid
	}
	return hi
})
}

alias(Array, 'each', 'forEach')

method(Array, 'tokeys', function(v) {
	v = or(v, true)
	let t = obj()
	for (let k of this)
		t[k] = v
	return t
})

// hash maps -----------------------------------------------------------------

obj = () => Object.create(null)
set = (iter) => new Set(iter)
map = (iter) => new Map(iter)

empty = obj()

keys = Object.keys

assign = Object.assign

// like Object.assign() but skips assigning `undefined` values.
function assign_opt(dt, ...ts) {
	for (let t of ts)
		if (t != null)
			for (let k in t)
				if (!t.hasOwnProperty || t.hasOwnProperty(k))
					if (t[k] !== undefined)
						dt[k] = t[k]
	return dt
}

function attr(t, k, cons) {
	cons = cons || Object
	let v = (t instanceof Map) ? t.get(k) : t[k]
	if (v === undefined) {
		v = new cons()
		if (t instanceof Map)
			t.set(k, v)
		else
			t[k] = v
	}
	return v
}

// TOOD: multi-arg memoize.
function memoize(f) {
	let t = new Map()
	return function(x) {
		if (t.has(x))
			return t.get(x)
		else {
			let y = f(x)
			t.set(x, y)
			return y
		}
	}
}

// typed arrays --------------------------------------------------------------

f32arr = Float32Array
i8arr  = Int8Array
u8arr  = Uint8Array
i16arr = Int16Array
u16arr = Uint16Array
i32arr = Int32Array
u32arr = Uint32Array

function max_index_from_array(a) {
	if (a.max_index != null) // hint
		return a.max_index
	let max_idx = 0
	for (let idx of a)
		max_idx = max(max_idx, idx)
	return max_idx
}

function arr_type_from_max_index(max_idx) {
	return max_idx > 65535 && u32arr || max_idx > 255 && u16arr || u8arr
}

// for inferring the data type of gl.ELEMENT_ARRAY_BUFFER VBOs.
function index_arr_type(arg) {
	if (isnum(arg)) // max_idx
		return arr_type_from_max_index(arg)
	if (isarray(arg)) // [...]
		return arr_type_from_max_index(max_index_from_array(arg))
	if (arg.BYTES_PER_ELEMENT) // arr | arr_type
		return arg.constructor.prototype == arg.__proto__ ? arg.constructor : arg
	return assert(arg, 'arr_type required')
}

class dyn_arr_class {

	// NOTE: `nc` is "number of components" useful for storing compound values
	// without having to compute offsets and lengths manually.

	constructor(arr_type, data_or_cap, nc) {
		this.arr_type = arr_type
		this.nc = nc || 1
		this.inv_nc = 1 / this.nc
		this.array = null
		this.invalid = false
		this.invalid_offset1 = null
		this.invalid_offset2 = null

		if (data_or_cap != null) {
			if (isnum(data_or_cap)) {
				let cap = data_or_cap
				this.grow(cap, false, false)
			} else if (data_or_cap) {
				let data = data_or_cap
				let data_len = data.length * this.inv_nc
				assert(data_len == floor(data_len),
					'source array length not multiple of {0}', this.nc)
				this.array = data
				this.array.len = data_len
			}
		}

	}

	grow(cap, preserve_contents, pow2) {
		cap = max(0, cap)
		if (this.capacity < cap) {
			if (pow2 !== false)
				cap = nextpow2(cap)
			let array = new this.arr_type(cap * this.nc)
			array.nc = this.nc
			array.len = this.len
			if (preserve_contents !== false && this.array)
				array.set(this.array)
			this.array = array
		}
		return this
	}

	grow_type(arg, preserve_contents) {
		let arr_type1 = index_arr_type(arg)
		if (arr_type1.BYTES_PER_ELEMENT <= this.arr_type.BYTES_PER_ELEMENT)
			return
		if (this.array) {
			let this_len = this.len
			let array1 = new arr_type1(this.capacity)
			if (preserve_contents !== false)
				for (let i = 0, n = this_len * this.nc; i < n; i++)
					array1[i] = this.array[i]
			array1.nc = this.nc
			array1.len = this_len
			this.array = array1
		}
		this.arr_type = arr_type1
		return this
	}

	set(offset, data, len, data_offset) {

		// check/clamp/slice source.
		data_offset = data_offset || 0
		let data_len
		if (data.nc != null) {
			assert(data.nc == this.nc, 'source array nc is {0}, expected {1}', data.nc, this.nc)
			data_len = or(data.len, data.length)
		} else {
			data_len = data.length * this.inv_nc
			assert(data_len == floor(data_len), 'source array length not multiple of {0}', this.nc)
		}
		assert(data_offset >= 0 && data_offset <= data_len, 'source offset out of range')
		len = clamp(or(len, 1/0), 0, data_len - data_offset)
		if (data_offset != 0 || len != data_len) // gotta make garbage here...
			data = data.subarray(data_offset * this.nc, (data_offset + len) * this.nc)

		assert(offset >= 0, 'offset out of range')

		this.setlen(max(this.len, offset + len))
		this.array.set(data, offset * this.nc)
		this.invalidate(offset, len)

		return this
	}

	remove(offset, len) {
		assert(offset >= 0, 'offset out of range')
		len = max(0, min(or(len, 1), this.len - offset))
		if (len == 0)
			return
		for (let a = this.array, o1 = offset, o2 = offset + len, i = 0; i < len; i++)
			a[o1+i] = a[o2+i]
		this._len -= len
		this.invalidate(offset)
		return this
	}

	setlen(len) {
		len = max(0, len)
		let arr = this.grow(len).array
		if (arr)
			arr.len = len
		if (this.invalid) {
			this.invalid_offset1 = min(this.invalid_offset1, len)
			this.invalid_offset2 = min(this.invalid_offset2, len)
		}
		return this
	}

	invalidate(offset, len) {
		let o1 = max(0, offset || 0)
		len = max(0, or(len, 1/0))
		let o2 = min(o1 + len, this.len)
		o1 = min(or(this.invalid_offset1,  1/0), o1)
		o2 = max(or(this.invalid_offset2, -1/0), o2)
		this.invalid = true
		this.invalid_offset1 = o1
		this.invalid_offset2 = o2
		return this
	}

	validate() {
		this.invalid = false
		this.invalid_offset1 = null
		this.invalid_offset2 = null
	}

}

property(dyn_arr_class, 'capacity',
	function() { return this.array ? this.array.length * this.inv_nc : 0 },
)

property(dyn_arr_class, 'len',
	function() { return this.array ? this.array.len : 0 },
	function(len) { this.setlen(len) }
)

function dyn_arr(arr_type, data_or_cap, nc) {
	return new dyn_arr_class(arr_type, data_or_cap, nc)
}

dyn_arr.index_arr_type = index_arr_type

{
	let dyn_arr_func = function(arr_type) {
		return function(data_or_cap, nc) {
			return new dyn_arr_class(arr_type, data_or_cap, nc)
		}
	}
	dyn_f32arr = dyn_arr_func(f32arr)
	dyn_i8arr  = dyn_arr_func(i8arr)
	dyn_u8arr  = dyn_arr_func(u8arr)
	dyn_i16arr = dyn_arr_func(i16arr)
	dyn_u16arr = dyn_arr_func(u16arr)
	dyn_i32arr = dyn_arr_func(i32arr)
	dyn_u32arr = dyn_arr_func(u32arr)
}

// data structures -----------------------------------------------------------

function freelist(create, init, destroy) {
	let e = []
	e.alloc = function() {
		let e = this.pop()
		if (e)
			init(e)
		else
			e = create()
		return e
	}
	e.release = function(e) {
		destroy(e)
		this.push(e)
	}
	return e
}

// stack with freelist.
function freelist_stack(create, init, destroy) {
	let e = {}
	let stack = []
	let fl = freelist(create, init, destroy)
	e.push = function() {
		let e = fl.alloc()
		stack.push(e)
		return e
	}
	e.pop = function() {
		let e = stack.pop()
		fl.release(e)
		return e
	}
	e.clear = function() {
		while (this.pop());
	}
	e.stack = stack
	return e
}

// timestamps ----------------------------------------------------------------

_d = new Date() // public temporary date object.

// NOTE: months start at 1, and seconds can be fractionary.
function time(y, m, d, H, M, s) {
	if (isnum(y)) {
		_d.setUTCFullYear(y)
		_d.setUTCMonth(or(m, 1) - 1)
		_d.setUTCDate(or(d, 1))
		_d.setUTCHours(H || 0)
		_d.setUTCMinutes(M || 0)
		s = s || 0
		_d.setUTCSeconds(s)
		_d.setUTCMilliseconds((s - floor(s)) * 1000)
		return _d.valueOf() / 1000
	} else if (isstr(y)) {
		return Date.parse(y) / 1000
	} else if (y == null) {
		return Date.now() / 1000
	} else {
		assert(false)
	}
}

// get the time at the start of the day of a given time, plus/minus a number of days.
function day(t, offset) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCMilliseconds(0)
	_d.setUTCSeconds(0)
	_d.setUTCMinutes(0)
	_d.setUTCHours(0)
	_d.setUTCDate(_d.getUTCDate() + (offset || 0))
	return _d.valueOf() / 1000
}

// get the time at the start of the month of a given time, plus/minus a number of months.
function month(t, offset) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCMilliseconds(0)
	_d.setUTCSeconds(0)
	_d.setUTCMinutes(0)
	_d.setUTCHours(0)
	_d.setUTCDate(1)
	_d.setUTCMonth(_d.getUTCMonth() + (offset || 0))
	return _d.valueOf() / 1000
}

// get the time at the start of the year of a given time, plus/minus a number of years.
function year(t, offset) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCMilliseconds(0)
	_d.setUTCSeconds(0)
	_d.setUTCMinutes(0)
	_d.setUTCHours(0)
	_d.setUTCDate(1)
	_d.setUTCMonth(0)
	_d.setUTCFullYear(_d.getUTCFullYear() + (offset || 0))
	return _d.valueOf() / 1000
}

// get the time at the start of the week of a given time, plus/minus a number of weeks.
function week(t, offset) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCMilliseconds(0)
	_d.setUTCSeconds(0)
	_d.setUTCMinutes(0)
	_d.setUTCHours(0)
	let days = -_d.getUTCDay() + week_start_offset()
	if (days > 0) days -= 7
	_d.setUTCDate(_d.getUTCDate() + days + (offset || 0) * 7)
	return _d.valueOf() / 1000
}

function days(dt) {
	if (dt == null) return null
	return dt / (3600 * 24)
}

function year_of      (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCFullYear() }
function month_of     (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCMonth() + 1 }
function week_day_of  (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCDay() }
function month_day_of (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCDate() }
function hours_of     (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCHours() }
function minutes_of   (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCMinutes() }
function seconds_of   (t) { if (t == null) return null; _d.setTime(t * 1000); return _d.getUTCSeconds() }

function set_year(t, x) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCFullYear(x)
	return _d.valueOf() / 1000
}

function set_month(t, x) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCMonth(x)
	return _d.valueOf() / 1000
}

function set_month_day(t, x) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCDate(x)
	return _d.valueOf() / 1000
}

function set_hours(t, x) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCHours(x)
	return _d.valueOf() / 1000
}

function set_minutes(t, x) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCMinutes(x)
	return _d.valueOf() / 1000
}

function set_seconds(t, x) {
	if (t == null) return null
	_d.setTime(t * 1000)
	_d.setUTCSeconds(x)
	return _d.valueOf() / 1000
}

locale = navigator.language

{
	let wd = {short: obj(), long: obj()}

	for (let i = 0; i < 7; i++) {
		_d.setTime(1000 * 3600 * 24 * (3 + i))
		for (let how of ['short', 'long'])
			wd[how][i] = _d.toLocaleDateString(lang() || locale, {weekday: how, timeZone: 'UTC'})
	}

	function weekday_name(t, how) {
		if (t == null) return null
		_d.setTime(t * 1000)
		return wd[how || 'short'][_d.getDay()]
	}

	function month_name(t, how) {
		if (t == null) return null
		_d.setTime(t * 1000)
		return _d.toLocaleDateString(locale, {month: how || 'short'})
	}

	function month_year(t, how) {
		if (t == null) return null
		_d.setTime(t * 1000)
		return _d.toLocaleDateString(locale, {month: how || 'short', year: 'numeric'})
	}
}

// no way to get OS locale in JS in 2020. I hate the web.
function week_start_offset() {
	return locale.starts('en') ? 0 : 1
}

// time formatting -----------------------------------------------------------

method(Number, 'duration', function() {
	let d = this
	if (d > 2 * 365 * 24 * 3600)
		return S('years', '{0} years', d / (365 * 24 * 3600).dec())
	else if (d > 2 * 30.5 * 24 * 3600)
		return S('months', '{0} months', (d / (30.5 * 24 * 3600)).dec())
	else if (d > 1.5 * 24 * 3600)
		return S('days', '{0} days', (d / (24 * 3600)).dec())
	else if (d > 2 * 3600)
		return S('hours', '{0} hours', (d / 3600).dec())
	else if (d > 2 * 60)
		return S('minutes', '{0} minutes', (d / 60).dec())
	else if (d >= 60)
		return S('one_minute', '1 minute')
	else
		return S('seconds', 'seconds')
})

method(Number, 'timeago', function() {
	var d = time() - this
	return (d > -1 ? S('time_ago', '{0} ago') : S('in_time', 'in {0}')).subst(abs(d).duration())
})

// file size formatting ------------------------------------------------------

{
let suffix = [' B', ' KB', ' MB', ' GB', ' TB']
let magnitudes = {KB: 1, MB: 2, GB: 3}
method(Number, 'filesize', function(x, mag, dec) {
	dec = dec || 0
	let i = mag ? magnitudes[mag] : floor(ln(x) / ln(1024))
	let z = x / 1024**i
	let s = z.dec(dec) + suffix[i]
	return s
})
}

// colors --------------------------------------------------------------------

{

// hsl is in (0..360, 0..1, 0..1); rgb is #rrggbb
let h2rgb = function(m1, m2, h) {
	if (h < 0) h = h+1
	if (h > 1) h = h-1
	if (h*6 < 1)
		return m1+(m2-m1)*h*6
	else if (h*2 < 1)
		return m2
	else if (h*3 < 2)
		return m1+(m2-m1)*(2/3-h)*6
	else
		return m1
}

let hex = x => round(255 * x).base(16, 2)

function hsl_to_rgb(h, s, L) {
	h = h / 360
	let m2 = L <= .5 ? L*(s+1) : L+s-L*s
	let m1 = L*2-m2
	return '#' +
		hex(h2rgb(m1, m2, h+1/3)) +
		hex(h2rgb(m1, m2, h)) +
		hex(h2rgb(m1, m2, h-1/3))
}

function hex3(x) {
	return x != null && (
		((x >> 16) & 0xff).base(16, 2) +
		((x >>  8) & 0xff).base(16, 2) +
		( x        & 0xff).base(16, 2)
	)
}

function hex4(x) {
	return x != null && (
		((x >> 24) & 0xff).base(16, 2) +
		((x >> 16) & 0xff).base(16, 2) +
		((x >>  8) & 0xff).base(16, 2) +
		( x        & 0xff).base(16, 2)
	)
}

}

// geometry ------------------------------------------------------------------

// point at a specified angle on a circle.
function point_around(cx, cy, r, angle) {
	angle = rad * angle
	return [
		cx + cos(angle) * r,
		cy + sin(angle) * r
	]
}

// timers --------------------------------------------------------------------

function runafter(t, f) { return setTimeout(f, t * 1000) }
function runevery(t, f) { return setInterval(f, t * 1000) }

function clock() { return performance.now() / 1000 }

function timer(f) {
	let timer_id
	function wrapper() {
		timer_id = null
		f()
	}
	return function(t) {
		if (timer_id != null) {
			clearTimeout(timer_id)
			timer_id = null
		}
		if (t != null && t !== false)
			timer_id = runafter(t, wrapper)
	}
}

// serialization -------------------------------------------------------------

json_arg = (s) => isstr(s) ? JSON.parse(s) : s
json = JSON.stringify

// clipboard -----------------------------------------------------------------

function copy_to_clipboard(text, done) {
	return navigator.clipboard.writeText(text).then(done)
}

// local storage -------------------------------------------------------------

function save(key, s) {
	localStorage.setItem(key, s)
}

function load(key) {
	return localStorage.getItem(key)
}

// URL encoding & decoding ---------------------------------------------------

function url_arg(s) {

	if (!isstr(s))
		return s

	let path, query, fragment

	{
		let i = s.indexOf('#')
		if (i > -1) {
			fragment = path.substring(i + 1)
			path = s.substring(0, i)
		} else
			path = s
	}

	{
		let i = path.indexOf('?')
		if (i > -1) {
			query = path.substring(i + 1)
			path = path.substring(0, i)
		}
	}

	let a = path.split('/')
	for (let i = 0; i < a.length; i++)
		a[i] = decodeURIComponent(a[i])

	let t = obj()
	if (query !== undefined) {
		let args = query.split('&')
		for (let i = 0; i < args.length; i++) {
			let kv = args[i].split('=')
			let k = decodeURIComponent(kv[0])
			let v = kv.length == 1 ? true : decodeURIComponent(kv[1])
			if (t[k] !== undefined) {
				if (isarray(t[k]))
					t[k] = [t[k]]
				t[k].push(v)
			} else {
				t[k] = v
			}
		}
	}

	return {path: path, segments: a, query: query, args: t, fragment: fragment}
}

function url(t) {

	if (!isobject(t))
		return t

	let path, args, fragment

	let segments = isarray(t) ? t : t.segments
	if (segments) {
		let a = []
		for (let i = 0; i < segments.length; i++)
			a[i] = encodeURIComponent(segments[i])
		path = a.join('/')
	} else
		path = t.path

	if (t.args) {
		let a = []
		let pkeys = keys(t.args).sort()
		for (let i = 0; i < pkeys.length; i++) {
			let pk = pkeys[i]
			let k = encodeURIComponent(pk)
			let v = t.args[pk]
			if (isarray(v)) {
				for (let j = 0; j < v.length; j++) {
					let z = v[j]
					let kv = k + (z !== true ? '=' + encodeURIComponent(z) : '')
					a.push(kv)
				}
			} else if (v != null) {
				let kv = k + (v !== true ? '=' + encodeURIComponent(v) : '')
				a.push(kv)
			}
		}
		args = a.join('&')
	} else
		args = t.args

	return path + (args ? '?' + args : '') + (fragment ? '#' + fragment : '')
}

/* AJAX requests -------------------------------------------------------------

	ajax(opt) -> req
		opt.url
		opt.upload: object (sent as json) | s
		opt.timeout (browser default)
		opt.method ('POST' or 'GET' based on req.upload)
		opt.slow_timeout (4)
		opt.headers: {h->v}
		opt.user
		opt.pass
		opt.async (true)
		opt.dont_send (false)
		opt.notify: widget to send 'load' events to

	req.send()
	req.abort()

	^slow(show|hide)
	^progress(p, loaded, [total])
	^upload_progress(p, loaded, [total])
	^success(res)
	^fail(error, 'timeout'|'network'|'abort')
	^fail(error, 'http', status, message, content)
	^done('success' | 'fail', ...)

*/
function ajax(req) {

	req = assign_opt(new EventTarget(), {slow_timeout: 4}, req)

	let xhr = new XMLHttpRequest()

	let method = req.method || (req.upload ? 'POST' : 'GET')
	let async = req.async !== false // NOTE: this is deprecated but that's ok.

	xhr.open(method, url(req.url), async, req.user, req.pass)

	let upload = req.upload
	if (isobj(upload)) {
		upload = json(upload)
		xhr.setRequestHeader('content-type', 'application/json')
	}

	if (async)
		xhr.timeout = (req.timeout || 0) * 1000

	if (req.headers)
		for (let h in req.headers)
			xhr.setRequestHeader(h, req.headers[h])

	let slow_watch

	function stop_slow_watch() {
		if (slow_watch) {
			clearTimeout(slow_watch)
			slow_watch = null
		}
		if (slow_watch === false) {
			fire('slow', false)
			slow_watch = null
		}
	}

	function slow_expired() {
		fire('slow', true)
		slow_watch = false
	}

	req.send = function() {
		fire('start')
		slow_watch = runafter(req.slow_timeout, slow_expired)
		xhr.send(upload)
		return req
	}

	// NOTE: only Firefox fires progress events on non-200 responses.
	xhr.onprogress = function(ev) {
		if (ev.loaded > 0)
			stop_slow_watch()
		let p = ev.lengthComputable ? ev.loaded / ev.total : .5
		fire('progress', p, ev.loaded, ev.total)
	}

	xhr.upload.onprogress = function(ev) {
		if (ev.loaded > 0)
			stop_slow_watch()
		let p = ev.lengthComputable ? ev.loaded / ev.total : .5
		fire('upload_progress', p, ev.loaded, ev.total)
	}

	xhr.ontimeout = function() {
		req.failtype = 'timeout'
		fire('done', 'fail', req.error_message('timeout'), 'timeout')
	}

	// NOTE: only fired on network errors like connection refused!
	xhr.onerror = function() {
		req.failtype = 'network'
		fire('done', 'fail', req.error_message('network'), 'network')
	}

	xhr.onabort = function() {
		req.failtype = 'abort'
		fire('done', 'fail', null, 'abort')
	}

	xhr.onreadystatechange = function(ev) {
		if (xhr.readyState > 1)
			stop_slow_watch()
		if (xhr.readyState == 4) {
			let status = xhr.status
			if (status) { // status is 0 for network errors, incl. timeout.
				let res = xhr.response
				if (!xhr.responseType || xhr.responseType == 'text')
					if (xhr.getResponseHeader('content-type') == 'application/json' && res)
						res = json_arg(res)
				req.response = res
				if (status == 200) {
					fire('done', 'success', res)
				} else {
					req.failtype = 'http'
					let status_message = xhr.statusText
					fire('done', 'fail',
						req.error_message('http', status, status_message, res),
						'http', status, status_message, res)
				}
			}
		}
	}

	req.abort = function() {
		xhr.abort()
		return req
	}

	function fire(name, arg1, ...rest) {
		if (name == 'done')
			fire(arg1, ...rest)

		if (name == 'fail' && arg1 && window.notify)
			window.notify(arg1, 'error')

		req.fire(name, arg1, ...rest)
		if (req[name])
			req[name](arg1, ...rest)

		req.fire('event', name, arg1, ...rest)
		if (req.event)
			req.event(name, arg1, ...rest)

		if (req.notify instanceof EventTarget)
			req.notify.fire('load', name, arg1, ...rest)
		else if (isarray(req.notify)) // multiple targets
			for (target of req.notify)
				target.fire('load', name, arg1, ...rest)

	}

	req.xhr = xhr

	req.error_message = function(type, status, status_message, content) {
		if (type == 'http') {
			return S('error_http', '{error}', {
				status: status,
				status_message: status_message,
				error: (isobj(content) ? content.error : content) || status_message,
			})
		} else if (type == 'network') {
			return S('error_network', 'Network error')
		} else if (type == 'timeout') {
			return S('error_timeout', 'Timed out')
		}
	}

	if (!req.dont_send)
		req.send()

	return req
}

function get(url, success, fail, opt) {
	return ajax(assign({
		url: url,
		success: success,
		fail: fail,
	}, opt))
}

function post(url, upload, success, fail, opt) {
	return ajax(assign({
		url: url,
		upload: upload,
		success: success,
		fail: fail,
	}, opt))
}
