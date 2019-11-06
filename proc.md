---
tagline: processes and IPC
---

## `local proc = require'proc'`

A library for creating, controlling and communicating with child processes.
Works on Windows, Linux and OSX.

## API

------------------------------------------------ -----------------------------
`proc.exec(cmd,[args],[env],[cur_dir]) -> p`     spawn a child process
`proc.exec_luafile(file,[args],...) -> p`        spawn a process running a Lua script
`p:kill()`                                       kill process
`p:exit_code() -> code | nil,'active'|'killed'`  get process status or exit code
`p:forget()`                                     close process handles
`proc.env(k) -> v`                               get env. var
`proc.setenv(k, v)`                              set env. var
`proc.setenv(k)`                                 delete env. var
`proc.env() -> env`                              get all env. vars
------------------------------------------------ -----------------------------

### `proc.exec(cmd,[args],[env],[cur_dir]) -> p`

Spawn a child process and return a process object to query and control the
process.

  * `cmd` is the filepath of the executable to run.
  * `args` is an array of strings representing command-line arguments.
  * `env` is a table of environment variables (if not given, the current
  environment is inherited).
  * `cur_dir` is the directory to start the process in.

## Programming Notes

* only use uppercase env. var names because like file names, env. vars
  are case-sensitive on POSIX, but case-insensitive on Windows.
* only use exit status codes in the 0..255 range because Windows exit
  codes are int32 but POSIX codes are limited to a byte.
* if using `proc.setenv()`, use `proc.env()` to read back variables instead
of `os.getenv()` because the latter won't see the changes.
