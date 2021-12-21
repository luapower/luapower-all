# lua-resty-mail

[![CircleCI](https://circleci.com/gh/GUI/lua-resty-mail.svg?style=svg)](https://circleci.com/gh/GUI/lua-resty-mail)

A high-level, easy to use, and non-blocking email and SMTP library for OpenResty.

# Features

- SMTP authentication, STARTTLS, and SSL support.
- Multipart plain text and HTML message bodies.
- From, To, Cc, Bcc, Reply-To, and Subject fields (custom headers also supported).
- Email addresses in "test@example.com" and "Name &lt;test@example.com&gt;" formats.
- File attachments.

# Installation

Via [OPM](https://opm.openresty.org):

```sh
opm get GUI/lua-resty-mail
```

Or via [LuaRocks](https://luarocks.org):

```sh
luarocks install lua-resty-mail
```

# Usage

```lua
local mail = require "resty.mail"

local mailer, err = mail.new({
  host = "smtp.gmail.com",
  port = 587,
  starttls = true,
  username = "example@gmail.com",
  password = "password",
})
if err then
  ngx.log(ngx.ERR, "mail.new error: ", err)
  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local ok, err = mailer:send({
  from = "Master Splinter <splinter@example.com>",
  to = { "michelangelo@example.com" },
  cc = { "leo@example.com", "Raphael <raph@example.com>", "donatello@example.com" },
  subject = "Pizza is here!",
  text = "There's pizza in the sewer.",
  html = "<h1>There's pizza in the sewer.</h1>",
  attachments = {
    {
      filename = "toppings.txt",
      content_type = "text/plain",
      content = "1. Cheese\n2. Pepperoni",
    },
  },
})
if err then
  ngx.log(ngx.ERR, "mailer:send error: ", err)
  return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
```

# API

## new

**syntax:** `mailer, err = mail.new(options)`

Create and return a new mail object. In case of errors, returns `nil` and a string describing the error.

The `options` table accepts the following fields:

- `host`: The host of the SMTP server to connect to. (default: `localhost`)
- `port`: The port number on the SMTP server to connect to. (default: `25`)
- `starttls`: Set to `true` to ensure [STARTTLS](https://en.wikipedia.org/wiki/STARTTLS) is always used to encrypt communication with the SMTP server. If not set, STARTTLS will automatically be enabled if the server supports it (but explicitly setting this to true if your server supports it is preferable to prevent STRIPTLS attacks). This is usually used in conjunction with port 587. (default: `nil`)
- `ssl`: Set to `true` to use [SMTPS](https://en.wikipedia.org/wiki/SMTPS) to encrypt communication with the SMTP server (not needed if STARTTLS is being used instead). This is usually used in conjunction with port 465. (default: `nil`)
- `username`: Username to use for SMTP authentication. (default: `nil`)
- `password`: Password to use for SMTP authentication. (default: `nil`)
- `auth_type`: The type of SMTP authentication to perform. Can either be `plain` or `login`. (default: `plain` if username and password are present)
- `domain`: The domain name presented to the SMTP server during the `EHLO` connection and used as part of the Message-ID header. (default: `localhost.localdomain`)
- `timeout_connect`: The timeout (in milliseconds) for connecting to the SMTP server. (default: OpenResty's global `lua_socket_connect_timeout` timeout, which defaults to 60s)
- `timeout_send`: The timeout (in milliseconds) for sending data to the SMTP server. (default: OpenResty's global `lua_socket_send_timeout` timeout, which defaults to 60s)
- `timeout_read`: The timeout (in milliseconds) for reading data from the SMTP server. (default: OpenResty's global `lua_socket_read_timeout` timeout, which defaults to 60s)

## mailer:send

**syntax:** `ok, err = mailer:send(data)`

Send an email via the SMTP server. This function returns `true` on success. In case of errors, returns `nil` and a string describing the error.

The `data` table accepts the following fields:

- `from`: Email address for the `From` header.
- `reply_to`: Email address for the `Reply-To` header.
- `to`: A table (list-like) of email addresses for the `To` recipients.
- `cc`: A table (list-like) of email addresses for the `Cc` recipients.
- `bcc`: A table (list-like) of email addresses for the `Bcc` recipients.
- `subject`: Message subject.
- `text`: Body of the message (plain text version).
- `html`: Body of the message (HTML verion).
- `headers`: A table of additional headers to set on the message.
- `attachments`: A table (list-like) of file attachments for the message. Each attachment must be an table (map-like) with the following fields:
  - `filename`: The filename of the attachment.
  - `content_type`: The `Content-Type` of the file attachment.
  - `content`: The contents of the file attachment as a string.
  - `disposition`: The `Content-Disposition` of the file attachment. Can either be `attachment` or `inline`. (default: `attachment`)
  - `content_id`: The `Content-ID` of the file attachment. (default: randomly generated ID)

# Development

After checking out the repo, Docker can be used to run the test suite:

```sh
docker-compose run --rm app make test
```

## Release Process

To release a new version to LuaRocks and OPM:

- Ensure `CHANGELOG.md` is up to date.
- Update the `_VERSION` in `lib/resty/mail.lua`.
- Update the `version` in `dist.ini`.
- Move the rockspec file to the new version number (`git mv lua-resty-mail-X.X.X-1.rockspec lua-resty-mail-X.X.X-1.rockspec`), and update the `version` and `tag` variables in the rockspec file.
- Commit and tag the release (`git tag -a vX.X.X -m "Tagging vX.X.X" && git push origin vX.X.X`).
- Run `make release VERSION=X.X.X`.
