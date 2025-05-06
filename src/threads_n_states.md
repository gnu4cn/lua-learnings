# 线程与状态

Lua 不支持真正的多线程，即抢占式的线程共享内存。缺乏支持有两个原因。第一个是 ISO C 并不支持多线程，因此 Lua 没有实现这种机制的可移植方法。第二个也是更重要的原因是，我们（Lua 开发团队）不认为多线程对于 Lua 来说是个好主意。


多线程是为底层编程开发的。像信号量及监视器这样的同步机制，synchronization mechanisms like semaphores and monitors，是在操作系统（与经验丰富的程序员），而非应用程序的背景下提出的。发现和纠正与多线程相关的 bug 非常困难，其中一些 bug 可能会导致安全漏洞。此外，多线程会导致与程序的某些关键部分，如内存分配器，需要同步相关的性能下降。


抢占与共享内存二者结合，会造成更多的多线程问题，因此通过使用非抢占线程，及不共享内存，我们可以避免这些问题。Lua 提供了这两种支持。Lua 的线程（也称为协程）是协作式的，因此可避免不可预知线程切换所带来的问题。Lua 状态不共享内存，而因此为 Lua 的并行机制，奠定了良好基础。我们将在本章中介绍这两种选项。


## 多线程


所谓 *线程*，就是 Lua 中协程的本质。我们可将协程当作一个线程，外加一个漂亮的接口，也可以将线程，当作一个带有低级 API 的协程。


从 C API 的角度看，将线程当作堆栈，可能会有所帮助 -- 从实现角度来看，线程实际上就是个栈。每个栈都保存了线程的待处理调用信息，以及每次调用的参数与局部变量。换句话说，栈上包含了线程继续运行所需的所有信息。因此，多个线程意味着多个独立的栈。

Lua 的 C API 中的大多数函数，都在特定栈上运行。Lua 怎样知道要使用哪个栈呢？在调用 `lua_pushnumber` 时，我们如何确定处要将该数字压入和处呢？秘密在于，这些函数的第一个参数 `lua_State` 类型，不仅代表了一个 Lua 状态，还代表了该状态下的一个线程。(很多人认为这种类型应该叫做 `lua_Thread`。也许他们是对的。）


每当我们创建出一个 Lua 状态时，Lua 都会自动创建出一个该状态下的主线程，并返回一个表示该线程的 `lua_State`。这个主线程永远不会被回收。当我们以 `lua_close` 关闭该状态时，其将与这个状态一起被释放。用不到线程的程序，会在该主线程中运行一切。


通过调用 `lua_newthread`，我们可在某状态下创建其他线程：


```c
lua_State *lua_newthread (lua_State *L);
```

该函数会将新线程，作为 `"thread"` 类型的值压入栈上，并返回一个代表该新线程的 `lua_State` 指针。例如，请看下面的语句：


```c
L1 = lua_newthread(L);
```

运行该语句后，我们将有两个线程 `L1` 和 `L`，在内部他们引用了同一个 Lua 状态。每个线程都有自己的栈。新线程 `L1` 以一个空栈开始，而旧线程 `L` 的堆栈顶部，有着到这个新线程的引用：


```c
printf("%d\n", lua_gettop(L1)); --> 0
printf("%s\n", luaL_typename(L, -1)); --> thread
```


除主线程外，别的线程也会像其他 Lua 对象一样被垃圾回收。当我们创建出某个新线程时，压入栈的那个值，会确保该线程不会被回收。我们绝不应使用，未在 Lua 状态中正确锚定的线程。(主线程属于内部锚定的，所以我们不必担心。）对 Lua API 的任何调用，即使是正使用该线程的调用，都可能会回收某个未锚定的线程。例如，请看下面的片段：


```c
    lua_State *L1 = lua_newthread (L);
    lua_pop(L, 1); /* L1 now is garbage for Lua */
    lua_pushstring(L1, "hello");
```


其中对 `lua_pushstring` 的调用，就可能触发垃圾回收器而回收 `L1`，从而导致该应用崩溃，尽管事实上 `L1` 正在使用中。为避免这种情况，请始终保留一个对咱们正在使用线程的引用，例如在某个锚定线程的栈上、在注册表中或某个 Lua 变量中。



一旦咱们有了个新线程，我们就可像使用主线程一样使用他。我们可以向其栈压入与弹出元素，还可以用他调用函数，等等。例如，下面的代码在新线程中调用 `f(5)`，然后将结果移到旧线程中：


```c
    lua_getglobal(L1, "f"); /* assume a global function 'f' */
    lua_pushinteger(L1, 5);
    lua_call(L1, 1, 1);
    lua_xmove(L1, L, 1);
```

> **译注**：这里我们可以使用

```lua
luaL_dostring(L, "function f (a) return a + 5 end");
```

> 通过 `luaL_dostring` 函数临时加载一个 Lua 函数 `f` 进入主线程。

函数 `lua_xmove` 会在处于同一状态下的两个堆栈间移动 Lua 值。像 `lua_xmove(F, T, n)` 这样的调用，会从栈 `F` 上弹出 `n` 个元素，并将他们压入栈 `T` 上。


不过，对于这些用途，我们并不需要一个新线程；我们仍需使用主线程即可。使用多线程的主要目的，是要实现协程，这样我们就可以暂停其执行，并在稍后恢复。为此，我们需要函数 `lua_resume`：


```c
int lua_resume (lua_State *L, lua_State *from, int narg);
```

> **译注**：Lua 5.4 中，该函数原型为：

```c
int lua_resume (lua_State *L, lua_State *from, int nargs,
            int *nresults);
```

要开始运行某个协程，我们可像使用 `lua_pcall` 一样，使用 `lua_resume`：我们将要调用的函数（即协程的主体）压入栈，再压入其参数，然后调用 `lua_resume`，并传入参数个数 `narg`。（其中 `from` 参数是完成该调用的线程，或 `NULL`。）其行为也与 `lua_pcall` 非常相似，但有三点不同。

- 首先，`lua_resume` 没有所想要结果数量的参数；他总是会返回被调用函数的所有结果；
- 其次，`lua_resume` 没有为消息处理程序的参数；出错不会释放栈，因此我们可以在出错后检查栈；an error does not unwind the stack, so we can inspect the stack after the error.
- 第三，如果正在运行的函数，那么 `lua_resume` 会返回代码 `LUA_YIELD`，并让该线程处于稍后可以恢复的状态。


当 `lua_resume` 返回 `LUA_YIELD` 时，该线程栈的可见部分，就只包含传递给 `yield` 的值。一次对 `lua_gettop` 的调用，将返回被避让值的数量，a call to `lua_gettop` will return the nubmer of yielded values。要将这些值迁移到另一线程，我们可以使用 `lua_xmove`。


要恢复某个暂停的线程，我们需要再次调用 `lua_resume`。在这样的调用中，Lua 会假定栈上所有的值，均为将由到 `yield` 的调用所返回的值。例如，若我们在从 `lua_resume` 返回，到下一次恢复之间，没有触碰该线程的栈，那么 `yield` 将准确返回他所产生的值。

> **译注**：这指的是幂等性？idempotency?


通常，我们会以一个 Lua 函数，作为某个协程的主体。这个 Lua 函数可调用其他函数，而这些函数中的任何一个，都可能随时避让，终止对 `lua_resume` 的调用。例如，假设有以下定义：


```lua
function foo (x) coroutine.yield(10, x) end
function foo1 (x) foo(x + 1); return 3 end
```

现在，我们运行下面这段 C 代码：


```c
    lua_State *L1 = lua_newthread(L);
    lua_getglobal(L1, "foo1");
    lua_pushinteger(L1, 20);
    lua_resume(L1, L, 1);
```


> **译注**：在 Lua 5.4 中，应写作如下：

```c
    int nres;

    lua_State *L1 = lua_newthread(L);
    lua_getglobal(L1, "foo1");
    lua_pushinteger(L1, 20);
    lua_resume(L1, L, 1, &nres);
```

> 参考：[New param in lua_resume in Lua 5.4](http://lua-users.org/lists/lua-l/2020-07/msg00120.html)

其中对 `lua_resume` 的调用，将返回 `LUA_YIELD`，表示该线程已避让。此刻，`L1` 栈上的值，就是给到 `yield` 的值：


```c
    printf("%d\n", lua_gettop(L1)); // 2
    printf("%lld\n", lua_tointeger(L1, 1)); // 10
    printf("%lld\n", lua_tointeger(L1, 2)); // 21
```


> **译注**：译者运行得到的结果为：

```c
    printf("%d\n", lua_gettop(L1)); // 7
    printf("%lld\n", lua_tointeger(L1, 1)); // 21
    printf("%lld\n", lua_tointeger(L1, 2)); // 0
```

> 不知何故。


当我们再次恢复该线程时，他会从停止（调用 `yield`）的地方继续运行。从那里，`foo` 会回到 `foo1`，而 `foo1` 又会回到 `lua_resume`：


```c
    lua_resume(L1, L, 0);
    printf("%d\n", lua_gettop(L1)); // 1
    printf("%lld\n", lua_tointeger(L1, 1)); // 3
```


> **译注**：译者运行得到的结果为：

```c
    lua_resume(L1, L, 0, &nres);
    printf("%d\n", lua_gettop(L1)); // 8
    printf("%lld\n", lua_tointeger(L1, 1)); // 21
```


这第二次对 `lua_resume` 的调用，将返回 `LUA_OK`，即一次正常返回。

携程也可调用 C 函数，而 C 函数可以回调其他 Lua 函数。我们已经讨论过如何使用连续性，允许这些 Lua 函数避让（名为 [“连续性”](./calling_c.md#连续性) 的小节）。C 函数也可以避让。在这种情况下，他还必须提供一个延续函数，以便在线程恢复时被调用。C 函数必须调用以下函数才能避让，to yield, a C function must call the following function：


```c
int lua_yieldk (lua_State *L, int nresults, int ctx,
                              lua_CFunction k);
```


我们应始终在返回语句中，使用该函数，例如此处：


```c
static inf myCfunction (lua_State *L) {
    // ...
    return lua_yieldk(L, nresults, ctx, k);
}
```


该调用会立即暂停正在运行的协程。其中的 `nresults` 参数是栈上要返回给相应 `lua_resume` 值的个数；`ctx` 是要传递给继续函数的上下文信息；`k` 是继续函数。当协程恢复运行时，控制权会直接转到继续函数 `k`。在避让后，`myCfunction` 无法做任何其他事情。他必须将任何进一步的工作，委托给其继续函数。


我们来看一个典型的例子。假设我们要编写一个读取一些数据，在数据不可用时避让的函数，a function that reads some data, yielding if the data is not available。我们可以这样以 C 写这个函数：<sup>1</sup>


```c
int readK (lua_State *L, int status, lua_KContext ctx) {
    (void)status; (void)ctx; /* unused parameters */

    if (something_to_read()) {
        lua_pushstring(L, read_some_data());
        return 1;
    }
    else
        return lua_yieldk(L, 0, 0, &readK);
}

int prim_read (lua_State *L) {
    return readK(L, 0, 0);
}
```


> **脚注**：
>
> <sup>1</sup>：正如我（作者）已经提到的，早于 Lua 5.3 前的延续性 API 有些许不同。特别是，连续函数只有一个参数，即 Lua 状态。


在这个示例中，`prim_read` 不需要进行任何初始化，因此他直接调用了那个连续函数 (`readK`)。如果存在要读取的数据，`readK` 会读取并返回这些数据。否则，他就会避让。当线程恢复时，他会再次调用这个继续函数，该函数将再次尝试读取数据。


若某个 C 函数在避让后，没有其他事情要做，那么他可以不带继续函数下调用 `lua_yieldk`，或使用宏 `lua_yield`：


```c
return lua_yield(L, nres);
```

在此调用后，当线程恢复时，控制权会返回到调用 `myCfunction` 的函数。


## Lua 状态


每次到 `luaL_newstate`（或 `lua_newstate`）的调用，都会创建出一个新的 Lua 状态。不同 Lua 状态彼此完全独立。他们完全不共享数据。这意味着无论某个 Lua 状态内部发生了什么，都不会损坏另一 Lua 状态。这也意味着 Lua 状态无法直接通信；我们必须使用一些干预性的 C 代码。例如，给定两个状态 `L1` 和 `L2`，下面的命令会将 `L1` 栈顶层的字符串，压入 `L2`：


```c
lua_pushstring(L2, lua_tostring(L1, -1));
```


由于数据必须通过 C，因此 Lua 状态只能交换那些以 C 表示的类型，如字符串和数字。其他类型（如表）必须要被序列化，才能传输。


在提供了多线程的系统中，一种有趣的设计是为每个线程，创建一个独立的 Lua 状态。这种设计会产生类似于 POSIX 进程的线程，其中我们可在不共享内存下实现并发。在本小节中，我们将按照这种方法，开发一种多线程的原型实现。我将在这种实现中，使用 POSIX 的线程（`pthreads`）。将代码移植到其他线程系统，应并不困难，因为此代码只使用了一些基本设施。


我们要开发的系统非常简单。其主要目的是展示在某种多线程环境下，多个 Lua 状态的使用。在咱们将其启动并运行后，我们可以在其基础上，添加一些高级功能。我们会将咱们的库叫作 `lproc`。他只提供四个函数：


- `lproc.start(chunk)`，会启动一个新进程，运行给定的代码块（一个字符串）。该库会将一个 Lua *进程*，作为一个 C *线程* 及其相关 Lua 状态实现；

- `lproc.send(channel, val1, val2, ...)`，会将所有给定值（应为一些字符串），发送到由名字，也应是个字符串，标识的给定通道；(后面练习，会要求咱们添加发送其他类型的支持。）

- `lproc.receive(channel)`：接收发送到给定通道的值；

- `lproc.exit()`，结束某个进程。只有主进程需要这个函数。若此进程结束时没有调用 `lproc.exit`，整个进程就会结束，而不会等待其他进程的结束。


这个库会通过字符串识别通道，并使用他们匹配发送方和接收方。发送操作可以发送任意数量的字符串值，这些值会由匹配的接收操作返回。所有通信都是同步的：向某个通道发送信息的进程会阻塞，直到有进程从该通道接收信息；而从某个通道接收信息的进程也会阻塞，直到有进程向该通道发送信息。


与其接口一样，`lproc` 的实现也很简单。他会用到两个循环双链列表，一个用于等待发送消息的进程，另一个用于等待接收消息的进程。他使用了单个互斥锁，控制对这些列表的访问。每个进程都有一个相关的条件变量。当某个进程打算向某个通道发送消息时，他会遍历接收列表，寻找等待该通道的进程。在找到时，他就会从该等待列表中移除该进程，将消息值从自身移至所找到的进程，并向其他进程发出信号。否则，他会将自己插入发送列表，并等待其条件变量。而要接收消息，他会执行一次对称操作。


该实现中的一个主要元素，是表示某个进程的结构体：


```c
#include <pthread.h>
#include "lua.h"
#include "lauxlib.h"

typedef struct Proc {
    lua_State *L;
    pthread_t thread;
    pthread_cond_t cond;
    const char *channel;
    struct Proc *previous, *next;
} Proc;
```

其中前两个字段，表示由进程所使用的 Lua 状态，及运行该进程的 C 线程。第三个字段 `cond`，当线程需要等待某此匹配的发送/接收时，用于阻塞自身的条件变量。第四个字段存储进程正在等待的通道，在需要等待时。最后两个字段，`previous` 与 `next`，用于将该进程结构体，链接到等待列表中。


下面的代码声明了两个等待列表，及相关的互斥锁：


```c
static Proc *waitsend = NULL;
static Proc *waitreceive = NULL;

static pthread_mutex_t kernel_access = PTHREAD_MUTEX_INITIALIZER;
```


每个进程都需要个 `Proc` 结构体，每当其脚本调用 `send` 或 `receive` 时，都需要访问该结构体。这些函数接收的唯一参数，便是进程的 Lua 状态；因此，每个进程都应在其 Lua 状态中，存储其 `Proc` 结构体。在我们的实现中，每个状态都将其对应的 `Proc` 结构体，作为完整的用户数据，保存在注册表中，并与键 `"_SELF"` 相关联。辅助函数 `getself` 可获取到与给定状态相关联的 `Proc` 结构体：


```c
static Proc *getself (lua_State *L) {
    Proc *p;

    lua_getfield(L, LUA_REGISTRYINDEX, "_SELF");
    p = (Proc *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    return p;
}
```


下一函数是 `movevalues`，他会将值从某个发送进程，迁移到某个接收进程：


```c
static void movevalues (lua_State *send, lua_State *rec) {
    int n = lua_gettop(send);
    int i;

    luaL_checkstack(rec, n, "too many results");

    for (i = 2; i <= n; i++) /* move values to receiver */
        lua_pushstring(rec, lua_tostring(send, i));
}
```

他会将发送方栈上的所有值，迁移至接收方，但首先将迁移到通道。请注意，由于我们压入的是任意数量的元素，因此咱们必须检查栈空间。


图 33.1 [“检索某个正在等待通道进程的函数”](#f-33.1)，定义了函数可遍历某个列表，寻找正在等待给定通道进程的函数 `searchmatch`。

<a name="f-33.1"></a> **图 33.1，检索某个正在等待通道进程的函数**


```c
static Proc *searchmatch (const char *channel, Proc **list) {
    Proc *node;

    /* traverse the list */
    for (node = *list; node != NULL; node = node->next) {
        if (strcmp(channel, node->channel) == 0) { /* match? */
            /* remove node from the list */
            if (*list == node) /* is this node the first element? */
                *list = (node->next == node) ? NULL : node->next;

            node->previous->next = node->next;
            node->next->previous = node->previous;

            return node;
        }
    }
    return NULL; /* no match found */
}
```


在其找到一个进程时，他会将该进程从列表中移除，并返回该进程；否则，该函数会返回 `NULL`。


图 33.2 “将进程添加到等待列表的函数” 中的最后一个辅助函数，会在某个进程无法找到匹配时被调用。


<a name="f-33.2"></a> **图 33.2，将进程添加到等待列表的函数**


```c
static void waitonlist (lua_State *L, const char *channel,
        Proc **list) {
    Proc *p = getself(L);

    /* link itself at the end of the list */
    if (*list == NULL) { /* empty list? */
        *list = p;
        p->previous = p->next = p;
    }
    else {
        p->previous = (*list)->previous;
        p->next = *list;
        p->previous->next = p->next->previous = p;
    }

    p->channel = channel; /* waiting channel */
    do { /* wait on its condition variable */
        pthread_cond_wait(&p->cond, &kernel_access);
    } while (p->channel);
}
```


在这种情况下，进程会将自己，链接到相应等待列表的末尾，然后等待另一进程与之匹配并唤醒他。(围绕 `pthread_cond_wait` 的循环，会处理 POSIX 线程中所允许的那些虚假唤醒。）当某个进程唤醒另一进程时，他会将另一进程的字段 `channel` 设置为 `NULL`。因此，在 `p->channel` 不为 `NULL` 时，就意味着没有进程匹配进程 `p`，因此其必须继续保持等待。



有了这些辅助函数，我们就可以编写 `send` 和 `receive` 了（图 33.3 “发送和接收消息的函数”）。


<a name="f-33.3"></a> **图 33.3，发送和接收消息的函数**



```c
static int ll_send (lua_State *L) {
    Proc *p;
    const char *channel = luaL_checkstring(L, 1);

    pthread_mutex_lock(&kernel_access);

    p = searchmatch(channel, &waitreceive);

    if (p) { /* found a matching receiver? */
        movevalues(L, p->L); /* move values to receiver */
        p->channel = NULL; /* mark receiver as not waiting */
        pthread_cond_signal(&p->cond); /* wake it up */
    }
    else
        waitonlist(L, channel, &waitsend);

    pthread_mutex_unlock(&kernel_access);
    return 0;
}

static int ll_receive (lua_State *L) {
    Proc *p;
    const char *channel = luaL_checkstring(L, 1);
    lua_settop(L, 1);

    pthread_mutex_lock(&kernel_access);

    p = searchmatch(channel, &waitsend);

    if (p) { /* found a matching sender? */
        movevalues(p->L, L); /* get values from sender */
        p->channel = NULL; /* mark sender as not waiting */
        pthread_cond_signal(&p->cond); /* wake it up */
    }
    else
        waitonlist(L, channel, &waitreceive);

    pthread_mutex_unlock(&kernel_access);

    /* return all stack values except the channel */
    return lua_gettop(L) - 1;
}
```


函数 `ll_send` 开始获取通道。然后他会给互斥锁上锁，并寻找匹配的接收方。在找到时，他就将其值迁移到该接收方，将接收方标记为就绪，并将其唤醒。否则，他将处于等待状态。当其完成该操作时，他会释放互斥锁，不带值下回到 Lua。函数 `ll_receive` 与此类似，但他必须返回所有接收到的值。


现在我们来看看如何创建出新的进程。新进程需要一个新的 POSIX 线程，而新的线程需要一个要运行的主体。我们稍后将定义这个主体；下面是其原型，由 `pthreads` 指定：


```c
static void *ll_thread (void *arg);
```


要创建并运行某个新进程，系统必须

- 创建出一个新的 Lua 状态；
- 启动一个新线程；
- 编译给定的代码块；
- 调用该代码块；
- 并最后释放其资源。


原线程会完成前三项任务，新线程则完成其余任务。(为了简化错误处理，该系统只有在成功编译了给定块后，才会启动新线程。）



函数 `ll_start` 将创建一个新进程（图 33.4 “创建新进程的函数”）。


<a name="f-33.4"></a> **图 33.4，创建新进程的函数**



```c
static int ll_start (lua_State *L) {
    pthread_t thread;
    const char *chunk = luaL_checkstring(L, 1);
    lua_State *L1 = luaL_newstate();

    if (L1 == NULL)
        luaL_error(L, "unable to create new state");

    if (luaL_loadstring(L1, chunk) != 0)
        luaL_error(L, "error in thread body: %s",
                lua_tostring(L1, -1));

    if (pthread_create(&thread, NULL, ll_thread, L1) != 0)
        luaL_error(L, "unable to create new thread");

    pthread_detach(thread);
    return 0;
}
```


此函数会创建出一个新的 Lua 状态 `L1`，并在这个新状态下编译给定的代码块。在出现错误时，他将向原状态 `L` 发出错误信号。然后，他将创建一个以 `ll_thread` 为主体的新线程（使用 `pthread_create`），将新状态 `L1` 作为参数传递给该主体。到 `pthread_detach` 的调用会告诉系统，我们不打算从这个线程得到任何最终答案。


每个新线程的主体，都是函数 `ll_thread`（图 33.5，“新线程的主体”），他会接收其对应的 Lua 状态（由 `ll_start` 创建），栈上只有预编译的主代码块。


<a name="f-33.5"></a> **图 33.5，新线程的主体**


```c
int luaopen_lproc (lua_State *L);

static void *ll_thread (void *arg) {
    lua_State *L = (lua_State *)arg;
    Proc *self; /* own control block */

    openlibs(L); /* open standard libraries */
    luaL_requiref(L, "lproc", luaopen_lproc, 1);
    lua_pop(L, 1); /* remove result from previous call */

    self = (Proc *)lua_newuserdata(L, sizeof(Proc));
    lua_setfield(L, LUA_REGISTRYINDEX, "_SELF");
    self->L = L;
    self->thread = pthread_self();
    self->channel = NULL;
    pthread_cond_init(&self->cond, NULL);

    if (lua_pcall(L, 0, 0, 0) != 0) /* call main chunk */
        fprintf(stderr, "thread error: %s", lua_tostring(L, -1));

    pthread_cond_destroy(&getself(L)->cond);
    lua_close(L);
    return NULL;
}
```

> **译注**：在 Lua 5.4 中，`openlibs(L);` 应写作 `luaL_openlibs(L);`，并应 `#include "lualib.h"`。


首先，他会打开标准 Lua 库及 `lproc` 库。其次，他创建并初始化了其自己的控制代码块。然后，他会调用其主块。最后，他销毁了其条件变量，并关闭其 Lua 状态。


请注意使用 `luaL_requiref` 来打开 `lproc` 库的用法。<sup>2</sup> 这个函数在某种程度上等同于 `require`，但他不是检索某个加载器，而是使用给定函数（在我们的例子中是 `luaopen_lproc`）来打开该库。调用这个打开函数后，`luaL_requiref` 会将结果，注册到 `package.loaded` 表中，这样今后的那些需要该库的调用，就不会再尝试打开该库了。在以 `true` 为其最后一个参数下，他还会将库，注册到相应的全局变量中（在本例中为 `lproc`）。


> **脚注**：
>
> <sup>2</sup>：该函数是在 Lua 5.2 中引入的。


图 33.6 “`lproc` 模组的额外函数”，列出了该模组的最后几个函数。



<a name="f-33.6"></a> **图 33.6，`lproc` 模组的额外函数**


```c
static int ll_exit (lua_State *L) {
    pthread_exit(NULL);
    return 0;
}

static const struct luaL_Reg ll_funcs[] = {
    {"start", ll_start},
    {"send", ll_send},
    {"receive", ll_receive},
    {"exit", ll_exit},
    {NULL, NULL}
};

int luaopen_lproc (lua_State *L) {
    luaL_newlib(L, ll_funcs); /* open library */
    return 1;
}
```


二者均非常简单。函数 `ll_exit` 只应由主进程，在其结束时调用，以避免整个程序立即结束。函数 `luaopen_lproc` 是用于打开该模组的标准函数。


正如我（作者）前面所说，这个 Lua 进程的实现非常简单。我们可以做出无穷无尽的改进。下面我（作者）将简要讨论其中的一些。


第一个显而易见的改进，是改变检索匹配通道的线性方法。一种不错的替代方案，是使用哈希表查找通道，并为每个通道使用独立的等待列表。


另一项改进，与进程创建的效率有关。创建新的 Lua 状态，是项轻量级操作。然而，打开全部标准库的操作，却并不那么轻量级，而且大多数进程，可能并不需要全部标准库。正如我们在 [“函数 `require`”](./modules_and_packages.md#函数-require) 小节中所讨论的，我们可通过使用库的预注册，避免打开某个库的开销。在这种方法下，我们无需为每个标准库，调用 `luaL_requiref`，而只需将该库的打开函数，放入 `package.preload` 表中即可。在进程调用 `require "lib"` 时，那么 -- 也只有 -- `require` 才会调用相关函数来打开该库。图 33.7 “按需注册要打开的库” 中的函数 `registerlib`，就完成了这种注册。



<a name="f-33.7"></a> **图 33.7，按需注册要打开的库**


```c
static void registerlib (lua_State *L, const char *name,
        lua_CFunction f) {
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload"); /* get 'package.preload' */
    lua_pushcfunction(L, f);
    lua_setfield(L, -2, name); /* package.preload[name] = f */
    lua_pop(L, 2); /* pop 'package' and 'preload' tables */
}

static void openlibs (lua_State *L) {
    luaL_requiref(L, "_G", luaopen_base, 1);
    luaL_requiref(L, "package", luaopen_package, 1);
    lua_pop(L, 2); /* remove results from previous calls */

    registerlib(L, "coroutine", luaopen_coroutine);
    registerlib(L, "table", luaopen_table);
    registerlib(L, "io", luaopen_io);
    registerlib(L, "os", luaopen_os);
    registerlib(L, "string", luaopen_string);
    registerlib(L, "math", luaopen_math);
    registerlib(L, "utf8", luaopen_utf8);
    registerlib(L, "debug", luaopen_debug);
}
```


打开基本库始终是个好主意。我们还需要软件包库；否则，我们将没有打开其他库的 `require`。所有其他库都可以是可选的。因此，在开启新状态时，与其调用 `luaL_openlibs`，我们可调用咱们自己的函数 `openlibs`（同样在图 33.7 [“注册按需打开的库”](#f-33.7) 种给出了）。只要某个进程需要这些库中的一个，他就会明确要求使用该库，而 `require` 将调用相应的 `luaopen_*` 函数。


其他改进涉及到一些通信元语。例如，对 `lproc.send` 和 `lproc.receive` 等待匹配的时间进行限制，就是非常有用的。特别是，零限制将使这些函数成为非阻塞函数。在 POSIX 线程下，我们可使用 `pthread_cond_timedwait`，实现这一特性。



## 练习

<a name="exercise-33.1"></a> 练习 33.1：正如我们所看到的，若某个函数调用了 `lua_yield`（无延续版本），当线程恢复时，控制权会返回到调用他的函数。那么调用函数会从该调用的结果中，接收到哪些值呢？

<a name="exercise-33.2"></a> 练习 33.2：请修改这个 `lproc` 库，使其可以发送和接收其他原生类型，如布尔型和数字，而无需将其转换为字符串；(提示：咱们只需修改函数 `movevalues` 即可。）

<a name="exercise-33.3"></a> 练习 33.3：请修改这个 `lproc` 库，使其可以发送和接收表；(提示：咱们可以在接收状态下，遍历原始表，构建出一个副本。）

<a name="exercise-33.4"></a> 练习 33.4： 请在 `lproc` 库中，实现非阻塞的 `send` 操作。


（End）



