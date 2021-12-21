/*
 (c) 2011-2015, Vladimir Agafonkin, BSD License.
 SunCalc is a JavaScript library for calculating sun/moon position and light phases.
 https://github.com/mourner/suncalc
*/

let suncalc = {};

(function () {

// sun calculations are based on http://aa.quae.nl/en/reken/zonpositie.html formulas


// date/time constants and conversions

let day_s = 60 * 60 * 24
let J1970 = 2440588
let J2000 = 2451545

function to_julian(t)   { return t / day_s - 0.5 + J1970 }
function from_julian(j) { return (j + 0.5 - J1970) * day_s }
function to_days(t)     { return to_julian(t) - J2000 }

// general calculations for position

let e = rad * 23.4397 // obliquity of the Earth

function right_ascension(l, b) { return atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l)) }
function declination(l, b)     { return asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l)) }
function azimuth(H, phi, dec)  { return atan2(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi)) }
function altitude(H, phi, dec) { return asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H)) }
function sidereal_time(d, lw)  { return rad * (280.16 + 360.9856235 * d) - lw }

function astro_refraction(h) {
	if (h < 0) // the following formula works for positive altitudes only.
		h = 0 // if h = -0.08901179 a div/0 would occur.
	// formula 16.4 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
	// 1.02 / tan(h + 10.26 / (h + 5.10)) h in degrees, result in arc minutes -> converted to rad:
	return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179))
}

// general sun calculations

function solar_mean_anomaly(d) {
	return rad * (357.5291 + 0.98560028 * d)
}

function ecliptic_longitude(M) {
	let C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M)) // equation of center
	let P = rad * 102.9372 // perihelion of the Earth
	return M + C + P + PI
}

function sun_coords(d) {
	let M = solar_mean_anomaly(d)
	let L = ecliptic_longitude(M)
	return {
		dec : declination(L, 0),
		ra  : right_ascension(L, 0)
	}
}

// calculates sun position for a given date and latitude/longitude

suncalc.sun_position = function(t, lat, lng) {
	let lw  = rad * -lng
	let phi = rad *  lat
	let d = to_days(t)
	let c = sun_coords(d)
	let H = sidereal_time(d, lw) - c.ra
	return {
		azimuth  : azimuth (H, phi, c.dec),
		altitude : altitude(H, phi, c.dec),
	}
}


// sun times configuration (angle, morning name, evening name)

let times = suncalc.times = [
	[-0.833, 'sunrise',         'sunset'       ],
	[  -0.3, 'sunrise_end',     'sunset_start' ],
	[    -6, 'dawn',            'dusk'         ],
	[   -12, 'nautical_dawn',   'nautical_dusk'],
	[   -18, 'night_end',       'night'        ],
	[     6, 'golden_hour_end', 'golden_hour'  ]
]

// calculations for sun times

let J0 = 0.0009

function julian_cycle(d, lw) { return round(d - J0 - lw / (2 * PI)) }

function approx_transit(Ht, lw, n) { return J0 + (Ht + lw) / (2 * PI) + n }
function solar_transit_j(ds, M, L) { return J2000 + ds + 0.0053 * sin(M) - 0.0069 * sin(2 * L) }

function hour_angle(h, phi, d) { return acos((sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d))) }
function observer_angle(height) { return -2.076 * sqrt(height) / 60 }

// returns set time for the given sun altitude
function get_set_j(h, lw, phi, dec, n, M, L) {
	let w = hour_angle(h, phi, dec)
	let a = approx_transit(w, lw, n)
	return solar_transit_j(a, M, L)
}


// calculates sun times for a given date, latitude/longitude, and, optionally,
// the observer height (in meters) relative to the horizon

suncalc.times = function (t, lat, lng, height) {

	height = height || 0

	let lw  = rad * -lng
	let phi = rad *  lat

	let dh = observer_angle(height)

	let d = to_days(t)
	let n = julian_cycle(d, lw)
	let ds = approx_transit(0, lw, n)

	let M = solar_mean_anomaly(ds)
	let L = ecliptic_longitude(M)
	let dec = declination(L, 0)

	let Jnoon = solar_transit_j(ds, M, L)

	let result = {
		solar_noon: from_julian(Jnoon),
		nadir: from_julian(Jnoon - 0.5)
	}

	for (let i = 0, len = times.length; i < len; i++) {

		let time = times[i]
		let h0 = (time[0] + dh) * rad

		let Jset = get_set_j(h0, lw, phi, dec, n, M, L)
		let Jrise = Jnoon - (Jset - Jnoon)

		result[time[1]] = from_julian(Jrise)
		result[time[2]] = from_julian(Jset)
	}

	return result
}


// moon calculations, based on http://aa.quae.nl/en/reken/hemelpositie.html formulas

function moon_coords(d) { // geocentric ecliptic coordinates of the moon

	let L = rad * (218.316 + 13.176396 * d) // ecliptic longitude
	let M = rad * (134.963 + 13.064993 * d) // mean anomaly
	let F = rad * ( 93.272 + 13.229350 * d) // mean distance

	let l  = L + rad * 6.289 * sin(M) // longitude
	let b  = rad * 5.128 * sin(F)     // latitude
	let dt = 385001 - 20905 * cos(M)  // distance to the moon in km

	return {
		ra   : right_ascension(l, b),
		dec  : declination(l, b),
		dist : dt
	}

}

suncalc.moon_position = function (t, lat, lng) {

	let lw  = rad * -lng
	let phi = rad * lat
	let d   = to_days(t)

	let c = moon_coords(d)
	let H = sidereal_time(d, lw) - c.ra
	let h = altitude(H, phi, c.dec)
	// formula 14.1 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
	let pa = atan2(sin(H), tan(phi) * cos(c.dec) - sin(c.dec) * cos(H))

	h = h + astro_refraction(h) // altitude correction for refraction

	return {
		azimuth  : azimuth(H, phi, c.dec),
		altitude : h,
		distance : c.dist,
		parallactic_angle: pa,
	}
}


// calculations for illumination parameters of the moon,
// based on http://idlastro.gsfc.nasa.gov/ftp/pro/astro/mphase.pro formulas and
// Chapter 48 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.

suncalc.moon_illumination = function (t) {

	let d = to_days(t)
	let s = sun_coords(d)
	let m = moon_coords(d)

	let sdist = 149598000 // distance from Earth to Sun in km

	let phi = acos(sin(s.dec) * sin(m.dec) + cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra))
	let inc = atan2(sdist * sin(phi), m.dist - sdist * cos(phi))
	let angle = atan2(
			cos(s.dec) * sin(s.ra - m.ra),
			sin(s.dec) * cos(m.dec) - cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra)
		)

	return {
		fraction: (1 + cos(inc)) / 2,
		phase: 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / PI,
		angle: angle
	}
}


function hours_later(t, h) {
	return t + h * day_s / 24
}

// calculations for moon rise/set times are based on http://www.stargazing.net/kepler/moonrise.html article

suncalc.moon_times = function (t, lat, lng) {

	let hc = 0.133 * rad
	let h0 = suncalc.moon_position(t, lat, lng).altitude - hc

	// go in 2-hour chunks, each time seeing if a 3-point quadratic curve crosses zero (which means rise or set)
	let rise, set
	for (let i = 1; i <= 24; i += 2) {

		let h1 = suncalc.moon_position(hours_later(t, i), lat, lng).altitude - hc
		let h2 = suncalc.moon_position(hours_later(t, i + 1), lat, lng).altitude - hc

		let a = (h0 + h2) / 2 - h1
		let b = (h2 - h0) / 2
		let xe = -b / (2 * a)
		let ye = (a * xe + b) * xe + h1
		let d = b * b - 4 * a * h1
		let roots = 0

		if (d >= 0) {
			let dx = sqrt(d) / (abs(a) * 2)
			let x1 = xe - dx
			let x2 = xe + dx
			if (abs(x1) <= 1) roots++
			if (abs(x2) <= 1) roots++
			if (x1 < -1) x1 = x2
		}

		if (roots === 1) {
			if (h0 < 0)
				rise = i + x1
			else
				set = i + x1
		} else if (roots === 2) {
			rise = i + (ye < 0 ? x2 : x1)
			set = i + (ye < 0 ? x1 : x2)
		}

		if (rise && set)
			break

		h0 = h2
	}

	let result = {}

	if (rise)
		result.rise = hours_later(t, rise)
	if (set)
		result.set = hours_later(t, set)

	if (!rise && !set)
		result[ye > 0 ? 'alwaysUp' : 'alwaysDown'] = true

	return result
}

}())
