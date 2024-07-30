#!/usr/bin/env lua

local key = {}      -- 唯一键
local mt = {__index = function (t) return t[key] end}
function setDefault (t, d)
    t.[key] = d
    setmetatable(t, mt)
end

tab = {x=10, y=20}
print(tab.x, tab.z)         --> 10      nil
setDefault(tab, 30)
print(tab.x, tab.z)         --> 10      0



