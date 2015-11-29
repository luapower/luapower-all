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
	local easy = make_easy()
	easy:clone():perform():close()
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

--run all tests in order

for i,name in ipairs(test) do
	print(name .. ' ' .. ('-'):rep(78 - #name))
	test[name]()
end
