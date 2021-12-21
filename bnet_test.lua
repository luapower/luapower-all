local socket = require "bnet"

local u = socket.udp() assert(u:setsockname("*", 5088)) u:close()
local u = socket.udp() assert(u:setsockname("*", 0)) u:close()
local t = socket.tcp() assert(t:bind("*", 5088)) t:close()
local t = socket.tcp() assert(t:bind("*", 0)) t:close()
print("done!")

-- testsrvr

host = host or "localhost";
port = port or "8383";
server = assert(socket.bind(host, port));
ack = "\n";
print("server: waiting for client connection... (open your navigator and connect to http://127.0.0.1:8383/)");
control = assert(server:accept());
while 1 do
	command, emsg = control:receive();
	if emsg == "closed" then
		control:close()
		break
	end
	assert(command, emsg)
	assert(control:send(ack));
	print(command);
end

-- udp-zero-length-send

s = assert(socket.udp())
r = assert(socket.udp())
assert(r:setsockname("*", 5432))
assert(s:setpeername("127.0.0.1", 5432))

ssz, emsg = s:send("")

print(ssz == 0 and "OK" or "FAIL",[[send:("")]], ssz, emsg)

-- udp-zero-length-send-recv

s = assert(socket.udp())
r = assert(socket.udp())
assert(r:setsockname("*", 5433))
assert(s:setpeername("127.0.0.1", 5433))

ok, emsg = s:send("")
if ok ~= 0 then
    print("send of zero failed with:", ok, emsg)
end

assert(r:settimeout(2))

ok, emsg = r:receive()

if not ok or string.len(ok) ~= 0 then
    print("fail - receive of zero failed with:", ok, emsg)
    os.exit(1)
end

print"ok"
