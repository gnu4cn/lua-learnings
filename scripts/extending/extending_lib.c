#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "extending_lib.h"

void error (lua_State *L, const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    va_end(argp);
    lua_close(L);
    exit(EXIT_FAILURE);
}


/* assume that table is on the top of the stack */
int getcolorfield (lua_State *L, const char *key) {
    int result, isnum;

    if (lua_getfield(L, -1, key) != LUA_TNUMBER)
        error(L, "invalid component '%s' in color", key);

    lua_pop(L, 1); /* remove number */
    return result;
}

/* assume that table is on top */
void setcolorfield (lua_State *L, const char *index, int value) {
    lua_pushnumber(L, (double)value / MAX_COLOR);
    lua_setfield(L, -2, index);
}

void setcolor (lua_State *L, struct ColorTable *ct) {
    // lua_newtable(L); /* creates a table */
    lua_createtable(L, 0, 3);

    setcolorfield(L, "red", ct->red);
    setcolorfield(L, "green", ct->green);
    setcolorfield(L, "blue", ct->blue);
    lua_setglobal(L, ct->name); /* 'name' = table */
}

int getglobint (lua_State *L, const char *var) {
    int isnum, result;

    lua_getglobal(L, var);
    result = (int)lua_tointegerx(L, -1, &isnum);

    if (!isnum)
        error(L, "'%s' should be a number\n", var);

    lua_pop(L, 1); /* remove result from the stack */
    return result;
}

void _load (lua_State *L, const char *fname) {
    if (luaL_loadfile(L, fname) || lua_pcall(L, 0, 0, 0))
        error(L, "cannot run config. file: %s", lua_tostring(L, -1));
}

void load (lua_State *L, const char *fname, int *w, int *h) {
    if (luaL_loadfile(L, fname) || lua_pcall(L, 0, 0, 0))
        error(L, "cannot run config. file: %s", lua_tostring(L, -1));

    *w = getglobint(L, "width");
    *h = getglobint(L, "height");
}

/* call a function 'f' defined in Lua */
double f (lua_State *L, double x, double y) {
    int isnum;
    double z;

    /* push functions and arguments */
    lua_getglobal(L, "f"); /* function to be called */
    lua_pushnumber(L, x); /* push 1st argument */
    lua_pushnumber(L, y); /* push 2nd argument */

    /* do the call (2 arguments, 1 result) */
    if (lua_pcall(L, 2, 1, 0) != LUA_OK)
        error(L, "error running function 'f': %s",
                lua_tostring(L, -1));

    /* retrieve result */
    z = lua_tonumberx(L, -1, &isnum);

    if (!isnum)
        error(L, "function 'f' should return a number");

    lua_pop(L, 1); /* pop returned value */
    return z;
}


void call_va (lua_State *L, const char *func,
        const char *sig, ...) {
    va_list vl;
    int narg, nres; /* number of arguments and results */

    va_start(vl, sig);
    lua_getglobal(L, func); /* push function */

    //
    // Pushing arguments for the generic call function
    //
    for (narg = 0; *sig; narg++) { /* repeat for each argument */
        /* check stack space */
        luaL_checkstack(L, 1, "too many arguments");

        switch (*sig++) {
            case 'd': /* double argument */
                lua_pushnumber(L, va_arg(vl, double));
                break;
            case 'i': /* int argument */
                lua_pushinteger(L, va_arg(vl, int));
                break;
            case 's': /* string argument */
                lua_pushstring(L, va_arg(vl, char *));
                break;
            case '>': /* end of arguments */
                goto endargs; /* break the loop */
            default:
                error(L, "invalid option (%c)", *(sig - 1));
        }
    }
    endargs:
    //
    //
    //

    nres = strlen(sig); /* number of expected results */
    if (lua_pcall(L, narg, nres, 0) != 0) /* do the call */
        error(L, "error calling '%s': %s", func,
                lua_tostring(L, -1));

    //
    // Retrieving results for the generic call function
    //
    nres = -nres; /* stack index of first result */
    while (*sig) { /* repeat for each result */
        switch (*sig++) {
            case 'd': { /* double result */
                          int isnum;
                          double n = lua_tonumberx(L, nres, &isnum);
                          if (!isnum)
                              error(L, "wrong result type");
                          *va_arg(vl, double *) = n;
                          break;
                      }
            case 'i': { /* int result */
                          int isnum;
                          int n = lua_tointegerx(L, nres, &isnum);
                          if (!isnum)
                              error(L, "wrong result type");
                          *va_arg(vl, int *) = n;
                          break;
                      }
            case 's': { /* string result */
                          const char *s = lua_tostring(L, nres);
                          if (s == NULL)
                              error(L, "wrong result type");
                          *va_arg(vl, const char **) = s;
                          break;
                      }
            default:
                      error(L, "invalid option (%c)", *(sig - 1));
        }
        nres++;
    }
    //
    //
    //
    va_end(vl);
}
