# 入门

为了保持传统，咱们用 Lua 编写的第一个程序，只是打印 `"Hello World"`：


```lua
print("Hello World")
```

如果咱们使用的是独立的 Lua 解释器，要运行第一个程序，只需调用解释器 -- 通常命名为 `lua` 或 `lua5.3`，并输入包含程序的文本文件名称即可。如果将上述程序保存在 `hello.lua` 文件中，下面的命令就可以运行它：

```bash
% lua hello.lua
```


作为一个更复杂示例，下一个程序定义了一个计算给定数字阶乘的函数，要求用户输入一个数字，并打印其阶乘：


```lua
-- defines a factorial function
function fact (n)
    if n == 0 then
        return 1
    else
        return n * fact(n - 1)
    end
end

print("Please enter a number:")
a = io.read("*n")               -- reads a number
print(fact(a))
```

> **注意**：此 Lua 脚本，只能计算到 `25` 的阶乘，`26` 往上将发生溢出。


## 代码块

**Chunks**


我们将 Lua 执行的每段代码（如某个文件，或交互模式下的一行代码），称为一个 *代码块，chunk*（块）。一个代码块就是一个命令（或语句）序列。


代码块可以是简单的一条语句，如 "Hello World "示例；也可以由语句和函数定义（实际上是赋值，稍后我们将看到）混合组成，如那个阶乘示例。代码块大小可以随心所欲。由于 Lua 同时也是一种数据描述语言，a data-description language，因此几兆字节的代码块并不少见。Lua 解释器在处理大块时，完全没有问题。


咱们可以在交互模式下，运行独立解释器，the stand-alone interpreter，而不用将程序写入文件。如果不带任何参数调用 `lua`，咱们将得到这样的提示符：

```lua
$ lua
Lua 5.4.6  Copyright (C) 1994-2023 Lua.org, PUC-Rio
>
```

此后，输入的每一条命令（如 `print "Hello World"`），都会在输入后立即执行。要退出交互模式与解释器，只需键入文件结束控制字符（POSIX 中为 `ctrl-D`，Windows 中为 `ctrl-Z`），或调用操作系统库中的 `os.exit` 函数 -- 必须键入 `os.exit()`。


从 5.3 版本开始，咱们可以在交互模式下，直接输入表达式，Lua 就会打印出他们的值：


```bash
~ lua
Lua 5.4.6  Copyright (C) 1994-2023 Lua.org, PUC-Rio
> math.pi / 4
0.78539816339745
> a = 15
> a^2
225.0
> a + 2
17
```

在较早版本中，咱们需要在这些表达式前面，加上等号：


```bash
% lua5.2
Lua 5.2.3 Copyright (C) 1994-2013 Lua.org, PUC-Rio
> a = 15
> = a^2             --> 225
```

为了兼容性，Lua 5.3 仍然接受这些等号。


而要将这些代码，作为代码块运行（非交互模式下），咱们必须将表达式，包含在对 `print` 的调用中：


```lua
print(math.pi / 4)
a = 15
print(a^2)
print(a + 2)
```


Lua 通常将咱们在交互模式下键入的每一行，解释为一个完整的块或表达式。然而，如果他检测到该行不完整，他就会等待更多的输入，直到有一个完整的块。这样，咱们就可以直接在交互模式下，输入多行的定义，例如之前那个阶乘函数。然而，通常更方便的做法是，将这样的定义放在一个文件中，然后调用 Lua 来运行该文件。


咱们可以使用 `-i` 选项，来指示 Lua 在运行给定块后，启动交互式会话：


```bash
% lua -i prog
```

像这样的命令行，将运行文件 `prog` 中的代码块，然后提示交互，prompt for interaction。对于调试及手动测试，这特别有用。在本章最后，我们将看到独立解释器的其他选项。


运行代码块的另一方法，是使用 `dofile` 函数，其可以立即执行文件。例如，假设咱们有一个包含以下代码的 `lib.lua` 文件：


```lua
function norm (x, y)
    return math.sqrt(x^2 + y^2)
end

function twice (x)
    return 2.0 * x
end
```


然后，在交互模式下，咱们可以输入以下代码：


```bash
> dofile("lib.lua")
> n = norm(3.4, 1.0)
> n
3.5440090293339
> twice(n)
7.0880180586677
```

在咱们测试某段代码时，函数 `dofile` 也很有用。我们可以使用两个窗口：一个是有着咱们程序的文本编辑器（例如，在 `prog.lua` 文件中），另一个是以交互模式运行 Lua 的控制台。在咱们的程序中保存修改后，我们便在 Lua 控制台中，执行 `dofile(“prog.lua”)` 来加载新代码；然后咱们就可以运行新代码，调用其函数并打印结果。


## 部分词法规定

**Some Lexical Conventions**


Lua 中的标识符（或名称），可以是字母、数字和下划线的任意字符串，不能以数字开头；例如


```lua
i   j   i10     _ij
aSomewhatLongName   _INPUT
```

应避免使用以下划线开头、后跟一个或多个大写字母的标识符（例如 `_VERSION`）；他们在 Lua 中，被保留用于特殊用途。通常，我将标识符 `_`（单个下划线）保留给虚拟变量，dummy variables。


下列词语为保留字，不能用作标识符：


```lua
and     break       do      else        elseif
end     false       for     function    goto
if      in          local   nil         not
or      repeat      return  then        true
until   while
```

Lua 区分大小写：`and` 是一个保留字，但 `And` 和 `AND`，则是两个不同的标识符。


注释以两个连续的连字符 （`--`） 开始，直至行尾。Lua 还提供长注释，他们以两个连字符开始，后面是两个开头的方括号（`[[`），直到第一次出现两个连续的结尾方括号（`]]`）为止，就像下面这样[<sup>注 1</sup>](#尾注)：


```lua
--[[A multi-line
long comment
]]
```


我们注释掉一段代码的常用技巧，是将代码括在 `--[[` 和 `--]]` 之间，就像这里一样：


```lua
--[[
print(10)           -- no action (commented out)
--]]
```


要重新激活这段代码，咱们要在第一行，添加一个连字符：


```lua
---[[
print(10)           --> 10
--]]
```

第一个示例中，第一行中的 `--[[`，开始了一个长注释，最后一行中的两个连字符，仍在该注释内。在第二个示例中，序列，the sequence，`---[[` 开启了一个普通的单行注释，以便第一行和最后一行，成为独立的注释。在这种情况下，`print` 是位于注释之外的。


Lua 不需要连续语句之间的分隔符，但如果咱们愿意，是可以使用分号（`;`）的。换行符在 Lua 语法中，不起作用；例如，以下四个块都是有效且等价的：

```lua
a = 1
b = a * 2


a = 1;
b = a * 2;


a = 1; b = a * 2


a = 1 b = a * 2     -- ugly, but valid
```

我（作者）个人的惯例，是仅当在同一行中，写入两个或多个语句时，才使用分号（我几乎不这样做）。


## 全局变量

全局变量不需要声明；咱们只是使用他们。访问未初始化的变量不会是错误；我们只会得到 nil 作为结果：


```lua
> b
nil
> b = 10
> b
10
```

如果咱们将 `nil` 赋值给全局变量，Lua 就会认为，我们从未使用过该变量：


```lua
> b = nil
> b
nil
```

Lua 不会区分未初始化的变量，和赋值为 `nil` 的变量。赋值后，Lua 便可最终回收变量使用的内存。



## 类型与值

**Types and Values**


Lua 是一门动态类型语言。语言中没有类型定义；每个值都有自己的类型。


Lua 有八种基本类型：`nil`、布尔、数字、字符串、用户数据，`userdata`、函数，`function`、线程，`thread` 及表，`table`。函数 `type` 给出了任何给定值的类型名称：

```lua
> type(nil)
nil
> type(false)
boolean
> type(10.4 * 3)
number
> type("Hello World")
string
> type(io.stdin)
userdata
> type(print)
function
> type(type)
function
> type({})
table
> type(type(X))
string
```

无论 `X` 的值为何，最后一行的结果都是 `string`，因为 `type` 的结果，总是字符串。


`userdata` 类型，允许在 Lua 变量中存储任意 C 的数据。除了赋值和相等条件测试外，其在 Lua 中没有预定义的操作。`userdata` 用于表示由应用程序，或 C 语言编写的库所创建的新类型；例如，标准 I/O 库就使用他们，来表示打开的文件。关于 `userdata`，我们将在稍后讨论 C API 时,进一步讨论。


变量没有预先定义的类型；任何变量，都可以包含任何类型的值：


```lua
> type(a)
nil                 --> nil     ('a' is not initialized)
> a = 10
> type(a)
number
> a = "a string!"
> type(a)
string
> a = nil
> type(a)
nil
```

通常，当咱们使用单个变量，来表示不同的类型时，会导致代码混乱。不过，有时明智地使用这一工具，还是很有帮助的，例如使用 `nil` 来区分正常返回值与异常情况。


现在我们将讨论简单类型 `nil` 和布尔类型。在接下来的章节中，我们将详细讨论 `number`（第 3 章，*数字*）、`string`（第 4 章，*字符串*）、`table`（第 5 章，*表*）和 `function`（第 6 章，*函数*）类型。我们将在第 24 章 *例程，Coroutines* 中，讨论 `thread` 类型。


### 空值，Nil


空值，Nil，是一种只有一个值 `nil` 的类型，其主要特性是不同于任何其他值。Lua 使用 `nil` 作为一种非值，a kind of non-value，表示没有用处的值。正如我们所看到的，全局变量在第一次赋值之前，其默认值为 `nil`，我们可以给某个全局变量赋值 `nil` 来删除他。


### 布尔值

布尔类型有两个值，`@false{}` 和 `@true{}`，他们代表传统的布尔值。然而，布尔值没有垄断条件值：在 Lua 中，任何值都可以表示条件。条件测试（如控制结构中的条件），会将布尔值 `false` 和 `nil` 视为 `false`，而将其他任何值，视为 `true`。特别是，在条件测试中，Lua 将 `0` 和空字符串（`""`），都视为 `true`。


在本书中，我（作者）将用“假，false”，表示任何的 `false`，即布尔值 `false` 或 `nil`。当我特指布尔值时，我会写成 “**false**”。`true` 和 “**true**” 也是如此。


Lua 支持一组常规的逻辑运算符：`and`、`or` 和 `not`。与控制结构一样，所有逻辑运算符，都将布尔值 `false` 和 `nil` 视为 `false`，而将其他任何值视为 `true`。如果 `and` 运算符的第一个操作数为 `false`，那么其结果就是该操作数；否则，他的结果就是第二个操作数。如果 `or` 运算符的第一个操作数不是 `false`，那么其结果就是他的第一个操作数；否则，他的结果就是他的第二个操作数：


```lua
> 4 and 5
5
> nil and 13
nil
> false and 13
false
> 0 or 5
0
> false or "hi"
hi
> nil or false
false
```

> **注意**：Lua 交互模式下，清除屏幕：
>
> 1. 在 Windows 系统上：`os.execute("cls")`；
>
> 2. 在 *nix 系统上：`os.execute("clear")`。


`and` 和 `or` 都用到了短路求值，short-circuit evaluation，即只在必要时，才计算第二个操作数。短路求值确保了类似 `(i ~= 0 and a/i > b)` 这样的表达式，不会引发运行时错误： 当 `i` 为零时，Lua 不会尝试对 `a / i` 求值。


一种有用的 Lua 习惯用法，便是 `x = x or v`，这相当于：


```lua
if not x then x = v end
```

也就是说，当 `x` 未被设置时，该表达式会将 `x`，设置为默认值 `v`（前提是 `x` 未被设置为 `false`）。

> **注意**：这里即使 `x` 被设置为了 `false`，仍然会被赋值为 `v` 的值。因此怀疑这里属于笔误，实际应为 “前提是 `v` 未被设置为 `nil`”，因为即使 `v` 被设置为 `false`，`x` 仍会被赋值为 `v` 的值 `false`。


另一种有用的习惯用法，是 `((a and b) or c)`，或简写为 `(a and b or c)`（鉴于 `and` 的优先级高于 `or`）。这等价于 C 语言表达式 `a ? b : c`，前提是 `b` 不为 `false`。例如，咱们可以用表达式 `(x > y) and x or y`，从两个数 `x` 和 `y` 中，选择出最大值。当 `x > y` 时，`and` 的第一个表达式为真，因此 `and` 的第二个操作数（`x`）总是真的（因为他是一个 `number`），然后 `or` 表达式的结果，是其第一个操作数 `x` 的值。

`not` 运算符，则总是给到一个布尔值：


```lua
> not nil
true
> not false
true
> not 0
false
> not not 1
true
> not not nil
false
```


## 关于独立解释器

**The Standa-Alone Interpreter**

独立解释器（因其源文件，也被称为 `lua.c`，因其可执行文件也称为 `lua`），是一个可以直接用上 Lua 的小程序。本节将介绍其主要选项。

在解释器加载文件时，如果文件的第一行以哈希符号（`#`）开头，则解释器会忽略该行。这一特性允许在 POSIX 类型的系统中，将 Lua 用作脚本解释器。在我们以类似

```lua
#!/usr/local/bin/lua
```

（假设独立解释器位于 `/usr/local/bin`），或

```lua
#/usr/bin/env lua
```

开始咱们的脚本时，咱们就可以直接调用该脚本，而显式调用 Lua 解释器。

`lua` 明亮的用法为：

```bash
lua [options] [script [args]]
```

一切都是可选的。正如已经看到的，当咱们调用不带参数的 `lua` 时，解释器会进入交互模式。


`-e` 选项允许咱们直接在命令行中，输入代码，就像这里一样：

```bash
% lua -e "print(math.sin(12))" --> -0.53657291800043
```


（POSIX 系统需要双引号，来阻止 shell 对其中的括号进行解释）。


`-l` 选项加载某个库。如前所述，`-i` 则会在运行其他参数后，进入交互模式。因此，下一次调用将加载 `lib` 库，然后执行赋值 `x = 10`，最后出现一个交互提示。


```bash
% lua -i -llib -e "x = 10"
```

如我们在交互模式下写出一个表达式，Lua 会打印其值：


```lua
> math.sin(3)
0.14112000805987
> a = 30
> a
30
```

（请记住，此功能是 Lua 5.3 带来的。在旧版本中，我们必须在表达式前，加上等号）。而为了避免打印，咱们可以用分号结束该行：

```lua
> io.flush()
true
> io.flush();
>
```

分号会令到该行作为表达式的语法无效，但其作为命令仍然是有效的。

运行其参数前，解释器会查找名为 `LUA_INIT_5_3` 的环境变量，如果没有，则会查找 `LUA_INIT`。如果存在这样一个变量，且其内容为 `@file-name`，那么解释器将运行那个给定的文件。如果定义了 `LUA_INIT_5_3`（或 `LUA_INIT`），但其不是以 at 符号（`@`）开头，那么解释器就会认为，该环境变量包含了 Lua 代码，并运行他。在配置独立解释器时，`LUA_INIT` 赋予了我们很强能力，因为我们可以在配置中，使用 Lua 的全部能力。我们可以预加载软件包、修改路径、定义咱们自己的函数、重命名或删掉某些函数等等。


> **注意**：`LUA_INIT` 环境变量，类似于 `~/.bashrc`，或 `~/.zshrc` 这样的功能。


脚本可以通过预定义的全局变量 `arg`，获取到其参数。在 `% lua script a b c` 这样的调用中，解释器会在运行任何代码前，创建出包含所有命令行参数的 `arg` 表，the table `arg`。脚本名称会进入索引 `0`，第一个参数（示例中的 `"a"`）进入索引 `1`，依此类推。前面的选项，因为出现在脚本之前，会进入负的索引。例如，请看下面的调用：


```lua
% lua -e "sin=math.sin" script a b
```

解释器会会收集到下面这些参数：


```lua
arg[-3] = "lua"
arg[-2] = "-e"
arg[-1] = "sin=math.sin"
arg[0] = "script"
arg[1] = "a"
arg[2] = "b"
```

通常情况下，脚本只会用到正索引（例子中的 `arg[1]` 和 `arg[2]`）。


脚本还可以通过 `vararg` 表达式，获取参数。在脚本的主体，the main body of a script，中，表达式 `...`（三点）会产生出脚本的参数。(我们将在 “变量函数，Variadic Functions” 小节，讨论 `vararg` 表达式）。

## 尾注

1. 长注释可能比这更复杂，我们将在 [“长字符串”](strings.md#长字符串) 小节，看到这一点。

## 练习

（略）
