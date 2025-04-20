#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"




void error (lua_State *L, const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    va_end(argp);
    lua_close(L);
    exit(EXIT_FAILURE);
}
