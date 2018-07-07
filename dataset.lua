
--In-memory datasets.
--Written by Cosmin Apreutesei. Public Domain.

--features:
-- row-level change tracking with the ability to apply, merge or cancel changes.
-- apply changes with failure tracking and retry.
-- sorting by multiple columns; row order is preserved with inserts and updates.
--

--[[
TODO:
- master-detail
	- ?
- grouping
- undo/redo

- memory model
- mysql model
- firebird model
	- load field metadata
	- auto-generate select queries with sorting and filtering
	- auto-generate insert, update, delete queries

]]
local glue = require'glue'

--in-memory data model

local dataset = {}

function dataset:new(fields)
	self = glue.inherit(self)
	self.fields = self:parse_fields(fields)
	self.clones = {}
	self:clear()
	return self
end

--clear the dataset and the change log
function dataset:clear()
	self.records = {}
	self.deleted = {}
	self.row_order_lost = false --flag indicating that original_row lost its meaning
end

function dataset:row_count()
	return #self.records
end

--insert a record at a specified position.
--if the dataset is sorted, the row argument is ignored and the position is that which preserves the sorting order.
function dataset:insert(row, record, nosort)
	row = row or #self.records + 1
	assert(row >= 1 and row <= #self.records + 1)
	record = record or {}
	if self.sort_cmp and not nosort then
		row = self:sorted_row(record)
	end
	record.status = 'new'
	table.insert(self.records, row, record)
end

function dataset:append(record)
	self:insert(nil, record)
end

function dataset:delete(row)
	assert(row >= 1 and row <= #self.records)
	local record = self.records[row]
	table.remove(self.records, row)
	if record.status == 'changed' then
		table.insert(self.deleted, record.old)
	elseif not record.status then --won't log 'new' records
		table.insert(self.deleted, record)
	end
end

function dataset:copy_record(row)
	local new_record = {}
	for i=1,#self.fields do
		new_record[i] = cur_record[i]
	end
	return new_record
end

function dataset:update(row, new_record, nosort)
	assert(row >= 1 and row <= #self.records)
	local new_row = self.sort_cmp and not nosort and self:sorted_row(new_record)
	local cur_record = self.records[row]
	if cur_record.status then
		new_record.status = cur_record.status
		new_record.old = cur_record.old
	else
		new_record.status = 'changed'
		new_record.old = cur_record
	end
	self.records[row] = new_record
	if new_row then
		self:move(row, new_row)
	end
end

--prepare the dataset for updating a row in-place.
function dataset:edit(row)
	local new_row = #self.records + 1
	row = row or new_row
	assert(row >= 1 and row <= new_row)
	if row == new_row then
		self:insert(new_row)
	else
		if self.records[row].status then return end --already updating
		self:update(row, self:copy_record(row), true)
	end
end

function dataset:move(row, dst_row)
	assert(row >= 1 and row <= #self.records)
	assert(dst_row >= 1 and dst_row <= #self.records)
	if row == dst_row then return end
	local record = table.remove(self.records, row)
	table.insert(self.records, dst_row, record)
	if record.status ~= 'new' then
		self.row_order_lost = true
	end
end

--merge changes back into the datset: remove any traces of record change without applying the changes
function dataset:merge()
	for row, record in ipairs(self.records) do
		record.status = nil
		record.old = nil
		record.original_row = row
		record.fail = nil
		record.fail_count = nil
	end
	self.deleted = {}
	self.row_order_lost = false
end

--cancel changes: revert the dataset to the original state, before any changes were made
function dataset:cancel()
	assert(not self.dirty)
	--remove added records and revert updated ones
	local i = 1
	while self.records[i] do
		local record = self.records[i]
		if record.status == 'new' then
			table.remove(self.records, i)
		else
			if record.status == 'changed' then
				self.records[i] = record.old
			end
			i = i + 1
		end
	end
	--add deleted records back to their original places, or at the end, if row order was lost
	for i,record in ipairs(self.deleted) do
		local row = self.row_order_lost and #self.records + 1 or record.original_row
		table.insert(self.records, row, record)
	end
	--remove traces of record change
	self:merge()
end

function dataset:exec(cmd, record) end --stub

--apply pending changes to the backend, and log failures
function dataset:apply()
	local fail_count = 0
	local success_count = 0
	for i = #self.deleted, 1, -1 do
		local record = self.deleted[i]
		if exec('delete', record) then
			table.remove(self.deleted, i)
			success_count = success_count + 1
		else
			record.fail = true
			record.fail_count = (record.fail_count or 0) + 1
			fail_count = fail_count + 1
		end
	end
	for row,record in ipairs(self.records) do
		if record.status then
			if exec(record.status == 'new' and 'insert' or 'update', record) then
				record.status = nil
				record.old = nil
				record.original_row = row
				record.fail = nil
				success_count = success_count + 1
			else
				record.fail = true
				record.fail_count = (record.fail_count or 0) + 1
				fail_count = fail_count + 1
			end
		end
	end
	local partial_merge = success_count > 0 and self.fail_count > 0
	self.row_order_lost = partial_merge or self.row_order_lost
	return self.fail_count == 0, fail_count, success_count
end

--field-based access

function dataset:parse_fields(fields)
	if type(fields) == 'string' then
		local t = {}
		local i = 1
		for name in glue.gsplit(fields, ',') do
			name = glue.trim(name)
			local field = {
				name = name,
				index = i,
				lt_cmp = nil, --lt comparator: use default
				eq_cmp = nil, --eq comparator: use default
			}
			t[name] = field --index field def by name
			t[i] = field --index field def by index
			i = i + 1
		end
		return t
	else
		return fields
	end
end

function dataset:col(field_name)
	return self.fields[field_name].index
end

function dataset:get(row, field_name)
	return self.records[row][self:col(field_name)]
end

function dataset:set(row, field_name, value)
	assert(row >= 1 and row <= #self.records)
	assert(self.records[row].status)
	self.records[row][self:col(field_name)] = value
end

function dataset.lt_cmp(v1, v2) --default less-than value comparator
	return v1 < v2
end

function dataset.gt_cmp(v1, v2) --default greater-than value comparator
	return v2 < v1
end

function dataset.eq_cmp(v1, v2) --default equals-to value comparator
	return v1 == v2
end

function dataset:field_eq_cmp(field) --eq value comparator for a field
	local eq = self.fields[field].eq_cmp or self.eq_cmp
	local col = self.fields[field].index
	return function(rec1, rec2)
		return eq(rec1[col], rec2[col])
	end
end

function dataset:field_lt_cmp(field, dir) --lt value comparator for a field and direction
	dir = dir or 'asc'
	assert(dir == 'asc' or dir == 'desc')
	local lt
	if dir == 'asc' then
		lt = self.fields[field].lt_cmp or self.lt_cmp
	else
		lt = self.fields[field].gt_cmp or self.gt_cmp
	end
	local col = self.fields[field].index
	return function(rec1, rec2)
		return lt(rec1[col], rec2[col])
	end
end

function dataset:record_lt_cmp(arg) --lt record comparator from a sorting specification

	local t = {} --{eq_cmp1, lt_cmp1, ...}
	for i = 1, #arg, 2 do
		local field, dir = arg[i], arg[i+1]
		t[#t+1], t[#t+2] = self:field_eq_cmp(field), self:field_lt_cmp(field, dir)
	end

	--simple case: compare a single column directly
	if #t == 2 then
		return t[2] --lt cmp
	end

	--complex case: compare multiple columns recursively
	local function cmp(rec1, rec2, i)
		i = i or 1
		if i > #t then
			return false --all fields are equal
		end
		local eq, lt = t[i], t[i+1]
		if eq(rec1, rec2) then
			return cmp(rec1, rec2, i + 2) --tail call
		else
			return lt(rec1, rec2)
		end
	end

	return cmp
end

function dataset:parse_sort_spec(arg) --parse 'field1[:asc|:dsc], ...' -> {field_name, 'asc'|'dsc', ...}
	local t = {}
	for s in glue.gsplit(arg, ',') do
		s = glue.trim(s)
		local field, dir = s:match'^([^%:]+):?(.*)$'
		if dir == '' then dir = 'asc' end
		t[#t+1], t[#t+2] = field, dir
	end
	return t
end

--sort by one or more fields or with a custom function.
--cmp is either a sorting specification expressed as a string or table, or a record comparator function.
--if called without arguments and there's a sorting comparator current, the dataset is re-sorted with that.
function dataset:sort(cmp)
	if cmp then
		if type(cmp) == 'string' then
			cmp = self:parse_sort_spec(cmp)
		end
		--reset the list of sort fields
		self.sort_fields = {}
		for i=1,#cmp,2 do
			table.insert(self.sort_fields, cmp[i])
		end
		--reset the informative sorted flag for each field
		for i,field in ipairs(self.fields) do
			field.sorted = nil
		end
		for i=1,#cmp,2 do
			local field, dir = cmp[i], cmp[i+1]
			self.fields[field].sorted = dir
		end
		cmp = self:record_lt_cmp(cmp)
	else
		cmp = self.sort_cmp
	end
	self.sort_cmp = cmp
	table.sort(self.records, self.sort_cmp)
	self.row_order_lost = true
end

--binary search over sorted rows

local function sorted_row_recursive(rec, records, cmp, i, j)
	local m = math.floor((i + j) / 2 + 0.5)
	if cmp(rec, records[m]) then
		return m == i and i or sorted_row_recursive(rec, records, cmp, i, m - 1) --tail call
	else
		return m == j and j + 1 or sorted_row_recursive(rec, records, cmp, m + 1, j) --tail call
	end
end

local function sorted_row(rec, records, cmp)
	if #records == 0 then return 1 end
	return sorted_row_recursive(rec, records, cmp, 1, #records)
end

--find a record's position in a sorted dataset, if that record is to be inserted into the dataset
function dataset:sorted_row(rec)
	return sorted_row(rec, self.records, self.sort_cmp)
end




function dataset:record_eq_cmp(arg) --eq record comparator for a list of fields

	--custom comparator: return it
	if type(arg) == 'function' then
		return arg
	end

	local t = {} --{eq_cmp1, ...}
	if type(arg) == 'string' then --spec of form 'field1, ...'
		for s in glue.gsplit(arg, ',') do
			s = glue.trim(s)
			t[#t+1] = self:field_eq_cmp(field)
		end
	else --spec of form {field_name, ...}
		for _, field in ipairs(arg) do
			t[#t+1] = self:field_eq_cmp(field)
		end
	end

	--simple case: compare a single column directly
	if #t == 1 then
		return t[1]
	end

	--complex case: compare multiple columns
	local function cmp(rec1, rec2)
		for i = 1, #t do
			if not t[i](rec1, rec2) then
				return false
			end
		end
		return true
	end

	return cmp
end


--TODO: sub-groups
function dataset:group(cmp)
	self:sort(cmp)
	local eq = self:record_eq_cmp(self.sort_fields)
	local rec1 = self.records[1]
	local row1 = 1
	local row2 = 1
	for i = 2, #self.records do
		local rec2 = self.records[i]
		if eq(rec1, rec2) then
			row2 = i
		else
			self:make_group(row1, row2)
			row1 = i
			row2 = i
		end
		rec1 = rec2
	end
end


function dataset:clone()
	local ds = self:new(self.fields)
	--copy records as references
	for i,rec in ipairs(self.records) do
		ds.records[i] = rec
	end
	self.clones[ds] = true
end


if not ... then

local ds = dataset:new()

--not tracking deleting new records
ds:clear()
ds:insert()
assert(ds.records[1].status == 'new')
ds:delete(1)
assert(#ds.records == 0)
assert(#ds.deleted == 0)

--tracking deleting existing records and cancelling
ds:clear()
ds:insert()
ds:merge()
ds:delete(1)
assert(#ds.records == 0)
assert(ds.deleted[1].original_row == 1)
ds:cancel()
assert(not ds.records[1].status)
assert(#ds.deleted == 0)

--tracking updates and cancelling
ds:clear()
ds:insert()
ds:merge()
ds:update(1, {})
assert(ds.records[1].old)
assert(ds.records[1].status == 'changed')
ds:cancel()
assert(not ds.records[1].old)
assert(not ds.records[1].status)

--sorting
ds = dataset:new('id,name,descr')
for i=40000,1,-4 do
	ds:append{i-3,'foo','bla bla bla'}
	ds:append{i-1,'bar','bla bla bla'}
	ds:append{i-2,'bar','bla bla bla'}
	ds:append{i-0,'zab','bla bla bla'}
end
assert(ds:row_count() == 40000)
ds:merge()
ds:sort('name:desc,id:desc')

--row of sorted record
local function cmp(a, b) return a < b end
assert(sorted_row('a', {'b'}, cmp) == 1)
assert(sorted_row('b', {'a'}, cmp) == 2)
assert(sorted_row('a', {'a', 'b'}, cmp) == 2)
assert(sorted_row('a', {'a', 'a', 'a', 'b'}, cmp) == 4)
assert(sorted_row('b', {'a', 'c'}, cmp) == 2)
assert(sorted_row('d', {'a', 'c'}, cmp) == 3)

end

return dataset
