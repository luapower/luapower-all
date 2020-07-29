
component('x-cssgrid', function(e) {

	serializable_widget(e)
	editable_widget(e)
	cssgrid_item_widget(e)

	e.align_x = 'stretch'
	e.align_y = 'stretch'
	e.classes = 'x-widget x-cssgrid'

	e.init = function() {
		let items = e.items || []
		e.items = []
		for (let item of items) {
			item = component.create(item)
			e.add_child_widget(item)
		}
	}

	e.serialize = function() {
		let t = e.serialize_fields()
		t.items = []
		for (let item of e.items)
			t.items.push(item.serialize())
		return t
	}

	// add/remove items -------------------------------------------------------

	e.child_widgets = function() {
		return e.items.slice()
	}

	e.add_child_widget = function(item) {
		e.items.push(item)
		e.add(item)
	}

	e.remove_child_widget = function(item) {
		let i = e.items.indexOf(item)
		assert(i >= 0)
		e.items.remove(i)
		item.remove()
	}

	// get/set gaps -----------------------------------------------------------

	e.prop('gap_x', {style: 'column-gap', type: 'number', default: 0, style_format: v => v+'px'})
	e.prop('gap_y', {style: 'row-gap'   , type: 'number', default: 0, style_format: v => v+'px'})

	// get/set template sizes -------------------------------------------------

	function type(axis) { return axis == 'x' ? 'column' : 'row' }

	function get_sizes_for(axis) {
		return e.style[`grid-template-${type(axis)}s`]
	}
	function set_sizes_for(axis, s) {
		e.style[`grid-template-${type(axis)}s`] = s
	}
	e.get_sizes_x = function() { return get_sizes_for('x') }
	e.get_sizes_y = function() { return get_sizes_for('y') }
	e.set_sizes_x = function(s) { set_sizes_for('x', s) }
	e.set_sizes_y = function(s) { set_sizes_for('y', s) }
	e.prop('sizes_x')
	e.prop('sizes_y')

	// edit mode --------------------------------------------------------------

	e.set_widget_editing = function(v, ...args) {
		if (!v) return
		cssgrid_widget_editing(e)
		e.set_widget_editing(true, ...args)
	}

})

// ---------------------------------------------------------------------------
// cssgrid widget editing mixin
// ---------------------------------------------------------------------------

function cssgrid_widget_editing(e) {

	e.set_widget_editing = function(v) {
		if (v)
			enter_editing()
		else
			exit_editing()
	}

	function set_item_span(e, axis, i1, i2) {
		if (i1 !== false)
			e['pos_'+axis] = i1+1
		if (i2 !== false)
			e['span_'+axis] = i2 - (i1 !== false ? i1 : e['pos_'+axis]-1)
	}

	function type(axis) { return axis == 'x' ? 'column' : 'row' }

	function track_sizes(axis) {
		return e.css(`grid-template-${type(axis)}s`).split(' ').map(num)
	}

	e.each_cssgrid_line = function(axis, f) {
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
		e.each_cssgrid_line(axis, function(i, x) {
			if (i == i1)
				x1 = x
			if (i == i2)
				x2 = x
		})
		return [x1, x2]
	}

	e.cssgrid_track_bounds = function(i1, j1, i2, j2) {
		let [x1, x2] = track_bounds_for('x', i1, i2)
		let [y1, y2] = track_bounds_for('y', j1, j2)
		return [x1, y1, x2, y2]
	}

	// get/set template sizes from/to array

	function get_sizes(axis) {
		return e['sizes_'+axis].split(' ')
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

	//

	function update_guides_for(axis) {
		if (!e.prevent_recreate_guides) {
			remove_guides_for(axis)
			create_guides_for(axis)
		}
		update_sizes_for(axis)
	}

	function update_guides() {
		update_guides_for('x')
		update_guides_for('y')
	}

	function bind(on) {
		e.on('prop_changed', prop_changed, on)
	}

	function enter_editing() {
		make_implicit_lines_explicit_for('x')
		make_implicit_lines_explicit_for('y')
		create_guides_for('x')
		create_guides_for('y')
		update_sizes()
		bind(true)
	}

	function exit_editing() {
		bind(false)
		e.add_button.hide()
		remove_guides_for('x')
		remove_guides_for('y')
	}

	function prop_changed(k, v, v0, ev) {
		if (ev.target.parent == e) {
			if (k == 'pos_x' || k == 'span_x')
				update_guides_for('x')
			else if (k == 'pos_y' || k == 'span_y')
				update_guides_for('y')
		} else if (ev.target == e) {
			if (k == 'sizes_x')
				update_sizes_for('x')
			else if (k == 'sizes_y')
				update_sizes_for('y')
		}
	}

	// add/remove grid lines --------------------------------------------------

	function remove_line(axis, i) {
		let ts = get_sizes(axis)
		ts.remove(i)
		set_sizes(axis, ts)
		for (let item of e.items) {
			let i1 = item['pos_'+axis]-1
			let i2 = item['pos_'+axis]-1 + e['span_'+axis]
			set_item_span(item, axis,
				i1 >= i && max(0, i1-1),
				i2 >  i && i2-1)
		}
	}

	function insert_line(axis, i) {
		let ts = get_sizes(axis)
		ts.insert(i, '20px')
		set_sizes(axis, ts)
		for (let item of e.items) {
			let i1 = item['pos_'+axis]-1
			let i2 = item['pos_'+axis]-1 + e['span_'+axis]
			set_item_span(item, axis,
				i1 >= i && i1+1,
				i2 >  i && i2+1)
		}
	}

	// visuals ////////////////////////////////////////////////////////////////

	// grid line guides -------------------------------------------------------

	function update_sizes_for(axis) {
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

	function other_axis(axis) { return axis == 'x' ? 'y' : 'x' }

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

	// controller /////////////////////////////////////////////////////////////

	// drag-move guide tips => change grid template sizes ---------------------

	function tip_pointerdown(ev, mx, my) {
		if (ev.ctrlKey) {
			remove_line(this.axis, this.i+1)
			return false
		}

		let s0 = track_sizes(this.axis)[this.i]
		let drag_mx =
			(this.axis == 'x' ? mx : my) -
			e.rect()[this.axis]

		// transform auto size to pixels to be able to move the line.
		let tz = get_sizes(this.axis)
		let z0 = tz[this.i]
		if (z0 == 'auto') {
			z0 = s0
			z0 = z0.toFixed(0) + 'px'
			tz[this.i] = z0
			set_sizes(this.axis, tz, true)
		}
		z0 = num(z0)

		return this.capture_pointer(ev, function(mx, my, ev) {
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
		})

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

	// show add button when hovering empty grid cells -------------------------

	e.add_button = button({classes: 'x-cssgrid-add-button', text: 'add...'})
	e.add_button.can_select_widget = false
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
		if (!e.widget_editing)
			return

		let r = e.rect()
		my -= r.y
		mx -= r.x
		let pos_x, pos_y, x1, y1, x2, y2
		e.each_cssgrid_line('x', function(i, x) {
			if (mx > x) {
				pos_x = i + 1
				x1 = x
			} else if (x2 == null)
				x2 = x
		})
		e.each_cssgrid_line('y', function(j, y) {
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

	// xmodule interface ------------------------------------------------------

	e.accepts_form_widgets = true

	e.replace_widget = function(old_widget, new_widget) {
		let i = e.items.indexOf(old_widget)
		e.items[i] = new_widget
		old_widget.parent.replace(old_widget, new_widget)
		e.fire('widget_tree_changed')
	}

	// you won't believe this shit, but page-up/down from inner contenteditables
	// bubble up on overflow:hidden containers scroll them.
	e.on('keydown', function(key) {
		if (key == 'PageUp' || key == 'PageDown')
			return false
	})

}

