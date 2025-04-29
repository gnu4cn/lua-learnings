# C 中的用户定义类型

在上一章中，我们了解了如何用以 C 编写的新函数，扩展 Lua。现在，我们将了解如何用以 C 编写的新类型扩展 Lua。我们将从一个小的示例开始；在本章中，我们将以元方法和其他一些好东西，扩展这个示例。


本章中咱们的运行示例，将是个相当简单的类型：布尔的数组。这个示例的主要动机，是他未涉及到复杂算法，因此我们可以专注于 API 问题。不过，这个示例本身还是很有用的。当然，我们可以使用表，在 Lua 中实现布尔数组。但在 C 的实现中，我们将把每个条目，都存储在一个比特位中，其内存用量还不到表的 3%.


我们的实现，将需要以下定义：


```c
#include <limits.h>

#define BITS_PER_WORD (CHAR_BIT * sizeof(unsigned int))
#define I_WORD(i) ((unsigned int)(i) / BITS_PER_WORD)
#define I_BIT(i) (1 << ((unsigned int)(i) % BITS_PER_WORD))
```

`BITS_PER_WORD` 是无符号整数的位数。宏 `I_WORD` 会计算存储与给定索引对应位的字，而 `I_BIT` 则会计算访问该字内正确位的掩码。


我们将以下面的结构体，表示我们的数组：


```c
typedef struct BitArray {
    int size;
    unsigned int values[1]; /* variable part */
} BitArray;
```


我们声明将数组 `values` 声明为 `1` 的大小，只是为了占位，因为 C 89 不允许大小为 `0` 的数组；我们将在分配数组时，设置实际大小。接下来的表达式，会计算出有着 `n` 个元素的数组总大小：


```c
sizeof(BitArray) + I_WORD(n - 1) * sizeof(unsigned int)
```


(我们从 `n` 减去 `1`，是因为原始结构已经包含了一个元素的空间。）



## 用户数据

**Userdata**


在这首个版本中，我们将使用显式调用设置与获取值，如下面的示例：


```lua
local array = require "array"

a = array.new(1000)

for i = 1, 1000 do
    array.set(a, i, i % 2 == 0)     -- a[i] = (i % 2 == 0)
end

print(array.get(a, 10))
print(array.get(a, 11))
print(array.size(a))
```

稍后我们将看到，如何同时支持像是 `a:get(i)` 这样的面向对象样式，及像是 `a[i]` 这样的传统语法。对于所有版本，基础的函数都是相同的，如图 31.1 “操作布尔数组” 中所定义的。


<a name="f-31.1"></a> **图 31.1，操作布尔数组**


```c
static int newarray (lua_State *L) {
    int i;
    size_t nbytes;
    BitArray *a;

    int n = (int)luaL_checkinteger(L, 1); /* number of bits */
    luaL_argcheck(L, n >= 1, 1, "invalid size");
    nbytes = sizeof(BitArray) + I_WORD(n - 1)*sizeof(unsigned int);
    a = (BitArray *)lua_newuserdata(L, nbytes);
    a->size = n;
    for (i = 0; i <= I_WORD(n - 1); i++)
        a->values[i] = 0; /* initialize array */

    return 1; /* new userdata is already on the stack */
}
static int setarray (lua_State *L) {
    BitArray *a = (BitArray *)lua_touserdata(L, 1);
    int index = (int)luaL_checkinteger(L, 2) - 1;

    luaL_argcheck(L, a != NULL, 1, "'array' expected");
    luaL_argcheck(L, 0 <= index && index < a->size, 2,
            "index out of range");
    luaL_checkany(L, 3);

    if (lua_toboolean(L, 3))
        a->values[I_WORD(index)] |= I_BIT(index); /* set bit */
    else
        a->values[I_WORD(index)] &= ~I_BIT(index); /* reset bit */

    return 0;
}
static int getarray (lua_State *L) {
    BitArray *a = (BitArray *)lua_touserdata(L, 1);
    int index = (int)luaL_checkinteger(L, 2) - 1;

    luaL_argcheck(L, a != NULL, 1, "'array' expected");
    luaL_argcheck(L, 0 <= index && index < a->size, 2,
            "index out of range");
    lua_pushboolean(L, a->values[I_WORD(index)] & I_BIT(index));

    return 1;
}
```


我们来一点一点地看。


我们首先要关注的是，如何在 Lua 中表示某个 C 结构体。Lua 为此专门提供了一种基本类型，称为 *用户数据，userdata*。用户数据提供了一个在 Lua 中没有预定义操作的原始内存区域，我们可以用他来存储任何东西。


```c
void *lua_newuserdata (lua_State *L, size_t size);
```

在出于某种原因，我们需要通过其他方式分配内存时，那么以指针大小，并存储一个指向真正内存块的指针，创建出一个用户数据是非常容易的。我们将在第 32 章 [“资源管理”](./resource.md) 中，举例说明这种技术。


图 31.1 [“操作布尔数组”](#f-31.1) 中的第一个函数 `newarray`，就使用 `lua_newuserdata` 创建了个新数组。其代码简单明了。他检查了器唯一参数（数组的大小，以位为单位），计算出该数组的字节大小，以适当大小创建出一个用户数据，初始化了其字段，然后将该用户数据返回给 Lua。

下一函数是 `setarray`，他接收三个参数：数组、索引与新值。按照 Lua 的惯例，他假定索引从一开始。由于 Lua 接受布尔值的任意值，因此我们对第三个参数使用了 `luaL_checkany`：他只确保该参数有一个值（任意值）。如果我们以错误参数调用了 `setarray`，就会得到解释性的错误消息，例如下面的示例：


```console
Lua 5.4.7  Copyright (C) 1994-2024 Lua.org, PUC-Rio
> array = require "array"
> a = array.new(1000)
> array.set(0, 11, 0)
stdin:1: bad argument #1 to 'set' ('array' expected)
stack traceback:
        [C]: in function 'array.set'
        stdin:1: in main chunk
        [C]: in ?
> array.set(a, 1)
stdin:1: bad argument #3 to 'set' (value expected)
stack traceback:
        [C]: in function 'array.set'
        stdin:1: in main chunk
        [C]: in ?
```

图 31.1 [“操作布尔数组”](#f-31.1) 中的最后一个函数是 `getarray`，他是个获取条目的函数。他与 `setarray` 类似。


我们还将定义一个获取数组大小的函数，并定义一些初始化我们库的额外代码，参见图 31.2 “布尔数组库的额外代码”。


<a name="f-31.2"></a> **图 31.2 布尔数组库的额外代码**


```c
static int getsize (lua_State *L) {
    BitArray *a = (BitArray *)lua_touserdata(L, 1);
    luaL_argcheck(L, a != NULL, 1, "'array' expected");
    lua_pushinteger(L, a->size);
    return 1;
}

static const struct luaL_Reg arraylib [] = {
    {"new", newarray},
    {"set", setarray},
    {"get", getarray},
    {"size", getsize},
    {NULL, NULL} /* sentinel */
};

int luaopen_array (lua_State *L) {
    luaL_newlib(L, arraylib);
    return 1;
}
```


同样，我们用到辅助库中的 `luaL_newlib`。他会创建一个表，并在其中填入由数组 `arraylib` 所指定的成对名字与函数。

> **译注**：这里 `luaopen_array` 的名字，决定要生成 `array.so` 的动态连接库文件，以及通过 `local array = require "array"` 可将这些 C 函数导入 Lua 程序。`arraylib` 这个变量无关紧要。


## 元表


我们目前的实现有个重大漏洞。假设用户写下类似 `array.set(io.stdin, 1, false)` 的内容。`io.stdin` 的值，是个有着指向流（`FILE *`）指针的用户数据。由于他是个用户数据，`array.set` 将很乐意接受他作为一个有效参数；可能的结果，将是内存损坏（幸运的话，我们会得到一个索引超出范围的错误，an index-out-of-range error）。对于任何的 Lua 库来说，这种行为都是不可接受的。无论我们如何使用某个库，他都不应该损坏 C 数据或导致 Lua 系统崩溃。


将一个用户数据与另一用户数据区分开的通常方法，是为该类型创建一个唯一的元表。每次咱们创建出某个用户数据时，我们都要用相应的元表标记他；每次咱们获取到某个用户数据时，我们都要检查他是否有着正确的元表。由于 Lua 代码无法更改某个用户数据的元表，因此无法欺骗这些检查。



我们还需要一个存储这个新元表的处所，这样我们就可以访问他，而创建出新的用户数据，并检查某个给定用户数据，是否有着正确的类型。如前所述，有存储该元表有两个选项：在注册表中，或作为函数库中函数的上值。在 Lua 中，使用该类型的名字作为索引，对应的元表作为值，而将任何的新 C 类型，注册到注册表是种习惯做法。与其他注册表索引一样，我们必须谨慎选择类型名字，以避免冲突。我们的示例将使用 `"LuaBook.array"`，作为这个新类型的名字。


像往常一样，辅助库提供了一些此处帮助到我们的函数。我们将用到的新辅助函数如下：


```c
int luaL_newmetatable (lua_State *L, const char *tname);
void luaL_getmetatable (lua_State *L, const char *tname);
void *luaL_checkudata (lua_State *L, int index,
                                     const char *tname);
```


- 函数 `luaL_newmetatable` 会创建出一个新的表（将用作元表），将这个新表留在栈顶，并将该表映射到注册表中的给定名字；
- 函数 `luaL_getmetatable` 会从注册表中获取与 `tname` 关联的元表；
- 最后，`luaL_checkudata` 会检查位于给定栈位置的对象，是否是个与元表与给定名字匹配的用户数据。若该对象不是个用户数据，或没有正确的元表，则他会抛出错误；否则，他会返回该用户数据的地址。


现在我们可以开始咱们的修改了。第一步是修改打开这个库的函数，以便其为数组创建出元表：


```c
int luaopen_arraylib (lua_State *L) {
    luaL_newmetatable(L, "LuaBook.array");
    luaL_newlib(L, func_list);
    return 1;
}
```

下一步是更改 `newarray`，使其在他创建的所有数组中，设置这个元表：


```c
static int newarray (lua_State *L) {
    // as before

    luaL_getmetatable(L, "LuaBook.array");
    lua_setmetatable(L, -2);
    return 1; /* new userdata is already on the stack */
}
```

其中函数 `lua_setmetatable` 会从栈上弹出一个表，并将其设置为给定索引处对象的元表。在我们的例子中，这个对象就是那个新的用户数据。


最后，`setarray`、`getarray` 及 `getsize` 都必须检查他们得到的第一个参数，是否是个有效的数组。为了简化其任务，我们定义了以下的宏：


```c
#define checkarray(L) \
    (BitArray *)luaL_checkudata(L, 1, "LuaBook.array")
```

使用这个宏，`getsize` 的新定义就简单明了了：


```c
static int getsize (lua_State *L) {
    BitArray *a = checkarray(L);
    lua_pushinteger(L, a->size);
    return 1;
}
```

由于 `setarray` 和 `getarray` 还共用了读取与检查作为他们第二个参数的索引的代码，因此我们将他们的共同部分，分解到一个新的辅助函数（`getparams`）。


<a name="f-31.3"></a> **图 31.3，新版本的 `setarray`/`getarray`**


```c
static unsigned int *getparams (lua_State *L,
        unsigned int *mask) {
    BitArray *a = checkarray(L);
    int index = (int)luaL_checkinteger(L, 2) - 1;

    luaL_argcheck(L, 0 <= index && index < a->size, 2,
            "index out of range");
    *mask = I_BIT(index); /* mask to access correct bit */

    return &a->values[I_WORD(index)]; /* word address */
}

static int setarray (lua_State *L) {
    unsigned int mask;
    unsigned int *entry = getparams(L, &mask);
    luaL_checkany(L, 3);
    if (lua_toboolean(L, 3))
        *entry |= mask;
    else
        *entry &= ~mask;

    return 0;
}
static int getarray (lua_State *L) {
    unsigned int mask;
    unsigned int *entry = getparams(L, &mask);
    lua_pushboolean(L, *entry & mask);

    return 1;
}
```


有了这个新函数 `getparams`，`setarray` 与 `getarray` 就变得简单了，参见图 31.3 [“新版本的 `setarray`/`getarray`”](#f-31.3)。现在，在我们以无效的用户数据调用他们时，就会得到一条正确的错误消息：


```console
> array = require "arraylib"
> a = array.get(io.stdin, 10)
stdin:1: bad argument #1 to 'get' (LuaBook.array expected, got FILE*)
```

## 面向对象的访问


我们接下来是将咱们的新类型，转换为对象，这样我们就可以使用通常的面向对象语法，对其实例进行操作，就像这样：


```lua
local array = require "arraylib"

a = array.new(1000)
print(a:size()) --> 1000

a:set(10, true)
print(a:get(10)) --> true

a.set(a, 11, false)
print(a:get(11)) --> false
```

请记住，`a:size()` 等同于 `a.size(a)`。因此，我们必须安排表达式 `a.size` 返回函数 `getsize`。这里的关键机制，是 `__index` 这个元方法。对于表，每当 Lua 找不到某个给定键的值时，就会调用这个元方法。而对于用户数据，Lua 在每次访问时，都会调用他，因为用户数据根本没有键。


假设我们要运行以下代码：


```lua
do
    local metaarray = getmetatable(array.new(1))
    metaarray.__index = metaarray
    metaarray.set = array.set
    metaarray.get = array.get
    metaarray.size = array.size
end
```

在第一行中，我们创建了个数组，只是为了获得其元表，并将其赋值给 `metaarray`。（我们无法在 Lua 中设置用户数据的元表，但我们可以得到他。）然后我们将 `metaarray.__index` 设置为了 `metaarray`。当我们计算 `a.size` 时，Lua 无法在对象 `a` 中找到键 `"size"`，因为该对象是个用户数据。因此，Lua 会试图从 `a` 的元表中的字段 `__index` 中，获取这个值，而这个字段恰好就是 `metaarray` 本身。而 `metaarray.size` 就是 `array.size`，因此 `a.size(a)` 的结果，就是 `array.size(a)`，如我们所愿。


当然，我们也可以用 C 写出这同样的东西。我们甚至可以做得更好：既然数组是一些对象，有其自己的操作，我们就不再需要把这些操作，放在在表 `array` 中了。咱们库仍必须导出的函数，便是用于创建新数组的 `new`。所有其他操作，都仅成为了方法。C 代码可以直接将他们注册为方法。


`getsize`、`getarray` 与 `setarray` 三项操作，与我们之前的方法没有变化。改变的是我们注册他的方式。也就是说，我们必须修改打开这个库的代码。首先，我们需要两个单独函数列表：一个用于常规函数，另一个用于方法。



```c
static const struct luaL_Reg func_list_f [] = {
    {"new", newarray},
    {NULL, NULL} /* sentinel */
};

static const struct luaL_Reg func_list_m [] = {
    {"set", setarray},
    {"get", getarray},
    {"size", getsize},
    {NULL, NULL} /* sentinel */
};
```

新版本的打开函数 `luaopen_arraylib`，必须创建出该元表，将其分配给其自己的 `__index` 字段，注册其中的所有方法，并创建并填充这个 `array` 表：


```c
int luaopen_arraylib (lua_State *L) {
    luaL_newmetatable(L, "LuaBook.array"); /* create metatable */
    lua_pushvalue(L, -1); /* duplicate the metatable */

    lua_setfield(L, -2, "__index"); /* mt.__index = mt */
    luaL_setfuncs(L, func_list_m, 0); /* register metamethods */
    luaL_newlib(L, func_list_f); /* create lib table */

    return 1;
}
```

在这里，我们再次用到 `luaL_setfuncs`，将列表 `func_list_m` 中的函数，设置到栈顶的元表中。然后，我们调用 `luaL_newlib` 创建出一个新表，并注册了列表 `func_list_f` 中的函数。


作为最后的修改，我们将一个新的 `__tostring` 方法，添加到咱们的新类型，这样 `print(a)` 就会打印出 `"array"`，以及括号内那个数组的大小。该函数本身在此：


```c
int array2string (lua_State *L) {
    BitArray *a = checkarray(L);
    lua_pushfstring(L, "array(%d)", a->size);
    return 1;
}
```

其中到 `lua_pushfstring` 的调用，会格式化字符串，并将其留在栈顶。我们还必须将 `array2string` 添加到列表 `func_list_m`，以将其包含在数组对象的元表中：


```c
static const struct luaL_Reg func_list_m [] = {
    {"__tostring", array2string},
    // other methods
};
```

## 数组的访问


除了面向对象表示法外，还有一种更好的方法，那就是使用常规的数组表示法访问数组。与其写下 `a:get(i)`，不如直接写 `a[i]`。对于我们的示例，因为我们的函数 `setarray` 和 `getarray` 已经按照参数被给到对应元方法的顺序接收参数，这就很容易做到。快速的解决方案，是直接在 Lua 中定义出下面这些元方法：


```lua
local metaarray = getmetatable(array.new(1))
metaarray.__index = array.get
metaarray.__newindex = array.set
metaarray.__len = array.size
```

(我们必须在未经对象访问修改的数组原始实现上，运行这段代码。）这便是我们使用标准语法，所需的全部：


```lua
a = array.new(1000)

a[10] = true -- 'setarray'
print(a[10]) -- 'getarray' --> true
print(#a) -- 'getsize' --> 1000
```


如果愿意，我们可在 C 代码中，注册这些元方法。为此，我们要再次修改咱们的初始化函数；参见图 31.4 “比特数组库的新初始化代码”。


<a name="f-31.4"></a> **图 31.4 比特数组库的新初始化代码**


```c
static const struct luaL_Reg func_list_f [] = {
    {"new", newarray},
    {NULL, NULL} /* sentinel */
};

static const struct luaL_Reg func_list_m [] = {
    {"__newindex", setarray},
    {"__index", getarray},
    {"__len", getsize},
    {"__tostring", array2string},
    {NULL, NULL} /* sentinel */
};

int luaopen_arraylib (lua_State *L) {
    luaL_newmetatable(L, "LuaBook.array"); /* create metatable */
    luaL_setfuncs(L, func_list_m, 0); /* register metamethods */
    luaL_newlib(L, func_list_f); /* create lib table */

    return 1;
}
```

在这个新版本中，我们再次只使用了一个公共函数 `new`。所有其他函数，都只能作为特定操作的元方法使用。


## 轻用户数据


迄今为止，我们一直在使用的用户数据，被称为 *完整用户数据，full userdata*。Lua 提供了另一种称为 *轻用户数据，light userdata* 的用户数据。

轻用户数据是表示 C 指针的值，即 `void *` 值。轻用户是个值，而不是个对象；我们不会创建出他（就像我们不会创建出数字一样）。要将某个轻用户数据放入栈上，我们要调用 `lua_pushlightuserdata`：


```c
void lua_pushlightuserdata (lua_State *L, void *p);
```

尽管他们有着共同的名字，轻用户数据与完整用户数据却截然不同。轻用户数据不是缓冲区，而是裸指针。他们没有元数据。与数字一样，轻用户数据不受垃圾回收器的管理。


有时，人们会使用轻用户数据，作为完整用户数据的廉价替代。但这并不是一种典型的用法。首先，轻用户数据没有元数据，因此无法知道他们的类型。其次，尽管名称如此，完整用户数据也很便宜。与给定内存大小的 `malloc` 相比，他们增加的开销很小。

轻用户数据的真正用途，来自于相等性。由于完整用户数据是个对象，因此他只等于其自身。而轻用户数据则表示一个 C 指针值。因此，他等于任何表示同一指针的用户数据。因此，我们可以使用轻用户数据，找到 Lua 中的 C 对象。


我们已经见到过轻用户数据作为注册表键值的一种典型用途（[“注册表”](./techniques.md#注册表) 小节）。在那里，轻用户数据的相等性是最基本的。每次我们以 `lua_pushlightuserdata`，压入同一地址时，都会得到相同的 Lua 值，同时应此也是注册表中的同一条目。


Lua 中的另一种典型情况，是以 Lua 对象充当对应 C 对象的代理。例如，I/O 库就会使用 Lua 用户数据，表示 Lua 中的 C 数据流。当操作从 Lua 转到 C 时，从 Lua 对象到 C 对象的映射非常简单。还是以 I/O 库为例，每个 Lua 流都会保留一个到其对应 C 流的指针。然而，当操作从 C 转到 Lua 时，这种映射就会变得棘手。举个例子，假设我们的 I/O 系统中，有某种回调（例如，告知有数据要读取。）该回调会在其应进行操作出，接收 C 数据流。至此，我们怎样才能找到对应的 Lua 对象呢？因为 C 数据流是由 C 标准库定义的，而不是由我们定义的，所以我们无法在其中存储任何内容。


轻用户数据为这种映射，提供了一个很好的解决方案。我们会保存其中索引为有着流地址的一些轻用户数据，而值则是 Lua 中表示流的完整用户数据的一个表。在回调中，一旦我们有个某个流地址，就可以将其作为轻型用户数据，用作该表的索引，获取到其对应的 Lua 对象。(该表可能应有着弱值，否则将那些完整用户数据将永远不会被回收。）



## 练习


<a name="exercise-31.1"></a> 练习 31.1：轻修改 `setarray` 的实现，使其只接受布尔值；

<a name="exercise-31.2"></a> 练习 31.2：我们可以把布尔数组，看作一个整数的集合（数组中具有真实值的索引）。请添加计算两个数组的并集和交集的布尔数组函数实现。这些函数应接收两个数组，并在不修改其参数下返回一个新数组；

<a name="exercise-31.3"></a> 练习 31.3：请扩展前面的练习，从而我们可以用加法得到两个数组的并集，用乘法得到两个数组的交集；、

<a name="exercise-31.4"></a> 练习 31.4：请修改 `__tostring` 这个元方法的实现，使其能以适当的方式，显示数组的全部内容。要使用缓冲区设施（ [“字符串操作”](./techniques.md#操作字符串) 小节），创建出结果字符串；


<a name="exercise-31.5"></a> 练习 31.5：请根据布尔数组的示例，实现一个小型的整数数组 C 库。


（End）


