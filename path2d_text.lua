
local function to_bezier3(write, x, y, font, s)
	write('text', x, y, font, s)
end

return {
	to_bezier3 = to_bezier3,
}

