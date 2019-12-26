---
title:    luapower
tagline:  Lua, JIT, batteries

---

![](luapower.png)

## News

<div id="news_table">loading...</div>

## Modules

<div id="package_table">loading...</div>
<div style="width: 100%; text-align: right; font-size: 80%">manifest file: [Lua](packages.lua) | [JSON](packages.json)</div>

## LUA POWER IS

  * a binary + source distribution of LuaJIT and Lua modules
  * a platform for publishing Lua modules

## FEATURES

  * __LOW-TECH__: based on http, zip, and git
  * __PORTABLE__: no install, no deploy, just run
  * __MODULAR__: each module is a separate git project
  * __ON GITHUB__: fork/pull-request-based collaboration
  * __NO DIRECTORIES__: all modules in a single directory
  * __BINARIES__ for all platforms: get code running in minutes
  * __SOURCES & BUILD SCRIPTS__: upgrade it yourself, don't wait for others
  * __PACKAGE DATABASE__: self-maintaining, auto-generated
  * __DOCUMENTED__: online browsing or offline grepping; powered by pandoc
  * __FREE__: no-strings attached

> Read [more][problem-solution] about the motivations behind these choices.

## Get Started

  1. download [luajit]
  2. choose/download wanted packages along with their listed dependencies
  3. unzip all _over the same directory_
  4. (optional) [rebuild][building] binaries
  5. run a demo: `luajit ..._demo.lua`

This will give you an instantly **portable luajit distro** that will work reagardless of where you run it from.
The luajit binary is in `bin/<your-platform>/` (cross-platform shell wrappers are in the root dir).

## Get Started / Git Way

Alternatively you can go the git way with [luapower-git] which allows you to:

  * clone/build everything in one shot
  * keep your modules up-to-date by pulling
  * [create your own modules][get-involved] and publish them

> NOTE: The listed dependencies for a package are for the modules of that package only. Associated demos and test units
can sometimes have additional dependencies which are not listed, so I better tell you now:
some test units need [unit], and most demos need [cplayer] and [glue].

> NOTE: Packages marked `dev` are either in active development or are planned for more development in the future.
In any case, they are not yet ready for public consumption. Poke around of course, just don't expect stability.


[capr]:  https://github.com/capr
[unit]:  https://github.com/luapower/unit
