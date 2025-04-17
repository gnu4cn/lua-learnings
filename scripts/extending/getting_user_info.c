#include <stdio.h>
#include "lua.h"
#include "lauxlib.h"

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
