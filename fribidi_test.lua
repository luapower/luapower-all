local fb = require'fribidi'
local ffi = require'ffi'

print('fb.unicode_version()', fb.unicode_version)
print('fb.version_info()')
print(fb.version_info)

for i,charset in ipairs{
	'utf-8', 'caprtl', 'iso8859-6', 'iso8859-8', 'cp1255', 'cp1256'
} do
	print(string.format('%-10s %-10s %s\n%s',
		charset,
		fb.charset_name(charset),
		fb.charset_title(charset),
		fb.charset_desc(charset) or ''
	))
end

local function test(s0, charset, b)
	local s, len, b = fb.bidi(s0, nil, charset, b)
	print()
	print(s0, #s0, charset, '->')
	print(s, len)
	print('dir', fb.par_type_name(b.par_base_dir))
	for i=0,len-1 do
		local bidi_type_name = fb.bidi_type_name(b.bidi_types[i])
		local joining_type_name = fb.joining_type_name(b.ar_props[i])
		print(
			s:sub(i+1, i+1),
			bidi_type_name,
			b.levels[i],
			joining_type_name,
			b.visual_str[i],
			b.v_to_l[i],
			b.l_to_v[i])
	end
end

local b = fb.buffers(1)
test('english test', 'utf-8', b)
test('a _lsimple _RteST_o th_oat', 'caprtl', b)
test('HE SAID "it is a car!" AND RAN', 'caprtl', b)
