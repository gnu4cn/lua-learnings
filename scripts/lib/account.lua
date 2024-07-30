Account = {balance = 0}

function Account:new (o)
    o = o or {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function Account:deposit (v)
    self.balance = self.balance + v
end

function Account:withdraw (v)
    if v > self.balance then error"资金不足" end
    self.balance = self.balance - v
end

SpecialAccount = Account:new()

function SpecialAccount:withdraw (v)
    if v - self.balance > self:getLimit() then
        error"无效金额"
    end
    self.balance = self.balance -v
end

function SpecialAccount:getLimit ()
    return self.limit or 0
end
