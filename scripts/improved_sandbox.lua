local debug = require "debug"

-- 可被使用的最大内存数（以 KB 计）
local memlimit = 1000

-- 可被执行的最大 “步数”
local steplimit = 1000

local function checkmem ()
    if collectgarbage("count") > memlimit then
        error("脚本使用了太多内存")
    end
end

local count = 0     -- 步数计数器
local function step ()
    checkmem()
    count = count + 1
    if count > steplimit then
        error("脚本使用了过多 CPU")
    end
end

-- 加载文件
local f = assert(loadfile(arg[1], "t", {}))

debug.sethook(step, "", 100)    -- 设置钩子

f()     -- 运行文件
