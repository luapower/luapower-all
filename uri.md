
## `local uri = require'uri'`

URI parsing and formatting.

## API

------------------------------------ -----------------------------------------
`uri.format(t) -> s`                 format URI
`uri.parse(s) -> t`                  parse URI
`uri.escape(s[,res][,unres]) -> s`   escape URI fragment
`uri.unescape(s) -> s`               unescape URI fragment
`uri.parse_args(s) -> t`             parse the URI query part
`uri.format_args(t) -> s`            format the URI query part
`uri.parse_path(s) -> t`             parse the URI path part
`uri.format_path(t) -> s`            format the URI path part
------------------------------------ -----------------------------------------

### `uri.format(t) -> s`

Format a URI from a table containing the fields:
`scheme`, `user`, `pass`, `host`, `port`, `path` or `segments`,
`query` or `args`, and `fragment`.

If the field `segments` is present, it will be used instead of `path` to
format the path part of the URI. It must be a list of strings representing
the path segments, with the advantage that each segment can contain slashes
which will be properly encoded.

If the field `args` is present, it will be used instead of `query` to format
the query part of the URI with the advantage that arg keys and values can
contain the characters `&`, `=`, `?`, `#` which will be properly encoded.
The args can be given as a list of form `{key1, value1, ...}` or as a table
of form `{key -> value}`. The first form allows duplicate keys and preserves
key order while the map form lays out the keys alphabetically. Values can be
tostringables, `true` to format only the key without `=` or `false` to ignore
the key.

### `uri.parse(s) -> t`

Parse a URI of the form
`[scheme:](([//[user[:pass]@]host[:port][/path])|path)[?query][#fragment]`
into its components. The fields `segments` and `args` are present too,
and have the same meaning as for `uri.format` above (the `args` table will
have both its array part and its hash part populated).

Some edge cases and how they're handled:

--------------------- --------------------------------------------------------
`foo?a=b&a=c`         `{path='foo', args={a='c', 'a', 'b', 'a', 'c'}}`
`foo?a=`              `{path='foo', args={a='', 'a', ''}}`
`foo?=b`              `{path='foo', args={[''] = 'b', '', 'b'}}`
`foo?a`               `{path='foo', args={a=true, 'a', true}}`
`foo?=`               `{path='foo', args={[''] = '', '', ''}}`
`foo?`                `{path='foo', args={[''] = true, '', true}}`
`foo`                 `{path='foo'}`
--------------------- --------------------------------------------------------

> Note that `://:@/?#` is a valid URL.

### `uri.escape(s[,reserved][,unreserved]) -> s`

Escape all characters except the URI spec `unreserved` and `sub-delims`
characters, and the characters in the unreserved list, plus the characters
in the reserved list, if any.

### `uri.unescape(s) -> s`

Unescape escaped characters in the URI.
