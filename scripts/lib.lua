Lib = {}

Lib.exit = os.exit
Lib.x = os.execute

Lib.norm = function (x, y)
    return math.sqrt(x^2 + y^2)
end

Lib.twice = function (x)
    return 2.0 * x
end

local tolerance = 0.17
Lib.isturnback = function (angle)
    angle = angle % (2*math.pi)
    return (math.abs(angle - math.pi) < tolerance)
end


Lib.round = function (x)
    local f = math.floor(x)

    if x == f
        or (x % 2.0 == 0.5)
        then return f
    else return math.floor(x + 0.5)
    end
end

Lib.cond2int = function (x)
    return math.tointeger(x) or x
end

-- 将序列 'a' 的元素相加
Lib.addd = function (a)
    local sum = 0

    for i = 1, #a do
        sum = sum + a[i]
    end

    return sum
end


Lib.incCount = function (n)
    n = n or 1
    globalCounter = globalCounter + n
end


Lib.maxium = function (a)
    local mi = 1            -- 最大值的索引
    local m = a[mi]         -- 最大值

    for i = 1, #a do
        if a[i] > m then
            mi = i; m = a[i]
        end
    end

    return m, mi
end


Lib.sum = function (...)
    local sum = 0

    for i = 1, select("#", ...) do
        sum = sum + select(i, ...)
    end

    return sum
end


Lib.f_write = function (fmt, ...)
    return io.write(string.format(fmt, ...))
end


Lib.nonils = function (...)
    local arg = table.pack(...)

    for i = 1, arg.n do
        if arg[i] == nil then return false end
    end

    return true
end


Lib._unpack = function (t, i, n)
    i = i or 1
    n = n or #t
    if i <= n then
        return t[i], _unpack(t, i + 1, n)
    end
end


Lib.f_size = function (file)
    local current = file:seek()     -- 保存当前位置
    local size = file:seek("end")   -- 获取文件大小

    file:seek("set", current)       -- 恢复位置

    return size
end


Lib.createDir = function (dirname)
    os.execute("mkdir " .. dirname)
end


-- 使用 Newton-Raphson 方法，计算 'x' 的平方根
Lib.nr_sqrt = function (x)
    local sqrt = x / 2

    repeat
        sqrt = (sqrt + x/sqrt) / 2
        local error = math.abs(sqrt^2 - x)
    until error < x/10000       -- 循环体中的本地 'error' 变量，在这里仍然可见

    return sqrt
end


function Lib.derivative (f, delta)
    delta = delta or 1e-4
    return function (x)
        return (f(x + delta) - f(x))/delta
    end
end

function Lib.degreesin (x)
    local k = math.pi / 180
    return math.sin(x * k)
end

function Lib.trim(s)
    s = string.gsub(s, "^%s*(.-)%s*$", "%1")
    return s
end

function Lib.udiv (n, d)
    if d < 0 then
        if math.ult(n, d) then return 0
        else return 1
        end
    end

    local q = ((n >> 1) // d) << 1
    local r = n - q * d
    if not math.ult(r, d) then q = q + 1 end
    return q
end

function Lib.mt_mult (a, b)
    local c = {}        -- 得到的矩阵

    for i = 1, #a do
        local resultline = {}                   -- 将是 'c[i]'
        for k, va in pairs(a[i]) do             -- 'va' 为 a[i][k]
            for j, vb in pairs(b[k]) do         -- 'vb' 为 b[k][j]
                local res = (resultline[j] or 0) + va * vb
                resultline[j] = (res ~= 0) and res or nil
            end
        end
        c[i] = resultline
    end

    return c
end

function Lib.getfield (f)
    local v = _G    -- 从全局变量表开始

    for w in string.gmatch(f, "[%a_][%w_]*") do
        v = v[w]
    end

    return v
end


function Lib.setfield (f, v)
    local t = _G                -- 从全局变量表开始
    for w, d in string.gmatch(f, "([%a_][%w_]*)(%.?)") do
        if d == "." then        -- 不是最后的名字？
            t[w] = t[w] or {}   -- 在缺失时创建表
            t = t[w]            -- 获取到该表
        else                    -- 是最后的名字时
            t[w] = v            -- 进行赋值
        end
    end
end

Lib.setfield("_PROMPT", "*-*: ")

local declaredNames = {}

setmetatable(_G, {
    __newindex = function(t, n, v)
        if not declaredNames[n] then
            local w = debug.getinfo(2, "S").what
            if w ~= "main" and w ~= "C" then
                error("尝试写入未经声明的变量"..n, 2)
            end
            declaredNames[n] = true
        end
        rawset(t, n, v)     -- 执行真正设置
    end,

    __index = function (_, n)
        if not declaredNames[n] then
            error("尝试读取未经声明的变量 "..n, 2)
        else
            return nil
        end
    end,
})
