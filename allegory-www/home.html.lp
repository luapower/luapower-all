<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="initial-scale=1">
<title>ALLEGORY</title>
<meta charset="utf-8">
<link rel="stylesheet" type="text/css" href="x-widgets.css">
<link rel="stylesheet" type="text/css" href="fontawesome.css">
<script src="glue.js"></script>
<script src="divs.js"></script>
<script src="x-widgets.js"></script>
<style>

* { box-sizing: border-box; }

@font-face {
	font-family: "opensans-light";
	src: url("OpenSans-Light.ttf");
}

@font-face {
	font-family: "opensans";
	src: url("OpenSans-Regular.ttf");
}

h1, h2, h3 {
	font-family: opensans-light, arial, sans-serif;
	font-weight: normal;
}

h2 { font-size: 22px; }

:focus {
	outline: none;
}

a {
	text-decoration: none;
	color: #000;
}

html, body {
	width: 100%;
	margin: 0;
	padding: 0;
}

body, .x-widget {
	font-family: opensans, arial, sans-serif;
	font-size: 15px;
	line-height: 2;
}

body {
	padding: 2em 2em .5em 2em;
	overflow-y: scroll;
	display: flex;
	flex-flow: column;
	justify-content: top;
	align-items: center;
}

.big-logo {
	max-width: 100%;
	height: auto;
}

#topmenu {
	width: 600px;
	align-self: center;
}

#topmenu > .x-pagelist-header {
	font-family: opensans-light, arial, sans-serif;
	margin-top: 1em;
	justify-content: space-between;
	background: none;
	border: none;
}

#topmenu > .x-pagelist-content {
	padding: 3em 1.5em;
}

#topmenu > .x-pagelist-header > .x-pagelist-tab {
	font-size: 22px;
	color: #aaa;
	cursor: pointer;
	padding: .5em 1em;
}

#topmenu > .x-pagelist-header > .x-pagelist-tab > .x-pagelist-title {
	padding: 0;
}

#topmenu > .x-pagelist-header > .x-pagelist-tab.selected {
	color: #333;
}

#topmenu > .x-pagelist-header > .x-pagelist-tab.selected,
#topmenu > .x-pagelist-header > .x-pagelist-tab:focus,
#topmenu > .x-pagelist-header > .x-pagelist-tab:hover
{
	background: none;
}

#topmenu > .x-pagelist-header > .x-pagelist-selection-bar {
	background-color: #ddd;
}

#topmenu:focus-within > .x-pagelist-header > .x-pagelist-selection-bar {
	background-color: #ddf;
}

#about_us {
	display: grid;
	grid-template-columns: 50% 50%;
	gap: 0 4em;
}

.person-box {
	display: flex;
	flex-flow: column;
	align-items: center;
}

.person-box h2 { margin: 0; }
.person-box img { margin: 1em 0; }

</style>
<script>

window.on('load', function() {
	topmenu.items = [...$('template[id^=pagetpl_]')].map(e => H(e.html))
})

</script>

<template id=pagetpl_what>
	<div title="What we do">
	</div>
</template>

<template id=pagetpl_about>
	<div title="Who we are" id=about_us>

		<div class=person-box>
			<img src=cosmin.jpg>
			<h2>Cosmin Apreutesei</h2>
			<div>Founder & CEO</div>
			<p>
				Cosmin learned to program in 5th grade on a Z80,
				He got his first paying job at 17 when he wrote
				an online shop in php back in 1999.
			</p>
			<p>
				In the past he worked on everything from device drivers
				to compilers to automatic pricing software
				for large Amazon sellers.
			</p>
			<p>
				Cosmin is also known in the Open Source world for
				<a href="https://luapower.com/" target="_blank">luapower.com</a>,
				a hefty collection of cross-platform libraries for the Lua
				programming language.
			</p>
		</div>

		<div class=person-box>
			<img src=denisa.jpg>
			<h2>Denisa Zetu</h2>
			<div>Business Analyst</div>
			<p>
				Denisa, say a few words about yourself dear, please.
			</p>
		</div>

	</div>
</template>

<template id=pagetpl_jobs>
	<div title="Jobs">
		<h2>Programmer</h2>

		<h2>Business Analyst</h2>
	</div>
</template>

<template id=pagetpl_contact>
	<div title="Contact" style="display: grid; grid-template-columns: auto auto; grid-column-gap: 1em">
		<div class=title>Phone:</div><div class=title>+40 754 958 185</div>
		<div>Email:</div><a href="mailto:office@allegory.ro">office@allegory.ro</a>
	</div>
</template>

</head>
<body>
	<a href="/"><img class=big-logo src=allegory.png></a>
	<x-pagelist id=topmenu></x-pagelist>
	<div class=footer>
		<small style="color: #888">2020 © Allegory Software |
			<a href=terms.html style="color: #888">Terms of Use</a> |
			<a href=privacy.html style="color: #888">Privacy Policy</a>
		</small>
	</div>
</body>
</html>
