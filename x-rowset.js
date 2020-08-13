
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
		enum_values    : [v1, ...]

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
		display_col    : field in lookup_rowset to use as display_val of this field.
		lookup_failed_display_val : f(v) -> s; what to use when lookup fails.

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
		return (s || '').replace(/[\w]/, upper).replace(/(_[\w])/g, upper2)
	}
}

function widget_multiuser_mixin(e) {

	let refcount = 0

	e.bind_user_widget = function(user, on) {
		assert(user.typename) // must be a widget
		if (on)
			user_attached()
		else
			user_detached()
	}

	function user_attached() {
		refcount++
		if (refcount == 1) {
			e.attached = true
			e.attach()
		}
	}

	function user_detached() {
		refcount--
		assert(refcount >= 0)
		if (refcount == 0) {
			e.attached = false
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

	function init_fields(def) {

		let fields = def.fields
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

		let pk = def.pk
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

		d.id_field = d.pk_fields.length == 1 && d.pk_fields[0]

		d.index_field = d.field(def.index_col)
	}

	function init_rows(rows) {
		d.rows = (!rows || isarray(rows)) && new Set(rows) || rows
		each_lookup('rebuild')
		init_tree()
	}

	property(d, 'row_count', { get: function() { return d.rows.size } })

	function init() {
		update(d, rowset, ...options) // set options/override.
		d.client_fields = d.fields
		init_fields(d)
		init_params()
		init_rows(d.rows)
	}

	d.attach = function() {
		bind_lookup_rowsets(true)
		bind_param_nav(true)
		d.load()
	}

	d.detach = function() {
		bind_lookup_rowsets(false)
		bind_param_nav(false)
		abort_ajax_requests()
	}

	// vlookup ----------------------------------------------------------------

	function lookup_function(field, on) {

		let index

		function lookup(v) {
			return index.get(v)
		}

		lookup.rebuild = function() {
			index = new Map()
			let fi = field.index
			for (let row of d.rows) {
				index.set(row[fi], row)
			}
		}

		lookup.row_added = function(row) {
			index.set(row[field.index], row)
		}

		lookup.row_removed = function(row) {
			index.delete(row[field.index])
		}

		lookup.val_changed = function(row, changed_field, val) {
			if (changed_field == field) {
				let prev_val = d.prev_val(row, field)
				index.delete(prev_val)
				index.set(val, row)
			}
		}

		lookup.rebuild()

		return lookup
	}

	d.lookup = function(field, v) {
		if (isarray(field)) {
			field = field[0]
			// TODO: multi-key indexing
		}
		if (!field.lookup)
			field.lookup = lookup_function(field, true)
		return field.lookup(v)
	}

	function each_lookup(method, ...args) {
		if (d.fields)
			for (let field of d.fields)
				if (field.lookup)
					field.lookup[method](...args)
	}

	// tree -------------------------------------------------------------------

	d.each_child_row = function(row, f) {
		if (d.parent_field)
			for (let child_row of row.child_rows) {
				d.each_child_row(child_row, f) // depth-first
				f(child_row)
			}
	}

	function init_parents_for_row(row, parent_rows) {

		if (!init_parents_for_rows(row.child_rows))
			return // circular ref: abort.

		if (!parent_rows) {

			// reuse the parent rows array from a sibling, if any.
			let sibling_row = (row.parent_row || d).child_rows[0]
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

	function init_parents_for_rows(rows) {
		let parent_rows
		for (let row of rows) {
			parent_rows = init_parents_for_row(row, parent_rows)
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
		;(row.parent_row || d).child_rows.remove_value(row)
		if (row.parent_row && row.parent_row.child_rows.length == 0)
			delete row.parent_row.collapsed
		row.parent_row = null
		remove_parent_rows_for(row)
	}

	function add_row_to_tree(row, parent_row) {
		row.parent_row = parent_row
		;(parent_row || d).child_rows.push(row)
	}

	function init_tree() {

		d.parent_field = d.id_field && d.parent_col && d.field(d.parent_col)
		if (!d.parent_field)
			return

		d.child_rows = []
		for (let row of d.rows)
			row.child_rows = []

		let p_fi = d.parent_field.index
		for (let row of d.rows)
			add_row_to_tree(row, d.lookup(d.id_field, row[p_fi]))

		if (!init_parents_for_rows(d.child_rows)) {
			// circular refs detected: revert to flat mode.
			for (let row of d.rows) {
				row.child_rows = null
				row.parent_rows = null
				row.parent_row = null
				print('circular ref detected')
			}
			d.child_rows = null
			d.parent_field = null
		}

	}

	d.move_row = function(row, parent_row, ev) {
		if (!d.parent_field)
			return
		if (parent_row == row.parent_row)
			return
		assert(parent_row != row)
		assert(!parent_row || !parent_row.parent_rows.includes(row))

		let parent_id = parent_row ? d.val(parent_row, d.id_field) : null
		d.set_val(row, d.parent_field, parent_id, ev)

		remove_row_from_tree(row)
		add_row_to_tree(row, parent_row)

		assert(init_parents_for_row(row))
	}

	// collapsed state --------------------------------------------------------

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

	d.set_collapsed = function(row, collapsed, recursive) {
		if (!row.child_rows.length)
			return
		if (recursive)
			set_collapsed_all(row, collapsed)
		else if (row.collapsed != collapsed) {
			row.collapsed = collapsed
			set_parent_collapsed(row, collapsed)
		}
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

	d.compare_vals = function(v1, v2) {
		return v1 !== v2 ? (v1 < v2 ? -1 : 1) : 0
	}

	function field_comparator(field) {

		let compare_rows = d.compare_rows
		let compare_types  = field.compare_types  || d.compare_types
		let compare_vals = field.compare_vals || d.compare_vals
		let field_index = field.index

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

	d.must_sort = function(order_by) {
		return !!(d.parent_field || d.index_field || order_by.size)
	}

	// order_by: [[field1,'desc'|'asc'],...]
	d.comparator = function(order_by) {

		order_by = new Map(order_by)

		// use index-based ordering by default, unless otherwise specified.
		if (d.index_field && order_by.size == 0)
			order_by.set(d.index_field, 'asc')

		// the tree-building comparator requires a stable sort order
		// for all parents so we must always compare rows by id after all.
		if (d.parent_field && !order_by.has(d.id_field))
			order_by.set(d.id_field, 'asc')

		let s = []
		let cmps = []
		for (let [field, dir] of order_by) {
			let i = field.index
			cmps[i] = field_comparator(field)
			let r = dir == 'desc' ? -1 : 1
			if (field != d.index_field) {
				// invalid rows come first
				s.push('{')
				s.push('  let v1 = r1.row_error == null')
				s.push('  let v2 = r2.row_error == null')
				s.push('  if (v1 < v2) return -1')
				s.push('  if (v1 > v2) return  1')
				s.push('}')
				// invalid vals come after
				s.push('{')
				s.push('  let v1 = !(r1.error && r1.error['+i+'] != null)')
				s.push('  let v2 = !(r2.error && r2.error['+i+'] != null)')
				s.push('  if (v1 < v2) return -1')
				s.push('  if (v1 > v2) return  1')
				s.push('}')
				// modified rows come after
				s.push('{')
				s.push('  let v1 = !r1.cells_modified')
				s.push('  let v2 = !r2.cells_modified')
				s.push('  if (v1 < v2) return -1')
				s.push('  if (v1 > v2) return  1')
				s.push('}')
			}
			// compare vals using the rowset comparator
			s.push('{')
			s.push('let cmp = cmps['+i+']')
			s.push('let r = cmp(r1, r2)')
			s.push('if (r) return r * '+r)
			s.push('}')
		}
		s.push('return 0')
		let cmp = 'let cmp = function(r1, r2) {\n\t' + s.join('\n\t') + '\n}\n; cmp;\n'

		// tree-building comparator: order elements by their position in the tree.
		if (d.parent_field) {
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
		if (ev && ev.fire_changed_events === false)
			return
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
			'lookup_rowset', 'lookup_col', 'display_col', 'lookup_failed_display_val',
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

		rs.reload = function() {
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

	// get/set cell vals and cell & row state ---------------------------------

	d.val = function(row, field) {
		return row[field.index]
	}

	d.input_val = function(row, field) {
		return d.cell_state(row, field, 'input_val', d.val(row, field))
	}

	d.old_val = function(row, field) {
		return d.cell_state(row, field, 'old_val', d.val(row, field))
	}

	d.prev_val = function(row, field) {
		return d.cell_state(row, field, 'prev_val', d.val(row, field))
	}

	d.validate_val = function(field, val, row, ev) {

		if (val == null)
			if (!field.allow_null)
				return S('error_not_null', 'NULL not allowed')
			else
				return

		if (field.min != null && val < field.min)
			return S('error_min_value', 'Value must be at least {0}').subst(field.min)

		if (field.max != null && val > field.max)
			return S('error_max_value', 'Value must be at most {0}').subst(field.max)

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

	d.on_validate_val = function(col, validate, on) {
		d.on('validate_'+d.field(col).name, validate, on)
	}

	d.validate_row = function(row) {
		return d.fire('validate', row)
	}

	d.can_focus_cell = function(row, field) {
		return (!row || row.focusable != false) && (field == null || field.focusable != false)
	}

	d.can_change_val = function(row, field) {
		return d.can_edit && d.can_change_rows && (!row || row.editable != false)
			&& (field == null || field.editable)
			&& d.can_focus_cell(row, field)
	}

	d.can_have_children = function(row) {
		return row.can_have_children != false
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

	d.set_val = function(row, field, val, ev) {
		if (val === undefined)
			val = null
		let err = d.validate_val(field, val, row, ev)
		err = typeof err == 'string' ? err : undefined
		let invalid = err != null
		let cur_val = row[field.index]
		let val_changed = !invalid && val !== cur_val

		let input_val_changed = d.set_cell_state(row, field, 'input_val', val, cur_val)
		let cell_err_changed = d.set_cell_state(row, field, 'error', err)
		let row_err_changed = d.set_row_state(row, 'row_error')

		if (val_changed) {
			let was_modified = d.cell_modified(row, field)
			let modified = val !== d.old_val(row, field)

			row[field.index] = val
			d.set_cell_state(row, field, 'prev_val', cur_val)
			if (!was_modified)
				d.set_cell_state(row, field, 'old_val', cur_val)
			let cell_modified_changed = d.set_cell_state(row, field, 'modified', modified, false)
			let row_modified_changed = modified && (!(ev && ev.row_not_modified))
				&& d.set_row_state(row, 'cells_modified', true, false)

			each_lookup('val_changed', row, field, val)

			cell_state_changed(row, field, 'val', val, ev)
			if (cell_modified_changed)
				cell_state_changed(row, field, 'cell_modified', modified, ev)
			if (row_modified_changed)
				row_state_changed(row, 'row_modified', true, ev)
			row_changed(row)
		}

		if (input_val_changed)
			cell_state_changed(row, field, 'input_val', val, ev)
		if (cell_err_changed)
			cell_state_changed(row, field, 'cell_error', err, ev)
		if (row_err_changed)
			row_state_changed(row, 'row_error', undefined, ev)

		return !invalid
	}

	d.reset_val = function(row, field, val, ev) {
		if (val === undefined)
			val = null
		let cur_val = row[field.index]
		let input_val_changed = d.set_cell_state(row, field, 'input_val', val, cur_val)
		let cell_modified_changed = d.set_cell_state(row, field, 'modified', false, false)
		d.set_cell_state(row, field, 'old_val', val)
		if (val !== cur_val) {
			row[field.index] = val
			d.set_cell_state(row, field, 'prev_val', cur_val)

			cell_state_changed(row, field, 'val', val, ev)
		}

		if (input_val_changed)
			cell_state_changed(row, field, 'input_val', val, ev)
		if (cell_modified_changed)
			cell_state_changed(row, field, 'cell_modified', false, ev)

	}

	d.pk_vals = (row) => d.pk_fields.map((field) => d.val(row, field))

	// get/set display val ----------------------------------------------------

	function bind_lookup_rowsets(on) {
		for (let field of d.fields) {
			let lr = field.lookup_rowset
			if (lr) {
				if (on && !field.lookup_rowset_loaded) {
					field.lookup_rowset_loaded = function() {
						field.lookup_field  = lr.field(field.lookup_col)
						field.display_field = lr.field(field.display_col || lr.name_col)
						d.fire('display_vals_changed', field)
						d.fire('display_vals_changed_for_'+field.name)
					}
					field.lookup_rowset_display_vals_changed = function() {
						d.fire('display_vals_changed', field)
						d.fire('display_vals_changed_for_'+field.name)
					}
					field.lookup_rowset_loaded()
				}
				lr.on('loaded'      , field.lookup_rowset_loaded, on)
				lr.on('row_added'   , field.lookup_rowset_display_vals_changed, on)
				lr.on('row_removed' , field.lookup_rowset_display_vals_changed, on)
				lr.on('input_val_changed_for_'+field.lookup_col,
					field.lookup_rowset_display_vals_changed, on)
				lr.on('input_val_changed_for_'+(field.display_col || lr.name_col),
					field.lookup_rowset_display_vals_changed, on)
			}
		}
	}

	d.display_val = function(row, field) {
		let v = d.input_val(row, field)
		if (v == null)
			return field.null_text
		let lr = field.lookup_rowset
		if (lr) {
			let lf = field.lookup_field
			if (lf) {
				let row = lr.lookup(lf, v)
				if (row)
					return lr.display_val(row, field.display_field)
			}
			return field.lookup_failed_display_val(v)
		} else
			return field.format(v, row)
	}

	d.text_val = function(row, field) {
		let v = d.display_val(row, field)
		if (v instanceof Node)
			return v.textContent
		if (typeof v != 'string')
			return ''
		return v
	}

	// add/remove/move rows ---------------------------------------------------

	d.add_row = function(values, ev) {
		if (!d.can_add_rows)
			return
		let row = []
		// add server_default values or null
		for (let i = 0; i < d.fields.length; i++) {
			let field = d.fields[i]
			row[i] = or(or(values && values[field.name], field.server_default), null)
		}
		row.is_new = true
		d.rows.add(row)

		if (d.parent_field) {
			row.child_rows = []
			row.parent_row = ev && ev.parent_row || null
			;(row.parent_row || d).child_rows.push(row)
			if (row.parent_row) {
				// silently set parent id to be the id of the parent row before firing `row_added` event.
				let parent_id = d.val(row.parent_row, d.id_field)
				d.set_val(row, d.parent_field, parent_id, update({fire_changed_events: false}, ev))
			}
			assert(init_parents_for_row(row))
		}

		each_lookup('row_added', row)
		d.fire('row_added', row, ev)

		// set default client values as if they were typed in by the user.
		let set_val_ev = update({row_not_modified: true}, ev)
		for (let field of d.fields)
			if (field.client_default != null)
				d.set_val(row, field, field.client_default, set_val_ev)

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
			d.each_child_row(row, function(row) {
				d.rows.delete(row)
			})
			d.rows.delete(row)
			remove_row_from_tree(row)
			each_lookup('row_removed', row)
			d.fire('row_removed', row, ev)
		} else {
			if (!d.can_remove_row(row))
				return
			d.each_child_row(row, function(row) {
				if (d.set_row_state(row, 'removed', true, false))
					row_state_changed(row, 'row_removed', ev)
			})
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

	function init_params() {

		if (typeof d.param_names == 'string')
			d.param_names = d.param_names.split(' ')
		else if (!d.param_names)
			d.param_names = []

		bind_param_nav(false)

		if (d.param_names.length == 0)
			return

		if (!d.param_nav) {
			let param_fields = []
			let params_row = []
			for (let param of d.param_names) {
				param_fields.push({
					name: param,
				})
				params_row.push(null)
			}
			let params_rowset = rowset({fields: param_fields, rows: [params_row]})
			d.param_nav = rowset_nav({rowset: params_rowset})
		}

		if (d.attached)
			bind_param_nav(true)
	}

	function params_changed(row) {
		d.reload()
	}

	function bind_param_nav(on) {
		if (!d.param_nav)
			return
		if (!d.param_names || !d.param_names.length)
			return
		d.param_nav.on('focused_row_changed', params_changed, on)
		for (let param of d.param_names)
			d.param_nav.on('focused_row_val_changed_for_'+param, params_changed, on)
	}

	function make_url(params) {
		if (!d.param_nav)
			return d.url
		if (!params) {
			params = {}
			for (let param of d.param_names) {
				let field = d.param_nav.rowset.field(param)
				let row = d.param_nav.focused_row
				let v = row ? d.param_nav.rowset.val(row, field) : null
				params[field.name] = v
			}
		}
		return url(d.url, {params: json(params)})
	}

	// loading ----------------------------------------------------------------

	d.reload = function(params) {
		params = or(params, d.params)
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
			success: d.reset,
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

	d.load = function() {
		d.load = noop
		d.reload()
	}

	d.load_fields = function() {
		d.load_fields = noop
		d.reload(update({limit: 0}, d.params))
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

	d.reset = function(res) {

		d.fire('before_loaded')

		d.changed_rows = null

		d.can_edit        = or(res.can_edit         , d.can_edit)
		d.can_add_rows    = or(res.can_add_rows     , d.can_add_rows)
		d.can_remove_rows = or(res.can_remove_rows  , d.can_remove_rows)
		d.can_change_rows = or(res.can_change_rows  , d.can_change_rows)

		if (res.fields) {
			if (!check_fields(res.fields))
				return
			init_fields(res)
			d.id_col = res.id_col
		}

		if (res.params) {
			d.param_names = res.params
			init_params()
		}

		init_rows(res.rows)

		d.fire('loaded', !!res.fields)
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
				t.values[field.name] = d.old_val(row, field)
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
					t.values[field.name+':old'] = d.old_val(row, field)
				rows.push(t)
			}
		}
	}

	d.pack_changes = function(row) {
		let changes = {rows: []}
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
							d.reset_val(row, d.field(k), rt.values[k])
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

	d.save_to_url = function(row, url) {
		let req = ajax({
			url: url,
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

	d.save = function(row) {
		if (!d.changed_rows)
			return
		if (d.url)
			d.save_to_url(d.url, row)
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
			err = S('error_http', 'Server returned {0} {1}').subst(status, message)
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
			d = rowset({url: 'rowset.json/'+name, name: name}, ...options)
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
		allow_null: true,
		editable: true,
		sortable: true,
		maxlen: 256,
		true_text: () => H('<div class="fa fa-check"></div>'),
		false_text: '',
		null_text: S('null', 'null'),
		lookup_failed_display_val: function(v) {
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
		enum  : {},
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
				return S('error_multiple', 'Value must be multiple of {0}').subst(field.multiple_of)
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
		_d.setTime(t * 1000)
		return _d.toLocaleString(locale, this.date_format)
	}

	rowset.types.date.date_format =
		{weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' }

	rowset.types.date.editor = function(...options) {
		return date_dropdown(update({
			nolabel: true,
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

	// enums

	rowset.types.enum.editor = function(...options) {
		return list_dropdown(update({
			nolabel: true,
			items: this.enum_values,
		}, ...options))
	}

}

