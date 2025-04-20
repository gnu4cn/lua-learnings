#include <stdio.h>
#include "lauxlib.h"
#include "stack_lib.h"

int main (void) {
    lua_State *L = luaL_newstate();

    lua_pushboolean(L, 1);
    lua_pushnumber(L, 10);
    lua_pushnil(L);
    lua_pushstring(L, "hello");

    stackDump(L);
    /* will print: true 10 nil 'hello' */
    lua_pushvalue(L, -4); stackDump(L);
    /* will print: true 10 nil 'hello' true */
    lua_replace(L, 3); stackDump(L);
    /* will print: true 10 true 'hello' */
    lua_settop(L, 6); stackDump(L);
    /* will print: true 10 true 'hello' nil nil */
    lua_rotate(L, 3, 1); stackDump(L);
    /* will print: true 10 nil true 'hello' nil */
    lua_remove(L, -3); stackDump(L);
    /* will print: true 10 nil 'hello' nil */
    lua_settop(L, -5); stackDump(L);
    /* will print: true */

    lua_close(L);
    return 0;
}
