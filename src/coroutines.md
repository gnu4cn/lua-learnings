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
