
component('x-cssgrid', function(e) {

	e.default_align_x = 'stretch'
	e.default_align_y = 'stretch'
	layouted_widget(e)
	serializable_widget(e)

	e.class('x-widget')
	e.class('x-cssgrid')

	e.init = function() {
		let items = e.items || [widget_placeholder()]
		e.items = []
		for (let item of items) {
			item = component.create(item)
			e.items.push(item)
			e.add(item)
		}
	}

	e.attach = function() {
		create_lines()
		after(0.1, () => raf(update))
		document.on('layout_changed', update)
	}

	e.detach = function() {
		document.off('layout_changed', update)
	}

	// spans ------------------------------------------------------------------

	function span1(item, type) { return e[type == 'column' ? 'pos_x' : 'pos_y']-1 }
	function span2(item, type) { return span1(item, type) + e[type == 'column' ? 'span_x' : 'span_y'] }
	function set_span1(item, type, i) { item[type == 'column' ? 'pos_x' : 'pos_y'] = i+1 }
	function set_span2(item, type, i) { item[type == 'column' ? 'span_x' : 'span_y'] = i - span1(item, type) }

	// tracks -----------------------------------------------------------------

	e.prop('gap_x', {style: 'column-gap', type: 'number', default: 0, style_format: (v) => v+'px'})
	e.prop('gap_y', {style: 'row-gap'   , type: 'number', default: 0, style_format: (v) => v+'px'})

	function track_sizes(type) {
		return e.css(`grid-template-${type}s`).split(' ').map(num)
	}

	function template_sizes(type) {
		let tsizes = e.style[`grid-template-${type}s`].split(' ')
		let sizes = track_sizes(type)
		for (let i = 0; i < sizes.length; i++)
			tsizes[i] = tsizes[i] || 'auto'
		return tsizes
	}

	function set_template_sizes_s(type, s) {
		e.style[`grid-template-${type}s`] = s
	}

	function set_template_sizes(type, sizes) {
		set_template_sizes_s(type, sizes.join(' '))
	}

	e.get_sizes_x = function() { return template_sizes('column').join(' ') }
	e.get_sizes_y = function() { return template_sizes('row'   ).join(' ') }
	e.set_sizes_x = function(s) { set_template_sizes_s('column', s) }
	e.set_sizes_y = function(s) { set_template_sizes_s('row'   , s) }
	e.prop('sizes_x')
	e.prop('sizes_y')

	function set_template_size(type, i, sz) {
		let tsizes = template_sizes(type)
		tsizes[i] = sz
		set_template_sizes(type, tsizes)
	}

	function each_track_line(type, f) {
		let sizes = track_sizes(type)
		let gap = e[type == 'column' ? 'gap_x' : 'gap_y']
		let x1, x2
		let x = 0
		for (let i = 0; i < sizes.length; i++) {
			f(i, x)
			if (i > 0)
				x += gap / 2
			x += sizes[i]
			if (i < sizes.length-1)
				x += gap / 2
			else
				x -= 1 // make it fit the grid since it's overflow hidden
		}
		f(sizes.length, x)
	}

	function track_bounds_for(type, i1, i2) {
		let x1, x2
		each_track_line(type, function(i, x) {
			if (i == i1)
				x1 = x
			if (i == i2)
				x2 = x
		})
		return [x1, x2]
	}

	function track_bounds(i1, j1, i2, j2) {
		let [x1, x2] = track_bounds_for('column', i1, i2)
		let [y1, y2] = track_bounds_for('row'   , j1, j2)
		return [x1, y1, x2, y2]
	}

	function item_track_bounds(item) {
		let i = item.pos_x-1
		let j = item.pos_y-1
		return track_bounds(i, j, i + item.span_x, j + item.span_y)
		return [x1, y1, x2, y2]
	}

	// add/remove inter-track lines -------------------------------------------

	function remove_line(type, i) {
		let tsizes = template_sizes(type)
		tsizes.remove(i)
		set_template_sizes(type, tsizes)
		for (let item of e.items) {
			let i1 = span1(item, type)
			let i2 = span2(item, type)
			if (i1 >= i)
				set_span1(item, type, max(0, i1-1))
			if (i2 > i)
				set_span2(item, type, i2-1)
		}
	}

	function insert_line(type, i) {
		let tsizes = template_sizes(type)
		tsizes.insert(i, '20px')
		set_template_sizes(type, tsizes)
		for (let item of e.items) {
			let i1 = span1(item, type)
			let i2 = span2(item, type)
			if (i1 >= i)
				set_span1(item, type, i1+1)
			if (i2 > i)
				set_span2(item, type, i2+1)
		}
	}

	// add-remove items -------------------------------------------------------

	function	remove_item(item) {
		select_item(null, true)
		item.remove()
		let i = e.items.indexOf(item)
		e.items.remove(i)
		select_item(e.items[i] || e.items[0], true)
	}

	// line tips & guides -----------------------------------------------------

	let hit_line_tip

	function tip_set_cursor(tip, shift) {
		// TODO: find a "remove" cursor.
		// tip.style.cursor = shift ? 'not-allowed' : null
	}

	function tip_mouseenter(ev) {
		hit_line_tip = this
		tip_set_cursor(hit_line_tip, ev.shiftKey)
	}

	function tip_mouseleave() {
		tip_set_cursor(hit_line_tip)
		hit_line_tip = null
	}

	{
		let dragging, drag_mx, cx, s0, z0

		function tip_mousedown(ev) {
			if (ev.ctrlKey) {
				remove_line(this.type, this.track_index+1)
				create_lines()
				update()
				return false
			}
			dragging = true
			this.setPointerCapture(ev.pointerId)
			let sizes = track_sizes(this.type)
			let cr = this.client_rect()
			let pcr = this.parent.client_rect()
			let left = this.type == 'column' ? 'left' : 'top'
			cx = cr[left] - pcr[left]
			drag_mx = ev[this.type == 'column' ? 'clientX' : 'clientY'] - cr[left]
			s0 = sizes[this.track_index]

			let tsizes = template_sizes(this.type)
			z0 = tsizes[this.track_index]
			if (z0 == 'auto') {
				z0 = track_sizes(this.type)[this.track_index]
				z0 = z0.toFixed(0) + 'px'
				tsizes[this.track_index] = z0
				set_template_sizes(this.type, tsizes)
			}
			z0 = num(z0)

			return false
		}

		function tip_mousemove(mx, my, ev) {
			if (!dragging) return
			let cr = this.parent.client_rect()
			let left = this.type == 'column' ? 'left' : 'top'
			mx = (this.type == 'column' ? mx : my) - drag_mx - cr[left]
			let ds = mx - cx
			let tsizes = template_sizes(this.type)
			let z = tsizes[this.track_index]
			if (z.ends('px')) {
				z = s0 + ds
				if (!ev.shiftKey)
					z = round(z / 10) * 10
				z = z.toFixed(0) + 'px'
			} else if (z.ends('%')) {
				z = num(z)
				let dz = lerp(ds, 0, s0, 0, z0)
				z = z0 + dz
				if (!ev.shiftKey) {
					let z1 = round(z / 5) * 5
					let z2 = round(z / (100 / 3)) * (100 / 3)
					z = abs(z1 - z) < abs(z2 - z) ? z1 : z2
				}
				z = z.toFixed(1) + '%'
			} else if (z.ends('fr')) {

			}
			tsizes[this.track_index] = z
			set_template_sizes(this.type, tsizes)
			update()
			return false
		}

		function tip_mouseup(ev) {
			if (!dragging) return
			dragging = false
			this.releasePointerCapture(ev.pointerId)
			return false
		}
	}

	function tip_dblclick() {
		insert_line(this.type, this.track_index+1)
		create_lines()
		update()
		return false
	}

	function label_mousedown(ev) {
		let z = template_sizes(this.tip.type)[this.tip.track_index]
		if (z == 'auto') {
			z = track_sizes(this.tip.type)[this.tip.track_index]
			z = z.toFixed(0) + 'px'
		} else if (z.ends('px')) {
			let px = track_sizes(this.tip.type)[this.tip.track_index]
			z = lerp(px, 0, e.clientWidth, 0, 100)
			z = z.toFixed(1) + '%'
		} else if (z.ends('fr')) {
			z = 'auto'
		} else if (z.ends('%')) {
			z = 'auto'
		}
		set_template_size(this.tip.type, this.tip.track_index, z)
		update()
		return false
	}

	function update_lines_for(type) {
		if (!e.tips)
			return
		let gap = e[type == 'column' ? 'gap_x' : 'gap_y']
		let tsizes = template_sizes(type)
		let sizes = track_sizes(type)
		let X = type == 'column' ? 'x' : 'y'
		let Y = type == 'column' ? 'y' : 'x'
		let x = gap / 2
		let ti = 0
		let guide_w = e.client_rect()[type == 'column' ? 'height' : 'width']
		for (let tip of e.tips)
			if (tip.type == type) {
				x += sizes[ti]
				tip[X] = x
				tip[Y] = 0
				tip.guide[type == 'column' ? 'h' : 'w'] = guide_w
				tip.guide[X] = x
				tip.label[Y] = 0
				tip.label[X] = x
				tip.label.set(tsizes[ti].ends('px') ? num(tsizes[ti]) : tsizes[ti])
				tip.show()
				// -1 is to place it inside the grid because it has overflow hidden.
				x += (ti < sizes.length-2) ? gap : gap / 2 - 1
				ti++
			}
	}

	function update() {
		update_lines_for('column')
		update_lines_for('row')
		update_item_overlays()
		update_focused_item_span()
	}

	function create_lines_for(type) {
		let side = type == 'column' ? 'top' : 'left'
		for (let i = 0; i < track_sizes(type).length; i++) {
			let tip = div({class: 'x-arrow x-cssgrid-line-tip', side: side})
			tip.hide()
			tip.label = div({class: 'x-cssgrid-line-label', side: side})
			tip.guide = div({class: 'x-cssgrid-line-guide', side: side})
			tip.track_index = i
			tip.type = type
			tip.label.tip = tip
			e.tips.push(tip)
			tip.on('pointerdown' , tip_mousedown)
			tip.on('pointermove' , tip_mousemove)
			tip.on('pointerup'   , tip_mouseup)
			tip.on('dblclick'    , tip_dblclick)
			tip.on('pointerenter', tip_mouseenter)
			tip.on('pointerleave', tip_mouseleave)
			tip.label.on('pointerdown', label_mousedown)

			e.add(tip)
			e.add(tip.guide)
			e.add(tip.label)
		}
	}

	function remove_lines() {
		if (e.tips)
			for (let tip of e.tips) {
				tip.guide.remove()
				tip.label.remove()
				tip.remove()
			}
	}

	function create_lines() {
		remove_lines()
		if (!e.editing || !e.isConnected)
			return
		e.tips = []
		create_lines_for('column')
		create_lines_for('row')
	}

	// item selection ---------------------------------------------------------

	let selected_items = new Set()
	let focused_item

	function select_item(item, single) {
		if (single)
			selected_items.clear()
		if (item)
			selected_items.add(item)
		focused_item = selected_items.size == 1
			? selected_items.values().next().value : null
		update_item_overlays()
		update_focused_item_span()
	}

	// item overlays ----------------------------------------------------------

	function item_overlay(cls) {
		let overlay = div({class: 'x-cssgrid-item-overlay '+(cls||'')})
		overlay.hide()
		e.add(overlay)
		return overlay
	}

	function update_item_overlay(overlay, item) {
		let show = !!item && e.editing
		if (show) {
			overlay.x = item.offsetLeft
			overlay.y = item.offsetTop
			overlay.w = item.offsetWidth
			overlay.h = item.offsetHeight
		}
		overlay.show(show)
	}

	let hit_item_overlay     = item_overlay('hover')
	let focused_item_overlay = item_overlay('focused')

	function update_item_overlays() {
		update_item_overlay(hit_item_overlay    , hit_item != focused_item && hit_item)
		update_item_overlay(focused_item_overlay, focused_item)
	}

	// item moving in/out of layout ----------------------------------------

	let item_ph = div({class: 'x-cssgrid-item-ph'}) // ph=placeholder

	function pop_out_item() {
		if (hit_item.parent != e)
			return

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

		// fixate the size of the poped out item and keep the old values.
		hit_item._w = hit_item.style.width
		hit_item._h = hit_item.style.height
		hit_item.w = hit_item.offsetWidth
		hit_item.h = hit_item.offsetHeight

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
		hit_item.style.position = null
		hit_item_overlay.style.position = null
		focused_item_overlay.style.position = null

		e.add(hit_item)
		update_item_overlays()
		e.add(hit_item_overlay)
		e.add(focused_item_overlay)
	}

	// item moving ---------------------------------------------------------

	function hit_test_item(mx, my) {
		for (let item of e.items)
			if (item.client_rect().contains(mx, my))
				return item
	}

	function start_move_item(mx, my) {
		hit_item_overlay.class('x-cssgrid-moving', true)

		let css = hit_item.css()
		let r = hit_item.client_rect()
		drag_mx = drag_mx - r.left + num(css['margin-left'])
		drag_my = drag_my - r.top  + num(css['margin-top' ])

		move_item(mx, my)
	}

	function stop_move_item() {
		push_in_item()
		hit_item_overlay.class('x-cssgrid-moving', false)
		raf(update)
	}

	function hit_test_inside_span_for(type, x1, x2) {
		let min_dx = 1/0
		let closest_i, closest_bx1, closest_bx2
		let bx1
		each_track_line(type, function(i, bx2) {
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
		let er = e.client_rect()
		let ir = item.client_rect()
		let x1 = ir.left   - er.left
		let x2 = ir.right  - er.left
		let y1 = ir.top    - er.top
		let y2 = ir.bottom - er.top
		let [i, bx1, bx2] = hit_test_inside_span_for('column', x1, x2)
		let [j, by1, by2] = hit_test_inside_span_for('row'   , y1, y2)
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

		let x1 = x - e.offsetLeft
		let y1 = y - e.offsetTop
		let x2 = x1 + hit_item.offsetWidth
		let y2 = y1 + hit_item.offsetHeight
		let i1 = span1(hit_item, 'column')
		let j1 = span1(hit_item, 'row'   )
		let i2 = span2(hit_item, 'column')
		let j2 = span2(hit_item, 'row'   )
		let [bx1, by1, bx2, by2] = track_bounds(i1, j1, i2, j2)
		let align_x = hit_test_span_edge(20, x1, x2, bx1, bx2)
		let align_y = hit_test_span_edge(20, y1, y2, by1, by2)
		print(bx1, by1, bx2, by2, align_x, align_y)
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
			hit_item.x = !stretch_x ? x : e.client_rect().left + bx1 + (i1 > 0 ? e.gap_x / 2 : 0)
			hit_item.y = !stretch_y ? y : e.client_rect().top  + by1 + (j1 > 0 ? e.gap_y / 2 : 0)

			let [i, j, mbx1, mby1, mbx2, mby2] = hit_test_inside_span(hit_item)
			let can_move_item =
				(i < i1 || i >= i2) ||
				(j < j1 || j >= j2)
			if (can_move_item) {
				set_span1(hit_item, 'column', i)
				set_span1(hit_item, 'row'   , j)
				set_span2(hit_item, 'column', i+1)
				set_span2(hit_item, 'row'   , j+1)
				set_span1(item_ph , 'column', i)
				set_span1(item_ph , 'row'   , j)
				set_span2(item_ph , 'column', i+1)
				set_span2(item_ph , 'row'   , j+1)
			}

			raf(update)
		}

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

	function update_span_outline(so, bx1, by1, bx2, by2) {
		so.x = bx1
		so.y = by1
		so.w = bx2-bx1+1
		so.h = by2-by1+1
	}

	// selected item span outline: resizing the item's grid area.

	let focused_item_span = span_outline()

	function update_focused_item_span() {
		let show = e.editing && !!focused_item
		if (show)
			update_span_outline(focused_item_span, ...item_track_bounds(focused_item))
		focused_item_span.show(show)
	}

	function hit_test_edge_center(mx, my, bx1, bx2, by, side) {
		return abs((bx1 + bx2) / 2 - mx) <= 5 && abs(by - my) <= 5 && side
	}

	function hit_test_focused_item_span(mx, my) {
		if (!focused_item)
			return
		let [bx1, by1, bx2, by2] = item_track_bounds(focused_item)
		let r = e.client_rect()
		mx -= r.left
		my -= r.top
		return (
			hit_test_edge_center(mx, my, bx1, bx2, by1, 'top'   ) ||
			hit_test_edge_center(mx, my, bx1, bx2, by2, 'bottom') ||
			hit_test_edge_center(my, mx, by1, by2, bx1, 'left'  ) ||
			hit_test_edge_center(my, mx, by1, by2, bx2, 'right' )
		)
	}

	function start_resize_focused_item_span(mx, my) {
		let r = e.client_rect()
		let [bx1, by1, bx2, by2] = item_track_bounds(focused_item)
		let second = hit_area == 'right' || hit_area == 'bottom'
		drag_mx -= second ? bx2 : bx1
		drag_my -= second ? by2 : by1
		resize_focused_item_span(mx, my)
	}

	function stop_resize_focused_item_span() {
		//
	}

	function resize_focused_item_span(mx, my) {
		let horiz = hit_area == 'left' || hit_area == 'right'
		let type = horiz ? 'column' : 'row'
		let second = hit_area == 'right' || hit_area == 'bottom'
		mx = horiz ? mx - drag_mx : my - drag_my
		let i1 = span1(e.hit_item, type)
		let i2 = span2(e.hit_item, type)
		let dx = 1/0
		let closest_i
		each_track_line(type, function(i, x) {
			if (second ? i > i1 : i < i2) {
				if (abs(x - mx) < dx) {
					dx = abs(x - mx)
					closest_i = i
				}
			}
		})

		if (second)
			set_span2(hit_item, type, closest_i)
		else
			set_span1(hit_item, type, closest_i)

		raf(update)
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
		item[attr] = align
		item[horiz ? 'w' : 'h'] = align == 'stretch' ? 'auto' : null
		return align
	}

	function toggle_stretch(item, horiz, vert) {
		if (horiz && vert) {
			let stretch_x = item.align_x == 'stretch'
			let stretch_y = item.align_y == 'stretch'
			if (stretch_x != stretch_y) {
				toggle_stretch(item, !stretch_x, !stretch_y)
			} else {
				toggle_stretch(item, true, false)
				toggle_stretch(item, false, true)
			}
			return
		}
		if (horiz)
			return toggle_stretch_for(item, true)
		if (vert)
			return toggle_stretch_for(item, false)
	}

	// drag & drop controller ----------------------------------------------

	let hit_item, hit_area
	let dragging, drag_mx, drag_my

	e.on('pointerdown', function(ev) {
		if (!e.editing)
			return
		if (!hit_item) {
			if (!ev.shiftKey)
				select_item(null, true)
			return
		}
		dragging = true
		drag_mx = ev.clientX
		drag_my = ev.clientY
		this.setPointerCapture(ev.pointerId)
		select_item(hit_item, !ev.shiftKey)
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

	// keyboard bindings ------------------------------------------------------

	let editing = false
	e.property('editing',
		function() { return editing },
		function(v) {
			v = !!v
			if (editing == v)
				return
			editing = v
			e.attrval('tabindex', editing ? 0 : null)
			e.class('editing', v)
			create_lines()
			raf(update)
			if (v)
				e.focus()
		}
	)

	e.on('keydown', function(key) {
		if (!e.editing)
			return
		if (key == 'Shift' && hit_line_tip) {
			tip_set_cursor(hit_line_tip, true)
			return false
		}
	})

	e.on('keyup', function(key) {
		if (!e.editing)
			return
		if (key == 'Shift' && hit_line_tip) {
			tip_set_cursor(hit_line_tip, false)
			return false
		}
	})

	e.on('keydown', function(key, shift, ctrl) {
		if (key == 'F2') {
			e.editing = !e.editing
			return false
		}
		if (!e.editing)
			return
		if (key == 'Tab') {
			let item = e.items[mod(e.items.indexOf(focused_item) + (shift ? -1 : 1), e.items.length)]
			select_item(item, true)
			return false
		}
		if (focused_item) {
			if (key == 'Enter') { // toggle stretch
				toggle_stretch(focused_item, !shift, !ctrl)
				raf(update)
				return false
			}
			if (key == 'Delete') {
				remove_item(focused_item)
				raf(update)
				return false
			}
			if (key == 'ArrowLeft' || key == 'ArrowRight' || key == 'ArrowUp' || key == 'ArrowDown') {
				let horiz = key == 'ArrowLeft' || key == 'ArrowRight'
				let fw = key == 'ArrowRight' || key == 'ArrowDown'
				let type = horiz ? 'column' : 'row'
				if (ctrl) { // change alignment
					let attr = horiz ? 'align_x' : 'align_y'
					let align = focused_item[attr]
					if (align == 'stretch')
						align = toggle_stretch(focused_item, horiz, !horiz)
					let align_indices = {start: 0, center: 1, end: 2}
					let align_map = keys(align_indices)
					align = align_map[align_indices[align] + (fw ? 1 : -1)]
					focused_item[attr] = align
				} else { // resize span or move to diff. span
					if (shift) { // resize span
						let i1 = span1(focused_item, type)
						let i2 = span2(focused_item, type)
						let i = max(i1+1, i2 + (fw ? 1 : -1))
						set_span2(focused_item, type, i)
					} else {
						let i = max(0, span1(focused_item, type) + (fw ? 1 : -1))
						set_span1(focused_item, type, i)
						set_span2(focused_item, type, i+1)
					}
				}
				create_lines()
				raf(update)
				return false
			}
		}

	})

	// xmodule interface ------------------------------------------------------

	e.child_widgets = function() {
		return e.items.slice()
	}

	e.replace_widget = function(old_widget, new_widget) {
		let i = e.items.indexOf(old_widget)
		e.items[i] = new_widget
		old_widget.parent.replace(old_widget, new_widget)
		e.fire('widget_replaced', new_widget, old_widget)
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

