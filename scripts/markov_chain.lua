#!/usr/bin/env lua

function prefix (w1, w2)
    return w1 .. " " .. w2
end

statetab = {}

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
