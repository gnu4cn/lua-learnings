# C API 概述

Lua 是一门 *嵌入式语言，embedded language*。这意味着 Lua 并不是一个独立的应用，而是一个我们可以将其与其他应用链接，将 Lua 设施纳入其中的库。


咱们可能会想：既然 Lua 不是个独立的程序，那为什么我们在这整本书中，一直都在使用 Lua 这个独立程序呢？这个问题的答案就是 Lua 解释器 -- 可执行的 `lua`。这个可执行文件是个小的应用程序，大约有六百行代码，使用 Lua 库来实现了独立的解释器。该程序处理与用户的接口，接收用户的文件和字符串，将其输入到完成大部分工作（比如实际运行 Lua 代码）的 Lua 库。

这种作为库用于扩展应用的能力，使 Lua 成为一门 *可嵌入的语言，embeddable language*。同时，使用 Lua 的程序，可在 Lua 环境中注册新的函数；这些函数是以 C （或其他语言）实现的，因此他们可以添加 Lua 无法直接编写的一些设施。这就是 Lua 成为一门 *可扩展语言，extensible language* 的原因。

Lua 的这两种视角（作为一门可嵌入语言和一门可扩展语言），对应了 C 和 Lua 之间的两种交互方式。在第一种交互中，C 语言有着控制权，而 Lua 则是库。这种交互中的 C 代码，就是我们所说的 *应用代码，application code*。在第二种交互中，Lua 拥有控制权，而 C 是库。在这里，C 代码被称为 *库代码，library code*。应用代码和库代码，都使用同样的 API 与 Lua 进行通信，即所谓的 C API。

所谓 C API，是一组实现 C 代码与 Lua 交互的函数、常量和类型 <sup>1</sup>。C API 由读写 Lua 全局变量、调用 Lua 函数、运行 Lua 代码片段，以及注册 C 函数以便 Lua 代码可以调用他们等的函数构成。几乎所有 Lua 代码能做的事情，C 代码经由 C API 都能完成。

> 注：原文为 “The C API is the set of functions, constants, and types that allow C code to interact with Lua”。在本教材中，“函数” 一词实际上指的是 “函数或宏”。API 以宏的形式实现了多种功能。


C API 遵循的是 C 语言的 *运作方式* <sup>2</sup>，与 Lua 截然不同。在使用 C 语言编程时，我们必须关注类型检查、错误恢复、内存分配错误以及其他一些复杂性来源。API 中的大多数函数都不会检查其参数的正确性；我们有责任在调用函数之前确保参数是有效的2。此外，应用程序接口强调灵活性和简洁性，但有时却牺牲了易用性。普通任务可能需要调用多次 API。这可能很无聊，但却能让我们完全控制所有细节。

> 译注：原文为 “ the *modus operandi* ”，为拉丁文，英文翻译 “mode of operation”。
>
> 参考：[wikipedia: 犯罪手法](https://zh.wikipedia.org/zh-cn/%E7%8A%AF%E7%BD%AA%E6%89%8B%E6%B3%95)
