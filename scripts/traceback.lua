function traceback ()
    for level = 1, math.huge do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        if info.what == "C" then    -- 是个 C 函数？
            print(string.format("%d\tC 函数", level))
        else    -- 是个 Lua 函数
            print(string.format("%d\t[%s]:%d", level, info.short_src, info.currentline))
        end
    end
end
