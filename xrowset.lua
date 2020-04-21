
--Server-side rowset counterpart for x-widgets rowsets.
--Written by Cosmin Apreutesei. Public Domain.

local rowset = {}

--testing --------------------------------------------------------------------

local action = {}
rowset.action = action

local function send_slowly(s, dt)
	setheader('content-length', #s)
	local n = floor(#s * .1 / dt)
	while #s > 0 do
		out(s:sub(1, n))
		flush()
		sleep(.1)
		s = s:sub(n+1)
	end
end

action['ajax_test.txt'] = function()
	local s = 'There\'s no scientific evidence that life is important\n'
	local n = 5
	local z = 1
	sleep(1) --triggers `slow` event.
	setheader('content-length', #s * z * n)
	--^^comment to trigger chunked encoding (no progress in browser).
	--ngx.status = 500
	--^^uncomment see how browsers handles slow responses with non-200 codes.
	for i = 1, n do
		for i = 1, z do
			out(s)
		end
		flush(true)
		sleep(.5)
		--return
		--^^uncomment to trigger a timeout, if content_length is set.
	end
end

action['ajax_test.json'] = function()
	local t = post()
	t.a = t.a * 2
	out_json(t)
end

action['rowset_test.json'] = function()
	if method'post' then
		--
	else
		local rows = {}
		for i = 1, 1e5 do
			rows[i] = {values = {i, 'Row '..i, 0}}
		end
		local t = {
			fields = {
				{name = 'id', type = 'number'},
				{name = 'name'},
				{name = 'date', type = 'date'},
			},
			rows = rows,
		}
		return t
		--sleep(5)
		--send_slowly(json(t), 1)
	end
end

return rowset

