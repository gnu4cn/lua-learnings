# 协程

**Coroutines**


我们并不经常需要用到协程，但当我们需要的时候，协程就是项无与伦比的特性。明面上协程可以颠覆调用者与被调用者之间的关系，这种灵活性解决了软件架构中，“谁是老大，who-is-the-boss”（或 “谁拥有主循环，who-has-the-main-loop”）问题。这是几个看似不相关问题，如事件驱动程序中的纠缠，entanglement in event-driven programs、生成器构建迭代器，building iterators through generators，以及合作多线程，cooperative multithreading，等的概括。协程以简单高效的方式，解决了所有这些问题。


所谓 *协程，coroutine*，类似于线程（在多线程的意义上）：他是条拥有自己堆栈、自己局部变量，以及自己指令指针的执行线，a line of execution，with its own stack, its own local varialbes, and its own instruction pointer；线程与协程之间的主要区别在于，多线程的程序会并行运行多个线程，而协程程序则是协作式的：在任何给定时间，有着协程的程序，都只运行其协程程序的其中之一，并且只有当这个运行中的协程程序明确要求暂停执行时，他才会暂停执行。


在本章中我们将介绍 Lua 中，协程的工作原理，以及如何使用他们来解决各种问题。



## 协程基础

**Coroutine Basics**


Lua 将所有与协程相关的函数，都打包在表 `coroutine` 中。函数 `create` 可以创建出新协程。他只有一个参数，即包含协程将要运行代码的函数（协程 *体*，the coroutine *body*）。他会返回一个 `thread` 类型的值，代表新的协程。通常，`create` 的参数是个匿名函数，就像这里一样：


```lua
#!/usr/bin/env lua
co = coroutine.create(function () print("hi") end)
print(type(co))             --> thread
```



