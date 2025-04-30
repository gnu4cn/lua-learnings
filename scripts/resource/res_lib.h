#ifndef RES_LIB_H
#define RES_LIB_H


#include <dirent.h>
#include <errno.h>
#include <string.h>
#include <expat.h>
#include "lua.h"
#include "lauxlib.h"


/* forward declaration for the iterator function */
static int dir_iter (lua_State *L);

static int l_dir (lua_State *L) {
    const char *path = luaL_checkstring(L, 1);
    /* create a userdata to store a DIR address */
    DIR **d = (DIR **)lua_newuserdata(L, sizeof(DIR *));

    /* pre-initialize it */
    *d = NULL;
    /* set its metatable */
    luaL_getmetatable(L, "LuaBook.dir");
    lua_setmetatable(L, -2);
    /* try to open the given directory */
    *d = opendir(path);

    if (*d == NULL) /* error opening the directory? */
        luaL_error(L, "cannot open %s: %s", path, strerror(errno));

    /* creates and returns the iterator function;
       its sole upvalue, the directory userdata,
       is already on the top of the stack */
    lua_pushcclosure(L, dir_iter, 1);

    return 1;
}

static int dir_iter (lua_State *L) {
    DIR *d = *(DIR **)lua_touserdata(L, lua_upvalueindex(1));
    struct dirent *entry = readdir(d);

    if (entry != NULL) {
        lua_pushstring(L, entry->d_name);
        return 1;
    }
    else return 0; /* no more values to return */
}

static int dir_gc (lua_State *L) {
    DIR *d = *(DIR **)lua_touserdata(L, 1);

    if (d) closedir(d);

    return 0;
}

static const struct luaL_Reg dirlib [] = {
    {"open", l_dir},
    {NULL, NULL}
};


#endif
