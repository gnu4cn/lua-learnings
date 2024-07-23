# 元表与元方法

**Metatables and Metamethods**


通常，Lua 中的每个值，都有一套相对可预测的操作。我们可以把数字相加，可以连接字符串，可以将键值对，插入表等等。但是，我们不能把表相加，不能把函数作比较，也不能调用字符串。除非我们使用元表。


元表允许我们在某个值面临某种未知操作时，改变其行为。例如，运用元表，我们可以定义 Lua 如何计算表达式 `a + b`，其中 `a` 和 `b` 是表。每当 Lua 尝试将两个表相加时，他都会检查两个表之一，是否有个 *元表，metatable*，以及元表是否有个 `__add` 字段。如果 Lua 找到了这个字段，他就会调用相应的值 -- 即所谓的 *元方法，metamethod*，其应是个计算和的函数。


我们可以把元表，看作面向对象的术语体系中，一种受限制的类。与类一样，元表定义了其实例的行为。不过，元表比类更受限，因为他们只能将行为赋予给一组预定义操作；同时，元表不具有继承性。不过，我们将在第 21 章，[面向对象编程](oop.md) 中，看到如何在元表的基础上，构建出一种相当完整的类系统。


Lua 中的每个值，都可以有个元表。表和用户数据，都有各自的元表；其他类型的值，则共享该类型全体值的单个元表。Lua 总是会创建出，不带元表的新表：



```lua
t = {}
print(getmetatable(t))      --> nil
```

我们可以使用 `setmetatable`，来设置或更改某个表的元表：


```lua
t1 = {}
setmetatable(t, t1)
assert(getmetatable(t) == t1)
```

在 Lua 中，我们只能设置表的元表；要操作其他类型值的元表，我们必须使用 C 代码，或调试库。(这一限制的主要原因，是为了限制宽类型元表的过度使用，to curb excessive use of type-wide metables。一些老版本 Lua 的经验表明，这些全局设置，经常会导致不可重用的代码。）字符串库为字符串设置了元表；所有其他类型，默认情况下，均无元表：


```lua
print(getmetatable("hi"))               --> table: 000002634fa4aea0
print(getmetatable("xuxu"))             --> table: 000002634fa4aea0
print(getmetatable(10))                 --> nil
print(getmetatable(print))              --> nil
```

任何的表，都可以是任何值的元表；一组相关的表，可以共用一个描述他们共同行为的共同元表；某个表可以是他自己的元表，从而用来描述他自己的单独行为。任何的配置，都是有效的。


## 算术的元方法

**Arithmetic Metamethods**


在这一小节中，我们将引入一个运行示例，来解释元表的基础知识。假设我们有个使用表来表示集合，并使用函数来计算集合的并集、交集等的模组，如下 [图 20.1，“一个简单的集合模块”](#f-20.1) 所示。


<a name="f-20.1">**图 20.1，一个简单的集合模组**</a>


```lua
local Set = {}

-- 以给定列表，创建出一个新的集合
function Set.new (l)
    local set = {}
    for _, v in ipairs(l) do set[v] = true end
    retur set
end

function Set.union (a, b)
    local res = Set.new{}
    for k in pairs(a) do do res[k] = true end
    for k in pairs(b) do do res[k] = true end
    return res
end

function Set.intersection (a, b)
    local res = Set.new{}
    for k in pairs(a) do
        res[k] = b[k]
    end
    return res
end


-- 将集合表示为字符串
function Set.tostring (set)
    local l = {}    -- 将该集合中全部元素放入的列表
    for e in pairs(set) do
        l[#l + 1] = tostring(e)
    end
    return "{" .. table.concat(l, ", ") .. "}"
end

return Set
```


现在，我们打算使用加法运算符，来计算两个集合的并集。为此，我们将安排所有代表集合的表，共享某个元表。这个元表将定义出，他们对加法运算符的反应。我们的第一步，是创建出一个常规表，并将其用作集合的元表：


```lua
local mt = {}       -- 集合的元表
```


下一步是修改创建出集合的 `Set.new`。新版本只多了将 `mt`，设置为其所创建出表的元表的一行：


```lua
function Set.new (l)        -- 第二版
    local set = {}
    setmetatable(set, mt)
    for _, v in ipairs(l) do set[v] = true end
    retur set
end
```


自那以后，我们使用 `Set.new` 创建的每个集合，都将以那同一个表，作为其元表：


```lua
s1 = Set.new{10, 20, 30, 50}
s2 = Set.new{30, 1}
print(getmetatable(s1))         --> table: 000002ade230b160
print(getmetatable(s2))         --> table: 000002ade230b160
```

最后，我们将 *元方法，metamethod* `__add`，一个描述如何执行加法运算的字段，添加到那个元表：


```lua
mt.__add = Set.union
```

自那以后，每当 Lua 尝试加上两个集合时，他都会调用 `Set.union`，并将两个操作数，作为参数。

有了这个元方法，我们就可以使用加法运算符，来完成集合的并集运算：


```lua
s3 = s1 + s2
print(Set.tostring(s3))         --> {1, 30, 10, 20, 50}
```

类似地，我们也可以将乘法运算符，设置为执行集合的交集运算：


```lua
mt.__mul = Set.intersection

print("s1 x s2 = ", Set.tostring(s2 * s1))  --> {30}
```

对于每个算术运算符，都有一个元方法名字与之对应。除加法和乘法外，还有：

- 减法（`__sub`）

- 浮除，float division（`__div`）

- 底除，floor division（`__idiv`）

- 求反，negation（`__unm`）

- 取模，modulo（`__mod`）

- 及幂运算（`__pow`）

同样，所有位操作，也都有相应的元方法：

- 位与操作，AND (`__band`)

- 或，OR (`__bor`)

- 异或，OR (`__bxor`)

- 非，NOT (`__bnot`)

- 左移位 (`__shl`)

- 右移位 (`__shr`)

我们还可以用（元表中的）字段 `__concat`，来定义连接运算符（`..`）的行为。


> **译注**：Lua 的这种元表与元方法的特性，与 Rust 中 [运用特质实现运算符重载](https://doc.rust-lang.org/rust-by-example/trait/ops.html) 类似。


在我们将两个集合相加时，不存在使用哪种元表的问题。不过，我们可能会编写一个，混合了两个有着不同元表的值的表达式，例如像这样：

```lua
s = Set.new{1, 2, 3}
s = s + 8
```

在查找元方法时，Lua 会执行以下步骤：在第一个值有着带有所需元方法的元表时，那么 Lua 就会独立于第二个值，而使用这个元方法；否则，在第二个值有着带有所需元方法的元表时，Lua 就会使用这个元方法；否则，Lua 就会抛出错误。因此，最后这个示例，与表达式 `10 + s` 和 `"hello" + s` 一样，都将调用 `Set.union`（因为数字和字符串，都没有元方法 `__add`）。

Lua 不会关心这些混合类型，但我们的实现会关心。如果我们运行 `s = s + 8` 那个示例，我们会得到函数 `Set.union` 内部的一个报错：

```console
bad argument #1 to 'for iterator' (table expected, got number)
```

如果我们想要获得更清晰的错误信息，就必须在尝试执行该运算前，显式检查操作数的类型，例如使用下面这样的代码：

```lua
    if getmetatable(a) ~= mt or getmetatable(b) ~= mt then
        error("attempt to 'add' a set with a non-set value", 2)
    end

    -- as before
```

请记住，`error` 的第二个参数（本例中为 `2`），会将错误信息中的源位置，设置到调用该运算的代码。

> **注意**：这句话的意思，是说报错本来是在 `mod_sets` 模组中，但因为这个第二参数 `2`，最终的报错输出，会显示为导入该模组的程序中。实际输出为：

```console
lua: ./arithmetic_metamethod.lua:16: attempt to 'add' a set with a non-set value
stack traceback:
        [C]: in function 'error'
        ./mod_sets.lua:14: in function 'mod_sets.union'
        ./arithmetic_metamethod.lua:16: in main chunk
        [C]: in ?
```

> 表示在 `arithmetic_metamethod.lua` 的第 16 行出错，该行正是调用了 `Set.union` 的 `s = s + 8` 语句。


## 关系型元方法

**Relational Metamethods**


元表还可以通过元方法

- `__eq` (等于)；

- `__lt` (小于)；

- 和 `__le` (小于等于)

而赋予这些关系运算符以意义。其他三个关系运算符，则没有单独的元方法： Lua 会

- 把 `a ~= b` 转换为 `not (a == b)`；

- 把 `a > b` 转换为 `b < a`；

- 把`a >= b` 转换为 `b <= a`。

在旧有版本中，Lua 曾通过把 `a <= b`，转换为 `not (b < a)`，把所有顺序运算符，order operators，都转换为单个运算符。然而，在我们有着其中的全部元素，并非都是恰当排序的类型，这种 *部分序，partial order* 时，这样的转换是不正确的。例如，由于非数值，Not a Number，`NaN` 值的存在，大多数机器都没有浮点数的一种总顺序，a total order for floating-point numbers。根据 IEEE 754 标准，`NaN` 表示未定义的值，例如 `0/0` 的结果。这意味着 `NaN <= x` 总是假，而 `x < NaN` 也是假。这也意味着在这种情况下，从 `a <= b` 到 `not (b < a)` 的转换，是无效的。

在我们那个集合的例子中，我们有着类似的问题。集合中 `<=` 的一个显而易见（而且有用）的含义，便是是集合的包含关系：`a <= b` 表示 `a` 是 `b` 的子集。因此，我们必须同时实现 `__le`（ *小于* 或 *等于*，子集关系）以及 `__lt`（*小于，less than*，恰当的那种子集关系）：


```lua
mt.__le = function (a, b)       -- 子集
    for k in pairs(a) do
        if not b[k] then return false end
    end
    return true
end

mt.__lt = function (a, b)       -- 恰当的子集
    return a <= b and not (b <= a)
end
```

最后，通过集合的包含关系，我们可以定义出集合的相等：

```lua
mt.__eq = function (a, b)
    return a <= b and b <= a
end
```

有了这些定义后，我们就可以比较集合了：


```lua
s1 = Set.new{2, 4}
s2 = Set.new{2, 10, 4}
print(s1 <= s2)         --> true
print(s1 < s2)          --> true
print(s1 >= s2)         --> false
print(s1 > s2)          --> false
print(s1 == s2 * s1)    --> true
```

相等比较有着一些限制。如果两个对象具有不同的基本类型，则相等操作会导致 `false`，甚至不调用任何元方法。因此，无论其元方法如何，集合始终会与某个数字不同。


## 库定义的元方法

**Library-Defined Metamethods**


到目前为止，我们看到的所有元方法，都是属于 Lua 核心的。虚拟机会检测到某项操作中涉及到的值，有着对该操作元方法的元表。不过，由于元表是常规表，从而任何人都可以使用他们。因此，在元表中定义和使用库自己的一些字段，便是库的常见做法。


函数 `tostring` 就提供了个典型的例子。正如我们前面看到的，`tostring` 以一种相当简单的格式，表示表：

```lua
print({})       --> table: 00000223d28cafc0
```

函数 `print` 总是会调用 `tostring`，来格式化其输出。然而，在格式化任何值时，`tostring` 会首先检查，该值是否有个 `__tostring` 元方法。在这种情况下，`tostring` 会将该对象作为参数，传递调用这个元方法完成其工作。这个元方法返回的结果，就是 `tostring` 的结果。


在上面的集合示例中，我们已经定义了一个，将集合显示为字符串的函数。因此，我们只需在元表中设置 `__tostring` 字段：


```lua
mt.__tostring = Set.tostring
```

此后，每当我们以某个集合为参数，调用 `print` 时，`print` 都会调用 `tostring`，而 `tostring` 又会调用 `Set.tostring`：


```lua
s1 = Set.new{10, 4, 5}
print(s1)       --> {10, 5, 4}
```


函数 `setmetatable` 和 `getmetatable`，也用到了一个元字段，这种情形下，是为了保护元表。假设我们打算保护咱们的集合，进而用户既不能看到也不能更改他们的元表。如果我们在元表中，设置了一个 `__metatable` 字段，那么 `getmetatable` 将返回该字段的值，而 `setmetatable` 将抛出错误：


```lua
local MT_HASH = "V8K4Rwux72nEYFfSDTWmCp"

s1 = Set.new{}
print(getmetatable(s1))     --> V8K4Rwux72nEYFfSDTWmCp
setmetatable(s1, {})
    -->  stdin:30: cannot change a protected metatable
```

> **译注**：这里对 `mt.__metatable` 使用了一次性密码网站生成的随机密码，类似于 UUID 值。

自 Lua 5.2 起，`pairs` 也有了元方法，这样我们就可以修改表的遍历方式，并为非表对象，添加遍历行为。当某个对象有 `__pairs` 元方法时，`pairs` 将调用他，来完成其所有工作。


## 表访问元方法

**Table-Access Metamethods**

算术运算符、位运算符和关系运运算符的元方法，都是为其他错误情形，而定义行为；他们不会改变语言的正常行为。Lua 还为两种正常情况，即访问与修改表中的缺失字段，提供了改变表行为的方法。


### `__index` 方法

早先我们曾看到，当我们访问表中不存在的字段时，结果为 `nil`。这是事实，但并非全部的事实。实际上，这种访问会触发解释器，寻找一个 `__index` 元方法：如果没有这种方法（通常就会发生这种情况），则该访问就会导致 `nil`；否则，这个元方法将提供结果。


这里的典型示例，就是继承。假设我们打算创建几个描述视窗的表。每个表必须描述几个视窗的参数，如位置、大小、配色方案等等。所有这些参数都有默认值，因此我们希望只给出非默认参数，来构建视窗对象。第一种方法，是提供一个填充缺失字段的构造器。第二种方法，是安排新视窗，从某个原型的视窗，*继承，inherit* 任何缺失的字段。首先，我们要声明出原型：


```lua
-- 以一些默认值，创建出原型
prototype = {x = 0, y = 0, width = 100, height = 100}
```

然后，我们要定义一个，创建出共用了某个元表的新视窗的构造器函数：


```lua
local mt = {}       -- 创建一个元表

-- 声明出构造器函数
function new (o)
    setmetatable(o, mt)
    return o
end
```

现在，我们定义要定义出这个 `__index` 元方法：


```lua
mt.__index = function (_, key)
    return prototype[key]
end
```

在这段代码之后，我们创建出某个新视窗，并查询其中是否有缺失字段：


```lua
w = new{x=10, y=20}
print(w.width)      --> 100
```

Lua 会检测到，`w` 没有那个请求的字段，但有个带有 `__index` 字段的元表。因此，Lua 会以参数是 `w`（表）和 `"width"`（缺失的键），调用这个 `__index` 元方法。该元方法接着会以所给的键，索引那个原型，并返回结果。


`__index` 元方法用于继承用途，是如此普遍的，以至于 Lua 提供了一种快捷方式。尽管被称作一个 *方法，method*，`__index` 元方法却无需是个函数：相反，他可以是个表。当他是个函数时，Lua 会使用表和缺失键，作为参数来调用他，正如我们刚才所看到的。当他是个表时，Lua 会在这个表中，重新进行那个访问。因此，在上一示例中，我们可以像下面这样，简单地声明出 `__index`：


```lua
mt.__index = prototype
```

现在，当 Lua 要查找元表的 `__index` 字段时，他会找到是个表的 `prototype` 值。因此，Lua 会在这个表中，重复该访问，即执行与 `prototype["width"]` 等价的操作。这次访问就得到了所需的结果。


将某个表作为一个 `__index` 元方法这种用法，提供了单一继承的一种快速且简单的方法。函数虽然成本较高，却提供了更大的灵活性：我们可以实现多重继承、缓存及其他一些变体。我们将在第 21 章，[面向对象编程](oop.md) 中，在我们将介绍面向对象编程时，讨论到这些继承形式。


当我们打算在不调用其 `__index` 元方法下，访问某个表时，我们要使用 `rawget` 函数。调用 `rawget(t, i)` 可以对表 `t`，进行 *原始，raw* 访问，即不考虑元表的一种原语访问，a primitive access。进行原始访问，不会加快我们代码（函数调用的开销，会抹杀我们可能获得的任何收益），但有时我们需要他，正如我们稍后将看到的那样。


### `__newindex` 元方法

**The `__newindex` metamethod**


`__newindex` 元方法对表更新的作用，就像 `__index` 对表访问的作用一样。当我们为表中某个缺失的索引赋值时，解释器会查找 `__newindex` 元方法：如果有，解释器就会调用他,而不是进行赋值。与 `__index` 一样，如果元方法是一个表，解释器就会在这个表中，而不是在原来的表中进行赋值。此外，还有个允许我们绕过这个元方法的原始函数：在无需调用任何元方法下，调用 `rawset(t, k, v)` 即相当于 `t[k] = v`。

结合使用 `__index` 和 `__newindex` 两个元方法，便可以在 Lua 中实现多种强大结构，如只读表、带默认值的表，以及面向对象编程的继承。在本章中，我们将看到其中的一些用途。稍后，面向对象编程将有自己的一章。


### 带默认值的表

**Tables with default values**


常规表中的任何字段，默认值都是 `nil`。使用元表，便可轻松更改默认值：

```lua
function setDefault (t, d)
    local mt = {__index = function () return d end}
    setmetatable(t, mt)
end

tab = {x=10, y=20}
print(tab.x, tab.z)         --> 10      nil
setDefault(tab, 0)
print(tab.x, tab.z)         --> 10      0
```


在其中到 `setDefault` 的调用后，对 `tab` 中某个缺失字段的任何访问，都会调用其 `__index` 元方法，其就会返回零（这个元方法的 `d` 值）。

> **译注**：若把该元方法的 `d` 改为 `s`，就不会生效（仍然会返回 `nil`）。故可认为 Lua 将 `d` 硬编码到了其解释器中。


那个函数 `setDefault`，创建了个新的闭包，以及给到需要某个默认值的各个表的一个新元表。在有很多表都需要默认值时，这样做的成本会很高。然而，元表将其中的默认值 `d`，连接到了他的元方法，因此我们无法为具有不同默认值的表，使用单一的元表。为了让所有表都能使用单一元表，我们可使用某个独占字段，将每个表的默认值，存储在表本身中。在不用担心名字冲突下，我们可以使用类似 `"____"` 的键，作为独占字段：


```lua
local mt = {__index = function (t) return t.___ end}
function setDefault (t, d)
    t.___ = d
    setmetatable(t, mt)
end
```

请注意，现在我们只在 `SetDefault` 之外，创建了一次元表 `mt` 及其相应的元方法。


若担心名字冲突，则很容易就能确保，那个特殊键的唯一性。我们只需要用作键的一个新的独占表：


```lua
local key = {}      -- 唯一键
local mt = {__index = function (t) return t[key] end}
function setDefault (t, d)
    t.[key] = d
    setmetatable(t, mt)
end
```


将每个表与其默认值关联起来的另一种方法，是我（作者）称之为 *双重表示，dual representation* 的一种技巧，其要用到其中索引是一些表，值为这些表的默认值的一个单独表。不过，要正确实现这种方法，我们需要称为 *弱表，weak tables* 的一种特殊表，因此我们不会在此使用他；我们将在第 23 章，[垃圾](garbage.md) 中，再讨论这个问题。


另一种方法是 *记住，memorize* 元表，以便在带有相同默认值的那些表中，重用同一个元表。不过，这也需要弱表，所以我们还是要等到，在第 23 章 [垃圾](garbage.md) 中再讨论。



### 对表访问进行追踪


**Tracking table accesses**


假设我们打算跟踪对某个表的每次访问。只有当表中不存在索引时，`__index` 和 `__newindex` 才有意义。因此，捕捉对表全部访问的唯一方法，就是保持表为空。在我们打算监控对表的所有访问时，就应该为真正的表，创建一个 *代理，proxy*。此代理会是个带有适当元方法，可以跟踪所有访问，并将其重定向到原始表的空表。[图 20.2 中的代码，“跟踪表访问”](#f-20.2)，实现了这一概念。


<a name="f-20.2">**追踪表访问**</a>

```lua
function track (t)
    local proxy = {}        -- `t` 的代理表

    -- 创建代理的元表
    local mt = {
        __index = function (_, k)
            print("*access to element " .. tostring(k))
            return t[k]     -- 访问原始表
        end,


        __newindex = function (_, k, v)
            print("*update of element " .. tostring(k) ..
                " to " .. tostring(v))
            t[k] = v    -- 更新原始表
        end,

        __pairs = function ()
            return function (_, k)      -- 迭代函数
                local nextkey, nextvalue = next(t, k)
                if nextkey ~= nil then      -- 避开最后一个值
                    print("*traversing element " .. tostring(nextkey))
                end
                return nextkey, nextvalue
            end
        end,

        __len = function () return #t end
    }

    setmetatable(proxy, mt)

    return proxy
end
```

下面的示例演示了其用法：

```console
$ lua -i lib/track.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> t = {}
> t = track(t)
> t[2] = "hello"
*update of element 2 to hello
> print(t[2])
*access to element 2
hello
```

其中元方法 `__index` 和 `__newindex` 遵循了我们所设定的准则，跟踪每次访问，然后将其重定向到原始表。通过 `__pairs` 元方法，我们可以像遍历原始表一样遍历代理表，同时跟踪这些访问。最后，`__len` 元方法通过代理表，提供了长度运算符：


```console
$ lua -i lib/track.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> t = track({10, 20})
> print(#t)                                                                                                    2
> for k, v in pairs(t) do print(k, v) end
*traversing element 1
1       10
*traversing element 2
2       20
```

如果我们想监控多个表，就不需要为每个表使用不同元表。相反，我们可以通过某种方式，将每个代理表映射到其原始表，并为所有代理表共用一个共同的元表。这个问题与我们在上一节讨论过的，将表与其默认值关联起来的问题类似，而可以采用相同的解决方案。例如，我们可以使用独占键，在某个代理表字段中保留原始表，或者使用双重表示法，a dual representation，将每个代理表映射到其对应的表。


### 只读表

**Read-only tables**


运用代理表的概念，实现只读表非常简单。我们所要做的就是，每当我们跟踪到任何更新表的尝试时，就抛出一个错误。对于 `__index` 元方法，我们可以使用一个表 -- 原始表本身 -- 而不是函数，因为我们不需要跟踪查询；将所有查询重定向到原始表会更简单、更有效。这种用法要求为每个只读代理表，创建一个新的元表，其中 `__index` 指向原始表：


```lua
function readOnly (t)
	local proxy = {}

	local mt = { -- 创建元表
	    __index = t,
    	__newindex = function (t, k, v)
		    error("attempt to update a read-only table", 2)
	    end
    }

    setmetatable(proxy, mt)
    return proxy
end
```


举例来说，我们可以创建一个工作日只读表：


```console
$ lua -i lib/read_only.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> days = readOnly{"周日", "周一", "周二", "周三", "周四", "周五", "周六"}
> print(days[1])
周日
> days[2] = "星期八"
stdin:1: attempt to update a read-only table
stack traceback:
        [C]: in function 'error'
        lib/read_only.lua:7: in metamethod 'newindex'
        stdin:1: in main chunk
        [C]: in ?
```


## 练习

练习 20.1：请为集合定义一个返回两个集合差值的元方法 `__sub`；(集合 `a - b` 是 `a` 中不在 `b` 中的元素集合。）

练习 20.2：请为集合定义一个元方法 `__len`，使 `#s` 返回集合 `s` 中的元素个数；

练习 20.3：实现只读表的另一种方法，是使用一个函数作为 `__index` 元方法。这种方法的访问开销较高，而创建只读表的成本较低，因为所有只读表都可以公用一个元表。请使用这种方式重写函数 `readOnly`；


练习 20.4：代理表可以表示表格以外的其他类型对象。 请编写一个取文件名做参数，并返回该文件的代理的函数 `fileAsArray`，这样在调用 `t = fileAsArray("myFile")` 之后，访问 `t[i]` 返回该文件的第 `i` 个字节，并在赋值给 `t[i]`  时更新其第 `i` 个字节；


练习 20.5：请扩展前面的示例，实现使用 `pairs(t)` 遍历文件中的字节，使用 `#t` 获取文件长度。
