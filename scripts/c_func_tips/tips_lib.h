#ifndef TIPS_LIB_H
#define TIPS_LIB_H

#include <string.h>
#include "lua.h"

static int l_split (lua_State *L) {
    const char *s = luaL_checkstring(L, 1); /* subject */
    const char *sep = luaL_checkstring(L, 2); /* separator */
    const char *e;
    int i = 1;

    lua_newtable(L); /* result table */

    /* repeat for each separator */
    while ((e = strchr(s, *sep)) != NULL) {
        lua_pushlstring(L, s, e - s); /* push substring */
        lua_rawseti(L, -2, i++); /* insert it in table */
        s = e + 1; /* skip separator */
    }

    /* insert last substring */
    lua_pushstring(L, s);
    lua_rawseti(L, -2, i);

    return 1; /* return the table */
}


static int tconcat (lua_State *L) {
    luaL_Buffer b;
    int i, n;

    luaL_checktype(L, 1, LUA_TTABLE);
    n = luaL_len(L, 1);
    luaL_buffinit(L, &b);

    for (i = 1; i <= n; i++) {
        lua_geti(L, 1, i); /* get string from table */
        luaL_addvalue(&b); /* add it to the buffer */
    }

    luaL_pushresult(&b);
    return 1;
}

static int counter (lua_State *L) {
    int val = lua_tointeger(L, lua_upvalueindex(1));
    lua_pushinteger(L, ++val); /* new value */
    lua_copy(L, -1, lua_upvalueindex(1)); /* update upvalue */
    return 1; /* return new value */
}

#endif
