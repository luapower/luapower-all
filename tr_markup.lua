
--text markup parser.
--Written by Cosmin Apreutesei. Public Domain.

--xml tag processor that dispatches the processing of tags inside <signatures> tag to a table of tag handlers.
--the tag handler gets the tag attributes and a conditional iterator to get any subtags.
local function process_tags(gettag)

	local function nextwhile(endtag)
		local start, tag, attrs = gettag()
		if not start then
			if tag == endtag then return end
			return nextwhile(endtag)
		end
		return tag, attrs
	end
	local function getwhile(endtag) --iterate tags until `endtag` ends, returning (tag, attrs) for each tag
		return nextwhile, endtag
	end

	for tagname, attrs in getwhile'signatures' do
		if tag[tagname] then
			tag[tagname](attrs, getwhile)
		end
	end
end

--fast, push-style xml parser.
local function parse_xml(s, write)
	for endtag, tag, attrs, tagends in s:gmatch'<(/?)([%a_][%w_]*)([^/>]*)(/?)>' do
		if endtag == '/' then
			write(false, tag)
		else
			local t = {}
			for name, val in attrs:gmatch'([%a_][%w_]*)=["\']([^"\']*)["\']' do
				if val:find('&quot;', 1, true) then --gsub alone is way slower
					val = val:gsub('&quot;', '"') --the only escaping found in all xml files tested
				end
				t[name] = val
			end
			write(true, tag, t)
			if tagends == '/' then
				write(false, tag)
			end
		end
	end
end
