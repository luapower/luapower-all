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

/* reset ------------------------------------------------------------------ */

@font-face {
	font-family: "opensans-light";
	src: url("OpenSans-Light.ttf");
}

@font-face {
	font-family: "opensans";
	src: url("OpenSans-Regular.ttf");
}

* { box-sizing: border-box; }

* { overflow-anchor: none; }

h1, h2, h3 {
	font-family: opensans-light, arial, sans-serif;
	font-weight: normal;
	line-height: 1.5;
	margin: 1em 0;
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
	height: 100vh;
	display: flex;
	flex-flow: column;
	margin: 0;
	padding: 0;
}

body {
	padding: 2em 2em .5em 2em;
	overflow-y: scroll;
}

/* top menu --------------------------------------------------------------- */

#topmenu {
	min-height: auto; /* don't scroll content, expand self */
}

#topmenu > .x-pagelist-header {
	font-family: opensans-light, arial, sans-serif;
	margin-top: .5em;
	justify-content: center;
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
	padding: 0; /* remove the padding to align the selection bar to the text */
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

#topmenu              > .x-pagelist-header > .x-pagelist-selection-bar,
#topmenu:focus-within > .x-pagelist-header > .x-pagelist-selection-bar {
	background-color: #ddd;
}

/* footer ----------------------------------------------------------------- */

.footer {
	align-self: center;
	display: flex;
	flex-flow: wrap;
	margin-top: 2em;
}

.footer a, .footer span {
	color: #888;
	font-size: 80%;
	white-space: nowrap;
	padding: 0 .5em;
}

/* demo page -------------------------------------------------------------- */

.demo-page {
	display: flex;
	flex-flow: column;
	font-size: 16px;
	font-family: opensans, arial, sans-serif;
}

.demo-page h1 { margin-top: 0; }

.demo-split {
	display: grid;
	grid-template-columns: 1fr 3fr;
	grid-gap: 2em;
}

.demo-split-2 {
	min-height: 50vh;
	border: 1px solid #f99;
}

.next-btn, .back-btn {
	float: right;
	font-size: 15px;
	font-family: opensans, arial, sans-serif;
	font-weight: normal;
	background-image: none !important;
	//box-shadow: 2px 1px 3px #00000033;
	padding: .4em 1.4em;
}

/* about page ------------------------------------------------------------- */

.about-page {
	justify-self: center;
	max-width: 85vw;
	margin-left: 50px;
	display: flex;
	flex-flow: column;
}

.person-boxes {
	display: flex;
	flex-flow: wrap;
	grid-gap: 0 4em;
}

.person-box {
	max-width: 240px;
	display: flex;
	flex-flow: column;
	align-items: center;
}

.person-box h2 { margin: 0; }
.person-box img { padding: 1em 2em; }
.person-box p { text-align: justify; }

/* jobs page ----------------------------------------------------------- */

.jobs-page {
	justify-self: center;
	min-width: 450px;
}

/* contact page ----------------------------------------------------------- */

.contact-page {
	justify-self: center;
	min-width: 450px;
}

.contact-table {
	align-self: start;
	display: grid;
	align-items: start;
	grid-template-columns: auto auto;
	grid-gap: 1em 0;
}

.contact-table h3 { margin: 0; }

/* mobile layout ---------------------------------------------------------- */

@media (max-width: 900px) {
	#topmenu {
		align-self: start;
	}
	#topmenu > .x-pagelist-header {
		flex-flow: column;
	}
	.demo-split {
		grid-template-columns: 1fr;
	}
	.footer {
		flex-flow: column;
		align-self: start;
	}
}

</style>
<script>

window.on('load', function() {

	topmenu.can_move_items = false
	topmenu.auto_focus_first_item = false
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
<div title="Our Deal" class=demo-page>

<div style="margin-bottom: 2em">
	The short answer is we build the <b>fastest</b>, <b>slickest</b>, most kick-ass
	<b>custom business software</b> in the industry today.
</div>

<div class=demo-split>

	<div class=demo-split-1>

		<h1>Computers are way faster than you think</h1>

		Let's look at the basic element that every business app is made of:
		the data grid. For instance, this grid here just loaded <b>50K records</b>
		from a database. Go ahead, <a href="/">hit refresh</a>. How's the scrolling?
		Try clicking on the header to reorder the rows. Click on a cell
		and start typing for quick-search (hit Enter for the next find).
		Drag to move some columns around. Drag some rows too.
		This could be your clinic's patient list. Or your online shop's inventory.
		<br>
		<br>
		<x-button class=next-btn align-x=right text="Tell me more..." primary></x-button>
		<x-button class=back-btn align-x=right text="Go back" disabled></x-button>
	</div>

	<x-grid id=demo_grid class=demo-split-2></x-grid>

</div>

</div>
</template>

<template id=pagetpl_about>
	<div title="Who we are" class="page about-page">

		<h3>
		We are a young software technology company based in Bucharest.
		</h3>

		<div class=person-boxes>

			<div class=person-box>
				<img src=cosmin.jpg>
				<h2>Cosmin Apreutesei</h2>
				<div>Founder & CEO</div>
				<p>
					Cosmin is a software developer with over 20 years of experience
					working on everything from compilers to device drivers to
					automatic pricing software for large Amazon sellers.
					He got his first paying job at 17 when he wrote an online shop
					for a local art dealer.
				</p>
				<p>
					Cosmin is also known in the Open Source world for luapower.com,
					a popular library distribution for the Lua programming language.
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
	<div title="Jobs" class=jobs-page>
		<h1>Available positions</h1>
		<h2>Good Programmer</h2>
		<p>Coming soon...</p>
		<h2>Good Business Analyst</h2>
		<p>Coming soon...</p>
	</div>
</template>

<template id=pagetpl_contact>
	<div title="Contact" class=contact-page>
		<h1>Get in touch with us</h1>
		<div class=contact-table>
			<h3>Phone:</h3><h3>+40 754 958 185</h3>
			<h3>Email:</h3><h3><a href="mailto:office@allegory.ro">office@allegory.ro</a></h3>
		</div>
		<h1>Company info</h1>
		<div class=contact-table>
			<h3>Name:</h3><h3>Allegory Software SRL</h3>
			<h3>EUID:</h3><h3>ROONRC.J40/13063/2020</h3>
		</div>
	</div>
</template>

</head>
<body>
	<a style="align-self: center" href="/"><img src=allegory.png></a>
	<x-pagelist id=topmenu></x-pagelist>
	<div class=footer>
		<span>2020 © Allegory Software</span>
		<a href=terms.html>Terms of Use</a>
		<a href=privacy.html>Privacy Policy</a>
	</div>
</body>
</html>
