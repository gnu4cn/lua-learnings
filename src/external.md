# 外部世界

由于其在可移植性，与可嵌入性方面的强调，Lua 本身，并没有提供太多与外部世界通信的设施。真实 Lua 程序中的大多数 I/O，从图形到数据库及网络的访问，要么由主机应用程序完成，要么通过主发行版中未包含的一些外部库完成。 纯粹的 Lua，仅提供 ISO C 标准提供的功能，即基本文件操作，加上一些额外功能。在本章中，我们将了解标准库，如何涵盖这些功能。


## 简单 I/O 模型

I/O 库提供了两种不同的文件操作模型。其中简单模型假设了，*当前输入流，current input stream*，和 *当前输出流，current out stream*，且其 I/O 操作是对这两种流进行操作。该库将当前输入流，初始化为进程的标准输入 (`stdin`)，将当前输出流，初始化为进程的标准输出 (`stdout`)。因此，当我们执行 `io.read()` 之类的操作时，我们会从标准输入中，读取一行。

我们可以使用 `io.input` 和 `io.output` 函数，更改这些当前流。像 `io.input(filename)` 这样的调用，会以读取模式，在文件上的打开流，并将其设置为当前输入流。从此时起，所有输入，都将来自该文件，直到再次调用 `io.input`。函数 `io.output`，则对输出执行类似的工作。如果出现错误，两个函数都会抛出错误。如果咱们想要直接处理错误，就应使用 完整 I/O 模型，the complete I/O model。

由于相较 `read`，`write` 要简单一些，因此我们首先看他。函数 `io.write` 只是接受任意数量的字符串（或数字），并将他们写入当前输出流。因为我们可以使用多个参数来调用他，所以我们应该避免像 `io.write(a..b..c);` 这样的调用。调用 `io.write(a, b, c)`，会以更少资源，达到相同的效果，因为他避免了连接运算。

通常，咱们应仅将 `print`，用于快速而肮脏的程序或调试，quick-and-dirty programs or debugging；当咱们需要完全控制输出时，请始终使用 `io.write`。与 `print` 不同，`write` 不会向输出，添加额外字符，例如制表符或换行符。此外，`io.write` 允许咱们重定向输出，而 `print` 则始终使用标准输出，the standard output。最后， `print` 会自动将 `tostring`，应用于其参数；这对于调试来说很方便，但这也可能隐藏一些微妙的错误，subtle bugs。

函数 `io.write`，会按照通常的转换规则，将数字转换为字符串；为了完全控制这种转换，我们应该使用 `string.format`：

```lua
> io.write("sin(3) = ", math.sin(3), "\n")
sin(3) = 0.14112000805987
file (0x7f386f1505c0)
> io.write(string.format("sin(3) = %.4f\n", math.sin(3)))
sin(3) = 0.1411
file (0x7f386f1505c0)
```

函数 `io.read`，会从当前输入流读取字符串。他的参数，控制着读取的内容：<sup>注 1</sup>


| 参数 | 读取内容 |
| :-- | :-- |
| `"a"` | 读取整个文件。 |
| `"l"` | 读取下一行（丢弃新行字符，dropping the newline）。 |
| `"L"` | 读取下一行（保留新行字符，keeping the newline）。 |
| `"n"` | 读取一个数字。 |
| `num` | 将 `num` 个字符，作为字符串读取。 |


> **注 1**：在 Lua 5.2 及之前版本中，所有字符串选项前面，都应该有一个星号，an asterisk, `*`。 Lua 5.3 仍然接受星号，以实现兼容性。


`io.read("a")` 这个调用，会从当前位置开始，读取整个当前输入文件。如果我们位于文件末尾，或者文件为空，则该调用会返回一个空字符串。


因为 Lua 可以有效地处理长字符串，故以 Lua 编写过滤器的一种简单技巧，便是将整个文件读入字符串，处理该字符串，然后将字符串写入输出：


```lua
> io.input("data")
file (0x564a2d55ffe0)
> io.output("new-data")
file (0x564a2d5a1510)
> t = io.read("a")
> t = string.gsub(t, "the", "that")
> io.write(t)
file (0x564a2d5a1510)
> io.close()
```

作为更具体的示例，以下代码块，是使用 MIME *扩起来的可打印* 编码，the MIME *quoted-printable* encoding，对文件内容进行编码的完整程序。这种编码将每个非 ASCII 字节，编码为 `=xx`，其中 `xx` 是字节的十六进制值。为了保持编码的一致性，他还必须对等号进行编码：


```lua
> io.input("data")
> t = io.read("a")
> t = string.gsub(t, "([\128-\255=])", function (c) return string.format("=%02X", string.byte(c)) end)
> io.write(t)
```

其中的函数 `string.gsub`，将匹配所有非 ASCII 字节（从 `128` 到 `255` 的代码），加上等号，并调用给定函数来提供替换。 （我们将在第 10 章 [”模式匹配”](pattern_matching.md) 中详细讨论模式匹配。）

调用 `io.read("l")`，会返回当前输入流中的下一行，不带换行符；调用 `io.read("L")` 类似，但他会保留换行符（如文件中存在）。当我们到达文件末尾时，调用会返回 `nil`，因为没有下一行要返回。选项 `“l”` 是 `read` 函数的默认选项。通常，仅在算法自然地逐行处理数据时，我（作者）才使用此选项；否则，我喜欢使用选项 `“a”` 立即读取整个文件，或者如我们稍后将看到的，分块读取。

作为基于行输入的运用简单示例，以下程序，会将其当前输入，复制到当前输出，并对每行进行编号：

```lua
> io.input("data")
file (0x5650b9a53fe0)
> for count = 1, math.huge do
>> local line = io.read("L")
>> if line == nil then break end
>> io.write(string.format("%6d ", count), line)
>> end
     1 Dozens were killed and many more injured in a blast at the Al-Maghazi refugee camp in the central Gaza Strip late Saturday night, according to hospital officials.
     2
     3 The explosion in the camp killed 52 people, said Mohammad al Hajj, the director of communications at the nearby Al-Aqsa Martyr’s hospital in Deir Al-Balah. He told CNN that the explosion was the result of an Israeli airstrike.
     4
     5 One resident of the camp told CNN: “We were sitting in our homes, suddenly we heard a very, very powerful sound of an explosion. It shook the whole area, all of it.”
     6
     7 The Israel Defense Forces (IDF) says it is looking into the circumstances around the explosion.
     8
     9 Dr. Khalil Al-Daqran, the head of nursing at the Al-Aqsa Martyr’s hospital told CNN he had seen at least 33 bodies from what he also claimed was an Israeli airstrike.
```


但是，`io.lines` 迭代器实现了使用更简单的代码，来逐行迭代整个文件：


```lua
local count = 0

for line in io.lines() do
    count = count + 1
    io.write(string.format("%6d ", count), line, "\n")
end
```

> **注意**：原文的代码如下，若在 Lua 交互模式下，因为变量作用域的缘故，而报出了在 `nil` 上执行算术运算的错误。

```console
> local count = 0
> for line in io.lines() do
>> count = count + 1
>> io.write(string.format("%6d ", count), line, "\n")
>> end
stdin:2: attempt to perform arithmetic on a nil value (global 'count')
stack traceback:
        stdin:2: in main chunk
        [C]: in ?
```

作为基于行输入的另一示例，下 [图 7.1 “对文件进行排序的程序”](#f-7.1) 给出了对文件行进行排序的一个完整程序。


<a name="f-7.1">**图 7.1，一个对文件加以排序的程序**</a>

```lua
local lines = {}

-- 将文件中的行，读入到表 `lines` 中
for line in io.lines() do
    lines[#lines + 1] = line
end

-- 排序
table.sort(lines)

-- 写所有行
for _, l in ipairs(lines) do
    io.write(l, "\n")
end
```

调用 `io.read("n")`，会从当前输入流中，读取一个数字。这是 `read` 返回数字（整数或浮点数，遵循 Lua 扫描器的相同规则），而不是字符串的唯一情况。如果在跳过空格后，`io.read` 在当前文件位置找不到数字（由于格式错误或文件结尾），则返回 `nil`。

除了基本的读取模式之外，咱们还可以使用数字 *n* 作为参数，来调用 `read`：在这种情况下，他会尝试从输入流中，读取 *n* 个字符。如果无法读取任何字符（文件结尾），则调用返回 `nil`；否则，他会从流中返回最多包含 *n* 个字符的字符串。作为此读取模式的示例，以下程序是将文件从 `stdin`，复制到 `stdout` 的有效方法：


```lua
while true do
    local block = io.read(2^13)         -- 块大小为 8k
    if not block then break end
    io.write(block)
end
```

作为一种特殊情况，`io.read(0)` 用作文件结尾的测试：如果有更多内容要读取，则返回空字符串，否则返回 `nil`。

我们可以使用多个选项，来调用 `read`；对于每个参数，该函数将返回相应的结果。假设我们有一个文件，每行包含三个数字：

```txt
6.0     -3.23   15e12
4.3     234     1000001
89      95      78
...
```

现在我们要打印出每行的最大值。我们可以通过一次 `read` 调用，读取每行的所有三个数字：

```lua
while true do
    local n1, n2, n3 = io.read("n", "n", "n")
    if not n1 then break end
    print(math.max(n1, n2, n3))
end
```


输出为:

```console
15000000000000.0
1000001
95
```


## 完整 I/O 模型

简单的 I/O 模型，对于简单的事情来说很方便，但对于更高级的文件操作（例如同时读取或写入多个文件）来说，还不够。对于这些操作，我们需要完整模型。

要打开文件，咱们要使用模仿 C 函数 `fopen` 的 `io.open` 函数。他以要打开的文件名，和 *模式，mode* 字符串作为参数。此模式字符串，可以包含用于读取的 `r`、用于写入的 `w`（这也会删除文件以前的任何内容），或用于追加的 `a`，以及用于打开二进制文件的可选项 `b`。函数 `open` 返回一个文件上的新流。如果发生错误，`open` 会返回 `nil`，加上错误消息，以及与系统相关的错误编号：


```console
> print(io.open("data-num", "r"))
nil     data-num: No such file or directory     2
> print(io.open("data-number", "w"))
nil     data-number: Permission denied  13
```

一种检查错误的典型习惯用法，便是使用函数 `assert`：

```console
> f = assert(io.open("data", "r"))
> f
file (0x563c8dffcfe0)
>
> f = assert(io.open("data-number", "r"))
> f
file (0x563c8e03f270)
> f = assert(io.open("data-number", "w"))
stdin:1: data-number: Permission denied
stack traceback:
        [C]: in function 'assert'
        stdin:1: in main chunk
        [C]: in ?
```


如果 `open` 失败了，那么错误信息，就将作为 `assert` 的第二个参数，然后显示错误消息。


打开文件后，我们就可以使用 `read` 和 `write` 方法，从其读取或写入到所产生的流。他们与函数 `read` 和 `write` 类似，但我们使用冒号操作符，将他们作为流对象上的方法来调用。例如，要打开一个文件并全部读取，我们可以使用如下的代码片段：


```lua
local f = assert(io.open("data", "r"))

local t = f:read("a")
f:close()
```

（我们将在第 21 章 [*面向对象编程*](oop.md) 中，详细讨论冒号运算符。）


I/O 库为三个预定义的 C 语言（文件）流提供了句柄，分别名为 `io.stdin`、`io.stdout` 和 `io.stderr`。例如，我们可以直接向错误流，发送信息，代码如下：


```lua
io.stderr:write(message)
```

函数 `io.input` 和 `io.output`，允许咱们混合使用完整模型与简单模型。我们通过调用 `io.input()`（不带参数），获取当前输入流。通过调用 `io.input(handle)`，我们可以设置输入流。（类似调用也对 `io.output()` 有效。）例如，如果我们想临时更改当前输入流，可以这样写：


```lua
local temp = io.input()     -- 保存当前流
io.input("newinput")        -- 打开一个新的当前流

-- 对新的流进行一些操作
io.input():close()          -- 关闭当前流
io.input(temp)
```


请注意，`io.read(args)` 实际上是 `io.input():read(args)` 的简写，即应用在当前输入流上的 `read` 方法。同样，`io.write(args)` 是 `io.output():write(args)` 的简写。


我们还可以使用 `io.lines`，代替 `io.read` 从流中读取数据。正如我们在前面的示例中看到的，`io.lines` 提供了一个迭代器，可以重复从流中读取数据。在给定了某个文件名时，`io.lines` 将以读取模式，在文件上打开一个流，并在文件结束后关闭该流。如果调用时没有参数，`io.lines` 将从当前输入流中，读取数据。我们还可以将 `lines` 作为句柄上的方法使用，as a method over handles。此外，自 Lua 5.2 版起，`io.lines` 也接受与 `io.read` 相同的选项。例如，接下来的代码片段，会将当前输入，复制到当前输出，迭代 `8 KB` 的数据块：


```lua
for block in io.input():lines(2^13) do
    io.write(block)
end
```


## 其他文件操作

函数 `io.tmpfile` 会返回一个，以读写模式，read/write mode，打开的临时文件流。程序结束时，该文件将自动删除。


函数 `flush` 会执行所有待处理的写入文件操作。与函数 `write` 一样，我们可以函数 `io.flush()` 的形式，调用他来刷新当前输出流，或以方法 `f:flush()` 的形式，调用他来刷新流 `f`。


`setvbuf` 方法，用于设置数据流的缓冲模式。他的第一个参数是个字符串： `"no"` 表示不缓冲；`"full"` 表示只有当缓冲区满，或我们显式刷新文件时，才写出流数据；`"line"` 表示在输出换行符，或有来自特殊文件（如终端设备）的输入前，输出会被缓冲。对于后两个选项，`setvbuf` 接受可选的第二个参数，即缓冲区大小，the buffer size。


在大多数系统中，标准错误流（`io.stderr`）是不缓冲的，而标准输出流（`io.stdout`）在行模式下，in line mode，是缓冲的。因此，在我们向标准输出，写入不完整的行（如进度指示器），就可能需要刷新流，才能看到输出。


`seek` 方法，可以获取及设置文件流的当前位置。他的一般形式是 `f:seek(whence,offset)`，其中 `whence` 参数是个字符串，用于指定如何解释偏移量。其有效值为，`"set"`，用于相对于文件开头的偏移量；`"cur"`，用于相对于文件当前位置的偏移量；`"end"`，用于相对于文件结尾的偏移量。而与 `whence` 的值无关，调用会返回数据流的新当前位置，从文件开头开始以字节为单位计算。


`whence` 的默认值是 `"cur"`，偏移量的默认值是零。因此，调用 `file:seek()`，就会在不会改变当前流位置下，返回当前流位置；调用 `file:seek("set")` 会将位置，重置为文件开头（并返回零）；调用 `file:seek("end")` 会将位置设置为文件结尾，并返回文件大小。下面的函数，可以在不改变文件当前位置的情况下，获取文件大小：


```lua
function fsize(file)
    local current = file:seek()     -- 保存当前位置
    local size = file:seek("end")   -- 获取文件大小

    file:seek("set", current)       -- 恢复位置

    return size
end
```


为完善整套的文件操作，`os.rename` 会更改文件名，而 `os.remove` 则会删除文件。请注意，这些函数来自 `os` 库，而不是 `io` 库，因为他们处理的是真实文件，而不是数据流。


全部这些函数，在出现错误时，都会返回 `nil` 与错误信息，以及错误代码。


## 其他系统调用

函数 `os.exit` 会终止程序的执行。他的第一个可选参数，是程序的返回状态。其可以是一个数字（`0` 表示执行成功）或一个布尔值（`true` 表示执行成功）。当可选的第二个参数为 `true` 时，会关闭 Lua 状态，调用所有终结器，all finalizers，并释放该状态使用的所有内存。(通常这种终结，this finalization，是不必要的，因为大多数操作系统，都会在进程退出时，释放进程使用的所有资源。）

函数 `os.getenv`，会获取环境变量的值。他取变量的名称，并返回一个包含其值的字符串：


```console
> print(os.getenv("HOME"))
C:\tools\msys64\home\Lenny.Peng
```

对于未定义的变量，该调用会返回 `nil`。


### 运行系统命令


函数 `os.execute` 运行一条系统命令；他等同于 C 语言函数 `system`。他取一个包含命令的字符串，并返回命令结束的信息，information regarding how the command terminated。第一个结果是布尔值：`true` 表示程序无错误退出。第二个结果是一个字符串：如果程序正常结束，则返回 `"exit"`；如果程序被信号中断，则返回 `"signal"`。第三个结果是返回状态，the return status（在程序正常终止时），或终止程序的信号编号，the number of the signal that terminated the program。举例来说，在 POSIX 和 Windows 中，我们都可以使用下面的函数，来创建新目录：

```lua
function createDir (dirname)
    os.execute("mkdir " .. dirname)
end
```


另一个相当有用的函数，是 `io.popen`。<sup>注 2</sup> 与 `os.execute` 类似，他运行一条系统命令，但同时也将命令的输出（或输入），连接到一个新的本地流，并返回该流，这样我们的脚本就可以，从命令中读取数据（或向命令写入数据）。例如，下面的脚本，会用当前目录中的条目，建立了一个表：


> **注 2**：该函数并非在所有 Lua 安装中都可用，因为相应的功能并非 ISO C 的一部分。尽管不是 C 中的标准，但由于其通用性和在主要操作系统中的存在，我们将其包含在标准库中。


```lua
-- 对于 Windows，请使用 'dir /B' 代替 'ls -1'
local f = io.popen("ls -1", "r")
-- local f = io.popen("dir /B", "r")

local dir = {}
for entry in f:lines() do
    dir[#dir + 1] = entry
end
```

其中 `io.popen` 的第二个参数（`"r"`），表示咱们打算，从命令中读取数据。默认情况下是读取，因此在示例中，该参数是可选的。


下个示例，会发送一封电子邮件：


```lua
local subject = "Some news"
local address = "someone@example.com"

local cmd = string.format("mail -s '%s' '%s'", subject, address)
local f = io.popen(cmd, "w")

f:write([[
Nothing important to sys.
-- me
]])
f:close()
```

（此脚本仅适用于安装了相应软件包（`bsd-mailx`）的 POSIX 系统。）现在，`io.popen` 的第二个参数是 `"w"`，表示我们打算写入该命令。


从以上两个示例可以看出，`os.execute` 和 `io.popen`，都是功能强大的函数，但他们也是系统高度依赖的。


对于扩展的操作系统访问，咱们最好使用某个外部 Lua 库，诸如 `LuaFileSystem`（用于目录和文件属性的基本操作）或 `luaposix`（提供 POSIX.1 标准的大部分功能）。


## 练习

练习 7.1：请编写一个读取文本文件，并按字母顺序排序其中的行后，重写该文件。当不带参数调用时，他应该从标准输入读取，并写入标准输出。当使用文件名参数调用时，他应该从该文件读取，并写入标准输出。当使用两个文件名参数调用时，他应该从第一个文件读取，并写入第二个文件。


练习 7.2：更改上一程序，使其在用户提供其输出文件的某个既有文件名时，要求用户确认。


练习 7.3：比较以下列方式，将标准输入流复制到标准输出流的 Lua 程序性能：

- 逐个字节，byte by byte；

- 逐行，line by line；

- 以 8KB 块方式，in chunks of 8 kB；

- 一次性整个文件方式，the whole file at once。

对于最后一个选项，输入文件可以有多大？


练习 7.4：请编写一个程序，打印出文本文件的最后一行。当文件较大且可寻时，when the file is large and seekable，要尽量避免读取整个文件。


练习 7.5：将上一程序通用化，以便打印文本文件的最后 `n` 行。同样，当文件较大且可寻时，要尽量避免读取整个文件。


练习 7.6：请使用 `os.execute` 和 `io.popen`，编写出创建目录、删除目录和收集目录中项目的函数。


练习 7.7：你能使用 `os.execute`，改变咱们 Lua 脚本的当前目录吗？为什么？
