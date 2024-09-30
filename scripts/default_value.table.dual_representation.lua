local defaults = {}
setmetatable(defaults, {__mode = "k"})

local mt = {__index = function (t) return defaults[t] end}

function setDefault (t, d)
    defaults[t] = d
    setmetatable(t, mt)
end
