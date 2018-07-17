
--google fonts font selector.
--Written by Cosmin Apreutesei. Public Domain.

--Requires: git clone https://github.com/google/fonts media/fonts/gfonts.

local fs = require'fs'
local glue = require'glue'
local pp = require'pp'

local gfonts = {}

gfonts.root_dir = 'media/fonts/gfonts'

local function path(dir, file)
	return (dir or gfonts.root_dir) .. (file and '/' .. file or '')
end

local function normal_name(s)
	return s and glue.trim(s):lower():gsub('[%s%-_]+', '_')
end

local function parse_metadata_file(dir, file, fonts)
	file = file or 'METADATA.pb'
	fonts = fonts or {}
	local font
	for s in io.lines(path(dir, file)) do
		if s:find'^fonts {' then
			assert(not font)
			font = {}
		elseif s:find'^}' then
			assert(font)
			local name = normal_name(font.name)
			local fname = normal_name(font.full_name)
			local style = font.style:lower()
			fonts[name] = fonts[name] or {}
			fonts[fname] = fonts[fname] or {}
			fonts[name][style] = fonts[name][style] or {}
			fonts[fname][style] = fonts[fname][style] or {}
			local t = {
				path = path(dir, font.filename):sub(#gfonts.root_dir + 2),
				weight = font.weight,
			}
			table.insert(fonts[name][style], t)
			if fname ~= name then
				table.insert(fonts[fname][style], t)
			end
			font = nil
		elseif font then
			local k,v = assert(s:match'^(.-):(.*)$')
			k = glue.trim(k)
			v = glue.trim(v)
			if k ~= '' then
				if v:find'^"' then
					v = assert(v:match'^"(.-)"$')
				else
					v = assert(tonumber(v))
				end
				font[k] = v
			end
		end
	end
	return fonts
end

local function parse_metadata_dir(dir, dt)
	dir = path(dir)
	dt = dt or {}
	for name, d in fs.dir(dir) do
		if name then
			if d:is'dir' then
				parse_metadata_dir(path(dir, name), dt)
			elseif name == 'METADATA.pb' then
				parse_metadata_file(dir, name, dt)
			end
		end
	end
	return dt
end

local function parse_metadata()
	local fonts = parse_metadata_dir()
	for name, styles in ipairs(fonts) do
		for style, fonts in pairs(styles) do
			table.sort(fonts, function(f1, f2)
				return f1.weight < f2.weight
			end)
		end
	end
	return fonts
end

local fonts
function get_fonts(use_bundle)
	if not fonts then
		local mcache = path(nil, 'metadata.cache')
		if use_bundle then
			local bundle = require'bundle'
			if bundle.canopen(mcache) then
				fonts = assert(loadstring(bundle.load(mcache))())
			end
		elseif glue.canopen(mcache) then
			fonts = assert(loadfile(mcache)())
		end
		if not fonts then
			fonts = parse_metadata()
			pp.save(mcache, fonts)
		end
	end
	return fonts
end

local function closest_weight_font(fonts, weight)
	if #fonts == 0 then return end
	if #fonts == 1 then return fonts[1] end
	local w0 = fonts[1].weight
	if weight <= w0 then return fonts[1] end
	for i=2,#fonts do
		local w1 = fonts[i].weight
		if w1 >= weight then
			return w1 - weight < weight - w0 and fonts[i] or fonts[i-1]
		end
		w0 = w1
	end
	assert(false)
end

local weights = {
	thin = 100,
	extralight = 200,
	light = 300,
	normal = 400,
	regular = 400,
	semibold = 600,
	bold = 700,
	extrabold = 800,
}

function gfonts.font_file(name, weight, style, use_bundle)
	assert(name)
	name = normal_name(name)
	weight = weight or 'normal'
	if type(weight) == 'string' then
		weight = weight:lower()
	end
	weight = weights[weight] or weight
	style = (style or 'normal'):lower()

	local styles = get_fonts(use_bundle)[name]
	if not styles then return nil end
	local fonts = styles[style]
	if not fonts then return nil end
	local font = closest_weight_font(fonts, weight)
	return font and gfonts.root_dir .. '/' .. font.path
end

if not ... then
	print(gfonts.font_file('open_sans', 'semibold', 'italic', true))
end

return gfonts
