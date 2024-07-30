#!/usr/bin/env lua

function foo (str)
    if type(str) ~= "string" then
        error("string expected", 2)
    end

    print(str)
end

function stringrep (s, n)
    local r = ""

    if n > 0 then
        while n > 1 do
            if n % 2 ~= 0 then r = r .. s end
            s = s .. s
            n = math.floor(n / 2)
        end
        r = r .. s
    end

    return r
end

print(arg[1], arg[2])
print(stringrep(arg[1], tonumber(arg[2])))

function stringrep_5 (s)
    local r = ""
    r = r .. s
    s = s .. s
    s = s .. s
    r = r .. s
    return r
end
