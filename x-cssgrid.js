
component('x-cssgrid', function(e) {

	cssgrid_child_widget(e)
	e.align_x = 'stretch'
	e.align_y = 'stretch'
	serializable_widget(e)
	e.classes = 'x-widget x-cssgrid'

	e.init = function() {
		let items = e.items || []
		e.items = []
		for (let item of items) {
			item = component.create(item)
			e.items.push(item)
			e.add(item)
		}
	}

	e.attach = function() {
		make_implicit_lines_explicit_for('x')
		make_implicit_lines_explicit_for('y')
	}

	// form nav ---------------------------------------------------------------

	/*
	let form_nav
	e.property('form_nav',
		() => form_nav,
		function(nav) {
			form_nav = nav
			for (let item of e.items)
				item.fire('form_nav_changed', nav)
		})

	e.set_form_nav_name = function(nav) {
		e.form_nav = global_nav(
	}
	e.prop('form_rowset_name', {store: 'var', type: 'rowset', noinit: true})

	e.on('form_rowset_changed', function(rs) {
		if (!e.form_rowset_name)
			e.form_rowset = rs
	})
	*/

	// model & geometry ///////////////////////////////////////////////////////

	// grid lines & tracks ----------------------------------------------------

	function type(axis) { return axis == 'x' ? 'column' : 'row' }
	function other_axis(axis) { return axis == 'x' ? 'y' : 'x' }

	// get/set gaps

	e.prop('gap_x', {style: 'column-gap', type: 'number', default: 0, style_format: (v) => v+'px'})
	e.prop('gap_y', {style: 'row-gap'   , type: 'number', default: 0, style_format: (v) => v+'px'})

	// get computed track sizes

	function track_sizes(axis) {
		return e.css(`grid-template-${type(axis)}s`).split(' ').map(num)
	}

	// get/set template sizes

	function get_sizes_for(axis) {
		return e.style[`grid-template-${type(axis)}s`]
	}

	function set_sizes_for(axis, s) {
		e.style[`grid-template-${type(axis)}s`] = s
		update_guides_for(axis)
	}

	e.get_sizes_x = function() { return get_sizes_for('x') }
	e.get_sizes_y = function() { return get_sizes_for('y') }
	e.set_sizes_x = function(s) { set_sizes_for('x', s) }
	e.set_sizes_y = function(s) { set_sizes_for('y', s) }
	e.prop('sizes_x')
	e.prop('sizes_y')

	// get/set template sizes from/to array

	function get_sizes(axis) {
		return get_sizes_for(axis).split(' ')
	}

	function set_sizes(axis, ts, prevent_recreate_guides) {
		e.prevent_recreate_guides = prevent_recreate_guides
		e['sizes_'+axis] = ts.join(' ')
		e.prevent_recreate_guides = false
	}

	function set_size(axis, i, sz) {
		let ts = get_sizes(axis)
		ts[i] = sz
		set_sizes(axis, ts)
	}

	// can't have implicit grid lines because spans with -1 can't reach them.
	function make_implicit_lines_explicit_for(axis) {
		let ts = get_sizes(axis)
		let n = track_sizes(axis).length
		for (let i = 0; i < n; i++)
			ts[i] = or(repl(ts[i], '', null), 'auto')
		set_sizes(axis, ts)
	}

	function each_boundary_line(axis, f) {
		let ts = track_sizes(axis)
		let gap = e['gap_'+axis]
		let x1, x2
		let x = 0
		for (let i = 0; i < ts.length; i++) {
			f(i, x)
			x += ts[i] + (i < ts.length-1 ? gap : 0)
		}
		f(ts.length, x)
	}

	// track bounds -----------------------------------------------------------

	function track_bounds_for(axis, i1, i2) {
		let x1, x2
		each_boundary_line(axis, function(i, x) {
			if (i == i1)
				x1 = x
			if (i == i2)
				x2 = x
		})
		return [x1, x2]
	}

	function track_bounds(i1, j1, i2, j2) {
		let [x1, x2] = track_bounds_for('x', i1, i2)
		let [y1, y2] = track_bounds_for('y', j1, j2)
		return [x1, y1, x2, y2]
	}

	function item_track_bounds(item) {
		let i = item.pos_x-1
		let j = item.pos_y-1
		return track_bounds(i, j, i + item.span_x, j + item.span_y)
	}

	// item spans -------------------------------------------------------------

	function span1(item, axis) { return item['pos_'+axis]-1 }
	function span2(item, axis) { return span1(item, axis) + item['span_'+axis] }

	function set_span(item, axis, i1, i2) {
		if (i1 !== false)
			item['pos_'+axis] = i1+1
		if (i2 !== false)
			item['span_'+axis] = i2 - (i1 !== false ? i1 : span1(item, axis))
	}

	e.on('prop_changed', function(k, v, v0, ev) {
		if (ev.target.parent == e)
			if (k == 'align_x' || k == 'align_y') {
				update_focused_item_overlay()
			} else if (k == 'pos_x' || k == 'span_x') {
				update_guides_for('x')
				update_focused_item_span()
			} else if (k == 'pos_y' || k == 'span_y') {
				update_guides_for('y')
				update_focused_item_span()
			}
	})

	// add/remove grid lines --------------------------------------------------

	function remove_line(axis, i) {
		let ts = get_sizes(axis)
		ts.remove(i)
		set_sizes(axis, ts)
		for (let item of e.items) {
			let i1 = span1(item, axis)
			let i2 = span2(item, axis)
			set_span(item, axis,
				i1 >= i && max(0, i1-1),
				i2 >  i && i2-1)
		}
	}

	function insert_line(axis, i) {
		let ts = get_sizes(axis)
		ts.insert(i, '20px')
		set_sizes(axis, ts)
		for (let item of e.items) {
			let i1 = span1(item, axis)
			let i2 = span2(item, axis)
			set_span(item, axis,
				i1 >= i && i1+1,
				i2 >  i && i2+1)
		}
	}

	// add/remove items -------------------------------------------------------

	function	remove_item(item) {
		e.select_item(null, true)
		item.remove()
		let i = e.items.indexOf(item)
		e.items.remove(i)
		return e.items[i] || e.items[0]
	}

	// setting stretch alignment ----------------------------------------------

	function toggle_stretch_for(item, horiz) {
		let attr = horiz ? 'align_x' : 'align_y'
		let align = item[attr]
		if (align == 'stretch')
			align = item['_'+attr] || 'center'
		else {
			item['_'+attr] = align
			align = 'stretch'
		}
		// NOTE: must change item's dimensions before changing its alignment
		// so that the item overlay updates with the right width.
		item[horiz ? 'w' : 'h'] = align == 'stretch' ? 'auto' : null
		item[attr] = align
		return align
	}

	e.toggle_stretch = function(item, horiz, vert) {
		if (horiz && vert) {
			let stretch_x = item.align_x == 'stretch'
			let stretch_y = item.align_y == 'stretch'
			if (stretch_x != stretch_y) {
				e.toggle_stretch(item, !stretch_x, !stretch_y)
			} else {
				e.toggle_stretch(item, true, false)
				e.toggle_stretch(item, false, true)
			}
		} else if (horiz)
			toggle_stretch_for(item, true)
		else if (vert)
			toggle_stretch_for(item, false)
	}

	// visuals ////////////////////////////////////////////////////////////////

	// grid line guides -------------------------------------------------------

	function update_sizes_for(axis) {
		if (!e.editing) return
		if (!e.isConnected) return
		let n = track_sizes(axis).length
		let ts = get_sizes(axis)
		for (let i = 0; i < n; i++) {
			let guide = e.guides[axis][i]
			let s = or(ts[i], 'auto')
			guide.label.set(s.ends('px') ? num(s) : s)
		}
	}

	function update_sizes() {
		update_sizes_for('x')
		update_sizes_for('y')
	}

	e.guides = {x: [], y: []}

	function create_guides_for(axis) {
		let n = track_sizes(axis).length
		for (let i = 0; i < n; i++) {
			let tip = div({class: 'x-arrow x-cssgrid-tip', axis: axis, side: axis == 'x' ? 'top' : 'left'})
			let label = div({class: 'x-cssgrid-label', axis: axis})
			let guide = div({class: 'x-cssgrid-guide', axis: axis}, tip, label)
			tip.axis = axis
			tip.i = i
			label.axis = axis
			label.i = i
			tip.on('pointerdown', tip_pointerdown)
			tip.on('dblclick'   , tip_dblclick)
			label.on('pointerdown', label_pointerdown)
			guide.tip = tip
			guide.label = label
			guide.style[`grid-${type(axis)}-start`] = i+2
			guide.style[`grid-${type(other_axis(axis))}-start`] =  1
			e.guides[axis][i] = guide
			e.add(guide)
		}
	}

	function remove_guides_for(axis) {
		let guides = e.guides[axis]
		if (guides)
			for (let guide of guides)
				guide.remove()
		e.guides[axis] = []
	}

	// span outlines ----------------------------------------------------------

	function span_outline(cls) {
		let so = div({class: 'x-cssgrid-span '+(cls||'')},
			div({class: 'x-cssgrid-span-handle', side: 'top'}),
			div({class: 'x-cssgrid-span-handle', side: 'left'}),
			div({class: 'x-cssgrid-span-handle', side: 'right'}),
			div({class: 'x-cssgrid-span-handle', side: 'bottom'}),
		)
		so.hide()
		e.add(so)
		return so
	}

	function create_focused_item_span() {
		e.focused_item_span = span_outline()
		e.focused_item_span.on('pointerdown', so_pointerdown)
	}

	function remove_focused_item_span() {
		e.focused_item_span.off('pointerdown', so_pointerdown)
		e.focused_item_span.remove()
		e.focused_item_span = null
	}

	function update_focused_item_span() {
		if (!e.editing) return
		let fs = e.focused_item_span
		let fi = e.focused_item
		let show = e.editing && !!fi
		if (show) {
			fs.style['grid-column-start'] = fi.style['grid-column-start']
			fs.style['grid-row-start'   ] = fi.style['grid-row-start'   ]
			fs.style['grid-column-end'  ] = fi.style['grid-column-end'  ]
			fs.style['grid-row-end'     ] = fi.style['grid-row-end'     ]
		}
		fs.show(show)
		update_focused_item_overlay()
	}

	// item overlays ----------------------------------------------------------

	function item_overlay(cls) {
		let ol = div({class: 'x-cssgrid-item-overlay '+(cls||'')})
		ol.hide()
		e.add(ol)
		return ol
	}

	function create_item_overlays() {
		e.hit_item_overlay     = item_overlay('hover')
		e.focused_item_overlay = item_overlay('focused')
		e.add(e.hit_item_overlay, e.focused_item_overlay)
		for (let item of e.selected_items) {
			item.selected_overlay = item_overlay('selected')
			item.selected_overlay.on('pointerdown', sio_pointerdown)
			item.selected_overlay.style['pointer-events'] = 'none'
			item.selected_overlay.item = item
		}
		e.hit_item_overlay.on('pointerdown', hio_pointerdown)
		e.focused_item_overlay.on('pointerdown', fio_pointerdown)
	}

	function remove_item_overlays() {
		e.hit_item_overlay.off('pointerdown', hio_pointerdown)
		e.hit_item_overlay.remove()
		e.hit_item_overlay = null
		e.focused_item_overlay.remove()
		e.focused_item_overlay = null
		for (let item of e.selected_items) {
			item.selected_overlay.off('pointerdown', sio_pointerdown)
			item.selected_overlay.remove()
			item.selected_overlay = null
		}
	}

	function update_item_overlay(ol, item) {
		let show = !!item
		if (show) {
			let css = item.css()
			ol.style['grid-column-start'] = css['grid-column-start']
			ol.style['grid-column-end'  ] = css['grid-column-end'  ]
			ol.style['grid-row-start'   ] = css['grid-row-start'   ]
			ol.style['grid-row-end'     ] = css['grid-row-end'     ]
			ol.style['justify-self'     ] = 'stretch'
			ol.style['align-self'       ] = 'stretch'
		}
		ol.show(show)
	}

	function update_hit_item_overlay() {
		update_item_overlay(e.hit_item_overlay, e.hit_item != e.focused_item && e.hit_item)
	}

	function update_focused_item_overlay() {
		update_hit_item_overlay()
		update_item_overlay(e.focused_item_overlay, e.focused_item)
	}

	function update_item_overlays() {
		update_focused_item_overlay()
		for (let item of e.selected_items)
			update_item_overlay(item.selected_overlay, item)
	}

	// controller /////////////////////////////////////////////////////////////

	// editing mode -----------------------------------------------------------

	function update_guides_for(axis) {
		if (!e.editing) return
		if (!e.isConnected) return
		if (!e.prevent_recreate_guides) {
			remove_guides_for(axis)
			create_guides_for(axis)
		}
		update_sizes_for(axis)
	}

	function update_guides() {
		if (!e.editing) return
		if (!e.isConnected) return
		update_guides_for('x')
		update_guides_for('y')
	}

	function enter_editing() {
		e.focused_item = e.items[0]
		create_guides_for('x')
		create_guides_for('y')
		create_item_overlays()
		create_focused_item_span()
		update_sizes()
		update_focused_item_span()
		update_item_overlays()
		e.on('pointermove', e_pointermove)
	}

	function exit_editing() {
		e.add_button.hide()
		e.off('pointermove', e_pointermove)
		remove_item_overlays()
		remove_focused_item_span()
		remove_guides_for('x')
		remove_guides_for('y')
	}

	let editing = false
	e.property('editing',
		function() { return editing },
		function(v) {
			v = !!v
			if (editing == v)
				return
			editing = v
			e.attrval('tabindex', v ? 0 : null)
			e.class('x-editing', v)
			if (v)
				enter_editing()
			else
				exit_editing()
		}
	)

	// selecting items --------------------------------------------------------

	e.selected_items = new Set()

	e.select_item = function(item, single) {
		remove_item_overlays()
		if (single)
			e.selected_items.clear()
		if (item)
			e.selected_items.add(item)
		e.focused_item = e.selected_items.size == 1
			? e.selected_items.values().next().value : null
		create_item_overlays()
		update_item_overlays()
		update_focused_item_span()
	}

	// hover items with the mouse ---------------------------------------------

	function hit_test_item(mx, my) {
		let r = e.rect()
		mx -= r.x
		my -= r.y
		for (let item of e.items) {
			let [x1, y1, x2, y2] = item_track_bounds(item)
			if (mx >= x1 && mx < x2 && my >= y1 && my < y2)
				return item
		}
	}

	function e_pointermove(mx, my) {
		e.hit_item = hit_test_item(mx, my)
		update_hit_item_overlay()
	}

	// select items with the mouse --------------------------------------------

	function hio_pointerdown(ev, mx, my) {
		e.select_item(e.hit_item, !ev.shiftKey)
		return false
	}

	function fio_pointerdown(ev, mx, my) {
		if (e.focused_item.typename == 'cssgrid') {
			e.focused_item.editmode = true
			e.focused_item.focus()
		}
		return false
	}

	function sio_pointerdown(ev, mx, my) {
		//return false
	}

	// drag-move guide tips => change grid template sizes ---------------------

	{
		let drag_mx, s0, z0

		function tip_pointerdown(ev, mx, my) {
			if (ev.ctrlKey) {
				remove_line(this.axis, this.i+1)
				return false
			}

			s0 = track_sizes(this.axis)[this.i]
			drag_mx =
				(this.axis == 'x' ? mx : my) -
				e.rect()[this.axis]

			// transform auto size to pixels to be able to move the line.
			let tz = get_sizes(this.axis)
			z0 = tz[this.i]
			if (z0 == 'auto') {
				z0 = s0
				z0 = z0.toFixed(0) + 'px'
				tz[this.i] = z0
				set_sizes(this.axis, tz, true)
			}
			z0 = num(z0)

			return this.capture_pointer(ev, tip_pointermove)
		}

		function tip_pointermove(mx, my, ev) {
			let dx = (this.axis == 'x' ? mx : my) - drag_mx - e.rect()[this.axis]
			let tz = get_sizes(this.axis)
			let z = tz[this.i]
			if (z.ends('px')) {
				z = s0 + dx
				if (!ev.shiftKey)
					z = round(z / 10) * 10
				z = z.toFixed(0) + 'px'
			} else if (z.ends('%')) {
				z = num(z)
				let dz = lerp(dx, 0, s0, 0, z0)
				z = z0 + dz
				if (!ev.shiftKey) {
					let z1 = round(z / 5) * 5
					let z2 = round(z / (100 / 3)) * (100 / 3)
					z = abs(z1 - z) < abs(z2 - z) ? z1 : z2
				}
				z = z.toFixed(1) + '%'
			} else if (z.ends('fr')) {
				// TODO:
			}
			tz[this.i] = z
			set_sizes(this.axis, tz, true)
		}

	}

	function tip_dblclick() {
		insert_line(this.axis, this.i+1)
		return false
	}

	function label_pointerdown() {
		let z = get_sizes(this.axis)[this.i]
		if (z == 'auto') {
			z = track_sizes(this.axis)[this.i]
			z = z.toFixed(0) + 'px'
		} else if (z.ends('px')) {
			let px = track_sizes(this.axis)[this.i]
			z = lerp(px, 0, e.clientWidth, 0, 100)
			z = z.toFixed(1) + '%'
		} else if (z.ends('fr')) {
			z = 'auto'
		} else if (z.ends('%')) {
			z = 'auto'
		}
		set_size(this.axis, this.i, z)
		return false
	}

	// drag-move item => align or move to different grid area -----------------

	function hit_test_edge_center(mx, my, bx1, bx2, by, side) {
		return abs((bx1 + bx2) / 2 - mx) <= 5 && abs(by - my) <= 5 && side
	}

	function hit_test_focused_item_span(mx, my) {
		if (!focused_item)
			return
		let [bx1, by1, bx2, by2] = item_track_bounds(e.focused_item)
		let r = e.rect()
		mx -= r.x
		my -= r.y
		return (
			hit_test_edge_center(mx, my, bx1, bx2, by1, 'top'   ) ||
			hit_test_edge_center(mx, my, bx1, bx2, by2, 'bottom') ||
			hit_test_edge_center(my, mx, by1, by2, bx1, 'left'  ) ||
			hit_test_edge_center(my, mx, by1, by2, bx2, 'right' )
		)
	}

	function start_move_item(mx, my) {
		hit_item_overlay.class('x-cssgrid-moving', true)

		let css = hit_item.css()
		let r = hit_item.rect()
		drag_mx = drag_mx - r.x + num(css['margin-left'])
		drag_my = drag_my - r.y + num(css['margin-top' ])

		move_item(mx, my)
	}

	function stop_move_item() {
		push_in_item()
		hit_item_overlay.class('x-cssgrid-moving', false)
		raf(update)
	}

	function hit_test_inside_span_for(horiz, x1, x2) {
		let min_dx = 1/0
		let closest_i, closest_bx1, closest_bx2
		let bx1
		each_boundary_line(horiz, function(i, bx2) {
			if (i > 0) {
				let dx = (x1 >= bx1 && x2 <= bx2) ? 0 : abs((x1 + x2) / 2 - (bx1 + bx2) / 2)
				if (dx < min_dx) {
					min_dx = dx
					closest_i = i-1
					closest_bx1 = bx1
					closest_bx2 = bx2
				}
			}
			bx1 = bx2
		})
		return [closest_i, closest_bx1, closest_bx2]
	}

	function hit_test_inside_span(item) {
		let er = e.rect()
		let ir = item.rect()
		let x1 = ir.x1 - er.x1
		let x2 = ir.x2 - er.x1
		let y1 = ir.y1 - er.y1
		let y2 = ir.y2 - er.y1
		let [i, bx1, bx2] = hit_test_inside_span_for(true , x1, x2)
		let [j, by1, by2] = hit_test_inside_span_for(false, y1, y2)
		return [i, j, bx1, by1, bx2, by2]
	}

	function hit_test_span_edge(dx, x1, x2, bx1, bx2) {
		let dx1 = abs(bx1 - x1)
		let dx2 = abs(bx2 - x2)
		if (dx1 <= dx && dx2 <= dx) // close to both edges
			if (abs(dx1 - dx2) <= (dx1 + dx2) / 2)
				return 'center'
			else
				return dx1 < dx2 ? 'start' : 'end'
		else if (dx1 <= dx)
			return 'start'
		else if (dx2 <= dx)
			return 'end'
		else if (abs(dx1 - dx2) <= dx)
			return 'center'
	}

	function move_item(mx, my) {

		let x = mx - drag_mx
		let y = my - drag_my

		let x1 = x - e.ox
		let y1 = y - e.oy
		let hr = hit_item.rect()
		let x2 = x1 + hr.w
		let y2 = y1 + hr.h
		let i1 = span1(hit_item, true)
		let i2 = span2(hit_item, true)
		let j1 = span1(hit_item, false)
		let j2 = span2(hit_item, false)
		let [bx1, by1, bx2, by2] = track_bounds(i1, j1, i2, j2)
		let align_x = hit_test_span_edge(20, x1, x2, bx1, bx2)
		let align_y = hit_test_span_edge(20, y1, y2, by1, by2)
		let stretch_x = hit_item.align_x == 'stretch'
		let stretch_y = hit_item.align_y == 'stretch'

		if (align_x && align_y) {
			push_in_item()
			if (align_x && !stretch_x)
				hit_item.align_x = align_x
			if (align_y && !stretch_y)
				hit_item.align_y = align_y
			raf(update)
		} else {
			pop_out_item()

			let r = e.rect()
			hit_item.x = !stretch_x ? x : r.x + bx1 + (i1 > 0 ? e.gap_x / 2 : 0)
			hit_item.y = !stretch_y ? y : r.y + by1 + (j1 > 0 ? e.gap_y / 2 : 0)

			let [i, j, mbx1, mby1, mbx2, mby2] = hit_test_inside_span(hit_item)
			let can_move_item =
				(i < i1 || i >= i2) ||
				(j < j1 || j >= j2)
			if (can_move_item) {
				//set_span(hit_item, 'column', i, i+1)
				//set_span(hit_item, 'row'   , j, j+1)
				//update_item_ph()
			}

			raf(update)
		}

	}

	// drag-resize item's span outline => change item's grid area -------------

	{
		let drag_mx, drag_my, side

		function resize_focused_item_span(mx, my) {
			let horiz = side == 'left' || side == 'right'
			let axis = horiz ? 'x' : 'y'
			let second = side == 'right' || side == 'bottom'
			mx = horiz ? mx - drag_mx : my - drag_my
			let i1 = span1(e.focused_item, axis)
			let i2 = span2(e.focused_item, axis)
			let dx = 1/0
			let closest_i
			each_boundary_line(axis, function(i, x) {
				if (second ? i > i1 : i < i2) {
					if (abs(x - mx) < dx) {
						dx = abs(x - mx)
						closest_i = i
					}
				}
			})
			set_span(e.focused_item, axis,
				!second ? closest_i : i1,
				 second ? closest_i : i2)
		}

		function so_pointerdown(ev, mx, my) {
			let handle = ev.target.closest('.x-cssgrid-span-handle')
			if (!handle) return
			side = handle.attr('side')

			let [bx1, by1, bx2, by2] = item_track_bounds(e.focused_item)
			let second = side == 'right' || side == 'bottom'
			drag_mx = mx - (second ? bx2 : bx1)
			drag_my = my - (second ? by2 : by1)
			resize_focused_item_span(mx, my)

			return this.capture_pointer(ev, so_pointermove)
		}

		function so_pointermove(mx, my) {
			resize_focused_item_span(mx, my)
		}

	}

	/*
	// drag & drop controller ----------------------------------------------

	let hit_item, hit_area
	let dragging, drag_mx, drag_my

	e.on('pointerdown', function(ev) {
		if (!e.editing)
			return
		e.focus()
		if (!hit_item) {
			if (!ev.shiftKey)
				e.select_item(null, true)
			return
		}
		dragging = true
		drag_mx = ev.clientX
		drag_my = ev.clientY
		this.setPointerCapture(ev.pointerId)
		e.select_item(hit_item, !ev.shiftKey)
		return false
	})

	e.on('pointerup', function(ev) {
		if (!e.editing)
			return
		if (!hit_item) return
		this.releasePointerCapture(ev.pointerId)
		if (dragging == 'move_item') {
			stop_move_item()
		} else if (dragging == 'resize_focused_item_span') {
			stop_resize_focused_item_span()
		}
		dragging = false
		return false
	})

	e.on('dblclick', function(ev) {
		if (!e.editing)
			return
		if (!hit_item) return
		toggle_stretch(hit_item, !ev.shiftKey, !ev.ctrlKey)
		raf(update)
		return false
	})

	let cursors = {
		left   : 'ew-resize',
		right  : 'ew-resize',
		top    : 'ns-resize',
		bottom : 'ns-resize',
	}

	e.on('pointermove', function(mx, my, ev) {
		if (!e.editing)
			return
		if (dragging == 'move_item') {
			move_item(mx, my)
		} else if (dragging == 'resize_focused_item_span') {
			resize_focused_item_span(mx, my)
		} else if (dragging) {
			if (max(abs(mx - drag_mx), abs(my - drag_my)) > 10) {
				if (hit_area == 'item') {
					dragging = 'move_item'
					start_move_item(mx, my)
				} else {
					dragging = 'resize_focused_item_span'
					start_resize_focused_item_span(mx, my)
				}
			}
		} else {
			let cur
			if (!ev.target.hasclass('x-cssgrid-line-tip')) {
				hit_area = hit_test_focused_item_span(mx, my)
				cur = cursors[hit_area]
				hit_item = cur && focused_item
				if (!hit_item) {
					hit_item = hit_test_item(mx, my)
					if (hit_item) {
						cur = 'move'
						hit_area = 'item'
					}
				}
				update_item_overlays()
			}
			e.style.cursor = cur || null
		}
		return false
	})

	// item moving in/out of layout ----------------------------------------

	let item_ph = div({class: 'x-cssgrid-item-ph'}) // ph=placeholder

	function update_item_ph() {
		// position & size the placeholder in grid so that the tracks don't change.
		let css = hit_item.css()
		item_ph.style['grid-column-start'] = css['grid-column-start']
		item_ph.style['grid-column-end'  ] = css['grid-column-end'  ]
		item_ph.style['grid-row-start'   ] = css['grid-row-start'   ]
		item_ph.style['grid-row-end'     ] = css['grid-row-end'     ]
		item_ph.style['margin-left'      ] = css['margin-left'      ]
		item_ph.style['margin-right'     ] = css['margin-right'     ]
		item_ph.style['margin-top'       ] = css['margin-top'       ]
		item_ph.style['margin-bottom'    ] = css['margin-bottom'    ]
		item_ph.style['justify-self'     ] = css['justify-self'     ]
		item_ph.style['align-self'       ] = css['align-self'       ]
		item_ph.w = hit_item.offsetWidth
		item_ph.h = hit_item.offsetHeight
	}

	function pop_out_item() {
		if (hit_item.parent != e)
			return

		// fixate the size of the poped out item and keep the old values.
		hit_item._w = hit_item.style.width
		hit_item._h = hit_item.style.height
		hit_item._pos_x = hit_item.pos_x
		hit_item._pos_y = hit_item.pos_y
		hit_item._span_x = hit_item.span_x
		hit_item._span_y = hit_item.span_y
		hit_item._margin_x = hit_item.style['margin-left']
		hit_item._margin_y = hit_item.style['margin-top']

		hit_item.w = hit_item.offsetWidth
		hit_item.h = hit_item.offsetHeight

		update_item_ph()

		hit_item.style['margin-left'] = 0
		hit_item.style['margin-top' ] = 0
		hit_item.pos_x = 1
		hit_item.pos_y = 1

		hit_item.remove()
		hit_item_overlay.remove()
		focused_item_overlay.remove()
		hit_item.style.position = 'absolute'
		hit_item_overlay.style.position = 'absolute'
		focused_item_overlay.style.position = 'absolute'
		e.add(item_ph)
		document.body.add(hit_item)
		document.body.add(hit_item_overlay)
		document.body.add(focused_item_overlay)
		update_item_overlays()
	}

	function push_in_item() {
		if (hit_item.parent == e)
			return
		item_ph.remove()

		hit_item.x = null
		hit_item.y = null
		hit_item.w = hit_item._w
		hit_item.h = hit_item._h
		hit_item.pos_x = hit_item._pos_x
		hit_item.pos_y = hit_item._pos_y
		hit_item.span_x = hit_item._span_x
		hit_item.span_y = hit_item._span_y
		hit_item.style['margin-left'] = hit_item._margin_x
		hit_item.style['margin-top' ] = hit_item._margin_y
		hit_item.style.position = null
		hit_item_overlay.style.position = null
		focused_item_overlay.style.position = null

		e.add(hit_item)
		update_item_overlays()
		e.add(hit_item_overlay)
		e.add(focused_item_overlay)
	}

	*/

	// show add button when hovering empty grid cells -------------------------

	e.add_button = button({classes: 'x-cssgrid-add-button', text: 'add...'})
	e.add_button.hide()
	e.add(e.add_button)
	e.add_button.on('click', function() {
		let item = widget_placeholder()
		item.pos_x = this.pos_x
		item.pos_y = this.pos_y
		e.items.push(item)
		e.add(item)
		e.fire('widget_tree_changed')
	})

	function is_cell_empty(i, j) {
		for (let item of e.items)
			if (
				item.pos_x <= i && item.pos_x + item.span_x > i &&
				item.pos_y <= j && item.pos_y + item.span_y > j
			) return false
		return true
	}

	e.on('pointermove', function(mx, my, ev) {
		if (ev.buttons)
			return
		if (!e.editing)
			return

		let r = e.rect()
		my -= r.y
		mx -= r.x
		let pos_x, pos_y, x1, y1, x2, y2
		each_boundary_line('x', function(i, x) {
			if (mx > x) {
				pos_x = i + 1
				x1 = x
			} else if (x2 == null)
				x2 = x
		})
		each_boundary_line('y', function(j, y) {
			if (my > y) {
				pos_y = j + 1
				y1 = y
			} else if (y2 == null)
				y2 = y
		})

		e.add_button.pos_x = pos_x
		e.add_button.pos_y = pos_y

		e.add_button.show(is_cell_empty(pos_x, pos_y))

	})

	// keyboard bindings ------------------------------------------------------

	e.on('keydown', function(key, shift, ctrl) {
		if (!e.editing)
			return
		if (key == 'Tab') {
			let item = e.items[mod(e.items.indexOf(e.focused_item) + (shift ? -1 : 1), e.items.length)]
			e.select_item(item, true)
			return false
		}
		if (e.focused_item) {
			if (key == 'Enter') { // toggle stretch
				e.toggle_stretch(e.focused_item, !shift, !ctrl)
				return false
			}
			if (key == 'Delete') {
				let next_item = remove_item(e.focused_item)
				e.select_item(next_item, true)
				return false
			}
			if (key == 'ArrowLeft' || key == 'ArrowRight' || key == 'ArrowUp' || key == 'ArrowDown') {
				let horiz = key == 'ArrowLeft' || key == 'ArrowRight'
				let fw = key == 'ArrowRight' || key == 'ArrowDown'
				if (ctrl) { // change alignment
					let attr = horiz ? 'align_x' : 'align_y'
					let align = e.focused_item[attr]
					if (align == 'stretch')
						align = e.toggle_stretch(e.focused_item, horiz, !horiz)
					let align_indices = {start: 0, center: 1, end: 2}
					let align_map = keys(align_indices)
					align = align_map[align_indices[align] + (fw ? 1 : -1)]
					e.focused_item[attr] = align
				} else { // resize span or move to diff. span
					let axis = horiz ? 'x' : 'y'
					if (shift) { // resize span
						let i1 = span1(e.focused_item, axis)
						let i2 = span2(e.focused_item, axis)
						let i = max(i1+1, i2 + (fw ? 1 : -1))
						set_span(e.focused_item, axis, false, i)
					} else {
						let i = max(0, span1(e.focused_item, axis) + (fw ? 1 : -1))
						set_span(e.focused_item, axis, i, i+1)
					}
				}
				return false
			}
		}

	})

	// xmodule interface ------------------------------------------------------

	e.accepts_form_widgets = true

	e.child_widgets = function() {
		return e.items.slice()
	}

	e.replace_widget = function(old_widget, new_widget) {
		let i = e.items.indexOf(old_widget)
		e.items[i] = new_widget
		old_widget.parent.replace(old_widget, new_widget)
		e.fire('widget_tree_changed')
	}

	e.select_child_widget = function(widget) {
		// select_item(widget, true)
		e.editing = false
		if (widget.editing != null)
			widget.editing = true
	}

	e.inspect_fields = [
		{name: 'gap', type: 'number'},
	]

	e.serialize = function() {
		let t = e.serialize_fields()
		t.items = []
		for (let item of e.items)
			t.items.push(item.serialize())
		return t
	}

})

