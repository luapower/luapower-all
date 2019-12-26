---
title:   API design
tagline: how to design friendly APIs
---

## The golden rule

Design your APIs from the point of view of the user, not to satisfy implementation requirements. Start with the usage code first. Real usage code, not fake usage code like unit tests. This is probably the number one reason why APIs suck, because their authors haven't put themselves in the shoes of the user to really see how it feels.

## Compact your API

Structuring your API semantically makes it easier to learn and later to recall because humans work best with semantic hierarchies. Here's a few techniques you can use:

  * group functions into namespaces (the easy one)
  * group semantic variations into a single function using parameter polymorphism (aka function overloading)

Lua uses both of these techniques to extremes, making its API seem much smaller than it actually is, eg. by carefully shelving even the most basic functions like `table.insert` into their proper namespaces, or cramming multiple variations for reading from a file into a single function, `file:read()` with a `mode` argument with values that form a small namespace of their own and are cleverly mnemonic.

Note that semantic hierarchies are different than classification hierarchies. In terms of helping with remembering, the first is good, the second is bad. Eg. `file:read(mode)` creates a semantic hierarchy file -> read -> mode because each level in the hierarchy contains a different _class_ of concepts (file object -> file method -> mode parameter). Memory is helped by this association. But `urllib.parse.urlparse` is a classification hierarchy, which although a logical one to make from the implementation point of view, the fact that `urlparse` is to be found under the `parse` sub-namespace is completely arbitrary from the user's pov. and thus hard to remember.

## Caveats of function overloading

Dispatching based on select('#', ...) means there's now a difference between passing a nil as the last argument or not passing that argument at all which can lead to subtle bugs. Eg. if function `f` is sensitive to the number of arguments passed, the expression `f(a,b,c,g())` is now sensitive to whether `g()` returns nil or nothing which can lead to hard to find bugs since many functions signal a missing result value implicitly by exiting the function scope instead of calling `return nil`. It can also make it harder to wrap such a function sometimes, eg. to cap a depth variable with an optional maximum value you can't just write `depth = math.min(depth, maxdepth)`, instead you have to write `depth = math.min(depth, maxdepth or depth)`.

Dispatching based on type can create ambiguities when passing objects with metamethods, eg. a function that can use either a table or an iterator to get its data would have to decide on how it would use a callable table (which eg. modules and classes sometimes are). Again, analyze the usage scenarios to decide: if they lead to a clear choice, the ambiguity is resolved, if not, avoid the overloading.

Make argument optional only when it doesn't leave you wondering what the default is, eg. as the default separator for a `split()` function would. Contrast with `table.concat` for which the default separator is implied by the verb.

Avoid boolean flag arguments, you can never tell what they stand for by looking at the code, eg. `fileopen(filename, mode = '*b' or '*t')` not `fileopen(filename, is_binary)` which could just as well be `fileopen(filename, is_text)` and you wouldn't know which by looking at a code like: `fileopen('file', false)`. On the other hand, it's ok to use use boolean for on/off enable/disable switches. Avoid inverted switches though where `true` means "disabled". Even when "disabled" is the default value it's usually better to disambiguate on `nil` rather than make an inverted flag.

Don't close your semantic options with generalized rules like "arguments should never/always be coerced" or "mutating operations should never return a value". A function's behavior and signature is dictated by its usage patterns which may be idiosyncratic and thus make generalized rules seem arbitrary. Eg. `t = update({}, t)` works better than `tt = {}; update(tt, t); t = tt`.

## Convention over configuration

Don't make it configurable if it affects portability, eg. a table serialization function that generates Lua code can be made to generate locale-dependent identifier keys that Lua 5.2 would refuse to load. Instead of making this choice a configuration option, it's better to just generate ascii identifier keys.

Don't make it configurable if there's a clear best choice between alternatives, even if that would upset some users. Avoid compulsive customization. Best to add in customization options after presented with use cases from users, and use them to justify and document each option.

## Virtualization is overrated

Lua doesn't have the virtualization capabilities of some of the more extreme OO languages like Eiffel. In these languages you have enough hooks to achieve semantic equivalence of the native types and it's not easy to subvert the virtualization, making libraries mostly work automatically with the new types. This model is incompatible with Lua for practical reasons. The high performance standard Lua has set to follow is enough of a show-stopper: hooks are expensive to check and many standard utilities exploit implementation details for performance. It is also a broken model philosophically because abstractions leak, like how `1/0` breaks when LUA_NUMBER is int, or `#` lacking a good definition for a utf-8 string. It's also because of Lua's philosophy of "mechanism not policy" that you don't even have a clear (semantic or behavioral) definition of what exactly an array is. The Lua standard library is also hostile to virtualization, typechecking arguments and refusing to check hooks all over the place. If still not convinced, search the Lua mailing list for "`__next`". I don't know why they even bothered with `__pairs` and `__ipairs`. This clearly isn't going anywhere.

That being said, there _are_ patterns of virtualization that you should care for. In particular, callable tables and userdata are common enough that typechecking for functions should be made with `callable(f)` (a function which I just made up which checks for `__call`) instead of `type(f)=='function'`. Virtualized functions work because the API of a function (i.e. what you can do with it) is almost leak-free: except for dumping and loading, all you can do with a function is call it and pass it around.
