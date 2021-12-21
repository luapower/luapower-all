/*

	WebGL 2 renderer for a 3D model editor.
	Written by Cosmin Apreutesei. Public domain.

	Based on tutorials from learnopengl.com.

	TODO: interlaced vertex buffers.
	TODO: u32 color buffers.

*/

(function() {

let gl = WebGL2RenderingContext.prototype

gl.module('globals', `

	precision highp float;
	precision highp int;

	layout (std140) uniform globals {

		mat4 view;
		mat4 proj;
		mat4 view_proj;
		vec3 view_pos;
		vec2 view_size;
		float view_near;

		vec3 sunlight_pos;
		vec3 sunlight_color;
		float ambient_strength;

		uniform bool enable_shadows;
	};

`)

gl.module('mesh.vs', `

	#version 300 es

	#include globals

	in mat4 model;
	in vec3 pos;
	in vec3 normal;
	in vec2 uv;
	in float disabled;

	out vec3 v_pos;
	out vec3 v_normal;
	out vec2 v_uv;
	flat out float v_disabled;

	vec4 mvp(vec3 pos) {
		return view_proj * model * vec4(pos, 1.0);
	}

`)

gl.module('mesh.fs', `

	#version 300 es

	#include globals

	precision highp float;
	precision highp int;

	uniform vec3 diffuse_color;
	uniform sampler2D diffuse_map;

	in vec3 v_pos;
	in vec3 v_normal;
	in vec2 v_uv;
	flat in float v_disabled;

	layout (location = 0) out vec4 frag_color;

`)

gl.module('phong.vs', `

	#include mesh.vs

	uniform mat4 sdm_view_proj;

	out vec4 v_pos_sdm_view_proj;

	void do_phong() {
		v_pos = vec3(model * vec4(pos, 1.0));
		v_pos_sdm_view_proj = sdm_view_proj * vec4(v_pos, 1.0);
		v_normal = inverse(transpose(mat3(model))) * normal; /* model must be affine! */
		v_uv = uv;
		v_disabled = disabled;
		gl_Position = view_proj * vec4(v_pos, 1.0);
	}

`)

gl.module('phong.fs', `

	#include mesh.fs

	uniform float shininess;
	uniform float specular_strength;

	uniform sampler2D shadow_map;

	in vec4 v_pos_sdm_view_proj;

	float shadow = 0.0;

	void do_phong() {

		float ambient = ambient_strength;

		vec3 normal = normalize(v_normal);

		vec3 light_dir = normalize(sunlight_pos - v_pos);
		float diffuse = max(dot(normal, light_dir), 0.0);

		vec3 view_dir = normalize(view_pos - v_pos);
		vec3 reflect_dir = reflect(-light_dir, normal);
		float specular = specular_strength * pow(max(dot(view_dir, reflect_dir), 0.0), shininess);

		if (enable_shadows) {

			vec3 p = v_pos_sdm_view_proj.xyz / v_pos_sdm_view_proj.w;
			p = p * 0.5 + 0.5;
			float current_depth = p.z;
			float bias = max(0.05 * (1.0 - dot(normal, light_dir)), 0.000001);

			// PCF: soften the shadow.
			vec2 texel_size = 1.0 / vec2(textureSize(shadow_map, 0));
			for (int x = -1; x <= 1; ++x) {
				 for (int y = -1; y <= 1; ++y) {
					  float pcf_depth = texture(shadow_map, p.xy + vec2(x, y) * texel_size).r;
					  shadow += current_depth - bias > pcf_depth ? 1.0 : 0.0;
				 }
			}
			shadow /= 9.0;
		}

		float light = (ambient + (1.0 - shadow) * (diffuse + specular));

		vec4 b_color = vec4(diffuse_color, 1.0);
		vec4 t_color = texture(diffuse_map, v_uv);
		vec4 color = mix(b_color + t_color, vec4(1.0, 1.0, 1.0, 1.0), v_disabled);
		vec4 disabled_color = vec4(0.7, 0.7, 0.7, 1.0);

		frag_color = mix(vec4(light * sunlight_color, 1.0) * color, disabled_color, 0.7 * v_disabled);

	}

`)

gl.scene_renderer = function(r) {

	let gl = this

	r = r || {}

	r.background_color = r.background_color || v4(1, 1, 1, 1)
	r.sunlight_dir     = r.sunlight_dir || v3(0, 1, 0)
	r.sunlight_color   = r.sunlight_color || v3(1, 1, 1)
	r.ambient_strength = or(r.ambient_strength, 0.3)

	r.show_back_faces  = or(r.show_back_faces, false)

	let globals_ubo = gl.ubo('globals')
	globals_ubo.bind()

	let w = 20
	let shadow_depth = sqrt(FAR)
	r.sdm_proj = r.sdm_proj || mat4().ortho(-w, w, -w, w, -shadow_depth, shadow_depth)

	let sdm_view_proj = mat4()
	let sunlight_pos = v3()

	let sdm_prog = gl.program('shadow_map', `
		#version 300 es
		uniform mat4 sdm_view_proj;
		in vec3 pos;
		in mat4 model;
		void main() {
			gl_Position = sdm_view_proj * model * vec4(pos, 1.0);
		}
	`, `
		#version 300 es
		void main() {
			// this is what the GPU does automatically:
			// gl_FragDepth = gl_FragCoord.z;
		}
	`)

	let sdm_tex = gl.texture()
	let sdm_fbo = gl.fbo()

	let sdm_res

	r.update = function() {

		sunlight_pos.set(r.sunlight_dir).set_len(FAR)

		globals_ubo.set('view'             , r.camera.view)
		globals_ubo.set('proj'             , r.camera.proj)
		globals_ubo.set('view_proj'        , r.camera.view_proj)
		globals_ubo.set('view_size'        , r.camera.view_size)
		globals_ubo.set('view_pos'         , r.camera.pos)
		globals_ubo.set('view_near'        , r.camera.near)

		globals_ubo.set('sunlight_pos'     , sunlight_pos)
		globals_ubo.set('sunlight_color'   , r.sunlight_color)
		globals_ubo.set('ambient_strength' , r.ambient_strength)

		globals_ubo.set('enable_shadows'   , r.enable_shadows)

		globals_ubo.upload()

		if (r.enable_shadows) {

			let sunlight_view = mat4()
			sunlight_view.reset()
				.translate(sunlight_pos)
				.look_at(r.sunlight_dir, v3.up)
				.invert()
			mat4.mul(r.sdm_proj, sunlight_view, sdm_view_proj)
			sdm_prog.use()
			sdm_prog.set_uni('sdm_view_proj', sdm_view_proj)
			sdm_prog.unuse()

			let sdm_res1 = or(r.shadow_map_resolution, 1024 * 4)
			if (sdm_res1 != sdm_res) {
				sdm_res = sdm_res1

				sdm_tex.set_depth(sdm_res, sdm_res, true)
				sdm_tex.set_wrap('clamp')

				sdm_fbo.bind()
				sdm_fbo.attach(sdm_tex, 'depth')
				sdm_fbo.unbind()

				gl.set_uni('shadow_map', sdm_tex, 1)

			}

		}

	}

	r.render = function(draw) {

		if (r.enable_shadows) {
			// render depth of scene to sdm texture (from light's perspective).
			sdm_fbo.bind('draw', 'none')
			gl.viewport(0, 0, sdm_res, sdm_res)
			gl.clearDepth(1)
			gl.cull('front') // to get rid of peter paning.
			gl.clear(gl.DEPTH_BUFFER_BIT)
			draw(sdm_prog)
			sdm_fbo.unbind()
		}

		// 2. render scene as normal with shadow mapping (using depth map).
		let cw = gl.canvas.cw
		let ch = gl.canvas.ch
		gl.viewport(0, 0, cw, ch)
		gl.clear_all(...r.background_color)
		gl.cull(r.show_back_faces ? false : 'back')
		draw()
	}

	gl.polygonOffset(1, 0) // make face edges show propertly.

	r.update()

	return r
}

// render-based hit testing --------------------------------------------------

gl.module('hit_test_render.vs', `

	#include mesh.vs

	in uint geom_id;

	flat out uint v_geom_id;
	flat out uint v_inst_id;

	void do_hit_test_render() {
		v_geom_id = geom_id;
		v_inst_id = uint(gl_InstanceID);
	}

`)

gl.module('hit_test_render.fs', `

	#version 300 es

	precision highp float;
	precision highp int;

	flat in uint v_geom_id;
	flat in uint v_inst_id;

	layout (location = 0) out uvec4 frag_color;

	void do_hit_test_render() {
		frag_color.r = v_geom_id >> 16;
		frag_color.g = v_geom_id & 0xffffu;
		frag_color.b = v_inst_id >> 16;
		frag_color.a = v_inst_id & 0xffffu;
	}

`)

gl.hit_test_renderer = function(r) {

	let gl = this

	r = r || {}

	let face_prog = gl.program('hit_face', `

		#include hit_test_render.vs

		void main() {
			gl_Position = mvp(pos);
			do_hit_test_render();
		}

	`, `

		#include hit_test_render.fs

		void main() {
			do_hit_test_render();
		}

	`)

	// NOTE: not used (we do line hit-testing geometrically).
	let line_prog = gl.program('hit_line', `

		#include fat_line.vs
		#include hit_test_render.vs

		void main() {
			gl_Position = fat_line_pos();
			do_hit_test_render();
		}

	`, `

		#include hit_test_render.fs

		void main() {
			do_hit_test_render();
		}

	`)

	let w, h
	let hit_test_map = gl.texture()
	let depth_map = gl.rbo()
	let fbo = gl.fbo()
	let hit_test_arr

	r.render = function(draw) {
		let w1 = floor(gl.canvas.cw)
		let h1 = floor(gl.canvas.ch)
		if (w1 != w || h1 != h) {
			w = w1
			h = h1
			hit_test_map.set_rgba16(w, h)
			hit_test_arr = new u16arr(4 * w * h)
			depth_map.set_depth(w, h, true)
		}
		fbo.bind('draw', ['color'])
		fbo.attach(hit_test_map, 'color')
		fbo.attach(depth_map)
		fbo.clear_color(0, 0xffff, 0xffff, 0xffff, 0xffff)
		gl.clear_all()

		draw(face_prog)
		//draw(line_prog)

		fbo.unbind()
		fbo.read_pixels('color', 0, hit_test_arr)
	}

	let hit = {}
	r.hit_test = function(x, y) {
		if (!hit_test_arr)
			return
		// when the browser is zoomed, mouse coords can be fractional so we need to round them.
		x = round(x)
		y = round(y)
		if (x < 0 || x >= w || y < 0 || y >= h)
			return
		y = (h-1) - y // textures are read upside down...
		let i = 4 * (y * w + x)
		let r = hit_test_arr[i+0]
		let g = hit_test_arr[i+1]
		let b = hit_test_arr[i+2]
		let a = hit_test_arr[i+3]
		let geom_id = ((r << 16) | g) >>> 0
		let inst_id = ((b << 16) | a) >>> 0

		if (geom_id == 0xffffffff || inst_id == 0xffffffff)
			return

		hit.comp_id = geom_id >>> 18 // 32K components
		hit.face_id = geom_id & ((1 << 18) - 1) // 500K faces each
		hit.inst_id = inst_id

		return hit
	}

	return r

}

// face rendering ------------------------------------------------------------

gl.faces_renderer = function() {

	let gl = this

	let e = {
		specular_strength: .2,
		shininess: 5,
		diffuse_color: 0xffffff,
	}

	let prog = this.program('face', `

		#include phong.vs

		in int selected;
		flat out int v_selected;

		void main() {
			do_phong();
			v_selected = selected;
		}

	`, `

		#include phong.fs

		flat in int v_selected;

		void main() {

			do_phong();

			if (v_selected == 1) {
				float x = mod(gl_FragCoord.x, 4.0);
				float y = mod(gl_FragCoord.y, 8.0);
				vec4 disabled_color = vec4(0.7, 0.7, 0.7, 1.0);
				vec4 selected_color = vec4(0.0, 0.0, .8, 1.0);
				frag_color =
					((x >= 0.0 && x <= 1.1 && y >= 0.0 && y <= 0.5) ||
					 (x >= 2.0 && x <= 3.1 && y >= 4.0 && y <= 4.5))
					? mix(selected_color, disabled_color, 0.7 * v_disabled) : frag_color;
			}
		}

	`)

	let vao = prog.vao()

	let draw_ranges = []

	let davb = gl.dyn_arr_vertex_buffer({
		pos      : 'v3',
		normal   : 'v3',
		uv       : 'v2',
		selected : 'i32',
		geom_id  : 'u32',
	})

	let index_dab = gl.dyn_arr_index_buffer()

	let _v0 = v3()
	let _v1 = v3()
	let _uv = v2()

	e.update = function(comp_id, mat_faces_map) {

		// get total vertex count and vertex index count.
		let pt_n = 0
		let pi_n = 0
		for (let mat_inst of mat_faces_map.values()) {
			for (let face of mat_inst) {
				pt_n += face.length
				pi_n += face.triangles().length
			}
		}

		// resize buffers and arrays to fit.
		davb.grow(pt_n, false)
		index_dab.grow_type(pt_n, false)
		index_dab.grow(pi_n, false)

		// populate the arrays.
		let pos      = davb.pos      .array
		let normal   = davb.normal   .array
		let uv       = davb.uv       .array
		let selected = davb.selected .array
		let geom_id  = davb.geom_id  .array
		let index    = index_dab     .array
		let j = 0
		let k = 0
		draw_ranges.length = 0
		for (let [mat, faces] of mat_faces_map) {
			let k0 = k
			for (let face of faces) {
				let j0 = j
				let i, n
				for (i = 0, n = face.length; i < n; i++, j++) {
					let p  = face.get_point(i, _v0)
					let np = face.get_normal(i, _v1)
					let uv = face.uv_at(i, face.uvm, mat.uv, _uv)
					pos[3*j+0] = p[0]
					pos[3*j+1] = p[1]
					pos[3*j+2] = p[2]
					normal[3*j+0] = np[0]
					normal[3*j+1] = np[1]
					normal[3*j+2] = np[2]
					uv[2*j+0] = uv[0]
					uv[2*j+1] = uv[1]
					selected[j] = face.selected
					geom_id[j] = (comp_id << 18) | face.i

				}
				let tris = face.triangles()
				for (i = 0, n = tris.length; i < n; i++, k++) {
					index[k] = j0 + tris[i]
				}
			}
			draw_ranges.push([mat, k0, k - k0])
		}

		// upload all to the GPU.
		davb.setlen(pt_n).upload()
		index_dab.setlen(pi_n).upload()

	}

	let vao_set = gl.vao_set()

	e.draw = function(prog1) {
		if (prog1) {
			if (!(prog1.name == 'hit_face' || prog1.name == 'shadow_map'))
				return
			let vao = vao_set.vao(prog1)
			vao.use()
			vao.set_attrs(davb)
			vao.set_index(index_dab.buffer)
			vao.set_attr('model'   , e.model)
			vao.set_attr('inst_id' , e.inst_id)
			gl.draw_triangles()
		} else {
			vao.use()
			vao.set_attrs(davb)
			vao.set_index(index_dab.buffer)
			vao.set_attr('model'    , e.model)
			vao.set_attr('disabled' , e.disabled)
			for (let [mat, offset, len] of draw_ranges) {
				prog.set_uni('specular_strength' , or(mat.specular_strength, e.specular_strength))
				prog.set_uni('shininess'         , 1 << or(mat.shininess, e.shininess)) // keep this a pow2.
				prog.set_uni('diffuse_color'     , or(mat.diffuse_color, e.diffuse_color))
				prog.set_uni('diffuse_map'       , mat.diffuse_map)
				gl.draw_triangles(offset, len)
			}
		}
	}

	e.free = function() {
		vao.free()
		vao_set.free()
	}

	return e
}

// solid lines rendering -----------------------------------------------------

gl.solid_lines_renderer = function() {

	let gl = this
	let e = {
		base_color: 0x000000,
	}

	let prog = this.program('solid_line', `

		#include mesh.vs

		uniform vec3 base_color;
		in vec3 color;
		flat out vec4 v_color;

		void main() {
			gl_Position = mvp(pos);
			v_color = vec4(base_color + color, 1.0);
			v_disabled = disabled;
		}

	`, `

		#include mesh.fs

		flat in vec4 v_color;

		void main() {
			frag_color = mix(v_color, vec4(0.7, 0.7, 0.7, 1.0), 0.7 * v_disabled);
		}

	`)

	let vao = prog.vao()

	e.draw = function(prog1, has_index) {
		if (prog1)
			return // no shadows or hit-testing.
		if (!e.index && has_index !== false)
			return
		vao.use()
		vao.set_attr('pos', e.pos)
		vao.set_attr('model', e.model)
		vao.set_attr('disabled', e.disabled)
		vao.set_index(e.index)
		prog.set_uni('base_color', e.base_color)
		vao.set_attr('color', e.color)
		gl.draw_lines()
	}

	e.free = function() {
		vao.free()
	}

	return e

}

// solid point rendering -----------------------------------------------------

gl.points_renderer = function(e) {

	let gl = this
	e = assign({
		base_color : 0x000000,
		point_size : 4,
	}, e)

	let prog = this.program('solid_point', `

		#include mesh.vs

		uniform vec3 base_color;
		uniform float point_size;
		in vec3 color;
		flat out vec4 v_color;

		void main() {
			gl_Position = mvp(pos);
			gl_PointSize = point_size;
			v_color = vec4(base_color + color, 1.0);
			v_disabled = disabled;
		}

	`, `

		#include mesh.fs

		flat in vec4 v_color;

		void main() {
			frag_color = mix(v_color, vec4(0.7, 0.7, 0.7, 1.0), 0.7 * v_disabled);
		}

	`)

	let vao = prog.vao()

	e.draw = function(prog1, has_index) {
		if (prog1)
			if (prog1.name != 'hit_point')
				return // no shadows.
		if (!e.index && has_index !== false)
			return
		vao.use()
		prog.set_uni('point_size', e.point_size)
		vao.set_attr('pos', e.pos)
		vao.set_attr('model', e.model)
		vao.set_attr('disabled', e.disabled)
		vao.set_index(e.index)
		prog.set_uni('base_color', e.base_color)
		vao.set_attr('color', e.color)
		gl.draw_points()
	}

	e.free = function() {
		vao.free()
	}

	return e
}

// dashed lines rendering ----------------------------------------------------

gl.dashed_lines_renderer = function(e) {

	let gl = this
	e = assign({
		base_color: 0x000000,
		dash: 1,
		gap: 3,
	}, e)

	// works with gl.LINES drawing mode.
	let prog = this.program('dashed_line', `

		#include mesh.vs

		uniform vec3 base_color;
		in vec3 color;
		out vec4 v_p1;
		flat out vec4 v_p2; // because gl.LAST_VERTEX_CONVENTION.
		flat out vec4 v_color;

		void main() {
			vec4 p = mvp(pos);
			v_p1 = p;
			v_p2 = p;
			v_color = vec4(base_color + color, 1.0);
			gl_Position = p;
			v_disabled = disabled;
		}

	`, `

		#include mesh.fs

		uniform float dash;
		uniform float gap;

		in vec4 v_p1;
		flat in vec4 v_p2; // because GL_LAST_VERTEX_CONVENTION.
		flat in vec4 v_color;

		void main() {
			vec2 p1 = (v_p1.xyz / v_p1.w).xy;
			vec2 p2 = (v_p2.xyz / v_p2.w).xy;
			float dist = length((p1 - p2) * view_size.xy * 0.5);
			if (fract(dist / (dash + gap)) > dash / (dash + gap))
				discard;
			frag_color = mix(v_color, vec4(0.7, 0.7, 0.7, 1.0), 0.7 * v_disabled);
		}

	`)

	let vao = prog.vao()

	e.draw = function(prog1, has_index) {
		if (prog1)
			return // no shadows or hit-testing.
		if (!e.index && has_index !== false)
			return
		vao.use()
		prog.set_uni('dash', e.dash)
		prog.set_uni('gap', e.gap)
		vao.set_attr('pos', e.pos)
		vao.set_attr('model', e.model)
		vao.set_attr('disabled', e.disabled)
		vao.set_index(e.index)
		prog.set_uni('base_color', e.base_color)
		vao.set_attr('color', e.color)
		gl.draw_lines()
	}

	e.free = function() {
		vao.free()
	}

	return e

}

// fat lines rendering -------------------------------------------------------

gl.module('fat_line.vs', `

	#include mesh.vs

	uniform vec3 base_color;
	in vec3 q; // line's other end-point.
	in float dir;

	vec4 shorten_line(vec4 p1, vec4 p2, float cut_w) {
		float t = (cut_w - p2.w) / (p1.w - p2.w);
		return mix(p2, p1, t);
	}

	vec4 fat_line_pos() {

		// line points in NDC.
		vec4 p1 = mvp(pos);
		vec4 p2 = mvp(q);

		// cut the line at near-plane if one of its end-points has w < 0.
		float cut_w = view_near * .5;
		if (p1.w < cut_w && p2.w > cut_w) {
			p1 = shorten_line(p1, p2, cut_w);
		} else if (p2.w < cut_w && p1.w > cut_w) {
			p2 = shorten_line(p2, p1, cut_w);
		}

		// line normal in screen space.
		vec2 s1 = p1.xy / p1.w;
		vec2 s2 = p2.xy / p2.w;
		float nx = s2.x - s1.x;
		float ny = s1.y - s2.y;
		vec2 n = normalize(vec2(ny, nx) * dir) / view_size * 2.0 * p1.w;

		return p1 + vec4(n, 0.0, 0.0);

	}

`)

gl.fat_lines_renderer = function(e) {

	let gl = this
	e = assign({
		base_color: 0x000000,
	}, e)

	let prog = gl.program('fat_line', `

		#include fat_line.vs

		flat out vec4 v_color;

		void main() {
			gl_Position = fat_line_pos();
			v_color = vec4(base_color, 1.0);
			v_disabled = disabled;
		}

	`, `

		#include mesh.fs

		flat in vec4 v_color;

		void main() {
			frag_color = mix(v_color, vec4(0.7, 0.7, 0.7, 1.0), 0.7 * v_disabled);
		}

	`)

	let davb = gl.dyn_arr_vertex_buffer({pos: 'v3', q: 'v3', dir: 'i8'})
	let ib = gl.dyn_arr_index_buffer()

	function set_line_pos(line, i, ps, qs) {

		let p1x = line[0][0]
		let p1y = line[0][1]
		let p1z = line[0][2]
		let p2x = line[1][0]
		let p2y = line[1][1]
		let p2z = line[1][2]

		// each line has 4 points: (p1, p1, p2, p2).
		ps[3*(i+0)+0] = p1x
		ps[3*(i+0)+1] = p1y
		ps[3*(i+0)+2] = p1z

		ps[3*(i+1)+0] = p1x
		ps[3*(i+1)+1] = p1y
		ps[3*(i+1)+2] = p1z

		ps[3*(i+2)+0] = p2x
		ps[3*(i+2)+1] = p2y
		ps[3*(i+2)+2] = p2z

		ps[3*(i+3)+0] = p2x
		ps[3*(i+3)+1] = p2y
		ps[3*(i+3)+2] = p2z

		// each point has access to its opposite point, so (p2, p2, p1, p1).
		qs[3*(i+0)+0] = p2x
		qs[3*(i+0)+1] = p2y
		qs[3*(i+0)+2] = p2z

		qs[3*(i+1)+0] = p2x
		qs[3*(i+1)+1] = p2y
		qs[3*(i+1)+2] = p2z

		qs[3*(i+2)+0] = p1x
		qs[3*(i+2)+1] = p1y
		qs[3*(i+2)+2] = p1z

		qs[3*(i+3)+0] = p1x
		qs[3*(i+3)+1] = p1y
		qs[3*(i+3)+2] = p1z

	}

	e.update_at = function(i, line) {
		let ps = davb.pos.array
		let qs = davb.q.array
		set_line_pos(line, i * 4, ps, qs)
		davb.pos.invalidate(i * 4, 4).upload_invalid()
		davb.q  .invalidate(i * 4, 4).upload_invalid()
	}

	e.update = function(each_line, max_line_count) {

		let vertex_count = 4 * max_line_count
		let index_count  = 6 * max_line_count

		davb.grow(vertex_count, false)

		ib.grow_type(vertex_count-1, false)
		ib.grow(index_count, false)

		let ps = davb.pos.array
		let qs = davb.q.array
		let ds = davb.dir.array
		let is = ib.array

		let i = 0
		let j = 0
		each_line(function(line) {

			set_line_pos(line, i, ps, qs)

			// each point has an alternating normal direction.
			ds[i+0] =  1
			ds[i+1] = -1
			ds[i+2] = -1
			ds[i+3] =  1

			// each line is made of 2 triangles (0, 1, 2) and (1, 3, 2).
			is[j+0] = i+0
			is[j+1] = i+1
			is[j+2] = i+2
			is[j+3] = i+1
			is[j+4] = i+3
			is[j+5] = i+2

			i += 4
			j += 6
		})

		davb.setlen(i).upload()
		ib.setlen(j).upload()
	}

	let vao = prog.vao()

	e.draw = function(prog1) {
		if (prog1)
			if (prog1.name != 'hit_line')
				return // no shadows
		if (!ib.buffer)
			return
		vao.use()
		vao.set_attrs(davb)
		vao.set_attr('model', e.model)
		vao.set_attr('disabled', e.disabled)
		vao.set_index(ib.buffer)
		prog.set_uni('base_color', e.base_color)
		gl.draw_triangles()
	}

	e.free = function() {
		vao.free()
		davb.free()
		pb.free()
		qb.free()
		db.free()
		ib.free()
	}

	return e
}

// parametric geometry generators --------------------------------------------

{

	let len = 6 * 3 * 2
	let pos = new f32arr(len * 3)

	gl.box_geometry = function(reverse_faces) {

		let pos = new f32arr(box3.points.length)
		pos.type = 'v3'
		pos.nc = 3

		let triangle_pis = reverse_faces ? box3.triangle_pis_back : box3.triangle_pis_front

		let e = {
			pos: pos,
			index: triangle_pis,
			len: len,
		}

		e.set = function(xd, yd, zd) {
			for (let i = 0; i < len * 3; i += 3) {
				pos[i+0] = box3.points[i+0] * xd
				pos[i+1] = box3.points[i+1] * yd
				pos[i+2] = box3.points[i+2] * zd
			}
			return this
		}

		return e
	}
}



// skybox --------------------------------------------------------------------

gl.skybox = function(opt) {

	let gl = this
	let e = new EventTarget()

	let prog = gl.program('skybox', `

		#include mesh.vs

		out vec3 v_model_pos;

		void main() {
			v_model_pos = pos.xyz;
			gl_Position = mvp(pos);
		}

	`, `

		#include mesh.fs

		uniform vec3 sky_color;
		uniform vec3 horizon_color;
		uniform vec3 ground_color;
		uniform float exponent;

		uniform samplerCube diffuse_cube_map;

		in vec3 v_model_pos;

		void main() {
			float h = normalize(v_model_pos).y;
			frag_color = vec4(
				mix(
					mix(horizon_color, sky_color * texture(diffuse_cube_map, v_model_pos).xyz, pow(max(h, 0.0), exponent)),
					ground_color,
					1.0-step(0.0, h)
			), 1.0);
		}

	`)

	let geo = gl.box_geometry(true).set(1, 1, 1)
	let pos_buf = gl.buffer(geo.pos)
	let model = mat4f32()
	let model_buf = gl.mat4_instance_buffer(model)
	let index_buf = gl.index_buffer(geo.index)
	let vao = prog.vao()
	vao.set_attr('pos', pos_buf)
	vao.set_attr('model', model_buf)
	vao.set_index(index_buf)

	let cube_map_tex

	e.update_view = function(view_pos) {
		model.reset().set_position(view_pos).scale(FAR)
		model_buf.upload(model)
	}

	e.update = function() {

		prog.use()
		prog.set_uni('sky_color'     , e.sky_color || 0xccddff)
		prog.set_uni('horizon_color' , e.horizon_color || 0xffffff)
		prog.set_uni('ground_color'  , e.ground_color || 0xe0dddd)
		prog.set_uni('exponent'      , or(e.exponent, 1))

		let n_loaded
		let on_load = function() {
			n_loaded++
			if (n_loaded == 6) {
				e.fire('load')
			}
		}
		if (e.images && !e.loaded) {
			e.loaded = true
			cube_map_tex = cube_map_tex || gl.texture('cubemap')
			cube_map_tex.set_wrap('clamp', 'clamp')
			cube_map_tex.set_filter('linear', 'linear')
			prog.set_uni('diffuse_cube_map', cube_map_tex)
			n_loaded = 0
			for (let side in e.images) {
				let img = e.images[side]
				if (isstr(img))
					cube_map_tex.load(img, 1, on_load, side)
				else
					cube_map_tex.set_image(image, 1, on_load)
			}
		}
		prog.unuse()

	}

	e.draw = function(prog1) {
		if (prog1)
			return // no shadows or hit-testing
		vao.use()
		gl.draw_triangles()
	}

	assign(e, opt)
	e.update()

	return e
}

// helper lines --------------------------------------------------------------

gl.helper_lines_renderer = function() {

	let gl = this
	let e = {s: [], d: [], f: []}
	let ts = [e.s, e.d, e.f]

	e.s.rr = gl.solid_lines_renderer({})
	e.d.rr = gl.dashed_lines_renderer({dash: 5, gap: 3})
	e.f.rr = gl.fat_lines_renderer({})

	let dab_model = gl.dyn_arr_mat4_instance_buffer()
	dab_model.set(0, mat4f32.identity)
	dab_model.upload_invalid()

	function each_fat_line(f) {
		for (let line of e.f)
			f(line)
	}

	e.f.update = function() {
		e.f.rr.update(each_fat_line, e.f.length)
	}

	e.f.update_for = function(line) {
		e.f.rr.update_at(e.f.indexOf(line), line)
	}

	for (let t of ts)
		t.rr.model = dab_model.buffer

	function sldr(t) {

		let dab_pos   = gl.dyn_arr_v3_buffer()
		let dab_color = gl.dyn_arr_v3_buffer()

		{
		let _v0 = v3()
		function set_line(i, line) {
			assert(i >= 0)
			dab_pos.set(2*i+0, line[0])
			dab_pos.set(2*i+1, line[1])
			let c = _v0.set(line.color)
			dab_color.set(2*i+0, c)
			dab_color.set(2*i+1, c)

		}}

		t.update_for = function(line) {
			set_line(t.indexOf(line), line)
			dab_pos  .upload_invalid()
			dab_color.upload_invalid()
		}

		t.update = function() {

			let len = 2 * t.length

			dab_pos  .grow(len, false)
			dab_color.grow(len, false)

			let i = 0
			for (line of t)
				set_line(i++, line)

			dab_pos  .setlen(len).upload()
			dab_color.setlen(len).upload()

			t.rr.pos   = dab_pos  .buffer
			t.rr.color = dab_color.buffer
		}

	}

	sldr(e.s)
	sldr(e.d)

	e.line = function(line, color, type, visible) {

		line.color = color || 0
		line.visible = visible !== false
		type = type || 'solid'

		let lines =
			   type == 'solid'  && e.s
			|| type == 'dashed' && e.d
			|| type == 'fat'    && e.f
			|| assert(false, 'invalid helper line type {0}', type)

		line.free = function() {
			if (line._visible) {
				lines.remove_value(line)
				lines.update()
			}
		}

		line.update = function() {
			if (line._visible != line.visible) {
				if (line.visible)
					lines.push(line)
				else
					lines.remove_value(line)
				line._visible = line.visible
				lines.update()
			} else if (line.visible) {
				lines.update_for(line)
			}
		}

		lines.update()

		return line
	}

	e.draw = function(prog) {
		for (let t of ts)
			t.rr.draw(prog, false)
	}

	e.free = function() {
		for (let t of ts)
			t.rr.free()
	}

	return e

}

// axes prop -----------------------------------------------------------------

gl.axes_renderer = function(opt) {

	let gl = this

	let e = assign({
		x_color: 0x990000,
		y_color: 0x000099,
		z_color: 0x006600,
	}, opt)

	let lines_rr  = gl.solid_lines_renderer()
	let dashed_rr = gl.dashed_lines_renderer()

	let pos_poz = [
		...v3.zero, ...v3(FAR,   0,   0),
		...v3.zero, ...v3(  0, FAR,   0),
		...v3.zero, ...v3(  0,   0, FAR),
	]
	pos_poz = gl.v3_buffer(pos_poz)

	let pos_neg = [
		...v3.zero, ...v3(-FAR,    0,    0),
		...v3.zero, ...v3(   0, -FAR,    0),
		...v3.zero, ...v3(   0,    0, -FAR),
	]
	pos_neg = gl.v3_buffer(pos_neg)

	let color = [
		...v3().from_rgb(e.x_color),
		...v3().from_rgb(e.x_color),
		...v3().from_rgb(e.y_color),
		...v3().from_rgb(e.y_color),
		...v3().from_rgb(e.z_color),
		...v3().from_rgb(e.z_color),
	]
	color = gl.v3_buffer(color)

	let model_dab = gl.dyn_arr_mat4_instance_buffer()
	let axes_list = []

	e.axes = function() {

		let axes = {model: mat4()}
		axes_list.push(axes)

		axes.update = function() {
			let i = axes_list.indexOf(axes)
			model_dab.set(i, axes.model)
			model_dab.upload_invalid()
			lines_rr .model = model_dab.buffer
			dashed_rr.model = model_dab.buffer
		}

		axes.free = function() {
			let i = axes_list.remove_value(axes)
			model_dab.remove(i)
			model_dab.upload_invalid()
			lines_rr .model = model_dab.buffer
			dashed_rr.model = model_dab.buffer
		}

		axes.update()

		return axes
	}

	lines_rr.pos = pos_poz
	lines_rr.color = color

	dashed_rr.pos = pos_neg
	dashed_rr.color = color

	e.draw = function(prog1) {
		lines_rr .draw(prog1, false)
		dashed_rr.draw(prog1, false)
	}

	e.free = function() {
		lines_rr .free()
		dashed_rr.free()
	}

	e.clear = function() {
		axes_list.length = 0
		model_dab.len = 0
	}

	e.axes_list = axes_list

	return e
}

// ground plane with shadows -------------------------------------------------

gl.ground_plane_renderer = function() {

	let gl = this
	let e = {}

	let prog = gl.program('ground_plane', `

		#include phong.vs

		void main() {
			do_phong();
		}

	`, `

		#include phong.fs

		void main() {
			do_phong();
			if (shadow < 0.0)
				discard;
			if (shadow < 1.0)
				frag_color.a = 1.0 - shadow;
		}

	`)

	let rr = gl.faces_renderer()
	let poly = poly3([0, 1, 2, 3])
	poly.points = [
		-1,  0,  1,
		 1,  0,  1,
		 1,  0, -1,
		-1,  0, -1,
	]
	poly.material = {
		diffuse_color: 0xffffff,
		uv: v2(1, 1),
		opacity: 1,
		faces: [poly],
	}

	rr.model = gl.mat4_instance_buffer(mat4f32().scale(100))
	rr.update([poly])

	e.draw = function(prog1) {
		if (prog1)
			if (prog1.name == 'hit_face')
				return // not hit-testable.
		rr.draw(prog1 || prog)
	}

	return e
}

// shadow map display quad (for debugging) -----------------------------------

gl.shadow_map_quad = function(tex, imat) {
	let gl = this
	let e = {model: imat || mat4f32()}

	let pos = gl.v3_buffer([
		-1, -1,  0,
		 1, -1,  0,
		 1,  1,  0,
		-1,  1,  0,
	])
	let uv = gl.v2_buffer([
		0, 0,
		1, 0,
		1, 1,
		0, 1,
	])
	let index = gl.index_buffer([0, 1, 2, 0, 2, 3])
	let model = gl.mat4_instance_buffer(e.model)

	let prog = gl.program('texture_quad', `
		#include mesh.vs
		void main() {
			v_uv = uv;
			gl_Position = mvp(pos);
		}
	`, `
		#include mesh.fs
		void main() {
			float r = texture(diffuse_map, v_uv).r;
			//if (r == 1.0) discard;
			frag_color = vec4(vec3(r), 1.0);
		}
	`)

	let vao = prog.vao()
	vao.bind()
	vao.set_attr('pos', pos)
	vao.set_attr('uv', uv)
	vao.set_attr('model', model)
	vao.set_index(index)
	vao.unbind()
	prog.use()
	prog.set_uni('diffuse_map', tex)
	prog.unuse()

	e.update = function() {
		model.upload(e.model, 0)
	}

	e.draw = function(prog1) {
		if (prog1)
			return
		vao.use()
		gl.draw_triangles()
	}

	e.free = function() {
		vao.free()
		pos.free()
		index.free()
		uv.free()
		model.free()
	}

	return e
}

// immediate-mode drawing ----------------------------------------------------

gl.im_draw = function() {

	let e = {}



	e.line = function(p1, p2, color) {
		//
	}

	e.dot = function(p) {
		//
	}

	e.poly = function(poly) {
		//
	}

	e.draw = function(prog1) {
		if (prog1)
			return

	}

	e.free = function() {

	}

	return e

}

}()) // module scope.
