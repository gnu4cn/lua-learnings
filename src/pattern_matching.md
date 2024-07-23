# 模式匹配

与其他几种脚本语言不同，Lua 在进行模式匹配时，既不使用 POSIX 正则表达式，也不使用 Perl 正则表达式。做出这一决定的主要原因，在于规模：POSIX 正则表达式的典型实现，需要 4000 多行代码，是全部 Lua 标准库总和的一半还多。相比之下，Lua 中模式匹配的实现，只需不到 600 行代码。当然，Lua 中的模式匹配，并不能像完整的 POSIX 实现那样，做到所有事情。不过，Lua 中的模式匹配，是一个强大的工具，他包含了一些标准 POSIX 实现，难以企及的功能。


## 模式匹配函数


字符串库提供了基于 *模式，patterns* 的四个函数。我们已经简要介绍了 `find` 和 `gsub`；另外两个函数是 `match` 和 `gmatch`（ *全局匹配* ）。现在我们将详细了解他们。


### 函数 `string.find`


函数 string.find 会在给定主题字符串里，检索某种模式。模式的最简单形式，是只匹配其自身副本的一个单词。例如，模式 `"hello"`，就将搜索主题字符串中的子串 `"hello"`。`string.find` 找到模式后，会返回两个值：匹配开始的索引，与匹配结束的索引。如果没有找到匹配，则返回 `nil`：


```lua
s = "hello world"
i, j = string.find(s, "hello")
print(i, j)                     --> 1       5
print(string.sub(s, i, j))      --> hello
print(string.find(s, "world"))  --> 7       11
i, j = string.find(s, "l")
print(i, j)                     --> 3       3
print(string.find(s, "lll"))    --> nil

s = "这是一个测试"
print(string.find(s, "测试"))   --> 13      18
```

匹配成功时，咱们便可以 `find` 返回的值，调用 `string.sub`，来获取到主题字符串中，与模式匹配的部分。对于简单模式，这必然是模式本身。


函数 `string.find`，有两个可选参数。第三个参数是告知在主题串中的哪个位置，开始检索的一个索引。第四个参数是个布尔值，表示普通检索，a plain search。顾名思义，普通检索会在主题中，进行普通的 “查找子串” 检索，does a plain "find substring" search，不考虑模式：


```lua
> string.find("a [word]", "[")
stdin:1: malformed pattern (missing ']')
stack traceback:
        [C]: in function 'string.find'
        stdin:1: in main chunk
        [C]: in ?
> string.find("a [word]", "[", 1, true)
3       3
```

在第一次调用中，该函数会抱怨，因为在模式中，`"["` 有着特殊含义。而在第二次调用中，该函数会将 `"["` 视为简单字符串。请注意，若没有第三个可选参数，我们就无法传递第四个可选参数。


### 函数 `string.match`


函数 `string.match` 与 `find` 类似，也是在字符串中检索模式。不过，与返回找到模式的位置不同，他会返回主题字符串中，与模式匹配的部分：


```lua
print(string.match("hello world", "hello"))     --> hello
```

对于 `"hello"` 这种固定模式，该函数毫无意义。在与可变（变量）模式，variable patterns，一起使用时，他就会显示出他的威力，就像下面这个示例一样：


```lua
date = "Today is 9/11/2023"
d = string.match(date, "%d+/%d+/%d+")
print(d)    --> 9/11/2023
```

很快，我们就将讨论模式 `"%d+/%d+/%d+"` 的含义，以及 `string.match` 的更多高级用法。


### 函数 `string.gsub`


函数 `string.gsub` 有着三个必选参数，three mandatory parameters：主题字符串，a subject string、模式，a pattern 以及替换的字符串，a replacement。他的基本用途，是用替换字符串替代主题字符串中，所有出现的模式：


```lua
s = string.gsub("Lua is cute", "cute", "great")
print(s)        --> Lua is great

s = string.gsub("all lii", "l", "x")
print(s)        --> axx xii

s = string.gsub("Lua is great", "Sol", "Sun")
print(s)        --> Lua is great
```


可选的第四个参数，会限制替换次数：

```lua
s = string.gsub("all lii", "l", "x", 1)
print(s)        --> axl lii

s = string.gsub("all lii", "l", "x", 2)
print(s)        --> axx lii
```

`string.gsub` 的第三个参数，除了可以是替换字符串外，还可以是个被调用（或被索引），以生成替换字符串的函数（或表）；我们将在 [“替换物，replacements”](#替换物) 小节，介绍这一功能。

函数 `string.gsub` 还会返回作为第二个结果的替换次数。


```lua
s, n = string.gsub("all lii", "l", "x")
print(s, n)     --> "axx xii"       3
```


### 函数 `string.gmatch`


函数 `string.gmatch` 会返回，对字符串中某种模式的全部存在，加以迭代的一个函数（即：迭代器，iterator？）。例如，下面的示例，会收集给定字符串 `s` 的所有单词：


```lua
s = "Most pattern-matching libraries use the backslash as an escape. However, this choice has some annoying consequences. For the Lua parser, patterns are regular strings."

words = {}
for w in string.gmatch(s, "%a+") do
    words[#words + 1] = w
end
```


正如我们即将讨论到的，模式 `"%a+"` 会匹配一个或多个字母字符的序列（即单词）。因此，其中的 `for` 循环，将遍历主题字符串中的所有单词，并将他们存储在列表 `words` 中。


## 模式

大多数模式匹配库，都将反斜杠（`/`），用作了转义字符。不过，这种选择，会带来一些令人讨厌的后果。对于 Lua 解析器来说，模式就是一些常规字符串。他们没有特殊待遇，遵循了与其他字符串相同的规则。只有模式匹配函数，才将他们解释为模式。因为反斜杠是 Lua 中的转义字符，因此我们必须将其转义，才能将其传递给任何函数。模式原本就很难读懂，到处写 `"\\"` 而不是 `"\"`，也无济于事。


通过使用长字符串，将模式括在双重方括号之间，咱们就可以改善这个问题。（某些语言就推荐这种做法。）然而，对于通常较短的模式来说，长字符串表示法，似乎有些繁琐。此外，我们将失去在模式内部使用转义的能力。（一些模式匹配工具，则通过重新实现通常的字符串转义，绕过了这种限制。）


Lua 的解决方案就更简单了：Lua 中的模式，将百分号用作了转义符。(C 语言中的几个函数，如 `printf` 和 `strftime`，也采用了同样的解决方案）。一般来说，任何转义过的字母数字字符，都具有某种特殊含义（例如，`"%a"` 就匹配任意字母），而任何转义的非字母数字字符，都代表其本身（例如，`"%."` 匹配点）。


我们将从 *字符类，character classes*，开始讨论模式。所谓字符类，是某个模式中，可以匹配到特定字符集中，任何字符的一个项目。例如，字符类 `%d`，就可以匹配任何数字。因此，我们可以使用 `"%d%d/%d%d/%d%d%d"` 模式，检索格式为 `dd/mm/yyyy` 的日期：


```lua
s = "Deadline is 30/11/2023, firm"
date = "%d%d/%d%d/%d%d%d%d"
print(string.match(s, date))    --> 30/11/2023
```

下表列出了那些预定义的字符类，及其含义：


| 字符类 | 含义 |
| :-- | :-- |
| `.` | 全部字符 |
| `%a` | 字母，包括大小写, `a-zA-Z`） |
| `%c` | 控制字符，control characters |
| `%d` | 数字，`0-9`）|
| `%g` | 除空格外的可打印字符，printable characters except spaces |
| `%l` | 小写字母 |
| `%p` | 标点符号，punctuation characters |
| `%s` | 空格 |
| `%u` | 大写字母 |
| `%w` | 字母和数字字符 |
| `%x` | 十六进制数字，`0-9a-fA-F`？ |



任意这些类的大写版本，表示该类的补集，the complement of the class。例如，`"%A"`，就表示所有的非字母字符：


```lua
> print((string.gsub("hello, up-down!", "%A", ".")))
hello..up.down.
>
> print((string.gsub("hello, 1, 2, 3...up-down!", "%A", ".")))
hello............up.down.
```

（在打印 `gsub` 的结果时，我<作者>使用了额外括号，来丢弃第二个结果，即替换次数。）


有些称为 *魔法字符，magic characters* 的字符，在模式中使用时，有着特殊含义。Lua 中的模式，用到以下这些魔法字符：


```lua
( ) . % + - * ? [ ] ^ $
```

如同我们所看到的，百分号可作为这些魔法字符的转义字符。因此，`"%?"` 会匹配问号，而 `"%%"` 会匹配百分号本身。我们不仅可以转义魔法字符，还可以转义任何的非字母数字字符，non-alphanumeric character。在不确定时，就要谨慎行事，而使用转义。


而 *字符集，char-set* 则允许我们，通过将一些单个字符，以及一些类，组合在方括号内，而创建出咱们自己的字符类。例如，字符集 `"[%w_]"`，会同时匹配字母数字字符及下划线，`"[01]"` 会匹配二进制数字，而 `"[%[%]]"` 则会匹配方括号。要计算文本中元音字母的数量，我们可以写这样的代码：


```lua
_, nvow = string.gsub(text, "[aeiouAEIOU]", "")
```

在字符集中，咱们还可以包含字符范围，方法是写出范围内的第一和最后一个字符，中间用连字符分隔。我（作者）很少使用这一功能，因为大多数有用的范围，都是预定义的；例如，`"%d"` 取代了 `"[0-9]"`，而 `"%x"` 取代了 `"[0-9a-fA-F]"`。不过，如果咱们需要找到某个八进制数字，则可能会更喜欢 `"[0-7]"`，而不是 `"[01234567]"` 这样的明确列举。


通过以插入符号（`^`），开始任何字符集，咱们就可以得到他们的补集：模式 `"[^0-7]"` 可以找到任何非八进制数字的字符，而 `"[^/n]"` 则可匹配任何不同于换行符的字符。不过，请记住，咱们可以用简单类的大写字母版本，来对简单类取反：相比比 `'[^%s]'`，`'[%S]'` 要更简单。


通过重复和可选部分的修饰符，modifiers for repititions and optional parts，咱们可以使模式更加有用。 Lua 中的模式，提供四种修饰符：


| 修饰符 | 意义 |
| :-- | :-- |
| `+` | 1 次或多次的重复 |
| `*` | 0 次或多次的重复 |
| `-` | 0 次或多次惰性重复，0 or more lazy repititions |
| `?` | 可选的（0 或 1 次出现） |


> **注意**：关于惰性重复，请参阅：[What do 'lazy' and 'greedy' mean in the context of regular expressions?](https://stackoverflow.com/a/2301298)


加号修饰符，the plus modifier, `+`，会匹配原始类的一或多个字符。他总是会获取与该模式相匹配的最长序列（贪婪模式，greedy）。例如，模式 `"%a+"` 表示一或多个的字母（即某个单词）：


```lua
> print((string.gsub("one, and two; and three", "%a+", "word")))
word, word word; word word
```

模式 `'%d+'` 会匹配一或多个的数字（即某个整数）：


```lua
> print(string.match("the number 1298 is even", "%d+"))
1298
```

星号修饰符，the asterisk modifier, `*`，与加号类似，但他还接受原始类字符的零次出现，it also accepts zero occurrences of characters of the class。其典型用法，是匹配模式中，各部分之间的可选空格。例如，要匹配某个空括号对，比如 `()` 或 `( )`，我们可以使用模式 `"%(%s*%)"`，其中的模式 `"%s*"`，会匹配零或多个的空格。（括号在模式中有着特殊意义，因此咱们必须转义他们。）再比如，模式 `"[_%a][_%w]*"`，会匹配 Lua 程序中的标识符：以字母或下划线开头，后面跟零或多个下划线或字母数字字符的序列。

与星号一样，减号修饰符，the minus modifier，`-`，也会匹配原始类的字符的零或多次出现。不过，他不是匹配最长的序列，而是匹配最短的序列。在有的时候，星号和减号并没有什么区别，但通常情况下，他们给出的结果却大相径庭。例如，在试图查找一个格式为 `"[_%a][_%w]-"` 的标识符时，我们将只会找到第一个字母，因为 `"[_%w]-"` 总是会匹配空序列。另一方面，假设我们打算删除某个 C 程序中的注释。许多人首先会尝试使用 `"/%*.*%*/"`（即使用正确的转义写出的，一个 `"/*"`，后跟任意字符序列，最后跟 `*/`）。然而，由于 `'.*'` 会尽可能地远地扩展，从而程序中的第一个 `"/*"`，将只会以最后一个 `"*/"` 结束：


```lua
test = "int x; /* x */  int y; /* y */"
print((string.gsub(test, "/%*.*%*/", "")))  --> int x;
```

相反，模式 `'.-'` 将仅尽可能地以找到第一个 "*/" 进行扩展，从而咱们就会得到所期望的结果：

```lua
test = "int x; /* x */  int y; /* y */"
print((string.gsub(test, "/%*.-%*/", "")))  --> int x;  int y;
```

最后一个修饰符，即问号，the question mark，`?`，用于匹配某个可选字符。举个例子，假设我们想在文本中查找，其中数字可以包含某个可选符号的整数。模式 `"[+-]?%d+"` 可以匹配 `"-12"`、`"23"` 和 `"+1009"` 等数字。字符类 `"[+-]"` 可以匹配加号或减号；接着的 `"?"` 使这个符号成为可选的。


与其他系统不同的是，在 Lua 中，我们只能将修饰符，应用于某个字符类；而在修改器下，不能对模式进行分组，there is no way to grup patterns under a modifier。例如，匹配某个可选单词的模式，就不存在（除非该单词只有一个字母）。通常情况下，我们可以使用本章最后将介绍的一些高级技巧，来规避这一限制。


如果某个模式以插入符号（`"^"`）开头，则他将仅在主题字符串的开头匹配。与此类似，如果他以美元符号（`"$"`）结尾，则他仅在主题字符串的末尾匹配。我们可以使用这些符号，来限制我们找到的匹配项，以及锚定模式，anchor patterns。例如，下一个测试，会检查字符串 `s` 是否以数字开头：


```lua
if string.find(s, "^%d") then ...
```

下一个则是检查该字符串，是否表示某个不含任何其他前导，或尾随字符的整数：


```lua
if string.find(s, "^[+-]?%d+$") then ...
```

插入符号和美元符号，仅在模式的开头或结尾使用时，才具有魔力。否则，他们将充当与自身匹配的常规字符。


模式中的另一个项目，便是 `"%b"`，他会匹配到平衡字符串，balanced strings。我们将此项目写为 `"%bxy"`，其中 `x` 和 `y` 是任意两个不同的字符； `x` 充当开始字符，`y` 充当结束字符。例如，模式 `'%b()'`，会匹配字符串中，以左括号开头并以对应的右括号结束的部分：


```lua
s = "a (enclosed (in) parentheses) line"
print((string.gsub(s, "%b()", "")))     --> a  line
```

通常，我们将这种模式用作 `"%b()"`、`"%b[]"`、`"%b{}"`或 `"%b<>"`，但也可以使用任意两个不同的字符，作为分隔符。


最后，项目 `"%f[char-set]"` 表示 *先锋模式，frontier pattern*。只有当下一字符在 `char-set` 中，且上一字符不在 `char-set` 中时，他才会匹配到空字符串：


```lua
s = "the anthem is the theme"
print((string.gsub(s, "%f[%w]the%f[%W]", "one")))   --> one anthem is one theme
```

模式 `"%f[%w]"` 会匹配到，非字母数字字符与字母数字字符之间的边界，而模式 `"%f[%W]"` 则会匹配到，字母数字字符与非字母数字字符之间的边界。因此，上面所给定的模式，只会匹配作为整个单词的字符串 `"the"`。请注意，即使是单个字符集，我们也必须将字符集写在方括号内。

> **注意**：要进一步了解 `%f` 边界模式，请参阅 [Frontier Pattern](http://lua-users.org/wiki/FrontierPattern)。

边界模式将主题字符串中，第一个字符之前和最后一个字符之后的那些位置，视为他们具有空字符（即 ASCII 代码零）。在前面的示例中，第一个 `"the"`，就以空字符（不在集合 `"[%w]"` 中），和 `t`（在集合中）之间的边界开始。


## 捕获物


*捕获，capture* 机制，允许某个模式，将主题字符串中，与该模式的部分匹配的部分提取出来，以供进一步使用。通过在括号中写下想要捕获的部分，咱们就可以指定出某个捕获。


当模式有捕获值时，函数 `string.match` 会将每个捕获值，作为一个单独的结果返回；换句话说，他会将字符串，分解成其捕获到的部分。


```lua
pair = "name = Anna"
k, v = string.match(pair, "(%a+)%s*=%s*(%a+)")
print(k, v)     --> name    Anna
```

其中的模式 `"%a+"`，指定一个非空的字母序列；模式 `"%s*"` 指定了一个可能为空的空格序列。因此，在上面的示例中，整个模式指定了一串字母，后面是一串空格，后面是等号，再度后面是空格，再加上另一串字母。这两个字母序列，都用括号括了起来，以便在出现匹配时捕获他们。下面是一个类似的示例：


```lua
d, m, y = string.match(date, "(%d+)/(%d+)/(%d+)")
print(d, m, y)  --> 09      11      2023
```

在此示例中，我们使用了三个捕获，每个数字序列一个。


在模式中，`"%n"` 这样的项目（其中 `n` 是一位数字），只会匹配第 `n` 个捕获的副本。一个典型的例子是，假设我们想在一个字符串中，查找一个由单引号或双引号括起来的子串。我们可以尝试使用 `"["'].-["']"` 这样的模式，即一个引号后跟任何内容，然后再跟一个引号；但我们在处理 `"it's all right"` 这样的字符串时，会遇到问题。为了解决这个问题，我们可以捕捉第一个引号，并利用他来指定出第二个引号：


```lua
s = [[then he said: "it's all right"!]]
q, quotedPart = string.match(s, "([\"'])(.-)%1")
print(q, quotedPart)    --> "       it's all right
```

第一个捕获的是引号字符本身，第二个捕获的是引号的内容（与 `".-"` 匹配的子串）。


类似的例子还有下面这个模式，他可以匹配 Lua 中的长字符串：


```lua
%[(=*)%[(.-)%]%1%]
```

他将匹配一个开头的方括号，然后是零个或多个等号，接着是另一个开头方括号，接着是任何内容（字符串内容），接着是一个结尾方括号，接着是相同数量的等号，接着是另一个结尾方括号：


```lua
p = "%[(=*)%[(.-)%]%1%]"
s = "a = [=[[[ something ]] ]==] ]=]; print(a)"
print(string.match(s, p))   --> =       [[ something ]] ]==]
```

第一个捕获，是等号序列（本例中只有一个等号）；第二个捕获就是字符串内容。


捕获到值的第三种用途，是在 `gsub` 的替换字符串中。与模式一样，替换字符串也可以包含类似 `"%n"` 这样的项目，在替换时，这些项目会被修改为相应的捕获值。特别的，`"%0"` 这个项目，会成为整个匹配项。(顺便说一下，替换字符串中的百分号，必须被转义为 `"%%"`。）例如，下面的命令，会复制字符串中的每个字母，并在副本之间，加上连字符：


```lua
print((string.gsub("hello lua!", "%a", "%0-%0")))
    --> h-he-el-ll-lo-o l-lu-ua-a!
```

下面这个示例，会交换相邻的字符：


```lua
print((string.gsub("hello Lua", "(.)(.)", "%2%1")))
    --> ehll ouLa
```

举个更有用的例子，咱们来编写一个原始的格式转换器，a primitive format converter，他可以获取带有以 LaTeX 风格编写的命令的一个字符串，并将其转换为 XML 风格的格式：


```text
\command{some text}     -->     <command>some text</command>
```

在我们不允许嵌套命令的情况下，下面的这个对 `string.gsub` 的调用，就可以完成这项工作：


```lua
s = [[the \quote{task} is to \em{change} that.]]
s = string.gsub(s, "\\(%a+){(.-)}", "<%1>%2<%1>")
print(s)    --> the <quote>task<quote> is to <em>change<em> that.
```

（下一小节，我们将看到如何处理嵌套的命令。）

另一个有用的例子，是如何修剪字符串，how to trim a string：

```lua
function Lib.trim(s)
    s = string.gsub(s, "^%s*(.-)%s*$", "%1")
    return s
end
```

用法：

```lua
> Lib.trim("This is a string with tail spaces.    ")
This is a string with tail spaces.
```

请注意其中模式修饰符的明智使用。两个锚点（`^` 和`$`），确保了我们得到整个字符串。由于中间的 `'.-'` 会尽量少地扩展，因此两个封闭模式 `'%s*'`，会匹配到两端的所有空格。


## 替代物

**Replacements**


如同我们已经看到的，除了字符串外，咱们可以使用函数或表，作为 `string.gsub` 的第三个参数。在以某个函数调用到他时，`string.gsub` 会在每次找到匹配的字符串时，调用该函数；每次调用的参数，都是捕获到的字符串，函数返回的值，将成为替换字符串。在使用表调用到他时，`string.gsub` 会将首个捕获物用作键，查找表格，并使用关联的值，作为替换字符串。如果调用或表查找的结果为空，`gsub` 就不会更改该次匹配。


作为第一个例子，下面的函数会执行变量的展开：他会将字符串中出现的每一个 `$varname`，替换为全局变量 `varname` 的值：


```lua
function expand (s)
    return (string.gsub(s, "$(%w+)", _G))
end

name = "Lua"; status = "great"
print(expand("$name is $status, isn't it?"))
    --> Lua is great, isn't it?
```


(如同我们将在第 22 章 [*环境*](environment.md) 中将详细讨论到的，`_G` 是个包含了所有全局变量的预定义表。）对于每个与 `"$(%w+)"`（美元符号后跟一个名字）匹配项，`gsub` 都会在全局表 `_G` 中，查找捕获到的名字；插座结果会替换掉匹配项。如果表中没有那个键，则不会进行替换：


```lua
print(expand("$othername is $status, isn't it?"))
    --> $othername is great, isn't it?
```

在我们不能确定，给定变量是否具有字符串值时，我们可能会希望，对其值应用 `tostring`。在这种情况下，我们可以使用函数，作为替代值：


```lua
function expand (s)
    return (string.gsub(s, "$(%w+)", function (n)
        return tostring(_G[n])
    end))
end

name = "Lua"; status = "great"
print(expand("$name is $status, isn't it?"))
    --> Lua is great, isn't it?


print(expand("print = $print; a = $a"))
    --> print = function: 00007ffdc4d0f640; a = nil
```

在 `expand` 里，每当匹配到 `"$(%w+)"` 时，`gsub` 就会调用那个以捕获到的名字，为参数给到的函数；返回的字符串，会替换匹配的字符串。


最后一个例子，又回到了上一节的格式转换器。我们要再次将 LaTeX 风格（`\example{text}`）的命令，转换为 XML 风格（`<example>text</example>`），但这次会允许嵌套的命令。下面的函数，使用了递归，来完成这项工作：


```lua
function toxml (s)
    s = string.gsub(s, "\\(%a+)(%b{})", function (tag, body)
        body = string.sub(body, 2, -2)  --> 移除花括号
        body = toxml(body)              --> 处理嵌套的命令
        return string.format("<%s>%s</%s>", tag, body, tag)
    end)
    return s
end

print(toxml("\\title{The \\bold{big} example}"))
    --> <title>The <bold>big</bold> example</title>
```


### URL 编码

咱们的下一个示例，将用到作为 HTTP 用于发送 URL 中所嵌入参数编码的 *URL 编码，URL encoding*。这种编码，会将特殊字符（如 `=`、`&` 和 `+`），表示为 `"%xx"`，其中的 `xx`，是字符的十六进制代码。之后，他会将空格修改为加号。例如，他会将字符串 `"a+b = c "`，编码为 `"a%2Bb+%3D+c"`。最后，它会在写下每对参数名和参数值时，在中间加上等号，并在所有结果对 `name = value` 之间，加上一个 `&` 符号。例如，下面这些值

```url
name = "a1"; query = "a+b = c"; q="yes or no"
```

会被编码为 `name=a1&query=a%2Bb+%3D+c&q=yes+or+no`。

现在，假设我们打算解码此 URL，并按每个值所对应的名称进行索引，将他们存储在一个表中。以下函数会执行基本的解码：


```lua
function unescape (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

print(unescape("a%2Bb+%3D+c"))  --> a+b = c
```

首个 `gsub`，会将字符串中的每个加号，更改为空格。第二个 `gsub`，则会匹配前面带有百分号的所有两位十六进制数字，并为每个匹配，调用一个匿名函数。该函数将十六进制数字，转换为数字（使用基数为 16 的 `tonumber`），并返回相应的字符（`string.char`）。

为了解码 `name=value` 这样键值对，我们要用到 `gmatch`。因为名称和值，都不能包含 `&` 符号或等号，所以我们可以将他们与模式 `"[^&=]+"` 相匹配：

```lua
cgi = {}
function decode (s)
    for n, v in string.gmatch(s, "([^&=]+)=([^&=]+)") do
        n = unescape(n)
        v = unescape(v)
        cgi[n] = v
    end
end
```

对 `gmatch` 的调用，会匹配到 `name=value` 形式的所有对。而对于每一对，迭代器都会返回相应的捕获（由匹配字符串中的括号标记），作为 `n` 和 `v` 的值。循环体只是将 `unescape`，应用于这两个字符串，并将该对存储在 `cgi` 表中。

与此对应的编码，也很容易编写。首先，我们要编写 `escape` 函数；该函数会将所有特殊字符，编码为百分号，后跟十六进制的字符代码（`format` 选项 `"%02X"`，会生成有着两位的十六进制数，使用 `0` 进行填充），然后将空格更改为加号：


```lua
function escape (s)
    s = string.gsub(s, "[&=+%%%c]", function (c)
        return string.format("%%%02X", string.byte(c))
    end)
    s = string.gsub(s, " ", "+")
    return s
end
```

`encode` 函数，会遍历要编码的表，构建出结果字符串：


```lua
function encode (t)
    local b = {}
    for k, v in pairs(t) do
        b[#b + 1] = (escape(k) .. "=" .. escape(v))
    end

    -- 连接 'b' 中所有的条目，以 ”&“ 分开
    return table.concat(b, "&")
end

t = {name = "al", query = "a+b = c", q = "yes or no"}
print(encode(t))    --> query=a%2Bb+%3D+c&name=al&q=yes+or+no
```

### 制表符的展开

**Tab expansion**


像 `"()"` 这样的空捕获，在 Lua 中具有特殊含义。该模式并非不捕获任何内容（无用的任务），而是捕获其在主题字符串中，作为一个数字的位置：

```lua
print(string.match("hello", "()ll()"))  --> 3       5
```

（请注意，此示例的结果，并不同于与我们从 `string.find` 得到的结果，因为第二个空捕获的位置，是在匹配 *之后*。）

位置捕获运用的一个很好的例子，便是展开字符串中的制表符：

```lua
function expanTabs (s, tab)
    tab = tab or 8      -- 制表符的 ”大小“ （默认为 8）
    local corr = 0      -- 校准量

    s = string.gsub(s, "()\t", function (p)
        local sp = tab - (p - 1 + corr)%tab
        corr = corr - 1 + sp
        return string.rep(" ", sp)
    end)
    return s
end

print(expandTabs("name\tage\tnationality\tgender", 8))
    --> name    age     nationality     gender
```

其中 `gsub` 的模式，会匹配字符串中的所有制表符，捕获到他们的位置。对于每个制表符，匿名函数会使用此位置，来计算出到达为制表符倍数的列，所需的空格数：他从位置中减去 `1`，以使其相对于零，并加上 `corr`，以补偿先前的制表符。 （每个制表符的展开，都会影响后续制表符的位置。）然后更新下一个制表符的校准量：减去 `1` 是因为这个正要被删除选项卡，而加上 `sp` 则是因为那些正要添加的空格。最后，他返回了一个要替换制表符的，有着正确数量空格的字符串。

为了完整起见，我们来看看，如何反转此操作，将空格转换为制表符。第一种方法还是可能涉及到，使用空捕获来操作位置，但有一个更简单的解决办法：咱们在字符串的每八个字符处，插入一个标记。然后，只要标记前面有空格，我们就用一个制表符，替换掉该空格-标记序列，wherever the mark is preceded by spaces, we replace the sequence spaces-mark by a tab：

```lua
function unexpandTabs (s, tab)
    tab = tab or 8
    s = expandTabs(s, tab)

    local pat = string.rep(".", tab)
    s = string.gsub(s, pat, "%0\1")
    s = string.gsub(s, " +\1", "\\t")
    s = string.gsub(s, "\1", "")
    return s
end
```

该函数以展开字符串，删除任何先前的选项卡开始。然后，他计算出用于匹配所有的八个字符序列的一种辅助模式，并使用该模式在每八个字符后，添加一个标记（控制字符 `\1`）。然后，他用一个制表符，替换掉后跟标记的一或多个空格的所有序列。最后，他删除了留下的标记（那些前面没有空格的标记）。

> **注意**，`s = string.gsub(s, pat, "%0\1")` 语句中的 `%0`，是 [捕获物](#捕获物) 小节中，提到的 `%n` 语法，表示全部匹配项。
>
> **译注**：原文中，`s = string.gsub(s, " +\1", "\\t")` 这条语句原本为 `s = string.gsub(s, " +\1", "\t")`，少了一个字符串的反斜杠转义，达不到逆展开的目的。

### Tricks of the Trade


模式匹配是操纵字符串的强大工具。只需调用几次 `string.gsub`，咱们就可以执行许多复杂的操作。然而，就像任何强大的工具一样，我们必须谨慎使用。

模式匹配并不能替代恰当的解析器。对于一些快速而肮脏的程序，quick-and-dirty programs，我们可以对源代码一些进行有用的操作，但可能很难构建出高质量的产品。作为一个很好的例子，考虑那些我们用来匹配 C 程序中注释的模式： `'/%*.-%*/'`。如果程序中有一个包含 `"*/"` 的字面字符串，我们就可能会得到错误的结果：


```lua
test = [[char s[] = "a /* here"; /* a tricky string */]]
print((string.gsub(test, "/%*.-%*/", "<COMMENT>")))
    --> char s[] = "a <COMMENT>
```

包含如此内容的字符串，并不多见。就我们自己的使用而言，这种模式可能会起到作用，但我们不应该发布有这种缺陷的程序，a program with such a flaw。

通常情况下，对于 Lua 程序来说，模式匹配已经足够高效：我的新机器计算一个 4.4 MB 文本（850 K 个单词） 中的所有单词，只需不到 0.2 秒。<sup>注 1</sup>我们应尽可能使模式具体；松散的模式，比具体的模式要慢。一个极端的例子是 `"(.-)%$"`，用于获取某个字符串中，第一个美元符号之前的所有文本。如果主题字符串中有一个美元符号，则一切顺利，但请设想一下，字符串中不包含任何美元符号。算法首先会尝试从字符串的第一个位置，开始匹配模式。他将遍历所有字符串，寻找美元符号。当字符串结束时，模式会在字符串的 *第一个位置* 失败，*for the first position* of the string。然后，算法会从字符串的第二个位置开始，再次进行整个搜索，结果发现该位置也没有匹配到模式，这样就重复着对字符串中，每个位置的搜索。这将花费次方时间，`O(n^2)`，a quadratic time，<sup>注 2</sup>在我的新机器上，一个 20 万字符的字符串，需要四分多钟。只需以 `"^(.-)% $"`，将该模式锚定于字符串的首个位置，咱们就能解决这个问题。锚点告诉算法，如果在第一个位置找不到匹配，就停止搜索。使用锚点后，匹配过程只需百分之一秒。

> **注 1**：“我的新机器” 是台英特尔酷睿 i7-4790 3.6 GHz，8 GB 内存的机器。我（作者）在这台机器上，测量了本书中的所有性能数据。
>
> **注 2**：这个“次方时间”，讲的是算法的时间复杂度问题，参阅：[[演算法]Big O and Time Complexity](https://medium.com/@yunyubee/%E6%BC%94%E7%AE%97%E6%B3%95-big-o-and-time-complexity-65f2dfafe9d1)

还要小心空模式，即匹配到空字符串的模式。例如，如果我们尝试用 `"%a*"` 这样的模式来匹配名称，我们就会发现，到处都是名称：


```lua
i, j = string.find(";$%  **#$hello13", "%a*")
print(i, j)     --> 1       0
```

在这个示例中，对 `string.find` 的调用，就正确地发现了字符串开头的空字母序列，an empty sequence of letters at the beginning of the string。


编写以减号修饰符（`-`）结尾的模式，是毫无意义的，因为他只能匹配到空字符串。这个修饰符后面，总是需要一些东西来锚定其展开，to anchor its expansion。同样，包含了 `'.*'` 的模式，也很棘手，因为这种结构的扩展范围，远远超出了我们的预期。

有时，使用 Lua 本身，来构建模式也很有用。我们已经在将空格转换为制表符的函数中，使用过这种技巧。再举个例子，我们来看看如何在文本中找到一些长行，比如超过 70 个字符的那些行。所谓长行，是指与换行符不同的 70 或更多个字符的序列。我们可以用字符类 `"[^//n]"`，来匹配与换行符不同的单个字符。因此，我们可以用重复了 70 次单个字符模式的模式，匹配到某个长行，最后重复一次该模式（以匹配该行的其余部分）。我们可以使用 `string.rep`，来创建出这种模式，而不是手工编写：


```lua
pattern = string.rep("[^\n]", 70) .. "+"
```

再举个例子，假设我们打算进行大小写不敏感的检索。一种方法是，将模式中的任何字母 `x`，改为 `"[xX]"` 类，即同时包括原始字母的大小写字母的类。我们可以用一个函数，自动完成这种转换：


```lua
function nocase (s)
    s = string.gsub(s, "%a", function (c)
        return "[" .. string.lower(c) .. string.upper(c) .. "]"
    end)
    return s
end

print(nocase("Hi there!"))      --> [hH][iI] [tT][hH][eE][rR][eE]!
```

有时，我们希望用 `s2`，替换 `s1` 的每次普通出现，而不将任何字符，视为魔法字符。如果字符串 `s1` 和 `s2` 都是是字面值，我们可以在编写字符串时，为魔法字符添加适当的转义字符。而如果这两个字符串是变量值，我们可以使用另一个 `gsub`，为我们添加转义字符：


```lua
s1 = string.gsub(s1, "(%W)", "%%%1")
s2 = string.gsub(s2, "%%", "%%%%")
```

在检索字符串中，我们转义了所有非字母数字字符（因此是大写的 `W`）。而在替换字符串中，我们只转义了百分号。

另一种有用的模式匹配技巧，是在真正工作之前，对主题字符串加以预处理。假设我们打算将文本中所有带引号的字符串，都改为大写，其中引号字符串以双引号（`"`）开始和结束，但也可能包含转义的引号（`"\""`）：


```text
follows a typical string: "This is \"great\"!"
```

处理这种情况的一种方法，便是对文本加以预处理，将有问题的序列，编码为其他序列。例如，我们可以把 `"\""` 编码为 `"\1"`。但是，如果原文中已经包含了一个 `"\1"`，我们就有麻烦了。要进行编码并避免这个问题，一个简单的方法，是将所有 `"\x"` 序列，编码为 `"\ddd"`，其中 `ddd` 是字符 `x` 的十进制表示法：


```lua
function code (s)
    return (string.gsub(s, "\\(.)", function (x)
        return string.format("\\%03d", string.byte(x))
    end))
end
```

现在，编码字符串中的任何序列 `"\ddd"`，都必定来自编码，因为原始字符串中的任何 `"\ddd"`，也已经被编码了。因此，解码就是一件很容易的事：


```lua
function decode (s)
    return (string.gsub(s, "\\(%d%d%d)", function (d)
        return "\\" .. string.char(tonumber(d))
    end))
end
```

现在我们就可以完成任务了。由于编码字符串不再包含任何转义了引号（`"\""`），我们只需使用 `'".-"'`，即可检索到带引号的字符串：


```lua
s = [[follows a typical string: "This is \"greate\"!"]]

s = code(s)
s = string.gsub(s, '".-"', string.upper)
s = decode(s)
print(s)    --> follows a typical string: "THIS IS \"GREATE\"!"
```

我们也可以这样写：

```lua
print(decode(string.gsub(code(s), '".-"', string.upper)))
```

模式匹配函数对 UTF-8 字符串的适用性取决于模式。由于 UTF-8 任何字符的编码，都不会出现在任何其他字符的编码中这一关键特性，因此字面模式的运行不会出现问题。字符类和字符集，character classes and character sets，只适用于 ASCII 字符。例如，`"%s"` 模式会工作于 UTF-8 字符串，但他只会匹配 ASCII 空格，而不会匹配额外的 Unicode 空格，如非断开空格，a non-break space（`U+00A0`）或蒙古语的元音分隔符（`U+180E`）。

明智的模式，judicious patterns，可以为 Unicode 处理，带来一些额外功能。一个很好的例子，便是预定义模式 `utf8.charpattern`，他可以精确匹配一个 UTF-8 字符。`utf8` 库将此模式定义如下：


```lua
utf8.charpattern = [\0-\x7F\xC2-\xF4][\x80-\xBF]*
```

其中的第一部分，是一个匹配 ASCII 字符（范围 `[0, 0x7F]`），或多字节序列初始字节（范围 `[0xC2, 0xF4]`）的类。第二部分会匹配零或多个后续字节（范围 `[0x80，0xBF]`）。


## 练习

练习 10.1：请编写一个函数，他会取一个字符串，和一个分隔符模式，并返回其中包含由分隔符分隔出的、原始字符串中块的表：


```lua
t = split("a whole new world", " ")
-- t = {"a", "whole", "new", "world"}
```

练习 10.2：模式 `"%D"` 和 `"[^%d]"` 是等价的。那么模式 `"[^%d%u]"` 和 `"[%D%U]"` 呢？


练习 10.3：请编写一个函数 `transliterate`。该函数要取一个字符串，并根据作为第二个参数所给到的表，将字符串中的每个字符，都替换为另一个字符。如果表将 `"a"` 映射为 `"b"`，函数应将出现的任何 `"a"`，都替换为 `"b"`；如果表将 `"a"` 映射为 `false`，函数应从结果字符串中，删除出现的 `"a"`。


练习 10.4： 在 [“捕获物”](#捕获物) 小节的结尾，我们定义了一个 `trim` 函数。由于使用了回溯，backtracking，因此对于某些字符串，该函数可能需要花费次方的时间，`O(n^2)`（例如，在我的新机器上，匹配一个 100 KB 的字符串，可能需要 52 秒。）

- 请创建一个会触发函数 `trim` 中，这种次方行为的字符串；

- 请重写该函数，使其始终以线性时间运行。


练习 10.5：请写一个函数，将二进制字符串，格式化为 Lua 中的字面形式，所有字节都使用转义序列 `\x`：


```lua
print(escape("\0\1hello\200"))
    --> \x00\x01\x68\x65\x6C\x6C\x6F\xC8
```

作为改进版，还要使用转义序列 `\z`，来中断长的行。


练习 10.6：请为 UTF-8 字符，重写函数 `transliterate`。


练习 10.7：请编写一个反转 UTF-8 字符串的函数。
