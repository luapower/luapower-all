
re = [[
	g <- tokens

	tokens <- 
]]

local function parse(file)
	local t = {}
	for s in io.lines(file) do
		if s:find'^%s*#' then
			local s, rest = s:match'^%s*#([a-zA-Z_]+)(.*)'
			if s == 'if' then
				rest = 
			elseif s == 'ifdef' then
			elseif s == 'ifndef' then
			elseif s == 'elif' then
			elseif s == 'else' then

			elseif s == 'endif' then

			elseif s == 'include' then
				--
			end
		end
	end
	return t
end

return {
	parse = parse,
}
