
// ---------------------------------------------------------------------------
// grid
// ---------------------------------------------------------------------------

component('x-grid', function(e) {

	rowset_widget(e)
	focusable_widget(e)

	e.align_x = 'stretch'
	e.align_y = 'stretch'
	e.classes = 'x-widget x-focusable x-grid'

	// geometry
	e.cell_h = 26
	e.auto_w = false
	e.auto_h = false
	e.auto_cols_w = true        // horizontal grid
	e.header_w = 120            // vertical grid
	e.cell_w = 120              // vertical grid

	// keyboard behavior
	e.tab_navigation = false    // disabled as it prevents jumping out of the grid.
	e.auto_advance = 'next_row' // advance on enter = false|'next_row'|'next_cell'
	e.auto_jump_cells = true    // jump to next/prev cell on caret limits
	e.quick_edit = false        // quick edit (vs. quick-search) when pressing a key

	// mouse behavior
	e.can_sort_rows = true
	e.can_reorder_fields = true
	e.enter_edit_on_click = false
	e.enter_edit_on_click_focused = true
	e.exit_edit_on_escape = true
	e.exit_edit_on_enter = true
	e.focus_cell_on_click_header = false
	e.can_move_rows = false
	e.can_change_parent = true

	// context menu features
	e.enable_context_menu = true
	e.can_change_header_visibility = false
	e.can_change_filters_visibility = true
	e.can_change_fields_visibility = true

	let horiz = true
	e.get_vertical = function() { return !horiz }
	e.set_vertical = function(v) {
		horiz = !v
		e.class('x-hgrid',  horiz)
		e.class('x-vgrid', !horiz)
		e.init_fields()
		e.init_rows()
	}
	e.prop('vertical', {type: 'bool'})

	e.header       = div({class: 'x-grid-header'})
	e.cells        = div({class: 'x-grid-cells'})
	e.cells_ct     = div({class: 'x-grid-cells-ct'}, e.cells)
	e.cells_view   = div({class: 'x-grid-cells-view'}, e.cells_ct)
	e.progress_bar = div({class: 'x-grid-progress-bar'})
	e.add(e.header, e.progress_bar, e.cells_view)

	e.init = function() {
		e.rowset_widget_init()
	}

	function bind(on) {
		document.on('layout_changed', layout_changed, on)
	}

	e.attach = function() {
		e.rowset_widget_attach()
		bind(true)
	}

	e.detach = function() {
		e.rowset_widget_detach()
		bind(false)
	}

	// geometry ---------------------------------------------------------------

	function update_cell_widths_horiz(col_resizing) {

		let cols_w = 0
		for (let field of e.fields)
			cols_w += field.w

		let total_free_w = 0
		let cw = cols_w
		if (e.auto_cols_w && !col_resizing) {
			cw = e.cells_view.clientWidth
			total_free_w = max(0, cw - cols_w)
		}

		let col_x = 0
		for (let fi = 0; fi < e.fields.length; fi++) {
			let hcell = e.header.at[fi]

			let min_col_w = col_resizing ? hcell._w : e.fields[fi].w
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

			let ci = fi
			let cell
			while (cell = e.cells.at[ci]) {
				cell.x = col_x
				cell.w = col_w
				ci += e.fields.length
			}

			if (hcell.filter_dropdown)
				hcell.filter_dropdown.w = hcell.clientWidth

			col_x += col_w
		}

		let header_w = e.fields.length ? col_x : cw
		e.header.w = header_w
		e.cells_ct.w = header_w
	}

	let cells_h, cells_w, header_h, cells_view_w, cells_view_h, page_row_count, vrn

	function update_sizes() {

		if (horiz) {

			// these must be reset when changing from !horiz to horiz.
			e.header.w = null
			e.header.h = null
			e.cells.x = null
			e.cells_view.w = null

			cells_h = e.cell_h * e.rows.length

			let client_h = e.clientHeight
			let border_h = e.offsetHeight - client_h
			header_h = e.header.offsetHeight

			if (e.auto_w) {

				let cols_w = 0
				for (let field of e.fields)
					cols_w += field.w

				let client_w = e.cells_view.clientWidth
				let border_w = e.offsetWidth - e.clientWidth
				let vscrollbar_w = e.cells_view.offsetWidth - client_w
				e.w = cols_w + border_w + vscrollbar_w
			}

			if (e.auto_h)
				e.h = cells_h + header_h + border_h

			cells_view_h = floor(e.cells_view.rect().h)
			e.cells_ct.h = max(1, cells_h) // need at least 1px to show scrollbar.
			vrn = floor(cells_view_h / e.cell_h) + 2
			page_row_count = floor(cells_view_h / e.cell_h)

			update_cell_widths_horiz()

		} else {

			e.header.w = e.header_w
			e.header.h = e.cell_h * e.fields.length

			cells_w = e.cell_w * e.rows.length
			cells_h = e.cell_h * e.fields.length

			let border_w = e.offsetWidth - e.clientWidth

			if (e.auto_w)
				e.w = cells_w + e.header_w + border_w

			let client_w = e.clientWidth
			border_w = e.offsetWidth - client_w
			let header_w = e.header.offsetWidth

			if (e.auto_h) {
				let client_h = e.cells_view.clientHeight
				let border_h = e.offsetHeight - e.clientHeight
				let hscrollbar_h = e.cells_view.offsetHeight - client_h
				e.h = cells_h + border_h + hscrollbar_h
			}

			cells_view_w = client_w - header_w
			e.cells_ct.w = cells_w
			e.cells_ct.h = cells_h
			e.cells_view.w = cells_view_w
			vrn = floor(cells_view_w / e.cell_w) + 2

			for (let fi = 0; fi < e.fields.length; fi++) {
				let hcell = e.header.at[fi]
				hcell.y = cell_y(0, fi)
			}

		}

		vrn = min(vrn, e.rows.length)

		if (e.editor)
			update_editor(e.editor)

		update_scroll()

	}

	let vri1, vri2
	let scroll_x, scroll_y

	function update_scroll() {
		let sy = e.cells_view.scrollTop
		let sx = e.cells_view.scrollLeft
		sx =  horiz ? sx : clamp(sx, 0, max(0, cells_w - cells_view_w))
		sy = !horiz ? sy : clamp(sy, 0, max(0, cells_h - cells_view_h))
		scroll_x = sx
		scroll_y = sy
		if (horiz) {
			e.header.x = -sx
			e.cells.y = floor(sy - sy % e.cell_h)
			vri1 = floor(sy / e.cell_h)
		} else {
			e.header.y = -sy
			e.cells.x = floor(sx - sx % e.cell_w)
			vri1 = floor(sx / e.cell_w)
		}
		vri2 = vri1 + vrn
	}

	function cell_x(vri, fi) {
		return horiz
			? e.header.at[fi]._x
			: vri * e.cell_w
	}

	function cell_y(vri, fi) {
		return horiz
			? vri * e.cell_h
			: fi * e.cell_h
	}

	function cell_w(fi) {
		return horiz
			? e.header.at[fi]._w
			: e.cell_w
	}

	function field_has_indent(field) {
		return horiz && field == e.tree_field
	}

	function row_indent(row) {
		return row.parent_rows ? row.parent_rows.length : 0
	}

	function set_col_w(fi, w) { // hgrid
		let field = e.fields[fi]
		field.w = clamp(w, field.min_w, field.max_w)
		e.header.at[fi]._w = field.w
	}

	function update_header_w(w) { // vgrid
		e.header_w = max(0, w)
		update_sizes()
	}

	e.scroll_to_cell = function(ri, fi) {
		if (ri == null)
			return
		let x = fi != null ? cell_x(ri, fi) : 0
		let y = cell_y(ri, fi)
		let w = fi != null ? cell_w(fi) : 0
		let h = e.cell_h
		e.cells_view.scroll_to_view_rect(null, null, x, y, w, h)
	}

	// ri/fi to visible cell --------------------------------------------------

	function cell_index(ri, fi) {
		if (ri == null || fi == null)
			return
		if (ri >= vri1 && ri < vri2)
			return (ri - vri1) * e.fields.length + fi
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

	function each_cell_of_row(ri, f, ...args) {
		let ci = cell_index(ri, 0)
		if (ci == null)
			return
		for (let fi = 0; fi < e.fields.length; fi++)
			f(e.cells.at[ci+fi], fi, ...args)
	}

	// responding to layout changes -------------------------------------------

	{
		let w0, h0
		function layout_changed() {
			let r = e.rect()
			let w1 = r.w
			let h1 = r.h
			if (w1 == 0 && h1 == 0)
				return // hidden
			if (h1 !== h0 || w1 !== w0) {
				let last_vrn = vrn
				update_sizes()
				if (vrn != last_vrn) {
					init_cells()
					update_viewport()
				}
			}
			w0 = w1
			h0 = h1
		}
	}

	// detect w/h changes from resizing made with css 'resize: both'.
	e.on('attr_changed', function(mutations) {
		if (mutations[0].attributeName == 'style')
			layout_changed()
	})

	// rendering --------------------------------------------------------------

	e.init_fields = function() {
		if (!e.isConnected)
			return
		e.header.clear()
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let sort_icon     = H.span({class: 'fa x-grid-sort-icon'})
			let sort_icon_pri = H.span({class: 'x-grid-header-sort-icon-pri'})
			let e1 = H.td({class: 'x-grid-header-title-td'})
			e1.set(field.text)
			e1.title = e1.textContent
			let e2 = H.td({class: 'x-grid-header-sort-icon-td'}, sort_icon, sort_icon_pri)
			if (horiz && field.align == 'right')
				[e1, e2] = [e2, e1]
			e1.attr('align', 'left')
			e2.attr('align', 'right')
			let title_table = H.table({class: 'x-grid-header-cell-table'}, H.tr(0, e1, e2))
			let hcell = div({class: 'x-grid-header-cell'}, title_table)
			hcell.fi = fi
			hcell.sort_icon = sort_icon
			hcell.sort_icon_pri = sort_icon_pri
			e.header.add(hcell)
			init_filter(field, hcell)
		}
		update_sort_icons()
	}

	function init_filter(field, hcell) {
		if (!(horiz && e.filters_visible && field.filter_by))
			return
		let rs = e.filter_rowset(field)
		let dd = grid_dropdown({
			lookup_rowset : rs,
			lookup_col    : 1,
			classes       : 'x-grid-filter-dropdown',
			mode          : 'fixed',
			grid: {
				cell_h: 22,
				classes: 'x-grid-filter-dropdown-grid',
			},
		})

		let f0 = rs.field(0)
		let f1 = rs.field(1)

		dd.display_val = function() {
			if (!rs.filtered_count)
				return () => div({class: 'x-item disabled'}, S('all', 'all'))
			else
				return () => span({}, div({class: 'x-grid-filter fa fa-filter'}), rs.filtered_count+'')
		}

		dd.on('opened', function() {
			rs.load()
		})

		dd.picker.pick_val = function() {
			let checked = !rs.val(this.focused_row, f0)
			rs.set_val(this.focused_row, f0, checked)
			rs.filtered_count = (rs.filtered_count || 0) + (checked ? -1 : 1)
			dd.update_val()
			e.init_rows_array()
			e.init_rows()
			e.sort()
		}

		dd.picker.on('keydown', function(key) {
			if (key == ' ')
				this.pick_val()
		})

		hcell.filter_dropdown = dd
		hcell.add(dd)
	}

	function update_sort_icons() {
		if (!e.isConnected)
			return
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let hcell = e.header.at[fi]
			let dir = e.order_by_dir(field)
			let pri = e.order_by_priority(field)
			let asc  = horiz ? 'up' : 'left'
			let desc = horiz ? 'down' : 'right'
			hcell.sort_icon.class('fa-angle-'+asc        , false)
			hcell.sort_icon.class('fa-angle-double-'+asc , false)
			hcell.sort_icon.class('fa-angle-'+desc       , false)
			hcell.sort_icon.class('fa-angle-double-'+desc, false)
			hcell.sort_icon.class('fa-angle'+(pri?'-double':'')+'-'+asc , dir == 'asc')
			hcell.sort_icon.class('fa-angle'+(pri?'-double':'')+'-'+desc, dir == 'desc')
			hcell.sort_icon.parent.class('sorted', !!dir)
			hcell.sort_icon_pri.set(pri > 1 ? pri : '')
		}
	}

	e.on('sort_order_changed', function() {
		update_sort_icons()
	})

	function init_cells(moving) {
		e.cells.clear()
		let n = vrn * (moving ? 2 : 1)
		for (let i = 0; i < n; i++) {
			for (let fi = 0; fi < e.fields.length; fi++) {
				let classes = 'x-grid-cell x-item'
				if (moving && i >= vrn)
					classes += ' row-moving'
				let cell = div({class: classes})
				e.cells.add(cell)
			}
		}
	}

	e.update_cell_val = function(cell, row, field, input_val) {
		let v = e.rowset.display_val(row, field)
		if (cell.indent)
			cell.replace(cell.childNodes[1], v)
		else
			cell.set(v)
		cell.class('null', input_val == null)
	}

	e.update_cell_error = function(cell, row, field, err) {
		let invalid = !!err
		cell.class('invalid', invalid)
		cell.attr('title', err || null)
	}

	function indent_offset(indent) {
		return 12 + indent * 16
	}

	function set_cell_indent(cell, indent) {
		cell.indent.style['padding-left'] = (indent_offset(indent) - 4)+'px'
	}

	function update_cell_content(cell, row, ri, fi, row_focused, indent) {

		cell.ri = ri
		cell.fi = fi

		if (!row) {
			cell.hide()
			return
		}

		cell.w = cell_w(fi)
		cell.h = e.cell_h

		let field = e.fields[fi]

		cell.attr('align', field.align)
		cell.class('focusable', e.can_focus_cell(row, field))
		cell.class('disabled', e.is_cell_disabled(row, field))
		cell.class('new', !!row.is_new)
		cell.class('removed', !!row.removed)
		cell.class('modified', e.rowset.cell_modified(row, field))

		if (field_has_indent(field)) {
			if (!cell.indent) {
				cell.indent = div({class: 'x-grid-cell-indent'})
				cell.set(cell.indent)
			}
			let has_children = row.child_rows.length > 0
			cell.indent.class('far', has_children)
			cell.indent.class('fa-plus-square' , has_children && !!row.collapsed)
			cell.indent.class('fa-minus-square', has_children && !row.collapsed)
			set_cell_indent(cell, or(indent, row_indent(row)))
		} else if (cell.indent) {
			cell.set(null)
			cell.indent = null
		}

		e.update_cell_val(cell, row, field, e.rowset.input_val(row, field))
		e.update_cell_error(cell, row, field, e.rowset.cell_error(row, field))

		row_focused = or(row_focused, e.focused_row_index == ri)
		let cell_focused = row_focused && (!e.can_focus_cells || fi == e.focused_field_index)
		let sel_fields = e.selected_rows.get(row)
		let selected = (isarray(sel_fields) ? sel_fields[fi] : sel_fields) || false
		let editing = !!e.editor
		cell.class('focused', cell_focused)
		cell.class('editing', cell_focused && editing)
		cell.class('row-focused', row_focused)
		cell.class('selected', selected)

		cell.show()
	}

	function update_cells() {
		for (let ri = vri1; ri < vri2; ri++) {
			for (let fi = 0; fi < e.fields.length; fi++) {
				let cell = e.cells.at[(ri - vri1) * e.fields.length + fi]
				cell.x = cell_x(ri - vri1, fi)
				cell.y = cell_y(ri - vri1, fi)
				update_cell_content(cell, e.rows[ri], ri, fi)
			}
		}
	}

	e.cells_view.on('scroll', function() {
		let last_vri1 = vri1
		update_scroll()
		if (vri1 != last_vri1)
			update_viewport()
	})

	function update_viewport() {
		if (hit.state == 'row_moving')
			update_cells_moving()
		else
			update_cells()
	}

	function unfocus_cell(cell) {
		cell.class('focused', false)
		cell.class('editing', false)
		cell.class('row-focused', false)
	}

	function focus_cell(cell, fi, focused_fi, editing) {
		let focused = !e.can_focus_cells || fi == focused_fi
		cell.class('focused', focused)
		cell.class('editing', focused && editing)
		cell.class('row-focused', true)
	}

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
		e.init_val()
		e.init_focused_cell()
	}

	// resize guides ----------------------------------------------------------

	let resize_guides

	function update_resize_guides() {
		if (!resize_guides)
			return
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let guide = resize_guides.at[fi]
			let hcell = e.header.at[fi]
			guide.x = field.align == 'right'
				? hcell._x + hcell._w - field.w
				: hcell._x + field.w
			guide.h = header_h + cells_view_h
		}
	}

	function create_resize_guides() {
		if (!horiz)
			return
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

	// header_visible & filters_visible live properties -----------------------

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

	// when: input created, column width or height changed.
	function update_editor(editor, x, y, indent) {
		let ri = e.focused_row_index
		let fi = e.focused_field_index
		let hcell = e.header.at[fi]
		let css = e.cells.at[0].css()
		let iw = field_has_indent(e.fields[fi])
			? indent_offset(or(indent, row_indent(e.rows[ri]))) : 0
		editor.x = or(x, cell_x(ri, fi) + iw)
		editor.y = or(y, cell_y(ri, fi))
		editor.w = cell_w(fi) - num(css['border-right-width']) - iw
		editor.h = e.cell_h - num(css['border-bottom-width'])
	}

	let create_editor = e.create_editor
	e.create_editor = function(field, ...editor_options) {
		let editor = create_editor(field, {
			inner_label: false,
			can_select_widget: false,
		}, ...editor_options)
		if (!editor)
			return
		editor.class('grid-editor')
		e.cells_ct.add(editor)
		update_editor(editor)
		return editor
	}

	e.update_cell_editing = function(ri, fi, editing) {
		let cell = e.cells.at[cell_index(ri, fi)]
		if (cell)
			cell.class('editing', editing)
	}

	// responding to rowset changes -------------------------------------------

	e.init_rows = function() {
		if (!e.isConnected)
			return
		update_sizes()
		init_cells()
		update_viewport()
	}

	e.update_cell_focus = function() {
		update_viewport()
	}

	e.update_cell_state = function(ri, fi, prop, val) {
		let cell = e.cells.at[cell_index(ri, fi)]
		if (!cell)
			return
		if (prop == 'input_val')
			e.update_cell_val(cell, e.rows[ri], e.fields[fi], val)
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
			each_cell_of_row(ri, function(cell, fi, cls, val) {
				cell.class(cls, val)
			}, cls, val)
	}

	e.update_load_progress = function(p) {
		e.progress_bar.w = (lerp(p, 0, 1, .2, 1) * 100) + '%'
	}

	// picker protocol --------------------------------------------------------

	e.pick_val = function() {
		e.fire('val_picked', {input: e})
	}

	// vgrid header resizing --------------------------------------------------

	function ht_header_resize(mx, my, hit) {
		if (horiz) return
		let r = e.header.rect()
		let x = mx - r.x2
		if (!(x >= -5 && x <= 5)) return
		hit.x = r.x + x
		return true
	}

	function mm_header_resize(mx, my, hit) {
		update_header_w(mx - hit.x)
	}

	// col resizing -----------------------------------------------------------

	function ht_col_resize_horiz(mx, my, hit) {
		if (mx >= e.header.offsetWidth)
			return
		for (let fi = 0; fi < e.fields.length; fi++) {
			let hcell = e.header.at[fi]
			let x = mx - (hcell._x + hcell._w)
			if (x >= -5 && x <= 5) {
				hit.fi = fi
				hit.x = x
				return true
			}
		}
	}

	function ht_col_resize_vert(mx, my, hit) {
		if (my >= e.header.offsetHeight)
			return
		let x = ((mx + 5) % e.cell_w) - 5
		if (!(x >= -5 && x <= 5))
			return
		hit.ri = floor((mx - 6) / e.cell_w)
		hit.dx = e.cell_w * hit.ri - scroll_x
		let r = e.cells_view.rect()
		hit.mx = r.x + hit.dx + x
		return true
	}

	function ht_col_resize(mx, my, hit) {
		let r = e.cells_ct.rect()
		mx -= r.x
		my -= r.y
		if (horiz)
			return ht_col_resize_horiz(mx, my, hit)
		else
			return ht_col_resize_vert(mx, my, hit)
	}

	let mm_col_resize, mu_col_resize

	function md_col_resize(mx, my, hit) {

		if (horiz) {

			mm_col_resize = function(mx, my, hit) {
				let r = e.cells_ct.rect()
				let w = mx - r.x - e.header.at[hit.fi]._x - hit.x
				set_col_w(hit.fi, w)
				update_cell_widths_horiz(true)
				update_resize_guides()
			}

		} else {

			mm_col_resize = function(mx, my, hit) {
				e.cell_w = max(20, mx - hit.mx)
				let sx = hit.ri * e.cell_w - hit.dx
				e.cells_view.scrollLeft = sx
				let last_vrn = vrn
				update_sizes()
				if (vrn != last_vrn)
					e.init_rows()
				else
					update_viewport()
			}

		}

		e.class('col-resize', true)

		mu_col_resize = function() {
			mm_col_resize = null
			mu_col_resize = null
			e.class('col-resizing', false)
			remove_resize_guides()
			update_sizes()
		}

	}

	// cell clicking ----------------------------------------------------------

	function ht_row_drag(mx, my, hit, ev) {
		hit.cell = ev.target.closest('.x-grid-cell')
		if (!hit.cell) return
		hit.mx = mx
		hit.my = my
		return true
	}

	function md_row_drag(ev, mx, my) {

		let cell = hit.cell
		let over_indent = ev.target.closest('.x-grid-cell-indent')

		if (!e.hasfocus)
			e.focus()

		if (!cell)
			return

		let already_on_it =
			e.focused_row_index   == cell.ri &&
			e.focused_field_index == cell.fi

		if (e.focus_cell(cell.ri, cell.fi, 0, 0, {
			must_not_move_row: true,
			enter_edit: !over_indent && e.can_edit && (e.enter_edit_on_click
				|| (e.enter_edit_on_click_focused && already_on_it)),
			focus_editor: true,
			editor_state: 'select_all',
			expand_selection: ev.shiftKey,
			invert_selection: ev.ctrlKey,
			input: e,
		})) {
			if (over_indent)
				e.toggle_collapsed(e.focused_row_index, ev.shiftKey)
			if (!already_on_it)
				e.pick_val()
		}
	}

	// row moving -------------------------------------------------------------

	function ht_row_move(mx, my, hit) {
		if (!e.can_move_rows) return
		if (e.focused_row_index != hit.cell.ri) return
		if ( horiz && abs(hit.my - my) < 8) return
		if (!horiz && abs(hit.mx - mx) < 8) return
		if (!horiz && e.rowset.parent_field) return
		if (e.order_by) return
		if (e.filter_rowsets && e.filter_rowsets.size > 0) return
		return true
	}

	let mm_row_move, mu_row_move, update_cells_moving

	function md_row_move(mx, my, hit) {

		// init

		let hit_mx, hit_my
		{
			let r = e.cells.rect()
			hit_mx = hit.mx - r.x - num(hit.cell.style.left)
			hit_my = hit.my - r.y - num(hit.cell.style.top)
		}

		let move_fi = hit.cell.fi

		let move_ri1 = hit.cell.ri
		let move_n = 1 + e.child_row_count(move_ri1)
		let move_ri2 = move_ri1 + move_n

		let w = horiz ? e.cell_h : e.cell_w

		let parent_row = e.rows[move_ri1].parent_row

		let tree_fi = e.fields.indexOf(e.tree_field)

		let ri1 = 0
		let ri2 = e.rows.length
		if (!e.can_change_parent && e.rowset.parent_field) {
			if (parent_row) {
				let parent_ri = e.row_index(parent_row)
				ri1 = parent_ri + 1
				ri2 = parent_ri + 1 + e.child_row_count(parent_ri)
			}
		}
		ri2 -= move_n // adjust to after removal.

		let moved_rows = e.rows.splice(move_ri1, move_n)

		// state

		let hit_x
		let hit_ri = move_ri1
		let hit_parent_row = parent_row
		let hit_indent

		let xof       = (ri => ri * w)
		let final_xof = (ri => xof(ri) + (ri < hit_ri ? 0 : move_n) * w)

		// view update

		function update_row(moving, vri, row, ri, xy, vxy1, focused) {
			if (moving)
				vri += (vri2 - vri1)

			let ci0 = vri * e.fields.length
			for (let fi = 0; fi < e.fields.length; fi++) {
				let cell = e.cells.at[ci0 + fi]
				if (horiz) {
					cell.y = xy - vxy1
					cell.x = cell_x(vri, fi)
				} else {
					cell.x = xy - vxy1
					cell.y = cell_y(vri, fi)
				}

				let indent
				if (moving && row && field_has_indent(e.fields[fi]))
					indent = hit_indent
						+ row_indent(row)
						- row_indent(moved_rows[0])

				if (cell.ri != ri || ri == null)
					update_cell_content(cell, row, ri, fi, focused, indent)
				else if (cell.indent)
					set_cell_indent(cell, indent)

				cell.class('row-moving', moving)

				cell.class('moving-parent-cell',
					row == hit_parent_row && fi == tree_fi)
			}

			if (e.editor && ri != null && focused)
				update_editor(e.editor,
					 horiz ? null : xy,
					!horiz ? null : xy, hit_indent)
		}

		// hit testing

		function advance_row(before_ri) {
			if (!d.parent_field)
				return 1
			if (e.can_change_parent)
				return 1
			if (before_ri < 0)
				return 1
			if (before_ri == ri2 - 1)
				return 1
			let hit_row = moved_rows[0]
			let over_row = e.rows[before_ri+1]
			if ((over_row && over_row.parent_row) == hit_row.parent_row)
				return 1
			return 1 + e.child_row_count(before_ri)
		}

		function update_hit_parent_row(hit_p) {
			hit_indent = null
			hit_parent_row = e.rows[hit_ri].parent_row
			if (horiz && e.tree_field && e.can_change_parent) {
				let row1 = e.rows[hit_ri-1]
				let row2 = e.rows[hit_ri]
				let i1 = row1 ? row_indent(row1) : 0
				let i2 = row2 ? row_indent(row2) : 0
				// if the row can be a child of the row above,
				// the indent right limit is increased one unit.
				let ii1 = i1 + (row1 && !row1.collapsed && e.rowset.can_have_children(row1) ? 1 : 0)
				hit_indent = min(floor(lerp(hit_p, 0, 1, ii1 + 1, i2)), ii1)
				let parent_i = i1 - hit_indent
				hit_parent_row = parent_i >= 0 ? row1 && row1.parent_rows[parent_i] : row1
			}
		}

		{
			let xs = [] // {ci -> x}
			let is = [] // {ci -> ri}

			{
				let x = xof(ri1)
				let ci = 0
				for (let ri = ri1, n; ri < ri2; ri += n) {
					n = advance_row(ri)
					let wn = w * n
					xs[ci] = x + wn / 2
					is[ci] = ri
					ci++
					x += wn
				}
			}

			function hit_test() {
				let ci = xs.binsearch(hit_x)
				let last_hit_ri = hit_ri
				hit_ri = or(is[ci], ri2)
				let x1 = or(xs[ci  ], xof(ri2))
				let x0 = or(xs[ci-1], xof(ri1))
				let hit_p = lerp(hit_x, x0, x1, 0, 1)
				update_hit_parent_row(hit_p)
				return hit_ri != last_hit_ri
			}

		}

		// animations

		{
			let xs = []; xs.length = e.rows.length
			let zs = []; zs.length = e.rows.length
			let ts = []; ts.length = e.rows.length

			for (let ri = 0; ri < xs.length; ri++) {
				zs[ri] = xof(ri + (ri < move_ri1 ? 0 : move_n))
				xs[ri] = zs[ri]
			}

			let ari1 = 1/0
			let ari2 = -1/0

			function move() {
				let last_hit_ri = hit_ri
				if (hit_test()) {

					// find the range of elements that must make way for the
					// moving elements to be inserted at hit_ri.
					let mri1 = min(hit_ri, last_hit_ri)
					let mri2 = max(hit_ri, last_hit_ri)

					// extend the animation range with the newfound range.
					ari1 = min(ari1, mri1)
					ari2 = max(ari2, mri2)

					// reset animations for the newfound elements.
					let t = clock()
					for (let ri = ari1; ri < ari2; ri++) {
						zs[ri] = xs[ri]
						ts[ri] = t
					}

				}
			}

			function animate() {

				// update animations and compute the still-active animation range.
				let t = clock()
				let td = .1
				let aari1, aari2
				for (let ri = ari1; ri < ari2; ri++) {
					let t0 = ts[ri]
					let t1 = t0 + td
					let x0 = zs[ri]
					let x1 = final_xof(ri)
					let finished = t - t0 >= td
					if (finished) {
						xs[ri] = x1
					} else {
						let v = lerp(t, t0, t1, 0, 1)
						let ev = 1 - (1 - v)**3
						xs[ri] = lerp(ev, 0, 1, x0, x1)

						aari1 = or(aari1, ri)
						aari2 = ri + 1
					}
				}

				// shrink the animation range to the active range.
				ari1 = max(ari1, or(aari1, ari1))
				ari2 = min(ari2, or(aari2, ari1))

				let vri1x = xof(vri1)

				let view_x = horiz ? scroll_y : scroll_x
				let view_w = horiz ? cells_view_h : cells_view_w

				// update positions for the visible range of non-moving elements.
				{
					let vri1 = xs.binsearch(view_x, '<=') - 1
					let vri2 = xs.binsearch(view_x + view_w)

					vri1 = clamp(vri1, 0, e.rows.length-1)

					let vri = 0
					for (let ri = vri1; ri < vri2; ri++)
						update_row(false, vri++, e.rows[ri], ri, xs[ri], vri1x, false)

					// hide leftover rows.
					while(vri < vrn)
						update_row(false, vri++)
				}

				// update element positions for the visible range of moving elements.
				{
					// moving cells use a second block of cells temporarily
					// allocated for this purpose.
					let dx1 = max(0, view_x - hit_x)
					let di1 = floor(dx1 / w)
					let move_vri1x = hit_x + dx1
					let move_vri1 = move_ri1 + di1
					let move_vrn = min(vrn, move_ri2 - move_vri1)
					let move_vri2 = move_ri1 + move_vrn
					let vri = 0
					let x = move_vri1x
					for (let ri = move_vri1; ri < move_vri2; ri++) {
						update_row(true, vri++, moved_rows[ri - move_ri1], ri, x, vri1x, ri == move_ri1)
						x += w
					}

					// hide leftover rows.
					while(vri < vrn)
						update_row(true, vri++)
				}

				return ari2 > ari1
			}

		}

		// mouse, scroll and animation controller

		let af

		update_cells_moving = function() {
			if (animate())
				af = raf(update_cells_moving)
			else
				af = null
		}

		{
			let mx0, my0
			function update_hit_x(mx, my) {
				mx = or(mx, mx0)
				my = or(my, my0)
				mx0 = mx
				my0 = my
				let r = e.cells_ct.rect()
				hit_x = horiz
					? my - r.y - hit_my
					: mx - r.x - hit_mx
				hit_x = clamp(hit_x, xof(ri1), xof(ri2))
			}
		}

		function scroll_to_moving_cell() {
			update_hit_x()
			let x =  horiz ? (move_fi != null ? cell_x(null, move_fi) : 0) : hit_x
			let y = !horiz ? (move_fi != null ? cell_y(null, move_fi) : 0) : hit_x
			let w = move_fi != null ? cell_w(move_fi) : 0
			let h = e.cell_h
			e.cells_view.scroll_to_view_rect(null, null, x, y, w, h)
		}

		mm_row_move = function(mx, my) {
			let hit_x0 = hit_x
			update_hit_x(mx, my)
			if (hit_x0 == hit_x)
				return
			move()
			if (af == null)
				af = raf(update_cells_moving)
			scroll_to_moving_cell()
		}

		mu_row_move = function() {
			if (af != null)
				cancelAnimationFrame(af)
			clearInterval(scroll_timer)

			mm_row_move = null
			mu_row_move = null
			update_cells_moving = null
			hit.state = null

			e.class('row-moving', false)
			if (e.editor)
				e.editor.class('row-moving', false)

			e.move_row(moved_rows, hit_ri, hit_parent_row)

			e.focused_row_index = hit_ri
			e.init_rows()
		}

		// post-init

		e.class('row-moving')
		if (e.editor)
			e.editor.class('row-moving')

		init_cells(true)

		let scroll_timer = every(.1, mm_row_move)

	}

	// column moving ----------------------------------------------------------

	live_move_mixin(e)

	e.movable_element_size = function(fi) {
		return horiz ? cell_w(fi) : e.cell_h
	}

	function set_cell_of_col_x(cell, x) { cell.x = x }
	function set_cell_of_col_y(cell, y) { cell.y = y }
	e.set_movable_element_pos = function(fi, x) {
		each_cell_of_col(fi, horiz ? set_cell_of_col_x : set_cell_of_col_y, x)
		if (e.editor && e.focused_field_index == fi)
			update_editor(e.editor, horiz ? x : null, !horiz ? x : null)
	}

	function ht_col_drag(mx, my, hit, ev) {
		let hcell_table = ev.target.closest('.x-grid-header-cell-table')
		if (!hcell_table) return
		hit.fi = hcell_table.parent.index
		hit.mx = mx
		hit.my = my
		return true
	}

	function ht_col_move(mx, my, hit) {
		if ( horiz && abs(hit.mx - mx) < 8) return
		if (!horiz && abs(hit.my - my) < 8) return
		let r = e.header.rect()
		hit.mx -= r.x
		hit.my -= r.y
		hit.mx -= num(e.header.at[hit.fi].style.left)
		hit.my -= num(e.header.at[hit.fi].style.top)
		e.class('col-moving')
		each_cell_of_col(hit.fi, cell => cell.class('col-moving'))
		if (e.editor && e.focused_field_index == hit.fi)
			e.editor.class('col-moving')
		e.move_element_start(hit.fi, 1, 0, e.fields.length)
		return true
	}

	function mm_col_move(mx, my, hit) {
		let r = e.header.rect()
		mx -= r.x
		my -= r.y
		let x = horiz
			? mx - hit.mx
			: my - hit.my
		e.move_element_update(x)
	}

	function mu_col_move() {
		let over_fi = e.move_element_stop() // sets x of moved element.
		e.class('col-moving', false)
		each_cell_of_col(hit.fi, cell => cell.class('col-moving', false))
		if (e.editor)
			e.editor.class('col-moving', false)
		if (over_fi != hit.fi) {
			let focused_field  = e.focused_field
			let selected_field = e.selected_field

			let insert_fi = over_fi - (over_fi > hit.fi ? 1 : 0)
			let field = e.fields.remove(hit.fi)
			e.fields.insert(insert_fi, field)

			e.fields_array_changed()
			e.focused_field_index  = e.field_index(focused_field)
			e.selected_field_index = e.field_index(selected_field)
			for (let [row, a] of e.selected_rows)
				if (isarray(a))
					a.insert(insert_fi, a.remove(hit.fi))

			e.init_fields()
			update_sizes()
			update_viewport()
		}
	}

	// mouse bindings ---------------------------------------------------------

	let hit = {}

	function pointermove(mx, my, ev) {
		if (hit.state == 'header_resizing') {
			mm_header_resize(mx, my, hit)
		} else if (hit.state == 'col_resizing') {
			mm_col_resize(mx, my, hit)
		} else if (hit.state == 'col_dragging') {
			if (e.can_reorder_fields && ht_col_move(mx, my, hit)) {
				hit.state = 'col_moving'
				mm_col_move(mx, my, hit)
			}
		} else if (hit.state == 'col_moving') {
			mm_col_move(mx, my, hit)
		} else if (hit.state == 'row_dragging') {
			if (ht_row_move(mx, my, hit)) {
				hit.state = 'row_moving'
				md_row_move(mx, my, hit)
				mm_row_move(mx, my, hit)
			}
		} else if (hit.state == 'row_moving') {
			mm_row_move(mx, my, hit)
		} else {
			hit.state = null
			e.class('col-resize', false)
			if (!e.disabled) {
				if (ht_header_resize(mx, my, hit)) {
					hit.state = 'header_resize'
					e.class('col-resize', true)
				} else if (ht_col_resize(mx, my, hit)) {
					hit.state = 'col_resize'
					md_col_resize(mx, my, hit)
				} else if (ht_col_drag(mx, my, hit, ev)) {
					hit.state = 'col_drag'
				} else if (ht_row_drag(mx, my, hit, ev)) {
					hit.state = 'row_drag'
				}
			}
			if (hit.state)
				return false
		}
	}

	e.on('pointermove', pointermove)

	e.on('pointerdown', function(ev, mx, my) {
		if (!hit.state)
			pointermove(mx, my, ev)
		if (!hit.state)
			return
		e.focus()
		if (hit.state == 'header_resize') {
			hit.state = 'header_resizing'
			e.class('col-resizing')
		} else if (hit.state == 'col_resize') {
			hit.state = 'col_resizing'
			e.class('col-resizing')
			create_resize_guides()
		} else if (hit.state == 'col_drag') {
			hit.state = 'col_dragging'
		} else if (hit.state == 'row_drag') {
			hit.state = 'row_dragging'
			md_row_drag(ev, mx, my)
		} else
			assert(false)
		return 'capture'
	})

	function pointerup(mx, my, ev) {
		if (!hit.state)
			return
		if (hit.state == 'header_resizing') {
			e.class('col-resizing', false)
			e.init_rows()
		} else if (hit.state == 'col_resizing') {
			mu_col_resize()
		} else if (hit.state == 'col_dragging') {
			if (e.can_sort_rows)
				e.set_order_by_dir(e.fields[hit.fi], 'toggle', ev.shiftKey)
			else if (e.focus_cell_on_click_header)
				e.focus_cell(true, hit.fi)
		} else if (hit.state == 'col_moving') {
			mu_col_move()
		} else if (hit.state == 'row_moving') {
			mu_row_move()
		}
		hit.state = null
		return false
	}

	e.on('pointerup', pointerup)
	e.on('pointerleave', pointerup)

	e.on('contextmenu', function(ev) {
		let cell = ev.target.closest('.x-grid-header-cell') || ev.target.closest('.x-grid-cell')
		context_menu_popup(cell && cell.fi, ev.clientX, ev.clientY)
		return false
	})

	e.cells.on('dblclick', function(ev) {
		let cell = ev.target.closest('.x-grid-cell')
		if (!cell) return
		ev.row_index = cell.ri
		e.fire('cell_dblclick', e.rows[cell.ri], ev)
	})

	// keyboard bindings ------------------------------------------------------

	e.on('keydown', function(key, shift, ctrl) {

		if (e.disabled)
			return

		let left_arrow  =  horiz ? 'ArrowLeft'  : 'ArrowUp'
		let right_arrow =  horiz ? 'ArrowRight' : 'ArrowDown'
		let up_arrow    = !horiz ? 'ArrowLeft'  : 'ArrowUp'
		let down_arrow  = !horiz ? 'ArrowRight' : 'ArrowDown'

		// same-row field navigation.
		if (key == left_arrow || key == right_arrow) {

			let cols = key == left_arrow ? -1 : 1

			let move = !e.editor
				|| (e.auto_jump_cells && !shift
					&& (!horiz
						|| !e.editor.editor_state
						|| e.editor.editor_state(cols < 0 ? 'left' : 'right')))

			if (move)
				if (e.focus_next_cell(cols, {
					editor_state: horiz ? (cols > 0 ? 'left' : 'right') : 'select_all',
					expand_selection: shift,
					input: e,
				}))
					return false

		}

		// Tab/Shift+Tab cell navigation.
		if (key == 'Tab' && e.tab_navigation) {

			let cols = shift ? -1 : 1

			if (e.focus_next_cell(cols, {
				auto_advance_row: true,
				editor_state: cols > 0 ? 'left' : 'right',
				input: e,
			}))
				return false

		}

		// insert with the arrow down key on the last focusable row.
		if (key == down_arrow) {
			if (e.is_last_row_focused())
				if (e.insert_row(null, true))
					return false
		}

		// remove last row with the arrow up key if not edited.
		if (key == up_arrow) {
			if (e.is_last_row_focused()) {
				let row = e.focused_row
				if (row.is_new && !row.cells_modified) {
					e.remove_focused_row({refocus: true})
					return false
				}
			}
		}

		// row navigation.
		let rows
		switch (key) {
			case up_arrow    : rows = -1; break
			case down_arrow  : rows =  1; break
			case 'PageUp'    : rows = -page_row_count; break
			case 'PageDown'  : rows =  page_row_count; break
			case 'Home'      : rows = -1/0; break
			case 'End'       : rows =  1/0; break
		}
		if (rows) {

			let move = !e.editor
				|| (e.auto_jump_cells && !shift
					&& (horiz
						|| !e.editor.editor_state
						|| e.editor.editor_state(rows < 0 ? 'left' : 'right')))

			if (move)
				if (e.focus_cell(true, true, rows, 0, {
					editor_state: rows > 0 ? 'left' : 'right',
					expand_selection: shift,
					input: e
				}))
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
				e.pick_val()
			} else if (!e.editor) {
				e.enter_edit('select_all')
			} else if (e.exit_edit_on_enter && e.exit_edit()) {
				if (e.auto_advance == 'next_row')
					e.focus_cell(true, true, 1, 0, {editor_state: 'select_all', input: e})
				else if (e.auto_advance == 'next_cell')
					e.focus_next_cell(shift ? -1 : 1, {editor_state: 'select_all', input: e})
			}
			return false
		}

		// Esc: exit edit mode.
		if (key == 'Escape') {
			if (e.hasclass('picker'))
				return
			if (e.exit_edit_on_escape)
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

		if (!e.editor && key == ' ') {
			if (e.focused_row_index)
				e.toggle_collapsed(e.focused_row_index, shift)
			return false
		}

		if (key == 'a' && ctrl) {
			e.select_all()
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
				e.rowset.set_val(e.focused_row, e.focused_field, v)
				return false
			}
		} else if (!e.editor)
			e.quicksearch(c, e.focused_field)
	})

	e.property('ctrl_click_used', () => e.multiple_selection)

	// column context menu ----------------------------------------------------

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
			text: e.rowset && e.rowset.changed_rows ?
				S('discard_changes_and_reload', 'Discard changes and reload') : S('reload', 'Reload'),
			enabled: !!e.rowset,
			icon: 'fa fa-sync',
			action: function() {
				e.rowset.reload()
			},
			separator: true,
		})

		items.push({
			text: S('save', 'Save'),
			icon: 'fa fa-save',
			enabled: !!(e.rowset && e.rowset.changed_rows),
			action: function() {
				e.rowset.save()
			},
			separator: true,
		})

		items.push({
			text: S('revert_changes', 'Revert changes'),
			icon: 'fa fa-undo',
			enabled: !!(e.rowset && e.rowset.changed_rows),
			action: function() {
				e.rowset.revert()
			},
			separator: true,
		})

		if (horiz && e.can_change_filters_visibility)
			items.push({
				text: S('show_filters', 'Show filters'),
				checked: e.filters_visible,
				action: function(item) {
					e.filters_visible = item.checked
				},
				separator: true,
			})

		items.push({
			text: S('vertical_grid', 'Show as Vertical Grid'),
			checked: e.vertical,
			action: function(item) {
				e.vertical = item.checked
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

		if (e.can_change_fields_visibility) {

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
			if (e.rowset)
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

			if (e.rowset.parent_field) {
				items.push({
					text: S('expand_all', 'Expand all'),
					enabled: horiz && e.tree_field,
					action: function() { e.set_collapsed(null, false, true) },
				})
				items.push({
					text: S('collapse_all', 'Collapse all'),
					enabled: horiz && e.tree_field,
					action: function() { e.set_collapsed(null, true, true) },
				})
			}

		}

		context_menu = menu({items: items})
		let r = e.rect()
		let px = mx - r.x
		let py = my - r.y
		context_menu.popup(e, 'inner-top', null, px, py)
	}

})

// vgrid ---------------------------------------------------------------------

vgrid = function(...options) {
	return grid({vertical: true}, ...options)
}

// grid_dropdown -------------------------------------------------------------

component('x-grid-dropdown', function(e) {

	e.class('x-grid-dropdown')
	dropdown.construct(e)

	init = e.init
	e.init = function() {
		e.picker = grid(update({
			rowset: e.lookup_rowset,
			val_col: e.lookup_col,
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
