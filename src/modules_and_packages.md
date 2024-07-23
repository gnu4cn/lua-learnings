# 模组与包

通常，Lua 不会设置策略。相反，Lua 提供了功能强大的机制，让开发人员小组，可以实施最适合他们的策略。然而，这种方法并不能很好地适用于。模组系统的主要目标之一，是允许不同小组共用代码。缺乏通用策略，会阻碍这种共用。

从 5.1 版开始，Lua 已为和包（包是模组的集合），定义了一套策略。这些策略，并不要求语言提供任何额外设施；程序员可以使用我们到目前为止已见到的技巧，来实现他们。程序员可以自由使用不同策略。当然，其他一些实现方式，可能会导致程序无法使用外来模组，以及外来程序无法使用（咱们自己的）模组。


从用户角度来看，所谓模组，就是一些可以通过 `require` 函数加载，而创建出并返回表的代码（可以是 Lua 语言的，也可以是 C 语言的）。模组所导出的全部内容，如函数和常量，都在这个返回的表中定义，该表的运作方式，就如同某种命名空间。


例如，全部标准库，都属于模组。我们可以这样使用数学库：


```lua
local m = require "math"
print(m.sin(3.14))          --> 0.0015926529164868
```

不过，独立的解释器，使用与下面相同的代码，预加载了全部的标准库：

```lua
math = require "math"
string = require "string"
-- ...
```

这种预加载，就允许了我们再费心导入 `math` 模组下，写出通常的 `math.sin` 写法。


使用表来实现的一个显而易见的好处是，我们可以像操作其他表一样，操作模组，并利用 Lua 的全部能力，来创建出一些额外设施。在大多数语言中，模组都不是头等值（也就是说，他们不能存储在变量中，也不能作为参数，传递给函数等）；这些就会为想要提供模组，所需的每种额外设施，都需要一种特殊机制。在 Lua 中，我们可以无代价地获得这些额外设施。


例如，用户可以通过多种方式，调用模组中的函数。通常的方法是


```lua
local mod = require "mod"
mod.foo()
```


用户可以为该模组，设置任何的本地名字：


```lua
local m = require "mod"
m.foo()
```

他还可以为各个函数，提供替代的名字：


```lua
local m = require "mod"
local f = m.foo
f()
```

他还可以只导入某个特定的函数：

```lua
local f = require "mod".foo         -- (require("mod")).foo
f()
```

这些设施的优点，是无需 Lua 提供特殊支持。他们使用的，均是 Lua 语言已提供的特性。


## 函数 `require`


尽管 `require` 在 Lua 的模组实现中，扮演着核心角色，但他只是一个普通函数，并无特殊权限。要加载某个模组，我们只需以模组名称一个参数，调用 `require` 这个函数。请记住，当函数的单一参数，是个字面字符串时，括号就是可选的，在 `require` 的常规用法中，括号因此就通常省略了。不过，下面的用法，也都是正确的：


```lua
local m = require("math")

local modname = 'math'
local m = require(modname)
```

函数 `require` 尽量减少了对是什么的假设。对他来说，模组就是定义了，一些诸如函数或包含函数的表，的代码。通常情况下，代码会返回一个包含着模组函数的表。然而，由于这一操作是由模组代码，而非 `require` 完成的，因此某些模组，就可能会选择返回一些别的值，甚至产生副作用（例如，创建出一些全局变量）。


`require` 的第一步，是在 `package.loaded` 表中，检查该是否已被加载。如果是，`require` 会返回该模组相应的值。因此，一旦某个模组加载完毕，其他导入该同一模组的调用，就只需返回这同一值，而无需再次运行任何代码。


在该模组尚未加载时，`require` 就会搜索带有该模组名字的 Lua 文件。(此搜索由 `package.path` 变量引导，稍后咱们将讨论到）。如果找到了，就用 `loadfile` 加载他。结果便是我们称之为 *加载器，loader* 的函数。(加载器是个，在其被调用时，加载的函数。）


在找不到有着该模组名字的 Lua 文件时，`require` 就会搜索有着该名字的 C 库 <sup>注 1</sup> 。（在这种情况下，搜索会由变量 `package.cpath` 引导。）如果找到了 C 库，他就会使用底层函数 `package.loadlib` 加载该库，寻找名为 <code>luaopen<i>_modname</i></code> 的函数。在这种情况下，加载器就是 `loadlib` 的结果，即用表示为某个 Lua 函数的 C 函数 <code>luaopen<i>_modname</i></code>。

> **注 1**：在名为 [C 模组](calling_c_from_lua.md#C-模组) 的小节，咱们将讨论怎样编写 C 库。

无论模组是在 Lua 文件，还是 C 库中找到的，`require` 现在都有了该模组的加载器。为最终加载该模组，`require` 会以两个参数，调用该加载器：模组名称，与获取到加载器的那个文件的名称。（多数模组，都只会忽略这两个参数。）如果加载器返回了任何值，`require` 就会将该值返回，并将其存储在 `package.loaded` 表中，以便在今后这个同一模组的调用中，返回同样的值。如果加载器没有返回值，并且表项 `package.loaded[@rep{modname}]` 仍然为空，`require` 则会如同该模组返回 `true` 那样行事。如果没有这一修正，后续的 `require` 调用，则将再次运行该模组。

> **译注**：这里原文为：if the loader returns no value, and the table entry `package.loaded[@rep{modname}]` is still empty, `require` behaves as if the module returned `true`. Without this correction, a subsequent call to `require` would run the module again.

对 `require` 的一种常见抱怨，是他不能将参数传递给正在加载的模组。例如，数学模组，就可能有个在度和弧度之间，进行选择的选项：


```lua
-- 烂代码
local math = require("math", "degree")
```

这里的问题在于，`require` 的主要目标之一，是避免多次加载某个模组。一旦某个模组已被加载，他就将会被程序中，会再度导入他的部分重用。如果同一模组需要以不同参数导入，就会产生冲突。如果咱们真的希望咱们的模组有些参数，那么最好创建一个显式函数来设置这些模组，就像下面这样：


```lua
local mod = require "mod"
mod.init(0, 0)
```

在该初始化函数返回模组本身时，我们可以这样编写这段代码：


```lua
local mod  = require "mod".init(0, 0)
```

无论如何，都要记住模组本身，只会被加载一次；冲突初始化的解决，取决于模组本身。


### 重命名模组

**Renaming a module**


通常，我们会以模组的原名，使用该模组，但有时我们必须重新命名某个模组，以避免名字冲突。一种典型的情况是，我们需要加载同一模组的不同版本，例如用于测试。Lua 模组在内部并没有固定的名字，因此通常只需重命名 `.lua` 文件即可。但是，我们却无法编辑某个 C 库的目标代码，来修改其 `luaopen_*` 函数的名字。为了实现此类重命名，`require` 用到了一个小技巧：如果模组名字中包含连字符（`-`），`require` 在创建 `luaopen_*` 函数名称时，会从名字中删除连字符后的后缀。例如，如果模组名为 `mod-v3.4`，`require` 就会预期该模组的开放函数，its open function，被命名为 `luaopen_mod`，而不是 `luaopen_mod-v3.4`（这不会是个有效的 C 语言名字）。因此，在需要使用两个名字均为 `mod` 的模组（或同一模组的两个版本）时，我们可以将其中一个，重命名为 `mod-v1`。当我们调用 `m1 = require "mod-v1"` 时，`require` 会找到重命名后的文件 `mod-v1`，并在该文件中，找到原名为 `luaopen_mod` 的函数。


### 路径的检索

**Path searching**


当 `require` 检索某个 Lua 文件时，引导 `require` 的路径，与那些典型路径有些不同。所谓典型路径，a typical path，是个要在其中，检索给定文件的目录列表。然而，ISO C（Lua 所运行的抽象平台，the abstract platform where Lua runs），却并没有目录的概念。因此，`require` 用到的路径，是个 *模板，templates* 的列表，其中的每个模板，都指定了将模组名名字（`require` 的参数），转换为文件名的替代方法。更具体地说，路径中的每个模板，都是一个包含一些可选问号的文件名。对于每种模板，`require` 都会将模组名字，替换为各个问号，并检查是否存在与替换结果的名字相同的文件；如果没有，则转到下一模板。路径中的模板之间，是用分号隔开的，在大多数操作系统中，分号都很少用于文件名。例如，请看下面这个路径：


```lua
?;?.lua?c:\windows\?;/usr/local/lua/?/?.lua
```


在这个路径下，`require "sql"` 这个调用，将尝试打开下面这些 Lua 文件：


```lua
sql
sql.lua
c:\windows\sql
/usr/local/lua/sql/sql.lua
```

函数 `require` 仅假定了分号（作为组件的分隔符）和问号；其他一切，包括目录分隔符与文件扩展名，都由路径本身定义。


`require` 用于搜索 Lua 文件的路径，始终是变量 `package.path` 的当前值。当模组 `package` 被初始化时，他会以环境变量 `LUA_PATH_5_4` 的值，设置这个变量；如果这个环境变量未定义，Lua 就会尝试使用环境变量 `LUA_PATH`。如果这两个变量都未定义，Lua 将使用其编译时所定义的默认路径。<sup>注 2</sup>在使用某个环境变量的值时，Lua 会用该默认路径，代替任何子串 `";;"`。例如，在我们将 `LUA_PATH_5_4` 设置为 `"mydir/?.lua;;"` 时，最终路径将是其后带有默认路径的模板 `"mydir/?.lua"`。

> **注 2**：自 Lua 5.2 起，独立解释器，就接受命令行选项 `-E`，来阻止使用这些环境变量，而强制使用默认值。

用于搜索 C 库的路径，与此完全相同，但其值来自变量 `package.cpath`，而不是 `package.path`。同样，该变量会从环境变量 `LUA_CPATH_5_4` 或 `LUA_CPATH`，获取其初始值。POSIX 中的该路径典型值，是下面这样的：


```lua
./?.so;/usr/local/lib/lua/5.4/?.so
```

请注意，该路径定义了文件扩展名。上面的示例，对全部所有模板都使用了 `.so` 文件扩展名；在 Windows 系统中，典型路径则会与此相似：


```lua
.\?.dll;C:/Program Files\Lua502\dll\?.dll
```

函数 `package.searchpath`，会把全部这些规则，编码用于库的检索。他会取一个模组名字，以及一个路径，并按照这里所描述的规则，查找某个文件。他要么返回存在的第一个文件的名字，要么返回 `nil`，以及一条说明他尝试未成功打开的所有文件的消息，如下面这个示例所示：


```lua
> path = ".\\?.dll;C:\\Program Files\\Lua502\\dll\\?.dll"
> print(package.searchpath("X", path))
nil     no file '.\X.dll'
        no file 'C:\Program Files\Lua502\dll\X.dll'
```

作为一个有趣的练习，在下 [图 17.1，“一个自制的 `package.searchpath`”](#fig-17.1) 中，我们实现了一个类似 `package.searchpath` 的函数。


<a name="fig-17.1"></a>图 17.1，一个自制的 `package.searchpath`


```lua
function search (modname, path)
    modname = string.gsub(modname, "%.", "/")
    local msg = {}
    for c in string.gmatch(path, "[^;]+") do
        local fname = string.gsub(c, "?", modname)
        local f = io.open(fname)
        if f then
            f:close()
            return fname
        else
            msg[#msg + 1] = string.format("\n\tno file '%s'", fname)
        end
    end
    return nil, table.concat(msg)       -- 未找到
end
```

第一步是用目录分隔符（本例中假定为斜线），代替所有的点。（如同稍后我们将看到的，点在模组名字中，有特殊含义。）。然后，该函数循环遍历了路径的所有组件，其中每个组件，都是非分号字符的最大展开形式。对于每个组件，该函数都会用模组名字取代问号，来得到最终的文件名，然后检查是否存在这样一个文件。如果有，该函数将关闭这个文件，并返回其名字。否则，他会为一条可能的错误信息，存储这个失败的文件名。(请注意为了避免创建出无用的长字符串，其中字符串缓冲的运用。）如果没有找到文件，则其会返回 `nil` 和最终的错误信息。



### 检索器

**Searchers**


实际上，`require` 要比我们曾描述的，要复杂一些。搜寻 Lua 文件和 C 库，只是 *检索器，searchers* 这一更普遍概念的两个实例。所谓检索器，只是个取模组名字，并要么返回该模组的加载器，要么在找不到时，返回 `nil` 的函数。


数组 `package.searchers` 列出了 `require` 用到的那些检索器。在查找某个模组时，`require` 会调用这个列表中的各个检索器，传递该模组的名字，直到其中某个检索器找到该模组的加载器。如果列表结束时没有肯定的回应，`require` 就会抛出一个错误。


使用列表来驱动模组的检索，实现了 `require` 的极大灵活性。例如，如果我们打算把模组，压缩存储在 zip 文件中，就只需为此提供一个适当的检索器函数，并将其添加到列表中。在其默认配置中，我们前面介绍过的 Lua 文件检索器，以及 C 语言库检索器，就分别是该列表中的第二和第三个元素。在他们之前，是预加载检索器，the preload searcher。


*预加载* 检索器，实现了定义任意函数，来加载某个模组。他用到了一个将模组名称，映射到加载器函数，名为 `package.preload` 的表。在检索某个模组的名称时，该检索器只需在这个表中，查找所给的名称。如果在其中找到一个函数，就会将该函数作为模组加载器返回。否则，他将返回 `nil`。该检索器提供了一种处理一些非常规情况的通用方法。例如，静态链接到 Lua 的某个 C 库，便可以将其 `luaopen_` 函数，注册到 `preload` 表中，从而就只有在用户导入该模组时，才会调用该函数。以这种方式，在该模组不会被用到时，程序就不会浪费资源去打开他。


`package.searchers` 的默认内容，包括了只与子模组相关的第四个函数。我们将在 [“子模组与包”](#子模组与包) 小节中讨论这个函数。


## Lua 中编写模组的基本方法

**The Basic Approch for Writing Modules in Lua**

在 Lua 中创建模组的最简单方法，其实很简单：我们创建出一个表，将所有咱们打算导出的函数放在该表中，然后返回这个表。下图 17.2，“用于复数的简单模组”，展示了这种方法。


```lua
local M = {}        -- 模组


-- 创建出一个新的复数
local function new (r, i)
    return {r = r, i = i}
end

M.new = new

-- 常量 'i'
M.i = new(0, 1)

function M.add (c1, c2)
    return new(c1.r + c2.r, c1.i + c2.i)
end

function M.sub (c1, c2)
    return new(c1.r - c2.r, c1.i - c2.i)
end


function M.mul (c1, c2)
    return new(c1.r*c2.r - c1.i*c2.i, c1.r*c2.i + c1.i*c2.r)
end

local function inv (c)
    local n = c.r^2 + c.i^2
    return new(c.r/n, -c.i/n)
end

function M.div (c1, c2)
    return M.mul(c1, inv(c2))
end

function M.tostring (c)
    return string.format("(%g,%g)", c.r, c.i)
end

return M
```

请注意我们是如何将 `new` 和 `inv` 定义为私有函数的，只需将他们声明为针对该代码块的本地函数。


有的人会不喜欢最后的那个返回语句。消除他的一种方法，是将这个模组表，直接赋值给 `package.loaded`：


```lua
local M = {}
package.loaded[...] = M
    -- 随后的内容与之前一样，只是不带那个返回语句
```

请记住，`require` 会传入模组名字作为第一个参数，调用加载器。因此，那个表索引中的可变参数表达式 `...`，就会产生出该名称。在这个赋值后，我们就不需要在模组结束时，返回 `M` 了：在某个模组没有返回值时，`require` 将返回 `package.loaded[modname]` 的当前值（在其不是 `nil` 时）。总之，我（作者）觉得，写上那个最后的返回语句，会更清楚。如果我们忘记了这一点，任何对该模组的简单测试，都会发现这种错误。


编写模组的另一种方法，是将所有函数，都定义为本地函数，而在最后，构建出返回表，如下图 17.3，“带导出列表的模组”。


```lua
local function new (r, i) return {r=r, i=i} end

-- 定义常量 'i'
local i = complex.new(0, 1)

    -- 其他函数遵循了同一模式

return {
    new         = new,
    i           = i,
    add         = add,
    sub         = sub,
    mul         = mul,
    div         = div,
    tostring    = tostring,
}
```

这种方法有些什么优点？我们不需要在每个名字前，都加上 `M.`，或类似的前缀；这种方法有个明确的导出列表；且我们在模组内，针对那些导出函数和内部函数，定义和使用他们的方式相同。有些什么缺点呢？那个导出列表位于模组的末尾，而不是开头，而作为快速文档，位于开头会更有用；且那个导出列表有些多余，因为我们必须把每个名称写两次。（后一个缺点，可能会成为优点，因为他允许函数在模组内外，使用不同的名称，但我（作者）认为程序员会很少这样做。）


总之，请记住，无论我们如何定义模组，用户都应能以标准的方式使用他：


```lua
local cpx = require "complex"
print(cpx.tostring(cpx.add(cpx.new(3, 4), cpx.i)))
    --> (3,5)
```

稍后，我们将了解如何使用一些高级的 Lua 特性，比如元表和环境，来编写模组。不过，除了一种检测因失误而创建出全局变量的好技巧外，在我自己的模组中，我都只用到这种基本方法。


## 子模组与包

**Submodules and Packages**

Lua 允许使用点来分隔模组名称的层级，实现模组名字的层次化。例如，名为 `mod.sub` 的模组，就是个 `mod` 的子模组。而 *包，package*，则是棵完整的模组树；包是 Lua 中的分发单位，the unit of distribution in Lua。

在导入某个名为 `mod.sub` 的模组时，函数 `require` 会将原始模组名字 `"mod.sub"` 用作键，首先查询 `package.loaded` 表，然后查询 `package.preload` 表。在这里，其中的点只是个字符，就像模组名中的其他字符一样。

不过，在搜索定义出该子模组的文件时，`require` 会将点，翻译成另一个字符，通常是系统的目录分隔符（如 POSIX 的斜线（`/`），或 Windows 的反斜线（`\`））。翻译后，`require` 会像搜索其他名字一样，搜索得到的名字。例如，假设斜线是目录分隔符，同时路径如下：


```lua
./?.lua;/usr/local/lua/?.lua;/usr/local/lua/?/init.lua
```

`require "a.b"` 这个调用，将会尝试打开下面这些文件：


```lua
./a/b.lua
/usr/local/lua/a/b.lua
/usr/local/lua/a/b/init.lua
```

这种行为实现了，包的所有模组都位于单个目录中。例如，如果软件包中有 `p`、`p.a` 和 `p.b` 三个模组，那么他们各自的文件，就可以是 `p/init.lua`、`p/a.lua` 和 `p/b.lua`，而 `p` 目录则位于某个适当的目录中。

Lua 使用的目录分隔符，是在编译时配置的，可以是任何字符串（请记住，Lua 对目录一无所知）。例如，那些没有层次化目录的系统，可以使用下划线作为“目录分隔符”，这样，`require "a.b"`，将检索文件 `a_b.lua`。


C 语言中的名字，不能包含点，因此子模组 `a.b` 的 C 库，就不能导出函数 `luaopen_a.b`。这种情况下，`require` 会把点，转换为另一个字符，即下划线。因此，名为 `a.b` 的 C 库，应将其初始化函数命名为 `luaopen_a_b`。

作为一项额外设施，`require` 还有另外一个，用于加载 C 语言子模组的检索器。当他找不到子模组的 Lua 文件，或 C 文件时，最后一个检索器，会再次搜索 C 的路径，但这次是检索包的名字。例如，如果程序需要某个子模组 `a.b.c`，那么这个检索器就会查找 `a`。如果他找到了这个名字的 C 库，那么 `require` 就会在这个库中，查找某个合适的打开函数，例如这个例中的 `luaopen_a_b_c`。这一特性，允许（包）发布，将多个子模组（其中每个都有自己的打开函数），整合到一个 C 库中。

从 Lua 的角度来看，同一包中的子模组之间，没有明确的关系。导入某个模组，并不会自动加载他的任何子模组；同样，导入某个子模组，也不会自动加载他的父模组。当然，包的实现者，可以根据自己的需要，创建这些链接。例如，某个特定的模组，可以经由显式地导入其一个或所有子模组，而启动。


## 练习

练习 17.1：请将双端队列的实现（[图 14.2 “双端队列”](data_structure.md#队列和双端队列)），改写为一个适当的模块。


练习 17.2：请将几何区域系统的实现（[“浅尝函数式编程”](closures.md#浅尝函数式编程) 小节），重写为一个适当的模块。


练习 17.3：如果路径中有一些固定的组件（即不带问号的组件），那么在检索库时，会发生什么情况？这种行为有用吗？


练习 17.4：请编写一个同时搜索 Lua 文件和 C 语言库的检索器。例如，该检索器用到的路径，可以是这样的：


```lua
./?.lua;./?.so;/usr/lib/lua5.3/?.so;/usr/share/lua5.3/?.lua
```

（提示：要使用 `package.searchpath` 找到某个合适的文件，然后首先以 `loadfile`，然后再以 `package.loadlib`，分别尝试加载这个文件。）
