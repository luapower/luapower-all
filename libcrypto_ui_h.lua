local ffi = require'ffi'
--[[
// csrc/openssl/src/include/openssl/ui.h
UI *UI_new(void);
UI *UI_new_method(const UI_METHOD *method);
void UI_free(UI *ui);
int UI_add_input_string(UI *ui, const char *prompt, int flags,
                        char *result_buf, int minsize, int maxsize);
int UI_dup_input_string(UI *ui, const char *prompt, int flags,
                        char *result_buf, int minsize, int maxsize);
int UI_add_verify_string(UI *ui, const char *prompt, int flags,
                         char *result_buf, int minsize, int maxsize,
                         const char *test_buf);
int UI_dup_verify_string(UI *ui, const char *prompt, int flags,
                         char *result_buf, int minsize, int maxsize,
                         const char *test_buf);
int UI_add_input_boolean(UI *ui, const char *prompt, const char *action_desc,
                         const char *ok_chars, const char *cancel_chars,
                         int flags, char *result_buf);
int UI_dup_input_boolean(UI *ui, const char *prompt, const char *action_desc,
                         const char *ok_chars, const char *cancel_chars,
                         int flags, char *result_buf);
int UI_add_info_string(UI *ui, const char *text);
int UI_dup_info_string(UI *ui, const char *text);
int UI_add_error_string(UI *ui, const char *text);
int UI_dup_error_string(UI *ui, const char *text);
enum {
	UI_INPUT_FLAG_ECHO   = 0x01,
	UI_INPUT_FLAG_DEFAULT_PWD = 0x02,
	UI_INPUT_FLAG_USER_BASE = 16,
};
char *UI_construct_prompt(UI *ui_method,
                          const char *object_desc, const char *object_name);
void *UI_add_user_data(UI *ui, void *user_data);
int UI_dup_user_data(UI *ui, void *user_data);
void *UI_get0_user_data(UI *ui);
const char *UI_get0_result(UI *ui, int i);
int UI_get_result_length(UI *ui, int i);
int UI_process(UI *ui);
int UI_ctrl(UI *ui, int cmd, long i, void *p, void (*f) (void));
enum {
	UI_CTRL_PRINT_ERRORS = 1,
	UI_CTRL_IS_REDOABLE  = 2,
};
#define UI_set_app_data(s,arg) UI_set_ex_data(s,0,arg)
#define UI_get_app_data(s) UI_get_ex_data(s,0)
#define UI_get_ex_new_index(l,p,newf,dupf,freef) CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_UI, l, p, newf, dupf, freef)
int UI_set_ex_data(UI *r, int idx, void *arg);
void *UI_get_ex_data(UI *r, int idx);
void UI_set_default_method(const UI_METHOD *meth);
const UI_METHOD *UI_get_default_method(void);
const UI_METHOD *UI_get_method(UI *ui);
const UI_METHOD *UI_set_method(UI *ui, const UI_METHOD *meth);
UI_METHOD *UI_OpenSSL(void);
const UI_METHOD *UI_null(void);
typedef struct ui_string_st UI_STRING;
struct stack_st_UI_STRING; typedef int (*sk_UI_STRING_compfunc)(const UI_STRING * const *a, const UI_STRING *const *b); typedef void (*sk_UI_STRING_freefunc)(UI_STRING *a); typedef UI_STRING * (*sk_UI_STRING_copyfunc)(const UI_STRING *a); static __attribute__((unused)) inline int sk_UI_STRING_num(const struct stack_st_UI_STRING *sk) { return OPENSSL_sk_num((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline UI_STRING *sk_UI_STRING_value(const struct stack_st_UI_STRING *sk, int idx) { return (UI_STRING *)OPENSSL_sk_value((const OPENSSL_STACK *)sk, idx); } static __attribute__((unused)) inline struct stack_st_UI_STRING *sk_UI_STRING_new(sk_UI_STRING_compfunc compare) { return (struct stack_st_UI_STRING *)OPENSSL_sk_new((OPENSSL_sk_compfunc)compare); } static __attribute__((unused)) inline struct stack_st_UI_STRING *sk_UI_STRING_new_null(void) { return (struct stack_st_UI_STRING *)OPENSSL_sk_new_null(); } static __attribute__((unused)) inline struct stack_st_UI_STRING *sk_UI_STRING_new_reserve(sk_UI_STRING_compfunc compare, int n) { return (struct stack_st_UI_STRING *)OPENSSL_sk_new_reserve((OPENSSL_sk_compfunc)compare, n); } static __attribute__((unused)) inline int sk_UI_STRING_reserve(struct stack_st_UI_STRING *sk, int n) { return OPENSSL_sk_reserve((OPENSSL_STACK *)sk, n); } static __attribute__((unused)) inline void sk_UI_STRING_free(struct stack_st_UI_STRING *sk) { OPENSSL_sk_free((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_UI_STRING_zero(struct stack_st_UI_STRING *sk) { OPENSSL_sk_zero((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline UI_STRING *sk_UI_STRING_delete(struct stack_st_UI_STRING *sk, int i) { return (UI_STRING *)OPENSSL_sk_delete((OPENSSL_STACK *)sk, i); } static __attribute__((unused)) inline UI_STRING *sk_UI_STRING_delete_ptr(struct stack_st_UI_STRING *sk, UI_STRING *ptr) { return (UI_STRING *)OPENSSL_sk_delete_ptr((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_UI_STRING_push(struct stack_st_UI_STRING *sk, UI_STRING *ptr) { return OPENSSL_sk_push((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_UI_STRING_unshift(struct stack_st_UI_STRING *sk, UI_STRING *ptr) { return OPENSSL_sk_unshift((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline UI_STRING *sk_UI_STRING_pop(struct stack_st_UI_STRING *sk) { return (UI_STRING *)OPENSSL_sk_pop((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline UI_STRING *sk_UI_STRING_shift(struct stack_st_UI_STRING *sk) { return (UI_STRING *)OPENSSL_sk_shift((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline void sk_UI_STRING_pop_free(struct stack_st_UI_STRING *sk, sk_UI_STRING_freefunc freefunc) { OPENSSL_sk_pop_free((OPENSSL_STACK *)sk, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline int sk_UI_STRING_insert(struct stack_st_UI_STRING *sk, UI_STRING *ptr, int idx) { return OPENSSL_sk_insert((OPENSSL_STACK *)sk, (const void *)ptr, idx); } static __attribute__((unused)) inline UI_STRING *sk_UI_STRING_set(struct stack_st_UI_STRING *sk, int idx, UI_STRING *ptr) { return (UI_STRING *)OPENSSL_sk_set((OPENSSL_STACK *)sk, idx, (const void *)ptr); } static __attribute__((unused)) inline int sk_UI_STRING_find(struct stack_st_UI_STRING *sk, UI_STRING *ptr) { return OPENSSL_sk_find((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline int sk_UI_STRING_find_ex(struct stack_st_UI_STRING *sk, UI_STRING *ptr) { return OPENSSL_sk_find_ex((OPENSSL_STACK *)sk, (const void *)ptr); } static __attribute__((unused)) inline void sk_UI_STRING_sort(struct stack_st_UI_STRING *sk) { OPENSSL_sk_sort((OPENSSL_STACK *)sk); } static __attribute__((unused)) inline int sk_UI_STRING_is_sorted(const struct stack_st_UI_STRING *sk) { return OPENSSL_sk_is_sorted((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_UI_STRING * sk_UI_STRING_dup(const struct stack_st_UI_STRING *sk) { return (struct stack_st_UI_STRING *)OPENSSL_sk_dup((const OPENSSL_STACK *)sk); } static __attribute__((unused)) inline struct stack_st_UI_STRING *sk_UI_STRING_deep_copy(const struct stack_st_UI_STRING *sk, sk_UI_STRING_copyfunc copyfunc, sk_UI_STRING_freefunc freefunc) { return (struct stack_st_UI_STRING *)OPENSSL_sk_deep_copy((const OPENSSL_STACK *)sk, (OPENSSL_sk_copyfunc)copyfunc, (OPENSSL_sk_freefunc)freefunc); } static __attribute__((unused)) inline sk_UI_STRING_compfunc sk_UI_STRING_set_cmp_func(struct stack_st_UI_STRING *sk, sk_UI_STRING_compfunc compare) { return (sk_UI_STRING_compfunc)OPENSSL_sk_set_cmp_func((OPENSSL_STACK *)sk, (OPENSSL_sk_compfunc)compare); }
enum UI_string_types {
    UIT_NONE = 0,
    UIT_PROMPT,
    UIT_VERIFY,
    UIT_BOOLEAN,
    UIT_INFO,
    UIT_ERROR
};
UI_METHOD *UI_create_method(const char *name);
void UI_destroy_method(UI_METHOD *ui_method);
int UI_method_set_opener(UI_METHOD *method, int (*opener) (UI *ui));
int UI_method_set_writer(UI_METHOD *method,
                         int (*writer) (UI *ui, UI_STRING *uis));
int UI_method_set_flusher(UI_METHOD *method, int (*flusher) (UI *ui));
int UI_method_set_reader(UI_METHOD *method,
                         int (*reader) (UI *ui, UI_STRING *uis));
int UI_method_set_closer(UI_METHOD *method, int (*closer) (UI *ui));
int UI_method_set_data_duplicator(UI_METHOD *method,
                                  void *(*duplicator) (UI *ui, void *ui_data),
                                  void (*destructor)(UI *ui, void *ui_data));
int UI_method_set_prompt_constructor(UI_METHOD *method,
                                     char *(*prompt_constructor) (UI *ui,
                                                                  const char
                                                                  *object_desc,
                                                                  const char
                                                                  *object_name));
int UI_method_set_ex_data(UI_METHOD *method, int idx, void *data);
int (*UI_method_get_opener(const UI_METHOD *method)) (UI *);
int (*UI_method_get_writer(const UI_METHOD *method)) (UI *, UI_STRING *);
int (*UI_method_get_flusher(const UI_METHOD *method)) (UI *);
int (*UI_method_get_reader(const UI_METHOD *method)) (UI *, UI_STRING *);
int (*UI_method_get_closer(const UI_METHOD *method)) (UI *);
char *(*UI_method_get_prompt_constructor(const UI_METHOD *method))
    (UI *, const char *, const char *);
void *(*UI_method_get_data_duplicator(const UI_METHOD *method)) (UI *, void *);
void (*UI_method_get_data_destructor(const UI_METHOD *method)) (UI *, void *);
const void *UI_method_get_ex_data(const UI_METHOD *method, int idx);
enum UI_string_types UI_get_string_type(UI_STRING *uis);
int UI_get_input_flags(UI_STRING *uis);
const char *UI_get0_output_string(UI_STRING *uis);
const char *UI_get0_action_string(UI_STRING *uis);
const char *UI_get0_result_string(UI_STRING *uis);
int UI_get_result_string_length(UI_STRING *uis);
const char *UI_get0_test_string(UI_STRING *uis);
int UI_get_result_minsize(UI_STRING *uis);
int UI_get_result_maxsize(UI_STRING *uis);
int UI_set_result(UI *ui, UI_STRING *uis, const char *result);
int UI_set_result_ex(UI *ui, UI_STRING *uis, const char *result, int len);
int UI_UTIL_read_pw_string(char *buf, int length, const char *prompt,
                           int verify);
int UI_UTIL_read_pw(char *buf, char *buff, int size, const char *prompt,
                    int verify);
UI_METHOD *UI_UTIL_wrap_read_pem_callback(pem_password_cb *cb, int rwflag);

// csrc/openssl/src/include/openssl/uierr.h
int ERR_load_UI_strings(void);
enum {
	UI_F_CLOSE_CONSOLE   = 115,
	UI_F_ECHO_CONSOLE    = 116,
	UI_F_GENERAL_ALLOCATE_BOOLEAN = 108,
	UI_F_GENERAL_ALLOCATE_PROMPT = 109,
	UI_F_NOECHO_CONSOLE  = 117,
	UI_F_OPEN_CONSOLE    = 114,
	UI_F_UI_CONSTRUCT_PROMPT = 121,
	UI_F_UI_CREATE_METHOD = 112,
	UI_F_UI_CTRL         = 111,
	UI_F_UI_DUP_ERROR_STRING = 101,
	UI_F_UI_DUP_INFO_STRING = 102,
	UI_F_UI_DUP_INPUT_BOOLEAN = 110,
	UI_F_UI_DUP_INPUT_STRING = 103,
	UI_F_UI_DUP_USER_DATA = 118,
	UI_F_UI_DUP_VERIFY_STRING = 106,
	UI_F_UI_GET0_RESULT  = 107,
	UI_F_UI_GET_RESULT_LENGTH = 119,
	UI_F_UI_NEW_METHOD   = 104,
	UI_F_UI_PROCESS      = 113,
	UI_F_UI_SET_RESULT   = 105,
	UI_F_UI_SET_RESULT_EX = 120,
	UI_R_COMMON_OK_AND_CANCEL_CHARACTERS = 104,
	UI_R_INDEX_TOO_LARGE = 102,
	UI_R_INDEX_TOO_SMALL = 103,
	UI_R_NO_RESULT_BUFFER = 105,
	UI_R_PROCESSING_ERROR = 107,
	UI_R_RESULT_TOO_LARGE = 100,
	UI_R_RESULT_TOO_SMALL = 101,
	UI_R_SYSASSIGN_ERROR = 109,
	UI_R_SYSDASSGN_ERROR = 110,
	UI_R_SYSQIOW_ERROR   = 111,
	UI_R_UNKNOWN_CONTROL_COMMAND = 106,
	UI_R_UNKNOWN_TTYGET_ERRNO_VALUE = 108,
	UI_R_USER_DATA_DUPLICATION_UNSUPPORTED = 112,
};
]]
