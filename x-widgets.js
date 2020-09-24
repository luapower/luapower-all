/*

	X-WIDGETS: Model-driven live-editable web components in JavaScript.
	Written by Cosmin Apreutesei. Public Domain.

*/

DEBUG_ATTACH_TIME = false

/* ---------------------------------------------------------------------------
// creating & setting up web components
// ---------------------------------------------------------------------------
uses:
	bind_events <- t|f
publishes:
	e.iswidget: t
	e.type
	e.initialized: t|f
	e.attached: t|f
	e.bind(t|f)
	calls:
	e.init()
fires:
	e.'bind' (t|f)
	document.'global_attached', document.'global_detached'
	document.'widget_attached', document.'widget_detached'
------------------------------------------------------------------------------
NOTE: the only reason for using this web components "technology" instead
of creating normal elements is because of connectedCallback and
disconnectedCallback for which there are no events in built-in elements,
and we use those events to solve the so-called "lapsed listener problem"
(a proper iterable weak hash map would be a better way to solve this but
alas, the web people could't get that one right either).
--------------------------------------------------------------------------- */

let repl_empty_str = v => repl(v, '', undefined)

bind_events = true

// component(tag, cons) -> create({option: value}) -> element.
function component(tag, cons) {

	let type = tag.replace(/^[^\-]+\-/, '').replace(/\-/g, '_')

	let cls = class extends HTMLElement {

		constructor() {
			super()
			this.initialized = null // for log_add_event().
			this.attached = false
		}

		connectedCallback() {
			if (this.attached)
				return
			if (!this.isConnected)
				return
			// elements created by the browser must be initialized on first
			// attach as they aren't allowed to create children or set
			// attributes in the constructor.
			init(this)
			this.bind(true)
		}

		disconnectedCallback() {
			this.bind(false)
		}

		bind(on) {
			assert(typeof on == 'boolean')
			if (!bind_events)
				return
			if (on) {
				if (this.attached)
					return
				let t0 = DEBUG_ATTACH_TIME && time()

				this.attached = true
				this.begin_update()
				this.fire('bind', true)
				if (this.id)
					document.fire('global_attached', this, this.id)
				if (this.gid)
					document.fire('widget_attached', this)
				this.end_update()

				if (DEBUG_ATTACH_TIME) {
					let t1 = time()
					let dt = (t1 - t0) * 1000
					if (dt > 10)
						print((dt).toFixed(0).padStart(3, ' ')+'ms', this.debug_name())
				}
			} else {
				if (!this.attached)
					return
				this.attached = false
				this.fire('bind', false)
				if (this.id)
					document.fire('global_detached', this, this.id)
				if (this.gid)
					document.fire('widget_detached', this)
			}
		}

		debug_name(prefix) {
			prefix = (prefix && prefix + ' < ' || '') + this.type
				+ (this.id || this.gid != null ? ' ' + (this.id || this.gid) : '')
			let p = this; do { p = p.popup_target || p.parent } while (p && !p.debug_name)
			if (!(p && p.debug_name))
				return prefix
			return p.debug_name(prefix)
		}

	}

	customElements.define(tag, cls)

	function init(e, opt) {
		if (e.initialized)
			return
		let assign_gid = opt.gid === true
		if (assign_gid) { // assign new gid.
			opt.gid = xmodule.next_gid(opt.module)
		} else if (opt.gid && !opt.type) { // put prop_vals on top of instance options.
			update(opt, xmodule.prop_vals(opt.gid))
		}
		component_prop_system(e, opt.props)
		component_deferred_updating(e)
		e.iswidget = true
		e.type = type
		e.init = noop
		cons(e)
		e.initialized = false
		e.begin_update()
		e.xmodule_updating_props = true
		for (let k in opt)
			e.set_prop(k, opt[k])
		e.xmodule_updating_props = false
		if (e.gid)
			xmodule.init_widget(e)
		e.end_update()
		e.initialized = true
		e.init()
		if (assign_gid)
			document.fire('prop_changed', e, 'type', e.type, undefined, null)
	}

	function create(...args) {
		let e = new cls()
		init(e, update({}, ...args))
		return e
	}

	create.class = cls
	create.construct = cons

	component.types[type] = create
	window[type] = create

	return create
}

component.types = {} // {type -> create}

component.create = function(e, e0) {
	if (e instanceof HTMLElement)
		return e
	if (typeof e == 'string') { // e is a gid
		if (e0 && e0.gid == e)
			return e0  // already created (called from a prop's `convert()`).
		e = xmodule.prop_vals(e) // to get e.type
	}
	let create = component.types[e.type]
	return create && create(e)
}

/* ---------------------------------------------------------------------------
// component partial deferred updating mixin
// ---------------------------------------------------------------------------
publishes:
	e.updating
	e.begin_update()
	e.end_update()
	e.update()
calls:
	e.do_update()
--------------------------------------------------------------------------- */

let component_deferred_updating = function(e) {

	e.updating = 0

	e.begin_update = function() {
		if (!e.attached)
			return
		e.updating++
	}

	e.end_update = function() {
		if (!e.attached)
			return
		assert(e.updating)
		e.updating--
		if (!e.updating)
			if (invalid)
				e.update()
	}

	e.do_update = noop

	let invalid, opt

	e.update = function(opt1) {
		invalid = true
		if (opt1)
			if (opt)
				update(opt, opt1)
			else
				opt = opt1
		if (e.updating)
			return
		if (!e.attached)
			return
		let opt_arg = opt
		opt = null
		e.do_update(opt_arg)
		invalid = false
	}

}

/* ---------------------------------------------------------------------------
// component property system mixin
// ---------------------------------------------------------------------------
uses:
	e.property(name, get[, set])
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

/* TODO: use it or scrape it.
method(HTMLElement, 'override', function(method, func) {
	let inherited = this[method] || noop
	this[method] = function(...args) {
		return func(inherited, ...args)
	}
})
*/

let fire_prop_changed = function(e, prop, v1, v0, slot) {
	document.fire('prop_changed', e, prop, v1, v0, slot)
}

global_widget_resolver = memoize(function(type) {
	let ISTYPE = 'is'+type
	return function(name) {
		let e = window[name]
		return isobject(e) && e.attached && e[ISTYPE] && e.can_select_widget ? e : null
	}
})

function component_prop_system(e, iprops) {

	/* TODO: use this or scrape it
	e.bind_ext = function(te, ev, f) {
		e.on('bind', function(on) { te.on(ev, f, on) })
	}
	*/

	e.property = function(prop, getter, setter) {
		property(this, prop, {get: getter, set: setter})
	}

	e.props = {}

	e.prop = function(prop, opt) {
		opt = opt || {}
		update(opt, e.props[prop], iprops && iprops[prop]) // class & instance overrides
		let getter = 'get_'+prop
		let setter = 'set_'+prop
		let type = opt.type
		opt.name = prop
		let convert = opt.convert || return_arg
		let priv = opt.private
		if (!e[setter])
			e[setter] = noop
		let prop_changed = fire_prop_changed
		let slot = opt.slot
		let dv = opt.default

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
				e[setter](v1, v0)
				if (!priv)
					prop_changed(e, prop, v1, v0, slot)
			}
		} else if (opt.store == 'attr') {  // for attr-based styling
			let attr = prop.replace(/_/g, '-')
			if (type == 'bool') {
				dv = dv || false
				if (dv)
					e.attr(attr, true)
				function get() {
					return e.attrval(attr) || false
				}
				function set(v1) {
					let v0 = get()
					v1 = convert(v1, v0) && true || false
					if (v1 === v0)
						return
					e.attr(attr, v1)
					e[setter](v1, v0)
					if (!priv)
						prop_changed(e, prop, v1, v0, slot)
				}
			} else {
				if (dv != null)
					e.attr(attr, dv)
				function get() {
					return e.attrval(attr)
				}
				function set(v1) {
					let v0 = get()
					v1 = convert(v1, v0)
					if (v1 === v0)
						return
					e.attr(attr, v1)
					e[setter](v1, v0)
					if (!priv)
						prop_changed(e, prop, v1, v0, slot)
				}
			}
		} else if (opt.style) {
			let style = opt.style
			let format = opt.style_format || return_arg
			let parse  = opt.style_parse  || type == 'number' && num || repl_empty_str
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
				e[setter](v, v0)
				if (!priv)
					prop_changed(e, prop, v, v0, slot)
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
				e[setter](v, v0)
				if (!priv)
					prop_changed(e, prop, v, v0, slot)
			}
		}

		// gid-based dynamic binding.

		if (opt.bind_gid) {
			let resolve = opt.resolve || xmodule.resolve
			let GID = prop
			let REF = opt.bind_gid
			function widget_attached(te) {
				if (e[GID] == te.gid)
					e[REF] = te
			}
			function widget_detached(te) {
				if (e[GID] == te.gid)
					e[REF] = null
			}
			function bind(on) {
				e[REF] = on ? resolve(e[GID]) : null
				document.on('widget_attached', widget_attached, on)
				document.on('widget_detached', widget_detached, on)
			}
			function gid_changed(gid1, gid0) {
				if (e.attached)
					e[REF] = resolve(gid1)
				if ((gid1 != null) != (gid0 != null)) {
					e.on('bind', bind, gid1 != null)
				}
			}
			prop_changed = function(e, k, v1, v0, slot) {
				fire_prop_changed(e, k, v1, v0, slot)
				if (k == GID)
					gid_changed(v1, v0)
			}
			if (e[GID] != null)
				gid_changed(e[GID])
		}

		// id-based dynamic binding.

		if (opt.bind_id) {
			let resolve = opt.resolve || global_widget_resolver(type)
			let NAME = prop
			let REF = opt.bind_id
			function global_changed(te, name, last_name) {
				// NOTE: changing the name from something to nothing
				// will unbind dependants forever.
				if (e[NAME] == last_name)
					e[NAME] = name
			}
			function global_attached(te, name) {
				if (e[NAME] == name)
					e[REF] = te
			}
			function global_detached(te, name) {
				if (e[REF] == te)
					e[REF] = null
			}
			function bind(on) {
				e[REF] = on ? resolve(e[NAME]) : null
				document.on('global_changed' , global_changed, on)
				document.on('global_attached', global_attached, on)
				document.on('global_detached', global_detached, on)
			}
			function name_changed(name, last_name) {
				if (e.attached)
					e[REF] = resolve(name)
				if ((name != null) != (last_name != null)) {
					e.on('bind', bind, name != null)
				}
			}
			prop_changed = function(e, k, v1, v0, slot) {
				fire_prop_changed(e, k, v1, v0, slot)
				if (k == NAME)
					name_changed(v1, v0)
			}
			if (e[NAME] != null)
				name_changed(e[NAME])
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

	e.props.id = {
		name: 'id',
		unique: true, // don't show in prop inspector when selecting multiple objects.
		default: '',
		validate: function(id) {
			return window[id] === undefined || window[id] == e || 'id already in use'
		},
	}

	override_property_setter(e, 'id', function(inherited, id) {
		if (!id) id = ''
		let id0 = e.id
		inherited.call(this, id)
		if (id === id0)
			return
		document.fire('prop_changed', e, 'id', id, id0, null)
		document.fire('global_changed', this, id, id0)
	})

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

	pagelist_item_widget(e)

	e.prop('pos_x'  , {style: 'grid-column-start' , type: 'number', default: 1})
	e.prop('pos_y'  , {style: 'grid-row-start'    , type: 'number', default: 1})
	e.prop('span_x' , {style: 'grid-column-end'   , type: 'number', default: 1, style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('span_y' , {style: 'grid-row-end'      , type: 'number', default: 1, style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('align_x', {style: 'justify-self'      , type: 'enum', enum_values: ['start', 'end', 'center', 'stretch'], default: 'center'})
	e.prop('align_y', {style: 'align-self'        , type: 'enum', enum_values: ['start', 'end', 'center', 'stretch'], default: 'center'})

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
			side = handle.attrval('side')

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
		if (e.gid)
			return e.gid
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
	e.focusable
--------------------------------------------------------------------------- */

function focusable_widget(e, fe) {
	fe = fe || e

	let focusable = true
	fe.attr('tabindex', 0)

	e.set_tabindex = function(i) {
		fe.attr('tabindex', focusable ? i : -1)
	}
	e.prop('tabindex', {store: 'var', type: 'number', default: 0})

	e.property('focusable', () => focusable, function(v) {
		v = !!v
		if (v == focusable) return
		focusable = v
		e.set_tabindex(e.tabindex)
	})
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
			for (s of c0.split(/\s+/))
				this.class(s, false)
		if (c1)
			for (s of c1.split(/\s+/))
				this.class(s, true)
	}
	e.prop('css_classes', {store: 'var'})

}

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
	e.do_update(opt)
calls:
	e.do_update_val(val, ev)
	e.do_update_error(err, ev)
	e.do_error_tooltip_check()
	e.to_val(v) -> v
	e.from_val(v) -> v
--------------------------------------------------------------------------- */

function val_widget(e, enabled_without_nav) {

	selectable_widget(e)
	cssgrid_item_widget(e)
	serializable_widget(e)

	// nav dynamic binding ----------------------------------------------------

	function init_field() {
		e.field = nav && nav.all_fields[col] || null
	}

	function init_val() {
		if (initial_val !== undefined) {
			let v = initial_val
			initial_val = undefined
			e.reset_val(v, {validate: true})
		}
	}

	function val_changed() {
		e.update()
	}

	function loaded() {
		init_field()
		e.update()
	}

	function label_changed() {
		e.update()
	}

	function cell_state_changed(prop, val, ev) {
		if (e.updating)
			return
		if (prop == 'input_val')
			e.do_update_val(val, ev)
		else if (prop == 'val')
			e.fire('val_changed', val, ev)
		else if (prop == 'cell_error') {
			e.invalid = val != null
			e.class('invalid', e.invalid)
			e.do_update_error(val, ev)
		} else if (prop == 'cell_modified')
			e.class('modified', val)
	}

	function bind_nav(nav, col, on) {
		if (!(nav && col != null))
			return
		nav.on('focused_row_changed', val_changed, on)
		nav.on('focused_row_cell_state_changed_for_'+col, cell_state_changed, on)
		nav.on('display_vals_changed_for_'+col, val_changed, on)
		nav.on('loaded', loaded, on)
		nav.on('col_text_changed_for_'+col, label_changed, on)
	}

	let field_opt
	e.on('bind', function(on) {
		if (on) {
			if (e.field && !e.standalone) {
				field_opt = e.field
				e.standalone = true
			}
			if (e.standalone) {
				e.nav = global_val_nav()
				e.field = e.nav.add_field(field_opt)
				e.col = e.field.name
				init_val()
			} else {
				init_field()
				bind_nav(nav, col, true)
			}
		} else {
			bind_nav(nav, col, false)
			if (e.standalone)
				e.nav.remove_field(e.field)
			e.field = null
		}
	})

	function set_nav_col(nav1, nav0, col1, col0) {
		if (e.attached) {
			bind_nav(nav0, col0, false)
			bind_nav(nav1, col1, true)
			init_field()
		}
		e.update()
	}

	let nav
	e.set_nav = function(nav1, nav0) {
		assert(nav1 != e)
		nav = nav1
		set_nav_col(nav1, nav0, col, col)
	}
	e.prop('nav', {store: 'var', private: true})
	e.prop('nav_gid' , {store: 'var', bind_gid: 'nav', type: 'nav'})

	let col
	e.set_col = function(col1, col0) {
		col = col1
		set_nav_col(nav, nav, col1, col0)
	}
	e.prop('col', {store: 'var', type: 'col', col_nav: () => e.nav})

	// model ------------------------------------------------------------------

	e.to_val = function(v) { return v; }
	e.from_val = function(v) { return v; }

	e.property('row', () => nav && nav.focused_row)

	function get_val() {
		let row = e.row
		return row && e.field ? nav.cell_val(row, e.field) : null
	}
	let initial_val
	e.set_val = function(v, ev) {
		v = e.to_val(v)
		if (v === undefined)
			v = null
		if (nav && e.field)
			nav.set_cell_val(e.row, e.field, v, ev)
		else
			initial_val = v
	}
	e.property('val', get_val, e.set_val)

	e.reset_val = function(v, ev) {
		v = e.to_val(v)
		if (v === undefined)
			v = null
		if (e.row && e.field)
			nav.reset_cell_val(e.row, e.field, v, ev)
	}

	e.property('input_val', function() {
		let row = e.row
		return row && e.field ? e.from_val(nav.cell_input_val(e.row, e.field)) : null
	})

	e.property('error', function() {
		let row = e.row
		return row && e.field ? nav.cell_error(row, e.field) : undefined
	})

	e.property('modified', function() {
		let row = e.row
		return row && e.field ? nav.cell_modified(row, e.field) : false
	})

	e.display_val = function() {
		if (!e.field)
			return 'no field'
		let row = e.row
		if (!row)
			return 'no row'
		return nav.cell_display_val(row, e.field)
	}

	// view -------------------------------------------------------------------

	let enabled = true

	e.do_update = function() {
		init_field()
		enabled = !!(enabled_without_nav || (e.row && e.field))
		e.class('disabled', !enabled)
		e.focusable = enabled
		cell_state_changed('input_val', e.input_val)
		cell_state_changed('val', e.val)
		cell_state_changed('cell_error', e.error)
		cell_state_changed('cell_modified', e.modified)
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
// tooltip
// ---------------------------------------------------------------------------

component('x-tooltip', function(e) {

	e.classes = 'x-widget x-tooltip'

	e.text_div = div({class: 'x-tooltip-text'})
	e.content = div({class: 'x-tooltip-content'}, e.text_div)
	e.pin = div({class: 'x-tooltip-tip'})
	e.add(e.content, e.pin)

	e.prop('target'      , {store: 'var', private: true})
	e.prop('target_name' , {store: 'var', type: 'element', bind: 'target'})
	e.prop('text'        , {store: 'var', slot: 'lang'})
	e.prop('side'        , {store: 'attr', type: 'enum', enum_values: ['top', 'bottom', 'left', 'right', 'inner-top', 'inner-bottom', 'inner-left', 'inner-right', 'inner-center'], default: 'top'})
	e.prop('align'       , {store: 'attr', type: 'enum', enum_values: ['center', 'start', 'end'], default: 'center'})
	e.prop('kind'        , {store: 'attr', type: 'enum', enum_values: ['default', 'info', 'error'], default: 'default'})
	e.prop('px'          , {store: 'var', type: 'number', default: 0})
	e.prop('py'          , {store: 'var', type: 'number', default: 0})
	e.prop('timeout'     , {store: 'var'})
	e.prop('close_button', {store: 'var', type: 'bool'})

	e.init = function() {
		e.update({reset_timer: true})
		e.bind(true)
	}

	e.popup_target_updated = function(target) {
		let visible = !!(!e.check || e.check(target))
		e.class('visible', visible)
	}

	e.close = function() {
		if (e.fire('closed'))
			e.target = null
	}

	function close() { e.close() }

	e.do_update = function(opt) {
		if (e.close_button && !e.xbutton) {
			e.xbutton = div({class: 'x-tooltip-xbutton fa fa-times'})
			e.xbutton.on('pointerup', close)
			e.content.add(e.xbutton)
		} else if (e.xbutton) {
			e.xbutton.show(e.close_button)
		}
		e.popup(e.target, e.side, e.align, e.px, e.py)
		if (opt && opt.reset_timer)
			reset_timeout_timer()
	}

	function update() { e.update() }
	e.set_target = function() { e.update({reset_timer: true}) }
	e.set_side   = update
	e.set_align  = update
	e.set_kind   = update
	e.set_px     = update
	e.set_py     = update
	e.set_close_button = update

	e.set_text = function(s) {
		e.text_div.set(s, 'pre-wrap')
		e.update({reset_timer: true})
	}

	let remove_timer = timer(close)
	function reset_timeout_timer() {
		if (!e.initialized)
			return
		let t = e.timeout
		if (t == 'auto')
			t = clamp((e.text || '').length / (tooltip.reading_speed / 60), 1, 10)
		else
			t = num(t)
		remove_timer(t)
	}

	e.property('visible',
		function()  { return e.style.display != 'none' },
		function(v) { e.show(v); e.update() }
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
	e.prop('text', {store: 'var', default: 'OK', slot: 'lang'})

	e.set_icon = function(v) {
		if (typeof v == 'string')
			e.icon_div.attr('class', 'x-button-icon fa '+v)
		else
			e.icon_div.set(v)
		e.icon_div.show(!!v)
	}
	e.prop('icon', {store: 'var', type: 'icon'})

	e.prop('primary', {store: 'attr', type: 'bool', default: false})

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

	e.on('pointerdown', function(ev) {
		if (e.widget_editing)
			return
		e.focus()
		return this.capture_pointer(ev, null, function() {
			if(e.action)
				e.action()
			e.fire('action')
		})
	})

	// widget editing ---------------------------------------------------------

	e.set_widget_editing = function(v) {
		e.text_div.contenteditable = v
		if (!v)
			e.text = e.text_div.innerText
	}

	e.on('pointerdown', function(ev) {
		if (e.widget_editing && ev.target != e.text_div) {
			e.text_div.focus()
			e.text_div.select_all()
			return this.capture_pointer(ev)
		}
	})

	function prevent_bubbling(ev) {
		if (e.widget_editing)
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

	e.classes = 'x-widget x-radiogroup'

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

	e.classes = 'x-widget x-input'

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
	e.classes = 'x-spin-input'

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
	e.classes = 'x-widget x-slider'

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

	val_widget(e)
	input_widget(e)
	focusable_widget(e)

	e.classes = 'x-widget x-input x-dropdown'

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

	e.init = function() {
		e.picker.dropdown = e
		e.picker.nav = e.nav
		e.picker.col = e.col
		e.picker.class('picker', true)
		e.picker.can_select_widget = false
		e.picker.on('val_picked', picker_val_picked)
		e.picker.on('keydown'   , picker_keydown)

		let picker_do_update = e.picker.do_update
		e.picker.do_update = function(opt) {
			picker_do_update(opt)
			let text = e.picker.dropdown_display_val()
			if (text == null)
				text = e.display_val()
			let empty = text === ''
			e.val_div.class('empty', empty)
			e.val_div.class('null', false)
			e.inner_label_div.class('empty', empty)
			e.val_div.set(empty ? H('&nbsp;') : text)
		}

	}

	e.on('bind', function(on) {
		if (on) {
			document.on('pointerdown'     , document_pointerdown, on)
			document.on('rightpointerdown', document_pointerdown, on)
			document.on('stopped_event'   , document_stopped_event, on)
			e.picker.bind(true)
		} else {
			e.close()
			e.picker.bind(false)
			e.picker.popup(false)
		}
	})

	// val updating

	e.do_update_val = function(v, ev) {
		// nothing: wait for when the picker updates itself
		// and use picker-provided value.
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
// nav dropdown mixin
// ---------------------------------------------------------------------------

function nav_dropdown_widget(e) {

	dropdown.construct(e)

	let set_nav = e.set_nav
	e.set_nav = function(v, ...args) {
		set_nav(v, ...args)
		if (!e.initialized) return
		e.picker.nav = v
	}

	let set_col = e.set_col
	e.set_col = function(v, ...args) {
		set_col(v, ...args)
		if (!e.initialized) return
		e.picker.col = v
	}

	e.set_val_col = function(v) {
		if (!e.initialized) return
		e.picker.val_col = v
	}
	e.prop('val_col', {store: 'var'})

	e.set_display_col = function(v) {
		if (!e.initialized) return
		e.picker.display_col = v
	}
	e.prop('display_col', {store: 'var'})

	e.set_rowset_name = function(v) {
		if (!e.initialized) return
		e.picker.rowset_name = v
	}
	e.prop('rowset_name', {store: 'var', type: 'rowset'})

}

// ---------------------------------------------------------------------------
// calendar widget
// ---------------------------------------------------------------------------

component('x-calendar', function(e) {

	focusable_widget(e)
	val_widget(e)
	e.classes = 'x-widget x-focusable x-calendar'

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
	e.picker = calendar()
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
		tr.on('pointerdown' , item_pointerdown)
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

	e.popup_target_bind = function(target, on) {
		document.on('pointerdown', document_pointerdown, on)
		document.on('rightpointerdown', document_pointerdown, on)
		document.on('stopped_event', document_stopped_event, on)
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

	override(e, 'popup', function(inherited, target, side, align, x, y, select_first_item) {
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

	function click_item(tr) {
		let item = tr.item
		if ((item.action || item.checked != null) && item.enabled != false) {
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
// widget placeholder
// ---------------------------------------------------------------------------

component('x-widget-placeholder', function(e) {

	e.props.align_x = {default: 'stretch'}
	e.props.align_y = {default: 'stretch'}

	serializable_widget(e)
	selectable_widget(e)
	cssgrid_item_widget(e)

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
		['CD', 'color_dropdown', true],
		['ID', 'icon_dropdown', true],
		['B', 'button'],
	]

	function create_btn_action() {
		let pe = e.parent_widget
		let te = component.create({type: this.type, gid: true, module: pe.module || e.module})
		if (pe)
			pe.replace_child_widget(e, te)
		else {
			let pe = e.parent
			pe.replace(e, te)
			root_widget = te
		}
		te.focus()
	}

	function create_widget_buttons(widgets) {
		e.clear()
		let i = 1
		for (let [s, type, sep] of widgets) {
			let btn = button({text: s, title: type, pos_x: i++})
			btn.class('x-widget-placeholder-button')
			if (sep)
				btn.style['margin-right'] = '.5em'
			e.add(btn)
			btn.can_select_widget = false
			btn.type = type
			btn.action = create_btn_action
		}
	}

	e.on('bind', function(on) {
		if (on) {
			widgets = stretched_widgets
			let pe = e.parent_widget
			if (pe && pe.accepts_form_widgets)
				widgets = [].concat(widgets, form_widgets)
			create_widget_buttons(widgets)
		}
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
//   e.do_init_items(items)
//   e.do_remove_item(item)
// ---------------------------------------------------------------------------

widget_items_widget = function(e) {

	function same_items(t, items) {
		if (t.length != items.length)
			return false
		for (let i = 0; i < t.length; i++) {
			let gid0 = items[i].gid
			let gid1 = typeof t[i] == 'string' ? t[i] : t[i].gid
			if (gid1 != gid0)
				return false
		}
		return true
	}

	function diff_items(t, cur_items) {

		if (typeof t == 'string')
			t = t.split(/\s+/)

		if (same_items(t, cur_items))
			return cur_items

		// diff between t and cur_items keyed on gid or item identity.

		// map current items by identity and by gid.
		let cur_set = new Set()
		let cur_by_gid = new Map()
		for (let item of cur_items) {
			cur_set.add(item)
			if (item.gid)
				cur_by_gid.set(item.gid, item)
		}

		// create new items or reuse-by-gid.
		let items = new Set()
		for (let v of t) {
			// v is either an item from cur_items, a gid, or the attrs for a new item.
			let cur_item = cur_set.has(v) ? v : cur_by_gid.get(v)
			items.add(component.create(v, cur_item))
		}

		// remove items that are missing from the new set.
		for (let item of cur_items)
			if (!items.has(item))
				e.do_remove_item(item)

		items = [...items]

		e.do_init_items(items)

		return items
	}

	function serialize_items(items) {
		let t = []
		for (let item of items)
			t.push(item.serialize())
		return t
	}

	e.set_items = e.update

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
		e.items = [...e.items].remove_value(item)
	}

	// widget-items widget protocol.
	e.do_remove_item = function(item) {
		item.remove()
	}

}

// ---------------------------------------------------------------------------
// pagelist
// ---------------------------------------------------------------------------

component('x-pagelist', function(e) {

	e.classes = 'x-widget x-pagelist'

	e.props.align_x = {default: 'stretch'}
	e.props.align_y = {default: 'stretch'}

	selectable_widget(e)
	editable_widget(e)
	cssgrid_item_widget(e)
	serializable_widget(e)
	widget_items_widget(e)

	e.prop('tabs_side', {store: 'attr', type: 'enum', enum_values: ['top', 'bottom', 'left', 'right'], default: 'top'})

	e.set_header_width = function(v) {
		e.header.w = v
	}
	e.prop('header_width', {store: 'var', type: 'number'})

	e.selection_bar = div({class: 'x-pagelist-selection-bar'})
	e.add_button = div({class: 'x-pagelist-tab x-pagelist-add-button fa fa-plus', tabindex: 0})
	e.header = div({class: 'x-pagelist-header'}, e.selection_bar, e.add_button)
	e.content = div({class: 'x-pagelist-content'})
	e.add(e.header, e.content)

	function add_item(item) {
		if (!item._tab) {
			let xbutton = div({class: 'x-pagelist-xbutton fa fa-times'})
			xbutton.hide()
			let title_div = div({class: 'x-pagelist-title'})
			let tab = div({class: 'x-pagelist-tab', tabindex: 0}, title_div, xbutton)
			tab.title_div = title_div
			tab.xbutton = xbutton
			tab.on('pointerdown' , tab_pointerdown)
			tab.on('dblclick'    , tab_dblclick)
			tab.on('keydown'     , tab_keydown)
			title_div.on('input' , update_title)
			title_div.on('blur'  , title_blur)
			xbutton.on('pointerdown', xbutton_pointerdown)
			tab.item = item
			item._tab = tab
			update_tab_title(tab)
		}
		item._tab.x = null
		e.header.add(item._tab)
	}

	// widget-items widget protocol.
	e.do_init_items = function(items) {

		let sel_tab = e.selected_tab

		e.header.clear()
		for (let item of items)
			add_item(item)
		e.header.add(e.selection_bar)
		e.header.add(e.add_button)

		if (sel_tab && sel_tab.parent) // tab was kept
			select_tab(sel_tab)
		else
			select_default_tab()
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

	e.init = function() {
		e.update()
	}

	function update_tab_title(tab) {
		tab.title_div.set(tab.item.title, 'pre-wrap')
		tab.title_div.title = tab.item.title
		update_selection_bar()
	}

	function update_tab_state(tab, select) {
		tab.xbutton.show(select && (e.can_remove_items || e.widget_editing) || false)
		tab.title_div.contenteditable = select && (e.widget_editing || e.renaming)
	}

	function update_selection_bar() {
		let tab = e.selected_tab
		let horiz = e.tabs_side == 'top' || e.tabs_side == 'bottom'
		if (horiz) {
			e.selection_bar.x = tab ? tab.ox : 0
			e.selection_bar.w = tab ? tab.rect().w : 0
			e.selection_bar.y = null
			e.selection_bar.h = null
		} else {
			e.selection_bar.y = tab ? tab.oy : 0
			e.selection_bar.h = tab ? tab.rect().h : 0
			e.selection_bar.x = null
			e.selection_bar.w = null
		}
		e.selection_bar.show(!!tab)
	}

	e.do_update = function() {
		update_selection_bar()
		if (e.selected_tab)
			update_tab_state(e.selected_tab, true)
		e.add_button.show(e.can_add_items || e.widget_editing)
	}

	e.set_can_add_items    = e.update
	e.set_can_remove_items = e.update
	e.set_can_rename_items = e.update

	e.prop('can_rename_items', {store: 'var', type: 'bool', default: false})
	e.prop('can_add_items'   , {store: 'var', type: 'bool', default: false})
	e.prop('can_remove_items', {store: 'var', type: 'bool', default: false})
	e.prop('can_move_items'  , {store: 'var', type: 'bool', default: true})

	function prop_changed(te, k, v) {
		if (k == 'title' && te._tab && te._tab.parent == e.header)
			update_tab_title(te._tab)
	}

	e.on('bind', function(on) {
		if (on)
			select_default_tab()
		document.on('prop_changed', prop_changed, on)
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
			e.update()
			if (tab) {
				tab.class('selected', true)
				e.fire('open', tab.index)
				e.content.set(tab.item)
			}
		}
		if (enter_editing) {
			e.widget_editing = true
			return
		}
		if (!e.widget_editing && focus_tab != false) {
			let first_focusable = e.content.focusables()[0]
			if (first_focusable)
				first_focusable.focus()
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
		return item.title || item.gid
	}

	function format_gid(gid) {
		let item = e.items.find(item => item.gid == gid)
		return item && item.title || gid
	}

	function item_select_editor(...opt) {

		let rows = []
		for (let item of e.items)
			if (item.gid)
				rows.push([item.gid, item])

		return list_dropdown({
			rowset: {
				fields: [{name: 'gid'}, {name: 'item', format: format_item}],
				rows: rows,
			},
			nolabel: true,
			val_col: 'gid',
			display_col: 'item',
			mode: 'fixed',
		}, ...opt)

	}

	e.prop('selected_item_gid', {store: 'var', text: 'Selected Item',
		editor: item_select_editor, format: format_gid})

	function select_default_tab() {
		if (e.selected_item_gid) {
			let item = e.items.find(item => item.gid == e.selected_item_gid)
			if (item)
				select_tab(item._tab)
		} else {
			if (e.items.length)
				select_tab(e.header.at[0])
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
		if (this.title_div.contenteditable && !ev.ctrlKey) {
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
			dragging = e.can_move_items
				&& abs(down_mx - mx) > 4 || abs(down_my - my) > 4
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
	}

	// key bindings -----------------------------------------------------------

	function set_renaming(renaming) {
		e.renaming = !!renaming
		e.selected_tab.title_div.contenteditable = e.renaming
	}

	function tab_keydown(key, shift, ctrl) {
		if (key == 'F2' && e.can_rename_items) {
			set_renaming(!e.renaming)
			return false
		}
		if (e.widget_editing || e.renaming) {
			if (key == 'Enter') {
				if (ctrl)
					this.title_div.insert_at_caret('<br>')
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
		e.update()
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
			e.selected_tab.item.title = e.selected_tab.title_div.innerText
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

	e.init = function() {
		e.update()
	}

	e.set_orientation = e.update
	e.set_fixed_side  = e.update
	e.set_resizeable  = e.update
	e.set_fixed_size  = e.update
	e.set_min_size    = e.update

	e.prop('orientation', {store: 'attr', type: 'enum', enum_values: ['horizontal', 'vertical'], default: 'horizontal'})
	e.prop('fixed_side' , {store: 'attr', type: 'enum', enum_values: ['first', 'second'], default: 'first'})
	e.prop('resizeable' , {store: 'attr', type: 'bool', default: true})
	e.prop('fixed_size' , {store: 'var', type: 'number', default: 200})
	e.prop('min_size'   , {store: 'var', type: 'number', default:   0})

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

	function popup_target_bind(target, on) {
		if (!on) {
			e.tooltips.delete(this)
			update_stack()
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
			target: e.target,
			text: text,
			side: e.side,
			align: e.align,
			timeout: strict_or(timeout, e.timeout),
			check: popup_check,
			popup_target_bind: popup_target_bind,
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
		for (let s of e.layout.split(/\s+/)) {
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
		if (e.footer && !(e.footer instanceof Node))
			e.footer = action_band({layout: e.footer, buttons: e.buttons})
		e.add(e.header, e.content, e.footer)
		if (e.x_button) {
			e.x_button = div({class: 'x-dialog-xbutton fa fa-times'})
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

	e.istoolbox = true
	e.classes = 'x-widget x-toolbox pinned'

	e.pin_button = div({class: 'x-toolbox-button x-toolbox-pin-button fa fa-thumbtack'})
	e.xbutton = div({class: 'x-toolbox-button x-toolbox-xbutton fa fa-times'})
	e.title_div = div({class: 'x-toolbox-title'})
	e.titlebar = div({class: 'x-toolbox-titlebar'}, e.title_div, e.pin_button, e.xbutton)
	e.add(e.titlebar)

	e.get_text = () => e.title_div.textContent
	e.set_text = function(v) { e.title_div.set(v) }
	e.prop('text', {slot: 'lang'})

	e.set_popup_side   = e.update
	e.set_popup_align  = e.update
	e.set_popup_widget = e.update
	e.set_popup_x      = e.update
	e.set_popup_y      = e.update
	e.set_pinned       = e.update

	e.prop('popup_side'  , {store: 'var', type: 'enum', enum_values: ['inner-right', 'inner-left', 'inner-top', 'inner-bottom', 'left', 'right', 'top', 'bottom'], default: 'inner-right'})
	e.prop('popup_align' , {store: 'var', type: 'enum', enum_values: ['start', 'center', 'end'], default: 'start'})
	e.prop('popup_widget', {store: 'var', type: 'widget'})
	e.prop('popup_x'     , {store: 'var', type: 'number', default: false, slot: 'user'})
	e.prop('popup_y'     , {store: 'var', type: 'number', default: false, slot: 'user'})
	e.prop('pinned'      , {store: 'attr', type: 'bool', default: true, slot: 'user'})

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
		e.popup(e.popup_widget || document.body, e.popup_side, e.popup_align, e.popup_x || 0, e.popup_y || 0)

		// move to top if the update was user-triggered not layout-triggered.
		if (opt && opt.input == e && !is_top()) {
			let sx = e.scrollLeft
			let sy = e.scrollTop
			bind_events = false
			document.body.add(e)
			bind_events = true
			e.scroll(sx, sy)
		}

	}

	e.init = function() {
		e.content_div = div({class: 'x-toolbox-content'})
		e.content_div.set(e.content)
		e.add(e.content_div)
		e.hide()
		e.update()
		e.bind(true)
	}

	e.on('focusin', function(ev) {
		e.update()
		ev.target.focus()
	})

	e.titlebar.on('pointerdown', function(ev, mx, my) {
		e.focus()
		e.update({input: e})

		let first_focusable = e.content_div.focusables()[0]
		if (first_focusable)
			first_focusable.focus()

		if (ev.target != e.titlebar)
			return

		let r = e.rect()
		let drag_x = mx - r.x
		let drag_y = my - r.y

		return this.capture_pointer(ev, function(ev, mx, my) {
			let r = this.rect()
			e.begin_update()
			e.update({input: e})
			let px = clamp(0, mx - drag_x, window.innerWidth  - r.w)
			let py = clamp(0, my - drag_y, window.innerHeight - r.h)
			if (e.popup_side == 'inner-right')
				px = window.innerWidth  - px - r.w
			else if (e.popup_side == 'inner-bottom')
				py = window.innerHeight - py - r.h
			e.popup_x = px
			e.popup_y = py
			e.end_update()
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

	e.detect_style_size_changes()
	e.on('style_size_changed', function() {
		document.fire('layout_changed')
	})

})

// ---------------------------------------------------------------------------
// richtext
// ---------------------------------------------------------------------------

component('x-richtext', function(e) {

	e.props.align_x = {default: 'stretch'}
	e.props.align_y = {default: 'stretch'}

	serializable_widget(e)
	selectable_widget(e)
	editable_widget(e)
	cssgrid_item_widget(e)

	e.classes = 'x-widget x-richtext'

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

