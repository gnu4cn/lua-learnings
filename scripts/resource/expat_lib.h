#ifndef EXPAT_LIB_H
#define EXPAT_LIB_H


#include <stdlib.h>
#include "expat.h"
#include "lua.h"
#include "lauxlib.h"

typedef struct lxp_userdata {
    XML_Parser parser; /* associated expat parser */
    lua_State *L;
} lxp_userdata;

/* forward declarations for callback functions */
static void f_StartElement (void *ud,
        const char *name,
        const char **atts);
static void f_CharData (void *ud, const char *s, int len);
static void f_EndElement (void *ud, const char *name);

static int lxp_make_parser (lua_State *L) {
    XML_Parser p;

    /* (1) create a parser object */
    lxp_userdata *xpu = (lxp_userdata *)lua_newuserdata(L,
            sizeof(lxp_userdata));
    /* pre-initialize it, in case of error */
    xpu->parser = NULL;
    /* set its metatable */
    luaL_getmetatable(L, "Expat");
    lua_setmetatable(L, -2);

    /* (2) create the Expat parser */
    p = xpu->parser = XML_ParserCreate(NULL);
    if (!p)
        luaL_error(L, "XML_ParserCreate failed");

    /* (3) check and store the callback table */
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushvalue(L, 1); /* push table */
    lua_setuservalue(L, -2); /* set it as the user value */

    /* (4) configure Expat parser */
    XML_SetUserData(p, xpu);
    XML_SetElementHandler(p, f_StartElement, f_EndElement);
    XML_SetCharacterDataHandler(p, f_CharData);

    return 1;
}


static int lxp_parse (lua_State *L) {
    int status;
    size_t len;
    const char *s;
    lxp_userdata *xpu;

    /* get and check first argument (should be a parser) */
    xpu = (lxp_userdata *)luaL_checkudata(L, 1, "Expat");

    /* check if it is not closed */
    luaL_argcheck(L, xpu->parser != NULL, 1, "parser is closed");

    /* get second argument (a string) */
    s = luaL_optlstring(L, 2, NULL, &len);

    /* put callback table at stack index 3 */
    lua_settop(L, 2);
    lua_getuservalue(L, 1);
    xpu->L = L; /* set Lua state */

    /* call Expat to parse string */
    status = XML_Parse(xpu->parser, s, (int)len, s == NULL);

    /* return error code */
    lua_pushboolean(L, status);
    return 1;
}

static void f_CharData (void *ud, const char *s, int len) {
    lxp_userdata *xpu = (lxp_userdata *)ud;
    lua_State *L = xpu->L;

    /* get handler from callback table */
    lua_getfield(L, 3, "CharacterData");
    if (lua_isnil(L, -1)) { /* no handler? */
        lua_pop(L, 1);
        return;
    }

    lua_pushvalue(L, 1); /* push the parser ('self') */
    lua_pushlstring(L, s, len); /* push Char data */
    lua_call(L, 2, 0); /* call the handler */
}

static void f_EndElement (void *ud, const char *name) {
    lxp_userdata *xpu = (lxp_userdata *)ud;
    lua_State *L = xpu->L;

    lua_getfield(L, 3, "EndElement");
    if (lua_isnil(L, -1)) { /* no handler? */
        lua_pop(L, 1);
        return;
    }

    lua_pushvalue(L, 1); /* push the parser ('self') */
    lua_pushstring(L, name); /* push tag name */
    lua_call(L, 2, 0); /* call the handler */
}

static void f_StartElement (void *ud,
        const char *name,
        const char **atts) {
    lxp_userdata *xpu = (lxp_userdata *)ud;
    lua_State *L = xpu->L;

    lua_getfield(L, 3, "StartElement");
    if (lua_isnil(L, -1)) { /* no handler? */
        lua_pop(L, 1);
        return;
    }

    lua_pushvalue(L, 1); /* push the parser ('self') */
    lua_pushstring(L, name); /* push tag name */

    /* create and fill the attribute table */
    lua_newtable(L);
    for (; *atts; atts += 2) {
        lua_pushstring(L, *(atts + 1));
        lua_setfield(L, -2, *atts); /* table[*atts] = *(atts+1) */
    }

    lua_call(L, 3, 0); /* call the handler */
}

static int lxp_close (lua_State *L) {
    lxp_userdata *xpu =
        (lxp_userdata *)luaL_checkudata(L, 1, "Expat");

    /* free Expat parser (if there is one) */
    if (xpu->parser)
        XML_ParserFree(xpu->parser);
    xpu->parser = NULL; /* avoids closing it again */
    return 0;
}

#endif
