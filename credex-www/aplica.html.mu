<style>
#splitter {
	display: flex;
	flex-flow: row wrap;
}

#leftside {
	display: flex;
	flex-flow: wrap;
	align-items: flex-start;
	justify-content: flex-start;
	padding-right: 1rem;
	width: 0;
	min-width: 12rem;  /* auto-wrap the right side */
	flex-grow: 1;
}

#rightside {
	padding-bottom: 2em;
}

.half_ct, .full_ct {
	flex: 1 0 50%;
	display: flex;
	padding: 1rem;
	min-width: 12em;
}

.full_ct {
	flex: 0 0 100%;
}

.half, .full {
	flex: 0 0 100%;
	min-width: 0;
	width: auto;
}

/* put padding between sides, but only while they're _not_ wrapped */
@media (min-width: 620px) {
	#rightside {
		padding-left: 1.5rem;
		border-left: 1px solid #ddd;
	}
}

.icon {
	display: inline-block;
	width: 1rem;
	margin-right: .5rem;
}

.pay_button {
	display: block; /* invisible by default, only visibile on this page */
}

</style>

<div style="font-size: 1.5rem; padding-bottom: .25rem">
	Aplica pentru un credit
</div>

<div class="grey" style="padding: .25rem 0">
	<img src="/info.svg" alt="Info icon">
	Lasa-ne datele si te vom contacta in cel mai scurt timp.
</div>

<div class="grey" style="font-size: .85rem; margin-left: 1rem; ">
	<i>Campurile marcate cu * sunt obligatorii.</i>
</div>

<div class=error>{{error}}</div>

<div id=splitter>

	<form id=leftside method=post>

		<div class="half_ct"><input class="half" name="last_name"  placeholder="Nume: *"    required   value="{{last_name}}">  </div>
		<div class="half_ct"><input class="half" name="first_name" placeholder="Preume: *"  required   value="{{first_name}}"> </div>
		<div class="half_ct"><input class="half" name="phone"      placeholder="Telefon: *" required   value="{{phone}}">      </div>
		<div class="half_ct"><input class="half" name="email"      placeholder="Email:"     type=email value="{{email}}">      </div>

		<div class="full_ct">
			<textarea class="full" rows=3 name="message" placeholder="Mesaj: *" required>{{message}}</textarea>
		</div>

		<div style="margin: 1rem 0">
			<input id=agree1 name=agree1 type=checkbox required {{agree1}}>
			<label for=agree1 class="grey">
				Sunt de acord cu interogarea datelor mele din baza de date
				in Biroul de Credit, conform Acordului de transmitere si
				prelucrare a datelor cu caracter personal.
				- <a class="blue" href="/Acordul-BC-CREDEX-IFN.pdf">Detalii</a>
			</label>
		</div>

		<div>
			<input id=agree2 name=agree2 type=checkbox required {{agree2}}>
			<label for=agree2 class="grey">
				* Am citit Politica de prelucrare a datelor cu caracter personal.
				- <a class="blue" href="/Politica-date-cu-caracter-personal-CREDEX-IFN.pdf">Detalii</a>
			</label>
		</div>

		<button type=submit style="align-self: flex-start;">Trimite</button>

	</form>

	<div id=rightside>
		<h3>Detalii contact</h3>
		<div class=grey>
			<img src="/email.svg" alt="Email box" class="icon">
			E-mail <a class="blue" href="mailto:contact@credex-ifn.ro">contact@credex-ifn.ro</a>
		</div>
		<h3>Program</h3>
		<div class=grey>
			<img src="/program.svg" alt="Program" class="icon">
			Luni - Vineri <span style="color: black">09:00 - 18:00</span>
			<br>
			<img src="/program_inchis.svg" alt="Program Inchis" class="icon">
			Sambata - Duminica: <span style="color: red">inchis</span>
		</div>
		<h3>Sediu Central</h3>
		<div class=grey style="display: flex; align-items: flex-start;">
			<img src="/adresa.svg" alt="Adresa" class="icon">
			<div>
				Soseaua Bucuresti-Nord, Numarul 10,<br>
				Corp O1, Voluntari, Judetul Ilfov
			</div>
		</div>
	</div>

</div>
