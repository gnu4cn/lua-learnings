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


其不接受宽度或精度等修饰符。<sup>1</sup>


当我们打算连接仅少量字符串时，`lua_concat` 和 `lua_pushfstring` 都很有用。然而，若我们需要将许多字符串（或字符）连接在一起，逐一连接的方法可能会非常低效，正如我们在 [“字符串缓冲区”](./data_structure.md#字符串缓冲) 小节中所看到的那样。相反，我们可以使用辅助库提供的 *缓冲区设施，buffer facility*。


在其较简单用法中，咱们可用到缓冲区设施的两个函数：一个提供了咱们于其中构造字符串的任何大小缓冲区；另一个会将该缓冲区的内容，转换为 Lua 的字符串。<sup>2</sup> 图 30.3，“函数 `string.upper`” 以源文件 `lstrlib.c` 中 `string.upper` 的实现，演示了这两个函数。


> **脚注**：
>
> <sup>1</sup>：指令 `p` 是在 Lua 5.2 中引入的。指令 `I` 和 `U` 是在 Lua 5.3 中引入的。
>
> <sup>2</sup>：这两个函数是在 Lua 5.2 中引入的。


<a name="f-30.3"></a> **图 30.3，函数 `string.upper`**


```c
static int str_upper (lua_State *L) {
    size_t l;
    size_t i;
    luaL_Buffer b;
    const char *s = luaL_checklstring(L, 1, &l);
    char *p = luaL_buffinitsize(L, &b, l);

    for (i = 0; i < l; i++)
        p[i] = toupper(uchar(s[i]));

    luaL_pushresultsize(&b, l);
    return 1;
}
```


其中第一步就使用辅助库中的缓冲区，声明了一个类型为 `luaL_Buffer` 的变量。下一步是调用 `luaL_buffinitsize`，获得一个具有给定大小的缓冲区指针；然后我们就可以自由使用该缓冲区创建字符串了。最后一步是调用 `luaL_pushresultsize`，将该缓冲区内容，转换为一个新的 Lua 字符串，并将其压入栈。第二个调用中的大小（`l`），就是该字符串的最终大小。通常，正如我们的示例中，这个大小等于缓冲区的大小，但也可能更小。如果我们不知道最终字符串的确切大小，但有一个上限，我们可以保守地分配一个较大的大小。

要注意 `luaL_pushresultsize` 不会将 Lua 状态作为第一个参数。在初始化后，缓冲区会保留对状态的引用，因此我们在调用其他操作缓冲区的函数时，无需传递状态。


我们还可以使用辅助库的缓冲区，在无需知道结果大小上限下，向缓冲区零散地添加内容。辅助库提供了几个向缓冲区添加内容的函数：

- `luaL_addvalue` 添加栈顶部的 Lua 字符串；
- `luaL_addlstring` 添加长度明确的字符串；
- `luaL_addstring` 添加零结尾字符串；
- `luaL_addchar` 添加单个字符。

这些函数的原型如下。


```c
void luaL_buffinit (lua_State *L, luaL_Buffer *B);
void luaL_addvalue (luaL_Buffer *B);
void luaL_addlstring (luaL_Buffer *B, const char *s, size_t l);
void luaL_addstring (luaL_Buffer *B, const char *s);
void luaL_addchar (luaL_Buffer *B, char c);
void luaL_pushresult (luaL_Buffer *B);
```


图 30.4 “`table.concat` 的简化实现” 通过对函数 `table.concat` 的简化实现，演示了这些函数的用法。


<a name="f-30.4"></a> **图 30.4，`table.concat` 的简化实现**

```c
static int tconcat (lua_State *L) {
    luaL_Buffer b;
    int i, n;

    luaL_checktype(L, 1, LUA_TTABLE);
    n = luaL_len(L, 1);
    luaL_buffinit(L, &b);

    for (i = 1; i <= n; i++) {
        lua_geti(L, 1, i); /* get string from table */
        luaL_addvalue(&b); /* add it to the buffer */
    }

    luaL_pushresult(&b);
    return 1;
}
```


在该函数中，我们首先调用 `luaL_buffinit` 初始化该缓冲区。然后，我们逐个向该缓冲区添加元素，本例中使用的是 `luaL_addvalue`。最后，`luaL_pushresult` 会清空该缓冲区，并将最终字符串留在栈顶部。


当我们使用辅助库的缓冲区时，我们务必要注意一个细节。在我们初始化某个缓冲区后，他可能会在 Lua 的栈上保留一些内部数据。因此，我们不能假设，栈顶部将保持其在咱们开始使用该缓冲区前的位置。此外，虽然我们可以在使用缓冲区时，将栈用于其他任务，但每次访问缓冲区时，这些用途的压入/弹出计数必须保持平衡。这一规则的唯一例外是 `luaL_addvalue`，他假定了要添加到缓冲区的字符串位于栈顶部。


## 于 C 函数中存储状态


C 函数经常需要保存一些非本地的数据，即在其调用后仍然存活的一些数据。在 C 中，我们通常使用全局变量（ `extern` ），或静态变量来满足这种需求。然而，当我们编写 Lua 的库函数时，这两种方法都不适用。首先，我们无法在某个 C 变量中，存储通用的 Lua 值。其次，使用此类变量的库无法处理多个 Lua 状态。

更好的办法是获得 Lua 的一些帮助。Lua 函数有两处存储非本地数据的地方：全局变量于非本地变量。C API 提供了存储非本地数据的两个类似处所：注册表与上值。

### 注册表

**The registry**


Lua 的 *注册表* 是个只能被 C 代码访问的全局表。<sup>3</sup> 通常，我们用其存储在多个模组间共享的数据。


注册表始终位于 *伪索引，pseudo-index* `LUA_REGISTRYINDEX` 处。所谓伪索引，就像某个栈上的索引，只是其相关值并不在栈上。Lua API 中大多数接受索引作为参数的函数，也会接受伪索引，不过那些操作栈本身的函数除外，如 `lua_remove` 及 `lua_insert` 等。例如，要获取注册表中，存储在键 `"Key"` 下的某个值，我们可以使用下面的调用：


```c
lua_getfield(L, LUA_REGISTRYINDEX, "Key");
```

Lua 的注册表是个常规 Lua 表。因此，我们可以使用任何非零的 Lua 值，对其进行索引。不过，由于所有 C 模组都共用了同一个注册表，我们必须谨慎选择作为键值的值，以避免冲突。当我们打算允许其他独立库，访问我们的数据时，字符串的键就特别有用，因为他们只需要知道键的名字。对于这些键来说，选择名字没有万无一失的方法，但有一些好的做法，例如避免使用常见名字，并在名字前加上库名称或类似名称。(像是 `lua` 或 `lualib` 这样的前缀，就不是好的选择。）


我们绝不应使用咱们自己的数字，作为注册表中的键，因为 Lua 保留了数字键用于其 *引用系统，reference system*。该系统由辅助库中的一对函数组成，他们允许我们在不必担心如何创建唯一键值下，在表中存储值。函数 `luaL_ref` 会创建处新的引用：


```c
int ref = luaL_ref(L, LUA_REGISTRYINDEX);
```

前面的调用会从栈上弹出一个值，将其与一个新整数键值一起，存储到注册表中，然后返回这个键值。我们称这个键为一个 *引用*。


顾名思义，我们主要是在需要于某个 C 结构内部，存储某个 Lua 值的引用时，才会用到引用。正如我们所看到的，我们绝不应将指向 Lua 字符串的指针，存储在获取这些字符串的 C 函数之外。此外，Lua 甚至不提供指向其他对象（如表或函数）的指针。因此，我们不能经由指针，引用 Lua 的对象。相反，当我们需要此类指针时，我们要创建一个引用，并将其存储在 C 中。


要将与某个引用 `ref` 关联的值压入栈，我们只需这样写：


```c
lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
```

最后，要同时释放值与引用，我们要调用 `luaL_unref`：


```c
luaL_unref(L, LUA_REGISTRYINDEX, ref);
```

这次调用后，对 `luaL_ref` 的一次新调用，可能会再次返回该引用。

引用系统会将 `nil` 作为特殊情况处理。当我们对某个 `nil` 值调用 `luaL_ref` 时，他不会创出建一个新引用，而是返回常量引用 `LUA_REFNIL`。下面的调用没有任何效果：


```c
luaL_unref(L, LUA_REGISTRYINDEX, LUA_REFNIL);
```

不出所料，接下来这个调用，会压入一个 `nil`：


```c
lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_REFNIL);
```


引用系统还定义了常量 `LUA_NOREF`，他是个不同于任何有效引用的整数。他的作用是表明作为引用的某个值无效。

当我们创建出一个 Lua 状态时，注册表就有了两个预定义的引用：

- `LUA_RIDX_MAINTHREAD`，保存着该 Lua 状态本身，同时也是其主线程；
- `LUA_RIDX_GLOBALS`，保存着全局环境。


在注册表中创建唯一键的另一种安全方法，是使用咱们代码中某个静态变量的地址作为键值： C 的链接编辑器，会确保该键在所有加载的库间都是唯一的。要使用此选项，我们需要函数 `lua_pushlightuserdata`，该函数会将一个表示 C 指针的值压入栈。下面的代码展示了，如何使用该方法在注册表中存储及检索某个字符串：


```c
    /* variable with a unique address */
    static char Key = 'k';

    /* store a string */
    lua_pushlightuserdata(L, (void *)&Key); /* push address */
    lua_pushstring(L, myStr); /* push value */
    lua_settable(L, LUA_REGISTRYINDEX); /* registry[&Key] = myStr */

    /* retrieve a string */
    lua_pushlightuserdata(L, (void *)&Key); /* push address */
    lua_gettable(L, LUA_REGISTRYINDEX); /* retrieve value */
    myStr = lua_tostring(L, -1); /* convert to string */
```


我们将在 [“轻用户数据”](./types.md#轻用户数据) 小节，详细讨论轻型用户数据。


为简化将变量地址作为唯一键的使用，Lua 5.2 引入了两个新函数：`lua_rawgetp` 和 `lua_rawsetp`。他们与 `lua_rawgeti` 和 `lua_rawseti` 类似，但使用 C 指针（被翻译为了轻用户数据）作为键。有了他们，我们就可以像这样，编写之前的代码：


```c
    static char Key = 'k';

    /* store a string */
    lua_pushstring(L, myStr);
    lua_rawsetp(L, LUA_REGISTRYINDEX, (void *)&Key);

    /* retrieve a string */
    lua_rawgetp(L, LUA_REGISTRYINDEX, (void *)&Key);
    myStr = lua_tostring(L, -1);
```

两个函数都使用了原始的访问。由于注册表没有元表，原始访问的行为与常规访问相同，而且效率略高。



### 上值

**Upvalues**


由于注册表提供了全局变量，而 *上值* 机制则实现了，仅在某个特定函数内部可见的 C 静态变量的同等效果。每次在 Lua 中创建出一个新的 C 函数时，我们都可以将其与任意数量的上值关联，每个上值都保留着一个 Lua 值。随后，当我们调用该函数时，他可以使用伪索引，自由访问其任意上值。


我们将这种 C 函数与其上值的关联，称为 *闭包*。C 的闭包是 Lua 闭包的 C 近似值。特别是，我们可以使用同一函数代码，以不同上值，创建出不同的闭包。


要看到一个简单示例，咱们来在 C 中创建一个函数 `newCounter`（我们在第 9 章 [“闭包”](./closures.md) 中，在 Lua 语言中定义了一个类似函数）。这个函数是个工厂：每次调用他时，都会返回一个新的计数器函数，如同下面这个示例一样：


```lua
local mylib = require "mylib"

c1 = mylib.newCounter()
print(c1(), c1(), c1())     --> 1   2   3

c2 = mylib.newCounter()
print(c2(), c2(), c1())     --> 1   2   4
```

> **译注**：这里已把相关 C 代码，放入 `mylib.so` 库中。


虽然所有计数器沟共用了同样的 C 代码，但每个计数器都有自己独立的计数器。工厂函数如下：


```c
static int counter (lua_State *L); /* forward declaration */


int newCounter (lua_State *L) {
    lua_pushinteger(L, 0);
    lua_pushcclosure(L, &counter, 1);
    return 1;
}
```


这里的关键函数是 `lua_pushcclosure`，他会创建出一个新的闭包。其第二个参数，是基本函数（示例中为 `counter`），第三个参数是上值的个数（示例中为 `1`）。在创建新闭包前，我们必须将其上值的初始值压入栈。在我们的示例中，我们将 `0` 作为那个单一上值的初始值。不出所料，`lua_pushcclosure` 会将这个新闭包留在栈上，因此该闭包可作为 `newCounter` 的结果返回。


现在，我们来看看 `counter` 的定义：


```c
static int counter (lua_State *L) {
    int val = lua_tointeger(L, lua_upvalueindex(1));
    lua_pushinteger(L, ++val); /* new value */
    lua_copy(L, -1, lua_upvalueindex(1)); /* update upvalue */
    return 1; /* return new value */
}
```


这里的关键元素，是产生某个上限值的伪索引的宏 `lua_upvalueindex`。特别是，表达式 `lua_upvalueindex(1)` 会给出运行中函数的第一个上值的伪索引。同样，这个伪索引与任何的栈索引一样，只是其不在栈上。因此，调用 `lua_tointeger` 可获取到第一个（也是唯一一个）上值的当前整数值。然后，函数 `counter` 会压入新值 `++val`，将其复制为新上值的值，并返回他。


作为更高级的示例，我们将使用上值实现元组。元组是一种有着匿名字段的常量结构；我们可以数字的索引，获取到特定字段，也可以一次获取到所有字段。在我们的实现中，我们将元组表示为，将其值存储在上值中的函数。在以数字参数调用时，该函数会返回特定字段。在不带参数调用时，则返回所有字段。以下代码演示了元组的这种用法：



```lua
local mylib = require "mylib"

x = mylib.new_tuple(10, "hi", {}, 3)
print(x(1))
print(x(2))
print(x())
```

在 C 中，我们将以图 30.5 “元组的实现” 中的同一函数 `t_tuple`，表示所有元组。


<a name="f-30.5"></a> **图 30.5，元组的实现**


```c
int t_tuple (lua_State *L) {
    lua_Integer op = luaL_optinteger(L, 1, 0);
    if (op == 0) { /* no arguments? */
        int i;
        /* push each valid upvalue onto the stack */
        for (i = 1; !lua_isnone(L, lua_upvalueindex(i)); i++)
            lua_pushvalue(L, lua_upvalueindex(i));
        return i - 1; /* number of values */
    }
    else { /* get field 'op' */
        luaL_argcheck(L, 0 < op && op <= 256, 1,
                "index out of range");
        if (lua_isnone(L, lua_upvalueindex(op)))
            return 0; /* no such field */
        lua_pushvalue(L, lua_upvalueindex(op));
        return 1;
    }
}

int t_new (lua_State *L) {
    int top = lua_gettop(L);
    luaL_argcheck(L, top < 256, top, "too many fields");
    lua_pushcclosure(L, t_tuple, top);
    return 1;
}
```


因为我们可以调用某个带或不带数字参数的元组，所以 `t_tuple` 使用了 `luaL_optinteger`，获取其可选参数。该函数类似于 `luaL_checkinteger`，但在参数缺失时他不会抱怨；相反，他会返回一个给定的默认值（在本例中为 `0`）。


C 函数上值的最大数目为 255，而我们可对 `lua_upvalueindex` 使用的最大索引数目就为 256。因此，我们使用了 `luaL_argcheck`，确保这些限制。


当我们索引某个不存在的上值时，结果会是个类型为 `LUA_TNONE` 的伪值。（当我们访问一个高于当前栈顶的栈索引时，也会得到此类型 `LUA_TNONE` 的伪值。）我们的函数 `t_tuple` 使用了 `lua_isnone`，测试他是否有着给定的上值。然而，我们绝不应对 `lua_upvalueindex` 使用负数或大于 256 （这是 C 函数的最大上值数目）的索引，因此我们必须在用户提供索引时，检查这种情况。函数 `luaL_argcheck` 会对给定条件进行检查，在条件不符合时，就会抛出错误，并给出漂亮的提示信息：

```console
> mylib = require "mylib"
> t = mylib.new_tuple(2, 4, 5)
> t(300)
stdin:1: bad argument #1 to 't' (index out of range)
stack traceback:
        [C]: in function 't'
        stdin:1: in main chunk
        [C]: in ?
```


`luaL_argcheck` 的第三个参数，提供了错误消息的参数编号（示例中为 `1`），第四个参数提供了该消息的补充（`"index out of range"`）。


创建出元组的函数 `t_new`（同样在图 30.5 “元组的实现” 中）是微不足道的：因为他的参数已经在栈上，他会首先检查字段的数量是否符合闭包中上值的限制，然后调用 `lua_pushcclosure`，创建一个将所有参数作为上值的 `t_tuple` 闭包。最后，数组 `tuplelib` 与函数 `luaopen_tuple`（也在图 30.5 “元组的实现” 中），便是以该单个函数 `new`，创建出 `tuple` 库的标准代码。



### 共用上值

**Shared upvalues**


通常，我们需要在某个库中所有函数间，共用一些值或变量。虽然我们可以使用注册表完成这项任务，但我们也可以使用上值。


与 Lua 的闭包不同，C 闭包不能共用上值。每个闭包都有其自己独立的上值。不过，我们可以将不同函数的上值，设置为引用某个共同的表，这样这个表就成了函数共享数据的一个共同环境。


Lua 提供了一个可简化在某个库的所有函数间，共用某个上值任务的函数。我们一直都以 `luaL_newlib`，打开 C 库。Lua 通过以下宏，实现了这个函数：


```c
#define luaL_newlib(L,lib) \
    (luaL_newlibtable(L,lib), luaL_setfuncs(L,lib,0))
```

宏 `luaL_newlibtable` 只是为该库，创建了个新表。(该表有着与给定库中的函数个数相等的预分配大小。）然后，函数 `luaL_setfuncs` 会将列表 `lib` 中的那些函数，添加到栈顶的该新表中。


`luaL_setfuncs` 的第三个参数，是我们在这里感兴趣的。他给出了库中新函数的共用上值数量。这些上值的初始值，应该在栈上，就像 `lua_pushcclosure` 中的情况一样。因此，要创建一个其中所有函数都共享了作为他们单一上值的表的函数库，我们可以使用以下代码：

```c
/* create library table ('lib' is its list of functions) */
luaL_newlibtable(L, lib);

/* create shared upvalue */
lua_newtable(L);

/* add functions in list 'lib' to the new library, sharing
    previous table as upvalue */
luaL_setfuncs(L, lib, 1);
```

最后那个调用，还会从栈上删除共用的表，而只留下新库。



## 练习


<a name="exercise-30.1"></a> 练习 30.1：请用 C 实现一个过滤器函数。该函数应接收一个列表和一个谓词，并返回一个有着包含给定列表中，所有满足谓词的元素：


```lua
t = filter({1, 3, 20, -4, 5}, function (x) return x < 5 end)
-- t = {1, 3, -4}
```


(所谓谓词，a predicate，只是一个测试某些条件，返回一个布尔值的函数。）

<a name="exercise-30.2"></a> 练习 30.2：请修改函数 `l_split`（来自图 30.2 [“分割字符串”](#f-30.2) ），使其能够处理包含零的字符串；(除其他修改外，他还应使用 `memchr` 而非 `strchr`。）

<a name="exercise-30.3"></a> 练习 30.3：请用 C 重新实现函数 `transliterate`（ [练习 10.3](./pattern_matching.md#exercise-10.3) ）；


<a name="exercise-30.4"></a> 练习 30.4：请实现以一个修改版的 `transliterate` 实现一个库，使音译表不在作为参数给出，而是由该库保存。咱们的库应提供以下函数：

```lua
lib.settrans (table) -- set the transliteration table
lib.gettrans () -- get the transliteration table
lib.transliterate(s) -- transliterate 's' according to the current table
```

请使用注册表，保存音译表；

<a name="exercise-30.5"></a> 练习 30.5：重复前一练习，使用上值保存音译表；

<a name="exercise-30.6"></a> 练习 30.6：将音译表作为库状态的一部分，而不是作为 `transliterate` 函数的参数，你认为这种设计好吗？


（End）


