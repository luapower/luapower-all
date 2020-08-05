/*

	X-WIDGETS: Model-driven live-editable web components in JavaScript.
	Written by Cosmin Apreutesei. Public Domain.

*/

// ---------------------------------------------------------------------------
// undo stack, selected widgets, editing widget and clipboard.
// ---------------------------------------------------------------------------

undo_stack = []
redo_stack = []

function push_undo(f) {
	undo_stack.push(f)
}

function undo() {
	let f = undo_stack.pop()
	if (!f)
		return
	redo_stack.push(f)
	f()
}

function redo() {
	;[undo_stack, redo_stack] = [redo_stack, undo_stack]
	undo()
	;[undo_stack, redo_stack] = [redo_stack, undo_stack]
}

function focused_widget(e) {
	e = e || document.activeElement
	return e && e.typename && e || (e.parent && e.parent != e && focused_widget(e.parent))
}

editing_widget = null
selected_widgets = new Set()

function unselect_all_widgets() {
	if (editing_widget)
		editing_widget.widget_editing = false
	for (let e of selected_widgets)
		e.widget_selected = false
}

copied_widgets = new Set()

function copy_selected_widgets() {
	copied_widgets = new Set(selected_widgets)
}

function cut_selected_widgets() {
	copy_selected_widgets()
	for (let e of selected_widgets)
		e.remove_widget()
}

function paste_copied_widgets(parent_widget) {
	for (let e of copied_widgets)
		parent_widget.add_widget(e)
}

document.on('keydown', function(key, shift, ctrl) {
	if (key == 'Escape')
		unselect_all_widgets()
	else if (ctrl && key == 'c')
		copy_selected_widgets()
	else if (ctrl && key == 'x')
		cut_selected_widgets()
	else if (ctrl && key == 'z')
		if (shift)
			redo()
		else
			undo()
	else if (ctrl && key == 'y')
		redo()
})

document.on('pointerdown', function() {
	unselect_all_widgets()
})

// ---------------------------------------------------------------------------
// selectable widget mixin
// ---------------------------------------------------------------------------

function parent_widget(e) {
	assert(e != window)
	let parent = e.parent
	while (parent) {
		if (parent.child_widgets)
			return parent
		parent = parent.parent
	}
}

function selectable_parent_widget(e) {
	assert(e != window)
	let parent = e.parent
	while (parent) {
		if (parent.child_widgets && parent.can_select_widget)
			return parent
		parent = parent.parent
	}
}

function selectable_widget(e) {

	attr(e, 'props').id = {name: 'id'}

	override_property_setter(e, 'id', function(inherited, id) {
		let id0 = e.id
		inherited.call(this, id)
		if (id === id0)
			return
		this.fire('prop_changed', 'id', id, id0)
		document.fire(event('global_changed', false, this, id, id0))
	})

	e.property('parent_widget', function() {
		return parent_widget(this)
	})

	e.property('selectable_parent_widget', function() {
		return selectable_parent_widget(this)
	})

	e.can_select_widget = true

	e.set_widget_selected = function(select, focus, fire_changed_event) {
		select = select !== false
		if (e.widget_selected == select)
			return
		if (select) {
			selected_widgets.add(e)
			e.select_widget(focus)
		} else {
			selected_widgets.delete(e)
			e.unselect_widget(focus)
		}
		e.class('widget-selected', select)
		if (fire_changed_event !== false)
			document.fire('selected_widgets_changed', selected_widgets)
	}

	e.property('widget_selected',
		() => selected_widgets.has(e),
		function(v, ...args) { e.set_widget_selected(v, ...args) })

	e.select_widget = function(focus) {

		// make widget unfocusable: the overlay will be focusable instead.
		e.focusable = false

		let overlay = div({class: 'x-widget-selected-overlay', tabindex: 0})
		e.widget_selected_overlay = overlay
		e.add(overlay)

		overlay.on('keydown', function(key) {
			if (key == 'Delete') {
				e.remove_widget()
				return false
			}
		})

		overlay.on('pointerdown', function(ev) {

			if (ev.ctrlKey && ev.shiftKey) {
				if (!overlay.focused)
					overlay.focus()
				if (selected_widgets.size == 1) {
					unselect_all_widgets()
					let p = e.selectable_parent_widget
					if (p)
						p.widget_selected = true
				} else
					e.widget_selected = !e.widget_selected
			} else
				unselect_all_widgets()

			return false

		})

		if (focus !== false)
			overlay.focus()
	}

	e.unselect_widget = function(focus_prev) {

		e.focusable = true

		e.widget_selected_overlay.remove()
		e.widget_selected_overlay = null

		if (focus_prev !== false && selected_widgets.size)
			[...selected_widgets].last.widget_selected_overlay.focus()
	}

	e.remove_widget = function() {
		let p = e.parent_widget
		if (!p) return
		e.widget_selected = false
		p.remove_child_widget(e)
	}

	e.on('pointerdown', function(ev) {

		if (!e.can_select_widget)
			return

		if (ev.ctrlKey && (!e.ctrl_click_used || ev.shiftKey)) {

			// prevent accidentally clicking on the parent of any of the selected widgets.
			for (let e1 of selected_widgets) {
				let p = e1.selectable_parent_widget
				while (p) {
					if (p == e)
						return false
					p = p.selectable_parent_widget
				}
			}

			if (!ev.shiftKey) {
				if (e.can_edit_widget) {
					unselect_all_widgets()
					e.widget_editing = true
					ev.stopPropagation()
					// don't prevent default to let the caret land under the mouse.
				} else
					return false
			} else {
				e.widget_editing = false
				e.widget_selected = true
				return false
			}
		}

	})

	e.on('detach', function() { e.widget_selected = false })

	e.on('click', function(ev) {
		if (e.widget_selected)
			return false // prevent dropdown from opening.
	})

}

// ---------------------------------------------------------------------------
// editable widget mixin
// ---------------------------------------------------------------------------

function editable_widget(e) {

	e.can_edit_widget = true
	e.set_widget_editing = noop

	e.property('widget_editing',
		() => editing_widget == e,
		function(v) {
			v = !!v
			if (e.widget_editing == v) return
			e.class('widget-editing', v)
			if (v) {
				if (editing_widget)
					editing_widget.widget_editing = false
				assert(editing_widget == null)
				e.focusable = false
				editing_widget = e
			} else {
				e.focusable = true
				editing_widget = null
			}
			e.set_widget_editing(v)
		})

	e.on('detach', function() { e.widget_editing = false })

}

// ---------------------------------------------------------------------------
// cssgrid item widget mixin
// ---------------------------------------------------------------------------

function cssgrid_item_widget(e) {

	e.prop('pos_x'  , {style: 'grid-column-start' , type: 'number', default: 1})
	e.prop('pos_y'  , {style: 'grid-row-start'    , type: 'number', default: 1})
	e.prop('span_x' , {style: 'grid-column-end'   , type: 'number', default: 1, style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('span_y' , {style: 'grid-row-end'      , type: 'number', default: 1, style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('align_x', {style: 'justify-self'      , type: 'enum', enum_values: ['start', 'end', 'center', 'stretch'], default: 'center'})
	e.prop('align_y', {style: 'align-self'        , type: 'enum', enum_values: ['start', 'end', 'center', 'stretch'], default: 'center'})

	let select_widget = e.select_widget
	let unselect_widget = e.unselect_widget

	e.select_widget = function(focus) {
		select_widget(focus)
		let p = e.parent_widget
		if (p && p.typename == 'cssgrid') {
			cssgrid_item_widget_editing(e)
			e.cssgrid_item_select_widget()
		}
	}

	e.unselect_widget = function(focus_prev) {
		let p = e.parent_widget
		if (p && p.typename == 'cssgrid')
			e.cssgrid_item_unselect_widget()
		unselect_widget(focus_prev)
	}

}

// ---------------------------------------------------------------------------
// cssgrid item widget editing mixin
// ---------------------------------------------------------------------------

function cssgrid_item_widget_editing(e) {

	function track_bounds() {
		let i = e.pos_x-1
		let j = e.pos_y-1
		return e.parent_widget.cssgrid_track_bounds(i, j, i + e.span_x, j + e.span_y)
	}

	function set_span(axis, i1, i2) {
		if (i1 !== false)
			e['pos_'+axis] = i1+1
		if (i2 !== false)
			e['span_'+axis] = i2 - (i1 !== false ? i1 : e['pos_'+axis]-1)
	}

	function toggle_stretch_for(horiz) {
		let attr = horiz ? 'align_x' : 'align_y'
		let align = e[attr]
		if (align == 'stretch')
			align = e['_'+attr] || 'center'
		else {
			e['_'+attr] = align
			align = 'stretch'
		}
		e[horiz ? 'w' : 'h'] = align == 'stretch' ? 'auto' : null
		e[attr] = align
		return align
	}
	function toggle_stretch(horiz, vert) {
		if (horiz && vert) {
			let stretch_x = e.align_x == 'stretch'
			let stretch_y = e.align_y == 'stretch'
			if (stretch_x != stretch_y) {
				toggle_stretch(!stretch_x, !stretch_y)
			} else {
				toggle_stretch(true, false)
				toggle_stretch(false, true)
			}
		} else if (horiz)
			toggle_stretch_for(true)
		else if (vert)
			toggle_stretch_for(false)
	}

	e.cssgrid_item_select_widget = function() {

		let p = e.parent_widget
		if (!p || p.typename != 'cssgrid')
			return

		p.widget_editing = true

		e.widget_selected_overlay.on('focus', function() {
			p.widget_editing = true
		})

		let span_outline = div({class: 'x-cssgrid-span'},
			div({class: 'x-cssgrid-span-handle', side: 'top'}),
			div({class: 'x-cssgrid-span-handle', side: 'left'}),
			div({class: 'x-cssgrid-span-handle', side: 'right'}),
			div({class: 'x-cssgrid-span-handle', side: 'bottom'}),
		)
		span_outline.on('pointerdown', so_pointerdown)
		p.add(span_outline)

		function update_so() {
			for (let s of ['grid-column-start', 'grid-column-end', 'grid-row-start', 'grid-row-end'])
				span_outline.style[s] = e.style[s]
		}
		update_so()

		function prop_changed(k, v, v0, ev) {
			if (ev.target == e)
				if (k == 'pos_x' || k == 'span_x' || k == 'pos_y' || k == 'span_y')
					update_so()
		}
		e.on('prop_changed', prop_changed)

		// drag-resize item's span outline => change item's grid area ----------

		let drag_mx, drag_my, side

		function resize_span(mx, my) {
			let horiz = side == 'left' || side == 'right'
			let axis = horiz ? 'x' : 'y'
			let second = side == 'right' || side == 'bottom'
			mx = horiz ? mx - drag_mx : my - drag_my
			let i1 = e['pos_'+axis]-1
			let i2 = e['pos_'+axis]-1 + e['span_'+axis]
			let dx = 1/0
			let closest_i
			e.parent_widget.each_cssgrid_line(axis, function(i, x) {
				if (second ? i > i1 : i < i2) {
					if (abs(x - mx) < dx) {
						dx = abs(x - mx)
						closest_i = i
					}
				}
			})
			set_span(axis,
				!second ? closest_i : i1,
				 second ? closest_i : i2
			)
		}

		function so_pointerdown(ev, mx, my) {
			let handle = ev.target.closest('.x-cssgrid-span-handle')
			if (!handle) return
			side = handle.attr('side')

			let [bx1, by1, bx2, by2] = track_bounds()
			let second = side == 'right' || side == 'bottom'
			drag_mx = mx - (second ? bx2 : bx1)
			drag_my = my - (second ? by2 : by1)
			resize_span(mx, my)

			return this.capture_pointer(ev, so_pointermove)
		}

		function so_pointermove(mx, my) {
			resize_span(mx, my)
		}

		function overlay_keydown(key, shift, ctrl) {
			if (key == 'Enter') { // toggle stretch
				toggle_stretch(!shift, !ctrl)
				return false
			}
			if (key == 'ArrowLeft' || key == 'ArrowRight' || key == 'ArrowUp' || key == 'ArrowDown') {
				let horiz = key == 'ArrowLeft' || key == 'ArrowRight'
				let fw = key == 'ArrowRight' || key == 'ArrowDown'
				if (ctrl) { // change alignment
					let attr = horiz ? 'align_x' : 'align_y'
					let align = e[attr]
					if (align == 'stretch')
						align = toggle_stretch(horiz, !horiz)
					let align_indices = {start: 0, center: 1, end: 2}
					let align_map = keys(align_indices)
					align = align_map[align_indices[align] + (fw ? 1 : -1)]
					e[attr] = align
				} else { // resize span or move to diff. span
					let axis = horiz ? 'x' : 'y'
					if (shift) { // resize span
						let i1 = e['pos_'+axis]-1
						let i2 = e['pos_'+axis]-1 + e['span_'+axis]
						let i = max(i1+1, i2 + (fw ? 1 : -1))
						set_span(axis, false, i)
					} else {
						let i = max(0, e['pos_'+axis]-1 + (fw ? 1 : -1))
						set_span(axis, i, i+1)
					}
				}
				return false
			}

		}
		e.widget_selected_overlay.on('keydown', overlay_keydown)

		e.cssgrid_item_unselect_widget = function() {
			e.off('prop_changed', prop_changed)
			e.widget_selected_overlay.off('keydown', overlay_keydown)
			span_outline.remove()
			e.cssgrid_item_unselect_widget = noop

			// exit parent editing if this was the last item to be selected.
			let p = e.parent_widget
			if (p && p.widget_editing) {
				let only_item = true
				for (let e1 of selected_widgets)
					if (e1 != e && e1.parent_widget == p) {
						only_item = false
						break
					}
				if (only_item)
					p.widget_editing = false
			}

		}

	}

}

// ---------------------------------------------------------------------------
// serializable widget mixin
// ---------------------------------------------------------------------------

function serializable_widget(e) {

	e.serialize_fields = function() {
		let t = {typename: e.typename}
		if (e.props)
			for (let prop in e.props) {
				let v = e[prop]
				let def = e.props[prop]
				if (v !== def.default) {
					if (def.serialize)
						v = def.serialize(v)
					else if (isobject(v) && v.serialize)
						v = v.serialize()
					if (v !== undefined)
						t[prop] = v
				}
			}
		return t
	}

	e.serialize = e.serialize_fields

}

// ---------------------------------------------------------------------------
// focusable widget mixin
// ---------------------------------------------------------------------------

function focusable_widget(e, fe) {
	fe = fe || e
	let tabindex
	let focusable = true
	e.get_tabindex = function() {
		return tabindex
	}
	e.set_tabindex = function(i) {
		tabindex = i
		fe.attr('tabindex', focusable ? i : -1)
	}
	e.prop('tabindex', {default: 0})
	e.property('focusable', () => focusable, function(v) {
		v = !!v
		if (v == focusable) return
		focusable = v
		e.set_tabindex(tabindex)
	})
}

// ---------------------------------------------------------------------------
// cell nav
// ---------------------------------------------------------------------------

function cell_nav(field_opt, rs_opt) {

	let field = update({}, field_opt)
	let row = [null]

	let rs = rowset(update({
		fields: [field],
		rows: [row],
		can_change_rows: true,
	}, rs_opt))

	rs.set_val(row, rs.field(0), field.val)

	return {rowset: rs, focused_row: row, is_fake: true}
}

// ---------------------------------------------------------------------------
// val widget mixin
// ---------------------------------------------------------------------------

function val_widget(e) {

	selectable_widget(e)
	cssgrid_item_widget(e)
	serializable_widget(e)

	// nav & col --------------------------------------------------------------

	function rowset_cell_state_changed(row, field, prop, val, ev) {
		cell_state_changed(prop, val, ev)
	}

	function rowset_changed(rs1, rs0) {
		bind_nav(nav, col, rs0, false)
		bind_nav(nav, col, rs1, true)
		e.update()
	}

	function bind_nav(nav, col, rs, on) {
		if (!(nav && col != null && rs)) return
		if (nav.is_fake) {
			rs.bind_user_widget(e, on)
			rs.on('cell_state_changed', rowset_cell_state_changed, on)
		} else {
			nav.on('rowset_changed', rowset_changed)
			nav.on('focused_row_changed', e.update, on)
			nav.on('focused_row_cell_state_changed_for_'+col, cell_state_changed, on)
			rs.on('display_vals_changed_for_'+col, e.update, on)
			rs.on('loaded', rowset_loaded, on)
		}
	}

	e.on('attach', function() {
		bind_nav(nav, col, nav && nav.rowset, true)
		e.update()
	})

	e.on('detach', function() {
		bind_nav(nav, col, nav && nav.rowset, false)
		e.update()
	})

	function set_nav_col(nav0, col0) {
		if (e.attached) {
			bind_nav(nav0, col0, nav0 && nav0.rowset, false)
			bind_nav(nav, col, nav && nav.rowset, true)
		}
		e.update()
	}

	let nav = null
	e.set_nav = function(nav1, nav0) {
		nav = nav1
		set_nav_col(nav0, col)
	}
	e.prop('nav', {store: 'var', private: true})

	e.prop('nav_name', {store: 'var', bind: 'nav'})

	function set_col(col1) {
		let col0 = col
		col = col1
		set_nav_col(nav, col0)
	}
	let col = 0
	e.property('col', () => col, set_col)

	// field & val ------------------------------------------------------------

	function rowset_loaded() {
		e.update()
	}

	let disabled = false
	e.update = function() {
		if (e.attached) {
			e.field = nav && col != null && nav.rowset && nav.rowset.field(col)
			disabled = !e.row || !e.field
			e.class('disabled', disabled)
			e.focusable = !disabled
			cell_state_changed('input_val', e.input_val)
			cell_state_changed('val', e.val)
			cell_state_changed('cell_error', e.error)
			cell_state_changed('cell_modified', e.modified)
		} else {
			e.field = null
		}
	}

	function if_enabled() { if (disabled) return false }
	e.on('pointerdown', if_enabled)
	e.on('pointerup'  , if_enabled)
	e.on('click'      , if_enabled)

	function cell_state_changed(prop, val, ev) {
		if (prop == 'input_val')
			e.update_val(val, ev)
		else if (prop == 'val')
			e.fire('val_changed', val, ev)
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
			e.error_tooltip = tooltip({kind: 'error', target: e,
				check: e.error_tooltip_check})
		}
		if (e.invalid)
			e.error_tooltip.text = err
		e.error_tooltip.update()
	}

	// getters/setters --------------------------------------------------------

	e.to_val = function(v) { return v; }
	e.from_val = function(v) { return v; }

	e.property('row', () => nav && nav.focused_row)

	function get_val() {
		let row = e.row
		return row && e.field ? nav.rowset.val(row, e.field) : null
	}
	e.set_val = function(v, ev) {
		nav.rowset.set_val(e.row, e.field, e.to_val(v), ev)
	}
	e.late_property('val', get_val, e.set_val)

	e.property('input_val', function() {
		let row = e.row
		return row ? e.from_val(nav.rowset.input_val(e.row, e.field)) : null
	})

	e.property('error', function() {
		let row = e.row
		return row ? nav.rowset.cell_error(row, e.field) : undefined
	})

	e.property('modified', function() {
		let row = e.row
		return row ? nav.rowset.cell_modified(row, e.field) : false
	})

	e.display_val = function() {
		let row = e.row
		return row ? nav.rowset.display_val(row, e.field) : ''
	}

}

// ---------------------------------------------------------------------------
// tooltip
// ---------------------------------------------------------------------------

component('x-tooltip', function(e) {

	e.classes = 'x-widget x-tooltip'

	e.text_div = div({class: 'x-tooltip-text'})
	e.pin = div({class: 'x-tooltip-tip'})
	e.add(e.text_div, e.pin)

	e.prop('side'   , {attr: 'side'    , type: 'enum', enum_values: ['top', 'bottom', 'left', 'right', 'inner-top', 'inner-bottom', 'inner-left', 'inner-right', 'inner-center'], default: 'top'})
	e.prop('align'  , {attr: 'align'   , type: 'enum', enum_values: ['center', 'start', 'end'], default: 'center'})
	e.prop('kind'   , {attr: 'kind'    , type: 'enum', enum_values: ['default', 'info', 'error'], default: 'default'})
	e.prop('px'     , {attr: 'px'      , type: 'number', default: 0})
	e.prop('py'     , {attr: 'py'      , type: 'number', default: 0})
	e.prop('timeout', {attr: 'timeout'})

	let target

	e.popup_target_changed = function(target) {
		let visible = !!(!e.check || e.check(target))
		e.class('visible', visible)
	}

	e.update = function() {
		e.popup(target, e.side, e.align, e.px, e.py)
	}

	e.set_side  = e.update
	e.set_align = e.update
	e.set_kind  = e.update
	e.set_px    = e.update
	e.set_py    = e.update

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

	e.late_property('target',
		function()  { return target },
		function(v) { target = v; e.update() }
	)

})

tooltip.reading_speed = 800 // letters-per-minute.

// ---------------------------------------------------------------------------
// button
// ---------------------------------------------------------------------------

component('x-button', function(e) {

	serializable_widget(e)
	selectable_widget(e)
	focusable_widget(e)
	editable_widget(e)
	cssgrid_item_widget(e)

	e.classes = 'x-widget x-button'

	e.icon_div = span({class: 'x-button-icon', style: 'display: none'})
	e.text_div = span({class: 'x-button-text'})
	e.add(e.icon_div, e.text_div)

	e.set_text = function(s) { e.text_div.set(s, 'pre-wrap') }
	e.prop('text', {store: 'var', default: 'OK'})

	e.set_icon = function(v) {
		if (typeof v == 'string')
			e.icon_div.attr('class', 'x-button-icon '+v)
		else
			e.icon_div.set(v)
		e.icon_div.show(!!v)
	}
	e.prop('icon', {store: 'var'})

	e.prop('primary', {attr: 'primary', type: 'bool', default: false})

	e.on('keydown', function keydown(key, shift, ctrl) {
		if (e.widget_editing) {
			if (key == 'Enter') {
				if (ctrl) {
					e.text_div.insert_at_caret('<br>')
					return
				} else {
					e.widget_editing = false
					return false
				}
			}
			return
		}
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

	// widget editing ---------------------------------------------------------

	e.set_widget_editing = function(v) {
		e.text_div.contenteditable = v
		if (!v)
			e.text = e.text_div.innerText
	}

	e.on('pointerdown', function(ev) {
		if (e.widget_editing && ev.target != e.text_div) // prevent :active state
			return this.capture_pointer(ev, noop, function() {
				e.text_div.focus()
				e.text_div.select_all()
			})
	})

	function prevent_bubbling(ev) {
		if (e.widget_editing && !ev.ctrlKey)
			ev.stopPropagation()
	}
	e.text_div.on('pointerdown', prevent_bubbling)
	e.text_div.on('click', prevent_bubbling)

	e.text_div.on('blur', function() {
		e.widget_editing = false
	})

})

// ---------------------------------------------------------------------------
// checkbox
// ---------------------------------------------------------------------------

component('x-checkbox', function(e) {

	focusable_widget(e)
	editable_widget(e)
	val_widget(e)

	e.classes = 'x-widget x-markbox x-checkbox'
	e.prop('align', {attr: 'align', type: 'enum', enum_values: ['left', 'right'], default: 'left'})

	e.checked_val = true
	e.unchecked_val = false

	e.icon_div = span({class: 'x-markbox-icon x-checkbox-icon far fa-square'})
	e.text_div = span({class: 'x-markbox-text x-checkbox-text'})
	e.add(e.icon_div, e.text_div)

	// model

	e.init = function() {
		e.class('center', !!e.center)
	}

	let get_checked = function() {
		return e.val === e.checked_val
	}
	let set_checked = function(v) {
		e.set_val(v ? e.checked_val : e.unchecked_val, {input: e})
	}
	e.late_property('checked', get_checked, set_checked)

	// view

	e.set_text = function(s) { e.text_div.set(s, 'pre-wrap') }
	e.prop('text', {store: 'var', default: 'Check me!'})

	e.update_val = function() {
		let v = e.checked
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

	e.on('pointerdown', function(ev) {
		if (e.widget_editing)
			return
		ev.preventDefault() // prevent accidental selection by double-clicking.
		e.focus()
	})

	e.on('click', function(ev) {
		if (e.widget_editing)
			return
		e.toggle()
		return false
	})

	e.on('keydown', function(key, shift, ctrl) {
		if (e.widget_editing) {
			if (key == 'Escape') {
				e.widget_editing = false
				return false
			}
			if (key == 'Enter') {
				if (ctrl)
					e.text_div.insert_at_caret('<br>')
				else
					e.widget_editing = false
				return false
			}
			return
		}
		if (key == 'Enter' || key == ' ') {
			e.toggle()
			return false
		}
	})

	// widget editing ---------------------------------------------------------

	e.set_widget_editing = function(v) {
		e.text_div.contenteditable = v
		if (!v)
			e.text = e.text_div.innerText
	}

	e.on('pointerdown', function(ev) {
		if (e.widget_editing && ev.target != e.text_div)
			return this.capture_pointer(ev, noop, function() {
				e.text_div.focus()
				e.text_div.select_all()
			})
	})

	function prevent_bubbling(ev) {
		if (e.widget_editing && !ev.ctrlKey)
			ev.stopPropagation()
	}
	e.text_div.on('pointerdown', prevent_bubbling)
	e.text_div.on('click', prevent_bubbling)

	e.text_div.on('blur', function() {
		e.widget_editing = false
	})

})

// ---------------------------------------------------------------------------
// radiogroup
// ---------------------------------------------------------------------------

component('x-radiogroup', function(e) {

	e.classes = 'x-widget x-radiogroup'
	e.prop('align', {attr: 'align', type: 'enum', enum_values: ['left', 'right'], default: 'left'})

	val_widget(e)

	e.items = []

	e.init = function() {
		for (let item of e.items) {
			if (typeof item == 'string' || item instanceof Node)
				item = {text: item}
			let radio_div = span({class: 'x-markbox-icon x-radio-icon far fa-circle'})
			let text_div = span({class: 'x-markbox-text x-radio-text'})
			text_div.set(item.text)
			let idiv = div({class: 'x-widget x-markbox x-radio-item', tabindex: 0},
				radio_div, text_div)
			idiv.attrval('align', e.align)
			idiv.class('center', !!e.center)
			idiv.item = item
			idiv.on('click', idiv_click)
			idiv.on('keydown', idiv_keydown)
			e.add(idiv)
		}
	}

	let sel_item

	e.update_val = function(i) {
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
		e.set_val(item.index, {input: e})
		item.focus()
	}

	function idiv_click() {
		select_item(this)
		return false
	}

	function idiv_keydown(key) {
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

	e.prop('align', {attr: 'align', type: 'enum', enum_values: ['left', 'right'], default: 'left'})
	e.prop('mode', {attr: 'mode', type: 'enum', enum_values: ['default', 'inline'], default: 'default'})

	function update_inner_label() {
		e.class('with-inner-label', !e.nolabel && e.field && !!e.field.text)
	}

	e.class('with-inner-label', true)
	e.prop('nolabel', {attr: 'nolabel', type: 'bool'})
	e.set_nolabel = update_inner_label

	let update = e.update
	e.update = function() {
		update()
		update_inner_label()
		if (e.field)
			e.inner_label_div.set(e.field.text)
	}

}

component('x-input', function(e) {

	val_widget(e)
	input_widget(e)

	e.classes = 'x-widget x-input'

	e.input = H.input({class: 'x-input-value'})
	e.inner_label_div = div({class: 'x-input-inner-label'})
	e.input.set_input_filter() // must be set as first event handler!
	e.add(e.input, e.inner_label_div)

	function update_state(s) {
		e.input.class('empty', s == '')
		e.inner_label_div.class('empty', s == '')
	}

	e.from_text = function(s) { return e.field.from_text(s) }
	e.to_text = function(v) { return e.field ? e.field.to_text(v) : '' }

	e.update_val = function(v, ev) {
		if (ev && ev.input == e && e.typing)
			return
		let s = e.to_text(v)
		e.input.value = s
		update_state(s)
	}

	e.input.on('input', function() {
		e.set_val(e.from_text(e.input.value), {input: e, typing: true})
		update_state(e.input.value)
	})

	e.input.input_filter = function(s) {
		return s.length <= or(e.maxlen, e.field.maxlen)
	}

	// focusing

	focusable_widget(e, e.input)

	focus = e.focus
	e.focus = function() {
		if (e.widget_selected)
			focus.call(e)
		else
			e.input.focus()
	}

	// grid editor protocol ---------------------------------------------------

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

component('x-spin-input', function(e) {

	input.construct(e)
	e.classes = 'x-spin-input'

	e.align = 'right'

	e.prop('button_style'    , {attr: 'button-style'    , type: 'enum', enum_values: ['plus-minus', 'up-down', 'left-right'], default: 'plus-minus'})
	e.prop('button_placement', {attr: 'button-placement', type: 'enum', enum_values: ['each-side', 'left', 'right'], default: 'each-side'})

	e.up   = div({class: 'x-spin-input-button fa'})
	e.down = div({class: 'x-spin-input-button fa'})

	e.field_type = 'number'

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
		e.set_val(e.input_val + (dy / 100), {input: e})
		e.input.select(0, -1)
		return false
	})

	// increment buttons click

	let increment
	function increment_val() {
		if (!increment) return
		let v = e.input_val + increment
		let r = v % or(e.field.multiple_of, 1)
		e.set_val(v - r, {input: e})
		e.input.select(0, -1)
	}
	let increment_timer
	function start_incrementing() {
		increment_val()
		increment_timer = setInterval(increment_val, 100)
	}
	let start_incrementing_timer
	function add_events(button, sign) {
		button.on('pointerdown', function() {
			if (start_incrementing_timer || increment_timer)
				return
			e.input.focus()
			increment = or(e.field.multiple_of, 1) * sign
			increment_val()
			start_incrementing_timer = after(.5, start_incrementing)
			return false
		})
		function pointerup() {
			clearTimeout(start_incrementing_timer)
			clearInterval(increment_timer)
			start_incrementing_timer = null
			increment_timer = null
			increment = 0
		}
		button.on('pointerup', pointerup)
		button.on('pointerleave', pointerup)
	}
	add_events(e.up  , 1)
	add_events(e.down, -1)

})

// ---------------------------------------------------------------------------
// slider
// ---------------------------------------------------------------------------

component('x-slider', function(e) {

	focusable_widget(e)

	e.from = 0
	e.to = 1

	e.classes = 'x-widget x-slider'

	e.val_fill = div({class: 'x-slider-fill x-slider-value-fill'})
	e.range_fill = div({class: 'x-slider-fill x-slider-range-fill'})
	e.input_thumb = div({class: 'x-slider-thumb x-slider-input-thumb'})
	e.val_thumb = div({class: 'x-slider-thumb x-slider-value-thumb'})
	e.add(e.range_fill, e.val_fill, e.val_thumb, e.input_thumb)

	// model

	val_widget(e)

	e.field_type = 'number'

	let update = e.update
	e.update = function() {
		update()
		e.class('animated', e.field && e.field.multiple_of >= 5) // TODO: that's not the point of this.
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
		e.set_val(clamp(v, cmin(), cmax()), ev)
	}

	e.late_property('progress',
		function() {
			return progress_for(e.input_val)
		},
		e.set_progress,
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

	e.update_val = function(v) {
		let input_p = progress_for(v)
		let val_p = progress_for(e.val)
		let diff = input_p != val_p
		update_thumb(e.val_thumb, val_p, diff)
		update_thumb(e.input_thumb, input_p)
		e.val_thumb.class('different', diff)
		e.input_thumb.class('different', diff)
		let p1 = progress_for(cmin())
		let p2 = progress_for(cmax())
		update_fill(e.val_fill, max(p1, 0), min(p2, val_p))
		update_fill(e.range_fill, p1, p2)
	}

	// controller

	e.input_thumb.on('pointerdown', function(ev) {
		e.focus()
		let r = e.input_thumb.rect()
		let hit_x = ev.clientX - (r.x + r.w / 2)
		return this.capture_pointer(ev, function(mx, my) {
			let r = e.rect()
			e.set_progress((mx - r.x - hit_x) / r.w, {input: e})
			return false
		})
	})

	e.on('pointerdown', function(ev) {
		let r = e.rect()
		e.set_progress((ev.clientX - r.x) / r.w, {input: e})
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

	e.inspect_fields = [

		{name: 'from', type: 'number'},
		{name: 'to', type: 'number'},
		{name: 'multiple_of', type: 'number'},

		{name: 'grid_area'},
		{name: 'tabIndex', type: 'number'},

	]

})

// ---------------------------------------------------------------------------
// dropdown
// ---------------------------------------------------------------------------

component('x-dropdown', function(e) {

	val_widget(e)
	input_widget(e)
	focusable_widget(e)

	e.classes = 'x-widget x-input x-dropdown'

	e.val_div = span({class: 'x-input-value x-dropdown-value'})
	e.button = span({class: 'x-dropdown-button fa fa-caret-down'})
	e.inner_label_div = div({class: 'x-input-inner-label x-dropdown-inner-label'})
	e.add(e.val_div, e.button, e.inner_label_div)

	e.init = function() {
		e.picker.on('val_picked', picker_val_picked)
		e.picker.on('keydown', picker_keydown)
	}

	function bind_document(on) {
		document.on('pointerdown', document_pointerdown, on)
		document.on('rightpointerdown', document_pointerdown, on)
		document.on('stopped_event', document_stopped_event, on)
	}

	e.on('attach', function() {
		bind_document(true)
		e.picker.hide()
		e.picker.popup(e, 'bottom', e.align)
	})

	e.on('detach', function() {
		e.close()
		bind_document(false)
	})

	// val updating

	e.update_val = function(v, ev) {
		let text = e.display_val()
		let empty = text === ''
		e.val_div.class('empty', empty)
		e.val_div.class('null', v == null)
		e.inner_label_div.class('empty', empty)
		e.val_div.set(empty ? H('&nbsp;') : text)
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
				e.cancel_val = e.input_val
				e.picker.min_w = e.rect().w
				e.picker.show()
				e.fire('opened')
			} else {
				e.cancel_val = null
				e.picker.hide()
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
			e.set_val(e.cancel_val)
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

	function picker_val_picked() {
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
				e.picker.pick_near_val(key == 'ArrowDown' ? 1 : -1, {input: e})
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
		e.picker.pick_near_val(dy / 100, {input: e})
		return false
	})

	// clicking outside the picker closes the picker.
	function document_pointerdown(ev) {
		if (e.contains(ev.target)) // clicked inside the dropdown.
			return
		if (e.picker.contains(ev.target)) // clicked inside the picker.
			return
		e.cancel()
	}

	// clicking outside the picker closes the picker, even if the click did something.
	function document_stopped_event(ev) {
		if (ev.type.ends('pointerdown'))
			document_pointerdown(ev)
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

component('x-menu', function(e) {

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
		tr.on('pointerup'   , item_pointerup)
		tr.on('pointerenter', item_pointerenter)
		return tr
	}

	function create_heading(item) {
		let td = H.td({class: 'x-menu-heading', colspan: 5})
		td.set(item.heading)
		let tr = H.tr({}, td)
		tr.focusable = false
		tr.on('pointerenter', separator_pointerenter)
		return tr
	}

	function create_separator() {
		let td = H.td({class: 'x-menu-separator', colspan: 5}, H.hr())
		let tr = H.tr({}, td)
		tr.focusable = false
		tr.on('pointerenter', separator_pointerenter)
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
		document.on('pointerdown', document_pointerdown, on)
		document.on('rightpointerdown', document_pointerdown, on)
		document.on('stopped_event', document_stopped_event, on)
	}

	e.popup_target_attached = function(target) {
		bind_document(true)
	}

	e.popup_target_detached = function(target) {
		bind_document(false)
	}

	function document_pointerdown(ev) {
		if (e.contains(ev.target)) // clicked inside the menu.
			return
		e.close()
	}

	// clicking outside the menu closes the menu, even if the click did something.
	function document_stopped_event(ev) {
		if (e.contains(ev.target)) // clicked inside the menu.
			return
		if (ev.type.ends('pointerdown'))
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

	function item_pointerup() {
		click_item(this)
		return false
	}

	function item_pointerenter(ev) {
		if (this.submenu_table)
			return // mouse entered on the submenu.
		this.parent.focus()
		select_item(this.parent, this)
		show_submenu(this)
	}

	function separator_pointerenter(ev) {
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
// widget placeholder
// ---------------------------------------------------------------------------

component('x-widget-placeholder', function(e) {

	serializable_widget(e)
	selectable_widget(e)
	cssgrid_item_widget(e)

	e.align_x = 'stretch'
	e.align_y = 'stretch'

	e.classes = 'x-widget x-widget-placeholder'

	let stretched_widgets = [
		['SP', 'split'],
		['CG', 'cssgrid'],
		['PL', 'pagelist', true],
		['L', 'listbox'],
		['G', 'grid', true],
	]

	let form_widgets = [
		['RT', 'richtext'],
		['I' , 'input'],
		['SI', 'spin_input'],
		['CB', 'checkbox'],
		['RG', 'radiogroup'],
		['SL', 'slider'],
		['LD', 'list_dropdown'],
		['GD', 'grid_dropdown'],
		['DD', 'date_dropdown', true],
		['B', 'button'],
	]

	function replace_with_widget() {
		let widget = component.create({typename: this.typename})
		let pe = e.parent_widget
		if (pe)
			pe.replace_widget(e, widget)
		else {
			let pe = e.parent
			pe.replace(e, widget)
			root_widget = widget
			pe.fire('widget_tree_changed')
		}
		widget.focus()
	}

	function create_widget_buttons(widgets) {
		e.clear()
		let i = 1
		for (let [s, typename, sep] of widgets) {
			let btn = button({text: s, title: typename, pos_x: i++})
			btn.class('x-widget-placeholder-button')
			if (sep)
				btn.style['margin-right'] = '.5em'
			e.add(btn)
			btn.typename = typename
			btn.action = replace_with_widget
		}
	}

	e.on('attach', function() {
		widgets = stretched_widgets
		let pe = e.parent_widget
		if (pe && pe.accepts_form_widgets)
			widgets = [].concat(widgets, form_widgets)
		create_widget_buttons(widgets)
	})

})

// ---------------------------------------------------------------------------
// pagelist
// ---------------------------------------------------------------------------

component('x-pagelist', function(e) {

	selectable_widget(e)
	editable_widget(e)
	cssgrid_item_widget(e)

	e.align_x = 'stretch'
	e.align_y = 'stretch'
	serializable_widget(e)
	e.classes = 'x-widget x-pagelist'

	e.prop('tabs', {attr: 'tabs', type: 'enum', enum_values: ['above', 'below'], default: 'above'})

	e.header = div({class: 'x-pagelist-header'})
	e.content = div({class: 'x-pagelist-content'})
	e.add_button = div({class: 'x-pagelist-item x-pagelist-add-button fa fa-plus', tabindex: 0})
	e.add(e.header, e.content)

	function add_item(item) {
		if (typeof item == 'string' || item instanceof Node)
			item = {text: item}
		item.page = component.create(item.page || {typename: 'widget_placeholder'})
		let xbutton = div({class: 'x-pagelist-xbutton fa fa-times'})
		xbutton.hide()
		let tdiv = div({class: 'x-pagelist-text'})
		let idiv = div({class: 'x-pagelist-item', tabindex: 0}, tdiv, xbutton)
		idiv.text_div = tdiv
		idiv.xbutton = xbutton
		tdiv.set(item.text, 'pre-wrap')
		tdiv.title = item.text
		idiv.on('pointerdown', idiv_pointerdown)
		idiv.on('dblclick'   , idiv_dblclick)
		idiv.on('keydown'    , idiv_keydown)
		tdiv.on('input'      , tdiv_input)
		tdiv.on('blur'       , tdiv_blur)
		xbutton.on('pointerdown', xbutton_pointerdown)
		idiv.item = item
		item.idiv = idiv
		e.header.add(idiv)
		e.items.push(item)
	}

	e.init = function() {
		let items = e.items
		e.items = []
		if (items)
			for (let item of items)
				add_item(item)
		e.header.add(e.add_button)
		e.selection_bar = div({class: 'x-pagelist-selection-bar'})
		e.header.add(e.selection_bar)
		e.update()
	}

	e.serialize = function() {
		let t = e.serialize_fields()
		t.items = []
		for (let item of e.items) {
			let sitem = {text: item.text}
			sitem.page = item.page.serialize()
			t.items.push(sitem)
		}
		return t
	}

	function update_item(idiv, select) {
		idiv.xbutton.show(select && (e.can_remove_items || e.widget_editing))
		idiv.text_div.contenteditable = select && (e.widget_editing || e.renaming)
	}

	function update_selection_bar() {
		let idiv = e.selected_item
		e.selection_bar.x = idiv ? idiv.ox : 0
		e.selection_bar.w = idiv ? idiv.rect().w   : 0
		e.selection_bar.show(!!idiv)
	}

	e.update = function() {
		update_selection_bar()
		let idiv = e.selected_item
		if (idiv)
			update_item(idiv, true)
		e.add_button.show(e.can_add_items || e.widget_editing)
	}

	e.set_can_add_items    = update
	e.set_can_remove_items = update
	e.set_can_rename_items = update

	e.prop('can_rename_items', {store: 'var', type: 'bool', default: false})
	e.prop('can_add_items'   , {store: 'var', type: 'bool', default: false})
	e.prop('can_remove_items', {store: 'var', type: 'bool', default: false})
	e.prop('can_move_items'  , {store: 'var', type: 'bool', default: true})

	e.on('attach', function() {
		e.selected_index = or(e.selected_index, 0)
	})

	function select_item(idiv, focus_page, enter_editing) {
		if (e.selected_item != idiv) {
			if (e.selected_item) {
				e.selected_item.class('selected', false)
				e.fire('close', e.selected_item.index)
				e.content.clear()
				update_item(e.selected_item, false)
			}
			e.selected_item = idiv
			e.update()
			if (idiv) {
				idiv.class('selected', true)
				e.fire('open', idiv.index)
				let page = idiv.item.page
				e.content.set(page)
			}
		}
		if (enter_editing) {
			e.widget_editing = true
			return
		}
		if (!e.widget_editing && focus_page != false) {
			let first_focusable = e.content.focusables()[0]
			if (first_focusable)
				first_focusable.focus()
		}
	}

	e.late_property('selected_index',
		function() {
			return e.selected_item ? e.selected_item.index : null
		},
		function(i) {
			let idiv = i != null ? e.header.at[clamp(i, 0, e.items.length-1)] : null
			select_item(idiv)
		}
	)

	// drag-move tabs ---------------------------------------------------------

	live_move_mixin(e)

	e.set_movable_element_pos = function(i, x) {
		let idiv = e.items[i].idiv
		idiv.x = x - idiv._offset_x
	}

	e.movable_element_size = function(i) {
		return e.items[i].idiv.rect().w
	}

	let dragging, drag_mx

	function idiv_pointerdown(ev, mx, my) {
		if (this.text_div.contenteditable && !ev.ctrlKey) {
			ev.stopPropagation()
			return
		}
		select_item(this)
		if (ev.ctrlKey)
			return // bubble-up to enter editing mode.
		this.focus()
		return this.capture_pointer(ev, idiv_pointermove, idiv_pointerup)
	}

	function idiv_pointermove(mx, my, ev, down_mx, down_my) {
		if (!dragging) {
			dragging = e.can_move_items
				&& abs(down_mx - mx) > 4 || abs(down_my - my) > 4
			if (dragging) {
				for (let item of e.items)
					item.idiv._offset_x = item.idiv.ox
				e.move_element_start(this.index, 1, 0, e.items.length)
				drag_mx = down_mx - this.ox
				e.class('moving', true)
				this.class('moving', true)
				update_selection_bar()
			}
		} else {
			e.move_element_update(mx - drag_mx)
			e.update()
		}
	}

	function idiv_pointerup() {
		if (dragging) {
			let over_i = e.move_element_stop()
			let insert_i = over_i - (over_i > this.index ? 1 : 0)
			e.items.remove(this.index)
			e.items.insert(insert_i, this.item)
			this.remove()
			e.header.insert(insert_i, this)
			for (let item of e.items)
				item.idiv.x = null
			update_selection_bar()
			e.class('moving', false)
			this.class('moving', false)
			dragging = false
		}
		select_item(this, true)
	}

	// key bindings -----------------------------------------------------------

	function set_renaming(renaming) {
		e.renaming = !!renaming
		e.selected_item.text_div.contenteditable = e.renaming
	}

	function idiv_keydown(key, shift, ctrl) {
		if (key == 'F2' && e.can_rename_items) {
			set_renaming(!e.renaming)
			return false
		}
		if (e.widget_editing || e.renaming) {
			if (key == 'Enter') {
				if (ctrl)
					this.text_div.insert_at_caret('<br>')
				else
					e.widget_editing = false
				return false
			}
		}
		if (e.renaming) {
			if (key == 'Enter' || key == 'Escape') {
				set_renaming(false)
				return false
			}
		}
		if (!e.widget_editing && !e.renaming) {
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

	e.set_widget_editing = function(v) {
		if (!v)
			tdiv_input()
		e.update()
	}

	e.add_button.on('click', function() {
		if (e.selected_item == this)
			return
		let item = {text: 'New'}
		e.selection_bar.remove()
		e.add_button.remove()
		add_item(item)
		e.header.add(e.selection_bar)
		e.header.add(e.add_button)
		e.fire('widget_tree_changed')
		return false
	})

	function idiv_dblclick() {
		if (e.renaming || !e.can_rename_items)
			return
		set_renaming(true)
		this.focus()
		return false
	}

	function tdiv_input() {
		e.items[e.selected_index].text = e.selected_item.text_div.innerText
		e.update()
	}

	function tdiv_blur() {
		e.widget_editing = false
	}

	function xbutton_pointerdown() {
		let idiv = this.parent
		select_item(null)
		idiv.remove()
		e.items.remove_value(idiv.item)
		e.fire('widget_tree_changed')
		return false
	}

	// xmodule protocol -------------------------------------------------------

	e.child_widgets = function() {
		let widgets = []
		for (let item of e.items)
			widgets.push(item.page)
		return widgets
	}

	e.replace_widget = function(old_widget, new_widget) {
		for (let item of e.items)
			if (item.page == old_widget) {
				old_widget.parent.replace(old_widget, new_widget)
				item.page = new_widget
				e.fire('widget_tree_changed')
				break
			}
	}

})

// ---------------------------------------------------------------------------
// split-view
// ---------------------------------------------------------------------------

component('x-split', function(e) {

	serializable_widget(e)
	selectable_widget(e)
	cssgrid_item_widget(e)

	e.align_x = 'stretch'
	e.align_y = 'stretch'
	e.classes = 'x-widget x-split'

	e.pane1 = div({class: 'x-split-pane'})
	e.pane2 = div({class: 'x-split-pane'})
	e.sizer = div({class: 'x-split-sizer'})
	e.add(e.pane1, e.sizer, e.pane2)

	let horiz, left

	function update_view() {
		horiz = e.orientation == 'horizontal'
		left = e.fixed_side == 'first'
		e.fixed_pane = left ? e.pane1 : e.pane2
		e.auto_pane  = left ? e.pane2 : e.pane1
		e.fixed_pane.class('x-split-pane-fixed')
		e.fixed_pane.class('x-split-pane-auto', false)
		e.auto_pane.class('x-split-pane-auto')
		e.auto_pane.class('x-split-pane-fixed', false)
		e.class('resizeable', e.resizeable)
		e.sizer.show(e.resizeable)
		e.fixed_pane[horiz ? 'h' : 'w'] = null
		e.fixed_pane[horiz ? 'w' : 'h'] = e.fixed_size
		e.auto_pane.w = null
		e.auto_pane.h = null
		e.fixed_pane[horiz ? 'min_h' : 'min_w'] = null
		e.fixed_pane[horiz ? 'min_w' : 'min_h'] = e.min_size
		e.auto_pane.min_w = null
		e.auto_pane.min_h = null
	}

	function update_size() {
		update_view()
		e.fire('layout_changed')
	}

	e.set_orientation = update_view
	e.set_fixed_side = update_view
	e.set_resizeable = update_view
	e.set_fixed_size = update_size
	e.set_min_size = update_size

	e.prop('orientation', {attr: 'orientation', type: 'enum', enum_values: ['horizontal', 'vertical'], default: 'horizontal', noinit: true})
	e.prop('fixed_side' , {attr: 'fixed-side' , type: 'enum', enum_values: ['first', 'second'], default: 'first', noinit: true})
	e.prop('resizeable' , {attr: 'resizeable' , type: 'bool', default: true, noinit: true})
	e.prop('fixed_size' , {store: 'var', type: 'number', default: 200, noinit: true})
	e.prop('min_size'   , {store: 'var', type: 'number', default:   0, noinit: true})

	e.init = function() {
		e[1] = component.create(or(e[1], widget_placeholder()))
		e[2] = component.create(or(e[2], widget_placeholder()))
		e.pane1.set(e[1])
		e.pane2.set(e[2])
		update_view()
	}

	// resizing ---------------------------------------------------------------

	let hit, hit_x, mx0, w0, resizing, resist

	e.on('pointermove', function(rmx, rmy) {
		if (resizing) {

			let mx = horiz ? rmx : rmy
			let w
			if (left) {
				let fpx1 = e.fixed_pane.rect()[horiz ? 'x' : 'y']
				w = mx - (fpx1 + hit_x)
			} else {
				let ex2 = e.rect()[horiz ? 'x2' : 'y2']
				let sw = e.sizer.rect()[horiz ? 'w' : 'h']
				w = ex2 - mx + hit_x - sw
			}

			resist = resist && abs(mx - mx0) < 20
			if (resist)
				w = w0 + (w - w0) * .2 // show resistance

			if (!e.fixed_pane.hasclass('collapsed')) {
				if (w < min(max(e.min_size, 20), 30) - 5)
					e.fixed_pane.class('collapsed', true)
			} else {
				if (w > max(e.min_size, 30))
					e.fixed_pane.class('collapsed', false)
			}

			w = max(w, e.min_size)
			if (e.fixed_pane.hasclass('collapsed'))
				w = 0

			e.fixed_size = round(w)
			e.tooltip.text = round(w)

			return false

		} else {

			// hit-test for split resizing.
			hit = false
			if (e.rect().contains(rmx, rmy)) {
				// ^^ mouse is not over some scrollbar.
				let mx = horiz ? rmx : rmy
				let sr = e.sizer.rect()
				let sx1 = horiz ? sr.x1 : sr.y1
				let sx2 = horiz ? sr.x2 : sr.y2
				w0 = e.fixed_pane.rect()[horiz ? 'w' : 'h']
				hit_x = mx - sx1
				hit = abs(hit_x - (sx2 - sx1) / 2) <= 5
				resist = true
				mx0 = mx
			}
			e.class('resize', hit)

			if (hit)
				return false

		}
	})

	e.on('pointerdown', function(ev) {
		if (!hit)
			return

		e.tooltip = e.tooltip || tooltip()
		e.tooltip.side = horiz ? (left ? 'right' : 'left') : (left ? 'bottom' : 'top')
		e.tooltip.target = e.sizer
		e.tooltip.text = e.fixed_size

		resizing = true
		e.class('resizing')

		return 'capture'
	})

	e.on('pointerup', function() {
		if (!resizing)
			return

		e.class('resizing', false)
		resizing = false

		if (resist) // reset width
			e.fixed_size = w0

		if (e.tooltip)
			e.tooltip.target = false

		return false
	})

	// xmodule protocol -------------------------------------------------------

	e.child_widgets = function() {
		return [e[1], e[2]]
	}

	function widget_index(ce) {
		return e[1] == ce && 1 || e[2] == ce && 2 || null
	}

	e.replace_widget = function(old_widget, new_widget) {
		e[widget_index(old_widget)] = new_widget
		old_widget.parent.replace(old_widget, new_widget)
		update_view()
		e.fire('widget_tree_changed')
	}

	e.serialize = function() {
		let t = e.serialize_fields()
		t[1] = e[1].serialize()
		t[2] = e[2].serialize()
		return t
	}

})

function hsplit(...options) { return split(...options) }
function vsplit(...options) { return split(update({orientation: 'vertical'}, ...options)) }

// ---------------------------------------------------------------------------
// toaster
// ---------------------------------------------------------------------------

component('x-toaster', function(e) {

	e.classes = 'x-widget x-toaster'

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
			py += t.rect().h + e.spacing
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

	e.post = function(text, kind, timeout) {
		let t = tooltip({
			classes: 'x-toaster-message',
			kind: kind,
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

	e.on('detach', function() {
		e.close_all()
	})

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

component('x-action-band', function(e) {

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

component('x-dialog', function(e) {

	focusable_widget(e)

	e.classes = 'x-widget x-dialog'

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

component('x-toolbox', function(e) {

	focusable_widget(e)

	e.classes = 'x-widget x-toolbox'

	e.xbutton = div({class: 'x-toolbox-xbutton fa fa-times'})
	e.title_div = div({class: 'x-toolbox-title'})
	e.titlebar = div({class: 'x-toolbox-titlebar'}, e.title_div, e.xbutton)
	e.add(e.titlebar)

	e.init = function() {
		e.title_div.set(e.title)
		e.title = ''

		e.content_div = div({class: 'x-toolbox-content'})
		e.content_div.set(e.content)
		e.add(e.content_div)

		e.hide()
		document.body.add(e)
	}

	e.titlebar.on('pointerdown', function(ev, mx, my) {
		e.focus()

		let first_focusable = e.content_div.focusables()[0]
		if (first_focusable)
			first_focusable.focus()

		if (ev.target == e.xbutton)
			return
		let r = e.rect()
		let drag_x = mx - r.x
		let drag_y = my - r.y
		return this.capture_pointer(ev, function(mx, my) {
			let r = this.rect()
			e.x = clamp(0, mx - drag_x, window.innerWidth  - r.w)
			e.y = clamp(0, my - drag_y, window.innerHeight - r.h)
		})
	})

	e.xbutton.on('pointerup', function() {
		e.hide()
		return false
	})

	e.on('attr_changed', function() {
		e.fire('layout_changed')
	})

})

// ---------------------------------------------------------------------------
// richtext
// ---------------------------------------------------------------------------

component('x-richtext', function(e) {

	serializable_widget(e)
	selectable_widget(e)
	editable_widget(e)
	cssgrid_item_widget(e)

	e.classes = 'x-widget x-richtext'
	e.align_x = 'stretch'
	e.align_y = 'stretch'

	e.content_div = div({class: 'x-richedit-content'}, tag('slot', {}))
	e.attachShadow({mode: 'open'}).appendChild(e.content_div)

	// content property

	e.get_content = function()  { return e.content_div.html }
	e.set_content = function(s) { e.content_div.html = s }
	e.prop('content')

	// widget editing ---------------------------------------------------------

	e.set_widget_editing = function(v) {
		if (!v) return
		richtext_widget_editing(e)
		e.set_widget_editing(true)
	}

})

// ---------------------------------------------------------------------------
// richedit widget editing mixin
// ---------------------------------------------------------------------------

{

let exec = (command, value = null) => document.execCommand(command, false, value)
let cstate = (command) => document.queryCommandState(command)

let actions = {
	bold: {
		//icon: '<b>B</b>',
		icon_class: 'fa fa-bold',
		result: () => exec('bold'),
		state: () => cstate('bold'),
		title: 'Bold (Ctrl+B)',
	},
	italic: {
		//icon: '<i>I</i>',
		icon_class: 'fa fa-italic',
		result: () => exec('italic'),
		state: () => cstate('italic'),
		title: 'Italic (Ctrl+I)',
	},
	underline: {
		//icon: '<u>U</u>',
		icon_class: 'fa fa-underline',
		result: () => exec('underline'),
		state: () => cstate('underline'),
		title: 'Underline (Ctrl+U)',
	},
	code: {
		//icon: '&lt/&gt',
		icon_class: 'fa fa-code',
		result: () => exec('formatBlock', '<pre>'),
		title: 'Code',
	},
	heading1: {
		icon: '<b>H<sub>1</sub></b>',
		result: () => exec('formatBlock', '<h1>'),
		title: 'Heading 1',
	},
	heading2: {
		icon: '<b>H<sub>2</sub></b>',
		result: () => exec('formatBlock', '<h2>'),
		title: 'Heading 2',
	},
	line: {
		icon: '&#8213',
		result: () => exec('insertHorizontalRule'),
		title: 'Horizontal Line',
	},
	link: {
		//icon: '&#128279',
		icon_class: 'fa fa-link',
		result: function() {
			let url = window.prompt('Enter the link URL')
			if (url) exec('createLink', url)
		},
		title: 'Link',
	},
	olist: {
		//icon: '&#35',
		icon_class: 'fa fa-list-ol',
		result: () => exec('insertOrderedList'),
		title: 'Ordered List',
	},
	ulist: {
		//icon: '&#8226',
		icon_class: 'fa fa-list-ul',
		result: () => exec('insertUnorderedList'),
		title: 'Unordered List',
	},
	paragraph: {
		//icon: '&#182',
		icon_class: 'fa fa-paragraph',
		result: () => exec('formatBlock', '<p>'),
		title: 'Paragraph',
	},
	quote: {
		//icon: '&#8220 &#8221',
		icon_class: 'fa fa-quote-left',
		result: () => exec('formatBlock', '<blockquote>'),
		title: 'Quote',
	},
	strikethrough: {
		//icon: '<strike>S</strike>',
		icon_class: 'fa fa-strikethrough',
		result: () => exec('strikeThrough'),
		state: () => cstate('strikeThrough'),
		title: 'Strike-through',
	},
}

function richtext_widget_editing(e) {

	let button_pressed
	function press_button() { button_pressed = true }

	e.actionbar = div({class: 'x-richtext-actionbar'})
	for (let k in actions) {
		let action = actions[k]
		let button = tag('button', {class: 'x-richtext-button', title: action.title})
		button.html = action.icon || ''
		button.classes = action.icon_class
		button.on('pointerdown', press_button)
		button.on('click', function() {
			button_pressed = false
			if (action.result())
				e.content_div.focus()
			return false
		})
		if (action.state) {
			let update_button = function() {
				button.class('x-richtext-button-selected', action.state())
			}
			e.content_div.on('keyup', update_button)
			e.content_div.on('pointerup', update_button)
			button.on('click', update_button)
		}
		e.actionbar.add(button)
	}
	e.actionbar.popup(e, 'top', 'left')

	e.content_div.on('input', function(ev) {
		let e1 = ev.target.first
		if (e1 && e1.nodeType == 3)
			exec('formatBlock', '<p>')
		else if (e.content_div.html == '<br>')
			e.content_div.html = ''
	})

	e.content_div.on('keydown', function(ev) {
		if (ev.key === 'Enter')
			if (document.queryCommandValue('formatBlock') == 'blockquote')
				after(0, function() { exec('formatBlock', '<p>') })
			else if (document.queryCommandValue('formatBlock') == 'pre')
				after(0, function() { exec('formatBlock', '<br>') })
	})

	e.content_div.on('pointerdown', function(ev) {
		if (!ev.ctrlKey)
			ev.stopPropagation() // prevent exit editing.
	})

	e.actionbar.on('pointerdown', function(ev) {
		ev.stopPropagation() // prevent exit editing.
	})

	e.set_widget_editing = function(v) {
		e.content_div.contentEditable = v
		e.actionbar.show(v)
	}

	e.content_div.on('blur', function() {
		if (!button_pressed)
			e.widget_editing = false
	})

}

}

