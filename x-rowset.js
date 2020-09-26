
/* ---------------------------------------------------------------------------
	client-side rowsets with referential integrity constraints.
------------------------------------------------------------------------------

	e.fields: [{col -> field})
		field.default
		field.fk_rowset
		field.fk_col
		field.on_update: 'cascade' | action(rs, rrow, fk, v)
		field.on_delete: 'cascade' | 'set_null' | action(rs, rrow, fk)
	e.fks: [{rowset_gid -> {fk_col->ref_col}, on_update:, on_delete:},...]
	e.rows: [{col -> val}, ...]

	e.cell_val(row, col)
	e.set_cell_val(row, col, v)
	e.remove_rows(new Set(row1,...))

	xmodule.rowset(gid, opt) -> e
	xmodule.create_rowsets(layer_props)

*/

function xmodule_rowsets(xmodule) {

	xmodule.rowsets = {} // {gid -> rowset}
	xmodule.rowset_fks = {} // {fk_rowset_gid -> {ref_gid -> {cols: {fk_col->col}, on_delete:, on_update: }}}

	function create_rowset(e) {

		let fields = empty
		let rows = empty_array
		let fks = empty_array

		function split(ss) {
			let t = {}
			for (let s of ss.split(/\s+/))
				t[s] = true
			return t
		}

		function add_fk(fk_rs, fk) {
			attr(xmodule.rowset_fks, fk_rs)[e.gid] = fk
		}

		function set_fields(v) {
			fields = v
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

		function set_rows(v) {
			/*
			rows = []
			for (vals of v) {
				let row = []
				for (let fi = 0; fi < fields.length; fi++) {
					let field = fields[fi]
					row[fi] = strict_or(vals[field.name], or(field.default, null))
				}
				rows.push(row)
			}
			*/
			rows = v
		}

		function set_fks(v) {
			fks = v
			for (let fk of fks)
				add_fk(fk.rowset, {
					cols: fk.cols,
					on_update: fk.on_update,
					on_delete: fk.on_delete,
				})
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

		function vals_equal(row, rs, rrow, fk_cols) {
			for (let fk_col in fk_cols) {
				let rcol = fk_cols[fk_col]
				if (rs.cell_val(rrow, rcol) !== e.cell_val(row, fk_col))
					return false
			}
			return true
		}

		function each_fk_ref_row(row, matches, col, enforce_fk) {
			let fks = xmodule.rowset_fks[e.gid]
			if (!fks) return
			for (let gid in fks) {
				let fk = fks[gid]
				if (fk && matches(fk, col)) {
					let rs = xmodule.rowsets[gid]
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

			each_fk_ref_row(row, fk_matches_col, col, function(rs, rrow, fk) {
				let action = or(fk.on_update, 'cascade')
				if (action == 'cascade')
					rs.set_cell_val(rrow, fk.cols[col], v)
				else if (action)
					action(rs, rrow, fk, v)
			})

			v = or(v, null)
			let v0 = e.cell_val(row, col)
			if (v === e.cell_default_val(col))
				delete row[col]
			else
				row[col] = v
		}

		e.remove_rows = function(row_set) {

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

			let all_rows = rows
			rows = []
			for (let row of all_rows)
				if (!row_set.has(row))
					rows.push(row)
		}

	}

	xmodule.rowset = function(gid, opt) {
		let e = xmodule.rowsets[gid]
		if (!e) {
			if (opt.type != 'rowset')
				return
			e = {gid: gid}
			create_rowset(e)
			xmodule.rowsets[gid] = e
		}
		return update(e, opt)
	}

	xmodule.create_rowsets = function(layer_props) {
		for (let gid in layer_props)
			xmodule.rowset(gid, layer_props[gid])
	}

}

