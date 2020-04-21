
local headers = require'http_headers'

local function dump(s)
	for s in s:gmatch'(.-)\r?\n' do
		local k, v = s:match'(.-)%s*:(.*)'
	end
end

dump[[
Accept: text/plain; q=0.5, text/html,
				text/x-dvi; q=0.8, text/x-c
Accept-Charset: utf-8
Accept-Encoding: gzip, deflate
Accept-Language: en-US
Accept-Datetime: Thu, 31 May 2007 20:35:00 GMT
Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
Cache-Control: no-cache
Cache-control: max-age=15
Connection: keep-alive, close
Cookie: $Version=1; Skin=new;
Content-Length: 348
Content-MD5: Q2hlY2sgSW50ZWdyaXR5IQ==
content-type: text/plain; Charset=ISO-8859_1
Date: Tue, 15 Nov 1994 08:12:31 GMT
Expect: 100-continue
From: user@example.com
Host: en.wikipedia.org:80
If-Match: "737060cd8c284d8af7ad3082f209582d"
If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT
If-None-Match: "737060cd8c284d8af7ad3082f209582d"
If-Range: "737060cd8c284d8af7ad3082f209582d"
If-Unmodified-Since: Sat, 29 Oct 1994 19:43:31 GMT
Max-Forwards: 10
Pragma: no-cache
Proxy-Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
Range: bytes=500-999
Referer: http://en.wikipedia.org/wiki/Main_Page
TE: trailers, deflate
Upgrade: HTTP/2.0, SHTTP/1.3, IRC/6.9, RTA/x11
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0
Via: 1.0 fred, https/1.1 example.com (Apache/1.1)
Warning: 199 Miscellaneous warning
X-Requested-With: XMLHttpRequest
DNT: 1 (Do Not Track Enabled)
X-Forwarded-For: client1, proxy1, proxy2
X-Forwarded-For: 129.78.138.66, 129.78.64.103
X-Forwarded-Proto: https
Front-End-Https: on
x-att-deviceid: MakeModel/Firmware
x-wap-profile: http://wap.samsungmobile.com/uaprof/SGH-I777.xml
Proxy-Connection: keep-alive
]]

dump[[
Access-Control-Allow-Origin: *
Accept-Ranges: bytes
Age: 12
Allow: GET, HEAD
Cache-Control: max-age=3600
Connection: close
Content-Encoding: gzip
Content-Language: da
Content-Length: 348
Content-Location: /index.htm
Content-MD5: Q2hlY2sgSW50ZWdyaXR5IQ==
Content-Disposition: attachment; filename="fname.ext"
Content-Range: bytes 21010-47021/47022
Content-Type: text/html; charset=utf-8
Date: Tue, 15 Nov 1994 08:12:31 GMT
ETag: "737060cd8c284d8af7ad3082f209582d"
Expires: Thu, 01 Dec 1994 16:00:00 GMT
Last-Modified: Tue, 15 Nov 1994 12:45:26 GMT
Link: </feed>; rel="alternate"
Location: http://www.w3.org/pub/WWW/People.html
P3P: CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."
Pragma: no-cache
Proxy-Authenticate: Basic
Refresh: 5; url=http://www.w3.org/pub/WWW/People.html
Retry-After: 120
Server: Apache/2.4.1 (Unix)
Set-Cookie: UserID=JohnDoe; Max-Age=3600; Version=1
Strict-Transport-Security: max-age=16070400; includeSubDomains
Trailer: Max-Forwards
Transfer-Encoding: chunked
Vary: *
Via: 1.0 fred, 1.1 example.com (Apache/1.1)
Warning: 199 Miscellaneous warning
WWW-Authenticate: Basic
X-Frame-Options: deny
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
X-Powered-By: PHP/5.4.0
X-UA-Compatible: IE=EmulateIE7
X-UA-Compatible: IE=edge
X-UA-Compatible: Chrome=1
]]

dump[[
Authorization: Digest username="Mufasa",
	realm="testrealm@host.com",
	nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
	uri="/dir/index.html",
	qop=auth,
	nc=00000001,
	cnonce="0a4f113b",
	response="6629fae49393a05397450978507c4ef1",
	opaque="5ccc069c403ebaf9f0171e9517f40e41"
]]
