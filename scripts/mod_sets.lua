local Set = {}
local mt = {}
local MT_HASH = "V8K4Rwux72nEYFfSDTWmCp"
mt.__metatable = MT_HASH


-- 以给定列表，创建出一个新的集合
function Set.new (l)
    local set = {}
    setmetatable(set, mt)
    for _, v in ipairs(l) do set[v] = true end
    return set
end

function Set.union (a, b)
    if getmetatable(a) ~= MT_HASH or getmetatable(b) ~= MT_HASH then
        error("attempt to 'add' a set with a non-set value", 2)
    end

    local res = Set.new{}
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

function Set.intersection (a, b)
    local res = Set.new{}
    for k in pairs(a) do
        res[k] = b[k]
    end
    return res
end


-- 将集合表示为字符串
function Set.tostring (set)
    local l = {}    -- 将该集合中全部元素放入的列表
    for el in pairs(set) do
        l[#l + 1] = tostring(el)
    end
    return "{" .. table.concat(l, ", ") .. "}"
end

mt.__add = Set.union
mt.__mul = Set.intersection
mt.__tostring = Set.tostring

mt.__le = function (a, b)       -- 子集
    for k in pairs(a) do
        if not b[k] then return false end
    end
    return true
end

mt.__lt = function (a, b)       -- 恰当的子集
    return a <= b and not (b <= a)
end

mt.__eq = function (a, b)
    return a <= b and b <= a
end
return Set
