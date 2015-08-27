--encode the request buffer and decode the reply buffer for requesting information about an active connection.

local info = require'fbclient_info'
local glue = require'glue'
local INT_SIZE = 4
local MAX_BYTE = 255
local MAX_SHORT = 32767

--used by decode_timestamp()
local datetime = require 'fbclient_datetime'

local info_codes = {
	isc_info_db_id              = 4, --{db_filename,site_name}

	isc_info_reads              = 5,  --number of page reads
	isc_info_writes             = 6,  --number of page writes
	isc_info_fetches            = 7,  --number of reads from the memory buffer cache
	isc_info_marks              = 8,  --number of writes to the memory buffer cache

	isc_info_implementation     = 11, --implementation code name
	isc_info_isc_version        = 12, --interbase server version identification string
	isc_info_base_level         = 13, --database level number, i.e. capability version of the server
	isc_info_page_size          = 14, --number of bytes per page of the attached database
	isc_info_num_buffers        = 15, --number of memory buffers currently allocated
	isc_info_limbo              = 16, --TODO: make some limbo transactions
	isc_info_current_memory     = 17, --amount of server memory (in bytes) currently in use
	isc_info_max_memory         = 18, --maximum amount of memory (in bytes) used at one time since the first process attached to the database

	isc_info_window_turns       = 19, --returns error code on firebird !!
	isc_info_license            = 20, --returns error code on firebird !!

	isc_info_allocation         = 21, --number of database pages allocated
	isc_info_attachment_id      = 22, --attachment id number; att. IDs are in system table MON$ATTACHMENTS.

	--all *_count codes below return {[table_id]=operation_count,...}; table IDs are in the system table RDB$RELATIONS.
	isc_info_read_seq_count     = 23, --number of sequential table scans (row reads) done on each table since the database was last attached
	isc_info_read_idx_count     = 24, --number of reads done via an index since the database was last attached
	isc_info_insert_count       = 25, --number of inserts into the database since the database was last attached
	isc_info_update_count       = 26, --number of database updates since the database was last attached
	isc_info_delete_count       = 27, --number of database deletes since the database was last attached
	isc_info_backout_count      = 28, --number of removals of a version of a record
	isc_info_purge_count        = 29, --number of removals of old versions of fully mature records (records that are committed, so that older ancestor versions are no longer needed)
	isc_info_expunge_count      = 30, --number of removals of a record and all of its ancestors, for records whose deletions have been committed

	isc_info_sweep_interval     = 31, --number of transactions that are committed between sweeps to remove database record versions that are no longer needed
	isc_info_ods_version        = 32, --ODS major version number
	isc_info_ods_minor_version  = 33, --On-disk structure (ODS) minor version number
	isc_info_no_reserve         = 34, --boolean: 20% page space is NOT reserved for holding backup versions of modified records

	--[[ WAL was removed from firebird
	isc_info_logfile = 35,
	isc_info_cur_logfile_name = 36,
	isc_info_cur_log_part_offset = 37,
	isc_info_num_wal_buffers = 38,
	isc_info_wal_buffer_size = 39,
	isc_info_wal_ckpt_length = 40,
	isc_info_wal_cur_ckpt_interval = 41,
	isc_info_wal_prv_ckpt_fname = 42,
	isc_info_wal_prv_ckpt_poffset = 43,
	isc_info_wal_recv_ckpt_fname = 44,
	isc_info_wal_recv_ckpt_poffset = 45,
	isc_info_wal_grpc_wait_usecs = 47,
	isc_info_wal_num_io = 48,
	isc_info_wal_avg_io_size = 49,
	isc_info_wal_num_commits = 50,
	isc_info_wal_avg_grpc_size = 51,
	]]

	isc_info_forced_writes      = 52, --mode in which database writes are performed: true=sync, false=async
	isc_info_user_names         = 53, --array of names of all the users currently attached to the database

	isc_info_page_errors        = 54, --number of page level errors validate found
	isc_info_record_errors      = 55, --number of record level errors validate found
	isc_info_bpage_errors       = 56, --number of blob page errors validate found
	isc_info_dpage_errors       = 57, --number of data page errors validate found
	isc_info_ipage_errors       = 58, --number of index page errors validate found
	isc_info_ppage_errors       = 59, --number of pointer page errors validate found
	isc_info_tpage_errors       = 60, --number of transaction page errors validate found

	isc_info_set_page_buffers   = 61, --set ?! the number of page buffers used in a classic attachment.
	isc_info_db_sql_dialect     = 62, --dialect of currently attached database
	isc_info_db_read_only       = 63, --boolean: whether the database is read-only or not
	isc_info_db_size_in_pages   = 64, --same as isc_info_allocation

	frb_info_att_charset        = 101, --charset of current attachment
	isc_info_db_class           = 102,
	isc_info_firebird_version   = 103, --firebird server version identification string

	isc_info_oldest_transaction = 104, --ID of oldest transaction
	isc_info_oldest_active      = 105, --ID of oldest active transaction
	isc_info_oldest_snapshot    = 106, --ID of oldest snapshot transaction
	isc_info_next_transaction   = 107, --ID of next transaction

	isc_info_db_provider        = 108, --for firebird is 'isc_info_db_code_firebird'
	isc_info_active_transactions= 109, --array of active transaction IDs; fb 1.5+
	isc_info_active_tran_count  = 110, --number of active transactions; fb 2.0+
	isc_info_creation_date      = 111, --time_t struct representing database creation date & time; fb 2.0+
	isc_info_db_file_size       = 112, --?; returns 0

	fb_info_page_contents		= 113, --get raw page contents; takes page_number as parameter; fb 2.5+
}

local info_code_lookup = glue.index(info_codes)

local info_buf_sizes = {
	isc_info_db_id = 1+1+MAX_BYTE+1+MAX_BYTE, --mark,dbfile,hostname
	isc_info_reads = INT_SIZE,
	isc_info_writes = INT_SIZE,
	isc_info_fetches = INT_SIZE,
	isc_info_marks = INT_SIZE,

	isc_info_implementation = 1+1+1+1, --mark,impl_number,class_number,?
	isc_info_isc_version = 255,
	isc_info_base_level = 1+1, --mark,version
	isc_info_page_size = INT_SIZE,
	isc_info_num_buffers = INT_SIZE,
	isc_info_limbo = INT_SIZE,
	isc_info_current_memory = INT_SIZE,
	isc_info_max_memory = INT_SIZE,
	isc_info_window_turns = INT_SIZE,
	isc_info_license = INT_SIZE,

	isc_info_allocation = INT_SIZE,
	isc_info_attachment_id = INT_SIZE,
	isc_info_read_seq_count = MAX_SHORT,
	isc_info_read_idx_count = MAX_SHORT,
	isc_info_insert_count = MAX_SHORT,
	isc_info_update_count = MAX_SHORT,
	isc_info_delete_count = MAX_SHORT,
	isc_info_backout_count = MAX_SHORT,
	isc_info_purge_count = MAX_SHORT,
	isc_info_expunge_count = MAX_SHORT,

	isc_info_sweep_interval = INT_SIZE,
	isc_info_ods_version = INT_SIZE,
	isc_info_ods_minor_version = INT_SIZE,
	isc_info_no_reserve = INT_SIZE,

	--[[ WAL was removed from firebird
	isc_info_logfile = 2048,
	isc_info_cur_logfile_name = 2048,
	isc_info_cur_log_part_offset = INT_SIZE,
	isc_info_num_wal_buffers = INT_SIZE,
	isc_info_wal_buffer_size = INT_SIZE,
	isc_info_wal_ckpt_length = INT_SIZE,
	isc_info_wal_cur_ckpt_interval = INT_SIZE,
	isc_info_wal_prv_ckpt_fname = 2048,
	isc_info_wal_prv_ckpt_poffset = INT_SIZE,
	isc_info_wal_recv_ckpt_fname = 2048,
	isc_info_wal_recv_ckpt_poffset = INT_SIZE,
	isc_info_wal_grpc_wait_usecs = INT_SIZE,
	isc_info_wal_num_io = INT_SIZE,
	isc_info_wal_avg_io_size = INT_SIZE,
	isc_info_wal_num_commits = INT_SIZE,
	isc_info_wal_avg_grpc_size = INT_SIZE,
	]]

	isc_info_forced_writes = INT_SIZE,
	isc_info_user_names = MAX_SHORT,
	isc_info_page_errors = INT_SIZE,
	isc_info_record_errors = INT_SIZE,
	isc_info_bpage_errors = INT_SIZE,
	isc_info_dpage_errors = INT_SIZE,
	isc_info_ipage_errors = INT_SIZE,
	isc_info_ppage_errors = INT_SIZE,
	isc_info_tpage_errors = INT_SIZE,

	isc_info_set_page_buffers = INT_SIZE,
	isc_info_db_sql_dialect = 1,
	isc_info_db_read_only = INT_SIZE,
	isc_info_db_size_in_pages = INT_SIZE,

	frb_info_att_charset = INT_SIZE,
	isc_info_db_class = 1,
	isc_info_firebird_version = 255,
	isc_info_oldest_transaction = INT_SIZE,
	isc_info_oldest_active = INT_SIZE,
	isc_info_oldest_snapshot = INT_SIZE,
	isc_info_next_transaction = INT_SIZE,
	isc_info_db_provider = 1,
	isc_info_active_transactions = MAX_SHORT,
	isc_info_active_tran_count = INT_SIZE,
	isc_info_creation_date = 2*INT_SIZE,
	isc_info_db_file_size = INT_SIZE,
	fb_info_page_contents = MAX_SHORT,
}

local info_db_implementations = {
	isc_info_db_impl_rdb_vms = 1,
	isc_info_db_impl_rdb_eln = 2,
	isc_info_db_impl_rdb_eln_dev = 3,
	isc_info_db_impl_rdb_vms_y = 4,
	isc_info_db_impl_rdb_eln_y = 5,
	isc_info_db_impl_jri = 6,
	isc_info_db_impl_jsv = 7,

	isc_info_db_impl_isc_apl_68K = 25,
	isc_info_db_impl_isc_vax_ultr = 26,
	isc_info_db_impl_isc_vms = 27,
	isc_info_db_impl_isc_sun_68k = 28,
	isc_info_db_impl_isc_os2 = 29,
	isc_info_db_impl_isc_sun4 = 30,

	isc_info_db_impl_isc_hp_ux = 31,
	isc_info_db_impl_isc_sun_386i = 32,
	isc_info_db_impl_isc_vms_orcl = 33,
	isc_info_db_impl_isc_mac_aux = 34,
	isc_info_db_impl_isc_rt_aix = 35,
	isc_info_db_impl_isc_mips_ult = 36,
	isc_info_db_impl_isc_xenix = 37,
	isc_info_db_impl_isc_dg = 38,
	isc_info_db_impl_isc_hp_mpexl = 39,
	isc_info_db_impl_isc_hp_ux68K = 40,

	isc_info_db_impl_isc_sgi = 41,
	isc_info_db_impl_isc_sco_unix = 42,
	isc_info_db_impl_isc_cray = 43,
	isc_info_db_impl_isc_imp = 44,
	isc_info_db_impl_isc_delta = 45,
	isc_info_db_impl_isc_next = 46,
	isc_info_db_impl_isc_dos = 47,
	isc_info_db_impl_m88K = 48,
	isc_info_db_impl_unixware = 49,
	isc_info_db_impl_isc_winnt_x86 = 50,

	isc_info_db_impl_isc_epson = 51,
	isc_info_db_impl_alpha_osf = 52,
	isc_info_db_impl_alpha_vms = 53,
	isc_info_db_impl_netware_386 = 54,
	isc_info_db_impl_win_only = 55,
	isc_info_db_impl_ncr_3000 = 56,
	isc_info_db_impl_winnt_ppc = 57,
	isc_info_db_impl_dg_x86 = 58,
	isc_info_db_impl_sco_ev = 59,
	isc_info_db_impl_i386 = 60,

	isc_info_db_impl_freebsd = 61,
	isc_info_db_impl_netbsd = 62,
	isc_info_db_impl_darwin_ppc = 63,
	isc_info_db_impl_sinixz = 64,

	isc_info_db_impl_linux_sparc = 65,
	isc_info_db_impl_linux_amd64 = 66,

	isc_info_db_impl_freebsd_amd64 = 67,

	isc_info_db_impl_winnt_amd64 = 68,

	isc_info_db_impl_linux_ppc = 69,
	isc_info_db_impl_darwin_x86 = 70,
	isc_info_db_impl_linux_mipsel = 71,
	isc_info_db_impl_linux_mips = 72,
	isc_info_db_impl_darwin_x64 = 73,
	isc_info_db_impl_sun_amd64 = 74,

	isc_info_db_impl_linux_arm = 75,
	isc_info_db_impl_linux_ia64 = 76,

	isc_info_db_impl_darwin_ppc64 = 77,
}

local info_db_classes = {
	isc_info_db_class_access = 1,
	isc_info_db_class_y_valve = 2,
	isc_info_db_class_rem_int = 3,
	isc_info_db_class_rem_srvr = 4,
	isc_info_db_class_pipe_int = 7,
	isc_info_db_class_pipe_srvr = 8,
	isc_info_db_class_sam_int = 9,
	isc_info_db_class_sam_srvr = 10,
	isc_info_db_class_gateway = 11,
	isc_info_db_class_cache = 12,
	isc_info_db_class_classic_access = 13,
	isc_info_db_class_server_access = 14,
}

local info_db_providers = {
	isc_info_db_code_rdb_eln = 1,
	isc_info_db_code_rdb_vms = 2,
	isc_info_db_code_interbase = 3,
	isc_info_db_code_firebird = 4,
}

--returns {table_id,number_of_operations}
local function decode_count(s)
	local t = {}
	for i=1,#s/6 do
		local table_id,op_num = struct.unpack('<HI',s,(i-1)*6+1)
		t[table_id] = op_num
	end
	return t
end

local function decode_version_string(s)
	local mark,ver = struct.unpack('bBc0',s)
	return ver
end

--the sole user of this decoder is isc_info_creation_date;
--it's also the only decoder that requires a fbapi object.
local function decode_timestamp(s,fbapi)
	assert(#s == struct.size('<iI'))
	local dx,tx = struct.unpack('<iI',s) --little endian & no alignment
	local dt_buf = alien.buffer(2*INT_SIZE)
	dt_buf:set(1,dx)
	dt_buf:set(1+INT_SIZE,tx)
	return datetime.decode_timestamp(dt_buf,fbapi)
end

local decoders = {
	isc_info_db_id = function(s)
			local mark,s1,s2,s3 = struct.unpack('bBc0Bc0',s)
			return {db_filename=s1,site_name=s2}
		end,
	isc_info_reads = info.decode_unsigned,
	isc_info_writes = info.decode_unsigned,
	isc_info_fetches = info.decode_unsigned,
	isc_info_marks = info.decode_unsigned,
	isc_info_implementation = function(s)
			return assert(info.decode_enum(info_db_implementations)(s:sub(2)))
		end,
	isc_info_isc_version = decode_version_string,
	isc_info_base_level = function(s)
			local mark,version = struct.unpack('bB',s) --mark,version
			return version
		end,
	isc_info_page_size = info.decode_unsigned,
	isc_info_num_buffers = info.decode_unsigned,
	--isc_info_limbo = ,
	isc_info_current_memory = info.decode_unsigned,
	isc_info_max_memory = info.decode_unsigned,
	isc_info_window_turns = info.decode_unsigned,
	--isc_info_license = ,
	isc_info_allocation = info.decode_unsigned,
	isc_info_attachment_id = info.decode_unsigned,
	isc_info_read_seq_count = decode_count,
	isc_info_read_idx_count = decode_count,
	isc_info_insert_count = decode_count,
	isc_info_update_count = decode_count,
	isc_info_delete_count = decode_count,
	isc_info_backout_count = decode_count,
	isc_info_purge_count = decode_count,
	isc_info_expunge_count = decode_count,
	isc_info_sweep_interval = info.decode_unsigned,
	isc_info_ods_version = info.decode_unsigned,
	isc_info_ods_minor_version = info.decode_unsigned,
	isc_info_no_reserve = info.decode_boolean,

	--[[ WAL was removed from firebird
	isc_info_logfile = info.decode_string,
	isc_info_cur_logfile_name = info.decode_string,
	isc_info_cur_log_part_offset = info.decode_unsigned,
	isc_info_num_wal_buffers = info.decode_unsigned,
	isc_info_wal_buffer_size = info.decode_unsigned,
	isc_info_wal_ckpt_length = info.decode_unsigned,
	isc_info_wal_cur_ckpt_interval = info.decode_unsigned,
	isc_info_wal_prv_ckpt_fname = info.decode_string,
	isc_info_wal_prv_ckpt_poffset = info.decode_unsigned,
	isc_info_wal_recv_ckpt_fname = info.decode_string,
	isc_info_wal_recv_ckpt_poffset = info.decode_unsigned,
	isc_info_wal_grpc_wait_usecs = info.decode_unsigned,
	isc_info_wal_num_io = info.decode_unsigned,
	isc_info_wal_avg_io_size = info.decode_unsigned,
	isc_info_wal_num_commits = info.decode_unsigned,
	isc_info_wal_avg_grpc_size = info.decode_unsigned,
	]]

	isc_info_forced_writes = info.decode_boolean,
	isc_info_user_names = function(s)
			return struct.unpack('Bc0',s)
		end,
	isc_info_page_errors = info.decode_unsigned,
	isc_info_record_errors = info.decode_unsigned,
	isc_info_bpage_errors = info.decode_unsigned,
	isc_info_dpage_errors = info.decode_unsigned,
	isc_info_ipage_errors = info.decode_unsigned,
	isc_info_ppage_errors = info.decode_unsigned,
	isc_info_tpage_errors = info.decode_unsigned,
	isc_info_set_page_buffers = info.decode_unsigned,
	isc_info_db_sql_dialect = info.decode_unsigned,
	isc_info_db_read_only = info.decode_boolean,
	isc_info_db_size_in_pages = info.decode_unsigned,
	frb_info_att_charset = info.decode_unsigned,
	isc_info_db_class = info.decode_enum(info_db_classes),
	isc_info_firebird_version = decode_version_string,
	isc_info_oldest_transaction = info.decode_unsigned,
	isc_info_oldest_active = info.decode_unsigned,
	isc_info_oldest_snapshot = info.decode_unsigned,
	isc_info_next_transaction = info.decode_unsigned,
	isc_info_db_provider = info.decode_enum(info_db_providers),
	isc_info_active_transactions = info.decode_unsigned,
	isc_info_active_tran_count = info.decode_unsigned,
	isc_info_creation_date = decode_timestamp,
	isc_info_db_file_size = info.decode_unsigned,
	fb_info_page_contents = info.decode_string,
}

--info on these options can occur multiple times, so they are to be encapsulated as arrays.
local array_options = {
	isc_info_user_names = true,
	isc_info_active_transactions = true,
}

local encoders = {
	fb_info_page_contents = function(page_num)
		return struct.pack('<HI',4,page_num)
	end
}

local dbinfo = {}

function dbinfo.encode(opts)
	return info.encode('DB_INFO', opts, info_codes, info_buf_sizes, encoders)
end

function dbinfo.decode(info_buf, info_buf_len, fbapi) --yeah, some decoder wants a fbapi, just pass it on and fuggetaboutit
	return info.decode('DB_INFO', info_buf, info_buf_len, info_code_lookup, decoders, array_options, fbapi)
end

return dbinfo
