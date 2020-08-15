
// ---------------------------------------------------------------------------
// calendar
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
		nav: cell_nav({format: format_month}),
		listbox: {
			format_item: format_month,
		},
	})
	e.sel_year = spin_input({
		classes: 'x-calendar-sel-year',
		nav: cell_nav({
			min: 100,
			max: 3000,
		}),
		button_style: 'left-right',
	})
	e.header = div({class: 'x-calendar-header'},
		e.sel_day, e.sel_day_suffix, e.sel_month, e.sel_year)
	e.weekview = H.table({class: 'x-calendar-weekview'})
	e.add(e.header, e.weekview)

	e.sel_year.attach()
	e.sel_month.attach()

	function as_ts(v) {
		return v != null && e.field && e.field.to_time ? e.field.to_time(v) : v
	}

	e.update_val = function(v) {
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

	function update_weekview(d, weeks) {
		let today = day(time())
		let this_month = month(d)
		d = week(this_month)
		e.weekview.clear()
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
					s = s + (d == day(as_ts(e.input_val)) ? ' focused selected' : '')
					let td = H.td({class: 'x-calendar-day x-item'+s}, floor(1 + days(d - m)))
					td.day = d
					td.on('pointerdown', day_pointerdown)
					tr.add(td)
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

	function day_pointerdown() {
		set_ts(this.day)
		e.sel_month.cancel()
		e.focus()
		e.fire('val_picked') // picker protocol
		return false
	}

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

	e.weekview.on('wheel', function(dy) {
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
	e.field_type = 'date'
	e.picker = calendar()
	dropdown.construct(e)
})

