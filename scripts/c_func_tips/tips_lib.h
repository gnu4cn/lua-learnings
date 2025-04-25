#ifndef TIPS_LIB_H
#define TIPS_LIB_H

#include <string.h>
#include "lua.h"

extern int l_map (lua_State *L);
extern int luaopen_mylib (lua_State *L);

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

#endif
