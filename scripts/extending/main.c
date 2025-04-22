#include <stdio.h>
#include <string.h>
#include "lauxlib.h"
#include "extending_lib.h"

int main (void) {
    int width, height, red, green, blue;
    struct ColorTable colortable[] = {
        {"WHITE", MAX_COLOR, MAX_COLOR, MAX_COLOR},
        {"RED", MAX_COLOR, 0, 0},
        {"GREEN", 0, MAX_COLOR, 0},
        {"BLUE", 0, 0, MAX_COLOR},
        // other colors
        {NULL, 0, 0, 0} /* sentinel */
    };

    lua_State *L = luaL_newstate();
    load(L, "conf.lua", &width, &height);
    printf("%d, %d\n", width, height);

    lua_getglobal(L, "background");
    if (lua_isstring(L, -1)) { /* value is a string? */
        const char *colorname = lua_tostring(L, -1); /* get string */

        int i; /* search the color table */
        for (i = 0; colortable[i].name != NULL; i++) {
            if (strcmp(colorname, colortable[i].name) == 0)
                break;
        }

        if (colortable[i].name == NULL) /* string not found? */
            error(L, "invalid color name (%s)", colorname);
        else { /* use colortable[i] */
            red = colortable[i].red;
            green = colortable[i].green;
            blue = colortable[i].blue;
        }
    } else if (lua_istable(L, -1)) {
        red = getcolorfield(L, "red");
        green = getcolorfield(L, "green");
        blue = getcolorfield(L, "blue");
    } else
        error(L, "invalid value for 'background'");

    printf("%d, %d, %d\n", red, green, blue);

    lua_close(L);
    return 0;
}
