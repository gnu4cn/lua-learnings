local debug = require "debug"

-- 可执行的最大 “步数”
local steplimit = 1000

local count = 0 -- 步骤计数器

-- 已授权函数的集合
local validfunc = {
    [string.upper] = true,
    [string.lower] = true,
    ...     -- 其他已授权函数
}

local function hook (event)
    if event == "call" then
        local info = debug.getinfo(2, "fn")
        if not validfunc[info.func] then
            error("正调用不良函数：" .. (info.name or "?"))
        end
    end

    count = count + 1
    if count > steplimit then
        error("脚本使用了过多 CPU")
    end
end
