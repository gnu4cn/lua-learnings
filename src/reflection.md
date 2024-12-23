# 反射

**Reflection**


反射，是指程序检查、修改其自身执行某些方面的能力。动态语言（如 Lua）自然而然支持多种反射特性：

- 环境特性允许了运行时的全局变量检查；
- 函数（如 `type` 和 `pairs`）允许了运行时的未知数据结构检查和遍历；
- 函数（如 `load` 和 `require`）允许了程序为自身添加代码或更新自己的代码。


然而，仍有许多不足之处：程序无法自省其局部变量，程序无法跟踪其执行情况，函数无法获悉其调用者，等等。调试库，the debug library，填补了这些空白。


调试库包含两类函数：*内省函数，introspective functions* 和 *钩子，hooks*。内省函数允许我们检查正在运行程序的多个方面，譬如活动函数堆栈、当前执行行及局部变量的值和名称等。钩子允许我们跟踪程序的执行。


尽管名为调试库，但他并未提供一个 Lua 调试器。不过，他提供了编写我们自己调试器所需的，复杂程度各不相同的全部原语。


与其他库不同，我们应该谨慎使用调试库，use the debug library with parsimony。首先，调试库的某些功能，并不以性能著称。其次，他打破了该门语言的一些神圣真理，比如我们不能从局部变量的词法范围之外，访问该局部变量这一条。虽然调试库与标准库一样直接可用，但我（作者）更倾向于，在任何用到调试库的代码块中，显式地导入他。



## 自省设施

**Introspective Facilities**


调试库中的主要自省函数，是 `getinfo`。其第一个参数可以是某个函数，也可以是某个堆栈层级，a stack level。当我们对函数 `foo` 调用 `debug.getinfo(foo)` 时，他会返回一个包含有关该函数一些数据的表。该表可以包含以下字段：


- `source`：该字段给出函数于何处定义。如果函数是在字符串中定义的（经由一个 `load` 调用），那么 `source` 就是那个字符串。如果函数是在某个文件中定义的，那么 `source` 就是以 `@` 符号为前缀的文件名；

- `short_src`：该字段是 `source` 简短版本（最多 60 个字符）。这对于错误信息非常有用；

- `linedefined`：该字段给出了定义函数的源代码第一行编号；

- `lastlinedefined`：该字段给出了定义函数的源代码最后一行编号；

- `what`：该字段给出了此函数是什么。如果 `foo` 是个常规 Lua 函数，则选项为 `Lua`；如果是个 C 函数，则选项为 `C`；如果是 Lua 代码块的主要部分，则选项为 `main`；

- `name`：该字段给到函数的合理名称，例如存储该函数的全局变量名称；

- `namewhat`：该字段给出前一字段的含义。该字段可以是 `global`、`local`、`method`、`field` 或 ``（空字符串）。空字符串表示 Lua 没有找到函数名称；

- `nups`：这是该函数的上值个数，the number of upvalues；

- `nparams`：这是该函数的参数个数；

- `isvararg`：这表明函数是否为可变参数，whether the function is variadic（一个布尔值）；

- `activelines`：该字段是个表示函数活动行集合的表。所谓 *活动行，active line*，是指有代码的行，而不是空行或仅包含注释的行。(该信息的一个典型用途，是设置断点。大多数调试器不允许我们在活动行之外设置断点，因为这样的断点是无法到达的。）

- `func`：该字段为函数本身。


当 `foo` 是个 C 语言函数时，Lua 就没有太多关于他的数据。对于此类函数，只有 `what`、`name`、`namewhat`、`nups` 和 `func` 字段是有意义的。

当我们对某个数字 `n` 调用 `debug.getinfo(n)` 时，我们会获取到有关活动于该堆栈级别函数的数据，data about the function active at that stack level。所谓 *堆栈级别*，是个表示当时处于活动状态特定函数的数字。调用 `getinfo` 的函数级别为一，调用他的函数级别为二，依此类推。 （在级别零处，我们会获取到有关 `getinfo` 本身（一个 C 函数）的数据。）如果 `n` 大于堆栈上活动函数的数量，则 `debug.getinfo` 返回 `nil`。当我们通过调用带有堆栈级别的 `debug.getinfo` ，查询某个活动函数时，结果表有两个额外的字段：`currentline`，该函数当时所在的行； `istailcall`（布尔值），如果该函数是通过尾调用调用的，则为 `true`。 （在这种情况下，该函数的真正调用者不再在堆栈上。）

`name` 字段很棘手。请记住，由于函数在 Lua 中属于头等值，functions are first-class values in Lua，因此函数可能没有名字，也可能有多个名字。Lua 尝试通过查看调用函数的代码，了解某个函数是如何被调用的，来找到该函数的名字。这种方法只有在我们调用带有数字的 `getinfo` ，即在我们请求有关某个特定调用的信息时，才会起作用。

函数 `getinfo` 并不高效。Lua 以不影响程序执行的形式，保存调试信息；高效检索是次要目标。为获得更好性能，`getinfo` 有个可选的第二参数，用于选择要获取的信息。这样，该函数就不会浪费时间，收集用户不需要的数据。该参数的格式是个字符串，每个字母代表一组字段，如下表所示。

| 选项 | 意义 |
| :-: | :- |
| `n` | 选择 `name` 与 `namewhat` |
| `f` | 选择 `func` |
| `S` | 选择 `source`、`short_src`、`what`、`linedefined` 与 `lastlinedefined` |
| `l` | 选择 `currentline` |
| `L` | 选择 `activelines` |
| `u` | 选择 `nups`、`nparams` 与 `isvararg` |


以下函数通过打印活动堆栈的原始回溯，说明了 `debug.getinfo` 用法：


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

要改进这个函数并不难，只要包含更多 `getinfo` 中的数据即可。实际上，调试库就提供了这样一个改进版本，即函数 `traceback`。与我们的版本不同，`debug.traceback` 并不打印结果，而是返回一个包含回溯信息的字符串（可能很长）：


```console
> print(debug.traceback())
stack traceback:
        stdin:1: in main chunk
        [C]: in ?
```


## 访问本地变量

**Accessing local variables**


使用 `debug.getlocal`，我就就可以检查任何活动函数的局部变量。该函数有两个参数：所查询函数的堆栈级别，以及变量索引。他会返回两个值：变量名与其当前值。如果变量索引大于了活动变量数目，`getlocal` 将返回 `nil`。如果堆栈级别无效，他会抛出一个错误。(我们可以使用 `debug.getinfo`，检查堆栈级别的有效性）。

Lua 按照局部变量在函数中出现的顺序对其编号，只计算那些在函数当前作用域中活动的变量。例如，请看下面的函数：


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



