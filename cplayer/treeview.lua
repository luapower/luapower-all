local player = require'cplayer'

local function count_open_nodes(nodes, open_nodes)
	local count = 0
	for i,node in ipairs(nodes) do
		if type(node) == 'table' then
			if open_nodes[node] then
				count = count + 1 + count_open_nodes(node, open_nodes)
			end
		else
			count = count + 1
		end
	end
	return count
end

local function do_open_nodes(nodes, open_nodes, indent, f)
	for i,node in ipairs(nodes) do
		f(node, indent)
		if type(node) == 'table' and open_nodes[node] then
			do_open_nodes(node, open_nodes, indent + 1, f)
		end
	end
end


function player:treeview(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local nodes = assert(t.nodes, 'nodes missing')
	local state = t.state or {
		open_nodes = {},
	}
	local row_h = 24
	local indent_w = 24

	local n = count_open_nodes(nodes, state.open_nodes)
	local ch = n * row_h
	local cw = w

	local cx, cy, bx, by, bw, bh = self:scrollbox{
		id = id .. '_scrollbox',
		x = x, y = y, w = w, h = h,
		cw = cw,
		ch = ch,
		cx = state.cx,
		cy = state.cy,
		vscroll = 'auto',
		hscroll = 'never',
	}

	state.cx = cx
	state.cy = cy

	local i = 1
	do_open_nodes(nodes, state.open_nodes, 0, function(node, indent)
		local name = type(node) == 'table' and (node.name or 'unnamed') or node
		self:textbox(x + indent * indent_w, y + i * row_h, w, row_h, name, t.font, 'normal_fg', 'left', 'center')
		i = i + 1
	end)

	return state
end

if not ... then require'cplayer.widgets_demo' end


