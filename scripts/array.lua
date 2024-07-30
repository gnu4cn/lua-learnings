#!/usr/bin/env lua

local a = {}        -- 新建数组
for i = 1, 1000 do
    a[i] = 0
end

print(#a, a[#a], a[#a + 5])


-- 创建一个索引为 -5 到 5 的数组
a = {}
for i = -5, 5 do
    a[i] = 0
end

squares = {1, 4, 9, 16, 25, 36, 49, 64, 81}

