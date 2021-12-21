
--prettycjson 1.5 from https://github.com/bungle/lua-resty-prettycjson.
--Copyright (c) 2015 — 2016, Aapo Talvensaari. BSD license.

local cjson = require'cjson.safe'
local cat = table.concat
local rep = string.rep

return function(dt, lf, id, ac)
	local s, e = cjson.encode(dt)
	if not s then return s, e end
	lf, id, ac = lf or '\n', id or '\t', ac or ' '
	local i, j, k, n, r, p, q  = 1, 0, 0, #s, {}, nil, nil
	local al = ac:sub(-1) == '\n'
	for x = 1, n do
		local c = s:sub(x, x)
		if not q and (c == '{' or c == '[') then
			r[i] = p == ':' and c..lf or rep(id, j)..c..lf
			j = j + 1
		elseif not q and (c == '}' or c == ']') then
			j = j - 1
			if p == '{' or p == '[' then
				i = i - 1
				r[i] = rep(id, j)..p..c
			else
				r[i] = lf..rep(id, j)..c
			end
		elseif not q and c == ',' then
			r[i] = c..lf
			k = -1
		elseif not q and c == ':' then
			r[i] = c..ac
			if al then
				i = i + 1
				r[i] = rep(id, j)
			end
		else
			if c == '\'' and p ~= '\\' then
				q = not q and true or nil
			end
			if j ~= k then
				r[i] = rep(id, j)
				i, k = i + 1, j
			end
			r[i] = c
		end
		p, i = c, i + 1
	end
	return cat(r)
end
