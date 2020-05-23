
cssgrid = component('x-cssgrid', function(e) {

	e.class('x-cssgrid')
	e.class('editing')

	e.init = function() {
		if (e.items)
			for (let item of e.items)
				e.add(item)
	}

	e.attach = function() {

		// normalize positions in grid.
		for (let item of e.items) {
			let css = item.css()
			item.style['grid-column-start'] = css['grid-column-start']
			item.style['grid-column-end'  ] = (css['grid-column-end'  ] == 'auto' ? css['grid-column-start'] : css['grid-column-end'])
			item.style['grid-row-start'   ] = css['grid-row-start'   ]
			item.style['grid-row-end'     ] = (css['grid-row-end'     ] == 'auto' ? css['grid-row-start'   ] : css['grid-row-end'   ])
		}

		create_resize_tips()

		after(0.1, function() {
			update_resize_tips('column')
			update_resize_tips('row')
		})
	}

	e.detach = function() {

	}

	// geometry ---------------------------------------------------------------

	function track_sizes(type) {
		return e.css(`grid-template-${type}s`).split(' ').map(num)
	}

	function item_track_bounds_for(sizes, gap, i1, i2) {
		let x1, x2
		let x = 0
		for (let i = 0; i < sizes.length; i++) {
			if (i1 == i)
				x1 = x
			if (i > 0)
				x += gap / 2
			x += sizes[i]
			if (i < sizes.length-1)
				x += gap / 2
			if (i2 == i)
				x2 = x
		}
		return [x1, x2]
	}

	function item_track_bounds(item) {
		let css = item.css()
		let e_css = e.css()
		let col_gap = num(e_css['column-gap'])
		let row_gap = num(e_css['row-gap'])
		let i1 = num(css['grid-column-start'])-1
		let i2 = num(css['grid-column-end'])-1
		let j1 = num(css['grid-row-start'])-1
		let j2 = num(css['grid-row-end'])-1
		let col_sizes = track_sizes('column')
		let row_sizes = track_sizes('row')
		let [x1, x2] = item_track_bounds_for(col_sizes, col_gap, i1, i2)
		let [y1, y2] = item_track_bounds_for(row_sizes, row_gap, j1, j2)
		return [x1, y1, x2, y2]
	}

	// resize tips ------------------------------------------------------------

	{
		let dragging, drag_mx, cx, s0, s1, sizes

		function tip_mousedown(ev) {
			dragging = true
			this.setPointerCapture(ev.pointerId)
			sizes = track_sizes(this.type)
			let cr = this.client_rect()
			let pcr = this.parent.client_rect()
			let left = this.type == 'column' ? 'left' : 'top'
			cx = cr[left] - pcr[left]
			drag_mx = ev[this.type == 'column' ? 'clientX' : 'clientY'] - cr[left]
			s0 = sizes[this.track_index  ]
			s1 = sizes[this.track_index+1]
			return false
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
			return false
		}

		function tip_mouseup(ev) {
			if (!dragging) return
			dragging = false
			this.releasePointerCapture(ev.pointerId)
			return false
		}
	}

	function tip_dblclick() {
		let tracks = track_sizes(this.type)
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
		update_item_overlay()
	}

	function update_resize_tips_for(type) {
		let gap = num(e.css(`grid-${type}-gap`))
		let tracks = track_sizes(type)
		let X = type == 'column' ? 'x' : 'y'
		let Y = type == 'column' ? 'y' : 'x'
		let x = gap / 2
		let ti = 0
		let guide_w = e.client_rect()[type == 'column' ? 'height' : 'width']
		for (let tip of e.tips)
			if (tip.type == type) {
				x += tracks[ti++]
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
		let side = type == 'column' ? 'top' : 'left'
		for (let i = 0; i < track_sizes(type).length-1; i++) {
			let tip = div({class: 'x-arrow x-cssgrid-resize-tip', side: side})
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

	{
		let item_ph = div()
		let span_ph = div({class: 'x-cssgrid-span-ph'}) // ph=placeholder
		let align_arrow = div({class: 'x-arrow x-cssgrid-align-arrow'})

		let hit_item, hit_area, hit_x, hit_y, moving

		function pop_out_item() {
			if (hit_item.parent != e)
				return
			let css = hit_item.css()
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
			document.body.add(hit_item)
			document.body.add(item_overlay)
			update_item_overlay()
		}

		function push_in_item() {
			if (hit_item.parent == e)
				return
			item_ph.remove()
			hit_item.x = null
			hit_item.y = null
			hit_item.style.position = null
			item_overlay.style.position = null
			e.add(hit_item)
			update_item_overlay()
			e.add(item_overlay)
		}

		function start_move_item(mx, my) {
			let css = hit_item.css()
			let r = hit_item.client_rect()
			hit_x = drag_mx - r.left + num(css['margin-left'])
			hit_y = drag_my - r.top  + num(css['margin-top' ])

			moving = true
			item_overlay.class('x-cssgrid-moving', true)

			let [bx1, by1, bx2, by2] = item_track_bounds(hit_item)
			span_ph.x = bx1
			span_ph.y = by1
			span_ph.w = bx2-bx1
			span_ph.h = by2-by1
			//e.add(span_ph)

			move_item(mx, my)
		}

		function stop_move_item() {
			push_in_item()
			span_ph.remove()

			moving = false
			item_overlay.class('x-cssgrid-moving', false)
		}

		function hit_test_edge(dx, x1, x2, bx1, bx2) {
			let dx1 = abs(bx1 - x1)
			let dx2 = abs(bx2 - x2)
			if (dx1 <= dx && dx2 <= dx) // close to both edges
				if (abs(dx1 - dx2) <= (dx1 + dx2) / 2)
					return 'center'
				else
					return dx1 < dx2 ? 'start' : 'end'
			else if (dx1 <= dx)
				return 'start'
			else if (dx2 <= dx)
				return 'end'
			else if (abs(dx1 - dx2) <= dx)
				return 'center'
		}

		function move_item(mx, my) {

			let x = mx - hit_x
			let y = my - hit_y

			let x1 = x - e.offsetLeft
			let y1 = y - e.offsetTop
			let x2 = x1 + hit_item.offsetWidth
			let y2 = y1 + hit_item.offsetHeight
			let [bx1, by1, bx2, by2] = item_track_bounds(hit_item)
			let align_x = hit_test_edge(20, x1, x2, bx1, bx2)
			let align_y = hit_test_edge(20, y1, y2, by1, by2)
			let stretch_x = hit_item.style['justify-self'] == 'stretch'
			let stretch_y = hit_item.style['align-self'  ] == 'stretch'
			if (align_x && align_y) {
				push_in_item()
				if (align_x && !stretch_x)
					hit_item.style['justify-self'] = align_x
				if (align_y && !stretch_y)
					hit_item.style['align-self'  ] = align_y
				update_item_overlay()
			} else {
				pop_out_item()
				hit_item.x = !stretch_x ? x : e.client_rect().left
				hit_item.y = !stretch_y ? y : e.client_rect().top
				update_item_overlay()
			}

		}

		let dragging, drag_mx, drag_my

		e.on('pointerdown', function(ev) {
			if (!hit_item) return
			dragging = true
			drag_mx = ev.clientX
			drag_my = ev.clientY
			this.setPointerCapture(ev.pointerId)
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
			let align_x = hit_item.style['justify-self']
			let align_y = hit_item.style['align-self'  ]
			if (align_x == 'stretch' || align_x == 'center') {
				align_x = align_x == 'stretch' ? 'center' : 'stretch'
				hit_item.style['justify-self'] = align_x
			}
			if (align_y == 'stretch' || align_y == 'center') {
				align_y = align_y == 'stretch' ? 'center' : 'stretch'
				hit_item.style['align-self'  ] = align_y
			}
			hit_item.w = align_x == 'stretch' ? 'auto' : null
			hit_item.h = align_y == 'stretch' ? 'auto' : null
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

		let cursors = {
			left         : 'ew-resize',
			right        : 'ew-resize',
			top          : 'ns-resize',
			bottom       : 'ns-resize',
		}

		e.on('pointermove', function(mx, my, ev) {
			if (moving) {
				move_item(mx, my)
				return false
			} else if (dragging) {
				if (hit_area = 'move')
					if (max(abs(mx - drag_mx), abs(my - drag_my)) > 10)
						start_move_item(mx, my)
				return false
			}
			hit_item = null
			hit_area = null
			let cur
			for (let item of e.items) {
				if (item.client_rect().contains(mx, my)) {
					hit_area = 'move'
					hit_item = item
					break
				}
				hit_area = item.hit_test_sides(ev.clientX, ev.clientY, 10, 10)
				cur = cursors[hit_area]
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
