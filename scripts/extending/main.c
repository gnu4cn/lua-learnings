#include <stdio.h>
#include "lauxlib.h"
#include "extending_lib.h"

int main (void) {
    int width, height;
    lua_State *L = luaL_newstate();

    load(L, "conf.lua", &width, &height);
    printf("%d, %d\n", width, height);


    lua_close(L);
    return 0;
}
