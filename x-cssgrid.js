
cssgrid = component('x-cssgrid', function(e) {

	e.class('x-cssgrid')

	e.init = function() {
		if (e.items)
			for (let item of e.items) {
				e.add(item)
			}

	}

	e.attach = function() {

		create_resize_tips()

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

	function tip_dblclick() {
		let tracks = e.css(`grid-template-${this.type}s`).split(' ').map(num)
		let i = this.track_index+1
		tracks.insert(i, 20)
		e.style[`grid-template-${this.type}s`] = tracks.join('fr ')+'fr'
		for (let item of e.items) {
			let i1 = num(item.css(`grid-${this.type}-start`))
			let i2 = num(item.css(`grid-${this.type}-end`))
			if (i2 == 'auto') i2 = i1
			i1--; i2--
			if (i1 >= i)
				item.style[`grid-${this.type}-start`] = i1+2
			if (i2 >= i)
				item.style[`grid-${this.type}-start`] = i2+2
		}
		create_resize_tips()
		update_resize_tips()
	}

	function update_resize_tips() {
		update_resize_tips_for('column')
		update_resize_tips_for('row')
	}

	function update_resize_tips_for(type) {
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

	function create_resize_tips() {
		if (e.tips)
			for (let tip of e.tips) {
				tip.guide.remove()
				tip.remove()
			}
		e.tips = []
		create_resize_tips_for('column')
		create_resize_tips_for('row')
	}

	function create_resize_tips_for(type) {
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
			tip.on('dblclick'   , tip_dblclick)

			e.add(tip.guide)
			e.add(tip)
		}
	}

	// dragging items ---------------------------------------------------------

	let cursors = {
		left         : 'ew-resize',
		right        : 'ew-resize',
		top          : 'ns-resize',
		bottom       : 'ns-resize',
	}

	{
		let dragging, drag_mx, drag_my
		let hit_item, hit_side, hit_x, hit_y, moving

		function start_move_item(mx, my) {
			moving = true

			let css = hit_item.css()
			let r = hit_item.client_rect()
			hit_x = drag_mx - r.left + num(css['margin-left'])
			hit_y = drag_my - r.top  + num(css['margin-top' ])

			hit_item.style['grid-column-start'] = css['grid-column-start']
			hit_item.style['grid-column-end'  ] = css['grid-column-end'  ] == 'auto' ? css['grid-column-start'] : css['grid-column-end']
			hit_item.style['grid-row-start'   ] = css['grid-row-start'   ]
			hit_item.style['grid-row-end'     ] = css['grid-row-end'     ] == 'auto' ? css['grid-row-start'   ] : css['grid-row-end'   ]

			item_ph.style['grid-column-start'] = css['grid-column-start']
			item_ph.style['grid-column-end'  ] = css['grid-column-end'  ]
			item_ph.style['grid-row-start'   ] = css['grid-row-start'   ]
			item_ph.style['grid-row-end'     ] = css['grid-row-end'     ]
			item_ph.style['margin-left'      ] = css['margin-left'      ]
			item_ph.style['margin-right'     ] = css['margin-right'     ]
			item_ph.style['margin-top'       ] = css['margin-top'       ]
			item_ph.style['margin-bottom'    ] = css['margin-bottom'    ]
			item_ph.h = hit_item.offsetHeight
			item_ph.w = hit_item.offsetWidth
			e.add(item_ph)

			hit_item.remove()
			item_overlay.remove()
			hit_item.style.position = 'absolute'
			item_overlay.style.position = 'absolute'
			move_item(mx, my)
			document.body.add(hit_item)
			document.body.add(item_overlay)
			update_item_overlay()
			item_overlay.class('x-cssgrid-moving', true)
			item_overlay.style.cursor = 'moving'

		}

		function move_item(mx, my) {
			hit_item.x = mx - hit_x
			hit_item.y = my - hit_y
			update_item_overlay()
		}

		function stop_move_item() {
			moving = false
			item_overlay.class('x-cssgrid-moving', false)
			item_ph.remove()
			hit_item.x = null
			hit_item.y = null
			hit_item.style.position = null
			item_overlay.style.position = null
			e.add(hit_item)
			update_item_overlay()
			e.add(item_overlay)
		}

		let item_ph = div({class: 'x-cssgrid-item-ph'}) // ph=placeholder

		e.on('pointerdown', function(ev) {
			if (!hit_item) return
			dragging = true
			drag_mx = ev.clientX
			drag_my = ev.clientY
			this.setPointerCapture(ev.pointerId)
			if (hit_side == 'move') {

			}
			if (hit_side == 'right') {
				//
			}
			return false
		})

		e.on('pointerup', function(ev) {
			if (!hit_item) return
			dragging = false
			this.releasePointerCapture(ev.pointerId)
			if (moving) {
				stop_move_item()
				return false
			}
		})

		e.on('dblclick', function(ev) {
			if (!hit_item) return
			hit_item.style['justify-self'] = hit_item.style['justify-self'] == 'stretch' ? 'center' : 'stretch'
			hit_item.style['align-self'  ] = hit_item.style['align-self'  ] == 'stretch' ? 'center' : 'stretch'
			hit_item.style.width = hit_item.style['justify-self'] == 'stretch' ? 'auto' : null
			update_resize_tips()
			update_item_overlay()
			return false
		})

		let item_overlay = div({class: 'x-cssgrid-item-overlay'})
		item_overlay.hide()
		e.add(item_overlay)

		function update_item_overlay() {
			if (hit_item) {
				item_overlay.x = hit_item.offsetLeft
				item_overlay.y = hit_item.offsetTop
				item_overlay.w = hit_item.offsetWidth
				item_overlay.h = hit_item.offsetHeight
			}
			item_overlay.show(!!hit_item)
		}

		e.on('pointermove', function(mx, my, ev) {
			if (moving) {
				move_item(mx, my)
				return false
			} else if (dragging) {
				if (max(abs(mx - drag_mx), abs(my - drag_my)) > 10)
					start_move_item(mx, my)
				return false
			}
			hit_item = null
			hit_side = null
			let cur
			for (let item of e.items) {
				if (item.client_rect().contains(mx, my)) {
					hit_side = 'move'
					hit_item = item
					break
				}
				hit_side = item.hit_test_sides(10, ev)
				cur = cursors[hit_side]
				if (cur) {
					hit_item = item
					break
				}
			}
			e.style.cursor = cur || 'default'
			update_item_overlay()
		})
	}

})
