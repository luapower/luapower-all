--SVG 1.1 parser
--[[
TODO:
	- patterns
	- radial gradient has issues
	- text
	- markers
	- constrained transforms: ref(svg,[x,y])
	- external references
	- use tag
NEVER:
	- icc colors
	- css language

]]
local glue = require'glue'
local re = require'lpeg.re'
local colors = require'svg_parser_colors'
local expat = require'expat'

local black = {type='color',0,0,0,1}
local white = {type='color',1,1,1,1}

local default_styles = { --these must be parsed values; we comment those that are the same as scene graph defaults.
	clip = 'auto',
	color = black,
	cursor = 'auto',
	display = 'inline',
	overflow = 'see prose - fuckin writers',
	--visibility = 'visible',
	--opacity = 1,
	fill = black,
	--fill_opacity = 1,
	--fill_rule = 'nonzero',
	--stroke = 'none',
	--stroke_dasharray = 'none',
	--stroke_opacity = 1,
	--stroke_miterlimit = 4,
	--stroke_width = 1,
	stop_color = black,
	--stop_opacity = 1,
	clip_path = nil,
	--clip_rule = 'nonzero',
	mask = nil,
	enable_background = 'accumulate',
	filter = nil,
	flood_color = black,
	--flood_opacity = 1,
	lighting_color = white,
}

--value parsing: input is a string and maybe some context, output is a parsed value or nil.

local function greater(x,min)
	return x and x >= min and x or nil
end

local function clamp(x,min,max)
	return x and math.max(math.min(x,max),min)
end

local function hex_color(s) --#abcdef or #abc
	if not s:find'^#' then return end
	local r,g,b
	if #s == 7 then
		r,g,b = tonumber(s:sub(2,3), 16), tonumber(s:sub(4,5), 16), tonumber(s:sub(6,7), 16)
	elseif #s == 4 then
		r,g,b = tonumber(s:sub(2,2), 16), tonumber(s:sub(3,3), 16), tonumber(s:sub(4,4), 16)
		r,g,b = r*16+r, g*16+g, b*16+b
	end
	if r and g and b then return {type = 'color', r/255, g/255, b/255, 1} end
end

local function rgb_value(s) --125 or 99%
	if s:sub(-1) == '%' then
		s = tonumber(s:sub(1,-2))
		s = s and s / 100
	else
		s = tonumber(s)
		s = s and s / 255
	end
	return clamp(s, 0, 1)
end

local function rgb_color(s) --rgb(0,128,50%)
	local r,g,b = s:match'^rgb%s*%(([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)%s*%)$'
	if not r then return end
	r,g,b = rgb_value(r), rgb_value(g), rgb_value(b)
	if r and g and b then return {type = 'color', r, g, b, 1} end
end

local function color(s) --#hex | rgb(...)
	return colors[s] or hex_color(s) or rgb_color(s)
end

local function ccolor(s, ct) --currentColor | <color>
	return s == 'currentColor' and ct.currentColor or color(s)
end

local function func_uri_and_rest(s) --url(<id>) ...
	return s:match'^url%s*%(%s*"?#([^"]*)"?%s*%)%s*(.*)'
end

local function func_uri(s, ct) --url(#<id>)
	return ct.byid[func_uri_and_rest(s)]
end

local function uri(s, ct) --#<id> | url(#<id>)
	return s and (ct.byid[s:match'^#(.*)'] or func_uri(s, ct))
end

local function nccolor(s, ct) --none | currentColor | <color>
	return s == 'none' and s or ccolor(s, ct)
end

--none | currentColor | <color> | { url(#<id>) { none | currentColor | <color> } }
local function paint(s, ct)
	local uri, alt = func_uri_and_rest(s)
	if uri then
		return ct.byid[uri] or nccolor(alt, ct)
	else
		return nccolor(s, ct)
	end
end

local units = glue.index{'em' , 'ex' , 'px' , 'in' , 'cm' , 'mm' , 'pt' , 'pc' , '%'}

local unit_scales = {
	pt = 1.25,
	pc = 15,
	mm = 3.543307,
	cm = 35.43307,
	['in'] = 90,
}

local function coord(s, ref, ct) --scalar; ct must contain: w, h, font_size. ref is a number, 'x', 'y', or 'xy'.
	if not s then return end
	local n,unit = s:match'^(.-)([a-zA-Z%%]*)$'
	n = tonumber(n)
	if unit == '' or unit == 'px' then
		return n
	elseif unit == '%' then
		if ref == 'x' then
			ref = ct.w or 0
		elseif ref == 'y' then
			ref = ct.h or 0
		elseif ref == 'xy' then
			ref = math.sqrt(ct.w^2 + ct.h^2) / math.sqrt(2)
		end
		return n * ref / 100
	elseif unit == 'em' then
		return n * ct.font_size
	elseif unit == 'ex' then
		return n * ct.font_size / 2 --assume 1em == 2ex
	elseif unit_scales[unit] then
		return n * unit_scales[unit]
	end
end

local function length(s, ref, ct) --positive scalar
	local n = coord(s, ref, ct)
	return n and n >= 0 and n or nil
end

local function dasharray(s, ct) --none | 1,5,7 -> 1,5,7,1,5,7 | 1,5,7,8
	if s == 'none' then return 'none' end
	local t = {}
	for n in s:gmatch'[^,%s]+' do
		n = length(n, 'xy', ct)
		if not n then return end
		t[#t+1] = n
	end
	if #t % 2 == 1 then --odd number of dashes, duplicate
		glue.extend(t,t)
	end
	return #t > 0 and t or 'none'
end

local function list(s, ct) --a,b,c,...
	local t = {}
	for s in s:gmatch'[^,%s]+' do
		t[#t+1] = s
	end
	return t
end

local function style_list(s) --return {style = unparsed_value}
	if not s then return end
	local t = {}
	for s in s:gmatch'[^;]+' do
		local k,v = s:match'^([^:]+):(.*)$'
		if k then
			t[glue.trim(k)] = glue.trim(v)
		end
	end
	return t
end

local transform_re = re.compile([[
	list <- (sep func)+ -> {}
	func <- ({name} s '(' s args s ')') -> {}
	name <- 'matrix' / 'translate' / 'scale' / 'rotate' / 'skewX' / 'skewY'
	args <- ( arg (sep arg)* )
	arg  <- {[0-9.e-]+} -> number
	sep  <- s ','? s
	s    <- %s*
]], {number = function(s) return tonumber(s) or 0 end})

local function transforms(s) --return {{'func', args_t, ...},...}
	--TODO: check for nil arg in array
	if not s then return end
	local t = transform_re:match(s)
	for i,t in ipairs(t) do
		if t[1] == 'skewX' then t[1] = 'skew'; t[2], t[3] = t[2], 0; end
		if t[1] == 'skewY' then t[1] = 'skew'; t[2], t[3] = 0, t[2]; end
	end
	return t
end

local path_cmd = {
	m = 'rel_move',
	M = 'move',
	l = 'rel_line',
	L = 'line',
	z = 'close',
	Z = 'close',
	h = 'rel_hline',
	H = 'hline',
	v = 'rel_vline',
	V = 'vline',
	c = 'rel_curve',
	C = 'curve',
	s = 'rel_symm_curve',
	S = 'symm_curve',
	q = 'rel_quad_curve',
	Q = 'quad_curve',
	t = 'rel_symm_quad_curve',
	T = 'symm_quad_curve',
	a = 'rel_svgarc',
	A = 'svgarc',
}

local path_argc = {
	rel_move = 2,
	move = 2,
	rel_line = 2,
	line = 2,
	close = 0,
	rel_hline = 1,
	hline = 1,
	rel_vline = 1,
	vline = 1,
	rel_curve = 6,
	curve = 6,
	rel_symm_curve = 4,
	symm_curve = 4,
	rel_quad_curve = 4,
	quad_curve = 4,
	rel_symm_quad_curve = 2,
	symm_quad_curve = 2,
	rel_svgarc = 7,
	svgarc = 7,
}

local path_re = re.compile([[
	path <- s (cmd / val)* -> {}
	cmd  <- {[mMlLzZhHvVcCsSqQtTaA]} -> command s
	val  <- { ((int? frac) / int) exp? } -> number s
	int  <- '-'? [0-9]+
	frac <- '.' [0-9]+
	exp  <- 'e' int
	s    <- [%s,]*
]], {command = path_cmd, number = function(s) return tonumber(s) or 0 end})

local function path(s) --return {cmd1, val11, ..., cmd2, val21, ...}
	if not s then return end
	local t = path_re:match(s)
	if t[1] == 'rel_move' then t[1] = 'move' end --starting with m means start with M
	if t[1] ~= 'move' then return end --must start with M or we ignore the whole path
	--convert implicit commands to explicit commands
	local dt = {}
	local i = 1
	local cmd, argc
	while i <= #t do
		if type(t[i]) == 'string' then --see if command changed
			cmd = t[i]
			i = i + 1
			argc = path_argc[cmd]
		elseif cmd == 'move' then --an implicit 'move' must be interpreted as a 'line'
			cmd = 'line'
			argc = path_argc[cmd]
		elseif cmd == 'rel_move' then --an implicit 'rel_move' must be interpreted as a 'rel_line'
			cmd = 'rel_line'
			argc = path_argc[cmd]
		end
		dt[#dt+1] = cmd
		glue.append(dt, unpack(t, i, i + argc - 1))
		i = i + argc
	end
	return dt
end

local function unescape(s)
	return (s:gsub('%%(%x%x)', function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local data_uri_re = re.compile[[
	uri     <- ('data:' type? charset? base64? data) -> {}
	type    <- {:type: [^;,]+ :}
	charset <- ';charset=' {:charset: [^;,]+ :}
	base64  <- ';base64' {:base64: '' -> 'yes' :}
	data    <- ',' {:data: .* :}
]]
local function data_uri(s) --data:[<MIME-type>][;charset=<encoding>][;base64],<data>
	if not s then return end
	local uri = data_uri_re:match(s)
	if uri.base64 then
		local b64 = require'libb64'
		uri.data = b64.decode_string(uri.data)
	else
		uri.data = unescape(uri.data)
	end
	return uri
end

local function viewBox(s) --<min-x> <min-y> <width> <height>
	if not s then return end
	local x,y,w,h = s:match'([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)'
	x,y,w,h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
	if not (x and y and w and h and w > 0 and h > 0) then return end
	return x,y,w,h
end

local preserveAspectRatio_re = re.compile([[
	spec  <- (defer align meet) -> {}
	defer <- {:defer: ('defer' s -> 'yes') / ('' -> 'no') :}
	align <- {:align: 'none' :} / xymmm
	xymmm <- 'x' {:x: mmm :} 'Y' {:y: mmm :}
	mmm   <- ('Min' / 'Max' / 'Mid') -> lower
	meet  <- {:meet: (s 'meet' / 'slice') / ('' -> 'meet') :}
	s     <- %s+
]], {lower = string.lower})

local function preserveAspectRatio(s) --[defer] <align> [<meetOrSlice>]
	return preserveAspectRatio_re:match(s or 'xMidYMax')
end

--style parsing: input is a style name and value and some context, output is a parsed style value
--or nil if the value should be inherited or it's invalid. uri references are resolved to unparsed
--xml nodes (we have to compute all styles before we can start parsing the nodes themselves).

local display_values = glue.index{
	'inline','block','list','item','run','in','compact','marker',
	'table','inline','table','table','row','group','table','header','group',
	'table','footer','group','table','row','table','column','group','table','column',
	'able','cell','table','caption','none'
}
local overflow_values = glue.index{'visible','hidden','scroll','auto'}
local visibility_values = glue.index{'visible','hidden','collapse'}
local cursor_values = glue.index{
	'auto','crosshair','default','pointer','move','e','resize',
	'ne','resize','nw','resize','n','resize','se','resize','sw','resize',
	's','resize','w','resize','text','wait','help','inherit'
}
local linecap_values = glue.index{'butt','round','square'}
local linejoin_values = glue.index{'miter','round','bevel'}

local function style(k, v, ct)
	if v == '' or v == 'inherit' then return ct.parent_style[k] end
	if k == 'fill' or k == 'stroke' then
		return paint(v, ct)
	elseif k == 'flood_color'
			or k == 'lighting_color'
			or k == 'stop_color'
	then
		return ccolor(v, ct)
	elseif k == 'fill_opacity'
			or k == 'stroke_opacity'
			or k == 'stop_opacity'
			or k == 'opacity'
			or k == 'flood_opacity'
	then
		return clamp(tonumber(v), 0, 1)
	elseif k == 'fill_rule' then
		return (v == 'nonzero' or v == 'evenodd') and v or nil
	elseif k == 'stroke_dasharray' then
		return dasharray(v, ct)
	elseif k == 'stroke_dashoffset' then
		return length(v, 'xy', ct)
	elseif k == 'stroke_linecap' then
		return linecap_values[v] and v
	elseif k == 'stroke_linejoin' then
		return linejoin_values[v] and v
	elseif k == 'stroke_miterlimit' then
		return greater(tonumber(v), 1)
	elseif k == 'stroke_width' then
		return greater(length(v, 'xy', ct), 0)
	elseif k == 'clip_path' then
		return func_uri(v, ct)
	elseif k == 'clip_rule' then
		return v == 'nonzero' or v == 'evenodd' and v or nil
	elseif k == 'mask' then
		return func_uri(v, ct)
	elseif k == 'enable_background' then
		if v == 'accumulate' or v == 'new' then return v end
		local x,y,w,h = v:match'^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+(.*)'
		x,y,w,h = tonumber(x),tonumber(y),tonumber(w),tonumber(h)
		if x and y and w and h then return {x,y,w,h} end
	elseif k == 'filter' then
		return func_uri(v, ct)
	elseif k == 'clip' then
		return
	elseif k == 'color' then
		return color(v)
	elseif k == 'cursor' then
		return cursor_values[k] or func_uri(v, ct)
	elseif k == 'display' then
		return display_values[v] and v
	elseif k == 'overflow' then
		return overflow_values[v] and v
	elseif k == 'visibility' then
		return visibility_values[v] and v
	end
end

local function update_style(dest, source, ct)
	for k,v in pairs(source) do
		k = k:gsub('-', '_')
		dest[k] = style(k, v, ct)
	end
end

local non_inheritable_styles = glue.index{
	'alignment_baseline', 'baseline_shift', 'clip', 'clip_path', 'display', 'dominant_baseline',
	'enable_background', 'filter', 'flood_color', 'flood_opacity', 'lighting_color', 'mask', 'opacity',
	'overflow', 'stop_color', 'stop_opacity', 'text_decoration', 'unicode_bidi',
}

local function compute_styles(t, ct)
	local style_list = style_list(t.attrs.style) or {}
	--compute the "current color", which replaces colors named 'currentColor', imagine that
	ct.currentColor =
			(style_list.color and style('color', style_list.color, ct)) or
			(t.attrs.color and style('color', t.attrs.color, ct)) or
			t.parent.style.color

	--bring together styles from individual attrs and style attr
	t.style = {}
	ct.parent_style = t.parent.style
	update_style(t.style, t.attrs, ct)
	update_style(t.style, style_list, ct)
	--inherit inheritable styles that weren't set from parent's computed styles
	for k,v in pairs(t.parent.style) do
		if t.style[k] == nil then
			if non_inheritable_styles[k] then
				t.style[k] = default_styles[k]
			else
				t.style[k] = v
			end
		end
	end
	for _,t in ipairs(t.children) do
		compute_styles(t, ct)
	end
end

--tag parsing: input is a xml node and some context, output is the parsed value or nil if invalid.

local tags = {} --{tag = parser}; parser(tag_t) -> new_t | nil

local function tag(t, ct) --parse a tag and memoize its parsed value
	if not t or not tags[t.tag] then return end
	if not t.parsed then
		t.parsed_value = tags[t.tag](t, ct)
		t.parsed = true
	end
	return t.parsed_value
end

local containables = glue.index{
	'svg', 'g', 'circle', 'ellipse', 'image', 'line', 'path', 'polygon', 'polyline', 'rect', 'text'
}

local function group(o, t, ct) --> tag=, transforms=, children in the array part
	o.type = 'group'
	o.transforms = transforms(t.attrs.transform)
	o.alpha = t.style.opacity
	o.hidden = t.style.visibility == 'hidden' or t.style.visibility == 'collapse' or nil
	if o.alpha == 1 then o.alpha = nil end
	for _,t in ipairs(t.children) do
		if containables[t.tag] then
			local tt = tag(t, ct)
			o[#o+1] = tt
		end
	end
	return #o > 0 and o or nil
end

function tags.svg(t, ct)
	local x = coord(t.attrs.x or '0', 'x', ct)
	local y = coord(t.attrs.y or '0', 'y', ct)
	local w = length(t.attrs.width or '100%', 'x', ct)
	local h = length(t.attrs.height or '100%', 'y', ct)
	if not (x and y and w and h) then return end
	ct.w = w
	ct.h = h
	--compute aspect ratio stuff
	local vx,vy,vw,vh = viewBox(t.attrs.viewBox)
	if not vx then vx,vy,vw,vh = x,y,w,h end
	local aspect = preserveAspectRatio(t.attrs.preserveAspectRatio)
	local sx, sy = vw and w / vw, vh and h / vh
	if aspect.align == 'none' then
		--
	elseif aspect.meet == 'slice' then
		sx = sx and math.max(sx, sy); sy = sx
	else
		sx = sx and math.min(sx, sy); sy = sx
		if aspect.x == 'mid' then
			x = x + (w / sx - vw) / 2
		end
		if aspect.y == 'mid' then
			y = y + (h / sy - vh) / 2
		end
		if aspect.x == 'max' then
			x = x + w / sx - vw
		end
		if aspect.y == 'max' then
			y = y + h / sy - vh
		end
	end
	return group({x = x, y = y, sx = sx, sy = sy}, t, ct)
end

function tags.g(t, ct)
	return group({}, t, ct)
end

local spread_methods = glue.index{'pad', 'reflect', 'repeat'}

local function alpha_color(color, opacity)
	return glue.merge({[4] = opacity}, color)
end

local function gradient(t, ct)
	--inherit attrs and children from xlink:href'ed tags, because my time is worth nothing
	local attrs, children = {}, {}
	local p = t
	repeat
		glue.merge(attrs, p.attrs)
		glue.extend(children, p.children)
		p = uri(p.attrs['xlink:href'], ct)
	until not p
	--parse the gradient
	local o = {
		type = 'gradient',
		relative = attrs.gradientUnits ~= 'userSpaceOnUse',
		extend = spread_methods[attrs.spreadMethod] and attrs.spreadMethod,
		transforms = transforms(attrs.gradientTransform),
	}
	for _,t in ipairs(children) do
		if t.tag == 'stop' then
			--TODO: for radial gradients, offset represents a percentage distance from (fx,fy) to the
			--edge of the outermost/largest circle.
			o[#o+1] = clamp(length(t.attrs.offset or '0', 1, ct), 0, 1)
			o[#o+1] = alpha_color(t.style.stop_color, t.style.stop_opacity)
		end
	end
	return o, attrs
end

local dummy_1x1_ct = {w = 1, h = 1}

function tags.linearGradient(t, ct)
	local o, attrs = gradient(t, ct)
	if attrs.gradientUnits ~= 'userSpaceOnUse' then
		ct = dummy_1x1_ct
	end
	o.x1 = coord(attrs.x1 or '0%', 'x', ct)
	o.y1 = coord(attrs.y1 or '0%', 'y', ct)
	o.x2 = coord(attrs.x2 or '100%', 'x', ct)
	o.y2 = coord(attrs.y2 or '0%', 'y', ct)
	return o.x1 and o.y1 and o.x2 and o.y2 and o or nil
end

function tags.radialGradient(t, ct)
	local o, attrs = gradient(t, ct)
	if attrs.gradientUnits ~= 'userSpaceOnUse' then
		ct = dummy_1x1_ct
	end
	o.x1 = coord(attrs.fx or attrs.cx or '50%', 'x', ct)
	o.y1 = coord(attrs.fy or attrs.cy or '50%', 'y', ct)
	o.r1 = 0
	o.x2 = coord(attrs.cx or '50%', 'x', ct)
	o.y2 = coord(attrs.cy or '50%', 'y', ct)
	o.r2 = length(attrs.r or '50%', 'xy', ct)
	return o.x1 and o.y1 and o.x2 and o.y2 and o.r1 and o.r2 and o or nil
end

local function parsed_paint(t, alpha, ct) -- 'none' | color_t | gradient_node_t | pattern_node_t
	if not t or t == 'none' then return end
	t.alpha = alpha ~= 1 and alpha or nil
	if not t.tag then return t end
	if t.tag == 'linearGradient' or t.tag == 'radialGradient' then
		return tag(t, ct)
	end
end

local function parsed_clip_path(t, ct)
	if not t then return end
	if t.tag ~= 'clipPatn' then return end
	return tag(t, ct)
end

local function shape(o, t, ct)
	o.type = 'shape'
	o.alpha = t.style.opacity
	o.hidden = t.style.visibility == 'hidden' or t.style.visibility == 'collapse' or nil
	if o.alpha == 1 then o.alpha = nil end
	o.fill = parsed_paint(t.style.fill, t.style.fill_opacity, ct)
	if not t.style.stroke_width or t.style.stroke_width > 0 then
		o.stroke = parsed_paint(t.style.stroke, t.style.stroke_opacity, ct)
	end
	if not t.style.fill and not t.style.stroke then return end
	o.transforms = transforms(t.attrs.transform)
	if o.fill then
		o.fill_rule = t.style.fill_rule
	end
	if o.stroke then
		o.line_dashes = t.style.stroke_dasharray ~= 'none' and t.style.stroke_dasharray or nil
		if o.line_dashes then
			o.line_dashes.offset = t.style.stroke_dashoffset
		end
		o.stroke_linkecap = t.style.stroke_linecap
		o.stroke_linejoin = t.style.stroke_linejoin
		o.stroke_miterlimit = t.style.stroke_miterlimit
		o.line_width = t.style.stroke_width
	end
	--[[
	o.clip_path = parsed_clip_path(t.style.clip_path, ct)
	o.clip_rule = t.style.clip_rule
	o.cursor = t.style.cursor
	o.display = t.style.display
	o.overflow = t.style.overflow
	]]
	return o
end

function tags.circle(t, ct)
	local cx = coord(t.attrs.cx or '0', 'x', ct)
	local cy = coord(t.attrs.cy or '0', 'y', ct)
	local r = length(t.attrs.r or '0', 'xy', ct)
	return cx and cy and r and r > 0 and
		shape({path = {'circle', cx, cy, r}}, t, ct) or nil
end

function tags.ellipse(t, ct)
	local cx = coord(t.attrs.cx or '0', 'x', ct)
	local cy = coord(t.attrs.cy or '0', 'y', ct)
	local rx = length(t.attrs.rx or '0', 'x', ct)
	local ry = length(t.attrs.ry or '0', 'y', ct)
	return cx and cy and rx and ry and rx > 0 and ry > 0 and
		shape({path = {'ellipse', cx, cy, rx, ry}}, t, ct) or nil
end

function tags.image(t, ct)
	local uri = data_uri(t.attrs['xlink:href'])
	local image_type = uri and uri.type and uri.type:match'^image/(.*)'
	return image_type and {
		type = 'image',
		w = length(t.attrs.width, 'x', ct),
		h = length(t.attrs.height, 'y', ct),
		file = {string = uri.data, type = image_type},
		transforms = transforms(t.attrs.transform),
	}
end

function tags.line(t, ct)
	local x1 = coord(t.attrs.x1 or '0', 'x', ct)
	local y1 = coord(t.attrs.y1 or '0', 'y', ct)
	local x2 = coord(t.attrs.x2 or '0', 'x', ct)
	local y2 = coord(t.attrs.y2 or '0', 'y', ct)
	return x1 and y1 and x2 and y2 and (x2 - x1 ~= 0 or y2 - y1 ~= 0) and
		shape({path = {'move', x1, y1, 'line', x2, y2}}, t, ct) or nil
end

function tags.path(t, ct)
	local path = path(t.attrs.d)
	return path and shape({path = path}, t, ct)
end

function tags.polyline(t, ct)
	local lt = list(t.attrs.points)
	local dt = {}
	local x = coord(lt[1], 'x', ct)
	local y = coord(lt[2], 'y', ct)
	if not x or not y then return end
	glue.append(dt, 'move', x, y)
	local x = coord(lt[3], 'x', ct)
	local y = coord(lt[4], 'y', ct)
	if not x or not y then return end
	glue.append(dt, 'line', x, y)
	for i=5,#lt,2 do
		local x = coord(lt[i+0], 'x', ct)
		local y = coord(lt[i+1], 'y', ct)
		if not x or not y then break end
		glue.append(dt, 'line', x, y)
	end
	return shape({path = dt}, t, ct)
end

function tags.polygon(t, ct)
	local shape = tags.polyline(t, ct)
	shape.path[#shape.path+1] = 'close'
	return shape
end

function tags.rect(t, ct)
	local x = coord(t.attrs.x or '0', 'x', ct)
	local y = coord(t.attrs.y or '0', 'y', ct)
	local w = length(t.attrs.width or '0', 'x', ct)
	local h = length(t.attrs.height or '0', 'y', ct)
	local rx = length(t.attrs.rx or '0', 'x', ct)
	local ry = length(t.attrs.ry or '0', 'y', ct)
	if not (x and y and w and h and rx and ry and w > 0 and h > 0) then return end
	if rx ~= 0 and ry ~= 0 then
		if rx == ry then
			return shape({path = {'round_rect', x, y, w, h, rx}}, t, ct)
		else
			return shape({path = {'elliptic_rect', x, y, w, h, rx, ry}}, t, ct)
		end
	else
		return shape({path = {'rect', x, y, w, h}}, t, ct)
	end
end

function tags.text(t)
end

--document-level parsing (multi-pass: collect ids, compute styles, parse tags)

local function collect_ids(t, dt)
	dt = dt or {}
	local id = t.attrs.id or t.attrs['xml:id']
	if id then
		glue.assert(not dt[id], 'duplicate id %s', id)
		dt[id] = t
	end
	for _,t in ipairs(t.children) do
		collect_ids(t, dt)
	end
	return dt
end

local known_tags = glue.update(glue.index{'defs', 'stop'}, tags)

local function parse(t)
	local doc = expat.treeparse(t, known_tags)
	local svg = assert(doc.tags.svg, 'root <svg> tag missing')
	svg.parent.style = default_styles
	local byid = collect_ids(svg)
	local ct = {byid = byid, dpi = 96, font_size = 12, w = 500, h = 500}
	compute_styles(svg, ct)
	svg.parent = nil
	return tag(svg, ct)
end

if not ... then
--require'svg_parser_test'
--pp(assert(parse{file = '../svg/test_files/leon.svg'}))
pp(parse{path = 'media/svg/futurama/Homer_and_Bender___Drinking_by_sircle.svg'})
end

return {
	parse = parse,
}

