
## `local mysql = require'mysql'`

MySQL client protocol in Lua. Ripped from OpenResty, modified to work with
[sock] (but you can bring your own I/O), added prepared statements,
better interpretation of field metadata (consistent with [sqlpp], [schema]
and [x-widgets]), and other minor changes.

## Example

```lua
local mysql = require'mysql'

assert(mysql.connect{
	host = '127.0.0.1',
	port = 3306,
	user = 'bar',
	password = 'baz',
	db = 'foo',
	charset = 'utf8mb4',
	max_packet_size = 1024 * 1024,
})

assert(cn:query('drop table if exists cats'))

local res = assert(cn:query('create table cats '
			  .. '(id serial primary key, '
			  .. 'name varchar(5))'))

local res = assert(cn:query('insert into cats (name) '
	.. "values ('Bob'),(''),(null)"))

print(res.affected_rows, ' rows inserted into table cats ',
		'(last insert id: ', res.insert_id, ')')

require'pp'(assert(cn:query('select * from cats order by id asc', 10)))

assert(cn:close())
```

## API

### `mysql.connect(options) -> ok | nil,err,errcode,sqlstate`

Connect to a MySQL server.

The `options` argument is a Lua table holding the following keys:

  * `host`: server's IP address (required).
  * `port`: server's port (optional, defaults to 3306).
  * `user`: user name.
  * `password`: password (optional).
  * `db`: the database to set as current database (optional).
  * `charset`: the character set used for the connection (required, see below).
  * `collation`: the collation used for the connection (required, see below).
   * if only `charset` is given, the default collation for the charset is set automatically.
   * if `collation` is given, `charset` is set automatically and must not be supplied.
  * `max_packet_size`: the upper limit for the reply packets sent from the server (defaults to 16 MB).
  * `ssl`: if `true`, then uses SSL to connect to MySQL (defaults to `false`).
  If the server does not have SSL support (or just disabled), the error string
  "ssl disabled on server" is returned.
  * `ssl_verify`: if `true`, then verifies the validity of the server SSL
  certificate (default is `false`).
  * `to_lua = f(v, col) -> v` -- custom value converter (defaults to `mysql.to_lua`).

### `cn:close() -> true | nil,err`

Closes the current mysql connection and returns the status.

### `cn:closed() -> true | false`

Check if the connection was closed.

### `cn:send_query(query) -> bytes | nil,err`

Sends the query to the remote MySQL server without waiting for its replies.

Returns the bytes successfully sent out. Use `read_result()` to read the replies.

### `cn:read_result([options]) -> res,nil|'again',cols | nil,err,errcode,sqlstate`

Reads in the next result set returned from the server.

The `options` arg can contain:

  * `compact = true` -- return an array of arrays instead of an array
  of `{column->value}` maps
    * __NOTE__: unless you set `null_value`, the rows in compact mode will
    be sparse arrays so `ipairs(row)` and `#row` won't work on them
    (but `#cols` will).
  * `to_array  = true` -- return an array of values for single-column results.
  * `null_value = val` -- value to use for `null` (defaults to `nil`).
  * `field_attrs = {name -> attr}` -- extra field attributes. It can also be
  a function which will be called as `field_attrs(cn, fields, opt)`
  as soon as field metadata is received but before rows are received
  (so you can even set a custom `mysql_to_lua` for particular fields).

For queries that return a result set, it returns an array of rows.
For other queries it returns a Lua table with information such as
the autoincrement value if any and the affected rows.

If more results are following the current result, a second return value
`'again'` is returned. One should always check this value and call this
method again to retrieve more results. This usually happens when the original
query contains multiple statements (separated by semicolon in the same
query string) or calling a stored procedure.

In case of errors, this method returns at most 4 values: `nil`, `err`, `errcode`, and `sqlstate`.
The `err` return value contains a string describing the error, the `errcode`
return value holds the MySQL error code (a numerical value), and finally,
the `sqlstate` return value contains the standard SQL error code that consists
of 5 characters. Note that, the `errcode` and `sqlstate` might be `nil`
if MySQL does not return them.

__NOTE:__ Decimals with up to 15 digits of precision and 64 bit integers
are converted to Lua numbers by default. That limits the useful range of
integer types to 15 significant digits. If you have other needs, provide
your own `to_lua` (which you can set at module or connection level,
per query in `field_attrs`, or in a [schema] column definition with
the `mysql_to_lua` attribute).

### `cn:query(query, [options]) -> res,nil,cols | nil,err,errcode,sqlstate`

This is a shortcut for combining the [send_query](#send_query) call
and the first [read_result](#read_result) call.

You should always check if the `err` return value  is `again` in case of
success because this method will only call [read_result](#read_result)
once for you.

### `cn:prepare(query, [opt]) -> stmt`

Prepare a statement. Options can contain:

  * `cursor`: 'read_only', 'update', 'scrollabe', 'none' (default: 'none').

### `stmt:exec(params...)`

Execute a statement. Use `cn:read_result()` to get the results.

### `stmt:free()`

Free statement.

### `cn.server_ver`

The MySQL server version string.

### `mysql.esc_utf8(s) -> s`

Escape string to be used inside SQL string literals. Only works on connections
for which the charset is ASCII or an ASCII superset (ascii, utf8).

### `cn:esc(s) -> s`

Escape string to be used inside SQL string literals.

### Multiple result set support

For a SQL query that produces multiple result-sets, it is always your duty to
check the 'again' error message returned by the query, and keep pulling more
result sets by calling the `read_result()` until no 'again' error message
returned (or some other errors happen).

## Limitations

### Authentication

By default, of all authentication methods, only
[Old Password Authentication(mysql_old_password)](https://dev.mysql.com/doc/internals/en/old-password-authentication.html)
and [Secure Password Authentication(mysql_native_password)](https://dev.mysql.com/doc/internals/en/secure-password-authentication.html)
are suppored.

## TODO

* implement the data compression support in the protocol.

