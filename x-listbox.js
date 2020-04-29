
// ---------------------------------------------------------------------------
// listbox
// ---------------------------------------------------------------------------

listbox = component('x-listbox', function(e) {

	rowset_widget(e)

	e.class('x-widget')
	e.class('x-listbox')
	e.class('x-focusable')
	e.attrval('tabindex', 0)
	e.attrval('flow', 'vertical')
	e.attr_property('flow')

	e.display_col = '0'

	e.init = function() {
		if(e.items) {
			assert(!e.rowset)
			create_rowset_for_items()
			update_rowset_from_items()
		}
		e.rowset = global_rowset(e.rowset)
		e.init_fields_array()
		e.init_rows_array()
		e.init_nav()
		e.init_fields()
	}

	e.attach = function() {
		e.init_rows()
		e.init_value()
		e.bind_rowset(true)
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_rowset(false)
		e.bind_nav(false)
	}

	// item-based rowset ------------------------------------------------------

	function create_rowset_for_items() {
		e.rowset = rowset({
			fields: [{format: e.format_item}],
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
		return typeof item == 'object' ? item.text : item
	}

	e.property('focused_item', function() {
		return e.focused_row ? e.focused_row[0] : null
	})

	// responding to rowset changes -------------------------------------------

	e.update_item = function(item, row) { // stub
		if (e.display_field)
			item.html = e.rowset.display_value(row, e.display_field)
	}

	e.init_fields = function() {
		e.display_field = e.rowset.field(e.display_col)
	}

	e.init_rows = function() {
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
	}

	e.update_cell_value = function(ri, fi) {
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
			item1.make_visible()
		}
		selected_row_index = ri
	}

	// navigation -------------------------------------------------------------

	function item_mousedown() {
		e.focus()
		let ri = this.row_index
		if (e.focus_cell(ri, null, 0, 0, {must_not_move_row: true}))
			e.fire('value_picked') // picker protocol.
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
			e.focus_cell(true, null, rows)
			return false
		}

		if (key == 'PageUp' || key == 'PageDown') {
			let item = page_item(key == 'PageDown')
			if (item)
				e.focus_cell(item.row_index, null, 0)
			return false
		}

		if (key == 'Enter') {
			if (e.focused_row)
				e.fire('value_picked') // picker protocol
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

list_dropdown = component('x-list-dropdown', function(e) {

	dropdown.construct(e)

	init = e.init
	e.init = function() {
		e.picker = listbox(update({
			items: e.items,
		}, e.listbox))
		init()
	}

})

