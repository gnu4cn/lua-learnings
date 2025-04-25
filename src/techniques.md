# 编写 C 函数的一些技巧

官方 API 和辅助库，都提供了多种机制来帮助编写 C 函数。在本章中，我们将介绍数组操作、字符串操作以及用 C 存储 Lua 值的一些机制。


## 数组操作


在 Lua 中的 “数组”，只是个以特定方式使用的表。我们可使用与操作表相同的通用函数，即 `lua_settable` 与 `lua_gettable` 来操作数组。不过，API 提供了以整数键，访问和更新表的一些特殊函数：


```c
void lua_geti (lua_State *L, int index, int key);
void lua_seti (lua_State *L, int index, int key);
```


5.3 之前的 Lua 版本，只提供了这些函数的原始版本，即 `lua_rawgeti` 和 `lua_rawseti`。他们与 `lua_geti` 和 `lua_seti` 类似，但都执行原始的访问（即未调用元方法）。在差别不大（例如，表没有元方法时），原始版本可能会稍快一些。


`lua_geti` 和 `lua_seti` 的描述有点混乱，因为其涉及到两个索引：`index` 指的是该表在栈上的位置；而 `key` 指的是元素在表中的位置。当 `t` 为正数时，调用 `lua_geti(L, t, key)` 等价于下面的序列（否则，我们必须补偿栈上的新条目）：



```c
lua_pushnumber(L, key);
lua_gettable(L, t);
```

调用 `lua_seti(L, t, key)`（同样 `t` 为正）等价于此序列：


```c
lua_pushnumber(L, key);
lua_insert(L, -2); /* put 'key' below previous value */
lua_settable(L, t);
```

作为使用这些函数的一个具体示例，图 30.1 “以 C 编写的函数 `map`”，实现了函数的映射：他会将给定的函数，应用于数组的所有元素，以调用结果替换各个元素。


<a name="f-30.1"></a> **图 30.1，以 C 编写的函数 `map`**



```c
int l_map (lua_State *L) {
    int i, n;

    /* 1st argument must be a table (t) */
    luaL_checktype(L, 1, LUA_TTABLE);
    /* 2nd argument must be a function (f) */
    luaL_checktype(L, 2, LUA_TFUNCTION);

    n = luaL_len(L, 1); /* get size of table */
    for (i = 1; i <= n; i++) {
        lua_pushvalue(L, 2); /* push f */
        lua_geti(L, 1, i); /* push t[i] */
        lua_call(L, 1, 1); /* call f(t[i]) */
        lua_seti(L, 1, i); /* t[i] = result */
    }

    return 0; /* no results */
}
```

这个示例还引入了三个新的函数：`luaL_checktype`、`luaL_len` 与 `lua_call`。


函数 `luaL_checktype`（来自 `lauxlib.h`）确保了给定参数有着给定类型，否则会抛出错误。


原生的 `lua_len`（示例中未使用），与长度运算符等价。由于其用到了元方法，该运算符可能返回任何类型的对象，而不仅是数字；因此，`lua_len` 会在栈上返回其结果。而函数 `luaL_len`（示例中用到的函数，来自辅助库）则会以整数形式返回长度，在无法进行强制转换时，会抛出一个错误。


其中函数 `lua_call` 会执行一次无保护的调用。他与 `lua_pcall` 类似，但会传播错误，而不是返回错误代码。在编写应用的主代码时，我们不应使用 `lua_call`，因为我们希望捕获任何的错误。然而，当我们编写函数时，使用 `lua_call` 通常是个好主意；若出现错误，只需将错误留给关心的人即可。


> **译注**：译者结合上一章中 [“C 模组”](./calling_c.md#C-模组) 中提到的，将 C 模组构建为 `.so` 方法，成功构建出 `mylib.so` 的动态链接库。包含以下三个文件。
>


- *tips_lib.c*

```c
{{#include ../scripts/c_func_tips/tips_lib.c}}
```

- *tips_lib.h*

```c
{{#include ../scripts/c_func_tips/tips_lib.c}}
```

- *demo_map.lua*

```lua
{{#include ../scripts/c_func_tips/demo_map.lua}}
```

> 要将 `tips_lib.c` 编译为 `.so`，执行以下命令。

```console
gcc -c -Wall -Werror -fpic tips_lib.c
gcc -shared -o mylib.so tips_lib.o
```

> 随后将 `mylib.so` 放在 `demo_map.lua` 所在目录下，随后即可在 `demo_map.lua` 脚本中，调用 `mylib` 这个 C 模组中的函数了。上述程序运行结果如下。

```console
$ lua demo_map.lua
1
2
3
4
---
2
4
6
8
```


## 操作字符串

当某个 C 函数从 Lua 收到一个字符串参数时，他必须遵守的规则只有两条：

- 在使用时不从栈上弹出该字符串；
- 以及绝不修改该字符串。


而当 C 函数需要创建一个返回给 Lua 的字符串时，情况就变得更加棘手了。现在，要由 C 代码负责处理缓冲区的分配/解分配、缓冲区溢出以及其他困难的任务。因此，Lua API 提供了一些帮助完成这些任务的函数。


标准 API 提供了对两种最基本字符串操作的支持：子字符串提取及字符串连接。要提取某个子字符串，请记住基本操作 `lua_pushlstring` 会获取字符串长度作为额外参数。因此，若我们打算传递字符串 `s` 从位置 `i` 到 `j` 范围的子字符串，只需执行以下操作：

```c
lua_pushlstring(L, s + i, j - i + 1);
```

举个例子，假设咱们需要一个根据给定分隔符（某个单独字符）切分字符串，并返回一个包含子字符串的表的函数。例如，调用 `split("hi:ho:there", ":")` ，应返回表 `{"hi"、"ho"、"there"}`。图 30.2 “切分字符串” 展示了该函数的一种简单实现。


<a name="f-30.2"></a> **图 30.2，切分字符串**


```c
static int l_split (lua_State *L) {
    const char *s = luaL_checkstring(L, 1); /* subject */
    const char *sep = luaL_checkstring(L, 2); /* separator */
    const char *e;
    int i = 1;

    lua_newtable(L); /* result table */

    /* repeat for each separator */
    while ((e = strchr(s, *sep)) != NULL) {
        lua_pushlstring(L, s, e - s); /* push substring */
        lua_rawseti(L, -2, i++); /* insert it in table */
        s = e + 1; /* skip separator */
    }

    /* insert last substring */
    lua_pushstring(L, s);
    lua_rawseti(L, -2, i);

    return 1; /* return the table */
}
```


其未使用缓冲区，并可处理任意长的字符串： Lua 负责了所有的内存分配。(由于我们创建的表，我们知道他没有元表，因此我们可以使用原始操作来处理他。）


要连接字符串，Lua 提供了一个名为 `lua_concat` 的特定函数。其等同于 Lua 中的连接运算符 (`..`) ：他会将数字转换为字符串，并在必要时触发元方法。此外，他可以同时连接两个以上的字符串。调用 `lua_concat(L, n)` 会连接（并弹出）栈上最顶部的 `n` 个值，并压入结果。


另一个有用的函数是 `lua_pushfstring`：


```c
const char *lua_pushfstring (lua_State *L, const char *fmt, ...);
```

他与 C 函数 `sprintf` 有些类似，在于他会根据某个格式字符串，及一些额外参数创建出一个字符串。但与 `sprintf` 不同的是，我们无需提供缓冲区。Lua 会为我们动态地创建字符串，字符串的大小视需要而定。该函数将生成的字符串压入栈，并返回一个指向结果的指针。该函数接受以下指令：


| 指令 | 意义 |
| :-- | :-- |
| `%s` | 插入一个以零终止的字符串 |
| `%d` | 插入一个 `int` |
| `%f` | 插入一个 Lua 的浮点数 |
| `%p` | 插入一个指针 |
| `%I` | 插入一个 Lua 的整数 |
| `%c` | 将一个 `int` 作为一个 1 字节的字符插入 |
| `%U` | 将一个 `int` 作为一个 UTF-8 的字节序列插入 |
| `%%` | 插入一个百分号 |



