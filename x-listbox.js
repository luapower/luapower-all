
// ---------------------------------------------------------------------------
// listbox
// ---------------------------------------------------------------------------

component('x-listbox', function(e) {

	rowset_widget(e)
	e.align_x = 'stretch'
	e.align_y = 'stretch'
	tabindex_widget(e)
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
		e.rowset_widget_init()
	}

	e.attach = function() {
		e.rowset_widget_attach()
	}

	e.detach = function() {
		e.rowset_widget_detach()
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
		item.set(e.row_display_val(row))
	}

	e.init_fields = function() {
		e.display_field = e.rowset.field(e.display_col)
	}

	e.init_rows = function() {
		if (!e.isConnected)
			return
		selected_row_index = null
		found_row_index = null
		e.clear()
		for (let i = 0; i < e.rows.length; i++) {
			let item = H.div({class: 'x-listbox-item x-item'})
			e.update_item(item, e.rows[i])
			e.add(item)
			item.on('pointerdown', item_pointerdown)
		}
		e.update_cell_focus(e.focused_row_index, e.focused_cell_index)
	}

	e.update_cell_val = function(ri, fi) {
		e.update_item(e.at[ri], e.rows[ri])
	}

	e.update_cell_error = function(ri, fi, err) {} // stub

	let selected_row_index
	e.update_cell_focus = function(ri, fi) {
		let item1 = e.at[ri]
		let item0 = e.at[selected_row_index]
		if (item0) {
			item0.class('focused', false)
			item0.class('selected', false)
		}
		if (item1) {
			item1.class('focused')
			item1.class('selected')
		}
		selected_row_index = ri
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

	let dragging, drag_mx, drag_my

	function item_pointerdown(ev, mx, my) {
		e.focus()
		let ri = this.index
		if (!e.focus_cell(ri, null, 0, 0, {must_not_move_row: true, input: e}))
			return false
		e.fire('val_picked', {input: e}) // picker protocol.
		return this.capture_pointer(ev, item_pointermove, item_pointerup)
	}

	function item_pointermove(mx, my, ev, down_mx, down_my) {
		if (!dragging) {
			dragging = e.can_move_items
				&& e.axis == 'x' ? abs(down_mx - mx) > 4 : abs(down_my - my) > 4
			if (dragging) {
				for (let item of e.children)
					item._offset = item[e.axis == 'x' ? 'offsetLeft' : 'offsetTop']
				e.move_element_start(this.index, e.child_count)
				drag_mx = down_mx - this.offsetLeft
				drag_my = down_my - this.offsetTop
				e.class('x-moving', true)
				this.class('x-moving', true)
			}
		} else
			e.move_element_update(e.axis == 'x' ? mx - drag_mx : my - drag_my)
	}

	function item_pointerup() {
		if (dragging) {
			let i0 = this.index
			let i1 = e.move_element_stop()

			this.remove()
			e.insert(i1, this)
			for (let item of e.children)
				item[e.axis] = null

			let row = e.rows[i0]
			e.rows.remove(i0)
			e.rows.insert(i1, row)
			e.rows_array_changed()

			selected_row_index = i1
			e.focused_row_index = i1
		}
		dragging = false
		e.class('x-moving', false)
		this.class('x-moving', false)
	}

	// key bindings -----------------------------------------------------------

	// find the next item before/after the selected item that would need
	// scrolling, if the selected item would be on top/bottom of the viewport.
	function page_item(forward) {
		if (!e.focused_row)
			return forward ? e.first : e.last
		let item = e.at[e.focused_row_index]
		let sy0 = item.offsetTop + (forward ? 0 : item.offsetHeight - e.clientHeight)
		item = forward ? item.next : item.prev
		while(item) {
			let [sx, sy] = item.make_visible_scroll_offset(0, sy0)
			if (sy != sy0)
				return item
			item = forward ? item.next : item.prev
		}
		return forward ? e.last : e.first
	}

	e.on('keydown', function(key) {
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
			e.focus_cell(true, null, rows, 0, {input: e})
			return false
		}

		if (key == 'PageUp' || key == 'PageDown') {
			let item = page_item(key == 'PageDown')
			if (item)
				e.focus_cell(item.index, null, 0, 0, {input: e})
			return false
		}

		if (key == 'Enter') {
			if (e.focused_row)
				e.fire('val_picked', {input: e}) // picker protocol
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

})
