--encode the request buffer and decode the reply buffer for requesting information about a prepared statement.

local glue = require'glue'
local info = require 'fbclient_info'

local INT_SIZE	   = 4
local SHORT_SIZE	= 2
local MAX_INT		=  2^(8*INT_SIZE-1)-1
local MAX_SHORT	=  2^(8*SHORT_SIZE-1)-1

local info_request_codes = {
	isc_info_sql_select			=  4, --undocumented
	isc_info_sql_bind				=  5, --undocumented
	isc_info_sql_num_variables	=  6, --undocumented
	isc_info_sql_describe_vars	=  7, --undocumented
	isc_info_sql_sqlda_start	= 20, --undocumented
	isc_info_sql_stmt_type		= 21, --statement type(s)
	isc_info_sql_get_plan		= 22, --execution plan
	isc_info_sql_records			= 23, --affected row counts for each operation
	isc_info_sql_batch_fetch	= 24, --undocumented
}

local info_reply_codes = {
	isc_info_sql_select			=  4, --undocumented
	isc_info_sql_bind				=  5, --undocumented
	isc_info_sql_num_variables	=  6, --undocumented
	isc_info_sql_describe_vars	=  7, --undocumented
	isc_info_sql_describe_end	=  8, --undocumented
	isc_info_sql_sqlda_seq		=  9, --undocumented
	isc_info_sql_message_seq	= 10, --undocumented
	isc_info_sql_type				= 11, --undocumented
	isc_info_sql_sub_type		= 12, --undocumented
	isc_info_sql_scale			= 13, --undocumented
	isc_info_sql_length			= 14, --undocumented
	isc_info_sql_null_ind		= 15, --undocumented
	isc_info_sql_field			= 16, --undocumented
	isc_info_sql_relation		= 17, --undocumented
	isc_info_sql_owner			= 18, --undocumented
	isc_info_sql_alias			= 19, --undocumented
	isc_info_sql_sqlda_start	= 20, --undocumented
	isc_info_sql_stmt_type		= 21, --array: one or more of stmt_codes table below
	isc_info_sql_get_plan		= 22, --string: execution plan
	isc_info_sql_records			= 23, --table: affected row counts for each operation
	isc_info_sql_batch_fetch	= 24, --undocumented
	isc_info_sql_relation_alias= 25, --fb 2.0+
}

local info_reply_code_lookup = glue.index(info_reply_codes)

local info_buf_sizes = {
	isc_info_sql_select			= 1,
	isc_info_sql_bind				= 1,
	isc_info_sql_num_variables	= INT_SIZE,
	isc_info_sql_describe_vars	= 1,
	isc_info_sql_sqlda_start	= 1,
	isc_info_sql_stmt_type		= 4, -- the manual says max. 2 entries will be filled but I get 4
	isc_info_sql_get_plan		= MAX_SHORT,
	isc_info_sql_records			= 4*(1+SHORT_SIZE+INT_SIZE), -- all 4 isc_info_req_* are expected
	isc_info_sql_batch_fetch	= 1,
	isc_info_sql_relation_alias= 32+1,
}

local stmt_codes = {
	isc_info_sql_stmt_select			= 1,
	isc_info_sql_stmt_insert			= 2,
	isc_info_sql_stmt_update			= 3,
	isc_info_sql_stmt_delete			= 4,
	isc_info_sql_stmt_ddl				= 5,
	isc_info_sql_stmt_get_segment		= 6,
	isc_info_sql_stmt_put_segment		= 7,
	isc_info_sql_stmt_exec_procedure	= 8,
	isc_info_sql_stmt_start_trans		= 9,
	isc_info_sql_stmt_commit			= 10,
	isc_info_sql_stmt_rollback			= 11,
	isc_info_sql_stmt_select_for_upd	= 12,
	isc_info_sql_stmt_set_generator	= 13,
	isc_info_sql_stmt_savepoint		= 14,
}

local stmt_code_lookup = glue.index(stmt_codes)

local records_cluster_codes = {
	isc_info_req_select_count = 13,
	isc_info_req_insert_count = 14,
	isc_info_req_update_count = 15,
	isc_info_req_delete_count = 16,
}

local records_cluster_code_lookup = glue.index(records_cluster_codes)

local decoders = {
	isc_info_sql_select			= info.decode_boolean,
	isc_info_sql_bind				= info.decode_boolean,
	isc_info_sql_num_variables	= info.decode_unsigned,
	isc_info_sql_describe_vars	= info.decode_boolean,
	isc_info_sql_describe_end	= info.decode_boolean,
	isc_info_sql_sqlda_seq		= info.decode_unsigned,
	isc_info_sql_message_seq	= info.decode_unsigned,
	isc_info_sql_type				= info.decode_unsigned,
	isc_info_sql_sub_type		= info.decode_unsigned,
	isc_info_sql_scale			= info.decode_unsigned,
	isc_info_sql_length			= info.decode_unsigned,
	isc_info_sql_null_ind		= info.decode_unsigned,
	isc_info_sql_field			= info.decode_string,
	isc_info_sql_relation		= info.decode_string,
	isc_info_sql_owner			= info.decode_string,
	isc_info_sql_alias			= info.decode_string,
	isc_info_sql_sqlda_start	= info.decode_boolean,
	isc_info_sql_stmt_type = function(s) -- custom decoder made because you can get one or two stmt. types
		local ret = {}
		for i=1,#s do
			local code = struct.unpack('B',s,i) -- when given a string, arg#2 means ofs
			if code == 0 then break end
			ret[#ret+1] = glue.assert(stmt_code_lookup[code], 'unknown stmt_code %d returned by server', code)
		end
		return ret
	end,
	isc_info_sql_get_plan = info.decode_string,
	isc_info_sql_records = function(s)
		local ret = {}
		for i=1,4 do
			local c,sz,n = struct.unpack('<BHI',s,struct.size('<BHI')*(i-1)+1)
			local cn = glue.assert(records_cluster_code_lookup[c], 'unknown records cluster code %d', c)
			assert(sz==INT_SIZE)
			ret[cn] = n
		end
		return ret
	end,
	isc_info_sql_batch_fetch = info.decode_boolean,
	isc_info_sql_relation_alias = info.decode_string,
}

local sqlinfo = {}

function sqlinfo.encode(opts)
	return info.encode('SQL_INFO', opts, info_request_codes, info_buf_sizes)
end

function sqlinfo.decode(info_buf, info_buf_len)
	return info.decode('SQL_INFO', info_buf, info_buf_len, info_reply_code_lookup, decoders)
end

return sqlinfo
