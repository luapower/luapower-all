
## `local schema = require'schema'`

So how do you keep your database schema definition that you need to apply
to the database server on a fresh install of your application? In SQL files
containing CREATE TABLE statements? I have a better idea.

This module implements a Lua-based Data Definition Language (DDL) for RDBMS
schemas. Lua-based means that instead of a textual format like SQL DDL,
we use Lua syntax to write table definitions in, and generate an Abstract
Syntax Three (AST) from that. Using setfenv and metamethod magic we create
a language that is very readable and at the same time more expressive than
any textual format could be, giving us full programming power in an otherwise
declarative language. Basically a metaprogrammed DDL.

So why would you want to keep your database schema in the application anyway?
Here's some reasons:

* you want to generate SQL DDL scripts for different SQL dialects
from a common structured format.
* you want to diff between a live database and your "on paper" schema
to find out if the database was migrated properly.
* you want to generate schema migrations (semi-)automatically without having
to create and maintain schema versions and migration scripts.
* you want to annotate table fields with extra information for use in
data-bound widget toolkits like [x-widgets], and you don't want to do that
off-band in a separate file.
* your app has modules or extensions and you want each module to define its
own part of the app schema, including adding columns to common tables
or even adding foreign keys that reference tables from other modules.
* you want to use a boolean type in MySQL.
* you want a "shell" API for bulk DML ops like copying tables between
databases with different engines.
* use it as a base for a scriptable ETL tool.

## Usage

See `schema_std.lua` for type definitions and `webb_lang.lua`
and `webb_auth.lua` from the [webb] package for examples of
table definitions.

### How this works / caveats

#### TL;DR

Field names in `my_schema` that clash with flag names need to be quoted.
Field names, type names and flag names that clash with globals from `sc.env`
or locals from the outer scope also need to be quoted.

#### Long version

Using Lua for syntax instead of our own means that Lua's lexical rules apply,
including lexical scoping which cannot be turned off, so there are some
quirks to this that you have to know.

When calling `sc:def(my_schema)`, the function `my_schema` is run in an
environment (available at `sc.env`) that resolves every unknown keyword
to itself, so `foo_id` simply turns into `'foo_id'`. This is so that you
don't have to quote the names of fields, types or flags, unless you have to.

Because of this, you need to define `my_schema` in a clean lexical scope,
ideally at the top of your script before you declare any locals, otherwise
those locals will be captured by `my_schema` and your names will resolve to
the locals instead of to themselves. Globals declared in `sc.env` are also
captured so they can also clash with any unquoted names. Flag names can
also clash but only with unquoted field names.

If you don't want to put the schema definition at the top of the script
for some reason, one simple way to fix an unwanted capture of an outer local
is with an override: `local unsigned = 'unsigned'`.

Also because of this, you cannot use globals inside `my_schema` directly,
you'll have to _bring them into scope_ via locals, or access them through
`_G`, which _is_ available. A DDL is mostly static however so you'd rarely
need to do this.

In the future, I might write a proper DSL based on [lx] that would avoid
these issues completely, but the cost-benefit of that might be too low
compared to this relatively simple and hackable implementation.

Q: Flags and types look like the do the same thing, why the distinction?

A: Because column definitions have the form `name, type, flag1, ...`
instead of `name, flag1|type1, ...` which would have allowed a field to
inherit from multiple types but would've also made type names clash with
field names. With the first variant only flag names clash with field names
which is more acceptable.

## API

--------------------------------- -------------------------------------------
`schema.new(opt) -> sc`           create a new schema object
`schema.diff(sc1, sc2) -> diff`   find out what changed between `sc1` and `sc2`
`diff:pp()`                       pretty print a schema diff
--------------------------------- -------------------------------------------

## Background & rationale

This library came about when I needed to migrate an ecommerce database
from MySQL to Tarantool, and I figured I would kill multiple birds with
one stone, namely:

* the need to migrate both schema and data automatically between engines.
Keeping the schema in an engine-neutral format allows me to generate both
DDL code for schema formatting in Tarantol, and also a table copy function
that can copy data between engines.

* the desire to keep extra field metadata in-band in the schema definition.
Keeping that metadata separate would burden me to keep it in sync with the
schema after schema refactorings (renaming columns, etc).

* the desire to check if the schema on the databases in production
is up-to-date with the on-paper schema, and generating schema migration
commands (semi-)automatically. The "semi" part is because I'm not sure
there's an algorithm to reliably tell the difference between a column
rename and a column delete & add and other things like that.

* minor things like not having to worry about dependency order when defining
the schema (eg. defining foreign keys pointing to tables that are not yet defined).
