local curl = require'libcurl'
local ffi = require'ffi'

--add tests to the test table in order
local function add(test, name, func)
	rawset(test, #test + 1, name)
	rawset(test, name, func)
end
local test = setmetatable({}, {__newindex = add})


function test.version()
	print(curl.version())
end

function test.version_info()
	local info = curl.version_info()
	for k,v in pairs(info) do
		if type(v) == 'table' then v = '{'..table.concat(v, ', ')..'}' end
		print(string.format('%-20s %s', k, v))
	end
	print('async?', bit.band(info.features, curl.C.CURL_VERSION_ASYNCHDNS) ~= 0)
end

function make_easy()
	return curl.easy{
		url = 'http://google.com/',
		verbose = false,
		noprogress = true,
		xferinfofunction = function(self, ...)
			print(...)
			return 0
		end,
	}
end

function dump_info(easy)
	for _,k in ipairs{
		'effective_url',
		'response_code',
		'total_time',
		'namelookup_time',
		'connect_time',
		'pretransfer_time',
		'size_upload',
		'size_download',
		'speed_download',
		'speed_upload',
		'header_size',
		'request_size',
		'ssl_verifyresult',
		'filetime',
		'content_length_download',
		'content_length_upload',
		'starttransfer_time',
		'content_type',
		'redirect_time',
		'redirect_count',
		'private',
		'http_connectcode',
		'httpauth_avail',
		'proxyauth_avail',
		'os_errno',
		'num_connects',
		'ssl_engines',
		'cookielist',
		'lastsocket',
		'ftp_entry_path',
		'redirect_url',
		'primary_ip',
		'appconnect_time',
		'certinfo',
		'condition_unmet',
		'rtsp_session_id',
		'rtsp_client_cseq',
		'rtsp_server_cseq',
		'rtsp_cseq_recv',
		'primary_port',
		'local_ip',
		'local_port',
		'tls_session',
		'activesocket',
	} do
		local v = easy:info(k)
		if type(v) == 'table' then
			v = '{'..table.concat(v, ', ')..'}'
		elseif ffi.istype('struct curl_tlssessioninfo*', v) then
			v = 'backend: '..tonumber(v.backend)..'; internals: '..tostring(v.internals)
		end
		print(string.format('%-20s %s', k, v))
	end
end

function test.easy()
	local easy = make_easy()
	easy:perform()
	dump_info(easy)
	easy:close()
end

function test.escape()
	local easy = make_easy()
	local url = ':/?+&='
	local eurl = easy:escape(url)
	local uurl = easy:unescape(eurl)
	assert(url == uurl)
	print(url, eurl)
	easy:close()
end

function test.clone()
	local e = make_easy()
	e:clone():perform():close()
	e:close()
end

function test.multi()
	local m = curl.multi()
	local e0 = make_easy()
	local t = {}
	for i = 1, 10 do
		local e = e0:clone()
		t[i] = e
		m:add(e)
	end
	e0:close()
	local n0
	while true do
		local n = m:perform()
		if n == 0 then break end
		if n0 ~= n then
			print(n)
			n0 = n
		end
	end
	m:close()
	for i = 1, #t do
		t[i]:close()
	end
end

function test.share()
	local sh = curl.share{unshare = 'cookie', userdata = 123}
	sh:set('share', 'dns')
	sh:free()
end

function test.remove_cb()
	local e = make_easy()
	e:set('xferinfofunction', nil)
	e:close()
end

function test.download()
	local time = require'time'
	local sh = curl.share()
	for i = 1, 1 do
		local t0 = time.time()
		local t = {sz = 0}
		local url = 'https://github.com/luapower/glue/archive/master.zip'
		local total_size = 17954
		local e = assert(curl.easy{
			url = url,
			share = sh,
			accept_encoding = '',
			--verbose = true,
			dns_use_global_cache = true,
			dns_cache_timeout = 999999,
			followlocation = true,
			writefunction = function(data, size)
				if size == 0 then return end
				table.insert(t, ffi.string(data, size))
				t.sz = t.sz + size
				local time_sofar = time.time() - t0
				print(string.format('%2d%% %3dKB from %3dKB (%.2f KB/s)',
					t.sz / total_size * 100,
					t.sz / 1024,
					total_size / 1024,
					t.sz / 1024 / time_sofar))
				return size
			end,
		})
		assert(e:perform())
		local s = table.concat(t)
		local dt = time.time() - t0
		print('DONE: ', #s, 'bytes')
		e:close()
	end
	sh:free()
end

function test.form()
	local form = curl.form()
	form:add('ptrname', 'name1', 'ptrcontents', 'yy')
	form:add('ptrname', 'name2', 'file', 'luajit', 'file', 'luajit.cmd')
	form:add('ptrname', 'name3', 'bufferptr', '@@@@@@@@@@@@@', 'contenttype', 'text/plain')
	form:add('array', {'ptrname', 'name4', 'bufferptr', 'aa', 'contentheader', {'H1: V1', 'H2: V2'}})

	print('>>> form get as string')
	local s = form:get()
	print(s)
	print('>>> form get as chunks')
	for i,s in ipairs(form:get{}) do
		print(i, s)
	end
	print('>>> form get to callback')
	form:get(function(buf, len)
		print(len, ffi.string(buf, len))
	end)
end

--run all tests in order

for i,name in ipairs(test) do
	print(name .. ' ' .. ('-'):rep(78 - #name))
	test[name]()
end
