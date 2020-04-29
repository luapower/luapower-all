
// ---------------------------------------------------------------------------
// grid
// ---------------------------------------------------------------------------

grid = component('x-grid', function(e) {

	rowset_widget(e)

	// geometry
	e.w = 400
	e.h = 400
	e.row_h = 26
	e.row_border_w = 1
	e.row_border_h = 1
	e.min_col_w = 20

	// keyboard behavior
	e.tab_navigation = false    // disabled as it prevents jumping out of the grid.
	e.auto_advance = 'next_row' // advance on enter = false|'next_row'|'next_cell'
	e.auto_jump_cells = true    // jump to next/prev cell on caret limits
	e.quick_edit = false        // quick edit (vs. quick-search) when pressing keys
	e.keep_editing = true       // re-enter edit mode after navigating

	e.class('x-widget')
	e.class('x-grid')
	e.class('x-focusable')
	e.attrval('tabindex', 0)

	e.progress_bar = H.div({class: 'x-grid-progress-bar'})
	e.header_tr = H.tr()
	e.header_table = H.table({class: 'x-grid-header-table'}, e.header_tr, e.progress_bar)
	e.rows_table = H.table({class: 'x-grid-rows-table'})
	e.rows_div = H.div({class: 'x-grid-rows-div'}, e.rows_table)
	e.rows_view_div = H.div({class: 'x-grid-rows-view-div'}, e.rows_div)
	e.add(e.header_table, e.rows_view_div)

	e.rows_view_div.on('scroll', update_view)

	e.init = function() {
		e.rowset = global_rowset(e.rowset, {param_nav: e.param_nav})
		e.init_fields_array()
		e.init_rows_array()
		e.init_nav()
		e.init_fields()
	}

	function bind_document(on) {
		document.on('mousedown', document_mousedown, on)
		document.on('mouseup'  , document_mouseup  , on)
		document.on('mousemove', document_mousemove, on)
	}

	e.attach = function() {
		set_header_visibility()
		set_picker_options()
		e.init_rows()
		e.init_value()
		e.bind_rowset(true)
		e.bind_nav(true)
		bind_document(true)
	}

	e.detach = function() {
		e.bind_rowset(false)
		e.bind_nav(false)
		bind_document(false)
	}

	// rendering / geometry ---------------------------------------------------

	function scroll_y(sy) {
		return clamp(sy, 0, max(0, e.rows_h - e.rows_view_h))
	}

	e.scroll_to_cell = function(ri, fi) {
		if (ri == null)
			return
		let view = e.rows_view_div
		let th = fi != null && e.header_tr.at[fi]
		let h = e.row_h
		let y = h * ri
		let x = th ? th.offsetLeft  : 0
		let w = th ? th.clientWidth : 0
		view.scroll_to_view_rect(null, null, x, y, w, h)
	}

	function first_visible_row(sy) {
		return floor(sy / e.row_h)
	}

	function rows_y_offset(sy) {
		return floor(sy - sy % e.row_h)
	}

	// when: row count or height changed, rows viewport height changed, header height changed.
	function update_heights() {
		e.rows_h = e.row_h * e.rows.length - floor(e.row_border_h / 2)
		if (e.picker_h != null && e.picker_max_h != null) {
			e.h = 0 // compute e.offsetHeight with 0 clientHeight. relayouting...
			e.h = max(e.picker_h, min(e.rows_h, e.picker_max_h)) + e.offsetHeight
		}
		e.rows_view_h = e.clientHeight - e.header_table.clientHeight
		e.rows_div.h = e.rows_h
		e.rows_view_div.h = e.rows_view_h
		e.visible_row_count = floor(e.rows_view_h / e.row_h) + 2
		e.page_row_count = floor(e.rows_view_h / e.row_h)
		init_editor_geometry()
	}

	function tr_at(ri) {
		if (ri == null)
			return
		let sy = e.scroll_y
		let i0 = first_visible_row(sy)
		let i1 = i0 + e.visible_row_count
		return e.rows_table.at[ri - i0]
	}

	function td_at(tr, fi) {
		return tr && fi != null ? tr.at[fi] : null
	}

	// rendering --------------------------------------------------------------

	function field_w(field, w) {
		return max(e.min_col_w, clamp(or(w, field.w), field.min_w, field.max_w))
	}

	// when: fields changed.
	e.init_fields = function() {
		set_header_visibility()
		e.header_tr.clear()
		for (let field of e.fields) {
			let sort_icon     = H.span({class: 'fa x-grid-sort-icon'})
			let sort_icon_pri = H.span({class: 'x-grid-header-sort-icon-pri'})
			let e1 = H.td({
					class: 'x-grid-header-title-td',
					title: field.text || field.name
				}, H(field.text) || field.name)
			let e2 = H.td({class: 'x-grid-header-sort-icon-td'}, sort_icon, sort_icon_pri)
			if (field.align == 'right')
				[e1, e2] = [e2, e1]
			e1.attr('align', 'left')
			e2.attr('align', 'right')
			let title_table =
				H.table({class: 'x-grid-header-th-table'},
					H.tr(0, e1, e2))

			let th = H.th({class: 'x-grid-header-th'}, title_table)

			th.field = field
			th.sort_icon = sort_icon
			th.sort_icon_pri = sort_icon_pri

			th.w = field_w(field)
			th.style['border-right-width' ] = e.row_border_w + 'px'

			e.header_tr.add(th)
		}
	}

	// when: fields changed, rows viewport height changed.
	function init_rows_table() {
		focused_tr = null
		focused_td = null
		e.rows_table.clear()
		for (let i = 0; i < e.visible_row_count; i++) {
			let tr = H.tr({class: 'x-grid-tr'})
			for (let i = 0; i < e.fields.length; i++) {
				let th = e.header_tr.at[i]
				let field = e.fields[i]
				let td = H.td({class: 'x-grid-td'})
				td.w = field_w(field)
				td.h = e.row_h
				td.style['border-right-width' ] = e.row_border_w + 'px'
				td.style['border-bottom-width'] = e.row_border_h + 'px'
				if (field.align)
					td.attr('align', field.align)
				tr.add(td)
			}
			e.rows_table.add(tr)
		}
	}

	// when: widget height changed.
	let cw, ch
	e.on('attr_changed', function() {
		if (e.clientWidth === cw && e.clientHeight === ch)
			return
		if (e.clientHeight !== ch) {
			let vrc = e.visible_row_count
			update_heights()
			if (e.visible_row_count != vrc) {
				init_rows_table()
				update_view()
			}
		}
		cw = e.clientWidth
		ch = e.clientHeight
	})

	e.update_td_value = function(td, row, field, input_val) {
		td.html = e.rowset.display_value(row, field)
		td.class('null', input_val == null)
	}

	e.update_td_error = function(td, row, field, err) {
		let invalid = !!err
		td.class('invalid', invalid)
		td.attr('title', err || null)
	}

	// when: scroll_y changed.
	function update_row(tr, ri) {
		let row = e.rows[ri]
		tr.row = row
		tr.row_index = ri
		if (row) {
			tr.class('x-item', e.can_focus_cell(row))
			tr.class('new'     , !!row.is_new)
			tr.class('modified', !!row.modified)
			tr.class('removed' , !!row.removed)
		}
		for (let fi = 0; fi < e.fields.length; fi++) {
			let td = tr.at[fi]
			if (row) {
				let field = e.fields[fi]
				td.field = field
				td.field_index = fi
				td.class('x-item', e.can_focus_cell(row, field))
				td.class('disabled', e.is_cell_disabled(row, field))
				let input_val = e.rowset.cell_error(row, field)
				e.update_td_value(td, row, field, e.rowset.input_value(row, field))
				e.update_td_error(td, row, field, e.rowset.cell_error(row, field))
				td.class('modified', e.rowset.cell_modified(row, field))
				td.show()
			} else {
				td.clear()
				td.hide()
			}
		}
	}
	function update_rows() {
		let sy = e.scroll_y
		let i0 = first_visible_row(sy)
		e.rows_table.y = rows_y_offset(sy)
		let n = e.visible_row_count
		for (let i = 0; i < n; i++) {
			let tr = e.rows_table.at[i]
			update_row(tr, i0 + i)
		}
	}

	// when: order_by changed.
	e.on('sort_order_changed', function() {
		for (let th of e.header_tr.children) {
			let dir = e.order_by_dir(th.field)
			let pri = e.order_by_priority(th.field)
			th.sort_icon.class('fa-sort'             , false)
			th.sort_icon.class('fa-angle-up'         , false)
			th.sort_icon.class('fa-angle-double-up'  , false)
			th.sort_icon.class('fa-angle-down'       , false)
			th.sort_icon.class('fa-angle-double-down', false)
			th.sort_icon.class('fa-angle'+(pri ? '-double' : '')+'-up'  , dir == 'asc')
			th.sort_icon.class('fa-angle'+(pri ? '-double' : '')+'-down', dir == 'desc')
			th.sort_icon_pri.html = pri > 1 ? pri : ''
		}
	})

	let focused_tr, focused_td
	function update_focus() {
		if (focused_tr) { focused_tr.class('focused', false); focused_tr.class('editing', false); }
		if (focused_td) { focused_td.class('focused', false); focused_td.class('editing', false); }
		focused_tr = tr_at(e.focused_row_index)
		focused_td = td_at(focused_tr, e.focused_field_index)
		if (focused_tr) { focused_tr.class('focused'); focused_tr.class('editing', e.editor || false); }
		if (focused_td) { focused_td.class('focused'); focused_td.class('editing', e.editor || false); }
	}

	// when: input created, heights changed, column width changed.
	function init_editor_geometry(editor) {
		editor = editor || e.editor
		if (!editor)
			return
		let th = e.header_tr.at[e.focused_field_index]
		let fix = floor(e.row_border_h / 2 + (window.chrome ? .5 : 0))
		editor.x = th.offsetLeft + th.clientLeft
		editor.y = e.row_h * e.focused_row_index + fix
		editor.w = th.clientWidth
		editor.h = e.row_h - e.row_border_h
		editor.style['padding-bottom'] = fix + 'px'
	}

	// when: col resizing.
	function update_col_width(td_index, w) {
		for (let tr of e.rows_table.children) {
			let td = tr.at[td_index]
			td.w = w
		}
	}

	// when: horizontal scrolling, widget width changed.
	function update_header_x(sx) {
		e.header_table.x = -sx
	}

	function set_header_visibility() {
		if (e.header_visible != false && !e.hasclass('picker'))
			e.header_table.show()
		else
			e.header_table.hide()
	}

	// when: scroll_y changed.
	function update_view() {
		let sy = e.rows_view_div.scrollTop
		let sx = e.rows_view_div.scrollLeft
		sy = scroll_y(sy)
		e.scroll_y = sy
		update_rows()
		update_focus()
		update_header_x(sx)
	}

	// when: attaching as picker.
	function set_picker_options() {
		if (!e.hasclass('picker'))
			return
		e.can_edit        = false
		e.can_focus_cells = false
		e.picker_h     = or(e.picker_h    , 0)
		e.picker_max_h = or(e.picker_max_h, 200)
	}

	let create_editor = e.create_editor
	e.create_editor = function(field, ...editor_options) {
		let editor = create_editor(field, {inner_label: false}, ...editor_options)
		if (!editor)
			return
		editor.class('grid-editor')
		init_editor_geometry(editor)
		e.rows_div.add(editor)
		return editor
	}

	e.update_cell_editing = function(ri, fi, editing) {
		let td = td_at(tr_at(ri), fi)
		if (td)
			td.class('editing', editing)
	}

	// responding to rowset changes -------------------------------------------

	e.init_rows = function() {
		update_heights()
		init_rows_table()
		update_view()
	}

	e.update_cell_focus = function(ri, fi) {
		update_focus()
	}

	e.update_cell_state = function(ri, fi, prop, val) {
		let td = td_at(tr_at(ri), fi)
		if (!td)
			return
		if (prop == 'input_value')
			e.update_td_value(td, e.rows[ri], e.fields[fi], val)
		else if (prop == 'cell_error')
			e.update_td_error(td, e.rows[ri], e.fields[fi], val)
		else if (prop == 'cell_modified')
			td.class('modified', val)
	}

	e.update_row_state = function(ri, prop, val, ev) {
		let tr = tr_at(ri)
		if (!tr)
			return
		if (prop == 'row_is_new')
			tr.class('new', val)
		else if (prop == 'row_modified')
			tr.class('modified', val)
		else if (prop == 'row_removed')
			tr.class('removed', val)
	}

	e.update_load_progress = function(p) {
		e.progress_bar.style.width = (p * 100) + '%'
	}

	// mouse bindings ---------------------------------------------------------

	function find_th(e) {
		return e && (e.field ? e : find_th(e.parent))
	}

	e.header_table.on('mousedown', function header_cell_mousedown(ev) {
		let th = find_th(ev.target)
		if (!th) // didn't click on the th.
			return
		if (e.hasclass('col-resize'))
			return
		e.focus()
		e.toggle_order(th.field, ev.shiftKey)
		return false
	})

	e.header_table.on('rightmousedown', function header_cell_rightmousedown(ev) {
		let th = find_th(ev.target)
		if (!th) // didn't click on the th.
			return
		if (e.hasclass('col-resize'))
			return
		e.focus()
		if (ev.shiftKey) {
			field_context_menu_popup(th, th.field)
			return false
		}
		e.clear_order()
		return false
	})

	e.header_table.on('contextmenu', function() { return false })

	function find_td(e) {
		return e && (e.field_index ? e : find_td(e.parent))
	}

	e.rows_table.on('mousedown', function cell_mousedown(ev) {
		let td = ev.target
		if (e.hasclass('col-resize'))
			return
		let had_focus = e.hasfocus
		if (!had_focus)
			e.focus()
		let ri = td.parent.row_index
		let fi = td.field_index
		if (e.focused_row_index == ri && e.focused_field_index == fi) {
			if (had_focus) {
				// TODO: what we want here is `e.enter_edit()` without `return false`
				// to let mousedown click-through to the input box and focus the input
				// and move the caret under the mouse all by itself.
				// Unfortunately, this only works in Chrome no luck with Firefox.
				e.enter_edit('select_all')
				return false
			}
		} else {
			if (e.focus_cell(ri, fi, 0, 0, {must_not_move_row: true, input: e}))
				e.fire('value_picked') // picker protocol.
			return false
		}
	})

	// make columns resizeable ------------------------------------------------

	let hit_th, hit_x

	function document_mousedown() {
		if (window.grid_col_resizing || !hit_th)
			return
		e.focus()
		window.grid_col_resizing = true
		e.class('col-resizing')
	}

	function document_mouseup() {
		window.grid_col_resizing = false
		e.class('col-resizing', false)
	}

	e.on('mousemove', function(mx, my, ev) {
		if (window.grid_col_resizing)
			return
		// hit-test for column resizing.
		hit_th = null
		if (mx <= e.rows_view_div.offsetLeft + e.rows_view_div.clientWidth) {
			// ^^ not over vertical scrollbar.
			for (let th of e.header_tr.children) {
				hit_x = mx - (e.header_table.offsetLeft + th.offsetLeft + th.offsetWidth)
				if (hit_x >= -5 && hit_x <= 5) {
					hit_th = th
					break
				}
			}
		}
		e.class('col-resize', hit_th != null)
	})

	function document_mousemove(mx, my) {
		if (!e.hasclass('col-resizing'))
			return
		let field = e.fields[hit_th.index]
		let w = mx - (e.header_table.offsetLeft + hit_th.offsetLeft + hit_x)
		field.w = field_w(field, w)
		hit_th.w = field.w
		update_col_width(hit_th.index, field.w)
		init_editor_geometry()
		return false
	}

	// keyboard bindings ------------------------------------------------------

	e.on('keydown', function(key, shift) {

		// Arrows: horizontal navigation.
		if (key == 'ArrowLeft' || key == 'ArrowRight') {

			let cols = key == 'ArrowLeft' ? -1 : 1

			let reenter_edit = e.editor && e.keep_editing

			let move = !e.editor
				|| (e.auto_jump_cells && !shift
					&& (!e.editor.editor_state
						|| e.editor.editor_state(cols < 0 ? 'left' : 'right')))

			if (move && e.focus_next_cell(cols, {editable: reenter_edit, input: e})) {
				if (reenter_edit)
					e.enter_edit(cols > 0 ? 'left' : 'right')
				return false
			}
		}

		// Tab/Shift+Tab cell navigation.
		if (key == 'Tab' && e.tab_navigation) {

			let cols = shift ? -1 : 1

			let reenter_edit = e.editor && e.keep_editing

			if (e.focus_next_cell(cols, {editable: reenter_edit, auto_advance_row: true, input: e}))
				if (reenter_edit)
					e.enter_edit(cols > 0 ? 'left' : 'right')

			return false
		}

		// insert with the arrow down key on the last focusable row.
		if (key == 'ArrowDown') {
			if (e.is_last_row_focused())
				if (e.insert_row(null, true))
					return false
		}

		// remove last row with the arrow up key if not edited.
		if (key == 'ArrowUp') {
			if (e.is_last_row_focused()) {
				let row = e.focused_row
				if (row.is_new && !row.modified) {
					e.remove_focused_row(true)
					return false
				}
			}
		}

		// vertical navigation.
		let rows
		switch (key) {
			case 'ArrowUp'   : rows = -1; break
			case 'ArrowDown' : rows =  1; break
			case 'PageUp'    : rows = -e.page_row_count; break
			case 'PageDown'  : rows =  e.page_row_count; break
			case 'Home'      : rows = -1/0; break
			case 'End'       : rows =  1/0; break
		}
		if (rows) {
			let reenter_edit = e.editor && e.keep_editing
			let editor_state = e.editor
				&& e.editor.editor_state && e.editor.editor_state()

			if (e.focus_cell(true, true, rows, 0, {input: e}))
				if (reenter_edit)
					e.enter_edit(editor_state)

			return false
		}

		// F2: enter edit mode
		if (!e.editor && key == 'F2') {
			e.enter_edit('select_all')
			return false
		}

		// Enter: toggle edit mode, and navigate on exit
		if (key == 'Enter') {
			if (e.hasclass('picker')) {
				e.fire('value_picked')
			} else if (!e.editor) {
				e.enter_edit('select_all')
			} else if (e.exit_edit()) {
				if (e.auto_advance == 'next_row') {
					if (e.focus_cell(true, true, 1, 0, {input: e}))
						if (e.keep_editing)
							e.enter_edit('select_all')
				} else if (e.auto_advance == 'next_cell')
					if (e.focus_next_cell(shift ? -1 : 1, {editable: e.keep_editing, input: e}))
						if (e.keep_editing)
							e.enter_edit('select_all')
			}
			return false
		}

		// Esc: revert cell edits or row edits.
		if (key == 'Escape') {
			if (e.hasclass('picker'))
				return
			e.exit_edit()
			e.focus()
			return false
		}

		// insert key: insert row
		if (key == 'Insert') {
			e.insert_row(true, true)
			return false
		}

		// delete key: delete active row
		if (!e.editor && key == 'Delete') {
			if (e.remove_focused_row(true))
				return false
		}

	})

	// printable characters: enter quick edit mode.
	e.on('keypress', function(c) {
		if (e.quick_edit) {
			if (!e.editor && e.focused_row && e.focused_field) {
				e.enter_edit('select_all')
				let v = e.focused_field.from_text(c)
				e.rowset.set_value(e.focused_row, e.focused_field, v)
				return false
			}
		} else if (!e.editor)
			e.quicksearch(c, e.focused_field)
	})

	// columns context menu ---------------------------------------------------

	function field_context_menu_popup(th, field) {
		if (th.menu)
			th.menu.close()
		function toggle_field(item) {
			return false
		}
		let items = []
		for (let field of e.fields) {
			items.push({field: field, text: field.name, checked: true, click: toggle_field})
		}
		th.menu = menu({items: items})
		th.menu.popup(th)
	}

})

grid_dropdown = component('x-grid-dropdown', function(e) {

	dropdown.construct(e)

	init = e.init
	e.init = function() {
		e.picker = grid(update({
			col: e.pick_col || '0',
		}, e.grid))
		init()
	}

})
