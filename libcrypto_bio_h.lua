// csrc/openssl/src/include/openssl/bio.h
enum {
	BIO_TYPE_DESCRIPTOR  = 0x0100,
	BIO_TYPE_FILTER      = 0x0200,
	BIO_TYPE_SOURCE_SINK = 0x0400,
	BIO_TYPE_NONE        = 0,
	BIO_TYPE_MEM         = ( 1|BIO_TYPE_SOURCE_SINK),
	BIO_TYPE_FILE        = ( 2|BIO_TYPE_SOURCE_SINK),
	BIO_TYPE_FD          = ( 4|BIO_TYPE_SOURCE_SINK|BIO_TYPE_DESCRIPTOR),
	BIO_TYPE_SOCKET      = ( 5|BIO_TYPE_SOURCE_SINK|BIO_TYPE_DESCRIPTOR),
	BIO_TYPE_NULL        = ( 6|BIO_TYPE_SOURCE_SINK),
	BIO_TYPE_SSL         = ( 7|BIO_TYPE_FILTER),
	BIO_TYPE_MD          = ( 8|BIO_TYPE_FILTER),
	BIO_TYPE_BUFFER      = ( 9|BIO_TYPE_FILTER),
	BIO_TYPE_CIPHER      = (10|BIO_TYPE_FILTER),
	BIO_TYPE_BASE64      = (11|BIO_TYPE_FILTER),
	BIO_TYPE_CONNECT     = (12|BIO_TYPE_SOURCE_SINK|BIO_TYPE_DESCRIPTOR),
	BIO_TYPE_ACCEPT      = (13|BIO_TYPE_SOURCE_SINK|BIO_TYPE_DESCRIPTOR),
	BIO_TYPE_NBIO_TEST   = (16|BIO_TYPE_FILTER),
	BIO_TYPE_NULL_FILTER = (17|BIO_TYPE_FILTER),
	BIO_TYPE_BIO         = (19|BIO_TYPE_SOURCE_SINK),
	BIO_TYPE_LINEBUFFER  = (20|BIO_TYPE_FILTER),
	BIO_TYPE_DGRAM       = (21|BIO_TYPE_SOURCE_SINK|BIO_TYPE_DESCRIPTOR),
	BIO_TYPE_ASN1        = (22|BIO_TYPE_FILTER),
	BIO_TYPE_COMP        = (23|BIO_TYPE_FILTER),
	BIO_TYPE_START       = 128,
	BIO_NOCLOSE          = 0x00,
	BIO_CLOSE            = 0x01,
	BIO_CTRL_RESET       = 1,
	BIO_CTRL_EOF         = 2,
	BIO_CTRL_INFO        = 3,
	BIO_CTRL_SET         = 4,
	BIO_CTRL_GET         = 5,
	BIO_CTRL_PUSH        = 6,
	BIO_CTRL_POP         = 7,
	BIO_CTRL_GET_CLOSE   = 8,
	BIO_CTRL_SET_CLOSE   = 9,
	BIO_CTRL_PENDING     = 10,
	BIO_CTRL_FLUSH       = 11,
	BIO_CTRL_DUP         = 12,
	BIO_CTRL_WPENDING    = 13,
	BIO_CTRL_SET_CALLBACK = 14,
	BIO_CTRL_GET_CALLBACK = 15,
	BIO_CTRL_PEEK        = 29,
	BIO_CTRL_SET_FILENAME = 30,
	BIO_CTRL_DGRAM_CONNECT = 31,
	BIO_CTRL_DGRAM_SET_CONNECTED = 32,
	BIO_CTRL_DGRAM_SET_RECV_TIMEOUT = 33,
	BIO_CTRL_DGRAM_GET_RECV_TIMEOUT = 34,
	BIO_CTRL_DGRAM_SET_SEND_TIMEOUT = 35,
	BIO_CTRL_DGRAM_GET_SEND_TIMEOUT = 36,
	BIO_CTRL_DGRAM_GET_RECV_TIMER_EXP = 37,
	BIO_CTRL_DGRAM_GET_SEND_TIMER_EXP = 38,
	BIO_CTRL_DGRAM_MTU_DISCOVER = 39,
	BIO_CTRL_DGRAM_QUERY_MTU = 40,
	BIO_CTRL_DGRAM_GET_FALLBACK_MTU = 47,
	BIO_CTRL_DGRAM_GET_MTU = 41,
	BIO_CTRL_DGRAM_SET_MTU = 42,
	BIO_CTRL_DGRAM_MTU_EXCEEDED = 43,
	BIO_CTRL_DGRAM_GET_PEER = 46,
	BIO_CTRL_DGRAM_SET_PEER = 44,
	BIO_CTRL_DGRAM_SET_NEXT_TIMEOUT = 45,
	BIO_CTRL_DGRAM_SET_DONT_FRAG = 48,
	BIO_CTRL_DGRAM_GET_MTU_OVERHEAD = 49,
	BIO_CTRL_DGRAM_SCTP_SET_IN_HANDSHAKE = 50,
	BIO_CTRL_DGRAM_SET_PEEK_MODE = 71,
	BIO_FP_READ          = 0x02,
	BIO_FP_WRITE         = 0x04,
	BIO_FP_APPEND        = 0x08,
	BIO_FP_TEXT          = 0x10,
	BIO_FLAGS_READ       = 0x01,
	BIO_FLAGS_WRITE      = 0x02,
	BIO_FLAGS_IO_SPECIAL = 0x04,
	BIO_FLAGS_RWS        = (BIO_FLAGS_READ|BIO_FLAGS_WRITE|BIO_FLAGS_IO_SPECIAL),
	BIO_FLAGS_SHOULD_RETRY = 0x08,
	BIO_FLAGS_UPLINK     = 0,
	BIO_FLAGS_BASE64_NO_NL = 0x100,
	BIO_FLAGS_MEM_RDONLY = 0x200,
	BIO_FLAGS_NONCLEAR_RST = 0x400,
};
typedef union bio_addr_st BIO_ADDR;
typedef struct bio_addrinfo_st BIO_ADDRINFO;
int BIO_get_new_index(void);
void BIO_set_flags(BIO *b, int flags);
int BIO_test_flags(const BIO *b, int flags);
void BIO_clear_flags(BIO *b, int flags);
#define BIO_get_flags(b) BIO_test_flags(b, ~(0x0))
#define BIO_set_retry_special(b) BIO_set_flags(b, (BIO_FLAGS_IO_SPECIAL|BIO_FLAGS_SHOULD_RETRY))
#define BIO_set_retry_read(b) BIO_set_flags(b, (BIO_FLAGS_READ|BIO_FLAGS_SHOULD_RETRY))
#define BIO_set_retry_write(b) BIO_set_flags(b, (BIO_FLAGS_WRITE|BIO_FLAGS_SHOULD_RETRY))
#define BIO_clear_retry_flags(b) BIO_clear_flags(b, (BIO_FLAGS_RWS|BIO_FLAGS_SHOULD_RETRY))
#define BIO_get_retry_flags(b) BIO_test_flags(b, (BIO_FLAGS_RWS|BIO_FLAGS_SHOULD_RETRY))
#define BIO_should_read(a) BIO_test_flags(a, BIO_FLAGS_READ)
#define BIO_should_write(a) BIO_test_flags(a, BIO_FLAGS_WRITE)
#define BIO_should_io_special(a) BIO_test_flags(a, BIO_FLAGS_IO_SPECIAL)
#define BIO_retry_type(a) BIO_test_flags(a, BIO_FLAGS_RWS)
#define BIO_should_retry(a) BIO_test_flags(a, BIO_FLAGS_SHOULD_RETRY)
enum {
	BIO_RR_SSL_X509_LOOKUP = 0x01,
	BIO_RR_CONNECT       = 0x02,
	BIO_RR_ACCEPT        = 0x03,
	BIO_CB_FREE          = 0x01,
	BIO_CB_READ          = 0x02,
	BIO_CB_WRITE         = 0x03,
	BIO_CB_PUTS          = 0x04,
	BIO_CB_GETS          = 0x05,
	BIO_CB_CTRL          = 0x06,
	BIO_CB_RETURN        = 0x80,
};
#define BIO_CB_return(a) ((a)|BIO_CB_RETURN)
#define BIO_cb_pre(a) (!((a)&BIO_CB_RETURN))
#define BIO_cb_post(a) ((a)&BIO_CB_RETURN)
typedef long (*BIO_callback_fn)(BIO *b, int oper, const char *argp, int argi,
                                long argl, long ret);
typedef long (*BIO_callback_fn_ex)(BIO *b, int oper, const char *argp,
                                   size_t len, int argi,
                                   long argl, int ret, size_t *processed);
BIO_callback_fn BIO_get_callback(const BIO *b);
void BIO_set_callback(BIO *b, BIO_callback_fn callback);
BIO_callback_fn_ex BIO_get_callback_ex(const BIO *b);
void BIO_set_callback_ex(BIO *b, BIO_callback_fn_ex callback);
char *BIO_get_callback_arg(const BIO *b);
void BIO_set_callback_arg(BIO *b, char *arg);
typedef struct bio_method_st BIO_METHOD;
const char *BIO_method_name(const BIO *b);
int BIO_method_type(const BIO *b);
typedef int BIO_info_cb(BIO *, int, int);
typedef BIO_info_cb bio_info_cb;
struct stack_st_BIO; typedef int (*sk_BIO_compfunc)(const BIO * const *a, const BIO *const *b); typedef void (*sk_BIO_freefunc)(BIO *a); typedef BIO * (*sk_BIO_copyfunc)(const BIO *a); static __attribute__((unused)) inline int sk_BIO_num(const struct stack_st_BIO *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline BIO *sk_BIO_value(const struct stack_st_BIO *sk, int idx) { return (BIO *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_BIO *sk_BIO_new(sk_BIO_compfunc compare) { return (struct stack_st_BIO *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_BIO *sk_BIO_new_null(void) { return (struct stack_st_BIO *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_BIO *sk_BIO_new_reserve(sk_BIO_compfunc compare, int n) { return (struct stack_st_BIO *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_BIO_reserve(struct stack_st_BIO *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_BIO_free(struct stack_st_BIO *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_BIO_zero(struct stack_st_BIO *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline BIO *sk_BIO_delete(struct stack_st_BIO *sk, int i) { return (BIO *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline BIO *sk_BIO_delete_ptr(struct stack_st_BIO *sk, BIO *ptr) { return (BIO *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_BIO_push(struct stack_st_BIO *sk, BIO *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_BIO_unshift(struct stack_st_BIO *sk, BIO *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline BIO *sk_BIO_pop(struct stack_st_BIO *sk) { return (BIO *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline BIO *sk_BIO_shift(struct stack_st_BIO *sk) { return (BIO *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_BIO_pop_free(struct stack_st_BIO *sk, sk_BIO_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_BIO_insert(struct stack_st_BIO *sk, BIO *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline BIO *sk_BIO_set(struct stack_st_BIO *sk, int idx, BIO *ptr) { return (BIO *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_BIO_find(struct stack_st_BIO *sk, BIO *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_BIO_find_ex(struct stack_st_BIO *sk, BIO *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_BIO_sort(struct stack_st_BIO *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_BIO_is_sorted(const struct stack_st_BIO *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_BIO * sk_BIO_dup(const struct stack_st_BIO *sk) { return (struct stack_st_BIO *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_BIO *sk_BIO_deep_copy(const struct stack_st_BIO *sk, sk_BIO_copyfunc copyfunc, sk_BIO_freefunc freefunc) { return (struct stack_st_BIO *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_BIO_compfunc sk_BIO_set_cmp_func(struct stack_st_BIO *sk, sk_BIO_compfunc compare) { return (sk_BIO_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
typedef int asn1_ps_func (BIO *b, unsigned char **pbuf, int *plen,
                          void *parg);
enum {
	BIO_C_SET_CONNECT    = 100,
	BIO_C_DO_STATE_MACHINE = 101,
	BIO_C_SET_NBIO       = 102,
	BIO_C_SET_FD         = 104,
	BIO_C_GET_FD         = 105,
	BIO_C_SET_FILE_PTR   = 106,
	BIO_C_GET_FILE_PTR   = 107,
	BIO_C_SET_FILENAME   = 108,
	BIO_C_SET_SSL        = 109,
	BIO_C_GET_SSL        = 110,
	BIO_C_SET_MD         = 111,
	BIO_C_GET_MD         = 112,
	BIO_C_GET_CIPHER_STATUS = 113,
	BIO_C_SET_BUF_MEM    = 114,
	BIO_C_GET_BUF_MEM_PTR = 115,
	BIO_C_GET_BUFF_NUM_LINES = 116,
	BIO_C_SET_BUFF_SIZE  = 117,
	BIO_C_SET_ACCEPT     = 118,
	BIO_C_SSL_MODE       = 119,
	BIO_C_GET_MD_CTX     = 120,
	BIO_C_SET_BUFF_READ_DATA = 122,
	BIO_C_GET_CONNECT    = 123,
	BIO_C_GET_ACCEPT     = 124,
	BIO_C_SET_SSL_RENEGOTIATE_BYTES = 125,
	BIO_C_GET_SSL_NUM_RENEGOTIATES = 126,
	BIO_C_SET_SSL_RENEGOTIATE_TIMEOUT = 127,
	BIO_C_FILE_SEEK      = 128,
	BIO_C_GET_CIPHER_CTX = 129,
	BIO_C_SET_BUF_MEM_EOF_RETURN = 130,
	BIO_C_SET_BIND_MODE  = 131,
	BIO_C_GET_BIND_MODE  = 132,
	BIO_C_FILE_TELL      = 133,
	BIO_C_GET_SOCKS      = 134,
	BIO_C_SET_SOCKS      = 135,
	BIO_C_SET_WRITE_BUF_SIZE = 136,
	BIO_C_GET_WRITE_BUF_SIZE = 137,
	BIO_C_MAKE_BIO_PAIR  = 138,
	BIO_C_DESTROY_BIO_PAIR = 139,
	BIO_C_GET_WRITE_GUARANTEE = 140,
	BIO_C_GET_READ_REQUEST = 141,
	BIO_C_SHUTDOWN_WR    = 142,
	BIO_C_NREAD0         = 143,
	BIO_C_NREAD          = 144,
	BIO_C_NWRITE0        = 145,
	BIO_C_NWRITE         = 146,
	BIO_C_RESET_READ_REQUEST = 147,
	BIO_C_SET_MD_CTX     = 148,
	BIO_C_SET_PREFIX     = 149,
	BIO_C_GET_PREFIX     = 150,
	BIO_C_SET_SUFFIX     = 151,
	BIO_C_GET_SUFFIX     = 152,
	BIO_C_SET_EX_ARG     = 153,
	BIO_C_GET_EX_ARG     = 154,
	BIO_C_SET_CONNECT_MODE = 155,
};
#define BIO_set_app_data(s,arg) BIO_set_ex_data(s,0,arg)
#define BIO_get_app_data(s) BIO_get_ex_data(s,0)
#define BIO_set_nbio(b,n) BIO_ctrl(b,BIO_C_SET_NBIO,(n),NULL)
enum {
	BIO_FAMILY_IPV4      = 4,
	BIO_FAMILY_IPV6      = 6,
	BIO_FAMILY_IPANY     = 256,
};
#define BIO_set_conn_hostname(b,name) BIO_ctrl(b,BIO_C_SET_CONNECT,0, (char *)(name))
#define BIO_set_conn_port(b,port) BIO_ctrl(b,BIO_C_SET_CONNECT,1, (char *)(port))
#define BIO_set_conn_address(b,addr) BIO_ctrl(b,BIO_C_SET_CONNECT,2, (char *)(addr))
#define BIO_set_conn_ip_family(b,f) BIO_int_ctrl(b,BIO_C_SET_CONNECT,3,f)
#define BIO_get_conn_hostname(b) ((const char *)BIO_ptr_ctrl(b,BIO_C_GET_CONNECT,0))
#define BIO_get_conn_port(b) ((const char *)BIO_ptr_ctrl(b,BIO_C_GET_CONNECT,1))
#define BIO_get_conn_address(b) ((const BIO_ADDR *)BIO_ptr_ctrl(b,BIO_C_GET_CONNECT,2))
#define BIO_get_conn_ip_family(b) BIO_ctrl(b,BIO_C_GET_CONNECT,3,NULL)
#define BIO_set_conn_mode(b,n) BIO_ctrl(b,BIO_C_SET_CONNECT_MODE,(n),NULL)
#define BIO_set_accept_name(b,name) BIO_ctrl(b,BIO_C_SET_ACCEPT,0, (char *)(name))
#define BIO_set_accept_port(b,port) BIO_ctrl(b,BIO_C_SET_ACCEPT,1, (char *)(port))
#define BIO_get_accept_name(b) ((const char *)BIO_ptr_ctrl(b,BIO_C_GET_ACCEPT,0))
#define BIO_get_accept_port(b) ((const char *)BIO_ptr_ctrl(b,BIO_C_GET_ACCEPT,1))
#define BIO_get_peer_name(b) ((const char *)BIO_ptr_ctrl(b,BIO_C_GET_ACCEPT,2))
#define BIO_get_peer_port(b) ((const char *)BIO_ptr_ctrl(b,BIO_C_GET_ACCEPT,3))
#define BIO_set_nbio_accept(b,n) BIO_ctrl(b,BIO_C_SET_ACCEPT,2,(n)?(void *)"a":NULL)
#define BIO_set_accept_bios(b,bio) BIO_ctrl(b,BIO_C_SET_ACCEPT,3, (char *)(bio))
#define BIO_set_accept_ip_family(b,f) BIO_int_ctrl(b,BIO_C_SET_ACCEPT,4,f)
#define BIO_get_accept_ip_family(b) BIO_ctrl(b,BIO_C_GET_ACCEPT,4,NULL)
enum {
	BIO_BIND_NORMAL      = 0,
	BIO_BIND_REUSEADDR   = BIO_SOCK_REUSEADDR,
	BIO_BIND_REUSEADDR_IF_UNUSED = BIO_SOCK_REUSEADDR,
};
#define BIO_set_bind_mode(b,mode) BIO_ctrl(b,BIO_C_SET_BIND_MODE,mode,NULL)
#define BIO_get_bind_mode(b) BIO_ctrl(b,BIO_C_GET_BIND_MODE,0,NULL)
#define BIO_do_connect(b) BIO_do_handshake(b)
#define BIO_do_accept(b) BIO_do_handshake(b)
#define BIO_do_handshake(b) BIO_ctrl(b,BIO_C_DO_STATE_MACHINE,0,NULL)
#define BIO_set_fd(b,fd,c) BIO_int_ctrl(b,BIO_C_SET_FD,c,fd)
#define BIO_get_fd(b,c) BIO_ctrl(b,BIO_C_GET_FD,0,(char *)(c))
#define BIO_set_fp(b,fp,c) BIO_ctrl(b,BIO_C_SET_FILE_PTR,c,(char *)(fp))
#define BIO_get_fp(b,fpp) BIO_ctrl(b,BIO_C_GET_FILE_PTR,0,(char *)(fpp))
#define BIO_seek(b,ofs) (int)BIO_ctrl(b,BIO_C_FILE_SEEK,ofs,NULL)
#define BIO_tell(b) (int)BIO_ctrl(b,BIO_C_FILE_TELL,0,NULL)
#define BIO_read_filename(b,name) (int)BIO_ctrl(b,BIO_C_SET_FILENAME, BIO_CLOSE|BIO_FP_READ,(char *)(name))
#define BIO_write_filename(b,name) (int)BIO_ctrl(b,BIO_C_SET_FILENAME, BIO_CLOSE|BIO_FP_WRITE,name)
#define BIO_append_filename(b,name) (int)BIO_ctrl(b,BIO_C_SET_FILENAME, BIO_CLOSE|BIO_FP_APPEND,name)
#define BIO_rw_filename(b,name) (int)BIO_ctrl(b,BIO_C_SET_FILENAME, BIO_CLOSE|BIO_FP_READ|BIO_FP_WRITE,name)
#define BIO_set_ssl(b,ssl,c) BIO_ctrl(b,BIO_C_SET_SSL,c,(char *)(ssl))
#define BIO_get_ssl(b,sslp) BIO_ctrl(b,BIO_C_GET_SSL,0,(char *)(sslp))
#define BIO_set_ssl_mode(b,client) BIO_ctrl(b,BIO_C_SSL_MODE,client,NULL)
#define BIO_set_ssl_renegotiate_bytes(b,num) BIO_ctrl(b,BIO_C_SET_SSL_RENEGOTIATE_BYTES,num,NULL)
#define BIO_get_num_renegotiates(b) BIO_ctrl(b,BIO_C_GET_SSL_NUM_RENEGOTIATES,0,NULL)
#define BIO_set_ssl_renegotiate_timeout(b,seconds) BIO_ctrl(b,BIO_C_SET_SSL_RENEGOTIATE_TIMEOUT,seconds,NULL)
#define BIO_get_mem_data(b,pp) BIO_ctrl(b,BIO_CTRL_INFO,0,(char *)(pp))
#define BIO_set_mem_buf(b,bm,c) BIO_ctrl(b,BIO_C_SET_BUF_MEM,c,(char *)(bm))
#define BIO_get_mem_ptr(b,pp) BIO_ctrl(b,BIO_C_GET_BUF_MEM_PTR,0, (char *)(pp))
#define BIO_set_mem_eof_return(b,v) BIO_ctrl(b,BIO_C_SET_BUF_MEM_EOF_RETURN,v,NULL)
#define BIO_get_buffer_num_lines(b) BIO_ctrl(b,BIO_C_GET_BUFF_NUM_LINES,0,NULL)
#define BIO_set_buffer_size(b,size) BIO_ctrl(b,BIO_C_SET_BUFF_SIZE,size,NULL)
#define BIO_set_read_buffer_size(b,size) BIO_int_ctrl(b,BIO_C_SET_BUFF_SIZE,size,0)
#define BIO_set_write_buffer_size(b,size) BIO_int_ctrl(b,BIO_C_SET_BUFF_SIZE,size,1)
#define BIO_set_buffer_read_data(b,buf,num) BIO_ctrl(b,BIO_C_SET_BUFF_READ_DATA,num,buf)
#define BIO_dup_state(b,ret) BIO_ctrl(b,BIO_CTRL_DUP,0,(char *)(ret))
#define BIO_reset(b) (int)BIO_ctrl(b,BIO_CTRL_RESET,0,NULL)
#define BIO_eof(b) (int)BIO_ctrl(b,BIO_CTRL_EOF,0,NULL)
#define BIO_set_close(b,c) (int)BIO_ctrl(b,BIO_CTRL_SET_CLOSE,(c),NULL)
#define BIO_get_close(b) (int)BIO_ctrl(b,BIO_CTRL_GET_CLOSE,0,NULL)
#define BIO_pending(b) (int)BIO_ctrl(b,BIO_CTRL_PENDING,0,NULL)
#define BIO_wpending(b) (int)BIO_ctrl(b,BIO_CTRL_WPENDING,0,NULL)
size_t BIO_ctrl_pending(BIO *b);
size_t BIO_ctrl_wpending(BIO *b);
#define BIO_flush(b) (int)BIO_ctrl(b,BIO_CTRL_FLUSH,0,NULL)
#define BIO_get_info_callback(b,cbp) (int)BIO_ctrl(b,BIO_CTRL_GET_CALLBACK,0, cbp)
#define BIO_set_info_callback(b,cb) (int)BIO_callback_ctrl(b,BIO_CTRL_SET_CALLBACK,cb)
#define BIO_buffer_get_num_lines(b) BIO_ctrl(b,BIO_CTRL_GET,0,NULL)
#define BIO_buffer_peek(b,s,l) BIO_ctrl(b,BIO_CTRL_PEEK,(l),(s))
#define BIO_set_write_buf_size(b,size) (int)BIO_ctrl(b,BIO_C_SET_WRITE_BUF_SIZE,size,NULL)
#define BIO_get_write_buf_size(b,size) (size_t)BIO_ctrl(b,BIO_C_GET_WRITE_BUF_SIZE,size,NULL)
#define BIO_make_bio_pair(b1,b2) (int)BIO_ctrl(b1,BIO_C_MAKE_BIO_PAIR,0,b2)
#define BIO_destroy_bio_pair(b) (int)BIO_ctrl(b,BIO_C_DESTROY_BIO_PAIR,0,NULL)
#define BIO_shutdown_wr(b) (int)BIO_ctrl(b, BIO_C_SHUTDOWN_WR, 0, NULL)
#define BIO_get_write_guarantee(b) (int)BIO_ctrl(b,BIO_C_GET_WRITE_GUARANTEE,0,NULL)
#define BIO_get_read_request(b) (int)BIO_ctrl(b,BIO_C_GET_READ_REQUEST,0,NULL)
size_t BIO_ctrl_get_write_guarantee(BIO *b);
size_t BIO_ctrl_get_read_request(BIO *b);
int BIO_ctrl_reset_read_request(BIO *b);
#define BIO_ctrl_dgram_connect(b,peer) (int)BIO_ctrl(b,BIO_CTRL_DGRAM_CONNECT,0, (char *)(peer))
#define BIO_ctrl_set_connected(b,peer) (int)BIO_ctrl(b, BIO_CTRL_DGRAM_SET_CONNECTED, 0, (char *)(peer))
#define BIO_dgram_recv_timedout(b) (int)BIO_ctrl(b, BIO_CTRL_DGRAM_GET_RECV_TIMER_EXP, 0, NULL)
#define BIO_dgram_send_timedout(b) (int)BIO_ctrl(b, BIO_CTRL_DGRAM_GET_SEND_TIMER_EXP, 0, NULL)
#define BIO_dgram_get_peer(b,peer) (int)BIO_ctrl(b, BIO_CTRL_DGRAM_GET_PEER, 0, (char *)(peer))
#define BIO_dgram_set_peer(b,peer) (int)BIO_ctrl(b, BIO_CTRL_DGRAM_SET_PEER, 0, (char *)(peer))
#define BIO_dgram_get_mtu_overhead(b) (unsigned int)BIO_ctrl((b), BIO_CTRL_DGRAM_GET_MTU_OVERHEAD, 0, NULL)
#define BIO_get_ex_new_index(l,p,newf,dupf,freef) CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_BIO, l, p, newf, dupf, freef)
int BIO_set_ex_data(BIO *bio, int idx, void *data);
void *BIO_get_ex_data(BIO *bio, int idx);
uint64_t BIO_number_read(BIO *bio);
uint64_t BIO_number_written(BIO *bio);
int BIO_asn1_set_prefix(BIO *b, asn1_ps_func *prefix,
                        asn1_ps_func *prefix_free);
int BIO_asn1_get_prefix(BIO *b, asn1_ps_func **pprefix,
                        asn1_ps_func **pprefix_free);
int BIO_asn1_set_suffix(BIO *b, asn1_ps_func *suffix,
                        asn1_ps_func *suffix_free);
int BIO_asn1_get_suffix(BIO *b, asn1_ps_func **psuffix,
                        asn1_ps_func **psuffix_free);
const BIO_METHOD *BIO_s_file(void);
BIO *BIO_new_file(const char *filename, const char *mode);
BIO *BIO_new_fp(FILE *stream, int close_flag);
BIO *BIO_new(const BIO_METHOD *type);
int BIO_free(BIO *a);
void BIO_set_data(BIO *a, void *ptr);
void *BIO_get_data(BIO *a);
void BIO_set_init(BIO *a, int init);
int BIO_get_init(BIO *a);
void BIO_set_shutdown(BIO *a, int shut);
int BIO_get_shutdown(BIO *a);
void BIO_vfree(BIO *a);
int BIO_up_ref(BIO *a);
int BIO_read(BIO *b, void *data, int dlen);
int BIO_read_ex(BIO *b, void *data, size_t dlen, size_t *readbytes);
int BIO_gets(BIO *bp, char *buf, int size);
int BIO_write(BIO *b, const void *data, int dlen);
int BIO_write_ex(BIO *b, const void *data, size_t dlen, size_t *written);
int BIO_puts(BIO *bp, const char *buf);
int BIO_indent(BIO *b, int indent, int max);
long BIO_ctrl(BIO *bp, int cmd, long larg, void *parg);
long BIO_callback_ctrl(BIO *b, int cmd, BIO_info_cb *fp);
void *BIO_ptr_ctrl(BIO *bp, int cmd, long larg);
long BIO_int_ctrl(BIO *bp, int cmd, long larg, int iarg);
BIO *BIO_push(BIO *b, BIO *append);
BIO *BIO_pop(BIO *b);
void BIO_free_all(BIO *a);
BIO *BIO_find_type(BIO *b, int bio_type);
BIO *BIO_next(BIO *b);
void BIO_set_next(BIO *b, BIO *next);
BIO *BIO_get_retry_BIO(BIO *bio, int *reason);
int BIO_get_retry_reason(BIO *bio);
void BIO_set_retry_reason(BIO *bio, int reason);
BIO *BIO_dup_chain(BIO *in);
int BIO_nread0(BIO *bio, char **buf);
int BIO_nread(BIO *bio, char **buf, int num);
int BIO_nwrite0(BIO *bio, char **buf);
int BIO_nwrite(BIO *bio, char **buf, int num);
long BIO_debug_callback(BIO *bio, int cmd, const char *argp, int argi,
                        long argl, long ret);
const BIO_METHOD *BIO_s_mem(void);
const BIO_METHOD *BIO_s_secmem(void);
BIO *BIO_new_mem_buf(const void *buf, int len);
const BIO_METHOD *BIO_s_socket(void);
const BIO_METHOD *BIO_s_connect(void);
const BIO_METHOD *BIO_s_accept(void);
const BIO_METHOD *BIO_s_fd(void);
const BIO_METHOD *BIO_s_log(void);
const BIO_METHOD *BIO_s_bio(void);
const BIO_METHOD *BIO_s_null(void);
const BIO_METHOD *BIO_f_null(void);
const BIO_METHOD *BIO_f_buffer(void);
const BIO_METHOD *BIO_f_linebuffer(void);
const BIO_METHOD *BIO_f_nbio_test(void);
const BIO_METHOD *BIO_s_datagram(void);
int BIO_dgram_non_fatal_error(int error);
BIO *BIO_new_dgram(int fd, int close_flag);
int BIO_sock_should_retry(int i);
int BIO_sock_non_fatal_error(int error);
int BIO_fd_should_retry(int i);
int BIO_fd_non_fatal_error(int error);
int BIO_dump_cb(int (*cb) (const void *data, size_t len, void *u),
                void *u, const char *s, int len);
int BIO_dump_indent_cb(int (*cb) (const void *data, size_t len, void *u),
                       void *u, const char *s, int len, int indent);
int BIO_dump(BIO *b, const char *bytes, int len);
int BIO_dump_indent(BIO *b, const char *bytes, int len, int indent);
int BIO_dump_fp(FILE *fp, const char *s, int len);
int BIO_dump_indent_fp(FILE *fp, const char *s, int len, int indent);
int BIO_hex_string(BIO *out, int indent, int width, unsigned char *data,
                   int datalen);
BIO_ADDR *BIO_ADDR_new(void);
int BIO_ADDR_rawmake(BIO_ADDR *ap, int family,
                     const void *where, size_t wherelen, unsigned short port);
void BIO_ADDR_free(BIO_ADDR *);
void BIO_ADDR_clear(BIO_ADDR *ap);
int BIO_ADDR_family(const BIO_ADDR *ap);
int BIO_ADDR_rawaddress(const BIO_ADDR *ap, void *p, size_t *l);
unsigned short BIO_ADDR_rawport(const BIO_ADDR *ap);
char *BIO_ADDR_hostname_string(const BIO_ADDR *ap, int numeric);
char *BIO_ADDR_service_string(const BIO_ADDR *ap, int numeric);
char *BIO_ADDR_path_string(const BIO_ADDR *ap);
const BIO_ADDRINFO *BIO_ADDRINFO_next(const BIO_ADDRINFO *bai);
int BIO_ADDRINFO_family(const BIO_ADDRINFO *bai);
int BIO_ADDRINFO_socktype(const BIO_ADDRINFO *bai);
int BIO_ADDRINFO_protocol(const BIO_ADDRINFO *bai);
const BIO_ADDR *BIO_ADDRINFO_address(const BIO_ADDRINFO *bai);
void BIO_ADDRINFO_free(BIO_ADDRINFO *bai);
enum BIO_hostserv_priorities {
    BIO_PARSE_PRIO_HOST, BIO_PARSE_PRIO_SERV
};
int BIO_parse_hostserv(const char *hostserv, char **host, char **service,
                       enum BIO_hostserv_priorities hostserv_prio);
enum BIO_lookup_type {
    BIO_LOOKUP_CLIENT, BIO_LOOKUP_SERVER
};
int BIO_lookup(const char *host, const char *service,
               enum BIO_lookup_type lookup_type,
               int family, int socktype, BIO_ADDRINFO **res);
int BIO_lookup_ex(const char *host, const char *service,
                  int lookup_type, int family, int socktype, int protocol,
                  BIO_ADDRINFO **res);
int BIO_sock_error(int sock);
int BIO_socket_ioctl(int fd, long type, void *arg);
int BIO_socket_nbio(int fd, int mode);
int BIO_sock_init(void);
#define BIO_sock_cleanup() while(0) continue
int BIO_set_tcp_ndelay(int sock, int turn_on);
struct hostent *BIO_gethostbyname(const char *name) __attribute__ ((deprecated));
int BIO_get_port(const char *str, unsigned short *port_ptr) __attribute__ ((deprecated));
int BIO_get_host_ip(const char *str, unsigned char *ip) __attribute__ ((deprecated));
int BIO_get_accept_socket(char *host_port, int mode) __attribute__ ((deprecated));
int BIO_accept(int sock, char **ip_port) __attribute__ ((deprecated));
union BIO_sock_info_u {
    BIO_ADDR *addr;
};
enum BIO_sock_info_type {
    BIO_SOCK_INFO_ADDRESS
};
int BIO_sock_info(int sock,
                  enum BIO_sock_info_type type, union BIO_sock_info_u *info);
enum {
	BIO_SOCK_REUSEADDR   = 0x01,
	BIO_SOCK_V6_ONLY     = 0x02,
	BIO_SOCK_KEEPALIVE   = 0x04,
	BIO_SOCK_NONBLOCK    = 0x08,
	BIO_SOCK_NODELAY     = 0x10,
};
int BIO_socket(int domain, int socktype, int protocol, int options);
int BIO_connect(int sock, const BIO_ADDR *addr, int options);
int BIO_bind(int sock, const BIO_ADDR *addr, int options);
int BIO_listen(int sock, const BIO_ADDR *addr, int options);
int BIO_accept_ex(int accept_sock, BIO_ADDR *addr, int options);
int BIO_closesocket(int sock);
BIO *BIO_new_socket(int sock, int close_flag);
BIO *BIO_new_connect(const char *host_port);
BIO *BIO_new_accept(const char *host_port);
BIO *BIO_new_fd(int fd, int close_flag);
int BIO_new_bio_pair(BIO **bio1, size_t writebuf1,
                     BIO **bio2, size_t writebuf2);
void BIO_copy_next_retry(BIO *b);
#define ossl_bio__attr__(x)
enum {
	ossl_bio__attr__     = __attribute__,
	ossl_bio__printf__   = __gnu_printf__,
};
int BIO_printf(BIO *bio, const char *format, ...)
__attribute__((__format__(__gnu_printf__, 2, 3)));
int BIO_vprintf(BIO *bio, const char *format, va_list args)
__attribute__((__format__(__gnu_printf__, 2, 0)));
int BIO_snprintf(char *buf, size_t n, const char *format, ...)
__attribute__((__format__(__gnu_printf__, 3, 4)));
int BIO_vsnprintf(char *buf, size_t n, const char *format, va_list args)
__attribute__((__format__(__gnu_printf__, 3, 0)));
BIO_METHOD *BIO_meth_new(int type, const char *name);
void BIO_meth_free(BIO_METHOD *biom);
int (*BIO_meth_get_write(const BIO_METHOD *biom)) (BIO *, const char *, int);
int (*BIO_meth_get_write_ex(const BIO_METHOD *biom)) (BIO *, const char *, size_t,
                                                size_t *);
int BIO_meth_set_write(BIO_METHOD *biom,
                       int (*write) (BIO *, const char *, int));
int BIO_meth_set_write_ex(BIO_METHOD *biom,
                       int (*bwrite) (BIO *, const char *, size_t, size_t *));
int (*BIO_meth_get_read(const BIO_METHOD *biom)) (BIO *, char *, int);
int (*BIO_meth_get_read_ex(const BIO_METHOD *biom)) (BIO *, char *, size_t, size_t *);
int BIO_meth_set_read(BIO_METHOD *biom,
                      int (*read) (BIO *, char *, int));
int BIO_meth_set_read_ex(BIO_METHOD *biom,
                         int (*bread) (BIO *, char *, size_t, size_t *));
int (*BIO_meth_get_puts(const BIO_METHOD *biom)) (BIO *, const char *);
int BIO_meth_set_puts(BIO_METHOD *biom,
                      int (*puts) (BIO *, const char *));
int (*BIO_meth_get_gets(const BIO_METHOD *biom)) (BIO *, char *, int);
int BIO_meth_set_gets(BIO_METHOD *biom,
                      int (*gets) (BIO *, char *, int));
long (*BIO_meth_get_ctrl(const BIO_METHOD *biom)) (BIO *, int, long, void *);
int BIO_meth_set_ctrl(BIO_METHOD *biom,
                      long (*ctrl) (BIO *, int, long, void *));
int (*BIO_meth_get_create(const BIO_METHOD *bion)) (BIO *);
int BIO_meth_set_create(BIO_METHOD *biom, int (*create) (BIO *));
int (*BIO_meth_get_destroy(const BIO_METHOD *biom)) (BIO *);
int BIO_meth_set_destroy(BIO_METHOD *biom, int (*destroy) (BIO *));
long (*BIO_meth_get_callback_ctrl(const BIO_METHOD *biom))
                                 (BIO *, int, BIO_info_cb *);
int BIO_meth_set_callback_ctrl(BIO_METHOD *biom,
                               long (*callback_ctrl) (BIO *, int,
                                                      BIO_info_cb *));

// X:/tools/mingw64/x86_64-w64-mingw32/include/stdarg.h
#define va_start(v,l) __builtin_va_start(v,l)
#define va_end(v) __builtin_va_end(v)
#define va_arg(v,l) __builtin_va_arg(v,l)
#define va_copy(d,s) __builtin_va_copy(d,s)
#define __va_copy(d,s) __builtin_va_copy(d,s)

// X:/tools/mingw64/x86_64-w64-mingw32/include/_mingw_stdarg.h

// csrc/openssl/src/include/openssl/bioerr.h
int ERR_load_BIO_strings(void);
enum {
	BIO_F_ACPT_STATE     = 100,
	BIO_F_ADDRINFO_WRAP  = 148,
	BIO_F_ADDR_STRINGS   = 134,
	BIO_F_BIO_ACCEPT     = 101,
	BIO_F_BIO_ACCEPT_EX  = 137,
	BIO_F_BIO_ACCEPT_NEW = 152,
	BIO_F_BIO_ADDR_NEW   = 144,
	BIO_F_BIO_BIND       = 147,
	BIO_F_BIO_CALLBACK_CTRL = 131,
	BIO_F_BIO_CONNECT    = 138,
	BIO_F_BIO_CONNECT_NEW = 153,
	BIO_F_BIO_CTRL       = 103,
	BIO_F_BIO_GETS       = 104,
	BIO_F_BIO_GET_HOST_IP = 106,
	BIO_F_BIO_GET_NEW_INDEX = 102,
	BIO_F_BIO_GET_PORT   = 107,
	BIO_F_BIO_LISTEN     = 139,
	BIO_F_BIO_LOOKUP     = 135,
	BIO_F_BIO_LOOKUP_EX  = 143,
	BIO_F_BIO_MAKE_PAIR  = 121,
	BIO_F_BIO_METH_NEW   = 146,
	BIO_F_BIO_NEW        = 108,
	BIO_F_BIO_NEW_DGRAM_SCTP = 145,
	BIO_F_BIO_NEW_FILE   = 109,
	BIO_F_BIO_NEW_MEM_BUF = 126,
	BIO_F_BIO_NREAD      = 123,
	BIO_F_BIO_NREAD0     = 124,
	BIO_F_BIO_NWRITE     = 125,
	BIO_F_BIO_NWRITE0    = 122,
	BIO_F_BIO_PARSE_HOSTSERV = 136,
	BIO_F_BIO_PUTS       = 110,
	BIO_F_BIO_READ       = 111,
	BIO_F_BIO_READ_EX    = 105,
	BIO_F_BIO_READ_INTERN = 120,
	BIO_F_BIO_SOCKET     = 140,
	BIO_F_BIO_SOCKET_NBIO = 142,
	BIO_F_BIO_SOCK_INFO  = 141,
	BIO_F_BIO_SOCK_INIT  = 112,
	BIO_F_BIO_WRITE      = 113,
	BIO_F_BIO_WRITE_EX   = 119,
	BIO_F_BIO_WRITE_INTERN = 128,
	BIO_F_BUFFER_CTRL    = 114,
	BIO_F_CONN_CTRL      = 127,
	BIO_F_CONN_STATE     = 115,
	BIO_F_DGRAM_SCTP_NEW = 149,
	BIO_F_DGRAM_SCTP_READ = 132,
	BIO_F_DGRAM_SCTP_WRITE = 133,
	BIO_F_DOAPR_OUTCH    = 150,
	BIO_F_FILE_CTRL      = 116,
	BIO_F_FILE_READ      = 130,
	BIO_F_LINEBUFFER_CTRL = 129,
	BIO_F_LINEBUFFER_NEW = 151,
	BIO_F_MEM_WRITE      = 117,
	BIO_F_NBIOF_NEW      = 154,
	BIO_F_SLG_WRITE      = 155,
	BIO_F_SSL_NEW        = 118,
	BIO_R_ACCEPT_ERROR   = 100,
	BIO_R_ADDRINFO_ADDR_IS_NOT_AF_INET = 141,
	BIO_R_AMBIGUOUS_HOST_OR_SERVICE = 129,
	BIO_R_BAD_FOPEN_MODE = 101,
	BIO_R_BROKEN_PIPE    = 124,
	BIO_R_CONNECT_ERROR  = 103,
	BIO_R_GETHOSTBYNAME_ADDR_IS_NOT_AF_INET = 107,
	BIO_R_GETSOCKNAME_ERROR = 132,
	BIO_R_GETSOCKNAME_TRUNCATED_ADDRESS = 133,
	BIO_R_GETTING_SOCKTYPE = 134,
	BIO_R_INVALID_ARGUMENT = 125,
	BIO_R_INVALID_SOCKET = 135,
	BIO_R_IN_USE         = 123,
	BIO_R_LENGTH_TOO_LONG = 102,
	BIO_R_LISTEN_V6_ONLY = 136,
	BIO_R_LOOKUP_RETURNED_NOTHING = 142,
	BIO_R_MALFORMED_HOST_OR_SERVICE = 130,
	BIO_R_NBIO_CONNECT_ERROR = 110,
	BIO_R_NO_ACCEPT_ADDR_OR_SERVICE_SPECIFIED = 143,
	BIO_R_NO_HOSTNAME_OR_SERVICE_SPECIFIED = 144,
	BIO_R_NO_PORT_DEFINED = 113,
	BIO_R_NO_SUCH_FILE   = 128,
	BIO_R_NULL_PARAMETER = 115,
	BIO_R_UNABLE_TO_BIND_SOCKET = 117,
	BIO_R_UNABLE_TO_CREATE_SOCKET = 118,
	BIO_R_UNABLE_TO_KEEPALIVE = 137,
	BIO_R_UNABLE_TO_LISTEN_SOCKET = 119,
	BIO_R_UNABLE_TO_NODELAY = 138,
	BIO_R_UNABLE_TO_REUSEADDR = 139,
	BIO_R_UNAVAILABLE_IP_FAMILY = 145,
	BIO_R_UNINITIALIZED  = 120,
	BIO_R_UNKNOWN_INFO_TYPE = 140,
	BIO_R_UNSUPPORTED_IP_FAMILY = 146,
	BIO_R_UNSUPPORTED_METHOD = 121,
	BIO_R_UNSUPPORTED_PROTOCOL_FAMILY = 131,
	BIO_R_WRITE_TO_READ_ONLY_BIO = 126,
	BIO_R_WSASTARTUP     = 122,
};


