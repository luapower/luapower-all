local glue = require'glue'
local dataset = require'dataset'

local cursor = {}

function cursor:new(dataset)
	return glue.inherit({
		dataset = dataset,
		row = 0,
		editing = false,
		changed = false,
	}, self)
end

function cursor:move(row)
	row = math.min(math.max(row, 1), self.dataset:row_count() + 1)
	if self.editing then
		if self.changed then
			self:save()
		else
			self:cancel()
		end
	end
	self.row = row
end

function cursor:edit()
	if self.editing then return end
	if self.row <= self.dataset:row_count() then
		self.dataset:update(self.row)
	else
		self.dataset:insert(self.row)
	end
	self.editing = true
end

function cursor:save()
	if not self.editing then return end
	self.dataset:apply()
end

function cursor:cancel()
	if not self.editing then return end
	self.dataset:cancel()
end

function cursor:get(field_name)
	return self.dataset:get(self.row, field_name)
end

function cursor:set(field_name, value)
	self:edit()
	self.dataset:set(self.row, field_name, value)
	self.changed = true
end


if not ... then

local ds = dataset:new()
local c = cursor:new(ds)


end


return cursor
