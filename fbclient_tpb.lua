--TPB (Transaction Parameter Block) structure: encode the options for creating transactions.
--encode(tpb_options_t) -> TPB encoded string.
--pass the encoded TPB to to isc_start_multiple() to start a transaction.
--table reservation options occupy the array part of tpb_options_t, one numerical index
--for each table that you want to reserve. the format for reserving a table is
--{table_reservation_mode_code, table_reservation_lock_code, table_name}.
--example: {'isc_tpb_shared','isc_tpb_lock_read','MYTABLE'}

local pb = require 'fbclient_pb'

local codes = {
	-- access mode: read | write
	isc_tpb_read             =  8, --true: read only access
	isc_tpb_write            =  9, --true: read/write access
	-- isolation level: consistency | concurrency | (read_commited + (rec_version | no_rec_version))
	isc_tpb_consistency      =  1, --true: repeatable reads but locks the tables from updating by other transactions
	isc_tpb_concurrency      =  2, --true: repeatable reads without locking: gets the best out of MVCC
	isc_tpb_read_committed   = 15, --true: see commited changes from other transactions
	isc_tpb_rec_version      = 17, --true: pending updates don't block reads; use along isc_tpb_read_committed
	isc_tpb_no_rec_version   = 18, --true: pending updates do block reads; use along isc_tpb_read_committed
	-- lock resolution: wait | nowait
	isc_tpb_wait             =  6, --true: in case of deadlock, wait for isc_tpb_lock_timeout seconds before breaking
	isc_tpb_nowait           =  7, --true: in case of deadlock, break immediately
	isc_tpb_lock_timeout     = 21, --number: use this timeout instead of server's configured default; fb 2.0+
	-- other options:
	--isc_tpb_verb_time      = 12, --?: intended for support timing of constraints. not used yet
	--isc_tpb_commit_time    = 13, --?: intended for support timing of constraints. not used yet
	isc_tpb_ignore_limbo     = 14, --true: ignore records made by limbo transactions
	isc_tpb_autocommit       = 16, --true: commit after each statement
	isc_tpb_restart_requests = 19, --true: automatically restart requests in a new transaction after failure
	isc_tpb_no_auto_undo     = 20, --true: refrain from keeping the log used to undo changes in the event of a rollback
}

local table_reservation_mode_codes = {
	isc_tpb_shared    = 3,
	isc_tpb_protected = 4,
	isc_tpb_exclusive = 5,
}

local table_reservation_lock_codes = {
	isc_tpb_lock_read  = 10,
	isc_tpb_lock_write = 11,
}

-- parameter: {'isc_tpb_ shared/protected/exclusive', 'isc_tpb_lock_ read/write', <table_name>}
-- note: the reason for creating this special encoder is because this is an array of sequences of options.
local function encode_table_reservation(t)
	local mode_opt = assert(table_reservation_mode_codes[t[1]], 'table reservation mode string expected at index 1')
	local lock_opt = assert(table_reservation_lock_codes[t[2]], 'table reservation lock string expected at index 2')
	local table_name = assert(t[3], 'table name expected at index 3')
	--NOTE: the IB6 Api Guide is wrong about this sequence (see CORE-1416)
	return struct.pack('BBc0B',lock_opt,#table_name,table_name,mode_opt)
end

local encoders = {
	isc_tpb_read            = pb.encode_none,
	isc_tpb_write           = pb.encode_none,
	isc_tpb_consistency     = pb.encode_none,
	isc_tpb_concurrency     = pb.encode_none,
	isc_tpb_read_committed  = pb.encode_none,
	isc_tpb_rec_version     = pb.encode_none,
	isc_tpb_no_rec_version  = pb.encode_none,
	isc_tpb_wait            = pb.encode_none,
	isc_tpb_nowait          = pb.encode_none,
	isc_tpb_lock_timeout    = pb.encode_uint,
	isc_tpb_verb_time       = nil,
	isc_tpb_commit_time     = nil,
	isc_tpb_ignore_limbo    = pb.encode_none,
	isc_tpb_autocommit      = pb.encode_none,
	isc_tpb_restart_requests= pb.encode_none,
	isc_tpb_no_auto_undo    = pb.encode_none,
}

-- in addition to encoding the options in the codes table, we encode the array part of opts, which
-- is used for table reservation.
local function encode(opts)
	-- encode table reservation options, if any
	local res_opts = ''
	if opts then
		for i,v in ipairs(opts) do
			res_opts = res_opts..encode_table_reservation(v)
		end
	end
	-- encode normal options and glue them with table reservation options
	return pb.encode('TPB', '\3', opts, codes, encoders)..res_opts
end

return encode

