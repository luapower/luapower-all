<script type=x-template id=tree_template>
<table id=tree width=100%>
</tr>
	<th width=300>File
		<a class=infotip>
			Navigate the tree with the arrow keys, page-up/down keys
			or with the mouse.
		</a>
	</th>
	<th width=140>Package</th>
	<th>Description</th>
	{{{rows}}}
</tr>
</table>
</script>
<div id=tree_container></div>
<script>

var root

function showhide_open_children(id, visible) {
	$('#tree [parent_id='+id+']')
		.toggle(visible)
		.filter('.open')
		.each(function() {
			showhide_open_children($(this).attr('id'), visible)
		})
}

function openclose_dir_tr(tr, open) {
	tr.show()
		.toggleClass('open', open)
		.toggleClass('closed', !open)
		.find('.filename .fa')
			.toggleClass('fa-folder-open-o', open)
			.toggleClass('fa-folder-o', !open)
}

function openclose_dir(id, open) {
	var dir = $('#'+id)

	if (!dir.hasClass('dir'))
		return

	if (open === undefined)
		open = dir.hasClass('closed')

	openclose_dir_tr(dir, open)

	var load = dir.data('load')
	if (load)
		load()

	showhide_open_children(id, open)
}

function select_node(id) {
	var oldsel = $('#tree .selected')
	var newsel = $('#'+id)
	oldsel.removeClass('selected')
	newsel.show().addClass('selected')
}

var nextid
var icons = {sh: 'fa-cog', cmd: 'fa-cog'}

function create_node(node, parent_id, level, filter, open_dirs, trs) {

	if (filter && !filter(node))
		return

	var id = 'n'+(nextid++)

	var tr =
		$('<tr/>')
			.attr('id', id)
			.attr('parent_id', parent_id)
			.hide()

	if (node.package)
		tr.attr('package', node.package)
	else
		tr.addClass('untracked')

	trs.push(tr)

	var ext = node.file.match('\.([^.]+)$')[1]
	var icon =
		$('<i class=fa></i>')
			.addClass(
				node.files ?
					'fa-folder-o' :
					(node.type == 'module' || node.type == 'script' ?
						'fa-code' :
						(node.type == 'doc' ?
							'fa-book' :
							(icons[ext] || 'fa-file-o'))))

	var td_filename =
		$('<td class=filename></td>')
			.append(icon)
			.append(node.file)
			.css({'padding-left': 20*level+'px'})

	var td_package = $('<td/>')
	if (node.package) {
		var a_package = $('<a/>')
			.html(node.package === true ?  '' : node.package)
			.click(function(e) {
				exec('/tree/' + $(this).html())
			})
		if (node.show_package) {
			tr.addClass('show_package')
			td_package
				.addClass('package_td')
				.append(a_package)
		}
	} else
		td_package.html('untracked')

	var td_descr = $('<td class=description></td>')
		.html(node.descr)

	tr.append(td_filename, td_package, td_descr)

	tr.click(function(e) {
		openclose_dir(id)
		select_node(id)
		e.preventDefault()
	})

	if (node.files) {
		tr.addClass('dir closed')
		if (node.files.length) {
			if (open_dirs) {
				openclose_dir_tr(tr, true)
				for(var i = 0; i < node.files.length; i++)
					create_node(node.files[i], id, level+1,
						filter, open_dirs, trs)
			} else {
				tr.data('load', function() {
					tr.data('load', false)
					var child_trs = []
					for(var i = 0; i < node.files.length; i++)
						create_node(node.files[i], id, level+1,
							filter, open_dirs, child_trs)
					tr.after(child_trs)
				})
			}
		} else
			tr.addClass('empty_dir')
	}

	return trs
}

function scroll_into_view_if_needed(target) {
	var rect = target.getBoundingClientRect()
	if (rect.bottom > window.innerHeight) {
		target.scrollIntoView(false)
	}
	if (rect.top < 0) {
		target.scrollIntoView()
	}
}

function render_tree(filter, open_dirs) {

	$(window).off('keydown')
	$('#tree_container').html($('#tree_template').html())
	nextid = 1

	$('#tree').append(create_node(root, null, 0, filter, open_dirs, []))
	select_node('n1')
	openclose_dir('n1', true)

	$(window).on('keydown', function(e) {
		var sel = $('#tree .selected')
		if (!sel.length)
			return
		var next
		if (e.key == 'ArrowUp') {
			next = sel.prevAll(':visible:not(:has(th)):first')
		} else if (e.key == 'ArrowDown') {
			next = sel.nextAll(':visible:first')
		} else if (e.key == 'ArrowLeft') {
			if (sel.hasClass('open')) {
				openclose_dir(sel.attr('id'), false)
				e.preventDefault()
			} else {
				next = sel.prevAll(':visible:not(:has(th)):first')
			}
		} else if (e.key == 'ArrowRight') {
			if (sel.hasClass('closed')) {
				openclose_dir(sel.attr('id'), true)
				e.preventDefault()
			} else {
				next = sel.nextAll(':visible:first')
			}
		}
		if (next && next.length) {
			select_node(next.attr('id'))
			scroll_into_view_if_needed(next[0])
			e.preventDefault()
		}
	})
}

// mark dirs which contain files that meet certain criteria
function mark_node(node, filter) {
	if (!node.files)  // not a dir
		node.marked = filter(node)
	else {
		node.marked = false
		for (var i = 0; i < node.files.length; i++)
			if (mark_node(node.files[i], filter))
				node.marked = true
	}
	return node.marked
}

var filtered
var old_tree

function render_package(pkg) {
	if (filtered)
		return
	old_tree = $('#tree').detach()
	function of_pkg(node) { return node.package && node.package == pkg; }
	mark_node(root, of_pkg)
	render_tree(function(node) { return node.marked; }, true)
	var filter_btn = $('#tree > tbody > tr:eq(1) > td:eq(1)')
		.addClass('filter_btn')
		.html(pkg)
		.append('<i class="fa fa-filter"></i>')
		.click(function() {
			exec('/tree')
			filtered = false
		})
	filtered = true
}

function exec(path) {
	window.history.pushState({}, '', path)
	$(window).trigger('hashchange')
}

$(function() {

	$(window).on('hashchange', function() {
		if (!root)
			return
		var match = window.location.pathname.match('tree/([^/]+)$')
		var pkg = match && match[1]
		if (pkg)
			render_package(pkg)
		else if (old_tree && old_tree.length)
			$('#tree_container').html(old_tree)
		else
			render_tree()
	})

	$.ajax('/tree.json', {
		success: function(root1) {
			root = root1
			$(window).trigger('hashchange')
		}
	})

})
</script>
