
// persistence ---------------------------------------------------------------

function setcookie(k, v) {
	jQuery.removeCookie(k, {path: '/'})
	jQuery.cookie(k, v, {path: '/'})
}

function getcookie(k, default_v) {
	var v = jQuery.cookie(k)
	if (v === undefined)
		v = default_v
	return v
}

// top button ----------------------------------------------------------------

$(function() {
	var btn = $('.top')
	$(window).scroll(function() {
		btn.toggleClass('visible', $(this).scrollTop() > $(window).height())
	})
	btn.on('click', function(event) {
		event.preventDefault()
		$('html, body').stop().animate({ scrollTop: 0, }, 700, 'easeOutQuint')
	})
})

// spyscroll navbar ----------------------------------------------------------

$(function() {
	var doc = $('.doc')
	var nav = $('#docnav')
	if(!doc.length || !nav.length) return
	if(nav.parents(':hidden').length) return

	// wrap content sections (heading + everything till next heading) into divs
	doc.find('h4').each(function() {
		$(this).nextUntil('h4,h3,h2,h1,enddoc').addBack().wrapAll('<div></div>')
	})
	doc.find('h3').each(function() {
		$(this).nextUntil('h3,h2,h1,enddoc').addBack().wrapAll('<div></div>')
	})
	doc.find('h2').each(function() {
		$(this).nextUntil('h2,h1,enddoc').addBack().wrapAll('<div></div>')
	})
	doc.find('h1').each(function() {
		$(this).nextUntil('h1,enddoc').addBack().wrapAll('<div></div>')
	})

	// wrap API sections
	var apis = doc.find('td > strong')
	apis.each(function() {
		$(this).wrapAll('<div></div>')
	})

	// build the doc nav
	var heads = doc.find('h1,h2,h3,h4')
	var h = heads.add(apis)
	if (h.length > 400) // too many entries. cut the apis
		h = heads
	if (h.length > 400) // still too many entries. cut the h4's too
		h = doc.find('h1,h2,h3')
	if (h.length > 400) // still too many entries. cut the h3's too
		h = doc.find('h1,h2')
	var t = []
	var idx = 1
	var idxs = [] // actually a map {level -> last_index}
	var parent_level = 0
	h.each(function() {
		var h = $(this)
		var level = parseInt(h.prop('tagName').match(/\d/))
		if (level) // heading
			parent_level = level
		else // API section
			level = parent_level + 1
		var parent_idx = idxs[level-1] || ''
		idxs[level] = idx

		var s = h.html().trim()
		if (h.has('code').length) {
			// cut the args part from API declarations
			s = h.find('code').html().trim().replace(/\(.*?\).*/, '()')
			// skip the "require..." headings
			if (h.html().indexOf('require\'') >= 0)
				return
		}
		t.push('<div class="'+
			(s.match(/\=\s*require/) ? 'hidden' : '')+
			' navlevel'+level+'" style="'+
			(parent_idx ? 'display: none;' : '')+
			'" idx='+idx+' parent_idx='+parent_idx+'><a>'+s+'</a></div>')
		h.parent().attr('idx', idx)

		idx++
	})
	nav.html(t.join(''))

	// activate the doc nav links
	nav.on('click', 'a', function(e) {
		e.preventDefault()
		var i = $(this).parent().attr('idx')
		$('html, body').stop().animate({
			scrollTop: doc.find('[idx='+i+']').offset().top - 10
		}, 700, 'easeOutQuint')
	})

	// scroll spy on the section divs
	doc.find('div[idx]')
		.on('scrollSpy:enter',
			function() {
				var i = $(this).attr('idx')
				var d = nav.find('[idx='+i+']')
				d.addClass('selected')
				nav.find('[parent_idx="'+i+'"]').show()
			})
		.on('scrollSpy:exit',
			function() {
				var i = $(this).attr('idx')
				var d = nav.find('[idx='+i+']')
				d.removeClass('selected')
				nav.find('[parent_idx="'+i+'"]').hide()
			})
		.scrollSpy()

	// make the doc nav follow the scroll.
	$(window).scroll(function() {
		var top0 = nav.prev().offset().top
		var scrolltop = $(window).scrollTop()
		// compute the vertical space (min_y, max_y) that we have available for the nav.
		var min_y = Math.max(20, top0 - scrolltop)
		var win_h = $(window).height()
		var max_y = Math.min(win_h - 10, $('.footer').offset().top - scrolltop - 20)
		var max_h = max_y - min_y
		// find out where we would want to put the nav.
		var nav_h = nav.height()
		var sel = nav.find('.selected:visible')
		var sel_h1 = sel.first() .offset().top - nav.offset().top
		var sel_h2 = sel.last()  .offset().top - nav.offset().top
		var sel_h = (sel_h1 + sel_h2) / 2
		var rel_y = h < max_h ? 0 : 0 - sel_h + max_h/2
		// constrain the wanted offset so that the nav fully encloses the available space.
		var rel_y = Math.max(rel_y, max_h - nav_h)
		var rel_y = Math.min(rel_y, 0)
		nav.css('position', 'fixed').css('bottom', '').css('top', min_y + rel_y)
	})
})

// infotips ------------------------------------------------------------------

$(function() {

	$('.infotip').each(function() {
		var s = $(this).html()
		var a = $('<a class="infotip"><i class="fa fa-question-circle"></i></a>')
		a.attr('title', s)
		$(this).replaceWith(a)
	})

	$('.infotip').mousedown(function(e) {
		e.preventDefault() // prevent selecting as text
		$(this).data('tooltipsy').show() // for touch...
	})

	$('.infotip').tooltipsy({
		delay: 200,
	}).show()

	$('.hastip').tooltipsy({
	    delay: 1000,
	})

})

// lights --------------------------------------------------------------------

function get_lights_state() { return getcookie('lights') == 'on' }
function set_lights_state(on) { setcookie('lights', on ? 'on' : 'off') }

function set_lights_button_text(on) {
	jQuery('.lights_icon').removeClass('fa-toggle-on fa-toggle-off')
	jQuery('.lights_icon').addClass('fa-toggle-' + (on ? 'on' : 'off'))
}

function set_lights_button() {
	// there was no button to set when the lights was set so we set it now
	set_lights_button_text(get_lights_state())
	$('.lights_btn').mousedown(function(e) {
		e.preventDefault() // prevent selecting as text
		set_lights(!get_lights_state())
	})
}

function set_lights(on) {
	if (on !== true && on !== false)
		on = get_lights_state()

	jQuery('#lights_css')
		.attr('href', '')
		.attr('href', '/lights' + (on ? 'on' : 'off') + '.css')

	//jQuery('body')[0].style.webkitTransform = element.style.webkitTransform

	set_lights_state(on)
	set_lights_button_text(on)
}

$(set_lights_button)

// grouped switch buttons ----------------------------------------------------

$(function() {
	$('.switch_group').each(function() {
		var grp = $(this)
		var grpcls = grp.attr('switch_group_for')
		var persistent = grp.attr('persistent')
		function activate(pcls) {
			var cls = pcls && grp.find('[switch_for="'+pcls+'"]').length &&
				pcls || grp.attr('active_switch')
			grp.find('[switch_for]').addClass('disabled')
			grp.find('[switch_for="'+cls+'"]').removeClass('disabled')
			$(grpcls).addClass('hidden')
			$(cls).removeClass('hidden')
			if (persistent)
				setcookie('switch'+grpcls, pcls || cls)
		}
		// make switches clickable
		grp.find('[switch_for]').click(function() {
			var cls = $(this).attr('switch_for')
			activate(cls)
		})
		// find the active switch and click on it
		activate(persistent && getcookie('switch'+grpcls))
	})
})

function init_switch(grp, val) {
	$('[switch_for="'+val+'"]').click()
}

// shell switch buttons ------------------------------------------------------

$(function() {
	var win = navigator.userAgent.indexOf('Windows') >= 0

	$('.shell_btn').html(
		'<a switch_for=".windows_shell" class="shell_switch' +
				(!win ? ' disabled"' : '"') + '>' +
			'<span class="icon-mingw"></span>' +
		'</a>' +
		'<a switch_for=".unix_shell" class="shell_switch' +
				(!win ? '"' : ' disabled"') + '>' +
			'<span class="icon-linux"></span>' +
			'<span class="icon-osx"></span>' +
		'</a>')

	$('.shell_btn .shell_switch').click(function() {
		$('.shell_btn .shell_switch').addClass('disabled')
		$('.unix_shell, .windows_shell').hide()
		var switch_for = $(this).attr('switch_for')
		$(switch_for).show()
		$('.shell_btn .shell_switch[switch_for="'+switch_for+'"]')
			.removeClass('disabled')
	})

	$('.shell_btn .shell_switch[switch_for=".'+
		(win ? 'windows' : 'unix')+'_shell"]').click()

})

// misc ----------------------------------------------------------------------

function fix_external_links() {
	// mark all external links and make them open in a new window
	$('a[href]:not(.download_link):not(.download_btn)').each(function() {
		var url = $(this).attr('href')
		if (url.match(/\w+:\/\//)) {
			$(this).addClass('external_link').attr('target', '_blank')
		}
	})
}

$(function() {

	fix_external_links()

	// make headings clickable
	$('.doc').find('h1,h2,h3,h4').each(function() {
		$(this).wrap('<a></a>').parent().attr('href', location.pathname +
			(location.search ? '?' + location.search : '') +
				'#' + $(this).attr('id'))
	})

	// create links on all back-references to all code headers
	var t1 = {} // exact match
	var t2 = {} // fuzzy match (without args and retval, just the name)
	$('.doc code').each(function() {
		var self = $(this)
		if (!self.parent().attr('id')) {
			var s1 = self.html().trim()
			if (s1) {
				t1[s1] = t1[s1] ? t1[s1].add(self) : self
				var s2 = s1.replace(/\(.*?\).*/, '()') // strip arg lists
				t2[s2] = t2[s2] ? t2[s2].add(self) : self
			}
		}
	})
	$('.doc').find('h1,h2,h3,h4').filter('[id]').each(function() {
		var self = $(this)
		var id = self.attr('id')
		self.find('code').each(function() {
			var s1 = $(this).html().trim()
			if (s1) {
				var s2 = s1.replace(/\(.*?\).*/, '()') // strip arg lists
				var target1 = t1[s1]
				var target2 = t2[s2]
				if (target1) { // perfect match
					target1.wrap('<a></a>').parent().attr('href', '#'+id)
					t1[s1] = null
					t2[s2] = null // assume no more fuzzy back refs?
				} else if (target2) { // fuzzy match
					target2.wrap('<a></a>').parent().attr('href', '#'+id)
					t2[s2] = null
				}
			}
		})
	})

	// make all images zoomable
	$.featherlight.defaults.closeOnClick = 'anywhere'
	$('img').each(function() {
		if (!$(this).closest('a').length) {
			var target = $(this).clone().css('cursor', 'pointer')
			$(this).css('cursor', 'pointer').featherlight(target)
		}
	})

	// make time and reltime switchable and the option persistent
	var reltime = getcookie('reltime', 'true') == 'true'
	function setreltime() {
		$('.time[reltime][time]').each(function() {
			$(this).html(reltime ? $(this).attr('reltime') : $(this).attr('time'))
		})
	}
	setreltime()
	$('.time[reltime][time]').click(function() {
		reltime = !reltime
		setreltime()
		setcookie('reltime', reltime)
	})

	// make faq button red when on faq page
	if (location.pathname == '/faq')
		$('.faq_btn').css({'background-color': '#e4741f'})
			.find('a').css('color', '#fff')

	// bind enter key for the search input
	$('.search_input').keydown(function(e) {
		if (e.which == 13)
			location = '/grep/'+encodeURIComponent($(this).val())
	})

	// bind click on search icon
	$('.search_icon').click(function() {
		location = '/grep/'+encodeURIComponent($('.search_input').val())
	})

	// show wrapping on <pre> items
	// TODO: fix this
	/*
	$('.doc pre > code').each(function() {
		$(this).html('<div>'+$(this).html()
			.replace(/\n/g, '</div><div>')+'</div>')
	})
	*/

	// indent API paragraphs
	$('.doc a > h3 > code').parent().parent()
		.nextUntil('a > h2, a > h3', 'p, ul, blockquote, table').addClass('indent')

	// remove left and right-side bars if the window width is too narrow
	function check_size() {
		var w = $(window).width()
		$('.rightside').toggle(w > 745)
		$('.leftside').toggle(w > 680)
	}
	$(window).resize(check_size)
	check_size()

})

