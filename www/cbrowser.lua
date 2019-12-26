
local glue = require'glue'
--local cpp = require'cpp'

local cb = {}

local function idfy(s)
	return s:gsub('[./]', '_')
end

local cats = {
	{'Util',          'lj_buf.c', 'lj_alloc.c', 'lj_char.c', 'lj_def.h', },
	{'Parsing',       'lj_lex.c', 'lj_parse.c', },
	{'Bytecode',      'lj_bc.c', 'lj_bcdump.h', },
	{'IR Emitter',    'lj_ir.c', 'lj_ircall.h', 'lj_iropt.h', },
	{'IR -> ASM',     'lj_asm.c', 'lj_asm_arm.h', 'lj_asm_mips.h', 'lj_asm_ppc.h', 'lj_asm_x86.h'},
	{'Interpreter',   'lj_dispatch.c', },
	{'Compiler',
		'lj_jit.h', 'lj_mcode.c', 'lj_snap.c',
		'lj_record.c', 'lj_crecord.c', 'lj_ff.h', 'lj_ffrecord.c', 'lj_trace.c', 'lj_traceerr.h',
	},
	{'Assembler',
		'lj_arch.h',
		'lj_target.h', 'lj_target_arm.h', 'lj_target_arm64.h', 'lj_target_mips.h', 'lj_target_ppc.h', 'lj_target_x86.h',
		'lj_emit_arm.h', 'lj_emit_mips.h', 'lj_emit_ppc.h', 'lj_emit_x86.h', },
	{'Errors',        'lj_err.c', 'lj_errmsg.h', },
	{'GC',            'lj_gc.c', },
	{'Debugging',     'lj_debug.c', 'lj_gdbjit.c', },
	{'Lua API',       'lj_lib.c', 'lj_tab.c', 'lj_str.c', 'lj_strscan.c', 'lj_strfmt.c', },
	{'Lua C API',     'lualib.h', 'lauxlib.h', 'lua.h', 'luajit.h', 'lua.hpp', },
	{'C Data',        'lj_carith.c', 'lj_cconv.c', 'lj_cdata.c', 'lj_cparse.c', 'lj_ctype.c', },
	{'FFI',           'lj_ccall.c', 'lj_ccallback.c', 'lj_clib.c'},
	{'Profiler',      'lj_profile.c', },
	{'Frontend',      'luajit.c', },
	{'Building',      'luaconf.h', 'ps4build.bat', },
}

local function parse_cscope_db(filename)
	local yield = coroutine.yield
	return coroutine.wrap(function()
		local lineno = 0
		local getline = io.lines(filename)
		local get = function()
			lineno = lineno + 1
			return getline()
		end
		assert(get()) --header
		local fileline = get()
		while fileline do
			local file = fileline:match'^\t@(.*)'
			if file == '' then break end --database footer
			assert(file, lineno..': '..fileline)
			yield('@', file)
			assert(get()) --mandatory empty line
			local lineline = get()
			while lineline do --lines
				local line, text = lineline:match'^(%d+) (.*)'
				if not line then --no more lines: next file?
					fileline = lineline
					break
				end
				yield(':', tonumber(line))
				local ifend
				if text == '#if ' then
					yield('if')
				elseif text == '#ifdef ' then
					yield('if')
					yield('', 'defined')
					yield('', '(')
					ifend = ')'
				elseif text == '#ifndef ' then
					yield('if')
					yield('', '!')
					yield('', 'defined')
					yield('', '(')
					ifend = ')'
				elseif text == '#elif' then
					yield('elif')
				elseif text == '#else' then
					yield('else')
				else
					yield('', text)
				end
				local symline = get()
				while symline do --symbols
					if symline == '' then --no more symbols: next line?
						lineline = get()
						if lineline:find'^\t%)' then --exception: end def
							yield('enddef')
							assert(get() == '') --mandatory empty line
							lineline = get()
						end
						break
					end
					local mark, text = symline:match'^\t(.)(.*)'
					local nonsymline = get() --non-symbol
					assert(nonsymline)
					if mark == '#' then
						if nonsymline == '(' then
							yield('macro', text)
						else
							yield('define', text)
						end
					elseif mark == '~' then
						local s, file = text:match'(.)(.*)'
						yield('include', file, s)
					elseif text then
						yield(mark, text)
					else
						yield('S', symline)
					end
					coroutine.yield('', nonsymline)
					symline = get()
				end
				if ifend then
					yield('', ifend)
					yield('ifend')
				end
			end
		end
	end)
end

local function if_tree(cscope_iter)
	local t = {}
	local file, line, branch, expr
	local function close_branches() --the cscope db doesn't keep '#endif's!
		while branch.parent do
			branch.line2 = line
			branch = branch.parent
		end
	end
	for what, text in cscope_iter do
		if what == '@' then
			close_branches()
			branch = {line1 = line, branches = {}}
			file = {name = text, branch = branch}
			table.insert(t, file)
		elseif what == ':' then
			line = text
		elseif what == 'if' then
			expr = {}
		elseif what == 'ifend' or what == 'else' then
			local newbranch = {line1 = line, expr = expr, branches = {}, parent = branch}
			table.insert(branch.branches, newbranch)
			branch = newbranch
			expr = nil
		elseif expr then
			table.insert(expr, text)
		else
		end
	end
	close_branches()
	return t
end

local function file_list()
	local map = {}
	for _,f in ipairs(t) do
		map[f.name] = f
	end
	local dt = {}
	for _,f in ipairs(t) do
		local name, ext = f.name:match'^(.-)%.(.-)$'
		if ext == 'c' then
			local h = name..'.h'
			if map[h] then
				f.impl_name = f.name
				f.impl_id = f.id
				f.header_name = h
				f.header_id = idfy(h)
				f.list = true
				table.insert(dt, f)
			end
		elseif ext == 'h' or ext == 'hpp' then
			local c = name..'.c'
			f.list = not map[c]
			f.header_name = f.name
			f.header_id = f.id
			table.insert(dt, f)
		else
			f.impl_name = f.name
			f.impl_id = f.id
			f.list = true
			table.insert(dt, f)
		end
	end

	local ddt = {}
	for _,cat in ipairs(cats) do
		local catname = cat[1]
		local ct = {catname = catname, files = {}, n = 0}
		table.insert(ddt, ct)
		for i=2,#cat do
			local f = map[cat[i]]
			if f then
				table.insert(ct.files, f)
				f.cat = catname
				if f.list then
					ct.n = ct.n + 1
					if ct.n == 1 then
						f.first = true
					end
				end
			end
		end
	end
	local ct = {catname = 'Other', files = {}, n = 0}
	table.insert(ddt, ct)
	for _,f in ipairs(dt) do
		if not f.cat then
			table.insert(ct.files, f)
			if f.list then
				ct.n = ct.n + 1
				if ct.n == 1 then
					f.first = true
				end
			end
		end
	end

	return ddt
end

function cb.index(db)
	return {cats = db}
end

local db

local function cbrowser(what, ...)
	what = what or 'index'
	local handler = cb[what] or cb.index
	db = db or parse_cscope_db()
	return handler(db, ...)
end


if not ... then
	local src_dir = '/Users/cosmin/luajit-cscope/luajit-2.1/src'
	local cscope_db = '/Users/cosmin/luajit-cscope/luajit-2.1.cscope'
	local pp = require'pp'

	local function test_parsing()
		local cmd = parse_cscope_db(cscope_db)
		local function pass(...)
			if ... then
				print(...)
				return true
			else
				return false
			end
		end
		for i = 1, 1000000 do
			if not pass(cmd()) then break end
		end
	end

	local function test_if_tree()
		pp(if_tree(parse_cscope_db(cscope_db)))
	end

	test_parsing()
	--test_if_tree()

end

return cbrowser
