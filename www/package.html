<table width=100%>
	<tr>
		<td valign=top width=110 style="padding-right: 20px;" class="leftside nowrap">
			{{^info}}{{^download}}
			<div style="min-height: 2em">
			<div class="package_cat_name">This package</div>
			{{#docs}}
				{{#selected}}<span class=selected_doc>{{shortname}}</span>{{/selected}}
				{{^selected}}<a href="/{{name}}">{{shortname}}</a>{{/selected}}
				<br>
			{{/docs}}
			</div>
			<br>
			{{#cats}}
			<div class="package_cat_name">{{name}}</div>
			{{#packages}}
				{{#selected}}<span class=selected_doc>{{package}}</span>{{/selected}}
				{{^selected}}<a href="/{{package}}">{{package}}</a>{{/selected}}
				<sup>{{note}}</sup>
				<br>
			{{/packages}}
			{{/cats}}
			{{/download}}{{/info}}
		</td>
		<td valign=top>
			<div style="position: relative; width: 100%">
				<div class=action_links>
					<span style="float: left; width: 180px">&nbsp;</span>
					<a href="/{{package}}"
						class="nowrap {{^info}}{{^download}}selected_link{{/download}}{{/info}}">
							<i class="fa fa-file-text-o"></i> docs</a>
					<a href="/{{package}}/info" class="nowrap {{#info}}selected_link{{/info}}">
						<i class="fa fa-info-circle"></i> info</a>
					<a href="/tree/{{package}}" class="nowrap">
						<i class="fa fa-files-o"></i> files</a>
					<a href="/{{package}}/download" class="nowrap download_link {{#download}}selected_link{{/download}}"><i class="fa fa-download"></i> download</a>
				</div>
				<h1 class=tight>{{title}}</h1>
				<h4 class=tight>{{tagline}}</h4>
			</div>
			<br>

			<!-- download =================================================== -->
			{{#download}}
			<h2>Download</h2>
			<table>
				<tr>
					<td valign=top style="padding-right: 1em">
						<a class=download_btn href="{{github_url}}/archive/master.zip">
							<i class="fa fa-download"></i>
							<span>{{package}}-master.zip</span>&nbsp;&nbsp;&nbsp;
						</a>
						<br>
						<a class="small download_link" href="{{github_url}}/archive/master.tar.gz">
							<i class="fa fa-download"></i>
							<span>{{package}}-master.tar.gz</span>
						</a>
					</td>
					<td valign=top>
						{{#changes_url}}
							<a href="{{changes_url}}">Changes since {{git_tag}}...</a>
						{{/changes_url}}
					</td>
				</tr>
			</table>

			<h2>Clone with <a href="/luapower-git"><span>multigit</span></a></h2>
			<div>
				<div
					class="switch_group"
					switch_group_for=".clone_for"
					active_switch=".clone_for_all"
					persistent=1>
				{{#clone_lists}}
					<a switch_for=".clone_for_{{platform}}" class="{{disabled}}">{{#icon}}<i class="icon-{{icon}}"></i>{{/icon}}<i>{{text}}</i></a>&nbsp;
				{{/clone_lists}}
				</div>
			</div>
			<div class=doc>
				{{#clone_lists}}
				<pre class="clone_for clone_for_{{platform}} {{hidden}}"><code>{{#is_unix}}./{{/is_unix}}mgit clone{{#packages}} {{dep_package}}{{/packages}}
</code></pre>
				{{/clone_lists}}
			</div>

			<h2>
				Releases
				<a href="{{github_url}}/releases"
					class=hastip
					style="margin-left: 1em"
					title="View releases on github">
					<i class="fa fa-github"></i>
				</a>
			</h2>
			<table>
			{{#git_tags}}
				<tr>
					<td valign=top style="padding-right: 1em">
						<a href="{{github_url}}/releases/tag/{{tag}}">{{tag}}</a>
					</td>
					<td valign=top style="padding-right: 1em">
						<span class=time time="{{time}}" reltime="{{reltime}}">{{reltime}}</span>
					</td>
					<td valign=top style="padding-bottom: 1em">
						<a class="nowrap small download_link" href="{{github_url}}/archive/{{tag}}.zip">
							<i class="fa fa-download"></i>
							<span>{{package}}-{{tag}}.zip</span>
						</a>
						<br>
						<a class="nowrap small download_link" href="{{github_url}}/archive/{{tag}}.tar.gz">
							<i class="fa fa-download"></i>
							<span>{{package}}-{{tag}}.tar.gz</span>
						</a>
					</td valign=top>
					<td valign=top style="padding-left: 1em">
						<a href="{{changes_url}}">{{changes_text}}</a>
					</td>
				</tr>
			{{/git_tags}}
			</table>
			{{^git_tags}}
				No releases made yet.
			{{/git_tags}}

			<!--
			<h2>Install with <a href="http://luarocks.org/">LuaRocks</a></h2>
			<pre>
luarocks install --server=http://rocks.moonscript.org/m/luapower {{package}}
			</pre>
			-->
			<br>
			<br>
			{{/download}}

			<!-- info ======================================================= -->
			{{#info}}

			<h2>Overview</h2>
			<table class=doc>
				<tr><td>Package type:</td><td><a href="/get-involved">{{type}}</a></td></tr>
				<tr><td>Version:</td><td>{{version}}</td></tr>
				<tr><td>Last commit:</td><td><span class=time time="{{mtime}}" reltime="{{mtime_ago}}">{{mtime_ago}}</span></td></tr>
				<tr>
					<td>Releases:</td>
					<td>
						{{#has_git_tags}}
							{{#git_tags}}
								<a href="{{github_url}}/releases/tag/{{tag}}">{{tag}}</a>
							{{/git_tags}}
							<a href="{{github_url}}/releases"><i class="fa fa-github"></i></a>
						{{/has_git_tags}}
						{{^has_git_tags}}
							None yet.
						{{/has_git_tags}}
					</td>
				</tr>
				<tr>
					<td>Platforms:</td>
					<td>
						{{#platforms}}
							{{#icon}}<i class="icon-{{icon}}"></i>{{/icon}}
							{{name}}
						{{/platforms}}
					</td>
				</tr>
			</table>

			{{#has_load_errors}}
			<h2>
				Load Errors
				&nbsp;
				<a class=infotip>
					Errors encountered when loading the module. Modules with load errors<br>
					on a platform don't have their dependencies recorded on that platform,<br>
					which also screws up the combined dependency list.
				</a>
				&nbsp;
			</h2>
			<table>
				<tr>
					<th></th>
					<th align=left valign=top style="padding-right: 1em; padding-bottom: 1em">module</th>
					<th align=left valign=top>load errors</th>
				</tr>
				{{#modules}}{{#module_has_load_errors}}
				<tr>
					<td width=30></td>
					<td class="nowrap" valign=top style="padding-right: 1em">
						{{#source_url}}
							<a href="{{source_url}}">{{module}}</a>
						{{/source_url}}
						{{#source_urls}}
							<a href="{{source_url}}">{{module}} ({{platform}})</a>
						{{/source_urls}}
						{{^source_url}}
							{{^source_urls}}
							<span>{{module}}</span>
							{{/source_urls}}
						{{/source_url}}
					</td>
					<td valign=top>
						{{#load_errors}}
							{{#errors}}
								<span class=error_line>
									{{#icon}}<span class="icon-{{icon}}"></span>&nbsp;{{/icon}}
									{{.}}
								</span><br>
							{{/errors}}
						{{/load_errors}}
					</td>
				</tr>
				{{/module_has_load_errors}}{{/modules}}
			</table>
			{{/has_load_errors}}

			<h2>Dependencies
				&nbsp;
				<a class=infotip>
					This is a combined list of packages required by <b><i>all modules</i></b> of this<br>
					package on each supported platform, plus <b><i>binary dependencies</i></b> if any.<br>
					Darker names, if present, represent indirect dependencies.<br>
					<br>
					<b>Note:</b> These are only the dependencies required for the modules to <i>load</i>.<br>
					Runtime dependencies, if any, are shown separately below.<br>
					<br>
					<b>Tip:</b> You may not need all the dependencies listed here if you are not planning<br>
					 to use all the modules of the package -- look at per-module dependencies below.<br>
				</a>
				&nbsp;
				<span
					class="switch_group"
					switch_group_for=".combined_deps"
					active_switch=".combined_deps_list"
					persistent=1>
					<a switch_for=".combined_deps_list" class="hastip" title="show as list"><i class="fa fa-list"></i></a>
					<a switch_for=".combined_deps_table" class="hastip" title="show as table"><i class="fa fa-table"></i></a>
				</span>
			</h2>
			{{#has_package_deps}}
			<table class="dep_lists combined_deps combined_deps_list hidden">
				{{#package_deps}}
				<tr>
					<td class=col1 valign=top align=right>
						{{#icon}}<i class="icon-{{icon}}"></i>{{/icon}}
						<i>{{text}}</i>
					</td>
					<td class=col2 valign=top>
						{{#packages}}
						{{#icon}}<span class=gray>&#43;</span>{{/icon}}<a href="/{{dep_package}}/info" class="{{kind}}">{{dep_package}}</a>&nbsp;
						{{/packages}}
					</td>
				</tr>
				{{/package_deps}}
			</table>
			<div class="dep_matrix doc combined_deps combined_deps_table hidden">
				<table>
					<thead>
						<tr>
							<th></th>
							{{#depmat_names}}
							<th><a href="/{{.}}">{{.}}</a></th>
							{{/depmat_names}}
						</tr>
					</thead>
					<tbody>
						{{#depmat}}
						<tr>
							<td>
								{{#icon}}<i class="icon-{{icon}}"></i>{{/icon}}
								<i>{{text}}</i>
							</td>
							{{#pkg}}
							<td align=center>
								{{#.}}
									{{#checked}}<i class="fa fa-check {{kind}}"></i>{{/checked}}
								{{/.}}
							</td>
							{{/pkg}}
						</tr>
						{{/depmat}}
					</tbody>
				</table>
				</div>
			{{/has_package_deps}}
			{{^has_package_deps}}
				<span class=smallnote>No dependencies.</span>
			{{/has_package_deps}}

			{{#has_modules}}
			<h2>Modules
				&nbsp;
				<span class="module_deps module_deps_packages hidden">
					<a class="infotip">
						This is the list of modules for this package.<br>
						On the right column you have the required packages for each module.<br>
						Darker names, if present, represent indirect dependencies.
					</a>
				</span>
				<span class="module_deps module_deps_modules hidden">
					<a class="infotip">
						This is the list of modules for this package.<br>
						On the right column you have the required modules for each module.<br>
						Darker names, if present, represent indirect dependencies.<br>
						Even darker names are internal dependencies.<br>
					</a>
				</span>
				&nbsp;
				<span
					class="switch_group"
					switch_group_for=".module_deps"
					active_switch=".module_deps_packages"
					persistent=1>
					<a switch_for=".module_deps_packages" class="hastip" title="show required packages">P</a>
					<a switch_for=".module_deps_modules" class="hastip" title="show required modules">M</a>
				</span>
			</h2>
			<table>
				<tr>
					<th></th>
					<th align=left valign=top style="padding-bottom: 1em">module &nbsp;</th>
					<th align=left valign=top style="padding-right: 1em">language</th>
					<th align=left valign=top>
						<span class="module_deps module_deps_packages hidden">required packages</span>
						<span class="module_deps module_deps_modules hidden">required modules</span>
					</th>
				</tr>
				{{#modules}}
				<tr>
					<td valign=top align=center width=30>
						{{#icons}}
							<i class="icon-{{name}} {{disabled}}" title="{{title}}"></i>
						{{/icons}}
					</td>
					<td class="nowrap" valign=top style="padding-right: 1em">
						{{#source_url}}
							<a href="{{source_url}}">{{module}}</a>
						{{/source_url}}
						{{#source_urls}}
							<a href="{{source_url}}">{{module}} ({{platform}})</a>
							<br>
						{{/source_urls}}
						{{^source_url}}
							{{^source_urls}}
							<span>{{module}}</span>
							{{/source_urls}}
						{{/source_url}}
					</td>
					<td valign=top>
						{{lang}}
					</td>
					<td valign=top>
						{{#module_has_load_errors}}
							<i class="disabled">(has errors)</i>
						{{/module_has_load_errors}}
						{{^module_has_load_errors}}
						<div class="module_deps module_deps_packages">
						{{#package_deps}}
							{{#icon}}<span class="icon-{{icon}}"></span>&nbsp;{{/icon}}
							{{#packages}}
								<a href="/{{dep_package}}/info" class="{{kind}}">{{dep_package}}</a>&nbsp;
							{{/packages}}
						{{/package_deps}}
						</div>
						<div class="module_deps module_deps_modules hidden">
						{{#module_deps}}
							{{#icon}}<span class="icon-{{icon}}"></span>&nbsp;{{/icon}}
							{{#modules}}
								{{#dep_source_url}}
									<a href="{{dep_source_url}}" class="{{kind}}">{{dep_module}}</a>&nbsp;
								{{/dep_source_url}}
								{{^dep_source_url}}
									<span class="{{kind}}">{{dep_module}}</span>&nbsp;
								{{/dep_source_url}}
							{{/modules}}
						{{/module_deps}}
						{{/module_has_load_errors}}
					</td>
				</tr>
				{{/modules}}
			</table>
			{{/has_modules}}

			{{#has_bin_deps}}
			<h2>
				Binary Dependencies
				&nbsp;
				<a class=infotip>
					Binary dependencies are the libraries that this library is<br>
					<b><i>dynamically linked</i></b> against.<br>
					Darker names represent indirect dependencies.
				</a>
			</h2>
			<table class="dep_lists bin_lists">
				{{#bin_deps}}
				<tr>
					<td class=col1 valign=top align=right>
						{{#icon}}<i class="icon-{{icon}}"></i>{{/icon}}
						<i>{{text}}</i>
					</td>
					<td class=col2 valign=top>
						{{#packages}}
						{{#icon}}<span class=gray>&#43;</span>{{/icon}}<a href="/{{dep_package}}/info" class="{{kind}}">{{dep_package}}</a>&nbsp;
						{{/packages}}
					</td>
				</tr>
				{{/bin_deps}}
			</table>

			<h2>
				Build Order
				&nbsp;
				<a class=infotip>
					This is the complete list of packages that need to be compiled<br>
					<b><i>in the prescribed order</i></b> in order to build this package.<br>
				</a>
			</h2>

			<table class=dep_lists>
				{{#build_order}}
				<tr>
					<td class=col1>
						{{#icon}}<i class="icon-{{icon}}"></i>{{/icon}}
						<i>{{text}}</i>
					</td>
					<td class=col2>
						{{#packages}}<a href="/{{.}}">{{.}}</a>&nbsp; {{/packages}}
					</td>
				</tr>
				{{/build_order}}
			</table>

			{{/has_bin_deps}}

			{{#has_autoloads}}
			<h2>Runtime Dependencies - Autoloads
				&nbsp;
				<div class=infotip>
					Some modules implement parts of their API in separate sub-modules.<br>
					These <i>implementation</i> modules are loaded automatically at runtime<br>
					only if and when accessing those APIs. See <a href="/glue#autoload">glue.autoload</a> for how this works.
				</div>
			</h2>
			{{#modules}}{{#module_has_autoloads}}
			<table>
				<tr>
					<th></th>
					<th align=left valign=top style="padding-bottom: 1em">module.field</th>
					<th align=left valign=top>implementation module</th>
				</tr>
				{{#autoloads}}
				<tr>
					<td valign=top align=center width=30>
						<i class="icon-{{icon}}"></i>
					</td>
					<td style="padding-right: 1em">
						<a href="{{github_url}}/blob/master/{{path}}?ts=3">{{module}}.{{key}}</a>
					</td>
					<td>
						<a href="{{github_url}}/blob/master/{{impl_path}}?ts=3">{{impl_module}}</a>
					</td>
				</tr>
				{{/autoloads}}
			</table>
			{{/module_has_autoloads}}{{/modules}}
			{{/has_autoloads}}

			{{#has_runtime_deps}}
			<h2>Runtime Dependencies - Parsed
				&nbsp;
				<a class=infotip>
					These are additional modules that are required at runtime<br>
					in specific circumstances. Check the module's documentation<br>
					or source code to find out what these circumstances are.
				</a>
				&nbsp;
				<span
					class="switch_group"
					switch_group_for=".runtime_deps"
					active_switch=".runtime_deps_packages"
					persistent=1>
					<a switch_for=".runtime_deps_packages" class="hastip" title="show required packages">P</a>
					<a switch_for=".runtime_deps_modules" class="hastip" title="show required modules">M</a>
				</span>
			</h2>
			<table>
				<tr>
					<th></th>
					<th align=left valign=top style="padding-right: 1em; padding-bottom: 1em">module</th>
					<th align=left valign=top>
						<span class="runtime_deps runtime_deps_packages hidden">required packages</span>
						<span class="runtime_deps runtime_deps_modules hidden">required modules</span>
					</th>
				</tr>
				{{#modules}}{{#module_has_runtime_deps}}
				<tr>
					<td width=30></td>
					<td class="nowrap" valign=top style="padding-right: 1em">
						{{#source_url}}
							<a href="{{source_url}}">{{module}}</a>
						{{/source_url}}
						{{^source_url}}
							<span>{{module}}</span>
						{{/source_url}}
					</td>
					<td valign=top>
						<div class="runtime_deps runtime_deps_packages hidden">
						{{#runtime_package_deps}}
							{{#icon}}<span class="icon-{{icon}}"></span>&nbsp;{{/icon}}
							{{#packages}}
								<a href="/{{dep_package}}/info" class="{{kind}}">{{dep_package}}</a>&nbsp;
							{{/packages}}
						{{/runtime_package_deps}}
						</div>
						<div class="runtime_deps runtime_deps_modules hidden">
						{{#runtime_module_deps}}
							{{#icon}}<span class="icon-{{icon}}"></span>&nbsp;{{/icon}}
							{{#modules}}
								{{#dep_source_url}}
									<a href="{{dep_source_url}}" class="{{kind}}">{{dep_module}}</a>&nbsp;
								{{/dep_source_url}}
								{{^dep_source_url}}
									<span class="{{kind}}">{{dep_module}}</span>&nbsp;
								{{/dep_source_url}}
							{{/modules}}
						{{/runtime_module_deps}}
					</td>
				</tr>
				{{/module_has_runtime_deps}}{{/modules}}
			</table>
			{{/has_runtime_deps}}

			{{#has_scripts}}
			<h2>Scripts
				&nbsp;
				<a class=infotip>
					This is the list of scripts (tests, demos, etc.).<br>
					Unlike normal modules, scripts are not run to track dependencies.<br>
					Instead, they are just <i>parsed</i> for <code>require()</code> calls.<br>
					This means that indirect dependencies are never shown.
				</a>
				&nbsp;
				<span
					class="switch_group"
					switch_group_for=".script_deps"
					active_switch=".script_deps_packages"
					persistent=1>
					<a switch_for=".script_deps_packages" class="hastip" title="show required packages">P</a>
					<a switch_for=".script_deps_modules" class="hastip" title="show required modules">M</a>
				</span>
			</h2>
			<table>
				<tr>
					<th></th>
					<th align=left valign=top style="padding-right: 1em; padding-bottom: 1em">script &nbsp;</th>
					<th align=left valign=top>
						<span class="script_deps script_deps_packages hidden">required packages</span>
						<span class="script_deps script_deps_modules hidden">required modules</span>
					</th>
				</tr>
				{{#scripts}}
				<tr>
					<td valign=top align=center width=30>
					</td>
					<td class="nowrap" valign=top style="padding-right: 1em">
						{{#source_url}}
							<a href="{{source_url}}">{{module}}</a>
						{{/source_url}}
						{{^source_url}}
							<span>{{module}}</span>
						{{/source_url}}
					</td>
					<td valign=top>
						<div class="script_deps script_deps_packages">
						{{#package_deps}}
							<a href="/{{.}}/info">{{.}}</a>&nbsp;
						{{/package_deps}}
						</div>
						<div class="script_deps script_deps_modules hidden">
						{{#module_deps}}
							{{#dep_source_url}}
								<a href="{{dep_source_url}}">{{dep_module}}</a>&nbsp;
							{{/dep_source_url}}
							{{^dep_source_url}}
								<span>{{dep_module}}</span>&nbsp;
							{{/dep_source_url}}
						{{/module_deps}}
					</td>
				</tr>
				{{/scripts}}
			</table>
			{{/has_scripts}}

			{{#has_docs}}
			<h2>Docs</h2>
			<table>
				<tr>
					<th></th>
					<th align=left valign=top style="padding-right: 1em; padding-bottom: 1em">name</th>
					<th align=left valign=top>source file</th>
					<th></th>
				</tr>
				{{#docs}}
				<tr>
					<td width=30></td>
					<td valign=top style="padding-right: 1em"><a href="/{{name}}">{{name}}</a></td>
					<td valign=top><a href="{{source_url}}">{{path}}</a></td>
				</tr>
				{{/docs}}
			</table>
			{{/has_docs}}

			{{/info}}

			<!-- documentation ============================================== -->
			{{^info}}{{^download}}
			<div id=doc class=doc>
				{{{doc_html}}}
				{{^doc_html}}
				<span class="small gray">No documentation found.</span>
				{{/doc_html}}
				<br>
				<p class="small gray" style="float: right">
					{{#doc_mtime_ago}}
						Last updated:
						<b class="time"
							time="{{doc_mtime}}"
							reltime="{{doc_mtime_ago}}">{{doc_mtime_ago}}</b>
					{{/doc_mtime_ago}}
					{{#edit_link}}
						{{#doc_mtime_ago}} | {{/doc_mtime_ago}}
						<a href="{{edit_link}}">Edit on GitHub</a>
					{{/edit_link}}
				</p>
				<!--enddoc is needed for spyscroll docnav-->
				<enddoc></enddoc>
			</div>
			{{/download}}{{/info}}

		</td>
		<td valign=top align=right class="rightside nowrap">
			<h1 class=tight style="margin-bottom: 30px">
				{{#icons}}
					<span class="icon-{{name}} {{disabled}}" title="{{title}}"></span>
				{{/icons}}
			</h1>
			<table width=100% class=infobar>
				<tr>
					<td align=left class="gray">Package:</td><td align=left><a href="/{{package}}">{{package}}</a></td>
				</tr>
				<tr>
					<td align=left class="gray">Pkg type:</td><td align=left><a href="/get-involved">{{type}}</a></td>
				</tr>
				<tr>
					<td align=left class="gray">Version: </td><td align=left>
						<a href="{{github_url}}/commits/master">{{version}}</a>
					</td>
				</tr>
				<tr>
					<td align=left class="gray">Last commit: </td><td align=left>
						<span class=time time="{{mtime}}" reltime="{{mtime_ago}}"></span>
					</td>
				</tr>
				{{#author}}
				<tr>
					<td align=left class="gray">Author: </td><td align=left>{{author}}</td>
				</tr>
				{{/author}}
				<tr>
					<td align=left class="gray">License: </td><td align=left>{{license}}</td>
				</tr>
				{{#c_name}}
				<tr>
					<td align=left class="gray">Import: </td><td align=left>{{c_name}}</td>
				</tr>
				{{/c_name}}
				{{#c_version}}
				<tr>
					<td align=left class="gray">Import ver: </td><td align=left><a href="{{c_url}}">{{c_version}}</a></td>
				</tr>
				{{/c_version}}
				<tr>
					<td align=left valign=top colspan=2>
						<span class="gray requires_label">Requires:</span>
						<span style="white-space: normal" class=deps_sidebar>
						{{#package_deps}}
							{{#icon}}<span class="gray platform_icon icon-{{icon}}"></span>{{/icon}}
							{{#packages}}
								{{#icon}}<span class=gray>&#43;</span>{{/icon}}<a href="/{{dep_package}}" class="{{kind}}">{{dep_package}}</a>&nbsp;
							{{/packages}}
						{{/package_deps}}
						{{^package_deps}}
						<span class=smallnote>none</span>
						{{/package_deps}}
					</td>
				</tr>
				<tr>
					<td align=left valign=top colspan=2>
						<span class="gray requires_label">Required by: </span>
						<span style="white-space: normal" class=deps_sidebar>
						{{#package_rdeps}}
							{{#icon}}<span class="gray platform_icon icon-{{icon}}"></span>{{/icon}}
							{{#packages}}
								<span></span><a href="/{{dep_package}}" class="{{kind}}">{{dep_package}}</a>&nbsp;
							{{/packages}}
						{{/package_rdeps}}
						</span>
						{{^package_rdeps}}
						<span class=smallnote>none</span>
						{{/package_rdeps}}
					</td>
					<script>
						// prevent icons from showing up alone at the end of the line.
						$('.deps_sidebar .platform_icon').each(function() {
							$(this)
								.css({'display': 'inline', 'margin-right': '4px'})
								.add($(this).next())        // +
								.add($(this).next().next()) // first text
								.wrapAll('<span class=nowrap></span>')
						})
					</script>
				</tr>
			</table>
			<br>
			<div id=docnav></div>
		</td>
	</tr>
</table>
