/*

	X-WIDGETS: Web Components in JavaScript.
	Written by Cosmin Apreutesei. Public Domain.

	Widgets:

		tooltip
		button
		menu
		widget_placeholder
		pagelist
		split
		slides
		toaster
		action_band
		dialog
		toolbox
		pagenav
		richtext

	Globals
		notify(text, ['search'|'info'|'error'], [timeout])

*/

DEBUG_ATTACH_TIME = false

/* ---------------------------------------------------------------------------
// creating & setting up web components
// ---------------------------------------------------------------------------
publishes:
	e.isinstance: t
	e.iswidget: t
	e.type
	e.initialized: t|f
calls:
	e.init()
fires:
	^document.'widget_bind' (on)
	^document.'ID.bind' (on)
--------------------------------------------------------------------------- */

{

let set_attr_func = function(e, k, opt) {
	if (opt.to_attr)
		return (v) => e.attr(k, v)
	if (opt.type == 'bool')
		return (v) => e.bool_attr(k, v || null)
	return (v) => e.attr(k, v)
}

let from_bool_attr = v => repl(repl(v, '', true), 'false', false)

let from_attr_func = function(opt) {
	return opt.from_attr
			|| (opt.type == 'bool'   && from_bool_attr)
			|| (opt.type == 'number' && num)
}

let attr_val_opt = function(e) {
	let opt = obj()
	for (let attr of e.attrs) {
		let k = attr.name
		// TODO: not cool that we must add all built-in attrs that we use for
		// custom components here (so that they aren't set twice, and wrong too
		// because text attr vals don't convert well to bool props, eg. `hidden`).
		if (k != 'id' && k != 'class' && k != 'style' && k != 'hidden') {
			let v = attr.value
			let popt = e.get_prop_attrs(k)
			if (popt && popt.from_attr)
				v = popt.from_attr(v)
			if (!(k in opt))
				opt[k] = v
		}
	}
	return opt
}

// component(tag, cons) -> create({option: value}) -> element.
function component(tag, category, cons) {

	if (!isstr(category)) {
		cons = category
		category = 'Other'
	}

	let type = tag.replace(/^x-/, '').replaceAll('-', '_')

	// override cons() so that calling `parent_widget.construct()` always
	// sets the css class for parent_widget.
	function construct(e, ...args) {
		e.class(tag)
		return cons(e, ...args)
	}

	function initialize(e, ...args) {

		e.bool_attr('_bind', true)

		e.do_bind = function(on) {
			if (on) {

				let t0 = DEBUG_ATTACH_TIME && time()

				this.fire('bind', true)
				if (this.id) {
					document.fire('widget_bind', this, true)
					document.fire(this.id+'.bind', this, true)
				}

				if (DEBUG_ATTACH_TIME) {
					let t1 = time()
					let dt = (t1 - t0) * 1000
					if (dt > 10)
						debug((dt).dec().padStart(3, ' ')+'ms', this.debug_name())
				}

				this.end_update()

			} else {

				this.begin_update()

				this.fire('bind', false)
				if (this.id) {
					document.fire('widget_bind', this, false)
					document.fire(this.id+'.bind', this, false)
				}

			}
		}

		component_deferred_updating(e)

		e.begin_update() // bind(true) calls end_update().
		e.update() // ...deferred on first call to bind().

		if (DEBUG_ATTACH_TIME)
			e.debug_name = function(prefix) {
				prefix = (prefix && prefix + ' < ' || '') + this.type + (this.id ? ' ' + this.id : '')
				let p = this; do { p = p.popup_target || p.parent } while (p && !p.debug_name)
				if (!(p && p.debug_name))
					return prefix
				return p.debug_name(prefix)
			}

		e.initialized = null // for log_add_event().

		// combine initial prop values from multiple sources, in overriding order:
		// - html attributes.
		// - constructor return value.
		// - constructor args.
		let opt = assign_opt(obj(), ...args)
		component_props(e, opt.props)
		e.isinstance = true   // because you can have non-widget instances.
		e.iswidget = true     // to diff from normal html elements.
		e.type = type         // for serialization.
		e.init = noop         // init point after all props are set.
		e.class('x-widget')
		let cons_opt = construct(e)
		opt = assign_opt(attr_val_opt(e), cons_opt, opt)

		e.initialized = false // setter barrier to delay init to e.init().

		// register events from the options directly.
		if (opt.on) {
			for (let k in opt.on)
				e.on(k, opt.on[k])
			delete opt.on
		}

		// set props to combined initial values.
		if (window.xmodule) {
			xmodule.init_instance(e, opt)
		} else {
			for (let k in opt)
				e.set_prop(k, opt[k])
		}

		// call the after-properties-are-set init function.
		e.initialized = true
		e.init()

		if (e.id)
			document.fire(e.id+'.init', e)
	}

	bind_component(tag, initialize)

	function create(...args) {
		let e = document.createElement(tag)
		initialize(e, ...args)
		return e
	}

	create.type = type
	create.construct = construct

	attr(component.categories, category, Array).push(create)
	component.types[type] = create
	window[type] = create

	return create
}

component.types = {} // {type -> create}
component.categories = {} // {cat -> {craete1,...}}

component.create = function(t, e0) {
	if (iselem(t) || (isobject(t) && t.isinstance))
		return t // instances pass through.
	let id = isstr(t) ? t : t.id
	if (e0 && e0.id == id)
		return e0  // already created (called from a prop's `convert()`).
	if (isstr(t)) // t is an id
		t = {id: t}
	if (!t.type) {
		t.type = xmodule.instance_type(id)
		if (!t.type) {
			warn('component id not found:', id)
			return
		}
	}
	let create = component.types[t.type]
	if (!create) {
		warn('component type not found', t.type, t.id)
		return
	}
	return create(t)
}

/* ---------------------------------------------------------------------------
// component partial deferred updating mixin
// ---------------------------------------------------------------------------
publishes:
	e.updating
	e.begin_update()
	e.end_update()
	e.update([opt])
calls:
	e.do_update([opt])
--------------------------------------------------------------------------- */

let component_deferred_updating = function(e) {

	e.updating = 0

	e.begin_update = function() {
		e.updating++
	}

	e.end_update = function() {
		assert(e.updating)
		e.updating--
		if (!e.updating)
			if (opt)
				e.update(opt)
	}

	e.do_update = noop

	let opt, in_update

	e.update = function(opt1) {
		if (in_update)
			return
		if (opt)
			if (opt1)
				assign_opt(opt, opt1)
			else
				opt.val = true
		else if (opt1)
			opt = opt1
		else
			opt = {val: true}
		if (e.updating)
			return
		in_update = true
		e.do_update(opt)
		in_update = false
		opt = null
	}

}

/* ---------------------------------------------------------------------------
// component property system mixin
// ---------------------------------------------------------------------------
uses:
	e.property(name, get, [set])
	e.prop(name, attrs)
publishes:
	e.<prop>
	e.props: {prop -> attrs}
		store: 'var'|'attr'|, private, default, convert,
		type, ...,
		style, style_format, style_parse, bind, resolve.
calls:
	e.get_<prop>() -> v
	e.set_<prop>(v1, v0)
fires:
	document.'prop_changed' (e, prop, v1, v0, slot)
--------------------------------------------------------------------------- */

let component_props = function(e, iprops) {

	e.xon  = function() { e.xmodule_noupdate = false }
	e.xoff = function() { e.xmodule_noupdate = true  }

	function fire_prop_changed(e, prop, v1, v0, slot) {
		document.fire('prop_changed', e, prop, v1, v0, slot)
	}

	function resolve_widget_id(id) {
		let e = window[id]
		return isobject(e) && e.iswidget && e.bound && e.can_select_widget != false ? e : null
	}

	e.props = {}

	e.prop = function(prop, opt) {
		opt = opt || {}
		assign_opt(opt, e.props[prop], iprops && iprops[prop]) // class & instance overrides
		let getter = 'get_'+prop
		let setter = 'set_'+prop
		let type = opt.type
		opt.name = prop
		let convert = opt.convert || return_arg
		let priv = opt.private
		let serialize = opt.serialize
		if (!e[setter])
			e[setter] = noop
		let prop_changed = fire_prop_changed
		let slot = opt.slot
		let dv = opt.default

		opt.from_attr = from_attr_func(opt)
		let set_attr = opt.attr && set_attr_func(e, prop, opt)

		if (opt.store == 'var') {
			let v = dv
			function get() {
				return v
			}
			function set(v1) {
				let v0 = v
				v1 = convert(v1, v0)
				if (v1 === v0)
					return
				v = v1
				e.begin_update()
				e[setter](v1, v0)
				if (set_attr)
					set_attr(v1)
				if (!priv)
					prop_changed(e, prop, v1, v0, slot)
				e.update()
				e.end_update()
			}
			if (set_attr && !e.hasattr(prop))
				set_attr(dv)
		} else if (opt.style) {
			let style = opt.style
			let format = opt.style_format || return_arg
			let parse  = opt.style_parse  || type == 'number' && num || (v => repl(v, '', undefined))
			if (dv != null && parse(e.style[style]) == null)
				e.style[style] = format(dv)
			function get() {
				return parse(e.style[style])
			}
			function set(v) {
				let v0 = get.call(e)
				v = convert(v, v0)
				if (v == v0)
					return
				e.style[style] = format(v)
				v = get.call(e) // take it again (browser only sets valid values)
				if (v == v0)
					return
				e.begin_update()
				e[setter](v, v0)
				if (!priv)
					prop_changed(e, prop, v, v0, slot)
				e.update()
				e.end_update()
			}
		} else {
			assert(!('default' in opt))
			function get() {
				return e[getter]()
			}
			function set(v) {
				let v0 = e[getter]()
				v = convert(v, v0)
				if (v === v0)
					return
				e.begin_update()
				e[setter](v, v0)
				if (!priv)
					prop_changed(e, prop, v, v0, slot)
				e.update()
				e.end_update()
			}
		}

		// id-based dynamic binding.
		if (opt.bind_id) {
			let resolve = opt.resolve || resolve_widget_id
			let ID = prop
			let REF = opt.bind_id
			function widget_bind(te, on) {
				if (e[ID] == te.id)
					e[REF] = on ? te : null
			}
			function bind(on) {
				e[REF] = on ? resolve(e[ID]) : null
				document.on('widget_bind', widget_bind, on)
			}
			function id_changed(id1, id0) {
				if (e.bound)
					e[REF] = resolve(id1)
				if ((id1 != null) != (id0 != null)) {
					e.on('bind', bind, id1 != null)
				}
			}
			prop_changed = function(e, k, v1, v0, slot) {
				fire_prop_changed(e, k, v1, v0, slot)
				if (k == ID)
					id_changed(v1, v0)
			}
			if (e[ID] != null)
				id_changed(e[ID])
		}

		e.property(prop, get, set)

		if (!priv)
			e.props[prop] = opt

	}

	// dynamic properties.

	e.set_prop = function(k, v) { e[k] = v } // stub
	e.get_prop = k => e[k] // stub
	e.get_prop_attrs = k => e.props[k] // stub

	// prop serialization.

	e.serialize_prop = function(k, v, even_if_default) {
		let def = e.props[k]
		if (def && !even_if_default && v === def.default)
			return undefined // undefined is not stored.
		if (def && def.serialize)
			v = def.serialize(v)
		else if (isobject(v) && v.serialize)
			v = v.serialize()
		return v
	}

}

}

/* ---------------------------------------------------------------------------
// undo stack, selected widgets, editing widget and clipboard.
// ---------------------------------------------------------------------------
publishes:
	undo_stack, redo_stack
	editing_widget
	selected_widgets
	copied_widgets
	focused_widget(e)
	unselect_all_widgets()
	copy_selected_widgets()
	cut_selected_widgets()
	paste_copied_widgets()
	undo()
	redo()
	push_undo(f)
behavior:
	uncaptured clicks and escape unselect all widgets.
	ctrl+x/+c/+v/(+shift)+z/+y do the usual thing with selected widgets.
--------------------------------------------------------------------------- */

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
	return e && e.iswidget && e || (e.parent && e.parent != e && focused_widget(e.parent))
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

function paste_copied_widgets() {
	if (!copied_widgets.size)
		return
	if (editing_widget) {
		editing_widget.add_widgets(copied_widgets)
		copied_widgets.clear()
	} else {
		for (let e of selected_widgets) {
			let ce = copied_widgets.values().next().value
			if (!ce)
				break
			let pe = e.parent_widget
			if (pe)
				pe.replace_child_widget(e, ce)
			copied_widgets.delete(ce)
		}
	}
}

document.on('keydown', function(key, shift, ctrl) {
	if (key == 'Escape')
		unselect_all_widgets()
	else if (ctrl && key == 'c')
		copy_selected_widgets()
	else if (ctrl && key == 'x')
		cut_selected_widgets()
	else if (ctrl && key == 'v')
		paste_copied_widgets()
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

/* ---------------------------------------------------------------------------
// selectable widget mixin
// ---------------------------------------------------------------------------
uses:
	e.can_select_widget
publishes:
	e.parent_widget
	e.selectable_parent_widget
	e.widget_selected
	e.set_widget_selected()
	e.remove_widget()
calls:
	e.do_select_widget()
	e.do_unselect_widget()
calls from the first parent which has e.child_widgets:
	p.can_select_widget
	p.remove_child_widget()
behavior:
	enters widget editing mode and/or selects widget with ctrl(+shift)+click.
--------------------------------------------------------------------------- */

function parent_widget_which(e, which) {
	assert(e != window)
	e = e.popup_target || e.parent
	while (e) {
		if (e.iswidget && which(e))
			return e
		e = e.popup_target || e.parent
	}
}

function up_widget_which(e, which) {
	return which(e) ? e : parent_widget_which(e, which)
}

function selectable_widget(e) {

	e.property('parent_widget', function() {
		return parent_widget_which(this, p => p.child_widgets)
	})

	e.property('selectable_parent_widget', function() {
		return parent_widget_which(e, p => p.child_widgets && p.can_select_widget)
	})

	e.can_select_widget = true

	e.set_widget_selected = function(select, focus, fire_changed_event) {
		select = select !== false
		if (e.widget_selected == select)
			return
		if (select) {
			selected_widgets.add(e)
			e.do_select_widget(focus)
		} else {
			selected_widgets.delete(e)
			e.do_unselect_widget(focus)
		}
		e.class('widget-selected', select)
		if (fire_changed_event !== false)
			document.fire('selected_widgets_changed')
	}

	e.property('widget_selected',
		() => selected_widgets.has(e),
		function(v, ...args) { e.set_widget_selected(v, ...args) })

	e.do_select_widget = function(focus) {

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
				return false
			} else
				unselect_all_widgets()
		})

		if (focus !== false)
			overlay.focus()
	}

	e.do_unselect_widget = function(focus_prev) {

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

	e.hit_test_widget_editing = return_true

	e.on('pointerdown', function(ev, mx, my) {

		if (!e.can_select_widget)
			return

		if (e.widget_selected)
			return false // prevent dropdown from opening.

		if (!ev.ctrlKey)
			return

		if (ev.shiftKey) {

			// prevent accidentally clicking on the parent of any of the selected widgets.
			for (let e1 of selected_widgets) {
				let p = e1.selectable_parent_widget
				while (p) {
					if (p == e)
						return false
					p = p.selectable_parent_widget
				}
			}

			e.widget_editing = false
			e.widget_selected = true

		} else {

			unselect_all_widgets()

			if (e.can_edit_widget && !selected_widgets.size)
				if (e.hit_test_widget_editing(ev, mx, my)) {
					e.widget_editing = true
					// don't prevent default to let the caret land under the mouse.
					ev.stopPropagation()
					return
				}

		}

		return false

	})

	e.on('bind', function(on) {
		if (!on)
			e.widget_selected = false
	})

}

/* ---------------------------------------------------------------------------
// editable widget mixin
// ---------------------------------------------------------------------------
uses:
	e.can_edit_widget
publishes:
	e.widget_editing
calls:
	e.set_widget_editing()
--------------------------------------------------------------------------- */

function editable_widget(e) {

	e.can_edit_widget = true
	e.set_widget_editing = noop

	e.property('widget_editing',
		() => editing_widget == e,
		function(v) {
			v = !!v
			if (e.widget_editing == v)
				return
			e.class('widget-editing', v)
			if (v) {
				assert(editing_widget != e)
				if (editing_widget)
					editing_widget.widget_editing = false
				assert(editing_widget == null)
				e.focusable = false
				editing_widget = e
			} else {
				e.focusable = true
				editing_widget = null
			}
			getSelection().removeAllRanges()
			e.set_widget_editing(v)
		})

	e.on('bind', function(on) {
		if (!on)
			e.widget_editing = false
	})

}

// ---------------------------------------------------------------------------
// pagelist item widget mixin
// ---------------------------------------------------------------------------

function pagelist_item_widget(e) {

	e.props.title = {name: 'title', slot: 'lang', default: ''}

	override_property_setter(e, 'title', function(inherited, v) {
		if (!v) v = ''
		let v0 = e.title
		inherited.call(this, v)
		if (v === v0)
			return
		document.fire('prop_changed', e, 'title', v, v0, 'lang')
	})

}

// ---------------------------------------------------------------------------
// cssgrid item widget mixin
// ---------------------------------------------------------------------------

function cssgrid_item_widget(e) {

	e.prop('pos_x'  , {style: 'grid-column-start' , type: 'number'})
	e.prop('pos_y'  , {style: 'grid-row-start'    , type: 'number'})
	e.prop('span_x' , {style: 'grid-column-end'   , type: 'number', style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('span_y' , {style: 'grid-row-end'      , type: 'number', style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('align_x', {style: 'justify-self'      , type: 'enum', enum_values: ['start', 'end', 'center', 'stretch']})
	e.prop('align_y', {style: 'align-self'        , type: 'enum', enum_values: ['start', 'end', 'center', 'stretch']})

	let do_select_widget = e.do_select_widget
	let do_unselect_widget = e.do_unselect_widget

	e.do_select_widget = function(focus) {
		do_select_widget(focus)
		let p = e.parent_widget
		if (p && p.iswidget && p.type == 'cssgrid') {
			cssgrid_item_widget_editing(e)
			e.cssgrid_item_do_select_widget()
		}
	}

	e.do_unselect_widget = function(focus_prev) {
		let p = e.parent_widget
		if (p && p.iswidget && p.type == 'cssgrid')
			e.cssgrid_item_do_unselect_widget()
		do_unselect_widget(focus_prev)
	}

}

function contained_widget(e) {
	pagelist_item_widget(e)
	cssgrid_item_widget(e)
}

// ---------------------------------------------------------------------------
// editable widget protocol for cssgrid item
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

	e.cssgrid_item_do_select_widget = function() {

		let p = e.parent_widget
		if (!(p && p.iswidget && p.type == 'cssgrid'))
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

		function prop_changed(te, k) {
			if (te == e)
				if (k == 'pos_x' || k == 'span_x' || k == 'pos_y' || k == 'span_y')
					update_so()
		}

		e.on('bind', function(on) {
			document.on('prop_changed', prop_changed, on)
		})

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

		function so_pointermove(ev, mx, my) {
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

		e.cssgrid_item_do_unselect_widget = function() {
			e.off('prop_changed', prop_changed)
			e.widget_selected_overlay.off('keydown', overlay_keydown)
			span_outline.remove()
			e.cssgrid_item_do_unselect_widget = noop

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

/* ---------------------------------------------------------------------------
// serializable widget mixin
// ---------------------------------------------------------------------------
publishes:
	e.serialize()
--------------------------------------------------------------------------- */

function serializable_widget(e) {

	e.serialize = function() {
		if (e.id)
			return e.id
		let t = {type: e.type}
		if (e.props)
			for (let prop in e.props) {
				let v = e.serialize_prop(prop, e[prop])
				if (v !== undefined)
					t[prop] = v
			}
		return t
	}

}

/* ---------------------------------------------------------------------------
// focusable widget mixin
// ---------------------------------------------------------------------------
publishes:
	e.tabindex
	e.disabled
	e.focusable

NOTE: The `disabled` state is a concerted effort located in multiple places:
	- mouse events are blocked in divs.js.
	- forcing the default cursor on the element and its children is done in css.
	- showing the element with 50% transparency is done in css.
	- keyboard focusing is disabled here.

NOTE: To disable a non-focusable but clickable element it's enough to set its
attr `disabled` but note that `:hover` and `:active` will still work so
make sure to add `:not([disabled])` in css on those selectors.
--------------------------------------------------------------------------- */

function focusable_widget(e, fe) {
	fe = fe || e

	let focusable = true

	if (!fe.hasattr('tabindex'))
		fe.attr('tabindex', 0)

	function do_update() {
		let can_be_focused = focusable && !e.disabled
		fe.attr('tabindex', can_be_focused ? e.tabindex : (fe instanceof HTMLInputElement ? -1 : null))
		if (!can_be_focused)
			e.blur()
	}

	e.set_tabindex = do_update
	e.prop('tabindex', {store: 'var', type: 'number', default: 0})

	e.property('focusable', () => focusable, function(v) {
		v = !!v
		if (v == focusable) return
		focusable = v
		do_update()
	})

	e.set_disabled = do_update
	e.prop('disabled', {store: 'var', type: 'bool', attr: true})

	let inh_focus = e.focus
	e.focus = function() {
		if (fe == this || this.widget_selected)
			inh_focus.call(this)
		else
			fe.focus()
	}

}

/* ---------------------------------------------------------------------------
// stylable widget mixin
// ---------------------------------------------------------------------------
publishes:
	e.css_classes
--------------------------------------------------------------------------- */

function stylable_widget(e) {

	e.set_css_classes = function(c1, c0) {
		if (c0)
			e.class(c0, false)
		if (c1)
			e.class(c1, true)
	}
	e.prop('css_classes', {store: 'var'})

	e.prop('theme', {store: 'var', attr: true})
}

// ---------------------------------------------------------------------------
// tooltip
// ---------------------------------------------------------------------------

component('x-tooltip', function(e) {

	e.content = div({class: 'x-tooltip-content'})
	e.icon_box = div()
	e.body = div({class: 'x-tooltip-body'}, e.icon_box, e.content)
	e.pin = div({class: 'x-tooltip-tip'})
	e.add(e.body, e.pin)

	e.prop('target'      , {store: 'var', private: true})
	e.prop('text'        , {store: 'var', slot: 'lang'})
	e.prop('icon_visible', {store: 'var', type: 'bool'})
	e.prop('side'        , {store: 'var', type: 'enum', enum_values: ['top', 'bottom', 'left', 'right', 'inner-top', 'inner-bottom', 'inner-left', 'inner-right', 'inner-center'], default: 'top'})
	e.prop('align'       , {store: 'var', type: 'enum', enum_values: ['center', 'start', 'end'], default: 'center', attr: true})
	e.prop('kind'        , {store: 'var', type: 'enum', enum_values: ['default', 'search', 'info', 'warn', 'error', 'cursor'], default: 'default', attr: true})
	e.prop('px'          , {store: 'var', type: 'number'})
	e.prop('py'          , {store: 'var', type: 'number'})
	e.prop('pw'          , {store: 'var', type: 'number'})
	e.prop('ph'          , {store: 'var', type: 'number'})
	e.prop('timeout'     , {store: 'var'})
	e.prop('close_button', {store: 'var', type: 'bool'})

	e.init = function() {
		e.update({reset_timer: true})
		e.popup(e.target, e.side, e.align, e.px, e.py, e.pw, e.ph)
	}

	e.popup_target_updated = function(target, side) {
		let visible = !!(!e.check || e.check(target))
		e.class('visible', visible)
		e.attr('side', side)
	}

	e.close = function() {
		if (e.fire('closed'))
			e.target = null
	}

	function close() { e.close() }

	let last_popup_time

	e.do_update = function(opt) {
		if (e.close_button && !e.xbutton) {
			e.xbutton = div({class: 'x-tooltip-xbutton fa fa-times'})
			e.xbutton.on('pointerup', close)
			e.body.add(e.xbutton)
		} else if (e.xbutton) {
			e.xbutton.show(e.close_button)
		}
		let icon_classes = e.icon_visible && tooltip.icon_classes[e.kind]
		e.icon_box.attr('class', icon_classes ? ('x-tooltip-icon ' + icon_classes) : null)
		e.popup(e.target, e.side, e.align, e.px, e.py, e.pw, e.ph)
		if (opt && opt.reset_timer)
			reset_timeout_timer()
		if (e.target)
			last_popup_time = time()
	}

	e.set_target = function() {
		if (e.initialized)
			e.init()
	}

	e.set_text = function(s) {
		e.content.set(s, 'pre-wrap')
		e.update({reset_timer: true})
	}

	let remove_timer = timer(close)
	function reset_timeout_timer() {
		let t = e.timeout
		if (t == 'auto')
			t = clamp((e.text || '').length / (tooltip.reading_speed / 60), 1, 10)
		else
			t = num(t)
		remove_timer(t)
	}

	override_property_setter(e, 'hidden', function(inherited, v) {
		inherited.call(this, v)
		e.update()
	})

	e.property('visible',
		function()  { return !e.hidden },
		function(v) { e.hidden = !v },
	)

	// keyboard, mouse & focusing behavior ------------------------------------

	e.on('keydown', function(key) {
		if (key == 'Escape') {
			e.close()
			return false
		}
	})

	e.content.on('pointerdown', function(ev) {
		if (ev.target != this)
			return // clicked inside the tooltip.
		let first_focusable = this.focusables()[0]
		if (!first_focusable)
			return
		first_focusable.focus()
		return false
	})

	// autoclose --------------------------------------------------------------

	e.prop('autoclose', {store: 'var', type: 'bool', default: false})

	e.on('popup_bind', function(on) {
		document.on('pointerdown', document_pointerdown, on)
		document.on('stopped_event', document_stopped_event, on)
		document.on('focusin', document_focusin, on)
		document.on('focusout', document_focusout, on)
	})

	function too_soon() {
		// HACK: if less than 100ms has passed since the last call to popup()
		// then it means that this event is the one that made the popup show
		// in the first place, so we don't close the popup in that case.
		return (time() - last_popup_time) < .1
	}

	// clicking outside the tooltip or its anchor closes the tooltip.
	function document_pointerdown(ev) {
		if (!e.autoclose)
			return
		if (e.target && e.target.contains(ev.target)) // clicked inside the anchor.
			return
		if (e.contains(ev.target)) // clicked inside the tooltip.
			return
		if (too_soon())
			return
		e.close()
	}

	// clicking outside the tooltip closes the tooltip, even if the click did something.
	function document_stopped_event(ev) {
		if (!ev.type.ends('pointerdown'))
			return
		document_pointerdown(ev)
	}

	// focusing an element outside the tooltip or its anchor closes the tooltip.
	function document_focusin(ev) {
		document_pointerdown(ev)
	}

	// focusing out of the document (to the titlebar etc.) closes the tooltip.
	function document_focusout(ev) {
		if (!e.autoclose)
			return
		if (ev.relatedTarget)
			return
		if (!e.autoclose)
			return
		e.close()
	}

})

tooltip.reading_speed = 800 // letters-per-minute.

tooltip.icon_classes = {
	info   : 'fa fa-info-circle',
	error  : 'fa fa-exclamation-circle',
	warn   : 'fa fa-exclamation-triangle',
}

// ---------------------------------------------------------------------------
// button
// ---------------------------------------------------------------------------

component('x-button', 'Input', function(e) {

	serializable_widget(e)
	selectable_widget(e)
	focusable_widget(e)
	editable_widget(e)
	contained_widget(e)

	let html_text = unsafe_html(e.html)
	e.clear()

	e.icon_box = span({class: 'x-button-icon'})
	e.text_box = span({class: 'x-button-text'})
	e.icon_box.hide()
	e.add(e.icon_box, e.text_box)

	e.prop('href', {store:'var', attr: true})
	e.set_href = function(s) {
		if (s) {
			if (!e.link) { // make a link for google bot to follow.
				let noscript = tag('noscript')
				e.add(noscript)
				e.link = tag('a')
				e.link.set(TC(e.text))
				e.link.title = e.title
				noscript.set(e.link)
			}
			e.link.href = s
		} else if (e.link) {
			e.link.href = null
		}
	}

	e.set_text = function(s) {
		e.text_box.set(s, 'pre-wrap')
		e.class('text-empty', !s)
		if (e.link)
			e.link.set(TC(e.text))
	}
	e.prop('text', {store: 'var', default: 'OK', slot: 'lang'})

	e.do_after('init', function() {
		if (html_text != null && html_text != e.text)
			e.text = html_text
		else
			e.set_text(e.text) // set default
	})

	e.set_icon = function(v) {
		if (isstr(v))
			e.icon_box.attr('class', 'x-button-icon '+v)
		else
			e.icon_box.set(v)
		e.icon_box.show(!!v)
	}
	e.prop('icon', {store: 'var', type: 'icon'})

	e.prop('primary', {store: 'var', type: 'bool', attr: true})
	e.prop('bare'   , {store: 'var', type: 'bool', attr: true})
	e.prop('danger' , {store: 'var', type: 'bool', attr: true})

	e.activate = function() {
		if (e.effectively_hidden || e.effectively_disabled)
			return
		if (e.href) {
			exec(e.href)
			return
		}
		// action can be set directly or can be a global with a maching name.
		if (e.action)
			e.action()
		let action_name = e.action_name || (e.id && e.id+'_action')
		let action = window[action_name]
		if (action)
			action.call(e)
		e.fire('activate')
	}

	function set_active(on) {
		e.class('active', on)
		e.fire('active', on)
		if (!on)
			e.activate()
	}

	e.on('keydown', function keydown(key, shift, ctrl) {
		if (e.widget_editing) {
			if (key == 'Enter') {
				if (ctrl) {
					e.text_box.insert_at_caret('<br>')
					return
				} else {
					e.widget_editing = false
					return false
				}
			}
			return
		}
		if (key == ' ' || key == 'Enter') {
			set_active(true)
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
				set_active(false)
			}
			return false
		}
	})

	e.on('pointerdown', function(ev) {
		if (e.widget_editing)
			return
		e.focus()
		set_active(true)
		return this.capture_pointer(ev, null, function() {
			set_active(false)
		})
	})

	// widget editing ---------------------------------------------------------

	e.set_widget_editing = function(v) {
		e.text_box.contenteditable = v
		if (!v)
			e.text = e.text_box.innerText
	}

	e.on('pointerdown', function(ev) {
		if (e.widget_editing && ev.target != e.text_box) {
			e.text_box.focus()
			e.text_box.select_all()
			return this.capture_pointer(ev)
		}
	})

	function prevent_bubbling(ev) {
		if (e.widget_editing)
			ev.stopPropagation()
	}
	e.text_box.on('pointerdown', prevent_bubbling)
	e.text_box.on('click', prevent_bubbling)

	e.text_box.on('blur', function() {
		e.widget_editing = false
	})

	// ajax notifications -----------------------------------------------------

	e.on('load', function(ev, ...args) {
		e.disabled = ev != 'done'
		if (e.load_spin)
			e.icon_box.class('fa-spin', ev == 'start')
	})

	e.load = function(url, success, fail, opt) {
		return get(url, success, fail, assign({notify: e}, opt))
	}

	e.post = function(url, upload, success, fail, opt) {
		return post(url, upload, success, fail, assign({notify: e}, opt))
	}

})

// ---------------------------------------------------------------------------
// menu
// ---------------------------------------------------------------------------

component('x-menu', function(e) {

	focusable_widget(e)
	e.class('x-focusable-items')

	// view

	function create_item(item, disabled) {
		let check_box = div({class: 'x-menu-check-div fa fa-check'})
		let icon_box  = div({class: 'x-menu-icon-div'})
		if (isstr(item.icon))
			icon_box.classes = item.icon
		else
			icon_box.set(item.icon)
		let check_td  = tag('td', {class: 'x-menu-check-td'}, check_box, icon_box)
		let title_td  = tag('td', {class: 'x-menu-title-td'})
		title_td.set(item.text)
		let key_td    = tag('td', {class: 'x-menu-key-td'}, item.key)
		let sub_box   = div({class: 'x-menu-sub-div fa fa-caret-right'})
		let sub_td    = tag('td', {class: 'x-menu-sub-td'}, sub_box)
		sub_box.style.visibility = item.items ? null : 'hidden'
		let tr = tag('tr', {class: 'x-item x-menu-tr'}, check_td, title_td, key_td, sub_td)
		tr.class('disabled', disabled || item.disabled)
		tr.item = item
		tr.check_box = check_box
		update_check(tr)
		tr.on('pointerdown' , item_pointerdown)
		tr.on('pointerenter', item_pointerenter)
		return tr
	}

	function create_heading(item) {
		let td = tag('td', {class: 'x-menu-heading', colspan: 5})
		td.set(item.heading)
		let tr = tag('tr', {}, td)
		tr.focusable = false
		tr.on('pointerenter', separator_pointerenter)
		return tr
	}

	function create_separator() {
		let td = tag('td', {class: 'x-menu-separator', colspan: 5}, tag('hr'))
		let tr = tag('tr', {}, td)
		tr.focusable = false
		tr.on('pointerenter', separator_pointerenter)
		return tr
	}

	function create_menu(table, items, is_submenu, disabled) {
		table = table || tag('table')
		table.classes = 'x-widget x-focusable x-menu'+(is_submenu ? ' x-menu-submenu' : '')
		table.attr('tabindex', 0)
		for (let i = 0; i < items.length; i++) {
			let item = items[i]
			item.menu = e
			let tr = item.heading ? create_heading(item) : create_item(item, disabled)
			table.add(tr)
			if (item.separator)
				table.add(create_separator())
		}
		table.on('keydown', menu_keydown)
		return table
	}

	e.init = function() {
		e.table = create_menu(e, e.items, false, e.disabled)
	}

	function show_submenu(tr) {
		let table = tr.submenu_table
		if (!table) {

			let items = tr.item.items
			if (!items)
				return

			table = create_menu(null, items, true, tr.item.disabled)
			table.parent_menu = tr.parent
			tr.submenu_table = table
			tr.last.add(table)

		} else {

			table.x = null
			table.y = null

		}

		// adjust submenu to fit the screen.
		let r = table.rect()
		let br = document.body.rect()
		table.y = -max(0, r.y2 - br.y2 + 10)
		if (r.x2 - br.x2 > 10) {
			table.x = -r.w - tr.clientWidth + tr.last.clientWidth + 2
		} else {
			table.x = tr.last.clientWidth - 2
		}

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
		tr.check_box.show(tr.item.checked != null)
		tr.check_box.style.visibility = tr.item.checked ? null : 'hidden'
	}

	// popup protocol

	e.on('popup_bind', function(on, target) {
		document.on('pointerdown', document_pointerdown, on)
		document.on('rightpointerdown', document_pointerdown, on)
		document.on('stopped_event', document_stopped_event, on)
	})

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

	override(e, 'popup', function(inherited, target, side, align, px, py, pw, ph, ox, oy, select_first_item) {
		popup_target = target
		inherited.call(this, target, side, align, px, py, pw, ph, ox, oy)
		if (select_first_item)
			select_next_item(e.table)
		e.table.focus()
	})

	// navigation

	function next_item(menu, down, tr) {
		tr = tr && (down ? tr.next : tr.prev)
		return tr || (down ? menu.first : menu.last)
	}
	function next_valid_item(menu, down, tr, disabled) {
		let i = menu.children.length
		while (i--) {
			tr = next_item(menu, down != false, tr)
			if (tr && tr.focusable != false && (disabled || tr.disabled))
				return tr
		}
	}
	function select_next_item(menu, down, tr0, disabled) {
		select_item(menu, next_valid_item(menu, down, tr0, disabled))
	}

	function activate_submenu(tr) {
		let submenu = show_submenu(tr)
		if (!submenu)
			return
		submenu.focus()
		select_next_item(submenu)
		return true
	}

	function click_item(tr) {
		let item = tr.item
		if ((item.action || item.checked != null) && !item.disabled) {
			if (item.checked != null) {
				item.checked = !item.checked
				update_check(tr)
			}
			return !item.action || item.action(item) != false
		}
	}

	// mouse bindings

	function item_pointerdown(ev) {
		return this.capture_pointer(ev, null, function() {
			if (click_item(this))
				return e.close()
		})
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
				if (click_item(tr) && !submenu_activated)
					e.close(true)
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
// context menu
// ---------------------------------------------------------------------------

component('x-context-menu', function(e) {

	// TODO:

	let cmenu

	function close_context_menu() {
		if (cmenu) {
			cmenu.close()
			cmenu = null
		}
	}

	e.on('rightpointerdown', close_context_menu)

	e.on('contextmenu', function(ev) {

		close_context_menu()

		if (update_mouse(ev))
			fire_pointermove()

		let items = []

		if (tool.context_menu)
			items.extend(tool.context_menu())

		cmenu = menu({
			items: items,
		})

		cmenu.popup(e, 'inner-top', null, null, null, null, null, mouse.x, mouse.y)

		return false
	})

})

// ---------------------------------------------------------------------------
// widget placeholder
// ---------------------------------------------------------------------------

component('x-widget-placeholder', function(e) {

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	contained_widget(e)

	function replace_widget(item) {
		let pe = e.parent_widget
		let te = component.create({
			type: item.create.type,
			id: '<new>', // pseudo-id to be replaced with an auto-generated id.
			module: pe && pe.module || e.module,
		})
		if (pe) {
			pe.replace_child_widget(e, te)
		} else {
			xmodule.set_root_widget(te)
		}
		te.focus()
	}

	let cmenu

	function create_context_menu() {
		let items = []
		for (let cat in component.categories) {
			let comp_items = []
			let cat_item = {text: cat, items: comp_items}
			items.push(cat_item)
			for (let create of component.categories[cat])
				comp_items.push({
					text: create.type.display_name(),
					create: create,
					action: replace_widget,
				})
		}
		if (cmenu)
			cmenu.close()
		cmenu = menu({
			items: items,
		})
	}

	e.on('bind', function(on) {
		if (on)
			create_context_menu()
	})

	e.on('contextmenu', function(ev, mx, my) {
		cmenu.popup(e, 'inner-top', null, null, null, null, null, ev.clientX, ev.clientY)
		return false
	})

})

// ---------------------------------------------------------------------------
// widget-items widget mixin
// ---------------------------------------------------------------------------
// publishes:
//   e.items
// implements:
//   e.child_widgets()
//   e.remove_child_widget()
// calls:
//   e.do_init_items()
//   e.do_remove_item(item)
// ---------------------------------------------------------------------------

widget_items_widget = function(e) {

	function same_items(t, items) {
		if (t.length != items.length)
			return false
		for (let i = 0; i < t.length; i++) {
			let id0 = items[i].id
			let id1 = isstr(t[i]) ? t[i] : t[i].id
			if (!id1 || !id0 || id1 != id0)
				return false
		}
		return true
	}

	function diff_items(t, cur_items) {

 		t = isstr(t) ? t.names() : t

		if (same_items(t, cur_items))
			return cur_items

		// diff between t and cur_items keyed on id or item identity.

		// map current items by identity and by id.
		let cur_set = new Set()
		let cur_by_id = new Map()
		for (let item of cur_items) {
			cur_set.add(item)
			if (item.id)
				cur_by_id.set(item.id, item)
		}

		// create new items or reuse-by-id.
		let items = new Set()
		for (let v of t) {
			// v is either an item from cur_items, an id, or the attrs for a new item.
			let cur_item = cur_set.has(v) ? v : cur_by_id.get(v)
			items.add(component.create(v, cur_item))
		}

		// remove items that are missing from the new set.
		for (let item of cur_items)
			if (!items.has(item))
				e.do_remove_item(item)

		items = [...items]
		return items
	}

	function serialize_items(items) {
		let t = []
		for (let item of items)
			t.push(item.serialize())
		return t
	}

	e.do_init_items = noop // stub

	e.do_remove_item = function(item) { // stub
		item.remove()
	}

	e.set_items = function() {
		e.do_init_items()
	}

	e.prop('items', {store: 'var', convert: diff_items, serialize: serialize_items, default: []})

	// parent-of selectable widget protocol.
	e.child_widgets = function() {
		return e.items.slice()
	}

	// parent-of selectable widget protocol.
	e.replace_child_widget = function(old_item, new_item) {
		let i = e.items.indexOf(old_item)
		let items = [...e.items]
		items[i] = new_item
		e.items = items
	}

	// parent-of selectable widget protocol.
	e.remove_child_widget = function(item) {
		let items = [...e.items]
		items.remove_value(item)
		e.items = items
	}

	if (e.at.length) {
		let html_items = [...e.at]
		e.clear()
		return html_items
	}

}

// ---------------------------------------------------------------------------
// pagelist
// ---------------------------------------------------------------------------

component('x-pagelist', 'Containers', function(e) {

	e.class('x-stretched')

	selectable_widget(e)
	editable_widget(e)
	contained_widget(e)
	serializable_widget(e)
	let html_items = widget_items_widget(e)

	e.prop('tabs_side', {store: 'var', type: 'enum', enum_values: ['top', 'bottom', 'left', 'right'], default: 'top', attr: true})

	e.set_header_width = function(v) {
		e.header.w = v
	}
	e.prop('header_width', {store: 'var', type: 'number'})

	e.selection_bar = div({class: 'x-pagelist-selection-bar'})
	e.add_button = div({class: 'x-pagelist-tab x-pagelist-add-button fa fa-plus', tabindex: 0})
	e.header = div({class: 'x-pagelist-header'}, e.selection_bar, e.add_button)
	e.content = div({class: 'x-pagelist-content x-container x-flex'})
	e.add(e.header, e.content)

	function add_item(item) {
		if (!item._tab) {
			let xbutton = div({class: 'x-pagelist-xbutton fa fa-times'})
			xbutton.hide()
			let title_box = div({class: 'x-pagelist-title'})
			let tab = div({class: 'x-pagelist-tab', tabindex: 0}, title_box, xbutton)
			tab.title_box = title_box
			tab.xbutton = xbutton
			tab.on('pointerdown' , tab_pointerdown)
			tab.on('dblclick'    , tab_dblclick)
			tab.on('keydown'     , tab_keydown)
			title_box.on('input' , update_title)
			title_box.on('blur'  , title_blur)
			xbutton.on('pointerdown', xbutton_pointerdown)
			tab.item = item
			item._tab = tab
			update_tab_title(tab)
		}
		item._tab.x = null
		e.header.add(item._tab)
	}

	// widget-items widget protocol.
	e.do_init_items = function() {

		let sel_tab = e.selected_tab

		e.header.clear()
		for (let item of e.items)
			add_item(item)
		e.header.add(e.selection_bar)
		e.header.add(e.add_button)

		if (sel_tab && sel_tab.parent) // tab was kept
			select_tab(sel_tab)
		else {
			e.selected_tab = null
			select_default_tab()
		}
	}

	// widget-items widget protocol.
	e.do_remove_item = function(item) {
		let tab = item._tab
		tab.remove()
		item.remove()
		item._tab = null
	}

	// widget placeholder protocol.
	let inh_replace_child_widget = e.replace_child_widget
	e.replace_child_widget = function(old_widget, new_widget) {
		let i = e.items.indexOf(old_widget)
		let tab = e.items[i]._tab
		tab.item = new_widget
		new_widget._tab = tab
		e.content.set(tab.item)
		update_tab_title(tab)
		inh_replace_child_widget(old_widget, new_widget)
	}

	function update_tab_title(tab) {
		tab.title_box.set(tab.item.title, 'pre-wrap')
		tab.title_box.title = tab.item.title
		update_selection_bar()
	}

	function update_tab_state(tab, select) {
		tab.xbutton.show(select && (e.can_remove_items || e.widget_editing) || false)
		tab.title_box.contenteditable = select && (e.widget_editing || e.renaming)
	}

	function update_selection_bar() {
		let tab = e.selected_tab
		let b = e.selection_bar
		let sl = e.tabs_side == 'left'
		let sr = e.tabs_side == 'right'
		let st = e.tabs_side == 'top'
		let sb = e.tabs_side == 'bottom'
		let horiz = st || sb
		let hr = e.header.rect()
		let cr = tab && tab.at[0].rect()
		let br = b.rect()
		b.x = cr ? (cr.x - hr.x) + (sr ? cr.w - br.w : 0) : 0
		b.y = cr ? (cr.y - hr.y) + (st ? cr.h - br.h : 0) : 0
		b.w =  horiz ? (cr ? cr.w : 0) : null
		b.h = !horiz ? (cr ? cr.h : 0) : null
		b.show(!!tab)
	}

	e.do_update = function() {
		if (e.selected_tab)
			update_tab_state(e.selected_tab, true)
		e.add_button.show(e.can_add_items || e.widget_editing)
		update_selection_bar()
	}

	e.prop('can_rename_items', {store: 'var', type: 'bool', default: false})
	e.prop('can_add_items'   , {store: 'var', type: 'bool', default: false})
	e.prop('can_remove_items', {store: 'var', type: 'bool', default: false})
	e.prop('can_move_items'  , {store: 'var', type: 'bool', default: true})
	e.prop('auto_focus_first_item', {store: 'var', type: 'bool', default: true})

	function prop_changed(te, k, v) {
		if (k == 'title' && te._tab && te._tab.parent == e.header)
			update_tab_title(te._tab)
	}

	e.on('bind', function(on) {
		if (on)
			select_default_tab()
		document.on('prop_changed', prop_changed, on)
		document.on('layout_changed', update_selection_bar, on)
	})

	function select_tab(tab, focus_tab, enter_editing) {
		if (e.selected_tab != tab) {
			if (e.selected_tab) {
				e.selected_tab.class('selected', false)
				e.fire('close', e.selected_tab.index)
				e.content.clear()
				update_tab_state(e.selected_tab, false)
			}
			e.selected_tab = tab
			if (tab) {
				tab.class('selected', true)
				e.fire('open', tab.index)
				e.content.set(tab.item)
			}
			e.update()
		}
		if (enter_editing) {
			e.widget_editing = true
			return
		}
		if (!e.widget_editing && focus_tab != false && e.auto_focus_first_item) {
			let ff = [...e.content.focusables()].filter(e => e.isinput)[0]
			if (ff)
				ff.focus()
		}
	}

	e.property('selected_index',
		function() {
			return e.selected_tab ? e.selected_tab.index : null
		},
		function(i) {
			let tab = i != null ? e.header.at[clamp(i, 0, e.items.length-1)] : null
			select_tab(tab)
		}
	)

	// selected-item persistent property --------------------------------------

	function format_item(item) {
		return item.title || item.id
	}

	function format_id(id) {
		let item = e.items.find(item => item.id == id)
		return item && item.title || id
	}

	function item_select_editor(...opt) {

		let rows = []
		for (let item of e.items)
			if (item.id)
				rows.push([item.id, item])

		return list_dropdown({
			rowset: {
				fields: [{name: 'id'}, {name: 'item', format: format_item}],
				rows: rows,
			},
			nolabel: true,
			val_col: 'id',
			display_col: 'item',
			mode: 'fixed',
		}, ...opt)

	}

	e.prop('selected_item_id', {store: 'var', text: 'Selected Item',
		editor: item_select_editor, format: format_id})

	function select_default_tab() {
		if (e.selected_item_id) {
			let item = e.items.find(item => item.id == e.selected_item_id)
			if (item)
				select_tab(item._tab)
		} else if (e.items.length) {
			select_tab(url_path_tab() || e.header.at[0])
		}
	}

	// url --------------------------------------------------------------------

	function url_path_level() {
		let parent = e.parent
		let i = 0
		while (parent && parent.iswidget) {
			i += parent.hasclass('x-pagelist')
			parent = parent.parent
		}
		return i
	}

	function item_slug(item) {
		let s = item.slug || item.title
		return s.replace(/[\- ]/g, '-').lower()
	}

	function url_path_tab() {
		let p = url_arg(location.pathname).segments.splice(2)
		let slug = p[url_path_level()]
		for (let item of e.items) {
			if (slug == item_slug(item))
				return item._tab
		}
	}

	// drag-move tabs ---------------------------------------------------------

	live_move_mixin(e)

	e.set_movable_element_pos = function(i, x) {
		let tab = e.items[i]._tab
		tab.x = x - tab._offset_x
	}

	e.movable_element_size = function(i) {
		return e.items[i]._tab.rect().w
	}

	let dragging, drag_mx

	function tab_pointerdown(ev, mx, my) {
		if (this.title_box.contenteditable && !ev.ctrlKey) {
			ev.stopPropagation()
			return
		}
		select_tab(this)
		if (ev.ctrlKey)
			return // bubble-up to enter editing mode.
		this.focus()
		return this.capture_pointer(ev, tab_pointermove, tab_pointerup)
	}

	function tab_pointermove(ev, mx, my, down_mx, down_my) {
		if (!dragging) {
			dragging = e.can_move_items && (abs(down_mx - mx) > 4 || abs(down_my - my) > 4)
			if (dragging) {
				for (let item of e.items)
					item._tab._offset_x = item._tab.ox
				e.move_element_start(this.index, 1, 0, e.items.length)
				drag_mx = down_mx - this.ox
				e.class('moving', true)
				this.class('moving', true)
				update_selection_bar()
			}
		} else {
			e.move_element_update(mx - drag_mx)
			update_selection_bar()
		}
	}

	function tab_pointerup() {
		if (dragging) {

			let over_i = e.move_element_stop()
			let insert_i = over_i - (over_i > this.index ? 1 : 0)
			let items = [...e.items]
			let rem_item = items.remove(this.index)
			items.insert(insert_i, rem_item)
			e.items = items

			e.class('moving', false)
			this.class('moving', false)

			dragging = false
		}
		select_tab(this, true)
		update_selection_bar()
	}

	// key bindings -----------------------------------------------------------

	function set_renaming(renaming) {
		e.renaming = !!renaming
		e.selected_tab.title_box.contenteditable = e.renaming
	}

	function tab_keydown(key, shift, ctrl) {
		if (key == 'F2' && e.can_rename_items) {
			set_renaming(!e.renaming)
			return false
		}
		if (e.widget_editing || e.renaming) {
			if (key == 'Enter') {
				if (ctrl)
					this.title_box.insert_at_caret('<br>')
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
				select_tab(this)
				return false
			}
			if (key == 'ArrowRight' || key == 'ArrowLeft') {
				e.selected_index += (key == 'ArrowRight' ? 1 : -1)
				if (e.selected_tab)
					e.selected_tab.focus()
				return false
			}
		}
	}

	e.set_widget_editing = function(v) {
		if (!v)
			update_title()
	}

	e.add_button.on('click', function() {
		if (e.selected_tab == this)
			return
		e.items = [...e.items, widget_placeholder({title: 'New', module: e.module})]
		return false
	})

	function tab_dblclick() {
		if (e.renaming || !e.can_rename_items)
			return
		set_renaming(true)
		this.focus()
		return false
	}

	function update_title() {
		if (e.selected_tab)
			e.selected_tab.item.title = e.selected_tab.title_box.innerText
		e.update()
	}

	function title_blur() {
		e.widget_editing = false
	}

	function xbutton_pointerdown() {
		select_tab(null)
		e.remove_child_widget(this.parent.item)
		return false
	}

	return {items: html_items}

})

// ---------------------------------------------------------------------------
// split-view
// ---------------------------------------------------------------------------

component('x-split', 'Containers', function(e) {

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	contained_widget(e)

	let html_item1 = e.at[0]
	let html_item2 = e.at[1]
	e.clear()

	e.pane1 = div({class: 'x-split-pane x-container x-flex'})
	e.pane2 = div({class: 'x-split-pane x-container x-flex'})
	e.sizer = div({class: 'x-split-sizer'})
	e.add(e.pane1, e.sizer, e.pane2)

	e.set_item1 = function(ce) { e.pane1.set(ce) }
	e.set_item2 = function(ce) { e.pane2.set(ce) }

	e.prop('item1', {store: 'var', type: 'widget', convert: component.create})
	e.prop('item2', {store: 'var', type: 'widget', convert: component.create})

	let horiz, left

	e.do_update = function() {

		if (!e.item1) e.item1 = widget_placeholder({module: e.module})
		if (!e.item2) e.item2 = widget_placeholder({module: e.module})

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

		document.fire('layout_changed')
	}

	e.prop('orientation', {store: 'var', type: 'enum', enum_values: ['horizontal', 'vertical'], default: 'horizontal', attr: true})
	e.prop('fixed_side' , {store: 'var', type: 'enum', enum_values: ['first', 'second'], default: 'first', attr: true})
	e.prop('resizeable' , {store: 'var', type: 'bool', default: true, attr: true})
	e.prop('fixed_size' , {store: 'var', type: 'number', default: 200, attr: true})
	e.prop('min_size'   , {store: 'var', type: 'number', default: 0})

	// resizing ---------------------------------------------------------------

	let hit, hit_x, mx0, w0, resizing, resist

	e.on('pointermove', function(ev, rmx, rmy) {
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

		return false
	})

	// parent-of selectable widget protocol.
	e.child_widgets = function() {
		return [e.item1, e.item2]
	}

	// parent-of selectable widget protocol.
	e.remove_child_widget = function(item) {
		e.replace_child_widget(item, widget_placeholder({module: e.module}))
	}

	// widget placeholder protocol.
	e.replace_child_widget = function(old_item, new_item) {
		let ITEM = e.item1 == old_item && 'item1' || e.item2 == old_item && 'item2' || null
		e[ITEM] = new_item
		e.update()
	}

	if (html_item1) e.item1 = html_item1
	if (html_item2) e.item2 = html_item2

})

component('x-vsplit', function(e) {
	split.construct(e)
	return {orientation: 'vertical'}
})

// ---------------------------------------------------------------------------
// toaster
// ---------------------------------------------------------------------------

component('x-toaster', function(e) {

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

	function popup_check() {
		this.style.position = 'fixed'
		return true
	}

	e.post = function(text, kind, timeout) {
		let t = tooltip({
			classes: 'x-toaster-message',
			kind: kind,
			icon_visible: true,
			target: e.target,
			text: text,
			side: e.side,
			align: e.align,
			timeout: strict_or(timeout, e.timeout),
			check: popup_check,
		})
		t.on('popup_bind', function(on) {
			if (!on) {
				e.tooltips.delete(this)
				update_stack()
			}
		})
		t.on('close', close)
		e.tooltips.add(t)
		update_stack()
		return t
	}

	e.close_all = function() {
		for (let t of e.tooltips)
			t.target = false
	}

	e.on('bind', function(on) {
		if (!on)
			e.close_all()
	})

})

// global notify function.
{
	let t
	function notify(...args) {
		t = t || toaster({classes: 'x-notify-toaster'})
		t.post(...args)
		print('NOTIFY', args[0])
	}
}

// ---------------------------------------------------------------------------
// action band
// ---------------------------------------------------------------------------

component('x-action-band', 'Input', function(e) {

	e.layout = 'ok:ok cancel:cancel'

	e.init = function() {
		let ct = e
		for (let s of e.layout.names()) {
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
			let bname = name.replaceAll('-', '_').replace(/[^\w]/g, '')
			let btn = e.buttons && e.buttons[bname]
			let btn_sets_text
			if (!(isnode(btn))) {
				if (typeof btn == 'function')
					btn = {action: btn}
				else
					btn = assign_opt({}, btn)
				if (spec.has('primary') || spec.has('ok'))
					btn.primary = true
				btn_sets_text = btn.text != null
				btn = button(btn)
				e.buttons[bname] = btn
			}
			btn.class('x-dialog-button-'+name)
			btn.dialog = e
			if (!btn_sets_text) {
				btn.text = S(bname, name.replace(/[_\-]/g, ' '))
				btn.style['text-transform'] = 'capitalize'
			}
			if (name == 'ok' || spec.has('ok')) {
				btn.on('activate', function() {
					e.ok()
				})
			}
			if (name == 'cancel' || spec.has('cancel')) {
				btn.on('activate', function() {
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

	e.prop('heading', {store: 'var', attr: true}) // because title is taken
	e.prop('xbutton', {store: 'var', type: 'bool', attr: true, default: true})

	e.init = function() {

		e.header  = e.header  || e.$1('header' ) || tag('header', {hidden: true})
		e.content = e.content || e.$1('content') || tag('content')
		e.footer  = e.footer  || e.$1('footer' ) || tag('footer', {hidden: true})
		e.clear()

		e.header  .classes = 'x-dialog-header'
		e.content .classes = 'x-dialog-content'
		e.footer  .classes = 'x-dialog-footer'

		if (e.heading != null) {
			let heading = div({class: 'x-dialog-heading'}, e.heading)
			e.header.add(heading)
			e.header.show()
		}

		if (e.buttons || e.buttons_layout) {
			e.footer.set(action_band({
				layout: e.buttons_layout, buttons: e.buttons
			}))
			e.footer.show()
		}

		e.add(e.header, e.content, e.footer)

		if (e.xbutton) {
			e.x_button = div({class: 'x-dialog-xbutton fa fa-times'})
			e.x_button.on('click', function() {
				e.cancel()
			})
			e.add(e.x_button)
		}
	}

	e.on('bind', function(on) {
		document.on('keydown', doc_keydown, on)
		document.on('keyup', doc_keyup, on)
		document.on('pointerdown', doc_pointerdown, on)
	})

	function doc_keydown(key) {
		if (key == 'Escape' && e.x_button) {
			e.x_button.class('active', true)
		}
	}

	function doc_keyup(key) {
		if (key == 'Escape' && e.x_button && e.x_button.hasclass('active')) {
			e.x_button.class('active', false)
			e.cancel()
		}
	}

	function doc_pointerdown(ev) {
		if (e.positionally_contains(ev.target)) // clicked inside the dialog
			return
		e.cancel()
	}

	e.on('keyup', function(key) {
		if (key == 'Enter') {
			e.ok()
			return false
		}
	})

	e.close = function() {
		e.modal(false)
		if (e.x_button)
			e.x_button.class('active', false)
		e.fire('close')
	}

	e.cancel = function() {
		let cancel_btn = e.$1('x-button[cancel]')
		if (cancel_btn)
			cancel_btn.activate()
		else
			e.close()
	}

	e.ok = function() {
		for (let btn of e.$('x-button[primary]')) {
			if (!(btn.effectively_hidden || btn.effectively_disabled)) {
				btn.activate()
				return
			}
		}
		e.close()
	}

})

// ---------------------------------------------------------------------------
// floating toolbox
// ---------------------------------------------------------------------------

component('x-toolbox', function(e) {

	focusable_widget(e)

	e.istoolbox = true
	e.class('pinned')

	e.pin_button = div({class: 'x-toolbox-button x-toolbox-button-pin fa fa-thumbtack'})
	e.xbutton = div({class: 'x-toolbox-button x-toolbox-button-close fa fa-times'})
	e.title_box = div({class: 'x-toolbox-title'})
	e.titlebar = div({class: 'x-toolbox-titlebar'}, e.title_box, e.pin_button, e.xbutton)
	e.content_box = div({class: 'x-toolbox-content x-container'})
	e.resize_overlay = div({class: 'x-toolbox-resize-overlay'})
	e.add(e.titlebar, e.content_box, e.resize_overlay)

	e.get_text = () => e.title_box.textContent
	e.set_text = function(v) { e.title_box.set(v) }
	e.prop('text', {slot: 'lang'})

	e.prop('side'  , {store: 'var', type: 'enum', enum_values: ['left', 'right'], default: 'right'})
	e.prop('px'    , {store: 'var', type: 'number', slot: 'user'})
	e.prop('py'    , {store: 'var', type: 'number', slot: 'user'})
	e.prop('pw'    , {store: 'var', type: 'number', slot: 'user'})
	e.prop('ph'    , {store: 'var', type: 'number', slot: 'user'})
	e.prop('pinned', {store: 'var', type: 'bool'  , slot: 'user'})

	function is_top() {
		let last = document.body.last
		while (last) {
			if (e == last)
				return true
			else if (last.istoolbox)
				return false
			last = last.prev
		}
	}

	e.do_update = function(opt) {

		e.w = e.pw
		e.h = e.ph

		let r = e.rect()
		let br = document.body.rect()
		let px = clamp(e.px, 0, window.innerWidth  - r.w) - br.x
		let py = clamp(e.py, 0, window.innerHeight - r.h) - br.y

		e.popup(document.body, 'inner-'+e.side, 'start', null, null, null, null, px, py)

		// move to top if the update was user-triggered not layout-triggered.
		if (opt && opt.input == e && !is_top())
			e.index = 1/0

	}

	e.init = function() {
		e.content_box.set(e.content)
		e.hide()
		e.bind(true)
	}

	e.on('focusin', function(ev) {
		// TODO: moving the div loses mouse events!
		e.update({input: e}) // move-to-top
		ev.target.focus()
	})


	let hit_side, down
	e.resize_overlay.on('pointermove', function(ev, mx, my) {
		if (down)
			return
		hit_side = e.resize_overlay.hit_test_sides(mx, my)
		e.resize_overlay.attr('hit_side', hit_side)
	})

	let mx2px = (mx, w) => e.side == 'right'  ? window.innerWidth  - mx - w : mx
	let my2py = (my, h) => e.side == 'bottom' ? window.innerHeight - my - h : my

	e.resize_overlay.on('pointerdown', function(ev, mx, my) {

		e.focus()
		e.update({input: e}) // move-to-top

		if (!hit_side)
			return

		down = true

		let r = e.rect()
		let mx0 = mx
		let my0 = my

		return e.capture_pointer(ev, function(ev, mx, my) {
			let dx = mx - mx0
			let dy = my - my0
			e.begin_update()
			e.update({input: e})
			let x1 = r.x1
			let y1 = r.y1
			let x2 = r.x2
			let y2 = r.y2
			if (hit_side.includes('top'   )) y1 += dy
			if (hit_side.includes('bottom')) y2 += dy
			if (hit_side.includes('right' )) x2 += dx
			if (hit_side.includes('left'  )) x1 += dx
			let w = x2 - x1
			let h = y2 - y1
			e.px = mx2px(x1, w)
			e.py = my2py(y1, h)
			e.pw = w
			e.ph = h
			e.end_update()
		}, function() {
			down = false
		})

	},)

	e.titlebar.on('pointerdown', function(ev, mx, my) {

		e.focus()
		e.update({input: e}) // move-to-top

		let first_focusable = e.content_box.focusables()[0]
		if (first_focusable)
			first_focusable.focus()

		if (ev.target != e.titlebar)
			return

		down = true
		let r = e.rect()
		let mx0 = mx
		let my0 = my
		let dx = mx - r.x
		let dy = my - r.y
		let dragging

		return this.capture_pointer(ev, function(ev, mx, my) {
			if (!dragging) {
				if (max(abs(mx - mx0), abs(my - my0)) >= 20 || (ev.shiftKey || ev.ctrlKey))
					dragging = true
				else
					return
			}
			mx -= dx
			my -= dy
			e.begin_update()
			e.update({input: e})
			e.px = mx2px(mx, r.w)
			e.py = my2py(my, r.h)
			e.end_update()
		}, function() {
			down = false
		})

	})

	e.xbutton.on('pointerup', function() {
		e.hide()
		return false
	})

	e.pin_button.on('pointerup', function() {
		e.class('pinned', !e.hasclass('pinned'))
		return false
	})

	e.on('resize', function() {
		document.fire('layout_changed', e)
	})

})

// ---------------------------------------------------------------------------
// progress
// ---------------------------------------------------------------------------

component('x-progress', function() {

})

// ---------------------------------------------------------------------------
// slides
// ---------------------------------------------------------------------------

component('x-slides', 'Containers', function(e) {

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	contained_widget(e)
	let html_items = widget_items_widget(e)

	e.do_init_items = function() {
		e.clear()
		for (let ce of e.items) {
			ce.class('x-slide', true)
			e.add(ce)
		}
		e.set_selected_index(e.selected_index)
	}

	e.set_selected_index = function(i1, i0) {
		let e0 = e.items[i0]
		let e1 = e.items[i1]
		if (e0) e0.class('x-slide-selected', false)
		if (e1) e1.class('x-slide-selected', true)
		if (e1) e.fire('slide_changed', i1)
	}

	e.prop('selected_index', {store: 'var'})

	e.property('selected_item', () => e.items[e.selected_index])

	e.slide = function(i) {
		e.selected_index = i
		if (e.selected_item)
			e.selected_item.focus_first_input_element()
	}

	return {items: html_items}

})


// ---------------------------------------------------------------------------
// markdown widget
// ---------------------------------------------------------------------------

{
let md
component('x-md', function(e) {

	md = md || markdownit()
		.use(MarkdownItIndentedTable)

	e.unsafe_html = md.render_string(e.html)

})}

// ---------------------------------------------------------------------------
// page navigation widget
// ---------------------------------------------------------------------------

component('x-pagenav', function(e) {

	e.prop('page', {store: 'var', type: 'number', attr: true, default: 1})
	e.prop('page_size', {store: 'var', type: 'number', attr: true, default: 100})
	e.prop('item_count', {store: 'var', type: 'number', attr: true})

	property(e, 'page_count', () => ceil(e.item_count / e.page_size))

	e.page_url = noop

	function cur_page() {
		return clamp(e.page || 1, 1, e.page_count)
	}

	e.page_button = function(page, text, title, href) {
		let b = button()
		b.class('x-pagenav-button')
		b.class('selected', page == cur_page())
		b.bool_attr('disabled', page >= 1 && page <= e.page_count && page != cur_page() || null)
		b.title = or(title, or(text, S('page', 'Page {0}', page)))
		b.href = href !== false ? e.page_url(page) : null
		b.set(or(text, page))
		return b
	}

	e.nav_button = function(offset) {
		return e.page_button(cur_page() + offset,
			offset > 0 ?
				S('next_page_button_text', 'Next →') :
				S('previous_page_button_text', '← Previous'),
			offset > 0 ?
				S('next_page', 'Next') :
				S('previous_page', 'Previous'),
			false
		)
	}

	e.do_update = function() {
		e.clear()
		e.add(e.nav_button(-1))
		let n = e.page_count
		let p = cur_page()
		let dotted
		for (let i = 1; i <= n; i++) {
			if (i == 1 || i == n || (i >= p-1 && i <= p+1)) {
				e.add(e.page_button(i))
				dotted = false
			} else if (!dotted) {
				e.add(' ... ')
				dotted = true
			}
		}
		e.add(e.nav_button(1))
	}

})


// ---------------------------------------------------------------------------
// richtext
// ---------------------------------------------------------------------------

component('x-richtext', function(e) {

	e.class('x-stretched')

	selectable_widget(e)
	contained_widget(e)
	serializable_widget(e)
	editable_widget(e)

	e.content_box = div({class: 'x-richtext-content'})
	e.add(e.content_box)

	// content property

	e.get_content = function() {
		return e.content_box.html
	}

	e.set_content = function(s) {
		e.content_box.html = s
		e.fire('content_changed')
	}
	e.prop('content', {slot: 'lang'})

	// widget editing ---------------------------------------------------------

	e.set_widget_editing = function(v) {
		if (!v) return
		richtext_widget_editing(e)
		e.set_widget_editing = function(v) {
			e.editing = v
		}
		e.editing = true
	}

})

// ---------------------------------------------------------------------------
// richtext widget editing mixin
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
		button.attr('tabindex', '-1')
		button.html = action.icon || ''
		button.classes = action.icon_class
		button.on('pointerdown', press_button)
		let update_button
		if (action.state) {
			update_button = function() {
				button.class('selected', action.state())
			}
			e.content_box.on('keyup', update_button)
			e.content_box.on('pointerup', update_button)
		}
		button.on('click', function() {
			button_pressed = false
			if (action.result()) {
				e.content_box.focus()
			}
			if (update_button)
				update_button()
			return false
		})
		e.actionbar.add(button)
	}

	e.actionbar.class('x-richtext-actionbar-embedded', !!e.focus_box)
	if (e.focus_box) // is richedit
		e.focus_box.insert(0, e.actionbar)
	else
		e.actionbar.popup(e, 'top', 'left')

	e.content_box.on('input', function(ev) {
		let e1 = ev.target.first
		if (e1 && e1.nodeType == 3)
			exec('formatBlock', '<p>')
		else if (e.content_box.html == '<br>')
			e.content_box.clear()
		e.fire('content_changed')
	})

	e.content_box.on('keydown', function(key, shift, ctrl, alt, ev) {
		if (key === 'Enter')
			if (document.queryCommandValue('formatBlock') == 'blockquote')
				runafter(0, function() { exec('formatBlock', '<p>') })
			else if (document.queryCommandValue('formatBlock') == 'pre')
				runafter(0, function() { exec('formatBlock', '<br>') })
		ev.stopPropagation()
	})

	e.content_box.on('keypress', function(key, shift, ctr, alt, ev) {
		ev.stopPropagation()
	})

	e.content_box.on('pointerdown', function(ev) {
		if (!e.widget_editing)
			return
		if (!ev.ctrlKey)
			ev.stopPropagation() // prevent exit editing.
	})

	e.actionbar.on('pointerdown', function(ev) {
		ev.stopPropagation() // prevent exit editing.
	})

	e.set_editing = function(v) {
		e.content_box.contentEditable = v
		e.actionbar.show(v)
	}
	e.prop('editing', {store: 'var', private: true})

	e.content_box.on('blur', function() {
		if (!button_pressed)
			e.widget_editing = false
	})

}

}
