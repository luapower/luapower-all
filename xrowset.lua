
--Server-side rowset counterpart for x-widgets rowsets.
--Written by Cosmin Apreutesei. Public Domain.

local errors = require'errors'
local catch = errors.catch
local raise = errors.raise

rowset = {}

action['rowset.json'] = function(name, ...)
	return check(rowset[name])(...)
end

function virtual_rowset(init, ...)

	local rs = {}

	rs.can_edit = true
	rs.can_add_rows = true
	rs.can_remove_rows = true
	rs.can_change_rows = true

	function rs:load(param_values)
		local res = {
			can_edit = rs.can_edit,
			can_add_rows = rs.can_add_rows,
			can_remove_rows = rs.can_remove_rows,
			can_change_rows = rs.can_change_rows,
			pk = rs.pk,
			id_col = rs.id_col,
			params = rs.params,
		}
		rs:select_rows(res, param_values)
		return res
	end

	function rs:validate_field(name, val)
		local validate = rs.validators and rs.validators[name]
		if validate then
			return validate(val)
		end
	end

	function rs:validate_fields(values)
		local errors
		for k,v in sortedpairs(values) do --TODO: get these pre-sorted in UI order!
			local err = rs:validate_field(k, v)
			if type(err) == 'string' then
				errors = errors or {}
				errors[k] = err
			end
		end
		return errors
	end

	local function db_error(err, s)
		return config'hide_errors' and s or s..'\n'..err.message
	end

	function rs:can_add_row(values)
		if not rs.can_add_rows then
			return false, 'adding rows not allowed'
		end
		local errors = rs:validate_fields(values)
		if errors then return false, nil, errors end
	end

	function rs:can_change_row(values)
		if not rs.can_change_rows then
			return false, 'updating rows not allowed'
		end
		local errors = rs:validate_fields(values)
		if errors then return false, nil, errors end
	end

	function rs:can_remove_row(values)
		if not rs.can_remove_rows then
			return false, 'removing rows not allowed'
		end
	end

	function rs:apply_changes(changes)

		local res = {rows = {}}

		for _,row in ipairs(changes.rows) do
			local rt = {type = row.type}
			if row.type == 'new' then
				local can, err, field_errors = rs:can_add_row(row.values)
				if can ~= false then
					local ok, affected_rows, id = catch('db', rs.insert_row, rs, row.values)
					if ok then
						if (affected_rows or 1) == 0 then
							rt.error = S('row_not_inserted', 'row not inserted')
						else
							if id then
								local id_col = assert(changes.id_col)
								row.values[id_col] = id
								rt.values = {[id_col] = id}
							end
							if rs.select_row then
								local ok, values = catch('db', rs.select_row, rs, row.values)
								if ok then
									if values then
										rt.values = values
									else
										rt.error = S('inserted_row_not_found',
											'inserted row could not be selected back')
									end
								else
									local err = values
									rt.error = db_error(err,
										S('select_inserted_row_error',
											'db error on selecting back inserted row'))
								end
							end
						end
					else
						local err = affected_rows
						rt.error = db_error(err,
							S('insert_error', 'db error on inserting row'))
					end
				else
					rt.error = err or true
					rt.field_errors = field_errors
				end
			elseif row.type == 'update' then
				local can, err, field_errors = rs:can_change_row(row.values)
				if can ~= false then
					local ok, affected_rows = catch('db', rs.update_row, rs, row.values)
					if ok then
						if rs.select_row_update then
							local ok, values = catch('db', rs.select_row_update, rs, row.values)
							if ok then
								if values then
									rt.values = values
								else
									rt.remove = true
									rt.error = S('updated_row_not_found',
										'updated row could not be selected back')
								end
							else
								local err = values
								rt.error = db_error(err,
									S('select_updated_row_error',
										'db error on selecting back updated row'))
							end
						end
					else
						local err = affected_rows
						rt.error = db_error(err, S('update_error', 'db error on updating row'))
					end
				else
					rt.error = err or true
					rt.field_errors = field_errors
				end
			elseif row.type == 'remove' then
				local can, err, field_errors = rs:can_remove_row(row.values)
				if can ~= false then
					local ok, affected_rows = catch('db', rs.delete_row, rs, row.values)
					if ok then
						if (affected_rows or 1) == 0 then
							rt.error = S('row_not_removed', 'row not removed')
						else
							if rs.select_row then
								local ok, values = catch('db', rs.select_row, rs, row.values)
								if ok then
									if values then
										rt.error = S('rmeoved_row_found',
											'removed row is still in db')
									end
								else
									local err = values
									rt.error = db_error(err,
										S('select_removed_row_error',
											'db error on selecting back removed row'))
								end
							end
						end
					else
						local err = affected_rows
						rt.error = db_error(err,
							S('delete_error', 'db error on removing row'))
					end
				else
					rt.error = err or true
					rt.field_errors = field_errors
				end
				rt.remove = not rt.error
			else
				assert(false)
			end
			add(res.rows, rt)
		end

		return res
	end

	function rs:respond()
		if method'post' then
			return rs:apply_changes(post())
		else
			return rs:load(json(args'params'))
		end
	end

	init(rs, ...)

	if not rs.insert_row then rs.can_add_rows    = false end
	if not rs.update_row then rs.can_change_rows = false end
	if not rs.delete_row then rs.can_remove_rows = false end

	return rs
end

