
require'xrowset'
local path = require'path'
local fs = require'fs'
local ppjson = require'prettycjson' --TODO: this is broken.

--rowsets --------------------------------------------------------------------

local rowsets = virtual_rowset(function(rs)
	function rs:select_rows(res, param_values)
		res.fields = {
			{name = 'name'},
		}
		res.pk = {'name'}
		res.rows = {}
		for name, rs in sortedpairs(rowset) do
			add(res.rows, {name})
		end
	end
end)

function rowset.rowsets()
	return rowsets:respond()
end

--xmodule --------------------------------------------------------------------

function xmodule_file(layer)
	return _('x-%s.json', layer)
end

function action.xmodule_next_gid(module)
	local file = _('x-%s-next-gid', module)
	local id = tonumber(assert(readfile(file) or '1'))
	if method'post' then
		assert(writefile(file, tostring(id + 1), nil, file..'.tmp'))
	end
	setmime'txt'
	out(module..id)
end

action['xmodule_layer.json'] = function(layer)
	layer = check(str_arg(layer))
	assert(layer:find'^[%w_%-]+$')
	local file = xmodule_file(layer)

	if method'post' then
		writefile(file, post(), nil, file..'.tmp')
	else
		return readfile(file) or '{}'
	end
end

action['sql_rowset.json'] = function(gid, ...)
	local module = check(gid:match'^[^_%d]+')
	local layer = json(check(readfile(xmodule_file(_('%s-server', module)))))
	local t = check(layer[gid])
	local rs = {}
	for k,v in pairs(t) do
		if k:starts'sql_' then
			rs[k:sub(5)] = v
		end
	end
	return sql_rowset(rs):respond()
end

