# 反射

**Reflection**


反射，是指程序检查、修改其自身执行某些方面的能力。动态语言（如 Lua）自然而然支持多种反射特性：

- 环境特性允许运行时的全局变量检查；
- 诸如 `type` 及 `pairs` 等函数，允许运行时的未知数据结构检查和遍历；
- 而诸如 `load` 及 `require` 等函数，则允许程序为自身添加代码，或更新自己的代码。


然而，仍缺少许多东西：

- 程序无法自省其局部变量；
- 程序无法跟踪其执行情况；
- 函数无法获悉其调用者等等。


调试库，the `debug` library，填补了这些空白。


调试库包含两类函数：

- *内省函数，introspective functions*；
- 和 *钩子，hooks*。


内省函数允许我们检查正在运行程序的多个方面，譬如活动函数堆栈、当前执行行及局部变量的值和名称等。钩子则允许我们跟踪程序的执行。


尽管名为调试库，但他并未提供给我们一个 Lua 调试器。不过，他提供了编写我们自己调试器所需的、复杂程度各不相同的全部原语。


与其他库不同，我们应谨慎使用调试库，use the debug library with parsimony。首先，调试库的某些功能，并不以性能著称。其次，他打破了该门语言的一些神圣真理，比如我们不能从局部变量的词法范围外，访问该局部变量这一条。虽然调试库与标准库一样直接可用，但我（作者）更倾向于，在任何用到调试库的代码块中，显式地导入他。


## 自省设施 - `debug.getinfo`

**Introspective Facilities**


调试库中的主要自省函数为 `getinfo`。其第一个参数可以是某个函数，或某个堆栈层级，a stack level。当我们对某个函数 `foo`，调用 `debug.getinfo(foo)` 时，他会返回一个包含有着该函数一些数据的表。该表可能包含以下字段：


- `source`：该字段给出函数于何处定义。如果该函数定义在某个字符串中（经由一次 `load` 调用），`source` 就是那个字符串。如果函数定义在在某个文件中，`source` 就是以 `@` 符号为前缀的文件名；

- `short_src`：该字段是 `source` 简短版本（最多 60 个字符）。这对于错误消息非常有用；

- `linedefined`：该字段给出来源中定义该函数处的第一行编号；

- `lastlinedefined`：该字段给出来源中定义该函数处的最后一行编号；

- `what`：该字段给出了该函数是什么。如果 `foo` 是个常规 Lua 函数，则选项为 `Lua`；如果是个 C 函数，则选项为 `C`；如果该函数是某个 Lua 代码块的主要部分，则为 `main`；

- `name`：该字段给出一个该函数的合理名称，比如存储该函数的全局变量名字；

- `namewhat`：该字段给出前一字段的含义。该字段可以是 `global`、`local`、`method`、`field` 或 `''`（空字符串）。空字符串表示 Lua 没有找到该函数的名字；

- `nups`：这是该函数的上值个数，the number of upvalues；

- `nparams`：这是该函数的参数个数；

- `isvararg`：这表示该函数是否为可变参数（一个布尔值），whether the function is variadic；

- `activelines`：该字段是个表示函数活动行的集合的表。所谓 *活动行，active line*，是指有代码的行，而不是空行或仅包含注释的行。(此信息的一个典型用途是设置断点。大多数调试器都不允许我们在活动行之外设置断点，因为这样的断点是无法到达的。）

- `func`：该字段为函数本身。


当 `foo` 是个 C 语言函数时，Lua 就没有太多关于他的数据。对于此类函数，只有 `what`、`name`、`namewhat`、`nups` 和 `func` 字段是有意义的。

当我们以某个数字 `n` 调用 `debug.getinfo(n)` 时，我们会获取到有关活动于该堆栈级别函数的数据，data about the function active at that stack level。所谓 *堆栈级别*，是个指向活动于该时刻的某个特定函数的数字。调用 `getinfo` 的函数级别为一，调用他的函数级别为二，依此类推。（在级别零处，我们就会得到有关 `getinfo` 本身（一个 C 函数）的数据。）如果 `n` 大于了堆栈上的活动函数数量，`debug.getinfo` 就会返回 `nil`。当我们通过调用带有堆栈级别的 `debug.getinfo` ，查询某个活动函数时，结果表会有两个额外的字段：

- `currentline`，该函数当时所在的行；
- `istailcall`（一个布尔值），在该函数是经由一个尾调用而被调用到时，则为 `true`。（在这种情况下，该函数的真正调用者已不在堆栈上了。）

`name` 字段很棘手。请记住，由于函数是 Lua 中的头等值，functions are first-class values in Lua，因此函数可能没有名字，也可能有多个名字。Lua 通过查看调用函数代码，了解某个函数是如何被调用的，尝试找到该函数的名字。这种方式只有在我们以某个数字调用 `getinfo` ，即在我们请求有关某个特定调用的信息时，才会起作用。

函数 `getinfo` 并不高效。Lua 以不影响程序执行的形式，保存调试信息；高效检索是次要目标。为达到更好性能，`getinfo` 有个用于选取要获得信息的可选的第二个参数。这样，该函数就不会浪费时间收集用户不需要的数据。该参数的格式是个字符串，其中每个字母会选取一组字段，如下表所示。

| 选项 | 意义 |
| :-: | :- |
| `n` | 选取 `name` 与 `namewhat` |
| `f` | 选取 `func` |
| `S` | 选取 `source`、`short_src`、`what`、`linedefined` 与 `lastlinedefined` |
| `l` | 选取 `currentline` |
| `L` | 选取 `activelines` |
| `u` | 选取 `nups`、`nparams` 与 `isvararg` |


下面这个函数通过打印出活动堆栈的原始回溯，说明了 `debug.getinfo` 用法：


```lua
function traceback ()
    for level = 1, math.huge do
        local info = debug.getinfo(level, "Sl")

        if not info then break end

        if info.what == "C" then    -- 是个 C 函数？
            print(string.format("%d\tC 函数", level))
        else    -- 是个 Lua 函数
            print(string.format("%d\t[%s]:%d", level, info.short_src, info.currentline))
        end

    end
end
```

要改进这个函数并不难，只要包含更多 `getinfo` 中的数据即可。实际上，调试库就提供了这样一个改进版本，即函数 `traceback`。与我们的版本不同，`debug.traceback` 并不打印结果；而是返回一个包含回溯信息的字符串（可能很长）：


```console
> print(debug.traceback())
stack traceback:
        stdin:1: in main chunk
        [C]: in ?
```


## 访问本地变量 - `debug.getlocal`

**Accessing local variables**


使用 `debug.getlocal`，我们可以检查任何活动函数的局部变量。该函数有两个参数：

- 所查询函数的堆栈级别；
- 以及某个变量的索引。


他会返回两个值：名字与其当前值。若变量索引大于了活动变量数目，则 `getlocal` 就会返回 `nil`。若堆栈级别无效，其会抛出一个错误。(我们可使用 `debug.getinfo`，检查堆栈级别的有效性。）

Lua 按照其在函数中出现的顺序，对局部变量编号，只计算在函数当前作用域中活动的变量。例如，请看下面的函数：


```lua
function foo (a, b)
    local x
    do local c = a - b end
    local a = 1
    while true do
        local name, value = debug.getlocal(1, a)
        if not name then break end
        print(name, value)
        a = a + 1
    end
end
```

调用 `foo(10, 20)` 将打印如下输出：


```console
a       10
b       20
x       nil
a       4
```


索引为 `1` 的变量是 `a`（第一个参数），`2` 是 `b`，`3` 是 `x`，`4` 为内部的 `a`。在调用 `getlocal` 时，`c` 已经超出了作用域，同时 `name` 和 `value` 还不在作用域中。(请记住，局部变量只有在其初始化代码后才可见）。

从 Lua 5.2 开始，负的索引会获取到有关可变参数函数的额外参数信息：索引 `-1` 指向第一个额外参数。在这种情况下，变量的名字将始终是 `"(*vararg)"`。

使用 `debug.setlocal`，我们还可以改变局部变量的值。与 `getlocal` 中类似，其前两个参数为堆栈级别与变量索引。他的第三个参数，则是该变量的新值。他会返回变量的名字，或在变量索引超出作用域时返回 `nil`。


## 访问非本地变量 - `debug.getupvalue`

**Accessing non-local variables**

调试库还允许我们使用 `getupvalue`，访问某个 Lua 函数用到的非本地变量。不同于局部变量，被某个函数引用的非本地变量，即使在该函数未活动时也存在（这就是闭包的意义所在）。因此，`getupvalue` 的第一个参数，便不是某个堆栈层级，而是个函数了（更准确地说是闭包）。第二个参数是变量的索引。Lua 以非本地变量在函数中首次引用的顺序为其编号，但这个顺序不是相对的，因为函数无法访问两个同名的非本地变量。


使用 `debug.setupvalue`，我们还可以更新非本地变量。如咱们所料，他有三个参数：一个闭包、一个变量索引以及一个新值。类似 `setlocal`，他会返回变量的名字，或在变量索引超出范围时返回 `nil`。


下图 25.1，“获取某个变量的值” 展示了如何在给定变量名字情况下，从调用函数访问某个变量的值。


<a name="f-25.1"></a> **获取某个变量的值**

```lua
{{#include ../scripts/reflection/getting_variable_value.lua}}
```


其可这样使用：


```console
> local a = 4; print(getvarvalue("a"))      --> local   4
> a = "xx"; print(getvarvalue("a"))         --> global  xx
```

> **译注**：进一步检查发现，这个 `getvarvalue` 函数似乎并不能如预期那样，访问到非本地变量。

参数 `level` 告诉该函数应查看堆栈上的何处；`1`（默认值）表示直接调用者。代码中的加一校正了堆栈级别，以包括对 `getvarvalue` 本身的调用。我(作者)稍后将解释参数 `isenv`。

该函数首先会查找局部变量。如果有多个给定名字的局部变量，则其必须获取索引最高的那个；因此，他必须始终遍历整个循环。如果他找不到任何有着该名字的局部变量，随后就会尝试非局部变量。为此，他使用 `debug.getinfo`，获取调用闭包，然后遍历其非局部变量。最后，若他找不到有着该名字的非局部变量，则他会查找全局变量：其会递归调用自身，以访问正确的 `_ENV` 变量，然后在该环境中查找那个名字。

参数 `isenv` 避免了一个棘手的问题。他告诉了咱们何时处于某个递归调用中，要查找变量 `_ENV` 来查询某个全局的名字。未用到全局变量的函数，就可能没有上值 `_ENV`。在这种情况下，如果我们尝试将 `_ENV` 作为全局变量，就将进入某种递归循环，因为我们需要 `_ENV` 来获取其自身的值。因此，当 `isenv` 为 `true` 并且函数无法找到局部变量或某个上值时，他就不会尝试全局变量（译者注：此时会在 “尝试非本地变量” 中找到。）


## 访问其他协程

**Accessing other coroutines**

调试库中的所有自省函数，都接受一个可选的协程作为其第一个参数，这样我们就可以从外部检查该协程。例如，请看下一示例：


```lua
{{#include ../scripts/reflection/coroutine_inspection.lua}}
```

其中到 `traceback` 的调用，将作用于协程 `co` 上，结果类似于下面这样：

```console
> lua scripts/coroutine_inspection.lua
stack traceback:
        [C]: in function 'coroutine.yield'
        scripts/coroutine_inspection.lua:3: in function <scripts/coroutine_inspection.lua:1>
```

栈追踪不会经过调用 `resume`，因为协程和主程序运行在不同栈上。


当某个协程抛出错误时，他不会释放其堆栈，unwind its stack。这意味着我们可以在该报错后对其加以检查。继续咱们的示例，若我们再次恢复该协程，他就会遇到那个报错：


```lua
print(coroutine.resume(co))         --> false   scripts/coroutine_inspection.lua:4: some error
```

现在，若我们打印其回溯，就会得到如下结果：


```console
stack traceback:
        [C]: in function 'error'
        scripts/coroutine_inspection.lua:4: in function <scripts/coroutine_inspection.lua:1>
```

我们还可以检查协程中的局部变量，即使在报错后：

```lua
print(debug.getlocal(co, 1, 1))         --> x       10
```

## 钩子

**Hooks**

调试库的钩子机制，允许我们注册一个在程序运行过程中，发生一些特定事件时调用的函数。有四种可以触发钩子的事件：

- 于 Lua 调用某个函数时，发生的 `call` 事件；
- 于函数返回值时，发生的 `return` 事件；
- 于 Lua 开始执行某个新代码行时，发生的 `line` 事件；
- 在给定数量的指令后，发生的 `count` 事件。（这里的 “指令” 指的是内部操作码，internal opcodes，我们在 [“预编译代码” 小节](cee.md#预编译的代码) 中简要介绍过。）

Lua 会以一个描述产生该钩子调用事件的字符串参数，调用所有钩子： `call`（或 `tail call`）、`return`、`line` 或 `count`。对于行事件，他还会传递第二个参数，即新行的编号。要得到某个钩子内部的更多信息，我们必须调用 `debug.getinfo`。

要注册一个钩子，我们以两到三个参数，调用 `debug.sethook`：

- 第一个参数是钩子函数；
- 第二个参数是描述我们要监控事件的掩码字符串，a mask string；
- 第三个参数是个可选的数字，描述我们希望以何种频率，获取计数事件。


要监控 `call`、`return` 及 `line` 事件，我们就要把他们的首字母（`c`、`r` 或 `l`），添加到掩码字符串中。要监控计数事件，我们只需提供一个计数器作为第三个参数。要关闭这些钩子，我们就要不带参数调用 `sethook`。


举个简单的例子，下面的代码会安装一个原始追踪器，他会打印出解释器执行的每一行：


```lua
debug.sethook(print, "l")
```

此调用只是将 `print` 安装为钩子函数，并指示 Lua 仅在行事件时调用他。更复杂的跟踪器则可使用 `getinfo`，将当前文件的名字，添加到行的追踪：


```lua
{{#include ../scripts/reflection/elaborated_tracer.lua}}
```

与钩子一起使用的一个有用函数是 `debug.debug`。这个简单的函数，给到我们一个执行任意 Lua 命令的提示符。他大致相当于以下代码：


```lua
{{#include ../scripts/reflection/debug_impl.lua}}
```

当用户输入 “命令” `cont` 时，该函数就会返回。标准实现非常简单，且会在全局环境中，所调试代码作用域外部运行命令。[练习 25.4](#exercise_25.4) 讨论了一种更好的实现。


## 分析

**Profiles**


除调试外，反射机制的另一常见应用，便是分析，profiling，即分析程序在资源使用方面的行为。对于时序分析，timing profile，最好使用 C 接口：每个钩子一次 Lua 调用的开销太大，可能会使任何测量都无效。不过，对于计数的分析，counting profiles，Lua 代码的表现还算不错。在本节中，我们将开发一个列出某次运行过程中，各个函数调用次数的初级分析器，a rudimentary profiler that lists the number of times each function in a program is called during a run。

咱们的程序主要数据结构是两个表：

- 一个将函数映射到其调用计数器；
- 另一个将函数映射到其名字。


两个表的索引，都是函数本身。


```lua
{{#include ../scripts/reflection/profiler.lua::2}}
```

我们可在分析后获取函数名，但请记住，如果我们在某个函数处于活动状态时就获取其函数名，效果会更好，因为这样 Lua 就可以查看调用该函数的代码，以找到其名字。

现在我们定义出钩子函数。他的任务是获取被调用的函数、递增相应的计数器并收集函数名字。代码位于图 25.2：“用于统计调用次数的钩子”。

<a name="f-25.2"></a>**图 25.2，用于统计调用次数的钩子**


```lua
{{#include ../scripts/reflection/profiler.lua:4:13}}
```

下一步是使用该钩子运行程序。我们假设打算分析的程序在某个文件中，用户将该文件名作为参数，提供给这个分析器，就像这样：


```console
> lua profiler.lua main-prog
```

在这种方案下，分析器可以获取 `arg[1]` 中的文件名，打开钩子并运行该文件:

```lua
{{#include ../scripts/profiler.lua:15:18}}
```

最后一步是显示结果。图 25.3 “获取函数名称” 中的函数 `getname`，会产生某个函数的名字。

<a name="f-25.3"></a> **图 25.3，获取函数名字**

```lua
{{#include ../scripts/profiler.lua:20:32}}
```

由于 Lua 中函数的名字非常不确定，因此我们给各个函数添加了位置，以 `file:line` 对的形式给出。若某个函数没有名字，我们就只使用其位置。对于 C 函数，我们只使用其名字（因为他没有位置）。该定义之后，我们就要打印各个函数及其计数器：

```lua
{{#include ../scripts/profiler.lua:34:}}
```

若咱们将咱们的分析器，应用到 [第 19 章 “插曲：马可夫链算法“](markov_chain_algorithm.md) 中开发的 Markov 示例，咱们会得到如下结果：


```console
$ lua reflection/profiler.lua markov.lua
Biden administration has received stark warnings from American diplomats of growing fury against US in Arab world have made clear their deep anger at the humanitarian crisis in the Arab
[./markov_chain.lua]: 18 (allwords)     1
require 1
nil     1
sethook 1
[./markov_chain.lua]: 3 (prefix)        729
write   31
random  30
[./markov_chain.lua]: 9 (insert)        699
[./markov_chain.lua]: 21 (for iterator) 699
read    38
[markov.lua]: 0 1
match   735
[./markov_chain.lua]: 0 1
input   1
nil     1
```

这一结果意味着，定义在 `markov_chain.lua` 中第 21 行的匿名函数（即 `allwords` 内部定义的迭代器函数）被调用了 699 次，`write` (`io.write`) 被调用了 31 次，以此类推。


> *附*：`markov_chain.lua` 源码：


```lua
{{#include ../scripts/markov_chain.lua}}
```

我们还可以对这个分析器进行数项改进，例如对输出进行排序、打印出更好的函数名字，以及美化输出格式等。不过，这个基本的分析器已经非常有用了。


## 沙箱化

**Sandboxing**


在 [“`_ENV` 与 `load` ”](env.md#_env-与-load) 小节中，我们曾看到使用 `load` 特性，在受限环境中运行某个 Lua 片段是多么容易。由于 Lua 与外部世界的所有通信，都是通过库函数完成的，因此一旦我们移除这些函数，也就消除了脚本对外部世界产生任何影响的可能性。不过，在脚本浪费大量 CPU 时间或内存下，我们仍然容易受到拒绝服务，denial of service，DoS 的攻击。调试钩子形式下的反射，为遏制此类攻击提供了一种有趣方法。


第一步是使用计数钩子，限制某个代码块可以执行的指令数量。图 25.4 “使用钩子的简单沙箱”，展示了一个在这种沙箱中运行给定文件的程序。

<a name="f-25.4"></a> **图 25.4，使用钩子的简单沙箱**

```lua
{{#include ../scripts/reflection/naive_sandbox.lua}}
```

程序加载给定文件，设置钩子，然后运行该文件。程序将钩子设置为计数钩子，这样 Lua 就会每 100 个指令调用一次钩子。钩子（函数`step`）只是递增一个计数器，并将其与一个固定限制进行比较。可能会出什么问题呢？

当然，我们必须限制所加载代码块大小：只要加载一个巨大块，就会在加载时耗尽内存。另一个问题是，正如下面这个片段所示，程序可以用少得惊人的指令，消耗大量内存：

```lua
local s = "123456789012345"
for i = 1, 36 do s = s .. s end
```

在不到 150 条指令下，这个小片段就将尝试创建一个 1 TB 的字符串。显然，仅限制步骤和程序大小是不够的。

如图 25.5 “控制内存使用” 所示，一种改进方法是，在 `step` 函数中，检查并限制内存使用。


<a name="f-25.5"></a> **控制内存使用**
```lua
{{#include ../scripts/reflection/improved_sandbox.lua:3:22}}

-- 如前
```


由于在如此少的指令下，内存就能快速增长，我们应该设置一个非常低的限制，或者以小的步骤调用钩子。更具体地说，某个程序可以在 40 条指令内，将某个字符串的大小增加一千倍。因此，我们要么以比每 40 步更高的频率调用钩子，要么将内存限制设为我们真正能承受的千分之一。我（作者）可能会两者兼顾。

更微妙的问题便是 Lua 的字符串库。我们可在某个字符串上，以方法方式调用这个库中的任何函数。因此，即使这些函数不在环境中，我们也可以调用他们；字面的字符串会将他们，偷偷地带入我们的沙箱。字符串库中的任何函数，都不会影响外部世界，但他们会绕过我们的步骤计数器。（对 C 函数的一次调用，会算作 Lua 中的一条指令。）字符串库中的某些函数，可能是非常危险的 DoS 攻击。例如，在一个步骤中调用 `(“x”):rep(2^30)` 一次，就会吞噬 1 GB 的内存。再举个例子，在我（作者）的新机器上，运行下面的调用 Lua 5.2 需要 13 分钟：


```lua
s = "01234567890123456789012345678901234567890123456789"
s:find(".*.*.*.*.*.*.*.*.*x")
```


限制对字符串库访问的一种有趣方法，是使用调用钩子。每次调用某个函数时，我们都会检查该函数是否经过授权。下图 25.6 “使用钩子禁止对未授权函数的调用”，实现了这一想法。


<a name="f-25.6"></a> **使用钩子禁止对未授权函数的调用**

```lua
{{#include ../scripts/reflection/demo_call_hook.lua}}
```


在该代码中，表 `validfunc` 表示程序可以调用函数的集合。其中函数 `hook` 使用了 `debug` 库访问正被调用的函数，然后检查该函数是否在 `validfunc` 集合中。


