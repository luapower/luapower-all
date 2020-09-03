
-- Fast and dependency-free UUID library for LuaJIT.
-- Written by Thibault Charbonnier. MIT License.

local bit = require 'bit'
local tohex = bit.tohex
local band = bit.band
local bor = bit.bor

local _M = {}

--validation
do
	local match = string.match
	local d = '[0-9a-fA-F]'
	local p = '^' .. table.concat({
		d:rep(8),
		d:rep(4),
		d:rep(4),
		'[89ab]' .. d:rep(3),
		d:rep(12)
	}, '%-') .. '$'

	function _M.is_valid(str)
		if type(str) ~= 'string' or #str ~= 36 then
			return false
		end
		return match(str, p) ~= nil
	end
end

-- v4 generation
do
	local fmt = string.format
	local random = math.random

	function _M.generate_v4()
		return (fmt('%s%s%s%s-%s%s-%s%s-%s%s-%s%s%s%s%s%s',
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),

					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),

					tohex(bor(band(random(0, 255), 0x0F), 0x40), 2),
					tohex(random(0, 255), 2),

					tohex(bor(band(random(0, 255), 0x3F), 0x80), 2),
					tohex(random(0, 255), 2),

					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2),
					tohex(random(0, 255), 2)))
	end
end

if not ... then
	local t = {}
	for j = 1, 1e4 do
		math.randomseed(require'time'.clock())
		for i = 1, 1e6 do
			local uuid = _M.generate_v4()
			if i == 1 then
				print(uuid)
			end
			assert(not t[uuid])
			t[uuid] = true
		end
		print(j..'M')
	end
end

return setmetatable(_M, {
	__call = _M.generate_v4
})
