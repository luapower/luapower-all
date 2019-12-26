
function ellipsis(s, maxlen) {
	return s.substring(0, maxlen-1) + (s.length <= maxlen ? '' : '...')
}

// github events -------------------------------------------------------------

function github_api_(url, success) {
	$.ajax({
		url: 'https://api.github.com/' + url + (url.indexOf('?') >= 0 ? '&' : '?') + 'callback=?',
		cache: true,  // because of github's aggressive throttling policies
		dataType: 'jsonp',
		jsonpCallback:'ghajpc', // a global function will be created so careful what you name here
		success: success,
	})
}

function github_api(url, success) {
	var try_again
	try_again = function(data) {
		if (data.meta.status == 304) { // github api is shit
			github_api_(url, try_again)
		} else {
			success(data)
		}
	}
	github_api_(url, try_again)
}

function github_date(date) {
	return new Date(date).toUTCString().slice(5, 16)
}

function ahref(href, text, attrs) {
	return '<a' + (attrs ? ' ' + attrs : '') + (href ? ' href="' + href + '"' : '') + '>' + text + '</a>'
}

function link(link, attrs) {
	return ahref(link[1], link[0], attrs)
}

function get_repo_link(repo, packages) {
	var plink
	var project
	if (repo.match(/^luapower\//)) { // it's a luapower repo
		var project = repo.replace(/^luapower\//, '')
		if (project in packages)
			plink = link(packages[project].link)
	}
	// we're not interested in news for non-packages (if we were, we would do the following)
	// if(!plink) plink = ahref('https://github.com/' + repo, project || repo)
	return plink
}

function add_news_rows(rows, event, packages) {
	var maxtext = 80

	if (event.type != 'PushEvent' && event.type != 'CreateEvent' && event.type != 'IssuesEvent')
		return

	var plink = get_repo_link(event.repo.name, packages)
	if (!plink) return

	var s =
		'<td style="width: 10%">' + github_date(event.created_at) + '</td>' +
		'<td style="width: 8%">' +
			'<a href="https://github.com/' + event.actor.login + '">' + event.actor.login + '</a>' +
		'</td>' +
		'<td style="width: 12%">' + plink + '</td>' +
		'<td style="width: 70%">'

	if (event.type == 'PushEvent') {
		for (var i = 0; i < event.payload.commits.length; i++) {
			var commit = event.payload.commits[i]
			var url = 'https://github.com/' + event.repo.name + '/commit/' + commit.sha
			if (commit.message != 'unimportant')
				rows.push(s + ahref(url, ellipsis(commit.message, maxtext)) + '</td>')
		}
	} else if (event.type == 'CreateEvent' && event.payload.ref_type == 'tag') {
		var url = 'https://github.com/' + event.repo.name + '/tree/' + event.payload.ref
		rows.push(s + 'New tag: <b>' + ahref(url, event.payload.ref) + '</b>' + '</td>')
	} else if (event.type == 'IssuesEvent') {
		var url = 'https://github.com/' + event.repo.name + '/issues/' + event.payload.issue.number
		var text = 'issue <b>' + event.payload.action + '</b>: ' +
						ahref(url, ellipsis(event.payload.issue.title, maxtext - 15))
		rows.push(s + text + '</td>')
	}
}

function set_news_table(rows, events, packages) {
	var s = '<h3>News</h3>'
	s = s + '<table width="100%">'
	s = s + '<tr>' + rows.join('</tr><tr>') + '</tr>'
	s = s + '</table>'

	$('.news_table').html(s)
	fix_external_links()
}

function load_github_events(packages) {
	if ($('.news_table').length == 0) return
	var page = 1
	var maxpage = 10
	var rows = []
	var maxrows = 10
	var try_next
	try_next = function(events) {
		for(var i=0; i < events.data.length; i++) {
			add_news_rows(rows, events.data[i], packages)
		}
		if (page < maxpage && rows.length < maxrows) {
			page += 1
			github_api('orgs/luapower/events?page=' + page, try_next)
		} else {
			rows = rows.slice(0, maxrows)
			set_news_table(rows, events, packages)
		}
	}
	github_api('orgs/luapower/events?page=' + page, try_next)
}
