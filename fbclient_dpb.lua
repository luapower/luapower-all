--DPB (Database Parameter Block) structure: encode the options for connecting to a database
--encode(dpb_options_t) -> DPB encoded string.
--pass the encoded DPB to isc_attach_database() to connect to a database.
--NOTE: options that take no arguments themselves must be encoded with encode_zero() instead of encode_none().

local pb = require 'fbclient_pb'

local codes = {
	--isc_dpb_cdd_pathname           =  1, --ancient DEC common data dictionary
	--isc_dpb_allocation             =  2, --support preallocated files. unused. carried over from DEC
	--isc_dpb_journal                =  3, --WAL is gone
	isc_dpb_page_size                =  4, --number: page size to specify on db_create()
	isc_dpb_num_buffers              =  5, --number: how many cache buffers to use for this session
	--isc_dpb_buffer_length          =  6, --variable sized buffers. unused. carried over from DEC
	--isc_dpb_debug                  =  7, --debug attachment. unused. carried over from DEC
	isc_dpb_garbage_collect          =  8, --true: sweep the database upon attachment
	isc_dpb_verify                   =  9, --enum: perform consistency checking; see isc_dpb_verify_enum below
	isc_dpb_sweep                    = 10, --true: sweep the database upon attachment
	--isc_dpb_enable_journal         = 11, --WAL is gone
	--isc_dpb_disable_journal        = 12, --WAL is gone
	--isc_dpb_dbkey_scope            = 13, --boolean: dbkey context scope: 0=transaction, 1=session
	--isc_dpb_number_of_users        = 14, --restrict access. unused. carried over from DEC
	--isc_dpb_trace                  = 15, --produce call trace. unused. carried over from DEC
	isc_dpb_no_garbage_collect       = 16, --true: disable sweeping
	isc_dpb_damaged                  = 17, --boolean: mark database as damaged or undamaged
	--isc_dpb_license                = 18, --string: authorisation key for a software license
	isc_dpb_sys_user_name            = 19, --string: sysdba's username
	--isc_dpb_encrypt_key            = 20, --string: database encryption key. not implemented in Firebird
	isc_dpb_activate_shadow          = 21, --true: activate shadow
	isc_dpb_sweep_interval           = 22, --number: sweep interval in seconds
	isc_dpb_delete_shadow            = 23, --true: delete shadow files
	isc_dpb_force_write              = 24, --boolean: forced writes (true=synchronous writing)
	--isc_dpb_begin_log              = 25, --WAL is gone
	--isc_dpb_quit_log               = 26, --WAL is gone
	isc_dpb_no_reserve               = 27, --boolean: disable page reservation for old records
	isc_dpb_user_name                = 28, --string: username
	isc_dpb_password                 = 29, --string: password
	isc_dpb_password_enc             = 30, --string: encrypted password
	isc_dpb_sys_user_name_enc        = 31, --string: sysdba's encrypted username
	--isc_dpb_interp                 = 32, --unused. abandoned Borland feature
	--isc_dpb_online_dump            = 33, --unused. abandoned Borland feature
	--isc_dpb_old_file_size          = 34, --unused. abandoned Borland feature
	--isc_dpb_old_num_files          = 35, --unused. abandoned Borland feature
	--isc_dpb_old_file               = 36, --unused. abandoned Borland feature
	--isc_dpb_old_start_page         = 37, --unused. abandoned Borland feature
	--isc_dpb_old_start_seqno        = 38, --unused. abandoned Borland feature
	--isc_dpb_old_start_file         = 39, --unused. abandoned Borland feature
	--isc_dpb_drop_walfile           = 40, --WAL is gone
	--isc_dpb_old_dump_id            = 41, --unused. abandoned Borland feature
	--isc_dpb_wal_backup_dir         = 42, --WAL is gone
	--isc_dpb_wal_chkptlen           = 43, --WAL is gone
	--isc_dpb_wal_numbufs            = 44, --WAL is gone
	--isc_dpb_wal_bufsize            = 45, --WAL is gone
	--isc_dpb_wal_grp_cmt_wait       = 46, --WAL is gone
	--isc_dpb_lc_messages            = 47, --string: language-specific message file. not implemented in Firebird
	isc_dpb_lc_ctype                 = 48, --string: connection charset
	--isc_dpb_cache_manager          = 49, --unused. abandoned Borland feature
	isc_dpb_shutdown                 = 50, --bitmask: see isc_dpb_shutdown_bitmask below; fb 2.0+
	isc_dpb_online                   = 51, --true: bring database online (??)
	--isc_dpb_shutdown_delay         = 52, --unused. abandoned Borland feature
	isc_dpb_reserved                 = 53, --true: sets the database to single user if su
	isc_dpb_overwrite                = 54, --true: on create, allow overwriting existing file
	isc_dpb_sec_attach               = 55, --true: special attach for security database (obsolete)
	--isc_dpb_disable_wal            = 56, --WAL is gone
	isc_dpb_connect_timeout          = 57, --number: terminate connection if no traffic for n seconds
	isc_dpb_dummy_packet_interval    = 58, --number: interval between keep-alive packets
	isc_dpb_gbak_attach              = 59, --true: special rights for gbak
	isc_dpb_sql_role_name            = 60, --string: role name
	isc_dpb_set_page_buffers         = 61, --number: set buffer count in database header
	isc_dpb_working_directory        = 62, --string: set working directory for this session (for classic I suppose)
	isc_dpb_sql_dialect              = 63, --number: dialect to specify on db_create()
	isc_dpb_set_db_readonly          = 64, --boolean: set db as read only in database header
	isc_dpb_set_db_sql_dialect       = 65, --number: set sql dialect in database header
	isc_dpb_gfix_attach              = 66, --true: special rights for gfix
	isc_dpb_gstat_attach             = 67, --true: special rights for gfix
	isc_dpb_set_db_charset           = 68, --string: set default db charset in database header
	isc_dpb_gsec_attach              = 69, --true: special rights for gfix
	isc_dpb_address_path             = 70, --string: protocol dependent network address of the remote client
                                          --including intermediate hosts in the case of redirection
	isc_dpb_process_id               = 71, --number: pid
	isc_dpb_no_db_triggers           = 72, --true: disable database (eg. ON CONNECT) triggers for this session
	isc_dpb_trusted_auth             = 73, --true: force trusted authentication; fb 2.1+
	isc_dpb_process_name             = 74, --string: process name
	isc_dpb_trusted_role             = 75, --string: name of the trusted role for this session
	isc_dpb_org_filename             = 76, --string: database name passed by the client (possibly an alias)
	isc_dpb_utf8_filename            = 77, --true: inform Firebird that dbname is in UTF8 as opposed to OS charset
	isc_dpb_ext_call_depth           = 78, --number: set level of nested external database connections
}

-- firebird 2.0+
local isc_dpb_shutdown_bitmask = {
	isc_dpb_shut_cache               = 0x1,
	isc_dpb_shut_attachment          = 0x2,
	isc_dpb_shut_transaction         = 0x4,
	isc_dpb_shut_force               = 0x8,

	isc_dpb_shut_default             = 0x0,
	isc_dpb_shut_normal              = 0x10,
	isc_dpb_shut_multi               = 0x20,
	isc_dpb_shut_single              = 0x30,
	isc_dpb_shut_full                = 0x40,
}

local isc_dpb_verify_enum = {
	isc_dpb_pages                    = 1,
	isc_dpb_records                  = 2,
	isc_dpb_indices                  = 4,
	isc_dpb_transactions             = 8,
	isc_dpb_no_update                = 16,
	isc_dpb_repair                   = 32,
	isc_dpb_ignore                   = 64,
}

local encoders = {
	isc_dpb_page_size                = pb.encode_uint,
	isc_dpb_num_buffers              = pb.encode_uint,
	isc_dpb_garbage_collect          = pb.encode_zero,
	isc_dpb_verify                   = pb.encode_enum(isc_dpb_verify_enum),
	isc_dpb_sweep                    = pb.encode_zero,
	isc_dpb_no_garbage_collect       = pb.encode_bool,
	isc_dpb_damaged                  = pb.encode_bool,
	isc_dpb_sys_user_name            = pb.encode_string,
	isc_dpb_activate_shadow          = pb.encode_zero,
	isc_dpb_sweep_interval           = pb.encode_uint,
	isc_dpb_delete_shadow            = pb.encode_zero,
	isc_dpb_force_write              = pb.encode_bool,
	isc_dpb_no_reserve               = pb.encode_bool,
	isc_dpb_user_name                = pb.encode_string,
	isc_dpb_password                 = pb.encode_string,
	isc_dpb_password_enc             = pb.encode_string,
	isc_dpb_sys_user_name_enc        = pb.encode_string,
	isc_dpb_lc_ctype                 = pb.encode_string,
	isc_dpb_shutdown                 = pb.encode_bitmask(isc_dpb_shutdown_bitmask),
	isc_dpb_online                   = pb.encode_zero,
	isc_dpb_reserved                 = pb.encode_zero,
	isc_dpb_overwrite                = pb.encode_zero,
	isc_dpb_sec_attach               = pb.encode_zero,
	isc_dpb_connect_timeout          = pb.encode_uint,
	isc_dpb_dummy_packet_interval    = pb.encode_uint,
	isc_dpb_gbak_attach              = pb.encode_zero,
	isc_dpb_sql_role_name            = pb.encode_string,
	isc_dpb_set_page_buffers         = pb.encode_uint,
	isc_dpb_working_directory        = pb.encode_string,
	isc_dpb_sql_dialect              = pb.encode_byte,
	isc_dpb_set_db_readonly          = pb.encode_bool,
	isc_dpb_set_db_sql_dialect       = pb.encode_byte,
	isc_dpb_gfix_attach              = pb.encode_zero,
	isc_dpb_gstat_attach             = pb.encode_zero,
	isc_dpb_set_db_charset           = pb.encode_string,
	isc_dpb_gsec_attach              = pb.encode_zero,
	isc_dpb_address_path             = pb.encode_string,
	isc_dpb_process_id               = pb.encode_uint,
	isc_dpb_no_db_triggers           = pb.encode_zero,
	isc_dpb_trusted_auth             = pb.encode_zero,
	isc_dpb_process_name             = pb.encode_string,
	isc_dpb_trusted_role			      = pb.encode_string,
	isc_dpb_org_filename			      = pb.encode_string,
	isc_dpb_utf8_filename			   = pb.encode_string,
	isc_dpb_ext_call_depth			   = pb.encode_uint,
}

--[[
/**************************************************/
/* clumplet tags used inside isc_dpb_address_path */
/*			 and isc_spb_address_path */
/**************************************************/

/* Format of this clumplet is the following:

 <address-path-clumplet> ::=
	isc_dpb_address_path <byte-clumplet-length> <address-stack>

 <address-stack> ::=
	<address-descriptor> |
	<address-stack> <address-descriptor>

 <address-descriptor> ::=
	isc_dpb_address <byte-clumplet-length> <address-elements>

 <address-elements> ::=
	<address-element> |
	<address-elements> <address-element>

 <address-element> ::=
	isc_dpb_addr_protocol <byte-clumplet-length> <protocol-string> |
	isc_dpb_addr_endpoint <byte-clumplet-length> <remote-endpoint-string>

 <protocol-string> ::=
	"TCPv4" |
	"TCPv6" |
	"XNET" |
	"WNET" |
	....

 <remote-endpoint-string> ::=
	<IPv4-address> | // such as "172.20.1.1"
	<IPv6-address> | // such as "2001:0:13FF:09FF::1"
	<xnet-process-id> | // such as "17864"
	...
*/

	isc_dpb_address 1

	isc_dpb_addr_protocol 1
	isc_dpb_addr_endpoint 2
]]

local function encode(opts)
	return pb.encode('DPB', '\1', opts, codes, encoders)
end

return encode
