--result of cpp `ibase.h` from firebird 2.5.2 (deprecated functions removed)
local ffi = require'ffi'

ffi.cdef[[
typedef intptr_t ISC_STATUS;
typedef int32_t  ISC_LONG;
typedef uint32_t ISC_ULONG;
typedef int16_t  ISC_SHORT;
typedef uint16_t ISC_USHORT;
typedef uint8_t  ISC_UCHAR;
typedef int8_t   ISC_SCHAR;
typedef int64_t  ISC_INT64;
typedef uint64_t ISC_UINT64;
typedef int32_t  ISC_DATE;
typedef uint32_t ISC_TIME;
typedef struct
{
	ISC_DATE timestamp_date;
	ISC_TIME timestamp_time;
} ISC_TIMESTAMP;
struct GDS_QUAD_t {
	ISC_LONG gds_quad_high;
	ISC_ULONG gds_quad_low;
};
typedef struct  GDS_QUAD_t GDS_QUAD;
typedef struct  GDS_QUAD_t ISC_QUAD;
typedef int32_t FB_API_HANDLE;
typedef int (*FB_SHUTDOWN_CALLBACK)(const int reason, const int mask, void* arg);

typedef FB_API_HANDLE isc_db_handle;
typedef FB_API_HANDLE isc_tr_handle;
typedef FB_API_HANDLE isc_req_handle;
typedef FB_API_HANDLE isc_stmt_handle;
typedef FB_API_HANDLE isc_svc_handle;
typedef FB_API_HANDLE isc_blob_handle;
typedef void (* isc_callback) ();
typedef ISC_LONG isc_resv_handle;
typedef void (*ISC_PRINT_CALLBACK) (void*, ISC_SHORT, const char*);
typedef void (*ISC_VERSION_CALLBACK)(void*, const char*);
typedef void (*ISC_EVENT_CALLBACK)(void*, ISC_USHORT, const ISC_UCHAR*);
typedef GDS_QUAD GDS__QUAD;
typedef struct
{
 short array_bound_lower;
 short array_bound_upper;
} ISC_ARRAY_BOUND;
typedef struct
{
 ISC_UCHAR array_desc_dtype;
 ISC_SCHAR array_desc_scale;
 unsigned short array_desc_length;
 ISC_SCHAR array_desc_field_name[32];
 ISC_SCHAR array_desc_relation_name[32];
 short array_desc_dimensions;
 short array_desc_flags;
 ISC_ARRAY_BOUND array_desc_bounds[16];
} ISC_ARRAY_DESC;
typedef struct
{
 short blob_desc_subtype;
 short blob_desc_charset;
 short blob_desc_segment_size;
 ISC_UCHAR blob_desc_field_name[32];
 ISC_UCHAR blob_desc_relation_name[32];
} ISC_BLOB_DESC;
typedef struct isc_blob_ctl
{
 ISC_STATUS (* ctl_source)();
 struct isc_blob_ctl* ctl_source_handle;
 short ctl_to_sub_type;
 short ctl_from_sub_type;
 unsigned short ctl_buffer_length;
 unsigned short ctl_segment_length;
 unsigned short ctl_bpb_length;
 ISC_SCHAR* ctl_bpb;
 ISC_UCHAR* ctl_buffer;
 ISC_LONG ctl_max_segment;
 ISC_LONG ctl_number_segments;
 ISC_LONG ctl_total_length;
 ISC_STATUS* ctl_status;
 long ctl_data[8];
} * ISC_BLOB_CTL;
typedef struct bstream
{
 isc_blob_handle bstr_blob;
 ISC_SCHAR * bstr_buffer;
 ISC_SCHAR * bstr_ptr;
 short bstr_length;
 short bstr_cnt;
 char bstr_mode;
} BSTREAM;
enum blob_lseek_mode {blb_seek_relative = 1, blb_seek_from_tail = 2};
enum blob_get_result {blb_got_fragment = -1, blb_got_eof = 0, blb_got_full_segment = 1};
typedef struct blobcallback {
    short (*blob_get_segment)
  (void* hnd, ISC_UCHAR* buffer, ISC_USHORT buf_size, ISC_USHORT* result_len);
    void* blob_handle;
    ISC_LONG blob_number_segments;
    ISC_LONG blob_max_segment;
    ISC_LONG blob_total_length;
    void (*blob_put_segment)
  (void* hnd, const ISC_UCHAR* buffer, ISC_USHORT buf_size);
    ISC_LONG (*blob_lseek)
  (void* hnd, ISC_USHORT mode, ISC_LONG offset);
} *BLOBCALLBACK;
typedef struct paramdsc {
    ISC_UCHAR dsc_dtype;
    signed char dsc_scale;
    ISC_USHORT dsc_length;
    short dsc_sub_type;
    ISC_USHORT dsc_flags;
    ISC_UCHAR *dsc_address;
} PARAMDSC;
typedef struct paramvary {
    ISC_USHORT vary_length;
    ISC_UCHAR vary_string[1];
} PARAMVARY;
typedef struct
{
 ISC_SHORT sqltype;
 ISC_SHORT sqlscale;
 ISC_SHORT sqlsubtype;
 ISC_SHORT sqllen;
 ISC_SCHAR* sqldata;
 ISC_SHORT* sqlind;
 ISC_SHORT sqlname_length;
 ISC_SCHAR sqlname[32];
 ISC_SHORT relname_length;
 ISC_SCHAR relname[32];
 ISC_SHORT ownname_length;
 ISC_SCHAR ownname[32];
 ISC_SHORT aliasname_length;
 ISC_SCHAR aliasname[32];
} XSQLVAR;
typedef struct
{
 ISC_SHORT version;
 ISC_SCHAR sqldaid[8];
 ISC_LONG sqldabc;
 ISC_SHORT sqln; // number of XSQLVAR allocated
 ISC_SHORT sqld; // number of XSQLVAR used
 XSQLVAR sqlvar[?];
} XSQLDA;

// from jrd.h for isc_start_multiple
typedef struct {
	isc_db_handle*  teb_database;
	int32_t         teb_tpb_length;
	const uint8_t*  teb_tpb;
} ISC_TEB;

ISC_STATUS isc_attach_database(ISC_STATUS*,
            short,
            const ISC_SCHAR*,
            isc_db_handle*,
            short,
            const ISC_SCHAR*);
ISC_STATUS isc_array_gen_sdl(ISC_STATUS*,
          const ISC_ARRAY_DESC*,
          ISC_SHORT*,
          ISC_UCHAR*,
          ISC_SHORT*);
ISC_STATUS isc_array_get_slice(ISC_STATUS*,
            isc_db_handle*,
            isc_tr_handle*,
            ISC_QUAD*,
            const ISC_ARRAY_DESC*,
            void*,
            ISC_LONG*);
ISC_STATUS isc_array_lookup_bounds(ISC_STATUS*,
             isc_db_handle*,
             isc_tr_handle*,
             const ISC_SCHAR*,
             const ISC_SCHAR*,
             ISC_ARRAY_DESC*);
ISC_STATUS isc_array_lookup_desc(ISC_STATUS*,
           isc_db_handle*,
           isc_tr_handle*,
           const ISC_SCHAR*,
           const ISC_SCHAR*,
           ISC_ARRAY_DESC*);
ISC_STATUS isc_array_set_desc(ISC_STATUS*,
           const ISC_SCHAR*,
           const ISC_SCHAR*,
           const short*,
           const short*,
           const short*,
           ISC_ARRAY_DESC*);
ISC_STATUS isc_array_put_slice(ISC_STATUS*,
            isc_db_handle*,
            isc_tr_handle*,
            ISC_QUAD*,
            const ISC_ARRAY_DESC*,
            void*,
            ISC_LONG *);
void isc_blob_default_desc(ISC_BLOB_DESC*,
           const ISC_UCHAR*,
           const ISC_UCHAR*);
ISC_STATUS isc_blob_gen_bpb(ISC_STATUS*,
            const ISC_BLOB_DESC*,
            const ISC_BLOB_DESC*,
            unsigned short,
            ISC_UCHAR*,
            unsigned short*);
ISC_STATUS isc_blob_info(ISC_STATUS*,
         isc_blob_handle*,
         short,
         const ISC_SCHAR*,
         short,
         ISC_SCHAR*);
ISC_STATUS isc_blob_lookup_desc(ISC_STATUS*,
             isc_db_handle*,
             isc_tr_handle*,
             const ISC_UCHAR*,
             const ISC_UCHAR*,
             ISC_BLOB_DESC*,
             ISC_UCHAR*);
ISC_STATUS isc_blob_set_desc(ISC_STATUS*,
          const ISC_UCHAR*,
          const ISC_UCHAR*,
          short,
          short,
          short,
          ISC_BLOB_DESC*);
ISC_STATUS isc_cancel_blob(ISC_STATUS *,
           isc_blob_handle *);
ISC_STATUS isc_cancel_events(ISC_STATUS *,
          isc_db_handle *,
          ISC_LONG *);
ISC_STATUS isc_close_blob(ISC_STATUS *,
          isc_blob_handle *);
ISC_STATUS isc_commit_retaining(ISC_STATUS *,
             isc_tr_handle *);
ISC_STATUS isc_commit_transaction(ISC_STATUS *,
            isc_tr_handle *);
ISC_STATUS isc_create_blob(ISC_STATUS*,
           isc_db_handle*,
           isc_tr_handle*,
           isc_blob_handle*,
           ISC_QUAD*);
ISC_STATUS isc_create_blob2(ISC_STATUS*,
            isc_db_handle*,
            isc_tr_handle*,
            isc_blob_handle*,
            ISC_QUAD*,
            short,
            const ISC_SCHAR*);
ISC_STATUS isc_create_database(ISC_STATUS*,
            short,
            const ISC_SCHAR*,
            isc_db_handle*,
            short,
            const ISC_SCHAR*,
            short);
ISC_STATUS isc_database_info(ISC_STATUS*,
          isc_db_handle*,
          short,
          const ISC_SCHAR*,
          short,
          ISC_SCHAR*);
void isc_decode_date(const ISC_QUAD*,
        void*);
void isc_decode_sql_date(const ISC_DATE*,
         void*);
void isc_decode_sql_time(const ISC_TIME*,
         void*);
void isc_decode_timestamp(const ISC_TIMESTAMP*,
          void*);
ISC_STATUS isc_detach_database(ISC_STATUS *,
            isc_db_handle *);
ISC_STATUS isc_drop_database(ISC_STATUS *,
          isc_db_handle *);
ISC_STATUS isc_dsql_allocate_statement(ISC_STATUS *,
              isc_db_handle *,
              isc_stmt_handle *);
ISC_STATUS isc_dsql_alloc_statement2(ISC_STATUS *,
            isc_db_handle *,
            isc_stmt_handle *);
ISC_STATUS isc_dsql_describe(ISC_STATUS *,
          isc_stmt_handle *,
          unsigned short,
          XSQLDA *);
ISC_STATUS isc_dsql_describe_bind(ISC_STATUS *,
            isc_stmt_handle *,
            unsigned short,
            XSQLDA *);
ISC_STATUS isc_dsql_exec_immed2(ISC_STATUS*,
             isc_db_handle*,
             isc_tr_handle*,
             unsigned short,
             const ISC_SCHAR*,
             unsigned short,
             const XSQLDA*,
             const XSQLDA*);
ISC_STATUS isc_dsql_execute(ISC_STATUS*,
            isc_tr_handle*,
            isc_stmt_handle*,
            unsigned short,
            const XSQLDA*);
ISC_STATUS isc_dsql_execute2(ISC_STATUS*,
          isc_tr_handle*,
          isc_stmt_handle*,
          unsigned short,
          const XSQLDA*,
          const XSQLDA*);
ISC_STATUS isc_dsql_execute_immediate(ISC_STATUS*,
             isc_db_handle*,
             isc_tr_handle*,
             unsigned short,
             const ISC_SCHAR*,
             unsigned short,
             const XSQLDA*);
ISC_STATUS isc_dsql_fetch(ISC_STATUS *,
          isc_stmt_handle *,
          unsigned short,
          const XSQLDA *);
ISC_STATUS isc_dsql_finish(isc_db_handle *);
ISC_STATUS isc_dsql_free_statement(ISC_STATUS *,
             isc_stmt_handle *,
             unsigned short);
ISC_STATUS isc_dsql_insert(ISC_STATUS*,
           isc_stmt_handle*,
           unsigned short,
           XSQLDA*);
ISC_STATUS isc_dsql_prepare(ISC_STATUS*,
            isc_tr_handle*,
            isc_stmt_handle*,
            unsigned short,
            const ISC_SCHAR*,
            unsigned short,
            XSQLDA*);
ISC_STATUS isc_dsql_set_cursor_name(ISC_STATUS*,
              isc_stmt_handle*,
              const ISC_SCHAR*,
              unsigned short);
ISC_STATUS isc_dsql_sql_info(ISC_STATUS*,
          isc_stmt_handle*,
          short,
          const ISC_SCHAR*,
          short,
          ISC_SCHAR*);
void isc_encode_date(const void*,
        ISC_QUAD*);
void isc_encode_sql_date(const void*,
         ISC_DATE*);
void isc_encode_sql_time(const void*,
         ISC_TIME*);
void isc_encode_timestamp(const void*,
          ISC_TIMESTAMP*);
ISC_LONG isc_event_block(ISC_UCHAR**,
             ISC_UCHAR**,
             ISC_USHORT, ...);
ISC_USHORT isc_event_block_a(ISC_SCHAR**,
          ISC_SCHAR**,
          ISC_USHORT,
          ISC_SCHAR**);
void isc_event_block_s(ISC_SCHAR**,
          ISC_SCHAR**,
          ISC_USHORT,
          ISC_SCHAR**,
          ISC_USHORT*);
void isc_event_counts(ISC_ULONG*,
         short,
         ISC_UCHAR*,
         const ISC_UCHAR *);
int isc_modify_dpb(ISC_SCHAR**,
         short*,
         unsigned short,
         const ISC_SCHAR*,
         short);
ISC_LONG isc_free(ISC_SCHAR *);
ISC_STATUS isc_get_segment(ISC_STATUS *,
           isc_blob_handle *,
           unsigned short *,
           unsigned short,
           ISC_SCHAR *);
ISC_STATUS isc_get_slice(ISC_STATUS*,
         isc_db_handle*,
         isc_tr_handle*,
         ISC_QUAD*,
         short,
         const ISC_SCHAR*,
         short,
         const ISC_LONG*,
         ISC_LONG,
         void*,
         ISC_LONG*);
ISC_LONG fb_interpret(ISC_SCHAR*,
         unsigned int,
         const ISC_STATUS**);
ISC_STATUS isc_open_blob(ISC_STATUS*,
         isc_db_handle*,
         isc_tr_handle*,
         isc_blob_handle*,
         ISC_QUAD*);
ISC_STATUS isc_open_blob2(ISC_STATUS*,
          isc_db_handle*,
          isc_tr_handle*,
          isc_blob_handle*,
          ISC_QUAD*,
          ISC_USHORT,
          const ISC_UCHAR*);
ISC_STATUS isc_prepare_transaction2(ISC_STATUS*,
              isc_tr_handle*,
              ISC_USHORT,
              const ISC_UCHAR*);
void isc_print_sqlerror(ISC_SHORT,
           const ISC_STATUS*);
ISC_STATUS isc_print_status(const ISC_STATUS*);
ISC_STATUS isc_put_segment(ISC_STATUS*,
           isc_blob_handle*,
           unsigned short,
           const ISC_SCHAR*);
ISC_STATUS isc_put_slice(ISC_STATUS*,
         isc_db_handle*,
         isc_tr_handle*,
         ISC_QUAD*,
         short,
         const ISC_SCHAR*,
         short,
         const ISC_LONG*,
         ISC_LONG,
         void*);
ISC_STATUS isc_que_events(ISC_STATUS*,
          isc_db_handle*,
          ISC_LONG*,
          short,
          const ISC_UCHAR*,
          ISC_EVENT_CALLBACK,
          void*);
ISC_STATUS isc_rollback_retaining(ISC_STATUS*,
            isc_tr_handle*);
ISC_STATUS isc_rollback_transaction(ISC_STATUS*,
              isc_tr_handle*);
ISC_STATUS isc_start_multiple(ISC_STATUS*,
           isc_tr_handle*,
           short,
           void *);
ISC_STATUS isc_start_transaction(ISC_STATUS*,
               isc_tr_handle*,
               short, ...);
ISC_STATUS fb_disconnect_transaction(ISC_STATUS*, isc_tr_handle*);
ISC_LONG isc_sqlcode(const ISC_STATUS*);
void isc_sqlcode_s(const ISC_STATUS*,
         ISC_ULONG*);
void fb_sqlstate(char*,
       const ISC_STATUS*);
void isc_sql_interprete(short,
           ISC_SCHAR*,
           short);
ISC_STATUS isc_transaction_info(ISC_STATUS*,
             isc_tr_handle*,
             short,
             const ISC_SCHAR*,
             short,
             ISC_SCHAR*);
ISC_STATUS isc_transact_request(ISC_STATUS*,
             isc_db_handle*,
             isc_tr_handle*,
             unsigned short,
             ISC_SCHAR*,
             unsigned short,
             ISC_SCHAR*,
             unsigned short,
             ISC_SCHAR*);
ISC_LONG isc_vax_integer(const ISC_SCHAR*,
         short);
ISC_INT64 isc_portable_integer(const ISC_UCHAR*,
            short);
typedef struct {
 short sec_flags;
 int uid;
 int gid;
 int protocol;
 ISC_SCHAR *server;
 ISC_SCHAR *user_name;
 ISC_SCHAR *password;
 ISC_SCHAR *group_name;
 ISC_SCHAR *first_name;
 ISC_SCHAR *middle_name;
 ISC_SCHAR *last_name;
 ISC_SCHAR *dba_user_name;
 ISC_SCHAR *dba_password;
} USER_SEC_DATA;
ISC_STATUS isc_add_user(ISC_STATUS*, const USER_SEC_DATA*);
ISC_STATUS isc_delete_user(ISC_STATUS*, const USER_SEC_DATA*);
ISC_STATUS isc_modify_user(ISC_STATUS*, const USER_SEC_DATA*);
ISC_STATUS isc_compile_request(ISC_STATUS*,
            isc_db_handle*,
            isc_req_handle*,
            short,
            const ISC_SCHAR*);
ISC_STATUS isc_compile_request2(ISC_STATUS*,
             isc_db_handle*,
             isc_req_handle*,
             short,
             const ISC_SCHAR*);
ISC_STATUS isc_prepare_transaction(ISC_STATUS*,
             isc_tr_handle*);
ISC_STATUS isc_receive(ISC_STATUS*,
          isc_req_handle*,
          short,
          short,
          void*,
          short);
ISC_STATUS isc_reconnect_transaction(ISC_STATUS*,
            isc_db_handle*,
            isc_tr_handle*,
            short,
            const ISC_SCHAR*);
ISC_STATUS isc_release_request(ISC_STATUS*,
            isc_req_handle*);
ISC_STATUS isc_request_info(ISC_STATUS*,
            isc_req_handle*,
            short,
            short,
            const ISC_SCHAR*,
            short,
            ISC_SCHAR*);
ISC_STATUS isc_seek_blob(ISC_STATUS*,
         isc_blob_handle*,
         short,
         ISC_LONG,
         ISC_LONG*);
ISC_STATUS isc_send(ISC_STATUS*,
          isc_req_handle*,
          short,
          short,
          const void*,
          short);
ISC_STATUS isc_start_and_send(ISC_STATUS*,
           isc_req_handle*,
           isc_tr_handle*,
           short,
           short,
           const void*,
           short);
ISC_STATUS isc_start_request(ISC_STATUS *,
          isc_req_handle *,
          isc_tr_handle *,
          short);
ISC_STATUS isc_unwind_request(ISC_STATUS *,
           isc_tr_handle *,
           short);
ISC_STATUS isc_wait_for_event(ISC_STATUS*,
           isc_db_handle*,
           short,
           const ISC_UCHAR*,
           ISC_UCHAR*);
ISC_STATUS isc_close(ISC_STATUS*,
        const ISC_SCHAR*);
ISC_STATUS isc_declare(ISC_STATUS*,
          const ISC_SCHAR*,
          const ISC_SCHAR*);
ISC_STATUS isc_describe(ISC_STATUS*,
           const ISC_SCHAR*,
           XSQLDA *);
ISC_STATUS isc_describe_bind(ISC_STATUS*,
          const ISC_SCHAR*,
          XSQLDA*);
ISC_STATUS isc_execute(ISC_STATUS*,
          isc_tr_handle*,
          const ISC_SCHAR*,
          XSQLDA*);
ISC_STATUS isc_execute_immediate(ISC_STATUS*,
           isc_db_handle*,
           isc_tr_handle*,
           short*,
           const ISC_SCHAR*);
ISC_STATUS isc_fetch(ISC_STATUS*,
        const ISC_SCHAR*,
        XSQLDA*);
ISC_STATUS isc_open(ISC_STATUS*,
          isc_tr_handle*,
          const ISC_SCHAR*,
          XSQLDA*);
ISC_STATUS isc_prepare(ISC_STATUS*,
          isc_db_handle*,
          isc_tr_handle*,
          const ISC_SCHAR*,
          const short*,
          const ISC_SCHAR*,
          XSQLDA*);
ISC_STATUS isc_dsql_execute_m(ISC_STATUS*,
           isc_tr_handle*,
           isc_stmt_handle*,
           unsigned short,
           const ISC_SCHAR*,
           unsigned short,
           unsigned short,
           ISC_SCHAR*);
ISC_STATUS isc_dsql_execute2_m(ISC_STATUS*,
            isc_tr_handle*,
            isc_stmt_handle*,
            unsigned short,
            const ISC_SCHAR*,
            unsigned short,
            unsigned short,
            ISC_SCHAR*,
            unsigned short,
            ISC_SCHAR*,
            unsigned short,
            unsigned short,
            ISC_SCHAR*);
ISC_STATUS isc_dsql_execute_immediate_m(ISC_STATUS*,
               isc_db_handle*,
               isc_tr_handle*,
               unsigned short,
               const ISC_SCHAR*,
               unsigned short,
               unsigned short,
               ISC_SCHAR*,
               unsigned short,
               unsigned short,
               ISC_SCHAR*);
ISC_STATUS isc_dsql_exec_immed3_m(ISC_STATUS*,
            isc_db_handle*,
            isc_tr_handle*,
            unsigned short,
            const ISC_SCHAR*,
            unsigned short,
            unsigned short,
            ISC_SCHAR*,
            unsigned short,
            unsigned short,
            const ISC_SCHAR*,
            unsigned short,
            ISC_SCHAR*,
            unsigned short,
            unsigned short,
            ISC_SCHAR*);
ISC_STATUS isc_dsql_fetch_m(ISC_STATUS*,
            isc_stmt_handle*,
            unsigned short,
            ISC_SCHAR*,
            unsigned short,
            unsigned short,
            ISC_SCHAR*);
ISC_STATUS isc_dsql_insert_m(ISC_STATUS*,
          isc_stmt_handle*,
          unsigned short,
          const ISC_SCHAR*,
          unsigned short,
          unsigned short,
          const ISC_SCHAR*);
ISC_STATUS isc_dsql_prepare_m(ISC_STATUS*,
           isc_tr_handle*,
           isc_stmt_handle*,
           unsigned short,
           const ISC_SCHAR*,
           unsigned short,
           unsigned short,
           const ISC_SCHAR*,
           unsigned short,
           ISC_SCHAR*);
ISC_STATUS isc_dsql_release(ISC_STATUS*,
            const ISC_SCHAR*);
ISC_STATUS isc_embed_dsql_close(ISC_STATUS*,
             const ISC_SCHAR*);
ISC_STATUS isc_embed_dsql_declare(ISC_STATUS*,
            const ISC_SCHAR*,
            const ISC_SCHAR*);
ISC_STATUS isc_embed_dsql_describe(ISC_STATUS*,
             const ISC_SCHAR*,
             unsigned short,
             XSQLDA*);
ISC_STATUS isc_embed_dsql_describe_bind(ISC_STATUS*,
               const ISC_SCHAR*,
               unsigned short,
               XSQLDA*);
ISC_STATUS isc_embed_dsql_execute(ISC_STATUS*,
            isc_tr_handle*,
            const ISC_SCHAR*,
            unsigned short,
            XSQLDA*);
ISC_STATUS isc_embed_dsql_execute2(ISC_STATUS*,
             isc_tr_handle*,
             const ISC_SCHAR*,
             unsigned short,
             XSQLDA*,
             XSQLDA*);
ISC_STATUS isc_embed_dsql_execute_immed(ISC_STATUS*,
               isc_db_handle*,
               isc_tr_handle*,
               unsigned short,
               const ISC_SCHAR*,
               unsigned short,
               XSQLDA*);
ISC_STATUS isc_embed_dsql_fetch(ISC_STATUS*,
             const ISC_SCHAR*,
             unsigned short,
             XSQLDA*);
ISC_STATUS isc_embed_dsql_fetch_a(ISC_STATUS*,
            int*,
            const ISC_SCHAR*,
            ISC_USHORT,
            XSQLDA*);
void isc_embed_dsql_length(const ISC_UCHAR*,
           ISC_USHORT*);
ISC_STATUS isc_embed_dsql_open(ISC_STATUS*,
            isc_tr_handle*,
            const ISC_SCHAR*,
            unsigned short,
            XSQLDA*);
ISC_STATUS isc_embed_dsql_open2(ISC_STATUS*,
             isc_tr_handle*,
             const ISC_SCHAR*,
             unsigned short,
             XSQLDA*,
             XSQLDA*);
ISC_STATUS isc_embed_dsql_insert(ISC_STATUS*,
           const ISC_SCHAR*,
           unsigned short,
           XSQLDA*);
ISC_STATUS isc_embed_dsql_prepare(ISC_STATUS*,
            isc_db_handle*,
            isc_tr_handle*,
            const ISC_SCHAR*,
            unsigned short,
            const ISC_SCHAR*,
            unsigned short,
            XSQLDA*);
ISC_STATUS isc_embed_dsql_release(ISC_STATUS*,
            const ISC_SCHAR*);
BSTREAM* BLOB_open(isc_blob_handle,
           ISC_SCHAR*,
           int);
int BLOB_put(ISC_SCHAR,
      BSTREAM*);
int BLOB_close(BSTREAM*);
int BLOB_get(BSTREAM*);
int BLOB_display(ISC_QUAD*,
       isc_db_handle,
       isc_tr_handle,
       const ISC_SCHAR*);
int BLOB_dump(ISC_QUAD*,
       isc_db_handle,
       isc_tr_handle,
       const ISC_SCHAR*);
int BLOB_edit(ISC_QUAD*,
       isc_db_handle,
       isc_tr_handle,
       const ISC_SCHAR*);
int BLOB_load(ISC_QUAD*,
       isc_db_handle,
       isc_tr_handle,
       const ISC_SCHAR*);
int BLOB_text_dump(ISC_QUAD*,
         isc_db_handle,
         isc_tr_handle,
         const ISC_SCHAR*);
int BLOB_text_load(ISC_QUAD*,
         isc_db_handle,
         isc_tr_handle,
         const ISC_SCHAR*);
BSTREAM* Bopen(ISC_QUAD*,
          isc_db_handle,
          isc_tr_handle,
          const ISC_SCHAR*);
ISC_LONG isc_ftof(const ISC_SCHAR*,
        const unsigned short,
        ISC_SCHAR*,
        const unsigned short);
ISC_STATUS isc_print_blr(const ISC_SCHAR*,
         ISC_PRINT_CALLBACK,
         void*,
         short);
int fb_print_blr(const ISC_UCHAR*,
       ISC_ULONG,
       ISC_PRINT_CALLBACK,
       void*,
       short);
void isc_set_debug(int);
void isc_qtoq(const ISC_QUAD*,
       ISC_QUAD*);
void isc_vtof(const ISC_SCHAR*,
       ISC_SCHAR*,
       unsigned short);
void isc_vtov(const ISC_SCHAR*,
       ISC_SCHAR*,
       short);
int isc_version(isc_db_handle*,
         ISC_VERSION_CALLBACK,
         void*);
uintptr_t isc_baddress(ISC_SCHAR*);
void isc_baddress_s(const ISC_SCHAR*,
          uintptr_t*);
ISC_STATUS isc_service_attach(ISC_STATUS*,
           unsigned short,
           const ISC_SCHAR*,
           isc_svc_handle*,
           unsigned short,
           const ISC_SCHAR*);
ISC_STATUS isc_service_detach(ISC_STATUS *,
           isc_svc_handle *);
ISC_STATUS isc_service_query(ISC_STATUS*,
          isc_svc_handle*,
          isc_resv_handle*,
          unsigned short,
          const ISC_SCHAR*,
          unsigned short,
          const ISC_SCHAR*,
          unsigned short,
          ISC_SCHAR*);
ISC_STATUS isc_service_start(ISC_STATUS*,
          isc_svc_handle*,
          isc_resv_handle*,
          unsigned short,
          const ISC_SCHAR*);
int fb_shutdown(unsigned int, const int);
ISC_STATUS fb_shutdown_callback(ISC_STATUS*,
             FB_SHUTDOWN_CALLBACK,
             const int,
             void*);
ISC_STATUS fb_cancel_operation(ISC_STATUS*,
            isc_db_handle*,
            ISC_USHORT);
void isc_get_client_version ( ISC_SCHAR *);
int isc_get_client_major_version ();
int isc_get_client_minor_version ();
enum db_info_types
{
 isc_info_db_id = 4,
 isc_info_reads = 5,
 isc_info_writes = 6,
 isc_info_fetches = 7,
 isc_info_marks = 8,
 isc_info_implementation = 11,
 isc_info_isc_version = 12,
 isc_info_base_level = 13,
 isc_info_page_size = 14,
 isc_info_num_buffers = 15,
 isc_info_limbo = 16,
 isc_info_current_memory = 17,
 isc_info_max_memory = 18,
 isc_info_window_turns = 19,
 isc_info_license = 20,
 isc_info_allocation = 21,
 isc_info_attachment_id = 22,
 isc_info_read_seq_count = 23,
 isc_info_read_idx_count = 24,
 isc_info_insert_count = 25,
 isc_info_update_count = 26,
 isc_info_delete_count = 27,
 isc_info_backout_count = 28,
 isc_info_purge_count = 29,
 isc_info_expunge_count = 30,
 isc_info_sweep_interval = 31,
 isc_info_ods_version = 32,
 isc_info_ods_minor_version = 33,
 isc_info_no_reserve = 34,
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
 isc_info_forced_writes = 52,
 isc_info_user_names = 53,
 isc_info_page_errors = 54,
 isc_info_record_errors = 55,
 isc_info_bpage_errors = 56,
 isc_info_dpage_errors = 57,
 isc_info_ipage_errors = 58,
 isc_info_ppage_errors = 59,
 isc_info_tpage_errors = 60,
 isc_info_set_page_buffers = 61,
 isc_info_db_sql_dialect = 62,
 isc_info_db_read_only = 63,
 isc_info_db_size_in_pages = 64,
 frb_info_att_charset = 101,
 isc_info_db_class = 102,
 isc_info_firebird_version = 103,
 isc_info_oldest_transaction = 104,
 isc_info_oldest_active = 105,
 isc_info_oldest_snapshot = 106,
 isc_info_next_transaction = 107,
 isc_info_db_provider = 108,
 isc_info_active_transactions = 109,
 isc_info_active_tran_count = 110,
 isc_info_creation_date = 111,
 isc_info_db_file_size = 112,
 fb_info_page_contents = 113,
 isc_info_db_last_value
};
enum info_db_implementations
{
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
 isc_info_db_impl_linux_s390x = 78,
 isc_info_db_impl_linux_s390 = 79,
 isc_info_db_impl_linux_sh = 80,
 isc_info_db_impl_linux_sheb = 81,
 isc_info_db_impl_linux_hppa = 82,
 isc_info_db_impl_linux_alpha = 83,
 isc_info_db_impl_last_value
};
enum info_db_class
{
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
 isc_info_db_class_last_value
};
enum info_db_provider
{
 isc_info_db_code_rdb_eln = 1,
 isc_info_db_code_rdb_vms = 2,
 isc_info_db_code_interbase = 3,
 isc_info_db_code_firebird = 4,
 isc_info_db_code_last_value
};
]]
