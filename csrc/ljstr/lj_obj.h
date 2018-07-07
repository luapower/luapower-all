
#ifndef _LJ_OBJ_H
#define _LJ_OBJ_H

/* Tagged value. */
typedef LJ_ALIGN(8) union TValue {
  uint64_t u64;	/* 64 bit pattern overlaps number. */
  lua_Number n;	/* Number object overlaps split tag/value object. */
  int32_t i;		/* Integer value. */
} TValue;

#endif
