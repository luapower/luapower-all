
// ---------------------------------------------------------------------------
// grid
// ---------------------------------------------------------------------------

component('x-grid', function(e) {

	rowset_widget(e)
	e.align_x = 'stretch'
	e.align_y = 'stretch'
	tabindex_widget(e)
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
	e.exit_edit_on_escape = true

	// context menu features
	e.enable_context_menu = true
	e.can_change_header_visibility = false
	e.can_change_filters_visibility = true
	e.can_change_fields_visibility = true

	let horiz = true
	e.class('x-hgrid', horiz)
	e.property('vertical',
		function() { return !horiz },
		function(v) {
			horiz = !v
			e.class('x-hgrid',  horiz)
			e.class('x-vgrid', !horiz)
		})

	e.header       = div({class: 'x-grid-header'})
	e.cells        = div({class: 'x-grid-cells'})
	e.cells_ct     = div({class: 'x-grid-cells-ct'}, e.cells)
	e.cells_view   = div({class: 'x-grid-cells-view'}, e.cells_ct)
	e.progress_bar = div({class: 'x-grid-progress-bar'})
	e.add(e.header, e.progress_bar, e.cells_view)

	e.cells_view.on('scroll', update_viewport)

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

	function update_cell_widths(col_resizing) {

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
				let remaining_w = cw - col_x - 1 // -1 to avoid flickering scrollbars.
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
	}

	function update_filter_width(fd, fi) {
		let hcell = e.header.at[fi]
		fd.w = hcell.clientWidth
	}

	function update_sizes() {

		if (horiz) {

			e.cells_h = e.cell_h * e.rows.length

			e.header.h = null // auto
			e.cells_view.h = 0 // measure the header height
			let client_h = e.clientHeight
			let border_h = e.offsetHeight - client_h
			e.header_h = e.header.offsetHeight

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
				e.h = e.cells_h + e.header_h + border_h

			e.cells_view_h = client_h - e.header_h
			e.cells_ct.h = max(1, e.cells_h) // need at least 1px to show scrollbar.
			e.cells_ct.w = e.header.offsetWidth
			e.cells_view.h = e.cells_view_h
			e.visible_row_count = floor(e.cells_view_h / e.cell_h) + 2
			e.page_row_count = floor(e.cells_view_h / e.cell_h)

			update_cell_widths()

		} else {

			e.header.w = e.header_w
			e.header.h = e.cell_h * e.fields.length

			e.cells_w = e.cell_w * e.rows.length
			e.cells_h = e.cell_h * e.fields.length

			let border_w = e.offsetWidth - e.clientWidth

			if (e.auto_w)
				e.w = e.cells_w + e.header_w + border_w

			let client_w = e.clientWidth
			border_w = e.offsetWidth - client_w
			let header_w = e.header.offsetWidth

			if (e.auto_h) {
				let client_h = e.cells_view.clientHeight
				let border_h = e.offsetHeight - e.clientHeight
				let hscrollbar_h = e.cells_view.offsetHeight - client_h
				e.h = e.cells_h + border_h + hscrollbar_h
			}

			e.cells_view_w = client_w - header_w
			e.cells_ct.w = e.cells_w
			e.cells_ct.h = e.cells_h
			e.cells_view.w = e.cells_view_w
			e.visible_row_count = floor(e.cells_view_w / e.cell_w) + 2

			for (let fi = 0; fi < e.fields.length; fi++) {
				let hcell = e.header.at[fi]
				hcell.y = cell_y(0, fi)
			}

		}

		if (e.editor)
			update_editor(e.editor)

	}

	function first_visible_row(sx, sy) {
		if (horiz) {
			sy = or(sy, e.scroll_y)
			return floor(sy / e.cell_h)
		} else {
			sx = or(sx, e.scroll_x)
			return floor(sx / e.cell_w)
		}
	}

	function cell_x(ri, fi) {
		return horiz
			? e.header.at[fi]._x
			: ri * e.cell_w
	}

	function cell_y(ri, fi) {
		return horiz
			? ri * e.cell_h
			: fi * e.cell_h
	}

	function cell_w(fi) {
		return horiz
			? e.header.at[fi]._w
			: e.cell_w
	}

	function cell_indent(row, field) {
		return horiz && field == e.tree_field && row.parent_rows
			? 12 + row.parent_rows.length * 16 : 0
	}

	function row_has_visible_children(ri, row) {
		let next_row = e.rows[ri+1]
		return next_row && next_row.parent_rows.length > row.parent_rows.length
	}

	function scroll_x(sx) {
		return horiz ? sx : clamp(sx, 0, max(0, e.cells_w - e.cells_view_w))
	}

	function scroll_y(sy) {
		return !horiz ? sy : clamp(sy, 0, max(0, e.cells_h - e.cells_view_h))
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

	function update_header_pos(sx, sy) {
		if (horiz)
			e.header.x = -sx
		else
			e.header.y = -sy
	}

	function rows_x_offset(sx) {
		return floor(sx - sx % e.cell_w)
	}

	function rows_y_offset(sy) {
		return floor(sy - sy % e.cell_h)
	}

	function update_cells_pos(sx, sy) {
		if (horiz)
			e.cells.y = rows_y_offset(sy)
		else
			e.cells.x = rows_x_offset(sx)
	}

	// ri/fi to visible cell --------------------------------------------------

	function cell_index(ri, fi, sx, sy) {
		if (ri == null || fi == null)
			return
		let ri0 = first_visible_row(sx, sy)
		let ri1 = min(ri0 + e.visible_row_count, e.rows.length)
		if (ri >= ri0 && ri < ri1)
			return (ri - ri0) * e.fields.length + fi
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

	function each_cell_of_row(ri, sx, sy, f, ...args) {
		let ci = cell_index(ri, 0, sx, sy)
		if (ci == null)
			return
		for (let fi = 0; fi < e.fields.length; fi++)
			f(e.cells.at[ci+fi], fi, ...args)
	}

	// responding to layout changes -------------------------------------------

	{
		let w0, h0
		function layout_changed() {
			let r = e.client_rect()
			let w1 = r.width
			let h1 = r.height
			if (w1 == 0 && h1 == 0)
				return // hidden
			if (h1 !== h0 || w1 !== w0) {
				let vrc = e.visible_row_count
				update_sizes()
				if (e.visible_row_count != vrc) {
					init_cells()
					update_viewport()
				}
			}
			w0 = w1
			h0 = h1
		}
	}

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

	function init_cells() {
		let tree_field = horiz && e.tree_field
		focused_td = null
		e.cells.clear()
		for (let j = 0; j < e.visible_row_count; j++) {
			for (let i = 0; i < e.fields.length; i++) {
				let field = e.fields[i]
				let indent = field == tree_field && div({class: 'x-grid-cell-indent'}) || null
				let cell = div({class: 'x-grid-cell x-item'}, indent)
				cell.indent = indent
				e.cells.add(cell)
			}
		}
	}

	e.update_cell_val = function(cell, row, field, input_val) {
		let content_node = cell.childNodes[cell.indent ? 1 : 0]
		cell.replace(content_node, e.rowset.display_val(row, field))
		cell.class('null', input_val == null)
	}

	e.update_cell_error = function(cell, row, field, err) {
		let invalid = !!err
		cell.class('invalid', invalid)
		cell.attr('title', err || null)
	}

	function update_cell(cell, row, field) {
		cell.attr('align', field.align)
		cell.class('focusable', e.can_focus_cell(row, field))
		cell.class('disabled', e.is_cell_disabled(row, field))
		cell.class('new', !!row.is_new)
		cell.class('removed', !!row.removed)
		cell.class('modified', e.rowset.cell_modified(row, field))
		let input_val = e.rowset.cell_error(row, field)
		e.update_cell_val(cell, row, field, e.rowset.input_val(row, field))
		e.update_cell_error(cell, row, field, e.rowset.cell_error(row, field))
	}

	function update_cell_tree_aspect(cell, ri, row, field) {
		let has_children = (row.child_row_count || 0) > 0
		let has_visible_children = row_has_visible_children(ri, row)
		cell.indent.class('far', has_children)
		cell.indent.class('fa-plus-square' , has_children && !has_visible_children)
		cell.indent.class('fa-minus-square', has_children && has_visible_children)
		cell.indent.style['padding-left'] = (cell_indent(row, field) - 4)+'px'
	}

	function update_cells() {
		let ri0 = first_visible_row()
		for (let rel_ri = 0; rel_ri < e.visible_row_count; rel_ri++) {
			let ri = ri0 + rel_ri
			let row = e.rows[ri]
			for (let fi = 0; fi < e.fields.length; fi++) {
				let cell = e.cells.at[rel_ri * e.fields.length + fi]
				if (row) {
					let field = e.fields[fi]
					cell.ri = ri
					cell.fi = fi
					cell.x = cell_x(rel_ri, fi)
					cell.y = cell_y(rel_ri, fi)
					cell.w = cell_w(fi)
					cell.h = e.cell_h
					update_cell(cell, row, field)
					if (cell.indent)
						update_cell_tree_aspect(cell, ri, row, field)
					cell.show()
				} else {
					cell.clear()
					cell.hide()
				}
			}
		}
	}

	function update_viewport() {
		let sy = e.cells_view.scrollTop
		let sx = e.cells_view.scrollLeft
		sx = scroll_x(sx)
		sy = scroll_y(sy)
		e.scroll_x = sx
		e.scroll_y = sy
		update_header_pos(sx, sy)
		update_cells_pos(sx, sy)
		update_cells()
		update_focus()
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

	{
	let sx, sy, focused_ri
	function update_focus() {
		if (sx != null)
			each_cell_of_row(focused_ri, sx, sy, unfocus_cell)
		sx = e.scroll_x
		sy = e.scroll_y
		focused_ri = e.focused_row_index
		if (focused_ri != null)
			each_cell_of_row(focused_ri, sx, sy, focus_cell, e.focused_field_index, e.editor || false)
	}
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
			guide.h = e.header_h + e.cells_view_h
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
	function update_editor(editor, x, y) {
		let ri = e.focused_row_index
		let fi = e.focused_field_index
		let hcell = e.header.at[fi]
		let css = e.cells.at[0].css()
		let iw = cell_indent(e.rows[ri], e.fields[fi])
		editor.x = or(x, cell_x(ri, fi) + iw)
		editor.y = or(y, cell_y(ri, fi))
		editor.w = cell_w(fi) - num(css['border-right-width']) - iw
		editor.h = e.cell_h - num(css['border-bottom-width'])
	}

	let create_editor = e.create_editor
	e.create_editor = function(field, ...editor_options) {
		let editor = create_editor(field, {inner_label: false}, ...editor_options)
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

	e.update_cell_focus = function(ri, fi) {
		update_focus()
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
			each_cell_of_row(ri, null, null, function(cell, fi, cls, val) {
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

	// live column moving -----------------------------------------------------

	live_move_mixin(e)

	e.movable_element_size = function(fi) {
		return horiz ? cell_w(fi) : e.cell_h
	}

	function set_cell_x(cell, x) { cell.x = x }
	function set_cell_y(cell, y) { cell.y = y }
	e.set_movable_element_pos = function(fi, x) {
		each_cell_of_col(fi, horiz ? set_cell_x : set_cell_y, x)
		if (e.editor && e.focused_field_index == fi)
			update_editor(e.editor, horiz ? x : null, !horiz ? x : null)
	}

	// hit-testing and mouse-based moving & resizing --------------------------

	function ht_header_resize(mx, my, hit) {
		if (horiz) return
		let r = e.header.client_rect()
		let x = mx - r.right
		if (!(x >= -5 && x <= 5)) return
		hit.x = r.left + x
		return true
	}

	function mm_header_resize(mx, my, hit) {
		update_header_w(mx - hit.x)
	}

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
		let x = ((mx + 5) % e.cell_w) - 5
		if (!(x >= -5 && x <= 5)) return
		//hit.ri = floor(x / e.cell_w)
		//hit.x = x + e.cell_w * hit.ri
		return true
	}

	function ht_col_resize(mx, my, hit) {
		let r = e.cells_ct.client_rect()
		mx -= r.left
		my -= r.top
		if (horiz)
			return ht_col_resize_horiz(mx, my, hit)
		else
			return ht_col_resize_vert(mx, my, hit)
	}

	function mm_col_resize_horiz(mx, my, hit) {
		let w = mx - e.header.at[hit.fi]._x - hit.x
		set_col_w(hit.fi, w)
		update_cell_widths(true)
		update_resize_guides()
	}

	function mm_col_resize_vert(mx, my, hit) {

	}

	function mm_col_resize(mx, my, hit) {
		let r = e.cells_ct.client_rect()
		mx -= r.left
		my -= r.top
		if (horiz)
			return mm_col_resize_horiz(mx, my, hit)
		else
			return mm_col_resize_vert(mx, my, hit)
	}

	function ht_col_drag(mx, my, hit, ev) {
		let hcell_table = ev.target.closest('.x-grid-header-cell-table')
		if (!hcell_table) return
		hit.fi = hcell_table.parent.index
		hit.mx = ev.clientX
		hit.my = ev.clientY
		return true
	}

	function ht_col_move(mx, my, hit) {
		if ( horiz && abs(hit.mx - mx) < 8) return
		if (!horiz && abs(hit.my - my) < 8) return
		let r = e.header.client_rect()
		hit.mx -= r.left
		hit.my -= r.top
		hit.mx -= num(e.header.at[hit.fi].style.left)
		hit.my -= num(e.header.at[hit.fi].style.top)
		e.class('col-moving')
		each_cell_of_col(hit.fi, function(cell) {
			cell.class('col-moving')
			cell.style['z-index'] = 1
		})
		if (e.editor && e.focused_field_index == hit.fi)
			e.editor.class('col-moving')
		e.move_element_start(hit.fi, e.fields.length)
		return true
	}

	function mm_col_move(mx, my, hit) {
		let r = e.header.client_rect()
		mx -= r.left
		my -= r.top
		let x = horiz
			? mx - hit.mx
			: my - hit.my
		e.move_element_update(x)
	}

	function mu_col_move() {
		let over_fi = e.move_element_stop() // sets x of moved element.
		hit.state = 'col_moving_finish'
		after(.1, function() { // delay to allow the transition on x to finish.
			hit.state = null
			e.class('col-moving', false)
			each_cell_of_col(hit.fi, function(cell) {
				cell.class('col-moving', false)
				cell.style['z-index'] = null
			})
			if (e.editor)
				e.editor.class('col-moving', false)
			if (over_fi != hit.fi) {
				let focused_field = e.fields[e.focused_field_index]
				let field = e.fields.remove(hit.fi)
				e.fields.insert(over_fi, field)
				e.focused_field_index = focused_field && e.fields.indexOf(focused_field)
				e.init_fields()
				update_sizes()
				update_viewport()
			}
		})
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
		} else if (hit.state == 'col_moving_finish') {
			// just wait, timer will finish this.
		} else {
			hit.state = null
			e.class('col-resize', false)
			if (!e.disabled) {
				if (ht_header_resize(mx, my, hit)) {
					hit.state = 'header_resize'
					e.class('col-resize', true)
				} else if (ht_col_resize(mx, my, hit)) {
					hit.state = 'col_resize'
					e.class('col-resize', true)
				} else if (ht_col_drag(mx, my, hit, ev)) {
					hit.state = 'col_drag'
				}
			}
			if (hit.state)
				return false
		}
	}

	e.on('pointermove', pointermove)

	e.on('pointerdown', function(ev) {
		if (!hit.state)
			pointermove(ev.clientX, ev.clientY, ev)
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
		} else
			assert(false)
		this.setPointerCapture(ev.pointerId)
		return false
	})

	function pointerup(ev) {
		if (!hit.state)
			return
		this.releasePointerCapture(ev.pointerId)
		if (hit.state == 'header_resizing') {
			e.class('col-resizing', false)
			hit.state = null
			update_sizes()
			return false
		} else if (hit.state == 'col_resizing') {
			e.class('col-resizing', false)
			hit.state = null
			remove_resize_guides()
			update_sizes()
			return false
		} else if (hit.state == 'col_dragging') {
			if (e.can_sort_rows)
				e.set_order_by_dir(e.fields[hit.fi], 'toggle', ev.shiftKey)
			hit.state = null
			return false
		} else if (hit.state == 'col_moving') {
			mu_col_move()
			return false
		}
	}

	e.on('pointerup', pointerup)
	e.on('pointerleave', pointerup)

	e.cells.on('mousedown', function(ev) {
		if (hit.state)
			return

		let cell = ev.target.closest('.x-grid-cell')
		let indent = ev.target.closest('.x-grid-cell-indent')

		if (!e.hasfocus)
			e.focus()

		if (!cell)
			return

		let already_on_it =
			e.focused_row_index   == cell.ri &&
			e.focused_field_index == cell.fi

		if (indent)
			e.toggle_collapsed(cell.ri)

		if (!already_on_it)
			if (e.focus_cell(cell.ri, cell.fi, 0, 0, {must_not_move_row: true, input: e}))
				e.pick_val()
			else
				return

		if (!indent)
			if (e.enter_edit_on_click || already_on_it)
				// TODO: instead of `select_all`, put the caret where the mouse is.
				e.enter_edit('select_all')

		return false

	})

	e.on('contextmenu', function(ev) {
		let hcell = ev.target.closest('.x-grid-header-cell')
		if (!hcell) return
		context_menu_popup(hcell.index, ev.clientX, ev.clientY)
		return false
	})

	e.cells.on('dblclick', function(ev) {
		let cell = ev.target.closest('.x-grid-cell')
		if (!cell) return
		ev.row_index = cell.ri
		e.fire('cell_dblclick', e.rows[cell.ri], ev)
	})

	// keyboard bindings ------------------------------------------------------

	e.on('keydown', function(key, shift) {

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
			case 'PageUp'    : rows = -e.page_row_count; break
			case 'PageDown'  : rows =  e.page_row_count; break
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
			} else if (e.exit_edit()) {
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
				e.toggle_collapsed(e.focused_row_index)
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
			text: e.rowset.changed_rows ?
				S('discard_changes_and_reload', 'Discard changes and reload') : S('reload', 'Reload'),
			icon: 'fa fa-sync',
			action: function() {
				e.rowset.reload()
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

		if (horiz && e.can_change_filters_visibility)
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

		}

		context_menu = menu({items: items})
		let r = e.client_rect()
		let px = mx - r.left
		let py = my - r.top
		context_menu.popup(e, 'inner-top', null, px, py)
	}

})

vgrid = function(...options) {
	return grid({vertical: true}, ...options)
}

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

