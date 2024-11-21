local lib = require "async-lib"

function run (code)
    local co = coroutine.wrap(function ()
        code()
        lib.stop()      -- 在完成后结束事件循环
    end)

    co()                -- 启动协程
    lib.runloop()       -- 启动事件循环
end


function putline (stream, line)
    local co = coroutine.running()      -- 调用协程
    local callback = (function () coroutine.resume(co) end)
    lib.writeline(stream, line, callback)
    coroutine.yield()
end

function getline (stream, line)
    local co = coroutine.running()        -- 调用协程
    local callback = (function (l) coroutine.resume(co, l) end)
    lib.readline(stream, callback)
    local line = coroutine.yield()
    return line
end

run(function ()
    local t = {}
    local inp = io.input()
    local out = io.output()

    while true do
        local line = getline(inp)
        if not line then break end
        t[#t + 1] = line
    end

    for i = #t, 1, -1 do
        putline(out, t[i] .. "\n")
    end
end)
