#include <stdio.h>
#include "lua.h"
#include "lauxlib.h"


void main () {
    char* myStr = "测试字符串";
    lua_State *L = luaL_newstate(); /* opens Lua */

    /* variable with a unique address */
    static char Key = 'k';

    /* store a string */
    lua_pushstring(L, myStr); /* push value */
    lua_rawsetp(L, LUA_REGISTRYINDEX, (void *)&Key); /* registry[&Key] = myStr */

    /* retrieve a string */
    lua_rawgetp(L, LUA_REGISTRYINDEX, (void *)&Key); /* retrieve value */
    myStr = lua_tostring(L, -1); /* convert to string */

    printf("%s\n", myStr);
}
