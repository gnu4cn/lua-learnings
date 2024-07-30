#!/usr/bin/env lua

do
    local oldSin = math.sin
    local k = math.pi / 180
    math.sin = function (x)
        return oldSin(x * k)
    end
end

print(math.sin(90))
