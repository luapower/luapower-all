---
tagline: mysql database client
---

## `local mysql = require'mysql'`

A complete, lightweight ffi binding of the mysql client library.

> NOTE: binaries are in separate packages [libmysql] and [libmariadb].

## Summary

-------------------------------------------------------------------------------- --------------------------------------------------------------------------------
**[Initialization]**
`mysql.config(['mysql'|'mariadb'|libname|clib]) -> mysql`
**[Connections]**
`mysql.connect(host, [user], [pass], [db], [charset], [port]) -> conn`           connect to a mysql server
`mysql.connect(options_t) -> conn`                                               connect to a mysql server
`conn:close()`                                                                   close the connection
**[Queries]**
`conn:query(s)`                                                                  execute a query
`conn:escape(s) -> s`                                                            escape an SQL string
**[Fetching results]**
`conn:store_result() -> result`                                                  get a cursor for buffered read ([manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-store-result.html))
`conn:use_result() -> result`                                                    get a cursor for unbuffered read  ([manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-use-result.html))
`result:fetch([mode[, row_t]]) -> true, v1, v2, ... | row_t | nil`               fetch the next row from the result
`result:rows([mode[, row_t]]) -> iterator() -> row_num, val1, val2, ...`         row iterator
`result:rows([mode[, row_t]]) -> iterator() -> row_num, row_t`                   row iterator
`result:free()`                                                                  free the cursor
`result:row_count() -> n`                                                        number of rows
`result:eof() -> true | false`                                                   check if no more rows
`result:seek(row_number)`                                                        seek to row number
**[Query info]**
`conn:field_count() -> n`                                                        number of result fields in the executed query
`conn:affected_rows() -> n`                                                      number of affected rows in the executed query
`conn:insert_id() -> n`                                                          the id of the autoincrement column in the executed query
`conn:errno() -> n`                                                              mysql error code (0 if no error) from the executed query
`conn:sqlstate() -> s`
`conn:warning_count() -> n`                                                      number of errors, warnings, and notes from executed query
`conn:info() -> s`
**[Field info]**
`result:field_count() -> n`                                                      number of fields in the result
`result:field_name(field_number) -> s`                                           field name given field index
`result:field_type(field_number) -> type, length, unsigned, decimals`            field type given field index
`result:field_info(field_number) -> info_t`                                      field info table
`result:fields() -> iterator() -> i, info_t`                                     field info iterator
**[Result bookmarks]**
`result:tell() -> bookmark`                                                      bookmark the current row for later seek
`result:seek(bookmark)`                                                          seek to a row bookmark
**[Multiple statement queries]**
`conn:next_result() -> true | false`                                             skip to the next result set ([manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-next-result.html))
`conn:more_results() -> true | false`                                            are there more result sets?
**[Prepared statements]**
`conn:prepare(query) -> stmt`                                                    prepare a query for multiple executions
`stmt:param_count() -> n`																			number of params
`stmt:exec()`                                                                    execute a prepared statement
`stmt:store_result()`                                                            store all the resulted rows to the client
`stmt:fetch() -> true | false | true, 'truncated'`                               fetch the next row
`stmt:free_result()`                                                             free the current result buffers
`stmt:close()`                                                                   close the statement
`stmt:next_result()`                                                             skip to the next result set
`stmt:row_count() -> n`                                                          number of rows in the result, if the result was stored
`stmt:affected_rows() -> n`                                                      number of affected rows after execution
`stmt:insert_id() -> n`                                                          the id of the autoincrement column after execution
`stmt:field_count() -> n`                                                        number of fields in the result after execution
`stmt:errno() -> n`                                                              mysql error code, if any, from the executed statement
`stmt:sqlstate() -> s`
`stmt:result_metadata() -> result`                                               get a result for accessing the field info
`stmt:fields() -> iterator() -> i, info_t`                                       iterate the result fields info
`stmt:reset()`                                                                   see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-reset.html)
`stmt:seek(row_number)`                                                          seek to row number
`stmt:tell() -> bookmark`                                                        get a bookmark in the current result
`stmt:seek(bookmark)`                                                            seek to a row bookmark in the current result
**[Prepared statements I/O]**
`stmt:bind_params(type1, ... | types_t) -> params`                               bind query parameters based on type definitions
`params:set(i, number | int64_t | uint64_t | true | false)`                      set an integer, float or bit param
`params:set(i, s[, size])`                                                       set a variable sized param
`params:set(i, cdata, size)`                                                     set a variable sized param
`params:set(i, {year=, month=, ...})`                                            set a time/date param
`params:set_date(i, [year], [month], [day], [hour], [min], [sec], [frac])`       set a time/date param
`stmt:write(param_number, data[, size])`                                         send a long param in chunks
`stmt:bind_result([type1, ... | types_t | maxsize]) -> fields`                   bind query result fields based on type definitions
`fields:get(i) -> value`                                                         get the current row value of a field
`fields:get_datetime(i) -> year, month, day, hour, min, sec, frac`               get the value of a date/time field directly
`fields:is_null(i) -> true | false`                                              is field null?
`fields:is_truncated(i) -> true | false`                                         was field value truncated?
**[Prepared statements settings]**
`stmt:update_max_length() -> true | false`                                       see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
`stmt:set_update_max_length(true | false)`                                       see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
`stmt:cursor_type() -> mysql.C.MYSQL_CURSOR_TYPE_*`                              see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
`stmt:set_cursor_type('CURSOR_TYPE_...')`                                        see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
`stmt:set_cursor_type(mysql.C.MYSQL_CURSOR_TYPE_...)`                            see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
`stmt:prefetch_rows() -> n`                                                      see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
`stmt:set_prefetch_rows(stmt, n)`                                                see [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html)
**[Connection info]**
`conn:set_charset(charset)`                                                      change the current charset
`conn:select_db(dbname)`                                                         change the current database
`conn:change_user(user, [pass], [db])`                                           change the current user (and database)
`conn:set_multiple_statements(true | false)`                                     enable/disable support for multiple statements
`conn:charset() -> s`                                                            get current charset's name
`conn:charset_info() -> info_t`                                                  get info about the current charset
`conn:ping() -> true | false`                                                    check if the connection is still alive
`conn:thread_id() -> id`
`conn:stat() -> s`
`conn:server_info() -> s`
`conn:host_info() -> s`
`conn:server_version() -> n`
`conn:proto_info() -> n`
`conn:ssl_cipher() -> s`
**[Transactions]**
`conn:commit()`                                                                  commit the current transaction
`conn:rollback()`                                                                rollback the current transaction
`conn:set_autocommit([true | false])`                                            enable/disable autocommit on the current connection
**[Reflection]**
`conn:list_dbs([wildcard]) -> result`                                            return info about databases as a result object
`conn:list_tables([wildcard]) -> result`                                         return info about tables as a result object
`conn:list_processes() -> result`                                                return info about processes as a result object
**[Remote control]**
`conn:kill(pid)`                                                                 kill a connection based on process id
`conn:shutdown([level])`                                                         shutdown the server
`conn:refresh(options)`                                                          flush tables or caches
`conn:dump_debug_info()`                                                         dump debug info in the log file
**[Client library info]**
`mysql.thread_safe() -> true | false`                                            was the client library compiled as thread-safe?
`mysql.client_info() -> s`
`mysql.client_version() -> n`
-------------------------------------------------------------------------------- --------------------------------------------------------------------------------

## Features

  * covers all of the functionality provided by the mysql C API
  * all data types are supported with options for conversion
  * prepared statements, avoiding dynamic allocations and format conversions when fetching rows
  * all C calls are checked for errors and Lua errors are raised
  * all C objects are tied to Lua's garbage collector
  * lightweight OOP-style API using only `ffi.metatype`
  * no external dependencies

## Example

~~~{.lua}
function print_help(search)
   local mysql = require'mysql'

   local conn = mysql.connect('localhost', 'root', nil, 'mysql', 'utf8')
   conn:query("select name, description, example from help_topic where name like '" ..
						conn:escape(search) .. "'")
   local result = conn:store_result()

   print('Found:')
   for i,name in result:rows() do
      print('  ' .. name)
   end

   print()
   for i, name, description, example in result:rows() do
      print(name)
      print'-------------------------------------------'
      print(description)
      print'Example:'
      print'-------------------------------------------'
      print(example)
      print()
   end

   result:free()
   conn:close()
end

print_help'CONCAT%'
~~~

## Initialization

### `mysql.config(['mysql'|'mariadb'|libname|clib]) -> mysql`

Load the mysql client library to use (default is 'mysql').
This function is called on every module-level function.
Calling this function again is a no-op.

## Connections

### `mysql.connect(host, [user], [pass], [db], [charset], [port]) -> conn`
### `mysql.connect(options_t) -> conn`

Connect to a mysql server, optionally selecting a working database and charset.

In the second form, `options_t` is a table that besides `host`, `user`, `pass`, `db`, `charset`, `port`
can have the following fields:

  * `unix_socket`: specify a unix socket filename to connect to
  * `flags`: bit field corresponding to mysql [client_flag](http://dev.mysql.com/doc/refman/5.7/en/mysql-real-connect.html) parameter
    * can be a table of form `{CLIENT_... = true | false, ...}`, or
    * a number of form `bit.bor(mysql.C.CLIENT_..., ...)`
  * `options`: a table of form `{MYSQL_OPT_... = value, ...}`, containing options per [mysql_options()](http://dev.mysql.com/doc/refman/5.7/en/mysql-options.html) (values are properly converted from Lua types)
  * `attrs`: a table of form `{attr = value, ...}` containing attributes to be passed to the server per [mysql_options4()](http://dev.mysql.com/doc/refman/5.7/en/mysql-options4.html)
  * `key`, `cert`, `ca`, `cpath`, `cipher`: parameters used to establish a [SSL connection](http://dev.mysql.com/doc/refman/5.7/en/mysql-ssl-set.html)

### `conn:close()`

Close a mysql connection freeing all associated resources (otherwise called when `conn` is garbage collected).

##  Queries

### `conn:query(s)`

Execute a query. If the query string contains multiple statements, only the first statement is executed
(see the section on multiple statements).

### `conn:escape(s) -> s`

Escape a value to be safely embedded in SQL queries. Assumes the current charset.

##  Fetching results

### `conn:store_result() -> result`

Fetch all the rows in the current result set from the server and return a result object to read them one by one.

### `conn:use_result() -> result`

Return a result object that will fetch the rows in the current result set from the server on demand.

### `result:fetch([mode[, row_t]]) -> true, v1, v2, ... | row_t | nil`

Fetch and return the next row of values from the current result set. Returns nil if there are no more rows to fetch.

  * the `mode` arg can contain any combination of the following letters:
    * `"n"` - return values in a table with numeric indices as keys.
    * `"a"` - return values in a table with field names as keys.
    * `"s"` - do not convert numeric and time values to Lua types.
  * the `row_t` arg  is an optional table to store the row values in, instead of creating a new one on each fetch.
  * options "a" and "n" can be combined to get a table with both numeric and field name indices.
  * if `mode` is missing or if neither "a" nor "n" is specified, the values
  are returned to the caller unpacked, after a first value that is always
  true, to make it easy to distinguish between a valid `NULL` value in the
  first column and eof.
  * in "n" mode, the result table may contain `nil` values so `#row_t` and `ipairs(row_t)` are out; instead iterate from 1 to `result:field_count()`.
  * in "a" mode, for fields with duplicate names only the last field will be present.
  * if `mode` does not specify `"s"`, the following conversions are applied on the returned values:
    * integer types are returned as Lua numbers, except bigint which is returned as an `int64_t` cdata (or `uint64` if unsigned).
    * date/time types are returned as tables in the usual `os.date"*t"` format (date fields are missing for time-only types and viceversa).
    * decimal/numeric types are returned as Lua strings.
    * bit types are returned as Lua numbers, and as `uint64_t` for bit types larger than 48 bits.
    * enum and set types are always returned as strings.

### `result:rows([mode[, row_t]]) -> iterator() -> row_num, val1, val2, ...`
### `result:rows([mode[, row_t]]) -> iterator() -> row_num, row_t`

Convenience iterator for fetching (or refetching) all the rows from the current result set. The `mode` arg
is the same as for `result:fetch()`, with the exception that in unpacked mode, the first `true` value is not present.

### `result:free()`

Free the result buffer (otherwise called when `result` is garbage collected).

### `result:row_count() -> n`

Return the number of rows in the current result set . This value is only correct if `result:store_result()` was
previously called or if all the rows were fetched, in other words if `result:eof()` is true.

### `result:eof() -> true | false`

Check if there are no more rows to fetch. If `result:store_result()` was previously called, then all rows were
already fetched, so `result:eof()` always returns `true` in this case.

### `result:seek(row_number)`

Seek back to a particular row number to refetch the rows from there.

## Query info

### `conn:field_count() -> n`
### `conn:affected_rows() -> n`
### `conn:insert_id() -> n`
### `conn:errno() -> n`
### `conn:sqlstate() -> s`
### `conn:warning_count() -> n`
### `conn:info() -> s`

Return various pieces of information about the previously executed query.

## Field info

### `result:field_count() -> n`
### `result:field_name(field_number) -> s`
### `result:field_type(field_number) -> type, length, decimals, unsigned`
### `result:field_info(field_number) -> info_t`
### `result:fields() -> iterator() -> i, info_t`

Return information about the fields (columns) in the current result set.

## Result bookmarks

### `result:tell() -> bookmark`

Get a bookmark to the current row to be later seeked into with `seek()`.

### `result:seek(bookmark)`

Seek to a previous saved row bookmark, or to a specific row number, fetching more rows as needed.

## Multiple statement queries

### `conn:next_result() -> true | false`

Skip over to the next result set in a multiple statement query, and make that the current result set.
Return true if there more result sets after this one.

### `conn:more_results() -> true | false`

Check if there are more result sets after this one.

## Prepared statements

Prepared statements are a way to run queries and retrieve results more efficiently from the database, in particular:

  * parametrized queries allow sending query parameters in their native format, avoiding having to convert values into strings and escaping those strings.
  * running the same query multiple times with different parameters each time allows the server to reuse the parsed query and possibly the query plan between runs.
  * fetching the result rows in preallocated buffers avoids dynamic allocation on each row fetch.

The flow for prepared statements is like this:

  * call `conn:prepare()` to prepare a query and get a statement object.
  * call `stmt:bind_params()` and `stmt:bind_result()` to get the buffer objects for setting params and getting row values.
  * run the query multiple times; each time:
    * call `params:set()` for each param to set param values.
    * call `stmt:exec()` to run the query.
    * fetch the resulting rows one by one; for each row:
      * call `stmt:fetch()` to get the next row (it returns false if it was the last row).
      * call `fields:get()` to read the values of the fetched row.
  * call `stmt:close()` to free the statement object and all the associated resources from the server and client.

### `conn:prepare(query) -> stmt, params`

Prepare a query for multiple execution and return a statement object.

### `stmt:param_count() -> n`

Number of parameters.

### `stmt:exec()`

Execute a prepared statement.

### `stmt:store_result()`

Fetch all the rows in the current result set from the server, otherwise the rows are fetched on demand.

### `stmt:fetch() -> true | false | true, 'truncated'`

Fetch the next row from the current result set. Use a binding buffer (see prepared statements I/O section)
to get the row values. If present, second value indicates that at least one of the rows were truncated because
the receiving buffer was too small for it.

### `stmt:free_result()`

Free the current result and all associated resources (otherwise the result is closed when the statement is closed).

### `stmt:close()`

Close a prepared statement and free all associated resources (otherwise the statement is closed when garbage collected).

### `stmt:next_result()`

Skip over to the next result set in a multiple statement query.

### `stmt:row_count() -> n`
### `stmt:affected_rows() -> n`
### `stmt:insert_id() -> n`
### `stmt:field_count() -> n`
### `stmt:errno() -> n`
### `stmt:sqlstate() -> s`
### `stmt:result_metadata() -> result`
### `stmt:fields() -> iterator() -> i, info_t`

Return various pieces of information on the executed statement.

### `stmt:reset()`

See [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-reset.html).

### `stmt:seek(row_number)`
### `stmt:tell() -> bookmark`
### `stmt:seek(bookmark)`

Seek into the current result set.

## Prepared statements I/O

### `stmt:bind_params(type1, ... | types_t) -> params`

Bind query parameters according to a list of type definitions (which can be given either packed or unpacked).
Return a binding buffer object to be used for setting parameters.

The types must be valid, fully specified SQL types, eg.

  * `smallint unsigned` specifies a 16bit unsigned integer
  * `bit(32)` specifies a 32bit bit field
  * `varchar(200)` specifies a 200 byte varchar.

### `params:set(i, number | int64_t | uint64_t | true | false)`
### `params:set(i, s[, size])`
### `params:set(i, cdata, size)`
### `params:set(i, {year=, month=, ...})`
### `params:set_date(i, [year], [month], [day], [hour], [min], [sec], [frac])`

Set a parameter value.

  * the first form is for setting integers and bit fields.
  * the second and third forms are for setting variable-sized fields and decimal/numeric fields.
  * the last forms are for setting date/time/datetime/timestamp fields.
  * the null type cannot be set (raises an error if attempted).

### `stmt:write(param_number, data[, size])`

Send a parameter value in chunks (for long, var-sized values).

### `stmt:bind_result([type1, ... | types_t | maxsize]) -> fields`

Bind result fields according to a list of type definitions (same as for params).
Return a binding buffer object to be used for getting row values.
If no types are specified, appropriate type definitions will be created automatically as to minimize type conversions.
Variable-sized fields will get a buffer sized according to data type's maximum allowed size
and `maxsize` (which defaults to 64k).

### `fields:get(i) -> value`
### `fields:get_datetime(i) -> year, month, day, hour, min, sec, frac`

Get a row value from the last fetched row. The same type conversions as for `result:fetch()` apply.

### `fields:is_null(i) -> true | false`

Check if a value is null without having to get it if it's not.

### `fields:is_truncated(i) -> true | false`

Check if a value was truncated due to insufficient buffer space.

### `stmt:bind_result_types([maxsize]) -> types_t`

Return the list of type definitions that describe the result of a prepared statement.

## Prepared statements settings

### `stmt:update_max_length() -> true | false`
### `stmt:set_update_max_length(true | false)`
### `stmt:cursor_type() -> mysql.C.MYSQL_CURSOR_TYPE_*`
### `stmt:set_cursor_type('CURSOR_TYPE_...')`
### `stmt:set_cursor_type(mysql.C.MYSQL_CURSOR_TYPE_...)`
### `stmt:prefetch_rows() -> n`
### `stmt:set_prefetch_rows(stmt, n)`

See [manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-stmt-attr-set.html) for these.

## Connection info

### `conn:set_charset(charset)`

Change the current charset.

### `conn:select_db(dbname)`

Change the current database.

### `conn:change_user(user, [pass], [db])`

Change the current user and optionally select a database.

### `conn:set_multiple_statements(true | false)`

Enable or disable support for query strings containing multiple statements separated by a semi-colon.

### `conn:charset() -> s`

Get the current charset.

### `conn:charset_info() -> info_t`

Return a table of information about the current charset.

### `conn:ping() -> true | false`

Check if the connection to the server is still alive.

### `conn:thread_id() -> id`
### `conn:stat() -> s`
### `conn:server_info() -> s`
### `conn:host_info() -> s`
### `conn:server_version() -> n`
### `conn:proto_info() -> n`
### `conn:ssl_cipher() -> s`

Return various pieces of information about the connection and server.

## Transactions

### `conn:commit()`
### `conn:rollback()`

Commit/rollback the current transaction.

### `conn:set_autocommit([true | false])`

Set autocommit on the connection (set to true if no argument is given).

## Reflection

### `conn:list_dbs([wildcard]) -> result`
### `conn:list_tables([wildcard]) -> result`
### `conn:list_processes() -> result`

Return information about databases, tables and proceses as a stored result object that can be iterated etc.
using the methods of result objects. The optional `wild` parameter may contain the wildcard characters
`"%"` or `"_"`, similar to executing the query `SHOW DATABASES [LIKE wild]`.

## Remote control

### `conn:kill(pid)`

Kill a connection with a specific `pid`.

### `conn:shutdown([level])`

Shutdown the server. `SHUTDOWN` priviledge needed. The level argument is reserved for future versions of mysql.

### `conn:refresh(options)`

Flush tables or caches, or resets replication server information. `RELOAD` priviledge needed. Options are either
a table of form `{REFRESH_... = true | false, ...}` or a number of form `bit.bor(mysql.C.MYSQL_REFRESH_*, ...)` and
they are as described in the [mysql manual](http://dev.mysql.com/doc/refman/5.7/en/mysql-refresh.html).

### `conn:dump_debug_info()`

Instruct the server to dump debug info in the log file. `SUPER` priviledge needed.

## Client library info

### `mysql.thread_safe() -> true | false`
### `mysql.client_info() -> s`
### `mysql.client_version() -> n`

----

## TODO

  * reader function for getting large blobs in chunks using
  mysql_stmt_fetch_column: `stmt:chunks(i[, bufsize])` or `stmt:read()` ?
