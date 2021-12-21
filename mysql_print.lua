
--MySQL result pretty printing.
--Written by Cosmin Apreutesei. Public Domain.

local null = require'cjson'.null

local function ellipsis(s,n)
	return #s > n and (s:sub(1,n-3) .. '...') or s
end

local align = {}

function align.left(s,n)
	s = s..(' '):rep(n - #s)
	return ellipsis(s,n)
end

function align.right(s,n)
	s = (' '):rep(n - #s)..s
	return ellipsis(s,n)
end

function align.center(s,n)
	local total = n - #s
	local left = math.floor(total / 2)
	local right = math.ceil(total / 2)
	s = (' '):rep(left)..s..(' '):rep(right)
	return ellipsis(s,n)
end

local function fit(s,n,al)
	return align[al or 'left'](s,n)
end

local function print_table(fields, rows, aligns, minsize, print)
	print = print or _G.print
	minsize = minsize or 0
	local max_sizes = {}
	for i=1,#rows do
		for j=1,#fields do
			max_sizes[j] = math.max(max_sizes[j] or minsize, #rows[i][j])
		end
	end

	local totalsize = 0
	for j=1,#fields do
		max_sizes[j] = math.max(max_sizes[j] or minsize, #fields[j])
		totalsize = totalsize + max_sizes[j] + 3
	end

	print()
	local s, ps = '', ''
	for j=1,#fields do
		s = s .. fit(fields[j], max_sizes[j], 'center') .. ' | '
		ps = ps .. ('-'):rep(max_sizes[j]) .. ' + '
	end
	print(s)
	print(ps)

	for i=1,#rows do
		local s = ''
		for j=1,#fields do
			local val = rows[i][j]
			s = s .. fit(val, max_sizes[j], aligns and aligns[j]) .. ' | '
		end
		print(s)
	end
	print()
end

local function invert_table(fields, rows, minsize)
	local ft, rt = {'field'}, {}
	for i=1,#rows do
		ft[i+1] = tostring(i)
	end
	for j=1,#fields do
		local row = {fields[j]}
		for i=1,#rows do
			row[i+1] = rows[i][j]
		end
		rt[j] = row
	end
	return ft, rt
end

local function format_cell(v)
	if v == null then
		return 'NULL'
	else
		return tostring(v)
	end
end

local function cell_align(current_align, cell_value)
	if current_align == 'left' then return 'left' end
	if type(cell_value) == 'number' or type(cell_value) == 'cdata' then return 'right' end
	return 'left'
end

function print_result(rows, cols, minsize)
	local fs = {}
	for i,col in ipairs(cols) do
		fs[i] = col.name
	end
	local rs = {}
	local aligns = {} --deduced from values
	for i,row in ipairs(rows) do
		local t = {}
		for j=1,#fs do
			t[j] = format_cell(row[j])
			aligns[j] = cell_align(aligns[j], row[j])
		end
		rs[i] = t
	end
	print_table(fs, rs, aligns, minsize)
end

return {
	fit = fit,
	format_cell = format_cell,
	cell_align = cell_align,
	table = print_table,
	result = print_result,
}

