mt = {__gc = function (o) print(o[1]) end}

list = nil
for i = 1, 3 do
    list = setmetatable({i, link = list}, mt)
end

list = nil
collectgarbage()
