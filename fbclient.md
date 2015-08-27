---
tagline: firebird database client
---

## `local fb = require'fbclient'`

A complete ffi binding of the [Firebird] client library.

## Work in progress

In the meantime, you can use the [old fbclient] which is stable and complete.

##  Summary

**Connections**
------------------------------------------------------------- -------------------------------------
`fb.connect(db, [user], [pass], [charset], [port]) -> conn`   connect to a firebird server
`fb.connect(options_t) -> conn`                               connect to a firebird server
`conn:close()`                                                close the connection
------------------------------------------------------------- -------------------------------------

##  Firebird plug

  * MVCC concurrency
  * column-level character sets and collations
  * updatable views and triggers
  * selectable stored procedures
  * elegant procedural language
  * multi-database transactions
  * global temporary tables (GTEs)
  * common table expressions (CTEs)
  * asynchronous events
  * computed-by columns
  * check constraints and foreign key constraints
  * datatype domains
  * online backup and restore, remotely controlled
  * user-defined functions (UDFs)
  * full SQL-92 compliance
  * multi-process and multi-threading implementations
  * feature-full embedded edition
  * binaries for Windows, Linux and Mac
  * a real [IBExpert][IDE]
		(made by real programmers who don't have time to build a website)

If you don't need all this, there's also [bindings][mysql] for the most _popular_ database in the world.


[Firebird]:     http://www.firebirdsql.org/
[IBExpert]:     http://ibexpert.net/ibe/index.php?n=Main.IBExpertFeatures
[old fbclient]: https://code.google.com/p/fbclient/
