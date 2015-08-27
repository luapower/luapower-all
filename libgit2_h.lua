local ffi = require'ffi'

ffi.cdef[[
typedef long long __time64_t;
typedef long long off64_t;

void git_libgit2_version(int *major, int *minor, int *rev);
typedef enum {
	GIT_FEATURE_THREADS = (1 << 0),
	GIT_FEATURE_HTTPS = (1 << 1),
	GIT_FEATURE_SSH = (1 << 2),
} git_feature_t;
int git_libgit2_features(void);
typedef enum {
	GIT_OPT_GET_MWINDOW_SIZE,
	GIT_OPT_SET_MWINDOW_SIZE,
	GIT_OPT_GET_MWINDOW_MAPPED_LIMIT,
	GIT_OPT_SET_MWINDOW_MAPPED_LIMIT,
	GIT_OPT_GET_SEARCH_PATH,
	GIT_OPT_SET_SEARCH_PATH,
	GIT_OPT_SET_CACHE_OBJECT_LIMIT,
	GIT_OPT_SET_CACHE_MAX_SIZE,
	GIT_OPT_ENABLE_CACHING,
	GIT_OPT_GET_CACHED_MEMORY,
	GIT_OPT_GET_TEMPLATE_PATH,
	GIT_OPT_SET_TEMPLATE_PATH,
	GIT_OPT_SET_SSL_CERT_LOCATIONS,
} git_libgit2_opt_t;
int git_libgit2_opts(int option, ...);
typedef off64_t git_off_t;
typedef __time64_t git_time_t;
typedef enum {
	GIT_OBJ_ANY = -2,
	GIT_OBJ_BAD = -1,
	GIT_OBJ__EXT1 = 0,
	GIT_OBJ_COMMIT = 1,
	GIT_OBJ_TREE = 2,
	GIT_OBJ_BLOB = 3,
	GIT_OBJ_TAG = 4,
	GIT_OBJ__EXT2 = 5,
	GIT_OBJ_OFS_DELTA = 6,
	GIT_OBJ_REF_DELTA = 7,
} git_otype;
typedef struct git_odb git_odb;
typedef struct git_odb_backend git_odb_backend;
typedef struct git_odb_object git_odb_object;
typedef struct git_odb_stream git_odb_stream;
typedef struct git_odb_writepack git_odb_writepack;
typedef struct git_refdb git_refdb;
typedef struct git_refdb_backend git_refdb_backend;
typedef struct git_repository git_repository;
typedef struct git_object git_object;
typedef struct git_revwalk git_revwalk;
typedef struct git_tag git_tag;
typedef struct git_blob git_blob;
typedef struct git_commit git_commit;
typedef struct git_tree_entry git_tree_entry;
typedef struct git_tree git_tree;
typedef struct git_treebuilder git_treebuilder;
typedef struct git_index git_index;
typedef struct git_index_conflict_iterator git_index_conflict_iterator;
typedef struct git_config git_config;
typedef struct git_config_backend git_config_backend;
typedef struct git_reflog_entry git_reflog_entry;
typedef struct git_reflog git_reflog;
typedef struct git_note git_note;
typedef struct git_packbuilder git_packbuilder;
typedef struct git_time {
	git_time_t time;
	int offset;
} git_time;
typedef struct git_signature {
	char *name;
	char *email;
	git_time when;
} git_signature;
typedef struct git_reference git_reference;
typedef struct git_reference_iterator git_reference_iterator;
typedef struct git_transaction git_transaction;
typedef struct git_annotated_commit git_annotated_commit;
typedef struct git_merge_result git_merge_result;
typedef struct git_status_list git_status_list;
typedef struct git_rebase git_rebase;
typedef enum {
	GIT_REF_INVALID = 0,
	GIT_REF_OID = 1,
	GIT_REF_SYMBOLIC = 2,
	GIT_REF_LISTALL = GIT_REF_OID|GIT_REF_SYMBOLIC,
} git_ref_t;
typedef enum {
	GIT_BRANCH_LOCAL = 1,
	GIT_BRANCH_REMOTE = 2,
	GIT_BRANCH_ALL = GIT_BRANCH_LOCAL|GIT_BRANCH_REMOTE,
} git_branch_t;
typedef enum {
	GIT_FILEMODE_UNREADABLE = 0000000,
	GIT_FILEMODE_TREE = 0040000,
	GIT_FILEMODE_BLOB = 0100644,
	GIT_FILEMODE_BLOB_EXECUTABLE = 0100755,
	GIT_FILEMODE_LINK = 0120000,
	GIT_FILEMODE_COMMIT = 0160000,
} git_filemode_t;
typedef struct git_refspec git_refspec;
typedef struct git_remote git_remote;
typedef struct git_push git_push;
typedef struct git_remote_head git_remote_head;
typedef struct git_remote_callbacks git_remote_callbacks;
typedef struct git_transfer_progress {
	unsigned int total_objects;
	unsigned int indexed_objects;
	unsigned int received_objects;
	unsigned int local_objects;
	unsigned int total_deltas;
	unsigned int indexed_deltas;
	size_t received_bytes;
} git_transfer_progress;
typedef int (*git_transfer_progress_cb)(const git_transfer_progress *stats, void *payload);
typedef int (*git_transport_message_cb)(const char *str, int len, void *payload);
typedef enum git_cert_t {
	GIT_CERT_X509,
	GIT_CERT_HOSTKEY_LIBSSH2,
} git_cert_t;
typedef struct {
	git_cert_t cert_type;
} git_cert;
typedef int (*git_transport_certificate_check_cb)(git_cert *cert, int valid, const char *host, void *payload);
typedef struct git_submodule git_submodule;
typedef enum {
	GIT_SUBMODULE_UPDATE_RESET = -1,
	GIT_SUBMODULE_UPDATE_CHECKOUT = 1,
	GIT_SUBMODULE_UPDATE_REBASE = 2,
	GIT_SUBMODULE_UPDATE_MERGE = 3,
	GIT_SUBMODULE_UPDATE_NONE = 4,
	GIT_SUBMODULE_UPDATE_DEFAULT = 0
} git_submodule_update_t;
typedef enum {
	GIT_SUBMODULE_IGNORE_RESET = -1,
	GIT_SUBMODULE_IGNORE_NONE = 1,
	GIT_SUBMODULE_IGNORE_UNTRACKED = 2,
	GIT_SUBMODULE_IGNORE_DIRTY = 3,
	GIT_SUBMODULE_IGNORE_ALL = 4,
	GIT_SUBMODULE_IGNORE_DEFAULT = 0
} git_submodule_ignore_t;
typedef enum {
	GIT_SUBMODULE_RECURSE_RESET = -1,
	GIT_SUBMODULE_RECURSE_NO = 0,
	GIT_SUBMODULE_RECURSE_YES = 1,
	GIT_SUBMODULE_RECURSE_ONDEMAND = 2,
} git_submodule_recurse_t;
typedef struct git_oid {
	unsigned char id[20];
} git_oid;
int git_oid_fromstr(git_oid *out, const char *str);
int git_oid_fromstrp(git_oid *out, const char *str);
int git_oid_fromstrn(git_oid *out, const char *str, size_t length);
void git_oid_fromraw(git_oid *out, const unsigned char *raw);
void git_oid_fmt(char *out, const git_oid *id);
void git_oid_nfmt(char *out, size_t n, const git_oid *id);
void git_oid_pathfmt(char *out, const git_oid *id);
char * git_oid_tostr_s(const git_oid *oid);
char * git_oid_tostr(char *out, size_t n, const git_oid *id);
void git_oid_cpy(git_oid *out, const git_oid *src);
int git_oid_cmp(const git_oid *a, const git_oid *b);
int git_oid_equal(const git_oid *a, const git_oid *b);
int git_oid_ncmp(const git_oid *a, const git_oid *b, size_t len);
int git_oid_streq(const git_oid *id, const char *str);
int git_oid_strcmp(const git_oid *id, const char *str);
int git_oid_iszero(const git_oid *id);
typedef struct git_oid_shorten git_oid_shorten;
git_oid_shorten * git_oid_shorten_new(size_t min_length);
int git_oid_shorten_add(git_oid_shorten *os, const char *text_id);
void git_oid_shorten_free(git_oid_shorten *os);
typedef struct {
	char *ptr;
	size_t asize, size;
} git_buf;
void git_buf_free(git_buf *buffer);
int git_buf_grow(git_buf *buffer, size_t target_size);
int git_buf_set(
	git_buf *buffer, const void *data, size_t datalen);
int git_buf_is_binary(const git_buf *buf);
int git_buf_contains_nul(const git_buf *buf);
int git_repository_open(git_repository **out, const char *path);
int git_repository_wrap_odb(git_repository **out, git_odb *odb);
int git_repository_discover(
	 git_buf *out,
	 const char *start_path,
	 int across_fs,
	 const char *ceiling_dirs);
typedef enum {
	GIT_REPOSITORY_OPEN_NO_SEARCH = (1 << 0),
	GIT_REPOSITORY_OPEN_CROSS_FS = (1 << 1),
	GIT_REPOSITORY_OPEN_BARE = (1 << 2),
} git_repository_open_flag_t;
int git_repository_open_ext(
	git_repository **out,
	const char *path,
	unsigned int flags,
	const char *ceiling_dirs);
int git_repository_open_bare(git_repository **out, const char *bare_path);
void git_repository_free(git_repository *repo);
int git_repository_init(
	git_repository **out,
	const char *path,
	unsigned is_bare);
typedef enum {
	GIT_REPOSITORY_INIT_BARE = (1u << 0),
	GIT_REPOSITORY_INIT_NO_REINIT = (1u << 1),
	GIT_REPOSITORY_INIT_NO_DOTGIT_DIR = (1u << 2),
	GIT_REPOSITORY_INIT_MKDIR = (1u << 3),
	GIT_REPOSITORY_INIT_MKPATH = (1u << 4),
	GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE = (1u << 5),
	GIT_REPOSITORY_INIT_RELATIVE_GITLINK = (1u << 6),
} git_repository_init_flag_t;
typedef enum {
	GIT_REPOSITORY_INIT_SHARED_UMASK = 0,
	GIT_REPOSITORY_INIT_SHARED_GROUP = 0002775,
	GIT_REPOSITORY_INIT_SHARED_ALL = 0002777,
} git_repository_init_mode_t;
typedef struct {
	unsigned int version;
	uint32_t flags;
	uint32_t mode;
	const char *workdir_path;
	const char *description;
	const char *template_path;
	const char *initial_head;
	const char *origin_url;
} git_repository_init_options;
int git_repository_init_init_options(
	git_repository_init_options *opts,
	unsigned int version);
int git_repository_init_ext(
	git_repository **out,
	const char *repo_path,
	git_repository_init_options *opts);
int git_repository_head(git_reference **out, git_repository *repo);
int git_repository_head_detached(git_repository *repo);
int git_repository_head_unborn(git_repository *repo);
int git_repository_is_empty(git_repository *repo);
const char * git_repository_path(git_repository *repo);
const char * git_repository_workdir(git_repository *repo);
int git_repository_set_workdir(
	git_repository *repo, const char *workdir, int update_gitlink);
int git_repository_is_bare(git_repository *repo);
int git_repository_config(git_config **out, git_repository *repo);
int git_repository_config_snapshot(git_config **out, git_repository *repo);
int git_repository_odb(git_odb **out, git_repository *repo);
int git_repository_refdb(git_refdb **out, git_repository *repo);
int git_repository_index(git_index **out, git_repository *repo);
int git_repository_message(git_buf *out, git_repository *repo);
int git_repository_message_remove(git_repository *repo);
int git_repository_state_cleanup(git_repository *repo);
typedef int (*git_repository_fetchhead_foreach_cb)(const char *ref_name,
	const char *remote_url,
	const git_oid *oid,
	unsigned int is_merge,
	void *payload);
int git_repository_fetchhead_foreach(
	git_repository *repo,
	git_repository_fetchhead_foreach_cb callback,
	void *payload);
typedef int (*git_repository_mergehead_foreach_cb)(const git_oid *oid,
	void *payload);
int git_repository_mergehead_foreach(
	git_repository *repo,
	git_repository_mergehead_foreach_cb callback,
	void *payload);
int git_repository_hashfile(
	git_oid *out,
	git_repository *repo,
	const char *path,
	git_otype type,
	const char *as_path);
int git_repository_set_head(
	git_repository* repo,
	const char* refname,
	const git_signature *signature,
	const char *log_message);
int git_repository_set_head_detached(
	git_repository* repo,
	const git_oid* commitish,
	const git_signature *signature,
	const char *log_message);
int git_repository_detach_head(
	git_repository* repo,
	const git_signature *signature,
	const char *reflog_message);
typedef enum {
	GIT_REPOSITORY_STATE_NONE,
	GIT_REPOSITORY_STATE_MERGE,
	GIT_REPOSITORY_STATE_REVERT,
	GIT_REPOSITORY_STATE_CHERRYPICK,
	GIT_REPOSITORY_STATE_BISECT,
	GIT_REPOSITORY_STATE_REBASE,
	GIT_REPOSITORY_STATE_REBASE_INTERACTIVE,
	GIT_REPOSITORY_STATE_REBASE_MERGE,
	GIT_REPOSITORY_STATE_APPLY_MAILBOX,
	GIT_REPOSITORY_STATE_APPLY_MAILBOX_OR_REBASE,
} git_repository_state_t;
int git_repository_state(git_repository *repo);
int git_repository_set_namespace(git_repository *repo, const char *nmspace);
const char * git_repository_get_namespace(git_repository *repo);
int git_repository_is_shallow(git_repository *repo);
int git_annotated_commit_from_ref(
	git_annotated_commit **out,
	git_repository *repo,
	const git_reference *ref);
int git_annotated_commit_from_fetchhead(
	git_annotated_commit **out,
	git_repository *repo,
	const char *branch_name,
	const char *remote_url,
	const git_oid *id);
int git_annotated_commit_lookup(
	git_annotated_commit **out,
	git_repository *repo,
	const git_oid *id);
const git_oid * git_annotated_commit_id(
	const git_annotated_commit *commit);
void git_annotated_commit_free(
	git_annotated_commit *commit);
typedef enum {
	GIT_ATTR_UNSPECIFIED_T = 0,
	GIT_ATTR_TRUE_T,
	GIT_ATTR_FALSE_T,
	GIT_ATTR_VALUE_T,
} git_attr_t;
git_attr_t git_attr_value(const char *attr);
int git_attr_get(
	const char **value_out,
	git_repository *repo,
	uint32_t flags,
	const char *path,
	const char *name);
int git_attr_get_many(
	const char **values_out,
	git_repository *repo,
	uint32_t flags,
	const char *path,
	size_t num_attr,
	const char **names);
typedef int (*git_attr_foreach_cb)(const char *name, const char *value, void *payload);
int git_attr_foreach(
	git_repository *repo,
	uint32_t flags,
	const char *path,
	git_attr_foreach_cb callback,
	void *payload);
void git_attr_cache_flush(
	git_repository *repo);
int git_attr_add_macro(
	git_repository *repo,
	const char *name,
	const char *values);
int git_object_lookup(
	 git_object **object,
	 git_repository *repo,
	 const git_oid *id,
	 git_otype type);
int git_object_lookup_prefix(
	 git_object **object_out,
	 git_repository *repo,
	 const git_oid *id,
	 size_t len,
	 git_otype type);
int git_object_lookup_bypath(
	 git_object **out,
	 const git_object *treeish,
	 const char *path,
	 git_otype type);
const git_oid * git_object_id(const git_object *obj);
int git_object_short_id(git_buf *out, const git_object *obj);
git_otype git_object_type(const git_object *obj);
git_repository * git_object_owner(const git_object *obj);
void git_object_free(git_object *object);
const char * git_object_type2string(git_otype type);
git_otype git_object_string2type(const char *str);
int git_object_typeisloose(git_otype type);
size_t git_object__size(git_otype type);
int git_object_peel(
	git_object **peeled,
	const git_object *object,
	git_otype target_type);
int git_object_dup(git_object **dest, git_object *source);
int git_blob_lookup(git_blob **blob, git_repository *repo, const git_oid *id);
int git_blob_lookup_prefix(git_blob **blob, git_repository *repo, const git_oid *id, size_t len);
void git_blob_free(git_blob *blob);
const git_oid * git_blob_id(const git_blob *blob);
git_repository * git_blob_owner(const git_blob *blob);
const void * git_blob_rawcontent(const git_blob *blob);
git_off_t git_blob_rawsize(const git_blob *blob);
int git_blob_filtered_content(
	git_buf *out,
	git_blob *blob,
	const char *as_path,
	int check_for_binary_data);
int git_blob_create_fromworkdir(git_oid *id, git_repository *repo, const char *relative_path);
int git_blob_create_fromdisk(git_oid *id, git_repository *repo, const char *path);
typedef int (*git_blob_chunk_cb)(char *content, size_t max_length, void *payload);
int git_blob_create_fromchunks(
	git_oid *id,
	git_repository *repo,
	const char *hintpath,
	git_blob_chunk_cb callback,
	void *payload);
int git_blob_create_frombuffer(
	git_oid *id, git_repository *repo, const void *buffer, size_t len);
int git_blob_is_binary(const git_blob *blob);
typedef enum {
	GIT_BLAME_NORMAL = 0,
	GIT_BLAME_TRACK_COPIES_SAME_FILE = (1<<0),
	GIT_BLAME_TRACK_COPIES_SAME_COMMIT_MOVES = (1<<1),
	GIT_BLAME_TRACK_COPIES_SAME_COMMIT_COPIES = (1<<2),
	GIT_BLAME_TRACK_COPIES_ANY_COMMIT_COPIES = (1<<3),
	GIT_BLAME_FIRST_PARENT = (1<<4),
} git_blame_flag_t;
typedef struct git_blame_options {
	unsigned int version;
	uint32_t flags;
	uint16_t min_match_characters;
	git_oid newest_commit;
	git_oid oldest_commit;
	uint32_t min_line;
	uint32_t max_line;
} git_blame_options;
int git_blame_init_options(
	git_blame_options *opts,
	unsigned int version);
typedef struct git_blame_hunk {
	uint16_t lines_in_hunk;
	git_oid final_commit_id;
	uint16_t final_start_line_number;
	git_signature *final_signature;
	git_oid orig_commit_id;
	const char *orig_path;
	uint16_t orig_start_line_number;
	git_signature *orig_signature;
	char boundary;
} git_blame_hunk;
typedef struct git_blame git_blame;
uint32_t git_blame_get_hunk_count(git_blame *blame);
const git_blame_hunk* git_blame_get_hunk_byindex(
	 git_blame *blame,
	 uint32_t index);
const git_blame_hunk* git_blame_get_hunk_byline(
	 git_blame *blame,
	 uint32_t lineno);
int git_blame_file(
	 git_blame **out,
	 git_repository *repo,
	 const char *path,
	 git_blame_options *options);
int git_blame_buffer(
	 git_blame **out,
	 git_blame *reference,
	 const char *buffer,
	 size_t buffer_len);
void git_blame_free(git_blame *blame);
int git_branch_create(
	git_reference **out,
	git_repository *repo,
	const char *branch_name,
	const git_commit *target,
	int force,
	const git_signature *signature,
	const char *log_message);
int git_branch_delete(git_reference *branch);
typedef struct git_branch_iterator git_branch_iterator;
int git_branch_iterator_new(
	git_branch_iterator **out,
	git_repository *repo,
	git_branch_t list_flags);
int git_branch_next(git_reference **out, git_branch_t *out_type, git_branch_iterator *iter);
void git_branch_iterator_free(git_branch_iterator *iter);
int git_branch_move(
	git_reference **out,
	git_reference *branch,
	const char *new_branch_name,
	int force,
	const git_signature *signature,
	const char *log_message);
int git_branch_lookup(
	git_reference **out,
	git_repository *repo,
	const char *branch_name,
	git_branch_t branch_type);
int git_branch_name(
	 const char **out,
	 const git_reference *ref);
int git_branch_upstream(
	git_reference **out,
	const git_reference *branch);
int git_branch_set_upstream(git_reference *branch, const char *upstream_name);
int git_branch_upstream_name(
	git_buf *out,
	git_repository *repo,
	const char *refname);
int git_branch_is_head(
	const git_reference *branch);
int git_branch_remote_name(
	git_buf *out,
	git_repository *repo,
	const char *canonical_branch_name);
	int git_branch_upstream_remote(git_buf *buf, git_repository *repo, const char *refname);
int git_tree_lookup(
	git_tree **out, git_repository *repo, const git_oid *id);
int git_tree_lookup_prefix(
	git_tree **out,
	git_repository *repo,
	const git_oid *id,
	size_t len);
void git_tree_free(git_tree *tree);
const git_oid * git_tree_id(const git_tree *tree);
git_repository * git_tree_owner(const git_tree *tree);
size_t git_tree_entrycount(const git_tree *tree);
const git_tree_entry * git_tree_entry_byname(
	const git_tree *tree, const char *filename);
const git_tree_entry * git_tree_entry_byindex(
	const git_tree *tree, size_t idx);
const git_tree_entry * git_tree_entry_byid(
	const git_tree *tree, const git_oid *id);
int git_tree_entry_bypath(
	git_tree_entry **out,
	const git_tree *root,
	const char *path);
int git_tree_entry_dup(git_tree_entry **dest, const git_tree_entry *source);
void git_tree_entry_free(git_tree_entry *entry);
const char * git_tree_entry_name(const git_tree_entry *entry);
const git_oid * git_tree_entry_id(const git_tree_entry *entry);
git_otype git_tree_entry_type(const git_tree_entry *entry);
git_filemode_t git_tree_entry_filemode(const git_tree_entry *entry);
git_filemode_t git_tree_entry_filemode_raw(const git_tree_entry *entry);
int git_tree_entry_cmp(const git_tree_entry *e1, const git_tree_entry *e2);
int git_tree_entry_to_object(
	git_object **object_out,
	git_repository *repo,
	const git_tree_entry *entry);
int git_treebuilder_new(
	git_treebuilder **out, git_repository *repo, const git_tree *source);
void git_treebuilder_clear(git_treebuilder *bld);
unsigned int git_treebuilder_entrycount(git_treebuilder *bld);
void git_treebuilder_free(git_treebuilder *bld);
const git_tree_entry * git_treebuilder_get(
	git_treebuilder *bld, const char *filename);
int git_treebuilder_insert(
	const git_tree_entry **out,
	git_treebuilder *bld,
	const char *filename,
	const git_oid *id,
	git_filemode_t filemode);
int git_treebuilder_remove(
	git_treebuilder *bld, const char *filename);
typedef int (*git_treebuilder_filter_cb)(
	const git_tree_entry *entry, void *payload);
void git_treebuilder_filter(
	git_treebuilder *bld,
	git_treebuilder_filter_cb filter,
	void *payload);
int git_treebuilder_write(
	git_oid *id, git_treebuilder *bld);
typedef int (*git_treewalk_cb)(
	const char *root, const git_tree_entry *entry, void *payload);
typedef enum {
	GIT_TREEWALK_PRE = 0,
	GIT_TREEWALK_POST = 1,
} git_treewalk_mode;
int git_tree_walk(
	const git_tree *tree,
	git_treewalk_mode mode,
	git_treewalk_cb callback,
	void *payload);
typedef struct git_strarray {
	char **strings;
	size_t count;
} git_strarray;
void git_strarray_free(git_strarray *array);
int git_strarray_copy(git_strarray *tgt, const git_strarray *src);
int git_reference_lookup(git_reference **out, git_repository *repo, const char *name);
int git_reference_name_to_id(
	git_oid *out, git_repository *repo, const char *name);
int git_reference_dwim(git_reference **out, git_repository *repo, const char *shorthand);
int git_reference_symbolic_create_matching(git_reference **out, git_repository *repo, const char *name, const char *target, int force, const char *current_value, const git_signature *signature, const char *log_message);
int git_reference_symbolic_create(git_reference **out, git_repository *repo, const char *name, const char *target, int force, const git_signature *signature, const char *log_message);
int git_reference_create(git_reference **out, git_repository *repo, const char *name, const git_oid *id, int force, const git_signature *signature, const char *log_message);
int git_reference_create_matching(git_reference **out, git_repository *repo, const char *name, const git_oid *id, int force, const git_oid *current_id, const git_signature *signature, const char *log_message);
const git_oid * git_reference_target(const git_reference *ref);
const git_oid * git_reference_target_peel(const git_reference *ref);
const char * git_reference_symbolic_target(const git_reference *ref);
git_ref_t git_reference_type(const git_reference *ref);
const char * git_reference_name(const git_reference *ref);
int git_reference_resolve(git_reference **out, const git_reference *ref);
git_repository * git_reference_owner(const git_reference *ref);
int git_reference_symbolic_set_target(
	git_reference **out,
	git_reference *ref,
	const char *target,
	const git_signature *signature,
	const char *log_message);
int git_reference_set_target(
	git_reference **out,
	git_reference *ref,
	const git_oid *id,
	const git_signature *signature,
	const char *log_message);
int git_reference_rename(
	git_reference **new_ref,
	git_reference *ref,
	const char *new_name,
	int force,
	const git_signature *signature,
	const char *log_message);
int git_reference_delete(git_reference *ref);
int git_reference_remove(git_repository *repo, const char *name);
int git_reference_list(git_strarray *array, git_repository *repo);
typedef int (*git_reference_foreach_cb)(git_reference *reference, void *payload);
typedef int (*git_reference_foreach_name_cb)(const char *name, void *payload);
int git_reference_foreach(
	git_repository *repo,
	git_reference_foreach_cb callback,
	void *payload);
int git_reference_foreach_name(
	git_repository *repo,
	git_reference_foreach_name_cb callback,
	void *payload);
void git_reference_free(git_reference *ref);
int git_reference_cmp(
	const git_reference *ref1,
	const git_reference *ref2);
int git_reference_iterator_new(
	git_reference_iterator **out,
	git_repository *repo);
int git_reference_iterator_glob_new(
	git_reference_iterator **out,
	git_repository *repo,
	const char *glob);
int git_reference_next(git_reference **out, git_reference_iterator *iter);
int git_reference_next_name(const char **out, git_reference_iterator *iter);
void git_reference_iterator_free(git_reference_iterator *iter);
int git_reference_foreach_glob(
	git_repository *repo,
	const char *glob,
	git_reference_foreach_name_cb callback,
	void *payload);
int git_reference_has_log(git_repository *repo, const char *refname);
int git_reference_ensure_log(git_repository *repo, const char *refname);
int git_reference_is_branch(const git_reference *ref);
int git_reference_is_remote(const git_reference *ref);
int git_reference_is_tag(const git_reference *ref);
int git_reference_is_note(const git_reference *ref);
typedef enum {
	GIT_REF_FORMAT_NORMAL = 0u,
	GIT_REF_FORMAT_ALLOW_ONELEVEL = (1u << 0),
	GIT_REF_FORMAT_REFSPEC_PATTERN = (1u << 1),
	GIT_REF_FORMAT_REFSPEC_SHORTHAND = (1u << 2),
} git_reference_normalize_t;
int git_reference_normalize_name(
	char *buffer_out,
	size_t buffer_size,
	const char *name,
	unsigned int flags);
int git_reference_peel(
	git_object **out,
	git_reference *ref,
	git_otype type);
int git_reference_is_valid_name(const char *refname);
const char * git_reference_shorthand(const git_reference *ref);
typedef enum {
	GIT_DIFF_NORMAL = 0,
	GIT_DIFF_REVERSE = (1u << 0),
	GIT_DIFF_INCLUDE_IGNORED = (1u << 1),
	GIT_DIFF_RECURSE_IGNORED_DIRS = (1u << 2),
	GIT_DIFF_INCLUDE_UNTRACKED = (1u << 3),
	GIT_DIFF_RECURSE_UNTRACKED_DIRS = (1u << 4),
	GIT_DIFF_INCLUDE_UNMODIFIED = (1u << 5),
	GIT_DIFF_INCLUDE_TYPECHANGE = (1u << 6),
	GIT_DIFF_INCLUDE_TYPECHANGE_TREES = (1u << 7),
	GIT_DIFF_IGNORE_FILEMODE = (1u << 8),
	GIT_DIFF_IGNORE_SUBMODULES = (1u << 9),
	GIT_DIFF_IGNORE_CASE = (1u << 10),
	GIT_DIFF_DISABLE_PATHSPEC_MATCH = (1u << 12),
	GIT_DIFF_SKIP_BINARY_CHECK = (1u << 13),
	GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS = (1u << 14),
	GIT_DIFF_UPDATE_INDEX = (1u << 15),
	GIT_DIFF_INCLUDE_UNREADABLE = (1u << 16),
	GIT_DIFF_INCLUDE_UNREADABLE_AS_UNTRACKED = (1u << 17),
	GIT_DIFF_FORCE_TEXT = (1u << 20),
	GIT_DIFF_FORCE_BINARY = (1u << 21),
	GIT_DIFF_IGNORE_WHITESPACE = (1u << 22),
	GIT_DIFF_IGNORE_WHITESPACE_CHANGE = (1u << 23),
	GIT_DIFF_IGNORE_WHITESPACE_EOL = (1u << 24),
	GIT_DIFF_SHOW_UNTRACKED_CONTENT = (1u << 25),
	GIT_DIFF_SHOW_UNMODIFIED = (1u << 26),
	GIT_DIFF_PATIENCE = (1u << 28),
	GIT_DIFF_MINIMAL = (1 << 29),
	GIT_DIFF_SHOW_BINARY = (1 << 30),
} git_diff_option_t;
typedef struct git_diff git_diff;
typedef enum {
	GIT_DIFF_FLAG_BINARY = (1u << 0),
	GIT_DIFF_FLAG_NOT_BINARY = (1u << 1),
	GIT_DIFF_FLAG_VALID_ID = (1u << 2),
} git_diff_flag_t;
typedef enum {
	GIT_DELTA_UNMODIFIED = 0,
	GIT_DELTA_ADDED = 1,
	GIT_DELTA_DELETED = 2,
	GIT_DELTA_MODIFIED = 3,
	GIT_DELTA_RENAMED = 4,
	GIT_DELTA_COPIED = 5,
	GIT_DELTA_IGNORED = 6,
	GIT_DELTA_UNTRACKED = 7,
	GIT_DELTA_TYPECHANGE = 8,
	GIT_DELTA_UNREADABLE = 9,
} git_delta_t;
typedef struct {
	git_oid id;
	const char *path;
	git_off_t size;
	uint32_t flags;
	uint16_t mode;
} git_diff_file;
typedef struct {
	git_delta_t status;
	uint32_t flags;
	uint16_t similarity;
	uint16_t nfiles;
	git_diff_file old_file;
	git_diff_file new_file;
} git_diff_delta;
typedef int (*git_diff_notify_cb)(
	const git_diff *diff_so_far,
	const git_diff_delta *delta_to_add,
	const char *matched_pathspec,
	void *payload);
typedef struct {
	unsigned int version;
	uint32_t flags;
	git_submodule_ignore_t ignore_submodules;
	git_strarray pathspec;
	git_diff_notify_cb notify_cb;
	void *notify_payload;
	uint32_t context_lines;
	uint32_t interhunk_lines;
	uint16_t id_abbrev;
	git_off_t max_size;
	const char *old_prefix;
	const char *new_prefix;
} git_diff_options;
int git_diff_init_options(
	git_diff_options *opts,
	unsigned int version);
typedef int (*git_diff_file_cb)(
	const git_diff_delta *delta,
	float progress,
	void *payload);
typedef struct {
	int old_start;
	int old_lines;
	int new_start;
	int new_lines;
	size_t header_len;
	char header[128];
} git_diff_hunk;
typedef int (*git_diff_hunk_cb)(
	const git_diff_delta *delta,
	const git_diff_hunk *hunk,
	void *payload);
typedef enum {
	GIT_DIFF_LINE_CONTEXT = ' ',
	GIT_DIFF_LINE_ADDITION = '+',
	GIT_DIFF_LINE_DELETION = '-',
	GIT_DIFF_LINE_CONTEXT_EOFNL = '=',
	GIT_DIFF_LINE_ADD_EOFNL = '>',
	GIT_DIFF_LINE_DEL_EOFNL = '<',
	GIT_DIFF_LINE_FILE_HDR = 'F',
	GIT_DIFF_LINE_HUNK_HDR = 'H',
	GIT_DIFF_LINE_BINARY = 'B'
} git_diff_line_t;
typedef struct {
	char origin;
	int old_lineno;
	int new_lineno;
	int num_lines;
	size_t content_len;
	git_off_t content_offset;
	const char *content;
} git_diff_line;
typedef int (*git_diff_line_cb)(
	const git_diff_delta *delta,
	const git_diff_hunk *hunk,
	const git_diff_line *line,
	void *payload);
typedef enum {
	GIT_DIFF_FIND_BY_CONFIG = 0,
	GIT_DIFF_FIND_RENAMES = (1u << 0),
	GIT_DIFF_FIND_RENAMES_FROM_REWRITES = (1u << 1),
	GIT_DIFF_FIND_COPIES = (1u << 2),
	GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED = (1u << 3),
	GIT_DIFF_FIND_REWRITES = (1u << 4),
	GIT_DIFF_BREAK_REWRITES = (1u << 5),
	GIT_DIFF_FIND_AND_BREAK_REWRITES =
	 (GIT_DIFF_FIND_REWRITES | GIT_DIFF_BREAK_REWRITES),
	GIT_DIFF_FIND_FOR_UNTRACKED = (1u << 6),
	GIT_DIFF_FIND_ALL = (0x0ff),
	GIT_DIFF_FIND_IGNORE_LEADING_WHITESPACE = 0,
	GIT_DIFF_FIND_IGNORE_WHITESPACE = (1u << 12),
	GIT_DIFF_FIND_DONT_IGNORE_WHITESPACE = (1u << 13),
	GIT_DIFF_FIND_EXACT_MATCH_ONLY = (1u << 14),
	GIT_DIFF_BREAK_REWRITES_FOR_RENAMES_ONLY = (1u << 15),
	GIT_DIFF_FIND_REMOVE_UNMODIFIED = (1u << 16),
} git_diff_find_t;
typedef struct {
	int (*file_signature)(
	 void **out, const git_diff_file *file,
	 const char *fullpath, void *payload);
	int (*buffer_signature)(
	 void **out, const git_diff_file *file,
	 const char *buf, size_t buflen, void *payload);
	void (*free_signature)(void *sig, void *payload);
	int (*similarity)(int *score, void *siga, void *sigb, void *payload);
	void *payload;
} git_diff_similarity_metric;
typedef struct {
	unsigned int version;
	uint32_t flags;
	uint16_t rename_threshold;
	uint16_t rename_from_rewrite_threshold;
	uint16_t copy_threshold;
	uint16_t break_rewrite_threshold;
	size_t rename_limit;
	git_diff_similarity_metric *metric;
} git_diff_find_options;
int git_diff_find_init_options(
	git_diff_find_options *opts,
	unsigned int version);
void git_diff_free(git_diff *diff);
int git_diff_tree_to_tree(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	git_tree *new_tree,
	const git_diff_options *opts);
int git_diff_tree_to_index(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	git_index *index,
	const git_diff_options *opts);
int git_diff_index_to_workdir(
	git_diff **diff,
	git_repository *repo,
	git_index *index,
	const git_diff_options *opts);
int git_diff_tree_to_workdir(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	const git_diff_options *opts);
int git_diff_tree_to_workdir_with_index(
	git_diff **diff,
	git_repository *repo,
	git_tree *old_tree,
	const git_diff_options *opts);
int git_diff_merge(
	git_diff *onto,
	const git_diff *from);
int git_diff_find_similar(
	git_diff *diff,
	const git_diff_find_options *options);
size_t git_diff_num_deltas(const git_diff *diff);
size_t git_diff_num_deltas_of_type(
	const git_diff *diff, git_delta_t type);
const git_diff_delta * git_diff_get_delta(
	const git_diff *diff, size_t idx);
int git_diff_is_sorted_icase(const git_diff *diff);
int git_diff_foreach(
	git_diff *diff,
	git_diff_file_cb file_cb,
	git_diff_hunk_cb hunk_cb,
	git_diff_line_cb line_cb,
	void *payload);
char git_diff_status_char(git_delta_t status);
typedef enum {
	GIT_DIFF_FORMAT_PATCH = 1u,
	GIT_DIFF_FORMAT_PATCH_HEADER = 2u,
	GIT_DIFF_FORMAT_RAW = 3u,
	GIT_DIFF_FORMAT_NAME_ONLY = 4u,
	GIT_DIFF_FORMAT_NAME_STATUS = 5u,
} git_diff_format_t;
int git_diff_print(
	git_diff *diff,
	git_diff_format_t format,
	git_diff_line_cb print_cb,
	void *payload);
int git_diff_blobs(
	const git_blob *old_blob,
	const char *old_as_path,
	const git_blob *new_blob,
	const char *new_as_path,
	const git_diff_options *options,
	git_diff_file_cb file_cb,
	git_diff_hunk_cb hunk_cb,
	git_diff_line_cb line_cb,
	void *payload);
int git_diff_blob_to_buffer(
	const git_blob *old_blob,
	const char *old_as_path,
	const char *buffer,
	size_t buffer_len,
	const char *buffer_as_path,
	const git_diff_options *options,
	git_diff_file_cb file_cb,
	git_diff_hunk_cb hunk_cb,
	git_diff_line_cb line_cb,
	void *payload);
int git_diff_buffers(
	const void *old_buffer,
	size_t old_len,
	const char *old_as_path,
	const void *new_buffer,
	size_t new_len,
	const char *new_as_path,
	const git_diff_options *options,
	git_diff_file_cb file_cb,
	git_diff_hunk_cb hunk_cb,
	git_diff_line_cb line_cb,
	void *payload);
typedef struct git_diff_stats git_diff_stats;
typedef enum {
	GIT_DIFF_STATS_NONE = 0,
	GIT_DIFF_STATS_FULL = (1u << 0),
	GIT_DIFF_STATS_SHORT = (1u << 1),
	GIT_DIFF_STATS_NUMBER = (1u << 2),
	GIT_DIFF_STATS_INCLUDE_SUMMARY = (1u << 3),
} git_diff_stats_format_t;
int git_diff_get_stats(
	git_diff_stats **out,
	git_diff *diff);
size_t git_diff_stats_files_changed(
	const git_diff_stats *stats);
size_t git_diff_stats_insertions(
	const git_diff_stats *stats);
size_t git_diff_stats_deletions(
	const git_diff_stats *stats);
int git_diff_stats_to_buf(
	git_buf *out,
	const git_diff_stats *stats,
	git_diff_stats_format_t format,
	size_t width);
void git_diff_stats_free(git_diff_stats *stats);
typedef enum {
	GIT_DIFF_FORMAT_EMAIL_NONE = 0,
	GIT_DIFF_FORMAT_EMAIL_EXCLUDE_SUBJECT_PATCH_MARKER = (1 << 0),
} git_diff_format_email_flags_t;
typedef struct {
	unsigned int version;
	git_diff_format_email_flags_t flags;
	size_t patch_no;
	size_t total_patches;
	const git_oid *id;
	const char *summary;
	const git_signature *author;
} git_diff_format_email_options;
int git_diff_format_email(
	git_buf *out,
	git_diff *diff,
	const git_diff_format_email_options *opts);
int git_diff_commit_as_email(
	git_buf *out,
	git_repository *repo,
	git_commit *commit,
	size_t patch_no,
	size_t total_patches,
	git_diff_format_email_flags_t flags,
	const git_diff_options *diff_opts);
int git_diff_format_email_init_options(
	git_diff_format_email_options *opts,
	unsigned int version);
typedef enum {
	GIT_CHECKOUT_NONE = 0,
	GIT_CHECKOUT_SAFE = (1u << 0),
	GIT_CHECKOUT_SAFE_CREATE = (1u << 1),
	GIT_CHECKOUT_FORCE = (1u << 2),
	GIT_CHECKOUT_ALLOW_CONFLICTS = (1u << 4),
	GIT_CHECKOUT_REMOVE_UNTRACKED = (1u << 5),
	GIT_CHECKOUT_REMOVE_IGNORED = (1u << 6),
	GIT_CHECKOUT_UPDATE_ONLY = (1u << 7),
	GIT_CHECKOUT_DONT_UPDATE_INDEX = (1u << 8),
	GIT_CHECKOUT_NO_REFRESH = (1u << 9),
	GIT_CHECKOUT_SKIP_UNMERGED = (1u << 10),
	GIT_CHECKOUT_USE_OURS = (1u << 11),
	GIT_CHECKOUT_USE_THEIRS = (1u << 12),
	GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH = (1u << 13),
	GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES = (1u << 18),
	GIT_CHECKOUT_DONT_OVERWRITE_IGNORED = (1u << 19),
	GIT_CHECKOUT_CONFLICT_STYLE_MERGE = (1u << 20),
	GIT_CHECKOUT_CONFLICT_STYLE_DIFF3 = (1u << 21),
	GIT_CHECKOUT_UPDATE_SUBMODULES = (1u << 16),
	GIT_CHECKOUT_UPDATE_SUBMODULES_IF_CHANGED = (1u << 17),
} git_checkout_strategy_t;
typedef enum {
	GIT_CHECKOUT_NOTIFY_NONE = 0,
	GIT_CHECKOUT_NOTIFY_CONFLICT = (1u << 0),
	GIT_CHECKOUT_NOTIFY_DIRTY = (1u << 1),
	GIT_CHECKOUT_NOTIFY_UPDATED = (1u << 2),
	GIT_CHECKOUT_NOTIFY_UNTRACKED = (1u << 3),
	GIT_CHECKOUT_NOTIFY_IGNORED = (1u << 4),
	GIT_CHECKOUT_NOTIFY_ALL = 0x0FFFFu
} git_checkout_notify_t;
typedef int (*git_checkout_notify_cb)(
	git_checkout_notify_t why,
	const char *path,
	const git_diff_file *baseline,
	const git_diff_file *target,
	const git_diff_file *workdir,
	void *payload);
typedef void (*git_checkout_progress_cb)(
	const char *path,
	size_t completed_steps,
	size_t total_steps,
	void *payload);
typedef struct git_checkout_options {
	unsigned int version;
	unsigned int checkout_strategy;
	int disable_filters;
	unsigned int dir_mode;
	unsigned int file_mode;
	int file_open_flags;
	unsigned int notify_flags;
	git_checkout_notify_cb notify_cb;
	void *notify_payload;
	git_checkout_progress_cb progress_cb;
	void *progress_payload;
	git_strarray paths;
	git_tree *baseline;
	const char *target_directory;
	const char *ancestor_label;
	const char *our_label;
	const char *their_label;
} git_checkout_options;
int git_checkout_init_options(
	git_checkout_options *opts,
	unsigned int version);
int git_checkout_head(
	git_repository *repo,
	const git_checkout_options *opts);
int git_checkout_index(
	git_repository *repo,
	git_index *index,
	const git_checkout_options *opts);
int git_checkout_tree(
	git_repository *repo,
	const git_object *treeish,
	const git_checkout_options *opts);
typedef struct git_oidarray {
	git_oid *ids;
	size_t count;
} git_oidarray;
void git_oidarray_free(git_oidarray *array);
typedef struct git_indexer git_indexer;
int git_indexer_new(
	 git_indexer **out,
	 const char *path,
	 unsigned int mode,
	 git_odb *odb,
	 git_transfer_progress_cb progress_cb,
	 void *progress_cb_payload);
int git_indexer_append(git_indexer *idx, const void *data, size_t size, git_transfer_progress *stats);
int git_indexer_commit(git_indexer *idx, git_transfer_progress *stats);
const git_oid * git_indexer_hash(const git_indexer *idx);
void git_indexer_free(git_indexer *idx);
typedef struct {
	git_time_t seconds;
	unsigned int nanoseconds;
} git_index_time;
typedef struct git_index_entry {
	git_index_time ctime;
	git_index_time mtime;
	unsigned int dev;
	unsigned int ino;
	unsigned int mode;
	unsigned int uid;
	unsigned int gid;
	git_off_t file_size;
	git_oid id;
	unsigned short flags;
	unsigned short flags_extended;
	const char *path;
} git_index_entry;
typedef enum {
	GIT_IDXENTRY_EXTENDED = (0x4000),
	GIT_IDXENTRY_VALID = (0x8000),
} git_indxentry_flag_t;
typedef enum {
	GIT_IDXENTRY_INTENT_TO_ADD = (1 << 13),
	GIT_IDXENTRY_SKIP_WORKTREE = (1 << 14),
	GIT_IDXENTRY_EXTENDED2 = (1 << 15),
	GIT_IDXENTRY_EXTENDED_FLAGS = (GIT_IDXENTRY_INTENT_TO_ADD | GIT_IDXENTRY_SKIP_WORKTREE),
	GIT_IDXENTRY_UPDATE = (1 << 0),
	GIT_IDXENTRY_REMOVE = (1 << 1),
	GIT_IDXENTRY_UPTODATE = (1 << 2),
	GIT_IDXENTRY_ADDED = (1 << 3),
	GIT_IDXENTRY_HASHED = (1 << 4),
	GIT_IDXENTRY_UNHASHED = (1 << 5),
	GIT_IDXENTRY_WT_REMOVE = (1 << 6),
	GIT_IDXENTRY_CONFLICTED = (1 << 7),
	GIT_IDXENTRY_UNPACKED = (1 << 8),
	GIT_IDXENTRY_NEW_SKIP_WORKTREE = (1 << 9),
} git_idxentry_extended_flag_t;
typedef enum {
	GIT_INDEXCAP_IGNORE_CASE = 1,
	GIT_INDEXCAP_NO_FILEMODE = 2,
	GIT_INDEXCAP_NO_SYMLINKS = 4,
	GIT_INDEXCAP_FROM_OWNER = -1,
} git_indexcap_t;
typedef int (*git_index_matched_path_cb)(
	const char *path, const char *matched_pathspec, void *payload);
typedef enum {
	GIT_INDEX_ADD_DEFAULT = 0,
	GIT_INDEX_ADD_FORCE = (1u << 0),
	GIT_INDEX_ADD_DISABLE_PATHSPEC_MATCH = (1u << 1),
	GIT_INDEX_ADD_CHECK_PATHSPEC = (1u << 2),
} git_index_add_option_t;
int git_index_open(git_index **out, const char *index_path);
int git_index_new(git_index **out);
void git_index_free(git_index *index);
git_repository * git_index_owner(const git_index *index);
int git_index_caps(const git_index *index);
int git_index_set_caps(git_index *index, int caps);
int git_index_read(git_index *index, int force);
int git_index_write(git_index *index);
const char * git_index_path(const git_index *index);
int git_index_read_tree(git_index *index, const git_tree *tree);
int git_index_write_tree(git_oid *out, git_index *index);
int git_index_write_tree_to(git_oid *out, git_index *index, git_repository *repo);
size_t git_index_entrycount(const git_index *index);
int git_index_clear(git_index *index);
const git_index_entry * git_index_get_byindex(
	git_index *index, size_t n);
const git_index_entry * git_index_get_bypath(
	git_index *index, const char *path, int stage);
int git_index_remove(git_index *index, const char *path, int stage);
int git_index_remove_directory(
	git_index *index, const char *dir, int stage);
int git_index_add(git_index *index, const git_index_entry *source_entry);
int git_index_entry_stage(const git_index_entry *entry);
int git_index_add_bypath(git_index *index, const char *path);
int git_index_remove_bypath(git_index *index, const char *path);
int git_index_add_all(
	git_index *index,
	const git_strarray *pathspec,
	unsigned int flags,
	git_index_matched_path_cb callback,
	void *payload);
int git_index_remove_all(
	git_index *index,
	const git_strarray *pathspec,
	git_index_matched_path_cb callback,
	void *payload);
int git_index_update_all(
	git_index *index,
	const git_strarray *pathspec,
	git_index_matched_path_cb callback,
	void *payload);
int git_index_find(size_t *at_pos, git_index *index, const char *path);
int git_index_conflict_add(
	git_index *index,
	const git_index_entry *ancestor_entry,
	const git_index_entry *our_entry,
	const git_index_entry *their_entry);
int git_index_conflict_get(
	const git_index_entry **ancestor_out,
	const git_index_entry **our_out,
	const git_index_entry **their_out,
	git_index *index,
	const char *path);
int git_index_conflict_remove(git_index *index, const char *path);
int git_index_conflict_cleanup(git_index *index);
int git_index_has_conflicts(const git_index *index);
int git_index_conflict_iterator_new(
	git_index_conflict_iterator **iterator_out,
	git_index *index);
int git_index_conflict_next(
	const git_index_entry **ancestor_out,
	const git_index_entry **our_out,
	const git_index_entry **their_out,
	git_index_conflict_iterator *iterator);
void git_index_conflict_iterator_free(
	git_index_conflict_iterator *iterator);
typedef struct {
	unsigned int version;
	const char *ptr;
	size_t size;
	const char *path;
	unsigned int mode;
} git_merge_file_input;
int git_merge_file_init_input(
	git_merge_file_input *opts,
	unsigned int version);
typedef enum {
	GIT_MERGE_TREE_FIND_RENAMES = (1 << 0),
} git_merge_tree_flag_t;
typedef enum {
	GIT_MERGE_FILE_FAVOR_NORMAL = 0,
	GIT_MERGE_FILE_FAVOR_OURS = 1,
	GIT_MERGE_FILE_FAVOR_THEIRS = 2,
	GIT_MERGE_FILE_FAVOR_UNION = 3,
} git_merge_file_favor_t;
typedef enum {
	GIT_MERGE_FILE_DEFAULT = 0,
	GIT_MERGE_FILE_STYLE_MERGE = (1 << 0),
	GIT_MERGE_FILE_STYLE_DIFF3 = (1 << 1),
	GIT_MERGE_FILE_SIMPLIFY_ALNUM = (1 << 2),
} git_merge_file_flags_t;
typedef struct {
	unsigned int version;
	const char *ancestor_label;
	const char *our_label;
	const char *their_label;
	git_merge_file_favor_t favor;
	git_merge_file_flags_t flags;
} git_merge_file_options;
int git_merge_file_init_options(
	git_merge_file_options *opts,
	unsigned int version);
typedef struct {
	unsigned int automergeable;
	const char *path;
	unsigned int mode;
	const char *ptr;
	size_t len;
} git_merge_file_result;
typedef struct {
	unsigned int version;
	git_merge_tree_flag_t flags;
	unsigned int rename_threshold;
	unsigned int target_limit;
	git_diff_similarity_metric *metric;
	git_merge_file_favor_t file_favor;
} git_merge_options;
int git_merge_init_options(
	git_merge_options *opts,
	unsigned int version);
typedef enum {
	GIT_MERGE_ANALYSIS_NONE = 0,
	GIT_MERGE_ANALYSIS_NORMAL = (1 << 0),
	GIT_MERGE_ANALYSIS_UP_TO_DATE = (1 << 1),
	GIT_MERGE_ANALYSIS_FASTFORWARD = (1 << 2),
	GIT_MERGE_ANALYSIS_UNBORN = (1 << 3),
} git_merge_analysis_t;
typedef enum {
	GIT_MERGE_PREFERENCE_NONE = 0,
	GIT_MERGE_PREFERENCE_NO_FASTFORWARD = (1 << 0),
	GIT_MERGE_PREFERENCE_FASTFORWARD_ONLY = (1 << 1),
} git_merge_preference_t;
int git_merge_analysis(
	git_merge_analysis_t *analysis_out,
	git_merge_preference_t *preference_out,
	git_repository *repo,
	const git_annotated_commit **their_heads,
	size_t their_heads_len);
int git_merge_base(
	git_oid *out,
	git_repository *repo,
	const git_oid *one,
	const git_oid *two);
int git_merge_bases(
	git_oidarray *out,
	git_repository *repo,
	const git_oid *one,
	const git_oid *two);
int git_merge_base_many(
	git_oid *out,
	git_repository *repo,
	size_t length,
	const git_oid input_array[]);
int git_merge_bases_many(
	git_oidarray *out,
	git_repository *repo,
	size_t length,
	const git_oid input_array[]);
int git_merge_base_octopus(
	git_oid *out,
	git_repository *repo,
	size_t length,
	const git_oid input_array[]);
int git_merge_file(
	git_merge_file_result *out,
	const git_merge_file_input *ancestor,
	const git_merge_file_input *ours,
	const git_merge_file_input *theirs,
	const git_merge_file_options *opts);
int git_merge_file_from_index(
	git_merge_file_result *out,
	git_repository *repo,
	const git_index_entry *ancestor,
	const git_index_entry *ours,
	const git_index_entry *theirs,
	const git_merge_file_options *opts);
void git_merge_file_result_free(git_merge_file_result *result);
int git_merge_trees(
	git_index **out,
	git_repository *repo,
	const git_tree *ancestor_tree,
	const git_tree *our_tree,
	const git_tree *their_tree,
	const git_merge_options *opts);
int git_merge_commits(
	git_index **out,
	git_repository *repo,
	const git_commit *our_commit,
	const git_commit *their_commit,
	const git_merge_options *opts);
int git_merge(
	git_repository *repo,
	const git_annotated_commit **their_heads,
	size_t their_heads_len,
	const git_merge_options *merge_opts,
	const git_checkout_options *checkout_opts);
typedef struct {
	unsigned int version;
	unsigned int mainline;
	git_merge_options merge_opts;
	git_checkout_options checkout_opts;
} git_cherrypick_options;
int git_cherrypick_init_options(
	git_cherrypick_options *opts,
	unsigned int version);
int git_cherrypick_commit(
	git_index **out,
	git_repository *repo,
	git_commit *cherrypick_commit,
	git_commit *our_commit,
	unsigned int mainline,
	const git_merge_options *merge_options);
int git_cherrypick(
	git_repository *repo,
	git_commit *commit,
	const git_cherrypick_options *cherrypick_options);
typedef enum {
	GIT_DIRECTION_FETCH = 0,
	GIT_DIRECTION_PUSH = 1
} git_direction;
struct git_remote_head {
	int local;
	git_oid oid;
	git_oid loid;
	char *name;
	char *symref_target;
};
typedef int (*git_headlist_cb)(git_remote_head *rhead, void *payload);
const char * git_refspec_src(const git_refspec *refspec);
const char * git_refspec_dst(const git_refspec *refspec);
const char * git_refspec_string(const git_refspec *refspec);
int git_refspec_force(const git_refspec *refspec);
git_direction git_refspec_direction(const git_refspec *spec);
int git_refspec_src_matches(const git_refspec *refspec, const char *refname);
int git_refspec_dst_matches(const git_refspec *refspec, const char *refname);
int git_refspec_transform(git_buf *out, const git_refspec *spec, const char *name);
int git_refspec_rtransform(git_buf *out, const git_refspec *spec, const char *name);
typedef enum {
	GIT_CERT_SSH_MD5 = (1 << 0),
	GIT_CERT_SSH_SHA1 = (1 << 1),
} git_cert_ssh_t;
typedef struct {
	git_cert_t cert_type;
	git_cert_ssh_t type;
	unsigned char hash_md5[16];
	       unsigned char hash_sha1[20];
} git_cert_hostkey;
typedef struct {
	git_cert_t cert_type;
	void *data;
	size_t len;
} git_cert_x509;
typedef enum {
	GIT_CREDTYPE_USERPASS_PLAINTEXT = (1u << 0),
	GIT_CREDTYPE_SSH_KEY = (1u << 1),
	GIT_CREDTYPE_SSH_CUSTOM = (1u << 2),
	GIT_CREDTYPE_DEFAULT = (1u << 3),
	GIT_CREDTYPE_SSH_INTERACTIVE = (1u << 4),
	GIT_CREDTYPE_USERNAME = (1u << 5),
} git_credtype_t;
typedef struct git_cred git_cred;
struct git_cred {
	git_credtype_t credtype;
	void (*free)(git_cred *cred);
};
typedef struct {
	git_cred parent;
	char *username;
	char *password;
} git_cred_userpass_plaintext;
typedef struct _LIBSSH2_SESSION LIBSSH2_SESSION;
typedef struct _LIBSSH2_USERAUTH_KBDINT_PROMPT LIBSSH2_USERAUTH_KBDINT_PROMPT;
typedef struct _LIBSSH2_USERAUTH_KBDINT_RESPONSE LIBSSH2_USERAUTH_KBDINT_RESPONSE;
typedef int (*git_cred_sign_callback)(LIBSSH2_SESSION *session, unsigned char **sig, size_t *sig_len, const unsigned char *data, size_t data_len, void **abstract);
typedef void (*git_cred_ssh_interactive_callback)(const char* name, int name_len, const char* instruction, int instruction_len, int num_prompts, const LIBSSH2_USERAUTH_KBDINT_PROMPT* prompts, LIBSSH2_USERAUTH_KBDINT_RESPONSE* responses, void **abstract);
typedef struct git_cred_ssh_key {
	git_cred parent;
	char *username;
	char *publickey;
	char *privatekey;
	char *passphrase;
} git_cred_ssh_key;
typedef struct git_cred_ssh_interactive {
	git_cred parent;
	char *username;
	git_cred_ssh_interactive_callback prompt_callback;
	void *payload;
} git_cred_ssh_interactive;
typedef struct git_cred_ssh_custom {
	git_cred parent;
	char *username;
	char *publickey;
	size_t publickey_len;
	git_cred_sign_callback sign_callback;
	void *payload;
} git_cred_ssh_custom;
typedef struct git_cred git_cred_default;
typedef struct git_cred_username {
	git_cred parent;
	char username[1];
} git_cred_username;
int git_cred_has_username(git_cred *cred);
int git_cred_userpass_plaintext_new(
	git_cred **out,
	const char *username,
	const char *password);
int git_cred_ssh_key_new(
	git_cred **out,
	const char *username,
	const char *publickey,
	const char *privatekey,
	const char *passphrase);
int git_cred_ssh_interactive_new(
	git_cred **out,
	const char *username,
	git_cred_ssh_interactive_callback prompt_callback,
	void *payload);
int git_cred_ssh_key_from_agent(
	git_cred **out,
	const char *username);
int git_cred_ssh_custom_new(
	git_cred **out,
	const char *username,
	const char *publickey,
	size_t publickey_len,
	git_cred_sign_callback sign_callback,
	void *payload);
int git_cred_default_new(git_cred **out);
int git_cred_username_new(git_cred **cred, const char *username);
typedef int (*git_cred_acquire_cb)(
	git_cred **cred,
	const char *url,
	const char *username_from_url,
	unsigned int allowed_types,
	void *payload);
typedef enum {
	GIT_PACKBUILDER_ADDING_OBJECTS = 0,
	GIT_PACKBUILDER_DELTAFICATION = 1,
} git_packbuilder_stage_t;
int git_packbuilder_new(git_packbuilder **out, git_repository *repo);
unsigned int git_packbuilder_set_threads(git_packbuilder *pb, unsigned int n);
int git_packbuilder_insert(git_packbuilder *pb, const git_oid *id, const char *name);
int git_packbuilder_insert_tree(git_packbuilder *pb, const git_oid *id);
int git_packbuilder_insert_commit(git_packbuilder *pb, const git_oid *id);
int git_packbuilder_write_buf(git_buf *buf, git_packbuilder *pb);
int git_packbuilder_write(
	git_packbuilder *pb,
	const char *path,
	unsigned int mode,
	git_transfer_progress_cb progress_cb,
	void *progress_cb_payload);
const git_oid * git_packbuilder_hash(git_packbuilder *pb);
typedef int (*git_packbuilder_foreach_cb)(void *buf, size_t size, void *payload);
int git_packbuilder_foreach(git_packbuilder *pb, git_packbuilder_foreach_cb cb, void *payload);
uint32_t git_packbuilder_object_count(git_packbuilder *pb);
uint32_t git_packbuilder_written(git_packbuilder *pb);
typedef int (*git_packbuilder_progress)(
	int stage,
	unsigned int current,
	unsigned int total,
	void *payload);
int git_packbuilder_set_callbacks(
	git_packbuilder *pb,
	git_packbuilder_progress progress_cb,
	void *progress_cb_payload);
void git_packbuilder_free(git_packbuilder *pb);
typedef struct {
	unsigned int version;
	unsigned int pb_parallelism;
} git_push_options;
int git_push_init_options(
	git_push_options *opts,
	unsigned int version);
typedef int (*git_push_transfer_progress)(
	unsigned int current,
	unsigned int total,
	size_t bytes,
	void* payload);
typedef int (*git_remote_rename_problem_cb)(const char *problematic_refspec, void *payload);
int git_remote_create(
	 git_remote **out,
	 git_repository *repo,
	 const char *name,
	 const char *url);
int git_remote_create_with_fetchspec(
	 git_remote **out,
	 git_repository *repo,
	 const char *name,
	 const char *url,
	 const char *fetch);
int git_remote_create_anonymous(
	 git_remote **out,
	 git_repository *repo,
	 const char *url,
	 const char *fetch);
int git_remote_lookup(git_remote **out, git_repository *repo, const char *name);
int git_remote_save(const git_remote *remote);
int git_remote_dup(git_remote **dest, git_remote *source);
git_repository * git_remote_owner(const git_remote *remote);
const char * git_remote_name(const git_remote *remote);
const char * git_remote_url(const git_remote *remote);
const char * git_remote_pushurl(const git_remote *remote);
int git_remote_set_url(git_remote *remote, const char* url);
int git_remote_set_pushurl(git_remote *remote, const char* url);
int git_remote_add_fetch(git_remote *remote, const char *refspec);
int git_remote_get_fetch_refspecs(git_strarray *array, const git_remote *remote);
int git_remote_set_fetch_refspecs(git_remote *remote, git_strarray *array);
int git_remote_add_push(git_remote *remote, const char *refspec);
int git_remote_get_push_refspecs(git_strarray *array, const git_remote *remote);
int git_remote_set_push_refspecs(git_remote *remote, git_strarray *array);
void git_remote_clear_refspecs(git_remote *remote);
size_t git_remote_refspec_count(const git_remote *remote);
const git_refspec *git_remote_get_refspec(const git_remote *remote, size_t n);
int git_remote_connect(git_remote *remote, git_direction direction);
int git_remote_ls(const git_remote_head ***out, size_t *size, git_remote *remote);
int git_remote_download(git_remote *remote, const git_strarray *refspecs);
int git_remote_upload(git_remote *remote, const git_strarray *refspecs, const git_push_options *opts);
int git_remote_connected(const git_remote *remote);
void git_remote_stop(git_remote *remote);
void git_remote_disconnect(git_remote *remote);
void git_remote_free(git_remote *remote);
int git_remote_update_tips(
	 git_remote *remote,
	 const git_signature *signature,
	 const char *reflog_message);
int git_remote_prune(git_remote *remote);
int git_remote_fetch(
	 git_remote *remote,
	 const git_strarray *refspecs,
	 const git_signature *signature,
	 const char *reflog_message);
int git_remote_push(git_remote *remote,
	   const git_strarray *refspecs,
	   const git_push_options *opts,
	   const git_signature *signature, const char *reflog_message);
int git_remote_list(git_strarray *out, git_repository *repo);
typedef enum git_remote_completion_type {
	GIT_REMOTE_COMPLETION_DOWNLOAD,
	GIT_REMOTE_COMPLETION_INDEXING,
	GIT_REMOTE_COMPLETION_ERROR,
} git_remote_completion_type;
struct git_remote_callbacks {
	unsigned int version;
	git_transport_message_cb sideband_progress;
	int (*completion)(git_remote_completion_type type, void *data);
	git_cred_acquire_cb credentials;
	       git_transport_certificate_check_cb certificate_check;
	git_transfer_progress_cb transfer_progress;
	int (*update_tips)(const char *refname, const git_oid *a, const git_oid *b, void *data);
	git_packbuilder_progress pack_progress;
	git_push_transfer_progress push_transfer_progress;
	int (*push_update_reference)(const char *refname, const char *status, void *data);
	void *payload;
};
int git_remote_init_callbacks(
	git_remote_callbacks *opts,
	unsigned int version);
int git_remote_set_callbacks(git_remote *remote, const git_remote_callbacks *callbacks);
const git_remote_callbacks * git_remote_get_callbacks(git_remote *remote);
const git_transfer_progress * git_remote_stats(git_remote *remote);
typedef enum {
	GIT_REMOTE_DOWNLOAD_TAGS_AUTO = 0,
	GIT_REMOTE_DOWNLOAD_TAGS_NONE = 1,
	GIT_REMOTE_DOWNLOAD_TAGS_ALL = 2
} git_remote_autotag_option_t;
git_remote_autotag_option_t git_remote_autotag(const git_remote *remote);
void git_remote_set_autotag(
	git_remote *remote,
	git_remote_autotag_option_t value);
int git_remote_prune_refs(const git_remote *remote);
int git_remote_rename(
	git_strarray *problems,
	git_repository *repo,
	const char *name,
	const char *new_name);
int git_remote_update_fetchhead(git_remote *remote);
void git_remote_set_update_fetchhead(git_remote *remote, int value);
int git_remote_is_valid_name(const char *remote_name);
int git_remote_delete(git_repository *repo, const char *name);
int git_remote_default_branch(git_buf *out, git_remote *remote);
typedef enum {
	GIT_CLONE_LOCAL_AUTO,
	GIT_CLONE_LOCAL,
	GIT_CLONE_NO_LOCAL,
	GIT_CLONE_LOCAL_NO_LINKS,
} git_clone_local_t;
typedef int (*git_remote_create_cb)(
	git_remote **out,
	git_repository *repo,
	const char *name,
	const char *url,
	void *payload);
typedef int (*git_repository_create_cb)(
	git_repository **out,
	const char *path,
	int bare,
	void *payload);
typedef struct git_clone_options {
	unsigned int version;
	git_checkout_options checkout_opts;
	git_remote_callbacks remote_callbacks;
	int bare;
	git_clone_local_t local;
	const char* checkout_branch;
	git_signature *signature;
	git_repository_create_cb repository_cb;
	void *repository_cb_payload;
	git_remote_create_cb remote_cb;
	void *remote_cb_payload;
} git_clone_options;
int git_clone_init_options(
	git_clone_options *opts,
	unsigned int version);
int git_clone(
	git_repository **out,
	const char *url,
	const char *local_path,
	const git_clone_options *options);
int git_commit_lookup(
	git_commit **commit, git_repository *repo, const git_oid *id);
int git_commit_lookup_prefix(
	git_commit **commit, git_repository *repo, const git_oid *id, size_t len);
void git_commit_free(git_commit *commit);
const git_oid * git_commit_id(const git_commit *commit);
git_repository * git_commit_owner(const git_commit *commit);
const char * git_commit_message_encoding(const git_commit *commit);
const char * git_commit_message(const git_commit *commit);
const char * git_commit_message_raw(const git_commit *commit);
const char * git_commit_summary(git_commit *commit);
git_time_t git_commit_time(const git_commit *commit);
int git_commit_time_offset(const git_commit *commit);
const git_signature * git_commit_committer(const git_commit *commit);
const git_signature * git_commit_author(const git_commit *commit);
const char * git_commit_raw_header(const git_commit *commit);
int git_commit_tree(git_tree **tree_out, const git_commit *commit);
const git_oid * git_commit_tree_id(const git_commit *commit);
unsigned int git_commit_parentcount(const git_commit *commit);
int git_commit_parent(
	git_commit **out,
	const git_commit *commit,
	unsigned int n);
const git_oid * git_commit_parent_id(
	const git_commit *commit,
	unsigned int n);
int git_commit_nth_gen_ancestor(
	git_commit **ancestor,
	const git_commit *commit,
	unsigned int n);
int git_commit_create(
	git_oid *id,
	git_repository *repo,
	const char *update_ref,
	const git_signature *author,
	const git_signature *committer,
	const char *message_encoding,
	const char *message,
	const git_tree *tree,
	size_t parent_count,
	const git_commit *parents[]);
int git_commit_create_v(
	git_oid *id,
	git_repository *repo,
	const char *update_ref,
	const git_signature *author,
	const git_signature *committer,
	const char *message_encoding,
	const char *message,
	const git_tree *tree,
	size_t parent_count,
	...);
int git_commit_amend(
	git_oid *id,
	const git_commit *commit_to_amend,
	const char *update_ref,
	const git_signature *author,
	const git_signature *committer,
	const char *message_encoding,
	const char *message,
	const git_tree *tree);
typedef enum {
	GIT_CONFIG_LEVEL_SYSTEM = 1,
	GIT_CONFIG_LEVEL_XDG = 2,
	GIT_CONFIG_LEVEL_GLOBAL = 3,
	GIT_CONFIG_LEVEL_LOCAL = 4,
	GIT_CONFIG_LEVEL_APP = 5,
	GIT_CONFIG_HIGHEST_LEVEL = -1,
} git_config_level_t;
typedef struct {
	const char *name;
	const char *value;
	git_config_level_t level;
} git_config_entry;
typedef int (*git_config_foreach_cb)(const git_config_entry *, void *);
typedef struct git_config_iterator git_config_iterator;
typedef enum {
	GIT_CVAR_FALSE = 0,
	GIT_CVAR_TRUE = 1,
	GIT_CVAR_INT32,
	GIT_CVAR_STRING
} git_cvar_t;
typedef struct {
	git_cvar_t cvar_type;
	const char *str_match;
	int map_value;
} git_cvar_map;
int git_config_find_global(git_buf *out);
int git_config_find_xdg(git_buf *out);
int git_config_find_system(git_buf *out);
int git_config_open_default(git_config **out);
int git_config_new(git_config **out);
int git_config_add_file_ondisk(
	git_config *cfg,
	const char *path,
	git_config_level_t level,
	int force);
int git_config_open_ondisk(git_config **out, const char *path);
int git_config_open_level(
	git_config **out,
	const git_config *parent,
	git_config_level_t level);
int git_config_open_global(git_config **out, git_config *config);
int git_config_snapshot(git_config **out, git_config *config);
void git_config_free(git_config *cfg);
int git_config_get_entry(
	const git_config_entry **out,
	const git_config *cfg,
	const char *name);
int git_config_get_int32(int32_t *out, const git_config *cfg, const char *name);
int git_config_get_int64(int64_t *out, const git_config *cfg, const char *name);
int git_config_get_bool(int *out, const git_config *cfg, const char *name);
int git_config_get_string(const char **out, const git_config *cfg, const char *name);
int git_config_get_multivar_foreach(const git_config *cfg, const char *name, const char *regexp, git_config_foreach_cb callback, void *payload);
int git_config_multivar_iterator_new(git_config_iterator **out, const git_config *cfg, const char *name, const char *regexp);
int git_config_next(git_config_entry **entry, git_config_iterator *iter);
void git_config_iterator_free(git_config_iterator *iter);
int git_config_set_int32(git_config *cfg, const char *name, int32_t value);
int git_config_set_int64(git_config *cfg, const char *name, int64_t value);
int git_config_set_bool(git_config *cfg, const char *name, int value);
int git_config_set_string(git_config *cfg, const char *name, const char *value);
int git_config_set_multivar(git_config *cfg, const char *name, const char *regexp, const char *value);
int git_config_delete_entry(git_config *cfg, const char *name);
int git_config_delete_multivar(git_config *cfg, const char *name, const char *regexp);
int git_config_foreach(
	const git_config *cfg,
	git_config_foreach_cb callback,
	void *payload);
int git_config_iterator_new(git_config_iterator **out, const git_config *cfg);
int git_config_iterator_glob_new(git_config_iterator **out, const git_config *cfg, const char *regexp);
int git_config_foreach_match(
	const git_config *cfg,
	const char *regexp,
	git_config_foreach_cb callback,
	void *payload);
int git_config_get_mapped(
	int *out,
	const git_config *cfg,
	const char *name,
	const git_cvar_map *maps,
	size_t map_n);
int git_config_lookup_map_value(
	int *out,
	const git_cvar_map *maps,
	size_t map_n,
	const char *value);
int git_config_parse_bool(int *out, const char *value);
int git_config_parse_int32(int32_t *out, const char *value);
int git_config_parse_int64(int64_t *out, const char *value);
int git_config_backend_foreach_match(
	git_config_backend *backend,
	const char *regexp,
	git_config_foreach_cb callback,
	void *payload);
typedef enum {
	GIT_DESCRIBE_DEFAULT,
	GIT_DESCRIBE_TAGS,
	GIT_DESCRIBE_ALL,
} git_describe_strategy_t;
typedef struct git_describe_options {
	unsigned int version;
	unsigned int max_candidates_tags;
	unsigned int describe_strategy;
	const char *pattern;
	int only_follow_first_parent;
	int show_commit_oid_as_fallback;
} git_describe_options;
int git_describe_init_options(git_describe_options *opts, unsigned int version);
typedef struct {
	unsigned int version;
	unsigned int abbreviated_size;
	int always_use_long_format;
	char *dirty_suffix;
} git_describe_format_options;
int git_describe_init_format_options(git_describe_format_options *opts, unsigned int version);
typedef struct git_describe_result git_describe_result;
int git_describe_commit(
	git_describe_result **result,
	git_object *committish,
	git_describe_options *opts);
int git_describe_workdir(
	git_describe_result **out,
	git_repository *repo,
	git_describe_options *opts);
int git_describe_format(
	git_buf *out,
	const git_describe_result *result,
	const git_describe_format_options *opts);
void git_describe_result_free(git_describe_result *result);
typedef enum {
	GIT_OK = 0,
	GIT_ERROR = -1,
	GIT_ENOTFOUND = -3,
	GIT_EEXISTS = -4,
	GIT_EAMBIGUOUS = -5,
	GIT_EBUFS = -6,
	GIT_EUSER = -7,
	GIT_EBAREREPO = -8,
	GIT_EUNBORNBRANCH = -9,
	GIT_EUNMERGED = -10,
	GIT_ENONFASTFORWARD = -11,
	GIT_EINVALIDSPEC = -12,
	GIT_EMERGECONFLICT = -13,
	GIT_ELOCKED = -14,
	GIT_EMODIFIED = -15,
	GIT_EAUTH = -16,
	GIT_ECERTIFICATE = -17,
	GIT_EAPPLIED = -18,
	GIT_EPEEL = -19,
	GIT_PASSTHROUGH = -30,
	GIT_ITEROVER = -31,
} git_error_code;
typedef struct {
	char *message;
	int klass;
} git_error;
typedef enum {
	GITERR_NONE = 0,
	GITERR_NOMEMORY,
	GITERR_OS,
	GITERR_INVALID,
	GITERR_REFERENCE,
	GITERR_ZLIB,
	GITERR_REPOSITORY,
	GITERR_CONFIG,
	GITERR_REGEX,
	GITERR_ODB,
	GITERR_INDEX,
	GITERR_OBJECT,
	GITERR_NET,
	GITERR_TAG,
	GITERR_TREE,
	GITERR_INDEXER,
	GITERR_SSL,
	GITERR_SUBMODULE,
	GITERR_THREAD,
	GITERR_STASH,
	GITERR_CHECKOUT,
	GITERR_FETCHHEAD,
	GITERR_MERGE,
	GITERR_SSH,
	GITERR_FILTER,
	GITERR_REVERT,
	GITERR_CALLBACK,
	GITERR_CHERRYPICK,
	GITERR_DESCRIBE,
	GITERR_REBASE,
} git_error_t;
const git_error * giterr_last(void);
void giterr_clear(void);
int giterr_detach(git_error *cpy);
void giterr_set_str(int error_class, const char *string);
void giterr_set_oom(void);
typedef enum {
	GIT_FILTER_TO_WORKTREE = 0,
	GIT_FILTER_SMUDGE = GIT_FILTER_TO_WORKTREE,
	GIT_FILTER_TO_ODB = 1,
	GIT_FILTER_CLEAN = GIT_FILTER_TO_ODB,
} git_filter_mode_t;
typedef enum {
	GIT_FILTER_OPT_DEFAULT = 0u,
	GIT_FILTER_OPT_ALLOW_UNSAFE = (1u << 0),
} git_filter_opt_t;
typedef struct git_filter git_filter;
typedef struct git_filter_list git_filter_list;
int git_filter_list_load(
	git_filter_list **filters,
	git_repository *repo,
	git_blob *blob,
	const char *path,
	git_filter_mode_t mode,
	uint32_t options);
int git_filter_list_apply_to_data(
	git_buf *out,
	git_filter_list *filters,
	git_buf *in);
int git_filter_list_apply_to_file(
	git_buf *out,
	git_filter_list *filters,
	git_repository *repo,
	const char *path);
int git_filter_list_apply_to_blob(
	git_buf *out,
	git_filter_list *filters,
	git_blob *blob);
void git_filter_list_free(git_filter_list *filters);
int git_libgit2_init(void);
int git_libgit2_shutdown(void);
int git_graph_ahead_behind(size_t *ahead, size_t *behind, git_repository *repo, const git_oid *local, const git_oid *upstream);
int git_graph_descendant_of(
	git_repository *repo,
	const git_oid *commit,
	const git_oid *ancestor);
int git_ignore_add_rule(
	git_repository *repo,
	const char *rules);
int git_ignore_clear_internal_rules(
	git_repository *repo);
int git_ignore_path_is_ignored(
	int *ignored,
	git_repository *repo,
	const char *path);
int git_message_prettify(git_buf *out, const char *message, int strip_comments, char comment_char);
typedef int (*git_note_foreach_cb)(
	const git_oid *blob_id, const git_oid *annotated_object_id, void *payload);
typedef struct git_iterator git_note_iterator;
int git_note_iterator_new(
	git_note_iterator **out,
	git_repository *repo,
	const char *notes_ref);
void git_note_iterator_free(git_note_iterator *it);
int git_note_next(
	git_oid* note_id,
	git_oid* annotated_id,
	git_note_iterator *it);
int git_note_read(
	git_note **out,
	git_repository *repo,
	const char *notes_ref,
	const git_oid *oid);
const git_signature * git_note_author(const git_note *note);
const git_signature * git_note_committer(const git_note *note);
const char * git_note_message(const git_note *note);
const git_oid * git_note_id(const git_note *note);
int git_note_create(
	git_oid *out,
	git_repository *repo,
	const char *notes_ref,
	const git_signature *author,
	const git_signature *committer,
	const git_oid *oid,
	const char *note,
	int force);
int git_note_remove(
	git_repository *repo,
	const char *notes_ref,
	const git_signature *author,
	const git_signature *committer,
	const git_oid *oid);
void git_note_free(git_note *note);
int git_note_default_ref(const char **out, git_repository *repo);
int git_note_foreach(
	git_repository *repo,
	const char *notes_ref,
	git_note_foreach_cb note_cb,
	void *payload);
typedef int (*git_odb_foreach_cb)(const git_oid *id, void *payload);
int git_odb_new(git_odb **out);
int git_odb_open(git_odb **out, const char *objects_dir);
int git_odb_add_disk_alternate(git_odb *odb, const char *path);
void git_odb_free(git_odb *db);
int git_odb_read(git_odb_object **out, git_odb *db, const git_oid *id);
int git_odb_read_prefix(git_odb_object **out, git_odb *db, const git_oid *short_id, size_t len);
int git_odb_read_header(size_t *len_out, git_otype *type_out, git_odb *db, const git_oid *id);
int git_odb_exists(git_odb *db, const git_oid *id);
int git_odb_exists_prefix(
	git_oid *out, git_odb *db, const git_oid *short_id, size_t len);
int git_odb_refresh(struct git_odb *db);
int git_odb_foreach(git_odb *db, git_odb_foreach_cb cb, void *payload);
int git_odb_write(git_oid *out, git_odb *odb, const void *data, size_t len, git_otype type);
int git_odb_open_wstream(git_odb_stream **out, git_odb *db, size_t size, git_otype type);
int git_odb_stream_write(git_odb_stream *stream, const char *buffer, size_t len);
int git_odb_stream_finalize_write(git_oid *out, git_odb_stream *stream);
int git_odb_stream_read(git_odb_stream *stream, char *buffer, size_t len);
void git_odb_stream_free(git_odb_stream *stream);
int git_odb_open_rstream(git_odb_stream **out, git_odb *db, const git_oid *oid);
int git_odb_write_pack(
	git_odb_writepack **out,
	git_odb *db,
	git_transfer_progress_cb progress_cb,
	void *progress_payload);
int git_odb_hash(git_oid *out, const void *data, size_t len, git_otype type);
int git_odb_hashfile(git_oid *out, const char *path, git_otype type);
int git_odb_object_dup(git_odb_object **dest, git_odb_object *source);
void git_odb_object_free(git_odb_object *object);
const git_oid * git_odb_object_id(git_odb_object *object);
const void * git_odb_object_data(git_odb_object *object);
size_t git_odb_object_size(git_odb_object *object);
git_otype git_odb_object_type(git_odb_object *object);
int git_odb_add_backend(git_odb *odb, git_odb_backend *backend, int priority);
int git_odb_add_alternate(git_odb *odb, git_odb_backend *backend, int priority);
size_t git_odb_num_backends(git_odb *odb);
int git_odb_get_backend(git_odb_backend **out, git_odb *odb, size_t pos);
int git_odb_backend_pack(git_odb_backend **out, const char *objects_dir);
int git_odb_backend_loose(
	git_odb_backend **out,
	const char *objects_dir,
	int compression_level,
	int do_fsync,
	unsigned int dir_mode,
	unsigned int file_mode);
int git_odb_backend_one_pack(git_odb_backend **out, const char *index_file);
typedef enum {
	GIT_STREAM_RDONLY = (1 << 1),
	GIT_STREAM_WRONLY = (1 << 2),
	GIT_STREAM_RW = (GIT_STREAM_RDONLY | GIT_STREAM_WRONLY),
} git_odb_stream_t;
struct git_odb_stream {
	git_odb_backend *backend;
	unsigned int mode;
	void *hash_ctx;
	size_t declared_size;
	size_t received_bytes;
	int (*read)(git_odb_stream *stream, char *buffer, size_t len);
	int (*write)(git_odb_stream *stream, const char *buffer, size_t len);
	int (*finalize_write)(git_odb_stream *stream, const git_oid *oid);
	void (*free)(git_odb_stream *stream);
};
struct git_odb_writepack {
	git_odb_backend *backend;
	int (*append)(git_odb_writepack *writepack, const void *data, size_t size, git_transfer_progress *stats);
	int (*commit)(git_odb_writepack *writepack, git_transfer_progress *stats);
	void (*free)(git_odb_writepack *writepack);
};
typedef struct git_patch git_patch;
int git_patch_from_diff(
	git_patch **out, git_diff *diff, size_t idx);
int git_patch_from_blobs(
	git_patch **out,
	const git_blob *old_blob,
	const char *old_as_path,
	const git_blob *new_blob,
	const char *new_as_path,
	const git_diff_options *opts);
int git_patch_from_blob_and_buffer(
	git_patch **out,
	const git_blob *old_blob,
	const char *old_as_path,
	const char *buffer,
	size_t buffer_len,
	const char *buffer_as_path,
	const git_diff_options *opts);
int git_patch_from_buffers(
	git_patch **out,
	const void *old_buffer,
	size_t old_len,
	const char *old_as_path,
	const char *new_buffer,
	size_t new_len,
	const char *new_as_path,
	const git_diff_options *opts);
void git_patch_free(git_patch *patch);
const git_diff_delta * git_patch_get_delta(const git_patch *patch);
size_t git_patch_num_hunks(const git_patch *patch);
int git_patch_line_stats(
	size_t *total_context,
	size_t *total_additions,
	size_t *total_deletions,
	const git_patch *patch);
int git_patch_get_hunk(
	const git_diff_hunk **out,
	size_t *lines_in_hunk,
	git_patch *patch,
	size_t hunk_idx);
int git_patch_num_lines_in_hunk(
	const git_patch *patch,
	size_t hunk_idx);
int git_patch_get_line_in_hunk(
	const git_diff_line **out,
	git_patch *patch,
	size_t hunk_idx,
	size_t line_of_hunk);
size_t git_patch_size(
	git_patch *patch,
	int include_context,
	int include_hunk_headers,
	int include_file_headers);
int git_patch_print(
	git_patch *patch,
	git_diff_line_cb print_cb,
	void *payload);
int git_patch_to_buf(
	git_buf *out,
	git_patch *patch);
typedef struct git_pathspec git_pathspec;
typedef struct git_pathspec_match_list git_pathspec_match_list;
typedef enum {
	GIT_PATHSPEC_DEFAULT = 0,
	GIT_PATHSPEC_IGNORE_CASE = (1u << 0),
	GIT_PATHSPEC_USE_CASE = (1u << 1),
	GIT_PATHSPEC_NO_GLOB = (1u << 2),
	GIT_PATHSPEC_NO_MATCH_ERROR = (1u << 3),
	GIT_PATHSPEC_FIND_FAILURES = (1u << 4),
	GIT_PATHSPEC_FAILURES_ONLY = (1u << 5),
} git_pathspec_flag_t;
int git_pathspec_new(
	git_pathspec **out, const git_strarray *pathspec);
void git_pathspec_free(git_pathspec *ps);
int git_pathspec_matches_path(
	const git_pathspec *ps, uint32_t flags, const char *path);
int git_pathspec_match_workdir(
	git_pathspec_match_list **out,
	git_repository *repo,
	uint32_t flags,
	git_pathspec *ps);
int git_pathspec_match_index(
	git_pathspec_match_list **out,
	git_index *index,
	uint32_t flags,
	git_pathspec *ps);
int git_pathspec_match_tree(
	git_pathspec_match_list **out,
	git_tree *tree,
	uint32_t flags,
	git_pathspec *ps);
int git_pathspec_match_diff(
	git_pathspec_match_list **out,
	git_diff *diff,
	uint32_t flags,
	git_pathspec *ps);
void git_pathspec_match_list_free(git_pathspec_match_list *m);
size_t git_pathspec_match_list_entrycount(
	const git_pathspec_match_list *m);
const char * git_pathspec_match_list_entry(
	const git_pathspec_match_list *m, size_t pos);
const git_diff_delta * git_pathspec_match_list_diff_entry(
	const git_pathspec_match_list *m, size_t pos);
size_t git_pathspec_match_list_failed_entrycount(
	const git_pathspec_match_list *m);
const char * git_pathspec_match_list_failed_entry(
	const git_pathspec_match_list *m, size_t pos);
typedef struct {
	unsigned int version;
	int quiet;
	const char *rewrite_notes_ref;
} git_rebase_options;
typedef enum {
	GIT_REBASE_OPERATION_PICK = 0,
	GIT_REBASE_OPERATION_REWORD,
	GIT_REBASE_OPERATION_EDIT,
	GIT_REBASE_OPERATION_SQUASH,
	GIT_REBASE_OPERATION_FIXUP,
	GIT_REBASE_OPERATION_EXEC,
} git_rebase_operation_t;
typedef struct {
	git_rebase_operation_t type;
	const git_oid id;
	const char *exec;
} git_rebase_operation;
int git_rebase_init_options(
	git_rebase_options *opts,
	unsigned int version);
int git_rebase_init(
	git_rebase **out,
	git_repository *repo,
	const git_annotated_commit *branch,
	const git_annotated_commit *upstream,
	const git_annotated_commit *onto,
	const git_signature *signature,
	const git_rebase_options *opts);
int git_rebase_open(git_rebase **out, git_repository *repo);
size_t git_rebase_operation_entrycount(git_rebase *rebase);
size_t git_rebase_operation_current(git_rebase *rebase);
git_rebase_operation * git_rebase_operation_byindex(
	git_rebase *rebase,
	size_t idx);
int git_rebase_next(
	git_rebase_operation **operation,
	git_rebase *rebase,
	git_checkout_options *checkout_opts);
int git_rebase_commit(
	git_oid *id,
	git_rebase *rebase,
	const git_signature *author,
	const git_signature *committer,
	const char *message_encoding,
	const char *message);
int git_rebase_abort(
	git_rebase *rebase,
	const git_signature *signature);
int git_rebase_finish(
	git_rebase *rebase,
	const git_signature *signature,
	const git_rebase_options *opts);
void git_rebase_free(git_rebase *rebase);
int git_refdb_new(git_refdb **out, git_repository *repo);
int git_refdb_open(git_refdb **out, git_repository *repo);
int git_refdb_compress(git_refdb *refdb);
void git_refdb_free(git_refdb *refdb);
int git_reflog_read(git_reflog **out, git_repository *repo, const char *name);
int git_reflog_write(git_reflog *reflog);
int git_reflog_append(git_reflog *reflog, const git_oid *id, const git_signature *committer, const char *msg);
int git_reflog_rename(git_repository *repo, const char *old_name, const char *name);
int git_reflog_delete(git_repository *repo, const char *name);
size_t git_reflog_entrycount(git_reflog *reflog);
const git_reflog_entry * git_reflog_entry_byindex(const git_reflog *reflog, size_t idx);
int git_reflog_drop(
	git_reflog *reflog,
	size_t idx,
	int rewrite_previous_entry);
const git_oid * git_reflog_entry_id_old(const git_reflog_entry *entry);
const git_oid * git_reflog_entry_id_new(const git_reflog_entry *entry);
const git_signature * git_reflog_entry_committer(const git_reflog_entry *entry);
const char * git_reflog_entry_message(const git_reflog_entry *entry);
void git_reflog_free(git_reflog *reflog);
typedef enum {
	GIT_RESET_SOFT = 1,
	GIT_RESET_MIXED = 2,
	GIT_RESET_HARD = 3,
} git_reset_t;
int git_reset(
	git_repository *repo,
	git_object *target,
	git_reset_t reset_type,
	git_checkout_options *checkout_opts,
	const git_signature *signature,
	const char *log_message);
int git_reset_default(
	git_repository *repo,
	git_object *target,
	git_strarray* pathspecs);
typedef struct {
	unsigned int version;
	unsigned int mainline;
	git_merge_options merge_opts;
	git_checkout_options checkout_opts;
} git_revert_options;
int git_revert_init_options(
	git_revert_options *opts,
	unsigned int version);
int git_revert_commit(
	git_index **out,
	git_repository *repo,
	git_commit *revert_commit,
	git_commit *our_commit,
	unsigned int mainline,
	const git_merge_options *merge_options);
int git_revert(
	git_repository *repo,
	git_commit *commit,
	const git_revert_options *given_opts);
int git_revparse_single(
	git_object **out, git_repository *repo, const char *spec);
int git_revparse_ext(
	git_object **object_out,
	git_reference **reference_out,
	git_repository *repo,
	const char *spec);
typedef enum {
	GIT_REVPARSE_SINGLE = 1 << 0,
	GIT_REVPARSE_RANGE = 1 << 1,
	GIT_REVPARSE_MERGE_BASE = 1 << 2,
} git_revparse_mode_t;
typedef struct {
	git_object *from;
	git_object *to;
	unsigned int flags;
} git_revspec;
int git_revparse(
	git_revspec *revspec,
	git_repository *repo,
	const char *spec);
typedef enum {
	GIT_SORT_NONE = 0,
	GIT_SORT_TOPOLOGICAL = 1 << 0,
	GIT_SORT_TIME = 1 << 1,
	GIT_SORT_REVERSE = 1 << 2,
} git_sort_t;
int git_revwalk_new(git_revwalk **out, git_repository *repo);
void git_revwalk_reset(git_revwalk *walker);
int git_revwalk_push(git_revwalk *walk, const git_oid *id);
int git_revwalk_push_glob(git_revwalk *walk, const char *glob);
int git_revwalk_push_head(git_revwalk *walk);
int git_revwalk_hide(git_revwalk *walk, const git_oid *commit_id);
int git_revwalk_hide_glob(git_revwalk *walk, const char *glob);
int git_revwalk_hide_head(git_revwalk *walk);
int git_revwalk_push_ref(git_revwalk *walk, const char *refname);
int git_revwalk_hide_ref(git_revwalk *walk, const char *refname);
int git_revwalk_next(git_oid *out, git_revwalk *walk);
void git_revwalk_sorting(git_revwalk *walk, unsigned int sort_mode);
int git_revwalk_push_range(git_revwalk *walk, const char *range);
void git_revwalk_simplify_first_parent(git_revwalk *walk);
void git_revwalk_free(git_revwalk *walk);
git_repository * git_revwalk_repository(git_revwalk *walk);
typedef int(*git_revwalk_hide_cb)(
	const git_oid *commit_id,
	void *payload);
int git_revwalk_add_hide_cb(
	git_revwalk *walk,
	git_revwalk_hide_cb hide_cb,
	void *payload);
int git_signature_new(git_signature **out, const char *name, const char *email, git_time_t time, int offset);
int git_signature_now(git_signature **out, const char *name, const char *email);
int git_signature_default(git_signature **out, git_repository *repo);
int git_signature_dup(git_signature **dest, const git_signature *sig);
void git_signature_free(git_signature *sig);
typedef enum {
	GIT_STASH_DEFAULT = 0,
	GIT_STASH_KEEP_INDEX = (1 << 0),
	GIT_STASH_INCLUDE_UNTRACKED = (1 << 1),
	GIT_STASH_INCLUDE_IGNORED = (1 << 2),
} git_stash_flags;
int git_stash_save(
	git_oid *out,
	git_repository *repo,
	const git_signature *stasher,
	const char *message,
	unsigned int flags);
typedef int (*git_stash_cb)(
	size_t index,
	const char* message,
	const git_oid *stash_id,
	void *payload);
int git_stash_foreach(
	git_repository *repo,
	git_stash_cb callback,
	void *payload);
int git_stash_drop(
	git_repository *repo,
	size_t index);
typedef enum {
	GIT_STATUS_CURRENT = 0,
	GIT_STATUS_INDEX_NEW = (1u << 0),
	GIT_STATUS_INDEX_MODIFIED = (1u << 1),
	GIT_STATUS_INDEX_DELETED = (1u << 2),
	GIT_STATUS_INDEX_RENAMED = (1u << 3),
	GIT_STATUS_INDEX_TYPECHANGE = (1u << 4),
	GIT_STATUS_WT_NEW = (1u << 7),
	GIT_STATUS_WT_MODIFIED = (1u << 8),
	GIT_STATUS_WT_DELETED = (1u << 9),
	GIT_STATUS_WT_TYPECHANGE = (1u << 10),
	GIT_STATUS_WT_RENAMED = (1u << 11),
	GIT_STATUS_WT_UNREADABLE = (1u << 12),
	GIT_STATUS_IGNORED = (1u << 14),
} git_status_t;
typedef int (*git_status_cb)(
	const char *path, unsigned int status_flags, void *payload);
typedef enum {
	GIT_STATUS_SHOW_INDEX_AND_WORKDIR = 0,
	GIT_STATUS_SHOW_INDEX_ONLY = 1,
	GIT_STATUS_SHOW_WORKDIR_ONLY = 2,
} git_status_show_t;
typedef enum {
	GIT_STATUS_OPT_INCLUDE_UNTRACKED = (1u << 0),
	GIT_STATUS_OPT_INCLUDE_IGNORED = (1u << 1),
	GIT_STATUS_OPT_INCLUDE_UNMODIFIED = (1u << 2),
	GIT_STATUS_OPT_EXCLUDE_SUBMODULES = (1u << 3),
	GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS = (1u << 4),
	GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH = (1u << 5),
	GIT_STATUS_OPT_RECURSE_IGNORED_DIRS = (1u << 6),
	GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX = (1u << 7),
	GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR = (1u << 8),
	GIT_STATUS_OPT_SORT_CASE_SENSITIVELY = (1u << 9),
	GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY = (1u << 10),
	GIT_STATUS_OPT_RENAMES_FROM_REWRITES = (1u << 11),
	GIT_STATUS_OPT_NO_REFRESH = (1u << 12),
	GIT_STATUS_OPT_UPDATE_INDEX = (1u << 13),
	GIT_STATUS_OPT_INCLUDE_UNREADABLE = (1u << 14),
	GIT_STATUS_OPT_INCLUDE_UNREADABLE_AS_UNTRACKED = (1u << 15),
} git_status_opt_t;
typedef struct {
	unsigned int version;
	git_status_show_t show;
	unsigned int flags;
	git_strarray pathspec;
} git_status_options;
int git_status_init_options(
	git_status_options *opts,
	unsigned int version);
typedef struct {
	git_status_t status;
	git_diff_delta *head_to_index;
	git_diff_delta *index_to_workdir;
} git_status_entry;
int git_status_foreach(
	git_repository *repo,
	git_status_cb callback,
	void *payload);
int git_status_foreach_ext(
	git_repository *repo,
	const git_status_options *opts,
	git_status_cb callback,
	void *payload);
int git_status_file(
	unsigned int *status_flags,
	git_repository *repo,
	const char *path);
int git_status_list_new(
	git_status_list **out,
	git_repository *repo,
	const git_status_options *opts);
size_t git_status_list_entrycount(
	git_status_list *statuslist);
const git_status_entry * git_status_byindex(
	git_status_list *statuslist,
	size_t idx);
void git_status_list_free(
	git_status_list *statuslist);
int git_status_should_ignore(
	int *ignored,
	git_repository *repo,
	const char *path);
typedef enum {
	GIT_SUBMODULE_STATUS_IN_HEAD = (1u << 0),
	GIT_SUBMODULE_STATUS_IN_INDEX = (1u << 1),
	GIT_SUBMODULE_STATUS_IN_CONFIG = (1u << 2),
	GIT_SUBMODULE_STATUS_IN_WD = (1u << 3),
	GIT_SUBMODULE_STATUS_INDEX_ADDED = (1u << 4),
	GIT_SUBMODULE_STATUS_INDEX_DELETED = (1u << 5),
	GIT_SUBMODULE_STATUS_INDEX_MODIFIED = (1u << 6),
	GIT_SUBMODULE_STATUS_WD_UNINITIALIZED = (1u << 7),
	GIT_SUBMODULE_STATUS_WD_ADDED = (1u << 8),
	GIT_SUBMODULE_STATUS_WD_DELETED = (1u << 9),
	GIT_SUBMODULE_STATUS_WD_MODIFIED = (1u << 10),
	GIT_SUBMODULE_STATUS_WD_INDEX_MODIFIED = (1u << 11),
	GIT_SUBMODULE_STATUS_WD_WD_MODIFIED = (1u << 12),
	GIT_SUBMODULE_STATUS_WD_UNTRACKED = (1u << 13),
} git_submodule_status_t;
typedef struct git_submodule_update_options {
	unsigned int version;
	git_checkout_options checkout_opts;
	git_remote_callbacks remote_callbacks;
	unsigned int clone_checkout_strategy;
	git_signature *signature;
} git_submodule_update_options;
int git_submodule_update_init_options(
	git_submodule_update_options *opts, unsigned int version);
int git_submodule_update(git_submodule *submodule, int init, git_submodule_update_options *options);
int git_submodule_lookup(
	git_submodule **out,
	git_repository *repo,
	const char *name);
void git_submodule_free(git_submodule *submodule);
int git_submodule_foreach(
	git_repository *repo,
	int (*callback)(git_submodule *sm, const char *name, void *payload),
	void *payload);
int git_submodule_add_setup(
	git_submodule **out,
	git_repository *repo,
	const char *url,
	const char *path,
	int use_gitlink);
int git_submodule_add_finalize(git_submodule *submodule);
int git_submodule_add_to_index(
	git_submodule *submodule,
	int write_index);
int git_submodule_save(git_submodule *submodule);
git_repository * git_submodule_owner(git_submodule *submodule);
const char * git_submodule_name(git_submodule *submodule);
const char * git_submodule_path(git_submodule *submodule);
const char * git_submodule_url(git_submodule *submodule);
int git_submodule_resolve_url(git_buf *out, git_repository *repo, const char *url);
const char * git_submodule_branch(git_submodule *submodule);
int git_submodule_set_url(git_submodule *submodule, const char *url);
const git_oid * git_submodule_index_id(git_submodule *submodule);
const git_oid * git_submodule_head_id(git_submodule *submodule);
const git_oid * git_submodule_wd_id(git_submodule *submodule);
git_submodule_ignore_t git_submodule_ignore(
	git_submodule *submodule);
git_submodule_ignore_t git_submodule_set_ignore(
	git_submodule *submodule,
	git_submodule_ignore_t ignore);
git_submodule_update_t git_submodule_update_strategy(
	git_submodule *submodule);
git_submodule_update_t git_submodule_set_update(
	git_submodule *submodule,
	git_submodule_update_t update);
git_submodule_recurse_t git_submodule_fetch_recurse_submodules(
	git_submodule *submodule);
git_submodule_recurse_t git_submodule_set_fetch_recurse_submodules(
	git_submodule *submodule,
	git_submodule_recurse_t fetch_recurse_submodules);
int git_submodule_init(git_submodule *submodule, int overwrite);
int git_submodule_repo_init(
	git_repository **out,
	const git_submodule *sm,
	int use_gitlink);
int git_submodule_sync(git_submodule *submodule);
int git_submodule_open(
	git_repository **repo,
	git_submodule *submodule);
int git_submodule_reload(git_submodule *submodule, int force);
int git_submodule_reload_all(git_repository *repo, int force);
int git_submodule_status(
	unsigned int *status,
	git_submodule *submodule);
int git_submodule_location(
	unsigned int *location_status,
	git_submodule *submodule);
int git_tag_lookup(
	git_tag **out, git_repository *repo, const git_oid *id);
int git_tag_lookup_prefix(
	git_tag **out, git_repository *repo, const git_oid *id, size_t len);
void git_tag_free(git_tag *tag);
const git_oid * git_tag_id(const git_tag *tag);
git_repository * git_tag_owner(const git_tag *tag);
int git_tag_target(git_object **target_out, const git_tag *tag);
const git_oid * git_tag_target_id(const git_tag *tag);
git_otype git_tag_target_type(const git_tag *tag);
const char * git_tag_name(const git_tag *tag);
const git_signature * git_tag_tagger(const git_tag *tag);
const char * git_tag_message(const git_tag *tag);
int git_tag_create(
	git_oid *oid,
	git_repository *repo,
	const char *tag_name,
	const git_object *target,
	const git_signature *tagger,
	const char *message,
	int force);
int git_tag_annotation_create(
	git_oid *oid,
	git_repository *repo,
	const char *tag_name,
	const git_object *target,
	const git_signature *tagger,
	const char *message);
int git_tag_create_frombuffer(
	git_oid *oid,
	git_repository *repo,
	const char *buffer,
	int force);
int git_tag_create_lightweight(
	git_oid *oid,
	git_repository *repo,
	const char *tag_name,
	const git_object *target,
	int force);
int git_tag_delete(
	git_repository *repo,
	const char *tag_name);
int git_tag_list(
	git_strarray *tag_names,
	git_repository *repo);
int git_tag_list_match(
	git_strarray *tag_names,
	const char *pattern,
	git_repository *repo);
typedef int (*git_tag_foreach_cb)(const char *name, git_oid *oid, void *payload);
int git_tag_foreach(
	git_repository *repo,
	git_tag_foreach_cb callback,
	void *payload);
int git_tag_peel(
	git_object **tag_target_out,
	const git_tag *tag);
]]
