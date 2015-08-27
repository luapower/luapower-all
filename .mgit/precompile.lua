local f0 --current filename
local files = {} --{filename = lines_t}
local def = {}
local fstack = {}

for s in io.stdin:lines() do
	local f = s:match'^# %d+ "(.-)"'
	if f then
		f0 = f
	else
		if not files[f0] then
			fstack[#fstack+1] = f0
			files[f0] = {}
		end

		local df = files[f0]

		local d,v = s:match'^#define%s+([_%w]+)%s+(.*)'
		if d then
			if v ~= '' and not d:find'^_(.-)_H_$' then
				if not def[f0] then
					table.insert(df, 'enum {')
				end
				table.insert(df, string.format('\t%-20s = %s,', d, v))
				def[f0] = d
			end
		else
			if def[f0] then
				table.insert(df, '};')
				def[f0] = nil
			end
			table.insert(df, s)
		end
	end
end

for f,df in pairs(files) do
	if def[f] then
		table.insert(df, '};')
	end
end

local f = io.stdout
f:write[=[
local ffi = require'ffi'
ffi.cdef[[
]=]
for _,m in ipairs(fstack) do
	f:write('\n// '..m..'\n')
	for _,s in ipairs(files[m]) do
		f:write(s..'\n')
	end
end
f:write']]\n'
f:close()
