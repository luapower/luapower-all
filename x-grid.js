
/* ---------------------------------------------------------------------------
// grid widget
// ---------------------------------------------------------------------------
uses:
	...
implements:
	nav widget protocol.
calls:
	e.do_update_cell_val(cell, row, field, input_val)
	e.do_update_cell_error(cell, row, field, err)
--------------------------------------------------------------------------- */

component('x-grid', function(e) {

	e.props.align_x = {default: 'stretch'}
	e.props.align_y = {default: 'stretch'}

	nav_widget(e)
	editable_widget(e)
	focusable_widget(e)

	e.classes = 'x-widget x-focusable x-grid'

	// geometry
	e.cell_h = 26
	e.auto_w = false
	e.auto_h = false
	e.auto_cols_w = true        // horizontal grid
	e.header_w = 120            // vertical grid
	e.cell_w = 120              // vertical grid

	// keyboard behavior
	e.auto_jump_cells = true    // jump to next/prev cell on caret limits
	e.tab_navigation = false    // disabled as it prevents jumping out of the grid.
	e.advance_on_enter = 'next_row' // false|'next_row'|'next_cell'
	e.prop('exit_edit_on_escape'           , {store: 'var', type: 'bool', default: true})
	e.prop('exit_edit_on_enter'            , {store: 'var', type: 'bool', default: false})
	e.quick_edit = false        // quick edit (vs. quick-search) when pressing a key

	// mouse behavior
	e.prop('can_reorder_fields'            , {store: 'var', type: 'bool', default: true})
	e.prop('enter_edit_on_click'           , {store: 'var', type: 'bool', default: false})
	e.prop('enter_edit_on_click_focused'   , {store: 'var', type: 'bool', default: false})
	e.prop('enter_edit_on_dblclick'        , {store: 'var', type: 'bool', default: true})
	e.prop('focus_cell_on_click_header'    , {store: 'var', type: 'bool', default: false})
	e.prop('can_change_parent'             , {store: 'var', type: 'bool', default: true})

	// context menu features
	e.prop('enable_context_menu'           , {store: 'var', type: 'bool', default: true})
	e.prop('can_change_header_visibility'  , {store: 'var', type: 'bool', default: true})
	e.prop('can_change_filters_visibility' , {store: 'var', type: 'bool', default: true})
	e.prop('can_change_fields_visibility'  , {store: 'var', type: 'bool', default: true})

	let horiz = true
	e.get_vertical = function() { return !horiz }
	e.set_vertical = function(v) {
		horiz = !v
		e.class('x-hgrid',  horiz)
		e.class('x-vgrid', !horiz)
		e.update({fields: true, rows: true})
	}
	e.prop('vertical', {type: 'bool'})

	e.header       = div({class: 'x-grid-header'})
	e.cells        = div({class: 'x-grid-cells'})
	e.cells_ct     = div({class: 'x-grid-cells-ct'}, e.cells)
	e.cells_view   = div({class: 'x-grid-cells-view'}, e.cells_ct)
	e.progress_bar = div({class: 'x-grid-progress-bar'})
	e.add(e.header, e.progress_bar, e.cells_view)

	e.on('bind', function(on) {
		document.on('layout_changed', layout_changed, on)
	})

	// geometry ---------------------------------------------------------------

	function set_cell_xw(cell, field, x, w) {
		if (field.align == 'right') {
			cell.x  = null
			cell.x2 = cells_w - (x + w)
		} else {
			cell.x  = x
			cell.x2 = null
		}
		cell.min_w = w
		cell.w = w
	}

	function update_cell_widths_horiz(col_resizing) {

		let cols_w = 0
		for (let field of e.fields)
			cols_w += field.w

		let total_free_w = 0
		let cw = cols_w
		if (e.auto_cols_w && !col_resizing) {
			cw = e.cells_view.clientWidth - 3 // TODO: fix this 3 thing!
			total_free_w = max(0, cw - cols_w)
		}

		let col_x = 0
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let hcell = e.header.at[fi]

			let min_col_w = col_resizing ? hcell._w : field.w
			let max_col_w = col_resizing ? hcell._w : field.max_w
			let free_w = total_free_w * (min_col_w / cols_w)
			let col_w = min(floor(min_col_w + free_w), max_col_w)
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

			if (hcell.filter_dropdown)
				hcell.filter_dropdown.w = hcell.clientWidth

			col_x += col_w
		}

		let header_w = e.fields.length ? col_x : cw
		e.header.w   = header_w
		e.cells_ct.w = header_w
		e.cells.w    = header_w
		cells_w      = header_w

		for (let fi = 0; fi < e.fields.length; fi++) {
			let hcell = e.header.at[fi]
			each_cell_of_col(fi, set_cell_xw, e.fields[fi], hcell._x, hcell._w)
		}

	}

	function update_cell_width_vert(cell, ri, fi) {
		set_cell_xw(cell, e.fields[fi], cell_x(ri - vri1, fi), cell_w(fi))
	}
	function update_cell_widths_vert() {
		each_cell(update_cell_width_vert)
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
			e.cells.w = cells_w
			vrn = floor(cells_view_w / e.cell_w) + 2

			for (let fi = 0; fi < e.fields.length; fi++) {
				let hcell = e.header.at[fi]
				hcell.y = cell_y(0, fi)
			}

		}

		vrn = min(vrn, e.rows.length)

	}

	function update_cell_sizes(col_resizing) {
		update_scroll()
		if (horiz)
			update_cell_widths_horiz(col_resizing)
		else
			update_cell_widths_vert()
		update_editor()
		update_resize_guides()
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

	function update_header_w(w) { // vgrid
		e.header_w = max(0, w)
		e.update({sizes: true})
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

	function each_cell(f, ...args) {
		for (let ri = vri1; ri < vri2; ri++)
			for (let fi = 0; fi < e.fields.length; fi++) {
				let cell = e.cells.at[(ri - vri1) * e.fields.length + fi]
				f(cell, ri, fi, ...args)
			}
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
			if (h1 !== h0 || w1 !== w0)
				e.update({sizes: true})
			w0 = w1
			h0 = h1
		}

		// detect w/h changes from resizing made with css 'resize: both'.
		e.detect_style_size_changes()
		e.on('style_size_changed', layout_changed)
	}

	// rendering --------------------------------------------------------------

	function create_fields() {
		e.header.clear()
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let sort_icon     = H.span({class: 'fa x-grid-sort-icon'})
			let sort_icon_pri = H.span({class: 'x-grid-header-sort-icon-pri'})
			let title_div = H.td({class: 'x-grid-header-title-td'})
			title_div.set(field.text)
			title_div.title = field.hint || title_div.textContent
			let sort_icon_div = H.td({class: 'x-grid-header-sort-icon-td'}, sort_icon, sort_icon_pri)
			let e1 = title_div
			let e2 = sort_icon_div
			if (horiz && field.align == 'right')
				[e1, e2] = [e2, e1]
			e1.attr('align', 'left')
			e2.attr('align', 'right')
			let title_table = H.table({class: 'x-grid-header-cell-table'}, H.tr(0, e1, e2))
			let hcell = div({class: 'x-grid-header-cell'}, title_table)
			hcell.fi = fi
			hcell.title_div = title_div
			hcell.sort_icon = sort_icon
			hcell.sort_icon_pri = sort_icon_pri
			e.header.add(hcell)
			create_filter(field, hcell)
		}
	}

	function create_filter(field, hcell) {
		if (!(horiz && e.filters_visible && field.filter_by))
			return
		let rs = e.filter_rowset(field)
		let dd = grid_dropdown({
			lookup_rowset : e.rowset,
			lookup_col    : 1,
			classes       : 'x-grid-filter-dropdown',
			mode          : 'fixed',
			grid: {
				cell_h: 22,
				classes: 'x-grid-filter-dropdown-grid',
			},
		})

		let f0 = rs.all_fields[0]
		let f1 = rs.all_fields[1]

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
			dd.do_update_val()
		}

		dd.picker.on('keydown', function(key) {
			if (key == ' ')
				this.pick_val()
		})

		hcell.filter_dropdown = dd
		hcell.add(dd)
	}

	function update_sort_icons() {
		let asc  = horiz ? 'up' : 'left'
		let desc = horiz ? 'down' : 'right'
		for (let fi = 0; fi < e.fields.length; fi++) {
			let field = e.fields[fi]
			let hcell = e.header.at[fi]
			let dir = field.sort_dir
			let pri = field.sort_priority
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

	function create_cells(moving) {
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
		e.empty_rt.show(!e.rows.length)
	}

	e.do_update_cell_val = function(cell, row, field, input_val) {
		let v = e.cell_display_val_for(row, field, input_val)
		cell.qs_val = v
		let node = cell.childNodes[cell.indent ? 1 : 0]
		if (cell.qs_div) { // value is wrapped
			node.replace(node.childNodes[0], v)
			cell.qs_div.clear()
		} else {
			cell.replace(node, v)
		}
		cell.class('null', input_val == null)
		cell.class('empty', input_val == '')
	}

	e.do_update_cell_error = function(cell, row, field, err) {
		let invalid = !!err
		cell.class('invalid', invalid)
		cell.attr('title', err || null)
	}

	function indent_offset(indent) {
		return 12 + indent * 16
	}

	function set_cell_indent(cell_indent, indent) {
		cell_indent.style['padding-left'] = (indent_offset(indent) - 4)+'px'
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
		cell.class('modified', e.cell_modified(row, field))

		if (field_has_indent(field)) {
			if (!cell.indent) {
				cell.indent = div({class: 'x-grid-cell-indent'})
				cell.set(cell.indent)
			}
			let has_children = row.child_rows.length > 0
			cell.indent.class('far', has_children)
			cell.indent.class('fa-plus-square' , has_children && !!row.collapsed)
			cell.indent.class('fa-minus-square', has_children && !row.collapsed)
			set_cell_indent(cell.indent, or(indent, row_indent(row)))
		} else if (cell.indent) {
			cell.set(null)
			cell.indent = null
		}

		e.do_update_cell_val(cell, row, field, e.cell_input_val(row, field))
		e.do_update_cell_error(cell, row, field, e.cell_error(row, field))

		row_focused = or(row_focused, e.focused_row == row)
		let cell_focused = row_focused && (!e.can_focus_cells || field == e.focused_field)
		let sel_fields = e.selected_rows.get(row)
		let selected = (isobject(sel_fields) ? sel_fields.has(field) : sel_fields) || false
		let editing = !!e.editor
		cell.class('focused', cell_focused)
		cell.class('editing', cell_focused && editing)
		cell.class('row-focused', row_focused)
		cell.class('selected', selected)

		cell.show()
	}

	function update_cell(cell, ri, fi) {
		set_cell_xw(cell, e.fields[fi], cell_x(ri - vri1, fi), cell_w(fi))
		cell.y = cell_y(ri - vri1, fi)
		update_cell_content(cell, e.rows[ri], ri, fi)
	}
	function update_cells_not_moving() {
		each_cell(update_cell)
	}

	function update_cells() {
		if (hit.state == 'row_moving')
			update_cells_moving()
		else
			update_cells_not_moving()
	}

	e.cells_view.on('scroll', function() {
		let last_vri1 = vri1
		update_scroll()
		if (vri1 != last_vri1)
			update_cells()
		update_editor()
		update_quicksearch_cell()
	})

	// quicksearch highlight --------------------------------------------------

	function update_quicksearch_cell() {
		let row = e.focused_row
		let field = e.quicksearch_field
		let s = e.quicksearch_text
		if (!(row && field))
			return
		let cell = e.cells.at[cell_index(e.row_index(row), field.index)]
		if (!cell)
			return
		if (typeof cell.qs_val != 'string')
			return
		if (!cell.qs_div) {
			if (s) {
				cell.qs_div = div({class: 'x-grid-qs-text'}, s)
				let val_node = cell.childNodes[cell.indent ? 1 : 0]
				val_node.remove()
				cell.add(div({style: 'position: relative'}, val_node, cell.qs_div))
			}
		} else {
			if (s) {
				let prefix = e.cell_input_val(row, field).slice(0, s.length)
				cell.qs_div.set(prefix)
			} else {
				cell.qs_div.clear()
			}
		}
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
			e.update({sizes: true})
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
			e.update({sizes: true})
		}
	)

	// inline editing ---------------------------------------------------------

	// when: input created, column width or height changed.
	let bw, bh
	function update_editor(x, y, indent) {
		if (!e.editor) return
		let ri = e.focused_row_index
		let fi = e.focused_field_index
		let field = e.fields[fi]
		let hcell = e.header.at[fi]
		if (bw == null) {
			let css = e.cells.at[0].css()
			bw = num(css['border-right-width'])
			bh = num(css['border-bottom-width'])
		}
		let iw = field_has_indent(field)
			? indent_offset(or(indent, row_indent(e.rows[ri]))) : 0

		let w = cell_w(fi) - bw - iw

		x = or(x, cell_x(ri, fi) + iw)
		y = or(y, cell_y(ri, fi))

		if (field.align == 'right') {
			e.editor.x  = null
			e.editor.x2 = cells_w - (x + w)
		} else {
			e.editor.x  = x
			e.editor.x2 = null
		}

		// set min outer width to col width.
		// width is set in css to 'min-content' to shrink to min inner width.
		e.editor.min_w = w

		e.editor.y = y
		e.editor.h = e.cell_h - bh

		// set min inner width to cell's unclipped text width.
		if (e.editor.set_text_min_w) {
			let cell_text_w = 0
			let cell = e.cells.at[cell_index(ri, fi)]
			if (cell) {
				let cell_min_w = cell.style['min-width']
				let cell_w     = cell.style['width']
				// measure cell unclipped width.
				cell.style['min-width'] = null
				cell.style['width'    ] = null
				cell_text_w = cell.rect().w - bw - iw
				cell.style['min-width'] = cell_min_w
				cell.style['width'    ] = cell_w
			}
			e.editor.set_text_min_w(max(20, cell_text_w))
		}

	}

	let do_create_editor = e.do_create_editor
	e.do_create_editor = function(field, ...opt) {
		do_create_editor(field, {
			inner_label: false,
			grid_editor_for: e,
		}, ...opt)
		if (!e.editor)
			return
		e.editor.class('grid-editor')
		if (!e.editor.parent)
			e.cells_ct.add(e.editor)
		update_editor()
	}

	e.do_update_cell_editing = function(ri, fi, editing) {
		let cell = e.cells.at[cell_index(ri, fi)]
		if (cell)
			cell.class('editing', editing)
	}

	// responding to rowset changes -------------------------------------------

	let val_widget_do_update = e.do_update
	e.do_update = function(opt) {

		if (!opt) {
			val_widget_do_update()
			return
		}

		if (!e.attached)
			return

		if (opt.reload) {
			e.reload()
			return
		}

		if (opt.fields)
			create_fields()
		if (opt.fields || opt.sort_order)
			update_sort_icons()
		let opt_rows = opt.rows || opt.fields
		let opt_sizes = opt_rows || opt.sizes
		if (opt_sizes) {
			let last_vrn = vrn
			update_sizes()
			opt_rows = opt_rows || last_vrn != vrn
		}
		if (opt_rows)
			create_cells()
		if (opt_sizes)
			update_cell_sizes(opt.col_resizing)
		if (opt_rows || opt.vals || opt.state)
			update_cells()
		if (opt_rows || opt.state)
			update_quicksearch_cell()
		if (opt.enter_edit)
			e.enter_edit(...opt.enter_edit)
		if (opt.scroll_to_cell)
				e.scroll_to_cell(...opt.scroll_to_cell)
	}

	e.do_update_cell_state = function(ri, fi, prop, val) {
		let cell = e.cells.at[cell_index(ri, fi)]
		if (!cell)
			return
		if (prop == 'input_val')
			e.do_update_cell_val(cell, e.rows[ri], e.fields[fi], val)
		else if (prop == 'error')
			e.do_update_cell_error(cell, e.rows[ri], e.fields[fi], val)
		else if (prop == 'modified')
			cell.class('modified', val)
	}

	e.do_update_row_state = function(ri, prop, val, ev) {
		let ci = cell_index(ri, 0)
		if (ci == null)
			return
		let cls
		if (prop == 'is_new')
			cls = 'new'
		else if (prop == 'removed')
			cls = 'removed'
		if (cls)
			each_cell_of_row(ri, function(cell, fi, cls, val) {
				cell.class(cls, val)
			}, cls, val)
	}

	e.do_update_load_progress = function(p) {
		e.progress_bar.w = (lerp(p, 0, 1, .2, 1) * 100) + '%'
	}

	// picker protocol --------------------------------------------------------

	e.pick_val = function() {
		e.fire('val_picked', {input: e})
	}

	e.init_as_picker = function() {
		e.begin_update()
		update(e, grid_picker_options(e.dropdown))
		e.update({sizes: true})
		e.end_update()
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
		if (horiz) {
			let hr = e.header.rect()
			if (!hr.contains(mx, my))
				return
		}
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
				let field = e.fields[hit.fi]
				field.w = clamp(w, field.min_w, field.max_w)
				e.header.at[hit.fi]._w = field.w
				e.update({sizes: true, col_resizing: true})
			}

		} else {

			mm_col_resize = function(mx, my, hit) {
				e.cell_w = max(20, mx - hit.mx)
				let sx = hit.ri * e.cell_w - hit.dx
				e.cells_view.scrollLeft = sx
				e.update({sizes: true})
			}

		}

		e.class('col-resize', true)

		mu_col_resize = function() {
			let field = e.fields[hit.fi]
			mm_col_resize = null
			mu_col_resize = null
			e.class('col-resizing', false)
			remove_resize_guides()
			e.set_prop(`col.${field.name}.w`, field.w)
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

	function md_row_drag(ev, mx, my, shift, ctrl) {

		let cell = hit.cell
		let over_indent = ev.target.closest('.x-grid-cell-indent')

		if (!e.hasfocus)
			e.focus()

		if (!cell)
			return

		if (over_indent)
			e.toggle_collapsed(e.rows[cell.ri], shift)

		let already_on_it =
			cell.ri == e.focused_row_index &&
			cell.fi == e.focused_field_index

		let toggle =
			!e.enter_edit_on_click
			&& !e.stay_in_edit_mode
			&& !e.editor
			&& e.fields[cell.fi].type == 'bool'

		return e.focus_cell(cell.ri, cell.fi, 0, 0, {
			must_not_move_row: true,
			enter_edit: !over_indent && e.can_edit
				&& !ctrl && !shift
				&& ((e.enter_edit_on_click || toggle)
					|| (e.enter_edit_on_click_focused && already_on_it)),
			focus_editor: true,
			editor_state: toggle ? 'toggle' : 'select_all',
			expand_selection: shift,
			invert_selection: ctrl,
			input: e,
		})
	}

	// row moving -------------------------------------------------------------

	function ht_row_move(mx, my, hit) {
		if (!e.can_move_rows) return
		if (e.focused_row_index != hit.cell.ri) return
		if ( horiz && abs(hit.my - my) < 8) return
		if (!horiz && abs(hit.mx - mx) < 8) return
		if (!horiz && e.parent_field) return
		if (e.order_by) return
		if (e.is_filtered) return
		return true
	}

	let mm_row_move, mu_row_move, update_cells_moving

	function md_row_move(mx, my, hit) {

		// init

		let hit_mx, hit_my
		{
			let r = hit.cell.rect()
			hit_mx = hit.mx - r.x
			hit_my = hit.my - r.y
		}

		// initial state

		let state = e.start_move_selected_rows()
		let ri1 = state.ri1
		let ri2 = state.ri2
		let move_ri1 = state.move_ri1
		let move_ri2 = state.move_ri2
		let move_n = state.move_n

		let w = horiz ? e.cell_h : e.cell_w
		let tree_fi = e.field_index(e.tree_field)
		let move_fi = hit.cell.fi

		// move state

		let hit_x
		let hit_ri = move_ri1
		let hit_parent_row = state.parent_row
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
					set_cell_xw(cell, e.fields[fi], cell_x(vri, fi), cell_w(fi))
				} else {
					set_cell_xw(cell, e.fields[fi], xy - vxy1, cell_w(fi))
					cell.y = cell_y(vri, fi)
				}

				let indent
				if (moving && row && field_has_indent(e.fields[fi]))
					indent = hit_indent
						+ row_indent(row)
						- row_indent(state.rows[0])

				if (cell.ri != ri || ri == null)
					update_cell_content(cell, row, ri, fi, focused, indent)
				else if (cell.indent)
					set_cell_indent(cell.indent, indent)

				cell.class('row-moving', moving)

				cell.class('moving-parent-cell',
					row == hit_parent_row && fi == tree_fi)
			}

			if (ri != null && focused)
				update_editor(
					 horiz ? null : xy,
					!horiz ? null : xy, hit_indent)
		}

		// hit testing

		function advance_row(before_ri) {
			if (!e.parent_field)
				return 1
			if (e.can_change_parent)
				return 1
			if (before_ri < 0)
				return 1
			if (before_ri == ri2 - 1)
				return 1
			let hit_row = state.rows[0]
			let over_row = e.rows[before_ri+1]
			if ((over_row && over_row.parent_row) == hit_row.parent_row)
				return 1
			return 1 + e.expanded_child_row_count(before_ri)
		}

		function update_hit_parent_row(hit_p) {
			hit_indent = null
			hit_parent_row = e.rows[hit_ri] ? e.rows[hit_ri].parent_row : null
			if (horiz && e.tree_field && e.can_change_parent) {
				let row1 = e.rows[hit_ri-1]
				let row2 = e.rows[hit_ri]
				let i1 = row1 ? row_indent(row1) : 0
				let i2 = row2 ? row_indent(row2) : 0
				// if the row can be a child of the row above,
				// the indent right limit is increased one unit.
				let ii1 = i1 + (row1 && !row1.collapsed && e.row_can_have_children(row1) ? 1 : 0)
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
					while (vri < vrn)
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
						update_row(true, vri++, state.rows[ri - move_ri1], ri, x, vri1x, ri == move_ri1)
						x += w
					}

					// hide leftover rows.
					while (vri < vrn)
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
			hit.state = null // update() would call update_cells_moving() otherwise.

			e.class('row-moving', false)
			if (e.editor)
				e.editor.class('row-moving', false)

			state.finish(hit_ri, hit_parent_row)
		}

		// post-init

		e.class('row-moving')
		if (e.editor)
			e.editor.class('row-moving')

		create_cells(true)

		let scroll_timer = every(.1, mm_row_move)

	}

	// column moving ----------------------------------------------------------

	live_move_mixin(e)

	e.movable_element_size = function(fi) {
		return horiz ? cell_w(fi) : e.cell_h
	}

	function set_cell_of_col_x(cell, field, x, w) { set_cell_xw(cell, field, x, w) }
	function set_cell_of_col_y(cell, field, y) { cell.y = y }
	e.set_movable_element_pos = function(fi, x) {
		each_cell_of_col(fi, horiz ? set_cell_of_col_x : set_cell_of_col_y, e.fields[fi], x, cell_w(fi))
		if (e.focused_field_index == fi)
			update_editor(
				 horiz ? x : null,
				!horiz ? x : null)
	}

	function ht_col_drag(mx, my, hit, ev) {
		let hcell = ev.target.closest('.x-grid-header-cell')
		if (!hcell) return
		hit.fi = hcell.index
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
		hit.mx -= e.header.at[hit.fi]._x
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
		e.move_field(hit.fi, over_fi)
	}

	// empty placeholder text -------------------------------------------------

	e.empty_rt = richtext({
		classes: 'x-grid-empty-rt',
		align_x: 'center',
		align_y: 'center',
	})
	e.empty_rt.hide()
	e.cells_view.add(e.empty_rt)

	let barrier
	e.set_empty_text = function(s) {
		if (barrier) return
		e.empty_rt.content = s
	}

	e.on('bind', function(on) {
		document.on('prop_changed', function(te, k, v) {
			if (te == e.empty_rt && k == 'content') {
				barrier = true
				e.empty_text = v
				barrier = false
			}
		})
	})

	e.prop('empty_text', {store: 'var', slot: 'lang'})

	// widget editing protocol ------------------------------------------------

	let editing_field, editing_sql

	e.hit_test_widget_editing = function(ev, mx, my) {
		if (!hit.state)
			pointermove(ev, mx, my)
		return hit.state == 'col_drag' || hit.state == 'row_drag' || !hit.state
	}

	e.set_widget_editing = function(on) {
		if (editing_field)
			set_editing_field(on)
		else if (editing_sql)
			set_editing_sql(on)
	}

	e.on('pointerdown', function(ev, mx, my) {
		if (!e.widget_editing)
			return
		if (!hit.state)
			pointermove(ev, mx, my)

		if (!(hit.state == 'col_drag' || hit.state == 'row_drag' || !hit.state) || !ev.ctrlKey) {
			unselect_all_widgets()
			return false
		}

		// editable_widget mixin's `pointerdown` handler must have ran before
		// this handler and must have called unselect_all_widgets().
		assert(!editing_field)
		assert(!editing_sql)

		if (hit.state == 'col_drag') {

			editing_field = e.fields[hit.fi]
			if (editing_field) {
				set_editing_field(true)
				// for convenience: select-all text if clicking near it but not on it.
				let hcell = e.header.at[editing_field.index]
				let title_div = hcell.title_div
				if (ev.target != title_div && hcell.contains(ev.target)) {
					title_div.focus()
					title_div.select_all()
					return false
				}
			}

		} else {

			editing_sql = true
			set_editing_sql(true)

		}

		// don't prevent default to let the caret land under the mouse.
		ev.stopPropagation()
	})

	function prevent_bubbling(ev) {
		ev.stopPropagation()
	}

	function prevent_bubbling2(ev) {
		print(ev.type)
		ev.stopPropagation()
	}

	function exit_widget_editing() {
		e.widget_editing = false
	}

	function editing_field_keydown(key, shift, ctrl, alt, ev) {
		if (key == 'Enter') {
			if (ctrl) {
				let hcell = e.header.at[editing_field.index]
				let title_div = hcell.title_div
				title_div.insert_at_caret('<br>')
			} else {
				e.widget_editing = false
			}
			return false
		}
	}

	function set_editing_field(on) {
		let hcell = e.header.at[editing_field.index]
		let title_div = hcell.title_div
		hcell.class('editing', on)
		title_div.contenteditable = on
		title_div.on('blur'        , exit_widget_editing, on)
		title_div.on('raw:pointerdown' , prevent_bubbling, on)
		title_div.on('raw:pointerup'   , prevent_bubbling, on)
		title_div.on('raw:click'       , prevent_bubbling, on)
		title_div.on('raw:contextmenu' , prevent_bubbling, on)
		title_div.on('keydown'         , editing_field_keydown, on)
		if (!on) {
			let s = title_div.textContent
			e.set_prop(`col.${editing_field.name}.text`, s)
			editing_field = null
		}
	}

	let sql_editor, sql_editor_ct

	function set_editing_sql(on) {
		e.cells_view.class('editing', on)
		if (on) {
			sql_editor_ct = div({class: 'x-grid-sql-editor'})
			sql_editor = ace.edit(sql_editor_ct, {
				mode: 'ace/mode/mysql',
				highlightActiveLine: false,
				printMargin: false,
				displayIndentGuides: false,
				tabSize: 3,
				enableBasicAutocompletion: true,
			})
			sql_editor_ct.on('blur'            , exit_widget_editing, on)
			sql_editor_ct.on('raw:pointerdown' , prevent_bubbling, on)
			sql_editor_ct.on('raw:pointerup'   , prevent_bubbling, on)
			sql_editor_ct.on('raw:click'       , prevent_bubbling, on)
			sql_editor_ct.on('raw:contextmenu' , prevent_bubbling, on)
			sql_editor.getSession().setValue(e.sql_select || '')
			e.cells_view.add(sql_editor_ct)
		} else {
			e.sql_select = repl(sql_editor.getSession().getValue(), '', undefined)
			sql_editor.destroy()
			sql_editor = null
			sql_editor_ct.remove()
			sql_editor_ct = null
			editing_sql = null
		}
	}

	// mouse bindings ---------------------------------------------------------

	let hit = {}

	function pointermove(ev, mx, my) {
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
				if (e.widget_editing) {
					if (ht_col_drag(mx, my, hit, ev)) {
						hit.state = 'col_drag'
					}
				} else if (ht_header_resize(mx, my, hit)) {
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

	function pointerdown(ev, mx, my) {

		if (e.widget_editing)
			return
		if (!hit.state)
			pointermove(ev, mx, my)
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
			if (!md_row_drag(ev, mx, my, ev.shiftKey, ev.ctrlKey))
				return false
		} else
			assert(false)

		return this.capture_pointer(ev, pointermove, pointerup)
	}

	function rightpointerdown(ev, mx, my) {

		if (e.widget_editing)
			return
		if (!hit.state)
			pointermove(ev, mx, my)
		if (!hit.state)
			return

		e.focus()

		if (hit.state == 'row_drag')
			e.focus_cell(hit.cell.ri, hit.cell.fi, 0, 0, {
				must_not_move_row: true,
				expand_selection: ev.shiftKey,
				invert_selection: ev.ctrlKey,
				input: e,
			})

		return false
	}

	function pointerup(ev) {

		if (e.widget_editing)
			return
		if (!hit.state)
			return

		if (hit.state == 'header_resizing') {
			e.class('col-resizing', false)
			e.update({sizes: true})
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
		} else if (hit.state == 'row_dragging') {
			e.pick_val()
		}

		if (hit.state != 'row_dragging') // keep hit.cell for dblclick on header only
			hit.cell = null
		hit.state = null
		return false
	}

	e.on('pointermove'     , pointermove)
	e.on('pointerdown'     , pointerdown)
	e.on('pointerup'       , pointerup)
	e.on('pointerleave'    , pointerup)
	e.on('rightpointerdown', rightpointerdown)

	e.on('contextmenu', function(ev) {
		let cell = ev.target.closest('.x-grid-header-cell') || ev.target.closest('.x-grid-cell')
		context_menu_popup(cell && cell.fi, ev.clientX, ev.clientY)
		return false
	})

	e.on('dblclick', function(ev) {
		if (!hit.cell) return
		if (e.enter_edit_on_dblclick)
			e.enter_edit('select_all')
		e.fire('cell_dblclick', hit.cell.ri, hit.cell.fi, ev)
	})

	// keyboard bindings ------------------------------------------------------

	e.on('keydown', function(key, shift, ctrl) {

		if (e.widget_editing)
			return
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
				|| (e.auto_jump_cells && !shift && (!horiz || ctrl)
					&& (!horiz
						|| !e.editor.editor_state
						|| ctrl
							&& (e.editor.editor_state(cols < 0 ? 'left' : 'right')
							|| e.editor.editor_state('all_selected'))
						))

			if (move)
				if (e.focus_next_cell(cols, {
					editor_state: horiz
						? (((e.editor && e.editor.editor_state) ? e.editor.editor_state('all_selected') : ctrl)
							? 'select_all'
							: cols > 0 ? 'left' : 'right')
						: 'select_all',
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
				if (e.insert_rows(1, {input: e, focus_it: true}))
					return false
		}

		// remove last row with the arrow up key if not edited.
		if (key == up_arrow) {
			if (e.is_last_row_focused()) {
				let row = e.focused_row
				if (row.is_new && !e.row_is_user_modified(row)) {
					if (e.remove_selected_rows({refocus: true}))
						return false
				}
			}
		}

		// row navigation.
		let rows
		switch (key) {
			case up_arrow    : rows = -1; break
			case down_arrow  : rows =  1; break
			case 'PageUp'    : rows = -(ctrl ? 1/0 : page_row_count); break
			case 'PageDown'  : rows =  (ctrl ? 1/0 : page_row_count); break
			case 'Home'      : rows = -1/0; break
			case 'End'       : rows =  1/0; break
		}
		if (rows) {

			let move = !e.editor
				|| (e.auto_jump_cells && !shift
					&& (horiz
						|| !e.editor.editor_state
						|| (ctrl
							&& (e.editor.editor_state(rows < 0 ? 'left' : 'right')
							|| e.editor.editor_state('all_selected')))
						))

			if (move)
				if (e.focus_cell(true, true, rows, 0, {
					editor_state: e.editor && e.editor.editor_state
						&& (horiz ? e.editor.editor_state() : 'select_all'),
					expand_selection: shift,
					input: e,
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
			if (e.quicksearch_text) {
				e.quicksearch(e.quicksearch_text, e.focused_row, 1)
			} else if (e.hasclass('picker')) {
				e.pick_val()
			} else if (!e.editor) {
				e.enter_edit('toggle')
			} else if (!e.exit_edit_on_enter || e.exit_edit()) {
				if (e.advance_on_enter == 'next_row')
					e.focus_cell(true, true, 1, 0, {editor_state: 'select_all', input: e, enter_edit: e.stay_in_edit_mode})
				else if (e.advance_on_enter == 'next_cell')
					e.focus_next_cell(shift ? -1 : 1, {editor_state: 'select_all', input: e, enter_edit: e.stay_in_edit_mode})
			}
			return false
		}

		// Esc: exit edit mode.
		if (key == 'Escape') {
			if (e.quicksearch_text) {
				e.quicksearch('')
				return false
			}
			if (e.editor && e.exit_edit_on_escape) {
				e.exit_edit()
				e.focus()
				return false
			}
		}

		// insert key: insert row
		if (key == 'Insert')
			if (e.insert_rows(1, {input: e, at_focused_row: true, focus_it: true}))
				return false

		if (!e.editor && key == 'Delete') {

			// delete: toggle-delete active row
			if (!ctrl && e.remove_selected_rows({refocus: true, toggle: true}))
				return false

			// ctrl_delete: set selected cells to null.
			if (ctrl) {
				e.set_null_selected_cells()
				return false
			}

		}

		if (!e.editor && key == ' ' && !e.quicksearch_text) {
			if (e.focused_row && (!e.can_focus_cells || e.focused_field == e.tree_field))
				e.toggle_collapsed(e.focused_row, shift)
			else if (e.focused_field && e.focused_field.type == 'bool')
				e.enter_edit('toggle')
			return false
		}

		if (!e.editor && ctrl && key == 'a') {
			e.select_all_cells()
			return false
		}

		if (!e.editor && key == 'Backspace') {
			if (e.quicksearch_text)
				e.quicksearch(e.quicksearch_text.slice(0, -1), e.focused_row)
			return false
		}

	})

	// printable characters: enter quick edit mode.
	e.on('keypress', function(c) {

		if (e.widget_editing)
			return
		if (e.disabled)
			return

		if (e.quick_edit) {
			if (!e.editor && e.focused_row && e.focused_field) {
				e.enter_edit('select_all')
				let v = e.focused_field.from_text(c)
				e.set_cell_val(e.focused_row, e.focused_field, v)
				return false
			}
		} else if (!e.editor) {
			e.quicksearch(e.quicksearch_text + c, e.focused_row)
			return false
		}
	})

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
			text: e.changed_rows ?
				S('discard_changes_and_reload', 'Discard changes and reload') : S('reload', 'Reload'),
			enabled: !e.changed_rows && !!e.rowset_url,
			icon: 'fa fa-sync',
			action: function() {
				e.reload()
			},
			separator: true,
		})

		items.push({
			text: S('save', 'Save'),
			icon: 'fa fa-save',
			enabled: !!(e.changed_rows),
			action: function() {
				e.save()
			},
			separator: true,
		})

		items.push({
			text: S('revert_changes', 'Revert changes'),
			icon: 'fa fa-undo',
			enabled: !!(e.changed_rows),
			action: function() {
				e.revert()
			},
			separator: true,
		})

		items.push({
			text: S('remove_selected_rows', 'Remove selected rows'),
			icon: 'fa fa-trash',
			enabled: e.selected_rows.size && e.can_remove_row(),
			action: function() {
				e.remove_selected_rows({refocus: true})
			},
		})

		items.push({
			text: S('set_null_selected_cells', 'Set selected cells to null'),
			icon: 'fa fa-eraser',
			enabled: e.selected_rows.size && e.can_change_val(),
			action: function() {
				e.set_null_selected_cells()
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
					e.show_field(item.field, false)
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
				e.show_field(item.field, true, fi)
			}
			let items_added
			for (let field of e.all_fields) {
				if (field.visible !== false && !e.fields.includes(field)) {
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

			items.last.separator = true

		}

		if (e.parent_field) {
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

		context_menu = menu({items: items})
		let r = e.rect()
		let px = mx - r.x
		let py = my - r.y
		context_menu.popup(e, 'inner-top', null, px, py)
	}

})

// ---------------------------------------------------------------------------
// grid dropdown
// ---------------------------------------------------------------------------

function grid_picker_options(e) {
	return {
		type: 'grid',
		gid: e.gid && e.gid + '.dropdown',
		rowset: e.rowset,
		rowset_name: e.rowset_name,
		nav: e.nav,
		col: e.col,
		val_col: e.val_col,
		display_col: e.display_col,
		can_edit: false,
		can_focus_cells: false,
		auto_focus_first_cell: false,
		enable_context_menu: false,
		auto_w: true,
		auto_h: true,
	}
}

component('x-grid-dropdown', function(e) {

	nav_dropdown_widget(e)
	e.classes = 'x-grid-dropdown'

	init = e.init
	e.init = function() {
		e.picker = e.picker || component.create(update(grid_picker_options(e), e.grid))
		init()
	}

	e.on('opened', function() {
		e.picker.scroll_to_focused_cell()
	})

})

// ---------------------------------------------------------------------------
// grid profile
// ---------------------------------------------------------------------------

component('x-grid-profile', function(e) {

	pagelist_item_widget(e)


})
