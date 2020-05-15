
// ---------------------------------------------------------------------------
// calendar
// ---------------------------------------------------------------------------

calendar = component('x-calendar', function(e) {

	e.class('x-widget')
	e.class('x-calendar')
	e.class('x-focusable')
	e.attrval('tabindex', 0)

	value_widget(e)

	function format_month(i) {
		return month_name(utctime(0, i), 'short')
	}

	e.sel_day = div({class: 'x-calendar-sel-day'})
	e.sel_day_suffix = div({class: 'x-calendar-sel-day-suffix'})
	e.sel_month = list_dropdown({
		classes: 'x-calendar-sel-month',
		items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
		format: format_month,
		listbox: {
			format_item: format_month,
		},
	})
	e.sel_year = spin_input({
		classes: 'x-calendar-sel-year',
		min: 100,
		max: 3000,
		button_style: 'left-right',
	})
	e.header = div({class: 'x-calendar-header'},
		e.sel_day, e.sel_day_suffix, e.sel_month, e.sel_year)
	e.weekview = H.table({class: 'x-calendar-weekview'})
	e.add(e.header, e.weekview)

	e.init = function() {
		e.init_nav()
	}

	e.attach = function() {
		e.init_value()
		e.bind_nav(true)
	}

	e.detach = function() {
		e.bind_nav(false)
	}

	e.update_value = function(v) {
		t = day(v)
		update_weekview(t, 6)
		let y = year_of(t)
		let n = floor(1 + days(t - month(t)))
		e.sel_day.set(n)
		let day_suffixes = ['', 'st', 'nd', 'rd']
		e.sel_day_suffix.set(locale.starts('en') ?
			(n < 11 || n > 13) && day_suffixes[n % 10] || 'th' : '')
		e.sel_month.value = month_of(t)
		e.sel_year.value = y
	}

	function update_weekview(d, weeks) {
		let today = day(now())
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
					s = s + (d == day(e.input_value) ? ' focused selected' : '')
					let td = H.td({class: 'x-calendar-day x-item'+s}, floor(1 + days(d - m)))
					td.day = d
					td.on('mousedown', day_mousedown)
					tr.add(td)
					d = day(d, 1)
				}
			}
			e.weekview.add(tr)
		}
	}

	// controller

	function day_mousedown() {
		e.set_value(this.day, {input: e})
		e.sel_month.cancel()
		e.focus()
		e.fire('value_picked') // picker protocol
		return false
	}

	e.sel_month.on('value_changed', function(v, ev) {
		if (ev && ev.input) {
			_d.setTime(e.input_value)
			_d.setMonth(this.value)
			e.set_value(_d.valueOf(), {input: e})
		}
	})

	e.sel_year.on('value_changed', function(v, ev) {
		if (ev && ev.input) {
			_d.setTime(e.input_value)
			_d.setFullYear(this.value)
			e.set_value(_d.valueOf(), {input: e})
		}
	})

	e.weekview.on('wheel', function(dy) {
		e.set_value(day(e.input_value, 7 * dy / 100), {input: e})
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
			e.set_value(day(e.input_value, d), {input: e})
			return false
		}
		if (m) {
			_d.setTime(e.input_value)
			if (shift)
				_d.setFullYear(year_of(e.input_value) + m)
			else
				_d.setMonth(month_of(e.input_value) + m)
			e.set_value(_d.valueOf(), {input: e})
			return false
		}
		if (key == 'Home') {
			e.set_value(shift ? year(e.input_value) : month(e.input_value), {input: e})
			return false
		}
		if (key == 'End') {
			e.set_value(day(shift ? year(e.input_value, 1) : month(e.input_value, 1), -1), {input: e})
			return false
		}
		if (key == 'Enter') {
			e.fire('value_picked', {input: e}) // picker protocol
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

	e.pick_near_value = function(delta, ev) {
		e.set_value(day(e.input_value, delta), ev)
		e.fire('value_picked', ev)
	}

})

date_dropdown = component('x-date-dropdown', function(e) {
	e.field_type = 'date'
	e.picker = calendar()
	dropdown.construct(e)
})
