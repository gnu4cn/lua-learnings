#ifndef EXTENDING_LIB_H
#define EXTENDING_LIB_H

#include <math.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

static int l_sin (lua_State *L) {
    double d = luaL_checknumber(L, 1); /* get argument */
    lua_pushnumber(L, sin(d)); /* push result */
    return 1; /* number of results */
}


static int l_dir (lua_State *L) {
    DIR *dir;
    struct dirent *entry;
    int i;

    const char *path = luaL_checkstring(L, 1);
    /* open directory */
    dir = opendir(path);
    if (dir == NULL) { /* error opening the directory? */
        lua_pushnil(L); /* return nil... */
        lua_pushstring(L, strerror(errno)); /* and error message */
        return 2; /* number of results */
    }
    /* create result table */
    lua_newtable(L);
    i = 1;
    while ((entry = readdir(dir)) != NULL) { /* for each entry */
        lua_pushinteger(L, i++); /* push key */
        lua_pushstring(L, entry->d_name); /* push value */
        lua_settable(L, -3); /* table[i] = entry name */
    }
    closedir(dir);
    return 1; /* table is already on top */
}

#endif
