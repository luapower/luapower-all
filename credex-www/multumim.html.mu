<style>
#main {
	display: flex;
	flex-flow: column;
	align-items: center;
	text-align: center;
	padding: 6rem 2em;
	max-width: 40rem;
}
</style>
<div id=main>
	<img style="width: 20rem" src="/illustration_overlay.png">
	<div style="font-size: 125%; padding: 2em 0">
		{{#error_message}}
			<div class="error">{{error_message}}</div>
			<div>Va rugam incercati din nou.</div>
		{{/error_message}}
		{{^error_message}}
			<div>Plata a fost inregistrata cu succes. Va multumim!</div>
			<div>Numarul platii este {{orderNumber}}.</div>
		{{/error_message}}
	</div>
</div>
