#ifndef EXTENDING_LIB_H
#define EXTENDING_LIB_H

#include "lua.h"
#define MAX_COLOR 255

struct ColorTable {
    char *name;
    unsigned char red, green, blue;
};

void load (lua_State *L, const char *fname, int *w, int *h);
void _load (lua_State *L, const char *fname);
int getcolorfield (lua_State *L, const char *key);
void error (lua_State *L, const char *fmt, ...);
void setcolorfield (lua_State *L, const char *index, int value);
void setcolor (lua_State *L, struct ColorTable *ct);
double f (lua_State *L, double x, double y);
void call_va (lua_State *L, const char *func, const char *sig, ...);


static void stackDump (lua_State *L) {
    int i;
    int top = lua_gettop(L); /* depth of the stack */

    for (i = 1; i <= top; i++) { /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
            case LUA_TSTRING: { /* strings */
                printf("'%s'", lua_tostring(L, i));
                break;
            }
            case LUA_TBOOLEAN: { /* Booleans */
                printf(lua_toboolean(L, i) ? "true" : "false");
                break;
            }
            case LUA_TNUMBER: { /* numbers */
                if (lua_isinteger(L, i)) /* integer? */
                    printf("%lld", lua_tointeger(L, i));
                else /* float */
                    printf("%g", lua_tonumber(L, i));
                break;
            }
            default: { /* other values */
                printf("%s", lua_typename(L, t));
                break;
            }
        }
        printf(" "); /* put a separator */
    }
    printf("\n"); /* end the listing */
}


#endif
