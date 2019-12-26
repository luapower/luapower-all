#!/bin/sh
if [ "$1" ]; then
    wget -qO- https://luapower.com/$1/cc
else
    wget -qO- https://luapower.com/clear_cache
fi