local lanes = require'lanes'
local time = require'time'
io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
lanes.configure()

local linda = lanes.linda()

local function reverse_echo_server(port, coro)
	local loop = require'socketloop'
	if coro then loop = loop.coro end
	local hcount = 0
	local stop_loop
	local function handler(skt)
		hcount = hcount + 1
		while true do
			local line = assert(skt:receive'*l')
			if line == 'close' or line == 'stop' then
				if line == 'stop' then
					stop_loop = true
				end
				linda:set('clients_served', linda:get('clients_served') + 1)
				break
			end
			assert(skt:send(line:reverse() .. '\n'))
			linda:set('messages_served', linda:get('messages_served') + 1)
		end
		hcount = hcount - 1
		skt:close()
	end
	local srv_skt = loop.newserver('127.0.0.1', port, handler)
	print'server started'
	linda:set('server_started', true)
	while loop.step(1) do
		if stop_loop and hcount == 0 then break end
	end
	srv_skt:close()
	linda:set('server_started', false)
end

local function client_multi_conn(server_port, coro)
	local loop = require'socketloop'
	if coro then loop = loop.coro end
	local function client()
		local skt = assert(loop.connect('127.0.0.1', server_port))
		local function say(s)
			assert(skt:send(s .. '\n'))
			local ss, err = skt:receive'*l'
			assert(ss == s:reverse())
		end
		for i = 1,10 do
			say'goone'
			say'tit'
			say('erogenous zoone #'..tostring(i))
		end
		skt:send'close\n'
		skt:close()
	end
	for i=1,5 do
		loop.newthread(client)
	end
	loop.start(1)
end

local function stop_conn(server_port, coro)
	local loop = require'socketloop'
	if coro then loop = loop.coro end
	loop.newthread(function()
		local skt = assert(loop.connect('127.0.0.1', server_port))
		assert(skt:send'stop\n')
	end)
	loop.start(1)
end

local function test(coro)
	print('using coro:', coro and 'yes' or 'no')

	linda:set('messages_served', 0)
	linda:set('clients_served', 0)

	local port = 12355
	local server_lane_gen = lanes.gen('*', reverse_echo_server)
	local server_lane = server_lane_gen(port, coro)
	time.sleep(.1)

	local client_lane_gen = lanes.gen('*', client_multi_conn)
	local client_lanes = {}
	for i=1,10 do
		client_lanes[i] = client_lane_gen(port, coro)
	end

	print('waiting for server to start...')
	while not linda:get'server_started' do
		time.sleep(0.1)
	end
	print('waiting for clients')
	for i=#client_lanes,1,-1 do
		local _ = client_lanes[i][1]
	end
	print('all clients finished')

	print('stopping the server')
	stop_conn(port, coro)
	print('waiting for server to stop...')
	while linda:get'server_started' do
		time.sleep(0.1)
	end
	print('server stopped')

	print('waiting for server to finish')
	local _ = server_lane[1]
	print('server finished')
	print('clients served', linda:get('clients_served'))
	print('messages served', linda:get('messages_served'))
end

test(true)
test()

