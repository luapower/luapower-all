
require'xrowset'
local path = require'path'

local rowsets = virtual_rowset(function(rs)
	function rs:select_rows(res, param_values)
		res.fields = {
			{name = 'name'},
		}
		res.rows = {}
		for name, rs in sortedpairs(rowset) do
			add(res.rows, {name})
		end
	end
end)

action['xmodule.json'] = function()
	local file = path.combine(config'www_dir', 'xmodule0.json')
	if method'post' then
		writefile(file, json(post()))
	else
		return readfile(file)
	end
end

function rowset.rowsets()
	return rowsets:respond()
end
