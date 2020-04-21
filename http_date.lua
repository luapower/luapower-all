
--HTTP date parsing and formatting.
--Written by Cosmin Apreutesei. Public Domain.

local glue = require'glue'

--parsing

local wdays = {'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'}
local weekdays = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'}
local months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}

local wdays_map    = glue.index(wdays)
local weekdays_map = glue.index(weekdays)
local months_map   = glue.index(months)

local function check(w,d,mo,y,h,m,s)
	return w and mo and d >= 1 and d <= 31 and y <= 9999
			and h <= 23 and m <= 59 and s <= 59
end

--wkday "," SP 2DIGIT-day SP month SP 4DIGIT-year SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP "GMT"
--eg. Sun, 06 Nov 1994 08:49:37 GMT
local function rfc1123date(s)
	local w,d,mo,y,h,m,s = s:match'([A-Za-z]+), (%d+)[ %-]([A-Za-z]+)[ %-](%d+) (%d+):(%d+):(%d+) GMT'
	d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
	w = wdays_map[w]
	mo = months_map[mo]
	if not check(w,d,mo,y,h,m,s) then return end
	return {wday = w, day = d, year = y, month = mo,
			hour = h, min = m, sec = s, utc = true}
end

--weekday "," SP 2DIGIT "-" month "-" 2DIGIT SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP "GMT"
--eg. Sunday, 06-Nov-94 08:49:37 GMT
local function rfc850date(s)
	local w,d,mo,y,h,m,s = s:match'([A-Za-z]+), (%d+)%-([A-Za-z]+)%-(%d+) (%d+):(%d+):(%d+) GMT'
	d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
	w = weekdays_map[w]
	mo = months_map[mo]
	if y then y = y + (y > 50 and 1900 or 2000) end
	if not check(w,d,mo,y,h,m,s) then return end
	return {wday = w, day = d, year = y,
			month = mo, hour = h, min = m, sec = s, utc = true}
end

--wkday SP month SP ( 2DIGIT | ( SP 1DIGIT )) SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP 4DIGIT
--eg. Sun Nov  6 08:49:37 1994
local function asctimedate(s)
	local w,mo,d,h,m,s,y = s:match'([A-Za-z]+) ([A-Za-z]+) +(%d+) (%d+):(%d+):(%d+) (%d+)'
	d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
	w = wdays_map[w]
	mo = months_map[mo]
	if not check(w,d,mo,y,h,m,s) then return end
	return {wday = w, day = d, year = y, month = mo,
			hour = h, min = m, sec = s, utc = true}
end

local function parse(s)
	return rfc1123date(s) or rfc850date(s) or asctimedate(s)
end

--formatting

local function format(t, fmt)
	if not fmt or fmt == 'rfc1123' then
		--wkday "," SP 2DIGIT-day SP month SP 4DIGIT-year SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP "GMT"
		if type(t) == 'table' then
			t = glue.time(t)
		end
		local t = os.date('!*t', t)
		return string.format('%s, %02d %s %04d %02d:%02d:%02d GMT',
			wdays[t.wday], t.day, months[t.month], t.year, t.hour, t.min, t.sec)
	else
		--TODO: other formats...
		error'invalid format'
	end
end

--self-test

if not ... then
	require'unit'
	local d = {day = 6, sec = 37, wday = 1, min = 49, year = 1994, month = 11, hour = 8, utc = true}
	test(parse'Sun, 06 Nov 1994 08:49:37 GMT', d)
	test(parse'Sun, 06-Nov-1994 08:49:37 GMT', d) --RFC my ass...
	test(parse'Sunday, 06-Nov-94 08:49:37 GMT', d)
	test(parse'Sun Nov  6 08:49:37 1994', d)
	test(parse'Sun Nov 66 08:49:37 1994', nil)
	test(parse'SundaY, 06-Nov-94 08:49:37 GMT', nil)
	d.wday = nil --it gets populated based on date.
	test(format(d), 'Sun, 06 Nov 1994 08:49:37 GMT')
end

return {
	parse = parse,
	format = format,
}
