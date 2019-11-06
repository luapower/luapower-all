---
tagline: rsync algorithm in Lua
---

## `local rsync = require'rsync'`

The [RSYNC algorithm](https://rsync.samba.org/tech_report/) in Lua.

This library can be used to synchronize similar-but-not-identical files
between two machines with little bandwidth costs. This implementation is
CPU-bound on Gigabit networks even with a good CPU.

## API

----------------------------------------- -----------------------------------------
__stream-based API__

`rsync:gen_sigs_file(read, write          compute and save block signatures
[, block_len]) -> sig_count`

`rsync:load_sigs_file(read) -> sigs`      load block signatures

`rsync:gen_deltas_file(read, sigs,        compute and save file differences
write[, block_len]) -> false_alarms`

`rsync:patch_file(read_delta,             patch original file with file differences
seek, read, write[, block_len])`

__config__

`rsync:new([config]) -> rsync`            new rsync module with optional overrides

`rsync.block_len`                         default block length (1024)f_at

`rsync.mem_len`                           default buffer length (64K)

`rsync:weak_sum() -> sum`                 create a weak sum digest (default is rolling sum in Lua)

`rsync:strong_sum() -> sum`               create a strong sum digest (default is [blake2.blake2sp_digest][blake2])
----------------------------------------- -----------------------------------------

The file functions operate on abstract read and write functions:

  * `read(buf, len) -> read_len` assumed to read at most `len` bytes into
  `buf`, returns 0 to signal EOF, raises errors on failure.
  * `write(buf, len)` assumed to always write exactly `len` bytes from `buf`.
  should raise an error otherwise.

Callbacks are not allowed to yield but they can use [coro] for control inversion.

## HOWTO

To update file1 on machine1 from the updated file1 on machine2,

  * First call `rsync:gen_sigs_file()` on machine1 with a `read` function
  that reads file1 and with a `write` function that sends its bytes to
  machine2.
  * On machine2 call `rsync:load_sigs_file()` with a `read` function that
  reads the bytes sent through the network from machine1.
  * Then (still on machine2) call `rsync:gen_deltas_file()` with the
  signatures got from the previous step and a `read` function that reads
  file1 and a `write` function that sends its bytes to machine1.
  * Finally on machine1, call `rsync:patch_file()` with a `read_delta`
  function that reads the bytes sent through the network from machine1,
  a `seek(offset)` function that seeks in file1, a `read` function that
  reads from file1, and a `write` function that writes the resulting bytes
  to a new file. The optional arg `block_len`, if given, should be identical
  on all calls.
