/*

	webb | time formatting
	Written by Cosmin Apreutesei. Public Domain.

TIME FORMATTING

	rel_time(s) -> s
	timeago(timestamp) -> s
	parse_date(s) -> d
	format_time(d) -> s
	is_today(d) -> t|f
	shortdate(d, showtime) -> s
	longdate(d, showtime) -> s
	from_date(d) -> s
	update_timeago()                          update all .timeago elements

*/

$(function() {

function rel_time(s) {
	if (s > 2 * 365 * 24 * 3600)
		return S('years', '{0} years').format((s / (365 * 24 * 3600)).toFixed(0))
	else if (s > 2 * 30.5 * 24 * 3600)
		return S('months', '{0} months').format((s / (30.5 * 24 * 3600)).toFixed(0))
	else if (s > 1.5 * 24 * 3600)
		return S('days', '{0} days').format((s / (24 * 3600)).toFixed(0))
	else if (s > 2 * 3600)
		return S('hours', '{0} hours').format((s / 3600).toFixed(0))
	else if (s > 2 * 60)
		return S('minutes', '{0} minutes').format((s / 60).toFixed(0))
	else
		return S('one_minute', '1 minute')
}

function timeago(time) {
	var s = (Date.now() / 1000) - time
	return (s > 0 ? S('time_ago', '{0} ago') : S('in_time', 'in {0}')).format(rel_time(Math.abs(s)))
}

var short_months =
	['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
var months =
	['January','February','Mars','April','May','June','July','August','September','October','November','December']

function zeroes(n, d) {
	return Array(Math.max(d - String(n).length + 1, 0)).join(0) + n
}

function parse_date(s) {
	var a = s.split(/[^0-9]/)
	return new Date (a[0], a[1]-1, a[2], a[3], a[4], a[5])
}

function format_time(d) {
	return zeroes(d.getHours(), 2) + ':' + zeroes(d.getMinutes(), 2)
}

function is_today(d) {
	var now = new Date()
	return
		d.getDate() == now.getDate() &&
		d.getMonth() == now.getMonth() &&
		d.getFullYear() == now.getFullYear()
}

function format_date(date, months, showtime) {
	var d = parse_date(date)
	if (is_today(d)) {
		return S('today', 'Today') + (showtime ? format_time(d) : '')
	} else {
		var now = new Date()
		var day = d.getDate()
		var month = S(months[d.getMonth()].toLowerCase(), months[d.getMonth()])
		var year = (d.getFullYear() != now.getFullYear() ? d.getFullYear() : '')
		return S('date_format', '{year} {month} {day} {time}').format({
			day: day,
			month: month,
			year: year,
			time: (showtime == 'always' ? format_time(d) : '')
		})
	}
}

function shortdate(date, showtime) {
	return format_date(date, short_months, showtime)
}

function longdate(date, showtime) {
	return format_date(date, months, showtime)
}

function from_date(d) {
	return (d.match(/Azi/) ? 'de' : S('from', 'from')) + ' ' + d
}

function update_timeago_elem() {
	var time = parseInt($(this).attr('time'))
	if (!time) {
		// set client-relative time from timeago attribute
		var time_ago = parseInt($(this).attr('timeago'))
		if (!time_ago) return
		time = (Date.now() / 1000) - time_ago
		$(this).attr('time', time)
	}
	$(this).html(timeago(time))
}

function update_timeago() {
	$('.timeago').each(update_timeago_elem)
}

setInterval(update_timeago, 60 * 1000)

})
