#!/usr/bin/env lua
local results = {}
setmetatable(results, {__mode = "v"})   -- 使值成为弱值
function mem_loadstring (s)
    local res = results[s]
    if res == nil then                  -- 结果不存在？
        res = assert(load(s))           -- 计算新的结果
        results[s] = res                -- 保存用于后面的重用
    end
    return res
end
