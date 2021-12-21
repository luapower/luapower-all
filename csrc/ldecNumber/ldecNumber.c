/* ldecNumber.c
*  Lua wrapper for decNumber
*  created September 3, 2006 by e
*
* Copyright (c) 2006-7 Doug Currie, Londonderry, NH
* All rights reserved.
*
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, provided that the above
copyright notice(s) and this permission notice appear in all copies of
the Software and that both the above copyright notice(s) and this
permission notice appear in supporting documentation.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL
INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING
FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
************************************************************************/

#include "lua.h"
#include "lauxlib.h"

#ifndef DECNUMDIGITS
#define DECNUMDIGITS 69
#endif

#include "decimal128.h"

// #define LDN_SEAL_TABLES // to make tables and metatables read only

// testing
// #define LDN_CACHE_TEST 1

#ifndef LDN_ENABLE_CACHE
#define LDN_ENABLE_CACHE 0
#endif

#ifndef LDN_ENABLE_RANDOM
#define LDN_ENABLE_RANDOM 1
#endif

#ifndef LDN_CONTEXT_DEFAULT
#define LDN_CONTEXT_DEFAULT DEC_INIT_DECIMAL128
#endif

#define DN_NAME         "decNumber"
#define DN_CONTEXT_META " decNumber_CoNTeXT_MeTA"
#define DN_DNUMBER_META " decNumber_NuMBeR_MeTA"
#define DN_DRANDOM_META " decNumber_RaNDoM_MeTA"

#define DN_VERSION      "1.1.2"

const char *dn_context_meta = DN_CONTEXT_META;
const char *dn_dnumber_meta = DN_DNUMBER_META;
const char *dn_drandom_meta = DN_DRANDOM_META;

// decNumber constants initialized when library loaded
static decNumber dnc_one;

static void dn_dnc_init (void)
{
    decContext dc;
    decContextDefault (&dc, LDN_CONTEXT_DEFAULT);
    decNumberFromString (&dnc_one, "1", &dc);
}

/* ***************** context support functions ***************** */

/*
There is one decNumber decContext per Lua thread. This library stores
these decContexts as full userdata instances in the LUA_ENVIRONINDEX;
the keys of this table are the thread addresses of the thread owning the
decContext.

Because there is the overhead of a table lookup to get this decContext
for every decNumber operation, this library caches the most recently used
decContext. It is expected that the cache hit ratio will be large; it will
be 100% for a single threaded application, and should help multi-threaded
applications considerably.

The cache depends on userdata not being moved by the garbage collector...
*/
/*
From: Roberto Ierusalimschy <roberto@inf.puc-rio.br>
To: Lua list <lua@bazar2.conectiva.com.br>
Date: Tuesday, April 18, 2006, 9:04:52 AM
Subject: userdata and the gc

===8<==============Original message text===============
> >The current garbage collector is non-compacting, so no GCed objects
> >ever move around. IIRC, the authors have cautioned that this may not
> >always be the case, though a lot of current code I've seen relies on
> >unmoving userdata.

The caution is about strings, not about userdata (although we actually
did not say that explicitly in the manual). We have no intention of
allowing userdata addresses to change during GC. Unlike strings, which
are an internal data in Lua, the only purpose of userdata is to be used
by C code, which prefer that things stay where they are :)


> If that is the case, I'm confused about how the gc can shrink the pool
> without invalidating userdata. Using sockets for userdata :

The gc can shrink the pool as much as malloc/free can. In fact, Lua
has no notion of "pool". It only manipulates memory through
malloc/free/realloc.

-- Roberto
===8<===========End of original message text===========
*/

/* decContext construction and type checking */

static decContext *ldn_check_context (lua_State *L, int index)
{
    decContext *dc = (decContext *)luaL_checkudata (L, index, dn_context_meta);
    if (dc == NULL) luaL_argerror (L, index, "decNumber bad context");
    return dc; /* leaves context on Lua stack */
}

static decContext *ldn_make_context (lua_State *L)
{
    decContext *dc = (decContext *)lua_newuserdata(L, sizeof(decContext));
    luaL_getmetatable (L, dn_context_meta);
    lua_setmetatable (L, -2); /* set metatable */
    return dc;  /* leaves context on Lua stack */
}

/* decContext cache */

#if LDN_ENABLE_CACHE
static lua_State *L_of_context_cache;
static decContext *context_cache;
#if LDN_CACHE_TEST
static lua_Number hits;
static lua_Number misses;
#endif
#endif

/* decContext per thread storage */

/* the value on stack at index must be the decContext userdata corresponding to dc
   ldn_set_context must have no stack effect
*/
static void ldn_set_context (lua_State *L, int index, decContext *dc)
{
    /* make value at index the context for this thread */
    if (index < 0) index -= 1;
    lua_pushthread (L);        /* key */
    lua_pushvalue (L, index); /* value */
    lua_rawset (L, LUA_ENVIRONINDEX);
#if LDN_ENABLE_CACHE
    /* and cache */
    L_of_context_cache = L;
    context_cache = dc;
#endif
}

/* either
*  a) we need a decContext on the Lua stack, so we must bypass the cache, or
*  b) we have a cache miss
*/
static decContext *ldn_push_context (lua_State *L)
{
    decContext *dc;
    lua_pushthread (L);        /* key */
    lua_rawget (L, LUA_ENVIRONINDEX);

    if (lua_isnil (L, -1) )
    {
        /* nothing in the thread local state, so make a new context */
        lua_pop (L, 1);
        dc = ldn_make_context (L);
        dc = decContextDefault (dc, LDN_CONTEXT_DEFAULT);
        /* make it the context for this thread */
        ldn_set_context (L, -1, dc);
    }
    else
    {
        dc = ldn_check_context (L, -1);
#if LDN_ENABLE_CACHE
        /* and cache */
        L_of_context_cache = L;
        context_cache = dc;
#endif
    }
    return dc; /* leaves context on Lua stack */
}

static decContext *ldn_get_context (lua_State *L)
{
    decContext *dc;
#if LDN_ENABLE_CACHE
    /* try the cache first */
    if (L_of_context_cache == L)
    {
        dc = context_cache;
#if LDN_CACHE_TEST
        hits += (lua_Number )1;
#endif
    }
    else
#endif
    {
        /* go to the per thread storage next */
        dc = ldn_push_context (L);
        lua_pop (L, 1);
#if LDN_CACHE_TEST
        misses += (lua_Number )1;
#endif
    }
    return dc;
}

#if LDN_CACHE_TEST
static int dn_cache_stats (lua_State *L)
{
    lua_pushnumber (L, hits);
    lua_pushnumber (L, misses);
    return 2;
}
#endif

/* **************** stack/arg support functions ***************** */

static decNumber *ldn_make_decNumber (lua_State *L)
{
    decNumber *dn = (decNumber *)lua_newuserdata(L, sizeof(decNumber));
    luaL_getmetatable (L, dn_dnumber_meta);
    lua_setmetatable (L, -2); /* set metatable */
    return dn;  /* leaves decNumber on Lua stack */
}

static decNumber *ldn_get (lua_State *L, decContext *dc, int index)
{
    switch (lua_type(L,index))
    {
        case LUA_TUSERDATA:
        {
            decNumber *dn = luaL_checkudata (L, index, dn_dnumber_meta);
            if (dn != NULL)
                return dn;
            else
                break;
        }
        case LUA_TNUMBER:
        case LUA_TSTRING:
        {
            decNumber *dn = ldn_make_decNumber (L);
            const char *s = lua_tostring (L, index);
            decNumberFromString (dn, s, dc);
            lua_replace (L, index);
            return dn;
        }
    }
    luaL_typerror (L, index, dn_dnumber_meta);
    return NULL;
}

/* ******************** decNumber functions ********************* */

static int dn_get_context (lua_State *L)
{
    ldn_push_context (L);
    return 1;
}

static int dn_set_context (lua_State *L)
{
    decContext *dc = ldn_check_context (L, 1);
    ldn_push_context (L); /* return previous context */
    ldn_set_context (L, 1, dc);
    return 1;
}

static int dn_todecnumber (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    ldn_get (L, dc, 1);
    lua_pushvalue (L, 1);
    return 1;
}

  uint8_t * decPackedFromNumber(uint8_t *, int32_t, int32_t *,
                                const decNumber *);

  decNumber * decPackedToNumber(const uint8_t *, int32_t, const int32_t *,
                                decNumber *);

/* ************** pack/unpack extensions by luapower ****************** */

static int dn_frompacked (lua_State *L)
{
    const char *s = luaL_checkstring (L, 1);
    size_t len = lua_objlen (L, 1);
    lua_Number d_scale = luaL_checknumber (L, 2);
    decNumber *dn = ldn_make_decNumber (L); /* left in stack */
    int scale = d_scale;
    decPackedToNumber (s, len, &scale, dn);
    return 1;
}

static int dn_topacked (lua_State *L)
{
    decNumber *dn = luaL_checkudata (L, 1, dn_dnumber_meta);
    if (dn == NULL)
        luaL_typerror (L, 1, dn_dnumber_meta);
    int scale;
    int len = (dn->digits + 1) / 2;
    void *ud;
    lua_Alloc f = lua_getallocf (L, &ud);
    char *dbuf = (*f) (ud, NULL, 0, len); // malloc
    if (dbuf == NULL) luaL_error (L, "decNumber topacked cannot malloc");
    decPackedFromNumber (dbuf, len, &scale, dn);
    lua_pushlstring (L, dbuf, len);
    return 1;
}

/* ***************** decNumber methods ******************** */

#define DN_OP1(name,fun) \
static int name (lua_State *L) \
{ \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    decNumber *dnr = ldn_make_decNumber (L); \
    fun(dnr, dn1, dc); \
    return 1; \
}

DN_OP1(dn_exp,    decNumberExp)
DN_OP1(dn_ln,     decNumberLn)
DN_OP1(dn_log10,  decNumberLog10)
DN_OP1(dn_abs,    decNumberAbs)
DN_OP1(dn_neg,    decNumberMinus)
DN_OP1(dn_norm,   decNumberNormalize)
DN_OP1(dn_plus,   decNumberPlus)
DN_OP1(dn_sqrt,   decNumberSquareRoot)
DN_OP1(dn_intval, decNumberToIntegralValue)
DN_OP1(dn_invert, decNumberInvert)
DN_OP1(dn_logb,   decNumberLogB)
DN_OP1(dn_intxct, decNumberToIntegralExact)
DN_OP1(dn_intnmn, decNumberNextMinus)
DN_OP1(dn_intnpl, decNumberNextPlus)

#define DN_OP2(name,fun) \
static int name (lua_State *L) \
{ \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    decNumber *dn2 = ldn_get (L, dc, 2); \
    decNumber *dnr = ldn_make_decNumber (L); \
    fun(dnr, dn1, dn2, dc); \
    return 1; \
}

DN_OP2(dn_add, decNumberAdd)
DN_OP2(dn_div, decNumberDivide)
DN_OP2(dn_mul, decNumberMultiply)
DN_OP2(dn_pow, decNumberPower)
DN_OP2(dn_sub, decNumberSubtract)

DN_OP2(dn_compare,       decNumberCompare)
DN_OP2(dn_comparetotal,  decNumberCompareTotal)
DN_OP2(dn_divideinteger, decNumberDivideInteger)
DN_OP2(dn_max,           decNumberMax)
DN_OP2(dn_min,           decNumberMin)
DN_OP2(dn_quantize,      decNumberQuantize)
DN_OP2(dn_remainder,     decNumberRemainder)
DN_OP2(dn_remaindernear, decNumberRemainderNear)
DN_OP2(dn_rescale,       decNumberRescale)

DN_OP2(dn_and,             decNumberAnd)
DN_OP2(dn_comparetotalmag, decNumberCompareTotalMag)
DN_OP2(dn_maxmag,          decNumberMaxMag)
DN_OP2(dn_minmag,          decNumberMinMag)
DN_OP2(dn_nexttoward,      decNumberNextToward)
DN_OP2(dn_or,              decNumberOr)
DN_OP2(dn_rotate,          decNumberRotate)
DN_OP2(dn_scaleb,          decNumberScaleB)
DN_OP2(dn_shift,           decNumberShift)
DN_OP2(dn_xor,             decNumberXor)

static int dn_fma (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    decNumber *dn2 = ldn_get (L, dc, 2);
    decNumber *dn3 = ldn_get (L, dc, 3);
    decNumber *dnr = ldn_make_decNumber (L);
    decNumberFMA (dnr, dn1, dn2, dn3, dc);
    return 1;
}

/* mod -- needs to be fudged from remainder */

static int dn_mod (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    decNumber *dn2 = ldn_get (L, dc, 2);
    decNumber *dnr = ldn_make_decNumber (L);
    decNumberRemainder (dnr, dn1, dn2, dc);
    if (decNumberIsNegative(dn1) != decNumberIsNegative(dn2) && !decNumberIsZero(dnr))
    {
        // convert remainder to modulo for mismatched signs
        decNumberAdd (dnr, dnr, dn2, dc);
    }
    return 1;
}

/* floor -- needs to be fudged from divideinteger */

static int dn_floor (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    decNumber *dn2 = ldn_get (L, dc, 2); // optional? (default to 1)
    decNumber *dnr = ldn_make_decNumber (L);
    decNumberDivideInteger (dnr, dn1, dn2, dc);
    if (decNumberIsNegative(dn1) != decNumberIsNegative(dn2))
    {
        decNumber dnm;
#if 0
        // ugh! get remainder
        decNumberRemainder (&dnm, dn1, dn2, dc);
#else
        // see if D = q * d, i.e., if r is 0
        decNumberMultiply (&dnm, dnr, dn2, dc); // m = q * d
        decNumberCompare (&dnm, &dnm, dn1, dc); // m = (m == D)
#endif
        if (!decNumberIsZero(&dnm))
        {
            // subtract one from result
            decNumberSubtract (dnr, dnr, &dnc_one, dc);
        }
    }
    return 1;
}

/* trim -- needs decNumberCopy */

static int dn_trim (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    decNumber *dnr = ldn_make_decNumber (L);
    decNumberCopy (dnr, dn1);
    decNumberTrim (dnr);
    return 1;
}

#define DN_OP1nc(name,fun) \
static int name (lua_State *L) \
{ \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    decNumber *dnr = ldn_make_decNumber (L); \
    fun(dnr, dn1); \
    return 1; \
}

DN_OP1nc(dn_copy, decNumberCopy)
DN_OP1nc(dn_copyabs, decNumberCopyAbs)
DN_OP1nc(dn_copynegate, decNumberCopyNegate)

#define DN_OP2nc(name,fun) \
static int name (lua_State *L) \
{ \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    decNumber *dn2 = ldn_get (L, dc, 2); \
    decNumber *dnr = ldn_make_decNumber (L); \
    fun(dnr, dn1, dn2); \
    return 1; \
}

DN_OP2nc(dn_samequantum, decNumberSameQuantum)
DN_OP2nc(dn_copysign, decNumberCopySign)

/* predicates */

#define DN_P1(name,pmac) \
static int name (lua_State *L) \
{ \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    dn1 = dn1; \
    lua_pushboolean (L, pmac(dn1)); \
    return 1; \
}

DN_P1(dn_iszero, decNumberIsZero)
DN_P1(dn_isneg,  decNumberIsNegative)
DN_P1(dn_isnan,  decNumberIsNaN)
DN_P1(dn_isqnan, decNumberIsQNaN)
DN_P1(dn_issnan, decNumberIsSNaN)
DN_P1(dn_isinf,  decNumberIsInfinite)
DN_P1(dn_iscncl, decNumberIsCanonical)
DN_P1(dn_isfini, decNumberIsFinite)
DN_P1(dn_isspec, decNumberIsSpecial)

#define DN_P1c(name,pmac) \
static int name (lua_State *L) \
{ \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    lua_pushboolean (L, pmac(dn1,dc)); \
    return 1; \
}

DN_P1c(dn_isnorm, decNumberIsNormal)
DN_P1c(dn_issubn, decNumberIsSubnormal)

#define DN_PR2(name,fun,pmac) \
static int name (lua_State *L) \
{ \
    decNumber dnr; \
    decContext *dc = ldn_get_context (L); \
    decNumber *dn1 = ldn_get (L, dc, 1); \
    decNumber *dn2 = ldn_get (L, dc, 2); \
    fun(&dnr, dn1, dn2, dc); \
    lua_pushboolean (L, pmac(&dnr)); \
    return 1; \
}

#define decNumberIsNegativeOrZero(d) (decNumberIsNegative(d) || decNumberIsZero(d))

DN_PR2(dn_eq,decNumberCompare,decNumberIsZero)
DN_PR2(dn_lt,decNumberCompare,decNumberIsNegative)
DN_PR2(dn_le,decNumberCompare,decNumberIsNegativeOrZero)

/* classifiers */

static int dn_radix (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    int r = decNumberRadix(dn1);
    dn1 = dn1;
    lua_pushinteger (L, r);
    return 1;
}

static int dn_class (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    int decClass = decNumberClass(dn1,dc);
    lua_pushinteger (L, decClass);
    return 1;
}

static int dn_classtostring (lua_State *L)
{
    //decContext *dc = ldn_get_context (L);
    int decClass = luaL_checkint (L,1);
    const char * s = decNumberClassToString(decClass);
    lua_pushstring (L, s);
    return 1;
}

static int dn_classasstring (lua_State *L)
{
    decContext *dc = ldn_get_context (L);
    decNumber *dn1 = ldn_get (L, dc, 1);
    int decClass = decNumberClass(dn1,dc);
    const char * s = decNumberClassToString(decClass);
    lua_pushstring (L, s);
    return 1;
}

/* to string */

static int ldn_string (lua_State *L, int x, char *(*sf)(const decNumber *, char *))
{
    char buf[128];
    decContext *dc = ldn_get_context (L);
    decNumber *dn = ldn_get (L, dc, x);
    if ((dn->digits + 15) <= 128)
    {
        lua_pushstring (L, sf(dn, buf));
    }
    else
    {
        void *ud;
        lua_Alloc f = lua_getallocf (L, &ud);
        char *dbuf = (*f) (ud, NULL, 0, dn->digits + 15); // malloc
        if (dbuf == NULL) luaL_error (L, "decNumber tostring cannot malloc");
        lua_pushstring (L, sf(dn, dbuf));
        (*f) (ud, dbuf, dn->digits + 15, 0);               // free
    }
    return 1;
}

static int dn_string (lua_State *L)
{
    return ldn_string (L, 1, decNumberToString);
}

static int dn_engstring (lua_State *L)
{
    return ldn_string (L, 1, decNumberToEngString);
}

static int dn_concat (lua_State *L)
{
    if (lua_isstring (L,1))
    {
        lua_pushvalue (L,1);
        ldn_string (L, 2, decNumberToString);
    }
    else if (lua_isstring (L,2))
    {
        ldn_string (L, 1, decNumberToString);
        lua_pushvalue (L,2);
    }
    else
    {
        return luaL_error (L, "concat decNumber requires a string argument");
    }
    lua_concat (L,2);
    return 1;
}

/* *********************** context methods ************************** */

/* Context must always be set correctly:                              */
/*                                                                    */
/*  digits   -- must be in the range 1 through 999999999              */
/*  emax     -- must be in the range 0 through 999999999              */
/*  emin     -- must be in the range 0 through -999999999             */
/*  round    -- must be one of the enumerated rounding modes          */
/*  traps    -- only defined bits may be set                          */
/*  status   -- [any bits may be cleared, but not set, by user]       */
/*  clamp    -- must be either 0 or 1                                 */
/*  extended -- must be either 0 or 1 [present only if DECSUBSET]     */

static int dn_ctx_set_default (lua_State *L)
{
    decContext *dc = ldn_check_context (L, 1);
    int32_t kind = luaL_checkint (L, 2);
    if (   kind == DEC_INIT_DECIMAL128
        || kind == DEC_INIT_DECIMAL64
        || kind == DEC_INIT_DECIMAL32
        || kind == DEC_INIT_BASE
       )
    {
        decContextDefault (dc, kind);
        if (kind == DEC_INIT_BASE)
        {
            dc->traps = 0; /* but turn off traps */
        }
    }
    else
    {
        luaL_error (L, "arg out of range for decNumber default");
    }
    return 0;
}

static int dn_ctx_dup (lua_State *L) \
{
    decContext *dc = ldn_check_context (L, 1);
    decContext *dc_dup = ldn_make_context (L); /* new ctx on top of stack now */
    *dc_dup = *dc; /* copy context's fields */
    return 1;
}

#define LDN_CTX_GETTER(field) \
static int dn_ctx_get_ ## field (lua_State *L) \
{ \
    decContext *dc = ldn_check_context (L, 1); \
    lua_pushinteger (L, dc->field); \
    return 1; \
}

LDN_CTX_GETTER(digits)
LDN_CTX_GETTER(emax)
LDN_CTX_GETTER(emin)
LDN_CTX_GETTER(round)
LDN_CTX_GETTER(traps)
LDN_CTX_GETTER(status)
LDN_CTX_GETTER(clamp)
#if DECSUBSET
LDN_CTX_GETTER(extended)
#endif

#define LDN_CTX_SETTER(field,min,max) \
static int dn_ctx_set_ ## field (lua_State *L) \
{ \
    decContext *dc = ldn_check_context (L, 1); \
    int32_t val = luaL_checkint (L, 2); \
    int32_t oldval = dc->field; \
    if (val < min || val > max) \
        luaL_error (L, "arg out of range for decNumber context " # field); \
    dc->field = val; \
    lua_pushinteger (L, oldval); \
    return 1; \
}

#define LDN_ALL_FLAGS (DEC_Errors|DEC_Information)

LDN_CTX_SETTER(digits,DEC_MIN_DIGITS,DECNUMDIGITS) /* can't hold DEC_MAX_DIGITS */
LDN_CTX_SETTER(emax,DEC_MIN_EMAX,DEC_MAX_EMAX)
LDN_CTX_SETTER(emin,DEC_MIN_EMIN,DEC_MAX_EMIN)
LDN_CTX_SETTER(round,0,(DEC_ROUND_MAX-1))
LDN_CTX_SETTER(traps,0,0) /* LDN_ALL_FLAGS -- this is unsafe since we have no handler */
LDN_CTX_SETTER(status,0,LDN_ALL_FLAGS)
LDN_CTX_SETTER(clamp,0,1)
#if DECSUBSET
LDN_CTX_SETTER(extended,0,1)
#endif

static int dn_ctx_get_status_s (lua_State *L)
{
    decContext *dc = ldn_check_context (L, 1);
    const char * s = decContextStatusToString(dc);
    lua_pushstring (L, s);
    return 1;
}

static int dn_ctx_set_status_s (lua_State *L)
{
    decContext *dc = ldn_check_context (L, 1);
    const char *s = luaL_checkstring (L, 2);
    decContextSetStatusFromString (dc, s);
    return 0;
}

static int dn_ctx_tostring (lua_State *L)
{
    decContext *dc = ldn_check_context (L, 1);
    const char * s = decContextStatusToString(dc);
    lua_pushfstring (L, "decNumber context (%p) %s", dc, s);
    return 1;
}

/* ************************** decNumber random ************************* */

#if LDN_ENABLE_RANDOM

typedef struct random_state
{
    uint32_t r[256];       // circular vector of random values
    uint64_t bit_supply;   // a supply of bits,
    int bit_supply_bits;   // and how many bits left in it
    int x;                 // index of last used r value
} random_state;

static random_state *ldrs_check_state (lua_State *L, int index)
{
    random_state *rs = (random_state *)luaL_checkudata (L, index, dn_drandom_meta);
    if (rs == NULL) luaL_argerror (L, index, "decNumber bad random_state");
    return rs; /* leaves random_state on Lua stack */
}

static int dn_randomstate (lua_State *L)
{
    int i;
    uint64_t t, a=698769069ULL;
    uint32_t x = luaL_optinteger (L, 1, 0); /* four seed values for KISS() */
    uint32_t y = luaL_optinteger (L, 2, 0);
    uint32_t z = luaL_optinteger (L, 3, 0);
    uint32_t c = luaL_optinteger (L, 4, 0);
    random_state *rs = (random_state *)lua_newuserdata(L, sizeof(random_state));
    luaL_getmetatable (L, dn_drandom_meta);
    lua_setmetatable (L, -2); /* set metatable */
    /* seed it */
    if (x == 0) x = 123456789;
    if (y == 0) y = 362436000;
    if (z == 0) z = 521288629;
    if (c == 0) c =   7654321;
    rs->bit_supply = rs->bit_supply_bits = 0;
    rs->x = 0;
    for (i = 0; i < 256; i++)
    {
        // KISS()
        x = 69069 * x + 12345;
        y ^= (y << 13); y ^= (y >> 17); y ^= (y << 5);
        t = a * z + c; c = (t >> 32);
        rs->r[i] = x + y + (z = t);
    }
    return 1;
}

static unsigned int lfib4_10bits (random_state *rs)
{
    unsigned int t;
    if (rs->bit_supply_bits < 10)
    {
        // stock up on bits
        int x = rs->x = (rs->x + 1) & 0xff;
        rs->r[x] += rs->r[(x + 58) & 0xff] + rs->r[(x + 119) & 0xff] + rs->r[(x + 178) & 0xff];
        rs->bit_supply |= (uint64_t )rs->r[x] << rs->bit_supply_bits;
        rs->bit_supply_bits += 32;
    }
    t = rs->bit_supply & 1023; // next 10 bits
    rs->bit_supply >>= 10;
    rs->bit_supply_bits -= 10;
    return t;
}

static int drs_call (lua_State *L)
{
    int t, q, r;
    random_state *rs = ldrs_check_state (L, 1);
    int x = luaL_optinteger (L, 2, 12); // digits
    int e = luaL_optinteger (L, 3, -x); // exponent
    decNumber *dnr = ldn_make_decNumber (L); // push
    // check for maxdigits
    if (!(0 < x && x <= DECNUMDIGITS))
    {
        luaL_error (L, "decNumber random %d digits exceeds available %d digits", x, DECNUMDIGITS);
    }
    if (!(DEC_MIN_EMIN <= e && e <= DEC_MAX_EMAX))
    {
        luaL_error (L, "decNumber exponent %d exceeds available range", e);
    }
    // this gets into decNumber's pants for efficiency
#if DECDPUN != 3
#error "DECDPUN must be 3 for drs_call which assumes 10 bits and 0..999 per unit"
#endif
    q = x / DECDPUN;
    r = x - (q * DECDPUN);
    if (q > DECNUMUNITS || (q == DECNUMUNITS && r != 0))
    {
        luaL_error (L, "decNumber random %d digits failed with %d units", x, q);
    }
    dnr->digits = x;
    dnr->exponent = e;
    dnr->bits = 0;
    while (r != 0)
    {
        t = lfib4_10bits (rs);
        if (t < 1000)
        {
            // too many bits; what can you do?
            dnr->lsu[q] = t % (r == 1 ? 10 : 100);
            r = 0;
        }
        // else reject 1000..1023
    }
    while (q > 0)
    {
        t = lfib4_10bits (rs);
        if (t < 1000)
        {
            // append 3 digits
            dnr->lsu[--q] = t;
        }
        // else reject 1000..1023
    }
    return 1;
}

#endif // LDN_ENABLE_RANDOM

/* ************************ decNumber constants *********************** */

#define DEC_(s)  { #s, DEC_ ## s },

static const struct {
    const char* name;
    int value;
} dn_constants[] = {
    /* rounding */
    DEC_(ROUND_CEILING)             /* round towards +infinity */
    DEC_(ROUND_UP)                  /* round away from 0 */
    DEC_(ROUND_HALF_UP)             /* 0.5 rounds up */
    DEC_(ROUND_HALF_EVEN)           /* 0.5 rounds to nearest even */
    DEC_(ROUND_HALF_DOWN)           /* 0.5 rounds down */
    DEC_(ROUND_DOWN)                /* round towards 0 (truncate) */
    DEC_(ROUND_FLOOR)               /* round towards -infinity */
    DEC_(ROUND_05UP)                /* round for reround  */
    /* Trap-enabler and Status flags */
    DEC_(Conversion_syntax)
    DEC_(Division_by_zero)
    DEC_(Division_impossible)
    DEC_(Division_undefined)
    DEC_(Insufficient_storage)
    DEC_(Inexact)
    DEC_(Invalid_context)
    DEC_(Invalid_operation)
  #if DECSUBSET
    DEC_(Lost_digits)
  #endif
    DEC_(Overflow)
    DEC_(Clamped)
    DEC_(Rounded)
    DEC_(Subnormal)
    DEC_(Underflow)
    /* flag combinations */
    DEC_(IEEE_854_Division_by_zero)
    DEC_(IEEE_854_Inexact)
    DEC_(IEEE_854_Invalid_operation)
    DEC_(IEEE_854_Overflow)
    DEC_(IEEE_854_Underflow)
    DEC_(Errors)      /* flags which are normally errors (results are qNaN, infinite, or 0) */
    DEC_(NaNs)        /* flags which cause a result to become qNaN */
    DEC_(Information) /* flags which are normally for information only (have finite results) */
    /* Initialization descriptors, used by decContextDefault */
    DEC_(INIT_BASE)
    DEC_(INIT_DECIMAL32)
    DEC_(INIT_DECIMAL64)
    DEC_(INIT_DECIMAL128)
    /* Classifications for decNumbers, aligned with 754r (note that     */
    /* 'normal' and 'subnormal' are meaningful only with a decContext)  */
    DEC_(CLASS_SNAN)
    DEC_(CLASS_QNAN)
    DEC_(CLASS_NEG_INF)
    DEC_(CLASS_NEG_NORMAL)
    DEC_(CLASS_NEG_SUBNORMAL)
    DEC_(CLASS_NEG_ZERO)
    DEC_(CLASS_POS_ZERO)
    DEC_(CLASS_POS_SUBNORMAL)
    DEC_(CLASS_POS_NORMAL)
    DEC_(CLASS_POS_INF)
    /* compile time config */
    {"MAX_DIGITS", DECNUMDIGITS },
    /* terminator */
    { NULL, 0 }
};

#if LDN_ENABLE_RANDOM
static const luaL_Reg dn_drandom_meta_lib[] =
{
    { "__call",     drs_call  },
    { NULL,         NULL      }
};
#endif

static const luaL_Reg dn_dnumber_meta_lib[] =
{
    {"eq",              dn_eq     },
    {"lt",              dn_lt     },
    {"le",              dn_le     },

    {"exp",             dn_exp    },
    {"ln",              dn_ln     },
    {"log10",           dn_log10  },
    {"abs",             dn_abs    },
    {"minus",           dn_neg    },
    {"normalize",       dn_norm   },
    {"plus",            dn_plus   },
    {"squareroot",      dn_sqrt   },
    {"tointegralvalue", dn_intval },
    {"invert",          dn_invert },
    {"logb",            dn_logb   },
    {"tointegralexact", dn_intxct },
    {"nextminus",       dn_intnmn },
    {"nextplus",        dn_intnpl },

    {"copy",            dn_copy       },
    {"copyabs",         dn_copyabs    },
    {"copynegate",      dn_copynegate },
    {"copysign",        dn_copysign   },

    {"add",             dn_add    },
    {"divide",          dn_div    },
    {"multiply",        dn_mul    },
    {"power",           dn_pow    },
    {"subtract",        dn_sub    },

    {"compare",         dn_compare       },
    {"comparetotal",    dn_comparetotal  },
    {"divideinteger",   dn_divideinteger },
    {"max",             dn_max           },
    {"min",             dn_min           },
    {"quantize",        dn_quantize      },
    {"remainder",       dn_remainder     },
    {"remaindernear",   dn_remaindernear },
    {"rescale",         dn_rescale       },
    {"samequantum",     dn_samequantum   },

    {"land",            dn_and           },
    {"comparetotalmag", dn_comparetotalmag },
    {"maxmag",          dn_maxmag        },
    {"minmag",          dn_minmag        },
    {"nexttoward",      dn_nexttoward    },
    {"lor",             dn_or            },
    {"rotate",          dn_rotate        },
    {"scaleb",          dn_scaleb        },
    {"shift",           dn_shift         },
    {"xor",             dn_xor           },

    {"fma",             dn_fma           },

    {"mod",             dn_mod           },
    {"floor",           dn_floor         },

    {"iszero",          dn_iszero        },
    {"isnegative",      dn_isneg         },
    {"isnan",           dn_isnan         },
    {"isqnan",          dn_isqnan        },
    {"issnan",          dn_issnan        },
    {"isinfinite",      dn_isinf         },
    {"isfinite",        dn_isfini        },
    {"iscanonical",     dn_iscncl        },
    {"isspecial",       dn_isspec        },
    {"isnormal",        dn_isnorm        },
    {"issubnormal",     dn_issubn        },

    {"radix",           dn_radix         },
    {"class",           dn_class         },
    {"classtostring",   dn_classtostring },
    {"classasstring",   dn_classasstring },

    {"trim",            dn_trim          },

    {"tostring",        dn_string        },
    {"toengstring",     dn_engstring     },

    { "__unm",      dn_neg    },
    { "__add",      dn_add    },
    { "__sub",      dn_sub    },
    { "__mul",      dn_mul    },
    { "__div",      dn_div    },
    { "__pow",      dn_pow    },
    { "__mod",      dn_mod    },
    { "__eq",       dn_eq     },
    { "__lt",       dn_lt     },
    { "__le",       dn_le     },
    { "__tostring", dn_string },
    { "__concat",   dn_concat },

    { NULL,         NULL      }
};

static const luaL_Reg dn_context_meta_lib[] =
{
    {"setdefault",       dn_ctx_set_default   },
    {"getstatus",        dn_ctx_get_status    },
    {"setstatus",        dn_ctx_set_status    },
    {"getdigits",        dn_ctx_get_digits    },
    {"setdigits",        dn_ctx_set_digits    },
    {"getemax",          dn_ctx_get_emax      },
    {"setemax",          dn_ctx_set_emax      },
    {"getemin",          dn_ctx_get_emin      },
    {"setemin",          dn_ctx_set_emin      },
    {"getround",         dn_ctx_get_round     },
    {"setround",         dn_ctx_set_round     },
    {"gettraps",         dn_ctx_get_traps     },
    {"settraps",         dn_ctx_set_traps     },
    {"getclamp",         dn_ctx_get_clamp     },
    {"setclamp",         dn_ctx_set_clamp     },
#if DECSUBSET
    {"getextended",      dn_ctx_get_extended  },
    {"setextended",      dn_ctx_set_extended  },
#endif
    {"getstatusstring",  dn_ctx_get_status_s  },
    {"setstatusstring",  dn_ctx_set_status_s  },
    {"duplicate",        dn_ctx_dup           },
    {"setcontext",       dn_set_context       },
    {"__tostring",       dn_ctx_tostring      },

    {NULL, NULL}
};

static const luaL_Reg dn_lib[] =
{
    {"eq",              dn_eq     },
    {"lt",              dn_lt     },
    {"le",              dn_le     },

    {"exp",             dn_exp    },
    {"ln",              dn_ln     },
    {"log10",           dn_log10  },
    {"abs",             dn_abs    },
    {"minus",           dn_neg    },
    {"normalize",       dn_norm   },
    {"plus",            dn_plus   },
    {"squareroot",      dn_sqrt   },
    {"tointegralvalue", dn_intval },
    {"invert",          dn_invert },
    {"logb",            dn_logb   },
    {"tointegralexact", dn_intxct },
    {"nextminus",       dn_intnmn },
    {"nextplus",        dn_intnpl },

    {"copy",            dn_copy       },
    {"copyabs",         dn_copyabs    },
    {"copynegate",      dn_copynegate },
    {"copysign",        dn_copysign   },

    {"add",             dn_add    },
    {"divide",          dn_div    },
    {"multiply",        dn_mul    },
    {"power",           dn_pow    },
    {"subtract",        dn_sub    },

    {"compare",         dn_compare       },
    {"comparetotal",    dn_comparetotal  },
    {"divideinteger",   dn_divideinteger },
    {"max",             dn_max           },
    {"min",             dn_min           },
    {"quantize",        dn_quantize      },
    {"remainder",       dn_remainder     },
    {"remaindernear",   dn_remaindernear },
    {"rescale",         dn_rescale       },
    {"samequantum",     dn_samequantum   },

    {"land",            dn_and           },
    {"comparetotalmag", dn_comparetotalmag },
    {"maxmag",          dn_maxmag        },
    {"minmag",          dn_minmag        },
    {"nexttoward",      dn_nexttoward    },
    {"lor",             dn_or            },
    {"rotate",          dn_rotate        },
    {"scaleb",          dn_scaleb        },
    {"shift",           dn_shift         },
    {"xor",             dn_xor           },

    {"fma",             dn_fma           },

    {"mod",             dn_mod           },
    {"floor",           dn_floor         },

    {"iszero",          dn_iszero        },
    {"isnegative",      dn_isneg         },
    {"isnan",           dn_isnan         },
    {"isqnan",          dn_isqnan        },
    {"issnan",          dn_issnan        },
    {"isinfinite",      dn_isinf         },
    {"isfinite",        dn_isfini        },
    {"iscanonical",     dn_iscncl        },
    {"isspecial",       dn_isspec        },
    {"isnormal",        dn_isnorm        },
    {"issubnormal",     dn_issubn        },

    {"radix",           dn_radix         },
    {"class",           dn_class         },
    {"classtostring",   dn_classtostring },
    {"classasstring",   dn_classasstring },

    {"trim",            dn_trim          },

    {"getcontext",      dn_get_context   },
    {"setcontext",      dn_set_context   },
    {"tonumber",        dn_todecnumber   },
    {"tostring",        dn_string        },
    {"toengstring",     dn_engstring     },
    {"frompacked",      dn_frompacked    },
    {"topacked",        dn_topacked      },

    {"randomstate",     dn_randomstate   },

#if LDN_CACHE_TEST
    {"cachestats",      dn_cache_stats   },
#endif
    {NULL, NULL}
};

static void mkmeta (lua_State *L, const char *uname, const char *tname, const luaL_Reg *reg)
{
    lua_pushstring (L, uname);    /* accesible for user with this name */
    luaL_newmetatable (L, tname); /* internal checkudata name */
    luaL_register (L, NULL, reg); /* register metatable functions */
    lua_pushstring (L, "__index");
    lua_pushvalue (L, -2);       /* push metatable */
    lua_rawset (L, -3);          /* metatable.__index = metatable */
    lua_settable (L,-3);
}

LUALIB_API int luaopen_ldecnumber(lua_State *L)
{
    /* initialize constants */
    dn_dnc_init ();
    /* create a shared environment for the decNumber functions */
    lua_createtable (L, 0, 5);     /* the shared environment */
#if !LDN_ENABLE_CACHE
    /* when cache is off (default: off), make keys weak so threads are GC'd */
    lua_createtable (L, 0, 1);     /* its metatable, which is */
    lua_pushliteral (L, "__mode"); /* used to make environment */
    lua_pushliteral (L, "k");      /* weak in the keys */
    lua_rawset (L, -3);            /* metatable.__mode = "k" */
    lua_setmetatable (L, -2);      /* set the environment metatable */
#endif
    lua_replace (L, LUA_ENVIRONINDEX); /* the new c function environment */
    /* create decNumber global table and register decNumber functions */
    luaL_register (L, DN_NAME, dn_lib);
    {
        int i = 0;
        /* add constants to global table */
        while (dn_constants[i].name)
        {
            lua_pushstring (L, dn_constants[i].name);
            lua_pushnumber (L, dn_constants[i].value);
            lua_rawset (L, -3);
            i += 1;
        }
    }
    lua_pushliteral (L,"version");              /** version */
    lua_pushliteral (L, DN_VERSION);
    lua_settable (L, -3);
    /* */
#if LDN_ENABLE_RANDOM
    mkmeta (L, "drandom_metatable", dn_drandom_meta, dn_drandom_meta_lib);
#endif
    /* */
    mkmeta (L, "context_metatable", dn_context_meta, dn_context_meta_lib);
    /* */
    mkmeta (L, "number_metatable", dn_dnumber_meta, dn_dnumber_meta_lib);
    /* */
#if LDN_SEAL_TABLES
    /* set decNumber's metatable to itself - set as readonly (__newindex) */
    lua_pushvalue(L, -1);
    lua_setmetatable(L, -2);
#endif
    return 1;
}

/* end of ldecNumber.c */
