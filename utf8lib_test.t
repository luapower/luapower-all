setfenv(1, require'low')
require'utf8lib'

local strings = {
	{'empty', ''},
	{'smallest', '\0'},
	{'largest', '\xF4\x8F\xBF\xBF'},
	{'valid', 'Hello!'},
	{'valid', 'هذه هي بعض النصوص العربي'},
	{'valid', 'ᚠᛇᚻ᛫ᛒᛦᚦ᛫ᚠᚱᚩᚠᚢᚱ᛫ᚠᛁᚱᚪ᛫ᚷᛖᚻᚹᛦᛚᚳᚢᛗ'},
	{'valid', 'Sîne klâwen durh die wolken sint geslagen'},
	{'valid', 'Τη γλώσσα μου έδωσαν ελληνική'},
	{'valid', 'На берегу пустынных волн'},
	{'valid', 'ვეპხის ტყაოსანი შოთა რუსთაველი'},
	{'valid', 'யாமறிந்த மொழிகளிலே தமிழ்மொழி போல் இனிதாவது எங்கும் காணோம்,'},
	{'valid', '我能吞下玻璃而不伤身体'},
	{'valid', '나는 유리를 먹을 수 있어요. 그래도 아프지 않아요'},
	{'invalid', '-\x80='},
	{'partial2', '-\xC2='},
	{'partial3', '-\xE0='},
	{'partial3', '-\xE0\xA0='},
	{'partial3', '-\xE0\xBF='},
	{'partial3', '-\xE1='},
	{'partial3', '-\xE1\x80='},
	{'partial3', '-\xEC\xBF='},
	{'partial3', '-\xED='},
	{'partial3', '-\xED\x80='},
	{'partial3', '-\xED\x9F='},
	{'partial3', '-\xEE='},
	{'partial3', '-\xEE\x80='},
	{'partial3', '-\xEF\xBF='},
	{'partial4', '-\xF0='},
	{'partial4', '-\xF0\x90='},
	{'partial4', '-\xF0\x90\x80='},
	{'partial4', '-\xF0\xBF\xBF='},
	{'partial4', '-\xF1='},
	{'partial4', '-\xF1\x80='},
	{'partial4', '-\xF1\x80\x80='},
	{'partial4', '-\xF3\xBF\xBF='},
	{'partial4', '-\xF4='},
	{'partial4', '-\xF1\x80='},
	{'partial4', '-\xF1\x80\x80='},
	{'partial4', '-\xF4\x8F\xBF='},
}

local text = concat(glue.map(strings, 2))

local valid_text = {}
for i,t in ipairs(strings) do
	if t[1] == 'valid' then add(valid_text, t[2]) end
end
valid_text = concat(valid_text)

local terra test_decode(msg: rawstring, s: rawstring, opt: enum)
	var sn = strlen(s)
	var n, i, q = utf8.decode.count(s, sn, maxint, opt, 0xFFFD)
	pfn('%-10s in: %3d  out: %3d  invalid: %3d  "%s"', msg, sn, n, q, s)
	var out = arr(codepoint); defer out:free(); out.len = n
	var n1, i1, q1 = utf8.decode.tobuffer(s, sn, out.elements, out.len, opt, 0xFFFD)
	assert(n1 == n)
	assert(i1 == i)
	assert(q1 == q)
end
for i,t in ipairs(strings) do
	test_decode(t[1], t[2], utf8.REPLACE)
end

local s = '-\xE0\xA0\xE0\xA0\x80\0'
local terra test_iter()
	print('for: ', [#s])
	for valid, i, c in utf8.decode.codepoints(s, [#s]) do
		print('', valid, i, c)
	end
end
test_iter()

local terra create_text_arr(text: rawstring, sn: int)
	var s = arr(int8)
	var rep = 20 * 1024 * 1024 / sn
	for i:int = 0, rep do
		s:add(text, sn)
	end
	return s
end

local terra test_decode_speed(msg: rawstring, opt: enum)

	var t0: double
	var mb = 1024.0 * 1024.0
	var s = create_text_arr(text, [#text]); defer s:free()

	t0 = clock()
	var n0, i0, q0 = utf8.decode.count(s.elements, s.len, maxint, opt, utf8.INVALID)
	var count_mbs = s.len / (clock() - t0) / mb

	var a = arr(codepoint); defer a:free()

	t0 = clock()
	var n1, i1, q1 = utf8.decode.toarr(s.elements, s.len, &a, maxint, opt, utf8.INVALID)
	var toarr_mbs = s.len / (clock() - t0) / mb

	assert(n1 == n0)
	assert(i1 == i0)
	assert(q1 == q0)

	a.len = s.len --overallocate
	t0 = clock()
	var n2, i2, q2 = utf8.decode.tobuffer(s.elements, s.len, a.elements, a.len, opt, utf8.INVALID)
	var tobuffer_mbs = s.len / (clock() - t0) / mb
	a.len = n2

	assert(n1 == n0)
	assert(i1 == i0)
	assert(q1 == q0)

	pfn('decode (%s): %.2f Mbytes -> %.2f Mchars, %.f / %.f / %.f MB/s',
		msg, s.len / mb, n0 / mb, toarr_mbs, tobuffer_mbs, count_mbs)

end
test_decode_speed('replace', utf8.REPLACE)
test_decode_speed(' skip  ', utf8.SKIP)
test_decode_speed(' keep  ', utf8.KEEP)

local terra test_encode_speed(msg: rawstring, opt: enum)

	var t0: double
	var mb = 1024.0 * 1024.0
	var s = create_text_arr(valid_text, [#valid_text]); defer s:free()
	var a = arr(codepoint); defer a:free()
	utf8.decode.toarr(s.elements, s.len, &a, maxint, utf8.SKIP, utf8.INVALID)

	t0 = clock()
	var n0, i0, q0 = utf8.encode.count(a.elements, a.len, maxint, opt, utf8.INVALID)
	var count_mbs = a.len / (clock() - t0) / mb

	var s2 = arr(int8); defer s2:free()

	t0 = clock()
	var n1, i1, q1 = utf8.encode.toarr(a.elements, a.len, &s2, maxint, opt, utf8.INVALID)
	var toarr_mbs = a.len / (clock() - t0) / mb

	assert(n1 == n0)
	assert(i1 == i0)
	assert(q1 == q0)
	assert(equal(&s, &s2))

	s2.len = a.len * 4 --overallocate
	t0 = clock()
	var n2, i2, q2 = utf8.encode.tobuffer(
		a.elements, a.len, s2.elements, s2.len, opt, utf8.INVALID)
	var tobuffer_mbs = a.len / (clock() - t0) / mb
	s2.len = n2

	assert(n2 == n0)
	assert(i2 == i0)
	assert(q2 == q0)
	assert(equal(&s, &s2))

	pfn('encode (%s): %.2f Mchars -> %.2f Mbytes, %.f / %.f / %.f MB/s',
		msg, a.len / mb, n0 / mb, toarr_mbs, tobuffer_mbs, count_mbs)
end
test_encode_speed('replace', utf8.REPLACE)
test_encode_speed(' skip  ', utf8.SKIP)
test_encode_speed(' stop  ', utf8.STOP)
