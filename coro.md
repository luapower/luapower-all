---
tagline: symmetric coroutines
---

## `local coro = require'coro'`

Symmetric coroutines are coroutines that can transfer control freely between
themselves, unlike Lua's standard coroutines which can only yield back to
the coroutine that resumed them (and are called asymmetric coroutines
or generators because of that reason).

## Rationale

Using coroutine-based async I/O methods (like the `read()` and `write()`
methods of async socket libraries) inside user-created standard coroutines
is by default not possible because the I/O methods would yield to the parent
coroutine instead of yielding to their scheduler. This can be solved using
a coroutine scheduler that allows transferring control not only to the parent
coroutine but to any specified coroutine.

This implementation is loosely based on the one from the paper
[Coroutines in Lua](http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf)
with some important modifications:

 * `coro.transfer()` can transfer multiple values between coroutines
 (without pressuring the gc).
 * the coro module reimplements all the methods of the built-in coroutine
 module such that it can replace it entirely, which is what enables arbitrary
 transfering of control from inside standard-behaving coroutines.
 * `coro.safewrap()` is added which allows cross-yielding.

## API

### `coro.create(f) -> thread`

Create a coroutine which can be started with either `coro.resume()` or
with `coro.transfer()`.

### `coro.transfer(thread[, ...]) -> ...`

Transfer control (and optionally any values) to a coroutine, suspending
execution. The target coroutine either hasn't started yet, in which case it
is started and it receives the values as the arguments of its main function,
or it's suspended in a call to `coro.transfer()`, in which case it is resumed
and receives the values as the return values of that call. Likewise, the
coroutine which transfers execution will stay suspended until `coro.transfer()`
is called again with it as target.

Errors raised inside a coroutine which was transferred into are re-raised
into the main thread.

A coroutine which was transferred into (as opposed to one which was
resumed into) must finish by transferring control to another coroutine
(or to the main thread) otherwise an error is raised.

### `coro.ptransfer(thread[, ...]) -> ok, ... | nil, err`

Protected transfer: a variant of `coro.transfer()` that doesn't raise.

### `coro.install() -> old_coroutine_module`

Replace `_G.coroutine` with `coro` and return the old coroutine module.
This enables coroutine-based-generators-over-abstract-I/O-callbacks
from external modules to work with scheduled I/O functions which call
`coro.transfer()` inside.

### `coro.yield(...) -> ...`

Behaves like standard `coroutine.yield()`. A coroutine that was transferred
into via `coro.transfer()` cannot yield (an error is raised if attempted).

### `coro.resume(...) -> true, ... | false, err, traceback`

Behaves like standard `coroutine.resume()`. Adds a traceback as the third
return value in case of error.

### `coro.current() -> thread, is_main`

Behaves like standard `coroutine.current()` (from Lua 5.2 / LuaJIT 2).

### `coro.status(thread) -> status`

Behaves like standard `coroutine.status()`.

__NOTE:__ In this implementation `type(thread) == 'thread'`.

### `coro.wrap(f) -> wrapper`

Behaves like standard `coroutine.wrap()`.

### `coro.safewrap(f) -> wrapper`

Behaves like `coroutine.wrap()` except that the wrapped function receives
a custom `yield()` function as its first argument which always yields back
to the calling thread even when called from a different thread. This allows
cross-yielding i.e. yielding past multiple levels of nested coroutines
which enables unrestricted inversion-of-control.

With this you can turn any callback-based library into a sequential library,
even if said library uses coroutines itself and wouldn't normally allow
the callbacks to yield.

## Why it works

This works because calling `resume()` from a thread is a lie: instead of
resuming the thread it actually suspends the calling thread giving back
control to the main thread which does the resuming. Since the calling
thread is now suspended, it can later be resumed from any other thread.
