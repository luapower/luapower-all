
/* ---------------------------------------------------------------------------
// client-side rowsets with referential integrity constraints.
// ---------------------------------------------------------------------------

	e.fields: [{col -> field})
		field.default
		field.fk_rowset
		field.fk_col
		field.on_update: 'cascade' | action(rs, rrow, fk, v)
		field.on_delete: 'cascade' | 'set_null' | action(rs, rrow, fk)
	e.fks: [{rowset:, cols: {fk_col->ref_col}, on_update:, on_delete:},...]
	e.rows: [{col -> val}, ...]

	e.cell_val(row, col)
	e.set_cell_val(row, col, v)
	e.remove_rows(new Set(row1,...))
	e.reorder_rows(rows)
	e.insert_row()

	NOTE: for foreign key constraints to work, all related rowsets must be
	kept instantiated at all times, regardless of the layer they have values in.

*/
function rowset(opt) {

	let e = {isinstance: true, isrowset: true}
	events_mixin(e)

	let fields = empty
	let rows = empty_array
	let fks = empty_array

	function add_fk(fk_rs, fk) {
		attr(xmodule.fks, fk_rs)[e.gid] = fk
	}

	function remove_fks() {
		if (!e.gid) return
		for (let fk of fks)
			delete xmodule.fks[fk.fk_rowset][e.gid]
		for (let col in fields) {
			let field = fields[col]
			if (field.fk_gid)
				delete xmodule.fks[field.fk_rowset][e.gid]
		}
	}

	function add_fks() {
		if (!e.gid) return
		if (fks)
			for (let fk of fks)
				add_fk(fk.rowset, {
					cols: fk.cols,
					on_update: fk.on_update,
					on_delete: fk.on_delete,
				})
		for (let col in fields) {
			let field = fields[col]
			if (field.fk_rowset)
				add_fk(field.fk_rowset, {
					cols: {[field.fk_col || col]: col},
					on_update: field.on_update,
					on_delete: field.on_delete,
				})
		}
	}

	function set_fields(v) {
		if (fields == v) return
		remove_fks()
		fields = v
		add_fks()
	}

	function set_rows(v) {
		if (rows == v) return
		rows = v
	}

	function set_fks(v) {
		if (fks == v) return
		remove_fks()
		fks = v
		add_fks()
	}

	e.prop = function(name, get, set) {
		property(e, name, {get: get, set: set})
	}

	e.prop('fields', () => fields , set_fields)
	e.prop('rows'  , () => rows   , set_rows  )
	e.prop('fks'   , () => fks    , set_fks   )

	e.cell_default_val = function(col) {
		return or(fields[col].default, null)
	}

	e.cell_val = function(row, col) {
		return strict_or(row[col], e.cell_default_val(col))
	}

	function vals_equal(row, rs, rrow, fk_cols) {
		for (let fk_col in fk_cols) {
			let rcol = fk_cols[fk_col]
			if (rs.cell_val(rrow, rcol) !== e.cell_val(row, fk_col))
				return false
		}
		return true
	}

	function each_fk_ref_row(row, matches, col, enforce_fk) {
		let fks = xmodule.fks[e.gid]
		if (!fks) return
		for (let gid in fks) {
			let fk = fks[gid]
			if (fk && matches(fk, col)) {
				let rs = xmodule.instances[e.gid][0]
				let remset
				for (let rrow of rs.rows)
					if (vals_equal(row, rs, rrow, fk.cols)) {
						if (enforce_fk(rs, rrow, fk) == 'remove') {
							remset = remset || new Set()
							remset.add(rrow)
						}
					}
				if (remset)
					rs.remove_rows(remset)
			}
		}
	}

	let fk_matches_col = (fk, col) => fk.cols[col]

	e.set_cell_val = function(row, col, v) {

		if (e.gid) {
			each_fk_ref_row(row, fk_matches_col, col, function(rs, rrow, fk) {
				let action = or(fk.on_update, 'cascade')
				if (action == 'cascade')
					rs.set_cell_val(rrow, fk.cols[col], v)
				else if (action)
					action(rs, rrow, fk, v)
			})
		}

		v = or(v, null)
		let v0 = e.cell_val(row, col)
		if (v === e.cell_default_val(col))
			delete row[col]
		else
			row[col] = v
	}

	e.remove_rows = function(row_set) {

		if (e.gid) {
			function enforce_fk(rs, rrow, fk) {
				let action = or(fk.on_delete, 'cascade')
				if (action == 'cascade')
					return 'remove'
				else if (action == 'set_null') {
					for (let rcol of fk.cols)
						e.set_cell_val(rrow, rcol, null)
				} else if (action)
					action(rs, rrow, fk)
			}
			for (let row of row_set)
				each_fk_ref_row(row, return_true, null, enforce_fk)
		}

		let all_rows = rows
		rows = []
		for (let row of all_rows)
			if (!row_set.has(row))
				rows.push(row)
	}

	e.insert_row = function(row) {
		//
	}

	e.reorder_rows = function(rows) {
		e.rows = rows
	}

	// xmodule instance protocol

	e.get_prop = k => e[k]
	e.set_prop = function(k, v) { e[k] = v }
	e.begin_update = noop
	e.end_update = noop

	// init & bind.

	e.bind = function(on) {
		xmodule.bind_instance(e, on)
	}

	opt = opt || empty
	if (!opt.gid) {
		for (let k in opt)
			e[k] = opt[k]
	} else {
		xmodule.init_instance(e, opt)
		e.bind(true)
	}

	return e
}

component.types.rowset = rowset

/* ---------------------------------------------------------------------------
// client rowsets kept in xmodule prop layers
// ---------------------------------------------------------------------------

	xnodule.fks

*/
function xmodule_rowsets_mixin(xm) {

	xm.fks = {} // {fk_rowset -> {ref_gid -> {cols: {fk_col->col}, on_delete:, on_update: }}}

	function each_fk_ref_row(row, matches, col, enforce_fk) {
		let fks = xmodule.fks[e.gid]
		if (!fks) return
		for (let gid in fks) {
			let fk = fks[gid]
			if (fk && matches(fk, col)) {
				let rs = xmodule.instances[e.gid][0]
				let remset
				for (let rrow of rs.rows)
					if (vals_equal(row, rs, rrow, fk.cols)) {
						if (enforce_fk(rs, rrow, fk) == 'remove') {
							remset = remset || new Set()
							remset.add(rrow)
						}
					}
				if (remset)
					rs.remove_rows(remset)
			}
		}
	}

	let fk_matches_col = (fk, col) => fk.cols[col]

	function nav_cell_val_changed(row, field, val) {
		let e = this
		let fk = xm.fks[e.gid]
		if (!fk) return
		let col = field.name
		each_fk_ref_row(row, fk_matches_col, col, function(rs, rrow, fk) {
			let action = or(fk.on_update, 'cascade')
			if (action == 'cascade')
				rs.set_cell_val(rrow, fk.cols[col], v)
			else if (action)
				action(rs, rrow, fk, v)
		})
	}

	function nav_rows_removed(rows) {
		let e = this
		let fk = xm.fks[e.gid]
		if (!fk) return
		print('nav_rows_removed', e.gid, fk)
	}

	document.on('widget_bind', function(e, on) {
		if (!xm.fks[e.gid])
			return
		e.on('cell_val_changed', nav_cell_val_changed, on)
		e.on('rows_removed', nav_rows_removed, on)
	})

}

