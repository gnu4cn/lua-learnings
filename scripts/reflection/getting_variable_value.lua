function getvarvalue (name, level, isenv)
    local value
    local found = false
    level = (level or 1) + 1

    -- 尝试本地变量
    for i = 1, math.huge do
        local n, v = debug.getlocal(level, i)
        if not n then break end
        if n == name then
            value = v
            found = true
        end
    end

    if found then return "local", value end

    -- 尝试非本地变量
    local func = debug.getinfo(level, "fn").func
    for i = 1, math.huge do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if n == name then return "upvalue", v end
    end

    if isenv then return "noenv" end    -- 避免循环

    -- 未找到；从环境获取值
    local _, env = getvarvalue("_ENV", level, true)
    if env then
        return "global", env[name]
    else
        return "noenv"
    end
end
