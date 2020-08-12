
// ---------------------------------------------------------------------------
// listbox
// ---------------------------------------------------------------------------

component('x-listbox', function(e) {

	rowset_widget(e)
	focusable_widget(e)

	e.can_focus_cells = false
	e.align_x = 'stretch'
	e.align_y = 'stretch'

	e.classes = 'x-widget x-focusable x-listbox'

	e.prop('orientation', {attr: 'orientation', type: 'enum', enum_values: ['vertical', 'horizontal'], default: 'vertical'})
	e.prop('can_move_items', {store: 'var', type: 'bool', default: true})
	e.prop('item_typename', {store: 'var', default: 'richtext'})

	e.display_col = 0

	e.init = function() {
		if(e.items) {
			assert(!e.rowset)
			create_rowset_from_items()
		}
	}

	// item-based rowset ------------------------------------------------------

	function setup_item(item) {
		item.classes = 'x-listbox-item x-item'
		item.on('pointerdown', item_pointerdown)
	}

	function create_rowset_from_items() {
		function row_added(row) {
			let item = e.create_item()
			item.ctrl_click_used = true
			setup_item(item)
			row[0] = item
		}
		let rs = rowset({
			fields: [{format: e.format_item}],
			rows: [],
		})
		rs.on('row_added', row_added)
		e.display_field = rs.field(0)
		rs.rows = new Set()
		for (let item of e.items) {
			if (isobject(item) && item.typename)
				item = component.create(item)
			if (item instanceof HTMLElement)
				setup_item(item)
			rs.rows.add([item])
		}
		e.rowset = rs
	}

	e.create_item = function() {
		return component.create({typename: e.item_typename})
	}

	e.format_item = function(item) {
		return isobject(item) ? item.text : item
	}

	e.property('focused_item', function() {
		return e.focused_row ? e.focused_row[0] : null
	})

	e.child_widgets = function() {
		let widgets = []
		for (let ce of e.children)
			if (ce.typename)
				widgets.push(ce)
		return widgets
	}

	e.serialize = function() {
		let t = e.serialize_fields()
		if (e.items) {
			t.items = []
			for (let ce of e.child_widgets)
				t.items.push(ce.serialize())
		}
		return t
	}

	// responding to rowset changes -------------------------------------------

	e.row_display_val = function(row) { // stub
		if (e.display_field)
			return e.rowset.display_val(row, e.display_field)
	}

	e.update_item = function(item, row) { // stub
		if (item.typename)
			return
		item.set(e.row_display_val(row))
	}

	let inh_update = e.update
	e.update = function(opt) {
		inh_update(opt)
		if (!opt)
			return
		if (!e.attached)
			return

		if (opt.rows) {
			e.display_field = e.rowset && e.rowset.field(e.display_col)
			e.clear()
			for (let row of e.rows) {
				let item
				if (e.items && row[0] instanceof HTMLElement) {
					item = row[0]
				} else {
					item = H.div({})
					setup_item(item)
				}
				e.add(item)
			}
		}

		if (opt.rows || opt.vals || opt.fields)
			for (let i = 0; i < e.rows.length; i++)
				e.update_item(e.at[i], e.rows[i])

		if (opt.rows || opt.focus)
			for (let i = 0; i < e.rows.length; i++) {
				let item = e.at[i]
				item.class('focused', e.focused_row_index == i)
				item.class('selected', !!e.selected_rows.get(e.rows[i]))
			}

	}

	e.update_cell_state = function(ri, fi, prop, val) {
		e.update_item(e.at[ri], e.rows[ri])
	}

	// drag-move items --------------------------------------------------------

	e.property('axis', function() { return e.orientation == 'horizontal' ? 'x' : 'y' })

	live_move_mixin(e)

	e.set_movable_element_pos = function(i, x) {
		let item = e.at[i]
		item[e.axis] = x - item._offset
	}

	e.movable_element_size = function(i) {
		return e.at[i][e.axis == 'x' ? 'offsetWidth' : 'offsetHeight']
	}

	function item_pointerdown(ev, mx, my) {

		if (ev.ctrlKey && ev.shiftKey) {
			e.focus_cell(false, false)
			return // enter editing / select widget
		}

		e.focus()

		if (!e.focus_cell(this.index, null, 0, 0, {
			input: e,
			must_not_move_row: true,
			expand_selection: ev.shiftKey,
			invert_selection: ev.ctrlKey,
		}))
			return false

		e.fire('val_picked', {input: e}) // picker protocol.

		if (!e.can_move_items)
			return false

		let dragging, drag_mx, drag_my

		let ri1 = e.focused_row_index
		let ri2 = or(e.selected_row_index, ri1)

		let move_ri1 = min(ri1, ri2)
		let move_ri2 = max(ri1, ri2)
		let move_n = move_ri2 - move_ri1 + 1

		let item1 = e.at[move_ri1]
		let item2 = e.at[move_ri2]
		let horiz = e.axis == 'x'
		let move_w = horiz ? 0 : item1.offsetWidth
		let move_h = horiz ? 0 : item2.oy + item2.offsetHeight - item1.oy

		let scroll_timer, mx0, my0

		function item_pointermove(mx, my, ev, down_mx, down_my) {
			if (!dragging) {
				dragging = e.can_move_items
					&& (e.axis == 'x' ? abs(down_mx - mx) > 4 : abs(down_my - my) > 4)
				if (dragging) {
					e.class('moving')
					for (let ri = 0; ri < e.rows.length; ri++) {
						let item = e.at[ri]
						item._offset = item[e.axis == 'x' ? 'ox' : 'oy']
						item.class('moving', ri >= move_ri1 && ri <= move_ri2)
					}
					e.move_element_start(move_ri1, move_n, 0, e.child_count)
					drag_mx = down_mx + e.scrollLeft - e.at[move_ri1].ox
					drag_my = down_my + e.scrollTop  - e.at[move_ri1].oy
					mx0 = mx
					my0 = my
					scroll_timer = every(.1, item_pointermove)
				}
			} else {
				mx = or(mx, mx0)
				my = or(my, my0)
				mx0 = mx
				my0 = my
				let x = mx - drag_mx + e.scrollLeft
				let y = my - drag_my + e.scrollTop
				e.move_element_update(horiz ? x : y)
				e.scroll_to_view_rect(null, null, x, y, move_w, move_h)
			}
		}

		function item_pointerup() {
			if (dragging) {

				clearInterval(scroll_timer)

				let over_ri = e.move_element_stop()
				let insert_ri = over_ri - (over_ri > move_ri1 ? move_n : 0)

				let move_state = e.start_move_selected_rows()
				move_state.finish(insert_ri)

				e.class('moving', false)
				for (let item of e.children) {
					item.class('moving', false)
					item.x = null
					item.y = null
				}

			}
		}

		return this.capture_pointer(ev, item_pointermove, item_pointerup)
	}

	// key bindings -----------------------------------------------------------

	// find the next item before/after the selected item that would need
	// scrolling, if the selected item would be on top/bottom of the viewport.
	function page_item(forward) {
		if (!e.focused_row)
			return forward ? e.first : e.last
		let item = e.at[e.focused_row_index]
		let sy0 = item.oy + (forward ? 0 : item.offsetHeight - e.clientHeight)
		item = forward ? item.next : item.prev
		while(item) {
			let [sx, sy] = item.make_visible_scroll_offset(0, sy0)
			if (sy != sy0)
				return item
			item = forward ? item.next : item.prev
		}
		return forward ? e.last : e.first
	}

	e.on('keydown', function(key, shift, ctrl) {
		let rows
		switch (key) {
			case 'ArrowUp'   : rows = -1; break
			case 'ArrowDown' : rows =  1; break
			case 'ArrowLeft' : rows = -1; break
			case 'ArrowRight': rows =  1; break
			case 'Home'      : rows = -1/0; break
			case 'End'       : rows =  1/0; break
		}
		if (rows) {
			e.focus_cell(true, null, rows, 0, {
				input: e,
				expand_selection: shift,
			})
			return false
		}

		if (key == 'PageUp' || key == 'PageDown') {
			let item = page_item(key == 'PageDown')
			if (item)
				e.focus_cell(item.index, null, 0, 0, {
					input: e,
					expand_selection: shift,
				})
			return false
		}

		if (key == 'Enter') {
			if (e.focused_row)
				e.fire('val_picked', {input: e}) // picker protocol
			return false
		}

		if (key == 'a' && ctrl) {
			e.select_all_cells()
			return false
		}

		// insert key: insert row
		if (key == 'Insert')
			if (e.insert_row(true, true))
				return false

	})

	e.scroll_to_cell = function(ri, fi) {
		let item = e.at[ri]
		item.make_visible()
	}

	e.on('keypress', function(c) {
		if (e.display_field)
			e.quicksearch(c, e.display_field)
	})

	e.property('ctrl_click_used', () => e.can_select_multiple)

})

hlistbox = function(...options) {
	return listbox({orientation: 'horizontal'}, ...options)
}

// ---------------------------------------------------------------------------
// list_dropdown
// ---------------------------------------------------------------------------

component('x-list-dropdown', function(e) {

	dropdown.construct(e)

	e.set_lookup_rowset = function(v) { e.picker.rowset = v }
	e.set_lookup_col    = function(v) {  }
	e.set_display_col   = function(v) { e.picker.display_col = v }

	e.prop('lookup_rowset'     , {store: 'var', private: true})
	e.prop('lookup_rowset_name', {store: 'var', bind: 'lookup_rowset', resolve: global_rowset})
	e.prop('lookup_col'        , {store: 'var', noinit: true})
	e.prop('display_col'       , {store: 'var', noinit: true})

	let inh_display_val = e.display_val
	e.display_val = function() {
		let lf = e.lookup_field
		let row = lf && e.lookup_rowset.lookup(lf, e.input_val)
		if (row)
			return e.picker.row_display_val(row)
		else
			return inh_display_val()
	}

	e.on('prop_changed', function(k, v) {
		if (!e.picker) return
		if (k == 'nav') e.picker.nav = v
		if (k == 'col') e.picker.col = v
	})

	e.set_lookup_rowset = function(lr1, lr0) {
		bind_lookup_rowset(lr0, false)
		if (e.attached)
			bind_lookup_rowset(lr1, true)
		lookup_rowset_changed()
	}

	function lookup_rowset_changed() {
		if (e.items) {
			//e.lookup_rowset = e.picker.rowset
		} else {
			let lr = e.attached && e.lookup_rowset
			e.lookup_field  = lr && lr.field(e.lookup_col)
			e.display_field = lr && lr.field(e.display_col || lr.name_col)
			e.picker.rowset = lr
		}
		lookup_values_changed()
	}

	function lookup_values_changed() {
		e.update()
	}

	function bind_lookup_rowset(lr, on) {
		if (!lr) return
		lr.on('loaded'           , lookup_rowset_changed, on)
		lr.on('row_added'        , lookup_values_changed, on)
		lr.on('row_removed'      , lookup_values_changed, on)
		lr.on('input_val_changed', lookup_values_changed, on)
	}

	e.on('attach', function() {
		lookup_rowset_changed()
		bind_lookup_rowset(e.lookup_rowset, true)
	})

	e.on('detach', function() {
		bind_lookup_rowset(e.lookup_rowset, false)
		lookup_rowset_changed()
	})

	init = e.init
	e.init = function() {

		if (e.items) {
			e.lookup_col = 0
			e.display_col = 0
		}

		e.picker = e.picker || listbox(update({
			items: e.items,
			rowset: e.lookup_rowset,
			display_col: e.display_col,
			nav: e.nav,
			col: e.col,
			val_col: e.lookup_col,
		}, e.listbox))

		if (e.items)
			e.lookup_rowset = e.picker.rowset

		e.picker.auto_focus_first_cell = false
		e.picker.can_move_items = false // can't capture mouse.
		e.picker.can_select_multiple = false

		e.on('opened', function() {
			e.picker.scroll(0, 0) // because toggling `display: none` screws the scrolling.
		})

		init()
	}

})

// ---------------------------------------------------------------------------
// select_button
// ---------------------------------------------------------------------------

component('x-select-button', function(e) {

	e.classes = 'x-select-button'
	listbox.construct(e)
	e.orientation = 'horizontal'
	e.can_move_items = false
	e.auto_focus_first_cell = false
	e.can_select_multiple = false

})
