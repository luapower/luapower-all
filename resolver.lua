
-- DNS resolver in Lua.
-- Written by Cosmin Apreutesei. Public Domain.
-- Original code by Yichun Zhang (agentzh). BSD License.

local ffi      = require'ffi'
local bit      = require'bit'
local clock    = require'time'.clock
local time     = require'time'.time
local errors   = require'errors'
local glue     = require'glue'
local lrucache = require'lrucache'

local band = bit.band
local shr = bit.rshift
local shl = bit.lshift
local char = string.char
local format = string.format
local add = table.insert
local concat = table.concat

--error handling -------------------------------------------------------------

local check_io, checkp, _, protect = errors.tcp_protocol_errors'dns'

local function check_len(q, i, n, len)
	return checkp(q, n >= i+len, 'response too short')
end

--build request --------------------------------------------------------------

local qtypes = {
	A      =  1,
	NS     =  2,
	CNAME  =  5,
	SOA    =  6,
	PTR    = 12,
	MX     = 15,
	TXT    = 16,
	AAAA   = 28,
	SRV    = 33,
	SPF    = 99,
}

local function name_str(q)
	local function label_str(s)
		checkp(q, #s <= 63, 'name part too long')
		return char(#s)..s
	end
	return q.name:gsub('([^.]+)%.?', label_str)..'\0'
end

local function u16_str(x)
	return char(shr(x, 8), band(x, 0xff))
end

local function query_str(q) --query: name qtype(2) class(2)
	checkp(q, q.name:sub(1, 1) ~= '.', 'name starts with a dot')
	local qtype = qtypes[q.type] or tonumber(q.type)
	return name_str(q)..u16_str(qtype)..'\0\1'
end

--NOTE: most DNS servers do not support multiple queries because it makes
--them vulnerable to amplification attacks, so we don't implement them either.
--NOTE: queries with a single name cannot be > 512 bytes, the UDP sending limit.
local function request_str(q)
	checkp(q, #q.name <= 253, 'name too long')
	local flags = q.recurse and '\1\0' or '\0\0'
	--request: id(2) flags(2) query_num(2) zero(2) zero(2) zero(2) query
	return u16_str(q.id)..flags..'\0\1\0\0\0\0\0\0'..query_str(q)
end

--parse response -------------------------------------------------------------

local function ip4(q, p, i, n) --ipv4 in binary
	check_len(q, i, n, 4)
	return format('%d.%d.%d.%d', p[i], p[i+1], p[i+2], p[i+3]), i+4
end

local function ip6(q, p, i, n) --ipv6 in binary
	check_len(q, i, n, 16)
	local t = {}
	for i = 0, 15, 2 do
		local a, b = p[i], p[i+1]
		if a == 0 then
			add(t, format('%x', b))
		else
			add(t, format('%x%02x', a, b))
		end
	end
	return concat(t, ':'), i+16
end

local function u16(q, p, i, n) --u16 in big-endian
	check_len(q, i, n, 2)
	return shl(p[i], 8) + p[i+1], i+2
end

local function u32(q, p, i, n) --u32 in big-endian
	check_len(q, i, n, 4)
	return shl(p[i], 24) + shl(p[i+1], 16) + shl(p[i+2], 8) + p[i+3], i+4
end

local function label(q, p, i, n, maxlen) --string: len(1) text
	check_len(q, i, n, 1)
	local len = p[i]; i=i+1
	checkp(q, len > 0 and len <= maxlen, 'response too short')
	check_len(q, i, n, len)
	return ffi.string(p+i, len), i+len
end

local function name(q, p, i, n) --name: label1... end|pointer
	local labels = {}
	while true do
		check_len(q, i, n, 1)
		local len = p[i]; i=i+1
		if len == 0 then --end: len(1) = 0
			break
		elseif band(len, 0xc0) ~= 0 then --pointer: offset(2) with b1100-0000-0000-0000 mask
			check_len(q, i, n, 1)
			local name_i = shl(band(len, 0x3f), 8) + p[i]; i=i+1
			local suffix = name(q, p, name_i, n)
			add(labels, suffix)
			break
		else --label: len(1) text
			local s; s, i = label(q, p, i-1, n, 63)
			add(labels, s)
		end
	end
	local s = concat(labels, '.')
	checkp(q, #s <= 253, 'name too long')
	return s, i
end

local qtype_names = glue.index(qtypes)

local function parse_answer(q, ans, p, i, n)
	ans.name  , i = name(q, p, i, n)
	local typ , i = u16(q, p, i, n)
	ans.class , i = u16(q, p, i, n)
	ans.ttl   , i = u32(q, p, i, n)
	local len , i = u16(q, p, i, n)
	typ = qtype_names[typ]
	ans.type = typ
	check_len(q, i, n, len)
	n = i+len
	if typ == 'A' then
		ans.a, i = ip4(q, p, i, n)
	elseif typ == 'CNAME' then
		ans.cname, i = name(q, p, i, n)
	elseif typ == 'AAAA' then
		ans.aaaa, i = ip6(q, p, i, n)
	elseif typ == 'MX' then
		ans.mx_priority , i =  u16(q, p, i, n)
		ans.mx          , i = name(q, p, i, n)
	elseif typ == 'SRV' then
		ans.srv_priority , i =  u16(q, p, i, n)
		ans.srv_weight   , i =  u16(q, p, i, n)
		ans.srv_port     , i = ua16(q, p, i, n)
		ans.srv_target   , i = name(q, p, i, n)
	elseif typ == 'NS' then
		ans.ns, i = name(q, p, i, n)
	elseif typ == 'TXT' or typ == 'SPF' then
		local key = typ == 'TXT' and 'txt' or 'spf'
		local s; s, i = label(q, p, i, n, 255)
		if i < n then --more string fragments
			local t = {s}
			repeat
				local s; s, i = label(q, p, i, n, 255)
				add(t, s)
			until i == n
			s = concat(t)
		end
		ans[key] = s
	elseif typ == 'PTR' then
		ans.ptr, i = name(q, p, i, n)
	elseif typ == 'SOA' then
		ans.soa_mname     , i = name(q, p, i, n)
		ans.soa_rname     , i = name(q, p, i, n)
		ans.soa_serial    , i =  u32(q, p, i, n)
		ans.soa_refresh   , i =  u32(q, p, i, n)
		ans.soa_retry     , i =  u32(q, p, i, n)
		ans.soa_expire    , i =  u32(q, p, i, n)
		ans.soa_minimum   , i =  u32(q, p, i, n)
	else --unknown type, return the raw value
		ans.rdata, i = ffi.string(p+i, n-i), n
	end
	return i
end

local function parse_section(q, answers, section, p, i, n, entries, should_skip)
	for _ = 1, entries do
		local ans = {section = section}
		if not should_skip then
			add(answers, ans)
		end
		i = parse_answer(q, ans, p, i, n)
	end
	return i
end

local resolver_err_strs = {
	'format error',     -- 1
	'server failure',   -- 2
	'name error',       -- 3
	'not implemented',  -- 4
	'refused',          -- 5
}

local function parse_qid(q, p, n)
	return u16(q, p, 0, n)
end

local function parse_response(q, p, n)

	-- header layout: qid(2) flags(2) n1(2) n2(2) n3(2) n4(2)
	local qid   , i = u16(q, p, 0, n)
	local flags , i = u16(q, p, i, n)
	local n1    , i = u16(q, p, i, n) --number of questions
	local n2    , i = u16(q, p, i, n) --number of answers
	local n3    , i = u16(q, p, i, n) --number of authority entries
	local n4    , i = u16(q, p, i, n) --number of additional entries

	if band(flags, 0x200) ~= 0 then
		return nil, 'truncated'
	end
	checkp(q, band(flags, 0x8000) ~= 0, 'bad QR flag')

	--skip question section: (qname qtype(2) qclass(2)) ...
	for _ = 1, n1 do
		local qname; qname, i = name(q, p, i, n)
		local qtype; qtype, i = u16(q, p, i, n)
		local class; class, i = u16(q, p, i, n)
		checkp(q, qname == q.name         , 'response name mismatch')
		checkp(q, qtype == qtypes[q.type] , 'response type mismatch')
		checkp(q, class == 1              , 'response class not 1')
	end

	local answers = {}

	local code = band(flags, 0xf)
	checkp(q, code == 0, resolver_err_strs[code] or 'unknown [%d]', code)

	local additional_section = q.additional_section
	local authority_section = q.type == 'SOA' or q.authority_section

	i = parse_section(q, answers, 'answer', p, i, n, n2)
	if authority_section or additional_section then
		i = parse_section(q, answers, 'authority', p, i, n, n3, not authority_section)
		if additional_section then
			i = parse_section(q, answers, 'additional', p, i, n, n4)
		end
	end

	return answers
end

--resolver -------------------------------------------------------------------

--[[

The problem: DNS uses UDP but we want to be able to resolve multiple names
concurrently from different coroutines, so we need to account for the fact
that responses may come out-of-order, some may not come at all, and some may
come way later than the timeout of the query which we must always respect.

The solution: when calling the resolver's lookup function from a sock thread,
a query object is created, sent to the server and queued for response.
Then the calling thread suspends itself. A scheduler that runs in its own
thread reads responses as they come, matches queries in the queue based on
id and resumes their corresponding threads with the answers. If/when
the queue gets empty, the scheduler suspends itself, waiting to be resumed
again when the first new request arrives.

Timed out queries are not dequeued right away to avoid reusing an id for a
query for which an answer might still come later.

If there's more than one server configured, the lookup function queries all
servers simultaneously in separate threads and suspends itself. The first
thread to receive a response wakes up the lookup thread which finishes up
with that response. Later responses are discarded. This results in the best
lookup times and impact-free (for the client) failovers.

TIP: When coding complex flows with coroutines, the question to ask before
suspending any thread is: "who is now responsible for resuming this thread?".
In the classic one-connection-per-thread scheme the answer is simple: it's
always the I/O scheduler. With more complex schemes the answer is up to you.

]]

local rs = {} --resolver class

rs.libs = 'sock'
rs.max_cache_entries = 1e5

function rs:_dbg(ns, q, ...)
	print(
		'resolver.lua:'..debug.getinfo(3).currentline..':',
		require'coro'.name(),
		ns and glue.count(ns.queue) or '',
		q and q.name:sub(1, 7) or '',
		q and q.i or '',
		...)
end

function rs:dbg(ns, q, ...)
	self:_dbg(ns, q, ...)
end

function rs:dbgr(ns, q, t, ...)
	self:_dbg(ns, q, '=>', require'coro'.name(t), ...)
end

function rs:dbgt(ns, q, ...)
	self:_dbg(ns, q, '->', require'coro'.name(q.thread), ...)
end

function rs:dbgs(ns, q, ...)
	self:_dbg(ns, q, '.', ...)
end

local q = {} --query class

q.timeout = 5
q.recurse = true
q.authority_section = false
q.additional_section = false
q.tracebacks = false
q.tcp_only = false

--NOTE: DNS servers don't support request pipelining so we use one-shot sockets.
local function tcp_query(rs, ns, q)

	rs:dbg(ns, q, 'TCP_QUERY')

	local tcp = check_io(q, rs.tcp())
	q.tcp = tcp --pin it so that it's closed automatically on error.

	local expires = q.expires

	check_io(q, tcp:connect(ns.ai, nil, expires))
	check_io(q, tcp:send(u16_str(#q.s) .. q.s, nil, expires))

	local len_buf = ffi.new'uint8_t[2]'
	check_io(q, tcp:recvn(len_buf, 2, expires))
	local len = u16(q, len_buf, 0, 2)
	checkp(q, len <= 4096, 'response too long')

	local buf = ffi.new('uint8_t[?]', len)
	check_io(q, tcp:recvn(buf, len, expires))

	tcp:close(0)
	q.tcp = nil

	return parse_response(q, buf, len)
end

local function gen_qid(rs, ns, now)
	for i = 1, 10 do --expect a 50% chance of collision at around 362 qids.
		local qid = math.random(0, 65535)
		local q = ns.queue[qid]
		if not q then
			return qid
		elseif q.lost and now > q.expires + 120 then --safe to reuse this id.
			rs:dbg(ns, q, 'REUSE')
			ns.queue[qid] = nil
			return qid
		end
	end
	return nil, 'busy' --queue clogged with live ids.
end

local qi = 0

local function ns_query(rs, ns, q)

	assert(q.timeout >= 0.1)

	--generate a request with a random id.
	local now = rs.clock()
	q.expires = now + q.timeout
	q.id = check_io(q, gen_qid(rs, ns, now))
	qi = qi + 1
	q.i = qi
	q.s = request_str(q)

	if q.tcp_only or ns.tcp_only or rs.tcp_only then
		return tcp_query(rs, ns, q)
	end

	--queue the query for response before sending it because the scheduler
	--might recv() our response even before our send() returns!
	ns.queue[q.id] = q

	--send the request. being resume()'d, this thread will now suspend
	--itself inside send(), returning control to the calling thread.
	--the I/O scheduler will resume this thread next when send() completes.
	rs:dbg(ns, q, 'SEND.')
	check_io(q, ns.udp:send(q.s, nil, q.expires))
	rs:dbg(ns, q, 'SENT')

	--start the scheduler or suspend. the scheduler will resume() us back
	--on the matching recv() or on timeout.
	q.thread = rs.currentthread()
	local buf, len, errcode
	if not ns.scheduler_running then
		rs:dbgr(ns, q, ns.scheduler)
		buf, len, errcode = check_io(q, rs.transfer(ns.scheduler))
	elseif q.result then
		rs:dbg(ns, q, 'EARLY', len)
		buf, len, errcode = check_io(q, glue.unpack(q.result))
	else
		rs:dbgs(ns, q)
		buf, len, errcode = check_io(q, rs.suspend())
	end

	local answers, err, errcode = parse_response(q, buf, len)

	if not answers and err == 'truncated' then
		answers, err, errcode = tcp_query(rs, ns, q)
	end

	return answers, err, errcode
end
local ns_query = protect(ns_query)

local function schedule(rs, ns)
	local sz = 4096
	local buf = ffi.new('uint8_t[?]', sz)
	local function respond(q, ...)
		if q.thread then
			rs.resume(q.thread, ...)
		else
			q.result = glue.pack(...)
		end
	end
	while true do
		ns.scheduler_running = true
		while true do
			local min_expires
			local now = rs.clock()
			for qid, q in pairs(ns.queue) do
				if not q.lost then
					if now < q.expires then
						min_expires = math.min(min_expires or 1/0, q.expires)
					else
						q.lost = true
						rs:dbgt(ns, q, 'TIMEOUT')
						respond(q, nil, 'timeut')
					end
				elseif now > q.expires + 120 then --safe to reuse this id.
					rs:dbg(ns, q, 'REUSE')
					ns.queue[qid] = nil
				end
			end
			rs:dbg(ns, nil, 'RECV.',
				rs.debug and min_expires and string.format('%.2f', min_expires - now)
					or 'ALL EXPIRED')
			if not min_expires then
				break
			end
			local len, err, errcode = ns.udp:recv(buf, sz, min_expires)
			rs:dbg(ns, nil, 'RECV', len, err or '', errcode or '')
			if not len then
				for qid, q in pairs(ns.queue) do
					if not q.lost then
						q.lost = true
						rs:dbgt(ns, q, 'ERROR', err, errcode)
						respond(q, nil, err, errcode)
					end
				end
			else
				local qid = parse_qid(glue.empty, buf, len)
				local q = ns.queue[qid]
				if q then
					if rs.clock() < q.expires then
						ns.queue[qid] = nil
						rs:dbgt(ns, q, 'DATA', len)
						respond(q, buf, len)
					else
						q.lost = true
						rs:dbgt(ns, q, 'TIMEOUT')
						respond(q, nil, 'timeout')
					end
				else
					rs:dbg(ns, nil, '???', qid)
				end
			end
		end
		ns.scheduler_running = false
		rs:dbgs()
		rs.suspend()
	end
end

local function bind_libs(self, libs)
	for lib in libs:gmatch'[^%s]+' do
		if lib == 'sock' then
			local sock = require'sock'
			self.tcp = sock.tcp
			self.udp = sock.udp
			self.addr = sock.addr
			--scheduling
			self.newthread = sock.newthread
			self.suspend = sock.suspend
			self.resume = sock.resume
			self.thread = sock.thread
			self.transfer = sock.transfer
			self.currentthread = sock.currentthread
			self.start = sock.start
			self.clock = sock.clock
		else
			assert(false)
		end
	end
end

local function create_resolver(opt)
	local rs = glue.update({}, rs, opt)

	if not rs.debug then
		rs.dbg  = glue.noop
		rs.dbgt = glue.noop
		rs.dbgs = glue.noop
		rs.dbgr = glue.noop
	end

	if rs.libs then
		bind_libs(rs, rs.libs)
	end

	local servers = type(rs.servers) == 'string'
		and glue.collect(rs.servers:gmatch'[^%s]+') or rs.servers

	rs.nst = {}
	for i,ns in ipairs(rs.servers) do
		local host, port, tcp_only
		if type(ns) == 'table' then
			host = ns.host or ns[1]
			port = ns.port or ns[2] or 53
			tcp_only = ns.tcp_only
		else
			host, port = ns, 53
		end
		local ai = assert(rs.addr(host, port))
		local udp = assert(rs.udp())
		assert(udp:connect(ai))
		local ns = {ai = ai, udp = udp, tcp_only = tcp_only, queue = {}}
		ns.scheduler = rs.newthread(function()
			schedule(rs, ns)
		end, 'N'..i)
		rs.nst[i] = ns
		ns.i = i
		rs:dbg(ns, nil, 'NS', rs.debug and ai:tostring())
	end

	rs.cache = lrucache{max_size = rs.max_cache_entries}

	return rs
end
rs.new = create_resolver

local function rs_query(rs, qname, qtype, timeout)
	local t = type(qname) == 'table' and qname or nil
	if t then
		qname, qtype, timeout = t.name, t.type, t.timeout
	end
	qtype = qtype or 'A'
	rs:dbg(nil, {name = qname}, 'LOOKUP')
	local key = qtype..' '..qname
	local res = rs.cache:get(key)
	if res and time() > res.expires then
		rs.cache:remove_val(res)
		res = nil
	end
	if res then
		return res
	end
	local lookup_thread = rs.currentthread()
	local queries_left = #rs.nst
	for i,ns in ipairs(rs.nst) do
		rs.resume(rs.newthread(function()
			local t = glue.update({name = qname, type = qtype, timeout = timeout}, t)
			local q = glue.object(q, t)
			local res, err, errcode = ns_query(rs, ns, q) --suspends inside the first send().
			queries_left = queries_left - 1
			if not lookup_thread then
				rs:dbg(ns, q, 'DISCARD (late)')
				return
			end
			if not res and errors.is(err, 'tcp') and queries_left > 0 then
				rs:dbg(ns, q, 'DISCARD (socket error and not last)')
				return
			end
			local lt = lookup_thread
			lookup_thread = nil
			if not res then
				rs:dbgr(ns, q, lt, nil, err, errcode)
				rs.resume(lt, nil, err, errcode)
			else
				local min_ttl = 1/0
				for _,answer in ipairs(res) do
					min_ttl = math.min(min_ttl, answer.ttl)
				end
				res.expires = time() + min_ttl
				rs.cache:put(key, res)
				rs:dbgr(ns, q, lt, '{...}')
				rs.resume(lt, res)
			end
		end, rs.debug and 'N'..i..'-'..require'coro'.name()))
	end
	rs:dbgs()
	return rs.suspend() -- the first thread to finish will resume us.
end
rs.query = protect(rs_query)

local function hex4(s)
	return ('%04x'):format(tonumber(s, 16))
end
local function arpa_str(s)
	if s:find(':', 1, true) then --ipv6
		local _, n = s:gsub('[^:]+', hex4) --add leading zeroes and count blocks
		if n < 8 then --decompress
			local i = s:find('::', 1, true)
			if i == 1 then
				s = s:gsub('^::',      ('0000:'):rep(8 - n), 1)
			elseif i == #s-1 then
				s = s:gsub('::$',      (':0000'):rep(8 - n), 1)
			else
				s = s:gsub('::' , ':'..('0000:'):rep(8 - n), 1)
			end
		end
		return (s:gsub(':', ''):reverse():gsub('.', '%0.')..'ip6.arpa')
	else
		return (s:gsub('^(%d+)%.(%d+)%.(%d+)%.(%d+)$', '%4.%3.%2.%1.in-addr.arpa'))
	end
end

local function filter_answers(type, key, ret, ...)
	if not ret then return ret, ... end
	local t = {}
	for i,ans in ipairs(ret) do
		if ans.type == type then
			table.insert(t, ans[key])
		end
	end
	return t
end

function rs:lookup(name, type, timeout)
	type = type or 'A'
	return filter_answers(type, type:lower(), self:query(name, type, timeout))
end

function rs:reverse_lookup(addr, timeout)
	local s = arpa_str(addr)
	if not s then return nil, 'invalid address' end
	return filter_answers('PTR', 'ptr', self:query(s, 'PTR', timeout))
end

--self-test ------------------------------------------------------------------

if not ... then

	math.randomseed(clock())

	local r = assert(rs.new{
		servers = {
			'127.0.0.1',
			'10.0.0.1',
			'10.0.0.10',
			'1.1.1.1',
			--'8.8.8.8',
			--{host = '8.8.4.4', port = 53},
		},
		--tcp_only = true,
		--debug = true,
	})

	local function lookup(q)

		local s = type(q) == 'string' and q or pp.format(q)

		local answers, err = r:query(q)

		if not answers then
			print(format('%s: %s', s, err))
		else
			for i, ans in ipairs(answers) do

				print(format('%-16s %-16s type: %s  ttl: %3d',
					ans.name,
					ans.a or ans.cname,
					ans.type,
					ans.ttl))

				if ans.a then
					local names, err = r:reverse_lookup(ans.a)
					if not names then
						print('', format('%s: %s', s, err))
					else
						for i,name in ipairs(names) do
							print('', ans.a, name)
						end
					end
				end
			end
		end
	end

	for i,s in ipairs{
		--{name = 'luapower.com', tcp_only = false, timeout = 1},
		{name = 'catcostaocasa.ro', timeout = 1},
		{name = 'www.yahoo.com', timeout = 1},
 		'www.openresty.org',
		'www.lua.org',
	} do
		r.resume(r.newthread(lookup, 'L'..i), s)
	end

	r.start()
end


return rs
