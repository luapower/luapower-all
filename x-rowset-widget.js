
// ---------------------------------------------------------------------------
// rowset_widget mixin
// ---------------------------------------------------------------------------

/*
	rowset widgets must implement:
		init_rows()
		update_cell_state(ri, fi, prop, val, ev)
		update_row_state(ri, prop, val, ev)
		update_cell_focus(ri, [fi], ev)
		update_cell_editing(ri, [fi], editing)
		scroll_to_cell(ri, [fi])
*/

function rowset_widget(e) {

	e.can_edit = true
	e.can_add_rows = true
	e.can_remove_rows = true
	e.can_change_rows = true

	e.can_focus_cells = true
	e.auto_focus_first_cell = true   // focus first cell automatically on loading.
	e.auto_edit_first_cell = false   // automatically enter edit mode on loading.
	e.stay_in_edit_mode = true       // re-enter edit mode after navigating
	e.auto_advance_row = true        // jump row on horiz. navigation limits
	e.save_row_on = 'exit_edit'      // save row on 'input'|'exit_edit'|'exit_row'|false
	e.insert_row_on = 'exit_edit'    // insert row on 'input'|'exit_edit'|'exit_row'|false
	e.remove_row_on = 'input'        // remove row on 'input'|'exit_row'|false
	e.can_exit_edit_on_errors = true // allow exiting edit mode on validation errors
	e.can_exit_row_on_errors = false // allow changing row on validation errors
	e.exit_edit_on_lost_focus = true // exit edit mode when losing focus

	e.val_col = 0

	val_widget(e)

	// row -> row_index mapping -----------------------------------------------

	let rowmap

	e.row_index = function(row, ri) {
		if (!row)
			return null
		if (ri != null && ri != false)
			return ri
		if (row == e.focused_row) // most likely true (avoid maiking a rowmap).
			return e.focused_row_index
		if (!rowmap) {
			rowmap = new Map()
			for (let i = 0; i < e.rows.length; i++) {
				rowmap.set(e.rows[i], i)
			}
		}
		return rowmap.get(row)
	}

	e.rows_array_changed = function() {
		rowmap = null
	}

	// field -> field_index mapping -------------------------------------------

	let fieldmap

	e.field_index = function(field, fi) {
		if (!field)
			return null
		if (fi != null && fi != false)
			return fi
		if (field == e.focused_field) // most likely true (avoid maiking a fieldmap).
			return e.focused_field_index
		if (!fieldmap) {
			fieldmap = new Map()
			for (let i = 0; i < e.fields.length; i++) {
				fieldmap.set(e.fields[i], i)
			}
		}
		return fieldmap.get(field)
	}

	// rows array -------------------------------------------------------------

	e.init_rows_array = function() {
		e.rows = []
		if (!e.rowset)
			return
		let i = 0
		let passes = e.rowset.filter_rowsets_filter(e.filter_rowsets)
		for (let row of e.rowset.rows) {
			if (!row.parent_collapsed && passes(row))
				e.rows.push(row)
		}
		e.rows_array_changed()
	}

	// fields array -----------------------------------------------------------

	e.init_fields_array = function() {
		fieldmap = null
		e.fields = []
		if (!e.rowset)
			return
		e.val_field = e.rowset.field(e.val_col)
		e.tree_field = e.rowset.field(e.tree_col)
		if (e.cols) {
			for (let col of e.cols.split(' ')) {
				let field = e.rowset.field(col)
				if (field && field.visible != false) {
					e.fields.push(field)
					e.fields.last = field
				}
			}
		} else
			for (let field of e.rowset.fields)
				if (field.visible != false) {
					e.fields.push(field)
					e.fields.last = field
				}
	}

	// rowset binding ---------------------------------------------------------

	e.bind_rowset = function(on) {
		if (!e.rowset)
			return
		// structural changes
		e.rowset.on('loaded'      , rowset_loaded , on)
		e.rowset.on('row_added'   , row_added     , on)
		e.rowset.on('row_removed' , row_removed   , on)
		// state changes
		e.rowset.on('row_state_changed'    , row_state_changed    , on)
		e.rowset.on('cell_state_changed'   , cell_state_changed   , on)
		e.rowset.on('display_vals_changed' , display_vals_changed , on)
		// network events
		e.rowset.on('loading'       , rowset_loading       , on)
		e.rowset.on('load_slow'     , rowset_load_slow     , on)
		e.rowset.on('load_progress' , rowset_load_progress , on)
		e.rowset.on('load_fail'     , rowset_load_fail     , on)
		// misc.
		e.rowset.on('notify', e.notify, on)
		// take/release ownership of the rowset.
		e.rowset.bind_user_widget(e, on)
	}

	// adding & removing rows -------------------------------------------------

	e.insert_row = function(ri, focus_it, ev) {
		if (!e.can_edit || !e.can_add_rows)
			return false
		if (ri == true)
			ri = e.focused_row_index
		let parent_row = ri != null ? e.rows[ri].parent_row : null
		let adjust_ri = e.focused_row && ri != null
		if (adjust_ri)
			e.focused_row_index++
		let row = e.rowset.add_row(update({row_index: ri, focus_it: focus_it, parent_row: parent_row}, ev))
		if (!row && adjust_ri)
			e.focused_row_index--
		if (row && e.save_row_on && e.insert_row_on == 'input')
			e.save(row)
		return row
	}

	e.remove_row = function(ri, ev) {
		if (!e.can_edit || !e.can_remove_rows)
			return false
		let row = e.rowset.remove_row(e.rows[ri], update({row_index: ri}, ev))
		if (e.save_row_on && e.remove_row_on == 'input')
			e.save(row)
		return row
	}

	e.remove_focused_row = function(ev) {
		if (e.focused_row)
			return e.remove_row(e.focused_row_index, ev)
	}

	// responding to structural updates ---------------------------------------

	function init() {
		let was_editing = !!e.editor
		let focus_editor = e.editor && e.editor.hasfocus
		e.update_load_fail(false)
		free_editor()
		e.unbind_filter_rowsets()
		e.focused_row_index = null
		e.focused_field_index = null
		e.init_fields_array()
		e.init_rows_array()
		if (!e.rowset)
			return
		e.init_fields()
		e.sort()
		e.init_val()
		e.init_focused_cell({
			was_editing: was_editing,
			focus_editor: focus_editor,
		})
	}

	e.rowset_widget_init = function() {
		e.rowset = global_rowset(e.rowset_name || e.rowset, {param_nav: e.param_nav})
		if (e.rowset)
			e.rowset.load()
		e.init_nav()
		init()
	}

	e.rowset_widget_attach = function() {
		if (!e.rowset)
			return
		e.init_fields()
		e.init_rows()
		e.bind_rowset(true)
		e.bind_nav(true)
		e.init_val()
	}

	e.rowset_widget_detach = function() {
		if (!e.rowset)
			return
		e.bind_rowset(false)
		e.bind_nav(false)
	}

	e.set_rowset_name = function(rs) {
		e.bind_rowset(false)
		e.rowset = global_rowset(rs, {param_nav: e.param_nav})
		e.bind_rowset(true)
		e.rowset.load()
		init()
	}

	e.prop('rowset_name', {store: 'var', type: 'rowset', noinit: true})

	function rowset_loaded() {
		init()
	}

	function row_added(row, ev) {
		let ri = ev && ev.row_index
		if (ri != null)
			e.rows.insert(ri, row)
		else
			ri = e.rows.push(row)
		e.rows_array_changed()
		e.init_rows()
		if (ev && ev.focus_it)
			e.focus_cell(ri, true, 0, 0, ev)
	}

	function row_removed(row, ev) {
		let ri = ev && ev.row_index
		ri = e.row_index(row, ri)
		let n = 1
		if (row.parent_rows) {
			let min_parent_rows = row.parent_rows.length + 1
			while (1) {
				let row = e.rows[ri + n]
				if (!row || row.parent_rows.length < min_parent_rows)
					break
				n++
			}
		}
		e.rows.remove(ri, n)
		e.rows_array_changed()
		e.init_rows()
		if (ev && ev.refocus)
			if (!e.focus_cell(ri, true, 0, 0, ev))
				e.focus_cell(ri, true, -0, 0, ev)
	}

	// responding to cell updates ---------------------------------------------

	e.init_row = function(ri, ev) {
		let row = e.rows[ri]
		e.update_row_state(ri, 'row_is_new'   , !!row.is_new         , ev)
		e.update_row_state(ri, 'row_modified' , !!row.cells_modified , ev)
		e.update_row_state(ri, 'row_removed'  , !!row.removed        , ev)
	}

	e.init_cell = function(ri, fi, ev) {
		let row = e.rows[ri]
		let field = e.fields[fi]
		let rs = e.rowset
		e.update_cell_state(ri, fi, 'input_val'    , rs.input_val     (row, field), ev)
		e.update_cell_state(ri, fi, 'cell_error'   , rs.cell_error    (row, field), ev)
		e.update_cell_state(ri, fi, 'cell_modified', rs.cell_modified (row, field), ev)
	}

	function row_state_changed(row, prop, val, ev) {
		let ri = e.row_index(row, ev && ev.row_index)
		e.update_row_state(ri, prop, val, ev)
		if (row == e.focused_row) {
			e.fire('focused_row_state_changed', prop, val, ev)
			e.fire('focused_row_'+prop+'_changed', val, ev)
		}
	}

	function cell_state_changed(row, field, prop, val, ev) {
		let ri = e.row_index(row, ev && ev.row_index)
		let fi = e.field_index(field, ev && ev.field_index)
		e.update_cell_state(ri, fi, prop, val, ev)
		if (row == e.focused_row) {
			e.fire('focused_row_cell_state_changed_for_'+field.name, prop, val, ev)
			e.fire('focused_row_'+prop+'_changed_for_'+field.name, val, ev)
		}
	}

	function display_vals_changed(field) {
		e.init_rows()
	}

	// responding to notifications from rowset --------------------------------

	e.notify = function(type, message) {
		notify(message, type)
	}

	e.update_loading = function(on) { // stub
		if (!on) return
		e.load_overlay(true)
	}

	function rowset_loading(on) {
		e.class('loading', on)
		e.update_loading(on)
		e.update_load_progress(0)
	}

	e.update_load_progress = noop // stub

	function rowset_load_progress(p) {
		e.update_load_progress(p)
	}

	e.update_load_slow = function(on) { // stub
		if (on)
			e.load_overlay(true, 'waiting',
				S('slow', 'Still working on it...'),
				S('stop_waiting', 'Stop waiting'))
		else
			e.load_overlay(true, 'waiting',
				S('loading', 'Loading...'),
				S('stop_loading', 'Stop loading'))
	}

	function rowset_load_slow(on) {
		e.update_load_slow(on)
	}

	e.update_load_fail = function(on, error, type, status, message, body) {
		if (type == 'abort')
			e.load_overlay(false)
		else
			e.load_overlay(on, 'error', error, null, body)
	}

	function rowset_load_fail(...args) {
		e.update_load_fail(true, ...args)
	}

	// loading overlay --------------------------------------------------------

	{
	let oe
	e.load_overlay = function(on, cls, text, cancel_text, detail) {
		if (oe) {
			oe.remove()
			oe = null
		}
		e.disabled = on
		e.class('disabled', e.disabled)
		if (!on)
			return
		oe = overlay({class: 'x-loading-overlay'})
		oe.content.class('x-loading-overlay-message')
		if (cls)
			oe.class(cls)
		let focus_e
		if (cls == 'error') {
			let more_div = div({class: 'x-loading-overlay-detail'})
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
						e.load_overlay(false)
						e.rowset.reload()
					},
					forget_it: function() {
						e.load_overlay(false)
					},
				},
			})
			band.at[1].hide()
			let error_icon = span({class: 'x-loading-error-icon fa fa-exclamation-circle'})
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

	// navigating -------------------------------------------------------------

	e.can_change_val = function(row, field) {
		return e.can_edit && e.can_change_rows
			&& e.rowset.can_change_val(row, field)
	}

	e.is_cell_disabled = function(row, field) {
		return !e.rowset.can_focus_cell(row, field)
	}

	e.can_focus_cell = function(row, field, for_editing) {
		return (field == null || e.can_focus_cells)
			&& e.rowset.can_focus_cell(row, field)
			&& (!for_editing || e.can_change_val(row, field))
	}

	e.focused_row_index = null
	e.focused_field_index = null
	e.focused_field_name = null

	e.property('focused_row', function() {
		return e.rows[e.focused_row_index]
	})

	e.property('focused_field', function() {
		return e.fields[e.focused_field_index]
	})

	e.first_focusable_cell = function(ri, fi, rows, cols, options) {

		if (ri === true) ri = e.focused_row_index
		if (fi === true) fi = e.field_index(e.rowset.field(e.focused_field_name))
		rows = or(rows, 0) // by default find the first focusable row.
		cols = or(cols, 0) // by default find the first focusable col.

		let editable = options && options.editable // skip non-editable cells.
		let must_move = options && options.must_move // return only if moved.
		let must_not_move_row = options && options.must_not_move_row // return only if row not moved.
		let must_not_move_col = options && options.must_not_move_col // return only if col not moved.

		let ri_inc = strict_sign(rows)
		let fi_inc = strict_sign(cols)
		rows = abs(rows)
		cols = abs(cols)

		// if starting from nowhere, include the first/last row/col into the count.
		if (ri == null && rows)
			rows--
		if (fi == null && cols)
			cols--

		let move_row = rows >= 1
		let move_col = cols >= 1
		let start_ri = ri
		let start_fi = fi

		// the default cell is the first or the last depending on direction.
		ri = or(ri, ri_inc * -1/0)
		fi = or(fi, fi_inc * -1/0)

		// clamp out-of-bound row/col indices.
		ri = clamp(ri, 0, e.rows.length-1)
		fi = clamp(fi, 0, e.fields.length-1)

		let last_valid_ri = null
		let last_valid_fi = null
		let last_valid_row

		// find the last valid row, stopping after the specified row count.
		if (e.can_focus_cell(null, null, editable))
			while (ri >= 0 && ri < e.rows.length) {
				let row = e.rows[ri]
				if (e.can_focus_cell(row, null, editable)) {
					last_valid_ri = ri
					last_valid_row = row
					if (rows <= 0)
						break
				}
				rows--
				ri += ri_inc
			}

		if (last_valid_ri == null)
			return [null, null]

		// if wanted to move the row but couldn't, don't move the col either.
		let row_moved = last_valid_ri != start_ri
		if (move_row && !row_moved)
			cols = 0

		while (fi >= 0 && fi < e.fields.length) {
			let field = e.fields[fi]
			if (e.can_focus_cell(last_valid_row, field, editable)) {4
				last_valid_fi = fi
				if (cols <= 0)
					break
			}
			cols--
			fi += fi_inc
		}

		let col_moved = last_valid_fi != start_fi

		if (must_move && !(row_moved || col_moved))
			return [null, null]

		if ((must_not_move_row && row_moved) || (must_not_move_col && col_moved))
			return [null, null]

		return [last_valid_ri, last_valid_fi]
	}

	e.focus_cell = function(ri, fi, rows, cols, ev) {

		if (ri === false || fi === false) // false means unfocus.
			return e.focus_cell(
				ri === false ? null : ri,
				fi === false ? null : fi, 0, 0,
				update({
					must_not_move_row: ri === false,
					must_not_move_col: fi === false,
					unfocus_if_not_found: true,
				}, ev)
			)

		let was_editing = (ev && ev.was_editing) || !!e.editor
		let focus_editor = (ev && ev.focus_editor) || (e.editor && e.editor.hasfocus)
		let enter_edit = (ev && ev.enter_edit) || (was_editing && e.stay_in_edit_mode)
		let editable = (ev && ev.editable) || enter_edit

		let opt = update({editable: editable}, ev)
		;[ri, fi] = e.first_focusable_cell(ri, fi, rows, cols, opt)

		if (ri == null) // failure to find row means cancel.
			if (!(ev && ev.unfocus_if_not_found))
				return false

		let row_changed = e.focused_row_index != ri
		let field_changed = e.focused_field_index != fi

		if (row_changed) {
			if (!e.exit_focused_row())
				return false
		} else if (field_changed) {
			if (!e.exit_edit())
				return false
		}

		if (row_changed || field_changed) {
			let old_focused_row = e.focused_row
			e.focused_row_index   = ri
			e.focused_field_index = fi
			if (fi != null)
				e.focused_field_name = e.fields[fi].name
			e.update_cell_focus(ri, fi, ev)
			let row = e.rows[ri]
			let val = row && e.val_field ? e.rowset.val(row, e.val_field) : null
			e.set_val(val, update({input: e}, ev))
			if (row_changed)
				e.fire('focused_row_changed', row, old_focused_row, ev)

		}

		if (enter_edit && ri != null && fi != null)
			e.enter_edit(ev && ev.editor_state, focus_editor || false)

		if (ri != null)
			if (!(ev && ev.make_visible == false))
				if (e.isConnected)
					e.scroll_to_cell(ri, fi)

		return true
	}

	e.focus_next_cell = function(cols, ev) {
		let dir = strict_sign(cols)
		let auto_advance_row = ev && ev.auto_advance_row || e.auto_advance_row
		return e.focus_cell(true, true, dir * 0, cols, update({must_move: true}, ev))
			|| (auto_advance_row && e.focus_cell(true, true, dir, dir * -1/0, ev))
	}

	e.is_last_row_focused = function() {
		let [ri] = e.first_focusable_cell(true, true, 1, 0, {must_move: true})
		return ri == null
	}

	e.init_focused_cell = function(ev) {
		e.focus_cell(true, true, 0, 0, update({
			must_not_move_row: !e.auto_focus_first_cell,
			enter_edit: e.auto_edit_first_cell,
		}, ev))
	}

	// responding to val changes ----------------------------------------------

	e.update_val = function(v, ev) {
		if (ev && ev.input == e)
			return // coming from focus_cell(), avoid recursion.
		if (!e.val_field)
			return // fields not initialized yet.
		let row = e.rowset.lookup(e.val_field, v)
		let ri = e.row_index(row)
		e.focus_cell(ri, true, 0, 0,
			update({must_not_move_row: true, unfocus_if_not_found: true}, ev))
	}

	// editing ----------------------------------------------------------------

	e.editor = null

	e.create_editor = function(field, ...editor_options) {
		return e.rowset.create_editor(field, {
			nav: e,
			field: field,
		}, ...editor_options)
	}

	e.enter_edit = function(editor_state, focus) {
		if (e.editor)
			return true
		if (!e.can_focus_cell(e.focused_row, e.focused_field, true))
			return false
		e.editor = e.create_editor(e.focused_field)
		if (!e.editor)
			return false
		e.update_cell_editing(e.focused_row_index, e.focused_field_index, true)
		e.editor.on('lost_focus', editor_lost_focus)
		if (e.editor.enter_editor)
			e.editor.enter_editor(editor_state)
		if (focus != false)
			e.editor.focus()
		return true
	}

	function free_editor() {
		let editor = e.editor
		if (editor) {
			e.editor = null // removing the editor first as a barrier for lost_focus().
			editor.remove()
		}
	}

	e.exit_edit = function() {
		if (!e.editor)
			return true

		if (!e.can_exit_edit_on_errors && e.rowset.row_has_errors(e.focused_row))
			return false

		if (!e.fire('exit_edit', e.focused_row_index, e.focused_field_index))
			return false

		if (e.save_row_on == 'exit_edit')
			e.save(e.focused_row)

		if (!e.can_exit_row_on_errors && e.rowset.row_has_errors(e.focused_row))
			return false

		let had_focus = e.hasfocus
		free_editor()
		e.update_cell_editing(e.focused_row_index, e.focused_field_index, false)
		if (had_focus)
			e.focus()

		return true
	}

	function editor_lost_focus(ev) {
		if (!e.editor) // editor is being removed.
			return
		if (ev.target != e.editor) // other input that bubbled up.
			return
		if (e.exit_edit_on_lost_focus)
			e.exit_edit()
	}

	e.exit_focused_row = function() {
		let row = e.focused_row
		if (!row)
			return true
		if (!e.exit_edit())
			return false
		if (row.cells_modified) {
			let err = e.rowset.validate_row(row)
			e.rowset.set_row_error(row, err)
		}
		if (!e.can_exit_row_on_errors && e.rowset.row_has_errors(row))
			return false
		if (e.save_row_on == 'exit_row'
			|| (e.save_row_on && row.is_new  && e.insert_row_on == 'exit_row')
			|| (e.save_row_on && row.removed && e.remove_row_on == 'exit_row')
		) {
			e.save(row)
		}
		return true
	}

	e.save = function(row) {
		e.rowset.save(row)
	}

	// sorting ----------------------------------------------------------------

	let order_by = new Map()

	e.late_property('order_by',
		function() {
			let a = []
			for (let [field, dir] of order_by) {
				a.push(field.name + (dir == 'asc' ? '' : ' desc'))
			}
			return a.join(', ')
		},
		function(s) {
			order_by = new Map()
			for (let s1 of s.split(/\s+/)) {
				let m = s1.split(':')
				let name = m[0]
				let field = e.rowset.field(name)
				if (field && field.sortable) {
					let dir = m[1] || 'asc'
					if (dir == 'asc' || dir == 'desc')
						order_by.set(field, dir)
				}
			}
			e.sort()
		}
	)

	e.order_by_priority = function(field) {
		let i = order_by.size-1
		for (let [field1] of order_by) {
			if (field1 == field)
				return i
			i--
		}
	}

	e.order_by_dir = function(field) {
		return order_by.get(field)
	}

	e.set_order_by_dir = function(field, dir, keep_others) {
		if (!field.sortable)
			return
		if (dir == 'toggle') {
			dir = order_by.get(field)
			dir = dir == 'asc' ? 'desc' : (dir == 'desc' ? false : 'asc')
		}
		if (!keep_others)
			order_by.clear()
		if (dir)
			order_by.set(field, dir)
		else
			order_by.delete(field)
		e.sort()
	}

	e.clear_order = function() {
		order_by.clear()
		e.sort()
	}

	e.sort = function(focused_row) {
		focused_row = or(focused_row, e.focused_row)
		if (e.rowset.parent_field || (order_by && order_by.size)) {
			let cmp = e.rowset.comparator(order_by)
			e.rows.sort(cmp)
		} else
			e.init_rows_array()
		e.rows_array_changed()
		e.focused_row_index = null // avoid row_index()'s short circuit.
		e.focused_row_index = e.row_index(focused_row)
		e.init_rows()
		if (e.focused_row_index != null)
			if (e.isConnected)
				e.scroll_to_cell(e.focused_row_index, e.focused_cell_index)
		e.fire('sort_order_changed')
	}

	// row collapsing ---------------------------------------------------------

	e.set_collapsed = function(ri, collapsed) {
		let row = e.rows[ri]
		if (!row.child_row_count)
			return
		let focused_row = e.focused_row
		e.rowset.set_collapsed(row, collapsed)
		e.init_rows_array()
		e.sort(focused_row)
	}

	e.toggle_collapsed = function(ri) {
		e.set_collapsed(ri, !e.rows[ri].collapsed)
	}

	// row moving -------------------------------------------------------------

	e.move_row = function(ri0, ri1) {
		if (ri0 == ri1)
			return

		let index_field = e.rowset.field(e.index_col)
		if (index_field) {
			// NOTE: this is simple like this because ri1 comes as the index
			// over which to move the row which is the index _after_ the removal
			// of the row at ri0 from the array.
			let min_ri = min(ri0, ri1)
			let max_ri = max(ri0, ri1)
			let index = e.rowset.val(e.rows[min_ri], index_field)
			for (let ri = min_ri; ri <= max_ri; ri++)
				e.rowset.set_val(e.rows[ri], index_field, index++)
		}

		if (e.rowset.parent_field) {
			e.rowset.set_val(e.rows[ri0], e.rowset.parent_field,
				e.rowset.val(e.rows[ri1], e.rowset.parent_field))
			e.rowset.init_parents()
			e.sort()
		}

		let row = e.rows[ri0]
		e.rows.remove(ri0)
		e.rows.insert(ri1, row)
		e.rows_array_changed()
	}

	// filtering --------------------------------------------------------------

	e.unbind_filter_rowsets = function() {
		if (!e.filter_rowsets)
			return
		for (let [field, rs] of e.filter_rowsets) {
			//TODO: rs.unbind()
		}
		e.filter_rowsets = null
	}

	e.filter_rowset = function(field) {
		e.filter_rowsets = e.filter_rowsets || new Map()
		let rs = e.filter_rowsets.get(field)
		if (!rs) {
			rs = e.rowset.filter_rowset(field, {
				field_attrs: {'0': {w: 20}},
			})
			e.filter_rowsets.set(field, rs)
		}
		return rs
	}

	// crude quick-search only for the first letter ---------------------------

	let found_row_index
	function quicksearch(c, field, again) {
		if (e.focused_row_index != found_row_index)
			found_row_index = null // user changed selection, start over.
		let ri = found_row_index != null ? found_row_index+1 : 0
		if (ri >= e.rows.length)
			ri = null
		while (ri != null) {
			let s = e.rowset.display_val(e.rows[ri], field)
			if (s.starts(c.lower()) || s.starts(c.upper())) {
				e.focus_cell(ri, true, 0, 0, {input: e})
				break
			}
			ri++
			if (ri >= e.rows.length)
				ri = null
		}
		found_row_index = ri
		if (found_row_index == null && !again)
			quicksearch(c, field, true)
	}

	e.quicksearch = function(c, field) {
		field = field
			||	e.quicksearch_field
			|| (e.quicksearch_col && e.rowset.field(e.quicksearch_col))
		if (field)
			quicksearch(c, field)
	}

	// picker protocol --------------------------------------------------------

	e.pick_near_val = function(delta, ev) {
		if (e.focus_cell(true, true, delta, 0, ev))
			e.fire('val_picked', ev)
	}

	// xmodule protocol -------------------------------------------------------

	e.inspect_fields = [

		{name: 'can_edit', type: 'bool'},
		{name: 'can_add_rows', type: 'bool'},
		{name: 'can_remove_rows', type: 'bool'},
		{name: 'can_change_rows', type: 'bool'},
		{name: 'can_focus_cells', type: 'bool'},
		{name: 'auto_focus_first_cell', type: 'bool'},
		{name: 'auto_edit_first_cell', type: 'bool'},
		{name: 'auto_advance_row', type: 'bool'},
		{name: 'save_row_on', type: 'enum', enum_values: ['input', 'exit_edit', 'exit_row', false]},
		{name: 'insert_row_on', type: 'enum', enum_values: ['input', 'exit_edit', 'exit_row', false]},
		{name: 'remove_row_on', type: 'enum', enum_values: ['input', 'exit_row', false]},
		{name: 'can_exit_edit_on_errors', type: 'bool'},
		{name: 'can_exit_row_on_errors', type: 'bool'},
		{name: 'exit_edit_on_lost_focus', type: 'bool'},

	]

}

