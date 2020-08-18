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
})

property(Element, 'attrs', {
	get: function() {
		return this.attributes
	},
	set: function(attrs) { // doesn't remove existing attrs.
		if (attrs)
			for (let k in attrs)
				this.attr(k, attrs[k])
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

method(Element, 'css', function(prop, state) {
	let css = getComputedStyle(this, state)
	return prop ? css[prop] : css
})

raf = requestAnimationFrame

// dom tree navigation for elements, skipping text nodes ---------------------

alias(Element, 'at'     , 'children')
alias(Element, 'parent' , 'parentNode')
alias(Element, 'first'  , 'firstElementChild')
alias(Element, 'last'   , 'lastElementChild')
alias(Element, 'next'   , 'nextElementSibling')
alias(Element, 'prev'   , 'previousElementSibling')
alias(Element, 'child_count', 'childElementCount')

{
let indexOf = Array.prototype.indexOf
property(Element, 'index', { get: function() {
	return indexOf.call(this.parentNode.children, this)
}})
}

// dom tree querying ---------------------------------------------------------

alias(Element, '$', 'querySelectorAll')
alias(DocumentFragment, '$', 'querySelectorAll')
function $(s) { return document.querySelectorAll(s) }

function E(s) {
	return typeof s == 'string' ? document.querySelector(s) : s
}

// safe dom tree manipulation ------------------------------------------------

// create a text node from a string, quoting it automatically, with wrapping control.
// can also take a constructor or an existing node as argument.
function T(s, whitespace) {
	if (typeof s == 'function')
		s = s()
	if (s instanceof Node)
		return s
	if (whitespace) {
		let e = document.createElement('span')
		e.style['white-space'] = whitespace
		e.textContent = s
		return e
	}
	return document.createTextNode(s)
}

// create a html element from a html string.
// if the string contains more than one element or text node, wrap them in a span.
function H(s) {
	if (typeof s != 'string') // pass-through nulls and elements
		return s
	let span = H.span(0)
	span.html = s.trim()
	return span.childNodes.length > 1 ? span : span.firstChild
}

// create a HTML element from an attribute map and a list of child nodes.
function tag(tag, attrs, ...children) {
	let e = document.createElement(tag)
	e.attrs = attrs
	if (children)
		e.add(...children)
	return e
}

['div', 'span', 'button', 'input', 'textarea', 'label', 'table', 'thead',
'tbody', 'tr', 'td', 'th', 'a', 'i', 'b', 'hr', 'img',
'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'].forEach(function(s) {
	H[s] = function(...a) { return tag(s, ...a) }
})

div = H.div
span = H.span

method(Element, 'add', function(...args) {
	for (let s of args)
		if (s != null)
			this.append(T(s))
})

method(Element, 'insert', function(i0, ...args) {
	for (let i = args.length-1; i >= 0; i--) {
		let s = args[i]
		if (s != null)
			this.insertBefore(T(s), this.at[i0])
	}
})

method(Element, 'replace', function(e0, s) {
	if (e0 != null)
		this.replaceChild(T(s), e0)
	else if (s != null)
		this.append(T(s))
})

method(Element, 'clear', function() {
	this.innerHTML = null
})

alias(Element, 'html', 'innerHTML')

method(Element, 'set', function(s, whitespace) {
	if (typeof s == 'function')
		s = s()
	if (s instanceof Node) {
		this.innerHTML = null
		this.append(s)
	} else {
		this.textContent = s
		if (whitespace)
			this.style['white-space'] = whitespace
	}
})

// quick overlays ------------------------------------------------------------

function overlay(attrs, content) {
	let e = div(attrs)
	e.style = `
		position: absolute;
		left: 0;
		top: 0;
		right: 0;
		bottom: 0;
		display: flex;
		overflow: auto;
		justify-content: center;
	` + (attrs && attrs.style || '')
	if (content == null)
		content = div()
	e.set(content)
	e.content = e.at[0]
	e.content.style['margin'] = 'auto' // center it.
	return e
}

method(Element, 'overlay', function(target, attrs, content) {
	let e = overlay(attrs, content)
	target.add(e)
	return e
})

// events & event wrappers ---------------------------------------------------

{
let callers = {}

let hidden_events = {prop_changed: 1, attr_changed: 1, stopped_event: 1}

function passthrough_caller(e, f) {
	if (isobject(e.detail) && e.detail.args) {
		//if (!(e.type in hidden_events))
		//print(e.type, ...e.detail.args)
		return f.call(this, ...e.detail.args, e)
	} else
		return f.call(this, e)
}

callers.click = function(e, f) {
	if (e.which == 1)
		return f.call(this, e)
	else if (e.which == 3)
		return this.fire('rightclick', e)
}

callers.pointerdown = function(e, f) {
	let ret
	if (e.which == 1)
		ret = f.call(this, e, e.clientX, e.clientY)
	else if (e.which == 3)
		ret = this.fire('rightpointerdown', e, e.clientX, e.clientY)
	if (ret == 'capture') {
		this.setPointerCapture(e.pointerId)
		ret = false
	}
	return ret
}

method(Element, 'capture_pointer', function(e, move, up) {
	move = or(move, return_false)
	up   = or(up  , return_false)
	let down_mx = e.clientX
	let down_my = e.clientY
	function wrap_move(mx, my, e) {
		return move.call(this, mx, my, e, down_mx, down_my)
	}
	function wrap_up(e, mx, my) {
		this.off('pointermove', wrap_move)
		this.off('pointerup'  , wrap_up)
		return up.call(this, e, mx, my)
	}
	this.on('pointermove', wrap_move)
	this.on('pointerup'  , wrap_up)
	return 'capture'
})

callers.pointerup = function(e, f) {
	let ret
	if (e.which == 1)
		ret = f.call(this, e.clientX, e.clientY, e)
	else if (e.which == 3)
		ret = this.fire('rightpointerup', e.clientX, e.clientY, e)
	if (this.hasPointerCapture(e.pointerId))
		this.releasePointerCapture(e.pointerId)
	return ret
}

callers.pointermove = function(e, f) {
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
		obs = new MutationObserver(function(mutations) {
			e.fire(event('attr_changed', false, mutations))
		})
		obs.observe(e, {attributes: true})
		e.__attr_observer = obs
	}
}

let on = function(e, f, enable, capture) {
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
				if (e.type == 'pointerdown')
					document.fire(event('stopped_event', false, e))
			}
		}
		f.listener = listener
	}
	this.addEventListener(e, listener, capture)
}

let off = function(e, f) {
	this.removeEventListener(e, f.listener || f)
}

let once = function(e, f) {
	let wrapper = function(...args) {
		let ret = f(...args)
		e.off(wrapper)
		return ret
	}
	e.on(wrapper)
}

function event(name, bubbles, ...args) {
	return typeof name == 'string'
		? new CustomEvent(name, {detail: {args}, cancelable: true, bubbles: bubbles})
		: name
}

let fire = function(name, ...args) {
	return this.dispatchEvent(event(name, true, ...args))
}

for (let e of [Window, Document, Element]) {
	method(e, 'on'   , on)
	method(e, 'off'  , off)
	method(e, 'once' , once)
	method(e, 'fire' , fire)
}

}

// geometry wrappers ---------------------------------------------------------

function px(v) {
	return typeof v == 'number' ? v+'px' : v
}

property(Element, 'x'    , { set: function(v) { this.style.left          = px(v) } })
property(Element, 'x2'   , { set: function(v) { this.style.right         = px(v) } })
property(Element, 'y'    , { set: function(v) { this.style.top           = px(v) } })
property(Element, 'w'    , { set: function(v) { this.style.width         = px(v) } })
property(Element, 'h'    , { set: function(v) { this.style.height        = px(v) } })
property(Element, 'min_w', { set: function(v) { this.style['min-width' ] = px(v) } })
property(Element, 'min_h', { set: function(v) { this.style['min-height'] = px(v) } })
property(Element, 'max_w', { set: function(v) { this.style['max-width' ] = px(v) } })
property(Element, 'max_h', { set: function(v) { this.style['max-height'] = px(v) } })

alias(Element, 'rect', 'getBoundingClientRect')

alias(HTMLElement, 'ox', 'offsetLeft')
alias(HTMLElement, 'oy', 'offsetTop')

alias(DOMRect, 'x' , 'left')
alias(DOMRect, 'y' , 'top')
alias(DOMRect, 'x1', 'left')
alias(DOMRect, 'y1', 'top')
alias(DOMRect, 'w' , 'width')
alias(DOMRect, 'h' , 'height')
alias(DOMRect, 'x2', 'right')
alias(DOMRect, 'y2', 'bottom')

method(DOMRect, 'contains', function(x, y) {
	return (
		(x >= this.left && x <= this.right) &&
		(y >= this.top  && y <= this.bottom))
})

window.on('resize', function() { document.fire('layout_changed') })

// common style wrappers -----------------------------------------------------

method(Element, 'show', function(v, affects_layout) {
	let d0 = this.style.display
	let d1 = (v === undefined || v) ? null : 'none'
	if (d0 == d1)
		return
	this.style.display = d1
	if (affects_layout)
		this.fire('layout_changed')
})
method(Element, 'hide', function() {
	this.show(false)
})

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

property(Element, 'contenteditable', {
	get: function() { return this.contentEditable == 'true' },
	set: function(v) { this.contentEditable = v ? 'true' : 'false' },
})

// for contenteditables.
method(HTMLElement, 'insert_at_caret', function(s) {
	let node = H(s)
	let sel = getSelection()
	let range = sel.getRangeAt(0)
	range.insertNode(node)
	range.setStartAfter(node)
	range.setEndAfter(node)
	sel.removeAllRanges()
	sel.addRange(range)
})

method(HTMLElement, 'select_all', function() {
	let range = document.createRange()
	range.selectNodeContents(this)
	let sel = getSelection()
	sel.removeAllRanges()
	sel.addRange(range)
})

method(HTMLElement, 'unselect', function() {
	let range = document.createRange()
	range.selectNodeContents(this)
	let sel = getSelection()
	sel.removeAllRanges()
})

// scrolling -----------------------------------------------------------------

// box scroll-to-view box. from box2d.lua.
function scroll_to_view_rect(x, y, w, h, pw, ph, sx, sy) {
	let min_sx = -x
	let min_sy = -y
	let max_sx = -(x + w - pw)
	let max_sy = -(y + h - ph)
	return [
		clamp(sx, min_sx, max_sx),
		clamp(sy, min_sy, max_sy)
	]
}

method(Element, 'scroll_to_view_rect_offset', function(sx0, sy0, x, y, w, h) {
	let pw  = this.clientWidth
	let ph  = this.clientHeight
	sx0 = or(sx0, this.scrollLeft)
	sy0 = or(sy0, this.scrollTop )
	let e = this
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

// popup pattern -------------------------------------------------------------

// Why is this so complicated? Because the forever almost-there-but-just-not-quite
// model of the web doesn't have the notion of a global z-index so we can't
// have relatively positioned popups that are also painted last i.e. on top
// of everything, so we have to choose between popups that are well-positioned
// but possibly clipped or obscured by other elements, or popups that stay
// on top but have to be manually positioned and kept in sync with the position
// of their target. We chose the latter since we have a lot of implicit
// "stacking contexts" (i.e. abstraction leaks of the graphics engine) and we
// try to auto-update the popup position the best we can, but there will be
// cases where you'll have to call popup() to update the popup's position
// manually. We simply don't have an observer for tracking changes to an
// element's position relative to another element (or to document.body, which
// would be enough for our case here).

// `popup_target_updated` event allows changing/animating popup's visibility
// based on target's hover state or focused state.

{

let popup_timer = function() {

	let tm = {}
	let timer_id
	let handlers = new Set()
	let frequency = .25

	function tick() {
		for (let f of handlers)
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
		side    = or(side1  , side)
		align   = or(align1 , align)
		px      = or(px1, px) || 0
		py      = or(py1, py) || 0
		target1 = or(repl(target1, null, target), target)
		if (target1 != target) {
			if (target)
				free()
			target = target1 && E(target1)
			if (target)
				init()
			e.popup_target = target
		}
		if (target)
			update(true)
	}

	function init() {
		if (target != document.body) { // prevent infinite recursion.
			if (target.typename) { // component
				target.on('attach', target_attached)
				target.on('detach', target_detached)
			}
		}
		if (target.isConnected || target.attached)
			target_attached()
	}

	function free() {
		if (target) {
			target_detached()
			if (target.typename) { // component
				target.off('attach', target_attached)
				target.off('detach', target_detached)
			}
			target = null
		}
	}

	function window_scroll(ev) {
		if (target && ev.target.contains(target))
			raf(update)
	}

	function bind_target(on) {

		// this detects explicit target element size changes which is not much.
		target.on('attr_changed', update, on)

		// allow popup_update() to change popup visibility on target hover.
		target.on('pointerenter', update, on)
		target.on('pointerleave', update, on)

		// allow popup_update() to change popup visibility on target focus.
		target.on('focusin' , update, on)
		target.on('focusout', update, on)

		// scrolling on any of the target's parents updates the popup position.
		window.on('scroll', window_scroll, on, true)

		// layout changes update the popup position.
		document.on('layout_changed', update, on)

	}

	function target_attached() {
		e.style.position = 'absolute'
		document.body.add(e)
		update()
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

	function target_updated() {
		if (e.popup_target_updated)
			e.popup_target_updated(target)
		e.fire('popup_target_updated', target)
	}

	function force_attached(e, v) {
		if (e.attached != null)
			e.attached = v
		for (let ce of e.children)
			force_attached(ce, v)
	}

	function is_top_popup() {
		let last = document.body.last
		while (1) {
			if (e == last)
				return true
			if (last.__popup_state) {
				return false
			}
			last = last.prev
		}
	}

	function update(from_user) {
		if (!(target && target.isConnected))
			return

		// move to top if the update was user-triggered not layout-triggered.
		if (from_user === true && e.parent == document.body && !is_top_popup()) {
			let sx = e.scrollLeft
			let sy = e.scrollTop
			force_attached(e, false)
			e.remove()
			force_attached(e, true)
			document.body.add(e)
			e.scroll(sx, sy)
		}

		let tr = target.rect()
		let er = e.rect()

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
		else if (side == 'inner-center')
			[x0, y0] = [tr.left + (tr.width - er.width) / 2, tr.top + (tr.height - er.height) / 2]
		else {
			side = 'bottom'; // default
			[x0, y0] = [tr.left + px, tr.bottom + py]
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

		target_updated()
	}

	return s
}

method(HTMLElement, 'popup', function(target, side, align, px, py) {
	this.__popup_state = this.__popup_state || popup_state(this)
	this.__popup_state.update(target, side, align, px, py)
})

}

// modal window pattern ------------------------------------------------------

method(Element, 'modal', function(on) {
	let e = this
	if (on == false) {
		if (e.__dialog) {
			e.__dialog.remove()
			e.__dialog = null
		}
	} else if (!e.__dialog) {
		let dialog = tag('dialog', {
			style: `
				position: fixed;
				left: 0;
				top: 0;
				width: 100%;
				height: 100%;
				overflow: auto;
				border: 0;
				background-color: rgba(0,0,0,0.4);
				display: flex;
				align-items: center;
				justify-content: center;
			`,
		}, e)
		dialog.on('pointerdown', () => false)
		e.__dialog = dialog
		document.body.add(dialog)
		dialog.showModal()
		e.focus()
	}
})

// live-move list element pattern --------------------------------------------

// implements:
//   move_element_start(move_i, move_n, i1, i2[, x1, x2])
//   move_element_update(elem_x, [i1, i2, x1, x2])
// uses:
//   movable_element_size(elem_i) -> w
//   set_movable_element_pos(i, x, moving)
//
function live_move_mixin(e) {

	e = e || {}

	let move_i1, move_i2, i1, i2, i1x, i2x
	let move_x, over_i, over_p, over_x
	let advance

	e.move_element_start = function(move_i, move_n, _i1, _i2, _i1x, _i2x) {
		move_n = or(move_n, 1)
		move_i1 = move_i
		move_i2 = move_i + move_n
		move_x = null
		over_i = null
		over_x = null
		i1  = _i1
		i2  = _i2
		i1x = _i1x
		i2x = _i2x
		advance = advance || e.movable_element_advance || (() => 1)
		if (i1x == null) {
			assert(i1 == 0)
			i1x = 0
			i2x = i1x
			for (let i = i1, n; i < i2; i += n) {
				n = advance(i)
				if (i < move_i1 || i >= move_i2)
					i2x += e.movable_element_size(i, n)
			}
		}
	}

	e.move_element_stop = function() {
		set_moving_element_pos(over_x)
		return over_i
	}

	function hit_test(elem_x) {
		let x = i1x
		let x0 = i1x
		let last_over_i = over_i
		let new_over_i, new_over_p
		for (let i = i1, n; i < i2; i += n) {
			n = advance(i)
			if (i < move_i1 || i >= move_i2) {
				let w = e.movable_element_size(i, n)
				let x1 = x + w / 2
				if (elem_x < x1) {
					new_over_i = i
					new_over_p = lerp(elem_x, x0, x1, 0, 1)
					if (i > i1 || advance(i1 - 1) == 1) {
						over_i = new_over_i
						over_p = new_over_p
						return new_over_i != last_over_i
					}
				}
				x += w
				x0 = x1
			}
		}
		new_over_i = i2
		x1 = i2x
		new_over_p = lerp(elem_x, x0, x1, 0, 1)
		if (advance(i2 - 1) == 1) {
			over_i = new_over_i
			over_p = new_over_p
			return new_over_i != last_over_i
		}
	}

 	// `[i1..i2)` index generator with `[move_i1..move_i2)` elements moved.
	function each_index(f) {
		if (over_i < move_i1) { // moving upwards
			for (let i = i1     ; i < over_i ; i++) f(i)
			for (let i = move_i1; i < move_i2; i++) f(i, true)
			for (let i = over_i ; i < move_i1; i++) f(i)
			for (let i = move_i2; i < i2     ; i++) f(i)
		} else {
			for (let i = i1     ; i < move_i1; i++) f(i)
			for (let i = move_i2; i < over_i ; i++) f(i)
			for (let i = move_i1; i < move_i2; i++) f(i, true)
			for (let i = over_i ; i <  i2    ; i++) f(i)
		}
	}

	let move_ri1, move_ri2, move_vi1

	function set_moving_element_pos(x, moving) {
		if (move_ri1 != null)
			for (let i = move_ri1; i < move_ri2; i++) {
				e.set_movable_element_pos(i, x, moving)
				x += e.movable_element_size(i, 1)
			}
	}

	e.move_element_update = function(elem_x) {
		elem_x = clamp(elem_x, i1x, i2x)
		if (elem_x != move_x) {
			move_x = elem_x
			e.move_x = move_x
			if (hit_test(move_x)) {
				e.over_i = over_i
				e.over_p = over_p
				let x = i1x
				move_ri1 = null
				move_ri2 = null
				over_x = null
				each_index(function(i, moving) {
					if (moving) {
						over_x = or(over_x, x)
						move_ri1 = or(move_ri1, i)
						move_ri2 = i+1
					} else
						e.set_movable_element_pos(i, x)
					x += e.movable_element_size(i, 1)
				})
			}
			set_moving_element_pos(move_x, true)
		}
	}

	return e
}

// ---------------------------------------------------------------------------
// creating & setting up web components
// ---------------------------------------------------------------------------

// NOTE: the only reason for using this web components "technology" instead
// of creating normal elements is because of connectedCallback and
// disconnectedCallback for which there are no events in built-in elements,
// and we use those events to solve the so-called "lapsed listener problem"
// (a proper iterable weak hash map would be a better way to solve this but
// alas, the web people could't get that one right either).

HTMLElement.prototype.init = noop

// component(tag, cons) -> create({option: value}) -> element.
function component(tag, cons) {

	let typename = tag.replace(/^[^\-]+\-/, '').replace('-', '_')

	let cls = class extends HTMLElement {

		constructor() {
			super()
			this.attached = false
		}

		connectedCallback() {
			if (this.attached)
				return
			if (!this.isConnected)
				return
			// elements created by the browser must be initialized on first
			// attach as they aren't allowed to create children or add
			// attributes in the constructor.
			this.initialize()
			this.attach()
		}

		disconnectedCallback() {
			this.detach()
		}

		initialize() {
			init(this)
		}

		attach() {
			if (this.attached)
				return
			this.attached = true
			this.fire(event('attach', false))
			if (this.id)
				document.fire(event('global_attached', false, this, this.id))
		}

		detach() {
			if (!this.attached)
				return
			this.attached = false
			this.fire(event('detach', false))
			if (this.id)
				document.fire(event('global_detached', false, this, this.id))
		}

	}

	customElements.define(tag, cls)

	function init(e, ...args) {
		e.initialize = noop
		e.typename = typename
		cons(e)

		// add user options, overriding any defaults and stub methods.
		// NOTE: this also calls any property setters, but some setters
		// cannot work on a partially configured object, so we defer
		// setting these properties to after init() runs (which is the
		// only reason for having a separate init() method at all).
		let init_later = attr(e, '__init_later')
		update(e, ...args)

		// finish configuring the object, now that user options are in.
		e.init()
		e.initialized = true

		// call the setters again, this time without the barrier.
		e.__init_later = null
		for (let k in init_later)
			e[k] = init_later[k]

	}

	function create(...args) {
		let e = new cls()
		init(e, ...args)
		return e
	}

	create.class = cls
	create.construct = cons

	component.types[typename] = create
	window[typename] = create

	return create
}

component.types = {} // {typename->create}

component.create = function(t) {
	if (t instanceof HTMLElement)
		return t
	let create = component.types[t.typename]
	return create(t)
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

method(HTMLElement, 'prop', function(prop, opt) {

	opt = opt || {}
	let getter = 'get_'+prop
	let setter = 'set_'+prop
	if (!opt.type) { // infer type
		if (opt.enum_values)
			opt.type = 'enum'
		if (typeof opt.default == 'boolean')
			opt.type = 'bool'
		else if (typeof opt.default == 'number')
			opt.type = 'number'
	}
	let type = opt.type
	let noinit = opt.noinit
	opt.name = prop
	if (!this[setter])
		this[setter] = noop

	if (opt.store == 'var') {
		let v = opt.default
		function get() {
			return v
		}
		function set(v1) {
			let v0 = v
			if (v1 === v0)
				return
			v = v1
			if (noinit && !this.initialized)
				return
			this[setter](v, v0)
			this.fire('prop_changed', prop, v, v0)
		}
	} else if (opt.attr) {
		let attr = opt.attr
		if (type == 'bool') {
			if (!!opt.default && !this.hasAttribute(attr))
				this.setAttribute(attr, '')
			function get() {
				return this.hasAttribute(attr)
			}
			function set(v) {
				v = !!v
				let v0 = this.hasAttribute(attr)
				if (v == v0)
					return
				if (v)
					this.setAttribute(attr, '')
				else
					this.removeAttribute(attr)
				if (noinit && !this.initialized)
					return
				this[setter](v, v0)
				this.fire('prop_changed', prop, v, v0)
			}
		} else if (type == 'number') {
			if (opt.default != null && !this.hasAttribute(attr))
				this.setAttribute(attr, opt.default+'')
			function get() {
				return num(this.getAttribute(attr))
			}
			function set(v) {
				let v0 = num(this.getAttribute(attr))
				if (v == v0)
					return
				this.setAttribute(attr, v+'')
				if (noinit && !this.initialized)
					return
				this[setter](v, v0)
				this.fire('prop_changed', prop, v, v0)
			}
		} else {
			if (opt.default != null && !this.hasAttribute(attr))
				this.setAttribute(attr, opt.default)
			function get() {
				return this.getAttribute(attr)
			}
			function set(v) {
				let v0 = this.getAttribute(attr)
				if (v == v0)
					return
				this.setAttribute(attr, v)
				if (noinit && !this.initialized)
					return
				this[setter](v, v0)
				this.fire('prop_changed', prop, v, v0)
			}
		}
	} else if (opt.style) {
		let style = opt.style
		let format = opt.style_format || return_arg
		let parse  = opt.style_parse  || type == 'number' && num || function(v) { return v }
		if (opt.default != null && !this.style[style])
			this.style[style] = format(opt.default)
		function get() {
			return parse(this.style[style])
		}
		function set(v) {
			let v0 = get.call(this)
			if (v == v0)
				return
			this.style[style] = format(v)
			if (noinit && !this.initialized)
				return
			v = get.call(this) // take it again (browser only sets valid values)
			if (v == v0)
				return
			this[setter](v, v0)
			this.fire('prop_changed', prop, v, v0)
		}
	} else {
		function get() {
			return this[getter]()
		}
		function set(v) {
			let v0 = this[getter]()
			if (v === v0)
				return
			if (noinit && !this.initialized)
				return
			this[setter](v, v0)
			this.fire('prop_changed', prop, v, v0)
		}
		if (opt.default !== undefined)
			set.call(this, opt.default)
	}

	if (opt.bind) {
		let resolve = opt.resolve || global_widget_resolver(opt.type)
		let NAME = prop
		let REF = repl(opt.bind, true, NAME)
		let e = this
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
			document.on('global_changed' , global_changed, on)
			document.on('global_attached', global_attached, on)
			document.on('global_detached', global_detached, on)
		}
		function attach() {
			e[REF] = resolve(e[NAME])
			bind(true)
		}
		function detach() {
			e[REF] = null
			bind(false)
		}
		function prop_changed(k, name, last_name) {
			if (k != NAME) return
			if (e.attached)
				e[REF] = resolve(name)
			if ((name != null) != (last_name != null)) {
				this.on('attach', attach, name != null)
				this.on('detach', detach, name != null)
			}
		}
		if (e[NAME] != null)
			prop_changed(NAME, e[NAME])
		this.on('prop_changed', prop_changed)
	}

	this.property(prop, get, set)

	if (!opt.private)
		attr(this, 'props')[prop] = opt
})

global_widget_resolver = memoize(function(type) {
	let is_type = 'is_'+type
	return function(name) {
		let e = window[name]
		return isobject(e) && e.attached && e[is_type] && e.can_select_widget ? e : null
	}
})

