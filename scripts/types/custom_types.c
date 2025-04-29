#include "lua.h"
#include "custom_types.h"

int array2string (lua_State *L) {
    BitArray *a = checkarray(L);
    lua_pushfstring(L, "array(%d)", a->size);
    return 1;
}

static const struct luaL_Reg func_list_f [] = {
    {"new", newarray},
    {NULL, NULL} /* sentinel */
};

static const struct luaL_Reg func_list_m [] = {
    {"__newindex", setarray},
    {"__index", getarray},
    {"__len", getsize},
    {"__tostring", array2string},
    {NULL, NULL} /* sentinel */
};

int luaopen_arraylib (lua_State *L) {
    luaL_newmetatable(L, "LuaBook.array"); /* create metatable */
    luaL_setfuncs(L, func_list_m, 0); /* register metamethods */
    luaL_newlib(L, func_list_f); /* create lib table */

    return 1;
}
