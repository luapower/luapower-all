
local lp = require'luapower'
local glue = require'glue'

local function filelines(file)
	local t = {}
	for line in io.lines(lp.powerpath(file)) do --most time is wasted here!
		t[#t+1] = line
	end
	return t
end

local function grepfile(s0, file, maxmatches)
	local lines = filelines(file)

	--record matches
	local matches = {}
	local limited = false
	for line, s in ipairs(lines) do
		local col0 = 1
		while true do
			if #matches >= maxmatches then
				limited = true
				break
			end
			local col = s:find(s0, col0, true)
			if not col then break end
			table.insert(matches, {line = line, col = col})
			col0 = col + #s0
		end
		if limited then break end
	end

	--combine matches that are close together in chunks
	local chunks = {}
	local lastchunk, lastline
	for i,match in ipairs(matches) do
		local line = match.line
		local chunk
		if lastline and line - lastline < 10 then
			chunk = lastchunk
		else
			chunk = {line1 = line}
			table.insert(chunks, chunk)
		end
		chunk.line2 = line
		table.insert(chunk, match)
		lastline = line
		lastchunk = chunk
	end

	--create the text fragments
	for i,chunk in ipairs(chunks) do
		local line1 = glue.clamp(chunk.line1 - 2, 1, #lines)
		local line2 = glue.clamp(chunk.line2 + 2, 1, #lines)
		local dt = {}
		for line = line1, line2 do
			local col0 = 1
			local s = lines[line]
			local t = {}
			for _, match in ipairs(chunk) do
				if match.line == line then
					local col = match.col
					local s1 = s:sub(col0, col - 1)
					table.insert(t, {s = s1})
					table.insert(t, {hl = s0})
					col0 = col + #s0
				end
			end
			local s1 = s:sub(col0)
			table.insert(t, {s = s1})
			table.insert(dt, {line = line, fragments = t})
		end
		chunk.text = dt
		chunk.line1 = line1
		chunk.line2 = line2
	end

	return {matchcount = #matches, limited = limited, chunks = chunks}
end

local function grep(s0, maxmatches)
	local t = {}
	local dn, mn, fn, n = 0, 0, 0, 0
	local limited
	if s0 and s0 ~= '' then
		for pkg in pairs(lp.installed_packages()) do
			for doc, file in pairs(lp.docs(pkg)) do
				local res = grepfile(s0, file, maxmatches)
				dn = dn + 1
				n = n + res.matchcount
				if res.matchcount > 0 then
					fn = fn + 1
					limited = limited or res.limited
					table.insert(t, glue.update({
						package = pkg,
						file = file,
					}, res))
				end
			end
			for mod, file in pairs(lp.modules(pkg)) do
				--exclude built-in modules and binary files
				if file ~= true and lp.module_tags(pkg, mod).lang ~= 'C' then
					file = tostring(file)
					local res = grepfile(s0, file, maxmatches)
					mn = mn + 1
					n = n + res.matchcount
					if res.matchcount > 0 then
						fn = fn + 1
						limited = limited or res.limited
						table.insert(t, glue.update({
							package = pkg, file = file,
						}, res))
					end
				end
			end
		end
	end
	table.sort(t, function(t1, t2) return t1.matchcount > t2.matchcount end)
	return {
		results = t,
		docs_searched = dn,
		modules_searched = mn,
		file_matchcount = fn,
		matchcount = n,
		matchcount_limited = limited,
	}
end

return grep

