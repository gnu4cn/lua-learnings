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

local function hook (ev)
    print("Enter hook")
    if ev == "call" then
        local info = debug.getinfo(2, "fn")
        local fn = validfunc[info.name]
        print(fn)

        if not validfunc[info.func] then
            error("正调用不良函数：" .. (info.name or "?"))
        end
    end

    count = count + 1
    if count > steplimit then
        error("脚本使用了过多 CPU")
    end
end

-- 加载代码块
local f = assert(loadfile(arg[1], "t", {}))
debug.sethook(hook, "call", 100)    -- 设置钩子
f()     -- 运行代码块
debug.sethook()
