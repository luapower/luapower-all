/*

CONFIG

	config('analytics_ua')

*/

function analytics_pageview() {} // stub

function analytics_init() {
	if (!config('analytics_ua', false)) return

	(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
	(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
	m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
	})(window,document,'script','//www.google-analytics.com/analytics.js','analytics');

	var ua = config('analytics_ua')
	if (typeof ua == 'string')
		ua = [ua]

	for(var i=0; i < ua.length; i++)
		analytics('create', ua[i], 'auto', {name : 'ga'+i})

	analytics_pageview = function() {

		// we need to give it the url because it doesn't have it for some reason.
		var url = window.location.protocol +
			'//' + window.location.hostname +
			window.location.pathname +
			window.location.search

		for(var i=0; i < ua.length; i++) {
			analytics('ga'+i+'.send', 'pageview', {
				useBeacon: true,
				page: url,
			})
			analytics('ga'+i+'.require', 'displayfeatures', {
				useBeacon: true,
				page: url,
			})
		}
	}
}
