# 数据文件与序列化

在处理数据文件时，写入数据通常要比回读数据，容易得多。在写入文件时，我们可以完全掌控，正在发生的事情。另一方面，当我们读取文件时，我们并不知道，会得到什么。除了某个正确文件，可能包含的各种数据外，健壮的程序，还应该优雅地处理坏文件。因此，编写出健壮输入例程，总是困难重重。在本章中，我们将了解如何使用 Lua，消除从程序中读取数据的所有代码，只需将数据以适当的格式写入即可。更具体地说，我们会将数据编写成 Lua 程序的形式，当运行这些程序时，就会重建数据。<sup>译注 1</sup>

> **译注 1**：此处原文为：In this chapter, we will see how we can use Lua to eliminate all code for reading data from our programs, simply by writing the data in an appropriate format. More specifically, we write data as Lua programs that, when run, rebuild the data.

自 1993 年创建以来，数据描述，data description，一直是 Lua 的主要应用之一。当时，文本式数据描述语言的主要选择，还是 SGML。<sup>译注 2</sup>对于许多人（包括我们）来说，SGML 既臃肿又复杂。1998 年的时候，一些人对其进行了简化，创建出了 XML，但在我们看来，XML 仍然臃肿而复杂。其他一些人赞同我们的观点，其中一些人又创建出了 JSON（2001 年）。JSON 基于 Javascript，与受限制过后的 Lua 数据文件，restricted Lua data files，非常相似。一方面，JSON 有一个很大的优势，那就是他是个国际标准，而且好几种语言（包括 Lua），都有着操作 JSON 文件的库。另一方面，Lua 的文件，易于读取且更加灵活。

> **译注 2**：标准通过标记语言，Standard Generalized Markup Language。参见：[Wikipedia: SGML](https://en.wikipedia.org/wiki/Standard_Generalized_Markup_Language)。

使用完整编程语言进行数据描述，当然会很灵活，但也带来了两个问题。一个是安全问题，因为 “数据” 文件可以在我们的程序中，肆意运行。我们可以通过在沙箱中运行文件，来解决这个问题，我们将在 [“沙箱”](#沙箱) 小节，讨论这个问题。

另一个问题是性能。Lua 不仅运行速度快，编译速度也很快。例如，在我（作者）的新机器上，Lua 5.3 读取、编译和运行一个，有着 1 千万个赋值的程序，只需 4 秒，使用 240 MB 内存。相比之下，Perl 5.18 需要 21 秒和 6 GB 内存，Python 2.7 和 Python 3.4，则会让机器崩溃，Node.js 0.10.25，会在 8 秒后出现 “内存不足，out of memory” 错误，Rhino 1.7 也会在 6 分钟后，出现 “内存不足” 错误。



## 数据文件

表构造器，table constructor，为文件格式提供了一种有趣的选择。只需在写入数据时，做一点额外的工作，读取数据就会变得轻而易举。方法是将数据文件，写成在运行时，将数据重建到程序中的 Lua 代码，the technique is to write our data file as Lua code that, when run, rebuilds the data into the program。在表构造器下，这些数据块，看起来就像普通的数据文件了。


咱们来看一个例子，来说明问题。如果我们的数据文件，是预定义格式的，如 CSV（Comma-Separated Values）或 XML，我们就没有什么选择。但是，如果我们打算创建自己使用的文件，我们就可以使用 Lua 构造器，作为我们的格式。在这种格式中，我们会将每条数据记录，表示为一个 Lua 构造器。而不是在数据文件中，写入下面这样的内容：


```txt
Donald E. Knuth,Literate Programming,CSLI,1992
Jon Bentley,More Programming Pearls,Addison-Wesley,1990
```


咱们会这样写：

```lua
Entry{"Donald E. Knuth",
"Literate Programming",
"CSLI",
1992}

Entry{"Jon Bentley",
"More Programming Pearls",
"Addison-Wesley",
1990}
```

请记住，`Entry{code}` 与 `Entry({code})` 相同，即调用某个以表为单一参数的函数 `Entry`。因此，前面的数据，就是一个 Lua 程序。要读取该文件，我们只需以 `Entry` 的一种合理定义，运行他即可。例如，下面的程序，会计算数据文件中，条目的数目：

```lua
local count = 0
function Entry () count = count + 1 end

dofile("data")

print("number of entries: " .. count)
```

下一程序则将会把在该文件中找到的所有作者姓名，收集到一个集合中，然后打印出来：


```lua
local authors = {}      -- 收集作者的一个集合
function Entry (b) authors[b[1]] = true end

dofile("data")
for name in pairs(authors) do print(name) end
```

请留意这些程序片段中的，事件驱动方法，the event-driven approach：函数 `Entry` 充当了，在 dofile 过程中，对于数据文件中的每个条目，都会被调用的一个回调函数。


在文件大小不是个大问题时，我们可以为咱们的表示法，使用一些名称-值对：<sup>1</sup>

```lua
Entry{
    author = "Donald E. Knuth",
    title = "Literate Programming",
    publisher = "CSLI",
    year = 1992
}

Entry{
    author = "Jon Bentley",
    title = "More Programming Pearls",
    year = 1990,
    publisher = "Addison-Wesley",
}
```

> **注 1**：如果这种格式让咱们想起 BibTeX，那就不是巧合了。BibTeX 是 Lua 中，构造器语法的灵感来源之一。

这种格式，就是我们所说的，*自描述数据，self-decribing data* 格式，因为每条数据，都附有其含义的简短描述。自描述数据，比 CSV 或其他紧凑记法，都更具可读性（至少，对于人类而言）；在必要时，可以轻松手动编辑他们；同时他们允许咱们，对基本格式进行小的修改，而无需更改数据文件。例如，如果我们添加一个新字段，我们只需要对读取程序，进行很小的更改，从而在该字段不存在时，提供一个默认值。


在名字-值格式下，咱们收集作者的程序，就变成了这样：


```lua
local authors = {}      -- 收集作者的一个集合
function Entry (b) authors[b.author] = true end

dofile("data")
for name in pairs(authors) do print(name) end
```

现在，字段顺序已经无关紧要。即使有些条目没有作者，我们也只需调整一下函数 `Entry` 函数：


```lua
function Entry (b)
    authors[b.author or "unknown"] = true
end
```


## 序列化

**Serialization**


我们经常会需要，将一些数据序列化，也就是将数据，转换成字节流或字符流，以便将其保存到文件中，或通过网络连接发送。我们可以将序列化数据，表示为 Lua 代码，这样当我们运行该代码时，他就会将保存的值，重建到读取的程序中。

通常，在我们打算恢复出，某个全局变量的值时，我们的代码块，就会类似于 <code>varname = <i>exp</i></code> 这种形式，其中 <code><i>exp</i></code>，为创建才该值的 Lua 代码。`varname` 是比较简单的部分，我们来看看，如何编写创建出值的代码。对于数值来说，这项任务非常简单：


```lua
function serialize (o)
    if type(o) == "number" then
        io.write(tonumber(o))
    else other cases
    end
end
```

然而，如果用十进制格式写浮点数，我们就有可能丢失一些精度。我们可以使用十六进制格式，来避免这个问题。使用格式 `("%a")`，读取的浮点数，就将与原始浮点数的位数完全相同。此外，自 Lua 5.3 起，我们应区分整数和浮点数，以便以正确的子类型，还原出他们：


```lua
local fmt = {integer = "%d", float = "%a"}

function serialize (o)
    if type(o) == "number" then
        io.write(string.format(fmt[math.type(o)], o))
    else other cases
    end
end
```

对于字符串值，一种单纯的方法，会是下面这样：


```lua
    if type(o) == "string" then
        io.write("'", o, "'")
```

但是，如果字符串包含特殊字符（如引号或换行符），生成的代码则将不会是有效的 Lua 程序。


咱们可能会想通过修改引号，来解决此问题：


```lua
    if type(o) == "string" then
        io.write("[[", o, "]]")
```

当心代码注入！如果某个恶意用户，设法引导咱们的程序，保存类似 `"]].os.execute('rm *').[["` 的内容（例如，她可以将这个字符串，提供作她的地址），咱们的最终代码块，就会像下面这样：


```lua
varname = [[ ]]..os.execute('rm *')..[[ ]]
```

当尝试加载此 “数据” 时，咱们就将会大吃一惊。


以安全方式，将字符串用引号括起来的一个简单方法，便是使用 `string.format` 的 `"%q"` 选项。该选项旨在以 Lua 可安全读回的方式，保存字符串。他会用双引号，将字符串括起来，并正确对双引号、换行符，以及字符串内的一些其他字符进行转义：


```lua
a = 'a "problematic" \\string'

print(string.format("%q", a))   --> "a \"problematic\" \\string"
```

运用这一特性，我们的序列化函数，现在看起来就像下面这样：


```lua
function serialize (o)
    if type(o) == "number" then
        io.write(string.format(fmt[math.type(o)], o))
    elseif type(o) == "string" then
        io.write(string.format("%q", o))
    else other cases
    end
end
```

Lua 5.3.3 扩展了格式选项 `"%q"`，使其也能处理数字（以及 `nil` 和布尔值），再次以 Lua 可读回的正确方式写入他们（特别是，他会将浮点数格式化为十六进制，来确保完全的精度。）因此，从该版本开始，我们可以进一步简化和扩展 `serialize` 函数：


```lua
function serialize (o)
    local t = type(o)

    if t == "number"
        or t == "string"
        or t == "boolean"
        or t == "nil"
        then
            io.write(string.format("%q", o))
    else other cases
    end
end
```

另一种保存字符串的方法，就是长字符串的符号 `[=[...]=]`。不过，这种符号主要用于，其中咱们不想以任何方式，改变字面字符串的手写代码。在自动生成的代码中，转义有问题的字符，就会更为容易，因为 `string.format` 中的选项 `"%q"`，就可以做到这一点。


如果咱们仍想在自动生成的代码中，使用长字符串表示法，则必须注意一些细节。首先，咱们必须选择适当数量的等号。所谓良好的适当数量，是比原始字符串中，出现的最大数量多一个。由于包含较长的等号序列的字符串，很常见（例如，源代码中的注释），我们应该将注意力，限制在用方括号括起来的等号序列上。第二个细节便是，Lua 总会忽略长字符串开头的换行符；要避免这一问题，一种简单方法为，总是要添加一个被忽略的换行符。


下 [图 15.1，“将任意字面字符串括起来”](#f-15.1) 中的函数 `quote`，便是咱们上面谈及的结果。


<a name="f-15.1">**图 15.1，将任意字面字符串括起来**</a>


```lua
function quote (s)
    -- 找出等号序列的最大长度
    local n = -1
    for w in string.gmatch(s, "]=*%f[%]]") do
        n = math.max(n, #w - 1)     -- 减去 1 是要排除那个 ']'
    end

    -- 产生出有着 'n' 加一个等号的字符串
    local eq = string.rep("=", n + 1)

    -- 构建出括起来的字符串
    return string.format(" [%s]\n%s]%s] ", eq, s, eq)
end
```

> **译注**：这里 `gmatch` 的模式字符串 `]=*%f[%]]` 中，需要注意两个地方。一是 `%f` 指的是先锋模式；二是其中 `%]` 是 `%f[]` 转义后的参数 `]`。整个模式字符串匹配 `]==]` 这样的子字符串。


他会取一个任意字符串，并将其格式化为长字符串后返回。对 `gmatch` 的调用，会创建出一个遍历字符串 `s` 中，所有出现 `"]=*%f[%]]"`（即一个结尾方括号，后面是一个由零或多个等号组成的序列，后面是一个带有结尾方括号的边界），模式的地方的迭代器。循环结束后，我们使用 `string.rep`，将等号复制 `n + 1` 次，即比字符串中出现的最大次数，多一次。最后，`string.format` 会用一对，其中有着正确数量等号的括号，将 `s` 括起来，并在引号字符串前后，添加了额外空格，还在括起来的字符串开头，添加了换行符。


（我们可能会倾向于，使用更简单的，未用到第二个方括号边界模式的模式 `']=*]'`，但这里有一个微妙之处。假设目标为 `"]=]==]"`。第一个匹配项，会是 `"]=]"`。在他之后，字符串中剩下的是 `"==]"`，因此没有其他匹配项；在循环结束时，`n` 就将是一而不是二。边界模式则不会消费那个括号，因此括号仍会保留在目标中，供后面的匹配使用。）


## 保存没有循环的表


**Saving tables without cycles**


我们的下一项（也是更难的一项）任务，是保存表。依据咱们对表结构的假设，有几种保存表的方法。似乎没有一种算法，适合所有情况。简单的表，不仅可以使用更简单的算法，而且输出也可以更短更清晰。

咱们的首次尝试，见下 [图 15.2，“序列化没有循环的表”](#f-15.2)



<a name="f-15.2">**图 15.2，序列化没有循环的表**</a>


```lua
function serialize (o)
    local t = type(o)

    if t == "number"
        or t == "string"
        or t == "boolean"
        or t == "nil"
        then
            io.write(string.format("%q", o))
    elseif t == "table" then
        io.write("{\n")
        for k, v in pairs(o) do
            io.write("\t", k, " = ")
            serialize(v)
            io.write(",\n")
        end
        io.write("}\n")
    else
        error("cannot serialize a " .. type(o))
    end
end
```

尽管他简单，但其工作却很合理。只要表结构是树形的，即不存在共用的子表，也没有循环，他甚至可以处理嵌套表（即在其他表中的表）。(美观上的一个小改进，将是缩进那些嵌套表，参见 [练习 15.1](#练习)）。

上面那个函数，假定了表中的所有键，都是有效的标识符。在表有着数字的键，或不是语法上有效的 Lua 标识符的字符串键时，我们就有麻烦了。解决这一问题的简单方法，是使用以下代码，编写每个键：

```lua
            io.write(string.format("\t[%s] = ", serialize(k)))
```

通过这一改动，我们提高了咱们函数的健壮性，但代价是牺牲了生成文件的美观性。请看接下来这个调用：


```lua
serialize{a=12, b='Lua', key='another "one"'}
```

> **译注**：这样写是错误的，会报出以下错误：
>
```console
"a"ser.lua:17: bad argument #2 to 'format' (no value)
stack traceback:
        [C]: in function 'string.format'
        ser.lua:17: in function 'serialize'
        ser.lua:27: in main chunk
        [C]: in function 'dofile'
        stdin:1: in main chunk
        [C]: in ?
```
>
> 原因在于，`io.write(string.format("\t[%s] = ", serialize(k)))` 中，`string.format` 的第二个参数，`serialize(k)`，并未返回一个字符串，而是往 `io` 写入字符串。推测应写为：`io.write(string.format("\t[%q] = ", k))`


使用 `serialize` 的第一个版本的调用，结果为下面这样：

```lua
{
        key = "another \"one\"",
        a = 12,
        b = "Lua",
}
```

将其与使用第二个版本的结果比较：

```lua
{
        ["key"] = "another \"one\"",
        ["b"] = "Lua",
        ["a"] = 12,
}
```

通过测试是否需要方括号的各种情况，我们可以同时获得稳健性和美观性；同样，我们将把这种改进，留作练习。


## 保存有着循环的表

**Saving tables with cycles**

要处理有着通用拓扑结构（即有着循环，与共享子表）的表，我们就需要不同方法。构造器无法创建出此类表，因此我们将不使用构造器。为表示循环，我们需要名字，因此我们的下一个函数，将取要保存的值与其名字，作为参数。此外，我们必须跟踪已保存表的那些名字，以便在检测到循环时，重新使用他们。我们将用到一个额外的表，用于此跟踪。跟踪表会将之前保存的表，作为索引，并将他们的那些名字，作为关联值。

得到的代码在下 [图 15.3，“保存带有循环的表”](#f-15.3) 中。


<a name="f-15.3">**图 15.3，保存带有循环的表**</a>


```lua
function basicSerialize (o)
    -- 假定 'o' 是个数字或字符串
    return string.format("%q", o)
end

function save (name, value, saved)
    saved = saved or {}
    io.write(name, " = ")

    if type(value) == "number"
        or type(value) == "string"
        then
            io.write(basicSerialize(value), "\n")
    elseif type(value) == "table" then
        if saved[value] then                -- 值已被保存？
            io.write(saved[value], "\n")    -- 使用其先前的名字
        else
            saved[value] = name             -- 为下一次保存名字
            io.write("{}\n")                -- 创建出一个新表
            for k, v in pairs(value) do     -- 保存其字段
                k = basicSerialize(k)
                local fname = string.format("%s[%s]", name, k)
                save(fname, v, saved)
            end
        end
    else
        error("cannot save a " .. type(value))
    end
end
```

我们保留了，咱们打算保存的表只有字符串和数字作为的键这一限制。函数 `basicSerialize` 会序列化这些基本类型，并返回结果。下一函数，`save`，完成了艰苦的工作。其中的参数 `saved`，便是那个跟踪已保存表的表。举个例子，假设我们构建了一个下面这样的表：


```lua
a = {x=1, y=2; {3, 4, 5}}
a[2] = a    -- 循环
a.z = a[1]  -- 共用的子表
```

调用 `save("a", a)`，就会将其保存为下面这样：

```lua
a = {}
a[1] = {}
a[1][1] = 3
a[1][2] = 4
a[1][3] = 5
a[2] = a
a["y"] = 2
a["z"] = a[1]
a["x"] = 1
```

这些赋值的具体顺序，可能会有所不同，因为他取决于某次表的遍历。尽管如此，这种算法确保了，新定义中所需的任何节点，都已被定义。

在打算保存有着共享部分的多个值时，咱们可以调用同一个 `save` 表，来保存它们。例如，假设有以下两个表：


```lua
a = {{"one", "two"}, 3}
b = {k = a[1]}
```

在我们单独保存他们时，结果将不会有共同的部分。但是，如果我们对两次 `save` 调用，使用相同的 `saved` 表，则结果就将共用公共部分：


```lua
local t = {}
save("a", a, t)
save("b", b, t)


    --> a = {}
    --> a[1] = {}
    --> a[1][1] = "one"
    --> a[1][2] = "two"
    --> a[2] = 3
    --> b = {}
    --> b["k"] = a[1]
```

按照 Lua 的惯例，还有其他的一些选择。其间，我们可以在不给值全局名称（而是，块会构建出一个局部值，并返回他）的情况下，保存某个值，在可行的情况下，咱们可以使用列表语法（参见本章练习），等等。Lua 为咱们提供了工具；咱们则要构建出这些机制。


## 练习

练习 15.1：请修改图 15.2，[“序列化不带循环的表”](#保存没有循环的表) 中的代码，以便其缩进嵌套表。 （提示：要添加一个额外的参数，以使用缩进字符串进行 `serialize`。）

练习 15.2：请按照 [“保存没有循环的表”](#保存没有循环的表) 小节的建议，修改上一个练习的代码，使其使用 `["key"]=value` 语法。

练习 15.3：请修改上一练习的代码，使其仅在必要时（即键是字符串，但不是有效标识符时），才使用 `["key"]=value` 语法。

练习 15.4：请修改上一练习的代码，使其尽可能使用列表的构造器语法。例如，应将表格 `{14, 15, 19}` 序列化为 `{14, 15, 19}`，而不是 `{[1] = 14, [2] = 15, [3] = 19}`。(提示：只要键不是 `nil`，就要首先保存键 1、2、.....的值。在遍历表的剩余部分时，要注意不要再度保存他们，Hint: start by saving the values of the keys 1, 2, ..., as long as they are not `nil`. Take care not to save them again when traversing the rest of the table。）

练习 15.5：保存带有循环的表时，避免使用构造器的方法，会过于激进。对于简单的情况，使用构造器以更愉快的格式保存表，并在随后使用赋值，修复共用（子表）及循环，是可行的。请使用这种方法，重新实现函数 `save`（图 15.3，“保存带有循环的表”）。为其添加上，将咱们在前面的练习中，实现过的所有优点（缩进、记录语法与列表语法，record syntax and list syntax）。

