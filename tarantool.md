
## `local tarantool = require'tarantool'`

Tarantool client for LuaJIT.
Uses [sock] for I/O but you can bring your own.

Compared to other implementations I've seen, this one has more consistent
error handling (from using [errors].tcp_protocol_errors in conjunction
with own [msgpack]), better handling of timeouts (due to [sock]'s `expires`
parameter), it's half the code size, it's based on Tarantool 2.8 (streams,
prepared statements, UUID & DECIMAL types), and you can use it in environments
where you need to use the environment's built-in async socket API.

## API

------------------------------------------------- ----------------------------
`tarantool.connect(opt) -> tt`                    connect to server
`  opt.host`                                      host (`'127.0.0.1'`)
`  opt.port`                                      port (`3301`)
`  opt.user`                                      user (optional)
`  opt.password`                                  password (optional)
`  opt.timeout`                                   timeout (`2`)
`  opt.tcp`                                       tcp object (`sock.tcp()`)
`  opt.clock`                                     clock function (`sock.clock`)
`  opt.mp`                                        [msgpack] instance to use (optional)
`tt:stream() -> tt`                               create a stream
`tt:select(space,[index],[key],[sopt]) -> tuples` select tuples from a space
`  sopt.limit`                                    limit (`4GB-1`)
`  sopt.offset`                                   offset (`0`)
`  sopt.iterator`                                 iterator
`tt:insert(space, tuple)`                         insert a tuple in a space
`tt:replace(space, tuple)`                        insert or update a tuple in a space
`tt:delete(space, key)`                           delete tuples from a space
`tt:update(space, index, key, oplist)`            [update tuples in bulk](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/update/)
`tt:upsert(space, index, key, oplist)`            [insert or update tuples in bulk](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/upsert/)
`tt:eval(expr, ...) -> ...`                       eval Lua expression on the server
`tt:call(fn, ...) -> ...`                         call Lua function on the server
`tt:exec(sql, params, [xopt]) -> rows`            execute SQL statement
`tt:prepare(sql) -> st`                           prepare SQL statement
`st:exec(params, [xopt]) -> rows`                 exec prepared statement
`st:free()`                                       unprepare statement
`st.fields`                                       field list with field info
`st.params`                                       param list with param info
`tt:ping()`                                       ping
`tt:clear_metadata_cache()`                       clear `space` and `index` names
`tt.mp`                                           [msgpack] instance used
------------------------------------------------- ----------------------------

What the args mean:

* `space` and `index` can be given by name or number. Resolved names are
cached so you need to call `tt:clear_metadata_cache()` if you know that
a space or index got renamed or removed (but not when new ones are created).
If you're using SQL exclusively, you don't have to worry about this.
* `tuple` is an array of values.
* `key` can be a string or an array of values.
* `oplist` is an array of update operations of form `{op, field, value}`.
* `params` in `tt:exec()` must always be an array, even when you're using
named params in the query. `st:exec()` doesn't have that limitation and
requires you to put `'?'` params in the array part and the named params in
the hash part of the params table.
* there's no valid `xopt` options yet.
