
require'xrowset'
require'xrowset_sql'

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

function rowset.test_static()
	math.randomseed(time())
	if random() > .5 then
		error'This is an error message in an error message box'
	end
	if method'post' then
		--
	else
		local rows = {}
		for i = 1, 1e5 do
			rows[i] = {i, 'Row '..i, 0}
		end
		local t = {
			fields = {
				{name = 'id', type = 'number'},
				{name = 'name'},
				{name = 'date', type = 'date'},
			},
			rows = rows,
		}
		sleep(5) --trigger slow timeout
		send_slowly(json(t), 5)
		--return t
	end
end

function rowset.test_query()
	math.randomseed(time())
	if random() > .5 then
		error'duude'
	end

	query'create database if not exists rowset_test'
	query'use rowset_test'
	query[[
		create table if not exists rowset_test (
			id int not null auto_increment primary key,
			name varchar(200)
		)
	]]

	return sql_rowset{
		select_all = 'select * from rowset_test',
		update_table = 'rowset_test',
		update_fields = 'name',
		pk = 'id',
		validators = {
			name = function(s)
				if not s:starts'aaa' then
					return 'Not starting with "aaa"'
				end
			end,
		},
	}:respond()

end

function rowset.loan_limit()
	query'use ifn_fin'
	return sql_rowset{
		select_all = 'select * from loan_limit',
	}:respond()
end

function rowset.product()
	query'use ifn_fin'
	return sql_rowset{
		select_all = 'select * from product',
	}:respond()
end
