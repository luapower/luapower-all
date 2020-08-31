
## `local uuid = require'uuid'`

Fast and dependency-free UUID library for LuaJIT.

## API

### `uuid() -> s`

Return a v4 (randomly generated) UUID.

Don't forget to seed the randomizer first, eg. with
`math.randomseed(require'time'.clock())` or what have you.

### `uuid.is_valid(s) -> true|false`

Check if an UUID is valid.
