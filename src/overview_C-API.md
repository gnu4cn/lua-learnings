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


