# 插曲： 八皇后之谜

**Interlude: The Eight-Queen Puzzle**


在本章中，我们将构造一个小插曲，介绍一个简单但完整的 Lua 程序，他可以解决 *八皇后谜题*：其目标是在棋盘上摆放八个皇后，使每个皇后都无法攻击另一个皇后。

这里的代码，没有用到任何 Lua 特有的东西；我们应该可以将代码，翻译成其他数种语言，只需做一些表面上的改动即可。我们的想法是介绍 Lua 的总体风貌，尤其是 Lua 语法的外观，而不涉及细节。我们将在后续章节中，介绍所有缺失的细节。


解决八皇后谜题的第一步，就是要注意，任何有效的解法，均必须在每一行中，都恰好有一个皇后。因此，我们可以用由八个数字组成的简单数组，来表示可能的解法，每行一个数字，每个数字表示该行的皇后在哪一列。例如，数组 `{3, 7, 2, 1, 8, 6, 5, 4}` 表示皇后在 `(1,3)`、`(2,7)`、`(3,2)`、`(4,1)`、`(5,8)`、`(6,6)`、`(7,5)` 和 `(8,4)` 格。(顺便说一下，这不是一个有效的解法；例如，位于 `(3,2）`位置的皇后，可以攻击位于 `(4,1)`位置的皇后）。请注意，任何有效的解法，都必须是整数 `1` 到 `8` 的排列，因为有效的解法，还必须在每一列中都有一个皇后。


完整程序见 [图 2.1 的 "八皇后程序"。](#f-2.1)


<a name="f-2.1">**图 2.1，八皇后程序**</a>

```lua
N = 8   -- board size

-- check whether position (n,c) is free from attacks
function isplaceok (a, n, c)
    for i = 1, n - 1 do     -- for each queen already placed
        if (a[i] == c)                  -- same column?
            or (a[i] - i == c - n)      -- same diagonal?
            or (a[i] + i == c + n)      -- same diagonal?
            then return false       -- place can be attacked
        end
    end

    return true     -- no attacks; place is OK
end

-- print a board
function printsolution (a)
    for i = 1, N do         -- for each row
        for j = 1, N do     -- and for each column
            -- write "X" or "-" plus a space
            io.write(a[i] == j and "X" or "-", " ")
        end
        io.write("\n")
    end
    io.write("\n")
end

-- add to board 'a' all queens from 'n' to 'N'
function addqueen (a, n)
    if n > N then       -- all queens have been placed?
        printsolution(a)
    else    -- try to place n-th queen
        for c = 1, N do
            if isplaceok(a, n, c) then
                a[n] = c    -- place n-th queen at column 'c'
                addqueen(a, n + 1)
            end
        end
    end
end

-- run the program
addqueen({}, 1)
```

> **注意**：关于这个 “八皇后问题”，请参阅 [维基百科：八皇后问题](https://zh.wikipedia.org/zh-cn/%E5%85%AB%E7%9A%87%E5%90%8E%E9%97%AE%E9%A2%98)。


第一个函数是 `isplaceok`，他会检查棋盘上给定的位置，是否不受先前放置的皇后攻击。更具体地说，他会检查将第 `n` 个皇后放入 `c` 列，是否会与数组 `a` 中，已放置的 `n-1` 个皇后发生冲突。请记住，根据表示法，两个皇后不能位于同一行，因此 `isplaceok` 会检查新位置的同一列，或同一对角线上是否没有皇后。


接下来是 `printsolution` 函数，他可以打印棋盘。他只需遍历整个棋盘，在有皇后的位置打印 `X`，在其他位置打印 `-`，没有任何花哨图形。(请注意，他使用了 `and-or` 习惯用法，来选择在每个位置，要打印的字符）。各个结果将如下所示：


```console
- - - - - - - X
- - - X - - - -
X - - - - - - -
- - X - - - - -
- - - - - X - -
- X - - - - - -
- - - - - - X -
- - - - X - - -
```


最后一个函数 `addqueen`，是程序的核心。他试图将所有大于或等于 `n` 的皇后，放入棋盘中。他使用了回溯法，backtracking，来搜索有效的解。首先，他会检查解是否完整，如果是，则打印该解。否则，他将在所有列中，循环寻找第 `n` 个皇后；对于没有攻击的每一列，程序都会将皇后放置在那里，并递归地尝试放置，后面的皇后。


最后，程序主体只需在空解决方案（`{}`）上，调用 `addqueen` 即可。


## 练习

练习 2.1： 修改八皇后程序，使其在打印第一个解后停止；


练习 2.2： 八皇后问题的另一种实现方法，是生成 `1` 到 `8` 的所有可能排列，并检查每种排列是否有效。请使用这种方法修改程序。新程序的性能与旧程序相比如何？(提示：要将排列总数，与原程序调用函数 `isplaceok` 的次数加以比较）。
