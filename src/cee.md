# 编译，执行与报错

尽管我们将 Lua 称作解释型语言，但 Lua 总是会在运行源代码之前，将其预编译为中间形式（这没什么大不了的：许多解释型语言，也是如此。）编译阶段的存在，听起来可能与解释型语言格格不入。然而，解释型语言的显著特点，并不是不编译，而是可以（而且很容易）执行即时生成的代码。我们可以说，正是因为有了 `dofile` 这样的函数，我们才有资格，把 Lua 称作解释型语言。


在本章中，我们将更详细地讨论，Lua 运行其代码块，its chunks，的过程，编译的含义与作用，Lua 如何执行编译后的代码，以及如何处理在这一过程中，出现的错误。


## 编译

**Compilation**


早先，我们将 `dofile`，作为运行 Lua 代码块的一种原语操作，加以了引入，但 `dofile` 实际上是一个辅助函数，an auxiliary function：函数 `loadfile` 真正完成了艰苦工作。与 `dofile` 一样，`loadfile` 会从文件，加载 Lua 块，但他不运行该块。相反，他只会编译块，并将编译后的块，作为函数返回。此外，与 `dofile` 不同，`loadfile` 不会抛出错误，而是返回错误代码。我们可以像下面这样，定义一个 `dofile`：


```lua
function dofile (filename)
    local f = assert(loadfile(filename))
    return f()
end
```

请注意，其中那个在 `loadfile` 失败时，用于抛出错误的 `assert` 的运用。


对于简单的任务，`dofile` 是很方便的，因为一次调用中，他就能完成全部工作。不过，`loadfile` 更为灵活。如果出现错误，`loadfile` 会返回 `nil` 和错误信息，这就允许我们，以自定义的方式处理错误。此外，如果需要多次运行某个文件，我们可以调用一次 `loadfile`，然后多次调用其结果。这种方法，比多次调用 `dofile` 开销要低，因为 `loadfile` 只需编译一次文件。(与语言中的其他任务相比，编译是一项有些开销高昂的操作。）

函数 `load`，类似于`loadfile`，不同之处在于，他会从字符串或函数中，读取代码块，而不是从文件中读取。<sup>注 1</sup>例如，请考虑下面这行代码：

> **注 1**：在 Lua 5.1 中，函数 `loadstring`，扮演了加载字符串的角色。

```lua
f = load("i = i + 1")
```

这段代码之后，在被调用时，`f` 将个是执行 `i = i + 1` 的函数：


```lua
i = 0
f(); print(i)   --> 1
f(); print(i)   --> 2
```

函数 `load` 功能强大；我们应谨慎使用。他也是一个开销高昂的函数（与某些替代函数相比），并能导致代码难以理解。在使用之前，咱们要确保，解决手头的问题，已没有更简单的方法。

在我们打算执行一次快速而不太规范的 `dostring`（即，加载并运行某个代码块）时，a quick-and-dirty `dostring`，我们可以直接调用 `load` 的结果：


```lua
s = "i = i + 1"
load(s)(); print(i)     --> 3
```


通常，在字面字符串上使用 `load`，没有意义。例如，下面的两行，就大致相同：


```lua
f = load("i = i + 1")
f = function () i = i + 1 end
```

不过，第二行要快得多，因为 Lua 会将函数与其外层代码块，一起编译。而在第一行中，到 `load` 的调用，则需要单独编译。


由于 `load` 不会以词法范围（作用域）编译，does not compile with lexical scoping，因此上个示例中的两行，可能并不真正等价。为了弄清其中的区别，咱们来稍微修改一下那个示例：

```lua
i = 32
local i = 0
f = load("i = i + 1; print(i)")
g = function () i = i + 1; print(i) end
f()             --> 33
g()             --> 1
```

函数 `g` 如预期那样，操作了局部变量 `i`，但函数 `f` 操作的，是全局的 `i`，因为 `load`，总是在全局环境中，编译他的代码块。

加载的最典型用途，是运行外部代码（即来自咱们程序外部的，一些代码片段），或动态生成的代码。例如，我们可能想要绘制某个用户定义的函数；用户输入该函数的代码，然后我们使用 `load`，对其进行计算。请注意，`load` 预期得到是个代码块，即一些语句。在打算计算某个表达式时，我们可以在表达式前，加上 `return`，这样我们就能得到，返回给定表达式值的一个语句。请看示例：

```lua
print "enter your expression:"
local line = io.read()
local func = assert(load("return " .. line))
print("the value of your express ion is " .. func())
```

由于 `load` 返回的函数，是个常规函数，因此我们可以多次调用他：


```lua
print "enter function to be plotted (with variable 'x'):"
local line = io.read()
local f = assert(load("return " .. line))
for i = 1, 20 do
    x = i   -- 全局的 'x' (要对该代码块可见)
    print(string.rep("*", f()))
end
```


我们也可以将一个 *读取函数，reader function*，用作其第一个参数，调用 `load`。读取函数可以分部分地，返回代码块；`load` 会连续调用读取函数，直到返回表示数据块结束的 `nil`。例如，下面这个调用，等同于 `loadfile`：


```lua
f = load(io.lines(filename, "*L"))
```

正如我们在第 7 章，[“外部世界”](external.md) 中所看到的，那个 `io.lines(filename, "*L")` 调用，在每次调用时，都会返回一个，从给定文件返回一行新内容的函数。因此，`load` 就会，逐行读取文件中的代码块。以下版本与之类似，但效率略高：


```lua
f = load(io.lines(filename, 1024))
```

这里，`io.lines` 所返回的迭代器，会以 1024 字节的块，读取该文件。


Lua 会将任何独立的代码块，都视为 [可变函数](functions.md#可变函数) 的主体。例如，`load("a = 1")` 会返回，以下表达式的等价内容：


```lua
function (...) a = 1 end
```

与其他函数一样，代码块可以声明出一些局部变量：

```lua
f = load("local a = 10; print(a + 20)")
f()         --> 30
```

运用这些特性，咱们就可以重写上面的绘图示例，以避免使用全局变量 `x`：


```lua
print "enter function to be plotted (with variable 'x'):"
local line = io.read()
local f = assert(load("local x = ...; return " .. line))
for i = 1, 20 do
    print(string.rep("*", f(i)))
end
```

这段代码中，我们在那个代码块的开头，添加了 `"local x = ..."` 的声明，从而将 `x` 声明为了，一个局部变量。然后，我们以参数 `i`，调用 `f`，参数 `i` 就将成为那个可变参数表达式（`...`）的值。

> **译注**：这里，若把行 `local f = assert(load("local x = ...; return " .. line))`，修改为 `local f = assert(load("local x = ...; return " .. line .. " + x"))`，将更能反应出 `load` 的代码块中，可变参数表达式 `...` 的意义。


函数 `load` 与 `loadfile`，从不抛出错误。在出现任何类型的错误时，他们都会返回 `nil`，与一条错误信息：


```lua
print(load("i i"))
    --> nil     [string "i i"]:1: syntax error near 'i'
```

此外，这两个函数从不会产生，任何类别的副作用，也就是说，他们不会修改，或创建变量，不会写入文件等。他们只是将代码块，编译成某种内部表示，并将该结果，作为匿名函数返回。一种常见的错误认识，是认为加载某个代码块，就会定义出一些函数。在 Lua 中，函数的定义，是一些赋值操作；因此，他们发生于运行时，而不是在编译时。例如，假设我们有个名为 `foo.lua` 的文件，内容如下：


```lua
-- 文件 'foo.lua'
function foo (x)
    print(x)
end
```

我们随后运行命令

```lua
f = loadfile("foo.lua")
```

这条命令会编译 `foo`，但不会定义出他。要定义出 `foo`，我们就必须运行那个代码块：


```lua
> f = loadfile("foo.lua")
> print(foo)
nil
> f()
> foo("ok")
ok
> print(foo)
function: 000001ab70327280
```

这种行为，听起来可能奇怪，但如果我们在不使用语法糖下，重写该文件，就会明白了：


```lua
-- 文件 'foo.lua'
foo = funtion (x)
    print(x)
end
```

在需要运行外部代码的生产级程序中，in a production-quality program that needs to run external code,我们应该那些，在处理加载代码块时，所报告的任何错误。此外，我们可能希望在受保护的环境中，运行新的代码块，以避免一些不愉快的副作用。我们将在第 22 章 [“环境”](environment.md) 中，详细讨论那些环境。


## 预编译的代码

**Precompiled Code**


正如我（作者）在本章开头曾提到的，在运行源代码之前，Lua 会对其进行预编译。Lua 还允许我们，以预编译的形式，发布代码。


生成预编译文件（在 Lua 术语中，也称为 *二进制代码块，binary chunk*）的最简单方法，是使用标准发布中的 `luac` 程序，the `luac` program that comes in the standard distribution。例如，下面这个调用，将创建出新文件 `prog.lc`，其中包含了文件 `prog.lua` 的预编译版本：


```bash
$ luac -o prog.lc prog.lua
```

Lua 解释器可以像执行普通 Lua 代码一样，执行这个新文件，其执行方式，与原始源代码完全相同：


```bash
$ lua prog.lc "file1" "file2"
```

Lua 在接受源代码的任何地方，都会接受预编译代码。特别是，`loadfile` 和 `load`，二者都接受预编译代码。

我们可以直接以 Lua，编写一个最小 `luac`：


```lua
p = loadfile(arg[1])
f = io.open(arg[2], "wb")
f:write(string.dump(p))
f:close()
```

这里的关键函数，是 `string.dump`：他接收一个 Lua 函数，在为今后由 Lua 加载而适当格式化后，返回该函数的预编译代码。

这个 `luac` 程序，还提供了其他一些有趣的选项。其中，选项 `-l` 会列出，对于给定代码块，编译器所生成的操作码，the opcodes that the compiler generates for a given chunk。例如，下 [图 16.1，“`luac - l` 的输出示例”](#f-16.1)，显示了在以下单行文件上，带有 `-l` 选项 `luac` 的输出：


```lua
a = x + y - z
```


<a name="f-16.1">**图 16.1，`luac -l` 的示例输出**</a>


```txt

main <stdin:0,0> (10 instructions at 00000192bdc12970)
0+ params, 2 slots, 1 upvalue, 0 locals, 4 constants, 0 functions
        1       [1]     VARARGPREP      0
        2       [1]     GETTABUP        0 0 1   ; _ENV "x"
        3       [1]     GETTABUP        1 0 2   ; _ENV "y"
        4       [1]     ADD             0 0 1
        5       [1]     MMBIN           0 1 6   ; __add
        6       [1]     GETTABUP        1 0 3   ; _ENV "z"
        7       [1]     SUB             0 0 1
        8       [1]     MMBIN           0 1 7   ; __sub
        9       [1]     SETTABUP        0 0 0   ; _ENV "a"
        10      [1]     RETURN          0 1 1   ; 0 out
```

> **译注**：其中的 `<stdin:0,0>` 是这样得到的，首先以 `echo "a = x + y -z" | lua -` 命令，会将这个字符串，编译到 `luac` 的默认输出 `luac.out`，注意其中的 `luac -` 子命令，其中的 `-` 是个 `luac` 的参数：

```bash
$ luac
C:\tools\msys64\mingw64\bin\luac.exe: no input files given
usage: C:\tools\msys64\mingw64\bin\luac.exe [options] [filenames]
Available options are:
  -l       list (use -l -l for full listing)
  -o name  output to file 'name' (default is "luac.out")
  -p       parse only
  -s       strip debug information
  -v       show version information
  --       stop handling options
  -        stop handling options and process stdin
```

> 然后运行 `luac -l luac.out`，或直接运行 `luac -l`（此命令会默认读取并列出 `luac.out` 的操作码），即可看到上面的输出。
>
>
> 还需注意，上面的输出，是在 Windows 系统下（运行了 MSYS2）环境中的输出，而在 Linux 系统下的输出，则为：


```console
$ luac -l

main <stdin:0,0> (7 instructions at 0x55b6b5651c50)
0+ params, 2 slots, 1 upvalue, 0 locals, 4 constants, 0 functions
        1       [1]     GETTABUP        0 0 -2  ; _ENV "x"
        2       [1]     GETTABUP        1 0 -3  ; _ENV "y"
        3       [1]     ADD             0 0 1
        4       [1]     GETTABUP        1 0 -4  ; _ENV "z"
        5       [1]     SUB             0 0 1
        6       [1]     SETTABUP        0 -1 0  ; _ENV "a"
        7       [1]     RETURN          0 1
```

> 二者之间，有较大的不同。


（在本书中，我们不会讨论 Lua 的内部细节；若对这些操作码的更多细节感兴趣，请在网上搜索 `lua opcode`，应该会找到相关资料。）


预编译形式的代码，并不总是会比原始代码小，但其加载速度更快。另一个好处是，他可以防止源代码的意外更改。与源代码不同的是，被恶意破坏的二进制代码，会崩溃掉 Lua 解释器，甚至会执行用户提供的机器码。运行普通代码时，则无需担心。然而，咱们应避免运行，预编译形式的不可靠的代码。函数 `load`，有个专门用于此任务的选项。


除了必须的第一个参数外，`load` 还有另外三个参数，他们都是可选的。第二个参数，是代码块的名字，只会在错误消息中用到。第四个参数是某种环境，我们将在第 22 章 [“环境”](environment.md) 中讨论。第三个参数，就是我们在此感兴趣的参数，他控制着可以加载哪些类型的代码块。如存在，则该参数必须是个字符串：字符串 `"t"`，只会允许文本（普通）代码块；`"b"` 只会允许二进制（预编译）代码块；默认的 `"bt"` 则会同时允许这两种格式。


## 错误

*人无完人，Errare humanum est.*<sup>译注</sup>因此，我们必须以最佳方式处理错误。由于 Lua 是一门扩展语言，a extension language，经常被嵌入到应用中，因此当发生错误时，他不能简单地崩溃或退出。相反，只要发生错误，Lua 就必须提供处理方法。

> **译注**：参见：[Wikipedia: Errare humanum est](https://az.wikipedia.org/wiki/Errare_humanum_est)"Errare (Errasse) humanum est, sed in errare (errore) perseverare diabolicum." "犯错（犯了错）是人之常情，但固执于错误（错误）是魔鬼的行为。"


Lua 遇到的任何意外情况，都会抛出错误。当程序尝试对非数字值相加、调用非函数的值、对非表的值进行索引等时，都会发生错误。（我们可以使用 *元表，metatables*，修改这种行为，稍后咱们就会看到。）通过调用函数 `error`，并将错误信息作为参数，咱们也可以显式地抛出错误。通常，这个函数是在咱们代码中，发出错误信号的适当方式：


```lua
print "enter a number:"
n = io.read("n")
if not n then error("invalid input") end
```

这种根据某个条件，调用 `error` 的结构非常常见，以至于 Lua 专门为此，设计了一个内置函数，名为 `assert`：


```lua
print "enter a number:"
n = assert(io.read("n"), "invalid input")
```

函数 `assert` 会检查其第一个参数是否为假，并简单地返回该参数；如果该参数为假，`assert` 就会抛出错误。第二个参数，即消息，是可选的。不过请注意，`assert` 是个常规函数。因此，Lua 在调用函数之前，总是先求取其参数。在我们写出下面这样的代码时


```lua
n = io.read()
assert(tonumber(n), "invalid input: " .. n .. " is not a number")
```

那么 Lua 将总是会执行那个字符串连接， 即使 `n` 是个数字。在这种情况下，使用一个显式测试，可能更为明智。


当函数发现意外情况（即 *异常，exception*）时，他可以采取两种基本行为：可以返回错误代码（通常为 `nil` 或 `false`），或者可以抛出错误，即调用 `error`。两种选择之间，没有固定规则，但我（作者）会用到以下准则：容易避免的异常，应抛出错误；否则，应返回错误代码。


例如，我们来设想一下 `math.sin`。于某个表上调用他时，他应如何运行？假设他返回了某个错误代码。在我们需要检查错误时，就必须这样写：

```lua
local res = math.sin(x)
if not res then     -- 出错了吗？
    -- error-handling code
```

不过，在调用函数 *之前*，我们原本可以很容易地检查这个异常：


```lua
if not tonumber(x) then     -- 'x' 不是个数字？
    -- error-handling code
```

咱们经常既不会检查参数，也不会检查调用 `sin` 的结果；如果参数不是数字，就意味着我们的程序，可能出了问题。在这种情况下，处理异常的最简单最实用的方法，就是停止计算并发出一条错误信息。


另一方面，我们来考虑一下打开某个文件的 `io.open`。当被要求打开某个不存在的文件时，他应该如何表现？在这种情况下，在调用该函数之前，并没有检查该异常的简单方法。在许多系统中，获悉某个文件是否存在的唯一方法，就是尝试打开他。因此，如果 `io.open` 由于外部原因（如“文件不存在” 或 “权限被拒绝”），而无法打开某个文件时，他就会返回 `false`，并附带一个包含错误信息的字符串。这样，我们就有机会以适当的方式，来处理这种情况，例如，要求用户提供另一个文件名：


```lua
local file, msg
repeat
    print "enter a file name:"
    local name = io.read()
    if not name then return end     -- 无输入
    file, msg = io.open(name, "r")
    if not file then print(msg) end
until file
```

如果我们不想处理这种情况，但仍然想要确保安全，我们可以简单地使用 `assert`，来保护该操作：


```lua
file = assert(io.open(name, "r"))
    -->  cee.lua:6: 1: No such file or directory
    --> stack traceback:
    -->         [C]: in function 'assert'
    -->         cee.lua:6: in main chunk
    -->         [C]: in ?
```

这是一种典型的 Lua 习惯用法：如果 `io.open` 失败，`assert` 将抛出错误。请注意，`io.open` 第二个返回结果的错误消息，会作为 `assert` 的第二个参数。


## 错误处理与异常

**Error Handling and Exceptions**


对于许多应用程序来说，我们不需要在 Lua 中，进行任何错误处理；应用程序会完成这种处理。自应用程序的某个调用开始后，全部 Lua 的活动，都通常是要求 Lua 运行某个代码块。如果出现任何错误，该调用会返回一个错误代码，以便应用程序采取适当的措施。对于独立解释器，其主循环就只会打印出错误信息，然后继续显示提示符，和运行所给的命令。


但是，如果我们打算在 Lua 代码内，处理错误，就应该使用函数 `pcall`（ *受保护的调用，protected call*），来封装我们的代码。

假设我们打算运行某段 Lua 代码，并要捕捉运行该代码时，出现的任何错误。第一步就是要将这段代码，封装在某个函数中；通常我们会使用匿名函数，来实现这点。然后，我们就要通过 `pcall`，调用该函数：


```lua
local ok, msg = pcall(function ()
    -- some code
    if unexpected_condition then error() end
    -- some code
    print(a[i])     -- 潜在的错误：'a' 可能不是个表
    -- some code
end)

if ok then      -- 在运行受保护代码期间没有错误发生
    -- regular code
else        -- 受保护代码抛出了某个错误：就要采取恰当措施
    -- error-handling code
end
```

函数 `pcall` 会在保护模式下，调用其第一个参数，这样其就能在函数运行时，捕捉到任何错误。无论如何，函数 `pcall` 都不会抛出任何错误。如果没有错误，`pcall` 会返回 `true`，以及该调用所返回的任何值。否则，他将返回 `false`，以及错误信息。


尽管名称如此，但错误信息，却并不一定是字符串；更好的名称，是 *错误对象，error object*，因为 `pcall` 将返回，咱们传递给 `error` 的任何 Lua 值：


```lua
local status, err = pcall(function () error({code=121}) end)
print(err.code)     --> 121
```

这些机制提供了，咱们在 Lua 中，进行异常处理所需的一切。我们会以 `error`，抛出异常，以 `pcall` 捕捉异常。错误信息，则会标识出，错误的类别。


## 错误消息与栈回溯

**Error Messages and Tracebacks**


虽然我们可以将任何类型的值，用作错误对象，error object，但错误对象，则通常是一些描述出错原因的字符串。当出现内部错误，internal error（例如某次索引非表值的尝试）时，Lua 会生成一个，在这种情况下总会是个字符串的错误对象；否则，错误对象就会是，传递给函数 `error` 的值。只要对象是个字符串，Lua 就会尝试添加一些，关于错误发生位置的信息：


```lua
local status, err = pcall(function () error("my error") end)
print(err)          --> cee.lua:4: my error
```

位置信息给出了代码块的名字（示例中为 `cee.lua`）和行号（示例中为 1）。


> **译注**：原文示例代码块名字为 `stdin`，要获得原文这样的代码块名字，需要运行 `cat cee.lua | lua -`，其中的 `-`，与 `luac -` 中的一样，是 `lua` 解释器的一种输入参数：

```bash
$ lua -h
C:\tools\msys64\mingw64\bin\lua.exe: unrecognized option '-h'
usage: C:\tools\msys64\mingw64\bin\lua.exe [options] [script [args]]
Available options are:
  -e stat   execute string 'stat'
  -i        enter interactive mode after executing 'script'
  -l mod    require library 'mod' into global 'mod'
  -l g=mod  require library 'mod' into global 'g'
  -v        show version information
  -E        ignore environment variables
  -W        turn warnings on
  --        stop handling options
  -         stop handling options and execute stdin
```

> 此时，`$ cat cee.lua | lua -` 的输出为：

```bash
$ cat cee.lua | lua -
stdin:4: my error
```


函数 `error`，有个额外的，给出应报告错误级别的第二参数。我们会使用这个参数，将错误归咎于他人。例如，假设我们编写了下面这个，其第一项任务，是检查他是否被正确调用的函数：


```lua
function foo (str)
    if type(str) ~= "string" then
        error("string expected")
    end

    -- regular code
end
```

然后，有人用错误的参数调用了这个函数：


```lua
foo({x=1})
```

现在，Lua 就会将矛头指向了 `foo` -- 毕竟是他调用了 `error` -- 而不是指向真正的罪魁祸首，调用者。为了纠正这个问题，我们就要告诉 `error`，他所报告的错误，发生在调用层次结构的第二层，occured on level two in the calling hierarchy（第一层，是咱们自己的函数）：


```lua
function foo (str)
    if type(str) ~= "string" then
        error("string expected", 2)
    end

    -- regular code
end
```

通常，当发生错误时，我们会需要更多的调试信息，而不仅仅是错误发生的位置。至少，我们会想要一个，给出了导致错误的完整调用栈的栈回溯。当 `pcall` 返回错误消息时，他会销毁栈的一部分（从 `pcall` 本身，到错误点的部分）。因此，如果我们想要一个栈回溯，我们就必须在 `pcall` 返回之前，构建出栈回溯。为此，Lua 提供了 `xpcall` 函数。他的工作方式类似于 `pcall`，但他的第二个参数，是个 *消息处理函数，message hanlder funciton*。如果发生错误，Lua 就会在栈展开之前，before the stack unwinds，调用这个消息处理器函数，以便该函数可以使用调试库，来收集他想要的，有关错误的任何额外信息。两个常见的消息处理器函数，一个是会给到我们一个 Lua 提示符，以便我们可以自己检查，发生错误时发生了什么的 `debug.debug`；以及另一个会使用栈回溯，构建出扩展的错误消息的 `debug.trackback`。后者就是独立解释器，用来构建其错误消息的函数。


## 练习


<a name="exercise-16.1"></a>练习 16.1：在加载代码块时，添加一些前缀，经常是有用的。(在本章中，咱们先前曾看到过，在一个表达式被加载时，我们就往那个表达式，添加了前缀 `return`）。请编写一个工作方式与 `load` 类似，只是在加载代码块时，会添加其第一个参数（一个字符串）作为前缀的函数 `loadwithprefix`。

`loadwithprefix` 应与原本的 `load` 一样，既接受字符串形式的代码块，也应接受读取函数。即使在原始代码块是字符串时，`loadwithprefix` 也不应将前缀，与数据块连接起来。相反，他应使用适当的，首先返回前缀，然后返回原始代码块的读取函数，来调用 `load`。

练习 16.2：请编写一个函数 `multiload`，通过接收读取函数列表，来使得 `loadwithprefix` 通用化，如下面的例所示：

```lua
f = multiload("loacal x = 10;",
               io.lines("temp", "*L"),
               " print(x)")
```

在上面的示例中，`multiload` 应加载一个相当于，字符串 `"local..."`、`temp` 文件内容与字符串 `" print(x)"`三者连接的代码块。与前面练习中的 `loadwithprefix` 一样，`multiload` 不应具体连接任何内容。


练习 16.3：下 [图 16.2，“字符串重复”](#f-16.2) 中的函数 `stringrep`，使用了一种二进制乘法算法，a binary multiplication algorithm，来连接给定字符串 `s` 的 `n` 份副本。


<a name="f-16.2">**图 16.2，字符串重复**</a>


```lua
function stringrep (s, n)
    local r = ""

    if n > 0 then
        while n > 1 do
            if n % 2 ~= 0 then r = r .. s end
            s = s .. s
            n = math.floor(n / 2)
        end
        r = r .. s
    end

    return r
end
```

对于任何固定的 `n`，我们都可以通过将循环展开为 `r = r .. s`，与 `s = s .. s` 的指令序列，而创建出一个专门版本的 `stringrep` 函数：


```lua
function stringrep_5 (s)
    local r = ""
    r = r .. s
    s = s .. s
    s = s .. s
    r = r .. s
    return r
end
```

请编写一个函数，在给定 `n` 的情况下，返回专门函数 `stringrep_n`。咱们的函数不应使用闭包，而应使用适当的指令序列（`r = r .. s` 和 `s = s .. s` 的混合），构建一个 Lua 函数的文本，然后使用 `load`，生成最终函数。请将通用函数 `stringrep`（或使用该函数的闭包），与咱们定制的函数，做性能的比较。

练习 16.4： 能找到任何的 `f` 值，使调用 `pcall(pcall, f)` 返回 `false`，作为其第一个结果吗？为什么会这样？
