<table width=100% style="font-size: 90%; line-height: 150%">
	<tr>
		<td valign=top>
			<table style="border-collapse: separate;">
			{{#cats}}
				{{#files}}{{#list}}
				{{#first}}
				<tr><td colspan=4><br></td></tr>
				{{/first}}
				<tr>
					{{#first}}
					<td valign=top rowspan={{n}}>
						<h4 class=tight style="padding-right: 1em">{{catname}}</h4>
					</td>
					{{/first}}
					<td style="padding-right: 1em"><a id="file_{{header_id}}">{{header_name}}</a></td>
					<td style="padding-right: 1em"><a id="file_{{impl_id}}">{{impl_name}}</a></td>
					<td>{{tagline}}</td>
				</tr>
				{{/list}}{{/files}}
			{{/cats}}
			</table>
		</td>
		<td valign=top width=30%>
			{{#cats}}
				{{#files}}
					<div class="symbols" style="display: none" id="syms_file_{{id}}">
						<h1 class=tight>{{name}}</h1>
						<br>
						<table>
						{{#ifdefs}}
							<tr>
								<td>{{.}}</td>
							</tr>
						{{/ifdefs}}
						</table>
						<br>
						<table>
						{{#defs}}
							<tr>
								<td align=right width=40 style="padding-right: 1em">{{line}}</td>
								<td><a href="https://github.com/capr/luajit/blob/v2.1/src/{{name}}#L{{line}}">{{text}}</a></td>
							</tr>
						{{/defs}}
						</table>
					</div>
				{{/files}}
			{{/cats}}
		</td>
	</tr>
</table>

<script>
$(function() {
	$('a[id^="file_"]').click(function() {
		$('div[id^="syms_file_"]').hide()
		console.log('#syms_'+$(this).attr('id'), $('#syms_'+$(this).attr('id')).length)
		$('#syms_'+$(this).attr('id')).show()
	})
})
</script>