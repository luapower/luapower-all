---
tagline: UNIX permissions strings
---

## `local unixperms = require'unixperms'`

### `unixperms.parse(s[, base]) -> mode, is_relative`

Parse a unix permissions string and return its binary value. The string
can be an octal number beginning with a `'0'`, or a specification of form
`'[ugo]*[-+=]?[rwxsStT]+ ...'`. `is_relative` is `true` if the permissions
do not modify the entire mask of the `base`, eg. `'+x'` (i.e. `'ugo+x'`) says
"add the execute bit for all" and it's thus a relative spec, while `'rx'`
(i.e. `'ugo=rx'`) says "set the read and execute bits for all" and it's thus
an absolute spec. `base` defaults to `0`. If `s` is not a string, `s, false`
is returned.

### `unixperms.format(mode[, opt]) -> s`

Format a unix permissions binary value to a string. `opt` can be `'l[ong]'`
(which turns `0555` into `'r-xr-xr-x'`) or `'o[ctal]'` (which turns `0555`
into `'0555'`). default is `'o'`.

