local M = {}        -- 模组


-- 创建出一个新的复数
local function new (r, i)
    return {r = r, i = i}
end

M.new = new

-- 常量 'i'
M.i = new(0, 1)

function M.add (c1, c2)
    return new(c1.r + c2.r, c1.i + c2.i)
end

function M.sub (c1, c2)
    return new(c1.r - c2.r, c1.i - c2.i)
end


function M.mul (c1, c2)
    return new(c1.r*c2.r - c1.i*c2.i, c1.r*c2.i + c1.i*c2.r)
end

local function inv (c)
    local n = c.r^2 + c.i^2
    return new(c.r/n, -c.i/n)
end

function M.div (c1, c2)
    return M.mul(c1, inv(c2))
end

function M.tostring (c)
    return string.format("(%q,%q)", c.r, c.i)
end

return M
