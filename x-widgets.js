/*

	X-WIDGETS: Data-driven web components in JavaScript.
	Written by Cosmin Apreutesei. Public Domain.

*/

// ---------------------------------------------------------------------------
// rowset
// ---------------------------------------------------------------------------

/*
	rowset(...options) -> rs

	rs.can_edit        : can edit at all (true)
	rs.can_add_rows    : allow adding/inserting rows (false)
	rs.can_remove_rows : allow removing rows (false)
	rs.can_change_rows : allow editing cell values (false)

	rs.fields: [{attr->val}, ...]

	identification:
		name           : field name (defaults to field's numeric index)
		type           : for choosing a field template.

	rendering:
		text           : field name for display purposes (auto-generated default).
		visible        : field can be visible in a grid (true).

	navigation:
		focusable      : field can be focused (true).

	editing:
		client_default : default value that new rows are initialized with.
		server_default : default value that the server sets.
		editable       : allow modifying (true).
		editor         : f() -> editor instance
		from_text      : f(s) -> v
		to_text        : f(v) -> s

	validation:
		allow_null     : allow null (true).
		validate       : f(v, field) -> undefined|err_string
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

	vlookup:
		lookup_rowset  : rowset to look up values of this field into
		lookup_col     : field in lookup_rowset that matches this field
		display_col    : field in lookup_rowset to use as display_value of this field.
		lookup_failed_display_value : f(v) -> s; what to use when lookup fails.

	sorting:
		sortable       : allow sorting (true).
		compare_types  : f(v1, v2) -> -1|0|1  (for sorting)
		compare_values : f(v1, v2) -> -1|0|1  (for sorting)

	grouping:
		group_by(col) -> group_rowset

	rs.rows: Set(row)
		row[i]             : current cell value (always valid).
		row.focusable      : row can be focused (true).
		row.editable       : allow modifying (true).
		row.input_val[i]   : currently set cell value, whether valid or not.
		row.error[i]       : error message if cell is invalid.
		row.row_error      : error message if row is invalid.
		row.modified[i]    : value was modified, change not on server yet.
		row.old_value[i]   : initial value before modifying.
		row.is_new         : new row, not added on server yet.
		row.cells_modified : one or more row cells were modified.
		row.removed        : removed row, not removed on server yet.

	rowset.types : {type -> {attr->val}}

	rowset.name_col   : default `display_col` of rowsets that lookup into this rowset.

*/

{
	let upper = function(s) {
		return s.toUpperCase()
	}
	let upper2 = function(s) {
		return ' ' + s.slice(1).toUpperCase()
	}
	function auto_display_name(s) {
		return (s || '').replace(/[\w]/, upper).replace(/(_[\w])/, upper2)
	}
}

function widget_multiuser_mixin(e) {

	let refcount = 0

	e.bind_user_widget = function(user, on) {
		assert(user.has_attach_events)
		if (on)
			user_attached()
		else
			user_detached()
	}

	function user_attached() {
		refcount++
		if (refcount == 1) {
			e.isConnected = true
			e.attach()
		}
	}

	function user_detached() {
		refcount--
		assert(refcount >= 0)
		if (refcount == 0) {
			e.isConnected = false
			e.detach()
		}
	}

}

rowset = function(...options) {

	let d = {}

	d.can_edit        = true
	d.can_add_rows    = false
	d.can_remove_rows = false
	d.can_change_rows = false

	events_mixin(d)
	widget_multiuser_mixin(d)

	let field_map = new Map() // field_name->field

	d.field = function(name) {
		if (typeof name == 'number')
			return d.fields[name] // by index
		if (typeof name != 'string')
			return name // pass-through
		return field_map.get(name)
	}

	function init_fields(fields) {
		unbind_fields()
		d.fields = []
		if (!fields)
			return
		for (let i = 0; i < fields.length; i++) {
			let f = fields[i]
			let custom_attrs = d.field_attrs && d.field_attrs[f.name || i+'']
			let type = f.type || (custom_attrs && custom_attrs.type)
			let type_attrs = type && (d.types[type] || rowset.types[type])
			let field = update({index: i, rowset: d},
				rowset.all_types, d.all_types, type_attrs, f, custom_attrs)
			field.w = clamp(field.w, field.min_w, field.max_w)
			if (field.text == null)
				field.text = auto_display_name(field.name)
			field.name = field.name || i+''
			if (field.lookup_rowset)
				field.lookup_rowset = global_rowset(field.lookup_rowset)
			d.fields[i] = field
			field_map.set(field.name, field)
		}
	}

	function init_pk(pk) {
		d.pk_fields = []
		if (pk) {
			if (typeof pk == 'string')
				pk = pk.split(' ')
			for (let col of pk) {
				let field = d.field(col)
				d.pk_fields.push(field)
				field.is_pk = true
			}
		}
	}

	function init_rows(rows) {
		d.rows = (!rows || isarray(rows)) && new Set(rows) || rows
	}

	property(d, 'row_count', { get: function() { return d.rows.size } })

	function init() {
		update(d, rowset, ...options) // set options/override.
		d.client_fields = d.fields
		init_fields(d.fields)
		init_pk(d.pk)
		init_params(d.params)
		init_rows(d.rows)
	}

	d.attach = function() {
		bind_lookup_rowsets(true)
		bind_param_nav(true)
	}

	d.detach = function() {
		bind_lookup_rowsets(false)
		bind_param_nav(false)
		abort_ajax_requests()
	}

	// vlookup ----------------------------------------------------------------

	function lookup_function(field, on) {

		let index = new Map()

		function rebuild() {
			let fi = field.index
			for (let row of d.rows) {
				index.set(row[fi], row)
			}
		}

		function row_added(row) {
			index.set(row[field.index], row)
		}

		function row_removed(row) {
			index.delete(row[field.index])
		}

		function value_changed_for_field(row, val) {
			let prev_val = d.prev_value(row, field)
			index.delete(prev_val)
			index.set(val, row)
		}

		function lookup(v) {
			return index.get(v)
		}

		function bind(on) {
			d.on('loaded', rebuild, on)
			d.on('row_added', row_added, on)
			d.on('row_removed', row_removed, on)
			d.on('value_changed_for_'+field.name, value_changed_for_field, on)
		}

		rebuild()
		bind(true)

		return [lookup, bind]
	}

	d.lookup = function(field, v) {
		if (!field.lookup)
			[field.lookup, field.bind_lookup] = lookup_function(field, true)
		return field.lookup(v)
	}

	function unbind_fields() {
		if (d.fields)
			for (let field of d.fields)
				if (field.bind_lookup)
					field.bind_lookup(false)
	}

	// sorting ----------------------------------------------------------------

	d.compare_rows = function(row1, row2) {
		// invalid rows come first.
		if (row1.invalid != row2.invalid)
			return row1.invalid ? -1 : 1
		return 0
	}

	d.compare_types = function(v1, v2) {
		// nulls come first.
		if ((v1 === null) != (v2 === null))
			return v1 === null ? -1 : 1
		// NaNs come second.
		if ((v1 !== v1) != (v2 !== v2))
			return v1 !== v1 ? -1 : 1
		return 0
	}

	d.compare_values = function(v1, v2) {
		return v1 !== v2 ? (v1 < v2 ? -1 : 1) : 0
	}

	function field_comparator(field) {

		var compare_rows = d.compare_rows
		var compare_types  = field.compare_types  || d.compare_types
		var compare_values = field.compare_values || d.compare_values
		var field_index = field.index

		return function(row1, row2) {
			var r = compare_rows(row1, row2)
			if (r) return r

			let v1 = row1[field_index]
			let v2 = row2[field_index]

			var r = compare_types(v1, v2)
			if (r) return r

			return compare_values(v1, v2)
		}
	}

	// order_by: [[field1,'desc'|'asc'],...]
	d.comparator = function(order_by) {
		let s = []
		let cmps = []
		for (let [field, dir] of order_by) {
			let i = field.index
			cmps[i] = field_comparator(field)
			let r = dir == 'desc' ? -1 : 1
			// invalid rows come first
			s.push('var v1 = r1.row_error == null')
			s.push('var v2 = r2.row_error == null')
			s.push('if (v1 < v2) return -1')
			s.push('if (v1 > v2) return  1')
			// invalid values come after
			s.push('var v1 = !(r1.error && r1.error['+i+'] != null)')
			s.push('var v2 = !(r2.error && r2.error['+i+'] != null)')
			s.push('if (v1 < v2) return -1')
			s.push('if (v1 > v2) return  1')
			// modified rows come after
			s.push('var v1 = !r1.cells_modified')
			s.push('var v2 = !r2.cells_modified')
			s.push('if (v1 < v2) return -1')
			s.push('if (v1 > v2) return  1')
			// compare values using the rowset comparator
			s.push('var cmp = cmps['+i+']')
			s.push('var r = cmp(r1, r2, '+i+')')
			s.push('if (r) return r * '+r)
		}
		s.push('return 0')
		s = 'let f = function(r1, r2) {\n\t' + s.join('\n\t') + '\n}; f'
		return eval(s)
	}

	// get/set cell & row state (storage api) ---------------------------------

	d.cell_state = function(row, field, key, default_val) {
		let v = row[key] && row[key][field.index]
		return v !== undefined ? v : default_val
	}

	d.set_cell_state = function(row, field, key, val, default_val) {
		let t = array_attr(row, key)
		let old_val = t[field.index]
		if (old_val === undefined)
			old_val = default_val
		let changed = old_val !== val
		if (changed)
			t[field.index] = val
		return changed
	}

	d.set_row_state = function(row, key, val, default_val, prop, ev) {
		let old_val = row[key]
		if (old_val === undefined)
			old_val = default_val
		let changed = old_val !== val
		if (changed)
			row[key] = val
		return changed
	}

	function cell_state_changed(row, field, prop, val, ev) {
		d.fire('cell_state_changed', row, field, prop, val, ev)
		d.fire('cell_state_changed_for_'+field.name, row, prop, val, ev)
		d.fire(prop+'_changed', row, field, val, ev)
		d.fire(prop+'_changed_for_'+field.name, row, val, ev)
	}

	function row_state_changed(row, prop, val, ev) {
		d.fire('row_state_changed', row, prop, val, ev)
		d.fire(prop+'_changed', row, val, ev)
	}

	// filtering --------------------------------------------------------------

	d.filter_rowset = function(field, ...opt) {

		field = d.field(field)
		let rs_field = {}
		for (let k of [
			'name', 'text', 'type', 'align', 'min_w', 'max_w',
			'format', 'true_text', 'false_text', 'null_text',
			'lookup_rowset', 'lookup_col', 'display_col', 'lookup_failed_display_value',
			'sortable',
		])
			rs_field[k] = field[k]

		let rs = rowset({
			fields: [
				{text: '', type: 'bool'},
				rs_field,
			],
			filtered_field: field,
		}, ...opt)

		rs.load = function() {
			let fi = field.index
			let rows = new Set()
			let val_set = new Set()
			for (let row of d.rows) {
				let v = row[fi]
				if (!val_set.has(v)) {
					rows.add([true, v])
					val_set.add(v)
				}
			}
			rs.rows = rows
			rs.fire('loaded')
		}

		return rs
	}

	d.row_filter = function(expr) {
		let expr_bin_ops = {'&&': 1, '||': 1}
		let expr_un_ops = {'!': 1}
		let s = []
		function push_expr(expr) {
			let op = expr[0]
			if (op in expr_bin_ops) {
				s.push('(')
				for (let i = 1; i < expr.length; i++) {
					if (i > 1)
						s.push(' '+op+' ')
					push_expr(expr[i])
				}
				s.push(')')
			} else if (op in expr_un_ops) {
				s.push('(')
				s.push(op)
				s.push('(')
				for (let i = 1; i < expr.length; i++)
					push_expr(expr[i])
				s.push('))')
			} else
				s.push('row['+d.field(expr[1]).index+'] '+expr[0]+' '+json(expr[2]))
		}
		push_expr(expr)
		s = 'let f = function(row) {\n\treturn ' + s.join('') + '\n}; f'
		return eval(s)
	}

	d.filter_rowsets_filter = function(filter_rowsets) {
		let expr = ['&&']
		if (filter_rowsets)
			for (let [field, rs] of filter_rowsets) {
				let e = ['&&']
				for (let row of rs.rows)
					if (!row[0])
						e.push(['!=', rs.filtered_field.index, row[1]])
				if (e.length > 1)
					expr.push(e)
			}
		return expr.length > 1 ? d.row_filter(expr) : return_true
	}

	// get/set cell values and cell & row state -------------------------------

	d.value = function(row, field) {
		return row[field.index]
	}

	d.input_value = function(row, field) {
		return d.cell_state(row, field, 'input_value', d.value(row, field))
	}

	d.old_value = function(row, field) {
		return d.cell_state(row, field, 'old_value', d.value(row, field))
	}

	d.prev_value = function(row, field) {
		return d.cell_state(row, field, 'prev_value', d.value(row, field))
	}

	d.validate_value = function(field, val, row, ev) {

		if (val == null)
			if (!field.allow_null)
				return S('error_not_null', 'NULL not allowed')
			else
				return

		if (field.min != null && val < field.min)
			return S('error_min_value', 'Value must be at least {0}').format(field.min)

		if (field.max != null && val > field.max)
			return S('error_max_value', 'Value must be at most {0}').format(field.max)

		let lr = field.lookup_rowset
		if (lr) {
			field.lookup_field = field.lookup_field || lr.field(field.lookup_col)
			field.display_field = field.display_field || lr.field(field.display_col || lr.name_col)
			if (!lr.lookup(field.lookup_field, val))
				return S('error_lookup', 'Value not found in lookup rowset')
		}

		let err = field.validate && field.validate.call(d, val, field)
		if (typeof err == 'string')
			return err

		return d.fire('validate_'+field.name, val, row, ev)
	}

	d.on_validate_value = function(col, validate, on) {
		d.on('validate_'+col, validate, on)
	}

	d.validate_row = function(row) {
		return d.fire('validate', row)
	}

	d.can_focus_cell = function(row, field) {
		return (!row || row.focusable != false) && (field == null || field.focusable != false)
	}

	d.can_change_value = function(row, field) {
		return d.can_edit && d.can_change_rows && (!row || row.editable != false)
			&& (field == null || field.editable)
			&& d.can_focus_cell(row, field)
	}

	d.create_row_editor = function(row, ...options) {} // stub

	d.create_editor = function(field, ...options) {
		if (field)
			return field.editor(...options)
		else
			return d.create_row_editor(...options)
	}

	d.cell_error = function(row, field) {
		return d.cell_state(row, field, 'error')
	}

	d.cell_modified = function(row, field) {
		return d.cell_state(row, field, 'modified', false)
	}

	d.set_row_error = function(row, err, ev) {
		err = typeof err == 'string' ? err : undefined
		if (err != null) {
			d.fire('notify', 'error', err)
			print(err)
		}
		if (d.set_row_state(row, 'row_error', err))
			row_state_changed(row, 'row_error', ev)
	}

	d.row_has_errors = function(row) {
		if (row.row_error != null)
			return true
		for (let field of d.fields)
			if (d.cell_error(row, field) != null)
				return true
		return false
	}

	d.set_value = function(row, field, val, ev) {
		if (val === undefined)
			val = null
		let err = d.validate_value(field, val, row, ev)
		err = typeof err == 'string' ? err : undefined
		let invalid = err != null
		let cur_val = row[field.index]
		let val_changed = !invalid && val !== cur_val

		let input_val_changed = d.set_cell_state(row, field, 'input_value', val, cur_val)
		let cell_err_changed = d.set_cell_state(row, field, 'error', err)
		let row_err_changed = d.set_row_state(row, 'row_error')

		if (val_changed) {
			let was_modified = d.cell_modified(row, field)
			let modified = val !== d.old_value(row, field)

			row[field.index] = val
			d.set_cell_state(row, field, 'prev_value', cur_val)
			if (!was_modified)
				d.set_cell_state(row, field, 'old_value', cur_val)
			let cell_modified_changed = d.set_cell_state(row, field, 'modified', modified, false)
			let row_modified_changed = modified && (!(ev && ev.row_not_modified))
				&& d.set_row_state(row, 'cells_modified', true, false)

			cell_state_changed(row, field, 'value', val, ev)
			if (cell_modified_changed)
				cell_state_changed(row, field, 'cell_modified', modified, ev)
			if (row_modified_changed)
				row_state_changed(row, 'row_modified', true, ev)
			row_changed(row)
		}

		if (input_val_changed)
			cell_state_changed(row, field, 'input_value', val, ev)
		if (cell_err_changed)
			cell_state_changed(row, field, 'cell_error', err, ev)
		if (row_err_changed)
			row_state_changed(row, 'row_error', undefined, ev)

		return !invalid
	}

	d.reset_value = function(row, field, val, ev) {
		if (val === undefined)
			val = null
		let cur_val = row[field.index]
		let input_val_changed = d.set_cell_state(row, field, 'input_value', val, cur_val)
		let cell_modified_changed = d.set_cell_state(row, field, 'modified', false, false)
		d.set_cell_state(row, field, 'old_value', val)
		if (val !== cur_val) {
			row[field.index] = val
			d.set_cell_state(row, field, 'prev_value', cur_val)

			cell_state_changed(row, field, 'value', val, ev)
		}

		if (input_val_changed)
			cell_state_changed(row, field, 'input_value', val, ev)
		if (cell_modified_changed)
			cell_state_changed(row, field, 'cell_modified', false, ev)

	}

	// get/set display value --------------------------------------------------

	function bind_lookup_rowsets(on) {
		for (let field of d.fields) {
			let lr = field.lookup_rowset
			if (lr) {
				if (on && !field.lookup_rowset_loaded) {
					field.lookup_rowset_loaded = function() {
						field.lookup_field  = lr.field(field.lookup_col)
						field.display_field = lr.field(field.display_col || lr.name_col)
						d.fire('display_values_changed', field)
						d.fire('display_values_changed_for_'+field.name)
					}
					field.lookup_rowset_display_values_changed = function() {
						d.fire('display_values_changed', field)
						d.fire('display_values_changed_for_'+field.name)
					}
					field.lookup_rowset_loaded()
				}
				lr.on('loaded'      , field.lookup_rowset_loaded, on)
				lr.on('row_added'   , field.lookup_rowset_display_values_changed, on)
				lr.on('row_removed' , field.lookup_rowset_display_values_changed, on)
				lr.on('input_value_changed_for_'+field.lookup_col,
					field.lookup_rowset_display_values_changed, on)
				lr.on('input_value_changed_for_'+(field.display_col || lr.name_col),
					field.lookup_rowset_display_values_changed, on)
			}
		}
	}

	d.display_value = function(row, field) {
		let v = d.input_value(row, field)
		if (v == null)
			return field.null_text
		let lr = field.lookup_rowset
		if (lr) {
			let lf = field.lookup_field
			if (lf) {
				let row = lr.lookup(lf, v)
				if (row)
					return lr.display_value(row, field.display_field)
			}
			return field.lookup_failed_display_value(v)
		} else
			return field.format(v, row)
	}

	// add/remove rows --------------------------------------------------------

	function create_row() {
		let row = []
		// add server_default values or null
		for (let field of d.fields) {
			let val = field.server_default
			row.push(val != null ? val : null)
		}
		row.is_new = true
		return row
	}

	d.add_row = function(ev) {
		if (!d.can_add_rows)
			return
		let row = create_row()
		d.rows.add(row)
		d.fire('row_added', row, ev)
		// set default client values as if they were typed in by the user.
		let set_value_ev = update({row_not_modified: true}, ev)
		for (let field of d.fields)
			if (field.client_default != null)
				d.set_value(row, field, field.client_default, set_value_ev)
		row_changed(row)
		return row
	}

	d.can_remove_row = function(row) {
		if (!d.can_remove_rows)
			return false
		if (row.can_remove === false)
			return false
		if (row.is_new && row.save_request) {
			d.fire('notify', 'error',
				S('error_remove_while_saving',
					'Cannot remove a row that is in the process of being added to the server'))
			return false
		}
		return true
	}

	d.remove_row = function(row, ev) {
		if ((ev && ev.forever) || row.is_new) {
			d.rows.delete(row)
			d.fire('row_removed', row, ev)
		} else {
			if (!d.can_remove_row(row))
				return
			if (d.set_row_state(row, 'removed', true, false))
				row_state_changed(row, 'row_removed', ev)
			row_changed(row)
		}
		return row
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

	// params -----------------------------------------------------------------

	function init_params(params) {

		if (typeof params == 'string')
			params = params.split(' ')
		else if (!params)
			params = []

		bind_param_nav(false)
		d.params = params

		if (params.length == 0)
			return

		if (!d.param_nav) {
			let param_fields = []
			let params_row = []
			for (let param of d.params) {
				param_fields.push({
					name: param,
				})
				params_row.push(null)
			}
			let params_rowset = rowset({fields: param_fields, rows: [params_row]})
			d.param_nav = rowset_nav({rowset: params_rowset})
		}

		if (d.isConnected)
			bind_param_nav(true)
	}

	function params_changed(row) {
		d.load()
	}

	function bind_param_nav(on) {
		if (!d.param_nav)
			return
		if (!d.params || !d.params.length)
			return
		d.param_nav.on('focused_row_changed', params_changed, on)
		//TODO:
		//for (let param of d.params)
		//	d.param_nav.on('focused_row_value_changed_for_'+param, params_changed, on)
	}

	function make_url(params) {
		if (!d.param_nav)
			return d.url
		if (!params) {
			params = {}
			for (let param of d.params) {
				let field = d.param_nav.rowset.field(param)
				let row = d.param_nav.focused_row
				let v = row ? d.param_nav.rowset.value(row, field) : null
				params[field.name] = v
			}
		}
		return url(d.url, {params: json(params)})
	}

	// loading ----------------------------------------------------------------

	d.load = function(params) {
		if (!d.url)
			return
		if (requests && requests.size && !d.load_request) {
			d.fire('notify', 'error',
				S('error_load_while_saving', 'Cannot reload while saving is in progress.'))
			return
		}
		d.abort_loading()
		let req = ajax({
			url: make_url(params),
			progress: load_progress,
			success: load_success,
			fail: load_fail,
			done: load_done,
			slow: load_slow,
			slow_timeout: d.slow_timeout,
		})
		add_request(req)
		d.load_request = req
		d.loading = true
		d.fire('loading', true)
		req.send()
	}

	d.abort_loading = function() {
		if (!d.load_request)
			return
		d.load_request.abort()
		d.load_request = null
	}


	function load_progress(p, loaded, total) {
		d.fire('load_progress', p, loaded, total)
	}

	function load_slow(show) {
		d.fire('load_slow', show)
	}

	function load_done() {
		requests.delete(this)
		d.load_request = null
		d.loading = false
		d.fire('loading', false)
	}

	function check_fields(server_fields) {
		if (!isarray(d.client_fields))
			return true
		let fi = 0
		let ok = false
		if (d.client_fields.length == server_fields.length) {
			for (sf of server_fields) {
				let cf = d.client_fields[fi]
				if (cf.name != sf.name)
					break
				if (cf.type != sf.type)
					break
				fi++
			}
			ok = true
		}
		if (!ok)
			d.fire('notify', 'error', 'Client fields do not match server fields')
		return ok
	}

	function load_success(res) {

		d.changed_rows = null

		d.can_edit        = res.can_edit
		d.can_add_rows    = res.can_add_rows
		d.can_remove_rows = res.can_remove_rows
		d.can_change_rows = res.can_change_rows

		if (res.fields) {
			if (!check_fields(res.fields))
				return
			init_fields(res.fields)
			init_pk(res.pk)
			d.id_col = res.id_col
			d.fire('fields_changed')
		}

		if (res.params)
			init_params(res.params)

		init_rows(res.rows)

		d.fire('loaded')
	}

	function load_fail(type, status, message, body) {
		let err
		if (type == 'http')
			err = S('error_http', 'Server returned {0} {1}').format(status, message)
		else if (type == 'network')
			err = S('error_load_network', 'Loading failed: network error.')
		else if (type == 'timeout')
			err = S('error_load_timeout', 'Loading failed: timed out.')
		if (err)
			d.fire('notify', 'error', err, body)
		d.fire('load_fail', err, type, status, message, body)
	}

	// saving changes ---------------------------------------------------------

	function row_changed(row) {
		if (row.is_new)
			if (!row.row_modified)
				return
			else assert(!row.removed)
		d.changed_rows = d.changed_rows || new Set()
		d.changed_rows.add(row)
		d.fire('row_changed', row)
	}

	function add_row_changes(row, rows) {
		if (row.save_request)
			return // currently saving this row.
		if (row.is_new) {
			let t = {type: 'new', values: {}}
			for (let fi = 0; fi < d.fields.length; fi++) {
				let field = d.fields[fi]
				let val = row[fi]
				if (val !== field.server_default)
					t.values[field.name] = val
			}
			rows.push(t)
		} else if (row.removed) {
			let t = {type: 'remove', values: {}}
			for (let field of d.pk_fields)
				t.values[field.name] = d.old_value(row, field)
			rows.push(t)
		} else if (row.cells_modified) {
			let t = {type: 'update', values: {}}
			let found
			for (let field of d.fields) {
				if (d.cell_modified(row, field)) {
					t.values[field.name] = row[field.index]
					found = true
				}
			}
			if (found) {
				for (let field of d.pk_fields)
					t.values[field.name+':old'] = d.old_value(row, field)
				rows.push(t)
			}
		}
	}

	d.pack_changes = function(row) {
		let pk = d.pk_fields.map(field => field.name)
		let changes = {rows: [], pk: pk}
		if (d.id_col)
			changes.id_col = d.id_col
		if (!row) {
			for (let row of d.changed_rows)
				add_row_changes(row, changes.rows)
		} else
			add_row_changes(row, changes.rows)
		return changes
	}

	d.apply_result = function(result, changed_rows) {
		for (let i = 0; i < result.rows.length; i++) {
			let rt = result.rows[i]
			let row = changed_rows[i]

			let err = typeof rt.error == 'string' ? rt.error : undefined
			let row_failed = rt.error != null
			d.set_row_error(row, err)

			if (rt.remove) {
				d.remove_row(row, {forever: true, refocus: true})
			} else {
				if (!row_failed) {
					if (d.set_row_state(row, 'is_new', false, false))
						row_state_changed(row, 'row_is_new', false)
					if (d.set_row_state(row, 'cells_modified', false, false))
						row_state_changed(row, 'row_modified', false)
				}
				if (rt.field_errors) {
					for (let k in rt.field_errors) {
						let field = d.field(k)
						let err = rt.field_errors[k]
						err = typeof err == 'string' ? err : undefined
						if (d.set_cell_state(row, field, 'error', err))
							cell_state_changed(row, field, 'cell_error', err)
					}
				} else {
					if (rt.values)
						for (let k in rt.values)
							d.reset_value(row, d.field(k), rt.values[k])
				}
			}
		}
		if (result.sql_trace && result.sql_trace.length)
			print(result.sql_trace.join('\n'))
	}

	function set_save_state(rows, req) {
		for (let row of d.rows)
			d.set_row_state(row, 'save_request', req)
	}

	d.save = function(row) {
		if (!d.url)
			return
		if (!d.changed_rows)
			return
		let req = ajax({
			url: d.url,
			upload: d.pack_changes(row),
			changed_rows: Array.from(d.changed_rows),
			success: save_success,
			fail: save_fail,
			done: save_done,
			slow: save_slow,
			slow_timeout: d.slow_timeout,
		})
		d.changed_rows = null
		add_request(req)
		set_save_state(req.rows, req)
		d.fire('saving', true)
		req.send()
	}

	function save_slow(show) {
		d.fire('saving_slow', show)
	}

	function save_done() {
		requests.delete(this)
		set_save_state(this.rows, null)
		d.fire('saving', false)
	}

	function save_success(result) {
		d.apply_result(result, this.changed_rows)
	}

	function save_fail(type, status, message, body) {
		let err
		if (type == 'http')
			err = S('error_http', 'Server returned {0} {1}').format(status, message)
		else if (type == 'network')
			err = S('error_save_network', 'Saving failed: network error.')
		else if (type == 'timeout')
			err = S('error_save_timeout', 'Saving failed: timed out.')
		if (err)
			d.fire('notify', 'error', err, body)
		d.fire('save_fail', err, type, status, message, body)
	}

	d.revert = function() {
		if (!d.changed_rows)
			return
			/*
		for (let row of d.changed_rows)
			if (row.is_new)
				//
			else if (row.removed)
				//
			else if (row.cells_modified)
				//
			*/
		d.changed_rows = null
	}

	init()

	return d
}

function global_rowset(name, ...options) {
	let d = name
	if (typeof name == 'string') {
		d = global_rowset[name]
		if (!d) {
			d = rowset({url: 'rowset.json/'+name}, ...options)
			global_rowset[name] = d
		}
	}
	return d
}

// ---------------------------------------------------------------------------
// field types
// ---------------------------------------------------------------------------

{

	rowset.all_types = {
		w: 100,
		min_w: 20,
		max_w: 2000,
		align: 'left',
		client_default: null,
		server_default: null,
		allow_null: true,
		editable: true,
		sortable: true,
		maxlen: 256,
		true_text: () => H('<div class="fa fa-check"></div>'),
		false_text: '',
		null_text: S('null', 'null'),
		lookup_failed_display_value: function(v) {
			return this.format(v)
		},
	}

	rowset.all_types.format = function(v) {
		return String(v)
	}

	rowset.all_types.editor = function(...options) {
		return input({nolabel: true}, ...options)
	}

	rowset.all_types.to_text = function(v) {
		return v != null ? String(v) : ''
	}

	rowset.all_types.from_text = function(s) {
		s = s.trim()
		return s !== '' ? s : null
	}

	rowset.types = {
		number: {align: 'right', min: 0, max: 1/0, multiple_of: 1},
		date  : {align: 'right', min: -(2**52), max: 2**52},
		bool  : {align: 'center'},
	}

	// numbers

	rowset.types.number.validate = function(val, field) {
		val = parseFloat(val)

		if (typeof val != 'number' || val !== val)
			return S('error_invalid_number', 'Invalid number')

		if (field.multiple_of != null)
			if (val % field.multiple_of != 0) {
				if (field.multiple_of == 1)
					return S('error_integer', 'Value must be an integer')
				return S('error_multiple', 'Value must be multiple of {0}').format(field.multiple_of)
			}
	}

	rowset.types.number.editor = function(...options) {
		return spin_input(update({
			nolabel: true,
			button_placement: 'left',
		}, ...options))
	}

	rowset.types.number.from_text = function(s) {
		return num(s)
	}

	rowset.types.number.to_text = function(x) {
		return x != null ? String(x) : ''
	}

	// dates

	rowset.types.date.validate = function(val, field) {
		if (typeof val != 'number' || val !== val)
			return S('error_date', 'Invalid date')
	}

	rowset.types.date.format = function(t) {
		_d.setTime(t)
		return _d.toLocaleString(locale, this.date_format)
	}

	rowset.types.date.date_format =
		{weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' }

	rowset.types.date.editor = function(...options) {
		return dropdown(update({
			nolabel: true,
			picker: calendar(),
			align: 'right',
			mode: 'fixed',
		}, ...options))
	}

	// booleans

	rowset.types.bool.validate = function(val, field) {
		if (typeof val != 'boolean')
			return S('error_boolean', 'Value not true or false')
	}

	rowset.types.bool.format = function(val) {
		return val ? this.true_text : this.false_text
	}

	rowset.types.bool.editor = function(...options) {
		return checkbox(update({
			center: true,
		}, ...options))
	}

}

// ---------------------------------------------------------------------------
// value_widget mixin
// ---------------------------------------------------------------------------

/*
	value widgets must implement:
		field_prop_map: {prop->field_prop}
		update_value(input_val, ev)
		update_error(err, ev)
*/

function value_widget(e) {

	e.default_value = null
	e.field_prop_map = {
		field_name: 'name', field_type: 'type', label: 'text',
		format: 'format',
		min: 'min', max: 'max', maxlen: 'maxlen', multiple_of: 'multiple_of',
		lookup_rowset: 'lookup_rowset', lookup_col: 'lookup_col', display_col: 'display_col',
	}

	e.init_nav = function() {
		if (!e.nav) {
			// create an internal one-row-one-field rowset.

			// transfer value of e.foo to field.bar based on field_prop_map.
			let field = {}
			for (let e_k in e.field_prop_map) {
				let field_k = e.field_prop_map[e_k]
				if (e_k in e)
					field[field_k] = e[e_k]
			}

			let row = [e.default_value]

			let internal_rowset = rowset({
				fields: [field],
				rows: [row],
				can_change_rows: true,
			})

			// create a fake navigator.

			e.nav = {rowset: internal_rowset, focused_row: row, is_fake: true}

			e.field = e.nav.rowset.field(0)
			e.col = e.field.name

			if (e.validate) // inline validator, only for internal-rowset widgets.
				e.nav.rowset.on_validate_value(e.col, e.validate)

			e.init_field()
		} else if (e.nav !== true) {
			if (e.field)
				e.col = e.field.name
			if (e.col == null)
				e.col = 0
			e.field = e.nav.rowset.field(e.col)
			e.init_field()
		}
	}

	function rowset_cell_state_changed(row, field, prop, val, ev) {
		cell_state_changed(prop, val, ev)
	}

	e.bind_nav = function(on) {
		if (e.nav.is_fake) {
			e.nav.rowset.bind_user_widget(e, on)
			e.nav.rowset.on('cell_state_changed', rowset_cell_state_changed, on)
		} else {
			e.nav.on('focused_row_changed', e.init_value, on)
			e.nav.on('focused_row_cell_state_changed_for_'+e.col, cell_state_changed, on)
		}
		e.nav.rowset.on('display_values_changed_for_'+e.col, e.init_value, on)
		e.nav.rowset.on('fields_changed', fields_changed, on)
	}

	e.rebind_value = function(nav, col) {
		if (e.isConnected)
			e.bind_nav(false)
		e.nav = nav
		e.col = col
		e.field = e.nav.rowset.field(e.col)
		e.init_field()
		if (e.isConnected) {
			e.bind_nav(true)
			e.init_value()
		}
	}

	e.init_field = function() {} // stub

	function fields_changed() {
		e.field = e.nav.rowset.field(e.col)
		e.init_field()
	}

	e.init_value = function() {
		cell_state_changed('input_value', e.input_value)
		cell_state_changed('value', e.value)
		cell_state_changed('cell_error', e.error)
		cell_state_changed('cell_modified', e.modified)
	}

	function cell_state_changed(prop, val, ev) {
		if (prop == 'input_value')
			e.update_value(val, ev)
		else if (prop == 'value')
			e.fire('value_changed', val, ev)
		else if (prop == 'cell_error') {
			e.invalid = val != null
			e.class('invalid', e.invalid)
			e.update_error(val, ev)
		} else if (prop == 'cell_modified')
			e.class('modified', val)
	}

	e.error_tooltip_check = function() {
		return e.invalid && !e.hasclass('picker')
			&& (e.hasfocus || e.hovered)
	}

	e.update_error = function(err) {
		if (!e.error_tooltip) {
			if (!e.invalid)
				return // don't create it until needed.
			e.error_tooltip = tooltip({type: 'error', target: e,
				check: e.error_tooltip_check})
		}
		if (e.invalid)
			e.error_tooltip.text = err
		e.error_tooltip.update()
	}

	// getters/setters --------------------------------------------------------

	e.to_value = function(v) { return v; }
	e.from_value = function(v) { return v; }

	function get_value() {
		let row = e.nav.focused_row
		return row ? e.nav.rowset.value(row, e.field) : null
	}
	e.set_value = function(v, ev) {
		let row = e.nav.focused_row
		if (!row)
			return
		e.nav.rowset.set_value(row, e.field, e.to_value(v), ev)
	}
	e.late_property('value', get_value, e.set_value)

	e.property('input_value', function() {
		let row = e.nav.focused_row
		return row ? e.from_value(e.nav.rowset.input_value(row, e.field)) : null
	})

	e.property('error', function() {
		let row = e.nav.focused_row
		return row ? e.nav.rowset.cell_error(row, e.field) : undefined
	})

	e.property('modified', function() {
		let row = e.nav.focused_row
		return row ? e.nav.rowset.cell_modified(row, e.field) : false
	})

	e.display_value = function() {
		let row = e.nav.focused_row
		return row ? e.nav.rowset.display_value(row, e.field) : ''
	}

}

// ---------------------------------------------------------------------------
// tooltip
// ---------------------------------------------------------------------------

tooltip = component('x-tooltip', function(e) {

	e.class('x-widget')
	e.class('x-tooltip')

	e.text_div = div({class: 'x-tooltip-text'})
	e.pin = div({class: 'x-tooltip-tip'})
	e.add(e.text_div, e.pin)

	e.attrval('side', 'top')
	e.attrval('align', 'center')

	let target

	e.popup_target_changed = function(target) {
		let visible = !!(!e.check || e.check(target))
		e.class('visible', visible)
	}

	e.update = function() {
		e.popup(target, e.side, e.align, e.px, e.py)
	}

	function set_timeout_timer() {
		let t = e.timeout
		if (t == 'auto')
			t = clamp(e.text.length / (tooltip.reading_speed / 60), 1, 10)
		else
			t = num(t)
		if (t != null)
			after(t, function() { e.target = false })
	}

	e.late_property('text',
		function()  { return e.text_div.textContent },
		function(s) {
			e.text_div.set(s, 'pre-wrap')
			e.update()
			set_timeout_timer()
		}
	)

	e.property('visible',
		function()  { return e.style.display != 'none' },
		function(v) { e.show(v); e.update() }
	)

	e.attr_property('side'    , e.update)
	e.attr_property('align'   , e.update)
	e.attr_property('type'    , e.update)
	e.num_attr_property('px'  , e.update)
	e.num_attr_property('py'  , e.update)
	e.attr_property('timeout')

	e.late_property('target',
		function()  { return target },
		function(v) { target = v; e.update() }
	)

})

tooltip.reading_speed = 800 // letters-per-minute.

// ---------------------------------------------------------------------------
// button
// ---------------------------------------------------------------------------

button = component('x-button', function(e) {

	e.class('x-widget')
	e.class('x-button')
	e.attrval('tabindex', 0)

	e.icon_div = span({class: 'x-button-icon'})
	e.text_div = span({class: 'x-button-text'})
	e.add(e.icon_div, e.text_div)

	e.init = function() {

		if (typeof e.icon == 'string')
			e.icon_div.classes = e.icon
		else
			e.icon_div.set(e.icon)

		// can't use CSS for this because margins don't collapse with paddings.
		if (!(e.icon_classes || e.icon))
			e.icon_div.hide()

	}

	e.late_property('text',
		function()  { return e.text_div.html },
		function(s) { e.text_div.set(s) }
	)

	e.late_property('primary', function() {
		return e.hasclass('primary')
	}, function(on) {
		e.class('primary', on)
	})

	e.on('keydown', function keydown(key) {
		if (key == ' ' || key == 'Enter') {
			e.class('active', true)
			return false
		}
	})

	e.on('keyup', function keyup(key) {
		if (e.hasclass('active')) {
			// ^^ always match keyups with keydowns otherwise we might catch
			// a keyup from someone else's keydown, eg. a dropdown menu item
			// could've been selected by pressing Enter which closed the menu
			// and focused this button back and that Enter's keyup got here.
			if (key == ' ' || key == 'Enter') {
				e.click()
				e.class('active', false)
			}
			return false
		}
	})

	e.on('click', function() {
		if(e.action)
			e.action()
		e.fire('action')
	})

})

// ---------------------------------------------------------------------------
// checkbox
// ---------------------------------------------------------------------------

checkbox = component('x-checkbox', function(e) {

	e.class('x-widget')
	e.class('x-markbox')
	e.class('x-checkbox')
	e.attrval('tabindex', 0)
	e.attrval('align', 'left')
	e.attr_property('align')

	e.checked_value = true
	e.unchecked_value = false

	e.icon_div = span({class: 'x-markbox-icon x-checkbox-icon far fa-square'})
	e.text_div = span({class: 'x-markbox-text x-checkbox-text'})
	e.add(e.icon_div, e.text_div)

	// model

	value_widget(e)

	e.init = function() {
		e.init_nav()
		e.class('center', !!e.center)
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_nav(false)
	}

	e.late_property('checked',
		function() {
			return e.value == e.checked_value
		},
		function(v) {
			e.set_value(v ? e.checked_value : e.unchecked_value, {input: e})
		}
	)

	// view

	e.late_property('text',
		function()  { return e.text_div.html },
		function(s) { e.text_div.set(s) }
	)

	e.update_value = function(v) {
		v = v === e.checked_value
		e.class('checked', v)
		e.icon_div.class('fa', v)
		e.icon_div.class('fa-check-square', v)
		e.icon_div.class('far', !v)
		e.icon_div.class('fa-square', !v)
	}

	// controller

	e.toggle = function() {
		e.checked = !e.checked
	}

	e.on('mousedown', function(ev) {
		ev.preventDefault() // prevent accidental selection by double-clicking.
		e.focus()
	})

	e.on('click', function() {
		e.toggle()
		return false
	})

	e.on('keydown', function(key) {
		if (key == 'Enter' || key == ' ') {
			e.toggle()
			return false
		}
	})

})

// ---------------------------------------------------------------------------
// radiogroup
// ---------------------------------------------------------------------------

radiogroup = component('x-radiogroup', function(e) {

	e.class('x-widget')
	e.class('x-radiogroup')
	e.attrval('align', 'left')
	e.attr_property('align')

	value_widget(e)

	e.items = []

	e.init = function() {
		e.init_nav()
		for (let item of e.items) {
			if (typeof item == 'string' || item instanceof Node)
				item = {text: item}
			let radio_div = span({class: 'x-markbox-icon x-radio-icon far fa-circle'})
			let text_div = span({class: 'x-markbox-text x-radio-text'})
			text_div.set(item.text)
			let item_div = div({class: 'x-widget x-markbox x-radio-item', tabindex: 0},
				radio_div, text_div)
			item_div.attrval('align', e.align)
			item_div.class('center', !!e.center)
			item_div.item = item
			item_div.on('click', item_click)
			item_div.on('keydown', item_keydown)
			e.add(item_div)
		}
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_nav(false)
	}

	let sel_item

	e.update_value = function(i) {
		if (sel_item) {
			sel_item.class('selected', false)
			sel_item.at[0].class('fa-dot-circle', false)
			sel_item.at[0].class('fa-circle', true)
		}
		sel_item = i != null ? e.at[i] : null
		if (sel_item) {
			sel_item.class('selected', true)
			sel_item.at[0].class('fa-dot-circle', true)
			sel_item.at[0].class('fa-circle', false)
		}
	}

	function select_item(item) {
		e.set_value(item.index, {input: e})
		item.focus()
	}

	function item_click() {
		select_item(this)
		return false
	}

	function item_keydown(key) {
		if (key == ' ' || key == 'Enter') {
			select_item(this)
			return false
		}
		if (key == 'ArrowUp' || key == 'ArrowDown') {
			let item = e.focused_element
			let next_item = item
				&& (key == 'ArrowUp' ? (item.prev || e.last) : (item.next || e.first))
			if (next_item)
				select_item(next_item)
			return false
		}
	}

})

// ---------------------------------------------------------------------------
// input
// ---------------------------------------------------------------------------

function input_widget(e) {

	e.attrval('align', 'left')
	e.attr_property('align')

	e.attrval('mode', 'default')
	e.attr_property('mode')

	function update_inner_label() {
		e.class('with-inner-label', !e.nolabel && e.field && !!e.field.text)
	}

	e.class('with-inner-label', true)
	e.bool_attr_property('nolabel', update_inner_label)

	e.init_field = function() {
		update_inner_label()
		e.inner_label_div.set(e.field.text)
	}

}

input = component('x-input', function(e) {

	e.class('x-widget')
	e.class('x-input')

	e.input = H.input({class: 'x-input-value'})
	e.inner_label_div = div({class: 'x-input-inner-label'})
	e.input.set_input_filter() // must be set as first event handler!
	e.add(e.input, e.inner_label_div)

	value_widget(e)
	input_widget(e)

	e.init = function() {
		e.init_nav()
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_nav(false)
	}

	function update_state(s) {
		e.input.class('empty', s == '')
		e.inner_label_div.class('empty', s == '')
	}

	e.from_text = function(s) { return e.field.from_text(s) }
	e.to_text = function(v) { return e.field.to_text(v) }

	e.update_value = function(v, ev) {
		if (ev && ev.input == e && e.typing)
			return
		let s = e.to_text(v)
		e.input.value = s
		update_state(s)
	}

	e.input.on('input', function() {
		e.set_value(e.from_text(e.input.value), {input: e, typing: true})
		update_state(e.input.value)
	})

	e.input.input_filter = function(s) {
		return s.length <= or(e.maxlen, e.field.maxlen)
	}

	// grid editor protocol ---------------------------------------------------

	e.focus = function() {
		e.input.focus()
	}

	e.input.on('blur', function() {
		e.fire('lost_focus')
	})

	let editor_state

	function update_editor_state(moved_forward, i0, i1) {
		i0 = or(i0, e.input.selectionStart)
		i1 = or(i1, e.input.selectionEnd)
		let anchor_left =
			e.input.selectionDirection != 'none'
				? e.input.selectionDirection == 'forward'
				: (moved_forward || e.align == 'left')
		let imax = e.input.value.length
		let leftmost  = i0 == 0
		let rightmost = (i1 == imax || i1 == -1)
		if (anchor_left) {
			if (rightmost) {
				if (i0 == i1)
					i0 = -1
				i1 = -1
			}
		} else {
			i0 = i0 - imax - 1
			i1 = i1 - imax - 1
			if (leftmost) {
				if (i0 == 1)
					i1 = 0
				i0 = 0
			}
		}
		editor_state = [i0, i1]
	}

	e.input.on('keydown', function(key, shift, ctrl) {
		// NOTE: we capture Ctrl+A on keydown because the user might
		// depress Ctrl first and when we get the 'a' Ctrl is not pressed.
		if (key == 'a' && ctrl)
			update_editor_state(null, 0, -1)
	})

	e.input.on('keyup', function(key, shift, ctrl) {
		if (key == 'ArrowLeft' || key == 'ArrowRight')
			update_editor_state(key == 'ArrowRight')
	})

	e.editor_state = function(s) {
		if (s) {
			let i0 = e.input.selectionStart
			let i1 = e.input.selectionEnd
			let imax = e.input.value.length
			let leftmost  = i0 == 0
			let rightmost = i1 == imax
			if (s == 'left')
				return i0 == i1 && leftmost && 'left'
			else if (s == 'right')
				return i0 == i1 && rightmost && 'right'
		} else {
			if (!editor_state)
				update_editor_state()
			return editor_state
		}
	}

	e.enter_editor = function(s) {
		if (!s)
			return
		if (s == 'select_all')
			s = [0, -1]
		else if (s == 'left')
			s = [0, 0]
		else if (s == 'right')
			s = [-1, -1]
		editor_state = s
		let [i0, i1] = s
		let imax = e.input.value.length
		if (i0 < 0) i0 = imax + i0 + 1
		if (i1 < 0) i1 = imax + i1 + 1
		e.input.select(i0, i1)
	}

})

// ---------------------------------------------------------------------------
// spin_input
// ---------------------------------------------------------------------------

spin_input = component('x-spin-input', function(e) {

	e.class('x-spin-input')
	input.construct(e)

	e.align = 'right'

	e.attrval('button-style', 'plus-minus')
	e.attrval('button-placement', 'each-side')
	e.attr_property('button-style')
	e.attr_property('button-placement')

	e.up   = div({class: 'x-spin-input-button fa'})
	e.down = div({class: 'x-spin-input-button fa'})

	e.field_type = 'number'
	update(e.field_prop_map, {field_type: 'type'})

	let init_input = e.init
	e.init = function() {

		init_input()

		let bs = e.button_style
		let bp = e.button_placement

		if (bs == 'plus-minus') {
			e.up  .class('fa-plus')
			e.down.class('fa-minus')
			bp = bp || 'each-side'
		} else if (bs == 'up-down') {
			e.up  .class('fa-caret-up')
			e.down.class('fa-caret-down')
			bp = bp || 'left'
		} else if (bs == 'left-right') {
			e.up  .class('fa-caret-right')
			e.down.class('fa-caret-left')
			bp = bp || 'each-side'
		}

		if (bp == 'each-side') {
			e.insert(0, e.down)
			e.add(e.up)
			e.down.class('left' )
			e.up  .class('right')
			e.down.class('leftmost' )
			e.up  .class('rightmost')
		} else if (bp == 'right') {
			e.add(e.down, e.up)
			e.down.class('right')
			e.up  .class('right')
			e.up  .class('rightmost')
		} else if (bp == 'left') {
			e.insert(0, e.down, e.up)
			e.down.class('left')
			e.up  .class('left')
			e.down.class('leftmost' )
		}

	}

	// controller

	let input_filter = e.input.input_filter
	e.input.input_filter = function(s) {
		if (!input_filter(s))
			return false
		if (or(e.min, e.field.min) >= 0)
			if (/\-/.test(s))
				return false // no minus
		let max_dec = or(e.max_decimals, e.field.max_decimals)
		if (or(e.multiple_of, e.field.multiple_of) == 1)
			max_dec = 0
		if (max_dec == 0)
			if (/\./.test(s))
				return false // no dots
		if (max_dec != null) {
			let m = s.match(/\.(\d+)$/)
			if (m != null && m[1].length > max_dec)
				return false // too many decimals
		}
		let max_digits = or(e.max_digits, e.field.max_digits)
		if (max_digits != null) {
			let digits = s.replace(/[^\d]/g, '').length
			if (digits > max_digits)
				return false // too many digits
		}
		return /^[\-]?\d*\.?\d*$/.test(s) // allow digits and '.' only
	}

	e.input.on('wheel', function(dy) {
		e.set_value(e.input_value + (dy / 100), {input: e})
		e.input.select(0, -1)
		return false
	})

	// increment buttons click

	let increment
	function increment_value() {
		if (!increment) return
		let v = e.input_value + increment
		let r = v % or(e.field.multiple_of, 1)
		e.set_value(v - r, {input: e})
		e.input.select(0, -1)
	}
	let increment_timer
	function start_incrementing() {
		increment_value()
		increment_timer = setInterval(increment_value, 100)
	}
	let start_incrementing_timer
	function add_events(button, sign) {
		button.on('mousedown', function() {
			if (start_incrementing_timer || increment_timer)
				return
			e.input.focus()
			increment = or(e.field.multiple_of, 1) * sign
			increment_value()
			start_incrementing_timer = after(.5, start_incrementing)
			return false
		})
		function mouseup() {
			clearTimeout(start_incrementing_timer)
			clearInterval(increment_timer)
			start_incrementing_timer = null
			increment_timer = null
			increment = 0
		}
		button.on('mouseup', mouseup)
		button.on('mouseleave', mouseup)
	}
	add_events(e.up  , 1)
	add_events(e.down, -1)

})

// ---------------------------------------------------------------------------
// slider
// ---------------------------------------------------------------------------

slider = component('x-slider', function(e) {

	e.from = 0
	e.to = 1
	e.multiple_of = null

	e.class('x-widget')
	e.class('x-slider')
	e.attrval('tabindex', 0)

	e.value_fill = div({class: 'x-slider-fill x-slider-value-fill'})
	e.range_fill = div({class: 'x-slider-fill x-slider-range-fill'})
	e.input_thumb = div({class: 'x-slider-thumb x-slider-input-thumb'})
	e.value_thumb = div({class: 'x-slider-thumb x-slider-value-thumb'})
	e.add(e.range_fill, e.value_fill, e.value_thumb, e.input_thumb)

	// model

	value_widget(e)

	e.field_type = 'number'
	update(e.field_prop_map, {field_type: 'type'})

	e.init = function() {
		e.init_nav()
		e.class('animated', e.field.multiple_of >= 5) // TODO: that's not the point of this.
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_nav(false)
	}

	function progress_for(v) {
		return lerp(v, e.from, e.to, 0, 1)
	}

	function cmin() { return max(or(e.field.min, -1/0), e.from) }
	function cmax() { return min(or(e.field.max, 1/0), e.to) }

	e.set_progress = function(p, ev) {
		let v = lerp(p, 0, 1, e.from, e.to)
		if (e.field.multiple_of != null)
			v = floor(v / e.field.multiple_of + .5) * e.field.multiple_of
		e.set_value(clamp(v, cmin(), cmax()), ev)
	}

	e.late_property('progress',
		function() {
			return progress_for(e.input_value)
		},
		e.set_progress,
		0
	)

	// view

	function update_thumb(thumb, p, show) {
		thumb.show(show)
		thumb.style.left = (p * 100)+'%'
	}

	function update_fill(fill, p1, p2) {
		fill.style.left  = (p1 * 100)+'%'
		fill.style.width = ((p2 - p1) * 100)+'%'
	}

	e.update_value = function(v) {
		let input_p = progress_for(v)
		let value_p = progress_for(e.value)
		let diff = input_p != value_p
		update_thumb(e.value_thumb, value_p, diff)
		update_thumb(e.input_thumb, input_p)
		e.value_thumb.class('different', diff)
		e.input_thumb.class('different', diff)
		let p1 = progress_for(cmin())
		let p2 = progress_for(cmax())
		update_fill(e.value_fill, max(p1, 0), min(p2, value_p))
		update_fill(e.range_fill, p1, p2)
	}

	// controller

	let hit_x

	e.input_thumb.on('mousedown', function(ev) {
		e.focus()
		let r = e.input_thumb.client_rect()
		hit_x = ev.clientX - (r.left + r.width / 2)
		document.on('mousemove', document_mousemove)
		document.on('mouseup'  , document_mouseup)
		return false
	})

	function document_mousemove(mx, my) {
		let r = e.client_rect()
		e.set_progress((mx - r.left - hit_x) / r.width, {input: e})
		return false
	}

	function document_mouseup() {
		hit_x = null
		document.off('mousemove', document_mousemove)
		document.off('mouseup'  , document_mouseup)
	}

	e.on('mousedown', function(ev) {
		let r = e.client_rect()
		e.set_progress((ev.clientX - r.left) / r.width, {input: e})
	})

	e.on('keydown', function(key, shift) {
		let d
		switch (key) {
			case 'ArrowLeft'  : d =  -.1; break
			case 'ArrowRight' : d =   .1; break
			case 'ArrowUp'    : d =  -.1; break
			case 'ArrowDown'  : d =   .1; break
			case 'PageUp'     : d =  -.5; break
			case 'PageDown'   : d =   .5; break
			case 'Home'       : d = -1/0; break
			case 'End'        : d =  1/0; break
		}
		if (d) {
			e.set_progress(e.progress + d * (shift ? .1 : 1), {input: e})
			return false
		}
	})

})

// ---------------------------------------------------------------------------
// dropdown
// ---------------------------------------------------------------------------

dropdown = component('x-dropdown', function(e) {

	// view

	e.class('x-widget')
	e.class('x-input')
	e.class('x-dropdown')
	e.attrval('tabindex', 0)

	e.value_div = span({class: 'x-input-value x-dropdown-value'})
	e.button = span({class: 'x-dropdown-button fa fa-caret-down'})
	e.inner_label_div = div({class: 'x-input-inner-label x-dropdown-inner-label'})
	e.add(e.value_div, e.button, e.inner_label_div)

	value_widget(e)
	input_widget(e)

	let init_nav = e.init_nav
	e.init_nav = function() {
		init_nav()
		if (e.nav !== true)
			e.picker.rebind_value(e.nav, e.col)
	}

	e.init = function() {
		e.init_nav()
		e.picker.on('value_picked', picker_value_picked)
		e.picker.on('keydown', picker_keydown)
	}

	function bind_document(on) {
		document.on('mousedown', document_mousedown, on)
		document.on('rightmousedown', document_mousedown, on)
		document.on('stopped_event', document_stopped_event, on)
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
		bind_document(true)
	}

	e.detach = function() {
		e.close()
		bind_document(false)
		e.bind_nav(false)
	}

	// value updating

	e.update_value = function(v, ev) {
		let text = e.display_value()
		let empty = text === ''
		e.value_div.class('empty', empty)
		e.value_div.class('null', v == null)
		e.inner_label_div.class('empty', empty)
		e.value_div.set(empty ? H('&nbsp;') : text)
		if (ev && ev.focus)
			e.focus()
	}

	let error_tooltip_check = e.error_tooltip_check
	e.error_tooltip_check = function() {
		return error_tooltip_check() || (e.invalid && e.isopen)
	}

	// focusing

	let builtin_focus = e.focus
	let focusing_picker
	e.focus = function() {
		if (e.isopen) {
			focusing_picker = true // focusout barrier.
			e.picker.focus()
			focusing_picker = false
		} else
			builtin_focus.call(this)
	}

	// opening & closing the picker

	e.set_open = function(open, focus) {
		if (e.isopen != open) {
			e.class('open', open)
			e.button.switch_class('fa-caret-down', 'fa-caret-up', open)
			e.picker.class('picker', open)
			if (open) {
				e.cancel_value = e.input_value
				e.picker.min_w = e.offsetWidth
				e.picker.popup(e, 'bottom', e.align)
				e.fire('opened')
			} else {
				e.cancel_value = null
				e.picker.popup(false)
				e.fire('closed')
				if (!focus)
					e.fire('lost_focus') // grid editor protocol
			}
		}
		if (focus)
			e.focus()
	}

	e.open   = function(focus) { e.set_open(true, focus) }
	e.close  = function(focus) { e.set_open(false, focus) }
	e.toggle = function(focus) { e.set_open(!e.isopen, focus) }
	e.cancel = function(focus) {
		if (e.isopen) {
			e.set_value(e.cancel_value)
			e.close(focus)
		}
		else
			e.close(focus)
	}

	e.late_property('isopen',
		function() {
			return e.hasclass('open')
		},
		function(open) {
			e.set_open(open, true)
		}
	)

	// picker protocol

	function picker_value_picked() {
		e.close(true)
	}

	// keyboard & mouse binding

	e.on('click', function() {
		e.toggle(true)
		return false
	})

	e.on('keydown', function(key) {
		if (key == 'Enter' || key == ' ') {
			e.toggle(true)
			return false
		}
		if (key == 'ArrowDown' || key == 'ArrowUp') {
			if (!e.hasclass('grid-editor')) {
				e.picker.pick_near_value(key == 'ArrowDown' ? 1 : -1, {input: e})
				return false
			}
		}
	})

	e.on('keypress', function(c) {
		if (e.picker.quicksearch) {
			e.picker.quicksearch(c)
			return false
		}
	})

	function picker_keydown(key) {
		if (key == 'Escape' || key == 'Tab') {
			e.cancel(true)
			return false
		}
	}

	e.on('wheel', function(dy) {
		e.picker.pick_near_value(dy / 100, {input: e})
		return false
	})

	// clicking outside the picker closes the picker.
	function document_mousedown(ev) {
		if (e.contains(ev.target)) // clicked inside the dropdown.
			return
		if (e.picker.contains(ev.target)) // clicked inside the picker.
			return
		e.cancel()
	}

	// clicking outside the picker closes the picker, even if the click did something.
	function document_stopped_event(ev) {
		if (ev.type.ends('mousedown'))
			document_mousedown(ev)
	}

	e.on('focusout', function(ev) {
		// prevent dropdown's focusout from bubbling to the parent when opening the picker.
		if (focusing_picker)
			return false
		e.fire('lost_focus') // grid editor protocol
	})

})

// ---------------------------------------------------------------------------
// menu
// ---------------------------------------------------------------------------

menu = component('x-menu', function(e) {

	// view

	function create_item(item) {
		let check_div = div({class: 'x-menu-check-div fa fa-check'})
		let icon_div  = div({class: 'x-menu-icon-div'})
		if (typeof item.icon == 'string')
			icon_div.classes = item.icon
		else
			icon_div.set(item.icon)
		let check_td  = H.td ({class: 'x-menu-check-td'}, check_div, icon_div)
		let title_td  = H.td ({class: 'x-menu-title-td'})
		title_td.set(item.text)
		let key_td    = H.td ({class: 'x-menu-key-td'}, item.key)
		let sub_div   = div({class: 'x-menu-sub-div fa fa-caret-right'})
		let sub_td    = H.td ({class: 'x-menu-sub-td'}, sub_div)
		sub_div.style.visibility = item.items ? null : 'hidden'
		let tr = H.tr({class: 'x-item x-menu-tr'}, check_td, title_td, key_td, sub_td)
		tr.class('disabled', item.enabled == false)
		tr.item = item
		tr.check_div = check_div
		update_check(tr)
		tr.on('mouseup'   , item_mouseup)
		tr.on('mouseenter', item_mouseenter)
		return tr
	}

	function create_heading(item) {
		let td = H.td({class: 'x-menu-heading', colspan: 5})
		td.set(item.heading)
		let tr = H.tr({}, td)
		tr.focusable = false
		tr.on('mouseenter', separator_mouseenter)
		return tr
	}

	function create_separator() {
		let td = H.td({class: 'x-menu-separator', colspan: 5}, H.hr())
		let tr = H.tr({}, td)
		tr.focusable = false
		tr.on('mouseenter', separator_mouseenter)
		return tr
	}

	function create_menu(items) {
		let table = H.table({class: 'x-widget x-focusable x-menu-table', tabindex: 0})
		for (let i = 0; i < items.length; i++) {
			let item = items[i]
			let tr = item.heading ? create_heading(item) : create_item(item)
			table.add(tr)
			if (item.separator)
				table.add(create_separator())
		}
		table.on('keydown', menu_keydown)
		return table
	}

	e.init = function() {
		e.table = create_menu(e.items)
		e.add(e.table)
	}

	function show_submenu(tr) {
		if (tr.submenu_table)
			return tr.submenu_table
		let items = tr.item.items
		if (!items)
			return
		let table = create_menu(items)
		table.x = tr.clientWidth - 2
		table.parent_menu = tr.parent
		tr.submenu_table = table
		tr.add(table)
		return table
	}

	function hide_submenu(tr) {
		if (!tr.submenu_table)
			return
		tr.submenu_table.remove()
		tr.submenu_table = null
	}

	function select_item(menu, tr) {
		unselect_selected_item(menu)
		menu.selected_item_tr = tr
		if (tr)
			tr.class('focused', true)
	}

	function unselect_selected_item(menu) {
		let tr = menu.selected_item_tr
		if (!tr)
			return
		menu.selected_item_tr = null
		hide_submenu(tr)
		tr.class('focused', false)
	}

	function update_check(tr) {
		tr.check_div.show(tr.item.checked != null)
		tr.check_div.style.visibility = tr.item.checked ? null : 'hidden'
	}

	// popup protocol

	function bind_document(on) {
		document.on('mousedown', document_mousedown, on)
		document.on('rightmousedown', document_mousedown, on)
		document.on('stopped_event', document_stopped_event, on)
	}

	e.popup_target_attached = function(target) {
		bind_document(true)
	}

	e.popup_target_detached = function(target) {
		bind_document(false)
	}

	function document_mousedown(ev) {
		if (e.contains(ev.target)) // clicked inside the menu.
			return
		e.close()
	}

	// clicking outside the menu closes the menu, even if the click did something.
	function document_stopped_event(ev) {
		if (e.contains(ev.target)) // clicked inside the menu.
			return
		if (ev.type.ends('mousedown'))
			e.close()
	}

	let popup_target

	e.close = function(focus_target) {
		let target = popup_target
		e.popup(false)
		select_item(e.table, null)
		if (target && focus_target)
			target.focus()
	}

	e.override('popup', function(inherited, target, side, align, x, y, select_first_item) {
		popup_target = target
		inherited.call(this, target, side, align, x, y)
		if (select_first_item)
			select_next_item(e.table)
		e.table.focus()
	})

	// navigation

	function next_item(menu, down, tr) {
		tr = tr && (down ? tr.next : tr.prev)
		return tr || (down ? menu.first : menu.last)
	}
	function next_valid_item(menu, down, tr, enabled) {
		let i = menu.children.length
		while (i--) {
			tr = next_item(menu, down != false, tr)
			if (tr && tr.focusable != false && (!enabled || tr.enabled != false))
				return tr
		}
	}
	function select_next_item(menu, down, tr0, enabled) {
		select_item(menu, next_valid_item(menu, down, tr0, enabled))
	}

	function activate_submenu(tr) {
		let submenu = show_submenu(tr)
		if (!submenu)
			return
		submenu.focus()
		select_next_item(submenu)
		return true
	}

	function click_item(tr, allow_close, from_keyboard) {
		let item = tr.item
		if ((item.action || item.checked != null) && item.enabled != false) {
			if (item.checked != null) {
				item.checked = !item.checked
				update_check(tr)
			}
			if (!item.action || item.action(item) != false)
				if (allow_close != false)
					e.close(from_keyboard)
		}
	}

	// mouse bindings

	function item_mouseup() {
		click_item(this)
		return false
	}

	function item_mouseenter(ev) {
		if (this.submenu_table)
			return // mouse entered on the submenu.
		this.parent.focus()
		select_item(this.parent, this)
		show_submenu(this)
	}

	function separator_mouseenter(ev) {
		select_item(this.parent)
	}

	// keyboard binding

	function menu_keydown(key) {
		if (key == 'ArrowUp' || key == 'ArrowDown') {
			select_next_item(this, key == 'ArrowDown', this.selected_item_tr)
			return false
		}
		if (key == 'ArrowRight') {
			if (this.selected_item_tr)
				activate_submenu(this.selected_item_tr)
			return false
		}
		if (key == 'ArrowLeft') {
			if (this.parent_menu) {
				this.parent_menu.focus()
				hide_submenu(this.parent)
			}
			return false
		}
		if (key == 'Home' || key == 'End') {
			select_next_item(this, key == 'Home')
			return false
		}
		if (key == 'PageUp' || key == 'PageDown') {
			select_next_item(this, key == 'PageUp')
			return false
		}
		if (key == 'Enter' || key == ' ') {
			let tr = this.selected_item_tr
			if (tr) {
				let submenu_activated = activate_submenu(tr)
				click_item(tr, !submenu_activated, true)
			}
			return false
		}
		if (key == 'Escape') {
			if (this.parent_menu) {
				this.parent_menu.focus()
				hide_submenu(this.parent)
			} else
				e.close(true)
			return false
		}
	}

})

// ---------------------------------------------------------------------------
// pagelist
// ---------------------------------------------------------------------------

pagelist = component('x-pagelist', function(e) {

	e.class('x-widget')
	e.class('x-pagelist')

	e.add_button = div({class: 'x-pagelist-item x-pagelist-add-button fa fa-plus', tabindex: 0})

	function add_item(item) {
		if (typeof item == 'string' || item instanceof Node)
			item = {text: item}
		let xbutton = div({class: 'x-pagelist-xbutton fa fa-times'})
		xbutton.hide()
		let tdiv = div({class: 'x-pagelist-text'})
		let idiv = div({class: 'x-pagelist-item', tabindex: 0}, tdiv, xbutton)
		idiv.text_div = tdiv
		idiv.xbutton = xbutton
		tdiv.set(item.text)
		tdiv.title = item.text
		idiv.on('mousedown', item_mousedown)
		idiv.on('dblclick' , item_dblclick)
		idiv.on('keydown'  , item_keydown)
		tdiv.on('input'    , tdiv_input)
		idiv.on('blur'     , item_blur)
		xbutton.on('mousedown', xbutton_mousedown)
		idiv.item = item
		e.add(idiv)
		e.items.push(item)
		idiv.index = e.items.length-1
	}

	e.init = function() {
		if (e.items) {
			let items = e.items
			e.items = []
			for (let item of items)
				add_item(item)
		}
		e.add(e.add_button)
		e.selection_bar = div({class: 'x-pagelist-selection-bar'})
		e.add(e.selection_bar)
	}

	function update_selection_bar() {
		let idiv = e.selected_item
		e.selection_bar.show(!!idiv)
		if (idiv) {
			e.selection_bar.x = idiv.offsetLeft
			e.selection_bar.w = idiv.clientWidth
		} else {
			e.selection_bar.w = 0
		}
	}

	function update_xbuttons() {
		for (let item of e.items)
			item.xbutton.show(can_remove_items)
	}

	let can_remove_items = false
	e.property('can_remove_items',
		() => can_remove_items,
		function(v) {
			can_remove_items = v
			update_xbuttons()
		})

	// controller

	e.attach = function() {
		e.selected_index = e.selected_index
	}

	function select_item(idiv) {
		exit_editing()
		if (e.selected_item) {
			e.selected_item.class('selected', false)
			e.fire('close', e.selected_item.index)
			if (e.page_container)
				e.page_container.clear()
		}
		e.selected_item = idiv
		update_selection_bar()
		if (idiv) {
			idiv.class('selected', true)
			e.fire('open', idiv.index)
			if (e.page_container) {
				let page = idiv.item.page
				if (page) {
					e.page_container.add(page)
					let first_focusable = page.focusables()[0]
					if (first_focusable)
						first_focusable.focus()
				}
			}
		}
	}

	function item_mousedown() {
		if (this.text_div.contenteditable)
			return
		this.focus()
		select_item(this)
		return false
	}

	function item_keydown(key) {
		if (key == 'F2') {
			if (this.text_div.contenteditable)
				exit_editing()
			else
				enter_editing()
			return false
		}
		if (this.text_div.contenteditable) {
			if (key == 'Enter' || key == 'Escape') {
				exit_editing()
				return false
			}
		} else {
			if (key == ' ' || key == 'Enter') {
				select_item(this)
				return false
			}
			if (key == 'ArrowRight' || key == 'ArrowLeft') {
				e.selected_index += (key == 'ArrowRight' ? 1 : -1)
				if (e.selected_item)
					e.selected_item.focus()
				return false
			}
		}
	}

	// selected_index property.

	e.late_property('selected_index',
		function() {
			return e.selected_item ? e.selected_item.index : null
		},
		function(i) {
			let idiv = i != null ? e.at[clamp(i, 0, e.items.length-1)] : null
			select_item(idiv)
		}
	)

	// editing the pagelist itself.

	function enter_editing() {
		if (!e.selected_item) return
		e.selected_item.text_div.contenteditable = true
		e.selected_item.xbutton.show()
	}

	function exit_editing() {
		if (!e.selected_item) return
		e.selected_item.text_div.contenteditable = false
		e.selected_item.xbutton.hide()
	}

	e.add_button.on('click', function() {
		if (e.selected_item == this)
			return
		exit_editing()
		let item = {text: 'New'}
		e.selection_bar.remove()
		e.add_button.remove()
		add_item(item)
		e.add(e.selection_bar)
		e.add(e.add_button)
		return false
	})

	function item_dblclick() {
		if (this.text_div.contenteditable)
			return
		enter_editing()
		this.focus()
		return false
	}

	function tdiv_input() {
		update_selection_bar()
	}

	function item_blur() {
		//exit_editing()
	}

	function xbutton_mousedown() {
		let idiv = this.parent
		select_item(null)
		idiv.remove()
		e.items.remove_value(idiv.item)
		return false
	}

})

// ---------------------------------------------------------------------------
// split-view
// ---------------------------------------------------------------------------

vsplit = component('x-split', function(e) {

	e.class('x-widget')
	e.class('x-split')

	let horiz, left, fixed_pane, auto_pane

	e.init = function() {

		horiz = e.horizontal == true

		// check which pane is the one with a fixed width.
		let fixed_pi =
			((e[1].style[horiz ? 'width' : 'height'] || '').ends('px') && 1) ||
			((e[2].style[horiz ? 'width' : 'height'] || '').ends('px') && 2) || 1
		e.fixed_pane = e[  fixed_pi]
		e. auto_pane = e[3-fixed_pi]
		left = fixed_pi == 1

		e.class('horizontal',  horiz)
		e.class(  'vertical', !horiz)
		e[1].class('x-split-pane', true)
		e[2].class('x-split-pane', true)
		e.fixed_pane.class('x-split-pane-fixed')
		e. auto_pane.class('x-split-pane-auto')
		e.sizer = div({class: 'x-split-sizer'})
		e.add(e[1], e.sizer, e[2])

		e.class('resizeable', e.resizeable != false)
		if (e.resizeable == false)
			e.sizer.hide()
	}

	e.on('mousemove', view_mousemove)
	e.on('mousedown', view_mousedown)

	e.detach = function() {
		document_mouseup()
	}

	// controller

	let hit, hit_x, mx0, w0, resist

	function view_mousemove(rmx, rmy) {
		if (window.x_widget_dragging)
			return
		// hit-test for split resizing.
		hit = false
		if (e.client_rect().contains(rmx, rmy)) {
			// ^^ mouse is not over some scrollbar.
			let mx = horiz ? rmx : rmy
			let sr = e.sizer.client_rect()
			let sx1 = horiz ? sr.left  : sr.top
			let sx2 = horiz ? sr.right : sr.bottom
			w0 = e.fixed_pane.client_rect()[horiz ? 'width' : 'height']
			hit_x = mx - sx1
			hit = abs(hit_x - (sx2 - sx1) / 2) <= 5
			resist = true
			mx0 = mx
		}
		e.class('resize', hit)
	}

	function view_mousedown() {
		if (!hit)
			return
		e.class('resizing')
		window.x_widget_dragging = true // view_mousemove barrier.
		document.on('mousemove', document_mousemove)
		document.on('mouseup'  , document_mouseup)

		e.tooltip = e.tooltip || tooltip({
			side: horiz ? (left ? 'right' : 'left') : (left ? 'bottom' : 'top'),
		})
		e.tooltip.target = e.sizer
	}

	function document_mousemove(rmx, rmy) {

		let mx = horiz ? rmx : rmy
		let w
		if (left) {
			let fpx1 = e.fixed_pane.client_rect()[horiz ? 'left' : 'top']
			w = mx - (fpx1 + hit_x)
		} else {
			let ex2 = e.client_rect()[horiz ? 'right' : 'bottom']
			let sw = e.sizer[horiz ? 'clientWidth' : 'clientHeight']
			w = ex2 - mx + hit_x - sw
		}

		resist = resist && abs(mx - mx0) < 20
		if (resist)
			w = w0 + (w - w0) * .2 // show resistance

		e.fixed_pane[horiz ? 'w' : 'h'] = w

		e.tooltip.text = round(w)

		if (e.collapsable != false) {
			let w1 = e.fixed_pane.client_rect()[horiz ? 'width' : 'height']

			let pminw = e.fixed_pane.style[horiz ? 'min-width' : 'min-height']
			pminw = pminw ? parseInt(pminw) : 0

			if (!e.fixed_pane.hasclass('collapsed')) {
				if (w < min(max(pminw, 20), 30) - 5)
					e.fixed_pane.class('collapsed', true)
			} else {
				if (w > max(pminw, 30))
					e.fixed_pane.class('collapsed', false)
			}
		}

		return false
	}

	function document_mouseup() {
		if (resist) // reset width
			e[1][horiz ? 'w' : 'h'] = w0
		e.class('resizing', false)
		window.x_widget_dragging = null
		document.off('mousemove', document_mousemove)
		document.off('mouseup'  , document_mouseup)
		if (e.tooltip)
			e.tooltip.target = false
	}

})

function hsplit(...args) {
	return vsplit({horizontal: true}, ...args)
}

// ---------------------------------------------------------------------------
// toaster
// ---------------------------------------------------------------------------

toaster = component('x-toaster', function(e) {

	e.class('x-widget')
	e.class('x-toaster')

	e.tooltips = new Set()

	e.target = document.body
	e.side = 'inner-top'
	e.align = 'center'
	e.timeout = 'auto'
	e.spacing = 6

	function update_stack() {
		let py = 0
		for (let t of e.tooltips) {
			t.py = py
			py += t.client_rect().height + e.spacing
		}
	}

	function popup_removed() {
		e.tooltips.delete(this)
		update_stack()
	}

	function popup_check() {
		this.style.position = 'fixed'
		return true
	}

	e.post = function(text, type, timeout) {
		let t = tooltip({
			classes: 'x-toaster-message',
			type: type,
			target: e.target,
			text: text,
			side: e.side,
			align: e.align,
			timeout: opt(timeout, e.timeout),
			check: popup_check,
			popup_target_detached: popup_removed,
		})
		e.tooltips.add(t)
		update_stack()
	}

	e.close_all = function() {
		for (t of e.tooltips)
			t.target = false
	}

	e.detach = function() {
		e.close_all()
	}

})

// global notify function.
{
	let t
	function notify(...args) {
		t = t || toaster({classes: 'x-notify-toaster'})
		t.post(...args)
	}
}

// ---------------------------------------------------------------------------
// action band
// ---------------------------------------------------------------------------

action_band = component('x-action-band', function(e) {

	e.classes = 'x-widget x-action-band'
	e.layout = 'ok:ok cancel:cancel'

	e.init = function() {
		let ct = e
		for (let s of e.layout.split(' ')) {
			if (s == '<') {
				ct = div({style: `
						flex: auto;
						display: flex;
						flex-flow: row wrap;
						justify-content: center;
					`})
				e.add(ct)
				continue
			} else if (s == '>') {
				align = 'right'
				ct = e
				continue
			}
			s = s.split(':')
			let name = s.shift()
			let spec = new Set(s)
			let btn = e.buttons && e.buttons[name.replace('-', '_').replace(/[^\w]/g, '')]
			let btn_sets_text
			if (!(btn instanceof Node)) {
				if (typeof btn == 'function')
					btn = {action: btn}
				else
					btn = update({}, btn)
				if (spec.has('primary') || spec.has('ok'))
					btn.primary = true
				btn_sets_text = btn.text != null
				btn = button(btn)
			}
			btn.class('x-dialog-button-'+name)
			btn.dialog = e
			if (!btn_sets_text) {
				btn.text = S(name.replace('-', '_'), name.replace(/[_\-]/g, ' '))
				btn.style['text-transform'] = 'capitalize'
			}
			if (name == 'ok' || spec.has('ok')) {
				btn.on('action', function() {
					e.ok()
				})
			}
			if (name == 'cancel' || spec.has('cancel')) {
				btn.on('action', function() {
					e.cancel()
				})
			}
			ct.add(btn)
		}
	}

	e.ok = function() {
		e.fire('ok')
	}

	e.cancel = function() {
		e.fire('cancel')
	}

})

// ---------------------------------------------------------------------------
// modal dialog with action band footer
// ---------------------------------------------------------------------------

dialog = component('x-dialog', function(e) {

	e.classes = 'x-widget x-dialog'
	e.attrval('tabindex', 0)

	e.x_button = true
	e.footer = 'ok:ok cancel:cancel'

	e.init = function() {
		if (e.title != null) {
			let title = div({class: 'x-dialog-title'})
			title.set(e.title)
			e.title = title
			e.header = div({class: 'x-dialog-header'}, title)
		}
		if (!e.content)
			e.content = div()
		e.content.class('x-dialog-content')
		if (!(e.footer instanceof Node))
			e.footer = action_band({layout: e.footer, buttons: e.buttons})
		e.add(e.header, e.content, e.footer)
		if (e.x_button) {
			e.x_button = div({class: 'x-dialog-button-close fa fa-times'})
			e.x_button.on('click', function() {
				e.cancel()
			})
			e.add(e.x_button)
		}
	}

	e.on('keydown', function(key) {
		if (key == 'Escape')
			if (e.x_button)
				e.x_button.class('active', true)
	})

	e.on('keyup', function(key) {
		if (key == 'Escape')
			e.cancel()
		else if (key == 'Enter')
			e.ok()
	})

	e.close = function() {
		e.modal(false)
		if (e.x_button)
			e.x_button.class('active', false)
	}

	e.cancel = function() {
		if (e.fire('cancel'))
			e.close()
	}

	e.ok = function() {
		if (e.fire('ok'))
			e.close()
	}

})

// ---------------------------------------------------------------------------
// floating toolbox
// ---------------------------------------------------------------------------

toolbox = component('x-toolbox', function(e) {

	e.classes = 'x-widget x-toolbox'
	e.attrval('tabindex', 0)

	let xbutton = div({class: 'x-toolbox-xbutton fa fa-times'})
	let title_div = div({class: 'x-toolbox-title'})
	e.titlebar = div({class: 'x-toolbox-titlebar'}, title_div, xbutton)
	e.add(e.titlebar)

	e.hide()
	document.body.add(e)

	e.init = function() {
		title_div.set(e.title)
		e.title = ''

		let content = div({class: 'x-toolbox-content'})
		content.set(e.content)
		e.add(content)
		e.content = content

	}

	{
		let moving, drag_x, drag_y

		e.titlebar.on('pointerdown', function(ev) {
			e.focus()
			moving = true
			let r = e.client_rect()
			drag_x = ev.clientX - r.left
			drag_y = ev.clientY - r.top
			this.setPointerCapture(ev.pointerId)
			return false
		})

		e.titlebar.on('pointerup', function(ev) {
			moving = false
			this.releasePointerCapture(ev.pointerId)
			return false
		})

		e.titlebar.on('pointermove', function(mx, my) {
			if (!moving) return
			e.x = clamp(0, mx - drag_x, window.innerWidth  - this.offsetWidth)
			e.y = clamp(0, my - drag_y, window.innerHeight - this.offsetHeight)
			return false
		})
	}

	xbutton.on('pointerdown', function() {
		e.hide()
		return false
	})

})

