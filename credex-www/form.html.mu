<style>
#header_ct, #footer_ct {
	width: 100%;
	background-color: #522e90;
	display: flex;
	flex-flow: column;
	align-items: center;
	text-align: center;
	color: white;
}

#form_ct {
	padding: 0 1em;
	width: 100%;
	max-width: 70rem;
}

#header_ct {
	background-image: url(/background.png);
	background-position: center top;
	padding-top: 2rem;
	padding-bottom: 12rem;
}

#header {
	display: flex;
	flex-flow: column;
	align-items: center;
	justify-content: flex-start;
	position: relative;
}

#form {
	min-height: 580px;
	border: 1px solid #dae1e7;
	border-radius: .5rem;
	margin-top: -10rem;
	margin-bottom: 4rem;
	padding: 1.5rem 2rem;
	background-color: #fff;
	box-shadow: 0 4px 8px 0 rgba(0, 0, 0, .12), 0 2px 4px 0 rgba(0, 0, 0, .08);
}

#footer {
	display: flex;
	text-align: left;
	justify-content: space-between;
	align-items: center;
	padding: 1rem 0;
}

.pay_button {
	position: absolute;
	right: 0; top: 0;
	color: white;
	font-size: 1rem;
	margin-top: -1em;
	padding: 12px 1.5em;
	background: none;
	border-radius: 10rem;
	border: 1px solid #926ed0;
	font-size: .9rem;
	cursor: pointer;
	text-decoration: none;
	margin-bottom: 1rem;
	display: none;
	//letter-spacing: 1px;
}

.pay_button:hover {
	background-color: #724eb0;
}

@media (max-width: 567px) {
	.pay_button {
		position: relative;
	}
}

#pay_button1 { top:  50px; }
#pay_button2 { top: 250px; background-color: rgb(208,53,85); border-color: rgb(127,55,103); }
#pay_button3 { top: 100px; background-color: rgb(248,158,54); color: white; border-color: rgb(208,53,85); }
#pay_button4 { top: 150px; background-color: rgb(127,198,103); color: white;  }
#pay_button5 { top: 200px; background-color: rgb(99,67,156); }
#pay_button6 { top:   0px; background-color: rgb(49,165,219); border-color: rgb(108,190,230); }

</style>

<div id=header_ct>
	<div id=form_ct>
		<div id=header>
			<a class=pay_button id=pay_button6 href="/plateste-rata">PLATESTE RATA</a>
			<img src="/logo_ifn.png" style="margin-left: 1rem">
			<div style="font-size: 185%; padding-top: 2.5rem; padding-bottom: .5em">
				Orice plan ai avea, noi te ajutam sa devina realitate!
			</div>
			<div style="font-size: 112%">
				Cu Creditul de nevoi personale de la Credex IFN, beneficiezi de rate
				fixe pe toata perioada contractului si dobanzi avantajoase.
			</div>
			<div style="padding: 1rem 0">
				<img src="/email_top.svg" alt="Email box" style="width: 1rem; margin: 0 .25rem">
				contact@credex-ifn.ro
			</div>
		</div>
	</div>
</div>

<div id=form_ct>
	<div id=form>
		{{>form_content}}
	</div>
</div>

<div id=footer_ct>
	<div id=form_ct>
		<div id=footer>
			<div>
				<img src="/logo_ifn.png" style="padding-top: 1rem">
				<div><a href="/Termeni-si-conditii.pdf">Termeni de utilizare</a></div>
			</div>
			<div class="grey" style="margin-left: 1rem">
				© Copyright Credex IFN 2019. All rights reserved.
			</div>
		</div>
	</div>
</div>
