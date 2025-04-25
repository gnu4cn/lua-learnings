#include "lua.h"
#include "lauxlib.h"
#include "tips_lib.h"


int l_map (lua_State *L) {
    int i, n;

    /* 1st argument must be a table (t) */
    luaL_checktype(L, 1, LUA_TTABLE);
    /* 2nd argument must be a function (f) */
    luaL_checktype(L, 2, LUA_TFUNCTION);

    n = luaL_len(L, 1); /* get size of table */
    for (i = 1; i <= n; i++) {
        lua_pushvalue(L, 2); /* push f */
        lua_geti(L, 1, i); /* push t[i] */
        lua_call(L, 1, 1); /* call f(t[i]) */
        lua_seti(L, 1, i); /* t[i] = result */
    }

    return 0; /* no results */
}


static const struct luaL_Reg mylib [] = {
    {"map", l_map},
    {"split", l_split},
    {NULL, NULL} /* sentinel */
};

int luaopen_mylib (lua_State *L) {
    luaL_newlib(L, mylib);
    return 1;
}
