<h1>luapower VMs</h1>
<style>
.vm td, .vm th { white-space: nowrap; padding-right: 20px; }
</style>
<table class=vm>
	<tr>
		<th align=left>platform</th>
		<th align=left>OS</th>
		<th align=left>Arch</th>
		<th align=left>host</th>
		<th align=left>port</th>
		<th align=left>status</th>
		<th align=left>packages</th>
		<th align=left nowrap>load errors</th>
		<th align=left></th>
	</tr>
	{{#statuses}}
	<tr>
		<td>{{platform}}</td>
		<td>{{os}}</td>
		<td>{{arch}}</td>
		<td>{{ip}}</td>
		<td>{{port}}</td>
		<td>{{status}}</td>
		<td width=1>{{installed_package_count}} / {{known_package_count}}</td>
		<td width=1>{{load_error_count}}</td>
		<td>{{error}}</td>
	</tr>
	{{/statuses}}
</table>

<h2>Module load errors</h2>
{{#statuses}}
	<h3>{{platform}}</h3>
	<table width=100%>
		{{#load_errors}}
		<tr>
			<td valign=top><a href="/{{module}}">{{module}}</a></td>
			<td style="padding-left: 1em">{{error}}</td>
		</tr>
		{{/load_errors}}
	</table>
{{/statuses}}
