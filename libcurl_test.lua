local curl = require'libcurl'
local ffi = require'ffi'

--add tests to the test table in order
local function add(test, name, func)
	rawset(test, #test + 1, name)
	rawset(test, name, func)
end
local test = setmetatable({}, {__newindex = add})

--[[
--TODO: load the default openssl file so it get get the path of the CA root file.
local crypto = require'libcrypto'
require'libcrypto_conf_h'
assert(crypto.CONF_modules_load_file('/etc/ssl/openssl.cnf',
	nil, crypto.CONF_MFLAGS_DEFAULT_SECTION) == 1)
]]

function test.version()
	print(curl.version())
end

local function list(v)
	local t = {'{'}
	for k,v in pairs(v) do
		if v then
			t[#t+1] = k..','
		end
	end
	t[#t+1] = '}'
	return table.concat(t)
end

function test.version_info()
	local info = curl.version_info()
	for k,v in pairs(info) do
		if k == 'protocols' or k == 'features' then
			v = list(v)
		end
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

function test.mime()
	local e = curl.easy{
		url = 'http://speedtest.tele2.net/upload.php',
	}
	local m = e:mime()
	local p = m:part()
	p:headers{'Some-Header: foo', 'Other-Header: bar'}
	p:file[[x:\openresty\openssl-1.1.1d.tar.gz]]
	assert(e:perform())
	e:close()
	print'\nDone'
end

--run all tests in order

test.mime()
os.exit()

for i,name in ipairs(test) do
	print(name .. ' ' .. ('-'):rep(78 - #name))
	test[name]()
end
