# 闭包

Lua 中的函数，是具有适当词法界定的一些头等值，functions in Lua are first-class values with proper lexical scoping。

函数是 “头等值”，是什么意思？这意味着，在 Lua 中，函数是与数字和字符串等常规值，具有相同权利的值。程序可以将函数，存储在变量（包括全局变量与局部变量）和表中，将函数作为参数，传递给其他函数，以及将函数作为结果返回。


函数具有“词法作用域，lexical scoping”，是什么意思？这意味着函数可以访问其外层函数的变量，functions can access variables of their enclosing functions。(这也意味着，Lua 正确地包含了 [lambda/λ 演算，the lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus)。）


这两个特性一起，赋予了 Lua 语言极大的灵活性；例如，在运行一段不被信任的代码（比如通过网络接收的代码）时，程序就可以重新定义一个函数，来添加新的功能，或删除某个函数，来创建出安全的环境。更重要的是，这两种特性，允许我们在 Lua 中，应用函数式语言世界中的许多强大编程技术。即使咱们对函数式编程完全毫无兴趣，也值得学习一下如何探索这些技术，因为他们可以让咱们的程序，变得更小更简单。


## 函数作为头等值

正如我们刚看到的，函数是 Lua 中的头等值。下面的示例说明了这一点：


```lua
a = {p = print}         -- 'a.p' 指向函数 'print'
a.p("Hello World")      -- Hello World

print = math.sin        -- 'print' 现在指向正弦函数
a.p(print(1))           -- 0.8414709848079

math.sin = a.p          -- 'sin' 现在指向打印函数
math.sin(10, 20)        -- 10       20
```

如果函数是些值，那么有创建函数的表达式吗？事实上，在 Lua 中编写函数的通常方法，比如


```lua
function foo (x) return 2*x end
```

便是我们所讲的 *语法糖，syntactic sugar* 的一个实例；其只是编写以下代码的一种漂亮方式：

```lua
foo = function (x) return 2*x end
```

赋值右侧的表达式（ `function (x) body end`），是个函数构造器，a function constructor，就像 `{}` 是表构造器一样。因此，函数定义，a function definition，实际上是创建出一个 `function` 类型值，并将其赋值给某个变量的一条语句。


请注意，在 Lua 中，所有函数都是匿名的。与其他值一样，他们没有名称。当我们讲到函数名称（如 `print`）时，实际上，我们是在讲存放该函数的变量。尽管我们经常将函数赋值给全局变量，给到他们一个类似于名字的东西，但在某些情况下，函数仍然是匿名的。我们来看几个例子。


表库提供了 `table.sort` 函数，该函数取一个表，并对其元素进行排序。这种函数必须允许排序顺序无限制地变化：升序或降序、数字或字母、根据键排序的表等。`sort` 并没有试图提供各种选项，而是提供了单一的可选参数，即 *排序函数，order function*：接收两个元素，并返回第一个元素是否必须排在第二个元素之前。例如，假设我们有下面这种记录的一个表：


```lua
network = {
    {name = "grauna",   IP = "210.26.30.34"},
    {name = "arraial",  IP = "210.26.30.23"},
    {name = "lua",      IP = "210.26.23.12"},
    {name = "derain",   IP = "210.26.23.20"},
}
```

如果我们打算按字段 `name` 的字母倒序，对该表进行排序，只需这样写即可：

```lua
table.sort(network, function (a, b) return (a.name > b.name) end)
```

看看在这个语句中，匿名函数是多么方便。

将另一函数作为参数的函数，比如 `sort`，我们称之为 *高阶函数，higher-order function*。高阶函数是一种功能强大的编程机制，而使用匿名函数，来创建他们的函数参数，便可以极大地提高灵活性。尽管如此，请记住，高阶函数并无特殊权利；他们是 Lua 将函数，作为头等值处理的直接结果。

为进一步说明高阶函数的使用，我们将编写一个常见高阶函数，导数，the derivative，的简单实现。在某种非正式的定义中，函数 *f* 的导数，是指当 *d* 变得无限小时的函数 *f'(x) = (f(x + d) - f(x)) / d*，根据这一定义，我们可以计算出，导数的近似值如下：


```lua
function derivative (f, delta)
    delta = delta or 1e-4
    return function (x)
        return (f(x + delta) - f(x))/delta
    end
end
```

在给定某个函数 `f` 时，调用 `derivative(f)` 就会返回其导数（近似值），而这个导数，就是另一个函数了：


```console
> c = derivative(math.sin)
> print(math.cos(5.2), c(5.2))
0.46851667130038        0.46856084325086
> print(math.cos(10), c(10))
-0.83907152907645       -0.83904432662041
> c = derivative(math.sin, 0.000000001)
> print(math.cos(5.2), c(5.2))
0.46851667130038        0.46851666990477
> print(math.cos(10), c(10))
-0.83907152907645       -0.83907158998642
```


## 非全局函数

**Non-Global Functions**


头等的函数的一个明显结果，便是我们不仅可以将函数存储在全局变量中，还可以在表字段，及局部变量中存储函数。


我们已经看到过，几个表字段中函数的例子：大多数 Lua 库，都使用这种机制（例如，`io.read`、`math.sin`）。要在 Lua 中创建此类函数，我们只需将迄今为止所学到的知识，整合在一起即可：


```lua
Lib = {}
Lib.foo = function (x, y) return x + y end
Lib.goo = function (x, y) return x - y end

print(Lib.foo(2, 3), Lib.goo(2, 3))     --> 5       -1
```

当然，咱们也可以使用构造器：


```lua
Lib = {
    foo = function (x, y) return x + y end,
    goo = function (x, y) return x - y end
}
```


此外，Lua 提供了一种特别语法，来定义此类函数：

```lua
Lib = {}
function Lib.foo (x, y) return x + y end
function Lib.goo (x, y) return x - y end
```

如同在第 21 章 [*面向对象编程*](oop.md) 中咱们将看到的，字段中函数的使用，是 Lua 中面向对象编程的关键要素。


当我们将某个函数，存储到局部变量中时，我们就会得到一个 *局部函数，local function*，即限制在给定范围内的一个函数。这样的定义，对软件包特别有用：因为 Lua 将每个代码片，each chunk，视为一个函数，所以代码片可以声明出一些局部函数，这些函数只在分片内部可见。词法的作用域，lexical scoping，可以确保该分片中的其他函数，可以使用这些局部函数。


Lua 通过局部函数的一种语法糖，支持局部函数的这种用法：


```lua
local function f (params)
    body
end
```

在递归的局部函数定义中，会出现一个微妙的问题，因为简单方法在这里行不通。请看下面的定义：

```lua
local fact = function (n)
    if n == 0 then return 1
    else return n*fact(n-1)     -- 问题代码
    end
end

```

当 Lua 编译函数体中的调用 `fact(n - 1)` 时，这个局部的 `fact` 尚未定义。因此，该表达式将尝试调用全局的 `fact`，而不是局部的 `fact`。我们可以通过先定义局部变量，然后再定义函数，来解决这个问题：


```lua
local fact
fact = function (n)
    if n == 0 then return 1
    else return n*fact(n-1)
    end
end
```


现在，函数中的那个 `fact`，指向了这个局部变量。函数定义时的值并不重要；函数执行时，`fact` 已经有了正确的值。

当 Lua 展开局部函数的语法糖时，他不会使用简单（朴素）定义，the naive definition。取而代之的是：

```lua
local function foo (params) body end
```

会展开为

```lua
local foo; foo = function (params) body end
```

因此，我们可以放心地将这种语法，用于递归函数。


当然，在我们使用的是间接递归函数，indirect recursive function，时，这种技巧就不起作用了。在这种情况下，我们必须使用等同于显式前向声明，the equivalent of an explicit forward declaration，的方法：


```lua
local f         -- “前向” 声明

local function g ()
    some code   f()   some code
end

function f ()
    some code   g()     some code
end
```

注意不要在最后一个定义中，写下 `local`。否则，Lua 将创建一个新的局部变量 `f`，而原来的 `f`（即 `g` 绑定的那个）就会是未定义的了。


## 词法作用域

**Lexical Scoping**


当我们编写包含在另一函数中的函数时，他可以完全访问其外部函数中的局部变量；我们称这种特性为 *词法作用域，lexical scoping*。虽然这一可见性规则，听起来很明显，但实际上并非如此。词法作用域，加上嵌套的头等函数，为编程语言提供了强大的功能，但许多编程语言，并不支持这种组合。


我们从一个简单的例子开始。假设咱们有个学生姓名的列表，和一个将姓名，映射到分数的表；我们想根据分数，对列表中的姓名进行排序，分数越高，排序越靠前。我们可以按下面的方法，完成这项任务：


```lua
names = {"Peter", "Paul", "Mary"}
grades = {Mary = 10, Paul = 7, Peter = 8}

table.sort(names, function (n1, n2)
    return grades[n1] > grades[n2]      -- 比较分数
end)
```

现在，假设我们打算创建一个函数，来完成此任务：


```lua
function sortbygrade (names, grades)
    table.sort(names, function (n1, n2)
        return grades[n1] > grades[n2]      -- 比较分数
    end)
end
```

后一个示例的有趣之处在于，给到 `sort` 的那个匿名函数，访问了外层函数 `sortbygrade` 的一个参数 `grades`。在这个匿名函数中，`grades` 既不是全局变量，也不是局部变量，而是我们所讲的 *非局部变量，non-local variable*。(由于历史原因，在 Lua 中，非局部变量也被称为 *上值，upvalues*。）


为什么这一点如此有趣？因为函数作为头等值，可以 *摆脱，escape* 其变量的原始作用域，the original scope of their variables。请看下面的代码：


```lua
function newCounter ()
    local count = 0
    return function ()      -- 匿名函数
        count = count + 1
        return count
    end
end

c1 = newCounter()
print(c1())     --> 1
print(c1())     --> 2
```

在这段代码中，匿名函数引用了一个非本地变量（`count`），来保存计数器。然而，当我们调用那个匿名函数时，变量 `count` 似乎已经超出了作用域，因为创建该变量（`newCounter`）的函数已经返回。不过，Lua 使用 *闭包，closure* 的概念，正确地处理了这种情况。简单地说，闭包就是函数，及其正确访问非本地变量所需的一切。如果我们再次调用 `newCounter`，他将创建一个新的本地变量 `count` 和作用于这个新变量的闭包：


```lua
c2 = newCounter()
print(c2())     --> 1
print(c1())     --> 3
print(c2())     --> 2
```

因此，`c1` 和 `c2`，是不同的闭包。他们都是在同一个函数上建立的，但各自作用于，本地变量 `count` 的独立实例。


从技术上讲，Lua 中的值，是闭包，而不是函数。函数本身，就是闭包的一种原型，a kind of a prototype for closures。尽管如此，只要没有混淆的可能，我们将继续使用 “函数” 一词，来指代闭包。


在很多情况下，闭包都提供了一种非常有价值的工具。正如我们所见，闭包可以作为排序等高阶函数的参数。对于那些构建其他函数的函数，闭包也很有价值，比如我们的 `newCounter` 例子，或 `derivative` 例子；这种机制允许 Lua 程序，结合来自函数式编程世界的，那些复杂编程技术。闭包对于 *回调，callback* 函数，也很有用。典型的例子，就是当我们在传统 GUI 工具包中，创建按钮时。每个按钮都有在用户按下按钮时，被调用的回调函数；我们希望不同按钮在按下时，做的事情略有不同。


例如，数字计算器会需要十个类似的按钮，每个数字一个。用下面这样的函数，咱们就可以创建出各个按钮：


```lua
function digitButton (digit)
    return Button{
        label = tostring(digit),
        action = function ()
            add_to_digits(digit)
        end
    }
end
```

在此示例中，我们假定 `Button` 是个创建新按钮的工具包函数；`label` 是按钮标签；`action` 是按钮被按下时，会被调用到的回调函数。回调函数可在 `digitButton` 完成任务很长时间后，才被调用，但他仍然可以访问 `digit` 变量。


在完全不同的环境中，闭包也很有价值。由于函数被存储在常规变量中，因此我们可以轻松地在 Lua 中，重新定义函数，甚至是那些预定义函数。这一功能，是 Lua 如此灵活的原因之一。通常，当我们重新定义某个函数时，我们需要在新的实现中，使用原来的函数。举例来说，假设我们打算重新定义 `sin` 函数，将其运算单位，从弧度改为度。这个新函数，会转换其参数，然后调用原始的 `sin` 函数，进行实际操作。我们的代码可能是这样的：


```lua
local oldSin = math.sin
math.sin = function (x)
    return oldSin(x * (math.pi / 180))
end
```

下面是一种稍微简洁一些的重新定义方法：


```lua
do
    local oldSin = math.sin
    local k = math.pi / 180
    math.sin = function (x)
        return oldSin(x * k)
    end
end
```

这段代码使用了 `do` 代码块，来限制局部变量 `oldSin` 的作用域；根据传统的可见性规则，该变量只能在代码块内可见。因此，只有通过那个新的函数，才能访问该变量。

使用这种同样的技巧，咱们就可以创建出安全环境，也称为沙箱，sandboxes。在运行不受信任的代码（比如服务器通过互联网接收的代码）时，安全环境至关重要。例如，为限制某个程序可以访问的文件，我们可以使用闭包，重新定义 `io.open`：


```lua
do
    local oldOpen = io.open
    local access_OK = function (filename, mode)
        check access
    end

    io.open = function (filename, mode)
        if access_OK(filename, mode) then
            return oldOpen(filename, mode)
        else
            return nil, "access denied"
        end
    end
end
```

这个示例之所以很好，是因为在这种重新定义之后，程序除了通过新的、受限的版本，是没有办法调用那个未受限制版本的 `io.open` 的。他将不安全版本，保留为闭包中的私有变量，从外部无法访问。使用这种技巧，我们可以在 Lua 中构建出，具备通常好处的 Lua 沙箱：简单和灵活。Lua 提供的，并非一刀切的解决方案，而是一种元机制，a meta-mechanism，以便我们可以根据特定的安全需求，来定制我们的环境。（真正的沙盒，不仅仅用于保护外部的文件。我们将在 [沙箱操作](reflection.md#沙箱操作) 一节中，再次讨论这个主题。）


## 浅尝函数式编程

**A Taste of Functional Programming**


为给出更具体的函数式编程示例，我们将在本节中，开发一个简单的几何区域系统，a simple system for geometric regions。<sup>注 1</sup>我们的目标，是开发出一个表示几何区域的系统，其中区域是一组点。我们希望能够表示各种形状，并以多种方式（旋转、平移、合并等），组合及修改形状。

> **注 1**：此示例改编自 Paul Hudak 和 Mark P. Jones 撰写的研究报告 *Haskell vs. Ada vs. C++ vs. Awk vs. ... An Experiment in Software Prototyping Productivity*。


为了实现这个系统，我们可以开始寻找表示形状的，一些良好数据结构；我们可以尝试面向对象的方法，而开发出形状的一些层次结构来。或者，我们可以在更高的抽象层次上工作，直接用集合的特征函数（或指标函数）来表示集合，represent our sets directly by their characteristic(or indicator) function。(某个集合 *A* 的特征函数，是这样的一个函数 <i>f<sub>A</sub></i>：当且仅当 *x* 属于 *A* 时，<i>f<sub>A</sub>(x)</i> 为真）。鉴于几何区域是一些点的集合，我们就可以用其特征函数，来表示某个区域；也就是说，我们会用这样一个函数，来表示某个区域：对于某个给定点，当且仅当该点属于那个区域时，函数的返回值才为真。

例如，下面这个函数，表示一个圆盘面（即圆形区域），圆心为 *(1.0, 3.0)*，半径为 *4.5*：


```lua
function disk1 (x, y)
    return (x - 1.0)^2 + (y - 3.0)^2 <= 4.5^2
end
```


在高阶函数，和词法范围下，定义出以给定中心和半径，创建出某个圆盘面的圆盘面工厂，a disk factory，就很容易：


```lua
function disk (cx, cy, r)
    return function (x, y)
        return (x - cx)^2 + (y - cy)^2 <= r^2
    end
end
```


像 `disk(1.0, 3.0, 4.5)` 这样的调用，就将创建出一个等于 `disk1` 的圆盘面。


下面这个函数，将根据给定的边界，创建出与轴对齐的矩形：


```lua
function rect (left, right, bottom, up)
    return function (x, y)
        return left <= x
            and x <= right
            and bottm <= x
            and x <= up
    end
end
```

以类似的方式，我们可以定义出创建其他基本形状，例如三角形和非轴对齐矩形等的函数。每个形状都有完全独立的实现，只需要正确的特征函数。


现在我们来看看，如何修改和组合区域。创建任何区域的补集，the complement of any region，都很简单：


```lua
function complement (r)
    return function (x, y)
        return not r(x, y)
    end
end
```

如下 [图 9.1，“区域的并集、交集和差集”](#f-9.1) 所示，并集，union、交集，intersection 和差集，difference，同样简单。


<a name="f-9.1">**图 9.1，Union, intersection, and difference of regions**</a>


```lua
function union (r1, r2)
    return function (x, y)
        return r1(x, y) or r2(x, y)
    end
end

function intersection (r1, r2)
    return function (x, y)
        return r1(x, y) and r2(x, y)
    end
end


function difference (r1, r2)
    return function (x, y)
        return r1(x, y) and not r2(x, y)
    end
end
```

下面的函数会按照给定的 delta 值，平移某个区域：


```lua
function translate (r, dx, dy)
    return function (x, y)
        return r(x - dx, y - dy)
    end
end
```

要可视化某个区域，我们可以遍历视口，traverse the viewport，对每个像素进行；区域内的像素，会被涂成黑色，区域外的像素则涂成白色。为了简单地说明这一过程，我们将编写一个函数，来生成一个 PBM（*便携式位图，portable bitmap*）文件，其中带有某个给定区域的绘图。


PBM 文件的结构，非常简单。(这种结构的效率也非常低，但我们在此强调的是简单。）在其文本模式的变种里，文件以标题为 `"P1"` 字符串的单行标题开始；然后是有着单位为像素的，绘制高度和宽度的一行。最后是一串数字，每个图像像素为一个数字（黑色为 `1`，白色为 `0`），像素与行，以空格和行尾分隔。下 [图 9.2 中的函数，“在 PBM 文件中绘制区域”](#f-9.2)，会为给定区域创建出一个 PBM 文件，将虚拟绘图区域 *(-1,1], [-1,1)*，映射到视口区域 *[1,M], [1,N]*。


<a name="f-9.2">**图 9.2，在 PBM 文件中绘制区域**</a>


```lua
function plot (r, M, N)
    io.write("P1\n", M, " ", N, "\n")       -- PBM 文件头部
    for i = 1, N do                 -- 对于每行
        local y = (N - i*2)/N
        for j = 1, M do         -- 对于每列
            local x = (j*2 -M)/M
            io.write(r(x, y) and "1" or "0")
        end
        io.write("\n")
    end
end
```

为了完成我们的示例，下面的命令绘制了一弯新月（从南半球看）：


```lua
c1 = disk(0, 0, 1)
plot(difference(c1, translate(c1, 0.3, 0)), 500, 500)
```

![绘制出的新月](images/neo_lunar.png)


## 练习


练习 9.1：请写取一个函数 `f`，并返回其积分的近似值的函数 `integral`。


练习 9.2：下面代码块的输出是什么？


```lua
function F (x)
    return {
        set = function (y) x = y end,
        get = function () return x end
    }
end

o1 = F(10)
o2 = F(20)
print(o1.get(), o2.get())

o2.set(100)
o1.set(300)
print(o1.get(), o2.get())
```

练习 9.3：[练习 5.4](tables.md#练习) 要求咱们编写出接收某个多项式（用表表示）和变量值，并返回该多项式值的一个函数。请编写该函数的 *柯里化* 版本，the *curried* version of that function。<sup>注 2</sup>咱们的函数，应接收多项式并返回一个函数，在以 `x` 值调用该函数时，就会返回该 `x` 的多项式值：

```lua
f = newpoly({3, 0, 1})
print(f(0))     --> 3
print(f(5))     --> 28
print(f(10))    --> 103
```


> **注 2**：所谓柯里化，是使用函数的一种高级技巧。参见：
>
> 1. [Currying](https://javascript.info/currying-partials)
>
> 2. [Wikipedia: Currying](https://en.wikipedia.org/wiki/Currying)


练习 9.4：使用咱们的几何区域系统，绘制从北半球看到的上弦新月，a waxing crescent moon as seen from the Northern Hemishpere。


练习 9.5：请在咱们的几何区域系统中，添加一个将给定区域，旋转给定角度的函数。


（End）


