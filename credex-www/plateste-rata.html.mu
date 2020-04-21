<style>

#main {
	display: flex;
	flex-flow: column nowrap;
	align-items: flex-start;
	justify-content: flex-end;
}

.input_ct {
	padding: 1rem 0;
}

.logo {
	max-width: auto;
	height: auto;
}

</style>

<div style="font-size: 1.5rem; padding-bottom: 1rem">
	Plateste rata
</div>

<div class="grey" style="font-size: .85rem;">
	<i>Campurile marcate cu * sunt obligatorii.</i>
</div>

<form id=main method=post>
	<div class=error>{{error}}</div>
	<div class="input_ct">
		<input name=cnp placeholder="CNP: *" required value="{{cnp}}">
	</div>
	<div class="input_ct">
		<input name=cid placeholder="Numar contract:" value="{{cid}}">
		<div class="grey" style="font-size: .85rem;">
			<i>Optional. Numarul de contract este format din 11 cifre.</i>
		</div>
	</div>
	<div class="input_ct">
		<input name=amount placeholder="Suma de plata: *" required value="{{amount}}">
		<div class="grey" style="font-size: .85rem;">
			<i>Pentru zecimale folositi punctul.</i>
		</div>
	</div>
	<div class="input_ct"> <button type=submit>Plateste</button> </div>
	<div style="border-bottom: 1px solid #ccc; align-self: stretch; margin: 1rem 0;"></div>
	<div style="align-self: stretch; display: flex; flex-flow: wrap; justify-content: space-between">
		<img class=logo style="height: 100%" src="/visa_mastercard.gif">
		<div>
			<img class=logo src="/verified_by_visa.gif">
			<img class=logo src="/securecode.gif">
			<img class=logo src="/logo_bt.png">
		</div>
	</div>
</form>
