--[==[

	webb | sending email
	Written by Cosmin Apreutesei. Public Domain.

MAIL

	sendmail(from, rcpt, subj, msg, html)     send mail via smtp to local server

]==]

require'webb'
require'resty.socket'
local smtp = require'socket.smtp'
smtp.TIMEOUT = 6000
local mime = require'mime'
local ltn12 = require'ltn12'

local function strip_name(email)
	return '<'..(email:match'<(.-)>' or email)..'>'
end

function sendmail(from, rcpt, subj, msg, html)
	local source = smtp.message{
		headers = {
			from = from,
			to = rcpt,
			subject = subj,
			['content-type'] = html and 'text/html' or 'text/plain'
		},
		body = mime.eol(0, msg),
	}
	assert(smtp.send{
		from   = strip_name(from),
		rcpt   = {
			strip_name(rcpt),
			strip_name(from),
		},
		source = source,
		server = config('smtp_host', '127.0.0.1'),
		port   = config('smtp_port', 25),
	})
end

