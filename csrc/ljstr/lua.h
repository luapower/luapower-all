
#ifndef _LUA_H
#define _LUA_H

typedef double lua_Number;

#define LJ_ENDIAN_LOHI(lo, hi)		lo hi

#define setnanV(o)		((o)->u64 = U64x(fff80000,00000000))
#define setpinfV(o)		((o)->u64 = U64x(7ff00000,00000000))
#define setminfV(o)		((o)->u64 = U64x(fff00000,00000000))
#define lj_num2int(n)   ((int32_t)(n))

#endif
