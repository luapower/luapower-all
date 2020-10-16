
/* ---------------------------------------------------------------------------
// val widget mixin
// ---------------------------------------------------------------------------
publishes:
	e.col
	e.field
	e.val
	e.input_val
	e.error
	e.modified
	e.set_val(v, ev)
	e.reset_val(v, ev)
	e.display_val()
implements:
	e.do_update([opt])
calls:
	e.do_update_val(val, ev)
	e.do_update_error(err, ev)
	e.do_error_tooltip_check()
	e.to_val(v) -> v
	e.from_val(v) -> v
--------------------------------------------------------------------------- */

function val_widget(e, enabled_without_nav) {

	selectable_widget(e)
	contained_widget(e)
	serializable_widget(e)

	// nav dynamic binding ----------------------------------------------------

	function bind_field(on) {
		let field0 = e.field
		let field1 = on && e.nav && e.nav.all_fields[e.col] || null
		if (field0 == field1)
			return
		if (field0)
			e.fire('bind_field', false)
		e.field = field1
		if (field1)
			e.fire('bind_field', true)
	}

	function val_changed() {
		bind_field(true)
		e.update()
	}

	function nav_reset() {
		bind_field(true)
		e.update()
	}

	function label_changed() {
		e.update()
	}

	function cell_state_changed(field, key, val, ev) {
		if (e.updating)
			return
		if (key == 'input_val')
			e.do_update_val(val, ev)
		else if (key == 'val')
			e.fire('val_changed', val, ev)
		else if (key == 'error') {
			e.invalid = val != null
			e.class('invalid', e.invalid)
			e.do_update_error(val, ev)
		} else if (key == 'modified')
			e.class('modified', val)
	}

	function bind_nav(nav, col, on) {
		if (!e.attached)
			return
		if (!(nav && col != null))
			return
		nav.on('focused_row_changed', val_changed, on)
		nav.on('focused_row_cell_state_changed_for_'+col, cell_state_changed, on)
		nav.on('display_vals_changed_for_'+col, val_changed, on)
		nav.on('reset', nav_reset, on)
		nav.on('col_text_changed_for_'+col, label_changed, on)
		bind_field(on)
	}

	let field_opt
	e.on('bind', function(on) {
		if (on && e.field && !e.owns_field) {
			// `field` option enables standalone mode.
			field_opt = e.field
			e.owns_field = true
		}
		if (e.owns_field) {
			if (on) {
				let nav = global_val_nav()
				let field = nav.add_field(field_opt)
				if (initial_val !== undefined)
					nav.reset_cell_val(nav.all_rows[0], field, initial_val, {validate: true})
				initial_val = undefined
				e.nav = nav
				e.col = field.name
			} else {
				let nav = e.nav
				let field = e.field
				e.nav = null
				e.col = null
				nav.remove_field(field)
			}
		} else {
			bind_nav(e.nav, e.col, on)
		}
	})

	function set_nav_col(nav1, nav0, col1, col0) {
		bind_nav(nav0, col0, false)
		bind_nav(nav1, col1, true)
		e.update()
	}

	e.set_nav = function(nav1, nav0) {
		assert(nav1 != e)
		set_nav_col(nav1, nav0, e.col, e.col)
	}
	e.prop('nav', {store: 'var', private: true})
	e.prop('nav_gid' , {store: 'var', bind_gid: 'nav', type: 'nav'})

	e.set_col = function(col1, col0) {
		set_nav_col(e.nav, e.nav, col1, col0)
	}
	e.prop('col', {store: 'var', type: 'col', col_nav: () => e.nav})

	// model ------------------------------------------------------------------

	e.to_val = function(v) { return v; }
	e.from_val = function(v) { return v; }

	e.property('row', () => e.nav && e.nav.focused_row)

	function get_val() {
		let row = e.row
		return row && e.field ? e.nav.cell_val(row, e.field) : null
	}
	let initial_val
	e.set_val = function(v, ev) {
		v = e.to_val(v)
		if (v === undefined)
			v = null
		if (e.nav && e.field)
			e.nav.set_cell_val(e.row, e.field, v, ev)
		else
			initial_val = v
	}
	e.property('val', get_val, e.set_val)

	e.reset_val = function(v, ev) {
		v = e.to_val(v)
		if (v === undefined)
			v = null
		if (e.row && e.field)
			e.nav.reset_cell_val(e.row, e.field, v, ev)
	}

	e.property('input_val', function() {
		let row = e.row
		return row && e.field ? e.from_val(e.nav.cell_input_val(e.row, e.field)) : null
	})

	e.property('error', function() {
		let row = e.row
		return row && e.field ? e.nav.cell_error(row, e.field) : undefined
	})

	e.property('modified', function() {
		let row = e.row
		return row && e.field ? e.nav.cell_modified(row, e.field) : false
	})

	e.display_val = function() {
		if (!e.field)
			return 'no field'
		let row = e.row
		if (!row)
			return 'no row'
		return e.nav.cell_display_val(row, e.field)
	}

	// view -------------------------------------------------------------------

	let enabled = true

	e.do_update = function() {
		enabled = !!(enabled_without_nav || (e.row && e.field))
		e.class('disabled', !enabled)
		e.focusable = enabled
		cell_state_changed(e.field, 'input_val', e.input_val)
		cell_state_changed(e.field, 'val', e.val)
		cell_state_changed(e.field, 'error', e.error)
		cell_state_changed(e.field, 'modified', e.modified)
	}

	{
		let prevent_if_disabled = function() {
			if (!enabled) return false
		}
		e.on('pointerdown', prevent_if_disabled)
		e.on('pointerup'  , prevent_if_disabled)
		e.on('click'      , prevent_if_disabled)
	}

	e.do_error_tooltip_check = function() {
		return e.invalid && !e.hasclass('picker')
			&& (e.hasfocus || e.hovered)
	}

	e.do_update_error = function(err) {
		if (!e.error_tooltip) {
			if (!e.invalid)
				return // don't create it until needed.
			e.error_tooltip = tooltip({kind: 'error', target: e,
				check: e.do_error_tooltip_check})
		}
		if (e.invalid)
			e.error_tooltip.text = err
		e.error_tooltip.update()
	}

}

// ---------------------------------------------------------------------------
// checkbox
// ---------------------------------------------------------------------------

component('x-checkbox', function(e) {

	focusable_widget(e)
	editable_widget(e)
	val_widget(e)

	e.class('x-markbox')

	e.prop('align', {store: 'attr', type: 'enum', enum_values: ['left', 'right'], default: 'left'})

	e.checked_val = true
	e.unchecked_val = false

	e.icon_div = span({class: 'x-markbox-icon x-checkbox-icon far fa-square'})
	e.text_div = span({class: 'x-markbox-text x-checkbox-text'})
	e.add(e.icon_div, e.text_div)

	// model

	e.get_checked = function() {
		return e.val === e.checked_val
	}
	e.set_checked = function(v, ev) {
		e.set_val(v ? e.checked_val : e.unchecked_val, ev)
	}
	e.prop('checked', {private: true})

	// view

	e.set_text = function(s) { e.text_div.set(s, 'pre-wrap') }
	e.prop('text', {store: 'var', default: 'Check me!', slot: 'lang'})

	e.do_update_val = function() {
		let v = e.checked
		e.class('checked', v)
		e.icon_div.class('fa', v)
		e.icon_div.class('fa-check-square', v)
		e.icon_div.class('far', !v)
		e.icon_div.class('fa-square', !v)
	}

	// controller

	e.toggle = function(ev) {
		e.set_checked(!e.checked, ev)
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
		e.toggle({input: e})
		return false
	})

	e.on('keydown', function(key, shift, ctrl) {
		if (e.widget_editing) {
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
			e.toggle({input: e})
			return false
		}
		if (key == 'Delete') {
			e.val = null
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
			return this.capture_pointer(ev, null, function() {
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

	val_widget(e)

	e.set_items = function(items) {
		for (let item of items) {
			if (typeof item == 'string' || item instanceof Node)
				item = {text: item}
			let radio_div = span({class: 'x-markbox-icon x-radio-icon far fa-circle'})
			let text_div = span({class: 'x-markbox-text x-radio-text'})
			text_div.set(item.text)
			let idiv = div({class: 'x-widget x-markbox x-radio-item', tabindex: 0},
				radio_div, text_div)
			idiv.attr('align', e.align)
			idiv.item = item
			idiv.on('click', idiv_click)
			idiv.on('keydown', idiv_keydown)
			e.add(idiv)
		}
	}
	e.prop('items', {store: 'var', default: []})

	e.set_align = function(align) {
		for (let idiv of e.children)
			idiv.attr('align', align)
	}
	e.prop('align', {store: 'attr', type: 'enum', enum_values: ['left', 'right'], default: 'left'})

	let sel_item

	e.do_update_val = function(i) {
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

	e.prop('align', {store: 'attr', type: 'enum', enum_values: ['left', 'right'], default: 'left'})
	e.prop('mode' , {store: 'attr', type: 'enum', enum_values: ['default', 'inline'], default: 'default'})

	function update_inner_label() {
		e.class('with-inner-label', !e.nolabel && e.field && !!e.field.text)
	}

	e.class('with-inner-label', true)
	e.prop('nolabel', {store: 'attr', type: 'bool'})
	e.set_nolabel = update_inner_label

	let inh_do_update = e.do_update
	e.do_update = function() {
		inh_do_update()
		update_inner_label()
		e.inner_label_div.set(e.field ? e.field.text : '(no field)')
	}

}

component('x-input', function(e) {

	val_widget(e)
	input_widget(e)

	e.input = H.input({class: 'x-input-value'})
	e.inner_label_div = div({class: 'x-input-inner-label'})
	e.add(e.input, e.inner_label_div)

	function update_state(s) {
		e.input.class('empty', s == '')
		e.inner_label_div.class('empty', s == '')
	}

	e.from_text = function(s) { return e.field.from_text(s) }
	e.to_text = function(v) { return e.field ? e.field.to_text(v) : '' }

	e.do_update_val = function(v, ev) {
		if (ev && ev.input == e && ev.typing)
			return
		let s = e.to_text(v)
		let maxlen = or(e.maxlen, e.field && e.field.maxlen)
		e.input.value = s.slice(0, maxlen)
		e.input.attr('maxlength', maxlen)
		update_state(s)
	}

	e.input.on('input', function() {
		e.set_val(e.from_text(e.input.value), {input: e, typing: true})
		update_state(e.input.value)
	})

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
			else if (s == 'all_selected')
				return leftmost && rightmost
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

	e.set_text_min_w = function(w) {
		e.input.min_w = w
	}

})

// ---------------------------------------------------------------------------
// spin_input
// ---------------------------------------------------------------------------

component('x-spin-input', function(e) {

	input.construct(e)

	e.align = 'right'
	e.field_type = 'number'

	e.set_button_style     = e.update
	e.set_button_placement = e.update
	e.prop('button_style'    , {store: 'attr', type: 'enum', enum_values: ['plus-minus', 'up-down', 'left-right'], default: 'plus-minus'})
	e.prop('button_placement', {store: 'attr', type: 'enum', enum_values: ['each-side', 'left', 'right'], default: 'each-side'})

	e.up   = div({class: 'x-spin-input-button fa'})
	e.down = div({class: 'x-spin-input-button fa'})

	let inh_do_update = e.do_update
	e.do_update = function() {

		inh_do_update()

		let bs = e.button_style
		let bp = e.button_placement

		bp = bp || (bs == 'up-down' && 'left' || 'each-side')

		e.up  .remove()
		e.down.remove()

		e.up  .class('fa-plus'       , bs == 'plus-minus')
		e.down.class('fa-minus'      , bs == 'plus-minus')
		e.up  .class('fa-caret-up'   , bs == 'up-down')
		e.down.class('fa-caret-down' , bs == 'up-down')
		e.up  .class('fa-caret-right', bs == 'left-right')
		e.down.class('fa-caret-left' , bs == 'left-right')

		e.up  .class('left'     , false)
		e.up  .class('right'    , false)
		e.up  .class('leftmost' , false)
		e.up  .class('rightmost', false)
		e.down.class('left'     , false)
		e.down.class('right'    , false)
		e.down.class('leftmost' , false)
		e.down.class('rightmost', false)

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

	e.input.on('wheel', function(ev, dy) {
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

	e.prop('from', {store: 'var', default: 0})
	e.prop('to', {store: 'var', default: 1})

	e.val_fill = div({class: 'x-slider-fill x-slider-value-fill'})
	e.range_fill = div({class: 'x-slider-fill x-slider-range-fill'})
	e.input_thumb = div({class: 'x-slider-thumb x-slider-input-thumb'})
	e.val_thumb = div({class: 'x-slider-thumb x-slider-value-thumb'})
	e.add(e.range_fill, e.val_fill, e.val_thumb, e.input_thumb)

	// model

	val_widget(e)

	e.field_type = 'number'

	let inh_do_update = e.do_update
	e.do_update = function() {
		inh_do_update()
		e.class('animated', e.field && e.field.multiple_of >= 5) // TODO: that's not the point of this.
	}

	function progress_for(v) {
		return clamp(lerp(v, e.from, e.to, 0, 1), 0, 1)
	}

	function cmin() { return max(or(e.field && e.field.min, -1/0), e.from) }
	function cmax() { return min(or(e.field && e.field.max, 1/0), e.to) }

	e.set_progress = function(p, ev) {
		let v = lerp(p, 0, 1, e.from, e.to)
		if (e.field.multiple_of != null)
			v = floor(v / e.field.multiple_of + .5) * e.field.multiple_of
		e.set_val(clamp(v, cmin(), cmax()), ev)
	}

	e.property('progress',
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

	e.do_update_val = function(v) {
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
		return this.capture_pointer(ev, function(ev, mx, my) {
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

	e.class('x-input')

	val_widget(e)
	input_widget(e)
	focusable_widget(e)

	e.props.mode.enum_values = ['default', 'inline', 'wrap', 'fixed']

	e.prop('picker_w', {store: 'var', type: 'number', text: 'Picker Width'})

	e.val_div = span({class: 'x-input-value x-dropdown-value'})
	e.button = span({class: 'x-dropdown-button fa fa-caret-down'})
	e.inner_label_div = div({class: 'x-input-inner-label x-dropdown-inner-label'})
	e.add(e.val_div, e.button, e.inner_label_div)

	e.set_more_action = function(action) {
		if (!e.more_button && action) {
			e.more_button = div({class: 'x-input-more-button x-dropdown-more-button fa fa-ellipsis-h'})
			e.add(e.more_button)
			e.more_button.on('pointerdown', function(ev) {
				return this.capture_pointer(ev, null, function() {
					e.more_action()
					return false
				})
			})
		} else if (e.more_button && !action) {
			e.more_button.remove()
			e.more_button = null
		}
	}
	e.prop('more_action', {store: 'var', private: true})

	let inh_set_nav = e.set_nav
	e.set_nav = function(v, v0) {
		inh_set_nav(v, v0)
		if (e.picker)
			e.picker.nav = v
	}

	let inh_set_col = e.set_col
	e.set_col = function(v, v0) {
		inh_set_col(v, v0)
		if (e.picker)
			e.picker.col = v
	}

	function bind_picker(on) {
		if (!e.attached)
			return
		if (on) {
			e.picker = e.create_picker({
				id: e.id && e.id + '_dropdown',
				dropdown: e,
				nav: e.nav,
				col: e.col,
				can_select_widget: false,
			})
			e.picker.class('picker', true)
			e.picker.on('val_picked', picker_val_picked)
			e.picker.on('keydown'   , picker_keydown)
			e.picker.bind(true)
		} else if (e.picker) {
			e.picker.popup(false)
			e.picker.bind(false)
			e.picker = null
		}
		document.on('pointerdown'     , document_pointerdown, on)
		document.on('rightpointerdown', document_pointerdown, on)
		document.on('stopped_event'   , document_stopped_event, on)
	}

	e.on('bind_field', function(on) {
		if (!on)
			e.close()
		bind_picker(on)
	})

	// val updating

	e.do_update_val = function(v, ev) {
		let text = e.picker && e.picker.dropdown_display_val()
		if (text == null)
			text = e.display_val()
		let empty = text === ''
		e.val_div.class('empty', empty)
		e.val_div.class('null', false)
		e.inner_label_div.class('empty', empty)
		e.val_div.set(empty ? H('&nbsp;') : text)
	}

	let do_error_tooltip_check = e.do_error_tooltip_check
	e.do_error_tooltip_check = function() {
		return do_error_tooltip_check() || (e.invalid && e.isopen)
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

	e.set_open = function(open, focus, hidden) {
		if (e.isopen != open) {
			e.class('open', open)
			e.button.switch_class('fa-caret-down', 'fa-caret-up', open)
			if (open) {
				e.cancel_val = e.input_val
				e.picker.min_w = e.rect().w
				if (e.picker_w)
					e.picker.auto_w = false
				e.picker.w = e.picker_w
				e.picker.show(!hidden)
				e.picker.popup(e, 'bottom', e.align)
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
	e.cancel = function(focus, ev) {
		if (e.isopen)
			e.set_val(e.cancel_val, ev)
		e.close(focus)
	}

	e.property('isopen',
		function() {
			return e.hasclass('open')
		},
		function(open) {
			e.set_open(open, true)
		}
	)

	// picker protocol

	function picker_val_picked(ev) {
		e.close(!(ev && ev.input == e))
	}

	// grid editor protocol

	e.set_text_min_w = function(w) {
		e.val_div.min_w = w
	}

	// keyboard & mouse binding

	e.on('pointerdown', function() {
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
				e.set_open(true, false, true)
				e.picker.pick_near_val(key == 'ArrowDown' ? 1 : -1, {input: e})
				return false
			}
		}
		if (key == 'Delete') {
			e.set_val(null, {input: e})
			return false
		}
	})

	e.on('keypress', function(c) {
		if (e.picker.quicksearch) {
			e.picker.quicksearch(c)
			return false
		}
	})

	function picker_keydown(key) {
		if (key == 'Escape') {
			e.cancel(true)
			return false
		}
		if (key == 'Tab') {
			e.close(true)
			return false
		}
	}

	e.on('wheel', function(ev, dy) {
			e.set_open(true, false, true)
		e.picker.pick_near_val(dy / 100, {input: e})
		return false
	})

	// clicking outside the picker closes the picker.
	function document_pointerdown(ev) {
		if (e.contains(ev.target)) // clicked inside the dropdown.
			return
		if (e.picker.contains(ev.target)) // clicked inside the picker.
			return
		e.close()
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
// calendar widget
// ---------------------------------------------------------------------------

component('x-calendar', function(e) {

	focusable_widget(e)
	val_widget(e)

	function format_month(i) {
		return month_name(time(0, i), 'short')
	}

	e.sel_day = div({class: 'x-calendar-sel-day'})
	e.sel_day_suffix = div({class: 'x-calendar-sel-day-suffix'})

	e.sel_month = list_dropdown({
		classes: 'x-calendar-sel-month',
		items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
		field: {format: format_month},
		val_col: 0,
		display_col: 0,
		listbox: {
			format_item: format_month,
		},
	})

	e.sel_year = spin_input({
		classes: 'x-calendar-sel-year',
		field: {
			min: -10000,
			max:  10000,
		},
		button_style: 'left-right',
	})

	e.header = div({class: 'x-calendar-header'},
		e.sel_day, e.sel_day_suffix, e.sel_month, e.sel_year)

	e.weekview = H.table({class: 'x-calendar-weekview'})

	e.add(e.header, e.weekview)

	function as_ts(v) {
		return v != null && e.field && e.field.to_time ? e.field.to_time(v) : v
	}

	e.on('bind', function(on) {
		e.sel_year.bind(on)
		e.sel_month.bind(on)
	})

	e.do_update_val = function(v) {
		assert(e.attached)
		v = or(as_ts(v), time())
		let t = day(v)
		update_weekview(t, 6)
		let y = year_of(t)
		let n = floor(1 + days(t - month(t)))
		e.sel_day.set(n)
		let day_suffixes = ['', 'st', 'nd', 'rd']
		e.sel_day_suffix.set(locale.starts('en') ?
			(n < 11 || n > 13) && day_suffixes[n % 10] || 'th' : '')
		e.sel_month.val = month_of(t)
		e.sel_year.val = y
	}

	let sel_td
	function update_weekview(d, weeks) {
		let today = day(time())
		let this_month = month(d)
		let sel_d = day(as_ts(e.input_val))
		d = week(this_month)
		e.weekview.clear()
		sel_td = null
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
					s = s + (d == sel_d ? ' focused selected' : '')
					let td = H.td({class: 'x-calendar-day x-item'+s}, floor(1 + days(d - m)))
					td.day = d
					tr.add(td)
					if (d == sel_d)
						sel_td = td
					d = day(d, 1)
				}
			}
			e.weekview.add(tr)
		}
	}

	// controller

	function set_ts(v, ev) {
		if (v != null && e.field.from_time)
			v = e.field.from_time(v)
		e.set_val(v, ev || {input: e})
	}

	e.weekview.on('pointerdown', function(ev) {
		let td = ev.target
		if (td.day == null)
			return
		if (sel_td) {
			sel_td.class('focused', false)
			sel_td.class('selected', false)
		}
		e.sel_month.cancel()
		e.focus()
		td.classes = 'focused selected'
		return this.capture_pointer(ev, null, function() {
			set_ts(td.day)
			e.fire('val_picked') // picker protocol
			return false
		})
	})

	e.sel_month.on('val_changed', function(v, ev) {
		if (ev && ev.input) {
			_d.setTime(as_ts(e.input_val) * 1000)
			_d.setMonth(this.val)
			set_ts(_d.valueOf() / 1000)
		}
	})

	e.sel_year.on('val_changed', function(v, ev) {
		if (ev && ev.input) {
			_d.setTime(as_ts(e.input_val) * 1000)
			_d.setFullYear(this.val)
			set_ts(_d.valueOf() / 1000)
		}
	})

	e.weekview.on('wheel', function(ev, dy) {
		set_ts(day(as_ts(e.input_val), 7 * dy / 100))
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
			set_ts(day(as_ts(e.input_val), d))
			return false
		}
		if (m) {
			let t = as_ts(e.input_val)
			_d.setTime(t * 1000)
			if (shift)
				_d.setFullYear(year_of(t) + m)
			else
				_d.setMonth(month_of(t) + m)
			set_ts(_d.valueOf() / 1000)
			return false
		}
		if (key == 'Home') {
			let t = as_ts(e.input_val)
			set_ts(shift ? year(t) : month(t))
			return false
		}
		if (key == 'End') {
			let t = as_ts(e.input_val)
			set_ts(day(shift ? year(t, 1) : month(t, 1), -1))
			return false
		}
		if (key == 'Enter') {
			e.fire('val_picked', {input: e}) // picker protocol
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

	e.dropdown_display_val = function() {
		return e.display_val()
	}

	// hack: trick dropdown into thinking that our own opened dropdown picker
	// is our child, which is how we would implement dropdowns if this fucking
	// rendering model would allow us to decouple painting order from element's
	// position in the tree (IOW we need the concept of global z-index).
	let builtin_contains = e.contains
	e.contains = function(e1) {
		return builtin_contains.call(this, e1) || e.sel_month.picker.contains(e1)
	}

	e.pick_near_val = function(delta, ev) {
		set_ts(day(as_ts(e.input_val), delta), ev)
		e.fire('val_picked', ev)
	}

})

// ---------------------------------------------------------------------------
// date dropdown
// ---------------------------------------------------------------------------

component('x-date-dropdown', function(e) {
	dropdown.construct(e)
	e.field_type = 'date'
	e.create_picker = calendar
})

// ---------------------------------------------------------------------------
// richtext
// ---------------------------------------------------------------------------

component('x-richtext', function(e) {

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	editable_widget(e)
	contained_widget(e)

	e.content_div = div({class: 'x-richedit-content'})
	e.add(e.content_div)

	// content property

	e.set_content = function(s) { e.content_div.html = s }
	e.prop('content', {store: 'var', slot: 'lang'})

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

	let barrier
	let inh_set_content = e.set_content
	e.set_content = function(...args) {
		if (barrier) return
		inh_set_content(...args)
	}

	e.content_div.on('input', function(ev) {
		let e1 = ev.target.first
		if (e1 && e1.nodeType == 3)
			exec('formatBlock', '<p>')
		else if (e.content_div.html == '<br>')
			e.content_div.html = ''
		barrier = true
		e.content = e.content_div.html
		barrier = false
	})

	e.content_div.on('keydown', function(key, shift, ctrl, alt, ev) {
		if (key === 'Enter')
			if (document.queryCommandValue('formatBlock') == 'blockquote')
				after(0, function() { exec('formatBlock', '<p>') })
			else if (document.queryCommandValue('formatBlock') == 'pre')
				after(0, function() { exec('formatBlock', '<br>') })
		ev.stopPropagation()
	})

	e.content_div.on('keypress', function(key, shift, ctr, alt, ev) {
		ev.stopPropagation()
	})

	e.content_div.on('pointerdown', function(ev) {
		if (!e.widget_editing)
			return
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

// ---------------------------------------------------------------------------
// sql editor
// ---------------------------------------------------------------------------

component('x-sql-editor', function(e) {

	e.class('x-stretched')

	val_widget(e)

	e.do_update_val = function(val, ev) {
		e.editor.getSession().setValue(val || '')
	}

	e.do_update_error = function(err, ev) {
		// TODO
	}

	e.on('bind', function(on) {
		if (on) {
			e.editor = ace.edit(e, {
					mode: 'ace/mode/mysql',
					highlightActiveLine: false,
					printMargin: false,
					displayIndentGuides: false,
					tabSize: 3,
					enableBasicAutocompletion: true,
				})
			//sql_editor_ct.on('blur'            , exit_widget_editing, on)
			//sql_editor_ct.on('raw:pointerdown' , prevent_bubbling, on)
			//sql_editor_ct.on('raw:pointerup'   , prevent_bubbling, on)
			//sql_editor_ct.on('raw:click'       , prevent_bubbling, on)
			//sql_editor_ct.on('raw:contextmenu' , prevent_bubbling, on)
			e.do_update_val(e.val)
			//sql_editor.getSession().getValue()
		} else {
			e.editor.destroy()
			e.editor = null
		}
	})

})

// ---------------------------------------------------------------------------
// chart
// ---------------------------------------------------------------------------

component('x-chart', function(e) {

	e.class('x-stretched')

	contained_widget(e)
	serializable_widget(e)
	selectable_widget(e)

	// view -------------------------------------------------------------------

	function redraw() {
		e.update()
	}

	function slice_color(i, n) {
		return hsl_to_rgb(((i / (n-1)) * 360 - 120) % 180, .8, .7)
	}

	let render = {} // {shape->func}

	render.stack = function() {

		let slices = pie_slices()
		if (!slices)
			return

		let stack = div({class: 'x-chart-stack'})
		let labels = div({style: 'position: absolute;'})
		e.add(stack, labels)

		let i = 0
		for (let slice of slices) {
			let cdiv = div({class: 'x-chart-stack-slice'})
			let sdiv = div({class: 'x-chart-stack-slice-ct'}, cdiv, slice.label)
			sdiv.style.flex = slice.size
			cdiv.style['background-color'] = slice_color(i, slices.length)
			stack.add(sdiv)
			i++
		}

	}

	render.pie = function() {

		let slices = pie_slices()
		if (!slices)
			return

		let pie = div({class: 'x-chart-pie'})
		let labels = div({style: 'position: absolute;'})
		e.add(pie, labels)

		let w = e.clientWidth
		let h = e.clientHeight
		let pw = (w / h < 1 ? w : h) * .5

		pie.w = pw
		pie.h = pw
		pie.x = (w - pw) / 2
		pie.y = (h - pw) / 2

		let s = []
		let angle = 0
		let i = 0
		for (let slice of slices) {
			let arclen = slice.size * 360

			// generate a gradient step for this slice.
			let color = slice_color(i, slices.length)
			s.push(color + ' ' + angle.toFixed(0)+'deg '+(angle + arclen).toFixed(0)+'deg')

			// add the label and position it around the pie.
			labels.add(slice.label)
			let pad = 5
			let center_angle = angle + arclen / 2
			let [x, y] = point_around(w / 2, h / 2, pw / 2, center_angle - 90)
			slice.label.x = x + pad
			slice.label.y = y + pad
			let left = center_angle > 180
			let top  = center_angle < 90 || center_angle > 3 * 90
			if (left)
				slice.label.x = x - slice.label.clientWidth - pad
			if (top)
				slice.label.y = y - slice.label.clientHeight - pad

			angle += arclen
			i++
		}

		pie.style['background-image'] = 'conic-gradient(' + s.join(',') + ')'
	}

	function slice_label(key_vals, row, sum) {
		let label = div({class: 'x-chart-label'})
		let i = 0
		for (let field of e.nav.flds(e.cat_cols)) {
			let v = key_vals[i]
			let text = e.nav.cell_display_val_for(field, v, row)
			if (i == 1)
				label.add('/')
			label.add(text)
			i++
		}
		label.add(tag('br'))
		label.add(e.nav.cell_display_val_for(e.nav.fld(e.sum_col), sum, row))
		return label
	}

	function pie_slices() {

		let cat_groups = e.nav
			&& e.nav.flds(e.cat_cols) != null
			&& e.nav.fld(e.sum_col) != null
			&& e.nav.row_group(e.cat_cols, range_defs())

		if (!cat_groups)
			return

		let slices = []
		slices.total = 0
		for (let group of cat_groups) {
			let slice = {}
			let sum = 0
			for (let row of group)
				sum += e.nav.cell_val(row, e.sum_col)
			slice.sum = sum
			slice.label = slice_label(group.key_vals, group[0], sum)
			slices.push(slice)
			slices.total += sum
		}

		// sum small slices into a single "other" slice.
		let big_slices = []
		let other_slice
		for (let slice of slices) {
			slice.size = slice.sum / slices.total
			if (slice.size < e.other_threshold) {
				other_slice = other_slice || {sum: 0}
				other_slice.sum += slice.sum
			} else
				big_slices.push(slice)
		}
		if (other_slice) {
			other_slice.size = other_slice.sum / slices.total
			other_slice.label = div({class: 'x-chart-label'},
				e.other_text,
				tag('br'),
				e.nav.cell_display_val_for(e.nav.fld(e.sum_col), other_slice.sum)
			)
			big_slices.push(other_slice)
		}
		return big_slices
	}

	render.line = function() {

		let groups = e.nav
			&& e.nav.fld(e.sum_col) != null
			&& e.nav.row_groups(e.cat_cols, range_defs())

		if (!groups)
			return

		print(groups, range_defs())

		//for (let [k, group] of cat_groups)

		e.add('Hello')
	}

	e.do_update = function() {
		e.clear()
		render[e.shape]()
	}

	// controller -------------------------------------------------------------

	function range_defs() {
		let defs
		for (let col of e.cat_cols.split(/[\s,]+/)) {
			let freq   = e['cat_cols.'+col+'.range_freq'  ]
			let offset = e['cat_cols.'+col+'.range_offset']
			let unit   = e['cat_cols.'+col+'.range_unit'  ]
			if (freq != null || offset != null || unit != null) {
				defs = defs || {}
				defs[col] = {
					freq   : freq,
					offset : offset,
					unit   : unit,
				}
			}
		}
		return defs
	}

	function bind_nav(nav, on) {
		if (!e.attached)
			return
		if (!nav)
			return
		nav.on('reset'               , redraw, on)
		nav.on('rows_changed'        , redraw, on)
		nav.on('cell_val_changed'    , redraw, on)
		nav.on('display_vals_changed', redraw, on)
	}

	e.on('bind', function(on) {
		bind_nav(e.nav, on)
		document.on('layout_changed', redraw, on)
	})

	e.set_nav = function(nav1, nav0) {
		assert(nav1 != e)
		bind_nav(nav0, false)
		bind_nav(nav1, true)
		redraw()
	}

	e.prop('nav', {store: 'var', private: true})
	e.prop('nav_gid' , {store: 'var', bind_gid: 'nav', type: 'nav'})

	e.set_sum_col         = redraw
	e.set_other_threshold = redraw
	e.set_other_text      = redraw

	e.set_cat_cols = function(cat_cols, cat_cols0) {
		if (cat_cols0)
			for (let col of cat_cols0.split(/\s+/)) {
				delete e.props['cat_col.'+col+'.range_freq'  ]
				delete e.props['cat_col.'+col+'.range_offset']
				delete e.props['cat_col.'+col+'.range_unit'  ]
			}
		if (cat_cols)
			for (let col of cat_cols.split(/\s+/)) {
				e.props['cat_col.'+col+'.range_freq'  ] = {name: 'cat_col.'+col+'.range_freq'  , type: 'number'}
				e.props['cat_col.'+col+'.range_offset'] = {name: 'cat_col.'+col+'.range_offset', type: 'number'}
				e.props['cat_col.'+col+'.range_unit'  ] = {name: 'cat_col.'+col+'.range_unit'  , type: 'enum', enum_values: ['month', 'year']}
			}
		redraw()
	}

	e.set_prop = function(k, v) {
		let v0 = e[k]
		e[k] = v
		if (v !== v0 && k.starts('cat_col.')) {
			redraw()
			document.fire('prop_changed', e, k, v, v0, null)
		}
	}

	e.prop('sum_col' , {store: 'var', type: 'col', col_nav: () => e.nav})
	e.prop('cat_cols', {store: 'var', type: 'col', col_nav: () => e.nav})
	e.prop('other_threshold', {store: 'var', type: 'number', default: .05, multiple_of: null})
	e.prop('other_text', {store: 'var', default: 'Other'})
	e.prop('shape', {store: 'attr', type: 'enum',
		enum_values: ['pie', 'stack', 'line', 'area', 'column', 'bar', 'stackbar', 'bubble', 'scatter'],
		default: 'pie'})

})
