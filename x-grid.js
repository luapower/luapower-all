
// ---------------------------------------------------------------------------
// grid
// ---------------------------------------------------------------------------

grid = component('x-grid', function(e) {

	rowset_widget(e)

	// geometry
	e.w = 400
	e.h = 400
	e.row_h = 26
	e.header_visible = true
	e.auto_w = false
	e.auto_h = false
	e.auto_cols_w = true

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

	e.header = div({class: 'x-grid-header'})
	e.cells = div({class: 'x-grid-cells'})
	e.rows_div = div({class: 'x-grid-rows'}, e.cells)
	e.rows_view = div({class: 'x-grid-rows-view'}, e.rows_div)
	e.progress_bar = div({class: 'x-grid-progress-bar'})
	e.add(e.header, e.rows_view, e.progress_bar)

	e.rows_view.on('scroll', update_view)

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
		e.init_rows()
		e.init_value()
		e.init_focused_row()
		e.bind_rowset(true)
		e.bind_nav(true)
		bind_document(true)
	}

	e.detach = function() {
		e.bind_rowset(false)
		e.bind_nav(false)
		bind_document(false)
	}

	// geometry on y ----------------------------------------------------------

	function scroll_y(sy) {
		return clamp(sy, 0, max(0, e.rows_h - e.rows_view_h))
	}

	e.scroll_to_cell = function(ri, fi) {
		if (ri == null)
			return
		let view = e.rows_view
		let th = fi != null && e.header.at[fi]
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
		e.rows_h = e.row_h * e.rows.length

		let client_h = e.clientHeight
		let border_h = e.offsetHeight - client_h
		e.header_h = e.header.offsetHeight

		if (e.auto_h)
			e.h = e.rows_h + e.header_h + border_h

		e.rows_view_h = client_h - e.header_h
		e.rows_div.h = e.rows_h
		e.rows_view.h = e.rows_view_h
		e.visible_row_count = floor(e.rows_view_h / e.row_h) + 2
		e.page_row_count = floor(e.rows_view_h / e.row_h)
		init_editor_geometry()
	}

	// ri/fi to visible cell and back -----------------------------------------

	function cell_index(ri, fi, sy) {
		if (ri == null || fi == null)
			return
		let ri0 = first_visible_row(or(sy, e.scroll_y))
		let ri1 = min(ri0 + e.visible_row_count, e.rows.length)
		if (ri >= ri0 && ri < ri1)
			return (ri - ri0) * e.fields.length + fi
	}

	function cell_address(cell) {
		let i = cell.index
		let ri0 = first_visible_row(e.scroll_y)
		let fn = e.fields.length
		let ri = ri0 + floor(i / fn)
		let fi = i % fn
		return [ri, fi]
	}

	function each_cell_of_col(fi, f, ...args) {
		f(e.header.at[fi], ...args)
		while (1) {
			let cell = e.cells.at[fi]
			if (!cell)
				break
			f(cell, ...args)
			fi += e.fields.length
		}
	}

	function each_cell_of_row(ri, sy, f, ...args) {
		let ci = cell_index(ri, 0, sy)
		if (ci == null)
			return
		for (let fi = 0; fi < e.fields.length; fi++)
			f(e.cells.at[ci+fi], fi, ...args)
	}

	// geometry on x ----------------------------------------------------------

	function set_col_w(fi, w) {
		let field = e.fields[fi]
		field.w = clamp(w, field.min_w, field.max_w)
		e.header.at[fi]._w = field.w
	}

	// when: vertical scroll bar changes visibility, field width changes (col resizing).
	function update_widths() {

		let cols_w = 0
		for (let fi = 0; fi < e.fields.length; fi++)
			cols_w += e.fields[fi].w

		if (e.auto_w) {
			let client_w = e.rows_view.clientWidth
			let border_w = e.offsetWidth - e.clientWidth
			let vscrollbar_w = e.rows_view.offsetWidth - client_w
			e.w = cols_w + border_w + vscrollbar_w
		}

		let total_free_w = 0
		let cw = cols_w
		if (e.auto_cols_w && !e.col_resizing) {
			cw = e.rows_view.clientWidth
			total_free_w = max(0, cw - cols_w)
		}
		let col_x = 0
		for (let fi = 0; fi < e.fields.length; fi++) {
			let hcell = e.header.at[fi]

			let min_col_w = e.col_resizing ? hcell._w : e.fields[fi].w
			let free_w = total_free_w * (min_col_w / cols_w)
			let col_w = floor(min_col_w + free_w)
			if (fi == e.fields.length - 1) {
				let remaining_w = cw - col_x
				if (total_free_w > 0)
					// set width exactly to prevent showing the horizontal scrollbar.
					col_w = remaining_w
				else
					// stretch last col to include leftovers from rounding.
					col_w = max(col_w, remaining_w)
			}

			hcell._x = col_x
			hcell._w = col_w

			hcell.x = col_x
			hcell.w = col_w

			let i = fi
			while (1) {
				let cell = e.cells.at[i]
				if (!cell)
					break
				cell.x = col_x
				cell.w = col_w
				i += e.fields.length
			}

			col_x += col_w
		}
		e.header.w = e.fields.length ? col_x : cw

	}

	// when: horizontal scrolling, widget width changed.
	function update_header_x(sx) {
		e.header.x = -sx
	}

	function col_resize_hit_test(mx) {
		for (let fi = 0; fi < e.fields.length; fi++) {
			let hcell = e.header.at[fi]
			let x = mx - (hcell._x + hcell._w)
			if (x >= -5 && x <= 5)
				return [fi, x]
		}
	}

	// when: moving a column.
	function update_col_x(fi, x) {
		each_cell_of_col(fi, function(hcell) {
			hcell.x = x
		})
	}

	// rendering --------------------------------------------------------------

	// when: fields changed.
	e.init_fields = function() {
		set_header_visibility()
		e.header.clear()
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let sort_icon     = H.span({class: 'fa x-grid-sort-icon'})
			let sort_icon_pri = H.span({class: 'x-grid-header-sort-icon-pri'})
			let e1 = H.td({class: 'x-grid-header-title-td'})
			e1.set(field.text || field.name)
			e1.title = e1.textContent
			let e2 = H.td({class: 'x-grid-header-sort-icon-td'}, sort_icon, sort_icon_pri)
			if (field.align == 'right')
				[e1, e2] = [e2, e1]
			e1.attr('align', 'left')
			e2.attr('align', 'right')
			let title_table =
				H.table({class: 'x-grid-header-th-table'},
					H.tr(0, e1, e2))

			let th = div({class: 'x-grid-header-th'}, title_table)

			th.sort_icon = sort_icon
			th.sort_icon_pri = sort_icon_pri

			e.header.add(th)
		}
		update_sort_icons()
	}

	function update_sort_icons() {
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let th = e.header.at[fi]
			let dir = e.order_by_dir(field)
			let pri = e.order_by_priority(field)
			th.sort_icon.class('fa-angle-up'         , false)
			th.sort_icon.class('fa-angle-double-up'  , false)
			th.sort_icon.class('fa-angle-down'       , false)
			th.sort_icon.class('fa-angle-double-down', false)
			th.sort_icon.class('fa-angle'+(pri ? '-double' : '')+'-up'  , dir == 'asc')
			th.sort_icon.class('fa-angle'+(pri ? '-double' : '')+'-down', dir == 'desc')
			th.sort_icon.parent.class('sorted', !!dir)
			th.sort_icon_pri.set(pri > 1 ? pri : '')
		}
	}

	// when: fields changed, rows viewport height changed.
	function init_cells() {
		focused_td = null
		e.cells.clear()
		let y = 0
		for (let i = 0; i < e.visible_row_count; i++) {
			for (let i = 0; i < e.fields.length; i++) {
				let field = e.fields[i]
				let cell = div({class: 'x-grid-cell x-item'})
				cell.y = y
				cell.h = e.row_h
				e.cells.add(cell)
			}
			y += e.row_h
		}
	}

	e.update_cell_value = function(cell, row, field, input_val) {
		cell.set(e.rowset.display_value(row, field))
		cell.class('null', input_val == null)
	}

	e.update_cell_error = function(cell, row, field, err) {
		let invalid = !!err
		cell.class('invalid', invalid)
		cell.attr('title', err || null)
	}

	// when: scroll_y changed.
	function update_cells() {
		let ri0 = first_visible_row(e.scroll_y)
		e.cells.y = rows_y_offset(e.scroll_y)
		for (let ri = 0; ri < e.visible_row_count; ri++) {
			let row = e.rows[ri0 + ri]
			for (let fi = 0; fi < e.fields.length; fi++) {
				let cell = e.cells.at[ri * e.fields.length + fi]
				if (row) {
					let field = e.fields[fi]
					cell.attr('align', field.align)
					cell.class('focusable', e.can_focus_cell(row, field))
					cell.class('disabled', e.is_cell_disabled(row, field))
					cell.class('new', !!row.is_new)
					cell.class('removed', !!row.removed)
					cell.class('modified', e.rowset.cell_modified(row, field))
					let input_val = e.rowset.cell_error(row, field)
					e.update_cell_value(cell, row, field, e.rowset.input_value(row, field))
					e.update_cell_error(cell, row, field, e.rowset.cell_error(row, field))
					cell.show()
				} else {
					cell.clear()
					cell.hide()
				}
			}
		}
	}

	// when: order_by changed.
	e.on('sort_order_changed', function() {
		update_sort_icons()
	})

	{
		let sy, focused_ri
		function update_focus() {
			if (sy != null) {
				each_cell_of_row(focused_ri, sy, function(cell) {
						cell.class('focused', false)
						cell.class('editing', false)
						cell.class('row-focused', false)
					}
				)
			}
			sy = e.scroll_y
			focused_ri = e.focused_row_index
			if (focused_ri != null) {
				each_cell_of_row(focused_ri, sy, function(cell, fi, focused_fi, editing) {
						let focused = !e.can_focus_cells || fi == focused_fi
						cell.class('focused', focused)
						cell.class('editing', focused && editing)
						cell.class('row-focused', true)
					}, e.focused_field_index, e.editor || false
				)
			}
		}
	}

	// when: width/height changed.
	{
		let w0, h0
		e.on('attr_changed', function() {
			let w1 = e.style.width
			let h1 = e.style.height
			if (w1 == 0 && h1 == 0)
				return // hidden
			if (h1 !== h0) {
				let vrc = e.visible_row_count
				update_heights()
				if (e.visible_row_count != vrc) {
					init_cells()
					update_widths()
					update_view()
				}
			}
			if (w1 !== w0)
				update_widths()
			w0 = w1
			h0 = h1
		})
	}

	// inline editing ---------------------------------------------------------

	// when: input created, heights changed, column width changed.
	function init_editor_geometry(editor) {
		editor = editor || e.editor
		if (!editor)
			return
		let th = e.header.at[e.focused_field_index]
		editor.x = th.offsetLeft + th.clientLeft
		editor.y = e.row_h * e.focused_row_index
		editor.w = th.clientWidth
		editor.h = e.row_h - num(e.cells.at[0].css('border-bottom-width'))
	}

	function set_header_visibility() {
		e.header.show(e.header_visible)
	}

	// when: scroll_y changed.
	function update_view() {
		let sy = e.rows_view.scrollTop
		let sx = e.rows_view.scrollLeft
		sy = scroll_y(sy)
		e.scroll_y = sy
		update_cells()
		update_focus()
		update_header_x(sx)
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
		let cell = e.cells.at[cell_index(ri, fi)]
		if (cell)
			cell.class('editing', editing)
	}

	// responding to rowset changes -------------------------------------------

	e.init_rows = function() {
		update_heights()
		init_cells()
		update_widths()
		update_view()
	}

	e.update_cell_focus = function(ri, fi) {
		update_focus()
	}

	e.update_cell_state = function(ri, fi, prop, val) {
		let cell = e.cells.at[cell_index(ri, fi)]
		if (!cell)
			return
		if (prop == 'input_value')
			e.update_cell_value(cell, e.rows[ri], e.fields[fi], val)
		else if (prop == 'cell_error')
			e.update_cell_error(cell, e.rows[ri], e.fields[fi], val)
		else if (prop == 'cell_modified')
			cell.class('modified', val)
	}

	e.update_row_state = function(ri, prop, val, ev) {
		let ci = cell_index(ri, 0)
		if (ci == null)
			return
		let cls
		if (prop == 'row_is_new')
			cls = 'new'
		else if (prop == 'row_removed')
			cls = 'removed'
		if (cls)
			each_cell_of_row(ri, null, function(cell, fi, cls, val) {
				cell.class(cls, val)
			}, cls, val)
	}

	e.update_load_progress = function(p) {
		e.progress_bar.style.width = (p * 100) + '%'
	}

	// column moving ----------------------------------------------------------

	{
		live_move_mixin(e)

		let move_px, move_fi

		function col_move_start_drag(fi, mx, my) {
			if (e.col_finishing_moving)
				return // finishing animations still running.
			e.col_moving = true
			window.grid_dragging = true
			e.class('col-moving')
			mx = mx - e.header.client_rect().left
			move_px = mx - e.header.at[fi]._x
			each_cell_of_col(fi, function(cell) {
				cell.class('col-moving', true)
				cell.style['z-index'] = 1
			})
			move_fi = fi
			e.move_element_start(fi, e.fields.length)
			return true
		}

		function col_move_document_mousemove(mx, my) {
			if (!e.col_moving)
				return
			if (e.col_finishing_moving)
				return
			let col_x = mx - e.header.client_rect().left - move_px
			e.move_element_update(col_x)
			return true
		}

		function col_move_document_mouseup() {
			if (!e.col_moving)
				return
			let over_fi = e.move_element_stop() // sets x of moved element.
			e.col_finishing_moving = true
			after(.1, function() { // delay to allow the transition on x to finish.
				e.col_moving = false
				e.col_finishing_moving = false
				e.class('col-moving', false)
				each_cell_of_col(move_fi, function(cell) {
					cell.class('col-moving', false)
					cell.style['z-index'] = null
				})
				if (over_fi != move_fi) {
					let focused_field = e.fields[e.focused_field_index]
					let field = e.fields.remove(move_fi)
					e.fields.insert(over_fi, field)
					e.focused_field_index = focused_field && e.fields.indexOf(focused_field)
					e.init_fields()
					update_widths()
					update_view()
				} else {
					update_widths()
				}
			})
			return true
		}

		// live_move_mixin protocol

		e.movable_element_size = function(fi) {
			return e.header.at[fi]._w
		}

		e.set_movable_element_pos = update_col_x

	}

	// column resizing --------------------------------------------------------

	{
		let resize_markers

		function update_resize_markers() {
			for (let fi = 0; fi < e.fields.length; fi++) {
				let marker = resize_markers.at[fi]
				marker.x = e.header.at[fi]._x + e.fields[fi].w
				marker.h = e.header_h + e.rows_view_h
			}
		}

		function create_resize_markers() {
			if (!e.auto_cols_w)
				return
			resize_markers = div({class: 'x-grid-resize-markers'})
			for (let fi = 0; fi < e.fields.length; fi++) {
				resize_markers.add(div({class: 'x-grid-resize-marker'}))
			}
			e.add(resize_markers)
			update_resize_markers()
		}

		function remove_resize_markers() {
			if (!resize_markers)
				return
			resize_markers.remove()
			resize_markers = null
		}
	}

	// column resize mouse events

	{
		let hit_fi, hit_x

		e.on('mousemove', function col_resize_mousemove(mx, my) {
			if (window.grid_dragging)
				return
			mx = mx - e.header.client_rect().left
			let t = col_resize_hit_test(mx)
			hit_fi = t && t[0]
			hit_x  = t && t[1]
			e.class('col-resize', hit_fi != null)
			return true
		})

		e.on('mouseleave', function col_resize_mouseleave() {
			if (window.grid_dragging)
				return
			hit_fi = null
			e.class('col-resize', false)
		})

		function col_resize_document_mousemove(mx, my) {
			if (!e.col_resizing)
				return
			mx = mx - e.header.client_rect().left
			let w = mx - e.header.at[hit_fi]._x - hit_x
			set_col_w(hit_fi, w)
			update_widths()
			update_resize_markers()
			init_editor_geometry()
			return true
		}

		function col_resize_document_mousedown() {
			if (hit_fi == null)
				return
			e.focus()
			e.col_resizing = true
			e.class('col-resizing')
			create_resize_markers()
			return true
		}

		function col_resize_document_mouseup() {
			if (!e.col_resizing)
				return
			e.col_resizing = false
			e.class('col-resizing', false)
			update_widths()
			remove_resize_markers()
			return true
		}
	}

	// column context menu ----------------------------------------------------

	function set_field_visibility(rowset_fi, view_fi, on) {
		let field = e.rowset.fields[rowset_fi]
		print(view_fi)
		if (on)
			if (view_fi != null)
				e.fields.insert(view_fi+1, field)
			else
				e.fields.push(field)
		else
			e.fields.remove_value(field)
		e.init_fields()
		e.init_rows()
		e.init_value()
		e.init_focused_row()
	}

	let context_menu
	function field_context_menu_popup(th, mx, my) {
		let fi = th && th.index
		if (context_menu) {
			context_menu.close()
			context_menu = null
		}
		function toggle_field(item) {
			set_field_visibility(item.field.index, fi, item.checked)
			return false
		}
		let items = []
		for (let field of e.rowset.fields) {
			items.push({
				field: field,
				text: field.name,
				checked: e.fields.indexOf(field) != -1,
				action: toggle_field,
			})
		}
		context_menu = menu({items: items})
		let r = (th || e).client_rect()
		let px = mx - r.left
		let py = my - r.top
		context_menu.popup(th, 'inner-top', null, px, py)
	}

	// mouse bindings ---------------------------------------------------------

	function find_th(e) {
		return e && (e.hasclass('x-grid-header-th') ? e : find_th(e.parent))
	}

	e.header.on('mousedown', function header_mousedown(ev) {
		if (e.hasclass('col-resize'))
			return // clicked on the resizing area.
		let th = ev.target != e.header && find_th(ev.target)
		if (!th) // didn't click on the th.
			return
		e.focus()
		e.col_dragging = true
		e.col_drag_index = th.index
		window.grid_dragging = true
		e.col_drag_mx = ev.clientX
		e.col_drag_my = ev.clientY
		return false
	})

	function col_drag_mousemove(mx, my) {
		if (!e.col_dragging)
			return
		if (abs(e.col_drag_mx - mx) < 8)
			return
		e.col_dragging = false
		col_move_start_drag(e.col_drag_index, e.col_drag_mx, e.col_drag_my)
		return true
	}

	function col_drag_mouseup() {
		if (!e.col_dragging)
			return
		e.col_dragging = false
		window.grid_dragging = false
		return true
	}

	e.header.on('mouseup', function header_mousedown(ev) {
		if (e.col_dragging)
			col_drag_mouseup()
		else if (e.col_moving)
			return
		else if (e.col_resizing)
			return
		if (e.hasclass('col-resize'))
			return // clicked on the resizing area.
		let th = find_th(ev.target)
		if (!th) // didn't click on the th.
			return
		e.focus()
		if (ev.shiftKey)
			e.clear_order()
		else
			e.toggle_order(e.fields[th.index], ev.shiftKey)
		return false
	})

	e.header.on('contextmenu', function(ev) {
		if (e.hasclass('col-resize'))
			return // clicked on the resizing area.
		e.focus()
		let th = ev.target != e.header && find_th(ev.target) || e.header
		field_context_menu_popup(th, ev.clientX, ev.clientY)
		return false
	})

	function find_cell(e) {
		return e && (e.hasclass('x-grid-cell') ? e : find_cell(e.parent))
	}

	e.cells.on('mousedown', function cell_mousedown(ev) {
		let cell = ev.target
		if (e.hasclass('col-resize'))
			return
		let had_focus = e.hasfocus
		if (!had_focus)
			e.focus()
		let [ri, fi] = cell_address(cell)
		if (e.focused_row_index == ri && e.focused_field_index == fi) {
			if (had_focus) {
				// TODO: instead of `select_all`, put the caret where the mouse is.
				e.enter_edit('select_all')
				return false
			}
		} else {
			if (e.focus_cell(ri, fi, 0, 0, {must_not_move_row: true, input: e}))
				e.fire('value_picked', {input: e}) // picker protocol.
			return false
		}
	})

	// document mouse bindings

	function document_mousedown() {
		if (window.grid_dragging)
			return // other grid is currently using the mouse.
		if (col_resize_document_mousedown()) {
			window.grid_dragging = true
			return false
		}
	}

	function document_mouseup() {
		if (col_drag_mouseup() || col_resize_document_mouseup() || col_move_document_mouseup()) {
			window.grid_dragging = false
			return false
		}
	}

	function document_mousemove(mx, my) {
		if (col_drag_mousemove(mx, my))
			return false
		if (col_resize_document_mousemove(mx, my))
			return false
		if (col_move_document_mousemove(mx, my))
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
					e.remove_focused_row({refocus: true})
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

			if (e.focus_cell(true, true, rows, 0, {editable: reenter_edit, input: e}))
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
			if (e.remove_focused_row({refocus: true}))
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

})

grid_dropdown = component('x-grid-dropdown', function(e) {

	e.class('x-grid-dropdown')
	dropdown.construct(e)

	init = e.init
	e.init = function() {
		e.picker = grid(update({
			rowset: e.lookup_rowset,
			col: e.lookup_col,
			can_edit: false,
			can_focus_cells: false,
			auto_focus_first_cell: false,
			//rowset_owner: false,
			auto_w: true,
			auto_h: true,
		}, e.grid))

		init()

	}

})
