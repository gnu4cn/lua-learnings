# 位与字节

Lua 处理二进制数据的方式，类似于文本。Lua 中的字符串，可以包含任意的字节，几乎全部处理字符串的库函数，都可以处理任意的字节。对二进制数据，咱们甚至可以进行模式匹配。除此之外，Lua 5.3 还引入了一些额外的，二进制数据处理功能：除了整数外，他带来了打包和解包二进制数据的位运算符及函数。在本章中，我们将介绍，在 Lua 中处理二进制数据的这些功能，以及一些其他功能。


## 位运算符

从 5.3 版开始，Lua 就提供了一组标准的数字位运算符。与算术运算不同，位运算符只对整数值起作用。位运算符包括 `&`（位与运算 AND）、`|`（位或运算 OR）、`~`（位异或运算 exclusive-OR）、`>>`（逻辑右移）、`<<`（逻辑左移）和一元运算符的 `~`（位非运算 NOT）。(注意，在一些语言中，异或运算符是用 `^` 表示的。而在 Lua 中，`^` 是指幂运算。）

```lua
> string.format("%x", 0xff & 0xadcd)
cd
> string.format("%x", 0xff | 0xadcd)
adff
> string.format("%x", 0xaaaa ~ -1)
ffffffffffff5555
> string.format("%x", ~0)
ffffffffffffffff
```


（本章中的数个示例，都将用到 `string.format`，来以十六进制显示结果。）

全部位运算符，都工作于整数的全部位上。在标准 Lua 中，那就指的是 64 位。在实现那些假定了 32 位整数的算法（如加密哈希 SHA-2）时，这可能是个问题。不过，执行 32 位的整数操作，并不困难。除了右移运算外，在我们忽略高的一半二进制位时，在64 位上所有位操作，都与 32 位的同一操作一致。加法、减法和乘法也是如此。因此，要对 32 位整数进行运算，我们只需在右移之前，擦除整数的高 32 位即可。(我们很少在这类计算中，进行除法运算。）


两种移位运算符，都会用零填充空位。这通常称为逻辑移位。Lua 不提供算术右移，即用符号位，the signal bit，填充空位。以适当的 2 的幂的底除，a floor division（向下取整的除法），咱们就可以执行等价于算术移位的操作。(例如，`x // 16` 与算术移位四相同。）


负位移，negative displacement，会向另一方向移动，即 `a >> n` 与 `a << -n` 相同：


```lua
> string.format("%x", 0xff << 12)
ff000
> string.format("%x", 0xff >> -12)
ff000
```


如果位移等于或大于整数表示法中的位数（标准 Lua 中为 64 位，小型 Lua 中为 32 位），则结果为零，因为所有位都从结果中移出了：


```lua
> string.format("%x", -1 << 80)
0
```


## 无符号整数


整数的表示法，会用到一位来存储符号。因此，使用 64 位的整数，咱们能表示的最大整数是 <i>2<sup>63</sup> - 1</i>，而不是 <i>2<sup>64</sup> - 1</i>。通常，这种差别无关紧要，因为 <i>2<sup>63</sup> - 1</i> 已经很大了。但是，有的时候，由于我们要么要使用无符号整数，处理外部数据，要么要执行某些需要全部 64 位整数的算法，因此而不能为符号浪费一个位，此外，在小型 Lua 中，这种差异可能非常显著。例如，如果我们使用 32 位有符号整数，作为文件中的一个位置，我们的文件限制为 2 GB；而无符号整数，则会将这一限制翻倍。


Lua 并未提供对无符号整数的显式支持。不过，只要稍加注意，处理 Lua 中的无符号整数，就并不困难，我们现在就将看到这一点。

我们可以直接写出大于 <i>2<sup>63</sup> - 1</i> 的常数，尽管表面上会是下面这样：


```lua
> x = 3 << 62               --> 13835058055282163712
> x
-4611686018427387904
```

这里的问题，不在于那个常数，而在于 Lua 打印常数的方式：打印数字的标准方式，是将数字解释为有符号整数。我们可以使用 `string.format` 中的 `%u` 或 `%x` 选项，将整数视为无符号整数：


```lua
> string.format("%u", x)
13835058055282163712
> string.format("0x%X", x)
0xC000000000000000
```

由于有符号整数的表示方法（二进制补码，two's complement），有符号整数和无符号整数的加法、减法和乘法运算方式相同：


```lua
> string.format("%u", x)
13835058055282163712
> string.format("%u", x + 1)
13835058055282163713
> string.format("%u", x - 1)
13835058055282163711
```

（对于如此大的值，即使将 `x` 乘以二也会溢出，因此在这个示例中，我们没有包含该操作。）


对于有符号整数和无符号整数，排序运算符会以不同方式工作。当我们比较两个高位不同的整数时，问题就出现了。对于有符号整数，设置了该位的整数较小，因为他表示负数：


```lua
> 0x7fffffffffffffff < 0x8000000000000000
false
```


在咱们把这两个整数，都看作无符号整数时，这个结果显然是不正确的。因此，我们需要一种不同的操作，来比较无符号整数。为此，Lua 5.3 提供了 `math.ult`（*无符号小于*）：


```lua
> math.ult(0x7fffffffffffffff, 0x8000000000000000)
true
```

另一种比较的方式是，在执行有符号比较之前，先翻转两个操作数的符号位：


```lua
> mask = 0x8000000000000000
> (0x7fffffffffffffff ~ mask) < (0x8000000000000000 ~ mask)
true
```


无符号除法，也不同于有符号除法。下 [图 13.1 “无符号除法”](#f-13.1) 给出了无符号除法的一种算法。


<a name="f-13.1">**图 13.1，无符号除法**</a>


```lua
function Lib.udiv (n, d)
    if d < 0 then
        if math.ult(n, d) then return 0
        else return 1
        end
    end

    local q = ((n >> 1) // d) << 1
    local r = n - q * d
    if not math.ult(r, d) then q = q + 1 end
    return q
end
```

第一个测试（`d < 0`），相当于测试 `d` 是否大于 <i>2<sup>63</sup></i>。在这种情况下，商只能是 1（在 `n` 等于或大于 `d` 时）或 0。否则，我们就执行将被除数除以二的等价运算，然后将结果除以除数，再将结果乘以二。其中的右移，相当于某个无符号数除以二，结果将是一个非负的有符号整数。随后的左移，纠正了商，从而撤消了之前的除法。

一般来说，`floor floor(floor(n/2)/d)*2`（这种算法所完成的计算），并不等于 `floor((n/2)/d)*2`（正确结果）。不过，不难证明两者的差异最多为一。因此，这种算法会计算除法的余数部分（在变量 `r` 中），并检查其是否大于除数：如果是，则修正商（在商上加一），这样就完成了。


将无符号整数转换为浮点数，或从浮点数转换为无符号整数，需要进行一些调整。要将无符号整数转换为浮点数，我们可以将其转换为有符号整数，然后使用求模运算符，对结果进行修正：


```lua
> u = 0xA000000000000000        --> 11529215046068469760
> f = (u + 0.0) % 2^64
> string.format("%.0f", f)
11529215046068469760
```

因为`u + 0.0` 的值为 `-6917529027641081856`，

因为标准转换，the standard conversion，会将 `u` 视为有符号整数，故 `u + 0.0` 的值为 `-6917529027641081856`。求模运算会将该值，带回到无符号整数的范围。(在实际代码中，因为浮点数的求模运算，也能完成转换，因此咱们就不需要那个加法。）

要将浮点数转换为无符号整数，我们可以使用以下代码：


```lua
> f = 0xA000000000000000.0
> u = math.tointeger(((f + 2^63) % 2^64) - 2^63)
> string.format("0x%x", u)
0xa000000000000000
```

其中的加法，会将大于 <i>2<sup>63</sup></i> 的值，转换为大于 <i>2<sup>64</sup></i> 的值。然后求模运算符，会将该值投影到范围 <i>[0,2<sup>63</sup>)</i>，而其中的减法，则使其成为 “负” 值（即设置了最高位的值） ）。对小于 <i>2<sup>63</sup></i> 的值，加法会使其保持小于 <i>2<sup>64</sup></i>，求模运算符，不会影响到他，而减法则会恢复其原始值。


## 打包与解包二进制数据

Lua 5.3 还引入了一些二进制数据和基本值（数字和字符串）之间，进行转换的函数。函数 `string.pack`，会将值”打包” 成二进制字符串； `string.unpack` 则从二进制字符串中，提取出这些值。


`string.pack` 和 `string.unpack` 两个函数，都将其第一个参数，获取为描述数据打包方式的格式字符串。这个字符串中的每个字母，都描述了如何打包/解包某个个值；请参见以下示例：


```lua
> s = string.pack("iii", 3, -27, 450)
> #s
12
> s

> string.unpack("iii", s)
3       -27     450     13
```

这个对 `string.pack` 的调用，创建了一个其中有着，三个整数二进制码（根据描述 `"iii"`）的字符串，每个二进制编码，都编码了其对应的参数。字符串的长度，将是本机的整数大小的三倍（在我（作者）的机器上，就是4 字节的 3 倍）。而对 `string.unpack` 的调用，则会从给定的字符串中，解码出三个整数（同样根据 `"iii"`），并返回解码后的值。


为了简化迭代，函数 `string.unpack` 还会返回最后一个读取项之后，字符串中的位置。（这解释了上一个示例中，结果中为何有个 `13`。）相应地，他接受可选的，告知从何处开始读取的第三个参数。例如，下一示例，将打印出，打包在指定字符串内的全部字符串：


```lua
s = "hello\0Lua\0world\0"

local i = 1
while i <= #s do
    local res
    res, i = string.unpack("z", s, i)
    print(res)
end
    --> hello
    --> Lua
    --> world
```

正如我们将看到的，其中的选项 `z`，表示以零结尾的字符串，因此那个到 `unpack` 的调用，会从 `s` 中，提取出位置 `i` 处的字符串，并返回该字符串，以及循环的下一位置。


### 整数

对于整数的编码，有着好几个选项，每种都对应了一种本机的整数大小：`b`（`char`）、`h`（`short`）、`i`（`int`）和 `l`（`long`）；其中的选项 `j`，使用了 Lua 整数的大小。要使用某种固定的、与机器相关的大小，我们可以在 `i` 选项上，加上从一到 16 的数字。例如，`i7` 将产生出七个字节的整数。全部大小，都会检查是否溢出：


```lua
> x = string.pack("i7", 1 << 54)
> n, p = string.unpack("i7", x)
> n
18014398509481984
> string.format("0x%X", n)
0x40000000000000
> x = string.pack("i7", -(1 << 54))
> n, p = string.unpack("i7", x)
> n
-18014398509481984
> string.format("0x%X", n)
0xFFC0000000000000
> x = string.pack("i7", 1 << 55)
stdin:1: bad argument #2 to 'pack' (integer overflow)
stack traceback:
        [C]: in function 'string.pack'
        stdin:1: in main chunk
        [C]: in ?
```

我们可以打包和解包，比本机 Lua 整数更大的整数，但在解包时，其实际值，必须要适合 Lua 整数：


```lua
> x = string.pack("i12", 2^61)
> string.unpack("i12", x)
2305843009213693952     13
> x = "aaaaaaaaaaaa"            -- 伪造一个大型 12 字节的数字
> string.unpack("i12", x)
stdin:1: 12-byte integer does not fit into Lua Integer
```

每个整数选项都有一个，与相同大小的无符号整数相对应的大写版本（`B`）：


```lua
> s = "\xFF"
> string.unpack("b", s)
-1      2
> string.unpack("B", s)
255     2
```


此外，无符号整数还有一个，用于表示 `size_t` 的额外选项 `T`（ISO C 中的 `size_t` 类型，是个无符号整数，其大小足以容纳任何对象的大小）。


### 字符串

我们可以用三种表示法，打包字符串：

- 零端字符串，zero-terminated strings

- 固定长度字符串，fixed-length strings

- 以及显式长度字符串，strings with explicit length

零端字符串使用 `z` 选项。对于固定长度的字符串，我们使用 <code>c<i>n</i></code> 选项，其中 `n` 是打包字符串的字节数。字符串的最后一个选项，存储了之前带有其长度的该字符串。在这种情况下，选项的格式为 <code>s<i>n</i></code>，其中 `n` 即为用于存储长度的无符号整数的大小。例如，选项 `s1`，就会用一个字节，存储字符串长度：


```lua
s = string.pack("s1", "hello")
for i = 1, #s do print((string.unpack("B", s, i))) end
    --> 5                       （长度）
    --> 104                     （'h'）
    --> 101                     （'e'）
    --> 108                     （'l'）
    --> 108                     （'l'）
    --> 111                     （'o'）
```

在长度不符合给定的大小，Lua 会抛出错误。我们也可以使用纯 `s` 作为选项；在这种情况下，长度会存储为大小足以容纳任何字符串长度的`size_t`。(在 64 位机器中，`size_t` 通常是个 8 字节的无符号整数，对于小字符串来说，这可能会浪费空间。）


### 浮点数

对于浮点数，有着三个选项：用于单精度的 `f`，用于双精度的 `d`，而对于 Lua 的浮点数，则是 `n`。


### 字节序与对齐方式

格式字符串，还有着一些控制二进制数据的字节序和对齐方式的选项，options to control the endianese and the alignment of the binary data。默认情况下，某种格式会使用机器的本机字节顺。 `>` 选项，会将该格式中的全部后续编码，转换为大端序或 *网络字节顺序*，big endian or *network byte order*：


```lua
s = string.pack(">i4", 1000000)
for i = 1, #s do print((string.unpack("B", s, i))) end
    --> 0
    --> 15
    --> 66
    --> 64
> string.format("0x%X", (string.unpack("i4", s)))
0x40420F00
> string.format("0x%X", (string.unpack(">i4", s)))
0xF4240
```


`<` 选项，则会转换为小端序，little endian：


```lua
s = string.pack("<i2 i2", 500, 24)
for i = 1, #s do print((string.unpack("B", s, i))) end
    --> 244
    --> 1
    --> 24
    --> 0
```

最后，`=` 选项会转换回默认的机器本机字节序。

对于对齐，<code>!<i>n</i></code> 选项，会强制数据以 `n` 的倍数索引处对齐。更具体地说，如果数据小于 `n`，则按其自己的大小对齐；否则，就会在 `n` 处对齐。例如，假设我们以 `!4` 开启格式字符串，那么那些一字节的整数，将被写入一的倍数索引中（即任意索引），那些二字节的整数，将被写入二的倍数的索引中，那些四字节或更大的整数，则将被写入四的倍数索引中。选项 `!`（不带数字），会将对齐方式设置为，机器的本机对齐方式，the machine's native alignment。


函数 `string.pack` 是通过往生成的字符串添加零，直到索引有了合适的值，来完成对齐。函数 `string.unpack` 在读取字符串时，会跳过填充。对齐方式只适用于二的幂次：如果我们将对齐方式设置为四，而尝试操作一个三字节的整数，Lua 将抛出错误。

任何格式字符串在冠以 `"=!1"` 时都会工作，`"=!1"` 表示本机字节序及无对齐方式（因为每个索引，都是一的倍数）。在转换过程中的任何时候，我们都可以更改字节序和对齐方式。


如果需要，咱们可以手动添加填充。选项 `x` 表示一个字节的填充；`string.pack` 往生成的字符串，添加一个零字节；`string.unpack` 则会从主题字符串，跳过一个字节。



## 二进制文件

函数 `io.input` 和 `io.output`，始终会以 *文本模式，text mode*，打开文件。在 POSIX 中，二进制文件和文本文件没有区别。但在 Windows 这类系统中，咱们必须在 `io.open` 的模式字符串中，使用字母 `b` 这种特殊方式，打开二进制文件。


通常，我们会以 `"a"` 模式（读取整个文件）或 `"n"` 模式（读取 `n` 个字节），读取二进制数据。(行在二进制文件中没有意义。）举个简单的例子，下面的程序，会将某个文本文件，从 Windows 格式转换为 POSIX 格式，也就是将回车-换行序列，转换为换行符：


```lua
local inp = assert(io.open(arg[1], "rb"))
local out = assert(io.open(arg[2], "wb"))

local data = inp:read("a")
data = string.gsub(data, "\r\n", "\n")
out:write(data)

assert(out:close())
```

这个程序就无法使用标准 I/O 流（`stdin`/`stdout`），因为这些流是以文本模式打开的。相反，其假定了输入和输出文件的名称，是程序的参数。我们可以用下面的命令行，调用该程序：


```bash
> lua prog.lua file.dos file.unix
```

> **注意**：`> ./prog.lua file.dos file.unix` 运行方式与此一致。


再比如，下面的程序会打印出，在某个二进制文件中找到的全部字符串：


```lua
local f = assert(io.open(arg[1], "rb"))
local data = f:read("a")

local validchars = "[%g%s]"
local pat = "(" .. string.rep(validchars, 6) .. "+)\0"

for w in string.gmatch(data, pat) do
    print(w)
end
```

> *注*：对经由 Chocolatey 包包管理器安装的 PUTTY.exe 程序运行，运行这个程序的输入如下：

```zsh
$ ./str_in_bin.lua PUTTY.exe
!This program cannot be run in DOS mode.
$
`.rsrc
@.reloc
v4.0.30319
#Strings
<Module>
PUTTY.EXE
CommandExecutor
ShimProgram
EventHandler
SignalControlType
StringExtensions
mscorlib
System
Object
MulticastDelegate
System.Diagnostics
Process
get_RunningProcess
set_RunningProcess
execute
<RunningProcess>k__BackingField
RunningProcess
ERROR_ELEVATION_REQUIRED
ERROR_CANCELLED
System.Collections.Generic
IEnumerable`1
strip_shim_gen_args
quote_arg_value_if_required
SetConsoleCtrlHandler
_handler
SetHandler
Handler
Invoke
......（省略）
```


程序假定了，字符串是由六或更多个有效字符，所组成的零端序列，其中所谓有效字符，是指模式 `validchars` 接受的任何字符。在咱们的示例中，该模式包含了可打印字符。我们使用了 `string.rep` 和连接，来创建出与以零结尾的，六或六个以上 `validchars` 序列相匹配的模式。模式中的括号，捕捉的是不带那个零的字符串。


咱们的最后示例，是一个以十六进制显示出文件内容的，对某个二进制文件进行转储的程序。下 [图 13.2 “转储 `dump` 程序，dump the `dump` program”](#f-13.2)，显式了在 POSIX 机器上，应用该程序的结果。


<a name="f-13.2">**图 13.2，转储 `dump` 程序**</a>

```lua
23 21 2F 75 73 72 2F 62 69 6E 2F 65 6E 76 20 6C  #!/usr/bin/env l
75 61 0A 0A 6C 6F 63 61 6C 20 66 20 3D 20 61 73  ua..local f = as
73 65 72 74 28 69 6F 2E 6F 70 65 6E 28 61 72 67  sert(io.open(arg
5B 31 5D 2C 20 22 72 62 22 29 29 0A 6C 6F 63 61  [1], "rb")).loca
6C 20 62 6C 6F 63 6B 73 69 7A 65 20 3D 20 31 36  l blocksize = 16
0A 0A 66 6F 72 20 62 79 74 65 73 20 69 6E 20 66  ..for bytes in f
3A 6C 69 6E 65 73 28 62 6C 6F 63 6B 73 69 7A 65  :lines(blocksize
29 20 64 6F 0A 20 20 20 20 66 6F 72 20 69 20 3D  ) do.    for i =
20 31 2C 20 23 62 79 74 65 73 20 64 6F 0A 20 20   1, #bytes do.
20 20 20 20 20 20 6C 6F 63 61 6C 20 62 20 3D 20        local b =
73 74 72 69 6E 67 2E 75 6E 70 61 63 6B 28 22 42  string.unpack("B
22 2C 20 62 79 74 65 73 2C 20 69 29 0A 20 20 20  ", bytes, i).
20 20 20 20 20 69 6F 2E 77 72 69 74 65 28 73 74       io.write(st
72 69 6E 67 2E 66 6F 72 6D 61 74 28 22 25 30 32  ring.format("%02
58 20 22 2C 20 62 29 29 0A 20 20 20 20 65 6E 64  X ", b)).    end
0A 0A 20 20 20 20 69 6F 2E 77 72 69 74 65 28 73  ..    io.write(s
74 72 69 6E 67 2E 72 65 70 28 22 20 20 20 22 2C  tring.rep("   ",
20 62 6C 6F 63 6B 73 69 7A 65 20 2D 20 23 62 79   blocksize - #by
74 65 73 29 29 0A 20 20 20 20 62 79 74 65 73 20  tes)).    bytes
3D 20 73 74 72 69 6E 67 2E 67 73 75 62 28 62 79  = string.gsub(by
74 65 73 2C 20 22 25 63 22 2C 20 22 2E 22 29 0A  tes, "%c", ".").
20 20 20 20 69 6F 2E 77 72 69 74 65 28 22 20 22      io.write(" "
2C 20 62 79 74 65 73 2C 20 22 5C 6E 22 29 0A 65  , bytes, "\n").e
6E 64 0A                                         nd.
```

完整程序如下：

```lua
local f = assert(io.open(arg[1], "rb"))
local blocksize = 16

for bytes in f:lines(blocksize) do
    for i = 1, #bytes do
        local b = string.unpack("B", bytes, i)
        io.write(string.format("%02X ", b))
    end

    io.write(string.rep(" ", blocksize - #bytes))
    bytes = string.gsub(bytes, "%c", ".")
    io.write(" ", bytes, "\n")
end
```


同样，第一个程序参数，是输入的文件名；输出是常规文本，因此可以转到标准输出。程序以 16 字节为单位，读取文件。对于每个字节块，程序会写出每个字节的十六进制表示法，然后写下每个字节的文本表示法，并将控制字符改为点。我们使用 `string.rep`，来填充最后一行的空白（一般来说，最后一行不会正好有 16 个字节），从而保持对齐。


## 练习


练习 13.1：请编写一个计算无符号整数的模运算的函数。


练习 13.2：实现几种计算 Lua 整数表示法中，二进制位数的几种不同方法。


练习 13.3：如何测试某个给定整数，是否是二的幂次？


练习 13.4：请编写一个计算给定整数汉明权重的函数。（所谓数字的 *汉明权重，Hamming weight*，是指其二进制表示形式中， 一的数量。）

练习 13.5：请编写一个测试某个给定整数的二进制表示，是否为回文，a palindrome，的函数。

练习 13.6：请用 Lua 实现 *位数组，bit array*。他应支持以下运算：

- `newBitArray(n)`，创建出有着 `n` 个二进制位的数组；

- `setBit(a, n, v)`，将布尔值 `v` 赋值给数组 `a` 的 `n` 位；

- `testBit(a, n)`，以 `n` 位的值，返回一个布尔值。


练习 13.7：假设我们有个包含了一系列记录的二进制文件，每条记录的格式如下：


```C
struct Record {
    int x;
    char[3] code;
    float value;
};
```


请编写一个读取该文件，并打印出 `value` 字段总和的程序。
