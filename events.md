
## `local events = require'events'`

Events are a way to associate an action with one or more callback functions
to be called on that action, while adding the distinct ability to remove one
or more callbacks selectively later on.

This module is only a mixin (a plain table with methods). It must be added to
your preferred object system by copying the methods over to your base class.

## Usage

To fire an event call `obj:fire(event_name, args...)`. To add one or more
functions to be called when an event is fired, use `obj:on(event_name, handler)`.
Those functions will be called in the order in which they were added.
If there's a method on the target object with the same name as the event,
that method will also be called when the event fires, before other handlers.

## Examples

  * `apple:on('falling.ns1.ns2', function(self, args...) ... end)` - register
  an event handler and associate it with the `ns1` and `ns2` tags/namespaces.
  * `apple:on({'falling', ns1, ns2}, function ... end)` - same but the tags
  can be any type.
  * `apple:once('falling', function ... end)` - fires only once.
  * `Apple:falling(args...)` - default event handler for the `falling` event.
  * `apple:fire('falling', args...)` - call all `falling` event handlers.
  * `apple:off'falling'` - remove all `falling` event handlers.
  * `apple:off'.ns1'` - remove all event handlers on the `ns1` tag.
  * `apple:off{nil, ns1}` - remove all event handlers on the `ns1` tag.
  * `apple:off() - remove all event handlers registered on `apple`.

## Event facts

  * events fire in the order in which they were added.
  * extra args passed to `fire()` are passed to each event handler.
  * if the method `obj:<event>(args...)` is found, it is called first.
  * returning a non-nil value from a handler interrupts the event handling
    call chain and the value is returned back by `fire()`.
  * the meta-event called `'event'` is fired on all events (the name of the
  event that was fired is received as arg#1).
  * events can be tagged with multiple tags/namespaces `'event.ns1.ns2...'`
  or `{event, ns1, ns2, ...}`: tags/namespaces are useful for easy bulk
  event removal with `obj:off'.ns1'` or `obj:off({nil, ns1})`.
  * multiple handlers can be added for the same event and/or namespace.
  * handlers are stored in `self.__observers`.

## API

### `obj:on('event[.ns1...]', function(self, args...) ... end)` <br> `obj:on({event_name, ns1, ...}, function(self, args...) ... end)`

Register an event handler for a named event and optionally associate it with
one or more tags/namespaces.

### `obj:once(event, function(self, args...) ... end)`

Register an event handler that will only fire once.

### `obj:fire(event, args...) -> ret`

Call all event handlers registered with a particular event in the order
in which they were registered. Extra args are passed to the handlers directly.
The first handler to return a non-nil value breaks the call chain and the
value is returned back to the user. The meta-event named `'event'` is fired
afterwards (but only if the call chain was not interrupted).

If there's a method on the target object with the same name as the event,
that method will be called first, before other handlers.

### `obj:off('[event][.ns1...]')` <br> `obj:off({[event], [ns1, ...]})` <br> `obj:off()`

Remove event handlers based on the event name and/or any matching tags.
All tags must match. In the variant with a table arg, tags can be of any type.
This allows objects to register event handlers on other objects using `self`
as tag so they can later remove them with `obj:off({nil, self})`.

This method can be safely called inside any event handler, even to remove itself.
