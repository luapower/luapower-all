local SG = require'sg_cairo'
local pp = require'pp'
local glue = require'glue'

local TSG = glue.update({}, SG)

for k,f in pairs(SG) do
	if type(f) == 'function' then
		TSG[k] = function(self,...)
			local t,n = {...}, select('#',...)
			for i=1,n do t[i] = tostring(pp.format(t[i], nil, {})) end
			print(k..'('..table.concat(t, ', ')..')')
			return f(self,...)
		end
	end
end

return TSG
