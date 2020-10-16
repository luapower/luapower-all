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
	e.isinstance: t
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
	document.'widget_bind'
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
				if (this.gid) {
					document.fire('widget_bind', this, true)
					document.fire(this.gid+'.bind', this, true)
				}
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
				if (this.gid) {
					document.fire('widget_bind', this, false)
					document.fire(this.gid+'.bind', this, false)
				}
			}
		}

		debug_name(prefix) {
			prefix = (prefix && prefix + ' < ' || '') + this.type
				+ (this.gid != null ? ' ' + this.gid : '')
			let p = this; do { p = p.popup_target || p.parent } while (p && !p.debug_name)
			if (!(p && p.debug_name))
				return prefix
			return p.debug_name(prefix)
		}

	}

	customElements.define(tag, cls)

	// override cons() so that calling `parent_widget.construct()` always
	// sets the css class for parent_widget.
	function construct(e, ...args) {
		e.class(tag)
		cons(e, ...args)
	}

	function init(e, opt) {
		if (e.initialized)
			return
		props_mixin(e, opt && opt.props)
		component_deferred_updating(e)
		e.isinstance = true   // because you can have non-widget instances.
		e.iswidget = true     // to diff from normal html elements.
		e.type = type         // for serialization.
		e.init = noop         // init point when all props are set.
		e.class('x-widget')
		construct(e)
		e.initialized = false // setter barrier to delay init to e.init().
		if (opt)
			if (opt.gid) {
				xmodule.init_instance(e, opt)
			} else {
				e.begin_update()
				for (let k in opt)
					e.set_prop(k, opt[k])
				e.end_update()
			}
		e.initialized = true
		e.init()
	}

	function create(...args) {
		let e = new cls()
		init(e, update({}, ...args))
		return e
	}

	create.class = cls
	create.construct = construct

	component.types[type] = create
	window[type] = create

	return create
}

component.types = {} // {type -> create}

component.create = function(e, e0) {
	if (e instanceof Node || (isobject(e) && e.isinstance))
		return e // instances pass through.
	let gid = typeof e == 'string' ? e : e.gid
	if (e0 && e0.gid == gid)
		return e0  // already created (called from a prop's `convert()`).
	if (typeof e == 'string') // e is a gid
		e = {gid: e}
	if (!e.type) {
		e.type = xmodule.instance_type(gid)
		if (!e.type) {
			print('gid not found', gid)
			return
		}
	}
	let create = component.types[e.type]
	if (!create) {
		print('component type not found', e.type, e.gid)
		return
	}
	return create(e)
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
			if (opt)
				e.update()
	}

	e.do_update = noop

	let opt, in_update

	e.update = function(opt1) {
		if (in_update)
			return
		opt1 = opt1 || {val: true}
		opt = opt ? update(opt, opt1) : opt1
		if (e.updating)
			return
		if (!e.attached)
			return
		in_update = true
		e.do_update(opt)
		opt = null
		in_update = false
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
	// TODO: add this to simplify some things? e.fire('prop_changed', e, prop, v1, v0, slot)
	document.fire('prop_changed', e, prop, v1, v0, slot)
}

global_widget_resolver = memoize(function(type) {
	let ISTYPE = 'is'+type
	return function(name) {
		let e = window[name]
		return isobject(e) && e.attached && e[ISTYPE] && e.can_select_widget ? e : null
	}
})

function props_mixin(e, iprops) {

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

	e.prop('pos_x'  , {style: 'grid-column-start' , type: 'number', default: 1})
	e.prop('pos_y'  , {style: 'grid-row-start'    , type: 'number', default: 1})
	e.prop('span_x' , {style: 'grid-column-end'   , type: 'number', default: 1, style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
	e.prop('span_y' , {style: 'grid-row-end'      , type: 'number', default: 1, style_format: v => 'span '+v, style_parse: v => num((v || 'span 1').replace('span ', '')) })
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

	e.class('x-focusable')

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

// ---------------------------------------------------------------------------
// tooltip
// ---------------------------------------------------------------------------

component('x-tooltip', function(e) {

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
	contained_widget(e)

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

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	contained_widget(e)

	let stretched_widgets = [
		['SP', 'split'],
		['CG', 'cssgrid'],
		['PL', 'pagelist', true],
		['L', 'listbox'],
		['G', 'grid', true],
		['WSW', 'widget_switcher'],
	]

	let form_widgets = [
		['RT', 'richtext'],
		['I' , 'input'],
		['SI', 'spin_input'],
		['CB', 'checkbox'],
		['RG', 'radiogroup'],
		['SL', 'slider'],
		['SQL', 'sql_editor'],
		['KD', 'lookup_dropdown'],
		['LD', 'list_dropdown'],
		['GD', 'grid_dropdown'],
		['DD', 'date_dropdown', true],
		['CD', 'color_dropdown', true],
		['ID', 'icon_dropdown', true],
		['PC', 'pie_chart', true],
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
//   e.do_init_items()
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
		return items
	}

	function serialize_items(items) {
		let t = []
		for (let item of items)
			t.push(item.serialize())
		return t
	}

	e.set_items = function(items) {
		e.do_init_items()
		e.update()
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

	// widget-items widget protocol.
	e.do_remove_item = function(item) {
		item.remove()
	}

}

// ---------------------------------------------------------------------------
// pagelist
// ---------------------------------------------------------------------------

component('x-pagelist', function(e) {

	e.class('x-stretched')

	selectable_widget(e)
	editable_widget(e)
	contained_widget(e)
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
		let r = tab && tab.at[0].rect()
		e.selection_bar.x = tab ? tab.ox + tab.at[0].ox + (horiz  ? 0 : r.w) : 0
		e.selection_bar.y = tab ? tab.oy + tab.at[0].oy + (!horiz ? 0 : r.h) : 0
		e.selection_bar.w = horiz  ? (r ? r.w : 0) : null
		e.selection_bar.h = !horiz ? (r ? r.h : 0) : null
		e.selection_bar.show(!!tab)
	}

	e.do_update = function() {
		if (e.selected_tab)
			update_tab_state(e.selected_tab, true)
		e.add_button.show(e.can_add_items || e.widget_editing)
		update_selection_bar()
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
		if (!e.widget_editing && focus_tab != false) {
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

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	contained_widget(e)

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

})

function hsplit(...options) { return split(...options) }
function vsplit(...options) { return split(update({orientation: 'vertical'}, ...options)) }

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
			let btn = e.buttons && e.buttons[name.replaceAll('-', '_').replace(/[^\w]/g, '')]
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
				btn.text = S(name.replaceAll('-', '_'), name.replace(/[_\-]/g, ' '))
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
	e.class('pinned')

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
// widget switcher
// ---------------------------------------------------------------------------

component('x-widget-switcher', function(e) {

	e.class('x-stretched')

	serializable_widget(e)
	selectable_widget(e)
	contained_widget(e)

	// nav dynamic binding ----------------------------------------------------

	function bind_nav(nav, on) {
		if (!nav)
			return
		if (!e.attached)
			return
		nav.on('focused_row_changed'     , refresh, on)
		nav.on('focused_row_val_changed' , refresh, on)
		nav.on('reset'                   , refresh, on)
	}

	e.on('bind', function(on) {
		bind_nav(e.nav, on)
	})

	e.set_nav = function(nav1, nav0) {
		assert(nav1 != e)
		bind_nav(nav0, false)
		bind_nav(nav1, true)
		e.update()
	}
	e.prop('nav', {store: 'var', private: true})
	e.prop('nav_gid' , {store: 'var', bind_gid: 'nav', type: 'nav'})

	// view -------------------------------------------------------------------

	e.format_item_gid = function(vals) {
		return e.module + '_' + e.item_gid_format.subst(vals)
	}

	e.item_create_options = noop // stub

	e.prop('item_gid_format', {store: 'var'})

	e.do_update = function() {
		let row = e.nav && e.nav.focused_row
		let vals = row && e.nav.serialize_row_vals(row)
		let gid = vals && e.format_item_gid(vals)
		let item = gid && component.create(update({gid: gid}, e.item_create_options(vals))) || null
		e.set(item)
	}

	function refresh() {
		e.update()
	}

})

