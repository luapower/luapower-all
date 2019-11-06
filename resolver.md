---
tagline: DNS resolver in Lua
---

## `local resolver = require'resolver'`

DNS resolver in Lua [from OpenResty](https://github.com/openresty/lua-resty-dns) (BSD License).
Modified to work with any LuaSocket-like API.

## API

------------------------------------------------------------- ----------------
`resolver.new(opts) -> r, err`                                create a resolver object
`r:query(name, [options], [tries]) -> answers, err, tries`    query DNS
`r:tcp_query(name, [options]) -> answers, err`                query DNS via TCP
`r:set_timeout(time)`                                         set timeout
`resolver.arpa_str(address) -> arpa_record`
`r:reverse_query(address) -> answers, err`
------------------------------------------------------------- ----------------

IMPORTANT: to be able generate unique ids, the random generator must be
properly seeded using `math.randomseed` prior to using this module.

## Example

```lua
local r, err = assert(resolver.new{
	nameservers = {'8.8.8.8', {'8.8.4.4', 53} },
	retrans = 5,  -- 5 retransmissions on receive timeout
	timeout = 2000,  -- 2 sec
})
local answers, err, tries = r:query('www.google.com', nil, {})
if not answers then
	 print('failed to query the DNS server: ' .. err)
	 print('retries: ' .. table.concat(tries, '\n'))
elseif answers.errcode then
	 print('server returned error code: ' ..
		answers.errcode .. ': ' .. answers.errstr)
end
for i, ans in ipairs(answers) do
	 print(ans.name .. ' ' .. (ans.address or ans.cname) ..
		' type:' .. ans.type .. ' class: ' .. ans.class .. ' ttl: ' .. ans.ttl)
end
```

## API

### `resolver.new(opts) -> r, err`

Creates a resolver object. Returns `nil` and an message string on error.

It accepts a `opts` table argument. The following options are supported:

* `nameservers`

	a list of nameservers to be used. Each nameserver entry can be either a
	single hostname string or a table holding both the hostname string and
	the port number. The nameserver is picked up by a simple round-robin
	algorithm for each `query` method call. This option is required.
* `retrans`

	the total number of times of retransmitting the DNS request when receiving
	a DNS response times out according to the `timeout` setting.
	Defaults to `5` times. When trying to retransmit the query, the next
	nameserver according to the round-robin algorithm will be picked up.
* `timeout`

	the time in milliseconds for waiting for the respond for a single attempt
	of request transmition. note that this is ''not'' the maximal total
	waiting time before giving up, the maximal total waiting time can be
	calculated by the expression `timeout x retrans`. The `timeout` setting
	can also be changed by calling the `set_timeout` method. The default
	`timeout` setting is 2000 milliseconds, or 2 seconds.
* `no_recurse`

	a boolean flag controls whether to disable the "recursion desired" (RD)
	flag in the UDP request. Defaults to `false`.

* `async`

	a boolean flag indicating that sockets shoud be wrapped by [socketloop].
* `tcp`, `udp`, `tcp_async`, `udp_async`

	alternative socket constructors, defaulting to [socket] tcp and udp
	constructors. Can also be set at module level.

### `r:query(name, [options], [tries]) -> answers, err, tries`

Perform a DNS standard query to the nameservers specified by the `new` method,
and returns all the answer records in an array-like Lua table. In case of
errors, it will return `nil` and a string describing the error instead.

If the server returns a non-zero error code, the fields `errcode` and `errstr`
will be set accordingly in the Lua table returned.

Each entry in the `answers` returned table value is also a hash-like Lua table
which usually takes some of the following fields:

* `name`

	The resource record name.
* `type`

	The current resource record type, possible values are `1` (`TYPE_A`),
	`5` (`TYPE_CNAME`), `28` (`TYPE_AAAA`), and any other values allowed by RFC 1035.
* `address`

	The IPv4 or IPv6 address in their textual representations when the
	resource record type is either `1` (`TYPE_A`) or `28` (`TYPE_AAAA`),
	respectively. Secussesive 16-bit zero groups in IPv6 addresses will not
	be compressed by default, if you want that, you need to call the
	`compress_ipv6_addr` static method instead.
* `section`

	The identifier of the section that the current answer record belongs to.
	Possible values are `1` (`SECTION_AN`), `2` (`SECTION_NS`), and `3`
	(`SECTION_AR`).
* `cname`

	The (decoded) record data value for `CNAME` resource records.
	Only present for `CNAME` records.
* `ttl`

	The time-to-live (TTL) value in seconds for the current resource
	record.
* `class`

	The current resource record class, possible values are `1` (`CLASS_IN`)
	or any other values allowed by RFC 1035.
* `preference`

	The preference integer number for `MX` resource records. Only present for
	`MX` type records.
* `exchange`

	The exchange domain name for `MX` resource records. Only present for
	`MX` type records.
* `nsdname`

	A domain-name which specifies a host which should be authoritative for
	the specified class and domain. Usually present for `NS` type records.
* `rdata`

	The raw resource data (RDATA) for resource records that are not recognized.
* `txt`

	The record value for `TXT` records. When there is only one character
	string in this record, then this field takes a single Lua string.
	Otherwise this field takes a Lua table holding all the strings.
* `ptrdname`

	The record value for `PTR` records.

This method also takes an optional `options` argument table, which takes
the following fields:

* `qtype`

	The type of the question. Possible values are `1` (`TYPE_A`),
	`5` (`TYPE_CNAME`), `28` (`TYPE_AAAA`), or any other QTYPE value specified
	by RFC 1035 and RFC 3596. Default to `1` (`TYPE_A`).
* `authority_section`

	When set to a true value, the `answers` return value includes the
	`Authority` section of the DNS response. Default to `false`.
* `additional_section`

	When set to a true value, the `answers` return value includes the
	`Additional` section of the DNS response. Default to `false`.

The optional parameter `tries` can be provided as an empty table, and will be
returned as a third result. The table will be an array with the error message
for each (if any) failed try.

When data truncation happens, the resolver will automatically retry using
the TCP transport mode to query the current nameserver. All TCP connections
are short lived.

### `r:tcp_query(name, [options]) -> answers, err`

Just like the `query` method, but enforce the TCP transport mode instead of UDP.

All TCP connections are short lived.

Here is an example:

```lua
local r, err = assert(resolver.new{
	nameservers = { '8.8.8.8' }
})
local ans, err = r:tcp_query('www.google.com', { qtype = r.TYPE_A })
if not ans then
	print('failed to query: ' .. err)
	return
end
```

### `r:set_timeout(time)`

Overrides the current `timeout` setting by the `time` argument in seconds
for all the nameserver peers.

### `resolver.arpa_str(address) -> arpa_record`

Generates the reverse domain name for PTR lookups for both IPv4 and IPv6
addresses. Compressed IPv6 addresses will be automatically expanded.

For example,

```lua
local ptr4 = resolver.arpa_str'1.2.3.4'
local ptr6 = resolver.arpa_str'FF01::101'
```

will yield `4.3.2.1.in-addr.arpa` for `ptr4`
and `1.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.0.F.F.ip6.arpa`
for `ptr6`.

### `r:reverse_query(address) -> answers, err`

Performs a PTR lookup for both IPv4 and IPv6 addresses. This function is
basically a wrapper for the `query` command which uses the `arpa_str` command
to convert the IP address on the fly.

### Constants

-------------- ---------------------------------------------------------------
`r.TYPE_A`     The `A` resource record type, equal to the decimal number `1`.
`r.TYPE_NS`    The `NS` resource record type, equal to the decimal number `2`.
`r.TYPE_CNAME` The `CNAME` resource record type, equal to the decimal number `5`.
`r.TYPE_SOA`   The `SOA` resource record type, equal to the decimal number `6`.
`r.TYPE_PTR`   The `PTR` resource record type, equal to the decimal number `12`.
`r.TYPE_MX`    The `MX` resource record type, equal to the decimal number `15`.
`r.TYPE_TXT`   The `TXT` resource record type, equal to the decimal number `16`.
`r.TYPE_AAAA`  The `AAAA` resource record type, equal to the decimal number `28`.
`r.TYPE_SRV`   The `SRV` resource record type, equal to the decimal number `33`. See RFC 2782 for details.
`r.TYPE_SPF`   The `SPF` resource record type, equal to the decimal number `99`. See RFC 4408 for details.
`r.CLASS_IN`   The `Internet` resource record type, equal to the decimal number `1`.
`r.SECTION_AN` Identifier of the `Answer` section in the DNS response. Equal to decimal number `1`.
`r.SECTION_NS` Identifier of the `Authority` section in the DNS response. Equal to the decimal number `2`.
`r.SECTION_AR` Idnetifier of the `Additional` section in the DNS response. Equal to the decimal number `3`.
-------------- ---------------------------------------------------------------

## TODO

* Concurrent (or parallel) query mode
* Better support for other resource record types like `TLSA`.
