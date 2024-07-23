# 数据结构


Lua 中的表，不属于某种数据结构，而 *就* 是数据结构本身，tables in Lua are not a data structure; they are *the* data structure。以 Lua 中的表，咱们可以表示其他语言所提供的全部结构 -- 数组 arrays、记录 records、列表 lists、队列 queues、集合 sets 等等。此外，Lua 表还能高效地实现，全部这些结构。


在 C 和 Pascal 等传统语言中，我们会以数组和列表（列表 = 记录 + 指针），来实现大多数数据结构。虽然我们可以使用 Lua 表，来实现数组和列表（有时我们也这样做），但表要比数组和列表更强大；使用表后，许多算法都简化到了微不足道的地步。例如，我们很少在 Lua 中编写某种搜索，因为表提供了对任何类型的直接访问。


掌握如何高效地使用表，需要一点时间。本章，我们将介绍如何使用表，实现一些典型的数据结构，并举例说明其用途。我们将从数组和列表开始，这并非因为其他结构需要他们，而是因为大多数程序员已经熟悉他们。(我们已经在第 5 章 [*表*](tables.md) 中，了解了这方面的基础知识，但为了完整起见，我（作者）还是在此重复一遍。）随后，我们将继续一些更高级的示例，如集合 sets、包 bags 以及图 graphs。


## 数组

我们中简单地通过用整数索引表，来实现 Lua 中的数组。因此，数组没有固定的大小，而是根据需要增长。通常，当我们初始化数组时，我们间接地定义了其大小。例如，在以下代码之后，任何访问 1-1000 范围之外字段的尝试,都将返回 `nil`，而不是零：

```lua
local a = {}                    -- 新建数组
for i = 1, 1000 do
    a[i] = 0
end

print(#a, a[#a], a[#a + 5])     --> 1000    0       nil
```

长度运算符 (`#`) 就运用这一事实，来查找数组的大小：


```lua
print(#a)           --> 1000
```

我们可以从索引零、一或任何其他值，开始某个数组：


```lua
-- 创建一个索引为 -5 到 5 的数组
a = {}
for i = -5, 5 do
    a[i] = 0
end
```

然而，Lua 中习惯以索引一，开始数组。 Lua 库遵循了这个惯例；长度运算符也是如此。如果咱们的数组不以一开头，我们将无法使用这些设施。


我们可以使用构造器，a constructor，在单个表达式中，创建并初始化某个数组：

```lua
squares = {1, 4, 9, 16, 25, 36, 49, 64, 81}
```

这样的构造器可以很大，可以根据需要设置很多元素。在 Lua 中，有着数百万元素的数据描述文件，并不少见。


## 矩阵与多维数组

Lua 中表示矩阵的主要方法有两种。第一种是 *交错数组，jagged array*（数组的数组），即一个表，其中每个元素均为另一个表。例如，咱们可以使用以下代码，创建出维度为 **N** × **M** 的一个零的矩阵：


```lua
local mt = {}           -- 创建矩阵
for i = 1, N do
    local row = {}      -- 创建一个新行
    mt[i] = row
    for j = 1, M do
        row[j] = 0
    end
end
```

因为表属于 Lua 中的一些对象，所以我们必须显式创建出每一行，来构建出矩阵。一方面，这肯定比咱们在 C 中所做的那样，简单地声明出矩阵，更为繁琐；另一方面，其带给了我们，更多的灵活性。例如，我们可以通过将前面示例中的内部循环，更改为 `for j=1,i do ... end`，而创建出三角矩阵，a triangular matrix。此代码下，三角矩阵仅会使用原先矩阵的一半内存。

表示矩阵的第二种方式，是将两个索引，组合成一个索引。通常，我们是通过将第一个索引，乘以合适的常数，然后加上第二个索引，实现这种方式。运用这种方法，以下代码将创建出，维度为 **N** × **M** 的零的矩阵：


```lua
local mt = {}           -- 创建矩阵
for i = 1, N do
    local aux = (i - 1) * M
    for j = 1, M do
        mt[aux + j] = 0
    end
end
```

通常，应用程序会用到 *稀疏矩阵，sparse matrix*，即一种其中大多数元素为零，或 `nil` 的矩阵。例如，我们可以用其邻接矩阵，来表示某个图，represent a graph by its adjacency matrix，当节点 *m* 和 *n* 之间存在开销为 *x* 的连接时，邻接矩阵的位置 *(m,n)* 的值，便是 *x*。当这两个节点没有连接时，位置 *(m,n)* 的值,便是 *nil*。要表示一张有着一万个节点，其中每个节点大约有五个邻居的图，我们将需要有着一亿条目的矩阵（有着 10000 列和 10000 行的方形矩阵），而大约只有五万个条目，不会为零（每行五个对应着节点五个邻居的非 `nil` 列）。很多数据结构方面的书籍，都详细讨论了如何在不浪费 800MB 内存下，实现这样的稀疏矩阵，但在以 Lua 编程时，咱们很少需要这些技巧。因为我们是用表，来表示数组，所以他们自然是稀疏的。在我们的第一种表示法（表的表）下，我们将需要一万个表，每个表大约有五个元素，总共有五万个条目。在第二种表示法下，我们将有一个，其中有着五万条目的表。无论哪种表示形式，我们需要的，只是那些非 `nil` 元素的空间。

在稀疏矩阵上，咱们无法使用长度运算符（`#`），因为活动条目之间存在空洞（`nil` 值）。这并不是什么大损失；即使可以使用他，我们可能不大会使用。对于大多数操作，遍历全部这些空条目，是非常低效的。相反，我们可以使用 `pairs`，来只遍历非 `nil` 元素。作为示例，咱们来看看，如何对由交错数组表示的稀疏矩阵，完成矩阵乘法。

假设我们要将矩阵 **a[M,K]**，与矩阵 **b[K,N]** 相乘，生成矩阵 **c[M,N]**。通常的矩阵乘法算法如下：

```lua
for i = 1, M do
    for j = 1, N do
        c[i][j] = 0
        for k = 1, K
            c[i][j] = c[i][j] + a[i][k] * b[k][j]
        end
    end
end
```

两个外层循环，会遍历整个结果矩阵，而对于每个元素，那个内部循环，会计算出其值。

对于交错数组的稀疏矩阵，这个内部循环便是个问题。因为他会遍历 **b** 的列，而非行，所以我们不能在这里使用类似 `pairs` 的东西：循环必须访问每一行，查看该行是否在那个列中具有元素。与只访问少数非零元素相反，这个循环还访问了全部零的元素。 （在其他上下文中，便利列也可能是一个问题，因为其空间局部性的缺失，loss of spatial locality。）

下面的算法与前一个算法非常相似，但他颠倒了两个内部循环的顺序。通过这个简单的更改，他可以避免遍历列：

```lua
-- 假定 'c' 的全部元素均为零
for i = 1, M do
    for k = 1, K
        for j = 1, N do
            c[i][j] = c[i][j] + a[i][k] * b[k][j]
        end
    end
end
```

现在，中间那个循环遍历行了行 `a[i]`，内层循环遍历了行 `b[k]`。两个循环都可以使用 `pairs`，仅访问非零元素。所得矩阵 **c** 的初始化，在这里不是问题，因为空的稀疏矩阵，自然会用零填充。


<a name="f-14.1">**图 14.1，稀疏矩阵的乘法**</a>

```lua
function Lib.mt_mult (a, b)
    local c = {}        -- 得到的矩阵
    for i = 1, #a do
        local resultline = {}                   -- 将是 'c[i]'
        for k, va in pairs(a[i]) do             -- 'va' 为 a[i][k]
            for j, vb in pairs(b[k]) do         -- 'vb' 为 b[k][j]
                local res = (resultline[j] or 0) + va * vb
                resultline[j] = (res ~= 0) and res or nil
            end
        end
        c[i] = resultline
    end
    return c
end
```

[图 14.1，“稀疏矩阵的乘法”](#f-14.1) 给出了上面算法的完整实现，用到了 `pairs`，并顾及到了那些稀疏条目。这个实现只会访问那些非 `nil` 的元素，结果自然是稀疏的。此外，代码会删除偶然计算出为零的那些结果条目。


## 链表

**Linked Lists**


因为表属于动态实体，所以在 Lua 中实现链表很容易。我们用一个表，来表示每个节点（不然？）；链接就只是一些，包含了对其他表引用的字段。例如，咱们来实现一个单链表，a singly-linked list，其中每个节点，都有两个字段：`value` 和 `next`。一个简单的变量，为该列表的根，the list root：


```lua
list = nil
```

要在列表开头，插入一个值为 `v` 的元素，我们这样做：

```lua
list = {next = list, value = v}
```

要遍历列表，我们可以这样写：

```lua
local l = list
while l do
    visit l.value
    l = l.next
end
```

我们还可以轻松实现，一些其他类型的列表，例如双链表或循环列表，doubly-linked lists or circular lists。不过，在 Lua 中，我们很少需要这些结构，因为通常有更简单的方法，来表示我们的数据，而无需使用链表。例如，我们可以用（无边界）数组，来表示堆栈，represent a stack with an (unbounbed) array。


## 队列和双端队列

**Queues and Double-Ended Queues**

在 Lua 中实现队列的一种简单方法，是使用表库中的 `insert` 和 `remove` 函数。正如我们在 [“表库”](tables.md#关于表库) 一节中所看到的，这两个函数会在数组的任意位置，插入和移除元素，同时移动其他元素，以满足操作。然而，对于大型结构而言，这些移动的代价可能会很高。一种更有效的实现方法，是使用两个索引，一个表示首个元素，另一个表示最后一个元素。如下 [图 14.2 “双端队列”](#f-14.2) 所示，在这种表示方法下，我们就可以在恒定时间，插入或移除两端的元素。



<a name="f-14.2">**图 14.2 双端队列**</a>

```lua
function listNew ()
    return {first = 0, last = -1}
end

function pushFirst (list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end

function pushLast (list, value)
    local last = list.last + 1
    list.last = last
    list[last] = value
end

function popFirst (list, value)
    local first = list.first
    if first > list.last then error("list is empty") end
    local value = list[first]
    list[first] = nil       -- 以允许垃圾回收，to allow garbage collection
    list.first = first + 1
    return value
end

function popLast (list, value)
    local last = list.last
    if list.first > last then error("list is empty") end
    local value = list[last]
    list[last] = nil       -- 以允许垃圾回收，to allow garbage collection
    list.last = last - 1
    return value
end
```


如果我们以严格队列规则，使用此结构，即只调用 `pushLast` 和 `popFirst`，那么 `first` 和 `last` 都会不断增加。不过，由于我们在 Lua 中，使用了表来表示数组，因此我们既可以从 1 到 20，也可以从 16,777,201 到 16,777,220，对数组进行索引。在 64 位整数下，在每秒插入 1000 万次时，这样一个队列可以运行三万年，然后才会出现溢出问题。


## 反转表

**Reverse Tables**


正如我（作者）之前所说，我们很少在 Lua 中进行搜索/检索。相反，我们使用所谓的索引表或反向表，an index or a reverse table。

假设我们有一个有着，一周中各天名字的表：


```lua
days = {"Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"}
```

现在，我们打算把某个名字，转换成他在一周中的位置。我们可以在表中，搜索给定的名称。不过，一种更有效的方法，是建立一个比方说 `revDays` 的，将名称作为索引，将数字作为值的反向表。这个表看起来是这样的：

```lua
revDays = {["Sunday"] = 1, ["Monday"] = 2,
           ["Tuesday"] = 3, ["Wednesday"] = 4,
           ["Thursday"] = 5, ["Friday"] = 6,
           ["Saturday"] = 7}
```

那么，我们只需要索引这个反向表，即可找到某个名称的顺序：

```lua
x = "Tuesday"
print(revDays[x])       --> 3
```

当然，我们不需要手动声明那个反向表。我们可以根据原始表，自动创建出他：


```lua
revDays = {}
for k, v in pairs(days) do
    revDays[v] = k
end
```

其中的循环，将就 `days` 的每个元素，进行赋值，变量 `k` 会获得键（`1`、`2`、......），`v` 获得值（ `"Sunday"`、`"Monday"`，......）。


## 集合与包

**Sets and Bags**


假设我们打算列出某个程序源代码中，用到的所有标识符；为此，我们需要从咱们的列表中，过滤出那些保留字。一些 C 语言程序员，可能会倾向于用字符串数组，来表示保留字的集合，并通过搜索该数组，来获悉某个给定的单词，是否在该集合中。要加快搜索速度，他们甚至可以使用二叉树，a binary tree，来表示这个集合。


在 Lua 中，表示此类集合的一种高效而简单的方法，是将集合元素作为 *索引，indices* 放在表中。这样，我们就不用在表中，搜索给定的元素，而只需索引表，并测试结果是否为 `nil`。在咱们的示例中，我们可以编写下面的代码：


```lua
reserved = {
    ["while"] = true, ["if"] = true,
    ["else"] = true, ["do"] = true,
}

for w in string.gmatch(s, "[%a_][%w_]*") do
    if not reserved[w] then
        do somthing with 'w'    -- 'w' 不是保留字
    end
end
```

(在 `reserved` 的定义中，我们不能写下 `while = true`，因为在 Lua 中，`while` 不是一个有效的名称。相反，我们使用了 `["while"] = true` 的写法。）


使用一个辅助函数，来构建这个集合，咱们就可以有一个，更清晰的初始化了：

```lua
function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

reserved = Set {"while", "end", "function", "local", }
```

我们还可以使用另一个集合，来收集标识符：

```lua
local ids = {}
for w in string.gmatch(s, "[%a_][%w_]*") do
    if not reserved[w] then
        ids[w] = true
    end
end

-- 每个标识符打印一次
for w in pairs(ids) do print(w) end
```

包，也称为 *多重集，multisets*，不同于常规集合之处在于，其中的每个元素，都可以出现多次。 Lua 中包的简单表示，类似之前的集合表示，但每个键，都有个关联的计数器。<sup>1</sup> 要插入某个元素，我们就会递增其计数器：


> **注 1**：我们已经在第 11 章，[“插曲：高频词”](interlude_most_frequent_words.md) 中，将这种表示法，用于那个最常见的单词程序。

```lua
function insert (bag, element)
    bag[element] = (bag[element] or 0) + 1
end
```

而要删除一个元素，我们就会递减其计数器：

```lua
function remove (bag, element)
    local count = bag[element]
    bag[element] = (count and count > 1) and count - 1 or nil
end
```

只有在计数器已经存在，且仍大于零时，我们才保留该计数器。


## 字符串缓冲

**String Buffers**


假设我们正在逐步构建一个字符串，例如逐行读取某个文件。我们的典型代码，可能如下所示：


```lua
local buff = ""
for line in io.lines() do
    buff = buff .. line .. "\n"
end
```

尽管他看起来无害，despite its innocent look，但Lua 中的这段代码，对于大文件可能会造成巨大的性能损失：例如，在我（作者）的新机器上，读取一个4.5 MB 的文件，需要超过 30 秒。

这是为什么呢？为了理解发生了什么，我们就要来设想一下，我们正处于那个读取循环的中间；每行有 20 个字节，咱们已经读取了大约 2500 行，所以 `buff` 就是是个 50 kB 的字符串了。当 Lua 连接 `buff..line.."\n"` 时，他就会分配一个 50020 字节的新字符串，并将 `buff` 中的 50000 字节，复制到这个新字符串中。也就是说，对于每一个新行，Lua 都会移动大约 50 kB 的内存，并且还在不断增加。这个算法是次方开销的。读取 100 个新行（仅 2 kB）后，Lua 就已经移动了，超过 5 MB 的内存。当 Lua 读取完 350 kB 时，他已经移动了大约 50 GB 左右的内存。 （这个问题并不是 Lua 特有的：其他那些，其中字符串为不可变值的语言，也存在类似的行为，Java 就是一个著名的例子。）


在咱们继续之前，我们应该指出，尽管我说了这么多，这种情况却并不是个常见问题。对于那些小的字符串，上面的循环没有什么问题。Lua 为读取整个文件，提供了一次性读取文件的 `io.read("a")` 选项。然而，有时我们必须面对这个问题。 Java 提供了 `StringBuffer` 类来改善这个问题。在 Lua 中，我们可以使用表作为字符串缓冲区。这种方法的关键，是函数 `table.concat`，他会返回给定列表中，所有字符串的连接。使用 `concat`，我们可以将之前的循环，编写如下：

```lua
local = {}
for line in io.lines() do
    t[#t + 1] = line .. "\n"
end
local s = table.concat(t)
```

使用原先代码读取需要半分钟以上的同一文件，这种算法只需不到 0.05 秒即可读取。（尽管如此，为了读取整个文件，最好使用带有 `"a"` 选项的 `io.read`。）

我们甚至可以做得更好。函数 `concat` 会取个可选，在字符串之间，要插入的分隔符的第二个参数。使用这个分隔符，我们就不需要在每行后面，插入换行符了：

```lua
local t = {}
for line in f:lines() do
    t[#t + 1] = line
end
local s = table.concat(t, "\n") .. "\n"
```

该函数会在字符串之间，插入分隔符，但我们仍然不得不，添加最后那个换行符。最后的连接，创建了一个结果字符串的新副本，该副本可能会很长。并无可以让 `concat` 插入这个额外分隔符的选择，但我们可以欺骗他，在 `t` 中，插入一个额外的空字符串：

```lua
local t = {}
for line in f:lines() do
    t[#t + 1] = line
end
t[#t + 1] = ""
local s = table.concat(t, "\n")
```

现在，`concat` 在这个空字符串之前，添加的额外换行符，就位于结果字符串的末尾了，这正如我们所希望的那样。


## 图数据结构

**Graphs**

> **注**：著名的 [迪杰斯特拉算法，Dijkstra 算法](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm)，就是基于图数据结构。

与其他正式语言一样，Lua 做到了图数据结构的多种实现，每种实现，都能更好地适应某些特定算法。在这里，我们将看到一种简单的，面向对象的实现，其中咱们会将节点，表示为对象（当然，实际上是表），将一些弧形，作为节点之间的引用。


我们将用包含了 `name`（节点名称）和 `adj`（邻接节点的集合），两个字段的表，表示每个节点。由于我们将从文本文件中，读取图，因此我们需要一种根据节点的名称，找到该节点的方法。因此，我们将使用一个将名称映射到节点的额外表。函数 `name2node` 会根据名称，返回相应的节点：


```lua
local function name2node (graph, name)
    local node = graph[name]

    if not node then
        -- 节点不存在；要创建一个新的节点
        node = {name = name, adj = {}}
        graph[name] = node
    end

    return node
end
```

下 [图 14.3 “从文件读取某个图”](#f-14.3) 给出了构建图的函数。



<a name="f-14.3">**图 14.3，从文件读取某个图**</a>


```lua
function readgraph (filename)
    local graph = {}
    local f = assert(filename, "r")

    for line in f:lines() do
        -- 将行拆分为两个名字
        local namefrom, nameto = string.match(line, "(%S+)%s+(%S+)")
        -- 找到相应节点
        local from = name2node(graph, namefrom)
        local to = name2node(graph, nameto)
        -- 将 'to' 添加到 `from` 的邻接集合
        from.adj[to] = true
    end
    f:close()

    return graph
end
```

他会其中每一行都有两个节点名称的文件，这意味着，从第一节点到第二节点之间，有一条弧线。对于每一行，该函数使用了 `string.match`，将该行拆分为两个名字，找出了与这些名字，相对应的节点（在需要时，创建出这些节点），并将节点连接起来。

下 [图 14.4，“找出两个节点之间的路径”](#f-14.4) 演示了运用这种图的一种算法。


<a name="f-14.4">**图 14.4，找出两个节点之间的路径**</a>


```lua
function findpath (curr, to, path, visited)
    path = path or {}
    visited = visited or {}

    if visited[curr] then       -- 节点已被访问过？
        return nil              -- 此处无路径
    end

    visited[curr] = true       -- 将节点标记为已访问过
    path[#path + 1] = curr      -- 将其添加到路径
    if curr == to then          -- 最终节点？
        return path
    end
    -- 尝试全部邻接节点
    for node in pairs(curr.adj) do
        local p = findpath(node, to, path, visited)
        if p then return p end
    end
    table.remove(path)          -- 从路径种移除节点
end
```

函数 `findPath` 采用深度优先遍历法，using a depth-first traversal，搜索两个节点之间的路径。他的第一个参数，是当前节点；第二个参数是目标节点；第三个参数保留了从原节点，到当前节点的路径；最后参数，是个有着所有已访问节点的集合，以避免循环。请注意，该算法是如何直接操作节点，而不使用节点名字的。例如，`visited` 是个节点集合，而不是节点名。同样，`path` 是个节点的列表。


为测试这段代码，我们添加了一个打印路径的函数，以及一些代码，来使其工作：


```lua
function printpath (path)
    for i = 1, #path do
        print(path[i].name)
    end
end

g = readgraph("demo.graph")
a = name2node(g, "a")
b = name2node(g, "b")
p = findpath(a, b)
if p then printpath(p) end
```


## 练习

练习 14.1：请编写一个，将两个稀疏矩阵相加的函数。


练习 14.2：请修改图 14.2，“双端队列” 中的队列实现，实现在队列为空时，两个索引都返回零。


练习 14.3：请修改那个图数据结构，使其能为每条弧，保留一个标签。该数据结构，还应该用带有两个字段：弧的标签，和弧所指向节点，两个字段的对象表示每个弧。每个节点保存的不是邻接节点集合，而是包含了从该节点出发，弧的事件集合，an incident set that contains the ars that originate at that node。


要将函数 `readgraph`，调整为从输入文件的每一行，读取两个节点名字，和以及一个标签。(假设标签是个数字。）


练习 14.4：假定使用前一练习的，其中每个弧的标签，表示该弧两端节点之间的距离。请使用 Dijkstra 算法，编写一个函数，找出两个给定节点之间，最短的路径。
