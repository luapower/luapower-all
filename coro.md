---
tagline: symmetric coroutines
---

## `local coro = require'coro'`

Symmetric coroutines are coroutines that can transfer control to any other
coroutine, unlike Lua's standard coroutines which can only yield back to
their parent coroutine (and are called asymmetric coroutines or generators).

Rationale: writing coroutine-based generators over scheduled async callbacks
(like the `read()` and `write()` methods of [socketloop] sockets) in Lua is
by default not possible because the callbacks would yield to the generator
coroutine instead of yielding to their scheduler. This can be solved using
a coroutine scheduler that allows transferring control both to the parent
coroutine as well as transferring control to a specific coroutine.

This implementation is loosely based on the one from the paper
[Coroutines in Lua](http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf)
with some important modifications:

 * `coro.transfer()` can transfer multiple values between coroutines
 (without pressuring the gc).
 * the coro module reimplements all the methods of the built-in coroutine
 module such that it can replace it entirely, which is what enables arbitrary
 transfering of control from inside standard-behaving coroutines.

## API

### `coro.create(f) -> thread`

Create a coroutine which can be started with either `coro.resume()` or
with `coro.transfer()`.

### `coro.transfer(thread|nil[, ...]) -> ...`

Transfer control (and optionally any values) to a coroutine (or to the main
thread if nil is passed for thread), suspending execution. The target
coroutine either hasn't started yet, in which case it is started and it
receives the values as the arguments of its main function, or it's suspended
in a call to `coro.transfer()`, in which case it is resumed and receives the
values as the return values of that call. Likewise, the coroutine which
transfers execution will stay suspended until `coro.transfer()` is called
again with it as target.

Errors raised inside a coroutine which was transferrred into are re-raised
into the main thread.

A coroutine which was transferred into (as opposed to one which was
resumed into) must finish by transferring control to another coroutine
(or to the main thread), otherwise an error is raised.

### `coro.install() -> old_coroutine_module`

Replace `_G.coroutine` with `coro` and return the old coroutine module.
This enables coroutine-based-generators-over-abstract-I/O-callbacks
from external modules to work with scheduled I/O functions which call
`coro.transfer()` inside.

### `coro.yield(...) -> ...`

Behaves like standard `coroutine.yield()`. A coroutine that was transferred
into via `coro.transfer()` cannot yield (an error is raised if attempted).

### `coro.resume(...) -> true, ... | false, err, tracekback`

Behaves like standard `coroutine.resume()`. Adds a traceback as the third
return value in case of error.

### `coro.current() -> thread | nil`

Behaves like standard `coroutine.current()`.

### `coro.status(thread) -> status`

Behaves like standard `coroutine.status()`.

__NOTE:__ In this implementation `type(thread) == 'thread'`.

## Why it works

This works because calling `resume()` from a thread is a lie: instead of
resuming the thread it actually suspends the calling thread giving back
control to the main thread which does the resuming. Since the calling
thread is now suspended, it can later be resumed from any other thread.
