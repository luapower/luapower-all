
--Lua "assorted lengths of wire" library.
--Written by Cosmin Apreutesei. Public domain.

if not ... then require'glue_test'; return end

local glue = {}

local min, max, floor, ceil, log =
	math.min, math.max, math.floor, math.ceil, math.log
local select, unpack, pairs, rawget = select, unpack, pairs, rawget

--math -----------------------------------------------------------------------

function glue.round(x, p)
	p = p or 1
	return floor(x / p + .5) * p
end

function glue.floor(x, p)
	p = p or 1
	return floor(x / p) * p
end

function glue.ceil(x, p)
	p = p or 1
	return ceil(x / p) * p
end

glue.snap = glue.round

function glue.clamp(x, x0, x1)
	return min(max(x, x0), x1)
end

function glue.lerp(x, x0, x1, y0, y1)
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
end

function glue.nextpow2(x)
	return max(0, 2^(ceil(log(x) / log(2))))
end

--varargs --------------------------------------------------------------------

if table.pack then
	glue.pack = table.pack
else
	function glue.pack(...)
		return {n = select('#', ...), ...}
	end
end

--always use this because table.unpack's default j is #t not t.n.
function glue.unpack(t, i, j)
	return unpack(t, i or 1, j or t.n or #t)
end

--tables ---------------------------------------------------------------------

--count the keys in a table with an optional upper limit.
function glue.count(t, maxn)
	local maxn = maxn or 1/0
	local n = 0
	for _ in pairs(t) do
		n = n + 1
		if n >= maxn then break end
	end
	return n
end

--reverse keys with values.
function glue.index(t)
	local dt={}
	for k,v in pairs(t) do dt[v]=k end
	return dt
end

--put keys in a list, optionally sorted.
local function desc_cmp(a, b) return a > b end
function glue.keys(t, cmp)
	local dt={}
	for k in pairs(t) do
		dt[#dt+1]=k
	end
	if cmp == true or cmp == 'asc' then
		table.sort(dt)
	elseif cmp == 'desc' then
		table.sort(dt, desc_cmp)
	elseif cmp then
		table.sort(dt, cmp)
	end
	return dt
end

--stateless pairs() that iterate elements in key order.
function glue.sortedpairs(t, cmp)
	local kt = glue.keys(t, cmp or true)
	local i = 0
	return function()
		i = i + 1
		return kt[i], t[kt[i]]
	end
end

--update a table with the contents of other table(s).
function glue.update(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t then
			for k,v in pairs(t) do dt[k]=v end
		end
	end
	return dt
end

--add the contents of other table(s) without overwrite.
function glue.merge(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t then
			for k,v in pairs(t) do
				if rawget(dt, k) == nil then dt[k]=v end
			end
		end
	end
	return dt
end

--get the value of a table field, and if the field is not present in the
--table, create it as an empty table, and return it.
function glue.attr(t, k, v0)
	local v = t[k]
	if v == nil then
		if v0 == nil then
			v0 = {}
		end
		v = v0
		t[k] = v
	end
	return v
end

--lists ----------------------------------------------------------------------

--extend a list with the elements of other lists.
function glue.extend(dt,...)
	for j=1,select('#',...) do
		local t=select(j,...)
		if t then
			local j = #dt
			for i=1,#t do dt[j+i]=t[i] end
		end
	end
	return dt
end

--append non-nil arguments to a list.
function glue.append(dt,...)
	local j = #dt
	for i=1,select('#',...) do
		dt[j+i] = select(i,...)
	end
	return dt
end

--insert n elements at i, shifting elemens on the right of i (i inclusive)
--to the right.
local function insert(t, i, n)
	if n == 1 then --shift 1
		table.insert(t, i, false)
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive)
--to the left.
local function remove(t, i, n)
	n = min(n, #t-i+1)
	if n == 1 then --shift 1
		table.remove(t, i)
		return
	end
	for p=i+n,#t do --shift n
		t[p-n] = t[p]
	end
	for p=#t,#t-n+1,-1 do --clean tail
		t[p] = nil
	end
end

--shift all the elements on the right of i (i inclusive) to the left
--or further to the right.
function glue.shift(t, i, n)
	if n > 0 then
		insert(t, i, n)
	elseif n < 0 then
		remove(t, i, -n)
	end
	return t
end

--map f over t or extract a column from a list of records.
function glue.map(t, f, ...)
	local dt = {}
	if #t == 0 then --treat as hashmap
		if type(f) == 'function' then
			for k,v in pairs(t) do
				dt[k] = f(k, v, ...)
			end
		else
			for k,v in pairs(t) do
				local sel = v[f]
				if type(sel) == 'function' then --method to apply
					dt[k] = sel(v, ...)
				else --field to pluck
					dt[k] = sel
				end
			end
		end
	else --treat as array
		if type(f) == 'function' then
			for i,v in ipairs(t) do
				dt[i] = f(v, ...)
			end
		else
			for i,v in ipairs(t) do
				local sel = v[f]
				if type(sel) == 'function' then --method to apply
					dt[i] = sel(v, ...)
				else --field to pluck
					dt[i] = sel
				end
			end
		end
	end
	return dt
end

--arrays ---------------------------------------------------------------------

--scan list for value. works with ffi arrays too given i and j.
function glue.indexof(v, t, eq, i, j)
	i = i or 1
	j = j or #t
	if eq then
		for i = i, j do
			if eq(t[i], v) then
				return i
			end
		end
	else
		for i = i, j do
			if t[i] == v then
				return i
			end
		end
	end
end

--reverse elements of a list in place. works with ffi arrays too given i and j.
function glue.reverse(t, i, j)
	i = i or 1
	j = (j or #t) + 1
	for k = 1, (j-i)/2 do
		t[i+k-1], t[j-k] = t[j-k], t[i+k-1]
	end
	return t
end

--binary search for an insert position that keeps the table sorted.
--works with ffi arrays too if lo and hi are provided.
local cmps = {}
cmps['<' ] = function(t, i, v) return t[i] <  v end
cmps['>' ] = function(t, i, v) return t[i] >  v end
cmps['<='] = function(t, i, v) return t[i] <= v end
cmps['>='] = function(t, i, v) return t[i] >= v end
local less = cmps['<']
function glue.binsearch(v, t, cmp, lo, hi)
	lo, hi = lo or 1, hi or #t
	cmp = cmp and cmps[cmp] or cmp or less
	local len = hi - lo + 1
	if len == 0 then return nil end
	if len == 1 then return not cmp(t, lo, v) and lo or nil end
	while lo < hi do
		local mid = floor(lo + (hi - lo) / 2)
		if cmp(t, mid, v) then
			lo = mid + 1
			if lo == hi and cmp(t, lo, v) then
				return nil
			end
		else
			hi = mid
		end
	end
	return lo
end

--strings --------------------------------------------------------------------

--string submodule. has its own namespace which can be merged with _G.string.
glue.string = {}

--split a string by a separator that can be a pattern or a plain string.
--return a stateless iterator for the pieces.
local function iterate_once(s, s1)
	return s1 == nil and s or nil
end
function glue.string.gsplit(s, sep, start, plain)
	start = start or 1
	plain = plain or false
	if not s:find(sep, start, plain) then
		return iterate_once, s:sub(start)
	end
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true; return s:sub(start) end
		return pass(s:find(sep, start, plain))
	end
end

--split a string into lines, optionally including the line terminator.
function glue.lines(s, opt)
	local term = opt == '*L'
	local patt = term and '([^\r\n]*()\r?\n?())' or '([^\r\n]*)()\r?\n?()'
	local next_match = s:gmatch(patt)
	local empty = s == ''
	local ended --string ended with no line ending
	return function()
		local s, i1, i2 = next_match()
		if s == nil then return end
		if s == '' and not empty and ended then s = nil end
		ended = i1 == i2
		return s
	end
end

--string trim12 from lua wiki.
function glue.string.trim(s)
	local from = s:match('^%s*()')
	return from > #s and '' or s:match('.*%S', from)
end

--escape a string so that it can be matched literally inside a pattern.
local function format_ci_pat(c)
	return ('[%s%s]'):format(c:lower(), c:upper())
end
function glue.string.esc(s, mode) --escape is a reserved word in Terra
	s = s:gsub('%%','%%%%'):gsub('%z','%%z')
		:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
	if mode == '*i' then s = s:gsub('[%a]', format_ci_pat) end
	return s
end

--string or number to hex.
function glue.string.tohex(s, upper)
	if type(s) == 'number' then
		return (upper and '%08.8X' or '%08.8x'):format(s)
	end
	if upper then
		return (s:gsub('.', function(c)
		  return ('%02X'):format(c:byte())
		end))
	else
		return (s:gsub('.', function(c)
		  return ('%02x'):format(c:byte())
		end))
	end
end

--hex to binary string.
function glue.string.fromhex(s)
	if #s % 2 == 1 then
		return glue.string.fromhex('0'..s)
	end
	return (s:gsub('..', function(cc)
	  return string.char(tonumber(cc, 16))
	end))
end

function glue.string.starts(s, p) --5x faster than s:find'^...' in LuaJIT 2.1
	return s:sub(1, #p) == p
end

function glue.string.ends(s, p)
	return p == '' or s:sub(-#p) == p
end

function glue.string.subst(s, t) --subst('{foo} {bar}', {foo=1, bar=2}) -> '1 2'
	return s:gsub('{([_%w]+)}', t)
end

--publish the string submodule in the glue namespace.
glue.update(glue, glue.string)

--iterators ------------------------------------------------------------------

--run an iterator and collect the n-th return value into a list.
local function select_at(i,...)
	return ...,select(i,...)
end
local function collect_at(i,f,s,v)
	local t = {}
	repeat
		v,t[#t+1] = select_at(i,f(s,v))
	until v == nil
	return t
end
local function collect_first(f,s,v)
	local t = {}
	repeat
		v = f(s,v); t[#t+1] = v
	until v == nil
	return t
end
function glue.collect(n,...)
	if type(n) == 'number' then
		return collect_at(n,...)
	else
		return collect_first(n,...)
	end
end

--closures -------------------------------------------------------------------

--no-op filters.
function glue.pass(...) return ... end
function glue.noop() return end

--memoize for 0, 1, 2-arg and vararg and 1 retval functions.
local function memoize0(fn) --for strict no-arg functions
	local v, stored
	return function()
		if not stored then
			v = fn(); stored = true
		end
		return v
	end
end
local nilkey = {}
local nankey = {}
local function memoize1(fn) --for strict single-arg functions
	local cache = {}
	return function(arg)
		local k = arg == nil and nilkey or arg ~= arg and nankey or arg
		local v = cache[k]
		if v == nil then
			v = fn(arg); cache[k] = v == nil and nilkey or v
		else
			if v == nilkey then v = nil end
		end
		return v
	end
end
local function memoize2(fn) --for strict two-arg functions
	local cache = {}
	return function(a1, a2)
		local k1 = a1 ~= a1 and nankey or a1 == nil and nilkey or a1
		local cache2 = cache[k1]
		if cache2 == nil then
			cache2 = {}
			cache[k1] = cache2
		end
		local k2 = a2 ~= a2 and nankey or a2 == nil and nilkey or a2
		local v = cache2[k2]
		if v == nil then
			v = fn(a1, a2)
			cache2[k2] = v == nil and nilkey or v
		else
			if v == nilkey then v = nil end
		end
		return v
	end
end
local function memoize_vararg(fn, minarg, maxarg)
	local cache = {}
	local values = {}
	return function(...)
		local key = cache
		local narg = min(max(select('#',...), minarg), maxarg)
		for i = 1, narg do
			local a = select(i,...)
			local k = a ~= a and nankey or a == nil and nilkey or a
			local t = key[k]
			if not t then
				t = {}; key[k] = t
			end
			key = t
		end
		local v = values[key]
		if v == nil then
			v = fn(...); values[key] = v == nil and nilkey or v
		end
		if v == nilkey then v = nil end
		return v
	end
end
local memoize_narg = {[0] = memoize0, memoize1, memoize2}
local function choose_memoize_func(func, narg)
	if narg then
		local memoize_narg = memoize_narg[narg]
		if memoize_narg then
			return memoize_narg
		else
			return memoize_vararg, narg, narg
		end
	else
		local info = debug.getinfo(func, 'u')
		if info.isvararg then
			return memoize_vararg, info.nparams, 1/0
		else
			return choose_memoize_func(func, info.nparams)
		end
	end
end
function glue.memoize(func, narg)
	local memoize, minarg, maxarg = choose_memoize_func(func, narg)
	return memoize(func, minarg, maxarg)
end

--memoize a function with multiple return values.
function glue.memoize_multiret(func, narg)
	local memoize, minarg, maxarg = choose_memoize_func(func, narg)
	local function wrapper(...)
		return glue.pack(func(...))
	end
	local func = memoize(wrapper, minarg, maxarg)
	return function(...)
		return glue.unpack(func(...))
	end
end

local tuple_mt = {__call = glue.unpack}
function tuple_mt:__tostring()
	local t = {}
	for i=1,self.n do
		t[i] = tostring(self[i])
	end
	return string.format('(%s)', table.concat(t, ', '))
end
function glue.tuples(narg)
	return glue.memoize(function(...)
		return setmetatable(glue.pack(...), tuple_mt)
	end)
end

--objects --------------------------------------------------------------------

--set up dynamic inheritance by creating or updating a table's metatable.
function glue.inherit(t, parent)
	local meta = getmetatable(t)
	if meta then
		meta.__index = parent
	elseif parent ~= nil then
		setmetatable(t, {__index = parent})
	end
	return t
end

--prototype-based dynamic inheritance with __call constructor.
function glue.object(super, o, ...)
	o = o or {}
	o.__index = super
	o.__call = super and super.__call
	glue.update(o, ...) --add mixins, defaults, etc.
	return setmetatable(o, o)
end

local function install(self, combine, method_name, hook)
	rawset(self, method_name, combine(self[method_name], hook))
end
local function before(method, hook)
	if method then
		return function(self, ...)
			hook(self, ...)
			return method(self, ...)
		end
	else
		return hook
	end
end
function glue.before(self, method_name, hook)
	install(self, before, method_name, hook)
end
local function after(method, hook)
	if method then
		return function(self, ...)
			method(self, ...)
			return hook(self, ...)
		end
	else
		return hook
	end
end
function glue.after(self, method_name, hook)
	install(self, after, method_name, hook)
end
local function override(method, hook)
	local method = method or glue.noop
	return function(...)
		return hook(method, ...)
	end
end
function glue.override(self, method_name, hook)
	install(self, override, method_name, hook)
end

--return a metatable that supports virtual properties.
--can be used with setmetatable() and ffi.metatype().
function glue.gettersandsetters(getters, setters, super)
	local get = getters and function(t, k)
		local get = getters[k]
		if get then return get(t) end
		return super and super[k]
	end
	local set = setters and function(t, k, v)
		local set = setters[k]
		if set then set(t, v); return end
		rawset(t, k, v)
	end
	return {__index = get, __newindex = set}
end

--i/o ------------------------------------------------------------------------

--check if a file exists and can be opened for reading or writing.
function glue.canopen(name, mode)
	local f = io.open(name, mode or 'rb')
	if f then f:close() end
	return f ~= nil and name or nil
end

--read a file into a string (in binary mode by default).
function glue.readfile(name, mode, open)
	open = open or io.open
	local f, err = open(name, mode=='t' and 'r' or 'rb')
	if not f then return nil, err end
	local s, err = f:read'*a'
	if s == nil then return nil, err end
	f:close()
	return s
end

--read the output of a command into a string.
function glue.readpipe(cmd, mode, open)
	return glue.readfile(cmd, mode, open or io.popen)
end

--like os.rename() but behaves like POSIX on Windows too.
if jit then

	local ffi = require'ffi'

	if ffi.os == 'Windows' then

		ffi.cdef[[
			int MoveFileExA(
				const char *lpExistingFileName,
				const char *lpNewFileName,
				unsigned long dwFlags
			);
			int GetLastError(void);
		]]

		local MOVEFILE_REPLACE_EXISTING = 1
		local MOVEFILE_WRITE_THROUGH    = 8
		local ERROR_FILE_EXISTS         = 80
		local ERROR_ALREADY_EXISTS      = 183

		function glue.replacefile(oldfile, newfile)
			if ffi.C.MoveFileExA(oldfile, newfile, 0) ~= 0 then
				return true
			end
			local err = ffi.C.GetLastError()
			if err == ERROR_FILE_EXISTS or err == ERROR_ALREADY_EXISTS then
				if ffi.C.MoveFileExA(oldfile, newfile,
					bit.bor(MOVEFILE_WRITE_THROUGH, MOVEFILE_REPLACE_EXISTING)) ~= 0
				then
					return true
				end
				err = ffi.C.GetLastError()
			end
			return nil, 'WinAPI error '..err
		end

	else

		function glue.replacefile(oldfile, newfile)
			return os.rename(oldfile, newfile)
		end

	end

end

--write a string, number, table or the results of a read function to a file.
--uses binary mode by default.
function glue.writefile(filename, s, mode, tmpfile)
	if tmpfile then
		local ok, err = glue.writefile(tmpfile, s, mode)
		if not ok then
			return nil, err
		end
		local ok, err = glue.replacefile(tmpfile, filename)
		if not ok then
			os.remove(tmpfile)
			return nil, err
		else
			return true
		end
	end
	local f, err = io.open(filename, mode=='t' and 'w' or 'wb')
	if not f then
		return nil, err
	end
	local ok, err
	if type(s) == 'table' then
		for i = 1, #s do
			ok, err = f:write(s[i])
			if not ok then break end
		end
	elseif type(s) == 'function' then
		local read = s
		while true do
			ok, err = xpcall(read, debug.traceback)
			if not ok or err == nil then break end
			ok, err = f:write(err)
			if not ok then break end
		end
	else --string or number
		ok, err = f:write(s)
	end
	f:close()
	if not ok then
		os.remove(filename)
		return nil, err
	else
		return true
	end
end

--virtualize the print function.
function glue.printer(out, format)
	format = format or tostring
	return function(...)
		local n = select('#', ...)
		for i=1,n do
			out(format((select(i, ...))))
			if i < n then
				out'\t'
			end
		end
		out'\n'
	end
end

--dates & timestamps ---------------------------------------------------------

--compute timestamp diff. to UTC because os.time() has no option for UTC.
function glue.utc_diff(t)
   local d1 = os.date( '*t', 3600 * 24 * 10)
   local d2 = os.date('!*t', 3600 * 24 * 10)
	d1.isdst = false
	return os.difftime(os.time(d1), os.time(d2))
end

--overloading os.time to support UTC and get the date components as separate args.
function glue.time(utc, y, m, d, h, M, s, isdst)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, y, m, d, h, M, s, isdst = nil, utc, y, m, d, h, M, s
	end
	if type(y) == 'table' then
		local t = y
		if utc == nil then utc = t.utc end
		y, m, d, h, M, s, isdst = t.year, t.month, t.day, t.hour, t.min, t.sec, t.isdst
	end
	local utc_diff = utc and glue.utc_diff() or 0
	if not y then
		return os.time() + utc_diff
	else
		s = s or 0
		local t = os.time{year = y, month = m or 1, day = d or 1, hour = h or 0,
			min = M or 0, sec = s, isdst = isdst}
		return t and t + s - floor(s) + utc_diff
	end
end

--get the time at the start of the week of a given time, plus/minus a number of weeks.
function glue.sunday(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month, d.day - (d.wday - 1) + (offset or 0) * 7)
end

--get the time at the start of the day of a given time, plus/minus a number of days.
function glue.day(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month, d.day + (offset or 0))
end

--get the time at the start of the month of a given time, plus/minus a number of months.
function glue.month(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year, d.month + (offset or 0))
end

--get the time at the start of the year of a given time, plus/minus a number of years.
function glue.year(utc, t, offset)
	if type(utc) ~= 'boolean' then --shift arg#1
		utc, t, offset = false, utc, t
	end
	local d = os.date(utc and '!*t' or '*t', t)
	return glue.time(false, d.year + (offset or 0))
end

--error handling -------------------------------------------------------------

--allocation-free assert() with string formatting.
--NOTE: unlike standard assert(), this only returns the first argument
--to avoid returning the error message and it's args along with it so don't
--use it with functions returning multiple values when you want those values.
function glue.assert(v, err, ...)
	if v then return v end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then
		err = string.format(err, ...)
	end
	error(err, 2)
end

--pcall with traceback. LuaJIT and Lua 5.2 only.
local function pcall_error(e)
	return debug.traceback('\n'..tostring(e))
end
function glue.pcall(f, ...)
	return xpcall(f, pcall_error, ...)
end

local function unprotect(ok, result, ...)
	if not ok then return nil, result, ... end
	if result == nil then result = true end --to distinguish from error.
	return result, ...
end

--wrap a function that raises errors on failure into a function that follows
--the Lua convention of returning nil,err on failure.
function glue.protect(func)
	return function(...)
		return unprotect(pcall(func, ...))
	end
end

--pcall with finally and except "clauses":
--		local ret,err = fpcall(function(finally, except)
--			local foo = getfoo()
--			finally(function() foo:free() end)
--			except(function(err) io.stderr:write(err, '\n') end)
--		emd)
--NOTE: a bit bloated at 2 tables and 4 closures. Can we reduce the overhead?
local function fpcall(f,...)
	local fint, errt = {}, {}
	local function finally(f) fint[#fint+1] = f end
	local function onerror(f) errt[#errt+1] = f end
	local function err(e)
		for i=#errt,1,-1 do errt[i](e) end
		for i=#fint,1,-1 do fint[i]() end
		return tostring(e) .. '\n' .. debug.traceback()
	end
	local function pass(ok,...)
		if ok then
			for i=#fint,1,-1 do fint[i]() end
		end
		return ok,...
	end
	return pass(xpcall(f, err, finally, onerror, ...))
end

function glue.fpcall(...)
	return unprotect(fpcall(...))
end

--fcall is like fpcall() but without the protection (i.e. raises errors).
local function assert_fpcall(ok, ...)
	if not ok then error(..., 2) end
	return ...
end
function glue.fcall(...)
	return assert_fpcall(fpcall(...))
end

--modules --------------------------------------------------------------------

--create a module table that dynamically inherits another module.
--naming the module returns the same module table for the same name.
function glue.module(name, parent)
	if type(name) ~= 'string' then
		name, parent = parent, name
	end
	if type(parent) == 'string' then
		parent = require(parent)
	end
	parent = parent or _M
	local parent_P = parent and assert(parent._P, 'parent module has no _P') or _G
	local M = package.loaded[name]
	if M then
		return M, M._P
	end
	local P = {__index = parent_P}
	M = {__index = parent, _P = P}
	P._M = M
	M._M = M
	P._P = P
	setmetatable(P, P)
	setmetatable(M, M)
	if name then
		package.loaded[name] = M
		P[name] = M
	end
	setfenv(2, P)
	return M, P
end

--setup a module to load sub-modules when accessing specific keys.
function glue.autoload(t, k, v)
	local mt = getmetatable(t) or {}
	if not mt.__autoload then
		local old_index = mt.__index
	 	local submodules = {}
		mt.__autoload = submodules
		mt.__index = function(t, k)
			--overriding __index...
			if type(old_index) == 'function' then
				local v = old_index(t, k)
				if v ~= nil then return v end
			elseif type(old_index) == 'table' then
				local v = old_index[k]
				if v ~= nil then return v end
			end
			if submodules[k] then
				local mod
				if type(submodules[k]) == 'string' then
					mod = require(submodules[k]) --module
				else
					mod = submodules[k](k) --custom loader
				end
				submodules[k] = nil --prevent loading twice
				if type(mod) == 'table' then --submodule returned its module table
					assert(mod[k] ~= nil) --submodule has our symbol
					t[k] = mod[k]
				end
				return rawget(t, k)
			end
		end
		setmetatable(t, mt)
	end
	if type(k) == 'table' then
		glue.update(mt.__autoload, k) --multiple key -> module associations.
	else
		mt.__autoload[k] = v --single key -> module association.
	end
	return t
end

--portable way to get script's directory, based on arg[0].
--NOTE: the path is not absolute, but relative to the current directory!
--NOTE: for bundled executables, this returns the executable's directory.
local dir = rawget(_G, 'arg') and arg[0]
	and arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
glue.bin = dir == '' and '.' or dir

--portable way to add more paths to package.path, at any place in the list.
--negative indices count from the end of the list like string.sub().
--index 'after' means 0.
function glue.luapath(path, index, ext)
	ext = ext or 'lua'
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local paths = glue.collect(glue.gsplit(package.path, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. psep .. 'init.' .. ext)
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.path = table.concat(paths, tsep)
end

--portable way to add more paths to package.cpath, at any place in the list.
--negative indices count from the end of the list like string.sub().
--index 'after' means 0.
function glue.cpath(path, index)
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local ext = package.cpath:match('%.([%a]+)%'..tsep..'?') --dll | so | dylib
	local paths = glue.collect(glue.gsplit(package.cpath, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.cpath = table.concat(paths, tsep)
end

--allocation -----------------------------------------------------------------

--freelist for Lua tables.
local function create_table()
	return {}
end
function glue.freelist(create, destroy)
	create = create or create_table
	destroy = destroy or glue.noop
	local t = {}
	local n = 0
	local function alloc()
		local e = t[n]
		if e then
			t[n] = false
			n = n - 1
		end
		return e or create()
	end
	local function free(e)
		destroy(e)
		n = n + 1
		t[n] = e
	end
	return alloc, free
end

--ffi ------------------------------------------------------------------------

if jit then

local ffi = require'ffi'

--static, auto-growing buffer allocation pattern (ctype must be vla).
function glue.buffer(ctype)
	local vla = ffi.typeof(ctype)
	local buf, len = nil, -1
	return function(minlen)
		if minlen == false then
			buf, len = nil, -1
		elseif minlen > len then
			len = glue.nextpow2(minlen)
			buf = vla(len)
		end
		return buf, len
	end
end

--like glue.buffer() but preserves data on reallocations
--also returns minlen instead of capacity.
function glue.dynarray(ctype)
	local buffer = glue.buffer(ctype)
	local elem_size = ffi.sizeof(ctype, 1)
	local buf0, minlen0
	return function(minlen)
		local buf, len = buffer(minlen)
		if buf ~= buf0 and buf ~= nil and buf0 ~= nil then
			ffi.copy(buf, buf0, minlen0 * elem_size)
		end
		buf0, minlen0 = buf, minlen
		return buf, minlen
	end
end

local intptr_ct = ffi.typeof'intptr_t'
local intptrptr_ct = ffi.typeof'const intptr_t*'
local intptr1_ct = ffi.typeof'intptr_t[1]'
local voidptr_ct = ffi.typeof'void*'

--x86: convert a pointer's address to a Lua number.
local function addr32(p)
	return tonumber(ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p)))
end

--x86: convert a number to a pointer, optionally specifying a ctype.
local function ptr32(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	return ffi.cast(ctype, addr)
end

--x64: convert a pointer's address to a Lua number or possibly string.
local function addr64(p)
	local np = ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p))
   local n = tonumber(np)
	if ffi.cast(intptr_ct, n) ~= np then
		--address too big (ASLR? tagged pointers?): convert to string.
		return ffi.string(intptr1_ct(np), 8)
	end
	return n
end

--x64: convert a number or string to a pointer, optionally specifying a ctype.
local function ptr64(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	if type(addr) == 'string' then
		return ffi.cast(ctype, ffi.cast(voidptr_ct,
			ffi.cast(intptrptr_ct, addr)[0]))
	else
		return ffi.cast(ctype, addr)
	end
end

glue.addr = ffi.abi'64bit' and addr64 or addr32
glue.ptr = ffi.abi'64bit' and ptr64 or ptr32

end --if jit

if bit then

	local band, bor, bnot = bit.band, bit.bor, bit.bnot

	--extract the bool value of a bitmask from a value.
	function glue.getbit(from, mask)
		return band(from, mask) == mask
	end

	--set a single bit of a value without affecting other bits.
	function glue.setbit(over, mask, yes)
		return bor(yes and mask or 0, band(over, bnot(mask)))
	end

	local function bor_bit(bits, k, mask, strict)
		local b = bits[k]
		if b then
			return bit.bor(mask, b)
		elseif strict then
			error(string.format('invalid bit %s', k))
		else
			return mask
		end
	end
	function glue.bor(flags, bits, strict)
		local mask = 0
		if type(flags) == 'number' then
			return flags --passthrough
		elseif type(flags) == 'string' then
			for k in flags:gmatch'[^%s]+' do
				mask = bor_bit(bits, k, mask, strict)
			end
		elseif type(flags) == 'table' then
			for k,v in pairs(flags) do
				k = type(k) == 'number' and v or k
				mask = bor_bit(bits, k, mask, strict)
			end
		else
			error'flags expected'
		end
		return mask
	end

end

return glue
