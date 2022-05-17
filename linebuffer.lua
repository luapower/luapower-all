
-- line buffer for line-based network protocols.
-- Written by Cosmin Apreutesei. Public Domain.

if not ... then require'linebuffer_test'; return end

local ffi = require'ffi'

--Based on `read(buf, maxsz) -> sz`, create the API:
--  `readline() -> s`
--  `read(maxsz) -> buf, sz`
return function(read, term, sz)

	local find_term
	if #term == 1 then
		local t = string.byte(term)
		function find_term(buf, i, j)
			for i = i, j-1 do
				if buf[i] == t then
					return true, i, i+1
				end
			end
			return false, 0, 0
		end
	elseif #term == 2 then
		local t1, t2 = string.byte(term, 1, 2)
		function find_term(buf, i, j)
			for i = i, j-2 do
				if buf[i] == t1 and buf[i+1] == t2 then
					return true, i, i+2
				end
			end
			return false, 0, 0
		end
	else
		assert(false)
	end

	--single-piece ring buffer (no wrap-around).

	assert(sz >= 1024)
	local buf = ffi.new('char[?]', sz)

	local i = 0 --index of first valid byte.
	local j = 0 --index right after last valid byte.

	local function more()
		if j == i then --buffer empty: reset.
			i, j = 0, 0
		elseif j == sz then --no more space at the end.
			if i == 0 then --buffer full.
				return nil, 'line too long'
			else --move data to make space at the end.
				ffi.copy(buf, buf + i, j - i)
				i, j = 0, j - i
			end
		end
		local n, err = read(buf + j, sz - j)
		if n == 0 then return nil, 'eof' end
		if not n then return nil, err end
		j = j + n
		return true
	end

	local function readline()
		if j == i then --buffer empty: refill.
			local ok, err = more()
			if not ok then return nil, err end
		end
		local n = 0
		while true do
			local found, line_j, next_i = find_term(buf, i + n, j)
			if found then
				local s = ffi.string(buf + i, line_j - i)
				i = next_i
				return s
			else
				n = j - i - (#term - 1)
				local ok, err = more()
				if not ok then return nil, err end
			end
		end
	end

	local function read(maxn)
		if j == i then --buffer empty: refill.
			local ok, err = more()
			if not ok then
				if err == 'eof' then return buf, 0 end
				return nil, err
			end
		end
		local n = math.min(maxn, j - i)
		local buf = buf + i
		i = i + n
		return buf, n
	end

	return {
		readline = readline,
		read = read,
	}

end
