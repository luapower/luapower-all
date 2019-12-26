<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>
		{{#title}}{{title}} - luapower.com{{/title}}
		{{^title}}luapower - The LuaJIT distribution for Windows, Linux and OS X{{/title}}
	</title>
	<link rel="shortcut icon" href="/favicon.ico?v4">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">

	<link href='https://fonts.googleapis.com/css?family=Open+Sans:300,400,600' rel='stylesheet' type='text/css'>
	<link href='https://fonts.googleapis.com/css?family=Inconsolata' rel='stylesheet' type='text/css'>
	<link rel="stylesheet" type="text/css" href="/font-awesome.css">

	<script src="/jquery.js"></script>
	<script src="/jquery.easing.js"></script>
	<script src="/jquery.cookie.js"></script>
	<script src="/jquery.scrollintoview.js"></script>
	<script src="/jquery.tablesorter.js"></script>
	<script src="/jquery.scrollspy.js"></script>
	<script src="/jquery.tooltipsy.js"></script>

	<link rel="stylesheet" type="text/css" href="/jquery.featherlight.css">
	<script src="/jquery.featherlight.js"></script>

	<link rel="stylesheet" type="text/css" href="/jquery.featherlight.gallery.css">
	<script src="/jquery.featherlight.gallery.js"></script>

	<script src="/main.js"></script>
	<link rel="stylesheet" type="text/css" href="/main.css">

	<link rel="stylesheet" type="text/css" id="lights_css">
	<script>
		// set the lights before rendering starts
		set_lights()
	</script>
</head>
<body>

<div class=body_wrapper>

<table width=100%>
	<tr>
		<td align=center valign=top class=topbar>
			<table class="topbar_content screen_width">
				<tr>
					<td align=left valign=middle width=130>
						<span class="topbar_logo tight">
							<a href="/">luapower.com</a>
						</span>
					</td>
					<td align=left valign=middle width=80>
						<a class=lights_btn>
							<span class=lights_label>lights</span><i class="lights_icon fa"></i></a>
					</td>
					<td width=50 align=center valign=middle class=faq_btn>
						<a href="/faq">FAQ</a>
					</td>
					<td width=50 align=center valign=middle>
						<a href="/forum/" class="external_link" target="_blank">Forum</a>
					</td>
					<td align=right valign=middle>
						{{#github_url}}
							<a class=github_label href="{{github_url}}">{{github_title}}<i class="github_icon fa fa-github"></i></a>
						{{/github_url}}
					</td>
					{{#grep_enabled}}
					<td align=left valign=middle width=190 class=rightside>
						<input class=search_input type=text value="{{{search}}}" placeholder="grep in sources">
						<div class="fa fa-search search_icon"></div>
					</td>
					{{/grep_enabled}}
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td align=center valign=top class=main>
			<table class=screen_width>
				<tr>
					<td align=left valign=top>
						<div>
{{! NOTE: we don't indent the partial because we have <code> sections inside }}
{{>content}}
						</div>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>

<div class=footer style="background: url('/bg-dark-concrete.jpg')">
	<table class="screen_width" style="margin: auto">
		<tr class="footer_heading">
			<td>UNDERSTANDING</td>
			<td>USING</td>
			<td>DEVELOPING</td>
			<td>COMMUNITY</td>
		</tr>
		<tr>
			<td valign=top align=left width=300 class=nowrap>
				<a href="/faq" class=faq_btn>FAQ</a><br>
				<a href="/philosophy">Philosophy</a><br>
			</td>
			<td valign=top align=left width=300 class=nowrap>
				<a href="/luapower-git">Luapower with Git</a><br>
				<a href="/building">Building Binaries</a><br>
				<a href="/bundle">Making Single-Exe Apps</a><br>
			</td>
			<td valign=top align=left class=nowrap>
				<a href="/get-involved">Getting Involved</a><br>
				<a href="/build-scripts">Writing Build Scripts</a><br>
				<a href="/coding-style">Coding Style Guide</a><br>
				<a href="/api-design">API Design Guide</a><br>
				<a href="/luajit-notes">LuaJIT Dev Notes</a><br>
				<a href="/lua-tricks">Lua Tricks</a><br>
			</td>
			<td valign=top align=left class=nowrap>
				<a href="/forum/" class="external_link" target="_blank">Forum</a><br>
			</td>
		</tr>
		<tr>
			<td colspan=4>
				<br>
				<hr style="border-top-color: #333">
			</td>
		</tr>
		<tr>
			<td align=left valign=top>
				<img src="/luapower2.png" class=footer_footer>
			</td>
			<td colspan=3 valign=top class="small gray footer_footer">
				Made with
					<a href="http://lua.org/about.html">sugar</a>,
					<a href="http://luajit.org/luajit.html">spice</a> and
					<a href="http://openresty.org/">everything nice</a> by
					<a href="/cosmin">Cosmin Apreutesei</a>.
				<br>
				Published as <a href="http://unlicense.org/">Public Domain</a>.
				Hosted on <a href="http://github.com/luapower/website">github</a>.
			</td>
		</tr>
	</table>
</div>

<a class=top>Top</a>

</div>

<div class=force_repaint></div>

<script>
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-10841867-16', 'auto');
ga('send', 'pageview');
</script>

</body>
</html>
