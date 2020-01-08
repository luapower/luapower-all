
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

---------------------------------------------------- -------------------------
`error.error`                                        base class for errors
`error.errortype(classname[, super]) -> eclass`      create an error class
`error.new(class|classname, [e], ...) -> e`          create/wrap an error object
`error.is(v[, classes]) -> t|f`                      check an error object type
`error.raise(class|classname,... | e)`               (create and) raise an error
`error.catch(classes, f, ...) -> t,... | f,e`        pcall `f` and catch errors
`error.pcall(f, ...) -> ...`                         pcall that stores traceback in `e.traceback`
`error.check(class, v, ...) -> v | raise(class,...)` assert with specifying an error class
`error.protect(classes, f) -> protected_f`           turn raising `f` into a `nil,e` function
`eclass:__call(...) -> e`                            error class constructor
`eclass:__tostring() -> s`                           to make `error(e)` work
---------------------------------------------------- -------------------------

In the API `classes` can be given as `'classname1 ...'` or `{class1->true}`.
When in table form, you must include all the superclasses in the table as
they are not added automatically!

