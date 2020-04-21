/*

	X-WIDGETS: Data-driven web components in JavaScript.
	Written by Cosmin Apreutesei. Public Domain.

*/

// ---------------------------------------------------------------------------
// rowset
// ---------------------------------------------------------------------------

/*
	rowset.types : {type -> {attr->val}}

	d.fields: [{attr->val}, ...]

	identification:
		name           : field name (defaults to field's numeric index)
		type           : for choosing a field template.
		text           : field name for display purposes (auto-generated default).

	editing:
		client_default : default value that new rows are initialized with.
		server_default : default value that the server sets.
		editable       : allow modifying (true).
		editor         : f(field) -> editor instance
		from_text      : f(s) -> v
		to_text        : f(v) -> s

	validation:
		allow_null     : allow null (true).
		validate       : f(v, field) -> undefined|true|err
		min            : min value.
		max            : max value.
		step           : number that the value must be multiple of.

	formatting:
		align          : 'left'|'right'|'center'
		format         : f(v, field) -> s
		date_format    : toLocaleString format options for the date type
		true_text      : display value for boolean true
		false_text     : display value for boolean false

	vlookup:
		lookup_rowset  : rowset to look up values of this field into
		lookup_col     : field in lookup_rowset that matches this field
		display_col    : field in lookup_rowset to use as display_value of this field.
		lookup_failed_display_value : f(v) -> s; what to use when lookup fails.

	sorting:
		sortable       : allow sorting (true).
		compare_types  : f(v1, v2) -> -1|0|1  (for sorting)
		compare_values : f(v1, v2) -> -1|0|1  (for sorting)

	d.rows: Set({k->v})
		values         : [v1,...]
		state          : [{k->v},...]
			input_value : currently set value, whether valid or not.
			error       : error message if invalid.
			modified    : value was modified, change not on server yet.
			old_value   : initial value before modifying.
		is_new         : new row, not added on server yet.
		removed        : removed row, not removed on server yet.

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

rowset = function(...options) {

	let d = {}

	d.can_edit        = true
	d.can_add_rows    = true
	d.can_remove_rows = true
	d.can_change_rows = true

	let fields // [fi: {name:, client_default: v, server_default: v, ...}]
	let rows   // Set(row); row = {values: [fi: val], attr: val, ...}
	let field_map = new Map() // field_name->field

	events_mixin(d)

	d.field = function(v) {
		return typeof(v) == 'string' ? field_map.get(v) :
			(typeof(v) == 'number' ? fields[v] : v)
	}

	function init() {

		// set options/override.
		update(d, rowset, ...options)

		d.fields = d.fields || []
		d.rows = (!d.rows || isarray(d.rows)) && new Set(d.rows) || d.rows
		d.pk_fields = d.pk_fields || []

		// init locals.
		fields = d.fields
		rows = d.rows

		for (let i = 0; i < d.fields.length; i++) {
			let f1 = d.fields[i]
			let f0 = f1.type ? (d.types[f1.type] || rowset.types[f1.type]) : null
			let field = update({index: i}, rowset.default_type, d.default_type, f0, f1)

			if (field.text == null)
				field.text = auto_display_name(field.name)
			field.name = field.name || i+''

			if (field.lookup_col)
				field.lookup_field = field.lookup_rowset.field(field.lookup_col)
			if (field.display_col)
				field.display_field = field.lookup_rowset.field(field.display_col)

			fields[i] = field
			field_map.set(field.name, field)
		}

		if (d.pk)
			for (let col of d.pk.split(' ')) {
				let field = d.field(col)
				d.pk_fields.push(field)
				field.is_pk = true
			}

	}

	let owner
	function set_owner_events(on) {
		if (!owner)
			return
		owner.onoff('attach', d.attach, on)
		owner.onoff('detach', d.detach, on)
	}
	property(d, 'owner', {
		get: function() { return owner },
		set: function(owner1) {
			set_owner_events(false)
			owner = owner1
			set_owner_events(true)
		},
	})

	d.attach = function() {
		set_display_values_changed_events(true)
	}

	d.detach = function() {
		set_display_values_changed_events(false)
		abort_ajax_requests()
	}

	// vlookup ----------------------------------------------------------------

	function lookup_function(field) {
		let index = new Map()

		let rebuild = function() {
			let fi = field.index
			for (let row of rows) {
				index.set(row.values[fi], row)
			}
		}

		d.on('reload', rebuild)

		d.on('row_added', function(row) {
			index.set(row.values[field.index], row)
		})

		d.on('row_removed', function(row) {
			index.delete(row.values[field.index])
		})

		d.on('value_changed', function(row, changed_field, val, old_val) {
			if (changed_field == field) {
				index.delete(old_val)
				index.set(val, row)
			}
		})

		rebuild()

		return function(v) {
			return index.get(v)
		}
	}

	d.lookup = function(field, v) {
		if (!field.lookup)
			field.lookup = lookup_function(field)
		return field.lookup(v)
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

			let v1 = row1.values[field_index]
			let v2 = row2.values[field_index]

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
			// invalid values come first
			s.push('var v1 = !(r1.state && r1.state['+i+'].error)')
			s.push('var v2 = !(r2.state && r2.state['+i+'].error)')
			s.push('if (v1 < v2) return -1')
			s.push('if (v1 > v2) return  1')
			// modified values come second
			s.push('var v1 = !(r1.state && r1.state['+i+'].modified)')
			s.push('var v2 = !(r2.state && r2.state['+i+'].modified)')
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

	// get/set cell state -----------------------------------------------------

	d.cell_state = function(row, field, key, default_val) {
		let t = row.state && row.state[field.index]
		let v = t && t[key]
		return v !== undefined ? v : default_val
	}

	d.set_cell_state = function(row, field, key, val, ...args) {
		let t = attr(array_attr(row, 'state'), field.index)
		let old_val = t[key]
		if (old_val === val)
			return
		t[key] = val
		d.fire('cell_state_changed', row, field, key, val, old_val, ...args)
	}

	// get/set row state ------------------------------------------------------

	d.set_row_state = function(row, key, val, ...args) {
		let old_val = row[key]
		if (old_val === val)
			return
		row[key] = val
		d.fire('row_state_changed', row, key, val, old_val, ...args)
	}

	// get/set cell values ----------------------------------------------------

	d.value = function(row, field) {
		let get_value = field.get_value // computed value?
		return get_value ? get_value(field, row, fields) : row.values[field.index]
	}

	d.input_value = function(row, field) {
		let v = d.cell_state(row, field, 'input_value')
		return v !== undefined ? v : d.value(row, field)
	}

	d.old_value = function(row, field) {
		let v = d.cell_state(row, field, 'old_value')
		return v !== undefined ? v : d.value(row, field)
	}

	d.validate_value = function(field, val, row) {

		if (!d.can_change_value(row, field))
			return S('error_cell_read_only', 'cell is read-only')

		if (val == null)
			if (!field.allow_null)
				return S('error_not_null', 'NULL not allowed')
			else
				return

		if (field.min != null && val < field.min)
			return S('error_min_value', 'value must be at least {0}').format(field.min)

		if (field.max != null && val > field.max)
			return S('error_max_value', 'value must be at most {0}').format(field.max)

		let lr = field.lookup_rowset
		if (lr && !lr.lookup(field.lookup_field, val))
			return S('error_lookup', 'value not found in lookup')

		let err = field.validate && field.validate.call(d, val, field)
		if (typeof(err) == 'string')
			return err

		return d.fire('validate_'+field.name, val, row)
	}

	d.on_validate_value = function(field, validate, on) {
		d.onoff('validate_'+field.name, validate, on === undefined || on)
	}

	d.validate_row = function(row) {

		if (!d.can_change_value(row))
			return S('error_row_read_only', 'row is read-only')

		return d.fire('validate', row)
	}

	d.can_focus_cell = function(row, field) {
		return row.focusable != false && (field == null || field.focusable != false)
	}

	d.can_change_value = function(row, field) {
		return d.can_edit && d.can_change_rows && row.editable != false
			&& (field == null || (field.editable && !field.get_value))
			&& d.can_focus_cell(row, field)
	}

	d.create_row_editor = function(row, ...options) {} // stub

	d.create_editor = function(field, ...options) {
		if (field)
			return field.editor.call(d, ...options)
		else
			return d.create_row_editor(...options)
	}

	d.set_value = function(row, field, val, ...args) {

		if (val === undefined)
			val = null

		let err = d.validate_value(field, val, row)

		let invalid = typeof(err) == 'string'
		if (!invalid) {
			let old_val = row.values[field.index]
			if (val !== old_val) {

				row.values[field.index] = val

				if (!d.cell_state(row, field, 'modified')) {
					d.set_cell_state(row, field, 'old_value', old_val, ...args)
					d.set_cell_state(row, field, 'modified', true, ...args)
					row.modified = true
				} else if (val === d.cell_state(row, field, 'old_value')) {
					d.set_cell_state(row, field, 'modified', false, ...args)
				}
				d.fire('value_changed', row, field, val, old_val, ...args)
				row_changed(row)
			}
		}
		d.set_cell_state(row, field, 'error', invalid ? err : undefined, ...args)
		d.set_cell_state(row, field, 'input_value', val, ...args)

		return !invalid
	}

	// get/set display value --------------------------------------------------

	function set_display_values_changed_events(on) {
		for (let field of fields)
			if (field.lookup_rowset) {
				if (on && !field.display_values_changed)
					field.display_values_changed = function() {
						d.fire('display_values_changed', field)
					}
				field.lookup_rowset.onoff('reload'       , field.display_values_changed, on)
				field.lookup_rowset.onoff('row_added'    , field.display_values_changed, on)
				field.lookup_rowset.onoff('row_removed'  , field.display_values_changed, on)
				field.lookup_rowset.onoff('value_changed', field.display_values_changed, on)
			}
	}

	d.display_value = function(row, field) {
		let v = d.input_value(row, field)
		let lr = field.lookup_rowset
		if (lr) {
			let row = lr.lookup(field.lookup_field, v)
			if (!row)
				return field.lookup_failed_display_value(v)
			else
				return lr.display_value(row, field.display_field)
		} else
			return field.format.call(d, v, field)
	}

	// add/remove rows --------------------------------------------------------

	function create_row() {
		let values = []
		// add server_default values or null
		for (let field of fields) {
			let val = field.server_default
			values.push(val != null ? val : null)
		}
		return {values: values, is_new: true}
	}

	d.add_row = function(...args) {
		if (!d.can_add_rows)
			return
		let row = create_row()
		rows.add(row)
		d.fire('row_added', row, ...args)
		// set default client values as if they were added by the user.
		for (let field of fields)
			if (field.client_default != null)
				d.set_value(row, field, field.client_default, ...args)
		// ... except we don't consider the row modified so that we can
		// remove it with the up-arrow key if no further edits are made.
		row.modified = false
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
				S('cannot remove a row that is in the process of being added to the server'))
			return false
		}
		return true
	}

	d.remove_row = function(row, ...args) {
		if (!d.can_remove_row(row))
			return
		row.removed = true
		rows.delete(row)
		d.fire('row_removed', row, ...args)
		row_changed(row)
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
		if (d.requests)
			for (let req of requests)
				req.abort()
	}

	// loading ----------------------------------------------------------------

	d.load = function() {
		if (!d.url)
			return
		if (d.save_request)
			return
		if (d.load_request)
			d.load_request.abort()
		let req = ajax({
			url: d.url,
			progress: load_progress,
			success: load_success,
			fail: load_fail,
			done: load_done,
			slow: load_slow,
		})
		add_request(req)
		d.load_request = req
		d.loading = true
		d.fire('loading', true)
		req.send()
	}

	function load_progress(p, loaded, total) {
		d.fire('load_progress', p, loaded, total)
	}

	function load_slow(show) {
		d.fire('loading_slow', show)
		if (show)
			d.fire('notify', 'info', S('slow', 'Still working on it...'))
	}

	function load_done() {
		requests.delete(this)
		d.load_request = null
		d.loading = false
		d.fire('loading', false)
	}

	function check_fields(server_fields) {
		let fi = 0
		let ok = false
		if (fields.length == server_fields.length) {
			for (sf of server_fields) {
				let cf = fields[fi]
				if (cf.name != sf.name)
					break
				if (cf.type != sf.type)
					break
				fi++
			}
			ok = true
		}
		if (!ok)
			d.fire('notify', 'error', 'client fields do not match server fields')
		return ok
	}

	function load_success(result) {
		if (!check_fields(result.fields))
			return
		rows = new Set(result.rows)
		d.rows = rows
		d.fire('reload')
	}

	function load_fail(type, status, message, body) {
		if (type == 'http')
			d.fire('notify', 'error',
				S('rowset_load_http_error',
					'Server returned {0} {1}<pre>{2}</pre>'.format(status, message, body)))
		else if (type == 'network')
			d.fire('notify', 'error', S('rowset_load_network_error', 'Loading failed: network error.'))
		else if (type == 'timeout')
			d.fire('notify', 'error', S('rowset_load_timeout_error', 'Loading failed: timed out.'))
	}

	// saving changes ---------------------------------------------------------

	let changeset

	function row_changed(row) {
		if (!changeset)
			changeset = new Set()
		if (row.is_new && row.removed)
			changeset.delete(row)
		else
			changeset.add(row)
		d.fire('row_changed', row)
	}

	function where_fields(row) {
		let t = {}
		for (let field of d.pk_fields)
			t[field.name] = d.old_value(row, field)
		return t
	}

	function add_row_changes(row, upload) {
		if (row.save_request)
			return
		if (row.is_new) {
			let t = {}
			for (let fi = 0; fi < fields.length; fi++) {
				let field = fields[fi]
				let val = row.values[fi]
				if (val !== field.server_default)
					t[field.name] = val
			}
			upload.new_rows.push(t)
		} else if (row.removed) {
			upload.removed_rows.push(where_fields(row))
		} else if (row.modified) {
			let t = {}
			let found
			for (let field of fields) {
				if (d.cell_state(row, field, 'modified')) {
					t[field.name] = row.values[field.index]
					found = true
				}
			}
			if (found)
				upload.updated_rows.push({values: t, where: where_fields(row)})
		}
	}

	d.pack_changeset = function(row) {
		let upload = {new_rows: [], updated_rows: [], removed_rows: []}
		if (!row) {
			for (let row of changeset)
				add_row_changes(row, upload)
		} else
			add_row_changes(row, upload)
		return upload
	}

	d.apply_resultset = function(resultset) {
		for (let row of resultset) {
			//d.set_cell_state(
			//d.set_row_state(
		}
	}

	function set_save_state(rows, req) {
		for (let row of rows)
			d.set_row_state(row, 'save_request', req)
	}

	d.save = function(row) {
		if (!d.url)
			return
		if (!d.changeset)
			return
		let req = ajax({
			url: d.url,
			upload: d.pack_changeset(row),
			rows: changeset,
			success: save_success,
			fail: save_fail,
			done: save_done,
			slow: save_slow,
		})
		changeset = null
		add_request(req)
		set_save_state(req.rows, req)
		d.fire('saving', true)
		req.send()
	}

	function save_slow(show) {
		d.fire('saving_slow', show)
		if (show)
			d.fire('notify', 'info', S('slow', 'Still working on it...'))
	}

	function save_done() {
		requests.delete(this)
		set_save_state(this.rows, null)
		d.fire('saving', false)
	}

	function save_success(resultset) {
		d.apply_resultset(resultset)
	}

	function save_fail(...args) {
		if (type == 'http')
			d.fire('notify', 'error',
				S('rowset_save_http_error',
					'Server returned {0} {1}<pre>{2}</pre>'.format(status, message, body)))
		else if (type == 'network')
			d.fire('notify', 'error', S('rowset_save_network_error', 'Saving failed: network error.'))
		else if (type == 'timeout')
			d.filre('notify', 'error', S('rowset_save_timeout_error', 'Saving failed: timed out.'))
	}

	init()

	return d
}

// ---------------------------------------------------------------------------
// field types
// ---------------------------------------------------------------------------

{
	let default_lookup_failed_display_value = function(v) {
		return v != null ? v+'' : ''
	}

	rowset.default_type = {
		width: 50,
		align: 'left',
		client_default: null,
		server_default: null,
		allow_null: true,
		editable: true,
		sortable: true,
		true_text: 'true',
		false_text: 'false',
		min: 0,
		max: 1/0,
		step: 1,
		lookup_failed_display_value: default_lookup_failed_display_value,
	}

	rowset.default_type.format = function(v) {
		return v == null ? 'null' : String(v)
	}

	rowset.default_type.editor = function(...options) {
		return input(...options)
	}

	rowset.default_type.to_text = function(v) {
		return v != null ? String(v) : ''
	}

	rowset.default_type.from_text = function(s) {
		s = s.trim()
		return s !== '' ? s : null
	}

	rowset.types = {
		number: {align: 'right'},
		date  : {align: 'right', min: -(2**52), max: 2**52},
		bool  : {align: 'center'},
	}

	// numbers

	rowset.types.number.validate = function(val, field) {
		val = parseFloat(val)

		if (typeof(val) != 'number' || val !== val)
			return S('error_invalid_number', 'invalid number')

		if (field.step != null)
			if (val % field.step != 0) {
				if (field.step == 1)
					return S('error_integer', 'value must be an integer')
				return S('error_multiple', 'value must be multiple of {0}').format(field.step)
			}
	}

	rowset.types.number.editor = function(...options) {
		return spin_input(update({
			button_placement: 'left',
		}, ...options))
	}

	rowset.types.number.from_text = function(s) {
		return s !== '' ? Number(s) : null
	}

	rowset.types.number.to_text = function(x) {
		return x != null ? String(x) : ''
	}

	// dates

	rowset.types.date.validate = function(val, field) {
		if (typeof(val) != 'number' || val !== val)
			return S('error_date', 'invalid date')
	}

	rowset.types.date.format = function(t, field) {
		_d.setTime(t)
		return _d.toLocaleString(locale, field.date_format)
	}

	rowset.default_type.date_format =
		{weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' }

	rowset.types.date.editor = function(...options) {
		return dropdown(update({
			picker: calendar(),
			align: 'right',
			mode: 'fixed',
		}, ...options))
	}

	// booleans

	rowset.types.bool.validate = function(val, field) {
		if (typeof(val) != 'boolean')
			return S('error_boolean', 'value not true or false')
	}

	rowset.types.bool.format = function(val, field) {
		return val ? field.true_text : field.false_text
	}

	rowset.types.bool.editor = function(...options) {
		return checkbox(update({
			center: true,
		}, ...options))
	}

}

// ---------------------------------------------------------------------------
// focused_row mixin
// ---------------------------------------------------------------------------

function focused_row_mixin(e) {

	let focused_row = null

	e.set_focused_row = function(row, ...args) {
		if (row == focused_row)
			return
		focused_row = row
		e.fire('focused_row_changed', row, ...args)
	}

	property(e, 'focused_row', {
		get: function() { return focused_row },
		set: function(row) { e.set_focused_row(row) },
	})

	e.bind_rowset = function(on) {
		e.rowset.onoff('reload' , reload, on)
		e.rowset.onoff('row_removed', row_removed, on)
	}

	// losing the focused row -------------------------------------------------

	function reload() {
		focused_row = null
	}

	// TODO: remove_by_index() that ends up calling set_focused_row_index()
	// instead, in order to avoid creating a rowmap.
	function row_removed(row) {
		if (focused_row == row)
			e.set_focused_row(null)
	}

}

// standalone rowset navigator object ----------------------------------------

rowset_nav = function(...options) {
	let nav = {}
	events_mixin(nav)
	focused_row_mixin(nav)
	update(nav, ...options)
	return nav
}

// ---------------------------------------------------------------------------
// value_widget mixin
// ---------------------------------------------------------------------------

/*
	value widgets must implement:
		field_prop_map: {prop->field_prop}
		update_value()
		update_error(err)
*/

function value_widget(e) {

	e.default_value = null
	e.field_prop_map = {field_name: 'name', label: 'text',
		min: 'min', max: 'max', step: 'step'}

	e.init_nav = function() {
		if (!e.nav) {
			// create an internal one-row-one-field rowset and a rowset_nav.

			// transfer value of e.foo to field.bar based on field_prop_map.
			let field = {}
			for (let e_k in e.field_prop_map) {
				let field_k = e.field_prop_map[e_k]
				field[field_k] = e[e_k]
			}

			let row = {values: [e.default_value]}

			let internal_rowset = rowset({
				fields: [field],
				rows: [row],
			})

			e.nav = rowset_nav({rowset: internal_rowset, focused_row: row})

			e.field = e.nav.rowset.field(0)

			if (e.validate) // inline validator, only for internal-rowset widgets.
				e.nav.rowset.on_validate_value(e.field, e.validate, true)

			e.internal_nav = true

		} else {
			if (e.col)
				e.field = e.nav.rowset.field(e.col)
		}
	}

	e.bind_nav = function(on) {
		let r = e.nav.rowset
		e.nav.onoff('focused_row_changed', e.init_value           , on)
		r.onoff('reload'                 , e.init_value           , on)
		r.onoff('value_changed'          , value_changed          , on)
		r.onoff('cell_state_changed'     , cell_state_changed     , on)
		r.onoff('display_values_changed' , display_values_changed , on)
		if (e.internal_nav)
			if (on)
				r.attach()
			else
				r.detach()
	}

	e.rebind_value = function(nav, field) {
		e.bind_nav(false)
		e.nav = nav
		e.field = field
		if (e.isConnected) {
			e.bind_nav(true)
			e.init_value()
		}
	}

	function get_value() {
		return e.nav.rowset.value(e.nav.focused_row, e.field)
	}

	e.set_value = function(v, ...args) {
		e.nav.rowset.set_value(e.nav.focused_row, e.field, v, e, ...args)
	}

	e.late_property('value', get_value, e.set_value)

	e.cell_state = function(key, default_val) {
		return e.nav.rowset.cell_state(e.nav.focused_row, e.field, key, default_val)
	}

	e.set_cell_state = function(key, val, ...args) {
		return e.nav.rowset.set_cell_state(e.nav.focused_row, e.field, key, val, e, ...args)
	}

	e.property('input_value', function() {
		return e.nav.rowset.input_value(e.nav.focused_row, e.field)
	})

	e.property('display_value', function() {
		return e.nav.rowset.display_value(e.nav.focused_row, e.field)
	})

	e.init_value = function() {
		e.update_value()
		update_error_state(e.cell_state('error'))
	}

	function value_changed(row, field, val, old_val, ...args) {
		if (row != e.nav.focused_row || field != e.field)
			return
		e.fire('value_changed', val, old_val, ...args)
	}

	function cell_state_changed(row, field, key, val, old_val, ...args) {
		if (row != e.nav.focused_row || field != e.field)
			return
		if (key == 'input_value')
			e.update_value(...args)
		else if (key == 'error')
			update_error_state(val, ...args)
		else if (key == 'modified')
			e.class('modified', val)
	}

	function display_values_changed(field) {
		if (field != e.field)
			return
		e.init_value()
	}

	function update_error_state(err, ...args) {
		e.invalid = err != null
		e.class('invalid', e.invalid)
		e.update_error(err, ...args)
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

}

// ---------------------------------------------------------------------------
// tooltip
// ---------------------------------------------------------------------------

tooltip = component('x-tooltip', function(e) {

	e.class('x-widget')
	e.class('x-tooltip')

	e.text_div = H.div({class: 'x-tooltip-text'})
	e.pin = H.div({class: 'x-tooltip-tip'})
	e.add(e.text_div, e.pin)

	e.attrval('side', 'top')
	e.attrval('align', 'center')

	let target

	e.popup_target_changed = function(target) {
		let visible = !!(!e.check || e.check(target))
		e.class('visible', visible)
	}

	e.update = function() {
		e.popup(target, e.side, e.align)
	}

	e.property('text',
		function()  { return e.text_div.html },
		function(s) { e.text_div.html = s; e.update() }
	)

	e.property('visible',
		function()  { return e.style.display != 'none' },
		function(v) { return e.show(v); e.update() }
	)

	e.attr_property('side' , e.update)
	e.attr_property('align', e.update)
	e.attr_property('type' , e.update)

	e.late_property('target',
		function()  { return target },
		function(v) { target = v; e.update() }
	)

})

// ---------------------------------------------------------------------------
// button
// ---------------------------------------------------------------------------

button = component('x-button', function(e) {

	e.class('x-widget')
	e.class('x-button')
	e.attrval('tabindex', 0)

	e.icon_span = H.span({class: 'x-button-icon'})
	e.text_span = H.span({class: 'x-button-text'})
	e.add(e.icon_span, e.text_span)

	e.init = function() {

		e.icon_span.add(e.icon)
		e.icon_span.classes = e.icon_classes

		// can't use CSS for this because margins don't collapse with paddings.
		if (!(e.icon_classes || e.icon))
			e.icon_span.hide()

		e.on('keydown', keydown)
		e.on('keyup', keyup)
	}

	e.property('text', function() {
		return e.text_span.html
	}, function(s) {
		e.text_span.html = s
	})

	e.late_property('primary', function() {
		return e.hasclass('primary')
	}, function(on) {
		e.class('primary', on)
	})

	function keydown(key) {
		if (key == ' ' || key == 'Enter') {
			e.class('active', true)
			return false
		}
	}

	function keyup(key) {
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
	}

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

	e.icon_div = H.span({class: 'x-markbox-icon x-checkbox-icon fa fa-square'})
	e.text_div = H.span({class: 'x-markbox-text x-checkbox-text'})
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
			e.value = v ? e.checked_value : e.unchecked_value
		}
	)

	// view

	e.property('text', function() {
		return e.text_div.html
	}, function(s) {
		e.text_div.html = s
	})

	e.update_value = function() {
		v = e.input_value === e.checked_value
		e.class('checked', v)
		e.icon_div.class('fa-check-square', v)
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
			if (typeof(item) == 'string')
				item = {text: item}
			let radio_div = H.span({class: 'x-markbox-icon x-radio-icon far fa-circle'})
			let text_div = H.span({class: 'x-markbox-text x-radio-text'})
			text_div.html = item.text
			let item_div = H.div({class: 'x-widget x-markbox x-radio-item', tabindex: 0},
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

	e.update_value = function() {
		if (sel_item) {
			sel_item.class('selected', false)
			sel_item.at[0].class('fa-dot-circle', false)
			sel_item.at[0].class('fa-circle', true)
		}
		let i = e.input_value
		sel_item = i != null ? e.at[i] : null
		if (sel_item) {
			sel_item.class('selected', true)
			sel_item.at[0].class('fa-dot-circle', true)
			sel_item.at[0].class('fa-circle', false)
		}
	}

	function select_item(item) {
		e.value = item.index
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

	e.init_inner_label = function() {
		if (e.inner_label != false) {
			let s = e.field.text
			if (s) {
				e.inner_label_div.html = s
				e.class('with-inner-label', true)
			}
		}
	}

}

input = component('x-input', function(e) {

	e.class('x-widget')
	e.class('x-input')

	e.input = H.input({class: 'x-input-value'})
	e.inner_label_div = H.div({class: 'x-input-inner-label'})
	e.input.set_input_filter() // must be set as first event handler!
	e.add(e.input, e.inner_label_div)

	value_widget(e)
	input_widget(e)

	e.init = function() {
		e.init_nav()
		e.init_inner_label()
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_nav(false)
	}

	let from_input

	function update_state(s) {
		e.input.class('empty', s == '')
		e.inner_label_div.class('empty', s == '')
	}

	e.update_value = function() {
		if (!from_input) {
			let s = e.field.to_text(e.input_value)
			e.input.value = s
			update_state(s)
		}
	}

	e.input.on('input', function() {
		from_input = true
		e.value = e.field.from_text(e.input.value)
		update_state(e.input.value)
		from_input = false
	})

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

	input.construct(e)

	e.class('x-spin-input')

	e.align = 'right'

	e.attrval('button-style', 'plus-minus')
	e.attrval('button-placement', 'each-side')
	e.attr_property('button-style')
	e.attr_property('button-placement')

	e.up   = H.div({class: 'x-spin-input-button fa'})
	e.down = H.div({class: 'x-spin-input-button fa'})

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

	e.input.input_filter = function(v) {
		return /^[\-]?\d*\.?\d*$/.test(v) // allow digits and '.' only
	}

	e.input.on('wheel', function(dy) {
		e.value = e.input_value + (dy / 100)
		e.input.select(0, -1)
		return false
	})

	// increment buttons click

	let increment
	function increment_value() {
		if (!increment) return
		e.value = e.input_value + increment
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
			increment = or(e.field.step, 1) * sign
			increment_value()
			start_incrementing_timer = setTimeout(start_incrementing, 500)
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

	e.class('x-widget')
	e.class('x-slider')
	e.attrval('tabindex', 0)

	e.value_fill = H.div({class: 'x-slider-fill x-slider-value-fill'})
	e.range_fill = H.div({class: 'x-slider-fill x-slider-range-fill'})
	e.input_thumb = H.div({class: 'x-slider-thumb x-slider-input-thumb'})
	e.value_thumb = H.div({class: 'x-slider-thumb x-slider-value-thumb'})
	e.add(e.range_fill, e.value_fill, e.value_thumb, e.input_thumb)

	// model

	value_widget(e)

	e.field_type = 'number'
	update(e.field_prop_map, {field_type: 'type'})

	e.init = function() {
		e.init_nav()
		e.class('animated', e.field.step >= 5)
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

	e.late_property('progress',
		function() {
			return progress_for(e.input_value)
		},
		function(p) {
			let v = lerp(p, 0, 1, e.from, e.to)
			if (e.field.step != null)
				v = floor(v / e.field.step + .5) * e.field.step
			e.value = clamp(v, cmin(), cmax())
		},
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

	e.update_value = function() {
		let input_p = progress_for(e.input_value)
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
		e.progress = (mx - r.left - hit_x) / r.width
		return false
	}

	function document_mouseup() {
		hit_x = null
		document.off('mousemove', document_mousemove)
		document.off('mouseup'  , document_mouseup)
	}

	e.on('mousedown', function(ev) {
		let r = e.client_rect()
		e.progress = (ev.clientX - r.left) / r.width
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
			e.progress += d * (shift ? .1 : 1)
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

	e.value_div = H.span({class: 'x-input-value x-dropdown-value'})
	e.button = H.span({class: 'x-dropdown-button fa fa-caret-down'})
	e.inner_label_div = H.div({class: 'x-input-inner-label x-dropdown-inner-label'})
	e.add(e.value_div, e.button, e.inner_label_div)

	value_widget(e)
	input_widget(e)

	e.init = function() {

		e.init_nav()
		e.init_inner_label()

		e.picker.rebind_value(e.nav, e.field)

		e.picker.on('value_picked', picker_value_picked)
		e.picker.on('keydown', picker_keydown)
	}

	function bind_document(on) {
		document.onoff('mousedown', document_mousedown, on)
		document.onoff('stopped_event', document_stopped_event, on)
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

	e.update_value = function(source, focus) {
		let html = e.display_value
		let empty = html === ''
		e.value_div.class('empty', empty)
		e.value_div.class('null', e.input_value == null)
		e.inner_label_div.class('empty', empty)
		e.value_div.html = empty ? '&nbsp;' : html
		if (source == e && focus)
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
				e.picker.min_w = e.clientWidth
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

	// kb & mouse binding

	e.on('mousedown', function() {
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
				e.picker.pick_near_value(key == 'ArrowDown' ? 1 : -1)
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
		e.picker.pick_near_value(dy / 100)
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
		if (ev.type == 'mousedown')
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
// calendar
// ---------------------------------------------------------------------------

function month_names() {
	let a = []
	for (let i = 0; i <= 11; i++)
		a.push(month_name(utctime(0, i), 'short'))
	return a
}

calendar = component('x-calendar', function(e) {

	e.class('x-widget')
	e.class('x-calendar')
	e.class('x-focusable')
	e.attrval('tabindex', 0)

	e.format = {weekday: 'short', year: 'numeric', month: 'short', day: 'numeric'}

	value_widget(e)

	e.sel_day = H.div({class: 'x-calendar-sel-day'})
	e.sel_day_suffix = H.div({class: 'x-calendar-sel-day-suffix'})
	e.sel_month = dropdown({
		classes: 'x-calendar-sel-month x-dropdown-nowrap',
		picker: listbox({
			items: month_names(),
		}),
	})
	e.sel_year = spin_input({
		classes: 'x-calendar-sel-year',
		min: 1000,
		max: 3000,
		button_style: 'left-right',
	})
	e.header = H.div({class: 'x-calendar-header'},
		e.sel_day, e.sel_day_suffix, e.sel_month, e.sel_year)
	e.weekview = H.table({class: 'x-calendar-weekview'})
	e.add(e.header, e.weekview)

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

	e.update_value = function() {
		t = day(e.input_value)
		update_weekview(t, 6)
		let y = year_of(t)
		let n = floor(1 + days(t - month(t)))
		e.sel_day.html = n
		let day_suffixes = ['', 'st', 'nd', 'rd']
		e.sel_day_suffix.html = locale.starts('en') ?
			(n < 11 || n > 13) && day_suffixes[n % 10] || 'th' : ''
		e.sel_month.value = month_of(t)
		e.sel_year.value = y
	}

	function update_weekview(d, weeks) {
		let today = day(now())
		let this_month = month(d)
		d = week(this_month)
		e.weekview.clear()
		for (let week = 0; week <= weeks; week++) {
			let tr = H.tr()
			for (let weekday = 0; weekday < 7; weekday++) {
				if (!week) {
					let th = H.th({class: 'x-calendar-weekday'}, weekday_name(day(d, weekday)))
					tr.add(th)
				} else {
					let m = month(d)
					let s = d == today ? ' today' : ''
					s = s + (m == this_month ? ' current-month' : '')
					s = s + (d == day(e.input_value) ? ' focused selected' : '')
					let td = H.td({class: 'x-calendar-day x-item'+s}, floor(1 + days(d - m)))
					td.day = d
					td.on('mousedown', day_mousedown)
					tr.add(td)
					d = day(d, 1)
				}
			}
			e.weekview.add(tr)
		}
	}

	// controller

	function day_mousedown() {
		e.value = this.day
		e.sel_month.cancel()
		e.focus()
		e.fire('value_picked') // picker protocol
		return false
	}

	e.sel_month.on('value_changed', function() {
		_d.setTime(e.value)
		_d.setMonth(this.value)
		e.value = _d.valueOf()
	})

	e.sel_year.on('value_changed', function() {
		_d.setTime(e.value)
		_d.setFullYear(this.value)
		e.value = _d.valueOf()
	})

	e.weekview.on('wheel', function(dy) {
		e.value = day(e.input_value, 7 * dy / 100)
		return false
	})

	e.on('keydown', function(key, shift) {
		if (!e.focused) // other inside element got focus
			return
		if (key == 'Tab' && e.hasclass('picker')) { // capture Tab navigation.
			if (shift)
				e.sel_year.focus()
			else
				e.sel_month.focus()
			return false
		}
		let d, m
		switch (key) {
			case 'ArrowLeft'  : d = -1; break
			case 'ArrowRight' : d =  1; break
			case 'ArrowUp'    : d = -7; break
			case 'ArrowDown'  : d =  7; break
			case 'PageUp'     : m = -1; break
			case 'PageDown'   : m =  1; break
		}
		if (d) {
			e.value = day(e.input_value, d)
			return false
		}
		if (m) {
			_d.setTime(e.input_value)
			if (shift)
				_d.setFullYear(year_of(e.input_value) + m)
			else
				_d.setMonth(month_of(e.input_value) + m)
			e.value = _d.valueOf()
			return false
		}
		if (key == 'Home') {
			e.value = shift ? year(e.input_value) : month(e.input_value)
			return false
		}
		if (key == 'End') {
			e.value = day(shift ? year(e.input_value, 1) : month(e.input_value, 1), -1)
			return false
		}
		if (key == 'Enter') {
			e.fire('value_picked') // picker protocol
			return false
		}
	})

	e.sel_month.on('keydown', function(key, shift) {
		if (key == 'Tab' && e.hasclass('picker')) {// capture Tab navigation.
			if (shift)
				e.focus()
			else
				e.sel_year.focus()
			return false
		}
	})

	e.sel_year.on('keydown', function(key, shift) {
		if (key == 'Tab' && e.hasclass('picker')) { // capture Tab navigation.
			if (shift)
				e.sel_month.focus()
			else
				e.focus()
			return false
		}
	})

	// picker protocol

	// hack: trick dropdown into thinking that our own opened dropdown picker
	// is our child, which is how we would implement dropdowns if this fucking
	// rendering model would allow us to decouple painting order from element's
	// position in the tree (IOW we need the concept of global z-index).
	let builtin_contains = e.contains
	e.contains = function(e1) {
		return builtin_contains.call(this, e1) || e.sel_month.picker.contains(e1)
	}

	e.pick_near_value = function(delta) {
		e.value = day(e.input_value, delta)
		e.fire('value_picked')
	}

})

// ---------------------------------------------------------------------------
// menu
// ---------------------------------------------------------------------------

menu = component('x-menu', function(e) {

	// view

	function create_item(item) {
		let check_div = H.div({class: 'x-menu-check-div fa fa-check'})
		let icon_div  = H.div({class: 'x-menu-icon-div '+(item.icon_class || '')})
		let check_td  = H.td ({class: 'x-menu-check-td'}, check_div, icon_div)
		let title_td  = H.td ({class: 'x-menu-title-td'}, item.text)
		let key_td    = H.td ({class: 'x-menu-key-td'}, item.key)
		let sub_div   = H.div({class: 'x-menu-sub-div fa fa-caret-right'})
		let sub_td    = H.td ({class: 'x-menu-sub-td'}, sub_div)
		sub_div.style.visibility = item.items ? null : 'hidden'
		let tr = H.tr({class: 'x-item x-menu-tr'}, check_td, title_td, key_td, sub_td)
		tr.class('disabled', item.enabled == false)
		tr.item = item
		tr.check_div = check_div
		update_check(tr)
		tr.on('mousedown' , item_mousedown)
		tr.on('mouseenter', item_mouseenter)
		return tr
	}

	function create_separator() {
		let td = H.td({colspan: 5}, H.hr())
		let tr = H.tr({class: 'x-menu-separator-tr'}, td)
		tr.focusable = false
		return tr
	}

	function create_menu(items) {
		let table = H.table({class: 'x-focusable x-menu-table', tabindex: 0})
		for (let i = 0; i < items.length; i++) {
			let item = items[i]
			let tr = create_item(item)
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

	function hide_submenu(tr, force) {
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

	e.popup_target_attached = function(target) {
		document.on('mousedown', e.close)
	}

	e.popup_target_detached = function(target) {
		document.off('mousedown', e.close)
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

	function item_mousedown() {
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

	e.init = function() {
		if (e.items)
			for (let i = 0; i < e.items.length; i++) {
				let item = e.items[i]
				if (typeof(item) == 'string')
					item = {text: item}
				let item_div = H.div({class: 'x-pagelist-item', tabindex: 0}, item.text)
				item_div.on('mousedown', item_mousedown)
				item_div.on('keydown'  , item_keydown)
				item_div.item = item
				item_div.index = i
				e.add(item_div)
			}
		e.selection_bar = H.div({class: 'x-pagelist-selection-bar'})
		e.add(e.selection_bar)
	}

	// controller

	e.attach = function() {
		e.selected_index = e.selected_index
	}

	function select_item(idiv) {
		if (e.selected_item) {
			e.selected_item.class('selected', false)
			e.fire('close', e.selected_item.index)
			if (e.page_container)
				e.page_container.clear()
		}
		e.selection_bar.show(idiv)
		e.selected_item = idiv
		if (idiv) {
			idiv.class('selected', true)
			e.selection_bar.x = idiv.offsetLeft
			e.selection_bar.w = idiv.clientWidth
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
		this.focus()
		select_item(this)
		return false
	}

	function item_keydown(key) {
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

	// selected_index property.

	e.late_property('selected_index',
		function() {
			return e.selected_item ? e.selected_item.index : null
		},
		function(i) {
			let idiv = e.at[clamp(i, 0, e.children.length-2)]
			if (!idiv)
				return
			select_item(idiv)
		}
	)

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
		e.sizer = H.div({class: 'x-split-sizer'})
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
		if (window.split_resizing)
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
		window.split_resizing = true // view_mousemove barrier.
		document.on('mousemove', document_mousemove)
		document.on('mouseup'  , document_mouseup)
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
		window.split_resizing = null
		document.off('mousemove', document_mousemove)
		document.off('mouseup'  , document_mouseup)
	}

})

function hsplit(...args) {
	return vsplit({horizontal: true}, ...args)
}

// ---------------------------------------------------------------------------
// notifystack
// ---------------------------------------------------------------------------

notifystack = component('x-notifystack', function(e) {

	e.class('x-widget')
	e.class('x-notifystack')

	e.notify = function(text, type) {

		let t = tooltip({
			type: type,
			target: e,
			text: text,

		})
	}

})

