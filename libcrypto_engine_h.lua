local ffi = require'ffi' --engine.h, engineerr.h
require'libcrypto_types_h'
ffi.cdef[[
// engine.h
enum {
	ENGINE_METHOD_RSA    = (unsigned int)0x0001,
	ENGINE_METHOD_DSA    = (unsigned int)0x0002,
	ENGINE_METHOD_DH     = (unsigned int)0x0004,
	ENGINE_METHOD_RAND   = (unsigned int)0x0008,
	ENGINE_METHOD_CIPHERS = (unsigned int)0x0040,
	ENGINE_METHOD_DIGESTS = (unsigned int)0x0080,
	ENGINE_METHOD_PKEY_METHS = (unsigned int)0x0200,
	ENGINE_METHOD_PKEY_ASN1_METHS = (unsigned int)0x0400,
	ENGINE_METHOD_EC     = (unsigned int)0x0800,
	ENGINE_METHOD_ALL    = (unsigned int)0xFFFF,
	ENGINE_METHOD_NONE   = (unsigned int)0x0000,
	ENGINE_TABLE_FLAG_NOINIT = (unsigned int)0x0001,
	ENGINE_FLAGS_MANUAL_CMD_CTRL = (int)0x0002,
	ENGINE_FLAGS_BY_ID_COPY = (int)0x0004,
	ENGINE_FLAGS_NO_REGISTER_ALL = (int)0x0008,
	ENGINE_CMD_FLAG_NUMERIC = (unsigned int)0x0001,
	ENGINE_CMD_FLAG_STRING = (unsigned int)0x0002,
	ENGINE_CMD_FLAG_NO_INPUT = (unsigned int)0x0004,
	ENGINE_CMD_FLAG_INTERNAL = (unsigned int)0x0008,
	ENGINE_CTRL_SET_LOGSTREAM = 1,
	ENGINE_CTRL_SET_PASSWORD_CALLBACK = 2,
	ENGINE_CTRL_HUP      = 3,
	ENGINE_CTRL_SET_USER_INTERFACE = 4,
	ENGINE_CTRL_SET_CALLBACK_DATA = 5,
	ENGINE_CTRL_LOAD_CONFIGURATION = 6,
	ENGINE_CTRL_LOAD_SECTION = 7,
	ENGINE_CTRL_HAS_CTRL_FUNCTION = 10,
	ENGINE_CTRL_GET_FIRST_CMD_TYPE = 11,
	ENGINE_CTRL_GET_NEXT_CMD_TYPE = 12,
	ENGINE_CTRL_GET_CMD_FROM_NAME = 13,
	ENGINE_CTRL_GET_NAME_LEN_FROM_CMD = 14,
	ENGINE_CTRL_GET_NAME_FROM_CMD = 15,
	ENGINE_CTRL_GET_DESC_LEN_FROM_CMD = 16,
	ENGINE_CTRL_GET_DESC_FROM_CMD = 17,
	ENGINE_CTRL_GET_CMD_FLAGS = 18,
	ENGINE_CMD_BASE      = 200,
	ENGINE_CTRL_CHIL_SET_FORKCHECK = 100,
	ENGINE_CTRL_CHIL_NO_LOCKING = 101,
};
typedef struct ENGINE_CMD_DEFN_st {
    unsigned int cmd_num;
    const char *cmd_name;
    const char *cmd_desc;
    unsigned int cmd_flags;
} ENGINE_CMD_DEFN;
typedef int (*ENGINE_GEN_FUNC_PTR) (void);
typedef int (*ENGINE_GEN_INT_FUNC_PTR) (ENGINE *);
typedef int (*ENGINE_CTRL_FUNC_PTR) (ENGINE *, int, long, void *,
                                     void (*f) (void));
typedef EVP_PKEY *(*ENGINE_LOAD_KEY_PTR)(ENGINE *, const char *,
                                         UI_METHOD *ui_method,
                                         void *callback_data);
typedef int (*ENGINE_SSL_CLIENT_CERT_PTR) (ENGINE *, SSL *ssl,
                                           struct stack_st_X509_NAME *ca_dn,
                                           X509 **pcert, EVP_PKEY **pkey,
                                           struct stack_st_X509 **pother,
                                           UI_METHOD *ui_method,
                                           void *callback_data);
typedef int (*ENGINE_CIPHERS_PTR) (ENGINE *, const EVP_CIPHER **,
                                   const int **, int);
typedef int (*ENGINE_DIGESTS_PTR) (ENGINE *, const EVP_MD **, const int **,
                                   int);
typedef int (*ENGINE_PKEY_METHS_PTR) (ENGINE *, EVP_PKEY_METHOD **,
                                      const int **, int);
typedef int (*ENGINE_PKEY_ASN1_METHS_PTR) (ENGINE *, EVP_PKEY_ASN1_METHOD **,
                                           const int **, int);
ENGINE *ENGINE_get_first(void);
ENGINE *ENGINE_get_last(void);
ENGINE *ENGINE_get_next(ENGINE *e);
ENGINE *ENGINE_get_prev(ENGINE *e);
int ENGINE_add(ENGINE *e);
int ENGINE_remove(ENGINE *e);
ENGINE *ENGINE_by_id(const char *id);
void ENGINE_load_builtin_engines(void);
unsigned int ENGINE_get_table_flags(void);
void ENGINE_set_table_flags(unsigned int flags);
int ENGINE_register_RSA(ENGINE *e);
void ENGINE_unregister_RSA(ENGINE *e);
void ENGINE_register_all_RSA(void);
int ENGINE_register_DSA(ENGINE *e);
void ENGINE_unregister_DSA(ENGINE *e);
void ENGINE_register_all_DSA(void);
int ENGINE_register_EC(ENGINE *e);
void ENGINE_unregister_EC(ENGINE *e);
void ENGINE_register_all_EC(void);
int ENGINE_register_DH(ENGINE *e);
void ENGINE_unregister_DH(ENGINE *e);
void ENGINE_register_all_DH(void);
int ENGINE_register_RAND(ENGINE *e);
void ENGINE_unregister_RAND(ENGINE *e);
void ENGINE_register_all_RAND(void);
int ENGINE_register_ciphers(ENGINE *e);
void ENGINE_unregister_ciphers(ENGINE *e);
void ENGINE_register_all_ciphers(void);
int ENGINE_register_digests(ENGINE *e);
void ENGINE_unregister_digests(ENGINE *e);
void ENGINE_register_all_digests(void);
int ENGINE_register_pkey_meths(ENGINE *e);
void ENGINE_unregister_pkey_meths(ENGINE *e);
void ENGINE_register_all_pkey_meths(void);
int ENGINE_register_pkey_asn1_meths(ENGINE *e);
void ENGINE_unregister_pkey_asn1_meths(ENGINE *e);
void ENGINE_register_all_pkey_asn1_meths(void);
int ENGINE_register_complete(ENGINE *e);
int ENGINE_register_all_complete(void);
int ENGINE_ctrl(ENGINE *e, int cmd, long i, void *p, void (*f) (void));
int ENGINE_cmd_is_executable(ENGINE *e, int cmd);
int ENGINE_ctrl_cmd(ENGINE *e, const char *cmd_name,
                    long i, void *p, void (*f) (void), int cmd_optional);
int ENGINE_ctrl_cmd_string(ENGINE *e, const char *cmd_name, const char *arg,
                           int cmd_optional);
ENGINE *ENGINE_new(void);
int ENGINE_free(ENGINE *e);
int ENGINE_up_ref(ENGINE *e);
int ENGINE_set_id(ENGINE *e, const char *id);
int ENGINE_set_name(ENGINE *e, const char *name);
int ENGINE_set_RSA(ENGINE *e, const RSA_METHOD *rsa_meth);
int ENGINE_set_DSA(ENGINE *e, const DSA_METHOD *dsa_meth);
int ENGINE_set_EC(ENGINE *e, const EC_KEY_METHOD *ecdsa_meth);
int ENGINE_set_DH(ENGINE *e, const DH_METHOD *dh_meth);
int ENGINE_set_RAND(ENGINE *e, const RAND_METHOD *rand_meth);
int ENGINE_set_destroy_function(ENGINE *e, ENGINE_GEN_INT_FUNC_PTR destroy_f);
int ENGINE_set_init_function(ENGINE *e, ENGINE_GEN_INT_FUNC_PTR init_f);
int ENGINE_set_finish_function(ENGINE *e, ENGINE_GEN_INT_FUNC_PTR finish_f);
int ENGINE_set_ctrl_function(ENGINE *e, ENGINE_CTRL_FUNC_PTR ctrl_f);
int ENGINE_set_load_privkey_function(ENGINE *e,
                                     ENGINE_LOAD_KEY_PTR loadpriv_f);
int ENGINE_set_load_pubkey_function(ENGINE *e, ENGINE_LOAD_KEY_PTR loadpub_f);
int ENGINE_set_load_ssl_client_cert_function(ENGINE *e,
                                             ENGINE_SSL_CLIENT_CERT_PTR
                                             loadssl_f);
int ENGINE_set_ciphers(ENGINE *e, ENGINE_CIPHERS_PTR f);
int ENGINE_set_digests(ENGINE *e, ENGINE_DIGESTS_PTR f);
int ENGINE_set_pkey_meths(ENGINE *e, ENGINE_PKEY_METHS_PTR f);
int ENGINE_set_pkey_asn1_meths(ENGINE *e, ENGINE_PKEY_ASN1_METHS_PTR f);
int ENGINE_set_flags(ENGINE *e, int flags);
int ENGINE_set_cmd_defns(ENGINE *e, const ENGINE_CMD_DEFN *defns);
int ENGINE_set_ex_data(ENGINE *e, int idx, void *arg);
void *ENGINE_get_ex_data(const ENGINE *e, int idx);
const char *ENGINE_get_id(const ENGINE *e);
const char *ENGINE_get_name(const ENGINE *e);
const RSA_METHOD *ENGINE_get_RSA(const ENGINE *e);
const DSA_METHOD *ENGINE_get_DSA(const ENGINE *e);
const EC_KEY_METHOD *ENGINE_get_EC(const ENGINE *e);
const DH_METHOD *ENGINE_get_DH(const ENGINE *e);
const RAND_METHOD *ENGINE_get_RAND(const ENGINE *e);
ENGINE_GEN_INT_FUNC_PTR ENGINE_get_destroy_function(const ENGINE *e);
ENGINE_GEN_INT_FUNC_PTR ENGINE_get_init_function(const ENGINE *e);
ENGINE_GEN_INT_FUNC_PTR ENGINE_get_finish_function(const ENGINE *e);
ENGINE_CTRL_FUNC_PTR ENGINE_get_ctrl_function(const ENGINE *e);
ENGINE_LOAD_KEY_PTR ENGINE_get_load_privkey_function(const ENGINE *e);
ENGINE_LOAD_KEY_PTR ENGINE_get_load_pubkey_function(const ENGINE *e);
ENGINE_SSL_CLIENT_CERT_PTR ENGINE_get_ssl_client_cert_function(const ENGINE
                                                               *e);
ENGINE_CIPHERS_PTR ENGINE_get_ciphers(const ENGINE *e);
ENGINE_DIGESTS_PTR ENGINE_get_digests(const ENGINE *e);
ENGINE_PKEY_METHS_PTR ENGINE_get_pkey_meths(const ENGINE *e);
ENGINE_PKEY_ASN1_METHS_PTR ENGINE_get_pkey_asn1_meths(const ENGINE *e);
const EVP_CIPHER *ENGINE_get_cipher(ENGINE *e, int nid);
const EVP_MD *ENGINE_get_digest(ENGINE *e, int nid);
const EVP_PKEY_METHOD *ENGINE_get_pkey_meth(ENGINE *e, int nid);
const EVP_PKEY_ASN1_METHOD *ENGINE_get_pkey_asn1_meth(ENGINE *e, int nid);
const EVP_PKEY_ASN1_METHOD *ENGINE_get_pkey_asn1_meth_str(ENGINE *e,
                                                          const char *str,
                                                          int len);
const EVP_PKEY_ASN1_METHOD *ENGINE_pkey_asn1_find_str(ENGINE **pe,
                                                      const char *str,
                                                      int len);
const ENGINE_CMD_DEFN *ENGINE_get_cmd_defns(const ENGINE *e);
int ENGINE_get_flags(const ENGINE *e);
int ENGINE_init(ENGINE *e);
int ENGINE_finish(ENGINE *e);
EVP_PKEY *ENGINE_load_private_key(ENGINE *e, const char *key_id,
                                  UI_METHOD *ui_method, void *callback_data);
EVP_PKEY *ENGINE_load_public_key(ENGINE *e, const char *key_id,
                                 UI_METHOD *ui_method, void *callback_data);
int ENGINE_load_ssl_client_cert(ENGINE *e, SSL *s,
                                struct stack_st_X509_NAME *ca_dn, X509 **pcert,
                                EVP_PKEY **ppkey, struct stack_st_X509 **pother,
                                UI_METHOD *ui_method, void *callback_data);
ENGINE *ENGINE_get_default_RSA(void);
ENGINE *ENGINE_get_default_DSA(void);
ENGINE *ENGINE_get_default_EC(void);
ENGINE *ENGINE_get_default_DH(void);
ENGINE *ENGINE_get_default_RAND(void);
ENGINE *ENGINE_get_cipher_engine(int nid);
ENGINE *ENGINE_get_digest_engine(int nid);
ENGINE *ENGINE_get_pkey_meth_engine(int nid);
ENGINE *ENGINE_get_pkey_asn1_meth_engine(int nid);
int ENGINE_set_default_RSA(ENGINE *e);
int ENGINE_set_default_string(ENGINE *e, const char *def_list);
int ENGINE_set_default_DSA(ENGINE *e);
int ENGINE_set_default_EC(ENGINE *e);
int ENGINE_set_default_DH(ENGINE *e);
int ENGINE_set_default_RAND(ENGINE *e);
int ENGINE_set_default_ciphers(ENGINE *e);
int ENGINE_set_default_digests(ENGINE *e);
int ENGINE_set_default_pkey_meths(ENGINE *e);
int ENGINE_set_default_pkey_asn1_meths(ENGINE *e);
int ENGINE_set_default(ENGINE *e, unsigned int flags);
void ENGINE_add_conf_module(void);
enum {
	OSSL_DYNAMIC_VERSION = (unsigned long)0x00030000,
	OSSL_DYNAMIC_OLDEST  = (unsigned long)0x00030000,
};
typedef void *(*dyn_MEM_malloc_fn) (size_t, const char *, int);
typedef void *(*dyn_MEM_realloc_fn) (void *, size_t, const char *, int);
typedef void (*dyn_MEM_free_fn) (void *, const char *, int);
typedef struct st_dynamic_MEM_fns {
    dyn_MEM_malloc_fn malloc_fn;
    dyn_MEM_realloc_fn realloc_fn;
    dyn_MEM_free_fn free_fn;
} dynamic_MEM_fns;
typedef struct st_dynamic_fns {
    void *static_state;
    dynamic_MEM_fns mem_fns;
} dynamic_fns;
typedef unsigned long (*dynamic_v_check_fn) (unsigned long ossl_version);
typedef int (*dynamic_bind_engine) (ENGINE *e, const char *id,
                                    const dynamic_fns *fns);
void *ENGINE_get_static_state(void);

// engineerr.h
int ERR_load_ENGINE_strings(void);
enum {
	ENGINE_F_DIGEST_UPDATE = 198,
	ENGINE_F_DYNAMIC_CTRL = 180,
	ENGINE_F_DYNAMIC_GET_DATA_CTX = 181,
	ENGINE_F_DYNAMIC_LOAD = 182,
	ENGINE_F_DYNAMIC_SET_DATA_CTX = 183,
	ENGINE_F_ENGINE_ADD  = 105,
	ENGINE_F_ENGINE_BY_ID = 106,
	ENGINE_F_ENGINE_CMD_IS_EXECUTABLE = 170,
	ENGINE_F_ENGINE_CTRL = 142,
	ENGINE_F_ENGINE_CTRL_CMD = 178,
	ENGINE_F_ENGINE_CTRL_CMD_STRING = 171,
	ENGINE_F_ENGINE_FINISH = 107,
	ENGINE_F_ENGINE_GET_CIPHER = 185,
	ENGINE_F_ENGINE_GET_DIGEST = 186,
	ENGINE_F_ENGINE_GET_FIRST = 195,
	ENGINE_F_ENGINE_GET_LAST = 196,
	ENGINE_F_ENGINE_GET_NEXT = 115,
	ENGINE_F_ENGINE_GET_PKEY_ASN1_METH = 193,
	ENGINE_F_ENGINE_GET_PKEY_METH = 192,
	ENGINE_F_ENGINE_GET_PREV = 116,
	ENGINE_F_ENGINE_INIT = 119,
	ENGINE_F_ENGINE_LIST_ADD = 120,
	ENGINE_F_ENGINE_LIST_REMOVE = 121,
	ENGINE_F_ENGINE_LOAD_PRIVATE_KEY = 150,
	ENGINE_F_ENGINE_LOAD_PUBLIC_KEY = 151,
	ENGINE_F_ENGINE_LOAD_SSL_CLIENT_CERT = 194,
	ENGINE_F_ENGINE_NEW  = 122,
	ENGINE_F_ENGINE_PKEY_ASN1_FIND_STR = 197,
	ENGINE_F_ENGINE_REMOVE = 123,
	ENGINE_F_ENGINE_SET_DEFAULT_STRING = 189,
	ENGINE_F_ENGINE_SET_ID = 129,
	ENGINE_F_ENGINE_SET_NAME = 130,
	ENGINE_F_ENGINE_TABLE_REGISTER = 184,
	ENGINE_F_ENGINE_UNLOCKED_FINISH = 191,
	ENGINE_F_ENGINE_UP_REF = 190,
	ENGINE_F_INT_CLEANUP_ITEM = 199,
	ENGINE_F_INT_CTRL_HELPER = 172,
	ENGINE_F_INT_ENGINE_CONFIGURE = 188,
	ENGINE_F_INT_ENGINE_MODULE_INIT = 187,
	ENGINE_F_OSSL_HMAC_INIT = 200,
	ENGINE_R_ALREADY_LOADED = 100,
	ENGINE_R_ARGUMENT_IS_NOT_A_NUMBER = 133,
	ENGINE_R_CMD_NOT_EXECUTABLE = 134,
	ENGINE_R_COMMAND_TAKES_INPUT = 135,
	ENGINE_R_COMMAND_TAKES_NO_INPUT = 136,
	ENGINE_R_CONFLICTING_ENGINE_ID = 103,
	ENGINE_R_CTRL_COMMAND_NOT_IMPLEMENTED = 119,
	ENGINE_R_DSO_FAILURE = 104,
	ENGINE_R_DSO_NOT_FOUND = 132,
	ENGINE_R_ENGINES_SECTION_ERROR = 148,
	ENGINE_R_ENGINE_CONFIGURATION_ERROR = 102,
	ENGINE_R_ENGINE_IS_NOT_IN_LIST = 105,
	ENGINE_R_ENGINE_SECTION_ERROR = 149,
	ENGINE_R_FAILED_LOADING_PRIVATE_KEY = 128,
	ENGINE_R_FAILED_LOADING_PUBLIC_KEY = 129,
	ENGINE_R_FINISH_FAILED = 106,
	ENGINE_R_ID_OR_NAME_MISSING = 108,
	ENGINE_R_INIT_FAILED = 109,
	ENGINE_R_INTERNAL_LIST_ERROR = 110,
	ENGINE_R_INVALID_ARGUMENT = 143,
	ENGINE_R_INVALID_CMD_NAME = 137,
	ENGINE_R_INVALID_CMD_NUMBER = 138,
	ENGINE_R_INVALID_INIT_VALUE = 151,
	ENGINE_R_INVALID_STRING = 150,
	ENGINE_R_NOT_INITIALISED = 117,
	ENGINE_R_NOT_LOADED  = 112,
	ENGINE_R_NO_CONTROL_FUNCTION = 120,
	ENGINE_R_NO_INDEX    = 144,
	ENGINE_R_NO_LOAD_FUNCTION = 125,
	ENGINE_R_NO_REFERENCE = 130,
	ENGINE_R_NO_SUCH_ENGINE = 116,
	ENGINE_R_UNIMPLEMENTED_CIPHER = 146,
	ENGINE_R_UNIMPLEMENTED_DIGEST = 147,
	ENGINE_R_UNIMPLEMENTED_PUBLIC_KEY_METHOD = 101,
	ENGINE_R_VERSION_INCOMPATIBILITY = 145,
};
]]
