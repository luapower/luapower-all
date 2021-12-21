--mysql table pretty printing

if not ... then require'mysql_test'; return end

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
	if v == nil then
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

local function print_result(res, minsize, print)
	local fields = {}
	for i,field in res:fields() do
		fields[i] = field.name
	end
	local rows = {}
	local aligns = {} --deduced from values
	for i,row in res:rows'n' do
		local t = {}
		for j=1,#fields do
			t[j] = format_cell(row[j])
			aligns[j] = cell_align(aligns[j], row[j])
		end
		rows[i] = t
	end
	print_table(fields, rows, aligns, minsize, print)
end

local function print_statement(stmt, minsize, print)
	local res = stmt:bind_result()
	local fields = {}
	for i,field in stmt:fields() do
		fields[i] = field.name
	end
	local rows = {}
	local aligns = {}
	while stmt:fetch() do
		local row = {}
		for i=1,#fields do
			local v = res:get(i)
			row[i] = format_cell(v)
			aligns[i] = cell_align(aligns[i], v)
		end
		rows[#rows+1] = row
	end
	stmt:close()
	print_table(fields, rows, aligns, minsize, print)
end

return {
	fit = fit,
	format_cell = format_cell,
	cell_align = cell_align,
	table = print_table,
	result = print_result,
	statement = print_statement,
}

