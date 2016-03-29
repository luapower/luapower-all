/*
  Encoding engine to use with dasm.lua.

  Compile with:

    gcc dasm_x86.c -O -fPIC -DDASM_CHECKS -shared -s -o libdasm_x86.so
*/

#include "dasm_extern.h"
#include "dasm_proto.h"
#include "dasm_x86.h"
