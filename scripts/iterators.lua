#!/usr/bin/env lua

lines = {
    ["luaH_set"] = 10,
    ["luaH_get"] = 24,
    ["luaH_present"] = 48,
}

a = {}
for n in pairs(lines) do a[#a + 1] = n end
table.sort(a)

for _, n in ipairs(a) do print(n) end

function pairsByKeys (t, f)
    local a = {}

    for n in pairs(t) do        -- 创建出有着全部键的列表
        a[#a + 1] = n
    end

    table.sort(a, f)            -- 对这个列表排序

    local i = 0                 -- 迭代器变量
    return function ()
        i = i + 1
        return a[i], t[a[i]]    -- 返回键，值
    end
end

for name, line in pairsByKeys(lines) do
    print(name, line)
end

function allwords (f)
    for line in io.lines() do
        for word in string.gmatch(line, "%w+") do
            f(word)     -- 调用那个函数
        end
    end
end

io.input("article", "r")


local count = 0
allwords(function (w)
    if w == "hello" then count = count + 1 end
end)
print(count)



function allwords ()
    local line = io.read()          -- 当前行
    local pos = 1                   -- 行中的当前位置

    return function ()              -- 迭代器函数
        while line do               -- 在存在行期间重复
            local w, e = string.match(line, "(%w+)()", pos)
            if w then               -- 发现了一个单词？
                pos = e             -- 下一位置是在这个单词之后
                return w            -- 返回这个单词
            else
                line = io.read()    -- 未找到单词；尝试下一行
                pos = 1             -- 从首个位置重新开始
            end
        end
        return nil                  -- 不再有行：遍历结束
    end
end


local count = 0
for w in allwords() do
    if w == "hello" then count = count + 1 end
end
print(count)



