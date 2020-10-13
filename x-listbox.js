
// ---------------------------------------------------------------------------
// listbox
// ---------------------------------------------------------------------------

component('x-listbox', function(e) {

	e.props.align_x = {default: 'stretch'}
	e.props.align_y = {default: 'stretch'}

	val_widget(e, true)
	nav_widget(e)
	focusable_widget(e)

	e.can_focus_cells = false

	e.prop('orientation'   , {store: 'attr', type: 'enum', enum_values: ['vertical', 'horizontal'], default: 'vertical'})
	e.prop('can_move_items', {store: 'var', type: 'bool', default: true})
	e.prop('item_type'     , {store: 'var', default: 'richtext'})

	e.display_col = 0

	let init = e.init
	e.init = function() {
		init()
		init_as_picker()
		if (e.items) {
			create_rows_items()
			e.items = null
		}
	}

	// item-based rowset ------------------------------------------------------

	function setup_item(item) {
		item.classes = 'x-listbox-item x-item'
		item.on('pointerdown', item_pointerdown)
	}

	function create_rows_items() {

		function rows_added(rows, ri1) {
			for (let row of rows) {
				let item = e.create_item()
				setup_item(item)
				row[0] = item
			}
		}
		e.on('rows_added', rows_added)

		e.display_col = 0
		let rows = []
		for (let item of e.items) {
			if (isobject(item) && item.type)
				item = component.create(item)
			if (item instanceof HTMLElement)
				setup_item(item)
			rows.push([item])
		}
		e.rowset = {
			fields: [{format: e.format_item}],
			rows: rows,
		}
	}

	e.create_item = function() {
		return component.create({type: e.item_type})
	}

	e.format_item = function(item) {
		return isobject(item) ? item.text : item
	}

	e.property('focused_item', function() {
		return e.focused_row ? e.focused_row[0] : null
	})

	e.child_widgets = function() {
		let widgets = []
		for (let ce of e.children)
			if (ce.iswidget)
				widgets.push(ce)
		return widgets
	}

	e.serialize = function() {
		let t = e.serialize()
		if (isobject(t) && e.items) {
			t.items = []
			for (let ce of e.child_widgets)
				t.items.push(ce.serialize())
		}
		return t
	}

	// responding to nav changes ----------------------------------------------

	e.do_update_item = function(item, row) { // stub
		if (item.iswidget)
			return
		item.set(e.row_display_val(row))
	}

	let update_val = e.do_update
	e.do_update = function(opt) {

		if (opt.reload) {
			e.reload()
			opt.rows = true
		}

		if (opt.rows) {
			e.clear()
			for (let row of e.rows) {
				let item
				if (e.items && row[0] instanceof HTMLElement) {
					item = row[0]
				} else {
					item = H.div({})
					setup_item(item)
				}
				e.add(item)
			}
		}

		if (opt.rows || opt.vals || opt.fields)
			for (let i = 0; i < e.rows.length; i++)
				e.do_update_item(e.at[i], e.rows[i])

		if (!opt || opt.val)
			update_val()

		if (opt.rows || opt.state)
			if (e.at.length)
				for (let i = 0; i < e.rows.length; i++) {
					let item = e.at[i]
					item.class('focused', e.focused_row_index == i)
					item.class('selected', !!e.selected_rows.get(e.rows[i]))
				}

		if (opt.scroll_to_cell)
			e.scroll_to_cell(...opt.scroll_to_cell)
	}

	e.do_update_cell_state = function(ri, fi, prop, val) {
		e.do_update_item(e.at[ri], e.rows[ri])
	}

	// drag-move items --------------------------------------------------------

	e.property('axis', function() { return e.orientation == 'horizontal' ? 'x' : 'y' })

	live_move_mixin(e)

	e.set_movable_element_pos = function(i, x) {
		let item = e.at[i]
		item[e.axis] = x - item._offset
	}

	e.movable_element_size = function(i) {
		return e.at[i][e.axis == 'x' ? 'offsetWidth' : 'offsetHeight']
	}

	function item_pointerdown(ev, mx, my) {

		if (ev.ctrlKey && ev.shiftKey) {
			e.focus_cell(false, false)
			return // enter editing / select widget
		}

		e.focus()
		if (!e.focus_cell(this.index, null, 0, 0, {
			input: e,
			must_not_move_row: true,
			expand_selection: ev.shiftKey,
			invert_selection: ev.ctrlKey,
		}))
			return false

		let dragging, drag_mx, drag_my

		let ri1 = e.focused_row_index
		let ri2 = or(e.selected_row_index, ri1)

		let move_ri1 = min(ri1, ri2)
		let move_ri2 = max(ri1, ri2)
		let move_n = move_ri2 - move_ri1 + 1

		let item1 = e.at[move_ri1]
		let item2 = e.at[move_ri2]
		let horiz = e.axis == 'x'
		let move_w = horiz ? 0 : item1.offsetWidth
		let move_h = horiz ? 0 : item2.oy + item2.offsetHeight - item1.oy

		let scroll_timer, mx0, my0

		function item_pointermove(ev, mx, my, down_mx, down_my) {
			if (!dragging) {
				dragging = e.can_move_items
					&& (e.axis == 'x' ? abs(down_mx - mx) > 4 : abs(down_my - my) > 4)
				if (dragging) {
					e.class('moving')
					for (let ri = 0; ri < e.rows.length; ri++) {
						let item = e.at[ri]
						item._offset = item[e.axis == 'x' ? 'ox' : 'oy']
						item.class('moving', ri >= move_ri1 && ri <= move_ri2)
					}
					e.move_element_start(move_ri1, move_n, 0, e.at.length)
					drag_mx = down_mx + e.scrollLeft - e.at[move_ri1].ox
					drag_my = down_my + e.scrollTop  - e.at[move_ri1].oy
					mx0 = mx
					my0 = my
					scroll_timer = every(.1, item_pointermove)
				}
			} else {
				mx = or(mx, mx0)
				my = or(my, my0)
				mx0 = mx
				my0 = my
				let x = mx - drag_mx + e.scrollLeft
				let y = my - drag_my + e.scrollTop
				e.move_element_update(horiz ? x : y)
				e.scroll_to_view_rect(null, null, x, y, move_w, move_h)
			}
		}

		function item_pointerup(ev, mx, my) {
			if (dragging) {

				clearInterval(scroll_timer)

				let over_ri = e.move_element_stop()
				let insert_ri = over_ri - (over_ri > move_ri1 ? move_n : 0)

				let move_state = e.start_move_selected_rows()
				move_state.finish(insert_ri)

				e.class('moving', false)
				for (let item of e.children) {
					item.class('moving', false)
					item.x = null
					item.y = null
				}

			} else if (!(ev.shiftKey || ev.ctrlKey)) {
				e.fire('val_picked', {input: e}) // picker protocol
			}

			return false
		}

		return this.capture_pointer(ev, item_pointermove, item_pointerup)
	}

	// key bindings -----------------------------------------------------------

	// find the next item before/after the selected item that would need
	// scrolling, if the selected item would be on top/bottom of the viewport.
	function page_item(forward) {
		if (!e.focused_row)
			return forward ? e.first : e.last
		let item = e.at[e.focused_row_index]
		let sy0 = item.oy + (forward ? 0 : item.offsetHeight - e.clientHeight)
		item = forward ? item.next : item.prev
		while(item) {
			let [sx, sy] = item.make_visible_scroll_offset(0, sy0)
			if (sy != sy0)
				return item
			item = forward ? item.next : item.prev
		}
		return forward ? e.last : e.first
	}

	e.on('keydown', function(key, shift, ctrl) {
		let rows
		switch (key) {
			case 'ArrowUp'   : rows = -1; break
			case 'ArrowDown' : rows =  1; break
			case 'ArrowLeft' : rows = -1; break
			case 'ArrowRight': rows =  1; break
			case 'Home'      : rows = -1/0; break
			case 'End'       : rows =  1/0; break
		}
		if (rows) {
			e.focus_cell(true, null, rows, 0, {
				input: e,
				expand_selection: shift,
			})
			return false
		}

		if (key == 'PageUp' || key == 'PageDown') {
			let item = page_item(key == 'PageDown')
			if (item)
				e.focus_cell(item.index, null, 0, 0, {
					input: e,
					expand_selection: shift,
				})
			return false
		}

		if (key == 'Enter') {
			if (e.focused_row)
				e.fire('val_picked', {input: e}) // picker protocol
			return false
		}

		if (key == 'a' && ctrl) {
			e.select_all_cells()
			return false
		}

		// insert key: insert row
		if (key == 'Insert')
			if (e.insert_row(true, true))
				return false

	})

	e.scroll_to_cell = function(ri, fi) {
		let item = e.at[ri]
		item.make_visible()
	}

	e.on('keypress', function(c) {
		if (e.display_field)
			e.quicksearch(c, e.display_field)
	})

	// picker protocol --------------------------------------------------------

	function init_as_picker() {
		if (!e.dropdown)
			return
		e.xmodule_noupdate = true
		e.auto_focus_first_cell = false
		e.can_select_multiple = false
		e.can_move_items = false
		e.xmodule_noupdate = false
	}

})

hlistbox = function(...options) {
	return listbox({orientation: 'horizontal'}, ...options)
}

// ---------------------------------------------------------------------------
// list dropdown
// ---------------------------------------------------------------------------

component('x-list-dropdown', function(e) {

	nav_dropdown_widget(e)

	e.create_picker = function(opt) {
		return component.create(update(opt, {
			type: 'listbox',
			gid: e.gid && e.gid + '.picker',
			val_col: e.val_col,
			display_col: e.display_col,
			items: e.items,
			rowset: e.rowset,
			rowset_name: e.rowset_name,
		}, e.listbox))
	}

})

// ---------------------------------------------------------------------------
// select button
// ---------------------------------------------------------------------------

component('x-select-button', function(e) {

	listbox.construct(e)

	e.orientation = 'horizontal'
	e.can_move_items = false
	e.auto_focus_first_cell = false
	e.can_select_multiple = false

})

// ---------------------------------------------------------------------------
// countries listbox & dropdown
// ---------------------------------------------------------------------------

countries_rowset = {
	fields: [
		{name: 'country_flag',
			format: function(v, row) {
				if (v == null)
					return ''
				return div({class: 'x-countries-listbox-flag-cell'},
					tag('img', {
						class: 'x-countries-listbox-flag-image',
						src: '/country-flags/'+row[1]+'_16.png',
					})
				)
			},
		},
		{name: 'country_code'},
		{name: 'country_name'},
	],
	rows: [
		[0, 'AE', 'United Arab Emirates'],
		[0, 'AF', 'Afghanistan'],
		[0, 'AG', 'Antigua and Barbuda'],
		[0, 'AI', 'Anguilla'],
		[0, 'AL', 'Albania'],
		[0, 'AM', 'Armenia'],
		[0, 'AO', 'Angola'],
		[0, 'AQ', 'Antarctica'],
		[0, 'AR', 'Argentina'],
		[0, 'AS', 'American Samoa'],
		[0, 'AT', 'Austria'],
		[0, 'AU', 'Australia'],
		[0, 'AW', 'Aruba'],
		[0, 'AX', 'Aland Islands'],
		[0, 'AZ', 'Azerbaijan'],
		[0, 'BA', 'Bosnia and Herzegovina'],
		[0, 'BB', 'Barbados'],
		[0, 'BD', 'Bangladesh'],
		[0, 'BE', 'Belgium'],
		[0, 'BF', 'Burkina Faso'],
		[0, 'BG', 'Bulgaria'],
		[0, 'BH', 'Bahrain'],
		[0, 'BI', 'Burundi'],
		[0, 'BJ', 'Benin'],
		[0, 'BM', 'Bermuda'],
		[0, 'BN', 'Brunei Darussalam'],
		[0, 'BO', 'Bolivia (Plurinational State of)'],
		[0, 'BR', 'Brazil'],
		[0, 'BS', 'Bahamas'],
		[0, 'BT', 'Bhutan'],
		[0, 'BV', 'Bouvet Island'],
		[0, 'BW', 'Botswana'],
		[0, 'BY', 'Belarus'],
		[0, 'BZ', 'Belize'],
		[0, 'CA', 'Canada'],
		[0, 'CC', 'Cocos (Keeling) Islands'],
		[0, 'CD', 'Congo (Democratic Republic of the)'],
		[0, 'CF', 'Central African Republic'],
		[0, 'CG', 'Congo'],
		[0, 'CH', 'Switzerland'],
		[0, 'CI', 'Cote D\'ivoire'],
		[0, 'CK', 'Cook Islands'],
		[0, 'CL', 'Chile'],
		[0, 'CM', 'Cameroon'],
		[0, 'CN', 'China'],
		[0, 'CO', 'Colombia'],
		[0, 'CR', 'Costa Rica'],
		[0, 'CU', 'Cuba'],
		[0, 'CV', 'Cabo Verde'],
		[0, 'CX', 'Christmas Island'],
		[0, 'CY', 'Cyprus'],
		[0, 'CZ', 'Czechia'],
		[0, 'DE', 'Germany'],
		[0, 'DJ', 'Djibouti'],
		[0, 'DK', 'Denmark'],
		[0, 'DM', 'Dominica'],
		[0, 'DO', 'Dominican Republic'],
		[0, 'DZ', 'Algeria'],
		[0, 'EC', 'Ecuador'],
		[0, 'EE', 'Estonia'],
		[0, 'EG', 'Egypt'],
		[0, 'EH', 'Western Sahara'],
		[0, 'ER', 'Eritrea'],
		[0, 'ES', 'Spain'],
		[0, 'ET', 'Ethiopia'],
		[0, 'FI', 'Finland'],
		[0, 'FJ', 'Fiji'],
		[0, 'FK', 'Falkland Islands (Malvinas)'],
		[0, 'FM', 'Micronesia (Federated States of)'],
		[0, 'FO', 'Faroe Islands'],
		[0, 'FR', 'France'],
		[0, 'GA', 'Gabon'],
		[0, 'GB', 'United Kingdom of Great Britain and Northern Ireland'],
		[0, 'GD', 'Grenada'],
		[0, 'GE', 'Georgia'],
		[0, 'GF', 'French Guiana'],
		[0, 'GG', 'Guernsey'],
		[0, 'GH', 'Ghana'],
		[0, 'GI', 'Gibraltar'],
		[0, 'GL', 'Greenland'],
		[0, 'GM', 'Gambia'],
		[0, 'GN', 'Guinea'],
		[0, 'GP', 'Guadeloupe'],
		[0, 'GQ', 'Equatorial Guinea'],
		[0, 'GR', 'Greece'],
		[0, 'GS', 'South Georgia and The South Sandwich Islands'],
		[0, 'GT', 'Guatemala'],
		[0, 'GU', 'Guam'],
		[0, 'GW', 'Guinea-Bissau'],
		[0, 'GY', 'Guyana'],
		[0, 'HK', 'Hong Kong'],
		[0, 'HM', 'Heard Island and Mcdonald Islands'],
		[0, 'HN', 'Honduras'],
		[0, 'HR', 'Croatia'],
		[0, 'HT', 'Haiti'],
		[0, 'HU', 'Hungary'],
		[0, 'ID', 'Indonesia'],
		[0, 'IE', 'Ireland'],
		[0, 'IL', 'Israel'],
		[0, 'IM', 'Isle of Man'],
		[0, 'IN', 'India'],
		[0, 'IO', 'British Indian Ocean Territory'],
		[0, 'IQ', 'Iraq'],
		[0, 'IR', 'Iran (Islamic Republic of)'],
		[0, 'IS', 'Iceland'],
		[0, 'IT', 'Italy'],
		[0, 'JE', 'Jersey'],
		[0, 'JM', 'Jamaica'],
		[0, 'JO', 'Jordan'],
		[0, 'JP', 'Japan'],
		[0, 'KE', 'Kenya'],
		[0, 'KG', 'Kyrgyzstan'],
		[0, 'KH', 'Cambodia'],
		[0, 'KI', 'Kiribati'],
		[0, 'KM', 'Comoros'],
		[0, 'KN', 'Saint Kitts and Nevis'],
		[0, 'KP', 'Korea (Democratic People\'s Republic of)'],
		[0, 'KR', 'Korea (Republic of)'],
		[0, 'KW', 'Kuwait'],
		[0, 'KY', 'Cayman Islands'],
		[0, 'KZ', 'Kazakhstan'],
		[0, 'LA', 'Lao People\'s Democratic Republic'],
		[0, 'LB', 'Lebanon'],
		[0, 'LC', 'Saint Lucia'],
		[0, 'LI', 'Liechtenstein'],
		[0, 'LK', 'Sri Lanka'],
		[0, 'LR', 'Liberia'],
		[0, 'LS', 'Lesotho'],
		[0, 'LT', 'Lithuania'],
		[0, 'LU', 'Luxembourg'],
		[0, 'LV', 'Latvia'],
		[0, 'LY', 'Libya'],
		[0, 'MA', 'Morocco'],
		[0, 'MC', 'Monaco'],
		[0, 'MD', 'Moldova (Republic of)'],
		[0, 'ME', 'Montenegro'],
		[0, 'MF', 'Saint Martin (French Part)'],
		[0, 'MG', 'Madagascar'],
		[0, 'MH', 'Marshall Islands'],
		[0, 'MK', 'North Macedonia'],
		[0, 'ML', 'Mali'],
		[0, 'MM', 'Myanmar'],
		[0, 'MN', 'Mongolia'],
		[0, 'MO', 'Macao'],
		[0, 'MP', 'Northern Mariana Islands'],
		[0, 'MQ', 'Martinique'],
		[0, 'MR', 'Mauritania'],
		[0, 'MS', 'Montserrat'],
		[0, 'MT', 'Malta'],
		[0, 'MU', 'Mauritius'],
		[0, 'MV', 'Maldives'],
		[0, 'MW', 'Malawi'],
		[0, 'MX', 'Mexico'],
		[0, 'MY', 'Malaysia'],
		[0, 'MZ', 'Mozambique'],
		[0, 'NA', 'Namibia'],
		[0, 'NC', 'New Caledonia'],
		[0, 'NE', 'Niger'],
		[0, 'NF', 'Norfolk Island'],
		[0, 'NG', 'Nigeria'],
		[0, 'NI', 'Nicaragua'],
		[0, 'NL', 'Netherlands'],
		[0, 'NO', 'Norway'],
		[0, 'NP', 'Nepal'],
		[0, 'NR', 'Nauru'],
		[0, 'NU', 'Niue'],
		[0, 'NZ', 'New Zealand'],
		[0, 'OM', 'Oman'],
		[0, 'PA', 'Panama'],
		[0, 'PE', 'Peru'],
		[0, 'PF', 'French Polynesia'],
		[0, 'PG', 'Papua New Guinea'],
		[0, 'PH', 'Philippines'],
		[0, 'PK', 'Pakistan'],
		[0, 'PL', 'Poland'],
		[0, 'PM', 'Saint Pierre and Miquelon'],
		[0, 'PN', 'Pitcairn'],
		[0, 'PR', 'Puerto Rico'],
		[0, 'PS', 'Palestine, State of'],
		[0, 'PT', 'Portugal'],
		[0, 'PW', 'Palau'],
		[0, 'PY', 'Paraguay'],
		[0, 'QA', 'Qatar'],
		[0, 'RE', 'Reunion'],
		[0, 'RO', 'Romania'],
		[0, 'RS', 'Serbia'],
		[0, 'RU', 'Russian Federation'],
		[0, 'RW', 'Rwanda'],
		[0, 'SA', 'Saudi Arabia'],
		[0, 'SB', 'Solomon Islands'],
		[0, 'SC', 'Seychelles'],
		[0, 'SD', 'Sudan'],
		[0, 'SE', 'Sweden'],
		[0, 'SG', 'Singapore'],
		[0, 'SH', 'Saint Helena, Ascension and Tristan Da Cunha'],
		[0, 'SI', 'Slovenia'],
		[0, 'SJ', 'Svalbard and Jan Mayen'],
		[0, 'SK', 'Slovakia'],
		[0, 'SL', 'Sierra Leone'],
		[0, 'SM', 'San Marino'],
		[0, 'SN', 'Senegal'],
		[0, 'SO', 'Somalia'],
		[0, 'SR', 'Suriname'],
		[0, 'SS', 'South Sudan'],
		[0, 'ST', 'Sao Tome and Principe'],
		[0, 'SV', 'El Salvador'],
		[0, 'SY', 'Syrian Arab Republic'],
		[0, 'SZ', 'Eswatini'],
		[0, 'TC', 'Turks and Caicos Islands'],
		[0, 'TD', 'Chad'],
		[0, 'TF', 'French Southern Territories'],
		[0, 'TG', 'Togo'],
		[0, 'TH', 'Thailand'],
		[0, 'TJ', 'Tajikistan'],
		[0, 'TK', 'Tokelau'],
		[0, 'TL', 'Timor-Leste'],
		[0, 'TM', 'Turkmenistan'],
		[0, 'TN', 'Tunisia'],
		[0, 'TO', 'Tonga'],
		[0, 'TR', 'Turkey'],
		[0, 'TT', 'Trinidad and Tobago'],
		[0, 'TV', 'Tuvalu'],
		[0, 'TW', 'Taiwan (Province of China)'],
		[0, 'TZ', 'Tanzania, United Republic of'],
		[0, 'UA', 'Ukraine'],
		[0, 'UG', 'Uganda'],
		[0, 'UM', 'United States Minor Outlying Islands'],
		[0, 'US', 'United States of America'],
		[0, 'UY', 'Uruguay'],
		[0, 'UZ', 'Uzbekistan'],
		[0, 'VA', 'Holy See'],
		[0, 'VC', 'Saint Vincent and The Grenadines'],
		[0, 'VE', 'Venezuela (Bolivarian Republic of)'],
		[0, 'VG', 'Virgin Islands (British)'],
		[0, 'VI', 'Virgin Islands (U.S.)'],
		[0, 'VN', 'Viet Nam'],
		[0, 'VU', 'Vanuatu'],
		[0, 'WF', 'Wallis and Futuna'],
		[0, 'WS', 'Samoa'],
		[0, 'YE', 'Yemen'],
		[0, 'YT', 'Mayotte'],
		[0, 'ZA', 'South Africa'],
		[0, 'ZM', 'Zambia'],
		[0, 'ZW', 'Zimbabwe'],
	],
}

function countries_listbox(...opt) {
	return listbox({
		rowset: countries_rowset,
		val_col: 'country_code',
		row_display_val: function(row) {
			return div({class: 'x-countries-listbox-row'},
				this.cell_display_val(row, this.all_fields[0]),
				this.cell_display_val(row, this.all_fields[2])
			)
		},
	}, ...opt)
}

component('x-country-dropdown', function(e) {
	list_dropdown.construct(e)
	e.picker = countries_listbox()
	e.val_col = 'country_code'
	e.display_col = 'country_name'
})


// ---------------------------------------------------------------------------
// colors listbox & dropdown
// ---------------------------------------------------------------------------

default_colors = ['#fff', '#ffa5a5', '#ffffc2', '#c8e7ed', '#bfcfff']

function colors_listbox(...opt) {
	return listbox({
		rowset: {
			fields: [{name: 'color', type: 'color'}],
			rows: [],
		},
		val_col: 'color',
	}, ...opt)
}

component('x-color-dropdown', function(e) {
	list_dropdown.construct(e)
	e.picker = colors_listbox()
	e.val_col = 'color'
	e.display_col = 'color'

	e.set_colors = function(t) {
		e.picker.rowset.rows = t.map(s => [s])
		e.picker.reset()
	}
	e.prop('colors', {store: 'var', default: default_colors})
	e.set_colors(default_colors)

})

// ---------------------------------------------------------------------------
// icons listbox & dropdown
// ---------------------------------------------------------------------------

default_icons = memoize(function() {
	let t = []
	for (let ss of document.styleSheets) {
		if (ss.href && ss.href.ends('/fontawesome.css')) {
			for (let rule of ss.rules) {
				let s = rule.selectorText
				if (s && s.ends('::before')) {
					let [_, cls] = s.match(/^\.([^\:]+)/)
					t.push(cls)
				}
			}
			break
		}
	}
	return t
})

function icons_listbox(...opt) {
	return listbox({
		rowset: {
			fields: [{name: 'icon'}],
			rows: [],
		},
		val_col: 'icon',
		row_display_val: function(row) {
			let s = row[0].replace(/^fa\-/, '')
			return div({class: 'x-icons-listbox-item'},
				div({class: 'x-icons-listbox-icon fa fa-'+s}), s)
		}
	}, ...opt)
}

component('x-icon-dropdown', function(e) {
	list_dropdown.construct(e)
	e.picker = icons_listbox()
	e.val_col = 'icon'
	e.display_col = 'icon'

	e.set_icons = function(t) {
		e.picker.rowset.rows = t.map(s => [s])
		e.picker.reset()
	}
	e.prop('colors', {store: 'var', default: default_icons()})
	e.set_icons(default_icons())
})

