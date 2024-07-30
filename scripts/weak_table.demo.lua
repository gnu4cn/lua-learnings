#!/usr/bin/env lua
a = {}
a[1] = "value"
mt = {__mode = "k"}
setmetatable(a, mt)     -- 现在 'a' 就有了弱键
key = {}                -- 创建出首个键
a[key] = 1
key = {}                -- 创建出第二个键
a[key] = 2
collectgarbage()        -- 强制进行一次垃圾回收周期
for k, v in pairs(a) do print(v) end
    --> 2
