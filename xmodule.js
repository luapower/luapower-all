
// ---------------------------------------------------------------------------
// prop layers
// ---------------------------------------------------------------------------

function xmodule(e) {

	let generation = 0

	assert(e.prop_layer_slots) // {slot -> layer_obj} in application order.
	attr(e, 'prop_layer_slot_colors')
	e.widgets = {} // {gid -> e}
	e.prop_layers = {} // {layer -> {slot:, name:, widgets: {gid -> prop_vals}}}
	e.selected_prop_slot = null

	e.resolve = gid => e.widgets[gid]

	e.nav_editor = function(...options) {
		return widget_select_editor(e.widgets, e => e.isnav, ...options)
	}

	document.on('widget_attached', function(te) {
		e.widgets[te.gid] = te
		update_widget(te)
		document.fire('widget_tree_changed')
	})

	document.on('widget_detached', function(te) {
		delete e.widgets[te.gid]
		document.fire('widget_tree_changed')
	})

	document.on('prop_changed', function(te, k, v, v0, slot) {
		if (!te.gid) return
		if (te.xmodule_updating_props) return
		slot = e.selected_prop_slot || slot || 'base'
		if (slot == 'none')
			return
		set_prop_val(te, slot, k, v, v0)
	})

	e.prop_vals = function(gid) {
		let t = {}
		let opt = {gid: gid, prop_layers_generation: generation, __pv: t}
		for (let slot in e.prop_layer_slots) {
			let layer_obj = e.prop_layer_slots[slot]
			if (layer_obj) {
				let prop_vals = layer_obj.widgets[gid]
				update(t, prop_vals)
			}
		}
		opt.type = t.type
		delete t.type
		return opt
	}

	e.init_widget = function(te) {
		te.xmodule_updating_props = true
		te.begin_update()
		let pv = te.__pv // the props set via prop_vals().
		te.__pv = null // don't need them after this.
		te.__pv0 = {} // prop vals before overrides.
		for (let k in pv)
			te.__pv0[k] = te.get_prop(k)
		for (let k in pv)
			te.set_prop(k, pv[k])
		te.end_update()
		te.xmodule_updating_props = false
	}

	function update_widget(te) {
		if (te.prop_layers_generation == generation)
			return
		te.xmodule_updating_props = true
		te.begin_update()
		let pv = e.prop_vals(te.gid).__pv
		let pv0 = attr(te, '__pv0') // initial vals of overriden props.
		// restore prop vals that are not present in this override.
		for (let prop in pv0)
			if (!(prop in pv)) {
				te.set_prop(prop, pv0[prop])
				delete pv0[prop]
			}
		// apply this override, saving current vals that were not saved before.
		for (let prop in pv) {
			if (!(prop in pv0))
				pv0[prop] = te.get_prop(prop)
			te.set_prop(prop, pv[prop])
		}
		te.end_update()
		te.xmodule_updating_props = false
	}

	function set_prop_val(te, slot, k, v, v0) {
		let layer_obj = e.prop_layer_slots[slot]
		if (!layer_obj) {
			print('prop-val-lost', te.gid, k, v, slot)
			return
		}

		v = te.serialize_prop(k, v)

		let t = layer_obj.widgets[te.gid]

		if (t && t[k] === v) // value already stored.
			return

		if (!t) {
			t = {}
			layer_obj.widgets[te.gid] = t
		}
		layer_obj.modified = true
		let pv0 = attr(te, '__pv0')
		if (v === undefined) { // `undefined` signals removal.
			if (t[k] !== undefined) {
				print('prop-val-deleted', te.gid, k, slot, layer_obj.name)
				delete t[k]
				delete pv0[k] // no need to keep this anymore.
			}
		} else {
			if (!(k in pv0)) // save current val if it wasn't saved before.
				pv0[k] = v0
			t[k] = v
			print('prop-val-set', te.gid, k, slot, layer_obj.name, v)
		}
	}

	e.update_widgets = function(layer_widgets) {
		for (let gid in e.widgets)
			if (layer_widgets && layer_widgets[gid])
				update_widget(e.widgets[gid])
	}

	function add_prop_layer_slot(slot) {

		// find a place for the slot.
		let before_slot; {
			let slots = keys(e.prop_layer_slots)
			slots.push(slot)
			slots.sort()
			before_slot = slots[slots.indexOf(slot) - 1]
		}
		let slots = keys(e.prop_layer_slots)
		slots.insert(slots.indexOf(before_slot) + 1, slot)

		let t = {}
		for (let slot of slots)
			t[slot] = e.prop_layer_slots[slot]
		e.prop_layer_slots = t
	}

	e.set_prop_layer = function(slot, layer, reload, on_loaded, async) {

		function update_layer(layer_widgets) {

			generation++

			if (slot) {

				if (!(slot in e.prop_layer_slots))
					add_prop_layer_slot(slot)

				let old_layer_obj = e.prop_layer_slots[slot]
				if (old_layer_obj)
					old_layer_obj.slot = null
			}
			let layer_obj = e.prop_layers[layer]
			if (!layer_obj) {
				layer_obj = {slot: slot, name: layer, widgets: layer_widgets}
				e.prop_layers[layer] = layer_obj
			} else {
				layer_obj.layer_widgets = layer_widgets
			}
			if (slot)
				e.prop_layer_slots[slot] = layer_obj

			e.update_widgets(layer_widgets)

			if (slot)
				document.fire('prop_layer_slots_changed')

			if (on_loaded)
				on_loaded()
		}

		if (!layer) {
			let layer_obj = e.prop_layer_slots[slot]
			if (!layer_obj)
				return
			e.prop_layer_slots[slot] = null
			slot = null
			update_layer(layer_obj.widgets)
			return
		}

		let layer_obj = e.prop_layers[layer]
		if (!layer_obj || reload) {
			ajax({
				url: 'xmodule-layer.json/'+layer,
				success: function(widgets) {
					update_layer(widgets)
				},
				async: async,
				fail: function(how, status) {
					if (how == 'http' && status == 404)
						update_layer({})
				},
			})
		} else {
			update_layer(layer_obj.widgets)
		}

	}

	e.save_prop_layer = function(layer) {
		let layer_obj = e.prop_layers[layer]
		if (layer_obj.save_request)
			return // already saving...

		layer_obj.save_request = ajax({
			url: 'xmodule-layer.json/'+layer,
			upload: json(layer_obj.widgets, null, '\t'),
			done: () => layer_obj.save_request = null,
		})
	}

	e.reload = function() {
		for (let layer in e.prop_layers) {
			let layer_obj = e.prop_layers[layer]
			e.set_prop_layer(layer_obj.slot, layer, true)
		}
	}

	e.save = function() {
		for (let layer in e.prop_layers)
			if (e.prop_layers[layer].modified)
				e.save_prop_layer(layer)
	}

	e.assign_gid = function(widget) {
		ajax({
			url: 'xmodule-next-gid/'+assert(widget.module),
			method: 'post',
			// TODO: find another way since smart-ass condescending w3c people
			// deprecated synchronous requests.
			async: false,
			success: function(gid) {
				widget.gid = gid
			},
		})
	}

	return e

}

// ---------------------------------------------------------------------------
// rowsets nav
// ---------------------------------------------------------------------------

//rowsets_nav = bare_nav({rowset_name: 'rowsets'})
//rowsets_nav.reload()

// ---------------------------------------------------------------------------
// rowset types
// ---------------------------------------------------------------------------

field_types.rowset = {}

field_types.rowset.editor = function(...options) {
	function more() {
		let d = sql_rowset_editor_dialog()
		d.modal()
	}
	return list_dropdown(update({
		nolabel: true,
		rowset_name: 'rowsets',
		val_col: 'name',
		display_col: 'name',
		mode: 'fixed',
		more_action: more,
	}, ...options))
}

// col

field_types.col = {}

/*
field_types.col.editor = function(...options) {
	let rs = rowset({
		fields: [{name: 'name'}],
	})
	let e = list_dropdown(update({
		nolabel: true,
		lookup_rowset: rs,
		mode: 'fixed',
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
*/

// ---------------------------------------------------------------------------
// state toaster
// ---------------------------------------------------------------------------

window.on('load', function() {
	state_toaster = toaster({
		timeout: null,
	})
	document.body.add(state_toaster)
})

// ---------------------------------------------------------------------------
// prop layers inspector
// ---------------------------------------------------------------------------

component('x-prop-layers-inspector', function(e) {

	grid.construct(e)
	e.cell_h = 22
	e.stay_in_edit_mode = false

	e.can_select_widget = false

	let barrier
	function reset() {
		if (barrier)
			return
		let rows = []
		for (let slot in xmodule.prop_layer_slots) {
			let layer_obj = xmodule.prop_layer_slots[slot]
			let layer = layer_obj ? layer_obj.name : null
			let row = [true, true, true, xmodule.prop_layer_slot_colors[slot] || '#fff', slot, layer]
			rows.push(row)
		}
		e.rowset = {
			fields: [
				{name: 'active', type: 'bool', visible: false},
				{name: 'selected', type: 'bool', w: 24,
					format: (_, row) => e.cell_val(row, e.all_fields.active)
						? H('<div class="fa fa-chevron'
							+(e.cell_val(row, e.all_fields.slot) == xmodule.selected_prop_slot ? '-circle' : '')
							+'-right" style="font-size: 80%"></div>') : '',
				},
				{name: 'visible', type: 'bool', w: 24,
					true_text: () => H('<div class="fa fa-eye" style="font-size: 80%"></div>'),
					false_text: '',
				},
				{name: 'color', w: 24, type: 'color'},
				{name: 'slot', w: 60},
				{name: 'layer', w: 60},
			],
			rows: rows,
		}
		e.reset()
	}

	let can_change_val = e.can_change_val
	e.can_change_val = function(row, field) {
		return can_change_val(row, field)
			&& (!row || !field || e.cell_val(row, e.all_fields.slot) != 'base'
					|| field.name == 'selected' || field.name == 'active')
	}

	e.on('bind', function(on) {
		document.on('prop_layer_slots_changed', reset, on)
		reset()
	})

	function set_selected_prop_slot(sel_slot) {
		if (barrier)
			return
		barrier = true

		xmodule.selected_prop_slot = sel_slot

		e.begin_update()
		let active = true

		for (let row of e.rows) {
			let slot    = e.cell_val(row, e.all_fields.slot)
			let layer   = e.cell_val(row, e.all_fields.layer)
			let visible = e.cell_val(row, e.all_fields.visible)
			let layer_obj = xmodule.prop_layers[layer]
			xmodule.set_prop_layer(slot, active && visible ? layer : null)
			e.reset_cell_val(row, e.all_fields.active, active)
			e.reset_cell_val(row, e.all_fields.selected, e.cell_val(row, e.all_fields.selected))
			if (slot == sel_slot)
				active = false
		}
		e.update({vals: true})
		e.end_update()

		if (e.state_tooltip)
			e.state_tooltip.close()

		if (sel_slot) {
			let layer_obj = xmodule.prop_layer_slots[xmodule.selected_prop_slot]
			let s = sel_slot + ': '+ (layer_obj ? layer_obj.name : 'none')
			e.state_tooltip = state_toaster.post(s, 'error')
			e.state_tooltip.close_button = true
			e.state_tooltip.on('closed', function() {
				e.state_tooltip = null
				if (barrier) return
				set_selected_prop_slot(null)
			})
		}

		barrier = false
	}

	e.on('cell_val_changed_for_selected', function(row, val) {
		let sel_slot = e.cell_val(row, e.all_fields.slot)
		set_selected_prop_slot(sel_slot)
	})

	e.on('cell_val_changed_for_visible', function(row, val) {
		if (barrier)
			return
		barrier = true
		let slot    = e.cell_val(row, e.all_fields.slot)
		let layer   = e.cell_val(row, e.all_fields.layer)
		let active  = e.cell_val(row, e.all_fields.active)
		let visible = e.cell_val(row, e.all_fields.visible)
		xmodule.set_prop_layer(slot, active && visible ? layer : null)
		barrier = false
	})

	e.on('cell_val_changed_for_color', function(row, val) {
		let slot = e.cell_val(row, e.all_fields.slot)
		xmodule.prop_layer_slot_colors[slot] = val
		document.fire('selected_widgets_changed')
	})

	e.reset_to_default = function() {
		for (let row of e.rows)
			e.reset_cell_val(row, e.all_fields.visible, true)
		if (e.state_tooltip)
			e.state_tooltip.close()
	}

})

// ---------------------------------------------------------------------------
// nav editor for prop inspector
// ---------------------------------------------------------------------------

function widget_select_editor(widgets_gid_map, filter, ...options) {
	let dd = list_dropdown({
		rowset: {
			fields: [{name: 'gid'}],
		},
		nolabel: true,
		val_col: 'gid',
		display_col: 'gid',
		mode: 'fixed',
	}, ...options)
	function reset_nav() {
		let rows = []
		for (let gid in widgets_gid_map) {
			let te = widgets_gid_map[gid]
			if (te.can_select_widget && filter(te))
				rows.push([gid])
		}
		dd.picker.rowset.rows = rows
		dd.picker.reset()
	}
	dd.on('bind', function(on) {
		document.on('widget_tree_changed', reset_nav, on)
	})
	reset_nav()
	return dd
}

field_types.nav = {}
field_types.nav.editor = function(...args) {
	return xmodule.nav_editor(...args)
}

// ---------------------------------------------------------------------------
// property inspector
// ---------------------------------------------------------------------------

component('x-prop-inspector', function(e) {

	grid.construct(e)
	e.cell_h = 22

	e.can_add_rows = false
	e.can_remove_rows = false

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

	e.empty_text = 'No widgets selected or focused'

	e.on('bind', function(on) {
		document.on('selected_widgets_changed', selected_widgets_changed, on)
		document.on('prop_changed', prop_changed, on)
		document.on('focusin', focus_changed, on)
		if (on)
			reset()
	})

	e.on('cell_val_changed', function(row, field, val, ev) {
		if (!ev)
			return // from reset()
		for (let te of widgets)
			te.set_prop(field.name, val)
	})

	function selected_widgets_changed() {
		reset()
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
		reset()
		barrier = false
	}

	function prop_changed(te, k, v) {
		if (!widgets.has(te))
			return
		let field = e.all_fields[k]
		if (!field)
			return
		if (e.editor && e.focused_field == field)
			return
		e.focus_cell(0, e.field_index(field), 0, 0, {
			// NOTE: override these options because if we're in updating mode,
			// editor_state = 'toggle' from the last time would be applied,
			// which would result in an infinte loop.
			enter_edit: true,
			editor_state: 'select_all',
		})
		e.reset_val(e.focused_row, field, v)
	}

	/*
	e.on('exit_edit', function(ri, fi) {
		let field = e.fields[fi]
		e.reset_cell_val(e.rows[ri], field, e.widget[field.name])
	})
	*/

	let widgets

	function reset() {

		widgets = selected_widgets
		if (!selected_widgets.size && focused_widget() && !up_widget_which(focused_widget(), e => !e.can_select_widget))
			widgets = new Set([focused_widget()])

		let i = 0
		for (let te of widgets) // for debugging...
			window['$'+i++] = te

		let rs = {}
		rs.fields = []
		let row = []
		rs.rows = []

		let prop_counts = {}
		let defs = {}
		let pv0 = {}
		let pv1 = {}
		let slots = {}

		for (let te of widgets)
			for (let prop in te.props)
				if (widgets.size == 1 || !te.props[prop].unique) {
					prop_counts[prop] = (prop_counts[prop] || 0) + 1
					defs[prop] = te.props[prop]
					let v1 = te.serialize_prop(prop, te[prop], true)
					let v0 = te.serialize_prop(prop, defs[prop].default, true)
					pv0[prop] = prop in pv0 && pv0[prop] !== v0 ? undefined : v0
					pv1[prop] = prop in pv1 && pv1[prop] !== v1 ? undefined : v1
					slots[prop] = defs[prop].slot
				}

		for (let prop in prop_counts)
			if (prop_counts[prop] == widgets.size) {
				rs.fields.push(update({}, defs[prop], {convert: null}))
				row.push(repl(pv0[prop], undefined, null))
			}

		if (row.length)
			rs.rows.push(row)

		e.rowset = rs
		e.reset()

		let inh_do_update_cell_val = e.do_update_cell_val
		e.do_update_cell_val = function(cell, row, field, input_val) {
			inh_do_update_cell_val(cell, row, field, input_val)
			let color = xmodule.prop_layer_slot_colors[slots[field.name]]
			let hcell = e.header.at[field.index]
			hcell.style['border-right'] = '4px solid'+color
		}

		if (e.all_rows.length) {
			let row = e.all_rows[0]
			for (let field of e.all_fields)
				e.set_cell_val(row, field, pv1[field.name])
		}

		e.title_text = ([...widgets].map(e => e.type + (e.gid ? ' ' + e.gid : ''))).join(' ')

		e.fire('prop_inspector_changed')
	}

	// prevent unselecting all widgets by default on document.pointerdown.
	e.on('pointerdown', function(ev) {
		ev.stopPropagation()
	})

})

// ---------------------------------------------------------------------------
// widget tree
// ---------------------------------------------------------------------------

component('x-widget-tree', function(e) {

	grid.construct(e)
	e.cell_h = 22

	function widget_tree_rows() {
		let rows = new Set()
		function add_widget(e, pe) {
			if (!e) return
			rows.add([e, pe, true])
			if (e.child_widgets)
				for (let ce of e.child_widgets())
					add_widget(ce, e)
		}
		add_widget(root_widget)
		return rows
	}

	function widget_name(e) {
		return () => typeof e == 'string'
			? e : H((e.id && '<b>'+e.id+'</b> ' || e.type.replace('_', ' ')))
	}

	let rs = {
		fields: [
			{name: 'widget', format: widget_name},
			{name: 'parent_widget', visible: false},
			{name: 'id', w: 40, format: (_, row) => row[0].id, visible: false},
		],
		rows: widget_tree_rows(),
		pk: 'widget',
		parent_col: 'parent_widget',
	}

	e.rowset = rs
	e.cols = 'id widget'
	e.tree_col = 'widget'

	e.can_select_widget = false
	e.header_visible = false
	e.can_focus_cells = false
	e.can_change_rows = false
	e.auto_focus_first_cell = false
	e.can_select_non_siblings = false

	function get_widget() {
		return e.focused_row && e.focused_row[0]
	}
	function set_widget(widget) {
		let row = e.lookup(e.all_fields[0], widget)
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

	function select_widgets(widgets) {
		let rows = new Map()
		for (let ce of widgets) {
			let row = e.lookup(e.all_fields[0], ce)
			rows.set(row, true)
		}
		let focused_widget = [...widgets].pop()
		let row = e.lookup(e.all_fields[0], focused_widget)
		let ri = e.row_index(row)
		e.focus_cell(ri, null, 0, 0, {
			selected_rows: rows,
			must_not_move_row: true,
			unfocus_if_not_found: true,
			dont_select_widgets: true,
		})
	}

	function selected_widgets_changed() {
		if (barrier) return
		barrier = true
		select_widgets(selected_widgets)
		barrier = false
	}

	function widget_tree_changed() {
		rs.rows = widget_tree_rows()
		e.reset()
	}

	/* TODO: not sure what to do here...
	function focus_changed() {
		if (selected_widgets.size)
			return
		let fe = focused_widget()
		if (!fe || !fe.can_select_widget)
			return
		//select_widgets(new Set([fe]))
	}
	*/

	e.on('bind', function(on) {
		document.on('widget_tree_changed', widget_tree_changed, on)
		document.on('selected_widgets_changed', selected_widgets_changed, on)
		//document.on('focusin', focus_changed, on)
	})

})

// ---------------------------------------------------------------------------
// sql rowset editor
// ---------------------------------------------------------------------------

sql_rowset_editor = component('x-sql-rowset-editor', function(e) {



})

// ---------------------------------------------------------------------------
// sql schema editor
// ---------------------------------------------------------------------------



// ---------------------------------------------------------------------------
// globals list
// ---------------------------------------------------------------------------

function globals_list() {

}

// ---------------------------------------------------------------------------
// toolboxes
// ---------------------------------------------------------------------------

let dev_toolbox_props = {
	text: {slot: 'none'},
	popup_x: {slot: 'dev'},
	popup_y: {slot: 'dev'},
}

function prop_layers_toolbox(tb_opt, insp_opt) {
	let pg = prop_layers_inspector(update({
			gid: 'prop_layers_inspector',
		}, insp_opt))
	let tb = toolbox(update({
			gid: 'prop_layers_toolbox',
			text: 'property layers',
			props: dev_toolbox_props,
			content: pg,
			can_select_widget: false,
		}, tb_opt))
	tb.inspector = pg
	return tb
}

function props_toolbox(tb_opt, insp_opt) {
	let pg = prop_inspector(update({
			gid: 'prop_inspector',
		}, insp_opt))
	let tb = toolbox(update({
			gid: 'props_toolbox',
			text: 'properties',
			props: dev_toolbox_props,
			content: pg,
			can_select_widget: false,
		}, tb_opt))
	tb.inspector = pg
	pg.on('prop_inspector_changed', function() {
		tb.text = pg.title_text + ' properties'
	})
	return tb
}

function widget_tree_toolbox(tb_opt, wt_opt) {
	let wt = widget_tree(update({
			gid: 'widget_tree',
		}, wt_opt))
	let tb = toolbox(update({
			gid: 'widget_tree_toolbox',
			text: 'widget tree',
			props: dev_toolbox_props,
			content: wt,
			can_select_widget: false,
		}, tb_opt))
	tb.tree = wt
	return tb
}

prop_layers_tb = null
props_tb = null
tree_tb = null

function show_toolboxes(on) {

	if (on == 'toggle')
		on = !prop_layers_tb

	if (on !== false) {
		prop_layers_tb = prop_layers_toolbox({
			popup_y: 2, w: 222, h: 225,
		})
		prop_layers_tb.show(true, true)

		props_tb = props_toolbox({
			popup_y: 230, w: 222, h: 397,
		}, {header_w: 80})
		props_tb.show(true, true)

		tree_tb = widget_tree_toolbox({
			popup_y: 630, w: 222, h: 311,
		})
		tree_tb.show(true, true)
	} else {

		prop_layers_tb.inspector.reset_to_default()

		prop_layers_tb.remove()
		props_tb.remove()
		tree_tb.remove()

		prop_layers_tb = null
		props_tb = null
		tree_tb = null
	}
}

// ---------------------------------------------------------------------------
// dialogs
// ---------------------------------------------------------------------------

function sql_rowset_editor_dialog() {
	let ed = sql_rowset_editor()
	let d = dialog({
		text: 'SQL Rowset Editor',
		content: ed,
		footer: '',
	})
	d.editor = ed
	return d
}

