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


> **译注**：由于这里用到 C 的 `math.h` 库，因此在不仅要 `#include <math.h>`，在编译时还要加上 GCC 的 `-lm` 命令行开关。

```console
gcc -o test c_func.c calling_c_lib.c -llua -ldl -lm
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


他以 `luaL_checkstring`（相当于字符串的 `luaL_checknumber`）获取目录路径开始。然后他以 `opendir` 打开该目录。若无法打开该目录，该函数将返回 `nil` 以及一条以 `strerror` 得到的错误消息。打开目录后，该函数会创建一个新表，并将目录条目填入其中。(每次咱们调用 `readdir`，他都会返回下一条目。）最后，他会关闭该目录并返回 `1`，在 C 种，这意味着他将把栈顶部的值返回给 Lua。(请记住，`lua_settable` 会弹出栈上的键与值。因此，在循环结束后，栈顶部的元素就是结果表。）


在某些情况下，`l_dir` 的这种实现可能会引起内存泄漏。他调用的三个 Lua 函数：`lua_newtable`、`lua_pushstring` 和 `lua_settable`，可能会因内存不足而失败。若这些函数中的任何一个失败，其都将抛出错误并中断 `l_dir`，从而导致其无法调用 `closedir`。在第 32 章 [“管理资源”](./resource.md) 中，我们将看到纠正此问题的目录函数另一种实现方法。


## 连续性

**Contiuations**

经由 `lua_pcall` 与 `lua_call`，从 Lua 调用的 C 函数，可以回调 Lua。标准库中有几个函数，就可以做到这一点：`table.sort` 可以调用一个排序函数；`string.gsub` 可以调用一个重置函数；`pcall` 与 `xpcall` 可调用保护模式下的函数。若我们还记得 Lua 主代码本身，即是从 C（主机程序）调用的，那么我们就有了这样一个调用序列：C（主机）调用 Lua (脚本），Lua 调用 C（库），而 C 又调用 Lua（回调）。


通常情况下，Lua 可以顺利处理这些调用序列；毕竟，与 C 的集成是该语言的一大特点。但在有一种情况下，这种置换可能会造成困难：即协程。


Lua 中的每个协程，都有其自己的栈，栈上保存着该协程的待调用信息。具体来说，栈存储了每次调用的返回地址、参数及本地变量。对于到 Lua 函数的调用，解释器只需要这个栈，我们称之为 *软栈，soft stack*。但是，对于到 C 函数的调用，解释器还必须使用 C 栈。毕竟，C 函数的返回地址与本地变量，都在 C 栈上。


解释器很容易有多个软栈，但 ISO C 的运行时，则只有一个内部栈。因此，Lua 中的协程无法暂停 C 函数的执行：如果在从某个 resume 到对应的 yield 调用路径中，存在某个 C 函数，Lua 就无法保存该 C 函数的状态，以便在下一次 resume 中恢复该 C 函数。请看下一个 Lua 5.1 中的示例：


```lua
co = coroutine.wrap(function ()
                        print(pcall(coroutine.yield))
                    end)
co()
    --> False attempt to yield across metamethod/C-call boundary
```


其中函数 `pcall` 是个 C 函数；因此，Lua 5.1 无法暂停他，因为 ISO C 中没有暂停某个 C 函数并在稍后恢复的方法。



Lua 5.2 及以后的版本，改善了 *连续性，contiuations* 下的困难。Lua 5.2 使用长跳转，long jumps，来实现 yields，这与其实现报错的方式相同。长跳转会简单地丢弃 C 栈中有关 C 函数的任何信息，因此无法继续执行这些函数。不过，某个 C 函数 `foo` 可以指定一个延续函数 `foo_k`，即在恢复 `foo` 时调用的另一个 C 函数。也就是说，当解释器检测到他应继续执行 `foo`，但某个长跳转丢弃了 C 栈中 `foo` 的条目时，他便会调用 `foo_k`。


为了让事情更具体，我们来以 `pcall` 的实现为例。在 Lua 5.1 中，该函数的代码如下：


```c
static int luaB_pcall (lua_State *L) {
    int status;

    luaL_checkany(L, 1); /* at least one parameter */
    status = lua_pcall(L, lua_gettop(L) - 1, LUA_MULTRET, 0);
    lua_pushboolean(L, (status == LUA_OK)); /* status */
    lua_insert(L, 1); /* status is first result */

    return lua_gettop(L); /* return status + all results */
}
```

若经由 `lua_pcall` 调用的函数避让了，那么以后就不可能继续执行 `luaB_pcall`。因此，每当我们试图在某个受保护调用中避让时，解释器都会抛出错误。Lua 5.3 对 `pcall` 的实现，大致如图 29.2 “使用连续调用实现 `pcall`” 所示 <sup>2</sup>。


<a name="f-29.2"></a> **图 29.2，使用连续调用实现 `pcall`**


```c
static int finishpcall (lua_State *L, int status, intptr_t ctx) {
    (void)ctx; /* unused parameter */

    status = (status != LUA_OK && status != LUA_YIELD);
    lua_pushboolean(L, (status == 0)); /* status */
    lua_insert(L, 1); /* status is first result */

    return lua_gettop(L); /* return status + all results */
}
static int luaB_pcall (lua_State *L) {
    int status;

    luaL_checkany(L, 1);
    status = lua_pcallk(L, lua_gettop(L) - 1, LUA_MULTRET, 0,
                        0, finishpcall);

    return finishpcall(L, status, 0);
}
```

> **脚注**：
>
> <sup>2</sup>：Lua 5.2 中连续操作的 API 有点不同。详情请查看参考手册。


与 Lua 5.1 版本相比，其中有三个重要区别：首先，新版本以调用 `lua_pcallk` 代替了 `lua_pcall` 调用；其次，他将调用后的所有操作，都放到了一个新的辅助函数 `finishpcall` 中；第三，`lua_pcallk` 返回的状态，除了 `LUA_OK` 或错误外，还可以是 `LUA_YIELD`。


在没有避让时，`lua_pcallk` 的工作方式与 `lua_pcall` 完全相同。然而，若存在避让，则情况就完全不同了。如果原始的 `lua_pcall` 调用的函数试图避让，Lua 5.3 就会像 Lua 5.1 一样抛出错误。但是，当新的 `lua_pcallk` 调用的函数产生 yield 时，则不会出现错误： Lua 会进行一次长跳转，并丢弃 C 栈上 `luaB_pcall` 的条目，但会在协程的软栈中，保留给到 `lua_pcallk` 延续函数的一个引用（在我们的例子中为 `finishpcall`）。稍后，当解释器检测到应该返回 `luaB_pcall`（这是不可能的）时，就会调用该延续函数。


当出现错误时，延续函数 `finishpcall` 也可被调用。与最初的 `luaB_pcall` 不同，`finishpcall` 无法获取 `lua_pcallk` 返回的值。因此，他会将该值作为一个额外参数 `status` 获取。在没有错误的情况下，`status` 为 `LUA_YIELD`，而不是 `LUA_OK`，这样该延续函数就可以检查他是如何被调用的。若出现错误，`status` 就是原来的错误代码。


除了调用状态外，continuation 函数还会接收上下文。lua_pcallk 的第五个参数是一个任意整数，作为最后一个参数传递给延续函数。(该参数的类型为 intptr_t，允许将指针作为上下文传递）。这个值允许原始函数直接向其延续函数传递一些任意信息。(我们的示例没有使用这一功能）。


除调用状态外，这个延续函数还会收到一个 *上下文*。`lua_pcallk` 的第五个参数是个任意整数，作为最后一个传递给延续函数的参数。(该参数的类型为 `intptr_t`，允许将指针作为上下文传递）。这个值允许原始函数，直接向其延续函数传递一些任意信息。(我们的示例并未使用这一设施。）


Lua 5.3 的延续系统，是一种支持 yields 的巧妙机制，但他并非万能的。某些 C 函数需要向其延续传递过多的上下文。例如，用到 C 栈进行递归的 `table.sort`，以及必须跟踪捕获及其部分结果缓冲区的 `string.gsub`。虽然以 "yieldable" 方式重写他们是可行的，但所带来的收益似乎并不值得额外的复杂度和性能损失。


## C 模组

所谓 Lua 模组，是某个定义了多个 Lua 函数，并通常将其作为表中的条目，存储在适当位置的代码块。而 Lua 的 C 模组则模仿了这种行为。除定义一些 C 函数外，他还必须定义一个在 Lua 库中扮演主代码块角色的特殊函数。该函数应注册该模组的所有 C 函数，并将他们存储在适当位置，通常也是作为表中的条目。与 Lua 的主代码块一样，他也应初始化该模组中，其他需要初始化的内容。


Lua 经由这个注册过程，感知到这些 C 函数。一旦某个 C 函数被表示并存储在 Lua 中，Lua 就会通过到其地址的一个直接引用（也就是我们在注册该函数时，向 Lua 提供的地址）来调用他。换句话说，一旦某个函数注册后，Lua 将不依赖于函数名称、包的位置，或可见性规则调用该函数。通常情况下，某个 C 语言模组，只有一个公共（外部）函数，即打开这个库的函数。所有其他函数都可以是私有函数，在 C 中被声明为静态函数。


当我们以 C 函数扩展 Lua 时，将代码设计为 C 模组是个好主意，即使我们只想注册一个 C 函数：我们迟早（通常更早）会需要别的函数。像往常一样，辅助库为这项工作提供了一个助手函数。宏 `luaL_newlib` 会取个 C 函数与各个函数名字的数组，并将他们全部注册到一个新表中。举个例子，假设我们想用先前定义的函数 `l_dir` 创建一个库。首先，我们必须定义出库函数：


```c
static int l_dir (lua_State *L) {
    // as before
}
```

接着，我们要声明一个带有模组中所有函数及其名字的数组。该数组有着一些类型为 `luaL_Reg` 的元素，该类型为包含了两个字段的结构体：函数名（`string`）与函数指针。


```c
static const struct luaL_Reg mylib [] = {
    {"dir", l_dir},
    {NULL, NULL} /* sentinel */
};
```

在咱们的示例中，只需声明一个函数 ( `l_dir` )。该数组中的最后一对，总是 `{NULL, NULL}`，标记其结束。最后，使用 `luaL_newlib`，咱们声明出一个主函数：


```c
int luaopen_mylib (lua_State *L) {
    luaL_newlib(L, mylib);
    return 1;
}
```


到 `luaL_newlib` 的调用会创建出一个新表，并在其中填入由数组 `mylib` 所指定的名称-函数对。当其返回时，`luaL_newlib` 会在栈上留下其所打开库的新表。然后函数 `luaopen_mylib` 会返回 `1`，而将此表返回给 Lua。


完成这个库后，我们必须将其链接到解释器。若咱们的 Lua 解释器支持动态链接设施，那么最方便的方法，就是使用这一设施。在这种情况下，咱们必须创建一个包含咱们代码的动态链接库（Windows 系统中为 `mylib.dll`，Linux 系统中为 `mylib.so`），并将其放在 C 路径中的某处。完成这些步骤后，咱们就可以使用 `require`，直接从 Lua 中加载咱们的库了：


> **译注**：有关使用 GCC 编译 `.so` 的过程，请参阅：[Shared libraries with GCC on Linux](https://www.cprogramming.com/tutorial/shared-libraries-linux-gcc.html)。


```lua
local mylib = require "mylib"
```

该调用会将动态库 `mylib` 与连接到 Lua，找到函数 `luaopen_mylib`，将其注册为 C 函数，并调用他打开模组。(这种行为就解释了，为何 `luaopen_mylib` 必须有着与其他 C 函数同样的原型。）


动态链接器必须知道函数 `luaopen_mylib` 的名字才能找到他。他会一直查找与模组名称连接的 `luaopen_`。因此，如果我们的模组名为 `mylib`，则该函数应称为 `luaopen_mylib`。(我们在第 17 章 [“模组和包”](./modules_and_packages.md) 中，讨论了函数名字的细节。）


若咱们的解释器不支持动态链接，那么咱们就必须以咱们的新库，重新编译 Lua。除重新编译外，咱们还需以某种方式，告诉独立解释器在打开新状态时，应该打开这个库。一种简单的方法，是在 `linit.c` 文件中，将 `luaopen_mylib` 添加到由 `luaL_openlibs` 打开的标准库列表中。


## 练习


<a name="exercise-29.1"></a> 练习 29.1：请用 C 编写一个可变参数的 `summation` 函数，计算可变数量的数字参数之和：

```lua
print(summation()) --> 0
print(summation(2.3, 5.4)) --> 7.7
print(summation(2.3, 5.4, -34)) --> -26.3
print(summation(2.3, 5.4, {}))
    --> stdin:1: bad argument #3 to 'summation' (number expected, got table)
```

<a name="exercise-29.2"></a> 练习 29.2：请实现一个与标准库中 `table.pack` 相当的函数；


<a name="exercise-29.3"></a> 练习 29.3：请编写一个取任意数量参数，并以相反顺序返回他们的函数；

```lua
print(reverse(1, "hello", 20)) --> 20 hello 1
```


<a name="exercise-29.4"></a> 练习 29.4：请编写一个取一个表及一个函数，并会对表中的每个键值对，调用该函数的函数；

```lua
foreach({x = 10, y = 20}, print)
--> x 10
--> y 20
```

(提示：查看 Lua 手册中的函数 `lua_next`。）

<a name="exercise-29.5"></a> 练习 29.5：重写上一练习中的函数 `foreach`，使被调用的函数能够避让；



<a name="exercise-29.6"></a> 练习 29.6：请创建一个带有前面练习中的所有函数的 C 模组。


（End）



