# C API 概述

Lua 是一门 *嵌入式语言，embedded language*。这意味着 Lua 并不是一个独立的应用，而是一个我们可以将其与其他应用链接，将 Lua 设施纳入其中的库。


咱们可能会想：既然 Lua 不是个独立的程序，那为什么我们在这整本书中，一直都在使用 Lua 这个独立程序呢？这个问题的答案就是 Lua 解释器 -- 可执行的 `lua`。这个可执行文件是个小的应用程序，大约有六百行代码，使用 Lua 库来实现了独立的解释器。该程序处理与用户的接口，接收用户的文件和字符串，将其输入到完成大部分工作（比如实际运行 Lua 代码）的 Lua 库。

这种作为库用于扩展应用的能力，使 Lua 成为一门 *可嵌入的语言，embeddable language*。同时，使用 Lua 的程序，可在 Lua 环境中注册新的函数；这些函数是以 C （或其他语言）实现的，因此他们可以添加 Lua 无法直接编写的一些设施。这就是 Lua 成为一门 *可扩展语言，extensible language* 的原因。

Lua 的这两种视角（作为一门可嵌入语言和一门可扩展语言），对应了 C 和 Lua 之间的两种交互方式。在第一种交互中，C 语言有着控制权，而 Lua 则是库。这种交互中的 C 代码，就是我们所说的 *应用代码，application code*。在第二种交互中，Lua 拥有控制权，而 C 是库。在这里，C 代码被称为 *库代码，library code*。应用代码和库代码，都使用同样的 API 与 Lua 进行通信，即所谓的 C API。

所谓 C API，是一组实现 C 代码与 Lua 交互的函数、常量和类型 <sup>1</sup>。C API 由读写 Lua 全局变量、调用 Lua 函数、运行 Lua 代码片段，以及注册 C 函数以便 Lua 代码可以调用他们等的函数构成。几乎所有 Lua 代码能做的事情，C 代码经由 C API 都能完成。

> 注 <sup>1</sup>：原文为 “The C API is the set of functions, constants, and types that allow C code to interact with Lua”。在本教材中，“函数” 一词实际上指的是 “函数或宏”。API 以宏的形式实现了多种功能。


C API 遵循了与 Lua 截然不同的 C 语言 *运作方式* <sup>2</sup>，。在以 C 语言编程时，我们必须关注类型检查、错误恢复、内存分配错误，以及其他一些复杂性来源。API 中的大多数函数，都不会检查其参数的正确性；我们有责任在调用函数前，确保参数是有效的 <sup>3</sup>。此外，应用程序接口强调灵活性和简洁性，但有时却牺牲了易用性。普通任务可能需要调用多次 API。这可能很无聊，但却能让我们完全控制所有细节。

> 注 <sup>2</sup>：原文为 “ the *modus operandi* ”，为拉丁文，英文翻译 “mode of operation”。
>
> 注 <sup>3</sup>：咱们可以在编译 Lua 时定义宏 `LUA_USE_APICHECK`，来启用某些检查；在调试咱们的 C 代码时这个选项特别有用。不过，有一些错误在 C 语言中根本无法检测到，比如无效指针等。
>
> 参考：[wikipedia: 犯罪手法](https://zh.wikipedia.org/zh-cn/%E7%8A%AF%E7%BD%AA%E6%89%8B%E6%B3%95)

正如其标题所讲的那样，本章的目的是概述从 C 语言中使用 Lua 时，所涉及到的内容。无需试图理解现在发生的所有细节，我们稍后会加以补充。不过，请不要忘记，咱们总是可以在 Lua 参考手册中，找到有关特定函数的更多详细信息。此外，咱们还可以在 Lua 发布本身中，找到这里用到的几个 API 的用例。Lua 的独立解释器 (`lua.c`)，提供了一些应用代码的示例，而标准库 (`lmathlib.c`, `lstrlib.c` 等)，也提供了库代码的示例。


从现在起，我们就冠以了 C 程序员的名头。


## 首个示例

我们将从一个简单的应用程序示例，开始这个概述：一个独立的 Lua 解释器。我们可以编写如图 27.1 “简易的独立 Lua 解释器” 所示的简易独立解释器。

<a name="f-27.1"></a> 图 27.1 “简易的独立 Lua 解释器”


```c
{{#include ../scripts/overview_C-API/bare-bones_interpreter.c}}
```


> **译注**：编译此代码时，需执行命令 `gcc -o lua.a bare-bones_interpreter.c -llua -ldl`。
>
> 参考：["Undefined reference to" using Lua](https://stackoverflow.com/a/14094300/12288760)


其中头文件 `lua.h` 声明了那些由 Lua 提供的基本函数。他包括了创建新的 Lua 环境、调用 Lua 函数、读写环境中的全局变量、注册由 Lua 调用的新函数等的函数。在 `lua.h` 中声明的所有内容，都有着前缀 `lua_`（例如 `lua_pcall`）。


头文件 `lauxlib.h` 声明了由 *辅助库，auxiliary library* ( `auxlib`) 提供的那些函数。其所有声明都以 `luaL_` 开头（例如 `luaL_loadstring`）。辅助库使用了由 `lua.h` 提供的基本 API，提供更高的抽象级别，尤其是被标准库用到的那些抽象。基本 API 追求经济性和正交性，而辅助库则追求少数常见任务的实用性。当然，咱们的程序也可以很容易地创建其所需的别的抽象。请记住，辅助库无法访问 Lua 的内部结构。他通过在 `lua.h` 中声明的官方基本 API，完成全部工作。无论他完成了些什么，咱们的程序也可以做到。

Lua 库完全没有定义任何 C 的全局变量。他将其全部状态，都保存在动态结构 `lua_State` 中；Lua 内部的所有函数，都会接收一个指向该结构的指针的参数。这种设计使 Lua 可以重入，并可在多线程代码中使用，this design makes Lua reentrant and ready to be used in multithreaded code。


顾名思义，函数 `luaL_newstate` 会创建出一个新的 Lua 状态。当 `luaL_newstate` 创建某个新状态时，其环境不会包含任何预定义的函数，甚至不包含 `print`。为保持 Lua 小巧，所有标准库都以独立包的形式提供，因此在不需要时，我们就不必使用他们。头文件 `lualib.h` 声明了打开这些库的函数。函数 `luaL_openlibs` 会打开所有标准库。


在创建出状态并用标准库填充该状态之后，就该处理用户输入了。对于用户输入的各行，该程序都会先以 `luaL_loadstring` 对其进行编译。若没有错误，则该调用会返回零，并将得到的函数推入栈。(我们将在下一小节讨论这个神秘的栈。）然后，该程序会调用从栈中弹出这个函数，并以保护模式运行他的 `lua_pcall`。与 `luaL_loadstring` 一样，在没有错误时，`lua_pcall` 会返回 `0`。而若出现错误，这两个函数都会在栈上推入一条错误消息；随后我们用 `lua_tostring` 获取该消息，并在打印后用 `lua_pop` 将其从栈中移除。

C 语言中真正的错误处理可能相当复杂，如何处理取决于咱们应用的性质。Lua 核心从不直接向任何输出流，写入任何内容；他通过返回错误消息指出错误。每个应用都可以根据自己的需要，处理这些信息。为简化我们的讨论，在接下来的示例中，我们将假设如下的一种简单错误处理程序，他将打印出错误消息、关闭 Lua 状态，并结束整个应用：


```c
{{#include ../scripts/overview_C-API/err_handler.c}}
```


稍后我们将进一步讨论应用代码中的错误处理。


由于我们可以将 Lua 作为 C 或 C++ 代码编译，因此 `lua.h` 并未包含 C 库中常用的以下模板代码：


```c
#ifdef __cplusplus
extern "C" {
#endif
    ...
#ifdef __cplusplus
}
#endif
```

如果我们将 Lua 作为 C 代码编译了，却要在 C++ 中使用他，我们可以包含 `lua.hpp` 而非 `lua.h`。其定义如下：


```c
extern "C" {
#include "lua.h"
}
```



## 栈

**The Stack**


Lua 和 C 之间通信的一个主要组件，是个无处不在的虚拟 *栈*，an omnipresent virtual *stack*。几乎全部的 API 调用，都是对这个栈上的值进行操作。从 Lua 到 C 以及从 C 到 Lua 的所有数据交换，都经由这个栈进行。此外，我们还可以使用该栈保存一些中间结果。

当尝试在 Lua 和 C 间交换数值时，我们面临两个问题：

- 动态类型系统和静态类型系统之间的不匹配；
- 以及自动内存管理和手动内存管理之间的不匹配。


在 Lua 中，当我们写下 `t[k] = v` 时，`k` 和 `v` 均可有着多种不同的类型；由于元表的原因，甚至 `t` 也可有着不同的类型。然而，如果我们想要在 C 中提供这种操作，那么任何给定的 `settable` 函数，都必须有某种固定类型。我们将需要几十个不同函数，完成这个单一操作（三种类型的每种组合，都需要一个函数）。

通过在 C 中声明可以代表所有 Lua 值的某种联合类型 -- 我们称之为 `lua_Value`，我们可以解决这个问题。然后，我们可将 `settable` 声明为：

```c
void lua_settable (lua_Value a, lua_Value k, lua_Value v);
```

这种解决方案有两个缺点。

- 首先，难于将如此复杂的类型，映射到其他语言；我们（Lua 语言开发团队）不仅将 Lua 设计为可轻易地与 C/C++ 连接，还要与 Java、Fortran、C# 等语言连接；
- 其次，Lua 会进行垃圾回收：如果我们将某个 Lua 表保存在一个 C 变量中，那么 Lua 引擎就无法获悉这一用途；他可能会（错误地）认为该表是垃圾而将其回收。


因此，Lua API 并未定义类似 `lua_Value` 类型的东西。相反，他使用了栈，在 Lua 和 C 之间交换值。栈中的每个槽都可以容纳任何 Lua 值。每当我们打算请求某个 Lua 中的值（比如某个全局变量的值）时，我们就会调用 Lua，他会将所需的值推入该栈。每当我们要将某个值传递给 Lua 时，我们首先要将该值推入该栈，然后再调用 Lua（他将弹出该值）。我们仍需一个不同的函数，将各种 C 类型推入该栈，以及一个别的函数从该栈中获取各种 C 语言类型，但我们避免了组合爆炸，combinatorial explosion。此外，由于这个栈是 Lua 状态的一部分，垃圾回收器就清楚 C 正使用哪些值。


C API 中的将近全部函数，都会用到这个栈。正如我们在咱们的首个示例中看到的，`luaL_loadstring` 会将其结果留在该栈上（编译后的代码块或错误消息）；`lua_pcall` 会从该栈中获取要调用的函数，并将错误消息留在栈上。


Lua 会以一种严格的 LIFO（后进先出）原则处理该栈。当我们调用 Lua 时，他只会改变栈顶部分。而我们的 C 代码则有更大的自由度；具体来说，他可以检查该栈中的任何元素，甚至可以在任何位置插入及删除元素。


## 推入元素

**Pushing elements**

C API 为每种 Lua 类型，都提供了一个用 C 直接表示的推入函数：

- `lua_pushnil` 用于常量 `nil`；
- `lua_pushboolean` 用于布尔型（在 C 语言中为整数）；
- `lua_pushnumber` 用于双精度数值 <sup>4</sup>；
- `lua_pushinteger` 用于整数；
- `lua_pushlstring` 用于任意字符串（一个只想 `char` 的指针以及一个长度值）；
- `lua_pushstring` 用于以零结束的字符串，zero-terminated strings。


> 注 <sup>4</sup>：由于历史原因，C API 中的 “数字” 一词指的是双精度数。


```c
void lua_pushnil (lua_State *L);
void lua_pushboolean (lua_State *L, int bool);
void lua_pushnumber (lua_State *L, lua_Number n);
void lua_pushinteger (lua_State *L, lua_Integer n);
void lua_pushlstring (lua_State *L, const char *s, size_t len);
void lua_pushstring (lua_State *L, const char *s);
```

还有一些将 C 函数与用户数据值推入栈的函数；我们稍后将讨论这些函数。


`lua_Number` 类型为 Lua 中的浮点数值类型。其默认为 `double`，但我们可以在编译时，将 Lua 配置为使用 `float` 或甚至 `long double`。`lua_Integer` 是 Lua 中的整数类型。通常，其被定义为 `long long`，即有符号的 64 位整数。同样，将 Lua 配置为使用 `int` 或 `long` 作为该类型也很简单。32 位的浮点数和整数的组合 `float-int`，产生了我们所说小型 Lua，这对小型机和受限硬件特别有用 <sup>5</sup>。


> 注 <sup>5</sup>：有关这些配置，请查看文件 `luaconf.h`。


Lua 中的字符串都不是以零结束的；他们可以包含任意的二进制数据。因此，将字符串推入栈的基本函数是 `lua_pushlstring`，他需要一个显式的长度作为一个参数。对于那些以零结束的字符串，我们还可以使用 `lua_pushstring`，他使用了 `strlen` 提供该字符串的长度。Lua 绝不会保存指向外部字符串的指针（或指向除 C 函数外任何其他外部对象的指针，因为 C 函数总是静态的）。对于必须保留的字符串，Lua 要么会构造一个在内部副本，要么重用一个。因此，只要这些函数返回，我们就可以立即释放或修改缓冲区。


每当我们向栈推入某个元素时，我们都有责任确保该栈有足够的空间容纳他。记住，咱们现在是名 C 程序员，Lua 不会把咱们惯坏。在 Lua 启动时及调用 C 的任何时候，该栈都至少要有 20 个空闲槽。(头文件 `lua.h` 将这一常量定义为 `LUA_MINSTACK`。）对于大多数常见用途来说，这一空间都绰绰有余，因此我们通常根本不会考虑他。不过，有些任务需要更多的栈空间，特别是当我们有着一个将元素推入栈的循环时。在这种情况下，我们就需要调用 `lua_checkstack`，他将检查该栈是否有满足我们需求的足够空间：


```c
int lua_checkstack (lua_State *L, int sz);
```

这里，`sz` 是我们所需的额外插槽数。在可行时，`lua_checkstack` 会增大栈以满足所需的额外大小。否则，他会返回 `0`。


辅助库提供了一个检查栈空间的高级别函数，a higher-level function to check for stack space：


```c
void luaL_checkstack (lua_State *L, int sz, const char *msg);
```

这个函数类似于 `lua_checkstack`，但在其无法满足请求时，会以给定的信息抛出错误，而不是返回错误代码。



## 查询元素

**Querying elements**


为引用栈上的元素，C API 使用了 *索引，indices*。推入栈的第一个元素的索引为 1，下一元素的索引为 2，以此类推。我们也可将栈顶用作参考，以负的索引访问元素。在这种情况下，-1 表示栈顶的元素（即最后推送的元素），-2 表示前一个元素，以此类推。例如，调用 `lua_tostring(L, -1)` 可将栈顶部的值，作为字符串返回。正如我们将看到的，在很多情况下，从栈底开始索引（即使用正索引）是很自然的，而在另外一些情况下，使用负索引才是自然的。


为检查某个栈元素是否有着某种特定类型，C API 提供了一系列名为 `lua_is*` 的函数，其中 `*` 可以是任何的 Lua 类型。因此，就有 `lua_isnil`、`lua_isnumber`、`lua_isstring`、`lua_istable` 等函数。所有这些函数都有着同一原型：


```c
int lua_is* (lua_State *L, int index);
```


实际上，`lua_isnumber` 并不会检查值是否具有该特定类型，而是检查该值是否可以转换为该类型；`lua_isstring` 与此类似：特别是，任何数字都会满足 `lua_isstring`。


还有个函数 `lua_type`，用于返回栈上某个元素的类型。每种类型都由一个相应常量表示： `LUA_TNIL`、`LUA_TBOOLEAN`、`LUA_TNUMBER`、`LUA_TSTRING` 等。咱们主要将该函数与 `switch` 语句结合使用。当我们需要检查在没有潜在类型转换的字符串和数字时，该函数也很有用，it is also useful when we need to check for strings and numbers without potential coercions。


要获取栈上的某个值，可以使用 `lua_to*` 函数：


```c
int         lua_toboolean (lua_State *L, int index);
const char *lua_tolstring (lua_State *L, int index,
                                         size_t *len);
lua_State  *lua_tothread (lua_State *L, int index);
lua_Number  lua_tonumber (lua_State *L, int index);
lua_Integer lua_tointeger (lua_State *L, int index);
```

即使给定元素没有某种适当类型，我们也可以调用这些函数中的任何一个。函数 `lua_toboolean` 适用于任何类型，根据 Lua 条件方面的规则，将任何的 Lua 值转换为 C 的布尔值：`nil` 和 `false` 值为零，任何其他 Lua 值为一。对于那些不正确的类型，函数 `lua_tolstring` 和 `lua_tothread` 返回 `NULL`。而两个数值函数，则无法提示错误的类型，因此只能简单地返回零。以前我们需要调用 `lua_isnumber` 来检查类型，但 Lua 5.2 引入了以下这些新的函数：


```c
lua_Number  lua_tonumberx (lua_State *L, int idx, int *isnum);
lua_Integer lua_tointegerx (lua_State *L, int idx, int *isnum);
```

其中的输出参数，the out parameter，`isnum` 会返回一个表示该 Lua 值是否已成功强制转换为所需类型的布尔值。


函数 `lua_tolstring` 会返回一个指向该字符串内部副本的指针，并将该字符串的长度，存储在 `len` 所指定的位置。我们绝不能更改这个内部副本（这里有个 `const` 提醒我们）。只要栈上存在相应的字符串值，Lua 就会确保该指针有效。当由 Lua 调用的某个 C 函数返回时，Lua 会清空其栈；因此，作为一项规则，我们绝不应将指向 Lua 字符串的指针，存储在获取这些指针的函数之外。

`lua_tolstring` 返回的任何字符串，总是在其末尾有个额外的零，但字符串内部也会有其他的零。经由第三个参数 `len` 返回的大小，是真实字符串的长度。若栈顶的值是个字符串，那么下面的断言总是有效的：


```c
size_t len;
const char *s = lua_tolstring(L, -1, &len); /* any Lua string */
assert(s[len] == '\0');
assert(strlen(s) <= len);
```


若不需要长度，我们可以 `NULL` 作为第三个参数调用 `lua_tolstring`。更妙的是，我们可以使用宏 `lua_tostring`，他只会以 `NULL` 的第三个参数调用 `lua_tolstring`。

为说明这些函数的用法，图 27.2 “转储栈” 给出了一个有用的辅助函数，他可以转储栈的全部内容。


<a name="f-27.2"></a> 图 27.2，转储栈

```c
{{#include ../scripts/overview_C-API/stack_dump.c}}
```


该函数会自下而上遍历 C API 的栈，根据每个元素的类型打印其内容。他会将字符串打印在单引号中；对于数字，他使用了 `"%g"` 的格式；对于没有 C 对应值（表、函数等）的值，他只打印其类型。(`lua_typename` 会将类型代码转换为类型名字。）

在 Lua 5.3 中，我们仍可以使用 `lua_tonumber` 与 `"%g"` 格式打印所有数字，因为整数始终可被转换为浮点数。不过，我们可能更喜欢将整数打印为整数，以避免丢失精度。在这种情况下，我们可以使用新函数 `lua_isinteger`，区分出整数和浮点数：


```c
case LUA_TNUMBER: { /* numbers */
    if (lua_isinteger(L, i)) /* integer? */
        printf("%lld", lua_tointeger(L, i));
    else /* float */
        printf("%g", lua_tonumber(L, i));
    break;
}
```


## 其他栈操作

除了前面那些在 C 和栈之间交换值的函数外，C API 还提供了以下用于一般操纵栈的一些操作：


```c
int     lua_gettop (lua_State *L);
void    lua_settop (lua_State *L, int index);
void    lua_pushvalue (lua_State *L, int index);
void    lua_rotate (lua_State *L, int index, int n);
void    lua_remove (lua_State *L, int index);
void    lua_insert (lua_State *L, int index);
void    lua_replace (lua_State *L, int index);
void    lua_copy (lua_State *L, int fromidx, int toidx);
```

函数 `lua_gettop` 会返回栈上元素的个数，也是栈顶那个元素的索引。函数 `lua_settop` 会将栈顶（即栈中元素数量）设置为某个特定值。若先前栈顶高于新值，则该函数会丢弃多余的栈顶值。相反，该函数会将一些 `nil` 值推入栈，以获得给定大小。特别是，`lua_settop(L, 0)` 会清空该栈。我们还可对 `lua_settop` 使用负的缩影。利用这一设施，C API 提供了以下宏，他会从栈中弹出 `n` 个元素：


```c
#define lua_pop(L,n) lua_settop(L, -(n) - 1)
```

函数 `lua_pushvalue` 会将给定索引处的元素副本，推入栈。


函数 `lua_rotate` 是 Lua 5.3 中新引入的函数。顾名思义，他会将栈元素从给定的索引处，向栈顶翻转 `n` 个位置。正的 `n` 会将该元素向栈顶方向翻转；而负的 `n` 则会向另一方向翻转。这是个相当通用的函数，且其他两个 API 操作，也被定义为使用该函数的宏。其中一个是 `lua_remove`，他会删除给定索引处的元素，并向下移动该位置上方的元素以填补空缺。其定义如下：


```c
#define lua_remove(L,idx) \
          (lua_rotate(L, (idx), -1), lua_pop(L, 1))
```


也就是说，他会将栈翻转一个位置，将指定元素移到顶部，然后弹出该元素。另一个宏是 `lua_insert`，他会将栈顶元素移到指定位置，并将该位置上方的元素移到空位上：


```c
#define lua_insert(L,idx) lua_rotate(L, (idx), 1)
```

函数 `lua_replace` 会弹出某个值，并将其设置为给定索引的值，但不会移动任何内容；最后，`lua_copy` 会将一个索引上的值，拷贝到另一个索引上，但保持原来的值未被改变 <sup>6</sup>。请注意，以下操作对某个非空的栈没有影响：

> 注 <sup>6</sup>：函数 `lua_copy` 是在 Lua 5.2 版本中引入的。


```c
lua_settop(L, -1); /* set top to its current value */
lua_insert(L, -1); /* move top element to the top */
lua_copy(L, x, x); /* copy an element to its own position */
lua_rotate(L, x, 0); /* rotates by zero positions */
```

图 27.3 “栈操作示例” 中的程序，使用了 `stackDump`（定义于 [图 27.2 “转储栈”](#f-27.2) ）来说明这些栈操作。

<a name="f-27.3"></a> 图 27.3，栈操作示例


```c
{{#include ../scripts/overview_C-API/demo_stack_man.c}}
```

> **译注**：
>
> - 以命令 `gcc -o stack_man demo_stack_man.c -llua -ldl` 编译此程序；
>
> - 译者尝试将 `stackDump` 放入到一个 C 头文件 `stack_ops.h` 中，但最后编译失败；
>
> - 运行上述程序的输出为：

```console
$ ./stack_man
true 10 nil 'hello'
true 10 nil 'hello' true
true 10 true 'hello'
true 10 true 'hello' nil nil
true 10 nil true 'hello' nil
true 10 nil 'hello' nil
true
```


## C API 下的错误处理

Lua 中的所有结构都是动态的：他们会按需增长，并在可行时最终再次收缩。这意味着内存分配失败的可能性在 Lua 中普遍存在。几乎所有操作都可能遇到这种情况。此外，许多操作还会抛出其他错误；例如，对某个全局变量的访问，可能会调用一次 `__index` 元方法，而该元方法就可能会抛出错误。最后，分配内存的操作，最终会调用垃圾回收器，而垃圾回收器可能会调用终结器，而终结器也可能抛出错误。总之，Lua API 中的绝大多数函数都可能导致错误。

Lua 使用异常来指出错误，而不是对其 API 中的各个操作使用错误代码。与 C++ 或 Java 不同，C 并未提供某种异常处理机制。为规避这一困难，Lua 使用了 C 语言中的 `setjmp` 设施，这就得到一种与异常处理类似的机制。因此，大多数 API 函数都可以抛出错误（即调用 `longjmp`）而不是返回（错误代码）。


当咱们编写库代码（从 Lua 中调用的 C 函数）时，使用长跳转不需要 C 端的额外工作，因为 Lua 会捕获任何的错误。但是，在咱们编写应用代码（调用 Lua 的 C 代码）时，我们必须提供一种捕获这些错误的方法。


### 应用代码中的错误处理


当咱们的应用调用 Lua API 中的函数时，应用就会面临一些报错。正如我们刚才所讨论的，Lua 通常经由长跳转，提示这些错误。但是，如果没有相应的 `setjmp`，解释器就无法进行长跳转。在这种情况下，API 中的任何错误都会导致 Lua 调用一次 `panic` 函数，在该函数返回时，退出应用。我们可以 `lua_atpanic` 设置自己的 `panic` 函数，但他能做的事情并不多。


为了恰当处理应用代码中的错误，咱们必须经由 Lua 调用咱们的代码，以便他设置一个适当的上下文来捕获错误 -- 也就是说，Lua 要在 `setjmp` 的上下文中运行代码。就像我们可以使用 `pcall` 在保护模式下运行 Lua 代码一样，我们也可以使用 `lua_pcall` 运行 C 代码。更具体地说，我们要将代码打包在某个函数中，然后使用 `lua_pcall` 经由 Lua 调用该函数。在这种设置下，咱们的 C 代码将在保护模式中运行。即使在内存分配失败的情况下，`lua_pcall` 也会返回某个恰当的错误代码，使解释器处于某种一致的状态。下面的代码片段展示了这一想法：


```c
static int foo (lua_State *L) {
    // code to run in protected mode
    return 0;
}
int secure_foo (lua_State *L) {
    lua_pushcfunction(L, foo); /* push 'foo' as a Lua function */
    return (lua_pcall(L, 0, 0, 0) == 0);
}
```


在这个示例中，无论发生什么情况，对 `secure_foo` 的调用都会返回一个表示 `foo` 成功与否的布尔值。特别要注意的是，栈中已有一些预分配的槽，且 `lua_pushcfunction` 不会分配内存，因此他不会抛出任何错误。(函数 `foo` 的原型是 `lua_pushcfunction` 的一项要求，而 `lua_pushcfunction` 在 Lua 中创建了一个表示某 C 函数的函数。我们将在 [“C 函数”](./calling_C.md#C-函数) 小节中，详细介绍 Lua 中的 C 函数。）


### 库代码中的错误处理



