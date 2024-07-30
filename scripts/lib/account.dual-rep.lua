local balance = {}

Account = {}


function Account:withdraw (v)
    balance[self] = balance[self] -v
end

function Account:deposit (v)
    balance[self] = balance[self] + v
end

function Account:balance ()
    return balance[self]
end

function Account:new (o)
    o = o or {}     -- 在用户没有提供表表时，创建出表
    setmetatable(o, self)
    self.__index = self
    balance[o] = 0      -- 初始余额
    return o
end
