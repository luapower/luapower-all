#!/bin/sh
pkg = "$1"; shift
[ "$pkg"] || { echo "Usage: $0 <package>"; exit 1; }
cd "$LUAPOWER_DIR" || { echo "LUAPOWER_DIR wrong or missing"; exit 1; }

git --git-dir="_git/$pkg" pull
./luajit "$WWW_DIR/update_db.lua" update "$pkg"
