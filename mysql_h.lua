
--result of `cpp mysql.h` with lots of cleanup and defines from other headers.
--Written by Cosmin Apreutesei. MySQL Connector/C 6.1.

--NOTE: MySQL Connector/C is GPL software. Is this "derived work" then?

local ffi = require'ffi'

ffi.cdef[[

typedef char my_bool;
typedef unsigned long long my_ulonglong;

enum {
	MYSQL_PORT = 3306,
	MYSQL_ERRMSG_SIZE = 512,

	// status return codes
	MYSQL_NO_DATA = 100,
	MYSQL_DATA_TRUNCATED = 101
};

// ----------------------------------------------------------- error constants

// NOTE: added MYSQL_ prefix to these.
enum mysql_error_code {
	MYSQL_CR_UNKNOWN_ERROR = 2000,
	MYSQL_CR_SOCKET_CREATE_ERROR = 2001,
	MYSQL_CR_CONNECTION_ERROR = 2002,
	MYSQL_CR_CONN_HOST_ERROR = 2003,
	MYSQL_CR_IPSOCK_ERROR = 2004,
	MYSQL_CR_UNKNOWN_HOST = 2005,
	MYSQL_CR_SERVER_GONE_ERROR = 2006,
	MYSQL_CR_VERSION_ERROR = 2007,
	MYSQL_CR_OUT_OF_MEMORY = 2008,
	MYSQL_CR_WRONG_HOST_INFO = 2009,
	MYSQL_CR_LOCALHOST_CONNECTION = 2010,
	MYSQL_CR_TCP_CONNECTION = 2011,
	MYSQL_CR_SERVER_HANDSHAKE_ERR = 2012,
	MYSQL_CR_SERVER_LOST = 2013,
	MYSQL_CR_COMMANDS_OUT_OF_SYNC = 2014,
	MYSQL_CR_NAMEDPIPE_CONNECTION = 2015,
	MYSQL_CR_NAMEDPIPEWAIT_ERROR = 2016,
	MYSQL_CR_NAMEDPIPEOPEN_ERROR = 2017,
	MYSQL_CR_NAMEDPIPESETSTATE_ERROR = 2018,
	MYSQL_CR_CANT_READ_CHARSET = 2019,
	MYSQL_CR_NET_PACKET_TOO_LARGE = 2020,
	MYSQL_CR_EMBEDDED_CONNECTION = 2021,
	MYSQL_CR_PROBE_SLAVE_STATUS = 2022,
	MYSQL_CR_PROBE_SLAVE_HOSTS = 2023,
	MYSQL_CR_PROBE_SLAVE_CONNECT = 2024,
	MYSQL_CR_PROBE_MASTER_CONNECT = 2025,
	MYSQL_CR_SSL_CONNECTION_ERROR = 2026,
	MYSQL_CR_MALFORMED_PACKET = 2027,
	MYSQL_CR_WRONG_LICENSE = 2028,

	/* new 4.1 error codes */
	MYSQL_CR_NULL_POINTER = 2029,
	MYSQL_CR_NO_PREPARE_STMT = 2030,
	MYSQL_CR_PARAMS_NOT_BOUND = 2031,
	MYSQL_CR_DATA_TRUNCATED = 2032,
	MYSQL_CR_NO_PARAMETERS_EXISTS = 2033,
	MYSQL_CR_INVALID_PARAMETER_NO = 2034,
	MYSQL_CR_INVALID_BUFFER_USE = 2035,
	MYSQL_CR_UNSUPPORTED_PARAM_TYPE = 2036,

	MYSQL_CR_SHARED_MEMORY_CONNECTION = 2037,
	MYSQL_CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR = 2038,
	MYSQL_CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR = 2039,
	MYSQL_CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR = 2040,
	MYSQL_CR_SHARED_MEMORY_CONNECT_MAP_ERROR = 2041,
	MYSQL_CR_SHARED_MEMORY_FILE_MAP_ERROR = 2042,
	MYSQL_CR_SHARED_MEMORY_MAP_ERROR = 2043,
	MYSQL_CR_SHARED_MEMORY_EVENT_ERROR = 2044,
	MYSQL_CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR = 2045,
	MYSQL_CR_SHARED_MEMORY_CONNECT_SET_ERROR = 2046,
	MYSQL_CR_CONN_UNKNOW_PROTOCOL = 2047,
	MYSQL_CR_INVALID_CONN_HANDLE = 2048,
	MYSQL_CR_SECURE_AUTH = 2049,
	MYSQL_CR_FETCH_CANCELED = 2050,
	MYSQL_CR_NO_DATA = 2051,
	MYSQL_CR_NO_STMT_METADATA = 2052,
	MYSQL_CR_NO_RESULT_SET = 2053,
	MYSQL_CR_NOT_IMPLEMENTED = 2054,
	MYSQL_CR_SERVER_LOST_EXTENDED = 2055,
	MYSQL_CR_STMT_CLOSED = 2056,
	MYSQL_CR_NEW_STMT_METADATA = 2057,
	MYSQL_CR_ALREADY_CONNECTED = 2058,
	MYSQL_CR_AUTH_PLUGIN_CANNOT_LOAD = 2059,
	MYSQL_CR_DUPLICATE_CONNECTION_ATTR = 2060,
	MYSQL_CR_AUTH_PLUGIN_ERR = 2061
};

// ------------------------------------------------------------ client library

unsigned int  mysql_thread_safe(void);   // is the client library thread safe?
const char   *mysql_get_client_info(void);
unsigned long mysql_get_client_version(void);

// --------------------------------------------------------------- connections

typedef struct MYSQL_ MYSQL;

MYSQL * mysql_init(MYSQL *mysql);

enum mysql_protocol_type
{
	MYSQL_PROTOCOL_DEFAULT, MYSQL_PROTOCOL_TCP, MYSQL_PROTOCOL_SOCKET,
	MYSQL_PROTOCOL_PIPE, MYSQL_PROTOCOL_MEMORY
};
enum mysql_option
{
	MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS, MYSQL_OPT_NAMED_PIPE,
	MYSQL_INIT_COMMAND, MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP,
	MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME, MYSQL_OPT_LOCAL_INFILE,
	MYSQL_OPT_PROTOCOL, MYSQL_SHARED_MEMORY_BASE_NAME, MYSQL_OPT_READ_TIMEOUT,
	MYSQL_OPT_WRITE_TIMEOUT, MYSQL_OPT_USE_RESULT,
	MYSQL_OPT_USE_REMOTE_CONNECTION, MYSQL_OPT_USE_EMBEDDED_CONNECTION,
	MYSQL_OPT_GUESS_CONNECTION, MYSQL_SET_CLIENT_IP, MYSQL_SECURE_AUTH,
	MYSQL_REPORT_DATA_TRUNCATION, MYSQL_OPT_RECONNECT,
	MYSQL_OPT_SSL_VERIFY_SERVER_CERT, MYSQL_PLUGIN_DIR, MYSQL_DEFAULT_AUTH,
	MYSQL_OPT_BIND,
	MYSQL_OPT_SSL_KEY, MYSQL_OPT_SSL_CERT,
	MYSQL_OPT_SSL_CA, MYSQL_OPT_SSL_CAPATH, MYSQL_OPT_SSL_CIPHER,
	MYSQL_OPT_SSL_CRL, MYSQL_OPT_SSL_CRLPATH,
	MYSQL_OPT_CONNECT_ATTR_RESET, MYSQL_OPT_CONNECT_ATTR_ADD,
	MYSQL_OPT_CONNECT_ATTR_DELETE,
	MYSQL_SERVER_PUBLIC_KEY,
	MYSQL_ENABLE_CLEARTEXT_PLUGIN,
	MYSQL_OPT_CAN_HANDLE_EXPIRED_PASSWORDS
};
int mysql_options(MYSQL *mysql, enum mysql_option option, const void *arg);
int mysql_options4(MYSQL *mysql, enum mysql_option option, const void *arg1, const void *arg2);

// NOTE: added MYSQL_ prefix to these. Also, these are bit flags not exclusive enum values.
enum {
	MYSQL_CLIENT_LONG_PASSWORD = 1,               /* new more secure passwords */
	MYSQL_CLIENT_FOUND_ROWS = 2,                  /* Found instead of affected rows */
	MYSQL_CLIENT_LONG_FLAG = 4,                   /* Get all column flags */
	MYSQL_CLIENT_CONNECT_WITH_DB = 8,             /* One can specify db on connect */
	MYSQL_CLIENT_NO_SCHEMA = 16,                  /* Don't allow database.table.column */
	MYSQL_CLIENT_COMPRESS = 32,                   /* Can use compression protocol */
	MYSQL_CLIENT_ODBC = 64,                       /* ODBC client */
	MYSQL_CLIENT_LOCAL_FILES = 128,               /* Can use LOAD DATA LOCAL */
	MYSQL_CLIENT_IGNORE_SPACE = 256,              /* Ignore spaces before '(' */
	MYSQL_CLIENT_PROTOCOL_41 = 512,               /* New 4.1 protocol */
	MYSQL_CLIENT_INTERACTIVE = 1024,              /* This is an interactive client */
	MYSQL_CLIENT_SSL = 2048,                      /* Switch to SSL after handshake */
	MYSQL_CLIENT_IGNORE_SIGPIPE = 4096,           /* IGNORE sigpipes */
	MYSQL_CLIENT_TRANSACTIONS = 8192,             /* Client knows about transactions */
	MYSQL_CLIENT_RESERVED = 16384,                /* Old flag for 4.1 protocol  */
	MYSQL_CLIENT_SECURE_CONNECTION = (1U << 15),  /* New 4.1 authentication */
	MYSQL_CLIENT_MULTI_STATEMENTS = (1U << 16),   /* Enable/disable multi-stmt support */
	MYSQL_CLIENT_MULTI_RESULTS = (1U << 17),      /* Enable/disable multi-results */
	MYSQL_CLIENT_PS_MULTI_RESULTS = (1U << 18),   /* Multi-results in PS-protocol */
	MYSQL_CLIENT_PLUGIN_AUTH = (1U << 19),        /* Client supports plugin authentication */
	MYSQL_CLIENT_CONNECT_ATTRS = (1U << 20),      /* Client supports connection attributes */

	/* Enable authentication response packet to be larger than 255 bytes. */
	MYSQL_CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA = (1U << 21),

	/* Don't close the connection for a connection with expired password. */
	MYSQL_CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS = (1U << 22),

	MYSQL_CLIENT_SSL_VERIFY_SERVER_CERT = (1U << 30),
	MYSQL_CLIENT_REMEMBER_OPTIONS = (1U << 31)
};
MYSQL * mysql_real_connect(MYSQL *mysql, const char *host,
        const char *user,
        const char *passwd,
        const char *db,
        unsigned int port,
        const char *unix_socket,
        unsigned long clientflag);

void mysql_close(MYSQL *sock);

int mysql_set_character_set(MYSQL *mysql, const char *csname);

int mysql_select_db(MYSQL *mysql, const char *db);

my_bool mysql_change_user(MYSQL *mysql, const char *user, const char *passwd,
	const char *db);

my_bool mysql_ssl_set(MYSQL *mysql, const char *key,
          const char *cert, const char *ca,
          const char *capath, const char *cipher);

enum enum_mysql_set_option
{
	MYSQL_OPTION_MULTI_STATEMENTS_ON,
	MYSQL_OPTION_MULTI_STATEMENTS_OFF
};
int mysql_set_server_option(MYSQL *mysql, enum enum_mysql_set_option option);

// ----------------------------------------------------------- connection info

const char * mysql_character_set_name(MYSQL *mysql);

typedef struct character_set
{
	unsigned int number;
	unsigned int state;
	const char *csname;
	const char *name;
	const char *comment;
	const char *dir;
	unsigned int mbminlen;
	unsigned int mbmaxlen;
} MY_CHARSET_INFO;
void mysql_get_character_set_info(MYSQL *mysql, MY_CHARSET_INFO *charset);

int mysql_ping(MYSQL *mysql);
unsigned long mysql_thread_id(MYSQL *mysql);
const char * mysql_stat(MYSQL *mysql);
const char * mysql_get_server_info(MYSQL *mysql);
const char * mysql_get_host_info(MYSQL *mysql);
unsigned long mysql_get_server_version(MYSQL *mysql);
unsigned int mysql_get_proto_info(MYSQL *mysql);
const char * mysql_get_ssl_cipher(MYSQL *mysql);

// -------------------------------------------------------------- transactions

my_bool mysql_commit(MYSQL * mysql);
my_bool mysql_rollback(MYSQL * mysql);
my_bool mysql_autocommit(MYSQL * mysql, my_bool auto_mode);

// ------------------------------------------------------------------- queries

unsigned long mysql_real_escape_string(MYSQL *mysql, char *to,
	const char *from, unsigned long length);
int mysql_real_query(MYSQL *mysql, const char *q, unsigned long length);

// ---------------------------------------------------------------- query info

unsigned int mysql_field_count(MYSQL *mysql);
my_ulonglong mysql_affected_rows(MYSQL *mysql);
my_ulonglong mysql_insert_id(MYSQL *mysql);
unsigned int mysql_errno(MYSQL *mysql);
const char * mysql_error(MYSQL *mysql);
const char * mysql_sqlstate(MYSQL *mysql);
unsigned int mysql_warning_count(MYSQL *mysql);
const char * mysql_info(MYSQL *mysql);

// ------------------------------------------------------------- query results

int mysql_next_result(MYSQL *mysql);
my_bool mysql_more_results(MYSQL *mysql);

// NOTE: normally we would've made this an opaque handle, but we need to expose
// the connection handle from it so we can report errors for unbuffered reads.
typedef struct st_mysql_res {
	my_ulonglong __row_count;
	void *__fields;
	void *__data;
	void *__data_cursor;
	void *__lengths;
	MYSQL *conn;  /* for unbuffered reads */
} MYSQL_RES;

MYSQL_RES *mysql_store_result(MYSQL *mysql);
MYSQL_RES *mysql_use_result(MYSQL *mysql);
void mysql_free_result(MYSQL_RES *result);

my_ulonglong mysql_num_rows(MYSQL_RES *res);
unsigned int mysql_num_fields(MYSQL_RES *res);
my_bool      mysql_eof(MYSQL_RES *res);

unsigned long * mysql_fetch_lengths(MYSQL_RES *result);
typedef char **MYSQL_ROW;
MYSQL_ROW mysql_fetch_row(MYSQL_RES *result);

void mysql_data_seek(MYSQL_RES *result, my_ulonglong offset);

typedef struct MYSQL_ROWS_ MYSQL_ROWS;
typedef MYSQL_ROWS *MYSQL_ROW_OFFSET;
MYSQL_ROW_OFFSET mysql_row_tell(MYSQL_RES *res);
MYSQL_ROW_OFFSET mysql_row_seek(MYSQL_RES *result, MYSQL_ROW_OFFSET offset);

// ---------------------------------------------------------- query field info

enum enum_field_types {
	MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
   MYSQL_TYPE_SHORT, MYSQL_TYPE_LONG,
   MYSQL_TYPE_FLOAT, MYSQL_TYPE_DOUBLE,
   MYSQL_TYPE_NULL, MYSQL_TYPE_TIMESTAMP,
   MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
   MYSQL_TYPE_DATE, MYSQL_TYPE_TIME,
   MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
   MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
   MYSQL_TYPE_BIT,
   MYSQL_TYPE_TIMESTAMP2,
   MYSQL_TYPE_DATETIME2,
   MYSQL_TYPE_TIME2,
   MYSQL_TYPE_NEWDECIMAL=246,
   MYSQL_TYPE_ENUM=247,
   MYSQL_TYPE_SET=248,
   MYSQL_TYPE_TINY_BLOB=249,
   MYSQL_TYPE_MEDIUM_BLOB=250,
   MYSQL_TYPE_LONG_BLOB=251,
   MYSQL_TYPE_BLOB=252,
   MYSQL_TYPE_VAR_STRING=253,
   MYSQL_TYPE_STRING=254,
   MYSQL_TYPE_GEOMETRY=255
};

// NOTE: added MYSQL_ prefix to these. Also, these are bit flags, not exclusive enum values.
enum {
	MYSQL_NOT_NULL_FLAG = 1,     /* Field can't be NULL */
	MYSQL_PRI_KEY_FLAG = 2,      /* Field is part of a primary key */
	MYSQL_UNIQUE_KEY_FLAG = 4,   /* Field is part of a unique key */
	MYSQL_MULTIPLE_KEY_FLAG = 8, /* Field is part of a key */
	MYSQL_BLOB_FLAG = 16,        /* Field is a blob */
	MYSQL_UNSIGNED_FLAG = 32,    /* Field is unsigned */
	MYSQL_ZEROFILL_FLAG = 64,    /* Field is zerofill */
	MYSQL_BINARY_FLAG = 128,     /* Field is binary   */

	/* The following are only sent to new clients */
	MYSQL_ENUM_FLAG = 256,              /* field is an enum */
	MYSQL_AUTO_INCREMENT_FLAG = 512,    /* field is a autoincrement field */
	MYSQL_TIMESTAMP_FLAG = 1024,        /* Field is a timestamp */
	MYSQL_SET_FLAG = 2048,              /* field is a set */
	MYSQL_NO_DEFAULT_VALUE_FLAG = 4096, /* Field doesn't have default value */
	MYSQL_ON_UPDATE_NOW_FLAG = 8192,    /* Field is set to NOW on UPDATE */
	MYSQL_NUM_FLAG = 32768,             /* Field is num (for clients) */
	MYSQL_PART_KEY_FLAG = 16384,        /* Intern; Part of some key */
	MYSQL_GROUP_FLAG = 32768,           /* Intern: Group field */
	MYSQL_UNIQUE_FLAG = 65536,          /* Intern: Used by sql_yacc */
	MYSQL_BINCMP_FLAG = 131072,         /* Intern: Used by sql_yacc */
	MYSQL_GET_FIXED_FIELDS_FLAG = (1 << 18),  /* Used to get fields in item tree */
	MYSQL_FIELD_IN_PART_FUNC_FLAG = (1 << 19) /* Field part of partition func */
};

typedef struct st_mysql_field {
	char *name;
	char *org_name;
	char *table;
	char *org_table;
	char *db;
	char *catalog;
	char *def;
	unsigned long length;
	unsigned long max_length;
	unsigned int name_length;
	unsigned int org_name_length;
	unsigned int table_length;
	unsigned int org_table_length;
	unsigned int db_length;
	unsigned int catalog_length;
	unsigned int def_length;
	unsigned int flags;
	unsigned int decimals;
	unsigned int charsetnr;
	enum enum_field_types type;
	void *extension;
} MYSQL_FIELD;

MYSQL_FIELD *mysql_fetch_field_direct(MYSQL_RES *res, unsigned int fieldnr);

// ---------------------------------------------------------------- reflection

MYSQL_RES *mysql_list_dbs(MYSQL *mysql, const char *wild);
MYSQL_RES *mysql_list_tables(MYSQL *mysql, const char *wild);
MYSQL_RES *mysql_list_processes(MYSQL *mysql);

// ------------------------------------------------------------ remote control

int mysql_kill(MYSQL *mysql, unsigned long pid);

// NOTE: added MYSQL_ prefix.
enum mysql_enum_shutdown_level {
	MYSQL_SHUTDOWN_DEFAULT           = 0,
	MYSQL_SHUTDOWN_WAIT_CONNECTIONS  = 1,
	MYSQL_SHUTDOWN_WAIT_TRANSACTIONS = 2,
	MYSQL_SHUTDOWN_WAIT_UPDATES      = 8,
	MYSQL_SHUTDOWN_WAIT_ALL_BUFFERS  = 16,
	MYSQL_SHUTDOWN_WAIT_CRITICAL_BUFFERS = 17,
	MYSQL_KILL_QUERY                 = 254,
	MYSQL_KILL_CONNECTION            = 255
};
int mysql_shutdown(MYSQL *mysql, enum mysql_enum_shutdown_level shutdown_level); // needs SHUTDOWN priviledge

// NOTE: added MYSQL_ prefix. not really enum values either, just bit flags.
enum {
	MYSQL_REFRESH_GRANT       = 1,    /* Refresh grant tables */
	MYSQL_REFRESH_LOG         = 2,    /* Start on new log file */
	MYSQL_REFRESH_TABLES      = 4,    /* close all tables */
	MYSQL_REFRESH_HOSTS       = 8,    /* Flush host cache */
	MYSQL_REFRESH_STATUS      = 16,   /* Flush status variables */
	MYSQL_REFRESH_THREADS     = 32,   /* Flush thread cache */
	MYSQL_REFRESH_SLAVE       = 64,   /* Reset master info and restart slave thread */
	MYSQL_REFRESH_MASTER      = 128,  /* Remove all bin logs in the index and truncate the index */
	MYSQL_REFRESH_ERROR_LOG   = 256,  /* Rotate only the erorr log */
	MYSQL_REFRESH_ENGINE_LOG  = 512,  /* Flush all storage engine logs */
	MYSQL_REFRESH_BINARY_LOG  = 1024, /* Flush the binary log */
	MYSQL_REFRESH_RELAY_LOG   = 2048, /* Flush the relay log */
	MYSQL_REFRESH_GENERAL_LOG = 4096, /* Flush the general log */
	MYSQL_REFRESH_SLOW_LOG    = 8192, /* Flush the slow query log */

	/* The following can't be set with mysql_refresh() */
	MYSQL_REFRESH_READ_LOCK   = 16384, /* Lock tables for read */
	MYSQL_REFRESH_FAST        = 32768, /* Intern flag */

	/* RESET (remove all queries) from query cache */
	MYSQL_REFRESH_QUERY_CACHE      = 65536,
	MYSQL_REFRESH_QUERY_CACHE_FREE = 0x20000,  /* pack query cache */
	MYSQL_REFRESH_DES_KEY_FILE     = 0x40000,
	MYSQL_REFRESH_USER_RESOURCES   = 0x80000,
	MYSQL_REFRESH_FOR_EXPORT       = 0x100000, /* FLUSH TABLES ... FOR EXPORT */
};
int mysql_refresh(MYSQL *mysql, unsigned int refresh_options); // needs RELOAD priviledge
int mysql_dump_debug_info(MYSQL *mysql);                       // needs SUPER priviledge

// ------------------------------------------------------- prepared statements

typedef struct MYSQL_STMT_ MYSQL_STMT;

MYSQL_STMT * mysql_stmt_init(MYSQL *mysql);
my_bool mysql_stmt_close(MYSQL_STMT * stmt);

int mysql_stmt_prepare(MYSQL_STMT *stmt, const char *query, unsigned long length);
int mysql_stmt_execute(MYSQL_STMT *stmt);

int mysql_stmt_next_result(MYSQL_STMT *stmt);
int mysql_stmt_store_result(MYSQL_STMT *stmt);
my_bool mysql_stmt_free_result(MYSQL_STMT *stmt);

MYSQL_RES *mysql_stmt_result_metadata(MYSQL_STMT *stmt);
my_ulonglong mysql_stmt_num_rows(MYSQL_STMT *stmt);
my_ulonglong mysql_stmt_affected_rows(MYSQL_STMT *stmt);
my_ulonglong mysql_stmt_insert_id(MYSQL_STMT *stmt);
unsigned int mysql_stmt_field_count(MYSQL_STMT *stmt);

unsigned int mysql_stmt_errno(MYSQL_STMT * stmt);
const char *mysql_stmt_error(MYSQL_STMT * stmt);
const char *mysql_stmt_sqlstate(MYSQL_STMT * stmt);

int mysql_stmt_fetch(MYSQL_STMT *stmt);
my_bool mysql_stmt_reset(MYSQL_STMT * stmt);

void mysql_stmt_data_seek(MYSQL_STMT *stmt, my_ulonglong offset);

MYSQL_ROW_OFFSET mysql_stmt_row_tell(MYSQL_STMT *stmt);
MYSQL_ROW_OFFSET mysql_stmt_row_seek(MYSQL_STMT *stmt, MYSQL_ROW_OFFSET offset);

// NOTE: added MYSQL_ prefix to these.
enum enum_cursor_type
{
  MYSQL_CURSOR_TYPE_NO_CURSOR= 0,
  MYSQL_CURSOR_TYPE_READ_ONLY= 1,
  MYSQL_CURSOR_TYPE_FOR_UPDATE= 2,
  MYSQL_CURSOR_TYPE_SCROLLABLE= 4
};

enum enum_stmt_attr_type
{
	STMT_ATTR_UPDATE_MAX_LENGTH,
	STMT_ATTR_CURSOR_TYPE,
	STMT_ATTR_PREFETCH_ROWS
};
my_bool mysql_stmt_attr_set(MYSQL_STMT *stmt, enum enum_stmt_attr_type attr_type, const void *attr);
my_bool mysql_stmt_attr_get(MYSQL_STMT *stmt, enum enum_stmt_attr_type attr_type, void *attr);

my_bool mysql_stmt_send_long_data(MYSQL_STMT *stmt,
                                          unsigned int param_number,
                                          const char *data,
                                          unsigned long length);

// -------------------------------------------- prepared statements / bindings

enum enum_mysql_timestamp_type
{
  MYSQL_TIMESTAMP_NONE= -2, MYSQL_TIMESTAMP_ERROR= -1,
  MYSQL_TIMESTAMP_DATE= 0, MYSQL_TIMESTAMP_DATETIME= 1, MYSQL_TIMESTAMP_TIME= 2
};
typedef struct st_mysql_time
{
  unsigned int  year, month, day, hour, minute, second;
  unsigned long second_part;  /**< microseconds */
  my_bool       neg;
  enum enum_mysql_timestamp_type time_type;
} MYSQL_TIME;

unsigned long mysql_stmt_param_count(MYSQL_STMT * stmt);

typedef struct NET_ NET;
typedef struct st_mysql_bind
{
	unsigned long *length;
	my_bool *is_null;
	void *buffer;
	my_bool *error;
	unsigned char *row_ptr;
	void (*store_param_func)(NET *net, struct st_mysql_bind *param);
	void (*fetch_result)(struct st_mysql_bind *, MYSQL_FIELD *,
							  unsigned char **row);
	void (*skip_result)(struct st_mysql_bind *, MYSQL_FIELD *,
		  unsigned char **row);
	unsigned long buffer_length;
	unsigned long offset;
	unsigned long length_value;
	unsigned int param_number;
	unsigned int pack_length;
	enum enum_field_types buffer_type;
	my_bool error_value;
	my_bool is_unsigned;
	my_bool long_data_used;
	my_bool is_null_value;
	void *extension;
} MYSQL_BIND;

my_bool mysql_stmt_bind_param(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool mysql_stmt_bind_result(MYSQL_STMT * stmt, MYSQL_BIND * bnd);

int mysql_stmt_fetch_column(MYSQL_STMT *stmt, MYSQL_BIND *bind_arg,
                                    unsigned int column,
                                    unsigned long offset);

// ---------------------------------------------- LOAD DATA LOCAL INFILE hooks

void mysql_set_local_infile_handler(MYSQL *mysql,
                               int (*local_infile_init)(void **, const char *, void *),
                               int (*local_infile_read)(void *, char *, unsigned int),
                               void (*local_infile_end)(void *),
                               int (*local_infile_error)(void *, char*, unsigned int),
										 void *);
void mysql_set_local_infile_default(MYSQL *mysql);

// ----------------------------------------------------- mysql proxy scripting

my_bool mysql_read_query_result(MYSQL *mysql);

// ----------------------------------------------------------------- debugging

void mysql_debug(const char *debug);

// ------------------------------------------------ present but not documented

int  mysql_server_init(int argc, char **argv, char **groups);
void mysql_server_end(void);
char *get_tty_password(const char *opt_message);
void myodbc_remove_escape(MYSQL *mysql, char *name);
my_bool mysql_embedded(void);
int mysql_send_query(MYSQL *mysql, const char *q, unsigned long length);

// ------------------------------------------------------- redundant functions

my_bool mysql_thread_init(void); // called anyway
void mysql_thread_end(void);  // called anyway
const char *mysql_errno_to_sqlstate(unsigned int mysql_errno); // use mysql_sqlstate
unsigned long mysql_hex_string(char *to, const char *from,
	unsigned long from_length); // bad taste

// redundant ways to get field info.
// we use use mysql_field_count and mysql_fetch_field_direct instead.
MYSQL_FIELD *mysql_fetch_field(MYSQL_RES *result);
MYSQL_FIELD *mysql_fetch_fields(MYSQL_RES *res);
typedef unsigned int MYSQL_FIELD_OFFSET;
MYSQL_FIELD_OFFSET mysql_field_tell(MYSQL_RES *res);
MYSQL_FIELD_OFFSET mysql_field_seek(MYSQL_RES *result, MYSQL_FIELD_OFFSET offset);
MYSQL_RES *mysql_stmt_param_metadata(MYSQL_STMT *stmt);

// ------------------------------------------------------ deprecated functions

unsigned long mysql_escape_string(char *to, const char *from,
	unsigned long from_length); // use mysql_real_escape_string
int mysql_query(MYSQL *mysql, const char *q); // use mysql_real_query
MYSQL_RES *mysql_list_fields(MYSQL *mysql, const char *table,
	const char *wild); // use "SHOW COLUMNS FROM table"

]]
