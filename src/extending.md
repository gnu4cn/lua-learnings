# 扩展咱们的应用


Lua 的一个重要用途，是作为一种 *配置* 语言。在本章中，我们将从一个简单的示例开始，演示咱们可以怎样使用 Lua，配置某个程序，并将该示例发展为完成愈加复杂的任务。


## 基础


作为咱们的首个任务，我们来设想一个简单的配置场景：咱们的 C 程序有一个窗口，且咱们希望用户能够指定初始的窗口大小。显然，对于这样一个简单任务，相比使用 Lua，有好几种更简单的选项，比如环境变量或有着一些名字-值对的文件。但即便使用简单的文本文件，我们也必须对其进行某种解析；因此，我们决定使用 Lua 的配置文件（即碰巧是各 Lua 程序的纯文本文件）。在其最简单的形式中，该文件可包含类似下面的内容：


```lua
-- define window size
width = 200
height = 300
```

现在，我们必须使用 Lua API 指导 Lua 解析该文件，然后获取全局变量 `width` 和 `height` 的值。图 28.1 “从配置文件中获取用户信息” 中的函数 `load` 完成了这项工作。

<a name="f-28.1"></a> **图 28.1，从配置文件中获取用户信息**


```c
{{#include ../scripts/extending/getting_user_info.c:5:}}
```

其假定咱们已经按照上一章的方法，创建出了个 Lua 状态。其调用 `luaL_loadfile`，从文件 `fname` 中加载 Lua 块，然后调用 `lua_pcall` 运行编译后的程序块。若出现错误（比如咱们配置文件中的语法错误），这些函数就会将错误信息推送到栈上，并返回一个非零的错误代码；然后我们的程序会以索引 `-1`，使用 `lua_tostring` 从栈顶部获取信息。(在 [“首个示例”](./overview_C-API.md#首个示例) 小节中，咱们定义了函数 `error`。）

运行该 Lua 代码块后，程序就需要获取到全局变量的值。为此，其调用了辅助函数 `getglobint`（见图 28.1 [“从配置文件获取用户信息”](#f-28.1) ）两次。该函数首先调用 `lua_getglobal`，其唯一参数（除那个无处不在的 `lua_State` 外），将相应的全局值推入栈上。接下来，`getglobint` 使用 `lua_tointegerx`，将该值转换为整数，确保其有着正确的类型。


值得用 Lua 来完成这项任务吗？正如我（作者）之前所说，对于这样一个简单任务，使用只有两个数字的简单文件，会比使用 Lua 更容易。即便如此，使用 Lua 还是有些优势。首先，Lua 为我们处理了所有语法细节；我们的配置文件甚至可以有注释！其次，用户已经可以使用他，完成一些复杂的配置。例如，这个脚本可以提示用户一些信息，或者查询环境变量以选择合适的大小：


```lua
-- configuration file
if getenv("DISPLAY") == ":0.0" then
    width = 300; height = 300
else
    width = 200; height = 200
end
```

即使在如此简单的配置场景下，也很难预见用户想要什么。但是，只要脚本定义这两个变量，咱们的 C 应用就可以无需更改。

使用 Lua 的最后一个原因，是现在可以很容易地为咱们的程序添加新的配置设施；这种便利促成了一种造成程序更加灵活的态度。

> **译注**：译者测试本小节的代码时，已将函数 `error`、`getglobint` 与 `load` 三个函数放入单独库文件 `extending_lib.h`，并通过头文件 `extending_lib.h` 实现在 C 主文件 `main.h` 中导入，最后通过编译命令 `gcc -o test main.c extending_lib.c -llua -ldl` 编译为二进制可执行文件。
>
> 除上一章中提到的 “C 代码中的 `static` 函数，应直接写在头文件中”，类型定义也需写在头文件中。
>
> 三个文件如下。

- *`extending_lib.c`*

```c
{{#include ../scripts/extending/extending_lib.c}}
```


- *`extending_lib.h`*

```c
{{#include ../scripts/extending/extending_lib.h}}
```


- *`main.c`*


```c
{{#include ../scripts/extending/main.c}}
```

> 参考：[C header issue: #include and "undefined reference"](https://stackoverflow.com/a/10357161/12288760)


## 表的操作


咱们来采取这一态度：现在，我们还要为窗口配置某种背景颜色。我们假设最终的颜色规范，是由三个数字组成，其中每个数字都是 RGB 中的一个颜色分量。在 C 语言中，这些数字通常是如 `[0,255]` 这样范围中的整数。在 Lua 中，我们将使用更自然的范围 `[0,1]`。

这里最简单的方法，是要求用户在不同的全局变量中设置每种颜色分量：


```lua
-- configuration file
width = 200
height = 300
background_red = 0.30
background_green = 0.10
background_blue = 0
```


这种方法有两个缺点：过于繁琐（实际程序可能需要数十种不同的颜色，如窗口背景、窗口前景、菜单背景等）；而且无法预定义一些常用颜色，如此用户以后只需写下 `background = WHITE` 即可。为避免这些缺点，我们将使用一个表来表示某种颜色：


```lua
background = {red = 0.30, green = 0.10, blue = 0}
```

表的使用赋予脚本更多结构；现在，用户（或应用程序）预定义一些颜色，以便以后在配置文件中使用就容易了：


```lua
BLUE = {red = 0, green = 0, blue = 1.0}
-- other color definitions
background = BLUE
```

要在 C 中获取这些值，我们可以这样做：


```c
lua_getglobal(L, "background");
if (!lua_istable(L, -1))
    error(L, "'background' is not a table");

red = getcolorfield(L, "red");
green = getcolorfield(L, "green");
blue = getcolorfield(L, "blue");
```

我们首先获取全局变量 `background` 的值，确保他是个表；然后咱们使用 `getcolorfield`，获取每个颜色分量。


当然，函数 `getcolorfield` 并非 Lua API 的一部分；我们必须定义出他。我们再次面临了多态的问题：潜在有多种版本的 `getcolorfield` 函数，他们在键类型、值类型、错误处理等方面各不相同。Lua API 提供了一个适用于所有类型的函数 `lua_gettable`。他会取得该表在堆栈中的位置，从栈上弹出键，并推送对应值。图 28.2 “一种特定的 `getcolorfield` 实现” 中，定义了咱们专属的 `getcolorfield` 实现。


<a name="f-28.2"></a> **图 28.2，一种特定 `getcolorfield` 实现**


```c
/* assume that table is on the top of the stack */
int getcolorfield (lua_State *L, const char *key) {
    int result, isnum;

    lua_pushstring(L, key); /* push key */
    lua_gettable(L, -2); /* get background[key] */

    result = (int)(lua_tonumberx(L, -1, &isnum) * MAX_COLOR);
    if (!isnum)
        error(L, "invalid component '%s' in color", key);

    lua_pop(L, 1); /* remove number */
    return result;
}
```

这种特定实现，假定了颜色表是在栈的顶部；因此，在以 `lua_pushstring` 推送出键后，该表将位于索引 `-2` 处。在返回值前，`getcolorfield` 会从栈上弹出获取到的值，让栈保持在该调用前的级别。


我们将进一步扩展咱们的示例，而为用户引入颜色名称。用户仍然可以使用颜色表，但也可以使用更常见颜色的一些预定义名字。为实现这一功能，我们需要 C 应用中的一个颜色表：


```c
    struct ColorTable colortable[] = {
        {"WHITE", MAX_COLOR, MAX_COLOR, MAX_COLOR},
        {"RED", MAX_COLOR, 0, 0},
        {"GREEN", 0, MAX_COLOR, 0},
        {"BLUE", 0, 0, MAX_COLOR},
        // other colors
        {NULL, 0, 0, 0} /* sentinel */
    };
```

咱们的实现将以颜色名字，创建处一些全局变量，并使用颜色表初始化这些变量。其结果与用户在脚本中输入以下的行相同：

```lua
WHITE = {red = 1.0, green = 1.0, blue = 1.0}
RED = {red = 1.0, green = 0, blue = 0}
-- other colors
```

要设置该表的字段，我们要定义一个辅助函数 `setcolorfield`；他会将索引和字段值推入栈，然后调用 `lua_settable`：


```c
/* assume that table is on top */
void setcolorfield (lua_State *L, const char *index, int value) {
    lua_pushstring(L, index); /* key */
    lua_pushnumber(L, (double)value / MAX_COLOR); /* value */
    lua_settable(L, -3);
}
```

与其他 API 函数一样，`lua_settable` 适用于多种不同类型，因此他会获取到栈上的其所有操作数。他会将表的索引作为参数，并弹出键与值。函数 `setcolorfield` 假定了在该调用前，表位于栈顶部（索引 `-1`）；在推入索引与值后，该表将位于索引 `-3` 处。


下一函数 `setcolor` 会定义出某种颜色。他会创建一个表，设置相应字段，并将该表赋值给对应的全局变量：


```c
void setcolor (lua_State *L, struct ColorTable *ct) {
    lua_newtable(L); /* creates a table */
    setcolorfield(L, "red", ct->red);
    setcolorfield(L, "green", ct->green);
    setcolorfield(L, "blue", ct->blue);
    lua_setglobal(L, ct->name); /* 'name' = table */
}
```


函数 `lua_newtable` 会创建出一个空表，并将其推入栈上；三次对 `setcolorfield` 的调用，设置该了表的字段；最后，`lua_setglobal` 会弹出该表，并将其设置为给定名字的全局变量的值。


有了前面的这两个函数，下面的循环将为配置脚本注册所有颜色：


```c
    int i = 0;
    while (colortable[i].name != NULL)
        setcolor(L, &colortable[i++]);
```


请记住，应用必须在运行脚本前执行这个循环。


图 28.3 “作为字符串或表的颜色”，给出了实现命名颜色的另一选项。


<a name="f-28.3"></a> **图 28.3 “作为字符串或表的颜色**


```c
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
```


用户可以用字符串，代替全局变量来表示颜色名字，将其设置写成 `background = “BLUE”`。因此，`background` 既可以是表，也可以是字符串。在这种设计下，应用在运行用户脚本之前不需要做任何事情。相反，他需要做更多工作，来获取到颜色。在获取到变量 `background` 的值时，应用必须测试该值是否是个字符串，然后在颜色表中查找该字符串。

最佳选项为何呢？在 C 程序中，使用字符串表示颜色选项不是种好的做法，因为编译器无法检测拼写错误。但在 Lua 中，拼写错误的颜色的错误信息，将可能被这个配置“程序”作者看到。程序员和用户间的区别是模糊的，因此编译错误和运行时错误之间的区别也是模糊的。


在字符串下，`background` 的值就是那个拼写错误的字符串；因此，应用可将这一信息，添加到错误消息。应用还可以比较字符串的大小写，因此用户可以写下 `"white"`、`"WHITE"` 甚至 `"White"`。此外，在用户脚本较小，而颜色又很多时，那么当用户仅需要几种颜色，而要注册数百种颜色（并创建出数百个表与全局变量）的效率可能会很低。在字符串下，我们就可以避免这种开销。


## 一些捷径

虽然 C API 追求简单，但 Lua 并不激进。因此，API 为一些常用操作，提供了快捷方式。咱们来看看其中的一些。


由于使用字符串的键，索引某个表非常常见，因此 Lua 为这种情况专门设计了一个 `lua_gettable` 版本：`lua_getfield`。使用这个函数，我们可以重写 `getcolorfield` 中的以下两行：

```c
lua_pushstring(L, key);
lua_gettable(L, -2); /* get background[key] */
```

为：


```c
lua_getfield(L, -1, key); /* get background[key] */
```

(由于我们没有将该字符串推入栈上，因此当我们调用 `lua_getfield` 时，表的索引仍为 `-1`。）


由于检查 `lua_gettable` 返回值的类型很常见，故在 Lua 5.3 中，该函数（以及类似函数，如 `lua_getfield`）现在会返回其结果的类型。因此，我们可进一步简化 `getcolorfield` 中的访问与检查：


```c
    if (lua_getfield(L, -1, key) != LUA_TNUMBER)
        error(L, "invalid component '%s' in color", key);
```

如咱们所料，Lua 还为字符串的键，提供了 `lua_settable` 的一个称为 `lua_setfield` 的专门版本。使用这个函数，我们可将之前的 `setcolorfield` 定义重写如下：


```c
void setcolorfield (lua_State *L, const char *index, int value) {
    lua_pushnumber(L, (double)value / MAX_COLOR);
    lua_setfield(L, -2, index);
}
```

作为一个小的优化，我们还可以替换函数 `setcolor` 中 `lua_newtable` 的使用。Lua 提供了另一个函数 `lua_createtable`，其间咱们会创建出一个表并为条目预分配空间。Lua 如下声明了这些函数：


```c
void lua_createtable (lua_State *L, int narr, int nrec);
#define lua_newtable(L) lua_createtable(L, 0, 0)
```

其中参数 `narr` 是表的序列部分（即具有连续整数索引的那些条目）的预期元素数目，`nrec` 是其他元素的预期数目。在 `setcolor` 中，我们可以写下 `lua_createtable(L,0,3)`，作为该表将获得三个条目的提示。(当我们写下某个构造函数时，Lua 代码也会执行类似的优化。）


## 调用 Lua 函数



