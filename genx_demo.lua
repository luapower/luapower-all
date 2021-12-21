local genx = require'genx'
local ffi = require'ffi'

print('version', genx.version())

local w = genx.new()

local ns1 = w:ns('ns1', 'pns1')
local ns2 = w:ns('ns2', 'pns2')
local body = w:element('body', ns1)
local a1 = w:attr('a1')
local a2 = w:attr('a2')

w:start_doc(io.stdout)
w:start_element'root'
w:text'hello'
w:end_element()
w:end_doc()
print()

w:start_doc(function(s, sz)
	s = s and (sz and ffi.string(s, sz) or ffi.string(s)) or '\n!EOF\n'
	io.write(s)
end)

w:start_element('html')
w:add_ns(ns1)
w:add_ns(ns2, 'g')

	w:text'\n\t'
	w:start_element('head')
	w:add_attr('b', 'vb')
	w:add_attr('a', 'va')
	w:text'hello'
	w:end_element()
	w:text'\n\t'

	w:start_element(body)
	w:add_attr(a1, 'v1')
	w:add_attr(a2, 'v2')
	w:text'hey'
	w:end_element()
	w:text'\n'

w:end_element()

w:end_doc()

w:free()
