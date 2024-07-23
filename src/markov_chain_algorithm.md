# 插曲：马科夫链算法

**Interlude: Markov Chain Algorithm**


我们的下一个完整程序，是马科夫链算法的实现，Kernighan 和 Pike，在他们的书《编程实践》（Addison-Wesley，1999 年）中，对该算法进行了描述。

该程序会根据基础文本中的前 `n` 个单词序列后，可能出现的单词，生成伪随机的文本。在这个实现中，我们假设 *n* 为二。


该程序的第一部分，会读取基础文本并建立一个表，对于由两个单词组成的每个前缀，都会给出这个文本中，该前缀后面单词的列表。建立这个表后，程序就会利用他，来生成一个，其中跟随了前两个单词的单词，有着与基本文本中的相同概率。作为结果，我们得到的文本会非常随机，但又不完全随机。例如，当应用到这本书（**译注**：指英文原文）时，程序的输出结果是这样的：“*Constructors can also traverse a table constructor, then the parentheses in the following line does the whole file in a field n to store the contents of each function, but to show its only argument. If you want to find the maximum element in an array can return both the maximum value and continues showing the prompt and running the code. The following words are reserved and cannot be used to convert between degrees and radians.*”


> **译注**：关于马科夫链算法与 GPT 的区别，请参阅：[GPT vs. 马科夫链](https://chat.openai.com/share/ac4230fa-0f19-4607-83c2-9dc5f1c6a6dc)，内容由 [ChatGPT 3.5](https://chat.openai.com/) 生成。

为将两单词的前缀，用作表中的键，我们将通过把两个单词，中间用一个空格连接起来表示这种两单词的前缀：


```lua
function prefix (w1, w2)
    return w1 .. " " .. w2
end
```

我们会使用字符串 `NOWORD`（换行符），来初始化这些前缀词，以及标记文本的结束。例如，对于文本 `"the more we try the more we do"`，接续单词表，the table of following words，将会如下所示：


```lua
{ ["\n \n"] = {"the"},
  ["\n the"] = {"more"},
  ["the more"] = {"we", "we"},
  ["more we"] = {"try", "do"},
  ["we try"] = {"the"},
  ["try the"] = ["more"]
  ["we do"] = {"\n"}
}
```

该程序将其表，保存在变量 `statetab` 中。要在这个表的某个列表中，插入一个新词，我们会使用以下函数：


```lua
function insert (prefix, value)
    local list = statetab[prefix]
    if list == nil then
        statetab[prefix] = {value}
    else
        list[#list + 1] = value
    end
end
```

他首先检查了，该前缀是否已经有一个列表；如果没有，就用那个新值创建出一个新的列表。否则，他会将那个新值，插入于现有列表的末尾。

为了建立起 `statetab` 这个表，我们会保留分别有着最后读取的两个单词的两个变量 `w1` 和 `w2`。我们会用到 [迭代器和闭包](iterators.md#迭代器与闭包) 小节中，那个迭代器 `allwords` 读取单词，但我们调整了 “单词” 的定义，将逗号和句号等可选标点符号，也包括在内（参见下 [图 19.1，“马尔可夫程序的辅助定义”](#f-19.1)）。每读取一个新词，我们就将其添加到与 `w1-w2` 关联的列表中，然后更新 `w1` 和 `w2`。


建立了这个表后，程序会开始生成包含 `MAXGEN` 个单词的文本。首先，程序会重新初始化变量 `w1` 和 `w2`。随后，对于每个前缀，程序从有效的下一单词列表，随机选择一个下一单词，打印出该单词，并更新 `w1` 和 `w2`。下面的图 19.1，“马尔可夫程序的辅助定义” 和 [图 19.2，“马尔可夫程序”](#f-19.2) 给出了完整程序。


<a name="f-19.1">**图 19.1，马科夫程序的一些辅助定义**</a>

```lua
function prefix (w1, w2)
    return w1 .. " " .. w2
end

function insert (prefix, value)
    local list = statetab[prefix]
    if list == nil then
        statetab[prefix] = {value}
    else
        list[#list + 1] = value
    end
end


function allwords ()
    local line = io.read()      -- 当前行
    local pos = 1               -- 行中的当前位置
    return function ()          -- 迭代器函数
        while line do           -- 在有行时重复
            local w, e = string.match(line, "(%w+[,;.:]?)()", pos)
            if w then                       -- 找了个单词？
                pos = e                     -- 更新下一位置
                return w                    -- 返回该单词
            else
                line = io.read()        -- 未找到单词；尝试下一行
                pos = 1
            end
        end
        return nil
    end
end

local statetab = {}
```

<a name="f-19.2">**图 19.2，马科夫程序**</a>

```lua
local MAXGEN = 200
local NOWORD = "\n"

-- 构建出表
local w1, w2 = NOWORD, NOWORD
for nextword in allwords() do
    insert(prefix(w1, w2), nextword)
    w1 = w2; w2 = nextword
end
insert(prefix(w1, w2), NOWORD)

-- 生成文本
w1 = NOWORD; w2 = NOWORD        -- 重新初始化
for i = 1, MAXGEN do
    local list = statetab[prefix(w1, w2)]
    -- 从清单选择一个随机项目
    local r = math.random(#list)
    local nextword = list[r]
    if nextword == NOWORD then return end
    io.write(nextword, " ")
    w1 = w2; w2 = nextword
end
```


## 练习


练习 19.1：将马尔可夫链算法推广扩大，使其能够在选择下一个单词时，使用的任意大小的前导单词序列。
