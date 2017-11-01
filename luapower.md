---
tagline: luapower package reflection library
---

## `local lp = require'luapower'`

This module leverages the many conventions in luapower to extract and
aggregate metadata about packages, modules and documentation and perform
various consistency checks. It gives accurate information about dependencies
between modules and packages because it actually loads the Lua modules and
tracks all `require` and `ffi.load` calls, and then it integrates that
information with the package information that it gets from git and
[multigit][luapower-git]. The entire API is memoized so it can be abused
without worrying about caching the results of the function calls.

Accompanying the library there's a command-line interface and an RPC server
which can be used to track module dependencies across multiple platforms,
run automated tests, etc.

## Module usage

The module assumes that the luapower tree is the current directory.
If that's not the case, you have say where it is:

	lp.luapower_dir = '/path/to/luapower

It also assumes that the luapower tree was cloned (see [luapower-git])
rather than just downloaded.

The API can be categorized based on the different types of things it does:

  1. getting info about packages and modules in the local luapower tree -
  this is the bulk of the API.
  2. connecting to an RPC server and using the API remotely, in order to
  collect data from other platforms.
  3. creating/updating a small database ([luapower_db.lua]) containing
  dependency information collected from different platforms.

[luapower_db.lua]: /files/luapower/luapower_db.lua

So the bulk of the API contains stuff like, eg.:

	lp.installed_packages() -> {package = true}      get installed packages
	lp.modules(package) -> {module = path}           get a package's modules

The API well documented in luapower.lua, so check that out. A quick way to
explore the capabilities of the library is to try out the command-line
interface.

## Using dependency info from other platforms

Luapower computes dependency info on-the-fly, but to get accurate dependency
info for a specific platform, luapower has to actually run on that platform
So dependency info for platform X must be acquired on platform X. But that
knowledge can be transferred and used on any other platform. This can happen
live via RPC, or by filling in a database file and moving it around.
You can also combine the two methods, so that you can update the database
file on one machine with information collected via RPC.

#### Starting an RPC server:

	$ ./luajit luapower_rpc.lua [IP] [PORT]

#### Connecting to an RPC server manually:

	lp.connect([ip], [port]) -> lp

The result is a full luapower API with the additional functions `close()`,
`restart()`, and `stop()` to control the connection and/or the server.

Each connection gets its own separate Lua state to do stuff in, so the
remote cache is lost when the connection is closed.

#### Configuring luapower to use RPC servers:

	lp.servers = {linux32 = '10.1.1.1', ...}

To use the luapower command line with RPC servers, change the servers table
in luapower.lua directly.

#### Updating the dependency database:

	lp.update_db([package], [platform])

	./luapower update-db [PACKAGE] [PLATFORM]

Passing nil (i.e. '--all' in the cmdline version) as package updates
all the packages, same with the platform (so not passing any args updates
the whole db).

