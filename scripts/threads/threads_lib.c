#include "lua.h"
#include "threads_lib.h"

static const struct luaL_Reg ll_funcs[] = {
    {"start", ll_start},
    {"send", ll_send},
    {"receive", ll_receive},
    {"exit", ll_exit},
    {NULL, NULL}
};

int luaopen_lproc (lua_State *L) {
    luaL_newlib(L, ll_funcs); /* open library */
    return 1;
}


