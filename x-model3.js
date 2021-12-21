/*

	Polygon-based editable 3D model components.
	Written by Cosmin Apreutesei. Public domain.

	Components are made primarily of polygons enclosed and connected by
	lines defined over a common point cloud. A component can contain instances
	of other components at relative transforms. A component can also contain
	standalone lines.

	The editing API implements the direct manipulation UI and performs
	automatic creation/removal/intersection of points/lines/polygons
	while keeping the model numerically stable and clean. In particular:
	- editing operations never leave duplicate points/lines/polygons.
	- existing points are never moved when adding new geometry.
	- when existing lines are cut, straightness is preserved to best accuracy.

*/

(function() {

model3_component = function(pe) {

	assert(pe)
	let e = {name: pe.name, editor: pe.editor}
	let gl = assert(pe.gl)
	let push_undo = pe.push_undo

	function log(s, ...args) {
		assert(LOG)
		print(e.id, s, ...args)
	}

	// model (as in MVC and as in 3D model) -----------------------------------

	let points    = [] // [(x, y, z), ...]
	let normals   = [] // [(x, y, z), ...]; normals for smooth meshes.
	let free_pis  = [] // [p1i,...]; freelist of point indices.
	let prc       = [] // [rc1,...]; ref counts of points.
	let lines     = [] // [(p1i, p2i, rc, sm, op), ...]; rc=refcount, sm=smoothness, op=opacity.
	let free_lis  = [] // [l1i,...]; freelist of line indices.
	let faces     = [] // [poly3[p1i, p2i, ..., lis: [line1i,...], selected:, material:, ],...]
	let free_fis  = [] // [face1_index,...]
	let meshes    = set() // {{face},...}; meshes are sets of all faces connected by smooth lines.

	let children  = [] // [mat1,...]

	// model-to-view info (as in MVC).
	let used_points_changed     // time to reload the used_pis buffer.
	let used_lines_changed      // time to reload the *_edge_lis buffers.
	let faces_changed           // time to rebuild faces geometry.
	let edge_line_count = 0     // number of face edge lines.
	let nonedge_line_count = 0  // number of standalone lines.
	let bbox_changed            // time to recompute the bbox.
	let sel_child_count = 0

	// low-level model editing API that:
	// - records undo ops in the undo stack.
	// - updates and/or invalidates any affected view buffers.

	let point_count = () => prc.length

	{
	let _v0 = v3()
	function get_point(pi, out) {
		out = out || _v0
		out[0] = points[3*pi+0]
		out[1] = points[3*pi+1]
		out[2] = points[3*pi+2]
		out.i = pi
		return out
	}}

	{
	let _v0 = v3()
	function add_point_xyz(x, y, z, expect_pi) {
		return add_point(_v0.set(x, y, z), expect_pi)
	}}

	function add_point(p, expect_pi) {
		assert(p.is_v3)
		let pi = free_pis.pop()
		if (pi == null) {
			points.push(p[0], p[1], p[2])
			normals.push(0, 0, 0)
			pi = prc.length
		} else {
			p.to_v3_array(points, pi)
		}
		prc[pi] = 0
		assert(expect_pi == null || pi == expect_pi)

		update_point(pi, p)

		if (LOG)
			log('add_point', pi, p.x+','+p.y+','+p.z)

		return pi
	}

	let unref_point = function(pi, expect_rc) {

		let rc0 = prc[pi]--
		assert(rc0 > 0)
		assert(expect_rc == null || expect_rc == rc0)

		if (rc0 == 1) {

			free_pis.push(pi)
			used_points_changed = true

			let p = get_point(pi)
			push_undo(add_point_xyz, p[0], p[1], p[2], pi)

		}

		push_undo(ref_point, pi, rc0 - 1)

		// if (LOG) log('unref_point', pi, prc[pi])
	}

	let ref_point = function(pi, expect_rc) {

		let rc0 = prc[pi]++
		assert(expect_rc == null || expect_rc == rc0)

		if (rc0 == 0)
			used_points_changed = true

		push_undo(unref_point, pi, rc0 + 1)

		// if (LOG) log('ref_point', pi, prc[pi])
	}

	{
	let _v0 = v3()
	function move_point_xyz(pi, x, y, z, x0, y0, z0) {
		return move_point(pi, _v0.set(x, y, z), x0, y0, z0)
	}}

	function move_point(pi, p, expect_x, expect_y, expect_z) {
		let p0 = get_point(pi)
		let x0 = p0[0]
		let y0 = p0[1]
		let z0 = p0[2]
		if (expect_x != null) {
			assert(expect_x == x0)
			assert(expect_y == y0)
			assert(expect_z == z0)
		}
		p.to_v3_array(points, pi)
		update_point(pi, p)
		push_undo(move_point_xyz, pi, x0, y0, z0, p[0], p[1], p[2])
	}

	let line_count = () => lines.length / 5

	{
	let _line = line3()
	function get_line(li, out) {
		out = out || _line
		let p1i = lines[5*li+0]
		let p2i = lines[5*li+1]
		get_point(p1i, out[0])
		get_point(p2i, out[1])
		out.i = li
		return out
	}}

	function line_rc         (li) { return lines[5*li+2] }
	function line_smoothness (li) { return lines[5*li+3] }
	function line_opacity    (li) { return lines[5*li+4] }

	function each_line(f) {
		for (let li = 0, n = line_count(); li < n; li++)
			if (line_rc(li))
				f(get_line(li))
	}

	function add_line(p1i, p2i, expect_li) {

		let li = free_lis.pop()
		if (li == null) {
			li = lines.push(p1i, p2i, 1, 0, 1)
			li = (lines.length / 5) - 1
		} else {
			lines[5*li+0] = p1i
			lines[5*li+1] = p2i
			lines[5*li+2] = 1 // ref. count
			lines[5*li+3] = 0 // smoothness
			lines[5*li+4] = 1 // opacity
		}
		assert(expect_li == null || expect_li == li)

		nonedge_line_count++
		used_lines_changed = true
		bbox_changed = true

		ref_point(p1i)
		ref_point(p2i)

		push_undo(unref_line, li, 1)

		if (LOG)
			log('add_line', li, p1i+','+p2i)

		return li
	}

	function unref_line(li, expect_rc) {

		let rc = --lines[5*li+2]
		assert(rc >= 0)
		assert(expect_rc == null || expect_rc == rc + 1)

		if (rc == 0) {

			nonedge_line_count--
			used_lines_changed = true
			bbox_changed = true

			let p1i = lines[5*li+0]
			let p2i = lines[5*li+1]

			unref_point(p1i)
			unref_point(p2i)

			free_lis.push(li)

			push_undo(add_line, p1i, p2i, li)

			if (LOG)
				log('remove_line', li)

		} else {

			if (rc == 1) {
				nonedge_line_count++
				edge_line_count--
				used_lines_changed = true
			} else {
				edge_line_count--
			}

			push_undo(ref_line, li, rc)

		}

		// if (LOG)
			// log('unref_line', li, rc)
	}

	function ref_line(li, expect_rc) {

		let rc0 = lines[5*li+2]++
		assert(expect_rc == null || expect_rc == rc0)

		if (rc0 == 1) {
			nonedge_line_count--
			edge_line_count++
			used_lines_changed = true
		} else {
			assert(rc0 > 1)
			edge_line_count++
		}

		push_undo(unref_line, li, rc0 + 1)

		// if (LOG)
			// log('ref_line', li, rc0 + 1)
	}

	function merge_lines(li1, li2, expect_rc) {

		let pi1 = lines[5*li2+0] // pi1
		let pi2 = lines[5*li2+1] // pi2

		if (LOG)
			log('merge_lines', li1, li2)

		assert(expect_rc == null || line_rc(li2) == expect_rc)

		while (line_rc(li2))
			unref_line(li2)

		lines[5*li1+1] = pi2 // pi2

		used_lines_changed = true

		push_undo(cut_line, li1, pi1, li2)
	}

	function cut_line(li1, pi, expect_li) {
		let pi2 = lines[5*li1+1] // pi2
		let rc1 = lines[5*li1+2] // rc
		let sm1 = lines[5*li1+3] // smoothness
		let op1 = lines[5*li1+4] // opacity

		if (LOG)
			log('cut_line', li1, pi)

		let li2 = add_line(pi, pi2)
		lines[5*li1+1] = pi // pi2
		while (line_rc(li2) < rc1)
			ref_line(li2)
		set_line_smoothness (li2, sm1)
		set_line_opacity    (li2, op1)

		used_lines_changed = true

		assert(expect_li == null || li2 == expect_li)

		push_undo(merge_lines, li1, li2, rc1)
	}

	function replace_line_endpoint(li, new_pi, old_pi) {

		let pi0 = lines[5*li+0]
		let pi1 = lines[5*li+1]

		let i = (old_pi == pi0) ? 0 : ((old_pi == pi1) ? 1 : assert(false))

		lines[5*li+i] = new_pi

		used_lines_changed = true

		ref_point(new_pi)
		unref_point(old_pi)

		if (LOG)
			log('replace_line_endpoint', li, '@'+i, old_pi, '->', new_pi)

		push_undo(replace_line_endpoint, old_pi, new_pi)
	}

	let face = {is_face3: true}

	face.get_point = function(ei, out) {
		return get_point(this[ei], out)
	}

	face.get_normal = function(ei, out) {
		if (this.mesh)
			return out.from_v3_array(normals, this[ei])
		else
			return this.plane().normal
	}

	face.get_edge = function(ei, out) {
		out = get_line(this.lis[ei], out)
		out.ei = ei // edge index.
		if (out[1].i == this[ei]) { // fix edge endpoints order.
			let p1 = out[0]
			let p2 = out[1]
			out[0] = p2
			out[1] = p1
		}
		return out
	}

	face.each_edge = function(f) {
		for (let ei = 0, n = this.length; ei < n; ei++)
			f(this.get_edge(ei))
	}

	face.is_flat = function() {
		for (let li of face.lis)
			if (lines[5*li+3])
				return false
		return true
	}

	let face3 = poly3.subclass(face)

	let mat_faces_map = map() // {material -> [face1,...]}

	function material_instance(mat) {
		mat = mat || pe.default_material
		let mat_insts = attr(mat_faces_map, mat, Array)
		mat_insts.material = mat
		return mat_insts
	}

	function add_face(pis, lis, material) {
		let face
		let fi = free_fis.pop()
		if (fi == null) {
			fi = faces.length
			face = face3()
			face.lis = []
			face.points = points
			face.i = fi
			faces[fi] = face
		} else {
			face = faces[fi]
		}
		if (pis) {
			face.extend(pis)
			for (let pi of pis)
				ref_point(pi)
		}
		if (lis) {
			face.lis.extend(lis)
			for (let li of lis)
				ref_line(li)
		} else
			update_face_lis(face)
		material = material || pe.default_material
		face.mat_inst = material_instance(material)
		face.mat_inst.push(face)
		faces_changed = true
		if (LOG)
			log('add_face', face.i, face.join(','), face.lis.join(','), material.i)
		return face
	}

	function remove_face(face) {
		free_fis.push(face.i)
		for (let li of face.lis)
			unref_line(li)
		for (let pi of face)
			unref_point(pi)
		face.length = 0
		face.lis.length = 0
		face.mat_inst.remove_value(face)
		face.mat_inst = null
		if (LOG)
			log('remove_face', face.i)
	}

	function set_material(face, material) {
		let m_inst0 = face.mat_inst
		let m0 = m_inst0.material
		let m_inst = material_instance(material)
		if (m_inst == m_inst0)
			return

		m_inst0.remove_value(face)
		face.mat_inst = m_inst
		face.mat_inst.push(face)
		faces_changed = true

		if (LOG)
			log('set_material', face.i, material.i)

		push_undo(set_material, face, m0)
	}

	function ref_or_add_line(p1i, p2i) {
		let found_li
		for (let li = 0, n = line_count(); li < n; li++) {
			let _p1i = lines[5*li+0]
			let _p2i = lines[5*li+1]
			if ((_p1i == p1i && _p2i == p2i) || (_p1i == p2i && _p2i == p1i)) {
				found_li = li
				break
			}
		}
		if (found_li == null)
			found_li = add_line(p1i, p2i)
		ref_line(found_li)
		return found_li
	}

	function update_face_lis(face) {
		let lis = face.lis
		lis.length = 0
		let p1i = face[0]
		for (let i = 1, n = face.length; i < n; i++) {
			let p2i = face[i]
			lis.push(assert(ref_or_add_line(p1i, p2i)))
			p1i = p2i
		}
		lis.push(assert(ref_or_add_line(p1i, face[0])))
		faces_changed = true
	}

	function insert_edge(face, ei, pi, line_before_point, li) {
		let line_ei = ei - (line_before_point ? 1 : 0)
		assert(line_ei >= 0) // can't use ei=0 and line_before_point=true with this function.
		if (LOG)
			log('insert_edge', face.i, '@'+ei, 'pi='+pi, '@'+line_ei, 'li='+li, 'before_pi='+face[ei])
		face.insert(ei, pi)
		face.lis.insert(line_ei, li)
		if (face.mesh)
			face.mesh.normals_valid = false
		face.invalidate()
		faces_changed = true
	}

	function replace_edge(face, ei, li, expect_li) {
		let li0 = face.lis[ei]
		assert(expect_li == null || expect_li == li0)
		face.lis[ei] = li

		if (LOG)
			log('replace_edge', face.i, '@'+ei, li0, '->', li)

		push_undo(replace_edge, face, ei, li0, li)
	}

	function replace_face_point(face, ei, pi) {
		let pi0 = face[ei]
		face[ei] = pi

		if (LOG)
			log('replace_face_point', face.i, '@'+ei, pi0, '->', pi)

		push_undo(replace_face_point, face, ei, pi0)
	}

	function each_line_face(li, f) {
		for (let face of faces)
			if (face.lis.includes(li))
				f(face)
	}

	{
	let common_meshes = set()
	let nomesh_faces = []
	function set_line_smoothness(li, sm) {

		let sm0 = lines[5*li+3]
		if (sm == sm0)
			return

		push_undo(set_line_smoothness, li, sm0)

		if (!sm0 == !sm) // smoothness category hasn't changed.
			return

		lines[5*li+3] = sm

		if (sm > 0) { // line has gotten smooth.

			each_line_face(li, function(face) {
				if (face.mesh)
					common_meshes.add(face.mesh)
				else
					nomesh_faces.push(face)
			})

			let target_mesh

			if (common_meshes.size == 0) {
				// none of the faces are part of a mesh, so make one.
				let mesh = set()
				meshes.add(mesh)
				common_meshes.add(mesh)
				target_mesh = mesh
			} else {
				// merge all meshes into the first one and remove the rest.
				for (let mesh of common_meshes) {
					if (!target_mesh) {
						target_mesh = mesh
					} else {
						for (let face of mesh) {
							target_mesh.add(face)
							face.mesh = target_mesh
						}
						meshes.delete(mesh)
					}
				}
			}

			// add flat faces to the target mesh.
			for (let face of nomesh_faces) {
				target_mesh.add(face)
				face.mesh = target_mesh
			}

			target_mesh.normals_valid = false

		} else { // line has gotten non-smooth.

			// remove faces containing `li` from their smooth mesh.
			let target_mesh
			each_line_face(li, function(face) {
				assert(!target_mesh || target_mesh == mesh) // one mesh only.
				target_mesh = face.mesh
				if (face.is_flat())
					face.mesh.delete(face)
				face.mesh = null
			})

			// remove the mesh if it became empty.
			if (target_mesh.size == 0)
				meshes.delete(target_mesh)

		}

		common_meshes.clear()
		nomesh_faces.length = 0

		faces_changed = true
	}}

	function set_line_opacity(li, op) {

		let op0 = lines[5*li+4]
		if (op == op0)
			return

		push_undo(set_line_opacity, li, op0)

		if (!op0 == !op) // opacity category hasn't changed.
			return

		lines[5*li+4] = op

		used_lines_changed = true
	}

	// component children

	function add_child(comp, mat, layer) {
		assert(mat.is_mat4)
		assert(comp.editor == pe.editor)
		mat.comp = comp
		mat.layer = layer || pe.default_layer
		children.push(mat)
		pe.child_added(e, mat)
		if (LOG)
			log('add_child', mat)
		return mat
	}

	function remove_child(mat) {
		assert(children.remove_value(mat))
		pe.child_removed(e, mat)
	}

	function set_child_layer(node, layer) {
		assert(node.comp == this)
		node.layer = layer
		pe.layer_changed(e, node)
		return node
	}

	function set_child_matrix(nat, mat1) {
		assert(mat.comp == this)
		return mat.set(mat1)
	}

	// public API

	e.point_count = point_count
	e.get_point   = get_point

	e.line_count      = line_count
	e.get_line        = get_line
	e.each_line       = each_line
	e.add_line        = add_line
	e.unref_line      = unref_line
	e.set_line_smoothness = set_line_smoothness
	e.set_line_opacity = set_line_opacity

	e.faces       = faces
	e.add_face    = add_face
	e.remove_face = remove_face

	e.set_material = set_material

	e.each_line_face = each_line_face

	e.children        = children
	e.add_child       = add_child
	e.remove_child    = remove_child
	e.set_child_layer = set_child_layer

	e.set = function(t) {

		if (t.points) {
			let p = v3()
			for (let i = 0, n = t.points.length; i < n; i += 3)
				add_point(p.from_array(t.points, i))
		}

		if (t.faces)
			for (let ft of t.faces)
				add_face(ft, ft.lis, ft.material)

		if (t.lines)
			for (let i = 0, n = t.lines.length; i < n; i += 2)
				add_line(t.lines[i], t.lines[i+1])

	}

	// hit testing & snapping -------------------------------------------------

	// return the line from target line to its closest point
	// with the point index in line[1].i.
	function line_hit_points(target_line, max_d, p2p_distance2, f) {
		let min_ds = 1/0
		let int_line = line3()
		let min_int_line
		let p1 = int_line[0]
		let p2 = int_line[1]
		let i1 = target_line[0].i
		let i2 = target_line[1].i
		for (let i = 0, n = point_count(); i < n; i++) {
			if (i == i1 || i == i2) // don't hit target line's endpoints
				continue
			get_point(i, p2)
			target_line.closest_point_to_point(p2, true, p1)
			let ds = p2p_distance2(p1, p2)
			if (ds <= max_d ** 2) {
				if (f && f(int_line) === false)
					continue
				if (ds < min_ds) {
					min_ds = ds
					min_int_line = min_int_line || line3()
					min_int_line[0].set(p1)
					min_int_line[1].set(p2)
					min_int_line[1].i = i
				}
			}
		}
		return min_int_line
	}

	// return the point on closest line from target point.
	function point_hit_lines(p, max_d, p2p_distance2, f, each_line_f) {
		let min_ds = 1/0
		let line = line3()
		let int_p = v3()
		let min_int_p
		each_line_f = each_line_f || each_line
		each_line_f(function(line) {
			line.closest_point_to_point(p, true, int_p)
			let ds = p2p_distance2(p, int_p)
			if (ds <= max_d ** 2) {
				if (!(f && f(int_p, line) === false)) {
					if (ds < min_ds) {
						min_ds = ds
						min_int_p = assign(min_int_p || v3(), int_p)
					}
				}
			}
		})
		return min_int_p
	}

	// return the point on closest face line from target point.
	function point_hit_edge(p, face, max_d, p2p_distance2, f) {
		return point_hit_lines(p, max_d, p2p_distance2, f, f => each_edge(face, f))
	}

	// return the projected point on closest line from target line.
	{
	let _l0 = line3()
	let _l1 = line3()
	let _l2 = line3()
	let _v0 = v3()
	function line_hit_lines(model, target_line, max_d, p2p_distance2, int_mode, is_line_valid, is_int_line_valid) {
		let min_ds = 1/0
		let min_int_p
		is_line_valid = is_line_valid || return_true
		is_int_line_valid = is_int_line_valid || return_true
		for (let li = 0, n = line_count(); li < n; li++) {
			if (lines[5*li+2]) { // ref count: used.
				let line = get_line(li)
				if (model)
					line.transform(model)
				if (is_line_valid(line)) {
					let p1i = line[0].i
					let p2i = line[1].i
					let q1i = target_line[0].i
					let q2i = target_line[1].i
					let touch1 = p1i == q1i || p1i == q2i
					let touch2 = p2i == q1i || p2i == q2i
					if (touch1 != touch2) {
						// skip lines with a single endpoint common with the target line.
					} else if (touch1 && touch2) {
						//
					} else {
						let int_line = target_line.intersect_line(line, _l0, int_mode)
						if (int_line) {
							let ds = p2p_distance2(int_line[0], int_line[1])
							if (ds <= max_d ** 2) {
								let int_p = int_line[1]
								int_p.line = line
								int_p.int_line = int_line
								int_p.li = li
								if (is_int_line_valid(int_p)) {
									if (ds < min_ds) {
										min_ds = ds
										min_int_p = min_int_p || _v0
										min_int_p.assign(int_p)
										min_int_p.line = _l1.assign(line)
										min_int_p.int_line = _l2.assign(int_line)
									}
								}
							}
						}
					}
				}
			}
		}
		return min_int_p
	}}

	e.point_hit_lines = point_hit_lines
	e.point_hit_edge = point_hit_edge
	e.line_hit_lines = line_hit_lines

	// selection --------------------------------------------------------------

	{
	let _bb0 = box3()
	let _bb1 = box3()
	e.bbox = function() {
		let bb = _bb0
		if (bbox_changed) {
			bb.reset()
			each_line(line => bb.add(line))
			for (let child of children) {
				let cbb = child.comp.bbox().to(_bb1).transform(child)
				bb.add(cbb)
			}
			bbox_changed = false
		}
		return bb
	}}

	let sel_lines = set() // {l1i,...}
	let sel_lines_changed

	{
	let _line = line3()
	e.each_selected_line = function(f) {
		for (let li of sel_lines) {
			get_line(li, _line)
			f(_line)
		}
	}}

	function select_all_lines(sel) {
		if (sel)
			for (let i = 0, n = e.line_count(); i < n; i++)
				sel_lines.add(i)
		else
			sel_lines.clear()
		sel_lines_changed = true
	}

	let sel_face_count = 0

	function face_set_selected(face, sel) {
		if (!face.selected == !sel)
			return
		face.selected = sel
		sel_face_count += (sel ? 1 : -1)
		faces_changed = true
	}

	function select_all_faces(sel) {
		for (let face of faces)
			face_set_selected(face, sel)
	}

	function select_edges(face, mode) {
		face.each_edge(function(line) {
			e.select_line(line.i, mode)
		})
	}

	function select_line_faces(li, mode) {
		e.each_line_face(li, function(face) {
			e.select_face(face, mode)
		})
	}

	e.select_face = function(face, mode, with_lines) {
		if (mode == 'add' || mode == 'remove') {
			face_set_selected(face, mode == 'add')
			if (mode == 'add' && with_lines) {
				select_edges(face, mode)
				sel_lines_changed = true
			}
		} else if (mode == 'toggle') {
			e.select_face(face, face.selected ? 'remove' : 'add', with_lines)
		} else
			assert(false)
	}

	e.select_line = function(li, mode, with_faces) {
		if (mode == 'add') {
			sel_lines.add(li)
			if (with_faces)
				select_line_faces(li, 'add')
		} else if (mode == 'remove') {
			sel_lines.delete(li)
		} else if (mode == 'toggle') {
			e.select_line(li, sel_lines.has(li) ? 'remove' : 'add', with_faces)
		} else
			assert(false)
		sel_lines_changed = true
	}

	e.is_line_selected = function(li) {
		return sel_lines.has(li)
	}

	e.selected_child = null

	e.select_child = function(child, mode) {
		let sel = mode == 'toggle' ? !child.selected : mode == 'add'
		if (sel == !!child.selected)
			return
		child.selected = sel
		sel_child_count += (sel ? 1 : -1)
		e.selected_child = sel_child_count == 1 ? child : null
		sel_lines_changed = true
	}

	function select_all_children(sel) {
		for (let child of children)
			e.select_child(child, sel ? 'add' : 'remove')
	}

	e.select_all = function(sel, with_children) {
		if (sel == null) sel = true
		select_all_faces(sel)
		select_all_lines(sel)
		if (with_children !== false)
			select_all_children(sel)
	}

	e.remove_selection = function() {

		// remove all faces that selected lines are sides of.
		for (let li of sel_lines)
			e.each_line_face(li, remove_face)

		// remove all selected faces.
		for (let face of faces)
			if (face.selected)
				remove_face(face)

		// remove all selected lines.
		remove_lines(sel_lines)

		// TODO: merge faces.

		select_all_lines(false)
		update_face_lis()
	}

	e.selected_face_count = () => sel_face_count
	e.selected_line_count = () => sel_lines.size
	e.selected_child_count = () => sel_child_count

	// model editing ----------------------------------------------------------

	let real_p2p_distance2 = (p1, p2) => p1.distance2(p2)

	e.draw_line = function(line) {

		let p1 = line[0]
		let p2 = line[1]

		// check for min. line length for lines with new endpoints.
		if (p1.i == null || p2.i == null) {
			if (p1.distance2(p2) <= NEAR ** 2)
				return
		} else if (p1.i == p2.i) {
			// check if end point was snapped to start end point.
			return
		}

		let line_ps = [p1, p2] // line's points as an open polygon.

		// cut the line into segments at intersections with existing points.
		line_hit_points(line, NEAR, real_p2p_distance2, null, null, function(int_line) {
			let p = int_line[0]
			let i = p.i
			if (i !== p1.i && i !== p2.i) { // exclude end points.
				p = p.clone()
				p.i = i
				line_ps.push(p)
			}
		})

		// sort intersection points by their distance relative to p1
		// so that adjacent points form line segments.
		function sort_line_ps() {
			if (line_ps.length)
				line_ps.sort(function(sp1, sp2) {
					let ds1 = p1.distance2(sp1)
					let ds2 = p1.distance2(sp2)
					return ds1 - ds2
				})
		}

		sort_line_ps()

		// check if any of the line segments intersect any existing lines.
		// the ones that do must be broken down further, and so must the
		// existing lines that are cut by them.
		let line_ps_len = line_ps.length

		let seg = line3()
		for (let i = 0; i < line_ps_len-1; i++) {
			seg[0] = line_ps[i+0]
			seg[1] = line_ps[i+1]
			line_hit_lines(null, seg, NEAR, real_p2p_distance2, 'clamp', null,
				function(int_p) {
					let p = int_p.clone()
					p.cut_li = int_p.line.i
					line_ps.push(p)
					return true
				})
		}

		// sort the points again if new points were added.
		if (line_ps.length > line_ps_len)
			sort_line_ps()

		// create missing points.
		for (let p of line_ps)
			if (p.i == null) {
				p.i = add_point(p)
			}

		// create line segments.
		for (let i = 0, n = line_ps.length; i < n-1; i++) {
			let p1i = line_ps[i+0].i
			let p2i = line_ps[i+1].i
			add_line(p1i, p2i)
		}

		// cut intersecting lines in two.
		for (let p of line_ps) {
			if (p.cut_li != null)
				cut_line(p.cut_li, p.i)
		}

	}

	// push/pull --------------------------------------------------------------

	e.start_pull = function(p) {

		let pull = {}

		// pulled face.
		pull.face = p.face

		// pull direction line, starting on the plane and with unit length.
		pull.line = line3(p.to(v3()), p.to(v3()).add(pull.face.plane().normal))
		pull.origin = pull.line[0]

		// faces and lines to exclude when hit-testing while pulling.
		// all moving geometry must be added here.
		let moving_faces = set() // {face->true}
		let moving_lis = set() // {li->true}

		moving_faces.add(pull.face)

		let min_distance = -1/0
		let max_distance =  1/0

		// pulling only works if the pulled face is connected exclusively to
		// perpendicular (pp) side faces with pp edges at the connection points.
		// when that's not the case, we extend the geometry around the pulled
		// face by either creating new pp faces with pp edges or extending
		// existing pp faces with pp edges. after that, pulling on the face
		// becomes just a matter of moving its points in the pull direction.

		// the setup takes two steps: 1) record what needs to be done with
		// the side geometry at each point of the pulled face, 2) perform the
		// modifications, avoiding making duplicate pp edges.
		{
			let new_pp_edge = map() // {pull_ei->true}
			let new_pp_face = map() // {pull_ei->true}
			let ins_edge = map() // {pp_face->[[pp_ei, line_before_point, pull_ei],...]}
			let pp_lis = set() // {pi}

			let pull_edge = line3()
			let side_edge = line3()
			let normal = v3()
			let _v0 = v3()

			let en = pull.face.length

			// for each edge of the pulled face, find all faces that also
			// contain that edge and are pp to the pulled face. there should be
			// at most two such faces per edge, one on each side of the pulled face.
			// also check for any other non-pp faces connected to the pulled face's points.
			for (let pull_ei = 0; pull_ei < en; pull_ei++) {

				let pp_faces_found = 0
				pull.face.get_edge(pull_ei, pull_edge)

				for (let face of faces) {

					if (face != pull.face) { // not the pulled face.

						if (abs(face.plane().normal.dot(pull.face.plane().normal)) < NEAR) { // face is pp.

							let pull_li = pull.face.lis[pull_ei]
							let face_ei = face.lis.indexOf(pull_li)
							if (face_ei != -1) { // face contains our pulled edge, so it's a pp side face.

								pp_faces_found++

								pull_edge.delta(normal).normalize()

								// iterate exactly twice: for prev pp edge and for next pp edge,
								// each of which connects to one of the endpoints of our pulled edge,
								// and we don't know which one, we need to find out.
								for (let i = 0; i <= 1; i++) {

									let side_ei = mod(face_ei - 1 + i * 2, face.length)
									face.get_edge(side_ei, side_edge)

									let is_side_edge_pp = abs(side_edge.delta(_v0).dot(normal)) < NEAR

									// figure out which endpoint of the pulled edge this side edge connects to.
									let is_first  = side_edge[0].i == pull_edge[0].i || side_edge[1].i == pull_edge[0].i
									let is_second = side_edge[0].i == pull_edge[1].i || side_edge[1].i == pull_edge[1].i
									assert(is_first || is_second)
									let endpoint_ei = (pull_ei + ((is_first) ? 0 : 1)) % en

									if (is_side_edge_pp) {
										moving_lis.add(side_edge.i)
										pp_lis.add(side_edge.i)
									} else {
										new_pp_edge.set(endpoint_ei, true)
									}

									moving_faces.add(face)

									// add a command to extend this face with a pp edge if it turns out
									// that the point at `endpoint_ei` will have a pp edge.
									// NOTE: can't call insert_edge() with ei=0. luckily, we don't have to.
									attr(ins_edge, face, Array).push([face_ei + 1, i == 0, endpoint_ei])

								}

							}

						} else { // face is not pp, check if it connects to the pulled face at all.

							// check if this face connects to pulled face's point at `ei`
							// and mark the point as needing a pp edge if it does.
							let face_ei = face.indexOf(pull.face[pull_ei])
							if (face_ei != -1) {
								new_pp_edge.set(pull_ei, true)
							}

						}

					}

				}

				if (!pp_faces_found) { // no pp faces found: create one along with its two edges.
					new_pp_face.set(pull_ei, true)
					new_pp_edge.set(pull_ei, true)
					new_pp_edge.set((pull_ei+1) % en, true)
				}

			}

			if (LOG) {
				log('pull.start', pull.face.i,
					'edges:'+[...new_pp_edge.keys()].join(','),
					'faces:'+[...new_pp_face.keys()].join(','),
					'insert:'+json(ins_edge).replaceAll('"', '')
				)
			}


			// create pp side edges and adjust pulled face points & edge endpoints.
			let old_points = {} // {ei: pi}
			for (let ei of new_pp_edge.keys()) {
				let old_pi = pull.face[ei]

				// create pp side edge at `ei`.
				let p = get_point(old_pi, _v0)
				let new_pi = add_point(p)
				let li = add_line(old_pi, new_pi)
				new_pp_edge.set(ei, li)
				moving_lis.add(li)
				pp_lis.add(li)

				// replace point in pulled face.
				old_points[ei] = old_pi
				replace_face_point(pull.face, ei, new_pi)
				pull.face.invalidate()

				// update the endpoint of pulled face edges that are connected to this point.
				let next_ei = ei
				let prev_ei = mod(ei - 1, en)
				let next_li = pull.face.lis[next_ei]
				let prev_li = pull.face.lis[prev_ei]
				if (!new_pp_face.get(next_ei)) replace_line_endpoint(next_li, new_pi, old_pi)
				if (!new_pp_face.get(prev_ei)) replace_line_endpoint(prev_li, new_pi, old_pi)
			}

			// create pp side faces using newly created pp side edges.
			for (let e1i of new_pp_face.keys()) {
				let e2i = (e1i + 1) % en
				let p1i = pull.face[e1i]
				let p2i = pull.face[e2i]
				let side1_li = new_pp_edge.get(e1i)
				let side2_li = new_pp_edge.get(e2i)
				let old_pull_li = pull.face.lis[e1i]
				let old_p1i = old_points[e1i]
				let old_p2i = old_points[e2i]

				// create pp side face.
				let pull_li = add_line(p1i, p2i)
				let face = add_face(
					[old_p1i, old_p2i, p2i, p1i],
					[old_pull_li, side2_li, pull_li, side1_li]
				)
				moving_faces.add(face)

				// replace edge in pulled face.
				replace_edge(pull.face, e1i, pull_li, old_pull_li)
			}

			// extend pp side faces with newly created pp side edges.
			for (let [pp_face, t] of ins_edge) {
				let insert_offset = 0
				for (let [pp_ei, line_before_point, pull_ei] of t) {
					let pull_pi = pull.face[pull_ei]
					let pp_li = new_pp_edge.get(pull_ei)
					if (pp_li != null) {
						insert_edge(pp_face, pp_ei + insert_offset, pull_pi, line_before_point, pp_li)
						insert_offset++
					}
				}
			}

			// mark final pulled face's edges as non-hittable.
			for (let li of pull.face.lis)
				moving_lis.add(li)

			// TODO: set min-max distance limits.
			for (let li of pp_lis) {
				let line = get_line(li)
			}

		}

		pull.can_hit = function(p) {
			if (!p.comp)
				return false
			if (p.comp != e)
				return true
			return (!(moving_faces.has(p.face) || moving_lis.has(p.li)))
		}

		{
		let initial_ps = pull.face.map(pi => get_point(pi, v3()))
		let _v0 = v3()
		let _v1 = v3()
		pull.pull = function(distance) {

			distance = clamp(distance, min_distance, max_distance)
			let delta = pull.line.delta(_v0).set_len(distance)

			let i = 0
			for (let pi of pull.face) {
				let p = initial_ps[i++].to(_v1).add(delta)
				move_point(pi, p)
			}

			for (let face of moving_faces)
				face.invalidate()

		}}

		pull.stop = function() {
			// TODO: make hole, etc.
			if (LOG)
				log('pull.stop')
		}

		return pull
	}

	// rendering --------------------------------------------------------------

	let points_dab           = gl && gl.dyn_arr_v3_buffer() // coords for points and lines
	let used_pis_dab         = gl && gl.dyn_arr_u32_index_buffer() // points index buffer
	let vis_edge_lis_dab     = gl && gl.dyn_arr_u32_index_buffer() // black thin lines
	let inv_edge_lis_dab     = gl && gl.dyn_arr_u32_index_buffer() // black dashed lines
	let sel_inv_edge_lis_dab = gl && gl.dyn_arr_u32_index_buffer() // blue dashed lines

	let points_rr             = gl.points_renderer()
	let faces_rr              = gl.faces_renderer()
	let black_thin_lines_rr   = gl.solid_lines_renderer()
	let black_dashed_lines_rr = gl.dashed_lines_renderer({dash: 5, gap: 3})
	let blue_dashed_lines_rr  = gl.dashed_lines_renderer({dash: 5, gap: 3, base_color: 0x0000ff})
	let black_fat_lines_rr    = gl.fat_lines_renderer({})
	let blue_fat_lines_rr     = gl.fat_lines_renderer({base_color: 0x0000ff})

	function free() {
		points_dab            .free()
		used_pis_dab          .free()
		vis_edge_lis_dab      .free()
		inv_edge_lis_dab      .free()
		sel_inv_edge_lis_dab  .free()

		points_rr             .free()
		faces_rr              .free()
		black_thin_lines_rr   .free()
		black_dashed_lines_rr .free()
		blue_dashed_lines_rr  .free()
		black_fat_lines_rr    .free()
		blue_fat_lines_rr     .free()

		camera_ubo            .free()
	}

	function update_point(pi, p) {
		points_dab.set(pi, p)
		bbox_changed = true
	}

	e.show_invisible_lines = true

	e.toggle_invisible_lines = function() {
		e.show_invisible_lines = !e.show_invisible_lines
		used_lines_changed = true
	}

	function each_nonedge_line(f) {
		for (let li = 0, n = line_count(); li < n; li++)
			if (lines[5*li+2] == 1) // rc: is standalone.
				f(get_line(li))
	}

	function each_sel_vis_line(f) {
		for (let li of sel_lines)
			if (lines[5*li+4] > 0) // opacity: is visible.
				f(get_line(li))
	}

	{
	let _m0 = mat4()
	let _v0 = v3()
	function each_bbox_line(node, f) {
		let bbox = node.comp.bbox()
		let m = _m0.reset()
			.mul(node)
			.translate(bbox[0])
			.scale(bbox.delta(_v0))
			.translate(.5, .5, .5)
		box3.each_line(function(line) {
			f(line.transform(m))
		})
	}}

	function each_blue_fat_line(f) {
		each_sel_vis_line(f)
		for (let node of children)
			if (node.selected)
				each_bbox_line(node, f)
	}

	function blue_fat_line_count() {
		return sel_lines.size + sel_child_count * 12
	}

	function update(models_buf, disabled_buf) {

		let points_changed = points_dab.invalid

		if (points_changed) {
			points_dab.upload_invalid()
			points_rr             .pos = points_dab.buffer
			black_thin_lines_rr   .pos = points_dab.buffer
			black_dashed_lines_rr .pos = points_dab.buffer
			blue_dashed_lines_rr  .pos = points_dab.buffer
		}

		if (used_points_changed) {

			let pn = point_count()
			used_pis_dab.grow(pn, false)

			let i = 0
			let is = used_pis_dab.array
			for (let pi = 0; pi < pn; pi++)
				if (prc[pi]) // is used
					is[i++] = pi

			used_pis_dab.setlen(i).upload()

			points_rr.index = used_pis_dab.buffer

		}

		if (used_lines_changed) {

			let vln = edge_line_count
			let iln = e.show_invisible_lines ? vln : 0

			let vdab  = vis_edge_lis_dab
			let idab  = inv_edge_lis_dab

			vdab.grow(2 * vln, false)
			idab.grow(2 * iln, false)

			let vi = 0
			let ii = 0
			let vs = vdab.array
			let is = idab.array
			for (let i = 0, n = lines.length; i < n; i += 5) {
				if (lines[i+2] >= 2) { // refcount: is edge
					let p1i = lines[i+0]
					let p2i = lines[i+1]
					if (lines[i+4] > 0) { // opacity: is not invisible
						vs[vi++] = p1i
						vs[vi++] = p2i
					} else if (is) {
						is[ii++] = p1i
						is[ii++] = p2i
					}
				}
			}

			vdab.setlen(vi).upload()
			idab.setlen(ii).upload()

			black_thin_lines_rr   .index = vdab.buffer
			black_dashed_lines_rr .index = idab.buffer
		}

		if (e.show_invisible_lines && (used_lines_changed || sel_lines_changed)) {

			let max_ln = e.show_invisible_lines ? sel_lines.size : 0
			let dab = sel_inv_edge_lis_dab
			dab.grow(max_ln * 2, false)
			let i = 0
			let is = dab.array
			if (is) {
				for (let li of sel_lines) {
					if (lines[5*li+4] == 0) { // opacity: is invisible.
						let p1i = lines[5*li+0]
						let p2i = lines[5*li+1]
						is[i++] = p1i
						is[i++] = p2i
					}
				}
			}
			dab.setlen(i).upload()

			blue_dashed_lines_rr.index = dab.buffer
		}


		if (points_changed || faces_changed) {

			for (let mesh of meshes)
				if (!mesh.normals_valid)
					for (let face of mesh)
						for (let i = 0, teis = face.triangles(), n = teis.length; i < n; i++) {
							let pi = face[teis[i]]
							normals[3*pi+0] = 0
							normals[3*pi+1] = 0
							normals[3*pi+2] = 0
						}

				for (let mesh of meshes)
					if (!mesh.normals_valid)
						for (let face of mesh)
							face.compute_smooth_normals(normals)

			faces_rr.update(e.id, mat_faces_map)
		}

		if (points_changed || used_lines_changed)
			black_fat_lines_rr.update(each_nonedge_line, nonedge_line_count)

		if (points_changed || sel_lines_changed)
			blue_fat_lines_rr.update(each_blue_fat_line, blue_fat_line_count())

		points_rr             .model = models_buf
		faces_rr              .model = models_buf
		black_thin_lines_rr   .model = models_buf
		black_dashed_lines_rr .model = models_buf
		blue_dashed_lines_rr  .model = models_buf
		black_fat_lines_rr    .model = models_buf
		blue_fat_lines_rr     .model = models_buf

		points_rr             .disabled = disabled_buf
		faces_rr              .disabled = disabled_buf
		black_thin_lines_rr   .disabled = disabled_buf
		black_dashed_lines_rr .disabled = disabled_buf
		blue_dashed_lines_rr  .disabled = disabled_buf
		black_fat_lines_rr    .disabled = disabled_buf
		blue_fat_lines_rr     .disabled = disabled_buf

		let mouse_invalid = points_changed || faces_changed

		points_changed      = false
		used_points_changed = false
		used_lines_changed  = false
		faces_changed       = false
		sel_lines_changed   = false

		return mouse_invalid
	}

	e.renderers = [
		faces_rr,
		points_rr,
		black_thin_lines_rr,
		black_dashed_lines_rr,
		blue_dashed_lines_rr,
		black_fat_lines_rr,
		blue_fat_lines_rr,
	]
	e.face_renderer = faces_rr
	e.free = free
	e.update = update

	// debugging --------------------------------------------------------------

	{
	let hp = []
	e.create_debug_points = function() {

		if (!DEBUG)
			return

		for (let p of hp)
			p.free()
		hp.length = 0

		for (let i = 0, n = point_count(); i < n; i++)
			if (prc[i])
				hp.push(pe.helper_point(get_point(i, v3()),
					{text: i, type: 'point', i: i, visible: true}))

		for (let i = 0, n = line_count(); i < n; i++)
			if (line_rc(i))
				hp.push(pe.helper_point(get_line(i).at(.5, v3()),
					{text: i, type: 'line', i: i, visible: true}))

		for (let face of faces)
			if (face.length)
				hp.push(pe.helper_point(face.center(v3()),
					{text: face.i, type: 'face', i: face.i, visible: true}))

	}}

	return e
}

}()) // module scope.
