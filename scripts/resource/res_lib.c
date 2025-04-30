#include "lua.h"
#include "res_lib.h"

int luaopen_dir (lua_State *L) {
    luaL_newmetatable(L, "LuaBook.dir");

    /* set its __gc field */
    lua_pushcfunction(L, dir_gc);
    lua_setfield(L, -2, "__gc");

    /* create the library */
    luaL_newlib(L, dirlib);

    return 1;
}
