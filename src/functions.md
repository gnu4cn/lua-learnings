# 函数

函数是 Lua 中，语句和表达式抽象的主要机制。函数既可以执行特定任务（在其他语言中有时称为 *过程，procedure*，或 *子程序，subroutine*），也可以计算并返回值。在第一种情况下，我们会将函数调用用作语句，use a function call as a statement；在第二种情况下，我们将函数调用，用作表达式，use it as an expression：


```lua
> print(8*9, 9/8)
72      1.125
> a = math.sin(3) + math.cos(10)
> print(os.date())
11/03/23 14:12:05
```

两种情况下，用括号括起来的参数列表，都表示了这种函数调用；如果调用没有参数，我们仍必须写下一个空列表，`()`，来表示函数调用。这条规则有一个特例：在函数只有一个参数，且该参数是字面字符串，或表构造器时，表示函数调用的括号，则是可选的：


```lua
> print "Hello World"       <-->    print("Hello World")
Hello World
> dofile 'lib.lua'          <-->    dofile("lib.lua")
> function f(a) ; end
> f{x=10, y=20}             <-->    f({x=10, y=20})
> type{}                    <-->    type({})
table
```

Lua 还为面向对象的调用，提供了一种特殊的语法，即冒号操作符。像 `o:foo(x)` 这样的表达式，就调用了对象 `o` 中的方法 `foo`。在第 21 章 [*面向对象编程*](oop.md) 中，我们将更详细地讨论，这样的调用及面向对象编程。


Lua 程序可以使用在 Lua 及 C（或主机应用程序用到的任何其他语言）中，定义的函数。通常情况下，咱们使用 C 语言函数，是为了获得更好的性能，以及访问那些不易从 Lua 直接访问的设施（如操作系统设施）。例如，标准 Lua 库中的所有函数，都是用 C 语言编写的。不过，在调用函数时，Lua 中定义的函数，与 C 中定义的函数，并无区别。


正如我们在其他示例中看到的，Lua 中的函数定义，有着传统的语法，就像下面这样：


```lua
-- 将序列 'a' 的元素相加
function add (a)
    local sum = 0

    for i = 1, #a do
        sum = sum + a[i]
    end

    return sum
end
```

在这种语法中，函数定义包含了一个 *名字，name*（在示例中为 `add`）、一个 *参数，parameters* 列表，和一个 *主体，body*（即语句的列表）。参数的作用，跟使用函数调用中传递的参数值，所初始化的局部变量完全相同。


我们可以使用与其参数数量不同的参数，来调用某个函数。 Lua 通过丢弃额外的参数，以及为额外的参数提供一些 `nil` 值，来调整参数的数量。例如，请考虑下面这个函数：


```lua
function f (a, b) print(a, b) end
```

其有着以下行为：


```lua
> f()
nil     nil
> f(3)
3       nil
> f(3, 4)
3       4
> f(3, 4, 5)        --> 5 会被丢弃
3       4
```

尽管这样的行为可能导致编程错误，programming errors（通过最少的测试，即可轻松发现），但他也很有用，尤其是对于默认参数。例如，请考虑下面的对某个全局计数器递增的函数：


```lua
function incCount (n)
    n = n or 1
    globalCounter = globalCounter + n
end
```

该函数的默认参数为 `1`；调用 `incCount()`（不带参数）时，`globalCounter` 会递增 `1`。当我们调用 `incCount()` 时，Lua 会首先将参数 `n`，初始化为 `nil`；而 `or` 表达式的结果为第二个操作数，因此 Lua 会将 `n` 赋值为默认的 `1`。



## 多个返回值

函数可以返回多个结果，这是 Lua 的一个非常规，但相当方便的特性。有几个 Lua 中预定义的函数，可以返回多个值。我们已经看到过函数 `string.find`，他可以在字符串中定位出某种模式。在找到模式时，该函数会返回两个索引：匹配开始处字符的索引，和匹配结束处字符的索引。多重赋值，a multiple assignment，允许程序获得这两个结果：


```lua
> s, e = string.find("Hello Lua users", "Lua")
> print(s, e)
7       9
```

(请记住，字符串第一个字符索引为 `1`。）


我们在 Lua 中编写的函数，也可以返回多个结果，方法是在 `return` 关键字后，列出所有结果。例如，查找某个序列中最大元素的函数，便可以返回最大值及其位置：


```lua
function maxium (a)
    local mi = 1            -- 最大值的索引
    local m = a[mi]         -- 最大值

    for i = 1, #a do
        if [ai] > m then
            mi = i; m = a[i]
        end
    end

    return m, mi
end

print(maxium({8, -1, 10, 23, 12, 5}))       --> 23      4
```


Lua 总是会根据调用的具体情况，调整函数结果的数量。当我们以语句形式调用函数时，Lua 会丢弃函数的所有结果。当我们将函数调用，作为表达式（例如加法的操作数）时，Lua 会只保留第一个结果。只有当调用是表达式列表中，最后一个（或唯一一个）表达式时，我们才能得到所有结果。这些列表会出现在 Lua 的四种结构中：

- 多重赋值

- 函数调用的参数

- 表构造器

- 以及 `return` 语句


为了说明所有这些情况，我们将在接下来的示例中，假设以下定义：


```lua
> function foo0 () end                      -- 不返回结果
> function foo1 ()  return 'a' end          -- 返回 1 个结果
> function foo2 ()  return 'a', 'b' end     -- 返回 2 个结果
```


在多重赋值中，作为最后（或唯一）表达式的函数调用，会产生与变量匹配所需的任意多个结果：


```lua
> x, y = foo2()
> print(x, y)
a       b
> x = foo2()                -- 这里返回的 'b' 会被丢弃
> print(x)
a
> x, y, z = 10, foo2()
> print(x, y, z)
10      a       b
```


在多重赋值中，如果函数的结果少于我们的所需，Lua 会为缺失的值生成一些 `nil`：


```lua
> x,y = foo0()
> print(x, y)
nil     nil
> x,y = foo1()
> print(x, y)
a       nil
> x,y,z = foo2()
> print(x, y, z)
a       b       nil
```

请记住，只有当调用是列表中的最后（或唯一）的表达式时，才会出现多个结果。如果函数调用不是表达式列表中的最后一个元素，则总是只产生一个结果：


```lua
> x,y = foo2(), 20
> print(x, y)
a       20
> x,y = foo0(), 20, 30
> print(x, y)
nil     20
```


当函数调用是另一调用的最后一个（或唯一一个）参数时，第一个调用的所有结果，都将作为参数。我们已经在 `print` 中，看到了这种结构的例子。由于 `print` 可以接收可变数量的参数，因此语句 `print(g())` 会打印出 `g` 返回的所有结果。


```lua
> print(foo0())             -- （没有结果）

> print(foo1())
a
> print(foo2())
a       b
> print(foo2(), 1)
a       1
> print(foo2() .. 'x')      -- （请参阅下文）
ax
```

当对 `foo2` 的调用，出现在某个表达式中时，Lua 会将结果数调整为一个；因此，在最后一行中，连接操作只会使用第一个结果 `"a"`。


在我们写下 `f(g())`，且 `f` 有着固定参数数目时，Lua 会将 `g` 的结果数，调整为 `f` 的参数数目。这并非偶然，这与多重赋值中发生的行为，完全相同。


表构造器，也会收集调用的所有结果，而不做任何调整：



```lua
> t = {foo0()}                              -- t = {}（一个空表）
> for k, v in pairs(t) do print(k, v) end
> t = {foo1()}                              -- t = {'a'}
> for k, v in pairs(t) do print(k, v) end
1       a
> t = {foo2()}                              -- t = {'a', 'b'}
> for k, v in pairs(t) do print(k, v) end
1       a
2       b
```


与往常一样，只有当调用是列表中的最后一个（或唯一一个）表达式时，才会出现这种行为；在任何其他位置的调用，都只会产生一个结果：


```lua
> t = {foo0(), foo2(), 4}                   -- t = {nil, 'a', 4}
> for k, v in pairs(t) do print(k, v) end
2       a
3       4
```


> **注意**：这里 `t[1]` 没有打印出来。



最后，`return f()` 这样的语句，会返回 `f` 所返回的所有值：



```lua
> function foo (i)
>> if i == 0 then return foo0()
>> elseif i == 1 then return foo1()
>> elseif i == 2 then return foo2()
>> end
>> end
>
> print(foo(1))
a
> print(foo(2))
a       b
> print(foo(0))

> print(foo(3))     -- (没有结果值)
```


通过用一对额外的括号，将调用括起来，咱们就可以强制其只返回一个结果：


```lua
> print((foo0()))
nil
> print((foo1()))
a
> print((foo2()))
a
```


请注意，`return` 语句不需要在返回值周围，加上括号；那里所加上的任何一对括号，都会算作额外的一对括号。因此，`return (f(x))` 这样的语句，总是会返回单个值，而无论 `f` 返回多少个值。有时这正是我们想要的，有时却不是。


## 可变函数

**Variadic Functions**


Lua 中的函数可以是 *可变的, variadic*，这说的是，函数可以接受可变数量的参数。例如，我们已经以一个、两个或更多参数，调用了 `print`。虽然 `print` 是在 C 语言中定义的，但我们也可以在 Lua 中，定义可变函数。



举个简单的例子，下面的函数，返回所有参数的和：


```lua
function add (...)
    local sum = 0

    for _, v in ipairs{...} do
        sum = sum + v
    end

    return sum
end

print(add(0, 1, 3, 5, 7, 11))       --> 27
```

参数列表中的三个点（`...`），表示函数是可变的。当我们调用这个函数时，Lua 会在内部，收集所有参数；我们称这些收集到的参数，为函数的 *额外参数，extra arguments*。函数访问其额外参数时，会再次用到这三个点，现在则是作为表达式了。在我们的示例中，表达式 `{...}` 的结果，是一个包含了所有已收集参数的列表。然后，函数遍历该列表，以累加其中的元素。


我们将这种三点表达式，称为 *可变参数表达式，vararg expression*。其行为类似于多重返回函数，会返回当前函数的所有额外参数。例如，命令 `print(...)`，便会打印该函数的所有额外参数。同样，下面这条命令，将以前两个可选参数的值（如果没有可选参数，则为 `nil`），创建出两个局部变量：


```lua
local a, b = ...
```


> **注意**：上面语法的完整示例：

```lua
function add (...)
    local sum = 0
    local a, b = ...

    for _, v in ipairs{...} do
        sum = sum + v
    end

    return sum, a+b
end

add(0, 1, 3, 5, 7, 11, 13)      --> 输出为：40      1
```


其实，对于 Lua 在将

```lua
function foo (a, b, )
```

翻译到


```lua
function foo (...)
    local a, b, c = ...
```

时的一般的参数传递机制，我们可以加以模拟。

喜欢 Perl 参数传递机制的那些人，可能会喜欢第二种形式。


像下一个的这种函数，只会简单地返回所有参数：


```lua
function id (...) return ... end
```

这是一个多值标识函数。下一个函数的行为，则与另一个函数 `foo` 完全相同，只是在调用之前，会打印一条包含参数的信息：


```lua
function foo1 (...)
    print("calling foo:", ...)
    return foo(...)
end
```

这是跟踪特定函数调用的一种有用技巧。


我们来看另一个有用的例子。Lua 分别提供了格式化文本（`string.format`）和写入文本（`io.write`）两个函数。将这两个函数合并为一个可变函数，就非常简单：


```lua
function f_write (fmt, ...)
    return io.write(string.format(fmt, ...))
end
```

请注意，在三点之前，有一个固定参数 `fmt`。可变函数在可变部分之前，可以有任意数量的固定参数，fixed paramenters。Lua 会将靠前的参数，the first arguments，分配给这些参数，其余参数（如果有的话）作为额外参数。


为了遍历额外参数，函数可以使用表达式 `{...}`，将他们全部收集到一个表中，就像我们在 `add` 的定义中所做的那样。然而，在额外参数可能是有效的一些 `nil` 的极少数情况下，用 `{...}` 创建的表，就可能不是正确的序列了。比如，在这样的表中，就无法检测原始参数中，是否有尾部的一些 `nil`。针对这种情况，Lua 提供了函数 `table.pack`。<sup>注 1</sup>这个函数会接收任意数量的参数，并返回一个包含所有参数的新表（就像 `{...}`），但这个表还有一个额外的字段 `"n"`，包含参数的总数。例如，下面的函数就使用了 `table.pack`，来测试是否其参数没有一个为 `nil`：


> **注 1**：这个函数时在 Lua 5.2 中引入的。


```lua
function nonils (...)
    local arg = table.pack(...)

    for i = 1, arg.n do
        if arg[i] == nil then return false end
    end

    return true
end


print(nonils(2,3,nil))      --> false
print(nonils(2,3))          --> true
print(nonils())             --> true
print(nonils(nil))          --> false
```


另一种遍历函数可变参数的方法，便是 `select` 函数。对 `select` 函数的调用，总是有着一个固定参数，即 *选择器，selector*，外加数量可变的额外参数。在选择器是个数 `n` 时，`select` 就会返回第 `n` 个参数后的所有参数；否则，选择器就应是字符串 `"#"`，如此 `select` 会返回额外参数的总数目。


```lua
> select(1, "a", "b", "c")
a       b       c
> select(2, "a", "b", "c")
b       c
> select(3, "a", "b", "c")
c
> select("#", "a", "b", "c")
3
```


通常，我们在使用 `select` 时，会将其结果数调整为 `1`，因此我们可以将 `select(n, ...)`，视为返回第 `n` 个额外参数。


```lua
> (select(1, "a", "b", "c"))
a
> (select(2, "a", "b", "c"))
b
> (select(3, "a", "b", "c"))
c
```

作为使用 `select` 的一个典型示例，下面是使用了 `select` 的我们之前的 `add` 函数：


```lua
function add (...)
    local sum = 0

    for i = 1, select("#", ...) do
        sum = sum + select(i, ...)
    end

    return sum
end
```


对于参数较少的情况，这个第二个版本的 `add` 更快，因为他避免了每次调用，都创建出一个新表。然而，对于参数较多的情况，多次调用有着多参数的 `select` 的开销，要比创建表的代价高，因此第一个版本成为更好的选择。(特别是，第二个版本的开销是二次方的，因为迭代次数，及每次迭代传递的参数数目，都会随着参数数目的增加而增加。）


## 关于函数 `table.unpack`


具有多重返回的一个特殊函数，是 `table.unpack`。他取得一个列表，并将列表中的所有元素，作为结果返回：


```lua
> table.unpack{10,20,30}
10      20      30
> a,b = table.unpack{10,20,30}      -- 30 会被丢弃
> print(a,b)
10      20
```


顾名思义，`table.unpack` 与 `table.pack` 相反。`pack` 将参数列表，转换为具体的 Lua 列表（表），而 `unpack` 则将具体的 Lua 列表（表），转换为返回列表，a return list，后者就可以作为参数列表，提供给另一个函数。


`unpack` 的一个重要用途，便是一种泛型调用机制中，in a generic call mechanism。泛型调用机制允许我们，以任意的参数，动态地调用任何函数。例如，在 ISO C 语言中，我们无法编写出泛型的调用。我们可以使用 `stdarg.h`，声明出接受可变参数的函数，也可以使用函数指针，调用某个可变函数。但是，我们无法调用某个参数数目可变的函数：在 C 语言中，咱们所编写的每个调用，都有固定的参数数目，每个参数都有固定的类型。在 Lua 中，如果我们想以数组 `a` 中的可变参数，调用可变函数 `f`，只需这样写即可：


```lua
f(table.unpack(a))
```

对 `unpack` 的调用，会返回 `a` 中所有的值，这些值会成为 `f` 的参数。例如，请考虑以下调用：


```lua
print(string.find("hello", "ll"))
```

我们可以用下面的代码，动态地建立一个等价调用：


```lua
f = string.find
a = {"hello", "ll"}

print(f(table.unpack(a)))
```

通常，`table.unpack` 会用到长度运算符，来确定出要返回多少个元素，因此他只适用于正确的序列。不过，如果需要，我们可以提供明确的限制：


```lua
> print(table.unpack({"Sun", "Mon", "Tue", "Wed"}, 2, 3))
Mon     Tue
```


虽然这个预定义的函数 `unpack` 是用 C 编写的，但我们也可以使用递归，using recursion，以 Lua 编写：


```lua
function _unpack (t, i, n)
    i = i or 1
    n = n or #t
    if i <= n then
        return t[i], _unpack(t, i + 1, n)
    end
end


_unpack({1, 3, 5, 7, 9})        --> 1       3       5       7       9
_unpack({1, 3, 5, 7, 9}, 2, 4)  --> 3       5       7
```

第一次使用单个参数调用时，参数 `i` 为 `1`，`n` 为序列的长度。然后，函数返回 `t[1]`，接着返回 `unpack(t, 2, n)` 的所有结果，然后返回 `t[2]`，接着返回 `unpack(t, 3, n)` 的所有结果，依此类推，直到返回 `n` 个元素后（递归）停止。



## 正确的尾部调用

**Proper Tail Calls**


Lua 中函数的另一个有趣特性，是 Lua 会消除尾部调用。(这意味着 Lua 具有 *适当的尾部递归性，properly tail recursive*，尽管这一概念并不直接涉及到递归；参见练习 6.6。）


所谓尾部调用，就是将 `goto` 伪装成调用。当某个函数作为其最后一个动作，调用另一函数时，就会发生尾部调用，这样他就没有其他事情可做了。例如，在下面的代码中，对 `g` 的调用就是尾调用：


```lua
function f (x) x = x + 1; return g(x) end
```

在 `f` 调用了 `g` 之后，就没有其他事情可做了。在这种情况下，程序不需要在被调用函数结束时，返回到调用函数。因此，在尾部调用后，程序无需在堆栈中，保留任何关于调用函数的信息。当 `g` 返回时，控制（CPU 底层部分）就可以直接返回到调用 `f` 的点。一些语言实现（如 Lua 解释器），利用了这一事实，在进行尾部调用时，实际上不会使用任何额外的栈空间。我们就说，这些实现消除了尾部调用。


由于尾部调用不会占用栈空间，因此程序可以构造无限次数的嵌套尾部调用。例如，我们可以将任意数字作为参数，调用下面的函数：


```lua
function foo (n)
    if n > 0 then return foo(n - 1) end
end
```

他永远不会溢出堆栈。


关于尾部调用消除，tail-call elimination，的一个微妙之处，便是什么是尾部调用。一些貌似显而易见的尾部调用，却不满足调用后没有其他事情可做的标准。例如，在下面的代码中，对 `g` 的调用，便不属于尾部调用：


```lua
function f (x) g(x) end
```


此示例中的问题，是在调用 `g` 之后，`f` 在返回之前，仍必须丢弃 `g` 的任何结果。同样，以下所有调用，均不符合标准：

```
return g(x) + 1     -- 必须完成这个加法
return x or g(x)    -- 必须调整到 1 个结果
return (g(x))       -- 必须调整到 1 个结果
```


在 Lua 中，只有 `return func(args)` 形式的调用，才是尾调用。然而，`func` 及其参数，都可以是复杂的表达式，因为 Lua 在调用之前，会对他们进行计算。例如，下一调用就是尾调用：


```lua
return x[i].foo(x[j] + a*b, i + j)
```



## 练习


练习 6.1：请编写出接受一个数组，并打印其所有元素的函数。

练习 6.2：请编写一个接受任意数量的值，并返回除第一个值之外其余值的函数。

练习 6.3：请编写一个接受任意数量的值，并返回除最后一个值之外其余值的函数。

练习 6.4：请编写一个打乱给定列表的函数。要确保所有排列的概率相同。

练习 6.5：请编写一个接受一个数组，并打印数组中元素的所有组合的函数。 （提示：咱们可以使用递归公式，进行组合：`C(n,m) = C(n-1, m-1) + C(n- 1, m)`。要生成所有 `C(n,m)` 的、大小为 `m` 的组中的 `n` 个元素的组合，咱们首先要将第一个元素添加到结果中，然后生成剩余槽中，剩余元素的所有 `C(n-1, m-1)` 组合；然后咱们从结果中删除第一个元素，然后在生成空闲槽中剩余元素的所有 `C(n - 1, m)` 种组合，当 `n` 小于 `m` 时，就没有组合了；当 `m` 为零时，只有一种组合，就不会使用任何元素。 ）

练习6.6：有时，具有正确尾部调用的语言，被称为 *正确尾部递归，properly tail recursive*，并认为该属性仅当我们具有递归调用，才相关。 （如果没有递归调用，程序的最大调用深度，将是静态固定的。）

请证明这个论点，在像 Lua 这样的动态语言中不成立：编写一个程序，执行无递归的无界调用链，performs an unbounded call chain without recurion。 （提示：请参阅名为 [“编译”](compilation_execution_and_errors.md#编译) 的小节。）
