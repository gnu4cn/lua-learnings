# 水到渠成

**Filling some Gaps**


在前面的示例中，我们已经使用了 Lua 的大部分语法结构，但很容易遗漏一些细节。为了完整起见，本章将在本书第一部分的结尾，介绍更多有关这些语法结构的细节。


## 本地（局部）变量与代码块


默认情况下，Lua 中的变量是全局变量。所有局部变量，都必须被声明。与全局变量不同，局部变量的作用域，仅限于声明他的代码块。所谓 *代码块，block*，是指控制结构的主体，the body of a control structure、函数的主体，the body of a function或块，a chunk（声明变量的文件或字符串）：


```lua
x = 10
local i = 1         -- 相对这个块，chunk，是本地的

while i <= x do
    local x = i * 2 -- 相对于这个 while 主体，是本地的
    print(x)
    i = i + 1
end


if i > 20 then
    local x         -- 相对于 then 这个主体，是本地的
    x = 20
    print(x + 2)    -- （在 if 测试成功时，应打印出 22）
else
    print(x)        -- 10（全局的那个）
end

print(x)            -- 10（全局的那个）
```


请注意，如果咱们以交互模式输入，最后一个示例将无法按预期工作。在交互模式下，每一行本身就是一个块（除非他不是一个完整的命令）。一旦咱们输入示例的第二行（`local i = 1`），Lua 就会运行他，并在下一行中开始一个新块。到那时，`local` 的声明已经超出了范围。为了解决这个问题，我们可以显式地分隔整个块，以关键字 `do-end` 将其括起来。一旦你输入了 `do`，命令只会在相应 `end` 处完成，故而 Lua 不会自己执行每一行。


当我们需要更精细地控制，某些局部变量的作用域时，这些 `do` 块也很有用：


```lua
local x1, x2
do
    local a2 = 2*a
    local d = (b^2 - 4*a*c)^(1/2)

    x1 = (-b + d)/a2
    x2 = (-b - d)/a2
end                         -- 'a2' 与 'd' 的作用域在这里结束

print(x1, x2)               -- 'x1' 与 `x2` 仍在作用域中
```


尽可能使用局部变量，是一种良好的编程风格。局部变量以非必要的名字，避免了搞乱全局变量；他们还可以避免程序不同部分之间的名字冲突。此外，访问局部变量比访问全局变量更快。最后，一旦局部变量的作用域结束，他就会消失，从而允许垃圾回收器释放出他的值。


鉴于局部变量比全局变量“更好”，有人认为 Lua 应该默认使用局部变量。然而，默认使用局部变量，也有其自身的问题（例如，访问非局部变量的问题）。更好的方法，是不使用默认值，也就是说，所有变量都应在使用前声明。Lua 发行版自带了一个用于全局变量检查的模块 `strict.lua`；如果我们在某个函数中，试图给某个不存在的全局变量赋值，或者使用某个不存在的全局变量，他就会抛出错误。在开发 Lua 代码时，使用 `strict.lua` 这个全局变量检查模块，是个好习惯。


每个局部声明，都可以包含一个初始的赋值，其工作方式与传统的多重赋值相同：多余的值会被丢弃，多余的变量会得到 `nil`。如果某个声明没有初始赋值，那么他的所有变量，都将被初始化为 `nil`：


```lua
local a, b = 1, 10
if a < b then
    print(a)    --> 1
    local a     -- 这里 '= nil' 是隐式的
    print(a)    -- nil
end
print(a, b)     --> 1   10
```


Lua 中一个常见的习惯用法是：

```lua
local foo = foo
```

此代码会创建出局部变量 `foo`，并用全局变量 `foo` 的值，对其进行初始化。（局部变量 `foo` 只有在声明 *后* 才可见。）对于加快对 foo 的访问速度，此习惯用法很有用。在即使后来其他函数，改变了全局变量 `foo` 的值，而仍要保修 `foo` 的原始值时，这种方法也很有用；特别是，他能使代码免受猴子修补，monkey patching，<sup>注 3</sup>的影响。任何以 `local print = print` 开头的代码，都将使用原始函数 `print`，即使 `print` 被猴子修补成了其他东西。

> **注 3**：关于 “猴子修补”，参见 [Wikipedia: Monkey patch](https://en.wikipedia.org/wiki/Monkey_patch)。


一些人认为，在代码块中间使用声明，是一种不好的做法。恰恰相反：通过只有在需要时才声明变量，我们就很少需要在没有初始值的情况下，声明变量（因此我们也很少会忘记初始化变量）。此外，我们还缩短了变量的作用域，从而提高了可读性。


## 控制结构


Lua 提供了一小套常规的控制结构，其中 `if` 用于条件执行，而 `while`、`repeat` 和 `for`，用于迭代。所有控制结构的语法，都有明确的终止符：`end` 终止 `if`、`for` 和 `while` 结构；`until` 终止 `repeat` 结构。


控制结构的条件表达式，可以产生任何值。请记住，Lua 将不同于 `false` 和 `nil` 的所有值，都视为 `true`。(特别是，Lua 将 `0` 和空字符串，都视为 `true`。）


### `if-then-else`

`if` 语句会测试其条件，并相应地执行 *`then` 部分，`then`-part* 或 *`else` 部分，`else`-part*。`else` 部分是可选的。

```lua
if a < 0 then a = 0 end

if a < b then return a else return b end

if line > MAXLINES then
    showpage()
    line = 0
end
```

要编写嵌套的 `if`，我们可以使用 `elseif`。他类似于一个 `else` 后面跟一个 `if`，但避免了多个 `end` 的需要：


```lua
if op == "+" then
    r = a + b
elseif op == "-" then
    r = a - b
elseif op == "*" then
    r = a*b
elseif op == "/" then
    r = a/b
else
    error("invalid operation")
end
```

由于 Lua 没有 `switch` 语句，所以这种链条会比较常见。


### `while`


顾名思义，`while` 循环，会在条件为真的情况下，重复其循环体，its body。通常，Lua 会首先测试 `while` 条件；如果条件为假，则循环结束；否则，Lua 会执行循环体，并重复循环过程。


```lua
local i = 1
while a[i] do
    print(a[i])
    i = i + 1
end
```

### `repeat-util`


顾名思义，`repeat-until` 语句，会重复执行其主体，its body，直到条件为真。该语句是在循环体之后，进行测试，因此总是会至少执行一次循环体。


```lua
-- 打印出首个非空的输入行
local line

repeat
    line = io.read()
until line ~= ""

print(line)
```


与大多数其他语言不同，在 Lua 中，循环内声明的局部变量的作用域，会将条件包含起来：


```lua
-- 使用 Newton-Raphson 方法，计算 'x' 的平方根
function NR_sqrt (x)
    local sqrt = x / 2

    repeat
        sqrt = (sqrt + x/sqrt) / 2
        local error = math.abs(sqrt^2 - x)
    until error < x/10000       -- 循环体中的本地 'error' 变量，在这里仍然可见

    return sqrt
end
```


### 数值的 `for`

**Numerical `for`**


`for` 语句有两个变体：*数值的，numerical* `for` 和 *通用的，generic* `for`。


数值的 `for`，有着以下语法：


```lua
for var = exp1, exp2, exp3 do
    something
end
```

此循环将对 `var`，从 `exp1` 到 `exp2` 的每个值执行 `something`，将 `exp3` 用作递增 `var` 的 *步长，step*。其中第三个表达式是可选的；在没有第三个表达式时，Lua 将假定步长为 `1`。如果咱们想要一个没有上限的循环，可以使用常量 `math.huge`：


```lua
for i = 1, math.huge do
    if (0.3*i^3 - 20*i^2 - 500 >=0) then
        print(i)
        break
    end
end
```


`for` 循环有一些微妙之处，要很好地利用他，咱们就应掌握这些微妙之处。首先，在循环开始之前，所有三个表达式都要求值一次。其次，那个控制变量，是 `for` 语句自动声明的一个局部变量，只在循环内部才可见。典型的错误，便是假定了该变量，在循环结束后仍然存在：


```lua
for i = 1, 10 do print(i) end
max = i         -- 可能就是错的了！

print(max)      -- 这里将打印出 nil
```

在循环结束后（通常是在中断循环时），如果咱们需要那个控制变量的值，则必须将其，保存到另一变量中：


```lua
-- 找到列表中的某个值
a = {0, 1, 3, 5, 7, -1, 9, -13}

local found = nil
for i = 1, #a do
    if a[i] < 0 then
        found = i   -- 保存 'i' 的值
        break
    end
end

print(found, a[found])
```

第三，咱们不应修改控制变量的值：这种修改的效果，是不可预测的。咱们如果想在 `for` 循环正常结束之前，结束他，可以使用 `break`（就像我们在上一示例中所做的那样）。



### 通用的 `for`


通用的 `for` 循环，会遍历某个迭代器函数所返回的值。我们已经看到过迭代器的一些例子，如 `pairs`、`ipairs`、`io.lines` 等。尽管表面上看似简单，但通用 `for` 功能强大。有了适当的迭代器，以可读方式，咱们几乎可以遍历任何东西。


当然，我们也可以编写自己的迭代器。虽然通用 `for` 的使用很简单，但编写迭代器函数，也有其微妙之处；因此，我们将在稍后的第 18 章 [*迭代器和通用 `for`*](iterators_and_the_generic_for.md) 中，介绍这一主题。


与数值的 `for` 不同，通用的 `for` 可以有多个变量，每次迭代都会更新所有变量。循环会在第一个变量为 `nil` 时停止，the loop stops when the first variable gets `nil`。与数值循环一样，这些循环变量，是循环体的局部变量，咱们不应在每次迭代中，更改他们的值。


### `break`、`return` 与 `goto`


通过 `break` 和 `return` 语句，我们可以跳出某个代码块。而通过 `goto` 语句，我们几乎可以跳转到，函数中的任何位置。


我们使用 `break` 语句，来结束某个循环。该语句会中断包含着他的内部循环，the inner loop（`for`、`repeat` 或 `while`），其不能在循环外部使用。在中断后，程序将从被中断的循环之后，紧接着的点，继续运行。


`return` 语句会返回函数的结果，或者简单地结束该函数。任何函数的结尾，都有一个隐式的返回语句，因此我们不需要为自然结束的函数，编写返回语句，因为这些函数不会返回任何值。


由于语法上的原因，`return` 只能作为代码块的最后一条语句出现：换句话说，只能作为代码块的最后一条语句，或者在 `end`、`else` 或 `until` 之前。例如，在下一示例中，`return` 便是其中 `then` 代码块的最后一条语句：


```lua
local i = 1
while a[i] do
    if a[i] == v then return i end
    i = i + 1
end
```


通常，我们会在这些地方，使用 `return`，因为 `return` 后面所跟的任何语句，都是无法执行的。但有时，在代码块中间，写一个 `return`，可能会很有用；例如，我们可能正在调试某个函数，并希望避免执行他。在这种情况下，我们可以在语句周围，使用一个显式 `do-end` 代码块：


```lua
function foo ()
    return              --<< 语法错误
    -- 'return' 是下一代码块中的最后一个语句
    do return end       -- 没有问题
    other statements
end
```


`goto` 语句会将程序的执行，跳转到某个相应的标签。关于 `goto` 语句的争论，由来已久，有些人甚至认为他对编程有害，应禁止在编程语言中使用。尽管如此，目前仍有几种语言，提供了 `goto`，这是有充分理由的。在小心使用时，他们是一种强大的机制，只会提高代码的质量。


在 Lua 中，`goto` 语句的语法非常传统：就是后面跟着标签名字的保留字 `goto`，标签名字可以是任何有效的标识符。而标签的语法，则比较复杂：其有着后面跟了标签名称的两个冒号，而标签名字后面，还有两个冒号，如 `::name::`。这种复杂的语法是有意为之，目的是突出程序中的标签。


对于咱们能使用 goto 跳转的位置，Lua 有一些限制。首先，标签遵循了一般的可见性规则，the usual visibility rules，因此，我们不能跳转到代码块中，cannot jump into a block，（因为代码块中的标签，在代码块外是不可见的）。其次，我们不能跳出函数。(注意，第一条规则，就已经排除了，跳入函数的可能性。）第三，我们不能跳入某个局部变量的作用域，the scope of a local variable。


典型的、表现良好的 `goto` 用法，便是模拟一些咱们在其他语言中了解到的，却在 Lua 中没有的结构，例如 `continue`、多级中断，multi-level `break`、多级继续，multi-level `continue`、重做，redo、局部错误处理，local error handling 等。所谓 `continue` 语句，简单地说就是，跳转到循环代码块末尾的标签；而 `redo` 语句，则是跳转到循环代码块的起始位置：


```lua
while some_condition do
    ::redo::

    if some_other_condition then goto continue
    else if yet_another_condition then goto redo
    end

    some code

    ::continue::
end
```


Lua 规范中，有个有用的细节，即局部变量的作用域，会定义出该变量的代码块的，最后一条 *非空* 语句处结束，ends on the last *non-void* statement；而标签，就被视为空语句，void statements。要了解这一细节的用处，请看下个片段：


```lua
while some_condition do
    if some_other_condition then goto continue end

    local var = something
    some code

    ::continue::
end
```

咱们可能会认为，这个 `goto` 跳转到了变量 `var` 的作用域内。但是， `continue` 标是出现在这个代码块的最后一个非空语句之后的，因此他不在 `var` 的作用域内。


`goto` 对于编写状态机，state machines，也很有用。例如，下 [图 8.1，“使用 `goto` 的状态机示例”](#f-8.1) 就给出了一个程序，该程序会检查其输入，是否有偶数个零。


<a name="f-8.1">**图 8.1，使用 `goto` 的状态机示例**</a>


```lua
::s1:: do
    local c = io.read(1)
    if c == '0' then goto s2
    elseif c == nil then print'ok'; return
    else goto s1
    end
end

::s2:: do
    local c = io.read(1)
    if c == '0' then goto s1
    elseif c == nil then print'not ok'; return
    else goto s2
    end
end

goto s1
```

虽然有更好的方法，来编写这个特定程序，但如果我们想将有限自动机，a finite automaton，自动转化为 Lua 代码（想想动态代码生成，think about dynamic code generation），这种技巧还是很有用的。


再举一个简单的迷宫游戏，a simple maze game，为例。迷宫中有几个房间，每个房间最多有四个门：北门、南门、东门和西门。每走一步，用户都要输入一个移动方向。如果在这个方向上有一扇门，用户就会进入相应的房间；否则，程序会打印出告警信息。游戏目标，是从初始房间到最终房间。


这个游戏，就是一种典型的状态机，其中的当前房间，就是所谓的状态。用代码块表示各个房间，咱们就可以实现这个迷宫，而用 `goto` 从一个房间，移动到另一个房间。下 [图 8.2 “迷宫游戏”](#f-8.2)，给出了我们如何编写一个，有四个房间的小型迷宫。


<a name="f-8.2">**图 8.2，迷宫游戏**</a>


```lua
goto room1          -- 初始房间

::room1:: do
    local move = io.read()
    if move == "south" then goto room3
    elseif move == "east" then goto room2
    else
        print("Invalid move")
        goto room1
    end
end

::room2:: do
    local move = io.read()
    if move == "south" then goto room4
    elseif move == "west" then goto room1
    else
        print("Invalid move")
        goto room2
    end
end

::room3:: do
    local move = io.read()
    if move == "north" then goto room1
    elseif move == "east" then goto room4
    else
        print("Invalid move")
        goto room3
    end
end

::room4:: do
    print("Congratulations, you won!")
end
```

对于这种简单游戏，咱们可能会发现，其中用表来描述房间和移动的数据驱动程序，a data-driven program，会是更好的设计。不过，如果在每个房间种，游戏都有几种特殊情形，那么这种状态机的设计，就非常合适了。



## 练习

练习 8.1：大多数有着类似 C 语法的语言，都没有提供 `elseif` 结构。为什么相比这些语言，Lua 更需要这种构造？


练习 8.2：请描述四种使用 Lua 语言，编写不带条件循环，an unconditional loop，的不同方法。你更喜欢哪一种？


练习 8.3：许多人认为，`repeat-until` 很少使用，因此不应该出现在像 Lua 这样的简约语言中。你怎么看？


练习 8.4：正如我们在 [“正确的尾部调用”](functions.md#正确的尾部调用) ，一节中所看到的尾部调用，就是变相的 `goto`。利用这一思想，请使用尾部调用，重新实现 [`break`、`return` 和 `goto`](#breakreturn-与-goto) 一节中，那个简单迷宫游戏。每个代码块都应成为一个新函数，而每个 `goto` 都应成为尾部调用。


练习 8.5：你能解释为什么 Lua 有 `goto` 不能跳出函数的限制吗？(提示：咱们应如何实现这一功能？）


练习 8.6：假设 `goto` 可以跳出函数，请解释下 [图 8.3 “`goto` 的一种奇怪（无效）用法”](#f-8.3) 中的程序会做什么。


<a name="f-8.3">**图 8.3，`goto` 的一种奇怪（无效）使用**</a>

```lua
function getlabel ()
    return function () goto L1 end
    ::L1::
    return 0
end

function f (n)
    if n == 0 then return getlabel()
    else
        local res = f(n - 1)
        print(n)
        return res
    end
end

x = f(10)
x()
```

(要尝试使用局部变量用到同一作用域规则，the same scoping rules used for local variables，对标签进行推理。）
