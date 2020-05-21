
cssgrid = component('x-cssgrid', function(e) {

	e.class('x-cssgrid')

	e.init = function() {
		if (e.items)
			for (let item of e.items) {
				item.style.width = 'auto'
				e.add(item)
			}

	}

	e.attach = function() {

		e.tips = []
		create_resize_tips('column')
		create_resize_tips('row')

		after(0.1, function() {
			update_resize_tips('column')
			update_resize_tips('row')
		})
	}

	e.detach = function() {

	}

	// resize tips ------------------------------------------------------------

	{
		let dragging, drag_mx, cx, s0, s1, sizes

		function tip_mousedown(ev) {
			dragging = true
			sizes = e.css(`grid-template-${this.type}s`).split(' ').map(num)
			let cr = this.client_rect()
			let pcr = this.parent.client_rect()
			let left = this.type == 'column' ? 'left' : 'top'
			cx = cr[left] - pcr[left]
			drag_mx = ev[this.type == 'column' ? 'clientX' : 'clientY'] - cr[left]
			s0 = sizes[this.track_index  ]
			s1 = sizes[this.track_index+1]
			this.setPointerCapture(ev.pointerId)
		}

		function tip_mousemove(mx, my) {
			if (!dragging) return
			let cr = this.parent.client_rect()
			let left = this.type == 'column' ? 'left' : 'top'
			mx = (this.type == 'column' ? mx : my) - drag_mx - cr[left]
			let dx = mx - cx
			sizes[this.track_index  ] = max(0, s0 + dx)
			sizes[this.track_index+1] = max(0, s1 - dx)
			e.style[`grid-template-${this.type}s`] = sizes.join('fr ')+'fr'
			update_resize_tips(this.type)
		}

		function tip_mouseup(ev) {
			dragging = false
			this.releasePointerCapture(ev.pointerId)
		}
	}

	function update_resize_tips(type) {
		let gap = num(e.css(`grid-${type}-gap`))
		let t = e.css(`grid-template-${type}s`).split(' ')
		let X = type == 'column' ? 'x' : 'y'
		let Y = type == 'column' ? 'y' : 'x'
		let x = gap / 2
		let ti = 0
		let guide_w = e.client_rect()[type == 'column' ? 'height' : 'width']
		for (let tip of e.tips)
			if (tip.type == type) {
				x += num(t[ti++])
				tip[X] = x
				tip[Y] = 0
				tip.guide[type == 'column' ? 'h' : 'w'] = guide_w
				tip.guide[X] = x
				tip.show()
				x += gap
			}
	}

	function create_resize_tips(type) {
		let t = e.css(`grid-template-${type}s`).split(' ')
		let side = type == 'column' ? 'top' : 'left'
		for (let i = 0; i < t.length-1; i++) {
			let tip = div({class: 'x-cssgrid-resize-tip', side: side})
			tip.hide()
			tip.guide = div({class: 'x-cssgrid-resize-guide', side: side})
			tip.track_index = i
			tip.type = type
			e.tips.push(tip)
			tip.on('pointerdown', tip_mousedown)
			tip.on('pointermove', tip_mousemove)
			tip.on('pointerup'  , tip_mouseup)

			e.add(tip.guide)
			e.add(tip)
		}
	}

	// dragging child elements by their sides ---------------------------------

	let cursors = {
		left         : 'ew-resize',
		right        : 'ew-resize',
		top          : 'ns-resize',
		bottom       : 'ns-resize',
	}

	{
		let hit_ce, hit_side

		e.on('pointerdown', function(ev) {
			if (!hit_ce) return
			this.setPointerCapture(ev.pointerId)
			if (hit_side == 'move') {

			} else if (hit_side == 'right') {
				//
			}
		})

		e.on('dblclick', function(ev) {
			if (!hit_ce) return
			hit_ce.style['justify-self'] = hit_ce.style['justify-self'] == 'stretch' ? 'center' : 'stretch'
			hit_ce.style['align-self'  ] = hit_ce.style['align-self'  ] == 'stretch' ? 'center' : 'stretch'
			update_overlay()
		})

		e.on('pointerup', function(ev) {
			if (!hit_ce) return
			this.releasePointerCapture(ev.pointerId)
		})

		let overlay = div({class: 'x-cssgrid-overlay'})
		overlay.hide()
		e.add(overlay)

		function update_overlay() {
			overlay.x = hit_ce.offsetLeft
			overlay.y = hit_ce.offsetTop
			overlay.w = hit_ce.offsetWidth
			overlay.h = hit_ce.offsetHeight
			overlay.show()
		}

		e.on('pointermove', function(mx, my, ev) {
			hit_ce = null
			hit_side = null
			overlay.hide()
			let cur
			for (let ce of e.items) {
				if (ce.client_rect().contains(mx, my)) {
					cur = 'move'
					hit_side = 'move'
					hit_ce = ce
					update_overlay()
					break
				}
				hit_side = ce.hit_test_sides(10, ev)
				cur = cursors[hit_side]
				if (cur) {
					hit_ce = ce
					break
				}
			}
			e.style.cursor = cur || 'default'
		})
	}

})
