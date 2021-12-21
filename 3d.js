/*

	3D math lib.
	Written by Cosmin Apreutesei. Public domain.

	Code adapted from three.js and glMatrix, MIT License.

	v2 [x, y]
		* add sub mul div
		set(x,y|v2|v3|v4) assign to sets clone equals from[_v2|_v3|_v4]_array to[_v2]_array
		len[2] set_len normalize
		add adds sub subs negate mul muls div divs min max dot
		distance[2]_to
		transform(mat3) rotate
		origin zero

	v3 [x, y, z]
		* add sub mul div cross zero one
		set(x,y,z|v2,z|v3|v4|mat4) assign to sets clone equals
		from[_v3|_v4]_array to[_v3]_array from_rgb from_rgba from_hsl
		len[2] set_len normalize
		add adds sub subs negate mul muls div divs min max dot cross
		angle_to distance[2]_to
		transform(mat3|mat4|quaternion) rotate project
		origin zero one up right x|y|z_axis black white

	v4 [x, y, z, w]
		* add sub mul div
		set assign to sets clone equals from[_v4]_array to[_v4]_array from_rgb from_rgba from_hsl
		len[2] set_len normalize
		add adds sub subs negate mul muls div divs min max dot
		transform(mat4)
		origin one black white

	mat3, mat3f32 [e11, e21, e31, e12, e22, e32, e13, e23, e33]
		* mul
		set(mat3|mat4) assign to reset clone equals from[_mat3]_array to[_mat3]_array
		transpose det invert
		mul premul muls scale rotate translate

	mat4, mat4f32 [e11, e21, e31, e41, e12, e22, e32, e42, e13, e23, e33, e43, e14, e24, e34, e44]
		* mul
		set(mat3|mat4|v3|quat) assign to reset clone equals from[_mat4]_array to[_mat4]_array
		transpose det invert normal
		mul premul muls scale set_position translate rotate
		frustum perspective ortho look_to compose rotation

	quat [x, y, z, w]
		set assign to reset clone equals from[_quat]_array to[_quat]_array
		set_from_axis_angle set_from_rotation_matrix set_from_unit_vectors
		len[2] normalize rotate_towards conjugate invert
		angle_to dot mul premul slerp

	plane[3] {constant:, normal:}
		set assign to clone equals
		set_from_normal_and_coplanar_point set_from_coplanar_points set_from_poly
		normalize negate
		distance_to_point project_point
		intersect_line intersects_line clip_line
		origin translate transform

	triangle3 [a, b, c]
		* normal barycoord contains_point uv is_front_facing
		set assign to clone equals from[_triangle3]_array to[_triangle3]_array
		area midpoint normal plane barycoord uv contains_point is_front_facing

	poly3
		% point_count get_point
		plane xy_quat is_convex_quad triangle_count triangles triangle contains_point

	line3 [p0, p1]
		set(line | p1,p2) assign to clone equals to|from[_line3]_array
		delta distance2 distance at reverse len set_len
		closest_point_to_point_t closest_point_to_point intersect_line intersect_plane intersects_plane
		transform

	box3 [min_p, max_p]
		set assign to clone equals reset to_array to[_box3]_array from[_box3]_array add
		is_empty center delta contains_point contains_box intersects_box
		transform translate

	camera[3]
		view_size pos dir up perspective ortho dolly orbit
		update proj view inv_view inv_proj view_proj
		world_to_screen screen_to_clip screen_to_view screen_to_world
		raycast

*/

(function() {

NEAR = 1e-5 // distance epsilon (tolerance)
FAR  = 1e5  // skybox distance from center

// v2 ------------------------------------------------------------------------

let v2_class = class v extends Array {

	constructor(x, y) {
		super(x || 0, y || 0)
	}

	set(x, y) {
		if (x.is_v2 || x.is_v3 || x.is_v4) {
			let v = x
			x = v[0]
			y = v[1]
		}
		this[0] = x
		this[1] = y
		return this
	}

	assign(v) {
		assert(v.is_v2)
		return assign(this, v)
	}

	to(v) {
		return v.set(this)
	}

	sets(s) {
		this[0] = s
		this[1] = s
		return this
	}

	clone() {
		return v2(this[0], this[1])
	}

	equals(v) {
		return (
			v[0] === this[0] &&
			v[1] === this[1]
		)
	}

	from_array(a, i) {
		this[0] = a[i  ]
		this[1] = a[i+1]
		return this
	}

	to_array(a, i) {
		a[i  ] = this[0]
		a[i+1] = this[1]
		return a
	}

	from_v2_array(a, i) { return this.from_array(a, 2 * i) }
	from_v3_array(a, i) { return this.from_array(a, 3 * i) }
	from_v4_array(a, i) { return this.from_array(a, 4 * i) }

	to_v2_array(a, i) { return this.to_array(a, 2 * i) }

	len2() {
		return (
			this[0] ** 2 +
			this[1] ** 2
		)
	}

	len() {
		return sqrt(this.len2())
	}

	normalize() {
		return this.divs(this.len() || 1)
	}

	set_len(v) {
		return this.normalize().muls(v)
	}

	add(v, s) {
		s = or(s, 1)
		this[0] += v[0] * s
		this[1] += v[1] * s
		return this
	}

	adds(s) {
		this[0] += s
		this[1] += s
		return this
	}

	sub(v) {
		this[0] -= v[0]
		this[1] -= v[1]
		return this
	}

	subs(s) {
		this[0] -= s
		this[1] -= s
		return this
	}

	negate() {
		this[0] = -this[0]
		this[1] = -this[1]
		return this
	}

	mul(v) {
		this[0] *= v[0]
		this[1] *= v[1]
		return this
	}

	muls(s) {
		this[0] *= s
		this[1] *= s
		return this
	}

	div(v) {
		this[0] /= v[0]
		this[1] /= v[1]
		return this
	}

	divs(s) {
		return this.muls(1 / s)
	}

	min(v) {
		this[0] = min(this[0], v[0])
		this[1] = min(this[1], v[1])
		return this
	}

	max(v) {
		this[0] = max(this[0], v[0])
		this[1] = max(this[1], v[1])
		return this
	}

	dot(v) {
		return (
			this[0] * v[0] +
			this[1] * v[1]
		)
	}

	distance2(v) {
		let dx = this[0] - v[0]
		let dy = this[1] - v[1]
		return (
			dx ** 2 +
			dy ** 2
		)
	}

	distance(v) {
		return sqrt(this.distance2(v))
	}

	transform(arg) {
		let x = this[0]
		let y = this[1]
		if (arg.is_mat3) {
			var m = arg
			this[0] = m[0] * x + m[3] * y + m[6]
			this[1] = m[1] * x + m[4] * y + m[7]
		} else
			assert(false)
		return this
	}

	rotate(axis, angle) {
		let cx = axis[0]
		let cy = axis[1]
		let c = cos(angle)
		let s = sin(angle)
		let x = this[0] - cx
		let y = this[1] - cy
		this[0] = x * c - y * s + cx
		this[1] = x * s + y * c + cy
		return this
	}

}

v2_class.prototype.is_v2 = true

property(v2_class, 'x', function() { return this[0] }, function(v) { this[0] = v })
property(v2_class, 'y', function() { return this[1] }, function(v) { this[1] = v })

v2 = function v2(x, y) { return new v2_class(x, y) }
v2.class = v2_class

v2.add = function add(a, b, s, out) {
	s = or(s, 1)
	out[0] = (a[0] + b[0]) * s
	out[1] = (a[1] + b[1]) * s
	return out
}

v2.sub = function sub(a, b, out) {
	out[0] = a[0] - b[0]
	out[1] = a[1] - b[1]
	return out
}

v2.mul = function mul(a, b, out) {
	out[0] = a[0] * b[0]
	out[1] = a[1] * b[1]
	return out
}

v2.div = function div(a, b, out) {
	out[0] = a[0] / b[0]
	out[1] = a[1] / b[1]
	return out
}

v2.origin = v2()
v2.zero = v2.origin

// v3 ------------------------------------------------------------------------

// hsl is in (0..360, 0..1, 0..1); rgb is (0..1, 0..1, 0..1)
function h2rgb(m1, m2, h) {
	if (h < 0) h = h + 1
	if (h > 1) h = h - 1
	if (h * 6 < 1)
		return m1 + (m2 - m1) * h * 6
	else if (h * 2 < 1)
		return m2
	else if (h * 3 < 2)
		return m1 + (m2 - m1) * (2 / 3 - h) * 6
	else
		return m1
}

function set_hsl(self, h, s, L) {
	h = h / 360
	let m2 = L <= .5 ? L * (s + 1) : L + s - L * s
	let m1 = L * 2 - m2
	self[0] = h2rgb(m1, m2, h+1/3)
	self[1] = h2rgb(m1, m2, h)
	self[2] = h2rgb(m1, m2, h-1/3)
}

let v3_class = class v extends Array {

	constructor(x, y, z) {
		super(x || 0, y || 0, z || 0)
	}

	set(x, y, z) {
		if (x.is_v3 || x.is_v4) {
			let v = x
			x = v[0]
			y = v[1]
			z = v[2]
		} else if (x.is_v2) { // (v2, z)
			let v = x
			z = or(y, 0)
			x = v[0]
			y = v[1]
		} else if (x.is_mat4) {
			x = e[12]
			y = e[13]
			z = e[14]
		} else if (y == null) {
			return this.from_rgb(x)
		}
		this[0] = x
		this[1] = y
		this[2] = z
		return this
	}

	assign(v) {
		assert(v.is_v3)
		return assign(this, v)
	}

	to(v) {
		return v.set(this)
	}

	sets(s) {
		this[0] = s
		this[1] = s
		this[2] = s
		return this
	}

	clone() {
		return v3(this[0], this[1], this[2])
	}

	equals(v) {
		return (
			v[0] === this[0] &&
			v[1] === this[1] &&
			v[2] === this[2]
		)
	}

	from_array(a, i) {
		this[0] = a[i  ]
		this[1] = a[i+1]
		this[2] = a[i+2]
		return this
	}

	to_array(a, i) {
		a[i  ] = this[0]
		a[i+1] = this[1]
		a[i+2] = this[2]
		return a
	}

	from_v3_array(a, i) { return this.from_array(a, 3 * i) }
	from_v4_array(a, i) { return this.from_array(a, 4 * i) }

	to_v3_array(a, i) { return this.to_array(a, 3 * i) }

	from_rgb(s) {
		if (isstr(s))
			s = parseInt(s.replace(/[^0-9a-fA-F]/g, ''), 16)
		this[0] = (s >> 16 & 0xff) / 255
		this[1] = (s >>  8 & 0xff) / 255
		this[2] = (s       & 0xff) / 255
		return this
	}

	from_rgba(s) {
		if (isstr(s))
			s = parseInt(s.replace(/[^0-9a-fA-F]/g, ''), 16)
		this[0] = (s >> 24 & 0xff) / 255
		this[1] = (s >> 16 & 0xff) / 255
		this[2] = (s >>  8 & 0xff) / 255
		return this
	}

	from_hsl(h, s, L) {
		set_hsl(this, h, s, L)
		return this
	}

	len2() {
		return (
			this[0] ** 2 +
			this[1] ** 2 +
			this[2] ** 2
		)
	}

	len() {
		return sqrt(this.len2())
	}

	normalize() {
		return this.divs(this.len() || 1)
	}

	set_len(v) {
		return this.normalize().muls(v)
	}

	add(v, s) {
		s = or(s, 1)
		this[0] += v[0] * s
		this[1] += v[1] * s
		this[2] += v[2] * s
		return this
	}

	adds(s) {
		this[0] += s
		this[1] += s
		this[2] += s
		return this
	}

	sub(v) {
		this[0] -= v[0]
		this[1] -= v[1]
		this[2] -= v[2]
		return this
	}

	subs(s) {
		this[0] -= s
		this[1] -= s
		this[2] -= s
		return this
	}

	negate() {
		this[0] = -this[0]
		this[1] = -this[1]
		this[2] = -this[2]
		return this
	}

	mul(v) {
		this[0] *= v[0]
		this[1] *= v[1]
		this[2] *= v[2]
		return this
	}

	muls(s) {
		this[0] *= s
		this[1] *= s
		this[2] *= s
		return this
	}

	div(v) {
		this[0] /= v[0]
		this[1] /= v[1]
		this[2] /= v[2]
		return this
	}

	divs(s) {
		return this.muls(1 / s)
	}

	min(v) {
		this[0] = min(this[0], v[0])
		this[1] = min(this[1], v[1])
		this[2] = min(this[2], v[2])
		return this
	}

	max(v) {
		this[0] = max(this[0], v[0])
		this[1] = max(this[1], v[1])
		this[2] = max(this[2], v[2])
		return this
	}

	dot(v) {
		return (
			this[0] * v[0] +
			this[1] * v[1] +
			this[2] * v[2]
		)
	}

	cross(b) {
		return v3.cross(this, b, this)
	}

	angle_to(v) {
		let den = sqrt(this.len2() * v.len2())
		if (den == 0) return PI / 2
		let theta = this.dot(v) / den // clamp, to handle numerical problems
		return acos(clamp(theta, -1, 1))
	}

	distance2(v) {
		let dx = this[0] - v[0]
		let dy = this[1] - v[1]
		let dz = this[2] - v[2]
		return (
			dx ** 2 +
			dy ** 2 +
			dz ** 2
		)
	}

	distance(v) {
		return sqrt(this.distance2(v))
	}

	transform(arg) {

		let x = this[0]
		let y = this[1]
		let z = this[2]

		if (arg.is_quat) {

			let qx = arg[0]
			let qy = arg[1]
			let qz = arg[2]
			let qw = arg[3] // calculate quat * vector

			let ix = qw * x + qy * z - qz * y
			let iy = qw * y + qz * x - qx * z
			let iz = qw * z + qx * y - qy * x
			let iw = -qx * x - qy * y - qz * z // calculate result * inverse quat

			this[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy
			this[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz
			this[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx

		} else if (arg.is_mat3) {

			let m = arg
			this[0] = m[0] * x + m[3] * y + m[6] * z
			this[1] = m[1] * x + m[4] * y + m[7] * z
			this[2] = m[2] * x + m[5] * y + m[8] * z

		} else if (arg.is_mat4) {

			let m = arg
			let w = 1 / (m[3] * x + m[7] * y + m[11] * z + m[15])
			this[0] = (m[0] * x + m[4] * y + m[ 8] * z + m[12]) * w
			this[1] = (m[1] * x + m[5] * y + m[ 9] * z + m[13]) * w
			this[2] = (m[2] * x + m[6] * y + m[10] * z + m[14]) * w

		} else
			assert(false)

		return this
	}

	rotate(axis, angle) {
		return this.transform(_q0.set_from_axis_angle(axis, angle))
	}

	project(plane, out) {
		return plane.project_point(this, out)
	}

}

v3_class.prototype.is_v3 = true

property(v3_class, 'x', function() { return this[0] }, function(v) { this[0] = v })
property(v3_class, 'y', function() { return this[1] }, function(v) { this[1] = v })
property(v3_class, 'z', function() { return this[2] }, function(v) { this[2] = v })

v3 = function v3(x, y, z) { return new v3_class(x, y, z) }
v3.class = v3_class

v3.cross = function(a, b, out) {
	let ax = a[0]
	let ay = a[1]
	let az = a[2]
	let bx = b[0]
	let by = b[1]
	let bz = b[2]
	out[0] = ay * bz - az * by
	out[1] = az * bx - ax * bz
	out[2] = ax * by - ay * bx
	return out
}

v3.add = function add(a, b, s, out) {
	s = or(s, 1)
	out[0] = a[0] + b[0] * s
	out[1] = a[1] + b[1] * s
	out[2] = a[2] + b[2] * s
	return out
}

v3.sub = function sub(a, b, out) {
	out[0] = a[0] - b[0]
	out[1] = a[1] - b[1]
	out[2] = a[2] - b[2]
	return out
}

v3.mul = function mul(a, b, out) {
	out[0] = a[0] * b[0]
	out[1] = a[1] * b[1]
	out[2] = a[2] * b[2]
	return out
}

v3.div = function div(a, b, out) {
	out[0] = a[0] / b[0]
	out[1] = a[1] / b[1]
	out[2] = a[2] / b[2]
	return out
}

v3.origin  = v3()
v3.zero   = v3.origin
v3.one    = v3(1, 1, 1)
v3.up     = v3(0, 1, 0)
v3.right  = v3(1, 0, 0)
v3.x_axis = v3.right
v3.y_axis = v3.up
v3.z_axis = v3(0, 0, 1)
v3.black  = v3.zero
v3.white  = v3.one

// temporaries for plane, triangle3 and line3 methods.
let _v0 = v3()
let _v1 = v3()
let _v2 = v3()
let _v3 = v3()
let _v4 = v3()

// v4 ------------------------------------------------------------------------

let v4_class = class v extends Array {

	constructor(x, y, z, w) {
		super(x || 0, y || 0, z || 0, or(w, 1))
	}

	set(x, y, z, w) {
		if (x.is_v4) {
			let v = x
			x = v[0]
			y = v[1]
			z = v[2]
			w = v[3]
		} else if (x.is_v3) {
			let v = x
			w = or(y, 1)
			x = v[0]
			y = v[1]
			z = v[2]
		} else if (x.is_v2) {
			let v = x
			z = or(y, 0)
			w = or(z, 1)
			x = v[0]
			y = v[1]
		} else if (y == null) {
			return this.from_rgba(x)
		}
		this[0] = x
		this[1] = y
		this[2] = z
		this[3] = w
		return this
	}

	assign(v) {
		assert(v.is_v4)
		return assign(this, v)
	}

	to(v) {
		return v.set(this)
	}

	sets(s) {
		this[0] = s
		this[1] = s
		this[2] = s
		this[3] = s
		return this
	}

	clone() {
		return v4().set(this)
	}

	equals(v) {
		return (
			v[0] === this[0] &&
			v[1] === this[1] &&
			v[2] === this[2] &&
			v[3] === this[3]
		)
	}

	from_array(a, i) {
		this[0] = a[i  ]
		this[1] = a[i+1]
		this[2] = a[i+2]
		this[3] = a[i+3]
		return this
	}

	to_array(a, i) {
		a[i  ] = this[0]
		a[i+1] = this[1]
		a[i+2] = this[2]
		a[i+3] = this[3]
		return a
	}

	from_v4_array(a, i) { return this.from_array(a, 4 * i) }

	to_v4_array(a, i) { return this.to_array(a, 4 * i) }

	len2() {
		return (
			this[0] ** 2 +
			this[1] ** 2 +
			this[2] ** 2 +
			this[3] ** 2
		)
	}

	from_rgb(s) {
		this[0] = ((s >> 16) & 0xff) / 255
		this[1] = ((s >>  8) & 0xff) / 255
		this[2] = ( s        & 0xff) / 255
		return this
	}

	from_rgba(s) {
		this[0] = ((s >> 24) & 0xff) / 255
		this[1] = ((s >> 16) & 0xff) / 255
		this[2] = ((s >>  8) & 0xff) / 255
		this[3] = ( s        & 0xff) / 255
		return this
	}

	from_hsl(h, s, L, a) {
		set_hsl(this, h, s, L)
		this[3] = or(a, 1)
		return this
	}

	len() {
		return sqrt(this.len2())
	}

	normalize() {
		return this.divs(this.len() || 1)
	}

	set_len(v) {
		return this.normalize().muls(v)
	}

	add(v, s) {
		s = or(s, 1)
		this[0] += v[0] * s
		this[1] += v[1] * s
		this[2] += v[2] * s
		this[3] += v[3] * s
		return this
	}

	adds(s) {
		this[0] += s
		this[1] += s
		this[2] += s
		this[3] += s
		return this
	}

	sub(v) {
		this[0] -= v[0]
		this[1] -= v[1]
		this[2] -= v[2]
		this[3] -= v[3]
		return this
	}

	subs(s) {
		this[0] -= s
		this[1] -= s
		this[2] -= s
		this[3] -= s
		return this
	}

	mul(v) {
		this[0] *= v[0]
		this[1] *= v[1]
		this[2] *= v[2]
		this[3] *= v[3]
		return this
	}

	muls(s) {
		this[0] *= s
		this[1] *= s
		this[2] *= s
		this[3] *= s
		return this
	}

	div(v) {
		this[0] /= v[0]
		this[1] /= v[1]
		this[2] /= v[2]
		this[3] /= v[3]
		return this
	}

	divs(s) {
		return this.muls(1 / s)
	}

	min(v) {
		this[0] = min(this[0], v[0])
		this[1] = min(this[1], v[1])
		this[2] = min(this[2], v[2])
		this[3] = min(this[3], v[3])
		return this
	}

	max(v) {
		this[0] = max(this[0], v[0])
		this[1] = max(this[1], v[1])
		this[2] = max(this[2], v[2])
		this[3] = max(this[3], v[3])
		return this
	}

	negate() {
		this[0] = -this[0]
		this[1] = -this[1]
		this[2] = -this[2]
		this[3] = -this[3]
		return this
	}

	dot(v) {
		return (
			this[0] * v[0] +
			this[1] * v[1] +
			this[2] * v[2] +
			this[3] * v[3]
		)
	}

	transform(arg) {
		if (arg.is_mat4) {
			let x = this[0]
			let y = this[1]
			let z = this[2]
			let w = this[3]
			let m = arg
			this[0] = m[0] * x + m[4] * y + m[ 8] * z + m[12] * w
			this[1] = m[1] * x + m[5] * y + m[ 9] * z + m[13] * w
			this[2] = m[2] * x + m[6] * y + m[10] * z + m[14] * w
			this[3] = m[3] * x + m[7] * y + m[11] * z + m[15] * w
		} else
			assert(false)
		return this
	}

}

v4_class.prototype.is_v4 = true

property(v4_class, 'x', function() { return this[0] }, function(v) { this[0] = v })
property(v4_class, 'y', function() { return this[1] }, function(v) { this[1] = v })
property(v4_class, 'z', function() { return this[2] }, function(v) { this[2] = v })
property(v4_class, 'w', function() { return this[3] }, function(v) { this[3] = v })

v4 = function v4(x, y, z, w) { return new v4_class(x, y, z, w) }
v4.class = v4_class

v4.add = function add(a, v, s, out) {
	s = or(s, 1)
	out[0] = a[0] + v[0] * s
	out[1] = a[1] + v[1] * s
	out[2] = a[2] + v[2] * s
	out[3] = a[3] + v[3] * s
	return out
}

v4.sub = function sub(a, v, out) {
	out[0] = a[0] - v[0]
	out[1] = a[1] - v[1]
	out[2] = a[2] - v[2]
	out[3] = a[3] - v[3]
	return out
}

v4.mul = function mul(a, v, out) {
	out[0] = a[0] * v[0]
	out[1] = a[1] * v[1]
	out[2] = a[2] * v[2]
	out[3] = a[3] * v[3]
	return out
}

v4.div = function div(a, v, out) {
	out[0] = a[0] / v[0]
	out[1] = a[1] / v[1]
	out[2] = a[2] / v[2]
	out[3] = a[3] / v[3]
	return out
}

v4.origin = v4()
v4.one = v4(1, 1, 1)
v4.black = v4()
v4.white = v4.one

// mat3 ----------------------------------------------------------------------

let mat3_type = function(super_class, super_args) {

	let mat3_class = class m extends super_class {

		constructor() {
			super(...super_args)
		}

		set(n11, n12, n13, n21, n22, n23, n31, n32, n33) {
			let a = this
			if (n11.is_mat3)
				return this.from_array(n11, 0)
			if (n11.is_mat4) {
				let a = n11
				return this.set(
					a[0], a[4], a[ 8],
					a[1], a[5], a[ 9],
					a[2], a[6], a[10])
			} else {
				a[0] = n11
				a[1] = n21
				a[2] = n31
				a[3] = n12
				a[4] = n22
				a[5] = n32
				a[6] = n13
				a[7] = n23
				a[8] = n33
			}
			return this
		}

		assign(m) {
			assert(m.is_mat3)
			return assign(this, m)
		}

		to(v) {
			return v.set(this)
		}

		reset() {
			return this.set(
				1, 0, 0,
				0, 1, 0,
				0, 0, 1)
		}

		clone() {
			return mat3().set(this)
		}

		equals(m) {
			for (let i = 0; i < 9; i++)
				if (this[i] !== m[i])
					return false
			return true
		}

		from_array(a, ai) {
			for (let i = 0; i < 9; i++)
				this[i] = a[ai + i]
			return this
		}

		to_array(a, ai) {
			for (let i = 0; i < 9; i++)
				a[ai + i] = this[i]
			return a
		}

		from_mat3_array(a, i) { return this.from_array(a, 9 * i) }

		to_mat3_array(a, i) { return this.to_array(a, 9 * i) }

		transpose() {
			let tmp
			let m = this
			tmp = m[1]; m[1] = m[3]; m[3] = tmp
			tmp = m[2]; m[2] = m[6]; m[6] = tmp
			tmp = m[5]; m[5] = m[7]; m[7] = tmp
			return this
		}

		det() {
			let a = this[0]
			let b = this[1]
			let c = this[2]
			let d = this[3]
			let e = this[4]
			let f = this[5]
			let g = this[6]
			let h = this[7]
			let i = this[8]
			return a * e * i - a * f * h - b * d * i + b * f * g + c * d * h - c * e * g
		}

		invert() {
			let n11 = this[0]
			let n21 = this[1]
			let n31 = this[2]
			let n12 = this[3]
			let n22 = this[4]
			let n32 = this[5]
			let n13 = this[6]
			let n23 = this[7]
			let n33 = this[8]
			let t11 = n33 * n22 - n32 * n23
			let t12 = n32 * n13 - n33 * n12
			let t13 = n23 * n12 - n22 * n13
			let det = n11 * t11 + n21 * t12 + n31 * t13
			if (det === 0)
				return this.set(0, 0, 0, 0, 0, 0, 0, 0, 0)
			let detInv = 1 / det
			this[0] = t11 * detInv
			this[1] = (n31 * n23 - n33 * n21) * detInv
			this[2] = (n32 * n21 - n31 * n22) * detInv
			this[3] = t12 * detInv
			this[4] = (n33 * n11 - n31 * n13) * detInv
			this[5] = (n31 * n12 - n32 * n11) * detInv
			this[6] = t13 * detInv
			this[7] = (n21 * n13 - n23 * n11) * detInv
			this[8] = (n22 * n11 - n21 * n12) * detInv
			return this
		}

		mul(m) {
			return mat3.mul(this, m, this)
		}

		premul(m) {
			return mat3.mul(m, this, this)
		}

		muls(s) {
			this[0] *= s
			this[3] *= s
			this[6] *= s
			this[1] *= s
			this[4] *= s
			this[7] *= s
			this[2] *= s
			this[5] *= s
			this[8] *= s
			return this
		}

		scale(x, y) {
			if (isarray(x)) {
				let v = x
				x = v[0]
				y = v[1]
			} else {
				y = or(y, x)
			}
			this[0] *= x
			this[3] *= x
			this[6] *= x
			this[1] *= y
			this[4] *= y
			this[7] *= y
			return this
		}

		rotate(angle) {
			let c = cos(angle)
			let s = sin(angle)
			let a11 = this[0]
			let a12 = this[3]
			let a13 = this[6]
			let a21 = this[1]
			let a22 = this[4]
			let a23 = this[7]
			this[0] =  c * a11 + s * a21
			this[3] =  c * a12 + s * a22
			this[6] =  c * a13 + s * a23
			this[1] = -s * a11 + c * a21
			this[4] = -s * a12 + c * a22
			this[7] = -s * a13 + c * a23
			return this
		}

		translate(x, y) {
			if (isarray(x)) {
				let v = x
				x = v[0]
				y = v[1]
			}
			this[0] += x * this[2]
			this[3] += x * this[5]
			this[6] += x * this[8]
			this[1] += y * this[2]
			this[4] += y * this[5]
			this[7] += y * this[8]
			return this
		}

	}

	mat3_class.prototype.is_mat3 = true

	property(mat3_class, 'e11', function() { return this[0] }, function(v) { this[0] = v })
	property(mat3_class, 'e21', function() { return this[1] }, function(v) { this[1] = v })
	property(mat3_class, 'e31', function() { return this[2] }, function(v) { this[2] = v })
	property(mat3_class, 'e12', function() { return this[3] }, function(v) { this[3] = v })
	property(mat3_class, 'e22', function() { return this[4] }, function(v) { this[4] = v })
	property(mat3_class, 'e32', function() { return this[5] }, function(v) { this[5] = v })
	property(mat3_class, 'e13', function() { return this[6] }, function(v) { this[6] = v })
	property(mat3_class, 'e23', function() { return this[7] }, function(v) { this[7] = v })
	property(mat3_class, 'e33', function() { return this[8] }, function(v) { this[8] = v })

	let mat3 = function() { return new mat3_class() }
	mat3.class = mat3_class

	mat3.mul = function mul(a, b, out) {

		let a11 = a[0]
		let a21 = a[1]
		let a31 = a[2]
		let a12 = a[3]
		let a22 = a[4]
		let a32 = a[5]
		let a13 = a[6]
		let a23 = a[7]
		let a33 = a[8]

		let b11 = b[0]
		let b21 = b[1]
		let b31 = b[2]
		let b12 = b[3]
		let b22 = b[4]
		let b32 = b[5]
		let b13 = b[6]
		let b23 = b[7]
		let b33 = b[8]

		out[0] = a11 * b11 + a12 * b21 + a13 * b31
		out[3] = a11 * b12 + a12 * b22 + a13 * b32
		out[6] = a11 * b13 + a12 * b23 + a13 * b33
		out[1] = a21 * b11 + a22 * b21 + a23 * b31
		out[4] = a21 * b12 + a22 * b22 + a23 * b32
		out[7] = a21 * b13 + a22 * b23 + a23 * b33
		out[2] = a31 * b11 + a32 * b21 + a33 * b31
		out[5] = a31 * b12 + a32 * b22 + a33 * b32
		out[8] = a31 * b13 + a32 * b23 + a33 * b33

		return out
	}

	return mat3

}

let mat3_ident = [1, 0, 0, 0, 1, 0, 0, 0, 1]
mat3    = mat3_type(Array, mat3_ident)
mat3f32 = mat3_type(f32arr, [mat3_ident])

mat3.identity = mat3()
mat3f32.identity = mat3f32()

// mat4 ----------------------------------------------------------------------

let mat4_type = function(super_class, super_args) {

	let mat4_class = class m extends super_class {

		constructor() {
			super(...super_args)
		}

		set(
			n11, n12, n13, n14,
			n21, n22, n23, n24,
			n31, n32, n33, n34,
			n41, n42, n43, n44
		) {
			if (n11.is_mat4)
				return this.from_array(n11, 0)
			if (n11.is_mat3) {
				let m = n11
				return this.set(
					m[0], m[3], m[6], 0,
					m[1], m[4], m[7], 0,
					m[2], m[5], m[8], 1)
			} else if (n11.is_quat) {
				return this.compose(v3.zero, n11, v3.one)
			} else {
				this[ 0] = n11
				this[ 1] = n21
				this[ 2] = n31
				this[ 3] = n41
				this[ 4] = n12
				this[ 5] = n22
				this[ 6] = n32
				this[ 7] = n42
				this[ 8] = n13
				this[ 9] = n23
				this[10] = n33
				this[11] = n43
				this[12] = n14
				this[13] = n24
				this[14] = n34
				this[15] = n44
			}
			return this
		}

		assign(m) {
			assert(m.is_mat4)
			return assign(this, m)
		}

		to(v) {
			return v.set(this)
		}

		reset() {
			return this.set(
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1)
		}

		clone() {
			return mat4().set(this)
		}

		equals(m) {
			for (let i = 0; i < 16; i++)
				if (this[i] !== m[i])
					return false
			return true
		}

		from_array(a, ai) {
			for (let i = 0; i < 16; i++)
				this[i] = a[ai + i]
			return this
		}

		to_array(a, ai) {
			for (let i = 0; i < 16; i++)
				a[ai + i] = this[i]
			return a
		}

		from_mat4_array(a, i) { return this.from_array(a, 16 * i) }

		to_mat4_array(a, i) { return this.to_array(a, 16 * i) }

		transpose() {
			let t
			let m = this
			t = m[ 1]; m[ 1] = m[ 4]; m[ 4] = t
			t = m[ 2]; m[ 2] = m[ 8]; m[ 8] = t
			t = m[ 6]; m[ 6] = m[ 9]; m[ 9] = t
			t = m[ 3]; m[ 3] = m[12]; m[12] = t
			t = m[ 7]; m[ 7] = m[13]; m[13] = t
			t = m[11]; m[11] = m[14]; m[14] = t
			return this
		}

		// http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
		det() {
			let n11 = this[ 0]
			let n21 = this[ 1]
			let n31 = this[ 2]
			let n41 = this[ 3]
			let n12 = this[ 4]
			let n22 = this[ 5]
			let n32 = this[ 6]
			let n42 = this[ 7]
			let n13 = this[ 8]
			let n23 = this[ 9]
			let n33 = this[10]
			let n43 = this[11]
			let n14 = this[12]
			let n24 = this[13]
			let n34 = this[14]
			let n44 = this[15]
			return (
				  n41 * (+n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34)
				+ n42 * (+n11 * n23 * n34 - n11 * n24 * n33 + n14 * n21 * n33 - n13 * n21 * n34 + n13 * n24 * n31 - n14 * n23 * n31)
				+ n43 * (+n11 * n24 * n32 - n11 * n22 * n34 - n14 * n21 * n32 + n12 * n21 * n34 + n14 * n22 * n31 - n12 * n24 * n31)
				+ n44 * (-n13 * n22 * n31 - n11 * n23 * n32 + n11 * n22 * n33 + n13 * n21 * n32 - n12 * n21 * n33 + n12 * n23 * n31)
			)
		}

		invert() {
			let a00 = this[ 0]
			let a01 = this[ 1]
			let a02 = this[ 2]
			let a03 = this[ 3]
			let a10 = this[ 4]
			let a11 = this[ 5]
			let a12 = this[ 6]
			let a13 = this[ 7]
			let a20 = this[ 8]
			let a21 = this[ 9]
			let a22 = this[10]
			let a23 = this[11]
			let a30 = this[12]
			let a31 = this[13]
			let a32 = this[14]
			let a33 = this[15]
			let b00 = a00 * a11 - a01 * a10
			let b01 = a00 * a12 - a02 * a10
			let b02 = a00 * a13 - a03 * a10
			let b03 = a01 * a12 - a02 * a11
			let b04 = a01 * a13 - a03 * a11
			let b05 = a02 * a13 - a03 * a12
			let b06 = a20 * a31 - a21 * a30
			let b07 = a20 * a32 - a22 * a30
			let b08 = a20 * a33 - a23 * a30
			let b09 = a21 * a32 - a22 * a31
			let b10 = a21 * a33 - a23 * a31
			let b11 = a22 * a33 - a23 * a32
			let det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06
			if (!det)
				return
			det = 1.0 / det
			this[ 0] = (a11 * b11 - a12 * b10 + a13 * b09) * det
			this[ 1] = (a02 * b10 - a01 * b11 - a03 * b09) * det
			this[ 2] = (a31 * b05 - a32 * b04 + a33 * b03) * det
			this[ 3] = (a22 * b04 - a21 * b05 - a23 * b03) * det
			this[ 4] = (a12 * b08 - a10 * b11 - a13 * b07) * det
			this[ 5] = (a00 * b11 - a02 * b08 + a03 * b07) * det
			this[ 6] = (a32 * b02 - a30 * b05 - a33 * b01) * det
			this[ 7] = (a20 * b05 - a22 * b02 + a23 * b01) * det
			this[ 8] = (a10 * b10 - a11 * b08 + a13 * b06) * det
			this[ 9] = (a01 * b08 - a00 * b10 - a03 * b06) * det
			this[10] = (a30 * b04 - a31 * b02 + a33 * b00) * det
			this[11] = (a21 * b02 - a20 * b04 - a23 * b00) * det
			this[12] = (a11 * b07 - a10 * b09 - a12 * b06) * det
			this[13] = (a00 * b09 - a01 * b07 + a02 * b06) * det
			this[14] = (a31 * b01 - a30 * b03 - a32 * b00) * det
			this[15] = (a20 * b03 - a21 * b01 + a22 * b00) * det
			return this
		}

		normal(out) {
			return out.set(this).invert().transpose()
		}

		mul(m) {
			return mat4.mul(this, m, this)
		}

		premul(m) {
			return mat4.mul(m, this, this)
		}

		muls(s) {
			this[ 0] *= s
			this[ 1] *= s
			this[ 2] *= s
			this[ 3] *= s
			this[ 4] *= s
			this[ 5] *= s
			this[ 6] *= s
			this[ 7] *= s
			this[ 8] *= s
			this[ 9] *= s
			this[10] *= s
			this[11] *= s
			this[12] *= s
			this[13] *= s
			this[14] *= s
			this[15] *= s
			return this
		}

		scale(x, y, z) {
			if (x.is_v3 || x.is_v4) {
				let v = x
				x = v[0]
				y = v[1]
				z = v[2]
			} else {
				y = or(y, x)
				z = or(z, x)
			}
			this[ 0] *= x
			this[ 4] *= y
			this[ 8] *= z
			this[ 1] *= x
			this[ 5] *= y
			this[ 9] *= z
			this[ 2] *= x
			this[ 6] *= y
			this[10] *= z
			this[ 3] *= x
			this[ 7] *= y
			this[11] *= z
			return this
		}

		set_position(x, y, z) {
			if (x.is_v3 || x.is_v4) {
				let v = x
				x = v[0]
				y = v[1]
				z = v[2]
			} else if (x.is_mat4) {
				let me = x.elements
				x = me[12]
				y = me[13]
				z = me[14]
			}
			this[12] = x
			this[13] = y
			this[14] = z
			return this
		}

		translate(x, y, z) {
			if (x.is_v3 || x.is_v4) {
				let v = x
				x = v[0]
				y = v[1]
				z = v[2]
			}
			let m = this
			m[12] = m[0] * x + m[4] * y + m[ 8] * z + m[12]
			m[13] = m[1] * x + m[5] * y + m[ 9] * z + m[13]
			m[14] = m[2] * x + m[6] * y + m[10] * z + m[14]
			m[15] = m[3] * x + m[7] * y + m[11] * z + m[15]
			return this
		}

		rotate(axis, angle) {
			let x = axis[0]
			let y = axis[1]
			let z = axis[2]
			let len = Math.hypot(x, y, z)
			assert(len >= NEAR)
			len = 1 / len
			x *= len
			y *= len
			z *= len
			let s = sin(angle)
			let c = cos(angle)
			let t = 1 - c
			let a00 = this[ 0]
			let a01 = this[ 1]
			let a02 = this[ 2]
			let a03 = this[ 3]
			let a10 = this[ 4]
			let a11 = this[ 5]
			let a12 = this[ 6]
			let a13 = this[ 7]
			let a20 = this[ 8]
			let a21 = this[ 9]
			let a22 = this[10]
			let a23 = this[11]
			// construct the elements of the rotation matrix.
			let b00 = x * x * t + c
			let b01 = y * x * t + z * s
			let b02 = z * x * t - y * s
			let b10 = x * y * t - z * s
			let b11 = y * y * t + c
			let b12 = z * y * t + x * s
			let b20 = x * z * t + y * s
			let b21 = y * z * t - x * s
			let b22 = z * z * t + c
			// perform rotation-specific matrix multiplication.
			this[ 0] = a00 * b00 + a10 * b01 + a20 * b02
			this[ 1] = a01 * b00 + a11 * b01 + a21 * b02
			this[ 2] = a02 * b00 + a12 * b01 + a22 * b02
			this[ 3] = a03 * b00 + a13 * b01 + a23 * b02
			this[ 4] = a00 * b10 + a10 * b11 + a20 * b12
			this[ 5] = a01 * b10 + a11 * b11 + a21 * b12
			this[ 6] = a02 * b10 + a12 * b11 + a22 * b12
			this[ 7] = a03 * b10 + a13 * b11 + a23 * b12
			this[ 8] = a00 * b20 + a10 * b21 + a20 * b22
			this[ 9] = a01 * b20 + a11 * b21 + a21 * b22
			this[10] = a02 * b20 + a12 * b21 + a22 * b22
			this[11] = a03 * b20 + a13 * b21 + a23 * b22
			return this
		}

		frustum(left, right, bottom, top, near, far) {
			let rl = 1 / (right - left)
			let tb = 1 / (top - bottom)
			let nf = 1 / (near - far)
			this[ 0] = near * 2 * rl
			this[ 1] = 0
			this[ 2] = 0
			this[ 3] = 0
			this[ 4] = 0
			this[ 5] = near * 2 * tb
			this[ 6] = 0
			this[ 7] = 0
			this[ 8] = (right + left) * rl
			this[ 9] = (top + bottom) * tb
			this[10] = (far + near) * nf
			this[11] = -1
			this[12] = 0
			this[13] = 0
			this[14] = far * near * 2 * nf
			this[15] = 0
			return this
		}

		perspective(fovy, aspect, near, far) {
			let f = 1 / tan(fovy / 2)
			this[ 0] = f / aspect
			this[ 1] = 0
			this[ 2] = 0
			this[ 3] = 0
			this[ 4] = 0
			this[ 5] = f
			this[ 6] = 0
			this[ 7] = 0
			this[ 8] = 0
			this[ 9] = 0
			this[11] = -1
			this[12] = 0
			this[13] = 0
			this[15] = 0
			if (far != null && far != 1/0) {
				let nf = 1 / (near - far)
				this[10] = (far + near) * nf
				this[14] = 2 * far * near * nf
			} else {
				this[10] = -1
				this[14] = -2 * near
			}
			return this
		}

		ortho(left, right, bottom, top, near, far) {
			let w = 1.0 / (right - left)
			let h = 1.0 / (top - bottom)
			let p = 1.0 / (far - near)
			let x = (right + left) * w
			let y = (top + bottom) * h
			let z = (far + near) * p
			this[ 0] = 2 * w
			this[ 4] = 0
			this[ 8] = 0
			this[12] = -x
			this[ 1] = 0
			this[ 5] = 2 * h
			this[ 9] = 0
			this[13] = -y
			this[ 2] = 0
			this[ 6] = 0
			this[10] = -2 * p
			this[14] = -z
			this[ 3] = 0
			this[ 7] = 0
			this[11] = 0
			this[15] = 1
			return this
		}

		// NOTE: dir is the opposite of the direction vector pointing towards the target!
		look_at(dir, up) {
			let z = _v0.set(dir).normalize()
			let x = _v1.set(up).cross(z)
			if (!x.len2()) { // up and z are parallel, diverge them a little.
				if (abs(up.z) == 1)
					z.x += 0.0001
				else
					z.z += 0.0001
				z.normalize()
				x.set(up).cross(z)
			}
			x.normalize()
			let y = _v2.set(z).cross(x)
			this[ 0] = x[0]
			this[ 4] = y[0]
			this[ 8] = z[0]
			this[ 1] = x[1]
			this[ 5] = y[1]
			this[ 9] = z[1]
			this[ 2] = x[2]
			this[ 6] = y[2]
			this[10] = z[2]
			return this
		}

		compose(pos, quat, scale) {
			let x = quat[0]
			let y = quat[1]
			let z = quat[2]
			let w = quat[3]
			let x2 = x + x
			let y2 = y + y
			let z2 = z + z
			var xx = x * x2
			let xy = x * y2
			let xz = x * z2
			let yy = y * y2
			let yz = y * z2
 			let zz = z * z2
			let wx = w * x2
			let wy = w * y2
			let wz = w * z2
			let sx = scale[0]
			let sy = scale[1]
			let sz = scale[2]
			this[ 0] = (1 - (yy + zz)) * sx
			this[ 1] = (xy + wz) * sx
			this[ 2] = (xz - wy) * sx
			this[ 3] = 0
			this[ 4] = (xy - wz) * sy
			this[ 5] = (1 - (xx + zz)) * sy
			this[ 6] = (yz + wx) * sy
			this[ 7] = 0
			this[ 8] = (xz + wy) * sz
			this[ 9] = (yz - wx) * sz
			this[10] = (1 - (xx + yy)) * sz
			this[11] = 0
			this[12] = pos[0]
			this[13] = pos[1]
			this[14] = pos[2]
			this[15] = 1
			return this
		}

		// http://www.gamedev.net/reference/articles/article1199.asp
		rotation(axis, angle) {
			let c = cos(angle)
			let s = sin(angle)
			let t = 1 - c
			let x = axis[0]
			let y = axis[1]
			let z = axis[2]
			let tx = t * x
			let ty = t * y
			this.set(
				tx * x + c    , tx * y - s * z, tx * z + s * y, 0,
				tx * y + s * z, ty * y + c    , ty * z - s * x, 0,
				tx * z - s * y, ty * z + s * x, t * z * z + c , 0,
				0             ,              0,              0, 1)
			return this
		}

	}

	mat4_class.prototype.is_mat4 = true

	property(mat4_class, 'e11', function() { return this[ 0] }, function(v) { this[ 0] = v })
	property(mat4_class, 'e21', function() { return this[ 1] }, function(v) { this[ 1] = v })
	property(mat4_class, 'e31', function() { return this[ 2] }, function(v) { this[ 2] = v })
	property(mat4_class, 'e41', function() { return this[ 3] }, function(v) { this[ 3] = v })
	property(mat4_class, 'e12', function() { return this[ 4] }, function(v) { this[ 4] = v })
	property(mat4_class, 'e22', function() { return this[ 5] }, function(v) { this[ 5] = v })
	property(mat4_class, 'e32', function() { return this[ 6] }, function(v) { this[ 6] = v })
	property(mat4_class, 'e42', function() { return this[ 7] }, function(v) { this[ 7] = v })
	property(mat4_class, 'e13', function() { return this[ 8] }, function(v) { this[ 8] = v })
	property(mat4_class, 'e23', function() { return this[ 9] }, function(v) { this[ 9] = v })
	property(mat4_class, 'e33', function() { return this[10] }, function(v) { this[10] = v })
	property(mat4_class, 'e43', function() { return this[11] }, function(v) { this[11] = v })
	property(mat4_class, 'e14', function() { return this[12] }, function(v) { this[12] = v })
	property(mat4_class, 'e24', function() { return this[13] }, function(v) { this[13] = v })
	property(mat4_class, 'e34', function() { return this[14] }, function(v) { this[14] = v })
	property(mat4_class, 'e44', function() { return this[15] }, function(v) { this[15] = v })

	let mat4 = function(elements) { return new mat4_class(elements) }
	mat4.class = mat4_class

	mat4.mul = function mul(a, b, out) {

		let a11 = a[ 0]
		let a21 = a[ 1]
		let a31 = a[ 2]
		let a41 = a[ 3]
		let a12 = a[ 4]
		let a22 = a[ 5]
		let a32 = a[ 6]
		let a42 = a[ 7]
		let a13 = a[ 8]
		let a23 = a[ 9]
		let a33 = a[10]
		let a43 = a[11]
		let a14 = a[12]
		let a24 = a[13]
		let a34 = a[14]
		let a44 = a[15]

		let b11 = b[ 0]
		let b21 = b[ 1]
		let b31 = b[ 2]
		let b41 = b[ 3]
		let b12 = b[ 4]
		let b22 = b[ 5]
		let b32 = b[ 6]
		let b42 = b[ 7]
		let b13 = b[ 8]
		let b23 = b[ 9]
		let b33 = b[10]
		let b43 = b[11]
		let b14 = b[12]
		let b24 = b[13]
		let b34 = b[14]
		let b44 = b[15]

		out[ 0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41
		out[ 4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42
		out[ 8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43
		out[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44
		out[ 1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41
		out[ 5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42
		out[ 9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43
		out[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44
		out[ 2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41
		out[ 6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42
		out[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43
		out[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44
		out[ 3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41
		out[ 7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42
		out[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43
		out[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44

		return out
	}

	return mat4

}

let mat4_ident = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
mat4    = mat4_type(Array, mat4_ident)
mat4f32 = mat4_type(f32arr, [mat4_ident])

mat4.identity = mat4()
mat4f32.identity = mat4f32()

// quaternion ----------------------------------------------------------------

let quat_class = class q extends Array {

	constructor(x, y, z, w) {
		super(x || 0, y || 0, z || 0, or(w, 1))
	}

	set(x, y, z, w) {
		if (x.is_quat) {
			let v = x
			x = v[0]
			y = v[1]
			z = v[2]
			w = v[3]
		}
		this[0] = x
		this[1] = y
		this[2] = z
		this[3] = or(w, 1)
		return this
	}

	assign(v) {
		assert(v.is_quat)
		return assign(this, v)
	}

	to(v) {
		return v.set(this)
	}

	reset() {
		return this.set(0, 0, 0, 1)
	}

	clone() {
		return quat().set(this)
	}

	equals(q) {
		return (
			q[0] === this[0] &&
			q[1] === this[1] &&
			q[2] === this[2] &&
			q[3] === this[3]
		)
	}

	from_array(a, i) {
		this[0] = a[i  ]
		this[1] = a[i+1]
		this[2] = a[i+2]
		this[3] = a[i+3]
		return this
	}

	to_array(a, i) {
		a[i  ] = this[0]
		a[i+1] = this[1]
		a[i+2] = this[2]
		a[i+3] = this[3]
		return a
	}

	from_quat_array(a, i) { return this.from_array(a, 4 * i) }

	to_quat_array(a, i) { return this.to_array(a, 4 * i) }

	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm
	// assumes axis is normalized
	set_from_axis_angle(axis, angle) {
		let s = sin(angle / 2)
		this[0] = axis[0] * s
		this[1] = axis[1] * s
		this[2] = axis[2] * s
		this[3] = cos(angle / 2)
		return this
	}

	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
	// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
	set_from_rotation_matrix(m) {
		let m11 = m[ 0]
		let m21 = m[ 1]
		let m31 = m[ 2]
		let m12 = m[ 4]
		let m22 = m[ 5]
		let m32 = m[ 6]
		let m13 = m[ 8]
		let m23 = m[ 9]
		let m33 = m[10]
		let trace = m11 + m22 + m33
		if (trace > 0) {
			let s = 0.5 / sqrt(trace + 1.0)
			this[2] = 0.25 / s
			this[0] = (m32 - m23) * s
			this[1] = (m13 - m31) * s
			this[2] = (m21 - m12) * s
		} else if (m11 > m22 && m11 > m33) {
			let s = 2.0 * sqrt(1.0 + m11 - m22 - m33)
			this[2] = (m32 - m23) / s
			this[0] = 0.25 * s
			this[1] = (m12 + m21) / s
			this[2] = (m13 + m31) / s
		} else if (m22 > m33) {
			let s = 2.0 * sqrt(1.0 + m22 - m11 - m33)
			this[2] = (m13 - m31) / s
			this[0] = (m12 + m21) / s
			this[1] = 0.25 * _s2
			this[2] = (m23 + m32) / s
		} else {
			let s = 2.0 * sqrt(1.0 + m33 - m11 - m22)
			this[2] = (m21 - m12) / s
			this[0] = (m13 + m31) / s
			this[1] = (m23 + m32) / s
			this[2] = 0.25 * s
		}
		return this
	}

	// assumes direction vectors are normalized.
	set_from_unit_vectors(from, to) {
		let EPS = 0.000001
		let r = from.dot(to) + 1
		if (r < EPS) {
			r = 0
			if (abs(from[0]) > abs(from[2])) {
				this[0] = -from[1]
				this[1] =  from[0]
				this[2] =  0
			} else {
				this[0] =  0
				this[1] = -from[2]
				this[2] =  from[1]
			}
		} else {
			v3.cross(from, to, this)
		}
		this[3] = r
		return this.normalize()
	}

	rotate_towards(q, step) {
		let angle = this.angle_to(q)
		if (angle === 0) return this
		let t = min(1, step / angle)
		this.slerp(q, t)
		return this
	}

	conjugate() {
		this[0] *= -1
		this[1] *= -1
		this[2] *= -1
		return this
	}

	// quaternion is assumed to have unit length.
	invert() {
		return this.conjugate()
	}

	len2() {
		return (
			this[0] ** 2 +
			this[1] ** 2 +
			this[2] ** 2 +
			this[3] ** 2
		)
	}

	len() {
		return sqrt(this.len2())
	}

	normalize() {
		let l = this.len()
		if (l === 0) {
			this.reset()
		} else {
			l = 1 / l
			this[0] *= l
			this[1] *= l
			this[2] *= l
			this[3] *= l
		}
		return this
	}

	angle_to(q) {
		return 2 * acos(abs(clamp(this.dot(q), -1, 1)))
	}

	dot(v) {
		return this[0] * v[0] + this[1] * v[1] + this[2] * v[2] + this[3] * v[3]
	}

	mul(q, p) {
		return quat.mul(this, q, this)
	}

	premul(q) {
		return quat.mul(q, this, this)
	}

	// http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/
	slerp(qb, t) {
		if (t === 0) return this
		if (t === 1) return this.set(qb)
		let x = this[0]
		let y = this[1]
		let z = this[2]
		let w = this[3]

		let cos_half_angle = w * qb.w + x * qb.x + y * qb.y + z * qb.z

		if (cos_half_angle < 0) {
			this.w = -qb.w
			this.x = -qb.x
			this.y = -qb.y
			this.z = -qb.z
			cos_half_angle = -cos_half_angle
		} else {
			this.set(qb)
		}

		if (cos_half_angle >= 1.0) {
			this.w = w
			this.x = x
			this.y = y
			this.z = z
			return this
		}

		let sqr_sin_half_angle = 1.0 - cos_half_angle * cos_half_angle

		if (sqr_sin_half_angle <= NEAR) {
			let s = 1 - t
			this.w = s * w + t * this.w
			this.x = s * x + t * this.x
			this.y = s * y + t * this.y
			this.z = s * z + t * this.z
			this.normalize()
			return this
		}

		let sin_half_angle = sqrt(sqr_sin_half_angle)
		let half_angle = atan2(sin_half_angle, cos_half_angle)
		let r1 = sin((1 - t) * half_angle) / sin_half_angle
		let r2 = sin(t * half_angle) / sin_half_angle
		this.w = w * r1 + this.w * r2
		this.x = x * r1 + this.x * r2
		this.y = y * r1 + this.y * r2
		this.z = z * r1 + this.z * r2

		return this
	}
}

quat_class.prototype.is_quat = true

property(quat_class, 'x', function() { return this[0] }, function(v) { this[0] = v })
property(quat_class, 'y', function() { return this[1] }, function(v) { this[1] = v })
property(quat_class, 'z', function() { return this[2] }, function(v) { this[2] = v })
property(quat_class, 'w', function() { return this[3] }, function(v) { this[3] = v })

quat = function(x, y, z, w) { return new quat_class(x, y, z, w) }
quat.class = quat_class
quat3 = quat

// from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm
quat.mul = function mul(a, b, out) {
	let qax = a[0]
	let qay = a[1]
	let qaz = a[2]
	let qaw = a[3]
	let qbx = b[0]
	let qby = b[1]
	let qbz = b[2]
	let qbw = b[3]
	out[0] = qax * qbw + qaw * qbx + qay * qbz - qaz * qby
	out[1] = qay * qbw + qaw * qby + qaz * qbx - qax * qbz
	out[2] = qaz * qbw + qaw * qbz + qax * qby - qay * qbx
	out[3] = qaw * qbw - qax * qbx - qay * qby - qaz * qbz
	return out
}

let _q0 = quat() // for v3

// plane ---------------------------------------------------------------------

let _m3_1 = mat3()

let plane_class = class plane {

	constructor(normal, constant) {
		this.normal = normal || v3.up.clone()
		this.constant = constant || 0
	}

	set(normal, constant) {
		if (normal.is_plane) {
			let pl = normal
			this.normal.set(pl.normal)
			this.constant = pl.constant
		} else {
			this.normal.set(normal)
			this.constant = constant
		}
		return this
	}

	assign(v) {
		assert(v.is_plane)
		let normal = this.normal
		assign(this, v)
		this.normal = normal.assign(v.normal)
	}

	to(v) {
		return v.set(this)
	}

	clone() {
		return new plane(this.normal, this.constant)
	}

	equals(v) {
		return v.normal.equals(this.normal) && v.constant === this.constant
	}

	set_from_normal_and_coplanar_point(normal, v) {
		this.normal.set(normal)
		this.constant = -v.dot(this.normal)
		return this
	}

	set_from_coplanar_points(a, b, c) {
		let normal = _v1.set(c).sub(b).cross(_v2.set(a).sub(b)).normalize()
		this.set_from_normal_and_coplanar_point(normal, a)
		return this
	}

	// Newell's method.
	set_from_poly(poly) {
		let n = poly.point_count()
		assert(n >= 3)
		let pn = _v1.set(0, 0, 0)
		let p1 = poly.get_point(0, _v2)
		for (let i = 1; i <= n; i++) {
			let p2 = poly.get_point(i % n, _v3)
			pn[0] += (p1[1] - p2[1]) * (p1[2] + p2[2])
			pn[1] += (p1[2] - p2[2]) * (p1[0] + p2[0])
			pn[2] += (p1[0] - p2[0]) * (p1[1] + p2[1])
			p1.set(p2)
		}
		pn.normalize()
		return this.set_from_normal_and_coplanar_point(pn, p1)
	}

	normalize() {
		// Note: will lead to a divide by zero if the plane is invalid.
		let inv_len = 1.0 / this.normal.len()
		this.normal.muls(inv_len)
		this.constant *= inv_len
		return this
	}

	negate() {
		this.constant *= -1
		this.normal.negate()
		return this
	}

	distance_to_point(p) {
		return this.normal.dot(p) + this.constant
	}

	project_point(p, out) {
		assert(p != out)
		return out.set(this.normal).muls(-this.distance_to_point(p)).add(p)
	}

	intersect_line(line, out, mode) {
		let dir = line.delta(_v1)
		let denom = this.normal.dot(dir)
		if (abs(denom) < NEAR)
			return // line is on the plane
		let t = -(line[0].dot(this.normal) + this.constant) / denom
		let p = out.set(dir).muls(t).add(line[0])
		if (mode == 'strict' && (t < 0 || t > 1))
			return // intersection point is outside of the line segment.
		p.t = t
		return p
	}

	intersects_line(line) {
		let d1 = this.distance_to_point(line[0])
		let d2 = this.distance_to_point(line[1])
		return (
			(d2 < -NEAR && d1 > NEAR && 'through-front') ||
			(d1 < -NEAR && d2 > NEAR && 'through-back') ||
			(d1 >= -NEAR && d2 >= -NEAR && 'in-front') || 'behind'
		)
	}

	// shorten line to only the part that's in front of the plane.
	clip_line(line) {
		let hit = this.intersects_line(line)
		line.clip = hit
		if (hit == 'in-front')
			return line
		if (hit == 'behind')
			return
		let int_p = this.intersect_line(line, _v4, 'strict')
		if (!int_p) // line is on the plane or not intersecting the plane.
			return line
		if (hit == 'through-front')
			line[1].set(int_p)
		else
			line[0].set(int_p)
		return line
	}

	// project the plane's normal at origin onto the plane.
	origin(out) {
		return out.set(this.normal).muls(-this.constant)
	}

	translate(offset) {
		this.constant -= offset.dot(this.normal)
		return this
	}

	transform(m) {
		let nm = m.normal(_m3_1)
		let ref_p = this.origin(_v0).transform(m)
		let normal = this.normal.transform(nm).normalize()
		this.constant = -ref_p.dot(normal)
		return this
	}

}

plane_class.prototype.is_plane = true

plane = function(normal, constant) { return new plane_class(normal, constant) }
plane.class = plane_class
plane3 = plane // so you can do `let plane = plane3()`.

// triangle3 -----------------------------------------------------------------

let triangle3_class = class triangle3 extends Array {

	constructor(a, b, c) {
		super(a || v3(), b || v3(), c || v3())
	}

	set(a, b, c) {
		if (a.is_triangle) {
			let t = a
			this[0].set(t[0])
			this[1].set(t[1])
			this[2].set(t[2])
		} else {
			this[0].set(a)
			this[1].set(b)
			this[2].set(c)
		}
		return this
	}

	assign(v) {
		assert(v.is_triangle)
		let p0 = this[0]
		let p1 = this[0]
		let p2 = this[0]
		assign(this, v)
		this[0] = p0.assign(v[0])
		this[1] = p1.assign(v[1])
		this[2] = p2.assign(v[2])
	}

	to(v) {
		return v.set(this)
	}

	clone() {
		return new triangle3().set(this)
	}

	equals(t) {
		return (
			t[0].equals(this[0]) &&
			t[1].equals(this[1]) &&
			t[2].equals(this[2])
		)
	}

	from_array(a, i) {
		this[0][0] = a[i+0]
		this[0][1] = a[i+1]
		this[0][2] = a[i+2]
		this[1][0] = a[i+3]
		this[1][1] = a[i+4]
		this[1][2] = a[i+5]
		this[2][0] = a[i+6]
		this[2][1] = a[i+7]
		this[2][2] = a[i+8]
		return this
	}

	to_array(a, i) {
		a[i+0] = this[0][0]
		a[i+1] = this[0][1]
		a[i+2] = this[0][2]
		a[i+3] = this[1][0]
		a[i+4] = this[1][1]
		a[i+5] = this[1][2]
		a[i+6] = this[2][0]
		a[i+7] = this[2][1]
		a[i+8] = this[2][2]
		return a
	}

	from_triangle3_array(a, i) { return this.from_array(a, 9 * i) }

	to_triangle3_array(a, i) { return this.to_array(a, 9 * i) }

	area() {
		_v0.set(this[2]).sub(this[1])
		_v1.set(this[0]).sub(this[1])
		return _v0.cross(_v1).len() * 0.5
	}

	midpoint(out) {
		return out.set(this[0]).add(this[1]).add(this[2]).muls(1 / 3)
	}

	normal(out) {
		return triangle3.normal(this[0], this[1], this[2], out)
	}

	plane(out) {
		return out.set_from_coplanar_points(this[0], this[1], this[2])
	}

	barycoord(p, out) {
		return triangle3.barycoord(p, this[0], this[1], this[2], out)
	}

	uv(p, uv1, uv2, uv3, out) {
		return triangle3.uv(p, this[0], this[1], this[2], uv1, uv2, uv3, out)
	}

	contains_point(p) {
		return triangle3.contains_point(p, this[0], this[1], this[2])
	}

	is_front_facing(direction) {
		return triangle3.is_front_facing(this[0], this[1], this[2], direction)
	}

}

triangle3_class.prototype.is_triangle3 = true

triangle3 = function(a, b, c) { return new triangle3_class(a, b, c) }
triangle3.class = triangle3_class

triangle3.normal = function normal(a, b, c, out) {
	out.set(c).sub(b)
	_v0.set(a).sub(b)
	out.cross(_v0)
	let out_len2 = out.len2()
	if (out_len2 > 0)
		return out.muls(1 / sqrt(out_len2))
	return out.set(0, 0, 0)
}

// static/instance method to calculate barycentric coordinates
// http://www.blackpawn.com/texts/pointinpoly/default.html
triangle3.barycoord = function barycoord(p, a, b, c, out) {
	_v0.set(c).sub(a)
	_v1.set(b).sub(a)
	_v2.set(p).sub(a)
	let dot00 = _v0.dot(_v0)
	let dot01 = _v0.dot(_v1)
	let dot02 = _v0.dot(_v2)
	let dot11 = _v1.dot(_v1)
	let dot12 = _v1.dot(_v2)
	let denom = dot00 * dot11 - dot01 * dot01
	if (denom == 0)
		return
	let inv_denom = 1 / denom
	let u = (dot11 * dot02 - dot01 * dot12) * inv_denom
	let v = (dot00 * dot12 - dot01 * dot02) * inv_denom // barycentric coordinates must always sum to 1
	return out.set(1 - u - v, v, u)
}

triangle3.contains_point = function contains_point(p, a, b, c) {
	let bc = this.barycoord(p, a, b, c, _v3)
	let x = bc[0]
	let y = bc[1]
	return x >= 0 && y >= 0 && x + y <= 1
}

triangle3.uv = function uv(p, p1, p2, p3, uv1, uv2, uv3, out) {
	let bc = this.barycoord(p, p1, p2, p3, _v3)
	out.set(0, 0)
	out.add(uv1, bc[0])
	out.add(uv2, bc[1])
	out.add(uv3, bc[2])
	return out
}

triangle3.is_front_facing = function is_front_facing(a, b, c, direction) {
	let p = _v0.set(c).sub(b)
	let q = _v1.set(a).sub(b) // strictly front facing
	return p.cross(q).dot(direction) < 0
}

// poly3 ---------------------------------------------------------------------

let poly3_cons = function(_this, opt, elements) {
	assign(_this, opt)
	_this.invalid = true
}

let poly3_class = class poly3 extends Array {

	constructor(opt, elements) {
		if (elements)
			super(...elements)
		else
			super()
		poly3_cons(this, opt, elements)
	}

	to(v) {
		return v.set(this)
	}

}

let poly3p = poly3_class.prototype

poly3p.is_poly3 = true

poly3 = function(opt, elements) { return new poly3_class(opt, elements) }
poly3.class = poly3_class

poly3.subclass = function(methods) {
	let cls = class poly3 extends Array {
		constructor(opt, elements) {
			if (elements)
				super(...elements)
			else
				super()
			poly3_cons(this, opt, elements)
		}
	}
	assign(cls.prototype, poly3_class.prototype, methods) // static inheritance (keep lookup chain short).
	let cons = function(opt, elements) { return new cls(opt, elements) }
	cons.class = cls
	return cons
}

// point accessor stubs. replace in subclasses based on how the points are stored.
poly3p.point_count = function point_count() {
	return this.length
}
poly3p.get_point = function get_point(i, out) {
	return out.from_v3_array(this.points, this[i])
}
poly3p.get_normal = function(i, out) {
	return out.set(this.plane().normal)
}

poly3p._update_plane = function() {
	let pl = this._plane || plane()
	this._plane = pl
	pl.set_from_poly(this)
}
poly3p.plane = function() {
	return this._update_if_invalid()._plane
}

// xy_quat projects points on the xy plane for in-plane calculations.
poly3p._update_xy_quat = function() {
	if (!this._xy_quat)
		this._xy_quat = quat()
	this._xy_quat.set_from_unit_vectors(this._plane.normal, v3.z_axis)
}
poly3p.xy_quat = function() {
	return this._update_if_invalid()._xy_quat
}

// check if a polygon is a convex quad (the most common case for trivial triangulation).
{
	let a = v3()
	let c = v3()
	let v = v3()
	let m = mat3()
	let cross_sign = function(_a, _b, _c) {
		v3.sub(_a, _b, a)
		v3.sub(_c, _b, c)
		v3.cross(a, c, v)
		// compute the signed volume between ab, cb and ab x cb.
		// the sign tells you the direction of the cross vector.
		m.set(
			v[0], a[0], c[0],
			v[1], a[1], c[1],
			v[2], a[2], c[2]
		)
		return sign(m.det())
	}

	let p0 = v3()
	let p1 = v3()
	let p2 = v3()
	let p3 = v3()
	poly3p.is_convex_quad = function is_convex_quad() {
		if (this.point_count() != 4)
			return false
		this.get_point(0, p0)
		this.get_point(1, p1)
		this.get_point(2, p2)
		this.get_point(3, p3)
		let s0 = cross_sign(p0, p1, p2)
		let s1 = cross_sign(p1, p2, p3)
		let s2 = cross_sign(p2, p3, p0)
		let s3 = cross_sign(p3, p0, p1)
		let sr = abs(s0) >= NEAR ? s0 : s1 // one (and only one) of them can be zero.
		return (
			   (s0 == 0 || s0 == sr)
			&& (s1 == 0 || s1 == sr)
			&& (s2 == 0 || s2 == sr)
			&& (s3 == 0 || s3 == sr)
		)
	}
}

poly3p.triangle_count = function() {
	return 3 * (this.point_count() - 2)
}

{
let ps = []
poly3p._update_triangles = function() {
	let tri_count = this.triangle_count()
	let out = this._triangles
	let pn = this.point_count()
	if (pn == 3) { // triangle: nothing to do, push points directly.
		if (!out)
			out = [0, 0, 0]
		else if (out.length != 3)
			out.length = 3
		out[0] = 0
		out[1] = 1
		out[2] = 2
	} else if (pn == 4 && this.is_convex_quad()) { // convex quad: most common case.
		if (!out)
			out = [0, 0, 0, 0, 0, 0]
		else if (out.length != 6)
			out.length = 6
		// triangle 1
		out[0] = 2
		out[1] = 3
		out[2] = 0
		// triangle 2
		out[3] = 0
		out[4] = 1
		out[5] = 2
	} else {
		ps.length = pn * 2
		let xy_quat = this.xy_quat()
		for (let i = 0; i < pn; i++) {
			let p = this.get_point(i, _v0).transform(xy_quat)
			ps[2*i+0] = p[0]
			ps[2*i+1] = p[1]
		}
		out = earcut2(ps, null, 2)
	}
	this._triangles = out
}
}

poly3p.triangles = function() {
	return this._update_if_invalid()._triangles
}

poly3p.triangle = function(ti, out) {
	assert(out.is_triangle3)
	let teis = this.triangles()
	this.get_point(teis[3*ti+0], out[0])
	this.get_point(teis[3*ti+1], out[1])
	this.get_point(teis[3*ti+2], out[2])
	return out
}

// from https://www.iquilezles.org/www/articles/normals/normals.htm
{
let p1 = v3()
let p2 = v3()
let p3 = v3()
poly3p.compute_smooth_normals = function(normals, normalize) {

	let teis = this.triangles()
	let points = this.points
	for (let i = 0, n = teis.length; i < n; i += 3) {

		let p1i = this[teis[i+0]]
		let p2i = this[teis[i+1]]
		let p3i = this[teis[i+2]]

		p3.from_array(points, 3*p3i)
		p1.from_array(points, 3*p1i).sub(p3)
		p2.from_array(points, 3*p2i).sub(p3)

		let p = p1.cross(p2)

		normals[3*p1i+0] += p[0]
		normals[3*p1i+1] += p[1]
		normals[3*p1i+2] += p[2]

		normals[3*p2i+0] += p[0]
		normals[3*p2i+1] += p[1]
		normals[3*p2i+2] += p[2]

		normals[3*p3i+0] += p[0]
		normals[3*p3i+1] += p[1]
		normals[3*p3i+2] += p[2]
	}

	if (normalize)
		for (let i = 0, n = normals.length; i < n; i += 3) {
			p1.from_array(normals, i)
			p1.normalize()
			p1.to_array(normals, i)
		}

	return normals
}}

{
let _tri = triangle3()
poly3p.contains_point = function(p) {
	for (let ti = 0, tn = this.triangle_count(); ti < tn; ti++)
		if (this.triangle(ti, _tri).contains_point(p))
			return true
	return false
}
}

// (tex_uv) are 1 / (texture's (u, v) in world space).
{
let _v2_0 = v2()
let _v2_1 = v2()
poly3p.uv_at = function(i, uvm, tex_uv, out) {
	let xy_quat = this.xy_quat()
	let p0 = _v2_0.set(this.get_point(0, _v0).transform(xy_quat))
	let pi = _v2_1.set(this.get_point(i, _v1).transform(xy_quat))
	pi.sub(p0).mul(tex_uv)
	if (uvm)
		pi.transform(uvm)
	out[0] = pi[0]
	out[1] = pi[1]
	return out
}}

poly3p.uvs = function(uvm, tex_uv, out) {
	for (let i = 0, n = this.point_count(); i < n; i++) {
		let uv = this.uv_at(i, uvm, tex_uv, _v1)
		out[2*i+0] = uv[0]
		out[2*i+1] = uv[1]
	}
	return out
}

poly3p._update_if_invalid = function() {
	if (this.invalid)
		this._update()
	return this
}

poly3p._update = function() {
	this.invalid = false
	this._update_plane()
	this._update_xy_quat()
	this._update_triangles()
	return this
}

poly3p.invalidate = function() {
	this.invalid = true
	return this
}

poly3p.center = function(out) {
	for (let i = 0, n = this.point_count(); i < n; i++)
		out.add(this.get_point(i, _v0))
	let len = this.length
	out.x /= len
	out.y /= len
	out.z /= len
	return out
}


/*
// region-finding algorithm --------------------------------------------------

// The algorithm below is O(n log n) and it's from the paper:
//   "An optimal algorithm for extracting the regions of a plane graph"
//   X.Y. Jiang and H. Bunke, 1992.

// return a number from the range [0..4] which is monotonic
// in the angle that the input vector makes against the x axis.
function v2_pseudo_angle(dx, dy) {
	let p = dx / (abs(dx) + abs(dy))  // -1..1 increasing with x
	return dy < 0 ? 3 + p : 1 - p     //  2..4 or 0..2 increasing with x
}

poly3_class.regions = function() {

	if (this._regions)
		return this._regions

	let pp = this.project_xy()

	// phase 1: find all wedges.

	// step 1+2: make pairs of directed edges from all the edges and compute
	// their angle-to-horizontal so that they can be then sorted by that angle.
	let edges = [] // [[p1i, p2i, angle], ...]
	let p1 = v3()
	let p2 = v3()
	for (let i = 0, n = pp.point_count(); i < n; i++) {
		let p1i = i
		let p2i = (i+1) % n
		pp.get_point(p1i, p1)
		pp.get_point(p2i, p2)
		edges.push(
			[p1i, p2i, v2_pseudo_angle(p2[0] - p1[0], p2[1] - p1[1])],
			[p2i, p1i, v2_pseudo_angle(p1[0] - p2[0], p1[1] - p2[1])])
	}

	// step 3: sort by edges by (p1, angle).
	edges.sort(function(e1, e2) {
		if (e1[0] == e2[0])
			return e1[2] < e2[2] ? -1 : (e1[2] > e2[2] ? 1 : 0)
		else
			return e1[0] < e2[0] ? -1 : 1
	})

	// for (let e of edges) { print('e', e[0]+1, e[1]+1) }

	// step 4: make wedges from edge groups formed by edges with the same p1.
	let wedges = [] // [[p1i, p2i, p3i, used], ...]
	let wedges_first_pi = edges[0][1]
	for (let i = 0; i < edges.length; i++) {
		let edge = edges[i]
		let next_edge = edges[i+1]
		let same_group = next_edge && edge[0] == next_edge[0]
		if (same_group) {
			wedges.push([edge[1], edge[0], next_edge[1], false])
		} else {
			wedges.push([edge[1], edge[0], wedges_first_pi, false])
			wedges_first_pi = next_edge && next_edge[1]
		}
	}

	// for (let w of wedges) { print('w', w[0]+1, w[1]+1, w[2]+1) }

	// phase 2: group wedges into regions.

	// step 1: sort wedges by (p1, p2) so we can binsearch them by the same key.
	wedges.sort(function(w1, w2) {
		if (w1[0] == w2[0])
			return w1[1] < w2[1] ? -1 : (w1[1] > w2[1] ? 1 : 0)
		else
			return w1[0] < w2[0] ? -1 : 1
	})

	// for (let w of wedges) { print('w', w[0]+1, w[1]+1, w[2]+1) }

	// step 2: mark all wedges as unused (already did on construction).
	// step 3, 4, 5: find contiguous wedges and group them into regions.
	// NOTE: the result also contans the outer region which goes clockwise
	// while inner regions go anti-clockwise.
	let regions = [] // [[p1i, p2i, ...], ...]
	let k = [0, 0] // reusable (p1i, p2i) key for binsearch.
	function cmp_wedges(w1, w2) { // binsearch comparator on wedge's (p1i, p2i).
		return w1[0] == w2[0] ? w1[1] < w2[1] : w1[0] < w2[0]
	}
	for (let i = 0; i < wedges.length; i++) {
		let w0 = wedges[i]
		if (w0[3])
			continue // skip wedges marked used
		region = [w0[1]]
		regions.push(region)
		k[0] = w0[1]
		k[1] = w0[2]
		while (1) {
			let i = wedges.binsearch(k, cmp_wedges)
			let w = wedges[i]
			region.push(w[1])
			w[3] = true // mark used so we can skip it
			if (w[1] == w0[0] && w[2] == w0[1]) // cycle complete.
				break
			k[0] = w[1]
			k[1] = w[2]
		}
	}

	// for (let r of regions) { print('r', r.map(i => i+1)) }

	this._regions = regions
	return regions
}

// TODO: redo this test with a poly3
function test_plane_graph_regions() {
	let points = [
		v3(0, -5, 0),
		v3(-10, 0, 0), v3(10, 0, 0), v3(-10, 5, 0), v3(10, 5, 0),
		//v3(-5, 1, 0), v3(5,  1, 0), v3(-5, 4, 0), v3(5, 4, 0),
		//v3(0, -1, 0), v3(1, -2, 0),
	]
	let get_point = function(i, out) { out.set(points[i]); return out }
	let lines  = [0,1, 0,2,  1,2, 1,3, 2,4, 3,4,  ] // 5,6, 5,7, 6,8, 7,8,  0,9, 9,10]
	let rt = plane_graph_regions(v3(0, 0, 1), get_point, lines)
	for (let r of rt) { print(r.map(i => i+1)) }
}
// test_plane_graph_regions()
*/

// line3 ---------------------------------------------------------------------

let line3_class = class line3 extends Array {

	constructor(p0, p1) {
		super(p0 || v3(), p1 || v3())
	}

	set(p0, p1) {
		if (p0.is_line3) {
			let line = p0
			p0 = line[0]
			p1 = line[1]
		}
		this[0].set(p0)
		this[1].set(p1)
		return this
	}

	assign(v) {
		let p0 = this[0]
		let p1 = this[1]
		assign(this, v)
		this[0] = p0.assign(v[0])
		this[1] = p1.assign(v[1])
		return this
	}

	to(v) {
		return v.set(this)
	}

	clone() {
		return new line3().set(this[0], this[1])
	}

	equals(line) {
		return (
			line[0].equals(this[0]) &&
			line[1].equals(this[1])
		)
	}

	delta(out) {
		return v3.sub(this[1], this[0], out)
	}

	distance2() {
		return this[0].distance2(this[1])
	}

	distance() {
		return this[0].distance2(this[1])
	}

	at(t, out) {
		return this.delta(out).muls(t).add(this[0])
	}

	reverse() {
		let p0 = this[0]
		this[0] = this[1]
		this[1] = p0
		return this
	}

	len() {
		return this.delta(_v0).len()
	}

	set_len(len) {
		this[1].set(this.delta(_v0).set_len(len).add(this[0]))
		return this
	}

	to_array(a, i) {
		this[0].to_array(a, i)
		this[1].to_array(a, i+3)
		return a
	}

	to_line3_array(a, i) {
		this[0].to_v3_array(a, 2 * (i+0))
		this[1].to_v3_array(a, 2 * (i+1))
		return a
	}

	from_array(a, i) {
		this[0].from_array(a, i)
		this[1].from_array(a, i+3)
		return this
	}

	from_line3_array(a, i) {
		this[0].from_v3_array(a, 2 * (i+0))
		this[1].from_v3_array(a, 2 * (i+1))
		return this
	}

	closest_point_to_point_t(p, clamp_to_line) {
		let p0 = v3.sub(p, this[0], _v0)
		let p1 = v3.sub(this[1], this[0], _v1)
		let t = p1.dot(p0) / p1.dot(p1)
		if (clamp_to_line)
			t = clamp(t, 0, 1)
		return t
	}

	closest_point_to_point(p, clamp_to_line, out) {
		out.t = this.closest_point_to_point_t(p, clamp_to_line)
		return this.delta(out).muls(out.t).add(this[0])
	}

	transform(m) {
		this[0].transform(m)
		this[1].transform(m)
		return this
	}

	// returns the smallest line that connects two (coplanar or skewed) lines.
	// returns null for parallel lines.
	intersect_line(lq, out, mode) {
		let lp = this
		let rp = out[0]
		let rq = out[1]
		let p = lp[0]
		let q = lq[0]
		let mp = lp.delta(_v0)
		let mq = lq.delta(_v1)
		let qp = _v2.set(p).sub(q)

		let qp_mp = qp.dot(mp)
		let qp_mq = qp.dot(mq)
		let mp_mp = mp.dot(mp)
		let mq_mq = mq.dot(mq)
		let mp_mq = mp.dot(mq)

		let detp = qp_mp * mq_mq - qp_mq * mp_mq
		let detq = qp_mp * mp_mq - qp_mq * mp_mp
		let detm = mp_mq * mp_mq - mq_mq * mp_mp

		if (detm == 0) // lines are parallel
			return

		rp.set(p).add(mp.muls(detp / detm))
		rq.set(q).add(mq.muls(detq / detm))

		if (mode == 't' || mode == 'clamp') {
			let p1 = _v0.set(lp[1]).sub(lp[0])
			let p2 = _v1.set(rp).sub(lp[0])
			let tp = p2.len() / p1.len() * (p1.dot(p2) > 0 ? 1 : -1)
			p1.set(lq[1]).sub(lq[0])
			p2.set(rq).sub(lq[0])
			let tq = p2.len() / p1.len() * (p1.dot(p2) > 0 ? 1 : -1)
			rp.t = tp
			rq.t = tq
			if (mode == 'clamp') {
				if (tp < 0)
					rp.set(lp[0])
				else if (tp > 1)
					rp.set(lp[1])
				if (tq < 0)
					rq.set(lq[0])
				else if (tq > 1)
					rq.set(lq[1])
			}
		}

		return out
	}

	intersect_plane(plane, out, mode) {
		return plane.intersect_line(this, out, mode)
	}

	intersects_plane(plane) {
		return plane.intersects_line(this)
	}

}

line3_class.prototype.is_line3 = true

line3 = function(p1, p2) { return new line3_class(p1, p2) }

// box3 ----------------------------------------------------------------------

v3.inf = v3(inf, inf, inf)
v3.minus_inf = v3(-inf, -inf, -inf)

let box3_class = class box3 extends Array {

	constructor(min, max) {
		super(min || v3.inf.clone(), max || v3.minus_inf.clone())
	}

	set(min, max) {
		if (min.is_box3) {
			let b = min
			min = b[0]
			max = b[1]
		}
		this[0].set(min)
		this[1].set(max)
		return this
	}

	assign(v) {
		let min = this[0]
		let max = this[1]
		assign(this, v)
		this[0] = min.assign(v[0])
		this[1] = max.assign(v[1])
		return this
	}

	to(v) {
		return v.set(this)
	}

	clone() {
		return new box3().set(this)
	}

	equals(b) {
		return (
			this[0].equals(b[0]) &&
			this[1].equals(b[1])
		)
	}

	reset() {
		this[0].set(v3.inf)
		this[1].set(v3.minus_inf)
		return this
	}

	to_array(a, i) {
		this[0].to_array(a, i)
		this[1].to_array(a, i+3)
		return a
	}

	to_box3_array(a, i) {
		this[0].to_v3_array(a, 2 * (i+0))
		this[1].to_v3_array(a, 2 * (i+1))
		return a
	}

	from_array(a, i) {
		this[0].from_array(a, i)
		this[1].from_array(a, i+3)
		return this
	}

	from_box3_array(a, i) {
		this[0].from_v3_array(a, 2 * (i+0))
		this[1].from_v3_array(a, 2 * (i+1))
		return this
	}


	is_empty = function is_empty() {
		return (
			this[1][0] < this[0][0] ||
			this[1][1] < this[0][1] ||
			this[1][2] < this[0][2]
		)
	}

	add(v) {
		if (v.is_v3) {
			this[0].min(v)
			this[1].max(v)
		} else if (v.is_line3 || v.is_box3) {
			this[0].min(v[0]).min(v[1])
			this[1].max(v[0]).max(v[1])
		} else if (v.is_poly3) {
			for (let i = 0, n = v.point_count(); i < n; i++) {
				let p = v.get_point()
				this[0].min(p)
				this[1].max(p)
			}
		} else {
			assert(false)
		}
		return this
	}

	center = function(out) {
		return v3.add(this[0], this[1], .5)
	}

	delta(out) {
		return v3.sub(this[1], this[0], out)
	}

	contains_point(p) {
		return !(
			p[0] < this[0][0] || p[0] > this[1][0] ||
			p[1] < this[0][1] || p[1] > this[1][1] ||
			p[2] < this[0][2] || p[2] > this[1][2]
		)
	}

	contains_box(b) {
		return (
			this[0][0] <= b[0][0] && b[1][0] <= this[1][0] &&
			this[0][1] <= b[0][1] && b[1][1] <= this[1][1] &&
			this[0][2] <= b[0][2] && b[1][2] <= this[1][2]
		)
	}

	intersects_box(b) {
		// using 6 splitting planes to rule out intersections.
		return !(
			b[1][0] < this[0][0] || b[0][0] > this[1][0] ||
			b[1][1] < this[0][1] || b[0][1] > this[1][1] ||
			b[1][2] < this[0][2] || b[0][2] > this[1][2]
		)
	}

	transform(m) {
		if (this.is_empty())
			return this
		let v0 = this[0].to(_v0)
		let v1 = this[1].to(_v1)
		this.reset()
		this.add(_v2.set(v0[0], v0[1], v0[2]).transform(m))
		this.add(_v2.set(v0[0], v0[1], v1[2]).transform(m))
		this.add(_v2.set(v0[0], v1[1], v0[2]).transform(m))
		this.add(_v2.set(v0[0], v1[1], v1[2]).transform(m))
		this.add(_v2.set(v1[0], v0[1], v0[2]).transform(m))
		this.add(_v2.set(v1[0], v0[1], v1[2]).transform(m))
		this.add(_v2.set(v1[0], v1[1], v0[2]).transform(m))
		this.add(_v2.set(v1[0], v1[1], v1[2]).transform(m))
		return this
	}

	translate(v) {
		this[0].add(v)
		this[1].add(v)
		return this
	}

}

box3_class.prototype.is_box3 = true

property(box3_class, 'min', function() { return this[0] }, function(v) { this[0] = v })
property(box3_class, 'max', function() { return this[1] }, function(v) { this[1] = v })

box3 = function(x1, y1, x2, y2) { return new box3_class(x1, y1, x2, y2) }

// templates for parametric modeling -----------------------------------------

box3.points = new f32arr([
	-.5,  -.5,  -.5,
	 .5,  -.5,  -.5,
	 .5,   .5,  -.5,
	-.5,   .5,  -.5,
	-.5,  -.5,   .5,
	 .5,  -.5,   .5,
	 .5,   .5,   .5,
	-.5,   .5,   .5,
])

box3.line_pis = new u8arr([
	0, 1,  1, 2,  2, 3,  3, 0,
	4, 5,  5, 6,  6, 7,  7, 4,
	0, 4,  1, 5,  2, 6,  3, 7,
])

{
let _l0 = line3()
box3.each_line = function(f) {
	for (let i = 0, n = box3.line_pis.length; i < n; i += 2) {
		_l0[0][0] = box3.points[3*box3.line_pis[i+0]+0]
		_l0[0][1] = box3.points[3*box3.line_pis[i+0]+1]
		_l0[0][2] = box3.points[3*box3.line_pis[i+0]+2]
		_l0[1][0] = box3.points[3*box3.line_pis[i+1]+0]
		_l0[1][1] = box3.points[3*box3.line_pis[i+1]+1]
		_l0[1][2] = box3.points[3*box3.line_pis[i+1]+2]
		f(_l0)
	}
}}

box3.set_points = function(xd, yd, zd) {
	for (let i = 0; i < len * 3; i += 3) {
		pos[i+0] = box3.points[i+0] * xd
		pos[i+1] = box3.points[i+1] * yd
		pos[i+2] = box3.points[i+2] * zd
	}
	return this
}

box3.triangle_pis_front = new u8arr([
	3, 2, 1,  1, 0, 3,
	6, 7, 4,  4, 5, 6,
	2, 3, 7,  7, 6, 2,
	1, 5, 4,  4, 0, 1,
	7, 3, 0,  0, 4, 7,
	2, 6, 5,  5, 1, 2,
])

box3.triangle_pis_back = new u8arr(box3.triangle_pis_front)
for (let i = 0, a = box3.triangle_pis_back, n = a.length; i < n; i += 3) {
	let t = a[i]
	a[i] = a[i+1]
	a[i+1] = t
}

box3.triangle_pis_front.max_index = 7
box3.triangle_pis_back .max_index = 7

// camera --------------------------------------------------------------------

{
let _v4_0 = v4()
camera = function(e) {
	e = e || {}

	e.pos  = e.pos || v3(-1, 5, 10)
	e.dir  = e.dir || v3(-.5, .5, 1)
	e.up   = e.up  || v3(0, 1, 0)

	e.fov  = e.fov || 60
	e.near = e.near || 0.01

	e.proj = mat4()
	e.view = mat4()
	e.inv_proj = mat4()
	e.inv_view = mat4()
	e.view_proj = mat4()

	e.view_size = e.view_size || v2()

	e.set = function(c) {
		e.pos.set(c.pos)
		e.dir.set(c.dir)
		e.up.set(c.up)
		e.fov = c.fov
		e.near = c.near
		e.far = c.far
		e.proj.set(c.proj)
		e.view.set(c.view)
		e.inv_proj.set(c.inv_proj)
		e.inv_view.set(c.inv_view)
		e.view_proj.set(c.view_proj)
		return e
	}

	e.to = function(v) {
		return v.set(this)
	}

	e.clone = function() {
		return camera().set(e)
	}

	e.perspective = function() {
		let aspect = e.view_size[0] / e.view_size[1]
		e.proj.perspective(rad * e.fov, aspect, e.near, e.far)
		return this
	}

	e.ortho = function() {
		e.proj.ortho(-10, 10, -10, 10, -FAR, FAR)
		return this
	}

	e.dolly = function(target, t) {
		let d = e.pos.clone().sub(target)
		let len = d.len() * t
		if (abs(len) < NEAR) {
			e.pos.set(target)
		} else {
			if (len < 0)
				d.set_len(-len).negate()
			else
				d.set_len(len)
			e.pos.set(target).add(d)
		}
		return this
	}

	e.orbit = function(target, ax, ay, az) {
		let vdir = _v0.set(e.world_to_view(e.pos.clone().add(e.dir), _v4_0))
		vdir.rotate(v3.x_axis, -ax)
		vdir.rotate(v3.y_axis, -ay)
		vdir.rotate(v3.z_axis, -az)
		let dir = e.view_to_world(vdir, _v2).sub(e.pos)
		e.dir.set(dir)
		let vtarget = e.world_to_view(target, _v4_0)
		let vpos = _v3.set(vtarget).negate()
		vpos.rotate(v3.x_axis, -ax)
		vpos.rotate(v3.y_axis, -ay)
		vpos.rotate(v3.z_axis, -az)
		vpos.add(vtarget)
		let pos = e.view_to_world(vpos, _v4)
		e.pos.set(pos)
		return this
	}

	e.pan = function(target, x0, y0, x1, y1) {
		let q = e.screen_to_view(x0, y0, 1, v4())
		let t = e.screen_to_view(x1, y1, 1, v4()).sub(q)
		let p = e.world_to_view(target, v4())
		let s = t.muls(p.len() / q.len()).negate().transform(e.inv_view)
		e.pos.add(s)
		return this
	}

	e.update = function() {
		e.inv_proj.set(e.proj).invert()
		e.inv_view.reset().translate(e.pos).look_at(e.dir, e.up)
		e.view.set(e.inv_view).invert()
		mat4.mul(e.proj, e.view, e.view_proj)
		return this
	}

	// space conversions from https://antongerdelan.net/opengl/raycasting.html

	e.world_to_view = function(p, out) {
		assert(out.is_v4)
		return out.set(p).transform(e.view)
	}

	e.view_to_clip = function(p, out) {
		assert(out.is_v4)
		return out.set(p).transform(e.proj)
	}

	e.world_to_clip = function(p, out) {
		assert(out.is_v4)
		return out.set(p).transform(e.view_proj)
	}

	e.clip_to_screen = function(p, out) {
		assert(out.is_v2 || out.is_v3)
		let w = p[3]
		out[0] = round(( (p[0] / w) + 1) * e.view_size[0] / 2)
		out[1] = round((-(p[1] / w) + 1) * e.view_size[1] / 2)
		if (out.is_v3)
			out[2] = 0
		return out
	}

	e.world_to_screen = function(p, out) {
		let cp = e.world_to_clip(p, _v4_0)
		return e.clip_to_screen(cp, out)
	}

	// (0..w, 0..h, z) -> (-1..1, -1..1, z)
	e.screen_to_clip = function(x, y, z, out) {
		let w = e.view_size[0]
		let h = e.view_size[1]
		assert(out.is_v4)
		out[0] = (2 * x) / w - 1
		out[1] = 1 - (2 * y) / h
		out[2] = or(z, 1)
		out[3] = 1
		return out
	}

	// (-1..1, -1..1, 1..-1, 1) -> frustum space (z in 0..100, for a 0.01..inf frustrum)
	e.clip_to_view = function(p, out) {
		assert(out.is_v4)
		return out.set(p).transform(e.inv_proj)
	}

	e.view_to_world = function(p, out) {
		assert(out.is_v3)
		return out.set(_v4_0.set(p).transform(e.inv_view))
	}

	// z_clip is 1..-1 (near..far planes)
	e.screen_to_view = function(x, y, z_clip, out) {
		assert(out.is_v4)
		return e.screen_to_clip(x, y, or(z_clip, 1), out).transform(e.inv_proj)
	}

	e.clip_to_world = function(p, out) {
		assert(out.is_v3)
		return out.set(e.clip_to_view(p, _v4_0).transform(e.inv_view))
	}

	e.screen_to_world = function(mx, my, out) {
		assert(out.is_v3)
		return out.set(e.screen_to_clip(mx, my, 1, _v4_0).transform(e.inv_proj).transform(e.inv_view))
	}

	// return a line of unit length from camera position pointing towards (mx, my).
	// the line can be directly intersected with a plane, and its delta() is
	// the ray's direction vector.
	e.raycast = function(mx, my, out) {
		let ray = e.screen_to_world(mx, my, _v0).normalize()
		assert(out.is_line3)
		out[0].set(e.pos)
		out[1].set(e.pos).add(ray)
		return out
	}

	{
	let _v2_0 = v2()
	let _v2_1 = v2()
	e.screen_distance2 = function(p1, p2) {
		let p = e.world_to_screen(p1, _v2_0)
		let q = e.world_to_screen(p2, _v2_1)
		return p.distance2(q)
	}}

	e.screen_distance = function(p1, p2) {
		return sqrt(e.distance2(p1, p2))
	}

	return e
}}

camera3 = camera // so you can do `let camera = camera3()`.

}()) // module scope.
