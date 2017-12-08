---
tagline: path manipulation
---

## `local path = require'path'`

Path manipulation library for Windows and UNIX paths. Parses all Windows
path formats including long paths (`\\?\`), device paths (`\\.\`)
and UNC paths.

## API

------------------------------------------------ ------------------------------------------------
`path.platform -> s`                             get the current platform
`path.sep([pl]) -> s`                            get the default separator for a platform
`path.dev_alias(s) -> s`                         check if a path is a Windows device alias
`path.type(s, [pl]) -> type`                     get the path type
`path.parse(s, [pl]) -> type, path[, drv|srv]`   break down a path to its basic parts
`path.format(type, path, [drv|srv], pl) -> s`    put together a path from parsed parts
`path.isabs(s, [pl]) -> is_abs, is_empty`        check if path is absolute and if it's empty
`path.endsep(s, [pl], [sep]) -> s, success`      get/add/remove the ending separator
`path.separator(s, [pl], [sep], ...) -> s`       detect/set the path separator
`path.basename(s, [pl]) -> s`                    get the last component from a path
`path.splitext(s, [pl]) -> name, ext`            split path's basename into name and extension
`path.ext(s, [pl]) -> s`                         return only the extension from `path.splitext()`
`path.dirname(s, [pl]) -> s`                     get the path without basename
`path.gsplit(s, [pl], [full]) ->iter() ->s,sep`  iterate over path's components
`path.normalize(s, [pl], [opt]) -> s`            normalize a path in various ways
`path.commonpath(p1, p2, [pl]) -> s`             get the common base path between two paths
`path.rel(s, pwd, [pl]) -> s`                    convert absolute path to relative
`path.combine(p1, p2, [pl]) -> s`                combine two paths if possible
`path.abs(s, pwd, [pl]) -> s`                    convert relative path to absolute
`path.filename(s, [pl], [repl]) -> s|nil`        validate/make-valid filename
------------------------------------------------ ------------------------------------------------

In the table above, `pl` is for platform and can be `'win'` or `'unix'` and
defaults to the current platform.

### `path.platform -> s`

Get the current platform which can be `'win'` or `'unix'`.

### `path.sep([pl]) -> s`

Get the default separator for a platform which can be `\\` or `/`.

### `path.dev_alias(s) -> s`

Check if a path is a Windows device alias and if it is, return that alias.

### `path.type(s, [pl]) -> type`

Get the path type which can be:

  * `'abs'` - `C:\path` (Windows) or `/path` (UNIX)
  * `'rel'` - `a/b` (Windows, UNIX)
  * `'abs_long'` - `\\?\C:\path` (Windows)
  * `'abs_nodrive'` - `\path` (Windows)
  * `'rel_drive'` - `C:a\b` (Windows)
  * `'unc'` - `\\server\share\path` (Windows)
  * `'unc_long'` - `\\?\UNC\server\share\path` (Windows)
  * `'global'` - `\\?\path` (Windows)
  * `'dev'` - `\\.\path` (Windows)
  * `'dev_alias'`: `CON`, `c:\path\nul.txt`, etc. (Windows)

The empty path (`''`, which is technically invalid) comes off as type `'rel'`.

The only paths that are portable between Windows and UNIX (Linux, OSX)
without translation are type `'rel'` paths using forward slashes only which
are no longer than 259 bytes and which don't contain any control characters
(code 0-31) or the symbols `<>:"|%?*\`.

### `path.parse(s, [pl]) -> type, path[, drive|server]`

Split a path into its local path component and, depending on the path type,
the drive letter or server name.

UNC paths are not validated and can have an empty server or path.

### `path.format(type, path, [drive|server], [pl]) -> s`

Put together a path from its broken-down components. No validation is done.

### `path.isabs(s, [pl]) -> is_abs, is_empty`

Check if a path is an absolute path or not, and if it's empty or not.

__NOTE:__ Absolute paths for which their local path is `''` are actually
invalid (currently only incomplete UNC paths like `\\server` or `\\?` can be
like that). For those paths `is_empty` is `nil`.

### `path.endsep(s, [pl], [sep]) -> s, success`

Get/add/remove an ending separator. The arg `sep` can be `nil`, `true`,
`false`, `'\\'`, `'/'`, `''`: if `sep` is `nil` or missing, the ending
separator is returned (`nil` if missing), otherwise it is added or removed
(`true` means use path's separator or the default separator, `false` means
`''`). `success` is `false` if trying to add an ending separator to an empty
relative path or trying to remove it from an empty absolute path, which are
not allowed.

Multiple consecutive separators are treated as one in that they
are returned together and are replaced together.

### `path.separator(s, [pl], [sep], [default_sep], [empty_names]) -> s`

Detect or set the a path's separator (for Windows paths only).

The arg `sep` can be `nil` (detect), `true` (set to `default_sep`), `false`
(set to `default_sep` but only if both `\\` and `/` are found in the path),
`'\\'` or `'/'` (set specifically), or `nil` when `empty_names` is `false`
(collapse duplicate separators only). `default_sep` defaults to the platform
separator. Unless `empty_names` is `true`, consecutive separators are
collapsed into the first one.

__NOTE:__ Setting the separator as `\` on a UNIX path may result in an
invalid path because `\` is a valid character in UNIX filenames.

### `path.basename(s, [pl]) -> s`

Get the last component from a path.
If the path ends with a separator then the empty string is returned.

### `path.splitext(s, [pl]) -> name, ext`

Split a path's basename into the name and extension parts like so:

  * `a.txt'` -> `'a', 'txt'`
  * `'.bashrc'` -> `'.bashrc', nil`
  * `a'` -> `'a', nil`
  * `'a.'` -> `'a', ''`

### `path.ext(s, [pl]) -> s`

Return only the extension from `path.splitext()`.

### `path.dirname(s, [pl]) -> s`

Get the path without basename and last separator. If the path ends with a
separator then the whole path without the separator is returned. Multiple
consecutive separators are treated as one.

### `path.gsplit(s, [pl], [full]) -> iter() -> s, sep`

Iterate over a path's local components (that is excluding prefixes like
`\\server` or `C:`). Pass `true` to the `full` arg to iterate over the
whole unparsed path. For absolute paths, the first iteration is
`'', <root_separator>`. Empty names are not iterated. Instead, consecutive
separators are returned together. Concatenating all the iterated path
components and separators always results in the exact original path.

### `path.normalize(s, [pl], [opt]) -> s`

Normalize a path by removing `.` dirs, removing unnecessary `..` dirs
(careful: this doesn't work if there are symlinks on the path!), collapsing,
normalizing or changing the separator (for Windows paths), converting
between Windows long (`\\?\`, `\\?\UNC\`) and normal paths.

The `opt` arg controls the normalization:

  * `dot_dirs` - `true` to keep `.` dirs.
  * `dot_dot_dirs` - `true` to keep the `..` dirs.
  * `separator`, `default_separator`, `empty_names` - args to pass to
  `path.separator()` (`separator` defaults to `false`, use `'leave'`
  to avoid normalizing the separators)
  * `endsep` - `sep` arg to pass to `path.endsep()` (`endsep` defaults
  to `false`, use `'leave'` to avoid removing the end separator)
  * `long` - `'auto'` (default) convert `'abs'` paths to `'abs_long'` when
  they are too long and viceversa when they are short enough (pass `true` or
  `false` to this option to force a conversion instead). Separators are
  automatically normalized to `\` when converting to a long path. Make sure
  to have dot dirs removed too when using long paths.

### `path.commonpath(p1, p2, [pl]) -> s`

Get the common base path (including the end separator) between two paths.

__BUG:__ The case-insensitive comparison for Windows doesn't work with
paths with non-ASCII characters because it's made with `string.lower()`.
Proper lowercase your paths before using this function, or patch
`string.lower()` to support utf8 lowercasing. This is not an issue if both
paths come from the same API.

### `path.rel(s, pwd) -> s`

Convert an absolute path into a relative path which is relative to `pwd`.

### `path.combine(s1, s2, pl) -> s`

Combine two paths if possible (return `nil, err` if not). Supported
combinations are between types `rel` and anything except `dev_alias`,
between `abs_nodrive` and `rel_drive`, and between `rel_drive` and `abs`
or `abs_long`. Arguments can be given in any order when the paths can only
be combined in one way.

### `path.abs(s, pwd) -> s`

Convert a relative path to an absolute path given a base dir
(this is currently an alias of `path.combine()`).

### `path.filename(s, [pl], [repl]) -> s|nil`

Validate a filename or apply a replacement function/table/string on it in
order to make it valid.

