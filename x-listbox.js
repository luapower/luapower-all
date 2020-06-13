
// ---------------------------------------------------------------------------
// listbox
// ---------------------------------------------------------------------------

component('x-listbox', function(e) {

	rowset_widget(e)
	e.align_x = 'stretch'
	e.align_y = 'stretch'
	tabindex_widget(e)
	e.classes = 'x-widget x-focusable x-listbox'

	e.attrval('flow', 'vertical')
	e.attr_property('flow')

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
			item.row_index = i
			item.on('mousedown', item_mousedown)
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

	// navigation -------------------------------------------------------------

	function item_mousedown() {
		e.focus()
		let ri = this.row_index
		if (e.focus_cell(ri, null, 0, 0, {must_not_move_row: true, input: e}))
			e.fire('val_picked', {input: e}) // picker protocol.
		return false
	}

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
				e.focus_cell(item.row_index, null, 0, 0, {input: e})
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
	return listbox({flow: 'horizontal'}, ...options)
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

	e.attrval('flow', 'horizontal')
	listbox.construct(e)
	e.auto_focus_first_cell = false

})
