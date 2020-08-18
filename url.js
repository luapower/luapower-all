/*

	URL encoding & decoding.
	Written by Cosmin Apreutesei. Public domain.

	1. decode: url('a/b?k=v') -> {path: ['a','b'], params: {k:'v'}}
	2. encode: url(['a','b'], {k:'v'}) -> 'a/b?k=v'
	3. update: url('a/b', {k:'v'}) -> 'a/b?k=v'
	4. update: url('a/b?k=v', ['c'], {k:'x'}) -> 'c/b?k=x'

*/

function url(path, params, update) {
	if (typeof path == 'string') { // decode or update
		if (params !== undefined || update !== undefined) { // update
			if (!isarray(params)) { // update params only
				update = params
				params = undefined
			}
			let t = url(path) // decode
			if (params) // update path
				for (let i = 0; i < params.length; i++)
					t.path[i] = params[i]
			if (update) // update params
				for (let k in update)
					t.params[k] = update[k]
			return url(t.path, t.params) // encode back
		} else { // decode
			let i = path.indexOf('?')
			if (i > -1) {
				params = path.substring(i + 1)
				path = path.substring(0, i)
			}
			let a = path.split('/')
			for (let i = 0; i < a.length; i++)
				a[i] = decodeURIComponent(a[i])
			let t = {}
			if (params !== undefined) {
				params = params.split('&')
				for (let i = 0; i < params.length; i++) {
					let kv = params[i].split('=')
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
			return {path: a, params: t}
		}
	} else { // encode
		if (!isarray(path)) {
			params = path.params
			path = path.path
		}
		let a = []
		for (let i = 0; i < path.length; i++)
			a[i] = encodeURIComponent(path[i])
		path = a.join('/')
		a = []
		let pkeys = keys(params).sort()
		for (let i = 0; i < pkeys.length; i++) {
			let pk = pkeys[i]
			let k = encodeURIComponent(pk)
			let v = params[pk]
			if (isarray(v)) {
				for (let j = 0; j < v.length; j++) {
					let z = v[j]
					let kv = k + (z !== true ? '=' + encodeURIComponent(z) : '')
					a.push(kv)
				}
			} else {
				let kv = k + (v !== true ? '=' + encodeURIComponent(v) : '')
				a.push(kv)
			}
		}
		params = a.join('&')
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
