# 扩展咱们的应用


Lua 的一个重要用途，是作为一种 *配置* 语言。在本章中，我们将从一个简单的示例开始，演示咱们可以怎样使用 Lua，配置某个程序，并将该示例发展为完成愈加复杂的任务。


## 基础


作为咱们的首个任务，我们来设想一个简单的配置场景：咱们的 C 程序有一个窗口，且咱们希望用户能够指定初始的窗口大小。显然，对于这样一个简单任务，相比使用 Lua，有好几种更简单的选项，比如环境变量或有着一些名字-值对的文件。但即便使用简单的文本文件，我们也必须对其进行某种解析；因此，我们决定使用 Lua 的配置文件（即碰巧是各 Lua 程序的纯文本文件）。在其最简单的形式中，该文件可包含类似下面的内容：


```lua
-- define window size
width = 200
height = 300
```

现在，我们必须使用 Lua API 指导 Lua 解析该文件，然后获取全局变量 `width` 和 `height` 的值。图 28.1 “从配置文件中获取用户信息” 中的函数 `load` 完成了这项工作。

<a name="f-28.1"></a> **图 28.1，从配置文件中获取用户信息**


```c
{{#include ../scripts/extending/getting_user_info.c:5:}}
```

其假定咱们已经按照上一章的方法，创建出了个 Lua 状态。其调用 `luaL_loadfile`，从文件 `fname` 中加载 Lua 块，然后调用 `lua_pcall` 运行编译后的程序块。若出现错误（比如咱们配置文件中的语法错误），这些函数就会将错误信息推送到栈上，并返回一个非零的错误代码；然后我们的程序会以索引 `-1`，使用 `lua_tostring` 从栈顶部获取信息。(在 [“首个示例”](./overview_C-API.md#首个示例) 小节中，咱们定义了函数 `error`。）

运行该 Lua 代码块后，程序就需要获取到全局变量的值。为此，其调用了辅助函数 `getglobint`（见图 28.1 [“从配置文件获取用户信息”](#f-28.1) ）两次。该函数首先调用 `lua_getglobal`，其唯一参数（除那个无处不在的 `lua_State` 外），将相应的全局值推入栈上。接下来，`getglobint` 使用 `lua_tointegerx`，将该值转换为整数，确保其有着正确的类型。


值得用 Lua 来完成这项任务吗？正如我（作者）之前所说，对于这样一个简单任务，使用只有两个数字的简单文件，会比使用 Lua 更容易。即便如此，使用 Lua 还是有些优势。首先，Lua 为我们处理了所有语法细节；我们的配置文件甚至可以有注释！其次，用户已经可以使用他，完成一些复杂的配置。例如，这个脚本可以提示用户一些信息，或者查询环境变量以选择合适的大小：


```lua
-- configuration file
if getenv("DISPLAY") == ":0.0" then
    width = 300; height = 300
else
    width = 200; height = 200
end
```

即使在如此简单的配置场景下，也很难预见用户想要什么。但是，只要脚本定义这两个变量，咱们的 C 应用就可以无需更改。


> **译注**：译者测试本小节的代码时，已将函数 `error`、`getglobint` 与 `load` 三个函数放入单独库文件 `extending_lib.h`，并通过头文件 `extending_lib.h` 实现在 C 主文件 `main.h` 中导入，最后通过编译命令 `gcc -o test main.c extending_lib.c -llua -ldl` 编译为二进制可执行文件。三个文件如下。

- *`extending_lib.c`*

```c
{{#include ../scripts/extending/extending_lib.c}}
```


- *`extending_lib.h`*

```c
{{#include ../scripts/extending/extending_lib.h}}
```


- *`main.c`*


```c
{{#include ../scripts/extending/main.c}}
```

> 参考：[C header issue: #include and "undefined reference"](https://stackoverflow.com/a/10357161/12288760)
