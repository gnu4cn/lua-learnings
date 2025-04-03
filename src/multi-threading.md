# 插曲：使用协程的多线程

在这个插曲中，我们将看到一个基于协程的多线程系统实现。


正如我们早先所看到的，协程允许一种协作式的多线程。每个协程就相当于一个线程。一对 `yield-resume` 就可以将控制权，从一个线程切换到另一线程。然而，与常规多线程不同的是，协程是非抢占式的，coroutines are non preemptive。当某个协程在运行时，我们无法从外部停止他。只有通过一次 `yield` 调用明确要求他暂停执行时，他才会暂停执行。对于一些应用来说，这不是个问题，恰恰相反（是个优势）。在没有抢占的情况下，编程要容易得多。我们不必过分担心同步错误（译注：数据竞争，data race？），因为程序中所有线程间的同步都是显式的。我们只需确保例程只会在临界区域外才产生结果，we just need to ensure that a coroutine yields only when it is outside a critical region。

然而，在非抢占式多线程下，每当有线程调用了某个阻塞操作时，整个程序都会阻塞，直到该操作完成。对于许多应用来说，这种行为是不可接受的，这导致许多程序员不把协程视为传统多线程的真正替代方案。我们将在这里看到，这个问题有种有趣（事后看来也很明显）的解决方案。


我们来假设一种典型的多线程情况：我们打算经由 HTTP 下载多个远程文件。要下载多个远程文件，首先我们必须了解如何下载一个远程文件。在这个示例中，我们将使用 LuaSocket 库。要下载某个文件，我们必须打开一个到其站点的连接，发送一个到该文件请求，接收文件（以块为单位），然后关闭连接。在 Lua 中，我们可以如下编写这个任务。首先，我们加载这个 LuaSocket 库：


```lua
local socket = require "socket"
```

然后，我们定义出主机与要下载的文件。在本例中，我们将从 Lua 网站下载 Lua 5.3 手册：


```lua
host = "www.lua.org"
file = "/manual/5.3/manual.html"
```

然后，我们打开到该站点 80 端口（HTTP 连接的标准端口）的 TCP 连接：

```lua
c = assert(socket.connect(host, 80))
```

此操作会返回一个连接对象，我们使用他发送文件请求：


```lua
local request = string.format(
    "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n", file, host)
c:send(request)
```


接下来，我们以 1 kB 的块读取该文件，同时将每个块写入标准输出：


```lua
repeat
    local s, status, partial = c:receive(2^10)
    io.write(s or partial)
until status == "closed"
```

方法 `receive` 会返回一个带有其所读取内容的字符串，或返回在出错时的 `nil`；在后一种情况下，他还会返回一个错误代码（`status`），及出错前读取到的内容（`partial`）。当主机关闭连接时，我们会把剩余输入打印出来，并中断这个接收循环。

> 参考: [TCP](https://w3.impa.br/~diego/software/luasocket/tcp.html#receive)


下载了这个文件后，我们就要关闭该连接：


```lua
c:close()
```

既然我们知道了怎样下载一个文件，那么让我们回到下载多个文件的问题。最简单的方法是一次下载一个文件。然而，这种顺序方法，即在完成前一个文件后才开始读取某个文件，速度太慢。在读取某个远端文件时，程序将其大部分时间花在等待数据的到来。更具体地说，程序的大部分时间阻塞于到 `receive` 的调用中。因此，若该程序能并发地下载所有文件，那么他的运行速度就会快得多。这时，当某个连接没有可用数据时，程序可以从另一连接读取数据。显然，协程为组织这些并发下载，提供了一种方便的方法。我们要为每个下载任务创建出一个新线程。当某个线程没有可用数据时，他会将控制权交给一个简单的调度程序，该调度程序会调用另一线程，when a thread has no data available, it yields control to a simple dispatcher, which invokes another thread。


要以协程重写该程序，我们首先要将之前的下载代码，重写为一个函数。结果如图 26.1 所示：“下载 web 页面的函数”。


<a name="f-26.1"></a> **图 26.1，下载 web 页面的函数**


```lua
function download (host, file)
    local c = assert(socket.connect(host, 80))
    local count = 0 -- counts number of bytes read

    local request = string.format(
        "GET %s HTTP/1.0\r\nhost: %s\r\n\r\n", file, host)
    c:send(request)

    while true do
        local s, status = receive(c)
        count = count + #s
        if status == "closed" then break end
    end

    c:close()
    print(file, count)
end
```

> **译注**：由于 `www.lua.org` 以使用 HTTPS，运行上述代码会得到 `301 moved permanently` 响应代码。因此需修改代码为下面这样：

```lua
{{#include ../scripts/multi-threading/demo_multithreading.lua}}
```

> 参考：
>
> - [HTTPS/SSL calls with Lua and LuaSec](https://notebook.kulchenko.com/programming/https-ssl-calls-with-lua-and-luasec)
>
> - [Lua https timeout is not working](https://stackoverflow.com/questions/20193454/lua-https-timeout-is-not-working)
>
> - [`lua-http`](https://daurnimator.github.io/lua-http/0.4/#stream)
>
> - [How to check a socket is closed or not in luasocket library?](https://stackoverflow.com/a/16074095/12288760)


由于我们对远端文件内容不感兴趣，因此该函数会计算并打印出文件大小，而不是将该文件写到标准输出。(在多个线程读取多个文件的情况下，输出打乱所有文件。）

在这一新代码中，我们使用了个辅助函数（`receive`），从连接接收数据。在顺序方式下，其代码将如下：


```lua
function receive (connection)
    local s, status, partial = connection:receive(2^10)
    return s or partial, status
end
```


而对于并发的实现，该函数必须在无阻塞下接收数据。与顺序执行相反，在没有足够的可用数据时，他就会避让，yield。新的代码如下：


```lua
function receive (connection)
    connection:settimeout(0) -- do not block
    local s, status, partial = connection:receive(2^10)
    if status == "timeout" then
        coroutine.yield(connection)
    end
    return s or partial, status
end
```

调用 `settimeout(0)` 会使连接上的任何操作，都成为非阻塞的操作。当结果状态为 `timeout` 时，表示操作没有完成就返回了。在这种情况下，该线程就会退让。传递给 `yield` 的非假参数，会向调度程序发出信号，表明该线程仍在执行他的任务。请注意，即使在超时的情况下，连接也会返回他在超时前所读取的内容，即变量 `partial` 中的内容。


图 26.2 “调度器” 给出了这个调度程序，和一些辅助代码。


<a name="f-26.2"></a> 图 26.2，调度器


```lua
{{#include ../scripts/multi-threading/dispatcher.lua}}
```

其中表 `tasks` 保存了该调度程序所有存活任务的列表。函数 `get` 确保了每个下载任务都在一个单独线程中运行。该调度程序本身主要是个遍历所有任务，将这些任务逐一恢复的循环。他还必须移除列表中已完成的任务。当没有任务要运行时，他就会停止该循环。

最后，主程序创建其所需的任务，并调用调度器。要从 Lua 网站下载一些发布，主程序可以这样编写：

```lua
{{#include ../scripts/multi-threading/main.lua}}
```


在我（作者）的机器上，顺序的实现需要 15 秒才能下载这些文件。而使用协程的实现，运行速度要快三倍以上。


尽管速度加快了，但后一种实现方式远非最优。当至少有一个线程有数据要读时，一切都很顺利。但是，在一个线程都没有数据要读时，这个调度程序就会忙于等待，在各个线程之间穿梭，只为检查他们是否仍然没有数据。因此，与顺序的解决方案相比，这种协程实现所耗费的 CPU，要多出三个数量级。


为避免这种行为，我们可以使用 LuaSocket 中的 `select` 函数：他允许程序在等待一组套接字的状态变化时阻塞。我们实现中的变化很小：我只需修改这个调度器，如图 26.3 “使用 `select` 的调度器” 所示。


<a name="f-26.3"></a> 图 26.3，使用 `select` 的调度器

```lua
{{#include ../scripts/multi-threading/new_dispatcher.lua:14:38}}
```

在循环过程中，这个新的调度器会将超时的连接收集到 `timedout` 表中。(请记住，`receive` 会将这些连接传递给 `yield`，因此 `resume` 就会返回他们。）如果所有连接都超时，调度器就会调用 `select` 等待这些连接中的任何一个改变状态。在协程下，这个最终实现的运行速度与之前的实现一样快。此外，由于他不会进行繁忙等待，因此 CPU 占用率就与顺序的实现一样高。


## 练习


<a name="exercise-26.1"></a> 练习 26.1，实现并运行本章中介绍的代码。


（End）



