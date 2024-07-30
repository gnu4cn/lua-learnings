-- 在表 `plist` 的列表种查找 `k`
local function search (k, plist)
    for i = 1, #plist do
        local v = plist[i][k]   -- 尝试第 `i` 个超类
        if v then return v end
    end
end

function createClass (...)
    local c = {}            -- 新类
    local parents = {...}   -- 父类的列表

    -- 类在其父类列表中检索缺失的方法
    setmetatable (c, {__index = function (t, k)
        local v = search (k, parents)
        t[k] = v    -- 保存用于下次访问
        return v
    end})

    -- 准备 `c` 作为其实例的元表
    c.__index = c

    -- 定义这个新类的新构造器
    function c:new (o)
        o = o or {}
        setmetatable (o, c)
        return o
    end

    return c
end
