
// ---------------------------------------------------------------------------
// rowset types
// ---------------------------------------------------------------------------

rowset.types.rowset = {}

rowsets_rowset = global_rowset('rowsets')
rowsets_rowset.load()

rowset.types.rowset.editor = function(...options) {
	return list_dropdown(update({
		nolabel: true,
		lookup_rowset: rowsets_rowset,
	}, ...options))
}

rowset.types.rowset_field = {}

rowset.types.rowset_field.editor = function(...options) {
	let e = list_dropdown(update({
		nolabel: true,
		lookup_rowset: rowset({
			fields: [{name: 'name'}],
		}),
	}, ...options))
	let rs_field = e.nav.rowset.field(this.rowset_col)
	let rs_name = e.nav.rowset.value(e.nav.focused_row, rs_field)
	let rs = rs_name && global_rowset(rs_name)
	if (rs) {
		rs.once('loaded', function() {
			let rows = rs.fields.map(field => [field.name])
			e.lookup_rowset.reset({
				rows: rows,
			})
		})
		rs.load_fields()
	}
	return e
}

// ---------------------------------------------------------------------------
// property inspector
// ---------------------------------------------------------------------------

prop_inspector = component('x-prop-inspector', function(e) {

	grid.construct(e)

	e.can_select_widget = false

	e.vertical = true

	e.exit_edit_on_lost_focus = false
	e.can_sort_rows = false
	e.enable_context_menu = false
	e.focus_cell_on_click_header = true

	// prevent getting out of edit mode.
	e.auto_edit_first_cell = true
	e.enter_edit_on_click = true
	e.exit_edit_on_escape = false
	e.exit_edit_on_enter = false
	e.stay_in_edit_mode = true

	e.rowset = rowset({
		can_change_rows: true,
	})

	init = e.init
	e.init = function() {
		init_widgets()
		init_rowset()
		init()
	}

	function bind(on) {
		document.on('selected_widgets_changed', selected_widgets_changed, on)
		document.on('prop_changed', prop_changed, on)
		document.on('focusin', focus_changed, on)
	}
	e.on('attach', function() { bind(true) })
	e.on('detach', function() { bind(false) })

	let widgets

	function init_widgets() {
		widgets = selected_widgets
		if (!selected_widgets.size && focused_widget() && focused_widget().can_select_widget)
			widgets = new Set([focused_widget()])
	}

	e.rowset.on('val_changed', function(row, field, val) {
		if (!widgets)
			init_widgets()
		for (let e of widgets)
			e[field.name] = val
	})

	function selected_widgets_changed() {
		init_widgets()
		init_rowset()
	}

	let barrier
	function focus_changed() {
		if (barrier) return
		if (selected_widgets.size)
			return
		let fe = focused_widget()
		if (!fe || !fe.can_select_widget)
			return
		barrier = true
		init_widgets()
		init_rowset()
		barrier = false
	}

	function prop_changed(k, v, v0, ev) {
		let widget = ev.target
		if (!widgets.has(widget))
			return
		let field = e.rowset.field(k)
		e.focus_cell(0, e.field_index(field))
		e.rowset.reset_val(e.focused_row, field, v)
	}

	/*
	e.on('exit_edit', function(ri, fi) {
		let field = e.fields[fi]
		e.rowset.reset_val(e.rows[ri], field, e.widget[field.name])
	})
	*/

	function init_rowset() {

		let res = {}
		res.fields = []
		let vals = []
		res.rows = [vals]

		let prop_counts = {}
		let props = {}
		let prop_vals = {}

		for (let e of widgets)
			for (let prop in e.props) {
				prop_counts[prop] = (prop_counts[prop] || 0) + 1
				props[prop] = e.props[prop]
				prop_vals[prop] = prop in prop_vals && prop_vals[prop] !== e[prop] ? undefined : e[prop]
			}

		for (let prop in prop_counts)
			if (prop_counts[prop] == widgets.size) {
				res.fields.push(props[prop])
				vals.push(prop_vals[prop])
			}

		e.rowset.reset(res)
	}

	// prevent unselecting all widgets by default on document.pointerdown.
	e.on('pointerdown', function(ev) { ev.stopPropagation() })

})

// ---------------------------------------------------------------------------
// widget tree
// ---------------------------------------------------------------------------

widget_tree = component('x-widget-tree', function(e) {

	function widget_tree_rows() {
		let rows = new Set()
		function add_widget(e, pe) {
			if (!e) return
			rows.add([e, pe])
			if (e.child_widgets)
				for (let ce of e.child_widgets())
					add_widget(ce, e)
		}
		add_widget(root_widget)
		return rows
	}

	function widget_name(e) {
		return e.typename.replace('_', ' ')
	}

	let rs = rowset({
		fields: [
			{name: 'widget', format: widget_name},
			{name: 'parent_widget', visible: false},
		],
		rows: widget_tree_rows(),
		pk: 'widget',
		parent_col: 'parent_widget',
	})

	grid.construct(e)

	e.can_select_widget = false

	e.rowset = rs
	e.tree_col = 'widget'
	e.header_visible = false
	e.can_focus_cells = false
	e.auto_focus_first_cell = false
	e.can_select_non_siblings = false

	function get_widget() {
		return e.focused_row && e.focused_row[0]
	}
	function set_widget(widget) {
		let row = rs.lookup(rs.field(0), widget)
		let ri = e.row_index(row)
		e.focus_cell(ri, 0)
	}
	e.property('widget', get_widget, set_widget)

	let barrier

	e.on('selected_rows_changed', function() {
		if (barrier) return
		barrier = true
		let to_unselect = new Set(selected_widgets)
		for (let [row] of e.selected_rows) {
			let ce = row[0]
			ce.set_widget_selected(true, false, false)
			to_unselect.delete(ce)
		}
		for (let ce of to_unselect)
			ce.set_widget_selected(false, false, false)
		document.fire('selected_widgets_changed')
		barrier = false
	})

	function selected_widgets_changed(widgets) {
		if (barrier) return
		barrier = true
		let rows = new Map()
		for (let ce of widgets) {
			let row = rs.lookup(rs.field(0), ce)
			rows.set(row, true)
		}
		let ce = [...widgets].pop()
		let row = rs.lookup(rs.field(0), ce)
		let ri = e.row_index(row)
		e.focus_cell(ri, null, 0, 0, {
			selected_rows: rows,
			must_not_move_row: true,
			unfocus_if_not_found: true,
			dont_select_widgets: true,
		})
		barrier = false
	}

	function widget_tree_changed() {
		rs.reset({rows: widget_tree_rows()})
	}

	function bind(on) {
		document.on('widget_tree_changed', widget_tree_changed, on)
		document.on('selected_widgets_changed', selected_widgets_changed, on)
	}
	e.on('attach', function() { bind(true) })
	e.on('detach', function() { bind(false) })

})

// toolboxes -----------------------------------------------------------------

function properties_toolbox(tb_opt, insp_opt) {
	let pg = prop_inspector(insp_opt)
	let tb = toolbox(update({
		title: 'properties',
		content: pg,
	}, tb_opt))
	tb.inspector = pg
	return tb
}

function widget_tree_toolbox(tb_opt, wt_opt) {
	let wt = widget_tree(wt_opt)
	let tb = toolbox(update({
		title: 'widget tree',
		content: wt,
	}, tb_opt))
	tb.tree = wt
	return tb
}

