--[[
	date/time/timestamp encoding and decoding helpers

	decode_time|date|timestamp(dt_buf, fbapi, [t], [tm_buf]) -> t, tm_buf
	encode_time|date|timestamp(t, dt_buf, fbapi)

	mktime(t) -> setmetatable(t, time_meta)
	mkdate(t) -> setmetatable(t, date_meta)
	mktimestamp(t) -> setmetatable(t, timestamp_meta)

]]

do return true end

module(...,require 'fbclient.module')

local alien = require 'alien'

local function format_time(t)
	local tt = { --os.time() breaks if fields month, day, hour are not present
		year = t.year or 0,
		month = t.month or 0,
		day = t.day or 0,
		hour = t.hour,
		min = t.min,
		sec = t.sec,
		isdst = t.isdst
	}
	return os.date('%X', os.time(tt))..(t.sfrac and ' '..tostring(t.sfrac) or '')
end

local function format_date(t)
	return os.date('%x', os.time(t))
end

local function format_timestamp(t)
	return os.date('%x %X', os.time(t))..(t.sfrac and ' '..tostring(t.sfrac) or '')
end

local function date_equal(t1,t2)
	return t1.day == t2.day and t1.month == t2.month and t1.year == t2.year
end

local function time_equal(t1,t2)
	return t1.sfrac == t2.sfrac and t1.sec == t2.sec and t1.min == t2.min and t1.hour == t2.hour
end

local function timestamp_equal(t1,t2)
	return date_equal(t1,t2) and time_equal(t1,t2)
end

time_meta = {
	__type = 'fbclient time',
	__tostring = format_time,
	__eq = time_equal,
}

date_meta = {
	__type = 'fbclient date',
	__tostring = format_date,
	__eq = date_equal,
}

timestamp_meta = {
	__type = 'fbclient timestamp',
	__tostring = format_timestamp,
	__eq = timestamp_equal,
}

function mktime(t) return setmetatable(t, time_meta) end
function mkdate(t) return setmetatable(t, date_meta) end
function mktimestamp(t) return setmetatable(t, timestamp_meta) end


local TM_STRUCT = 'iiiiiiiii' -- C's tm struct: sec,min,hour,day,mon,year,wday,yday,isdst
local ISC_TIME_SECONDS_PRECISION = 10000 -- firebird keeps time in seconds*ISC_TIME_SECONDS_PRECISION.

--BUG: for some reason, in Linux, isc_decode_timestamp writes 2 integers outside the TM_STRUCT space !!
TM_STRUCT = TM_STRUCT..'xxxxxxxx'

function decode_time(dt_buf,fbapi,t,tm_buf)
	t = t or {}
	tm_buf = tm_buf or alien.buffer(struct.size(TM_STRUCT))
	fbapi.isc_decode_sql_time(dt_buf, tm_buf)
	t.sec,t.min,t.hour = struct.unpack(TM_STRUCT,tm_buf,struct.size(TM_STRUCT))
	t.sfrac = dt_buf:get(1,'uint') % ISC_TIME_SECONDS_PRECISION
	return mktime(t),tm_buf
end

function decode_date(dt_buf,fbapi,t,tm_buf)
	t = t or {}
	tm_buf = tm_buf or alien.buffer(struct.size(TM_STRUCT))
	fbapi.isc_decode_sql_date(dt_buf, tm_buf)
	local x
	x,x,x,t.day,t.month,t.year,t.wday,t.yday,t.isdst =
		struct.unpack(TM_STRUCT,tm_buf,struct.size(TM_STRUCT))
	t.month = t.month+1
	t.year = t.year+1900
	t.wday = t.wday+1
	t.yday = t.yday+1
	t.isdst = t.isdst ~= 0
	return mkdate(t),tm_buf
end

function decode_timestamp(dt_buf,fbapi,t,tm_buf)
	t = t or {}
	tm_buf = tm_buf or alien.buffer(struct.size(TM_STRUCT))
	fbapi.isc_decode_timestamp(dt_buf, tm_buf)
	t.sec,t.min,t.hour,t.day,t.month,t.year,t.wday,t.yday,t.isdst =
		struct.unpack(TM_STRUCT,tm_buf,struct.size(TM_STRUCT))
	t.month = t.month+1
	t.year = t.year+1900
	t.wday = t.wday+1
	t.yday = t.yday+1
	t.isdst = t.isdst ~= 0
	local dx = dt_buf:get(1,'int')
	local tx = dt_buf:get(1+INT_SIZE,'uint')
	t.sfrac = tx % ISC_TIME_SECONDS_PRECISION
	return mktimestamp(t),tm_buf
end

function encode_time(t,dt_buf,fbapi)
	local tm = struct.pack(TM_STRUCT,t.sec or 0,t.min or 0,t.hour or 0,0,0,0,0,0,0)
	fbapi.isc_encode_sql_time(tm, dt_buf)
	if t.sfrac then
		dt_buf:set(1,dt_buf:get(1,'uint')+t.sfrac,'uint')
	end
end

function encode_date(t,dt_buf,fbapi)
	local tm = struct.pack(TM_STRUCT,0,0,0,
							t.day or 1,(t.month or 1)-1,(t.year or 1900)-1900,0,0,0)
	fbapi.isc_encode_sql_date(tm, dt_buf)
end

function encode_timestamp(t,dt_buf,fbapi)
	local tm = struct.pack(TM_STRUCT,t.sec or 0,t.min or 0,t.hour or 0,
							t.day or 1,(t.month or 1)-1,(t.year or 1900)-1900,0,0,0)
	fbapi.isc_encode_timestamp(tm, dt_buf)
	if t.sfrac then
		dt_buf:set(1+INT_SIZE,dt_buf:get(1+INT_SIZE,'uint')+t.sfrac,'uint')
	end
end

