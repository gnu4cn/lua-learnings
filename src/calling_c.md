# 在 Lua 中调用 C

当我们讲 Lua 可以调用 C 函数时，并不意味着 Lua 可以调用任何 C 函数。<sup>1</sup> 正如我们在上一章中所看到的，当 C 调用某个 Lua 函数时，他必须遵循一种简单协议，来传递参数及获取结果。与此类似，Lua 要调用 C 函数，则 C 函数也必须遵循一种协议，来获取参数并返回结果。此外，要让 Lua 调用 C 函数，我们必须注册该函数，也就是说，我们必须以适当方式，向 Lua 提供该函数的地址。

> **脚注**：
>
> <sup>1</sup> 有一些允许 Lua 调用任何 C 函数的包，但他们既不像 Lua 那样可移植，也不安全。

当 Lua 调用某个 C 函数时，他会用到与 C 调用 Lua 时，同一类型的堆栈。C 函数会从栈上获取参数，并将结果压入栈。


这里的重点是，这个栈并非一个全局的结构；每个函数都有其自己的私有本地栈。当 Lua 调用某个 C 函数时，第一个参数始终位于这个本地栈的索引 1 处。即使某个 C 函数调用了再次调用同一（或另一）C 函数的 Lua 代码，每次这些调用都只能看到自己的私有栈，其第一个参数都位于索引 1 处。


## C 函数


作为第一个例子，我们来看看如何实现一个返回给定数值正弦值函数的简化版本：


```c
static int l_sin (lua_State *L) {
    double d = lua_tonumber(L, 1); /* get argument */
    lua_pushnumber(L, sin(d)); /* push result */
    return 1; /* number of results */
}
```


注册到 Lua 的任何函数，都必须有以下这种同样原型，即在 `lua.h` 中定义为 `lua_CFunction`：


```c
typedef int (*lua_CFunction) (lua_State *L);
```

从 C 语言的角度来看，某个 C 函数会获取到 Lua 状态这一单一参数，并返回其于栈上返回值个数的一个整数值。因此，在将结果压入栈上前，该函数无需清除栈。在返回后，Lua 会自动保存其结果，并清除整个栈。


在从 Lua 调用该函数前，我们必须先注册他。我们可以使用 `lua_pushcfunction`，来完成这项神奇的工作：他会获取一个指向某个 C 函数的指针，并创建出一个在 Lua 中代表该函数的 `"function"` 类型值。一旦注册后，C 函数就会像 Lua 中的其他函数一样行事。


测试咱们 `l_sin` 的一种快捷方法，是将其代码直接放入我们的基本解释器（ 图 27.1，[“裸机独立 Lua 解释器”](./overview_C-API.md#f-27.1) ），并在调用 `luaL_openlibs` 后，添加以下几行：


```c
    lua_pushcfunction(L, l_sin);
    lua_setglobal(L, "mysin");
```


第一行会压入一个函数类型的值；第二行将其赋值给全局变量 `mysin`。在这些修改后，我们就可以在 Lua 脚本中使用这个新函数 `mysin` 了。在下一小节中，我们将讨论将新 C 函数与 Lua 连接起来的更好方法。在此，我们将探讨如何编写更好的 C 函数。


为了一个更专业的正弦函数，我们必须检查其参数的类型。辅助库可帮助我们完成这项任务。函数 `luaL_checknumber` 会检查某个给定参数是否为数字：如果出错，他就会抛出一条信息丰富的错误消息；相反，他会返回该数字。对咱们函数的修改微乎其微：


```c
static int l_sin (lua_State *L) {
    double d = luaL_checknumber(L, 1); /* get argument */
    lua_pushnumber(L, sin(d)); /* push result */
    return 1; /* number of results */
}
```


在上面的定义下，若咱们调用 `mysin('a')`，就会得到类似下面的报错：


```console
bad argument #1 to 'mysin' (number expected, got string)
```

函数 `luaL_checknumber` 会以参数编号（`#1`）、函数名称（`"mysin"`）、预期参数类型（`number`）及实际参数类型（`string`），填充错误消息。


举一个更复杂的例子，咱们来编写一个返回给定目录内容的函数。Lua 的标准库中并没有提供这个函数，因为 ISO C 并没有为这项作业提供函数。在此，我们假设有着兼容 POSIX 的系统。我们的函数 -- 在 Lua 中称为 `dir`，在 C 语言中称为 `l_dir` -- 会获取一个目录路径的字符串作为参数，并返回一个该目录条目的列表。例如，调用 `dir(“/home/lua”)`，就可能会返回 `{".", "..", "src", "bin", "lib"}` 这个表。该函数的完整代码，见图 29.1 “读取目录的函数”。


<a name="f-29.1"></a> **图 29.1，读取目录的函数**


```c
#include <dirent.h>
#include <errno.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

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
```



