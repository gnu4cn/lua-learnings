A = {x = "this is A"}
B = {f = A}

setmetatable(B, {__gc = function (o) print(o.f.x) end})
A, B = nil
collectgarbage()
