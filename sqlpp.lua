
--SQL preprocessor, postprocessor and generator API.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'sqlpp_mysql_test'; return end

local glue = require'glue'
local errors = require'errors'

local fmt = string.format
local add = table.insert
local del = table.remove
local cat = table.concat
local char = string.char

local assertf = glue.assert
local repl = glue.repl
local attr = glue.attr
local update = glue.update
local merge = glue.merge
local empty = glue.empty
local names = glue.names
local outdent = glue.outdent
local imap = glue.imap
local pack = glue.pack
local trim = glue.trim
local sortedpairs = glue.sortedpairs

local sqlpp = {package = {}}

function sqlpp.ispp(v) return type(v) == 'table' and v.is_sqlpp or false end

function sqlpp.new(init)

	assert(init, 'engine module name or engine init function expected')
	if type(init) == 'string' then
		init = require('sqlpp_'..init).init_spp
	end

	local spp = {is_sqlpp = true}
	local cmd = {spp = spp}
	spp.command = cmd

	local avoid_code = string.byte'?' --because we're gonna match '?' alone later
	local function mark(n)
		assert(n <= 254, 'too many substitutions')
		local n = n ~= avoid_code and n or 255
		return '\0'..char(n)
	end

	--parsing string literals -------------------------------------------------

	local function collect_strings(s, repl)
		local i = 1
		local t = {}
		::next_string::
		local i1 = s:find("'", i, true)
		if i1 then --string literal start
			local i2
			local j = i1 + 1
			::again::
			local j1 = s:find("\\'", j, true) --skip over \'
			if j1 then
				j = j1 + 2
				goto again
			end
			local j1 = s:find("''", j, true) --skip over ''
			if j1 then
				j = j1 + 2
				goto again
			end
			i2 = s:find("'", j, true) --string literal end
			if i2 then
				add(t, s:sub(i, i1 - 1))
				add(repl, s:sub(i1, i2))
				add(t, mark(#repl))
				i = i2 + 1
				goto next_string
			else
				error'string literal not closed'
			end
		else
			add(t, s:sub(i))
		end
		return cat(t)
	end

	--conditional compilation -------------------------------------------------

	--Process #if #elif #else #endif conditionals.
	--Also normalize newlines and remove single-line comments which the mysql
	--client protocol cannot parse. Multiline comments are not removed since
	--they can be used for optimizer hints.
	local globals_mt = {__index = _G}
	local function parse_expr(s, params)
		local f = assert(loadstring('return '..s))
		params = update({}, params) --copy it so we alter it
		setmetatable(params, globals_mt)
		setfenv(f, params)
		return f()
	end
	local function spp_ifs(sql, params)
		local t = {}
		local state = {active = true}
		local states = {state}
		local level = 1
		for line in glue.lines(sql) do
			local s, expr = line:match'^%s*#([%w_]+)(.*)'
			if s == 'if' then
				level = level + 1
				if state.active then
					local active = parse_expr(expr, params) and true or false
					state = {active = active, activated = active}
				else
					state = {active = false, activated = true}
				end
				states[level] = state
			elseif s == 'else' then
				assert(level > 1, '#else without #if')
				assert(not state.done, '#else after #else')
				if not state.activated then
					state.active = true
					state.activated = true
				else
					state.active = false
				end
				state.done = true
			elseif s == 'elif' then
				assert(level > 1, '#elif without #if')
				assert(not state.done, '#elif after #else')
				if not state.activated and parse_expr(expr, params) then
					state.active = true
					state.activated = true
				else
					state.active = false
				end
			elseif s == 'endif' then
				assert(level > 1, '#endif without #if')
				states[level] = nil
				level = level - 1
				state = states[level]
			elseif state.active then
				line = line:gsub('%-%-.*', '') --remove `-- ...` comments
				line = line:gsub('#.*', '') -- remove `# ...` comments
				if trim(line) ~= '' then
					add(t, line)
				end
			end
		end
		assert(level == 1, '#endif missing')
		return cat(t, '\n')
	end

	--quoting -----------------------------------------------------------------

	local symbols = {} --{sym -> sql}
	spp.symbol_for = {} --{keyword -> sym}

	function spp.define_symbol(sql, sym)
		assertf(not spp.symbol_for[sql], 'symbol already defined for `%s`', sql)
		sym = sym or {sql}
		symbols[sym] = sql
		spp.symbol_for[sql] = sym
		return sym
	end

	function cmd:sqlstring(s)
		return "'"..self:esc(s).."'"
	end

	function cmd:sqlnumber(x) --stub
		return fmt('%0.17g', x) --max precision, min length.
	end

	function cmd:sqlboolean(v) --stub
		return tostring(v)
	end

	--NOTE: don't use dots in db names, table names and column names!
	cmd.sqlname_quote = '"'
	function cmd:sqlname(s)
		s = s and trim(s) or ''
		assert(s ~= '', 'sql name missing')
		local q = self.sqlname_quote
		if s:sub(1, 1) == q then
			return s
		end
		if not s:find('.', 1 , true) then
			return self:needs_quoting(s) and q..s..q or s
		end
		self:needs_quoting() --avoid yield accross C-call boundary :rolleyes:
		return s:gsub('[^%.]+', function(s)
			return self:needs_quoting(s) and q..trim(s)..q or s
		end)
	end

	function cmd:sqlval(v, field)
		local to_sql = field and field[spp.TO_SQL]
		if v == nil then
			return 'null'
		elseif to_sql then
			return to_sql(v, field)
		elseif type(v) == 'number' then
			return self:sqlnumber(v)
		elseif type(v) == 'string' then
			return self:sqlstring(v)
		elseif type(v) == 'boolean' then
			return self:sqlboolean(v)
		elseif symbols[v] then
			return symbols[v]
		elseif type(v) == 'table' then
			if #v > 0 then --list: for use in `in (?)`
				local t = {}
				for i,v in ipairs(v) do
					t[i] = self:sqlval(v, field)
				end
				return cat(t, ', ')
			else --empty list: good for 'in (?)' but NOT GOOD for `not in (?)` !!!
				return 'null'
			end
		else
			error('invalid value ' .. v)
		end
	end

	function cmd:binval(v, field)
		local to_bin = field and field.to_bin
		if to_bin then
			return to_bin(v)
		else
			return v
		end
	end

	--macros ------------------------------------------------------------------

	local defines = {}

	function spp.subst(def) --'name type'
		local name, val = def:match'([%w_]+)%s+(.*)'
		assertf(not defines[name], 'macro already defined: $%s', name)
		defines[name] = val
	end

	spp.macro = {}

	local function macro_arg(self, arg, t)
		local k = arg:match'^:([%w_][%w_%:]*)'
		if k then --unparsed param expansion.
			return t[k]
		else --parsed param expansion.
			return self:sqlparams(arg, t)
		end
	end

	local function macro_subst(self, name, args, t)
		local macro = assertf(spp.macro[name], 'undefined macro: $%s()', name)
		args = args:sub(2,-2)..','
		local dt = {}
		for arg in args:gmatch'([^,]+)' do
			arg = trim(arg)
			dt[#dt+1] = macro_arg(self, arg, t) --expand params in macro args *unquoted*!
		end
		return macro(self, unpack(dt))
	end

	--named params & positional args substitution -----------------------------

	function cmd:sqlparams(sql, vals)
		self:needs_quoting() --avoid yield accross C-call boundary :rolleyes:
		local names = {}
		return sql:gsub('::([%w_]+)', function(k) -- ::col, ::table, etc.
				add(names, k)
				return self:sqlname(vals[k])
			end):gsub(':([%w_][%w_%:]*)', function(k) -- :foo, :foo:old, etc.
				add(names, k)
				return self:sqlval(vals[k])
			end), names
	end

	function cmd:sqlargs(sql, vals) --not used
		self:needs_quoting() --avoid yield accross C-call boundary :rolleyes:
		local i = 0
		return (sql:gsub('%?%?', function() -- ??
				i = i + 1
				return self:sqlname(vals[i])
			end):gsub('%?', function() -- ?
				i = i + 1
				return self:sqlval(vals[i])
			end))
	end

	--preprocessor ------------------------------------------------------------

	local function args_params(...)
		local args = select('#', ...) > 0 and pack(...) or empty
		local params = type((...)) == 'table' and (...) or empty
		return args, params
	end

	local function sqlquery(self, prepare, sql, ...)

		self:needs_quoting() --avoid yield accross C-call boundary :rolleyes:

		local args, params = args_params(...)

		if not sql:find'[#$:?{]' and not sql:find'%-%-' then --nothing to see here
			return sql, empty
		end

		local sql = spp_ifs(sql, params) --#if ... #endif

		--We can't just expand values on-the-fly in multiple passes of gsub()
		--because each pass would result in a partially-expanded query with
		--string literals inside so the next pass would parse inside those
		--literals. To avoid that, we replace expansion points inside the query
		--with special markers and on a second step we replace the markers
		--with the expanded values.

		--step 1: find all expansion points and replace them with a marker
		--that string literals can't contain.

		local repl = {}

		--collect string literals
		sql = collect_strings(sql, repl)

		--collect macros
		local macros = {}
		sql = sql:gsub('$([%w_]+)(%b())', function(name, args)
				add(macros, name)
				add(macros, args)
				return mark(#repl + #macros / 2)
			end) --$foo(arg1,...)
		for i = 1, #macros, 2 do
			local m_name, m_args = macros[i], macros[i+1]
			add(repl, macro_subst(self, m_name, m_args, params) or '')
		end

		--collect defines
		sql = sql:gsub('$([%w_]+)', function(name)
				add(repl, assertf(defines[name], '$%s is undefined', name))
				return mark(#repl)
			end) --$foo

		local param_names = {}

		--collect verbatims
		sql = glue.subst(sql, function(name)
				add(param_names, name)
				add(repl, assertf(params[name], '{%s} is missing', name))
				return mark(#repl)
			end) --{foo}

		local param_map = prepare and {}

		--collect named params
		sql = sql:gsub('::([%w_]+)', function(k) -- ::col, ::table, etc.
				add(param_names, k)
				add(repl, self:sqlname(params[k]))
				return mark(#repl)
			end):gsub(':([%w_][%w_%:]*)', function(k) -- :foo, :foo:old, etc.
				add(param_names, k)
				if prepare then
					add(param_map, k)
					add(repl, '?')
				else
					add(repl, opt and opt.prepare and '?' or self:sqlval(params[k]))
				end
				return mark(#repl)
			end)

		--collect indexed params
		local i = 0
		sql = sql:gsub('%?%?', function() -- ??
				i = i + 1
				add(repl, self:sqlname(args[i]))
				return mark(#repl)
			end):gsub('%?', function() -- ?
				i = i + 1
				if prepare then
					add(param_map, i)
					add(repl, '?')
				else
					add(repl, self:sqlval(args[i]))
				end
				return mark(#repl)
			end)

		assert(not (#param_names > 0 and i > 0),
			'both named params and positional args found')

		--step 3: expand markers.

		sql = sql:gsub('%z(.)', function(ci)
			local i = string.byte(ci)
			if i == 255 then i = avoid_code end
			return repl[i]
		end)

		return sql, param_names, param_map
	end

	function cmd:sqlquery(sql, ...)
		return sqlquery(self, nil, sql, ...)
	end

	function cmd:sqlprepare(sql, ...)
		return sqlquery(self, true, sql, ...)
	end

	local function map_params(stmt, cmd, param_map, ...)
		local args, params = args_params(...)
		local t = {}
		for i,k in ipairs(param_map) do
			local v
			if type(k) == 'number' then --arg
				v = args[k]
			else --param
				v = params[k]
			end
			t[i] = cmd:binval(v, stmt.params[i])
			t.n = i
		end
		return t
	end

	--schema diff formatting --------------------------------------------------

	local function ix_cols(self, t)
		local dt = {}
		for i,s in ipairs(t) do
			dt[i] = self:sqlname(s) .. (t.desc and t.desc[i] and ' desc' or '')
		end
		return cat(dt, ', ')
	end

	function cmd:sqlcol(fld, cf)
		return _('%-16s %-14s %s%s', self:sqlname(fld.col), self:sqltype(fld),
			self:sqlcol_flags(fld) or '',
			cf ~= nil and (cf == false and ' first' or ' after '..self:sqlname(cf)) or ''
		)
	end

	function cmd:sqlpk(pk, tbl_name)
		return _('primary key (%s)', ix_cols(self, pk))
	end

	function cmd:sqluk(name, uk)
		return _('constraint %-20s unique (%s)', self:sqlname(name), ix_cols(self, uk))
	end

	function cmd:sqlix(name, ix, tbl_name)
		return _('index %-20s on %s (%s)',
			self:sqlname(name), self:sqlname(tbl_name), ix_cols(self, ix))
	end

	function cmd:sqlfk(name, fk)
		assertf(fk.ref_cols, 'fk not resolved: %s', name)
		local ondelete = fk.ondelete or 'no action'
		local onupdate = fk.onupdate or 'cascade'
		local a1 = ondelete ~= 'no action' and ' on delete '..ondelete or ''
		local a2 = onupdate ~= 'no action' and ' on update '..onupdate or ''
		return _('constraint %-20s foreign key (%s) references %s (%s)%s%s',
			self:sqlname(name), ix_cols(self, fk.cols), self:sqlname(fk.ref_table),
			ix_cols(self, fk.ref_cols), a1, a2)
	end

	function cmd:sqltrigger(tbl_name, name, tg)
		local BODY = spp.engine..'_body'
		return tg[BODY] and _('trigger %s %s %s on %s for each row\n%s',
			self:sqlname(name), tg.when, tg.op, self:sqlname(tbl_name), tg[BODY])
	end

	function cmd:sqlproc(name, proc)
		local BODY = spp.engine..'_body'
		if not proc[BODY] then return end
		local args = {}; for i,arg in ipairs(proc.args) do
			args[i] = _('%s %s', arg.mode or 'in', self:sqlcol(arg))
		end
		return _('procedure %s (\n\t%s\n)\n%s', name, cat(args, ',\n\t'), proc[BODY])
	end

	function cmd:sqlcheck(name, ck)
		local BODY = spp.engine..'_body'
		local s = ck[BODY] or ck.body
		return s and _('constraint %-20s check (%s)', self:sqlname(name), s)
	end

	function cmd:sqltable(t)
		local dt = {}
		for i,fld in ipairs(t.fields) do
			dt[i] = self:sqlcol(fld)
		end
		if t.pk then
			add(dt, self:sqlpk(t.pk, t.name))
		end
		if t.uks then
			for name, uk in sortedpairs(t.uks) do
				add(dt, self:sqluk(name, uk))
			end
		end
		if t.checks then
			for name, ck in sortedpairs(t.checks) do
				add(dt, self:sqlcheck(name, ck))
			end
		end
		return _('(\n\t%s\n)', cat(dt, ',\n\t'))
	end

	function cmd:sqldiff(diff)

		assertf(diff.engine == spp.engine,
			'diff engine is `%s`, expected `%s`', diff.engine, spp.engine)

		local dt = {}

		local function P(...) add(dt, _(...)) end
		local function N(s) return self:sqlname(s) end
		local function TN(s) return self:sqlname(s) end
		local BODY = spp.engine..'_body'

		local fk_bin = {} --{fk->true}

		--gather fks pointing to tables that need to be removed.
		if diff.tables and diff.tables.remove then
			for _, tbl in pairs(diff.tables.remove) do
				if tbl.fks then
					for _, fk in pairs(tbl.fks) do
						if diff.tables.remove[fk.ref_table] then
							fk_bin[fk] = true
						end
					end
				end
			end
		end

		if diff.tables and diff.tables.update then
			for _, d in pairs(diff.tables.update) do

				--gather fks pointing to fields that need to be removed.
				if d.fields and d.fields.remove then
					for col in pairs(d.fields.remove) do
						for _, tbl in pairs(diff.old_schema.tables) do
							if tbl.fks then
								for fk_name, fk in pairs(tbl.fks) do
									for _, ref_col in ipairs(fk.ref_cols) do
										if ref_col == col then
											fk_bin[fk] = true
										end
									end
								end
							end
						end
					end
				end

				--gather fks that need to be explicitly removed.
				if d.fks and d.fks.remove then
					for _,fk in pairs(d.fks.remove) do
						fk_bin[fk] = true
					end
				end

			end
		end

		--drop gathered fks.
		for fk in sortedpairs(fk_bin, function(fk1, fk2) return fk1.name < fk2.name end) do
			P('alter  table %-16s drop %-16s %s', N(fk.table), 'foreign key', N(fk.name))
		end

		--drop procs.
		if diff.procs and diff.procs.remove then
			for proc_name, proc in sortedpairs(diff.procs.remove) do
				if proc[BODY] then
					P('drop %-16s %s', 'procedure', N(proc_name))
				end
			end
		end

		--drop tables.
		if diff.tables and diff.tables.remove then
			for tbl_name in sortedpairs(diff.tables.remove) do
				P('drop table %s', N(tbl_name))
			end
		end

		--add new tables.
		if diff.tables and diff.tables.add then
			for tbl_name, tbl in sortedpairs(diff.tables.add) do
				P('create table %-16s %s', N(tbl_name), self:sqltable(tbl))
				local tgs = tbl.triggers
				if tgs then
					local function cmp_tg(tg1, tg2)
						local a = tgs[tg1]
						local b = tgs[tg2]
						if a.op ~= b.op then return a.op < b.op end
						if a.when ~= b.when then return a.when < b.when end
						return a.pos < b.pos
					end
					for tg_name, tg in sortedpairs(tgs, cmp_tg) do
						local s = self:sqltrigger(tbl_name, tg_name, tg)
						if s then P('create %s', s) end
					end
				end
				if tbl.ixs then
					for ix_name, ix in sortedpairs(tbl.ixs) do
						P('create %s', self:sqlix(ix_name, ix, tbl_name))
					end
				end
				if tbl.rows then
					P('insert into %s values\n%s',
						self:sqlname(tbl_name), self:sqlrows(tbl.rows,
							{n = #tbl.fields, indent = '\t'}))
				end
			end
		end

		--update tables.
		if diff.tables and diff.tables.update then
			for old_tbl_name, d in sortedpairs(diff.tables.update) do

				if d.fields then

					--doing table changes in a single statement allows both column
					--name changes and column position changes without conflicts.
					local changes = {}

					--remove columns.
					if d.fields.remove then
						local function cmp_by_col_pos(col1, col2)
							local f1 = d.fields.remove[col1]
							local f2 = d.fields.remove[col2]
							return f1.col_pos < f2.col_pos
						end
						for col, fld in sortedpairs(d.fields.remove, cmp_by_col_pos) do
							add(changes, _('drop   %s', N(col)))
						end
					end

					--add columns.
					if d.fields.add then
						local function cmp_by_col_pos(col1, col2)
							local f1 = d.fields.add[col1]
							local f2 = d.fields.add[col2]
							return f1.col_pos < f2.col_pos
						end
						for col, fld in sortedpairs(d.fields.add, cmp_by_col_pos) do
							add(changes, _('add    %s', self:sqlcol(fld, fld.col_in_front)))
						end
					end

					--modify columns (incl. changing column order).
					if d.fields.update then
						local function cmp_by_col_pos(col1, col2)
							local d1 = d.fields.update[col1]
							local d2 = d.fields.update[col2]
							return d1.new.col_pos < d2.new.col_pos
						end
						for old_col, fd in sortedpairs(d.fields.update, cmp_by_col_pos) do
							add(changes, _('change %-16s %s',
								N(old_col), self:sqlcol(fd.new, fd.new.col_in_front)))
						end
					end

					if #changes > 0 then
						P('alter  table %-16s\n\t%s',
							N(old_tbl_name), concat(changes, ',\n\t'))
					end

				end --d.fields

				--remove constraints, indexes and triggers.

				if d.remove_pk then
					P('alter  table %-16s drop primary key', N(old_tbl_name))
				end

				if d.uks and d.uks.remove then
					for uk_name in sortedpairs(d.uks.remove) do
						P('alter  table %-16s drop %-16s %s',
							N(tbl_name), 'key', N(uk_name))
					end
				end

				if d.ixs and d.ixs.remove then
					for ix_name in sortedpairs(d.ixs.remove) do
						P('drop index %-16s on %-16s', N(ix_name), N(tbl_name))
					end
				end
				if d.checks and d.checks.remove then
					for ck_name in sortedpairs(d.checks.remove) do
						P('alter  table %-16s drop %-16s %s',
							N(tbl_name), 'check', N(ck_name))
					end
				end

				if d.triggers and d.triggers.remove then
					for tg_name, tg in sortedpairs(d.triggers.remove) do
						if tg[BODY] then P('drop trigger %-16s', N(tg_name)) end
					end
				end

				--rename table before adding constraints back.

				local new_tbl_name = d.new.name

				if old_tbl_name ~= new_tbl_name then
					P('rename table %-16s to %-16s', N(old_tbl_name), N(new_tbl_name))
				end

				--add constraints, indexes and triggers.

				if d.add_pk then
					P('alter  table %-16s add %s', N(new_tbl_name),
						self:sqlpk(d.add_pk, tbl_name))
				end

				if d.uks and d.uks.add then
					for uk_name, uk in sortedpairs(d.uks.add) do
						P('alter  table %-16s add %s',
							N(new_tbl_name), self:sqluk(uk_name, uk))
					end
				end

				if d.ixs and d.ixs.add then
					for ix_name, ix in sortedpairs(d.ixs.add) do
						P('create %s', self:sqlix(ix_name, ix, new_tbl_name))
					end
				end

				if d.checks and d.checks.add then
					for ck_name, ck in sortedpairs(d.checks.add) do
						P('alter  table %-16s add %s',
							N(new_tbl_name), self:sqlcheck(ck_name, ck))
					end
				end

				if d.triggers and d.triggers.add then
					for tg_name, tg in sortedpairs(d.triggers.add) do
						local s = self:sqltrigger(new_tbl_name, tg_name, tg)
						if s then P('create '..s) end
					end
				end

			end
		end

		--add new fks for current tables.
		if diff.tables and diff.tables.update then
			for _, d in sortedpairs(diff.tables.update) do
				local new_tbl_name = d.new.name
				if d.fks and d.fks.add then
					for fk_name, fk in sortedpairs(d.fks.add) do
						P('alter  table %-16s add %s',
							N(new_tbl_name), self:sqlfk(fk_name, fk))
					end
				end
			end
		end

		--add new fks for added tables.
		if diff.tables and diff.tables.add then
			for tbl_name, tbl in sortedpairs(diff.tables.add) do
				if tbl.fks and diff.old_schema.supports_fks then
					for fk_name, fk in sortedpairs(tbl.fks) do
						P('alter  table %-16s add %s',
							N(tbl_name), self:sqlfk(fk_name, fk))
					end
				end
			end
		end

		--add new procs.
		if diff.procs and diff.procs.add then
			for proc_name, proc in sortedpairs(diff.procs.add) do
				local s = self:sqlproc(proc_name, proc)
				if s then P('create %s', s) end
			end
		end

		return dt
	end

	--row list formatting -----------------------------------------------------

	function cmd:sqlrows(rows, opt) --{{v1,...},...} -> '(v1,...),\n (v2,...)'
		local max_sizes = {}
		local pad_dirs = {}
		local srows = {}
		local as_cols = {} --{as_col1,...}
		local as_col_map = {} --{as_col->col}
		if opt.col_map then
			for col, as_col in sortedpairs(opt.col_map) do
				add(as_cols, as_col)
				as_col_map[as_col] = col
			end
		elseif opt.fields then
			for i, field in ipairs(opt.fields) do
				local as_col = opt.compact and i or col
				add(as_cols, as_col)
				as_col_map[as_col] = field.name
			end
		elseif opt.n then
			for i = 1, opt.n do
				as_cols[i] = i
			end
		end
		for ri,row in ipairs(rows) do
			local srow = {}
			srows[ri] = srow
			for i,as_col in ipairs(as_cols) do
				local v = row[as_col]
				if type(v) == 'function' then --self-generating value.
					v = v()
				end
				pad_dirs[i] = type(v) == 'number' and 'l' or 'r'
				local col = as_col_map[as_col]
				local field = opt.fields and opt.fields[col]
				local s = tostring(self:sqlval(v, field))
				srow[i] = s
				max_sizes[i] = math.max(max_sizes[i] or 0, #s)
			end
		end
		local dt = {}
		local prefix = (opt and opt.indent or '')..'('
		for ri,srow in ipairs(srows) do
			local t = {}
			for i,s in ipairs(srow) do
				t[i] = glue.pad(s, max_sizes[i], ' ', pad_dirs[i])
			end
			dt[ri] = prefix..cat(t, ', ')..')'
		end
		return cat(dt, ',\n')
	end

	--tab-separated rows parsing ----------------------------------------------

	function spp.tsv_rows(t, s) --{n=3|cols='3 1 2', transform1, ...}
		s = trim(s)
		local cols
		if t.cols then
			cols = {}
			for s in t.cols:gmatch'[^%s]+' do
				cols[#cols+1] = assert(tonumber(s))
			end
		end
		local n = t.n
		if not n then
			if cols then
				local cols = glue.extend({}, cols)
				table.sort(cols)
				n = cols[#cols]
			else
				local s = s:match'^[^\r\n]+'
				if s then
					n = 1
					for _ in s:gmatch'\t' do
						n = n + 1
					end
				else
					n = 1
				end
			end
		end
		cols = cols and glue.index(cols) --{3, 1, 2} -> {[3]->1, [1]->2, [2]->3}
		local patt = '^'..('(.-)\t'):rep(n-1)..'(.*)'
		local function transform_line(row, ...)
			for i=1,n do
				local di = not cols and i or cols[i]
				if di then
					local s = select(i,...)
					local transform_val = t[i]
					if transform_val then
						s = transform_val(s)
					end
					row[di] = s
				end
			end
		end
		local rows = {}
		local ri = 1
		for s in glue.lines(s) do
			local row = {}
			rows[ri] = row
			transform_line(row, s:match(patt))
			ri = ri + 1
		end
		return rows
	end

	function cmd:sqltsv(t, s)
		return self:sqlrows(spp.tsv_rows(t, s), t.rows)
	end

	--row grouping ------------------------------------------------------------

	local function group_key(col)
		return (type(col) == 'string' or type(col) == 'number')
			and function(e) return e[col] end
			or col
	end

	function spp.groups(col, items, group_store_key)
		local t = {}
		local k, st
		local group_key = group_key(col)
		for i,e in ipairs(items) do
			local k1 = group_key(e)
			if not st or k1 ~= k then
				st = {}
				if group_store_key ~= nil then
					st[group_store_key] = k1
				end
				t[#t+1] = st
			end
			st[#st+1] = e
			k = k1
		end
		return t
	end

	function spp.each_group(col, items)
		local group_key = group_key(col)
		local groups = spp.groups(col, items)
		local i, n = 1, #groups
		return function()
			if i > n then return end
			local items = groups[i]
			i = i + 1
			return i-1, group_key(items[1]), items
		end
	end

	--module system -----------------------------------------------------------

	spp.loaded = {}

	function spp.import(pkg)
		for pkg in pkg:gmatch'[^%s]+' do
			if not spp.loaded[pkg] then
				assertf(sqlpp.package[pkg], 'no sqlpp module: %s', pkg)(spp)
				spp.loaded[pkg] = true
			end
		end
		return self
	end

	--command API -------------------------------------------------------------

	spp.errno = {} --{errno->f(err)}

	function cmd:assert(ret, ...)
		if ret ~= nil then
			return ret, ...
		end
		local msg, errno, sqlstate = ...
		local parse = spp.errno[errno]
		local err
		if parse then
			err = errors.new('db', {
				sqlcode = errno,
				sqlstate = sqlstate,
				message = msg,
			})
			parse(self, err)
		else
			err = errors.new('db', {
					sqlcode = errno,
					sqlstate = sqlstate,
					addtraceback = true,
				},
				'%s%s%s', msg,
					errno and ' ['..errno..']' or '',
					sqlstate and ' '..sqlstate or ''
			)
		end
		errors.raise(err)
	end

	local function init_conn(self, opt, rawconn)
		self.rawconn = rawconn
		self.db = rawconn.db
		self.schemas = attr(self:server_cache(), 'schemas')
		if self.db and opt.schema then
			self.schemas[self.db] = opt.schema
		end
		return self
	end

	function spp.connect(opt)
		local self = update({}, cmd)
		return init_conn(self, opt, self:assert(self:rawconnect(opt)))
	end

	function cmd:close()
		self:assert(self.rawconn:close())
	end

	function cmd:use(db, schema)
		self:assert(self.rawconn:use(db))
		self.db = self.rawconn.db
		if self.db and schema then
			self.schemas[self.db] = schema
		end
		return self
	end

	function spp.use(rawconn)
		local self = update({}, cmd)
		return init_conn(self, self:rawuse(rawconn))
	end

	local function query_opt(self, opt)
		if next(self.schemas) then
			local field_attrs = opt.field_attrs
			local function update_field_attrs(rawconn, fields, opt)
				if type(field_attrs) == 'function' then
					field_attrs = field_attrs(rawconn, fields, opt)
				end
				for i,f in ipairs(fields) do
					if f.table and f.db and self.schemas[f.db] then
						update(f, self.schemas[f.db].tables[f.table].fields[f.col])
					end
					if field_attrs then
						update(f, field_attrs[f.name])
					end
				end
			end
			opt.field_attrs = update_field_attrs
		end
		return opt
	end

	local function get_result_sets(self, results, opt, param_names, ret, ...)
		if ret == nil then return nil, ... end --error
		local rows, again, fields = ret, ...
		results = results or (again and {param_names = param_names}) or nil
		if results then --multiple result sets
			add(results, {rows, fields})
			if again then
				return get_result_sets(self, results, opt, param_names,
					self:assert(self:rawagain(opt)))
			else
				return results
			end
		else --single result set
			return rows, fields, param_names
		end
	end

	function cmd:query(opt, sql, ...)

		if opt == nil then --nil, ...
			return self:query(sql, ...)
		elseif type(opt) ~= 'table' then --sql, ...
			return self:query(empty, opt, sql, ...)
		elseif type(sql) == 'table' then --opt1, opt2, ...
			return self:query(update(opt, sql), ...)
		end
		opt = query_opt(self, opt)

		local param_names
		if opt.parse ~= false then
			sql, param_names = self:sqlquery(sql, ...)
		end

		return get_result_sets(self, nil, opt, param_names,
			self:assert(self:rawquery(sql, opt)))
	end

	cmd.exec_with_options = cmd.query

	local function pass(rows, ...)
		if rows and (...) then
			return rows[1], ...
		else
			return rows, ...
		end
	end
	function cmd:first_row(...)
		return pass(self:exec_with_options({to_array=1}, ...))
	end

	function cmd:each_group(col, ...)
		local rows = self:exec_with_options(nil, ...)
		return spp.each_group(col, rows)
	end

	function cmd:each_row(...)
		local rows = self:exec_with_options({to_array=1}, ...)
		return ipairs(rows)
	end

	function cmd:each_row_vals(...)
		local rows, cols = self:exec_with_options({compact=1, to_array=1}, ...)
		local i, n, cn = 1, #rows, #cols
		return function()
			if i > n then return end
			local row = rows[i]
			i = i + 1
			if cn == 1 then --because to_array=1, row is val in this case
				return i-1, row
			else
				return i-1, unpack(row, 1, cn)
			end
		end
	end

	function cmd:prepare(opt, sql, ...)

		if type(opt) ~= 'table' then --sql, ...
			return self:prepare(empty, opt, sql, ...)
		elseif type(sql) == 'table' then --opt1, opt2, ...
			return self:prepare(update(opt, sql), ...)
		end
		opt = query_opt(self, opt)

		local param_names, param_map
		if opt.parse ~= false then
			sql, param_names, param_map = self:sqlprepare(sql, ...)
		end

		local cmd = self
		local function pass(rawstmt, ...)
			if rawstmt == nil then return nil, ... end

			local stmt = {
				exec          = cmd.exec,
				first_row     = cmd.first_row,
				each_group    = cmd.each_group,
				each_row      = cmd.each_row,
				each_row_vals = cmd.each_row_vals,
			}

			function stmt:free()
				return cmd:rawstmt_free(rawstmt)
			end

			function stmt:exec_with_options(exec_opt, ...)
				local t = map_params(self, cmd, param_map, ...)
				local opt = exec_opt and update(exec_opt, opt) or opt
				return get_result_sets(cmd, nil, opt, param_names,
					cmd:assert(cmd:rawstmt_query(rawstmt, opt, unpack(t, 1, t.n))))
			end

			function stmt:exec(...)
				return self:exec_with_options(nil, ...)
			end

			return stmt, param_names
		end
		return pass(self:assert(self:rawprepare(sql, opt)))
	end

	function cmd:atomic(f, ...)
		self:query('start transaction')
		local function pass(ok, ...)
			self:query(ok and 'commit' or 'rollback')
			return assert(ok, ...)
		end
		return pass(glue.pcall(f, ...))
	end

	--schema reflection -------------------------------------------------------

	function cmd:dbs()
		return self:exec_with_options({to_array=1}, 'show databases')
	end

	function cmd:tables(db)
		return self:exec_with_options({to_array=1},
			'show tables from ??', db or self.db)
	end

	local server_caches = {}

	function cmd:server_cache()
		return attr(server_caches, self.server_cache_key)
	end

	function cmd:needs_quoting(s)
		local t = self:server_cache()
		local rt = t.reserved_words
		if not rt then
			rt = self:get_reserved_words()
			t.reserved_words = rt
		end
		return rt[s]
	end

	local function strip_ticks(s)
		return s:gsub('^`', ''):gsub('`$', '')
	end
	function cmd:table_def(db_tbl, opt)
		local db, tbl = db_tbl:match'^(.-)%.(.*)$'
		if not db then
			db, tbl = assert(self.db), db_tbl
		end
		db  = strip_ticks(db)
		tbl = strip_ticks(tbl)
		db_tbl = db..'.'..tbl
		local schemas = self.schemas
		local schema = schemas and schemas[db]
		return schema and schema.tables[tbl]
	end

	function spp.empty_schema()
		local schema = require'schema'
		return schema.new(update({engine = spp.engine}, spp.schema_options))
	end

	function cmd:empty_schema()
		return spp.empty_schema()
	end

	function cmd:extract_schema(db)
		db = db or assert(self.db)
		local sc = self:empty_schema()
		for db_tbl, tbl in pairs(self:get_table_defs{db = db, all=1}) do
			sc.tables[tbl.name] = tbl
		end
		sc.procs = self:get_procs(db)[db]
		return sc
	end

	--DDL commands ------------------------------------------------------------

	function cmd:create_db(name, charset, collation)
		return self:assert(self:query(outdent[[
			create database if not exists ::name
				#if charset
				character set {charset}
				#endif
				#if collation
				collate {collation}
				#endif
			]], {
				name      = name,
				charset   = charset,
				collation = collation,
			}))
	end

	function cmd:drop_db(name)
		return self:query('drop database if exists ??', name)
	end

	function cmd:sync_schema(src, opt)
		opt = opt or empty
		local schema = require'schema'
		local src_sc =
			schema.isschema(src) and src
			or sqlpp.ispp(src) and src:extract_schema()
			or assertf(false, 'schema or sqlpp expected, got %s', type(src))
		local this_sc = self:extract_schema()
		local diff = schema.diff(this_sc, src_sc)
		local qopt = {parse = false}
		local sqls = self:sqldiff(diff)
		if #sqls == 0 then
			if opt.dry then
				print'\n/***** SCHEMA ALREADY SYNC\'ED ******/\n'
			end
		else
			if opt.dry then
				print'\n/******** BEGIN SYNC SCHEMA ********/\n'
			end
			for _,sql in ipairs(sqls) do
				if opt.dry then
					print(sql)
				else
					self:query(qopt, sql)
				end
			end
			if opt.dry then
				print'\n/********* END SYNC SCHEMA *********/\n'
			end
		end
	end

	--MDL commands ------------------------------------------------------------

	local function col_map_arg(s)
		if type(s) ~= 'string' then
			return s or empty
		end
		local t = {}
		for _,s in ipairs(names(s)) do
			local col, val_name = s:match'^(.-)=(.*)'
			if not col then
				col, val_name = s, s
			end
			t[col] = val_name
		end
		return t
	end

	local function where_sql(self, vals, col_map, pk, fields, security_filter)
		local t = {}
		for i, col in ipairs(pk) do
			local val_name = col..':old'
			local val_name = col_map[val_name] or val_name
			local v = vals[val_name]
			local field = fields[col]
			if i > 1 then add(t, ' and ') end
			add(t, self:sqlname(col)..' = '..self:sqlval(v, field))
		end
		local sql = cat(t)
		if security_filter then
			sql = '('..sql..') and ('..security_filter..')'
		end
		return sql
	end

	local function set_sql(self, vals, col_map, fields)
		local t = {}
		for _, field in ipairs(fields) do
			local val_name = col_map[field.col]
			if val_name then
				local v = vals[val_name]
				if v ~= nil then
					add(t, self:sqlname(field.col)..' = '..self:sqlval(v, field))
				end
			end
		end
		return #t > 0 and cat(t, ',\n\t')
	end

	local function pass(ret, ...)
		if not ret then return nil, ... end
		return repl(ret.insert_id, 0, nil)
	end
	function cmd:insert_row(tbl, vals, col_map)
		local col_map = col_map_arg(col_map)
		local tdef = self:table_def(tbl)
		local set_sql = set_sql(self, vals, col_map, tdef.fields)
		local sql
		if not set_sql then --no fields, special syntax.
			sql = fmt('insert into %s values ()', self:sqlname(tbl))
		else
			sql = fmt(outdent[[
				insert into %s set
					%s
			]], self:sqlname(tbl), set_sql)
		end
		return pass(self:query({parse = false}, sql))
	end
	function cmd:insert_or_update_row(tbl, vals, col_map)
		local col_map = col_map_arg(col_map)
		local tdef = self:table_def(tbl)
		local set_sql = set_sql(self, vals, col_map, tdef.fields)
		local sql = fmt(outdent[[
				insert into %s set
					%s
				on duplicate key update
					%s
			]], self:sqlname(tbl), set_sql, set_sql)
		return pass(self:query({parse = false}, sql))
	end

	function cmd:update_row(tbl, vals, col_map, security_filter)
		local col_map = col_map_arg(col_map)
		local tdef = self:table_def(tbl)
		local set_sql = set_sql(self, vals, col_map, tdef.fields)
		if not set_sql then
			return
		end
		local where_sql = where_sql(self, vals, col_map, tdef.pk, tdef.fields, security_filter)
		local sql = fmt(outdent[[
			update %s set
				%s
			where %s
		]], self:sqlname(tbl), set_sql, where_sql)
		return self:query({parse = false}, sql)
	end

	function cmd:delete_row(tbl, vals, col_map, security_filter)
		local col_map = col_map_arg(col_map)
		local tdef = self:table_def(tbl)
		local where_sql = where_sql(self, vals, col_map, tdef.pk, tdef.fields, security_filter)
		local sql = fmt(outdent[[
			delete from %s where %s
		]], self:sqlname(tbl), where_sql)
		return self:query({parse = false}, sql)
	end

	--NOTE: The returned insert_id is that of the first inserted row.
	--You do the math for the other rows, they should be consecutive even
	--while other inserts are happening at the same time but I'm not sure.
	function cmd:insert_rows(tbl, rows, col_map, compact)
		local col_map = col_map_arg(col_map)
		if #rows == 0 then
			return
		end
		local tdef = self:table_def(tbl)
		local rows_sql = self:sqlrows(rows, {
			col_map = col_map,
			fields = tdef.fields,
			compact = compact,
			indent = '\t',
		})
		local t = {}
		for i,s in ipairs(glue.keys(col_map, true)) do
			t[i] = self:sqlname(s)
		end
		local cols_sql = cat(t, ', ')
		local sql = fmt(outdent[[
			insert into %s
				(%s)
			values
				%s
		]], self:sqlname(tbl), cols_sql, rows_sql)
		return pass(self:query({parse = false}, sql))
	end

	function cmd:copy_table(tbl, dst_cmd)

		local rows, cols = self:query({compact=1, noparse=1},
			'select * from '..self:sqlname(tbl))

		local CONVERT = spp.engine .. '_to_' .. dst_cmd.spp.engine
		for fi,col in ipairs(cols) do
			local f = col[CONVERT]
			if f then
				for ri,row in ipairs(rows) do
					row[fi] = f(row[fi], col, row, spp)
				end
			end
		end

		for i,row in ipairs(rows) do
			dst_cmd:raw_insert_row(tbl, row, #cols)
			if i % 10000 == 0 then
				print(i)
			end
		end

	end

	init(spp, cmd)

	return spp
end

return sqlpp
