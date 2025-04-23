#include <stdio.h>
#include <stdlib.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "extending_lib.h"

int main (void) {
    double x = 3.14, y = 3.0, z;
    struct lua_State *L = luaL_newstate();
    if( L == NULL ) {
        puts( "Lua failed to initialize." );
        exit(1);
    }

    // Ref:
    //
    //  https://stackoverflow.com/a/65626530/12288760
    //  https://stackoverflow.com/a/57190172/12288760
    luaL_openlibs(L);
    _load(L, "conf.lua");

    call_va(L, "f", "dd>d", x, y, &z);
    printf("%10.2f\n", z);

    lua_close(L);
    return 0;
}
