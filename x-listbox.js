/*

	Model-driven widget listbox widget.
	Written by Cosmin Apreutesei. Public Domain.

	Widgets:

		listbox
		list_dropdown
		enum_dropdown
		select_button
		color_dropdown
		icon_dropdown

*/

// ---------------------------------------------------------------------------
// listbox widget
// ---------------------------------------------------------------------------

function listbox_widget(e) {

	e.class('x-listbox x-stretched')

	val_widget(e, true)
	nav_widget(e)
	focusable_widget(e)
	e.class('x-focusable-items')
	stylable_widget(e)

	e.xoff()
	e.can_focus_cells = false
	e.display_col = 0
	e.xon()

	e.prop('orientation'   , {store: 'var', type: 'enum', enum_values: ['vertical', 'horizontal'], default: 'vertical', attr: true})
	e.prop('can_move_items', {store: 'var', type: 'bool', default: true})

	// embedded template: doesn't work if the listbox itself is declared in a template.
	let item_template = e.$('script[type="text/x-mustache"]')[0]
	if (item_template) {
		item_template.remove()
		item_template = item_template.html
	}

	let html_items
	if (e.at.length) {
		html_items = [...e.at]
		e.clear()
	}

	function format_item(row, val) { // stub
		if (iselem(val)) // element, dupe it.
			return val.clone()
		return div(0, val) // string or we don't know, use `item_field.format` to specify.
	}

	function create_item(row) {
		let item = e.row_display_val(row)
		if (!(iselem(item))) // plain string or text node, wrap it.
			item = div(0, item)
		item.classes = 'x-listbox-item x-item'
		item.on('pointerdown', item_pointerdown)
		return item
	}

	e.do_update_item = function(item, row) {
		e.replace(item, create_item(row))
	}

	e.prop('items', {store: 'var', private: true})

	function update_item_field() {
		let field = assign({format: (val, row) => format_item(row, val)}, e.item_field)
		if (e.rowset)
			e.rowset.fields[0] = field
	}

	e.set_items = function(items) {

		if (!items) {
			e.rowset = null
			e.reload()
			return
		}

		e.display_col = 0

		let rows = []
		for (let item of items)
			rows.push([item])

		e.rowset = {
			fields: [null],
			rows: rows,
		}

		update_item_field()

		e.reload()
	}

	e.set_item_field = update_item_field
	e.prop('item_field', {store: 'var'})

	e.child_widgets = function() {
		let widgets = []
		for (let ce of e.children)
			if (ce.iswidget)
				widgets.push(ce)
		return widgets
	}

	e.serialize = function() {
		let t = e.serialize()
		if (isobject(t) && e.items) {
			t.items = []
			for (let ce of e.child_widgets)
				t.items.push(ce.serialize())
		}
		return t
	}

	// responding to nav changes ----------------------------------------------

	/* TODO: remove this
	function rows_added(rows, ri1) {
		for (let row of rows) {
			let item = create_item(row)
			e.insert(ri1++, item)
		}
	}
	e.on('rows_added', rows_added)
	*/

	let inh_do_update = e.do_update
	e.do_update = function(opt) {

		if (opt.reload) {
			e.reload()
			opt.fields = true
		}

		if (opt.fields)
			opt.rows = true

		if (opt.rows) {
			e.clear()
			for (let row of e.rows) {
				let item = create_item(row)
				e.add(item)
			}
			opt.vals = false
			opt.state = true
		}

		if (opt.vals) {
			for (let i = 0; i < e.rows.length; i++)
				e.do_update_item(e.at[i], e.rows[i])
			opt.state = true
		}

		if (opt.val) {
			inh_do_update()
			opt.state = true
		}

		if (opt.state && e.len)
			for (let i = 0; i < e.rows.length; i++) {
				let item = e.at[i]
				item.class('focused', e.focused_row_index == i)
				item.class('selected', e.selected_rows.get(e.rows[i]))
			}

		if (opt.scroll_to_cell)
			e.scroll_to_cell(...opt.scroll_to_cell)
	}

	e.do_update_cell_state = function(ri, fi, prop, val) {
		e.do_update_item(e.at[ri], e.rows[ri])
	}

	// drag-move items --------------------------------------------------------

	e.property('axis', function() { return e.orientation == 'horizontal' ? 'x' : 'y' })

	live_move_mixin(e)

	e.set_movable_element_pos = function(i, x) {
		let item = e.at[i]
		// we use x1 and y1 instead of x and y because <img> defines x and y props.
		item[e.axis == 'x' ? 'x1' : 'y1'] = x - item._offset
	}

	e.movable_element_size = function(i) {
		let item = e.at[i]
		return item[e.axis == 'x' ? 'offsetWidth' : 'offsetHeight'] +
			num(item.css('margin-'+(e.axis == 'x' ? 'left'  : 'top'   ))) +
			num(item.css('margin-'+(e.axis == 'x' ? 'right' : 'bottom')))
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

		let down_mx = mx
		let down_my = my

		function item_pointermove(ev, mx, my) {
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
					let item1_offset = num(e.at[0].css('margin-'+(e.axis == 'x' ? 'left' : 'top')))
					e.move_element_start(move_ri1, move_n, 0, e.len, null, null, item1_offset)
					drag_mx = down_mx + e.scrollLeft - e.at[move_ri1].ox
					drag_my = down_my + e.scrollTop  - e.at[move_ri1].oy
					mx0 = mx
					my0 = my
					scroll_timer = runevery(.1, item_pointermove)
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

		function item_pointerup(ev, mx, my) {
			if (dragging) {

				clearInterval(scroll_timer)

				let over_ri = e.move_element_stop()
				let insert_ri = over_ri - (over_ri > move_ri1 ? move_n : 0)

				let move_state = e.start_move_selected_rows()
				move_state.finish(insert_ri)

				e.class('moving', false)
				for (let item of e.children) {
					item.class('moving', false)
					item.x1 = null
					item.y1 = null
				}

			} else if (!(ev.shiftKey || ev.ctrlKey)) {
				e.fire('val_picked', {input: e}) // picker protocol
			}

			// let the href do its thing on pointerup.
			if (this.href) {
				return
			}

			return false
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
			if (!shift) {
				let ri = e.first_focusable_cell(true, null, rows, 0)[0]
				let item = e.at[ri]
				if (item && item.attr('href')) {
					item.click()
					return false
				}
			}
			e.focus_cell(true, null, rows, 0, {
				input: e,
				expand_selection: shift,
			})
			return false
		}

		if (key == 'PageUp' || key == 'PageDown') {
			let item = page_item(key == 'PageDown')
			if (item) {
				if (!shift && item.attr('href')) {
					item.click()
					return false
				}
				e.focus_cell(item.index, null, 0, 0, {
					input: e,
					expand_selection: shift,
				})
				return false
			}
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

		// delete key: delete row
		if (key == 'Delete') {
			if (!e.can_remove_rows) {
				// TODO: either one should set the other
				e.set_val(null, {input: e})
				e.focus_cell(false, false, 0, 0, {input: e})
				return false
			}
			if (e.remove_selected_rows({input: e, refocus: true, toggle: true}))
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

	// picker protocol --------------------------------------------------------

	e.init_as_picker = function() {
		e.xoff()
		e.auto_focus_first_cell = false
		e.can_select_multiple = false
		e.can_move_items = false
		e.xon()
	}

	return {items: html_items, row_display_val_template: item_template}
}

component('x-listbox', 'Input', listbox_widget)

hlistbox = function(...options) {
	return listbox({orientation: 'horizontal'}, ...options)
}

// ---------------------------------------------------------------------------
// list dropdown
// ---------------------------------------------------------------------------

component('x-list-dropdown', function(e) {

	nav_dropdown_widget(e)

	e.create_picker = function(opt) {

		let lb = component.create(assign_opt(opt, {
			type: 'listbox',
			id: e.id && e.id + '.picker',
			val_col: e.val_col,
			display_col: e.display_col,
			items: e.items,
			item_field: e.item_field,
			rowset: e.rowset,
			rowset_name: e.rowset_name,
			theme: e.theme,
		}, e.listbox))

		// in the rare case that the rows in the listbox are updated while
		// the listbox is serving as the picker for the dropdown,
		// update the display value in the dropdown.
		function update(...args) {
			e.do_update_val(e.val)
		}
		lb.on('focused_row_cell_state_changed', update)
		lb.on('focused_row_state_changed', update)
		lb.on('display_vals_changed', update)

		return lb
	}

})

// ---------------------------------------------------------------------------
// enum dropdown
// ---------------------------------------------------------------------------

component('x-enum-dropdown', function(e) {

	list_dropdown.construct(e)

	e.on('bind_field', function(on) {
		if (e.picker)
			e.picker.items = on ? e.field.enum_values : null
	})

	e.val_col = 0

})

// ---------------------------------------------------------------------------
// select button
// ---------------------------------------------------------------------------

component('x-select-button', function(e) {

	listbox.construct(e)

	e.orientation = 'horizontal'
	e.can_move_items = false
	e.auto_focus_first_cell = false
	e.can_select_multiple = false

})

// ---------------------------------------------------------------------------
// colors listbox & dropdown
// ---------------------------------------------------------------------------

default_colors = ['#fff', '#ffa5a5', '#ffffc2', '#c8e7ed', '#bfcfff']

function colors_listbox(...opt) {
	return listbox({
		rowset: {
			fields: [{name: 'color', type: 'color'}],
			rows: [],
		},
		val_col: 'color',
	}, ...opt)
}

component('x-color-dropdown', function(e) {
	list_dropdown.construct(e)
	e.picker = colors_listbox()
	e.val_col = 'color'
	e.display_col = 'color'

	e.set_colors = function(t) {
		e.picker.rowset.rows = t.map(s => [s])
		e.picker.reset()
	}
	e.prop('colors', {store: 'var', default: default_colors})
	e.set_colors(default_colors)

})

// ---------------------------------------------------------------------------
// icons listbox & dropdown
// ---------------------------------------------------------------------------

default_icons = memoize(function() {
	let t = []
	for (let ss of document.styleSheets) {
		if (ss.href && ss.href.ends('/fontawesome.css')) {
			for (let rule of ss.rules) {
				let s = rule.selectorText
				if (s && s.ends('::before')) {
					let [_, cls] = s.match(/^\.([^\:]+)/)
					t.push(cls)
				}
			}
			break
		}
	}
	return t
})

function icons_listbox(...opt) {
	return listbox({
		rowset: {
			fields: [{name: 'icon'}],
			rows: [],
		},
		val_col: 'icon',
		row_display_val: function(row) {
			let s = row[0].replace(/^fa\-/, '')
			return div({class: 'x-icons-listbox-item'},
				div({class: 'x-icons-listbox-icon fa fa-'+s}), s)
		}
	}, ...opt)
}

component('x-icon-dropdown', function(e) {
	list_dropdown.construct(e)
	e.picker = icons_listbox()
	e.val_col = 'icon'
	e.display_col = 'icon'

	e.set_icons = function(t) {
		e.picker.rowset.rows = t.map(s => [s])
		e.picker.reset()
	}
	e.prop('colors', {store: 'var', default: default_icons()})
	e.set_icons(default_icons())
})
