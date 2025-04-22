#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
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

void load (lua_State *L, const char *fname, int *w, int *h) {
    if (luaL_loadfile(L, fname) || lua_pcall(L, 0, 0, 0))
        error(L, "cannot run config. file: %s", lua_tostring(L, -1));

    *w = getglobint(L, "width");
    *h = getglobint(L, "height");
}
