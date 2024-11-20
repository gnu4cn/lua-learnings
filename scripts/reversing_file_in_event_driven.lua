local lib = require "async-lib"

local t = {}
local inp = io.input()
local out = io.output()
local i


-- 写-行 处理器
local function putline ()
    i = i - 1
    if i == 0 then
        lib.stop()      -- 没有更多行了？
    else
        lib.writeline(out, t[i] .. "\n", putline)
    end
end

-- 读-行 处理器
local function getline (line)
    if line then                        -- 非 EOF？
        t[#t + 1] = line                -- 保存行
        lib.readline(inp, getline)      -- 读取下一行
    else                                -- 文件结束处
        i = #t + 1                      -- 准备写循环
        putline()                       -- 进入写循环
    end
end

lib.readline(inp, getline)              -- 请求读取首行
lib.runloop()                           -- 运行主循环
