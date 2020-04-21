#!/bin/sh
cd "${0%lp}" && exec ./luajit luapower_cli.lua "$@"
