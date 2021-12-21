
--RDBMS schema definition language & operations
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'schema_test'; return end

local glue = require'glue'

local add = table.insert
local cat = table.concat

local isstr = glue.isstr
local istab = glue.istab
local isfunc = glue.isfunc
local assertf = glue.assert
local attr = glue.attr
local update = glue.update
local names = glue.names
local pack = glue.pack
local unpack = glue.unpack
local keys = glue.keys
local empty = glue.empty
local kbytes = glue.kbytes
local sortedpairs = glue.sortedpairs
local catargs = glue.catargs
local repl = glue.repl
local imap = glue.imap
local _ = string.format
local trim = glue.trim
local index = glue.index
local outdent = glue.outdent
local extend = glue.extend

--definition parsing ---------------------------------------------------------

--NOTE: flag names clash with unquoted field names!
--NOTE: env names clash with all unquoted names!

local function isschema(t) return istab(t) and t.is_schema end

local schema = {is_schema = true, package = {}, isschema = isschema}

--NOTE: the double-underscore is for disambiguation, not for aesthetics.
schema.fk_name_format = 'fk_%s__%s'
schema.ck_name_format = 'ck_%s__%s'
schema.ix_name_format = '%s_%s__%s'

local function resolve_type(self, fld, t, i, n, fld_ct, allow_types, allow_flags, allow_unknown)
	for i = i, n do
		local k = t[i]
		local v = k
		if isstr(v) then --type name, flag name or next field
			v = allow_types and self.types[k] or allow_flags and self.flags[k]
			if not v and allow_unknown then --next field
				return i
			end
		end
		assertf(v ~= nil, 'unknown flag or type name `%s`', k)
		if isfunc(v) then --type generator
			v = v(self, fld_ct, fld)
		end
		if v then
			resolve_type(self, fld, v, 1, #v, fld_ct, true, true) --recurse
			for k,v in pairs(v) do --copy named attrs
				if isstr(k) then
					fld[k] = v
				end
			end
		end
	end
	return n + 1
end

local function parse_cols(self, t, dt, loc1, fld_ct)
	local i = 1
	while i <= #t do --[out], field_name, type_name, flag_name|{attr->val}, ...
		if i == 1 and not isstr(t[1]) then --aka for renaming the table.
			t[1](self, fld_ct)
			i = i + 1
		end
		local col, mode
		if not fld_ct.is_table then --this is a proc param, not a table field.
			mode = t[i]
			if mode == 'out' then
				i = i + 1
			else
				mode = nil --'in' (default)
			end
		end
		col = t[i]
		assertf(isstr(col), 'column name expected for `%s`, got %s', loc1, type(col))
		i = i + 1
		local fld = {col = col, mode = mode}
		if fld_ct.is_table then
			local col_pos = #dt + 1
			fld.col_pos = col_pos
			fld.col_in_front = col_pos > 1 and dt[col_pos-1].col
		end
		add(dt, fld)
		dt[col] = fld
		i = resolve_type(self, fld, t, i, i , fld_ct, true, false)
		i = resolve_type(self, fld, t, i, #t, fld_ct, false, true, true)
	end
end

local function resolve_fk(fk, tbl, ref_tbl)
	assertf(ref_tbl.pk, 'ref table `%s` has no PK', ref_tbl.name)
	fk.ref_cols = extend({}, ref_tbl.pk)
	--add convenience ref fields for automatic lookup in x-widgets.
	if #fk.cols == 1 then
		local fld = tbl.fields[fk.cols[1]]
		fld.ref_table = ref_tbl.name
		fld.ref_col   = ref_tbl.pk[1]
	end
end

local function parse_table(self, name, t)
	local tbl = {is_table = true, name = name, fields = {}}
	parse_cols(self, t, tbl.fields, name, tbl)
	--resolve fks that ref this table.
	local fks = self.table_refs and self.table_refs[name]
	if fks then
		for fk in pairs(fks) do
			local fk_tbl =
				fk.table == name and tbl --self-reference
				or self.tables[fk.table]
			resolve_fk(fk, fk_tbl, tbl)
		end
		self.table_refs[name] = nil
	end
	--add API to table to add more cols after-definition.
	function tbl.add_cols(t)
		parse_cols(self, t, tbl.fields, name, tbl)
	end
	return tbl
end

local function parse_ix_cols(fld, ...) --'col1 [desc], ...'
	if not ... then
		return {fld.col}
	end
	local s = cat({...}, ',')
	local dt = {desc = {}}
	for s in s:gmatch'[^,]+' do
		s = trim(s)
		local name, desc = s:match'(.-)%s+desc$'
		if name then
			desc = true
		else
			name, desc = s, false
		end
		add(dt, name)
		add(dt.desc, desc and true or false)
	end
	return dt
end

local function check_cols(T, tbl, cols)
	for i,col in ipairs(cols) do
		local found = false
		for i,fld in ipairs(tbl.fields) do
			if fld.col == col then found = true; break end
		end
		assertf(found, 'unknown column in %s of `%s`: `%s`', T, tbl.name, col)
	end
	return cols
end

local function return_false() return false end

local function add_pk(self, tbl, cols)
	assertf(not tbl.pk, 'pk already applied for table `%s`', tbl.name)
	tbl.pk = check_cols('pk', tbl, cols)
	tbl.pk.desc = imap(cols, return_false)
end

local function add_ix(self, T, tbl, cols)
	local t = attr(tbl, T..'s')
	local k = _(self.ix_name_format, T, tbl.name, cat(cols, '_'))
	assertf(not t[k], 'duplicate %s `%s`', T, k)
	t[k] = check_cols(T, tbl, cols)
end

local function add_fk(self, tbl, cols, ref_tbl_name, ondelete, onupdate, fld)
	local fks = attr(tbl, 'fks')
	local k = _(self.fk_name_format, tbl.name, cat(cols, '_'))
	assertf(not fks[k], 'duplicate fk `%s`', k)
	ref_tbl_name = ref_tbl_name or assert(#cols == 1 and cols[1])
	local cols = check_cols('fk', tbl, cols)
	cols.desc = imap(cols, return_false)
	local fk = {name = k, table = tbl.name, cols = cols,
		ref_table = ref_tbl_name, ondelete = ondelete, onupdate = onupdate}
	fks[k] = fk
	local ref_tbl =
		ref_tbl_name == tbl.name and tbl --self-reference
		or self.tables[ref_tbl_name]
	if ref_tbl then
		resolve_fk(fk, tbl, ref_tbl)
	else --we'll resolve it when the table is defined later.
		attr(attr(self, 'table_refs'), ref_tbl_name)[fk] = true
	end
end

do
	local function add_global(t, k, v)
		assertf(not t.flags [k], 'global overshadows flag `%s`', k)
		assertf(not t.types [k], 'global overshadows type `%s`', k)
		assertf(not t.tables[k], 'global overshadows table `%s`', k)
		assertf(not t.procs [k], 'global overshadows proc `%s`', k)
		rawset(t, k, v)
	end
	local T = function() end
	local function getter(t, k) return t[T][k] end
	local function init(self, env, k, parse)
		local k1 = k:gsub('s$', '')
		local t = update({}, schema[k])
		self[k] = t
		env[k] = setmetatable({}, {
			__index = t,
			__newindex = function(_, k, v)
				assertf(not t[k], 'duplicate %s `%s`', k1, k)
				t[k] = parse(self, k, v)
			end,
		})
	end
	function schema.new(opt)
		assert(opt ~= schema, 'use dot notation')
		local self = update(opt or {}, schema)
		local env = update({self = self}, schema.env)
		self.flags = update({}, schema.flags)
		self.types = update({}, schema.types)
		self.procs = {}
		env.flags = self.flags
		env.types = self.types
		init(self, env, 'tables', parse_table)
		local function resolve_symbol(t, k)
			return k --symbols resolve to their name as string.
		end
		setmetatable(env, {__index = resolve_symbol, __newindex = add_global})
		self.env = env
		self.loaded = {}

		function env.import  (...) self:import      (...) end
		function env.add_fk  (...) self:add_fk      (...) end
		function env.trigger (...) self:add_trigger (...) end
		function env.proc    (...) self:add_proc    (...) end

		return self
	end
end

local function import(self, k, sc)
	local k1 = k:gsub('s$', '')
	for k,v in pairs(sc[k]) do
		assertf(not self[k], 'duplicate %s `%s`', k1, k)
		self[k] = v
	end
end
function schema:import(src)
	if isstr(src) then --module
		src = schema.package[src] or require(src)
	end
	if isfunc(src) then --def
		if not self.loaded[src] then
			setfenv(src, self.env)
			src()
			self.loaded[src] = true
		end
	elseif isschema(src) then --schema
		if not self.loaded[src] then
			import(self, 'types' , sc)
			import(self, 'tables', sc)
			import(self, 'procs' , sc)
			self.loaded[src] = true
		end
	elseif istab(src) then --plain table: use as environsment.
		update(self.env, src)
	else
		assert(false)
	end
	return self
end

schema.env = {_G = _G}

local function fk_func(force_ondelete, force_onupdate)
	return function(arg1, ...)
		if isschema(arg1) then --used as flag: make a fk on current field.
			local self, tbl, fld = arg1, ...
			add_fk(self, tbl, {fld.col}, nil,
				force_ondelete,
				force_onupdate,
				fld)
		else --called by user, return a flag generator.
			local ref_tbl, ondelete, onupdate = arg1, ...
			return function(self, tbl, fld)
				add_fk(self, tbl, {fld.col}, ref_tbl,
					force_ondelete or ondelete,
					force_onupdate or onupdate,
					fld)
			end
		end
	end
end
schema.env.fk       = fk_func(nil, 'cascade')
schema.env.child_fk = fk_func('cascade', 'cascade')
schema.env.weak_fk  = fk_func('set null', 'cascade')

function schema:add_fk(tbl, cols, ...)
	local tbl = assertf(self.tables[tbl], 'unknown table `%s`', tbl)
	add_fk(self, tbl, names(cols), ...)
end

local function ix_func(T)
	return function(arg1, ...)
		if isschema(arg1) then --used as flag: make an index on current field.
			local self, tbl, fld = arg1, ...
			add_ix(self, T, tbl, {fld.col, desc = {false}})
			fld[T] = true
		else --called by user, return a flag generator.
			local cols = pack(arg1, ...)
			return function(self, tbl, fld)
				local cols = parse_ix_cols(fld, unpack(cols))
				add_ix(self, T, tbl, cols)
			end
		end
	end
end
schema.env.uk = ix_func'uk'
schema.env.ix = ix_func'ix'

schema.flags = {}
schema.types = {}

function schema.env.pk(arg1, ...)
	if isschema(arg1) then --used as flag.
		local self, tbl, cur_fld = arg1, ...
		add_pk(self, tbl, imap(tbl.fields, 'col'))
		--apply `not_null` flag to all fields up to this.
		for _,fld in ipairs(tbl.fields) do
			fld.not_null = true
			if fld == cur_fld then break end
		end
	else --called by user, return a flag generator.
		local cols = pack(arg1, ...)
		return function(self, tbl, fld)
			local cols = parse_ix_cols(fld, unpack(cols))
			add_pk(self, tbl, cols)
		end
	end
end

function schema.env.check(body)
	return function(self, tbl, fld)
		local name = _(self.ck_name_format, tbl.name, fld.col)
		local ck = {}
		if istab(body) then
			update(ck, body) --mysql'...'
		else
			ck.body = body
		end
		attr(tbl, 'checks')[name] = ck
	end
end

function schema.env.aka(old_names)
	return function(self, tbl, fld)
		local entity = fld or tbl --table rename or field rename.
		for _,old_name in ipairs(names(old_names)) do
			attr(entity, 'aka')[old_name] = true
		end
	end
end

local function trigger_pos(tgs, when, op)
	local i = 1
	for _,tg in pairs(tgs) do
		if tg.when == when and tg.op == op then
			i = i + 1
		end
	end
	return i
end
function schema:add_trigger(name, when, op, tbl_name, ...)
	name = _('%s_%s_%s%s', tbl_name, name, when:sub(1,1), op:sub(1,1))
	local tbl = assertf(self.tables[tbl_name], 'unknown table `%s`', tbl_name)
	local triggers = attr(tbl, 'triggers')
	assertf(not triggers[name], 'duplicate trigger `%s`', name)
	triggers[name] = update({name = name, when = when, op = op,
		table = tbl_name, pos = trigger_pos(triggers, when, op)}, ...)
end

function schema:add_proc(name, args, ...)
	local p = {name = name, args = {}}
	parse_cols(self, args, p.args, name, p)
	update(p, ...)
	self.procs[name] = p
end

function schema:add_cols(...)
	--TODO:
end

function schema:check_refs()
	if not self.table_refs or not next(self.table_refs) then return end
	assertf(false, 'unresolved refs to tables: %s', cat(keys(self.table_refs, true), ', '))
end

--schema diff'ing ------------------------------------------------------------

local function map_fields(flds)
	local t = {}
	for i,fld in ipairs(flds) do
		t[fld.col] = fld
	end
	return t
end

local function diff_maps(self, t1, t0, diff_vals, map, sc0, supported) --sync t0 to t1.
	if not supported then return nil end
	t1 = t1 and (map and map(t1) or t1) or empty
	t0 = t0 and (map and map(t0) or t0) or empty

	--map out current renames.
	local new_name --{old_name->new_name}
	local old_name --{new_name->old_name}
	for k1, v1 in pairs(t1) do
		if istab(v1) and v1.aka then
			for k0 in pairs(v1.aka) do
				if t0[k0] ~= nil then
					if not old_name then
						old_name = {}
						new_name = {}
					end
					assertf(not old_name[k1], 'double rename for `%s`', k1)
					new_name[k0] = k1
					old_name[k1] = k0
				end
			end
		end
	end

	local dt = {}

	--remove names not present in new schema and not renamed.
	for k0,v0 in pairs(t0) do
		local v1 = new_name and t1[new_name[k0]] --must rename, not remove.
		if v1 == nil and t1[k0] ~= nil then --old name in new schema, keep it?
			if not (old_name and old_name[k0]) then --not a rename of other field, keep it.
				v1 = t1[k0]
			end
		end
		if v1 == nil then
			attr(dt, 'remove')[k0] = v0
		end
	end

	--add names not present in old schema and not renamed, or update.
	for k1,v1 in pairs(t1) do
		local v0 = t0[k1]
		if v0 == nil and old_name then --not present in old schema, check if renamed.
			v0 = t0[old_name[k1]]
		end
		if v0 == nil then
			attr(dt, 'add')[k1] = v1
		elseif diff_vals then
			local k0 = old_name and old_name[k1] or k1
			local vdt = diff_vals(self, v1, v0, sc0)
			if vdt == true then
				attr(dt, 'remove')[k0] = v0
				attr(dt, 'add'   )[k1] = v1
			elseif vdt then
				attr(dt, 'update')[k0] = vdt
			end
		end
	end

	return next(dt) and dt or nil
end

local function diff_arrays(a1, a0)
	a1 = a1 or empty
	a0 = a0 or empty
	if #a1 ~= #a0 then return true end
	for i,s in ipairs(a1) do
		if a0[i] ~= s then return true end
	end
	return false
end
local function diff_ixs(self, c1, c0)
	return diff_arrays(c1, c0) or diff_arrays(c1.desc, c0.desc)
end

local function not_eq(_, a, b) return a ~= b end
local function diff_keys(self, t1, t0, keys)
	local dt = {}
	for k, diff in pairs(keys) do
		if not isfunc(diff) then diff = not_eq end
		if diff(self, t1[k], t0[k]) then
			dt[k] = true
		end
	end
	return next(dt) and {old = t0, new = t1, changed = dt}
end

local function diff_fields(self, f1, f0, sc0)
	return diff_keys(self, f1, f0, sc0.relevant_field_attrs)
end

local function diff_fks(self, fk1, fk0)
	return diff_keys(self, fk1, fk0, {
		table=1,
		ref_table=1,
		onupdate=1,
		ondelete=1,
		cols=function(self, c1, c0) return diff_ixs(self, c1, c0) end,
		ref_cols=function(self, c1, c0) return diff_ixs(self, c1, c0) end,
	}) and true
end

local function diff_checks(self, c1, c0)
	local BODY = self.engine..'_body'
	local b1 = c1[BODY] or c1.body
	local b0 = c0[BODY] or c0.body
	return b1 ~= b0
end

local function diff_triggers(self, t1, t0)
	local BODY = self.engine..'_body'
	return diff_keys(self, t1, t0, {
		pos=1,
		when=1,
		op=1,
		[BODY]=1,
	}) and true
end

local function diff_procs(self, p1, p0, sc0)
	local BODY = self.engine..'_body'
	return diff_keys(self, p1, p0, {
		[BODY]=1,
		args=function(self, a1, a0)
			return diff_maps(self, a1, a0, diff_fields, map_fields, sc0, true) and true
		end,
	}) and true
end

local function diff_tables(self, t1, t0, sc0)
	local d = {}
	d.fields   = diff_maps(self, t1.fields  , t0.fields  , diff_fields   , map_fields, sc0, true)
	local pk   = diff_maps(self, {pk=t1.pk} , {pk=t0.pk} , diff_ixs      , nil, sc0, true)
	d.uks      = diff_maps(self, t1.uks     , t0.uks     , diff_ixs      , nil, sc0, true)
	d.ixs      = diff_maps(self, t1.ixs     , t0.ixs     , diff_ixs      , nil, sc0, true)
	d.fks      = diff_maps(self, t1.fks     , t0.fks     , diff_fks      , nil, sc0, sc0.supports_fks     )
	d.checks   = diff_maps(self, t1.checks  , t0.checks  , diff_checks   , nil, sc0, sc0.supports_checks  )
	d.triggers = diff_maps(self, t1.triggers, t0.triggers, diff_triggers , nil, sc0, sc0.supports_triggers)
	d.add_pk    = pk and pk.add    and pk.add.pk
	d.remove_pk = pk and pk.remove and pk.remove.pk
	if not (next(d) or t1.name ~= t0.name) then return nil end
	d.old = t0
	d.new = t1
	return d
end

local diff = {is_diff = true}

function schema.diff(sc0, sc1, opt) --sync sc0 to sc1.
	local sc0 = assertf(isschema(sc0) and sc0, 'schema expected, got `%s`', type(sc0))
	sc0:check_refs()
	sc1:check_refs()
	local self = {engine = sc0.engine, __index = diff, old_schema = sc0, new_schema = sc1}
	self.tables = diff_maps(self, sc1.tables, sc0.tables, diff_tables, nil, sc0, true)
	self.procs  = diff_maps(self, sc1.procs , sc0.procs , diff_procs , nil, sc0, sc0.supports_procs)
	return setmetatable(self, self)
end

--diff pretty-printing -------------------------------------------------------

local function dots(s, n) return #s > n and s:sub(1, n-2)..'..' or s end
local kbytes = function(x) return x and kbytes(x) or '' end
local function P(...) print(_(...)) end
function diff:pp(opt)
	local BODY = self.engine..'_body'
	print()
	local function P_fld(fld, prefix)
		P(' %1s %3s %-2s%-16s %-8s %4s%1s %6s %6s %-18s %s',
			fld.auto_increment and 'A' or '',
			prefix or '',
			fld.not_null and '*' or '',
			dots(fld.col, 16), fld.type or '',
			fld.type == 'number' and not fld.digits and '['..fld.size..']'
			or fld.type == 'bool' and ''
			or (fld.digits or '')..(fld.decimals and ','..fld.decimals or ''),
			fld.type == 'number' and not fld.unsigned and '-' or '',
			kbytes(fld.size) or '', kbytes(fld.maxlen) or '',
			fld[self.engine..'_collation'] or '',
			repl(repl(fld[self.engine..'_default'], nil, fld.default), nil, '')
		)
	end
	local function format_fk(fk)
		return _('(%s) -> %s (%s)%s%s', cat(fk.cols, ','), fk.ref_table,
				cat(fk.ref_cols, ','),
				fk.ondelete and ' D:'..fk.ondelete or '',
				fk.onupdate and ' U:'..fk.onupdate or ''
			)
	end
	local function ix_cols(ix)
		local dt = {}
		for i,s in ipairs(ix) do
			dt[i] = s .. (ix.desc and ix.desc[i] and ':desc' or '')
		end
		return cat(dt, ',')
	end
	local function P_tg(tg, prefix)
		if not tg[BODY] then return end
		P('   %1sTG %d %s %s `%s`', prefix or '', tg.pos, tg.when, tg.op, tg.name)
		if prefix ~= '-' then
			print(outdent(tg[BODY], '         '))
		end
	end
	if self.tables and self.tables.add then
		for tbl_name, tbl in sortedpairs(self.tables.add) do
			P(' %-24s %-8s %2s,%-1s%1s %6s %6s %-18s %s', '+ TABLE '..tbl_name,
				'type', 'D', 'd', '-', 'size', 'maxlen', 'collation', 'default')
			print(('-'):rep(80))
			local pk = tbl.pk and index(tbl.pk)
			for i,fld in ipairs(tbl.fields) do
				local pki = pk and pk[fld.col]
				local desc = pki and tbl.pk.desc and tbl.pk.desc[pki]
				P_fld(fld, pki and _('%sK%d', desc and 'p' or 'P', pki))
			end
			print('    -------')
			if tbl.uks then
				for uk_name, uk in sortedpairs(tbl.uks) do
					P('    UK   %s', ix_cols(uk))
				end
			end
			if tbl.ixs then
				for ix_name, ix in sortedpairs(tbl.ixs) do
					P('    IX   %s', ix_cols(ix))
				end
			end
			if tbl.fks then
				for fk_name, fk in sortedpairs(tbl.fks) do
					P('    FK   %s', format_fk(fk))
				end
			end
			if tbl.checks then
				for ck_name, ck in sortedpairs(tbl.checks) do
					P('    CK   %s', ck[BODY] or ck.body)
				end
			end
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
					P_tg(tg)
				end
			end
			print()
		end
	end
	if self.tables and self.tables.update then
		local hide_attrs = opt and opt.hide_attrs
		for old_tbl_name, d in sortedpairs(self.tables.update) do
			if opt and opt.tables and not opt.tables[old_tbl_name] then
				goto skip
			end
			P(' ~ TABLE %s%s', old_tbl_name,
				d.new.name ~= old_tbl_name and ' -> '..d.new.name or '')
			print(('-'):rep(80))
			if d.fields and d.fields.add then
				for col, fld in sortedpairs(d.fields.add) do
					P_fld(fld, '+')
				end
			end
			if d.fields and d.fields.remove then
				for col, fld in sortedpairs(d.fields.remove) do
					P_fld(fld, '-')
				end
			end
			if d.fields and d.fields.update then
				for col, d in sortedpairs(d.fields.update) do
					P_fld(d.old, '<')
					P_fld(d.new, '>')
					for k in sortedpairs(d.changed) do
						P('           %-14s %s -> %s', k, d.old[k], d.new[k])
					end
				end
			end
			if d.remove_pk then
					P('   -PK   %s', ix_cols(d.remove_pk))
			end
			if d.add_pk then
					P('   +PK   %s', ix_cols(d.add_pk))
			end
			if d.uks and d.uks.remove then
				for uk_name, uk in sortedpairs(d.uks.remove) do
					P('   -UK   %s', ix_cols(uk))
				end
			end
			if d.uks and d.uks.add then
				for uk_name, uk in sortedpairs(d.uks.add) do
					P('   +UK   %s', ix_cols(uk))
				end
			end
			if d.ixs and d.ixs.remove then
				for ix_name, ix in sortedpairs(d.ixs.remove) do
					P('   -IX   %s', ix_cols(ix))
				end
			end
			if d.ixs and d.ixs.add then
				for ix_name, ix in sortedpairs(d.ixs.add) do
					P('   +IX   %s', ix_cols(ix))
				end
			end
			if d.checks and d.checks.remove then
				for ck_name, ck in sortedpairs(d.checks.remove) do
					P('   -CK   %s', ck[BODY] or ck.body)
				end
			end
			if d.checks and d.checks.add then
				for ck_name, ck in sortedpairs(d.checks.add) do
					P('   +CK   %s', ck[BODY] or ck.body)
				end
			end
			if d.fks and d.fks.remove then
				for fk_name, fk in sortedpairs(d.fks.remove) do
					P('   -FK   %s', format_fk(fk))
				end
			end
			if d.fks and d.fks.add then
				for fk_name, fk in sortedpairs(d.fks.add) do
					P('   +FK   %s', format_fk(fk))
				end
			end
			if d.triggers and d.triggers.remove then
				for tg_name, tg in sortedpairs(d.triggers.remove) do
					P_tg(tg, '-')
				end
			end
			if d.triggers and d.triggers.add then
				for tg_name, tg in sortedpairs(d.triggers.add) do
					P_tg(tg, '+')
				end
			end
			print()
			::skip::
		end
	end
	if self.tables and self.tables.remove then
		for tbl_name in sortedpairs(self.tables.remove) do
			P('  - TABLE %s', tbl_name)
		end
		print()
	end
	if self.procs and self.procs.remove then
		for proc_name, proc in sortedpairs(self.procs.remove) do
			if proc[BODY] then
				P(' - PROC %s', proc_name)
			end
		end
		print()
	end
	if self.procs and self.procs.add then
		for proc_name, proc in sortedpairs(self.procs.add) do
			if proc[BODY] then
				P(' + PROC %s(', proc_name)
				for i,arg in ipairs(proc.args) do
					P_fld(arg)
				end
				P('\t)\n%s', proc[BODY])
			end
		end
		print()
	end
end

return schema
