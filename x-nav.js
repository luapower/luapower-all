
/* ---------------------------------------------------------------------------
//	nav widget mixin
// ---------------------------------------------------------------------------

implements:
	val widget mixin.

typing:
	isnav: t

rowset:
	needs:
		e.static_rowset
		e.rowset_vals
		e.rowset <- {fields: [field1,...], rows: [row1,...]}
	publishes:
		e.reset()

rowset field attributes:

	identification:
		name           : field name (defaults to field's numeric index)
		type           : for choosing a field preset.

	rendering:
		text           : field name for display purposes (auto-generated default).
		visible        : field can be visible in a grid (true).
		w              : field's width.
		min_w          : field's minimum width.
		max_w          : field's maximum width.

	navigation:
		focusable      : field can be focused (true).

	editing:
		client_default : default value that new rows are initialized with.
		default        : default value that the server sets for new rows.
		editable       : allow modifying (true).
		editor         : f({nav:, col:}, ...opt) -> editor instance
		from_text      : f(s) -> v
		to_text        : f(v) -> s
		enum_values    : [v1, ...]

	validation:
		allow_null     : allow null (true).
		validate       : f(v, field) -> undefined|err_string
		convert        : f(v) -> v
		min            : min value (0).
		max            : max value (inf).
		maxlen         : max text length (256).
		multiple_of    : number that the value must be multiple of (1).
		max_digits     : max number of digits allowed.
		max_decimals   : max number of decimals allowed.

	formatting:
		align          : 'left'|'right'|'center'
		format         : f(v, row) -> s
		date_format    : toLocaleString format options for the date type
		true_text      : display value for boolean true
		false_text     : display value for boolean false
		null_text      : display value for null
		empty_text     : display value for ''

	vlookup:
		lookup_nav     : nav to look up values of this field into.
		lookup_nav_gid : nav gid for creating lookup_nav.
		lookup_col     : field in lookup_nav that matches this field.
		display_col    : field in lookup_nav to use as display_val of this field.
		lookup_failed_display_val : f(v) -> s; what to use when lookup fails.

	sorting:
		sortable       : allow sorting (true).
		compare_types  : f(v1, v2) -> -1|0|1  (for sorting)
		compare_values : f(v1, v2) -> -1|0|1  (for sorting)

rowset row attributes:
	row[i]             : current cell value (always valid).
	row.focusable      : row can be focused (true).
	row.editable       : allow modifying (true).
	row[input_val_i]   : currently set cell value, whether valid or not.
	row[error_i]       : error message if cell is invalid.
	row.error          : error message if row is invalid.
	row[modified_i]    : value was modified, change not on server yet.
	row[old_val_i]     : initial value before modifying.
	row.is_new         : new row, not added on server yet.
	row.modified       : one or more row cells were modified.
	row.removed        : removed row, not removed on server yet.

fields:
	publishes:
		e.all_fields[col|fi] -> field
		e.add_field(field)
		e.remove_field(field)

visible fields:
	publishes:
		e.fields[fi] -> field
		e.field_index(field) -> fi
		e.show_field(field, on, at_fi)
		e.move_field(fi, over_fi)

rows:
	publishes:
		e.all_rows[ri] -> row
		e.rows[ri] -> row
		e.row_index(row) -> ri

indexing:
	e.index_tree()
	e.lookup()
	e.row_group()

master-detail:
	needs:
		e.params <- 'param1[=master_col1] ...'
		e.param_nav
		e.param_nav_gid

tree:
	needs:
		e.tree_col
		e.name_col
	publishes:
		e.each_child_row(row, f)
		e.expanded_child_row_count(ri) -> n

focusing and selection:
	publishes:
		e.focused_row, e.focused_field
		e.selected_row, e.selected_field
		e.last_focused_col
		e.selected_rows: Map(row -> true|Set(field))
		e.focus_cell()
		e.focus_next_cell()
		e.select_all_cells()
	calls:
		e.can_change_val()
		e.can_focus_cell()
		e.is_cell_disabled()
		e.can_select_cell()
		e.is_row_selected()
		e.is_last_row_focused()
		e.first_focusable_cell()

scrolling:
	publishes:
		e.scroll_to_focused_cell()
	calls:
		e.scroll_to_cell(ri, [fi])

sorting:
	publishes:
		e.order_by <- 'col1[:desc] ...'
	calls:
		e.compare_rows(row1, row2)
		e.compare_types(v1, v2)
		e.compare_vals(v1, v2)

quicksearch:
	e.quicksearch()

tree node collapsing:
	e.set_collapsed()
	e.toggle_collapsed()

row adding, removing, moving:
	publishes:
		e.remove_rows()
		e.remove_selected_rows()
		e.insert_rows()
		e.start_move_selected_rows() -> state; state.finish()
	calls:
		e.can_remove_row()

cell values & state:
	publishes:
		e.cell_state()
		e.cell_val()
		e.cell_input_val()
		e.cell_old_val()
		e.cell_prev_val()
		e.cell_error()
		e.cell_modified()
		e.cell_vals()

updating cells:
	publishes:
		e.set_cell_state()
		e.validate_val()
		e.on_validate_val()
		e.set_cell_val()
		e.reset_cell_val()
	calls:
		e.do_update_cell_state(ri, fi, prop, val, ev)
		e.do_update_cell_editing(ri, [fi], editing)

row state:
	publishes:
		row.<key>
		e.row_has_errors()
		e.row_can_have_children()

updating row state:
	publishes:
		e.set_row_state()
		e.validate_row()
		e.set_row_error()
		e.set_row_is_new()
	calls:
		e.do_update_row_state(ri, prop, val, ev)

updating rowset:
	publishes:
		e.commit_changes()
		e.revert_changes()
		e.set_null_selected_cells()

editing:
	publishes:
		e.editor
		e.enter_edit()
		e.exit_edit()
		e.exit_focused_row()
	calls:
		e.do_create_editor()

loading & saving:
	needs:
		e.rowset_name
		e.rowset_url
	publishes:
		e.can_save_changes()
		e.reload()
		e.abort_loading()
		e.save()
	calls:
		e.notify()
		e.do_update_loading()
		e.do_update_load_progress()
		e.do_update_load_slow()
		e.do_update_load_fail()
		e.load_overlay()

display val & text val:
	publishes:
		e.cell_display_val_for()
		e.cell_display_val()
		e.cell_text_val()
		e.'display_vals_changed'
		e.'display_vals_changed_for_<col>'

picker:
	publishes:
		e.display_col
		e.row_display_val()
		e.dropdown_display_val()
		e.pick_near_val()

server-side properties:
	publishes:
		e.sql_select_all
		e.sql_select
		e.sql_select_one
		e.sql_select_one_update
		e.sql_pk
		e.sql_insert_fields
		e.sql_update_fields
		e.sql_where
		e.sql_where_row
		e.sql_where_row_update
		e.sql_schema
		e.sql_db

field_types : {type -> {attr->val}}

--------------------------------------------------------------------------- */

{
	let upper = function(s) {
		return s.toUpperCase()
	}
	let upper2 = function(s) {
		return ' ' + s.slice(1).toUpperCase()
	}
	function auto_display_name(s) {
		return (s || '').replace(/[\w]/, upper).replace(/(_[\w])/g, upper2)
	}
}

function nav_widget(e) {

	e.isnav = true // for resolver

	e.prop('can_edit'                , {store: 'var', type: 'bool', default: true, hint: 'can change anything at all'})
	e.prop('can_add_rows'            , {store: 'var', type: 'bool', default: true})
	e.prop('can_remove_rows'         , {store: 'var', type: 'bool', default: true})
	e.prop('can_change_rows'         , {store: 'var', type: 'bool', default: true})
	e.prop('can_move_rows'           , {store: 'var', type: 'bool', default: true})
	e.prop('can_sort_rows'           , {store: 'var', type: 'bool', default: true})
	e.prop('can_focus_cells'         , {store: 'var', type: 'bool', default: true , hint: 'can focus individual cells vs entire rows'})
	e.prop('can_select_multiple'     , {store: 'var', type: 'bool', default: true})
	e.prop('can_select_non_siblings' , {store: 'var', type: 'bool', default: true})
	e.prop('auto_focus_first_cell'   , {store: 'var', type: 'bool', default: true , hint: 'focus first cell automatically on loading'})
	e.prop('auto_edit_first_cell'    , {store: 'var', type: 'bool', default: false, hint: 'automatically enter edit mode on loading'})
	e.prop('stay_in_edit_mode'       , {store: 'var', type: 'bool', default: true , hint: 're-enter edit mode after navigating'})
	e.prop('auto_advance_row'        , {store: 'var', type: 'bool', default: false, hint: 'jump row on horizontal navigation limits'})
	e.prop('save_row_on'             , {store: 'var', type: 'enum', default: 'exit_edit', enum_values: ['input', 'exit_edit', 'exit_row', 'manual']})
	e.prop('save_new_row_on'         , {store: 'var', type: 'enum', default: 'exit_edit', enum_values: ['input', 'exit_edit', 'exit_row', 'manual']})
	e.prop('save_row_remove_on'      , {store: 'var', type: 'enum', default: 'input'    , enum_values: ['input', 'exit_row', 'manual']})
	e.prop('save_row_move_on'        , {store: 'var', type: 'enum', default: 'input'    , enum_values: ['input', 'manual']})
	e.prop('can_exit_edit_on_errors' , {store: 'var', type: 'bool', default: true , hint: 'allow exiting edit mode on validation errors'})
	e.prop('can_exit_row_on_errors'  , {store: 'var', type: 'bool', default: false, hint: 'allow changing row on validation errors'})
	e.prop('exit_edit_on_lost_focus' , {store: 'var', type: 'bool', default: false, hint: 'exit edit mode when losing focus'})
	e.prop('save_row_states'         , {store: 'var', type: 'bool', default: false})
	e.prop('action_band_visible'     , {store: 'var', type: 'enum', enum_values: ['auto', 'always', 'no'], default: 'auto'})

	// init -------------------------------------------------------------------

	function init_all() {
		init_all_fields()
	}

	function force_unfocus_focused_cell() {
		assert(e.focus_cell(false, false, 0, 0, {force_exit_edit: true}))
	}

	e.on('bind', function(on) {
		bind_param_nav(on)
		if (on) {
			e.update({reload: true})
		} else {
			abort_ajax_requests()
			force_unfocus_focused_cell()
			init_all()
		}
	})

	e.set_static_rowset = function(rs) {
		e.rowset = rs
		e.reload()
	}
	e.prop('static_rowset', {store: 'var'})

	e.set_row_vals = function() {
		if (save_barrier) return
		e.reload()
	}
	e.prop('row_vals', {store: 'var', slot: 'app'})

	e.set_row_states = function() {
		if (save_barrier) return
		e.reload()
	}
	e.prop('row_states', {store: 'var', slot: 'app'})

	e.set_rowset_name = function(v) {
		e.rowset_url = v ? 'rowset.json/' + v : null
		e.reload()
	}
	e.prop('rowset_name', {store: 'var', type: 'rowset'})

	e.set_rowset_gid = function(v) {
		e.rowset = xmodule.rowset(v)
		e.reload()
	}
	e.prop('rowset_gid', {store: 'var', type: 'rowset'})

	// utils ------------------------------------------------------------------

	let fld     = col => typeof col == 'string' ? e.all_fields[col] : col
	let fldname = col => typeof col == 'string' ? col : col.name

	let is_not_null = v => v != null
	function flds(cols) {
		let fields = typeof cols == 'string' ? cols.split(/\s+/).map(fld).filter(is_not_null) : cols
		return fields.length ? fields : null
	}

	e.fldnames = function(cols) {
		if (typeof cols == 'string') // 'col1 ...' (preferred)
			return cols
		if (typeof cols == 'number') // fi
			return e.all_fields[cols].name
		else if (isobject(cols)) // field
			return cols.name
		else if (isarray(cols)) // [col1|field1,...]
			return cols.map(fldname).join(' ')
	}

	e.fld = fld
	e.flds = flds

	// fields array matching 1:1 to row contents ------------------------------

	let convert_field_attr = {}

	convert_field_attr.text = function(field, v, f) {
		return v == null ? auto_display_name(f.name) : v
	}

	convert_field_attr.w = function(field, v) {
		return clamp(v, field.min_w, field.max_w)
	}

	convert_field_attr.exclude_vals = function(field, v) {
		set_exclude_filter(field, v)
		return v
	}

	function init_field_attrs(field, f, name) {

		let pt = e.prop_col_attrs && e.prop_col_attrs[name]
		let ct = e.col_attrs && e.col_attrs[name]
		let type = f.type || (ct && ct.type)
		let tt = field_types[type]
		let att = all_field_types

		update(field, att, tt, f, ct, pt)

		for (let k in convert_field_attr)
			field[k] = convert_field_attr[k](field, field[k], f)

	}

	function set_field_attr(field, k, v) {

		let f = e.rowset.fields[field.val_index]

		if (v === undefined) {

			let ct = e.col_attrs && e.col_attrs[field.name]
			let type = f.type || (ct && ct.type)
			let tt = type && field_types[type]
			let att = all_field_types

			v = ct && ct[k]
			v = strict_or(v, f[k])
			v = strict_or(v, tt && tt[k])
			v = strict_or(v, att[k])
		}

		let convert = convert_field_attr[k]
		if (convert)
			v = convert(field, v, f)

		if (field[k] === v)
			return
		field[k] = v

	}

	function init_field(f, fi) {

		// disambiguate field name.
		let name = (f.name || 'f'+fi).replaceAll(' ', '_')
		if (name in e.all_fields) {
			let suffix = 2
			while (name+suffix in e.all_fields)
				suffix++
			name += suffix
		}

		let field = {}

		init_field_attrs(field, f, name)

		field.name = name
		field.val_index = fi
		field.nav = e

		e.all_fields[fi] = field
		e.all_fields[name] = field

		return field
	}

	e.add_field = function(f) {
		let fn = e.all_fields.length
		let field = init_field(f, fn)
		for (let ri = 0; ri < e.all_rows.length; ri++) {
			let row = e.all_rows[ri]
			// append a val slot to the row.
			row.splice(fn, 0, null)
			// insert a slot into all cell_state sub-arrays of the row.
			fn++
			for (let i = 2 * fn; i < row.length; i += fn)
				row.splice(i, 0, null)
		}
		init_fields()
		e.update({fields: true})
		return field
	}

	e.remove_field = function(field) {
		let fi = field.val_index
		e.all_fields.remove(fi)
		delete e.all_fields[field.name]
		for (let i = fi; i < e.all_fields.length; i++)
			e.all_fields[i].val_index = i
		let fn = e.all_fields.length
		for (let row of e.all_rows) {
			// remove the val slot of the row.
			row.splice(fi, 1)
			// remove all cell_state slots of the row for this field.
			for (let i = fn + 1 + fi; i < row.length; i += fn)
				row.splice(i, 1)
		}
		init_fields()
		e.update({fields: true})
	}

	function init_all_fields() {

		if (e.all_fields) {

			for (let field of e.all_fields)
				if (field.editor_instance)
					field.editor_instance.remove()

			bind_lookup_navs(false)
		}

		e.all_fields = [] // fields in row value order.

		let rs = e.rowset || empty

		// not creating fields and rows unless attached because we don't get
		// events while not attached so the nav might get stale.
		if (e.attached)
			if (rs.fields)
				for (let fi = 0; fi < rs.fields.length; fi++)
					init_field(rs.fields[fi], fi)

		bind_lookup_navs(true)

		e.pk = e.attached ? (isarray(rs.pk) ? rs.pk.join(' ') : rs.pk) : null
		e.id_field = e.pk && e.all_fields[e.pk.split(/\s+/)[0]]
		e.parent_field = e.id_field && e.all_fields[rs.parent_col]
		init_tree_field()

		e.val_field   = e.all_fields[e.val_col]
		e.index_field = e.all_fields[rs.index_col]

		init_fields()

		init_all_rows()
	}

	// `*_col` properties

	function init_tree_field() {
		let rs = e.rowset || empty
		e.tree_field = or(e.all_fields[or(e.tree_col, e.name_col)], or(rs.tree_col, rs.name_col))
	}

	e.set_val_col = function(v) {
		e.val_field = e.all_fields[v]
		if (e.val_field)
			e.update()
	}
	e.prop('val_col', {store: 'var'})

	e.set_tree_col = function() {
		init_tree_field(e)
		init_fields()
		e.update({rows: true})
	}
	e.prop('tree_col', {store: 'var'})

	e.set_name_col = function(v) {
		e.name_field = e.all_fields[v]
		if (!e.tree_col)
			e.set_tree_col()
	}
	e.prop('name_col', {store: 'var'})

	e.set_quicksearch_col = function(v) {
		e.quicksearch_field = e.all_fields[v]
		reset_quicksearch()
		e.update({state: true})
	}
	e.prop('quicksearch_col', {store: 'var'})

	// field attributes exposed as `col.*` props

	function get_col_attr(col, k) {
		return e.prop_col_attrs && e.prop_col_attrs[col] ? e.prop_col_attrs[col][k] : undefined
	}

	function set_col_attr(prop, col, k, v) {
		let v0 = get_col_attr(col, k)
		if (v === v0)
			return
		attr(attr(e, 'prop_col_attrs'), col)[k] = v

		let field = e.all_fields[col]
		if (field) {
			set_field_attr(field, k, v)
			e.update({fields: true})
		}

		e.fire('col_attr_changed', col, k, v)
		e.fire('col_'+k+'_changed_for_'+col, col, k, v)

		let attrs = field_prop_attrs[k]
		let slot = attrs && attrs.slot
		document.fire('prop_changed', e, prop, v, v0, slot)
	}

	function parse_col_prop_name(prop) {
		let [_, col, k] = prop.match(/^col\.([^\.]+)\.(.*)/)
		return [col, k]
	}

	e.get_prop = function(prop) {
		if (prop.starts('col.')) {
			let [col, k] = parse_col_prop_name(prop)
			return get_col_attr(col, k)
		}
		return e[prop]
	}

	e.set_prop = function(prop, v) {
		if (prop.starts('col.')) {
			let [col, k] = parse_col_prop_name(prop)
			set_col_attr(prop, col, k, v)
			return
		}
		e[prop] = v
	}

	e.get_prop_attrs = function(prop) {
		if (prop.starts('col.')) {
			let [col, k] = parse_col_prop_name(prop)
			return field_prop_attrs[k]
		}
		return e.props[prop]
	}

	// all_fields subset in custom order --------------------------------------

	function init_fields() {
		e.fields = []
		if (e.all_fields.length)
			for (let col of cols_array()) {
				let field = e.all_fields[col]
				if (!field)
					print('col not found', col)
				else if (field.visible != false)
					e.fields.push(field)
			}
		update_field_index()
		update_field_sort_order()

		// remove references to invisible fields.
		if (e.focused_field && e.focused_field.index == null)
			e.focused_field = null
		if (e.selected_field && e.selected_field.index == null)
			e.selected_field = null
		let lff = e.all_fields[e.last_focused_col]
		if (lff && lff.index == null)
			e.last_focused_col = null
		if (e.quicksearch_field && e.quicksearch_field.index == null)
			reset_quicksearch()
		if (e.selected_rows)
			for (let [row, sel_fields] of e.selected_rows)
				if (isobject(sel_fields))
					for (let field of sel_fields)
						if (field && field.index == null)
							sel_fields.delete(field)

	}

	e.field_index = function(field) {
		return field && field.index
	}

	function update_field_index() {
		for (let field of e.all_fields)
			field.index = null
		for (let i = 0; i < e.fields.length; i++)
			e.fields[i].index = i
	}

	// visible cols list ------------------------------------------------------

	e.set_cols = function() {
		if (!e.exit_edit())
			return
		init_fields()
		e.update({fields: true})
	}
	e.prop('cols', {store: 'var', slot: 'user'})

	function visible_col(col) {
		let field = e.all_fields[col]
		return field && field.visible !== false
	}

	let all_cols = () => e.all_fields.map(f => f.name).filter(visible_col)

	let cols_array = () => e.cols ? e.cols.split(/\s+/).filter(visible_col) : all_cols()

	function cols_from_array(cols) {
		cols = cols.join(' ')
		return cols == all_cols() ? null : cols
	}

	e.show_field = function(field, on, at_fi) {
		let cols = cols_array()
		if (on)
			if (at_fi != null)
				cols.insert(at_fi, field.name)
			else
				cols.push(field)
		else
			cols.remove_value(field.name)
		e.cols = cols_from_array(cols)
	}

	e.move_field = function(fi, over_fi) {
		if (fi == over_fi)
			return
		let insert_fi = over_fi - (over_fi > fi ? 1 : 0)
		let cols = cols_array()
		let col = cols.remove(fi)
		cols.insert(insert_fi, col)
		e.cols = cols_from_array(cols)
	}

	// param nav --------------------------------------------------------------

	function params_changed() {
		if (!e.rowset_url && (e.row_vals || e.row_states)) {
			// client-side detail: just re-filter and re-focus.
			force_unfocus_focused_cell()
			init_param_vals()
			init_rows()
			e.begin_update()
			e.update({rows: true})
			e.focus_cell()
			e.end_update()
		} else
			e.reload()
	}

	function param_nav_val_changed(master_row, master_field, val, ev) {
		if (!e.rowset_url && (e.row_vals || e.row_states)) {
			// detail nav with client-side rowset: cascade-update forein keys.
			let prev_val = this.cell_prev_val(master_row, master_field)
			let col = param_map(e.params).get(master_field.name)
			let field = e.all_fields[col]
			for (let row of e.all_rows)
				if (e.cell_val(row, field) === prev_val)
					e.set_cell_val(row, field, val)
		} else
			e.reload()
	}

	function param_vals_match(master_nav, e, params, master_row, row) {
		for (let [master_col, col] of params) {
			let master_field = master_nav.all_fields[master_col]
			let master_val = master_nav.cell_val(master_row, master_field)
			let field = e.all_fields[col]
			let val = e.cell_val(row, field)
			if (master_val !== val)
				return false
		}
		return true
	}

	function param_nav_row_removed_changed(master_row, removed) {
		if (!e.rowset_url && (e.row_vals || e.row_states)) {
			// detail nav with client-side rowset: cascade-remove detail rows.
			let params = param_map(e.params)
			for (let row of e.all_rows)
				if (param_vals_match(this, e, params, master_row, row)) {
					e.set_row_state(row, 'removed', removed, false)
				}
		}
	}

	function bind_param_nav_cols(nav, params, on) {
		if (on && !e.attached)
			return
		if (!(nav && params))
			return
		nav.on('selected_rows_changed', params_changed, on)
		for (let [col, param] of param_map(params)) {
			nav.on('cell_val_changed_for_'+col, param_nav_val_changed, on)
		}
		nav.on('row_removed_changed', param_nav_row_removed_changed, on)
	}

	function bind_param_nav(on) {
		bind_param_nav_cols(e.param_nav, e.params, on)
	}

	e.set_param_nav = function(nav1, nav0) {
		bind_param_nav_cols(nav0, e.params, false)
		bind_param_nav_cols(nav1, e.params, true)
		e.reload()
	}
	e.prop('param_nav', {store: 'var', private: true})
	e.prop('param_nav_gid', {store: 'var', bind_gid: 'param_nav', type: 'nav', text: 'Param Nav'})

	e.set_params = function(params1, params0) {
		bind_param_nav_cols(e.param_nav, params0, false)
		bind_param_nav_cols(e.param_nav, params1, true)
		e.reload()
	}
	e.prop('params', {store: 'var'})

	function param_map(params) {
		let m = new Map()
		for (let s of params.split(/\s+/)) {
			let p = s.split('=')
			let param = p && p[0] || s
			let col = p && (p[1] || p[0]) || param
			m.set(col, param)
		}
		return m
	}

	function init_param_vals(param_vals) {
		if (!e.params) {
			e.param_vals = null
		} else if (!(e.param_nav && e.param_nav.focused_row)) {
			e.param_vals = param_vals || false
		} else {
			e.param_vals = []
			for (let [row] of e.param_nav.selected_rows) {
				let vals = {}
				for (let [col, param] of param_map(e.params)) {
					let field = e.param_nav.all_fields[col]
					if (!field)
						print('param nav is missing col', col)
					let v = field && row ? e.param_nav.cell_val(row, field) : null
					vals[param] = v
				}
				e.param_vals.push(vals)
			}
		}
	}

	// all rows in load order -------------------------------------------------

	function init_all_rows() {
		e.do_update_load_fail(false)
		update_indices('invalidate')
		e.all_rows = e.attached && e.rowset && (
				e.deserialize_all_row_states(e.row_states)
				|| e.deserialize_all_row_vals(e.row_vals)
				|| e.rowset.rows
			) || []
		init_tree()
		init_rows()
	}

	// filtered and custom-sorted subset of all_rows --------------------------

	function create_rows() {
		e.rows = []
		if (e.attached) {
			let i = 0
			for (let row of e.all_rows)
				if (!row.parent_collapsed && e.row_is_visible(row))
					e.rows.push(row)
		}
	}

	function init_rows() {
		e.focused_row = null
		e.selected_row = null
		e.selected_rows = new Map()
		reset_quicksearch()

		init_filters()
		create_rows()
		sort_rows()
	}

	e.row_index = function(row) {
		return row && row[e.all_fields.length]
	}

	function update_row_index() {
		let index_fi = e.all_fields.length
		for (let i = 0; i < e.rows.length; i++)
			e.rows[i][index_fi] = i
	}

	function reinit_rows() {
		let refocus = refocus_state('row')
		init_rows()
		e.begin_update()
		e.update({rows: true})
		refocus()
		e.end_update()
	}

	// navigation and selection -----------------------------------------------

	e.property('focused_row_index'   , () => e.row_index(e.focused_row))
	e.property('focused_field_index' , () => e.field_index(e.focused_field))
	e.property('selected_row_index'  , () => e.row_index(e.selected_row))
	e.property('selected_field_index', () => e.field_index(e.selected_field))

	e.can_change_val = function(row, field) {
		return e.can_edit && e.can_change_rows
			&& (!row || (row.editable != false && !row.removed))
			&& (!field || field.editable)
			&& e.can_focus_cell(row, field)
	}

	e.can_focus_cell = function(row, field, for_editing) {
		return (!row || row.focusable != false)
			&& (field == null || !e.can_focus_cells || field.focusable != false)
			&& (!for_editing || e.can_change_val(row, field))
	}

	e.is_cell_disabled = function(row, field) {
		return !e.can_focus_cell(row, field)
	}

	e.can_select_cell = function(row, field, for_editing) {
		return e.can_focus_cell(row, field, for_editing)
			&& (e.can_select_non_siblings
				|| e.selected_rows.size == 0
				|| row.parent_row == e.selected_rows.keys().next().value.parent_row)
	}

	e.first_focusable_cell = function(ri, fi, rows, cols, opt) {

		opt = opt || empty
		let editable = opt.editable // skip non-editable cells.
		let must_move = opt.must_move // return only if moved.
		let must_not_move_row = opt.must_not_move_row // return only if row not moved.
		let must_not_move_col = opt.must_not_move_col // return only if col not moved.

		rows = or(rows, 0) // by default find the first focusable row.
		cols = or(cols, 0) // by default find the first focusable col.
		let ri_inc = strict_sign(rows)
		let fi_inc = strict_sign(cols)
		rows = abs(rows)
		cols = abs(cols)

		if (ri === true) ri = e.focused_row_index
		if (fi === true) fi = e.field_index(e.all_fields[e.last_focused_col])

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
		ev = ev || empty

		if (ri === false || fi === false) { // false means unfocus.
			return e.focus_cell(
				ri === false ? null : ri,
				fi === false ? null : fi, 0, 0,
				update({
					must_not_move_row: ri === false,
					must_not_move_col: fi === false,
					unfocus_if_not_found: true,
				}, ev)
			)
		}

		let was_editing = ev.was_editing || !!e.editor
		let focus_editor = ev.focus_editor || (e.editor && e.editor.hasfocus)
		let enter_edit = ev.enter_edit || (was_editing && e.stay_in_edit_mode)
		let editable = ev.editable || enter_edit
		let expand_selection = ev.expand_selection && e.can_select_multiple
		let invert_selection = ev.invert_selection && e.can_select_multiple

		let opt = update({editable: editable}, ev)

		;[ri, fi] = e.first_focusable_cell(ri, fi, rows, cols, opt)

		// failure to find cell means cancel.
		if (ri == null && !ev.unfocus_if_not_found)
			return false

		let row_changed   = e.focused_row != e.rows[ri]
		let field_changed = e.focused_field != e.fields[fi]

		if (row_changed) {
			if (!e.exit_focused_row(ev.force_exit_edit))
				return false
		} else if (field_changed) {
			if (!e.exit_edit(ev.force_exit_edit))
				return false
		}

		let last_ri = e.focused_row_index
		let last_fi = e.focused_field_index
		let ri0 = or(e.selected_row_index  , last_ri)
		let fi0 = or(e.selected_field_index, last_fi)
		let row0 = e.focused_row

		e.focused_row = e.rows[ri]
		e.focused_field = e.fields[fi]
		if (e.focused_field != null)
			e.last_focused_col = e.focused_field.name

		let row = e.rows[ri]

		if (e.val_field && row) {
			let val = e.cell_val(row, e.val_field)
			e.set_val(val, update({input: e}, ev))
		}

		let sel_rows_changed
		if (ev.preserve_selection) {
			// leave it
		} else if (ev.selected_rows) {
			e.selected_rows = new Map(ev.selected_rows)
			sel_rows_changed = true
		} else if (e.can_focus_cells) {
			if (expand_selection) {
				e.selected_rows.clear()
				let ri1 = min(ri0, ri)
				let ri2 = max(ri0, ri)
				let fi1 = min(fi0, fi)
				let fi2 = max(fi0, fi)
				for (let ri = ri1; ri <= ri2; ri++) {
					let row = e.rows[ri]
					if (e.can_select_cell(row)) {
						let sel_fields = new Set()
						for (let fi = fi1; fi <= fi2; fi++) {
							let field = e.fields[fi]
							if (e.can_select_cell(row, field)) {
								sel_fields.add(field)
								sel_rows_changed = true
							}
						}
						if (sel_fields.size)
							e.selected_rows.set(row, sel_fields)
						else
							e.selected_rows.delete(row)
					}
				}
			} else {
				let sel_fields = e.selected_rows.get(row) || new Set()

				if (!invert_selection) {
					e.selected_rows.clear()
					sel_fields = new Set()
				}

				let field = e.fields[fi]
				if (field)
					if (sel_fields.has(field))
						sel_fields.delete(field)
					else
						sel_fields.add(field)

				if (sel_fields.size && row)
					e.selected_rows.set(row, sel_fields)
				else
					e.selected_rows.delete(row)

				sel_rows_changed = true
			}
		} else {
			if (expand_selection) {
				e.selected_rows.clear()
				let ri1 = min(ri0, ri)
				let ri2 = max(ri0, ri)
				for (let ri = ri1; ri <= ri2; ri++) {
					let row = e.rows[ri]
					if (!e.selected_rows.has(row)) {
						if (e.can_select_cell(row)) {
							e.selected_rows.set(row, true)
							sel_rows_changed = true
						}
					}
				}
			} else {
				if (!invert_selection)
					e.selected_rows.clear()
				if (row)
					if (e.selected_rows.has(row))
						e.selected_rows.delete(row)
					else
						e.selected_rows.set(row, true)
				sel_rows_changed = true
			}
		}

		e.selected_row = expand_selection ? e.rows[ri0] : null
		e.selected_field = expand_selection ? e.fields[fi0] : null

		if (row_changed)
			e.fire('focused_row_changed', row, row0, ev)

		if (sel_rows_changed)
			e.fire('selected_rows_changed')

		let qs_changed = !!ev.quicksearch_text
		if (qs_changed) {
			e.quicksearch_text = ev.quicksearch_text
			e.quicksearch_field = ev.quicksearch_field
		} else if (e.quicksearch_text) {
			reset_quicksearch()
			qs_changed = true
		}

		e.begin_update()

		if (row_changed || sel_rows_changed || field_changed || qs_changed)
			e.update({state: true})

		if (enter_edit && ri != null && fi != null)
			e.update({enter_edit: [ev.editor_state, focus_editor || false]})

		if (ev.make_visible != false)
			if (e.focused_row)
				e.update({scroll_to_cell: [e.focused_row_index, e.focused_field_index]})

		e.end_update()

		return true
	}

	e.scroll_to_focused_cell = function() {
		if (e.focused_row_index != null)
			e.scroll_to_cell(e.focused_row_index, e.focused_field_index)
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

	e.select_all_cells = function(fi) {
		let sel_rows_size_before = e.selected_rows.size
		e.selected_rows.clear()
		let of_field = e.fields[fi]
		for (let row of e.rows)
			if (e.can_select_cell(row)) {
				let sel_fields = true
				if (e.can_focus_cells) {
					sel_fields = new Set()
					for (let field of e.fields)
						if (e.can_select_cell(row, field) && (of_field == null || field == of_field))
							sel_fields.add(field)
				}
				e.selected_rows.set(row, sel_fields)
			}
		e.update({state: true})
		if (sel_rows_size_before != e.selected_rows.size)
			e.fire('selected_rows_changed')
	}

	e.is_row_selected = function(row) {
		return e.selected_rows.has(row)
	}

	function refocus_state(how) {
		let was_editing = !!e.editor
		let focus_editor = e.editor && e.editor.hasfocus

		let refocus_pk, refocus_row
		if (how == 'pk')
			refocus_pk = e.focused_row ? e.cell_vals(e.focused_row, e.pk) : null
		else if (how == 'row')
			refocus_row = e.focused_row

		return function() {

			let must_not_move_row = !e.auto_focus_first_cell
			let ri, unfocus_if_not_found
			if (how == 'val' && e.val_field && e.nav && e.field) {
				ri = e.row_index(e.lookup(e.val_col, [e.input_val])[0])
				unfocus_if_not_found = true
			} else if (how == 'pk' && e.pk) {
				ri = e.row_index(e.lookup(e.pk, refocus_pk)[0])
			} else if (how == 'row') {
				ri = e.row_index(refocus_row)
			} else if (!how) { // TODO: not used (unfocus)
				ri = false
				must_not_move_row = true
				unfocus_if_not_found = true
			}

			e.focus_cell(ri, true, 0, 0, {
				must_not_move_row: must_not_move_row,
				unfocus_if_not_found: unfocus_if_not_found,
				enter_edit: e.auto_edit_first_cell,
				was_editing: was_editing,
				focus_editor: focus_editor,
			})

		}
	}

	// vlookup ----------------------------------------------------------------

	// cols: 'col1 ...' | fi | field | [col1|field1,...], [v1, ...]
	function create_index(cols, range_defs) {

		let idx = {}

		let tree // Map(f1_val->Map(f2_val->[row1,...]))
		let cols_arr // [col1,...]
		let fis // [val_index1, ...]

		let range_val = return_arg
		let range_text = return_arg
		if (range_defs) {
			let range_val_funcs = {}
			let range_text_funcs = {}
			for (let col in range_defs) {
				let range = range_defs[col]
				let freq = range.freq
				let range_val
				let range_text
				if (freq) {
					let offset = range.offset || 0
					if (!range.unit) {
						range_val  = v => floor((v - offset) / freq) + offset
						range_text = v => v + ' .. ' + (v + freq - 1)
					} else if (range.unit == 'month') {
						freq = floor(freq)
						if (freq > 1) {
							range_val  = v => month(v, offset) // TODO
							range_text = v => month_year(v) + ' .. ' + (month_year(month(v, freq - 1)))
						} else {
							range_val  = v => month(v, offset)
							range_text = v => month_year(v)
						}
					} else if (range.unit == 'year') {
						freq = floor(freq)
						if (freq > 1) {
							range_val  = v => year(v, offset) // TODO
							range_text = v => v + ' .. ' + year(v, freq - 1)
						} else {
							range_val  = v => year(v, offset)
							range_text = v => year_of(v)
						}
					}
				}
				range_val_funcs[col] = range_val
				range_text_funcs[col] = range_text
			}

			range_val = function(v, i) {
				if (v != null) {
					let f = range_val_funcs[cols_arr[i]]
					v = f ? f(v) : v
				}
				return v
			}

			range_text = function(v, i) {
				if (v != null) {
					let f = range_text_funcs[cols_arr[i]]
					v = f ? f(v) : v
				}
				return v
			}

		}

		function add_row(row) {
			let last_fi = fis.last
			let t0 = tree
			let i = 0
			for (let fi of fis) {
				let v = range_val(row[fi], i)
				let t1 = t0.get(v)
				if (!t1) {
					t1 = fi == last_fi ? [] : new Map()
					t0.set(v, t1)
					t1.text = range_text(v, i)
				}
				t0 = t1
				i++
			}
			t0.push(row)
		}

		idx.rebuild = function() {
			cols_arr = cols.split(/\s+/)
			fis = cols_arr.map(fld).map(f => f.val_index)
			tree = new Map()
			for (let row of e.all_rows)
				add_row(row)
		}

		idx.invalidate = function() {
			tree = null
			fis = null
		}

		idx.row_added = function(row) {
			add_row(row)
		}

		idx.row_removed = function(row) {
			// TODO:
			idx.invalidate()
		}

		idx.val_changed = function(row, field, val) {
			// TODO:
			idx.invalidate()
		}

		idx.lookup = function(vals) {
			if (!tree)
				idx.rebuild()
			let t = tree
			let i = 0
			for (let fi of fis) {
				let v = range_val(vals[i], i); i++
				t = t.get(v)
				if (!t)
					return empty_array
			}
			return t
		}

		idx.tree = function() {
			if (!tree)
				idx.rebuild()
			return tree
		}

		return idx
	}

	let indices = {} // {cache_key->index}

	function index(cols, range_defs) {
		cols = e.fldnames(cols)
		let cache_key = range_defs ? cols+' '+json(range_defs) : cols
		let index = indices[cache_key]
		if (!index) {
			index = create_index(cols, range_defs)
			indices[cache_key] = index
		}
		return index
	}

	e.index_tree = function(cols, range_defs) {
		return index(cols, range_defs).tree()
	}

	e.lookup = function(cols, v, range_defs) {
		return index(cols, range_defs).lookup(v)
	}

	function update_indices(method, ...args) {
		for (let cols in indices)
			indices[cols][method](...args)
	}

	// groups -----------------------------------------------------------------

	e.row_group = function(cols, range_defs) {
		let fields = flds(cols)
		if (!fields)
			return
		let rows = new Set()
		for (let row of e.all_rows) {
			let group_vals = e.cell_vals(row, fields)
			let group_rows = e.lookup(cols, group_vals, range_defs)
			rows.add(group_rows)
			group_rows.key_vals = group_vals
		}
		return rows
	}

	function flatten(t, path, depth, f, arg1, arg2) {
		let path_pos = path.length
		for (let [k, t1] of t) {
			path[path_pos] = k
			if (depth)
				flatten(t1, path, depth-1, f, arg1, arg2)
			else
				f(t1, path, arg1, arg2)
		}
		path.remove(path_pos)
	}

	e.row_groups = function(group_cols, range_defs) {
		let all_cols = group_cols.replaceAll(',', ' ')
		let fields = flds(all_cols)
		if (!fields)
			return
		let tree = e.index_tree(all_cols, range_defs)

		let col_groups = group_cols.split(/\s*,\s*/)
		let root_group = []
		let depth = col_groups[0].split(/\s+/).length-1
		function add_group(t, path, parent_group, parent_group_level) {
			let group = []
			group.key_vals = path.slice()
			group.text = t.text
			parent_group.push(group)
			let level = parent_group_level + 1
			let col_group = col_groups[level]
			if (col_group) { // more group levels down...
				let depth = col_group.split(/\s+/).length-1
				flatten(t, [], depth, add_group, group, level)
			} else { // last group level, t is the array of rows.
				group.push(...t)
			}
		}
		flatten(tree, [], depth, add_group, root_group, 0)
		return root_group
	}

	// tree -------------------------------------------------------------------

	e.each_child_row = function(row, f) {
		if (e.parent_field)
			for (let child_row of row.child_rows) {
				e.each_child_row(child_row, f) // depth-first
				f(child_row)
			}
	}

	function init_parent_rows_for_row(row, parent_rows) {

		if (!init_parent_rows_for_rows(row.child_rows))
			return // circular ref: abort.

		if (!parent_rows) {

			// reuse the parent rows array from a sibling, if any.
			let sibling_row = (row.parent_row || e).child_rows[0]
			parent_rows = sibling_row && sibling_row.parent_rows

			if (!parent_rows) {

				parent_rows = []
				let parent_row = row.parent_row
				while (parent_row) {
					if (parent_row == row || parent_rows.includes(parent_row))
						return // circular ref: abort.
					parent_rows.push(parent_row)
					parent_row = parent_row.parent_row
				}
			}
		}
		row.parent_rows = parent_rows
		return parent_rows
	}

	function init_parent_rows_for_rows(rows) {
		let parent_rows
		for (let row of rows) {
			parent_rows = init_parent_rows_for_row(row, parent_rows)
			if (!parent_rows)
				return // circular ref: abort.
		}
		return true
	}

	function remove_parent_rows_for(row) {
		row.parent_rows = null
		for (let child_row of row.child_rows)
			remove_parent_rows_for(child_row)
	}

	function remove_row_from_tree(row) {
		let child_rows = (row.parent_row || e).child_rows
		if (!child_rows)
			return
		child_rows.remove_value(row)
		if (row.parent_row && row.parent_row.child_rows.length == 0)
			delete row.parent_row.collapsed
		row.parent_row = null
		remove_parent_rows_for(row)
	}

	function add_row_to_tree(row, parent_row) {
		row.parent_row = parent_row
		;(parent_row || e).child_rows.push(row)
	}

	function init_tree() {

		e.child_rows = null

		if (!e.parent_field)
			return

		e.child_rows = []
		for (let row of e.all_rows)
			row.child_rows = []

		let p_fi = e.parent_field.val_index
		for (let row of e.all_rows) {
			let parent_id = row[p_fi]
			let parent_row = parent_id != null ? e.lookup(e.id_field.name, [parent_id])[0] : null
			add_row_to_tree(row, parent_row)
		}

		if (!init_parent_rows_for_rows(e.child_rows)) {
			// circular refs detected: revert to flat mode.
			for (let row of e.all_rows) {
				row.child_rows = null
				row.parent_rows = null
				row.parent_row = null
				print('circular ref detected')
			}
			e.child_rows = null
			e.parent_field = null
		}

	}

	// row moving -------------------------------------------------------------

	function change_row_parent(row, parent_row, ev) {
		if (!e.parent_field)
			return
		if (parent_row == row.parent_row)
			return
		assert(parent_row != row)
		assert(!parent_row || !parent_row.parent_rows.includes(row))

		let parent_id = parent_row ? e.cell_val(parent_row, e.id_field) : null
		e.set_cell_val(row, e.parent_field, parent_id, ev)

		remove_row_from_tree(row)
		add_row_to_tree(row, parent_row)

		assert(init_parent_rows_for_row(row))
	}

	// row collapsing ---------------------------------------------------------

	function set_parent_collapsed(row, collapsed) {
		for (let child_row of row.child_rows) {
			child_row.parent_collapsed = collapsed
			if (!child_row.collapsed)
				set_parent_collapsed(child_row, collapsed)
		}
	}

	function set_collapsed_all(row, collapsed) {
		if (row.child_rows.length > 0) {
			row.collapsed = collapsed
			for (let child_row of row.child_rows) {
				child_row.parent_collapsed = collapsed
				set_collapsed_all(child_row, collapsed)
			}
		}
	}

	function set_collapsed(row, collapsed, recursive) {
		if (!row.child_rows.length)
			return
		if (recursive)
			set_collapsed_all(row, collapsed)
		else if (row.collapsed != collapsed) {
			row.collapsed = collapsed
			set_parent_collapsed(row, collapsed)
		}
	}

	e.set_collapsed = function(row, collapsed, recursive) {
		if (!e.parent_field)
			return
		if (row)
			set_collapsed(row, collapsed, recursive)
		else
			for (let row of e.child_rows)
				set_collapsed(row, collapsed, recursive)
		reinit_rows()
	}

	e.toggle_collapsed = function(row, recursive) {
		e.set_collapsed(row, !row.collapsed, recursive)
	}

	// sorting ----------------------------------------------------------------

	e.compare_rows = function(row1, row2) {
		// invalid rows come first.
		if (row1.invalid != row2.invalid)
			return row1.invalid ? -1 : 1
		return 0
	}

	e.compare_types = function(v1, v2) {
		// nulls come first.
		if ((v1 === null) != (v2 === null))
			return v1 === null ? -1 : 1
		// NaNs come second.
		if ((v1 !== v1) != (v2 !== v2))
			return v1 !== v1 ? -1 : 1
		return 0
	}

	e.compare_vals = function(v1, v2) {
		return v1 !== v2 ? (v1 < v2 ? -1 : 1) : 0
	}

	function field_comparator(field) {

		let compare_rows = e.compare_rows
		let compare_types = field.compare_types  || e.compare_types
		let compare_vals = field.compare_vals || e.compare_vals
		let field_index = field.val_index

		return function(row1, row2) {
			let r1 = compare_rows(row1, row2)
			if (r1) return r1

			let v1 = row1[field_index]
			let v2 = row2[field_index]

			let r2 = compare_types(v1, v2)
			if (r2) return r2

			return compare_vals(v1, v2)
		}
	}

	function row_comparator() {

		let order_by = new Map(order_by_map)

		// use index-based ordering by default, unless otherwise specified.
		if (e.index_field && order_by.size == 0)
			order_by.set(e.index_field, 'asc')

		// the tree-building comparator requires a stable sort order
		// for all parents so we must always compare rows by id after all.
		if (e.parent_field && !(e.row_vals || e.row_states) && !order_by.has(e.id_field))
			order_by.set(e.id_field, 'asc')

		let s = []
		let cmps = []
		for (let [field, dir] of order_by) {
			let i = field.val_index
			cmps[i] = field_comparator(field)
			let r = dir == 'desc' ? -1 : 1
			let err_i = cell_state_val_index('error', field)
			if (field != e.index_field) {
				// invalid rows come first
				s.push('{')
				s.push('  let v1 = r1.error == null')
				s.push('  let v2 = r2.error == null')
				s.push('  if (v1 < v2) return -1')
				s.push('  if (v1 > v2) return  1')
				s.push('}')
				// invalid vals come after
				s.push('{')
				s.push('  let v1 = r1['+err_i+'] == null')
				s.push('  let v2 = r2['+err_i+'] == null')
				s.push('  if (v1 < v2) return -1')
				s.push('  if (v1 > v2) return  1')
				s.push('}')
				// modified rows come after
				s.push('{')
				s.push('  let v1 = !r1.modified')
				s.push('  let v2 = !r2.modified')
				s.push('  if (v1 < v2) return -1')
				s.push('  if (v1 > v2) return  1')
				s.push('}')
			}
			// compare vals using the value comparator
			s.push('{')
			s.push('let cmp = cmps['+i+']')
			s.push('let r = cmp(r1, r2)')
			s.push('if (r) return r * '+r)
			s.push('}')
		}
		s.push('return 0')
		let cmp = 'let cmp = function(r1, r2) {\n\t' + s.join('\n\t') + '\n}\n; cmp;\n'

		// tree-building comparator: order elements by their position in the tree.
		if (e.parent_field) {
			// find the closest sibling ancestors of the two rows and compare them.
			let s = []
			s.push('let i1 = r1.parent_rows.length-1')
			s.push('let i2 = r2.parent_rows.length-1')
			s.push('while (i1 >= 0 && i2 >= 0 && r1.parent_rows[i1] == r2.parent_rows[i2]) { i1--; i2--; }')
			s.push('let p1 = i1 >= 0 ? r1.parent_rows[i1] : r1')
			s.push('let p2 = i2 >= 0 ? r2.parent_rows[i2] : r2')
			s.push('if (p1 == p2) return i1 < i2 ? -1 : 1') // one is parent of another.
			s.push('return cmp_direct(p1, p2)')
			cmp = cmp+'let cmp_direct = cmp; cmp = function(r1, r2) {\n\t' + s.join('\n\t') + '\n}\n; cmp;\n'
		}

		return eval(cmp)
	}

	function sort_rows(force) {
		let must_sort = !!(e.parent_field || e.index_field || order_by_map.size)
		if (must_sort)
			e.rows.sort(row_comparator())
		else if (force)
			create_rows()
		update_row_index()
	}

	// changing the sort order ------------------------------------------------

	let order_by_map = new Map()

	function update_field_sort_order() {
		order_by_map.clear()
		let pri = 0
		for (let field of e.all_fields) {
			field.sort_dir = null
			field.sort_priority = null
		}
		for (let s1 of (e.order_by || '').split(/\s+/)) {
			let m = s1.split(':')
			let name = m[0]
			let field = e.all_fields[name]
			if (field && field.sortable) {
				let dir = m[1] || 'asc'
				if (dir == 'asc' || dir == 'desc') {
					order_by_map.set(field, dir)
					field.sort_dir = dir
					field.sort_priority = pri
					pri++
				}
			}
		}
	}

	function order_by_from_map() {
		let a = []
		for (let [field, dir] of order_by_map)
			a.push(field.name + (dir == 'asc' ? '' : ':desc'))
		return a.length ? a.join(' ') : undefined
	}

	e.set_order_by = function() {
		update_field_sort_order()
		sort_rows(true)
		e.update({vals: true, state: true, sort_order: true})
		e.scroll_to_focused_cell()
	}
	e.prop('order_by', {store: 'var', slot: 'user'})

	e.set_order_by_dir = function(field, dir, keep_others) {
		if (!field.sortable)
			return
		if (dir == 'toggle') {
			dir = order_by_map.get(field)
			dir = dir == 'asc' ? 'desc' : (dir == 'desc' ? false : 'asc')
		}
		if (!keep_others)
			order_by_map.clear()
		if (dir)
			order_by_map.set(field, dir)
		else
			order_by_map.delete(field)
		e.order_by = order_by_from_map()
	}

	// filtering --------------------------------------------------------------

	// expr: [bin_oper, expr1, ...] | [un_oper, expr] | [col, oper, val]
	function expr_filter(expr) {
		let expr_bin_ops = {'&&': 1, '||': 1}
		let expr_un_ops = {'!': 1}
		let s = []
		function push_expr(expr) {
			let op = expr[0]
			if (op in expr_bin_ops) {
				assert(expr.length > 1)
				s.push('(')
				for (let i = 1; i < expr.length; i++) {
					if (i > 1)
						s.push(' '+op+' ')
					push_expr(expr[i])
				}
				s.push(')')
			} else if (op in expr_un_ops) {
				s.push('('+op+'(')
				push_expr(expr[1])
				s.push('))')
			} else {
				s.push('row['+e.all_fields[expr[1]].val_index+'] '+expr[0]+' '+json(expr[2]))
			}
		}
		push_expr(expr)
		if (!s.length)
			return return_true
		s = 'let f = function(row) {\n\treturn ' + s.join('') + '\n}; f'
		return eval(s)
	}

	function init_filters() {
		e.is_filtered = false
		if (e.param_vals === false) {
			e.row_is_visible = return_false
			return
		}
		let expr = ['&&']
		if (e.param_vals && !e.rowset_url) {
			if (e.param_vals.length == 1) {
				for (let k in e.param_vals[0])
					expr.push(['===', k, e.param_vals[0][k]])
			} else {
				let or_expr = ['||']
				for (let vals of e.param_vals) {
					let and_expr = ['&&']
					for (let k in vals)
						and_expr.push(['===', k, vals[k]])
					or_expr.push(and_expr.length > 1 ? and_expr : and_expr[1])
				}
				expr.push(or_expr)
			}
		}
		for (let field of e.all_fields)
			if (field.exclude_vals)
				for (let v of field.exclude_vals) {
					expr.push(['!==', field.name, v])
					e.is_filtered = true
				}
		e.row_is_visible = expr.length > 1 ? expr_filter(expr) : return_true
	}

	e.and_filter = function(cols, vals) {
		let expr = ['&&']
		let i = 0
		for (let col of cols.split(/\s+/))
			expr.push(['===', col, vals[i++]])
		return expr.length > 1 ? expr_filter(expr) : return_true
	}

	// exclude filter UI ------------------------------------------------------

	e.create_exclude_vals_nav = function(opt, field) { // stub
		return bare_nav(opt)
	}

	function set_exclude_filter(field, exclude_vals) {
		let nav = field.exclude_vals_nav
		if (!exclude_vals) {
			if (nav) {
				field.exclude_vals_nav.remove()
				field.exclude_vals_nav = null
			}
			return
		}
		if (!nav) {
			function format_row(row) {
				return e.cell_display_val_for(field, null, row)
			}
			nav = e.create_exclude_vals_nav({
					rowset: {
						fields: [
							{name: 'include', type: 'bool', default: true},
							{name: 'row', format: format_row},
						],
					},
				}, field)
			field.exclude_vals_nav = nav
		}
		let exclude_set = new Set(exclude_vals)
		let rows = []
		let val_set = new Set()
		for (let row of e.all_rows) {
			let v = e.cell_val(row, field)
			if (!val_set.has(v)) {
				rows.push([!exclude_set.has(v), row])
				val_set.add(v)
			}
		}
		nav.rowset.rows = rows
		nav.reset()

		reinit_rows()
	}

	// get/set cell & row state (storage api) ---------------------------------

	let next_key_index = 0
	let key_index = {}

	function cell_state_key_index(key) {
		let i = key_index[key]
		if (i == null) {
			i = next_key_index++
			key_index[key] = i
		}
		return i
	}

	function cell_state_val_index(key, field) {
		let fn = e.all_fields.length
		return fn + 1 + cell_state_key_index(key) * fn + field.val_index
	}

	e.cell_state = function(row, field, key, default_val) {
		let v = row[cell_state_val_index(key, field)]
		return v !== undefined ? v : default_val
	}

	e.set_cell_state = function(row, field, key, val, default_val, fire_change_event, ev) {
		let vi = cell_state_val_index(key, field)
		let old_val = row[vi]
		if (old_val === undefined)
			old_val = default_val
		if (old_val === val)
			return false
		row[vi] = val
		if (fire_change_event !== false)
			cell_state_changed(row, field, key, val, ev)
		return true
	}

	e.set_row_state = function(row, key, val, default_val, fire_change_event, ev) {
		let old_val = row[key]
		if (old_val === undefined)
			old_val = default_val
		if (old_val === val)
			return false
		row[key] = val
		if (fire_change_event !== false)
			row_state_changed(row, key, val, ev)
		return true
	}

	function cell_state_changed(row, field, key, val, ev) {
		if (ev && ev.fire_changed_events === false)
			return
		e.fire('cell_state_changed', row, field, key, val, ev)
		e.fire('cell_state_changed_for_'+field.name, row, field, key, val, ev)
		e.fire('cell_'+key+'_changed', row, field, val, ev)
		e.fire('cell_'+key+'_changed_for_'+field.name, row, field, val, ev)

		let ri = e.row_index(row)
		let fi = e.field_index(field)
		e.do_update_cell_state(ri, fi, key, val, ev)
		if (row == e.focused_row) {
			e.fire('focused_row_cell_state_changed', field, key, val, ev)
			e.fire('focused_row_cell_state_changed_for_'+field.name, field, key, val, ev)
			e.fire('focused_row_cell_'+key+'_changed_for_'+field.name, field, val, ev)
		}
	}

	function row_state_changed(row, key, val, ev) {

		let ri = e.row_index(row, ev && ev.row_index)
		e.do_update_row_state(ri, key, val, ev)
		if (row == e.focused_row) {
			e.fire('focused_row_state_changed', key, val, ev)
			e.fire('focused_row_'+key+'_changed', val, ev)
		}
		e.fire('row_state_changed', row, key, val, ev)
		e.fire('row_'+key+'_changed', row, val, ev)
	}

	// get/set cell vals and cell & row state ---------------------------------

	e.cell_val          = (row, col) => row[fld(col).val_index]
	e.cell_input_val    = (row, col) => e.cell_state(row, fld(col), 'input_val'   , row[fld(col).val_index])
	e.cell_old_val      = (row, col) => e.cell_state(row, fld(col), 'old_val'     , row[fld(col).val_index])
	e.cell_prev_val     = (row, col) => e.cell_state(row, fld(col), 'prev_val'    , row[fld(col).val_index])
	e.cell_error        = (row, col) => e.cell_state(row, fld(col), 'error')
	e.cell_modified     = (row, col) => e.cell_state(row, fld(col), 'modified', false)

	e.cell_vals = function(row, cols) {
		let fields = flds(cols)
		return fields ? fields.map(f => row[f.val_index]) : null
	}

	e.convert_val = function(field, val, row, ev) {
		return field.convert ? field.convert.call(e, val, field, row) : val
	}

	e.validate_val = function(field, val, row, ev) {

		if (val == null)
			if (!field.allow_null)
				return S('error_not_null', 'NULL not allowed')
			else
				return

		if (field.min != null && val < field.min)
			return S('error_min_value', 'Value must be at least {0}').subst(field.min)

		if (field.max != null && val > field.max)
			return S('error_max_value', 'Value must be at most {0}').subst(field.max)

		let ln = field.lookup_nav
		if (ln) {
			field.display_field = field.display_field || ln.all_fields[field.display_col || ln.name_col]
			if (!ln.lookup(field.lookup_col, [val]).length)
				return S('error_lookup', 'Value not found in lookup nav')
		}

		let err = field.validate && field.validate.call(e, val, field, row)
		if (typeof err == 'string')
			return err

		return e.fire('validate_'+field.name, val, row, ev)
	}

	e.on_validate_val = function(col, validate, on) {
		e.on('validate_'+e.all_fields[col].name, validate, on)
	}

	e.validate_row = function(row) {
		return e.fire('validate', row)
	}

	e.row_can_have_children = function(row) {
		return row.can_have_children != false
	}

	e.set_row_error = function(row, err, ev) {
		err = typeof err == 'string' ? err : undefined
		if (err != null) {
			e.notify('error', err)
			print(err)
		}
		e.set_row_state(row, 'error', err, undefined, true, ev)
	}

	e.set_row_is_new = function(row, is_new, ev) {
		e.set_row_state(row, 'is_new', is_new, false, ev)
		e.set_row_state(row, 'modified', is_new, false, ev)
		if (is_new)
			row_changed(row)
	}

	e.row_has_errors = function(row) {
		if (row.error != null)
			return true
		for (let field of e.all_fields)
			if (e.cell_error(row, field) != null)
				return true
		return false
	}

	function cells_modified(row) {
		for (let field of e.all_fields)
			if (e.cell_state(row, field, 'modified'))
				return true
	}

	e.row_is_user_modified = function(row) {
		if (!row.modified)
			return false
		if (!e.index_field)
			return true
		for (let field of e.all_fields)
			if (e.cell_state(row, field, 'modified') && field !== e.index_field)
				return true
		return false
	}

	e.set_cell_val = function(row, col, val, ev) {
		let field = fld(col)
		if (field.nosave) {
			e.reset_cell_val(row, field, val, ev)
			return
		}
		if (val === undefined)
			val = null
		val = e.convert_val(field, val, row, ev)
		let err = e.validate_val(field, val, row, ev)
		err = typeof err == 'string' ? err : undefined
		let invalid = err != null
		let cur_val = row[field.val_index]
		let val_changed = !invalid && val !== cur_val

		let input_val_changed = e.set_cell_state(row, field, 'input_val', val, cur_val, false)
		let cell_err_changed = e.set_cell_state(row, field, 'error', err, undefined, false)
		let row_err_changed = e.set_row_state(row, 'error', undefined, undefined, false)

		if (val_changed) {
			let was_modified = e.cell_modified(row, field)
			let modified = val !== e.cell_old_val(row, field)

			row[field.val_index] = val
			e.set_cell_state(row, field, 'prev_val', cur_val, null, false)
			if (!was_modified)
				e.set_cell_state(row, field, 'old_val', cur_val, null, false)
			let cell_modified_changed = e.set_cell_state(row, field, 'modified', modified, false, false)
			let row_modified = modified || cells_modified(row)
			let row_modified_changed = (!(ev && ev.row_not_modified))
				&& e.set_row_state(row, 'modified', row_modified, false, false)

			update_indices('val_changed', row, field, val)

			cell_state_changed(row, field, 'val', val, ev)
			if (cell_modified_changed)
				cell_state_changed(row, field, 'modified', modified, ev)
			if (row_modified_changed)
				row_state_changed(row, 'modified', true, ev)

			row_changed(row)
		}

		if (input_val_changed)
			cell_state_changed(row, field, 'input_val', val, ev)
		if (cell_err_changed)
			cell_state_changed(row, field, 'error', err, ev)
		if (row_err_changed)
			row_state_changed(row, 'error', undefined, ev)

		return !invalid
	}

	e.reset_cell_val = function(row, field, val, ev) {
		if (val === undefined)
			val = null
		let err
		if (ev && ev.validate) {
			err = e.validate_val(field, val, row, ev)
			err = typeof err == 'string' ? err : undefined
		}
		let invalid = err != null
		let cur_val = row[field.val_index]
		let old_val = e.cell_old_val(row, field)
		let input_val_changed = e.set_cell_state(row, field, 'input_val', val, cur_val, false)
		let old_val_changed = e.set_cell_state(row, field, 'old_val', val, old_val, false)
		let cell_modified_changed = e.set_cell_state(row, field, 'modified', false, false, false)
		let cell_err_changed = e.set_cell_state(row, field, 'error', err, undefined, false)
		let row_err_changed = e.set_row_state(row, 'error', undefined, undefined, false)
		let row_is_new_changed = e.set_row_state(row, 'is_new', false, false, false)
		if (val !== cur_val) {
			row[field.val_index] = val
			e.set_cell_state(row, field, 'prev_val', cur_val, null, false)

			cell_state_changed(row, field, 'val', val, ev)
		}

		if (old_val_changed)
			cell_state_changed(row, field, 'old_val', val, ev)
		if (input_val_changed)
			cell_state_changed(row, field, 'input_val', val, ev)
		if (cell_modified_changed)
			cell_state_changed(row, field, 'modified', false, ev)
		if (cell_err_changed)
			cell_state_changed(row, field, 'error', err, ev)
		if (row_err_changed)
			row_state_changed(row, 'error', undefined, ev)
		if (row_is_new_changed)
			row_state_changed(row, 'is_new', false, ev)

		return !invalid
	}

	// responding to val changes ----------------------------------------------

	e.do_update_val = function(v, ev) {
		if (ev && ev.input == e)
			return // coming from focus_cell(), avoid recursion.
		if (!e.val_field)
			return // fields not initialized yet.
		let row = e.lookup(e.val_col, [v])[0]
		let ri = e.row_index(row)
		e.focus_cell(ri, true, 0, 0,
			update({
				must_not_move_row: true,
				unfocus_if_not_found: true,
			}, ev))
	}

	// editing ----------------------------------------------------------------

	e.editor = null

	e.do_create_editor = function(field, ...opt) {
		if (!field.editor_instance) {
			e.editor = field.editor({
				// TODO: use original gid as template but
				// load/save to this gid after instantiation.
				//gid: e.gid && e.gid+'.editor.'+field.name,
				nav: e,
				col: field.name,
				can_select_widget: false,
				nolabel: true,
			}, ...opt)
			if (!e.editor)
				return
			field.editor_instance = e.editor
		} else {
			e.editor = field.editor_instance
			e.editor.show()
		}
	}

	e.enter_edit = function(editor_state, focus) {
		if (!e.focused_field)
			return
		if (e.editor)
			return true
		if (!e.can_focus_cell(e.focused_row, e.focused_field, true))
			return false

		if (editor_state == 'toggle' && e.focused_field && e.focused_field.type == 'bool') {
			if (e.set_cell_val(e.focused_row, e.focused_field,
					!e.cell_val(e.focused_row, e.focused_field), {input: e}))
				if (e.save_row_on == 'exit_edit')
					e.save()
			return false
		}
		if (editor_state == 'toggle')
			editor_state = 'select_all'

		e.do_create_editor(e.focused_field)
		if (!e.editor)
			return false

		e.do_update_cell_editing(e.focused_row_index, e.focused_field_index, true)

		e.editor.on('lost_focus', editor_lost_focus)

		if (e.editor.enter_editor)
			e.editor.enter_editor(editor_state)

		if (focus != false)
			e.editor.focus()

		return true
	}

	e.exit_edit = function(force) {
		if (!e.editor)
			return true

		if (!force)
			if (!e.can_exit_edit_on_errors && e.row_has_errors(e.focused_row))
				return false

		if (!e.fire('exit_edit', e.focused_row_index, e.focused_field_index, force))
			if (!force)
				return false

		if (e.save_row_on == 'exit_edit')
			e.save()

		if (!force)
			if (!e.can_exit_row_on_errors && e.row_has_errors(e.focused_row))
				return false

		let had_focus = e.hasfocus

		e.editor.off('lost_focus', editor_lost_focus)
		e.editor.hide()
		e.editor = null

		e.do_update_cell_editing(e.focused_row_index, e.focused_field_index, false)
		if (had_focus)
			e.focus()

		return true
	}

	function editor_lost_focus(ev) {
		if (ev.target != e.editor) // other input that bubbled up.
			return
		if (e.exit_edit_on_lost_focus)
			e.exit_edit()
	}

	e.exit_focused_row = function(force) {
		let row = e.focused_row
		if (!row)
			return true
		if (!e.exit_edit(force))
			return false
		if (row.modified) {
			let err = e.validate_row(row)
			e.set_row_error(row, err)
		}
		if (!force)
			if (!e.can_exit_row_on_errors && e.row_has_errors(row))
				return false
		if (e.save_row_on == 'exit_row'
			|| (e.save_row_on != 'manual' && row.is_new  && e.save_new_row_on     == 'exit_row')
			|| (e.save_row_on != 'manual' && row.removed && e.save_row_remove_on  == 'exit_row')
		) {
			e.save()
		}
		return true
	}

	e.set_null_selected_cells = function() {
		for (let [row, sel_fields] of e.selected_rows)
			for (let field of (isobject(sel_fields) ? sel_fields : e.fields))
				if (e.can_change_val(row, field))
					e.set_cell_val(row, field, null)
	}

	// get/set cell display val -----------------------------------------------

	function bind_lookup_navs(on) {
		for (let field of e.all_fields) {
			let ln_gid = field.lookup_nav_gid
			if (ln_gid) {
				field.lookup_nav = component.create(ln_gid)
				field.lookup_nav.gid = null // not saving into the original.
				field.lookup_nav.hide()
				e.add(field.lookup_nav)
			}
			let ln = field.lookup_nav
			if (ln) {
				if (on && !field.lookup_nav_reset) {
					field.lookup_nav_reset = function() {
						field.display_field = ln.all_fields[field.display_col || ln.name_col]
						e.fire('display_vals_changed', field)
						e.fire('display_vals_changed_for_'+field.name, field)
					}
					field.lookup_nav_display_vals_changed = function() {
						e.fire('display_vals_changed', field)
						e.fire('display_vals_changed_for_'+field.name, field)
					}
					field.lookup_nav_reset()
				}
				ln.on('reset'       , field.lookup_nav_reset, on)
				ln.on('rows_changed', field.lookup_nav_display_vals_changed, on)
				ln.on('cell_val_changed_for_'+field.lookup_col,
					field.lookup_nav_display_vals_changed, on)
				ln.on('cell_val_changed_for_'+(field.display_col || ln.name_col),
					field.lookup_nav_display_vals_changed, on)
			}
		}
	}

	function null_display_val_for(row, field) {
		let s = field.null_text
		if (!field.null_lookup_col)
			return s
		let lf = e.all_fields[field.null_lookup_col]      ; if (!lf || !lf.lookup_col) return s
		let ln = lf.lookup_nav                            ; if (!ln) return s
		let nfv = e.cell_val(row, lf)
		let ln_row = ln.lookup(lf.lookup_col, [nfv])[0]   ; if (!ln_row) return s
		let dcol = or(field.null_display_col, field.name)
		let df = ln.all_fields[dcol]                      ; if (!df) return s
		return ln.cell_display_val(ln_row, df)
	}

	e.cell_display_val_for = function(field, v, row) {
		if (v == null)
			return null_display_val_for(row, field)
		if (v === '')
			return field.empty_text
		let ln = field.lookup_nav
		if (ln) {
			if (field.lookup_col) {
				let row = ln.lookup(field.lookup_col, [v])[0]
				if (row)
					return ln.cell_display_val(row, field.display_field)
			}
			return field.lookup_failed_display_val(v)
		} else
			return field.format(v, row)
	}

	e.cell_display_val = function(row, field) {
		return e.cell_display_val_for(field, e.cell_input_val(row, field), row)
	}

	e.on('display_vals_changed', function(field) {
		reset_quicksearch()
		e.update({vals: true})
	})

	// get cell text val ------------------------------------------------------

	e.cell_text_val = function(row, field) {
		let v = e.cell_display_val(row, field)
		if (v instanceof Node)
			return v.textContent
		if (typeof v != 'string')
			return ''
		return v
	}

	// row adding & removing --------------------------------------------------

	e.insert_rows = function(row_vals, ev) {
		if (!e.can_edit || !e.can_add_rows)
			return false

		ev = ev || empty

		let at_row = ev.at_focused_row && e.focused_row
		let parent_row = at_row ? at_row.parent_row : null

		let row_num = isarray(row_vals) ? row_vals.length : row_vals // arg#1 is row_num.
		if (row_num <= 0)
			return false

		let ri1 = at_row ? e.focused_row_index : e.rows.length

		e.begin_update()

		let rows_added, rows_updated
		let changed_rows = []

		let has_rows = e.all_rows.length > 0

		for (let i = 0, ri = ri1; i < row_num; i++) {

			let vals = row_vals && row_vals[i]
			let row = []
			for (let fi = 0; fi < e.all_fields.length; fi++) {
				let field = e.all_fields[fi]
				// row vals can be [val1,...] or {col->val}.
				// `undefined` allows for partial updates on specific fields only
				// and allows for setting the field's default value on insert.
				let val = isobject(vals) ? vals[field.name] : (vals ? vals[fi] : undefined)
				// update with current param values if it's a client-side-filtered detail rowset.
				if (val === undefined && !e.rowset_url && e.param_vals)
					val = e.param_vals[0][field.name]
				row[fi] = val
			}

			// check pk to perform an "insert or update" op.
			let row0 = has_rows && e.pk && e.lookup(e.pk, e.cell_vals(row, e.pk))[0]

			if (row0) {

				// update values that are not `undefined`.
				for (let fi = 0; fi < e.all_fields.length; fi++) {
					let field = e.all_fields[fi]
					if (row[fi] !== undefined)
						e.set_cell_val(row0, field, row[fi])
				}

				update(row0, ev.row_state)
				changed_rows.push(row0)
				rows_updated = true

			} else {

				// set server default value for `undefined` values only.
				for (let fi = 0; fi < e.all_fields.length; fi++) {
					let field = e.all_fields[fi]
					row[fi] = strict_or(row[fi], field.default)
				}

				row.is_new = true
				e.all_rows.push(row)
				update(row, ev.row_state)
				changed_rows.push(row)
				rows_added = true

				if (e.parent_field) {
					row.child_rows = []
					row.parent_row = parent_row || null
					;(row.parent_row || e).child_rows.push(row)
					if (row.parent_row) {
						// silently set parent id to be the id of the parent row.
						let parent_id = e.cell_val(row.parent_row, e.id_field)
						e.set_cell_val(row, e.parent_field, parent_id,
							update({fire_changed_events: false}, ev))
					}
					assert(init_parent_rows_for_row(row))
				}

				update_indices('row_added', row)

				if (e.row_is_visible(row)) {
					e.rows.insert(ri, row)
					if (e.focused_row_index >= ri)
						e.focused_row = e.rows[e.focused_row_index + 1]
					ri++
				}

				// set default client values as if they were typed in by the user.
				let set_val_ev = update({row_not_modified: true}, ev)
				for (let field of e.all_fields)
					if (field.client_default != null)
						e.set_cell_val(row, field, field.client_default, set_val_ev)

				if (row.is_new)
					row_changed(row)

			}
		}

		if (rows_added) {

			update_row_index()

			if (ev.input)
				update_index_field()

		}

		e.fire('rows_changed', changed_rows)

		if (rows_added || rows_updated)
			e.update({rows: rows_added, vals: rows_updated})

		if (ev.focus_it)
			e.focus_cell(ri1, true, 0, 0, ev)

		if (e.save_row_on != 'manual' && e.save_new_row_on == 'input')
			e.save()

		e.end_update()

		return true
	}

	e.can_remove_row = function(row) {
		if (!(e.can_edit && e.can_remove_rows))
			return false
		if (!row)
			return true
		if (row.can_remove === false)
			return false
		if (row.is_new && row.save_request) {
			e.notify('error',
				S('error_remove_while_saving',
					'Cannot remove a row that is in the process of being added to the server'))
			return false
		}
		return true
	}

	e.remove_rows = function(rows_to_remove, ev) {

		ev = ev || empty
		let forever = (ev.forever) || !e.can_save_changes()

		e.begin_update()

		let removed_rows = new Set()
		let changed_rows = []
		let rows_marked
		let top_row_index

		for (let row of rows_to_remove) {

			if (forever || row.is_new) {

				if (ev.refocus) {
					let row_index = e.row_index(row)
					if (top_row_index == null || row_index < top_row_index)
						top_row_index = row_index
				}

				removed_rows.add(row)
				e.each_child_row(row, function(row) {
					removed_rows.add(row)
				})

				remove_row_from_tree(row)

				update_indices('row_removed', row)

				row.removed = true

			} else if (e.can_remove_row(row)) {

				let removed = !ev.toggle || !row.removed

				e.each_child_row(row, function(row) {
					row.removed = removed
					changed_rows.push(row)
				})
				row.removed = removed
				changed_rows.push(row)

				rows_marked = rows_marked || removed
			}

			row_changed(row)

		}

		if (removed_rows.size) {

			if (removed_rows.size < 100) {
				// much faster removal for a small number of rows (common case).
				for (let row of removed_rows.keys()) {
					e.rows.remove_value(row)
					e.all_rows.remove_value(row)
				}
				update_row_index()
			} else {
				e.all_rows = e.all_rows.filter(row => !removed_rows.has(row))
				init_rows()
			}

			e.fire('rows_removed', removed_rows)

			e.update({rows: true})

			if (top_row_index != null) {
				if (!e.focus_cell(top_row_index, true))
					e.focus_cell(top_row_index, true, -0)
			} else {
				e.focus_cell(false, false)
			}

			if (ev.input)
				update_index_field()

		}

		if (changed_rows.length || removed_rows.size)
			e.fire('rows_changed', changed_rows)

		if (changed_rows.length || removed_rows.size)
			e.update({state: !!changed_rows.length, rows: !!removed_rows.size})

		if (rows_marked && e.save_row_on != 'manual' && e.save_row_remove_on == 'input')
			e.save()

		e.end_update()

		return removed_rows.size > 0 || rows_marked
	}

	e.remove_selected_rows = function(ev) {
		return e.remove_rows(e.selected_rows.keys(), ev)
	}

	// row moving -------------------------------------------------------------

	e.expanded_child_row_count = function(ri) {
		let n = 0
		if (e.parent_field) {
			let row = e.rows[ri]
			let min_parent_count = row.parent_rows.length + 1
			for (ri++; ri < e.rows.length; ri++) {
				let child_row = e.rows[ri]
				if (child_row.parent_rows.length < min_parent_count)
					break
				n++
			}
		}
		return n
	}

	function update_index_field_for_children_of(row) {
		let index = 1
		let min_parent_count = row ? row.parent_rows.length + 1 : 0
		for (let ri = row ? e.row_index(row) + 1 : 0; ri < e.rows.length; ri++) {
			let child_row = e.rows[ri]
			if (child_row.parent_rows.length < min_parent_count)
				break
			if (child_row.parent_row == row)
				e.set_cell_val(child_row, e.index_field, index++)
		}
	}

	function update_index_field() {
		if (!e.index_field)
			return
		if (e.parent_field) {
			reset_indices_for_children_of(old_parent_row)
			if (parent_row != old_parent_row)
				reset_indices_for_children_of(parent_row)
		} else {
			let index = 1
			for (let ri = 0; ri < e.rows.length; ri++)
				e.set_cell_val(e.rows[ri], e.index_field, index++)
		}
	}

	e.start_move_selected_rows = function() {

		let focused_ri  = e.focused_row_index
		let selected_ri = or(e.selected_row_index, focused_ri)

		let move_ri1 = min(focused_ri, selected_ri)
		let move_ri2 = max(focused_ri, selected_ri)
		move_ri2 += 1 + e.expanded_child_row_count(move_ri2)
		let move_n = move_ri2 - move_ri1

		let top_row = e.rows[move_ri1]
		let parent_row = top_row.parent_row

		// check to see that all selected rows are siblings or children of the first one.
		if (e.parent_field)
			for (let ri = move_ri1; ri < move_ri2; ri++)
				if (e.rows[ri].parent_rows.length < top_row.parent_rows.length)
					return

		// compute allowed row range in which to move the rows.
		let ri1 = 0
		let ri2 = e.rows.length
		if (!e.can_change_parent && e.parent_field && parent_row) {
			let parent_ri = e.row_index(parent_row)
			ri1 = parent_ri + 1
			ri2 = parent_ri + 1 + e.expanded_child_row_count(parent_ri)
		}
		ri2 -= move_n // adjust to after removal.

		let move_rows = e.rows.splice(move_ri1, move_n)

		let state = {
			move_ri1: move_ri1,
			move_ri2: move_ri2,
			move_n: move_n,
			parent_row: parent_row,
			ri1: ri1,
			ri2: ri2,
		}

		state.rows = move_rows

		state.finish = function(insert_ri, parent_row) {

			e.rows.splice(insert_ri, 0, ...move_rows)

			let row = move_rows[0]
			let old_parent_row = row.parent_row

			change_row_parent(row, parent_row)

			update_row_index()

			e.focused_row_index = insert_ri + (move_ri1 == focused_ri ? 0 : move_n - 1)

			if (!e.rowset_url && (e.row_states || e.row_vals) && e.param_vals) {
				// detail nav with client-side rowset: move visible rows to index 0
				// in the unfiltered rows array so that move_ri1, move_ri2 and insert_ri
				// point to the same rows in both unfiltered and filtered arrays.
				let r1 = []
				let r2 = []
				for (let ri = 0; ri < e.all_rows.length; ri++) {
					let visible = e.row_is_visible(e.all_rows[ri])
					;(visible ? r1 : r2).push(e.all_rows[ri])
				}
				e.all_rows = [].concat(r1, r2)
			}

			if (e.parent_field)
				e.all_rows = e.rows.slice()
			else
				e.all_rows.move(move_ri1, move_n, insert_ri)

			update_row_index()

			e.begin_update()

			update_index_field()

			e.rows_moved = true
			if (e.save_row_move_on == 'input')
				e.save()
			else
				e.show_action_band(true)

			e.update({rows: true})

			e.end_update()

		}

		return state
	}

	// ajax requests ----------------------------------------------------------

	let requests

	function add_request(req) {
		if (!requests)
			requests = new Set()
		requests.add(req)
	}

	function abort_ajax_requests() {
		if (requests)
			for (let req of requests)
				req.abort()
	}

	// loading ----------------------------------------------------------------

	e.reset = function() {

		if (!e.attached)
			return
		if (!e.rowset)
			return

		let refocus = refocus_state('val')
		force_unfocus_focused_cell()

		e.changed_rows = null // Set(row)
		e.rows_moved = false

		e.can_edit        = strict_or(e.rowset.can_edit       , true) && e.can_edit
		e.can_add_rows    = strict_or(e.rowset.can_add_rows   , true) && e.can_add_rows
		e.can_remove_rows = strict_or(e.rowset.can_remove_rows, true) && e.can_remove_rows
		e.can_change_rows = strict_or(e.rowset.can_change_rows, true) && e.can_change_rows

		init_all()

		e.begin_update()
		e.update({fields: true, rows: true})
		refocus()
		e.end_update()
		e.fire('reset', true)

	}

	e.reload = function(param_vals) {
		if (!e.attached) {
			e.update({reload: true})
			return
		}
		init_param_vals(param_vals)
		if (!e.rowset_url || e.param_vals === false) {
			// client-side rowset or param vals not available: reset it.
			e.reset()
			return
		}
		let uri = e.param_vals ? url(e.rowset_url, {params: json(e.param_vals)}) : e.rowset_url
		if (requests && requests.size && !e.load_request) {
			e.notify('error',
				S('error_load_while_saving', 'Cannot reload while saving is in progress.'))
			return
		}
		e.abort_loading()
		let req = ajax({
			url: uri,
			progress: load_progress,
			success: load_success,
			fail: load_fail,
			done: load_done,
			slow: load_slow,
			slow_timeout: e.slow_timeout,
		})
		add_request(req)
		e.load_request = req
		e.loading = true
		loading(true)
	}

	e.abort_loading = function() {
		if (!e.load_request)
			return
		e.load_request.abort()
		e.load_request = null
	}

	function load_progress(p, loaded, total) {
		e.do_update_load_progress(p, loaded, total)
		e.fire('load_progress', p, loaded, total)
	}

	function load_slow(show) {
		e.do_update_load_slow(show)
		e.fire('load_slow', show)
	}

	function load_done() {
		requests.delete(this)
		e.load_request = null
		e.loading = false
		loading(false)
	}

	function load_fail(type, status, message, body) {
		let err
		if (type == 'http')
			err = S('error_http', 'Server returned {0} {1}').subst(status, message)
		else if (type == 'network')
			err = S('error_load_network', 'Loading failed: network error.')
		else if (type == 'timeout')
			err = S('error_load_timeout', 'Loading failed: timed out.')
		if (err)
			e.notify('error', err, body)
		e.do_update_load_fail(true, err, type, status, message, body)
		e.fire('load_fail', err, type, status, message, body)
	}

	function load_success(rs) {
		e.rowset = rs
		e.reset()
	}

	// saving changes ---------------------------------------------------------

	function row_changed(row) {
		if (row.nosave || (row.is_new && (!row.modified || row.removed)))
			return
		e.changed_rows = e.changed_rows || new Set()
		e.changed_rows.add(row)
		e.show_action_band(true)
	}

	function add_row_changes(row, rows) {
		if (row.save_request)
			return // currently saving this row.
		if (row.is_new) {
			let t = {type: 'new', values: {}}
			for (let fi = 0; fi < e.all_fields.length; fi++) {
				let field = e.all_fields[fi]
				let val = row[fi]
				if (val !== field.default && !field.nosave)
					t.values[field.name] = val
			}
			rows.push(t)
		} else if (row.removed) {
			let t = {type: 'remove', values: {}}
			for (let col of e.pk.split(/\s+/))
				t.values[col] = e.cell_old_val(row, col)
			rows.push(t)
		} else if (row.modified) {
			let t = {type: 'update', values: {}}
			let found
			for (let field of e.all_fields) {
				if (e.cell_modified(row, field) && !field.nosave) {
					t.values[field.name] = row[field.val_index]
					found = true
				}
			}
			if (found) {
				for (let col of e.pk.split(/\s+/))
					t.values[col+':old'] = e.cell_old_val(row, col)
				rows.push(t)
			}
		}
	}

	function pack_changes() {
		let changes = {rows: []}
		for (let row of e.changed_rows)
			add_row_changes(row, changes.rows)
		return changes
	}

	function apply_result(result, changed_rows) {
		let rows_to_remove = []
		for (let i = 0; i < result.rows.length; i++) {
			let rt = result.rows[i]
			let row = changed_rows[i]

			let err = typeof rt.error == 'string' ? rt.error : undefined
			let row_failed = rt.error != null
			e.set_row_error(row, err)

			if (rt.remove) {
				rows_to_remove.push(row)
			} else {
				if (!row_failed) {
					let is_new_changed = e.set_row_state(row, 'is_new', false, false, false)
					let modified_changed = e.set_row_state(row, 'modified', false, false, false)
					if (is_new_changed)
						row_state_changed(row, 'is_new', false)
					if (modified_changed)
						row_state_changed(row, 'modified', false)
				}
				if (rt.field_errors) {
					for (let k in rt.field_errors) {
						let field = e.all_fields[k]
						let err = rt.field_errors[k]
						err = typeof err == 'string' ? err : undefined
						e.set_cell_state(row, field, 'error', err)
					}
				}
				if (rt.values)
					for (let k in rt.values)
						e.reset_cell_val(row, e.all_fields[k], rt.values[k])
			}
		}
		e.remove_rows(rows_to_remove, {forever: true, refocus: true})

		if (result.sql_trace && result.sql_trace.length)
			print(result.sql_trace.join('\n'))
	}

	function set_save_state(rows, req) {
		for (let row of e.all_rows)
			e.set_row_state(row, 'save_request', req, undefined, false)
	}

	function save_to_server() {
		let req = ajax({
			url: e.rowset_url,
			upload: pack_changes(),
			changed_rows: Array.from(e.changed_rows),
			success: save_success,
			fail: save_fail,
			done: save_done,
			slow: save_slow,
			slow_timeout: e.slow_timeout,
		})
		e.changed_rows = null
		e.rows_moved = false
		e.show_action_band(false)
		add_request(req)
		set_save_state(req.rows, req)
		e.fire('saving', true)
	}

	e.can_save_changes = function() {
		return !!(e.rowset_url || e.static_rowset)
	}

	e.save = function() {
		if (!e.changed_rows && !e.rows_moved)
			return
		if (e.static_rowset) {
			if (e.save_row_states)
				save_to_row_states()
			else
				save_to_row_vals()
		} else if (e.rowset_url)
			save_to_server()
	}

	function save_slow(show) {
		e.fire('saving_slow', show)
	}

	function save_done() {
		requests.delete(this)
		set_save_state(this.rows, null)
		e.fire('saving', false)
	}

	function save_success(result) {
		apply_result(result, this.changed_rows)
	}

	function save_fail(type, status, message, body) {
		let err
		if (type == 'http')
			err = S('error_http', 'Server returned {0} {1}').subst(status, message)
		else if (type == 'network')
			err = S('error_save_network', 'Saving failed: network error.')
		else if (type == 'timeout')
			err = S('error_save_timeout', 'Saving failed: timed out.')
		if (err)
			e.notify('error', err, body)
		e.fire('save_fail', err, type, status, message, body)
	}

	e.revert_changes = function() {
		if (!e.changed_rows)
			return
		e.begin_update()
		/*
		for (let row of e.changed_rows)
			if (row.is_new)
				//
			else if (row.removed)
				//
			else if (row.modified)
				//
		*/
		e.changed_rows = null
		e.show_action_band(false)
		e.end_update()
	}

	e.commit_changes = function() {
		if (!e.changed_rows)
			return
		e.begin_update()
		let rows_to_remove = []
		for (let row of e.changed_rows) {
			e.set_row_error(row, undefined)
			if (row.removed) {
				rows_to_remove.push(row)
			} else {
				let is_new_changed   = e.set_row_state(row, 'is_new', false, false, false)
				let modified_changed = e.set_row_state(row, 'modified', false, false, false)
				if (is_new_changed)
					row_state_changed(row, 'is_new', false)
				if (modified_changed)
					row_state_changed(row, 'modified', false)
				for (let field of e.all_fields)
					e.reset_cell_val(row, field, e.cell_val(row, field))
			}
		}
		e.remove_rows(rows_to_remove, {forever: true, refocus: true})
		e.changed_rows = null
		e.rows_moved = false
		e.show_action_band(false)
		e.end_update()
	}

	// row (de)serialization --------------------------------------------------

	e.save_row = return_true // stub

	e.serialize_row_vals = function(row) {
		let vals = {}
		for (let field of e.all_fields) {
			let v = e.cell_val(row, field)
			if (v !== field.default && !field.nosave)
				vals[field.name] = v
		}
		return vals
	}

	e.deserialize_row_vals = function(vals) {
		let row = []
		for (let fi = 0; fi < e.all_fields.length; fi++) {
			let field = e.all_fields[fi]
			row[fi] = strict_or(vals[field.name], field.default)
		}
		return row
	}

	e.serialize_all_row_vals = function() {
		let rows = []
		for (let row of e.all_rows)
			if (!row.removed && !row.nosave) {
				let vals = e.serialize_row_vals(row)
				if (e.save_row(vals) !== 'skip')
					rows.push(vals)
			}
		return rows
	}

	e.deserialize_all_row_vals = function(row_vals) {
		if (!row_vals)
			return
		let rows = []
		for (vals of row_vals) {
			let row = e.deserialize_row_vals(vals)
			rows.push(row)
		}
		return rows
	}

	e.serialize_all_row_states = function() {
		let rows = []
		for (let row of e.all_rows) {
			if (!row.nosave) {
				let state = {}
				if (row.is_new)
					state.is_new = true
				if (row.removed)
					state.removed = true
				state.vals = e.serialize_row_vals(row)
				for (let field of e.all_fields) {
					if (!field.nosave) {
						let modified = e.cell_state(row, field, 'modified')
						if (modified) {
							let t = attr(state, 'cell')
							let old_val = e.cell_state(row, field, 'old_val')
							if (old_val != null)
								t.old_val = old_val
							let prev_val = e.cell_state(row, field, 'prev_val')
							if (prev_val != null)
								t.prev_val = prev_val
						}
					}
				}
				rows.push(state)
			}
		}
		return rows
	}

	e.deserialize_all_row_states = function(row_states) {
		if (!row_states)
			return
		let rows = []
		for (state of row_states) {
			let row = state.vals ? e.deserialize_row_vals(state.vals) : []
			if (state.cells)
				for (let col of state.cells) {
					let field = e.all_fields[col]
					if (field) {
						let t = state.cells[col]
						for (let k in t)
							e.set_cell_state(row, field, k, t[k], undefined, false)
					}
				}
			rows.push(row)
		}
		return rows
	}

	let save_barrier

	function save_to_row_vals() {

		save_barrier = true
		e.row_vals = e.serialize_all_row_vals()
		save_barrier = false

		e.commit_changes()
	}

	function save_to_row_states() {
		save_barrier = true
		e.row_states = e.serialize_all_row_states()
		save_barrier = false
	}

	// responding to notifications from the server ----------------------------

	e.notify = function(type, message, ...args) {
		notify(message, type)
		e.fire('notify', type, message, ...args)
	}

	e.do_update_loading = function(on) { // stub
		if (!on) return
		e.load_overlay(true)
	}

	function loading(on) {
		e.class('loading', on)
		e.do_update_loading(on)
		e.do_update_load_progress(0)
		e.fire('loading', on)
	}

	e.do_update_load_progress = noop // stub

	e.do_update_load_slow = function(on) { // stub
		if (on)
			e.load_overlay(true, 'waiting',
				S('slow', 'Still working on it...'),
				S('stop_waiting', 'Stop waiting'))
		else
			e.load_overlay(true, 'waiting',
				S('loading', 'Loading...'),
				S('stop_loading', 'Stop loading'))
	}

	e.do_update_load_fail = function(on, error, type, status, message, body) {
		if (!e.attached)
			return
		if (type == 'abort')
			e.load_overlay(false)
		else
			e.load_overlay(on, 'error', error, null, body)
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
						e.reload()
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
					e.abort_loading()
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

	// action bar -------------------------------------------------------------

	e.set_action_band_visible = function(v) {
		e.show_action_band(v == 'always' || (v == 'auto' && e.changed_rows))
	}

	e.show_action_band = function(on) {
		if (e.action_band_visible == 'no')
			return
		if (on && !e.action_band) {
			e.action_band = action_band({
				layout: 'save:ok',
				buttons: {
					'save': function() {
						e.save()
					},
				}
			})
			e.add(e.action_band)
		}
		e.action_band.show(on)
	}

	// quick-search -----------------------------------------------------------

	function* qs_reach_row(start_row, ri_offset) {
		let n = e.rows.length
		let ri1 = or(e.row_index(start_row), 0) + (ri_offset || 0)
		for (let ri = ri1; ri < n; ri++)
			yield ri
		for (let ri = 0; ri < ri1; ri++)
			yield ri
	}

	function reset_quicksearch() {
		e.quicksearch_text = ''
		e.quicksearch_field = null
	}

	reset_quicksearch()

	e.quicksearch = function(s, start_row, ri_offset) {

		if (!s) {
			reset_quicksearch()
			e.update({state: true})
			return
		}

		s = s.lower()

		let field = e.focused_field || (e.quicksearch_col && e.all_fields[e.quicksearch_col])
		if (!field)
			return

		for (let ri of qs_reach_row(start_row, ri_offset)) {
			let row = e.rows[ri]
			let cell_text = e.cell_text_val(row, field).lower()
			if (cell_text.starts(s)) {
				if (e.focus_cell(ri, field.index, 0, 0, {
						input: e,
						must_not_move_row: true,
						must_not_move_col: true,
						quicksearch_text: s,
						quicksearch_field: field,
				})) {
					break
				}
			}
		}

	}

	// picker protocol --------------------------------------------------------

	e.row_display_val = function(row) { // stub
		if (!e.all_fields.length)
			return 'no fields'
		let field = e.all_fields[e.display_col]
		if (!field)
			return 'no display field'
		return e.cell_display_val(row, field)
	}

	e.dropdown_display_val = function() {
		if (!e.focused_row)
			return
		return e.row_display_val(e.focused_row)
	}

	e.pick_near_val = function(delta, ev) {
		if (e.focus_cell(true, true, delta, 0, ev))
			e.fire('val_picked', ev)
	}

	e.set_display_col = function() {
		reset_quicksearch()
		e.update({vals: true, state: true})
	}
	e.prop('display_col', {store: 'var'})

	init_all()

	// server-side props ------------------------------------------------------

	e.set_sql_db = function(v) {
		if (!e.gid)
			return
		e.rowset_url = v ? 'sql_rowset.json/' + e.gid : null
		e.reload()
	}

	e.set_sql_select = e.reload

	e.prop('sql_select_all'        , {store: 'var', slot: 'server'})
	e.prop('sql_select'            , {store: 'var', slot: 'server'})
	e.prop('sql_select_one'        , {store: 'var', slot: 'server'})
	e.prop('sql_select_one_update' , {store: 'var', slot: 'server'})
	e.prop('sql_pk'                , {store: 'var', slot: 'server'})
	e.prop('sql_insert_fields'     , {store: 'var', slot: 'server'})
	e.prop('sql_update_fields'     , {store: 'var', slot: 'server'})
	e.prop('sql_where'             , {store: 'var', slot: 'server'})
	e.prop('sql_where_row'         , {store: 'var', slot: 'server'})
	e.prop('sql_where_row_update'  , {store: 'var', slot: 'server'})
	e.prop('sql_schema'            , {store: 'var', slot: 'server'})
	e.prop('sql_db'                , {store: 'var', slot: 'server'})

}

// ---------------------------------------------------------------------------
// view-less nav with manual lifetime management.
// ---------------------------------------------------------------------------

component('x-bare-nav', function(e) {

	nav_widget(e)

	e.scroll_to_cell = noop
	e.do_update_cell_state = noop
	e.do_update_row_state = noop

	let init = e.init
	e.init = function() {
		init()
		e.bind(true)
	}

	e.free = function() {
		e.bind(false)
	}

	let val_widget_do_update = e.do_update
	e.do_update = function(opt) {
		if (!e.attached)
			return
		if (opt.reload) {
			e.reload()
			return
		}
		if (!opt || opt.val) {
			val_widget_do_update()
			return
		}
	}

})

// ---------------------------------------------------------------------------
// global one-row nav for all standalone (i.e. not bound to a nav) widgets.
// ---------------------------------------------------------------------------

global_val_nav = function() {
	global_val_nav = () => nav // memoize.
	let nav = bare_nav({
		rowset: {
			fields: [],
			rows: [[]],
		},
	})
	nav.focus_cell(true, false)
	return nav
}

// ---------------------------------------------------------------------------
// nav dropdown mixin
// ---------------------------------------------------------------------------

function nav_dropdown_widget(e) {

	dropdown.construct(e)

	e.set_val_col = function(v) {
		if (!e.picker) return
		e.picker.val_col = v
	}
	e.prop('val_col', {store: 'var'})

	e.set_display_col = function(v) {
		if (!e.picker) return
		e.picker.display_col = v
	}
	e.prop('display_col', {store: 'var'})

	e.set_rowset_name = function(v) {
		if (!e.picker) return
		e.picker.rowset_name = v
	}
	e.prop('rowset_name', {store: 'var', type: 'rowset'})

	e.on('opened', function() {
		if (!e.picker) return
		e.picker.scroll_to_focused_cell()
	})

}

// ---------------------------------------------------------------------------
// lookup dropdown (for binding to fields with `lookup_nav_gid`)
// ---------------------------------------------------------------------------

component('x-lookup-dropdown', function(e) {

	dropdown.construct(e)

	e.create_picker = function(opt) {
		let ln_gid = e.field.lookup_nav_gid
		if (!ln_gid)
			return
		opt.gid         = ln_gid
		opt.val_col     = e.field.lookup_col
		opt.display_col = e.field.display_col

		let picker = component.create(opt)
		picker.gid = null // not saving into the original.
		return picker
	}

	e.on('opened', function() {
		if (!e.picker) return
		e.picker.scroll_to_focused_cell()
	})

})

// ---------------------------------------------------------------------------
// field types and prop attrs
// ---------------------------------------------------------------------------

{
	field_prop_attrs = {
		text : {slot: 'lang'},
		w    : {slot: 'user'},
	}

	all_field_types = {
		default: null,
		w: 100,
		min_w: 22,
		max_w: 2000,
		align: 'left',
		allow_null: true,
		editable: true,
		sortable: true,
		maxlen: 256,
		null_text: S('null_text', ''),
		empty_text: S('empty_text', 'empty text'),
		lookup_failed_display_val: function(v) {
			return this.format(v)
		},
	}

	all_field_types.format = function(v) {
		return String(v)
	}

	all_field_types.editor = function(...opt) {
		if (this.lookup_nav_gid)
			return lookup_dropdown(...opt)
		return input(...opt)
	}

	all_field_types.to_text = function(v) {
		return v != null ? String(v).replace('\n', '\\n') : ''
	}

	all_field_types.from_text = function(s) {
		s = s.trim()
		return s !== '' ? s.replace('\\n', '\n') : null
	}

	field_types = {}

	// numbers

	let number = {align: 'right', min: 0, max: 1/0, multiple_of: 1}
	field_types.number = number

	number.validate = function(val, field) {
		val = num(val)

		if (typeof val != 'number' || val !== val)
			return S('error_invalid_number', 'Invalid number')

		if (field.multiple_of != null)
			if (val % field.multiple_of != 0) {
				if (field.multiple_of == 1)
					return S('error_integer', 'Value must be an integer')
				return S('error_multiple', 'Value must be multiple of {0}').subst(field.multiple_of)
			}
	}

	number.editor = function(...opt) {
		return spin_input(update({
			button_placement: 'left',
		}, ...opt))
	}

	number.from_text = function(s) {
		s = s.trim()
		s = s !== '' ? s : null
		let x = num(s)
		return x != null ? x : s
	}

	number.to_text = function(x) {
		return x != null ? String(x) : ''
	}

	// file sizes

	let filesize = update({}, number)
	field_types.filesize = filesize

	let log = Math.log
	let suffix = [' B', ' KB', ' MB', ' GB', ' TB']
	let magnitudes = {KB: 1, MB: 2, GB: 3}
	filesize.format = function(x) {
		let mag = this.filesize_magnitude
		let dec = this.filesize_decimals || 0
		let min = this.filesize_min || 1/10**dec
		let i = mag ? magnitudes[mag] : parseInt(floor(log(x) / log(1024)))
		let z = x / 1024**i
		let s = z.toFixed(dec) + suffix[i]
		return z < min ? () => span({class: 'x-dba-insignificant-size'}, s) : s
	}

	// dates

	let date = {align: 'right', min: -(2**52), max: 2**52}
	field_types.date = date

	date.validate = function(val, field) {
		if (typeof val != 'number' || val !== val)
			return S('error_date', 'Invalid date')
	}

	date.format = function(t) {
		_d.setTime(t * 1000)
		return _d.toLocaleString(locale, this.date_format)
	}

	date.date_format =
		{weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' }

	date.editor = function(...opt) {
		return date_dropdown(update({
			align: 'right',
			mode: 'fixed',
		}, ...opt))
	}

	// datetime

	let datetime = {align: 'right'}
	field_types.datetime = datetime

	datetime.to_time = function(d) {
		return Date.parse(d + ' UTC') / 1000
	}

	datetime.from_time = function(t) {
		_d.setTime(t * 1000)
		return _d.toISOString().slice(0, 19).replace('T', ' ')
	}

	datetime.format = function(s) {
		let t = datetime.to_time(s)
		_d.setTime(t * 1000)
		return _d.toLocaleString(locale, this.date_format)
	}

	datetime.date_format =
		{weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' }

	datetime.editor = function(...opt) {
		return date_dropdown(update({
			align: 'right',
			mode: 'fixed',
		}, ...opt))
	}

	// booleans

	let bool = {align: 'center', w: 26, max_w: 28}
	field_types.bool = bool

	bool.true_text = () => H('<div class="fa fa-check"></div>')
	bool.false_text = ''

	bool.null_text = () => H('<div class="fa fa-square"></div>')

	bool.validate = function(val, field) {
		if (typeof val != 'boolean')
			return S('error_boolean', 'Value not true or false')
	}

	bool.format = function(val) {
		return val ? this.true_text : this.false_text
	}

	bool.editor = function(...opt) {
		return checkbox(update({
			center: true,
		}, ...opt))
	}

	// enums

	let enm = {}
	field_types.enum = enm

	enm.editor = function(...opt) {
		return list_dropdown(update({
			items: this.enum_values,
			mode: 'fixed',
			val_col: 0,
		}, ...opt))
	}

	// colors

	let color = {}
	field_types.color = color

	color.format = function(color) {
		return div({class: 'x-item-color', style: 'background-color: '+color}, H('&nbsp;'))
	}

	color.editor = function(...opt) {
		return color_dropdown(update({
			mode: 'fixed',
		}, ...opt))
	}

	// icons

	let icon = {}
	field_types.icon = icon

	icon.format = function(icon) {
		return div({class: 'fa '+icon})
	}

	icon.editor = function(...opt) {
		return icon_dropdown(update({
			mode: 'fixed',
		}, ...opt))
	}

}

