<center>
	<a href="/faq"><img class="home_logo" title="FAQ" src="/luapower.png" alt="LUA POWER"></a>
	<h1 class=home_tagline>the LuaJIT distribution for Windows, Linux and OS X</h1>
</center>

<table class=quick_faq>
	<tr>
		<td>
			<h3>What is luapower?</h3>

			Luapower is a binary+source module distribution for LuaJIT and a way of
			deploying and sharing Lua modules. <a href="/faq">Learn more...</a>

			<h3>How do I get started?</h3>

			<p>
				<b>Option 1.</b> Like a Pro, using <a href="/luapower-git">multigit</a>:
				<div class="shell_btn"></div>
				<div class=doc style="padding-right: 0;">
				<pre class="windows_shell"><code>git clone https://github.com/capr/multigit luapower
cd luapower
mgit clone https://github.com/luapower/luapower-repos
mgit clone-all
</code></pre>

				<pre class="unix_shell"><code>git clone https://github.com/capr/multigit luapower
cd luapower
./mgit clone https://github.com/luapower/luapower-repos
./mgit clone-all
</code></pre>
				</div>
			</p>

			<p>
				<!--
				Option 2. Daily bundles:
				<p class=downloads_home>
					{{#download_buttons}}
						<a class=download_btn href="/{{file}}">
							<i class="icon-{{platform}}"></i>
							<span>{{name}} <span class="small" style="padding-left: 0.5em;">{{size}}</span></span>
						</a>
					{{/download_buttons}}
				</p>
				-->

				<b>Option 2.</b> All-in-one:
				<p class=downloads_home>
					<a class=download_btn href="https://github.com/luapower/all/archive/master.zip">
						<i class="icon-mingw"></i>
						<i class="icon-osx"></i>
						<i class="icon-linux"></i>
						<span>DOWNLOAD <span class="small" style="padding-left: 0.5em;">{{{all_download_size}}}</span></span>
					</a>
					<br>
					<a class="small" href="https://github.com/luapower/luapower-all/releases">older versions...</a>
				</p>
			</p>

			<p>
				<b>Option 3.</b> Swedish buffet: Get only <a href="/luajit">luajit</a> and the modules
				you need from the <b>table below</b>, and unzip their contents <i>over the same directory</i>
				to get a portable, self-contained luapower installation.
			</p>

			<b style="color:yellow;">NEW!</b> <a href="/tree">Browse the whole annotated source tree online!</a>

		</td>
		<td class="quick_faq2">
			<h3>What is Lua?</h3>
			<a href="http://lua.org/about.html">Lua</a>
			is a powerful, fast and lightweight scripting language.
			It has been used in
			<a href="https://sites.google.com/site/marbux/home/where-lua-is-used">many popular applications</a>
			since its inception
			<a href="http://www.lua.org/doc/hopl.pdf">in 1993</a>.

			<h3>Why is it special?</h3>
			Lua has a <a href="http://www.lua.org/pil/1.html">clean syntax</a>,
			only
			<a href="http://www.lua.org/pil/2.html">8 basic types</a>
			(with LuaJIT adding a ninth),
			<a href="http://www.lua.org/pil/2.6.html">first class functions</a>
			with
			<a href="http://www.lua.org/pil/5.1.html">multiple return values</a> and
			<a href="http://www.lua.org/pil/5.2.html">varargs</a>,
			<a href="http://www.lua.org/pil/11.html">a versatile data structuring type</a>,
			<a href="http://www.lua.org/pil/6.1.html">lexical scoping</a>,
			<a href="http://www.lua.org/pil/9.html">light threads</a>,
			<a href="http://www.lua.org/pil/4.3.5.html">iterators</a>,
			<a href="http://www.lua.org/pil/16.html">inheritance</a>,
			<a href="http://www.lua.org/pil/8.4.html">exceptions</a>,
			<a href="http://www.lua.org/pil/14.3.html">function environments</a>,
			<a href="http://www.lua.org/pil/20.1.html">built-in pattern matching</a>,
			<a href="http://www.lua.org/pil/6.3.html">tail calls</a>, and a
			<a href="http://www.lua.org/pil/8.1.html">one-function module system</a>.

			<br>
			<br>
			Lua has a small and concise
			<a href="http://www.lua.org/manual/5.1/manual.html">manual</a>,
			an extensive
			<a href="http://www.luafaq.org/">FAQ</a>
			and an active and friendly
			<a href="http://www.lua.org/lua-l.html">mailing list</a>,
			making it easy to learn and get help along the way.

			<h3>What is LuaJIT?</h3>
			<a href="http://luajit.org/luajit.html">LuaJIT</a> is a
			<a href="http://en.wikipedia.org/wiki/Tracing_just-in-time_compilation">tracing</a>
			<a href="http://en.wikipedia.org/wiki/Just-in-time_compilation">just-in-time compiler</a> (JIT) for Lua,
			and it's one of the fastest compilers for a dynamic language around.
			<br>
			<br>
			LuaJIT is fully compatible with Lua
			<a href="http://www.lua.org/versions.html">5.1</a>,
			and includes many
			<a href="http://luajit.org/extensions.html#lua52">features from Lua 5.2</a>
			as well as some
			<a href="http://luajit.org/extensions.html#library">portability enhancements</a>
			of the standard library.
			<br>
			<br>
			LuaJIT extends Lua with a powerful
			<a href="http://luajit.org/ext_ffi.html">ffi interface</a>
			that allows calling C functions directly, without the need to write
			glue code.

		</td>
	</tr>
</table>

<br>
<h3 class=switch_group
	switch_group_for=".package"
	active_switch=".package_list"
	persistent=1>
	Packages
	&nbsp;
	<a class="hastip" switch_for=".package_list" title="view condensed package list"><i class="fa fa-align-justify"></i></a>
	<a class="hastip" switch_for=".package_table" title="view full package table"><i class="fa fa-table"></i></a>
	<a class="hastip" switch_for=".package_cards" title="view info cards"><i class="fa fa-th"></i></a>
</h3>

<div class="package package_list hidden">
	<ul class=multicol_name>
		{{#cats}}
			<li class=package_cat>
				<h4 class="package_cat_name tight">{{cat}}</h4>
				<ul>
					{{#packages}}
					<li>
						<a href="/{{name}}" title="{{tagline}}">{{name}}</a>
						<sup>{{note}}</sup>
						{{#hot}} <i class="fa fa-star hot" title="updated in the last 7 days"></i>{{/hot}}
					</li>
					{{/packages}}
				</ul>
			</li>
		{{/cats}}
	</ul>
	<i class="fa fa-star hot"></i> <span class=smallnote>updated in the last 7 days</span>
</div>

<table width=100% class="package package_table doc hidden">
	<thead>
		<tr>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>Type</th>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>Package</th>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>What</th>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>Version</th>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>Updated</th>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>Platforms</th>
			<th align=left title="Hold Shift to sort by multiple columns" class=hastip>License</th>
		</tr>
	</thead>
	<tbody>
		{{#packages}}
		<tr>
			<td nowrap>{{type}}</td>
			<td nowrap><a href="/{{name}}">{{name}}</a></td>
			<td>{{tagline}}</td>
			<td nowrap>{{version}}</td>
			<td nowrap>
				<span class=hidden>{{mtimestamp}}</span> <!--always sort by timestamp-->
				<span class=time time="{{mtime}}" reltime="{{mtime_ago}}"></span></td>
			<td class=nowrap>
				<span class=hidden>{{platform_string}}</span>
				{{#icons}}<span class="icon icon-{{name}} {{disabled}} {{invisible}}"></span>{{/icons}}
			</td>
			<td nowrap>{{license_short}}</td>
		</tr>
		{{/packages}}
	</tbody>
</table>

<table width=100% class="package package_cards hidden">
	{{#cats}}
	<tr>
		<td>
			<h3 class="package_cat_name">{{cat}}</h3>
			{{#packages}}
			<div class=package_card>
				<table width=100% height=100%>
					<tr>
						<td valign=top>
							<h3 class="tight">
								<a href="/{{name}}">{{name}}</a>
								{{#hot}} <i class="fa fa-star hot" title="updated in the last 7 days"></i>{{/hot}}
							</h3>
							{{tagline}}
						</td>
					</tr>
					<tr>
						<td valign=bottom class="small gray">
							Version: {{version}}<br>
							Updated: <span class=time time="{{mtime}}" reltime="{{mtime_ago}}"></span><br>
							Type: {{type}} &nbsp;
							{{#icons}}
								<span class="icon icon-{{name}} {{disabled}} {{invisible}}"></span>
							{{/icons}}
							<br>
							License: {{license}}
						</td>
					</tr>
				</table>
			</div>
			{{/packages}}
		</td>
	</tr>
	{{/cats}}
</table>

<div class=news_table></div>

<script src="/github.js"></script>

<script>

$(function() {

	$('.package_table').tablesorter({
		cancelSelection: true,
		sortList: JSON.parse(getcookie('pt_sortlist', '[[1,0]]')), //initially sort by name
	}).bind("sortEnd", function(sorter) {
		var sl = sorter.target.config.sortList
		setcookie('pt_sortlist', JSON.stringify(sl))
	})

	load_github_events({
		{{#packages}}
		"{{name}}": { link: ["{{name}}", "/{{name}}"], },
		{{/packages}}
	})

})

</script>
