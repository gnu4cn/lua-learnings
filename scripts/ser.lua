#!/usr/bin/env lua

local fmt = {integer = "%d", float = "%a"}

function serialize (o)
    local t = type(o)

    if t == "number"
        or t == "string"
        or t == "boolean"
        or t == "nil"
        then
            io.write(string.format("%q", o))
    elseif t == "table" then
        io.write("{\n")
        for k, v in pairs(o) do
            io.write(string.format("\t[%q] = ", k))
            serialize(v)
            io.write(",\n")
        end
        io.write("}\n")
    else
        error("cannot serialize a " .. type(o))
    end
end

serialize{a=12, b='Lua', key='another "one"'}

function quote (s)
    -- 找出等号序列的最大长度
    local n = -1
    for w in string.gmatch(s, "]=*%f[%]]") do
        n = math.max(n, #w - 1)     -- 减去 1 是要排除那个 ']'
    end

    -- 产生出有着 'n' 加一个等号的字符串
    local eq = string.rep("=", n + 1)

    -- 构建出括起来的字符串
    return string.format(" [%s]\n%s]%s]", eq, s, eq)
end

function basicSerialize (o)
    -- 假定 'o' 是个数字或字符串
    return string.format("%q", o)
end

function save (name, value, saved)
    saved = saved or {}
    io.write(name, " = ")

    if type(value) == "number"
        or type(value) == "string"
        then
            io.write(basicSerialize(value), "\n")
    elseif type(value) == "table" then
        if saved[value] then                -- 值已被保存？
            io.write(saved[value], "\n")    -- 使用其先前的名字
        else
            saved[value] = name             -- 为下一次保存名字
            io.write("{}\n")                -- 创建出一个新表
            for k, v in pairs(value) do     -- 保存其字段
                k = basicSerialize(k)
                local fname = string.format("%s[%s]", name, k)
                save(fname, v, saved)
            end
        end
    else
        error("cannot save a " .. type(value))
    end
end

a = {x=1, y=2; {3, 4, 5}}
a[2] = a    -- 循环
a.z = a[1]  -- 共用的子表

save("a", a)

a = {{"one", "two"}, 3}
b = {k = a[1]}


local t = {}
save("a", a, t)
save("b", b, t)
