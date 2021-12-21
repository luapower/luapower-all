---
tagline: procedural web framework in Lua
---

## Status

Webb is a _procedural_ web framework, which is a very alien way to program
for most web developers, so I expect the general interest in this library
to be exactly zero. So there will be no stable releases and no formal
documentation (there's sparse documentation in the source code).

## Features

* filesystem decoupling (virtual files and actions, IOW you can have an
entire web app in a single Lua file)
* action-based routing with multi-language URLs
* http error responses via exceptions
* file serving with cache control
* output buffering stack
* rendering with mustache templates, LuaPages and Lua scripts
* html language filtering
* js and css bundling with .cat files
* email sending with popular email sending providers
* standalone operation without a web server for debugging and offline scripts
* mysql module with macros and param substitution
* SPA module with client-side action-based routing and mustache rendering
