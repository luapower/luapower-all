/*

	WebGL 2 wrapper.
	Written by Cosmin Apreutesei. Public domain.

	Canvas

		gl.clear_all(r, g, b, [a=1], [depth=1])

	Programs

		gl.module(name, code)

		gl.program(name, vs_code, fs_code) -> prog

		prog.set_uni(name, f | v2 | v3 | v4 | x,[y,[z,[w]]])
		prog.set_uni(name, tex, [texture_unit=0])

	VBOs

		gl.[dyn_][arr_]<type>_[instance_]buffer([data|capacity]) -> [d][a]b
			type: f32|u8|u16|u32|i8|i16|i32|v2|v3|v4|mat3|mat4
		gl.[dyn_][arr_][<type>_]index_buffer(data|capacity, [type|max_idx]) -> [d][a]b
			type: u8|u16|u32
		gl.dyn_arr_vertex_buffer({name->type}) -> davb

		b.upload(in_arr, [offset=0], [len=1/0], [in_offset=0])
		b.download(out_arr, [offset=0], [len=1/0], [out_offset=0]) -> out_arr
		b.set(offset, in_b, [len=1/0], [in_offset=0])
		b.arr([data|len]) -> a
		b.len

		db.setlen(len) db.len db.buffer
		db.grow_type(arr|[...]|u8arr|u16arr|u32arr|max_idx, [preserve_contents=true])
		db.grow(cap, [preserve_contents=true], [pow2=true])

		dab.setlen(len) dab.len dab.buffer dab.array
		dab.grow_type(type|max_idx, [preserve_contents=true])
		dab.grow(cap, [preserve_contents=true], [pow2=true])
		dab.set(offset, in_arr, [len=1/0], [in_offset=0])
		dab.remove(offset, [len=1])
		dab.invalidate([offset=0], [len=1/0])
		dab.upload()

		davb.setlen(len) davb.len
		davb.grow(cap, [preserve_contents=true], [pow2=true])
		davb.<name> -> dab
		davb.to_vao(vao)

	UBOs

		gl.ubo(ub_name) -> ubo
		ubo.set(field_name, val)
		ubo.values = {name->val}
		ubo.upload()
		ubo.bind()

	VAOs

		prog.vao() -> vao
		vao.use()
		vao.set_attrs(davb)
		vao.set_attr(name, b)
		vao.set_index(b)
		vao.unuse()
		vao.dab(attr_name, [cap]) -> dab

	Textures

		gl.texture(['cubemap']) -> tex
		tex.set_rgba(w, h, pixels, [side])
		tex.set_u32(w, h, values, [side])
		tex.set_depth(w, h, [f32])
		tex.set_image(image, [pixel_scale], [side])
		tex.load(url, [pixel_scale], [on_load])

	RBOs

		gl.rbo() -> rbo
		rbo.set_rgba(w, h, [n_samples|multisampling])
		rbo.set_depth(w, h, [f32], [n_samples|multisampling])

	FBOs

		gl.fbo() -> fbo
		fbo.bind('read', 'none|back|color', [color_unit=0])
		fbo.bind(['draw'], [ 'none'|'back'|'color'|['none'|'back'|'color',...] ])
		fbo.attach(tex|rbo, 'color|depth|depth_stencil', [color_unit])
		fbo.clear_color(color_unit, r, g, b, [a=1])
		fbo.clear_depth_stencil([depth=1], [stencil=0])
		gl.read_pixels(attachment, color_unit, [buf], [x, y, w, h])
		gl.blit(
			[src_fbo], 'back|color', [color_unit],
			[dst_fbo], [ 'none'|'back'|'color'|['none'|'back'|'color',...] ],
			['color depth stencil'], ['nearest|linear'],
			[sx0], [sy0], [sx1], [sy1],
			[dx0], [dy0], [dx1], [dy1])

	Freeing

		prog|b|db|dab|davb|ubo|vao|tex|rbo|fbo.free()

*/

(function() {

let gl = WebGL2RenderingContext.prototype

// debugging -----------------------------------------------------------------

let methods = {}
let C = {}
for (let name in gl) {
	let d = Object.getOwnPropertyDescriptor(gl, name)
	if (isfunc(d.value) && name != 'getError')
		methods[name] = d.value
	else if (isnum(d.value))
		C[d.value] = name
}
gl.C = C

function count_call(name, args, t) {
	if (name == 'useProgram' && args[0])
		name = name + ' ' + args[0].name
	if (name.starts('uniform'))
		name = name + ' ' + args[0].name
	t[name] = (t[name] || 0) + 1
	t._n++
}

gl.wrap_calls = function() {
	for (let name in methods) {
		let f = methods[name]
		this[name] = function(...args) {
			if (this._trace)
				count_call(name, args, this._trace)
			let ret = f.call(this, ...args)
			let err = this.getError()
			assert(!err, '{0}: {1}', name, C[err])
			return ret
		}
	}
	this.wrap_calls = noop
	return this
}

gl.start_trace = function() {
	this.wrap_calls()
	this._trace = {_n: 0, _t0: time()}
}

gl.stop_trace = function() {
	let t = this._trace
	this._trace = null
	t._t1 = time()
	t._dt_ms = (t._t1 - t._t0) * 1000
	return t
}

// clearing ------------------------------------------------------------------

gl.clear_all = function(r, g, b, a, depth) {
	let gl = this
	if (gl.draw_fbo) {
		// NOTE: not using gl.clear(gl.COLOR_BUFFER_BIT) on a FBO because that
		// clears _all_ color buffers, which we don't want (we clear the
		// secondary color buffers separately with a different value).
		if (r != null)
			gl.draw_fbo.clear_color(0, r, g, b, a)
		gl.draw_fbo.clear_depth_stencil(depth)
	} else {
		if (r != null)
			gl.clearColor(r, g, b, or(a, 1))
		gl.clearDepth(or(depth, 1))
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	}
	gl.enable(gl.DEPTH_TEST)
	gl.depthFunc(gl.LEQUAL)
	gl.enable(gl.POLYGON_OFFSET_FILL)
	return this
}

// programs ------------------------------------------------------------------

let outdent = function(s) {
	s = s
		.replaceAll('\r', '')
		// trim line ends.
		.replaceAll(/[\t ]+\n/g, '\n')
		.replace(/[\t ]+$/, '')
		// trim text of empty lines.
		.replace(/^\n+/, '')
		.replace(/\n+$/, '')
	let indent = s.match(/^[\t ]*/)[0]
	return s.replace(indent, '').replaceAll('\n'+indent, '\n')
}

gl.module = function(name, s) {
	let t = attr(this, 'includes')
	assert(t[name] == null, 'module already exists: {0}', name)
	t[name] = outdent(s)
}

let preprocess = function(gl, code, included) {
	return ('\n' + outdent(code))
		.replaceAll(/\n#include[ \t]+([^\n]+)/g, function(_, name) {
			if (included[name])
				return ''
			included[name] = true
			let inc_code = attr(gl, 'includes')[name]
			assert(inc_code, 'include not found: {0}', name)
			return '\n'+preprocess(gl, inc_code, included)+'\n'
		}).replace(/^\n/, '')
}

let linenumbers = function(s, errors) {
	let t = map()
	for (let match of errors.matchAll(/ERROR\: 0\:(\d+)\: ([^\n]+)/g))
		t.set(num(match[1]), match[2])
	let i = 0
	s = ('\n' + s).replaceAll(/\n/g, function() {
		i++
		return '\n' + (t.has(i) ? t.get(i) + '\n' + '!' : ' ') + (i+'').padStart(4, ' ') + '  '

	}).slice(1)
	return s
}

gl.shader = function(type, name, gl_type, code) {
	let gl = this

	let shader = gl.createShader(gl_type)
	shader.code = code
	shader.raw_code = preprocess(gl, code, {})
	gl.shaderSource(shader, shader.raw_code)
	gl.compileShader(shader)

	if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
		let errors = gl.getShaderInfoLog(shader)
		print(errors)
		print(linenumbers(shader.raw_code, errors))
		gl.deleteShader(shader)
		assert(false, '{0} shader compilation failed for program {1}', type, name)
	}

	return shader
}

let prog = WebGLProgram.prototype

let bt_by_gl_type = {}
let bt_by_type = {}
let bt_by_arr_type = map()
for (let [gl_type, type, arr_type, nc, val_gl_type, nloc] of [
	[gl.FLOAT         , 'f32' , f32arr,  1, null    , 1],
	[gl.UNSIGNED_BYTE , 'u8'  , u8arr ,  1, null    , 1],
	[gl.UNSIGNED_SHORT, 'u16' , u16arr,  1, null    , 1],
	[gl.UNSIGNED_INT  , 'u32' , u32arr,  1, null    , 1],
	[gl.BYTE          , 'i8'  , i8arr ,  1, null    , 1],
	[gl.SHORT         , 'i16' , i16arr,  1, null    , 1],
	[gl.INT           , 'i32' , i32arr,  1, null    , 1],
	[gl.FLOAT_VEC2    , 'v2'  , f32arr,  2, gl.FLOAT, 1],
	[gl.FLOAT_VEC3    , 'v3'  , f32arr,  3, gl.FLOAT, 1],
	[gl.FLOAT_VEC4    , 'v4'  , f32arr,  4, gl.FLOAT, 1],
	[gl.FLOAT_MAT3    , 'mat3', f32arr,  9, gl.FLOAT, 3],
	[gl.FLOAT_MAT4    , 'mat4', f32arr, 16, gl.FLOAT, 4],
]) {
	let bt = {
		gl_type: gl_type,
		val_gl_type: or(val_gl_type, gl_type),
		type: type,
		arr_type: arr_type,
		nc: nc,
		nloc: nloc,
	}
	bt_by_gl_type[gl_type] = bt
	bt_by_type[type] = bt
	if (nc == 1)
		bt_by_arr_type.set(arr_type, bt)
}

function tex_type(gl_type) {
	return (
			gl_type == gl.SAMPLER_2D   && '2d'
		|| gl_type == gl.SAMPLER_CUBE && 'cubemap'
	)
}

gl.ub = function(name) {
	return assert(this.ubs && this.ubs[name], 'unknown uniform block {0}', name)
}

// NOTE: Each UB gets assigned a static UB binding index (we call it slot).
// NOTE: UBs with the same name must have exactly the same layout, which
// is what makes it possible to use the same UBO with different programs.
// This scheme is wasteful of UB binding indices but the assumption is that
// you'll make just a few very reusable UBOs (one for globals, one for materials).
gl.register_ub = function(ub) {
	let ub0 = attr(this, 'ubs')[ub.name]
	if (ub0) {
		// check that the layouts of ub and ub0 match.
		assert(ub0.size == ub.size)
		assert(ub0.field_count == ub.field_count)
		for (let name in ub.fields) {
			let u1 = ub.fields[name]
			let u0 = ub0.fields[name]
			assert(u1.type      == u0.type)
			assert(u1.size      == u0.size)
			assert(u1.ub_offset == u0.ub_offset)
		}
		return ub0
	} else {
		this.ubs[ub.name] = ub
		this.ub_slot_count = this.ub_slot_count || 0
		ub.slot = this.ub_slot_count++
		return ub
	}
}

gl.program = function(pr_name, vs_code, fs_code) {
	let gl = this

	assert(isstr(pr_name), 'program name required')
	let pr = attr(gl, 'programs')[pr_name]
	if (pr) {
		assert(pr.vs.code == vs_code)
		assert(pr.fs.code == fs_code)
		return pr
	}

	let vs = gl.shader('vertex'  , pr_name, gl.VERTEX_SHADER  , vs_code)
	let fs = gl.shader('fragment', pr_name, gl.FRAGMENT_SHADER, fs_code)
	pr = gl.createProgram()
	gl.attachShader(pr, vs)
	gl.attachShader(pr, fs)
	gl.linkProgram(pr)
	gl.validateProgram(pr)

	if (!gl.getProgramParameter(pr, gl.LINK_STATUS)) {
		print(gl.getProgramInfoLog(pr))
		print('VERTEX SHADER')
		print(vs_code)
		print('FRAGMENT SHADER')
		print(fs_code)
		gl.deleteProgram(pr)
		gl.deleteShader(vs)
		gl.deleteShader(fs)
		assert(false, 'linking failed for program {0}', pr_name)
	}

	// uniforms RTTI.
	pr.uniform_count = gl.getProgramParameter(pr, gl.ACTIVE_UNIFORMS)
	pr.uniforms = {} // {name->u}, excluding UB fields.
	let us = [] // [index->u], including UB fields.
	let n_cubemap = 0
	for (let i = 0, n = pr.uniform_count; i < n; i++) {
		let u = gl.getActiveUniform(pr, i)
		u.location = gl.getUniformLocation(pr, u.name)
		us[i] = u
		if (u.location) { // UBO fields are listed too but don't get a location.
			pr.uniforms[u.name] = u
			u.location.name = u.name
			let tt = tex_type(u.type)
			if (tt)
				u.tex_type = tt
		}
	}

	// UBs RTTI.
	pr.uniform_block_count = gl.getProgramParameter(pr, gl.ACTIVE_UNIFORM_BLOCKS)
	pr.uniform_blocks = {} // {name->ub}
	for (let ubi = 0, ubn = pr.uniform_block_count; ubi < ubn; ubi++) {
		let ub_name = gl.getActiveUniformBlockName(pr, ubi)
		let ub = {
			name: ub_name,
			fields: {}, // {name->u}
		}
		ub.size = gl.getActiveUniformBlockParameter(pr, ubi, gl.UNIFORM_BLOCK_DATA_SIZE)
		let uis = gl.getActiveUniformBlockParameter(pr, ubi, gl.UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES)
		let ubos = gl.getActiveUniforms(pr, uis, gl.UNIFORM_OFFSET)
		for (let i = 0, n = uis.length; i < n; i++) {
			let u = us[uis[i]]
			u.ub_offset = ubos[i]
			ub.fields[u.name] = u
		}
		ub.field_count = uis.length
		ub = gl.register_ub(ub)

		gl.uniformBlockBinding(pr, ubi, ub.slot)
		pr.uniform_blocks[ub_name] = ub
	}

	// assign static texture units to sampler uniforms.
	pr.tex_uniforms = [] // [u1,...]
	let t = {}
	for (let u of us) {
		if (u.tex_type && u.location) {
			t[u.tex_type] = t[u.tex_type] || 0
			u.tex_unit = t[u.tex_type]++
			pr.tex_uniforms.push(u)
		}
	}

	// attributes RTTI.
	pr.attrs = {} // {name->a}
	pr.attr_count = gl.getProgramParameter(pr, gl.ACTIVE_ATTRIBUTES)
	for (let i = 0, n = pr.attr_count; i < n; i++) {
		let info = gl.getActiveAttrib(pr, i)
		let location = gl.getAttribLocation(pr, info.name)
		let a = assign({
				name: info.name,
				size: info.size,
				location: location,
				program: pr,
			}, bt_by_gl_type[info.type])
		pr.attrs[info.name] = a
		pr.attrs[location] = a
	}

	pr.gl = gl
	pr.vs = vs
	pr.fs = fs
	pr.name = pr_name

	gl.programs[pr_name] = pr

	return pr
}

prog.use = function() {
	let gl = this.gl

	if (gl.active_program == this)
		return this

	gl.useProgram(this)
	gl.active_program = this

	// set or clear texture units to previously set values.
	for (let u of this.tex_uniforms)
		gl.bind_texture(u.tex_type, u.value, u.tex_unit)

	return this
}

prog.unuse = function() {
	let gl = this.gl
	assert(gl.active_program == this, 'program not in use: {0}', this.name)
	gl.useProgram(null)
	gl.active_program = null
}

prog.free = function() {
	let pr = this
	let gl = pr.gl
	if (gl.active_vao && gl.active_vao.program == this)
		gl.active_vao.unbind()
	for (let vao of this.vaos)
		gl.deleteVertexArray(vao)
	if (gl.active_program == this)
		this.unuse()
	delete gl.programs[pr.name]
	gl.deleteProgram(pr)
	gl.deleteShader(pr.vs)
	gl.deleteShader(pr.fs)
	this.free = noop
}

// uniforms ------------------------------------------------------------------

prog.set_uni = function(name, x, y, z, w) {
	let gl = this.gl

	let u = this.uniforms[name]
	if (!u)
		return this

	let loc = u.location
	let t = u.type

	if (t == gl.FLOAT || t == gl.INT || t == gl.BOOL) {
		x = x || 0
		if (u.value == null || x != u.value) {
			if (t == gl.FLOAT)
				gl.uniform1f(loc, x)
			else
				gl.uniform1i(loc, x)
			u.value = x
		}
	} else if (t == gl.FLOAT_VEC2) {
		if (x == null) {
			x = 0
			y = 0
		} else if (x.is_v2 || x.is_v3 || x.is_v4) {
			let p = x
			x = p[0]
			y = p[1]
		}
		let v = u.value
		if (!v || x != v[0] || y != v[1]) {
			gl.uniform2f(loc, x, y)
			if (v)
				v.set(x, y)
			else
				u.value = v2(x, y)
		}
	} else if (t == gl.FLOAT_VEC3) {
		if (x == null) {
			x = 0
			y = 0
			z = 0
		} else if (x.is_v3 || x.is_v4) {
			let p = x
			x = p[0]
			y = p[1]
			z = p[2]
		} else if (isnum(x) && y == null) { // 0xRRGGBB -> (r, g, b)
			let c = x
			x = (c >> 16 & 0xff) / 255
			y = (c >>  8 & 0xff) / 255
			z = (c       & 0xff) / 255
		}
		let v = u.value
		if (!v || x != v[0] || y != v[1] || z != v[2]) {
			gl.uniform3f(loc, x, y, z)
			if (v)
				v.set(x, y, z)
			else
				u.value = v3(x, y, z)
		}
	} else if (t == gl.FLOAT_VEC4) {
		if (x == null) {
			x = 0
			y = 0
			z = 0
			w = 1
		} else if (x.is_v3 || x.is_v4) {
			let p = x
			x = p[0]
			y = p[1]
			z = p[2]
			w = p[3]
		} else if (isnum(x) && y == null) { // 0xRRGGBBAA -> (r, g, b, a)
			let c = x
			x = (c >> 24       ) / 255
			y = (c >> 16 & 0xff) / 255
			z = (c >>  8 & 0xff) / 255
			w = (c       & 0xff) / 255
		}
		w = or(w, 1)
		let v = u.value
		if (!v || x != v[0] || y != v[1] || z != v[2] || w != v[3]) {
			gl.uniform4f(loc, x, y, z, w)
			if (v)
				v.set(x, y, z, w)
			else
				u.value = v4(x, y, z, w)
		}
	} else if (t == gl.FLOAT_MAT3) {
		let changed = !u.value || !u.value.equals(x)
		if (u.value)
			u.value.set(x)
		else
			u.value = mat3f32(...x)
		if (changed)
			gl.uniformMatrix3fv(loc, false, u.value)
	} else if (t == gl.FLOAT_MAT4) {
		let changed = !u.value || !u.value.equals(x)
		if (u.value)
			u.value.set(x)
		else
			u.value = mat4f32(...x)
		if (changed)
			gl.uniformMatrix4fv(loc, false, u.value)
	} else if (t == gl.SAMPLER_2D || t == gl.SAMPLER_CUBE) {
		let tex = x
		let tex0 = u.value
		if (tex == tex0)
			return this
		if (tex)
			assert(tex.type == u.tex_type,
				'texture type mismatch {0}, expected {1}', tex.type, u.tex_type)
		gl.bind_texture(u.tex_type, tex, u.tex_unit)
		u.value = tex
		gl.uniform1i(loc, u.tex_unit)
	} else {
		assert(false, 'NYI: {2} uniform (program {0}, uniform {1})',
			this.name, name, C[t])
	}

	return this
}

// UBOs ----------------------------------------------------------------------

gl.ubo = function(ub_name) {
	let gl = this

	let ub = gl.ub(ub_name)

	let b = gl.buffer(ub.size)
	let arr = new ArrayBuffer(ub.size)
	let arr_u8  = new u8arr(arr)
	let arr_f32 = new f32arr(arr)
	let arr_i32 = new i32arr(arr)

	let ubo = {
		name: ub_name,
		buffer: b,
		values: {}, // {name->val}
		tex_values: [],
	}

	ubo.set = function(name, val) {
		if (!ub.fields[name])
			return this
		this.values[name] = val
		return this
	}

	ubo.upload = function() {
		let set_one
		for (let name in this.values) {
			let val = this.values[name]
			let u = ub.fields[name]
			let gl_type = u.type
			let offset = u.ub_offset >> 2
			if (gl_type == gl.INT || gl_type == gl.BOOL) {
				arr_i32[offset] = val
			} else if (gl_type == gl.FLOAT) {
				arr_f32[offset] = val
			} else if (
				   gl_type == gl.FLOAT_VEC2
				|| gl_type == gl.FLOAT_VEC3
				|| gl_type == gl.FLOAT_VEC4
				|| gl_type == gl.FLOAT_MAT3
				|| gl_type == gl.FLOAT_MAT4
			) {
				assert(val.length == bt_by_gl_type[gl_type].nc)
				arr_f32.set(val, offset)
			} else {
				assert(false, 'NYI: {3} field', C[gl_type])
			}
			delete this.values[name]
			set_one = true
		}
		if (set_one)
			b.upload(arr_u8)
		return this
	}

	let slot = ub.slot
	ubo.bind = function() {
		let slots = attr(gl, 'ubo_slots', Array)
		if (slots[slot] != this) {
			gl.bindBufferBase(gl.UNIFORM_BUFFER, slot, b)
			slots[slot] = this
		}
		return this
	}

	return ubo
}

// drawing -------------------------------------------------------------------

gl.draw = function(gl_mode, offset, count) {
	let gl = this
	let vao = gl.active_vao
	let ib = vao.index_buffer
	let n_inst = vao.instance_count
	offset = offset || 0
	if (ib) {
		if (count == null)
			count = ib.len
		if (n_inst != null) {
			// NOTE: don't look for an offset-in-the-instance-buffers arg,
			// that's glDrawElementsInstancedBaseInstance() which is not exposed.
			gl.drawElementsInstanced(gl_mode, count, ib.gl_type, offset, n_inst)
		} else {
			gl.drawElements(gl_mode, count, ib.gl_type, offset)
		}
	} else {
		if (count == null)
			count = vao.vertex_count
		if (n_inst != null) {
			gl.drawArraysInstanced(gl_mode, offset, count, n_inst)
		} else {
			gl.drawArrays(gl_mode, offset, count)
		}
	}
	return this
}

gl.draw_triangles = function(o, n) { return this.draw(gl.TRIANGLES, o, n) }
gl.draw_points    = function(o, n) { return this.draw(gl.POINTS   , o, n) }
gl.draw_lines     = function(o, n) { return this.draw(gl.LINES    , o, n) }

gl.cull = function(which) {
	if (which == this.cull_mode)
		return this
	if (!which) {
		this.disable(gl.CULL_FACE)
	} else {
		this.enable(gl.CULL_FACE)
		this.cullFace(which == 'back' ? gl.BACK : gl.FRONT)
	}
	this.cull_mode = which
	return this
}

// VAOs ----------------------------------------------------------------------

let vao = WebGLVertexArrayObject.prototype

// shared VAO: works with multiple programs but requires hardcoded attr. locations.
gl.vao = function(programs) {
	let gl = this
	let vao = gl.createVertexArray()
	vao.gl = gl
	vao.programs = assert(programs, 'programs required')
	vao.attrs = {}
	for (let prog of programs) {
		for (let name of prog.attrs) {
			let a = prog.attrs[name]
			let a0 = vao.attrs[name]
			if (!a0) {
				a.program = prog
				vao.attrs[name] = a
			} else {
				assert(a0.type == a.type, 'type mismatch {0} from {1} vs {2} from {3}',
					a.type, prog, a0.type, a0.program.name)
				assert(a0.location == a.location, 'location mismatch {0} from {1} vs {2} from {3}',
					a.location, prog, a0.location, a0.program.name)
			}
		}
	}
	return vao
}

// program-specific VAO: only with the program that created it.
prog.vao = function() {
	let gl = this.gl
	let vao = gl.createVertexArray()
	vao.gl = gl
	vao.program = this
	vao.attrs = this.attrs
	vao.buffers = [] // {loc->buffer}
	if (!this.vaos)
		this.vaos = []
	this.vaos.push(vao)
	return vao
}

vao.bind = function() {
	let gl = this.gl
	if (this != gl.active_vao) {
		assert(!gl.active_program || !this.program || gl.active_program == this.program,
			'different active program')
		gl.bindVertexArray(this)
		gl.active_vao = this
	}
}

vao.unbind = function() {
	let gl = this.gl
	assert(gl.active_vao == this, 'vao not bound')
	gl.bindVertexArray(null)
	gl.active_vao = null
}

vao.use = function() {
	let gl = this.gl
	if (this.program) {
		this.program.use()
	} else {
		assert(gl.active_program, 'no active program for shared VAO')
	}
	this.bind()
	return this
}

vao.unuse = function() {
	this.unbind()
	this.program.unuse()
}

vao.set_attr = function(name, b) {
	let gl = this.gl

	let bound = gl.active_vao == this
	assert(bound || !gl.active_vao)

	let a = this.attrs[name]
	if (a == null)
		return this

	let loc = a.location
	let b0 = this.buffers[loc]
	if (b0 == b)
		return this

	if (!bound)
		this.bind()

	gl.bindBuffer(gl.ARRAY_BUFFER, b)

	let nc = a.nc
	let nloc = a.nloc

	if (!b != !b0) {
		for (let i = 0; i < nloc; i++)
			if (b)
				gl.enableVertexAttribArray(loc+i)
			else
				gl.disableVertexAttribArray(loc+i)
	}


	if (b) {
		assert(b.nc == nc && b.nloc == nloc,
			'type mismatch {0}, expected {1} for {2}', b.type, a.type, name)
		if (b.type == 'i32' || b.type == 'u32') {
			gl.vertexAttribIPointer(loc, nc, b.val_gl_type, 0, 0)
		} else if (nloc == 1) {
			gl.vertexAttribPointer(loc, nc, b.val_gl_type, false, 0, 0)
		} else {
			let nc_per_loc = nc / nloc
			let stride = nc * 4
			for (let i = 0; i < nloc; i++) {
				let offset = i * nc_per_loc * 4
				gl.vertexAttribPointer(loc+i, nc_per_loc, b.val_gl_type, false, stride, offset)
			}
		}
	}

	if ((b && b.inst_div || 0) != (b0 && b0.inst_div || 0))
		for (let i = 0; i < nloc; i++)
			gl.vertexAttribDivisor(loc+i, b && b.inst_div || 0)

	if (!bound)
		this.unbind()

	this.buffers[loc] = b

	return this
}

vao.set_attrs = function(davb) {
	assert(davb.is_dyn_arr_vertex_buffer)
	davb.to_vao(this)
	return this
}

property(vao, 'vertex_count', function() {
	let min_len
	if (this.buffers)
		for (let b of this.buffers)
			if (b && !b.inst_div)
				min_len = min(or(min_len, 1/0), b.len)
	return min_len || 0
})

property(vao, 'instance_count', function() {
	let min_len
	if (this.buffers)
		for (let b of this.buffers)
			if (b && b.inst_div)
				min_len = min(or(min_len, 1/0), b.len)
	return min_len || 0
})

vao.set_index = function(b) {
	let gl = this.gl
	let bound = gl.active_vao == this
	assert(bound || !gl.active_vao)
	if (!bound)
		this.bind()
	if (this.index_buffer != b) {
		assert(!b || b.for_index, 'not an index buffer')
		this.index_buffer = b
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, b)
	}
	if (!bound)
		this.unbind()
	return this
}

vao.free = function() {
	this.gl.deleteVertexArray(this)
	this.program.vaos.remove_value(this)
	this.free = noop
}

gl.vao_set = function() {
	let vaos = {}
	let e = {}
	e.vao = function(prog) {
		let vao = vaos[prog.name]
		if (!vao) {
			vao = prog.vao()
			vaos[prog.name] = vao
		}
		return vao
	}
	e.free = function() {
		for (let prog_name in vaos)
			vaos[prog_name].free()
		vaos = null
	}
	return e
}

// VBOs ----------------------------------------------------------------------

function get_bt(type) {
	assert(type, 'type required')
	if (isobject(type)) // custom type
		return type
	return assert(bt_by_type[type], 'unknown type {1}', type)
}

function check_arr_type(arr, arr_type) {
	if (!arr_type)
		return arr.constructor
	assert(arr instanceof arr_type,
		'different arr_type {0}, expected {1}', arr.constructor.name, arr_type.name)
	return arr_type
}

function check_arr_nc(arr, nc) {
	let arr_nc = arr.nc
	nc = or(or(nc, arr_nc), 1)
	assert(or(arr_nc, nc) == nc, 'different number of components {0}, expected {1}', arr_nc, nc)
	return nc
}

function check_arr_len(nc, arr, len, arr_offset) {
	if (len == null && arr.len != null) // dyn_arr
		len = arr.len - arr_offset
	if (len == null) {
		len = arr.length / nc - arr_offset
		assert(len == floor(len), 'array length not multiple of {0}', nc)
	}
	return max(0, len)
}

gl.buffer = function(data_or_cap, type, inst_div, for_index) {
	let gl = this

	data_or_cap = data_or_cap || 0
	inst_div = inst_div || 0
	assert(inst_div == 0 || inst_div == 1, 'NYI: inst_div != 1')

	let bt, cap, len
	if (isnum(data_or_cap)) { // [capacity], [type], ...
		bt = get_bt(type || 'u8')
		cap = data_or_cap
		len = 0
		data_or_cap = cap * bt.nc * bt.arr_type.BYTES_PER_ELEMENT
	} else if (isarray(data_or_cap)) { // [element1, ...], [type], ...
		type = type || data_or_cap.type // take the hint from the array.
		bt = get_bt(type)
		cap = check_arr_len(bt.nc, data_or_cap, null, 0)
		len = cap
		data_or_cap = new bt.arr_type(data_or_cap)
	} else { // arr, [type], ...
		type = type || data_or_cap.type // take the hint from the array.
		if (type) {
			bt = get_bt(type)
			check_arr_type(data_or_cap, bt.arr_type)
			check_arr_nc(data_or_cap, bt.nc)
		} else { // infer type
			let arr_type = check_arr_type(data_or_cap)
			// inferring type based on the array's `nc` would be more aking to
			// speculation than inference, so we're not going to do that.
			let nc = check_arr_nc(data_or_cap, 1)
			bt = assign({}, bt_by_arr_type.get(arr_type))
		}
		cap = check_arr_len(bt.nc, data_or_cap, null, 0)
		len = cap
	}

	let ib0 = for_index && gl.active_vao && gl.active_vao.index_buffer

	let gl_target = for_index ? gl.ELEMENT_ARRAY_BUFFER : gl.ARRAY_BUFFER
	let b = gl.createBuffer()
	gl.bindBuffer(gl_target, b)
	gl.bufferData(gl_target, data_or_cap, gl.STATIC_DRAW)

	if (ib0) // TODO: decide if OpenGL was made by psychotic apes.
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ib0)

	b.gl = gl
	b.capacity = cap
	b._len = len
	assign(b, bt)
	b.for_index = for_index
	b.inst_div = inst_div

	return b
}

function index_bt(data_or_cap, type_or_max_idx) {
	if (!isnum(type_or_max_idx))
		type_or_max_idx = get_bt(type_or_max_idx || 'u8').arr_type
	let arr_type = dyn_arr.index_arr_type(or(type_or_max_idx, or(data_or_cap, 0)))
	return assert(bt_by_arr_type.get(arr_type))
}

gl.index_buffer = function(data_or_cap, type_or_max_idx) {
	let type = index_bt(data_or_cap, type_or_max_idx).type
	return this.buffer(data_or_cap, type, null, true)
}

let buf = WebGLBuffer.prototype

buf.setlen = function(len) {
	assert(len <= this.capacity, 'len exceeds capacity')
	this._len = len
	return this
}

property(buf, 'len', function() { return this._len }, buf.setlen)

buf.arr = function(data_or_len) {
	if (data_or_len == null)
		data_or_len = this.len
	if (isnum(data_or_len))
		data_or_len = data_or_len * this.nc
	else
		check_arr_nc(data_or_len, this.nc)
	let arr = new this.arr_type(data_or_len)
	arr.type = this.type // hint for buffer()
	arr.nc = this.nc
	return arr
}

buf.upload = function(in_arr, offset, len, in_offset) {
	let gl = this.gl
	let nc = this.nc
	if (isarray(in_arr)) { // [...], ...
		in_arr = new this.arr_type(in_arr)
	} else { // arr, ...
		check_arr_type(in_arr, this.arr_type)
		check_arr_nc(in_arr, nc)
	}
	offset = offset || 0
	in_offset = in_offset || 0
	assert(offset >= 0)
	assert(in_offset >= 0)
	len = check_arr_len(nc, in_arr, len, in_offset)
	let bpe = in_arr.BYTES_PER_ELEMENT

	if (!len)
		return this

	gl.bindBuffer(gl.COPY_WRITE_BUFFER, this)
	gl.bufferSubData(gl.COPY_WRITE_BUFFER, offset * nc * bpe, in_arr, in_offset * nc, len * nc)
	this._len = max(this._len, offset + len)

	return this
}

buf.download = function(out_arr, offset, len, out_offset) {
	let gl = this.gl
	let nc = this.nc
	check_arr_type(out_arr, this.arr_type)
	check_arr_nc(out_arr, nc)
	offset = offset || 0
	out_offset = out_offset || 0
	assert(offset >= 0)
	assert(out_offset >= 0)
	if (len == null)
		len = this.len - offset // source dictates len, dest must accomodate.
	let bpe = out_arr.BYTES_PER_ELEMENT

	gl.bindBuffer(gl.COPY_READ_BUFFER, this)
	gl.getBufferSubData(gl.COPY_READ_BUFFER, offset * nc * bpe, out_arr, out_offset * nc, len * nc)

	return out_arr
}

buf.set = function(offset, in_buf, len, in_offset) {
	let gl = this.gl
	let nc = this.nc
	assert(in_buf.arr_type == this.arr_type,
		'different arr_type {0}, expected {1}', in_buf.arr_type.name, this.arr_type.name)
	check_arr_nc(in_buf, nc)
	in_offset = in_offset || 0
	assert(offset >= 0)
	assert(in_offset >= 0)
	if (len == null)
		len = in_buf.len - in_offset
	let bpe = this.arr_type.BYTES_PER_ELEMENT

	gl.bindBuffer(gl.COPY_READ_BUFFER, in_buf)
	gl.bindBuffer(gl.COPY_WRITE_BUFFER, this)
	gl.copyBufferSubData(gl.COPY_READ_BUFFER, gl.COPY_WRITE_BUFFER,
		in_offset * nc * bpe,
		offset * nc * bpe,
		len * nc * bpe)

	this._len = max(this._len, offset + len)

	return this
}

buf.free = function() {
	this.gl.deleteBuffer(this)
}

gl.dyn_buffer = function(type, data_or_cap, inst_div, for_index) {

	let gl = this
	let db = assign({
		is_dyn_buffer: true,
		gl: gl,
		inst_div: inst_div,
		for_index: for_index,
		buffer: null,
		buffer_replaced: noop, // event handler stub
	}, get_bt(type))

	db.grow_type = function(type_or_max_idx, preserve_contents) {
		assert(for_index, 'not an index buffer')
		let bt = index_bt(null, type_or_max_idx)
		if (bt.arr_type.BYTES_PER_ELEMENT <= this.arr_type.BYTES_PER_ELEMENT)
			return
		if (this.buffer) {
			let a1
			if (preserve_contents !== false && this.len > 0) {
				let a0 = this.buffer.download(this.buffer.arr())
				let a1 = new bt.arr_type(this.len)
				a1.set(a0)
			}
			let cap = this.buffer.capacity
			this.buffer.free()
			this.buffer = gl.buffer(cap, bt.type, inst_div, for_index)
			if (a1)
				this.buffer.upload(a1)
			this.buffer_replaced(this.buffer)
		}
		type = bt.type
		assign(this, bt)
		return this
	}

	db.grow = function(cap, preserve_contents, pow2) {
		cap = max(0, cap)
		if ((this.buffer ? this.buffer.capacity : 0) < cap) {
			if (pow2 !== false)
				cap = nextpow2(cap)
			let b0 = this.buffer
			let b1 = gl.buffer(cap, type, inst_div, for_index)
			if (b0) {
				if (preserve_contents !== false)
					b1.set(0, b0)
				b0.free()
			}
			this.buffer = b1
			this.buffer_replaced(b1)
		}
		return this
	}

	db.free = function() {
		if (!this.buffer)
			return
		this.buffer.free()
		this.buffer = null
	}

	db.setlen = function(len) {
		len = max(0, len)
		let buffer = db.grow(len).buffer
		if (buffer)
			buffer.len = len
		return this
	}

	property(db, 'len',
		function() { return db.buffer && db.buffer.len || 0 },
		db.setlen,
	)

	if (data_or_cap != null) {
		if (isnum(data_or_cap)) {
			db.grow(data_or_cap, false)
		} else {
			db.buffer = gl.buffer(data_or_cap, type, inst_div, for_index)
		}
	}

	return db
}

gl.dyn_index_buffer = function(data_or_cap, type_or_max_idx) {
	let type = index_bt(data_or_cap, type_or_max_idx).type
	return this.dyn_buffer(type, data_or_cap, null, true)
}

gl.dyn_arr_buffer = function(type, data_or_cap, inst_div, for_index) {

	let bt = get_bt(type)
	let dab = {is_dyn_arr_buffer: true}
	let db = this.dyn_buffer(type, data_or_cap, inst_div, for_index)
	let da = dyn_arr(bt.arr_type, data_or_cap, bt.nc)

	dab.buffer_replaced = noop
	db.buffer_replaced = function(b) { dab.buffer_replaced(b) }

	dab.setlen = function(len) {
		da.len = len
		return this
	}

	property(dab, 'len',
		function() { return da.len },
		dab.setlen,
	)

	dab.grow_type = function(type_or_max_idx, preserve_contents) {
		da.grow_type(type_or_max_idx, preserve_contents)
		db.grow_type(type_or_max_idx, preserve_contents)
		return this
	}

	dab.grow = function(cap, preserve_contents, pow2) {
		da.grow(cap, preserve_contents, pow2)
	}

	dab.set = function(offset, in_arr, len, in_offset) {
		da.set(offset, in_arr, len, in_offset)
		return this
	}

	dab.remove = function(offset, len) {
		da.remove(offset, len)
		return this
	}

	dab.invalidate = function(offset, len) {
		da.invalidate(offset, len)
		return this
	}

	dab.upload = function() {
		db.len = da.len
		if (db.buffer)
			db.buffer.upload(da.array)
		da.validate()
		return this
	}

	dab.upload_invalid = function() {
		if (!da.invalid)
			return
		db.len = da.len
		db.buffer.upload(da.array, da.invalid_offset1, da.invalid_offset2 - da.invalid_offset1, da.invalid_offset1)
		da.validate()
		return this
	}

	property(dab, 'array', () => da.array)
	property(dab, 'buffer', () => db.buffer)
	property(dab, 'invalid', () => da.invalid)

	return dab
}

gl.dyn_arr_index_buffer = function(data_or_cap, type_or_max_idx) {
	let type = index_bt(data_or_cap, type_or_max_idx).type
	return this.dyn_arr_buffer(type, data_or_cap, null, true)
}

// generate gl.*_buffer() APIs.
for (let type in bt_by_type) {
	gl[type+'_buffer'] = function buffer(data_or_cap) {
		return this.buffer(data_or_cap, type)
	}
	gl[type+'_instance_buffer'] = function instance_buffer(data_or_cap) {
		return this.buffer(data_or_cap, type, 1)
	}
	gl['dyn_'+type+'_buffer'] = function dyn_buffer(data_or_cap) {
		return this.dyn_buffer(type, data_or_cap)
	}
	gl['dyn_'+type+'_instance_buffer'] = function dyn_instance_buffer(data_or_cap) {
		return this.dyn_buffer(type, data_or_cap, 1)
	}
	gl['dyn_arr_'+type+'_buffer'] = function dyn_arr_buffer(data_or_cap) {
		return this.dyn_arr_buffer(type, data_or_cap)
	}
	gl['dyn_arr_'+type+'_instance_buffer'] = function dyn_arr_instance_buffer(data_or_cap) {
		return this.dyn_arr_buffer(type, data_or_cap, 1)
	}
}

// generate gl.*_index_buffer() APIs.
for (let type of ['u8', 'u16', 'u32']) {
	gl[type+'_index_buffer'] = function index_buffer(data_or_cap) {
		return this.index_buffer(data_or_cap, type)
	}
	gl['dyn_'+type+'_index_buffer'] = function dyn_index_buffer(data_or_cap) {
		return this.dyn_index_buffer(data_or_cap, type)
	}
	gl['dyn_arr_'+type+'_index_buffer'] = function dyn_arr_index_buffer(data_or_cap) {
		return this.dyn_arr_index_buffer(data_or_cap, type)
	}
}

vao.dab = function(name, cap) {
	let vao = this
	let a = assert(vao.program.attrs[name], 'invalid attribute {0}', name)
	let dab = vao.gl.dyn_arr_buffer(a.type, cap)
	if (dab.buffer)
		vao.set_attr(name, dab.buffer)
	dab.buffer_replaced = function(b) { vao.set_attr(name, b) }
	return dab
}

gl.dyn_arr_vertex_buffer = function(attrs, cap, inst_div) {

	let e = {dabs: {}, dabs_list: [], is_dyn_arr_vertex_buffer: true}

	let dab0
	for (let name in attrs) {
		let type = attrs[name]
		let bt = get_bt(type)
		let dab = this.dyn_arr_buffer(bt.type, cap, inst_div)
		dab.name = name
		e.dabs[name] = dab
		e.dabs_list.push(dab)
		e[name] = dab
		dab0 = dab0 || dab
	}

	e.setlen = function(len) {
		for (let dab of e.dabs_list)
			dab.len = len
		return this
	}

	property(e, 'len',
		function() {
			return dab0.len
		},
		e.setlen,
	)

	e.grow = function(cap, preserve_contents, pow2) {
		for (let dab of e.dabs_list)
			dab.grow(cap, preserve_contents, pow2)
	}

	e.remove = function(offset, len) {
		for (let dab of e.dabs_list)
			dab.remove(offset, len)
	}

	e.upload = function() {
		for (let dab of e.dabs_list)
			dab.upload()
	}

	e.to_vao = function(vao) {
		for (let dab of e.dabs_list)
			vao.set_attr(dab.name, dab.buffer)
	}

	e.free = function() {
		for (let dab of e.dabs_list)
			dab.free()
	}

	return e
}

gl.dyn_arr_vertex_instance_buffer = function(attrs, cap) {
	return this.dyn_arr_vertex_buffer(attrs, cap, 1)
}

// textures ------------------------------------------------------------------

let tex = WebGLTexture.prototype

let tex_gl_target = function(type) {
	return type == 'cubemap' && gl.TEXTURE_CUBE_MAP || gl.TEXTURE_2D
}

gl.texture = function(type) {
	let gl = this
	let tex = gl.createTexture()
	tex.gl = gl
	tex.type = type || '2d'
	tex.gl_target = tex_gl_target(tex.type)
	return tex
}

gl.bind_texture = function(type, tex1, unit) {
	let gl = this
	type = type || '2d'
	unit = or(unit, -1)
	if (unit < 0)
		unit = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS) + unit
	let units = attr(attr(gl, 'tex_units'), type, Array)
	let tex0 = units[unit]
	if (tex1 == tex0)
		return this

	if (tex1)
		assert(tex1.type == type,
			'texture type mismatch {0}, expected {1}', tex1.type, type)
	if (tex0)
		tex0.unit = null

	gl.activeTexture(gl.TEXTURE0 + unit)
	gl.bindTexture(tex_gl_target(type), tex1)

	units[unit] = tex1
	if (tex1)
		tex1.unit = unit

	return this
}

tex.bind = function(unit) {
	this.gl.bind_texture(this.type, this, unit)
	return this
}

tex.unbind = function() {
	assert(this.unit != null, 'texture not bound')
	this.gl.bind_texture(this.type, null, this.unit)
	return this
}

tex.free = function() {
	let gl = this.gl
	this.gl.deleteTexture(this)
}

tex.set_depth = function(w, h, f32) {
	let gl = this.gl
	assert(this.type == '2d')

	this.bind()
	gl.texImage2D(gl.TEXTURE_2D, 0,
		f32 ? gl.DEPTH_COMPONENT32F : gl.DEPTH_COMPONENT24,
		w, h, 0, gl.DEPTH_COMPONENT, f32 ? gl.FLOAT : gl.UNSIGNED_INT, null)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	this.w = w
	this.h = h
	this.format = 'depth'
	this.attach = 'depth'
	return this
}

let gl_cube_sides = {
	right  : gl.TEXTURE_CUBE_MAP_POSITIVE_X,
	left   : gl.TEXTURE_CUBE_MAP_NEGATIVE_X,
	top    : gl.TEXTURE_CUBE_MAP_POSITIVE_Y,
	bottom : gl.TEXTURE_CUBE_MAP_NEGATIVE_Y,
	front  : gl.TEXTURE_CUBE_MAP_POSITIVE_Z,
	back   : gl.TEXTURE_CUBE_MAP_NEGATIVE_Z,

	posx: gl.TEXTURE_CUBE_MAP_POSITIVE_X,
	negx: gl.TEXTURE_CUBE_MAP_NEGATIVE_X,
	posy: gl.TEXTURE_CUBE_MAP_POSITIVE_Y,
	negy: gl.TEXTURE_CUBE_MAP_NEGATIVE_Y,
	posz: gl.TEXTURE_CUBE_MAP_POSITIVE_Z,
	negz: gl.TEXTURE_CUBE_MAP_NEGATIVE_Z,
}

let tex_side_target = function(tex, side) {
	if (tex.type == 'cubemap') {
		return assert(gl_cube_sides[side], 'invalid cube map texture side {0}', side)
	} else {
		assert(!side)
		return tex.gl_target
	}
}

tex.set_rgba = function(w, h, pixels, side) {
	let gl = this.gl

	this.bind()
	gl.texImage2D(tex_side_target(this, side), 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, pixels)

	this.w = w
	this.h = h
	this.format = 'rgba'
	this.attach = 'color'
	return this
}

tex.set_rgba16 = function(w, h, pixels, side) {
	let gl = this.gl

	this.bind()
	gl.texImage2D(tex_side_target(this, side), 0, gl.RGBA16UI, w, h, 0, gl.RGBA_INTEGER, gl.UNSIGNED_SHORT, pixels)

	this.w = w
	this.h = h
	this.format = 'rgba16'
	this.attach = 'color'
	return this
}

tex.set_u32 = function(w, h, pixels, side) {
	let gl = this.gl

	this.bind()
	gl.texImage2D(tex_side_target(this, side), 0, gl.R32UI, w, h, 0, gl.RED_INTEGER, gl.UNSIGNED_INT, pixels)

	this.w = w
	this.h = h
	this.format = 'u32'
	this.attach = 'color'
	return this
}

let is_pow2 = function(value) {
	return (value & (value - 1)) == 0
}

tex.set_image = function(image, pixel_scale, side) {
	let gl = this.gl
	let gl_target = tex_side_target(this, side)

	this.bind()
	gl.texImage2D(gl_target, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
	if (gl_target == gl.TEXTURE_2D)
		gl.generateMipmap(gl_target)

	let w = image.width
	let h = image.height
	if (!side) {
		pixel_scale = or(pixel_scale, 1)
		this.uv = v2(
			1 / (w * pixel_scale),
			1 / (h * pixel_scale)
		)
		this.image = image
	} else {
		attr(this, 'images')[side] = image
	}
	this.w = w
	this.h = h
	this.format = 'rgba'
	this.attach = 'color'

	return this
}

let missing_pixel_rgba_1x1 = new u8arr([0, 0, 255, 255])

tex.load = function(url, pixel_scale, on_load, side) {
	let tex = this
	let gl = this.gl
	tex.set_rgba(1, 1, missing_pixel_rgba_1x1, side)
	let image = new Image()
	image.crossOrigin = ''
	image.onload = function() {
		tex.set_image(image, pixel_scale, side)
		tex.loading.remove_value(image)
		if (on_load)
			on_load(tex, image, side)
	}
	image.src = url
	attr(tex, 'loading', Array).push(image)
	return tex
}

let parse_wrap = function(s) {
	if (s == 'repeat') return gl.REPEAT
	if (s == 'clamp') return gl.CLAMP_TO_EDGE
	if (s == 'mirror') return gl.MIRRORED_REPEAT
	assert(false, 'invalid wrap value {0}', s)
}

tex.set_wrap = function(wrap_s, wrap_t) {
	let gl = this.gl
	wrap_t = or(wrap_t, wrap_s)

	this.bind()
	gl.texParameteri(this.gl_target, gl.TEXTURE_WRAP_S, parse_wrap(wrap_s))
	gl.texParameteri(this.gl_target, gl.TEXTURE_WRAP_T, parse_wrap(wrap_t))

	return this
}

let parse_filter = function(s) {
	if (s == 'nearest') return gl.NEAREST
	if (s == 'linear' ) return gl.LINEAR
	if (s == 'nearest_mipmap_nearest') return gl.NEAREST_MIPMAP_NEAREST
	if (s == 'linear_mipmap_nearest' ) return gl.LINEAR_MIPMAP_NEAREST
	if (s == 'nearest_mipmap_linear' ) return gl.NEAREST_MIPMAP_LINEAR // default
	if (s == 'linear_mipmap_linear'  ) return gl.LINEAR_MIPMAP_LINEAR
	assert(false, 'invalid filter value {0}', s)
}

tex.set_filter = function(min_filter, mag_filter) {
	let gl = this.gl

	this.bind()
	gl.texParameteri(this.gl_target, gl.TEXTURE_MIN_FILTER, parse_filter(min_filter))
	gl.texParameteri(this.gl_target, gl.TEXTURE_MAG_FILTER, parse_filter(mag_filter))

	return this
}

// RBOs ----------------------------------------------------------------------

let rbo = WebGLRenderbuffer.prototype

gl.rbo = function() {
	let rbo = this.createRenderbuffer()
	rbo.gl = this
	return rbo
}

rbo.bind = function() {
	let gl = this.gl
	gl.bindRenderbuffer(gl.RENDERBUFFER, this)
	return this
}

rbo.unbind = function() {
	let gl = this.gl
	gl.bindRenderbuffer(gl.RENDERBUFFER, null)
}

rbo.free = function() {
	this.gl.deleteRenderBuffer(this)
}

// NOTE: `n_samples` must be the same on _all_ RBOs attached to the same FBO.
// NOTE: can't blit a MSAA FBO onto a MSAA canvas (disable MSAA on the canvas!).
let rbo_set = function(rbo, gl, attach, gl_format, w, h, n_samples) {
	rbo.bind()
	if (n_samples != null) {
		n_samples = min(repl(n_samples, true, 4), gl.getParameter(gl.MAX_SAMPLES))
		gl.renderbufferStorageMultisample(gl.RENDERBUFFER, rbo.n_samples, gl_format, w, h)
	} else {
		n_samples = 1
		gl.renderbufferStorage(gl.RENDERBUFFER, gl_format, w, h)
	}
	rbo.w = w
	rbo.h = h
	rbo.n_samples = n_samples
	rbo.attach = attach
	return rbo
}

rbo.set_rgba = function(w, h, n_samples) {
	return rbo_set(this, this.gl, 'color', this.gl.RGBA8, w, h, n_samples)
}

rbo.set_depth = function(w, h, f32, n_samples) {
	let gl = this.gl
	let gl_format = f32 ? gl.DEPTH_COMPONENT32F : gl.DEPTH_COMPONENT24
	return rbo_set(this, gl, 'depth', gl_format, w, h, n_samples)
}

// FBOs ----------------------------------------------------------------------

let fbo = WebGLFramebuffer.prototype

gl.fbo = function() {
	let fbo = this.createFramebuffer()
	fbo.gl = this
	fbo.attachments = {}
	return fbo
}

let parse_attachment = function(gl, s, i) {
	if (s == 'color') return gl.COLOR_ATTACHMENT0 + i
	if (s == 'back') return gl.BACK
	if (s == 'none') return gl.NONE
	return assert(s, 'invalid attachment {0}', s)
}

gl.set_read_buffer = function(attachment, color_unit) {
	this.readBuffer(parse_attachment(this, attachment, color_unit))
}

gl.set_draw_buffers = function(attachments) {
	if (!isarray(attachments))
		attachments = [attachments || 'color']
	this.drawBuffers(attachments.map((s, i) => parse_attachment(this, s, i)))
}

fbo.bind = function(mode, attachments, color_unit) {
	let gl = this.gl
	if (gl.active_vao)
		gl.active_vao.unuse()
	else if (gl.active_program)
		gl.active_program.unuse()
	let gl_target
	if (mode == 'read') {
		if (this != gl.read_fbo) {
			gl.bindFramebuffer(gl.READ_FRAMEBUFFER, this)
			gl.read_fbo = this
		}
		let att = parse_attachment(gl, attachments || 'color', color_unit || 0)
		if (this.read_attachment != att) {
			gl.readBuffer(att)
			this.read_attachment = att
		}
	} else if (!mode || mode == 'draw') {
		if (this != gl.draw_fbo) {
			gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, this)
			gl.draw_fbo = this
		}
		gl.set_draw_buffers(attachments)
	} else
		assert(false)
	return this
}

gl.blit = function(
	src_fbo, read_attachment, color_unit,
	dst_fbo, draw_attachments,
	mask, filter,
	src_x0, src_y0, src_x1, src_y1,
	dst_x0, dst_y0, dst_x1, dst_y1
) {
	let gl = this

	assert(!gl.read_fbo)
	assert(!gl.draw_fbo)

	if (src_fbo) {
		src_fbo.bind('read', read_attachment, color_unit)
	} else {
		gl.set_read_buffer(read_attachment, color_unit)
	}

	if (dst_fbo) {
		dst_fbo.bind('draw', draw_attachments)
	} else {
		gl.set_draw_buffers(draw_attachments)
	}

	if (src_x0 == null) {
		src_x0 = 0
		src_y0 = 0
		src_x1 = src_fbo.w
		src_y1 = src_fbo.h
	} else {
		assert(src_x0 != null)
		assert(src_y0 != null)
		assert(src_x1 != null)
		assert(src_y1 != null)
	}

	if (dst_x0 == null) {
		dst_x0 = 0
		dst_y0 = 0
		dst_x1 = dst_fbo.w
		dst_y1 = dst_fbo.h
	} else {
		assert(dst_x0 != null)
		assert(dst_y0 != null)
		assert(dst_x1 != null)
		assert(dst_y1 != null)
	}

	mask = mask && (
			(mask.includes('color') && gl.COLOR_BUFFER_BIT || 0) ||
			(mask.includes('depth') && gl.DEPTH_BUFFER_BIT || 0) ||
			(mask.includes('stencil') && gl.STENCIL_BUFFER_BIT || 0)
		) || gl.COLOR_BUFFER_BIT

	filter = filter && (
			(filter.includes('nearest') && gl.NEAREST || 0) ||
			(filter.includes('linear') && gl.LINEAR || 0)
		) || gl.NEAREST

	gl.blitFramebuffer(
		src_x0, src_y0, src_x1, src_y1,
		dst_x0, dst_y0, dst_x1, dst_y1,
		mask, filter
	)

	if (src_fbo) src_fbo.unbind()
	if (dst_fbo) dst_fbo.unbind()
}

// NOTE: this is a total performance killer, use sparringly!
fbo.read_pixels = function(attachment, color_unit, buf, x, y, w, h) {
	let gl = this.gl
	let fbo = this
	assert(!gl.read_fbo)
	if (x == null) {
		x = 0
		y = 0
		w = fbo.w
		h = fbo.h
	} else {
		assert(x != null)
		assert(y != null)
	}
	assert(w != null)
	assert(h != null)

	fbo.bind('read', attachment, color_unit)
	let tex = assert(this.attachment(attachment, color_unit))
	if (tex.format == 'rgba') {
		if (!buf) {
			buf = new u8arr(w * h * 4)
		} else {
			check_arr_type(buf, u8arr)
		}
		gl.readPixels(0, 0, w, h, gl.RGBA, gl.UNSIGNED_BYTE, buf)
	} else if (tex.format == 'rgba16') {
		if (!buf) {
			buf = new u16arr(w * h * 4)
		} else {
			check_arr_type(buf, u16arr)
		}
		gl.readPixels(0, 0, w, h, gl.RGBA_INTEGER, gl.UNSIGNED_SHORT, buf)
	} else if (tex.format == 'u32') {
		if (!buf) {
			buf = new u32arr(w * h)
		} else {
			check_arr_type(buf, u32arr)
		}
		gl.readPixels(0, 0, w, h, gl.RED_INTEGER, gl.UNSIGNED_INT, buf)
	} else {
		assert(false, 'NYI: {0} texture', tex.format)
	}
	fbo.unbind()

	return buf
}

fbo.gl_target = function() {
	let gl = this.gl
	if (gl.read_fbo == this) return gl.READ_FRAMEBUFFER
	if (gl.draw_fbo == this) return gl.DRAW_FRAMEBUFFER
	assert(false, 'fbo not bound')
}

fbo.unbind = function() {
	let gl = this.gl
	if (gl.active_vao)
		gl.active_vao.unuse()
	else if (gl.active_program)
		gl.active_program.unuse()
	if (this == gl.read_fbo) {
		gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null)
		gl.read_fbo = null
	} else if (this == gl.draw_fbo) {
		gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null)
		gl.draw_fbo = null
	} else
		assert(false, 'not the bound fbo')
	return this
}

fbo.free = function() {
	this.gl.deleteFramebuffer(this)
}

fbo.attachment = function(target, color_unit) {
	return this.attachments[target + (color_unit || 0)]
}

let fbo_att = {
	color: gl.COLOR_ATTACHMENT0,
	depth: gl.DEPTH_ATTACHMENT,
	depth_stencil: gl.DEPTH_STENCIL_ATTACHMENT,
}
fbo.attach = function(tex_or_rbo, target, color_unit) {
	let gl = this.gl
	target = target || tex_or_rbo.attach
	color_unit = color_unit || 0
	let gl_attach = assert(fbo_att[target], 'invalid attachment target {0}', target) + color_unit
	if (tex_or_rbo instanceof WebGLRenderbuffer) {
		let rbo = tex_or_rbo
		rbo.bind()
		gl.framebufferRenderbuffer(this.gl_target(), gl_attach, gl.RENDERBUFFER, rbo)
		assert(this.n_samples == null || this.n_samples == rbo.n_samples,
			'different n_samples {0}, was {1}', rbo.n_samples, this.n_samples)
		this.n_samples = rbo.n_samples
	} else if (tex_or_rbo instanceof WebGLTexture) {
		let tex = tex_or_rbo
		gl.framebufferTexture2D(this.gl_target(), gl_attach, gl.TEXTURE_2D, tex, 0)
	} else
		assert(false, 'rbo or texture expected')

	this.w = or(tex_or_rbo.w, this.w)
	this.h = or(tex_or_rbo.h, this.h)

	this.attachments[target + color_unit] = tex_or_rbo

	return this
}

let _c = new f32arr(4)
let _u = new u32arr(4)
fbo.clear_color = function(color_unit, r, g, b, a) {
	let gl = this.gl
	assert(gl.draw_fbo == this, 'not the draw fbo')
	let tex = assert(this.attachment('color', color_unit))
	if (tex.format == 'rgba') {
		_c[0] = r
		_c[1] = g
		_c[2] = b
		_c[3] = or(a, 1)
		gl.clearBufferfv(gl.COLOR, color_unit, _c)
	} else if (tex.format == 'rgba16') {
		_u[0] = r
		_u[1] = g
		_u[2] = b
		_u[3] = or(a, 1)
		gl.clearBufferuiv(gl.COLOR, color_unit, _u)
	} else if (tex.format == 'u32') {
		_u[0] = r
		gl.clearBufferuiv(gl.COLOR, color_unit, _u)
	} else {
		assert(false, 'NYI: {0} texture', tex.format)
	}
}

fbo.clear_depth_stencil = function(depth, stencil) {
	let gl = this.gl
	assert(gl.draw_fbo == this, 'not the draw fbo')
	gl.clearBufferfi(gl.DEPTH_STENCIL, 0, or(depth, 1), or(stencil, 0))
}

}()) // module scope.
