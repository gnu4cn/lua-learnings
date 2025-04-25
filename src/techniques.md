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
> - *tips_lib.c*

```c
{{#include ../scripts/c_func_tips/tips_lib.c}}
```

> - *tips_lib.h*
>

```c
{{#include ../scripts/c_func_tips/tips_lib.c}}
```

> - *demo_map.lua*

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
