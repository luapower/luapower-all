<!DOCTYPE html>
<html>
<head>
<link rel="shortcut icon" href="/favicon.ico">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<style>

*, *::before, *::after {
	box-sizing: border-box;
	//border: 1px solid blue;
}

html, body {
	margin: 0;
	padding: 0;
}

a {
	color: inherit;
}

img {
	display: inline-block;
	max-width: 100%;
	height: auto;
}

html {
	font-family: sans-serif;
	font-size: 16px;
	line-height: 1.25;
	color: #22292f;
}

body {
	display: flex;
	flex-flow: column;
	align-items: center;
}

input, textarea {
	border: 0;
	border-bottom: 1px solid #aaa;
	font: inherit;
	padding: .5rem 0;
	padding-bottom: 4px;
}

input:focus, textarea:focus {
	outline: none;
	padding-bottom: 3px;
	border-bottom: 2px solid #1999d6;
}

input[type=checkbox] {
	width: auto;
	display: inline-block;
	margin: .5em 0;
	margin-right: .25em;
}

button:focus {
	outline: none;
}

button[type=submit] {
	color: white;
	font-size: 1rem;
	border: 0;
	border-radius: 10rem;
	padding: .75em 4em;
	background-color: #1999d6;
	margin: 2rem 0;
}

button[type=submit]:hover {
	background-color: #1090c6;
}

.grey    { color: #8795a1; }
.blue    { color: #1999d6; }

a.blue { text-decoration: none; }

.error:not(:empty) {
	color: white;
	background-color: red;
	padding: .5rem 1rem;
	border-radius: .25rem;
	background-color: #e3342f;
	margin: 1rem 0;
}

</style>
</head>

<body>
{{>main_content}}
</body>

</html>
