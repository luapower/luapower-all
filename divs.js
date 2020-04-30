/*

	DOM manipulation & extensions.
	Written by Cosmin Apreutesei. Public Domain.

*/

// element attribute map manipulation ----------------------------------------

alias(Element, 'hasattr', 'hasAttribute')

method(Element, 'attr', function(k, v) {
	if (v === undefined)
		return this.getAttribute(k)
	else if (v == null)
		this.removeAttribute(k)
	else
		this.setAttribute(k, v)
	return this
})

property(Element, 'attrs', {
	get: function() {
		return this.attributes
	},
	set: function(attrs) { // doesn't remove existing attrs.
		if (attrs)
			for (let k in attrs)
				this.attr(k, attrs[k])
		return this
	}
})

// setting a default value for an attribute if one wasn't set in html.
method(Element, 'attrval', function(k, v) {
	if (!this.hasAttribute(k))
		this.setAttribute(k, v)
})

// element css class list manipulation ---------------------------------------

method(Element, 'class', function(name, enable) {
	if (enable !== false)
		this.classList.add(name)
	else
		this.classList.remove(name)
	return this
})

method(Element, 'hasclass', function(name) {
	return this.classList.contains(name)
})

method(Element, 'switch_class', function(s1, s2, normal) {
	this.class(s1, normal == false)
	this.class(s2, normal != false)
})


property(Element, 'classes', {
	get: function() {
		return this.attr('class')
	},
	set: function(s) { // doesn't remove existing classes.
		if (s)
			for (s of s.split(/\s+/))
				this.class(s, true)
	}
})

method(Element, 'css', function(prop) {
	return getComputedStyle(this)[prop]
})

/*
function css(classname, prop) {
	let div = H.div({class: classname, style: 'position: absolute; visibility: hidden'})
	document.children[0].appendChild(div)
	let v = getComputedStyle(div)[prop]
	document.children[0].removeChild(div)
	return v
}
*/

// dom tree navigation for elements, skipping text nodes ---------------------

alias(Element, 'at'     , 'children')
alias(Element, 'parent' , 'parentNode')
alias(Element, 'first'  , 'firstElementChild')
alias(Element, 'last'   , 'lastElementChild')
alias(Element, 'next'   , 'nextElementSibling')
alias(Element, 'prev'   , 'previousElementSibling')

{
let indexOf = Array.prototype.indexOf
property(Element, 'index', { get: function() {
	return indexOf.call(this.parentNode.children, this)
}})
}

// dom tree querying & element list manipulation -----------------------------

alias(Element, '$', 'querySelectorAll')
alias(DocumentFragment, '$', 'querySelectorAll')
function $(s) { return document.querySelectorAll(s) }

function E(s) {
	return typeof s == 'string' ? document.querySelector(s) : s
}

// dom tree manipulation -----------------------------------------------------

method(Element, 'add', function(...args) {
	for (let e of args)
		if (e != null)
			this.append(e)
	return this
})

method(Element, 'insert', function(i0, ...args) {
	for (let i = args.length-1; i >= 0; i--) {
		let e = args[i]
		if (e != null)
			this.insertBefore(e, this.at[i0])
	}
	return this
})

method(Element, 'replace', function(i, e) {
	let e0 = this.at[i]
	if (e0 != null)
		this.replaceChild(e, e0)
	else if (e != null)
		this.append(e)
	return this
})

method(Element, 'clear', function() {
	this.innerHTML = null
	return this
})

alias(Element, 'html', 'innerHTML')

// creating html elements ----------------------------------------------------

// create a text node from a string, quoting it automatically.
function T(s) {
	return typeof s == 'string' ? document.createTextNode(s) : s
}

// create a html element from a html string.
// if the string contains more than one element or text node, wrap them in a span.
function H(s) {
	if (typeof s != 'string') // pass-through nulls and elements
		return s
	var span = H.span(0)
	span.html = s.trim()
	return span.childNodes.length > 1 ? span : span.firstChild
}

// create a HTML element from an attribute map and a list of child elements or text.
function tag(tag, attrs, ...children) {
	let e = document.createElement(tag)
	e.attrs = attrs
	if (children)
		e.add(...children)
	return e
}

['div', 'span', 'button', 'input', 'textarea', 'label', 'table', 'thead',
'tbody', 'tr', 'td', 'th', 'a', 'i', 'b', 'hr',
'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'].forEach(function(s) {
	H[s] = function(...a) { return tag(s, ...a) }
})

// easy custom events & event wrappers ---------------------------------------

{
let callers = {}

function passthrough_caller(e, f) {
	if (typeof e.detail == 'object' && e.detail.args)
		return f.call(this, ...e.detail.args, e)
	else
		return f.call(this, e)
}

callers.click = function(e, f) {
	if (e.which == 1)
		return f.call(this, e)
	else if (e.which == 3)
		return this.fire('rightclick', e)
}

callers.mousedown = function(e, f) {
	if (e.which == 1)
		return f.call(this, e)
	else if (e.which == 3)
		return this.fire('rightmousedown', e)
}

callers.mouseup = function(e, f) {
	if (e.which == 1)
		return f.call(this, e)
	else if (e.which == 3)
		return this.fire('rightmouseup', e)
}

callers.mousemove = function(e, f) {
	return f.call(this, e.clientX, e.clientY, e)
}

callers.keydown = function(e, f) {
	return f.call(this, e.key, e.shiftKey, e.ctrlKey, e.altKey, e)
}
callers.keyup    = callers.keydown
callers.keypress = callers.keydown

callers.wheel = function(e, f) {
	if (e.deltaY)
		return f.call(this, e.deltaY, e)
}

let installers = {}

installers.attr_changed = function(e) {
	let obs = e.__attr_observer
	if (!obs) {
		obs = new MutationObserver(function() {
			e.fire('attr_changed')
		})
		obs.observe(e, {attributes: true})
		e.__attr_observer = obs
	}
}

let on = function(e, f, enable) {
	assert(enable === undefined || typeof enable == 'boolean')
	if (enable == false)
		return this.off(e, f)
	let install = installers[e]
	if (install)
		install(this)
	if (e.starts('raw:')) { // raw handler
		e = e.slice(4)
		listener = f
	} else {
		let caller = callers[e] || passthrough_caller
		listener = function(e) {
			let ret = caller.call(this, e, f)
			if (ret === false) { // like jquery
				e.preventDefault()
				e.stopPropagation()
				e.stopImmediatePropagation()
				// notify document of stopped events.
				document.fire('stopped_event', e)
			}
		}
		f.listener = listener
	}
	this.addEventListener(e, listener)
	return this
}

let off = function(e, f) {
	this.removeEventListener(e, f.listener || f)
	return this
}

let fire = function(name, ...args) {
	let e = typeof name == 'string' ?
		new CustomEvent(name, {detail: {args}}) : name
	return this.dispatchEvent(e)
}

for (let e of [Window, Document, Element]) {
	method(e, 'on'   , on)
	method(e, 'off'  , off)
	method(e, 'fire' , fire)
}

}

// geometry wrappers ---------------------------------------------------------

property(Element, 'x'    , { set: function(v) { this.style.left          = and(v, v+'px'); } })
property(Element, 'y'    , { set: function(v) { this.style.top           = and(v, v+'px'); } })
property(Element, 'w'    , { set: function(v) { this.style.width         = and(v, v+'px'); } })
property(Element, 'h'    , { set: function(v) { this.style.height        = and(v, v+'px'); } })
property(Element, 'min_w', { set: function(v) { this.style['min-width' ] = and(v, v+'px'); } })
property(Element, 'min_h', { set: function(v) { this.style['min-height'] = and(v, v+'px'); } })
property(Element, 'max_w', { set: function(v) { this.style['max-width' ] = and(v, v+'px'); } })
property(Element, 'max_h', { set: function(v) { this.style['max-height'] = and(v, v+'px'); } })

alias(Element, 'client_rect', 'getBoundingClientRect')

method(DOMRect, 'contains', function(x, y) {
	return (
		(x >= this.left && x <= this.right) &&
		(y >= this.top  && y <= this.bottom))
})

// common style wrappers -----------------------------------------------------

method(Element, 'show', function(v) { this.style.display = (v === undefined || v) ? null : 'none' })
method(Element, 'hide', function() { this.style.display = 'none' })

// common state wrappers -----------------------------------------------------

property(Element, 'hovered', {get: function() {
	return this.matches(':hover')
}})

property(Element, 'focused_element', {get: function() {
	return this.querySelector(':focus')
}})

property(Element, 'focused', {get: function() {
	return document.activeElement == this
}})

property(Element, 'hasfocus', {get: function() {
	return this.contains(document.activeElement)
}})

method(Element, 'focusables', function() {
	return this.$('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
})

// text editing --------------------------------------------------------------

alias(HTMLInputElement, 'select', 'setSelectionRange')

method(HTMLInputElement, 'set_input_filter', function() {
	function filter(e) {
		if (!this.input_filter || this.input_filter(this.value)) {
			this._valid_val  = this.value
			this._valid_sel1 = this.selectionStart
			this._valid_sel2 = this.selectionEnd
		} else {
			if (this._valid_val != null) {
				this.value = this._valid_val
				this.setSelectionRange(this._valid_sel1, this._valid_sel2)
			} else
				this.value = ''
			e.preventDefault()
			e.stopPropagation()
			e.stopImmediatePropagation()
		}
	}
	let events = ['input', 'keydown', 'keyup', 'mousedown', 'mouseup',
		'select', 'contextmenu', 'drop']
	for (e of events)
		this.on('raw:'+e, filter)
})

// scrolling -----------------------------------------------------------------

// box scroll-to-view box. from box2d.lua.
function scroll_to_view_rect(x, y, w, h, pw, ph, sx, sy) {
	let min_sx = -x
	let min_sy = -y
	let max_sx = -(x + w - pw)
	let max_sy = -(y + h - ph)
	return [
		min(max(sx, min_sx), max_sx),
		min(max(sy, min_sy), max_sy)
	]
}

method(Element, 'scroll_to_view_rect_offset', function(sx0, sy0, x, y, w, h) {
	let pw  = this.clientWidth
	let ph  = this.clientHeight
	sx0 = or(sx0, this.scrollLeft)
	sy0 = or(sy0, this.scrollTop )
	let [sx, sy] = scroll_to_view_rect(x, y, w, h, pw, ph, -sx0, -sy0)
	return [-sx, -sy]
})

// scroll to make inside rectangle invisible.
method(Element, 'scroll_to_view_rect', function(sx0, sy0, x, y, w, h) {
	this.scroll(...this.scroll_to_view_rect_offset(sx0, sy0, x, y, w, h))
})

method(Element, 'make_visible_scroll_offset', function(sx0, sy0) {
	let x = this.offsetLeft
	let y = this.offsetTop
	let w = this.offsetWidth
	let h = this.offsetHeight
	return this.parent.scroll_to_view_rect_offset(sx0, sy0, x, y, w, h)
})

// scroll parent to make self visible.
method(Element, 'make_visible', function() {
	this.parent.scroll(...this.make_visible_scroll_offset())
})

// creating & setting up web components --------------------------------------

// NOTE: the only reason for using this web components "technology" instead
// of creating normal elements is because of connectedCallback and
// disconnectedCallback for which there are no events in built-in elements.

HTMLElement.prototype.attach = noop
HTMLElement.prototype.detach = noop
HTMLElement.prototype.init   = noop

// component(tag, cons) -> create({option: value}) -> element.
function component(tag, cons) {

	let cls = class extends HTMLElement {

		constructor(...args) {
			super()
			cons(this)

			// add user options, overriding any defaults and stub methods.
			// NOTE: this also calls any property setters, but some setters
			// cannot work on a partially configured object, so we defer
			// setting these properties to after init() runs (which is the
			// only reason for having a separate init() method at all).
			let init_later = attr(this, '__init_later')
			update(this, ...args)

			// finish configuring the object, now that user options are in.
			this.init()

			// call the setters again, this time without the barrier.
			this.__init_later = null
			for (let k in init_later)
				this[k] = init_later[k]
		}

		connectedCallback() {
			if (!this.isConnected)
				return
			this.attach()
			this.fire('attach') // for popup() and setting rowset.owner.
		}

		disconnectedCallback() {
			this.detach()
			this.fire('detach') // for popup() and setting rowset.owner.
		}
	}

	customElements.define(tag, cls)

	function make(...args) {
		return new cls(...args)
	}
	make.class = cls
	make.construct = cons
	return make
}

method(HTMLElement, 'override', function(method, func) {
	override(this, method, func)
})

method(HTMLElement, 'property', function(prop, getter, setter) {
	property(this, prop, {get: getter, set: setter})
})

// create a property which is guaranteed not to be set until after init() runs.
method(HTMLElement, 'late_property', function(prop, getter, setter, default_value) {
	setter_wrapper = setter && function(v) {
		let init_later = this.__init_later
		if (init_later)
			init_later[prop] = v // defer calling the actual setter.
		else
			setter.call(this, v)
	}
	property(this, prop, {get: getter, set: setter_wrapper})
	if (default_value !== undefined)
		attr(this, '__init_later')[prop] = default_value
})

function noop_setter(v) {
	return v
}

/*
// create a boolean property that sets or removes a css class.
method(HTMLElement, 'css_property', function(name, setter = noop_setter) {
	name = name.replace('_', '-')
	function get() {
		return this.hasclass(name)
	}
	function set(v) {
		if (!!v == this.hasclass(name))
			return
		setter.call(this, v)
		this.class(name, v)
	}
	this.late_property(name.replace('-', '_'), get, set)
})
*/

// create a property that represents a html attribute.
// NOTE: a property `foo_bar` is created for an attribute `foo-bar`.
// NOTE: attr properties are not late properties so that their value
// can be available to init()!
// NOTE: you need to call `e.setattr(<name>, <default_val>)` on your
// constructor or else you won't be able to do css based on the attribute!
method(HTMLElement, 'attr_property', function(name, setter = noop_setter, type) {
	name = name.replace('_', '-')
	function get() {
		return this.getAttribute(name)
	}
	if (type == 'bool') {
		function set(v) {
			if (v)
				this.setAttribute(name, '')
			else
				this.removeAttribute(name)
			setter.call(this, v)
		}
	} else {
		if (type == 'number') {
			function get() {
				return Number(this.getAttribute(name))
			}
		}
		function set(v) {
			this.setAttribute(name, v)
			setter.call(this, v)
		}
	}
	this.property(name.replace('-', '_'), get, set)
})

method(HTMLElement, 'bool_attr_property', function(name, setter) {
	this.attr_property(name, setter, 'bool')
})

method(HTMLElement, 'num_attr_property', function(name, setter) {
	this.attr_property(name, setter, 'number')
})

// popup pattern -------------------------------------------------------------

// NOTE: why is this so complicated? because the forever almost-there-but-
// just-not-quite model of the web doesn't have the notion of a global z-index
// (they'd have to keep two parallel trees, one for painting and one for
// layouting and they just don't wanna I suppose) so we can't have relatively
// positioned popups that are also painted last i.e. on top of everything,
// so we have to choose between popups that are well-positioned but possibly
// clipped or obscured by other elements, or popups that stay on top but
// have to be manually positioned and kept in sync with the position of their
// target. We chose the latter and try to auto-update the popup position the
// best we can, but there will be cases where you'll have to call popup()
// to update the popup's position manually. We simply don't have an observer
// for tracking changes to an element's position relative to another element
// (or to document.body, which would be enough for our case here).

// `popup_target_changed` event allows changing/animating popup's visibility
// based on target's hover state or focused state.

{

let popup_timer = function() {

	let tm = {}
	let timer_id
	let handlers = new Set()
	let frequency = .25

	function tick() {
		for (f of handlers)
			f()
	}

	tm.add = function(f) {
		handlers.add(f)
		timer_id = timer_id || setInterval(tick, frequency * 1000)
	}

	tm.remove = function(f) {
		handlers.delete(f)
		if (!handlers.size) {
			clearInterval(timer_id)
			timer_id = null
		}
	}

	return tm
}

popup_timer = popup_timer()

let popup_state = function(e) {

	let s = {}

	let target, side, align, px, py

	s.update = function(target1, side1, align1, px1, py1) {
		[side, align, px, py] = [side1, align1, px1, py1]
		px = px || 0
		py = py || 0
		if (target1 != target) {
			if (target)
				free()
			target = target1 && E(target1)
			if (target)
				init()
		}
		update()
	}

	function init() {
		target.on('attach', target_attached)
		target.on('detach', target_detached)
		if (target.isConnected)
			target_attached()
	}

	function free() {
		if (target) {
			target_detached()
			target.off('attach', target_attached)
			target.off('detach', target_detached)
			target = null
		}
	}

	function bind_target(on) {
		window.on('resize', update, on)

		// NOTE: this detects target element size changes but there's no
		// observer that can monitor position changes relative to document.body.
		target.on('attr_changed', update, on)

		// allow popup_update() to change popup visibility on hover.
		target.on('mouseenter', update, on)
		target.on('mouseleave', update, on)

		// allow popup_update() to change popup visibility on focus.
		target.on('focusin' , update, on)
		target.on('focusout', update, on)

		// TODO: add events for other things that could cause popups to misalign:
		// * scrolling on any of the target's parents.
		// * moving the split widget.
		// * any layouting changes due to changes in content.

	}

	function target_attached() {
		update()
		e.style.position = 'absolute'
		document.body.add(e)
		if (e.popup_target_attached)
			e.popup_target_attached(target)
		e.fire('popup_target_attached')
		bind_target(true)
		popup_timer.add(update)
	}

	function target_detached() {
		e.remove()
		popup_timer.remove(update)
		bind_target(false)
		if (e.popup_target_detached)
			e.popup_target_detached(target)
		e.fire('popup_target_detached')
	}

	function target_changed() {
		if (e.popup_target_changed)
			e.popup_target_changed(target)
		e.fire('popup_target_changed', target)
	}

	function update() {
		if (!target || !target.isConnected)
			return

		let tr = target.client_rect()
		let er = e.client_rect()

		let x0, y0
		if (side == 'right')
			[x0, y0] = [tr.right + px, tr.top + py]
		else if (side == 'left')
			[x0, y0] = [tr.left - er.width - px, tr.top + py]
		else if (side == 'top')
			[x0, y0] = [tr.left + px, tr.top - er.height - py]
		else if (side == 'inner-right')
			[x0, y0] = [tr.right - er.width - px, tr.top + py]
		else if (side == 'inner-left')
			[x0, y0] = [tr.left + px, tr.top + py]
		else if (side == 'inner-top')
			[x0, y0] = [tr.left + px, tr.top + py]
		else if (side == 'inner-bottom')
			[x0, y0] = [tr.left + py, tr.bottom - er.height - py]
		else {
			side = 'bottom'; // default
			[x0, y0] = [tr.left, tr.bottom]
		}

		if (align == 'center' && (side == 'top' || side == 'bottom'))
			x0 = x0 - er.width / 2 + tr.width / 2
		else if (align == 'center' && (side == 'inner-top' || side == 'inner-bottom'))
			x0 = x0 - er.width / 2 + tr.width / 2
		else if (align == 'center' && (side == 'left' || side == 'right'))
			y0 = y0 - er.height / 2 + tr.height / 2
		else if (align == 'end' && (side == 'top' || side == 'bottom'))
			x0 = x0 - er.width + tr.width
		else if (align == 'end' && (side == 'left' || side == 'right'))
			y0 = y0 - er.height + tr.height

		e.x = window.scrollX + x0
		e.y = window.scrollY + y0

		target_changed()
	}

	return s
}

method(HTMLElement, 'popup', function(target, side, align, px, py) {
	this.__popup_state = this.__popup_state || popup_state(this)
	this.__popup_state.update(target, side, align, px, py)
})

}
