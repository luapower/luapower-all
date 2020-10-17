<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="initial-scale=1">
<title>ALLEGORY SOFTWARE</title>
<meta charset="utf-8">
<link rel="stylesheet" type="text/css" href="x-widgets.css">
<link rel="stylesheet" type="text/css" href="fontawesome.css">
<script src="glue.js"></script>
<script src="divs.js"></script>
<script src="x-widgets.js"></script>
<script src="x-nav.js"></script>
<script src="x-input.js"></script>
<script src="x-grid.js"></script>
<script src="x-listbox.js"></script>
<style>

* { box-sizing: border-box; }

* { overflow-anchor: none; }

@font-face {
	font-family: "opensans-light";
	src: url("OpenSans-Light.ttf");
}

@font-face {
	font-family: "opensans";
	src: url("OpenSans-Regular.ttf");
}

/* tags ------------------------------------------------------------------- */

h1, h2, h3 {
	font-family: opensans-light, arial, sans-serif;
	font-weight: normal;
}

h2 { font-size: 22px; }
h3 { font-size: 18px; }

:focus {
	outline: none;
}

img {
	max-width: 100%;
	height: auto;
}

a {
	text-decoration: none;
	color: #000;
}

body {
	font-family: opensans, arial, sans-serif;
	font-size: 15px;
	line-height: 2;
}

/* body ------------------------------------------------------------------- */

html, body {
	min-height: calc(100vh - 20px); /* because horizontal scrollbar is not counted */
	display: flex;
	flex-flow: column;
	flex: 1;
	margin: 0;
	padding: 0;
}

body {
	margin: auto; /* use in place of `safe center` which doesn't work */
	padding: 2em 2em .5em 2em;
	overflow-y: scroll;
	display: flex;
	flex-flow: column;
	align-items: center;
}

/* top menu --------------------------------------------------------------- */

#topmenu {
	align-self: center;
}

#topmenu > .x-pagelist-header {
	font-family: opensans-light, arial, sans-serif;
	margin-top: 1em;
	justify-content: center;
	background: none;
	border: none;
}

@media (max-width: 620px) {
	#topmenu {
		align-self: start;
	}
	#topmenu > .x-pagelist-header {
		flex-flow: column;
	}
}

#topmenu > .x-pagelist-content {
	padding: 3em 1.5em;
	display: flex;
	overflow: visible;
}

#topmenu > .x-pagelist-header > .x-pagelist-tab {
	font-size: 22px;
	color: #aaa;
	cursor: pointer;
	padding: .5em 1em;
}

#topmenu > .x-pagelist-header > .x-pagelist-tab > .x-pagelist-title {
	padding: 0;
	white-space: nowrap !important;
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

/* footer ----------------------------------------------------------------- */

.footer {
	display: flex;
	flex-flow: row wrap;
}

.footer a, .footer span {
	color: #888;
	font-size: 80%;
	white-space: nowrap;
	padding: 0 .5em;
}

/* what-we-do page -------------------------------------------------------- */

.demo-page {
	max-width: 480px;
	overflow: visible;
	display: flex;
	flex-flow: column;
	flex: 1;
	font-size: 18px;
	font-family: opensans-light, arial, sans-serif;
}

#demo_grid {
	width: 85vw;
	align-self: center;
	border: 1px solid #f99;
}

/* about us --------------------------------------------------------------- */

.about-page {
	display: flex;
	flex-flow: column;
}

.person-boxes {
	display: flex;
	flex-flow: wrap;
	gap: 0 4em;
}

.person-box {
	max-width: 300px;
	display: flex;
	flex-flow: column;
	align-items: center;
}

.person-box h2 { margin: 0; }
.person-box img { margin: 1em 0; }

/* contact page ----------------------------------------------------------- */

#contact_page {
	align-self: start;
	display: grid;
	align-items: start;
	grid-template-columns: auto auto;
	grid-column-gap: 1em;
}

</style>
<script>

window.on('load', function() {

	topmenu.can_move_items = false
	topmenu.items = [...$('template[id^=pagetpl_]')].map(e => H(e.html))

	let icons = {male: 'mars', female: 'venus'}
	demo_grid.col_attrs = {
		gender: {
			format: v => icons[v] ? div({class: 'fa fa-'+icons[v], title: v}) : v,
			w: 22,
		},
	}
	demo_grid.rowset_url = 'demo_rowset.json'
	demo_grid.reload()

})

</script>

<template id=pagetpl_what>
	<div title="What we do" class=demo-page>

<div>
Simply put, we make the <b>fastest</b>, <b>slickest</b>, most <b>kick-ass</b>
<b>custom business applications</b> in the world today.
<br>
<br>

</div>

		<x-grid id=demo_grid></x-grid>

	</div>
</template>

<template id=pagetpl_about>
	<div title="Who we are" class=about-page>

		<h3>
		We are a fast-growing company based in Bucharest.
		</h3>

		<div class=person-boxes>

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
					an extensive collection of cross-platform libraries for the Lua
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

	</div>
</template>

<template id=pagetpl_jobs>
	<div title="Jobs">
		<h2>Programmer</h2>
		<p>Coming soon...</p>
		<h2>Business Analyst</h2>
		<p>Coming soon...</p>
	</div>
</template>

<template id=pagetpl_contact>
	<div title="Contact" id=contact_page>
		<h3>Phone:</h3><h3>+40 754 958 185</h3>
		<h3>Email:</h3><h3><a href="mailto:office@allegory.ro">office@allegory.ro</a></h3>
	</div>
</template>

</head>
<body>
	<a href="/"><img class=big-logo src=allegory.png></a>
	<x-pagelist id=topmenu></x-pagelist>
	<div class=footer>
		<span>2020 © Allegory Software</span>
		<a href=terms.html>Terms of Use</a>
		<a href=privacy.html>Privacy Policy</a>
	</div>
</body>
</html>
