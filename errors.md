
## `local errors = require'errors'`

This is an API that adds structured exceptions to Lua. Exceptions, like
coroutines are not used very frequently in Lua because they solve
cross-cutting concerns(*) that don't appear very often in code. But when
they do appear, these devices are invaluable code decluttering tools.

Structured exceptions are an enhancement over string exceptions that enable
_selective catching_ and allow _providing a context_ for the failure to help
with recovery or logging.

> (*) Coroutines address the problem of inversion-of-control head-on.
Exceptions address the problem of recoverable failure head-on, so they're
most useful in network I/O contexts.

## API

-------------------------------------------------------- ---------------------
`errors.error`                                           base class for errors
`errors.error:init()`                                    stub: called after the error is created
`errors.errortype([classname], [super]) -> eclass`       create/get an error class
`eclass(...) -> e`                                       create an error object
`errors.new(classname,... | e) -> e`                     create/wrap/pass-through an error object
`errors.is(v[, classes]) -> true|false`                  check an error object type
`errors.raise(classname,... | e)`                        (create and) raise an error
`errors.catch([classes], f, ...) -> true,... | false,e`  pcall `f` and catch errors
`errors.pcall(f, ...) -> ...`                            pcall that stores traceback in `e.traceback`
`errors.check(v, ...) -> v | raise(...)`                 assert with specifying an error class
`errors.protect(classes, f) -> protected_f`              turn raising `f` into a `nil,e` function
`eclass:__call(...) -> e`                                error class constructor
`eclass:__tostring() -> s`                               to make `error(e)` work
`eclass.addtraceback`                                    add a traceback to errors
`e.message`                                              formatted error message
`e.traceback`                                            traceback at error site
-------------------------------------------------------- ---------------------

In the API `classes` can be given as `'classname1 ...'` or `{class1->true}`.
When given in table form, you must include all the superclasses in the table
since they are not added automatically!

### How to construct an error

`errors.raise()` passes its varargs to `errors.new()` which passes them
to `eclass()` which passes them to `eclass:__call()` which interprets them
as follows: `[err_obj, err_obj_options..., ][format, format_args...]`.
So if the first arg is a table it is converted to the final error object.
Any following table args are merged with this object. Any following args
after that are passed to `string.format()` and the result is placed in
`err_obj.message` (if `message` was not already set). All args are optional.

## TCP protocol error handling

### `errors.tcp_protocol_errors(protocol_name) -> check_io, checkp, check, protect`

### `check[p|_io](self, val, format, format_args...) -> val`

This is an error-handling discipline to use when writing TCP-based
protocols. Instead of using standard `assert()` and `pcall()`, use `check()`,
`checkp()` and `check_io()` to raise errors inside protocol methods and then
wrap those methods in `protect()` to catch those errors and have the method
return `nil, err` instead of raising for those types of errors.

You should distinguish between multiple types of errors:

- Invalid API usage, i.e. bugs on this side, which should raise (but shouldn't
  happen in production). Use `assert()` for those.
- Response validation errors, i.e. bugs on the other side which shouldn't
  raise but they put the connection in an inconsistent state so the connection
  must be closed. Use `checkp()` short of "check protocol" for those. Note that
  if your protocol is not meant to work with a hostile or unstable peer, you
  can skip the `checkp()` checks entirely because they won't guard against
  anything and just bloat the code.
- Request or response content validation errors, which can be user-corrected
  so mustn't raise and mustn't close the connection. Use `check()` for those.
- I/O errors, i.e. network failures which can be temporary and thus make the
  call retriable, so they must be distinguishable from other types of errors.
  Use `check_io()` for those. On the call side then check the error class for
  implementing retries.

Following this protocol should easily cut your network code in half, increase
its readability (no more error-handling noise) and its reliability (no more
confusion about when to raise and when not to or forgetting to handle an error).

#### Other notes

Your connection object must have a `tcp` field with a `tcp:close()` method
that will be called by `check_io()` and `checkp()` (but not `check()`)
on failure.

`protect()` only protects from errors raised by `check*()`.
Other Lua errors pass through.
