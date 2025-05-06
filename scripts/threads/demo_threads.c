#include <stdio.h>
#include "lauxlib.h"


static void stackDump (lua_State *L) {
    int i;
    int top = lua_gettop(L); /* depth of the stack */

    for (i = 1; i <= top; i++) { /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
            case LUA_TSTRING: { /* strings */
                                  printf("%d - '%s'\n", i, lua_tostring(L, i));
                                  break;
                              }
            case LUA_TBOOLEAN: { /* Booleans */
                                   char* res = lua_toboolean(L, i) ? "true" : "false";
                                   printf("%d - '%s'\n", i, res);
                                   break;
                               }
            case LUA_TNUMBER: { /* numbers */
                                  printf("%d - %g\n", i, lua_tonumber(L, i));
                                  break;
                              }
            default: { /* other values */
                         printf("%d - %s\n", i, lua_typename(L, t));
                         break;
                     }
        }
        // printf(" "); /* put a separator */
    }
    printf("\n"); /* end the listing */
}

int main (void) {
    int nres;

    lua_State *L = luaL_newstate();

    // Define Lua function f
    luaL_dostring(L, "function foo (x) coroutine.yield(10, x) end \
            function foo1 (x) foo(x + 1); return 3 end");

    lua_State *L1 = lua_newthread(L);
    lua_getglobal(L1, "foo1");
    lua_pushinteger(L1, 20);
    lua_resume(L1, L, 1, &nres);

    printf("%d\n", lua_gettop(L1)); // 2
    printf("%lld\n", lua_tointeger(L1, 1)); // 10
    printf("%lld\n", lua_tointeger(L1, 2)); // 21

    lua_resume(L1, L, 0, &nres);
    printf("%d\n", lua_gettop(L1)); // 1
    printf("%lld\n", lua_tointeger(L1, 1)); // 3

    // stackDump(L);

    lua_close(L);
    return 0;
}

