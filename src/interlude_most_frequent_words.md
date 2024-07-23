# 插曲：高频词

**Interlude: Most Frequent Words**

在本插曲中，我们将开发一个，读取文本并打印出文本中，出现频率最高单词的程序。与上一个插曲一样，本程序非常简单，但使用了一些更高级的功能，比如迭代器，以及匿名函数等。

咱们程序的主要数据结构，是个将文本中找到的每个单词，映射到其频率计数器的表。在此数据结构下，程序有三项主要任务：


- 读取文本，就每个单词出现的次数进行计算；

- 按词频降序，对单词表加以排序；

- 打印出已排序列表中，前 *n* 个条目。


要读取文本，我们可以遍历文本的所有行，并遍历每一行的所有单词。每读取到一个单词，我们就递增相应的计数器：


```lua
local counter = {}
for l in io.lines() do
    for word in string.gmatch(l, "%w+") do
        counter[word] = (counter[word] or 0) + 1
    end
end
```

这里，我们使用 `"%w+"` 这个模式，来描述一个 “单词”，即一个或多个字母数字字符。


下一步是对这个单词列表加以排序。然而，细心的读者可能已经注意到，我们并没有要排序的单词列表！尽管如此，使用 `counter` 表中，作为键出现的单词，创建一个单词列表，还是很容易的：


```lua
local words = {}    -- 在文本中找到的全部单词列表

for w in pairs(counter) do
    words[#words + 1] = w
end
```

有了这个列表后，我们就可以使用 `table.sort`，对其进行排序了：


```lua
table.sort(words, function(w1, w2)
    return counter[w1] > counter[w2]
    or (counter[w1] == counter[w2] and w1 < w2)
end)
```

请记住，在结果中，`w1` 若要必须排在 `w2` 之前，排序函数就必须返回 `true`。有着较大计数器的单词，会排在前面；计数器相等的单词，则会按字母顺序排列。


下 [图 11.1，“词频程序”](#f-11.1)，给出了完整程序。


<a name="f-11.1">**图 11.1，词频程序**</a>


```lua
local f = assert(io.open("article", "r"))


local counter = {}
for l in f:lines() do
    for word in string.gmatch(l, "%w+") do
        counter[word] = (counter[word] or 0) + 1
    end
end

f:close()

local words = {}    -- 在文本中找到的全部单词列表

for w in pairs(counter) do
    words[#words + 1] = w
end

table.sort(words, function(w1, w2)
    return counter[w1] > counter[w2]
    or (counter[w1] == counter[w2] and w1 < w2)
end)

-- 要打印的单词数目
local n = math.min(tonumber(arg[1]) or math.huge, #words)

for i = 1, n do
    io.write(words[i], "\t", counter[words[i]], "\n")
end
```

最后一个循环打印出结果，即前 `n` 个单词，及其各自的计数器。程序假定其第一个参数，是要打印的单词数；默认情况下，如果没有给定参数，程序会打印出所有单词。

```console
~ ./word_freq.lua 20
the     47
in      18
to      17
and     16
a       14
of      14
US      13
Israel  11
for     11
by      10
that    8
Gaza    7
cable   7
from    7
s       7
Arab    6
The     6
growing 6
it      6
officials       6
```

## 练习

练习 11.1：当我们将这个词频程序应用到某个文本时，最常见的词，通常是冠词和介词等不感兴趣的小单词。请修改这个程序，使其忽略少于四个字母的单词。

练习 11.2：重复前面的练习，但程序应从某个文本文件中，读取要忽略的单词列表，而不是以长度作为忽略单词的标准。
