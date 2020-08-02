
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

	e.display_col = 0

	e.init = function() {
		if(e.items) {
			assert(!e.rowset)
			create_rowset_for_items()
			update_rowset_from_items()
		}
	}

	// item-based rowset ------------------------------------------------------

	function create_rowset_for_items() {
		e.rowset = rowset({
			fields: [{format: function(v) { return e.format_item(v) } }],
			rows: [],
		})
		e.display_field = e.rowset.field(0)
	}

	function update_rowset_from_items() {
		e.rowset.rows = new Set()
		for (let item of e.items) {
			e.rowset.rows.add([item])
		}
	}

	e.format_item = function(item) {
		return (typeof item == 'string' || item instanceof Node) ? item : item.text
	}

	e.property('focused_item', function() {
		return e.focused_row ? e.focused_row[0] : null
	})

	// responding to rowset changes -------------------------------------------

	e.row_display_val = function(row) { // stub
		if (e.display_field)
			return e.rowset.display_val(row, e.display_field)
	}

	e.update_item = function(item, row) { // stub
		item.row = row
		item.set(e.row_display_val(row))
	}

	e.update = function(opt) {

		if (!e.attached)
			return

		if (opt.rows) {
			e.display_field = e.rowset.field(e.display_col)
			e.clear()
			for (let i = 0; i < e.rows.length; i++) {
				let item = H.div({class: 'x-listbox-item x-item'})
				e.add(item)
				item.on('pointerdown', item_pointerdown)
			}
		}

		if (opt.rows || opt.vals || opt.fields) {
			for (let i = 0; i < e.rows.length; i++) {
				e.update_item(e.at[i], e.rows[i])
			}
		}

		if (opt.rows || opt.focus) {
			for (let item of e.children) {
				item.class('focused', e.focused_row == item.row)
				item.class('selected', !!e.selected_rows.get(item.row))
			}
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

				e.class('moving', false)
				for (let item of e.children) {
					item.class('moving', false)
					item.x = null
					item.y = null
				}

				let over_ri = e.move_element_stop()
				let insert_ri = over_ri - (over_ri > move_ri1 ? move_n : 0)
				let moved_rows = e.rows.splice(move_ri1, move_n)
				e.move_row(moved_rows, insert_ri)
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

	e.on('keydown', function(key, shift) {
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
			e.select_all()
			return false
		}

	})

	e.scroll_to_cell = function(ri, fi) {
		let item = e.at[ri]
		item.make_visible()
	}

	e.on('keypress', function(c) {
		if (e.display_field)
			e.quicksearch(c, e.display_field)
	})

	e.property('ctrl_click_used', () => e.multiple_selection)

})

hlistbox = function(...options) {
	return listbox({orientation: 'horizontal'}, ...options)
}

// ---------------------------------------------------------------------------
// list_dropdown
// ---------------------------------------------------------------------------

component('x-list-dropdown', function(e) {

	dropdown.construct(e)

	let display_val = e.display_val

	e.display_val = function() {
		let lr = e.picker.rowset
		let lf = e.picker.val_field
		let row = lf && lr.lookup(lf, e.input_val)
		if (row)
			return e.picker.row_display_val(row)
		else
			return display_val()
	}

	init = e.init
	e.init = function() {
		e.picker = e.picker || listbox(update({
			items: e.items,
			rowset: e.lookup_rowset,
			val_col: e.lookup_col,
			display_col: e.display_col,
			auto_focus_first_cell: false,
			can_move_items: false, // can't capture mouse.
		}, e.listbox))
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
	e.multiple_selection = false

})
