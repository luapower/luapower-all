
C = terralib.includec("stdio.h")

terra hello()
	C.printf'hello from Terra\n'
end

hello()
print'hello from Lua'
