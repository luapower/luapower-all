<div class=grep>
<table width=100%>
	<tr>
		<td valign=top width=160>
			<table width=100% class=small>
			{{#results}}
				<tr>
					<td><a class=goto>{{file}}</a></td>
					<td align=right class=gray>{{matchcount}}{{#limited}}&#43;{{/limited}}</td>
				</tr>
			{{/results}}
			</table>
		</td>

		<td valign=top style="padding-left: 20px">
			<table width=100%>
				<tr>
					<td>{{message}}</td>
					<td align=right>
						{{#searched}}
						<span class=gray>Lua modules searched: </span>{{modules_searched}},
						<span class=gray>Docs searched: </span>{{docs_searched}},
						<span class=gray>Matching files: </span>{{file_matchcount}}
						<span class=gray>Matches: </span>{{matchcount}}{{#matchcount_limited}}&#43;{{/matchcount_limited}}
						{{/searched}}
					</td>
				</tr>
			</table>
		{{#results}}
			<div class=result file="{{file}}">
			<table width=100%>
				<tr>
					<td><h3><a href="https://github.com/luapower/{{package}}/blob/master/{{file}}?ts=3">{{file}}</a></h3></td>
					<td align=right valign=bottom>{{matchcount}}{{#limited}}&#43;{{/limited}} matches</td>
				</tr>
				<tr>
					<td colspan=2>
						<div class=more>
						{{#chunks}}
<pre>
{{#text}}<span class=line>{{line}}</span>{{#fragments}}{{#hl}}<span class=hl>{{hl}}</span>{{/hl}}{{s}}{{/fragments}}<br>{{/text}}</pre>
						{{/chunks}}
						</div>
					</td>
				</tr>
				<tr>
					<td colspan=2 align=right valign=top>
						<a class=expand>expand...</a>
					</td>
				</tr>
			</table>
			</div>
		{{/results}}
		</div>
		</td>
	</tr>
</table>
</div>

<script>
$(function() {

	$('.grep .expand').each(function() {
		var a = $(this)
		var resdiv = a.closest('.result')
		var morediv = resdiv.find('.more')
		var h1 = morediv.css('max-height')
		function collapse(e) {
			e.preventDefault()
			a.off('click')
			morediv.animate({'max-height': h1}, 200, 'easeOutQuint', function() {
				$('.result').removeClass('active')
				resdiv.scrollintoview().addClass('active')
				a.html('expand...')
				a.click(expand)
			})
		}
		function expand(e) {
			e.preventDefault()
			var h = morediv[0].scrollHeight + 10
			a.off('click')
			morediv.animate({'max-height': h+'px'}, 200, 'easeOutQuint', function() {
				$('.result').removeClass('active')
				resdiv.scrollintoview().addClass('active')
				a.html('collapse...')
				a.click(collapse)
			})
		}
		a.click(expand)
	})

	$('.grep .goto').click(function(e) {
		e.preventDefault()
		var file = $(this).html()
		var h = $('.grep .result[file="'+file+'"] a').click()
	})

})
</script>
