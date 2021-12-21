
--Tarantool sqlpp backend.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'test'; return end

local glue = require'glue'
local tarantool = require'tarantool'
local mp = require'msgpack'

--[[
local fmt = string.format
local add = table.insert
local cat = table.concat

local repl = glue.repl
local outdent = glue.outdent
local sortedpairs = glue.sortedpairs
local subst = glue.subst
local attr = glue.attr
local imap = glue.imap
local index = glue.index
local update = glue.update
]]
local catargs = glue.catargs
local empty = glue.empty


--https://www.tarantool.io/en/doc/latest/reference/reference_sql/sql_user_guide/#reserved-words
local reserved_words = {}
for s in ([[
ALL ALTER ANALYZE AND ANY AS ASC ASENSITIVE AUTOINCREMENT BEGIN BETWEEN BINARY BLOB BOOL BOOLEAN BOTH BY CALL CASE CAST CHAR CHARACTER CHECK COLLATE COLUMN COMMIT CONDITION CONNECT CONSTRAINT CREATE CROSS CURRENT CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER CURSOR DATE DATETIME dec DECIMAL DECLARE DEFAULT DEFERRABLE DELETE DENSE_RANK DESC DESCRIBE DETERMINISTIC DISTINCT DOUBLE DROP EACH ELSE ELSEIF END ESCAPE EXCEPT EXISTS EXPLAIN FALSE FETCH FLOAT FOR FOREIGN FROM FULL FUNCTION GET GRANT GROUP HAVING IF IMMEDIATE IN INDEX INNER INOUT INSENSITIVE INSERT INT INTEGER INTERSECT INTO IS ITERATE JOIN LEADING LEAVE LEFT LIKE LIMIT LOCALTIME LOCALTIMESTAMP LOOP MATCH NATURAL NOT NULL NUM NUMBER NUMERIC OF ON OR ORDER OUT OUTER OVER PARTIAL PARTITION PRAGMA PRECISION PRIMARY PROCEDURE RANGE RANK READS REAL RECURSIVE REFERENCES REGEXP RELEASE RENAME REPEAT REPLACE RESIGNAL RETURN REVOKE RIGHT ROLLBACK ROW ROWS ROW_NUMBER SAVEPOINT SCALAR SELECT SENSITIVE SESSION SET SIGNAL SIMPLE SMALLINT SPECIFIC SQL START STRING SYSTEM TABLE TEXT THEN TO TRAILING TRANSACTION TRIGGER TRIM TRUE TRUNCATE UNION UNIQUE UNKNOWN UNSIGNED UPDATE USER USING UUID VALUES VARBINARY VARCHAR VIEW WHEN WHENEVER WHERE WHILE WITH
]]):lower():gmatch'[^%s]+' do
	reserved_words[s] = true
end

local function init_spp(spp, cmd)

	--command API -------------------------------------------------------------

	local function first_elem(row) return row[1] end
	local function pass(self, cn, ...)
		if not cn then return cn, ... end
		cn.db = 'default' --always
		self.server_cache_key = cn.host..':'..cn.port
		function self:rawquery(sql, opt)
			local rows, cols = cn:exec(sql)
			if not rows then return nil, cols end
			if cols then --it's a select
				if opt.to_array and #cols == 1 then
					rows = imap(rows, first_elem)
				elseif not opt.compact then
					local crows = rows
					rows = {}
					for i, crow in ipairs(crows) do
						local row = {}
						rows[i] = row
						for i,col in ipairs(cols) do
							row[col.col] = crow[i]
						end
					end
				end
			end
			return rows, nil, cols
		end
		function self:rawprepare(sql)
			return cn:prepare(sql)
		end
		return cn
	end
	function cmd:rawconnect(opt)
		if opt and opt.fake then
			return {fake = true, host = 'fake', port = 'fake', esc = cmd.esc}
		end
		return pass(self, tarantool.connect(opt))
	end
	function cmd:rawuse(cn)
		return pass(self, cn)
	end

	function cmd:rawstmt_query(rawstmt, opt, ...)
		return rawstmt:exec({...}, opt)
	end

	function cmd:rawstmt_free(rawstmt)
		rawstmt:free()
	end

	--SQL quoting -------------------------------------------------------------

	function cmd:get_reserved_words()
		return reserved_words
	end

	function cmd:esc(s)
		return tarantool.esc(s)
	end

	local needs_quoting = cmd.needs_quoting
	function cmd:needs_quoting(s)
		return needs_quoting(self, s) or (s and s ~= s:lower() and s ~= s:upper())
	end

	--SQL formatting ----------------------------------------------------------

	spp.engine = 'tarantool'
	spp.TO_SQL = 'tarantool_to_sql'

	function cmd:sqltype(fld)
		return fld.tarantool_type
	end

	function cmd:sqlcol_flags(fld)
		return catargs(' ',
			fld.tarantool_collation and 'collate "'..fld.tarantool_collation..'"' or nil,
			fld.not_null and 'not null' or nil,
			fld.auto_increment and 'autoincrement' or nil,
			fld.tarantool_default ~= nil and 'default '..self:sqlval(fld.tarantool_default) or nil
		)
	end

	--schema diff'ing ---------------------------------------------------------

	spp.schema_options = {
		--supports_fks = true,
		supports_checks = true,
		supports_triggers = true,
		supports_procs = true,
		relevant_field_attrs = {
			col=1,
			col_pos=1,
			not_null=1,
			auto_increment=1,
			tarantool_type=1,
			tarantool_collation=1,
			default=1,
		},
	}

	--schema extraction -------------------------------------------------------

	function cmd:dbs()
		return {'default'}
	end

	function cmd:tables(db)
		db = db or self.db
		if db ~= self.db then return {} end
		return (self:exec_with_options({to_array = 1}, [[
			select lower("name") from "_vspace" where "name" <> lower("name")
		]]))
	end

	local function parse_values(s)
		local vals = s:match'%((.-)%)$'
		if not vals then return end
		local t = {}
		vals:gsub("'(.-)'", function(s)
			t[#t+1] = s
		end)
		return t
	end

	function cmd:get_table_defs(opt)

		opt = opt or empty

		local tables = self:assert(self.rawconn:eval[[
			local tables = {}
			for i, sp in ipairs(box.space._vspace:select()) do
				if (sp.engine == 'memtx' or sp.engine == 'vinyl')
					and not sp.flags.view and sp.name:sub(1, 1) ~= '_'
					and sp.name == sp.name:upper() --SQL-defined
				then
					local name = sp.name:lower()
					local fields = {}
					local tbl = {
						name = name,
						engine = sp.engine,
						fields = fields,
					}
					tables[name] = tbl
					local seq = box.space._space_sequence:get(sp.id)
					for i, fm in ipairs(sp.format) do
						local coll = fm.collation and box.space._collation:get(fm.collation)
						local fld = {
							col = fm.name:lower(),
							tarantool_type = fm.type,
							not_null = fm.is_nullable == false or nil,
							col_pos = i,
							auto_increment = seq and seq[2] == i or nil,
							tarantool_collation = coll and coll[2],
						}
						fields[i] = fld
					end
				end
			end
			return tables
		]])

		for _,tbl in pairs(tables) do
			for _,fld in ipairs(tbl.fields) do
				tbl.fields[fld.col] = fld
			end
		end

		--[==[
		for i, db_tbl, constraints in spp.each_group('db_tbl', self:assert(self:rawquery([[
			select
				concat(cs.table_schema, '.', cs.table_name) db_tbl,
				cs.table_name,
				kcu.column_name col,
				cs.constraint_name,
				cs.constraint_type,
				kcu.referenced_table_schema ref_db,
				kcu.referenced_table_name ref_tbl,
				kcu.referenced_column_name ref_col,
				coalesce(rc.update_rule, 'no action') as onupdate,
				coalesce(rc.delete_rule, 'no action') as ondelete
			from
				information_schema.table_constraints cs /* cs type: pk, fk, uk */
				left join information_schema.key_column_usage kcu /* fk ref_tbl & ref_cols */
					 on kcu.table_schema     = cs.table_schema
					and kcu.table_name       = cs.table_name
					and kcu.constraint_name  = cs.constraint_name
				left join information_schema.referential_constraints rc /* fk rules: innodb only */
					 on rc.constraint_schema = kcu.table_schema
					and rc.table_name        = kcu.table_name
					and rc.constraint_name   = kcu.constraint_name
			where
				cs.table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
				and ]]..(catargs(' and ',
						db  and 'cs.table_schema = '..sql_db,
						tbl and 'cs.table_name   = '..sql_tbl) or '1 = 1')..[[
			order by
				cs.table_schema, cs.table_name, cs.constraint_name, kcu.ordinal_position
			]])))
		do
			local tbl = tables[db_tbl]
			for i, cs_name, grp in spp.each_group('constraint_name', constraints) do
				local cs_type = grp[1].constraint_type
				if cs_type == 'PRIMARY KEY' then
					tbl.pk = imap(grp, row_col)
				elseif cs_type == 'FOREIGN KEY' then
					local ref_db  = grp[1].ref_db
					local ref_tbl = (ref_db ~= db and ref_db..'.' or '')..grp[1].ref_tbl
					if #grp == 1 then
						local field = tbl.fields[grp[1].col]
						field.ref_table = ref_tbl
						field.ref_col = grp[1].ref_col
					end
					local cols = imap(grp, row_col)
					cols.desc = imap(cols, return_false) --in case there's no matching index.
					attr(tbl, 'fks')[cs_name] = {
						table     = tbl.name,
						ref_table = ref_tbl,
						cols      = cols,
						ref_cols  = imap(grp, row_ref_col),
						onupdate  = repl(grp[1].onupdate:lower(), 'no action', nil),
						ondelete  = repl(grp[1].ondelete:lower(), 'no action', nil),
					}
				elseif cs_type == 'UNIQUE' then
					attr(tbl, 'uks')[cs_name] = imap(grp, row_col)
				end
			end

		end

		--NOTE: constraints do not create an index if one is already available
		--on the columns that they need, so not every constraint has an entry
		--in the statistics table (which is why we couldn't join `statistics`
		--in and had to get indexes with a separate select).

		local function row_desc(t) return t.collation == 'D' end

		if opt.all or opt.indexes then
			for i, db_tbl, ixs in spp.each_group('db_tbl', self:assert(self:rawquery([[
				select
					concat(s.table_schema, '.', s.table_name) db_tbl,
					s.table_name,
					s.column_name col,
					cs.constraint_name,
					s.index_name,
					s.collation /* D|A */
				from information_schema.statistics s /* columns for pk, uk, fk, ix */
				left join information_schema.table_constraints cs /* cs type: pk, fk, uk */
					 on cs.table_schema     = s.table_schema
					and cs.table_name       = s.table_name
					and cs.constraint_name  = s.index_name
				where
					s.table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
					and ]]..(catargs(' and ',
							db  and 's.table_schema = '..sql_db,
							tbl and 's.table_name   = '..sql_tbl) or '1 = 1')..[[
				order by
					s.table_schema, s.table_name, s.index_name, s.seq_in_index
				]])))
			do
				local tbl = tables[db_tbl]
				local uks = tbl.uks
				local fks = tbl.fks
				for i, ix_name, grp in spp.each_group('index_name', ixs) do
					local desc = imap(grp, row_desc)
					if ix_name == 'PRIMARY' then
						tbl.pk.desc = desc
					else
						local cs_name = grp[1].constraint_name
						if cs_name then --matching uk or fk
							local uk = uks and uks[cs_name]
							local fk = fks and fks[cs_name]
							assert(not uk ~= not fk)
							if uk then uk.desc = desc end
							if fk then fk.cols.desc = desc end
						else --ix
							local ix = imap(grp, row_col)
							ix.desc = desc
							attr(tbl, 'ixs')[ix_name] = ix
						end
					end
				end
			end
		end

		if opt.all or opt.checks then
			for i, db_tbl, checks in spp.each_group('db_tbl', self:assert(self:rawquery([[
				select
					concat(cs.table_schema, '.', cs.table_name) db_tbl,
					cc.constraint_name,
					cc.check_clause
				from information_schema.table_constraints cs
				inner join information_schema.check_constraints cc
					 on cs.table_schema    = cc.constraint_schema
					and cs.constraint_name = cc.constraint_name
				where
					cs.table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
					and ]]..(catargs(' and ',
							db  and 'cs.table_schema = '..sql_db,
							tbl and 'cs.table_name   = '..sql_tbl) or '1 = 1')..[[
				order by
					cs.table_schema, cs.table_name
				]])))
			do
				local tbl = tables[db_tbl]
				for i, row in ipairs(checks) do
					attr(tbl, 'checks')[row.constraint_name] = {
						mysql_body = row.check_clause:gsub('`', ''):gsub('^%(', ''):gsub('%)$', ''),
					}
				end
			end
		end

		if opt.all or opt.triggers then
			for i, db_tbl, triggers in spp.each_group('db_tbl', self:assert(self:rawquery([[
				select
					concat(event_object_schema, '.', event_object_table) db_tbl,
					trigger_name,
					action_order,
					action_timing,      /* before|after */
					event_manipulation, /* insert|update|delete */
					action_statement
				from information_schema.triggers
				where
					event_object_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys')
					and definer = current_user
					and ]]..(catargs(' and ',
							db  and 'event_object_schema = '..sql_db,
							tbl and 'event_object_table  = '..sql_tbl) or '1 = 1')..[[
				order by
					event_object_schema, event_object_table
				]])))
			do
				local tbl = tables[db_tbl]
				for i, row in ipairs(triggers) do
					attr(tbl, 'triggers')[row.trigger_name] = {
						pos        = row.action_order,
						when       = row.action_timing:lower(),
						op         = row.event_manipulation:lower(),
						mysql_body = row.action_statement,
					}
				end
			end
		end

		]==]

		return tables
	end

	local function make_param(t)
		local p = make_field(t)
		p.mode = repl(t.parameter_mode:lower(), 'in', nil)
		p.col  = t.parameter_name --it's weird, but easier bc fields have `col`.
		return p
	end

	function cmd:get_procs(db)
		local procsets = {} --{db->{proc->p}}
		--[==[
		for i, db, procs in spp.each_group('db', self:assert(self:rawquery([[
			select
				r.routine_schema db,
				r.routine_name,
				r.routine_definition,

				p.parameter_mode, /* in|out */
				p.parameter_name,

				/* input for field_type_attrs(): */
				p.data_type,
				p.dtd_identifier column_type,
				p.numeric_precision,
				p.numeric_scale,
				p.ordinal_position,
				p.character_octet_length,
				p.character_set_name,
				p.collation_name,
				p.character_maximum_length

			from information_schema.routines r
			left join information_schema.parameters p
				on p.specific_name = r.routine_name
			where
				r.routine_type = 'PROCEDURE'
				and r.routine_schema <> 'sys'
				]]..(db and ' and r.routine_schema = '..self:sqlval(db) or '')..[[
			order by
				r.routine_schema
			]])))
		do
			local procset = attr(procsets, db)
			for i, proc_name, grp in spp.each_group('routine_name', procs) do
				local p = {
					args       = imap(grp, make_param),
					mysql_body = grp[1].routine_definition,
				}
				procset[proc_name] = p
				for i, param in ipairs(grp) do
					p[i] = self:sqltype(param)
				end
			end
		end
		]==]
		return procsets
	end

	--structured errors -------------------------------------------------------

	--TODO:

	--DDL commands ------------------------------------------------------------

	function cmd:raw_insert_row(tbl, t, col_count)
		return self.rawconn:replace(tbl:upper(), mp.toarray(t, col_count))
	end

end

return {
	init_spp = init_spp,
}
