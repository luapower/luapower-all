
// ---------------------------------------------------------------------------
// grid
// ---------------------------------------------------------------------------

grid = component('x-grid', function(e) {

	rowset_widget(e)

	// geometry
	e.w = 400
	e.h = 400
	e.row_h = 26
	e.auto_w = false
	e.auto_h = false
	e.auto_cols_w = true

	// keyboard behavior
	e.tab_navigation = false    // disabled as it prevents jumping out of the grid.
	e.auto_advance = 'next_row' // advance on enter = false|'next_row'|'next_cell'
	e.auto_jump_cells = true    // jump to next/prev cell on caret limits
	e.quick_edit = false        // quick edit (vs. quick-search) when pressing a key
	e.keep_editing = true       // re-enter edit mode after navigating

	e.enable_context_menu = true
	e.can_change_header_visibility = false
	e.can_change_filters_visibility = true

	e.class('x-widget')
	e.class('x-grid')
	e.class('x-focusable')
	e.attrval('tabindex', 0)

	e.header = div({class: 'x-grid-header'})
	e.cells = div({class: 'x-grid-cells'})
	e.rows_div = div({class: 'x-grid-rows'}, e.cells)
	e.rows_view = div({class: 'x-grid-rows-view'}, e.rows_div)
	e.progress_bar = div({class: 'x-grid-progress-bar'})
	e.add(e.header, e.progress_bar, e.rows_view)

	e.rows_view.on('scroll', update_view)

	e.init = function() {
		e.unbind_filter_rowsets()
		e.rowset = global_rowset(e.rowset, {param_nav: e.param_nav})
		e.init_fields_array()
		e.init_rows_array()
		e.init_nav()
		e.init_fields()
		e.sort()
	}

	function bind_document(on) {
		document.on('mousedown', document_mousedown, on)
		document.on('mouseup'  , document_mouseup  , on)
		document.on('mousemove', document_mousemove, on)
	}

	e.attach = function() {
		e.init_rows()
		e.init_value()
		e.init_focused_cell()
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
		let hcell = fi != null && e.header.at[fi]
		let h = e.row_h
		let y = h * ri
		let x = hcell ? hcell.offsetLeft  : 0
		let w = hcell ? hcell.clientWidth : 0
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

		if (e.editor)
			update_editor_height(e.editor, e.focused_field_index)

		for (let fi = 0; fi < e.fields.length; fi++) {
			let hcell = e.header.at[fi]
			let fd = hcell.filter_dropdown
			if (fd)
				update_filter_height(fd, fi)
		}

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

			if (hcell.filter_dropdown)
				update_filter_width(hcell.filter_dropdown, fi)

			col_x += col_w
		}
		e.header.w = e.fields.length ? col_x : cw

		if (e.editor)
			update_editor_width(e.editor, e.focused_field_index)

	}

	// when: horizontal scrolling, widget width changed.
	function update_header_x(sx) {
		e.header.x = -sx
	}

	function col_resize_hit_test(mx, my) {
		//TODO: if (my
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
		e.header.clear()
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let sort_icon     = H.span({class: 'fa x-grid-sort-icon'})
			let sort_icon_pri = H.span({class: 'x-grid-header-sort-icon-pri'})
			let e1 = H.td({class: 'x-grid-header-title-td'})
			e1.set(field.text)
			e1.title = e1.textContent
			let e2 = H.td({class: 'x-grid-header-sort-icon-td'}, sort_icon, sort_icon_pri)
			if (field.align == 'right')
				[e1, e2] = [e2, e1]
			e1.attr('align', 'left')
			e2.attr('align', 'right')
			let title_table =
				H.table({class: 'x-grid-header-cell-table'},
					H.tr(0, e1, e2))

			let hcell = div({class: 'x-grid-header-cell'}, title_table)

			hcell.sort_icon = sort_icon
			hcell.sort_icon_pri = sort_icon_pri

			sort_icon.on('click', sort_icon_click)

			if (e.filters_visible && field.filter_by) {
				let rs = e.filter_rowset(field)
				let dd = grid_dropdown({
					lookup_rowset : rs,
					lookup_col    : 1,
					classes       : 'x-grid-filter-dropdown',
					mode          : 'fixed',
					grid: {
						row_h: 22,
						classes: 'x-grid-filter-dropdown-grid',
					},
				})

				let f0 = rs.field(0)
				let f1 = rs.field(1)

				dd.display_value = function() {
					if (!rs.filtered_count)
						return () => div({class: 'x-item disabled'}, S('all', 'all'))
					else
						return () => span({}, div({class: 'x-grid-filter fa fa-filter'}), rs.filtered_count+'')
				}

				dd.on('opened', function() {
					if (!rs.is_loaded) {
						rs.load()
						rs.is_loaded = true
					}
				})

				dd.picker.pick_value = function() {
					let checked = !rs.value(this.focused_row, f0)
					rs.set_value(this.focused_row, f0, checked)
					rs.filtered_count = (rs.filtered_count || 0) + (checked ? -1 : 1)
					dd.update_value()
					e.init_rows_array()
					e.init_rows()
					e.sort()
				}

				dd.picker.on('keydown', function(key) {
					if (key == ' ')
						this.pick_value()
				})

				hcell.filter_dropdown = dd
				hcell.add(dd)
			}

			e.header.add(hcell)
		}
		update_sort_icons()
	}

	function update_sort_icons() {
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let hcell = e.header.at[fi]
			let dir = e.order_by_dir(field)
			let pri = e.order_by_priority(field)
			hcell.sort_icon.class('fa-angle-up'         , false)
			hcell.sort_icon.class('fa-angle-double-up'  , false)
			hcell.sort_icon.class('fa-angle-down'       , false)
			hcell.sort_icon.class('fa-angle-double-down', false)
			hcell.sort_icon.class('fa-angle'+(pri ? '-double' : '')+'-up'  , dir == 'asc')
			hcell.sort_icon.class('fa-angle'+(pri ? '-double' : '')+'-down', dir == 'desc')
			hcell.sort_icon.parent.class('sorted', !!dir)
			hcell.sort_icon_pri.set(pri > 1 ? pri : '')
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

	let header_visible = true
	e.property('header_visible',
		function() {
			return header_visible
		},
		function(v) {
			header_visible = !!v
			e.header.show(!!v)
			e.init_rows()
		}
	)

	let filters_visible = false
	e.property('filters_visible',
		function() {
			return filters_visible
		},
		function(v) {
			filters_visible = !!v
			e.header.class('with-filters', !!v)
			e.init_fields()
			e.init_rows()
		}
	)

	// inline editing ---------------------------------------------------------

	// when: input created, heights changed.
	function update_editor_height(editor, fi) {
		editor.y = e.row_h * e.focused_row_index
		editor.h = e.row_h - num(e.cells.at[0].css('border-bottom-width'))
	}

	// when: input created, column width changed.
	function update_editor_width(editor, fi) {
		let hcell = e.header.at[fi]
		editor.x = hcell.offsetLeft + hcell.clientLeft
		editor.w = hcell.clientWidth
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
		update_editor_height(editor, e.focused_field_index)
		update_editor_width(editor, e.focused_field_index)
		e.rows_div.add(editor)
		return editor
	}

	e.update_cell_editing = function(ri, fi, editing) {
		let cell = e.cells.at[cell_index(ri, fi)]
		if (cell)
			cell.class('editing', editing)
	}

	// filter dropdowns -------------------------------------------------------

	// when: fields changed, row height changes.
	function update_filter_height(fd, fi) {
		let hcell = e.header.at[fi]
		//fd.y = e.header.clientHeight - e.row_h
		//fd.h = e.row_h
	}

	// when: fields changed, column width changed.
	function update_filter_width(fd, fi) {
		let hcell = e.header.at[fi]
		fd.w = hcell.clientWidth
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

	e.update_loading = function(on) {
		if (on)
			load_overlay(true)
	}

	e.update_load_progress = function(p) {
		e.progress_bar.w = (lerp(p, 0, 1, .2, 1) * 100) + '%'
	}

	{
	let oe
	function load_overlay(on, cls, text, cancel_text, detail) {
		if (oe) {
			oe.remove()
			oe = null
		}
		e.disabled = on
		e.class('disabled', e.disabled)
		if (!on)
			return
		oe = overlay({class: 'x-grid-loading-overlay'})
		oe.content.class('x-grid-loading-overlay-message')
		if (cls)
			oe.class(cls)
		let focus_e
		if (cls == 'error') {
			let more_div = div({class: 'x-grid-loading-overlay-detail'})
			let band = action_band({
				layout: 'more... less... < > retry:ok forget-it:cancel',
				buttons: {
					more: function() {
						more_div.set(detail, 'pre-wrap')
						band.at[0].hide()
						band.at[1].show()
					},
					less: function() {
						more_div.clear()
						band.at[0].show()
						band.at[1].hide()
					},
					retry: function() {
						load_overlay(false)
						e.rowset.load()
					},
					forget_it: function() {
						load_overlay(false)
					},
				},
			})
			band.at[1].hide()
			let error_icon = span({class: 'x-grid-loading-error-icon fa fa-exclamation-circle'})
			oe.content.add(div({}, error_icon, text, more_div, band))
			focus_e = band.last.prev
		} else if (cls == 'waiting') {
			let cancel = button({
				text: cancel_text,
				action: function() {
					e.rowset.abort_loading()
				},
				attrs: {style: 'margin-left: 1em;'},
			})
			oe.content.add(text, cancel)
			focus_e = cancel
		} else
			oe.content.remove()
		e.add(oe)
		if(focus_e && e.hasfocus)
			focus_e.focus()
	}
	}

	e.update_load_slow = function(on) {
		if (on)
			load_overlay(true, 'waiting',
				S('slow', 'Still working on it...'),
				S('stop_waiting', 'Stop waiting'))
		else
			load_overlay(true, 'waiting',
				S('loading', 'Loading...'),
				S('stop_loading', 'Stop loading'))
	}

	e.update_load_fail = function(on, error, type, status, message, body) {
		if (type == 'abort')
			load_overlay(false)
		else
			load_overlay(on, 'error', error, null, body)
	}

	// column moving ----------------------------------------------------------

	{
		live_move_mixin(e)

		let move_px, move_fi

		function col_move_start_drag(fi, mx, my) {
			if (e.col_finishing_moving)
				return // finishing animations still running.
			e.col_moving = true
			window.x_widget_dragging = true
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
		let resize_guides

		function update_resize_guides() {
			for (let fi = 0; fi < e.fields.length; fi++) {
				let field = e.fields[fi]
				let guide = resize_guides.at[fi]
				let hcell = e.header.at[fi]
				guide.x = field.align == 'right'
					? hcell._x + hcell._w - field.w
					: hcell._x + field.w
				guide.h = e.header_h + e.rows_view_h
			}
		}

		function create_resize_guides() {
			if (!e.auto_cols_w)
				return
			resize_guides = div({class: 'x-grid-resize-guides'})
			for (let fi = 0; fi < e.fields.length; fi++)
				resize_guides.add(div({class: 'x-grid-resize-guide'}))
			e.add(resize_guides)
			update_resize_guides()
		}

		function remove_resize_guides() {
			if (!resize_guides)
				return
			resize_guides.remove()
			resize_guides = null
		}
	}

	// column resize mouse events

	{
		let hit_fi, hit_x

		e.on('mousemove', function mousemove(mx, my) {
			if (e.disabled) {
				if (hit_fi != null) {
					hit_fi = null
					e.class('col-resize', false)
				}
				return
			}
			if (window.x_widget_dragging)
				return
			let r = e.header.client_rect()
			mx = mx - r.left
			my = my - r.top
			let t = col_resize_hit_test(mx, my)
			hit_fi = t && t[0]
			hit_x  = t && t[1]
			e.class('col-resize', hit_fi != null)
			return true
		})

		e.on('mouseleave', function mouseleave() {
			if (window.x_widget_dragging)
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
			update_resize_guides()
			return true
		}

		function col_resize_document_mousedown() {
			if (hit_fi == null)
				return
			e.focus()
			e.col_resizing = true
			e.class('col-resizing')
			create_resize_guides()
			return true
		}

		function col_resize_document_mouseup() {
			if (!e.col_resizing)
				return
			e.col_resizing = false
			e.class('col-resizing', false)
			update_widths()
			remove_resize_guides()
			return true
		}
	}

	// column context menu ----------------------------------------------------

	function set_field_visibility(field, view_fi, on) {
		if (on)
			if (view_fi != null)
				e.fields.insert(view_fi, field)
			else
				e.fields.push(field)
		else
			e.fields.remove_value(field)
		e.init_fields()
		e.init_rows()
		e.init_value()
		e.init_focused_cell()
	}

	let context_menu
	function context_menu_popup(fi, mx, my) {

		if (!e.enable_context_menu)
			return

		if (context_menu) {
			context_menu.close()
			context_menu = null
		}

		let items = []

		items.push({
			text: e.rowset.changed_rows ?
				S('discard_changes_and_reload', 'Discard changes and reload') : S('reload', 'Reload'),
			icon: 'fa fa-sync',
			action: function() {
				e.rowset.load()
			},
			separator: true,
		})

		items.push({
			text: S('save', 'Save'),
			icon: 'fa fa-save',
			enabled: !!e.rowset.changed_rows,
			action: function() {
				e.rowset.save()
			},
			separator: true,
		})

		items.push({
			text: S('revert_changes', 'Revert changes'),
			icon: 'fa fa-undo',
			enabled: !!e.rowset.changed_rows,
			action: function() {
				e.rowset.revert()
			},
			separator: true,
		})

		if (e.can_change_filters_visibility)
			items.push({
				text: S('show_filters', 'Show filters'),
				checked: e.filters_visible,
				action: function(item) {
					e.filters_visible = item.checked
				},
				separator: true,
			})

		if (e.can_change_header_visibility)
			items.push({
				text: S('show_header', 'Show header'),
				checked: e.header_visible,
				action: function(item) {
					e.header_visible = item.checked
				},
				separator: true,
			})

		if (fi != null) {
			function hide_field(item) {
				set_field_visibility(item.field, null, false)
			}
			let field = e.fields[fi]
			let hide_field_text = span(); hide_field_text.set(field.text)
			let hide_text = span({}, S('hide_field', 'Hide '), hide_field_text)
			items.push({
				field: field,
				text: hide_text,
				action: hide_field,
			})
		}

		items.push({
			heading: S('show_more_fields', 'Show more fields'),
		})

		function show_field(item) {
			set_field_visibility(item.field, fi, true)
		}
		let items_added
		for (let field of e.rowset.fields) {
			if (e.fields.indexOf(field) == -1) {
				items_added = true
				items.push({
					field: field,
					text: field.text,
					action: show_field,
				})
			}
		}
		if (!items_added)
			items.push({
				text: S('all_fields_shown', 'All fields are shown'),
				enabled: false,
			})

		context_menu = menu({items: items})
		let r = e.client_rect()
		let px = mx - r.left
		let py = my - r.top
		context_menu.popup(e, 'inner-top', null, px, py)
	}

	// mouse bindings ---------------------------------------------------------

	e.pick_value = function() {
		e.fire('value_picked', {input: e}) // picker protocol.
	}

	e.header.on('mousedown', function header_mousedown(ev) {
		if (e.hasclass('col-resize'))
			return // clicked on the resizing area.
		let hcell = ev.target.closest('.x-grid-header-cell')
		if (!hcell) // didn't click on the hcell.
			return
		e.focus()
		e.col_dragging = true
		e.col_drag_index = hcell.index
		window.x_widget_dragging = true
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
		window.x_widget_dragging = false
		return true
	}

	function click_hcell(ev) {
		if (e.col_dragging)
			col_drag_mouseup()
		else if (e.col_moving)
			return
		else if (e.col_resizing)
			return
		if (e.hasclass('col-resize'))
			return // clicked on the resizing area.
		let hcell = ev.target.closest('.x-grid-header-cell')
		if (!hcell) // didn't click on the hcell.
			return
		e.focus()
		return hcell
	}

	e.header.on('click', function header_click(ev) {
		let hcell = click_hcell(ev)
		if (!hcell)
			return
		e.set_order_by_dir(e.fields[hcell.index], 'toggle', ev.shiftKey)
		return false
	})

	function sort_icon_click(ev) {
		let hcell = click_hcell(ev)
		if (!hcell)
			return
		e.set_order_by_dir(e.fields[hcell.index], false, ev.shiftKey)
		return false
	}

	e.on('contextmenu', function(ev) {
		if (e.hasclass('loading'))
			return false
		if (e.hasclass('col-resize'))
			return false // clicked on the resizing area.
		e.focus()
		let fi
		if (ev.target.hasclass('x-grid-cell'))
			fi = cell_address(ev.target)[1]
		else {
			let hcell = ev.target.closest('.x-grid-header-cell')
			fi = hcell && hcell.index
		}
		context_menu_popup(fi, ev.clientX, ev.clientY)
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
				e.pick_value()
			return false
		}
	})

	// document mouse bindings

	function document_mousedown() {
		if (window.x_widget_dragging)
			return // other grid is currently using the mouse.
		if (col_resize_document_mousedown()) {
			window.x_widget_dragging = true
			return false
		}
	}

	function document_mouseup() {
		if (col_drag_mouseup() || col_resize_document_mouseup() || col_move_document_mouseup()) {
			window.x_widget_dragging = false
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

		if (e.disabled)
			return

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
				if (row.is_new && !row.cells_modified) {
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
				e.pick_value()
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

		if (e.disabled)
			return

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
			value_col: e.lookup_col,
			can_edit: false,
			can_focus_cells: false,
			auto_focus_first_cell: false,
			enable_context_menu: false,
			auto_w: true,
			auto_h: true,
		}, e.grid))

		init()

	}

})

