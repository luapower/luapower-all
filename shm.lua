
--sys/shm.h and sys/ipc.h binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
assert(ffi.os == 'Linux', 'platform not Linux')

ffi.cdef[[
typedef unsigned int __uid_t;
typedef unsigned int __gid_t;
typedef unsigned int __mode_t;
typedef int          __key_t;
typedef long int     __time_t;
typedef int          __pid_t;

// sys/ipc.h
__key_t ftok (__const char *__pathname, int __proj_id);

// bits/ipc.h
enum {
	IPC_CREAT            = 01000,
	IPC_EXCL             = 02000,
	IPC_NOWAIT           = 04000,
	IPC_RMID             = 0,
	IPC_SET              = 1,
	IPC_STAT             = 2,
	IPC_PRIVATE          = 0,
};

struct ipc_perm {
	__key_t __key;
	__uid_t uid;
	__gid_t gid;
	__uid_t cuid;
	__gid_t cgid;
	unsigned short int mode;
	unsigned short int __pad1;
	unsigned short int __seq;
	unsigned short int __pad2;
	unsigned long int __unused1;
	unsigned long int __unused2;
};

// bits/shm.h
enum {
	SHM_R                = 0400,
	SHM_W                = 0200,
	SHM_RDONLY           = 010000,
	SHM_RND              = 020000,
	SHM_REMAP            = 040000,
	SHM_EXEC             = 0100000,
	SHM_LOCK             = 11,
	SHM_UNLOCK           = 12,
};

int __getpagesize (void);

typedef unsigned long int shmatt_t;

struct shmid_ds {
	struct ipc_perm shm_perm;
	size_t shm_segsz;
	__time_t shm_atime;
	__time_t shm_dtime;
	__time_t shm_ctime;
	__pid_t shm_cpid;
	__pid_t shm_lpid;
	shmatt_t shm_nattch;
	unsigned long int __unused4;
	unsigned long int __unused5;
};

enum {
	SHM_STAT             = 13,
	SHM_INFO             = 14,
	SHM_DEST             = 01000,
	SHM_LOCKED           = 02000,
	SHM_HUGETLB          = 04000,
	SHM_NORESERVE        = 010000,
};

struct shminfo {
	unsigned long int shmmax;
	unsigned long int shmmin;
	unsigned long int shmmni;
	unsigned long int shmseg;
	unsigned long int shmall;
	unsigned long int __unused1;
	unsigned long int __unused2;
	unsigned long int __unused3;
	unsigned long int __unused4;
};

struct shm_info {
	int used_ids;
	unsigned long int shm_tot;
	unsigned long int shm_rss;
	unsigned long int shm_swp;
	unsigned long int swap_attempts;
	unsigned long int swap_successes;
};

// sys/shm.h
int shmctl (int __shmid, int __cmd, struct shmid_ds *__buf);
int shmget (__key_t __key, size_t __size, int __shmflg);
void *shmat (int __shmid, __const void *__shmaddr, int __shmflg);
int shmdt (__const void *__shmaddr);
]]

local C = ffi.C

if not ... then
	print('getpagesize', C.__getpagesize())
end

return C
