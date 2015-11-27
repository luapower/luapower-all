local curl = require'libcurl'
local ffi = require'ffi'

print(curl.version())

local info = curl.version_info()
for k,v in pairs(info) do
	if type(v) == 'table' then v = '{'..table.concat(v, ', ')..'}' end
	print(string.format('%-20s %s', k, v))
end


local easy = curl.easy{
	url = 'http://google.com/',
	verbose = true,
	noprogress = false,
	xferinfofunction = function(self, _, ...)
		print(...)
		return 0
	end,
}

easy:perform()

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

local url = ':/?+&='
local eurl = easy:escape(url)
local uurl = easy:unescape(eurl)
assert(url == uurl)
print(url, eurl)

easy:free()
