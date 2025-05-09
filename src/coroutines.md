# 协程

**Coroutines**


我们并不经常需要用到协程，但当我们需要的时候，协程就是项无与伦比的特性。明面上协程可以颠覆调用者与被调用者之间的关系，这种灵活性解决了软件架构中，“谁是老大，who-is-the-boss”（或 “谁拥有主循环，who-has-the-main-loop”）问题。这是几个看似不相关问题，如事件驱动程序中的纠缠，entanglement in event-driven programs、生成器构建迭代器，building iterators through generators，以及合作多线程，cooperative multithreading，等的概括。协程以简单高效的方式，解决了所有这些问题。


所谓 *协程，coroutine*，类似于线程（在多线程的意义上）：他是条拥有自己堆栈、自己局部变量，以及自己指令指针的执行线，a line of execution，with its own stack, its own local varialbes, and its own instruction pointer；线程与协程之间的主要区别在于，多线程的程序会并行运行多个线程，而协程程序则是协作式的：在任何给定时间，有着协程的程序，都只运行其协程程序的其中之一，并且只有当这个运行中的协程程序明确要求暂停执行时，他才会暂停执行。


在本章中我们将介绍 Lua 中，协程的工作原理，以及如何使用他们来解决各种问题。



## 协程基础

**Coroutine Basics**


Lua 将所有与协程相关的函数，都打包在表 `coroutine` 中。函数 `create` 可以创建出新协程。他只有一个参数，即包含协程将要运行代码的函数（协程 *体*，the coroutine *body*）。他会返回一个 `thread` 类型的值，代表新的协程。通常，`create` 的参数是个匿名函数，就像这里一样：


```lua
co = coroutine.create(function () print("hi") end)
print(type(co))             --> thread
```


协程可处于四种状态之一：暂停、运行、正常和死亡，suspended, running, normal and dead。我们可以使用函数 `coroutine.status`，检查协程的状态：


```lua
print(coroutine.status(co))     --> suspended
```


当我们创建出某个协程时，他是以暂停状态启动的；当我们创建某个协程时，他不会自动运行其主体。函数 `coroutine.resume` 会（重新）开始执行某个协程，将其状态从暂停状态，变为运行状态：


```lua
coroutine.resume(co)    --> hi
```

(如果在交互模式下运行这段代码，咱们可能需要在上一行结束时加上分号，以消除 `resume` 的结果显示）。在第一个示例中，协程主体简单地打印了 `hi` 并终止，使协程处于死亡状态：


```lua
print(coroutine.status(co))     --> dead
```

到目前为止，协程看上去还不过是调用函数的一种复杂方式。协程的真正威力源自函数 `yield`，他允许运行中的协程暂停自己的执行，以便稍后恢复。我们来看个简单的示例：


```lua
co = coroutine.create(function ()
    for i =1, 10 do
        print("co", i)
        coroutine.yield()
    end
end)
```

现在，协程主体执行一个循环，打印一些数字，并在每次打印后避让，yielding。当我们恢复这个协程时，他会开始其执行，一直运行到第一个 `yield`：


```lua
coroutine.resume(co)    --> co      1
```


如果我们检查其状态，就会发现该协程已暂停，因此，其可被恢复：


```lua
print(coroutine.status(co))     --> suspended
```


从协程角度看，在他暂停时发生的所有活动，都发生在他对 `yield` 的调用中。当我们恢复协程时，对 `yield` 的此次调用最终会返回结果，而协程会继续执行，直到下一 `yield` 或其结束：


```lua
coroutine.resume(co)    --> co      2
coroutine.resume(co)    --> co      3
-- ...
coroutine.resume(co)    --> co      10
coroutine.resume(co)    -- 什么也不会打印
```

在最后一次调用 `resume` 时，协程主体完成了循环并随后返回，没有打印任何内容。如果我们再次尝试恢复，`resume` 会返回 `false` 以及一条错误信息：

```lua
print(coroutine.resume(co))
  --> false   cannot resume dead coroutine
```


请注意，与 `pcall` 一样，`resume` 也是在受保护模式下运行的。因此，如果在某个协程内出现任何错误，Lua 不会显示错误信息，而是将其返回给 `resume` 调用。

当某个协程恢复了另一协程时，他就未被中止；毕竟，我们无法恢复他。不过，他也不是在运行状态，因为正在运行的协程是另一个协程。因此，其自身的状态，就是我们所说的 *正常* 状态。

在 Lua 中，一项有用功能，就是一对恢复-退让， a pair resume-yield，可以交换数据。其中第一个 `resume` 没有对应的 `yield` 在等待，他会将额外参数，传递给协程的主函数：


```lua
co = coroutine.create(function (a, b, c)
        print("co", a, b, c + 2)
    end)
coroutine.resume(co, 1, 2, 3)   --> co      1       2       5
```

调用 `coroutine.resume` 时，会返回传递给相应 `yield`，没有错误的 `true` 信号后的所有参数：


```lua
co = coroutine.create(function (a, b)
        coroutine.yield(a + b, a - b)
end)
print(coroutine.resume(co, 20, 10))     --> true    30      10
```

与此对应，`coroutine.yield` 会返回传递给相应 `resume` 的任何额外参数：


```lua
co = coroutine.create (function (x)
    print("co1", x)
    print("co2", coroutine.yield())
end)
coroutine.resume(co, "hi")      --> co1     hi
coroutine.resume(co, 4, 5)      --> co2     4       5
```

最后，当某个协程结束时，其主函数返回的任何值，都会进入相应的 `resume`：

```lua
co = coroutine.create(function ()
    return 6, 7
end)
print(coroutine.resume(co))     --> true    6       7
```

我们很少在同一个协程中，使用所有这些设施，但他们都有各自用途。


尽管人们对协程的总体概念已经有了很好理解，但细节却大相径庭。因此，对于那些已经对协程有所了解的人来说，在我们继续讨论之前，有必要澄清一下这些细节。Lua 提供了我们所说的 *非对称协程，asymmetric coroutines*。这意味着他有个用于暂停执行某个协程的函数，以及另一个用于恢复暂停协程的函数。其他一些语言，则提供的是 *对称协程，symmetric coroutine*，即只有一个可以将控制权从一个协程，转移到另一协程的函数。

一些人把非对称协程，称为 *半协程，semi-coroutine*。不过，也有人用 *半协程，semi-coroutine* 来表示协程的一种受限实现，即只有在不调用任何函数时，也就是在控制栈中没有待处理调用时，协程才能暂停执行。换句话说，只有这种半协程的主体，才能产生避让，yield。(Python 中的 *生成器，generator*，就是半协程这种含义的一个例子。）


与对称和非对协程之间的区别不同，协程和生成器（如 Python 中所示）之间的区别是很深的；生成器根本不够强大，无法实现我们用完整协程，可以编写的一些最有趣结构。Lua 提供了完整的非对称协程。喜欢对称协程的人，可以在 Lua 的非对称性设施上实现他们（参见 [练习 24.6](#exercise-24_6)）。


## 谁是老大？

**Who Is the Boss?**


生产者-消费者问题，the producer-consumer problem，是协程最典型的例子之一。假设我们有个不断产生数值的函数（例如从文件中读取数值），和另一个不断消耗这些数值的函数（例如将数值写入另一文件）。这两个函数可以是这样的：


```lua
function producer ()
    while true do
        local x = io.read()     -- 产生新值
        send(x)                 -- 将其发送给消费者
    end
end

function consumer ()
    while true do
        local x = receive()     -- 从生产者接收值
        io.write(x, "\n")       -- 消费该值
    end
end
```

(为简化这个例子，生产者和消费者都将永远运行。将二者改为在没有更多数据需要处理时停止运行并不难。）这里的问题，是如何匹配 `send` 和 `receive`。这是个 “谁拥有主循环” 问题的典型例子。生产者和消费者都是活动的，都有各自的主循环，并且都假定对方是个可调用服务。在这个特殊例子中，改变其中一个函数的结构是很容易的，可以取消其循环，使其成为一个被动代理，a passive agent。然而，在其他一些真实场景中，这种结构的改变，可能远非如此简单。


例程提供了一种在不改变结构的情况下，匹配生产者和消费者的理想工具，因为恢复-避让对，a resume-yield pair，颠覆了调用者和被调用者之间的典型关系。当某个协程调用 `yield` 时，他并不会进入某个新函数；相反，他会返回一个待处理调用（`resume`）。同样，对 `resume` 的调用也不会启动某个新函数，而是返回一个对 `yield` 的调用。这一特性正是我们所需要的，他可以匹配一次 `send` 和 一次 `receive`，使每个函数都好像是主函数，另一个函数是从函数。（这就是为什么我称之为“谁是老板”问题。）如此一来，`receive` 会恢复出生产者，以产生出一个新值；而 `send` 则将新值发送回给消费者：


```lua
function receive ()
    local status, value = coroutine.resume(producer)
    return value
end

function send (x)
    coroutine.yield(x)
end
```


当然，生产者现在必须在协程内运行：

```lua
producer = coroutine.create(producer)
```


在这种设计中，程序通过调用消费者开始。当消费者需要某项目时，他会恢复生产者运行，直到生产者有个项目要给消费者，然后停止运行，直到消费者再次重新开始运行。因此，我们称之为 *消费者驱动，consumer-driven* 设计。另一种编写该程序的方法，是运用 *生产者驱动，producer-driven* 设计，其中消费者便是那个协程。虽然细节看起来相反，但两种设计的总体思路是一致的。


使用过滤器，我们就可以扩展这种设计，过滤器是位处生产者和消费者之间，对数据进行某种转换的一些任务。*过滤器，a filter* 同时既是消费者又是生产者，因此会恢复生产者以获取新值，并将转换后的值提供给消费者。举个简单的例子，我们可以在之前的代码中添加一个过滤器，在每一行的开头插入行号。代码见图 24.1 “带过滤器的生产者-消费者”。

**图 24.1 带过滤器的生产者-消费者**


```lua
function receive (prod)
    local status, value = coroutine.resume(prod)
    return value
end

function send (x)
    coroutine.yield(x)
end

function producer ()
    return coroutine.create(function ()
        while true do
            local x = io.read()     -- 产生新值
            send(x)
        end
    end)
end


function filter (prod)
    return coroutine.create(function ()
        for line = 1, math.huge do
            local x = receive(prod)     -- 获取新值
            x = string.format("%5d %s", line, x)
            send(x)     -- 将其发送给消费者
        end
    end)
end

function consumer (prod)
    while true do
        local x = receive(prod)     -- 获取新值
        io.write(x, "\n")           -- 消费新值
    end
end

consumer(filter(producer()))
```

> 运行上面的程序如下所示。

```console
10
    1 10
test                                                                                                                                 2 test
3.1416
    3 3.1416
20
    4 20
This is a test.
    5 This is a test.

    6
<Ctrl + C> 退出
```

程序最后一行只是创建了其所需的组件，将他们连接起来，然后启动最终消费者。


在看了前面的示例后，若咱们想到了 POSIX 管道，POSIX pipes，那么咱们并不孤单。毕竟，协程是种（非抢占式）多线程，non-preemptive multithreading。在管道下，各个任务在单独的进程中运行；而在协程下，每个任务在单独的协程中运行。在写入器（生产者）和读取器（消费者）之间，管道提供了个缓冲区，a buffer，因此他们的相对速度有一定自由度。在管道下这一点很重要，因为进程间切换的成本很高。而在运用协程时，任务间切换的成本要小得多（大致相当于函数调用），因此写入器和读取器可以齐头并进。


## 作为迭代器的协程

**Coroutines as Iterators**


我们可以把循环迭代器，loop iterators，看作是生产者-消费者模式的一个特殊例子：迭代器产生由循环体消耗的项目。因此，使用协程编写迭代器，似乎很合适。事实上，协程为这项任务提供了强大工具。同样，其主要特点，是能将调用者和被调用者之间的关系，从内部转向外部。有了这一特点，我们就可以不必担心如何在连续调用之间保持状态下，编写出迭代器。

为了说明这种用法，我们来编写一个遍历给定数组的所有排列的迭代器，an iterator to traverse all permutations of a given array。直接编写这样一个迭代器并不容易，但编写一个能生成所有这些排列的递归函数则并不难。这个想法很简单：依次将每个数组元素放在最后一个位置，然后递归生成剩余元素的所有排列。代码见图 24.2 “生成排列的函数”。

**图 24.2 生成排列的函数**


```lua
function permgen (a, n)
    n = n or #a         -- `n` 的默认值为 `a` 的大小
    if n <= 1 then
        printResult(a)
    else
        for i = 1, n do
            
            -- 将第 i 个元素置为最后一个
            a[n], a[i] = a[i], a[n]

            -- 生成全部其他元素的排列
            permgen(a, n - 1)


            -- 恢复第 i 个元素
            a[n], a[i] = a[i], a[n]
        end
    end
end
```

要让其工作起来，我们必须定义一个恰当的 `printResult` 函数，并使用适当参数调用 `permgen`：


```lua
function printResult (a)
    for i = 1, #a do io.write(a[i], " ") end
    io.write("\n")
end

permgen ({1, 2, 3, 4})
    --> 2 3 4 1
    --> 3 2 4 1
    --> 3 4 2 1
    --> ...
    --> 2 1 3 4
    --> 1 2 3 4
```


在生成器准备就绪后，将其转换为迭代器，便是项自动任务。首先，我们将 `printResult` 改为 `yield`：


```lua
function permgen (a, n)
    n = n or #a         -- `n` 的默认值为 `a` 的大小
    if n <= 1 then
        coroutine.yield(a)
    else
        -- 照旧
```

然后，我们定义出一个，将该生成器安排在协程中运行，并创建出迭代器函数的工厂函数。其中的迭代器只需恢复协程，即可生成下一排列：


```lua
function permutations (a)
    local co = coroutine.create(function () permgen(a) end)
    return function ()      -- 迭代器
        local code, res = coroutine.resume(co)
        return res
    end
end
```

有了这种机制，用 `for` 语句遍历数组的所有排列方式，就变得轻而易举了：

```lua
for p in permutations{"a", "b", "c"} do
    printResult(p)
end
    --> b c a
    --> c b a
    --> c a b
    --> a c b
    --> b a c
    --> a b c
```

函数 `permutations` 用到 Lua 中的一种常见模式，即在函数中将对 `resume` 的调用，与其对应的协程打包在一起。这种模式非常常见，以至于 Lua 为此提供了一个特殊函数：`coroutine.wrap`。与 `create` 类似，`wrap` 也会创建一个新的协程。与 `create` 不同的是，`wrap` 不会返回协程本身；相反，他会返回一个函数，调用该函数后，协程就会恢复。与最初的 `resume` 不同，该函数的第一个结果不是返回错误代码，而是在出错时抛出错误。使用 `wrap`，我们可以如下编写 `permutations`：


```lua
function permutations (a)
    return coroutine.wrap(function () permgen(a) end)
end
```

通常，`coroutine.wrap` 比 `coroutine.create` 更简单好用。他给到我们的，正是我们在协程上所需的：一个恢复协程的函数。然而，他也不那么灵活。我们无法检查使用 `wrap` 创建出的协程状态。此外，我们也无法检查运行时错误。



## 事件驱动的编程

**Event-Driven Programming**


乍一看也许并不明显，但传统的事件驱动型编程所产生的典型纠缠，是 “谁是老大” 问题的另一后果，the typical entanglement created by convientional event-driven programming is another cosequence of the who-is-the-boss problem。

在典型事件驱动平台中，外部实体通过所谓的 *事件循环，event loop*（或 *运行循环，run loop*），向我们的程序生成事件。谁才是这里的老大就明确了，而我们的代码并非老大。我们的程序成了事件循环的仆从，这就使其成为，那些没有任何明显联系的单个事件处理器集合。


为让内容更具体一些，我们假设有个类似 `libuv` 的异步 I/O 库。该库有与我们下面小例子有关的 4 个函数：


```c
lib.runloop();
lib.readline(stream, callback);
lib.writeline(stream, line, callback);
lib.stop();
```

第一个函数运行将要处理传入事件，并调用相关回调的事件循环。典型的事件驱动程序，会初始化一些东西，然后调用这个函数，他将成为应用程序的主循环。第二个函数指示函数库，读取给定数据流中的一行，读取完成后以得到的结果，调用给定的回调函数。第三个函数与第二个函数类似，但用于写一行内容。最后一个函数中断事件循环，通常是为了结束程序。


下图 24.3 “异步 I/O 库的丑陋实现” 展示了这样一个库的一种实现。


```lua
local cmdQueue = {}         -- 待处理操作队列

local lib = {}

function lib.readline (stream, callback)
    local nextCmd = function ()
        callback(stream:read())
    end

    table.insert(cmdQueue, nextCmd)
end

function lib.writeline ()
    local nextCmd = function ()
        callback(stream:write(line))
    end

    table.insert(cmdQueue, nextCmd)
end

function lib.stop ()
    table.insert(cmdQueue, "stop")
end

function lib.runloop ()
    while true do
        local nextCmd = table.remove(cmdQueue, 1)

        if nextCmd == "stop" then
            break
        else
            nextCmd()       -- 执行下一操作
        end
    end
end

return lib
```

这是个非常丑陋的实现。他的 “事件队列”，实际上是个待执行操作的列表，一旦被执行（同步地！），就会产生事件。尽管这很难看，但他还是满足了前面的规范，因此我们可以在不需要真正异步库下，测试下面的一些示例。

现在，我们来使用该库编写个将输入流中的所有行读入一个表，然后按相反顺序写入输出流的简单程序。若使用传统 I/O，程序会是下面这样。


```lua
local t = {}
local inp = io.input()      -- 输入流
local out = io.output()     -- 输出流


for line in inp:lines() do
    t[#t + 1] = line
end

for i = #t, 1, -1 do
    out:write(t[i], "\n")
end
```


> 运行该程序：


```console
This
There
That
Those <Ctrl+D>
Those
That
There
This
```

> 其中 `<Ctrl+D>` 表示输入的结束，参考：[How to signal the end of stdin input](https://unix.stackexchange.com/a/16338/664372)


现在，我们要在异步 I/O 库的基础上，以事件驱动的方式，in an event-driven style，重写该程序，结果如下图 24.4 所示：“以事件驱动方式反转文件”。



**图 24.4 以事件驱动方式反转某个文件**


```lua
local lib = require "async-lib"

local t = {}
local inp = io.input()
local out = io.output()
local i


-- 写-行 处理器
local function putline ()
    i = i - 1
    if i == 0 then
        lib.stop()      -- 没有更多行了？
    else
        lib.writeline(out, t[i] .. "\n", putline)
    end
end

-- 读-行 处理器
local function getline (line)
    if line then                        -- 非 EOF？
        t[#t + 1] = line                -- 保存行
        lib.readline(inp, getline)      -- 读取下一行
    else                                -- 文件结束处
        i = #t + 1                      -- 准备写循环
        putline()                       -- 进入写循环
    end
end

lib.readline(inp, getline)              -- 请求读取首行
lib.runloop()                           -- 运行主循环
```


事件驱动情形下，我们所有循环都消失了，因为主循环在库中。取而代之的是伪装成事件的递归调用。我们可以通过连续传递样式，使用闭包来改善这些情况，但我们仍旧无法编写自己的循环；我们必须通过递归，来重写他们。


协程允许我们将循环与事件循环相协调，reconsile our loops with the event loop。关键思路在于，在每次请求库时，将主代码作为协程运行，把回调函数设置为恢复主代码运行的函数，随后避让。下图 24.5 “在异步库上运行同步代码”，就运用这一思想，实现了个在异步 I/O 库上，运行传统同步代码的库。


<a name="f_24.5"></a>**图 24.5 在异步库上运行同步代码**



```lua
local lib = require "async-lib"

function run (code)
    local co = coroutine.wrap(function ()
        code()
        lib.stop()      -- 在完成后结束事件循环
    end)

    co()                -- 启动协程
    lib.runloop()       -- 启动事件循环
end


function putline (stream, line)
    local co = coroutine.running()      -- 调用协程
    local callback = (function () coroutine.resume(co) end)
    lib.writeline(stream, line, callback)
    coroutine.yield()
end

function getline (stream, line)
    local co = coroutine.running()        -- 调用协程
    local callback = (function (l) coroutine.resume(co, l) end)
    lib.readline(stream, callback)
    local line = coroutine.yield()
    return line
end
```

顾名思义，其中的 `run` 函数会运行其作为参数取得的同步代码。他首先创建出一个用于运行给定代码的协程，并在运行结束后完成事件循环。随后，他恢复了该协程（该协程将在第一次 I/O 调用时避让），然后进入事件循环。


函数 `getline` 和 `putline` 模拟了同步 I/O。如前所述，他们都调用了个适当的异步函数，作为传递的恢复所调用协程的回调函数。（请留意其中使用 `coroutine.running` 函数访问所调用协程的用法。）在此之后，协程就避让了，控制权回到事件循环。一旦操作完成，事件循环就会调用回调，恢复触发操作的协程。


有了这个库，我们就可以在异步库上，运行同步代码了。举例来说，以下代码片段再次实现了我们的翻转行示例：


```lua
run(function ()
    local t = {}
    local inp = io.input()
    local out = io.output()

    while true do
        local line = getline(inp)
        if not line then break end
        t[#t + 1] = line
    end

    for i = #t, 1, -1 do
        putline(out, t[i] .. "\n")
    end
end)
```


> **译注**：与上个程序一样，运行该代码时在输入若干行后按下 `Ctrl+D`，会报出如下错误。


```console
$ lua running_sync_code_on_top_of_async_lib.lua
This
There
That
Those
lua: ./async-lib.lua:15: attempt to index a nil value (global 'stream')
stack traceback:
        ./async-lib.lua:15: in local 'nextCmd'
        ./async-lib.lua:32: in function 'async-lib.runloop'
        running_sync_code_on_top_of_async_lib.lua:10: in function 'run'
        running_sync_code_on_top_of_async_lib.lua:29: in main chunk
        [C]: in ?
```

> 至于为何会这样，以及在异步下如何结束输入，需要进一步探讨。


除开将 `get/putline` 用于 I/O，并一个 `run` 调用内部运行外，该代码与最初的同步代码相同。其同步结构之下，他实际上是以事件驱动的方式运行的，同时与以更典型的事件驱动风格，编写的程序其他部分完全兼容。


## 练习


练习 24.1：请使用 *生产者驱动* 设计，a *producer-driven* design，重写 [“谁是老大” 小节](#谁是老大) 中的生产者-消费者示例，其中消费者为协程，生产者为主线程；


练习 24.2： [练习 6.5](functions.md#exercise_6.5) 曾要求咱们编写个打印出给定数组中，所有元素组合的函数。请使用协程，将此函数转换为一个组合生成器，并可像下面样使用：


```lua
    for c in combinations({"a", "b", "c"}, 2) do
        printResult(c)
    end
```


练习 24.3：在 [图 24.5 “在异步库上运行同步代码”](#f_24.5) 中，函数 `getline` 和 `putline` 在每次调用时，都会创建一个新闭包。请使用记忆法，来避免这种浪费；


练习 24.4： 请为这个基于协程的库，编写个行迭代器（[图 24.5，“在异步库上运行同步代码”](#f_24.5)），以便使用 `for` 循环读取文件；


练习 24.5：咱们可以使用基于协程的库（[图 24.5，“在异步库上运行同步代码”](#f_24.5)），并发运行多个线程吗？需要做些什么改动呢？


练习 24.6：请以 Lua 实现一个 `transfer` 函数。若咱们将恢复-避让，`resume-yield`，视为类似于调用-返回，`call-return`，那么一次转移，就像是个 `goto`：他会暂停运行中的协程，并恢复作为参数给定的其他协程。(提示：请使用某种调度，a kind of dispatch，来控制咱们的协程。然后，某次转移避让于调度，发出指示下一协程运行的信0号，而调度将恢复下一协程运行。use a kind of dispatch to control your coroutines. Then, a transfer would yield to the dispatch signaling the next coroutine to run, and the dispatch would resume that next coroutine.）


（End）


