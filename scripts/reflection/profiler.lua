local Counters = {}
local Names = {}

local function hook ()
    local f = debug.getinfo(2, "f").func
    local count = Counters[f]
    if count == nil then    -- 函数 ‘f’ 首次被调用？
        Counters[f] = 1
        Names[f] = debug.getinfo(2, "Sn")
    else            -- 仅递增计数器
        Counters[f] = count + 1
    end
end

local f = assert(loadfile(arg[1]))
debug.sethook(hook, "c")    -- 打开调用钩子
f()                         -- 运行主程序
debug.sethook()             -- 关闭钩子

function getname (func)
    local n = Names[func]
    if n.what == "C" then
        return n.name
    end

    local lc = string.format("[%s]: %d", n.short_src, n.linedefined)
    if n.what ~= "main" and n.namewhat ~= "" then
        return string.format("%s (%s)", lc, n.name)
    else
        return lc
    end
end

for func, count in pairs(Counters) do
    print (getname(func), count)
end
