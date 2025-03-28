local debug = require "debug"

-- 可被执行的最大 “步数”
local steplimit = 1000
local count = 0     -- 步数计数器

local function step ()
    count = count + 1
    if count > steplimit then
        error("脚本使用了过多 CPU")
    end
end

-- 加载文件
local f = assert(loadfile(arg[1], "t", {}))

debug.sethook(step, "", 100)    -- 设置钩子
f()     -- 运行文件
debug.sethook()                 -- 关闭钩子
