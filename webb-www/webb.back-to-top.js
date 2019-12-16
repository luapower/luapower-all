
// back-top-top button

$(function() {
	var btn = $('.back-to-top')
	$(window).scroll(function() {
		btn.toggleClass('visible', $(this).scrollTop() > $(window).height())
	})
	btn.on('click', function(event) {
		event.preventDefault()
		$('html, body').stop().animate({ scrollTop: 0, }, 700, 'easeOutQuint')
	})
})

