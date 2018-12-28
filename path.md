---
tagline: path manipulation
---

## `local path = require'path'`

Path manipulation library for Windows and UNIX paths. Parses all Windows
path formats including long paths (`\\?\`), device paths (`\\.\`)
and UNC paths.

## API

---------------------------------------------------- ------------------------------------------------
`path.platform -> s`                                 get the current platform
`path.default_sep([pl]) -> s`                        get the default separator for a platform
`path.dev_alias(s) -> s|nil`                         check if a path is a Windows device alias
`path.type(s, [pl]) -> type`                         get the path type
`path.parse(s, [pl]) -> type, path[, drv|srv]`       break down a path to its basic parts
`path.format(type, path, [drv|srv], pl) -> s`        put together a path from parsed parts
`path.isabs(s, [pl]) -> is_abs, is_empty`            check if path is absolute, empty and valid
`path.endsep(s, [pl], [sep], [dsep]) -> s, ok`       get/add/remove the ending separator
`path.sep(s, [pl], [sep], ...) -> s`                 detect/set the path separator
`path.long(s, [pl], [long]) -> s|nil`                get/set a Windows long absolute path
`path.file(s, [pl]) -> s`                            get the last component of a path
`path.nameext(s, [pl]) -> name, ext`                 split `path.file()` into name and extension
`path.ext(s, [pl]) -> s`                             return only the extension from `path.nameext()`
`path.dir(s, [pl]) -> s|nil`                         get the path without the last component
`path.gsplit(s, [pl], [full]) ->iter() -> s, sep`    iterate over path's components
`path.normalize(s, [pl], [opt]) -> s`                normalize a path in various ways
`path.commonpath(s1, s2, [pl]) -> s|nil`             get the common prefix of two paths
`path.depth(s, [pl]) -> n`                           get the number of non-empty path components
`path.combine(p1, p2, [pl], [sep], [dsep]) -> s|nil` combine two paths if possible
`path.abs(s, pwd, [pl], [sep], [dsep]) -> s|nil,err` convert relative path to absolute
`path.rel(s, pwd, [pl], [sep], [dsep]) -> s|nil`     convert absolute path to relative
`path.filename(s, [pl], [repl]) -> s|nil,err,code`   validate/make-valid filename
---------------------------------------------------- ------------------------------------------------

In the table above, `pl` is for platform and can be `'win'` or `'unix'` and
defaults to the current platform.

### `path.platform -> s`

Get the current platform which can be `'win'` or `'unix'`.

### `path.default_sep([pl]) -> s`

Get the default separator for a platform which can be `\` or `/`.

### `path.dev_alias(s) -> s|nil`

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

Split a path into its _local path_ component (i.e. the part containing only
directories and files, eg. `\path` for `C:\path` or for `\\server\path`)
and, depending on the path type, the drive letter or server name.

UNC paths are not validated and can have an empty server or share path.

### `path.format(type, path, [drive|server], [pl]) -> s`

Put together a path from its broken-down components. No validation is done.

### `path.isabs(s, [pl]) -> is_abs, is_empty, is_valid`

Check if a path is an absolute path or not, if it's empty (i.e. root)
or not, and if it's valid or not.

Absolute paths for which their _local path_ is `''` are actually invalid
(currently only incomplete UNC paths like `\\server` or `\\?` can be
like that). For those paths `is_valid` is `false`.

### `path.endsep(s, [pl], [sep], [dsep]) -> s, success`

Get/add/remove an ending separator of a path. If `sep` is `nil` or missing,
the ending separator is returned (`nil` is returned if the path has no ending
separator). If `sep` is `true`, `'\\'`, `'/'`, the path is returned with an
ending separator added (`true` means use path's own separator if it has one
and failing that, use `dsep` or the default platform separator). If `sep` is
`false` or `''` the path without its ending separator is returned. `success`
is `false` if trying to add or remove the ending separator from an empty path
(note that even when that happens, the path can still be concatenated
directly to a relative path and result in a valid path).

Multiple consecutive separators are treated as one in that they
are returned together and are replaced together.

### `path.sep(s, [pl], [sep], [default_sep], [empty_names]) -> s`

Detect or set the a path's separator (for Windows paths only).

The arg `sep` can be `nil` (detect), `true` (set to `default_sep`), `false`
(set to `default_sep` but only if both `\` and `/` are found in the path,
i.e. unify), `'\\'` or `'/'` (set specifically), or `nil` when `empty_names`
is explicitly `false` (collapse duplicate separators only). `default_sep`
defaults to the platform separator. Unless `empty_names` is `true`,
consecutive separators are collapsed into the first one.

__NOTE:__ Setting the separator as `\` on a UNIX path may result in an
invalid path because `\` is a valid character in UNIX filenames.

### `path.long(s, [pl], [long]) -> s|nil`

Get/set a Windows long absolute path (one starting with `\\?\C:\`). If
`long` is `nil`, returns whether the path is a long or short Windows absolute
path (returns `nil` for all other kinds of paths). Otherwise it converts the
path, in which case `long` can be `true` (convert to long path), `false`
(convert to short path) or `'auto'` (convert to long style if too long,
or to short style if short enough).

### `path.file(s, [pl]) -> s`

Get the last component of a path. Returns `''` if the path is empty or ends
with a separator.

### `path.nameext(s, [pl]) -> name, ext`

Split a path's last component into the name and extension parts like so:

  * `a.txt'` -> `'a', 'txt'`
  * `'.bashrc'` -> `'.bashrc', nil`
  * `'a'` -> `'a', nil`
  * `'a.'` -> `'a', ''`

### `path.ext(s, [pl]) -> s|nil`

Return only the extension from `path.nameext()`.

### `path.dir(s, [pl]) -> s`

Get the path without the last component and separator. If the path ends with
a separator then the whole path without the separator is returned. Multiple
consecutive separators are treated as one. Returns `nil` for `''`, `'.'`,
`'C:'`, `'/'`, `'C:\\'` and `\\server\`. Returns `'.'` for simple filenames.

### `path.gsplit(s, [pl], [full]) -> iter() -> s, sep`

Iterate over a path's _local components_ (that is excluding prefixes like
`\\server` or `C:`). Pass `true` to the `full` arg to iterate over the
whole unparsed path. For absolute paths, the first iteration is
`'', <root_separator>`. Empty names are not iterated. Instead, consecutive
separators are returned together. Concatenating all the iterated path
components and separators always results in the exact original path.

### `path.normalize(s, [pl], [opt]) -> s`

Normalize a path by removing `.` dirs, removing unnecessary `..` dirs
(careful: this changes where the path points to if there are symlinks on
the path!), collapsing, normalizing or changing the separator
(for Windows paths), converting between Windows long (`\\?\`, `\\?\UNC\`)
and normal paths.

The `opt` arg controls the normalization:

  * `dot_dirs` - use `true` to keep `.` dirs.
  * `dot_dot_dirs` - use `true` to keep the `..` dirs.
  * `sep`, `default_sep`, `empty_names` - args to pass to `path.sep()`
  (`sep` defaults to `false`, use `'leave'` to avoid normalizing the
  separators)
  * `endsep` - `sep` arg to pass to `path.endsep()` (defaults to `false`,
  use `'leave'` to avoid removing any end separator)
  * `long` - `long` arg to pass to `path.long()` (defaults to `'auto'`,
  use `'leave'` to avoid converting between short and long paths)

__NOTE:__ If normalization results in the empty relative path `''`, then
`'.'` is returned instead.

### `path.commonpath(s1, s2, [pl]) -> s|nil`

Get the common path prefix of two paths, including the end separator if both
paths share it, or `nil` if the paths don't have anything in common.

Note that `path.commonpath('C:', 'C:\\', 'win') == nil` because the paths are
of different type even if they look like they share a common prefix.

__BUG:__ The case-insensitive comparison for Windows doesn't work with
paths with non-ASCII characters because it's made with `string.lower()`.
Proper lowercase your paths before using this function, or patch
`string.lower()` to support utf8 lowercasing. This is not an issue if both
paths are in the original letter case (eg. they come from the same API).

### `path.depth(s, [pl]) -> n`

Get the number of non-empty path components, excluding prefixes like
`C:\`, `\\server\`, etc.

### `path.combine(s1, s2, [pl], [sep], [dsep]) -> s|nil,err`

Combine two paths if possible (return `nil, err` if not). Supported
combinations are between anything except `dev_alias` and `rel` paths,
between `abs_nodrive` and `rel_drive`, and between `rel_drive` and `abs`
or `abs_long`. When the paths can only be combined in one way, paths can be
given in any order. The separator with which paths are combined is either
`sep` or if `sep` is nil it's detected and if that fails `dsep` or the
default separator is used.

### `path.abs(s, pwd, [pl], [sep], [dsep]) -> s|nil,err`

Convert a relative path to an absolute path given a base dir
(this is currently an alias of `path.combine()`).

### `path.rel(s, pwd, [pl], [sep], [dsep]) -> s|nil`

Convert an absolute path into a relative path which is relative to `pwd`.
Returns `nil` if the paths are of different types or don't have a base path
in common. The ending (back)slash is preserved if present.

### `path.filename(s, [pl], [repl]) -> s|nil,err,errcode`

Validate a filename or apply a replacement function on it in order to make it
valid. The `repl` function receives the problematic match and an error code
indicating the problem which can be one of '', '.', '..', 'dev_alias',
'char', 'length', 'evil' and it should return a replacement string or
`false/nil` if it cannot do the replacement (`'evil'` errors should generally
be replaced with `''`).
