
local grep = require'grep'
local lp = require'luapower'

lp.luapower_dir = '../..'

local t = grep'x'
print(t.docs_searched + t.modules_searched)
