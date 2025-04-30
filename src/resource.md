# 管理资源

在上一章中的布尔数组实现里，我们无需担心资源管理问题。这些数组只需要内存。表示某个数组的每个用户数据，都有其自己的内存，由 Lua 管理。当某个数组成为垃圾（即无法由程序访问到）时，Lua 最终会将其回收，并释放其内存。


生活并不总是那么简单。有时，除了原始内存，对象还需要其他资源，如文件描述符、窗口句柄等。(这些资源通常也只是内存，但由系统的其他部分管理。）在这种情况下，当对象成为垃圾并被回收时，这些别的资源也必须以某种方式释放。


正如我们在 [“终结器”](./garbage.md#终结器) 小节中所看到的，Lua 以 `__gc` 元方法的形式，提供了终结器。为了说明在 C 中，以及这个 API 作为整体下，这个元方法的用法，我们将在本章中，开发两项外部设施的 Lua 绑定。第一个示例，是一个遍历目录函数的另一种实现。第二个（也是更重要的）示例，是对一种开源 XML 解析器，[`Expat`](https://libexpat.github.io/) 的绑定。


## 一个目录迭代器

在名为 [“C 函数”](./calling_c.md#c-函数) 的小节中，我们实现了个遍历目录，返回带有给定目录中所有文件的一个表的函数 `dir`。我们的新实现，将返回一个每次调用时，都会返回一个新条目的迭代器。在这个新实现下，我们就可以像这样，循环遍历某个目录了：


```lua
local dir = require "dir"

for fname in dir.open(".") do
    print(fname)
end
```

在 C 中，要遍历某个目录，我们需要一个 `DIR` 结构体。`DIR` 实例由 `opendir` 创建，并必须通过调用 `closedir` 显式释放。我们先前的实现，将 `DIR` 实例作为局部变量保存，并在获取到最后一个文件名后，关闭该实例。我们的新实现，无法将这个 `DIR` 实例保存在某个本地变量中，因为新实现必须在多次调用间查询这个值。此外，新实现还无法仅在获取到最后一个文件名后，才关闭目录；若程序中断了循环，其中的迭代器将永远不会获取到最后的文件名。因此，为了确保这个 `DIR` 实例总是被释放，我们将把他的地址，存储在某个用户数据中，并使用这个用户数据的 `__gc` 元方法，释放该目录结构体。


尽管用户数据在我们的实现中起着核心作用，但这个表示某个目录的用户数据，并不需要对 Lua 可见。函数 `dir.open` 会返回一个迭代函数，Lua 看到的就是这个函数。目录可以是这个迭代函数的上值。因此，这个迭代器函数有着对此结构体的直接访问，但 Lua 代码却无（也不需要）。


我们总共需要三个 C 函数。

- 首先，我们需要函数 `dir.open`，这是 Lua 创建迭代器时调用的工厂函数；他必须要打开某个 `DIR` 结构体，并以该结构体作为上值，创建出迭代器函数的闭包；
- 其次，我们需要这个迭代器函数；
- 第三，我们需要关闭 `DIR` 结构体的 `__gc` 元方法。


像往常一样，我们还需要一个进行初始安排，例如创建和初始化目录元表的额外函数。


我们来以从图 32.1 “`dir.open` 工厂函数” 中给出的函数 `dir.open`，开始我们的代码，。


<a name="f-32.1"></a> **图 32.1，`dir.open` 工厂函数**


```c
#include <dirent.h>
#include <errno.h>
#include <string.h>
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
```


该函数的一个微妙之处在于，在打开目录前，他必须创建出用户数据。如果先打开目录，随后对 `lua_newuserdata` 的调用就会抛出一个内存报错，该函数就会丢失并泄漏其中的 `DIR` 结构体。在正确顺序下，这个 `DIR` 结构体一旦创建，就会立即与该用户数据关联；无论之后发生什么，`__gc` 元方法最终都将释放该结构体。


另一个微妙之处在于其中用户数据的一致性。一旦我们设置了他的元表，`__gc` 这个元方法无论如何都会被调用。因此，在设置元表前，我们先以 `NULL` 初始化了这个用户数据，确保他有着明确定义的值。


接下来的函数是迭代器 `dir_iter` 本身（见图 32.2 “`dir` 库的其他函数”）。


<a name="f-32.2"></a> **图 32.2，`dir` 库的其他函数**


```c
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


int luaopen_dir (lua_State *L) {
    luaL_newmetatable(L, "LuaBook.dir");

    /* set its __gc field */
    lua_pushcfunction(L, dir_gc);
    lua_setfield(L, -2, "__gc");

    /* create the library */
    luaL_newlib(L, dirlib);

    return 1;
}
```

其代码简单明了。他会从其上值，获取到 `DIR` 结构体的地址，然后调用 `readdir` 读取下一个条目。


函数 `dir_gc`（也在 图 32.2 [“`dir` 库的其他函数”](#f-32.2) 中）便是 `__gc` 这个元方法。这个元方法会关闭某个目录。正如我们前面提到的，他必须采取一种预防措施：如果初始化过程中出错，目录便可以是 `NULL`。


图 32.2 [“`dir` 库的其他函数”](#f-32.2) 中最后一个函数 `luaopen_dir`，就是打开这个一个函数的库的函数。


这个完整示例，有个有趣的微妙之处。起初，`dir_gc` 似乎应该检查其参数是否是个目录，以及目录是否已经关闭。否则，恶意用户就可以用另一种用户数据（例如文件）来调用他，或者终结某个目录两次，从而造成灾难性后果。然而，Lua 程序是无法访问到这个函数的：他只存储在目录的元表中，而目录又存储为迭代函数的上值。Lua 程序无法访问到这些目录。


## 一个 XML 解析器


现在我们将看一个 Expat 的 Lua 绑定简化实现，我们称之为 `lxp`。Expat 是个用 C 编写的开源 XML 1.0 解析器。他实现了 XML 的简单 API，SAX，Simple API for XML。所谓 SAX，是一种基于事件的 API。这意味着，SAX 的解析器会读取某个 XML 文档，并随着读取的进行，会经由回调向应用报告他所发现的内容。例如，在我们指示 Expat 解析一个字符串，如 `"<tag cap="5">hi</tag>"`，他会产生三个事件：

- 读取到子串 `"<tag cap="5">"`时，会产生一个 *起始元素* 事件，a *start-element* event；
- 读取到 `"hi"` 时，会产生一个 *文本* 事件，a *text* event（也称为 *字符数据* 事件，a *character data* event）；
- 读取到 `"</tag>"` 时，会产生一个 *结束元素* 事件，a *end-element* event。


这每个事件，都会调用应用中的一个相应的 *回调处理程序*，an appropriate *callback handler*。


在这里，我们不会介绍整个 Expat 库。我们将仅专注于那些，能说明与 Lua 交互的新技术的部分。尽管 Expat 要处理十多种不同事件，但我们将只考虑前面示例中，看到的三种事件（开始元素、结束元素及文本）。<sup>1</sup>

> **脚注**：
>
> <sup>1</sup> `LuaExpat` 包提供了到 Expat 的一个相当完整的接口。


本例中咱们所需的 Expat API 部分很小。首先，我们需要创建及销毁某个 Expat 解析器的函数：


```c
XML_Parser XML_ParserCreate (const char *encoding);
void XML_ParserFree (XML_Parser p);
```

其中参数 `encoding` 是可选的，我们将在咱们的绑定中使用 `NULL`。


在咱们有了一个解析器后，我们必须注册其回调处理程序：


```c
void XML_SetElementHandler(XML_Parser p,
        XML_StartElementHandler start,
        XML_EndElementHandler end);
void XML_SetCharacterDataHandler(XML_Parser p,
        XML_CharacterDataHandler hndl);

```

其中第一个函数，注册了开始和结束元素的处理程序。第二个函数注册了文本（XML 术语中的 *字符数据*）的处理程序。


所有回调处理程序，都会取一个用户数据，作为其第一个参数。起始元素处理程序还会接收标签名字及其属性：


```c
typedef void (*XML_StartElementHandler)(void *uData,
        const char *name,
        const char **atts);

```


属性是一些以 `NULL` 结尾字符串的数组，其中每对连续字符串，保存着一个属性名字及其值。结束元素处理程序则仅有一个额外参数，即标签名字：


```c
typedef void (*XML_EndElementHandler)(void *uData,
        const char *name);
```

最后，文本处理程序只接收文本作为额外参数。这个文本字符串不是 `null` 结束的，而有着显式的长度：


```c
typedef void (*XML_CharacterDataHandler)(void *uData,
        const char *s,
        int len);
```


要将文本投喂给 Expat，我们使用了以下函数：


```c
int XML_Parse (XML_Parser p, const char *s, int len, int isLast);
```

经由到函数 `XML_Parse` 的连续调用，Expat 就会收到要解析为片段的文档。`XML_Parse` 的最后一个参数是个布尔值 `isLast`，他告诉 Expat 该片段是否是某个文档的最后一个片段。在检测到解析错误时，该函数会返回零。(Expat 还提供了获取错误信息的函数，但为了简单起见，我们在此将忽略他们。）



我们需要的 Expat 中最后一个函数，允许我们设置将传递给处理程序的用户数据：


```c
void XML_SetUserData (XML_Parser p, void *uData);
```

现在，我们来看看如何在 Lua 中，使用这个库。第一种方法是直接方式：只需将所有这些函数导出到 Lua 即可。更好的方法是把这些功能适配到 Lua。例如，由于 Lua 是无类型的，我们不需要设置每种回调的不同函数。更妙的是，我们可以完全避免这些回调的函数注册。相反，在我们创建解析器时，我们会给出一个包含所有回调处理程序的回调表，其中每个回调处理程序，都有一个与其对应事件相关的对应键。例如，在我们要打印某个文档的布局时，就可以使用以下回调表：


```lua
local count = 0

callbacks = {
    StartElement = function (parser, tagname)
        io.write("+ ", string.rep(" ", count), tagname, "\n")
        count = count + 1
    end,

    EndElement = function (parser, tagname)
        count = count - 1
        io.write("- ", string.rep(" ", count), tagname, "\n")
    end,
}
```


若以输入 `"<to> <yes/> </to>"` 投喂，那么这些处理程序就会打印这样的输出：


```console
+ to
+   yes
-   yes
- to
```

在这个 API 下，我们就不需要函数来操作回调了。我们直接在回调表中操作他们。因此，整个 API 只需要三个函数：

- 一个创建出解析器；
- 一个解析文本片段；
- 以及一个用于关闭解析器。


实际上，我们将把后两个函数，作为解析器对象的方法实现。该 API 的典型用法如下：


```lua
local lxp = require "lxp"

p = lxp.new(callbacks) -- create new parser

for l in io.lines() do -- iterate over input lines
    assert(p:parse(l)) -- parse the line
    assert(p:parse("\n")) -- add newline
end

assert(p:parse()) -- finish document
p:close() -- close parser
```

现在，我们来把注意力转向实现。首先要决定的是，如何在 Lua 中表示解析器。使用包含着一个 C 结构体的用户数据是很自然的，但我们需要在其中放入什么呢？我们至少需要具体的 Expat 解析器及回调表。我们还必须存储一个 Lua 状态，因为这些解析器对象，是 Expat 回调所接收的全部对象，而回调需要调用 Lua。我们可将 Expat 解析器和 Lua 状态（他们都是 C 值），直接存储在一个 C 结构体中。对于是个 Lua 值的回调表，一种选项是在注册表中，创建一个引用并存储该引用。(我们将在 [练习 32.2](#exercise-32.2) 中，探讨这一方案。）另一选项是使用 *用户值，a user value*。每个用户数据都可以有个与之直接相关的 Lua 值，这个值就称为用户值。<sup>2</sup> 在这一选项下，解析器对象的定义如下：


```c
#include <stdlib.h>
#include "expat.h"
#include "lua.h"
#include "lauxlib.h"

typedef struct lxp_userdata {
    XML_Parser parser; /* associated expat parser */
    lua_State *L;
} lxp_userdata;
```

> **脚注**：
>
> <sup>2</sup> 在 Lua 5.2 中，这个用户值必须为表。

接下来是创建解析器对象的函数 `lxp_make_parser`。图 32.3 “创建 XML 解析器对象的函数” 给出了该函数的代码。


<a name="f-32.3"></a> **图 32.3，创建 XML 解析器对象的函数**


```c
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
```

该函数有四个主要步骤：

- 其第一步遵循一种常见模式：首先创建出一个用户数据；然后用一致的值，预初始化该用户数据；最后设置其元表；(预初始化确保了在初始化过程中出现任何错误时，终结器会找到该处于一致状态的用户数据。）
- 在第 2 步，该函数创建出一个 Expat 解析器，将其存储在该用户数据中，并检查错误；
- 第 3 步确保了函数的第一个参数，确实是个表（回调表），并将其设置为其中新用户数据的用户值；
- 最后一步是初始化这个 Expat 解析器。他会将该用户数据，设置为要传递给回调函数的对象，并设置回调函数。请注意，这些回调函数对所有解析器都是一样的；毕竟，在 C 中动态创建新函数是不可行的，相反，这些固定的 C 函数，将使用回调表，决定他们每次应调用哪些 Lua 函数。


接下来是解析某段 XML 数据的解析方法 `lxp_parse`（图 32.4 “解析某个 XML 片段的函数”）。


<a name="f-32.4"></a> **图 32.4，解析某个 XML 片段的函数**


```c
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
```

他会获取到两个参数：解析器对象（该方法的 `self`）与可选的一段 XML 数据。在不带任何数据调用时，他会告知 Expat 文档已没有其他部分。


当 `lxp_parse` 调用 `XML_Parse` 时，后者会调用在其给定文档中找到的每个相关元素的处理程序。这些处理程序将需要访问回调表，因此 `lxp_parse` 会将这个回调表，放在栈索引 `3` 处（就在参数之后）。调用 `XML_Parse` 时还有个细节：请记住，该函数的最后一个参数会告诉 Expat，给定的文本是否是最后一段。在我们不带参数调用 `parse` 时，`s` 将为 `NULL`，因此最后一个参数将为 `true`。


现在，我们来将注意力转向处理回调的函数 `f_CharData`、`f_StartElement` 与 `f_EndElement`。所有这三个函数都有着一种类似结构：每个函数都会检查回调表，是否为其特定事件定义了个 Lua 处理程序，如果是，则会准备参数，然后调用该 Lua 处理程序。


我们先来看看图 32.5 “字符数据的处理程序” 中的 `f_CharData` 处理程序。


<a name="f-32.5"></a> **图 32.5，字符数据的处理程序**


```c
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
```


其代码非常简单。由于在创建解析器时咱们对 `XML_SetUserData` 的调用，因此该处理程序会收到第一个参数 `lxp_userdata` 结构体。在获取到 Lua 状态后，该处理程序就可以访问栈索引 `3` 处由 `lxp_parse` 设置的回调表，以及栈索引 `1` 处的解析器本身。然后，他会以两个参数：解析器及字符数据（字符串），调用 Lua 中的相应处理程序（如存在）。


`f_EndElement` 处理程序与 `f_CharData` 十分相似；参见图 32.6 “结束元素的处理程序”。

<a name="f-32.6"></a> **图 32.6，结束元素的处理程序**


```c
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
```


他同样以两个参数 -- 解析器与标记名字（同样是个字符串，但现在是 `null` 结束），调用相应的 Lua 处理程序。


图 32.7 “起始元素的处理程序”，给出了最后一个处理程序 `f_StartElement`。


<a name="f-32.7"></a> **图 32.7，起始元素的处理程序**


```c
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
```


他会以三个参数：解析器、标记名字及属性列表，调用 Lua 处理程序。这个处理程序比另外两个复杂一些，因为他需要将标签的属性列表，转换为 Lua 的列表。他使用了一种非常自然的转换方法，即构建出一个将属性名字，映射到属性值的表。例如，像下面的一个开始标签：


```xml
<to method="post" priority="high">
```

会生成以下的属性表：


```lua
{method = "post", priority = "high"}
```


解析器的最后一个方法是 `close`，如图 32.8 “关闭 XML 解析器的方法” 所示。


<a name="f-32.8"></a> **图 32.8，关闭 XML 解析器的方法**


```c
static int lxp_close (lua_State *L) {
    lxp_userdata *xpu =
        (lxp_userdata *)luaL_checkudata(L, 1, "Expat");

    /* free Expat parser (if there is one) */
    if (xpu->parser)
        XML_ParserFree(xpu->parser);
    xpu->parser = NULL; /* avoids closing it again */
    return 0;
}
```


当我们要关闭某个解析器时，我们必须释放其资源，即那个 Expat 结构体。请记住，由于在其创建过程中的偶尔出错，解析器可能没有这一资源。要注意在关闭解析器时，咱们要保持该解析器处于一致状态，如此当我们再次尝试关闭，或垃圾回收器将其终结时，就不会有问题。实际上，我们正要使用这个函数，作为终结器。这样确保了每个解析器最终都会释放其资源，即使程序员没有关闭他。



图 32.9 “`lxp` 库的初始化代码” 是最后一步：他给出了用于打开库，将前面所有部分整合在一起的 `luaopen_lxp`。


<a name="f-32.9"></a> **图 32.9，`lxp` 库的初始化代码**



```c
static const struct luaL_Reg lxp_meths[] = {
    {"parse", lxp_parse},
    {"close", lxp_close},
    {"__gc", lxp_close},
    {NULL, NULL}
};

static const struct luaL_Reg lxp_funcs[] = {
    {"new", lxp_make_parser},
    {NULL, NULL}
};

int luaopen_lxp (lua_State *L) {
    /* create metatable */
    luaL_newmetatable(L, "Expat");

    /* metatable.__index = metatable */
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");

    /* register methods */
    luaL_setfuncs(L, lxp_meths, 0);

    /* register functions (only lxp.new) */
    luaL_newlib(L, lxp_funcs);
    return 1;
}
```


这里，我们使用了与 [“面向对象的访问”](./types.md#面向对象的访问) 小节中，面向对象的布尔数组示例相同的方案：我们创建了个元表，使其 `__index` 字段指向自身，并将所有方法都放在该元表中。为此，我们需要一个包含解析器方法（`lxp_meths`）的列表。我们还需要一个包含该库的函数的列表（`lxp_funcs`）。与面向对象库的常见做法一样，该列表只有一个用于创建新解析器的函数。


> **译注**：译者在编译运行上面的代码时，使用以下命令构建 `.so` 动态链接库没有问题。

```console
gcc -c -Wall -Werror -lexpat -fpic expat_lib.c -ldl
gcc -shared -o lxp.so expat_lib.o -ldl
```

> 但在以命令 `lua demo_expat.lua`，运行示例 Lua 代码时，报出错误：

```console
lua: error loading module 'lxp' from file './lxp.so':
        ./lxp.so: undefined symbol: XML_ParserCreate
stack traceback:
        [C]: in ?
        [C]: in function 'require'
        demo_expat.lua:1: in main chunk
        [C]: in ?
```

> 看起来 Lua 解释器未能找到 Expat 的库。


## 练习


<a name="exercise-32.1"></a> 练习 32.1：请修改目录示例中的函数 `dir_iter`，使其在到达遍历末尾时，立即关闭那个 `DIR` 结构体。有了这个改动，程序就无需等待垃圾回收释放其知道的不再需要的资源。

(在咱们关闭目录时，咱们应将存储在用户数据中的地址，设置为 `NULL`，以便向终结器发出该目录已关闭的信号。此外，在使用目录之前，`dir_iter` 将必须检查目录是否已关闭。）

<a name="exercise-32.2"></a> 练习 32.2： 在 `lxp` 的示例中，我们使用了用户值，将回调表与表示解析器的用户数据关联起来。这一选择造成了一个小问题，因为 C 回调接收的是 `lxp_userdata` 结构体，而该结构体并不提供对表的直接访问。为解决此问题，通过在解析每个片段时，将回调表存储在某个固定的栈索引处，我们解决了这个问题。


另一种设计方案，是经由引用（ [“注册表” 小节](./techniques.md#注册表) ），将回调表与用户数据关联起来：我们会创建一个到该回调表的引用，并将该引用（一个整数）存储在 `lxp_userdata` 这个结构体中。请实现这个替代方案。不要忘记在关闭解析器时，释放该引用。


（End）


